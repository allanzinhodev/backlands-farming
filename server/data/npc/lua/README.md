# NPC Lua Organization

This folder is organized by NPC role. The NPC loader scans this folder recursively, so subfolders are safe.

## farming
- `seed_vendor.lua`: **Seed Vendor**, sells seeds, pots, watering cans and farm tools.
- `harvest_buyer.lua`: **Harvest Buyer**, buys wheat, flour, bread, fruit, vegetables, fish and mushrooms.

These NPCs use the existing TFS NPC library and current item IDs. Say `hi`, then `trade`.
Seeds currently grow ornamental plants in pots; wheat uses the existing scythe/decay cycle.
The starter world places both NPCs in the village square.

## bank
- `banker.lua`
- `Guild_Banker.lua`

## travel
- `Captain.lua`
- `merchant_traveler.lua`

## quests
- `The Oracle.lua`
- `Storyteller.lua`

## services
- `Alice.lua` (blessings)
- `The_Forgotten_King.lua` (promotion)
- `mark.lua` (addons)

## shops/buy
- `Deruno.lua`
- `Imbuement_Master.lua`
- `Lector.lua`
- `Obi.lua`
- `Perac.lua`
- `Ring_Seller.lua`
- `Riona.lua`
- `Tyoric.lua`

## shops/sell
- `Mad.lua`
- `Rashid.lua`

## shops/mixed
- `Dark Rodo.lua`
