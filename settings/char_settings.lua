local mq = require("mq")
local logger = require("lib/logger")
local v = require("lib/semver")

---@class Char_Settings
local char_settings = {}
char_settings.SaveState = {}
local myName = mq.TLO.Me.DisplayName()
char_settings.configPath = mq.configDir
	.. "/epiclaziness/epiclaziness_"
	.. mq.TLO.EverQuest.Server()
	.. "_"
	.. myName
	.. ".lua"
local class = mq.TLO.Me.Class.Name()

-- Create the character settings file if it does not exist
function char_settings.createConfig()
	---@class Char_Settings_SaveState
	char_settings.SaveState = {
		["class"] = {
			[_G.State.epic_choice] = {
				["Step"] = 0,
			},
			["Last_Ran"] = 1,
		},
		["general"] = {
			["stopTS"] = true,
			["useAOC"] = true,
			["invisForTravel"] = false,
			["returnToBind"] = false,
			["xtargClear"] = 1,
			["useGatePot"] = false,
			["useOrigin"] = false,
			["useGroupInvis"] = false,
		},
	}
	char_settings.saveState()
end

-- Add configuration settings if user is on a new character (or class in case of personas)
function char_settings.addConfig()
	if char_settings.SaveState[class] == nil then
		char_settings.SaveState[class] = {
			[_G.State.epic_choice] = {
				["Step"] = 0,
			},
			["Last_Ran"] = 1,
		}
	end
	char_settings.SaveState[class][_G.State.epic_choice] = {
		["Step"] = 0,
	}
	char_settings.saveState()
end

-- Load the saved character settings
function char_settings.loadState()
	local configData, err = loadfile(char_settings.configPath)
	if err then
		char_settings.createConfig()
	elseif configData then
		char_settings.SaveState = configData()
		if char_settings.SaveState[class] ~= nil then
			if char_settings.SaveState[class][_G.State.epic_choice] ~= nil then
				if char_settings.SaveState[class].Last_Ran == nil then
					char_settings.SaveState[class].Last_Ran = 1
				end
				if _G.State:readTaskRunning() == false then
					_G.State.epic_choice = char_settings.SaveState[class].Last_Ran
				else
					_G.State.current_step = char_settings.SaveState[class][_G.State.epic_choice].Step or 0
					logger.log_info("\aoStarting on step: \ar%s\ao.", _G.State.current_step)
				end
			else
				char_settings.addConfig()
			end
		else
			char_settings.addConfig()
		end
		if char_settings.SaveState.general ~= nil then
			if char_settings.SaveState.general.xtargClear == nil then
				char_settings.SaveState.general.xtargClear = 1
			end
			if char_settings.SaveState.general.useGatePot == nil then
				char_settings.SaveState.general.useGatePot = false
			end
			if char_settings.SaveState.general.useOrigin == nil then
				char_settings.SaveState.general.useOrigin = false
			end
		end
	end
end

-- Prepare to save the current step
function char_settings.prepSave(step)
	char_settings.SaveState[class][_G.State.epic_choice].Step = step
	char_settings.SaveState[class].Last_Ran = _G.State.epic_choice
	char_settings.saveState()
end

-- Save settings
function char_settings.saveState()
	logger.log_info("\aoSaving character settings.")
	mq.pickle(char_settings.configPath, char_settings.SaveState)
end

function char_settings.versionCheck(version)
	local temp_semver
	if type(char_settings.SaveState["version"]) == "string" then
		temp_semver = v(char_settings.SaveState["version"])
	else
		temp_semver = char_settings.SaveState["version"]
	end
	if char_settings.semver_less_than(temp_semver, v("0.4.3")) then
		logger.log_debug("\aoUpdating character configuration to \ag%s\ao.", version)
		char_settings.SaveState["general"]["useGroupInvis"] = false
		char_settings.SaveState["version"] = version
		char_settings.saveState()
	end
end

function char_settings.semver_less_than(a, b)
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

return char_settings
