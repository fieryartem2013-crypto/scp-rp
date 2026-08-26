--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sv_jobs.lua
	Регистрация тимов, смена джоб, вайтлист-проверки.
------------------------------------------------------------------------------]]

-----------------------------------------------------------------------------
-- РЕГИСТРАЦИЯ ТИМОВ
-----------------------------------------------------------------------------
local function registerTeams()
	local i = 100
	for id, job in pairs(SCPF.Jobs) do
		job.team = team.Create(i, job.name, job.color or Color(200, 200, 200))
		job.index = i
		i = i + 1
	end
end
registerTeams()

-----------------------------------------------------------------------------
-- СМЕНА ДЖОБЫ
-----------------------------------------------------------------------------
function SCPF.SetJob(ply, id, silent)
	if not IsValid(ply) then return false, "Игрок не найден" end
	local job = SCPF.GetJob(id)
	if not job then return false, "Джоба не найдена" end

	if ply.SCPF_Arrested then
		return false, "Вы задержаны. Смена должности недоступна."
	end

	-- Вайтлист
	local ok, err = SCPF.Whitelist.CheckPlayer(ply, id)
	if not ok then return false, err end

	-- Хук схемы
	local hookOk, hookErr = SCPF.CallSchemaHook("CanChangeJob", ply, job)
	if hookOk == false then return false, hookErr or "Смена запрещена" end

	-- Лимит
	if job.max and job.max > 0 then
		local count = 0
		for _, p in ipairs(player.GetAll()) do
			if p:Team() == job.team then count = count + 1 end
		end
		if count >= job.max then
			return false, "Все места заняты (лимит " .. job.max .. ")"
		end
	end

	-- SCP: только если контейнер пуст
	if job.scp and not silent then
		if SCPF.IsSCPAlive(job.id) then
			return false, "Объект уже активен. Дождитесь восстановления содержания."
		end
	end

	local oldJob = ply:Team()
	ply:SetTeam(job.team)
	ply:SetHealth(job.hp or SCPF.MaxHealth)
	ply:SetArmor(job.armor or 0)
	ply:StripAmmo()
	GAMEMODE:PlayerLoadout(ply)
	GAMEMODE:PlayerSetModel(ply)
	ply:SetupHands()
	ply:Spawn()

	if ply.SCPF_Char then
		ply.SCPF_Char.job = job.id
		ply.SCPF_Char.faction = job.faction
		ply.SCPF_Char.clearance = job.clearance or 0
		SCPF.Characters.Save(ply)
	end

	SCPF.CallSchemaHook("OnJobChanged", ply, oldJob, job)

	net.Start(SCPF.Net.JobChanged)
	net.WriteString(ply:Nick())
	net.WriteString(job.name)
	net.WriteString(job.id)
	net.Broadcast()

	if not silent then
		SCPF.Notify(ply, "Вы назначены: " .. job.name, 5, SCPF.NotifyTypes.SUCCESS)
	end

	return true, "Вы назначены: " .. job.name
end

-----------------------------------------------------------------------------
-- ПРОВЕРКА, ЖИВ ЛИ SCP
-----------------------------------------------------------------------------
function SCPF.IsSCPAlive(jobID)
	local job = SCPF.GetJob(jobID)
	if not job or not job.scpEntity then return false end
	for _, ent in ipairs(ents.FindByClass(job.scpEntity)) do
		if IsValid(ent) and ent:Alive() then return true end
	end
	return false
end

-----------------------------------------------------------------------------
-- СПАВН SCP
-----------------------------------------------------------------------------
function SCPF.SpawnSCP(jobID, pos)
	local job = SCPF.GetJob(jobID)
	if not job or not job.scpEntity then return nil end
	pos = pos or SCPF.Spawns.Find("scp") or Vector(0, 0, 100)

	local ent = ents.Create(job.scpEntity)
	if not IsValid(ent) then return nil end
	ent:SetPos(pos + Vector(0, 0, 10))
	ent.SCPFJobID = jobID
	ent:Spawn()
	ent:Activate()
	return ent
end

-----------------------------------------------------------------------------
-- КОМАНДА
-----------------------------------------------------------------------------
SCPF.AddCommand("/job", {
	desc = "Сменить должность. /job <id>",
	console = "job",
	run = function(ply, args)
		local id = args[1]
		if not id then
			local list = {}
			for jid in pairs(SCPF.Jobs) do list[#list + 1] = jid end
			table.sort(list)
			SCPF.Notify(ply, "Должности: " .. table.concat(list, ", "), 12, SCPF.NotifyTypes.INFO)
			return
		end
		local ok, msg = SCPF.SetJob(ply, id)
		SCPF.Notify(ply, msg, 5, ok and SCPF.NotifyTypes.SUCCESS or SCPF.NotifyTypes.ERROR)
	end,
})

-----------------------------------------------------------------------------
-- NET: СМЕНА ДЖОБЫ ИЗ F4
-----------------------------------------------------------------------------
net.Receive(SCPF.Net.ChangeJob, function(_, ply)
	if not IsValid(ply) then return end
	local id = net.ReadString()
	if not id or #id > 64 then return end
	local ok, msg = SCPF.SetJob(ply, id)
	SCPF.Notify(ply, msg, 5, ok and SCPF.NotifyTypes.SUCCESS or SCPF.NotifyTypes.ERROR)
end)

-----------------------------------------------------------------------------
-- СМЕРТЬ SCP
-----------------------------------------------------------------------------
hook.Add("PlayerDeath", "SCPF_SCPRespawn", function(ply)
	local job = SCPF.JobByTeam(ply:Team())
	if not job or not job.scp then return end
	timer.Simple(12, function()
		if not IsValid(ply) or ply:Alive() then return end
		ply:Spawn()
		SCPF.Notify(ply, "Объект восстановлен в камере содержания.", 6, SCPF.NotifyTypes.INFO)
	end)
end)
