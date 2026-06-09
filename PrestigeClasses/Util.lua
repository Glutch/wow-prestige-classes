local ADDON, PC = ...

PC.Util = {}
local Util = PC.Util

-- Armor materials ranked from lightest to heaviest. Used to enforce a "max
-- armor weight" rule (e.g. a Cloth-only prestige class is violated by any
-- Leather/Mail/Plate piece). Non-armor subtypes (Shields, Miscellaneous,
-- Librams, etc.) are intentionally absent so they never trip the weight check.
local ARMOR_RANK = {
    ["Cloth"] = 1,
    ["Leather"] = 2,
    ["Mail"] = 3,
    ["Plate"] = 4,
}
Util.ARMOR_RANK = ARMOR_RANK

-- Equipment slots that carry an armor "material" we want to weigh. Cloaks,
-- rings, trinkets and necks are excluded because their material does not
-- reflect a class's armor proficiency.
Util.ARMOR_SLOTS = {
    "HeadSlot", "ShoulderSlot", "ChestSlot", "WaistSlot",
    "LegsSlot", "FeetSlot", "WristSlot", "HandsSlot",
}

-- Returns the localized class name and the uppercase English class token
-- (e.g. "WARRIOR"). The token is what our rulesets compare against.
function Util.PlayerClass()
    local localized, token = UnitClass("player")
    return token, localized
end

-- Returns the race file token (e.g. "Orc", "Scourge", "NightElf") plus the
-- localized name. The file token is stable across locales, the localized name
-- is for display.
function Util.PlayerRace()
    local localized, file = UnitRace("player")
    return file, localized
end

-- Resolves an equipment slot name ("HeadSlot") to the item link currently
-- worn there, or nil if the slot is empty.
function Util.EquippedLink(slotName)
    local slotId = GetInventorySlotInfo(slotName)
    if not slotId then return nil end
    return GetInventoryItemLink("player", slotId)
end

-- GetItemInfoInstant is synchronous (no server round-trip) and gives us the
-- item type, subtype and equip location straight from the item ID, which is
-- exactly what our rules need: armor material or weapon class.
-- Returns: itemType, itemSubType, itemEquipLoc (any may be nil).
function Util.ItemTypeInfo(link)
    if not link then return nil end
    local _, itemType, itemSubType, itemEquipLoc = GetItemInfoInstant(link)
    return itemType, itemSubType, itemEquipLoc
end

-- Builds a set of the profession (and secondary skill) names the player
-- currently knows, e.g. { Blacksmithing = true, Mining = true }.
function Util.KnownProfessions()
    local known = {}
    for i = 1, GetNumSkillLines() do
        local name, isHeader = GetSkillLineInfo(i)
        if name and not isHeader then
            known[name] = true
        end
    end
    return known
end

-- Convenience: true when the named profession is trained.
function Util.HasProfession(name)
    local _, isHeader = nil, nil
    for i = 1, GetNumSkillLines() do
        local sName, sHeader = GetSkillLineInfo(i)
        if sName == name and not sHeader then
            return true
        end
    end
    return false
end

-- Membership helper for whitelist tables stored as arrays.
function Util.ListContains(list, value)
    if not list then return false end
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end
