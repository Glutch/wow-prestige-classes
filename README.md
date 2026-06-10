# Prestige Classes

A World of Warcraft **Classic Era (Hardcore)** addon that turns the old
Warcraft RPG *prestige classes* into self-imposed rulesets. Pick a prestige
class, follow its vows, and the addon tracks — live — whether you're truly
walking that path.

- **Client:** WoW Classic Era 1.15.x (Interface `11508`)
- **Install path:** `_classic_era_/Interface/AddOns/PrestigeClasses`

## The idea

Each prestige class is a way to *force yourself* to play a certain fantasy.
Example — the **Blademaster**:

- must be an **Orc Warrior**
- **no head, no chest** armor
- **two-handed sword only**
- themed profession: Blacksmithing
- vows: escape death rather than die, never raise a shield

When you equip a helm or swap to an axe, the screen flashes red, your
class cries out in chat ("The blade is dishonored!"), and your status flips
to *broken* until you fix it. The addon keeps a **record per path**: how long
you've walked it, how many times you broke your vows, and your current clean
streak. Keep an unbroken record from level 1 and wear it with pride.

## Using it

- `/pc` or `/prestige` — open the window
- `/pc status` — print your active path's compliance in chat
- `/pc journal` — open your path's trial journal (paths that have one)
- `/pc list` — list every prestige class (★ = open to your character)
- `/pc suggest` — let destiny pick an eligible path for you
- `/pc abandon` — drop your current path (asks for confirmation)
- `/pc help` — command list
- Minimap button — toggle the window; drag it along the ring to move it

The window opens on a full-width **browse page**: every path grouped by WoW
class (your own class first), colored by faction, with paths your character
can actually take sorted to the top and the rest greyed out. Hover a row for
its fantasy. Click one to open its **detail page** — icon, fantasy, live
requirement checks (ready-check ✓ / ✗) in one column, roleplay vows and your
record in the other. Hit **Walk this path** to bind it to the character, or
**Surprise me** to let fate pick. The choice is saved **per character**, and
your rank grows with your level: Initiate → Disciple → Exemplar → Paragon.

## What gets auto-checked

Machine-enforced rules: race, class, level, forbidden armor slots, max armor
weight (Cloth/Leather/Mail/Plate), allowed weapon types, dual-wield
requirement, no-shield, ranged weapon type, pet present/absent, required
professions (the Dark Apothecary *must* know Alchemy, the Tinker *must* know
Engineering) — and **talents**.

Most paths demand a talent discipline. A tree requirement scales with your
level (a Blademaster is expected to sink points into Arms as they grow,
reaching 31 by the mid-40s, with a few points of slack for utility), and key
talents become mandatory at the level they're reachable: the Blademaster must
learn Sweeping Strikes (the Bladestorm) and Mortal Strike, the Mountain
King's Storm Bolt is 5/5 Mace Specialization, the Hexer must freeze foes
solid with 3/3 Frostbite, the Priestess of the Moon places her moonwell with
Lightwell, multi-class paths like the Duelist check the right tree for your
class (Arms for warriors, Combat + Riposte for rogues). Respec away from the
path and it breaks on the spot.

Other professions are *suggested* (shown but never count as a failure). The
**vows** are roleplay honor rules the addon can't see — they're listed so you
know how to truly inhabit the class.

## Classes included

Blademaster, Mountain King, Berserker, Beastmaster, Marksman, Assassin,
Duelist, Warden, Druid of the Wild, Vindicator, Gladiator, Spirit Walker,
Hexer, Necromancer, Archmage of the Kirin Tor, Bone Crusher, Shadow Hunter,
Dark Apothecary, Demon Hunter, Priestess of the Moon, Elven Ranger, Far Seer,
Witch Doctor, Buccaneer, Tinker — 25 paths, each mapped to a Classic-legal
race/class combo.

Add your own by appending an entry to `Data.lua` (the format is documented at
the top of that file).

## Trials — the journey (Mountain King first)

A path can carry a **trial journey**: chapters of deeds, one per rank, all
auto-detected. The **Mountain King** has the full treatment — 22 deeds from
Coldridge Valley to the Molten Core:

- **Hunts** — named quarry (Grik'nir, Vagash, Chok'sul, Margol the Rager,
  General Angerforge, Emperor Thaurissan, Ragnaros…)
- **Rites & pilgrimages** — `/kneel` at the High Seat, `/salute` the
  Stonewrought Dam, `/mourn` on the Thandol Span, stand before Grim Batol,
  `/drink` at the Thunderbrew Distillery
- **Feats of arms** — 50 mace-storm stuns, Thunder Clap 3+ foes ten times,
  slay an elite during Stoneform
- **Craft & relics** — forge a Heavy Copper Maul at the Great Forge itself,
  smelt Dark Iron at the Black Anvil, wield Smite's Mighty Hammer, The
  Unstoppable Force, Sulfuras
- **The Grudge of Khaz Modan** — every Dark Iron you slay is counted,
  forever; milestones grant honorifics (Grudgebearer → Grudgekeeper →
  Avenger of the Three Hammers)

On a path with trials, **rank is earned, not given**: each chapter ends in a
rank trial, and ascending to Disciple/Exemplar/Paragon takes the level *and*
the deed. Trial completions flash the screen gold (the joyful mirror of the
red vow-break), honorifics stack on your record, and everything — deeds,
titles, the grudge count — is written into your death epitaph. Browse it all
in the **Path Journal** (`/pc journal`, or the button on your path's page).

Every deed carries a **suggested level** (shown in the journal, red while
it's still above you), and both the journal and the character-sheet sidebar
show **"up next"** — the deeds within reach right now, easiest first, with a
pending rank trial always on top.

Some trials demand clean vows at the moment of the kill, some demand you be
alone. Kills credit whenever you contributed damage, so dungeon rank trials
work in groups.

To write a journey for another class, drop a `Trials/<Class>.lua` file that
calls `PC.RegisterTrials(classId, { chapters, trials })` and list it in the
`.toc` — the format is documented at the top of `Trials.lua`.

## Development

```sh
lua test_compliance.lua   # offline logic tests (mocks the WoW API)
lua test_trials.lua       # trial engine: a full Mountain King playthrough
```

### Verifying journey data (no level-60 playtest required)

Trial data makes claims about the world — NPC names, subzones, spells,
items. Three layers keep them honest:

1. **Offline verifier** (run from the repo root):

   ```sh
   lua tools/extract_facts.lua > tools/facts.json
   python3 tools/verify_data.py
   ```

   Every zone/subzone string is checked against the actual client database
   (AreaTable/WMOAreaTable/Map DB2 dumps via wago.tools, pinned Era build) —
   the same strings `GetSubZoneText()` returns. Spell and aura names check
   against SpellName, items against ItemSparse, emote tokens against the
   client's own ChatFrame source. NPC names check against Wowhead Classic.
   Facts are extracted automatically from every `Trials/*.lua`, so a new
   journey is covered the moment the file exists.

2. **Structural lint** — `/pc verify` in game (or the test suite) validates
   every journey's shape: trial kinds, required fields, the rank-trial
   ladder, milestone ordering.

3. **Field probes** — `/pc debug` traces every detection input live (zone
   strings, your aura names, kill credits and why they were rejected). And
   when you do the right deed in the wrong spot, the addon always tells you
   what location the client reports vs. what the trial expects — so a wrong
   subzone string surfaces the first time anyone visits the place, on any
   character, at any level. Named-quarry kills that fail a condition (group,
   broken vows, missing buff) say so out loud instead of silently not
   counting.

What only the field can prove: proc/behavioral details (e.g. that Mace
Specialization's stun applies "Mace Stun Effect" — cross-checked against
vmangos and other addons' sources) — `/pc debug` confirms those the first
time they happen.

Files: `Util` (API introspection) → `Data` (rulesets) → `Compliance`
(evaluator) → `Alerts` (warnings, flashes, ceremonies, epitaph) →
`Trials` (trial engine) → `Trials/<Class>.lua` (per-class journeys) →
`UI` (window + journal + minimap) → `Core` (events + slash commands).
