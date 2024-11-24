local mq = require("mq")
local quests_done = require("data/questsdone")
local logger = require("utils/logger")
local loadsave = require("utils/loadsave")
local PackageMan = require("mq/PackageMan")
local sqlite3 = PackageMan.Require("lsqlite3")
local reqs = require("data/questrequirements")

local db_outline = sqlite3.open(mq.luaDir .. "\\epiclaziness\\epiclaziness_outline.db")
local AUTOSIZE_SIZES = { 1, 2, 5, 10, 20 }
local AUTOSIZE_CHOICE = 3

local State = {}

State = {
    task_table = {},
    task_outline_table = {},
    running = true,
    overview_steps = {},
    xtargIgnore = "",
    is_paused = false,           --
    is_task_running = false,     --
    do_start_run = false,        --
    should_stop_at_save = false, --
    current_step = 0,            --
    status = "",                 --
    status2 = "",                --
    requirements = "",           --
    bagslot1 = 0,                --0
    bagslot2 = 0,                --0
    group_combo = {},
    group_choice = 1,
    group_selected_member = "",
    epic_list = quests_done[string.lower(mq.TLO.Me.Class.ShortName())],
    epic_choice = 1,
    epicstring = "",
    Location = { --
        X = 0,
        Y = 0,
        Z = 0,
    },
    should_skip = false,
    is_rewound = false,
    bad_IDs = {},
    cannot_count = 0,
    is_traveling = false,
    -- autosize_sizes, autosize_choice = list of possible sizes, and current size value index
    autosize_sizes = AUTOSIZE_SIZES,
    autosize_choice = AUTOSIZE_CHOICE,
    combineSlot = 0,
    destType = "",
    dest = "",
    pathDist = 0,
    velocity = 0,
    estimatedTime = 0,
    startDist = 0,
    updateTime = mq.gettime(),
    badMeshes = {},
    velocityTable = {},
}

-- Clear the velocity table
function State:clearVelocityTable()
    self.velocityTable = {}
end

-- Calculate the average velocity from velocities stored in the velocity table
--- @return number
function State:getAverageVelocity()
    local velocitySum = 0
    for _, value in pairs(self.velocityTable) do
        velocitySum = velocitySum + value
    end
    return velocitySum / #self.velocityTable
end

-- Add a velocity to the velocity table
--- @param velocity number
function State:addVelocity(velocity)
    if #self.velocityTable >= 20 then
        table.remove(self.velocityTable, 1)
    end
    table.insert(self.velocityTable, velocity)
end

-- Read the status of the start_run variable
--- @return boolean
function State:readStartRun()
    return self.do_start_run
end

-- Set the start_run variable
--- @param value boolean
function State:setStartRun(value)
    self.do_start_run = value
end

-- Set xtargIgnore to value
--- @param value string
function State:setXtargIgnore(value)
    self.xtargIgnore = value
end

-- Read the value of xtargIgnore
--- @return string
function State:readXtargIgnore()
    return self.xtargIgnore
end

--Clear the value of xtargIgnore
function State:clearXtargIgnore()
    self.xtargIgnore = ""
end

-- Return is_task_running to determine if script is actively running
--- @return boolean
function State:readTaskRunning()
    return self.is_task_running
end

-- Set is_task_running to value
--- @param value boolean
function State:setTaskRunning(value)
    self.is_task_running = value
end

-- Return is_paused to determine if script is paused
--- @return boolean
function State:readPaused()
    return self.is_paused
end

-- Set is_paused to value
--- @param value boolean
function State:setPaused(value)
    self.is_paused = value
end

-- Return the value of should_stop_at_save
--- @return boolean
function State:readStopAtSave()
    return self.should_stop_at_save
end

-- Set should_stop_at_save to value
--- @param value boolean
function State:setStopAtSave(value)
    self.should_stop_at_save = value
end

-- Return the stored location of the player
--- @return number, number, number
function State:readLocation()
    return self.Location.X, self.Location.Y, self.Location.Z
end

-- Store the current location of the player
--- @param x number
--- @param y number
--- @param z number
function State:setLocation(x, y, z)
    self.Location.X = x
    self.Location.Y = y
    self.Location.Z = z
end

-- Handle changing of step. This will set the current step to the new step and set the is_rewound and should_skip variables to true
--- @param step number
function State:handle_step_change(step)
    logger.log_info("\aoSetting step to: \ar%s\ao.", step)
    logger.log_verbose("\aoStep type: \ar%s\ao.", task_table[step].type)
    self.is_rewound = true
    self.should_skip = true
    self.current_step = step
    for i, state in pairs(State.overview_steps) do
        if i >= step and state == 2 then
            State.overview_steps[i] = 0
        end
    end
end

-- Set the text of the status section in the GUI
--- @param text string
function State:setStatusText(text, ...)
    self.status = string.format(text, ...)
end

-- Set the text of the second status section in the GUI
--- @param text string
function State:setStatusTwoText(text)
    self.status2 = text
end

-- Read the text of the status section in the GUI
--- @return string
function State:readStatusText()
    return self.status
end

-- Read the text of the second status section in the GUI
--- @return string
function State:readStatusTwoText()
    return self.status2
end

-- Set the text of the requirements for this epic. Generated from questrequirements.lua
--- @param text string
function State:setReqsText(text)
    self.requirements = text
end

-- Read the text of the requirements for this epic
--- @return string
function State:readReqsText()
    return self.requirements
end

-- Read the outline of the selected epic from the outline db
function State.step_overview()
    task_outline_table = {}
    local class = string.lower(mq.TLO.Me.Class.ShortName())
    local choice = State.epic_choice
    local tablename = ""
    local quest = ""
    logger.log_super_verbose("\aoLoading step outline for %s - %s.", mq.TLO.Me.Class(), State.epic_list[choice])
    if State.epic_list[choice] == "1.0" then
        tablename = class .. "_10"
        quest = "10"
        State.epicstring = "1.0"
    elseif State.epic_list[choice] == "Pre-1.5" then
        tablename = class .. "_pre15"
        quest = "pre15"
        State.epicstring = "Pre-1.5"
    elseif State.epic_list[choice] == "1.5" then
        tablename = class .. "_15"
        quest = "15"
        State.epicstring = "1.5"
    elseif State.epic_list[choice] == "2.0" then
        tablename = class .. "_20"
        quest = "20"
        State.epicstring = "2.0"
    end
    State:setReqsText(reqs[class][quest])
    if tablename == "" then
        logger.log_error("\aoThis class and quest has not yet been implemented.")
        State:setTaskRunning(false)
        return
    end
    local sql = "SELECT * FROM " .. tablename
    for a in db_outline:nrows(sql) do
        table.insert(task_outline_table, a)
    end
    for _, task in pairs(task_outline_table) do
        State.overview_steps[task.Step] = 0
    end
    logger.log_super_verbose("\aoSuccessfuly loaded outline.")
end

-- Set group_selected_member to the selected member(s) in the group combo box
function State:setGroupSelection()
    self.group_selected_member = self.group_combo[self.group_choice]
end

-- Return the value of group_selected_member
--- @return number, string
function State:readGroupSelection()
    return self.group_choice, self.group_selected_member
end

-- Save the current step to the save state
function State.save()
    logger.log_info("\aoSaving step: \ar%s", State.current_step)
    loadsave.prepSave(State.current_step)
    if State:readStopAtSave() then
        logger.log_warn("\aoStopping at step: \ar%s\ao.", State.current_step)
        State.epicstring = ""
        State:setTaskRunning(false)
        State:setStopAtSave(false)
        State:setStatusText("Stopped at step: %s", _G.State.current_step)
        return
    end
end

-- Exclude the provided NPC from the list of NPCs that will be handled
--- @param item Item
function State.exclude_npc(item)
    exclude_name = item.npc
    create_spawn_list()
end

function State.exclude_npc_by_loc(item)
    ID = mq.TLO.Spawn(item.what).ID()
    table.insert(State.bad_IDs, ID)
end

-- Execute the provided command string
--- @param item Item
function State.execute_command(item)
    logger.log_info("\aoExecuting command: \ag%s", item.what)
    mq.cmdf("%s", item.what)
end

-- Pause the script

--- @param item Item
function State.pauseTask(item)
    State:setStatusText(item.status)
    State:setTaskRunning(false)
end

function State:populate_group_combo()
    logger.log_info("\aoPopulating group combo box with characters in your current zone.")
    self.group_combo = {}
    self.group_combo[#self.group_combo + 1] = "None"
    if mq.TLO.Me.Grouped() then
        self.group_combo[#self.group_combo + 1] = "Group"
        for i = 0, mq.TLO.Group() do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                self.group_combo[#self.group_combo + 1] = mq.TLO.Group.Member(i).DisplayName()
            end
        end
    end
end

return State
