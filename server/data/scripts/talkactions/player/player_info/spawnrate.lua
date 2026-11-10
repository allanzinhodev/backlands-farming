local talkaction = TalkAction("!spawnrate")
function talkaction.onSay(player, words, param)
	local rate = Game.getSpawnRate()
	local playersOnline = Game.getPlayers()
	local count = 0
	for _ in pairs(playersOnline) do count = count + 1 end

	local label
	if rate <= 1 then
		label = "Normal"
	elseif rate <= 2 then
		label = "Fast"
	elseif rate <= 3 then
		label = "Very Fast"
	else
		label = "Extreme"
	end

	local msg = string.format(
		"                  [Spawn Rate]\n" ..
		"--------------------------------\n" ..
		"The server spawn rate adjusts\n" ..
		"based on players online to keep\n" ..
		"hunting balanced.\n" ..
		"--------------------------------\n" ..
		"Players online: %d\n" ..
		"Current spawn rate: %s (x%d)",
		count, label, rate
	)

	player:popupFYI(msg)
	return false
end
talkaction:register()
