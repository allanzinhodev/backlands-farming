-- Riona – RevScript (NpcsHandler)
local npcType = Game.createNpcType("Riona")
npcType:speechBubble(2) -- SPEECHBUBBLE_TRADE
npcType:outfit({lookType = 138, lookHead = 57, lookBody = 59, lookLegs = 40, lookFeet = 76, lookAddons = 0})
npcType:health(100)
npcType:maxHealth(100)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Riona")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Hello |PLAYERNAME|. I sell backpacks and tools. Say {trade} to see my offers!"})

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

local shop = NpcShop("Riona", 1)
shop:addItem(2854,    20, 0)   -- backpack
shop:addItem(3253, 10000, 0)   -- backpack of holding
shop:addItem(5949,    50, 0)   -- beach backpack
shop:addItem(2869,    50, 0)   -- blue backpack
shop:addItem(8860,    50, 0)   -- brocade backpack
shop:addItem(2872,    50, 0)   -- camouflage backpack
shop:addItem(9605,    50, 0)   -- crown backpack
shop:addItem(9601,    50, 0)   -- demon backpack
shop:addItem(7342,    50, 0)   -- fur backpack
shop:addItem(2871,    50, 0)   -- golden backpack
shop:addItem(2865,    50, 0)   -- green backpack
shop:addItem(10327,   50, 0)   -- minotaur backpack
shop:addItem(9604,    50, 0)   -- moon backpack
shop:addItem(9602,    50, 0)   -- orange backpack
shop:addItem(5926,    50, 0)   -- pirate backpack
shop:addItem(2866,    50, 0)   -- yellow backpack
shop:addItem(5942, 20000, 0)   -- blessed wooden stake
shop:addItem(5908, 10000, 0)   -- obsidian knife
shop:addItem(2983,  1000, 0)   -- flower bowl
shop:addItem(2981,  1000, 0)   -- god flowers
shop:addItem(2984,  1000, 0)   -- honey flower
shop:addItem(2985,  1000, 0)   -- potted flower
shop:addItem(3308,  1000, 0)   -- machete
shop:addItem(3453,  1500, 0)   -- scythe
shop:addItem(3456,    10, 0)   -- pick
shop:addItem(3003,    50, 0)   -- rope
shop:addItem(3457,    20, 0)   -- shovel
shop:addItem(5710,  2000, 0)   -- light shovel
shop:addItem(3483,   100, 0)   -- fishing rod
shop:addItem(3492,    35, 0)   -- worm
