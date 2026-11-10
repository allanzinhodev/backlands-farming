-- CrystalServer compatibility wrapper for FocusModule
-- Keeps the old constructor/API while using the real NpcSystem focus logic.

CrystalFocusModule = CrystalFocusModule or {}
CrystalFocusModule.__index = CrystalFocusModule

function CrystalFocusModule:new(...)
	if FocusModule and FocusModule ~= CrystalFocusModule and FocusModule.new then
		return FocusModule.new(FocusModule, ...)
	end

	local obj = {}
	setmetatable(obj, CrystalFocusModule)
	return obj
end
