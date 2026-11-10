local talkaction = TalkAction("/unspy")

function talkaction.onSay(player, words, param)
	local stoppedSpy = Game.stopSpy(player:getId())
	local stoppedInventory = false
	if not stoppedSpy then
		stoppedInventory = Game.stopSpyInventory(player:getId())
	end

	if not stoppedSpy and not stoppedInventory then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "You are not spying anyone.")
	end
	return false
end

talkaction:accountType(ACCOUNT_TYPE_GOD)
talkaction:access(true)
talkaction:register()
