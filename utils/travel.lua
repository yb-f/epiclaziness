local mq                  = require('mq')
local logger              = require('utils/logger')
local dist                = require 'utils/distance'

local translocators       = { "Magus", "Translocator", "Priest of Discord", "Nexus Scion", "Deaen Greyforge",
    "Ambassador Cogswald", "Madronoa", "Belinda", "Herald of Druzzil Ro" }

local SELOS_BUFF          = 3704
local CHEETAH_BUFF        = 939
local SPIRIT_FALCONS_BUFf = 8600
local FLIGHT_FALCONS_BUFF = 8601
local speed_classes       = { "Bard", "Druid", "Ranger", "Shaman" }
local speed_buffs         = { "Selo's Accelerato", "Communion of the Cheetah", "Spirit of Falcons", "Flight of Falcons" }
local travel              = {}
travel.looping            = false

function travel.invisTranslocatorCheck()
    logger.log_verbose('\aoChecking if we are near a translocator npc before invising.')
    for _, name in ipairs(translocators) do
        if mq.TLO.Spawn('npc ' .. name).Distance() ~= nil then
            if mq.TLO.Spawn('npc ' .. name).Distance() < 50 then
                logger.log_super_verbose("\aoWe are near \ag%s\ao. Skipping invis.", mq.TLO.Spawn('npc ' .. name).DisplayName())
                return true
            end
        end
    end
    return false
end

function travel.face_heading(item)
    _G.State:setStatusText(string.format("Facing heading %s.", item.what))
    logger.log_info("\aoFacing heading: \ag%s\ao.", item.what)
    if _G.State.group_choice == 1 then
        mq.cmdf("/squelch /face heading %s", item.what)
    elseif _G.State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /face heading %s", item.what)
    else
        mq.cmdf("/squelch /face heading %s", item.what)
        mq.cmdf("/dex %s /squelch /face heading %s", _G.State.group_combo[_G.State.group_choice], item.what)
    end
    mq.delay(250)
end

function travel.face_loc(item)
    local x = item.whereX
    local y = item.whereY
    local z = item.whereZ
    _G.State:setStatusText(string.format("Facing location: %s %s %s.", y, x, z))
    logger.log_info("\aoFacing location \ag%s, %s, %s\ao.", y, x, z)
    if _G.State.group_choice == 1 then
        mq.cmdf("/squelch /face loc %s,%s,%s", y, x, z)
    elseif _G.State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /face loc %s,%s,%s", y, x, z)
    else
        mq.cmdf("/squelch /face loc %s,%s,%s", y, x, z)
        mq.cmdf("/dex %s /squelch /face loc %s,%s,%s", _G.State.group_combo[_G.State.group_choice], y, x, z)
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
    if travel.invisCheck(char_settings, class_settings, item.invis) then
        travel.invis(class_settings)
    end
    _G.State:setStatusText(string.format("Traveling forward to zone: %s.", item.zone))
    logger.log_info("\aoTraveling forward to zone: \ag%s\ao.", item.zone)
    if _G.State.group_choice == 1 then
        mq.cmd("/squelch /keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= item.zone do
            mq.delay(500)
        end
    elseif _G.State.group_choice == 2 then
        mq.cmd("/dgge /squelch /keypress forward hold")
        mq.cmd("/squelch /keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= item.zone do
            mq.delay(500)
        end
        while mq.TLO.Group.AnyoneMissing() do
            mq.delay(500)
        end
    else
        mq.cmdf("/dex %s /keypress forward hold", _G.State.group_combo[_G.State.group_choice])
        mq.cmd("/squelch /keypress forward hold")
        while mq.TLO.Zone.ShortName() ~= item.zone and mq.TLO.Zone.Name() ~= item.zone do
            mq.delay(500)
        end
        while mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).OtherZone() do
            mq.delay(500)
        end
    end
    mq.delay("2s")
end

function travel.gate_group()
    logger.log_info("\aoGating to \ag%s\ao.", mq.TLO.Me.BoundLocation('0')())
    if _G.State.group_choice == 1 then
        mq.cmd("/squelch /relocate gate")
        mq.delay(500)
    elseif _G.State.group_choice == 2 then
        mq.cmd("/dgga /squelch /relocate gate")
        mq.delay(500)
    else
        mq.cmd("/squelch /relocate gate")
        mq.cmdf('/dex %s /squelch /relocate gate', _G.State.group_combo[_G.State.group_choice])
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
    if travel.invisCheck(char_settings, class_settings, item.invis) then
        travel.invis(class_settings)
    end
    _G.State:setStatusText(string.format("Traveling forward to location: %s %s %s.", y, x, z))
    logger.log_info("\aoTraveling without MQ2Nav to \ag%s, %s, %s\ao.", y, x, z)
    if _G.State.group_choice == 1 then
        mq.cmd("/squelch /keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
            logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
            if _G.State.should_skip == true then
                _G.State.should_skip = false
                return
            end
        end
        mq.cmd("/squelch /keypress forward")
    elseif _G.State.group_choice == 2 then
        mq.cmd("/dgge /squelch /keypress forward hold")
        mq.cmd("/squelch /keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
            logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
            if _G.State.should_skip == true then
                _G.State.should_skip = false
                return
            end
        end
        mq.cmd("/dgge /squelch /keypress forward")
        mq.cmd("/squelch /keypress forward")
    else
        mq.cmdf("/dex %s /squelch /keypress forward hold", _G.State.group_combo[_G.State.group_choice])
        mq.cmd("/squelch /keypress forward hold")
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
        logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
        while distance > 5 do
            mq.delay(10)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
            logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
            if _G.State.should_skip == true then
                _G.State.should_skip = false
                return
            end
        end
        mq.cmdf("/dex %s /squelch /keypress forward", _G.State.group_combo[_G.State.group_choice])
        mq.cmd("/squelch /keypress forward")
    end
end

function travel.open_door(item)
    _G.State:setStatusText("Opening door.")
    mq.delay(200)
    mq.cmd("/squelch /doortarget")
    logger.log_info("\aoOpening door: \ar%s%s", mq.TLO.SwitchTarget(), mq.TLO.SwitchTarget.Name())
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
    local me = mq.TLO.Me
    _G.State:setLocation(me.X(), me.Y(), me.Z())
    ID = ID or 0
    local loopCount = 0
    local distance = 0
    while mq.TLO.Navigation.Active() do
        mq.delay(200)
        if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
            logger.log_error('\arNot in game, closing.')
            mq.exit()
        end
        if mq.TLO.Navigation.Paused() == true then
            travel.navUnpause(item)
        end
        if _G.State.should_skip == true then
            travel.navPause()
            _G.State.should_skip = false
            return
        end
        if item.zone == nil then
            if _G.Mob.xtargetCheck(char_settings) then
                travel.navPause()
                _G.Mob.clearXtarget(class_settings, char_settings)
                travel.navUnpause(item)
            end
        end
        if _G.State.is_paused == true then
            travel.navPause()
            _G.Actions.pauseTask(_G.State:readStatusText())
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
        if travel.invisCheck(char_settings, class_settings, item.invis) then
            travel.navPause()
            travel.invis(class_settings)
            travel.navUnpause(item)
        end
        if loopCount == 10 then
            if item.radius == 1 then
                return
            end
            local temp = _G.State:readStatusText()
            local door = travel.open_door()
            if door == false and _G.State.autosize == true then
                if _G.State.autosize_self == false then
                    mq.cmd('/autosize self')
                    _G.State.autosize_self = true
                end
                if _G.State.autosize_on == false then
                    mq.cmd('/squelch /autosize on')
                    _G.State.autosize_on = true
                    mq.cmdf('/squelch /autosize sizeself %s', _G.State.autosize_sizes[_G.State.autosize_choice])
                else
                    _G.State.autosize_choice = _G.State.autosize_choice + 1
                    if _G.State.autosize_choice == 6 then _G.State.autosize_choice = 1 end
                    mq.cmdf('/squelch /autosize sizeself %s', _G.State.autosize_sizes[_G.State.autosize_choice])
                end
            end
            loopCount = 0
            _G.State:setStatusText(temp)
        end
        if dist.GetDistance3D(me.X(), me.Y(), me.Z(), _G.State:readLocation()) < 20 then
            loopCount = loopCount + 1
        elseif dist.GetDistance3D(me.X(), me.Y(), me.Z(), _G.State:readLocation()) > 75 then
            logger.log_info("\aoWe seem to have crossed a teleporter, moving to next step.")
            _G.State.destType = ''
            _G.State.dest = ''
            _G.State.is_traveling = false
            _G.State.autosize_on = false
            mq.cmd('/squelch /autosize off')
            travel.navPause()
            _G.State:setLocation(me.X(), me.Y(), me.Z())
            return
        else
            _G.State:setLocation(me.X(), me.Y(), me.Z())
            loopCount = 0
            if _G.State.autosize_on == true then
                _G.State.autosize_on = false
                mq.cmd('/squelch /autosize off')
            end
        end
    end
    if ID ~= 0 then
        local spawn = mq.TLO.Spawn(ID)
        distance = dist.GetDistance(me.X(), me.Y(), spawn.X(), spawn.Y())
    elseif item.whereX ~= 0 then
        distance = dist.GetDistance(me.X(), me.Y(), item.whereX, item.whereY)
    end
    if distance > 30 and item.radius == nil then
        logger.log_warn("\aoStopped before reaching our destination. Attempting to restart navigation.")
        _G.State:handle_step_change(_G.State.current_step)
    end
    logger.log_verbose("\aoWe have reached our destination.")
    _G.State.destType = ''
    _G.State.dest = ''
    _G.State.is_traveling = false
    _G.State.autosize_on = false
    mq.cmd('/squelch /autosize off')
end

function travel.general_travel(item, class_settings, char_settings, ID)
    ID = ID or _G.Mob.findNearestName(item.npc, item, class_settings, char_settings)
    if char_settings.general.speedForTravel == true then
        local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
        if speedChar ~= 'none' then
            travel.navPause()
            travel.doSpeed(speedChar, speedSkill)
            travel.navUnpause(item)
        end
    end
    if travel.invisCheck(char_settings, class_settings, item.invis) then
        travel.invis(class_settings)
    end
    _G.State:setStatusText(string.format("Waiting for %s.", item.npc))
    logger.log_info("\aoLooking for \ag%s\ao.", item.npc)
    while ID == 0 or ID == nil do
        mq.delay(500)
        if _G.State.should_skip == true then
            travel.navPause()
            _G.State.should_skip = false
            return
        end
        if _G.State.is_paused == true then
            travel.navPause()
            _G.Actions.pauseTask(_G.State:readStatusText())
            travel.navUnpause(item)
        end
        ID = _G.Mob.findNearestName(item.npc, item, class_settings, char_settings)
    end
    _G.State:setStatusText(string.format("Navigating to %s.", item.npc))
    if ID == 0 then
        ID = _G.Mob.findNearestName(item.npc, item, class_settings, char_settings)
    end
    if dist.GetDistance3D(mq.TLO.Spawn(ID).X(), mq.TLO.Spawn(ID).Y(), mq.TLO.Spawn(ID).Z(), mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z()) < 10 then
        logger.log_debug('\aoDistance to \ag%s \aois less than 10. Not traveling.', item.npc)
    end
    logger.log_info("\aoNavigating to \ag%s \ao(\ag%s\ao).", item.npc, ID)
    if _G.State.group_choice == 1 then
        mq.cmdf("/squelch /nav id %s", ID)
    elseif _G.State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /nav id %s", ID)
    else
        mq.cmdf("/squelch /nav id %s", ID)
        mq.cmdf('/dex %s /squelch /nav id %s', _G.State.group_combo[_G.State.group_choice], ID)
    end
    _G.State.startDist = mq.TLO.Navigation.PathLength("id " .. ID)()
    _G.State.destType = 'ID'
    _G.State.dest = ID
    mq.delay(200)
    travel.travelLoop(item, class_settings, char_settings, ID)
end

function travel.invis(class_settings)
    local temp = _G.State:readStatusText()
    _G.State:setStatusText("Using invis.")
    logger.log_info("\aoUsing invisibility.")
    local invis_type = {}
    if mq.TLO.Me.Combat() == true then
        mq.cmd('/squelch /attack off')
    end
    for word in string.gmatch(class_settings.class_invis[mq.TLO.Me.Class()], '([^|]+)') do
        table.insert(invis_type, word)
    end
    if mq.TLO.Me.Invis() == false then
        logger.log_debug("\aoI am using \ag%s \aoto invis myself.", invis_type[class_settings.invis[mq.TLO.Me.Class()]])
        if invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Potion' then
            logger.log_super_verbose("\aoUsing a cloudy potion.")
            mq.cmd('/squelch /useitem "Cloudy Potion"')
        elseif invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Circlet of Shadows' then
            logger.log_super_verbose("\aoUsing Circlet of Shadows.")
            mq.cmd('/squelch /useitem "Circlet of Shadows"')
        elseif invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Hide/Sneak' then
            logger.log_super_verbose("\aoUsing hide/sneak.")
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
            logger.log_super_verbose("\aoUsing alt ability \ag%s \ao(\ag%s\ao).", invis_type[class_settings.invis[mq.TLO.Me.Class()]], ID)
            while mq.TLO.Me.AltAbilityReady(ID)() == false do
                mq.delay(50)
            end
            mq.cmdf('/squelch /alt act %s', ID)
            mq.delay(500)
            while mq.TLO.Me.Casting() and mq.TLO.Me.Class() ~= "Bard" do
                mq.delay(200)
            end
        end
    end
    if _G.State.group_choice == 1 then
    elseif _G.State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                if mq.TLO.Group.Member(i).Invis() == false then
                    local invis_type = {}
                    for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(i).Class()], '([^|]+)') do
                        table.insert(invis_type, word)
                    end
                    logger.log_debug("\aoUsing \ag%s \aoon \ag%s \ao to invis them.", invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]],
                        mq.TLO.Group.Member(i).DisplayName())
                    if invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == 'Potion' then
                        logger.log_super_verbose("\aoHaving \ag%s \aouse a cloudy potion.", mq.TLO.Group.Member(i).DisplayName())
                        mq.cmdf('/dex %s /squelch /useitem "Cloudy Potion"', mq.TLO.Group.Member(i).DisplayName())
                    elseif invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == 'Hide/Sneak' then
                        logger.log_super_verbose("\aoHaving \ag%s \aouse hide/sneak.", mq.TLO.Group.Member(i).DisplayName())
                        mq.cmdf("/dquery %s -q Me.Sneaking", mq.TLO.Group.Member(i).DisplayName())
                        if mq.TLO.DanNet.Query() == "FALSE" then
                            mq.cmdf("/dobserve %s -q Me.AbilityReady[Sneak]", mq.TLO.Group.Member(i).DisplayName())
                            while mq.TLO.DanNet(mq.TLO.Group.Member(i).DisplayName()).Observe("Me.AbilityReady[Sneak]")() == "FALSE" do
                                mq.delay(50)
                            end
                            mq.cmdf("/dex %s /squelch /doability sneak", mq.TLO.Group.Member(i).DisplayName())
                            mq.cmdf("/dobserve %s -q Me.AbilityReady[Sneak] -drop", mq.TLO.Group.Member(i).DisplayName())
                        end
                        if mq.TLO.Group.Member(i).Invis() == false then
                            mq.cmdf("/dobserve %s -q Me.AbilityReady[Hide]", mq.TLO.Group.Member(i).DisplayName())
                            while mq.TLO.DanNet(mq.TLO.Group.Member(i).DisplayName()).Observe("Me.AbilityReady[Hide]")() == "FALSE" do
                                mq.delay(50)
                            end
                            mq.cmdf("/dex %s /squelch /doability hide", mq.TLO.Group.Member(i).DisplayName())
                        end
                    elseif invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == 'Circlet of Shadows' then
                        logger.log_super_verbose("\aoHaving \ag%s \aouse circlet of shadows.", mq.TLO.Group.Member(i).DisplayName())
                        mq.cmdf('/dex %s /squelch /useitem "Circlet of Shadows"', mq.TLO.Group.Member(i).DisplayName())
                    else
                        local ID = class_settings['skill_to_num'][invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]]]
                        logger.log_super_verbose("\aoHaving \ag%s \aouse \ag%s \ao(\ag%s\ao).", mq.TLO.Group.Member(i).DisplayName(),
                            invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]], ID)
                        mq.cmdf('/dex %s /squelch /alt act "%s"', mq.TLO.Group.Member(i).DisplayName(),
                            ID)
                    end
                end
            end
        end
        mq.delay("4s")
    else
        local invis_type = {}
        for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).Class()], '([^|]+)') do
            table.insert(invis_type, word)
        end
        if invis_type[class_settings.invis[mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).Class()]] == 'Potion' then
            logger.log_super_verbose("\aoHaving \ag%s \aouse a cloudy potion.", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
            mq.cmdf('/dex %s /squelch /useitem "Cloudy Potion"', mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
        elseif invis_type[class_settings.invis[mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).Class()]] == 'Hide/Sneak' then
            logger.log_super_verbose("\aoHaving \ag%s \aouse hide/sneak.", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
            mq.cmdf("/dquery %s -q Me.Sneaking", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
            if mq.TLO.DanNet.Query() == "FALSE" then
                mq.cmdf("/dobserve %s -q Me.AbilityReady[Sneak]", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
                while mq.TLO.DanNet(mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName()).Observe("Me.AbilityReady[Sneak]")() == "FALSE" do
                    mq.delay(50)
                end
                mq.cmdf("/dex %s /squelch /doability sneak", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
                mq.cmdf("/dobserve %s -q Me.AbilityReady[Sneak] -drop", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
            end
            if mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).Invis() == false then
                mq.cmdf("/dobserve %s -q Me.AbilityReady[Hide]", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
                while mq.TLO.DanNet(mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName()).Observe("Me.AbilityReady[Hide]")() == "FALSE" do
                    mq.delay(50)
                end
                mq.cmdf("/dex %s /squelch /doability hide", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
            end
        else
            local ID = class_settings['skill_to_num'][invis_type[class_settings.invis[mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).Class()]]]
            logger.log_super_verbose("\aoHaving \ag%s \aouse \ag%s \ao(\ag%s\ao).", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName(),
                invis_type[class_settings.invis[mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).Class()]], ID)
            mq.cmdf('/dex %s /squelch /alt act "%s"', mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName(), ID)
        end
        mq.delay("4s")
    end
    mq.delay(100)
    _G.State:setStatusText(temp)
end

function travel.invisCheck(char_settings, class_settings, invis)
    logger.log_super_verbose("\aoChecking if we should be invis.")
    if invis == 1 and char_settings.general.invisForTravel == true then
        if mq.TLO.Me.Invis() == false then
            logger.log_super_verbose("\aoYes, we should be invis.")
            return true
        end
        if _G.State.group_choice == 2 then
            for i = 0, mq.TLO.Group.GroupSize() - 1 do
                if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                    if mq.TLO.Group.Member(i).Invis() == false then
                        logger.log_super_verbose("\aoYes, \ag%s \aoshould be invis.", mq.TLO.Group.Member(i).DisplayName())
                        return true
                    end
                end
            end
        else
            if mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).Invis() == false then
                logger.log_super_verbose("\aoYes, \ag%s \aoshould be invis.", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName())
                return true
            end
        end
    end
    return false
end

function travel.gotSpeedyClass(class, class_settings)
    for i, speedy in ipairs(speed_classes) do
        if class == speedy then
            local speed_type = {}
            for word in string.gmatch(class_settings.move_speed[class], '([^|]+)') do
                table.insert(speed_type, word)
            end
            local speed_skill = speed_type[class_settings.speed[class]]
            return speed_skill ~= 'None'
        end
    end
    return false
end

function travel.speedCheck(class_settings, char_settings)
    logger.log_super_verbose("\aoChecking if we are missing travel speed buff.")
    for i, buff in ipairs(speed_buffs) do
        if mq.TLO.Me.Buff(buff)() then
            logger.log_super_verbose("\aoWe currently have a travel speed buff active: \ag%s\ao.", buff)
            return 'none', 'none'
        end
    end
    local amSpeedy = false
    local aanums = {}
    local foundSpeed = false
    if _G.State.group_choice == 1 then
        local class = mq.TLO.Me.Class()
        amSpeedy = travel.gotSpeedyClass(class, class_settings)
        if amSpeedy == false then
            logger.log_verbose("\aoWe do not have a travel speed buff to cast.")
            return 'none', 'none'
        else
            local speed_type = {}
            for word in string.gmatch(class_settings.move_speed[class], '([^|]+)') do
                table.insert(speed_type, word)
            end
            local speed_skill = speed_type[class_settings.speed[class]]
            logger.log_verbose("\agI \aocan cast \ag%s\ao.", speed_skill)
            if speed_skill == 'Spirit of Eagles' then
                if class == 'Ranger' then speed_skill = "Spirit of Eagles(Ranger)" end
                if class == 'Druid' then speed_skill = "Spirit of Eagles(Druid)" end
            end
            local aaNum = class_settings['speed_to_num'][speed_skill]
            return mq.TLO.Me.DisplayName(), aaNum
        end
    elseif _G.State.group_choice == 2 then
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
                    logger.log_verbose("\ag%s \aocan cast \ag%s\ao.", mq.TLO.Group.Member(i).DisplayName(), speed_skill)
                    if speed_skill == 'Spirit of Eagles' then
                        if class == 'Ranger' then speed_skill = "Spirit of Eagles(Ranger)" end
                        if class == 'Druid' then speed_skill = "Spirit of Eagles(Druid)" end
                    end
                    local aaNum = class_settings['speed_to_num'][speed_skill]
                    aanums[mq.TLO.Group.Member(i).DisplayName()] = aaNum
                    foundSpeed = true
                    --return mq.TLO.Group.Member(i).DisplayName(), aaNum
                end
            end
        end
        if foundSpeed == false then
            logger.log_verbose("\aoWe do not have a travel speed buff to cast.")
            return 'none', 'none'
        else
            local aaNum = 0
            local casterName = ''
            for name, num in pairs(aanums) do
                if num == SELOS_BUFF then
                    aaNum = num
                    casterName = name
                    break
                elseif num == CHEETAH_BUFF and aaNum ~= SELOS_BUFF then
                    aaNum = num
                    casterName = name
                elseif (num == SPIRIT_FALCONS_BUFf or num == FLIGHT_FALCONS_BUFF) and aaNum ~= SELOS_BUFF and aaNum ~= CHEETAH_BUFF then
                    aaNum = num
                    casterName = name
                end
            end
            return casterName, aaNum
        end
    else
        local aaNum = 0
        local casterName = ''
        local class = mq.TLO.Me.Class()
        amSpeedy = travel.gotSpeedyClass(class, class_settings)
        if amSpeedy == true then
            local speed_type = {}
            for word in string.gmatch(class_settings.move_speed[class], '([^|]+)') do
                table.insert(speed_type, word)
            end
            local speed_skill = speed_type[class_settings.speed[class]]
            logger.log_verbose("\agI \aocan cast \ag%s\ao.", speed_skill)
            if speed_skill == 'Spirit of Eagles' then
                if class == 'Ranger' then speed_skill = "Spirit of Eagles(Ranger)" end
                if class == 'Druid' then speed_skill = "Spirit of Eagles(Druid)" end
            end
            aaNum = class_settings['speed_to_num'][speed_skill]
            casterName = mq.TLO.Me.DisplayName()
            --return mq.TLO.Me.DisplayName(), aaNum
        end
        if aaNum == SELOS_BUFF then
            return casterName, aaNum
        end
        aanums[mq.TLO.Me.DisplayName()] = aaNum
        class = mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).Class()
        amSpeedy = travel.gotSpeedyClass(class, class_settings)
        if amSpeedy == true then
            local speed_type = {}
            for word in string.gmatch(class_settings.move_speed[class], '([^|]+)') do
                table.insert(speed_type, word)
            end
            local speed_skill = speed_type[class_settings.speed[class]]
            logger.log_verbose("\ag%s \aocan cast \ag%s\ao.", mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName(), speed_skill)
            if speed_skill == 'Spirit of Eagles' then
                if class == 'Ranger' then speed_skill = "Spirit of Eagles(Ranger)" end
                if class == 'Druid' then speed_skill = "Spirit of Eagles(Druid)" end
            end
            aaNum = class_settings['speed_to_num'][speed_skill]
            aanums[mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).DisplayName()] = aaNum
            for name, num in pairs(aanums) do
                if num == SELOS_BUFF then
                    aaNum = num
                    casterName = name
                    break
                elseif num == CHEETAH_BUFF and aaNum ~= SELOS_BUFF then
                    aaNum = num
                    casterName = name
                elseif (num == SPIRIT_FALCONS_BUFf or num == FLIGHT_FALCONS_BUFF) and aaNum ~= SELOS_BUFF and aaNum ~= CHEETAH_BUFF then
                    aaNum = num
                    casterName = name
                end
            end
            return casterName, aaNum
        else
            logger.log_verbose("\aoWe do not have a travel speed buff to cast.")
            return 'none', 'none'
        end
    end
end

function travel.doSpeed(name, aaNum)
    if name == 'none' then return end
    if name == mq.TLO.Me.DisplayName() then
        logger.log_verbose("\aoI am using my travel speed skill.")
        mq.cmdf("/alt act %s", aaNum)
    else
        logger.log_verbose("\aoHaving \ag%s \aouse their travel speed skill.", name)
        mq.cmdf("/dex %s /alt act %s", name, aaNum)
    end
end

function travel.loc_travel(item, class_settings, char_settings)
    local x = item.whereX
    local y = item.whereY
    local z = item.whereZ
    if dist.GetDistance3D(x, y, z, mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z()) < 10 then
        logger.log_debug('\aoDistance to \ag%s %s %s \aois less than 10, not moving.', y, x, z)
        return
    end
    _G.State:setStatusText(string.format("Traveling to location: %s %s %s.", y, x, z))
    logger.log_info("\aoTraveling to location \ag%s, %s, %s\ao.", y, x, z)
    if mq.TLO.Navigation.PathExists('loc ' .. y .. ' ' .. x .. ' ' .. z) == false then
        _G.State:setStatusText(string.format("No path exists to location: %s %s %s.", y, x, z))
        logger.log_error("\aoNo path found to location \ag%s, %s, %s\ao.", y, x, z)
        _G.State.is_task_running = false
        mq.cmd('/foreground')
        return
    end
    _G.State.is_traveling = true
    if _G.State.group_choice == 1 then
        mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
    elseif _G.State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /nav loc %s %s %s", y, x, z)
    else
        mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
        mq.cmdf("/dex %s /squelch /nav loc %s %s %s", _G.State.group_combo[_G.State.group_choice], y, x, z)
    end
    local tempString = string.format("loc %s %s %s", y, x, z)
    _G.State.startDist = mq.TLO.Navigation.PathLength(tempString)()
    _G.State.destType = 'loc'
    _G.State.dest = string.format("%s %s %s", y, x, z)
    mq.delay(100)
    travel.travelLoop(item, class_settings, char_settings)
end

function travel.navPause()
    logger.log_info("\aoPausing navigation.")
    if _G.State.group_choice == 1 then
        mq.cmd('/squelch /nav pause')
    elseif _G.State.group_choice == 2 then
        mq.cmd('/dgga /squelch /nav pause')
    else
        mq.cmd('/squelch /nav pause')
        mq.cmdf('/dex %s /nav pause', _G.State.group_combo[_G.State.group_choice])
    end
    mq.delay(500)
end

function travel.navUnpause(item)
    if item.whereX then
        local x = item.whereX
        local y = item.whereY
        local z = item.whereZ
        logger.log_info("\aoResuming navigation to location \ag%s, %s, %s\ao.", y, x, z)
        if _G.State.group_choice == 1 then
            mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
        elseif _G.State.group_choice == 2 then
            mq.cmdf("/dgga /squelch /nav loc %s %s %s", y, x, z)
        else
            mq.cmdf("/squelch /nav loc %s %s %s", y, x, z)
            mq.cmdf("/dex %s /squelch /nav loc %s %s %s", _G.State.group_combo[_G.State.group_choice], y, x, z)
        end
        local tempString = string.format("loc %s %s %s", y, x, z)
        _G.State.startDist = mq.TLO.Navigation.PathLength(tempString)()
        _G.State.destType = 'loc'
        _G.State.dest = string.format("%s %s %s", y, x, z)
    elseif item.npc then
        logger.log_info("\aoResuming navigation to \ag%s\ao.", item.npc)
        if _G.State.group_choice == 1 then
            mq.cmdf("/squelch /nav spawn %s", item.npc)
        elseif _G.State.group_choice == 2 then
            mq.cmdf("/dgga /squelch /nav spawn %s", item.npc)
        else
            mq.cmdf("/squelch /nav spawn %s", item.npc)
            mq.cmdf("/dex %s /squelch /nav spawn %s", _G.State.group_combo[_G.State.group_choice], item.npc)
        end
        local tempString = string.format("spawn %s ", item.npc)
        _G.State.startDist = mq.TLO.Navigation.PathLength(tempString)()
        _G.State.destType = 'spawn'
        _G.State.dest = item.npc
    elseif item.zone then
        logger.log_info("\aoResuming navigation to zone \ag%s\ao.", item.zone)
        if _G.State.group_choice == 1 then
            mq.cmdf("/squelch /travelto %s", item.zone)
        elseif _G.State.group_choice == 2 then
            mq.cmdf("/dgga /squelch /travelto %s", item.zone)
        else
            mq.cmdf("/squelch /travelto %s", item.zone)
            mq.cmdf('/dex %s /squelch /travelto %s', _G.State.group_combo[_G.State.group_choice], item.zone)
        end
    end
    mq.delay(500)
end

function travel.follow_event()
    travel.looping = false
end

function travel.npc_follow(item, class_settings, char_settings, event)
    event = event or false
    if _G.Mob.xtargetCheck(char_settings) then
        travel.navPause()
        _G.Mob.clearXtarget(class_settings, char_settings)
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
    if travel.invisCheck(char_settings, class_settings, item.invis) then
        travel.invis(class_settings)
    end
    _G.State:setStatusText(string.format("Following %s.", item.npc))
    logger.log_info("\aoFollowing \ag%s\ao.", item.npc)
    if mq.TLO.Spawn("npc " .. item.npc).Distance() ~= nil then
        if mq.TLO.Spawn("npc " .. item.npc).Distance() > 100 then
            logger.log_warn("\ar%s \aois over 100 units away. Moving back to step \ar%s\ao.", item.npc, _G.State.current_step)
            _G.State:handle_step_change(_G.State.current_step - 1)
            return
        end
    end
    if _G.State.group_choice == 1 then
        mq.TLO.Spawn("npc " .. item.npc).DoTarget()
        mq.delay(300)
        mq.cmd('/squelch /afollow')
    elseif _G.State.group_choice == 2 then
        mq.cmdf('/dgga /squelch /target id %s', mq.TLO.Spawn("npc " .. item.npc).ID())
        mq.delay(300)
        mq.cmd('/dgga /squelch /afollow')
    else
        mq.TLO.Spawn("npc " .. item.npc).DoTarget()
        mq.cmdf('/dex %s /squelch /target id %s', _G.State.group_combo[_G.State.group_choice],
            mq.TLO.Spawn("npc " .. item.npc).ID())
        mq.delay(300)
        mq.cmd('/squelch /afollow')
        mq.cmdf('/dex %s /squelch /afollow', _G.State.group_combo[_G.State.group_choice])
    end
    if item.whereX ~= nil then
        local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), item.whereX, item.whereY)
        while distance > 50 do
            if _G.State.should_skip == true then
                if _G.State.group_choice == 1 then
                    mq.cmd('/squelch /afollow off')
                    _G.State.should_skip = false
                    return
                elseif _G.State.group_choice == 2 then
                    mq.cmd('/dgga /squelch /afollow off')
                    _G.State.should_skip = false
                    return
                else
                    mq.cmd('/squelch /afollow off')
                    mq.cmdf('/dex %s /squelch /afollow off', _G.State.group_combo[_G.State.group_choice])
                end
            end
            mq.delay(200)
            distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), item.whereX, item.whereY)
        end
        logger.log_info("\aoWe have reached our destination. Stopping follow.")
        travel.npc_stop_follow()
    end
    travel.looping = true
    if event == true then
        mq.event('follow_event', item.phrase, travel.follow_event)
        while travel.looping == true do
            mq.delay(100)
            mq.doevents()
            if _G.Mob.xtargetCheck(char_settings) then
                mq.cmd('/squelch /afollow off')
                _G.Mob.clearXtarget(class_settings, char_settings)
                mq.TLO.Spawn("npc " .. item.npc).DoTarget()
                mq.delay(300)
                mq.cmd('/squelch /afollow')
            end
        end
        mq.cmd('/squelch /afollow off')
    end
end

function travel.npc_stop_follow(item)
    _G.State:setStatusText(string.format("Stopping autofollow."))
    logger.log_info("\aoStopping autofollow.")
    if _G.State.group_choice == 1 then
        mq.cmd('/squelch /afollow off')
    elseif _G.State.group_choice == 2 then
        mq.cmd('/dgga /squelch /afollow off')
    else
        mq.cmd('/squelch /afollow off')
        mq.cmdf('/dex %s /squelch /afollow off', _G.State.group_combo[_G.State.group_choice])
    end
end

function travel.npc_travel(item, class_settings, ignore_path_check, char_settings)
    ignore_path_check = ignore_path_check or false
    if item.zone == nil then
        if _G.Mob.xtargetCheck(char_settings) then
            travel.navPause()
            _G.Mob.clearXtarget(class_settings, char_settings)
            travel.navUnpause(item)
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
    if travel.invisCheck(char_settings, class_settings, item.invis) then
        travel.invis(class_settings)
    end
    if item.whereX ~= nil then
        travel.loc_travel(item, class_settings, char_settings)
    else
        _G.State:setStatusText(string.format("Waiting for NPC %s.", item.npc))
        local ID = _G.Mob.findNearestName(item.npc, item, class_settings, char_settings)
        travel.general_travel(item, class_settings, char_settings, ID)
    end
end

function travel.portal_set(item)
    _G.State:setStatusText(string.format("Setting portal to %s.", item.zone))
    logger.log_info("\aoSetting portal to \ag%s\ao.", item.zone)
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
    if _G.Mob.xtargetCheck(char_settings) then
        travel.navPause()
        _G.Mob.clearXtarget(class_settings, char_settings)
        travel.navUnpause(item)
    end
    _G.State:setStatusText("Searching for relocation ability/item that is ready.")
    logger.log_info("\aoSearching for a relocation ability/item that is ready.")
    local relocate = 'none'
    relocate = travel.findReadyRelocate()
    mq.delay(50)
    while relocate == 'none' do
        logger.log_info("\aoWaiting for a relocation ability/item to be ready.")
        mq.delay("3s")
        relocate = travel.findReadyRelocate()
    end
    _G.State:setStatusText(string.format("Relocating to %s.", relocate))
    logger.log_info("\aoRelocating to \ag%s\ao.", relocate)
    if _G.State.group_choice == 1 then
        mq.cmdf('/squelch /relocate %s', relocate)
    elseif _G.State.group_choice == 2 then
        mq.cmdf('/dgga /squelch /relocate %s', relocate)
    else
        mq.cmdf('/squelch /relocate %s', relocate)
        mq.cmdf('/dex %s /squelch /relocate %s', _G.State.group_combo[_G.State.group_choice], relocate)
    end
    if _G.Mob.xtargetCheck(char_settings) then
        travel.navPause()
        _G.Mob.clearXtarget(class_settings, char_settings)
        travel.navUnpause(item)
    end
    local loopCount = 0
    while mq.TLO.Me.Casting() == nil do
        loopCount = loopCount + 1
        mq.delay(10)
        if _G.State.should_skip == true then
            travel.navPause()
            _G.State.should_skip = false
            return
        end
        if _G.State.is_paused == true then
            travel.navPause()
            _G.Actions.pauseTask(_G.State:readStatusText())
            travel.navUnpause(item)
        end
        if loopCount >= 200 then
            logger.log_warn("\aoSpent 2 seconds waiting for relocate to \ar%s \aoto cast. Moving on.", relocate)
            break
        end
    end
    loopCount = 0
    while mq.TLO.Me.Casting() ~= nil do
        loopCount = loopCount + 1
        mq.delay(500)
        if _G.State.should_skip == true then
            travel.navPause()
            _G.State.should_skip = false
            return
        end
        if _G.State.is_paused == true then
            travel.navPause()
            _G.Actions.pauseTask(_G.State:readStatusText())
            travel.navUnpause(item)
        end
        --[[if loopCount >= 33 then
            logger.log_warn("\aoSpent 16 seconds waiting for relocate to \ar%s \ao to finish casting. Moving on.", relocate)
            break
        end--]]
    end
    mq.delay("2s")
    if currentZone == mq.TLO.Zone.Name() then
        logger.log_warn("\aoWe are still in \ag%s \aoattempting to relocate again.", currentZone)
        _G.State:handle_step_change(_G.State.current_step)
        return
    end
end

function travel.zone_travel(item, class_settings, char_settings, continue)
    if char_settings.general.returnToBind == true and continue == false then
        _G.State:setStatusText("Returning to bind point.")
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
    if travel.invisCheck(char_settings, class_settings, item.invis) then
        travel.navPause()
        travel.invis(class_settings)
    end
    _G.State:setStatusText(string.format("Traveling to %s.", item.zone))
    logger.log_info("\aoTraveling to \ag%s\ao.", item.zone)
    _G.State.is_traveling = true
    if _G.State.group_choice == 1 then
        mq.cmdf("/squelch /travelto %s", item.zone)
    elseif _G.State.group_choice == 2 then
        mq.cmdf("/dgga /squelch /travelto %s", item.zone)
    else
        mq.cmdf("/squelch /travelto %s", item.zone)
        mq.cmdf('/dex %s /squelch /travelto %s', _G.State.group_combo[_G.State.group_choice], item.zone)
    end
    local loopCount = 0
    _G.State:setLocation(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z())
    --[[_G.State.is_traveling = true
    _G.State.destType = 'ZONE'
    if mq.TLO.Navigation.CurrentPathDistance() ~= nil then
        _G.State.startDist = mq.TLO.Navigation.CurrentPathDistance()
    end--]]
    while mq.TLO.Zone.ShortName() ~= item.zone and mq.TLO.Zone.Name() ~= item.zone do
        if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
            logger.log_error('\arNot in game, closing.')
            mq.exit()
        end
        if mq.TLO.Navigation.Paused() == true then
            travel.navUnpause(item)
        end
        if _G.State.should_skip == true then
            travel.navPause()
            _G.State.should_skip = false
            return
        end
        mq.delay(500)

        if _G.Mob.xtargetCheck(char_settings) then
            travel.navPause()
            _G.Mob.clearXtarget(class_settings, char_settings)
            travel.navUnpause(item)
        end
        if _G.State.is_paused == true then
            travel.navPause()
            _G.Actions.pauseTask(_G.State:readStatusText())
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
        if travel.invisCheck(char_settings, class_settings, item.invis) then
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
                    logger.log_info("\aoTravel stopped. Starting travel to \ag%s \aoagain.", item.zone)
                    if _G.State.group_choice == 1 then
                        mq.cmdf("/squelch /travelto %s", item.zone)
                    elseif _G.State.group_choice == 2 then
                        mq.cmdf("/dgga /squelch /travelto %s", item.zone)
                    else
                        mq.cmdf("/squelch /travelto %s", item.zone)
                        mq.cmdf('/dex %s /squelch /travelto %s', _G.State.group_combo[_G.State.group_choice], item.zone)
                    end
                end
            end
            loopCount = loopCount + 1
        else
            if loopCount == 10 then
                if item.radius == 1 then
                    return
                end
                local temp = _G.State:readStatusText()
                local door = travel.open_door()
                if door == false and _G.State.autosize == true then
                    if _G.State.autosize_self == false then
                        mq.cmd('/autosize self')
                        _G.State.autosize_self = true
                    end
                    if _G.State.autosize_on == false then
                        mq.cmd('/squelch /autosize on')
                        _G.State.autosize_on = true
                        mq.cmdf('/squelch /autosize sizeself %s', _G.State.autosize_sizes[_G.State.autosize_choice])
                    else
                        _G.State.autosize_choice = _G.State.autosize_choice + 1
                        if _G.State.autosize_choice == 6 then _G.State.autosize_choice = 1 end
                        mq.cmdf('/squelch /autosize sizeself %s', _G.State.autosize_sizes[_G.State.autosize_choice])
                    end
                end
                loopCount = 0
                _G.State:setStatusText(temp)
            end
            if dist.GetDistance3D(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z(), _G.State:readLocation()) < 20 then
                loopCount = loopCount + 1
            else
                _G.State:setLocation(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z())
                loopCount = 0
                if _G.State.autosize_on == true then
                    _G.State.autosize_on = false
                    mq.cmd('/squelch /autosize off')
                end
            end
        end
    end
    if _G.State.group_choice == 2 then
        logger.log_info("\aoWaiting for group members to arrive before continuing.")
        while mq.TLO.Group.AnyoneMissing() do
            mq.delay(500)
            if _G.State.should_skip == true then
                _G.State.should_skip = false
                return
            end
        end
        mq.delay("5s")
    end
    if _G.State.group_choice > 2 then
        logger.log_info("\aoWaiting for \ag%s to arrive before continuing.", _G.State.group_combo[_G.State.group_choice])
        while mq.TLO.Group.Member(_G.State.group_combo[_G.State.group_choice]).OtherZone() do
            mq.delay(500)
            if _G.State.should_skip == true then
                _G.State.should_skip = false
                return
            end
        end
        mq.delay("5s")
    end
    _G.State.destType = ''
    _G.State.dest = ''
    _G.State.is_traveling = false
    _G.State.autosize_on = false
    mq.cmd('/squelch /autosize off')
end

return travel
