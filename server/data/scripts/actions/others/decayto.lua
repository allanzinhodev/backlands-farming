local action = Action()

local decayItems = {
	[2660] = 2661,
	[2661] = 2660, -- cuckoo clock
	[2662] = 2663,
	[2663] = 2662, -- cuckoo clock
	[2911] = 2912,
	[2912] = 2911, -- candelabrum
	[2914] = 2915,
	[2915] = 2914, -- lamp
	[2917] = 2918,
	[2918] = 2917, -- candlestick
	[2920] = 2921,
	[2921] = 2920, -- torch
	[2922] = 2923,
	[2923] = 2922, -- torch
	[2924] = 2925,
	[2925] = 2924, -- torch
	[3046] = 3047,
	[3047] = 3046, -- magic light wand
	[5812] = 5813,
	[5813] = 5812, -- skull candle
	[7183] = 7184, -- baby seal doll
	[9802] = 9803, -- friendship amulet
	[3997] = 4010 -- Tibiora's box
}

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local transformIds = decayItems[item:getId()]
	if not transformIds then return false end

	item:transform(transformIds)
	item:decay()
	return true
end

action:id(2660, 2661, 2662, 2663, 2911, 2912, 2914, 2915, 2917, 2918, 2920, 2921, 2922, 2923, 2924, 2925, 3046, 3047, 5812, 5813, 7183, 9802, 3997)
action:register()
