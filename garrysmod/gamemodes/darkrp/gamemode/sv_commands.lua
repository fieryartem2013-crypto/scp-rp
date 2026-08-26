--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sv_commands.lua
	Система команд: чат (/ и !), консоль (scpf_*), /help, /me.
------------------------------------------------------------------------------]]

SCPF.Commands = SCPF.Commands or {}

function SCPF.AddCommand(cmd, opts)
	opts = opts or {}
	opts.cmd = cmd
	opts.name = opts.name or cmd
	opts.desc = opts.desc or "—"
	opts.console = opts.console or cmd:gsub("^/", "")
	opts.perm = opts.perm or function() return true end
	opts.admin = opts.admin or false
	SCPF.Commands[cmd] = opts
end

function SCPF.RunCommand(ply, cmd, args)
	local c = SCPF.Commands[cmd]
	if not c then return false, "Команда не найдена. /help" end
	if c.admin and not (ply:IsAdmin() or ply:IsSuperAdmin()) then
		return false, "Требуется админ"
	end
	if not c.perm(ply) then
		return false, "Недостаточно полномочий"
	end
	local ok, err = pcall(c.run, ply, args or {})
	if not ok then
		SCPF.Log("CMD", "Ошибка " .. cmd .. ": " .. tostring(err))
		return false, "Ошибка выполнения"
	end
	return true
end

hook.Add("PlayerSay", "SCPF_Chat", function(ply, text)
	if not IsValid(ply) then return end
	local first = string.sub(text, 1, 1)
	if first ~= "/" and first ~= "!" then return end
	local parts = string.Explode(" ", string.sub(text, 2))
	local cmd = "/" .. string.lower(parts[1] or "")
	table.remove(parts, 1)
	local ok, msg = SCPF.RunCommand(ply, cmd, parts)
	if not ok then SCPF.Notify(ply, msg, 5, SCPF.NotifyTypes.ERROR) end
	return ""
end)

local function makeConsole(cmd, opts)
	local name = "scpf_" .. opts.console
	if concommand.GetTable()[name] then return end
	concommand.Add(name, function(ply, _, _, raw)
		if not IsValid(ply) then return end
		local parsed = {}
		for w in string.gmatch(raw or "", "%S+") do parsed[#parsed + 1] = w end
		local ok, msg = SCPF.RunCommand(ply, cmd, parsed)
		if not ok then SCPF.Notify(ply, msg, 5, SCPF.NotifyTypes.ERROR) end
	end, nil, opts.desc)
end

hook.Add("PostGamemodeLoaded", "SCPF_ConsoleCmds", function()
	for cmd, opts in pairs(SCPF.Commands) do makeConsole(cmd, opts) end
	SCPF.Log("CMD", "Зарегистрировано команд: " .. table.Count(SCPF.Commands))
end)

-----------------------------------------------------------------------------
-- ВСТРОЕННЫЕ КОМАНДЫ
-----------------------------------------------------------------------------
SCPF.AddCommand("/help", {
	desc = "Список команд",
	console = "help",
	run = function(ply)
		local names = {}
		for cmd in pairs(SCPF.Commands) do names[#names + 1] = cmd end
		table.sort(names)
		SCPF.Notify(ply, "Команды: " .. table.concat(names, "  "), 15, SCPF.NotifyTypes.INFO)
	end,
})

SCPF.AddCommand("/me", {
	desc = "Действие от третьего лица. /me <текст>",
	console = "me",
	run = function(ply, args)
		local text = table.concat(args, " ")
		if text == "" then return end
		local job = SCPF.JobByTeam(ply:Team())
		SCPF.NotifyAll("* " .. ply:Nick() .. " (" .. (job and job.name or "?") .. ") " .. text, SCPF.NotifyTypes.INFO, 6)
	end,
})

SCPF.AddCommand("/dropweapon", {
	desc = "Выбросить текущее оружие",
	console = "dropweapon",
	run = function(ply)
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass():StartWith("weapon_phys") or wep:GetClass() == "gmod_tool" then
			SCPF.Notify(ply, "Нельзя выбросить", 4, SCPF.NotifyTypes.ERROR) return
		end
		local class = wep:GetClass()
		ply:StripWeapon(class)
		local ent = ents.Create(class)
		if IsValid(ent) then
			ent:SetPos(ply:GetShootPos() + ply:GetAimVector() * 40)
			ent:Spawn()
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then phys:SetVelocity(ply:GetAimVector() * 200) end
		end
	end,
})

-----------------------------------------------------------------------------
-- NET: ВЫПОЛНЕНИЕ КОМАНД ИЗ F4
-----------------------------------------------------------------------------
net.Receive(SCPF.Net.RunCmd, function(_, ply)
	if not IsValid(ply) then return end
	local line = net.ReadString()
	if not line or #line > 200 then return end
	local parts = string.Explode(" ", line)
	local cmd = string.lower(parts[1] or "")
	table.remove(parts, 1)
	if not cmd:StartWith("/") then cmd = "/" .. cmd end
	local ok, msg = SCPF.RunCommand(ply, cmd, parts)
	if not ok then SCPF.Notify(ply, msg, 5, SCPF.NotifyTypes.ERROR) end
end)

-----------------------------------------------------------------------------
-- NET: ПОКУПКА ИЗ F4
-----------------------------------------------------------------------------
net.Receive(SCPF.Net.Buy, function(_, ply)
	if not IsValid(ply) or ply.SCPF_Arrested then return end
	local class = net.ReadString()
	if not class or #class > 64 then return end
	-- Простая покупка: ищем в списке оружия джобы или создаём энтити
	local job = SCPF.JobByTeam(ply:Team())
	if job then
		for _, w in ipairs(job.weapons or {}) do
			if w == class and not ply:HasWeapon(class) then
				ply:Give(class)
				SCPF.Notify(ply, "Выдано: " .. class, 4, SCPF.NotifyTypes.SUCCESS)
				return
			end
		end
	end
	SCPF.Notify(ply, "Недоступно для вашей должности", 4, SCPF.NotifyTypes.ERROR)
end)
