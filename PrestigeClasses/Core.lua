local ADDON, PC = ...

-- Re-evaluate the active path and refresh both alerts and UI. Safe to call
-- often; it does nothing expensive when no class is chosen.
function PC.Refresh()
    local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
    local def = activeId and PC.ClassById[activeId] or nil

    if def then
        local results, summary = PC.Compliance.Evaluate(def)
        PC.lastSummary = summary -- consumed by the minimap indicator/tooltip
        PC.Alerts.OnEvaluated(def, results, summary)
    else
        PC.lastSummary = nil
        PC.Alerts.OnEvaluated(nil)
    end

    if PC.UI and PC.UI.UpdateMinimap then
        PC.UI.UpdateMinimap()
    end

    if PC.UI and PC.UI.frame and PC.UI.frame:IsShown() then
        PC.UI.Refresh()
    end
    if PC.UI and PC.UI.RefreshCharacterSidebar then
        PC.UI.RefreshCharacterSidebar() -- no-op while the character sheet is closed
    end
end

local function printStatus()
    local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
    if not activeId then
        print("|cffffd100[Prestige]|r No path chosen. Type |cff40ff40/pc|r to choose one.")
        return
    end
    local def = PC.ClassById[activeId]
    local results, summary = PC.Compliance.Evaluate(def)
    print("|cffffd100[Prestige]|r Path of the " .. def.name .. " — " ..
        (summary.compliant and "|cff40ff40honored|r" or "|cffff4040broken|r") ..
        " (" .. summary.rulesPassed .. "/" .. summary.rulesTotal .. " vows)")
    for _, r in ipairs(results) do
        if r.kind ~= "info" and not r.ok then
            print("   |cffff4040x|r " .. r.label .. " — " .. (r.detail or ""))
        end
    end
    local stats = PrestigeClassesCharDB.stats
    if stats then
        print("   |cff999999Vows broken " .. (stats.breaks or 0) .. " time(s) on this path.|r")
    end
    if def.trials and PC.Trials then
        local done, total = PC.Trials.Counts(def)
        local _, title, pending = PC.Trials.RankInfo(def)
        print("   |cff999999" .. title .. " — " .. done .. "/" .. total ..
            " deeds done" ..
            (pending and (". Next ascension: " .. pending.name) or "") ..
            ". /pc journal|r")
    end
end

local function suggestPath()
    local pool = {}
    for _, def in ipairs(PC.Classes) do
        if PC.Compliance.Eligible(def) and def.id ~= PrestigeClassesCharDB.active then
            pool[#pool + 1] = def
        end
    end
    if #pool == 0 then
        print("|cffffd100[Prestige]|r No other paths are open to this character.")
        return
    end
    local def = pool[math.random(#pool)]
    print("|cffffd100[Prestige]|r Destiny whispers: |cff40ff40" .. def.name .. "|r — " ..
        def.fantasy)
    print("   |cff999999Open /pc and look for it in the list.|r")
end

local function printHelp()
    print("|cffffd100[Prestige]|r Commands:")
    print("   |cff40ff40/pc|r — open the window")
    print("   |cff40ff40/pc status|r — your path's compliance in chat")
    print("   |cff40ff40/pc journal|r — your path's trials and deeds")
    print("   |cff40ff40/pc list|r — every prestige class (★ = open to you)")
    print("   |cff40ff40/pc suggest|r — let destiny pick a path for you")
    print("   |cff40ff40/pc abandon|r — give up your current path")
end

local function handleSlash(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "status" then
        printStatus()
    elseif msg == "journal" or msg == "trials" then
        PC.UI.OpenJournal()
    elseif msg == "debug" then
        PrestigeClassesCharDB.debug = not PrestigeClassesCharDB.debug
        print("|cffffd100[Prestige]|r Detection tracing " ..
            (PrestigeClassesCharDB.debug and "ON — emotes, auras, kills and locations will be logged."
                or "off."))
    elseif msg == "verify" then
        local total = 0
        for _, def in ipairs(PC.Classes) do
            if def.trials then
                local problems = PC.Trials.Lint(def)
                total = total + #problems
                for _, p in ipairs(problems) do
                    print("|cffff4040[Prestige]|r " .. p)
                end
            end
        end
        print("|cffffd100[Prestige]|r Journey data check: " ..
            (total == 0 and "|cff40ff40all clean|r" or (total .. " problem(s)")))
    elseif msg == "abandon" then
        PC.UI.Abandon()
    elseif msg == "suggest" or msg == "roll" then
        suggestPath()
    elseif msg == "help" then
        printHelp()
    elseif msg == "list" then
        print("|cffffd100[Prestige]|r Available paths:")
        for _, c in ipairs(PC.Classes) do
            local open = PC.Compliance.Eligible(c)
            print("   " .. (open and "|cffffd100★|r " or "|cff666666–|r ") ..
                c.name .. " |cff999999(" .. c.faction .. ")|r")
        end
    else
        PC.UI.Toggle()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("UNIT_PET")
f:RegisterEvent("SKILL_LINES_CHANGED")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("CHARACTER_POINTS_CHANGED") -- talent points spent (or respec)
f:RegisterEvent("PLAYER_DEAD") -- hardcore: the path ends — print the epitaph

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        PrestigeClassesCharDB = PrestigeClassesCharDB or {}
        -- Characters from before stats existed: start their record now.
        if PrestigeClassesCharDB.active and not PrestigeClassesCharDB.stats then
            PrestigeClassesCharDB.stats = { chosenAt = time(), breaks = 0 }
        end
        PC.UI.Init()
        PC.UI.InitMinimap()
        PC.Trials.Init()

        SLASH_PRESTIGECLASSES1 = "/pc"
        SLASH_PRESTIGECLASSES2 = "/prestige"
        SlashCmdList["PRESTIGECLASSES"] = handleSlash

    elseif event == "PLAYER_LOGIN" then
        -- Seed compliance state silently, then announce the chosen path.
        PC.Refresh()
        local activeId = PrestigeClassesCharDB.active
        if activeId and PC.ClassById[activeId] then
            print("|cffffd100[Prestige]|r Walking the path of the " ..
                PC.ClassById[activeId].name .. ". |cff999999/pc|r to manage.")
        else
            print("|cffffd100[Prestige]|r Type |cff40ff40/pc|r to choose an enhanced class.")
        end

    elseif event == "PLAYER_DEAD" then
        PC.Alerts.OnDeath()

    elseif event == "UNIT_PET" and arg1 ~= "player" then
        -- ignore other units' pets
    else
        PC.Refresh()
    end
end)
