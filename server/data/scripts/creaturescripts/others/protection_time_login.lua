local CONFIG = {
    SPECTATOR_RANGE = 5,
    MESSAGE_TYPE = MESSAGE_EVENT_ADVANCE,
    MONSTER_THRESHOLDS = {
        { min = 5, text = "several monsters nearby, be careful" },
        { min = 3, text = "various monsters nearby" },
        { min = 1, text = "a monster nearby" },
    }
}

local function getProtectionTime(player)
    if player.getProtectionTime then
        return player:getProtectionTime()
    elseif player.getProtectionTicks then
        return math.floor(player:getProtectionTicks() / 1000)
    end
    return 0
end

local function getMonsterText(count)
    for _, threshold in ipairs(CONFIG.MONSTER_THRESHOLDS) do
        if count >= threshold.min then
            return threshold.text
        end
    end
    return nil
end

local function countMonstersNearby(pos, range)
    local spectators = Game.getSpectators(pos, false, false, range, range, range, range)
    local count = 0
    for _, creature in ipairs(spectators) do
        if creature:isMonster() then
            count = count + 1
        end
    end
    return count
end

local protectionMessage = CreatureEvent("protectionMessage")
function protectionMessage.onLogin(player)
    if player:getGroup():getAccess() or player:getTile():hasFlag(TILESTATE_PROTECTIONZONE) then
        return true
    end

    local protectionTime = getProtectionTime(player)
    if protectionTime <= 0 then
        return true
    end

    addEvent(function(playerId)
        local p = Player(playerId)
        if not p then return end

        local monsterCount = countMonstersNearby(p:getPosition(), CONFIG.SPECTATOR_RANGE)
        if monsterCount <= 0 then return end

        local monsterText = getMonsterText(monsterCount)
        if not monsterText then return end

        p:sendTextMessage(
            CONFIG.MESSAGE_TYPE,
            string.format(
                "You are protected for %d second%s because there are %s. Moving or attacking will end your protection.",
                protectionTime,
                protectionTime ~= 1 and "s" or "",
                monsterText
            )
        )
    end, 300, player:getId())

    return true
end
protectionMessage:register()