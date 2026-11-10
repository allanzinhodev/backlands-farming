local function setDisplay(player, mode)
	if mode == 1 then
		player:setStorageValue(STORAGE_HEALTH_DISPLAY, 1)
		player:sendStats()
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Health display set to: PERCENT (e.g. 100%)")
	else
		player:setStorageValue(STORAGE_HEALTH_DISPLAY, 0)
		player:sendStats()
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Health display set to: REAL (e.g. 5000/5000)")
	end
end

local healthDisplay = TalkAction("/healthdisplay", "/healthreal", "/healthpercent")
function healthDisplay.onSay(player, words, param)
	local command = words:lower()
	if command == "/healthreal" then
		setDisplay(player, 0)
		return false
	end

	if command == "/healthpercent" then
		setDisplay(player, 1)
		return false
	end

	local mode = param:lower():gsub("^%s*(.-)%s*$", "%1")
	if mode == "real" then
		setDisplay(player, 0)
	elseif mode == "percent" then
		setDisplay(player, 1)
	else
		local current = player:getStorageValue(STORAGE_HEALTH_DISPLAY)
		setDisplay(player, current == 1 and 0 or 1)
	end
	return false
end
healthDisplay:separator(" ")
healthDisplay:register()
