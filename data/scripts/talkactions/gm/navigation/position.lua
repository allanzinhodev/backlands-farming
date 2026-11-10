local talk = TalkAction("/pos", "!pos")
function talk.onSay(player, words, param)
	if player:getGroup():getAccess() and param ~= "" then
		local x, y, z
		if param:find("{") then
			x = tonumber(param:match("x%s*=%s*(%d+)"))
			y = tonumber(param:match("y%s*=%s*(%d+)"))
			z = tonumber(param:match("z%s*=%s*(%d+)"))
		else
			local split = param:split(",")
			x = tonumber(split[1])
			y = tonumber(split[2])
			z = tonumber(split[3])
		end

		if x and y and z then
			player:teleportTo(Position(x, y, z))
		else
			player:sendCancelMessage("Invalid coordinates. Usage: /pos x,y,z or /pos {x=x, y=y, z=z}")
		end
	else
		local position = player:getPosition()
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		                       "Your current position is: " .. position.x .. ", " ..
			                       position.y .. ", " .. position.z .. ".")
	end
	return false
end
talk:separator(" ")
talk:register()
