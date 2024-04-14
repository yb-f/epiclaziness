local mq       = require('mq')
local ICONS    = require('mq.Icons')

local draw_gui = {}

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
