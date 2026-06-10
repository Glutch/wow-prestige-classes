local ADDON, PC = ...

PC.Alerts = {}
local A = PC.Alerts

local PREFIX = "|cffff2020[Prestige]|r "
local GOOD = "|cff20ff20[Prestige]|r "

-- Remember the last compliance state so we only shout on transitions
-- (broke a rule / restored a rule) instead of spamming every gear scan.
local lastBrokenCount

-- ------------------------------------------------------------------------
-- Screen vignette flash: red for a broken vow, gold for glory
-- ------------------------------------------------------------------------
local flash
local function flashScreen(r, g, b)
    if not flash then
        flash = CreateFrame("Frame", nil, UIParent)
        flash:SetAllPoints(UIParent)
        flash:SetFrameStrata("FULLSCREEN_DIALOG")
        flash:EnableMouse(false)

        local tex = flash:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        flash.tex = tex

        local anim = flash:CreateAnimationGroup()
        local fade = anim:CreateAnimation("Alpha")
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0)
        fade:SetDuration(0.9)
        fade:SetSmoothing("OUT")
        anim:SetScript("OnFinished", function() flash:Hide() end)
        flash.anim = anim
        flash:Hide()
    end
    flash.tex:SetColorTexture(r or 0.7, g or 0, b or 0, 0.35)
    flash.anim:Stop()
    flash:SetAlpha(1)
    flash:Show()
    flash.anim:Play()
end

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
        -- A vow was just broken — flash, cry out and name what's wrong.
        for _, r in ipairs(results) do
            if r.kind == "rule" and not r.ok then
                UIErrorsFrame:AddMessage("Prestige broken: " .. r.label, 1.0, 0.1, 0.1, 1.0)
            end
        end
        print(PREFIX .. (def.breakCry or ("You have broken the way of the " .. def.name .. "!")))
        flashScreen()
        PlaySound(8959, "Master") -- RaidWarning sound

        local stats = PrestigeClassesCharDB and PrestigeClassesCharDB.stats
        if stats then
            stats.breaks = (stats.breaks or 0) + 1
            stats.lastBreakAt = time()
        end
    elseif broken == 0 and lastBrokenCount > 0 then
        print(GOOD .. (def.restoreCry or ("You once again walk the path of the " .. def.name .. ".")))
        PlaySound(8960, "Master") -- RaidWarning end
    end

    lastBrokenCount = broken
end

function A.Reset()
    lastBrokenCount = nil
end

-- ------------------------------------------------------------------------
-- Trial ceremonies: the joyful mirror of the break alert
-- ------------------------------------------------------------------------
function A.TrialComplete(def, trial, honorific, milestoneCount)
    if milestoneCount then
        print(GOOD .. "Deed of renown — " .. trial.name ..
            " (" .. milestoneCount .. ").")
    else
        print(GOOD .. "Trial complete: " .. trial.name .. ".")
    end
    if honorific then
        print(GOOD .. "Henceforth you are |cffffd100" .. honorific .. "|r.")
    end
    if trial.completionNote then
        print("|cff999999" .. trial.completionNote .. "|r")
    end
    UIErrorsFrame:AddMessage(
        honorific and (trial.name .. " — " .. honorific)
            or ("Trial complete: " .. trial.name),
        1.0, 0.85, 0.1, 1.0)
    flashScreen(0.9, 0.75, 0)
    PlaySound(888, "Master") -- level-up fanfare
end

function A.RankUp(def, title)
    print(GOOD .. "The path acknowledges you. Rise, " .. title ..
        " of the " .. def.name .. "!")
    UIErrorsFrame:AddMessage("Rise, " .. title .. " of the " .. def.name .. "!",
        1.0, 0.85, 0.1, 1.0)
    flashScreen(0.9, 0.75, 0)
    PlaySound(8959, "Master")
end

-- ------------------------------------------------------------------------
-- Death epitaph: on Hardcore, a death is the end of the story — write it.
-- ------------------------------------------------------------------------
local function pathDuration(chosenAt)
    if not chosenAt then return "an unknown time" end
    local days = math.floor((time() - chosenAt) / 86400)
    if days <= 0 then return "less than a day"
    elseif days == 1 then return "1 day"
    else return days .. " days" end
end

function A.OnDeath()
    local db = PrestigeClassesCharDB
    local def = db and db.active and PC.ClassById[db.active]
    if not def then return end

    local s = db.stats or {}
    local level = UnitLevel("player")
    local rank = PC.Trials and select(2, PC.Trials.RankInfo(def))
        or PC.Util.RankTitle(level)
    local GREY, GOLD, R = "|cff999999", "|cffffd100", "|r"

    print(GREY .. "------------------------------------------" .. R)
    print(GOLD .. "Here fell " .. UnitName("player") .. ", " .. rank ..
        " of the " .. def.name .. "." .. R)
    print(GREY .. "Level " .. level .. ". Walked the path for " ..
        pathDuration(s.chosenAt) .. "." .. R)
    local breaks = s.breaks or 0
    if breaks == 0 then
        print("|cff20ff20Every vow honored to the end. Died with honor." .. R)
    else
        print("|cffff2020Vows broken " .. breaks .. " time" ..
            (breaks == 1 and "" or "s") .. " along the way." .. R)
    end
    if def.trials and PC.Trials then
        local done, total = PC.Trials.Counts(def)
        print(GREY .. done .. " of " .. total .. " deeds of the path done." .. R)
        local honorifics = PC.Trials.Honorifics(def)
        if #honorifics > 0 then
            print(GOLD .. "Titles earned: " ..
                table.concat(honorifics, ", ") .. "." .. R)
        end
        for _, trial in ipairs(def.trials) do
            if trial.epitaph then
                local ts = PC.Trials.State(trial.id)
                if ts and (ts.progress or 0) > 0 then
                    print(GREY .. trial.epitaph:format(ts.progress) .. R)
                end
            end
        end
    end
    print(GREY .. "------------------------------------------" .. R)
end
