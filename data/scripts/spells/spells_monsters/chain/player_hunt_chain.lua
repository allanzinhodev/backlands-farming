local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_HITAREA)
combat:setParameter(COMBAT_PARAM_CHAIN_EFFECT, CONST_ME_BLACK_BLOOD)

function getChainValue(creature)
	return 3, 4, true
end

combat:setCallback(CALLBACK_PARAM_CHAINVALUE, "getChainValue")

function canChainTarget(creature, target)
	if target:isPlayer() then
		local tile = target:getTile()
		if tile and tile:hasFlag(TILESTATE_PROTECTIONZONE) then
			return false
		end
		return true
	end
	return false
end

combat:setCallback(CALLBACK_PARAM_CHAINPICKER, "canChainTarget")

local spell = Spell("instant")

function spell.onCastSpell(creature, var)
	return combat:execute(creature, var)
end

spell:name("player hunt chain")
spell:words("###6059")
spell:needLearn(true)
spell:cooldown("3000")
spell:isSelfTarget(true)
spell:register()
