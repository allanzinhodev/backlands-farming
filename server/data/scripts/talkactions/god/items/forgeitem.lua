local talkaction = TalkAction("/forgeitem")

-- Usage examples:
-- /forgeitem amazon armor, tier 1
-- /forgeitem 1234, tier 2, classification 1

function talkaction.onSay(player, words, param)
    local split = param:splitTrimmed(",")
    if not split[1] or split[1] == "" then
        player:sendCancelMessage("Usage: /forgeitem <item name|id>, [tier N], [classification N]")
        return false
    end

    local itemType = ItemType(split[1])
    if not itemType or itemType:getId() == 0 then
        itemType = ItemType(tonumber(split[1]))
        if not itemType or itemType:getId() == 0 then
            player:sendCancelMessage("There is no item with that id or name.")
            return false
        end
    end

    local tier = 0
    local classification = 0
    for i = 2, #split do
        local s = split[i]:lower():trim()
        local t = s:match("tier%s*(%d+)")
        if t then tier = tonumber(t) end
        local c = s:match("classification%s*(%d+)")
        if c then classification = tonumber(c) end
        if not t then
            local ts = s:match("^t(%d+)")
            if ts then tier = tonumber(ts) end
        end
        if not c then
            local cs = s:match("^c(%d+)")
            if cs then classification = tonumber(cs) end
        end
    end

    local count = 1
    local result = nil
    if itemType:isStackable() then
        result = player:addItem(itemType:getId(), count, true)
    else
        result = player:addItem(itemType:getId(), 1, true, count)
    end

    if result then
        if classification and classification > 0 then
            result:setAttribute(ITEM_ATTRIBUTE_CLASSIFICATION, classification)
        end
        if tier and tier > 0 then
            result:setAttribute(ITEM_ATTRIBUTE_TIER, tier)
        end
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Created %s (Tier = %d Classification =%d)", result:getNameDescription(), result:getTier(), result:getClassification()))
    else
        player:sendCancelMessage("Could not create item.")
    end

    return false
end

talkaction:separator(" ")
talkaction:accountType(6)
talkaction:access(true)
talkaction:register()
