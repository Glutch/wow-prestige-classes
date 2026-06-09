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

When you equip a helm or swap to an axe, the addon flashes a warning and your
status flips to *broken* until you fix it.

## Using it

- `/pc` or `/prestige` — open the window
- `/pc status` — print your active path's compliance in chat
- `/pc list` — list every prestige class
- `/pc abandon` — drop your current path
- Minimap button — toggle the window

In the window: click a class on the left to read its fantasy, live
requirement checks (green ✓ / red ✗), and roleplay vows. Hit **Become this
class** to bind it to the character. The choice is saved **per character**.

## What gets auto-checked

Machine-enforced rules: race, class, level, forbidden armor slots, max armor
weight (Cloth/Leather/Mail/Plate), allowed weapon types, no-shield, ranged
weapon type, and pet present/absent. Professions are *suggested* (shown but
never count as a failure). The **vows** are roleplay honor rules the addon
can't see — they're listed so you know how to truly inhabit the class.

## Classes included

Blademaster, Mountain King, Berserker, Beastmaster, Marksman, Assassin,
Duelist, Warden, Druid of the Wild, Vindicator, Gladiator, Spirit Walker,
Hexer, Necromancer, Archmage of the Kirin Tor, Bone Crusher, Shadow Hunter,
Dark Apothecary — each mapped to a Classic-legal race/class combo.

Add your own by appending an entry to `Data.lua` (the format is documented at
the top of that file).

## Development

```sh
lua test_compliance.lua   # offline logic tests (mocks the WoW API)
```

Files: `Util` (API introspection) → `Data` (rulesets) → `Compliance`
(evaluator) → `Alerts` (transition warnings) → `UI` (window + minimap) →
`Core` (events + slash commands).
