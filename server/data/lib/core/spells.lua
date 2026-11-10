function Spell:blockType(blockType)
	local type = blockType:lower()
	if type == 'solid' then
		self:isBlocking(true, false)
	elseif type == 'creature' then
		self:isBlocking(false, true)
	elseif type == 'all' then
		self:isBlocking(true, true)
	end
end

function Spell:playerNameParam(bool)
	self:hasPlayerNameParam(bool)
end

function Spell:secondaryGroup(secondaryGroup)
	local primaryGroup = self:group()
	self:group(primaryGroup, secondaryGroup)
end

-- Monk spell attack value calculation (ported from Crystal Server)
function calculateAttackValue(player, attackSkill, weaponDamage)
	local level = player:getLevel()
	local flatBonus
	if level < 500 then
		flatBonus = level * 0.2
	elseif level <= 1100 then
		flatBonus = 100 + (level - 500) * 0.1667
	elseif level <= 1800 then
		flatBonus = 200 + (level - 1101) * 0.1429
	elseif level <= 2600 then
		flatBonus = 300 + (level - 1800) * 0.125
	else
		flatBonus = 400 + (level - 2600) * 0.111
	end

	local fightModeMultiplier = 1.2
	local fightFactor = math.floor(fightModeMultiplier * weaponDamage)
	local skillFactor = (attackSkill + 4) / 28
	return flatBonus + (fightFactor * skillFactor)
end
