local config = {
    storage = 45002,
    cooldown = 24 * 60 * 60, -- 24 hours in seconds
    charges = 1000,
    rewards = {
        [4] = 31208, -- Knight
        [3] = 31211, -- Paladin
        [2] = 31212, -- Druid
        [1] = 31213  -- Sorcerer
    }
}

local function sendStoreInboxRewardMessage(player, itemName)
    if player:isUsingOtcV8() then
        player:sendTextMessage(MESSAGE_INFO_DESCR, "You received your daily " .. itemName .. "! Check your store inbox.")
    else
        player:sendTextMessage(MESSAGE_INFO_DESCR, "You received your daily " .. itemName .. "! Type !storeinbox to open your inbox.")
    end
end

local dailyReward = TalkAction("!dailyexercise")
function dailyReward.onSay(player, words, param)
    local storageValue = player:getStorageValue(config.storage) or -1
    
    if storageValue ~= -1 and storageValue > os.time() then
        player:sendCancelMessage("You already claimed your daily reward. Try again in " .. os.date("!%H:%M:%S", storageValue - os.time()) .. ".")
        return false
    end

    local vocation = player:getVocation()
    local baseVocId = vocation:getBase():getId()
    local rewardId = config.rewards[baseVocId]
    
    if not rewardId then
        player:sendCancelMessage("Your vocation cannot receive this reward.")
        return false
    end

    local inbox = player:getStoreInbox()
    local item = Game.createItem(rewardId, 1)
    if not inbox or not item then
        player:sendCancelMessage("Could not create your reward. Please contact an administrator.")
        return false
    end

    item:setAttribute(ITEM_ATTRIBUTE_CHARGES, config.charges)
    local itemName = item:getName()
    if inbox:addItemEx(item) ~= RETURNVALUE_NOERROR then
        item:remove()
        player:sendCancelMessage("Your store inbox does not have enough space to receive the reward.")
        return false
    end

    player:setStorageValue(config.storage, os.time() + config.cooldown)
    sendStoreInboxRewardMessage(player, itemName)
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    return false
end
dailyReward:register()
