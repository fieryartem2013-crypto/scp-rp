--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sv_doors.lua
	Двери: покупка, замки, уровни доступа (keycard).
------------------------------------------------------------------------------]]

function SCPF.BuyDoor(ply, door)
	if not IsValid(door) or not door:IsDoor() then return false, "Это не дверь" end
	if door.SCPFOwner and door.SCPFOwner ~= ply then
		return false, "Дверь уже занята"
	end
	local price = 300
	if SCPF.Money.Get(ply) < price then
		return false, "Нужно " .. price .. " " .. SCPF.Currency
	end
	SCPF.Money.Take(ply, price)
	door.SCPFOwner = ply
	door:SetNWString("scpf_owner", ply:Nick())
	SCPF.Notify(ply, "Дверь приобретена за " .. price .. " " .. SCPF.Currency, 5, SCPF.NotifyTypes.SUCCESS)
	return true
end

function SCPF.SellDoor(ply, door)
	if not IsValid(door) or door.SCPFOwner ~= ply then return false, "Это не ваша дверь" end
	SCPF.Money.Add(ply, 150)
	door.SCPFOwner = nil
	door:SetNWString("scpf_owner", "")
	door:Fire("unlock")
	SCPF.Notify(ply, "Дверь продана. Возврат 150 " .. SCPF.Currency, 5, SCPF.NotifyTypes.SUCCESS)
	return true
end

function SCPF.ToggleDoorLock(ply, door)
	if not IsValid(door) or not door:IsDoor() then return end
	-- Проверка уровня доступа
	local job = SCPF.JobByTeam(ply:Team())
	local clearance = (job and job.clearance) or 0
	local required = door.SCPFRequiredClearance or 0
	if door.SCPFOwner ~= ply and clearance < required and not ply:IsAdmin() then
		SCPF.Notify(ply, "Требуется уровень доступа " .. required .. ". У вас: " .. clearance, 5, SCPF.NotifyTypes.ERROR)
		return false, "Недостаточно прав доступа"
	end
	door.SCPFLocked = not door.SCPFLocked
	door:Fire(door.SCPFLocked and "lock" or "unlock")
	ply:EmitSound(door.SCPFLocked and "doors/door_latch3.wav" or "doors/door_latch1.wav", 70)
	SCPF.Notify(ply, door.SCPFLocked and "Дверь заперта" or "Дверь открыта", 2, SCPF.NotifyTypes.INFO)
	return true
end

-----------------------------------------------------------------------------
-- БИНДЫ / КОМАНДЫ
-----------------------------------------------------------------------------
hook.Add("PlayerBindPress", "SCPF_DoorUse", function(ply, bind, pressed)
	if not pressed or bind ~= "+use" then return end
	local tr = util.TraceLine({start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 85, filter = ply})
	if IsValid(tr.Entity) and tr.Entity:IsDoor() then
		SCPF.ToggleDoorLock(ply, tr.Entity)
	end
end)

SCPF.AddCommand("/buydoor", {
	desc = "Купить дверь (300 " .. SCPF.Currency .. ")",
	console = "buydoor",
	run = function(ply)
		local tr = util.TraceLine({start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 100, filter = ply})
		local ok, msg = SCPF.BuyDoor(ply, tr.Entity)
		if not ok then SCPF.Notify(ply, msg, 5, SCPF.NotifyTypes.ERROR) end
	end,
})

SCPF.AddCommand("/selldoor", {
	desc = "Продать свою дверь (150 " .. SCPF.Currency .. ")",
	console = "selldoor",
	run = function(ply)
		local tr = util.TraceLine({start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 100, filter = ply})
		local ok, msg = SCPF.SellDoor(ply, tr.Entity)
		if not ok then SCPF.Notify(ply, msg, 5, SCPF.NotifyTypes.ERROR) end
	end,
})

hook.Add("PlayerDisconnected", "SCPF_DoorCleanup", function(ply)
	for _, ent in ipairs(ents.GetAll()) do
		if ent.SCPFOwner == ply then
			ent.SCPFOwner = nil
			ent:SetNWString("scpf_owner", "")
		end
	end
end)
