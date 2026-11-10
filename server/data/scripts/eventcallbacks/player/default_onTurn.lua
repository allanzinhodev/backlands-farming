local tryFloors = {1, 1, -3, -1}
local holdThreshold = 350  -- ms para considerar "segurando"

local function getNextStep(pos, direction)
    local nextPos = Position(pos)
    nextPos:getNextPosition(direction)
    local nextTile = Tile(nextPos)
    if not nextTile then
        for _, try in ipairs(tryFloors) do
            nextPos.z = nextPos.z + try
            nextTile = Tile(nextPos)
            if nextTile then
                return nextPos
            end
        end
    end
    return nextPos
end

local playerData = {}

local event = Event()

function event.onTurn(player, direction)
    if not player:getGroup():getAccess() then
        return true
    end

    local guid = player:getGuid()
    local now  = os.mtime()
    local data = playerData[guid] or {}

    local isHolding = (data.lastDir == direction)
                   and data.lastTime
                   and ((now - data.lastTime) < holdThreshold)

    data.lastDir  = direction
    data.lastTime = now
    playerData[guid] = data

    if not isHolding then
        return true  -- só vira
    end

    local pos     = player:getPosition()
    local nextPos = getNextStep(pos, direction)
    if nextPos == pos then
        return true
    end

    player:teleportTo(nextPos, true)
    return true
end

event:register()
