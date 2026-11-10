local ENTRY_PORTAL_AID = 1002
local EXIT_PORTAL_AID  = 1003

local INSTANCE_FROM = Position(1025, 1071, 5)
local INSTANCE_TO   = Position(1041, 1095, 5)

local WORKBENCH_ID    = 27547
local WORKBENCH_SLOTS = 4
local WORKBENCH_POSITIONS = {
    Position(1034, 1064, 5),
}

local NPC_NAME = "Imbuement Master"
local NPC_POS  = Position(1033, 1068, 5)

local instanceCounter = 10000
local returnPositions = {}
local instanceNpcs = {}

local function isImbuementEnabled()
    return configManager.getBoolean(configKeys.IMBUEMENT_SYSTEM_ENABLED)
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

local function getWorkbenchByInstance(pos, instanceId)
    local tile = Tile(pos)
    if not tile then return nil end

    local items = tile:getItems()
    if not items then return nil end

    for _, item in ipairs(items) do
        if item:getId() == WORKBENCH_ID and item:getInstanceId() == instanceId then
            return item
        end
    end
    return nil
end

local function hasInstancedWorkbench(pos)
    local tile = Tile(pos)
    if not tile then return false end

    local items = tile:getItems()
    if not items then return false end

    for _, item in ipairs(items) do
        if item:getId() == WORKBENCH_ID and item:getInstanceId() ~= 0 then
            return true
        end
    end
    return false
end

local function ensureWorkbenchAt(pos)
    if hasInstancedWorkbench(pos) then return end

    local existing = getWorkbenchByInstance(pos, 0)
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

local function createInstanceContent(instanceId)
    if instanceId == 0 then return end

    for _, pos in ipairs(WORKBENCH_POSITIONS) do
        local globalWorkbench = getWorkbenchByInstance(pos, 0)
        if globalWorkbench then
            globalWorkbench:remove()
        end

        if not getWorkbenchByInstance(pos, instanceId) then
            Game.createContainer(WORKBENCH_ID, WORKBENCH_SLOTS, pos, instanceId)
        end
    end

    local npc = Game.createNpc(NPC_NAME, NPC_POS, false, true, CONST_ME_NONE, instanceId)
    if npc then
        instanceNpcs[instanceId] = npc
    end
end

local function cleanupInstanceContent(instanceId)
    if instanceId == 0 then return end

    local npc = instanceNpcs[instanceId]
    if npc then
        npc:remove()
        instanceNpcs[instanceId] = nil
    end

    for _, pos in ipairs(WORKBENCH_POSITIONS) do
        local item = getWorkbenchByInstance(pos, instanceId)
        if item then
            item:remove()
        end
        ensureWorkbenchAt(pos)
    end
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

local entryMovement = MoveEvent()
function entryMovement.onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then return true end

	if not isImbuementEnabled() then
		player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		player:teleportTo(fromPosition, false, CONST_ME_NONE)
		fromPosition:sendMagicEffect(CONST_ME_POFF)
		return true
	end

	if player:getInstanceId() ~= 0 then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "You are already inside an instance.")
		player:teleportTo(fromPosition, false, CONST_ME_NONE)
		return false
	end

    instanceCounter = instanceCounter + 1
    local instanceId = instanceCounter

    returnPositions[player:getGuid()] = fromPosition
    player:setInstanceIdRaw(instanceId)
    Game.registerInstanceArea(instanceId, INSTANCE_FROM, INSTANCE_TO)

    createInstanceContent(instanceId)

    local dest = getInstanceCenter()
    local free = player:getClosestFreePosition(dest, false)
    if free.x ~= 0 then dest = free end

    player:teleportTo(dest)

    return true
end
entryMovement:aid(ENTRY_PORTAL_AID)
entryMovement:type("stepin")
entryMovement:register()

local exitMovement = MoveEvent()
function exitMovement.onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then return true end

    local instanceId = player:getInstanceId()
    if instanceId == 0 then return true end

    local returnPos = returnPositions[player:getGuid()]
    cleanupInstance(player)

    if returnPos then
        player:teleportTo(returnPos)
    else
        local temple = player:getTown():getTemplePosition()
        player:teleportTo(temple)
    end
    player:setInstanceId(0)

    return true
end
exitMovement:aid(EXIT_PORTAL_AID)
exitMovement:type("stepin")
exitMovement:register()

local logoutEvent = CreatureEvent("InstancePortalLogout")
function logoutEvent.onLogout(player)
    local instanceId = player:getInstanceId()
    if instanceId ~= 0 then
        cleanupInstance(player)
        local temple = player:getTown():getTemplePosition()
        player:teleportTo(temple)
        player:setInstanceId(0)
    end
    return true
end
logoutEvent:type("logout")
logoutEvent:register()

local loginEvent = CreatureEvent("InstancePortalLogin")
function loginEvent.onLogin(player)
    player:registerEvent("InstancePortalLogout")

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
