--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — shared.lua
	Точка входа гейммода. База: sandbox (DarkRP не требуется).
------------------------------------------------------------------------------]]

DeriveGamemode("sandbox")

GM.Name    = "SCP RP | DarkRP"
GM.Folder  = "gamemodes/darkrp"
GM.Author  = "Arena.ai"
GM.Version = "1.0.0"
GM.TeamBased = true

--[[--------------------------------------------------------------------------
	ФРЕЙМВОРК (общие файлы)
--------------------------------------------------------------------------]]
include("framework/sh_config.lua")
include("framework/sh_lib.lua")
include("framework/sh_factions.lua")
include("framework/sh_departments.lua")
include("framework/sh_jobs.lua")
include("framework/sh_whitelist.lua")
include("framework/sh_characters.lua")
include("framework/sh_schema.lua")

if SERVER then
	for _, f in ipairs({
		"framework/sh_config.lua", "framework/sh_lib.lua", "framework/sh_factions.lua",
		"framework/sh_departments.lua", "framework/sh_jobs.lua", "framework/sh_whitelist.lua",
		"framework/sh_characters.lua", "framework/sh_schema.lua",
		"cl_init.lua",
	}) do
		AddCSLuaFile(f)
	end
end

MsgC(Color(80, 140, 220), "[SCP RP | DarkRP] ", color_white,
	"shared.lua загружен. ", SCPF.Version, "\n")
