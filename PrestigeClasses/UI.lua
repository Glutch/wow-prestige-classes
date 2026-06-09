local ADDON, PC = ...

PC.UI = {}
local UI = PC.UI

local GREEN = "|cff40ff40"
local RED = "|cffff4040"
local GREY = "|cff999999"
local GOLD = "|cffffd100"
local WHITE = "|cffffffff"
local R = "|r"

local selectedId      -- class id highlighted in the list (may differ from active)

-- ------------------------------------------------------------------------
-- Detail text builder
-- ------------------------------------------------------------------------
local function buildDetail(def)
    if not def then
        return GREY .. "Select a prestige class from the list to see its path." .. R
    end

    local results, summary = PC.Compliance.Evaluate(def)
    local lines = {}

    lines[#lines + 1] = GOLD .. def.name .. R .. "  " .. GREY .. "(" .. def.source .. ", " .. def.faction .. ")" .. R
    lines[#lines + 1] = ""
    lines[#lines + 1] = WHITE .. def.fantasy .. R
    lines[#lines + 1] = ""

    local active = (PrestigeClassesCharDB and PrestigeClassesCharDB.active == def.id)
    if active then
        if summary.compliant then
            lines[#lines + 1] = GREEN .. "ACTIVE — you walk this path. (" ..
                summary.rulesPassed .. "/" .. summary.rulesTotal .. " rules met)" .. R
        elseif not summary.identityOk then
            lines[#lines + 1] = RED .. "ACTIVE — but your race/class can never satisfy this path." .. R
        else
            lines[#lines + 1] = RED .. "ACTIVE — path broken (" ..
                summary.rulesPassed .. "/" .. summary.rulesTotal .. " rules met)" .. R
        end
        lines[#lines + 1] = ""
    end

    lines[#lines + 1] = GOLD .. "Requirements" .. R
    for _, r in ipairs(results) do
        local mark = r.ok and (GREEN .. "v" .. R) or (RED .. "x" .. R)
        if r.kind == "info" then
            mark = r.ok and (GREEN .. "v" .. R) or (GREY .. "-" .. R)
        end
        local color = r.ok and WHITE or (r.kind == "info" and GREY or RED)
        lines[#lines + 1] = "  " .. mark .. " " .. color .. r.label .. R
        if r.detail and r.detail ~= "" then
            lines[#lines + 1] = "       " .. GREY .. r.detail .. R
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = GOLD .. "Vows of the " .. def.name .. R
    for _, h in ipairs(def.honorRules) do
        lines[#lines + 1] = "  " .. GREY .. "- " .. h .. R
    end

    return table.concat(lines, "\n")
end

-- ------------------------------------------------------------------------
-- Frame construction
-- ------------------------------------------------------------------------
local function createMainFrame()
    local f = CreateFrame("Frame", "PrestigeClassesFrame", UIParent, "BackdropTemplate")
    f:SetSize(640, 460)
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

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("|cffffd100Prestige Classes|r")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    -- Left: scrollable class list -----------------------------------------
    local listScroll = CreateFrame("ScrollFrame", "PrestigeClassesListScroll", f, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 20, -48)
    listScroll:SetSize(200, 380)

    local listChild = CreateFrame("Frame", nil, listScroll)
    listChild:SetSize(200, 10)
    listScroll:SetScrollChild(listChild)
    f.listChild = listChild

    -- Right: detail pane (scrollable) -------------------------------------
    local detailScroll = CreateFrame("ScrollFrame", "PrestigeClassesDetailScroll", f, "UIPanelScrollFrameTemplate")
    detailScroll:SetPoint("TOPLEFT", listScroll, "TOPRIGHT", 28, 0)
    detailScroll:SetSize(360, 340)

    local detailChild = CreateFrame("Frame", nil, detailScroll)
    detailChild:SetSize(360, 10)
    detailScroll:SetScrollChild(detailChild)

    local detailText = detailChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    detailText:SetPoint("TOPLEFT", 0, 0)
    detailText:SetWidth(345)
    detailText:SetJustifyH("LEFT")
    detailText:SetJustifyV("TOP")
    detailText:SetSpacing(2)
    f.detailText = detailText
    f.detailChild = detailChild

    -- Activate / Abandon buttons ------------------------------------------
    local activate = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    activate:SetSize(170, 26)
    activate:SetPoint("BOTTOMLEFT", detailScroll, "BOTTOMLEFT", 0, -34)
    activate:SetText("Become this class")
    activate:SetScript("OnClick", function()
        if selectedId then UI.Activate(selectedId) end
    end)
    f.activateBtn = activate

    local abandon = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    abandon:SetSize(170, 26)
    abandon:SetPoint("LEFT", activate, "RIGHT", 12, 0)
    abandon:SetText("Abandon path")
    abandon:SetScript("OnClick", function()
        UI.Abandon()
    end)
    f.abandonBtn = abandon

    return f
end

-- Build the list buttons once; highlight/active state refreshed separately.
local function buildList(f)
    local y = -4
    f.listButtons = {}
    for _, def in ipairs(PC.Classes) do
        local b = CreateFrame("Button", nil, f.listChild)
        b:SetSize(190, 22)
        b:SetPoint("TOPLEFT", 4, y)
        y = y - 23

        local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", 4, 0)
        label:SetJustifyH("LEFT")
        label:SetWidth(180)
        b.label = label
        b.classId = def.id
        b.className = def.name

        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 0.82, 0, 0.18)

        local sel = b:CreateTexture(nil, "BACKGROUND")
        sel:SetAllPoints()
        sel:SetColorTexture(1, 0.82, 0, 0.12)
        sel:Hide()
        b.selTex = sel

        b:SetScript("OnClick", function()
            selectedId = def.id
            UI.Refresh()
        end)

        f.listButtons[#f.listButtons + 1] = b
    end
    f.listChild:SetHeight(math.abs(y) + 8)
end

-- ------------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------------
function UI.Activate(id)
    local def = PC.ClassById[id]
    if not def then return end
    PrestigeClassesCharDB.active = id
    PC.Alerts.Reset()
    print("|cffffd100[Prestige]|r You have chosen the path of the " .. def.name ..
        ". Honor its vows.")
    PC.Refresh() -- triggers Core re-eval + UI refresh
end

function UI.Abandon()
    PrestigeClassesCharDB.active = nil
    PC.Alerts.Reset()
    print("|cffffd100[Prestige]|r You have abandoned your prestige path.")
    PC.Refresh()
end

function UI.Refresh()
    local f = UI.frame
    if not f then return end

    local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
    -- Default selection to the active class, else first in list.
    if not selectedId then
        selectedId = activeId or (PC.Classes[1] and PC.Classes[1].id)
    end

    -- List row colors: gold = active, white = selected, grey-ish default.
    if f.listButtons then
        for _, b in ipairs(f.listButtons) do
            local prefix = ""
            if b.classId == activeId then prefix = "|cffffd100* |r" end
            b.label:SetText(prefix .. b.className)
            b.selTex:SetShown(b.classId == selectedId)
        end
    end

    local def = selectedId and PC.ClassById[selectedId]
    f.detailText:SetText(buildDetail(def))
    f.detailChild:SetHeight(f.detailText:GetStringHeight() + 10)

    -- Button labels reflect whether the selected class is already active.
    if def and activeId == def.id then
        f.activateBtn:SetText("Re-affirm path")
    else
        f.activateBtn:SetText("Become this class")
    end
    f.abandonBtn:SetEnabled(activeId ~= nil)
end

function UI.Toggle()
    local f = UI.frame
    if not f then return end
    if f:IsShown() then f:Hide() else f:Show(); UI.Refresh() end
end

function UI.Init()
    local f = createMainFrame()
    buildList(f)
    UI.frame = f
end

-- ------------------------------------------------------------------------
-- Minimap button
-- ------------------------------------------------------------------------
function UI.InitMinimap()
    local mb = CreateFrame("Button", "PrestigeClassesMinimapButton", Minimap)
    mb:SetSize(31, 31)
    mb:SetFrameStrata("MEDIUM")
    mb:SetFrameLevel(8)

    local icon = mb:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\Ability_Warrior_Challange")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local ring = mb:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(53, 53)
    ring:SetPoint("TOPLEFT")

    -- Park it at a fixed spot on the minimap ring.
    local angle = math.rad(50)
    mb:SetPoint("CENTER", Minimap, "CENTER",
        80 * math.cos(angle), 80 * math.sin(angle))

    mb:SetScript("OnClick", function() UI.Toggle() end)
    mb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Prestige Classes")
        local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
        if activeId and PC.ClassById[activeId] then
            GameTooltip:AddLine("Path: " .. PC.ClassById[activeId].name, 1, 0.82, 0)
        else
            GameTooltip:AddLine("No path chosen", 0.6, 0.6, 0.6)
        end
        GameTooltip:AddLine("Click to open", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    mb:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
