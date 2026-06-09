local ADDON, PC = ...

PC.Alerts = {}
local A = PC.Alerts

local PREFIX = "|cffff2020[Prestige]|r "
local GOOD = "|cff20ff20[Prestige]|r "

-- Remember the last compliance state so we only shout on transitions
-- (broke a rule / restored a rule) instead of spamming every gear scan.
local lastBrokenCount

local function flashCount(results)
    local broken = 0
    for _, r in ipairs(results) do
        if r.kind == "rule" and not r.ok then broken = broken + 1 end
    end
    return broken
end

-- Called by Core after every re-evaluation. `def` may be nil (no class chosen).
function A.OnEvaluated(def, results, summary)
    if not def then
        lastBrokenCount = nil
        return
    end

    local broken = flashCount(results)

    -- First evaluation after login: seed state silently.
    if lastBrokenCount == nil then
        lastBrokenCount = broken
        return
    end

    if broken > lastBrokenCount then
        -- A vow was just broken — name what's wrong.
        for _, r in ipairs(results) do
            if r.kind == "rule" and not r.ok then
                UIErrorsFrame:AddMessage("Prestige broken: " .. r.label, 1.0, 0.1, 0.1, 1.0)
            end
        end
        print(PREFIX .. "You have broken the way of the " .. def.name .. "!")
        PlaySound(8959, "Master") -- RaidWarning sound
    elseif broken == 0 and lastBrokenCount > 0 then
        print(GOOD .. "You once again walk the path of the " .. def.name .. ".")
        PlaySound(8960, "Master") -- RaidWarning end
    end

    lastBrokenCount = broken
end

function A.Reset()
    lastBrokenCount = nil
end
