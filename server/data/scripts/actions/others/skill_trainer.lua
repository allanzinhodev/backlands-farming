local statues = { 16198, 16199, 16200, 16201, 16202 }

local skillOffline = Action()

function skillOffline.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:isPzLocked() then
		return false
	end
	
	-- SKILL_OFFLINE_AUTO = 255
	player:setOfflineTrainingSkill(255)
	player:remove()
	return true
end

for _, id in ipairs(statues) do
	skillOffline:id(id)
end

skillOffline:register() 