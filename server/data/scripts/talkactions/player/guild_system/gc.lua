local gc = TalkAction("/gc")

function gc.onSay(player, words, param)
	local guild = player:getGuild()
	if not guild then
		player:sendCancelMessage("You are not in a guild.")
		return false
	end

	if player:getGuildLevel() < 3 then
		player:sendCancelMessage("Only guild leaders can use this command.")
		return false
	end

	if guild:getMemberCount() < 10 then
		player:sendCancelMessage("Your guild needs at least 10 members to use this command.")
		return false
	end

	local lastUse = player:getStorageValue(PlayerStorageKeys.guildLeaderChatCooldown)
	local currentTime = os.time()
	
	if lastUse > 0 and (currentTime - lastUse) < 10 then
		local remaining = 10 - (currentTime - lastUse)
		player:sendCancelMessage(string.format("You can use this command again in %d seconds.", remaining))
		return false
	end

	if not param or param == "" then
		player:sendCancelMessage("Usage: /gc <message>")
		return false
	end

	local message = string.format("[Guild Leader] %s: %s", player:getName(), param)
	
	for _, member in ipairs(guild:getMembersOnline()) do
		member:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
	end

	player:setStorageValue(PlayerStorageKeys.guildLeaderChatCooldown, currentTime)
	
	return false
end

gc:separator(" ")
gc:register()
