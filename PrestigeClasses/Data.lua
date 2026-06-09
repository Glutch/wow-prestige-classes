local ADDON, PC = ...

-- =========================================================================
-- PRESTIGE CLASS RULESETS
-- =========================================================================
-- Each entry turns a Warcraft prestige class into a Classic-Era-enforceable
-- way to play. Fields the compliance engine understands:
--
--   races        = { raceFileToken, ... }   character must be one of these
--   classes      = { CLASS_TOKEN, ... }      character must be one of these
--   minLevel     = number                    soft requirement, info only below this
--   forbidSlots  = { "HeadSlot", ... }        these slots must stay EMPTY
--   maxArmor     = "Cloth"|"Leather"|"Mail"   no worn armor heavier than this
--   weaponTypes  = { "Two-Handed Swords",...} main/off-hand weapons limited to these
--   forbidShield = true                       off-hand may not be a Shield
--   rangedTypes  = { "Guns", ... }            if a ranged weapon is worn it must be one of these
--   requirePet   = true                       must have an active pet/minion
--   forbidPet    = true                       must NOT have a pet out
--   profession   = { "Blacksmithing", ... }   thematic professions (suggested, not failed)
--
-- honorRules are the roleplay vows the addon can't auto-check; they're shown
-- so the player knows how to truly inhabit the class.
-- =========================================================================

PC.Classes = {
    {
        id = "blademaster",
        name = "Blademaster",
        source = "Warcraft III / Orcish tradition",
        faction = "Horde",
        fantasy = "A master of the blade who scorns heavy armor, trusting reflexes and a single great sword. Disciplined, deadly, and never weighed down.",
        races = { "Orc" },
        classes = { "WARRIOR" },
        forbidSlots = { "HeadSlot", "ChestSlot" },
        weaponTypes = { "Two-Handed Swords" },
        profession = { "Blacksmithing" },
        honorRules = {
            "Wield only the two-handed blade — never a shield, never dual-wield.",
            "Bare your head and chest; let skill be your armor.",
            "When death looms, Wind Walk away (disengage, escape) before you fall.",
        },
    },
    {
        id = "mountainking",
        name = "Mountain King",
        source = "Alliance Player's Guide",
        faction = "Alliance",
        fantasy = "A legendary dwarven warrior wreathed in plate, swinging a massive hammer and hurling thunder. Immovable and proud.",
        races = { "Dwarf" },
        classes = { "WARRIOR" },
        weaponTypes = { "Two-Handed Maces" },
        rangedTypes = { "Guns" },
        profession = { "Mining", "Blacksmithing" },
        honorRules = {
            "Carry a two-handed hammer (mace) — the Storm Bolt is thrown, never sheathed.",
            "Keep a gun on your back to mimic the King's ranged thunder.",
            "Stand and fight as a dwarf should — never flee a winnable brawl.",
        },
    },
    {
        id = "berserker",
        name = "Berserker",
        source = "WoW RPG",
        faction = "Horde",
        fantasy = "A frenzied tribal warrior who throws caution — and armor — to the wind, striking with reckless fury and no shield to hide behind.",
        races = { "Troll", "Orc" },
        classes = { "WARRIOR" },
        maxArmor = "Mail",
        forbidShield = true,
        profession = { "Skinning", "Leatherworking" },
        honorRules = {
            "Never raise a shield — only fury answers the call.",
            "Wear no plate; the berserker disdains the turtle's shell.",
            "Fight in Berserker Stance whenever it is yours.",
        },
    },
    {
        id = "beastmaster",
        name = "Beastmaster",
        source = "Warcraft RPG",
        faction = "Both",
        fantasy = "A wilds-born hunter bonded to a single great beast. The pet is not a tool — it is family, and it never fights alone.",
        classes = { "HUNTER" },
        requirePet = true,
        profession = { "Skinning", "Leatherworking" },
        honorRules = {
            "Always have your beast at your side — never quest without it.",
            "Name your companion and never abandon or let it die.",
            "Tame the rarest beast you can find and keep it for life.",
        },
    },
    {
        id = "marksman",
        name = "Marksman",
        source = "Alliance & Horde Compendium",
        faction = "Both",
        fantasy = "A cold-eyed sharpshooter who trusts the rifle over any beast. One shot, one kill — no companion to share the glory.",
        classes = { "HUNTER" },
        rangedTypes = { "Guns", "Crossbows" },
        forbidPet = true,
        profession = { "Engineering" },
        honorRules = {
            "Fight with a gun or crossbow — never a bow.",
            "Dismiss your pet; the shot is yours alone.",
            "Open every fight at maximum range.",
        },
    },
    {
        id = "assassin",
        name = "Assassin",
        source = "WoW RPG",
        faction = "Both",
        fantasy = "A shadow with a blade. Strikes from stealth with twin daggers slick with poison, and is gone before the body falls.",
        classes = { "ROGUE" },
        weaponTypes = { "Daggers" },
        maxArmor = "Leather",
        profession = { "Skinning", "Leatherworking" },
        honorRules = {
            "Wield only daggers — the assassin's signature.",
            "Keep poisons applied at all times.",
            "Open every fight from Stealth, never head-on.",
        },
    },
    {
        id = "duelist",
        name = "Duelist",
        source = "WoW RPG",
        faction = "Both",
        fantasy = "An honorable blademaster of single combat. One sword, no shield, no tricks — just skill against skill.",
        classes = { "ROGUE", "WARRIOR" },
        weaponTypes = { "One-Handed Swords" },
        forbidShield = true,
        profession = { "Blacksmithing" },
        honorRules = {
            "Fight with a single one-handed sword — no shield, no off-hand.",
            "Face foes one at a time when you can.",
            "Never strike a fleeing, helpless enemy.",
        },
    },
    {
        id = "warden",
        name = "Warden",
        source = "Alliance Player's Guide",
        faction = "Alliance",
        fantasy = "A relentless night elf jailer who hunts the guilty across the world, striking with thrown glaives and vanishing into shadow.",
        races = { "NightElf" },
        classes = { "ROGUE" },
        maxArmor = "Leather",
        rangedTypes = { "Thrown" },
        profession = { "Skinning", "Leatherworking" },
        honorRules = {
            "Keep a thrown weapon ready — the Warden's glaive flies true.",
            "Use Shadowmeld and Stealth to stalk your prey.",
            "Pursue your target relentlessly; never let the guilty escape.",
        },
    },
    {
        id = "druidwild",
        name = "Druid of the Wild",
        source = "Warcraft RPG",
        faction = "Both",
        fantasy = "A shapeshifter who has all but forsaken their humanoid shell, living as bear and cat. The wild is the only true form.",
        classes = { "DRUID" },
        maxArmor = "Leather",
        profession = { "Herbalism", "Alchemy" },
        honorRules = {
            "Fight only in Bear or Cat form — your caster shape is for travel and healing, not war.",
            "Wear nothing heavier than leather.",
            "Walk the wilds; favor nature over civilization.",
        },
    },
    {
        id = "vindicator",
        name = "Vindicator",
        source = "Dark Factions",
        faction = "Alliance",
        fantasy = "A holy crusader clad head to toe in plate, hammer in hand and the Light at their back, shielding the weak from darkness.",
        races = { "Dwarf", "Human" },
        classes = { "PALADIN" },
        weaponTypes = { "One-Handed Maces", "Two-Handed Maces" },
        profession = { "Blacksmithing", "Mining" },
        honorRules = {
            "Wield a mace or hammer — the Light's blunt judgment.",
            "Wear full plate as soon as you are able.",
            "Protect allies before yourself; never abandon a party member.",
        },
    },
    {
        id = "gladiator",
        name = "Gladiator",
        source = "Warcraft RPG",
        faction = "Both",
        fantasy = "An arena-forged warrior who lives for the melee. Sword in hand, face to face, no ranged crutch and no retreat.",
        classes = { "WARRIOR" },
        weaponTypes = { "One-Handed Swords", "Two-Handed Swords" },
        forbidSlots = { "RangedSlot" },
        profession = { "Blacksmithing" },
        honorRules = {
            "Fight with swords only — the gladiator's chosen steel.",
            "Carry no bow, gun or thrown weapon; close the distance and win it in melee.",
            "Never flee a fight you started.",
        },
    },
    {
        id = "spiritwalker",
        name = "Spirit Walker",
        source = "Horde Player's Guide",
        faction = "Horde",
        fantasy = "A tauren mystic who walks between the living and the ancestors, mending allies and calling the elements through totems.",
        races = { "Tauren" },
        classes = { "SHAMAN" },
        maxArmor = "Mail",
        weaponTypes = { "One-Handed Maces", "Staves" },
        profession = { "Herbalism", "Alchemy" },
        honorRules = {
            "Drop totems in every meaningful fight — the elements fight beside you.",
            "Heal and shield your group; the Spirit Walker serves the living and the dead.",
            "Carry a mace or staff, never a blade.",
        },
    },
    {
        id = "hexer",
        name = "Hexer",
        source = "Horde Player's Guide",
        faction = "Horde",
        fantasy = "A troll voodoo caster who curses, hexes and freezes foes solid. Cloth and cunning over steel and muscle.",
        races = { "Troll" },
        classes = { "MAGE" },
        maxArmor = "Cloth",
        weaponTypes = { "Staves", "Daggers", "One-Handed Swords" },
        profession = { "Tailoring", "Enchanting" },
        honorRules = {
            "Wear only cloth — the Hexer needs no armor.",
            "Hex (Polymorph) a dangerous foe in every multi-enemy fight.",
            "Lead with curses and crowd control before raw damage.",
        },
    },
    {
        id = "necromancer",
        name = "Necromancer",
        source = "Alliance & Horde Compendium",
        faction = "Horde",
        fantasy = "A Forsaken death-mage who is never truly alone — a servant from beyond the grave always stands at their side, fed on stolen life.",
        races = { "Scourge" },
        classes = { "WARLOCK" },
        maxArmor = "Cloth",
        requirePet = true,
        profession = { "Tailoring" },
        honorRules = {
            "Always keep a summoned minion at your side — the dead never rest.",
            "Drain the life from your enemies to sustain yourself.",
            "Wear only the robes of a deathweaver.",
        },
    },
    {
        id = "archmage",
        name = "Archmage of the Kirin Tor",
        source = "WoW RPG",
        faction = "Alliance",
        fantasy = "A Dalaran arcanist of the highest order. Robes, a staff, and unmatched mastery of the arcane — no blade ever sullies their hands.",
        races = { "Human", "Gnome" },
        classes = { "MAGE" },
        minLevel = 20,
        maxArmor = "Cloth",
        weaponTypes = { "Staves" },
        profession = { "Enchanting", "Tailoring" },
        honorRules = {
            "Carry only a staff — the symbol of an archmage.",
            "Wear nothing but cloth robes.",
            "Master the arcane; let intellect, not muscle, win your battles.",
        },
    },
    {
        id = "bonecrusher",
        name = "Bone Crusher",
        source = "Horde Player's Guide",
        faction = "Horde",
        fantasy = "A brutal frontline smasher who answers everything with a two-handed hammer and refuses to take a single step back.",
        races = { "Orc", "Tauren" },
        classes = { "WARRIOR" },
        weaponTypes = { "Two-Handed Maces" },
        profession = { "Mining", "Blacksmithing" },
        honorRules = {
            "Crush with a two-handed mace — nothing else will do.",
            "Wade into the thickest of the fight; you are the front line.",
            "Never retreat while you can still swing.",
        },
    },
    {
        id = "shadowhunter",
        name = "Shadow Hunter",
        source = "Magic & Mayhem",
        faction = "Horde",
        fantasy = "A troll spiritualist blending healing voodoo with savage hexes — equal parts healer and headhunter.",
        races = { "Troll" },
        classes = { "PRIEST" },
        maxArmor = "Cloth",
        weaponTypes = { "Daggers", "One-Handed Maces", "Staves" },
        profession = { "Herbalism", "Alchemy" },
        honorRules = {
            "Heal your allies — the Shadow Hunter shepherds the tribe.",
            "Use Shadow magic to curse and torment your foes.",
            "Honor the loa; favor troll tradition over outsider ways.",
        },
    },
    {
        id = "darkapothecary",
        name = "Dark Apothecary",
        source = "Lands of Conflict",
        faction = "Horde",
        fantasy = "A Forsaken plague-chemist who weaponizes disease and decay. The laboratory is the true battlefield.",
        races = { "Scourge" },
        classes = { "WARLOCK", "MAGE", "PRIEST" },
        maxArmor = "Cloth",
        profession = { "Alchemy", "Herbalism" },
        honorRules = {
            "Train Alchemy — the apothecary's craft is mandatory.",
            "Brew and carry poisons, oils and concoctions at all times.",
            "Spread blight: favor damage-over-time and afflictions.",
        },
    },
}

-- Index by id for quick lookup.
PC.ClassById = {}
for _, c in ipairs(PC.Classes) do
    PC.ClassById[c.id] = c
end
