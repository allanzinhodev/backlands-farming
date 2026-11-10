local internalNpcName = "Mark"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName
npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
    lookType = 128,
    lookHead = 19,
    lookBody = 57,
    lookLegs = 114,
    lookFeet = 0,
    lookAddons = 3,
}

npcConfig.flags = {
    floorchange = false,
}

local addonInfo = {
    ['first citizen addon']   = {cost = 0,      items = {{5878,50}},                                                                     outfit_female = 136, outfit_male = 128, addon = 1, storageID = 10042},
    ['second citizen addon']  = {cost = 0,      items = {{5890,50},{5902,25},{2480,1}},                                                  outfit_female = 136, outfit_male = 128, addon = 2, storageID = 10043},
    ['first hunter addon']    = {cost = 0,      items = {{5876,50},{5948,50},{5891,5},{5887,1},{5889,1},{5888,1}},                       outfit_female = 137, outfit_male = 129, addon = 1, storageID = 10044},
    ['second hunter addon']   = {cost = 0,      items = {{5875,1}},                                                                      outfit_female = 137, outfit_male = 129, addon = 2, storageID = 10045},
    ['first knight addon']    = {cost = 0,      items = {{5880,50},{5892,1}},                                                            outfit_female = 139, outfit_male = 131, addon = 1, storageID = 10046},
    ['second knight addon']   = {cost = 0,      items = {{5893,50},{11422,1},{5885,1},{5887,1}},                                         outfit_female = 139, outfit_male = 131, addon = 2, storageID = 10047},
    ['first mage addon']      = {cost = 0,      items = {{2182,1},{2186,1},{2185,1},{8911,1},{2181,1},{2183,1},{2190,1},{2191,1},{2188,1},{8921,1},{2189,1},{2187,1},{2392,30},{5809,1},{2193,20}}, outfit_female = 138, outfit_male = 130, addon = 1, storageID = 10048},
    ['second mage addon']     = {cost = 0,      items = {{5903,1}},                                                                      outfit_female = 138, outfit_male = 130, addon = 2, storageID = 10049},
    ['first summoner addon']  = {cost = 0,      items = {{5878,20}},                                                                     outfit_female = 141, outfit_male = 133, addon = 1, storageID = 10050},
    ['second summoner addon'] = {cost = 0,      items = {{5894,35},{5911,20},{5883,40},{5922,35},{5879,10},{5881,30},{5882,40},{2392,3},{5905,30}}, outfit_female = 141, outfit_male = 133, addon = 2, storageID = 10051},
    ['first barbarian addon'] = {cost = 0,      items = {{5884,1},{5885,1},{5910,25},{5911,25},{5886,10}},                               outfit_female = 147, outfit_male = 143, addon = 1, storageID = 10011},
    ['second barbarian addon']= {cost = 0,      items = {{5880,25},{5892,1},{5893,25},{5876,25}},                                        outfit_female = 147, outfit_male = 143, addon = 2, storageID = 10012},
    ['first druid addon']     = {cost = 0,      items = {{5896,20},{5897,20}},                                                           outfit_female = 148, outfit_male = 144, addon = 1, storageID = 10013},
    ['second druid addon']    = {cost = 0,      items = {{5906,100}},                                                                    outfit_female = 148, outfit_male = 144, addon = 2, storageID = 10014},
    ['first nobleman addon']  = {cost = 300000, items = {},                                                                              outfit_female = 140, outfit_male = 132, addon = 1, storageID = 10015},
    ['second nobleman addon'] = {cost = 300000, items = {},                                                                              outfit_female = 140, outfit_male = 132, addon = 2, storageID = 10016},
    ['first oriental addon']  = {cost = 0,      items = {{5945,1}},                                                                      outfit_female = 150, outfit_male = 146, addon = 1, storageID = 10017},
    ['second oriental addon'] = {cost = 0,      items = {{5883,30},{5895,30},{5891,2},{5912,30}},                                        outfit_female = 150, outfit_male = 146, addon = 2, storageID = 10018},
    ['first warrior addon']   = {cost = 0,      items = {{5925,40},{5899,40},{5884,1},{5919,1}},                                         outfit_female = 142, outfit_male = 134, addon = 1, storageID = 10019},
    ['second warrior addon']  = {cost = 0,      items = {{5880,40},{5887,1}},                                                            outfit_female = 142, outfit_male = 134, addon = 2, storageID = 10020},
    ['first wizard addon']    = {cost = 0,      items = {{2536,1},{2492,1},{2488,1},{2123,1}},                                           outfit_female = 149, outfit_male = 145, addon = 1, storageID = 10021},
    ['second wizard addon']   = {cost = 0,      items = {{5922,40},{2472,10}},                                                           outfit_female = 149, outfit_male = 145, addon = 2, storageID = 10022},
    ['first assassin addon']  = {cost = 0,      items = {{5912,20},{5910,20},{5911,20},{5913,20},{5914,20},{5909,20},{5886,10}},         outfit_female = 156, outfit_male = 152, addon = 1, storageID = 10023},
    ['second assassin addon'] = {cost = 0,      items = {{5804,1},{5930,10}},                                                            outfit_female = 156, outfit_male = 152, addon = 2, storageID = 10024},
    ['first beggar addon']    = {cost = 0,      items = {{5878,30},{5921,20},{5913,10},{5894,10}},                                       outfit_female = 157, outfit_male = 153, addon = 1, storageID = 10025},
    ['second beggar addon']   = {cost = 0,      items = {{5883,30},{2160,2}},                                                            outfit_female = 157, outfit_male = 153, addon = 2, storageID = 10026},
    ['first pirate addon']    = {cost = 0,      items = {{6098,30},{6126,30},{6097,30}},                                                 outfit_female = 155, outfit_male = 151, addon = 1, storageID = 10027},
    ['second pirate addon']   = {cost = 0,      items = {{6101,1},{6102,1},{6100,1},{6099,1}},                                           outfit_female = 155, outfit_male = 151, addon = 2, storageID = 10028},
    ['first shaman addon']    = {cost = 0,      items = {{5810,5},{3955,5},{5015,1}},                                                    outfit_female = 158, outfit_male = 154, addon = 1, storageID = 10029},
    ['second shaman addon']   = {cost = 0,      items = {{3966,5},{3967,5}},                                                             outfit_female = 158, outfit_male = 154, addon = 2, storageID = 10030},
    ['first norseman addon']  = {cost = 0,      items = {{7290,5}},                                                                      outfit_female = 252, outfit_male = 251, addon = 1, storageID = 10031},
    ['second norseman addon'] = {cost = 0,      items = {{7290,10}},                                                                     outfit_female = 252, outfit_male = 251, addon = 2, storageID = 10032},
    -- next storage 10052
}

local outfitNames = {
    'citizen', 'hunter', 'knight', 'mage', 'summoner', 'warrior',
    'barbarian', 'druid', 'nobleman', 'oriental', 'wizard', 'pirate',
    'assassin', 'beggar', 'shaman', 'norseman'
}

local pendingAddon = {}

local TOPIC_CONFIRM = 1

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink       = function(npc, interval)                    npcHandler:onThink(npc, interval) end
npcType.onAppear      = function(npc, creature)                    npcHandler:onAppear(npc, creature) end
npcType.onDisappear   = function(npc, creature)                    npcHandler:onDisappear(npc, creature) end
npcType.onMove        = function(npc, creature, from, to)          npcHandler:onMove(npc, creature, from, to) end
npcType.onSay         = function(npc, creature, type, message)     npcHandler:onSay(npc, creature, type, message) end
npcType.onCloseChannel= function(npc, creature)                    npcHandler:onCloseChannel(npc, creature) end

local function buildItemList(items)
    local parts = {}
    for _, item in ipairs(items) do
        parts[#parts + 1] = item[2] .. 'x ' .. ItemType(item[1]):getName()
    end
    return table.concat(parts, ', ')
end

local function buildRequirementText(data)
    local hasCost  = data.cost > 0
    local hasItems = #data.items > 0
    if hasCost and hasItems then
        return buildItemList(data.items) .. ' and ' .. data.cost .. ' gold coins'
    elseif hasCost then
        return data.cost .. ' gold coins'
    elseif hasItems then
        return buildItemList(data.items)
    end
    return 'nothing'
end

local function resetPlayer(playerId)
    pendingAddon[playerId] = nil
    npcHandler:setTopic(playerId, 0)
end

local function creatureSayCallback(npc, creature, type, message)
    local player = Player(creature)
    if not player then return true end

    local playerId = player:getId()
    local topic    = npcHandler:getTopic(playerId) or 0
    local msg      = message:lower()

    if addonInfo[msg] then
        local data = addonInfo[msg]

        local storageValue = player:getStorageValue(data.storageID)
        if storageValue and storageValue >= 1 then
            npcHandler:say('You already have this addon!', npc, creature)
            resetPlayer(playerId)
            return true
        end

        local reqText = buildRequirementText(data)
        npcHandler:say(
            string.format('For the %s you will need: %s. Do you have it all with you?', msg, reqText),
            npc, creature
        )
        pendingAddon[playerId] = msg
        npcHandler:setTopic(playerId, TOPIC_CONFIRM)

    elseif MsgContains(message, 'yes') and topic == TOPIC_CONFIRM then
        local addonName = pendingAddon[playerId]
        if not addonName then
            resetPlayer(playerId)
            return true
        end

        local data = addonInfo[addonName]

		local hasAllItems = true
		for _, item in ipairs(data.items) do
			if (player:getItemCount(item[1]) or 0) < item[2] then
				hasAllItems = false
				break
			end
		end

		if (player:getMoney() or 0) >= data.cost and hasAllItems then
            if data.cost > 0 then
                player:removeMoney(data.cost)
            end

            for _, item in ipairs(data.items) do
                player:removeItem(item[1], item[2])
            end

            player:addOutfitAddon(data.outfit_male,   data.addon)
            player:addOutfitAddon(data.outfit_female, data.addon)

            player:setStorageValue(data.storageID, 1)

            npcHandler:say('Here you go! Enjoy your new addon.', npc, creature)
        else
            npcHandler:say('You do not have all the required items or gold. Come back when you do.', npc, creature)
        end

        resetPlayer(playerId)

    elseif MsgContains(message, 'addons') or msg == 'addon' then
        npcHandler:say(
            'I can give you {first} or {second} addons for {' .. table.concat(outfitNames, '}, {') .. '} outfits.',
            npc, creature
        )
        resetPlayer(playerId)

    elseif MsgContains(message, 'help') then
        npcHandler:say(
            "Say 'first NAME addon' for the first addon or 'second NAME addon' for the second.\n" ..
            "Example: 'first citizen addon' or 'second knight addon'.",
            npc, creature
        )
        resetPlayer(playerId)

    elseif MsgContains(message, 'no') then
        npcHandler:say('Alright, let me know if you need anything.', npc, creature)
        resetPlayer(playerId)

    elseif (topic or 0) == TOPIC_CONFIRM then
        npcHandler:say('Come back when you have the required items.', npc, creature)
        resetPlayer(playerId)
    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET,    "Greetings |PLAYERNAME|! Say {addons} or {help} if you don't know what to do.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Goodbye, |PLAYERNAME|. Come again!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Goodbye and come again!")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)