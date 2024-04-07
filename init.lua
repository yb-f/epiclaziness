local mq = require('mq')
local ImGui = require 'ImGui'
local dist = require 'utils/distance'
local inv = require 'utils/inventory'
local ICONS = require('mq.Icons')
local actions = require 'utils/actions'
local loadsave = require 'utils/loadsave'
local manage = require 'utils/manageautomation'
local class_settings = require 'utils/class_settings'
local invis_travel = require 'utils/travelandinvis'
local quests_done = require 'utils/questsdone'
local reqs = require 'utils/questrequirements'
local tsreqs = require 'utils/tradeskillreqs'
local PackageMan = require('mq/PackageMan')
local sqlite3 = PackageMan.Require('lsqlite3')

local version = 0.016
-- to obtain version_time # os.time(os.date("!*t"))
local version_time = 1712500231
local window_flags = bit32.bor(ImGuiWindowFlags.None)
local treeview_table_flags = bit32.bor(ImGuiTableFlags.Hideable, ImGuiTableFlags.RowBg,
    ImGuiTableFlags.Borders, ImGuiTableFlags.SizingFixedFit)
local openGUI, drawGUI = true, true
local myName = mq.TLO.Me.DisplayName()
local dbn = sqlite3.open(mq.luaDir .. '\\epiclaziness\\epiclaziness.db')
local db_outline = sqlite3.open(mq.luaDir .. '\\epiclaziness\\epiclaziness_outline.db')
local task_table = {}
local task_outline_table = {}
local running = true
local start_run = false
local elheader = "\ay[\agEpic Laziness\ay]"
local stop_at_save = false
local class_list_choice = 1
local changed = false
local myClass = mq.TLO.Me.Class()
local exclude_list = {}
local exclude_name = ''
--local epic_list = { "1.0", "Pre-1.5", "1.5", "2.0" }
local epic_list = quests_done[string.lower(mq.TLO.Me.Class.ShortName())]
local changed = false
local overview_steps = {}

local class_list = { 'Bard', 'Beastlord', 'Berserker', 'Cleric', 'Druid', 'Enchanter', 'Magician', 'Monk', 'Necromancer',
    'Paladin', 'Ranger', 'Rogue', 'Shadow Knight', 'Shaman', 'Warrior', 'Wizard' }

local automation_list = { 'CWTN', 'RGMercs (Lua)', 'RGMercs (Macro)', 'KissAssist', 'MuleAssist' }

local invis_type = {}

State = {}

State.pause = false
State.bind_travel = false
State.task_run = false
State.step = 0
State.status = ''
State.reqs = ''
State.bagslot1 = 0
State.bagslot2 = 0
State.group_combo = {}
State.group_choice = 1
State.use_cwtn = false
State.use_ka = false
State.use_rgl = false
State.epic_choice = 1
State.farming = false
State.nextmob = false
State.epicstring = ''
State.X, State.Y, State.Z = 0, 0, 0
State.skip = false
State.rewound = false
State.bad_IDs = {}
State.cannot_count = 0
State.traveling = false

--Messages that people will ignore
printf(
    "%s \aoif you encounter any nav mesh issues please insure you are using the latest mesh from \arhttps://github.com/yb-f/meshes",
    elheader)
local t = os.time(os.date("!*t"))
if version_time + 64800 < t then
    printf("%s \aoThis version is more than 18 hours old.  \arPlease check to see if an updated version is available.",
        elheader)
end

--Check if necessary plugins are loaded.
if mq.TLO.Plugin('mq2nav')() == nil then
    printf("%s \arMQ2Nav \aois required for this script.", elheader)
    printf("%s \aoPlease load it with the command \ar/plugin nav \aoand rerun this script.", elheader)
    mq.exit()
end
if mq.TLO.Plugin('mq2easyfind')() == nil then
    printf("%s \arMQ2EasyFind \aois required for this script.", elheader)
    printf("%s \aoPlease load it with the command \ar/plugin easyfind \aoand rerun this script.", elheader)
    mq.exit()
end
if mq.TLO.Plugin('mq2relocate')() == nil then
    printf("%s \arMQ2Relocate \aois required for this script.", elheader)
    printf("%s \aoPlease load it with the command \ar/plugin relocate \aoand rerun this script.", elheader)
    mq.exit()
end
if mq.TLO.Plugin('mq2portalsetter')() == nil then
    printf("%s \arMQ2PortalSetter \aois required for this script.", elheader)
    printf("%s \aoPlease load it with the command \ar/plugin portalsetter \aoand rerun this script.", elheader)
    mq.exit()
end

class_settings.loadSettings()

local function step_overview()
    task_outline_table = {}
    local class = string.lower(mq.TLO.Me.Class.ShortName())
    local choice = State.epic_choice
    local tablename = ''
    local quest = ''
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
        printf('%s \ao This class and quest has not yet been implemented.', elheader)
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
                        return_string = elheader ..
                            " \ar" ..
                            ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.Skill(ts)()
                    else
                        return_string = return_string .. "\n" ..
                            elheader ..
                            " \ar" ..
                            ts .. " \aorequires \ar" .. req .. " \aoskill. Currently \ar" .. mq.TLO.Me.Skill(ts)()
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
        printf('%s \aoThis class and quest has not yet been implemented.', elheader)
        State.task_run = false
        return
    end
    local ts_return = check_tradeskills(class, choice)
    if ts_return then
        print(ts_return)
        if class_settings.settings.general.stopTS == true then
            printf(
                '%s \aoPlease raise your tradeskills to continue, or turn off the "\agStop if tradeskill requirements are unmet\ao" setting.',
                elheader)
            State.task_run = false
        end
    end
    local sql = "SELECT * FROM " .. tablename
    for a in dbn:nrows(sql) do
        table.insert(task_table, a)
    end
    manage.startGroup(State.group_choice, class_settings.settings)
    mq.delay("5s")
    manage.pauseGroup(State.group_choice, class_settings.settings)
    while State.step < #task_table do
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
        if task_table[State.step].type == "AUTO_INV" then
            actions.auto_inv(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "BACKSTAB" then
            actions.backstab(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "CAST_ALT" then
            actions.cast_alt(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "COMBINE_CONTAINER" then
            actions.combine_container(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "COMBINE_DO" then
            actions.combine_do(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "COMBINE_DONE" then
            actions.combine_done(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "COMBINE_ITEM" then
            actions.combine_item(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "ENVIRO_COMBINE_CONTAINER" then
            actions.enviro_combine_container(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "ENVIRO_COMBINE_DO" then
            actions.enviro_combine_do(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "ENVIRO_COMBINE_ITEM" then
            actions.enviro_combine_item(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "EQUIP_ITEM" then
            inv.equip_item(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "EXCLUDE_NPC" then
            exclude_name = task_table[State.step].npc
            create_spawn_list()
        elseif task_table[State.step].type == "EXECUTE_COMMAND" then
            if mq.TLO.Me.XTarget() > 0 then
                for i = 1, mq.TLO.Me.XTargetSlots() do
                    if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                        manage.clearXtarget(State.group_choice, class_settings.settings)
                    end
                end
            end
            mq.cmdf("%s", task_table[State.step].what)
            mq.delay(500)
        elseif task_table[State.step].type == "FACE_HEADING" then
            actions.face_heading(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "FACE_LOC" then
            actions.face_loc(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "FARM_CHECK" then
            actions.farm_check(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "FARM_CHECK_PAUSE" then
            actions.farm_check_pause(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "FARM_RADIUS" then
            actions.farm_radius(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "FORAGE_FARM" then
            actions.forage_farm(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "FORWARD_ZONE" then
            actions.forward_zone(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "GENERAL_SEARCH" then
            actions.general_search(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "GENERAL_TRAVEL" then
            actions.general_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "GROUND_SPAWN" then
            actions.ground_spawn(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "IGNORE_MOB" then
            actions.ignore_mob(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "LOC_TRAVEL" then
            actions.loc_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "LOOT" then
            if mq.TLO.Me.XTarget() > 0 then
                for i = 1, mq.TLO.Me.XTargetSlots() do
                    if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                        manage.clearXtarget(State.group_choice, class_settings.settings)
                    end
                end
            end
            actions.loot(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NO_NAV_TRAVEL" then
            actions.no_nav_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_BUY" then
            actions.npc_buy(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_DAMAGE_UNTIL" then
            actions.npc_damage_until(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_FOLLOW" then
            actions.npc_follow(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_GIVE" then
            actions.npc_give(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_GIVE_ADD" then
            actions.npc_give_add(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_GIVE_CLICK" then
            actions.npc_give_click(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_GIVE_MONEY" then
            actions.npc_give_money(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_HAIL" then
            actions.npc_hail(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_KILL" then
            actions.npc_kill(task_table[State.step], class_settings.settings, task_table[State.step + 1].type)
        elseif task_table[State.step].type == "NPC_KILL_ALL" then
            actions.npc_kill_all(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_SEARCH" then
            actions.npc_search(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_STOP_FOLLOW" then
            actions.npc_stop_follow(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_TALK" then
            actions.npc_talk(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_TALK_ALL" then
            if mq.TLO.Me.XTarget() > 0 then
                for i = 1, mq.TLO.Me.XTargetSlots() do
                    if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                        manage.clearXtarget(State.group_choice, class_settings.settings)
                    end
                end
            end
            actions.npc_talk_all(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_TRAVEL" then
            actions.npc_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_TRAVEL_NO_PATH_CHECK" then
            actions.npc_travel(task_table[State.step], class_settings.settings, true)
        elseif task_table[State.step].type == "NPC_WAIT" then
            actions.npc_wait(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_WAIT_DESPAWN" then
            actions.npc_wait_despawn(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "OPEN_DOOR" then
            actions.open_door(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "OPEN_DOOR_ALL" then
            actions.open_door_all(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "PH_SEARCH" then
            actions.ph_search(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "PICK_DOOR" then
            actions.picklock_door(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "PICK_POCKET" then
            actions.pickpocket(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "PICKUP_KEY" then
            mq.cmdf("/squelch /itemnotify \"%s\" leftmouseup", task_table[State.step].what)
        elseif task_table[State.step].type == "PORTAL_SET" then
            actions.portal_set(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "PRE_FARM_CHECK" then
            actions.pre_farm_check(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "RELOCATE" then
            actions.relocate(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "REMOVE_INVIS" then
            actions.remove_invis(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "RESTORE_ITEM" then
            inv.restore_item()
        elseif task_table[State.step].type == "ROG_GAMBLE" then
            actions.rog_gamble(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "SEND_YES" then
            actions.send_yes(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "WAIT" then
            State.status = "Pausing for " .. task_table[State.step].what / 1000 .. " seconds"
            actions.wait(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "WAIT_EVENT" then
            actions.wait_event(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "ZONE_CONTINUE_TRAVEL" then
            actions.zone_continue_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "ZONE_TRAVEL" then
            State.bad_IDs = {}
            actions.zone_travel(task_table[State.step], class_settings.settings)
        else
            printf("%s \aoUnknown Type: \ar%s!", elheader, task_table[State.step].type)
            mq.exit()
        end
        if task_table[State.step].belev == nil then
            manage.removeLev(State.group_choice)
        end
        if task_table[State.step].SaveStep == 1 then
            printf("%s \aosaving step: \ar%s", elheader, State.step)
            loadsave.prepSave(State.step)
            if stop_at_save then
                printf("%s \aoStopping.", elheader)
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
    printf("%s \aoCompleted!", elheader)
end

local function displayGUI()
    if not openGUI then
        running = false
        mq.exit()
        return
    end
    ImGui.SetNextWindowSize(ImVec2(415, 475), ImGuiCond.FirstUseEver)
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
                    printf("%s \aoMoving to previous step \ar%s", elheader, State.step)
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip("Move to previous step.")
                end
                ImGui.SameLine()
                if State.pause == false then
                    if ImGui.SmallButton(ICONS.MD_PAUSE) then
                        State.pause = true
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetTooltip("Pause script.")
                    end
                else
                    if ImGui.SmallButton(ICONS.FA_PLAY) then
                        State.pause = false
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetTooltip("Resume script.")
                    end
                end
                ImGui.SameLine()
                if ImGui.SmallButton(ICONS.MD_FAST_FORWARD) then
                    State.skip = true
                    State.step = State.step + 1
                    printf("%s \aoSkipping to step \ar%s", elheader, State.step)
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip("Skip to next step.")
                end
                if ImGui.Button("Stop @ Next Save") then
                    printf("%s \aoStopping at next save point.", elheader)
                    stop_at_save = true
                end
            end
            ImGui.Separator()
            ImGui.Text("Step " .. tostring(State.step) .. " of " .. tostring(#task_table))
            ImGui.TextWrapped(State.status)
            for i = 1, 3 do
                ImGui.NewLine()
            end
            ImGui.TextWrapped(State.reqs)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Settings") then
            if ImGui.CollapsingHeader('General Settings') then
                class_settings.settings.general.stopTS = ImGui.Checkbox("Stop if tradeskill requirements are unmet",
                    class_settings.settings.general.stopTS)
                class_settings.settings.general.returnToBind = ImGui.Checkbox("Return to Bind Between Travel",
                    class_settings.settings.general.returnToBind)
                class_settings.settings.general.invisForTravel = ImGui.Checkbox("Invis When Travelling",
                    class_settings.settings.general.invisForTravel)
                if ImGui.Button("Save") then
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
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Outline") then
            ImGui.BeginTable('##table1', 3, treeview_table_flags)
            ImGui.TableSetupColumn("Manual Completion", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
            ImGui.TableSetupColumn("Step", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
            ImGui.TableSetupColumn("Description",
                bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.NoResize), 100)
            ImGui.TableSetupScrollFreeze(0, 1)
            ImGui.TableHeadersRow()
            for i = 1, #task_outline_table do
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                overview_steps[task_outline_table[i].Step] = ImGui.Checkbox("##" .. i,
                    overview_steps[task_outline_table[i].Step])
                ImGui.TableNextColumn()
                if ImGui.Selectable("##a" .. i, false, ImGuiSelectableFlags.None) then
                    printf("%s \aoSetting step to \ar%s", elheader, task_outline_table[i].Step)
                    State.rewound = true
                    State.step = task_outline_table[i].Step
                end
                ImGui.SameLine()
                ImGui.TextColored(IM_COL32(0, 255, 0, 255), task_outline_table[i].Step)
                ImGui.TableNextColumn()
                if ImGui.Selectable("##b" .. i, false, ImGuiSelectableFlags.None) then
                    printf("%s \aoSetting step to \ar%s", elheader, task_outline_table[i].Step)
                    State.rewound = true
                    State.step = task_outline_table[i].Step
                end
                ImGui.SameLine()
                ImGui.TextWrapped(task_outline_table[i].Description)
            end
            ImGui.EndTable()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
    ImGui.End()
end

populate_group_combo()
loadsave.loadState()
step_overview()
mq.imgui.init('displayGUI', displayGUI)

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

main()
