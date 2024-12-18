--[[
    Our functionality for displaying information via the console to the user
    Written by: Derple
    Thank you Derple!
--]]

--- @type Mq
local mq              = require('mq')

---@class Logger
---@field log_super_verbose function
---@field log_verbose function
---@field log_debug function
---@field log_info function
---@field log_warn function
---@field log_error function
local actions         = {}

actions.LogConsole    = nil

local elHeaderStart   = "\ar[\agEpic Laziness"
local elHeaderEnd     = "\ag]"

--- @type number
local currentLogLevel = 3
local logToFileAlways = false

---@class LogLevels
local logLevels       = {
    ['super_verbose'] = { level = 6, header = "\atSUPER\aw-\apVERBOSE\ax", },
    ['verbose']       = { level = 5, header = "\apVERBOSE\ax", },
    ['debug']         = { level = 4, header = "\amDEBUG  \ax", },
    ['info']          = { level = 3, header = "\aoINFO   \ax", },
    ['warn']          = { level = 2, header = "\ayWARN   \ax", },
    ['error']         = { level = 1, header = "\arERROR  \ax", },
}

-- Return the current log level
---@return number
function actions.get_log_level() return currentLogLevel end

-- Set the log level
---@param level number
function actions.set_log_level(level) currentLogLevel = level end

-- Set log to file setting.
---@param logToFile boolean
function actions.set_log_to_file(logToFile) logToFileAlways = logToFile end

-- Get the call stack for the current function
---@return string
local function getCallStack()
    local info = debug.getinfo(4, "Snl")

    local callerTracer = string.format("\ao%s\aw::\ao%s()\aw:\ao%-04d\ax",
        info and info.short_src and info.short_src:match("[^\\^/]*.lua$") or "unknown_file",
        info and info.name or "unknown_func", info and info.currentline or 0)

    return callerTracer
end

-- Log a message
---@param logLevel string
---@param output string
---@vararg any
local function log(logLevel, output, ...)
    if currentLogLevel < logLevels[logLevel].level then return end
    local callerTracer = getCallStack()

    if (... ~= nil) then output = string.format(output, ...) end

    local now = string.format("%.03f", mq.gettime() / 1000)

    if logLevels[logLevel].level <= 2 or logToFileAlways then
        local fileOutput = output:gsub("\a.", "")
        local fileHeader = logLevels[logLevel].header:gsub("\a.", "")
        local fileTracer = callerTracer:gsub("\a.", "")
        mq.cmd(string.format('/mqlog [%s:%s(%s)] <%s> %s', mq.TLO.Me.Name(), fileHeader, fileTracer, now, fileOutput))
    end

    local badMesh = ''
    for _, zone in ipairs(_G.State.badMeshes) do
        if zone == mq.TLO.Zone.ShortName() then
            badMesh = 'X'
        end
    end

    if actions.LogConsole ~= nil then
        local consoleText = string.format('[%s] [%s%s-%s%s] %s', logLevels[logLevel].header, mq.TLO.Me.Class.ShortName(),
            _G.State.epic_list[_G.State.epic_choice],
            _G.State.current_step,
            badMesh,
            output)
        actions.LogConsole:AppendText(consoleText)
    end

    printf('%s\aw:%s \aw<\at%s\aw> \aw(\ag%s%s-%s\ar%s\aw) \aw(%s\aw)%s \ax%s', elHeaderStart, logLevels[logLevel]
        .header, now, mq.TLO.Me.Class.ShortName(),
        _G.State.epic_list[_G.State.epic_choice], _G.State.current_step, badMesh, callerTracer, elHeaderEnd,
        output)
end

-- Generate shortcut functions for logging (log_super_verbose, log_verbose, log_debug, log_info, log_warn, log_error)
function actions.GenerateShortcuts()
    for level, _ in pairs(logLevels) do
        --- @diagnostic disable-next-line
        actions["log_" .. level:lower()] = function(output, ...)
            log(level, output, ...)
        end
    end
end

actions.GenerateShortcuts()

return actions
