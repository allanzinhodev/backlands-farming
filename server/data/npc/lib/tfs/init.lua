-- Default TFS NPC backend.
-- Loads classic NPC helpers, RevScript NPCs and the compatibility layer used
-- by the existing data/npc/lua scripts, without enabling Crystal overrides.

if _G.NpcSystemBackendLoaded then
	return
end

_G.NpcSystemBackendLoaded = "tfs"

dofile("data/npc/lib/npc.lua")
