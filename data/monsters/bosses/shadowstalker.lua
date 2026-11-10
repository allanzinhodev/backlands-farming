local mType = Game.createMonsterType("Shadowstalker")
local monster = {}

monster.description = "Shadowstalker"
monster.experience = 4000
monster.outfit = {
	lookType = 456,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 853,
	bossRace = RARITY_BANE,
}

monster.health = 6100
monster.maxHealth = 6100
monster.race = "venom"
monster.corpse = 13865
monster.speed = 125
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 10,
}

monster.strategiesTarget = {
	nearest = 70,
	damage = 30,
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = true,
	canPushItems = true,
	canPushCreatures = true,
	staticAttackChance = 95,
	targetDistance = 1,
	runHealth = 40,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = false,
	canWalkOnFire = false,
	canWalkOnPoison = true,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.voices = {
	interval = 5000,
	chance = 10,
}

monster.loot = {
    { name = "Crawler Head Plating", chance = 100000, maxCount = 1 },
    { name = "Gold Coin", chance = 100000, maxCount = 214 },
    { name = "Platinum Coin", chance = 88000, maxCount = 5 },
    { name = "Compound Eye", chance = 76000, maxCount = 1 },
    { name = "Great Health Potion", chance = 52000, maxCount = 2 },
    { name = "Great Mana Potion", chance = 48000, maxCount = 2 },
    { name = "Small Topaz", chance = 46670, maxCount = 2 },
    { id = 14225, chance = 41330, maxCount = 2 },
    { name = "Small Emerald", chance = 40000, maxCount = 2 },
    { name = "Yellow Gem", chance = 13330, maxCount = 1 },
    { name = "Springsprout Rod", chance = 2670, maxCount = 1 },
    { name = "War Hammer", chance = 2670, maxCount = 1 }
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -228, condition = { type = CONDITION_POISON, totalDamage = 80, interval = 4000 } },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_EARTHDAMAGE, minDamage = -100, maxDamage = -180, range = 7, shootEffect = CONST_ANI_EARTHARROW, effect = CONST_ME_SMALLPLANTS, target = true },
}

monster.defenses = {
	defense = 30,
	armor = 38,
	mitigation = 1.26,
	{ name = "speed", interval = 2000, chance = 15, speedChange = 300, effect = CONST_ME_MAGIC_RED, target = false, duration = 3000 },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = -8 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = -7 },
	{ type = COMBAT_HOLYDAMAGE, percent = -5 },
	{ type = COMBAT_DEATHDAMAGE, percent = 5 },
}

monster.immunities = {
	{ type = "paralyze", condition = false },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
