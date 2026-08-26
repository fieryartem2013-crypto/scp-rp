--[[----------------------------------------------------------------------------
	SCP RP | DarkRP — init.lua
	СЕРВЕРНАЯ ТОЧКА ВХОДА. GMod грузит именно gamemode/init.lua.
	Обязательно: сначала shared.lua (там DeriveGamemode и GM.Name),
	потом серверные модули.
------------------------------------------------------------------------------]]

include("shared.lua")

include("framework/sh_config.lua")
include("framework/sh_lib.lua")
include("framework/sh_factions.lua")
include("framework/sh_departments.lua")
include("framework/sh_jobs.lua")
include("framework/sh_whitelist.lua")
include("framework/sh_characters.lua")
include("framework/sh_schema.lua")

include("sv_jobs.lua")
include("sv_money.lua")
include("sv_arrest.lua")
include("sv_doors.lua")
include("sv_breach.lua")
include("sv_commands.lua")
include("sv_spawns.lua")
include("sv_admin.lua")

local GM = GM or GAMEMODE

-----------------------------------------------------------------------------
-- ХУКИ
-----------------------------------------------------------------------------
function GM:Initialize()
	self.BaseClass.Initialize(self)
	SCPF.Log("INIT", "SCP Framework " .. SCPF.Version .. " запущен")
end

function GM:PlayerInitialSpawn(ply)
	self.BaseClass.PlayerInitialSpawn(self, ply)

	ply.SCPF = ply.SCPF or {}
	ply.SCPF.Spawns = 0

	timer.Simple(1, function()
		if not IsValid(ply) then return end
		-- Загружаем или создаём персонажа
		local char = SCPF.Characters.Load(ply:SteamID64())
		if not char then
			char = SCPF.Characters.CreateFor(ply, ply:Nick(), "Новый сотрудник Зоны.", "dclass")
		end
		ply.SCPF_Char = char
		SCPF.Characters.Sync(ply)
		SCPF.Whitelist.SyncToClient(ply)
		SCPF.SetJob(ply, char.job, true)
		SCPF.Money.Set(ply, char.money or SCPF.StartingMoney)
		SCPF.SyncSpawns(ply)
		SCPF.Notify(ply, "Добро пожаловать в Зону. F4 — меню.", 8, SCPF.NotifyTypes.INFO)
	end)
end

function GM:PlayerLoadout(ply)
	if not IsValid(ply) then return end
	ply:StripWeapons()
	ply:Give("weapon_physcannon")
	ply:Give("gmod_tool")
	ply:Give("weapon_physgun")

	local job = SCPF.JobByTeam(ply:Team())
	if not job then return end
	for _, w in ipairs(job.weapons or {}) do
		ply:Give(w)
	end
	if #job.weapons > 0 then ply:SelectWeapon(job.weapons[1]) end
end

function GM:PlayerSetModel(ply)
	local job = SCPF.JobByTeam(ply:Team())
	local models = (job and job.models) or {"models/player/Group01/male_01.mdl"}
	ply:SetModel(models[(ply:EntIndex() % #models) + 1])
end

function GM:PlayerSpawn(ply)
	self.BaseClass.PlayerSpawn(self, ply)

	if ply.SCPF and ply.SCPF.SpawnPos then
		ply:SetPos(ply.SCPF.SpawnPos)
	end

	local job = SCPF.JobByTeam(ply:Team())
	ply:SetHealth((job and job.hp) or SCPF.MaxHealth)
	ply:SetArmor((job and job.armor) or 0)
	ply:SetWalkSpeed(SCPF.WalkSpeed)
	ply:SetRunSpeed(SCPF.RunSpeed)
	ply:SetMaxSpeed(SCPF.RunSpeed)
	ply:SetJumpPower(200)
	ply:Extinguish()
	ply:UnSpectate()

	ply.SCPF = ply.SCPF or {}
	ply.SCPF.Spawns = (ply.SCPF.Spawns or 0) + 1
end

function GM:PlayerDeathThink(ply) return false end

function GM:DoPlayerDeath(ply, attacker, dmginfo)
	ply:CreateRagdoll()
	ply:AddDeaths(1)
	SCPF.CallSchemaHook("OnPlayerDeath", ply, attacker)
end

function GM:PlayerDeathSound() return true end

-----------------------------------------------------------------------------
-- ЗАРПЛАТА
-----------------------------------------------------------------------------
hook.Add("PostGamemodeLoaded", "SCPF_Salary", function()
	timer.Create("SCPF_Salary", SCPF.SalaryInterval, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) or ply.SCPF_AFK then continue end
			local job = SCPF.JobByTeam(ply:Team())
			if not job or (job.salary or 0) <= 0 then continue end
			SCPF.Money.Add(ply, job.salary)
		end
	end)
end)

-----------------------------------------------------------------------------
-- АФК
-----------------------------------------------------------------------------
hook.Add("PlayerFootstep", "SCPF_AFKReset", function(ply)
	ply.SCPF = ply.SCPF or {}
	ply.SCPF.LastMove = CurTime()
	if ply.SCPF_AFK then ply.SCPF_AFK = false end
end)

hook.Add("Think", "SCPF_AFKCheck", function()
	if SCPF.AFKNext and SCPF.AFKNext > CurTime() then return end
	SCPF.AFKNext = CurTime() + 10
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) then continue end
		ply.SCPF = ply.SCPF or {}
		if ply.SCPF_AFK then continue end
		if (CurTime() - (ply.SCPF.LastMove or CurTime())) > 180 then
			ply.SCPF_AFK = true
			SCPF.Notify(ply, "Вы помечены как АФК. Зарплата приостановлена.", 6, SCPF.NotifyTypes.WARN)
		end
	end
end)

-----------------------------------------------------------------------------
-- ОГРАНИЧЕНИЯ
-----------------------------------------------------------------------------
function GM:PlayerShouldTakeDamage(ply, attacker)
	if ply.SCPF_Arrested and IsValid(attacker) and attacker:IsPlayer() then return false end
	return true
end

function GM:CanPlayerSuicide(ply)
	if ply.SCPF_Arrested then return false end
	local job = SCPF.JobByTeam(ply:Team())
	if job and job.scp then return false end
	return true
end

function GM:PlayerSpawnProp(ply, model) return not ply.SCPF_Arrested end
function GM:PlayerSpawnSWEP(ply) return ply:IsAdmin() end
function GM:PlayerSpawnNPC(ply) return ply:IsAdmin() end
function GM:PlayerSpawnSENT(ply, class)
	if ply.SCPF_Arrested then return false end
	return not string.find(class, "ent_scp_") or ply:IsAdmin()
end

function GM:PhysgunPickup(ply, ent)
	if ply.SCPF_Arrested then return false end
	if ent:IsPlayer() and not ply:IsAdmin() then return false end
	if ent:GetClass():StartWith("ent_scp_") and not ply:IsAdmin() then return false end
	return true
end

function GM:HUDShouldDraw(name)
	if name == "CHudHealth" or name == "CHudBattery" or name == "CHudAmmo"
		or name == "CHudSecondaryAmmo" or name == "CHudDamageIndicator" then
		return false
	end
	return true
end

function GM:DrawDeathNotice() return false end

function GM:InitPostEntity()
	self.BaseClass.InitPostEntity(self)
	timer.Simple(2, function()
		SCPF.Spawns.Load()
		SCPF.Log("INIT", "Системы инициализированы")
	end)
end
