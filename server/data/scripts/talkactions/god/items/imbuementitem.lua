local talkaction = TalkAction("/imbuementitem")

-- Usage examples:
-- /imbuementitem underworld rod, vampirism, powerful vampirism
-- /imbuementitem underworld rod, vampirism, powerful vampirism, void, powerful void

function talkaction.onSay(player, words, param)
    if not configManager.getBoolean(configKeys.IMBUEMENT_SYSTEM_ENABLED) then
        player:sendCancelMessage("Imbuement system is disabled.")
        return false
    end

    local split = param:splitTrimmed(",")
    if not split[1] or split[1] == "" then
        player:sendCancelMessage("Usage: /imbuementitem <item name|id>, <group>, <imbuement name>, ...")
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

    local item = player:addItem(itemType:getId(), 1, true)
    if not item then
        player:sendCancelMessage("Could not create item.")
        return false
    end

    local slots = item:getImbuementSlots()
    if slots <= 0 then
        player:sendCancelMessage("This item does not have imbuement slots.")
        return false
    end

    local definitions = Game.getImbuementDefinitions()
    local appliedCount = 0
    
    -- Start from index 2, take pairs (Group, Name) as per user's examples
    for i = 2, #split, 2 do
        local groupName = split[i]
        local imbuementName = split[i+1]
        
        if not imbuementName then
            player:sendCancelMessage("Missing imbuement name for group: " .. groupName)
            break
        end

        local foundDef = nil
        for _, def in ipairs(definitions) do
            local fullName = (def.baseName and def.baseName ~= "" and (def.baseName .. " " .. def.name) or def.name):lower()
            local baseName = (def.baseName or ""):lower()
            
            -- Match Group + Full Name OR Group + Tier Name (e.g. Vampirism, Powerful)
            if def.name:lower() == groupName:lower() and (fullName == imbuementName:lower() or baseName == imbuementName:lower()) then
                foundDef = def
                break
            end
        end

        if foundDef then
            if appliedCount < slots then
                local imbuement = Imbuement(foundDef.imbuementType, foundDef.value, foundDef.duration, foundDef.decayType, foundDef.baseId)
                if item:addImbuement(imbuement) then
                    appliedCount = appliedCount + 1
                else
                    player:sendCancelMessage("Failed to add imbuement: " .. imbuementName)
                end
            else
                player:sendCancelMessage("Item has no more slots for: " .. imbuementName)
                break
            end
        else
            player:sendCancelMessage("Imbuement not found: " .. imbuementName .. " in group " .. groupName)
        end
    end

    if appliedCount > 0 then
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Created %s with %d imbuements.", item:getNameDescription(), appliedCount))
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Created %s without imbuements.", item:getNameDescription()))
    end

    return false
end

talkaction:separator(" ")
talkaction:accountType(6)
talkaction:access(true)
talkaction:register()
