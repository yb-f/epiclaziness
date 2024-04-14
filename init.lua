local mq             = require('mq')
local ImGui          = require 'ImGui'
local ICONS          = require('mq.Icons')
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
local invis_travel   = require 'utils/travelandinvis'
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

LogConsole                 = nil

local version_url          = 'https://raw.githubusercontent.com/yb-f/EL-Ver/master/latest_ver'
local version              = "0.1.1"
local window_flags         = bit32.bor(ImGuiWindowFlags.None)
local treeview_table_flags = bit32.bor(ImGuiTableFlags.Hideable, ImGuiTableFlags.RowBg, ImGuiTableFlags.Borders, ImGuiTableFlags.SizingFixedFit, ImGuiTableFlags.ScrollX)
local openGUI, drawGUI     = true, true
local myName               = mq.TLO.Me.DisplayName()
local dbn                  = sqlite3.open(mq.luaDir .. '\\epiclaziness\\epiclaziness.db')
local db_outline           = sqlite3.open(mq.luaDir .. '\\epiclaziness\\epiclaziness_outline.db')
local task_table           = {}
local task_outline_table   = {}
local running              = true
local start_run            = false
local stop_at_save         = false
local class_list_choice    = 1
local changed              = false
local myClass              = mq.TLO.Me.Class()
local exclude_list         = {}
local exclude_name         = ''
local epic_list            = quests_done[string.lower(mq.TLO.Me.Class.ShortName())]
local changed              = false
local overview_steps       = {}
local LogLevels            = {
    "Errors",
    "Warnings",
    "Info",
    "Debug",
    "Verbose",
    "Super-Verbose",
}


local LoadTheme = require('lib.theme_loader')
local themeFile = string.format('%s/MyThemeZ.lua', mq.configDir)
local themeName = 'Default'
local themeID   = 5
local theme     = {}
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

local class_list          = { 'Bard', 'Beastlord', 'Berserker', 'Cleric', 'Druid', 'Enchanter', 'Magician', 'Monk', 'Necromancer',
    'Paladin', 'Ranger', 'Rogue', 'Shadow Knight', 'Shaman', 'Warrior', 'Wizard' }

local automation_list     = { 'CWTN', 'RGMercs (Lua)', 'RGMercs (Macro)', 'KissAssist', 'MuleAssist' }

local invis_type          = {}

State                     = {}

State.pause               = false
State.bind_travel         = false
State.task_run            = false
State.step                = 0
State.status              = ''
State.reqs                = ''
State.bagslot1            = 0
State.bagslot2            = 0
State.group_combo         = {}
State.group_choice        = 1
State.use_cwtn            = false
State.use_ka              = false
State.use_rgl             = false
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

class_settings.loadSettings()
loadsave.loadState()
if not class_settings.settings.LoadTheme then           --whatever your setting is saved as
    class_settings.settings.LoadTheme = theme.LoadTheme -- load the theme tables default if not set.
    class_settings.saveSettings()
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
        ['useAOC'] = class_settings.settings.general.useAOC,
        ['invisForTravel'] = class_settings.settings.general.invisForTravel,
        ['stopTS'] = class_settings.settings.general.stopTS,
        ['returnToBind'] = class_settings.settings.general.returnToBind,
    }
    loadsave.saveState()
end

local function step_overview()
    task_outline_table = {}
    local class = string.lower(mq.TLO.Me.Class.ShortName())
    local choice = State.epic_choice
    local tablename = ''
    local quest = ''
    Logger.log_super_verbose("\aoLoading step outline for %s - %s.", mq.TLO.Me.Class(), epic_list[choice])
    if epic_list[choice] == "1.0" then
        tablename = class .. "_10"
        quest = '10'
        State.epicstring = "1.0"
    elseif epic_list[choice] == "Pre-1.5" then
        tablename = class .. "_pre15"
        quest = 'pre15'
        State.epicstring = "Pre-1.5"
    elseif epic_list[choice] == "1.5" then
        tablename = class .. "_15"
        quest = '15'
        State.epicstring = "1.5"
    elseif epic_list[choice] == "2.0" then
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
        overview_steps[task.Step] = false
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

local function invis_needed(class, choice)
    local class_epic = ''
    if choice == 1 then
        class_epic = string.lower(class) .. "_10"
    elseif choice == 2 then
        class_epic = string.lower(class) .. "_pre15"
    elseif choice == 3 then
        class_epic = string.lower(class) .. "_15"
    elseif choice == 4 then
        class_epic = string.lower(class) .. "_20"
    end
    return invis_travel[class_epic].invis
end

local function gate_needed(class, choice)
    local class_epic = ''
    if choice == 1 then
        class_epic = string.lower(class) .. "_10"
    elseif choice == 2 then
        class_epic = string.lower(class) .. "_pre15"
    elseif choice == 3 then
        class_epic = string.lower(class) .. "_15"
    elseif choice == 4 then
        class_epic = string.lower(class) .. "_20"
    end
    return invis_travel[class_epic].gate
end

local function populate_group_combo()
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
        if epic_list[choice] == "1.0" then
            quest = '10'
        elseif epic_list[choice] == "Pre-1.5" then
            quest = 'pre15'
        elseif epic_list[choice] == "1.5" then
            quest = '15'
        elseif epic_list[choice] == "2.0" then
            quest = '20'
        end
        if tsreqs[class][quest] ~= nil then
            local first = true
            for ts, req in pairs(tsreqs[class][quest]) do
                if mq.TLO.Me.Skill(ts)() < req then
                    if first == true then
                        first = false
                        return_string = " \ag" .. ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.Skill(ts)() .. "."
                    else
                        return_string = return_string .. " \ag" .. ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.Skill(ts)() .. "."
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

local function run_epic(class, choice)
    task_table = {}
    local tablename = ''
    State.task_run = true
    loadsave.loadState()
    Logger.log_info("Begining quest for %s epic %s", mq.TLO.Me.Class(), epic_list[choice])
    if epic_list[choice] == "1.0" then
        tablename = class .. "_10"
        State.epicstring = "1.0"
    elseif epic_list[choice] == "Pre-1.5" then
        tablename = class .. "_pre15"
        State.epicstring = "Pre-1.5"
    elseif epic_list[choice] == "1.5" then
        tablename = class .. "_15"
        State.epicstring = "1.5"
    elseif epic_list[choice] == "2.0" then
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
        State.cannot_count = 0
        while State.pause == true do
            State.status = "Paused"
            mq.delay(500)
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
        if task_table[State.step].type == 'ADVENTURE_ENTRANCE' then
            Actions.adventure_entrance(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "AUTO_INV" then
            inv.auto_inv()
        elseif task_table[State.step].type == "BACKSTAB" then
            Mob.backstab(task_table[State.step])
        elseif task_table[State.step].type == "CAST_ALT" then
            Actions.cast_alt(task_table[State.step])
        elseif task_table[State.step].type == "COMBINE_CONTAINER" then
            inv.combine_container(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "COMBINE_DO" then
            inv.combine_do(class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "COMBINE_DONE" then
            inv.combine_done(class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "COMBINE_ITEM" then
            inv.combine_item(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "ENVIRO_COMBINE_CONTAINER" then
            inv.enviro_combine_container(task_table[State.step])
        elseif task_table[State.step].type == "ENVIRO_COMBINE_DO" then
            inv.enviro_combine_do()
        elseif task_table[State.step].type == "ENVIRO_COMBINE_ITEM" then
            inv.enviro_combine_item(task_table[State.step])
        elseif task_table[State.step].type == "EQUIP_ITEM" then
            inv.equip_item(task_table[State.step])
        elseif task_table[State.step].type == "EXCLUDE_NPC" then
            exclude_name = task_table[State.step].npc
            create_spawn_list()
        elseif task_table[State.step].type == "EXECUTE_COMMAND" then
            if Mob.xtargetCheck(loadsave.SaveState) then
                Mob.clearXtarget(class_settings.settings, loadsave.SaveState)
            end
            mq.cmdf("%s", task_table[State.step].what)
            mq.delay(500)
        elseif task_table[State.step].type == "FACE_HEADING" then
            travel.face_heading(task_table[State.step].what)
        elseif task_table[State.step].type == "FACE_LOC" then
            travel.face_loc(task_table[State.step])
        elseif task_table[State.step].type == "FARM_CHECK" then
            Actions.farm_check(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "FARM_CHECK_PAUSE" then
            Actions.farm_check_pause(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "FARM_RADIUS" then
            Actions.farm_radius(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "FISH_FARM" then
            Actions.fish_farm(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "FISH_ONCE" then
            Actions.fish_farm(task_table[State.step], class_settings.settings, loadsave.SaveState, true)
        elseif task_table[State.step].type == "FORAGE_FARM" then
            Actions.forage_farm(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "FORWARD_ZONE" then
            travel.forward_zone(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "GENERAL_SEARCH" then
            Mob.general_search(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "GENERAL_TRAVEL" then
            travel.general_travel(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "GROUND_SPAWN" then
            Actions.ground_spawn(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "IGNORE_MOB" then
            Actions.ignore_mob(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "LOC_TRAVEL" then
            travel.loc_travel(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "LOOT" then
            if Mob.xtargetCheck(loadsave.SaveState) then
                Mob.clearXtarget(class_settings.settings, loadsave.SaveState)
            end
            inv.loot(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NO_NAV_TRAVEL" then
            travel.no_nav_travel(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_BUY" then
            inv.npc_buy(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_DAMAGE_UNTIL" then
            Mob.npc_damage_until(task_table[State.step])
        elseif task_table[State.step].type == "NPC_FOLLOW" then
            travel.npc_follow(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_GIVE" then
            Actions.npc_give(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_GIVE_ADD" then
            Actions.npc_give_add(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_GIVE_CLICK" then
            Actions.npc_give_click(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_GIVE_MONEY" then
            Actions.npc_give_money(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_HAIL" then
            Actions.npc_hail(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_KILL" then
            Mob.npc_kill(task_table[State.step], class_settings.settings, task_table[State.step + 1].type)
        elseif task_table[State.step].type == "NPC_KILL_ALL" then
            Actions.npc_kill_all(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_SEARCH" then
            Mob.general_search(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_STOP_FOLLOW" then
            travel.npc_stop_follow()
        elseif task_table[State.step].type == "NPC_TALK" then
            Actions.npc_talk(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_TALK_ALL" then
            if Mob.xtargetCheck(loadsave.SaveState) then
                Mob.clearXtarget(class_settings.settings, loadsave.SaveState)
            end
            Actions.npc_talk_all(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_TRAVEL" then
            travel.npc_travel(task_table[State.step], class_settings.settings, false, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_TRAVEL_NO_PATH_CHECK" then
            travel.npc_travel(task_table[State.step], class_settings.settings, true, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_WAIT" then
            Actions.npc_wait(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "NPC_WAIT_DESPAWN" then
            Actions.npc_wait_despawn(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "OPEN_DOOR" then
            travel.open_door()
        elseif task_table[State.step].type == "OPEN_DOOR_ALL" then
            manage.openDoorAll()
        elseif task_table[State.step].type == "PH_SEARCH" then
            Mob.ph_search(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "PICK_DOOR" then
            manage.picklockGroup()
        elseif task_table[State.step].type == "PICK_POCKET" then
            Actions.pickpocket(task_table[State.step])
        elseif task_table[State.step].type == "PICKUP_KEY" then
            mq.cmdf("/squelch /itemnotify \"%s\" leftmouseup", task_table[State.step].what)
        elseif task_table[State.step].type == "PORTAL_SET" then
            travel.portal_set(task_table[State.step])
        elseif task_table[State.step].type == "PRE_FARM_CHECK" then
            Actions.pre_farm_check(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "RELOCATE" then
            travel.relocate(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "REMOVE_INVIS" then
            manage.removeInvis()
        elseif task_table[State.step].type == "RESTORE_ITEM" then
            inv.restore_item()
        elseif task_table[State.step].type == "ROG_GAMBLE" then
            Actions.rog_gamble(task_table[State.step])
        elseif task_table[State.step].type == "START_ADVENTURE" then
            Actions.start_adventure(task_table[State.step])
        elseif task_table[State.step].type == "SEND_YES" then
            manage.sendYes()
        elseif task_table[State.step].type == "WAIT" then
            State.status = "Pausing for " .. task_table[State.step].what / 1000 .. " seconds"
            Actions.wait(task_table[State.step], class_settings.settings, loadsave.SaveState)
        elseif task_table[State.step].type == "WAIT_EVENT" then
            Actions.wait_event(task_table[State.step])
        elseif task_table[State.step].type == "ZONE_CONTINUE_TRAVEL" then
            travel.zone_travel(task_table[State.step], class_settings.settings, loadsave.SaveState, true)
        elseif task_table[State.step].type == "ZONE_TRAVEL" then
            State.bad_IDs = {}
            travel.zone_travel(task_table[State.step], class_settings.settings, loadsave.SaveState, false)
        else
            local type = task_table[State.step].type
            if type == '' then type = 'none' end
            Logger.log_error("\aoUnknown Type: \ar%s!", type)
            State.status = "Unknown type: " .. type .. " -- Step: " .. State.step
            State.task_run = false
            return
        end
        if task_table[State.step].belev == nil then
            manage.removeLev()
        end
        if task_table[State.step].SaveStep == 1 then
            Logger.log_info("\aosaving step: \ar%s", State.step)
            loadsave.prepSave(State.step)
            if stop_at_save then
                Logger.log_warn("\aoStopping at step \ar%s.", State.Step)
                State.epicstring = ''
                State.task_run = false
                stop_at_save = false
                State.status = "Stopped at step " .. State.step
                return
            end
        end
        if State.task_run == false then
            mq.cmd('/afollow off')
            mq.cmd('/nav stop')
            mq.cmd('/stick off')
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
    if LogConsole == nil then
        LogConsole = ImGui.ConsoleWidget.new("##ELConsole")
        LogConsole.maxBufferLines = 100
        LogConsole.autoScroll = true
    end
    ImGui.SetNextWindowSize(ImVec2(415, 475), ImGuiCond.FirstUseEver)
    local ColorCount, StyleCount = LoadTheme.StartTheme(theme.Theme[themeID])
    openGUI, drawGUI = ImGui.Begin("Epic Laziness##" .. myName, openGUI, window_flags)
    if drawGUI then
        ImGui.BeginTabBar("##Tabs")
        if ImGui.BeginTabItem("General") then
            ImGui.Text("Class: " .. myClass .. " " .. State.epicstring)
            if State.task_run == false then
                State.epic_choice, changed = ImGui.Combo('##Combo', State.epic_choice, epic_list, #epic_list, #epic_list)
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('Which epic to run.')
                end
                if changed == true then
                    step_overview()
                end
            end
            if mq.TLO.Me.Grouped() == true then
                State.group_choice = ImGui.Combo('##Group_Combo', State.group_choice, State.group_combo)
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('Who should come with you (None. Full group. Individual group member.)')
                end
                ImGui.SameLine()
                if ImGui.SmallButton(ICONS.MD_REFRESH) then
                    populate_group_combo()
                end
            end
            if State.task_run == false then
                if ImGui.Button("Begin") then
                    start_run = true
                end
                if ImGui.IsItemHovered() then
                    local invis_num = invis_needed(mq.TLO.Me.Class.ShortName(), State.epic_choice)
                    local gate_num = gate_needed(mq.TLO.Me.Class.ShortName(), State.epic_choice)
                    local tooltip = "Begin/resume epic quest\nThis may require at least " ..
                        invis_num .. " invis potions.\nThis may require at least " .. gate_num .. " gate potions."
                    ImGui.SetTooltip(tooltip)
                end
            end
            if State.task_run == true then
                if ImGui.SmallButton(ICONS.MD_FAST_REWIND) then
                    State.skip = true
                    State.rewound = true
                    State.step = State.step - 1
                    Logger.log_info("\aoMoving to previous step \ar%s", State.step)
                    Logger.log_verbose("\aoStep type: \ar%s", task_table[State.step].type)
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip("Move to previous step.")
                end
                ImGui.SameLine()
                if State.pause == false then
                    if ImGui.SmallButton(ICONS.MD_PAUSE) then
                        Logger.log_info("\aoPausing script.")
                        State.pause = true
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetTooltip("Pause script.")
                    end
                else
                    if ImGui.SmallButton(ICONS.FA_PLAY) then
                        State.pause = false
                        Logger.log_info("\aoResuming script.")
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetTooltip("Resume script.")
                    end
                end
                ImGui.SameLine()
                if ImGui.SmallButton(ICONS.MD_FAST_FORWARD) then
                    State.skip = true
                    State.step = State.step + 1
                    State.rewound = true
                    Logger.log_info("\aoMoving to next step \ar%s", State.step)
                    Logger.log_verbose("\aoStep type: \ar%s", task_table[State.step].type)
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip("Skip to next step.")
                end
                if ImGui.Button("Stop @ Next Save") then
                    Logger.log_info("\aoStopping at next save point.")
                    stop_at_save = true
                end
            end
            ImGui.Separator()
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram, IM_COL32(40, 150, 40, 255))
            ImGui.ProgressBar(State.step / #task_table, ImGui.GetWindowWidth(), 17, "##hp")
            ImGui.PopStyleColor()
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 20)
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetWindowWidth() / 2) - 60)
            ImGui.Text("Step " .. tostring(State.step) .. " of " .. tostring(#task_table))
            ImGui.TextWrapped(State.status)
            for i = 1, 3 do
                ImGui.NewLine()
            end
            ImGui.TextWrapped(State.reqs)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Settings") then
            ImGui.BeginChild("##SettingsChild")
            if ImGui.CollapsingHeader('General Settings') then
                ImGui.Text("Cur Theme: %s", themeName)
                -- Combo Box Load Theme
                ImGui.PushItemWidth(120)
                if ImGui.BeginCombo("Load Theme##Waypoints", themeName) then
                    --ImGui.SetWindowFontScale(ZoomLvl)
                    for k, data in pairs(theme.Theme) do
                        local isSelected = data.Name == themeName
                        if ImGui.Selectable(data.Name, isSelected) then
                            theme.LoadTheme = data.Name
                            themeName = theme.LoadTheme
                            themeID = k
                            class_settings.settings.LoadTheme = theme.LoadTheme
                        end
                    end
                    ImGui.EndCombo()
                end
                ImGui.PopItemWidth()
                loadsave.SaveState.general.stopTS = ImGui.Checkbox("Stop if tradeskill requirements are unmet",
                    loadsave.SaveState.general.stopTS)
                loadsave.SaveState.general.returnToBind = ImGui.Checkbox("Return to Bind Between Travel",
                    loadsave.SaveState.general.returnToBind)
                loadsave.SaveState.general.invisForTravel = ImGui.Checkbox("Invis When Travelling",
                    loadsave.SaveState.general.invisForTravel)
                ImGui.PushItemWidth(120)
                loadsave.SaveState.general.xtargClear = ImGui.InputInt("Number of mobs to clear XTarget list.",
                    loadsave.SaveState.general.xtargClear)
                ImGui.PopItemWidth()
                if ImGui.Button("Save") then
                    loadsave.saveState()
                    class_settings.saveSettings()
                end
            end
            if ImGui.CollapsingHeader('Class Settings') then
                ImGui.BeginTable("##Class_Settings", 2, ImGuiTableFlags.Borders)
                ImGui.TableSetupColumn("##Class_List", ImGuiTableColumnFlags.WidthFixed, 120)
                ImGui.TableSetupColumn("##Class_Setting", ImGuiTableColumnFlags.None)
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.PushItemWidth(120)
                ImGui.PushStyleColor(ImGuiCol.FrameBg, IM_COL32(0, 0, 0, 255))
                class_list_choice = ImGui.ListBox("##classlist", class_list_choice, class_list, #class_list, #class_list)
                ImGui.PopItemWidth()
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                local width = ImGui.GetColumnWidth()
                local text_width = ImGui.CalcTextSize(class_list[class_list_choice])
                ImGui.SetCursorPosX((width - text_width))
                ImGui.Text(class_list[class_list_choice])
                class_settings.settings.class[class_list[class_list_choice]], changed = ImGui.Combo('##AutomationType',
                    class_settings.settings.class[class_list[class_list_choice]], automation_list, #automation_list,
                    #automation_list)
                invis_type = {}
                for word in string.gmatch(class_settings.settings.class_invis[class_list[class_list_choice]], '([^|]+)') do
                    table.insert(invis_type, word)
                end
                ImGui.PushItemWidth(230)
                class_settings.settings.invis[class_list[class_list_choice]], changed = ImGui.Combo('##InvisType',
                    class_settings.settings.invis[class_list[class_list_choice]], invis_type, #invis_type,
                    #invis_type)
                if changed then
                    changed = false
                    class_settings.saveSettings()
                end
                ImGui.EndTable()
            end
            ImGui.EndChild()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Outline") then
            ImGui.BeginTable('##outlinetable', 3, treeview_table_flags)
            ImGui.TableSetupColumn("Manual Completion", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
            ImGui.TableSetupColumn("Step", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
            ImGui.TableSetupColumn("Description", bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.NoResize), 100)
            ImGui.TableSetupScrollFreeze(0, 1)
            ImGui.TableHeadersRow()
            for i = 1, #task_outline_table do
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                overview_steps[task_outline_table[i].Step] = ImGui.Checkbox("##" .. i, overview_steps[task_outline_table[i].Step])
                ImGui.TableNextColumn()
                if ImGui.Selectable("##a" .. i, false, ImGuiSelectableFlags.None) then
                    State.rewound = true
                    State.skip = true
                    State.step = task_outline_table[i].Step
                    Logger.log_info('\aoSetting step to \ar%s', State.step)
                    Logger.log_verbose("\aoStep type: \ar%s", task_table[State.step].type)
                end
                ImGui.SameLine()
                ImGui.TextColored(IM_COL32(0, 255, 0, 255), task_outline_table[i].Step)
                ImGui.TableNextColumn()
                if ImGui.Selectable("##b" .. i, false, ImGuiSelectableFlags.None) then
                    State.rewound = true
                    State.skip = true
                    State.step = task_outline_table[i].Step
                    Logger.log_info('\aoSetting step to \ar%s', State.step)
                    Logger.log_verbose("\aoStep type: \ar%s", task_table[State.step].type)
                end
                ImGui.SameLine()
                ImGui.TextWrapped(task_outline_table[i].Description)
            end
            ImGui.EndTable()
            ImGui.EndTabItem()
        end
        if State.task_run == true then
            if ImGui.BeginTabItem("Full Outline") then
                ImGui.BeginTable('##outlinetable', 2, treeview_table_flags)
                ImGui.TableSetupColumn("Step", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
                ImGui.TableSetupColumn("Description", bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.NoResize), 100)
                ImGui.TableSetupScrollFreeze(0, 1)
                ImGui.TableHeadersRow()
                for i = 1, #task_table do
                    draw_gui.full_outline_row(task_table[i])
                end
                ImGui.EndTable()
                ImGui.EndTabItem()
            end
        end
        if ImGui.BeginTabItem("Console") then
            local changed
            class_settings.settings.logger.LogLevel, changed = ImGui.Combo("Debug Levels", class_settings.settings.logger.LogLevel, LogLevels, #LogLevels)
            if changed then
                class_settings.saveSettings()
            end

            ImGui.SameLine()
            class_settings.settings.logger.LogToFile, changed = draw_gui.RenderOptionToggle("##log_to_file", "Log to File", class_settings.settings.logger.LogToFile)
            if changed then
                class_settings.saveSettings()
            end

            local cur_x, cur_y = ImGui.GetCursorPos()
            local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
            LogConsole:Render(ImVec2(contentSizeX, math.max(200, (contentSizeY - 10))))
            ImGui.EndTabItem()
        end
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
        table.insert(version_table, word)
    end
    for word in string.gmatch(response, '([^.]+)') do
        table.insert(response_table, word)
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

local function init()
    populate_group_combo()
    step_overview()
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
end

local function main()
    while running == true do
        if start_run == true then
            start_run = false
            State.step = 0
            run_epic(string.lower(mq.TLO.Me.Class.ShortName()), State.epic_choice)
        end
        mq.delay(200)
    end
end

init()
main()
