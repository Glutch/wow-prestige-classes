# Prestige Classes — development notes

WoW **Classic Era (Hardcore)** addon: turns Warcraft RPG prestige classes into
self-imposed, live-checked rulesets. 25 paths, each a race/class-gated set of
gear/pet/profession/talent rules plus unenforceable roleplay "vows".

- Target client: Classic Era 1.15.x, Interface `11508` (keep `.toc` in sync)
- WoW runs **Lua 5.1** — no goto, no integer division, no `\z`. Local
  `lua`/`luac` are 5.4 (brew); code must stay 5.1-compatible.
- Locale assumption: **enUS**. Rules match localized strings (item subtypes
  like "Two-Handed Swords", skill lines like "Alchemy", talent/tree names).

## Workflow

```sh
cd PrestigeClasses
lua test_compliance.lua    # offline tests, mocks the WoW API — keep green
for f in *.lua; do luac -p "$f"; done   # syntax check

# install for live testing, then /reload in game
cp PrestigeClasses.toc *.lua "/Applications/World of Warcraft/_classic_era_/Interface/AddOns/PrestigeClasses/"
```

`test_compliance.lua` is dev-only — never list it in the `.toc`. When adding a
rule type or class, add a test; when changing existing checks, update the
mocks (`world.talentTrees`, `world.equipped`, etc. — see top of file).

## Architecture (load order = `.toc` order)

| File | Role |
|---|---|
| `Util.lua` | WoW API introspection: race/class tokens, equipped links, item type info, professions, `TalentSummary()` |
| `Data.lua` | `PC.Classes` rulesets. Full field reference in its header comment. Pure data — no logic |
| `Compliance.lua` | `Evaluate(def)` → ordered check results + summary; `Eligible(def)` (race/class only) |
| `Alerts.lua` | Transition-only warnings: red screen flash, per-class break/restore cries, increments `stats.breaks` |
| `UI.lua` | Two-page window (browse grouped by WoW class → full-window detail), abandon confirm popup, draggable minimap button |
| `Core.lua` | Event wiring, `PC.Refresh()`, slash commands (`/pc`, status/list/suggest/abandon/help) |

Modules share the private addon table: `local ADDON, PC = ...`.

## Key design decisions

- **Check kinds**: `identity` (race/class/level — unfixable, excluded from
  rules count), `rule` (live, fixable, drives broken/honored state), `info`
  (suggestions + not-yet-due talents — never fails). "Compliant" =
  identity OK and all `rule`s pass.
- **Alerts fire on transitions only** (`lastBrokenCount` compare), seeded
  silently on login. `Alerts.Reset()` on activate/abandon.
- **Talent tree rule scales with level**: expected points =
  `min(target, level - 9 - 5)` (`TREE_SLACK = 5` free points). Key talents
  (`keys = { name, level, rank? }`) are `rule` from their `level`, `info`
  preview below it. Multi-class paths key the spec by class token
  (`talents = { WARRIOR = {...}, ROGUE = {...} }`).
- **Talent data verified** against warcraft.wiki.gg + 1.12 calculator
  datasets. Gotchas already caught: shaman tab is named **"Elemental
  Combat"**, druid tab **"Feral Combat"**; Holy Nova is **tier 3** in 1.12
  (1.10 moved it), Holy 31-pointer is **Lightwell**. Verify tier/tree before
  adding new key talents — vanilla placement often differs from later
  expansions.
- Classic Era API: `GetTalentTabInfo(tab)` → `name, texture, pointsSpent,
  fileName`; `GetTalentInfo(tab, i)` → `name, icon, tier, column, rank,
  maxRank`. `GetItemInfoInstant` is used for item types (synchronous).
- **SavedVariables** (`PrestigeClassesCharDB`, per character):
  `{ active = id|nil, stats = { chosenAt, breaks, lastBreakAt }|nil,
  minimapAngle = deg|nil }`. Stats reset on activate, erased on abandon;
  pre-stats characters get seeded on `ADDON_LOADED`.
- UI ranks are level-based flavor: Initiate <20, Disciple <40, Exemplar <60,
  Paragon 60. Faction colors: Alliance `5aa0ff`, Horde `ff5a5a`, Both
  `d0b860`; ineligible grey `666666`.

## Adding a prestige class

Append to `Data.lua` (field docs in its header): id/name/source/faction,
`icon` (verify the texture exists in Classic-era files), fantasy, rule
fields, `talents`, `breakCry`/`restoreCry`, 3 `honorRules`. A journey's
`RegisterTrials` also takes `itemIds` (name→verified item ID — lint requires
one for every item a deed names; drives the hoverable spoils/suggested
strips on the path page) and `suggested` ({id,name,note} gear list — the
site consumes it via `bun run data`, never hand-edit the site copy). Keep faction
balance roughly even (currently A:8 H:9 Both:8). Race tokens are file tokens:
`Scourge` (undead), `NightElf`. Class entries appear automatically in the UI
under each class in `classes` and in eligibility sorting — no UI changes
needed.

## Misc

- A third-party addon `HardcoreClassesEnhanced` covers similar ground — keep
  names/saved-variable globals distinct.
- Frame names are prefixed `PrestigeClasses*`; main frame closes on Escape
  via `UISpecialFrames`.
- User prefs: short concise communication; no timeline estimates.
