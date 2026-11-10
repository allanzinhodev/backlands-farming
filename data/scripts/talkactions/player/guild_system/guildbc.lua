local guildbc = TalkAction("/guildbc")

function guildbc.onSay(player, words, param)
	local guild = player:getGuild()
	if not guild then
		player:sendCancelMessage("You are not in a guild.")
		return false
	end

	if player:getGuildLevel() < 3 then
		player:sendCancelMessage("Only guild leaders can use this command.")
		return false
	end

	if player:getLevel() < 300 then
		player:sendCancelMessage("You need to be at least level 300 to use this command.")
		return false
	end

	if guild:getMemberCount() < 20 then
		player:sendCancelMessage("Your guild needs at least 20 members to use this command.")
		return false
	end

	local lastUse = player:getStorageValue(PlayerStorageKeys.guildBroadcastCooldown)
	local currentTime = os.time()
	
	if lastUse > 0 and (currentTime - lastUse) < 600 then
		local remaining = 600 - (currentTime - lastUse)
		player:sendCancelMessage(string.format("You can use this command again in %d seconds.", remaining))
		return false
	end

	if not param or param == "" then
		player:sendCancelMessage("Usage: /guildbc <message>")
		return false
	end

	local message = string.format("[Guild Broadcast] %s: %s", guild:getName(), param)
	
	for _, targetPlayer in ipairs(Game.getPlayers()) do
		if targetPlayer:getGuild() then
			targetPlayer:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
		end
	end

	player:setStorageValue(PlayerStorageKeys.guildBroadcastCooldown, currentTime)
	
	return false
end

guildbc:separator(" ")
guildbc:register()
