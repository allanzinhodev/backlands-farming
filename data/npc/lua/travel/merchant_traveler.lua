--[[
    Merchant NPC example using the RevScript NPC system.
    Demonstrates: shop with discount, keywords and random responses.

    To spawn it, place an NPC named "Merchant" in the map XML or use
    the place_npc talkaction with the name "Merchant".
]]

-- speechBubble: 0 = none, 2 = trade, 3 = quest
local merchant = Game.createNpcType("Merchant")
merchant:speechBubble(2)
merchant:outfit({lookType = 128, lookHead = 40, lookBody = 95, lookLegs = 114, lookFeet = 27, lookAddons = 1})
merchant:health(100)
merchant:maxHealth(100)
merchant:walkInterval(2000)
merchant:walkSpeed(100)
merchant:spawnRadius(3)
merchant:defaultBehavior()

------------------------------------------------------------------------
-- Handler
------------------------------------------------------------------------
local handler = NpcsHandler("Merchant")

handler:setGreetKeywords({"hi", "hello", "oi", "ola"})
handler:setFarewellKeywords({"bye", "farewell", "tchau"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!", "Come back soon, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({
    "Welcome, |PLAYERNAME|! I sell {weapons} and {shields}.",
    "Hello |PLAYERNAME|! Ask me about {weapons} or {shields}."
})

------------------------------------------------------------------------
-- Weapons shop
------------------------------------------------------------------------
local weapons = greet:keyword({"weapons", "weapon"})
weapons:respond("I offer fine weapons. Do you want to see them?")

local buyWeapons = weapons:keyword("yes")
buyWeapons:respond({"Here are my weapons!", "Take a look at these fine blades!"})
buyWeapons:shop(1)

local noWeapons = weapons:keyword("no")
noWeapons:respond("Very well, let me know if you change your mind.")
noWeapons:farewell()

------------------------------------------------------------------------
-- Shields shop
------------------------------------------------------------------------
local shields = greet:keyword("shields")
shields:respond("I have sturdy shields for sale. Interested?")

local buyShields = shields:keyword("yes")
buyShields:respond("Here are my shields!")
buyShields:shop(2)

local noShields = shields:keyword("no")
noShields:respond("As you wish.")
noShields:farewell()

------------------------------------------------------------------------
-- Shops
------------------------------------------------------------------------
-- Shop 1: weapons (storage 9998 = 10% discount)
local shop1 = NpcShop("Merchant", 1)
shop1:addItem(3285, 2000, 1000) -- longsword
shop1:addItem(3267, 50, 25) -- dagger
shop1:addDiscount(9998, 10)

-- Shop 2: shields (storage 9999 = storage value as discount percent)
local shop2 = NpcShop("Merchant", 2)
shop2:addItem(3412, 200, 50) -- wooden shield
shop2:addItem(3409, 500, 200) -- steel shield
shop2:addDiscount(9999)

------------------------------------------------------------------------
-- Traveler NPC example
------------------------------------------------------------------------
local traveler = Game.createNpcType("Traveler")
traveler:speechBubble(0)
traveler:outfit({lookType = 151, lookHead = 78, lookBody = 115, lookLegs = 85, lookFeet = 114, lookAddons = 2})
traveler:walkInterval(3000)
traveler:walkSpeed(100)
traveler:spawnRadius(2)
traveler:defaultBehavior()

local travelerHandler = NpcsHandler("Traveler")

local destinations = {
    temple = {
        position = Position(1000, 1000, 7),
        money = 100,
        level = 1,
        premium = false,
    },
    city = {
        position = Position(1000, 998, 7),
        money = 300,
        level = 20,
        premium = false,
    },
}

travelerHandler:travelTo(destinations)
