local talkReset = TalkAction("!reset")

function talkReset.onSay(player, words, param)
	if not player or not player:isPlayer() then
		return false
	end
	doPlayerReset(player)
	return false
end

talkReset:separator(" ")
talkReset:register()

local talkGMReset = TalkAction("/resetplayer")

function talkGMReset.onSay(player, words, param)
	if not player or not player:isPlayer() then
		return false
	end

	if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Access denied.")
		return false
	end

	if param == "" then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Usage: /resetplayer <player name>")
		return false
	end

	local target = Player(param)
	if not target then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Player '" .. param .. "' not found or offline.")
		return false
	end

	local ok = doPlayerReset(target)
	if ok then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Reset applied to " .. target:getName() .. ".")
	end
	return false
end

talkGMReset:separator(" ")
talkGMReset:accountType(ACCOUNT_TYPE_GAMEMASTER)
talkGMReset:access(true)
talkGMReset:register()
