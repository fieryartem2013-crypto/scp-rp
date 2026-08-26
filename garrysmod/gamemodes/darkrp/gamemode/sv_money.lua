--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sv_money.lua
	Экономика: кошелёк, дроп, подбор, переводы.
------------------------------------------------------------------------------]]

SCPF.Money = SCPF.Money or {}

function SCPF.Money.Get(ply)
	if not IsValid(ply) then return 0 end
	ply.SCPF = ply.SCPF or {}
	return ply.SCPF.Money or SCPF.StartingMoney
end

function SCPF.Money.Set(ply, amount)
	if not IsValid(ply) then return end
	ply.SCPF = ply.SCPF or {}
	ply.SCPF.Money = math.Clamp(math.floor(amount), 0, SCPF.MaxMoney)
	if ply.SCPF_Char then ply.SCPF_Char.money = ply.SCPF.Money end
	net.Start(SCPF.Net.Money)
	net.WriteUInt(ply.SCPF.Money, 32)
	net.Send(ply)
end

function SCPF.Money.Add(ply, amount)
	SCPF.Money.Set(ply, SCPF.Money.Get(ply) + math.floor(amount))
end

function SCPF.Money.Take(ply, amount)
	amount = math.floor(amount)
	if SCPF.Money.Get(ply) < amount then
		return false, "Недостаточно средств. Нужно " .. amount .. " " .. SCPF.Currency
	end
	SCPF.Money.Set(ply, SCPF.Money.Get(ply) - amount)
	return true
end



-----------------------------------------------------------------------------
-- ДРОП / ПОДБОР
-----------------------------------------------------------------------------
SCPF.AddCommand("/dropmoney", {
	desc = "Выбросить деньги. /dropmoney <сумма>",
	console = "dropmoney",
	run = function(ply, args)
		local amount = math.floor(tonumber(args[1]) or 0)
		if amount <= 0 then SCPF.Notify(ply, "Сумма должна быть больше нуля", 4, SCPF.NotifyTypes.ERROR) return end
		local ok, err = SCPF.Money.Take(ply, amount)
		if not ok then SCPF.Notify(ply, err, 4, SCPF.NotifyTypes.ERROR) return end

		local ent = ents.Create("scpf_money")
		ent:SetPos(ply:GetShootPos() + ply:GetAimVector() * 40)
		ent.SCPFAmount = amount
		ent:Spawn()
		ent:Activate()
	end,
})

SCPF.AddCommand("/give", {
	desc = "Перевести деньги. /give <ник> <сумма>",
	console = "give",
	run = function(ply, args)
		local target = SCPF.FindPlayer(args[1])
		local amount = math.floor(tonumber(args[2]) or 0)
		if not target then SCPF.Notify(ply, "Игрок не найден", 4, SCPF.NotifyTypes.ERROR) return end
		if amount <= 0 then SCPF.Notify(ply, "Сумма должна быть больше нуля", 4, SCPF.NotifyTypes.ERROR) return end
		local ok, err = SCPF.Money.Take(ply, amount)
		if not ok then SCPF.Notify(ply, err, 4, SCPF.NotifyTypes.ERROR) return end
		SCPF.Money.Add(target, amount)
		SCPF.Notify(ply, "Переведено " .. amount .. " " .. SCPF.Currency .. " игроку " .. target:Nick(), 5, SCPF.NotifyTypes.SUCCESS)
	end,
})

-----------------------------------------------------------------------------
-- ЭНТИТИ ДЕНЕГ
-----------------------------------------------------------------------------
local MONEY = {}
MONEY.Type = "anim"

function MONEY:Initialize()
	self:SetModel("models/props/cs_assault/money.mdl")
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self.SCPCreated = CurTime()
end

function MONEY:StartTouch(ent)
	if not ent:IsPlayer() or ent.SCPF_Arrested then return end
	if CurTime() - (self.SCPCreated or 0) < 1 then return end
	SCPF.Money.Add(ent, self.SCPFAmount or 1)
	SCPF.Notify(ent, "+" .. (self.SCPFAmount or 1) .. " " .. SCPF.Currency, 3, SCPF.NotifyTypes.SUCCESS)
	self:Remove()
end

scripted_ents.Register(MONEY, "scpf_money")
