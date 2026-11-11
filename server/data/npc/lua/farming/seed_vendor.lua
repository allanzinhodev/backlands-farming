local npcType = Game.createNpcType("Seed Vendor")
npcType:outfit({ lookType = 128, lookHead = 78, lookBody = 69, lookLegs = 58, lookFeet = 76, lookAddons = 0 })
npcType:health(150)
npcType:maxHealth(150)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(1)
npcType:defaultBehavior()

local handler = NpcsHandler("Seed Vendor")
handler:setGreetKeywords({ "hi", "hello", "oi", "ola" })
handler:setFarewellKeywords({ "bye", "farewell", "tchau" })
handler:setFarewellResponse({ "Good harvest, |PLAYERNAME|!" })

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({ "Hello |PLAYERNAME|! Say {trade} for seeds, flower pots and tools. Drop a seed on an empty pot, then use a watering can on the plant. Use a scythe to harvest ripe wheat." })
local trade = greet:keyword({ "trade", "trocar", "comprar" })
trade:respond("Here are your farm supplies.")
trade:shop(1)

local shop = NpcShop("Seed Vendor", 1)
-- Buy prices only; all IDs belong to the current item catalog.
shop:addItem(647, 2, 0) -- seeds
shop:addItem(306, 10, 0) -- empty flower pot
shop:addItem(650, 10, 0) -- watering can
shop:addItem(2873, 5, 0) -- bucket
shop:addItem(3453, 15, 0) -- scythe
shop:addItem(3457, 15, 0) -- shovel
shop:addItem(3003, 10, 0) -- rope
shop:addItem(3483, 20, 0) -- fishing rod
shop:addItem(3492, 1, 0) -- worm
