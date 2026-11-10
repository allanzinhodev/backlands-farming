local condition = Condition(CONDITION_DROWN)
condition:setParameter(CONDITION_PARAM_PERIODICDAMAGE, -20)
condition:setParameter(CONDITION_PARAM_TICKS, -1)
condition:setParameter(CONDITION_PARAM_TICKINTERVAL, 2000)

local stepIn = MoveEvent()
function stepIn.onStepIn(creature, item, position, fromPosition)
    if creature:isPlayer() then
        local headItem = creature:getSlotItem(CONST_SLOT_HEAD)
        if headItem and isInArray({ 5459, 10629, 465 }, headItem.itemid) then
            return true
        elseif math.random(1, 10) == 1 then
            position:sendMagicEffect(CONST_ME_BUBBLES)
        end
        creature:addCondition(condition)
        creature:addAchievementProgress("Deep Sea Diver", 1000000)
    end
    return true
end
stepIn:type("stepin")
stepIn:id(2117, 9291, 5405, 5406, 5407, 5408, 5743, 5764, 7927, 7928, 7929, 8375)
stepIn:register()

local stepOut = MoveEvent()
function stepOut.onStepOut(creature, item, position, fromPosition)
    if creature:isPlayer() then creature:removeCondition(CONDITION_DROWN) end
    return true
end
stepOut:type("stepout")
stepOut:id(2117, 9291, 5405, 5406, 5407, 5408, 5743, 5764, 7927, 7928, 7929, 8375)
stepOut:register()
