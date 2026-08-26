--[[----------------------------------------------------------------------------
	SCP FRAMEWORK — sh_jobs.lua
	Все джобы: Фонд, МОГ, ГОИ, SCP.
	Поля: id, name, faction, department, models, weapons, salary, max, hp, armor,
	      clearance, whitelist, sort, desc, commands.
	whitelist = true → нужен вайтлист (data/whitelists/<faction>.txt или job id).
------------------------------------------------------------------------------]]

SCPF.Jobs = {}

local function job(data)
	SCPF.Jobs[data.id] = data
	return data
end

-----------------------------------------------------------------------------
-- ФОНД: ГРАЖДАНСКИЙ ПЕРСОНАЛ (без вайтлиста)
-----------------------------------------------------------------------------
job({
	id = "dclass", name = "Класс-D", faction = "foundation",
	color = Color(210, 120, 40),
	models = {"models/player/Group01/male_01.mdl", "models/player/Group01/male_02.mdl",
		"models/player/Group01/male_04.mdl", "models/player/Group01/male_06.mdl"},
	weapons = {}, salary = 25, max = 0, hp = 100, armor = 0, clearance = 0,
	sort = 1,
	desc = "Расходный персонал из числа заключённых. Участвует в экспериментах с аномалиями.",
	commands = {"/me", "/dropmoney", "/dropweapon"},
})

job({
	id = "janitor", name = "Уборщик", faction = "foundation", department = "engineering",
	color = Color(120, 180, 120),
	models = {"models/player/Group01/male_03.mdl", "models/player/Group01/male_05.mdl"},
	weapons = {"scpf_broom"}, salary = 40, max = 4, hp = 100, armor = 0, clearance = 1,
	sort = 2,
	desc = "Уборка Зоны после экспериментов и инцидентов. Допуск к большинству отсеков.",
	commands = {"/me", "/dropmoney", "/dropweapon"},
})

job({
	id = "guard_junior", name = "Охранник (младший)", faction = "foundation", department = "security",
	color = Color(70, 100, 160),
	models = {"models/player/police.mdl"},
	weapons = {"scpf_pistol", "scpf_baton", "scpf_radio", "scpf_keycard"},
	salary = 70, max = 6, hp = 110, armor = 40, clearance = 2,
	sort = 3,
	desc = "Охрана периметра, конвоирование D-класса, реагирование на инциденты.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/arrest", "/unarrest"},
})

job({
	id = "guard_senior", name = "Охранник (старший)", faction = "foundation", department = "security",
	color = Color(50, 80, 140),
	models = {"models/player/police_fem.mdl"},
	weapons = {"scpf_smg", "scpf_baton", "scpf_radio", "scpf_keycard", "scpf_medkit"},
	salary = 95, max = 3, hp = 120, armor = 60, clearance = 3, whitelist = true,
	sort = 4,
	desc = "Старший состав охраны. Руководит сменами, усиленная экипировка.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/arrest", "/unarrest"},
})

-----------------------------------------------------------------------------
-- ФОНД: ИССЛЕДОВАТЕЛИ (по департаментам, вайтлист)
-----------------------------------------------------------------------------
local researchDepts = {
	{id = "antimemetics", name = "Антимеметика",   color = Color(90, 110, 150)},
	{id = "pataphysics",  name = "Патафизика",     color = Color(150, 100, 160)},
	{id = "memetics",     name = "Меметика",       color = Color(110, 140, 170)},
	{id = "thaumatology", name = "Тауматургия",    color = Color(120, 90, 150)},
	{id = "surrealistics",name = "Сюрриалистика",  color = Color(170, 110, 140)},
	{id = "opii",         name = "ОПИИ",           color = Color(100, 150, 130)},
	{id = "apaib",        name = "АПАИБ",          color = Color(130, 130, 100)},
	{id = "anart",        name = "Артефакты",      color = Color(150, 120, 80)},
}

for i, d in ipairs(researchDepts) do
	job({
		id = "researcher_" .. d.id,
		name = "Исследователь — " .. d.name,
		faction = "foundation", department = d.id,
		color = d.color,
		models = {"models/player/eli.mdl", "models/player/kleiner.mdl"},
		weapons = {"scpf_scanner", "scpf_medkit", "scpf_radio", "scpf_keycard", "scpf_pistol"},
		salary = 110, max = 2, hp = 100, armor = 15, clearance = 3,
		whitelist = true, sort = 10 + i,
		desc = "Исследователь департамента «" .. d.name .. "». Проводит эксперименты, составляет отчёты.",
		commands = {"/me", "/dropmoney", "/dropweapon", "/research", "/report"},
	})
end

-----------------------------------------------------------------------------
-- ФОНД: МЕДИЦИНА, ИНЖЕНЕРИЯ
-----------------------------------------------------------------------------
job({
	id = "medic", name = "Врач", faction = "foundation", department = "medical",
	color = Color(160, 90, 110),
	models = {"models/player/Group03m/female_01.mdl", "models/player/Group03m/female_03.mdl"},
	weapons = {"scpf_medkit", "scpf_scanner", "scpf_radio", "scpf_keycard"},
	salary = 100, max = 3, hp = 100, armor = 15, clearance = 3, whitelist = true,
	sort = 20,
	desc = "Медицинская служба. Лечение персонала, мнемо-терапия, работа с биоаномалиями.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/heal"},
})

job({
	id = "engineer", name = "Инженер", faction = "foundation", department = "engineering",
	color = Color(150, 130, 60),
	models = {"models/player/monk.mdl"},
	weapons = {"scpf_toolgun", "scpf_scanner", "scpf_radio", "scpf_keycard", "scpf_pistol"},
	salary = 105, max = 3, hp = 110, armor = 30, clearance = 3, whitelist = true,
	sort = 21,
	desc = "Обслуживание систем содержания, ремонт после инцидентов.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/repair"},
})

-----------------------------------------------------------------------------
-- ФОНД: СЛУЖБА ВНУТРЕННЕЙ БЕЗОПАСНОСТИ (СБ)
-----------------------------------------------------------------------------
job({
	id = "isd_agent", name = "Агент СБ", faction = "foundation", department = "isd",
	color = Color(80, 90, 120),
	models = {"models/player/gman_high.mdl"},
	weapons = {"scpf_pistol", "scpf_baton", "scpf_radio", "scpf_keycard", "scpf_scanner"},
	salary = 130, max = 3, hp = 120, armor = 50, clearance = 4, whitelist = true,
	sort = 30,
	desc = "Контрразведка Фонда. Выявление агентов ГОИ и нарушителей протоколов.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/arrest", "/unarrest", "/investigate"},
})

job({
	id = "isd_director", name = "Директор СБ", faction = "foundation", department = "isd",
	color = Color(60, 70, 100),
	models = {"models/player/breen.mdl"},
	weapons = {"scpf_pistol", "scpf_baton", "scpf_radio", "scpf_keycard", "scpf_scanner", "scpf_medkit"},
	salary = 170, max = 1, hp = 130, armor = 60, clearance = 5, whitelist = true,
	sort = 31,
	desc = "Руководитель Службы внутренней безопасности Зоны.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/arrest", "/unarrest", "/investigate", "/announce"},
})

-----------------------------------------------------------------------------
-- ФОНД: КОМАНДОВАНИЕ
-----------------------------------------------------------------------------
job({
	id = "site_admin", name = "Администратор Зоны", faction = "foundation", department = "administration",
	color = Color(140, 140, 160),
	models = {"models/player/breen.mdl"},
	weapons = {"scpf_pistol", "scpf_radio", "scpf_keycard", "scpf_scanner", "scpf_medkit"},
	salary = 200, max = 1, hp = 120, armor = 40, clearance = 5, whitelist = true,
	sort = 40,
	desc = "Высшее должностное лицо Зоны. Координация департаментов, связь с O5.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/announce", "/lockdown", "/arrest", "/unarrest"},
})

job({
	id = "o5_rep", name = "Представитель O5", faction = "foundation", department = "administration",
	color = Color(200, 170, 60),
	models = {"models/player/breen.mdl"},
	weapons = {"scpf_pistol", "scpf_radio", "scpf_keycard", "scpf_scanner", "scpf_medkit"},
	salary = 260, max = 1, hp = 130, armor = 50, clearance = 6, whitelist = true,
	sort = 41,
	desc = "Представитель Совета O5. Полномочия выше Администратора Зоны.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/announce", "/lockdown", "/arrest", "/unarrest", "/o5order"},
})

-----------------------------------------------------------------------------
-- МОГ (официальные подразделения)
-----------------------------------------------------------------------------
job({
	id = "mtf_e11", name = "МОГ Эпсилон-11 «Девятихвостая лисица»",
	faction = "mtf",
	color = Color(40, 70, 140),
	models = {"models/player/swat.mdl"},
	weapons = {"scpf_rifle", "scpf_pistol", "scpf_baton", "scpf_radio", "scpf_keycard", "scpf_medkit", "scpf_recontain"},
	salary = 160, max = 6, hp = 140, armor = 90, clearance = 4, whitelist = true,
	sort = 50, mtf = "Epsilon-11",
	desc = "Основная группа восстановления содержания. Входит при нарушении содержания объектов Зоны.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/arrest", "/unarrest", "/recontain"},
})

job({
	id = "mtf_beta7", name = "МОГ Бета-7 «Шляпники Маз»",
	faction = "mtf",
	color = Color(60, 110, 90),
	models = {"models/player/riot.mdl"},
	weapons = {"scpf_smg", "scpf_pistol", "scpf_radio", "scpf_keycard", "scpf_medkit", "scpf_scanner", "scpf_recontain"},
	salary = 150, max = 4, hp = 150, armor = 100, clearance = 4, whitelist = true,
	sort = 51, mtf = "Beta-7",
	desc = "Специализация: биологические, химические и меметические угрозы. Работает в защитных костюмах.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/arrest", "/unarrest", "/recontain", "/decon"},
})

job({
	id = "mtf_nu7", name = "МОГ Ню-7 «Удар молота»",
	faction = "mtf",
	color = Color(30, 50, 100),
	models = {"models/player/riot.mdl"},
	weapons = {"scpf_lmg", "scpf_rifle", "scpf_radio", "scpf_keycard", "scpf_medkit", "scpf_recontain"},
	salary = 175, max = 3, hp = 180, armor = 130, clearance = 4, whitelist = true,
	sort = 52, mtf = "Nu-7",
	desc = "Тяжёлая штурмовая группа. Применяется при полном нарушении содержания и угрозе уровня «Кетер».",
	commands = {"/me", "/dropmoney", "/dropweapon", "/arrest", "/unarrest", "/recontain"},
})

-----------------------------------------------------------------------------
-- ГОИ
-----------------------------------------------------------------------------
job({
	id = "goc_strike", name = "Оперативник ГОК (ударная группа)", faction = "goc",
	color = Color(60, 140, 160),
	models = {"models/player/leet.mdl"},
	weapons = {"scpf_goc_rifle", "scpf_goc_pistol", "scpf_radio", "scpf_goc_device"},
	salary = 140, max = 4, hp = 140, armor = 80, clearance = 0, whitelist = true,
	sort = 60,
	desc = "Ударная группа Коалиции. Задача: уничтожение аномалий, а не содержание.",
	commands = {"/me", "/dropmoney", "/dropweapon"},
})

job({
	id = "serpent_mage", name = "Оператив «Длани Змея»", faction = "serpent",
	color = Color(80, 150, 80),
	models = {"models/player/monk.mdl"},
	weapons = {"scpf_serpent_staff", "scpf_serpent_pistol", "scpf_radio", "scpf_medkit"},
	salary = 120, max = 4, hp = 130, armor = 50, clearance = 0, whitelist = true,
	sort = 61,
	desc = "Аномальный активист. Освобождает объекты, защищает аномалии от Фонда и ГОК.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/free"},
})

job({
	id = "mcd_dealer", name = "Агент МКиД", faction = "mcd",
	color = Color(160, 130, 60),
	models = {"models/player/gman_high.mdl"},
	weapons = {"scpf_mcd_pistol", "scpf_mcd_case", "scpf_radio", "scpf_keycard"},
	salary = 150, max = 2, hp = 120, armor = 40, clearance = 0, whitelist = true,
	sort = 62,
	desc = "Представитель аукционного дома. Скупка и продажа аномалий коллекционерам.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/auction", "/trade"},
})

job({
	id = "chaos_operative", name = "Оперативник Повстанцев Хаоса", faction = "chaos",
	color = Color(150, 60, 50),
	models = {"models/player/leet.mdl"},
	weapons = {"scpf_rifle", "scpf_pistol", "scpf_radio", "scpf_medkit"},
	salary = 130, max = 4, hp = 140, armor = 70, clearance = 0, whitelist = true,
	sort = 63,
	desc = "Отколовшаяся ячейка Фонда. Использует аномалии как оружие.",
	commands = {"/me", "/dropmoney", "/dropweapon", "/steal"},
})

-----------------------------------------------------------------------------
-- SCP (играбельные аномалии)
-----------------------------------------------------------------------------
local scpList = {
	{id = "scp_173", name = "SCP-173 «Скульптура»",       hp = 800,  model = "models/props_c17/statue_doll.mdl",       sort = 70,
	 desc = "Не двигается под наблюдением. При отсутствии наблюдения перемещается мгновенно. Летальный контакт."},
	{id = "scp_096", name = "SCP-096 «Скромник»",         hp = 1200, model = "models/player/charple01.mdl",            sort = 71,
	 desc = "Входит в состояние крайнего дистресса при взгляде на лицо. Преследует наблюдателя до устранения."},
	{id = "scp_682", name = "SCP-682 «Неубиваемая рептилия»", hp = 3500, model = "models/antlion_guard.mdl",          sort = 72,
	 desc = "Крайне враждебна. Регенерация и адаптация к повреждениям. Требует тяжёлого вооружения."},
	{id = "scp_049", name = "SCP-049 «Чумной доктор»",    hp = 1400, model = "models/player/zombie_classic.mdl",       sort = 73,
	 desc = "Контакт приводит к немедленной смерти. Реанимирует жертв как SCP-049-2."},
	{id = "scp_939", name = "SCP-939 «С множественными голосами»", hp = 1600, model = "models/antlion_guard.mdl",     sort = 74,
	 desc = "Хищник. Имитирует голоса жертв. Ориентируется на звук, слабое зрение."},
	{id = "scp_106", name = "SCP-106 «Старик»",           hp = 2000, model = "models/player/charple01.mdl",            sort = 75,
	 desc = "Проходит сквозь материю. Увлекает жертв в «карманное измерение»."},
	{id = "scp_035", name = "SCP-035 «Одержимая маска»",  hp = 900,  model = "models/player/zombie_classic.mdl",       sort = 76,
	 desc = "Маска, контролирующая носителя. Манипулирует персоналом, вызывает коррозию."},
	{id = "scp_999", name = "SCP-999 «Щекоточный монстр»",hp = 600,  model = "models/props_junk/garbage_bag001a.mdl",  sort = 77,
	 desc = "Безопасен. Контакт вызывает эйфорию. Используется в терапевтических целях."},
	{id = "scp_079", name = "SCP-079 «Старый ИИ»",        hp = 500,  model = "models/props_lab/monitor01a.mdl",        sort = 78,
	 desc = "ИИ на устаревшем hardware. Взламывает системы Зоны, координирует другие объекты."},
}

for _, s in ipairs(scpList) do
	job({
		id = s.id, name = s.name, faction = "scp",
		color = Color(160, 60, 60),
		models = {s.model},
		weapons = {}, salary = 0, max = 1, hp = s.hp, armor = 0, clearance = 0,
		whitelist = true, scp = true, scpEntity = "ent_" .. s.id, sort = s.sort,
		desc = s.desc,
		commands = {"/me"},
	})
end

-----------------------------------------------------------------------------
-- ХЕЛПЕРЫ
-----------------------------------------------------------------------------
function SCPF.GetJob(id)
	return SCPF.Jobs[id]
end

function SCPF.JobByTeam(teamID)
	if not teamID then return nil end
	for _, j in pairs(SCPF.Jobs) do
		if j.team == teamID then return j end
	end
	return nil
end

function SCPF.AllJobsSorted()
	local out = {}
	for _, j in pairs(SCPF.Jobs) do out[#out + 1] = j end
	table.sort(out, function(a, b) return (a.sort or 99) < (b.sort or 99) end)
	return out
end

function SCPF.SCPJobs()
	local out = {}
	for _, j in pairs(SCPF.Jobs) do
		if j.scp then out[#out + 1] = j end
	end
	table.sort(out, function(a, b) return a.sort < b.sort end)
	return out
end

function SCPF.JobCommands(ply, cmd)
	if not IsValid(ply) then return false end
	if ply:IsAdmin() then return true end
	local j = SCPF.JobByTeam(ply:Team())
	if not j or not j.commands then return false end
	for _, c in ipairs(j.commands) do
		if c == cmd then return true end
	end
	return false
end
