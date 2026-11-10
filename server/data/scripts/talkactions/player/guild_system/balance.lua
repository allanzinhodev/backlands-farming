local balance = TalkAction("/balance")

function balance.onSay(player, words, param)
	local guild = player:getGuild()
	if not guild then
		player:sendCancelMessage("You are not in a guild.")
		return false
	end

	if not param or param == "" then
		local text = "Guild Banking System\n\n"
		text = text .. "Guild Balance: " .. guild:getBankBalance() .. " gold\n"
		text = text .. "Your Bank Balance: " .. player:getBankBalance() .. " gold\n\n"
		
		text = text .. "Commands:\n"
		text = text .. "/balance donate amount\n"
		text = text .. "Donate money from your bank to guild balance.\n\n"
		
		text = text .. "/balance pick amount\n"
		text = text .. "Withdraw money from guild balance (Leaders only).\n\n"
		
		text = text .. "IMPORTANT: You must open the Guild Channel (Ctrl+O) to use these commands!"
		
		player:popupFYI(text)
		return false
	end

	player:guildBalance(param)
	return false
end

balance:separator(" ")
balance:register()
