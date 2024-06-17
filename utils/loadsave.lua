local mq            = require('mq')
local logger        = require('utils/logger')

---@class Char_Settings
local loadsave      = {}
loadsave.SaveState  = {}
local myName        = mq.TLO.Me.DisplayName()
loadsave.configPath = mq.configDir .. '/epiclaziness/epiclaziness_' .. mq.TLO.EverQuest.Server() .. "_" .. myName .. '.lua'
local class         = mq.TLO.Me.Class.Name()

-- Create the character settings file if it does not exist
function loadsave.createConfig()
    ---@class Char_Settings_SaveState
    loadsave.SaveState = {
        ['class'] = {
            [_G.State.epic_choice] = {
                ['Step'] = 0
            },
            ['Last_Ran'] = 1
        },
        ['general'] = {
            ['stopTS']         = true,
            ['useAOC']         = true,
            ['invisForTravel'] = false,
            ['returnToBind']   = false,
            ['xtargClear']     = 1
        }
    }
    loadsave.saveState()
end

-- Add configuration settings if user is on a new character (or class in case of personas)
function loadsave.addConfig()
    if loadsave.SaveState[class] == nil then
        loadsave.SaveState[class] = {
            [_G.State.epic_choice] = {
                ['Step'] = 0
            },
            ['Last_Ran'] = 1
        }
    end
    loadsave.SaveState[class][_G.State.epic_choice] = {
        ['Step'] = 0
    }
    loadsave.saveState()
end

-- Load the saved character settings
function loadsave.loadState()
    local configData, err = loadfile(loadsave.configPath)
    if err then
        loadsave.createConfig()
    elseif configData then
        loadsave.SaveState = configData()
        if loadsave.SaveState[class] ~= nil then
            if loadsave.SaveState[class][_G.State.epic_choice] ~= nil then
                if loadsave.SaveState[class].Last_Ran == nil then
                    loadsave.SaveState[class].Last_Ran = 1
                end
                if _G.State:readTaskRunning() == false then
                    _G.State.epic_choice = loadsave.SaveState[class].Last_Ran
                else
                    _G.State.current_step = loadsave.SaveState[class][_G.State.epic_choice].Step or 0
                    logger.log_info("\aoStarting on step: \ar%s\ao.", _G.State.current_step)
                end
            else
                loadsave.addConfig()
            end
        else
            loadsave.addConfig()
        end
        if loadsave.SaveState.general ~= nil then
            if loadsave.SaveState.general.xtargClear == nil then
                loadsave.SaveState.general.xtargClear = 1
            end
            if loadsave.SaveState.general.useGatePot == nil then
                loadsave.SaveState.general.useGatePot = false
            end
            if loadsave.SaveState.general.useOrigin == nil then
                loadsave.SaveState.general.useOrigin = false
            end
        end
    end
end

-- Prepare to save the current step
function loadsave.prepSave(step)
    loadsave.SaveState[class][_G.State.epic_choice].Step = step
    loadsave.SaveState[class].Last_Ran = _G.State.epic_choice
    loadsave.saveState()
end

-- Save settings
function loadsave.saveState()
    logger.log_info("\aoSaving character settings.")
    mq.pickle(loadsave.configPath, loadsave.SaveState)
end

return loadsave
