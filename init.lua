--[[
TODO: Check the NPC_GIVE function and see if there is an issue where it is hanging or crashing when the NPC is not present.
TODO: Rogue 1.5 during the tradeskill combines do a pre-check before executing each of the combines.

TODO: Better checks for invis and speed that won't stutter step the character.
TODO: In farm_radius function look into prioritizing certain named mobs.
TODO: Use group invis if available.

TODO: Improve travel logic if possible. (There is not a native way to implement the ideas I have, give this more thought) )

TODO: Add check in Warrior 1.5 to see if High Quality Metal Bits were made successfully.

FIXME: Ranger 2.0 Step 73 Craftmaster Tieranu determine if npc will spawn if trigger spawns while you are in the room already.
* In progress -- Can not trigger NPC unless on that step, hooray.


* Berserker (3), Wizard (3), Druid (3), Enchanter (3), Necromancer (3), Monk (2)
? meshes: chardokb, nedaria
--]]

local mq                  = require('mq')
local ImGui               = require 'ImGui'
local logger              = require('utils/logger')
_G.Actions                = require('utils/actions')
_G.Mob                    = require('utils/mob')
--local dist               = require 'utils/distance'
--local inv                 = require 'utils/inventory'
--local travel             = require 'utils/travel'
local class_definitions   = require('lib/class_definitions')
local draw_gui            = require('utils/drawgui')
local manage              = require('utils/manageautomation')
local loadsave            = require('utils/loadsave')
local class_settings      = require('utils/class_settings')
local quests_done         = require('utils/questsdone')
local reqs                = require('utils/questrequirements')
local tsreqs              = require('utils/tradeskillreqs')
local v                   = require('lib/semver')
local LoadTheme           = require('lib.theme_loader')
local PackageMan          = require('mq/PackageMan')
local sqlite3             = PackageMan.Require('lsqlite3')
local http                = PackageMan.Require('luasocket', 'socket.http')
local ssl                 = PackageMan.Require('luasec', 'ssl')

local version_url         = 'https://raw.githubusercontent.com/yb-f/EL-Ver/master/latest_ver'
local version             = v("0.3.41")
local window_flags        = bit32.bor(ImGuiWindowFlags.None)
local openGUI, drawGUI    = true, true
local myName              = mq.TLO.Me.DisplayName()
local dbn                 = sqlite3.open(mq.luaDir .. '\\epiclaziness\\epiclaziness.db')
local db_outline          = sqlite3.open(mq.luaDir .. '\\epiclaziness\\epiclaziness_outline.db')
local plugins             = { 'MQ2Nav', 'MQ2EasyFind', 'MQ2Relocate', 'MQ2PortalSetter', }
local task_table          = {}
local task_outline_table  = {}
local running             = true
local exclude_list        = {}
local exclude_name        = ''
local overview_steps      = {}
local themeFile           = string.format('%s/MyThemeZ.lua', mq.configDir)
local themeName           = 'Default'
local themeID             = 5
local theme               = {}
local FIRST_WINDOW_WIDTH  = 415
local FIRST_WINDOW_HEIGHT = 475
local AUTOSIZE_SIZES      = { 1, 2, 5, 10, 20 }
local AUTOSIZE_CHOICE     = 3
local class_name_table    = {
    ['Bard'] = 'brd',
    ['Beastlord'] = 'bst',
    ['Berserker'] = 'ber',
    ['Cleric'] = 'clr',
    ['Druid'] = 'dru',
    ['Enchanter'] = 'enc',
    ['Magician'] = 'mag',
    ['Monk'] = 'mnk',
    ['Necromancer'] = 'nec',
    ['Paladin'] = 'pal',
    ['Ranger'] = 'rng',
    ['Rogue'] = 'rog',
    ['Shadow Knight'] = 'shd',
    ['Shaman'] = 'shm',
    ['Warrior'] = 'war',
    ['Wizard'] = 'wiz'
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
        theme = require('lib/themes') -- your local themes file incase the user doesn't have one in config folder
    end
    if not themeName then themeName = theme.LoadTheme or 'Default' end
    if theme and theme.Theme then
        for tID, tData in pairs(theme.Theme) do
            if tData['Name'] == themeName then
                themeID = tID
            end
        end
    end
end

-- Global State table, contains variables and methods necessary in other files
_G.State = {
    xtargIgnore           = '',
    is_paused             = false, --
    is_task_running       = false, --
    do_start_run          = false, --
    should_stop_at_save   = false, --
    current_step          = 0,     --
    status                = '',    --
    status2               = '',    --
    requirements          = '',    --
    bagslot1              = 0,     --0
    bagslot2              = 0,     --0
    group_combo           = {},
    group_choice          = 1,
    group_selected_member = '',
    epic_list             = quests_done[string.lower(mq.TLO.Me.Class.ShortName())],
    epic_choice           = 1,
    epicstring            = '',
    Location              = { --
        X = 0,
        Y = 0,
        Z = 0,
    },
    should_skip           = false,
    is_rewound            = false,
    bad_IDs               = {},
    cannot_count          = 0,
    is_traveling          = false,
    autosize              = false,
    autosize_sizes        = AUTOSIZE_SIZES,
    autosize_choice       = AUTOSIZE_CHOICE,
    autosize_self         = false,
    autosize_on           = false,
    combineSlot           = 0,
    destType              = '',
    dest                  = '',
    pathDist              = 0,
    velocity              = 0,
    estimatedTime         = 0,
    startDist             = 0,
    updateTime            = mq.gettime(),
    badMeshes             = {},
    velocityTable         = {},
}

-- Clear the velocity table
function _G.State:clearVelocityTable()
    self.velocityTable = {}
end

-- Calculate the average velocity from velocities stored in the velocity table
--- @return number
function _G.State:getAverageVelocity()
    local velocitySum = 0
    for i, v in pairs(self.velocityTable) do
        velocitySum = velocitySum + v
    end
    return velocitySum / #self.velocityTable
end

-- Add a velocity to the velocity table
--- @param velocity number
function _G.State:addVelocity(velocity)
    if #self.velocityTable >= 20 then
        table.remove(self.velocityTable, 1)
    end
    table.insert(self.velocityTable, velocity)
end

-- Read the status of the start_run variable
--- @return boolean
function _G.State:readStartRun()
    return self.do_start_run
end

-- Set the start_run variable
--- @param value boolean
function _G.State:setStartRun(value)
    self.do_start_run = value
end

-- Set xtargIgnore to value
--- @param value string
function _G.State:setXtargIgnore(value)
    self.xtargIgnore = value
end

-- Read the value of xtargIgnore
--- @return string
function _G.State:readXtargIgnore()
    return self.xtargIgnore
end

--Clear the value of xtargIgnore
function _G.State:clearXtargIgnore()
    self.xtargIgnore = ''
end

-- Return is_task_running to determine if script is actively running
--- @return boolean
function _G.State:readTaskRunning()
    return self.is_task_running
end

-- Set is_task_running to value
--- @param value boolean
function _G.State:setTaskRunning(value)
    self.is_task_running = value
end

-- Return is_paused to determine if script is paused
--- @return boolean
function _G.State:readPaused()
    return self.is_paused
end

-- Set is_paused to value
--- @param value boolean
function _G.State:setPaused(value)
    self.is_paused = value
end

-- Return the value of should_stop_at_save
--- @return boolean
function _G.State:readStopAtSave()
    return self.should_stop_at_save
end

-- Set should_stop_at_save to value
--- @param value boolean
function _G.State:setStopAtSave(value)
    self.should_stop_at_save = value
end

-- Return the stored location of the player
--- @return number, number, number
function _G.State:readLocation()
    return self.Location.X, self.Location.Y, self.Location.Z
end

-- Store the current location of the player
--- @param x number
--- @param y number
--- @param z number
function _G.State:setLocation(x, y, z)
    self.Location.X = x
    self.Location.Y = y
    self.Location.Z = z
end

-- Handle changing of step. This will set the current step to the new step and set the is_rewound and should_skip variables to true
--- @param step number
function _G.State:handle_step_change(step)
    logger.log_info('\aoSetting step to: \ar%s\ao.', step)
    logger.log_verbose("\aoStep type: \ar%s\ao.", task_table[step].type)
    self.is_rewound = true
    self.should_skip = true
    self.current_step = step
    for i, state in pairs(overview_steps) do
        if i >= step and state == 2 then
            overview_steps[i] = 0
        end
    end
end

-- Set the text of the status section in the GUI
--- @param text string
function _G.State:setStatusText(text)
    self.status = text
end

-- Set the text of the second status section in the GUI
--- @param text string
function _G.State:setStatusTwoText(text)
    self.status2 = text
end

-- Read the text of the status section in the GUI
--- @return string
function _G.State:readStatusText()
    return self.status
end

-- Read the text of the second status section in the GUI
--- @return string
function _G.State:readStatusTwoText()
    return self.status2
end

-- Set the text of the requirements for this epic. Generated from questrequirements.lua
--- @param text string
function _G.State:setReqsText(text)
    self.requirements = text
end

-- Read the text of the requirements for this epic
--- @return string
function _G.State:readReqsText()
    return self.requirements
end

-- Read the outline of the selected epic from the outline db
function _G.State.step_overview()
    task_outline_table = {}
    local class = string.lower(mq.TLO.Me.Class.ShortName())
    local choice = _G.State.epic_choice
    local tablename = ''
    local quest = ''
    logger.log_super_verbose("\aoLoading step outline for %s - %s.", mq.TLO.Me.Class(), _G.State.epic_list[choice])
    if _G.State.epic_list[choice] == "1.0" then
        tablename = class .. "_10"
        quest = '10'
        _G.State.epicstring = "1.0"
    elseif _G.State.epic_list[choice] == "Pre-1.5" then
        tablename = class .. "_pre15"
        quest = 'pre15'
        _G.State.epicstring = "Pre-1.5"
    elseif _G.State.epic_list[choice] == "1.5" then
        tablename = class .. "_15"
        quest = '15'
        _G.State.epicstring = "1.5"
    elseif _G.State.epic_list[choice] == "2.0" then
        tablename = class .. "_20"
        quest = '20'
        _G.State.epicstring = "2.0"
    end
    _G.State:setReqsText(reqs[class][quest])
    if tablename == '' then
        logger.log_error("\aoThis class and quest has not yet been implemented.")
        _G.State:setTaskRunning(false)
        return
    end
    local sql = "SELECT * FROM " .. tablename
    for a in db_outline:nrows(sql) do
        table.insert(task_outline_table, a)
    end
    for _, task in pairs(task_outline_table) do
        overview_steps[task.Step] = 0
    end
    logger.log_super_verbose("\aoSuccessfuly loaded outline.")
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
local function create_spawn_list()
    exclude_list = mq.getFilteredSpawns(matchFilters)
    for _, spawn in ipairs(exclude_list) do
        logger.log_verbose("\aoInserting bad ID for: \ar%s \ao(\ar%s\ao).", spawn.DisplayName(), spawn.ID())
        table.insert(_G.State.bad_IDs, spawn.ID())
    end
end

-- Set group_selected_member to the selected member(s) in the group combo box
function _G.State:setGroupSelection()
    self.group_selected_member = self.group_combo[self.group_choice]
end

-- Return the value of group_selected_member
--- @return number, string
function _G.State:readGroupSelection()
    return self.group_choice, self.group_selected_member
end

-- Save the current step to the save state
--- @param item Item
function _G.State.save(item)
    logger.log_info("\aoSaving step: \ar%s", _G.State.current_step)
    loadsave.prepSave(_G.State.current_step)
    if _G.State:readStopAtSave() then
        logger.log_warn("\aoStopping at step: \ar%s\ao.", _G.State.current_step)
        _G.State.epicstring = ''
        _G.State:setTaskRunning(false)
        _G.State:setStopAtSave(false)
        _G.State:setStatusText(string.format("Stopped at step: %s", _G.State.current_step))
        return
    end
end

-- Exclude the provided NPC from the list of NPCs that will be handled
--- @param item Item
function _G.State.exclude_npc(item)
    exclude_name = item.npc
    create_spawn_list()
end

function _G.State.exclude_npc_by_loc(item)
    ID = mq.TLO.Spawn(item.what).ID()
    table.insert(_G.State.bad_IDs, ID)
end

-- Execute the provided command string
--- @param item Item
function _G.State.execute_command(item)
    logger.log_info("\aoExecuting command: \ag%s", item.what)
    mq.cmdf("%s", item.what)
end

-- Pause the script

--- @param item Item
function _G.State.pauseTask(item)
    _G.State:setStatusText(item.status)
    _G.State:setTaskRunning(false)
end

local hashCheck   = require('utils/hashcheck')
_G.Task_Functions = require('utils/task_functions')

class_settings.loadSettings()
loadsave.loadState()
if not class_settings.settings.LoadTheme then              --whatever your setting is saved as
    class_settings.settings['LoadTheme'] = theme.LoadTheme -- load the theme tables default if not set.
    class_settings.saveSettings()
end
if loadsave.SaveState['version'] == nil then
    loadsave.SaveState['version'] = version
    loadsave.saveState()
end
themeName = class_settings.settings.LoadTheme
loadTheme()

if class_settings.settings['logger'] == nil then
    class_settings.settings['logger'] = {
        ['LogLevel'] = 3,
        ['LogToFile'] = false
    }
    class_settings.saveSettings()
end

logger.set_log_level(class_settings.settings.logger.LogLevel)
logger.set_log_to_file(class_settings.settings.logger.LogToFile)

if loadsave.SaveState['general'] == nil then
    loadsave.SaveState['general'] = {
        ['useAOC']         = class_settings.settings.general.useAOC,
        ['invisForTravel'] = class_settings.settings.general.invisForTravel,
        ['stopTS']         = class_settings.settings.general.stopTS,
        ['returnToBind']   = class_settings.settings.general.returnToBind,
        ['xtargClear']     = 1
    }
    loadsave.saveState()
end
if loadsave.SaveState.general['speedForTravel'] == nil then
    loadsave.SaveState.general['speedForTravel'] = true
    loadsave.saveState()
end

-- Populate the values of the group combo box. (None, Group, and all members of group currently in zone)
function _G.State:populate_group_combo()
    logger.log_info("\aoPopulating group combo box with characters in your current zone.")
    self.group_combo = {}
    self.group_combo[#self.group_combo + 1] = 'None'
    if mq.TLO.Me.Grouped() then
        self.group_combo[#self.group_combo + 1] = 'Group'
        for i = 0, mq.TLO.Group() do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                self.group_combo[#self.group_combo + 1] = mq.TLO.Group.Member(i).DisplayName()
            end
        end
    end
end

-- Check the tradeskills of the player against the requirements for the selected epic return true if they meet the requirements, false if they do not.
--- @param class string
--- @param choice number
--- @return boolean
local function check_tradeskills(class, choice)
    if tsreqs[class] ~= nil then
        local return_string = nil
        local quest = ''
        local quests = {
            ["1.0"] = "10",
            ["Pre-1.5"] = "pre15",
            ["1.5"] = "15",
            ["2.0"] = "20"
        }
        quest = quests[_G.State.epic_list[choice]]
        if tsreqs[class][quest] ~= nil then
            local first = true
            for ts, req in pairs(tsreqs[class][quest]) do
                if ts == 'Elder Elvish' then
                    if mq.TLO.Me.LanguageSkill(ts)() < req then
                        if first == true then
                            first = false
                            return_string = " \ag" .. ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.LanguageSkill(ts)() .. "."
                        else
                            return_string = return_string .. " \ag" .. ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.LanguageSkill(ts)() .. "."
                        end
                    end
                else
                    if mq.TLO.Me.Skill(ts)() < req then
                        if first then
                            first = false
                            return_string = " \ag" .. ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.Skill(ts)() .. "."
                        else
                            return_string = return_string .. " \ag" .. ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.Skill(ts)() .. "."
                        end
                    end
                end
            end
            if not return_string then
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
            func(task, unpack(params))
        else
            if task_type == '' then type = 'none' end
            logger.log_error("\aoUnknown Type: \ar%s!", type)
            _G.State:setStatusText(string.format("Unknown type: %s -- Step: %s", task_type, _G.State.current_step))
            _G.State:setTaskRunning(false)
            return
        end
    end
end

-- Initialize the selected quest. Load the steps from DB and check tradeskill requirements are met.
--- @param class string
--- @param choice number
local function init_epic(class, choice)
    task_table      = {}
    local tablename = ''
    _G.State:setTaskRunning(true)
    _G.State:setPaused(false)
    loadsave.loadState()
    draw_gui.jumpStep = _G.State.current_step
    draw_gui.dev.save_step = _G.State.current_step
    if draw_gui.dev['dev_on'] == true then
        logger.log_info("Begining quest for %s epic %s", draw_gui.class_list[draw_gui.dev['force_class']], _G.State.epic_list[choice])
        class = class_name_table[draw_gui.class_list[draw_gui.dev['force_class']]]
    else
        logger.log_info("Begining quest for %s epic %s", mq.TLO.Me.Class(), _G.State.epic_list[choice])
    end
    local epic_list = {
        ["1.0"]     = class .. "_10",
        ["Pre-1.5"] = class .. "_pre15",
        ["1.5"]     = class .. "_15",
        ["2.0"]     = class .. "_20",
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
            logger.log_error("\aoPlease raise your tradeskills to continue, or turn off the \"\agStop if tradeskill requirements are unmet\ao\" setting.")
            logger.log_error(ts_return)
            _G.State:setTaskRunning(false)
            return
        else
            logger.log_warn("\aoYour tradeskills do not meet requirements for this quest but you have opted to start the quest anyways.")
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
--- @param class string
--- @param choice number
local function run_epic(class, choice)
    while _G.State.current_step < #task_table do
        if overview_steps[_G.State.current_step] ~= nil then
            if overview_steps[_G.State.current_step] == 1 then
                logger.log_warn('\aoYou have selected to complete this step (\ag%s\ao) manually. Stopping script.', _G.State.current_step)
                if _G.State.autosize == true then
                    mq.cmdf('/autosize sizeself %s', loadsave.SaveState.general['self_size'])
                end
                mq.cmd('/afollow off')
                mq.cmd('/nav stop')
                mq.cmd('/stick off')
                _G.State:setTaskRunning(false)
                return
            elseif overview_steps[_G.State.current_step] == 2 then
                logger.log_warn('\aoYou have selected to skip this step (\ag%s\ao). Moving to next step.', _G.State.current_step)
                for i, item in pairs(task_outline_table) do
                    if item.Step == _G.State.current_step then
                        _G.State:handle_step_change(task_outline_table[i + 1].Step)
                        break
                    end
                end
            end
        end
        if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
            logger.log_error('\arNot in game, closing.')
            mq.exit()
        end
        _G.State.cannot_count = 0
        while _G.State:readPaused() do
            _G.State:setStatusText("Paused")
            mq.delay(500)
            if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
                logger.log_error('\arNot in game, closing.')
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
            mq.cmd('/attack off')
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
                    _G.State.epicstring = ''
                    _G.State:setTaskRunning(false)
                    _G.State:setStopAtSave(false)
                    _G.State:setStatusText(string.format("Stopped at step %s", _G.State.current_step))
                    return
                end
            end
        end
        if _G.State:readTaskRunning() == false then
            if _G.State.autosize == true then
                mq.cmdf('/autosize sizeself %s', loadsave.SaveState.general['self_size'])
            end
            mq.cmd('/afollow off')
            mq.cmd('/nav stop')
            mq.cmd('/stick off')
            return
        end
    end
    _G.State:setStatusText(string.format("Completed %s: %s", mq.TLO.Me.Class(), _G.State.epicstring))
    logger.log_info("\aoCompleted \ay%s \ao- \ar%s!", mq.TLO.Me.Class(), _G.State.epicstring)
    _G.State.epicstring = ''
    _G.State:setTaskRunning(false)
end

-- Display the ImGui window
local function displayGUI()
    if not openGUI then
        running = false
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
        theme.LoadTheme, themeName, themeID, class_settings.settings['LoadTheme'] = draw_gui.settingsTab(themeName, theme, themeID, class_settings, loadsave)
        draw_gui.outlineTab(task_outline_table, overview_steps, task_table)
        if _G.State:readTaskRunning() then
            draw_gui.fullOutlineTab(task_table)
        end
        draw_gui.consoleTab(class_settings)
        if draw_gui.dev['dev_on'] == true then
            draw_gui.dev_tab()
        end
        ImGui.EndTabBar()
    end
    LoadTheme.EndTheme(ColorCount, StyleCount)
    ImGui.End()
end

-- Check the version of the script against the latest version. If it is lower than the latest version notify user and exit.
local function version_check()
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
end
-- Event used at script startup to determine current state of MQ2Autosize
--- @param line string
--- @param arg1 string
local function autosize_self_event(line, arg1)
    if arg1 == "disabled" then
        _G.State.autosize_self = false
    else
        _G.State.autosize_self = true
    end
end

-- Event used at script startup to determine current state of MQ2Autosize selfsize
--- @param line string
--- @param arg1 string
local function autosize_self_size(line, arg1)
    loadsave.SaveState.general['self_size'] = tonumber(arg1)
    loadsave.saveState()
end

-- Initialize the MQ2Autosize plugin. Check current settings and if Mq2Autosize is not loaded disable it's use.
local function init_autosize()
    if mq.TLO.Plugin('MQ2Autosize')() == nil then
        logger.log_warn(
            "\aoThe \agMQ2Autosize \aoplugin is not loaded. This is not required for the script to run, but may help if you are frequently becoming stuck while navigating.")
        logger.log_warn("\aoIf you would like the script to make use of it please run the command \ar/plugin autosize \aoand restart Epic Laziness.")
        _G.State.autosize = false
    else
        mq.event('auto_self_on', 'MQ2AutoSize:: Option (Self) now #1#', autosize_self_event)
        mq.cmd('/autosize self')
        mq.delay(30)
        mq.doevents()
        if _G.State.autosize_self == false then
            mq.cmd('/autosize self')
        end
        mq.cmd('/autosize off')
        if loadsave.SaveState.general['self_size'] == nil then
            mq.event('auto_self_size', 'MQ2AutoSize:: Self size is #1# (was not modified)', autosize_self_size)
            mq.cmd('/autosize sizeself 0')
            mq.delay(30)
            mq.doevents()
            mq.unevent('autosize_self_size')
        end
        _G.State.autosize_on = false
        _G.State.autosize = true
    end
end

local function cmd_el(cmd)
    if cmd == "dev" then
        if draw_gui.dev['dev_on'] == true then
            draw_gui.dev['dev_on'] = false
        else
            draw_gui.dev['dev_on'] = true
        end
    end
end

-- Script startup initialization. Populate the information of various UI elements, check for required plugins and script version and load the ImGui window.
local function init()
    mq.bind('/el', cmd_el)
    _G.State:populate_group_combo()
    _G.State.step_overview()
    mq.imgui.init('displayGUI', displayGUI)
    version_check()
    logger.log_warn("If you encounter any nav mesh issues please ensure you are using the latest mesh from \arhttps://github.com/yb-f/meshes")
    for plugin in ipairs(plugins) do
        if mq.TLO.Plugin(plugin)() == nil then
            logger.log_error("\ar%s \aois required for this script.", plugin)
            logger.log_error("\aoPlease load it with the command \ar/plugin %s \aoand rerun this script.", plugin)
            mq.exit()
        end
    end
    init_autosize()
end

-- Main loop of the script. Check if we are in game, if we should start the script, and if we should exit.
local function main()
    while running == true do
        if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
            logger.log_error('\arNot in game, closing.')
            mq.exit()
        end
        if _G.State:readStartRun() then
            _G.State:setStartRun(false)
            _G.State.current_step = 0
            init_epic(string.lower(mq.TLO.Me.Class.ShortName()), _G.State.epic_choice)
            run_epic(string.lower(mq.TLO.Me.Class.ShortName()), _G.State.epic_choice)
        end
        mq.delay(200)
    end
end

init()
main()
