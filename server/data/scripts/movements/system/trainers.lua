local config = {
	actionId = 1957,

	first_room_pos = {x = 1053, y = 1324, z = 6},
	distX = 18,
	distY = 14,
	rX = 5,
	rY = 2
}

local function isBusyable(position)
	local tile = Tile(position)
	if not tile then
		return false
	end

	local player = tile:getTopCreature()
	if player and player:isPlayer() then
		return false
	end

	local ground = tile:getGround()
	if not ground or ground:hasProperty(CONST_PROP_BLOCKSOLID) then
		return false
	end

	local items = tile:getItems()
	if items then
		for _, item in ipairs(items) do
			local itemType = item:getType()
			if itemType:getType() ~= ITEM_TYPE_MAGICFIELD and not itemType:isMovable() and item:hasProperty(CONST_PROP_BLOCKSOLID) then
				return false
			end
		end
	end

	return true
end

local function calculatingRoom(player, position, coluna, linha)
	if coluna >= config.rX then
		coluna = 0
		linha = (linha < (config.rY - 1)) and (linha + 1) or false
	end

	if linha then
		local room_pos = Position(position.x + (coluna * config.distX), position.y + (linha * config.distY), position.z)
		if isBusyable(room_pos) then
			player:teleportTo(room_pos)
			room_pos:sendMagicEffect(CONST_ME_TELEPORT)
		else
			calculatingRoom(player, position, coluna + 1, linha)
		end
	else
		player:sendCancelMessage("There are no available positions for you at the moment.")
	end
end

local moveEvent = MoveEvent()

function moveEvent.onStepIn(creature, item, position, fromPosition)
	if not creature:isPlayer() then
		return true
	end

	calculatingRoom(creature, config.first_room_pos, 0, 0)
	return true
end

moveEvent:type("stepin")
moveEvent:aid(config.actionId)
moveEvent:register()