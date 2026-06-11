local ADDON, PC = ...

-- =========================================================================
-- THE BEASTMASTER'S JOURNEY
-- =========================================================================
-- Hunter of any people, one great beast at their side. Four chapters from
-- the first taming to the crater of the thunder lizards, plus one ledger
-- of despoilers that never closes. The shape of the path is Rexxar's: the
-- Warcraft III Beastmaster who calls bear, quilbeast and hawk, and walks
-- away from every throne he saves.
-- Trial format: see the top of Trials.lua.
-- =========================================================================

PC.RegisterTrials("beastmaster", {
    -- Item IDs verified against ItemSparse DB2 (tools/verify_data.py).
    itemIds = {
        ["Venomstrike"] = 6469,
        ["Bow of Searing Arrows"] = 2825,
        ["Devilsaur Leather"] = 15417,
        ["Rhok'delar, Longbow of the Ancient Keepers"] = 18713,
        ["Lok'delar, Stave of the Ancient Keepers"] = 18715,
    },
    suggested = {
        { id = 6469, name = "Venomstrike",
          note = "Lord Serpentis, Wailing Caverns — a serpent's fang strung as a bow" },
        { id = 2825, name = "Bow of Searing Arrows",
          note = "World drop — fire rides the string" },
        { id = 2824, name = "Hurricane",
          note = "World drop — the fastest bow in the world, quick as a wing-beat" },
        { id = 2100, name = "Precisely Calibrated Boomstick",
          note = "World drop — thunder for the hunter who trusts powder over feathers" },
        { id = 18323, name = "Satyr's Bow",
          note = "Zevrim Thornhoof, Dire Maul — taken from a tormentor of the wilds" },
        { id = 15063, name = "Devilsaur Gauntlets",
          note = "Leatherworking — cut from thunder-lizard hide you skinned yourself" },
        { id = 15062, name = "Devilsaur Leggings",
          note = "Leatherworking — the second half of the devilsaur's gift" },
        { id = 18680, name = "Ancient Bone Bow",
          note = "Scholomance — old bone, still singing" },
        { id = 12651, name = "Blackcrow",
          note = "Shadow Hunter Vosh'gajin, Lower Blackrock Spire — the crow's wing at full draw" },
        { id = 17069, name = "Striker's Mark",
          note = "Magmadar, Molten Core — claimed from the greatest hound in the world" },
        { id = 19361, name = "Ashjre'thul, Crossbow of Smiting",
          note = "Chromaggus, Blackwing Lair — taken from Nefarian's chained beast, who deserved better" },
        { id = 19853, name = "Gurubashi Dwarf Destroyer",
          note = "Hakkar the Soulflayer, Zul'Gurub — pulled from the Blood God's hoard" },
    },
    chapters = {
        [0] = "The Wild's Ledger",
        "Chapter I — The First Bond",
        "Chapter II — The Wandering Wilds",
        "Chapter III — Fang and Wrath",
        "Chapter IV — The Pack Eternal",
    },
    trials = {
        -- ---- lifelong --------------------------------------------------
        {
            id = "bst_ledger", chapter = 0, kind = "counter",
            pattern = { "Venture Co." },
            name = "The Wild's Ledger",
            objective = "Cut down the Venture Company wherever it fells, traps and strip-mines the wild",
            text = "Rexxar said it plainly: their wars do nothing but scar the land, and drive the wild things to extinction. The Venture Company does it for coin. Every logger, trapper and overseer you put down is one entry settled in the wild's ledger. The ledger is long.",
            milestones = {
                { count = 10, honorific = "Wildwarden" },
                { count = 50, honorific = "Wrath of the Wilds" },
                { count = 200, honorific = "Champion of the Wilds" },
            },
            epitaph = "The wild's ledger counted %d despoilers dead.",
        },

        -- ---- Chapter I: the first bond (Initiate) ------------------------
        {
            id = "bst_bond", chapter = 1, kind = "cast", level = 10,
            spell = "Tame Beast",
            name = "The First Bond",
            objective = "Pass the taming trials of your people and tame your first beast",
            text = "Every people sets the same test: three beasts, one rod, and the long quiet minute where the wild decides whether to trust you. Rexxar found Misha as an orphaned cub and never walked alone again. Pass the trials, speak the words, and take your first friend from the wild's own hand.",
        },
        {
            id = "bst_name", chapter = 1, kind = "emote", level = 11,
            emote = "PAT",
            name = "The Naming",
            objective = "/pat your companion, and give it a true name",
            text = "A tool has a label; family has a name. Look your beast in the eye, lay a hand on its head, and name it — not for what it does, but for what it is. You will say that name ten thousand times before the end. The vow stands: never abandon it, never let it die.",
        },
        {
            id = "bst_spines", chapter = 1, kind = "kill", level = 14,
            pattern = { "Razormane", "Bristleback" }, count = 25,
            name = "Thorn and Spine",
            objective = "Slay 25 Razormane and Bristleback quilboar with your beast at your side",
            text = "The old beastmasters fought beside spine-beasts, and the quilboar are what becomes of that kinship gone rotten — thornweavers who hex the boar instead of walking with it. Cull twenty-five of their raiders, two hunters working as one. Learn how your beast moves before the fights that matter.",
        },
        {
            id = "bst_bloodfeather", chapter = 1, kind = "kill", level = 18,
            targets = { "Serena Bloodfeather" }, solo = true, cleanOnly = true, rankTrial = true,
            name = "The Bloodfeather",
            objective = "Slay Serena Bloodfeather in the Barrens — you and your beast alone, vows clean",
            text = "The Witchwing harpies steal eggs, kill mothers, and pick the bones of the Barrens' young. Their matriarch is Serena Bloodfeather. Go to her crag with no one but your beast, vows clean, and show the wild what its two-bodied hunter is for.",
        },

        -- ---- Chapter II: the wandering wilds (Disciple) ------------------
        {
            id = "bst_pridelord", chapter = 2, kind = "cast", level = 23,
            spell = "Tame Beast", zone = "The Barrens",
            name = "The Pridelord",
            objective = "Tame a great beast of the Barrens — Humar the Pridelord, the black lion, prowls the lone oasis tree",
            text = "Word among hunters of both banners: a lion black as a moonless night holds the tree at the Forgotten Pools, and no second like him walks the world. Sit out his rivals, earn his charge, and make the rarest beast of the savannah your second self. Tame the rarest you can find — that is the vow.",
        },
        {
            id = "bst_venture", chapter = 2, kind = "kill", level = 26,
            pattern = "Venture Co.", count = 25,
            name = "The Despoiled Hills",
            objective = "Slay 25 of the Venture Company — Windshear Crag in Stonetalon is theirs from ridge to ridge",
            text = "In Stonetalon the Venture Company has eaten a whole valley: shredders, sawmills, stumps to the horizon. The beasts that lived there did not move out; they died. Twenty-five of the Company, anywhere you find them. The crag is a good place to start the lesson.",
        },
        {
            id = "bst_bite", chapter = 2, kind = "equip", level = 28,
            items = { "Venomstrike", "Bow of Searing Arrows" },
            name = "A Bow with a Bite",
            objective = "Wield Venomstrike from the Wailing Caverns, or a Bow of Searing Arrows",
            text = "A beastmaster's bow should be half animal itself. Venomstrike spits a serpent's poison from the deeps of the Wailing Caverns; the Bow of Searing Arrows bites with fire. Carry a weapon with its own temper, and learn to work with it the way you work with your beast.",
        },
        {
            id = "bst_hawkcry", chapter = 2, kind = "proc", level = 30,
            aura = "Screech", count = 50,
            honorific = "Hawkfriend",
            name = "The Hawk's Cry",
            objective = "Take a bird of prey under your wing and land its Screech on 50 foes",
            text = "The beastmaster's third summons was always the hawk — eyes above the canopy, a cry that breaks the enemy's nerve. Tame a screecher of the forests, teach it the war-cry, and let fifty foes flinch under it. The sky fights for you now.",
        },
        {
            id = "bst_greenhills", chapter = 2, kind = "visit", level = 32,
            zone = "Stranglethorn Vale", subzone = "Nesingwary's Expedition",
            name = "The Camp of the Great Hunt",
            objective = "Walk into Hemet Nesingwary's camp in Stranglethorn Vale",
            text = "The dwarf in that camp is the most famous hunter alive, and he has never once walked with a beast — only over them, stuffed and mounted. Share his fire, hear his stories, take his trials if you wish. Then look at the trophies and understand the difference between a hunter of beasts and a hunter with them.",
        },
        {
            id = "bst_matriarch", chapter = 2, kind = "kill", level = 33,
            targets = { "Charlga Razorflank" }, cleanOnly = true,
            name = "The Thorn Matriarch",
            objective = "Slay Charlga Razorflank in Razorfen Kraul, vows clean",
            text = "Beneath the Barrens the quilboar matriarch Charlga Razorflank dreams in a warren of thorns, hexing the boar-kin into chained war-beasts. The kinship she perverts is yours to defend. Walk into the Kraul with your vows clean and cut the rot out at the root.",
        },
        {
            id = "bst_stampede", chapter = 2, kind = "multihit", level = 34,
            spell = "Multi-Shot", hits = 3, count = 10,
            honorific = "Stampede",
            name = "The Stampede",
            objective = "Strike 3 or more foes with a single Multi-Shot, 10 times",
            text = "The old beastmasters' last word was the Stampede — the whole wild loosed at once, no foe left unstruck. Yours is loosed from a bowstring. Three foes under one volley, ten times over, until the enemy hears hoofbeats every time you draw.",
        },
        {
            id = "bst_bangalash", chapter = 2, kind = "kill", level = 42,
            targets = { "King Bangalash" }, cleanOnly = true, rankTrial = true,
            name = "The Great Hunt",
            objective = "Slay King Bangalash, the white king of Stranglethorn, vows clean (a level 43 elite — a deed for the low 40s)",
            text = "Nesingwary saves the white tiger for last because nothing in the jungle is his equal. Meet King Bangalash the old way — beast against beast, hunter against king — with your vows clean. End his hunt with honor, and leave his head where it lies. You are not collecting trophies; you are being measured.",
        },

        -- ---- Chapter III: fang and wrath (Exemplar) ----------------------
        {
            id = "bst_brokentooth", chapter = 3, kind = "cast", level = 40,
            spell = "Tame Beast", zone = "Badlands",
            name = "The Fastest Fangs",
            objective = "Tame a cat of the Badlands — hunters whisper of Broken Tooth, whose bite never stops",
            text = "In the dust of the Badlands stalks a battle-scarred mountain lion the goblins' traps could never hold. Broken Tooth, they call him — no faster set of jaws exists in all the world, and every beastmaster alive knows his name. Track him through the dry hills and offer him a better war than the one that scarred him.",
        },
        {
            id = "bst_wanderer", chapter = 3, kind = "emote", level = 41,
            emote = "SALUTE", zone = "Desolace",
            name = "The Wanderer's Road",
            objective = "/salute Rexxar, last of the Mok'Nathal, where he walks the roads of Desolace",
            text = "The greatest beastmaster alive saved a nation, broke an admiral, was named champion of a whole people — and walked away from all of it, back to the empty roads with Misha at his side. Find him on his endless patrol through Desolace and salute him, whatever banner you carry. He will understand what you are becoming.",
        },
        {
            id = "bst_predator", chapter = 3, kind = "crit", level = 45,
            count = 50,
            name = "The Predator's Eye",
            objective = "Land 50 critical strikes of your own",
            text = "Watch your beast hunt: it does not flail, it waits, and then it takes the throat. Fifty perfect strikes of your own — arrow or spear-thrust, each one placed where the prey ends. The beast teaches; the master learns.",
        },
        {
            id = "bst_timbermaw", chapter = 3, kind = "visit", level = 50,
            subzone = "Timbermaw Hold",
            name = "The Furbolg Door",
            objective = "Walk the tunnel of Timbermaw Hold in Felwood",
            text = "The Timbermaw are the last uncorrupted furbolg — beast-folk who judge every visitor by deed, not banner. Their hold is a door through the mountain that opens only to the trusted. Stand in their tunnel and be weighed. A friend of the wild should be at home among the beast-people, or learn why he is not.",
        },
        {
            id = "bst_thunderhides", chapter = 3, kind = "loot", level = 55,
            item = "Devilsaur Leather", count = 10,
            name = "Hides of the Thunder Lizard",
            objective = "Skin 10 Devilsaur Leather in Un'Goro Crater",
            text = "When the old beastmasters called the Stampede, it was thunder lizards that answered. Their blood runs in the devilsaurs of Un'Goro. Hunt the great lizards in their own crater and take ten hides with your own knife — the wild's armor, paid for at the wild's price.",
        },
        {
            id = "bst_frostsaber", chapter = 3, kind = "cast", level = 57,
            spell = "Tame Beast", zone = "Winterspring",
            name = "The Frostsaber",
            objective = "Tame a great cat of Winterspring — Rak'shiri, the pale stalker, hunts the snowfields",
            text = "North of everything, where the snow never breaks, the frostsaber prides hunt in silence. Among them moves Rak'shiri, ice-blue and faster than rumor. A beastmaster's last tame should be his rarest — that was the vow at the start. Winterspring is where such vows are kept.",
        },
        {
            id = "bst_thebeast", chapter = 3, kind = "kill", level = 58,
            targets = { "The Beast" }, cleanOnly = true, rankTrial = true,
            name = "No Cage May Hold",
            objective = "Slay The Beast in Blackrock Spire, vows clean",
            text = "In the upper halls of Blackrock Spire the warlocks of the Blackhand keep a creature with no name — only a cage. No taming this age knows will reach it; the fire has been bred too deep. Walk in with your vows clean and grant it the one freedom left to give. A beastmaster does not look away from this.",
            completionNote = "It died facing its keepers' door, not yours. Remember that the next time someone calls a chained thing a monster.",
        },

        -- ---- Chapter IV: mythic deeds (Paragon) --------------------------
        {
            id = "bst_kingmosh", chapter = 4, kind = "kill", level = 60,
            targets = { "King Mosh" }, solo = true,
            honorific = "Beastlord",
            name = "The King of Un'Goro",
            objective = "Slay King Mosh, the devilsaur king — you and your beast alone",
            text = "The crater has a king: King Mosh, eldest devilsaur of Un'Goro, whom whole hunting parties walk wide around. Take him with no army — just the two of you, wits, lures and legwork against the largest land predator alive. Bring this off and there is no beast on Azeroth you need fear, and none that need fear you without cause.",
        },
        {
            id = "bst_beastbreaker", chapter = 4, kind = "kill", level = 60,
            targets = { "Bloodlord Mandokir" },
            name = "The Beast-Breaker",
            objective = "Slay Bloodlord Mandokir in Zul'Gurub",
            text = "In sunken Zul'Gurub the Bloodlord Mandokir rides a raptor broken to the whip — a war-beast with no name of its own, only a master's spurs. He is everything your path stands against, wearing a crown. Take an army into the Gurubashi ruin and put the breaker of beasts in the ground.",
            completionNote = "The raptor Ohgan fell defending the hand that whipped him. Mourn the beast; never forgive the breaking.",
        },
        {
            id = "bst_ancients", chapter = 4, kind = "equip", level = 60,
            items = { "Rhok'delar, Longbow of the Ancient Keepers",
                      "Lok'delar, Stave of the Ancient Keepers" },
            name = "The Ancients' Answer",
            objective = "Earn Rhok'delar or Lok'delar from the Ancients of Irontree Woods",
            text = "From the Firelord's own cache comes a petrified leaf, and the Ancients of Felwood will read it as a summons. Their price is the strangest hunt of your life: four demons wearing friendly faces, each fought utterly alone — the one trial your beast must sit out. Pass it, and the trees themselves will arm you. No truer weapons exist for your kind.",
        },
        {
            id = "bst_roar", chapter = 4, kind = "emote", level = 60,
            emote = "ROAR", zone = "Un'Goro Crater",
            name = "The Wild's Voice",
            objective = "/roar with your beast in Un'Goro Crater",
            text = "You knelt to no throne and saluted only a wanderer. Finish as Rexxar finished: go to the oldest wild place in the world, stand beside the friend who walked every road with you, and roar — two voices answering as one. Then go back to the wild, owing nothing to anyone.",
        },
    },
})
