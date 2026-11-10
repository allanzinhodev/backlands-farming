local npcType = Game.createNpcType("Alice")
npcType:outfit({lookType = 139, lookHead = 20, lookBody = 39, lookLegs = 45, lookFeet = 7, addons = 0})
npcType:spawnRadius(4)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:defaultBehavior()

local handler = NpcsHandler(npcType)
local greet = handler:keyword(handler.greetWords)

function greet:callback(npc, player, message, handler)
    return true, "Greetings, |PLAYERNAME|. I offer five blessings for 10000 gold each. Which one do you seek?"
end

local function setupBless(blessId, keywords)
    local node = greet:keyword(keywords)

    function node:callback(npc, player, message, handler)
        return true, "Do you want to buy this blessing for 10000 gold?"
    end

    local yesNode = node:keyword("yes")
    function yesNode:callback(npc, player, message, handler)
        if player:hasBlessing(blessId) then
            return true, "You already possess this blessing."
        end

        if not player:isPremium() then
            return true, "You need a premium account to purchase blessings."
        end

        if player:getMoney() < 10000 then
            return true, "You do not have enough gold."
        end

        player:removeMoney(10000)
        player:addBlessing(blessId)
        return true, "Blessing acquired. Safe travels!"
    end

    local noNode = node:keyword("no")
    noNode:respond("Too expensive, eh?")
end

setupBless(1, {"first bless"})
setupBless(2, {"second bless"})
setupBless(3, {"third bless"})
setupBless(4, {"fourth bless"})
setupBless(5, {"fifth bless"})