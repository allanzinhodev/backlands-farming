local vocation = {1, 2, 3, 4} -- IDs: Sorcerer, Druid, Paladin, Knight

local area = {
    { 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
    { 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
    { 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
    { 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
    { 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
    { 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1 },
    { 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
    { 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
    { 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
    { 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
    { 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0 },
}

local createArea = createCombatArea(area)
local combat = Combat()
combat:setArea(createArea)

function onTargetTile(creature, pos)
    local tile = Tile(pos)
    if not tile then return true end

    local creatures = tile:getCreatures()
    local min, max = 4000, 6000

    if creatures and #creatures > 0 then
        for _, item in ipairs(creatures) do
            local target = Creature(item)
            if target and target:getId() ~= creature:getId() then
                local shouldDamage = false
                
                if target:isPlayer() then
                    local targetVoc = target:getVocation()
                    if targetVoc and table.contains(vocation, targetVoc:getBase():getId()) then
                        shouldDamage = true
                    end
                elseif target:isMonster() then
                    shouldDamage = true
                end

                if shouldDamage then
                    doTargetCombatHealth(creature:getId(), target:getId(), COMBAT_FIREDAMAGE, -min, -max, CONST_ME_NONE)
                end
            end
        end
    end

    pos:sendMagicEffect(CONST_ME_FIREAREA)
    return true
end

combat:setCallback(CALLBACK_PARAM_TARGETTILE, "onTargetTile")

local function delayedCastSpell(cid)
    local creature = Creature(cid)
    if not creature then return end

    local master = creature:getMaster()
    if master then
        master:addHealth(math.random(20000, 30000))
    end

    Game.createMonster("demon", creature:getPosition(), true, true)
    combat:execute(creature, Variant(creature:getPosition()))
    creature:remove()
end

local spell = Spell("instant")

function spell.onCastSpell(creature, var)
    addEvent(delayedCastSpell, 7000, creature:getId())
    return true
end

spell:name("eruption of destruction explosion")
spell:words("###413")
spell:isAggressive(true)
spell:blockWalls(true)
spell:needLearn(true)
spell:register()