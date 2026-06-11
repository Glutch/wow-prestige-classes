-- Extracts every externally-checkable claim from the addon's data files
-- (zones, subzones, spells, auras, items, NPC names, emote tokens) into
-- JSON for tools/verify_data.py. Run from the repo root:
--   lua tools/extract_facts.lua > tools/facts.json

local PC = {}
local function loadmod(path)
    local chunk = assert(loadfile(path))
    chunk("PrestigeClasses", PC)
end
loadmod("PrestigeClasses/Util.lua")
loadmod("PrestigeClasses/Data.lua")
-- Load every journey file so new classes are picked up automatically.
local journeys = io.popen('ls PrestigeClasses/Trials/*.lua 2>/dev/null')
for path in journeys:lines() do
    loadmod(path)
end
journeys:close()

local facts = {} -- list of { kind, value, source }
local function fact(kind, value, source)
    facts[#facts + 1] = { kind = kind, value = value, source = source }
end

for _, def in ipairs(PC.Classes) do
    for _, trial in ipairs(def.trials or {}) do
        local src = def.id .. "/" .. (trial.id or "?")
        if trial.zone then fact("zone", trial.zone, src) end
        if trial.subzone then fact("subzone", trial.subzone, src) end
        if trial.spell then fact("spell", trial.spell, src) end
        if trial.aura then fact("spell", trial.aura, src) end -- auras are spells
        if trial.requireBuff then fact("spell", trial.requireBuff, src) end
        if trial.item then fact("item", trial.item, src) end
        for _, item in ipairs(trial.items or {}) do
            fact("item", item, src)
        end
        for _, npc in ipairs(trial.targets or {}) do
            fact("npc", npc, src)
        end
        if type(trial.pattern) == "table" then
            for _, p in ipairs(trial.pattern) do
                fact("npc_pattern", p, src)
            end
        elseif trial.pattern then
            fact("npc_pattern", trial.pattern, src)
        end
        if trial.emote then fact("emote", trial.emote, src) end
    end
end

local function jsonEscape(s)
    return (s:gsub('[\\"]', '\\%0'):gsub("\n", "\\n"))
end

local parts = {}
for _, f in ipairs(facts) do
    parts[#parts + 1] = string.format(
        '  {"kind": "%s", "value": "%s", "source": "%s"}',
        f.kind, jsonEscape(f.value), jsonEscape(f.source))
end
print("[\n" .. table.concat(parts, ",\n") .. "\n]")
