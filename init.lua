--[[
Adding line for testing-----
FIXME: Ranger 2.0 Step 73 Craftmaster Tieranu determine if npc will spawn if trigger spawns while you are in the room already.
* In progress -- Can not trigger NPC unless on that step, hooray.

* Berserker (3), Wizard (3), Druid (3), Enchanter (3), Necromancer (3), Monk (2)
? meshes:
--]]
local mq = require("mq")
local ImGui = require("ImGui")
local logger = require("lib/logger")
_G.State = require("lib/state")
_G.Common = require("utils/common_func")
_G.Actions = require("utils/actions")
_G.Mob = require("utils/mob")
--local dist               = require 'utils/distance'
--local inv                 = require 'utils/inventory'
--local travel             = require 'utils/travel'
local class_definitions = require("types/class_definitions")
local draw_gui = require("utils/drawgui")
local manage = require("utils/manageautomation")
local loadsave = require("utils/loadsave")
local class_settings = require("utils/class_settings")
local quests_done = require("data/questsdone")
local reqs = require("data/questrequirements")
local tsreqs = require("data/tradeskillreqs")
local v = require("lib/semver")
local LoadTheme = require("theme/theme_loader")
local PackageMan = require("mq/PackageMan")
local sqlite3 = PackageMan.Require("lsqlite3")
--local http = PackageMan.Require("luasocket", "socket.http")
--local ssl = PackageMan.Require("luasec", "ssl")

--local version_url = "https://raw.githubusercontent.com/yb-f/EL-Ver/master/latest_ver"
local version = v("0.4.15")
local window_flags = bit32.bor(ImGuiWindowFlags.None)
local openGUI, drawGUI = true, true
local myName = mq.TLO.Me.DisplayName()
local dbn = sqlite3.open(mq.luaDir .. "\\epiclaziness\\epiclaziness.db")
local plugins = { "MQ2Nav", "MQ2EasyFind", "MQ2Relocate", "MQ2PortalSetter", "MQ2Autosize" }
local exclude_list = {}
local exclude_name = ""
local themeFile = string.format("%s/MyThemeZ.lua", mq.configDir)
local themeName = "Default"
local themeID = 5
local theme = {}
local FIRST_WINDOW_WIDTH = 415
local FIRST_WINDOW_HEIGHT = 475
local class_name_table = {
	["Bard"] = "brd",
	["Beastlord"] = "bst",
	["Berserker"] = "ber",
	["Cleric"] = "clr",
	["Druid"] = "dru",
	["Enchanter"] = "enc",
	["Magician"] = "mag",
	["Monk"] = "mnk",
	["Necromancer"] = "nec",
	["Paladin"] = "pal",
	["Ranger"] = "rng",
	["Rogue"] = "rog",
	["Shadow Knight"] = "shd",
	["Shaman"] = "shm",
	["Warrior"] = "war",
	["Wizard"] = "wiz",
}

-- Check if a file exist
--- @param name string
local function File_Exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

--Load the theme file
local function loadTheme()
	if File_Exists(themeFile) then
		theme = dofile(themeFile)
	else
		theme = require("theme/themes") -- your local themes file incase the user doesn't have one in config folder
	end
	if not themeName then
		themeName = theme.LoadTheme or "Default"
	end
	if theme and theme.Theme then
		for tID, tData in pairs(theme.Theme) do
			if tData["Name"] == themeName then
				themeID = tID
			end
		end
	end
end

-- Spawn filtering predicate
--- @param spawn spawn
--- @return boolean
local function matchFilters(spawn)
	if string.match(string.lower(spawn.CleanName()), string.lower(exclude_name)) then
		return true
	end
	return false
end

-- Create a list of spawns and add them to the list of excluded spawns.
function create_spawn_list()
	exclude_list = mq.getFilteredSpawns(matchFilters)
	for _, spawn in ipairs(exclude_list) do
		logger.log_verbose("\aoInserting bad ID for: \ar%s \ao(\ar%s\ao).", spawn.DisplayName(), spawn.ID())
		table.insert(_G.State.bad_IDs, spawn.ID())
	end
end

local hashCheck = require("utils/hashcheck")
_G.Task_Functions = require("utils/task_functions")

class_settings.loadSettings()
loadsave.loadState()
if not class_settings.settings.LoadTheme then           --whatever your setting is saved as
	class_settings.settings["LoadTheme"] = theme.LoadTheme -- load the theme tables default if not set.
	class_settings.saveSettings()
end
if loadsave.SaveState["version"] == nil then
	loadsave.SaveState["version"] = version
	loadsave.saveState()
end

themeName = class_settings.settings.LoadTheme
loadTheme()

if class_settings.settings["logger"] == nil then
	class_settings.settings["logger"] = {
		["LogLevel"] = 3,
		["LogToFile"] = false,
	}
	class_settings.saveSettings()
end

logger.set_log_level(class_settings.settings.logger.LogLevel)
logger.set_log_to_file(class_settings.settings.logger.LogToFile)

if loadsave.SaveState["general"] == nil then
	loadsave.SaveState["general"] = {
		["useAOC"] = class_settings.settings.general.useAOC,
		["invisForTravel"] = class_settings.settings.general.invisForTravel,
		["stopTS"] = class_settings.settings.general.stopTS,
		["returnToBind"] = class_settings.settings.general.returnToBind,
		["xtargClear"] = 1,
	}
	loadsave.saveState()
end
if loadsave.SaveState.general["speedForTravel"] == nil then
	loadsave.SaveState.general["speedForTravel"] = true
	loadsave.saveState()
end

-- Populate the values of the group combo box. (None, Group, and all members of group currently in zone)

-- Check the tradeskills of the player against the requirements for the selected epic return true if they meet the requirements, false if they do not.
--- @param class string
--- @param choice number
--- @return boolean|string
local function check_tradeskills(class, choice)
	if tsreqs[class] ~= nil then
		local quest = ""
		local quests = {
			["1.0"] = "10",
			["Pre-1.5"] = "pre15",
			["1.5"] = "15",
			["2.0"] = "20",
		}
		quest = quests[_G.State.epic_list[choice]]
		if tsreqs[class][quest] ~= nil then
			local return_string = ""
			for ts, req in pairs(tsreqs[class][quest]) do
				if ts == "Elder Elvish" then
					if mq.TLO.Me.LanguageSkill(ts)() < req then
						return_string = return_string
							.. " \ag"
							.. ts
							.. " \aorequires \ar"
							.. req
							.. " \aoskill. Currently \ar"
							.. mq.TLO.Me.LanguageSkill(ts)()
							.. "\ao."
					end
				else
					if mq.TLO.Me.Skill(ts)() < req then
						return_string = return_string
							.. " \ag"
							.. ts
							.. " \aorequires \ar"
							.. req
							.. " \aoskill. Currently \ar"
							.. mq.TLO.Me.Skill(ts)()
							.. "\ao."
					end
				end
			end
			if return_string == "" then
				return false
			else
				return return_string
			end
		end
	end
	return false
end

-- Update the status two text in the gui when we change steps
local function update_general_status()
	for i = 1, #task_outline_table do
		if task_outline_table[i].Step == _G.State.current_step then
			_G.State:setStatusTwoText(task_outline_table[i].Description)
		end
	end
end

-- Execute the provided task. Grab the function and parameters from the task_functions.lua file and execute it.
--- @param task Item
local function execute_task(task)
	local task_type = task.type
	local task_info = _G.Task_Functions[task_type]
	if task_info then
		local func = task_info.func
		local params = task_info.params
		if func then
			if type(params) == "function" then
				params = params()
			end
			---@diagnostic disable-next-line: param-type-mismatch
			func(task, unpack(params))
		else
			if task_type == "" then
				type = "none"
			end
			logger.log_error("\aoUnknown Type: \ar%s!", type)
			_G.State:setStatusText("Unknown type: %s -- Step: %s", task_type, _G.State.current_step)
			_G.State:setTaskRunning(false)
			return
		end
	end
end

-- Initialize the selected quest. Load the steps from DB and check tradeskill requirements are met.
--- @param class string
--- @param choice number
local function init_epic(class, choice)
	task_table = {}
	local tablename = ""
	_G.State:setTaskRunning(true)
	_G.State:setPaused(false)
	loadsave.loadState()
	draw_gui.jumpStep = _G.State.current_step
	draw_gui.dev.save_step = _G.State.current_step
	if draw_gui.dev["dev_on"] == true then
		logger.log_info(
			"Begining quest for %s epic %s",
			draw_gui.class_list[draw_gui.dev["force_class"]],
			_G.State.epic_list[choice]
		)
		class = class_name_table[draw_gui.class_list[draw_gui.dev["force_class"]]]
	else
		logger.log_info("Begining quest for %s epic %s", mq.TLO.Me.Class(), _G.State.epic_list[choice])
	end
	local epic_list = {
		["1.0"] = class .. "_10",
		["Pre-1.5"] = class .. "_pre15",
		["1.5"] = class .. "_15",
		["2.0"] = class .. "_20",
	}
	if epic_list[_G.State.epic_list[choice]] then
		tablename = epic_list[_G.State.epic_list[choice]]
		_G.State.epicstring = _G.State.epic_list[choice]
	else
		logger.log_error("\aoThis class and quest has not yet been implemented.")
		_G.State:setTaskRunning(false)
		return
	end
	local ts_return = check_tradeskills(class, choice)
	if ts_return then
		if loadsave.SaveState.general.stopTS == true then
			logger.log_error(
				'\aoPlease raise your tradeskills to continue, or turn off the "\agStop if tradeskill requirements are unmet\ao" setting.'
			)
			logger.log_error(ts_return)
			_G.State:setTaskRunning(false)
			return
		else
			logger.log_warn(
				"\aoYour tradeskills do not meet requirements for this quest but you have opted to start the quest anyways."
			)
		end
	end
	local sql = "SELECT * FROM " .. tablename
	for a in dbn:nrows(sql) do
		table.insert(task_table, a)
	end
	manage.startGroup(class_settings.settings, loadsave.SaveState)
	mq.delay("5s")
	manage.pauseGroup(class_settings.settings)
end

-- Run the selected quest. Loop through the steps and execute them until we reach the final step.
-- Loop checks for paused state, task running state, if the player is in game, if auto attack is on, and if we should remove levitate.
local function run_epic()
	while _G.State.current_step < #task_table do
		if _G.State.overview_steps[_G.State.current_step] ~= nil then
			if _G.State.overview_steps[_G.State.current_step] == 1 then
				logger.log_warn(
					"\aoYou have selected to complete this step (\ag%s\ao) manually. Stopping script.",
					_G.State.current_step
				)
				mq.cmdf("/autosize sizeself %s", loadsave.SaveState.general["self_size"])
				mq.cmd("/afollow off")
				mq.cmd("/nav stop")
				mq.cmd("/stick off")
				_G.State:setTaskRunning(false)
				return
			elseif _G.State.overview_steps[_G.State.current_step] == 2 then
				logger.log_warn(
					"\aoYou have selected to skip this step (\ag%s\ao). Moving to next step.",
					_G.State.current_step
				)
				for i, item in pairs(task_outline_table) do
					if item.Step == _G.State.current_step then
						_G.State:handle_step_change(task_outline_table[i + 1].Step)
						break
					end
				end
			end
		end
		if mq.TLO.EverQuest.GameState() ~= "INGAME" then
			logger.log_error("\arNot in game, closing.")
			mq.exit()
		end
		_G.State.cannot_count = 0
		while _G.State:readPaused() do
			_G.State:setStatusText("Paused")
			mq.delay(500)
			if mq.TLO.EverQuest.GameState() ~= "INGAME" then
				logger.log_error("\arNot in game, closing.")
				mq.exit()
			end
			if _G.State:readTaskRunning() == false then
				_G.State:setPaused(false)
				return
			end
		end
		_G.State.should_skip = false
		if _G.State.is_rewound == false then
			_G.State.current_step = _G.State.current_step + 1
		else
			_G.State.is_rewound = false
		end
		if mq.TLO.Me.Combat() == true then
			mq.cmd("/attack off")
		end
		update_general_status()
		mq.doevents()
		if task_table[_G.State.current_step].xtarget_ignore ~= nil then
			_G.State:setXtargIgnore(task_table[_G.State.current_step].xtarget_ignore)
		elseif task_table[_G.State.current_step].xtarget_ignore == nil and _G.State:readXtargIgnore() ~= nil then
			_G.State:clearXtargIgnore()
		end
		execute_task(task_table[_G.State.current_step])
		if mq.TLO.Me.Levitating() then
			if task_table[_G.State.current_step].belev == nil then
				manage.removeLev()
			end
		end
		if task_table[_G.State.current_step].SaveStep == 1 then
			if _G.State:readTaskRunning() then
				logger.log_info("\aoSaving step: \ar%s", _G.State.current_step)
				loadsave.prepSave(_G.State.current_step)
				if _G.State:readStopAtSave() then
					logger.log_warn("\aoStopping at step \ar%s.", _G.State.current_step)
					_G.State.epicstring = ""
					_G.State:setTaskRunning(false)
					_G.State:setStopAtSave(false)
					_G.State:setStatusText("Stopped at step %s", _G.State.current_step)
					return
				end
			end
		end
		if _G.State:readTaskRunning() == false then
			mq.cmdf("/autosize sizeself %s", loadsave.SaveState.general["self_size"])
			mq.cmd("/afollow off")
			mq.cmd("/nav stop")
			mq.cmd("/stick off")
			return
		end
	end
	_G.State:setStatusText("Completed %s: %s", mq.TLO.Me.Class(), _G.State.epicstring)
	logger.log_info("\aoCompleted \ay%s \ao- \ar%s!", mq.TLO.Me.Class(), _G.State.epicstring)
	_G.State.epicstring = ""
	_G.State:setTaskRunning(false)
end

-- Display the ImGui window
local function displayGUI()
	if not openGUI then
		_G.State.running = false
		mq.exit()
		return
	end
	if logger.LogConsole == nil then
		logger.LogConsole = ImGui.ConsoleWidget.new("##ELConsole")
		logger.LogConsole.maxBufferLines = 100
		logger.LogConsole.autoScroll = true
	end
	ImGui.SetNextWindowSize(ImVec2(FIRST_WINDOW_WIDTH, FIRST_WINDOW_HEIGHT), ImGuiCond.FirstUseEver)
	local ColorCount, StyleCount = LoadTheme.StartTheme(theme.Theme[themeID])
	openGUI, drawGUI = ImGui.Begin("Epic Laziness##" .. myName, openGUI, window_flags)
	if drawGUI then
		draw_gui.header()
		ImGui.BeginTabBar("##Tabs")
		draw_gui.generalTab(task_table)
		theme.LoadTheme, themeName, themeID, class_settings.settings["LoadTheme"] =
			draw_gui.settingsTab(themeName, theme, themeID, class_settings, loadsave)
		draw_gui.outlineTab(task_outline_table, _G.State.overview_steps, task_table)
		if _G.State:readTaskRunning() then
			draw_gui.fullOutlineTab(task_table)
		end
		draw_gui.consoleTab(class_settings)
		if draw_gui.dev["dev_on"] == true then
			draw_gui.dev_tab()
		end
		ImGui.EndTabBar()
	end
	LoadTheme.EndTheme(ColorCount, StyleCount)
	ImGui.End()
end

-- Check the version of the script against the latest version. If it is lower than the latest version notify user and exit.
--[[local function version_check()
	local success, response = pcall(http.request, version_url)
	if not success then
		logger.log_error("\aoFailed to fetch version information: %s", response)
		return
	end
	local latest_version = v(response)
	if latest_version > version then
		logger.log_error("\aoA new version is available (\arv%s\ao) please download it and try again.", response)
		mq.exit()
	end
end--]]

loadsave.versionCheck(version)
class_settings.version_check(version)

-- Initialize autosize, only sets stored value for starting size now.
local function init_autosize()
	---@diagnostic disable-next-line: undefined-field
	loadsave.SaveState.general["self_size"] = mq.TLO.AutoSize.SizeSelf()
end

local function cmd_el(cmd)
	if cmd == "dev" then
		if draw_gui.dev["dev_on"] == true then
			draw_gui.dev["dev_on"] = false
		else
			draw_gui.dev["dev_on"] = true
		end
	end
end

-- Script startup initialization. Populate the information of various UI elements, check for required plugins and script version and load the ImGui window.
local function init()
	mq.bind("/el", cmd_el)
	_G.State:populate_group_combo()
	_G.State.step_overview()
	mq.imgui.init("displayGUI", displayGUI)
	--version_check()
	logger.log_warn(
		"If you encounter any nav mesh issues please ensure you are using the latest mesh from \arhttps://github.com/yb-f/meshes"
	)
	for _, plugin in ipairs(plugins) do
		if mq.TLO.Plugin(plugin)() == nil then
			logger.log_error("\ar%s \aois required for this script.", plugin)
			logger.log_error("\aoLoaded \ar%s \aowith \agnoauto\ao.", plugin)
			mq.cmdf("/plugin %s noauto", plugin)
		end
	end
	init_autosize()
end

-- Main loop of the script. Check if we are in game, if we should start the script, and if we should exit.
local function main()
	while _G.State.running == true do
		if mq.TLO.EverQuest.GameState() ~= "INGAME" then
			logger.log_error("\arNot in game, closing.")
			mq.exit()
		end
		if _G.State:readStartRun() then
			_G.State:setStartRun(false)
			_G.State.current_step = 0
			init_epic(string.lower(mq.TLO.Me.Class.ShortName()), _G.State.epic_choice)
			run_epic()
		end
		mq.delay(200)
	end
end

init()
main()
