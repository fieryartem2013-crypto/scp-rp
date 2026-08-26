--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sh_factions.lua
	Фракции: Фонд, МОГ, ГОИ, SCP.
------------------------------------------------------------------------------]]

SCPF.Factions = {}

local function faction(id, data)
	data.id = id
	SCPF.Factions[id] = data
	return data
end

-----------------------------------------------------------------------------
-- ФОНД SCP
-----------------------------------------------------------------------------
faction("foundation", {
	name = "Фонд SCP",
	short = "ФОНД",
	color = Color(70, 110, 180),
	desc = "Фонд SCP — тайная организация, содержащая аномалии.Secure. Contain. Protect.",
	default = true,        -- доступен без вайтлиста
	departments = true,    -- есть департаменты
	keycard = true,
})

-----------------------------------------------------------------------------
-- МОГ (часть Фонда, но отдельная фракция для спавнов/формы)
-----------------------------------------------------------------------------
faction("mtf", {
	name = "Мобильные Оперативные Группы",
	short = "МОГ",
	color = Color(40, 70, 140),
	desc = "Элитные подразделения Фонда для реагирования на угрозы и восстановления содержания.",
	default = false,
	whitelist = true,
	keycard = true,
	clearance = 4,
})

-----------------------------------------------------------------------------
-- ГОК
-----------------------------------------------------------------------------
faction("goc", {
	name = "Глобальная Оккультная Коалиция",
	short = "ГОК",
	color = Color(60, 140, 160),
	desc = "Коалиция из 108 оккультных организаций. Задача: уничтожение аномалий, а не содержание.",
	default = false,
	whitelist = true,
	goi = true,
	hostile = {"foundation", "mtf", "chaos", "serpent", "mcd"},
})

-----------------------------------------------------------------------------
-- ДЛАНЬ ЗМЕЯ
-----------------------------------------------------------------------------
faction("serpent", {
	name = "Длань Змея",
	short = "ДЛАНЬ",
	color = Color(80, 150, 80),
	desc = "Сеть аномальных активистов. Освобождают аномалии и защищают их от Фонда и ГОК.",
	default = false,
	whitelist = true,
	goi = true,
	hostile = {"foundation", "mtf", "goc"},
})

-----------------------------------------------------------------------------
-- МАРШАЛ, КАРТЕР И ДАРК
-----------------------------------------------------------------------------
faction("mcd", {
	name = "Маршал, Картер и Дарк Лтд.",
	short = "МКиД",
	color = Color(160, 130, 60),
	desc = "Закрытый аукционный дом. Продаёт аномалии коллекционерам. Нейтрален ко всем, кроме конкурентов.",
	default = false,
	whitelist = true,
	goi = true,
	hostile = {"chaos"},
})

-----------------------------------------------------------------------------
-- ПОВСТАНЦЫ ХАОСА
-----------------------------------------------------------------------------
faction("chaos", {
	name = "Повстанцы Хаоса",
	short = "ХАОС",
	color = Color(150, 60, 50),
	desc = "Отколовшаяся ячейка Фонда. Используют аномалии как оружие. Террористы по классификации Фонда.",
	default = false,
	whitelist = true,
	goi = true,
	hostile = {"foundation", "mtf", "goc", "mcd"},
})

-----------------------------------------------------------------------------
-- SCP
-----------------------------------------------------------------------------
faction("scp", {
	name = "Аномалии SCP",
	short = "SCP",
	color = Color(160, 60, 60),
	desc = "Содержащиеся аномальные объекты. Играются по правилам объекта.",
	default = false,
	whitelist = true,
	scp = true,
	hostile = {"foundation", "mtf", "goc", "chaos", "serpent", "mcd"},
})

-----------------------------------------------------------------------------
-- ХЕЛПЕРЫ
-----------------------------------------------------------------------------
function SCPF.GetFaction(id)
	return SCPF.Factions[id]
end

function SCPF.DefaultFaction()
	for id, f in pairs(SCPF.Factions) do
		if f.default then return id end
	end
	return "foundation"
end

function SCPF.IsHostile(factionA, factionB)
	if not factionA or not factionB then return false end
	if factionA == factionB then return false end
	local fa = SCPF.Factions[factionA]
	if not fa or not fa.hostile then return false end
	for _, h in ipairs(fa.hostile) do
		if h == factionB then return true end
	end
	return false
end

function SCPF.FactionJobs(factionID)
	local out = {}
	for _, job in pairs(SCPF.Jobs or {}) do
		if job.faction == factionID then out[#out + 1] = job end
	end
	table.sort(out, function(a, b) return (a.sort or 99) < (b.sort or 99) end)
	return out
end
