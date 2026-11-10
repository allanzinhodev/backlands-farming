local vocation = {1, 2, 3, 4}

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
    local min, max = 30000, 30000

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
                    doTargetCombatHealth(creature:getId(), target:getId(), COMBAT_ENERGYDAMAGE, -min, -max, CONST_ME_NONE)
                end
            end
        end
    end

    pos:sendMagicEffect(CONST_ME_PURPLEENERGY)
    return true
end

combat:setCallback(CALLBACK_PARAM_TARGETTILE, "onTargetTile")

local function delayedCastSpell(cid)
    local creature = Creature(cid)
    if not creature then return end

    creature:say("Gaz'haragoth calls down: DEATH AND DOOM!", TALKTYPE_MONSTER_YELL)
    combat:execute(creature, Variant(creature:getPosition()))
end

local spell = Spell("instant")

function spell.onCastSpell(creature, var)
    creature:say("Gaz'haragoth begins to channel DEATH AND DOOM into the area! RUN!", TALKTYPE_MONSTER_YELL)
    addEvent(delayedCastSpell, 5000, creature:getId())
    return true
end

spell:name("gaz'haragoth death")
spell:words("###325")
spell:isAggressive(true)
spell:blockWalls(true)
spell:needLearn(true)
spell:register()