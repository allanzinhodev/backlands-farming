-- Perac – RevScript (NpcsHandler)
local npcType = Game.createNpcType("Perac")
npcType:outfit({lookType = 134, lookHead = 57, lookBody = 59, lookLegs = 40, lookFeet = 76, lookAddons = 0})
npcType:health(100)
npcType:maxHealth(100)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Perac")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Hello |PLAYERNAME|. I sell bows and ammunition. Say {trade}!"})

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

local shop = NpcShop("Perac", 1)
-- buy price, sell price
shop:addItem(3447,   2, 0)    -- arrow
shop:addItem(7368, 100, 0)    -- assassin star
shop:addItem(3446,   3, 0)    -- bolt
shop:addItem(3350, 200, 130)  -- bow
shop:addItem(3449,  56, 0)    -- burst arrow
shop:addItem(3349, 360, 150)  -- crossbow
shop:addItem(6528,  50, 0)    -- infernal bolt
shop:addItem(3448,  18, 0)    -- poison arrow
shop:addItem(3450, 200, 0)    -- power bolt
shop:addItem(7378,  15, 0)    -- royal spear
shop:addItem(3277,  10, 0)    -- spear
