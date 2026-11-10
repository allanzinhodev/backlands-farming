local npcType = Game.createNpcType("The Oracle")
npcType:outfit({lookType = 1448})
npcType:spawnRadius(2)
npcType:walkInterval(10000)
npcType:walkSpeed(50)
npcType:defaultBehavior()

-- Storage Keys
local STORAGE_VISITS         = PlayerStorageKeys.oracleVisits
local STORAGE_TRIAL_WISDOM   = PlayerStorageKeys.oracleTrialWisdom
local STORAGE_TRIAL_COURAGE  = PlayerStorageKeys.oracleTrialCourage
local STORAGE_TRIAL_PATIENCE = PlayerStorageKeys.oracleTrialPatience
local STORAGE_RIDDLE_ID      = PlayerStorageKeys.oracleRiddleId
local STORAGE_REWARD_GIVEN   = PlayerStorageKeys.oracleRewardGiven

local function ordinal(n)
    if n % 100 >= 11 and n % 100 <= 13 then return n .. "th" end
    local s = n % 10
    if s == 1 then return n .. "st"
    elseif s == 2 then return n .. "nd"
    elseif s == 3 then return n .. "rd"
    else return n .. "th" end
end

local NAV_KEYWORDS = {"lore", "trial", "prophecy", "reward", "courage", "patience", "wisdom", "hi", "hello", "bye", "farewell"}
local function isNavKeyword(message)
    local lower = string.lower(message)
    for _, word in ipairs(NAV_KEYWORDS) do
        if lower == word then return true end
    end
    return false
end

local RIDDLES = {
    { q = "I speak without a mouth and hear without ears. I have no body, but I come alive with wind. What am I?",                        a = "echo"      },
    { q = "The more you take, the more you leave behind. What am I?",                                                                     a = "footsteps" },
    { q = "I have cities, but no houses. Mountains, but no trees. Water, but no fish. Roads, but no travelers. What am I?",               a = "map"       },
    { q = "I am always in front of you, yet can never be seen. What am I?",                                                               a = "future"    },
    { q = "What has hands but cannot clap?",                                                                                              a = "clock"     },
    { q = "I am taken from a mine and shut up in a wooden case, from which I am never released. Yet I am used by almost all. What am I?", a = "pencil"    },
    { q = "I have a head and a tail, but no body. What am I?",                                                                            a = "coin"      },
    { q = "The more you have of it, the less you see. What am I?",                                                                        a = "darkness"  },
    { q = "I get stronger the more you break me. What am I?",                                                                             a = "habit"     },
    { q = "What can travel around the world while staying in a corner?",                                                                  a = "stamp"     },
    { q = "I have branches, but no fruit, trunk or leaves. What am I?",                                                                   a = "bank"      },
    { q = "What has to be broken before you can use it?",                                                                                 a = "egg"       },
}

local VOCATION_LINES = {
    [0] = "Your path is unwritten. No vocation chains your destiny - this is both a curse and a gift.",
    [1] = "The arcane flame dances in your veins, Sorcerer. Harness it, lest it consume you.",
    [2] = "The roots of the earth whisper your name, Druid. Nature herself watches your every step.",
    [3] = "The gods have marked your shield, Paladin. Your courage will be tested in ways unseen.",
    [4] = "Your blade is your tongue and your armor is your soul, Knight. The battlefield knows your footsteps well.",
    [5] = "The elder flame you carry burns with ancient wisdom, Master Sorcerer. Few have walked this far.",
    [6] = "You are one with the forest's oldest roots, Elder Druid. Your wisdom rivals the ancient trees.",
    [7] = "Heaven's aim guides your hand, Royal Paladin. Your arrows find truth even in darkness.",
    [8] = "Legends are written in iron and blood, Elite Knight. Your story is already being told.",
}

local function getCompletedTrials(player)
    local wisdom   = player:getStorageValue(STORAGE_TRIAL_WISDOM)
    local courage  = player:getStorageValue(STORAGE_TRIAL_COURAGE)
    local patience = player:getStorageValue(STORAGE_TRIAL_PATIENCE)
    local w = (wisdom   and wisdom   > 0) and 1 or 0
    local c = (courage  and courage  > 0) and 1 or 0
    local p = (patience and patience > 0) and 1 or 0
    return w + c + p, w == 1, c == 1, p == 1
end

-- ============================================================
-- GREET
-- ============================================================
local handler = NpcsHandler(npcType)
local greet = handler:keyword(handler.greetWords)

function greet:callback(npc, player, message, handler)
    local visits = player:getStorageValue(STORAGE_VISITS)
    if not visits or visits < 0 then visits = 0 end
    player:setStorageValue(STORAGE_VISITS, visits + 1)

    local total, w, c, p = getCompletedTrials(player)

    if visits == 0 then
        return true, "...A new soul drifts toward my flame. I am the Oracle, keeper of truths the world has forgotten. Seek a {prophecy}, face a {trial}, or uncover the ancient {lore}, |PLAYERNAME|."
    elseif total == 3 then
        local rewardGiven = player:getStorageValue(STORAGE_REWARD_GIVEN)
        if rewardGiven and rewardGiven > 0 then
            return true, "The Oracle remembers all, champion |PLAYERNAME|. You have walked this path " .. visits .. " times. The {prophecy} and {lore} are always open to you."
        end
        return true, "The champion returns! All three trials conquered, |PLAYERNAME|. The Oracle is ready to grant your {reward}. Or seek a {prophecy} or {lore}."
    else
        local missing = {}
        if not w then table.insert(missing, "{wisdom}")   end
        if not c then table.insert(missing, "{courage}")  end
        if not p then table.insert(missing, "{patience}") end
        return true, "The Oracle sees you again, |PLAYERNAME|. You return for the " .. ordinal(visits) .. " time. " .. total .. " of 3 trials complete. Still missing: " .. table.concat(missing, ", ") .. ". Say {trial} to choose one, seek a {prophecy}, or read the {lore}."
    end
end

-- ============================================================
-- PROPHECY
-- ============================================================
local prophecy = greet:keyword("prophecy")

function prophecy:callback(npc, player, message, handler)
    local vocId   = player:getVocation():getId()
    local vocLine = VOCATION_LINES[vocId] or VOCATION_LINES[0]
    local level   = player:getLevel()
    local hour    = tonumber(os.date("%H"))
    local name    = player:getName()

    local timeMsg
    if     hour < 6  then timeMsg = "The dead of night surrounds you. Shadows reveal what daylight hides."
    elseif hour < 12 then timeMsg = "Dawn breaks. What begins now carries great weight."
    elseif hour < 18 then timeMsg = "High sun watches over you. There is no hiding your true self today."
    else                   timeMsg = "Dusk settles. Choices made now echo into tomorrow."
    end

    local levelMsg
    if     level < 50  then levelMsg = "You are young, and the world is vast before you. Do not rush."
    elseif level < 150 then levelMsg = "You have proven yourself, yet the greatest trials still loom ahead."
    elseif level < 300 then levelMsg = "Few reach your experience. Yet power alone does not bring wisdom."
    else                    levelMsg = "A legend walks among mortals. The Oracle bows to very few."
    end

    local talk = NpcTalkQueue(npc)
    talk:addToQueue(player, "*closes eyes slowly... the air grows cold*",                  0)
    talk:addToQueue(player, "The threads of fate weave around you, " .. name .. "...",  2500)
    talk:addToQueue(player, vocLine,                                                     5000)
    talk:addToQueue(player, levelMsg,                                                    8000)
    talk:addToQueue(player, timeMsg,                                                    11000)
    talk:addToQueue(player, "...The Oracle has spoken. Guard what you have learned. You may speak of a trial, the lore, or your reward.", 14000)
    return true
end

-- ============================================================
-- TRIAL MENU
-- ============================================================
local trial = greet:keyword("trial")

function trial:callback(npc, player, message, handler)
    local total, w, c, p = getCompletedTrials(player)

    if total == 3 then
        return true, "You have already conquered all three trials, champion. Speak of your {reward}."
    end

    local available, completed = {}, {}
    if not w then table.insert(available, "{wisdom}")   else table.insert(completed, "Wisdom")   end
    if not c then table.insert(available, "{courage}")  else table.insert(completed, "Courage")  end
    if not p then table.insert(available, "{patience}") else table.insert(completed, "Patience") end

    local msg = "Three trials define a true champion of the Oracle. "
    if #completed > 0 then
        msg = msg .. "Conquered: " .. table.concat(completed, ", ") .. ". "
    end
    msg = msg .. "Remaining: " .. table.concat(available, ", ") .. ". Choose your next trial."
    return true, msg
end

-- ============================================================
-- TRIAL I: WISDOM (sob trial)
-- ============================================================
local wisdom = trial:keyword("wisdom")

function wisdom:callback(npc, player, message, handler)
    local wisdomStorage = player:getStorageValue(STORAGE_TRIAL_WISDOM)
    if wisdomStorage and wisdomStorage > 0 then
        return true, "Your wisdom is already proven. The Oracle does not test the same soul twice on the same trial."
    end
    local riddleId = math.random(1, #RIDDLES)
    player:setStorageValue(STORAGE_RIDDLE_ID, riddleId)
    return true, "The Trial of Wisdom. Answer correctly and prove your mind is a worthy vessel: " .. RIDDLES[riddleId].q
end

local wisdomAnswer = wisdom:onAnswer()

function wisdomAnswer:callback(npc, player, message, handler)
    if isNavKeyword(message) then return false end

    local riddleId = player:getStorageValue(STORAGE_RIDDLE_ID)
    if not riddleId or riddleId < 1 then
        return false, "Speak the word {wisdom} to begin the trial first."
    end

    local riddle = RIDDLES[riddleId]
    if string.lower(string.gsub(message, "%s+", "")) == riddle.a then
        player:setStorageValue(STORAGE_TRIAL_WISDOM, 1)
        player:setStorageValue(STORAGE_RIDDLE_ID, -1)
        local total = getCompletedTrials(player)
        if total == 3 then
            return true, "...Correct. Remarkably so. The Trial of Wisdom is complete. All three trials conquered - speak of your {reward}, champion."
        end
        return true, "...Correct. The Oracle is impressed. The Trial of Wisdom is complete. The remaining trials of {courage} and {patience} still await."
    end

    return false, "Incorrect. The answer escapes you. Breathe. Think. Speak {wisdom} again if you wish a new riddle, or try once more."
end

-- ============================================================
-- TRIAL II: COURAGE (sob trial)
-- ============================================================
local courage = trial:keyword("courage")

function courage:callback(npc, player, message, handler)
    local courageStorage = player:getStorageValue(STORAGE_TRIAL_COURAGE)
    if courageStorage and courageStorage > 0 then
        return true, "Your courage is already proven. The Oracle does not retest those who have stared into the void."
    end
    return true, "The Trial of Courage. I will show you something that has broken lesser souls. There is no undoing it. Do you {accept} or {refuse}?"
end

local courageAccept = courage:keyword("accept")

function courageAccept:callback(npc, player, message, handler)
    local name = player:getName()
    local talk = NpcTalkQueue(npc)
    talk:addToQueue(player, "Very well. Look into the Oracle's flame...",          0)
    talk:addToQueue(player, "You see your greatest fear.",                        2500)
    talk:addToQueue(player, "...",                                                5000)
    talk:addToQueue(player, "...",                                                6500)
    talk:addToQueue(player, "The void stares back at you.",                       8000)
    talk:addToQueue(player, "And yet... you did not look away.",                 10500)
    talk:addToQueue(player, "The Trial of Courage is complete, " .. name .. ". Not all who stand here can say the same.", 13000)
    player:setStorageValue(STORAGE_TRIAL_COURAGE, 1)
    local total = getCompletedTrials(player)
    if total == 3 then
        talk:addToQueue(player, "All three trials are now complete. When you are ready, speak of your reward.", 16000)
    end
    return true
end

local courageRefuse = courage:keyword("refuse")
courageRefuse:respond("Wisdom in knowing one's limits. Return when your heart is ready. Speak {courage} again when the time comes.")

-- ============================================================
-- TRIAL III: PATIENCE (sob trial)
-- ============================================================
local patience = trial:keyword("patience")

function patience:callback(npc, player, message, handler)
    local patienceStorage = player:getStorageValue(STORAGE_TRIAL_PATIENCE)
    if patienceStorage and patienceStorage > 0 then
        return true, "Your patience is already proven. The Oracle remembers your stillness."
    end
    return true, "The Trial of Patience. It appears simple - and that is the trap. You must echo my words exactly, in order. Not one letter wrong. Begin by saying: {I am ready}."
end

local pReady = patience:keyword("i am ready")
pReady:respond("Good. Your focus holds. Now say: {the oracle sees all}.")

local pSees = pReady:keyword("the oracle sees all")
pSees:respond("The flame flickers approvingly. Continue: {time is the greatest teacher}.")

local pTime = pSees:keyword("time is the greatest teacher")
pTime:respond("You are close. One final phrase remains - speak it true: {I have earned my wisdom}.")

local pEarned = pTime:keyword("i have earned my wisdom")

function pEarned:callback(npc, player, message, handler)
    local patienceStorage = player:getStorageValue(STORAGE_TRIAL_PATIENCE)
    if patienceStorage and patienceStorage > 0 then
        return true, "This trial is already behind you."
    end
    player:setStorageValue(STORAGE_TRIAL_PATIENCE, 1)
    local total = getCompletedTrials(player)
    if total == 3 then
        return true, "Patience perfected. The Oracle rarely witnesses such composure. All three trials are complete - claim your {reward}, champion."
    end
    return true, "Patience perfected. The Trial of Patience is complete. The other trials of {wisdom} and {courage} still await your conquest."
end

-- ============================================================
-- SHORTCUTS sob greet (com filhos completos)
-- ============================================================

-- Wisdom shortcut
local wisdomShortcut = greet:keyword("wisdom")
function wisdomShortcut:callback(npc, player, message, handler)
    return wisdom:callback(npc, player, message, handler)
end
local wisdomShortcutAnswer = wisdomShortcut:onAnswer()
function wisdomShortcutAnswer:callback(npc, player, message, handler)
    return wisdomAnswer:callback(npc, player, message, handler)
end

-- Courage shortcut (com accept e refuse)
local courageShortcut = greet:keyword("courage")
function courageShortcut:callback(npc, player, message, handler)
    return courage:callback(npc, player, message, handler)
end
local courageShortcutAccept = courageShortcut:keyword("accept")
function courageShortcutAccept:callback(npc, player, message, handler)
    return courageAccept:callback(npc, player, message, handler)
end
local courageShortcutRefuse = courageShortcut:keyword("refuse")
function courageShortcutRefuse:callback(npc, player, message, handler)
    return courageRefuse:callback(npc, player, message, handler)
end

-- Patience shortcut (com chain completa)
local patienceShortcut = greet:keyword("patience")
function patienceShortcut:callback(npc, player, message, handler)
    return patience:callback(npc, player, message, handler)
end
local psReady = patienceShortcut:keyword("i am ready")
psReady:respond("Good. Your focus holds. Now say: {the oracle sees all}.")
local psSees = psReady:keyword("the oracle sees all")
psSees:respond("The flame flickers approvingly. Continue: {time is the greatest teacher}.")
local psTime = psSees:keyword("time is the greatest teacher")
psTime:respond("You are close. One final phrase remains - speak it true: {I have earned my wisdom}.")
local psEarned = psTime:keyword("i have earned my wisdom")
function psEarned:callback(npc, player, message, handler)
    return pEarned:callback(npc, player, message, handler)
end

-- ============================================================
-- LORE
-- ============================================================
local lore = greet:keyword("lore")

function lore:callback(npc, player, message, handler)
    local total = getCompletedTrials(player)
    local name  = player:getName()

    if total == 0 then
        return true, "The Oracle's lore is sealed to the untested. Complete at least one {trial} and the first chapter will open to you."
    end

    local talk = NpcTalkQueue(npc)

    if total >= 1 then
        talk:addToQueue(player, "Chapter I: In the beginning, there was only silence and a single unblinking flame.",        0)
        talk:addToQueue(player, "From that flame, the first Oracle was born - not of flesh, but of pure knowing.",          3500)
        talk:addToQueue(player, "With knowing came creation. Stars. Oceans. Life. And with life, came the first question.", 7000)
    end
    if total >= 2 then
        talk:addToQueue(player, "Chapter II: A shadow emerged, born from every question left unanswered.",                 11000)
        talk:addToQueue(player, "It sent three champions against the flame - a deceiver, a coward, and a restless soul.",  14500)
        talk:addToQueue(player, "Each was defeated not by force, but by Wisdom, Courage, and Patience.",                  18000)
    end
    if total >= 3 then
        talk:addToQueue(player, "Chapter III: The flame did not die. It multiplied. It passed into those who sought it.", 22000)
        talk:addToQueue(player, "Into those willing to be tested. Into those who echoed the ancient words in silence.",   25500)
        talk:addToQueue(player, "It passed into you, " .. name .. ". Guard it. The Oracle's story is now, in part, yours.", 29000)
    end

    return true
end

-- ============================================================
-- REWARD
-- ============================================================
local reward = greet:keyword("reward")

function reward:callback(npc, player, message, handler)
    local total, w, c, p = getCompletedTrials(player)

    if total < 3 then
        local missing = {}
        if not w then table.insert(missing, "wisdom")   end
        if not c then table.insert(missing, "courage")  end
        if not p then table.insert(missing, "patience") end
        return false, "The reward is earned only by those who have completed all three trials. You still lack: " .. table.concat(missing, ", ") .. "."
    end

    local rewardGiven = player:getStorageValue(STORAGE_REWARD_GIVEN)
    if rewardGiven and rewardGiven > 0 then
        return true, "The Oracle's gift was already bestowed upon you, |PLAYERNAME|. Carry it with pride. The {prophecy} and {lore} remain open to you."
    end

    local talk = NpcTalkQueue(npc)
    talk:addToQueue(player, "Champion...",                                                                         0)
    talk:addToQueue(player, "You have proven Wisdom. Courage. Patience.",                                        2500)
    talk:addToQueue(player, "Three virtues. One soul. This is rare.",                                            5500)
    talk:addToQueue(player, "The Oracle grants you the Mark of Enlightenment. May it light your darkest roads.", 8500)

    player:setStorageValue(STORAGE_REWARD_GIVEN, 1)
    player:addItem(2160, 1)
    return true
end

--[[
    NPC TREE STRUCTURE:
    greet (dynamic: visits + ordinal + trials progress)
        |- prophecy    (NpcTalkQueue: vocation + level + time - player:getName())
        |- trial       (lista trials restantes)
        |   |- wisdom   (random riddle do pool de 12)
        |   |   └── onAnswer (valida - ignora nav keywords)
        |   |- courage  (intro)
        |   |   |- accept (NpcTalkQueue: void dramatico + completa trial)
        |   |   └── refuse
        |   └── patience (instrucoes)
        |       └── "i am ready"
        |           └── "the oracle sees all"
        |               └── "time is the greatest teacher"
        |                   └── "i have earned my wisdom" (completa trial)
        |- wisdom   [shortcut: wisdom:callback + wisdomAnswer:callback]
        |- courage  [shortcut: courage:callback]
        |   |- accept [shortcut: courageAccept:callback]
        |   └── refuse [shortcut: courageRefuse:callback]
        |- patience [shortcut: patience:callback]
        |   └── chain completa (i am ready -> ... -> i have earned my wisdom)
        |- lore    (NpcTalkQueue: capitulos por trial count - player:getName())
        └── reward (valida trials + item unico + NpcTalkQueue)
]]