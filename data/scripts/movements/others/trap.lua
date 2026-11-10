local traps = {
    [2145] = {transformTo = 2146, damage = {-50, -100}},
    [2148] = {damage = {-50, -100}},
    [3482] = {transformTo = 3481, damage = {-15, -30}, ignorePlayer = (Game.getWorldType() == WORLD_TYPE_NO_PVP) },
    [3944] = {transformTo = 3945, damage = {-15, -30}, type = COMBAT_EARTHDAMAGE}
}

local stepIn = MoveEvent()
function stepIn.onStepIn(creature, item, position, fromPosition)
    local trap = traps[item.itemid]
    if not trap then return true end

    if creature:isMonster() or creature:isPlayer() then
        doTargetCombat(0, creature, trap.type or COMBAT_PHYSICALDAMAGE,
                       trap.damage[1], trap.damage[2], CONST_ME_NONE, true, false,
                       false)
    end

    if trap.transformTo then item:transform(trap.transformTo) end
    return true
end
stepIn:type("stepin")
for itemId, info in pairs(traps) do
    stepIn:id(itemId)
end
stepIn:register()

local stepOut = MoveEvent()
function stepOut.onStepOut(creature, item, position, fromPosition)
    item:transform(item.itemid - 1)
    return true
end
stepOut:type("stepout")
stepOut:id(2146, 3945)
stepOut:register()

local removeItem = MoveEvent()
function removeItem.onRemoveItem(item, tile, position)
    local itemPosition = item:getPosition()
    if itemPosition:getDistance(position) > 0 then
        item:transform(item.itemid - 1)
        itemPosition:sendMagicEffect(CONST_ME_POFF)
    end
    return true
end
removeItem:type("removeitem")
removeItem:id(3482)
removeItem:register()
