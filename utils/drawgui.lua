local mq                   = require('mq')
local ICONS                = require('mq.Icons')
local invis_travel         = require('utils/travelandinvis')
local ImGui                = require('ImGui')
local logger               = require('utils/logger')

local LogLevels            = {
    "Errors",
    "Warnings",
    "Info",
    "Debug",
    "Verbose",
    "Super-Verbose",
}

local outlineFilter        = ''
local fullOutlineFilter    = ''
local draw_gui             = {}
local class_list_choice    = 1
local class_list           = { 'Bard', 'Beastlord', 'Berserker', 'Cleric', 'Druid', 'Enchanter', 'Magician', 'Monk', 'Necromancer', 'Paladin', 'Ranger', 'Rogue', 'Shadow Knight',
    'Shaman', 'Warrior', 'Wizard' }
local changed              = false
local automation_list      = { 'CWTN', 'RGMercs (Lua)', 'RGMercs (Macro)', 'KissAssist', 'MuleAssist' }
local invis_type           = {}
local treeview_table_flags = bit32.bor(ImGuiTableFlags.Hideable, ImGuiTableFlags.RowBg, ImGuiTableFlags.Borders, ImGuiTableFlags.SizingFixedFit, ImGuiTableFlags.ScrollX)
local myClass              = mq.TLO.Me.Class()

draw_gui.travelPct         = 0
draw_gui.travelText        = ''

function draw_gui.full_outline_row(item, step, outlineText)
    ImGui.TableNextRow()
    ImGui.TableNextColumn()
    if ImGui.Selectable("##c" .. step, false, ImGuiSelectableFlags.None) then
        _G.State.is_rewound = true
        _G.State.should_skip = true
        _G.State.current_step = step
        logger.log_info('\aoSetting step to \ar%s', _G.State.current_step)
        logger.log_verbose("\aoStep type: \ar%s", item.type)
    end
    ImGui.SameLine()
    local color = IM_COL32(0, 0, 0, 0)
    if step == _G.State.current_step then
        color = IM_COL32(255, 255, 255, 255)
    elseif step < _G.State.current_step then
        color = IM_COL32(255, 0, 0, 255)
    elseif step > _G.State.current_step then
        color = IM_COL32(0, 255, 0, 255)
    end
    --logger.log_super_verbose("\aoProcessing step \ag%s\ao.", step)
    ImGui.TextColored(color, tostring(step))
    ImGui.TableNextColumn()
    if ImGui.Selectable("##d" .. step, false, ImGuiSelectableFlags.None) then
        _G.State.is_rewound = true
        _G.State.should_skip = true
        _G.State.current_step = step
        logger.log_info('\aoSetting step to \ar%s', step)
        logger.log_verbose("\aoStep type: \ar%s", item.type)
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
        ImGui.SetNextItemWidth(120)
        class_settings.settings.logger.LogLevel, changed = ImGui.Combo("Debug Levels", class_settings.settings.logger.LogLevel, LogLevels, #LogLevels)
        if changed then
            logger.set_log_level(class_settings.settings.logger.LogLevel)
            class_settings.saveSettings()
        end

        ImGui.SameLine()
        class_settings.settings.logger.LogToFile, changed = draw_gui.RenderOptionToggle("##log_to_file", "Log to File", class_settings.settings.logger.LogToFile)
        if changed then
            class_settings.saveSettings()
        end

        local cur_x, cur_y = ImGui.GetCursorPos()
        local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
        logger.LogConsole:Render(ImVec2(contentSizeX, math.max(200, (contentSizeY - 10))))
        ImGui.EndTabItem()
    end
end

function draw_gui.fullOutlineTab(task_table)
    if ImGui.BeginTabItem("Full Outline") then
        fullOutlineFilter = ImGui.InputText("Filter", fullOutlineFilter, ImGuiInputTextFlags.None)
        if ImGui.BeginTable('##outlinetable', 2, treeview_table_flags) then
            ImGui.TableSetupColumn("Step", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
            ImGui.TableSetupColumn("Description", bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.NoResize), 100)
            ImGui.TableSetupScrollFreeze(0, 1)
            ImGui.TableHeadersRow()
            for i = 1, #task_table do
                local step, outlineText = draw_gui.generate_outline_text(task_table[i])
                if fullOutlineFilter == '' then
                    draw_gui.full_outline_row(task_table[i], step, outlineText)
                elseif string.find(string.lower(outlineText), string.lower(fullOutlineFilter)) then
                    draw_gui.full_outline_row(task_table[i], step, outlineText)
                end
            end
            ImGui.EndTable()
        end
        ImGui.EndTabItem()
    end
end

function draw_gui.pathUpdate()
    if mq.gettime() > _G.State.updateTime then
        _G.State.updateTime = mq.gettime() + 100
        --[[if _G.State.destType == 'ZONE' then
            if mq.TLO.Navigation.CurrentPathDistance() ~= nil then
                _G.State.pathDist      = mq.TLO.Navigation.CurrentPathDistance()
                _G.State.velocity      = mq.TLO.Navigation.Velocity()
                _G.State.estimatedTime = _G.State.pathDist / _G.State.velocity
                draw_gui.travelPct     = 1.0 - (_G.State.pathDist / _G.State.startDist)
                draw_gui.travelText    = string.format("Distance: %s Velocity: %s ETA: %s seconds", math.floor(_G.State.pathDist), math.floor(_G.State.velocity),
                    math.floor(_G.State.estimatedTime))
            end
        else--]]
        local path             = string.format("%s %s", _G.State.destType, _G.State.dest)
        _G.State.pathDist      = mq.TLO.Navigation.PathLength(path)()
        _G.State.velocity      = mq.TLO.Navigation.Velocity()
        _G.State.estimatedTime = _G.State.pathDist / _G.State.velocity
        draw_gui.travelPct     = 1.0 - (_G.State.pathDist / _G.State.startDist)
        draw_gui.travelText    = string.format("Distance: %s Velocity: %s ETA: %s seconds", math.floor(_G.State.pathDist), math.floor(_G.State.velocity),
            math.floor(_G.State.estimatedTime))
        --end
    end
end

function draw_gui.generalTab(task_table)
    if ImGui.BeginTabItem("General") then
        ImGui.Text("Class: " .. myClass .. " " .. _G.State.epicstring)
        if _G.State.is_task_running == false then
            _G.State.epic_choice, changed = ImGui.Combo('##Combo', _G.State.epic_choice, _G.State.epic_list, #_G.State.epic_list, #_G.State.epic_list)
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip('Which epic to run.')
            end
            if changed == true then
                _G.State.step_overview()
            end
        end
        if mq.TLO.Me.Grouped() == true then
            _G.State.group_choice = ImGui.Combo('##Group_Combo', _G.State.group_choice, _G.State.group_combo)
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip('Who should come with you (None. Full group. Individual group member.)')
            end
            ImGui.SameLine()
            if ImGui.SmallButton(ICONS.MD_REFRESH) then
                _G.State.populate_group_combo()
            end
        end
        if _G.State.is_task_running == false then
            if ImGui.Button("Begin") then
                _G.State.start_run = true
            end
            if ImGui.IsItemHovered() then
                local invis_num = invis_needed(mq.TLO.Me.Class.ShortName(), _G.State.epic_choice)
                local gate_num = gate_needed(mq.TLO.Me.Class.ShortName(), _G.State.epic_choice)
                local tooltip = "Begin/resume epic quest\nThis may require at least " ..
                    invis_num .. " invis potions.\nThis may require at least " .. gate_num .. " gate potions."
                ImGui.SetTooltip(tooltip)
            end
        end
        if _G.State.is_task_running == true then
            if ImGui.SmallButton(ICONS.MD_FAST_REWIND) then
                _G.State.should_skip = true
                _G.State.is_rewound = true
                _G.State.current_step = _G.State.current_step - 1
                logger.log_info("\aoMoving to previous step \ar%s", _G.State.current_step)
                logger.log_verbose("\aoStep type: \ar%s", task_table[_G.State.current_step].type)
            end
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip("Move to previous step.")
            end
            ImGui.SameLine()
            if _G.State.is_paused == false then
                if ImGui.SmallButton(ICONS.MD_PAUSE) then
                    logger.log_info("\aoPausing script.")
                    _G.State.is_paused = true
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip("Pause script.")
                end
            else
                if ImGui.SmallButton(ICONS.FA_PLAY) then
                    _G.State.is_paused = false
                    logger.log_info("\aoResuming script.")
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip("Resume script.")
                end
            end
            ImGui.SameLine()
            if ImGui.SmallButton(ICONS.MD_STOP) then
                _G.State.is_task_running = false
                _G.State.should_skip = true
                logger.log_warn("\aoManually stopping script at step: \ar%s", _G.State.current_step)
                _G.State:setStatusText(string.format("Manually stopped at step %s.", _G.State.current_step))
            end
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip("Stop script immedietly.")
            end
            ImGui.SameLine()
            if ImGui.SmallButton(ICONS.MD_FAST_FORWARD) then
                _G.State.should_skip = true
                _G.State.current_step = _G.State.current_step + 1
                _G.State.is_rewound = true
                logger.log_info("\aoMoving to next step \ar%s", _G.State.current_step)
                logger.log_verbose("\aoStep type: \ar%s", task_table[_G.State.current_step].type)
            end
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip("Skip to next step.")
            end
            if ImGui.Button("Stop @ Next Save") then
                logger.log_info("\aoStopping at next save point.")
                _G.State.stop_at_save = true
            end
        end
        ImGui.Separator()
        ImGui.PushStyleColor(ImGuiCol.PlotHistogram, IM_COL32(40, 150, 40, 255))
        ImGui.ProgressBar(_G.State.current_step / #task_table, ImGui.GetWindowWidth(), 17, "##prog")
        ImGui.PopStyleColor()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 20)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetWindowWidth() / 2) - 60)
        ImGui.Text("Step " .. tostring(_G.State.current_step) .. " of " .. tostring(#task_table))
        if _G.State.destType ~= '' then
            --[[if _G.State.destType == 'ZONE' then
                if mq.TLO.Navigation.CurrentPathDistance() ~= nil then
                    draw_gui.pathUpdate()
                    ImGui.PushStyleColor(ImGuiCol.PlotHistogram, IM_COL32(150, 150, 40, 255))
                    ImGui.ProgressBar(draw_gui.travelPct, ImGui.GetWindowWidth(), 17, "##dist")
                    ImGui.PopStyleColor()
                    ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 20)
                    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetWindowWidth() / 2) - 115)
                    ImGui.Text(draw_gui.travelText)
                end
            else--]]
            draw_gui.pathUpdate()
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram, IM_COL32(150, 150, 40, 255))
            ImGui.ProgressBar(draw_gui.travelPct, ImGui.GetWindowWidth(), 17, "##dist")
            ImGui.PopStyleColor()
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 20)
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetWindowWidth() / 2) - 115)
            ImGui.Text(draw_gui.travelText)
            --end
        end
        ImGui.TextWrapped(_G.State:readStatusText())
        ImGui.NewLine()
        ImGui.TextWrapped(_G.State:readStatusTwoText())
        ImGui.NewLine()
        ImGui.TextWrapped(_G.State:readReqsText())
        ImGui.EndTabItem()
    end
end

function draw_gui.outline_check_box(id, on, step)
    local toggled = false
    local state = on
    ImGui.PushID(id .. "_outline_btn")
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 1.0, 1.0, 1.0, 0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 1.0, 1.0, 1.0, 0)
    ImGui.PushStyleColor(ImGuiCol.Button, 1.0, 1.0, 1.0, 0)
    if step < _G.State.current_step then
        ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.3, 0.3, 0.8)
        ImGui.Button(ICONS.FA_SQUARE)
        toggled = false
        state = 2
    elseif state == 0 then
        ImGui.PushStyleColor(ImGuiCol.Text, 0.3, 1.0, 0.3, 0.9)
        if ImGui.Button(ICONS.FA_SQUARE_O) then
            toggled = true
            state   = 1
        end
    elseif state == 1 then
        ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 1.0, 0.3, 0.9)
        if ImGui.Button(ICONS.FA_CHECK_SQUARE_O) then
            toggled = true
            state   = 2
        end
    else
        ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.3, 0.3, 0.8)
        if ImGui.Button(ICONS.FA_SQUARE) then
            toggled = false
            state = 0
        end
    end
    ImGui.PopStyleColor(4)
    ImGui.PopID()
    return state, toggled
end

function draw_gui.outlineRow(overview_steps, task_outline_table, task_table, i)
    ImGui.TableNextRow()
    ImGui.TableNextColumn()
    overview_steps[task_outline_table[i].Step] = draw_gui.outline_check_box("outline_box_" .. i, overview_steps[task_outline_table[i].Step], task_outline_table[i].Step)
    ImGui.TableNextColumn()
    if ImGui.Selectable("##a" .. i, false, ImGuiSelectableFlags.None) then
        if _G.State.is_task_running == true then
            _G.State.is_rewound = true
            _G.State.should_skip = true
            _G.State.current_step = task_outline_table[i].Step
            logger.log_info('\aoSetting step to \ar%s', _G.State.current_step)
            logger.log_verbose("\aoStep type: \ar%s", task_table[_G.State.current_step].type)
        end
    end
    ImGui.SameLine()
    ImGui.TextColored(IM_COL32(0, 255, 0, 255), task_outline_table[i].Step)
    ImGui.TableNextColumn()
    if ImGui.Selectable("##b" .. i, false, ImGuiSelectableFlags.None) then
        if _G.State.is_task_running == true then
            _G.State.is_rewound = true
            _G.State.should_skip = true
            _G.State.current_step = task_outline_table[i].Step
            logger.log_info('\aoSetting step to \ar%s', _G.State.current_step)
            logger.log_verbose("\aoStep type: \ar%s", task_table[_G.State.current_step].type)
        end
    end
    ImGui.SameLine()

    ImGui.TextWrapped(task_outline_table[i].Description)
end

function draw_gui.outlineTab(task_outline_table, overview_steps, task_table)
    if ImGui.BeginTabItem("Outline") then
        outlineFilter = ImGui.InputText("Filter", outlineFilter, ImGuiInputTextFlags.None)
        if ImGui.BeginTable('##outlinetable', 3, treeview_table_flags) then
            ImGui.TableSetupColumn("Manual Completion", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
            ImGui.TableSetupColumn("Step", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
            ImGui.TableSetupColumn("Description", bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.NoResize), 100)
            ImGui.TableSetupScrollFreeze(0, 1)
            ImGui.TableHeadersRow()
            for i = 1, #task_outline_table do
                if outlineFilter == '' then
                    draw_gui.outlineRow(overview_steps, task_outline_table, task_table, i)
                elseif string.find(string.lower(task_outline_table[i].Description), string.lower(outlineFilter)) then
                    draw_gui.outlineRow(overview_steps, task_outline_table, task_table, i)
                end
            end
            ImGui.EndTable()
        end
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
            char_settings.SaveState.general.xtargClear = ImGui.InputInt("Number of mobs to clear XTarget list.", char_settings.SaveState.general.xtargClear)
            if char_settings.SaveState.general.xtargClear < 1 then char_settings.SaveState.general.xtargClear = 1 end
            if char_settings.SaveState.general.xtargClear > 20 then char_settings.SaveState.general.xtargClear = 21 end
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
    local task_type = item.type
    local text_generator = _G.Task_Functions[task_type].desc
    if text_generator then
        if type(text_generator) == "function" then
            return step, text_generator(item)
        else
            return step, text_generator
        end
    else
        return step, "Unknown step."
    end
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
