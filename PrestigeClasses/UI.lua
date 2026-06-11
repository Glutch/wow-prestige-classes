local ADDON, PC = ...

PC.UI = {}
local UI = PC.UI

local GREEN = "|cff40ff40"
local RED = "|cffff4040"
local GREY = "|cff999999"
local GOLD = "|cffffd100"
local WHITE = "|cffffffff"
local R = "|r"

local FACTION_COLOR = {
    Alliance = "|cff5aa0ff",
    Horde = "|cffff5a5a",
    Both = "|cffd0b860",
}
local INELIGIBLE = "|cff666666"

-- Inline texture escapes for requirement marks.
local MARK_OK = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:14:14:0:-1|t"
local MARK_FAIL = "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:14:14:0:-1|t"
local MARK_INFO = "|TInterface\\RAIDFRAME\\ReadyCheck-Waiting:14:14:0:-1|t"

-- Browse page groups paths under these WoW classes, player's own class first.
local CLASS_ORDER = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}

local selectedId      -- class id shown on the detail page
local page = "browse" -- "browse" | "detail" | "journal"

-- ------------------------------------------------------------------------
-- Small helpers
-- ------------------------------------------------------------------------
-- On paths with trials the rank is earned, not given; say so when a trial
-- still bars the way.
local function rankText(def)
    if PC.Trials and def then
        local rank, title, pending = PC.Trials.RankInfo(def)
        if pending then
            return title .. " — the " .. PC.Trials.RANK_TITLES[rank + 1] ..
                "'s trial awaits"
        end
        return title
    end
    return PC.Util.RankTitle(UnitLevel("player"))
end

local function daysAgoText(t)
    if not t then return "?" end
    local days = math.floor((time() - t) / 86400)
    if days <= 0 then return "today"
    elseif days == 1 then return "1 day"
    else return days .. " days" end
end

local function classColorStr(token)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if c and c.colorStr then return "|c" .. c.colorStr end
    if c then
        return ("|cff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255)
    end
    return GOLD
end

local function classDisplayName(token)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token])
        or token:sub(1, 1) .. token:sub(2):lower()
end

local function raceReqText(def)
    if not def.races then return "Any race" end
    return table.concat(def.races, ", "):gsub("NightElf", "Night Elf")
end

-- ------------------------------------------------------------------------
-- Detail page text builders (two columns)
-- ------------------------------------------------------------------------
local function buildReqText(def)
    local results = PC.Compliance.Evaluate(def)
    local lines = {}
    lines[#lines + 1] = GOLD .. "Requirements" .. R
    for _, r in ipairs(results) do
        local mark = r.ok and MARK_OK or MARK_FAIL
        if r.kind == "info" and not r.ok then mark = MARK_INFO end
        local color = r.ok and WHITE or (r.kind == "info" and GREY or RED)
        lines[#lines + 1] = mark .. " " .. color .. r.label .. R
        if r.detail and r.detail ~= "" then
            lines[#lines + 1] = "      " .. GREY .. r.detail .. R
        end
    end
    return table.concat(lines, "\n")
end

local function buildVowText(def)
    local lines = {}
    lines[#lines + 1] = GOLD .. "Vows of the " .. def.name .. R
    lines[#lines + 1] = GREY .. "Honor rules the addon cannot see. Your word is the only enforcement." .. R
    lines[#lines + 1] = ""
    for _, h in ipairs(def.honorRules) do
        lines[#lines + 1] = GOLD .. "•" .. R .. " " .. WHITE .. h .. R
    end

    local db = PrestigeClassesCharDB
    if db and db.active == def.id and db.stats then
        local s = db.stats
        lines[#lines + 1] = ""
        lines[#lines + 1] = GOLD .. "Your record" .. R
        lines[#lines + 1] = WHITE .. "Walking this path: " .. R .. GREY .. daysAgoText(s.chosenAt) .. R
        local breaks = s.breaks or 0
        if breaks == 0 then
            lines[#lines + 1] = GREEN .. "Vows never broken." .. R
        else
            lines[#lines + 1] = WHITE .. "Vows broken: " .. R .. RED .. breaks .. R
            lines[#lines + 1] = GREY .. "Clean for " .. daysAgoText(s.lastBreakAt or s.chosenAt) .. R
        end
        if def.trials and PC.Trials then
            local done, total = PC.Trials.Counts(def)
            lines[#lines + 1] = WHITE .. "Deeds done: " .. R .. GOLD ..
                done .. "/" .. total .. R .. GREY .. " — see the Path Journal" .. R
        end
    end
    return table.concat(lines, "\n")
end

-- ------------------------------------------------------------------------
-- Main frame shell
-- ------------------------------------------------------------------------
local function createMainFrame()
    local f = CreateFrame("Frame", "PrestigeClassesFrame", UIParent, "BackdropTemplate")
    f:SetSize(720, 560)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "PrestigeClassesFrame") -- close on Escape

    local ribbon = f:CreateTexture(nil, "ARTWORK")
    ribbon:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    ribbon:SetSize(320, 64)
    ribbon:SetPoint("TOP", 0, 12)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", ribbon, "TOP", 0, -14)
    title:SetText(GOLD .. "Prestige Classes" .. R)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    return f
end

-- ------------------------------------------------------------------------
-- Browse page: every path, grouped by WoW class
-- ------------------------------------------------------------------------
local function groupedClasses()
    local playerToken = PC.Util.PlayerClass()
    local order = { playerToken }
    for _, token in ipairs(CLASS_ORDER) do
        if token ~= playerToken then order[#order + 1] = token end
    end

    local groups = {}
    for _, token in ipairs(order) do
        local defs = {}
        for _, def in ipairs(PC.Classes) do
            if PC.Util.ListContains(def.classes, token) then
                defs[#defs + 1] = def
            end
        end
        -- Within a group, paths this character can actually take come first.
        table.sort(defs, function(a, b)
            local ea = PC.Compliance.Eligible(a) and 1 or 0
            local eb = PC.Compliance.Eligible(b) and 1 or 0
            if ea ~= eb then return ea > eb end
            return a.name < b.name
        end)
        if #defs > 0 then
            groups[#groups + 1] = { token = token, defs = defs }
        end
    end
    return groups
end

local function createBrowsePane(f)
    local pane = CreateFrame("Frame", nil, f)
    pane:SetPoint("TOPLEFT", 20, -48)
    pane:SetPoint("BOTTOMRIGHT", -20, 20)
    f.browsePane = pane

    local scroll = CreateFrame("ScrollFrame", "PrestigeClassesBrowseScroll", pane, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", -24, 36)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(640, 10)
    scroll:SetScrollChild(child)

    local y = -2
    pane.rows = {}
    for _, group in ipairs(groupedClasses()) do
        local header = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", 4, y)
        header:SetText(classColorStr(group.token) .. classDisplayName(group.token) .. R ..
            GREY .. "  —  " .. #group.defs .. (#group.defs == 1 and " path" or " paths") .. R)
        y = y - 20

        local line = child:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(1, 1, 1, 0.12)
        line:SetSize(630, 1)
        line:SetPoint("TOPLEFT", 4, y)
        y = y - 6

        for _, def in ipairs(group.defs) do
            local b = CreateFrame("Button", nil, child)
            b:SetSize(630, 26)
            b:SetPoint("TOPLEFT", 4, y)
            y = y - 27

            local hl = b:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 0.82, 0, 0.18)

            local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", 6, 0)
            label:SetJustifyH("LEFT")
            label:SetWidth(420)
            b.label = label

            local right = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            right:SetPoint("RIGHT", -8, 0)
            right:SetJustifyH("RIGHT")
            right:SetWidth(190)
            b.right = right

            b.def = def
            b.eligible = PC.Compliance.Eligible(def)

            b:SetScript("OnClick", function()
                UI.ShowDetail(def.id)
            end)
            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(def.name, 1, 0.82, 0)
                GameTooltip:AddLine(def.fantasy, 1, 1, 1, true)
                if not b.eligible then
                    GameTooltip:AddLine("Not available to this character.", 0.6, 0.6, 0.6)
                end
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)

            pane.rows[#pane.rows + 1] = b
        end
        y = y - 10
    end
    child:SetHeight(math.abs(y) + 8)

    local surprise = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
    surprise:SetSize(180, 26)
    surprise:SetPoint("BOTTOM", 0, 0)
    surprise:SetText("Surprise me")
    surprise:SetScript("OnClick", function()
        local pool = {}
        for _, def in ipairs(PC.Classes) do
            if PC.Compliance.Eligible(def) then pool[#pool + 1] = def.id end
        end
        if #pool > 0 then
            UI.ShowDetail(pool[math.random(#pool)])
        end
    end)
end

local function refreshBrowse(f)
    local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
    local activeOk
    if activeId and PC.ClassById[activeId] then
        local _, summary = PC.Compliance.Evaluate(PC.ClassById[activeId])
        activeOk = summary.compliant
    end

    for _, b in ipairs(f.browsePane.rows) do
        local def = b.def
        local color = b.eligible and FACTION_COLOR[def.faction] or INELIGIBLE
        local prefix, suffix = "", ""
        if def.id == activeId then
            prefix = GOLD .. "★ " .. R
            suffix = activeOk and (" " .. MARK_OK) or (" " .. MARK_FAIL)
        end
        b.label:SetText(prefix .. "|T" .. def.icon .. ":18:18:0:-2|t " ..
            color .. def.name .. R .. suffix)
        b.right:SetText(GREY .. raceReqText(def) .. "  " .. R ..
            (FACTION_COLOR[def.faction] or GREY) .. def.faction .. R)
    end
end

-- ------------------------------------------------------------------------
-- Item strips: the spoils a journey awards and the arms it suggests.
-- Hover for the live tooltip; shift-click links to chat, right-click
-- (or ctrl-click) opens the dressing room.
-- ------------------------------------------------------------------------
local QUESTION_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function collectSpoils(def)
    if not (def.trials and def.itemIds) then return {} end
    local suggested = {}
    for _, s in ipairs(def.suggestedItems or {}) do suggested[s.name] = true end
    local seen, list = {}, {}
    local function add(name)
        local id = name and def.itemIds[name]
        if id and not seen[name] and not suggested[name] then
            seen[name] = true
            list[#list + 1] = { id = id, name = name }
        end
    end
    for _, trial in ipairs(def.trials) do
        for _, name in ipairs(trial.items or {}) do add(name) end
        add(trial.item)
        add(trial.spell) -- crafted deeds: the spell and its item share a name
    end
    return list
end

local function itemButton(pane, i)
    local b = pane.itemButtons[i]
    if b then return b end
    b = CreateFrame("Button", nil, pane.scrollChild)
    b:SetSize(32, 32)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. self.itemId)
        if self.note then
            GameTooltip:AddLine(self.note, 0.78, 0.72, 0.47, true)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function(self, mouse)
        local _, link = GetItemInfo(self.itemId)
        if IsModifiedClick("CHATLINK") and link then
            ChatEdit_InsertLink(link)
        elseif mouse == "RightButton" or IsModifiedClick("DRESSUP") then
            DressUpItemLink(link or ("item:" .. self.itemId))
        end
    end)
    pane.itemButtons[i] = b
    return b
end

-- Lays out both strips below the two text columns; returns the total
-- scroll-child height.
local ITEMS_PER_ROW = 16

local function layoutItemStrips(pane, def)
    for _, b in ipairs(pane.itemButtons) do b:Hide() end
    for _, h in ipairs(pane.itemHeaders) do h:Hide() end
    local y = -(math.max(pane.reqText:GetStringHeight(),
        pane.vowText:GetStringHeight()) + 18)
    local n, hn = 0, 0
    local function header(text)
        hn = hn + 1
        local h = pane.itemHeaders[hn]
        if not h then
            h = pane.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            h:SetJustifyH("LEFT")
            pane.itemHeaders[hn] = h
        end
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", 0, y)
        h:SetText(text)
        h:Show()
        y = y - 22
    end
    local function strip(entries)
        local col = 0
        for _, e in ipairs(entries) do
            n = n + 1
            local b = itemButton(pane, n)
            b.itemId, b.note = e.id, e.note
            b.icon:SetTexture(GetItemIcon and GetItemIcon(e.id) or QUESTION_ICON)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", col * 38, y)
            b:Show()
            -- Warm the item cache so the first hover shows a real tooltip.
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(e.id)
            end
            col = col + 1
            if col >= ITEMS_PER_ROW then col = 0; y = y - 38 end
        end
        if col > 0 then y = y - 38 end
        y = y - 8
    end
    local spoils = collectSpoils(def)
    if #spoils > 0 then
        header(GOLD .. "Spoils of the path" .. R ..
            GREY .. "  — what the deeds award" .. R)
        strip(spoils)
    end
    if def.suggestedItems and #def.suggestedItems > 0 then
        header(GOLD .. "Suggested arms" .. R ..
            GREY .. "  — worth chasing along the way" .. R)
        strip(def.suggestedItems)
    end
    return -y
end

-- ------------------------------------------------------------------------
-- Detail page: one path, full window
-- ------------------------------------------------------------------------
local function createDetailPane(f)
    local pane = CreateFrame("Frame", nil, f)
    pane:SetPoint("TOPLEFT", 20, -44)
    pane:SetPoint("BOTTOMRIGHT", -20, 20)
    pane:Hide()
    f.detailPane = pane

    local back = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
    back:SetSize(110, 22)
    back:SetPoint("TOPLEFT", 0, 0)
    back:SetText("« All paths")
    back:SetScript("OnClick", function() UI.ShowBrowse() end)

    local icon = pane:CreateTexture(nil, "ARTWORK")
    icon:SetSize(44, 44)
    icon:SetPoint("TOPLEFT", 0, -32)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    pane.icon = icon

    local nameFS = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameFS:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    nameFS:SetJustifyH("LEFT")
    pane.name = nameFS

    local subFS = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subFS:SetPoint("TOPLEFT", nameFS, "BOTTOMLEFT", 0, -4)
    subFS:SetJustifyH("LEFT")
    pane.sub = subFS

    local fantasyFS = pane:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fantasyFS:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -10)
    fantasyFS:SetWidth(656)
    fantasyFS:SetJustifyH("LEFT")
    fantasyFS:SetSpacing(2)
    pane.fantasy = fantasyFS

    local statusFS = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusFS:SetPoint("TOPLEFT", fantasyFS, "BOTTOMLEFT", 0, -8)
    statusFS:SetWidth(656)
    statusFS:SetJustifyH("LEFT")
    pane.status = statusFS

    local scroll = CreateFrame("ScrollFrame", "PrestigeClassesDetailScroll", pane, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", statusFS, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", -24, 38)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(640, 10)
    scroll:SetScrollChild(child)
    pane.scrollChild = child

    local reqText = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    reqText:SetPoint("TOPLEFT", 0, 0)
    reqText:SetWidth(380)
    reqText:SetJustifyH("LEFT")
    reqText:SetJustifyV("TOP")
    reqText:SetSpacing(3)
    pane.reqText = reqText

    local vowText = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    vowText:SetPoint("TOPLEFT", 400, 0)
    vowText:SetWidth(240)
    vowText:SetJustifyH("LEFT")
    vowText:SetJustifyV("TOP")
    vowText:SetSpacing(3)
    pane.vowText = vowText

    pane.itemButtons = {}
    pane.itemHeaders = {}

    local activate = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
    activate:SetSize(180, 26)
    activate:SetPoint("BOTTOMLEFT", 0, 0)
    activate:SetText("Walk this path")
    activate:SetScript("OnClick", function()
        if selectedId then UI.Activate(selectedId) end
    end)
    pane.activateBtn = activate

    local abandon = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
    abandon:SetSize(180, 26)
    abandon:SetPoint("LEFT", activate, "RIGHT", 12, 0)
    abandon:SetText("Abandon path")
    abandon:SetScript("OnClick", function() UI.Abandon() end)
    pane.abandonBtn = abandon

    local journal = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
    journal:SetSize(180, 26)
    journal:SetPoint("LEFT", abandon, "RIGHT", 12, 0)
    journal:SetText("Path Journal")
    journal:SetScript("OnClick", function() UI.ShowJournal() end)
    journal:Hide()
    pane.journalBtn = journal
end

local function refreshDetail(f)
    local pane = f.detailPane
    local def = selectedId and PC.ClassById[selectedId]
    if not def then
        UI.ShowBrowse()
        return
    end

    local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active

    pane.icon:SetTexture(def.icon)
    pane.name:SetText(GOLD .. def.name .. R)
    pane.sub:SetText(GREY .. def.source .. "  •  " .. R ..
        (FACTION_COLOR[def.faction] or GREY) .. def.faction .. R ..
        GREY .. "  •  " .. raceReqText(def) .. R)
    pane.fantasy:SetText(WHITE .. def.fantasy .. R)

    local _, summary = PC.Compliance.Evaluate(def)
    if activeId == def.id then
        local rank = rankText(def)
        if summary.compliant then
            pane.status:SetText(GREEN .. "ACTIVE — " .. rank .. " of this path. All vows honored (" ..
                summary.rulesPassed .. "/" .. summary.rulesTotal .. ")" .. R)
        elseif not summary.identityOk then
            pane.status:SetText(RED .. "ACTIVE — but this character can never satisfy this path." .. R)
        else
            pane.status:SetText(RED .. "ACTIVE — PATH BROKEN (" ..
                summary.rulesPassed .. "/" .. summary.rulesTotal .. " vows held)" .. R)
        end
    elseif not PC.Compliance.Eligible(def) then
        pane.status:SetText(GREY .. "Not available to this character (race/class)." .. R)
    else
        pane.status:SetText(GREY .. "A path open to you. Read the vows, then commit." .. R)
    end

    pane.reqText:SetText(buildReqText(def))
    pane.vowText:SetText(buildVowText(def))
    pane.scrollChild:SetHeight(layoutItemStrips(pane, def) + 10)

    if activeId == def.id then
        pane.activateBtn:SetText("Re-affirm vows")
    else
        pane.activateBtn:SetText("Walk this path")
    end
    pane.activateBtn:SetEnabled(PC.Compliance.Eligible(def))
    pane.abandonBtn:SetEnabled(activeId ~= nil)
    pane.journalBtn:SetShown(activeId == def.id and def.trials ~= nil)
end

-- ------------------------------------------------------------------------
-- Journal page: the active path's chapters, deeds and honorifics
-- ------------------------------------------------------------------------
local ROMAN = { "I", "II", "III", "IV" }

local function chapterTitle(def, c)
    local t = def.trialChapters and def.trialChapters[c]
    if t then return t end
    if c == 0 then return "The Long Watch" end
    return "Chapter " .. ROMAN[c] .. " — the " .. PC.Trials.RANK_TITLES[c]
end

local TAN = "|cffc8b878" -- parchment tone for the mentor's voice

local function trialLevelTag(trial)
    if not trial.level then return "" end
    local color = PC.Trials.IsReady(trial) and GREY or "|cffcc6666"
    return color .. "  (lvl ~" .. trial.level .. ")" .. R
end

local function addTrialLines(def, trial, locked, lines)
    local Tr = PC.Trials
    if locked then
        lines[#lines + 1] = INELIGIBLE .. "-  " .. trial.name .. R ..
            trialLevelTag(trial) ..
            (trial.rankTrial and (INELIGIBLE .. "  (rank trial)" .. R) or "")
        return
    end

    local s = Tr.State(trial.id)
    local progress = s and s.progress or 0
    local complete = Tr.IsComplete(trial)
    local mark = complete and MARK_OK or MARK_INFO
    local tag = trial.rankTrial and (GOLD .. "  [Rank Trial]" .. R) or ""
    lines[#lines + 1] = mark .. " " .. (complete and GREEN or WHITE) ..
        trial.name .. R .. (complete and "" or trialLevelTag(trial)) .. tag
    lines[#lines + 1] = "      " .. WHITE .. trial.objective .. R
    if trial.text then
        lines[#lines + 1] = "      " .. TAN .. "\"" .. trial.text .. "\"" .. R
    end

    local target = Tr.Target(trial)
    if trial.milestones then
        local parts = {}
        for _, m in ipairs(trial.milestones) do
            parts[#parts + 1] = (progress >= m.count and GREEN or GREY) ..
                (m.honorific or "?") .. " (" .. m.count .. ")" .. R
        end
        lines[#lines + 1] = "      " .. WHITE .. "Count: " .. progress .. R ..
            "   " .. table.concat(parts, GREY .. "  ·  " .. R)
    elseif target > 1 then
        lines[#lines + 1] = "      " .. WHITE .. "Progress: " ..
            progress .. "/" .. target .. R
    end
    if complete and trial.honorific then
        lines[#lines + 1] = "      " .. GOLD .. "Honorific earned: " ..
            trial.honorific .. R
    end
    lines[#lines + 1] = ""
end

local function buildJournalText(def)
    local Tr = PC.Trials
    local rank = Tr.RankInfo(def)
    local lines = {}
    for chapter = 0, 4 do
        local entries = {}
        for _, trial in ipairs(def.trials) do
            if (trial.chapter or 0) == chapter then
                entries[#entries + 1] = trial
            end
        end
        if #entries > 0 then
            local locked = chapter > 0 and rank < chapter
            lines[#lines + 1] = GOLD .. chapterTitle(def, chapter) .. R ..
                (locked and (GREY .. "   (locked — ascend to " ..
                    Tr.RANK_TITLES[chapter] .. ")" .. R) or "")
            lines[#lines + 1] = ""
            for _, trial in ipairs(entries) do
                addTrialLines(def, trial, locked, lines)
            end
            if locked then lines[#lines + 1] = "" end
        end
    end
    return table.concat(lines, "\n")
end

local function createJournalPane(f)
    local pane = CreateFrame("Frame", nil, f)
    pane:SetPoint("TOPLEFT", 20, -44)
    pane:SetPoint("BOTTOMRIGHT", -20, 20)
    pane:Hide()
    f.journalPane = pane

    local back = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
    back:SetSize(110, 22)
    back:SetPoint("TOPLEFT", 0, 0)
    back:SetText("« Path")
    back:SetScript("OnClick", function()
        local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
        if activeId then UI.ShowDetail(activeId) else UI.ShowBrowse() end
    end)

    local title = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 0, -32)
    title:SetJustifyH("LEFT")
    pane.title = title

    local sub = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetJustifyH("LEFT")
    sub:SetWidth(656)
    pane.sub = sub

    local scroll = CreateFrame("ScrollFrame", "PrestigeClassesJournalScroll", pane, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", -24, 4)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(640, 10)
    scroll:SetScrollChild(child)
    pane.scrollChild = child

    local body = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", 0, 0)
    body:SetWidth(640)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(3)
    pane.body = body
end

local function refreshJournal(f)
    local pane = f.journalPane
    local db = PrestigeClassesCharDB
    local def = db and db.active and PC.ClassById[db.active]
    if not (def and def.trials and PC.Trials) then
        UI.ShowBrowse()
        return
    end

    local Tr = PC.Trials
    local _, title, pending = Tr.RankInfo(def)
    local done, total = Tr.Counts(def)

    pane.title:SetText(GOLD .. "Path Journal — " .. def.name .. R)
    local sub = (FACTION_COLOR[def.faction] or GREY) .. title .. R ..
        GREY .. "  •  " .. done .. "/" .. total .. " deeds done" .. R
    local honorifics = Tr.Honorifics(def)
    if #honorifics > 0 then
        sub = sub .. "\n" .. GOLD .. table.concat(honorifics, " · ") .. R
    end
    if pending then
        sub = sub .. "\n" .. WHITE .. "Next ascension: " .. R .. GREY ..
            pending.name .. R
    end
    local nextUp = Tr.UpNext(def, 3)
    if #nextUp > 0 then
        local parts = {}
        for _, t in ipairs(nextUp) do
            parts[#parts + 1] = (Tr.IsReady(t) and GREEN or GREY) .. t.name ..
                (t.level and (" (~" .. t.level .. ")") or "") .. R
        end
        sub = sub .. "\n" .. WHITE .. "Up next: " .. R ..
            table.concat(parts, GREY .. "  ·  " .. R)
    end
    pane.sub:SetText(sub)

    pane.body:SetText(buildJournalText(def))
    pane.scrollChild:SetHeight(pane.body:GetStringHeight() + 10)
end

-- ------------------------------------------------------------------------
-- Character sheet sidebar: your path, docked to the character panel (C)
-- ------------------------------------------------------------------------
local function createCharacterSidebar()
    if not CharacterFrame then return end
    local panel = CreateFrame("Frame", "PrestigeClassesCharSidebar", CharacterFrame, "BackdropTemplate")
    panel:SetSize(240, 410)
    -- Classic's CharacterFrame texture has transparent padding on the right;
    -- the negative offset tucks the panel against the visible border.
    panel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -34, -13)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    UI.sidebar = panel

    local icon = panel:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34)
    icon:SetPoint("TOPLEFT", 16, -16)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    panel.icon = icon

    local nameFS = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameFS:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1)
    nameFS:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    nameFS:SetJustifyH("LEFT")
    panel.name = nameFS

    local subFS = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subFS:SetPoint("TOPLEFT", nameFS, "BOTTOMLEFT", 0, -3)
    subFS:SetJustifyH("LEFT")
    panel.sub = subFS

    local statusFS = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusFS:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -10)
    statusFS:SetWidth(208)
    statusFS:SetJustifyH("LEFT")
    panel.status = statusFS

    local bodyFS = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyFS:SetPoint("TOPLEFT", statusFS, "BOTTOMLEFT", 0, -8)
    bodyFS:SetWidth(208)
    bodyFS:SetJustifyH("LEFT")
    bodyFS:SetSpacing(2)
    panel.body = bodyFS

    local recordFS = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    recordFS:SetPoint("BOTTOMLEFT", 16, 46)
    recordFS:SetWidth(208)
    recordFS:SetJustifyH("LEFT")
    recordFS:SetSpacing(2)
    panel.record = recordFS

    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(200, 22)
    btn:SetPoint("BOTTOM", 0, 14)
    btn:SetScript("OnClick", function()
        if UI.frame and not UI.frame:IsShown() then UI.Toggle() end
    end)
    panel.btn = btn

    -- Parented to CharacterFrame, so visibility follows it; refresh on open.
    panel:SetScript("OnShow", function() UI.RefreshCharacterSidebar() end)
end

function UI.RefreshCharacterSidebar()
    local panel = UI.sidebar
    if not panel or not panel:IsVisible() then return end

    local db = PrestigeClassesCharDB
    local def = db and db.active and PC.ClassById[db.active]

    if not def then
        panel.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        panel.name:SetText(GOLD .. "No prestige path" .. R)
        panel.sub:SetText(GREY .. "The way is unchosen" .. R)
        panel.status:SetText(GREY .. "Commit to a path and its vows will be watched here." .. R)
        panel.body:SetText("")
        panel.record:SetText(GREY .. "/pc opens the codex" .. R)
        panel.btn:SetText("Choose a path")
        return
    end

    panel.icon:SetTexture(def.icon)
    panel.name:SetText(GOLD .. def.name .. R)
    panel.sub:SetText((FACTION_COLOR[def.faction] or GREY) .. rankText(def) .. R ..
        GREY .. "  •  " .. def.source .. R)

    local results, summary = PC.Compliance.Evaluate(def)
    if summary.compliant then
        panel.status:SetText(GREEN .. "All vows honored (" ..
            summary.rulesPassed .. "/" .. summary.rulesTotal .. ")" .. R)
    elseif not summary.identityOk then
        panel.status:SetText(RED .. "This character can never satisfy this path." .. R)
    else
        panel.status:SetText(RED .. "PATH BROKEN (" ..
            summary.rulesPassed .. "/" .. summary.rulesTotal .. " vows held)" .. R)
    end

    local lines = {}
    for _, r in ipairs(results) do
        local mark = r.ok and MARK_OK or MARK_FAIL
        if r.kind == "info" and not r.ok then mark = MARK_INFO end
        local color = r.ok and WHITE or (r.kind == "info" and GREY or RED)
        lines[#lines + 1] = mark .. " " .. color .. r.label .. R
    end
    if def.trials and PC.Trials then
        local nextUp = PC.Trials.UpNext(def, 3)
        if #nextUp > 0 then
            lines[#lines + 1] = ""
            lines[#lines + 1] = GOLD .. "Deeds up next" .. R
            for _, t in ipairs(nextUp) do
                local ready = PC.Trials.IsReady(t)
                lines[#lines + 1] = (ready and WHITE or GREY) .. "• " ..
                    t.name .. R .. GREY ..
                    (t.level and (" (lvl ~" .. t.level .. ")") or "") ..
                    (t.rankTrial and " — rank trial" or "") .. R
            end
        end
    end
    panel.body:SetText(table.concat(lines, "\n"))

    local rec = {}
    local s = db.stats
    if s then
        rec[#rec + 1] = WHITE .. "Walking this path: " .. R .. GREY .. daysAgoText(s.chosenAt) .. R
        local breaks = s.breaks or 0
        if breaks == 0 then
            rec[#rec + 1] = GREEN .. "Vows never broken." .. R
        else
            rec[#rec + 1] = WHITE .. "Vows broken: " .. R .. RED .. breaks .. R ..
                GREY .. "  (clean " .. daysAgoText(s.lastBreakAt or s.chosenAt) .. ")" .. R
        end
    end
    if def.trials and PC.Trials then
        local done, total = PC.Trials.Counts(def)
        rec[#rec + 1] = WHITE .. "Deeds done: " .. R .. GOLD .. done .. "/" .. total .. R
    end
    panel.record:SetText(table.concat(rec, "\n"))
    panel.btn:SetText("Open Prestige Classes")
end

-- ------------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------------
function UI.ShowBrowse()
    page = "browse"
    UI.Refresh()
end

function UI.ShowDetail(id)
    selectedId = id
    page = "detail"
    UI.Refresh()
end

function UI.ShowJournal()
    page = "journal"
    UI.Refresh()
end

-- Open the window straight onto the journal (slash command entry point).
function UI.OpenJournal()
    local db = PrestigeClassesCharDB
    local def = db and db.active and PC.ClassById[db.active]
    if not (def and def.trials) then
        print("|cffffd100[Prestige]|r " ..
            (def and "The " .. def.name .. "'s journey has not been written yet."
                or "No path chosen. Type |cff40ff40/pc|r to choose one."))
        return
    end
    if UI.frame and not UI.frame:IsShown() then UI.frame:Show() end
    selectedId = def.id
    UI.ShowJournal()
end

function UI.Activate(id)
    local def = PC.ClassById[id]
    if not def then return end
    local already = (PrestigeClassesCharDB.active == id)
    PrestigeClassesCharDB.active = id
    if not already then
        PrestigeClassesCharDB.stats = { chosenAt = time(), breaks = 0 }
        if PC.Trials then PC.Trials.OnPathChanged() end
    end
    PC.Alerts.Reset()
    print("|cffffd100[Prestige]|r You " .. (already and "re-affirm" or "have chosen") ..
        " the path of the " .. def.name .. ". Honor its vows.")
    PC.Refresh() -- triggers Core re-eval + UI refresh
end

function UI.DoAbandon()
    PrestigeClassesCharDB.active = nil
    PrestigeClassesCharDB.stats = nil
    PrestigeClassesCharDB.trials = nil
    PrestigeClassesCharDB.trialsMeta = nil
    if PC.Trials then PC.Trials.InvalidateRank() end
    PC.Alerts.Reset()
    print("|cffffd100[Prestige]|r You have abandoned your prestige path.")
    PC.Refresh()
end

function UI.Abandon()
    local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
    if not activeId then return end
    local def = PC.ClassById[activeId]
    StaticPopup_Show("PRESTIGECLASSES_ABANDON", def and def.name or "?")
end

function UI.Refresh()
    local f = UI.frame
    if not f then return end

    if page == "journal" then
        f.browsePane:Hide()
        f.detailPane:Hide()
        f.journalPane:Show()
        refreshJournal(f)
    elseif page == "detail" and selectedId then
        f.browsePane:Hide()
        f.journalPane:Hide()
        f.detailPane:Show()
        refreshDetail(f)
    else
        f.detailPane:Hide()
        f.journalPane:Hide()
        f.browsePane:Show()
        refreshBrowse(f)
    end
end

function UI.Toggle()
    local f = UI.frame
    if not f then return end
    if f:IsShown() then
        f:Hide()
    else
        -- Open straight onto your active path; browse otherwise.
        local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
        if activeId and PC.ClassById[activeId] then
            selectedId = activeId
            page = "detail"
        else
            page = "browse"
        end
        f:Show()
        UI.Refresh()
    end
end

function UI.Init()
    StaticPopupDialogs["PRESTIGECLASSES_ABANDON"] = {
        text = "Abandon the path of the %s?\n\nYour record on this path will be erased.",
        button1 = YES,
        button2 = NO,
        OnAccept = function() UI.DoAbandon() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local f = createMainFrame()
    createBrowsePane(f)
    createDetailPane(f)
    createJournalPane(f)
    UI.frame = f

    createCharacterSidebar()
end

-- ------------------------------------------------------------------------
-- Minimap button (drag along the ring to reposition)
-- ------------------------------------------------------------------------
function UI.InitMinimap()
    local mb = CreateFrame("Button", "PrestigeClassesMinimapButton", Minimap)
    mb:SetSize(31, 31)
    mb:SetFrameStrata("MEDIUM")
    mb:SetFrameLevel(8)
    mb:RegisterForDrag("LeftButton")

    local icon = mb:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\Ability_Warrior_Challange")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    mb.icon = icon

    local badge = mb:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    badge:SetPoint("TOPRIGHT", 1, 1)
    badge:SetText("|cffff2020!|r")
    badge:Hide()
    mb.badge = badge

    local ring = mb:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(53, 53)
    ring:SetPoint("TOPLEFT")

    local function place(angleDeg)
        local rad = math.rad(angleDeg)
        mb:ClearAllPoints()
        mb:SetPoint("CENTER", Minimap, "CENTER",
            80 * math.cos(rad), 80 * math.sin(rad))
    end
    place(PrestigeClassesCharDB.minimapAngle or 50)

    mb:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            local angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            PrestigeClassesCharDB.minimapAngle = angle
            place(angle)
        end)
    end)
    mb:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    mb:SetScript("OnClick", function() UI.Toggle() end)
    mb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Prestige Classes")
        local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
        if activeId and PC.ClassById[activeId] then
            local def = PC.ClassById[activeId]
            GameTooltip:AddLine("Path: " .. def.name, 1, 0.82, 0)
            if def.trials and PC.Trials then
                local done, total = PC.Trials.Counts(def)
                GameTooltip:AddLine("Deeds: " .. done .. "/" .. total ..
                    "  •  /pc journal", 1, 0.82, 0)
            end
            local s = PC.lastSummary
            if s then
                if s.compliant then
                    GameTooltip:AddLine("All vows honored (" ..
                        s.rulesPassed .. "/" .. s.rulesTotal .. ")", 0.25, 1, 0.25)
                else
                    GameTooltip:AddLine("PATH BROKEN (" ..
                        s.rulesPassed .. "/" .. s.rulesTotal .. " vows held)", 1, 0.25, 0.25)
                end
            end
        else
            GameTooltip:AddLine("No path chosen", 0.6, 0.6, 0.6)
        end
        GameTooltip:AddLine("Click to open  •  Drag to move", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    mb:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UI.minimapButton = mb
end

-- Persistent broken-state signal: alerts fire only on transitions, but the
-- minimap icon stays red and desaturated for as long as any vow is broken
-- (including logging in already broken).
function UI.UpdateMinimap()
    local mb = UI.minimapButton
    if not mb then return end
    local s = PC.lastSummary
    if s and not s.compliant then
        mb.icon:SetDesaturated(true)
        mb.icon:SetVertexColor(1, 0.35, 0.35)
        mb.badge:Show()
    else
        mb.icon:SetDesaturated(false)
        mb.icon:SetVertexColor(1, 1, 1)
        mb.badge:Hide()
    end
end
