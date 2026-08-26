--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sv_breach.lua
	Нарушение содержания: уровни, спавн SCP, волна МОГ, завершение.
------------------------------------------------------------------------------]]

SCPF.BreachState = SCPF.BreachState or {}
SCPF.BreachState.Active = false
SCPF.BreachState.Level = 0
SCPF.BreachState.Spawned = {}
SCPF.BreachState.StartTime = 0

function SCPF.StartBreach(level, reason)
	if SCPF.BreachState.Active then return false end
	level = level or math.random(1, 3)
	local cfg = SCPF.Breach.Levels[level] or SCPF.Breach.Levels[1]

	SCPF.BreachState.Active = true
	SCPF.BreachState.Level = level
	SCPF.BreachState.StartTime = CurTime()
	SCPF.BreachState.Spawned = {}

	SCPF.NotifyAll(string.format("=== НАРУШЕНИЕ СОДЕРЖАНИЯ: %s ===%s",
		cfg.name, reason and (" Причина: " .. reason) or ""), SCPF.NotifyTypes.ERROR, 10)

	net.Start(SCPF.Net.Breach)
	net.WriteBool(true)
	net.WriteUInt(level, 4)
	net.Broadcast()

	-- Спавн SCP
	local scps = SCPF.SCPJobs()
	table.Shuffle(scps)
	for i = 1, math.min(cfg.scps, #scps) do
		local job = scps[i]
		if SCPF.IsSCPAlive(job.id) then continue end
		timer.Simple(i * 0.8, function()
			local ent = SCPF.SpawnSCP(job.id)
			if IsValid(ent) then
				SCPF.BreachState.Spawned[#SCPF.BreachState.Spawned + 1] = ent
				SCPF.NotifyAll("ОБНАРУЖЕН ОБЪЕКТ: " .. job.name, SCPF.NotifyTypes.WARN, 8)
			end
		end)
	end

	-- Волна МОГ
	if cfg.mtf then
		timer.Simple(20, function()
			if not SCPF.BreachState.Active then return end
			SCPF.NotifyAll("МОГ Эпсилон-11 «Девятихвостая лисица» прибыла на объект.", SCPF.NotifyTypes.INFO, 8)
		end)
	end

	timer.Create("SCPF_BreachTimeout", SCPF.Breach.Duration, 1, function()
		if SCPF.BreachState.Active then SCPF.EndBreach(false) end
	end)

	timer.Create("SCPF_BreachCheck", 3, 0, function()
		if not SCPF.BreachState.Active then timer.Remove("SCPF_BreachCheck") return end
		local alive = 0
		for _, ent in ipairs(SCPF.BreachState.Spawned) do
			if IsValid(ent) and ent:Alive() then alive = alive + 1 end
		end
		if alive == 0 and CurTime() - SCPF.BreachState.StartTime > 25 then
			SCPF.EndBreach(true)
		end
	end)

	SCPF.CallSchemaHook("OnBreachStart", level)
	return true
end

function SCPF.EndBreach(success)
	if not SCPF.BreachState.Active then return end
	SCPF.BreachState.Active = false
	SCPF.BreachState.Level = 0
	timer.Remove("SCPF_BreachTimeout")
	timer.Remove("SCPF_BreachCheck")

	net.Start(SCPF.Net.Breach)
	net.WriteBool(false)
	net.WriteUInt(0, 4)
	net.Broadcast()

	SCPF.NotifyAll(success and "=== СОДЕРЖАНИЕ ВОССТАНОВЛЕНО ===" or "=== НАРУШЕНИЕ УСТРАНЕНО (таймаут) ===",
		success and SCPF.NotifyTypes.SUCCESS or SCPF.NotifyTypes.WARN, 10)

	for _, ent in ipairs(SCPF.BreachState.Spawned) do
		if IsValid(ent) then ent:Remove() end
	end
	SCPF.BreachState.Spawned = {}

	SCPF.CallSchemaHook("OnBreachEnd", success)
	SCPF.ScheduleBreach()
end

function SCPF.ScheduleBreach()
	if not SCPF.Breach.Enabled then return end
	timer.Remove("SCPF_BreachSchedule")
	timer.Create("SCPF_BreachSchedule", math.random(SCPF.Breach.MinWait, SCPF.Breach.MaxWait), 1, function()
		if not SCPF.BreachState.Active then SCPF.StartBreach(math.random(1, 3)) else SCPF.ScheduleBreach() end
	end)
end

hook.Add("PostGamemodeLoaded", "SCPF_BreachInit", function()
	timer.Simple(40, SCPF.ScheduleBreach)
end)

-----------------------------------------------------------------------------
-- КОМАНДЫ
-----------------------------------------------------------------------------
SCPF.AddCommand("/lockdown", {
	desc = "Объявить локдаун (командование)",
	console = "lockdown",
	perm = function(ply)
		local j = SCPF.JobByTeam(ply:Team())
		return ply:IsAdmin() or (j and j.clearance >= 5)
	end,
	run = function(ply)
		SCPF.NotifyAll(ply:Nick() .. " объявил ЛОКДАУН. Все двери заблокированы.", SCPF.NotifyTypes.ERROR, 8)
		for _, ent in ipairs(ents.GetAll()) do
			if ent:IsDoor() then ent:Fire("lock") end
		end
		timer.Simple(30, function()
			SCPF.NotifyAll("Локдаун снят.", SCPF.NotifyTypes.SUCCESS, 6)
			for _, ent in ipairs(ents.GetAll()) do
				if ent:IsDoor() and not ent.SCPFLocked then ent:Fire("unlock") end
			end
		end)
	end,
})

SCPF.AddCommand("/announce", {
	desc = "Объявление на всю Зону. /announce <текст>",
	console = "announce",
	perm = function(ply)
		local j = SCPF.JobByTeam(ply:Team())
		return ply:IsAdmin() or (j and (j.clearance >= 4 or j.faction == "mtf"))
	end,
	run = function(ply, args)
		local text = table.concat(args, " ")
		if text == "" then return end
		SCPF.NotifyAll("ОБЪЯВЛЕНИЕ [" .. ply:Nick() .. "]: " .. text, SCPF.NotifyTypes.WARN, 10)
	end,
})

SCPF.AddCommand("/breach", {
	desc = "Запустить нарушение (админ). /breach <1-3>",
	console = "breach",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply, args)
		local lvl = tonumber(args[1]) or math.random(1, 3)
		if SCPF.BreachState.Active then SCPF.Notify(ply, "Уже активно", 4, SCPF.NotifyTypes.WARN) return end
		SCPF.StartBreach(lvl, "запущено администратором " .. ply:Nick())
	end,
})

SCPF.AddCommand("/endbreach", {
	desc = "Остановить нарушение (админ)",
	console = "endbreach",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply)
		if SCPF.BreachState.Active then SCPF.EndBreach(true) else SCPF.Notify(ply, "Нет активного нарушения", 4, SCPF.NotifyTypes.WARN) end
	end,
})

SCPF.AddCommand("/spawnscp", {
	desc = "Заспавнить SCP (админ). /spawnscp <id>",
	console = "spawnscp",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply, args)
		local id = args[1] or "scp_173"
		local tr = util.TraceLine({start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 300, filter = ply})
		local ent = SCPF.SpawnSCP(id, tr.HitPos)
		SCPF.Notify(ply, IsValid(ent) and ("Заспавнен: " .. id) or "Не вышло", 4,
			IsValid(ent) and SCPF.NotifyTypes.SUCCESS or SCPF.NotifyTypes.ERROR)
	end,
})
