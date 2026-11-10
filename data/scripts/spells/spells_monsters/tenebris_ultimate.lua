local vocation = {1, 2, 3, 4} -- IDs: Sorcerer, Druid, Paladin, Knight

local area = {
	{ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
	{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
	{ 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
	{ 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
	{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
	{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
	{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
	{ 1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1 },
	{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
	{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
	{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
	{ 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
	{ 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
	{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
	{ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
}

local createArea = createCombatArea(area)
local combat = Combat()
combat:setArea(createArea)

function onTargetTile(creature, pos)
	local tile = Tile(pos)
	if not tile then return true end

	local creatures = tile:getSpectators() -- getSpectators em área 1x1 é mais estável
	local min, max = 2200, 2500

	for _, item in ipairs(tile:getCreatures() or {}) do
		local target = Creature(item)
		if target and target:getId() ~= creature:getId() then
			local shouldDamage = false
			if target:isPlayer() then
				local voc = target:getVocation()
				if voc and table.contains(vocation, voc:getBase():getId()) then
					shouldDamage = true
				end
			elseif target:isMonster() then
				shouldDamage = true
			end

			if shouldDamage then
				doTargetCombatHealth(creature:getId(), target:getId(), COMBAT_DEATHDAMAGE, -min, -max, CONST_ME_NONE)
			end
		end
	end

	pos:sendMagicEffect(CONST_ME_MORTAREA)
	return true
end

combat:setCallback(CALLBACK_PARAM_TARGETTILE, "onTargetTile")

local function delayedCastSpell(cid)
	local creature = Creature(cid)
	if not creature then return end
	
	creature:setMoveLocked(false)
	combat:execute(creature, Variant(creature:getPosition()))
end

local spell = Spell("instant")

function spell.onCastSpell(creature, var)
	local roomCenterPosition = Position(32912, 31599, 14)
	local spectators = Game.getSpectators(roomCenterPosition, false, false, 12, 12, 12, 12)
	
	for _, spec in ipairs(spectators) do
		if spec:isPlayer() or spec:getName():lower() == "lady tenebris" then
			if not spec:getPosition():compare(roomCenterPosition) then
				spec:teleportTo(roomCenterPosition)
			end
			if spec:getName():lower() == "lady tenebris" then
				spec:setMoveLocked(true)
			end
		end
	end

	creature:say("LADY TENEBRIS BEGINS TO CHANNEL A POWERFULL SPELL! TAKE COVER!", TALKTYPE_MONSTER_YELL)
	addEvent(delayedCastSpell, 4000, creature:getId())
	return true
end

spell:name("tenebris ultimate")
spell:words("###430")
spell:isAggressive(true)
spell:blockWalls(true)
spell:needLearn(true)
spell:register()