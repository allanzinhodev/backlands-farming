local mType = Game.createMonsterType("The Primal Menace")
local monster = {}

local thePrimalMenaceConfig = {
	Storage = {
		Initialized = 1,
		SpawnPos = 2,
		NextPodSpawn = 3,
		NextMonsterSpawn = 4,
		PrimalBeasts = 5, -- List of monsters and when they were created in order to turn them into fungosaurus {monster, created}
	},

	-- Spawn area
	SpawnRadius = 5,

	-- Monster spawn time
	MonsterConfig = {
		IntervalBase = 30,
		IntervalReductionPer10PercentHp = 0.98,
		IntervalReductionPerHazard = 0.985,

		CountBase = 4,
		CountVarianceRate = 0.5,
		CountGrowthPerHazard = 1.05,
		CountMax = 6,

		MonsterPool = {
			"Emerald Tortoise (Primal)",
			"Gore Horn (Primal)",
			"Gorerilla (Primal)",
			"Headpecker (Primal)",
			"Hulking Prehemoth (Primal)",
			"Mantosaurus (Primal)",
			"Nighthunter (Primal)",
			"Noxious Ripptor (Primal)",
			"Sabretooth (Primal)",
			"Stalking Stalk (Primal)",
			"Sulphider (Primal)",
		},
	},

	PodConfig = {
		IntervalBase = 30,
		IntervalReductionPer10PercentHp = 0.98,
		IntervalReductionPerHazard = 0.985,

		CountBase = 2,
		CountVarianceRate = 0.5,
		CountGrowthPerHazard = 1.1,
		CountMax = 4,
	},
}

monster.name = "The Primal Menace"
monster.description = "The Primal Menace"
monster.experience = 0
monster.outfit = {
	lookType = 1566,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 2247,
	bossRace = RARITY_ARCHFOE,
}

monster.health = 400000
monster.maxHealth = 400000
monster.race = "venom"
monster.corpse = 39530
monster.speed = 180
monster.manaCost = 0

monster.changeTarget = {
	interval = 2000,
	chance = 10,
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
	staticAttackChance = 95,
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
}

monster.loot = {}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = -0, maxDamage = -763 },
	{ name = "combat", interval = 4000, chance = 25, type = COMBAT_EARTHDAMAGE, minDamage = -1500, maxDamage = -2200, length = 10, spread = 3, effect = CONST_ME_CARNIPHILA, target = false },
	{ name = "combat", interval = 2500, chance = 35, type = COMBAT_FIREDAMAGE, minDamage = -700, maxDamage = -1000, length = 10, spread = 3, effect = CONST_ME_HITBYFIRE, target = false },
	{ name = "big death wave", interval = 3500, chance = 25, minDamage = -250, maxDamage = -300, target = false },
	{ name = "combat", interval = 5000, chance = 25, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_ENERGYHIT, minDamage = -1200, maxDamage = -1300, range = 4, target = false },
	{ name = "combat", interval = 2700, chance = 35, type = COMBAT_EARTHDAMAGE, shootEffect = CONST_ANI_POISON, effect = CONST_ANI_EARTH, minDamage = -600, maxDamage = -1800, range = 4, target = true },
}

monster.defenses = {
	defense = 80,
	armor = 100,
	mitigation = 3.72,
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = -5 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = 5 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 50 },
	{ type = COMBAT_HOLYDAMAGE, percent = 40 },
	{ type = COMBAT_DEATHDAMAGE, percent = 0 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "drunk", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
