--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sv_arrest.lua
	Задержание: арест, освобождение, побег.
------------------------------------------------------------------------------]]

function SCPF.Arrest(ply, target, time)
	if not IsValid(ply) or not IsValid(target) or not target:IsPlayer() then
		return false, "Цель не найдена"
	end
	if target == ply then return false, "Нельзя задержать себя" end
	if not target:Alive() then return false, "Цель мертва" end
	if target.SCPF_Arrested then return false, "Уже задержан" end
	if ply.SCPF_Arrested then return false, "Вы сами задержаны" end

	local tjob = SCPF.JobByTeam(target:Team())
	if not tjob then return false, "Невозможно задержать" end

	-- Кого можно арестовать
	local arrestable = {dclass = true, chaos = true, serpent = true, mcd = true, goc = true}
	if tjob.scp then
		SCPF.Notify(ply, "Объект SCP не задерживается — он содержится. Применяйте силу.", 5, SCPF.NotifyTypes.WARN)
		return false
	end
	if not arrestable[tjob.faction] and tjob.faction == "foundation" and tjob.department ~= "isd" then
		SCPF.Notify(ply, "Сотрудник Фонда не подлежит задержанию (кроме СБ).", 5, SCPF.NotifyTypes.WARN)
		return false
	end

	-- Кто может арестовывать
	local pjob = SCPF.JobByTeam(ply:Team())
	local allowed = pjob and (pjob.department == "security" or pjob.department == "isd" or pjob.faction == "mtf")
	if not allowed and not ply:IsAdmin() then
		SCPF.Notify(ply, "У вас нет полномочий на задержание.", 5, SCPF.NotifyTypes.ERROR)
		return false
	end

	time = math.Clamp(tonumber(time) or SCPF.Arrest.Time, 10, SCPF.Arrest.MaxTime)
	SCPF.DoArrest(target, time, ply)

	local fine = math.min(SCPF.Arrest.Fine, SCPF.Money.Get(target))
	if fine > 0 then
		SCPF.Money.Take(target, fine)
		SCPF.Money.Add(ply, fine)
	end
	SCPF.Money.Add(ply, SCPF.Arrest.Bounty)

	SCPF.NotifyAll(string.format("%s задержал %s на %d сек.", ply:Nick(), target:Nick(), time), SCPF.NotifyTypes.WARN, 6)
	SCPF.CallSchemaHook("PlayerArrested", ply, target, time)
	return true
end

function SCPF.DoArrest(target, time, arrester)
	target.SCPF_Arrested = true
	target.SCPF_ArrestTime = CurTime() + time

	target:StripWeapons()
	target:Give("weapon_physcannon")
	target:SelectWeapon("weapon_physcannon")
	target:SetWalkSpeed(80)
	target:SetRunSpeed(80)
	target:SetJumpPower(0)

	local cell = SCPF.Spawns.Find("cell")
	if cell then target:SetPos(cell) end

	net.Start(SCPF.Net.Arrested)
	net.WriteBool(true)
	net.WriteUInt(math.floor(time), 16)
	net.Send(target)
end

function SCPF.UnArrest(target, by)
	if not IsValid(target) or not target.SCPF_Arrested then return end
	target.SCPF_Arrested = false
	target.SCPF_ArrestTime = nil
	target:SetWalkSpeed(SCPF.WalkSpeed)
	target:SetRunSpeed(SCPF.RunSpeed)
	target:SetJumpPower(200)
	GAMEMODE:PlayerLoadout(target)

	net.Start(SCPF.Net.Arrested)
	net.WriteBool(false)
	net.WriteUInt(0, 16)
	net.Send(target)

	SCPF.Notify(target, IsValid(by) and ("Вас освободил " .. by:Nick()) or "Срок задержания истёк.", 6, SCPF.NotifyTypes.INFO)
end

hook.Add("Think", "SCPF_ArrestTimer", function()
	for _, ply in ipairs(player.GetAll()) do
		if ply.SCPF_Arrested and ply.SCPF_ArrestTime and CurTime() >= ply.SCPF_ArrestTime then
			SCPF.UnArrest(ply)
		end
	end
end)

-----------------------------------------------------------------------------
-- КОМАНДЫ
-----------------------------------------------------------------------------
SCPF.AddCommand("/arrest", {
	desc = "Задержать. /arrest <ник> [сек]",
	console = "arrest",
	perm = function(ply)
		local j = SCPF.JobByTeam(ply:Team())
		return j and (j.department == "security" or j.department == "isd" or j.faction == "mtf")
	end,
	run = function(ply, args)
		local target = SCPF.FindPlayer(args[1])
		if not target then SCPF.Notify(ply, "Игрок не найден", 4, SCPF.NotifyTypes.ERROR) return end
		local ok, msg = SCPF.Arrest(ply, target, tonumber(args[2]))
		if not ok then SCPF.Notify(ply, msg, 5, SCPF.NotifyTypes.ERROR) end
	end,
})

SCPF.AddCommand("/unarrest", {
	desc = "Освободить. /unarrest <ник>",
	console = "unarrest",
	perm = function(ply)
		local j = SCPF.JobByTeam(ply:Team())
		return j and (j.department == "security" or j.department == "isd" or j.faction == "mtf")
	end,
	run = function(ply, args)
		local target = SCPF.FindPlayer(args[1])
		if not target then SCPF.Notify(ply, "Игрок не найден", 4, SCPF.NotifyTypes.ERROR) return end
		SCPF.UnArrest(target, ply)
	end,
})

SCPF.AddCommand("/escape", {
	desc = "Попытка побега (стоит " .. SCPF.Arrest.EscapeCost .. " " .. SCPF.Currency .. ")",
	console = "escape",
	run = function(ply)
		if not ply.SCPF_Arrested then SCPF.Notify(ply, "Вы не задержаны", 4, SCPF.NotifyTypes.ERROR) return end
		if ply.SCPF_Escaping then return end
		local ok, err = SCPF.Money.Take(ply, SCPF.Arrest.EscapeCost)
		if not ok then SCPF.Notify(ply, err, 5, SCPF.NotifyTypes.ERROR) return end

		ply.SCPF_Escaping = true
		SCPF.Notify(ply, "Попытка побега... 10 секунд.", 10, SCPF.NotifyTypes.WARN)

		timer.Simple(10, function()
			ply.SCPF_Escaping = false
			if not IsValid(ply) or not ply.SCPF_Arrested then return end
			-- Срывается, если рядом охрана
			for _, p in ipairs(player.GetAll()) do
				if p == ply or not p:Alive() then continue end
				local j = SCPF.JobByTeam(p:Team())
				if j and (j.department == "security" or j.faction == "mtf") and SCPF.Dist(p, ply) < 300 then
					SCPF.Notify(ply, "Побег сорван: охрана рядом.", 5, SCPF.NotifyTypes.ERROR)
					SCPF.Notify(p, ply:Nick() .. " пытался бежать.", 5, SCPF.NotifyTypes.WARN)
					return
				end
			end
			if math.random(1, 100) <= SCPF.Arrest.EscapeChance then
				SCPF.UnArrest(ply)
				SCPF.Notify(ply, "Вы сбежали.", 6, SCPF.NotifyTypes.SUCCESS)
				SCPF.NotifyAll(ply:Nick() .. " совершил побег.", SCPF.NotifyTypes.WARN, 6)
			else
				SCPF.Notify(ply, "Побег не удался.", 5, SCPF.NotifyTypes.ERROR)
			end
		end)
	end,
})
