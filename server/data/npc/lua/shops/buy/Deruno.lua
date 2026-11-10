-- Deruno – RevScript (NpcsHandler)
local npcType = Game.createNpcType("Deruno")
npcType:outfit({lookType = 132, lookHead = 20, lookBody = 39, lookLegs = 45, lookFeet = 7, lookAddons = 0})
npcType:health(100)
npcType:maxHealth(100)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Deruno")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Hello |PLAYERNAME|. Say {trade} to see my offers."})

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

local shop = NpcShop("Deruno", 1)
shop:addItem(3503, 15, 0)   -- parcel
shop:addItem(3507,  5, 0)   -- label
shop:addItem(3505, 10, 0)   -- letter
