local mType = Game.createMonsterType("Boosted Statue")
local monster = {}

monster.name = "Boosted Statue"
monster.description = "the boosted creature of the day"
monster.experience = 0
monster.outfit = {
	lookType = 160,
}

monster.health = 1000000
monster.maxHealth = monster.health
monster.race = "undead"
monster.corpse = 0
monster.speed = 0

monster.changeTarget = {
	interval = 0,
	chance = 0,
}

monster.flags = {
	summonable = false,
	attackable = false,
	hostile = false,
	convinceable = false,
	illusionable = false,
	canPushItems = false,
	canPushCreatures = false,
	targetDistance = 0,
	staticAttackChance = 0,
}

monster.summons = {}
monster.voices = {}
monster.loot = {}
monster.attacks = {}

monster.defenses = {
	defense = 0,
	armor = 0,
}

monster.elements = {}
monster.immunities = {
	{ type = "physical", combat = true },
	{ type = "energy", combat = true },
	{ type = "earth", combat = true },
	{ type = "fire", combat = true },
	{ type = "ice", combat = true },
	{ type = "holy", combat = true },
	{ type = "death", combat = true },
	{ type = "drown", combat = true },
	{ type = "lifedrain", combat = true },
	{ type = "manadrain", combat = true },
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = true },
	{ type = "invisible", condition = true },
}

mType:register(monster)
