local BOOSTED_DISPLAY_POS = Position(998, 992, 7)
local BOOSTED_DISPLAY_ID = 0

local function removeBoostedDisplay()
	local monster = Monster(BOOSTED_DISPLAY_ID)
	if monster then
		monster:remove()
	end
	BOOSTED_DISPLAY_ID = 0
end

local function spawnBoostedDisplay()
	removeBoostedDisplay()
	local boosted = Game.getBoostedCreature()
	if boosted == "" then
		return
	end

	local mType = MonsterType(boosted)
	if not mType then
		return
	end

	local statue = Game.createMonster("Boosted Statue", BOOSTED_DISPLAY_POS, false, true)
	if not statue then
		return
	end

	statue:setOutfit(mType:getOutfit())
	statue:rename(mType:getName(), "the boosted creature of the day")
	statue:setDropLoot(false)
	BOOSTED_DISPLAY_ID = statue:getId()
end

local startupEvent = GlobalEvent("BoostedDisplayStartup")
function startupEvent.onStartup()
	addEvent(spawnBoostedDisplay, 3000)
	return true
end
startupEvent:register()

local REFRESH_INTERVAL = 60 * 1000
local midnightCheck = GlobalEvent("BoostedDisplayRefresh")

midnightCheck:interval(REFRESH_INTERVAL)
function midnightCheck.onThink(interval)
	local boosted = Game.getBoostedCreature()
	if boosted == "" then
		return true
	end

	local needRefresh = true
	local monster = Monster(BOOSTED_DISPLAY_ID)
	if monster and monster:getName():lower() == boosted:lower() then
		needRefresh = false
	end

	if needRefresh then
		spawnBoostedDisplay()
	end
	return true
end
midnightCheck:register()
