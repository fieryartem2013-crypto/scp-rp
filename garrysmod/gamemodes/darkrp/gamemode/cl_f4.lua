--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — cl_f4.lua
	F4-меню: Джобы / Спавны / Админка / Помощь.
------------------------------------------------------------------------------]]

local C = SCPF.Colors
SCPF.F4 = SCPF.F4 or {}

local function panel(parent, col, x, y, w, h)
	local p = vgui.Create("DPanel", parent)
	p:SetPos(x, y) p:SetSize(w, h)
	p.Paint = function(s, w2, h2) surface.SetDrawColor(col or C.panel) surface.DrawRect(0, 0, w2, h2) end
	return p
end

local function button(parent, text, x, y, w, h, col, func)
	local b = vgui.Create("DButton", parent)
	b:SetPos(x, y) b:SetSize(w, h) b:SetText("")
	b.col = col or C.accent b.hover = false
	b.Paint = function(s, w2, h2)
		local c = s.hover and Color(s.col.r + 30, s.col.g + 30, s.col.b + 30) or s.col
		surface.SetDrawColor(c) surface.DrawRect(0, 0, w2, h2)
		draw.SimpleText(text, "SCPF_Medium", w2 / 2, h2 / 2, Color(15, 15, 20), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	b.OnCursorEntered = function(s) s.hover = true end
	b.OnCursorExited = function(s) s.hover = false end
	b.DoClick = function() surface.PlaySound("ui/buttonclick.wav") func() end
	return b
end

local function label(parent, text, x, y, font, col, maxw)
	local l = vgui.Create("DLabel", parent)
	l:SetPos(x, y) l:SetFont(font or "SCPF_Medium") l:SetTextColor(col or C.text) l:SetText(text)
	if maxw then l:SetWide(maxw) l:SetWrap(true) l:SetAutoStretchVertical(true) end
	l:SizeToContents()
	return l
end

-----------------------------------------------------------------------------
-- ОКНО
-----------------------------------------------------------------------------
function SCPF.F4.Open()
	if IsValid(SCPF.F4.Frame) then SCPF.F4.Close() return end
	local sw, sh = ScrW(), ScrH()
	local w, h = math.min(1050, sw - 120), math.min(700, sh - 120)

	local f = vgui.Create("DFrame")
	f:SetSize(w, h) f:Center() f:SetTitle("") f:ShowCloseButton(false) f:SetDraggable(true) f:MakePopup()
	f.Paint = function(s, w2, h2)
		surface.SetDrawColor(C.bg) surface.DrawRect(0, 0, w2, h2)
		surface.SetDrawColor(C.accent) surface.DrawRect(0, 0, w2, 4)
	end
	SCPF.F4.Frame = f

	label(f, "SCP FRAMEWORK", 20, 14, "SCPF_Title", C.accent)
	label(f, SCPF.Version .. "  •  Зона", 20, 54, "SCPF_Small", C.dim)
	label(f, SCPF.ClientMoney .. " " .. SCPF.Currency, w - 200, 20, "SCPF_Big", C.ok)
	button(f, "×", w - 44, 12, 32, 32, C.bad, SCPF.F4.Close)

	local tabs = {{id = "jobs", name = "Должности"}, {id = "spawns", name = "Спавны"}, {id = "admin", name = "Админка"}, {id = "help", name = "Помощь"}}
	local sideW = 170
	local content = panel(f, C.panel, sideW + 16, 76, w - sideW - 32, h - 92)
	local sidebar = panel(f, C.panel, 8, 68, sideW, h - 84)
	local current = nil

	local function switch(id)
		if current == id then return end
		current = id
		content:Clear()
		if id == "jobs" then SCPF.F4.TabJobs(content, w - sideW - 48, h - 108)
		elseif id == "spawns" then SCPF.F4.TabSpawns(content, w - sideW - 48, h - 108)
		elseif id == "admin" then SCPF.F4.TabAdmin(content, w - sideW - 48, h - 108)
		elseif id == "help" then SCPF.F4.TabHelp(content, w - sideW - 48, h - 108) end
	end

	for i, t in ipairs(tabs) do
		local b = button(sidebar, t.name, 8, 8 + (i - 1) * 42, sideW - 16, 36, C.panel2, function() switch(t.id) end)
		b.Paint = function(s, w2, h2)
			local active = current == t.id
			surface.SetDrawColor(active and C.accent or (s.hover and C.panel2 or C.panel))
			surface.DrawRect(0, 0, w2, h2)
			draw.SimpleText(t.name, "SCPF_Medium", 12, h2 / 2, active and Color(15, 15, 20) or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
	switch("jobs")
end

function SCPF.F4.Close()
	if IsValid(SCPF.F4.Frame) then SCPF.F4.Frame:Remove() SCPF.F4.Frame = nil end
end

-----------------------------------------------------------------------------
-- ДОЛЖНОСТИ
-----------------------------------------------------------------------------
function SCPF.F4.TabJobs(parent, w, h)
	label(parent, "Должности Зоны", 16, 10, "SCPF_Big", C.text)
	local list = vgui.Create("DScrollPanel", parent)
	list:SetPos(12, 44) list:SetSize(w - 24, h - 56)
	local ply = LocalPlayer()

	for _, job in ipairs(SCPF.AllJobsSorted()) do
		local has = SCPF.Whitelist.ClientHas(job.id) or SCPF.Whitelist.ClientHas(job.faction)
		local card = vgui.Create("DPanel", list)
		card:SetTall(72) card:Dock(TOP) card:DockMargin(0, 0, 0, 6)
		card.Paint = function(s, w2, h2)
			surface.SetDrawColor(ply:Team() == job.team and Color(40, 50, 70) or C.panel2)
			surface.DrawRect(0, 0, w2, h2)
			surface.SetDrawColor(job.color) surface.DrawRect(0, 0, 4, h2)
		end
		label(card, job.name, 16, 6, "SCPF_Medium", job.color)
		label(card, string.format("Зарплата: %d  HP: %d  Броня: %d  Допуск: %d%s",
			job.salary or 0, job.hp or 100, job.armor or 0, job.clearance or 0,
			job.whitelist and "  [ВАЙТЛИСТ]" or ""), 16, 26, "SCPF_Small", C.dim)
		label(card, job.desc, 16, 44, "SCPF_Tiny", C.dim, w - 200)

		local b = button(card, ply:Team() == job.team and "Текущая" or (has and "Выбрать" or "Нет вайтлиста"),
			w - 170, 18, 140, 36, ply:Team() == job.team and C.dim or (has and C.accent or C.bad), function()
			net.Start(SCPF.Net.ChangeJob) net.WriteString(job.id) net.SendToServer()
			timer.Simple(0.2, SCPF.F4.Close)
		end)
		if ply:Team() == job.team or not has then b:SetEnabled(false) end
	end
end

-----------------------------------------------------------------------------
-- СПАВНЫ
-----------------------------------------------------------------------------
function SCPF.F4.TabSpawns(parent, w, h)
	label(parent, "Точки спавна", 16, 10, "SCPF_Big", C.text)
	label(parent, "Админ может ставить точки: faction_<id>, job_<id>, scp, cell, default", 16, 38, "SCPF_Small", C.dim)

	local y = 66
	local keys = {"default", "cell", "scp"}
	for id in pairs(SCPF.Factions) do keys[#keys + 1] = "faction_" .. id end
	for id in pairs(SCPF.Jobs) do keys[#keys + 1] = "job_" .. id end

	local list = vgui.Create("DScrollPanel", parent)
	list:SetPos(12, y) list:SetSize(w - 24, h - y - 12)

	for _, key in ipairs(keys) do
		local row = vgui.Create("DPanel", list)
		row:SetTall(32) row:Dock(TOP) row:DockMargin(0, 0, 0, 4)
		row.Paint = function(s, w2, h2) surface.SetDrawColor(C.panel2) surface.DrawRect(0, 0, w2, h2) end
		label(row, key, 12, 6, "SCPF_Small", C.text)
		button(row, "Поставить здесь", w - 170, 4, 150, 24, C.accent, function()
			net.Start(SCPF.Net.SetSpawn) net.WriteString(key) net.SendToServer()
		end)
	end
end

-----------------------------------------------------------------------------
-- АДМИНКА
-----------------------------------------------------------------------------
function SCPF.F4.TabAdmin(parent, w, h)
	local ply = LocalPlayer()
	label(parent, "Админ-панель", 16, 10, "SCPF_Big", C.text)
	if not ply:IsAdmin() then label(parent, "Только для админов", 16, 38, "SCPF_Small", C.warn) return end

	local y = 66
	local function act(text, action, data, col)
		button(parent, text, 16, y, w - 32, 34, col or C.panel2, function()
			net.Start(SCPF.Net.AdminAction) net.WriteString(action) net.WriteTable(data or {}) net.SendToServer()
		end)
		y = y + 42
	end

	act("Запустить нарушение (уровень 1)", "breach", {level = 1}, C.warn)
	act("Запустить нарушение (уровень 3)", "breach", {level = 3}, C.bad)
	act("Остановить нарушение", "endbreach", {}, C.ok)
	act("Заспавнить SCP-173", "spawnscp", {id = "scp_173"}, C.bad)
	act("Заспавнить SCP-096", "spawnscp", {id = "scp_096"}, C.bad)
	act("Заспавнить SCP-682", "spawnscp", {id = "scp_682"}, C.bad)
	act("Точка спавна: default (здесь)", "setspawn", {key = "default"}, C.accent)
	act("Точка спавна: cell (здесь)", "setspawn", {key = "cell"}, C.accent)
	act("Точка спавна: scp (здесь)", "setspawn", {key = "scp"}, C.accent)
end

-----------------------------------------------------------------------------
-- ПОМОЩЬ
-----------------------------------------------------------------------------
function SCPF.F4.TabHelp(parent, w, h)
	label(parent, "Помощь", 16, 10, "SCPF_Big", C.text)
	local lines = {
		"F4 — это меню", "TAB — скорборд", "E — использовать", "F — замок двери",
		"", "=== КОМАНДЫ ===",
		"/job <id> — сменить должность", "/dropmoney <сумма> — выбросить деньги",
		"/give <ник> <сумма> — перевод", "/arrest <ник> [сек] — задержать",
		"/unarrest <ник> — освободить", "/escape — побег", "/buydoor — купить дверь",
		"/announce <текст> — объявление", "/lockdown — локдаун", "/breach <1-3> — нарушение (админ)",
		"/setspawn <key> — точка спавна (админ)", "/wl add|remove|list <id> [sid] — вайтлист (админ)",
	}
	local list = vgui.Create("DScrollPanel", parent)
	list:SetPos(12, 44) list:SetSize(w - 24, h - 56)
	for _, l in ipairs(lines) do
		local lb = vgui.Create("DLabel", list)
		lb:Dock(TOP) lb:SetTall(22) lb:SetFont("SCPF_Small")
		lb:SetTextColor(l:StartWith("===") and C.accent or C.text) lb:SetText(l)
	end
end

-----------------------------------------------------------------------------
-- ОТКРЫТИЕ
-----------------------------------------------------------------------------
hook.Add("SCPF_ToggleF4", "SCPF_F4", function()
	if IsValid(SCPF.F4.Frame) then SCPF.F4.Close() else SCPF.F4.Open() end
end)
concommand.Add("scpf_f4", function() hook.Run("SCPF_ToggleF4") end)
