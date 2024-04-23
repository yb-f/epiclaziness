local mq     = require('mq')
local dist   = require 'utils/distance'

local manage = {}

function manage.campGroup(radius, class_settings, char_settings)
    Logger.log_info("\aoSetting camp mode with radius \ag%s\ao.", radius)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'camp', char_settings)
    manage.setRadius(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(), class_settings.class[mq.TLO.Me.Class.Name()],
        radius, char_settings)
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'camp', char_settings)
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'camp',
            char_settings)
    end
end

function manage.doAutomation(character, class, script, action, char_settings)
    if action == 'start' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s mode 0 nosave', class)
                mq.cmdf('/squelch /%s usestick on nosave', class)
                mq.cmdf('/squelch /%s zhigh 100 nosave', class)
                mq.cmdf('/squelch /%s zlow 100 nosave', class)
            elseif script == 2 then
                mq.cmdf("/squelch /lua run rgmercs %s", mq.TLO.Me.DisplayName())
                mq.cmd("/squelch /rgl set PullZRadius 100")
                mq.cmd("/squelch /rgl set pullmincon 1")
            elseif script == 3 then
                mq.cmd("/squelch /mac rgmercs")
            elseif script == 4 then
                mq.cmd("/squelch /mac kissassist")
                mq.cmd("/squelch /maxzrange 100")
            elseif script == 5 then
                mq.cmd("/squelch /mac muleassist")
                mq.cmd("/squelch /maxzrange 100")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s mode 2 nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /lua run rgmercs", character)
                mq.delay(500)
                mq.cmdf('/dex %s /squelch /rgl chaseon %s', character, mq.TLO.Me.DisplayName())
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /mac rgmercs", character)
                mq.delay(500)
                mq.cmdf('/dex %s /squelch /rg chaseon %s', character, mq.TLO.Me.DisplayName())
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /mac kissassist", character)
                mq.cmdf("/dex %s /squelch /chase on %s", character, mq.TLO.Me.DisplayName())
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /mac muleassist", character)
                mq.cmdf("/dex %s /squelch /chase on %s", character, mq.TLO.Me.DisplayName())
            end
        end
    elseif action == 'pause' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s pause on nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /rgl pause")
            elseif script == 3 then
                mq.cmd("/squelch /rg off")
            elseif script == 4 then
                mq.cmd("/squelch /mqp on")
            elseif script == 5 then
                mq.cmd("/squelch /mqp on")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s pause on nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /rgl pause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /rg off", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /mqp on", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /mqp on", character)
            end
        end
    elseif action == 'unpause' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s pause off nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /rgl unpause")
            elseif script == 3 then
                mq.cmd("/squelch /rg on")
            elseif script == 4 then
                mq.cmd("/squelch /mqp off")
            elseif script == 5 then
                mq.cmd("/squelch /mqp off")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s pause off nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /rgl unpause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /rg on", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /mqp off", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /mqp off", character)
            end
        end
    elseif action == 'camp' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s resetcamp nosave', class)
                mq.cmdf('/squelch /%s mode HunterTank nosave', class)
                mq.cmdf('/squelch /%s pause off nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /rgl unpause")
                mq.cmd("/squelch /rgl set pullmode 3")
                mq.cmd("/squelch /rgl set dopull on")
            elseif script == 3 then
                mq.cmd("/squelch /rg camphere")
                mq.cmd("/squelch /rg on")
            elseif script == 4 then
                mq.cmd("/squelch /mqp off")
                mq.cmd("/squelch /camphere on")
            elseif script == 5 then
                mq.cmd("/squelch /mqp off")
                mq.cmd("/squelch /camphere on")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s resetcamp nosave', character, class)
                mq.cmdf('/dex %s /squelch /%s mode 1 nosave', character, class)
                mq.cmdf('/dex %s /squelch /%s pause off nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /rgl unpause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /rg camphere", character)
                mq.cmdf("/dex %s /squelch /rg on", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /mqp off", character)
                mq.cmdf("/dex %s /squelch /camphere on", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /mqp off", character)
                mq.cmdf("/dex %s /squelch /camphere on", character)
            end
        end
    elseif action == 'uncamp' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s mode 0 nosave', class)
                mq.cmdf('/squelch /%s pause on nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /rgl campoff")
                mq.cmd("/squelch /rgl pause")
            elseif script == 3 then
                mq.cmd("/squelch /rg campoff")
                mq.cmd("/squelch /rg off")
            elseif script == 4 then
                mq.cmd("/squelch /camphere off")
                mq.cmd("/squelch /mqp on")
            elseif script == 5 then
                mq.cmd("/squelch /camphere off")
                mq.cmd("/squelch /mqp on")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s mode 2 nosave', character, class)
                mq.cmdf('/dex %s /squelch /%s pause on nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /rgl campoff", character)
                mq.cmdf('/dex %s /squelch /rgl chaseon %s', character, mq.TLO.Me.DisplayName())
                mq.cmdf("/dex %s /squelch /rgl pause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /rg camphere", character)
                mq.cmdf('/dex %s /squelch /rg chaseon %s', character, mq.TLO.Me.DisplayName())
                mq.cmdf("/dex %s /squelch /rg off", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /camphere off", character)
                mq.cmdf("/dex %s /squelch /chaseon", character)
                mq.cmdf("/dex %s /squelch /mqp on", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /camphere off", character)
                mq.cmdf("/dex %s /squelch /chaseon", character)
                mq.cmdf("/dex %s /squelch /mqp on", character)
            end
        end
    end
end

function manage.groupTalk(npc, phrase)
    if mq.TLO.Spawn(npc).Distance() ~= nil then
        if mq.TLO.Spawn(npc).Distance() > 100 then
            State.rewound = true
            State.step = State.step - 1
            Logger.log_warn("\ar%s \aois over 100 units away. Moving back to step \ar%s\ao.", npc, State.step)
            return
        end
    end
    if State.group_choice == 1 then
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(npc).ID() then
            Logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
            mq.TLO.Spawn(npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                mq.cmdf("/dex %s /squelch /target id %s", mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Spawn(npc).ID())
                mq.delay(300)
                mq.cmdf("/dex %s /say %s", mq.TLO.Group.Member(i).DisplayName(), phrase)
            end
            math.randomseed(os.time())
            local wait = math.random(4000, 10000)
            mq.delay(wait)
        end
        math.randomseed(os.time())
        local wait = math.random(4000, 10000)
        mq.delay(wait)
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(npc).ID() then
            mq.TLO.Spawn(npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    else
        mq.cmdf("/dex %s /squelch /target id %s", State.group_combo[State.group_choice], mq.TLO.Spawn(npc).ID())
        mq.delay(300)
        mq.cmdf("/dex %s /say %s", State.group_combo[State.group_choice], phrase)
        math.randomseed(os.time())
        local wait = math.random(4000, 10000)
        mq.delay(wait)
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(npc).ID() then
            mq.TLO.Spawn(npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    end
end

function manage.openDoorAll()
    Logger.log_info("\aoHaving group click door.")
    if State.group_choice == 1 then
        mq.delay(200)
        mq.cmd("/squelch /doortarget")
        mq.delay(200)
        mq.cmd("/squelch /click left door")
        mq.delay(1000)
    elseif State.group_choice == 2 then
        mq.delay(200)
        mq.cmd("/dgga /squelch /doortarget")
        mq.delay(200)
        mq.cmd("/dgga /squelch /click left door")
        mq.delay(1000)
    else
        local name = State.group_combo[State.group_choice]
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
    Logger.log_info("\aoPausing class automation for all group members.")
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'pause')
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'pause')
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'pause')
    end
end

function manage.picklockGroup()
    State.status = "Lockpicking door"
    Logger.log_info("\aoLockpicking door.")
    if State.group_choice == 1 then
        if mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            Logger.log_verbose("\aoI am able to pick locks, doing so now.")
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
        else
            Logger.log_error("\aoI am not a class that is able to pick locks. Stopping script at step \ar%s \ao.", State.step)
            State.status = "I require a lockpicker to proceed. (" .. State.step .. ")"
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    elseif State.group_choice == 2 then
        local pickerFound = false
        if mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            Logger.log_verbose("\aoI am able to pick locks, doing so now.")
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
            pickerFound = true
        else
            for i = 0, mq.TLO.Group.GroupSize() - 1 do
                if mq.TLO.Group.Member(i).Class.ShortName() == 'BRD' or mq.TLO.Group.Member(i).Class.ShortName() == 'ROG' then
                    Logger.log_verbose("\ag%s \aois able to pick locks. Having them do so.", mq.TLO.Group.Member(i).DisplayName())
                    mq.cmdf("/dex %s /squelch /itemnotify lockpicks leftmouseup", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(200)
                    mq.cmdf("/dex %s /squelch /doortarget", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(200)
                    mq.cmdf("/dex %s /squelch /click left door", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(200)
                    mq.cmdf("/dex %s /squelch /autoinv", mq.TLO.Group.Member(i).DisplayName())
                    pickerFound = true
                    break
                end
            end
        end
        if pickerFound == false then
            State.status = "I require a lockpicker to proceed. (" .. State.step .. ")"
            Logger.log_error("\aoNo one in my group is a class that is able to pick locks. Stopping script at step \ar%s \ao.", State.step)
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    else
        local name = State.group_combo[State.group_choice]
        if mq.TLO.Group.Member(name).Class.ShortName() == 'BRD' or mq.TLO.Group.Member(name).Class.ShortName() == 'ROG' then
            Logger.log_verbose("\ag%s \aois able to pick locks. Having them do so.", mq.TLO.Group.Member(name).DisplayName())
            mq.cmdf("/dex %s /squelch /itemnotify lockpicks leftmouseup", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /doortarget", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /click left door", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /autoinv", name)
        elseif mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            Logger.log_verbose("\aoI am able to pick locks, doing so now.")
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
        else
            State.status = "I require a lockpicker to proceed. (" .. State.step .. ")"
            Logger.log_error("\aoI am not a class that is able to pick locks, nor is \ag%s\ao. Stopping script at step \ar%s \ao.", mq.TLO.Group.Member(name).DisplayName(),
                State.step)
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    end
end

function manage.removeInvis()
    local temp = State.status
    State.status = "Removing invis"
    if mq.TLO.Me.Invis() then
        Logger.log_info("\aoRemoving invisibility.")
        if State.group_choice == 1 then
            mq.cmd("/squelch /makemevis")
        elseif State.group_choice == 2 then
            mq.cmd("/dgga /squelch /makemevis")
        else
            mq.cmdf("/squelch /makemevis")
            mq.cmdf("/dex %s /squelch /makemevis", State.group_combo[State.group_choice])
        end
    end
    State.status = temp
end

function manage.removeLev()
    State.status = "Removing levitate"
    Logger.log_info("\aoRemoving levitate.")
    if State.group_choice == 1 then
        mq.cmd("/squelch /removelev")
    elseif State.group_choice == 2 then
        mq.cmd("/dgga /squelch /removelev")
    else
        mq.cmdf("/squelch /removelev")
        mq.cmdf("/dex %s /squelch /removelev", State.group_combo[State.group_choice])
    end
end

function manage.sendYes()
    Logger.log_info("\aoGive me a yes!")
    if State.group_choice == 1 then
        mq.cmd("/squelch /yes")
    elseif State.group_choice == 2 then
        mq.cmd("/dgga /squelch /yes")
    else
        mq.cmdf("/squelch /yes")
        mq.cmdf("/dex %s /squelch /yes", State.group_combo[State.group_choice])
    end
end

function manage.setRadius(character, class, script, radius, char_settings)
    Logger.log_verbose("\aoSetting radius to \ag%s\ao.", radius)
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
    Logger.log_verbose("\aoStarting class automation for group and setting group roles.")
    if mq.TLO.Me.Grouped() == true and mq.TLO.Group.Leader() == mq.TLO.Me.DisplayName() then
        Logger.log_super_verbose("\aoSetting self to MA and MT.")
        mq.cmdf("/squelch /grouprole set %s 1", mq.TLO.Me.DisplayName())
        mq.cmdf("/squelch /grouprole set %s 2", mq.TLO.Me.DisplayName())
        --mq.cmdf("/grouprole set %s 3", mq.TLO.Me.DisplayName())
    end
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'start', char_settings)
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'start', char_settings)
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'start',
            char_settings)
    end
end

function manage.uncampGroup(class_settings)
    Logger.log_info("\aoEnding camp mode.")
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'uncamp')
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'uncamp')
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'uncamp')
    end
end

function manage.unpauseGroup(class_settings)
    Logger.log_info("\aoUnpausing class automation for group.")
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()], 'unpause')
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        local groupSize = 1
        if mq.TLO.Group.GroupSize() ~= nil then
            groupSize = mq.TLO.Group.GroupSize()
        end
        for i = 0, groupSize - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'unpause')
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'unpause')
    end
end

return manage
