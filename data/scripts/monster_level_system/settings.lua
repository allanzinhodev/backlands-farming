-- Monster Level System Configuration
-- Range values are inclusive (min <= level <= max)

-- Skull ranges per monster level bracket
setMonsterLevelSkullRange(SKULL_WHITE, 1, 99)
setMonsterLevelSkullRange(SKULL_RED, 100, 499)
setMonsterLevelSkullRange(SKULL_BLACK, 500, 2000)

-- Bonus multipliers per level (0.0 = disabled)
-- damage: extra damage %, e.g. 0.01 = 1% more damage per level
-- speed: extra speed %, e.g. 0.01 = 1% more speed per level
-- health: extra health %, e.g. 0.02 = 2% more HP per level
setMonsterLevelBonus("damage", 0.01)
setMonsterLevelBonus("speed", 0.01)
setMonsterLevelBonus("health", 0.02)
