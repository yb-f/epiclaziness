local mq           = require('mq')
local logger       = require('utils/logger')

local RANDOM_MIN   = 300
local RANDOM_MAX   = 3000
local MAX_DISTANCE = 100
local manage       = {}
local me           = mq.TLO.Me
local group        = mq.TLO.Group

function manage.generateGroupCommands(selfTable, groupTable, tableSame, sendEach)
    tableSame = tableSame or false
    sendEach = sendEach or false
    local choice, name = _G.State:readGroupSelection()
    local outputTable = {}
    if tableSame then
        for _, command in ipairs(selfTable) do
            local cmd
            if choice == 1 then
                cmd = command
            elseif choice == 2 then
                if sendEach then

                else
                    outputTable[#outputTable + 1] = string.format("/dgga %s", command)
                end
            else
                outputTable[#outputTable + 1] = string.format("/dex %s %s", name, command)
                outputTable[#outputTable + 1] = command
            end
        end
    else
        for _, command in ipairs(groupTable) do
            if choice == 2 then
                outputTable[#outputTable + 1] = string.format("/dgge %s", command)
            else

            end
        end
    end
end

function manage.campGroup(radius, class_settings, char_settings)
    local choice, name = _G.State:readGroupSelection()
    logger.log_info("\aoSetting camp mode with radius \ag%s\ao.", radius)
    manage.doAutomation(me.DisplayName(), me.Class.ShortName(), class_settings.class[me.Class.Name()], 'camp', char_settings)
    manage.setRadius(me.DisplayName(), me.Class.ShortName(), class_settings.class[me.Class.Name()], radius, char_settings)
    if choice == 1 then
        return
    elseif choice == 2 then
        for i = 1, group.Members() do
            if group.Member(i).DisplayName() ~= me.DisplayName() then
                manage.doAutomation(group.Member(i).DisplayName(), group.Member(i).Class.ShortName(), class_settings.class[group.Member(i).Class.Name()], 'camp', char_settings)
            end
        end
    else
        manage.doAutomation(name, group.Member(name).Class.ShortName(), class_settings.class[Group.Member(name).Class.Name()], 'camp', char_settings)
    end
end

function manage.doAutomation(character, class, script, action, char_settings)
    local commands_self = {
        [1] = {
            start = function()
                return {
                    string.format('/squelch /%s mode 0 n osave', class),
                    string.format('/squelch /%s usestick on nosave', class),
                    string.format('/squelch /%s zhigh 100 nosave', class),
                    string.format('/squelch /%s zlow 100 nosave', class)
                }
            end,
            pause = function()
                return {
                    string.format('/squelch /%s pause on nosave', class)
                }
            end,
            unpause = function()
                return {
                    string.format('/squelch /%s pause off nosave', class)
                }
            end,
            camp = function()
                return {
                    string.format('/squelch /%s resetcamp nosave', class),
                    string.format('/squelch /%s pause off nosave', class),
                    string.format('/squelch /%s mode HunterTank nosave', class)
                }
            end,
            uncamp = function()
                return {
                    string.format('/squelch /%s mode 0 nosave', class),
                    string.format('/squelch /%s pause on nosave', class)
                }
            end,
        },
        [2] = {
            start = function()
                return {
                    string.format('/squelch /lua run rgmercs %s', mq.TLO.Me.DisplayName()),
                    string.format('/squelch /lua run rgmercs %s', mq.TLO.Me.DisplayName()),
                    string.format('/squelch /rgl set PullZRadius 100'),
                    string.format('/squelch /rgl set pullmincon 1')
                }
            end,
            pause = function()
                return {
                    string.format('/squelch /rgl pause')
                }
            end,
            unpause = function()
                return {
                    string.format('/squelch /rgl unpause')
                }
            end,
            camp = function()
                return {
                    string.format('/squelch /rgl unpause'),
                    string.format('/squelch /rgl set pullmode 3'),
                    string.format('/squelch /rgl set dopull on')
                }
            end,
            uncamp = function()
                return {
                    string.format('/squelch /rgl campoff'),
                    string.format('/squelch /rgl pause')
                }
            end,
        },
        [3] = {
            start = function()
                return {
                    string.format("/squelch /mac rgmercs/rgmerc"),
                }
            end,
            pause = function()
                return {
                    string.format("/squelch /rg off"),
                }
            end,
            unpause = function()
                return {
                    string.format("/squelch /rg on"),
                }
            end,
            camp = function()
                return {
                    string.format("/squelch /rg camphere"),
                    string.format("/squelch /rg on"),
                }
            end,
            uncamp = function()
                return {
                    string.format("/squelch /rg campoff"),
                    string.format("/squelch /rg off"),
                }
            end,
        },
        [4] = {
            start = function()
                return {
                    string.format("/squelch /mac kissassist %s", mq.TLO.Me.DisplayName()),
                    string.format("/squelch /maxzrange 100"),
                }
            end,
            pause = function()
                return {
                    string.format("/squelch /mqp on"),
                }
            end,
            unpause = function()
                return {
                    string.format("/squelch /mqp off"),
                }
            end,
            camp = function()
                return {
                    string.format("/squelch /camphere on"),
                    string.format("/squelch /mqp off"),
                }
            end,
            uncamp = function()
                return {
                    string.format("/squelch /camphere off"),
                    string.format("/squelch /mqp on"),
                }
            end,
        },
        [5] = {
            start = function()
                return {
                    string.format("/squelch /mac muleassist %s", mq.TLO.Me.DisplayName()),
                    string.format("/squelch /maxzrange 100"),
                }
            end,
            pause = function()
                return {
                    string.format("/squelch /mqp on"),
                }
            end,
            unpause = function()
                return {
                    string.format("/squelch /mqp off"),
                }
            end,
            camp = function()
                return {
                    string.format("/squelch /camphere on"),
                    string.format("/squelch /mqp off"),
                }
            end,
            uncamp = function()
                return {
                    string.format("/squelch /camphere off"),
                    string.format("/squelch /mqp on"),
                }
            end,
        },
    }
    local commands_group = {
        [1] = {
            start = function()
                return {
                    string.format('/dex %s /squelch /%s mode 2 nosave', character, class),
                }
            end,
            pause = function()
                return {
                    string.format('/dex %s /squelch /%s pause on nosave', character, class),
                }
            end,
            unpause = function()
                return {
                    string.format('/dex %s /squelch /%s pause off nosave', character, class),
                }
            end,
            camp = function()
                return {
                    string.format('/dex %s /squelch /%s resetcamp nosave', character, class),
                    string.format('/dex %s /squelch /%s mode 1 nosave', character, class),
                    string.format('/dex %s /squelch /%s pause off nosave', character, class),
                }
            end,
            uncamp = function()
                return {
                    string.format('/dex %s /squelch /%s mode 2 nosave', character, class),
                    string.format('/dex %s /squelch /%s pause on nosave', character, class),
                }
            end,
        },
        [2] = {
            start = function()
                return {
                    string.format("/dex %s /squelch /lua run rgmercs", character),
                    string.format('/dex %s /squelch /rgl chaseon %s', character, mq.TLO.Me.DisplayName()),
                }
            end,
            pause = function()
                return {
                    string.format("/dex %s /squelch /rgl pause", character),
                }
            end,
            unpause = function()
                return {
                    string.format("/dex %s /squelch /rgl unpause", character),
                }
            end,
            camp = function()
                return {
                    string.format("/dex %s /squelch /rgl campoff", character),
                    string.format('/dex %s /squelch /rgl chaseon %s', character, mq.TLO.Me.DisplayName()),
                    string.format("/dex %s /squelch /rgl pause", character),
                }
            end,
            uncamp = function()
                return {
                    string.format("/dex %s /squelch /rgl campoff", character),
                    string.format('/dex %s /squelch /rgl chaseon %s', character, mq.TLO.Me.DisplayName()),
                    string.format("/dex %s /squelch /rgl pause", character),
                }
            end,
        },
        [3] = {
            start = function()
                return {
                    string.format("/dex %s /squelch /mac rgmercs", character),
                    string.format('/dex %s /squelch /rg chaseon %s', character, mq.TLO.Me.DisplayName()),
                }
            end,
            pause = function()
                return {
                    string.format("/dex %s /squelch /rg off", character),
                }
            end,
            unpause = function()
                return {
                    string.format("/dex %s /squelch /rg on", character),
                }
            end,
            camp = function()
                return {
                    string.format("/dex %s /squelch /rg camphere", character),
                    string.format('/dex %s /squelch /rg on', character),
                }
            end,
            uncamp = function()
                return {
                    string.format("/dex %s /squelch /rg camphere", character),
                    string.format('/dex %s /squelch /rg chaseon %s', character, mq.TLO.Me.DisplayName()),
                    string.format("/dex %s /squelch /rg off", character),
                }
            end,
        },
        [4] = {
            start = function()
                return {
                    string.format("/dex %s /squelch /mac kissassist %s", character, mq.TLO.Me.DisplayName()),
                    string.format("/dex %s /squelch /chase on %s", character, mq.TLO.Me.DisplayName()),
                }
            end,
            pause = function()
                return {
                    string.format("/dex %s /squelch /mqp on", character),
                }
            end,
            unpause = function()
                return {
                    string.format("/dex %s /squelch /mqp off", character),
                }
            end,
            camp = function()
                return {
                    string.format("/dex %s /squelch /mqp off", character),
                    string.format("/dex %s /squelch /camphere on", character),
                }
            end,
            uncamp = function()
                return {
                    string.format("/dex %s /squelch /camphere off", character),
                    string.format("/dex %s /squelch /chaseon", character),
                    string.format("/dex %s /squelch /mqp on", character),
                }
            end,
        },
        [5] = {
            start = function()
                return {
                    string.format("/dex %s /squelch /mac muleassist %s", character, mq.TLO.Me.DisplayName()),
                    string.format("/dex %s /squelch /chase on %s", character, mq.TLO.Me.DisplayName()),
                }
            end,
            pause = function()
                return {
                    string.format("/dex %s /squelch /mqp on", character),
                }
            end,
            unpause = function()
                return {
                    string.format("/dex %s /squelch /mqp off", character),
                }
            end,
            camp = function()
                return {
                    string.format("/dex %s /squelch /mqp off", character),
                    string.format("/dex %s /squelch /camphere on", character),
                }
            end,
            uncamp = function()
                return {
                    string.format("/dex %s /squelch /camphere off", character),
                    string.format("/dex %s /squelch /chaseon", character),
                    string.format("/dex %s /squelch /mqp on", character),
                }
            end,
        },
    }
    if character == mq.TLO.Me.DisplayName() then
        if commands_self[script] and commands_self[script][action] then
            local cmds = commands_self[script][action]()
            for _, cmd in ipairs(cmds) do
                mq.cmd(cmd)
            end
        end
    else
        if commands_group[script] and commands_group[script][action] then
            local cmds = commands_group[script][action]()
            for _, cmd in ipairs(cmds) do
                mq.cmd(cmd)
            end
        end
    end
end

function manage.groupTalk(item, choice, name)
    manage.removeInvis(item, choice, name)
    _G.State:setStatusText(string.format("Talking to %s (%s).", item.npc, item.phrase))
    logger.log_info("\aoHaving all grouped characters say \ag%s \ao to \ag%s\ao.", item.phrase, item.npc)
    if mq.TLO.Spawn(item.npc).Distance() ~= nil then
        if mq.TLO.Spawn(item.npc).Distance() > MAX_DISTANCE then
            logger.log_warn("\ar%s \aois over %s units away. Moving back to step \ar%s\ao.", item.npc, MAX_DISTANCE, _G.State.current_step)
            _G.State:handle_step_change(_G.State.current_step - 1)
            return
        end
    end
    if choice == 1 then
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
            logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
            mq.TLO.Spawn(item.npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", item.phrase)
        mq.delay(750)
    elseif choice == 2 then
        for i = 1, group.Members() do
            if group.Member(i).DisplayName() ~= me.DisplayName() then
                mq.cmdf("/dex %s /squelch /target id %s", group.Member(i).DisplayName(), mq.TLO.Spawn(item.npc).ID())
                mq.delay(300)
                mq.cmdf("/dex %s /say %s", group.Member(i).DisplayName(), item.phrase)
            end
            math.randomseed(os.time())
            local wait = math.random(RANDOM_MIN, RANDOM_MAX)
            mq.delay(wait)
        end
        math.randomseed(os.time())
        local wait = math.random(RANDOM_MIN, RANDOM_MAX)
        mq.delay(wait)
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
            mq.TLO.Spawn(item.npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", item.phrase)
        mq.delay(750)
    else
        mq.cmdf("/dex %s /squelch /target id %s", name, mq.TLO.Spawn(item.npc).ID())
        mq.delay(300)
        mq.cmdf("/dex %s /say %s", name, item.phrase)
        math.randomseed(os.time())
        local wait = math.random(RANDOM_MIN, RANDOM_MAX)
        mq.delay(wait)
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
            mq.TLO.Spawn(item.npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", item.phrase)
        mq.delay(750)
    end
end

function manage.openDoorAll(item, choice, name)
    logger.log_info("\aoHaving group click door.")
    if choice == 1 then
        mq.delay(200)
        mq.cmd("/squelch /doortarget")
        mq.delay(200)
        mq.cmd("/squelch /click left door")
        mq.delay(1000)
    elseif choice == 2 then
        mq.delay(200)
        mq.cmd("/dgga /squelch /doortarget")
        mq.delay(200)
        mq.cmd("/dgga /squelch /click left door")
        mq.delay(1000)
    else
        mq.delay(200)
        mq.cmd("/squelch /doortarget")
        mq.cmdf("/dex %s /squelch /doortarget", name)
        mq.delay(200)
        mq.cmdf("/dex %s /squelch /click left door", name)
        mq.cmd("/squelch /click left door")
        mq.delay(100)
    end
end

function manage.pauseGroup(class_settings)
    local choice, name = _G.State:readGroupSelection()
    logger.log_info("\aoPausing class automation for all group members.")
    manage.doAutomation(me.DisplayName(), me.Class.ShortName(), class_settings.class[me.Class.Name()], 'pause')
    if choice == 1 then
        return
    elseif choice == 2 then
        for i = 1, group.Members() do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(group.Member(i).DisplayName(), group.Member(i).Class.ShortName(), class_settings.class[group.Member(i).Class.Name()], 'pause')
            end
        end
    else
        manage.doAutomation(name, group.Member(name).Class.ShortName(), class_settings.class[group.Member(name).Class.Name()], 'pause')
    end
end

function manage.picklockGroup(item, choice, name)
    _G.State:setStatusText("Lockpicking door.")
    logger.log_info("\aoLockpicking door.")
    if choice == 1 then
        if me.Class.ShortName() == 'BRD' or me.Class.ShortName() == 'ROG' then
            logger.log_verbose("\aoI am able to pick locks, doing so now.")
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
        else
            logger.log_error("\aoI am not a class that is able to pick locks. Stopping script at step \ar%s \ao.", _G.State.current_step)
            _G.State:setStatusText(string.format("I require a lockpicker to proceed. (%s).", _G.State.current_step))
            _G.State:setTaskRunning(false)
            mq.cmd('/foreground')
            return
        end
    elseif choice == 2 then
        local pickerFound = false
        if me.Class.ShortName() == 'BRD' or me.Class.ShortName() == 'ROG' then
            logger.log_verbose("\aoI am able to pick locks, doing so now.")
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
            pickerFound = true
        else
            for i = 1, group.Members() do
                if group.Member(i).Class.ShortName() == 'BRD' or group.Member(i).Class.ShortName() == 'ROG' then
                    logger.log_verbose("\ag%s \aois able to pick locks. Having them do so.", group.Member(i).DisplayName())
                    mq.cmdf("/dex %s /squelch /itemnotify lockpicks leftmouseup", group.Member(i).DisplayName())
                    mq.delay(200)
                    mq.cmdf("/dex %s /squelch /doortarget", group.Member(i).DisplayName())
                    mq.delay(200)
                    mq.cmdf("/dex %s /squelch /click left door", group.Member(i).DisplayName())
                    mq.delay(200)
                    mq.cmdf("/dex %s /squelch /autoinv", group.Member(i).DisplayName())
                    pickerFound = true
                    break
                end
            end
        end
        if pickerFound == false then
            _G.State:setStatusText(string.format("I require a lockpicker to proceed. (%s).", _G.State.current_step))
            logger.log_error("\aoNo one in my group is a class that is able to pick locks. Stopping script at step \ar%s \ao.", _G.State.current_step)
            _G.State:setTaskRunning(false)
            mq.cmd('/foreground')
            return
        end
    else
        if group.Member(name).Class.ShortName() == 'BRD' or group.Member(name).Class.ShortName() == 'ROG' then
            logger.log_verbose("\ag%s \aois able to pick locks. Having them do so.", group.Member(name).DisplayName())
            mq.cmdf("/dex %s /squelch /itemnotify lockpicks leftmouseup", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /doortarget", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /click left door", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /autoinv", name)
        elseif mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            logger.log_verbose("\aoI am able to pick locks, doing so now.")
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
        else
            _G.State:setStatusText(string.format("I require a lockpicker to proceed. (%s).", _G.State.current_step))
            logger.log_error("\aoI am not a class that is able to pick locks, nor is \ag%s\ao. Stopping script at step \ar%s \ao.", group.Member(name).DisplayName(),
                _G.State.current_step)
            _G.State:setTaskRunning(false)
            mq.cmd('/foreground')
            return
        end
    end
end

function manage.removeInvis(item)
    local choice, name = _G.State:readGroupSelection()
    local temp = _G.State:readStatusText()
    _G.State:setStatusText("Removing invis.")
    if me.Invis() then
        logger.log_info("\aoRemoving invisibility.")
        if choice == 1 then
            mq.cmd("/squelch /makemevis")
        elseif choice == 2 then
            mq.cmd("/dgga /squelch /makemevis")
        else
            mq.cmdf("/squelch /makemevis")
            mq.cmdf("/dex %s /squelch /makemevis", name)
        end
    end
    _G.State:setStatusText(temp)
end

function manage.removeLev()
    local choice, name = _G.State:readGroupSelection()
    _G.State:setStatusText("Removing levitate.")
    logger.log_info("\aoRemoving levitate.")
    if choice == 1 then
        mq.cmd("/squelch /removelev")
    elseif choice == 2 then
        mq.cmd("/dgga /squelch /removelev")
    else
        mq.cmdf("/squelch /removelev")
        mq.cmdf("/dex %s /squelch /removelev", name)
    end
end

function manage.sendYes(item, choice, name)
    logger.log_info("\aoGive me a yes!")
    if choice == 1 then
        mq.cmd("/squelch /yes")
    elseif choice == 2 then
        mq.cmd("/dgga /squelch /yes")
    else
        mq.cmdf("/squelch /yes")
        mq.cmdf("/dex %s /squelch /yes", name)
    end
end

function manage.setRadius(character, class, script, radius, char_settings)
    logger.log_verbose("\aoSetting radius to \ag%s\ao.", radius)
    if script == 1 then
        mq.cmdf('/squelch /%s pullradius %s nosave', class, radius)
    elseif script == 2 then
        mq.cmdf("/squelch /rgl set pullradiushunt %s", radius)
    elseif script == 3 then
        mq.cmd("/squelch /rg pullrad %s", radius)
    elseif script == 4 then
        mq.cmd("/squelch /maxradius %s", radius)
    elseif script == 5 then
        mq.cmd("/squelch /maxradius %s", radius)
    end
end

function manage.startGroup(class_settings, char_settings)
    local choice, name = _G.State:readGroupSelection()
    logger.log_verbose("\aoStarting class automation for group and setting group roles.")
    if me.Grouped() == true and group.Leader() == me.DisplayName() then
        logger.log_super_verbose("\aoSetting self to MA and MT.")
        mq.cmdf("/squelch /grouprole set %s 1", mq.TLO.Me.DisplayName())
        mq.cmdf("/squelch /grouprole set %s 2", mq.TLO.Me.DisplayName())
    end
    manage.doAutomation(me.DisplayName(), me.Class.ShortName(), class_settings.class[me.Class.Name()], 'start', char_settings)
    if choice == 1 then
        return
    elseif choice == 2 then
        for i = 1, group.Members() do
            if group.Member(i).DisplayName() ~= me.DisplayName() then
                manage.doAutomation(group.Member(i).DisplayName(), group.Member(i).Class.ShortName(), class_settings.class[group.Member(i).Class.Name()], 'start', char_settings)
            end
        end
    else
        manage.doAutomation(name, group.Member(name).Class.ShortName(), class_settings.class[group.Member(name).Class.Name()], 'start', char_settings)
    end
end

function manage.uncampGroup(class_settings)
    local choice, name = _G.State:readGroupSelection()
    logger.log_info("\aoEnding camp mode.")
    manage.doAutomation(me.DisplayName(), me.Class.ShortName(), class_settings.class[me.Class.Name()], 'uncamp')
    if choice == 1 then
        return
    elseif choice == 2 then
        for i = 1, group.Members() do
            if group.Member(i).DisplayName() ~= me.DisplayName() then
                manage.doAutomation(group.Member(i).DisplayName(), group.Member(i).Class.ShortName(), class_settings.class[group.Member(i).Class.Name()], 'uncamp')
            end
        end
    else
        manage.doAutomation(name, group.Member(name).Class.ShortName(), class_settings.class[group.Member(name).Class.Name()], 'uncamp')
    end
end

function manage.unpauseGroup(class_settings)
    local choice, name = _G.State:readGroupSelection()
    logger.log_info("\aoUnpausing class automation for group.")
    manage.doAutomation(me.DisplayName(), me.Class.ShortName(), class_settings.class[me.Class.Name()], 'unpause')
    if choice == 1 then
        return
    elseif choice == 2 then
        for i = 1, group.Members() do
            if group.Member(i).DisplayName() ~= me.DisplayName() then
                manage.doAutomation(group.Member(i).DisplayName(), group.Member(i).Class.ShortName(), class_settings.class[group.Member(i).Class.Name()], 'unpause')
            end
        end
    else
        manage.doAutomation(name, group.Member(name).Class.ShortName(), class_settings.class[group.Member(name).Class.Name()], 'unpause')
    end
end

return manage
