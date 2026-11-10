local talk = TalkAction("/addaddon")

local outfitsList = {}

local function loadOutfits()
	outfitsList = {}

	for sex = 0, 1 do
		local outfits = Game.getOutfits(sex)
		if not outfits then
			return
		end

		for _, outfit in ipairs(outfits) do
			local lookType = outfit.lookType or outfit.type or outfit.looktype
			if lookType then
				outfitsList[lookType] = true
			end
		end
	end
end

loadOutfits()

function talk.onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	loadOutfits()

	local split = param:split(",")
	if #split < 2 then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /addaddon playerName, outfitId (or 'all'), [addon (0-3)]")
		return false
	end

	local targetName = split[1]:trim()
	local outfitParam = split[2]:trim():lower()

	local target = Player(targetName)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player " .. targetName .. " not found or not online.")
		return false
	end

	local addonValue = 3
	if split[3] then
		local tmp = tonumber(split[3]:trim())
		if tmp then
			addonValue = math.max(0, math.min(3, tmp))
		end
	end

	-- Add all outfits
	if outfitParam == "all" then
		local count = 0

		for lookType in pairs(outfitsList) do
			if target:addOutfitAddon(lookType, addonValue) then
				count = count + 1
			end
		end

		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Added " .. count .. " outfits with addon " .. addonValue .. " to " .. target:getName() .. ".")
		target:sendTextMessage(MESSAGE_INFO_DESCR, "You received all outfits with addon " .. addonValue .. "!")
		return false
	end

	-- Add by outfit ID only
	local lookType = tonumber(outfitParam)
	if not lookType then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Invalid outfit id. Use the outfit id from outfits.xml (or 'all').")
		return false
	end

	if not outfitsList[lookType] then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Outfit id " .. lookType .. " does not exist.")
		return false
	end

	if target:addOutfitAddon(lookType, addonValue) then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Outfit id " .. lookType .. " with addon " .. addonValue .. " added to " .. target:getName() .. ".")
		target:sendTextMessage(MESSAGE_INFO_DESCR, "You received a new outfit addon!")
	else
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Failed to add outfit id " .. lookType .. " to " .. target:getName() .. ".")
	end

	return false
end

talk:separator(" ")
talk:access(true)
talk:register()