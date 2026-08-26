--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sh_characters.lua
	Система персонажей (Helix-style): имя, описание, джоба, инвентарь, деньги.
	Персонаж создаётся при первом входе и хранится на сервере.
------------------------------------------------------------------------------]]

SCPF.Characters = SCPF.Characters or {}

-----------------------------------------------------------------------------
-- СТРУКТУРА ПЕРСОНАЖА
-----------------------------------------------------------------------------
function SCPF.Characters.Create(data)
	return {
		steamid   = data.steamid or "",
		name      = data.name or "Неизвестный",
		desc      = data.desc or "",
		job       = data.job or "dclass",
		faction   = data.faction or "foundation",
		money     = data.money or SCPF.StartingMoney,
		inventory = data.inventory or {},
		clearance = data.clearance or 0,
		created   = data.created or os.time(),
	}
end

-----------------------------------------------------------------------------
-- СЕРВЕР: ХРАНЕНИЕ И ЗАГРУЗКА
-----------------------------------------------------------------------------
if SERVER then
	local CHAR_DIR = "scpf/characters"

	function SCPF.Characters.Load(steamid)
		if not file.IsDir(CHAR_DIR, "DATA") then file.CreateDir(CHAR_DIR) end
		local path = CHAR_DIR .. "/" .. steamid .. ".txt"
		if not file.Exists(path, "DATA") then return nil end
		local raw = file.Read(path, "DATA")
		if not raw or raw == "" then return nil end
		local ok, data = pcall(util.JSONToTable, raw)
		if not ok or type(data) ~= "table" then return nil end
		return SCPF.Characters.Create(data)
	end

	function SCPF.Characters.Save(ply)
		if not IsValid(ply) or not ply.SCPF_Char then return end
		if not file.IsDir(CHAR_DIR, "DATA") then file.CreateDir(CHAR_DIR) end
		local data = ply.SCPF_Char
		data.steamid = ply:SteamID64()
		file.Write(CHAR_DIR .. "/" .. data.steamid .. ".txt", util.TableToJSON(data, true))
	end

	function SCPF.Characters.CreateFor(ply, name, desc, jobID)
		local job = SCPF.GetJob(jobID or "dclass")
		if not job then return nil end
		local char = SCPF.Characters.Create({
			steamid = ply:SteamID64(),
			name = name,
			desc = desc,
			job = job.id,
			faction = job.faction,
			clearance = job.clearance or 0,
		})
		ply.SCPF_Char = char
		SCPF.Characters.Save(ply)
		return char
	end

	-- Автосохранение
	hook.Add("PlayerDisconnected", "SCPF_CharSave", function(ply)
		SCPF.Characters.Save(ply)
	end)
	hook.Add("ShutDown", "SCPF_CharSaveAll", function()
		for _, ply in ipairs(player.GetAll()) do SCPF.Characters.Save(ply) end
	end)
	timer.Create("SCPF_CharAutoSave", 120, 0, function()
		for _, ply in ipairs(player.GetAll()) do SCPF.Characters.Save(ply) end
	end)
end

-----------------------------------------------------------------------------
-- КЛИЕНТ: ЛОКАЛЬНЫЙ ПЕРСОНАЖ
-----------------------------------------------------------------------------
if CLIENT then
	SCPF.Characters.Local = nil

	net.Receive("scpf_char", function()
		local data = net.ReadTable()
		SCPF.Characters.Local = data
		hook.Run("SCPF_CharacterLoaded", data)
	end)

	function SCPF.Characters.GetLocal()
		return SCPF.Characters.Local
	end
end

if SERVER then util.AddNetworkString("scpf_char") end

-----------------------------------------------------------------------------
-- СИНХРОНИЗАЦИЯ ПЕРСОНАЖА С КЛИЕНТОМ
-----------------------------------------------------------------------------
if SERVER then
	function SCPF.Characters.Sync(ply)
		if not IsValid(ply) or not ply.SCPF_Char then return end
		net.Start("scpf_char")
		net.WriteTable(ply.SCPF_Char)
		net.Send(ply)
	end
end
