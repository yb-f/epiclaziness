local mq = require('mq')
local dist = require 'utils/distance'

local manage = {}
local elheader = "\ay[\agEpic Laziness\ay]"
local translocators = { "Magus", "Translocator", "Priest of Discord", "Nexus Scion", "Deaen Greyforge",
    "Ambassador Cogswald", "Madronoa", "Belinda", "Herald of Druzzil Ro" }

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

function manage.clearXtarget(group_set, class_settings, npc)
    npc = npc or "thiswontmatchanything"
    local max_xtargs = mq.TLO.Me.XTargetSlots()
    if mq.TLO.Me.XTarget() > 0 then
        local looping = true
        local loopCount = 0
        local i = 0
        local idList = {}
        while looping do
            mq.delay(200)
            i = i + 1
            loopCount = loopCount + 1
            if mq.TLO.Me.XTarget(i)() ~= '' and mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' then
                if mq.TLO.Me.XTarget(i).CleanName() ~= nil and npc ~= nil then
                    if string.find(string.lower(mq.TLO.Me.XTarget(i).CleanName()), string.lower(npc)) then
                        local ID = mq.TLO.Me.XTarget(i).ID()
                        local notFound = true
                        for _, ids in pairs(idList) do
                            if ID == ids then
                                notFound = false
                            end
                        end
                        if notFound then
                            table.insert(idList, ID)
                        end
                        if #idList == mq.TLO.Me.XTarget() then
                            break
                        end
                    else
                        if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                            if mq.TLO.Me.XTarget(i).Distance() ~= nil then
                                if mq.TLO.Me.XTarget(i).Distance() < 300 and mq.TLO.Me.XTarget(i).LineOfSight() == true then
                                    mq.TLO.Me.XTarget(i).DoTarget()
                                    ID = mq.TLO.Me.XTarget(i).ID()
                                    State.status = "Clearing XTarget " .. i .. ": " .. mq.TLO.Me.XTarget(i)()
                                    manage.unpauseGroup(group_set, class_settings)
                                    mq.cmd("/squelch /stick")
                                    mq.delay(100)
                                    mq.cmd("/squelch /attack on")
                                    while mq.TLO.Spawn(ID).Type() == 'NPC' do
                                        local breakout = true
                                        for j = 1, max_xtargs do
                                            if mq.TLO.Me.XTarget(j).ID() == ID then
                                                breakout = false
                                            end
                                        end
                                        if breakout == true then break end
                                        if mq.TLO.Target.ID() ~= ID then
                                            mq.TLO.Spawn(ID).DoTarget()
                                        end
                                        if mq.TLO.Me.Combat() == false then
                                            mq.cmd("/squelch /attack on")
                                        end
                                        mq.delay(200)
                                    end
                                    i = 0
                                    loopCount = 0
                                elseif i > mq.TLO.Me.XTarget() then
                                    i = 0
                                end
                            else
                                i = 0
                            end
                        end
                    end
                end
            end
            if loopCount == 20 then
                i = 0
                loopCount = 0
            end
            if mq.TLO.Me.XTarget() == 0 then
                looping = false
            end
            local continueLoop = false
            for j = 1, max_xtargs do
                if mq.TLO.Me.XTarget(j).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(j)() ~= '' then
                    continueLoop = true
                else
                end
            end
            if continueLoop == false then
                looping = false
            end
        end
        manage.pauseGroup(group_set, class_settings)
        if mq.TLO.Stick.Active() == true then
            mq.cmd('/squelch /stick off')
        end
    end
end

function manage.doAutomation(character, class, script, action)
    if action == 'start' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s mode 0 nosave', class)
                mq.cmdf('/squelch /%s usestick on nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /lua run rgmercs")
            elseif script == 3 then
                mq.cmd("/squelch /mac rgmercs")
            elseif script == 4 then
                mq.cmd("/squelch /mac kissassist")
            elseif script == 5 then
                mq.cmd("/squelch /mac muleassist")
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
                mq.cmd("/squelch /rgl campon")
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
                mq.cmdf("/dex %s /squelch /rgl campon", character)
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

function manage.faceHeading(group_set, heading)
    if group_set == 1 then
        mq.cmdf("/squelch /face heading %s", heading)
    elseif group_set == 2 then
        mq.cmdf("/dgga /squelch /face heading %s", heading)
    else
        mq.cmdf("/squelch /face heading %s", heading)
        mq.cmdf("/dex %s /squelch /face heading %s", State.group_combo[State.group_choice], heading)
    end
end

function manage.faceLoc(group_set, x, y, z)
    if group_set == 1 then
        mq.cmdf("/squelch /face loc %s,%s,%s", y, x, z)
    elseif group_set == 2 then
        mq.cmdf("/dgga /squelch /face loc %s,%s,%s", y, x, z)
    else
        mq.cmdf("/squelch /face loc %s,%s,%s", y, x, z)
        mq.cmdf("/dex %s /squelch /face loc %s,%s,%s", State.group_combo[State.group_choice], y, x, z)
    end
end

function manage.followGroup(group_set, npc)
    if mq.TLO.Spawn("npc " .. npc).Distance() ~= nil then
        if mq.TLO.Spawn("npc " .. npc).Distance() > 100 then
            State.step = State.step - 2
            return
        end
    end
    if group_set == 1 then
        mq.TLO.Spawn("npc " .. npc).DoTarget()
        mq.delay(300)
        mq.cmd('/squelch /afollow')
    elseif group_set == 2 then
        mq.cmdf('/dgga /squelch /target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/dgga /squelch /afollow')
    else
        mq.TLO.Spawn("npc " .. npc).DoTarget()
        mq.cmdf('/dex %s /squelch /nav id %s', State.group_combo[State.group_choice], mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/squelch /afollow')
        mq.cmdf('/dex %s /squelch /afollow', State.group_combo[State.group_choice])
    end
end

function manage.followGroupLoc(group_set, npc, x, y)
    if mq.TLO.Spawn("npc " .. npc).Distance() ~= nil then
        if mq.TLO.Spawn("npc " .. npc).Distance() > 100 then
            State.step = State.step - 2
            return
        end
    end
    if group_set == 1 then
        mq.TLO.Spawn("npc " .. npc).DoTarget()
        mq.delay(300)
        mq.cmd('/squelch /afollow')
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 50 do
            if State.skip == true then
                mq.cmd('/squelch /afollow off')
                State.skip = false
                return
            end
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd('/squelch /afollow off')
    elseif group_set == 2 then
        mq.cmdf('/dgga /squelch /target id %s', mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/dgga /squelch /afollow')
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 50 do
            if State.skip == true then
                mq.cmd('/dgga /squelch /afollow off')
                State.skip = false
                return
            end
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd('/dgga /squelch /afollow off')
    else
        mq.TLO.Spawn("npc " .. npc).DoTarget()
        mq.cmdf('/dex %s /squelch /nav id %s', State.group_combo[State.group_choice], mq.TLO.Spawn("npc " .. npc).ID())
        mq.delay(300)
        mq.cmd('/squelch /afollow')
        mq.cmdf('/dex %s /squelch /afollow', State.group_combo[State.group_choice])
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 50 do
            if State.skip == true then
                mq.cmd('/squelch /afollow off')
                mq.cmdf('/dex %s /squelch /afollow off', State.group_combo[State.group_choice])
                State.skip = false
                return
            end
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        end
        mq.cmd('/squelch /afollow off')
        mq.cmdf('/dex %s /squelch /afollow off', State.group_combo[State.group_choice])
    end
end

--WORK ON THIS ONE
function manage.forwardZone(group_set, zone)
    if group_set == 1 then
        mq.cmd("/squelch /keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
        end
        mq.delay("5s")
    elseif group_set == 2 then
        mq.cmd("/dgge /squelch /keypress forward hold")
        mq.cmd("/squelch /keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= zone do
            mq.delay(500)
        end
        while mq.TLO.Group.AnyoneMissing() do
            mq.delay(500)
        end
        mq.delay("5s")
    else
        mq.cmdf("/dex %s /keypress forward hold", State.group_combo[State.group_choice])
        mq.cmd("/squelch /keypress forward hold")
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
        mq.cmd("/squelch /relocate gate")
        mq.delay(500)
    elseif group_set == 2 then
        mq.cmd("/dgga /squelch/relocate gate")
        mq.delay(500)
    else
        mq.cmd("/squelch /relocate gate")
        mq.cmdf('/dex %s /squelch /relocate gate', State.group_combo[State.group_choice])
    end
end

function manage.groupTalk(group_set, npc, phrase)
    if mq.TLO.Spawn(npc).Distance() ~= nil then
        if mq.TLO.Spawn(npc).Distance() > 100 then
            State.step = State.step - 2
            return
        end
    end
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

function manage.invis(group_set, class_settings)
    State.status = "Using invis"
    local invis_type = {}
    if mq.TLO.Me.Combat() == true then
        mq.cmd('/squelch /attack off')
    end
    for word in string.gmatch(class_settings.class_invis[mq.TLO.Me.Class()], '([^|]+)') do
        table.insert(invis_type, word)
    end
    if invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Potion' then
        mq.cmd('/squelch /useitem "Cloudy Potion"')
    elseif invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Hide/Sneak' then
        while mq.TLO.Me.AbilityReady('Hide')() == false do
            mq.delay(100)
            if mq.TLO.Me.Invis() == true then
                break
            end
        end
        mq.cmd("/squelch /doability hide")
        while mq.TLO.Me.Invis() == false do
            mq.delay(100)
            if mq.TLO.Me.AbilityReady('Hide')() == true then
                mq.cmd("/squelch /doability hide")
            end
        end
        if mq.TLO.Me.Sneaking() == false then
            while mq.TLO.Me.AbilityReady('Sneak')() == false do
                mq.delay(100)
            end
            mq.cmd("/squelch /doability sneak")
            while mq.TLO.Me.Sneaking() == false do
                mq.delay(100)
                if mq.TLO.Me.AbilityReady('Sneak')() == true then
                    mq.cmd("/squelch /doability sneak")
                end
            end
        end
    else
        local ID = class_settings['skill_to_num'][invis_type[class_settings.invis[mq.TLO.Me.Class()]]]
        mq.cmdf('/squelch /alt act %s', ID)
        mq.delay(500)
        while mq.TLO.Me.Casting() == true do
            mq.delay(200)
        end
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
                    mq.cmdf('/dex %s /squelch /useitem "Cloudy Potion"', mq.TLO.Group.Member(i).DisplayName())
                elseif invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == 'Hide/Sneak' then
                    mq.cmdf("/dex %s /squelch /doability hide", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(250)
                    mq.cmdf("/dex %s /squelch /doability sneak", mq.TLO.Group.Member(i).DisplayName())
                else
                    local ID = class_settings['skill_to_num']
                        [invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]]]
                    mq.cmdf('/dex %s /squelch /alt act "%s"', mq.TLO.Group.Member(i).DisplayName(),
                        ID)
                end
            end
        end
        mq.delay("4s")
    else
        local invis_type = {}
        for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()], '([^|]+)') do
            table.insert(invis_type, word)
        end
        if invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]] == 'Potion' then
            mq.cmdf('/dex %s /squelch /useitem "Cloudy Potion"',
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
        elseif invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]] == 'Hide/Sneak' then
            mq.cmdf("/dex %s /squelch /doability hide",
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
            mq.delay(250)
            mq.cmdf("/dex %s /squelch /doability sneak",
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
        else
            local ID = class_settings['skill_to_num']
                [invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]]]
            mq.cmdf('/dex %s /squelch /alt act "%s"',
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName(), ID)
        end
        mq.delay("4s")
    end
    mq.delay(100)
end

function manage.invisTranslocatorCheck()
    for _, name in pairs(translocators) do
        if mq.TLO.Spawn('npc ' .. name).Distance() ~= nil then
            if mq.TLO.Spawn('npc ' .. name).Distance() < 50 then
                return true
            end
        end
    end
    return false
end

function manage.locTravelGroup(group_set, x, y, z, class_settings, invis)
    invis = invis or 0
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
    local unpause_automation = false
    local temp = State.status
    while mq.TLO.Navigation.Active() do
        if State.skip == true then
            manage.navPause(group_set)
            State.skip = false
            return
        end
        mq.delay(200)
        if mq.TLO.Me.XTarget() > 0 then
            for i = 1, mq.TLO.Me.XTargetSlots() do
                if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                    local temp = State.status
                    manage.navPause(group_set)
                    manage.clearXtarget(group_set, class_settings)
                    manage.navUnpause(group_set)
                    State.status = temp
                end
            end
        end
        if State.pause == true then
            manage.navPause(group_set)
            unpause_automation = true
            State.status = "Paused"
        end
        while State.pause == true do
            mq.delay(200)
        end
        if unpause_automation == true then
            State.status = temp
            manage.navUnpause(group_set)
            unpause_automation = false
        end
        if mq.TLO.Me.Invis() == false then
            if class_settings.general.invisForTravel == true then
                if invis == 1 then
                    local temp = State.status
                    local transCheck = manage.invisTranslocatorCheck()
                    if transCheck == false then
                        manage.navPause(group_set)
                        manage.invis(State.group_choice, class_settings)
                        manage.navUnpause(group_set)
                        State.status = temp
                    end
                end
            end
        end
        if loopCount == 10 then
            mq.cmd('/squelch /doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/squelch /click left door')
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

function manage.navGroup(group_set, npc, ID, class_settings, invis)
    invis = invis or 0
    local loopCount = 0
    if ID == 0 then
        ID = mq.TLO.Spawn("npc " .. npc).ID()
    end
    if group_set == 1 then
        mq.cmdf("/squelch /nav id %s", ID)
    elseif group_set == 2 then
        mq.cmdf("/dgga /squelch /nav id %s", ID)
    else
        mq.cmdf("/squelch /nav id %s", ID)
        mq.cmdf('/dex %s /squelch /nav id %s', State.group_combo[State.group_choice], ID)
    end
    mq.delay(200)
    local temp = State.status
    local unpause_automation = false
    while mq.TLO.Navigation.Active() do
        if mq.TLO.Navigation.Paused() == true then
            manage.navUnpause(group_set)
        end
        if State.skip == true then
            manage.navPause(group_set)
            State.skip = false
            return
        end
        mq.delay(200)
        mq.doevents()
        if mq.TLO.Me.XTarget() > 0 then
            for i = 1, mq.TLO.Me.XTargetSlots() do
                if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                    local temp = State.status
                    manage.navPause(group_set)
                    manage.clearXtarget(group_set, class_settings)
                    manage.navUnpause(group_set)
                    State.status = temp
                end
            end
        end
        if State.pause == true then
            manage.navPause(group_set)
            unpause_automation = true
            State.status = "Paused"
        end
        while State.pause == true do
            mq.delay(200)
        end
        if unpause_automation == true then
            State.status = temp
            manage.navUnpause(group_set)
            unpause_automation = false
        end
        if mq.TLO.Me.Invis() == false then
            if class_settings.general.invisForTravel == true then
                if invis == 1 then
                    local temp = State.status
                    local transCheck = manage.invisTranslocatorCheck()
                    if transCheck == false then
                        manage.navPause(group_set)
                        manage.invis(State.group_choice, class_settings)
                        manage.navUnpause(group_set)
                        State.status = temp
                    end
                end
            end
        end
        if loopCount == 10 then
            mq.cmd('/squelch /doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/squelch /click left door')
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

function manage.navGroupGeneral(group_set, npc, ID, class_settings, invis)
    invis = invis or 0
    local loopCount = 0
    if ID == 0 then
        ID = mq.TLO.Spawn(npc).ID()
    end
    if group_set == 1 then
        mq.cmdf("/squelch /nav id %s", ID)
    elseif group_set == 2 then
        mq.cmdf("/dgga /squelch /nav id %s", ID)
    else
        mq.cmdf("/squelch /nav id %s", ID)
        mq.cmdf('/dex %s /squelch /nav id %s', State.group_combo[State.group_choice], ID)
    end
    mq.delay(200)
    local temp = State.status
    local unpause_automation = false
    while mq.TLO.Navigation.Active() do
        if mq.TLO.Navigation.Paused() == true then
            manage.navUnpause(group_set)
        end
        if State.skip == true then
            manage.navPause(group_set)
            State.skip = false
            return
        end
        mq.delay(200)
        if mq.TLO.Me.XTarget() > 0 then
            for i = 1, mq.TLO.Me.XTargetSlots() do
                if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                    local temp = State.status
                    manage.navPause(group_set)
                    manage.clearXtarget(group_set, class_settings)
                    manage.navUnpause(group_set)
                    State.status = temp
                end
            end
        end
        if State.pause == true then
            manage.navPause(group_set)
            unpause_automation = true
            State.status = "Paused"
        end
        while State.pause == true do
            mq.delay(200)
        end
        if unpause_automation == true then
            State.status = temp
            manage.navUnpause(group_set)
            unpause_automation = false
        end
        if mq.TLO.Me.Invis() == false then
            if class_settings.general.invisForTravel == true then
                if invis == 1 then
                    local temp = State.status
                    local transCheck = manage.invisTranslocatorCheck()
                    if transCheck == false then
                        manage.navPause(group_set)
                        manage.invis(State.group_choice, class_settings)
                        manage.navUnpause(group_set)
                        State.status = temp
                    end
                end
            end
        end
        if loopCount == 10 then
            mq.cmd('/squelch /doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/squelch /click left door')
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

function manage.navGroupLoc(group_set, npc, x, y, z, class_settings, invis)
    invis = invis or 0
    local loopCount = 0
    State.X = mq.TLO.Me.X()
    State.Y = mq.TLO.Me.Y()
    State.Z = mq.TLO.Me.Z()
    local searchstring = "loc " .. x .. " " .. y .. " " .. z .. " radius 50 npc " .. npc
    local ID = mq.TLO.Spawn(searchstring).ID()
    if ID == 0 then
        if group_set == 1 then
            mq.cmdf("/squelch /nav locxyz %s %s %s", x, y, z)
        elseif group_set == 2 then
            mq.cmdf("/dgga /squelch /nav locxyz %s %s %s", x, y, z)
        else
            mq.cmdf("/squelch /nav locxyz %s %s %s", x, y, z)
            mq.cmdf('/dex %s /squelch /nav locxyz %s %s %s', State.group_combo[State.group_choice], x, y, z)
        end
    else
        if group_set == 1 then
            mq.cmdf("/squelch /nav id %s", ID)
        elseif group_set == 2 then
            mq.cmdf("/dgga /squelch /nav id %s", ID)
        else
            mq.cmdf("/squelch /nav id %s", ID)
            mq.cmdf('/dex %s /squelch /nav id %s', State.group_combo[State.group_choice], ID)
        end
    end

    mq.delay(200)
    local temp = State.status
    local unpause_automation = false
    while mq.TLO.Navigation.Active() do
        if mq.TLO.Navigation.Paused() == true then
            manage.navUnpause(group_set)
        end
        if State.skip == true then
            manage.navPause(group_set)
            State.skip = false
            return
        end
        mq.delay(200)
        if mq.TLO.Me.XTarget() > 0 then
            for i = 1, mq.TLO.Me.XTargetSlots() do
                if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                    local temp = State.status
                    manage.navPause(group_set)
                    manage.clearXtarget(group_set, class_settings)
                    manage.navUnpause(group_set)
                    State.status = temp
                end
            end
        end
        if State.pause == true then
            manage.navPause(group_set)
            unpause_automation = true
            State.status = "Paused"
        end
        while State.pause == true do
            mq.delay(200)
        end
        if unpause_automation == true then
            State.status = temp
            manage.navUnpause(group_set)
            unpause_automation = false
        end
        if mq.TLO.Me.Invis() == false then
            if class_settings.general.invisForTravel == true then
                if invis == 1 then
                    local temp = State.status
                    local transCheck = manage.invisTranslocatorCheck()
                    if transCheck == false then
                        manage.navPause(group_set)
                        manage.invis(State.group_choice, class_settings)
                        manage.navUnpause(group_set)
                        State.status = temp
                    end
                end
            end
        end
        if loopCount == 10 then
            mq.cmd('/squelch /doortarget')
            mq.delay(200)
            if mq.TLO.Switch.Distance() ~= nil then
                if mq.TLO.Switch.Distance() < 20 then
                    mq.cmd('/squelch /click left door')
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
        mq.cmd("/squelch /keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
            if State.skip == true then
                State.skip = false
                return
            end
        end
        mq.cmd("/squelch /keypress forward")
    elseif group_set == 2 then
        mq.cmd("/dgge /squelch /keypress forward hold")
        mq.cmd("/squelch /keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
            if State.skip == true then
                State.skip = false
                return
            end
        end
        mq.cmd("/dgge /squelch /keypress forward")
        mq.cmd("/squelch /keypress forward")
    else
        mq.cmdf("/dex %s /squelch /keypress forward hold", State.group_combo[State.group_choice])
        mq.cmd("/squelch /keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
            if State.skip == true then
                State.skip = false
                return
            end
        end
        mq.cmdf("/dex %s /squelch /keypress forward", State.group_combo[State.group_choice])
        mq.cmd("/squelch /keypress forward")
    end
end

function manage.navPause(group_set)
    if group_set == 1 then
        mq.cmd('/squelch /nav pause')
    elseif group_set == 2 then
        mq.cmd('/dgga /squelch /nav pause')
    else
        mq.cmd('/squelch /nav pause')
        mq.cmdf('/dex %s /nav pause', State.group_combo[State.group_choice])
    end
    mq.delay(500)
end

function manage.navUnpause(group_set, travelData)
    if group_set == 1 then
        mq.cmd('/squelch /nav pause')
    elseif group_set == 2 then
        mq.cmd('/dgga /squelch /nav pause')
    else
        mq.cmd('/squelch /nav pause')
        mq.cmdf('/dex %s /squelch /nav pause', State.group_combo[State.group_choice])
    end
    mq.delay(500)
end

function manage.openDoorAll(group_set)
    if group_set == 1 then
        mq.delay(200)
        mq.cmd("/squelch /doortarget")
        mq.delay(200)
        mq.cmd("/squelch /click left door")
        mq.delay(1000)
    elseif group_set == 2 then
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
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
        else
            printf("%s \aoI am not a class that is able to pick locks.", elheader)
            State.status = "I require a lockpicker to proceed. (" .. State.step .. ")"
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    elseif group_set == 2 then
        local pickerFound = false
        if mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
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
            printf("%s \aoI require a class that is able to pick locks.", elheader)
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    else
        local name = State.group_combo[State.group_choice]
        if mq.TLO.Group.Member(name).Class.ShortName() == 'BRD' or mq.TLO.Group.Member(name).Class.ShortName() == 'ROG' then
            mq.cmdf("/dex %s /squelch /itemnotify lockpicks leftmouseup", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /doortarget", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /click left door", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /autoinv", name)
        elseif mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
        else
            State.status = "I require a lockpicker to proceed. (" .. State.step .. ")"
            printf("%s \aoI require a class that is able to pick locks.", elheader)
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    end
end

function manage.relocateGroup(group_set, relocate, class_settings)
    local unpause_automation = false
    local temp = ''
    if relocate == 'lobby' then
        if mq.TLO.Me.AltAbilityReady('Throne of Heroes')() == false then
            while mq.TLO.Me.AltAbilityReady('Throne of Heroes')() == false do
                State.status = 'Waiting for Throne of Heroes AA to be ready'
                if mq.TLO.Navigation.Paused() == true then
                    manage.navUnpause(group_set)
                end
                if State.skip == true then
                    manage.navPause(group_set)
                    State.skip = false
                    return
                end
                mq.delay(200)
                if mq.TLO.Me.XTarget() > 0 then
                    for i = 1, mq.TLO.Me.XTargetSlots() do
                        if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                            local temp = State.status
                            manage.navPause(group_set)
                            manage.clearXtarget(group_set, class_settings)
                            manage.navUnpause(group_set)
                            State.status = temp
                        end
                    end
                end
                if State.pause == true then
                    manage.navPause(group_set)
                    unpause_automation = true
                    State.status = "Paused"
                end
                while State.pause == true do
                    mq.delay(200)
                end
                if unpause_automation == true then
                    State.status = temp
                    manage.navUnpause(group_set)
                    unpause_automation = false
                end
            end
        end
    elseif relocate == 'origin' then
        if mq.TLO.Me.AltAbilityReady('Origin')() == false then
            State.status = 'Waiting for Origin AA to be ready'
            while mq.TLO.Me.AltAbilityReady('Origin')() == false do
                if mq.TLO.Navigation.Paused() == true then
                    manage.navUnpause(group_set)
                end
                if State.skip == true then
                    manage.navPause(group_set)
                    State.skip = false
                    return
                end
                mq.delay(200)
                if mq.TLO.Me.XTarget() > 0 then
                    for i = 1, mq.TLO.Me.XTargetSlots() do
                        if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                            local temp = State.status
                            manage.navPause(group_set)
                            manage.clearXtarget(group_set, class_settings)
                            manage.navUnpause(group_set)
                            State.status = temp
                        end
                    end
                end
                if State.pause == true then
                    manage.navPause(group_set)
                    unpause_automation = true
                    State.status = "Paused"
                end
                while State.pause == true do
                    mq.delay(200)
                end
                if unpause_automation == true then
                    State.status = temp
                    manage.navUnpause(group_set)
                    unpause_automation = false
                end
            end
        end
    end
    if group_set == 1 then
        mq.cmdf('/squelch /relocate %s', relocate)
    elseif group_set == 2 then
        mq.cmdf('/dgga /squelch /relocate %s', relocate)
    else
        mq.cmdf('/squelch /relocate %s', relocate)
        mq.cmdf('/dex %s /squelch /relocate %s', State.group_combo[State.group_choice], relocate)
    end
end

function manage.removeInvis(group_set)
    State.status = "Removing invis"
    if group_set == 1 then
        mq.cmd("/squelch /makemevis")
    elseif group_set == 2 then
        mq.cmd("/dgga /squelch /makemevis")
    else
        mq.cmdf("/squelch /makemevis")
        mq.cmdf("/dex %s /squelch /makemevis", State.group_combo[State.group_choice])
    end
end

function manage.removeLev(group_set)
    --State.status = "Removing levitate"
    if group_set == 1 then
        mq.cmd("/squelch /removelev")
    elseif group_set == 2 then
        mq.cmd("/dgga /squelch /removelev")
    else
        mq.cmdf("/squelch /removelev")
        mq.cmdf("/dex %s /squelch /removelev", State.group_combo[State.group_choice])
    end
end

function manage.sendYes(group_set)
    State.status = "Removing levitate"
    if group_set == 1 then
        mq.cmd("/squelch /yes")
    elseif group_set == 2 then
        mq.cmd("/dgga /squelch /yes")
    else
        mq.cmdf("/squelch /yes")
        mq.cmdf("/dex %s /squelch /yes", State.group_combo[State.group_choice])
    end
end

function manage.setRadius(character, class, script, radius)
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

function manage.startGroup(group_set, class_settings)
    if mq.TLO.Me.Grouped() == true and mq.TLO.Group.Leader() == mq.TLO.Me.DisplayName() then
        mq.cmdf("/squelch /grouprole set %s 1", mq.TLO.Me.DisplayName())
        mq.cmdf("/squelch /grouprole set %s 2", mq.TLO.Me.DisplayName())
        --mq.cmdf("/grouprole set %s 3", mq.TLO.Me.DisplayName())
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
        mq.cmd('/squelch /afollow off')
    elseif group_set == 2 then
        mq.cmd('/dgga /squelch /afollow off')
    else
        mq.cmd('/squelch /afollow off')
        mq.cmdf('/dex %s /squelch /afollow off', State.group_combo[State.group_choice])
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
        class_settings.class[mq.TLO.Me.Class.Name()], 'unpause')
    if group_set == 1 then
        return
    elseif group_set == 2 then
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

function manage.zoneGroup(group_set, zone, class_settings, invis)
    invis = invis or 0
    if group_set == 1 then
        mq.cmdf("/squelch /travelto %s", zone)
    elseif group_set == 2 then
        mq.cmdf("/dgga /squelch /travelto %s", zone)
    else
        mq.cmdf("/squelch /travelto %s", zone)
        mq.cmdf('/dex %s /squelch /travelto %s', State.group_combo[State.group_choice], zone)
    end
    local temp = State.status
    local unpause_automation = false
    local loopCount = 0
    while mq.TLO.Zone.ShortName() ~= zone and mq.TLO.Zone.Name() ~= zone do
        if mq.TLO.Navigation.Paused() == true then
            manage.navUnpause(group_set)
        end
        if State.skip == true then
            manage.navPause(group_set)
            State.skip = false
            return
        end
        mq.delay(500)
        if mq.TLO.Me.XTarget() > 0 then
            for i = 1, mq.TLO.Me.XTargetSlots() do
                if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                    local temp = State.status
                    manage.navPause(group_set)
                    manage.clearXtarget(group_set, class_settings)
                    manage.navUnpause(group_set)
                    State.status = temp
                end
            end
        end
        if State.pause == true then
            manage.navPause(group_set)
            unpause_automation = true
            State.status = "Paused"
        end
        while State.pause == true do
            mq.delay(200)
        end
        if unpause_automation == true then
            State.status = temp
            manage.navUnpause(group_set)
            unpause_automation = false
        end
        if mq.TLO.Me.Invis() == false then
            if class_settings.general.invisForTravel == true then
                if invis == 1 then
                    local temp = State.status
                    local transCheck = manage.invisTranslocatorCheck()
                    if transCheck == false then
                        manage.navPause(group_set)
                        manage.invis(State.group_choice, class_settings)
                        manage.navUnpause(group_set)
                        State.status = temp
                    end
                end
            end
        end
        if not mq.TLO.Navigation.Active() then
            print(loopCount)
            if loopCount == 30 then
                loopCount = 0
                if mq.TLO.Cursor() ~= nil then
                    if mq.TLO.Cursor() == "Spire Stone" then
                        mq.cmd('/squelch /autoinv')
                    end
                end
                if mq.TLO.FindItem('=Spire Stone')() == nil then
                    if group_set == 1 then
                        mq.cmdf("/squelch /travelto %s", zone)
                    elseif group_set == 2 then
                        mq.cmdf("/dgga /squelch /travelto %s", zone)
                    else
                        mq.cmdf("/squelch /travelto %s", zone)
                        mq.cmdf('/dex %s /squelch /travelto %s', State.group_combo[State.group_choice], zone)
                    end
                end
            end
            loopCount = loopCount + 1
        end
    end
    if group_set == 2 then
        while mq.TLO.Group.AnyoneMissing() do
            mq.delay(500)
            if State.skip == true then
                State.skip = false
                return
            end
        end
    end
    if group_set > 2 then
        while mq.TLO.Group.Member(State.group_combo[State.group_choice]).OtherZone() do
            mq.delay(500)
            if State.skip == true then
                State.skip = false
                return
            end
        end
    end
    mq.delay("5s")
end

return manage
