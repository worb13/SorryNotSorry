SorryNotSorry = {}

local whitelist = {
    friends={
        id={},
        char={}
    },
    guilds={
        id={},
        char={}
    }
}

local SavedVars = {}
local defaultSavedVars = {
    settings={
        isFilterGlobal=false,
        isFilterFriend=false,
        isFilterGuildie=false,
        isBlockedMsgNote=true
    }
}

-- data structure
-- {
--     friends: {
--         id: {
--             "@Tailger": 1
--         }
--         char: {
--             "kaaz": 1
--         }
--     },
--     guilds: {
--         id: {
--             "@Tailger": 1
--         }
--         char: {
--             "kaaz": 1
--         }
--     }
-- }

local function truncCharName(name)
    local charNameLen = string.len(name)
    if(name:sub(charNameLen - 2, - 3) == "^") then
        return name:sub(1, -4)
    end
    return name
end

-- Function to set up the friends list in the whitelist
local function InitLookupFriends()
    whitelist["friends"]["id"] = {}
    whitelist["friends"]["char"] = {}
    for i=1, GetNumFriends() do
        local IdName = GetFriendInfo(i)
        local hasChar, CharName = GetFriendCharacterInfo(i);

        whitelist["friends"]["id"][IdName] = 1;
        whitelist["friends"]["char"][truncCharName(CharName)] = 1;
    end
end

-- src: https://www.esoui.com/forums/showthread.php?t=2298
-- thank you OP!
local function InitLookupGuilds()
    whitelist["guilds"]["id"] = {}
    whitelist["guilds"]["char"] = {}
    for guild = 1, GetNumGuilds() do
        -- Guildname
        local guildId = GetGuildId(guild)
        local guildName = GetGuildName(guildId)

        -- Occurs sometimes
        if(not guildName or (guildName):len() < 1) then
            guildName = "Guild " .. guildId
        end

        -- Iterate over each guild member
        for member = 1, GetNumGuildMembers(guildId) do
            -- Get account name and character name
            local IdName = GetGuildMemberInfo(guildId, member)
            local hasChar, CharName = GetGuildMemberCharacterInfo(guildId, member)

            whitelist["guilds"]["id"][IdName] = 1;
            whitelist["guilds"]["char"][truncCharName(CharName)] = 1;
        end
    end
end

local function isFriend(name)
    return ((whitelist["friends"]["id"][name] == 1) or (whitelist["friends"]["char"][truncCharName(name)] == 1))
end

local function isGuildie(name)
    return ((whitelist["guilds"]["id"][name] == 1) or (whitelist["guilds"]["char"][truncCharName(name)] == 1))
end

--- some code taken from harvens simple chat filter
-- Thank you!
local function OnChatEvent(control, ...)
    local messageSource, messageType, messageSender, messageContent = ...
    -- CHAT_SYSTEM:AddMessage("nara")
    -- --- message type indicated whether the message is from the system or from other users
    -- --- 327683 (system), 131103 (others, dialogue)
    -- CHAT_SYSTEM:AddMessage(messageSource)
    -- --- chat type
    -- --- number, number 2 if recieving tell msg
    -- CHAT_SYSTEM:AddMessage(messageType)
    -- --- sender
    -- --- can be @ name or char name
    -- CHAT_SYSTEM:AddMessage(messageSender)
    -- --- message
    -- --- displayed message or 1 if its system
    -- CHAT_SYSTEM:AddMessage(messageContent)


    -- if login then add char name to the friends list
    if(messageSource == 327683 and messageContent == 4) then
        whitelist["friends"]["char"][truncCharName(messageSender)] = 1;
    end

    -- if whisper / private msg / direct msg / etc.
    if(messageSource == 131103 and messageType == 2) then
        if(
            (not SavedVars["settings"]["isFilterFriend"]) and (not SavedVars["settings"]["isFilterGuildie"])
                or (SavedVars["settings"]["isFilterFriend"] and isFriend(messageSender))
                or (SavedVars["settings"]["isFilterGuildie"] and isGuildie(messageSender))
        ) then
            SorryNotSorry.OnChatEventOrg(control, ...)

        -- else do not call original chat event fn (and therefore message blocked)
        elseif(SavedVars["settings"]["isBlockedMsgNote"]) then
            CHAT_SYSTEM:AddMessage("Private Message Blocked!")
        end
    else
        SorryNotSorry.OnChatEventOrg(control, ...)
    end
end

local function printHelpMessage()
    CHAT_SYSTEM:AddMessage("Unknown Private Message Blocking --- Available Commands:")
    CHAT_SYSTEM:AddMessage("/sns --- toggles friend and guild PM whitelist on and off")
    CHAT_SYSTEM:AddMessage("/sns on --- turns on both friend and guild PM whitelist")
    CHAT_SYSTEM:AddMessage("/sns off --- turns off both friend and guild PM whitelist")
    CHAT_SYSTEM:AddMessage("/sns friendsonly --- turns on friend PM whitelist")
    CHAT_SYSTEM:AddMessage("/sns guildiesonly --- turns on guildie PM whitelist")
    CHAT_SYSTEM:AddMessage("/sns msgnote --- toggles blocked msg on and off")
end

local function slashCmdMainHandler(arg)
   -- the following can be a switch, just couldnt be bothered to figure out how lol
    if(arg == "help") then
        printHelpMessage()
    elseif(arg == "on") then
        SavedVars["settings"]["isFilterGlobal"] = true
        SavedVars["settings"]["isFilterFriend"] = true
        SavedVars["settings"]["isFilterGuildie"] = true

        CHAT_SYSTEM:AddMessage("Unknown Private Message Blocking:")
        CHAT_SYSTEM:AddMessage("On")
    elseif(arg == "off") then
        SavedVars["settings"]["isFilterGlobal"] = false
        SavedVars["settings"]["isFilterFriend"] = false
        SavedVars["settings"]["isFilterGuildie"] = false

        CHAT_SYSTEM:AddMessage("Unknown Private Message Blocking:")
        CHAT_SYSTEM:AddMessage("Off")
    elseif(arg == "friendsonly") then
        SavedVars["settings"]["isFilterGlobal"] = false
        SavedVars["settings"]["isFilterFriend"] = true
        SavedVars["settings"]["isFilterGuildie"] = false

        CHAT_SYSTEM:AddMessage("Unknown Private Message Blocking:")
        CHAT_SYSTEM:AddMessage("Friends Only")
    elseif(arg == "guildiesonly") then
        SavedVars["settings"]["isFilterGlobal"] = false
        SavedVars["settings"]["isFilterFriend"] = false
        SavedVars["settings"]["isFilterGuildie"] = true

        CHAT_SYSTEM:AddMessage("Unknown Private Message Blocking:")
        CHAT_SYSTEM:AddMessage("Guildies Only")
    elseif(arg == "msgnote") then
        SavedVars["settings"]["isBlockedMsgNote"] = not SavedVars["settings"]["isBlockedMsgNote"]

        CHAT_SYSTEM:AddMessage("Unknown Private Message Blocking:")
        if(SavedVars["settings"]["isBlockedMsgNote"]) then
            CHAT_SYSTEM:AddMessage("Blocked Message Note On")
        else
            CHAT_SYSTEM:AddMessage("Blocked Message Note Off")
        end
    else
        SavedVars["settings"]["isFilterGlobal"] = not SavedVars["settings"]["isFilterGlobal"]
        SavedVars["settings"]["isFilterFriend"] = SavedVars["settings"]["isFilterGlobal"]
        SavedVars["settings"]["isFilterGuildie"] = SavedVars["settings"]["isFilterGlobal"]

        CHAT_SYSTEM:AddMessage("Unknown Private Message Blocking:")
        if(SavedVars["settings"]["isFilterGlobal"]) then
            CHAT_SYSTEM:AddMessage("On")
        else
            CHAT_SYSTEM:AddMessage("Off")
        end
    end
end

function SorryNotSorry:Initialize()
    SavedVars = ZO_SavedVars:NewAccountWide("SorryNotSorry_Data", 1, nil, defaultSavedVars)

    -- store original OnChatEvent fn and overwrite the event handler with our own
    self.OnChatEventOrg = CHAT_SYSTEM.OnChatEvent
    CHAT_SYSTEM.OnChatEvent = OnChatEvent

    InitLookupFriends()
    InitLookupGuilds()

    SLASH_COMMANDS["/sorrynotsorry"] = printHelpMessage
    SLASH_COMMANDS["/sns"] = slashCmdMainHandler
end

local function SorryNotSorryAddonLoaded(eventType, addonName)
    if addonName ~= "SorryNotSorry" then return end

    SorryNotSorry:Initialize()
end

-- When friends list changes just rebuild friends list
-- If optimisation is required, this can be replaced with a targeted fn
EVENT_MANAGER:RegisterForEvent("SorryNotSorry", EVENT_FRIEND_ADDED, InitLookupFriends)
EVENT_MANAGER:RegisterForEvent("SorryNotSorry", EVENT_FRIEND_REMOVED, InitLookupFriends)

-- When guild roster changes just rebuild friends list
-- If optimisation is required, this can be replaced with a targeted fn
EVENT_MANAGER:RegisterForEvent("SorryNotSorry", EVENT_GUILD_MEMBER_ADDED, InitLookupGuilds)
-- the EVENT_GUILD_MEMBER_REMOVED event provides enough info to do very targeted removal
EVENT_MANAGER:RegisterForEvent("SorryNotSorry", EVENT_GUILD_MEMBER_REMOVED, InitLookupGuilds)

EVENT_MANAGER:RegisterForEvent("SorryNotSorry", EVENT_ADD_ON_LOADED, SorryNotSorryAddonLoaded)