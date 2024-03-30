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
            },
            ['Last_Ran'] = 1
        }
    }
    loadsave.saveState()
end

function loadsave.addConfig()
    loadsave.SaveState[class][State.epic_choice] = {
        ['Step'] = 0
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
                if State.task_run == false then
                    State.epic_choice = loadsave.SaveState[class]['Last_Ran']
                end
                State.step = loadsave.SaveState[class][State.epic_choice].Step
                printf("%s \aoStarting on step %s", elheader, State.step)
            else
                loadsave.addConfig()
            end
        else
            loadsave.addConfig()
        end
    end
end

function loadsave.prepSave(step)
    loadsave.SaveState[class][State.epic_choice].Step = step
    loadsave.SaveState[class]['Last_Ran'] = State.epic_choice
    loadsave.saveState()
end

function loadsave.saveState()
    mq.pickle(loadsave.configPath, loadsave.SaveState)
end

return loadsave
