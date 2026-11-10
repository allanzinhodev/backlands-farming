-- Rashid – RevScript (NpcsHandler)
local npcType = Game.createNpcType("Rashid")
npcType:outfit({lookType = 146, lookHead = 12, lookBody = 101, lookLegs = 122, lookFeet = 115, lookAddons = 2})
npcType:health(100)
npcType:maxHealth(100)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Rashid")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Hello |PLAYERNAME|. I buy helmets, armors, legs, boots, weapons and shields. Say {trade}!"})

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

local shop = NpcShop("Rashid", 1)
-- sell only (buy=0, sell=price)
shop:addItem(7426,      0, 8000)   -- amber staff
shop:addItem(3025,      0, 200)    -- ancient amulet
shop:addItem(7404,      0, 9000)   -- assassin dagger
shop:addItem(3344,      0, 1500)   -- beastslayer axe
shop:addItem(3441,      0, 80)     -- bone shield
shop:addItem(3408,      0, 7500)   -- bonelord helmet
shop:addItem(3079,      0, 40000)  -- boots of haste
shop:addItem(7379,      0, 1500)   -- brutetamer's staff
shop:addItem(3435,      0, 5000)   -- castle shield
shop:addItem(3556,      0, 1000)   -- crocodile boots
shop:addItem(3382,      0, 15000)  -- crown legs
shop:addItem(3419,      0, 5000)   -- crown shield
shop:addItem(3333,      0, 12000)  -- crystal mace
shop:addItem(7449,      0, 600)    -- crystal sword
shop:addItem(3327,      0, 110)    -- daramian mace
shop:addItem(3328,      0, 1000)   -- daramian waraxe
shop:addItem(3421,      0, 400)    -- dark shield
shop:addItem(3388,      0, 250000) -- demon armor
shop:addItem(3420,      0, 30000)  -- demon shield
shop:addItem(7382,      0, 10000)  -- demonrage sword
shop:addItem(3356,      0, 1000)   -- devil helmet
shop:addItem(7387,      0, 3000)   -- diamond sceptre
shop:addItem(3386,      0, 40000)  -- dragon scale mail
shop:addItem(7402,      0, 15000)  -- dragon slayer
shop:addItem(7430,      0, 3000)   -- dragonbone staff
shop:addItem(10388,     0, 10000)  -- drakinata
shop:addItem(3320,      0, 10000)  -- fire axe
shop:addItem(7457,      0, 2000)   -- fur boots
shop:addItem(7432,      0, 1000)   -- furry club
shop:addItem(3281,      0, 10000)  -- giant sword
shop:addItem(3063,      0, 2000)   -- gold ring
shop:addItem(3360,      0, 20000)  -- golden armor
shop:addItem(3364,      0, 70000)  -- golden legs
shop:addItem(3422,      0, 1000000)-- great shield
shop:addItem(10323,     0, 35000)  -- guardian boots
shop:addItem(3340,      0, 8000)   -- heavy mace
shop:addItem(3330,      0, 90)     -- heavy machete
shop:addItem(10451,     0, 9000)   -- jade hat
shop:addItem(3370,      0, 5000)   -- knight armor
shop:addItem(7461,      0, 200)    -- krimhorn helmet
shop:addItem(3404,      0, 1000)   -- leopard armor
shop:addItem(5710,      0, 300)    -- light shovel
shop:addItem(828,       0, 2500)   -- lightning headband
shop:addItem(825,       0, 11000)  -- lightning robe
shop:addItem(3366,      0, 150000) -- magic plate armor
shop:addItem(5904,      0, 8000)   -- magic sulphur
shop:addItem(7463,      0, 6000)   -- mammoth fur cape
shop:addItem(7381,      0, 300)    -- mammoth whopper
shop:addItem(3414,      0, 50000)  -- mastermind shield
shop:addItem(3436,      0, 9000)   -- medusa shield
shop:addItem(7418,      0, 35000)  -- nightmare blade
shop:addItem(5461,      0, 3000)   -- pirate boots
shop:addItem(6096,      0, 1000)   -- pirate hat
shop:addItem(5918,      0, 200)    -- pirate knee breeches
shop:addItem(6095,      0, 500)    -- pirate shirt
shop:addItem(3055,      0, 2500)   -- platinum amulet
shop:addItem(7462,      0, 400)    -- ragnir helmet
shop:addItem(3392,      0, 40000)  -- royal helmet
shop:addItem(7437,      0, 7000)   -- sapphire hammer
shop:addItem(3018,      0, 200)    -- scarab amulet
shop:addItem(3440,      0, 2000)   -- scarab shield
shop:addItem(7451,      0, 5000)   -- shadow sceptre
shop:addItem(3290,      0, 500)    -- silver dagger
shop:addItem(5741,      0, 40000)  -- skull helmet
shop:addItem(10438,     0, 10000)  -- spellweaver's robe
shop:addItem(5879,      0, 100)    -- spider silk
shop:addItem(3554,      0, 20000)  -- steel boots
shop:addItem(7425,      0, 500)    -- taurus mace
shop:addItem(3309,      0, 250000) -- thunder hammer
shop:addItem(6131,      0, 150)    -- tortoise shield
shop:addItem(10392,     0, 500)    -- twin hooks
shop:addItem(3434,      0, 25000)  -- vampire shield
shop:addItem(3342,      0, 9000)   -- war axe
shop:addItem(3369,      0, 6000)   -- warrior helmet
shop:addItem(7408,      0, 1500)   -- wyvern fang
shop:addItem(10384,     0, 14000)  -- zaoan armor
shop:addItem(10406,     0, 500)    -- zaoan halberd
shop:addItem(10387,     0, 14000)  -- zaoan legs
shop:addItem(10386,     0, 14000)  -- zaoan shoes
shop:addItem(10390,     0, 30000)  -- zaoan sword
