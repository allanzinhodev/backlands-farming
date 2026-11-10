local talkaction = TalkAction("/y")

function talkaction.onSay(player, words, param)
    local split = param:split(" ")

    local text = split[1]
    local color = tonumber(split[2])

    if not text then
        player:sendCancelMessage("Use: /y text color")
        return false
    end

    if not color or color < 1 or color > 255 then
        color = TEXTCOLOR_WHITE
    end

    local position = player:getPosition()

    Game.sendAnimatedText(text, position, color)

    return false
end

talkaction:separator(" ")
talkaction:access(true)
talkaction:register()