local ADDON, PC = ...

-- =========================================================================
-- THE BLADEMASTER'S JOURNEY
-- =========================================================================
-- Orc warrior, one two-handed sword, bare head and chest. Four chapters
-- from the Valley of Trials to the Tainted Scar, plus one debt written in
-- demon blood. The Burning Blade clan drank first and deepest of
-- Mannoroth's gift; its last swordmasters swear to cut the name clean.
-- Trial format: see the top of Trials.lua.
-- =========================================================================

PC.RegisterTrials("blademaster", {
    chapters = {
        [0] = "The Blood Debt",
        "Chapter I — The First Edge",
        "Chapter II — The Wandering Blade",
        "Chapter III — The Burning Path",
        "Chapter IV — The Perfect Cut",
    },
    trials = {
        -- ---- lifelong --------------------------------------------------
        {
            id = "bm_debt", chapter = 0, kind = "counter",
            -- The cult wears many names: Burning Blade in Durotar, the
            -- Barrens and Desolace; Searing Blade beneath Orgrimmar itself.
            pattern = { "Burning Blade", "Searing Blade" },
            name = "The Blood Debt",
            objective = "Cut down the Burning Blade cult — and the Searing Blade beneath Orgrimmar — wherever it festers",
            text = "Your clan drank first when Mannoroth poured. Now its name belongs to a cult that knives the Horde from the shadows. Every cultist you cut down buys back one drop of what was drunk. The debt is long.",
            milestones = {
                { count = 10, honorific = "Bladesworn" },
                { count = 50, honorific = "Cultbreaker" },
                { count = 200, honorific = "Redeemer of the Burning Blade" },
            },
            epitaph = "The blood debt counted %d of the Burning Blade dead.",
        },

        -- ---- Chapter I: Durotar & the Barrens (Initiate) -----------------
        {
            id = "bm_firstcut", chapter = 1, kind = "kill", level = 5,
            targets = { "Yarrog Baneshadow" },
            name = "The First Cut",
            objective = "Slay Yarrog Baneshadow in the cave above the Valley of Trials",
            text = "The cult does not wait for you to be ready. In a cave they call the Burning Blade Coven, within sight of the Den, Yarrog Baneshadow scratches demon marks into the rock. Walk in and make your first cut count.",
        },
        {
            id = "bm_oath", chapter = 1, kind = "emote", level = 8,
            emote = "KNEEL", zone = "Orgrimmar", subzone = "Valley of Wisdom",
            name = "The Oath of the Warchief",
            objective = "/kneel before Thrall in his fortress in the Valley of Wisdom",
            text = "A blade without an oath is just sharp iron. Walk into the Warchief's fortress in the Valley of Wisdom, kneel before Thrall, who freed your people, and bind your edge to the Horde where the old wolves can hear it.",
        },
        {
            id = "bm_forge", chapter = 1, kind = "cast", level = 10,
            spell = "Copper Claymore", zone = "Orgrimmar", subzone = "Valley of Honor",
            name = "Forged in the Valley of Honor",
            objective = "Craft a Copper Claymore at the forge in Orgrimmar's Valley of Honor",
            text = "Before you master the blade, make one. Smelt the copper yourself and hammer out a claymore in the Valley of Honor — a blademaster should know the weight of every step from ore to edge.",
        },
        {
            id = "bm_mirrors", chapter = 1, kind = "kill", level = 12,
            targets = { "Zalazane" },
            name = "The Way of Mirrored Images",
            objective = "Slay Zalazane on the Echo Isles",
            text = "Zalazane hides behind hexed kin and false faces on the Echo Isles. A blademaster knows the art of mirrored images better than any witch doctor — walk through the lies and cut the one that bleeds.",
        },
        {
            id = "bm_eye", chapter = 1, kind = "kill", level = 14,
            targets = { "Gazz'uz" },
            name = "The Eye in the Dark",
            objective = "Slay Gazz'uz in Skull Rock",
            text = "In the cave called Skull Rock, the warlock Gazz'uz whispers Durotar's secrets to a burning eye. The cult's tongue in this land. Cut it out.",
        },
        {
            id = "bm_whitemist", chapter = 1, kind = "kill", level = 16,
            targets = { "Echeyakee" }, solo = true, cleanOnly = true,
            name = "The White Mist",
            objective = "Call and slay Echeyakee in the Barrens — alone, vows clean",
            text = "Sergra Darkthorn will teach you the horn-call that brings Echeyakee, the white mist of the Barrens. Meet him alone, vows clean, and give the great hunt the respect of a single blade.",
        },
        {
            id = "bm_makgora", chapter = 1, kind = "kill", level = 20,
            targets = { "Hezrul Bloodmark" }, solo = true, cleanOnly = true, rankTrial = true,
            name = "The First Mak'gora",
            objective = "Slay Hezrul Bloodmark, the Kolkar khan — alone, vows clean",
            text = "Hezrul Bloodmark bleeds the Crossroads white and calls himself khan for it. Call your first mak'gora: walk into the Kolkar camps alone, vows clean, and answer him blade to blade. Win, and the Barrens will know a Disciple walks the gold grass.",
        },

        -- ---- Chapter II: the Barrens to the Scarlet gates (Disciple) -----
        {
            id = "bm_critical", chapter = 2, kind = "crit", level = 25,
            count = 50,
            honorific = "Keen Edge",
            name = "Trial of the Critical Strike",
            objective = "Land 50 critical strikes",
            text = "Any orc can swing hard. A blademaster finds the seam in the armor, the beat between heartbeats. Fifty perfect cuts — let your blade learn where the killing line runs.",
        },
        {
            id = "bm_hellscream", chapter = 2, kind = "emote", level = 29,
            emote = "SALUTE", zone = "Ashenvale", subzone = "Demon Fall Canyon",
            name = "Where Hellscream Fell",
            objective = "/salute at Grommash Hellscream's monument in Demon Fall Canyon",
            text = "Grom Hellscream drank the same blood your clan did — and paid the whole debt back in one swing. Walk to Demon Fall Canyon, stand before his axe, and salute the chieftain who showed every orc the way out.",
        },
        {
            id = "bm_islander", chapter = 2, kind = "kill", level = 32,
            targets = { "Big Will" }, solo = true,
            name = "The Islander's Test",
            objective = "Answer Klannoc Macleod's Affray on Fray Island and fell Big Will — alone",
            text = "On Fray Island off Ratchet, the Islander Klannoc Macleod keeps an old school: waves of brawlers, then their champion, Big Will. Take the test alone. A crowd at your back teaches the blade nothing.",
        },
        {
            id = "bm_purge", chapter = 2, kind = "kill", level = 31,
            pattern = { "Burning Blade", "Searing Blade" }, count = 25,
            name = "The Purge of Thunder Axe",
            objective = "Cut down 25 of the Burning Blade cult — Thunder Axe Fortress in Desolace crawls with them",
            text = "The cult holds a fortress now — Thunder Axe, in Desolace — and dreams demon dreams on Dreadmist Peak. Twenty-five of them. The debt does not collect itself.",
        },
        {
            id = "bm_bladestorm", chapter = 2, kind = "multihit", level = 36,
            spell = "Whirlwind", hits = 3, count = 10,
            honorific = "Bladestorm",
            name = "The Bladestorm",
            objective = "Strike 3 or more foes with a single Whirlwind, 10 times",
            text = "The masters of the old clan could become the storm — one blade, everywhere at once. Learn Whirlwind, then prove it: three foes caught in one turn of the blade, ten times over.",
        },
        {
            id = "bm_windmaster", chapter = 2, kind = "kill", level = 40,
            targets = { "Cyclonian" },
            name = "The Windmaster",
            objective = "Summon and slay Cyclonian, the Windmaster of Alterac",
            text = "Bath'rah the Windwatcher can call the Windmaster down from the peaks of Alterac — if you bring what the rite demands. Slay Cyclonian and take the storm itself into your steel.",
        },
        {
            id = "bm_champion", chapter = 2, kind = "kill", level = 42,
            targets = { "Herod" }, cleanOnly = true, rankTrial = true,
            name = "The Scarlet Champion",
            objective = "Answer Herod's challenge in the Scarlet Monastery, vows clean",
            text = "In the Monastery's armory, Herod bellows for a challenger worth his blade. Be the answer. Walk in with your vows clean and show the Scarlet Crusade what a single sword is for.",
            completionNote = "He dropped the Ravager — an axe, for all his bluster. No blade at all. Leave it.",
        },

        -- ---- Chapter III: Felwood & Blackrock (Exemplar) -----------------
        {
            id = "bm_stormblade", chapter = 3, kind = "equip", level = 41,
            items = { "Whirlwind Sword", "Sul'thraze the Lasher" },
            name = "A Blade with History",
            objective = "Wield the Whirlwind Sword forged from Cyclonian's heart, or reforge Sul'thraze the Lasher in Zul'Farrak",
            text = "Bath'rah can bind the Windmaster's heart into a greatsword — the storm you slew, sheathed at your back. Or piece Sul'thraze together from the two halves the Sandfury keep apart. Either way, carry a blade with a story worth telling.",
        },
        {
            id = "bm_bladefist", chapter = 3, kind = "emote", level = 44,
            emote = "SALUTE", zone = "Badlands", subzone = "Kargath",
            name = "The Price of the Blade",
            objective = "/salute at Kargath in the Badlands",
            text = "The outpost of Kargath bears the name of Bladefist, who cut off his own sword hand to be free of his chains. Stand among his namesakes and salute. Then ask yourself what you would give up for the blade.",
        },
        {
            id = "bm_reckless", chapter = 3, kind = "kill", level = 50,
            requireElite = true, requireBuff = "Recklessness",
            name = "The Reckless Strike",
            objective = "Slay an elite enemy while Recklessness is active",
            text = "There is a moment when the blademaster throws away the guard entirely — all edge, nothing held back. Call on Recklessness and fell an elite foe before the moment closes. The blade forgives nothing halfway.",
        },
        {
            id = "bm_council", chapter = 3, kind = "kill", level = 52,
            pattern = "Jaedenar", count = 25,
            name = "The Masters of the Cult",
            objective = "Slay 25 of the Shadow Council's servants in Jaedenar, Felwood",
            text = "The Burning Blade is the knife; the Shadow Council is the hand. In Felwood they named their den Jaedenar, after their demon lord. Carve twenty-five of them out of it.",
        },
        {
            id = "bm_arena", chapter = 3, kind = "kill", level = 56,
            targets = { "Skarr the Unbreakable", "Mushgog", "The Razza" }, cleanOnly = true,
            name = "The Gordunni Arena",
            objective = "Slay the champion of the Dire Maul arena pit, vows clean",
            text = "In the broken heart of Dire Maul the Gordunni keep a fighting pit, and things worse than ogres hold its title. Step onto the sand with your vows clean and take it from whichever champion is breathing.",
        },
        {
            id = "bm_falsewarchief", chapter = 3, kind = "kill", level = 58,
            targets = { "Warchief Rend Blackhand" }, cleanOnly = true, rankTrial = true,
            name = "The False Warchief",
            objective = "Slay Rend Blackhand in Blackrock Spire, vows clean",
            text = "Rend Blackhand squats on a throne of black rock and dares to call himself Warchief of a truer Horde. You knelt to the real one. Climb the Spire with your vows clean and cut the lie off at the neck.",
            completionNote = "He carried his father's twin blades — one for each hand. A blademaster needs but one. Leave them.",
        },

        -- ---- Chapter IV: mythic deeds (Paragon) --------------------------
        {
            id = "bm_doomlord", chapter = 4, kind = "kill", level = 60,
            targets = { "Lord Kazzak" },
            honorific = "Doomsbane",
            name = "The Last General",
            objective = "Slay Lord Kazzak in the Tainted Scar",
            text = "The Legion that bought your clan with blood left a general behind: Kazzak, brooding in the Tainted Scar. The debt has a final name on it. Take an army if you must — but take his head.",
        },
        {
            id = "bm_warlord", chapter = 4, kind = "equip", level = 60,
            items = { "High Warlord's Greatsword" },
            name = "The Warlord's Blade",
            objective = "Earn and wield the High Warlord's Greatsword",
            text = "The Horde's war has its own proving ground, and only its fiercest ever hold a High Warlord's blade. Fight under the banner until the whole Horde knows your name, and carry that greatsword into the field.",
        },
        {
            id = "bm_mythblade", chapter = 4, kind = "equip", level = 60,
            items = { "Ashkandi, Greatsword of the Brotherhood", "Zin'rokh, Destroyer of Worlds" },
            name = "A Blade Out of Legend",
            objective = "Wield Ashkandi from Nefarian's hoard, or Zin'rokh from the Gurubashi god-king",
            text = "Somewhere past the end of the war two blades wait: Ashkandi, in the claws of Nefarian atop Blackwing Lair, and Zin'rokh, in the blood-soaked halls of Zul'Gurub. A blademaster's life is complete with either. Few will ever hold one. Be few.",
        },
        {
            id = "bm_firstdust", chapter = 4, kind = "emote", level = 60,
            emote = "BOW", zone = "Durotar", subzone = "Valley of Trials",
            name = "The First Dust",
            objective = "/bow in the Valley of Trials",
            text = "You knelt to a Warchief; now bow to the dirt. Go back to the Valley of Trials, where the first cut was made, and bow to the dust that drank your first blood. The circle closes where it opened.",
        },
    },
})
