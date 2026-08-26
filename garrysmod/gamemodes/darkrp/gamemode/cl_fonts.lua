--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — cl_fonts.lua
------------------------------------------------------------------------------]]

local function createFonts()
	surface.CreateFont("SCPF_Title",  {font = "Roboto", size = 34, weight = 800})
	surface.CreateFont("SCPF_Big",    {font = "Roboto", size = 26, weight = 700})
	surface.CreateFont("SCPF_Medium", {font = "Roboto", size = 19, weight = 500})
	surface.CreateFont("SCPF_Small",  {font = "Roboto", size = 15, weight = 500})
	surface.CreateFont("SCPF_Tiny",   {font = "Roboto", size = 12, weight = 400})
end
createFonts()
hook.Add("OnReloaded", "SCPF_Fonts", createFonts)
