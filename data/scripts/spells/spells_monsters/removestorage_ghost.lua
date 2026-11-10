local vocation = {1, 2, 3, 4}

local area = {
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0 },
    { 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0 },
    { 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
    { 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
    { 0, 1, 1, 1, 1, 3, 1, 1, 1, 1, 0 },
    { 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
    { 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
    { 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0 },
    { 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
}

local createArea = createCombatArea(area)
local combat = Combat()
combat:setArea(createArea)

function onTargetTile(creature, pos)
    local tile = Tile(pos)
    if not tile then return true end

    local creatures = tile:getCreatures()
    if creatures and #creatures > 0 then
        for _, item in ipairs(creatures) do
            local target = Creature(item)
            if target and target:getId() ~= creature:getId() then
                local isProperVocation = false
                if target:isPlayer() then
                    local targetVoc = target:getVocation()
                    if targetVoc and table.contains(vocation, targetVoc:getBase():getId()) then
                        isProperVocation = true
                    end
                end

                if isProperVocation or target:isMonster() then
                    doTargetCombatHealth(creature:getId(), target:getId(), COMBAT_ENERGYDAMAGE, -1, -1, CONST_ME_NONE)
                    
                    if target:isPlayer() then
                        local currentStorage = target:getStorageValue(65121)
                        if currentStorage > 0 and math.random(1, 100) <= 30 then
                            target:setStorageValue(65121, 0)
                        end
                    end
                end
            end
        end
    end
    pos:sendMagicEffect(6)
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
    addEvent(delayedCastSpell, 1000, creature:getId())
    return true
end

spell:name("removepontos")
spell:words("###921")
spell:isAggressive(true)
spell:blockWalls(true)
spell:needLearn(true)
spell:register()