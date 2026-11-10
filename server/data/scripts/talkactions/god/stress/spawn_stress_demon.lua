local function stressMessage(player, text)
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[stress-demon] " .. text)
end

local function randomNearbyPosition(center)
	local position = Position(center.x + math.random(-3, 3), center.y + math.random(-3, 3), center.z)
	if position.x == center.x and position.y == center.y then
		position.x = position.x + 1
	end
	return position
end

local spawnStressDemon = TalkAction("/spawnstressdemon")

function spawnStressDemon.onSay(player, words, param)
	if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
		return false
	end

	local count = tonumber(param) or 1
	count = math.max(1, math.min(count, 25))

	local spawned = 0
	local center = player:getPosition()
	for _ = 1, count do
		local monster = Game.createMonster("Stress Demon", randomNearbyPosition(center), true, true)
		if monster then
			spawned = spawned + 1
		end
	end

	if spawned == 0 then
		stressMessage(player, "No Stress Demon spawned. Restart or reload monsters/scripts after adding the monster file.")
	else
		stressMessage(player, string.format("Spawned %d Stress Demon monster(s).", spawned))
		stressMessage(player, "Let them hit a GM/test character and watch console, Valgrind, or sanitizer output.")
	end
	return false
end

spawnStressDemon:separator(" ")
spawnStressDemon:register()
