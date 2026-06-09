local ADDON, PC = ...

-- Re-evaluate the active path and refresh both alerts and UI. Safe to call
-- often; it does nothing expensive when no class is chosen.
function PC.Refresh()
    local activeId = PrestigeClassesCharDB and PrestigeClassesCharDB.active
    local def = activeId and PC.ClassById[activeId] or nil

    if def then
        local results, summary = PC.Compliance.Evaluate(def)
        PC.Alerts.OnEvaluated(def, results, summary)
    else
        PC.Alerts.OnEvaluated(nil)
    end

    if PC.UI and PC.UI.frame and PC.UI.frame:IsShown() then
        PC.UI.Refresh()
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
        " (" .. summary.rulesPassed .. "/" .. summary.rulesTotal .. " rules)")
    for _, r in ipairs(results) do
        if r.kind ~= "info" and not r.ok then
            print("   |cffff4040x|r " .. r.label .. " — " .. (r.detail or ""))
        end
    end
end

local function handleSlash(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "status" then
        printStatus()
    elseif msg == "abandon" then
        PC.UI.Abandon()
    elseif msg == "list" then
        print("|cffffd100[Prestige]|r Available paths:")
        for _, c in ipairs(PC.Classes) do
            print("   " .. c.name .. " |cff999999(" .. c.faction .. ")|r")
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

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        PrestigeClassesCharDB = PrestigeClassesCharDB or {}
        PC.UI.Init()
        PC.UI.InitMinimap()

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

    elseif event == "UNIT_PET" and arg1 ~= "player" then
        -- ignore other units' pets
    else
        PC.Refresh()
    end
end)
