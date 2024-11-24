--TODO Check for epiclaziness_class_settings.lua if no common_settings.lua exists and move to new naming

local mq = require("mq")
local logger = require("lib/logger")
local v = require("lib/semver")

---@class Common_Settings
local common_settings = {}
common_settings.settings = {}
common_settings.configPath = mq.configDir .. "/epiclaziness/common_settings.lua"

-- Load the settings file if it exists
function common_settings.loadSettings()
	local configData, err = loadfile(common_settings.configPath)
	if err then
		common_settings.createSettings()
	elseif configData then
		common_settings.settings = configData()
		if common_settings.settings.skill_to_num == nil then
			common_settings.settings.skill_to_num = {
				["Shauri's Sonorous Clouding"] = 231,
				["Natural Invisibility"] = 980,
				["Innate Camouflage"] = 80,
				["Perfected Invisibility"] = 3812,
				["Cloak of Shadows"] = 531,
				["Silent Presence"] = 3730,
			}
			common_settings.saveSettings()
		end
		if common_settings.settings["version"] == nil then
			common_settings.settings["version"] = "0.3.31"
			common_settings.settings["class_invis"]["Necromancer"] = "Cloak of Shadows|Potion|Circlet of Shadows"
			common_settings.settings["class_invis"]["Shadow Knight"] = "Cloak of Shadows|Potion|Circlet of Shadows"
			common_settings.settings["move_speed"] = {
				["Bard"] = "Selo's Sonata|None",
				["Druid"] = "Communion of the Cheetah|Spirit of Eagles|None",
				["Shaman"] = "Communion of the Cheetah|None",
				["Ranger"] = "Spirit of Eagle|None",
			}
			common_settings.settings["speed"] = {
				["Druid"] = 1,
				["Ranger"] = 1,
				["Shaman"] = 1,
				["Bard"] = 1,
			}
			common_settings.settings["speed_to_num"] = {
				["Spirit of Eagles(Druid)"] = 8601,
				["Spirit of Eagle(Ranger)"] = 8600,
				["Communion of the Cheetah"] = 939,
				["Selo's Sonata"] = 3704,
			}
			common_settings.saveSettings()
		end
		if common_settings.settings["version"] == "0.1.5" then
			common_settings.settings["version"] = "0.3.31"
			common_settings.settings["move_speed"]["Ranger"] = "Spirit of Eagle|None"
			common_settings.settings["speed_to_num"]["Spirit of Eagle(Ranger)"] = 8600
			common_settings.settings["speed_to_num"]["Spirit of Eagles(Ranger)"] = nil
		end
	end
	if common_settings.settings["speed_to_num"] == nil then
		common_settings.settings["speed_to_num"] = {
			["Spirit of Eagles(Druid)"] = 8601,
			["Spirit of Eagles(Ranger)"] = 8600,
			["Communion of the Cheetah"] = 939,
			["Selo's Sonata"] = 3704,
		}
		common_settings.saveSettings()
	end
	if common_settings.settings["speed"] == nil then
		common_settings.settings["speed"] = {
			["Druid"] = 1,
			["Ranger"] = 1,
			["Shaman"] = 1,
			["Bard"] = 1,
		}
		common_settings.saveSettings()
	end
end

function common_settings.version_check(version)
	local temp_semver
	if type(common_settings.settings["version"]) == "string" then
		temp_semver = v(common_settings.settings["version"])
	else
		temp_semver = common_settings.settings["version"]
	end
	if common_settings.semver_less_than(temp_semver, v("0.4.3")) then
		common_settings.settings["group_invis"] = {
			["Bard"] = "Shauri's Sonorous Clouding",
			["Druid"] = "Shared Camouflage",
			["Enchanter"] = "Group Perfected Invisibility",
			["Magician"] = "Group Perfected Invisibility",
			["Ranger"] = "Shared Camouflage",
			["Shaman"] = "Group Silent Presence",
			["Wizard"] = "Group Perfected Invisibility",
		}
		common_settings.settings["group_invis_to_num"] = {
			["Shauri's Sonorous Clouding"] = 231,
			["Shared Camouflage"] = 518,
			["Group Perfected Invisibility"] = 1210,
			["Group Silent Presence"] = 630,
		}
		logger.log_debug("\aoUpdating general configuration to \ag%s\ao.", version)
		common_settings.settings["version"] = version
		common_settings.saveSettings()
	end
end

function common_settings.semver_less_than(a, b)
	if a.major ~= b.major then
		return a.major < b.major
	end
	if a.minor ~= b.minor then
		return a.minor < b.minor
	end
	if a.patch ~= b.patch then
		return a.patch < b.patch
	end
	return false
end

-- Create default settings
function common_settings.createSettings()
	---@class Common_Settings_Settings
	common_settings.settings = {
		["version"] = v("0.4.3"),
		["class"] = {
			["Bard"] = 1,
			["Beastlord"] = 1,
			["Berserker"] = 1,
			["Cleric"] = 1,
			["Druid"] = 1,
			["Enchanter"] = 1,
			["Magician"] = 1,
			["Monk"] = 1,
			["Necromancer"] = 1,
			["Paladin"] = 1,
			["Ranger"] = 1,
			["Rogue"] = 1,
			["Shadow Knight"] = 1,
			["Shaman"] = 1,
			["Warrior"] = 1,
			["Wizard"] = 2,
		},
		["general"] = {
			["returnToBind"] = false,
			["useAOC"] = true,
			["invisForTravel"] = true,
			["stopTS"] = true,
		},
		["invis"] = {
			["Bard"] = 1,
			["Beastlord"] = 1,
			["Berserker"] = 1,
			["Cleric"] = 1,
			["Druid"] = 1,
			["Enchanter"] = 1,
			["Magician"] = 1,
			["Monk"] = 1,
			["Necromancer"] = 1,
			["Paladin"] = 1,
			["Ranger"] = 1,
			["Rogue"] = 1,
			["Shadow Knight"] = 1,
			["Shaman"] = 1,
			["Warrior"] = 1,
			["Wizard"] = 1,
		},
		["class_invis"] = {
			["Bard"] = "Shauri's Sonorous Clouding|Potion",
			["Beastlord"] = "Natural Invisibility|Potion",
			["Berserker"] = "Potion",
			["Cleric"] = "Potion",
			["Druid"] = "Innate Camouflage|Potion",
			["Enchanter"] = "Perfected Invisibility|Potion",
			["Magician"] = "Perfected Invisibility|Potion",
			["Monk"] = "Potion",
			["Necromancer"] = "Cloak of Shadows|Potion|Circlet of Shadows",
			["Paladin"] = "Potion",
			["Ranger"] = "Innate Camouflage|Potion",
			["Rogue"] = "Hide/Sneak|Potion",
			["Shadow Knight"] = "Cloak of Shadows|Potion|Circlet of Shadows",
			["Shaman"] = "Silent Presence|Potion",
			["Warrior"] = "Potion",
			["Wizard"] = "Perfected Invisibility|Potion",
		},
		["skill_to_num"] = {
			["Shauri's Sonorous Clouding"] = 231,
			["Natural Invisibility"] = 980,
			["Innate Camouflage"] = 80,
			["Perfected Invisibility"] = 3812,
			["Cloak of Shadows"] = 531,
			["Silent Presence"] = 3730,
		},
		["group_invis"] = {
			["Bard"] = "Shauri's Sonorous Clouding",
			["Druid"] = "Shared Camouflage",
			["Enchanter"] = "Group Perfected Invisibility",
			["Magician"] = "Group Perfected Invisibility",
			["Ranger"] = "Shared Camouflage",
			["Shaman"] = "Group Silent Presence",
			["Wizard"] = "Group Perfected Invisibility",
		},
		["group_invis_to_num"] = {
			["Shauri's Sonorous Clouding"] = 231,
			["Shared Camouflage"] = 518,
			["Group Perfected Invisibility"] = 1210,
			["Group Silent Presence"] = 630,
		},
		["move_speed"] = {
			["Bard"] = "Selo's Sonata",
			["Druid"] = "Communion of the Cheetah|Spirit of Eagles",
			["Shaman"] = "Communion of the Cheetah",
			["Ranger"] = "Spirit of Eagle",
		},
		["speed"] = {
			["Druid"] = 1,
			["Ranger"] = 1,
			["Shaman"] = 1,
			["Bard"] = 1,
		},
		["speed_to_num"] = {
			["Spirit of Eagles(Druid)"] = 8601,
			["Spirit of Eagle(Ranger)"] = 8600,
			["Communion of the Cheetah"] = 939,
			["Selo's Sonata"] = 3704,
		},
		["LoadTheme"] = "Default",
		["logger"] = {
			["LogLevel"] = 3,
			["LogToFile"] = false,
		},
	}
	common_settings.saveSettings()
	logger.log_warn("\aoCreated default settings. Please set them appropriately for your use.")
end

--Save Settings
function common_settings.saveSettings()
	logger.log_info("\aoGeneral settings saved.")
	mq.pickle(common_settings.configPath, common_settings.settings)
end

return common_settings
