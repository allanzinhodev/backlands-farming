local talk = TalkAction("/addmount")

local mountsList = {}

local function loadMounts()
	mountsList = {}

	local mounts = Game.getMounts()
	if not mounts then
		return
	end

	for _, mount in ipairs(mounts) do
		if mount.id then
			mountsList[mount.id] = true
		end
	end
end

loadMounts()

function talk.onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	loadMounts()

	local split = param:split(",")
	if #split < 2 then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /addmount playerName, mountId (or 'all')")
		return false
	end

	local targetName = split[1]:trim()
	local mountParam = split[2]:trim():lower()

	local target = Player(targetName)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player " .. targetName .. " not found or not online.")
		return false
	end

	-- Add all mounts
	if mountParam == "all" then
		local count = 0

		for mountId in pairs(mountsList) do
			if target:addMount(mountId) then
				count = count + 1
			end
		end

		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Added " .. count .. " mounts to " .. target:getName() .. ".")
		target:sendTextMessage(MESSAGE_INFO_DESCR, "You received all mounts! Relog to use them.")
		return false
	end

	-- Add by mount ID only
	local mountId = tonumber(mountParam)
	if not mountId then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Invalid mount id. Use the mount id from mounts.xml (or 'all').")
		return false
	end

	if not mountsList[mountId] then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Mount id " .. mountId .. " does not exist.")
		return false
	end

	if target:addMount(mountId) then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Mount id " .. mountId .. " added to " .. target:getName() .. ". Player should relog to use it.")
		target:sendTextMessage(MESSAGE_INFO_DESCR, "You received a new mount! Relog to use it.")
	else
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Failed to add mount id " .. mountId .. " to " .. target:getName() .. " (already owned or invalid).")
	end

	return false
end

talk:separator(" ")
talk:access(true)
talk:register()
