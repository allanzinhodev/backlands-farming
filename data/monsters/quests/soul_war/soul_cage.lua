local mType = Game.createMonsterType("Soul Cage")
local monster = {}

monster.name = "Soul Cage"
monster.description = "a soul cage"
monster.experience = 100000
monster.outfit = {
	lookType = 863,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 100000
monster.maxHealth = 100000
monster.race = "undead"
monster.corpse = 0
monster.speed = 0
monster.manaCost = 0

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = false,
	staticAttackChance = 90,
	targetDistance = 1,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
}


monster.light = {
	level = 0,
	color = 0,
}

monster.defenses = {
	defense = 80,
	armor = 100,
	{ name = "combat", interval = 2000, chance = 40, type = COMBAT_HEALING, minDamage = 560, maxDamage = 1200, effect = CONST_ME_MAGIC_BLUE, target = false },

}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 0 },
	{ type = COMBAT_FIREDAMAGE, percent = 0 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 0 },
	{ type = COMBAT_HOLYDAMAGE, percent = 0 },
	{ type = COMBAT_DEATHDAMAGE, percent = 0 },
}

monster.immunities = {
	{ type = "invisible", condition = true },
}

mType:register(monster)
