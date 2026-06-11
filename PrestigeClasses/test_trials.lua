-- Offline test harness for the trial engine: mocks the WoW API and plays a
-- Mountain King's journey from Coldridge Valley to the Molten Core.
-- Run with: lua test_trials.lua

-- ---- mock world state ------------------------------------------------------
local world = {
    class = "WARRIOR", className = "Warrior",
    race = "Dwarf", raceName = "Dwarf",
    level = 12,
    equipped = {},    -- slotName -> { link }
    pet = false,
    skills = {},
    talentTrees = {},
    talentRanks = {},
    zone = "Dun Morogh", subzone = "", minimapZone = "",
    buffs = {},       -- array of buff names
    inGroup = false,
    now = 1000.0,     -- GetTime
    target = nil,     -- { guid, classification, canAttack }
}

local SLOT_IDS = {
    HeadSlot=1, ChestSlot=5, ShoulderSlot=3, WaistSlot=6, LegsSlot=7,
    FeetSlot=8, WristSlot=9, HandsSlot=10, MainHandSlot=16,
    SecondaryHandSlot=17, RangedSlot=18,
}
local ID_TO_SLOT = {}
for name, id in pairs(SLOT_IDS) do ID_TO_SLOT[id] = name end

-- ---- WoW API stubs ---------------------------------------------------------
time = os.time
function GetTime() return world.now end
function UnitClass() return world.className, world.class end
function UnitRace() return world.raceName, world.race end
function UnitLevel() return world.level end
function IsInGroup() return world.inGroup end
function UnitExists(u)
    if u == "pet" then return world.pet end
    if u == "target" then return world.target ~= nil end
    return false
end
function UnitGUID(u)
    if u == "player" then return "guid-player" end
    if u == "pet" then return world.pet and "guid-pet" or nil end
    if u == "target" then return world.target and world.target.guid or nil end
    return nil
end
function UnitCanAttack(_, u)
    return u == "target" and world.target ~= nil and world.target.canAttack
end
function UnitClassification(u)
    return u == "target" and world.target and world.target.classification or "normal"
end
function UnitBuff(_, i) return world.buffs[i] end
function GetRealZoneText() return world.zone end
function GetSubZoneText() return world.subzone end
function GetMinimapZoneText() return world.minimapZone end
function GetInventorySlotInfo(name) return SLOT_IDS[name] end
function GetInventoryItemLink(_, id)
    local slot = ID_TO_SLOT[id]
    local item = world.equipped[slot]
    return item and item.link or nil
end
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
    local names = {}
    for name in pairs(world.skills) do names[#names+1] = name end
    return names[i], false
end
local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    table.sort(keys)
    return keys
end
function GetNumTalentTabs() return #sortedKeys(world.talentTrees) end
function GetTalentTabInfo(i)
    local name = sortedKeys(world.talentTrees)[i]
    return name, nil, name and world.talentTrees[name] or 0, ""
end
function GetNumTalents(tab)
    return tab == 1 and #sortedKeys(world.talentRanks) or 0
end
function GetTalentInfo(tab, i)
    local name = sortedKeys(world.talentRanks)[i]
    return name, nil, 1, 1, name and world.talentRanks[name] or 0, 1
end

local function equip(slot, link, itemType, subType)
    LINK_INFO[link] = { id = link, type = itemType, subType = subType, equipLoc = "" }
    world.equipped[slot] = { link = link }
end

-- ---- load addon modules ----------------------------------------------------
local PC = {}
local function loadmod(path)
    local chunk = assert(loadfile(path))
    chunk("PrestigeClasses", PC)
end
loadmod("Util.lua")
loadmod("Data.lua")
loadmod("Compliance.lua")
loadmod("Trials.lua")
loadmod("Trials/MountainKing.lua")
loadmod("Trials/Blademaster.lua")

local T = PC.Trials

-- ---- tiny assert framework -------------------------------------------------
local pass, fail = 0, 0
local function check(name, cond)
    if cond then pass = pass + 1; print("  ok  " .. name)
    else fail = fail + 1; print("  FAIL " .. name) end
end

local function trial(id)
    for _, tr in ipairs(PC.ClassById.mountainking.trials) do
        if tr.id == id then return tr end
    end
end

-- Kill helper: deal a swing, then the mob dies.
local guidCounter = 0
local function slay(name)
    guidCounter = guidCounter + 1
    local guid = "guid-" .. guidCounter
    T.OnCombatEvent("SWING_DAMAGE", "guid-player", guid, name, nil)
    T.OnCombatEvent("UNIT_DIED", nil, guid, name, nil)
    return guid
end

-- ---- the journey begins ----------------------------------------------------
PrestigeClassesCharDB = { active = "mountainking", stats = { chosenAt = time(), breaks = 0 } }
T.OnPathChanged()
local mk = PC.ClassById.mountainking

-- A by-the-book Mountain King at level 12: 2H mace, gun on the back.
equip("MainHandSlot", "[Stone Hammer]", "Weapon", "Two-Handed Maces")
equip("RangedSlot", "[Blunderbuss]", "Weapon", "Guns")

print("\n[Rank] level 12 dwarf is an Initiate")
local rank, title, pending = T.RankInfo(mk)
check("rank 1", rank == 1)
check("title Initiate", title == "Initiate")
check("nothing pending", pending == nil)

print("\n[Rank] browsed paths (and paths without trials) rank by level alone")
world.level = 45
T.InvalidateRank()
local bRank = T.RankInfo(PC.ClassById.blademaster) -- has trials, but not walked
check("non-active path uses level rank", bRank == 3)
local zRank = T.RankInfo(PC.ClassById.berserker)   -- no trials at all
check("trial-less path uses level rank", zRank == 3)
world.level = 12
T.InvalidateRank()

print("\n[Emote] the oath only counts at the High Seat")
T.OnEmote("KNEEL")
check("kneeling in the wilds does nothing", not T.IsComplete(trial("mk_oath")))
world.zone, world.subzone = "Ironforge", "The High Seat"
T.OnEmote("DANCE")
check("wrong emote does nothing", not T.IsComplete(trial("mk_oath")))
T.OnEmote("KNEEL")
check("oath sworn at the High Seat", T.IsComplete(trial("mk_oath")))

print("\n[Kill] Grik'nir falls only if we drew blood")
T.OnCombatEvent("UNIT_DIED", nil, "guid-x", "Grik'nir the Cold", nil)
check("unattributed death not credited", not T.IsComplete(trial("mk_coldark")))
slay("Grik'nir the Cold")
check("our kill credited", T.IsComplete(trial("mk_coldark")))

print("\n[Kill] Vagash demands solitude and clean vows")
world.inGroup = true
slay("Vagash")
check("no credit in a group", not T.IsComplete(trial("mk_wendigo")))
world.inGroup = false
equip("MainHandSlot", "[Some Axe]", "Weapon", "Two-Handed Axes") -- vow broken
slay("Vagash")
check("no credit with broken vows", not T.IsComplete(trial("mk_wendigo")))
equip("MainHandSlot", "[Stone Hammer]", "Weapon", "Two-Handed Maces")
slay("Vagash")
check("solo + clean = credited", T.IsComplete(trial("mk_wendigo")))

print("\n[Cast] the maul must be made at the Great Forge")
world.zone, world.subzone = "Dun Morogh", ""
T.OnSpellSuccess("Heavy Copper Maul")
check("crafting elsewhere does nothing", not T.IsComplete(trial("mk_forge")))
world.zone, world.subzone = "Ironforge", "The Great Forge"
T.OnSpellSuccess("Heavy Copper Maul")
check("crafted at the Great Forge", T.IsComplete(trial("mk_forge")))

print("\n[Emote] saluting the dam (subzone matches by substring)")
world.zone, world.subzone = "Loch Modan", "The Stonewrought Dam"
T.OnEmote("SALUTE")
check("masons saluted", T.IsComplete(trial("mk_dam")))

print("\n[Counter] the grudge book and its honorifics")
for i = 1, 9 do slay("Dark Iron Spy") end
slay("Anvilrage Soldier") -- BRD garrison names count toward the grudge too
check("10 dark irons counted", T.State("mk_grudge").progress == 10)
local honorifics = T.Honorifics(mk)
check("Grudgebearer earned", honorifics[1] == "Grudgebearer")
check("grudge never reads complete", not T.IsComplete(trial("mk_grudge")))

print("\n[Lock] chapter II is sealed to an Initiate")
world.zone, world.subzone = "Wetlands", "Thandol Span"
T.OnEmote("MOURN")
check("mourning locked at rank 1", not T.IsComplete(trial("mk_span")))

print("\n[Rank trial] level grants nothing without the deed")
world.level = 25
world.talentTrees = { Arms = 16 } -- keep the vows clean as we level
T.InvalidateRank()
rank, title, pending = T.RankInfo(mk)
check("still rank 1 at level 25", rank == 1)
check("Chok'sul bars the way", pending and pending.id == "mk_ogre")

print("\n[Up next] the pending rank trial leads the list")
local up = T.UpNext(mk, 3)
check("only the gate remains in reach", #up == 1 and up[1].id == "mk_ogre")

slay("Chok'sul")
rank, title = T.RankInfo(mk)
check("Disciple after the ogre falls", rank == 2 and title == "Disciple")

print("\n[Up next] ready deeds first, easiest first")
local up2 = T.UpNext(mk, 3)
check("three suggestions", #up2 == 3)
check("Smite's hammer (lvl 20) tops the list at 25", up2[1].id == "mk_smite")
check("the Span (lvl 24) follows", up2[2].id == "mk_span")
check("level-30+ deeds wait their turn",
    up2[3].level <= 25)

print("\n[Unlock] chapter II opens to a Disciple")
T.OnEmote("MOURN")
check("mourning at the Span credited", T.IsComplete(trial("mk_span")))
T.OnZone()
check("visiting the Span is not Grim Batol", not T.IsComplete(trial("mk_grimbatol")))
world.subzone = "Grim Batol"
T.OnZone()
check("the gates of Grim Batol witnessed", T.IsComplete(trial("mk_grimbatol")))

print("\n[Proc] fifty storms from the mace")
for i = 1, 50 do
    T.OnCombatEvent("SPELL_AURA_APPLIED", "guid-player", "guid-mob" .. i,
        "Mosshide Gnoll", "Mace Stun Effect")
end
check("stormhammer complete", T.IsComplete(trial("mk_stormhammer")))
local hasStormhammer = false
for _, h in ipairs(T.Honorifics(mk)) do
    if h == "Stormhammer" then hasStormhammer = true end
end
check("Stormhammer honorific", hasStormhammer)

print("\n[Multihit] thunder must catch three at once")
T.OnCombatEvent("SPELL_DAMAGE", "guid-player", "guid-a", "Gnoll", "Thunder Clap")
T.OnCombatEvent("SPELL_DAMAGE", "guid-player", "guid-b", "Gnoll", "Thunder Clap")
local thunder = T.State("mk_thunder")
check("two hits is not thunder", thunder == nil or thunder.progress == 0)
world.now = world.now + 5
for c = 1, 10 do
    for v = 1, 3 do
        T.OnCombatEvent("SPELL_DAMAGE", "guid-player", "guid-c" .. c .. v,
            "Gnoll", "Thunder Clap")
    end
    world.now = world.now + 5
end
check("ten true claps", T.IsComplete(trial("mk_thunder")))

print("\n[Counter] 25 Dragonmaw")
for i = 1, 25 do slay("Dragonmaw Grunt") end
check("dragonmaw debt collected", T.IsComplete(trial("mk_dragonmaw")))

print("\n[Equip] Smite's hammer claimed")
T.OnEquip()
check("no relic yet", not T.IsComplete(trial("mk_smite")))
equip("MainHandSlot", "[Smite's Mighty Hammer]", "Weapon", "Two-Handed Maces")
T.OnEquip()
check("relic wielded", T.IsComplete(trial("mk_smite")))

print("\n[Rank trial] the titans judge at 40")
world.level = 41
world.talentTrees = { Arms = 31 }
world.talentRanks = { ["Mace Specialization"] = 5 } -- key talent due from 36
T.InvalidateRank()
rank, _, pending = T.RankInfo(mk)
check("rank 2 until Archaedas", rank == 2 and pending and pending.id == "mk_titans")
slay("Archaedas")
rank, title = T.RankInfo(mk)
check("Exemplar after Uldaman", rank == 3 and title == "Exemplar")

print("\n[Avatar] elite kill while stone-skinned")
world.target = { guid = "guid-elite-1", classification = "elite", canAttack = true }
T.NoteUnit("target")
T.OnCombatEvent("SWING_DAMAGE", "guid-player", "guid-elite-1", "Greater Lava Spider", nil)
T.OnCombatEvent("UNIT_DIED", nil, "guid-elite-1", "Greater Lava Spider", nil)
check("no credit without Stoneform", not T.IsComplete(trial("mk_avatar")))
world.buffs = { "Battle Shout", "Stoneform" }
slay("Scarshield Grunt") -- not noted as elite
check("no credit on a non-elite", not T.IsComplete(trial("mk_avatar")))
world.target = { guid = "guid-elite-2", classification = "elite", canAttack = true }
T.NoteUnit("target")
T.OnCombatEvent("SWING_DAMAGE", "guid-player", "guid-elite-2", "Greater Lava Spider", nil)
T.OnCombatEvent("UNIT_DIED", nil, "guid-elite-2", "Greater Lava Spider", nil)
check("the Avatar rises", T.IsComplete(trial("mk_avatar")))
world.buffs = {}

print("\n[Loot] ten loads of Dark Iron ore")
T.OnLoot("Someone receives loot: [Dark Iron Ore].")
check("another's loot ignored", T.State("mk_veins") == nil or T.State("mk_veins").progress == 0)
for i = 1, 5 do T.OnLoot("You receive loot: [Dark Iron Ore].") end
T.OnLoot("You receive loot: [Dark Iron Ore]x5.")
check("ten ore mined", T.IsComplete(trial("mk_veins")))

print("\n[Cast] Dark Iron smelted at the Black Anvil")
world.zone, world.subzone = "Blackrock Depths", "The Black Anvil"
T.OnSpellSuccess("Smelt Dark Iron")
check("the Black Anvil rite", T.IsComplete(trial("mk_blackanvil")))

print("\n[Kills] Margol alone, the General buried")
slay("Margol the Rager")
check("Margol slain", T.IsComplete(trial("mk_margol")))
slay("General Angerforge")
check("Angerforge slain", T.IsComplete(trial("mk_angerforge")))

print("\n[Rank trial] the Usurper falls at 60")
world.level = 60
T.InvalidateRank()
rank, _, pending = T.RankInfo(mk)
check("rank 3 until the Emperor", rank == 3 and pending and pending.id == "mk_usurper")
slay("Emperor Dagran Thaurissan")
rank, title = T.RankInfo(mk)
check("Paragon at last", rank == 4 and title == "Paragon")

print("\n[Paragon deeds]")
slay("Ragnaros")
check("the Firelord answered for Thaurissan", T.IsComplete(trial("mk_ragnaros")))
local avenger = false
for _, h in ipairs(T.Honorifics(mk)) do
    if h == "Avenger of Khaz Modan" then avenger = true end
end
check("Avenger of Khaz Modan", avenger)
equip("MainHandSlot", "[Sulfuras, Hand of Ragnaros]", "Weapon", "Two-Handed Maces")
T.OnEquip()
check("Sulfuras in hand", T.IsComplete(trial("mk_sulfuras")))
world.zone, world.subzone, world.minimapZone = "Dun Morogh", "Kharanos", "Thunderbrew Distillery"
T.OnEmote("DRINK")
check("last call honored (minimap zone match)", T.IsComplete(trial("mk_lastcall")))

print("\n[Record] the books balance")
local done, total = T.Counts(mk)
-- still open: the grudge (10/200), The Unstoppable Force, the chapter III relic
check("all but three deeds done", total - done == 3)
check("grudge count is 10", T.State("mk_grudge").progress == 10)

print("\n[Lint] journey data validates")
local problems = T.Lint(mk)
for _, p in ipairs(problems) do print("    lint: " .. p) end
check("mountain king lints clean", #problems == 0)

local broken = { id = "test", trials = {
    { id = "a", chapter = 1, kind = "kill", name = "A", objective = "o" }, -- matches every kill
    { id = "a", chapter = 9, kind = "nope", name = "B", objective = "o" }, -- dup id, bad chapter+kind
    { id = "c", chapter = 2, kind = "counter", name = "C", objective = "o",
      milestones = { { count = 10 }, { count = 5 } } },                     -- non-ascending
    { id = "d", chapter = 4, kind = "emote", emote = "kneel", name = "D", objective = "o" },
} }
local bad = T.Lint(broken)
check("broken journey caught", #bad >= 6) -- incl. missing rank trials for ch 1-3

print("\n[Abandon] a new path starts a clean book")
T.OnPathChanged()
check("trials wiped", T.State("mk_oath") == nil)
local r2 = T.RankInfo(mk)
check("rank resets to 1 (deeds gone)", r2 == 1)

-- ---- the Blademaster's journey ----------------------------------------------
local bm = PC.ClassById.blademaster
local function bmTrial(id)
    for _, tr in ipairs(bm.trials) do
        if tr.id == id then return tr end
    end
end

print("\n[Blademaster] the journey lints clean")
local bmProblems = T.Lint(bm)
for _, p in ipairs(bmProblems) do print("    lint: " .. p) end
check("blademaster lints clean", #bmProblems == 0)

print("\n[Blademaster] an orc takes up the blade")
world.race, world.raceName = "Orc", "Orc"
world.level = 25
world.talentTrees = { Arms = 11 }
world.talentRanks = {}
world.buffs = {}
equip("MainHandSlot", "[Massive Iron Blade]", "Weapon", "Two-Handed Swords")
world.equipped.RangedSlot = nil
PrestigeClassesCharDB.active = "blademaster"
T.OnPathChanged()
check("clean book on the new path", T.State("bm_makgora") == nil)

print("\n[Blademaster] the mak'gora demands solitude and clean vows")
world.inGroup = true
slay("Hezrul Bloodmark")
check("no mak'gora with a warband", not T.IsComplete(bmTrial("bm_makgora")))
world.inGroup = false
equip("MainHandSlot", "[Some Axe]", "Weapon", "Two-Handed Axes") -- vow broken
slay("Hezrul Bloodmark")
check("no mak'gora with broken vows", not T.IsComplete(bmTrial("bm_makgora")))
equip("MainHandSlot", "[Massive Iron Blade]", "Weapon", "Two-Handed Swords")
slay("Hezrul Bloodmark")
check("alone + clean = the khan falls", T.IsComplete(bmTrial("bm_makgora")))
local bmRank = T.RankInfo(bm)
check("Disciple after the first mak'gora", bmRank == 2)

print("\n[Counter] the blood debt hears both cult names")
slay("Burning Blade Fanatic")
slay("Searing Blade Cultist")
check("both cults pay the debt", T.State("bm_debt").progress == 2)
check("the purge counts alongside", T.State("bm_purge").progress == 2)

print("\n[Crit] fifty perfect cuts, player's hand only")
T.OnCombatEvent("SWING_DAMAGE", "guid-player", "guid-q", "Razormane Hunter", nil, nil)
local crit = T.State("bm_critical")
check("plain swings are not the trial", crit == nil or crit.progress == 0)
world.pet = true
T.OnCombatEvent("SWING_DAMAGE", "guid-pet", "guid-q", "Razormane Hunter", nil, true)
world.pet = false
crit = T.State("bm_critical")
check("a pet's crit does not count", crit == nil or crit.progress == 0)
for i = 1, 49 do
    T.OnCombatEvent("SWING_DAMAGE", "guid-player", "guid-q", "Razormane Hunter", nil, true)
end
T.OnCombatEvent("SPELL_DAMAGE", "guid-player", "guid-q", "Razormane Hunter", "Mortal Strike", true)
check("fifty crits, swing and stroke alike", T.IsComplete(bmTrial("bm_critical")))
local keenEdge = false
for _, h in ipairs(T.Honorifics(bm)) do
    if h == "Keen Edge" then keenEdge = true end
end
check("Keen Edge honorific", keenEdge)

print("\n[Emote] the final bow waits for the Paragon")
world.zone, world.subzone = "Durotar", "Valley of Trials"
T.OnEmote("BOW")
check("chapter IV sealed to a Disciple", not T.IsComplete(bmTrial("bm_firstdust")))

-- ---- summary ---------------------------------------------------------------
print(string.format("\n==== %d passed, %d failed ====", pass, fail))
os.exit(fail == 0 and 0 or 1)
