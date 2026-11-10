--[[
    Revisioned NPC System:
        - Version: 1.0

    Credits:
        - Evil Hero (https://otland.net/members/evil-hero.4280/)
        - EvilHero90 (https://github.com/EvilHero90)
        - evilhero90 discord

    Description:
        - This system is designed to make it easier to create NPCs with complex interactions with players.
        - It includes a handler for the NPCs, a focus system, a talk queue, and a shop system.
        - The system is modular and can be expanded with additional features as needed.

    Features:
        - NpcsHandler: Handles the keywords, responses, and shops for the NPCs.
        - NpcFocus: Manages the focus of NPCs on players.
        - NpcTalkQueue: Manages a queue of messages for NPCs to say to players.
        - NpcShop: Handles the items available in the shops for the NPCs.
        - NpcEvents: Handles the appearance, disappearance, thinking, and interaction with players for the NPCs.
        - NpcRequirements: Stores the requirements for an NPC interaction.
        - Constants: Contains the constants used by the system.

    Functions:
        - string:replaceTags(playerName: string, amount: string, total: string, itemName: string)
        - checkStorageValueWithOperator(player: Player, storage: table<string, string>)
        - checkLevelWithOperator(player: Player, level: number, operator: string)
        - NpcType:defaultBehavior()
        - NpcType.onAppearCallback(creature)
        - NpcType.onMoveCallback(creature, oldPos, newPos)
        - NpcType.onPlayerCloseChannelCallback(creature)
        - NpcType.onPlayerEndTradeCallback(creature)
        - NpcType.onDisappearCallback(creature)
        - NpcType.onThinkCallback()
        - NpcType.onSayCallback(creature, messageType, message)

    Example:
        - An example of how to use the system is provided in the data/npc/lua/#test.lua file.
]]

---@alias NpcType.onAppearCallback fun(creature: Creature)
---@alias NpcType.onMoveCallback fun(creature: Creature, oldPos: Position, newPos: Position)
---@alias NpcType.onPlayerCloseChannelCallback fun(creature: Creature)
---@alias NpcType.onPlayerEndTradeCallback fun(creature: Creature)
---@alias NpcType.onDisappearCallback fun(creature: Creature)
---@alias NpcType.onThinkCallback fun()
---@alias NpcType.onSayCallback fun(creature: Creature, messageType: number, message: string)

if not RevNpcSysResolveNpcName then
    function RevNpcSysResolveNpcName(npc)
        if type(npc) == "string" then
            return npc
        end

        if not npc then
            return nil
        end

        local accessors = {
            function(value) return value:name() end,
            function(value) return value:getName() end,
            function(value)
                local name = value.name
                if type(name) == "function" then
                    return name(value)
                end
                return name
            end,
            function(value)
                local getName = value.getName
                if type(getName) == "function" then
                    return getName(value)
                end
                return getName
            end,
        }

        for _, getter in ipairs(accessors) do
            local ok, ret = pcall(getter, npc)
            if ok and type(ret) == "string" and ret ~= "" then
                return ret
            end
        end

        return nil
    end
end

if not RevNpcSysGetStorageValue then
    function RevNpcSysGetStorageValue(creature, key, defaultValue)
        local fallback = defaultValue
        if fallback == nil then
            fallback = -1
        end

        local value = creature:getStorageValue(key, fallback)
        if value == nil then
            return fallback
        end
        return value
    end
end

-- Load all the necessary files to create the NPC system
dofile('data/npc/lib/revnpcsys/constants.lua')
dofile('data/npc/lib/revnpcsys/handler.lua')
dofile('data/npc/lib/revnpcsys/events.lua')
dofile('data/npc/lib/revnpcsys/focus.lua')
dofile('data/npc/lib/revnpcsys/shop.lua')
dofile('data/npc/lib/revnpcsys/talkqueue.lua')
dofile('data/npc/lib/revnpcsys/requirements.lua')
dofile('data/npc/lib/revnpcsys/modules.lua')
dofile('data/npc/lib/revnpcsys/voices.lua')

-- Compatibility: protocol 8.60 has no bank system, so getTotalMoney/removeTotalMoney
-- are aliases for getMoney/removeMoney.
if not Player.getTotalMoney then
    function Player:getTotalMoney() return self:getMoney() end
end
if not Player.removeTotalMoney then
    function Player:removeTotalMoney(amount) return self:removeMoney(amount) end
end
if not Player.sendInboxItems then
    function Player:sendInboxItems(items, containerId)
        -- Fallback: add items directly to player since inbox does not exist in 8.60
        for _, item in pairs(items) do
            self:addItem(item.item, item.count)
        end
    end
end

-- Replaces tags in a string with corresponding values.
---@param params table<string, number|string|table<string|number, string|number>> The parameters to replace the tags with.
---@return string stringLib The string with the tags replaced.
function string.replaceTags(string, params)
    local ret = string
    for _, handler in pairs(MESSAGE_TAGS) do
        ret = ret:gsub(handler.tag, handler.func(params))
    end
    return ret
end

-- Uses the correct operator on storage values, depending on string.
---@param player Player The player to check the storage value for.
---@param storage table<string, string> The storage value to check.
---@return boolean The result of the storage value check.
function checkStorageValueWithOperator(player, storage)
    local storageValue = RevNpcSysGetStorageValue(player, storage.key, -1)

    if storage.operator == "==" then
        return storageValue == storage.value
    elseif storage.operator == "~=" then
        return storageValue ~= storage.value
    elseif storage.operator == "<" then
        if storage.value2 and storage.operator2 == ">" then
            return storageValue < storage.value and storageValue > storage.value2
        elseif storage.value2 and storage.operator2 == ">=" then
            return storageValue < storage.value and storageValue >= storage.value2
        end
        return storageValue < storage.value
    elseif storage.operator == ">" then
        if storage.value2 and storage.operator2 == "<" then
            return storageValue > storage.value and storageValue < storage.value2
        elseif storage.value2 and storage.operator2 == "<=" then
            return storageValue > storage.value and storageValue <= storage.value2
        end
        return storageValue > storage.value
    elseif storage.operator == "<=" then
        if storage.value2 and storage.operator2 == ">" then
            return storageValue <= storage.value and storageValue > storage.value2
        elseif storage.value2 and storage.operator2 == ">=" then
            return storageValue <= storage.value and storageValue >= storage.value2
        end
        return storageValue <= storage.value
    elseif storage.operator == ">=" then
        if storage.value2 and storage.operator2 == "<" then
            return storageValue >= storage.value and storageValue < storage.value2
        elseif storage.value2 and storage.operator2 == "<=" then
            return storageValue >= storage.value and storageValue <= storage.value2
        end
        return storageValue >= storage.value
    end
    print("[Warning - checkStorageValueWithOperator] operator: ".. storage.operator .." does not exist.\n".. debug.getinfo(2).source:match("@?(.*)"))
    return false
end

-- Uses the correct operator on level, depending on string.
---@param player Player The player to check the storage value for.
---@param level number The level to check.
---@param operator string The operator to use for the check.
---@return boolean The result of the storage value check.
function checkLevelWithOperator(player, level, operator)
    if operator == "==" then
        return player:getLevel() == level
    elseif operator == "~=" then
        return player:getLevel() ~= level
    elseif operator == "<" then
        return player:getLevel() < level
    elseif operator == ">" then
        return player:getLevel() > level
    elseif operator == "<=" then
        return player:getLevel() <= level
    elseif operator == ">=" then
        return player:getLevel() >= level
    end
    print("[Warning - checkLevelWithOperator] operator: ".. operator .." does not exist.\n".. debug.getinfo(2).source:match("@?(.*)"))
    return false
end

-- This function assigns event handlers for the NPC's appearance, disappearance, thinking, and interaction with players.
function NpcType:defaultBehavior()
    local function resolveNpcContext(a, b)
        if b ~= nil then
            return a, b
        end
        return Npc(getNpcCid()), a
    end

    -- The onAppear function is called when the NPC/Creature appears.
    self.onAppear = function(a, b)
        local npc, creature = resolveNpcContext(a, b)
        NpcEvents.onAppear(npc, creature)
        if self.onAppearCallback then
            self.onAppearCallback(npc, creature)
        end
    end
    -- The onDisappear function is called when the NPC/Creature disappears.
    self.onDisappear = function(a, b)
        local npc, creature = resolveNpcContext(a, b)
        NpcEvents.onDisappear(npc, creature)
        if self.onDisappearCallback then
            self.onDisappearCallback(npc, creature)
        end
    end
    -- The onThink function is called when the NPC thinks.
    self.onThink = function(a, b)
        local npc = Npc(getNpcCid())
        local interval = nil
        if b ~= nil then
            npc = a
            interval = b
        elseif a ~= nil then
            interval = a
        end

        NpcEvents.onThink(npc)
        if self.onThinkCallback then
            self.onThinkCallback(npc, interval)
        end
        return true
    end
    -- The onSay function is called when a player says something to the NPC.
    self.onSay = function(a, b, c, d)
        local npc = Npc(getNpcCid())
        local creature, messageType, message = a, b, c
        if d ~= nil then
            npc = a
            creature = b
            messageType = c
            message = d
        end

        NpcEvents.onSay(npc, creature, messageType, message)
        if self.onSayCallback then
            self.onSayCallback(npc, creature, messageType, message)
        end
    end
    -- The onMove function is called when the NPC moves.
    self.onMove = function(a, b, c, d)
        local npc = Npc(getNpcCid())
        local oldPos, newPos = b, c
        if d ~= nil then
            npc = a
            oldPos = c
            newPos = d
        end

        NpcEvents.onMove(npc, oldPos, newPos)
        if self.onMoveCallback then
            self.onMoveCallback(npc, oldPos, newPos)
        end
    end
    -- The onPlayerCloseChannel function is called when a player closes the channel with the NPC.
    self.onPlayerCloseChannel = function(a, b)
        local npc, creature = resolveNpcContext(a, b)
        NpcEvents.onPlayerCloseChannel(npc, creature)
        if self.onPlayerCloseChannelCallback then
            self.onPlayerCloseChannelCallback(npc, creature)
        end
    end
    -- The onPlayerEndTrade function is called when a player ends the trade with the NPC.
    self.onPlayerEndTrade = function(a, b)
        local npc, creature = resolveNpcContext(a, b)
        NpcEvents.onPlayerEndTrade(npc, creature)
        if self.onPlayerEndTradeCallback then
            self.onPlayerEndTradeCallback(npc, creature)
        end
    end
end
