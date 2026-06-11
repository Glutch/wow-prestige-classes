local ADDON, PC = ...

PC.Theme = {}
local Theme = PC.Theme

-- =========================================================================
-- THEME: the website's design language, ported to WoW frames.
-- Dark warm stone, gold trim, Cinzel display type, Alegreya prose, ember
-- glows. Every page of the addon builds its surfaces from these factories
-- so the in-game codex and prestigeclasses site read as one artifact.
-- =========================================================================

local WHITE8 = "Interface\\Buttons\\WHITE8X8"

-- ------------------------------------------------------------------------
-- Palette (mirrors the site's globals.css)
-- ------------------------------------------------------------------------
Theme.COLOR = {
    bg        = { 0.078, 0.063, 0.047, 0.975 }, -- #141008 deep stone
    cardTop   = { 0.137, 0.114, 0.086, 0.92 },  -- panel gradient, lighter top
    cardBot   = { 0.094, 0.078, 0.059, 0.92 },
    border    = { 0.45, 0.37, 0.22, 0.70 },     -- outer gold trim
    innerLine = { 0.50, 0.42, 0.26, 0.16 },     -- inset frame line
    bevel     = { 0.62, 0.52, 0.32, 0.20 },     -- 1px top highlight
    text      = { 0.88, 0.84, 0.78 },           -- #e0d7c8 parchment
    muted     = { 0.62, 0.56, 0.50 },           -- #9e8f7f
    gold      = { 1.00, 0.82, 0.00 },           -- #ffd100
    ember     = { 1.00, 0.42, 0.16 },           -- #ff6a2a
    tan       = { 0.78, 0.72, 0.47 },           -- #c8b878 lore
    green     = { 0.12, 1.00, 0.00 },           -- #1eff00
    red       = { 1.00, 0.35, 0.35 },           -- #ff5a5a
}

-- Inline color escapes for text built with string concat.
Theme.HEX = {
    text  = "|cffe0d7c8",
    muted = "|cff9e8f7f",
    gold  = "|cffffd100",
    tan   = "|cffc8b878",
    green = "|cff1eff00",
    red   = "|cffff5a5a",
    grey  = "|cff666666",
    white = "|cffffffff",
}

-- ------------------------------------------------------------------------
-- Fonts. Cinzel carries the headings, Alegreya the prose, Alegreya Italic
-- the mentor's voice. Each path is probed once; a missing file falls back
-- to the stock UI fonts so a broken install still renders.
-- ------------------------------------------------------------------------
local FONT_DIR = "Interface\\AddOns\\" .. ADDON .. "\\Fonts\\"
local FONT_FILE = {
    display = FONT_DIR .. "Cinzel-Bold.ttf",
    body    = FONT_DIR .. "Alegreya-Regular.ttf",
    italic  = FONT_DIR .. "Alegreya-Italic.ttf",
}
local FONT_FALLBACK = {
    display = "Fonts\\FRIZQT__.TTF",
    body    = "Fonts\\FRIZQT__.TTF",
    italic  = "Fonts\\FRIZQT__.TTF",
}

local resolvedFont = {}
local function fontPath(kind)
    local path = resolvedFont[kind]
    if path then return path end
    -- Fresh probe per kind: a failed SetFont leaves a virgin FontString
    -- with no font, so GetFont() reliably reports the miss.
    local probe = UIParent:CreateFontString(nil, "BACKGROUND")
    local ok = probe:SetFont(FONT_FILE[kind], 12, "")
    if ok == false or not probe:GetFont() then
        path = FONT_FALLBACK[kind]
    else
        path = FONT_FILE[kind]
    end
    resolvedFont[kind] = path
    return path
end

-- kind: "display" | "body" | "italic"
function Theme.SetFont(fs, kind, size, flags)
    fs:SetFont(fontPath(kind), size, flags or "")
end

function Theme.Text(parent, kind, size, color, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    Theme.SetFont(fs, kind, size)
    local c = color or Theme.COLOR.text
    fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    fs:SetJustifyH("LEFT")
    return fs
end

-- WoW has no letter-spacing; spaced caps fake the site's tracked labels
-- ("The Journey" -> "T H E   J O U R N E Y"). UTF-8 aware so em dashes
-- and middot survive.
function Theme.Spaced(s)
    local words = {}
    for word in s:gmatch("%S+") do
        words[#words + 1] = word:upper()
            :gsub("[%z\1-\127\194-\244][\128-\191]*", "%0 "):sub(1, -2)
    end
    return table.concat(words, "   ")
end

-- ------------------------------------------------------------------------
-- Texture helpers
-- ------------------------------------------------------------------------
local function solid(parent, layer, r, g, b, a)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(WHITE8)
    t:SetVertexColor(r, g, b, a or 1)
    return t
end
Theme.Solid = solid

-- Vertical/horizontal gradient on a flat texture; falls back to a solid of
-- the first color if the client lacks the modern API.
local function gradient(tex, orientation, c1, c2)
    if tex.SetGradient and CreateColor then
        tex:SetVertexColor(1, 1, 1, 1)
        tex:SetGradient(orientation,
            CreateColor(c1[1], c1[2], c1[3], c1[4] or 1),
            CreateColor(c2[1], c2[2], c2[3], c2[4] or 1))
    else
        tex:SetVertexColor(c1[1], c1[2], c1[3], c1[4] or 1)
    end
end
Theme.Gradient = gradient

-- Four 1px edges around a frame; returns the set with a tint method.
local function edgeLines(frame, layer, inset, color)
    local r, g, b, a = color[1], color[2], color[3], color[4] or 1
    local edges = {}
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local t = solid(frame, layer, r, g, b, a)
        if side == "TOP" or side == "BOTTOM" then
            t:SetPoint(side .. "LEFT", inset, side == "TOP" and -inset or inset)
            t:SetPoint(side .. "RIGHT", -inset, side == "TOP" and -inset or inset)
            t:SetHeight(1)
        else
            t:SetPoint("TOP" .. side, side == "LEFT" and inset or -inset, -inset)
            t:SetPoint("BOTTOM" .. side, side == "LEFT" and inset or -inset, inset)
            t:SetWidth(1)
        end
        edges[#edges + 1] = t
    end
    function edges.SetColor(nr, ng, nb, na)
        for _, t in ipairs(edges) do t:SetVertexColor(nr, ng, nb, na or 1) end
    end
    return edges
end
Theme.EdgeLines = edgeLines

-- ------------------------------------------------------------------------
-- Panel: the site's .wow-panel. Gradient stone fill, gold trim, inset
-- frame line, 1px bevel under the top edge.
-- ------------------------------------------------------------------------
function Theme.Panel(parent)
    local p = CreateFrame("Frame", nil, parent)

    local bg = p:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE8)
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    gradient(bg, "VERTICAL", Theme.COLOR.cardBot, Theme.COLOR.cardTop)
    p.bg = bg

    p.border = edgeLines(p, "BORDER", 0, Theme.COLOR.border)
    p.inner = edgeLines(p, "BORDER", 3, Theme.COLOR.innerLine)

    local bevel = solid(p, "BORDER", unpack(Theme.COLOR.bevel))
    bevel:SetPoint("TOPLEFT", 1, -1)
    bevel:SetPoint("TOPRIGHT", -1, -1)
    bevel:SetHeight(1)

    return p
end

-- Horizontal rule that fades out at both ends (section dividers).
function Theme.Divider(parent, alpha)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(1)
    local a = alpha or 0.35
    local gold = Theme.COLOR.gold
    local left = holder:CreateTexture(nil, "ARTWORK")
    left:SetTexture(WHITE8)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMRIGHT", holder, "BOTTOM")
    gradient(left, "HORIZONTAL",
        { gold[1], gold[2], gold[3], 0 }, { gold[1], gold[2], gold[3], a })
    local right = holder:CreateTexture(nil, "ARTWORK")
    right:SetTexture(WHITE8)
    right:SetPoint("TOPLEFT", holder, "TOP")
    right:SetPoint("BOTTOMRIGHT")
    gradient(right, "HORIZONTAL",
        { gold[1], gold[2], gold[3], a }, { gold[1], gold[2], gold[3], 0 })
    return holder
end

-- ------------------------------------------------------------------------
-- Chip: the site's bordered micro-label (RANK TRIAL, SOLO, LVL 38...).
-- ------------------------------------------------------------------------
function Theme.Chip(parent)
    local c = CreateFrame("Frame", nil, parent)
    c:SetHeight(15)
    local bg = solid(c, "BACKGROUND", 0, 0, 0, 0.30)
    bg:SetAllPoints()
    c.borderLines = edgeLines(c, "BORDER", 0, Theme.COLOR.muted)
    c.label = Theme.Text(c, "body", 9, Theme.COLOR.muted)
    c.label:SetPoint("CENTER", 0, 0)
    function c.SetChip(text, color)
        local col = color or Theme.COLOR.muted
        c.label:SetText(Theme.Spaced(text))
        c.label:SetTextColor(col[1], col[2], col[3])
        c.borderLines.SetColor(col[1], col[2], col[3], 0.5)
        c:SetWidth(c.label:GetStringWidth() + 12)
    end
    return c
end

-- Lay a row of chips; entries = { {text, color}, ... }. Pools chips on the
-- owner frame. Returns the row's total width.
function Theme.ChipRow(owner, anchorTo, anchorPoint, relPoint, x, y, entries)
    owner.chips = owner.chips or {}
    for _, chip in ipairs(owner.chips) do chip:Hide() end
    local prev
    local width = 0
    for i, e in ipairs(entries) do
        local chip = owner.chips[i]
        if not chip then
            chip = Theme.Chip(owner)
            owner.chips[i] = chip
        end
        chip:ClearAllPoints()
        if prev then
            chip:SetPoint("LEFT", prev, "RIGHT", 6, 0)
        else
            chip:SetPoint(anchorPoint, anchorTo, relPoint, x, y)
        end
        chip.SetChip(e[1], e[2])
        chip:Show()
        width = width + chip:GetWidth() + (prev and 6 or 0)
        prev = chip
    end
    return width
end

-- ------------------------------------------------------------------------
-- Buttons: flat dark plate, gold trim, Cinzel caps. Primary gets a gold
-- wash. Hover lifts the trim to full gold (the site's hover glow).
-- ------------------------------------------------------------------------
function Theme.Button(parent, text, primary)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(170, 28)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE8)
    bg:SetAllPoints()
    b.bgTex = bg
    b.borderLines = edgeLines(b, "BORDER", 0, Theme.COLOR.border)

    b.label = Theme.Text(b, "display", 11,
        primary and Theme.COLOR.gold or Theme.COLOR.text)
    b.label:SetPoint("CENTER", 0, 0)

    local gold = Theme.COLOR.gold
    local function restState()
        if primary then
            bg:SetVertexColor(gold[1], gold[2], gold[3], 0.12)
            b.borderLines.SetColor(gold[1], gold[2], gold[3], 0.65)
        else
            bg:SetVertexColor(0, 0, 0, 0.35)
            local br = Theme.COLOR.border
            b.borderLines.SetColor(br[1], br[2], br[3], br[4])
        end
    end
    restState()

    b:SetScript("OnEnter", function()
        if not b:IsEnabled() then return end
        bg:SetVertexColor(gold[1], gold[2], gold[3], primary and 0.22 or 0.10)
        b.borderLines.SetColor(gold[1], gold[2], gold[3], 1)
        b.label:SetTextColor(gold[1], gold[2], gold[3])
    end)
    b:SetScript("OnLeave", function()
        restState()
        local c = primary and Theme.COLOR.gold or Theme.COLOR.text
        b.label:SetTextColor(c[1], c[2], c[3])
    end)
    b:SetScript("OnEnable", function() b:SetAlpha(1) end)
    b:SetScript("OnDisable", function() b:SetAlpha(0.4) end)

    function b.SetLabel(t) b.label:SetText(Theme.Spaced(t)) end
    b.SetLabel(text)
    return b
end

-- Quiet text-only link ("< ALL PATHS"); muted at rest, gold on hover.
function Theme.LinkButton(parent, text)
    local b = CreateFrame("Button", nil, parent)
    b.label = Theme.Text(b, "display", 10, Theme.COLOR.muted)
    b.label:SetPoint("LEFT")
    b.label:SetText(Theme.Spaced(text))
    b:SetSize(b.label:GetStringWidth() + 4, 18)
    local gold, muted = Theme.COLOR.gold, Theme.COLOR.muted
    b:SetScript("OnEnter", function()
        b.label:SetTextColor(gold[1], gold[2], gold[3])
    end)
    b:SetScript("OnLeave", function()
        b.label:SetTextColor(muted[1], muted[2], muted[3])
    end)
    return b
end

-- ------------------------------------------------------------------------
-- Icon slot: black plate, 1px trim, cropped icon. SetQualityByItem pulls
-- the rarity color once the item loads (the site's colored item slots);
-- legendaries get the orange halo.
-- ------------------------------------------------------------------------
function Theme.IconSlot(parent, size)
    local s = CreateFrame("Button", nil, parent)
    s:SetSize(size, size)
    local bg = solid(s, "BACKGROUND", 0, 0, 0, 0.6)
    bg:SetAllPoints()
    s.borderLines = edgeLines(s, "BORDER", 0, { 0.25, 0.22, 0.18, 0.9 })
    s.icon = s:CreateTexture(nil, "ARTWORK")
    s.icon:SetPoint("TOPLEFT", 2, -2)
    s.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    s.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local glow = s:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetPoint("CENTER")
    glow:SetSize(size * 1.9, size * 1.9)
    glow:Hide()
    s.glow = glow

    function s.SetQualityByItem(itemId)
        -- pooled slots get reassigned: drop the old rarity dress and ignore
        -- any load that resolves for a previous occupant
        s.borderLines.SetColor(0.25, 0.22, 0.18, 0.9)
        glow:Hide()
        s.pendingItem = itemId
        if not (Item and Item.CreateFromItemID) then return end
        local item = Item:CreateFromItemID(itemId)
        item:ContinueOnItemLoad(function()
            if s.pendingItem ~= itemId then return end
            local q = item:GetItemQuality()
            local qualityColor = GetItemQualityColor
                or (C_Item and C_Item.GetItemQualityColor)
            if not qualityColor then return end
            local r, g, b = qualityColor(q or 1)
            s.borderLines.SetColor(r, g, b, 0.8)
            if q and q >= 5 then
                glow:SetVertexColor(1, 0.5, 0, 0.45)
                glow:Show()
            end
        end)
    end
    return s
end

-- ------------------------------------------------------------------------
-- Motion. Rise() is the site's staggered fade-up; EmberPulse() the slow
-- breathing glow on hero icons and journey waypoints.
-- ------------------------------------------------------------------------
function Theme.Rise(frame)
    local grp = frame:CreateAnimationGroup()
    local fade = grp:CreateAnimation("Alpha")
    fade:SetFromAlpha(0)
    fade:SetToAlpha(1)
    fade:SetDuration(0.30)
    fade:SetSmoothing("OUT")
    local scale = grp:CreateAnimation("Scale")
    if scale.SetScaleFrom then
        scale:SetScaleFrom(0.985, 0.985)
        scale:SetScaleTo(1, 1)
    end
    scale:SetDuration(0.30)
    scale:SetSmoothing("OUT")
    function frame.PlayRise()
        grp:Stop()
        grp:Play()
    end
    return grp
end

-- Looping ember glow behind a region. Returns the glow texture.
function Theme.EmberPulse(parent, anchorTo, size, color)
    local glow = parent:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetPoint("CENTER", anchorTo, "CENTER")
    glow:SetSize(size, size)
    local c = color or Theme.COLOR.ember
    glow:SetVertexColor(c[1], c[2], c[3], 0.35)
    local grp = glow:CreateAnimationGroup()
    grp:SetLooping("BOUNCE")
    local pulse = grp:CreateAnimation("Alpha")
    pulse:SetFromAlpha(0.55)
    pulse:SetToAlpha(1)
    pulse:SetDuration(1.75)
    pulse:SetSmoothing("IN_OUT")
    grp:Play()
    glow.anim = grp
    return glow
end

-- ------------------------------------------------------------------------
-- Progress bar: thin track, gold fill, count overlaid in the site's mono
-- style (body face, small).
-- ------------------------------------------------------------------------
function Theme.ProgressBar(parent, width, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height or 9)
    bar:SetStatusBarTexture(WHITE8)
    bar:SetStatusBarColor(1, 0.82, 0, 0.85)

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(WHITE8)
    track:SetAllPoints()
    track:SetVertexColor(0, 0, 0, 0.55)
    bar.borderLines = edgeLines(bar, "OVERLAY", -1, { 0.45, 0.37, 0.22, 0.45 })

    bar.text = Theme.Text(bar, "body", 9, Theme.COLOR.text)
    bar.text:SetPoint("CENTER", 0, 0)

    function bar.SetProgress(value, target)
        bar:SetMinMaxValues(0, target)
        bar:SetValue(value)
        bar.text:SetText(value .. " / " .. target)
        if value >= target then
            bar:SetStatusBarColor(0.12, 0.9, 0.1, 0.7)
        else
            bar:SetStatusBarColor(1, 0.82, 0, 0.85)
        end
    end
    return bar
end

-- ------------------------------------------------------------------------
-- Scroll region with the site's minimal scrolling: mousewheel + a slim
-- gold position thumb instead of the stock arrow scrollbar.
-- ------------------------------------------------------------------------
function Theme.Scroll(parent, name)
    local scroll = CreateFrame("ScrollFrame", name, parent)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    scroll.child = child

    local track = solid(scroll, "OVERLAY", 1, 0.82, 0, 0.08)
    track:SetWidth(3)
    track:SetPoint("TOPRIGHT", 9, 0)
    track:SetPoint("BOTTOMRIGHT", 9, 0)
    local thumb = solid(scroll, "OVERLAY", 1, 0.82, 0, 0.45)
    thumb:SetWidth(3)

    local function update()
        local total, view = child:GetHeight(), scroll:GetHeight()
        local max = math.max(0, total - view)
        if scroll:GetVerticalScroll() > max then
            scroll:SetVerticalScroll(max)
        end
        if max <= 0 or view <= 0 then
            track:Hide()
            thumb:Hide()
            return
        end
        track:Show()
        thumb:Show()
        local th = math.max(24, view * view / total)
        thumb:SetHeight(th)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0,
            -(view - th) * (scroll:GetVerticalScroll() / max))
    end
    scroll.UpdateThumb = update

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        local max = math.max(0, child:GetHeight() - scroll:GetHeight())
        scroll:SetVerticalScroll(math.min(max,
            math.max(0, scroll:GetVerticalScroll() - delta * 60)))
        update()
    end)
    scroll:SetScript("OnSizeChanged", update)

    function scroll.ResetScroll()
        scroll:SetVerticalScroll(0)
        update()
    end
    return scroll, child
end

-- ------------------------------------------------------------------------
-- Window shell: the codex frame itself. Deep stone fill, gold trim, ember
-- glow bleeding down from the top edge (the site's hero gradient), spaced
-- Cinzel masthead between two fading rules.
-- ------------------------------------------------------------------------
function Theme.Window(name, width, height)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(width, height)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")

    local bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetTexture(WHITE8)
    bg:SetAllPoints()
    local c = Theme.COLOR.bg
    bg:SetVertexColor(c[1], c[2], c[3], c[4])

    -- ember wash at the top, vignette at the foot
    local emberC = Theme.COLOR.ember
    local ember = f:CreateTexture(nil, "BACKGROUND", nil, -7)
    ember:SetTexture(WHITE8)
    ember:SetPoint("TOPLEFT", 1, -1)
    ember:SetPoint("TOPRIGHT", -1, -1)
    ember:SetHeight(140)
    gradient(ember, "VERTICAL",
        { emberC[1], emberC[2], emberC[3], 0 },
        { emberC[1], emberC[2], emberC[3], 0.10 })
    local foot = f:CreateTexture(nil, "BACKGROUND", nil, -7)
    foot:SetTexture(WHITE8)
    foot:SetPoint("BOTTOMLEFT", 1, 1)
    foot:SetPoint("BOTTOMRIGHT", -1, 1)
    foot:SetHeight(120)
    gradient(foot, "VERTICAL", { 0, 0, 0, 0.35 }, { 0, 0, 0, 0 })

    f.border = edgeLines(f, "BORDER", 0, Theme.COLOR.border)
    f.inner = edgeLines(f, "BORDER", 3, Theme.COLOR.innerLine)

    -- masthead
    local title = Theme.Text(f, "display", 15, Theme.COLOR.gold)
    title:SetPoint("TOP", 0, -16)
    title:SetJustifyH("CENTER")
    f.title = title

    local ruleL = Theme.Divider(f, 0.45)
    ruleL:SetPoint("RIGHT", title, "LEFT", -14, 0)
    ruleL:SetWidth(150)
    local ruleR = Theme.Divider(f, 0.45)
    ruleR:SetPoint("LEFT", title, "RIGHT", 14, 0)
    ruleR:SetWidth(150)

    -- close glyph
    local close = CreateFrame("Button", nil, f)
    close:SetSize(26, 26)
    close:SetPoint("TOPRIGHT", -8, -8)
    close.label = Theme.Text(close, "body", 17, Theme.COLOR.muted)
    close.label:SetPoint("CENTER", 0, 0)
    close.label:SetText("×")
    close:SetScript("OnEnter", function()
        close.label:SetTextColor(1, 0.4, 0.3)
    end)
    close:SetScript("OnLeave", function()
        local m = Theme.COLOR.muted
        close.label:SetTextColor(m[1], m[2], m[3])
    end)
    close:SetScript("OnClick", function() f:Hide() end)

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    return f
end
