local mType = Game.createMonsterType("Maw")
local monster = {}

monster.description = "Maw"
monster.experience = 6500
monster.outfit = {
	lookType = 458,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 857,
	bossRace = RARITY_BANE,
}

monster.health = 8200
monster.maxHealth = 8200
monster.race = "venom"
monster.corpse = 13937
monster.speed = 115
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 10,
}

monster.strategiesTarget = {
	nearest = 100,
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
	targetDistance = 1,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = false,
	canWalkOnFire = true,
	canWalkOnPoison = true,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.voices = {
	interval = 5000,
	chance = 10,
	{ text = "Kropp!", yell = false },
}

monster.loot = {
    { name = "Compound Eye", chance = 100000, maxCount = 1 },
    { name = "Gold Coin", chance = 100000, maxCount = 196 },
    { name = "Kollos Shell", chance = 100000, maxCount = 1 },
    { name = "Platinum Coin", chance = 83820, maxCount = 6 },
    { name = "Great Mana Potion", chance = 66180, maxCount = 2 },
    { id = 14225, chance = 55880, maxCount = 2 },
    { name = "Ultimate Health Potion", chance = 33820, maxCount = 1 },
    { name = "Small Ruby", chance = 32350, maxCount = 4 },
    { name = "Black Pearl", chance = 29410, maxCount = 4 },
    { id = 3039, chance = 22060, maxCount = 1 },
    { name = "Gooey Mass", chance = 20590, maxCount = 2 },
    { id = 282, chance = 8820, maxCount = 1 },
    { name = "Gold Ingot", chance = 7350, maxCount = 1 },
    { name = "Calopteryx Cape", chance = 4410, maxCount = 1 },
    { name = "Hive Bow", chance = 1470, maxCount = 1 }
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -353 },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_PHYSICALDAMAGE, minDamage = 0, maxDamage = -350, range = 7, radius = 3, shootEffect = CONST_ANI_EXPLOSION, effect = CONST_ME_EXPLOSIONHIT, target = true },
}

monster.defenses = {
	defense = 35,
	armor = 52,
	mitigation = 1.71,
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 10 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = 30 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = -7 },
	{ type = COMBAT_HOLYDAMAGE, percent = 0 },
	{ type = COMBAT_DEATHDAMAGE, percent = -5 },
}

monster.immunities = {
	{ type = "paralyze", condition = false },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
