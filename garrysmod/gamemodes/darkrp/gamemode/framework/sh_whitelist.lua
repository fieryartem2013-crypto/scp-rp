--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sh_whitelist.lua
	Вайтлисты: по фракциям и по конкретным джобам.
	Хранение: data/scpf/whitelists/<faction|jobid>.txt (по одному SteamID64 на строку).
	Админ-команды: /wl add <steamid64> <id>, /wl remove ..., /wl list <id>.
------------------------------------------------------------------------------]]

SCPF.Whitelist = SCPF.Whitelist or {}
SCPF.Whitelist.Data = SCPF.Whitelist.Data or {}   -- [id] = { [steamid64] = true }

local WHITELIST_DIR = "scpf/whitelists"

-----------------------------------------------------------------------------
-- ЗАГРУЗКА / СОХРАНЕНИЕ
-----------------------------------------------------------------------------
function SCPF.Whitelist.Load()
	if not file.IsDir(WHITELIST_DIR, "DATA") then
		file.CreateDir(WHITELIST_DIR)
	end

	local files = file.Find(WHITELIST_DIR .. "/*.txt", "DATA")
	for _, f in ipairs(files) do
		local id = string.Replace(f, ".txt", "")
		local content = file.Read(WHITELIST_DIR .. "/" .. f, "DATA") or ""
		SCPF.Whitelist.Data[id] = {}
		for line in content:gmatch("[^\r\n]+") do
			line = line:Trim()
			if line ~= "" and not line:StartWith("#") then
				SCPF.Whitelist.Data[id][line] = true
			end
		end
	end

	if SERVER then
		local total = 0
		for _, list in pairs(SCPF.Whitelist.Data) do
			for _ in pairs(list) do total = total + 1 end
		end
		SCPF.Log("WHITELIST", "Загружено вайтлистов: " .. table.Count(SCPF.Whitelist.Data) .. ", записей: " .. total)
	end
end

function SCPF.Whitelist.Save(id)
	local list = SCPF.Whitelist.Data[id]
	if not list then return false end
	if not file.IsDir(WHITELIST_DIR, "DATA") then file.CreateDir(WHITELIST_DIR) end

	local lines = {"# SCP Framework whitelist: " .. id, "# Один SteamID64 на строку"}
	for sid in pairs(list) do lines[#lines + 1] = sid end
	file.Write(WHITELIST_DIR .. "/" .. id .. ".txt", table.concat(lines, "\n"))
	return true
end

-----------------------------------------------------------------------------
-- ПРОВЕРКИ
-----------------------------------------------------------------------------
function SCPF.Whitelist.Has(steamid64, id)
	if not steamid64 or not id then return false end
	local list = SCPF.Whitelist.Data[id]
	return list and list[steamid64] == true
end

-- Проверка для игрока: джоба требует вайтлист?
function SCPF.Whitelist.CheckPlayer(ply, jobID)
	if not IsValid(ply) then return false, "Игрок не найден" end
	local job = SCPF.GetJob(jobID)
	if not job then return false, "Джоба не найдена" end

	-- Админы обходят вайтлист
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end

	if not job.whitelist then return true end

	local sid = ply:SteamID64()
	-- Вайтлист по конкретной джобе
	if SCPF.Whitelist.Has(sid, jobID) then return true end
	-- Вайтлист по фракции
	if SCPF.Whitelist.Has(sid, job.faction) then return true end

	return false, "Требуется вайтлист для «" .. job.name .. "»"
end

-----------------------------------------------------------------------------
-- ДОБАВЛЕНИЕ / УДАЛЕНИЕ
-----------------------------------------------------------------------------
function SCPF.Whitelist.Add(id, steamid64)
	if not id or not steamid64 then return false, "Укажи id и SteamID64" end
	SCPF.Whitelist.Data[id] = SCPF.Whitelist.Data[id] or {}
	SCPF.Whitelist.Data[id][steamid64] = true
	SCPF.Whitelist.Save(id)
	return true
end

function SCPF.Whitelist.Remove(id, steamid64)
	if not id or not steamid64 then return false, "Укажи id и SteamID64" end
	if not SCPF.Whitelist.Data[id] or not SCPF.Whitelist.Data[id][steamid64] then
		return false, "Записи нет"
	end
	SCPF.Whitelist.Data[id][steamid64] = nil
	SCPF.Whitelist.Save(id)
	return true
end

function SCPF.Whitelist.List(id)
	local list = SCPF.Whitelist.Data[id]
	if not list then return {} end
	local out = {}
	for sid in pairs(list) do out[#out + 1] = sid end
	table.sort(out)
	return out
end

-----------------------------------------------------------------------------
-- СИНХРОНИЗАЦИЯ С КЛИЕНТОМ (для отображения «требуется вайтлист»)
-----------------------------------------------------------------------------
if SERVER then
	function SCPF.Whitelist.SyncToClient(ply)
		if not IsValid(ply) then return end
		local sid = ply:SteamID64()
		local allowed = {}
		for id, list in pairs(SCPF.Whitelist.Data) do
			if list[sid] then allowed[#allowed + 1] = id end
		end
		net.Start("scpf_whitelist_sync")
		net.WriteUInt(#allowed, 16)
		for _, id in ipairs(allowed) do net.WriteString(id) end
		net.Send(ply)
	end
end

if CLIENT then
	SCPF.Whitelist.MyAllowed = {}
	net.Receive("scpf_whitelist_sync", function()
		local n = net.ReadUInt(16)
		SCPF.Whitelist.MyAllowed = {}
		for i = 1, n do
			SCPF.Whitelist.MyAllowed[net.ReadString()] = true
		end
	end)

	function SCPF.Whitelist.ClientHas(id)
		if not id then return true end
		local lp = LocalPlayer()
		if IsValid(lp) and (lp:IsAdmin() or lp:IsSuperAdmin()) then return true end
		return SCPF.Whitelist.MyAllowed[id] == true
	end
end

-- Регистрируем net-строку для синка
if SERVER then util.AddNetworkString("scpf_whitelist_sync") end

-----------------------------------------------------------------------------
-- ЗАГРУЗКА ПРИ СТАРТЕ
-----------------------------------------------------------------------------
hook.Add("Initialize", "SCPF_WhitelistLoad", function()
	SCPF.Whitelist.Load()
end)
