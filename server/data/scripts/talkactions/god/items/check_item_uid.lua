local MAX_REPORT_LINES = 30

local function send(player, message, ...)
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format(message, ...))
end

local function trim(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local function addSlot(slots, seen, slot, name)
	if type(slot) ~= "number" or seen[slot] then
		return
	end
	seen[slot] = true
	slots[#slots + 1] = { id = slot, name = name }
end

local function getInventorySlots()
	local slots = {}
	local seen = {}
	addSlot(slots, seen, CONST_SLOT_HEAD or 1, "head")
	addSlot(slots, seen, CONST_SLOT_NECKLACE or 2, "necklace")
	addSlot(slots, seen, CONST_SLOT_BACKPACK or 3, "backpack")
	addSlot(slots, seen, CONST_SLOT_ARMOR or 4, "armor")
	addSlot(slots, seen, CONST_SLOT_RIGHT or 5, "right hand")
	addSlot(slots, seen, CONST_SLOT_LEFT or 6, "left hand")
	addSlot(slots, seen, CONST_SLOT_LEGS or 7, "legs")
	addSlot(slots, seen, CONST_SLOT_FEET or 8, "feet")
	addSlot(slots, seen, CONST_SLOT_RING or 9, "ring")
	addSlot(slots, seen, CONST_SLOT_AMMO or 10, "ammo")
	addSlot(slots, seen, CONST_SLOT_STORE_INBOX, "store inbox slot")
	return slots
end

local function itemLabel(item)
	return string.format("%s [%d]", item:getName(), item:getId())
end

local function isSystemContainer(item)
	local itemId = item:getId()
	if itemId == ITEM_DEPOT or itemId == ITEM_LOCKER or itemId == ITEM_INBOX or itemId == ITEM_STORE_INBOX then
		return true
	end
	if ITEM_REWARD_CONTAINER and itemId == ITEM_REWARD_CONTAINER then
		return true
	end
	return ITEM_DEPOT_BOX_1 and itemId >= ITEM_DEPOT_BOX_1 and itemId <= (ITEM_DEPOT_BOX_1 + 16)
end

local function isStackable(item)
	local itemType = ItemType(item:getId())
	return itemType and itemType:isStackable() == true
end

local function remember(state, uid, item, path)
	if state.targetUid then
		if uid == state.targetUid then
			state.matches[#state.matches + 1] = { item = itemLabel(item), path = path }
		end
		return
	end

	local bucket = state.byUid[uid]
	if not bucket then
		bucket = { count = 0, samples = {} }
		state.byUid[uid] = bucket
		state.uidCount = state.uidCount + 1
	end

	bucket.count = bucket.count + 1
	if #bucket.samples < 5 then
		bucket.samples[#bucket.samples + 1] = { item = itemLabel(item), path = path }
	end
end

local function scanItem(state, item, path)
	if not item then
		return
	end

	state.scanned = state.scanned + 1

	local uid = item:getItemUID()
	if uid and uid ~= "" and uid ~= "0" then
		remember(state, uid, item, path)
	elseif not state.targetUid and not isStackable(item) and not isSystemContainer(item) then
		state.missing = state.missing + 1
		if #state.missingSamples < 10 then
			state.missingSamples[#state.missingSamples + 1] = { item = itemLabel(item), path = path }
		end
	end

	if not item.getItems then
		return
	end

	local ok, children = pcall(item.getItems, item, false)
	if not ok or not children then
		return
	end

	for i = 1, #children do
		local child = children[i]
		scanItem(state, child, string.format("%s > %s", path, itemLabel(child)))
	end
end

local function scanPlayer(state, target)
	local owner = "Player " .. target:getName()
	for _, slot in ipairs(getInventorySlots()) do
		local item = target:getSlotItem(slot.id)
		if item then
			scanItem(state, item, string.format("%s %s: %s", owner, slot.name, itemLabel(item)))
		end
	end

	local inbox = target:getInbox()
	if inbox then
		scanItem(state, inbox, string.format("%s inbox: %s", owner, itemLabel(inbox)))
	end

	local storeInbox = target:getStoreInbox()
	if storeInbox then
		scanItem(state, storeInbox, string.format("%s store inbox: %s", owner, itemLabel(storeInbox)))
	end

	local rewardChest = target:getRewardChest()
	if rewardChest then
		scanItem(state, rewardChest, string.format("%s reward chest: %s", owner, itemLabel(rewardChest)))
	end

	for _, town in ipairs(Game.getTowns()) do
		local depotChest = target:getDepotChest(town:getId(), false)
		if depotChest then
			scanItem(state, depotChest, string.format("%s depot %d: %s", owner, town:getId(), itemLabel(depotChest)))
		end
	end
end

local function scanHouses(state)
	for _, house in ipairs(Game.getHouses()) do
		local items = house:getItems()
		for i = 1, #items do
			local item = items[i]
			scanItem(state, item, string.format("House %d %s: %s", house:getId(), house:getName(), itemLabel(item)))
		end
	end
end

local function buildReport(state)
	if state.targetUid then
		return state.matches
	end

	local duplicates = {}
	for uid, bucket in pairs(state.byUid) do
		if bucket.count > 1 then
			duplicates[#duplicates + 1] = { uid = uid, count = bucket.count, samples = bucket.samples }
		end
	end

	table.sort(duplicates, function(left, right)
		if left.count == right.count then
			return left.uid < right.uid
		end
		return left.count > right.count
	end)

	return duplicates
end

local talkaction = TalkAction("/check")
function talkaction.onSay(player, words, param)
	param = trim(param)
	local targetUid = param ~= "" and (param:match("^uid%s*=?%s*(%d+)$") or param:match("^(%d+)$")) or nil
	if param ~= "" and not targetUid then
		send(player, "Usage: %s or %s <item uid>.", words, words)
		return false
	end

	local state = {
		byUid = {},
		matches = {},
		missingSamples = {},
		targetUid = targetUid,
		scanned = 0,
		uidCount = 0,
		missing = 0
	}

	for _, target in ipairs(Game.getPlayers()) do
		scanPlayer(state, target)
	end
	scanHouses(state)

	local report = buildReport(state)
	if targetUid then
		send(player, "[UID Check] UID %s found %d time(s). Scanned %d loaded item(s).", targetUid, #report, state.scanned)
		for i = 1, math.min(#report, MAX_REPORT_LINES) do
			send(player, "%d) %s - %s", i, report[i].item, report[i].path)
		end
		return false
	end

	send(player, "[UID Check] Scanned %d loaded item(s), %d UID(s), %d duplicate UID group(s), %d missing non-stackable UID(s).",
		state.scanned, state.uidCount, #report, state.missing)

	for i = 1, math.min(#report, MAX_REPORT_LINES) do
		local duplicate = report[i]
		send(player, "Duplicate UID %s appears %d times:", duplicate.uid, duplicate.count)
		for _, sample in ipairs(duplicate.samples) do
			send(player, "- %s - %s", sample.item, sample.path)
		end
	end

	if #report == 0 then
		send(player, "No duplicate item UIDs found in loaded items.")
	end

	if state.missing > 0 then
		send(player, "Missing UID samples:")
		for _, sample in ipairs(state.missingSamples) do
			send(player, "- %s - %s", sample.item, sample.path)
		end
	end

	return false
end
talkaction:separator(" ")
talkaction:accountType(6)
talkaction:access(true)
talkaction:register()
