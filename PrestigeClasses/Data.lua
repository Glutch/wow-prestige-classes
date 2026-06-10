local ADDON, PC = ...

-- =========================================================================
-- PRESTIGE CLASS RULESETS
-- =========================================================================
-- Each entry turns a Warcraft prestige class into a Classic-Era-enforceable
-- way to play. Fields the compliance engine understands:
--
--   races             = { raceFileToken, ... }  character must be one of these
--   classes           = { CLASS_TOKEN, ... }    character must be one of these
--   minLevel          = number                  identity requirement below this
--   forbidSlots       = { "HeadSlot", ... }     these slots must stay EMPTY
--   maxArmor          = "Cloth"|"Leather"|"Mail" no worn armor heavier than this
--   weaponTypes       = { "Two-Handed Swords" } main/off-hand weapons limited to these
--   requireDualWield  = true                    both hands must hold a weapon
--   forbidShield      = true                    off-hand may not be a Shield
--   rangedTypes       = { "Guns", ... }         ranged slot must hold one of these
--   requirePet        = true                    must have an active pet/minion
--   forbidPet         = true                    must NOT have a pet out
--   requireProfession = { "Alchemy", ... }      at least one MUST be trained (hard rule)
--   profession        = { "Blacksmithing" }     thematic professions (suggested only)
--
--   talents = {                                 talent discipline for the path
--     tree = { name = "Arms", points = 31 },    keep at least min(points, level-14)
--                                               points in this tree as you level
--     keys = {                                  named talents that define the path,
--       { name = "Mortal Strike", level = 42 }, required once you reach `level`
--       { name = "Frostbite", rank = 3, level = 25 },  optionally a minimum rank
--     },
--   }
--   For multi-class paths, key the spec by class token instead:
--   talents = { WARRIOR = { tree=..., keys=... }, ROGUE = {...} }
--   Tree names are the in-game tab names (note: shaman "Elemental Combat",
--   druid "Feral Combat").
--
-- Presentation fields:
--   icon        = "Interface\\Icons\\..." texture shown in lists and detail
--   breakCry    = chat line shouted when a vow is broken
--   restoreCry  = chat line when the path is restored
--   honorRules  = roleplay vows the addon can't auto-check, shown to the player
--
-- A path may also carry a trial journey (chapters of deeds, rank trials,
-- honorifics). Journeys are NOT written here — each lives in its own file
-- under Trials\ and registers itself via PC.RegisterTrials (see the bottom
-- of this file and the format docs at the top of Trials.lua).
-- =========================================================================

local ICONS = "Interface\\Icons\\"

PC.Classes = {
    {
        id = "blademaster",
        name = "Blademaster",
        source = "Warcraft III / Orcish tradition",
        faction = "Horde",
        icon = ICONS .. "Ability_Warrior_SavageBlow",
        fantasy = "A master of the blade who scorns heavy armor, trusting reflexes and a single great sword. Disciplined, deadly, and never weighed down.",
        races = { "Orc" },
        classes = { "WARRIOR" },
        forbidSlots = { "HeadSlot", "ChestSlot" },
        weaponTypes = { "Two-Handed Swords" },
        talents = {
            tree = { name = "Arms", points = 31 },
            keys = {
                { name = "Sweeping Strikes", level = 32 }, -- the Bladestorm
                { name = "Mortal Strike", level = 42 },    -- the killing blow
            },
        },
        profession = { "Blacksmithing" },
        breakCry = "The blade is dishonored! A true Blademaster carries nothing but the sword.",
        restoreCry = "The blade sings again. Walk lightly, strike once.",
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
        icon = ICONS .. "INV_Hammer_05",
        fantasy = "A legendary dwarven warrior wreathed in plate, swinging a massive hammer and hurling thunder. Immovable and proud.",
        races = { "Dwarf" },
        classes = { "WARRIOR" },
        weaponTypes = { "Two-Handed Maces" },
        rangedTypes = { "Guns" },
        talents = {
            tree = { name = "Arms", points = 31 },
            keys = {
                -- Mace Specialization's stun proc is the Storm Bolt.
                { name = "Mace Specialization", rank = 5, level = 36 },
            },
        },
        profession = { "Mining", "Blacksmithing" },
        breakCry = "The mountain crumbles! Take up the hammer, son of Khaz Modan.",
        restoreCry = "Stone and storm! The Mountain King stands again.",
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
        icon = ICONS .. "Racial_Troll_Berserk",
        fantasy = "A frenzied tribal warrior who throws caution — and armor — to the wind, striking with reckless fury and no shield to hide behind.",
        races = { "Troll", "Orc" },
        classes = { "WARRIOR" },
        maxArmor = "Mail",
        forbidShield = true,
        talents = {
            tree = { name = "Fury", points = 31 },
            keys = {
                { name = "Death Wish", level = 32 },  -- reckless fury incarnate
                { name = "Bloodthirst", level = 42 },
            },
        },
        profession = { "Skinning", "Leatherworking" },
        breakCry = "The fury fades — you hide like prey! Cast off the shell and rage.",
        restoreCry = "The blood boils once more. RAAAGH!",
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
        icon = ICONS .. "Ability_Hunter_BeastCall",
        fantasy = "A wilds-born hunter bonded to a single great beast. The pet is not a tool — it is family, and it never fights alone.",
        classes = { "HUNTER" },
        requirePet = true,
        talents = {
            tree = { name = "Beast Mastery", points = 31 },
            keys = {
                { name = "Bestial Wrath", level = 42 },
            },
        },
        profession = { "Skinning", "Leatherworking" },
        breakCry = "Your beast is gone — a Beastmaster never walks alone!",
        restoreCry = "The pack is whole again.",
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
        icon = ICONS .. "Ability_Marksmanship",
        fantasy = "A cold-eyed sharpshooter who trusts the rifle over any beast. One shot, one kill — no companion to share the glory.",
        classes = { "HUNTER" },
        rangedTypes = { "Guns", "Crossbows" },
        forbidPet = true,
        talents = {
            tree = { name = "Marksmanship", points = 31 },
            keys = {
                { name = "Aimed Shot", level = 22 },   -- one shot, one kill
                { name = "Trueshot Aura", level = 42 },
            },
        },
        profession = { "Engineering" },
        breakCry = "The shot is fouled! The Marksman works alone, gun in hand.",
        restoreCry = "Sights aligned. One shot, one kill.",
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
        icon = ICONS .. "Ability_Rogue_Eviscerate",
        fantasy = "A shadow with a blade. Strikes from stealth with twin daggers slick with poison, and is gone before the body falls.",
        classes = { "ROGUE" },
        weaponTypes = { "Daggers" },
        maxArmor = "Leather",
        talents = {
            tree = { name = "Assassination", points = 31 },
            keys = {
                { name = "Improved Poisons", level = 27 }, -- blades slick with venom
                { name = "Cold Blood", level = 32 },
            },
        },
        profession = { "Skinning", "Leatherworking" },
        breakCry = "The contract is void! Only daggers, only shadow.",
        restoreCry = "The shadows welcome you back.",
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
        icon = ICONS .. "Ability_Parry",
        fantasy = "An honorable blademaster of single combat. One sword, no shield, no tricks — just skill against skill.",
        classes = { "ROGUE", "WARRIOR" },
        weaponTypes = { "One-Handed Swords" },
        forbidShield = true,
        talents = {
            ROGUE = {
                tree = { name = "Combat", points = 31 },
                keys = {
                    { name = "Riposte", level = 22 }, -- the duelist's answer
                    { name = "Sword Specialization", rank = 5, level = 36 },
                },
            },
            WARRIOR = {
                tree = { name = "Arms", points = 31 },
                keys = {
                    { name = "Sword Specialization", rank = 5, level = 36 },
                },
            },
        },
        profession = { "Blacksmithing" },
        breakCry = "Dishonor! A Duelist needs one sword and nothing else.",
        restoreCry = "En garde. Your honor is restored.",
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
        icon = ICONS .. "Ability_Ambush",
        fantasy = "A relentless night elf jailer who hunts the guilty across the world, striking with thrown glaives and vanishing into shadow.",
        races = { "NightElf" },
        classes = { "ROGUE" },
        maxArmor = "Leather",
        rangedTypes = { "Thrown" },
        talents = {
            tree = { name = "Subtlety", points = 31 },
            keys = {
                { name = "Preparation", level = 32 }, -- the hunt never ends
            },
        },
        profession = { "Skinning", "Leatherworking" },
        breakCry = "The hunt falters! The Warden's glaive must always be ready.",
        restoreCry = "The watch resumes. None escape.",
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
        icon = ICONS .. "Ability_Druid_CatForm",
        fantasy = "A shapeshifter who has all but forsaken their humanoid shell, living as bear and cat. The wild is the only true form.",
        classes = { "DRUID" },
        maxArmor = "Leather",
        talents = {
            tree = { name = "Feral Combat", points = 31 },
            keys = {
                { name = "Feral Charge", level = 22 },
                { name = "Leader of the Pack", level = 42 },
            },
        },
        profession = { "Herbalism", "Alchemy" },
        breakCry = "The wild rejects you! Shed the trappings of civilization.",
        restoreCry = "Tooth and claw. The wild knows its own.",
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
        icon = ICONS .. "Spell_Holy_HolyBolt",
        fantasy = "A holy crusader clad head to toe in plate, hammer in hand and the Light at their back, shielding the weak from darkness.",
        races = { "Dwarf", "Human" },
        classes = { "PALADIN" },
        weaponTypes = { "One-Handed Maces", "Two-Handed Maces" },
        talents = {
            tree = { name = "Protection", points = 31 },
            keys = {
                { name = "Blessing of Sanctuary", level = 32 }, -- shield the weak
            },
        },
        profession = { "Blacksmithing", "Mining" },
        breakCry = "The Light dims! Take up the hammer of judgment.",
        restoreCry = "The Light shines upon you once more.",
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
        icon = ICONS .. "INV_Sword_27",
        fantasy = "An arena-forged warrior who lives for the melee. Sword in hand, face to face, no ranged crutch and no retreat.",
        classes = { "WARRIOR" },
        weaponTypes = { "One-Handed Swords", "Two-Handed Swords" },
        forbidSlots = { "RangedSlot" },
        talents = {
            tree = { name = "Arms", points = 31 },
            keys = {
                { name = "Sword Specialization", rank = 5, level = 36 },
            },
        },
        profession = { "Blacksmithing" },
        breakCry = "The crowd jeers! A Gladiator wins with steel, face to face.",
        restoreCry = "The crowd roars your name!",
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
        icon = ICONS .. "Spell_Nature_HealingWaveGreater",
        fantasy = "A tauren mystic who walks between the living and the ancestors, mending allies and calling the elements through totems.",
        races = { "Tauren" },
        classes = { "SHAMAN" },
        maxArmor = "Mail",
        weaponTypes = { "One-Handed Maces", "Staves" },
        talents = {
            tree = { name = "Restoration", points = 31 },
            keys = {
                { name = "Totemic Focus", level = 17 },
                { name = "Mana Tide Totem", level = 42 },
            },
        },
        profession = { "Herbalism", "Alchemy" },
        breakCry = "The ancestors turn away! Walk gently between the worlds.",
        restoreCry = "The ancestors smile upon you.",
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
        icon = ICONS .. "Spell_Nature_Polymorph",
        fantasy = "A troll voodoo caster who curses, hexes and freezes foes solid. Cloth and cunning over steel and muscle.",
        races = { "Troll" },
        classes = { "MAGE" },
        maxArmor = "Cloth",
        weaponTypes = { "Staves", "Daggers", "One-Handed Swords" },
        talents = {
            tree = { name = "Frost", points = 31 },
            keys = {
                { name = "Frostbite", rank = 3, level = 25 }, -- foes frozen solid
                { name = "Ice Block", level = 32 },
            },
        },
        profession = { "Tailoring", "Enchanting" },
        breakCry = "Da mojo be broken, mon! Cloth and cunning only.",
        restoreCry = "Da spirits be pleased. Da mojo flows.",
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
        icon = ICONS .. "Spell_Shadow_AnimateDead",
        fantasy = "A Forsaken death-mage who is never truly alone — a servant from beyond the grave always stands at their side, fed on stolen life.",
        races = { "Scourge" },
        classes = { "WARLOCK" },
        maxArmor = "Cloth",
        requirePet = true,
        talents = {
            tree = { name = "Demonology", points = 31 },
            keys = {
                { name = "Master Summoner", level = 27 },
                { name = "Soul Link", level = 42 }, -- bound to the servant
            },
        },
        profession = { "Tailoring" },
        breakCry = "The grave grows silent! Raise your servant, deathweaver.",
        restoreCry = "The dead march with you once more.",
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
        icon = ICONS .. "Spell_Holy_MagicalSentry",
        fantasy = "A Dalaran arcanist of the highest order. Robes, a staff, and unmatched mastery of the arcane — no blade ever sullies their hands.",
        races = { "Human", "Gnome" },
        classes = { "MAGE" },
        minLevel = 20,
        maxArmor = "Cloth",
        weaponTypes = { "Staves" },
        talents = {
            tree = { name = "Arcane", points = 31 },
            keys = {
                { name = "Presence of Mind", level = 32 },
                { name = "Arcane Power", level = 42 },
            },
        },
        profession = { "Enchanting", "Tailoring" },
        breakCry = "The Kirin Tor disavows you! Staff and robes, archmage — nothing less.",
        restoreCry = "Dalaran acknowledges your mastery once more.",
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
        icon = ICONS .. "INV_Hammer_16",
        fantasy = "A brutal frontline smasher who answers everything with a two-handed hammer and refuses to take a single step back.",
        races = { "Orc", "Tauren" },
        classes = { "WARRIOR" },
        weaponTypes = { "Two-Handed Maces" },
        talents = {
            tree = { name = "Fury", points = 31 },
            keys = {
                { name = "Enrage", rank = 5, level = 30 }, -- pain only feeds the swing
            },
        },
        profession = { "Mining", "Blacksmithing" },
        breakCry = "Nothing left to crush with! Take up the great hammer.",
        restoreCry = "Bones will break again. Forward!",
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
        icon = ICONS .. "Spell_Shadow_CurseOfTounges",
        fantasy = "A troll spiritualist blending healing voodoo with savage hexes — equal parts healer and headhunter.",
        races = { "Troll" },
        classes = { "PRIEST" },
        maxArmor = "Cloth",
        weaponTypes = { "Daggers", "One-Handed Maces", "Staves" },
        talents = {
            -- Half healer, half headhunter: a foot in Shadow, never all the way in.
            tree = { name = "Shadow", points = 21 },
            keys = {
                { name = "Mind Flay", level = 22 },
            },
        },
        profession = { "Herbalism", "Alchemy" },
        breakCry = "Da loa be angry, mon! Walk da way of shadow and spirit.",
        restoreCry = "Da loa watch over ya again.",
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
        icon = ICONS .. "INV_Potion_19",
        fantasy = "A Forsaken plague-chemist who weaponizes disease and decay. The laboratory is the true battlefield.",
        races = { "Scourge" },
        classes = { "WARLOCK", "MAGE", "PRIEST" },
        maxArmor = "Cloth",
        requireProfession = { "Alchemy" },
        talents = {
            WARLOCK = {
                tree = { name = "Affliction", points = 31 },
                keys = {
                    { name = "Siphon Life", level = 32 }, -- the slow rot
                },
            },
            PRIEST = {
                tree = { name = "Shadow", points = 21 },
            },
        },
        profession = { "Herbalism" },
        breakCry = "The experiment is ruined! The Society demands your craft.",
        restoreCry = "The cauldron bubbles anew. For the Dark Lady.",
        honorRules = {
            "Brew and carry potions, oils and concoctions at all times.",
            "Spread blight: favor damage-over-time and afflictions.",
            "Test your latest brew before every dangerous fight.",
        },
    },
    {
        id = "demonhunter",
        name = "Demon Hunter",
        source = "WoW RPG / The Illidari",
        faction = "Alliance",
        icon = ICONS .. "Ability_DualWield",
        fantasy = "An outcast who sacrificed everything to fight fire with fire. Blindfolded, bare-chested, a blade in each hand — feared by friend and foe alike.",
        races = { "NightElf" },
        classes = { "ROGUE", "WARRIOR" },
        minLevel = 10,
        forbidSlots = { "HeadSlot", "ChestSlot" },
        maxArmor = "Leather",
        weaponTypes = { "One-Handed Swords", "Fist Weapons" },
        requireDualWield = true,
        talents = {
            ROGUE = {
                tree = { name = "Combat", points = 31 },
                keys = {
                    { name = "Dual Wield Specialization", rank = 5, level = 32 },
                },
            },
            WARRIOR = {
                tree = { name = "Fury", points = 31 },
                keys = {
                    { name = "Dual Wield Specialization", rank = 5, level = 32 },
                },
            },
        },
        profession = { "Enchanting" },
        breakCry = "You are not prepared! Twin blades, bare skin, nothing more.",
        restoreCry = "The sacrifice is honored. Hunt the demon within.",
        honorRules = {
            "Fight with a warglaive in each hand (one-handed swords or fists).",
            "Wear no helm and no chest — your scars are your armor.",
            "Embrace the dark: use every dirty trick, show no mercy to evil.",
        },
    },
    {
        id = "priestessmoon",
        name = "Priestess of the Moon",
        source = "Warcraft III / Sisterhood of Elune",
        faction = "Alliance",
        icon = ICONS .. "Spell_Holy_ElunesGrace",
        fantasy = "A chosen sister of Elune who fights bathed in moonlight, staff in hand, calling down the goddess's silver wrath.",
        races = { "NightElf" },
        classes = { "PRIEST" },
        maxArmor = "Cloth",
        weaponTypes = { "Staves", "One-Handed Maces" },
        rangedTypes = { "Wands" },
        talents = {
            tree = { name = "Holy", points = 31 },
            keys = {
                { name = "Holy Nova", level = 22 },  -- a burst of starlight
                { name = "Lightwell", level = 42 },  -- place a moonwell
            },
        },
        profession = { "Tailoring", "Enchanting" },
        breakCry = "Elune's light wavers! Bear the sister's staff with grace.",
        restoreCry = "Elune-adore. The goddess smiles upon you.",
        honorRules = {
            "Carry a staff or moon-blessed mace, and a wand for Elune's distant wrath.",
            "Use Starshards and holy starlight — you are Elune's arrow.",
            "Fight under the open sky when you can; the moon must see your deeds.",
        },
    },
    {
        id = "elvenranger",
        name = "Elven Ranger",
        source = "Warcraft RPG",
        faction = "Alliance",
        icon = ICONS .. "INV_Weapon_Bow_07",
        fantasy = "A silent sentinel of the deep forests. The bow is an extension of the arm; every arrow lands where the eye rests.",
        races = { "NightElf" },
        classes = { "HUNTER" },
        maxArmor = "Leather",
        rangedTypes = { "Bows" },
        talents = {
            tree = { name = "Survival", points = 31 },
            keys = {
                { name = "Deterrence", level = 22 },
                { name = "Wyvern Sting", level = 42 }, -- the poisoned arrow
            },
        },
        profession = { "Skinning", "Leatherworking" },
        breakCry = "The forest falls silent! A ranger trusts only the bow.",
        restoreCry = "The forest breathes again. Loose your arrows.",
        honorRules = {
            "Fight with a bow — never a gun's crude thunder.",
            "Wear nothing heavier than leather; move like wind through leaves.",
            "Track and skin your kills; waste nothing the forest gives.",
        },
    },
    {
        id = "farseer",
        name = "Far Seer",
        source = "Warcraft III / Horde tradition",
        faction = "Horde",
        icon = ICONS .. "Spell_Nature_FarSight",
        fantasy = "An ancient orc shaman whose eyes see across mountains and years. The elements speak, and the Far Seer listens.",
        races = { "Orc" },
        classes = { "SHAMAN" },
        maxArmor = "Mail",
        weaponTypes = { "Staves", "One-Handed Maces" },
        talents = {
            -- The in-game tab is named "Elemental Combat" in Classic Era.
            tree = { name = "Elemental Combat", points = 31 },
            keys = {
                { name = "Elemental Mastery", level = 42 },
            },
        },
        profession = { "Herbalism", "Alchemy" },
        breakCry = "The vision clouds! The elements demand a worthy vessel.",
        restoreCry = "The sight returns. The elements speak through you.",
        honorRules = {
            "Walk with a staff or mace; the Far Seer is a guide, not a butcher.",
            "Scout ahead with Far Sight before entering dangerous lands.",
            "Counsel your group; share what the spirits show you.",
        },
    },
    {
        id = "witchdoctor",
        name = "Witch Doctor",
        source = "Warcraft III / Darkspear tradition",
        faction = "Horde",
        icon = ICONS .. "INV_Misc_Bone_HumanSkull_01",
        fantasy = "A Darkspear mystic of wards and brews, rattling bone charms and flinging foul concoctions. Da voodoo provides.",
        races = { "Troll" },
        classes = { "SHAMAN" },
        maxArmor = "Leather",
        weaponTypes = { "Daggers", "Staves", "One-Handed Maces" },
        requireProfession = { "Alchemy" },
        talents = {
            keys = {
                -- Wards before war: the totems are the voodoo.
                { name = "Totemic Focus", rank = 5, level = 25 },
            },
        },
        profession = { "Herbalism" },
        breakCry = "Da voodoo be weak, mon! Brew, bones and spirit.",
        restoreCry = "Da voodoo be strong again, mon!",
        honorRules = {
            "Brew your own potions and drink them proudly — Alchemy is your craft.",
            "Drop totems like wards in every fight.",
            "Collect trophies from worthy kills (keep a bone or skull in your bags).",
        },
    },
    {
        id = "buccaneer",
        name = "Buccaneer",
        source = "Warcraft RPG / Pirates of the South Seas",
        faction = "Both",
        icon = ICONS .. "INV_Misc_Coin_02",
        fantasy = "A swaggering corsair with a cutlass on the hip and a pistol in the belt. Gold, grog and glory — in that order.",
        classes = { "ROGUE" },
        maxArmor = "Leather",
        weaponTypes = { "One-Handed Swords", "Daggers" },
        rangedTypes = { "Guns" },
        talents = {
            tree = { name = "Combat", points = 31 },
            keys = {
                { name = "Riposte", level = 22 },      -- swashbuckler's parry
                { name = "Blade Flurry", level = 32 }, -- flashing steel
            },
        },
        profession = { "Fishing", "Cooking" },
        breakCry = "Mutiny! A buccaneer fights with cutlass and pistol or not at all.",
        restoreCry = "Back aboard, captain. The horizon is yours.",
        honorRules = {
            "Cutlass in hand, pistol in the belt — sword or dagger, plus a gun.",
            "Loot every kill; never leave gold on a body.",
            "Eat, drink and be merry before every voyage (buff food and drink).",
        },
    },
    {
        id = "tinker",
        name = "Tinker",
        source = "Warcraft RPG / Gnomeregan",
        faction = "Alliance",
        icon = ICONS .. "INV_Misc_Gear_01",
        fantasy = "A gnomish genius who solves every problem with a bigger gadget. The gun is self-built, the bombs are homemade, and the warranty is void.",
        races = { "Gnome" },
        classes = { "WARRIOR", "ROGUE" },
        rangedTypes = { "Guns" },
        requireProfession = { "Engineering" },
        profession = { "Mining" },
        breakCry = "Catastrophic malfunction! A Tinker without gadgets is just short.",
        restoreCry = "All systems nominal. For Gnomeregan!",
        honorRules = {
            "Keep a gun on your back — preferably one you built yourself.",
            "Use an engineering gadget (bomb, dynamite, trinket) in every hard fight.",
            "Craft your own gear when Engineering allows it.",
        },
    },
}

-- Index by id for quick lookup.
PC.ClassById = {}
for _, c in ipairs(PC.Classes) do
    PC.ClassById[c.id] = c
end

-- ------------------------------------------------------------------------
-- Trial journeys live in their own files (Trials\<Class>.lua) so each
-- path's content can grow without bloating the rulesets above. A journey
-- file calls:
--
--   PC.RegisterTrials("mountainking", {
--       chapters = { [0] = "...", "Chapter I — ...", ... }, -- journal headings
--       trials   = { ... }, -- format documented at the top of Trials.lua
--   })
--
-- To give another class a journey: create Trials\<Class>.lua, register it
-- here-style, and add the file to the .toc after Data.lua.
-- ------------------------------------------------------------------------
function PC.RegisterTrials(classId, journey)
    local def = PC.ClassById[classId]
    if not def then
        print("|cffff4040[Prestige]|r RegisterTrials: unknown class id '" ..
            tostring(classId) .. "'")
        return
    end
    def.trialChapters = journey.chapters
    def.trials = journey.trials
end
