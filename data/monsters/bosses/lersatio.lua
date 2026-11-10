local mType = Game.createMonsterType("Lersatio")
local monster = {}

monster.description = "Lersatio"
monster.experience = 2500
monster.outfit = {
	lookType = 287,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.events = {}

monster.bosstiary = {
	bossRaceId = 482,
	bossRace = RARITY_BANE,
}

monster.health = 1645
monster.maxHealth = 1645
monster.race = "undead"
monster.corpse = 8109
monster.speed = 210
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 15,
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
	staticAttackChance = 90,
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

monster.summon = {
	maxSummons = 1,
	summons = {
		{ name = "vampire", chance = 10, interval = 2000, count = 3 },
	},
}

monster.voices = {
	interval = 5000,
	chance = 10,
	{ text = "The monsters in the mirrors will come eat your dreams.", yell = false },
	{ text = "Your pitiful life has come to an end.", yell = false },
	{ text = "One day I will see my pretty face in a mirror again.", yell = false },
}

monster.loot = {
    { name = "Gold Coin", chance = 100000, maxCount = 100 },
    { name = "Blood Preservation", chance = 89580, maxCount = 1 },
    { name = "Strong Health Potion", chance = 23660, maxCount = 1 },
    { id = 3098, chance = 11000, maxCount = 1 },
    { name = "Platinum Coin", chance = 9740, maxCount = 5 },
    { name = "Black Pearl", chance = 1850, maxCount = 1 },
    { name = "Vampire Shield", chance = 580, maxCount = 1 },
    { name = "Dreaded Cleaver", chance = 490, maxCount = 1 }
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -535 },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_PHYSICALDAMAGE, minDamage = 0, maxDamage = -400, range = 5, shootEffect = CONST_ANI_SNIPERARROW, target = true },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_LIFEDRAIN, minDamage = 0, maxDamage = -200, range = 1, target = true },
	{ name = "speed", interval = 2000, chance = 15, speedChange = 320, effect = CONST_ME_MAGIC_RED, target = false, duration = 5000 },
}

monster.defenses = {
	defense = 54,
	armor = 59,
	mitigation = 3.7,
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_HEALING, minDamage = 300, maxDamage = 400, effect = CONST_ME_MAGIC_BLUE, target = false },
	{ name = "invisible", interval = 2000, chance = 50, effect = CONST_ME_MAGIC_BLUE },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 50 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = 20 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 10 },
	{ type = COMBAT_HOLYDAMAGE, percent = -5 },
	{ type = COMBAT_DEATHDAMAGE, percent = 100 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType.onThink = function(monster, interval) end

mType.onAppear = function(monster, creature) end

mType.onDisappear = function(monster, creature) end

mType.onMove = function(monster, creature, fromPosition, toPosition) end

mType.onSay = function(monster, creature, type, message) end

mType:register(monster)
