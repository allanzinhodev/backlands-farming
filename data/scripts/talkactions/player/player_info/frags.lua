local frags = TalkAction("!frags")

local skullNames = {
    [SKULL_NONE] = "No Skull",
    [SKULL_YELLOW] = "Yellow Skull",
    [SKULL_GREEN] = "Green Skull",
    [SKULL_WHITE] = "White Skull",
    [SKULL_RED] = "Red Skull",
    [SKULL_BLACK] = "Black Skull"
}

local function formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))

    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400

    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600

    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60

    local parts = {}
    if days > 0 then
        parts[#parts + 1] = string.format("%dd", days)
    end

    if hours > 0 or days > 0 then
        parts[#parts + 1] = string.format("%dh", hours)
    end

    if minutes > 0 or hours > 0 or days > 0 then
        parts[#parts + 1] = string.format("%dm", minutes)
    end

    if #parts == 0 then
        parts[#parts + 1] = string.format("%ds", seconds)
    end

    return table.concat(parts, " ")
end

local function getActiveFrags(skullTime, fragTime)
    if fragTime <= 0 or skullTime <= 0 then
        return 0
    end

    return math.ceil(skullTime / fragTime)
end

local function getNextFragTime(skullTime, fragTime, activeFrags)
    if fragTime <= 0 or activeFrags <= 0 then
        return 0
    end

    return skullTime - ((activeFrags - 1) * fragTime)
end

local function getSkullDisplay(skull, activeFrags)
    local name = skullNames[skull] or "Unknown"
    if skull == SKULL_NONE and activeFrags > 0 then
        return name .. " (frags active)"
    end

    return name
end

local function getKillsRemainingText(limit, activeFrags)
    if limit <= 0 then
        return "disabled"
    end

    local remaining = math.max(0, limit - activeFrags)
    return remaining == 1 and "1 more" or string.format("%d more", remaining)
end

function frags.onSay(player, words, param)
    local skull = player:getSkull()
    local skullTime = math.max(0, player:getSkullTime() or 0)
    local fragTime = configManager.getNumber(configKeys.FRAG_TIME)

    if skull == SKULL_NONE and skullTime <= 0 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You do not have any active skull or frags.")
        return false
    end

    local activeFrags = getActiveFrags(skullTime, fragTime)
    local nextFragTime = getNextFragTime(skullTime, fragTime, activeFrags)
    local fragTimerText = activeFrags > 0 and formatDuration(skullTime) or "none"
    local nextFragText = activeFrags > 0 and formatDuration(nextFragTime) or "none"

    local message = {
        "-- Skull Status ------------------",
        string.format(" Current skull: %s", getSkullDisplay(skull, activeFrags)),
        string.format(" Frag timer: %s", fragTimerText),
        string.format(" Active frags: %d", activeFrags),
        string.format(" Next frag expires in: %s", nextFragText),
        string.format(" Kills to Red Skull: %s", getKillsRemainingText(configManager.getNumber(configKeys.KILLS_TO_RED), activeFrags)),
        string.format(" Kills to Black Skull: %s", getKillsRemainingText(configManager.getNumber(configKeys.KILLS_TO_BLACK), activeFrags)),
        "-----------------------------------"
    }

    player:popupFYI(table.concat(message, "\n"))
    return false
end

frags:register()
