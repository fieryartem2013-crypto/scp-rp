--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — cl_scoreboard.lua
	Скорборд (TAB): сортировка по фракциям/джобам.
------------------------------------------------------------------------------]]

local C = SCPF.Colors

function GM:ScoreboardShow()
	if IsValid(SCPF.Scoreboard) then
		SCPF.Scoreboard:SetVisible(true)
		SCPF.Scoreboard:MakePopup()
		SCPF.Scoreboard:Refresh()
		return
	end

	local sw, sh = ScrW(), ScrH()
	local w, h = math.min(800, sw - 100), math.min(620, sh - 100)
	local f = vgui.Create("DFrame")
	f:SetSize(w, h) f:Center() f:SetTitle("") f:ShowCloseButton(false) f:SetDraggable(false) f:MakePopup()
	f.Paint = function(s, w2, h2)
		surface.SetDrawColor(C.bg) surface.DrawRect(0, 0, w2, h2)
		surface.SetDrawColor(C.accent) surface.DrawRect(0, 0, w2, 4)
	end
	SCPF.Scoreboard = f

	local title = vgui.Create("DLabel", f)
	title:SetPos(20, 14) title:SetFont("SCPF_Title") title:SetTextColor(C.accent)
	title:SetText("ЗОНА — ПЕРСОНАЛ") title:SizeToContents()

	local list = vgui.Create("DScrollPanel", f)
	list:SetPos(12, 70) list:SetSize(w - 24, h - 82)
	f.List = list

	function f:Refresh()
		list:Clear()
		local players = player.GetAll()
		table.sort(players, function(a, b)
			local ja, jb = SCPF.JobByTeam(a:Team()), SCPF.JobByTeam(b:Team())
			return (ja and ja.sort or 99) < (jb and jb.sort or 99)
		end)
		for _, p in ipairs(players) do
			local job = SCPF.JobByTeam(p:Team())
			local row = vgui.Create("DPanel", list)
			row:SetTall(44) row:Dock(TOP) row:DockMargin(0, 0, 0, 4)
			row.Paint = function(s, w2, h2)
				surface.SetDrawColor(C.panel2) surface.DrawRect(0, 0, w2, h2)
				surface.SetDrawColor(job and job.color or C.dim) surface.DrawRect(0, 0, 4, h2)
			end
			local av = vgui.Create("AvatarImage", row)
			av:SetPos(8, 6) av:SetSize(32, 32) av:SetPlayer(p, 32)
			local nick = vgui.Create("DLabel", row)
			nick:SetPos(48, 4) nick:SetFont("SCPF_Medium") nick:SetTextColor(C.text)
			nick:SetText(p:Nick() .. (p.SCPF_Arrested and "  [ЗАДЕРЖАН]" or "")) nick:SizeToContents()
			local jl = vgui.Create("DLabel", row)
			jl:SetPos(48, 24) jl:SetFont("SCPF_Tiny") jl:SetTextColor(job and job.color or C.dim)
			jl:SetText(job and job.name or "—") jl:SizeToContents()
			local ping = vgui.Create("DLabel", row)
			ping:SetPos(w - 90, 12) ping:SetFont("SCPF_Small") ping:SetTextColor(C.dim)
			ping:SetText("Пинг: " .. p:Ping()) ping:SizeToContents()
		end
	end

	f:Refresh()
	timer.Create("SCPF_SBRefresh", 2, 0, function()
		if IsValid(SCPF.Scoreboard) and SCPF.Scoreboard:IsVisible() then SCPF.Scoreboard:Refresh() end
	end)
end

function GM:ScoreboardHide()
	if IsValid(SCPF.Scoreboard) then SCPF.Scoreboard:SetVisible(false) end
end
