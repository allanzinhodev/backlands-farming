local internalNpcName = "Captain"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 4

npcConfig.outfit = {
    lookType = 151,
    lookHead = 78,
    lookBody = 115,
    lookLegs = 85,
    lookFeet = 114,
    lookAddons = 2,
}

npcConfig.flags = {
    floorchange = false,
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval)
    npcHandler:onThink(npc, interval)
end

npcType.onAppear = function(npc, creature)
    npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
    npcHandler:onDisappear(npc, creature)
end

npcType.onMove = function(npc, creature, fromPosition, toPosition)
    npcHandler:onMove(npc, creature, fromPosition, toPosition)
end

npcType.onSay = function(npc, creature, type, message)
    npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
    npcHandler:onCloseChannel(npc, creature)
end

local function addTravelKeyword(keyword, cost, destination, premium)
    local text = "Do you seek a passage to " .. keyword:titleCase() .. " for |TRAVELCOST|?"
    local travelKeyword = keywordHandler:addKeyword({keyword}, StdModule.say, {npcHandler = npcHandler, text = text, cost = cost})
    travelKeyword:addChildKeyword({"yes"}, StdModule.travel, {npcHandler = npcHandler, premium = premium, cost = cost, destination = destination})
    travelKeyword:addChildKeyword({"no"}, StdModule.say, {npcHandler = npcHandler, text = "We would like to serve you some time.", reset = true})
end

addTravelKeyword("classiccity", 100, Position(1014, 926, 6), true)
addTravelKeyword("timberport", 120, Position(733, 973, 6), true)
addTravelKeyword("sandstone", 160, Position(1022, 1084, 6), true)
addTravelKeyword("ice", 150, Position(1167, 902, 7), true)

keywordHandler:addKeyword({"trip", "travel", "sail", "passage", "destination"}, StdModule.say, {npcHandler = npcHandler, text = "Where do you want to go? To Classiccity, Timberport, Sandstone or Ice?"})
keywordHandler:addKeyword({"captain"}, StdModule.say, {npcHandler = npcHandler, text = "I am the captain of this sailing-ship."})

npcHandler:setMessage(MESSAGE_GREET, "Welcome on board, |PLAYERNAME|.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell, |PLAYERNAME|.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Farewell, |PLAYERNAME|.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)