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
        },
        ['invis'] = {
            ['Bard'] = 1,
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
            ['Wizard'] = 1
        },
        ['class_invis'] = {
            ['Bard'] = "Shauri's Sonorous Clouding|Potion",
            ['Beastlord'] = "Natural Invisibility|Potion",
            ['Berserker'] = "Potion",
            ['Cleric'] = "Potion",
            ['Druid'] = "Innate Camouflage|Potion",
            ['Enchanter'] = "Perfected Invisibility|Potion",
            ['Magician'] = "Perfected Invisibility|Potion",
            ['Monk'] = "Potion",
            ['Necromancer'] = "Cloak of Shadows|Potion",
            ['Paladin'] = "Potion",
            ['Ranger'] = "Innate Camouflage|Potion",
            ['Rogue'] = "Hide/Sneak|Potion",
            ['Shadow Knight'] = "Cloak of Shadows|Potion",
            ['Shaman'] = "Silent Presence|Potion",
            ['Warrior'] = "Potion",
            ['Wizard'] = "Perfected Invisibility|Potion"
        },
        ['skill_to_num'] = {
            ["Shauri's Sonorous Clouding"] = 231,
            ['Natural Invisibility'] = 980,
            ['Innate Camouflage'] = 80,
            ['Perfected Invisibility'] = 3812,
            ['Cloak of Shadows'] = 531,
            ['Silent Presence'] = 3730
        }
    }
    class_settings.saveSettings()
    printf("%s \aocreated default settings. Please set them appropriately for your use.", elheader)
end

function class_settings.saveSettings()
    printf("%s \aoSettings saved.", elheader)
    mq.pickle(class_settings.configPath, class_settings.settings)
end

return class_settings
