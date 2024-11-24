--[[
	Functions for drawing our ImGui window
--]]

local mq = require("mq")
local ICONS = require("mq.Icons")
local invis_travel = require("data/travelandinvis")
local ImGui = require("ImGui")
local logger = require("lib/logger")
local char_settings = require("utils/char_settings")

local LogLevels = {
	"Errors",
	"Warnings",
	"Info",
	"Debug",
	"Verbose",
	"Super-Verbose",
}

local outlineFilter = ""
local fullOutlineFilter = ""
---@class DrawGui
local draw_gui = {}
local class_list_choice = 1
draw_gui.class_list = {
	"Bard",
	"Beastlord",
	"Berserker",
	"Cleric",
	"Druid",
	"Enchanter",
	"Magician",
	"Monk",
	"Necromancer",
	"Paladin",
	"Ranger",
	"Rogue",
	"Shadow Knight",
	"Shaman",
	"Warrior",
	"Wizard",
}
local YELLOW_COLOR = { 1.0, 1.0, 0.0, 1.0 }
local RED_COLOR = { 1.0, 0.0, 0.0, 1.0 }
local GREEN_COLOR = { 0.0, 1.0, 0.0, 1.0 }
local changed = false
local automation_list = { "CWTN", "RGMercs (Lua)", "RGMercs (Macro)", "KissAssist", "MuleAssist" }
local invis_type = {}
local treeview_table_flags = bit32.bor(
	ImGuiTableFlags.Hideable,
	ImGuiTableFlags.RowBg,
	ImGuiTableFlags.Borders,
	ImGuiTableFlags.SizingFixedFit,
	ImGuiTableFlags.ScrollX
)
local myClass = mq.TLO.Me.Class()

draw_gui.dev = {
	["save_step"] = 0,
	["dev_on"] = false,
	["force_class"] = 1,
}

for i = 1, 16 do
	if draw_gui.class_list[i] == mq.TLO.Me.Class() then
		draw_gui.dev["force_class"] = i
		break
	end
end

draw_gui.jumpStep = 0
draw_gui.travelPct = 0
draw_gui.travelText = ""

-- Dynamicalily color progress bar
---@param minColor ImVec4
---@param maxColor ImVec4
---@param value number
---@param midColor ImVec4
---@return ImVec4
function draw_gui.dynamicBarColor(minColor, maxColor, value, midColor)
	value = math.max(0, math.min(100, value))
	local r, g, b, a
	if midColor then
		-- If midColor is provided, calculate in two segments
		if value > 50 then
			local proportion = (value - 50) / 50
			r = midColor[1] + proportion * (maxColor[1] - midColor[1])
			g = midColor[2] + proportion * (maxColor[2] - midColor[2])
			b = midColor[3] + proportion * (maxColor[3] - midColor[3])
			a = midColor[4] + proportion * (maxColor[4] - midColor[4])
		else
			local proportion = value / 50
			r = minColor[1] + proportion * (midColor[1] - minColor[1])
			g = minColor[2] + proportion * (midColor[2] - minColor[2])
			b = minColor[3] + proportion * (midColor[3] - minColor[3])
			a = minColor[4] + proportion * (midColor[4] - minColor[4])
		end
	else
		-- If midColor is not provided, calculate between minColor and maxColor
		local proportion = value / 100
		r = minColor[1] + proportion * (maxColor[1] - minColor[1])
		g = minColor[2] + proportion * (maxColor[2] - minColor[2])
		b = minColor[3] + proportion * (maxColor[3] - minColor[3])
		a = minColor[4] + proportion * (maxColor[4] - minColor[4])
	end
	return ImVec4(r, g, b, a)
end

-- Draw the row of the indicated step in the Full Outline tab
---@param item table
---@param step number
---@param outlineText string
function draw_gui.full_outline_row(item, step, outlineText)
	ImGui.TableNextRow()
	ImGui.TableNextColumn()
	if ImGui.Selectable("##c" .. step, false, ImGuiSelectableFlags.None) then
		_G.State:handle_step_change(step)
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
		_G.State:handle_step_change(step)
	end
	ImGui.SameLine()
	ImGui.TextWrapped(outlineText)
end

function draw_gui.dev_tab()
	if ImGui.BeginTabItem("Dev") then
		draw_gui.dev["save_step"] = ImGui.InputInt("Save Step", draw_gui.dev["save_step"])
		if ImGui.Button("Save") then
			char_settings.prepSave(draw_gui.dev["save_step"])
		end
		draw_gui.dev["force_class"] = ImGui.Combo("##ForcedClass", draw_gui.dev["force_class"], draw_gui.class_list)
		ImGui.EndTabItem()
	end
end

-- Return how many invis potions are needed for the given class and quest
---@param class string
---@param choice number
---@return number
local function invis_needed(class, choice)
	local class_epic = ""
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

-- Return how many gate potions are needed for the given class and quest
---@param class string
---@param choice number
---@return number
local function gate_needed(class, choice)
	local class_epic = ""
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

-- Draw the Console log tab
---@param common_settings Common_Settings
function draw_gui.consoleTab(common_settings)
	if ImGui.BeginTabItem("Console") then
		ImGui.SetNextItemWidth(120)
		common_settings.settings.logger.LogLevel, changed =
			ImGui.Combo("Debug Levels", common_settings.settings.logger.LogLevel, LogLevels, #LogLevels)
		if changed then
			logger.set_log_level(common_settings.settings.logger.LogLevel)
			common_settings.saveSettings()
		end

		ImGui.SameLine()
		common_settings.settings.logger.LogToFile, changed =
			draw_gui.RenderOptionToggle("##log_to_file", "Log to File", common_settings.settings.logger.LogToFile)
		if changed then
			common_settings.saveSettings()
		end

		local cur_x, cur_y = ImGui.GetCursorPos()
		local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
		logger.LogConsole:Render(ImVec2(contentSizeX, math.max(200, (contentSizeY - 10))))
		ImGui.EndTabItem()
	end
end

-- Draw the Full Outline tab
---@param task_table table
function draw_gui.fullOutlineTab(task_table)
	if ImGui.BeginTabItem("Full Outline") then
		fullOutlineFilter = ImGui.InputText("Filter", fullOutlineFilter, ImGuiInputTextFlags.None)
		if ImGui.BeginTable("##outlinetable", 2, treeview_table_flags) then
			ImGui.TableSetupColumn("Step", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
			ImGui.TableSetupColumn(
				"Description",
				bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.NoResize),
				100
			)
			ImGui.TableSetupScrollFreeze(0, 1)
			ImGui.TableHeadersRow()
			for i = 1, #task_table do
				--print(i)
				local step, outlineText = draw_gui.generate_outline_text(task_table[i])
				if fullOutlineFilter == "" then
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

-- Fill in distance to destination, average velocity, and ETA
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
		local path = string.format("%s %s", _G.State.destType, _G.State.dest)
		_G.State.pathDist = mq.TLO.Navigation.PathLength(path)()
		--_G.State.velocity      = mq.TLO.Navigation.Velocity()
		_G.State.estimatedTime = _G.State.pathDist / _G.State.velocity
		draw_gui.travelPct = 1.0 - (_G.State.pathDist / _G.State.startDist)
		draw_gui.travelText = string.format(
			"Distance: %s Velocity: %s ETA: %s seconds",
			math.floor(_G.State.pathDist),
			math.floor(_G.State.velocity),
			math.floor(_G.State.estimatedTime)
		)
		--end
	end
end

-- Draw the header section of the GUI (Control buttons and fields)
function draw_gui.header()
	ImGui.Text("Epic: " .. myClass .. " " .. _G.State.epicstring)
	if _G.State:readTaskRunning() == false then
		if ImGui.Button("Begin") then
			_G.State:setStartRun(true)
		end
		if ImGui.IsItemHovered() then
			local invis_num = invis_needed(mq.TLO.Me.Class.ShortName(), _G.State.epic_choice)
			local gate_num = gate_needed(mq.TLO.Me.Class.ShortName(), _G.State.epic_choice)
			local tooltip = "Begin/resume epic quest\nThis may require at least "
				.. invis_num
				.. " invis potions.\nThis may require at least "
				.. gate_num
				.. " gate potions."
			ImGui.SetTooltip(tooltip)
		end
	end
	if _G.State:readTaskRunning() then
		if ImGui.SmallButton(ICONS.MD_FAST_REWIND) then
			_G.State:handle_step_change(_G.State.current_step - 1)
		end
		if ImGui.IsItemHovered() then
			ImGui.SetTooltip("Move to previous step.")
		end
		ImGui.SameLine()
		if _G.State:readPaused() == false then
			if ImGui.SmallButton(ICONS.MD_PAUSE) then
				logger.log_info("\aoPausing script.")
				_G.State:setPaused(true)
			end
			if ImGui.IsItemHovered() then
				ImGui.SetTooltip("Pause script.")
			end
		else
			if ImGui.SmallButton(ICONS.FA_PLAY) then
				_G.State:setPaused(false)
				logger.log_info("\aoResuming script.")
			end
			if ImGui.IsItemHovered() then
				ImGui.SetTooltip("Resume script.")
			end
		end
		ImGui.SameLine()
		if ImGui.SmallButton(ICONS.MD_STOP) then
			_G.State:setTaskRunning(false)
			_G.State.should_skip = true
			logger.log_warn("\aoManually stopping script at step: \ar%s", _G.State.current_step)
			_G.State:setStatusText("Manually stopped at step %s.", _G.State.current_step)
		end
		if ImGui.IsItemHovered() then
			ImGui.SetTooltip("Stop script immedietly.")
		end
		ImGui.SameLine()
		if ImGui.SmallButton(ICONS.MD_FAST_FORWARD) then
			_G.State:handle_step_change(_G.State.current_step + 1)
		end
		if ImGui.IsItemHovered() then
			ImGui.SetTooltip("Skip to next step.")
		end
		if ImGui.Button("Stop @ Next Save") then
			logger.log_info("\aoStopping at next save point.")
			_G.State:setStopAtSave(true)
		end
		ImGui.PushItemWidth(40)
		draw_gui.jumpStep = ImGui.InputInt("##Step Jump", draw_gui.jumpStep, 0, 0, 0)
		ImGui.PopItemWidth()
		ImGui.SameLine()
		if ImGui.Button("Jump to Step") then
			_G.State:handle_step_change(draw_gui.jumpStep)
		end
		ImGui.Separator()
	end
end

-- Draw the General tab of the GUI
---@param task_table table
function draw_gui.generalTab(task_table)
	if ImGui.BeginTabItem("General") then
		if _G.State:readTaskRunning() == false then
			_G.State.epic_choice, changed = ImGui.Combo(
				"##Combo",
				_G.State.epic_choice,
				_G.State.epic_list,
				#_G.State.epic_list,
				#_G.State.epic_list
			)
			if ImGui.IsItemHovered() then
				ImGui.SetTooltip("Which epic to run.")
			end
			if changed == true then
				_G.State.step_overview()
				changed = false
			end
		end
		if mq.TLO.Me.Grouped() == true then
			_G.State.group_choice, changed = ImGui.Combo(
				"##Group_Combo",
				_G.State.group_choice,
				_G.State.group_combo,
				#_G.State.group_combo,
				#_G.State.group_combo
			)
			if ImGui.IsItemHovered() then
				ImGui.SetTooltip("Who should come with you (None. Full group. Individual group member.)")
			end
			if changed == true then
				_G.State:setGroupSelection()
			end
			ImGui.SameLine()
			if ImGui.SmallButton(ICONS.MD_REFRESH) then
				_G.State:populate_group_combo()
			end
		end

		ImGui.Separator()

		if _G.State:readTaskRunning() == true and #task_table > 0 and _G.State.current_step > 0 then
			--ImGui.PushStyleColor(ImGuiCol.PlotHistogram, IM_COL32(40, 150, 40, 255))
			ImGui.PushStyleColor(
				ImGuiCol.PlotHistogram,
				draw_gui.dynamicBarColor(RED_COLOR, GREEN_COLOR, (_G.State.current_step / #task_table) * 100,
					YELLOW_COLOR)
			)
			ImGui.ProgressBar(_G.State.current_step / #task_table, ImGui.GetWindowWidth(), 17, "##prog")
			ImGui.PopStyleColor()
			ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 20)
			ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetWindowWidth() / 2) - 60)
			ImGui.Text("Step " .. tostring(_G.State.current_step) .. " of " .. tostring(#task_table))
		end
		if _G.State.destType ~= "" then
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
			--ImGui.PushStyleColor(ImGuiCol.PlotHistogram, IM_COL32(150, 150, 40, 255))
			ImGui.PushStyleColor(
				ImGuiCol.PlotHistogram,
				draw_gui.dynamicBarColor(RED_COLOR, GREEN_COLOR, draw_gui.travelPct * 100, YELLOW_COLOR)
			)
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

-- Get values and draw the check boxes in the Outline tab
---@param id string
---@param on number
---@param step number
function draw_gui.outline_check_box(id, on, step)
	local toggled = false
	local state = on
	ImGui.PushID(id .. "_outline_btn")
	ImGui.PushStyleColor(ImGuiCol.ButtonActive, 1.0, 1.0, 1.0, 0)
	ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 1.0, 1.0, 1.0, 0)
	ImGui.PushStyleColor(ImGuiCol.Button, 1.0, 1.0, 1.0, 0)
	if step < _G.State.current_step and on == 0 then
		ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.3, 0.3, 0.8)
		ImGui.Button(ICONS.FA_SQUARE)
		toggled = false
		state = 2
	elseif state == 0 then
		ImGui.PushStyleColor(ImGuiCol.Text, 0.3, 1.0, 0.3, 0.9)
		if ImGui.Button(ICONS.FA_SQUARE_O) then
			toggled = true
			state = 1
		end
	elseif state == 1 then
		ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 1.0, 0.3, 0.9)
		if ImGui.Button(ICONS.FA_CHECK_SQUARE_O) then
			toggled = true
			state = 2
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

-- Draw the row of the indicated step in the Outline Tab
---@param overview_steps table
---@param task_outline_table table
---@param task_table table
---@param i number
function draw_gui.outlineRow(overview_steps, task_outline_table, task_table, i)
	ImGui.TableNextRow()
	ImGui.TableNextColumn()
	overview_steps[task_outline_table[i].Step] = draw_gui.outline_check_box(
		"outline_box_" .. i,
		overview_steps[task_outline_table[i].Step],
		task_outline_table[i].Step
	)
	ImGui.TableNextColumn()
	if ImGui.Selectable("##a" .. i, false, ImGuiSelectableFlags.None) then
		if _G.State:readTaskRunning() then
			_G.State:handle_step_change(task_outline_table[i].Step)
		end
	end
	ImGui.SameLine()
	ImGui.TextColored(IM_COL32(0, 255, 0, 255), task_outline_table[i].Step)
	ImGui.TableNextColumn()
	if ImGui.Selectable("##b" .. i, false, ImGuiSelectableFlags.None) then
		if _G.State:readTaskRunning() == true then
			_G.State:handle_step_change(task_outline_table[i].Step)
		end
	end
	ImGui.SameLine()

	ImGui.TextWrapped(task_outline_table[i].Description)
end

-- Draw the Outline tab
---@param task_outline_table table
---@param overview_steps table
---@param task_table table
function draw_gui.outlineTab(task_outline_table, overview_steps, task_table)
	if ImGui.BeginTabItem("Outline") then
		outlineFilter = ImGui.InputText("Filter", outlineFilter, ImGuiInputTextFlags.None)
		if ImGui.BeginTable("##outlinetable", 3, treeview_table_flags) then
			ImGui.TableSetupColumn("Manual Completion", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
			ImGui.TableSetupColumn("Step", bit32.bor(ImGuiTableColumnFlags.NoResize), 30)
			ImGui.TableSetupColumn(
				"Description",
				bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.NoResize),
				100
			)
			ImGui.TableSetupScrollFreeze(0, 1)
			ImGui.TableHeadersRow()
			for i = 1, #task_outline_table do
				if outlineFilter == "" then
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

-- Draw the Settings tab
---@param themeName string
---@param theme table
---@param themeID number
---@param common_settings Common_Settings
---@param char_settings Char_Settings
---@return string, string, number, string
function draw_gui.settingsTab(themeName, theme, themeID, common_settings, char_settings)
	if ImGui.BeginTabItem("Settings") then
		ImGui.BeginChild("##SettingsChild")
		if ImGui.CollapsingHeader("General Settings") then
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
						common_settings.settings["LoadTheme"] = theme.LoadTheme
					end
					if ImGui.IsItemEdited() then
						common_settings.saveSettings()
					end
				end
				ImGui.EndCombo()
			end
			char_settings.SaveState.general.stopTS, changed = draw_gui.RenderOptionToggle(
				"##ts_setting",
				"Stop if tradeskill requirements are unmet",
				char_settings.SaveState.general.stopTS
			)
			if changed then
				char_settings.saveState()
			end
			char_settings.SaveState.general.useGatePot, changed = draw_gui.RenderOptionToggle(
				"##pot_setting",
				"Allow use of gate potions",
				char_settings.SaveState.general.useGatePot
			)
			if changed then
				char_settings.saveState()
			end
			char_settings.SaveState.general.useOrigin, changed = draw_gui.RenderOptionToggle(
				"##bind_setting",
				"Allow use of Origin",
				char_settings.SaveState.general.useOrigin
			)
			if changed then
				char_settings.saveState()
			end
			char_settings.SaveState.general.invisForTravel, changed = draw_gui.RenderOptionToggle(
				"##invis_setting",
				"Invis while traveling",
				char_settings.SaveState.general.invisForTravel
			)
			if changed then
				char_settings.saveState()
			end
			char_settings.SaveState.general.speedForTravel, changed = draw_gui.RenderOptionToggle(
				"##speed_setting",
				"Use travel speed skills",
				char_settings.SaveState.general.speedForTravel
			)
			if changed then
				char_settings.saveState()
			end
			char_settings.SaveState.general.useGroupInvis, changed = draw_gui.RenderOptionToggle(
				"##group_invis_setting",
				"Use group invis skills if available",
				char_settings.SaveState.general.useGroupInvis
			)
			if changed then
				if char_settings.SaveState.general.useGroupInvis == true then
					if char_settings.SaveState.general.invisForTravel == false then
						char_settings.SaveState.general.invisForTravel = true
					end
				end
				char_settings.saveState()
			end
			ImGui.PushItemWidth(120)
			char_settings.SaveState.general.xtargClear =
				ImGui.InputInt("Number of mobs to clear XTarget list.", char_settings.SaveState.general.xtargClear)
			if ImGui.IsItemEdited() then
				char_settings.saveState()
			end
			if char_settings.SaveState.general.xtargClear < 1 then
				char_settings.SaveState.general.xtargClear = 1
			end
			if char_settings.SaveState.general.xtargClear > 20 then
				char_settings.SaveState.general.xtargClear = 21
			end
			ImGui.PopItemWidth()
		end
		if ImGui.CollapsingHeader("Class Settings") then
			ImGui.BeginTable("##Common_Settings", 2, ImGuiTableFlags.Borders)
			ImGui.TableSetupColumn("##Class_List", ImGuiTableColumnFlags.WidthFixed, 120)
			ImGui.TableSetupColumn("##Class_Setting", ImGuiTableColumnFlags.None)
			ImGui.TableNextRow()
			ImGui.TableNextColumn()
			ImGui.PushItemWidth(120)
			ImGui.PushStyleColor(ImGuiCol.FrameBg, IM_COL32(0, 0, 0, 255))
			class_list_choice = ImGui.ListBox(
				"##classlist",
				class_list_choice,
				draw_gui.class_list,
				#draw_gui.class_list,
				#draw_gui.class_list
			)
			ImGui.PopItemWidth()
			ImGui.PopStyleColor()
			ImGui.TableNextColumn()
			local width = ImGui.GetColumnWidth()
			local text_width = ImGui.CalcTextSize(draw_gui.class_list[class_list_choice])
			ImGui.SetCursorPosX((width - text_width))
			ImGui.Text(draw_gui.class_list[class_list_choice])
			ImGui.PushItemWidth(160)
			common_settings.settings.class[draw_gui.class_list[class_list_choice]], changed = ImGui.Combo(
				"##AutomationType",
				common_settings.settings.class[draw_gui.class_list[class_list_choice]],
				automation_list,
				#automation_list,
				#automation_list
			)
			ImGui.PopItemWidth()
			if changed then
				changed = false
				common_settings.saveSettings()
			end
			invis_type = {}
			for word in
			string.gmatch(common_settings.settings.class_invis[draw_gui.class_list[class_list_choice]], "([^|]+)")
			do
				table.insert(invis_type, word)
			end
			ImGui.PushItemWidth(230)
			common_settings.settings.invis[draw_gui.class_list[class_list_choice]], changed = ImGui.Combo(
				"##InvisType",
				common_settings.settings.invis[draw_gui.class_list[class_list_choice]],
				invis_type,
				#invis_type,
				#invis_type
			)
			if changed then
				changed = false
				common_settings.saveSettings()
			end
			if common_settings.settings.move_speed[draw_gui.class_list[class_list_choice]] then
				local speed_type = {}
				for word in
				string.gmatch(common_settings.settings.move_speed[draw_gui.class_list[class_list_choice]], "([^|]+)")
				do
					table.insert(speed_type, word)
				end
				common_settings.settings.speed[draw_gui.class_list[class_list_choice]], changed = ImGui.Combo(
					"##SpeedType",
					common_settings.settings.speed[draw_gui.class_list[class_list_choice]],
					speed_type,
					#speed_type,
					#speed_type
				)
				if changed then
					changed = false
					common_settings.saveSettings()
				end
			end
			ImGui.EndTable()
		end
		ImGui.EndChild()
		ImGui.EndTabItem()
	end
	return theme.LoadTheme, themeName, themeID, common_settings.settings.LoadTheme
end

-- Generate the outline text for the indicated step (via task_fuctions desc field)
---@param item table
---@return number, string
function draw_gui.generate_outline_text(item)
	local step = item.step
	local task_type = item.type
	if task_type == "" then
		return step, "Unknown step."
	end
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

-- Draw the toggle switch (yoinked from Derple)
---@param id string
---@param text string
---@param on boolean
---@return boolean, boolean
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
			state = false
		end
	else
		ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.3, 0.3, 0.8)
		if ImGui.Button(ICONS.FA_TOGGLE_OFF) then
			toggled = true
			state = true
		end
	end
	ImGui.PopStyleColor(4)
	ImGui.PopID()
	ImGui.SameLine()
	ImGui.Text(text)
	return state, toggled
end

return draw_gui
