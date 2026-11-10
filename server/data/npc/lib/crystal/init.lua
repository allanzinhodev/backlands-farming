-- Crystal-compatible NPC backend.
-- This keeps the existing compatibility bundle isolated behind npcSystem = "crystal".

if _G.NpcSystemBackendLoaded then
	return
end

_G.NpcSystemBackendLoaded = "crystal"

dofile("data/npc/lib/npc.lua")
dofile("data/npc/lib/crystalcompat/init.lua")
