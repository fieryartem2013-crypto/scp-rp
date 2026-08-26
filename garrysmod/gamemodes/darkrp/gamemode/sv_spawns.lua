--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sv_spawns.lua
	Точки спавна: по фракциям, джобам, SCP, клетка.
	Хранение: data/scpf/spawns.txt (JSON).
	Админ: /setspawn <faction|job|scp|cell> — ставит точку там, где стоит.
------------------------------------------------------------------------------]]

SCPF.Spawns = SCPF.Spawns or {}
SCPF.Spawns.Data = {}   -- [key] = { {pos=Vector, ang=Angle}, ... }

local SPAWN_FILE = "scpf/spawns.txt"

-----------------------------------------------------------------------------
-- ЗАГРУЗКА / СОХРАНЕНИЕ
-----------------------------------------------------------------------------
function SCPF.Spawns.Load()
	if not file.Exists(SPAWN_FILE, "DATA") then
		SCPF.Spawns.AutoDetect()
		return
	end
	local raw = file.Read(SPAWN_FILE, "DATA")
	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or type(data) ~= "table" then
		SCPF.Spawns.AutoDetect()
		return
	end
	SCPF.Spawns.Data = {}
	for key, list in pairs(data) do
		SCPF.Spawns.Data[key] = {}
		for _, p in ipairs(list) do
			SCPF.Spawns.Data[key][#SCPF.Spawns.Data[key] + 1] = {
				pos = Vector(p.pos[1], p.pos[2], p.pos[3]),
				ang = Angle(p.ang[1], p.ang[2], p.ang[3]),
			}
		end
	end
	SCPF.Log("SPAWNS", "Загружено точек: " .. SCPF.Spawns.Count())
end

function SCPF.Spawns.Save()
	local out = {}
	for key, list in pairs(SCPF.Spawns.Data) do
		out[key] = {}
		for _, p in ipairs(list) do
			out[key][#out[key] + 1] = {
				pos = {p.pos.x, p.pos.y, p.pos.z},
				ang = {p.ang.p, p.ang.y, p.ang.r},
			}
		end
	end
	file.Write(SPAWN_FILE, util.TableToJSON(out, true))
end

function SCPF.Spawns.Count()
	local n = 0
	for _, list in pairs(SCPF.Spawns.Data) do n = n + #list end
	return n
end

-----------------------------------------------------------------------------
-- АВТО-ДЕТЕКТ (если файла нет): info_player_start / deathmatch
-----------------------------------------------------------------------------
function SCPF.Spawns.AutoDetect()
	SCPF.Spawns.Data = {default = {}, cell = {}, scp = {}}
	for _, ent in ipairs(ents.FindByClass("info_player_start")) do
		SCPF.Spawns.Data.default[#SCPF.Spawns.Data.default + 1] = {pos = ent:GetPos(), ang = ent:GetAngles()}
	end
	for _, ent in ipairs(ents.FindByClass("info_player_deathmatch")) do
		SCPF.Spawns.Data.default[#SCPF.Spawns.Data.default + 1] = {pos = ent:GetPos(), ang = ent:GetAngles()}
	end
	if #SCPF.Spawns.Data.default == 0 then
		SCPF.Spawns.Data.default[1] = {pos = Vector(0, 0, 64), ang = Angle(0, 0, 0)}
	end
	-- Клетка: рядом со спавном
	local base = SCPF.Spawns.Data.default[1].pos
	SCPF.Spawns.Data.cell[1] = {pos = base + Vector(-300, -400, 0), ang = Angle(0, 0, 0)}
	-- SCP: случайные дальние точки
	local center = Vector(0, 0, 0)
	for _, p in ipairs(SCPF.Spawns.Data.default) do center = center + p.pos end
	center = center / #SCPF.Spawns.Data.default
	for _, ent in ipairs(ents.GetAll()) do
		if ent:IsInWorld() and ent:GetClass():StartWith("prop_") and ent:GetPos():Distance(center) > 1200 then
			if math.random(1, 30) == 1 then
				SCPF.Spawns.Data.scp[#SCPF.Spawns.Data.scp + 1] = {pos = ent:GetPos() + Vector(0, 0, 40), ang = Angle(0, 0, 0)}
			end
		end
	end
	if #SCPF.Spawns.Data.scp == 0 then
		SCPF.Spawns.Data.scp[1] = {pos = center + Vector(700, 700, 64), ang = Angle(0, 0, 0)}
	end
	SCPF.Log("SPAWNS", "Авто-детект: " .. SCPF.Spawns.Count() .. " точек")
end

-----------------------------------------------------------------------------
-- ПОИСК ТОЧКИ
-----------------------------------------------------------------------------
function SCPF.Spawns.Find(key)
	local list = SCPF.Spawns.Data[key]
	if not list or #list == 0 then
		list = SCPF.Spawns.Data.default
	end
	if not list or #list == 0 then return nil end
	local p = list[math.random(#list)]
	return p.pos
end

-- Выбор спавна для игрока с учётом джобы/фракции
function GM:PlayerSelectSpawn(ply)
	local ent = self.BaseClass.PlayerSelectSpawn(self, ply)
	local job = SCPF.JobByTeam(ply:Team())
	local pos

	-- Хук схемы
	pos = SCPF.CallSchemaHook("GetSpawnPoint", ply, job)

	-- По джобе
	if not pos and job then pos = SCPF.Spawns.Find("job_" .. job.id) end
	-- По фракции
	if not pos and job then pos = SCPF.Spawns.Find("faction_" .. job.faction) end
	-- Общий
	if not pos then pos = SCPF.Spawns.Find("default") end

	if pos then
		local tr = util.TraceHull({
			start = pos + Vector(0, 0, 40), endpos = pos + Vector(0, 0, 40),
			mins = Vector(-16, -16, 0), maxs = Vector(16, 16, 72), mask = MASK_SOLID,
		})
		if not tr.Hit then
			ply.SCPF = ply.SCPF or {}
			ply.SCPF.SpawnPos = tr.HitPos
		end
	end
	return ent
end

-----------------------------------------------------------------------------
-- АДМИН: УСТАНОВКА ТОЧЕК
-----------------------------------------------------------------------------
SCPF.AddCommand("/setspawn", {
	desc = "Поставить точку спавна (админ). /setspawn <faction_x|job_x|scp|cell|default>",
	console = "setspawn",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply, args)
		local key = args[1]
		if not key then SCPF.Notify(ply, "Укажи ключ: faction_<id>, job_<id>, scp, cell, default", 6, SCPF.NotifyTypes.ERROR) return end
		SCPF.Spawns.Data[key] = SCPF.Spawns.Data[key] or {}
		SCPF.Spawns.Data[key][#SCPF.Spawns.Data[key] + 1] = {pos = ply:GetPos(), ang = ply:GetAngles()}
		SCPF.Spawns.Save()
		SCPF.SyncSpawns(ply)
		SCPF.Notify(ply, "Точка спавна добавлена: " .. key .. " (всего " .. #SCPF.Spawns.Data[key] .. ")", 6, SCPF.NotifyTypes.SUCCESS)
	end,
})

SCPF.AddCommand("/delspawn", {
	desc = "Удалить все точки ключа (админ). /delspawn <key>",
	console = "delspawn",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply, args)
		local key = args[1]
		if not key or not SCPF.Spawns.Data[key] then SCPF.Notify(ply, "Ключ не найден", 4, SCPF.NotifyTypes.ERROR) return end
		SCPF.Spawns.Data[key] = nil
		SCPF.Spawns.Save()
		SCPF.SyncSpawns(ply)
		SCPF.Notify(ply, "Точки удалены: " .. key, 5, SCPF.NotifyTypes.SUCCESS)
	end,
})

SCPF.AddCommand("/listspawns", {
	desc = "Список ключей спавнов (админ)",
	console = "listspawns",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply)
		local keys = {}
		for k, v in pairs(SCPF.Spawns.Data) do keys[#keys + 1] = k .. "(" .. #v .. ")" end
		table.sort(keys)
		SCPF.Notify(ply, "Спавны: " .. table.concat(keys, ", "), 12, SCPF.NotifyTypes.INFO)
	end,
})

-----------------------------------------------------------------------------
-- СИНХРОНИЗАЦИЯ С КЛИЕНТОМ
-----------------------------------------------------------------------------
function SCPF.SyncSpawns(ply)
	if not IsValid(ply) then return end
	local out = {}
	for k, v in pairs(SCPF.Spawns.Data) do out[k] = #v end
	net.Start(SCPF.Net.SpawnPoints)
	net.WriteTable(out)
	net.Send(ply)
end

net.Receive(SCPF.Net.SetSpawn, function(_, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	local key = net.ReadString()
	if not key or #key > 64 then return end
	SCPF.Spawns.Data[key] = SCPF.Spawns.Data[key] or {}
	SCPF.Spawns.Data[key][#SCPF.Spawns.Data[key] + 1] = {pos = ply:GetPos(), ang = ply:GetAngles()}
	SCPF.Spawns.Save()
	SCPF.SyncSpawns(ply)
	SCPF.Notify(ply, "Точка добавлена: " .. key, 5, SCPF.NotifyTypes.SUCCESS)
end)
