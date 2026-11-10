local playerBathTub = 26087

local bathtubEnter = MoveEvent()

function bathtubEnter.onStepIn(creature, item, position, fromPosition)
	if not creature:isPlayer() then
		return false
	end

	local condition = Condition(CONDITION_OUTFIT)
	condition:setOutfit({lookTypeEx = playerBathTub})
	condition:setTicks(-1)

	position:sendMagicEffect(CONST_ME_WATERSPLASH)
	item:transform(26100)
	creature:addCondition(condition)
	return true
end

bathtubEnter:id(26077)
bathtubEnter:register()

local bathtubExit = MoveEvent()
function bathtubExit.onStepOut(creature, item, position, fromPosition)
	if not creature:isPlayer() then
		return false
	end

	item:transform(26077)
	creature:removeCondition(CONDITION_OUTFIT)
	return true
end

bathtubExit:id(26100)
bathtubExit:register()