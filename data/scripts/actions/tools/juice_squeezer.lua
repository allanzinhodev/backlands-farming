local fruits = {
	3584, -- pear
	3585, -- red apple
	3586, -- orange
	3587, -- banana
	3588, -- blueberry
	3589, -- coconut
	3590, -- cherry
	3591, -- strawberry
	3592, -- grapes
	3593, -- melon
	5096, -- mango
	8011, -- plum
	8012, -- raspberry
	8013 -- lemon
}

local juiceSquizer = Action()

function juiceSquizer.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local targetItem = target:getItem()
	if not targetItem then return true end

	local targetId = targetItem:getId()
	if table.contains(fruits, targetId) and player:removeItem(2874, 1, 0) then
		targetItem:remove(1)
		player:addItem(2874, targetId == 3589 and 14 or 21) -- if target is a coconut, create coconut milk, otherwise create fruit juice
		return true
	end
	return true
end

juiceSquizer:id(5865)
juiceSquizer:register()
