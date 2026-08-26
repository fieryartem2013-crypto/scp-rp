--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — shared.lua
	Точка входа гейммода. База: sandbox (DarkRP не требуется).
------------------------------------------------------------------------------]]

SCPF = SCPF or {}

DeriveGamemode("sandbox")

GM.Name    = "SCP RP | DarkRP"
GM.Folder  = "gamemodes/darkrp"
GM.Author  = "Arena.ai"
GM.Version = "1.0.4"
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

-- На dedicated-сервере клиент качает эти файлы, поэтому перечисляем явно.
-- include() сам вызывает AddCSLuaFile, но только для файлов, которые он
-- действительно подключает на сервере — клиентские (cl_*) нужно добавлять руками.
if SERVER then
	for _, f in ipairs({
		"framework/sh_config.lua", "framework/sh_lib.lua", "framework/sh_factions.lua",
		"framework/sh_departments.lua", "framework/sh_jobs.lua", "framework/sh_whitelist.lua",
		"framework/sh_characters.lua", "framework/sh_schema.lua",
		"cl_init.lua", "cl_fonts.lua", "cl_notify.lua", "cl_hud.lua",
		"cl_f4.lua", "cl_scoreboard.lua", "cl_charmenu.lua",
	}) do
		AddCSLuaFile(f)
	end
end

if not SCPF.Version then
	MsgC(Color(255, 80, 80), "[SCP RP | DarkRP] ОШИБКА: ", color_white,
		"фреймворк не загрузился (framework/sh_config.lua). Проверь структуру папок.\n")
else
	MsgC(Color(80, 140, 220), "[SCP RP | DarkRP] ", color_white,
		"shared.lua загружен. Версия ", SCPF.Version, "\n")
end
