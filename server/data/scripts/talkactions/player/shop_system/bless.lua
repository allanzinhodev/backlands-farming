local BLESS_PRICE = 100000
local BLESSINGS = {
    {id = 1, name = "Twist of Fate"},
    {id = 2, name = "The Spiritual Shielding"},
    {id = 3, name = "The Embrace of Tibia"},
    {id = 4, name = "The Fire of the Suns"},
    {id = 5, name = "The Spark of the Phoenix"}
}

local talkaction = TalkAction("!bless", "/bless")
function talkaction.onSay(player, words, param)
    if not player then
        return false
    end

    local missingBlessings = 0
    local missingNames = {}

    for _, bless in ipairs(BLESSINGS) do
        if not player:hasBlessing(bless.id) then
            missingBlessings = missingBlessings + 1
            table.insert(missingNames, bless.name)
        end
    end

    if missingBlessings == 0 then
        player:sendCancelMessage("You already have all 5 blessings!")
        return false
    end

    if player:getMoney() < BLESS_PRICE then
        player:sendCancelMessage("You need " .. BLESS_PRICE .. " gold coins to buy all 5 blessings. (You're missing " .. missingBlessings .. " blessings)")
        return false
    end

    if player:removeMoney(BLESS_PRICE) then
        for _, bless in ipairs(BLESSINGS) do
            player:addBlessing(bless.id)
        end
        player:sendTextMessage(MESSAGE_INFO_DESCR, "You received all 5 blessings for " .. BLESS_PRICE .. " gold coins.")
        player:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
    else
        player:sendCancelMessage("Error processing your purchase.")
    end

    return false
end

talkaction:register()