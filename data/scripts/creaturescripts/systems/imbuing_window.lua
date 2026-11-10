local imbuingWindowLogout = CreatureEvent("ImbuingWindowLogout")
function imbuingWindowLogout.onLogout(player)
	ImbuingWindow.close(player)
	return true
end

imbuingWindowLogout:register()

local imbuingWindowLogin = CreatureEvent("ImbuingWindowLogin")
function imbuingWindowLogin.onLogin(player)
	player:registerEvent("ImbuingWindowLogout")
	return true
end

imbuingWindowLogin:register()
