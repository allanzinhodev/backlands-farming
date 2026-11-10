local moveevent = MoveEvent()
function moveevent.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local boosted = Game.getBoostedCreature()
	if boosted == "" then
		player:popupFYI("No boosted creature today.")
		return true
	end

	local expMult = configManager.getFloat(configKeys.BOOSTED_EXP_MULTIPLIER)
	local lootMult = configManager.getFloat(configKeys.BOOSTED_LOOT_MULTIPLIER)
	local spawnMult = configManager.getFloat(configKeys.BOOSTED_SPAWN_MULTIPLIER)

	local spawnText = string.format("%.0f%%", (1 / spawnMult) * 100)

	local msg = string.format(
		"========== BOOSTED CREATURE ==========\n\n" ..
		"  Creature: %s\n\n" ..
		"  Experience: %.1fx\n" ..
		"  Loot: %.1fx\n" ..
		"  Spawn Speed: %s faster\n\n" ..
		"The boosted creature changes every day\n" ..
		"at midnight (server time).\n\n" ..
		"=======================================",
		boosted, expMult, lootMult, spawnText
	)

	player:popupFYI(msg)
	return true
end
moveevent:type("stepin")
moveevent:uid(5000)
moveevent:register()
