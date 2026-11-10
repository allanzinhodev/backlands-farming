local npcType = Game.createNpcType("Captain")
npcType:outfit({lookType = 151, lookHead = 78, lookBody = 115, lookLegs = 85, lookFeet = 114, lookAddons = 2})
npcType:spawnRadius(4)
npcType:walkInterval(2000)
npcType:walkSpeed(100)
npcType:defaultBehavior()

local handler = NpcsHandler("Captain")
handler:setGreetKeywords({"hi", "hello"})
handler:setFarewellKeywords({"bye", "farewell"})
handler:setFarewellResponse({"Farewell, |PLAYERNAME|."})

local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse({"Welcome on board, |PLAYERNAME|."})
greet:keyword("captain"):respond("I am the captain of this sailing-ship.")
greet:keyword("trip"):respond("Where do you want to go? To Classic City, Timberport, Sandstone or Ice?")

local destinations = {
    classiccity  = { position = Position(1014, 926, 6), money = 100, premium = true },
    timberport   = { position = Position(733, 973, 6), money = 120, premium = true },
    sandstone    = { position = Position(1022, 1084, 6), money = 160, premium = true },
    ice          = { position = Position(1159, 902, 6), money = 150, premium = true }
}
handler:travelTo(destinations)