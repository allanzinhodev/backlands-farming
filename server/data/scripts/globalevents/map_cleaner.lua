local mapCleanScheduled = false

local function cleanMapTimer(clean)
    if not clean then
        Game.broadcastMessage("Map will be cleaned in 2 minutes. Be aware, there may be some lag.", MESSAGE_STATUS_WARNING)
        addEvent(cleanMapTimer, 2 * 60 * 1000, true)
    else
        local removed = cleanMap()
        if removed > 0 then
            Game.broadcastMessage(string.format("Map cleaned successfully! %d item%s removed from the ground.", removed, removed > 1 and "s" or ""), MESSAGE_STATUS_WARNING)
        else
            Game.broadcastMessage("Map cleaned successfully! No items found on the ground.", MESSAGE_STATUS_WARNING)
        end
        mapCleanScheduled = false
    end
end

local mapCleaner = GlobalEvent("MapCleaner")
function mapCleaner.onThink(interval, lastExecution)
    if mapCleanScheduled then
        return true
    end
    mapCleanScheduled = true
    Game.broadcastMessage("Map will be cleaned in 5 minutes. Please pick up your items!", MESSAGE_STATUS_WARNING)
    addEvent(cleanMapTimer, 3 * 60 * 1000, false)
    return true
end
mapCleaner:interval(30 * 60 * 1000)
mapCleaner:register()