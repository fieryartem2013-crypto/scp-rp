# SCP RP | DarkRP

Гейммод для Garry's Mod. Архитектура Helix (фракции, департаменты, вайтлисты, персонажи, хуки схемы) + доступность DarkRP (F4-меню, простая установка).

**Версия:** 1.0.0
**Имя в меню игры:** «SCP RP | DarkRP»
**Папка гейммода:** `darkrp`
**Язык:** русский

---

## Установка

1. Скачай релиз `SCP_SERVER_v1.0.0.zip` (или собери сам — см. ниже).
2. Распакуй **внутрь папки `garrysmod`**:
   ```
   Steam/steamapps/common/GarrysMod/garrysmod/
   ```
3. Должно получиться:
   ```
   garrysmod/gamemodes/darkrp/darkrp.txt
   garrysmod/gamemodes/darkrp/gamemode/shared.lua
   ```
   ⚠️ Если вышло `gamemodes/gamemodes/darkrp` — удали лишнюю папку.
4. Полностью перезапусти GMod.

**Найти в игре:** New Game → карта → список «Gamemode» → **«SCP RP | DarkRP»**

**Сервер:**
```bash
./srcds_run -game garrysmod +map rp_downtown_v4c_v2 +gamemode darkrp -maxplayers 24
```

---

## Сборка релиза из исходников

```bash
./build_release.sh
```
На выходе: `SCP_SERVER_v1.0.0.zip` в корне репозитория.

---

## Состав

### Фракции
Фонд SCP · МОГ · ГОК · Длань Змея · МКиД · Повстанцы Хаоса · SCP

### Департаменты Фонда
Антимеметика · Патафизика · Меметика · Тауматургия · Сюрриалистика · ОПИИ · АПАИБ · Артефакты · СБ · Охрана · Медслужба · Инженерия · Администрация

### Джобы (28+)
| Категория | Джобы |
|---|---|
| Фонд (без вайтлиста) | Класс-D, Уборщик, Охранник (младший) |
| Фонд (вайтлист) | Охранник (старший), Исследователи ×8 департаментов, Врач, Инженер, Агент СБ, Директор СБ, Администратор Зоны, Представитель O5 |
| МОГ | Эпсилон-11 «Девятихвостая лисица», Бета-7 «Шляпники Маз», Ню-7 «Удар молота» |
| ГОИ | Оперативник ГОК, Длань Змея, Агент МКиД, Повстанец Хаоса |
| SCP | 173, 096, 682, 049, 939, 106, 035, 999, 079 |

### Системы
- Нарушение содержания (уровни 1–3, сирена, волна МОГ)
- Задержание (арест, штраф/награда, побег)
- Двери (покупка/замок, уровни доступа keycard 0–6)
- Экономика (зарплата, дроп, переводы)
- Точки спавна по фракциям/джобам/SCP/клетка
- F4-меню: Должности / Спавны / Админка / Помощь
- HUD, скорборд, уведомления, создание персонажа
- Вайтлисты по фракциям и джобам

### Команды
```
/job <id>              сменить должность
/dropmoney <сумма>     выбросить деньги
/give <ник> <сумма>    перевод
/arrest <ник> [сек]    задержать (охрана/СБ/МОГ)
/unarrest <ник>        освободить
/escape                побег
/buydoor /selldoor     двери
/announce <текст>      объявление
/lockdown              локдаун
/breach <1-3>          нарушение (админ)
/spawnscp <id>         заспавнить SCP (админ)
/setspawn <key>        точка спавна (админ)
/wl add|remove|list    вайтлист (админ)
/setmoney <ник> <n>    выдать деньги (админ)
/bring /goto <ник>     телепорт (админ)
/giveweapon <ник> <c>  выдать оружие (админ)
/me <текст>            действие от третьего лица
/help                  список команд
```

---

## Структура

```
garrysmod/gamemodes/darkrp/
├── darkrp.txt / gamemode.info   метаданные (нужны, чтобы гейммод был виден в меню)
├── addon.json                   для Workshop
├── lua/framework/
│   ├── sh_config.lua            все настройки
│   ├── sh_lib.lua               ядро: net, хуки, утилиты
│   ├── sh_factions.lua          фракции
│   ├── sh_departments.lua       департаменты
│   ├── sh_jobs.lua              джобы
│   ├── sh_whitelist.lua         вайтлисты
│   ├── sh_characters.lua        персонажи
│   └── sh_schema.lua            хуки схемы
└── gamemode/
    ├── shared.lua / cl_init.lua / sv_init.lua
    ├── cl_f4.lua cl_hud.lua cl_scoreboard.lua cl_notify.lua
    ├── cl_charmenu.lua cl_fonts.lua
    └── sv_jobs sv_money sv_arrest sv_doors sv_breach
        sv_commands sv_spawns sv_admin
```

---

## Настройка

- Все цифры: `lua/framework/sh_config.lua`
- Вайтлисты: `data/scpf/whitelists/<faction|jobid>.txt` (SteamID64 по строке)
- Спавны: `data/scpf/spawns.txt` (JSON, ставит админ через `/setspawn`)

---

## Статус / Roadmap

Сделано: фреймворк, фракции, департаменты, джобы, вайтлисты, персонажи, breach, арест, двери, экономика, спавны, F4, HUD, скорборд, админка.

Не сделано:
- [ ] Оружие (SWEP): `scpf_pistol`, `scpf_smg`, `scpf_rifle`, `scpf_lmg`, `scpf_baton`, `scpf_medkit`, `scpf_scanner`, `scpf_radio`, `scpf_keycard`, `scpf_recontain`, `scpf_broom`, `scpf_toolgun`, `scpf_goc_*`, `scpf_serpent_*`, `scpf_mcd_*`
- [ ] SCP-энтити: `ent_scp_173`, `ent_scp_096`, `ent_scp_682`, `ent_scp_049`, `ent_scp_939`, `ent_scp_106`, `ent_scp_035`, `ent_scp_999`, `ent_scp_079`
- [ ] Инвентарь, рация, документы
- [ ] Сохранение денег/инвентаря между сессиями

---

## Лицензия

Свободная.
