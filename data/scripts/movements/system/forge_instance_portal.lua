local PORTAL_AID = 1001

local INSTANCE_FROM = Position(1037, 958, 7)
local INSTANCE_TO   = Position(1069, 989, 7)

local FORGE_CONTAINER_ID    = 37122
local FORGE_CONTAINER_SLOTS = 2
local FORGE_CONTAINER_POS   = Position(1054, 974, 7)

local instanceCounter = 20000
local returnPositions = {}

local function isForgeEnabled()
    return configManager.getBoolean(configKeys.FORGE_SYSTEM_ENABLED)
end

local function getInstanceCenter()
    return Position(
        math.floor((INSTANCE_FROM.x + INSTANCE_TO.x) / 2),
        math.floor((INSTANCE_FROM.y + INSTANCE_TO.y) / 2),
        INSTANCE_FROM.z
    )
end

local function isInsideInstanceArea(pos)
    return pos.x >= INSTANCE_FROM.x and pos.x <= INSTANCE_TO.x
       and pos.y >= INSTANCE_FROM.y and pos.y <= INSTANCE_TO.y
       and pos.z >= INSTANCE_FROM.z and pos.z <= INSTANCE_TO.z
end

local function getForgeContainerByInstance(pos, instanceId)
    local tile = Tile(pos)
    if not tile then return nil end

    local items = tile:getItems()
    if not items then return nil end

    for _, item in ipairs(items) do
        if item:getId() == FORGE_CONTAINER_ID and item:getInstanceId() == instanceId then
            return item
        end
    end
    return nil
end

local function hasInstancedForgeContainer(pos)
    local tile = Tile(pos)
    if not tile then return false end

    local items = tile:getItems()
    if not items then return false end

    for _, item in ipairs(items) do
        if item:getId() == FORGE_CONTAINER_ID and item:getInstanceId() ~= 0 then
            return true
        end
    end
    return false
end

local function ensureForgeContainerAt(pos)
    if hasInstancedForgeContainer(pos) then return end

    local existing = getForgeContainerByInstance(pos, 0)
    if existing then
        local container = Container(existing.uid)
        if not container then
            existing:remove()
            Game.createContainer(FORGE_CONTAINER_ID, FORGE_CONTAINER_SLOTS, pos)
        end
    else
        Game.createContainer(FORGE_CONTAINER_ID, FORGE_CONTAINER_SLOTS, pos)
    end
end

local function createInstanceContent(instanceId)
    if instanceId == 0 then return end

    local globalContainer = getForgeContainerByInstance(FORGE_CONTAINER_POS, 0)
    if globalContainer then
        globalContainer:remove()
    end

    if not getForgeContainerByInstance(FORGE_CONTAINER_POS, instanceId) then
        Game.createContainer(FORGE_CONTAINER_ID, FORGE_CONTAINER_SLOTS, FORGE_CONTAINER_POS, instanceId)
    end
end

local function cleanupInstanceContent(instanceId)
    if instanceId == 0 then return end

    local item = getForgeContainerByInstance(FORGE_CONTAINER_POS, instanceId)
    if item then
        item:remove()
    end
    ensureForgeContainerAt(FORGE_CONTAINER_POS)
end

local function cleanupInstanceMonsters(instanceId)
    if instanceId == 0 then return end

    local area = Game.getInstanceArea(instanceId)
    if not area then return end

    local cx = math.floor((area.fromPos.x + area.toPos.x) / 2)
    local cy = math.floor((area.fromPos.y + area.toPos.y) / 2)
    local searchCenter = Position(cx, cy, area.fromPos.z)
    local rangeX = math.floor(math.abs(area.toPos.x - area.fromPos.x) / 2)
    local rangeY = math.floor(math.abs(area.toPos.y - area.fromPos.y) / 2)

    local spectators = Game.getSpectators(searchCenter, false, false, rangeX, rangeX, rangeY, rangeY)
    for _, spec in ipairs(spectators) do
        if spec:isMonster() and spec:getInstanceId() == instanceId then
            local summons = spec:getSummons()
            if summons then
                for _, summon in ipairs(summons) do
                    summon:remove()
                end
            end
            spec:remove()
        end
    end
end
local function cleanupInstance(player)
    local instanceId = player:getInstanceId()
    if instanceId == 0 then return end

    cleanupInstanceMonsters(instanceId)
    cleanupInstanceContent(instanceId)
    Game.unregisterInstanceArea(instanceId)

    returnPositions[player:getGuid()] = nil
end


local ENTRY_DEST = Position(1053, 989, 7)

local portalMovement = MoveEvent()
function portalMovement.onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then return true end

    local instanceId = player:getInstanceId()

	if not isForgeEnabled() and instanceId == 0 then
		player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		player:teleportTo(fromPosition, false, CONST_ME_NONE)
		fromPosition:sendMagicEffect(CONST_ME_POFF)
		return true
	end

    if instanceId ~= 0 then
        local returnPos = returnPositions[player:getGuid()]
        cleanupInstance(player)

        if returnPos then
            player:teleportTo(returnPos)
        else
            local temple = player:getTown():getTemplePosition()
            player:teleportTo(temple)
        end
        player:setInstanceId(0)
    else
        instanceCounter = instanceCounter + 1
        local newId = instanceCounter

        returnPositions[player:getGuid()] = fromPosition
        player:setInstanceIdRaw(newId)
        Game.registerInstanceArea(newId, INSTANCE_FROM, INSTANCE_TO)

        createInstanceContent(newId)

        player:teleportTo(ENTRY_DEST)
    end

    return true
end
portalMovement:aid(PORTAL_AID)
portalMovement:type("stepin")
portalMovement:register()

local logoutEvent = CreatureEvent("ForgeInstanceLogout")
function logoutEvent.onLogout(player)
    local instanceId = player:getInstanceId()
    if instanceId ~= 0 and isInsideInstanceArea(player:getPosition()) then
        cleanupInstance(player)
        local temple = player:getTown():getTemplePosition()
        player:teleportTo(temple)
        player:setInstanceId(0)
    end
    return true
end
logoutEvent:type("logout")
logoutEvent:register()

local loginEvent = CreatureEvent("ForgeInstanceLogin")
function loginEvent.onLogin(player)
    player:registerEvent("ForgeInstanceLogout")

    local pos = player:getPosition()
    if isInsideInstanceArea(pos) then
        local temple = player:getTown():getTemplePosition()
        if player:getInstanceId() ~= 0 then
            player:teleportTo(temple)
            player:setInstanceId(0)
        else
            player:setInstanceIdRaw(0)
            player:teleportTo(temple)
        end

    end

    return true
end
loginEvent:type("login")
loginEvent:register()
