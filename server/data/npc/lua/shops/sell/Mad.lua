-- Mad – RevScript (NpcsHandler)
local npcType = Game.createNpcType("Mad")
npcType:outfit({lookType = 129, lookHead = 75, lookBody = 115, lookLegs = 125, lookFeet = 85, lookAddons = 3})
npcType:health(150)
npcType:maxHealth(150)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Mad")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Hello |PLAYERNAME|. I buy swords, clubs, axes, helmets, boots, legs, shields and armors. Say {trade}!"})

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

local shop = NpcShop("Mad", 1)
-- buy only
shop:addItem(5460, 10000, 0)     -- helmet of the deep

-- sell only (sell price, buy price = 0)
shop:addItem(3394,     0, 2500)  -- amazon armor
shop:addItem(3437,     0, 4000)  -- amazon shield
shop:addItem(3266,     0, 100)   -- battle axe
shop:addItem(3305,     0, 60)    -- battle hammer
shop:addItem(3418,     0, 1500)  -- beholder shield
shop:addItem(3423,     0, 150000)-- blessed shield
shop:addItem(3567,     0, 15000) -- blue robe
shop:addItem(3079,     0, 40000) -- boots of haste
shop:addItem(3359,     0, 200)   -- brass armor
shop:addItem(3295,     0, 6000)  -- bright sword
shop:addItem(3301,     0, 70)    -- broad sword
shop:addItem(3358,     0, 100)   -- chain armor
shop:addItem(3352,     0, 35)    -- chain helmet
shop:addItem(3311,     0, 200)   -- clerical mace
shop:addItem(3381,     0, 20000) -- crown armor
shop:addItem(3385,     0, 5000)  -- crown helmet
shop:addItem(3382,     0, 15000) -- crown legs
shop:addItem(3419,     0, 5000)  -- crown shield
shop:addItem(3391,     0, 9000)  -- crusader helmet
shop:addItem(3388,     0, 90000) -- demon armor
shop:addItem(3420,     0, 40000) -- demon shield
shop:addItem(3356,     0, 4000)  -- devil helmet
shop:addItem(3275,     0, 200)   -- double axe
shop:addItem(3322,     0, 2000)  -- dragon hammer
shop:addItem(3302,     0, 10000) -- dragon lance
shop:addItem(3386,     0, 60000) -- dragon scale mail
shop:addItem(7402,     0, 20000) -- dragonslayer
shop:addItem(7419,     0, 30000) -- dreaded cleaver
shop:addItem(3425,     0, 100)   -- dwarven shield
shop:addItem(3320,     0, 10000) -- fire axe
shop:addItem(3280,     0, 3000)  -- fire sword
shop:addItem(3281,     0, 10000) -- giant sword
shop:addItem(3360,     0, 30000) -- golden armor
shop:addItem(3555,     0, 200000)-- golden boots
shop:addItem(3364,     0, 80000) -- golden legs
shop:addItem(3422,     0, 100000)-- great shield
shop:addItem(3315,     0, 7500)  -- guardian halberd
shop:addItem(3415,     0, 200)   -- guardian shield
shop:addItem(3269,     0, 200)   -- halberd
shop:addItem(3276,     0, 20)    -- hatchet
shop:addItem(3284,     0, 4000)  -- ice rapier
shop:addItem(3353,     0, 30)    -- iron helmet
shop:addItem(3370,     0, 5000)  -- knight armor
shop:addItem(3318,     0, 2000)  -- knight axe
shop:addItem(3371,     0, 6000)  -- knight legs
shop:addItem(3286,     0, 30)    -- mace
shop:addItem(3278,     0, 150000)-- magic longsword
shop:addItem(3366,     0, 200000)-- magic plate armor
shop:addItem(3288,     0, 120000)-- magic sword
shop:addItem(3414,     0, 60000) -- mastermind shield
shop:addItem(3436,     0, 8000)  -- medusa shield
shop:addItem(3574,     0, 500)   -- mystic turban
shop:addItem(8063,     0, 30000) -- paladin armor
shop:addItem(3357,     0, 400)   -- plate armor
shop:addItem(3557,     0, 500)   -- plate legs
shop:addItem(3392,     0, 40000) -- royal helmet
shop:addItem(3297,     0, 1500)  -- serpent sword
shop:addItem(3294,     0, 30)    -- short sword
shop:addItem(5741,     0, 35000) -- skull helmet
shop:addItem(3324,     0, 6000)  -- skull staff
shop:addItem(8061,     0, 60000) -- skullcracker armor
shop:addItem(3271,     0, 800)   -- spike sword
shop:addItem(3554,     0, 40000) -- steel boots
shop:addItem(3319,     0, 90000) -- stonecutter axe
shop:addItem(3264,     0, 25)    -- sword
shop:addItem(3309,     0, 90000) -- thunder hammer
shop:addItem(3428,     0, 4000)  -- tower shield
shop:addItem(3265,     0, 400)   -- two handed sword
shop:addItem(3434,     0, 25000) -- vampire shield
shop:addItem(3279,     0, 6000)  -- war hammer
shop:addItem(3296,     0, 100000)-- warlord sword
shop:addItem(3369,     0, 6000)  -- warrior helmet
