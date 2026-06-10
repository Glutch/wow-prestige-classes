local ADDON, PC = ...
local Util = PC.Util

PC.Compliance = {}
local C = PC.Compliance

-- A check result: { label, ok, detail, kind }
--   kind = "identity"  -> race/class/level; cannot be fixed by gear (reroll-level)
--   kind = "rule"      -> live gear/pet rules the player can correct right now
--   kind = "info"      -> suggestions (professions); never counts as a failure
local function res(label, ok, detail, kind)
    return { label = label, ok = ok, detail = detail, kind = kind or "rule" }
end

-- Returns a localized, human list like "Orc or Troll".
local function joinOr(list)
    if not list or #list == 0 then return "" end
    if #list == 1 then return list[1] end
    return table.concat(list, ", ", 1, #list - 1) .. " or " .. list[#list]
end

-- ---- identity checks (race / class / level) -----------------------------

local function checkRace(def, out)
    if not def.races then return end
    local raceFile, raceName = Util.PlayerRace()
    local ok = Util.ListContains(def.races, raceFile)
    out[#out + 1] = res(
        "Race: " .. joinOr(def.races),
        ok,
        ok and ("You are " .. raceName) or ("You are " .. raceName .. " — reroll required"),
        "identity"
    )
end

local function checkClass(def, out)
    if not def.classes then return end
    local classToken, className = Util.PlayerClass()
    -- Display localized class names is overkill; tokens read fine capitalized.
    local ok = Util.ListContains(def.classes, classToken)
    out[#out + 1] = res(
        "Class: " .. joinOr(def.classes),
        ok,
        ok and ("You are a " .. className) or ("You are a " .. className .. " — reroll required"),
        "identity"
    )
end

local function checkLevel(def, out)
    if not def.minLevel then return end
    local lvl = UnitLevel("player")
    local ok = lvl >= def.minLevel
    out[#out + 1] = res(
        "Level " .. def.minLevel .. "+",
        ok,
        ok and ("Level " .. lvl) or ("Level " .. lvl .. " — keep leveling"),
        "identity"
    )
end

-- ---- live gear / pet rules ----------------------------------------------

local function checkForbiddenSlots(def, out)
    if not def.forbidSlots then return end
    for _, slot in ipairs(def.forbidSlots) do
        local link = Util.EquippedLink(slot)
        local pretty = slot:gsub("Slot", "")
        out[#out + 1] = res(
            "No " .. pretty:lower() .. " equipped",
            link == nil,
            link and ("Remove: " .. link) or "Slot is empty",
            "rule"
        )
    end
end

local function checkMaxArmor(def, out)
    if not def.maxArmor then return end
    local cap = Util.ARMOR_RANK[def.maxArmor]
    if not cap then return end
    local offenders = {}
    for _, slot in ipairs(Util.ARMOR_SLOTS) do
        local link = Util.EquippedLink(slot)
        if link then
            local _, subType = Util.ItemTypeInfo(link)
            local rank = subType and Util.ARMOR_RANK[subType]
            if rank and rank > cap then
                offenders[#offenders + 1] = link
            end
        end
    end
    out[#out + 1] = res(
        "Armor: " .. def.maxArmor .. " or lighter",
        #offenders == 0,
        #offenders == 0 and ("All worn armor is " .. def.maxArmor .. " or lighter")
            or ("Too heavy: " .. table.concat(offenders, ", ")),
        "rule"
    )
end

local function checkWeaponTypes(def, out)
    if not def.weaponTypes then return end
    local offenders = {}
    local count = 0
    local fishing = false
    for _, slot in ipairs({ "MainHandSlot", "SecondaryHandSlot" }) do
        local link = Util.EquippedLink(slot)
        if link then
            local itemType, subType = Util.ItemTypeInfo(link)
            -- Only judge actual weapons; an off-hand shield/holdable is covered
            -- by forbidShield or simply ignored here.
            if itemType == "Weapon" then
                -- A fishing pole is a tool, not a betrayal of the discipline.
                if subType == "Fishing Poles" then
                    fishing = true
                else
                    count = count + 1
                    if not Util.ListContains(def.weaponTypes, subType) then
                        offenders[#offenders + 1] = link
                    end
                end
            end
        end
    end
    local ok = #offenders == 0 and (count > 0 or fishing)
    local detail
    if #offenders > 0 then
        detail = "Wrong weapon: " .. table.concat(offenders, ", ")
    elseif count == 0 and fishing then
        detail = "Fishing — the vow rests while you fish"
    elseif count == 0 then
        detail = "Equip an allowed weapon"
    else
        detail = "Your weapon fits the discipline"
    end
    out[#out + 1] = res("Weapon: " .. joinOr(def.weaponTypes), ok, detail, "rule")
end

local function checkDualWield(def, out)
    if not def.requireDualWield then return end
    local holding = 0
    local fishing = false
    for _, slot in ipairs({ "MainHandSlot", "SecondaryHandSlot" }) do
        local link = Util.EquippedLink(slot)
        if link then
            local itemType, subType = Util.ItemTypeInfo(link)
            if itemType == "Weapon" then
                if subType == "Fishing Poles" then
                    fishing = true
                else
                    holding = holding + 1
                end
            end
        end
    end
    -- A pole occupies both hands; fishing suspends the vow rather than breaks it.
    local ok = holding == 2 or fishing
    out[#out + 1] = res(
        "A weapon in each hand",
        ok,
        (fishing and holding == 0) and "Fishing — the vow rests while you fish"
            or (ok and "Both hands armed"
                or "Equip a weapon in both main and off hand"),
        "rule"
    )
end

local function checkForbidShield(def, out)
    if not def.forbidShield then return end
    local link = Util.EquippedLink("SecondaryHandSlot")
    local isShield = false
    if link then
        local _, subType = Util.ItemTypeInfo(link)
        isShield = (subType == "Shields")
    end
    out[#out + 1] = res(
        "No shield",
        not isShield,
        isShield and ("Remove: " .. link) or "No shield equipped",
        "rule"
    )
end

local function checkRangedTypes(def, out)
    if not def.rangedTypes then return end
    local link = Util.EquippedLink("RangedSlot")
    if not link then
        out[#out + 1] = res(
            "Ranged: " .. joinOr(def.rangedTypes),
            false,
            "Equip a " .. joinOr(def.rangedTypes),
            "rule"
        )
        return
    end
    local _, subType = Util.ItemTypeInfo(link)
    local ok = Util.ListContains(def.rangedTypes, subType)
    out[#out + 1] = res(
        "Ranged: " .. joinOr(def.rangedTypes),
        ok,
        ok and ("Equipped " .. (subType or "?")) or ("Wrong ranged weapon: " .. link),
        "rule"
    )
end

local function checkPet(def, out)
    if def.requirePet then
        local has = UnitExists("pet")
        out[#out + 1] = res("Active pet/minion", has,
            has and "Companion is summoned" or "Summon or tame a companion", "rule")
    end
    if def.forbidPet then
        local has = UnitExists("pet")
        out[#out + 1] = res("No pet", not has,
            has and "Dismiss your pet" or "Fighting solo", "rule")
    end
end

-- ---- talents ---------------------------------------------------------------

-- A path's talent spec may be shared (def.talents = { tree=..., keys=... })
-- or differ per class (def.talents = { WARRIOR = {...}, ROGUE = {...} }).
local function talentSpecFor(def)
    local t = def.talents
    if not t then return nil end
    if t.tree or t.keys then return t end
    return t[(Util.PlayerClass())]
end

-- How deep in the tree we expect a player of this level to be. Talent points
-- start at level 10; SLACK leaves a few points free for off-tree utility
-- until the target is reached (full target is expected by level 45 for 31).
local TREE_SLACK = 5
local function expectedTreePoints(target, level)
    local expected = level - 9 - TREE_SLACK
    if expected < 0 then expected = 0 end
    if expected > target then expected = target end
    return expected
end

local function checkTalents(def, out)
    local spec = talentSpecFor(def)
    if not spec then return end
    local level = UnitLevel("player")
    local trees, talents = Util.TalentSummary()

    if spec.tree then
        local target = spec.tree.points or 31
        local expected = expectedTreePoints(target, level)
        local have = trees[spec.tree.name] or 0
        if expected > 0 then
            out[#out + 1] = res(
                "Talents: " .. spec.tree.name .. " (" .. target .. "+ pts)",
                have >= expected,
                have .. "/" .. target .. " points — your level calls for at least " .. expected,
                "rule"
            )
        else
            out[#out + 1] = res(
                "Talents: " .. spec.tree.name .. " (" .. target .. "+ pts)",
                true,
                "Spend your points in " .. spec.tree.name .. " as you level",
                "info"
            )
        end
    end

    for _, k in ipairs(spec.keys or {}) do
        local needRank = k.rank or 1
        local haveRank = talents[k.name] or 0
        local label = "Talent: " .. k.name ..
            (needRank > 1 and (" (rank " .. needRank .. ")") or "")
        if level >= (k.level or 10) then
            out[#out + 1] = res(
                label,
                haveRank >= needRank,
                haveRank >= needRank and "Learned"
                    or ("Learn it — the path demands it from level " .. (k.level or 10)),
                "rule"
            )
        else
            out[#out + 1] = res(
                label,
                haveRank >= needRank,
                "Required from level " .. (k.level or 10),
                "info"
            )
        end
    end
end

-- ---- professions ----------------------------------------------------------

-- Hard requirement: at least one of the listed professions must be trained.
local function checkRequiredProfession(def, out)
    if not def.requireProfession then return end
    local known = Util.KnownProfessions()
    local have = {}
    for _, p in ipairs(def.requireProfession) do
        if known[p] then have[#have + 1] = p end
    end
    out[#out + 1] = res(
        "Trained: " .. joinOr(def.requireProfession),
        #have > 0,
        #have > 0 and ("Trained in " .. table.concat(have, ", "))
            or ("Visit a trainer — " .. joinOr(def.requireProfession) .. " is this path's craft"),
        "rule"
    )
end

local function checkProfession(def, out)
    if not def.profession then return end
    local known = Util.KnownProfessions()
    local have = {}
    for _, p in ipairs(def.profession) do
        if known[p] then have[#have + 1] = p end
    end
    out[#out + 1] = res(
        "Profession: " .. joinOr(def.profession),
        #have > 0,
        #have > 0 and ("Trained: " .. table.concat(have, ", ")) or "Suggested, not required",
        "info"
    )
end

-- Evaluate the full ruleset. Returns an ordered list of check results plus a
-- summary { identityOk, rulesTotal, rulesPassed, compliant }.
function C.Evaluate(def)
    local out = {}
    checkRace(def, out)
    checkClass(def, out)
    checkLevel(def, out)
    checkForbiddenSlots(def, out)
    checkMaxArmor(def, out)
    checkWeaponTypes(def, out)
    checkDualWield(def, out)
    checkForbidShield(def, out)
    checkRangedTypes(def, out)
    checkPet(def, out)
    checkTalents(def, out)
    checkRequiredProfession(def, out)
    checkProfession(def, out)

    local identityOk, rulesTotal, rulesPassed = true, 0, 0
    for _, r in ipairs(out) do
        if r.kind == "identity" then
            if not r.ok then identityOk = false end
        elseif r.kind == "rule" then
            rulesTotal = rulesTotal + 1
            if r.ok then rulesPassed = rulesPassed + 1 end
        end
    end

    local summary = {
        identityOk = identityOk,
        rulesTotal = rulesTotal,
        rulesPassed = rulesPassed,
        -- "Compliant" means you are eligible (identity) AND every live rule passes.
        compliant = identityOk and rulesPassed == rulesTotal,
    }
    return out, summary
end

-- True when the player's race and class can ever satisfy this path. Level is
-- deliberately ignored: an underleveled character can still grow into it.
function C.Eligible(def)
    if def.races and not Util.ListContains(def.races, (Util.PlayerRace())) then
        return false
    end
    if def.classes and not Util.ListContains(def.classes, (Util.PlayerClass())) then
        return false
    end
    return true
end
