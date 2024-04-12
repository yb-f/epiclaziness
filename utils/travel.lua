local mq = require('mq')
local manage = require 'utils/manageautomation'
local translocators = { "Magus", "Translocator", "Priest of Discord", "Nexus Scion", "Deaen Greyforge",
    "Ambassador Cogswald", "Madronoa", "Belinda", "Herald of Druzzil Ro" }

local dist = require 'utils/distance'

local travel = {}

function travel.invisTranslocatorCheck()
    for _, name in pairs(translocators) do
        if mq.TLO.Spawn('npc ' .. name).Distance() ~= nil then
            if mq.TLO.Spawn('npc ' .. name).Distance() < 50 then
                return true
            end
        end
    end
    return false
end

function travel.face_heading(heading)
    State.status = "Facing heading " .. heading
    if State.group_choice == 1 then
        mq.cmdf("/squelch /face heading %s", heading)
    elseif State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /face heading %s", heading)
    else
        mq.cmdf("/squelch /face heading %s", heading)
        mq.cmdf("/dex %s /squelch /face heading %s", State.group_combo[State.group_choice], heading)
    end
    mq.delay(250)
end

function travel.face_loc(item)
    local x = item.whereX
    local y = item.wherey
    local z = item.wherez
    State.status = "Facing " .. y .. ", " .. x .. ", " .. z
    if State.group_choice == 1 then
        mq.cmdf("/squelch /face loc %s,%s,%s", y, x, z)
    elseif State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /face loc %s,%s,%s", y, x, z)
    else
        mq.cmdf("/squelch /face loc %s,%s,%s", y, x, z)
        mq.cmdf("/dex %s /squelch /face loc %s,%s,%s", State.group_combo[State.group_choice], y, x, z)
    end
    mq.delay(250)
end

function travel.forward_zone(item, class_settings, char_settings)
    if travel.invisCheck(char_settings, item.invis) then
        travel.invis(class_settings)
    end
    State.status = "Traveling forward to zone: " .. item.zone
    if State.group_choice == 1 then
        mq.cmd("/squelch /keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= item.zone do
            mq.delay(500)
        end
    elseif State.group_choice == 2 then
        mq.cmd("/dgge /squelch /keypress forward hold")
        mq.cmd("/squelch /keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= item.zone do
            mq.delay(500)
        end
        while mq.TLO.Group.AnyoneMissing() do
            mq.delay(500)
        end
    else
        mq.cmdf("/dex %s /keypress forward hold", State.group_combo[State.group_choice])
        mq.cmd("/squelch /keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= item.zone and mq.TLO.Zone.Name() ~= item.zone do
            mq.delay(500)
        end
        while mq.TLO.Group.Member(State.group_combo[State.group_choice]).OtherZone() do
            mq.delay(500)
        end
    end
    mq.delay("2s")
end

function travel.gate_group()
    if State.group_choice == 1 then
        mq.cmd("/squelch /relocate gate")
        mq.delay(500)
    elseif State.group_choice == 2 then
        mq.cmd("/dgga /squelch /relocate gate")
        mq.delay(500)
    else
        mq.cmd("/squelch /relocate gate")
        mq.cmdf('/dex %s /squelch /relocate gate', State.group_combo[State.group_choice])
    end
end

function travel.no_nav_travel(item, class_settings, char_settings)
    local x = item.whereX
    local y = item.whereY
    local z = item.whereZ
    if travel.invisCheck(char_settings, item.invis) then
        travel.invis(class_settings)
    end
    State.status = "Traveling forward to  " .. y .. ", " .. x .. ", " .. z
    if State.group_choice == 1 then
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
    elseif State.group_choice == 2 then
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

function travel.open_door()
    State.status = "Opening door"
    mq.delay(200)
    mq.cmd("/squelch /doortarget")
    mq.delay(200)
    if mq.TLO.Switch.Distance() ~= nil then
        if mq.TLO.Switch.Distance() < 20 then
            mq.cmd('/squelch /click left door')
        end
    end
    mq.delay(1000)
end

function travel.travelLoop(item, class_settings, char_settings, ID)
    ID = ID or 0
    local loopCount = 0
    local distance = 0
    while mq.TLO.Navigation.Active() do
        mq.delay(200)
        if mq.TLO.Navigation.Paused() == true then
            travel.navUnpause(item)
        end
        if State.skip == true then
            travel.navPause()
            State.skip = false
            return
        end
        if Mob.xtargetCheck(char_settings) then
            travel.navPause()
            Mob.clearXtarget(class_settings, char_settings)
            travel.navUnpause(item)
        end
        if State.pause == true then
            travel.navPause()
            Actions.pause(State.status)
            travel.navUnpause(item)
        end
        if travel.invisCheck(char_settings, item.invis) then
            travel.navPause()
            travel.invis(class_settings)
            travel.navUnpause(item)
        end
        if loopCount == 10 then
            local temp = State.status
            travel.open_door()
            loopCount = 0
            State.status = temp
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
    if ID ~= 0 then
        local spawn = mq.TLO.Spawn(ID)
        distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), spawn.X(), spawn.Y())
    elseif item.whereX ~= 0 then
        distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), item.whereX, item.whereY)
    end
    if distance > 30 then
        State.step = State.step
        State.rewound = true
        State.skip = true
    end
    State.traveling = false
end

function travel.general_travel(item, class_settings, char_settings, ID)
    ID = ID or Mob.findNearestName(item.npc)
    if travel.invisCheck(char_settings, item.invis) then
        travel.invis(class_settings)
    end
    State.status = "Waiting for " .. item.npc
    while ID == nil do
        mq.delay(500)
        if State.skip == true then
            travel.navPause()
            State.skip = false
            return
        end
        if State.pause == true then
            travel.navPause()
            Actions.pause(State.status)
            travel.navUnpause(item)
        end
        ID = Mob.findNearestName(item.npc)
    end
    State.status = "Navigating to " .. item.npc
    if ID == 0 then
        ID = Mob.findNearestName(item.npc)
    end
    if State.group_choice == 1 then
        mq.cmdf("/squelch /nav id %s", ID)
    elseif State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /nav id %s", ID)
    else
        mq.cmdf("/squelch /nav id %s", ID)
        mq.cmdf('/dex %s /squelch /nav id %s', State.group_combo[State.group_choice], ID)
    end
    mq.delay(200)
    travel.travelLoop(item, class_settings, char_settings, ID)
end

function travel.invis(class_settings)
    local temp = State.status
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
        while mq.TLO.Me.Invis() == false do
            mq.delay(100)
            if mq.TLO.Me.AbilityReady('Hide')() == true then
                mq.cmd("/squelch /doability hide")
            end
        end
        if mq.TLO.Me.Sneaking() == false then
            while mq.TLO.Me.Sneaking() == false do
                mq.delay(100)
                if mq.TLO.Me.AbilityReady('Sneak')() == true then
                    mq.cmd("/squelch /doability sneak")
                end
            end
        end
    else
        local ID = class_settings['skill_to_num'][invis_type[class_settings.invis[mq.TLO.Me.Class()]]]
        while mq.TLO.Me.AltAbilityReady(ID)() == false do
            mq.delay(50)
        end
        mq.cmdf('/squelch /alt act %s', ID)
        mq.delay(500)
        while mq.TLO.Me.Casting() do
            mq.delay(200)
        end
    end
    if State.group_choice == 1 then
    elseif State.group_choice == 2 then
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
    State.status = temp
end

function travel.invisCheck(char_settings, invis)
    if invis == 1 and char_settings.general.invisForTravel == true and mq.TLO.Me.Invis() == false then
        return true
    end
    return false
end

function travel.loc_travel(item, class_settings, char_settings)
    local x = item.whereX
    local y = item.whereY
    local z = item.whereZ
    State.status = "Traveling to  " .. y .. ", " .. x .. ", " .. z
    if mq.TLO.Navigation.PathExists('loc ' .. y .. ' ' .. x .. ' ' .. z) == false then
        State.status = "No path exists to loc Y: " .. y .. " X: " .. x .. " Z: " .. z
        State.task_run = false
        mq.cmd('/foreground')
        return
    end
    State.traveling = true
    if State.group_choice == 1 then
        mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
    elseif State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /nav loc %s %s %s", y, x, z)
    else
        mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
        mq.cmdf("/dex %s /squelch /nav loc %s %s %s", State.group_combo[State.group_choice], y, x, z)
    end
    mq.delay(100)
    travel.travelLoop(item, class_settings, char_settings)
end

function travel.navPause()
    if State.group_choice == 1 then
        mq.cmd('/squelch /nav pause')
    elseif State.group_choice == 2 then
        mq.cmd('/dgga /squelch /nav pause')
    else
        mq.cmd('/squelch /nav pause')
        mq.cmdf('/dex %s /nav pause', State.group_combo[State.group_choice])
    end
    mq.delay(500)
end

function travel.navUnpause(item)
    item = item
    if item.whereX then
        local x = item.whereX
        local y = item.whereY
        local z = item.whereZ
        if State.group_choice == 1 then
            mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
        elseif State.group_choice == 2 then
            mq.cmdf("/dgga /squelch /nav loc %s %s %s", y, x, z)
        else
            mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
            mq.cmdf("/dex %s /squelch /nav loc %s %s %s", State.group_combo[State.group_choice], y, x, z)
        end
    elseif item.npc then
        if State.group_choice == 1 then
            mq.cmdf("/squelch /nav spawn %s", item.npc)
        elseif State.group_choice == 2 then
            mq.cmdf("/dgga /squelch /nav spawn %s", item.npc)
        else
            mq.cmdf("/squelch /nav spawn %s", item.npc)
            mq.cmdf("/dex %s /squelch /nav spawn %s", State.group_combo[State.group_choice], item.npc)
        end
    elseif item.zone then
        if State.group_choice == 1 then
            mq.cmdf("/squelch /travelto %s", item.zone)
        elseif State.group_choice == 2 then
            mq.cmdf("/dgga /squelch /travelto %s", item.zone)
        else
            mq.cmdf("/squelch /travelto %s", item.zone)
            mq.cmdf('/dex %s /squelch /travelto %s', State.group_combo[State.group_choice], item.zone)
        end
    end
    mq.delay(500)
end

function travel.npc_follow(item, class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    if travel.invisCheck(char_settings, item.invis) then
        travel.invis(class_settings)
    end
    State.status = "Following " .. item.npc
    if mq.TLO.Spawn("npc " .. item.npc).Distance() ~= nil then
        if mq.TLO.Spawn("npc " .. item.npc).Distance() > 100 then
            State.rewound = true
            State.step = State.step
            return
        end
    end
    if State.group_choice == 1 then
        mq.TLO.Spawn("npc " .. item.npc).DoTarget()
        mq.delay(300)
        mq.cmd('/squelch /afollow')
    elseif State.group_choice == 2 then
        mq.cmdf('/dgga /squelch /target id %s', mq.TLO.Spawn("npc " .. item.npc).ID())
        mq.delay(300)
        mq.cmd('/dgga /squelch /afollow')
    else
        mq.TLO.Spawn("npc " .. item.npc).DoTarget()
        mq.cmdf('/dex %s /squelch /target id %s', State.group_combo[State.group_choice],
            mq.TLO.Spawn("npc " .. item.npc).ID())
        mq.delay(300)
        mq.cmd('/squelch /afollow')
        mq.cmdf('/dex %s /squelch /afollow', State.group_combo[State.group_choice])
    end
    if item.whereX ~= nil then
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), item.whereX, item.whereY)
        while distance > 50 do
            if State.skip == true then
                if State.group_choice == 1 then
                    mq.cmd('/squelch /afollow off')
                    State.skip = false
                    return
                elseif State.group_choice == 2 then
                    mq.cmd('/dgga /squelch /afollow off')
                    State.skip = false
                    return
                else
                    mq.cmd('/squelch /afollow off')
                    mq.cmdf('/dex %s /squelch /afollow off', State.group_combo[State.group_choice])
                end
            end
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), item.whereX, item.whereY)
        end
        travel.npc_stop_follow()
    end
end

function travel.npc_stop_follow()
    State.status = "Stopping autofollow"
    if State.group_choice == 1 then
        mq.cmd('/squelch /afollow off')
    elseif State.group_choice == 2 then
        mq.cmd('/dgga /squelch /afollow off')
    else
        mq.cmd('/squelch /afollow off')
        mq.cmdf('/dex %s /squelch /afollow off', State.group_combo[State.group_choice])
    end
end

function travel.npc_travel(item, class_settings, ignore_path_check, char_settings)
    ignore_path_check = ignore_path_check or false
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    if travel.invisCheck(char_settings, item.invis) then
        travel.invis(class_settings)
    end
    if item.whereX ~= nil then
        travel.loc_travel(item, class_settings, char_settings)
    else
        State.status = "Waiting for NPC " .. item.npc
        local ID = Mob.findNearestName(item.npc)
        travel.general_travel(item, class_settings, char_settings, ID)
    end
end

function travel.portal_set(item)
    State.status = "Setting portal to " .. item.zone
    mq.delay("1s")
    mq.cmdf("/squelch /portalset %s", item.zone)
    mq.delay("1s")
    while mq.TLO.PortalSetter.InProgress() == true do
        mq.delay(200)
    end
end

function travel.relocate(item, class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    State.status = "Relocating to " .. item.what
    if item.what == 'lobby' then
        if mq.TLO.Me.AltAbilityReady('Throne of Heroes')() == false then
            while mq.TLO.Me.AltAbilityReady('Throne of Heroes')() == false do
                State.status = 'Waiting for Throne of Heroes AA to be ready'
                if State.skip == true then
                    State.skip = false
                    return
                end
                mq.delay(200)
                if Mob.xtargetCheck(char_settings) then
                    Mob.clearXtarget(class_settings, char_settings)
                end
                if State.pause == true then
                    Actions.pause(State.status)
                end
            end
        end
    elseif item.what == 'origin' then
        if mq.TLO.Me.AltAbilityReady('Origin')() == false then
            State.status = 'Waiting for Origin AA to be ready'
            while mq.TLO.Me.AltAbilityReady('Origin')() == false do
                if State.skip == true then
                    State.skip = false
                    return
                end
                mq.delay(200)
                if Mob.xtargetCheck(char_settings) then
                    Mob.clearXtarget(class_settings, char_settings)
                end
                if State.pause == true then
                    Actions.pause(State.status)
                end
            end
        end
    end
    if State.group_choice == 1 then
        mq.cmdf('/squelch /relocate %s', item.what)
    elseif State.group_choice == 2 then
        mq.cmdf('/dgga /squelch /relocate %s', item.what)
    else
        mq.cmdf('/squelch /relocate %s', item.what)
        mq.cmdf('/dex %s /squelch /relocate %s', State.group_combo[State.group_choice], item.what)
    end
    while mq.TLO.Me.Casting() == nil do
        mq.delay(10)
    end
    while mq.TLO.Me.Casting() ~= nil do
        mq.delay(500)
    end
end

function travel.zone_travel(item, class_settings, char_settings, continue)
    if char_settings.general.returnToBind == true and continue == false then
        State.status = "Returning to bind point"
        while mq.TLO.Zone.ShortName() ~= mq.TLO.Me.BoundLocation('0')() do
            travel.gate_group()
            mq.delay("15s")
        end
    end
    if travel.invisCheck(char_settings, item.invis) then
        travel.navPause()
        travel.invis(class_settings)
    end
    State.status = "Traveling to " .. item.zone
    State.traveling = true
    if State.group_choice == 1 then
        mq.cmdf("/squelch /travelto %s", item.zone)
    elseif State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /travelto %s", item.zone)
    else
        mq.cmdf("/squelch /travelto %s", item.zone)
        mq.cmdf('/dex %s /squelch /travelto %s', State.group_combo[State.group_choice], item.zone)
    end
    local loopCount = 0
    while mq.TLO.Zone.ShortName() ~= item.zone and mq.TLO.Zone.Name() ~= item.zone do
        if mq.TLO.Navigation.Paused() == true then
            travel.navUnpause(item)
        end
        if State.skip == true then
            travel.navPause()
            State.skip = false
            return
        end
        mq.delay(500)
        if Mob.xtargetCheck(char_settings) then
            Mob.clearXtarget(class_settings, char_settings)
        end
        if State.pause == true then
            travel.navPause()
            Actions.pause(State.status)
            travel.navUnpause(item)
        end
        if travel.invisCheck(char_settings, item.invis) then
            if travel.invisTranslocatorCheck() == false then
                travel.navPause()
                travel.invis(class_settings)
                travel.navUnpause(item)
            end
        end
        if not mq.TLO.Navigation.Active() then
            if loopCount == 30 then
                loopCount = 0
                if mq.TLO.Cursor() ~= nil then
                    if mq.TLO.Cursor() == "Spire Stone" then
                        mq.cmd('/squelch /autoinv')
                    end
                end
                if mq.TLO.FindItem('=Spire Stone')() == nil then
                    if State.group_choice == 1 then
                        mq.cmdf("/squelch /travelto %s", item.zone)
                    elseif State.group_choice == 2 then
                        mq.cmdf("/dgga /squelch /travelto %s", item.zone)
                    else
                        mq.cmdf("/squelch /travelto %s", item.zone)
                        mq.cmdf('/dex %s /squelch /travelto %s', State.group_combo[State.group_choice], item.zone)
                    end
                end
            end
            loopCount = loopCount + 1
        end
    end
    if State.group_choice == 2 then
        while mq.TLO.Group.AnyoneMissing() do
            mq.delay(500)
            if State.skip == true then
                State.skip = false
                return
            end
        end
        mq.delay("5s")
    end
    if State.group_choice > 2 then
        while mq.TLO.Group.Member(State.group_combo[State.group_choice]).OtherZone() do
            mq.delay(500)
            if State.skip == true then
                State.skip = false
                return
            end
        end
        mq.delay("5s")
    end
    State.traveling = false
end

return travel
