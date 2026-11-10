local npcType = Game.createNpcType("The Forgotten King")
npcType:speechBubble(0)
npcType:outfit({lookType = 133, lookHead = 20, lookBody = 39, lookLegs = 45, lookFeet = 7, lookAddons = 0})
npcType:health(100)
npcType:maxHealth(100)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("The Forgotten King")

handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|."})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Greetings, |PLAYERNAME|. I can {promote} you if you meet the requirements."})

local promote = greet:keyword({"promot", "promotion", "promote"})

function promote:callback(npc, player, message, handler)
    return true, "I can promote you for 20000 gold coins. Do you want me to promote you?"
end

local yesPromote = promote:keyword("yes")

function yesPromote:callback(npc, player, message, handler)
    if player:getStorageValue(PlayerStorageKeys.promotion) == 1 then
        return true, "You are already promoted!"
    end
    
    if player:getLevel() < 20 then
        return true, "You need to reach level 20 before I can promote you."
    end
    
    local vocation = player:getVocation()
    local promotion = vocation:getPromotion()
    
    if not promotion then
        return true, "Your vocation cannot be promoted."
    end
    
    if not player:removeMoney(20000) then
        return true, "You do not have enough gold coins."
    end
    
    player:setVocation(promotion)
    player:setStorageValue(PlayerStorageKeys.promotion, 1)
    player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_RED)
    
    return true, "Congratulations! You are now promoted."
end

local noPromote = promote:keyword("no")

function noPromote:callback(npc, player, message, handler)
    return true, "Alright then, come back when you are ready."
end
