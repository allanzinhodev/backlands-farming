-- CrystalServer compatibility patch for StdModule
-- Keeps the legacy API but routes all behavior through the real NpcSystem.

CrystalStdModule = CrystalStdModule or {}

local function crystalParseText(npcHandler, text, parseInfo)
	if type(text) == "table" then
		local parsed = {}
		for i = 1, #text do
			parsed[i] = npcHandler:parseMessage(text[i], parseInfo)
		end
		return parsed
	end

	return npcHandler:parseMessage(text, parseInfo)
end

function CrystalStdModule.getTravelCost(player, baseCost, discount)
	local cost = baseCost or 0
	if not discount then
		return cost
	end

	local discounts = {}
	if type(discount) == "table" then
		discounts = discount
	elseif type(discount) == "string" then
		discounts = { discount }
	end

	for _, d in ipairs(discounts) do
		if d == "postman" then
			if player:getStorageValue(Storage.Quest.U7_24.ThePostmanMissions.Rank) == 5 then
				cost = cost - 10
			end
		elseif d == "new frontier" then
			if player:getStorageValue(Storage.Quest.U8_54.TheNewFrontier.Mission10[1]) == 2 then
				cost = 0
			end
		end
	end

	return math.max(0, cost)
end

function CrystalStdModule.say(...)
	if _G.CrystalCompatDebug then
		_G.CrystalCompatDebug("StdModule.say called")
	end
	local argc = select("#", ...)
	local cid, message, keywords, parameters, node

	-- Supports both old-style callback shape and the native NpcSystem shape.
	if argc >= 6 then
		local npc, creature, msgType, msg, keys, params = ...
		cid = type(creature) == "number" and creature or (Player(creature) and Player(creature):getId() or 0)
		message = msg
		keywords = keys
		parameters = params
		node = select(7, ...)
	else
		cid, message, keywords, parameters, node = ...
	end

	local npcHandler = parameters and parameters.npcHandler or nil
	if npcHandler == nil then
		error("StdModule.say called without any npcHandler instance.")
	end

	local onlyFocus = (parameters.onlyFocus == nil or parameters.onlyFocus == true)
	if onlyFocus and not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	if not player then
		return false
	end

	local parseInfo = {
		[TAG_PLAYERNAME] = player:getName(),
		["|TIME|"] = Game.getFormattedWorldTime(),
	}

	if parameters.cost then
		local cost = type(parameters.cost) == "function" and parameters.cost(player) or parameters.cost
		cost = CrystalStdModule.getTravelCost(player, cost, parameters.discount)
		parseInfo["|TRAVELCOST|"] = cost
	end

	local text = parameters.text or parameters.message
	local parsedText = crystalParseText(npcHandler, text, parseInfo)
	local delay = parameters.delay or parameters.interval or 4000
	if _G.CrystalCompatDebug then
		_G.CrystalCompatDebug("StdModule.say text type = " .. type(text) .. ", cid = " .. tostring(cid))
	end
	npcHandler:say(parsedText, cid, parameters.publicize and true or false, nil, delay)

	if parameters.reset then
		npcHandler:resetNpc(cid)
	elseif parameters.moveup then
		npcHandler.keywordHandler:moveUp(cid, parameters.moveup)
	end

	return true
end

function CrystalStdModule.travel(...)
	local argc = select("#", ...)
	local cid, message, keywords, parameters, node

	-- Supports both old-style callback shape and the native NpcSystem shape.
	if argc >= 6 then
		local npc, creature, msgType, msg, keys, params = ...
		cid = type(creature) == "number" and creature or (Player(creature) and Player(creature):getId() or 0)
		message = msg
		keywords = keys
		parameters = params
		node = select(7, ...)
	else
		cid, message, keywords, parameters, node = ...
	end

	local npcHandler = parameters and parameters.npcHandler or nil
	if npcHandler == nil then
		error("StdModule.travel called without any npcHandler instance.")
	end

	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	if not player then
		return false
	end

	if player:isPremium() or not parameters.premium then
		if player:isPzLocked() then
			npcHandler:say("First get rid of those blood stains! You are not going to ruin my vehicle!", cid)
		elseif parameters.level and player:getLevel() < parameters.level then
			npcHandler:say("You must reach level " .. parameters.level .. " before I can let you go there.", cid)
		else
			local cost = parameters.cost or 0
			if type(cost) == "function" then
				cost = cost(player)
			end
			cost = CrystalStdModule.getTravelCost(player, cost, parameters.discount)

			if not player:removeTotalMoney(cost) then
				npcHandler:say("You don't have enough money.", cid)
			else
				npcHandler:say(parameters.msg or "Set the sails!", cid)
				npcHandler:releaseFocus(cid)

				local destination = parameters.destination
				if type(destination) == "function" then
					destination = destination(player)
				end
				local destinationPos = Position(destination)
				local position = player:getPosition()
				player:teleportTo(destinationPos)

				position:sendMagicEffect(CONST_ME_TELEPORT)
				destinationPos:sendMagicEffect(CONST_ME_TELEPORT)
			end
		end
	else
		npcHandler:say("I'm sorry, but you need a premium account in order to travel onboard our ships.", cid)
	end
	npcHandler:resetNpc(cid)
	return true
end

if StdModule then
	StdModule.say = CrystalStdModule.say
	StdModule.travel = CrystalStdModule.travel
end
