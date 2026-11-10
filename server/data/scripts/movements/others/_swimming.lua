local condition = Condition(CONDITION_OUTFIT)
condition:setOutfit({lookType = 267})
condition:setTicks(-1)

local conditions = {
    CONDITION_POISON, CONDITION_FIRE, CONDITION_ENERGY, CONDITION_PARALYZE,
    CONDITION_DRUNK, CONDITION_DROWN, CONDITION_FREEZING, CONDITION_DAZZLED,
    CONDITION_CURSED, CONDITION_BLEEDING
}

local stepIn = MoveEvent()
function stepIn.onStepIn(creature, item, position, fromPosition)
    if not creature:isPlayer() then return false end
    for i = 1, #conditions do creature:removeCondition(conditions[i]) end
    creature:addAchievementProgress("Waverider", 100000)
    creature:addCondition(condition)
    return true
end
stepIn:type("stepin")
stepIn:id(629, 630, 631, 632, 633, 634)
stepIn:register()

local stepOut = MoveEvent()
function stepOut.onStepOut(creature, item, position, fromPosition)
    if not creature:isPlayer() then return false end
    creature:removeCondition(CONDITION_OUTFIT)
    return true
end
stepOut:type("stepout")
stepOut:id(629, 630, 631, 632, 633, 634)
stepOut:register()
