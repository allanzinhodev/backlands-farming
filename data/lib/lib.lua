DATA_DIRECTORY = "data"
CORE_DIRECTORY = DATA_DIRECTORY

-- Core API functions implemented in Lua
dofile(CORE_DIRECTORY .. '/lib/core/core.lua')

-- Compatibility library for our old Lua API
dofile(CORE_DIRECTORY .. '/lib/compat/compat.lua')

-- Debugging helper function for Lua developers
dofile(CORE_DIRECTORY .. '/lib/debugging/dump.lua')

dofile(CORE_DIRECTORY .. '/lib/functions/load.lua')

local startupFile = io.open("data/startup/startup.lua", "r")
if startupFile ~= nil then
	dofile("data/startup/startup.lua")
	io.close(startupFile)
end
