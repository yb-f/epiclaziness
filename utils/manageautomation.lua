local mq = require('mq')
local dist = require 'utils/distance'

local manage = {}
local elheader = "\ay[\agEpic Laziness\ay]"

function manage.campGroup(group_set, radius, class_settings)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'camp')
    manage.setRadius(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(), class_settings.class[mq.TLO.Me.Class.Name()],
        radius)
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
                mq.cmdf('/%s mode PullerTank', class)
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

function manage.faceHeading(group_set, heading)
    if group_set == 1 then
        mq.cmdf("/face heading %s", heading)
    elseif group_set == 2 then
        mq.cmdf("/dgga /face heading %s", heading)
    else
        mq.cmdf("/face heading %s", heading)
        mq.cmdf("/dex %s /face heading %s", State.group_combo[State.group_choice], heading)
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

function manage.followGroup(group_set, npc)
    if group_set == 1 then
        mq.TLO.Spawn("npc " .. npc).DoTarget()
        mq.delay(300)
        mq.cmd('/afollow')
    elseif group_set == 2 then
        mq.cmdf('/dgga /target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/dgga /afollow')
    else
        mq.TLO.Spawn("npc " .. npc).DoTarget()
        mq.cmdf('/dex %s /nav id %s', State.group_combo[State.group_choice], mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/afollow')
        mq.cmdf('/dex %s /afollow', State.group_combo[State.group_choice])
    end
end

function manage.followGroupLoc(group_set, npc, x, y)
    if group_set == 1 then
        mq.TLO.Spawn("npc " .. npc).DoTarget()
        mq.delay(300)
        mq.cmd('/afollow')
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 50 do
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd('/afollow off')
    elseif group_set == 2 then
        mq.cmdf('/dgga /target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/dgga /afollow')
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 50 do
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd('/dgga /afollow off')
    else
        mq.TLO.Spawn("npc " .. npc).DoTarget()
        mq.cmdf('/dex %s /nav id %s', State.group_combo[State.group_choice], mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/afollow')
        mq.cmdf('/dex %s /afollow', State.group_combo[State.group_choice])
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 50 do
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd('/afollow off')
        mq.cmdf('/dex %s /afollow off', State.group_combo[State.group_choice])
    end
end

--WORK ON THIS ONE
function manage.forwardZone(group_set, zone)
    if group_set == 1 then
        mq.cmd("/keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
        end
        mq.delay("5s")
    elseif group_set == 2 then
        mq.cmd("/dgge /keypress forward hold")
        mq.cmd("/keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
        end
        while mq.TLO.Group.AnyoneMissing() do
            mq.delay(500)
        end
        mq.delay("5s")
    else
        mq.cmdf("/dex %s /keypress forward hold", State.group_combo[State.group_choice])
        mq.cmd("/keypress forward hold")
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

function manage.groupTalk(group_set, npc, phrase)
    if group_set == 1 then
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(npc).ID() then
            mq.TLO.Spawn(npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    elseif group_set == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                mq.cmdf("/dex %s /target id %s", mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Spawn(npc).ID())
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
        mq.cmdf("/dex %s /target id %s", State.group_combo[State.group_choice], mq.TLO.Spawn(npc).ID())
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

function manage.invis(group_set, class_settings)
    State.status = "Using invis"
    local invis_type = {}
    for word in string.gmatch(class_settings.class_invis[mq.TLO.Me.Class()], '([^|]+)') do
        table.insert(invis_type, word)
    end
    if invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Potion' then
        mq.cmd('/useitem "Cloudy Potion"')
    elseif invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Hide/Sneak' then
        mq.cmd("/doability hide")
        mq.delay(250)
        mq.cmd("/doability sneak")
    else
        mq.cmdf('/casting "%s"', invis_type[class_settings.invis[mq.TLO.Me.Class()]])
    end
    if group_set == 1 then
    elseif group_set == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                local invis_type = {}
                for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(i).Class()], '([^|]+)') do
                    table.insert(invis_type, word)
                end
                if invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == 'Potion' then
                    mq.cmdf('/dex %s /useitem "Cloudy Potion"', mq.TLO.Group.Member(i).DisplayName())
                elseif invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == 'Hide/Sneak' then
                    mq.cmdf("/dex %s /doability hide", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(250)
                    mq.cmdf("/dex %s /doability sneak", mq.TLO.Group.Member(i).DisplayName())
                else
                    mq.cmdf('/dex %s /casting "%s"', mq.TLO.Group.Member(i).DisplayName(),
                        invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]])
                end
            end
        end
    else
        local invis_type = {}
        for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()], '([^|]+)') do
            table.insert(invis_type, word)
        end
        if invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]] == 'Potion' then
            mq.cmdf('/dex %s /useitem "Cloudy Potion"',
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
        elseif invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]] == 'Hide/Sneak' then
            mq.cmdf("/dex %s /doability hide", mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
            mq.delay(250)
            mq.cmdf("/dex %s /doability sneak", mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
        else
            mq.cmdf('/dex %s /casting "%s"', mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName(),
                invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]])
        end
    end
    mq.delay("4s")
end

function manage.locTravelGroup(group_set, x, y, z)
    local loopCount = 0
    if group_set == 1 then
        mq.cmdf("/nav locxyz %s %s %s", x, y, z)
    elseif group_set == 2 then
        mq.cmdf("/dgga /nav locxyz %s %s %s", x, y, z)
    else
        mq.cmdf("/nav locxyz %s %s %s", x, y, z)
        mq.cmdf("/dex %s /nav locxyz %s %s %s", State.group_combo[State.group_choice], x, y, z)
    end
    mq.delay(200)
    while mq.TLO.Navigation.Active() do
        mq.delay(200)
        if loopCount == 10 then
            mq.cmd('/doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/click left door')
                end
            end
            loopCount = 0
        end
        if dist.GetDistance3D(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z(), State.X, State.Y, State.Z) < 20 then
            loopCount = loopCount + 1
        else
            State.X = mq.TLO.Me.X()
            State.Y = mq.TLO.Me.Y()
            State.Z = mq.TLO.Me.Z()
            loopCount = 0
        end
    end
end

function manage.navGroup(group_set, npc, ID)
    local loopCount = 0
    if ID == 0 then
        ID = mq.TLO.Spawn("npc " .. npc).ID()
    end
    if group_set == 1 then
        mq.cmdf("/nav id %s", ID)
    elseif group_set == 2 then
        mq.cmdf("/dgga /nav id %s", ID)
    else
        mq.cmdf("/nav id %s", ID)
        mq.cmdf('/dex %s /nav id %s', State.group_combo[State.group_choice], ID)
    end
    mq.delay(200)
    while mq.TLO.Navigation.Active() do
        mq.delay(200)
        mq.doevents()
        if loopCount == 10 then
            mq.cmd('/squelch /doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/click left door')
                end
            end
            loopCount = 0
        end
        if dist.GetDistance3D(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z(), State.X, State.Y, State.Z) < 20 then
            loopCount = loopCount + 1
        else
            State.X = mq.TLO.Me.X()
            State.Y = mq.TLO.Me.Y()
            State.Z = mq.TLO.Me.Z()
            loopCount = 0
        end
    end
end

function manage.navGroupLoc(group_set, npc, x, y, z)
    local loopCount = 0
    State.X = mq.TLO.Me.X()
    State.Y = mq.TLO.Me.Y()
    State.Z = mq.TLO.Me.Z()
    local searchstring = "loc " .. x .. " " .. y .. " " .. z .. " radius 50 npc " .. npc
    if group_set == 1 then
        mq.cmdf("/nav id %s", mq.TLO.Spawn(searchstring).ID())
    elseif group_set == 2 then
        mq.cmdf("/dgga /nav id %s", mq.TLO.Spawn(searchstring).ID())
    else
        mq.cmdf("/nav id %s", mq.TLO.Spawn(searchstring).ID())
        mq.cmdf('/dex %s /nav id %s', State.group_combo[State.group_choice], mq.TLO.Spawn(searchstring).ID())
    end
    mq.delay(200)
    while mq.TLO.Navigation.Active() do
        mq.delay(200)
        if loopCount == 10 then
            mq.cmd('/squelch /doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/click left door')
                end
            end
            loopCount = 0
        end
        if dist.GetDistance3D(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z(), State.X, State.Y, State.Z) < 20 then
            loopCount = loopCount + 1
        else
            State.X = mq.TLO.Me.X()
            State.Y = mq.TLO.Me.Y()
            State.Z = mq.TLO.Me.Z()
            loopCount = 0
        end
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
                break
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

function manage.Relocate(group_set, relocate)
    if group_set == 1 then
        mq.cmdf('/relocate %s', relocate)
    elseif group_set == 2 then
        mq.cmdf('/dgga /relocate %s', relocate)
    else
        mq.cmdf('/relocate %s', relocate)
        mq.cmdf('/dex %s /relocate %s', State.group_combo[State.group_choice], relocate)
    end
end

function manage.removeInvis(group_set)
    State.status = "Removing invis"
    if group_set == 1 then
        mq.cmd("/makemevis")
    elseif group_set == 2 then
        mq.cmd("/dgga /makemevis")
    else
        mq.cmdf("/makemevis")
        mq.cmdf("/dex %s /makemevis", State.group_combo[State.group_choice])
    end
end

function manage.removeLev(group_set)
    State.status = "Removing levitate"
    if group_set == 1 then
        mq.cmd("/removelev")
    elseif group_set == 2 then
        mq.cmd("/dgga /removelev")
    else
        mq.cmdf("/removelev")
        mq.cmdf("/dex %s /removelev", State.group_combo[State.group_choice])
    end
end

function manage.sendYes(group_set)
    State.status = "Removing levitate"
    if group_set == 1 then
        mq.cmd("/yes")
    elseif group_set == 2 then
        mq.cmd("/dgga /yes")
    else
        mq.cmdf("/yes")
        mq.cmdf("/dex %s /yes", State.group_combo[State.group_choice])
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

function manage.startGroup(group_set, class_settings)
    if mq.TLO.Me.Grouped() == true and mq.TLO.Group.Leader() == mq.TLO.Me.DisplayName() then
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

function manage.stopfollowGroup(group_set)
    if group_set == 1 then
        mq.cmd('/afollow off')
    elseif group_set == 2 then
        mq.cmd('/dgga /afollow off')
    else
        mq.cmd('/afollow off')
        mq.cmdf('/dex %s /afollow off', State.group_combo[State.group_choice])
    end
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

function manage.zoneGroup(group_set, zone)
    if group_set == 1 then
        mq.cmdf("/travelto %s", zone)
        local loopCount = 0
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
            if not mq.TLO.Navigation.Active() then
                if loopCount == 60 then
                    mq.cmdf("/travelto %s", zone)
                    loopCount = 0
                end
                loopCount = loopCount + 1
            end
        end
        mq.delay("1s")
    elseif group_set == 2 then
        mq.cmdf("/dgga /travelto %s", zone)
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
        end
        while mq.TLO.Group.AnyoneMissing() do
            mq.delay(500)
            if not mq.TLO.Navigation.Active() then
                mq.cmdf("/dgga /travelto %s", zone)
            end
        end
        mq.delay("5s")
    else
        mq.cmdf("/travelto %s", zone)
        mq.cmdf('/dex %s /travelto %s', State.group_combo[State.group_choice], zone)
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
        end
        while mq.TLO.Group.Member(State.group_combo[State.group_choice]).OtherZone() do
            if not mq.TLO.Navigation.Active() then
                mq.cmdf("/travelto %s", zone)
                mq.cmdf('/dex %s /travelto %s', State.group_combo[State.group_choice], zone)
            end
            mq.delay(500)
        end
        mq.delay("5s")
    end
end

return manage
