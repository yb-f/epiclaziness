local mq             = require('mq')
local ImGui          = require 'ImGui'
Logger               = require('utils/logger')
local dist           = require 'utils/distance'
Actions              = require 'utils/actions'
local inv            = require 'utils/inventory'
Mob                  = require 'utils/mob'
local draw_gui       = require 'utils/drawgui'
local travel         = require 'utils/travel'
local manage         = require 'utils/manageautomation'
local loadsave       = require 'utils/loadsave'
local class_settings = require 'utils/class_settings'
local quests_done    = require 'utils/questsdone'
local reqs           = require 'utils/questrequirements'
local tsreqs         = require 'utils/tradeskillreqs'
local PackageMan     = require('mq/PackageMan')
local sqlite3        = PackageMan.Require('lsqlite3')
local http           = PackageMan.Require('luasocket', 'socket.http')
local ok, _          = pcall(require, 'ssl')
if not ok then
    PackageMan.Install('luasec')
end

local version_url        = 'https://raw.githubusercontent.com/yb-f/EL-Ver/master/latest_ver'
local version            = "0.3.1"
local window_flags       = bit32.bor(ImGuiWindowFlags.None)
local openGUI, drawGUI   = true, true
local myName             = mq.TLO.Me.DisplayName()
local dbn                = sqlite3.open(mq.luaDir .. '\\epiclaziness\\epiclaziness.db')
local db_outline         = sqlite3.open(mq.luaDir .. '\\epiclaziness\\epiclaziness_outline.db')
local task_table         = {}
local task_outline_table = {}
local running            = true
local exclude_list       = {}
local exclude_name       = ''
local overview_steps     = {}
local LoadTheme          = require('lib.theme_loader')
local themeFile          = string.format('%s/MyThemeZ.lua', mq.configDir)
local themeName          = 'Default'
local themeID            = 5
local theme              = {}
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

State                     = {}

State.pause               = false
State.bind_travel         = false
State.task_run            = false
State.start_run           = false
State.stop_at_save        = false
State.step                = 0
State.status              = ''
State.status2             = ''
State.reqs                = ''
State.bagslot1            = 0
State.bagslot2            = 0
State.group_combo         = {}
State.group_choice        = 1
State.use_cwtn            = false
State.use_ka              = false
State.use_rgl             = false
State.epic_list           = quests_done[string.lower(mq.TLO.Me.Class.ShortName())]
State.epic_choice         = 1
State.farming             = false
State.nextmob             = false
State.epicstring          = ''
State.X, State.Y, State.Z = 0, 0, 0
State.skip                = false
State.rewound             = false
State.bad_IDs             = {}
State.cannot_count        = 0
State.traveling           = false
State.autosize            = false
State.autosize_sizes      = { 1, 2, 5, 10, 20 }
State.autosize_choice     = 3
State.autosize_self       = false
State.autosize_on         = false
State.combineSlot         = 0
State.destType            = ''
State.dest                = ''
State.pathDist            = 0
State.velocity            = 0
State.estimatedTime       = 0
State.startDist           = 0
State.updateTime          = math.floor(mq.gettime() / 1000)
State.badMeshes           = {}

function State.step_overview()
    task_outline_table = {}
    local class = string.lower(mq.TLO.Me.Class.ShortName())
    local choice = State.epic_choice
    local tablename = ''
    local quest = ''
    Logger.log_super_verbose("\aoLoading step outline for %s - %s.", mq.TLO.Me.Class(), State.epic_list[choice])
    if State.epic_list[choice] == "1.0" then
        tablename = class .. "_10"
        quest = '10'
        State.epicstring = "1.0"
    elseif State.epic_list[choice] == "Pre-1.5" then
        tablename = class .. "_pre15"
        quest = 'pre15'
        State.epicstring = "Pre-1.5"
    elseif State.epic_list[choice] == "1.5" then
        tablename = class .. "_15"
        quest = '15'
        State.epicstring = "1.5"
    elseif State.epic_list[choice] == "2.0" then
        tablename = class .. "_20"
        quest = '20'
        State.epicstring = "2.0"
    end
    State.reqs = reqs[class][quest]
    if tablename == '' then
        Logger.log_error("\aoThis class and quest has not yet been implemented.")
        State.task_run = false
        return
    end
    local sql = "SELECT * FROM " .. tablename
    for a in db_outline:nrows(sql) do
        table.insert(task_outline_table, a)
    end
    for _, task in pairs(task_outline_table) do
        overview_steps[task.Step] = 0
    end
    Logger.log_super_verbose("\aoSuccessfuly loaded outline.")
end

local function matchFilters(spawn)
    if string.find(string.lower(spawn.CleanName()), string.lower(exclude_name)) then
        return true
    end
    return false
end

local function create_spawn_list()
    exclude_list = mq.getFilteredSpawns(matchFilters)
    for _, spawn in pairs(exclude_list) do
        Logger.log_verbose("\aoInserting \ar%s (%s) \aointo list of bad IDs.", spawn.DisplayName(), spawn.ID())
        table.insert(State.bad_IDs, spawn.ID())
    end
end

function State.save(item)
    Logger.log_info("\aoSaving step: \ar%s", State.step)
    loadsave.prepSave(State.step)
    if State.stop_at_save then
        Logger.log_warn("\aoStopping at step \ar%s.", State.Step)
        State.epicstring = ''
        State.task_run = false
        State.stop_at_save = false
        State.status = "Stopped at step " .. State.step
        return
    end
end

function State.exclude_npc(item)
    exclude_name = item.npc
    create_spawn_list()
end

function State.execute_command(item)
    mq.cmdf("%s", item.what)
end

function State.pause(item)
    State.status = item.status
    State.task_run = false
end

local hashCheck = require 'utils/hashcheck'
Task_Functions  = require 'utils/task_functions'

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

Logger.set_log_level(class_settings.settings.logger.LogLevel)
Logger.set_log_to_file(class_settings.settings.logger.LogToFile)

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

function State.populate_group_combo()
    State.group_combo = {}
    table.insert(State.group_combo, "None")
    if mq.TLO.Me.Grouped() == true then
        table.insert(State.group_combo, "Group")
        for i = 0, mq.TLO.Group() do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                table.insert(State.group_combo, mq.TLO.Group.Member(i).DisplayName())
            end
        end
    end
    Logger.log_super_verbose("\aoPopulating group combo box with characters in your current zone.")
end

local function check_tradeskills(class, choice)
    if tsreqs[class] ~= nil then
        local return_string = ''
        local quest = ''
        if State.epic_list[choice] == "1.0" then
            quest = '10'
        elseif State.epic_list[choice] == "Pre-1.5" then
            quest = 'pre15'
        elseif State.epic_list[choice] == "1.5" then
            quest = '15'
        elseif State.epic_list[choice] == "2.0" then
            quest = '20'
        end
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
                        if first == true then
                            first = false
                            return_string = " \ag" .. ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.Skill(ts)() .. "."
                        else
                            return_string = return_string .. " \ag" .. ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.Skill(ts)() .. "."
                        end
                    end
                end
            end
            if return_string == '' then
                return false
            else
                return return_string
            end
        end
    end
end

local function update_general_status()
    for i = 1, #task_outline_table do
        if task_outline_table[i].Step == State.step then
            State.status2 = task_outline_table[i].Description
        end
    end
end

local function execute_task(task)
    local task_type = task.type
    local task_info = Task_Functions[task_type]
    if task_info then
        local func = task_info.func
        local params = task_info.params
        print(task.type)
        print(func)
        if func then
            func(task, unpack(params))
        else
            if task_type == '' then type = 'none' end
            Logger.log_error("\aoUnknown Type: \ar%s!", type)
            State.status = "Unknown type: " .. task_type .. " -- Step: " .. State.step
            State.task_run = false
            return
        end
    end
end

local function run_epic(class, choice)
    task_table      = {}
    local tablename = ''
    State.task_run  = true
    State.pause     = false
    loadsave.loadState()
    Logger.log_info("Begining quest for %s epic %s", mq.TLO.Me.Class(), State.epic_list[choice])
    if State.epic_list[choice] == "1.0" then
        tablename = class .. "_10"
        State.epicstring = "1.0"
    elseif State.epic_list[choice] == "Pre-1.5" then
        tablename = class .. "_pre15"
        State.epicstring = "Pre-1.5"
    elseif State.epic_list[choice] == "1.5" then
        tablename = class .. "_15"
        State.epicstring = "1.5"
    elseif State.epic_list[choice] == "2.0" then
        tablename = class .. "_20"
        State.epicstring = "2.0"
    end
    if tablename == '' then
        Logger.log_error("\aoThis class and quest has not yet been implemented.")
        State.task_run = false
        return
    end
    local ts_return = check_tradeskills(class, choice)
    if ts_return then
        if loadsave.SaveState.general.stopTS == true then
            Logger.log_error("\aoPlease raise your tradeskills to continue, or turn off the \"\agStop if tradeskill requirements are unmet\ao\" setting.")
            Logger.log_error(ts_return)
            State.task_run = false
            return
        else
            Logger.log_warn("\aoYour tradeskills do not meet requirements for this quest but you have opted to start the quest anyways.")
        end
    end
    local sql = "SELECT * FROM " .. tablename
    for a in dbn:nrows(sql) do
        table.insert(task_table, a)
    end
    manage.startGroup(class_settings.settings, loadsave.SaveState)
    mq.delay("5s")
    manage.pauseGroup(class_settings.settings)
    while State.step < #task_table do
        if overview_steps[State.step] ~= nil then
            if overview_steps[State.step] == 1 then
                Logger.log_warn('\aoYou have selected to complete this step (\ag%s\ao) manually. Stopping script.', State.step)
                mq.cmdf('/squelch /autosize sizeself %s', loadsave.SaveState.general['self_size'])
                mq.cmd('/squelch /afollow off')
                mq.cmd('/squelch /nav stop')
                mq.cmd('/squelch /stick off')
                State.task_run = false
                return
            elseif overview_steps[State.step] == 2 then
                Logger.log_warn('\aoYou have selected to skip this step (\ag%s\ao). Moving to next step.', State.step)
                for i, item in pairs(task_outline_table) do
                    if item.Step == State.step then
                        State.rewound = true
                        State.step = task_outline_table[i + 1].Step
                        Logger.log_info('\aoSetting step to \ar%s', State.step)
                        break
                    end
                end
            end
        end
        if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
            Logger.log_error('\arNot in game, closing.')
            mq.exit()
        end
        State.cannot_count = 0
        while State.pause == true do
            State.status = "Paused"
            mq.delay(500)
            if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
                Logger.log_error('\arNot in game, closing.')
                mq.exit()
            end
            if State.task_run == false then
                State.pause = false
                return
            end
        end
        State.skip = false
        if State.rewound == false then
            State.step = State.step + 1
        else
            State.rewound = false
        end
        if mq.TLO.Me.Combat() == true then
            mq.cmd('/attack off')
        end
        update_general_status()
        mq.doevents()
        execute_task(task_table[State.step])
        if mq.TLO.Me.Levitating() then
            if task_table[State.step].belev == nil then
                manage.removeLev()
            end
        end
        if task_table[State.step].SaveStep == 1 then
            if State.task_run == true then
                Logger.log_info("\aoSaving step: \ar%s", State.step)
                loadsave.prepSave(State.step)
                if State.stop_at_save then
                    Logger.log_warn("\aoStopping at step \ar%s.", State.Step)
                    State.epicstring = ''
                    State.task_run = false
                    State.stop_at_save = false
                    State.status = "Stopped at step " .. State.step
                    return
                end
            end
        end
        if State.task_run == false then
            mq.cmdf('/squelch /autosize sizeself %s', loadsave.SaveState.general['self_size'])
            mq.cmd('/squelch /afollow off')
            mq.cmd('/squelch /nav stop')
            mq.cmd('/squelch /stick off')
            return
        end
    end
    State.status = "Completed " .. mq.TLO.Me.Class() .. ": " .. State.epicstring
    State.epicstring = ''
    State.task_run = false
    Logger.log_info("\aoCompleted \ay%s \ao- \ar%s!", mq.TLO.Me.Class(), State.epicstring)
end

local function displayGUI()
    if not openGUI then
        running = false
        mq.exit()
        return
    end
    if Logger.LogConsole == nil then
        Logger.LogConsole = ImGui.ConsoleWidget.new("##ELConsole")
        Logger.LogConsole.maxBufferLines = 100
        Logger.LogConsole.autoScroll = true
    end
    ImGui.SetNextWindowSize(ImVec2(415, 475), ImGuiCond.FirstUseEver)
    local ColorCount, StyleCount = LoadTheme.StartTheme(theme.Theme[themeID])
    openGUI, drawGUI = ImGui.Begin("Epic Laziness##" .. myName, openGUI, window_flags)
    if drawGUI then
        ImGui.BeginTabBar("##Tabs")
        draw_gui.generalTab(task_table)
        theme.LoadTheme, themeName, themeID, class_settings.settings.LoadTheme = draw_gui.settingsTab(themeName, theme, themeID, class_settings, loadsave)
        draw_gui.outlineTab(task_outline_table, overview_steps, task_table)
        if State.task_run == true then
            draw_gui.fullOutlineTab(task_table)
        end
        draw_gui.consoleTab(class_settings)
        ImGui.EndTabBar()
    end
    LoadTheme.EndTheme(ColorCount, StyleCount)
    ImGui.End()
end

local function version_check()
    local response = http.request(version_url)
    local version_table = {}
    local response_table = {}
    local new_version_available = false
    response = string.gsub(response, "\n", "")
    for word in string.gmatch(version, '([^.]+)') do
        table.insert(version_table, tonumber(word))
    end
    for word in string.gmatch(response, '([^.]+)') do
        table.insert(response_table, tonumber(word))
    end
    for i = 1, 3 do
        if response_table[i] > version_table[i] then
            new_version_available = true
            break
        end
    end
    if new_version_available then
        Logger.log_error("\aoA new version is available (\arv%s\ao) please download it and try again.", response)
        mq.exit()
    end
end

local function autosize_self_event(line, arg1)
    if arg1 == "disabled" then
        State.autosize_self = false
    else
        State.autosize_self = true
    end
end

local function autosize_self_size(line, arg1)
    loadsave.SaveState.general['self_size'] = tonumber(autosize_self_size)
    loadsave.saveState()
end

local function init_autosize()
    if mq.TLO.Plugin('MQ2Autosize')() == nil then
        Logger.log_warn(
            "\aoThe \agMQ2Autosize \aoplugin is not loaded. This is not required for the script to run, but may help if you are frequently becoming stuck while navigating.")
        Logger.log_warn("\aoIf you would like the script to make use of it please run the command \ar/plugin autosize \aoand restart Epic Laziness.")
        State.autosize = false
    else
        mq.event('auto_self_on', 'MQ2AutoSize:: Option (Self) now #1#', autosize_self_event)
        mq.cmd('/autosize self')
        mq.delay(30)
        mq.doevents()
        if State.autosize_self == false then
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
        State.autosize_on = false
        State.autosize = true
    end
end

local function init()
    State.populate_group_combo()
    State.step_overview()
    mq.imgui.init('displayGUI', displayGUI)
    version_check()
    Logger.log_warn("If you encounter any nav mesh issues please ensure you are using the latest mesh from \arhttps://github.com/yb-f/meshes")
    for plugin in ipairs({ 'MQ2Nav', 'MQ2EasyFind', 'MQ2Relocate', 'MQ2PortalSetter', }) do
        if mq.TLO.Plugin(plugin)() == nil then
            Logger.log_error("\ar%s \aois required for this script.", plugin)
            Logger.log_error("\aoPlease load it with the command \ar/plugin %s \aoand rerun this script.", plugin)
            mq.exit()
        end
    end
    init_autosize()
end

local function main()
    while running == true do
        if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
            Logger.log_error('\arNot in game, closing.')
            mq.exit()
        end
        if State.start_run == true then
            State.start_run = false
            State.step = 0
            run_epic(string.lower(mq.TLO.Me.Class.ShortName()), State.epic_choice)
        end
        mq.delay(200)
    end
end

init()
main()
