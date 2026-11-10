local resetOnLogin = CreatureEvent("ResetSystemOnLogin")

function resetOnLogin.onLogin(player)
	if ResetBonusConfig then
		ResetBonusConfig.applyBonuses(player)
	end
	return true
end

resetOnLogin:register()
