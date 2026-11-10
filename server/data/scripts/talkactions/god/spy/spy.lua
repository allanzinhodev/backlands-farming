local talkaction = TalkAction("/spy")

function talkaction.onSay(player, words, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /spy <player name>")
		return false
	end

	if not Game.startSpy(player:getId(), param) then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "Player not found or already offline.")
	end
	return false
end

talkaction:separator(" ")
talkaction:accountType(ACCOUNT_TYPE_GOD)
talkaction:access(true)
talkaction:register()
