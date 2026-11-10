local gotoInfluenced = TalkAction("/gotoinfluenced")
function gotoInfluenced.onSay(player, words, param)
    local targetType = "influenced"
    local list = {}

    -- Parse and clean parameter (handles commas, spaces, etc.)
    param = param:lower():gsub(",", ""):trim()
    if param == "fiendish" then
        targetType = "fiendish"
        list = Game.getFiendishCreatures()
    else
        list = Game.getInfluencedCreatures()
    end

    if #list == 0 then
        player:sendTextMessage(MESSAGE_EVENT_ORANGE,
            string.format("[GM] There are no active %s creatures at the moment.", targetType))
        return false
    end

    local playerPos = player:getPosition()
    local closest = nil
    local closestDist = math.huge

    for _, monster in ipairs(list) do
        local mPos = monster:getPosition()
        local dist = math.abs(playerPos.x - mPos.x) + math.abs(playerPos.y - mPos.y)
                   + math.abs(playerPos.z - mPos.z) * 10
        if dist < closestDist then
            closestDist = dist
            closest = monster
        end
    end

    if not closest then
        player:sendTextMessage(MESSAGE_EVENT_ORANGE,
            string.format("[GM] There are no active %s creatures at the moment.", targetType))
        return false
    end

    local destPos = closest:getPosition()
    player:teleportTo(destPos)
    destPos:sendMagicEffect(CONST_ME_TELEPORT)

    player:sendTextMessage(MESSAGE_EVENT_ORANGE,
        string.format("[GM] Teleported to %s.", closest:getName()))

    return false
end
gotoInfluenced:separator(" ")
gotoInfluenced:accountType(6)
gotoInfluenced:access(true)
gotoInfluenced:register()
