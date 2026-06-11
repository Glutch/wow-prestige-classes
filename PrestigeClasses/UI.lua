local ADDON, PC = ...

PC.UI = {}
local UI = PC.UI
local Theme = PC.Theme

-- Inline color escapes (theme palette)
local GOLD = Theme.HEX.gold
local GREY = Theme.HEX.muted
local TEXT = Theme.HEX.text
local TAN = Theme.HEX.tan
local GREEN = Theme.HEX.green
local RED = Theme.HEX.red
local WHITE = Theme.HEX.white
local DIM = Theme.HEX.grey
local R = "|r"

local FACTION_COLOR = {
    Alliance = "|cff5aa0ff",
    Horde = "|cffff5a5a",
    Both = "|cffd0b860",
}
local FACTION_RGB = {
    Alliance = { 0.35, 0.63, 1.00 },
    Horde = { 1.00, 0.35, 0.35 },
    Both = { 0.82, 0.72, 0.38 },
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

-- Window geometry. CONTENT is the usable width inside the margins; panes
-- lay their scroll children out at SCROLLW to leave the thumb a gutter.
local WIN_W, WIN_H = 880, 660
local PAD = 26
local CONTENT = WIN_W - PAD * 2 -- 828
local SCROLLW = CONTENT - 18    -- 810

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

local function itemIcon(id)
    if GetItemIcon then return GetItemIcon(id) end
    return C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
end

-- ------------------------------------------------------------------------
-- Detail page text builders
-- ------------------------------------------------------------------------
local function buildReqText(def)
    local results = PC.Compliance.Evaluate(def)
    local lines = {}
    for _, r in ipairs(results) do
        local mark = r.ok and MARK_OK or MARK_FAIL
        if r.kind == "info" and not r.ok then mark = MARK_INFO end
        local color = r.ok and TEXT or (r.kind == "info" and GREY or RED)
        lines[#lines + 1] = mark .. " " .. color .. r.label .. R
        if r.detail and r.detail ~= "" then
            lines[#lines + 1] = "      " .. GREY .. r.detail .. R
        end
    end
    return table.concat(lines, "\n")
end

local function buildVowText(def)
    local lines = {}
    lines[#lines + 1] = GREY .. "Honor rules the addon cannot see. Your word is the only enforcement." .. R
    lines[#lines + 1] = ""
    for _, h in ipairs(def.honorRules) do
        lines[#lines + 1] = GOLD .. "•" .. R .. " " .. TEXT .. h .. R
    end

    local db = PrestigeClassesCharDB
    if db and db.active == def.id and db.stats then
        local s = db.stats
        lines[#lines + 1] = ""
        lines[#lines + 1] = GOLD .. "Your record" .. R
        lines[#lines + 1] = TEXT .. "Walking this path: " .. R .. GREY .. daysAgoText(s.chosenAt) .. R
        local breaks = s.breaks or 0
        if breaks == 0 then
            lines[#lines + 1] = GREEN .. "Vows never broken." .. R
        else
            lines[#lines + 1] = TEXT .. "Vows broken: " .. R .. RED .. breaks .. R
            lines[#lines + 1] = GREY .. "Clean for " .. daysAgoText(s.lastBreakAt or s.chosenAt) .. R
        end
        if def.trials and PC.Trials then
            local done, total = PC.Trials.Counts(def)
            lines[#lines + 1] = TEXT .. "Deeds done: " .. R .. GOLD ..
                done .. "/" .. total .. R .. GREY .. " — see the Path Journal" .. R
        end
    end
    return table.concat(lines, "\n")
end

-- ------------------------------------------------------------------------
-- Browse page: every path, grouped by WoW class, as a card grid
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

local CARD_W = (SCROLLW - 12) / 2
local CARD_H = 54

local function pathCard(parent, def)
    local card = Theme.Panel(parent)
    card:SetSize(CARD_W, CARD_H)

    local slot = Theme.IconSlot(card, 36)
    slot:SetPoint("LEFT", 10, 0)
    slot:EnableMouse(false)
    slot.icon:SetTexture(def.icon)
    card.slot = slot

    card.nameFS = Theme.Text(card, "display", 13)
    card.nameFS:SetPoint("TOPLEFT", slot, "TOPRIGHT", 10, -2)
    card.nameFS:SetWidth(CARD_W - 140)

    card.raceFS = Theme.Text(card, "body", 10, Theme.COLOR.muted)
    card.raceFS:SetPoint("BOTTOMLEFT", slot, "BOTTOMRIGHT", 10, 2)
    card.raceFS:SetWidth(CARD_W - 140)

    card.sideFS = Theme.Text(card, "body", 10, Theme.COLOR.muted)
    card.sideFS:SetPoint("RIGHT", -12, 0)
    card.sideFS:SetJustifyH("RIGHT")

    -- click/hover surface above the card art
    local hit = CreateFrame("Button", nil, card)
    hit:SetAllPoints()
    hit:SetScript("OnClick", function() UI.ShowDetail(def.id) end)
    hit:SetScript("OnEnter", function()
        local g = Theme.COLOR.gold
        card.border.SetColor(g[1], g[2], g[3], 0.9)
        GameTooltip:SetOwner(card, "ANCHOR_RIGHT")
        GameTooltip:AddLine(def.name, 1, 0.82, 0)
        GameTooltip:AddLine(def.fantasy, 0.88, 0.84, 0.78, true)
        if not card.eligible then
            GameTooltip:AddLine("Not available to this character.", 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end)
    hit:SetScript("OnLeave", function()
        local rb = card.restBorder or Theme.COLOR.border
        card.border.SetColor(rb[1], rb[2], rb[3], rb[4])
        GameTooltip:Hide()
    end)

    card.def = def
    card.eligible = PC.Compliance.Eligible(def)
    return card
end

local function createBrowsePane(f)
    local pane = CreateFrame("Frame", nil, f)
    pane:SetPoint("TOPLEFT", PAD, -54)
    pane:SetPoint("BOTTOMRIGHT", -PAD, 22)
    Theme.Rise(pane)
    f.browsePane = pane

    local eyebrow = Theme.Text(pane, "display", 10, Theme.COLOR.muted)
    eyebrow:SetPoint("TOPLEFT", 0, 0)
    eyebrow:SetText(Theme.Spaced("The Codex"))

    local heading = Theme.Text(pane, "display", 21, Theme.COLOR.gold)
    heading:SetPoint("TOPLEFT", 0, -16)
    heading:SetText("Choose Your Path")

    local sub = Theme.Text(pane, "body", 12, Theme.COLOR.muted)
    sub:SetPoint("TOPRIGHT", pane, "TOPRIGHT", 0, -26)
    sub:SetJustifyH("RIGHT")
    sub:SetText(#PC.Classes .. " prestige paths · vows watched live")

    local scroll, child = Theme.Scroll(pane, "PrestigeClassesBrowseScroll")
    scroll:SetPoint("TOPLEFT", 0, -56)
    scroll:SetPoint("BOTTOMRIGHT", 0, 40)
    child:SetWidth(SCROLLW)
    pane.scroll = scroll

    local y = 0
    pane.cards = {}
    for _, group in ipairs(groupedClasses()) do
        local header = Theme.Text(child, "display", 13)
        header:SetPoint("TOPLEFT", 0, y)
        header:SetText(classColorStr(group.token) .. classDisplayName(group.token) .. R ..
            GREY .. "   " .. #group.defs .. (#group.defs == 1 and " path" or " paths") .. R)
        y = y - 22

        local rule = Theme.Divider(child, 0.25)
        rule:SetPoint("TOPLEFT", 0, y)
        rule:SetWidth(SCROLLW)
        y = y - 10

        local col = 0
        for _, def in ipairs(group.defs) do
            local card = pathCard(child, def)
            card:SetPoint("TOPLEFT", col * (CARD_W + 12), y)
            pane.cards[#pane.cards + 1] = card
            col = col + 1
            if col == 2 then
                col = 0
                y = y - (CARD_H + 10)
            end
        end
        if col > 0 then y = y - (CARD_H + 10) end
        y = y - 16
    end
    child:SetHeight(math.abs(y) + 8)

    local surprise = Theme.Button(pane, "Surprise Me")
    surprise:SetPoint("BOTTOM", 0, 0)
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

    for _, card in ipairs(f.browsePane.cards) do
        local def = card.def
        local color = card.eligible and FACTION_COLOR[def.faction] or INELIGIBLE
        local suffix = ""
        if def.id == activeId then
            suffix = activeOk and (" " .. MARK_OK) or (" " .. MARK_FAIL)
            card.restBorder = { 1, 0.82, 0, 0.7 }
        else
            card.restBorder = Theme.COLOR.border
        end
        local rb = card.restBorder
        card.border.SetColor(rb[1], rb[2], rb[3], rb[4])
        card.nameFS:SetText((def.id == activeId and (GOLD .. "★ " .. R) or "") ..
            color .. def.name .. R .. suffix)
        card.raceFS:SetText(raceReqText(def))
        card.sideFS:SetText((FACTION_COLOR[def.faction] or GREY) ..
            def.faction:upper() .. R)
        card.slot.icon:SetDesaturated(not card.eligible)
        card:SetAlpha(card.eligible and 1 or 0.55)
    end
    f.browsePane.scroll.UpdateThumb()
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
    b = Theme.IconSlot(pane.scrollChild, 34)
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

-- Lays out both strips below the two panels; takes and returns the running
-- y cursor on the scroll child.
local ITEMS_PER_ROW = 19

local function layoutItemStrips(pane, def, y)
    for _, b in ipairs(pane.itemButtons) do b:Hide() end
    for _, h in ipairs(pane.itemHeaders) do h:Hide() end
    local n, hn = 0, 0
    local function header(text)
        hn = hn + 1
        local h = pane.itemHeaders[hn]
        if not h then
            h = Theme.Text(pane.scrollChild, "display", 10, Theme.COLOR.muted)
            pane.itemHeaders[hn] = h
        end
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", 0, y)
        h:SetText(text)
        h:Show()
        y = y - 24
    end
    local function strip(entries)
        local col = 0
        for _, e in ipairs(entries) do
            n = n + 1
            local b = itemButton(pane, n)
            b.itemId, b.note = e.id, e.note
            b.icon:SetTexture(itemIcon(e.id) or QUESTION_ICON)
            b.SetQualityByItem(e.id)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", col * 42, y)
            b:Show()
            -- Warm the item cache so the first hover shows a real tooltip.
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(e.id)
            end
            col = col + 1
            if col >= ITEMS_PER_ROW then col = 0; y = y - 42 end
        end
        if col > 0 then y = y - 42 end
        y = y - 10
    end
    local spoils = collectSpoils(def)
    if #spoils > 0 then
        header(Theme.Spaced("Spoils of the Path") ..
            GREY .. "   what the deeds award" .. R)
        strip(spoils)
    end
    if def.suggestedItems and #def.suggestedItems > 0 then
        header(Theme.Spaced("Suggested Arms") ..
            GREY .. "   worth chasing along the way" .. R)
        strip(def.suggestedItems)
    end
    return y
end

-- ------------------------------------------------------------------------
-- Detail page: one path, full window. Hero block up top, panels below.
-- ------------------------------------------------------------------------
local REQ_W = 500
local VOW_W = SCROLLW - REQ_W - 12

local function createDetailPane(f)
    local pane = CreateFrame("Frame", nil, f)
    pane:SetPoint("TOPLEFT", PAD, -50)
    pane:SetPoint("BOTTOMRIGHT", -PAD, 22)
    pane:Hide()
    Theme.Rise(pane)
    f.detailPane = pane

    local back = Theme.LinkButton(pane, "< All Paths")
    back:SetPoint("TOPLEFT", 0, 0)
    back:SetScript("OnClick", function() UI.ShowBrowse() end)

    local slot = Theme.IconSlot(pane, 56)
    slot:SetPoint("TOPLEFT", 0, -28)
    slot:EnableMouse(false)
    pane.heroSlot = slot
    pane.heroGlow = Theme.EmberPulse(pane, slot, 110)

    local nameFS = Theme.Text(pane, "display", 24, Theme.COLOR.gold)
    nameFS:SetPoint("TOPLEFT", slot, "TOPRIGHT", 16, -2)
    pane.name = nameFS

    local subFS = Theme.Text(pane, "body", 11, Theme.COLOR.muted)
    subFS:SetPoint("TOPLEFT", nameFS, "BOTTOMLEFT", 1, -6)
    pane.sub = subFS

    -- mentor's voice: gold-barred lore block, full width
    local loreBar = Theme.Solid(pane, "ARTWORK", 1, 0.82, 0, 0.3)
    loreBar:SetWidth(2)
    pane.loreBar = loreBar
    local fantasyFS = Theme.Text(pane, "italic", 13, Theme.COLOR.tan)
    fantasyFS:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 12, -14)
    fantasyFS:SetWidth(CONTENT - 12)
    fantasyFS:SetSpacing(3)
    loreBar:SetPoint("TOPLEFT", fantasyFS, "TOPLEFT", -12, 1)
    loreBar:SetPoint("BOTTOMLEFT", fantasyFS, "BOTTOMLEFT", -12, -1)
    pane.fantasy = fantasyFS

    local statusFS = Theme.Text(pane, "display", 11)
    statusFS:SetPoint("TOPLEFT", fantasyFS, "BOTTOMLEFT", -12, -10)
    statusFS:SetWidth(CONTENT)
    pane.status = statusFS

    local scroll, child = Theme.Scroll(pane, "PrestigeClassesDetailScroll")
    scroll:SetPoint("TOPLEFT", statusFS, "BOTTOMLEFT", 0, -12)
    scroll:SetPoint("BOTTOMRIGHT", 0, 44)
    child:SetWidth(SCROLLW)
    pane.scroll = scroll
    pane.scrollChild = child

    -- requirements panel (anchored in refreshDetail, below the item strips)
    local reqPanel = Theme.Panel(child)
    reqPanel:SetWidth(REQ_W)
    pane.reqPanel = reqPanel
    local reqHead = Theme.Text(reqPanel, "display", 10, Theme.COLOR.muted)
    reqHead:SetPoint("TOPLEFT", 14, -12)
    reqHead:SetText(Theme.Spaced("The Requirements"))
    local reqText = Theme.Text(reqPanel, "body", 12)
    reqText:SetPoint("TOPLEFT", 14, -32)
    reqText:SetWidth(REQ_W - 28)
    reqText:SetJustifyV("TOP")
    reqText:SetSpacing(4)
    pane.reqText = reqText

    -- vows panel
    local vowPanel = Theme.Panel(child)
    vowPanel:SetWidth(VOW_W)
    pane.vowPanel = vowPanel
    local vowHead = Theme.Text(vowPanel, "display", 10, Theme.COLOR.muted)
    vowHead:SetPoint("TOPLEFT", 14, -12)
    vowHead:SetWidth(VOW_W - 28)
    vowHead:SetText(Theme.Spaced("The Code"))
    local vowText = Theme.Text(vowPanel, "body", 12)
    vowText:SetPoint("TOPLEFT", 14, -32)
    vowText:SetWidth(VOW_W - 28)
    vowText:SetJustifyV("TOP")
    vowText:SetSpacing(4)
    pane.vowText = vowText

    pane.itemButtons = {}
    pane.itemHeaders = {}

    local activate = Theme.Button(pane, "Walk This Path", true)
    activate:SetPoint("BOTTOMLEFT", 0, 0)
    activate:SetScript("OnClick", function()
        if selectedId then UI.Activate(selectedId) end
    end)
    pane.activateBtn = activate

    local abandon = Theme.Button(pane, "Abandon Path")
    abandon:SetPoint("LEFT", activate, "RIGHT", 12, 0)
    abandon:SetScript("OnClick", function() UI.Abandon() end)
    pane.abandonBtn = abandon

    local journal = Theme.Button(pane, "Path Journal")
    journal:SetPoint("LEFT", abandon, "RIGHT", 12, 0)
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

    pane.heroSlot.icon:SetTexture(def.icon)
    pane.name:SetText(def.name)
    pane.sub:SetText(GREY .. def.source:upper() .. "   ·   " .. R ..
        (FACTION_COLOR[def.faction] or GREY) .. def.faction:upper() .. R ..
        GREY .. "   ·   " .. raceReqText(def):upper() .. R)
    pane.fantasy:SetText(def.fantasy)

    local _, summary = PC.Compliance.Evaluate(def)
    if activeId == def.id then
        local rank = rankText(def)
        if summary.compliant then
            pane.status:SetText(GREEN .. Theme.Spaced("Active") .. "   " .. R ..
                TEXT .. rank .. " of this path — all vows honored (" ..
                summary.rulesPassed .. "/" .. summary.rulesTotal .. ")" .. R)
            pane.heroGlow:SetVertexColor(1, 0.42, 0.16, 0.35)
        elseif not summary.identityOk then
            pane.status:SetText(RED .. Theme.Spaced("Active") ..
                "   this character can never satisfy this path" .. R)
            pane.heroGlow:SetVertexColor(1, 0.2, 0.2, 0.4)
        else
            pane.status:SetText(RED .. Theme.Spaced("Path Broken") .. "   " ..
                summary.rulesPassed .. "/" .. summary.rulesTotal .. " vows held" .. R)
            pane.heroGlow:SetVertexColor(1, 0.2, 0.2, 0.4)
        end
    elseif not PC.Compliance.Eligible(def) then
        pane.status:SetText(DIM .. Theme.Spaced("Closed") ..
            "   not available to this character (race/class)" .. R)
        pane.heroGlow:SetVertexColor(0.5, 0.5, 0.5, 0.15)
    else
        pane.status:SetText(GREY .. Theme.Spaced("Open To You") .. "   " ..
            R .. TAN .. "read the vows, then commit" .. R)
        pane.heroGlow:SetVertexColor(1, 0.42, 0.16, 0.25)
    end

    pane.reqText:SetText(buildReqText(def))
    pane.vowText:SetText(buildVowText(def))
    pane.reqPanel:SetHeight(pane.reqText:GetStringHeight() + 46)
    pane.vowPanel:SetHeight(pane.vowText:GetStringHeight() + 46)

    -- item strips first, the two panels below them
    local y = layoutItemStrips(pane, def, 0)
    pane.reqPanel:ClearAllPoints()
    pane.reqPanel:SetPoint("TOPLEFT", 0, y)
    pane.vowPanel:ClearAllPoints()
    pane.vowPanel:SetPoint("TOPLEFT", REQ_W + 12, y)
    local panelBottom = math.max(pane.reqPanel:GetHeight(), pane.vowPanel:GetHeight())
    pane.scrollChild:SetHeight(-y + panelBottom + 10)
    -- jump to the top on a new path, but keep the reader's place on the
    -- live re-evals Core fires while the window is open
    if pane.shownId ~= def.id then
        pane.scroll.ResetScroll()
        pane.shownId = def.id
    else
        pane.scroll.UpdateThumb()
    end

    if activeId == def.id then
        pane.activateBtn.SetLabel("Re-Affirm Vows")
    else
        pane.activateBtn.SetLabel("Walk This Path")
    end
    pane.activateBtn:SetEnabled(PC.Compliance.Eligible(def))
    pane.abandonBtn:SetEnabled(activeId ~= nil)
    pane.journalBtn:SetShown(activeId == def.id and def.trials ~= nil)
end

-- ------------------------------------------------------------------------
-- Journal page: the active path's chapters as a journey down the road —
-- gold waypoints, deed cards, live progress bars.
-- ------------------------------------------------------------------------
local ROMAN = { "I", "II", "III", "IV" }

local function chapterTitle(def, c)
    local t = def.trialChapters and def.trialChapters[c]
    if t then return t end
    if c == 0 then return "The Long Watch" end
    return "Chapter " .. ROMAN[c] .. " — the " .. PC.Trials.RANK_TITLES[c]
end

-- Deed-kind fallback icons (equip/loot/cast prefer the item's own icon).
local KIND_ICON = {
    kill = "Interface\\Icons\\Ability_Warrior_DecisiveStrike",
    counter = "Interface\\Icons\\INV_Misc_Book_07",
    proc = "Interface\\Icons\\Spell_Frost_Stun",
    multihit = "Interface\\Icons\\Ability_Whirlwind",
    crit = "Interface\\Icons\\Ability_CriticalStrike",
    loot = "Interface\\Icons\\INV_Misc_Bag_10",
    equip = "Interface\\Icons\\INV_Sword_06",
    cast = "Interface\\Icons\\Trade_BlackSmithing",
    emote = "Interface\\Icons\\INV_Misc_Note_02",
    visit = "Interface\\Icons\\INV_Misc_Map_01",
}

local function trialIcon(def, trial)
    local ids = def.itemIds
    if ids then
        local name = (trial.items and trial.items[1]) or trial.item or
            (trial.kind == "cast" and trial.spell)
        local id = name and ids[name]
        if id then
            local tex = itemIcon(id)
            if tex then return tex end
        end
    end
    return KIND_ICON[trial.kind] or QUESTION_ICON
end

local DEED_W = SCROLLW - 28   -- cards sit right of the road
local DEED_TEXT_W = DEED_W - 24

-- One reusable deed card. layoutDeedCard() fills it and returns its height.
local function deedCard(pane, i)
    local card = pane.deedCards[i]
    if card then return card end
    card = Theme.Panel(pane.scrollChild)
    card:SetWidth(DEED_W)

    card.slot = Theme.IconSlot(card, 36)
    card.slot:SetPoint("TOPLEFT", 12, -12)
    card.slot:EnableMouse(false)

    card.check = card:CreateTexture(nil, "OVERLAY")
    card.check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
    card.check:SetSize(18, 18)
    card.check:SetPoint("BOTTOMRIGHT", card.slot, "BOTTOMRIGHT", 5, -5)

    card.title = Theme.Text(card, "display", 13)
    card.title:SetPoint("TOPLEFT", card.slot, "TOPRIGHT", 10, -1)
    card.title:SetWidth(DEED_W - 36 - 36)

    card.chipHolder = CreateFrame("Frame", nil, card)
    card.chipHolder:SetAllPoints()

    card.objective = Theme.Text(card, "body", 12)
    card.objective:SetPoint("TOPLEFT", card.slot, "BOTTOMLEFT", 0, -10)
    card.objective:SetWidth(DEED_TEXT_W)
    card.objective:SetSpacing(3)

    card.loreBar = Theme.Solid(card, "ARTWORK", 1, 0.82, 0, 0.3)
    card.loreBar:SetWidth(2)
    card.lore = Theme.Text(card, "italic", 12, Theme.COLOR.tan)
    card.lore:SetWidth(DEED_TEXT_W - 12)
    card.lore:SetSpacing(3)
    card.lore:SetPoint("TOPLEFT", card.objective, "BOTTOMLEFT", 12, -8)
    card.loreBar:SetPoint("TOPLEFT", card.lore, "TOPLEFT", -12, 1)
    card.loreBar:SetPoint("BOTTOMLEFT", card.lore, "BOTTOMLEFT", -12, -1)

    card.bar = Theme.ProgressBar(card, 230, 11)
    card.mileHolder = CreateFrame("Frame", nil, card)
    card.mileHolder:SetAllPoints()
    card.countFS = Theme.Text(card, "body", 12, Theme.COLOR.gold)

    card.honor = Theme.Text(card, "body", 11, Theme.COLOR.gold)
    card.honor:SetWidth(DEED_TEXT_W)

    pane.deedCards[i] = card
    return card
end

local function layoutDeedCard(card, def, trial, locked)
    local Tr = PC.Trials
    local s = Tr.State(trial.id)
    local progress = s and s.progress or 0
    local complete = (not locked) and Tr.IsComplete(trial)

    card.slot.icon:SetTexture(trialIcon(def, trial))
    card.slot.icon:SetDesaturated(locked)
    card.check:SetShown(complete)

    if complete then
        card.title:SetTextColor(0.12, 1, 0)
        card.border.SetColor(0.12, 0.8, 0.1, 0.45)
    elseif locked then
        card.title:SetTextColor(0.45, 0.42, 0.38)
        local b = Theme.COLOR.border
        card.border.SetColor(b[1], b[2], b[3], 0.4)
    else
        local t = Theme.COLOR.text
        card.title:SetTextColor(t[1], t[2], t[3])
        local b = Theme.COLOR.border
        card.border.SetColor(b[1], b[2], b[3], b[4])
    end
    card.title:SetText(trial.name)

    -- chips along the title
    local chips = {}
    if trial.level then
        local ready = locked or Tr.IsReady(trial)
        chips[#chips + 1] = { "Lvl " .. trial.level,
            ready and Theme.COLOR.muted or Theme.COLOR.red }
    end
    chips[#chips + 1] = { trial.kind, Theme.COLOR.muted }
    if trial.rankTrial then chips[#chips + 1] = { "Rank Trial", Theme.COLOR.gold } end
    if trial.solo then chips[#chips + 1] = { "Solo", Theme.COLOR.red } end
    if trial.cleanOnly then chips[#chips + 1] = { "Untouched", Theme.COLOR.red } end
    Theme.ChipRow(card.chipHolder, card.title, "TOPLEFT", "BOTTOMLEFT", 0, -5, chips)

    card.objective:SetText((locked and DIM or TEXT) .. trial.objective .. R)

    local hasLore = trial.text and not locked
    if hasLore then
        card.lore:SetText("\"" .. trial.text .. "\"")
        card.lore:Show()
        card.loreBar:Show()
    else
        card.lore:SetText("")
        card.lore:Hide()
        card.loreBar:Hide()
    end

    -- progress row: bar for finite deeds, count + milestone chips for
    -- lifelong counters
    local target = Tr.Target(trial)
    local rowAnchor = hasLore and card.lore or card.objective
    local rowH = 0
    card.bar:Hide()
    card.countFS:SetText("")
    local mileChips = {}
    if not locked then
        if trial.milestones then
            card.countFS:ClearAllPoints()
            card.countFS:SetPoint("TOPLEFT", rowAnchor, "BOTTOMLEFT",
                hasLore and -12 or 0, -10)
            card.countFS:SetText("Count: " .. progress)
            for _, m in ipairs(trial.milestones) do
                mileChips[#mileChips + 1] = {
                    (m.honorific or "?") .. " · " .. m.count,
                    progress >= m.count and Theme.COLOR.green or Theme.COLOR.muted,
                }
            end
            Theme.ChipRow(card.mileHolder, card.countFS, "LEFT", "RIGHT", 12, 0, mileChips)
            rowH = 24
        elseif target > 1 then
            card.bar:ClearAllPoints()
            card.bar:SetPoint("TOPLEFT", rowAnchor, "BOTTOMLEFT",
                hasLore and -12 or 0, -10)
            card.bar.SetProgress(math.min(progress, target), target)
            card.bar:Show()
            rowH = 25
        end
    end
    if #mileChips == 0 then
        Theme.ChipRow(card.mileHolder, card.countFS, "LEFT", "RIGHT", 12, 0, {})
    end

    local honorText = ""
    if complete and trial.honorific then
        honorText = Theme.Spaced("Honorific Earned") .. "   " .. trial.honorific
        if complete and trial.completionNote then
            honorText = honorText .. "\n" .. GREY .. trial.completionNote .. R
        end
    elseif complete and trial.completionNote then
        honorText = GREY .. trial.completionNote .. R
    end
    card.honor:SetText(honorText)
    local honorH = honorText ~= "" and (card.honor:GetStringHeight() + 8) or 0
    if honorText ~= "" then
        card.honor:ClearAllPoints()
        card.honor:SetPoint("TOPLEFT", rowAnchor, "BOTTOMLEFT",
            hasLore and -12 or 0, -(rowH > 0 and rowH + 10 or 10))
    end

    local h = 12 + 36 + 10 + card.objective:GetStringHeight()
    if hasLore then h = h + 8 + card.lore:GetStringHeight() end
    if rowH > 0 then h = h + 10 + rowH end
    h = h + honorH + 14
    card:SetHeight(h)
    card:SetAlpha(locked and 0.45 or 1)
    return h
end

local function createJournalPane(f)
    local pane = CreateFrame("Frame", nil, f)
    pane:SetPoint("TOPLEFT", PAD, -50)
    pane:SetPoint("BOTTOMRIGHT", -PAD, 22)
    pane:Hide()
    Theme.Rise(pane)
    f.journalPane = pane

    local back = Theme.LinkButton(pane, "< The Path")
    back:SetPoint("TOPLEFT", 0, 0)
    back:SetScript("OnClick", function()
        local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
        if activeId then UI.ShowDetail(activeId) else UI.ShowBrowse() end
    end)

    local eyebrow = Theme.Text(pane, "display", 10, Theme.COLOR.muted)
    eyebrow:SetPoint("TOPLEFT", 0, -26)
    eyebrow:SetText(Theme.Spaced("Path Journal"))

    local title = Theme.Text(pane, "display", 20, Theme.COLOR.gold)
    title:SetPoint("TOPLEFT", 0, -42)
    pane.title = title

    pane.deedsBar = Theme.ProgressBar(pane, 240, 12)
    pane.deedsBar:SetPoint("TOPRIGHT", 0, -46)
    local barHead = Theme.Text(pane, "display", 9, Theme.COLOR.muted)
    barHead:SetPoint("BOTTOMRIGHT", pane.deedsBar, "TOPRIGHT", 0, 5)
    barHead:SetText(Theme.Spaced("Deeds Done"))

    local sub = Theme.Text(pane, "body", 12, Theme.COLOR.muted)
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -6)
    sub:SetWidth(CONTENT - 260)
    sub:SetSpacing(3)
    pane.sub = sub

    pane.honorHolder = CreateFrame("Frame", nil, pane)
    pane.honorHolder:SetAllPoints()

    -- top hangs from the sub text so a wrapped "up next" line or a row of
    -- honorific chips pushes the scroll region down instead of under it
    local scroll, child = Theme.Scroll(pane, "PrestigeClassesJournalScroll")
    scroll:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -1, -36)
    scroll:SetPoint("BOTTOMRIGHT", 0, 0)
    child:SetWidth(SCROLLW)
    pane.scroll = scroll
    pane.scrollChild = child

    -- the road: a faint gold line the chapters hang from
    local road = Theme.Solid(child, "BACKGROUND", 1, 0.82, 0, 0.18)
    road:SetWidth(1)
    road:SetPoint("TOPLEFT", 7, -8)
    pane.road = road

    pane.deedCards = {}
    pane.chapterHeads = {}
end

-- Chapter heading with the gold waypoint diamond; returns its height.
local function chapterHead(pane, i)
    local h = pane.chapterHeads[i]
    if h then return h end
    h = CreateFrame("Frame", nil, pane.scrollChild)
    h:SetSize(SCROLLW, 40)

    -- waypoint diamond: SetRotation only spins texcoords (invisible on a
    -- flat color), so pinch the quad's corners to edge midpoints instead
    h.dot = Theme.Solid(h, "ARTWORK", 1, 0.82, 0, 0.9)
    h.dot:SetSize(11, 11)
    h.dot:SetPoint("TOPLEFT", 2, -5)
    if h.dot.SetVertexOffset then
        h.dot:SetVertexOffset(1, 5.5, 0)  -- upper-left  -> top point
        h.dot:SetVertexOffset(2, 0, 5.5)  -- lower-left  -> left point
        h.dot:SetVertexOffset(3, 0, -5.5) -- upper-right -> right point
        h.dot:SetVertexOffset(4, -5.5, 0) -- lower-right -> bottom point
    end

    h.title = Theme.Text(h, "display", 15, Theme.COLOR.gold)
    h.title:SetPoint("TOPLEFT", 28, 0)
    h.title:SetWidth(SCROLLW - 28)

    h.tag = Theme.Text(h, "display", 9, Theme.COLOR.muted)
    h.tag:SetPoint("TOPLEFT", h.title, "BOTTOMLEFT", 1, -4)

    pane.chapterHeads[i] = h
    return h
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
    local rank, title, pending = Tr.RankInfo(def)
    local done, total = Tr.Counts(def)

    pane.title:SetText(def.name)
    pane.deedsBar.SetProgress(done, total)

    local sub = (FACTION_COLOR[def.faction] or GREY) .. title .. R
    if pending then
        sub = sub .. GREY .. "   ·   next ascension: " .. R .. TEXT ..
            pending.name .. R
    end
    local nextUp = Tr.UpNext(def, 3)
    if #nextUp > 0 then
        local parts = {}
        for _, t in ipairs(nextUp) do
            parts[#parts + 1] = (Tr.IsReady(t) and GREEN or GREY) .. t.name ..
                (t.level and (" (~" .. t.level .. ")") or "") .. R
        end
        sub = sub .. "\n" .. GREY .. "up next:  " .. R ..
            table.concat(parts, GREY .. "  ·  " .. R)
    end
    pane.sub:SetText(sub)

    local honorifics = Tr.Honorifics(def)
    local chips = {}
    for _, hon in ipairs(honorifics) do
        chips[#chips + 1] = { hon, Theme.COLOR.gold }
    end
    Theme.ChipRow(pane.honorHolder, pane.sub, "TOPLEFT", "BOTTOMLEFT", -1, -8, chips)

    -- chapters + deed cards down the road
    for _, c in ipairs(pane.deedCards) do c:Hide() end
    for _, h in ipairs(pane.chapterHeads) do h:Hide() end

    local y = 0
    local nCard, nHead = 0, 0
    for chapter = 0, 4 do
        local entries = {}
        for _, trial in ipairs(def.trials) do
            if (trial.chapter or 0) == chapter then
                entries[#entries + 1] = trial
            end
        end
        if #entries > 0 then
            local locked = chapter > 0 and rank < chapter
            nHead = nHead + 1
            local head = chapterHead(pane, nHead)
            head:ClearAllPoints()
            head:SetPoint("TOPLEFT", 0, y)
            head.title:SetText(chapterTitle(def, chapter))
            if locked then
                head.title:SetTextColor(0.45, 0.42, 0.38)
                head.dot:SetVertexColor(0.4, 0.36, 0.3, 0.8)
                head.tag:SetText(Theme.Spaced("Locked — Ascend to " ..
                    Tr.RANK_TITLES[chapter]))
                head.tag:SetTextColor(0.55, 0.4, 0.35)
            else
                head.title:SetTextColor(1, 0.82, 0)
                head.dot:SetVertexColor(1, 0.82, 0, 0.9)
                local doneIn, totalIn = 0, #entries
                for _, t in ipairs(entries) do
                    if Tr.IsComplete(t) then doneIn = doneIn + 1 end
                end
                head.tag:SetText(Theme.Spaced(doneIn .. " of " .. totalIn .. " deeds done"))
                local m = Theme.COLOR.muted
                head.tag:SetTextColor(m[1], m[2], m[3])
            end
            -- breathing waypoint on the chapter you are walking now
            if not head.pulse then
                head.pulse = Theme.EmberPulse(head, head.dot, 38)
            end
            head.pulse:SetShown(not locked and chapter == rank)
            head:Show()
            y = y - 42

            for _, trial in ipairs(entries) do
                nCard = nCard + 1
                local card = deedCard(pane, nCard)
                card:ClearAllPoints()
                card:SetPoint("TOPLEFT", 28, y)
                local h = layoutDeedCard(card, def, trial, locked)
                card:Show()
                y = y - h - 10
            end
            y = y - 14
        end
    end
    pane.scrollChild:SetHeight(-y + 8)
    pane.road:SetHeight(-y - 20)
    pane.scroll.UpdateThumb()
end

-- ------------------------------------------------------------------------
-- Character sheet sidebar: your path, docked to the character panel (C)
-- ------------------------------------------------------------------------
local function createCharacterSidebar()
    if not CharacterFrame then return end
    local panel = Theme.Panel(CharacterFrame)
    panel:SetWidth(240)
    -- Classic's CharacterFrame texture has transparent padding on the right
    -- and below; the negative offsets tuck the panel against the visible
    -- border and run it the full height of the sheet.
    panel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -34, -13)
    panel:SetPoint("BOTTOMLEFT", CharacterFrame, "BOTTOMRIGHT", -34, 76)
    UI.sidebar = panel

    local slot = Theme.IconSlot(panel, 34)
    slot:SetPoint("TOPLEFT", 14, -14)
    slot:EnableMouse(false)
    panel.slot = slot

    local nameFS = Theme.Text(panel, "display", 13, Theme.COLOR.gold)
    nameFS:SetPoint("TOPLEFT", slot, "TOPRIGHT", 9, -1)
    nameFS:SetWidth(169)
    panel.name = nameFS

    local subFS = Theme.Text(panel, "body", 10, Theme.COLOR.muted)
    subFS:SetPoint("TOPLEFT", nameFS, "BOTTOMLEFT", 0, -3)
    subFS:SetWidth(169)
    panel.sub = subFS

    local rule = Theme.Divider(panel, 0.3)
    rule:SetPoint("TOPLEFT", 14, -56)
    rule:SetWidth(212)

    local statusFS = Theme.Text(panel, "display", 10)
    statusFS:SetPoint("TOPLEFT", 14, -66)
    statusFS:SetWidth(212)
    panel.status = statusFS

    local bodyFS = Theme.Text(panel, "body", 11)
    bodyFS:SetPoint("TOPLEFT", statusFS, "BOTTOMLEFT", 0, -8)
    bodyFS:SetWidth(212)
    bodyFS:SetSpacing(3)
    panel.body = bodyFS

    local recordFS = Theme.Text(panel, "body", 11)
    recordFS:SetPoint("BOTTOMLEFT", 14, 84)
    recordFS:SetWidth(212)
    recordFS:SetSpacing(3)
    panel.record = recordFS

    local deedsHead = Theme.Text(panel, "display", 9, Theme.COLOR.muted)
    deedsHead:SetPoint("BOTTOMLEFT", 14, 62)
    deedsHead:SetText(Theme.Spaced("Deeds Done"))
    panel.deedsHead = deedsHead

    local deedsBar = Theme.ProgressBar(panel, 212, 11)
    deedsBar:SetPoint("BOTTOMLEFT", 14, 46)
    panel.deedsBar = deedsBar

    local codexBtn = Theme.Button(panel, "Codex")
    codexBtn:SetSize(102, 24)
    codexBtn:SetPoint("BOTTOMLEFT", 14, 14)
    codexBtn:SetScript("OnClick", function()
        if UI.frame and not UI.frame:IsShown() then UI.Toggle() end
    end)
    panel.codexBtn = codexBtn

    local pathBtn = Theme.Button(panel, "Path")
    pathBtn:SetSize(102, 24)
    pathBtn:SetPoint("BOTTOMRIGHT", -14, 14)
    pathBtn:SetScript("OnClick", function() UI.OpenJournal() end)
    panel.pathBtn = pathBtn

    -- Parented to CharacterFrame, so visibility follows it; refresh on open.
    panel:SetScript("OnShow", function() UI.RefreshCharacterSidebar() end)
end

function UI.RefreshCharacterSidebar()
    local panel = UI.sidebar
    if not panel or not panel:IsVisible() then return end

    local db = PrestigeClassesCharDB
    local def = db and db.active and PC.ClassById[db.active]

    if not def then
        panel.slot.icon:SetTexture(QUESTION_ICON)
        panel.name:SetText("No Prestige Path")
        panel.sub:SetText("The way is unchosen")
        panel.status:SetText(GREY .. "Commit to a path and its vows will be watched here." .. R)
        panel.body:SetText("")
        panel.record:SetText(GREY .. "/pc opens the codex" .. R)
        panel.codexBtn.SetLabel("Choose a Path")
        panel.codexBtn:SetSize(212, 24)
        panel.pathBtn:Hide()
        panel.deedsHead:Hide()
        panel.deedsBar:Hide()
        return
    end
    panel.codexBtn.SetLabel("Codex")
    panel.codexBtn:SetSize(102, 24)
    panel.pathBtn:Show()
    panel.pathBtn:SetEnabled(def.trials ~= nil)
    if def.trials and PC.Trials then
        local done, total = PC.Trials.Counts(def)
        panel.deedsBar.SetProgress(done, total)
        panel.deedsHead:Show()
        panel.deedsBar:Show()
    else
        panel.deedsHead:Hide()
        panel.deedsBar:Hide()
    end

    panel.slot.icon:SetTexture(def.icon)
    panel.name:SetText(def.name)
    panel.sub:SetText((FACTION_COLOR[def.faction] or GREY) .. rankText(def) .. R ..
        GREY .. "  ·  " .. def.source .. R)

    local results, summary = PC.Compliance.Evaluate(def)
    if summary.compliant then
        panel.status:SetText(GREEN .. Theme.Spaced("All Vows Honored") ..
            "  " .. summary.rulesPassed .. "/" .. summary.rulesTotal .. R)
    elseif not summary.identityOk then
        panel.status:SetText(RED .. "This character can never satisfy this path." .. R)
    else
        panel.status:SetText(RED .. Theme.Spaced("Path Broken") .. "  " ..
            summary.rulesPassed .. "/" .. summary.rulesTotal .. " vows held" .. R)
    end

    local lines = {}
    for _, r in ipairs(results) do
        local mark = r.ok and MARK_OK or MARK_FAIL
        if r.kind == "info" and not r.ok then mark = MARK_INFO end
        local color = r.ok and TEXT or (r.kind == "info" and GREY or RED)
        lines[#lines + 1] = mark .. " " .. color .. r.label .. R
    end
    if def.trials and PC.Trials then
        local nextUp = PC.Trials.UpNext(def, 3)
        if #nextUp > 0 then
            lines[#lines + 1] = ""
            lines[#lines + 1] = GOLD .. "Deeds up next" .. R
            for _, t in ipairs(nextUp) do
                local ready = PC.Trials.IsReady(t)
                lines[#lines + 1] = (ready and TEXT or GREY) .. "• " ..
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
        rec[#rec + 1] = TEXT .. "Walking this path: " .. R .. GREY .. daysAgoText(s.chosenAt) .. R
        local breaks = s.breaks or 0
        if breaks == 0 then
            rec[#rec + 1] = GREEN .. "Vows never broken." .. R
        else
            rec[#rec + 1] = TEXT .. "Vows broken: " .. R .. RED .. breaks .. R ..
                GREY .. "  (clean " .. daysAgoText(s.lastBreakAt or s.chosenAt) .. ")" .. R
        end
    end
    panel.record:SetText(table.concat(rec, "\n"))
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

    local prevPage = f.shownPage
    local pane
    if page == "journal" then
        f.browsePane:Hide()
        f.detailPane:Hide()
        f.journalPane:Show()
        refreshJournal(f)
        pane = f.journalPane
    elseif page == "detail" and selectedId then
        f.browsePane:Hide()
        f.journalPane:Hide()
        f.detailPane:Show()
        refreshDetail(f)
        pane = f.detailPane
    else
        f.detailPane:Hide()
        f.journalPane:Hide()
        f.browsePane:Show()
        refreshBrowse(f)
        pane = f.browsePane
    end
    -- the site's rise animation, on page change only (not live re-evals)
    if pane and f.shownPage ~= page then
        pane.PlayRise()
    end
    f.shownPage = page
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
        f.shownPage = nil -- replay the rise on open
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

    local f = Theme.Window("PrestigeClassesFrame", WIN_W, WIN_H)
    f.title:SetText(Theme.Spaced("Prestige Classes"))
    f:Hide()
    tinsert(UISpecialFrames, "PrestigeClassesFrame") -- close on Escape

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
