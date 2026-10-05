local addonName, addonEnv = ...

-- Directional Node Mapping
local DIRECTIONS = {
    [1] = { name = "Up",    r = 0.9, g = 0.9, b = 0.9 },
    [2] = { name = "Right", r = 0.9, g = 0.9, b = 0.9 },
    [3] = { name = "Down",  r = 0.9, g = 0.9, b = 0.9 },
    [4] = { name = "Left",  r = 0.9, g = 0.9, b = 0.9 },
}

local sequence = {}
local currentIndex = 0
local debugMode = false
local manualOverride = false

-- UI Frame Setup (Widened frame to accommodate side-by-side list & D-Pad)
local frame = CreateFrame("Frame", "RelicHelperFrame", UIParent, "BackdropTemplate")
frame:SetSize(280, 280)
frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:EnableMouse(true)
frame:EnableKeyboard(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

-- Title
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", frame, "TOP", 0, -10)
title:SetText("Relic's Emanation Tracker")

-- Close (X) Button in Top Right
local closeBtn = CreateFrame("Button", "RelicHelperCloseBtn", frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
    manualOverride = false
    frame:Hide()
end)

-- Display Text Box (Left Side)
local displayText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
displayText:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -32)
displayText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 125, 55)
displayText:SetJustifyH("LEFT")
displayText:SetJustifyV("TOP")
displayText:SetText("Waiting...")

local buttons = {}

-- Cross / D-Pad Positioning Relative to Right Side (X, Y)
local buttonOffsets = {
    [1] = { 65, -55 },   -- Up (U)
    [2] = { 105, -95 },  -- Right (R)
    [3] = { 65, -135 },  -- Down (D)
    [4] = { 25, -95 },   -- Left (L)
}

-- Zone check function for Ogri'la (Blade's Edge Mountains)
local function CheckZone()
    if manualOverride then return true end
    local currentZone = GetZoneText()
    if currentZone == "Ogri'la" or currentZone == "Blade's Edge Mountains" then
        local subZone = GetSubZoneText()
        if currentZone == "Ogri'la" or subZone == "Ogri'la" then
            return true
        end
    end
    return false
end

local function UpdateDisplay()
    local total = #sequence
    if total == 0 then
        displayText:SetText("Waiting...")
        return
    end
    
    local lines = {}
    local maxLines = 10 -- Total visible lines in left column
    
    local function formatLine(i, dirIdx)
        local dir = DIRECTIONS[dirIdx]
        if i == currentIndex then
            return string.format("%2d. > |cffffd700%s|r <", i, dir.name)
        else
            return string.format("%2d.   |cffffffff%s|r", i, dir.name)
        end
    end

    if total <= maxLines then
        for i, dirIdx in ipairs(sequence) do
            table.insert(lines, formatLine(i, dirIdx))
        end
    else
        -- Determine window bounds to keep currentIndex visible
        local startIdx = 1
        local endIdx = total
        
        if currentIndex > 0 then
            -- Center around currentIndex if possible, keeping window size to maxLines
            startIdx = math.max(1, currentIndex - math.floor(maxLines / 2))
            endIdx = startIdx + maxLines - 1
            if endIdx > total then
                endIdx = total
                startIdx = math.max(1, endIdx - maxLines + 1)
            end
        else
            endIdx = maxLines
        end
        
        if startIdx > 1 then
            table.insert(lines, "|cff888888    ...|r")
        else
            table.insert(lines, formatLine(1, sequence[1]))
        end
        
        local loopStart = (startIdx > 1) and startIdx or 2
        local loopEnd = (endIdx < total) and endIdx or (total - 1)
        
        for i = loopStart, loopEnd do
            table.insert(lines, formatLine(i, sequence[i]))
        end
        
        if endIdx < total then
            table.insert(lines, "|cff888888    ...|r")
        elseif total > 1 then
            table.insert(lines, formatLine(total, sequence[total]))
        end
    end
    
    displayText:SetText(table.concat(lines, "\n"))
end

local function FlashNode(dirIdx)
    local btn = buttons[dirIdx]
    if not btn then return end
    btn:SetAlpha(1.0)
    C_Timer.After(0.3, function() btn:SetAlpha(0.7) end)
end

local function ResetSequence()
    sequence = {}
    currentIndex = 0
    UpdateDisplay()
end

local function RecordNode(dirIdx)
    if CheckZone() then
        frame:Show()
    end
    if currentIndex > 0 then
        sequence = {}
        currentIndex = 0
    end
    table.insert(sequence, dirIdx)
    FlashNode(dirIdx)
    UpdateDisplay()
end

local function AdvanceStep()
    if #sequence == 0 then return end
    
    if currentIndex == 0 then
        currentIndex = 1
    else
        currentIndex = currentIndex + 1
        if currentIndex > #sequence then
            ResetSequence()
            return
        end
    end
    UpdateDisplay()
end

-- Arrow Key Press Handler
frame:SetScript("OnKeyDown", function(self, key)
    if not CheckZone() then return end
    
    if key == "UP" then
        RecordNode(1)
        self:SetPropagateKeyboardInput(false)
    elseif key == "RIGHT" then
        RecordNode(2)
        self:SetPropagateKeyboardInput(false)
    elseif key == "DOWN" then
        RecordNode(3)
        self:SetPropagateKeyboardInput(false)
    elseif key == "LEFT" then
        RecordNode(4)
        self:SetPropagateKeyboardInput(false)
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

-- Create Cross / D-Pad Buttons (Right Side)
for id, info in ipairs(DIRECTIONS) do
    local btn = CreateFrame("Button", "RelicHelperBtn"..id, frame, "UIPanelButtonTemplate")
    btn:SetSize(36, 36)
    
    local offset = buttonOffsets[id]
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", offset[1] + 110, offset[2])
    btn:SetText(info.name:sub(1,1))
    btn:SetAlpha(0.7)
    btn:SetFrameLevel(frame:GetFrameLevel() + 5)
    
    btn:RegisterForClicks("LeftButtonUp")
    btn:SetScript("OnClick", function(self, button)
        RecordNode(id)
    end)
    
    buttons[id] = btn
end

-- Next Step Button (Bottom Right / Under D-Pad)
local nextBtn = CreateFrame("Button", "RelicHelperNextBtn", frame, "UIPanelButtonTemplate")
nextBtn:SetSize(120, 22)
nextBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 34)
nextBtn:SetText("Next Step")
nextBtn:SetFrameLevel(frame:GetFrameLevel() + 5)
nextBtn:SetScript("OnClick", AdvanceStep)

-- Reset Button (Enlarged, Bottom Center)
local resetBtn = CreateFrame("Button", "RelicHelperResetBtn", frame, "UIPanelButtonTemplate")
resetBtn:SetSize(120, 22)
resetBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
resetBtn:SetText("Reset")
resetBtn:SetFrameLevel(frame:GetFrameLevel() + 5)
resetBtn:SetScript("OnClick", ResetSequence)

-- Register Event Handlers & Zone Checking
local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
eventHandler:RegisterEvent("ZONE_CHANGED")
eventHandler:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventHandler:RegisterEvent("GOSSIP_SHOW")
eventHandler:RegisterEvent("ITEM_TEXT_BEGIN")
eventHandler:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

eventHandler:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        if not manualOverride then
            if CheckZone() then
                -- Zone matches
            else
                frame:Hide()
            end
        end
    elseif event == "GOSSIP_SHOW" or event == "ITEM_TEXT_BEGIN" then
        if CheckZone() then
            frame:Show()
        end
    elseif debugMode then
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            print(string.format("|cffffaa00[RH Debug]|r Unit Spellcast: %s -> SpellID: %s", tostring(unit), tostring(spellID)))
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName = CombatLogGetCurrentEventInfo()
            if spellID and (subevent:find("SPELL") or subevent:find("ENVIRONMENTAL")) then
                print(string.format("|cff00ffff[RH Debug]|r Event: %s | SpellID: |cffff0000%s|r (%s) | Source: %s", subevent, tostring(spellID), tostring(spellName), tostring(sourceName or "Unknown")))
            end
        end
    end
end)

-- Slash Commands & Macro Keybind Support
SLASH_RELICHELPER1 = "/rh"
SLASH_RELICHELPER2 = "/relic"

SlashCmdList["RELICHELPER"] = function(msg)
    msg = msg:lower():trim()
    if msg == "debug" then
        debugMode = not debugMode
        print("|cff00ff00[RelicHelper]|r Debug mode set to: " .. tostring(debugMode))
    elseif msg == "next" or msg == "n" then
        AdvanceStep()
    elseif msg == "1" or msg == "u" or msg == "up" then
        RecordNode(1)
    elseif msg == "2" or msg == "r" or msg == "right" then
        RecordNode(2)
    elseif msg == "3" or msg == "d" or msg == "down" then
        RecordNode(3)
    elseif msg == "4" or msg == "l" or msg == "left" then
        RecordNode(4)
    elseif msg == "reset" or msg == "c" or msg == "clear" then
        ResetSequence()
    elseif msg == "show" then
        manualOverride = true
        frame:Show()
        print("|cff00ff00[RelicHelper]|r Manual override active: window forced open.")
    elseif msg == "hide" then
        manualOverride = false
        frame:Hide()
        print("|cff00ff00[RelicHelper]|r Manual override cleared; window hidden.")
    else
        print("|cff00ff00[RelicHelper]|r Usage: /rh up, /rh right, /rh down, /rh left, /rh next, /rh show, /rh hide, /rh debug, /rh reset")
    end
end