local RESET_TILE_AID_BASE = 150000
local RESET_TILE_AID_MIN  = 150001
local RESET_TILE_AID_MAX  = 150999

local resetTile = MoveEvent()
resetTile:type("stepin")

function resetTile.onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player or player:isInGhostMode() then
        return true
    end

    local aid = item.actionid
    if aid < RESET_TILE_AID_MIN or aid > RESET_TILE_AID_MAX then
        return true
    end

    local requiredResets = aid - RESET_TILE_AID_BASE
    local playerResets   = player:getResetCount()

    if playerResets < requiredResets then
        player:teleportTo(fromPosition, false)
        position:sendMagicEffect(CONST_ME_MAGIC_BLUE)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
            string.format(
                "You need %d reset(s) to pass here. You have %d.",
                requiredResets, playerResets
            )
        )
    end

    return true
end

for aid = RESET_TILE_AID_MIN, RESET_TILE_AID_MAX do
    resetTile:aid(aid)
end

resetTile:register()
