local talkaction = TalkAction("/spyinv")

function talkaction.onSay(player, words, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /spyinv <player name>")
		return false
	end

	if not Game.spyInventory(player:getId(), param) then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "Player not found or has no backpack.")
	end
	return false
end

talkaction:separator(" ")
talkaction:accountType(ACCOUNT_TYPE_GOD)
talkaction:access(true)
talkaction:register()
