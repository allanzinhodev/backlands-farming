local event = Event()

local function clearFollow(player)
	player:setFollowCreature(nil)
	player:stopWalk()
end

function event.onFightModeChanged(player, stance, chase, secure)
	local tile = player:getTile()
	if player:getHealth() <= 0 or not tile or tile:hasFlag(TILESTATE_PROTECTIONZONE) then
		clearFollow(player)
		return
	end

	local target = player:getTarget()
	if not target then
		clearFollow(player)
		return
	end

	local targetTile = target:getTile()
	if target:getHealth() <= 0 or not targetTile or targetTile:hasFlag(TILESTATE_PROTECTIONZONE) then
		clearFollow(player)
		return
	end

	if player:isChasingEnabled() then
		if not player:getFollowCreature() then
			player:setFollowCreature(target)
		end
	else
		clearFollow(player)
	end
end

event:register()
