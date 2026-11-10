local talkaction = TalkAction("/t")

function talkaction.onSay(player, words, param)
	if player:getInstanceId() ~= 0 then
		player:setInstanceIdRaw(0)
	end
	player:teleportTo(player:getTown():getTemplePosition())
	return false
end

talkaction:access(true)
talkaction:register()

