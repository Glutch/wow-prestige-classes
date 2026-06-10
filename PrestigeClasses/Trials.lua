local ADDON, PC = ...
local Util = PC.Util

PC.Trials = {}
local T = PC.Trials

-- =========================================================================
-- TRIALS: the journey content of a prestige path.
-- =========================================================================
-- A path may carry `trials` — deeds the walker performs across four
-- chapters, one per rank (1 Initiate, 2 Disciple, 3 Exemplar, 4 Paragon;
-- chapter 0 is lifelong and always open). Chapter N opens at rank N. The
-- chapter's `rankTrial = true` entry gates ascension: on a path with
-- trials, reaching the next rank takes the level AND the deed.
--
-- Trial kinds and their fields (all detected automatically):
--   kill     targets={names} or pattern="substring"/{...substrings}
--            (neither = any foe), count?, solo?, cleanOnly?,
--            requireBuff="Stoneform", requireElite?
--   counter  like kill but endless; milestones={{count,honorific},...}
--   proc     aura="Mace Stun Effect", count — your aura landing on foes
--   multihit spell="Thunder Clap", hits=3, count — one cast striking N foes
--   loot     item="Dark Iron Ore", count
--   equip    items={"item name", ...} — wield/wear any one of them
--   cast     spell="Heavy Copper Maul", zone?, subzone?
--   emote    emote="KNEEL", zone?, subzone?
--   visit    zone="Wetlands", subzone="Grim Batol"
-- Shared fields: id, chapter (0..4), name, objective, text (mentor voice),
--   level (suggested level for the deed; required except on counters),
--   rankTrial?, honorific?, completionNote?, epitaph="...%d..." (counters).
-- Zone/subzone match case-insensitively as substrings; subzone also checks
-- the minimap zone text (inn/building names).
-- =========================================================================

local GOLD = "|cffffd100"
local GREY = "|cff999999"
local R = "|r"

-- /pc debug — trace every detection input so any data mismatch (subzone
-- strings, aura names, recipe spells) can be proven in the field without
-- leveling a character to the trial in question.
local function dbg(msg)
    local d = PrestigeClassesCharDB
    if d and d.debug then
        print(GREY .. "[Prestige:debug] " .. msg .. R)
    end
end

local function describeLocation()
    local mini = GetMinimapZoneText and GetMinimapZoneText() or nil
    return "zone='" .. (GetRealZoneText() or "?") ..
        "' subzone='" .. (GetSubZoneText() or "") ..
        "'" .. (mini and (" minimap='" .. mini .. "'") or "")
end

local RANK_TITLES = { "Initiate", "Disciple", "Exemplar", "Paragon" }
T.RANK_TITLES = RANK_TITLES

local function rankFromLevel(level)
    if level >= 60 then return 4
    elseif level >= 40 then return 3
    elseif level >= 20 then return 2
    else return 1 end
end

-- ------------------------------------------------------------------------
-- Saved state (PrestigeClassesCharDB.trials / .trialsMeta)
-- ------------------------------------------------------------------------
local function db() return PrestigeClassesCharDB end

function T.State(id)
    local d = db()
    return d and d.trials and d.trials[id] or nil
end

local function stateFor(id)
    local d = db()
    d.trials = d.trials or {}
    local s = d.trials[id]
    if not s then
        s = { progress = 0 }
        d.trials[id] = s
    end
    return s
end

local function activeDef()
    local d = db()
    local def = d and d.active and PC.ClassById[d.active]
    if def and def.trials then return def end
    return nil
end

-- Counters with milestones never flip `done`: the count runs forever.
function T.IsComplete(trial)
    local s = T.State(trial.id)
    if not s then return false end
    if s.done then return true end
    if trial.milestones then
        return (s.progress or 0) >= trial.milestones[#trial.milestones].count
    end
    return false
end

function T.Target(trial)
    if trial.milestones then return trial.milestones[#trial.milestones].count end
    return trial.count or 1
end

-- ------------------------------------------------------------------------
-- Earned rank
-- ------------------------------------------------------------------------
local rankCache
function T.InvalidateRank() rankCache = nil end

local function rankTrialFor(def, chapter)
    for _, trial in ipairs(def.trials) do
        if trial.rankTrial and trial.chapter == chapter then return trial end
    end
end

-- Effective rank on the active path: each ascension needs the level AND the
-- previous chapter's rank trial. Paths without trials — and paths merely
-- browsed, not walked — rank by level alone.
-- Returns rank index, rank title, pending rank trial (nil if none barred).
function T.RankInfo(def)
    local levelRank = rankFromLevel(UnitLevel("player"))
    local d = db()
    if not (def and def.trials and d and d.active == def.id) then
        return levelRank, RANK_TITLES[levelRank], nil
    end
    if rankCache then return rankCache[1], rankCache[2], rankCache[3] end
    local rank = 1
    for r = 2, levelRank do
        local gate = rankTrialFor(def, r - 1)
        if gate and not T.IsComplete(gate) then break end
        rank = r
    end
    local pending
    if rank < levelRank then pending = rankTrialFor(def, rank) end
    rankCache = { rank, RANK_TITLES[rank], pending }
    return rank, RANK_TITLES[rank], pending
end

function T.ChapterUnlocked(def, chapter)
    if not chapter or chapter <= 0 then return true end
    local rank = T.RankInfo(def)
    return rank >= chapter
end

-- Announce ascension, or (on level-up) the trial barring it.
function T.CheckRank(announcePending)
    local def = activeDef()
    if not def then return end
    local d = db()
    d.trialsMeta = d.trialsMeta or { rank = 1 }
    local rank, title, pending = T.RankInfo(def)
    if rank > (d.trialsMeta.rank or 1) then
        d.trialsMeta.rank = rank
        if PC.Alerts and PC.Alerts.RankUp then PC.Alerts.RankUp(def, title) end
    elseif announcePending and pending then
        print(GOLD .. "[Prestige]|r You have the level of a " ..
            RANK_TITLES[rank + 1] .. " but not yet the deed. Complete |cffffffff" ..
            pending.name .. "|r to ascend.")
    end
end

-- Called when the character commits to a (different) path: trial progress
-- belongs to one journey.
function T.OnPathChanged()
    local d = db()
    if not d then return end
    d.trials = {}
    T.InvalidateRank()
    local def = activeDef()
    d.trialsMeta = { rank = def and (T.RankInfo(def)) or rankFromLevel(UnitLevel("player")) }
end

-- ------------------------------------------------------------------------
-- Derived record (journal header, death epitaph)
-- ------------------------------------------------------------------------
function T.Honorifics(def)
    local out = {}
    if not (def and def.trials) then return out end
    for _, trial in ipairs(def.trials) do
        local s = T.State(trial.id)
        local progress = s and s.progress or 0
        if trial.milestones then
            for _, m in ipairs(trial.milestones) do
                if m.honorific and progress >= m.count then
                    out[#out + 1] = m.honorific
                end
            end
        elseif trial.honorific and s and s.done then
            out[#out + 1] = trial.honorific
        end
    end
    return out
end

function T.Counts(def)
    local done, total = 0, 0
    if not (def and def.trials) then return 0, 0 end
    for _, trial in ipairs(def.trials) do
        total = total + 1
        if T.IsComplete(trial) then done = done + 1 end
    end
    return done, total
end

-- The deeds to chase next: open, unfinished, ordered by "doable at your
-- level first, easiest first", with a pending rank trial always on top.
-- Endless counters are ambient and excluded. Returns up to maxCount trials.
function T.UpNext(def, maxCount)
    local out = {}
    if not (def and def.trials) then return out end
    local playerLevel = UnitLevel("player")
    local _, _, pending = T.RankInfo(def)
    for _, trial in ipairs(def.trials) do
        if trial.kind ~= "counter" and not T.IsComplete(trial)
            and T.ChapterUnlocked(def, trial.chapter) then
            out[#out + 1] = trial
        end
    end
    table.sort(out, function(a, b)
        if a == pending or b == pending then return a == pending end
        local ra = (a.level or 1) <= playerLevel and 0 or 1
        local rb = (b.level or 1) <= playerLevel and 0 or 1
        if ra ~= rb then return ra < rb end
        local la, lb = a.level or 0, b.level or 0
        if la ~= lb then return la < lb end
        if (a.chapter or 0) ~= (b.chapter or 0) then
            return (a.chapter or 0) < (b.chapter or 0)
        end
        return (a.id or "") < (b.id or "")
    end)
    while #out > (maxCount or 3) do table.remove(out) end
    return out
end

-- True when the deed is within reach of the player's level.
function T.IsReady(trial)
    return (trial.level or 1) <= UnitLevel("player")
end

-- ------------------------------------------------------------------------
-- Progress + ceremonies
-- ------------------------------------------------------------------------
local function refreshUI()
    if PC.UI then
        if PC.UI.frame and PC.UI.frame:IsShown() then PC.UI.Refresh() end
        if PC.UI.RefreshCharacterSidebar then PC.UI.RefreshCharacterSidebar() end
    end
end

local function celebrate(def, trial, honorific, milestoneCount)
    if PC.Alerts and PC.Alerts.TrialComplete then
        PC.Alerts.TrialComplete(def, trial, honorific, milestoneCount)
    end
end

-- Quiet chat tick on long counters so progress is felt between ceremonies.
local function tick(trial, s)
    local target = T.Target(trial)
    local every = trial.milestones and 10 or 5
    if target >= 10 and s.progress < target and s.progress % every == 0 then
        local nextUp = ""
        if trial.milestones then
            for _, m in ipairs(trial.milestones) do
                if s.progress < m.count then
                    nextUp = GREY .. " — " .. (m.honorific or "next mark") ..
                        " at " .. m.count .. R
                    break
                end
            end
        end
        print(GOLD .. "[Prestige]|r " .. trial.name .. ": " .. s.progress ..
            (trial.milestones and "" or ("/" .. target)) .. nextUp)
    end
end

local function bump(def, trial, n)
    local s = stateFor(trial.id)
    local old = s.progress or 0
    s.progress = old + (n or 1)

    if trial.milestones then
        for _, m in ipairs(trial.milestones) do
            if old < m.count and s.progress >= m.count then
                celebrate(def, trial, m.honorific, m.count)
            end
        end
        tick(trial, s)
        refreshUI()
        return
    end

    if not s.done and s.progress >= (trial.count or 1) then
        s.done = true
        s.doneAt = time()
        T.InvalidateRank()
        celebrate(def, trial, trial.honorific)
        T.CheckRank(false)
    else
        tick(trial, s)
    end
    refreshUI()
end

-- Run fn for every trial that can still advance right now.
local function eachActive(fn)
    local def = activeDef()
    if not def then return end
    for _, trial in ipairs(def.trials) do
        local live = trial.kind == "counter" or not T.IsComplete(trial)
        if live and T.ChapterUnlocked(def, trial.chapter) then
            fn(def, trial)
        end
    end
end

-- ------------------------------------------------------------------------
-- Matching helpers
-- ------------------------------------------------------------------------
local function containsCI(hay, needle)
    if not hay or not needle then return false end
    return hay:lower():find(needle:lower(), 1, true) ~= nil
end

function T.LocationMatches(trial)
    if trial.zone and not containsCI(GetRealZoneText(), trial.zone) then
        return false
    end
    if trial.subzone then
        local sub = GetSubZoneText()
        local mini = GetMinimapZoneText and GetMinimapZoneText() or nil
        if not (containsCI(sub, trial.subzone) or containsCI(mini, trial.subzone)) then
            return false
        end
    end
    return true
end

-- No targets and no pattern means "any foe" (used with requireElite etc.).
local function nameMatches(trial, name)
    if trial.targets then
        for _, n in ipairs(trial.targets) do
            if n == name then return true end
        end
        return false
    end
    if trial.pattern then
        if name == nil then return false end
        if type(trial.pattern) == "table" then
            for _, p in ipairs(trial.pattern) do
                if name:find(p, 1, true) then return true end
            end
            return false
        end
        return name:find(trial.pattern, 1, true) ~= nil
    end
    return true
end

local function isClean(def)
    local _, summary = PC.Compliance.Evaluate(def)
    return summary.compliant
end

local function hasBuff(name)
    for i = 1, 40 do
        local b = UnitBuff("player", i)
        if not b then return false end
        if b == name then return true end
    end
    return false
end

-- ------------------------------------------------------------------------
-- Kill detection. We credit a death if we damaged that GUID recently —
-- works solo and in groups (you must have contributed, not killing-blowed).
-- Elite-ness comes from a cache fed by target/mouseover, since the combat
-- log carries no classification.
-- ------------------------------------------------------------------------
local unitIsElite, unitInfoCount = {}, 0
local recentDamage, damageInserts = {}, 0

function T.NoteUnit(unit)
    if not UnitExists(unit) or not UnitCanAttack("player", unit) then return end
    local guid = UnitGUID(unit)
    if not guid then return end
    local c = UnitClassification(unit)
    if unitIsElite[guid] == nil then
        unitInfoCount = unitInfoCount + 1
        if unitInfoCount > 300 then -- crude prune; repopulates on next target
            unitIsElite, unitInfoCount = {}, 1
        end
    end
    unitIsElite[guid] = (c == "elite" or c == "rareelite" or c == "worldboss")
end

-- A named quarry that falls without counting deserves an explanation —
-- the player just did something hard and needs to know why it didn't land.
local function explainRejection(trial, reason)
    print(GOLD .. "[Prestige]|r " .. trial.name .. ": the foe fell, but " ..
        reason .. " The deed stands unfulfilled.")
end

function T.CreditKill(destName, destGUID)
    dbg("kill credit: '" .. (destName or "?") .. "'")
    eachActive(function(def, trial)
        if trial.kind ~= "kill" and trial.kind ~= "counter" then return end
        if not nameMatches(trial, destName) then return end
        local named = trial.targets ~= nil -- a specific quarry, not a tally
        if trial.solo and IsInGroup() then
            if named then explainRejection(trial, "the trial demanded you fight alone.") end
            return
        end
        if trial.requireBuff and not hasBuff(trial.requireBuff) then
            if named then explainRejection(trial, "the trial demanded " .. trial.requireBuff .. " be active.") end
            return
        end
        if trial.requireElite and not unitIsElite[destGUID] then
            dbg(trial.id .. ": target not seen as elite (target it before the kill)")
            return
        end
        if trial.cleanOnly and not isClean(def) then
            if named then explainRejection(trial, "your vows were broken at the moment of the kill.") end
            return
        end
        bump(def, trial, 1)
    end)
end

-- One cast striking several foes: combat log events of an instant AoE share
-- a tight time window; distinct destGUIDs within it are one swing's victims.
local windows = {}
local function multihitHit(def, trial, destGUID, now)
    local w = windows[trial.id]
    if not w or now - w.at > 1.0 then
        w = { at = now, guids = {}, n = 0 }
        windows[trial.id] = w
    end
    if not destGUID or w.guids[destGUID] then return end
    w.guids[destGUID] = true
    if w.n < 0 then return end -- this cast already credited
    w.n = w.n + 1
    if w.n >= (trial.hits or 3) then
        w.n = -1
        bump(def, trial, 1)
    end
end

-- Normalized combat-log entry point (the frame handler unpacks CLEU args;
-- tests call this directly).
function T.OnCombatEvent(subevent, sourceGUID, destGUID, destName, spellName)
    if not activeDef() then return end
    local now = GetTime()
    local mine = sourceGUID ~= nil and
        (sourceGUID == UnitGUID("player") or
            (UnitExists("pet") and sourceGUID == UnitGUID("pet")))

    if mine and destGUID then
        if subevent == "PARTY_KILL" or subevent:find("_DAMAGE", 1, true) then
            recentDamage[destGUID] = now + 120
            damageInserts = damageInserts + 1
            if damageInserts > 500 then
                damageInserts = 0
                for g, expiry in pairs(recentDamage) do
                    if expiry < now then recentDamage[g] = nil end
                end
            end
        end
        if subevent == "SPELL_AURA_APPLIED" and spellName then
            dbg("your aura applied: '" .. spellName .. "'")
            eachActive(function(def, trial)
                if trial.kind == "proc" and trial.aura == spellName then
                    bump(def, trial, 1)
                end
            end)
        elseif subevent == "SPELL_DAMAGE" and spellName then
            eachActive(function(def, trial)
                if trial.kind == "multihit" and trial.spell == spellName then
                    multihitHit(def, trial, destGUID, now)
                end
            end)
        end
    elseif subevent == "UNIT_DIED" and destGUID then
        local expiry = recentDamage[destGUID]
        recentDamage[destGUID] = nil
        if expiry and expiry > now then
            T.CreditKill(destName, destGUID)
        end
        unitIsElite[destGUID] = nil
    end
end

-- ------------------------------------------------------------------------
-- Non-combat detections
-- ------------------------------------------------------------------------
-- When the right action happens in the right zone but the wrong subzone,
-- say what the client actually reports — this is how location data gets
-- field-proven (and fixed) without a max-level character.
local function nearMissHint(trial)
    if trial.zone and not containsCI(GetRealZoneText(), trial.zone) then
        return -- wrong zone entirely; stay quiet
    end
    print(GOLD .. "[Prestige]|r " .. trial.name .. ": right deed, wrong spot. " ..
        "It asks for '" .. (trial.subzone or trial.zone or "?") ..
        "'; you are at " .. describeLocation() .. ".")
end

function T.OnEmote(token)
    if not token then return end
    token = token:upper()
    dbg("emote '" .. token .. "' at " .. describeLocation())
    eachActive(function(def, trial)
        if trial.kind ~= "emote" or trial.emote ~= token then return end
        if T.LocationMatches(trial) then
            bump(def, trial, 1)
        else
            nearMissHint(trial)
        end
    end)
end

function T.OnZone()
    eachActive(function(def, trial)
        if trial.kind == "visit" and T.LocationMatches(trial) then
            bump(def, trial, 1)
        end
    end)
end

function T.OnSpellSuccess(spellName)
    if not spellName then return end
    eachActive(function(def, trial)
        if trial.kind ~= "cast" or trial.spell ~= spellName then return end
        if T.LocationMatches(trial) then
            bump(def, trial, 1)
        else
            nearMissHint(trial)
        end
    end)
end

local EQUIP_SCAN_SLOTS = {
    "MainHandSlot", "SecondaryHandSlot", "RangedSlot",
    "HeadSlot", "ShoulderSlot", "ChestSlot", "WaistSlot",
    "LegsSlot", "FeetSlot", "WristSlot", "HandsSlot",
}

function T.OnEquip()
    local worn
    eachActive(function(def, trial)
        if trial.kind ~= "equip" then return end
        if not worn then
            worn = {}
            for _, slot in ipairs(EQUIP_SCAN_SLOTS) do
                local link = Util.EquippedLink(slot)
                if link then
                    worn[link:match("%[(.-)%]") or link] = true
                end
            end
        end
        for _, item in ipairs(trial.items or {}) do
            if worn[item] then
                bump(def, trial, 1)
                return
            end
        end
    end)
end

function T.OnLoot(msg)
    if not msg or not msg:find("^You ") then return end -- self loot only
    local item = msg:match("%[(.-)%]")
    if not item then return end
    local n = tonumber(msg:match("x(%d+)")) or 1
    eachActive(function(def, trial)
        if trial.kind == "loot" and trial.item == item then
            bump(def, trial, n)
        end
    end)
end

-- ------------------------------------------------------------------------
-- Lint: structural validation of a journey's data. Catches authoring
-- mistakes (bad kinds, missing fields, broken rank ladders) the moment a
-- new class file is written — run via /pc verify or the offline tests.
-- ------------------------------------------------------------------------
local KIND_FIELDS = {
    kill     = {},
    counter  = { "milestones" },
    proc     = { "aura", "count" },
    multihit = { "spell", "hits", "count" },
    loot     = { "item", "count" },
    equip    = { "items" },
    cast     = { "spell" },
    emote    = { "emote" },
    visit    = {},
}

function T.Lint(def)
    local problems = {}
    local function bad(trial, msg)
        problems[#problems + 1] = (trial and trial.id or def.id) .. ": " .. msg
    end
    if not def.trials then return problems end

    local seen, rankTrials = {}, {}
    local maxChapter = 0
    for _, trial in ipairs(def.trials) do
        if not trial.id then bad(trial, "missing id") end
        if trial.id and seen[trial.id] then bad(trial, "duplicate id") end
        seen[trial.id or ""] = true
        if not trial.name then bad(trial, "missing name") end
        if not trial.objective then bad(trial, "missing objective") end

        local c = trial.chapter or -1
        if c < 0 or c > 4 then bad(trial, "chapter must be 0..4") end
        if c > maxChapter then maxChapter = c end

        local fields = KIND_FIELDS[trial.kind]
        if not fields then
            bad(trial, "unknown kind '" .. tostring(trial.kind) .. "'")
        else
            for _, f in ipairs(fields) do
                if trial[f] == nil then
                    bad(trial, "kind '" .. trial.kind .. "' needs field '" .. f .. "'")
                end
            end
        end
        if trial.kind == "kill" and not trial.targets and not trial.pattern
            and not trial.requireElite and not trial.requireBuff then
            bad(trial, "kill with no targets/pattern/condition matches every kill")
        end
        if trial.kind == "visit" and not trial.zone and not trial.subzone then
            bad(trial, "visit needs zone or subzone")
        end
        if trial.kind == "emote" and trial.emote ~= (trial.emote or ""):upper() then
            bad(trial, "emote token must be uppercase")
        end
        if trial.milestones then
            local last = 0
            for _, m in ipairs(trial.milestones) do
                if not m.count or m.count <= last then
                    bad(trial, "milestones must have ascending counts")
                    break
                end
                last = m.count
            end
        end
        if trial.epitaph and not trial.epitaph:find("%%d") then
            bad(trial, "epitaph must contain %d")
        end
        if trial.kind ~= "counter" and not trial.level then
            bad(trial, "missing suggested level (journal/up-next need it)")
        end

        if trial.rankTrial then
            if c < 1 or c > 3 then
                bad(trial, "rankTrial only makes sense in chapters 1-3")
            elseif rankTrials[c] then
                bad(trial, "chapter " .. c .. " has two rank trials")
            end
            rankTrials[c] = true
        end
    end
    -- Every chapter below the journey's reach must have a gate, or ranks
    -- silently come free.
    for c = 1, math.min(maxChapter, 4) - 1 do
        if not rankTrials[c] then
            problems[#problems + 1] = def.id .. ": chapter " .. c ..
                " has no rank trial — rank " .. (c + 1) .. " would come free"
        end
    end
    return problems
end

-- ------------------------------------------------------------------------
-- Wiring (game only; tests call the handlers directly)
-- ------------------------------------------------------------------------
function T.Init()
    local d = db()
    if d and d.active and not d.trialsMeta then
        -- Characters from before trials existed: seed their rank silently.
        local def = activeDef()
        d.trialsMeta = { rank = def and (T.RankInfo(def)) or rankFromLevel(UnitLevel("player")) }
    end
    if not CreateFrame then return end

    local f = CreateFrame("Frame")
    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    f:RegisterEvent("ZONE_CHANGED")
    f:RegisterEvent("ZONE_CHANGED_INDOORS")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:RegisterEvent("CHAT_MSG_LOOT")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

    f:SetScript("OnEvent", function(_, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, sub, _, srcGUID, _, _, _, dstGUID, dstName, _, _, _, spellName =
                CombatLogGetCurrentEventInfo()
            T.OnCombatEvent(sub, srcGUID, dstGUID, dstName, spellName)
        elseif event == "PLAYER_TARGET_CHANGED" then
            T.NoteUnit("target")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            T.NoteUnit("mouseover")
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            T.OnEquip()
        elseif event == "CHAT_MSG_LOOT" then
            T.OnLoot((...))
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local _, _, spellID = ...
            local name
            if GetSpellInfo then
                name = GetSpellInfo(spellID)
            elseif C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(spellID)
                name = info and info.name
            end
            T.OnSpellSuccess(name)
        elseif event == "PLAYER_LEVEL_UP" then
            T.InvalidateRank()
            -- UnitLevel can lag the event by a frame; check shortly after.
            C_Timer.After(0.5, function() T.CheckRank(true) end)
        elseif event == "PLAYER_ENTERING_WORLD" then
            T.InvalidateRank()
            T.OnEquip()
            T.OnZone()
        else -- the ZONE_CHANGED family
            T.OnZone()
        end
    end)

    hooksecurefunc("DoEmote", function(emote) T.OnEmote(emote) end)
    T.frame = f
end
