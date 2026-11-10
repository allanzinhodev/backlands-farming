local config = {
	goldPouchId = 23721,
	goldPouchPrice = 50000
}

local function normalizeParam(param)
	return param:lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function containsGoldPouch(container)
	for _, item in ipairs(container:getItems()) do
		if item:getId() == config.goldPouchId then
			return true
		end

		local child = item:getContainer()
		if child and containsGoldPouch(child) then
			return true
		end
	end
	return false
end

local function playerHasGoldPouch(player)
	if player:getItemCount(config.goldPouchId) > 0 then
		return true
	end

	local inbox = player:getStoreInbox()
	return inbox and containsGoldPouch(inbox)
end

local talkaction = TalkAction("!buy")
function talkaction.onSay(player, words, param)
	local buyParam = normalizeParam(param)
	if buyParam ~= "gold pouch" and buyParam ~= "gold puch" then
		player:sendCancelMessage("Usage: !buy gold pouch")
		return false
	end

	if playerHasGoldPouch(player) then
		player:sendCancelMessage("You already have a Gold Pouch.")
		return false
	end

	if not player:removeTotalMoney(config.goldPouchPrice) then
		player:sendCancelMessage("You need " .. config.goldPouchPrice .. " gold to buy a Gold Pouch.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local inbox = player:getStoreInbox()
	local item = Game.createItem(config.goldPouchId, 1)
	if not inbox or not item or inbox:addItemEx(item) ~= RETURNVALUE_NOERROR then
		if item then
			item:remove()
		end
		player:addMoney(config.goldPouchPrice)
		player:sendCancelMessage("Could not deliver the Gold Pouch. Your money was refunded.")
		return false
	end

	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You bought a Gold Pouch for " .. config.goldPouchPrice .. " gold. It was sent to your store inbox.")
	player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
	return false
end
talkaction:separator(" ")
talkaction:register()
