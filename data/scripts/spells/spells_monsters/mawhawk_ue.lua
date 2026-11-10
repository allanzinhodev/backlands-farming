local vocation = {1, 2, 3, 4}

local condition = Condition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
condition:setParameter(CONDITION_PARAM_SUBID, 88888)
condition:setParameter(CONDITION_PARAM_TICKS, 10 * 60 * 1000)
condition:setParameter(CONDITION_PARAM_HEALTHGAIN, 0.01)
condition:setParameter(CONDITION_PARAM_HEALTHTICKS, 10 * 60 * 1000)

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
    local min, max = 1500, 1700

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
    combat:execute(creature, Variant(creature:getPosition()))
end

local spell = Spell("instant")

function spell.onCastSpell(creature, var)
    if creature:getHealth() < creature:getMaxHealth() * 0.1 and not creature:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT, 88888) then
        creature:addCondition(condition)
        addEvent(delayedCastSpell, 5000, creature:getId())
        creature:say("Better flee now.", TALKTYPE_MONSTER_SAY)
        return true
    end
    return false
end

spell:name("mawhawk ue")
spell:words("###361")
spell:isAggressive(true)
spell:blockWalls(true)
spell:needLearn(true)
spell:register()