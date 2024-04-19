local mq                   = require('mq')
local ICONS                = require('mq.Icons')
local invis_travel         = require 'utils/travelandinvis'

local LogLevels            = {
    "Errors",
    "Warnings",
    "Info",
    "Debug",
    "Verbose",
    "Super-Verbose",
}

local draw_gui             = {}
local class_list_choice    = 1
local class_list           = { 'Bard', 'Beastlord', 'Berserker', 'Cleric', 'Druid', 'Enchanter', 'Magician', 'Monk', 'Necromancer', 'Paladin', 'Ranger', 'Rogue', 'Shadow Knight',
    'Shaman', 'Warrior', 'Wizard' }
local changed              = false
local automation_list      = { 'CWTN', 'RGMercs (Lua)', 'RGMercs (Macro)', 'KissAssist', 'MuleAssist' }
local invis_type           = {}
local treeview_table_flags = bit32.bor(ImGuiTableFlags.Hideable, ImGuiTableFlags.RowBg, ImGuiTableFlags.Borders, ImGuiTableFlags.SizingFixedFit, ImGuiTableFlags.ScrollX)
local myClass              = mq.TLO.Me.Class()

function draw_gui.full_outline_row(item)
    local step, outlineText = draw_gui.generate_outline_text(item)
    ImGui.TableNextRow()
    ImGui.TableNextColumn()
    if ImGui.Selectable("##c" .. step, false, ImGuiSelectableFlags.None) then
        State.rewound = true
        State.skip = true
        State.step = step
        Logger.log_info('\aoSetting step to \ar%s', State.step)
        Logger.log_verbose("\aoStep type: \ar%s", item.type)
    end
    ImGui.SameLine()
    local color = IM_COL32(0, 0, 0, 0)
    if step == State.step then
        color = IM_COL32(255, 255, 255, 255)
    elseif step < State.step then
        color = IM_COL32(255, 0, 0, 255)
    elseif step > State.step then
        color = IM_COL32(0, 255, 0, 255)
    end
    --Logger.log_super_verbose("\aoProcessing step \ag%s\ao.", step)
    ImGui.TextColored(color, tostring(step))
    ImGui.TableNextColumn()
    if ImGui.Selectable("##d" .. step, false, ImGuiSelectableFlags.None) then
        State.rewound = true
        State.step = step
        Logger.log_info('\aoSetting step to \ar%s', step)
        Logger.log_verbose("\aoStep type: \ar%s", item.type)
    end
    ImGui.SameLine()
    ImGui.TextWrapped(outlineText)
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


function draw_gui.consoleTab(class_settings)
    if ImGui.BeginTabItem("Console") then
        local changed
        class_settings.settings.logger.LogLevel, changed = ImGui.Combo("Debug Levels", class_settings.settings.logger.LogLevel, LogLevels, #LogLevels)
        if changed then
            Logger.set_log_level(class_settings.settings.logger.LogLevel)
            class_settings.saveSettings()
        end

        ImGui.SameLine()
        class_settings.settings.logger.LogToFile, changed = draw_gui.RenderOptionToggle("##log_to_file", "Log to File", class_settings.settings.logger.LogToFile)
        if changed then
            class_settings.saveSettings()
        end

        local cur_x, cur_y = ImGui.GetCursorPos()
        local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
        Logger.LogConsole:Render(ImVec2(contentSizeX, math.max(200, (contentSizeY - 10))))
        ImGui.EndTabItem()
    end
end

function draw_gui.fullOutlineTab(task_table)
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

function draw_gui.pathUpdate()
    if math.floor(mq.gettime() / 1000) > State.updateTime then
        local path = string.format("%s %s", State.destType, State.dest)
        State.pathDist = mq.TLO.Navigation.PathLength(path)()
        State.velocity = mq.TLO.Navigation.Velocity()
        State.estimatedTime = State.pathDist / State.velocity
    end
end

function draw_gui.generalTab(task_table)
    if ImGui.BeginTabItem("General") then
        ImGui.Text("Class: " .. myClass .. " " .. State.epicstring)
        if State.task_run == false then
            State.epic_choice, changed = ImGui.Combo('##Combo', State.epic_choice, State.epic_list, #State.epic_list, #State.epic_list)
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip('Which epic to run.')
            end
            if changed == true then
                State.step_overview()
            end
        end
        if mq.TLO.Me.Grouped() == true then
            State.group_choice = ImGui.Combo('##Group_Combo', State.group_choice, State.group_combo)
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip('Who should come with you (None. Full group. Individual group member.)')
            end
            ImGui.SameLine()
            if ImGui.SmallButton(ICONS.MD_REFRESH) then
                State.populate_group_combo()
            end
        end
        if State.task_run == false then
            if ImGui.Button("Begin") then
                State.start_run = true
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
                State.stop_at_save = true
            end
        end
        ImGui.Separator()
        ImGui.PushStyleColor(ImGuiCol.PlotHistogram, IM_COL32(40, 150, 40, 255))
        ImGui.ProgressBar(State.step / #task_table, ImGui.GetWindowWidth(), 17, "##prog")
        ImGui.PopStyleColor()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 20)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetWindowWidth() / 2) - 60)
        ImGui.Text("Step " .. tostring(State.step) .. " of " .. tostring(#task_table))
        if State.destType ~= '' then
            draw_gui.pathUpdate()
            local travelPct = 1.0 - (State.pathDist / State.startDist)
            local travelText = string.format("Distance: %s Velocity: %s ETA: %s seconds", math.floor(State.pathDist), math.floor(State.velocity), math.floor(State.estimatedTime))
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram, IM_COL32(150, 150, 40, 255))
            ImGui.ProgressBar(travelPct, ImGui.GetWindowWidth(), 17, "##dist")
            ImGui.PopStyleColor()
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 20)
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetWindowWidth() / 2) - 115)
            ImGui.Text(travelText)
        end
        ImGui.TextWrapped(State.status)
        ImGui.NewLine()
        ImGui.TextWrapped(State.status2)
        ImGui.NewLine()
        ImGui.TextWrapped(State.reqs)
        ImGui.EndTabItem()
    end
end

function draw_gui.outlineTab(task_outline_table, overview_steps, task_table)
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
                if State.task_run == true then
                    State.rewound = true
                    State.skip = true
                    State.step = task_outline_table[i].Step
                    Logger.log_info('\aoSetting step to \ar%s', State.step)
                    Logger.log_verbose("\aoStep type: \ar%s", task_table[State.step].type)
                end
            end
            ImGui.SameLine()
            ImGui.TextColored(IM_COL32(0, 255, 0, 255), task_outline_table[i].Step)
            ImGui.TableNextColumn()
            if ImGui.Selectable("##b" .. i, false, ImGuiSelectableFlags.None) then
                if State.task_run == true then
                    State.rewound = true
                    State.skip = true
                    State.step = task_outline_table[i].Step
                    Logger.log_info('\aoSetting step to \ar%s', State.step)
                    Logger.log_verbose("\aoStep type: \ar%s", task_table[State.step].type)
                end
            end
            ImGui.SameLine()

            ImGui.TextWrapped(task_outline_table[i].Description)
        end
        ImGui.EndTable()
        ImGui.EndTabItem()
    end
end

function draw_gui.settingsTab(themeName, theme, themeID, class_settings, char_settings)
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
            char_settings.SaveState.general.stopTS = draw_gui.RenderOptionToggle("##ts_setting", "Stop if tradeskill requirements are unmet", char_settings.SaveState.general.stopTS)
            char_settings.SaveState.general.returnToBind = draw_gui.RenderOptionToggle("##bind_setting", "Return to bind between travel steps",
                char_settings.SaveState.general.returnToBind)
            char_settings.SaveState.general.invisForTravel = draw_gui.RenderOptionToggle("##invis_setting", "Invis while traveling", char_settings.SaveState.general.invisForTravel)
            char_settings.SaveState.general.speedForTravel = draw_gui.RenderOptionToggle("##speed_setting", "Use travel speed skills", char_settings.SaveState.general
                .speedForTravel)
            ImGui.PushItemWidth(120)
            char_settings.SaveState.general.xtargClear = ImGui.InputInt("Number of mobs to clear XTarget list.",
                char_settings.SaveState.general.xtargClear)
            ImGui.PopItemWidth()
            if ImGui.Button("Save") then
                char_settings.saveState()
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
            ImGui.PushItemWidth(160)
            class_settings.settings.class[class_list[class_list_choice]], changed = ImGui.Combo('##AutomationType',
                class_settings.settings.class[class_list[class_list_choice]], automation_list, #automation_list,
                #automation_list)
            ImGui.PopItemWidth()
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
            if class_settings.settings.move_speed[class_list[class_list_choice]] then
                local speed_type = {}
                for word in string.gmatch(class_settings.settings.move_speed[class_list[class_list_choice]], '([^|]+)') do
                    table.insert(speed_type, word)
                end
                class_settings.settings.speed[class_list[class_list_choice]], changed = ImGui.Combo('##SpeedType', class_settings.settings.speed[class_list[class_list_choice]],
                    speed_type, #speed_type, #speed_type)
                if changed then
                    changed = false
                    class_settings.saveSettings()
                end
            end
            ImGui.EndTable()
        end
        ImGui.EndChild()
        ImGui.EndTabItem()
    end
    return theme.LoadTheme, themeName, themeID, class_settings.settings.LoadTheme
end

--- @return number
--- @return string
function draw_gui.generate_outline_text(item)
    local step = item.step
    local text = ''
    if item.type == 'ADVENTURE_ENTRANCE' then
        text = 'Determine which LDON entrance to use.'
    elseif item.type == "AUTO_INV" then
        text = "Move item on cursor to inventory"
    elseif item.type == "BACKSTAB" then
        text = "Backstab " .. item.npc
    elseif item.type == "CAST_ALT" then
        text = "Cast alt ability " .. item.what
    elseif item.type == "COMBINE_CONTAINER" then
        text = "Prepare to combine items in " .. item.what
    elseif item.type == "COMBINE_DO" then
        text = "Peform combine"
    elseif item.type == "COMBINE_DONE" then
        text = "Combine complete, restore item to bag slot 8"
    elseif item.type == "COMBINE_ITEM" then
        text = "Add " .. item.what .. " to combine container"
    elseif item.type == "ENVIRO_COMBINE_CONTAINER" then
        text = "Travel to " .. item.what .. " and prepare combine"
    elseif item.type == "ENVIRO_COMBINE_DO" then
        text = "Perform combine in enviromental container"
    elseif item.type == "ENVIRO_COMBINE_ITEM" then
        text = "Add " .. item.what .. " to enviromental combine container"
    elseif item.type == "EQUIP_ITEM" then
        text = "Equip " .. item.what
    elseif item.type == "EXCLUDE_NPC" then
        text = "Exclude " .. item.npc .. " from pull list"
    elseif item.type == "EXECUTE_COMMAND" then
        text = "Execute command: " .. item.what
    elseif item.type == "FACE_HEADING" then
        text = "Face the heading " .. item.what
    elseif item.type == "FACE_LOC" then
        text = "Face location " .. item.whereY .. ", " .. item.whereX .. ", " .. item.whereZ
    elseif item.type == "FARM_CHECK" then
        text = "Check if we have the items we need: " .. item.what
    elseif item.type == "FARM_CHECK_PAUSE" then
        text = "Check if we have " .. item.what .. " pause script of we do not"
    elseif item.type == "FARM_RADIUS" then
        text = "Farm for " .. item.what
    elseif item.type == "FISH_FARM" then
        text = "Fish for " .. item.what
    elseif item.type == "FISH_ONCE" then
        text = "Fish for one cast"
    elseif item.type == "FORAGE_FARM" then
        text = "Forage for " .. item.what
    elseif item.type == "FORWARD_ZONE" then
        text = "Move forward to zone into " .. item.zone
    elseif item.type == "GENERAL_SEARCH" then
        text = "Searching for " .. item.npc
    elseif item.type == "GENERAL_TRAVEL" then
        text = "Travel to " .. item.npc
    elseif item.type == "GROUND_SPAWN" then
        text = "Pickup ground spawn at " .. item.whereY .. ", " .. item.whereX .. ", " .. item.whereZ
    elseif item.type == "IGNORE_MOB" then
        text = "Add " .. item.npc .. " to pull ignore list"
    elseif item.type == "LOC_TRAVEL" then
        text = "Travel to " .. item.whereY .. ", " .. item.whereX .. ", " .. item.whereZ
    elseif item.type == "LOOT" then
        text = "Attempt to loot " .. item.what
    elseif item.type == "NO_NAV_TRAVEL" then
        text = "Travel without using MQ2Nav to " .. item.whereY .. ", " .. item.whereX .. ", " .. item.whereZ
    elseif item.type == "NPC_BUY" then
        text = "Purchase " .. item.what .. " from " .. item.npc
    elseif item.type == "NPC_DAMAGE_UNTIL" then
        text = "Damage " .. item.npc .. " to " .. item.what .. "% health"
    elseif item.type == "NPC_FOLLOW" then
        text = "Follow " .. item.npc
    elseif item.type == "NPC_GIVE" then
        text = "Give " .. item.what .. " to " .. item.npc
    elseif item.type == "NPC_GIVE_ADD" then
        text = "Add " .. item.what .. " to give window with " .. item.npc
    elseif item.type == "NPC_GIVE_CLICK" then
        text = "Click give button"
    elseif item.type == "NPC_GIVE_MONEY" then
        text = "Give money (" .. item.what .. ") to " .. item.npc
    elseif item.type == "NPC_HAIL" then
        text = "Hail " .. item.npc
    elseif item.type == "NPC_KILL" then
        text = "Kill " .. item.npc
    elseif item.type == "NPC_KILL_ALL" then
        text = "Kill all " .. item.npc
    elseif item.type == "NPC_SEARCH" then
        text = "Look for " .. item.npc
    elseif item.type == "NPC_STOP_FOLLOW" then
        text = "Stop following " .. item.npc
    elseif item.type == "NPC_TALK" then
        text = "Say " .. item.what .. " to " .. item.npc
    elseif item.type == "NPC_TALK_ALL" then
        text = "Have all characters say " .. item.what .. " to " .. item.npc
    elseif item.type == "NPC_TRAVEL" then
        text = "Move to " .. item.npc
    elseif item.type == "NPC_TRAVEL_NO_PATH_CHECK" then
        text = "Move to " .. item.npc
    elseif item.type == "NPC_WAIT" then
        text = "Wait for " .. item.npc .. " to spawn"
    elseif item.type == "NPC_WAIT_DESPAWN" then
        text = "Wait for " .. item.npc .. " to despawn"
    elseif item.type == "OPEN_DOOR" then
        text = "Open door"
    elseif item.type == "OPEN_DOOR_ALL" then
        text = "Group click door"
    elseif item.type == "PH_SEARCH" then
        text = "Search for PH " .. item.npc
    elseif item.type == "PICK_DOOR" then
        text = "Attempt to lockpick door"
    elseif item.type == "PICK_POCKET" then
        text = "Pickpocket " .. item.what .. " from " .. item.npc
    elseif item.type == "PICKUP_KEY" then
        text = "Move key from inventory to cursor"
    elseif item.type == "PORTAL_SET" then
        text = "Set guild portal location to " .. item.zone
    elseif item.type == "PRE_FARM_CHECK" then
        text = "Check if we have the items to skip the next steps"
    elseif item.type == "RELOCATE" then
        text = "Relocate to " .. item.what
    elseif item.type == "REMOVE_INVIS" then
        text = "Remove invisibility"
    elseif item.type == "RESTORE_ITEM" then
        text = "Reequip item"
    elseif item.type == "ROG_GAMBLE" then
        text = "Gamble to 1900 chips"
    elseif item.type == "START_ADVENTURE" then
        text = "Request LDON adventure from " .. item.npc
    elseif item.type == "SEND_YES" then
        text = "Select yes in confirmation box"
    elseif item.type == "WAIT" then
        text = "Wait for " .. item.what / 1000 .. " seconds"
    elseif item.type == "WAIT_EVENT" then
        text = "Wait for event in chat to continue"
    elseif item.type == "ZONE_CONTINUE_TRAVEL" then
        text = "Travel to " .. item.zone
    elseif item.type == "ZONE_TRAVEL" then
        text = "Travel to " .. item.zone
    else
        text = "Unknown step"
    end
    return step, text
end

function draw_gui.RenderOptionToggle(id, text, on)
    local toggled = false
    local state = on
    ImGui.PushID(id .. "_tog_btn")

    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 1.0, 1.0, 1.0, 0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 1.0, 1.0, 1.0, 0)
    ImGui.PushStyleColor(ImGuiCol.Button, 1.0, 1.0, 1.0, 0)

    if on then
        ImGui.PushStyleColor(ImGuiCol.Text, 0.3, 1.0, 0.3, 0.9)
        if ImGui.Button(ICONS.FA_TOGGLE_ON) then
            toggled = true
            state   = false
        end
    else
        ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.3, 0.3, 0.8)
        if ImGui.Button(ICONS.FA_TOGGLE_OFF) then
            toggled = true
            state   = true
        end
    end
    ImGui.PopStyleColor(4)
    ImGui.PopID()
    ImGui.SameLine()
    ImGui.Text(text)

    return state, toggled
end

return draw_gui
