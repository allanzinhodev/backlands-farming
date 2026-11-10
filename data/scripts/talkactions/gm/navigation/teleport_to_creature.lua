local talkaction = TalkAction("/goto")

function talkaction.onSay(player, words, param)
	local target = Creature(param)
	if not target then
		player:sendCancelMessage("Creature not found.")
		return false
	end

	local targetInstanceId = target:getInstanceId()
	if player:getInstanceId() ~= targetInstanceId then
		player:setInstanceIdRaw(targetInstanceId)
	end
	player:teleportTo(target:getPosition())
	return false
end

talkaction:separator(" ")
talkaction:access(true)
talkaction:register()

