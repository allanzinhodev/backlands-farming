local checkTime = TalkAction("/time")

function checkTime.onSay(player, words, param)
	local split = param:split(" ")
	if split[1] == "set" then
		if player:getGroup():getId() < 3 then
			return true
		end

		local newTime = 0
		local target = split[2]
		if target == "sunrise" then 
			newTime = 330
		elseif target == "day" then 
			newTime = 360
		elseif target == "sunset" then 
			newTime = 1050
		elseif target == "night" then 
			newTime = 1080
		elseif tonumber(target) then 
			newTime = tonumber(target)
		else
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /time set [sunrise|day|sunset|night|minutes]")
			return true
		end

		Game.setWorldTime(newTime)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("World time set to %s (%d minutes).", target, newTime))
		return true
	end

	local lightState = Game.getLightState()
	local periodName = "Unknown"

	if lightState == LIGHT_STATE_SUNRISE then
		periodName = "Sunrise"
	elseif lightState == LIGHT_STATE_DAY then
		periodName = "Day"
	elseif lightState == LIGHT_STATE_SUNSET then
		periodName = "Sunset"
	elseif lightState == LIGHT_STATE_NIGHT then
		periodName = "Night"
	end

	local time = getWorldTime()
	local hours = math.floor(time / 60)
	local minutes = time % 60

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Current server time: %02d:%02d. Period: %s.", hours, minutes, periodName))
	return true
end

checkTime:separator(" ")
checkTime:accountType(6)
checkTime:access(true)
checkTime:register()
