local mq = require('mq')
local dist = require 'utils/distance'

local manage = {}
local elheader = "\ay[\agEpic Laziness\ay]"

function manage.picklockGroup(group_set)
    if group_set == 1 then
        if mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            mq.cmd("/itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/doortarget")
            mq.delay(200)
            mq.cmd("/click left door")
            mq.delay(200)
            mq.cmd("/autoinv")
        else
            printf("%s \aoI am not a class that is able to pick locks.", elheader)
        end
    elseif group_set == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).Class.ShortName() == 'BRD' or mq.TLO.Group.Member(i).Class.ShortName() == 'ROG' then
                mq.cmdf("/dex %s /itemnotify lockpicks leftmouseup", mq.TLO.Group.Member(i).DisplayName())
                mq.delay(200)
                mq.cmdf("/dex %s /doortarget", mq.TLO.Group.Member(i).DisplayName())
                mq.delay(200)
                mq.cmdf("/dex %s /click left door", mq.TLO.Group.Member(i).DisplayName())
                mq.delay(200)
                mq.cmdf("/dex %s /autoinv", mq.TLO.Group.Member(i).DisplayName())
            end
        end
    else
        local name = State.group_combo[State.group_choice]
        if mq.TLO.Group.Member(name).Class.ShortName() == 'BRD' or mq.TLO.Group.Member(name).Class.ShortName() == 'ROG' then
            mq.cmdf("/dex %s /itemnotify lockpicks leftmouseup", name)
            mq.delay(200)
            mq.cmdf("/dex %s /doortarget", name)
            mq.delay(200)
            mq.cmdf("/dex %s /click left door", name)
            mq.delay(200)
            mq.cmdf("/dex %s /autoinv", name)
        elseif mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            mq.cmd("/itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/doortarget")
            mq.delay(200)
            mq.cmd("/click left door")
            mq.delay(200)
            mq.cmd("/autoinv")
        else
            printf("%s \aoI require a class that is able to pick locks.", elheader)
        end
    end
end

function manage.groupTalk(group_set, npc, phrase)
    if group_set == 1 then
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(npc).ID() then
            mq.cmdf('/target id %s', mq.TLO.Spawn(npc).ID())
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    elseif group_set == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                mq.cmdf("/dex %s /target id %s", mq.TLO.Group.Member(i).DisplayName(), npc)
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
            mq.cmdf('/target id %s', mq.TLO.Spawn(npc).ID())
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    else
        mq.cmdf("/dex %s /target id %s", State.group_combo[State.group_choice], npc)
        mq.delay(300)
        mq.cmdf("/dex %s /say %s", State.group_combo[State.group_choice], phrase)
        math.randomseed(os.time())
        local wait = math.random(4000, 10000)
        mq.delay(wait)
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(npc).ID() then
            mq.cmdf('/target id %s', mq.TLO.Spawn(npc).ID())
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    end
end

function manage.campGroup(group_set, radius, class_settings)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'camp')
    if group_set == 1 then
        return
    elseif group_set == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'camp')
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'camp')
    end
    manage.setRadius(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(), class_settings.class[mq.TLO.Me.Class.Name()],
        radius)
end

function manage.uncampGroup(group_set, class_settings)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'uncamp')
    if group_set == 1 then
        return
    elseif group_set == 2 then
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

function manage.faceLoc(group_set, x, y, z)
    if group_set == 1 then
        mq.cmdf("/face loc %s,%s,%s", y, x, z)
    elseif group_set == 2 then
        mq.cmdf("/dgga /face loc %s,%s,%s", y, x, z)
    else
        mq.cmdf("/face loc %s,%s,%s", y, x, z)
        mq.cmdf("/dex %s /face loc %s,%s,%s", State.group_combo[State.group_choice], y, x, z)
    end
end

function manage.locTravelGroup(group_set, x, y, z)
    local loopCount = 0
    if group_set == 1 then
        mq.cmdf("/squelch /nav locxyz %s %s %s", x, y, z)
    elseif group_set == 2 then
        mq.cmdf("/dgga /squelch /nav locxyz %s %s %s", x, y, z)
    else
        mq.cmdf("/squelch /nav locxyz %s %s %s", x, y, z)
        mq.cmdf("/dex %s /squelch /nav locxyz %s %s %s", State.group_combo[State.group_choice], x, y, z)
    end
    mq.delay(200)
    while mq.TLO.Nav.Active() do
        if loopCount == 20 then
            mq.cmd('/squelch /doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/squelch /click left door')
                end
            end
            loopCount = 0
        end
        loopCount = loopCount + 1
    end
end

function manage.stopfollowGroup(group_set)
    if group_set == 1 then
        mq.cmd('/squelch /afollow off')
    elseif group_set == 2 then
        mq.cmd('/dgga /squelch /afollow off')
    else
        mq.cmd('/squelch /afollow off')
        mq.cmdf('/dex %s /squelch /afollow off', State.group_combo[State.group_choice])
    end
end

function manage.followGroup(group_set, npc)
    if group_set == 1 then
        mq.cmdf('/target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/squelch /afollow')
    elseif group_set == 2 then
        mq.cmdf('/dgga /target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/dgga /squelch /afollow')
    else
        mq.cmdf('/target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.cmdf('/dex %s /nav id %s', State.group_combo[State.group_choice], mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/squelch /afollow')
        mq.cmdf('/dex %s /squelch /afollow', State.group_combo[State.group_choice])
    end
end

function manage.followGroupLoc(group_set, npc, x, y)
    if group_set == 1 then
        mq.cmdf('/target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/squelch /afollow')
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 50 do
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd('/squelch /afollow off')
    elseif group_set == 2 then
        mq.cmdf('/dgga /target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/dgga /squelch /afollow')
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 50 do
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd('/dgga /squelch /afollow off')
    else
        mq.cmdf('/target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.cmdf('/dex %s /squelch /nav id %s', State.group_combo[State.group_choice], mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/squelch /afollow')
        mq.cmdf('/dex %s /squelch /afollow', State.group_combo[State.group_choice])
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 50 do
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd('/squelch /afollow off')
        mq.cmdf('/dex %s /squelch /afollow off', State.group_combo[State.group_choice])
    end
end

function manage.navGroup(group_set, npc)
    local loopCount = 0
    if group_set == 1 then
        mq.cmdf("/squelch /nav id %s", mq.TLO.Spawn("npc " .. npc).ID())
    elseif group_set == 2 then
        mq.cmdf("/dgga /squelch /nav id %s", mq.TLO.Spawn("npc " .. npc).ID())
    else
        mq.cmdf("/squelch /nav id %s", mq.TLO.Spawn("npc " .. npc).ID())
        mq.cmdf('/dex %s /squelch /nav id %s', State.group_combo[State.group_choice], mq.TLO.Spawn("npc " .. npc).ID())
    end
    mq.delay(200)
    while mq.TLO.Nav.Active() do
        if loopCount == 20 then
            mq.cmd('/squelch /doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/click left door')
                end
            end
            loopCount = 0
        end
        loopCount = loopCount + 1
    end
end

function manage.navGroupLoc(group_set, npc, x, y, z)
    local loopCount = 0
    local searchstring = "loc " .. x .. " " .. y .. " " .. z .. " radius 50 npc " .. npc
    if group_set == 1 then
        mq.cmdf("/squelch /nav id %s", mq.TLO.Spawn(searchstring).ID())
    elseif group_set == 2 then
        mq.cmdf("/dgga /squelch /nav id %s", mq.TLO.Spawn(searchstring).ID())
    else
        mq.cmdf("/squelch /nav id %s", mq.TLO.Spawn(searchstring).ID())
        mq.cmdf('/dex %s /squelch /nav id %s', State.group_combo[State.group_choice], mq.TLO.Spawn(searchstring).ID())
    end
    mq.delay(200)
    while mq.TLO.Nav.Active() do
        if loopCount == 20 then
            mq.cmd('/squelch /doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/squelch /click left door')
                end
            end
            loopCount = 0
        end
        loopCount = loopCount + 1
    end
end

function manage.noNavTravel(group_set, x, y, z)
    if group_set == 1 then
        mq.cmd("/keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd("/keypress forward")
    elseif group_set == 2 then
        mq.cmd("/dgge /keypress forward hold")
        mq.cmd("/keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd("/dgge /keypress forward")
        mq.cmd("/keypress forward")
    else
        mq.cmdf("/dex %s /keypress forward hold", State.group_combo[State.group_choice])
        mq.cmd("/keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmdf("/dex %s /keypress forward", State.group_combo[State.group_choice])
        mq.cmd("/keypress forward")
    end
end

function manage.zoneGroup(group_set, zone)
    if group_set == 1 then
        mq.cmdf("/squelch /travelto %s", zone)
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
        end
        mq.delay("1s")
    elseif group_set == 2 then
        mq.cmdf("/dgga /squelch /travelto %s", zone)
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
        end
        while mq.TLO.Group.AnyoneMissing() do
            mq.delay(500)
        end
        mq.delay("5s")
    else
        mq.cmdf("/squelch /travelto %s", zone)
        mq.cmdf('/dex %s /squelch /travelto %s', State.group_combo[State.group_choice], zone)
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
        end
        while mq.TLO.Group.Member(State.group_combo[State.group_choice]).OtherZone() do
            mq.delay(500)
        end
        mq.delay("5s")
    end
end

function manage.gateGroup(group_set)
    if group_set == 1 then
        mq.cmd("/relocate gate")
        mq.delay(500)
    elseif group_set == 2 then
        mq.cmd("/dgga /relocate gate")
        mq.delay(500)
    else
        mq.cmd("/relocate gate")
        mq.cmdf('/dex %s /relocate gate', State.group_combo[State.group_choice])
    end
end

function manage.pauseGroup(group_set, class_settings)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'pause')
    if group_set == 1 then
        return
    elseif group_set == 2 then
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

function manage.unpauseGroup(group_set, class_settings)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'unpause')
    if group_set == 1 then
        return
    elseif group_set == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.clas[mq.TLO.Group.Member(i).Class.Name()],
                    'unpause')
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'unpause')
    end
end

function manage.startGroup(group_set, class_settings)
    if mq.TLO.Me.Grouped() == true then
        mq.cmdf("/grouprole set %s 1", mq.TLO.Me.DisplayName())
        mq.cmdf("/grouprole set %s 2", mq.TLO.Me.DisplayName())
        mq.cmdf("/grouprole set %s 3", mq.TLO.Me.DisplayName())
    end
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'start')
    if group_set == 1 then
        return
    elseif group_set == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'start')
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'start')
    end
end

function manage.doAutomation(character, class, script, action)
    if action == 'start' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/%s mode 0', class)
            elseif script == 2 then
                mq.cmd("/lua run rgmercs")
            elseif script == 3 then
                mq.cmd("/mac rgmercs")
            elseif script == 4 then
                mq.cmd("/mac kissassist")
            elseif script == 5 then
                mq.cmd("/mac muleassist")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /%s mode 2', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /lua run rgmercs", character)
                mq.delay(500)
                mq.cmdf('/dex %s /rgl chaseon %s', character, mq.TLO.Me.DisplayName())
            elseif script == 3 then
                mq.cmdf("/dex %s /mac rgmercs", character)
                mq.delay(500)
                mq.cmdf('/dex %s /rg chaseon %s', character, mq.TLO.Me.DisplayName())
            elseif script == 4 then
                mq.cmdf("/dex %s /mac kissassist", character)
                mq.cmdf("/dex %s /chase on %s", character, mq.TLO.Me.DisplayName())
            elseif script == 5 then
                mq.cmdf("/dex %s /mac muleassist", character)
                mq.cmdf("/dex %s /chase on %s", character, mq.TLO.Me.DisplayName())
            end
        end
    elseif action == 'pause' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/%s pause on', class)
            elseif script == 2 then
                mq.cmd("/rgl pause")
            elseif script == 3 then
                mq.cmd("/rg off")
            elseif script == 4 then
                mq.cmd("/mqp on")
            elseif script == 5 then
                mq.cmd("/mqp on")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /%s pause on', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /rgl pause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /rg off", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /mqp on", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /mqp on", character)
            end
        end
    elseif action == 'unpause' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/%s pause off', class)
            elseif script == 2 then
                mq.cmd("/rgl unpause")
            elseif script == 3 then
                mq.cmd("/rg on")
            elseif script == 4 then
                mq.cmd("/mqp off")
            elseif script == 5 then
                mq.cmd("/mqp off")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /%s pause off', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /rgl unpause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /rg on", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /mqp off", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /mqp off", character)
            end
        end
    elseif action == 'camp' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/%s resetcamp', class)
                mq.cmdf('/%s mode 5', class)
                mq.cmdf('/%s pause off', class)
            elseif script == 2 then
                mq.cmd("/rgl campon")
                mq.cmd("/rgl unpause")
                mq.cmd("/rgl set dopull on")
            elseif script == 3 then
                mq.cmd("/rg camphere")
                mq.cmd("/rg on")
            elseif script == 4 then
                mq.cmd("/mqp off")
                mq.cmd("/camphere on")
            elseif script == 5 then
                mq.cmd("/mqp off")
                mq.cmd("/camphere on")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /%s resetcamp', character, class)
                mq.cmdf('/dex %s /%s mode 1', character, class)
                mq.cmdf('/dex %s /%s pause off', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /rgl campon", character)
                mq.cmdf("/dex %s /rgl unpause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /rg camphere", character)
                mq.cmdf("/dex %s /rg on", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /mqp off", character)
                mq.cmdf("/dex %s /camphere on", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /mqp off", character)
                mq.cmdf("/dex %s /camphere on", character)
            end
        end
    elseif action == 'uncamp' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/%s mode 0', class)
                mq.cmdf('/%s pause on', class)
            elseif script == 2 then
                mq.cmd("/rgl campoff")
                mq.cmd("/rgl pause")
            elseif script == 3 then
                mq.cmd("/rg campoff")
                mq.cmd("/rg off")
            elseif script == 4 then
                mq.cmd("/camphere off")
                mq.cmd("/mqp on")
            elseif script == 5 then
                mq.cmd("/camphere off")
                mq.cmd("/mqp on")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /%s mode 2', character, class)
                mq.cmdf('/dex %s /%s pause on', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /rgl campoff", character)
                mq.cmdf('/dex %s /rgl chaseon %s', character, mq.TLO.Me.DisplayName())
                mq.cmdf("/dex %s /rgl pause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /rg camphere", character)
                mq.cmdf('/dex %s /rg chaseon %s', character, mq.TLO.Me.DisplayName())
                mq.cmdf("/dex %s /rg off", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /camphere off", character)
                mq.cmdf("/dex %s /chaseon", character)
                mq.cmdf("/dex %s /mqp on", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /camphere off", character)
                mq.cmdf("/dex %s /chaseon", character)
                mq.cmdf("/dex %s /mqp on", character)
            end
        end
    end
end

function manage.setRadius(character, class, script, radius)
    if script == 1 then
        mq.cmdf('/%s pullradius %s', class, radius)
    elseif script == 2 then
        mq.cmd("/rgl set pullradius %s", radius)
    elseif script == 3 then
        mq.cmd("/rg pullrad %s", radius)
    elseif script == 4 then
        mq.cmd("/maxradius %s", radius)
    elseif script == 5 then
        mq.cmd("/maxradius %s", radius)
    end
end

return manage
