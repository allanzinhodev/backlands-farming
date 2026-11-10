local function stressMessage(player, text)
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[smart-pointer-stress] " .. text)
end

local function runCase(name, fn, errors)
	local ok, err = pcall(fn)
	if not ok then
		errors[#errors + 1] = string.format("%s: %s", name, tostring(err))
	end
end

local function deleteTwice(value)
	if value and value.delete then
		value:delete()
		value:delete()
	end
end

local stress = TalkAction("/spstress")

function stress.onSay(player, words, param)
	if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
		return false
	end

	local loops = tonumber(param) or 500
	loops = math.max(1, math.min(loops, 10000))

	local errors = {}
	local started = os.mtime and os.mtime() or os.time()

	for i = 1, loops do
		runCase("Condition", function()
			local condition = Condition(CONDITION_ATTRIBUTES)
			condition:setParameter(CONDITION_PARAM_TICKS, 1000)
			local clone = condition:clone()
			deleteTwice(clone)
			deleteTwice(condition)
		end, errors)

		runCase("NetworkMessage", function()
			local message = NetworkMessage()
			deleteTwice(message)
		end, errors)

		runCase("XMLDocument/XMLNode", function()
			local doc = XMLDocument("data/XML/smart_pointer_stress.xml")
			if doc then
				local root = doc:child("smartPointerStress")
				if root then
					local first = root:firstChild()
					if first then
						local second = first:nextSibling()
						deleteTwice(second)
						deleteTwice(first)
					end
					deleteTwice(root)
				end
				deleteTwice(doc)
			end
		end, errors)

		runCase("ModalWindow", function()
			local window = ModalWindow(900000 + i, "SP Stress", "owned userdata")
			deleteTwice(window)
		end, errors)

		runCase("Loot", function()
			local loot = Loot()
			deleteTwice(loot)
		end, errors)

		runCase("MonsterSpell", function()
			local spell = MonsterSpell()
			deleteTwice(spell)
		end, errors)

		runCase("OfflinePlayer", function()
			local offlinePlayer = OfflinePlayer(player:getGuid())
			deleteTwice(offlinePlayer)
		end, errors)

		if i % 50 == 0 then
			collectgarbage("collect")
		end
	end

	collectgarbage("collect")
	collectgarbage("collect")

	local finished = os.mtime and os.mtime() or os.time()
	if #errors == 0 then
		stressMessage(player, string.format("OK: %d loops finished. Check server console/log for crashes or sanitizer errors.", loops))
	else
		stressMessage(player, string.format("FAILED: %d Lua errors in %d loops.", #errors, loops))
		for i = 1, math.min(#errors, 8) do
			stressMessage(player, errors[i])
		end
	end

	stressMessage(player, string.format("Elapsed marker: %s -> %s", tostring(started), tostring(finished)))
	return false
end

stress:separator(" ")
stress:register()

local registerStress = TalkAction("/spregisterstress")

function registerStress.onSay(player, words, param)
	if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
		return false
	end

	local count = tonumber(param) or 25
	count = math.max(1, math.min(count, 250))
	local errors = {}
	local stamp = os.time()

	for i = 1, count do
		runCase("TalkAction register", function()
			local command = string.format("/sp_owned_%d_%d", stamp, i)
			local action = TalkAction(command)
			function action.onSay(innerPlayer)
				innerPlayer:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, command .. " alive")
				return false
			end
			action:register()
		end, errors)
	end

	collectgarbage("collect")
	collectgarbage("collect")

	if #errors == 0 then
		stressMessage(player, string.format("OK: registered %d temporary TalkAction objects.", count))
		stressMessage(player, "Optional: try one generated command from console log pattern /sp_owned_<timestamp>_<n>.")
	else
		stressMessage(player, string.format("FAILED: %d register errors.", #errors))
		for i = 1, math.min(#errors, 8) do
			stressMessage(player, errors[i])
		end
	end
	return false
end

registerStress:separator(" ")
registerStress:register()

local conditionStress = TalkAction("/spconditionstress")

function conditionStress.onSay(player, words, param)
	if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
		return false
	end

	local loops = tonumber(param) or 10000
	loops = math.max(1, math.min(loops, 100000))
	local errors = {}
	local conditionTypes = {
		CONDITION_ATTRIBUTES,
		CONDITION_HASTE,
		CONDITION_PARALYZE,
		CONDITION_INVISIBLE,
		CONDITION_LIGHT,
		CONDITION_REGENERATION,
		CONDITION_SOUL,
		CONDITION_DRUNK,
	}

	for i = 1, loops do
		for _, conditionType in ipairs(conditionTypes) do
			runCase("Condition-only", function()
				local condition = Condition(conditionType)
				if not condition then
					return
				end

				condition:setParameter(CONDITION_PARAM_TICKS, 1000 + i)
				condition:setConstant(i % 2 == 0)

				if conditionType == CONDITION_ATTRIBUTES then
					condition:setParameter(CONDITION_PARAM_STAT_MAXHITPOINTS, 10)
					condition:setParameter(CONDITION_PARAM_SKILL_MELEE, 1)
				elseif conditionType == CONDITION_LIGHT then
					condition:setParameter(CONDITION_PARAM_LIGHT_LEVEL, 6)
					condition:setParameter(CONDITION_PARAM_LIGHT_COLOR, 215)
				elseif conditionType == CONDITION_REGENERATION then
					condition:setParameter(CONDITION_PARAM_HEALTHGAIN, 1)
					condition:setParameter(CONDITION_PARAM_HEALTHTICKS, 1000)
					condition:setParameter(CONDITION_PARAM_MANAGAIN, 1)
					condition:setParameter(CONDITION_PARAM_MANATICKS, 1000)
				end

				local cloneA = condition:clone()
				local cloneB = cloneA and cloneA:clone() or nil

				deleteTwice(cloneB)
				deleteTwice(cloneA)
				deleteTwice(condition)
			end, errors)
		end

		if i % 100 == 0 then
			collectgarbage("collect")
		end
	end

	collectgarbage("collect")
	collectgarbage("collect")

	if #errors == 0 then
		stressMessage(player, string.format("OK: %d condition loops finished across %d condition types.", loops, #conditionTypes))
	else
		stressMessage(player, string.format("FAILED: %d condition errors in %d loops.", #errors, loops))
		for i = 1, math.min(#errors, 8) do
			stressMessage(player, errors[i])
		end
	end
	return false
end

conditionStress:separator(" ")
conditionStress:register()
