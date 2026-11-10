local mType = Game.createMonsterType("Malvaroth")
local monster = {}

monster.name = "Malvaroth"
monster.description = "Malvaroth"
monster.experience = 28000
monster.outfit = {
	lookType = 1794,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 3,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 2607,
	bossRace = RARITY_ARCHFOE,
}

monster.health = 40000
monster.maxHealth = 40000
monster.race = "undead"
monster.corpse = 50050
monster.speed = 160
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 10,
}

monster.strategiesTarget = {
	nearest = 80,
	health = 10,
	damage = 10,
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = true,
	illusionable = false,
	canPushItems = true,
	canPushCreatures = true,
	staticAttackChance = 90,
	targetDistance = 1,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = true,
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
	{ text = "I am superior!", yell = true },
	{ text = "You are mad to challange a demon prince!", yell = true },
	{ text = "You can't stop me or my plans!", yell = true },
	{ text = "Pesky humans!", yell = true },
	{ text = "This insolence!", yell = true },
	{ text = "Nobody can stop me!", yell = true },
	{ text = "All will have to bow to me!", yell = true },
	{ text = "With this power I can crush everyone!", yell = true },
	{ text = "All that energy is mine!", yell = true },
	{ text = "Face the power of hell!", yell = true },
	{ text = "AHHH! THE POWER!!", yell = true },
}

monster.loot = {
	{ id = 3035, chance = 99000, maxCount = 50 }, -- platinum coin
	{ id = 16124, chance = 99000, maxCount = 1 }, -- blue crystal splinter
	{ id = 16122, chance = 99000, maxCount = 1 }, -- green crystal splinter
	{ id = 7642, chance = 99000, maxCount = 1 }, -- great spirit potion
	{ id = 3029, chance = 99000, maxCount = 3 }, -- small sapphire
	{ id = 49949, chance = 7000, maxCount = 1 }, -- demonic core essence
	{ id = 49894, chance = 7000, maxCount = 1 }, -- demonic matter
	{ id = 3098, chance = 7000, maxCount = 1 }, -- ring of healing
	{ id = 49893, chance = 1000, maxCount = 1 }, -- skin of malvaroth
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 400, maxDamage = -500 },
}

monster.defenses = {
	defense = 80,
	armor = 80,
	mitigation = 1.45,
	{ name = "combat", interval = 1000, chance = 25, type = COMBAT_HEALING, minDamage = 600, maxDamage = 800, effect = CONST_ME_MAGIC_BLUE, target = false },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 30 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 0 },
	{ type = COMBAT_FIREDAMAGE, percent = 15 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 20 },
	{ type = COMBAT_HOLYDAMAGE, percent = 0 },
	{ type = COMBAT_DEATHDAMAGE, percent = 20 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = true },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = true },
}

mType:register(monster)
