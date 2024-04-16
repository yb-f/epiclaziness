local mq            = require('mq')
local manage        = require 'utils/manageautomation'
local translocators = { "Magus", "Translocator", "Priest of Discord", "Nexus Scion", "Deaen Greyforge",
    "Ambassador Cogswald", "Madronoa", "Belinda", "Herald of Druzzil Ro" }

local dist          = require 'utils/distance'

local speed_classes = { "Bard", "Druid", "Ranger", "Shaman" }
local speed_buffs   = { "Selo's Accelerato", "Communion of the Cheetah", "Spirit of Falcons", "Flight of Falcons" }
local travel        = {}

function travel.invisTranslocatorCheck()
    Logger.log_verbose('\aoChecking if we are near a translocator npc before invising.')
    for _, name in pairs(translocators) do
        if mq.TLO.Spawn('npc ' .. name).Distance() ~= nil then
            if mq.TLO.Spawn('npc ' .. name).Distance() < 50 then
                Logger.log_super_verbose("\aoWe are near \ag%s\ao. Skipping invis.", mq.TLO.Spawn('npc ' .. name).DisplayName())
                return true
            end
        end
    end
    return false
end

function travel.face_heading(heading)
    State.status = "Facing heading " .. heading
    Logger.log_info("\aoFacing heading: \ag%s\ao.", heading)
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
    local y = item.whereY
    local z = item.whereZ
    State.status = "Facing " .. y .. ", " .. x .. ", " .. z
    Logger.log_info("\aoFacing location \ag%s, %s, %s\ao.", y, x, z)
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
    if char_settings.general.speedForTravel == true then
        local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
        if speedChar ~= 'none' then
            travel.navPause()
            travel.doSpeed(speedChar, speedSkill)
            travel.navUnpause(item)
        end
    end
    if travel.invisCheck(char_settings, item.invis) then
        travel.invis(class_settings)
    end
    State.status = "Traveling forward to zone: " .. item.zone
    Logger.log_info("\aoTraveling forward to zone: \ag%s\ao.", item.zone)
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
    Logger.log_info("\aoGating to \ag%s\ao.", mq.TLO.Me.BoundLocation('0')())
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
    if char_settings.general.speedForTravel == true then
        local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
        if speedChar ~= 'none' then
            travel.navPause()
            travel.doSpeed(speedChar, speedSkill)
            travel.navUnpause(item)
        end
    end
    if travel.invisCheck(char_settings, item.invis) then
        travel.invis(class_settings)
    end
    State.status = "Traveling forward to  " .. y .. ", " .. x .. ", " .. z
    Logger.log_info("\aoTraveling without MQ2Nav to \ag%s, %s, %s\ao.", y, x, z)
    if State.group_choice == 1 then
        mq.cmd("/squelch /keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        Logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
            Logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
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
        Logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
            Logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
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
        Logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
            Logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
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
    Logger.log_info("\aoOpening door: \ar%s%s", mq.TLO.SwitchTarget(), mq.TLO.SwitchTarget.Name())
    mq.delay(200)
    if mq.TLO.Switch.Distance() ~= nil then
        if mq.TLO.Switch.Distance() < 20 then
            mq.cmd('/squelch /click left door')
            mq.delay(1000)
            return true
        end
    end
    return false
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
        if char_settings.general.speedForTravel == true then
            local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
            if speedChar ~= 'none' then
                travel.navPause()
                travel.doSpeed(speedChar, speedSkill)
                travel.navUnpause(item)
            end
        end
        if travel.invisCheck(char_settings, item.invis) then
            travel.navPause()
            travel.invis(class_settings)
            travel.navUnpause(item)
        end
        if loopCount == 10 then
            if item.radius == 1 then
                return
            end
            local temp = State.status
            local door = travel.open_door()
            if door == false and State.autosize == true then
                if State.autosize_self == false then
                    mq.cmd('/autosize self')
                    State.autosize_self = true
                end
                if State.autosize_on == false then
                    mq.cmd('/squelch /autosize on')
                    State.autosize_on = true
                    mq.cmdf('/squelch /autosize sizeself %s', State.autosize_sizes[State.autosize_choice])
                else
                    State.autosize_choice = State.autosize_choice + 1
                    if State.autosize_choice == 6 then State.autosize_choice = 1 end
                    mq.cmdf('/squelch /autosize sizeself %s', State.autosize_sizes[State.autosize_choice])
                end
            end
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
            if State.autosize_on == true then
                State.autosize_on = false
                mq.cmd('/squelch /autosize off')
            end
        end
    end
    if ID ~= 0 then
        local spawn = mq.TLO.Spawn(ID)
        distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), spawn.X(), spawn.Y())
    elseif item.whereX ~= 0 then
        distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), item.whereX, item.whereY)
    end
    if distance > 30 and item.radius == nil then
        Logger.log_warn("\aoStopped before reaching our destination. Attempting to restart navigation.")
        State.step = State.step
        State.rewound = true
        State.skip = true
    end
    Logger.log_verbose("\aoWe have reached our destination.")
    State.traveling = false
    State.autosize_on = false
    mq.cmd('/squelch /autosize off')
end

function travel.general_travel(item, class_settings, char_settings, ID)
    ID = ID or Mob.findNearestName(item.npc)
    if char_settings.general.speedForTravel == true then
        local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
        if speedChar ~= 'none' then
            travel.navPause()
            travel.doSpeed(speedChar, speedSkill)
            travel.navUnpause(item)
        end
    end
    if travel.invisCheck(char_settings, item.invis) then
        travel.invis(class_settings)
    end
    State.status = "Waiting for " .. item.npc
    Logger.log_info("\aoLooking for \ag%s\ao.", item.npc)
    while ID == 0 do
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
    Logger.log_info("\aoNavigating to \ag%s \ao(\ag%s\ao).", item.npc, ID)
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
    Logger.log_info("\aoUsing invisibility.")
    local invis_type = {}
    if mq.TLO.Me.Combat() == true then
        mq.cmd('/squelch /attack off')
    end
    for word in string.gmatch(class_settings.class_invis[mq.TLO.Me.Class()], '([^|]+)') do
        table.insert(invis_type, word)
    end
    if invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Potion' then
        Logger.log_super_verbose("\aoUsing a cloudy potion.")
        mq.cmd('/squelch /useitem "Cloudy Potion"')
    elseif invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Circlet of Shadows' then
        Logger.log_super_verbose("\aoUsing Circlet of Shadows.")
        mq.cmd('/squelch /useitem "Circlet of Shadows"')
    elseif invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Hide/Sneak' then
        Logger.log_super_verbose("\aoUsing hide/sneak.")
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
        Logger.log_super_verbose("\aoUsing alt ability \ag%s \ao(\ag%s\ao).", invis_type[class_settings.invis[mq.TLO.Me.Class()]], ID)
        while mq.TLO.Me.AltAbilityReady(ID)() == false do
            mq.delay(50)
        end
        mq.cmdf('/squelch /alt act %s', ID)
        mq.delay(500)
        while mq.TLO.Me.Casting() and mq.TLO.Me.Class() ~= "Bard" do
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
                    Logger.log_super_verbose("\aoHaving \ag%s \aouse a cloudy potion.", mq.TLO.Group.Member(i).DisplayName())
                    mq.cmdf('/dex %s /squelch /useitem "Cloudy Potion"', mq.TLO.Group.Member(i).DisplayName())
                elseif invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == 'Hide/Sneak' then
                    Logger.log_super_verbose("\aoHaving \ag%s \aouse hide/sneak.", mq.TLO.Group.Member(i).DisplayName())
                    mq.cmdf("/dex %s /squelch /doability hide", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(250)
                    mq.cmdf("/dex %s /squelch /doability sneak", mq.TLO.Group.Member(i).DisplayName())
                else
                    local ID = class_settings['skill_to_num'][invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]]]
                    Logger.log_super_verbose("\aoHaving \ag%s \aouse \ag%s \ao(\ag%s\ao).", mq.TLO.Group.Member(i).DisplayName(),
                        invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]], ID)
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
            Logger.log_super_verbose("\aoHaving \ag%s \aouse a cloudy potion.", mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
            mq.cmdf('/dex %s /squelch /useitem "Cloudy Potion"', mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
        elseif invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]] == 'Hide/Sneak' then
            Logger.log_super_verbose("\aoHaving \ag%s \aouse hide/sneak.", mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
            mq.cmdf("/dex %s /squelch /doability hide", mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
            mq.delay(250)
            mq.cmdf("/dex %s /squelch /doability sneak",
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
        else
            local ID = class_settings['skill_to_num'][invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]]]
            Logger.log_super_verbose("\aoHaving \ag%s \aouse \ag%s \ao(\ag%s\ao).", mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName(),
                invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]], ID)
            mq.cmdf('/dex %s /squelch /alt act "%s"', mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName(), ID)
        end
        mq.delay("4s")
    end
    mq.delay(100)
    State.status = temp
end

function travel.invisCheck(char_settings, invis)
    Logger.log_super_verbose("\aoChecking if we should be invis.")
    if invis == 1 and char_settings.general.invisForTravel == true and mq.TLO.Me.Invis() == false then
        Logger.log_super_verbose("\aoYes, we should be invis.")
        return true
    end
    return false
end

function travel.gotSpeedyClass(class, class_settings)
    for i, speedy in pairs(speed_classes) do
        if class == speedy then
            local speed_type = {}
            for word in string.gmatch(class_settings.move_speed[class], '([^|]+)') do
                table.insert(speed_type, word)
            end
            local speed_skill = speed_type[class_settings.speed[class]]
            if speed_skill == 'None' then
                return false
            else
                return true
            end
        end
    end
    return false
end

function travel.speedCheck(class_settings, char_settings)
    Logger.log_super_verbose("\aoChecking if we are missing travel speed buff.")
    for i, buff in pairs(speed_buffs) do
        if mq.TLO.Me.Buff(buff)() then
            Logger.log_super_verbose("\aoWe currently have a travel speed buff active: \ag%s\ao.", buff)
            return 'none', 'none'
        end
    end
    local amSpeedy = false
    if State.group_choice == 1 then
        local class = mq.TLO.Me.Class()
        amSpeedy = travel.gotSpeedyClass(class, class_settings)
        if amSpeedy == false then
            Logger.log_verbose("\aoWe do not have a travel speed buff to cast.")
            return 'none', 'none'
        else
            local speed_type = {}
            for word in string.gmatch(class_settings.move_speed[class], '([^|]+)') do
                table.insert(speed_type, word)
            end
            local speed_skill = speed_type[class_settings.speed[class]]
            Logger.log_verbose("\agI \aocan cast \ag%s\ao.", speed_skill)
            if speed_skill == 'Spirit of Eagles' then
                if class == 'Ranger' then speed_skill = "Spirit of Eagles(Ranger)" end
                if class == 'Druid' then speed_skill = "Spirit of Eagles(Druid)" end
            end
            local aaNum = class_settings['speed_to_num'][speed_skill]
            return mq.TLO.Me.DisplayName(), aaNum
        end
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            local class = mq.TLO.Group.Member(i).Class()
            amSpeedy = travel.gotSpeedyClass(class, class_settings)
            if amSpeedy == true then
                local speed_type = {}
                for word in string.gmatch(class_settings.move_speed[class], '([^|]+)') do
                    table.insert(speed_type, word)
                end
                if speed_type[class_settings.speed[class]] ~= 'none' then
                    local speed_skill = speed_type[class_settings.speed[class]]
                    Logger.log_verbose("\ag%s \aocan cast \ag%s\ao.", mq.TLO.Group.Member(i).DisplayName(), speed_skill)
                    if speed_skill == 'Spirit of Eagles' then
                        if class == 'Ranger' then speed_skill = "Spirit of Eagles(Ranger)" end
                        if class == 'Druid' then speed_skill = "Spirit of Eagles(Druid)" end
                    end
                    local aaNum = class_settings['speed_to_num'][speed_skill]
                    return mq.TLO.Group.Member(i).DisplayName(), aaNum
                end
            end
        end
        Logger.log_verbose("\aoWe do not have a travel speed buff to cast.")
        return 'none', 'none'
    else
        local class = mq.TLO.Me.Class()
        amSpeedy = travel.gotSpeedyClass(class, class_settings)
        if amSpeedy == true then
            local speed_type = {}
            for word in string.gmatch(class_settings.move_speed[class], '([^|]+)') do
                table.insert(speed_type, word)
            end
            local speed_skill = speed_type[class_settings.speed[class]]
            Logger.log_verbose("\agI \aocan cast \ag%s\ao.", speed_skill)
            if speed_skill == 'Spirit of Eagles' then
                if class == 'Ranger' then speed_skill = "Spirit of Eagles(Ranger)" end
                if class == 'Druid' then speed_skill = "Spirit of Eagles(Druid)" end
            end
            local aaNum = class_settings['speed_to_num'][speed_skill]
            return mq.TLO.Me.DisplayName(), aaNum
        else
            class = mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()
            amSpeedy = travel.gotSpeedyClass(class, class_settings)
            if amSpeedy == true then
                local speed_type = {}
                for word in string.gmatch(class_settings.move_speed[class], '([^|]+)') do
                    table.insert(speed_type, word)
                end
                local speed_skill = speed_type[class_settings.speed[class]]
                Logger.log_verbose("\ag%s \aocan cast \ag%s\ao.", mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName(), speed_skill)
                if speed_skill == 'Spirit of Eagles' then
                    if class == 'Ranger' then speed_skill = "Spirit of Eagles(Ranger)" end
                    if class == 'Druid' then speed_skill = "Spirit of Eagles(Druid)" end
                end
                local aaNum = class_settings['speed_to_num'][speed_skill]
                return mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName(), aaNum
            else
                Logger.log_verbose("\aoWe do not have a travel speed buff to cast.")
                return 'none', 'none'
            end
        end
    end
end

function travel.doSpeed(name, aaNum)
    if name == 'none' then return end
    if name == mq.TLO.Me.DisplayName() then
        Logger.log_verbose("\aoI am using my travel speed skill.")
        mq.cmdf("/alt act %s", aaNum)
    else
        Logger.log_verbose("\aoHaving \ag%s use their travel speed skill.", name)
        mq.cmdf("/dex %s /alt act %s", name, aaNum)
    end
end

function travel.loc_travel(item, class_settings, char_settings)
    local x = item.whereX
    local y = item.whereY
    local z = item.whereZ
    State.status = "Traveling to  " .. y .. ", " .. x .. ", " .. z
    Logger.log_info("\aoTraveling to location \ag%s, %s, %s\ao.", y, x, z)
    if mq.TLO.Navigation.PathExists('loc ' .. y .. ' ' .. x .. ' ' .. z) == false then
        State.status = "No path exists to loc Y: " .. y .. " X: " .. x .. " Z: " .. z
        Logger.log_error("\aoNo path found to location \ag%s, %s, %s\ao.", y, x, z)
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
    Logger.log_info("\aoPausing navigation.")
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
    if item.whereX then
        local x = item.whereX
        local y = item.whereY
        local z = item.whereZ
        Logger.log_info("\aoResuming navigation to location \ag%s, %s, %s\ao.", y, x, z)
        if State.group_choice == 1 then
            mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
        elseif State.group_choice == 2 then
            mq.cmdf("/dgga /squelch /nav loc %s %s %s", y, x, z)
        else
            mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
            mq.cmdf("/dex %s /squelch /nav loc %s %s %s", State.group_combo[State.group_choice], y, x, z)
        end
    elseif item.npc then
        Logger.log_info("\aoResuming navigation to \ag%s\ao.", item.npc)
        if State.group_choice == 1 then
            mq.cmdf("/squelch /nav spawn %s", item.npc)
        elseif State.group_choice == 2 then
            mq.cmdf("/dgga /squelch /nav spawn %s", item.npc)
        else
            mq.cmdf("/squelch /nav spawn %s", item.npc)
            mq.cmdf("/dex %s /squelch /nav spawn %s", State.group_combo[State.group_choice], item.npc)
        end
    elseif item.zone then
        Logger.log_info("\aoResuming navigation to zone \ag%s\ao.", item.zone)
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
    if char_settings.general.speedForTravel == true then
        local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
        if speedChar ~= 'none' then
            travel.navPause()
            travel.doSpeed(speedChar, speedSkill)
            travel.navUnpause(item)
        end
    end
    if travel.invisCheck(char_settings, item.invis) then
        travel.invis(class_settings)
    end
    State.status = "Following " .. item.npc
    Logger.log_info("\aoFollowing \ag%s\ao.", item.npc)
    if mq.TLO.Spawn("npc " .. item.npc).Distance() ~= nil then
        if mq.TLO.Spawn("npc " .. item.npc).Distance() > 100 then
            State.rewound = true
            State.step = State.step
            Logger.log_warn("\ar%s \aois over 100 units away. Moving back to step \ar%s\ao.", item.npc, State.step)
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
        Logger.log_info("\aoWe have reached our destination. Stopping follow.")
        travel.npc_stop_follow()
    end
end

function travel.npc_stop_follow()
    State.status = "Stopping autofollow"
    Logger.log_info("\aoStopping autofollow.")
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
    if char_settings.general.speedForTravel == true then
        local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
        if speedChar ~= 'none' then
            travel.navPause()
            travel.doSpeed(speedChar, speedSkill)
            travel.navUnpause(item)
        end
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
    Logger.log_info("\aoSetting portal to \ag%s\ao.", item.zone)
    mq.delay("1s")
    mq.cmdf("/squelch /portalset %s", item.zone)
    mq.delay("1s")
    while mq.TLO.PortalSetter.InProgress() == true do
        mq.delay(200)
    end
end

--- @return string
function travel.findReadyRelocate()
    if mq.TLO.Me.AltAbilityReady("Gate")() then
        return 'gate'
    end
    if mq.TLO.FindItem("=Drunkard's Stein").Timer() == 0 then
        return 'pok'
    end
    if mq.TLO.Me.AltAbilityReady("Throne of Heroes")() then
        return 'lobby'
    end
    if mq.TLO.Me.AltAbilityReady("Origin")() then
        return 'origin'
    end
    if mq.TLO.FindItem("=Philter of Major Transloation")() then
        return 'gate'
    end
    return 'none'
end

function travel.relocate(item, class_settings, char_settings)
    local currentZone = mq.TLO.Zone.Name()
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    State.status = "Searching for relocation ability/item that is ready."
    Logger.log_info("\aoSearching for a relocation ability/item that is ready.")
    local relocate = 'none'
    relocate = travel.findReadyRelocate()
    while relocate == 'none' do
        mq.delay("3s")
        relocate = travel.findReadyRelocate()
    end
    State.status = "Relocating to " .. relocate
    Logger.log_info("\aoRelocating to \ag%s\ao.", relocate)
    if State.group_choice == 1 then
        mq.cmdf('/squelch /relocate %s', relocate)
    elseif State.group_choice == 2 then
        mq.cmdf('/dgga /squelch /relocate %s', relocate)
    else
        mq.cmdf('/squelch /relocate %s', relocate)
        mq.cmdf('/dex %s /squelch /relocate %s', State.group_combo[State.group_choice], relocate)
    end
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    local loopCount = 0
    while mq.TLO.Me.Casting() == nil do
        loopCount = loopCount + 1
        mq.delay(10)
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
        if loopCount >= 200 then
            Logger.log_warn("\aoSpent 2 seconds waiting for relocate to \ar%s \ao to cast. Moving on.", relocate)
            break
        end
    end
    loopCount = 0
    while mq.TLO.Me.Casting() ~= nil do
        loopCount = loopCount + 1
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
        if loopCount >= 33 then
            Logger.log_warn("\aoSpent 16 seconds waiting for relocate to \ar%s \ao to finish casting. Moving on.", relocate)
            break
        end
    end
    if currentZone == mq.TLO.Zone.Name() then
        Logger.log_warn("\aoWe are still in \ag%s \aoattempting to relocate again.", currentZone)
        State.rewound = true
        State.step = State.step
        return
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
    if char_settings.general.speedForTravel == true then
        local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
        if speedChar ~= 'none' then
            travel.navPause()
            travel.doSpeed(speedChar, speedSkill)
            travel.navUnpause(item)
        end
    end
    if travel.invisCheck(char_settings, item.invis) then
        travel.navPause()
        travel.invis(class_settings)
    end
    State.status = "Traveling to " .. item.zone
    Logger.log_info("\aoTraveling to \ag%s\ao.", item.zone)
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
    State.X = mq.TLO.Me.X()
    State.Y = mq.TLO.Me.Y()
    State.Z = mq.TLO.Me.Z()
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
        if char_settings.general.speedForTravel == true then
            local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
            if speedChar ~= 'none' then
                travel.navPause()
                travel.doSpeed(speedChar, speedSkill)
                travel.navUnpause(item)
            end
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
                    Logger.log_info("\aoTravel stopped. Starting travel to \ag%s \aoagain.", item.zone)
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
        else
            if loopCount == 10 then
                if item.radius == 1 then
                    return
                end
                local temp = State.status
                local door = travel.open_door()
                if door == false and State.autosize == true then
                    if State.autosize_self == false then
                        mq.cmd('/autosize self')
                        State.autosize_self = true
                    end
                    if State.autosize_on == false then
                        mq.cmd('/squelch /autosize on')
                        State.autosize_on = true
                        mq.cmdf('/squelch /autosize sizeself %s', State.autosize_sizes[State.autosize_choice])
                    else
                        State.autosize_choice = State.autosize_choice + 1
                        if State.autosize_choice == 6 then State.autosize_choice = 1 end
                        mq.cmdf('/squelch /autosize sizeself %s', State.autosize_sizes[State.autosize_choice])
                    end
                end
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
                if State.autosize_on == true then
                    State.autosize_on = false
                    mq.cmd('/squelch /autosize off')
                end
            end
        end
    end
    if State.group_choice == 2 then
        Logger.log_info("\aoWaiting for group members to arrive before continuing.")
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
        Logger.log_info("\aoWaiting for \ag%s to arrive before continuing.", State.group_combo[State.group_choice])
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
