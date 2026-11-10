-- BossLever System library
-- Ported from Crystal Server to TFS Downgrade 1.8-8.60 (Lua-only implementation of missing systems).

-- Helper function toKey
if not toKey then
	function toKey(str)
		return str:lower():gsub(" ", "-"):gsub("%s+", "")
	end
end

-- Define unique placeholder keys for configKeys if they don't exist
if configKeys then
	configKeys.BOSS_DEFAULT_TIME_TO_FIGHT_AGAIN = configKeys.BOSS_DEFAULT_TIME_TO_FIGHT_AGAIN or 99999
	configKeys.BOSS_DEFAULT_TIME_TO_DEFEAT = configKeys.BOSS_DEFAULT_TIME_TO_DEFEAT or 99998
end

-- Hook configManager.getNumber
if configManager and configManager.getNumber then
	local oldGetNumber = configManager.getNumber
	function configManager.getNumber(key)
		if key == configKeys.BOSS_DEFAULT_TIME_TO_FIGHT_AGAIN then
			return _G.bossDefaultTimeToFightAgain or 72000
		elseif key == configKeys.BOSS_DEFAULT_TIME_TO_DEFEAT then
			return _G.bossDefaultTimeToDefeat or 600
		end
		return oldGetNumber(key)
	end
end

-- SimpleTeleport implementation

if not SimpleTeleport then
	function SimpleTeleport(from, destination, condition, disableEffect)
		local teleport = MoveEvent()

		function teleport.onStepIn(creature, item, position, fromPosition)
			local player = creature:getPlayer()
			if not player then
				return false
			end

			if condition and not condition(player, item, position, fromPosition) then
				return false
			end

			player:teleportTo(destination)
			if not disableEffect then
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			end
			return true
		end

		teleport:position(from)
		teleport:register()
		return teleport
	end
end

-- Zone implementation in Lua
local RealZone = _G.Zone

_G.Zone = {}
Zone.__index = Zone

local zonesByName = {}

setmetatable(Zone, {
	__call = function(self, name)
		if type(name) == "number" then
			if RealZone then
				return RealZone(name)
			end
		end

		name = tostring(name)
		if zonesByName[name] then
			return zonesByName[name]
		end

		local obj = {
			name = name,
			areas = {},
			removeDestination = nil,
		}
		setmetatable(obj, Zone)
		zonesByName[name] = obj
		return obj
	end
})

function Zone:getName()
	return self.name
end

function Zone:addArea(fromPos, toPos)
	table.insert(self.areas, {from = Position(fromPos), to = Position(toPos)})
end

function Zone:blockFamiliars()
	-- No-op fallback
end

function Zone:setRemoveDestination(pos)
	self.removeDestination = Position(pos)
end

function Zone:getRemoveDestination()
	return self.removeDestination
end

function Zone:refresh()
	-- No-op
end

function Zone:getCreatures(onlyPlayers, onlyMonsters)
	local result = {}
	local seen = {}
	for _, area in ipairs(self.areas) do
		local cx = math.floor((area.from.x + area.to.x) / 2)
		local cy = math.floor((area.from.y + area.to.y) / 2)
		local cz = area.from.z
		local center = Position(cx, cy, cz)
		local rx = math.ceil(math.abs(area.from.x - area.to.x) / 2)
		local ry = math.ceil(math.abs(area.from.y - area.to.y) / 2)

		local specs = Game.getSpectators(center, false, onlyPlayers or false, rx, rx, ry, ry)
		if specs then
			for _, spec in ipairs(specs) do
				if not seen[spec:getId()] then
					if not onlyMonsters or spec:isMonster() then
						seen[spec:getId()] = true
						table.insert(result, spec)
					end
				end
			end
		end
	end
	return result
end

function Zone:getPlayers()
	return self:getCreatures(true, false)
end

function Zone:getMonsters()
	return self:getCreatures(false, true)
end

function Zone:countPlayers(notFlag)
	local players = self:getPlayers()
	local count = 0
	for _, player in ipairs(players) do
		if notFlag then
			local hasFlag = false
			if player.hasGroupFlag then
				hasFlag = player:hasGroupFlag(notFlag)
			elseif player.getGroup then
				local group = player:getGroup()
				if group and group:getId() >= 3 then
					hasFlag = true
				end
			end
			if not hasFlag then
				count = count + 1
			end
		else
			count = count + 1
		end
	end
	return count
end

function Zone:sendTextMessage(...)
	local players = self:getPlayers()
	for _, player in ipairs(players) do
		player:sendTextMessage(...)
	end
end

function Zone:removePlayers()
	local players = self:getPlayers()
	for _, player in ipairs(players) do
		if self.removeDestination then
			player:teleportTo(self.removeDestination)
			self.removeDestination:sendMagicEffect(CONST_ME_TELEPORT)
		end
	end
end

function Zone:removeMonsters()
	local monsters = self:getMonsters()
	for _, monster in ipairs(monsters) do
		monster:remove()
	end
end

-- Lever implementation in Lua
Lever = {}
Lever.__index = Lever

setmetatable(Lever, {
	__call = function(self)
		local lever_data = {
			positions = {},
			info_positions = nil,
			players = {},
			condition = function()
				return true
			end,
			teleport_player_func = function()
				return true
			end,
		}
		return setmetatable(lever_data, { __index = Lever })
	end,
})

function Lever:getPositions()
	return self.positions
end

function Lever:setPositions(positions)
	if type(positions) ~= "table" then
		positions = { positions }
	end
	self.positions = positions
end

function Lever:getInfoPositions()
	return self.info_positions
end

function Lever:getPlayers()
	return self.players
end

function Lever:addPlayer(player)
	if player and player:isPlayer() then
		table.insert(self.players, player)
	end
end

function Lever:setCondition(func)
	self.condition = func
end

function Lever:getCondition(...)
	return self.condition(...)
end

function Lever:setTeleportPlayerFunc(func)
	self.teleport_player_func = func
end

function Lever:getTeleportPlayerFunc(...)
	return self.teleport_player_func(...)
end

function Lever:checkPositions()
	local positions = self:getPositions()
	if not positions then
		error("Positions: not set")
		return nil
	end
	local array = {}
	self.players = {}
	for i, v in ipairs(positions) do
		local tile = Tile(v.pos)
		if tile then
			local creature = tile:getBottomCreature()
			local items = tile:getItems()
			local ground = tile:getGround()
			local actionID = ground and ground:getActionId() or 0
			local uniqueID = ground and ground:getUniqueId() or 0
			self:addPlayer(creature)
			table.insert(array, {
				tile = tile,
				creature = creature,
				teleport = v.teleport,
				effect = v.effect or CONST_ME_TELEPORT,
				item = items,
				ground = ground,
				actionID = actionID,
				uniqueID = uniqueID,
			})
		end
	end
	self.info_positions = array
	return array
end

function Lever:checkConditions()
	local info = self:getInfoPositions()
	if not info then
		error("Necessary information from positions missing")
		return false
	end
	for i, v in pairs(info) do
		v.condition = self:getCondition(v.creature)
		if v.condition == false then
			return v.condition
		end
	end
	return true
end

function Lever:executeOnPlayers(func)
	for _, player in pairs(self:getPlayers()) do
		func(player)
	end
end

function Lever:teleportPlayers()
	local info = self:getInfoPositions()
	if not info then
		return false
	end

	for i, v in pairs(info) do
		local player = v.creature
		if player then
			player:teleportTo(v.teleport)
			player:getPosition():sendMagicEffect(v.effect or CONST_ME_TELEPORT)
			self:getTeleportPlayerFunc(player)
		end
	end
end

function Lever:setCooldownAllPlayers(bossName, value)
	local info = self:getInfoPositions()
	if not info then
		error("Necessary information from players missing")
		return false
	end

	for i, v in pairs(info) do
		if v.creature then
			local player = v.creature:getPlayer()
			if player then
				player:setBossCooldown(bossName, value)
			end
		end
	end
end

function Lever:canUseLever(player, bossName, timeToFightAgain)
	local info = self:getInfoPositions()
	for _, v in pairs(info) do
		local newPlayer = v.creature
		if newPlayer and not newPlayer:canFightBoss(bossName) then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You or a member in your team have to wait " .. timeToFightAgain .. " hours to face " .. bossName .. " again!")
			newPlayer:getPosition():sendMagicEffect(CONST_ME_POFF)
			return false
		end
	end
	return true
end

-- BossLever implementation in Lua
BossLever = {}
BossLever.__index = BossLever

setmetatable(BossLever, {
	__call = function(self, config)
		local boss = config.boss
		if not boss then
			error("BossLever: boss is required")
		end
		return setmetatable({
			name = boss.name:lower(),
			encounter = config.encounter,
			bossPosition = boss.position,
			timeToFightAgain = config.timeToFightAgain or (configManager and configManager.getNumber(configKeys.BOSS_DEFAULT_TIME_TO_FIGHT_AGAIN)) or 72000,
			timeToDefeat = config.timeToDefeat or (configManager and configManager.getNumber(configKeys.BOSS_DEFAULT_TIME_TO_DEFEAT)) or 600,
			timeAfterKill = config.timeAfterKill or 60,
			requiredLevel = config.requiredLevel or 0,
			createBoss = boss.createFunction,
			disabled = config.disabled,
			minPlayers = config.minPlayers or 1,
			playerPositions = config.playerPositions,
			onUseExtra = config.onUseExtra or function() end,
			exitTeleporter = config.exitTeleporter,
			exit = config.exit,
			area = config.specPos,
			monsters = config.monsters or {},
			disableCooldown = config.disableCooldown,
			_position = nil,
			_uid = nil,
			_aid = nil,
		}, { __index = BossLever })
	end,
})

function BossLever:position(position)
	self._position = position
	return self
end

function BossLever:uid(uid)
	self._uid = uid
	return self
end

function BossLever:aid(aid)
	self._aid = aid
	return self
end

function BossLever:kvScope()
	local mType = MonsterType(self.name)
	if not mType then
		error("BossLever: boss name is invalid")
	end
	return "boss.cooldown." .. toKey(tostring(mType:raceId()))
end

function BossLever:lastEncounterTime(player)
	if not player or self.disableCooldown then
		return 0
	end
	return player:getBossCooldown(self.name)
end

function BossLever:setLastEncounterTime(time)
	local info = self.lever:getInfoPositions()
	if not info then
		logger.error("BossLever:setLastEncounterTime - lever:getInfoPositions() returned nil")
		return false
	end
	for _, v in pairs(info) do
		if v.creature then
			local player = v.creature:getPlayer()
			if player then
				player:setBossCooldown(self.name, time)
			end
		end
	end
	return true
end

function BossLever:onUse(player)
	local monsterType = MonsterType(self.name)
	local monsterName = monsterType and monsterType:getName() or self.name
	local isParticipant = false
	for _, v in ipairs(self.playerPositions) do
		if Position(v.pos) == player:getPosition() then
			isParticipant = true
		end
	end
	if not isParticipant then
		return false
	end

	if self.disabled then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The boss is temporarily disabled.")
		return true
	end

	local zone = self:getZone()
	zone:refresh()
	if zone:countPlayers() > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There's already someone fighting with " .. monsterName .. ".")
		return true
	end

	self.lever = Lever()
	local lever = self.lever
	lever:setPositions(self.playerPositions)
	lever:setCondition(function(creature)
		if not creature or not creature:isPlayer() then
			return true
		end

		local checkAccountType = creature:getAccountType() < ACCOUNT_TYPE_GAMEMASTER
		local isGameTester = PlayerFlag_IsGameTester and player:hasFlag(PlayerFlag_IsGameTester)
		if checkAccountType and not isGameTester and creature:getLevel() < self.requiredLevel then
			local message = "All players need to be level " .. self.requiredLevel .. " or higher."
			creature:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
			return false
		end

		local infoPositions = lever:getInfoPositions()
		if checkAccountType and not isGameTester and self:lastEncounterTime(creature) > os.time() then
			for _, posInfo in pairs(infoPositions) do
				local currentPlayer = posInfo.creature
				if currentPlayer then
					local lastEncounter = self:lastEncounterTime(currentPlayer)
					local currentTime = os.time()
					if lastEncounter and currentTime < lastEncounter then
						local timeLeft = lastEncounter - currentTime
						local timeMessage = Game.getTimeInWords(timeLeft) .. " to face " .. self.name .. " again!"
						local message = "You have to wait " .. timeMessage

						if currentPlayer ~= player then
							player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A member in your team has to wait " .. timeMessage)
						end

						currentPlayer:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
						currentPlayer:getPosition():sendMagicEffect(CONST_ME_POFF)
					end
				end
			end
			return false
		end

		return self.onUseExtra(creature, infoPositions) ~= false
	end)

	lever:checkPositions()
	if #lever:getPlayers() < self.minPlayers then
		lever:executeOnPlayers(function(creature)
			local message = string.format("You need %d qualified players for this challenge.", self.minPlayers)
			creature:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
			creature:getPosition():sendMagicEffect(CONST_ME_POFF)
		end)
		return false
	end
	if lever:checkConditions() then
		zone:removeMonsters()
		for _, monster in pairs(self.monsters) do
			Game.createMonster(monster.name, monster.pos, true, true)
		end
		if self.createBoss then
			if not self.createBoss() then
				return true
			end
		elseif self.bossPosition then
			logger.debug("BossLever:onUse - creating boss: %s", self.name)
			local monster = Game.createMonster(self.name, self.bossPosition, true, true)
			if not monster then
				return true
			end
			monster:registerEvent("BossLeverOnDeath")
		end
		lever:teleportPlayers()
		lever:setCooldownAllPlayers(self.name, os.time() + self.timeToFightAgain)
		if self.encounter and Encounter then
			local encounter = Encounter(self.encounter)
			encounter:reset()
			encounter:start()
		end
		self:setLastEncounterTime(os.time() + self.timeToFightAgain)
		if self.timeoutEvent then
			stopEvent(self.timeoutEvent)
			self.timeoutEvent = nil
		end
		self.timeoutEvent = addEvent(function(zn)
			zn:refresh()
			zn:removePlayers()
		end, self.timeToDefeat * 1000, zone)
	end
	return true
end

function BossLever:getZone()
	return Zone("boss." .. toKey(self.name))
end

function BossLever:register()
	local missingParams = {}
	if not self.name then
		table.insert(missingParams, "boss.name")
	end
	if not self.playerPositions then
		table.insert(missingParams, "playerPositions")
	end
	if not self.area then
		table.insert(missingParams, "specPos")
	end
	if not self.exit then
		table.insert(missingParams, "exit")
	end
	if not self._position and not self._uid and not self._aid then
		table.insert(missingParams, "position or uid or aid")
	end
	if #missingParams > 0 then
		local name = self.name or "unknown"
		logger.error("BossLever:register() - boss with name %s missing parameters: %s", name, table.concat(missingParams, ", "))
		return false
	end

	local zone = self:getZone()

	zone:addArea(self.area.from, self.area.to)
	zone:blockFamiliars()
	zone:setRemoveDestination(self.exit)

	local action = Action()
	action.onUse = function(player, item, fromPosition, target, toPosition, isHotkey)
		return self:onUse(player)
	end
	if self._position then
		action:position(self._position)
	end
	if self._uid then
		action:uid(self._uid)
	end
	if self._aid then
		action:aid(self._aid)
	end
	action:register()
	BossLever[self.name] = self

	if self.exitTeleporter then
		SimpleTeleport(self.exitTeleporter, self.exit)
	end
	return true
end
