--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sv_admin.lua
	Админ-действия: вайтлист, деньги, телепорт, выдача предметов.
------------------------------------------------------------------------------]]

SCPF.AddCommand("/wl", {
	desc = "Вайтлист. /wl add|remove|list <id> [steamid64]",
	console = "wl",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply, args)
		local action = args[1]
		local id = args[2]
		local sid = args[3]
		if action == "add" and id and sid then
			SCPF.Whitelist.Add(id, sid)
			SCPF.Notify(ply, "Добавлен в вайтлист " .. id .. ": " .. sid, 5, SCPF.NotifyTypes.SUCCESS)
		elseif action == "remove" and id and sid then
			SCPF.Whitelist.Remove(id, sid)
			SCPF.Notify(ply, "Удалён из " .. id .. ": " .. sid, 5, SCPF.NotifyTypes.SUCCESS)
		elseif action == "list" and id then
			local list = SCPF.Whitelist.List(id)
			SCPF.Notify(ply, id .. ": " .. (#list > 0 and table.concat(list, ", ") or "пусто"), 10, SCPF.NotifyTypes.INFO)
		else
			SCPF.Notify(ply, "/wl add|remove|list <id> [steamid64]", 6, SCPF.NotifyTypes.ERROR)
		end
	end,
})

SCPF.AddCommand("/setmoney", {
	desc = "Выдать деньги (админ). /setmoney <ник> <сумма>",
	console = "setmoney",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply, args)
		local target = SCPF.FindPlayer(args[1])
		local amount = math.floor(tonumber(args[2]) or 0)
		if not target then SCPF.Notify(ply, "Игрок не найден", 4, SCPF.NotifyTypes.ERROR) return end
		SCPF.Money.Add(target, amount)
		SCPF.Notify(target, "Админ выдал " .. amount .. " " .. SCPF.Currency, 5, SCPF.NotifyTypes.SUCCESS)
	end,
})

SCPF.AddCommand("/bring", {
	desc = "Притянуть игрока (админ)",
	console = "bring",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply, args)
		local target = SCPF.FindPlayer(args[1])
		if not target then SCPF.Notify(ply, "Игрок не найден", 4, SCPF.NotifyTypes.ERROR) return end
		target:SetPos(ply:GetPos() + ply:GetAimVector() * 80 + Vector(0, 0, 10))
	end,
})

SCPF.AddCommand("/goto", {
	desc = "Телепортироваться к игроку (админ)",
	console = "goto",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply, args)
		local target = SCPF.FindPlayer(args[1])
		if not target then SCPF.Notify(ply, "Игрок не найден", 4, SCPF.NotifyTypes.ERROR) return end
		ply:SetPos(target:GetPos() + Vector(0, 0, 10))
	end,
})

SCPF.AddCommand("/giveweapon", {
	desc = "Выдать оружие (админ). /giveweapon <ник> <класс>",
	console = "giveweapon",
	perm = function(ply) return ply:IsAdmin() end,
	run = function(ply, args)
		local target = SCPF.FindPlayer(args[1])
		local class = args[2]
		if not target or not class then SCPF.Notify(ply, "/giveweapon <ник> <класс>", 4, SCPF.NotifyTypes.ERROR) return end
		target:Give(class)
		SCPF.Notify(target, "Админ выдал " .. class, 4, SCPF.NotifyTypes.SUCCESS)
	end,
})

-----------------------------------------------------------------------------
-- NET: АДМИН-ДЕЙСТВИЯ ИЗ F4
-----------------------------------------------------------------------------
net.Receive(SCPF.Net.AdminAction, function(_, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	local action = net.ReadString()
	local data = net.ReadTable()

	if action == "wl_add" then
		SCPF.Whitelist.Add(data.id, data.sid)
		SCPF.Notify(ply, "Вайтлист: добавлен " .. data.sid .. " → " .. data.id, 5, SCPF.NotifyTypes.SUCCESS)
	elseif action == "wl_remove" then
		SCPF.Whitelist.Remove(data.id, data.sid)
		SCPF.Notify(ply, "Вайтлист: удалён " .. data.sid, 5, SCPF.NotifyTypes.SUCCESS)
	elseif action == "setmoney" then
		local target = SCPF.FindPlayer(data.nick)
		if target then SCPF.Money.Add(target, data.amount) end
	elseif action == "breach" then
		SCPF.StartBreach(data.level, "запущено из админ-панели")
	elseif action == "spawnscp" then
		SCPF.SpawnSCP(data.id)
	elseif action == "setspawn" then
		SCPF.Spawns.Data[data.key] = SCPF.Spawns.Data[data.key] or {}
		SCPF.Spawns.Data[data.key][#SCPF.Spawns.Data[data.key] + 1] = {pos = ply:GetPos(), ang = ply:GetAngles()}
		SCPF.Spawns.Save()
		SCPF.SyncSpawns(ply)
		SCPF.Notify(ply, "Точка спавна: " .. data.key, 5, SCPF.NotifyTypes.SUCCESS)
	end
end)
