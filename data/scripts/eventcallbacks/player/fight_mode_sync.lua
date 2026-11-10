local event = Event()

function event.onFightModeChanged(player, stance, chase, secure)
	player:sendFightMode()
end

event:register()
