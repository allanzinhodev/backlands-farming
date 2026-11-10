local talk = TalkAction("/stress_reactor")

function talk.onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return false
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Running reactor stress tests... Check console for results.")
	stressReactor()
	return false
end

talk:separator(" ")
talk:accountType(6)
talk:register()
