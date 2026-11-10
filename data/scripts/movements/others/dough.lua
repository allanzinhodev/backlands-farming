local moveevent = MoveEvent()
function moveevent.onAddItem(moveitem, tileitem, position)
	if moveitem:getId() == 1848 then
		moveitem:transform(1768)
		position:sendMagicEffect(CONST_ME_HITBYFIRE)
	elseif moveitem:getId() == 6275 then
		moveitem:transform(6276, 12)
		position:sendMagicEffect(CONST_ME_HITBYFIRE)
	end
	return true
end
moveevent:type("additem")
moveevent:id(3435, 3437, 3439, 3441)
moveevent:tileItem(1)
moveevent:register()
