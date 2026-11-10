-- Soulpit Creature Event: Boss enrage (damage reduction by HP threshold)
-- Ported from Crystal Server.

-- Guard: only register if Soulpit system is enabled
if not configManager or not configManager.getBoolean or not configManager.getBoolean(configKeys.SOULPIT_SYSTEM_ENABLED) then
	return
end

local enrage = CreatureEvent("SoulPitEnrage")

function enrage.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType)
	if not creature or not creature:isMonster() then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	-- Only applies to active soulpit bosses in the arena
	if not SoulPit or not SoulPit.encounter then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	-- Verify creature is within the soulpit arena zone
	local pos = creature:getPosition()
	if not pos or not SoulPit.zone then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	-- Only reduce damage for monsters inside the zone
	local spectators = Game.getSpectators(SoulPit.zoneArea.fromPos, SoulPit.zoneArea.toPos, false, false)
	local isInArena = false
	if spectators then
		for _, spec in ipairs(spectators) do
			if spec == creature then
				isInArena = true
				break
			end
		end
	end
	if not isInArena then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	local healthPercent = creature:getHealth() / math.max(1, creature:getMaxHealth())
	local reductionMultiplier = 1.0

	-- Damage reduction by HP threshold
	if healthPercent >= 0.6 and healthPercent < 0.8 then
		reductionMultiplier = 0.9   -- 10% reduction at 60-80% HP
	elseif healthPercent >= 0.4 and healthPercent < 0.6 then
		reductionMultiplier = 0.75  -- 25% reduction at 40-60% HP
	elseif healthPercent >= 0.2 and healthPercent < 0.4 then
		reductionMultiplier = 0.6   -- 40% reduction at 20-40% HP
	elseif healthPercent < 0.2 then
		reductionMultiplier = 0.4   -- 60% reduction below 20% HP
	end

	if reductionMultiplier < 1.0 then
		primaryDamage = math.floor(primaryDamage * reductionMultiplier)
		if secondaryDamage then
			secondaryDamage = math.floor(secondaryDamage * reductionMultiplier)
		end
	end

	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

enrage:register()
