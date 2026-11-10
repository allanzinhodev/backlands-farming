local RESET_DOOR_AID_BASE = 150000
local RESET_DOOR_AID_MIN  = 150001
local RESET_DOOR_AID_MAX  = 150999

local resetDoor = Action()

function resetDoor.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not player or not player:isPlayer() then
        return false
    end

    local aid = item.actionid
    if aid < RESET_DOOR_AID_MIN or aid > RESET_DOOR_AID_MAX then
        return false
    end

    local requiredResets = aid - RESET_DOOR_AID_BASE
    local playerResets   = player:getResetCount()

    if playerResets < requiredResets then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
            string.format(
                "You need %d reset(s) to open this door. You have %d.",
                requiredResets, playerResets
            )
        )
        return true
    end

    for _, value in ipairs(LevelDoorTable) do
        if value.closedDoor == item.itemid then
            item:transform(value.openDoor)
            item:getPosition():sendSingleSoundEffect(SOUND_EFFECT_TYPE_ACTION_OPEN_DOOR)
            player:teleportTo(toPosition, true)
            return true
        end
    end

    player:teleportTo(toPosition, true)
    return true
end

for aid = RESET_DOOR_AID_MIN, RESET_DOOR_AID_MAX do
    resetDoor:aid(aid)
end

resetDoor:register()
