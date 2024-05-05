local mq                  = require('mq')
local ImGui               = require 'ImGui'
local logger              = require('utils/logger')
_G.Actions                = require('utils/actions')
_G.Mob                    = require('utils/mob')
--local dist               = require 'utils/distance'
--local inv                = require 'utils/inventory'
--local travel             = require 'utils/travel'
local draw_gui            = require('utils/drawgui')
local manage              = require('utils/manageautomation')
local loadsave            = require('utils/loadsave')
local class_settings      = require('utils/class_settings')
local quests_done         = require('utils/questsdone')
local reqs                = require('utils/questrequirements')
local tsreqs              = require('utils/tradeskillreqs')
local v                   = require('lib/semver')
local PackageMan          = require('mq/PackageMan')
local sqlite3             = PackageMan.Require('lsqlite3')
local http                = PackageMan.Require('luasocket', 'socket.http')
local ssl                 = PackageMan.Require('luasec', 'ssl')
--local ok, _          = pcall(require, 'ssl')
--if not ok then
--   PackageMan.Install('luasec')
--end

local version_url         = 'https://raw.githubusercontent.com/yb-f/EL-Ver/master/latest_ver'
local version             = v("0.3.2")
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
local LoadTheme           = require('lib.theme_loader')
local themeFile           = string.format('%s/MyThemeZ.lua', mq.configDir)
local themeName           = 'Default'
local themeID             = 5
local theme               = {}
local FIRST_WINDOW_WIDTH  = 415
local FIRST_WINDOW_HEIGHT = 475

local function File_Exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

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

_G.State                           = {}

_G.State.pause                     = false
_G.State.bind_travel               = false
_G.State.task_run                  = false
_G.State.start_run                 = false
_G.State.stop_at_save              = false
_G.State.step                      = 0
_G.State.status                    = ''
_G.State.status2                   = ''
_G.State.reqs                      = ''
_G.State.bagslot1                  = 0
_G.State.bagslot2                  = 0
_G.State.group_combo               = {}
_G.State.group_choice              = 1
_G.State.use_cwtn                  = false
_G.State.use_ka                    = false
_G.State.use_rgl                   = false
_G.State.epic_list                 = quests_done[string.lower(mq.TLO.Me.Class.ShortName())]
_G.State.epic_choice               = 1
_G.State.farming                   = false
_G.State.nextmob                   = false
_G.State.epicstring                = ''
_G.State.X, _G.State.Y, _G.State.Z = 0, 0, 0
_G.State.skip                      = false
_G.State.rewound                   = false
_G.State.bad_IDs                   = {}
_G.State.cannot_count              = 0
_G.State.traveling                 = false
_G.State.autosize                  = false
_G.State.autosize_sizes            = { 1, 2, 5, 10, 20 }
_G.State.autosize_choice           = 3
_G.State.autosize_self             = false
_G.State.autosize_on               = false
_G.State.combineSlot               = 0
_G.State.destType                  = ''
_G.State.dest                      = ''
_G.State.pathDist                  = 0
_G.State.velocity                  = 0
_G.State.estimatedTime             = 0
_G.State.startDist                 = 0
_G.State.updateTime                = math.floor(mq.gettime() / 1000)
_G.State.badMeshes                 = {}

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
    _G.State.reqs = reqs[class][quest]
    if tablename == '' then
        logger.log_error("\aoThis class and quest has not yet been implemented.")
        _G.State.task_run = false
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

local function matchFilters(spawn)
    if string.match(string.lower(spawn.CleanName()), string.lower(exclude_name)) then
        return true
    end
    return false
end

local function create_spawn_list()
    exclude_list = mq.getFilteredSpawns(matchFilters)
    for _, spawn in ipairs(exclude_list) do
        logger.log_verbose("\aoInserting bad ID for: \ar%s \ao(\ar%s\ao).", spawn.DisplayName(), spawn.ID())
        table.insert(_G.State.bad_IDs, spawn.ID())
    end
end

function _G.State.save(item)
    logger.log_info("\aoSaving step: \ar%s", _G.State.step)
    loadsave.prepSave(_G.State.step)
    if _G.State.stop_at_save then
        logger.log_warn("\aoStopping at step: \ar%s\ao.", _G.State.Step)
        _G.State.epicstring = ''
        _G.State.task_run = false
        _G.State.stop_at_save = false
        _G.State.status = string.format("Stopped at step: %s", _G.State.step)
        return
    end
end

function _G.State.exclude_npc(item)
    exclude_name = item.npc
    create_spawn_list()
end

function _G.State.execute_command(item)
    logger.log_info("\aoExecuting command: \ag%s", item.what)
    mq.cmdf("%s", item.what)
end

function _G.State.pause(item)
    _G.State.status = item.status
    _G.State.task_run = false
end

local hashCheck   = require('utils/hashcheck')
_G.Task_Functions = require('utils/task_functions')

class_settings.loadSettings()
loadsave.loadState()
if not class_settings.settings.LoadTheme then           --whatever your setting is saved as
    class_settings.settings.LoadTheme = theme.LoadTheme -- load the theme tables default if not set.
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

function _G.State.populate_group_combo()
    _G.State.group_combo = {}
    table.insert(_G.State.group_combo, "None")
    if mq.TLO.Me.Grouped() then
        table.insert(_G.State.group_combo, "Group")
        for i = 0, mq.TLO.Group() do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                table.insert(_G.State.group_combo, mq.TLO.Group.Member(i).DisplayName())
            end
        end
    end
    logger.log_super_verbose("\aoPopulating group combo box with characters in your current zone.")
end

local function check_tradeskills(class, choice)
    if tsreqs[class] ~= nil then
        local return_string = ''
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
end

local function update_general_status()
    for i = 1, #task_outline_table do
        if task_outline_table[i].Step == _G.State.step then
            _G.State.status2 = task_outline_table[i].Description
        end
    end
end

local function execute_task(task)
    local task_type = task.type
    local task_info = _G.Task_Functions[task_type]
    if task_info then
        local func = task_info.func
        local params = task_info.params
        if func then
            func(task, unpack(params))
        else
            if task_type == '' then type = 'none' end
            logger.log_error("\aoUnknown Type: \ar%s!", type)
            _G.State.status = "Unknown type: " .. task_type .. " -- Step: " .. _G.State.step
            _G.State.task_run = false
            return
        end
    end
end

local function run_epic(class, choice)
    task_table        = {}
    local tablename   = ''
    _G.State.task_run = true
    _G.State.pause    = false
    loadsave.loadState()
    logger.log_info("Begining quest for %s epic %s", mq.TLO.Me.Class(), _G.State.epic_list[choice])
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
        _G.State.task_run = false
        return
    end
    local ts_return = check_tradeskills(class, choice)
    if ts_return then
        if loadsave.SaveState.general.stopTS == true then
            logger.log_error("\aoPlease raise your tradeskills to continue, or turn off the \"\agStop if tradeskill requirements are unmet\ao\" setting.")
            logger.log_error(ts_return)
            _G.State.task_run = false
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
    while _G.State.step < #task_table do
        if overview_steps[_G.State.step] ~= nil then
            if overview_steps[_G.State.step] == 1 then
                logger.log_warn('\aoYou have selected to complete this step (\ag%s\ao) manually. Stopping script.', _G.State.step)
                mq.cmdf('/squelch /autosize sizeself %s', loadsave.SaveState.general['self_size'])
                mq.cmd('/squelch /afollow off')
                mq.cmd('/squelch /nav stop')
                mq.cmd('/squelch /stick off')
                _G.State.task_run = false
                return
            elseif overview_steps[_G.State.step] == 2 then
                logger.log_warn('\aoYou have selected to skip this step (\ag%s\ao). Moving to next step.', _G.State.step)
                for i, item in pairs(task_outline_table) do
                    if item.Step == _G.State.step then
                        _G.State.rewound = true
                        _G.State.step = task_outline_table[i + 1].Step
                        logger.log_info('\aoSetting step to \ar%s', _G.State.step)
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
        while _G.State.pause == true do
            _G.State.status = "Paused"
            mq.delay(500)
            if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
                logger.log_error('\arNot in game, closing.')
                mq.exit()
            end
            if _G.State.task_run == false then
                _G.State.pause = false
                return
            end
        end
        _G.State.skip = false
        if _G.State.rewound == false then
            _G.State.step = _G.State.step + 1
        else
            _G.State.rewound = false
        end
        if mq.TLO.Me.Combat() == true then
            mq.cmd('/attack off')
        end
        update_general_status()
        mq.doevents()
        execute_task(task_table[_G.State.step])
        if mq.TLO.Me.Levitating() then
            if task_table[_G.State.step].belev == nil then
                manage.removeLev()
            end
        end
        if task_table[_G.State.step].SaveStep == 1 then
            if _G.State.task_run == true then
                logger.log_info("\aoSaving step: \ar%s", _G.State.step)
                loadsave.prepSave(_G.State.step)
                if _G.State.stop_at_save then
                    logger.log_warn("\aoStopping at step \ar%s.", _G.State.Step)
                    _G.State.epicstring = ''
                    _G.State.task_run = false
                    _G.State.stop_at_save = false
                    _G.State.status = "Stopped at step " .. _G.State.step
                    return
                end
            end
        end
        if _G.State.task_run == false then
            mq.cmdf('/squelch /autosize sizeself %s', loadsave.SaveState.general['self_size'])
            mq.cmd('/squelch /afollow off')
            mq.cmd('/squelch /nav stop')
            mq.cmd('/squelch /stick off')
            return
        end
    end
    _G.State.status = "Completed " .. mq.TLO.Me.Class() .. ": " .. _G.State.epicstring
    _G.State.epicstring = ''
    _G.State.task_run = false
    logger.log_info("\aoCompleted \ay%s \ao- \ar%s!", mq.TLO.Me.Class(), _G.State.epicstring)
end

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
        ImGui.BeginTabBar("##Tabs")
        draw_gui.generalTab(task_table)
        theme.LoadTheme, themeName, themeID, class_settings.settings.LoadTheme = draw_gui.settingsTab(themeName, theme, themeID, class_settings, loadsave)
        draw_gui.outlineTab(task_outline_table, overview_steps, task_table)
        if _G.State.task_run == true then
            draw_gui.fullOutlineTab(task_table)
        end
        draw_gui.consoleTab(class_settings)
        ImGui.EndTabBar()
    end
    LoadTheme.EndTheme(ColorCount, StyleCount)
    ImGui.End()
end

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

local function autosize_self_event(line, arg1)
    if arg1 == "disabled" then
        _G.State.autosize_self = false
    else
        _G.State.autosize_self = true
    end
end

local function autosize_self_size(line, arg1)
    loadsave.SaveState.general['self_size'] = tonumber(autosize_self_size)
    loadsave.saveState()
end

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
            mq.cmd('/squelch /autosize self')
        end
        mq.cmd('/squelch /autosize off')
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

local function init()
    _G.State.populate_group_combo()
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

local function main()
    while running == true do
        if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
            logger.log_error('\arNot in game, closing.')
            mq.exit()
        end
        if _G.State.start_run == true then
            _G.State.start_run = false
            _G.State.step = 0
            run_epic(string.lower(mq.TLO.Me.Class.ShortName()), _G.State.epic_choice)
        end
        mq.delay(200)
    end
end

init()
main()
