# Crystal NPC Lua Organization

This folder uses the same category layout as `data/npc/lua`.

## Folders
- `bank`
- `travel`
- `quests`
- `services`
- `shops/buy`
- `shops/sell`
- `shops/mixed`

## Notes
- Scripts were reorganized from `data/npc/npc_Crystal_Server_15x`.
- NPC script loading is recursive, so subfolders are supported.
- If `npcSystem = "crystal"`, scripts are loaded from `data/npc/crystalserver` first.
