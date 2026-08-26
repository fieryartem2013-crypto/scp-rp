--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — cl_charmenu.lua
	Создание/редактирование персонажа (Helix-style).
	Открывается автоматически при первом входе или по команде /char.
------------------------------------------------------------------------------]]

local C = SCPF.Colors
SCPF.CharMenu = SCPF.CharMenu or {}

function SCPF.CharMenu.Open(editing)
	if IsValid(SCPF.CharMenu.Frame) then SCPF.CharMenu.Frame:Remove() end

	local sw, sh = ScrW(), ScrH()
	local w, h = 520, 420
	local f = vgui.Create("DFrame")
	f:SetSize(w, h) f:Center() f:SetTitle("") f:ShowCloseButton(false) f:MakePopup()
	f.Paint = function(s, w2, h2)
		surface.SetDrawColor(C.bg) surface.DrawRect(0, 0, w2, h2)
		surface.SetDrawColor(C.accent) surface.DrawRect(0, 0, w2, 4)
	end
	SCPF.CharMenu.Frame = f

	local title = vgui.Create("DLabel", f)
	title:SetPos(20, 16) title:SetFont("SCPF_Title") title:SetTextColor(C.accent)
	title:SetText(editing and "Редактирование персонажа" or "Создание персонажа")
	title:SizeToContents()

	-- Имя
	vgui.Create("DLabel", f):SetPos(20, 70)
	local nameLbl = f:GetChildren()[#f:GetChildren()]
	nameLbl:SetFont("SCPF_Small") nameLbl:SetTextColor(C.dim) nameLbl:SetText("Имя (Формат: «Имя Фамилия»)") nameLbl:SizeToContents()

	local nameEntry = vgui.Create("DTextEntry", f)
	nameEntry:SetPos(20, 92) nameEntry:SetSize(w - 40, 30) nameEntry:SetFont("SCPF_Medium")
	nameEntry:SetPlaceholderText("Иван Петров")
	if editing and SCPF.Characters.GetLocal() then nameEntry:SetText(SCPF.Characters.GetLocal().name or "") end

	-- Описание
	local descLbl = vgui.Create("DLabel", f)
	descLbl:SetPos(20, 134) descLbl:SetFont("SCPF_Small") descLbl:SetTextColor(C.dim)
	descLbl:SetText("Описание (мин. " .. SCPF.DescMinLen .. " символов)") descLbl:SizeToContents()

	local descEntry = vgui.Create("DTextEntry", f)
	descEntry:SetPos(20, 156) descEntry:SetSize(w - 40, 100) descEntry:SetFont("SCPF_Small")
	descEntry:SetMultiline(true) descEntry:SetPlaceholderText("Внешность, характер, биография...")
	if editing and SCPF.Characters.GetLocal() then descEntry:SetText(SCPF.Characters.GetLocal().desc or "") end

	-- Кнопка
	local btn = vgui.Create("DButton", f)
	btn:SetPos(20, h - 60) btn:SetSize(w - 40, 40) btn:SetText("")
	btn.Paint = function(s, w2, h2)
		surface.SetDrawColor(C.accent) surface.DrawRect(0, 0, w2, h2)
		draw.SimpleText(editing and "Сохранить" or "Создать", "SCPF_Medium", w2 / 2, h2 / 2, Color(15, 15, 20), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btn.DoClick = function()
		local name = nameEntry:GetText():Trim()
		local desc = descEntry:GetText():Trim()
		net.Start(SCPF.Net.CharCreate)
		net.WriteString(name)
		net.WriteString(desc)
		net.WriteBool(editing or false)
		net.SendToServer()
		f:Remove()
	end
end

concommand.Add("scpf_char", function() SCPF.CharMenu.Open(true) end)

net.Receive("scpf_openchar", function()
	SCPF.CharMenu.Open(net.ReadBool())
end)
