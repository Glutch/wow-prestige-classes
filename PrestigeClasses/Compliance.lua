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
    for _, slot in ipairs({ "MainHandSlot", "SecondaryHandSlot" }) do
        local link = Util.EquippedLink(slot)
        if link then
            local itemType, subType = Util.ItemTypeInfo(link)
            -- Only judge actual weapons; an off-hand shield/holdable is covered
            -- by forbidShield or simply ignored here.
            if itemType == "Weapon" then
                count = count + 1
                if not Util.ListContains(def.weaponTypes, subType) then
                    offenders[#offenders + 1] = link
                end
            end
        end
    end
    local ok = #offenders == 0 and count > 0
    out[#out + 1] = res(
        "Weapon: " .. joinOr(def.weaponTypes),
        ok,
        count == 0 and "Equip an allowed weapon"
            or (#offenders == 0 and "Your weapon fits the discipline"
                or ("Wrong weapon: " .. table.concat(offenders, ", "))),
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

-- ---- suggestions ---------------------------------------------------------

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
    checkForbidShield(def, out)
    checkRangedTypes(def, out)
    checkPet(def, out)
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
