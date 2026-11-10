local mType = Game.createMonsterType("Stress Demon")
local monster = {}

monster.name = "Stress Demon"
monster.description = "a stress demon"
monster.experience = 0
monster.outfit = {
	lookType = 35,
	lookHead = 114,
	lookBody = 94,
	lookLegs = 79,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 250000
monster.maxHealth = 250000
monster.race = "fire"
monster.corpse = 5995
monster.speed = 180
monster.manaCost = 0

monster.changeTarget = {
	interval = 1000,
	chance = 100,
}

monster.strategiesTarget = {
	nearest = 25,
	health = 25,
	damage = 25,
	random = 25,
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = false,
	canPushItems = true,
	canPushCreatures = true,
	staticAttackChance = 95,
	targetDistance = 4,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = true,
	canWalkOnFire = true,
	canWalkOnPoison = true,
}

monster.light = {
	level = 8,
	color = 215,
}

monster.voices = {
	interval = 2000,
	chance = 25,
	{ text = "CONDITION STRESS!", yell = true },
	{ text = "Tick, clone, collect!", yell = false },
	{ text = "More conditions!", yell = true },
}

monster.loot = {}

monster.attacks = {
	{ name = "melee", interval = 1000, chance = 100, minDamage = 0, maxDamage = -1, condition = { type = CONDITION_POISON, totalDamage = 40, interval = 1000 } },
	{ name = "condition", interval = 700, chance = 35, type = CONDITION_FIRE, minDamage = -5, maxDamage = -15, radius = 5, effect = CONST_ME_FIREAREA, target = false, duration = 6000 },
	{ name = "condition", interval = 700, chance = 35, type = CONDITION_ENERGY, minDamage = -5, maxDamage = -15, radius = 5, effect = CONST_ME_ENERGYHIT, target = false, duration = 6000 },
	{ name = "condition", interval = 700, chance = 30, type = CONDITION_CURSED, minDamage = -5, maxDamage = -15, radius = 5, effect = CONST_ME_MORTAREA, target = false, duration = 6000 },
	{ name = "condition", interval = 700, chance = 30, type = CONDITION_BLEEDING, minDamage = -5, maxDamage = -15, radius = 5, effect = CONST_ME_DRAWBLOOD, target = false, duration = 6000 },
	{ name = "condition", interval = 700, chance = 25, type = CONDITION_DROWN, minDamage = -5, maxDamage = -15, radius = 5, effect = CONST_ME_LOSEENERGY, target = false, duration = 6000 },
	{ name = "condition", interval = 700, chance = 25, type = CONDITION_FREEZING, minDamage = -5, maxDamage = -15, radius = 5, effect = CONST_ME_ICEATTACK, target = false, duration = 6000 },
	{ name = "speed", interval = 700, chance = 40, speedChange = -450, range = 7, radius = 4, effect = CONST_ME_MAGIC_RED, target = true, duration = 3000 },
	{ name = "drunk", interval = 700, chance = 35, range = 7, radius = 4, effect = CONST_ME_SOUND_WHITE, target = false, duration = 5000, drunkenness = 80 },
	{ name = "outfit", interval = 1200, chance = 12, range = 7, radius = 3, effect = CONST_ME_MAGIC_BLUE, target = true, duration = 2500, outfitMonster = "rat" },
	{ name = "combat", interval = 800, chance = 45, type = COMBAT_FIREDAMAGE, minDamage = -1, maxDamage = -3, range = 7, radius = 4, shootEffect = CONST_ANI_FIRE, effect = CONST_ME_FIREAREA, target = true },
	{ name = "combat", interval = 800, chance = 45, type = COMBAT_ENERGYDAMAGE, minDamage = -1, maxDamage = -3, range = 7, radius = 4, shootEffect = CONST_ANI_ENERGY, effect = CONST_ME_ENERGYAREA, target = true },
}

monster.defenses = {
	defense = 80,
	armor = 80,
	mitigation = 2.0,
	{ name = "combat", interval = 1000, chance = 35, type = COMBAT_HEALING, minDamage = 500, maxDamage = 1500, effect = CONST_ME_MAGIC_BLUE, target = false },
	{ name = "speed", interval = 1000, chance = 35, speedChange = 500, effect = CONST_ME_MAGIC_RED, target = false, duration = 2500 },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 25 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 50 },
	{ type = COMBAT_EARTHDAMAGE, percent = 50 },
	{ type = COMBAT_FIREDAMAGE, percent = 100 },
	{ type = COMBAT_LIFEDRAIN, percent = 100 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 100 },
	{ type = COMBAT_ICEDAMAGE, percent = 30 },
	{ type = COMBAT_HOLYDAMAGE, percent = -10 },
	{ type = COMBAT_DEATHDAMAGE, percent = 30 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = true },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = true },
}

mType:register(monster)
