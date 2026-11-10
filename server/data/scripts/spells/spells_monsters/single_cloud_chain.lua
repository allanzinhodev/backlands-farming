local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ENERGYDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_STORM)

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
			creaturePos:sendMagicEffect(CONST_ME_STORM)
		end
	end

	return combat:execute(creature, var)
end

spell:name("singlecloudchain")
spell:words("###487")
spell:isAggressive(true)
spell:needTarget(true)
spell:needLearn(true)
spell:register()
