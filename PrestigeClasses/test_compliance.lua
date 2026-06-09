-- Offline test harness: mocks the WoW API and runs the compliance engine
-- against the real Data.lua rulesets. Run with: lua test_compliance.lua
-- This validates Util + Data + Compliance logic without launching the game.

-- ---- mock world state ----------------------------------------------------
local world = {
    class = "WARRIOR", className = "Warrior",
    race = "Orc", raceName = "Orc",
    level = 30,
    equipped = {},   -- slotName -> { link, type, subType }
    pet = false,
    skills = {},     -- name -> true
}

-- slotName -> numeric id (values arbitrary, just must be stable)
local SLOT_IDS = {
    HeadSlot=1, ChestSlot=5, ShoulderSlot=3, WaistSlot=6, LegsSlot=7,
    FeetSlot=8, WristSlot=9, HandsSlot=10, MainHandSlot=16,
    SecondaryHandSlot=17, RangedSlot=18,
}
local ID_TO_SLOT = {}
for name, id in pairs(SLOT_IDS) do ID_TO_SLOT[id] = name end

-- ---- WoW API stubs -------------------------------------------------------
function UnitClass() return world.className, world.class end
function UnitRace() return world.raceName, world.race end
function UnitLevel() return world.level end
function UnitExists(u) return u == "pet" and world.pet or false end
function GetInventorySlotInfo(name) return SLOT_IDS[name] end
function GetInventoryItemLink(_, id)
    local slot = ID_TO_SLOT[id]
    local item = world.equipped[slot]
    return item and item.link or nil
end
-- our links are just plain strings keyed in a table; resolve type info from there
local LINK_INFO = {}
function GetItemInfoInstant(link)
    local i = LINK_INFO[link]
    if not i then return nil end
    return i.id, i.type, i.subType, i.equipLoc
end
function GetNumSkillLines()
    local n = 0
    for _ in pairs(world.skills) do n = n + 1 end
    return n
end
function GetSkillLineInfo(i)
    local idx, names = 0, {}
    for name in pairs(world.skills) do names[#names+1] = name end
    return names[i], false
end

-- helper to register & equip an item
local function equip(slot, link, itemType, subType)
    LINK_INFO[link] = { id = link, type = itemType, subType = subType, equipLoc = "" }
    world.equipped[slot] = { link = link }
end
local function clear() world.equipped = {} end

-- ---- load addon modules --------------------------------------------------
local PC = {}
local function loadmod(path)
    local chunk = assert(loadfile(path))
    chunk("PrestigeClasses", PC)
end
loadmod("Util.lua")
loadmod("Data.lua")
loadmod("Compliance.lua")

-- ---- tiny assert framework ----------------------------------------------
local pass, fail = 0, 0
local function check(name, cond)
    if cond then pass = pass + 1; print("  ok  " .. name)
    else fail = fail + 1; print("  FAIL " .. name) end
end

-- ========================================================================
-- Test 1: Blademaster — compliant orc warrior
-- ========================================================================
print("\n[Blademaster] compliant orc warrior, 2H sword, no head/chest")
world.class, world.className = "WARRIOR", "Warrior"
world.race, world.raceName = "Orc", "Orc"
world.level = 30
clear()
equip("MainHandSlot", "Sword2H", "Weapon", "Two-Handed Swords")
local def = PC.ClassById["blademaster"]
local _, s = PC.Compliance.Evaluate(def)
check("compliant", s.compliant == true)
check("identity ok", s.identityOk == true)

print("[Blademaster] wearing a helm -> broken")
equip("HeadSlot", "Helm", "Armor", "Mail")
local _, s2 = PC.Compliance.Evaluate(def)
check("not compliant with helm", s2.compliant == false)

print("[Blademaster] wrong weapon (axe) -> broken")
clear()
equip("MainHandSlot", "Axe2H", "Weapon", "Two-Handed Axes")
local _, s3 = PC.Compliance.Evaluate(def)
check("not compliant with axe", s3.compliant == false)

print("[Blademaster] human warrior -> identity fails")
world.race, world.raceName = "Human", "Human"
clear()
equip("MainHandSlot", "Sword2H", "Weapon", "Two-Handed Swords")
local _, s4 = PC.Compliance.Evaluate(def)
check("identity fails for human", s4.identityOk == false)

-- ========================================================================
-- Test 2: Beastmaster — pet requirement
-- ========================================================================
print("\n[Beastmaster] hunter with pet")
world.class, world.className = "HUNTER", "Hunter"
world.race, world.raceName = "Orc", "Orc"
clear()
world.pet = true
local bm = PC.ClassById["beastmaster"]
local _, b1 = PC.Compliance.Evaluate(bm)
check("compliant with pet", b1.compliant == true)
world.pet = false
local _, b2 = PC.Compliance.Evaluate(bm)
check("broken without pet", b2.compliant == false)

-- ========================================================================
-- Test 3: Marksman — forbid pet + ranged type
-- ========================================================================
print("\n[Marksman] gun, no pet")
clear()
world.pet = false
equip("RangedSlot", "Rifle", "Weapon", "Guns")
local mm = PC.ClassById["marksman"]
local _, m1 = PC.Compliance.Evaluate(mm)
check("compliant gun no pet", m1.compliant == true)
print("[Marksman] with a bow -> broken")
equip("RangedSlot", "Bow", "Weapon", "Bows")
local _, m2 = PC.Compliance.Evaluate(mm)
check("broken with bow", m2.compliant == false)
print("[Marksman] pet out -> broken")
equip("RangedSlot", "Rifle", "Weapon", "Guns")
world.pet = true
local _, m3 = PC.Compliance.Evaluate(mm)
check("broken with pet", m3.compliant == false)
world.pet = false

-- ========================================================================
-- Test 4: Archmage — cloth cap + staff + level + race
-- ========================================================================
print("\n[Archmage] human mage, cloth, staff, level 25")
world.class, world.className = "MAGE", "Mage"
world.race, world.raceName = "Human", "Human"
world.level = 25
clear()
equip("ChestSlot", "Robe", "Armor", "Cloth")
equip("MainHandSlot", "Staff", "Weapon", "Staves")
local am = PC.ClassById["archmage"]
local _, a1 = PC.Compliance.Evaluate(am)
check("compliant archmage", a1.compliant == true)
print("[Archmage] underlevel -> identity fails")
world.level = 10
local _, a2 = PC.Compliance.Evaluate(am)
check("identity fails underlevel", a2.identityOk == false)
world.level = 25
print("[Archmage] plate chest -> armor rule broken")
equip("ChestSlot", "Platebody", "Armor", "Plate")
local _, a3 = PC.Compliance.Evaluate(am)
check("broken with plate", a3.compliant == false)

-- ========================================================================
-- Test 5: Berserker — forbid shield, max armor mail
-- ========================================================================
print("\n[Berserker] orc warrior, no shield, mail ok")
world.class, world.className = "WARRIOR", "Warrior"
world.race, world.raceName = "Orc", "Orc"
clear()
equip("ChestSlot", "MailChest", "Armor", "Mail")
local bz = PC.ClassById["berserker"]
local _, z1 = PC.Compliance.Evaluate(bz)
check("compliant berserker mail", z1.compliant == true)
print("[Berserker] shield -> broken")
equip("SecondaryHandSlot", "Shield", "Armor", "Shields")
local _, z2 = PC.Compliance.Evaluate(bz)
check("broken with shield", z2.compliant == false)
print("[Berserker] plate -> broken")
clear()
equip("ChestSlot", "PlateChest", "Armor", "Plate")
local _, z3 = PC.Compliance.Evaluate(bz)
check("broken with plate", z3.compliant == false)

-- ========================================================================
-- Test 6: profession suggestion never fails identity/rules
-- ========================================================================
print("\n[Profession] suggestion is info-only")
world.class, world.className = "WARRIOR", "Warrior"
world.race, world.raceName = "Orc", "Orc"
clear()
equip("MainHandSlot", "Sword2H", "Weapon", "Two-Handed Swords")
world.skills = {} -- no professions known
local _, p1 = PC.Compliance.Evaluate(PC.ClassById["blademaster"])
check("compliant despite no profession", p1.compliant == true)

-- ---- summary -------------------------------------------------------------
print(string.format("\n==== %d passed, %d failed ====", pass, fail))
os.exit(fail == 0 and 0 or 1)
