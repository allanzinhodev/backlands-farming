local talkResetInfo = TalkAction("!resetinfo")

function talkResetInfo.onSay(player, words, param)
	if not player or not player:isPlayer() then
		return false
	end

	local resets = player:getResetCount()
	local vocation = player:getVocation()
	local vocId = vocation and vocation:getId() or 0
	local function getBonus(getterName, fallback)
		local method = player[getterName]
		if type(method) == "function" then
			return method(player)
		end
		return fallback or 0
	end

	local function getMaxBonus(configName, getterName)
		local total = ResetBonusConfig.getTotalBonus(configName, resets, vocId)
		local config = ResetBonusConfig[configName]
		if config and config.bonusMode == "percent" then
			local maxMethod = player[getterName]
			if type(maxMethod) == "function" then
				return math.floor(maxMethod(player) * total / 100)
			end
		end
		return math.floor(total)
	end

	local dmgBonus = getBonus("getResetDamageBonus", ResetBonusConfig.getTotalBonus("damage", resets, vocId))
	local defBonus = getBonus("getResetDefenseBonus", ResetBonusConfig.getTotalBonus("defense", resets, vocId))
	local healBonus = getBonus("getResetHealingBonus", ResetBonusConfig.getTotalBonus("healing", resets, vocId))
	local xpBonus = ResetBonusConfig.getTotalBonus("experience", resets, vocId)
	local atkSpdBonus = getBonus("getResetAttackSpeedBonus", math.floor(ResetBonusConfig.getTotalBonus("attackSpeed", resets, vocId)))
	local hpBonus = getBonus("getResetHpBonus", getMaxBonus("hp", "getMaxHealth"))
	local manaBonus = getBonus("getResetManaBonus", getMaxBonus("mana", "getMaxMana"))
	local manaPotBonus = getBonus("getResetManaPotionBonus", ResetBonusConfig.getTotalBonus("manaPotion", resets, vocId))
	local manaSpellBonus = getBonus("getResetManaSpellBonus", ResetBonusConfig.getTotalBonus("manaSpell", resets, vocId))

	local msg = string.format(
		"[Reset Info] Resets: %d | Damage: %.1f%% | Defense: %.1f%% | Healing: %.1f%% | XP: %.1f%% | AtkSpeed: -%dms | HP+: %d | Mana+: %d | ManaPot: %.1f%% | ManaSpell: %.1f%%",
		resets, dmgBonus, defBonus, healBonus, xpBonus, atkSpdBonus, hpBonus, manaBonus, manaPotBonus, manaSpellBonus
	)

	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, msg)
	return false
end

talkResetInfo:register()
