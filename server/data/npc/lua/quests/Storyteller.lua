local npcType = Game.createNpcType("Storyteller")
npcType:outfit({lookType = 128, lookHead = 78, lookBody = 76, lookLegs = 78, lookFeet = 76})
npcType:emblem(1)
npcType:spawnRadius(2)
npcType:walkInterval(5000)
npcType:walkSpeed(80)
npcType:defaultBehavior()

local handler = NpcsHandler(npcType)
local greet = handler:keyword(handler.greetWords)
greet:setGreetResponse("Hello |PLAYERNAME|! Would you like to hear a {story}?")

local story = greet:keyword("story")

function story:callback(npc, player, message, handler)
    local talk = NpcTalkQueue(npc)
    local messages = {
        "This is part 1...",
        "And here we have part 2.",
        "What if we made this part 3.",
        "Then this will be 4 after 3.",
        "And the last one is 5."
    }
    talk:addToQueue(player, "Sit back and enjoy the story.", 0)
    for i, message in ipairs(messages) do
        talk:addToQueue(player, message, i * 2000)
    end
    return true
end

local decline = greet:keyword("no")
decline:respond("Alright then, maybe next time.")
