local mType = Game.createMonsterType("Mindmasher")
local monster = {}

monster.description = "Mindmasher"
monster.experience = 6000
monster.outfit = {
	lookType = 403,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 855,
	bossRace = RARITY_BANE,
}

monster.health = 9500
monster.maxHealth = 9500
monster.race = "venom"
monster.corpse = 12525
monster.speed = 120
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
	canPushCreatures = false,
	staticAttackChance = 90,
	targetDistance = 1,
	runHealth = 0,
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
    { name = "Compound Eye", chance = 100000, maxCount = 2 },
    { id = 14225, chance = 100000, maxCount = 3 },
    { name = "Gold Coin", chance = 100000, maxCount = 233 },
    { name = "Platinum Coin", chance = 77360, maxCount = 4 },
    { name = "Great Mana Potion", chance = 50940, maxCount = 2 },
    { name = "Great Health Potion", chance = 49060, maxCount = 2 },
    { name = "Small Sapphire", chance = 43400, maxCount = 2 },
    { name = "Small Emerald", chance = 37740, maxCount = 2 },
    { name = "Ripper Lance", chance = 32079, maxCount = 1 },
    { id = 3097, chance = 20750, maxCount = 1 },
    { name = "Yellow Gem", chance = 16980, maxCount = 1 },
    { name = "Twin Hooks", chance = 11320, maxCount = 1 },
    { name = "Spike Sword", chance = 5660, maxCount = 1 },
    { name = "Epee", chance = 3769, maxCount = 1 },
    { name = "Carapace Shield", chance = 1890, maxCount = 1 },
    { id = 282, chance = 1890, maxCount = 1 },
    { name = "Grasshopper Legs", chance = 1890, maxCount = 1 }
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -110, condition = { type = CONDITION_POISON, totalDamage = 160, interval = 4000 } },
}

monster.defenses = {
	defense = 15,
	armor = 30,
	mitigation = 0.91,
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 5 },
	{ type = COMBAT_ENERGYDAMAGE, percent = -5 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = -10 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = -10 },
	{ type = COMBAT_HOLYDAMAGE, percent = 0 },
	{ type = COMBAT_DEATHDAMAGE, percent = 0 },
}

monster.immunities = {
	{ type = "paralyze", condition = false },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
