--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — cl_hud.lua
	HUD: HP, броня, деньги, джоба, патроны, брич, арест.
------------------------------------------------------------------------------]]

local C = SCPF.Colors

local function bar(x, y, w, h, frac, col)
	surface.SetDrawColor(0, 0, 0, 160)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(col)
	surface.DrawRect(x + 2, y + 2, (w - 4) * math.Clamp(frac, 0, 1), h - 4)
end

local function txt(text, x, y, font, col, align)
	draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, 180), align or TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(text, font, x, y, col or C.text, align or TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

SCPF.ClientMoney = 0
net.Receive(SCPF.Net.Money, function() SCPF.ClientMoney = net.ReadUInt(32) end)

SCPF.ClientBreach = {active = false, level = 0}
net.Receive(SCPF.Net.Breach, function()
	SCPF.ClientBreach.active = net.ReadBool()
	SCPF.ClientBreach.level = net.ReadUInt(4)
end)

LocalPlayer().SCPF_Arrested = false
net.Receive(SCPF.Net.Arrested, function()
	LocalPlayer().SCPF_Arrested = net.ReadBool()
	LocalPlayer().SCPF_ArrestTime = net.ReadBool() and (CurTime() + net.ReadUInt(16)) or 0
end)

hook.Add("HUDPaint", "SCPF_HUD", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end
	local sw, sh = ScrW(), ScrH()

	-- HP / Armor
	local bx, by, bw = 24, sh - 92, 260
	local hp = math.max(0, ply:Health())
	bar(bx, by, bw, 20, hp / ply:GetMaxHealth(), hp > ply:GetMaxHealth() * 0.5 and C.ok or C.bad)
	txt("HP " .. hp, bx + 8, by + 3, "SCPF_Small", C.text)
	if ply:Armor() > 0 then
		bar(bx, by + 26, bw, 20, ply:Armor() / SCPF.MaxArmor, C.accent)
		txt("БРОНЯ " .. ply:Armor(), bx + 8, by + 29, "SCPF_Small", C.text)
	end

	-- Джоба
	local job = SCPF.JobByTeam(ply:Team())
	if job then
		surface.SetDrawColor(job.color)
		surface.DrawRect(bx, by - 28, 4, 22)
		txt(job.name, bx + 12, by - 26, "SCPF_Medium", C.text)
	end

	-- Деньги
	local mtxt = SCPF.ClientMoney .. " " .. SCPF.Currency
	surface.SetFont("SCPF_Big")
	local mw = surface.GetTextSize(mtxt)
	surface.SetDrawColor(0, 0, 0, 160)
	surface.DrawRect(sw - mw - 48, 24, mw + 32, 44)
	surface.SetDrawColor(C.ok)
	surface.DrawRect(sw - mw - 48, 24, 4, 44)
	txt(mtxt, sw - mw - 32, 34, "SCPF_Big", C.ok)

	-- Патроны
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep:GetMaxClip1() > 0 then
		local t = wep:Clip1() .. " / " .. ply:GetAmmoCount(wep:GetPrimaryAmmoType())
		surface.SetFont("SCPF_Big")
		local tw = surface.GetTextSize(t)
		surface.SetDrawColor(0, 0, 0, 160)
		surface.DrawRect(sw - tw - 48, sh - 88, tw + 32, 44)
		txt(t, sw - tw - 32, sh - 78, "SCPF_Big", wep:Clip1() == 0 and C.bad or C.text)
	end

	-- Брич
	if SCPF.ClientBreach.active then
		local pulse = math.abs(math.sin(CurTime() * 3))
		local t = string.format("!!! НАРУШЕНИЕ СОДЕРЖАНИЯ — УРОВЕНЬ %d !!!", SCPF.ClientBreach.level)
		surface.SetFont("SCPF_Title")
		local tw = surface.GetTextSize(t)
		surface.SetDrawColor(120, 0, 0, 140 + pulse * 80)
		surface.DrawRect(sw / 2 - tw / 2 - 20, 60, tw + 40, 44)
		txt(t, sw / 2 - tw / 2, 70, "SCPF_Title", Color(255, 60 + pulse * 120, 60))
	end

	-- Арест
	if ply.SCPF_Arrested then
		local remain = math.max(0, math.ceil((ply.SCPF_ArrestTime or 0) - CurTime()))
		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawRect(0, sh / 2 - 60, sw, 120)
		txt("ВЫ ЗАДЕРЖАНЫ", 0, sh / 2 - 44, "SCPF_Title", C.bad, TEXT_ALIGN_CENTER)
		txt("Осталось: " .. remain .. " сек.   /escape — попытка побега", 0, sh / 2 + 4, "SCPF_Medium", C.dim, TEXT_ALIGN_CENTER)
	end
end)
