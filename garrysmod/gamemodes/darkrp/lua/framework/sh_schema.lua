--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sh_schema.lua
	Точка расширения схемы (Helix-style).
	Схема может переопределять хуки через SCPF.Schema:Hook("Name", fn).
------------------------------------------------------------------------------]]

SCPF.Schema = SCPF.Schema or {}
SCPF.Schema.Hooks = SCPF.Schema.Hooks or {}

-----------------------------------------------------------------------------
-- ДОСТУПНЫЕ ХУКИ СХЕМЫ
--  OnCharacterCreated(ply, char)
--  OnJobChanged(ply, oldJob, newJob)
--  CanChangeJob(ply, job) -> bool, reason
--  OnBreachStart(level)
--  OnBreachEnd(success)
--  PlayerArrested(ply, target, time)
--  OnPlayerDeath(ply, attacker)
--  GetSpawnPoint(ply, job) -> Vector or nil
-----------------------------------------------------------------------------

-- Пример переопределения (закомментировано):
--[[
SCPF.Schema:Hook("CanChangeJob", function(self, ply, job)
	if job.id == "o5_rep" and not ply:IsSuperAdmin() then
		return false, "Только для высшего состава"
	end
end)
]]

-- Вызов хука схемы с фолбэком на default
function SCPF.CallSchemaHook(name, ...)
	local fn = SCPF.Schema.Hooks[name]
	if fn then return fn(SCPF.Schema, ...) end
end
