local ITEM_GOLD_POUCH = 23721

local function containsCheck(container, checkFn)
	if checkFn(container:getId()) then
		return true
	end
	if container:isContainer() then
		local items = container:getItems()
		for _, item in ipairs(items) do
			if checkFn(item:getId()) then
				return true
			end
			if item:isContainer() and containsCheck(item, checkFn) then
				return true
			end
		end
	end
	return false
end

local function isGoldPouch(id) return id == ITEM_GOLD_POUCH end
local function isExercise(id) return ExerciseWeaponsTable[id] ~= nil end

local event = Event()
event.onTradeAccept = function(self, target, item, targetItem)
	-- Gold Pouch
	if containsCheck(item, isGoldPouch) then
		self:sendCancelMessage("You cannot trade the Gold Pouch.")
		return false
	end
	if containsCheck(targetItem, isGoldPouch) then
		self:sendCancelMessage("You cannot accept a trade containing a Gold Pouch.")
		return false
	end

	-- Exercise Weapons
	if containsCheck(item, isExercise) then
		self:sendCancelMessage("You cannot trade this training weapon.")
		return false
	end
	if containsCheck(targetItem, isExercise) then
		self:sendCancelMessage("You cannot accept this training weapon.")
		return false
	end
	file = io.open('data/logs/trade.txt',"a")
    file:write(""..os.date("%c")..": "..self:getName().." traded:")
    if item:isContainer() then
            file:write(string.format(' %s (%s)(%s),',  item:getName(), item:getId(), item:getCount() > 1 and item:getCount()))
    else
        file:write(string.format(' %s (%s)(%s),', item:getName(), item:getId(), item:getCount() > 1 and item:getCount()))
    end
    file:write(" with "..target:getName().." for:")
    if targetItem:isContainer() then
            file:write(string.format(' %s (%s)(%s),', targetItem:getName(), targetItem:getId(), targetItem:getCount() > 1 and targetItem:getCount()))
			self:sendTextMessage(MESSAGE_INFO_DESCR, "You just trade with "..target:getName()..". Exchanged an "..item:getName().." for "..targetItem:getName()..".")
    else
        file:write(string.format(' %s (%s)(%s).', targetItem:getName(), targetItem:getId(), targetItem:getCount() > 1 and targetItem:getCount()))
		self:sendTextMessage(MESSAGE_INFO_DESCR, "You just trade with "..target:getName()..". Exchanged an "..item:getName().." for "..targetItem:getName()..".")
	end
    file:write('\n-------------------------\n\n')
    file:close()
	return true
end
event:register()
