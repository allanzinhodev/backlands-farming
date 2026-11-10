local talkaction = TalkAction("/town")

function talkaction.onSay(player, words, param)
	local town = Town(param) or Town(tonumber(param))
	if not town then
		player:sendCancelMessage("Town not found.")
		return false
	end

	-- Reset instance BEFORE teleporting so the move packet
	-- is built in world context (single refresh, no stale creatures).
	if player:getInstanceId() ~= 0 then
		player:setInstanceIdRaw(0)
	end
	player:teleportTo(town:getTemplePosition())
	return false
end

talkaction:separator(" ")
talkaction:access(true)
talkaction:register()

