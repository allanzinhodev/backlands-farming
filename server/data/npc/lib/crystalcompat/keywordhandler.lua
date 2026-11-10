-- CrystalServer compatibility wrapper for KeywordHandler
-- Reuses the real NpcSystem handler so legacy NPCs keep working unchanged.

CrystalKeywordHandler = CrystalKeywordHandler or {}
CrystalKeywordHandler.__index = CrystalKeywordHandler

function CrystalKeywordHandler:new(...)
	if _G.OriginalKeywordHandlerNew then
		return _G.OriginalKeywordHandlerNew(KeywordHandler, ...)
	end

	local obj = {}
	setmetatable(obj, CrystalKeywordHandler)
	return obj
end

-- Extension to support condition and action in the Keyword Node and Handler
if KeywordNode then
	function KeywordNode:new(keys, func, param, condition, action)
		local obj = {}
		obj.keywords = keys
		obj.callback = func
		obj.parameters = param
		obj.condition = condition
		obj.action = action
		obj.children = {}
		setmetatable(obj, self)
		self.__index = self
		return obj
	end

	function KeywordNode:processMessage(cid, message)
		if self.condition then
			local player = Player(cid)
			if player then
				if not self.condition(player) then
					return false
				end
			end
		end

		if self.action then
			local player = Player(cid)
			if player then
				self.action(player)
			end
		end

		return (not self.callback or
			       self.callback(cid, message, self.keywords, self.parameters, self))
	end

	function KeywordNode:addChildKeyword(keywords, callback, parameters, condition, action)
		local new = KeywordNode:new(keywords, callback, parameters, condition, action)
		return self:addChildKeywordNode(new)
	end
end

if KeywordHandler then
	function KeywordHandler:addKeyword(keys, callback, parameters, condition, action)
		return self:getRoot():addChildKeyword(keys, callback, parameters, condition, action)
	end
end
