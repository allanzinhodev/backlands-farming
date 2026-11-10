-- Native OTBM zone MoveEvent test.
-- Set TEST_ZONE_ID to a zone id stored on a tile in the map/OTBM, then walk in/out.

local TEST_ZONE_ID = 1

local function formatZoneIds(zoneIds)
	if not zoneIds or #zoneIds == 0 then
		return "none"
	end

	local values = {}
	for i = 1, #zoneIds do
		values[#values + 1] = tostring(zoneIds[i])
	end
	return table.concat(values, ",")
end

local zoneStepIn = MoveEvent()

function zoneStepIn.onStepIn(creature, item, position, fromPosition, zoneId)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local tile = Tile(position)
	local tileZoneIds = tile and tile:getZoneIds() or {}
	local creatureZoneIds = creature:getZoneIds()

	player:sendTextMessage(
		MESSAGE_EVENT_ORANGE,
		string.format(
			"[ZoneTest] StepIn zoneId=%d pos=%d,%d,%d tileZones=%s creatureZones=%s",
			zoneId or 0,
			position.x,
			position.y,
			position.z,
			formatZoneIds(tileZoneIds),
			formatZoneIds(creatureZoneIds)
		)
	)
	position:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return true
end

zoneStepIn:type("stepin")
zoneStepIn:zoneid(TEST_ZONE_ID)
zoneStepIn:register()

local zoneStepOut = MoveEvent()

function zoneStepOut.onStepOut(creature, item, position, fromPosition, zoneId)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	player:sendTextMessage(
		MESSAGE_EVENT_ORANGE,
		string.format(
			"[ZoneTest] StepOut zoneId=%d pos=%d,%d,%d from=%d,%d,%d",
			zoneId or 0,
			position.x,
			position.y,
			position.z,
			fromPosition.x,
			fromPosition.y,
			fromPosition.z
		)
	)
	position:sendMagicEffect(CONST_ME_POFF)
	return true
end

zoneStepOut:type("stepout")
zoneStepOut:zoneid(TEST_ZONE_ID)
zoneStepOut:register()
