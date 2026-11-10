local antiAdvertising = {}

antiAdvertising.blockedWords = {
    "ddns", "com", "br", "online", "org", "net", 
    "http", "https", "www", "sytes",
    "killermamonas", "normandierpg", "ilusion pex", "pysco",
    "aurera", "rubinot", "ilusion", "illusion", "kaldrox",
    "demolidores", "luxot", "rexia", "gunzodus", "auroria",
    "cyleria", "canob", "unline", "aiolosot", "oxygenot",
    "blacktalon", "noxiousot", "otmadness", "furiaot",
    "retrotibia", "netunia", "icewar", "evolunia", "natala",
    "karma", "arinar", "primot", "fast", "rezoria",
    "baiaksp", "brazzinum", "pbotwars", "amonot", "mazeot",
    "holiday", "redbaiak", "baiakworld", "nostalther",
    "baiakao", "taleon", "vantoria", "marlboro", "mythibia",
    "thornia", "slaynville", "necroxia", "taleonaura",
    "limbo", "baiakeria", "heroserv", "giveria", "oldlucera",
    "glabela", "underwar", "baiakeros", "middleearth",
    "drakonia", "spiderot", "valdraken", "vestia", "tibiara",
    "alastera", "kimeraot", "balrogot", "mexas", "antiga",
    "elderan", "modukot", "exordionlegacy", "jobot", "dura",
    "treasura", "valeriaot", "oasis", "falumirot",
    "vendettaots", "realots", "geniumot", "aqueleot",
    "vanyria", "dragot", "galanaxot", "armada", "cyntara",
    "zinxot", "alphaot", "arcananemesis", "arcananmsis", 
    "arcana nemesis", "script", "scripts", "tyr"
}

function antiAdvertising.normalizeText(text)
    if not text then return "" end
    text = text:lower()
    local accents = {
        ["á"] = "a", ["à"] = "a", ["ã"] = "a", ["â"] = "a", ["ä"] = "a",
        ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
        ["í"] = "i", ["ì"] = "i", ["î"] = "i", ["ï"] = "i",
        ["ó"] = "o", ["ò"] = "o", ["õ"] = "o", ["ô"] = "o", ["ö"] = "o",
        ["ú"] = "u", ["ù"] = "u", ["û"] = "u", ["ü"] = "u",
        ["ç"] = "c", ["ñ"] = "n"
    }
    for accent, normal in pairs(accents) do
        text = text:gsub(accent, normal)
    end
    return text
end

function antiAdvertising.checkText(text)
    if not text or text == "" then
        return false, nil
    end
    local normalizedText = antiAdvertising.normalizeText(text)
    for _, word in ipairs(antiAdvertising.blockedWords) do
        if normalizedText:find(word, 1, true) then
            return true, word
        end
    end
    return false, nil
end

-- Global function called by the C++ engine (Game::playerSay)
function checkMessage(text, isStaff)
    if isStaff then
        return false, ""
    end
    
    local hasBlockedWord, word = antiAdvertising.checkText(text)
    
    if hasBlockedWord then
        return true, "[Mensaje bloqueado por contener publicidad]."
    end
    
    return false, ""
end

return antiAdvertising
