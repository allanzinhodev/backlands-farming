-- Imbuement Master – RevScript (NpcsHandler)
-- Converted from: Imbuement_Master.xml + imbuement_master.lua
local npcType = Game.createNpcType("Imbuement Master")
npcType:outfit({lookType = 130, lookHead = 95, lookBody = 116, lookLegs = 121, lookFeet = 115, lookAddons = 3})
npcType:health(100)
npcType:maxHealth(100)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:spawnRadius(3)
npcType:defaultBehavior()

local handler = NpcsHandler("Imbuement Master")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|!"})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Welcome, |PLAYERNAME|! I sell {imbuement} {scrolls}, the {etcher} tool, and all imbuement materials. Say {trade} to see my offers!"})

greet:keyword({"scrolls", "offer", "stuff", "wares", "imbuement", "imbuements"}):respond("I sell {intricate} and {powerful} imbuement scrolls, plus the {etcher} tool. Say {trade} to see my full catalog!")
greet:keyword({"etcher"}):respond("The etcher is needed to apply scrolls on a workbench. Place your equipment and scrolls on the workbench, then use the etcher on it.")
greet:keyword({"workbench"}):respond("You need a workbench to apply imbuements. Place your equipment and the scrolls inside the workbench, then use the etcher on it.")
greet:keyword({"intricate"}):respond("Intricate scrolls are tier 2 imbuements. They cost 60,000 gold to apply. Say {trade} to see them!")
greet:keyword({"powerful"}):respond("Powerful scrolls are tier 3 imbuements, the strongest! They cost 250,000 gold to apply. Say {trade} to see them!")

local trade = greet:keyword({"trade"})
trade:respond("Here is what I offer!")
trade:shop(1)

------------------------------------------------------------------------
-- Shop 1
------------------------------------------------------------------------
local shop = NpcShop("Imbuement Master", 1)

-- tool
shop:addItem(51443, 5000, 0)    -- etcher

-- intricate scrolls (tier 2)
shop:addItem(51724, 15000, 0)   -- intricate bash scroll
shop:addItem(51725, 15000, 0)   -- intricate blockade scroll
shop:addItem(51726, 15000, 0)   -- intricate chop scroll
shop:addItem(51731, 15000, 0)   -- intricate epiphany scroll
shop:addItem(51735, 15000, 0)   -- intricate precision scroll
shop:addItem(51736, 15000, 0)   -- intricate punch scroll
shop:addItem(51740, 15000, 0)   -- intricate slash scroll
shop:addItem(51730, 15000, 0)   -- intricate electrify scroll
shop:addItem(51733, 15000, 0)   -- intricate frost scroll
shop:addItem(51738, 15000, 0)   -- intricate reap scroll
shop:addItem(51739, 15000, 0)   -- intricate scorch scroll
shop:addItem(51745, 15000, 0)   -- intricate venom scroll
shop:addItem(51727, 15000, 0)   -- intricate cloud fabric scroll
shop:addItem(51728, 15000, 0)   -- intricate demon presence scroll
shop:addItem(51729, 15000, 0)   -- intricate dragon hide scroll
shop:addItem(51734, 15000, 0)   -- intricate lich shroud scroll
shop:addItem(51737, 15000, 0)   -- intricate quara scale scroll
shop:addItem(51741, 15000, 0)   -- intricate snake skin scroll
shop:addItem(51742, 15000, 0)   -- intricate strike scroll
shop:addItem(51744, 15000, 0)   -- intricate vampirism scroll
shop:addItem(51747, 15000, 0)   -- intricate void scroll
shop:addItem(51743, 15000, 0)   -- intricate swiftness scroll
shop:addItem(51732, 15000, 0)   -- intricate featherweight scroll
shop:addItem(51746, 15000, 0)   -- intricate vibrancy scroll

-- powerful scrolls (tier 3)
shop:addItem(51444, 50000, 0)   -- powerful bash scroll
shop:addItem(51445, 50000, 0)   -- powerful blockade scroll
shop:addItem(51446, 50000, 0)   -- powerful chop scroll
shop:addItem(51451, 50000, 0)   -- powerful epiphany scroll
shop:addItem(51455, 50000, 0)   -- powerful precision scroll
shop:addItem(51456, 50000, 0)   -- powerful punch scroll
shop:addItem(51460, 50000, 0)   -- powerful slash scroll
shop:addItem(51450, 50000, 0)   -- powerful electrify scroll
shop:addItem(51453, 50000, 0)   -- powerful frost scroll
shop:addItem(51458, 50000, 0)   -- powerful reap scroll
shop:addItem(51459, 50000, 0)   -- powerful scorch scroll
shop:addItem(51465, 50000, 0)   -- powerful venom scroll
shop:addItem(51447, 50000, 0)   -- powerful cloud fabric scroll
shop:addItem(51448, 50000, 0)   -- powerful demon presence scroll
shop:addItem(51449, 50000, 0)   -- powerful dragon hide scroll
shop:addItem(51454, 50000, 0)   -- powerful lich shroud scroll
shop:addItem(51457, 50000, 0)   -- powerful quara scale scroll
shop:addItem(51461, 50000, 0)   -- powerful snake skin scroll
shop:addItem(51462, 50000, 0)   -- powerful strike scroll
shop:addItem(51464, 50000, 0)   -- powerful vampirism scroll
shop:addItem(51467, 50000, 0)   -- powerful void scroll
shop:addItem(51463, 50000, 0)   -- powerful swiftness scroll
shop:addItem(51452, 50000, 0)   -- powerful featherweight scroll
shop:addItem(51466, 50000, 0)   -- powerful vibrancy scroll

-- materials: critical
shop:addItem(11444,   60, 0)    -- protective charm
shop:addItem(10311,  400, 0)    -- sabretooth
shop:addItem(22728, 1100, 0)    -- vexclaw talon
-- life leech
shop:addItem(9685,   275, 0)    -- vampire teeth
shop:addItem(9633,   100, 0)    -- bloody pincers
shop:addItem(9663,   420, 0)    -- piece of dead brain
-- mana leech
shop:addItem(11492,   66, 0)    -- rope belt
shop:addItem(20200,  390, 0)    -- silencer claws
shop:addItem(22730, 1200, 0)    -- some grimeleech wings
-- elemental damage (death)
shop:addItem(11484,   25, 0)    -- pile of grave earth
shop:addItem(9647,    80, 0)    -- demonic skeletal hand
shop:addItem(10420,  250, 0)    -- petrified scream
-- elemental damage (earth)
shop:addItem(9686,    20, 0)    -- swamp grass
shop:addItem(9640,    50, 0)    -- poisonous slime
shop:addItem(21194,  160, 0)    -- slime heart
-- elemental damage (energy)
shop:addItem(18993,   70, 0)    -- rorc feather
shop:addItem(21975,  350, 0)    -- peacock feather fan
shop:addItem(23508,  270, 0)    -- energy vein
-- elemental damage (fire)
shop:addItem(9636,   375, 0)    -- fiery heart
shop:addItem(5920,   100, 0)    -- green dragon scale
shop:addItem(5954,  1000, 0)    -- demon horn
-- elemental damage (ice)
shop:addItem(9661,   280, 0)    -- frosty heart
shop:addItem(21801,  260, 0)    -- seacrest hair
shop:addItem(9650,    30, 0)    -- polar bear paw
-- elemental protection (holy)
shop:addItem(11466,   30, 0)    -- flask of embalming fluid
shop:addItem(22007,   70, 0)    -- gloom wolf fur
shop:addItem(9660,   700, 0)    -- mystical hourglass
-- elemental protection (earth)
shop:addItem(17823,   30, 0)    -- piece of swampling wood
shop:addItem(9694,   400, 0)    -- snake skin
shop:addItem(11702,  380, 0)    -- brimstone fangs
-- elemental protection (energy)
shop:addItem(9644,   265, 0)    -- wyvern talisman
shop:addItem(14079,  210, 0)    -- crawler head plating
shop:addItem(9665,   400, 0)    -- wyrm scale
-- elemental protection (fire)
shop:addItem(5877,   100, 0)    -- green dragon leather
shop:addItem(16131,  610, 0)    -- blazing bone
shop:addItem(11658,  550, 0)    -- draken sulphur
-- elemental protection (death)
shop:addItem(9639,   150, 0)    -- cultish robe
shop:addItem(9638,   280, 0)    -- cultish mask
shop:addItem(10304,  475, 0)    -- hellspawn tail
-- elemental protection (ice)
shop:addItem(10295,   20, 0)    -- winter wolf fur
shop:addItem(10307,  150, 0)    -- thick fur
shop:addItem(14012,  180, 0)    -- deepling warts
-- skill boosts (club)
shop:addItem(10196,  150, 0)    -- orc tooth
shop:addItem(11447,  290, 0)    -- battle stone
shop:addItem(21200,  140, 0)    -- moohtant horn
-- skill boosts (sword)
shop:addItem(9657,    55, 0)    -- cyclops toe
shop:addItem(22189,  210, 0)    -- ogre nose ring
shop:addItem(10405,  200, 0)    -- warmaster's wristguards
-- skill boosts (distance)
shop:addItem(11464,   50, 0)    -- elven scouting glass
shop:addItem(18994,  115, 0)    -- elven hoof
shop:addItem(10298,  320, 0)    -- metal spike
-- skill boosts (axe)
shop:addItem(9691,    60, 0)    -- lion's mane
shop:addItem(21202,  110, 0)    -- mooh'tah shell
shop:addItem(9654,   460, 0)    -- war crystal
-- skill boosts (magic)
shop:addItem(9635,    45, 0)    -- elvish talisman
shop:addItem(11452,   35, 0)    -- broken shamanic staff
shop:addItem(10309,  600, 0)    -- strand of medusa hair
-- skill boosts (shielding)
shop:addItem(9641,    45, 0)    -- piece of scarab shell
shop:addItem(11703,  210, 0)    -- brimstone shell
shop:addItem(20199,  400, 0)    -- frazzle skin
-- speed
shop:addItem(17458,   20, 0)    -- damselfly wing
shop:addItem(10302,   45, 0)    -- compass
shop:addItem(14081,  190, 0)    -- waspoid wing
-- capacity
shop:addItem(25694,  200, 0)    -- fairy wings
shop:addItem(25702,  500, 0)    -- little bowl of myrrh
shop:addItem(20205,  650, 0)    -- goosebump leather
-- paralysis protection
shop:addItem(22053,  175, 0)    -- wereboar hooves
shop:addItem(23507,  400, 0)    -- crystallized anger
shop:addItem(28567, 1100, 0)    -- quill
