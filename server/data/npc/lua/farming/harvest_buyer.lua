local npcType = Game.createNpcType("Harvest Buyer")
npcType:outfit({ lookType = 136, lookHead = 57, lookBody = 82, lookLegs = 114, lookFeet = 76, lookAddons = 0 })
npcType:health(150)
npcType:maxHealth(150)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(1)
npcType:defaultBehavior()

local handler = NpcsHandler("Harvest Buyer")
handler:setGreetKeywords({ "hi", "hello", "oi", "ola" })
handler:setFarewellKeywords({ "bye", "farewell", "tchau" })
handler:setFarewellResponse({ "Come back with your next harvest, |PLAYERNAME|!" })

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({ "Hello |PLAYERNAME|! I buy wheat, fruit, vegetables, fish and bread. Say {trade} to sell your harvest." })
local trade = greet:keyword({ "trade", "trocar", "vender" })
trade:respond("Let me see your harvest.")
trade:shop(1)

local shop = NpcShop("Harvest Buyer", 1)
-- Sell prices only: buying supplies and reselling them cannot create money.
shop:addItem(3605, 0, 3) -- bunch of wheat
shop:addItem(3603, 0, 4) -- flour
shop:addItem(3600, 0, 6) -- bread
shop:addItem(3585, 0, 2) -- red apple
shop:addItem(3586, 0, 2) -- orange
shop:addItem(3587, 0, 2) -- banana
shop:addItem(3588, 0, 1) -- blueberry
shop:addItem(3590, 0, 1) -- cherry
shop:addItem(3591, 0, 2) -- strawberry
shop:addItem(3592, 0, 2) -- grapes
shop:addItem(3595, 0, 2) -- carrot
shop:addItem(3596, 0, 2) -- tomato
shop:addItem(3578, 0, 4) -- fish caught in the village pond
shop:addItem(3725, 0, 2) -- brown mushroom
