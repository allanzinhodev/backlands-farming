local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_DEATHDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_WHITE_ENERGY_SPARK)

local spell = Spell("instant")

function spell.onCastSpell(creature, var)
	local target = Creature(var.number)
	if not target then
		return false
	end
	local targetPos = target:getPosition()
	local creaturePos = creature:getPosition()

	local path = creature:getPathTo(targetPos, 0, 1, true, true, 8)
	if path then
		for i = 1, #path do
			creaturePos:getNextPosition(path[i], 1)
			creaturePos:sendMagicEffect(CONST_ME_WHITE_ENERGY_SPARK)
		end
	end

	return combat:execute(creature, var)
end

spell:name("singledeathchain")
spell:words("###485")
spell:isAggressive(true)
spell:needTarget(true)
spell:needLearn(true)
spell:register()
