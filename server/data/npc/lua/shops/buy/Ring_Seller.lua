-- Ring Seller – RevScript (NpcsHandler)
local npcType = Game.createNpcType("Ring Seller")
npcType:outfit({lookType = 144, lookHead = 76, lookBody = 115, lookLegs = 0, lookFeet = 78, lookAddons = 3})
npcType:health(100)
npcType:maxHealth(100)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Ring Seller")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Hello |PLAYERNAME|. I sell rings useful for your adventures. Say {trade} to see my offers!"})

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

local shop = NpcShop("Ring Seller", 1)
shop:addItem(3092,  2000, 0)  -- axe ring
shop:addItem(3093,  2000, 0)  -- club ring
shop:addItem(3097,  2000, 0)  -- dwarven ring
shop:addItem(3051,  2000, 0)  -- energy ring
shop:addItem(3052,  2000, 0)  -- life ring
shop:addItem(3050,  2000, 0)  -- power ring
shop:addItem(3098,  4000, 0)  -- ring of healing
shop:addItem(3091,  2000, 0)  -- sword ring
shop:addItem(3053, 20000, 0)  -- time ring
