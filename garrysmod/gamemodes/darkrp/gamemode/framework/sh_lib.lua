--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sh_lib.lua
	Ядро: net-слой, хуки схемы, утилиты.
------------------------------------------------------------------------------]]

SCPF = SCPF or {}

-----------------------------------------------------------------------------
-- NET-СЛОЙ
-----------------------------------------------------------------------------
SCPF.Net = {
	-- server -> client
	Money       = "scpf_money",
	Notify      = "scpf_notify",
	JobChanged  = "scpf_jobchanged",
	Breach      = "scpf_breach",
	Arrested    = "scpf_arrested",
	CharLoaded  = "scpf_charloaded",
	SpawnPoints = "scpf_spawnpoints",
	AdminData   = "scpf_admindata",
	-- client -> server
	Buy         = "scpf_buy",
	ChangeJob   = "scpf_changejob",
	RunCmd      = "scpf_runcmd",
	SetSpawn    = "scpf_setspawn",
	AdminAction = "scpf_adminaction",
	CharCreate  = "scpf_charcreate",
}

if SERVER then
	for _, n in pairs(SCPF.Net) do util.AddNetworkString(n) end
end

-----------------------------------------------------------------------------
-- ХУКИ СХЕМЫ (Helix-style)
-- Схема может переопределять поведение через SCPF.Schema:Hook("Name", fn)
-----------------------------------------------------------------------------
SCPF.Schema = SCPF.Schema or {}
SCPF.Schema.Hooks = SCPF.Schema.Hooks or {}

function SCPF.Schema:Hook(name, fn)
	self.Hooks[name] = fn
end

function SCPF.Schema:Call(name, ...)
	local fn = self.Hooks[name]
	if fn then return fn(self, ...) end
end

-- Вызов хука схемы с фолбэком
function SCPF.CallSchemaHook(name, ...)
	return SCPF.Schema:Call(name, ...)
end

-----------------------------------------------------------------------------
-- УВЕДОМЛЕНИЯ
-----------------------------------------------------------------------------
SCPF.NotifyTypes = {
	INFO    = "info",
	SUCCESS = "success",
	ERROR   = "error",
	WARN    = "warn",
}

if SERVER then
	function SCPF.Notify(ply, text, kind, len)
		if not IsValid(ply) then return end
		net.Start(SCPF.Net.Notify)
		net.WriteString(text or "")
		net.WriteString(kind or SCPF.NotifyTypes.INFO)
		net.WriteUInt(math.Clamp(len or 5, 1, 30), 5)
		net.Send(ply)
	end

	function SCPF.NotifyAll(text, kind, len)
		net.Start(SCPF.Net.Notify)
		net.WriteString(text or "")
		net.WriteString(kind or SCPF.NotifyTypes.INFO)
		net.WriteUInt(math.Clamp(len or 5, 1, 30), 5)
		net.Broadcast()
	end
end

-----------------------------------------------------------------------------
-- УТИЛИТЫ
-----------------------------------------------------------------------------
function SCPF.Dist(a, b)
	if not IsValid(a) or not IsValid(b) then return math.huge end
	return a:GetPos():Distance(b:GetPos())
end

function SCPF.IsLooking(ply, target, fov, maxDist)
	if not IsValid(ply) or not IsValid(target) then return false end
	if not ply:Alive() then return false end
	fov = fov or 100
	maxDist = maxDist or 3000
	local toTarget = (target:GetPos() + Vector(0, 0, 40)) - ply:EyePos()
	if toTarget:Length() > maxDist then return false end
	toTarget:Normalize()
	if toTarget:Dot(ply:GetAimVector()) < math.cos(math.rad(fov * 0.5)) then return false end
	local tr = util.TraceLine({
		start = ply:EyePos(),
		endpos = target:GetPos() + Vector(0, 0, 40),
		filter = {ply, target},
		mask = MASK_SOLID_BRUSHONLY,
	})
	return not tr.Hit
end

function SCPF.FindPlayer(query)
	if not query or query == "" then return nil end
	query = string.lower(tostring(query))
	for _, p in ipairs(player.GetAll()) do
		if string.lower(p:Nick()) == query then return p end
	end
	for _, p in ipairs(player.GetAll()) do
		if string.find(string.lower(p:Nick()), query, 1, true) then return p end
	end
	for _, p in ipairs(player.GetAll()) do
		if tostring(p:UserID()) == query or p:SteamID64() == query then return p end
	end
	return nil
end

-- Проверка, что игрок может действовать (жив, не арестован)
function SCPF.CanAct(ply)
	return IsValid(ply) and ply:Alive() and not ply.SCPF_Arrested
end

-----------------------------------------------------------------------------
-- ЦВЕТА ТЕМЫ (Helix-like dark UI)
-----------------------------------------------------------------------------
SCPF.Colors = {
	bg       = Color(18, 20, 26, 250),
	panel    = Color(28, 32, 42, 255),
	panel2   = Color(38, 43, 56, 255),
	accent   = Color(80, 140, 220, 255),   -- синий Фонда
	accent2  = Color(60, 180, 140, 255),   -- бирюзовый
	ok       = Color(90, 200, 120, 255),
	bad      = Color(220, 70, 70, 255),
	warn     = Color(230, 170, 60, 255),
	text     = Color(225, 230, 240, 255),
	dim      = Color(130, 140, 160, 255),
	border   = Color(50, 58, 76, 255),
	foundation = Color(70, 110, 180, 255),
	goi      = Color(180, 80, 80, 255),
	scp      = Color(160, 60, 60, 255),
}

-----------------------------------------------------------------------------
-- ЛОГИРОВАНИЕ
-----------------------------------------------------------------------------
function SCPF.Log(category, text)
	local line = string.format("[SCPF][%s] %s", category, tostring(text))
	if SERVER then
		print(line)
		if not game.IsDedicated() then return end
		-- На dedicated можно писать в файл
		file.Append("scpf_log.txt", os.date("[%Y-%m-%d %H:%M:%S] ") .. line .. "\n")
	end
end
