local tokenTalkaction = TalkAction("!token")
function tokenTalkaction.onSay(player, words, param)
    param = param:trim():lower()

    if player:isTokenLocked() then
        if param == "" then
             player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "[TOKEN]: You are LOCKED! Type !token <password> to unlock.")
             return false
        end
        
        -- Try to unlock with the provided param as token


        if player:unlockWithToken(param) then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[TOKEN]: You have been UNLOCKED successfully.")
            player:popupFYI("Token Unlocked!\n\nYou can now move freely, but items are still protected (if enabled).\nTo disable item protection: !token off, <TOKEN>")
        else
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "[TOKEN]: Incorrect token! You remain LOCKED.")
        end
        return false
    end
    
    if param == "" then
        local status = player:isTokenProtected() and "On" or "Off"
        
        local msg = "-------------------- TOKEN PROTECT ITEMS --------------------\n\n"
        msg = msg .. "Status: " .. status .. "\n\n"
        msg = msg .. "The token system exists to protect server players.\n"
        msg = msg .. "When 'On', the system prevents character items from being moved.\n"
        msg = msg .. "This helps protect against account hacking.\n\n"
        
        msg = msg .. "Main commands:\n"
        msg = msg .. "!token on (turn validation on)\n"
        msg = msg .. "!token off, YOUR-TOKEN (turn validation off)\n"
        msg = msg .. "!token set, YOUR-TOKEN (set a token)\n\n"
        
        msg = msg .. "Rules:\n"
        msg = msg .. "It is only possible to set a token if protection is OFF.\n"
        msg = msg .. "It is only possible to disable protection knowing the token.\n"
        msg = msg .. "The char will not be able to throw items out of the BP.\n"
        msg = msg .. "Move from ground to BP is allowed.\n"
        msg = msg .. "Moving items inside BP is BLOCKED to ensure safety.\n"
        msg = msg .. "You can play normally (hunt, use spells) if unlocked with !token <pass>.\n"
        msg = msg .. "Will serve as good protection when lending chars and avoiding hacks!"
        
        player:popupFYI(msg)
        return false
    end
    
    if param == "on" then
        if player:isTokenProtected() then
            player:sendCancelMessage("Token protection is already enabled.")
            return false
        end
        
        local hash = player:getTokenHash()
        if not hash or hash == "" then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "[TOKEN]: ERROR, type !token set, SOME_TOKEN | you need to set a token to enable!\nRemember to save this token.")
            return false
        end
        
        player:setTokenProtected(true)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[TOKEN]: Character protection enabled, you can no longer move items! (Use !token <pass> to unlock movement)")
        return false
    end
    
    local split = param:split(",")
    local command = split[1]:trim():lower()
    local token = split[2] and split[2]:trim() or ""
    
    if command == "off" then
        if not player:isTokenProtected() then
            player:sendCancelMessage("Token protection is already disabled.")
            return false
        end
        
        if token == "" then
            player:sendCancelMessage("You must provide your token! Use: !token off, <YOUR_TOKEN>")
            return false
        end
        
        local storedHash = player:getTokenHash()
        local inputHash = hashToken(token)
        
        if storedHash ~= inputHash then
            player:sendCancelMessage("Invalid token! Protection NOT disabled.")
            return false
        end
        
        player:setTokenProtected(false)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Token] Protection DISABLED. You can now move items freely.")
        return false
    end
    
    if command == "set" then
        if player:isTokenProtected() then
            player:sendCancelMessage("You must disable protection first to change your token! Use: !token off, <CURRENT_TOKEN>")
            return false
        end
        
        if token == "" then
            player:sendCancelMessage("You must provide a token! Use: !token set, <YOUR_TOKEN>")
            return false
        end
        
        if #token < 8 then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "[TOKEN]: ERROR, Enter a valid token with at LEAST 8 characters!")
            return false
        end
        
        if #token > 32 then
            player:sendCancelMessage("Token must be at most 32 characters long!")
            return false
        end
        
        local hash = hashToken(token)
        player:setTokenHash(hash)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[TOKEN]: You set a security token, now type !token on \nSave your token well: %s", token))
        return false
    end
    
    player:sendCancelMessage("Unknown command. Use !token for help.")
    return false
end

function hashToken(token)
    local hash = 0
    for i = 1, #token do
        local char = string.byte(token, i)
        hash = ((hash * 31) + char) % 4294967296
    end
    return string.format("%08x", hash)
end

function isTokenException(itemId)
    if not tokenProtectionExceptions then
        return false
    end
    for _, id in ipairs(tokenProtectionExceptions) do
        if id == itemId then
            return true
        end
    end
    return false
end
tokenTalkaction:separator(" ")
tokenTalkaction:register()
