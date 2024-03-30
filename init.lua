local mq = require('mq')
local ImGui = require 'ImGui'
local sqlite3 = require('lsqlite3')
local dist = require 'utils/distance'
local inv = require 'utils/inventory'
local ICONS = require('mq.Icons')
local actions = require 'utils/actions'
local loadsave = require 'utils/loadsave'
local manage = require 'utils/manageautomation'
local class_settings = require 'utils/class_settings'
local invis_travel = require 'utils/travelandinvis'

local window_flags = bit32.bor(ImGuiWindowFlags.None)
local openGUI, drawGUI = true, true
local myName = mq.TLO.Me.DisplayName()
local epic_list = { "1.0", "Pre-1.5", "1.5", "2.0" }
local dbn = sqlite3.open(mq.luaDir .. '\\epiclaziness\\epiclaziness.db')
local task_table = {}
local running = true
local start_run = false
local elheader = "\ay[\agEpic Laziness\ay]"
local stop_at_save = false
local class_list_choice = 1
local changed = false
local myClass = mq.TLO.Me.Class()
local exclude_list = {}
local exclude_name = ''

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
State.bad_IDs = {}
State.cannot_count = 0
State.traveling = false

class_settings.loadSettings()

local function matchFilters(spawn)
    if string.find(string.lower(spawn.Name()), string.lower(exclude_name)) then return true end
    return false
end

local function create_spawn_list()
    exclude_list = mq.getFilteredSpawns(matchFilters)
    for _, spawn in pairs(exclude_list) do
        print(spawn.Name())
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

local function run_epic(class, choice)
    task_table = {}
    State.task_run = true
    loadsave.loadState()
    manage.startGroup(State.group_choice, class_settings.settings)
    mq.delay("5s")
    manage.pauseGroup(State.group_choice, class_settings.settings)
    local tablename = ''
    if choice == 1 then
        tablename = class .. "_10"
        State.epicstring = "1.0"
    elseif choice == 2 then
        tablename = class .. "_pre15"
        State.epicstring = "Pre-1.5"
    elseif choice == 3 then
        tablename = class .. "_15"
        State.epicstring = "1.5"
    elseif choice == 4 then
        tablename = class .. "_20"
        State.epicstring = "2.0"
    end
    local sql = "SELECT * FROM " .. tablename
    for a in dbn:nrows(sql) do
        table.insert(task_table, a)
    end
    while State.step < #task_table do
        while State.pause == true do
            mq.delay(500)
        end
        State.skip = false
        State.step = State.step + 1
        if task_table[State.step].type == "ZONE_TRAVEL" then
            State.bad_IDs = {}
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.zone_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_TRAVEL" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.npc_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "GENERAL_TRAVEL" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.general_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_KILL" then
            actions.npc_kill(task_table[State.step], class_settings.settings, task_table[State.step + 1].type)
        elseif task_table[State.step].type == "NPC_KILL_ALL" then
            actions.npc_kill_all(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_WAIT" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.npc_wait(task_table[State.step])
        elseif task_table[State.step].type == "NPC_TALK" then
            actions.npc_talk(task_table[State.step])
        elseif task_table[State.step].type == "NPC_GIVE" then
            actions.npc_give(task_table[State.step])
        elseif task_table[State.step].type == "AUTO_INV" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.auto_inv(task_table[State.step])
        elseif task_table[State.step].type == "NPC_HAIL" then
            actions.npc_hail(task_table[State.step])
        elseif task_table[State.step].type == "EXCLUDE_NPC" then
            exclude_name = task_table[State.step].npc
            create_spawn_list()
        elseif task_table[State.step].type == "NPC_FOLLOW" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.npc_follow(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "PRE_FARM_CHECK" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.pre_farm_check(task_table[State.step])
        elseif task_table[State.step].type == "FARM_CHECK" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.farm_check(task_table[State.step])
        elseif task_table[State.step].type == "COMBINE_CONTAINER" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.combine_container(task_table[State.step])
        elseif task_table[State.step].type == "COMBINE_ITEM" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.combine_item(task_table[State.step])
        elseif task_table[State.step].type == "COMBINE_DO" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.combine_do(task_table[State.step])
        elseif task_table[State.step].type == "COMBINE_DONE" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.combine_done(task_table[State.step])
        elseif task_table[State.step].type == "GROUND_SPAWN" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.ground_spawn(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "LOOT" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.loot(task_table[State.step])
        elseif task_table[State.step].type == "ROG_GAMBLE" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.rog_gamble(task_table[State.step])
        elseif task_table[State.step].type == "NPC_SEARCH" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.npc_search(task_table[State.step])
        elseif task_table[State.step].type == "GENERAL_SEARCH" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.general_search(task_table[State.step])
        elseif task_table[State.step].type == "PH_SEARCH" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.ph_search(task_table[State.step])
        elseif task_table[State.step].type == "LOC_TRAVEL" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.loc_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "OPEN_DOOR" then
            actions.open_door(task_table[State.step])
        elseif task_table[State.step].type == "OPEN_DOOR_ALL" then
            actions.open_door_all(task_table[State.step])
        elseif task_table[State.step].type == "FACE_HEADING" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.face_heading(task_table[State.step])
        elseif task_table[State.step].type == "NO_NAV_TRAVEL" then
            actions.no_nav_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "CAST_ALT" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.cast_alt(task_table[State.step])
        elseif task_table[State.step].type == "PICK_DOOR" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.picklock_door(task_table[State.step])
        elseif task_table[State.step].type == "PICK_POCKET" then
            actions.pickpocket(task_table[State.step])
        elseif task_table[State.step].type == "BACKSTAB" then
            actions.backstab(task_table[State.step])
        elseif task_table[State.step].type == "WAIT" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            State.status = "Pausing for " .. task_table[State.step].what / 1000 .. " seconds"
            mq.delay(tonumber(task_table[State.step].what))
        elseif task_table[State.step].type == "NPC_GIVE_ADD" then
            actions.npc_give_add(task_table[State.step])
        elseif task_table[State.step].type == "NPC_GIVE_MONEY" then
            actions.npc_give_money(task_table[State.step])
        elseif task_table[State.step].type == "NPC_GIVE_CLICK" then
            actions.npc_give_click(task_table[State.step])
        elseif task_table[State.step].type == "NPC_STOP_FOLLOW" then
            actions.npc_stop_follow(task_table[State.step])
        elseif task_table[State.step].type == "FARM_RADIUS" then
            actions.farm_radius(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_TALK_ALL" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.npc_talk_all(task_table[State.step])
        elseif task_table[State.step].type == "ZONE_CONTINUE_TRAVEL" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.zone_continue_travel(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "FACE_LOC" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.face_loc(task_table[State.step])
        elseif task_table[State.step].type == "NPC_BUY" then
            actions.npc_buy(task_table[State.step])
        elseif task_table[State.step].type == "NPC_WAIT_DESPAWN" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.npc_wait_despawn(task_table[State.step])
        elseif task_table[State.step].type == "FORWARD_ZONE" then
            actions.forward_zone(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "NPC_WAIT_DESPAWN" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.npc_wait_despawn(task_table[State.step])
        elseif task_table[State.step].type == "IGNORE_MOB" then
            actions.ignore_mob(task_table[State.step], class_settings.settings)
        elseif task_table[State.step].type == "EXECUTE_COMMAND" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            mq.cmdf("%s", task_table[State.step].what)
            mq.delay(500)
        elseif task_table[State.step].type == "SEND_YES" then
            actions.send_yes(task_table[State.step])
        elseif task_table[State.step].type == "PORTAL_SET" then
            actions.portal_set(task_table[State.step])
        elseif task_table[State.step].type == "FARM_CHECK_PAUSE" then
            actions.farm_check_pause(task_table[State.step])
        elseif task_table[State.step].type == "WAIT_EVENT" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.wait_event(task_table[State.step])
        elseif task_table[State.step].type == "FORAGE_FARM" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.forage_farm(task_table[State.step])
        elseif task_table[State.step].type == "NPC_DAMAGE_UNTIL" then
            actions.npc_damage_until(task_table[State.step])
        elseif task_table[State.step].type == "RELOCATE" then
            if mq.TLO.Me.XTarget() > 0 then
                actions.clear_xtarget(class_settings.settings)
            end
            actions.relocate(task_table[State.step])
        elseif task_table[State.step].type == "ENVIRO_COMBINE_CONTAINER" then
            actions.enviro_combine_container(task_table[State.step])
        elseif task_table[State.step].type == "ENVIRO_COMBINE_ITEM" then
            actions.enviro_combine_item(task_table[State.step])
        elseif task_table[State.step].type == "ENVIRO_COMBINE_DO" then
            actions.enviro_combine_do(task_table[State.step])
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
                return
            end
        end
        if State.task_run == false then
            return
        end
    end
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
                State.epic_choice = ImGui.Combo('##Combo', State.epic_choice, epic_list)
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('Which Epic to run')
                end
            end
            if mq.TLO.Me.Grouped() == true then
                State.group_choice = ImGui.Combo('##Group_Combo', State.group_choice, State.group_combo)
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('Who should come with you (None, Group, Individual group member)')
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
                    local tooltip = "Begin/resume epic quest\nThis may require up to " ..
                        invis_num .. " invis potions.\nThis may require up to " .. gate_num .. " gate potions."
                    ImGui.SetTooltip(tooltip)
                end
            end
            if State.task_run == true then
                if State.pause == false then
                    if ImGui.SmallButton(ICONS.MD_PAUSE) then
                        State.pause = true
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetTooltip("Pause before begining next step.")
                    end
                else
                    if ImGui.SmallButton(ICONS.FA_PLAY) then
                        State.pause = false
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetTooltip("Resume")
                    end
                end
                ImGui.SameLine()
                if ImGui.SmallButton(ICONS.MD_FAST_FORWARD) then
                    State.skip = true
                    State.step = State.step + 1
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip("Next Step")
                end
                if ImGui.Button("Stop @ Next Save") then
                    printf("%s \aoStopping at next save point.", elheader)
                    stop_at_save = true
                end
            end
            ImGui.Separator()
            ImGui.Text("Step " .. tostring(State.step) .. " of " .. tostring(#task_table))
            ImGui.Text(State.status)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Settings") then
            if ImGui.CollapsingHeader('General Settings') then
                class_settings.settings.general.useAOC = ImGui.Checkbox("Use Agent of Change",
                    class_settings.settings.general.useAOC)
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
        ImGui.EndTabBar()
    end
    ImGui.End()
end

populate_group_combo()
loadsave.loadState()
mq.imgui.init('displayGUI', displayGUI)

local function main()
    while running == true do
        if start_run == true then
            start_run = false
            State.step = 0
            run_epic(mq.TLO.Me.Class.ShortName(), State.epic_choice)
        end
        mq.delay(200)
    end
end

main()
