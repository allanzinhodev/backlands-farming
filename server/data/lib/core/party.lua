local CHANNEL_LOOT = 10

function Party.broadcastPartyLoot(self, text)
	self:getLeader():sendChannelMessage("", text, TALKTYPE_CHANNEL_O, CHANNEL_LOOT)
	local membersList = self:getMembers()
	for i = 1, #membersList do
		local player = membersList[i]
		if player then player:sendChannelMessage("", text, TALKTYPE_CHANNEL_O, CHANNEL_LOOT) end
	end
end

function Participants(player, requireSharedExperience)
	local party = player:getParty()
	if not party then
		return { player }
	end

	if requireSharedExperience and not party:isSharedExperienceActive() then
		return { player }
	end

	local members = party:getMembers()
	table.insert(members, party:getLeader())
	return members
end

function onDeathForParty(creature, player, func)
	if not player or not player:isPlayer() then
		return
	end

	local participants = Participants(player, true)
	for _, participant in ipairs(participants) do
		func(creature, participant)
	end
end

function onDeathForDamagingPlayers(creature, func)
	local damageMap = creature:getDamageMap()
	if not damageMap then
		return
	end

	for key, _ in pairs(damageMap) do
		local player = Player(key)
		if player then
			func(creature, player)
		end
	end
end