-- CrystalServer compatibility wrapper for NpcHandler
-- Reuses the real NpcSystem handler and only preserves the old constructor API.

CrystalNpcHandler = CrystalNpcHandler or {}
CrystalNpcHandler.__index = CrystalNpcHandler

function CrystalNpcHandler:new(keywordHandler, ...)
	if _G.OriginalNpcHandlerNew then
		local handler = _G.OriginalNpcHandlerNew(NpcHandler, keywordHandler, ...)
		_G.LastCrystalNpcHandler = handler
		return handler
	end

	local obj = {
		keywordHandler = keywordHandler,
		messages = {},
		modules = {},
	}
	setmetatable(obj, CrystalNpcHandler)
	_G.LastCrystalNpcHandler = obj
	return obj
end
