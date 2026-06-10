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
    talentTrees = {}, -- treeName -> pointsSpent
    talentRanks = {}, -- talentName -> currentRank
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
local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    table.sort(keys)
    return keys
end
function GetNumTalentTabs()
    return #sortedKeys(world.talentTrees)
end
function GetTalentTabInfo(i)
    local name = sortedKeys(world.talentTrees)[i]
    return name, nil, name and world.talentTrees[name] or 0, ""
end
function GetNumTalents(tab)
    -- all known talents reported under the first tab; Util merges across tabs
    return tab == 1 and #sortedKeys(world.talentRanks) or 0
end
function GetTalentInfo(tab, i)
    local name = sortedKeys(world.talentRanks)[i]
    return name, nil, 1, 1, name and world.talentRanks[name] or 0, 1
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
world.talentTrees = { Arms = 21 }
world.talentRanks = {}
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
world.talentTrees = { ["Beast Mastery"] = 16 }
world.talentRanks = {}
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
world.talentTrees = { Marksmanship = 16 }
world.talentRanks = { ["Aimed Shot"] = 1 }
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
world.talentTrees = { Arcane = 11 }
world.talentRanks = {}
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
world.level = 30
clear()
world.talentTrees = { Fury = 16 }
world.talentRanks = {}
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
world.talentTrees = { Arms = 21 }
world.talentRanks = {}
equip("MainHandSlot", "Sword2H", "Weapon", "Two-Handed Swords")
world.skills = {} -- no professions known
local _, p1 = PC.Compliance.Evaluate(PC.ClassById["blademaster"])
check("compliant despite no profession", p1.compliant == true)

-- ========================================================================
-- Test 7: Demon Hunter — dual wield requirement
-- ========================================================================
print("\n[Demon Hunter] night elf rogue, twin swords, bare head/chest")
world.class, world.className = "ROGUE", "Rogue"
world.race, world.raceName = "NightElf", "Night Elf"
world.level = 30
clear()
world.talentTrees = { Combat = 16 }
world.talentRanks = {}
equip("MainHandSlot", "SwordMH", "Weapon", "One-Handed Swords")
equip("SecondaryHandSlot", "SwordOH", "Weapon", "One-Handed Swords")
local dh = PC.ClassById["demonhunter"]
local _, d1 = PC.Compliance.Evaluate(dh)
check("compliant dual wield", d1.compliant == true)
print("[Demon Hunter] one sword only -> broken")
world.equipped["SecondaryHandSlot"] = nil
local _, d2 = PC.Compliance.Evaluate(dh)
check("broken single weapon", d2.compliant == false)
print("[Demon Hunter] helm on -> broken")
equip("SecondaryHandSlot", "SwordOH", "Weapon", "One-Handed Swords")
equip("HeadSlot", "Blindfold", "Armor", "Leather")
local _, d3 = PC.Compliance.Evaluate(dh)
check("broken with helm", d3.compliant == false)

-- ========================================================================
-- Test 8: Tinker — required profession is a hard rule
-- ========================================================================
print("\n[Tinker] gnome warrior with gun, Engineering required")
world.class, world.className = "WARRIOR", "Warrior"
world.race, world.raceName = "Gnome", "Gnome"
clear()
equip("RangedSlot", "BoomStick", "Weapon", "Guns")
world.skills = {}
local tk = PC.ClassById["tinker"]
local _, t1 = PC.Compliance.Evaluate(tk)
check("broken without Engineering", t1.compliant == false)
world.skills = { Engineering = true }
local _, t2 = PC.Compliance.Evaluate(tk)
check("compliant with Engineering", t2.compliant == true)
world.skills = {}

-- ========================================================================
-- Test 9: Eligibility helper
-- ========================================================================
print("\n[Eligible] race/class gating")
world.class, world.className = "WARRIOR", "Warrior"
world.race, world.raceName = "Orc", "Orc"
check("orc warrior eligible for blademaster",
    PC.Compliance.Eligible(PC.ClassById["blademaster"]) == true)
check("orc warrior not eligible for archmage",
    PC.Compliance.Eligible(PC.ClassById["archmage"]) == false)
check("any-race rule: orc warrior eligible for gladiator",
    PC.Compliance.Eligible(PC.ClassById["gladiator"]) == true)

-- ========================================================================
-- Test 10: Buccaneer — sword + gun rogue
-- ========================================================================
print("\n[Buccaneer] rogue with cutlass and pistol")
world.class, world.className = "ROGUE", "Rogue"
world.race, world.raceName = "Human", "Human"
clear()
world.talentTrees = { Combat = 16 }
world.talentRanks = { Riposte = 1 }
equip("MainHandSlot", "Cutlass", "Weapon", "One-Handed Swords")
equip("RangedSlot", "Pistol", "Weapon", "Guns")
local bc = PC.ClassById["buccaneer"]
local _, c1 = PC.Compliance.Evaluate(bc)
check("compliant buccaneer", c1.compliant == true)
print("[Buccaneer] bow instead of gun -> broken")
equip("RangedSlot", "Bow", "Weapon", "Bows")
local _, c2 = PC.Compliance.Evaluate(bc)
check("broken with bow", c2.compliant == false)

-- ========================================================================
-- Test 11: talent tree scaling + key talents
-- ========================================================================
print("\n[Talents] Blademaster at 60 with full Arms + key talents")
world.class, world.className = "WARRIOR", "Warrior"
world.race, world.raceName = "Orc", "Orc"
world.level = 60
clear()
equip("MainHandSlot", "Sword2H", "Weapon", "Two-Handed Swords")
world.talentTrees = { Arms = 31 }
world.talentRanks = { ["Sweeping Strikes"] = 1, ["Mortal Strike"] = 1 }
local bl = PC.ClassById["blademaster"]
local _, t60 = PC.Compliance.Evaluate(bl)
check("compliant at 60 full Arms", t60.compliant == true)

print("[Talents] only 20 points in Arms at 60 -> broken")
world.talentTrees = { Arms = 20 }
local _, t60b = PC.Compliance.Evaluate(bl)
check("broken with shallow tree", t60b.compliant == false)

print("[Talents] missing Mortal Strike at 60 -> broken")
world.talentTrees = { Arms = 31 }
world.talentRanks = { ["Sweeping Strikes"] = 1 }
local _, t60c = PC.Compliance.Evaluate(bl)
check("broken without key talent", t60c.compliant == false)

print("[Talents] key talents not yet due at level 20 -> fine")
world.level = 20
world.talentTrees = { Arms = 11 }
world.talentRanks = {}
local _, t20 = PC.Compliance.Evaluate(bl)
check("compliant at 20, capstones pending", t20.compliant == true)

-- ========================================================================
-- Test 12: key talent rank requirement (Witch Doctor: Totemic Focus 5/5)
-- ========================================================================
print("\n[Witch Doctor] troll shaman, rank requirement")
world.class, world.className = "SHAMAN", "Shaman"
world.race, world.raceName = "Troll", "Troll"
world.level = 30
clear()
equip("MainHandSlot", "BoneKnife", "Weapon", "Daggers")
world.skills = { Alchemy = true }
world.talentTrees = { Restoration = 10 }
world.talentRanks = { ["Totemic Focus"] = 3 }
local wd = PC.ClassById["witchdoctor"]
local _, w1 = PC.Compliance.Evaluate(wd)
check("broken at rank 3/5", w1.compliant == false)
world.talentRanks = { ["Totemic Focus"] = 5 }
local _, w2 = PC.Compliance.Evaluate(wd)
check("compliant at rank 5/5", w2.compliant == true)
world.skills = {}

-- ========================================================================
-- Test 13: multi-class talent spec picks the player's class
-- ========================================================================
print("\n[Duelist] warrior uses Arms spec, rogue uses Combat spec")
world.level = 30
clear()
equip("MainHandSlot", "Rapier", "Weapon", "One-Handed Swords")
world.class, world.className = "WARRIOR", "Warrior"
world.race, world.raceName = "Human", "Human"
world.talentTrees = { Arms = 16 }
world.talentRanks = {}
local du = PC.ClassById["duelist"]
local _, du1 = PC.Compliance.Evaluate(du)
check("warrior duelist compliant on Arms", du1.compliant == true)
world.class, world.className = "ROGUE", "Rogue"
local _, du2 = PC.Compliance.Evaluate(du)
check("rogue duelist broken on Arms-only build", du2.compliant == false)
world.talentTrees = { Combat = 16 }
world.talentRanks = { Riposte = 1 }
local _, du3 = PC.Compliance.Evaluate(du)
check("rogue duelist compliant on Combat + Riposte", du3.compliant == true)

-- ========================================================================
-- Test 14: fishing poles suspend weapon vows instead of breaking them
-- ========================================================================
print("\n[Fishing] blademaster with pole in hand stays compliant")
world.class, world.className = "WARRIOR", "Warrior"
world.race, world.raceName = "Orc", "Orc"
world.level = 30
clear()
world.talentTrees = { Arms = 21 }
world.talentRanks = {}
equip("MainHandSlot", "Pole", "Weapon", "Fishing Poles")
local _, f1 = PC.Compliance.Evaluate(PC.ClassById["blademaster"])
check("compliant while fishing", f1.compliant == true)

print("[Fishing] bare hands (no pole) still break the weapon vow")
clear()
local _, f2 = PC.Compliance.Evaluate(PC.ClassById["blademaster"])
check("broken bare-handed", f2.compliant == false)

print("[Fishing] dual-wield path tolerates the pole")
world.class, world.className = "ROGUE", "Rogue"
world.race, world.raceName = "NightElf", "Night Elf"
clear()
world.talentTrees = { Combat = 16 }
world.talentRanks = {}
equip("MainHandSlot", "Pole", "Weapon", "Fishing Poles")
local _, f3 = PC.Compliance.Evaluate(PC.ClassById["demonhunter"])
check("demon hunter compliant while fishing", f3.compliant == true)

-- ---- summary -------------------------------------------------------------
print(string.format("\n==== %d passed, %d failed ====", pass, fail))
os.exit(fail == 0 and 0 or 1)
