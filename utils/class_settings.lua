local mq = require('mq')

local elheader = "\ay[\agEpic Laziness\ay]"

local class_settings = {}
class_settings.configPath = mq.configDir .. '/epiclaziness/epiclaziness_class_settings.lua'

function class_settings.loadSettings()
    local configData, err = loadfile(class_settings.configPath)
    if err then
        class_settings.createSettings()
    elseif configData then
        class_settings.settings = configData()
    end
end

function class_settings.createSettings()
    class_settings.settings = {
        ['class'] = {
            ['Bard'] = 2,
            ['Beastlord'] = 1,
            ['Berserker'] = 1,
            ['Cleric'] = 1,
            ['Druid'] = 1,
            ['Enchanter'] = 1,
            ['Magician'] = 1,
            ['Monk'] = 1,
            ['Necromancer'] = 1,
            ['Paladin'] = 1,
            ['Ranger'] = 1,
            ['Rogue'] = 1,
            ['Shadow Knight'] = 1,
            ['Shaman'] = 1,
            ['Warrior'] = 1,
            ['Wizard'] = 2
        },
        ['general'] = {
            ['useAOC'] = true,
            ['invisForTravel'] = false,
            ['returnToBind'] = false
        }
    }
    class_settings.saveSettings()
    printf("%s \aocreated default settings. Please set them appropriately for your use.", elheader)
end

function class_settings.saveSettings()
    mq.pickle(class_settings.configPath, class_settings.settings)
end

return class_settings
