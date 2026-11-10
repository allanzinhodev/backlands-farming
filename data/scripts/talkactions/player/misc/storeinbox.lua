local storeInbox = TalkAction("!storeinbox", "!sinbox", "!inbox")
function storeInbox.onSay(player, words, param)
    local inbox = player:getStoreInbox()
    if not inbox then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Your store inbox is empty.")
        return true
    end

    local cid = player:getContainerID(inbox)
    if cid ~= -1 then
        player:closeContainer(cid)
    end

    player:openContainer(inbox)
    return true
end
storeInbox:separator(" ")
storeInbox:register()
