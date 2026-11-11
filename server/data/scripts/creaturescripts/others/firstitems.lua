-- Shared starter kit for Backlands farmers. IDs match data/items/items.xml.
local starterItems = {
    { 3003, 1 }, -- rope
    { 3457, 1 }, -- shovel
    { 3453, 1 }, -- scythe (harvest ripe wheat)
    { 3483, 1 }, -- fishing rod
    { 3492, 20 }, -- worms
    { 650, 1 }, -- watering can
    { 647, 10 }, -- seeds (drop one on an empty flower pot)
    { 306, 1 }, -- empty flower pot
    { 3600, 5 }, -- bread
    { 3031, 50 }, -- gold for supplies
}

local firstItems = CreatureEvent("FirstItems")
function firstItems.onLogin(player)
    if player:getLastLoginSaved() > 0 then
        return true
    end

    local backpack = player:addItem(2854)
    if not backpack then
        return true
    end
    for _, entry in ipairs(starterItems) do
        backpack:addItem(entry[1], entry[2])
    end
    backpack:addItem(2873, FLUID_WATER) -- bucket for bread-making
    player:sendTextMessage(MESSAGE_STATUS_DEFAULT,
        "Welcome, farmer! Use your scythe on ripe wheat and say hi, then trade to the Seed Vendor or Harvest Buyer in the village.")
    return true
end
firstItems:register()
