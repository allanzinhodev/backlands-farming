local combat = {}

local damageValue = 2.32

combat[damageValue] = Combat()
combat[damageValue]:setParameter(COMBAT_PARAM_TYPE, COMBAT_DEATHDAMAGE)
combat[damageValue]:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_SUDDENDEATH)

local condition = Condition(CONDITION_CURSED)
condition:setParameter(CONDITION_PARAM_DELAYED, 1)

local damage = damageValue
condition:addDamage(1, 4000, -damage)

for j = 1, 23 do
	damage = damage * 1.2
	condition:addDamage(1, 4000, -damage)
end

combat[damageValue]:addCondition(condition)

local spell = Spell("instant")

function spell.onCastSpell(creature, var)
	return combat[damageValue]:execute(creature, var)
end

spell:name("metal gargoyle curse")
spell:words("###370")
spell:isAggressive(true)
spell:blockWalls(true)
spell:needTarget(true)
spell:needLearn(true)
spell:register()