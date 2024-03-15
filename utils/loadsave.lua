local mq = require('mq')

local loadsave = {}
loadsave.SaveState = {}
local myName = mq.TLO.Me.DisplayName()
loadsave.configPath = mq.configDir ..
'/epiclaziness/epiclaziness_' .. mq.TLO.EverQuest.Server() .. "_" .. myName .. '.lua'
local class = mq.TLO.Me.Class.Name()
local elheader = "\ay[\agEpic Laziness\ay]"


function loadsave.createConfig()
    loadsave.SaveState = {
        [class] = {
            [State.epic_choice] = {
                ['Step'] = 0
            }
        }
    }
    loadsave.saveState()
end

function loadsave.loadState()
    local configData, err = loadfile(loadsave.configPath)
    if err then
        loadsave.createConfig()
    elseif configData then
        loadsave.SaveState = configData()
        if loadsave.SaveState[class] ~= nil then
            if loadsave.SaveState[class][State.epic_choice] ~= nil then
                State.step = loadsave.SaveState[class][State.epic_choice].Step
                printf("%s \aoStarting on step %s", elheader, State.step)
            end
        end
    end
end

function loadsave.prepSave(step)
    loadsave.SaveState[class][State.epic_choice].Step = step
    loadsave.saveState()
end

function loadsave.saveState()
    mq.pickle(loadsave.configPath, loadsave.SaveState)
end

return loadsave
