--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — cl_init.lua
	Клиентская точка входа.
------------------------------------------------------------------------------]]

SCPF = SCPF or {}

include("framework/sh_config.lua")
include("framework/sh_lib.lua")
include("framework/sh_factions.lua")
include("framework/sh_departments.lua")
include("framework/sh_jobs.lua")
include("framework/sh_whitelist.lua")
include("framework/sh_characters.lua")
include("framework/sh_schema.lua")

include("cl_fonts.lua")
include("cl_notify.lua")
include("cl_hud.lua")
include("cl_f4.lua")
include("cl_scoreboard.lua")
include("cl_charmenu.lua")

-----------------------------------------------------------------------------
-- F4 → меню
-----------------------------------------------------------------------------
function GM:ShowSpare2()
	hook.Run("SCPF_ToggleF4")
end

hook.Add("PlayerBindPress", "SCPF_F4Bind", function(ply, bind, pressed)
	if pressed and bind == "gm_showspare2" then
		hook.Run("SCPF_ToggleF4")
		return true
	end
end)

MsgC(Color(80, 140, 220), "[SCP Framework] ", color_white, "Клиент загружен. F4 — меню.\n")
