------------------------------------------------------------------------
-- Dark Rodo – RevScript (NpcsHandler)
-- Converted from: Dark_Rodo.xml + runes.lua
------------------------------------------------------------------------

local npcType = Game.createNpcType("Dark Rodo")
npcType:outfit({lookType = 133, lookHead = 0, lookBody = 86, lookLegs = 0, lookFeet = 38, lookAddons = 1})
npcType:speechBubble(2) -- SPEECHBUBBLE_TRADE
npcType:health(100)
npcType:maxHealth(100)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Dark Rodo")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Hello |PLAYERNAME|. I sell runes, potions, wands and rods."})

greet:keyword({"stuff", "wares", "offer"}):respond("Just ask me for a {trade} to see my offers.")

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

local vocItems = {[1] = 3074, [2] = 3066, [5] = 3074, [6] = 3066}

local firstItem = greet:keyword({"first rod", "first wand", "first"})
function firstItem:callback(npc, player, message, handler)
    local voc = player:getVocation():getId()
    if not vocItems[voc] then
        return false, "Sorry, you aren't a druid or a sorcerer."
    end
    if player:getStorageValue(PlayerStorageKeys.firstRod) ~= -1 then
        return false, "What? I have already gave you one {" .. ItemType(vocItems[voc]):getName() .. "}!"
    end
    return true, "So you ask me for a {" .. ItemType(vocItems[voc]):getName() .. "} to begin your adventure?"
end

local confirmFirst = firstItem:keyword("yes")
function confirmFirst:callback(npc, player, message, handler)
    local voc = player:getVocation():getId()
    if vocItems[voc] and player:getStorageValue(PlayerStorageKeys.firstRod) == -1 then
        player:addItem(vocItems[voc], 1)
        player:setStorageValue(PlayerStorageKeys.firstRod, 1)
        return true, "Here you are young adept, take care yourself."
    end
    return false, "I already gave you one!"
end

firstItem:keyword("no"):respond("Ok then.")

------------------------------------------------------------------------
-- Shop 1 – All items
------------------------------------------------------------------------
local shop = NpcShop("Dark Rodo", 1)

-- Spellbook / lightwand
shop:addItem(3059, 150, 0)      -- spellbook
shop:addItem(3047, 400, 0)      -- magic lightwand

-- Potions
shop:addItem(7876, 20, 0)       -- small health potion
shop:addItem(266,  45, 0)       -- health potion
shop:addItem(268,  50, 0)       -- mana potion
shop:addItem(236, 100, 0)       -- strong health potion
shop:addItem(237,  80, 0)       -- strong mana potion
shop:addItem(239, 190, 0)       -- great health potion
shop:addItem(238, 120, 0)       -- great mana potion
shop:addItem(7642, 190, 0)      -- great spirit potion
shop:addItem(7643, 310, 0)      -- ultimate health potion
shop:addItem(7644, 50, 0)       -- antidote potion

-- Runes
shop:addItem(3203, 375, 0)      -- animate dead
shop:addItem(3153, 250, 0)      -- antidote
shop:addItem(3161, 250, 0)      -- avalanche
shop:addItem(3147, 250, 0)      -- blank rune
shop:addItem(3178, 210, 0)      -- chameleon
shop:addItem(3177, 80, 0)       -- convince creature
shop:addItem(3148, 45, 0)       -- destroy field
shop:addItem(3197, 80, 0)       -- disintegrate
shop:addItem(3149, 250, 0)      -- energy bomb
shop:addItem(3164, 250, 0)      -- energy field
shop:addItem(3166, 250, 0)      -- energy wall
shop:addItem(3200, 250, 0)      -- explosion
shop:addItem(3192, 250, 0)      -- fire bomb
shop:addItem(3188, 250, 0)      -- fire field
shop:addItem(3190, 250, 0)      -- fire wall
shop:addItem(3189, 250, 0)      -- fireball
shop:addItem(3191, 180, 0)      -- great fireball
shop:addItem(3198, 120, 0)      -- heavy magic missile
shop:addItem(3182, 250, 0)      -- holy missile
shop:addItem(3158, 250, 0)      -- icicle
shop:addItem(3152, 95, 0)       -- intense healing
shop:addItem(3174, 40, 0)       -- light magic missile
shop:addItem(3180, 350, 0)      -- magic wall
shop:addItem(3165, 700, 0)      -- paralyze
shop:addItem(3173, 250, 0)      -- poison bomb
shop:addItem(3172, 250, 0)      -- poison field
shop:addItem(3176, 250, 0)      -- poison wall
shop:addItem(3195, 250, 0)      -- soulfire
shop:addItem(3179, 250, 0)      -- stalagmite
shop:addItem(3175, 250, 0)      -- stone shower
shop:addItem(3155, 350, 0)      -- sudden death
shop:addItem(3202, 250, 0)      -- thunderstorm
shop:addItem(3160, 175, 0)      -- ultimate healing
shop:addItem(3156, 250, 0)      -- wild growth

-- Wands (buy / sell)
shop:addItem(3074, 500,   250)   -- wand of vortex
shop:addItem(3075, 1000,  500)   -- wand of dragonbreath
shop:addItem(3072, 5000,  2500)  -- wand of decay
shop:addItem(8093, 7500,  3750)  -- wand of draconia
shop:addItem(3073, 10000, 5000)  -- wand of cosmic energy
shop:addItem(3071, 15000, 7500)  -- wand of inferno
shop:addItem(8092, 18000, 9000)  -- wand of starstorm
shop:addItem(8094, 22000, 11000) -- wand of voodoo

-- Rods (buy / sell)
shop:addItem(3066, 500,   250)   -- snakebite rod
shop:addItem(3070, 1000,  500)   -- moonlight rod
shop:addItem(3069, 5000,  2500)  -- necrotic rod
shop:addItem(8083, 7500,  3750)  -- northwind rod
shop:addItem(3065, 10000, 5000)  -- terra rod
shop:addItem(3067, 15000, 7500)  -- hailstorm rod
shop:addItem(8084, 18000, 9000)  -- springsprout rod
shop:addItem(8082, 22000, 11000) -- underworld rod