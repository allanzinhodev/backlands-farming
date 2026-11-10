-- Obi – RevScript (NpcsHandler)
local npcType = Game.createNpcType("Obi")
npcType:outfit({lookType = 134, lookHead = 115, lookBody = 10, lookLegs = 90, lookFeet = 115, lookAddons = 0})
npcType:health(150)
npcType:maxHealth(150)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Obi")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Hello |PLAYERNAME|. I sell chairs, tables, plants, containers and more. Say {trade}!"})

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

local shop = NpcShop("Obi", 1)
shop:addItem(2793,  500, 0)   -- bamboo table
shop:addItem(2788,  500, 0)   -- bamboo table (alt)
shop:addItem(2812,  500, 0)   -- christmas tree
shop:addItem(2792,  500, 0)   -- bird cage
shop:addItem(9056,  500, 0)   -- black skull
shop:addItem(3734, 1000, 0)   -- blood herb
shop:addItem(2394,  500, 0)   -- blue pillow
shop:addItem(2398,  500, 0)   -- blue round pillow
shop:addItem(2659,  500, 0)   -- blue tapestry
shop:addItem(6372,  500, 0)   -- bookcase
shop:addItem(2789,  500, 0)   -- box
shop:addItem(2787,  500, 0)   -- carved stone table
shop:addItem(2472,  500, 0)   -- chest
shop:addItem(2805,  500, 0)   -- christmas tree (alt)
shop:addItem(2807,  500, 0)   -- clock
shop:addItem(2782,  500, 0)   -- coal basin
shop:addItem(9028,  500, 0)   -- crystal of balance
shop:addItem(9027,  500, 0)   -- crystal of focus
shop:addItem(9066,  500, 0)   -- green crystal pedestal
shop:addItem(9065,  500, 0)   -- light blue crystal pedestal
shop:addItem(9064,  500, 0)   -- blue crystal pedestal
shop:addItem(9063,  500, 0)   -- red crystal pedestal
shop:addItem(9040,  500, 0)   -- dracoyle statue east
shop:addItem(9035,  500, 0)   -- dracoyle statue south
shop:addItem(2795,  500, 0)   -- drawer
shop:addItem(2806,  500, 0)   -- dresser
shop:addItem(8775,  500, 0)   -- gear wheel
shop:addItem(2801,  500, 0)   -- globe
shop:addItem(2981, 1000, 0)   -- god flowers
shop:addItem(9059,  500, 0)   -- gold lamp
shop:addItem(2778,  500, 0)   -- green cushioned chair
shop:addItem(2803,  500, 0)   -- green flower
shop:addItem(2387,  500, 0)   -- green pillow
shop:addItem(2396,  500, 0)   -- green round pillow
shop:addItem(2647,  500, 0)   -- green tapestry
shop:addItem(2791,  500, 0)   -- harp
shop:addItem(2393,  500, 0)   -- heart pillow
shop:addItem(2811,  500, 0)   -- indoor plant
shop:addItem(2780,  500, 0)   -- ivory chair
shop:addItem(2794,  500, 0)   -- large trunk
shop:addItem(2808,  500, 0)   -- locker
shop:addItem(2653,  500, 0)   -- orange tapestry
shop:addItem(2800,  500, 0)   -- piano
shop:addItem(2802,  500, 0)   -- pink flower
shop:addItem(2386,  500, 0)   -- purple pillow
shop:addItem(2400,  500, 0)   -- purple round pillow
shop:addItem(2644,  500, 0)   -- purple tapestry
shop:addItem(2777,  500, 0)   -- red cushioned chair
shop:addItem(2395,  500, 0)   -- red pillow
shop:addItem(2399,  500, 0)   -- red round pillow
shop:addItem(2656,  500, 0)   -- red tapestry
shop:addItem(2785,  500, 0)   -- round table
-- small round table (2316) and square table (2315) removed: not pickupable
shop:addItem(2776,  500, 0)   -- sofa chair
shop:addItem(2798,  500, 0)   -- table lamp
shop:addItem(2809,  500, 0)   -- trough
shop:addItem(2392,  500, 0)   -- turqoise pillow
shop:addItem(2401,  500, 0)   -- turqoise round pillow
shop:addItem(2779,  500, 0)   -- tusk chair
shop:addItem(9041,  500, 0)   -- vampiric crest
shop:addItem(8923,  500, 0)   -- velvet tapestry
shop:addItem(2974, 50000, 0)  -- water pipe
shop:addItem(2980, 1000, 0)   -- water pipe (deluxe)
shop:addItem(2667,  500, 0)   -- white tapestry
shop:addItem(2775,  500, 0)   -- wooden chair
shop:addItem(2650,  500, 0)   -- yellow tapestry
