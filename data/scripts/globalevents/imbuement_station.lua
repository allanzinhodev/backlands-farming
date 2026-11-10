--[[ 
    Script for creating imbuement stations at server startup.
    Each station is a container with a specific ID and number of slots, placed at predefined positions.
    The script ensures that the stations are present and correctly set up when the server starts.
local WORKBENCH_ID    = 27547
local WORKBENCH_SLOTS = 4
local WORKBENCH_POSITIONS = {
    --Position(1034, 1064, 5),
    -- Position(0, 0, 0),
    -- Position(0, 0, 0),
    -- Position(0, 0, 0),
}

local function ensureWorkbenchAt(pos)
    local tile = Tile(pos)
    if not tile then return end

    local existing = tile:getItemById(WORKBENCH_ID)
    if existing then
        local container = Container(existing.uid)
        if not container then
            existing:remove()
            Game.createContainer(WORKBENCH_ID, WORKBENCH_SLOTS, pos)
        end
    else
        Game.createContainer(WORKBENCH_ID, WORKBENCH_SLOTS, pos)
    end
end

local globalevent = GlobalEvent("ImbuementStationStartup")

function globalevent.onStartup()
    for _, pos in ipairs(WORKBENCH_POSITIONS) do
        ensureWorkbenchAt(pos)
    end
    return true
end

globalevent:register()
]]