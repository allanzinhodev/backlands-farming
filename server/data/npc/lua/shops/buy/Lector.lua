-- Lector – RevScript (NpcsHandler)
local npcType = Game.createNpcType("Lector")
npcType:outfit({lookType = 128, lookHead = 20, lookBody = 100, lookLegs = 50, lookFeet = 99, lookAddons = 0})
npcType:health(100)
npcType:maxHealth(100)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Lector")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Hello |PLAYERNAME|. I sell food and mushrooms. Say {trade} to see my offers!"})

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

local shop = NpcShop("Lector", 1)
shop:addItem(3587, 8, 0)   -- banana
shop:addItem(3588, 8, 0)   -- blueberry
shop:addItem(3600, 8, 0)   -- bread
shop:addItem(3602, 8, 0)   -- brown bread
shop:addItem(3725, 8, 0)   -- brown mushroom
shop:addItem(3732, 8, 0)   -- green mushroom
shop:addItem(3723, 8, 0)   -- white mushroom
shop:addItem(3724, 8, 0)   -- red mushroom
shop:addItem(3726, 8, 0)   -- orange mushroom
shop:addItem(3727, 8, 0)   -- wood mushroom
shop:addItem(3592, 8, 0)   -- grapes
shop:addItem(6569, 8, 0)   -- candy
shop:addItem(3599, 8, 0)   -- candy cane
shop:addItem(3595, 8, 0)   -- carrot
shop:addItem(3590, 8, 0)   -- cherry
shop:addItem(3589, 8, 0)   -- coconut
shop:addItem(3597, 8, 0)   -- corncob
shop:addItem(3598, 8, 0)   -- cookie
shop:addItem(3583, 8, 0)   -- dragon ham
shop:addItem(3606, 8, 0)   -- egg
shop:addItem(3578, 8, 0)   -- fish
shop:addItem(3582, 8, 0)   -- ham
shop:addItem(229,  8, 0)   -- ice cream cone
shop:addItem(3577, 8, 0)   -- meat
shop:addItem(3593, 8, 0)   -- melon
shop:addItem(3591, 8, 0)   -- strawberry
shop:addItem(3579, 8, 0)   -- salmon
shop:addItem(3581, 8, 0)   -- shrimp
shop:addItem(3596, 8, 0)   -- tomato
shop:addItem(3585, 8, 0)   -- red apple
shop:addItem(3584, 8, 0)   -- pear
shop:addItem(3594, 8, 0)   -- pumpkin
shop:addItem(3586, 8, 0)   -- orange
