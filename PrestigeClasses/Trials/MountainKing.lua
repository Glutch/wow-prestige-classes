local ADDON, PC = ...

-- =========================================================================
-- THE MOUNTAIN KING'S JOURNEY
-- =========================================================================
-- Dwarf warrior, warhammer and hand axe, gun on the back. Four chapters
-- from Coldridge Valley to the Molten Core, plus one grudge that never
-- closes.
-- Trial format: see the top of Trials.lua.
-- =========================================================================

PC.RegisterTrials("mountainking", {
    chapters = {
        [0] = "The Book of Grudges",
        "Chapter I — Sons of the Mountain",
        "Chapter II — Thunder at the Span",
        "Chapter III — Into the Fire",
        "Chapter IV — The Mountain Eternal",
    },
    trials = {
        -- ---- lifelong --------------------------------------------------
        {
            id = "mk_grudge", chapter = 0, kind = "counter",
            -- Under Blackrock the clan goes by its garrison names —
            -- Anvilrage, Shadowforge, Doomforge — all Dark Iron dwarves.
            pattern = { "Dark Iron", "Anvilrage", "Shadowforge", "Doomforge" },
            name = "The Grudge of Khaz Modan",
            objective = "Slay Dark Iron dwarves — and their Anvilrage, Shadowforge and Doomforge kin — wherever they scheme",
            text = "Two hundred and thirty years since Thaurissan's treachery split the clans. Every Dark Iron you put in the ground is a line written in the book of grudges. The book is never full.",
            milestones = {
                { count = 10, honorific = "Grudgebearer" },
                { count = 50, honorific = "Grudgekeeper" },
                { count = 200, honorific = "Avenger of the Three Hammers" },
            },
            epitaph = "The grudge counted %d Dark Iron dead.",
        },

        -- ---- Chapter I: Dun Morogh & Loch Modan (Initiate) ---------------
        {
            id = "mk_coldark", chapter = 1, kind = "kill", level = 5,
            targets = { "Grik'nir the Cold" },
            name = "The Cold Dark",
            objective = "Slay Grik'nir the Cold in Coldridge Valley",
            text = "Frostmane trolls skulk in the cave below Coldridge while we guard the wrong doors. Their chieftain Grik'nir squats in the dark. Carry the mountain's answer to him.",
        },
        {
            id = "mk_oath", chapter = 1, kind = "emote", level = 8,
            emote = "KNEEL", zone = "Ironforge", subzone = "The High Seat",
            name = "The Oath at the High Seat",
            objective = "/kneel at the High Seat of Ironforge",
            text = "Words spoken in a tavern are wind. Climb to the High Seat, kneel before the throne of Magni Bronzebeard, and swear the old oath where the mountain can hear it.",
        },
        {
            id = "mk_forge", chapter = 1, kind = "cast", level = 10,
            spell = "Heavy Copper Maul", zone = "Ironforge", subzone = "The Great Forge",
            name = "Forged at the Great Forge",
            objective = "Craft a Heavy Copper Maul at the Great Forge in Ironforge",
            text = "A bought weapon is a stranger in your hands. Smelt the copper yourself and hammer it out at the Great Forge — no lesser anvil will do.",
        },
        {
            id = "mk_dam", chapter = 1, kind = "emote", level = 12,
            emote = "SALUTE", zone = "Loch Modan", subzone = "Stonewrought Dam",
            name = "The Stonewrought Dam",
            objective = "/salute atop the Stonewrought Dam in Loch Modan",
            text = "Before you break stone, learn what stone can hold. Stand atop the Stonewrought Dam and salute the masons who dammed a lake with their two hands.",
        },
        {
            id = "mk_wendigo", chapter = 1, kind = "kill", level = 15,
            targets = { "Vagash" }, solo = true, cleanOnly = true,
            name = "The Wendigo",
            objective = "Slay Vagash above Amberstill Ranch — alone, vows clean",
            text = "Vagash has been bleeding the Amberstill flock white. Go up the mountain alone, hammer in hand, vows clean, and come down with frost in your beard.",
        },
        {
            id = "mk_ogre", chapter = 1, kind = "kill", level = 22,
            targets = { "Chok'sul" }, cleanOnly = true, rankTrial = true,
            name = "The Ogre Problem",
            objective = "Slay Chok'sul at the Mo'grosh Stronghold, vows clean",
            text = "The Mo'grosh ogres squat in our quarry, and their chief Chok'sul grows fat on stolen stone. Put him down with your vows clean, and the Loch will know a Disciple walks its shore.",
        },

        -- ---- Chapter II: Wetlands & the war road (Disciple) --------------
        {
            id = "mk_smite", chapter = 2, kind = "equip", level = 20,
            items = { "Smite's Mighty Hammer" },
            name = "The First Mate's Due",
            objective = "Claim and wield Smite's Mighty Hammer from the Deadmines",
            text = "A first mate aboard the Defias ship in the Deadmines swings a hammer worth more than his whole crew. Relieve Mr. Smite of it and let it serve an honest dwarf.",
        },
        {
            id = "mk_span", chapter = 2, kind = "emote", level = 24,
            emote = "MOURN", zone = "Wetlands", subzone = "Thandol Span",
            name = "The Span of the Fallen",
            objective = "/mourn on the Thandol Span",
            text = "Dark Iron sappers dropped the central span and good dwarves with it — some still lie beneath the water. Walk the Thandol Span and mourn them where they fell.",
        },
        {
            id = "mk_stormhammer", chapter = 2, kind = "proc", level = 25,
            aura = "Mace Stun Effect", count = 50,
            honorific = "Stormhammer",
            name = "Trial of the Storm",
            objective = "Stun 50 foes with your mace's storm (Mace Specialization)",
            text = "The old kings threw hammers of lightning. Yours answers in its own way — let the storm in your mace speak until the whole road has heard it.",
        },
        {
            id = "mk_thunder", chapter = 2, kind = "multihit", level = 25,
            spell = "Thunder Clap", hits = 3, count = 10,
            name = "Trial of the Thunder",
            objective = "Strike 3 or more foes with a single Thunder Clap, 10 times",
            text = "One clap, three foes staggered — that is the King's thunder. Do it ten times and the sky itself will take notes.",
        },
        {
            id = "mk_dragonmaw", chapter = 2, kind = "kill", level = 26,
            pattern = "Dragonmaw", count = 25,
            name = "The Chains of the Dragonmaw",
            objective = "Slay 25 Dragonmaw orcs in the Wetlands",
            text = "The Dragonmaw clan put chains on Alexstrasza at Grim Batol. Their grandsons camp at Angerfang as if the debt were paid. It is not. Collect.",
        },
        {
            id = "mk_grimbatol", chapter = 2, kind = "visit", level = 30,
            zone = "Wetlands", subzone = "Grim Batol",
            name = "The Gates of Grim Batol",
            objective = "Stand before the gates of Grim Batol",
            text = "Grim Batol was ours once, before the Dragonmaw chained the Dragonqueen in its halls. Stand before its gates and remember what was lost. Mind the red drakes — they remember too.",
        },
        {
            id = "mk_titans", chapter = 2, kind = "kill", level = 45,
            targets = { "Archaedas" }, cleanOnly = true, rankTrial = true,
            name = "The Titans' Judgment",
            objective = "Defeat Archaedas in Uldaman, vows clean (a level 47 elite — a deed for the mid-40s)",
            text = "Beneath the Badlands the titans left Uldaman, and a keeper of stone who suffers no unworthy hand. Stand before Archaedas with your vows clean and let the makers judge you.",
        },

        -- ---- Chapter III: Searing Gorge & Thaurissan (Exemplar) ----------
        {
            id = "mk_relic3", chapter = 3, kind = "equip", level = 42,
            items = { "Mograine's Might", "The Rockpounder" },
            name = "A Hammer with History",
            objective = "Wield Mograine's Might or The Rockpounder",
            text = "A hammer with history hits harder. Scarlet Commander Mograine carries one in his Cathedral; Archaedas guards another in Uldaman's vaults. Bring either to hand.",
        },
        {
            id = "mk_avatar", chapter = 3, kind = "kill", level = 45,
            requireElite = true, requireBuff = "Stoneform",
            name = "Rite of the Avatar",
            objective = "Slay an elite enemy while Stoneform is active",
            text = "When the old kings called on the mountain, their skin turned to living stone. You carry that gift in your blood. Become the Avatar — fell an elite foe while you stand as stone.",
        },
        {
            id = "mk_veins", chapter = 3, kind = "loot", level = 50,
            item = "Dark Iron Ore", count = 10,
            name = "Veins of the Enemy",
            objective = "Mine 10 Dark Iron Ore",
            text = "Dark Iron ore in Dark Iron country, under Dark Iron crossbows. Ten loads, dug with your own pick. The mountain gives nothing for free.",
        },
        {
            id = "mk_margol", chapter = 3, kind = "kill", level = 52,
            targets = { "Margol the Rager" }, solo = true,
            name = "The Thunder Below",
            objective = "Slay Margol the Rager in Searing Gorge — alone",
            text = "Margol the Rager shakes the Searing Gorge with every step. Thunder belongs to the Mountain King — go take it back from her. Alone.",
        },
        {
            id = "mk_angerforge", chapter = 3, kind = "kill", level = 56,
            targets = { "General Angerforge" },
            name = "The General",
            objective = "Slay General Angerforge in Blackrock Depths",
            text = "General Angerforge drills the Emperor's army below Blackrock. An army needs a general; see that theirs is buried with full honors.",
        },
        {
            id = "mk_blackanvil", chapter = 3, kind = "cast", level = 56,
            spell = "Smelt Dark Iron", zone = "Blackrock Depths",
            name = "Secrets of the Black Forge",
            objective = "Smelt Dark Iron at the Black Forge in Blackrock Depths",
            text = "Gloom'rel's ghost guards the secret of Dark Iron smelting, and only the Black Forge will work it. Pay his tribute, learn the rite, and smelt the enemy's own iron in the heart of his city.",
        },
        {
            id = "mk_usurper", chapter = 3, kind = "kill", level = 58,
            targets = { "Emperor Dagran Thaurissan" }, cleanOnly = true, rankTrial = true,
            name = "The Usurper",
            objective = "Slay Emperor Dagran Thaurissan, vows clean",
            text = "Dagran Thaurissan calls himself Emperor in a mountain his fathers stole. Walk into the Imperial Seat with your vows clean and end the family business.",
            completionNote = "He carried Ironfoe — Franclorn Forgewright's stolen masterwork. In a thane's main fist, a hand axe beside it, it serves honest folk at last.",
        },

        -- ---- Chapter IV: mythic deeds (Paragon) --------------------------
        {
            id = "mk_ragnaros", chapter = 4, kind = "kill", level = 60,
            targets = { "Ragnaros" },
            honorific = "Avenger of Khaz Modan",
            name = "The Final Line",
            objective = "Slay Ragnaros in the Molten Core",
            text = "It was Thaurissan who screamed the Firelord into our world. The grudge has one final line, and it is written in fire. Descend to the Molten Core and close the book.",
        },
        {
            id = "mk_tuf", chapter = 4, kind = "equip", level = 60,
            items = { "The Unstoppable Force" },
            name = "The Unstoppable Force",
            objective = "Earn and wield The Unstoppable Force (Stormpike exalted)",
            text = "The Stormpike fight our war in Alterac. Stand with them until they call you brother, and carry The Unstoppable Force into the field.",
        },
        {
            id = "mk_sulfuras", chapter = 4, kind = "equip", level = 60,
            items = { "Sulfuras, Hand of Ragnaros" },
            name = "The Hammer Above All Hammers",
            objective = "Forge and wield Sulfuras, Hand of Ragnaros",
            text = "There is one hammer above all hammers, and you must make it yourself: Sulfuron's plans, the Firelord's eye, and three hundred skill at the forge. Few will ever hold it. Be few.",
        },
        {
            id = "mk_lastcall", chapter = 4, kind = "emote", level = 60,
            emote = "DRINK", zone = "Dun Morogh", subzone = "Thunderbrew",
            name = "Last Call",
            objective = "/drink at the Thunderbrew Distillery in Kharanos",
            text = "You knelt before a throne; now raise a mug where it all began. One drink at the Thunderbrew Distillery — for the road, the dead, and the mountain.",
        },
    },
})
