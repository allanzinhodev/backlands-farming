local mType = Game.createMonsterType("Stress Test Dummy")
local monster = {}

monster.name = "Stress Test Dummy"
monster.description = "a stress test dummy"
monster.experience = 0
monster.outfit = {
	lookType = 35,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.raceId = 9999

monster.health = 500000
monster.maxHealth = 500000
monster.race = "blood"
monster.corpse = 5995
monster.speed = 140
monster.manaCost = 0

monster.changeTarget = {
	interval = 2000,
	chance = 20,
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
	staticAttackChance = 50,
	targetDistance = 1,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = true,
	canWalkOnFire = true,
	canWalkOnPoison = true,
}

monster.light = {
	level = 4,
	color = 215,
}

monster.voices = {
	interval = 3000,
	chance = 30,
	{ text = "STRESS TEST!", yell = true },
	{ text = "FEEL ALL THE SPELLS!", yell = true },
	{ text = "SPECTATORS GO BRRR!", yell = true },
}

monster.loot = {}

-- STRESS: many different attack types, effects, conditions, areas
monster.attacks = {
	-- Melee
	{ name = "melee", interval = 1000, chance = 100, minDamage = -10, maxDamage = -50 },

	-- Fire AoE (ranged, radius)
	{ name = "combat", interval = 1500, chance = 40, type = COMBAT_FIREDAMAGE, minDamage = -30, maxDamage = -80, range = 7, radius = 4, shootEffect = CONST_ANI_FIRE, effect = CONST_ME_FIREAREA, target = true },

	-- Ice wave (length/spread)
	{ name = "combat", interval = 1500, chance = 35, type = COMBAT_ICEDAMAGE, minDamage = -20, maxDamage = -70, length = 8, spread = 3, effect = CONST_ME_ICEAREA, target = false },

	-- Energy beam (length)
	{ name = "combat", interval = 1500, chance = 35, type = COMBAT_ENERGYDAMAGE, minDamage = -25, maxDamage = -60, length = 6, spread = 0, effect = CONST_ME_ENERGYHIT, target = false },

	-- Earth AoE
	{ name = "combat", interval = 1500, chance = 30, type = COMBAT_EARTHDAMAGE, minDamage = -20, maxDamage = -50, radius = 3, effect = CONST_ME_GREEN_RINGS, target = false },

	-- Death ranged
	{ name = "combat", interval = 2000, chance = 25, type = COMBAT_DEATHDAMAGE, minDamage = -30, maxDamage = -90, range = 7, shootEffect = CONST_ANI_DEATH, effect = CONST_ME_MORTAREA, target = true },

	-- Holy ranged
	{ name = "combat", interval = 2000, chance = 25, type = COMBAT_HOLYDAMAGE, minDamage = -20, maxDamage = -60, range = 7, shootEffect = CONST_ANI_HOLY, effect = CONST_ME_HOLYDAMAGE, target = true },

	-- Physical AoE
	{ name = "combat", interval = 1500, chance = 30, type = COMBAT_PHYSICALDAMAGE, minDamage = -15, maxDamage = -40, radius = 2, effect = CONST_ME_EXPLOSIONAREA, target = false },

	-- Lifedrain wave
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_LIFEDRAIN, minDamage = -30, maxDamage = -80, length = 5, spread = 2, effect = CONST_ME_MAGIC_RED, target = false },

	-- Manadrain ranged
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_MANADRAIN, minDamage = -20, maxDamage = -60, range = 7, shootEffect = CONST_ANI_ENERGY, target = true },

	-- Drown AoE
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_DROWNDAMAGE, minDamage = -10, maxDamage = -40, radius = 3, effect = CONST_ME_LOSEENERGY, target = false },

	-- Firefield
	{ name = "firefield", interval = 3000, chance = 15, range = 7, radius = 3, shootEffect = CONST_ANI_FIRE, target = true },

	-- Poisonfield
	{ name = "poisonfield", interval = 3000, chance = 15, range = 7, radius = 3, shootEffect = CONST_ANI_POISON, target = true },

	-- Energyfield
	{ name = "energyfield", interval = 3000, chance = 15, range = 7, radius = 3, shootEffect = CONST_ANI_ENERGY, target = true },

	-- Condition: paralyze
	{ name = "speed", interval = 3000, chance = 20, speed = { min = -300, max = -200 }, range = 7, shootEffect = CONST_ANI_EARTH, effect = CONST_ME_GREEN_RINGS, target = true, duration = 6000 },

	-- Fire splash AoE
	{ name = "combat", interval = 4000, chance = 10, type = COMBAT_FIREDAMAGE, minDamage = -5, maxDamage = -15, radius = 5, effect = CONST_ME_FIREATTACK, target = false },
}

monster.defenses = {
	defense = 40,
	armor = 40,
	-- Self healing (multiple types to stress different code paths)
	{ name = "combat", interval = 1500, chance = 30, type = COMBAT_HEALING, minDamage = 100, maxDamage = 300, effect = CONST_ME_MAGIC_BLUE, target = false },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_HEALING, minDamage = 50, maxDamage = 150, effect = CONST_ME_MAGIC_GREEN, target = false },
	{ name = "speed", interval = 3000, chance = 15, speed = { min = 200, max = 300 }, effect = CONST_ME_MAGIC_RED, target = false, duration = 4000 },
	{ name = "outfit", interval = 5000, chance = 10, effect = CONST_ME_MAGIC_BLUE, target = false, duration = 3000, outfitMonster = "Rat" },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 30 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 20 },
	{ type = COMBAT_EARTHDAMAGE, percent = 20 },
	{ type = COMBAT_FIREDAMAGE, percent = 20 },
	{ type = COMBAT_LIFEDRAIN, percent = 50 },
	{ type = COMBAT_MANADRAIN, percent = 50 },
	{ type = COMBAT_DROWNDAMAGE, percent = 20 },
	{ type = COMBAT_ICEDAMAGE, percent = 20 },
	{ type = COMBAT_HOLYDAMAGE, percent = 20 },
	{ type = COMBAT_DEATHDAMAGE, percent = 20 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "invisible", condition = true },
}

monster.summon = {
	maxSummons = 3,
	summons = {
		{ name = "Rat", chance = 15, interval = 3000, count = 3 },
	},
}

mType:register(monster)
