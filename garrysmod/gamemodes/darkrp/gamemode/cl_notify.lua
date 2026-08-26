--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — cl_notify.lua
	Уведомления (Helix-style, сверху справа).
------------------------------------------------------------------------------]]

SCPF.Notifications = {}

net.Receive(SCPF.Net.Notify, function()
	local text = net.ReadString()
	local kind = net.ReadString()
	local len = net.ReadUInt(5)
	table.insert(SCPF.Notifications, 1, {text = text, kind = kind, time = CurTime() + len})
	if #SCPF.Notifications > 6 then table.remove(SCPF.Notifications) end
end)

hook.Add("HUDPaint", "SCPF_Notifications", function()
	local sw = ScrW()
	local y = 100
	for i = #SCPF.Notifications, 1, -1 do
		local n = SCPF.Notifications[i]
		if CurTime() > n.time then
			table.remove(SCPF.Notifications, i)
		else
			local col = n.kind == "error" and SCPF.Colors.bad
				or n.kind == "success" and SCPF.Colors.ok
				or n.kind == "warn" and SCPF.Colors.warn
				or SCPF.Colors.text
			surface.SetFont("SCPF_Medium")
			local tw, th = surface.GetTextSize(n.text)
			local px = sw - tw - 56
			local fade = math.min(1, (n.time - CurTime()) * 2)
			surface.SetDrawColor(0, 0, 0, 170 * fade)
			surface.DrawRect(px - 12, y, tw + 24, th + 12)
			surface.SetDrawColor(col.r, col.g, col.b, 230 * fade)
			surface.DrawRect(px - 12, y, 4, th + 12)
			draw.SimpleText(n.text, "SCPF_Medium", px, y + 6, Color(col.r, col.g, col.b, 255 * fade))
			y = y + th + 20
		end
	end
end)
