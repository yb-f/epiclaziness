local mq           = require('mq')
local manage       = require('utils/manageautomation')
local inv          = require('utils/inventory')
local travel       = require('utils/travel')
local logger       = require('utils/logger')
local dist         = require 'utils/distance'

local MAX_DISTANCE = 100
local mob          = {}
local searchFilter = ''

local function target_invalid_switch()
    _G.State.cannot_count = _G.State.cannot_count + 1
end

function mob.backstab(item, class_settings, char_settings)
    logger.log_info("\aoBackstabbing \ag%s\ao.", item.npc)
    local ID = mob.findNearestName(item.npc, item, class_settings, char_settings)
    if mq.TLO.Spawn(item.npc).Distance() ~= nil then
        if mq.TLO.Spawn(item.npc).Distance() > MAX_DISTANCE then
            logger.log_warn("\ar%s \aois over %s units away. Moving back to step \ar%s\ao.", item.npc, MAX_DISTANCE, _G.State.current_step)
            _G.State:handle_step_change(_G.State.current_step - 1)
            return
        end
    end
    logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
    mq.TLO.Spawn(item.npc).DoTarget()
    mq.delay(300)
    mq.cmd('/squelch /stick behind')
    mq.delay("2s")
    logger.log_super_verbose("\aoPerforming backstab.")
    mq.cmd('/squelch /doability backstab')
    mq.delay(500)
end

function mob.xtargetCheck(char_settings)
    logger.log_super_verbose("\aoPerforming xtarget check.")
    if mq.TLO.Me.XTarget() then
        if mq.TLO.Me.XTarget() >= char_settings.general.xtargClear then
            local haterCount = 0
            for i = 1, mq.TLO.Me.XTargetSlots() do
                if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                    haterCount = haterCount + 1
                end
            end
            if haterCount >= char_settings.general.xtargClear then
                logger.log_info("\aoSuffecient auto hater targets found. Calling clear xtarget function.")
                return true
            end
        end
    end
    return false
end

function mob.ph_search(item, class_settings, char_settings)
    if mob.xtargetCheck(char_settings) then
        mob.clearXtarget(class_settings, char_settings)
    end
    _G.State:setStatusText(string.format("Searching for PH for %s.", item.npc))
    logger.log_info("\aoSearching for PH for \ag%s\ao.", item.npc)
    local spawn_search = "npc loc " ..
        item.whereX .. " " .. item.whereY .. " " .. item.whereZ .. " radius " .. item.radius
    if mq.TLO.Spawn(spawn_search).ID() ~= 0 then
        logger.log_info("\aoPH found. Moving to step: \ar%s\ao.", _G.State.current_step)
        _G.State:handle_step_change(item.gotostep)
    end
    mq.delay(500)
end

function mob.clearXtarget(class_settings, char_settings)
    logger.log_info("\aoClearing all auto hater targets from XTarget list.")
    local temp = _G.State:readStatusText()
    local max_xtargs = mq.TLO.Me.XTargetSlots()
    local looping = true
    local loopCount = 0
    local i = 0
    local idList = {}
    while looping do
        mq.delay(200)
        i = i + 1
        loopCount = loopCount + 1
        if mq.TLO.Me.XTarget(i)() ~= '' and mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' then
            if mq.TLO.Me.XTarget(i).CleanName() ~= nil then
                if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                    if mq.TLO.Me.XTarget(i).Distance() ~= nil then
                        logger.log_verbose("\aoTargeting XTarget #\ag%s\ao.", i)
                        mq.TLO.Me.XTarget(i).DoTarget()
                        ID = mq.TLO.Me.XTarget(i).ID()
                        _G.State:setStatusText(string.format("Clearing XTarget %s: %s (%s).", i, mq.TLO.Me.XTarget(i)(), ID))
                        logger.log_info("\aoClearing XTarget \ag%s \ao: \ag%s \ao(\ag%s\ao).", i, mq.TLO.Me.XTarget(i)(), ID)
                        manage.unpauseGroup(class_settings)
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
                                logger.log_super_verbose("\aoAttack was off when it should have been on. Turning it back on.")
                                mq.cmd("/squelch /attack on")
                            end
                            mq.delay(200)
                        end
                        i = 0
                        loopCount = 0
                        if i > mq.TLO.Me.XTarget() then
                            i = 0
                        end
                    else
                        i = 0
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
    manage.pauseGroup(class_settings)
    logger.log_info("\aoAll auto hater targets cleared from XTarget list.")
    if mq.TLO.Stick.Active() == true then
        mq.cmd('/squelch /stick off')
    end
    _G.State:setStatusText(temp)
end

local function matchFilters(spawn)
    if string.find(string.lower(spawn.CleanName()), string.lower(searchFilter)) and (spawn.Type() == 'NPC' or spawn.Type() == 'Trigger' or spawn.Type() == 'Chest' or spawn.Type() == 'Corpse' or spawn.Type() == 'Pet') then
        for _, ID in pairs(_G.State.bad_IDs) do
            if spawn.ID() == ID then
                return false
            end
        end
        return true
    end
    return false
end

local function create_spawn_list()
    logger.log_verbose("\aoCreating spawn list.")
    local mob_list = mq.getFilteredSpawns(matchFilters)
    return mob_list
end

function mob.findNearestName(npc, item, class_settings, char_settings)
    _G.State:setStatusText(string.format("Searching for nearest %s.", npc))
    searchFilter = npc
    logger.log_info("\aoSearching for nearest \ag%s\ao.", npc)
    local mob_list = create_spawn_list()
    local closest_distance = 25000
    local closest_ID = 0
    local loopCount = 0
    local looted = false
    while closest_ID == 0 do
        local foundCorpse = false
        loopCount = loopCount + 1
        if loopCount == 10 then
            loopCount = 0
            mob_list = create_spawn_list()
        end
        mq.delay(200)
        for _, spawn in pairs(mob_list) do
            if mq.TLO.Navigation.PathExists('id ' .. spawn.ID())() then
                if mq.TLO.Navigation.PathLength('id ' .. spawn.ID())() < closest_distance then
                    if spawn.Type() == 'Corpse' then
                        foundCorpse = true
                    else
                        if item.whereX then
                            local distance = dist.GetDistance3D(spawn.X(), spawn.Y(), spawn.Z(), item.whereX, item.whereY, item.whereZ)
                            if distance > 50 then
                                logger.log_verbose("\aoFound \ag%s \aobut it is not the proper spawn, continuing search.", item.npc)
                            else
                                closest_distance = mq.TLO.Navigation.PathLength('id ' .. spawn.ID())()
                                closest_ID = spawn.ID()
                            end
                        else
                            closest_distance = mq.TLO.Navigation.PathLength('id ' .. spawn.ID())()
                            closest_ID = spawn.ID()
                        end
                    end
                end
            else
            end
        end
        if _G.State.should_skip == true then
            return
        end
        if mob.xtargetCheck(char_settings) then
            mob.clearXtarget(class_settings, char_settings)
        end
        if _G.State:readPaused() then
            _G.Actions.pauseTask(_G.State:readStatusText())
        end
        if char_settings.general.speedForTravel == true then
            local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
            if speedChar ~= 'none' then
                travel.doSpeed(speedChar, speedSkill)
            end
        end
        if travel.invisCheck(char_settings, class_settings, item.invis) then
            travel.invis(class_settings)
        end
        if item.type == "NPC_KILL" then
            if item.what ~= nil then
                if inv.loot_check(item) then
                    looted = inv.loot(item)
                end
                if inv.item_check(item) == true and looted == false then
                    looted = true
                end
            end
            if looted then
                break
            end
            if item.named == 1 then
                if closest_ID == 0 then
                    if mq.TLO.Spawn('corpse ' .. item.npc).ID() ~= 0 then
                        logger.log_warn("\ar%s \aohas already been killed. Advancing to step: \ag%s\ao.", item.npc, item.gotostep)
                        _G.State:handle_step_change(item.gotostep)
                        return nil
                    end
                end
            end
        end
        if item.type == "NPC_SEARCH" then
            if closest_ID == 0 then
                logger.log_debug("\ar%s \ao not found. Advancing to next step.", item.npc)
                _G.State:handle_step_change(_G.State.current_step + 1)
                return nil
            end
        end
        --[[if closest_ID == 0 then
            logger.log_warn("\aoUnable to find \ar%s\ao.", npc)
            return nil
        end--]]
    end
    logger.log_verbose("\aoNearest ID found is \ag%s\ao.", closest_ID)
    return tostring(closest_ID) or nil
end

function mob.general_search(item, class_settings, char_settings)
    if item.zone == nil then
        if mob.xtargetCheck(char_settings) then
            mob.clearXtarget(class_settings, char_settings)
        end
    end
    _G.State:setStatusText(string.format("Searching for %s.", item.npc))
    logger.log_info("\aoSearching for \ag%s\ao.", item.npc)
    local looping = true
    local i = 1
    while looping do
        if _G.State.should_skip == true then
            _G.State.should_skip = false
            return
        end
        local ID = mob.findNearestName(item.npc, item, class_settings, char_settings)
        if ID ~= nil then
            logger.log_verbose("\aoFound \ag%s \ao(\ag%s\ao) going to step \ar%s\ao.", item.npc, ID, _G.State.current_step)
            _G.State:handle_step_change(item.gotostep)
            return
        else
            --Does this ever trigger?
            if item.zone ~= nil then
                _G.State:handle_step_change(item.backstep)
                logger.log_warn("\aoUnable to find \ar%s \aolooping back to step \ar%s\ao.", item.npc, _G.State.current_step)
            end
            return
        end
        i = i + 1
    end
end

function mob.npc_damage_until(item)
    _G.State:setStatusText(string.format("Damaging %s to below %s% health.", item.npc, item.damage_pct))
    logger.log_info("\aoDamaging \ag%s \aoto below \ag%s%% health\ao.", item.npc, item.damage_pct)
    ID = mq.TLO.Spawn('npc ' .. item.npc).ID()
    if mq.TLO.Spawn(ID).Distance() ~= nil then
        if mq.TLO.Spawn(ID).Distance() > MAX_DISTANCE then
            logger.log_warn("\ar%s \aois over %s units away. Moving back to step \ar%s\ao.", item.npc, MAX_DISTANCE, _G.State.current_step)
            _G.State:handle_step_change(_G.State.current_step - 1)
            return
        end
    end
    local weapon1 = ''
    local weapon2 = ''
    if item.zone ~= nil then
        if mq.TLO.Me.Level() >= item.maxlevel then
            logger.log_warn("\aoOur level is \ag%s \aoor higher. Removing weapons before engaging.", item.maxlevel)
            inv.remove_weapons()
        end
    end
    mq.TLO.Spawn(ID).DoTarget()
    mq.cmd("/squelch /stick")
    mq.delay(100)
    mq.cmd("/squelch /attack on")
    local looping = true
    while looping do
        if _G.State.should_skip == true then
            _G.State.should_skip = false
            return
        end
        if mq.TLO.Spawn(ID)() == nil then
            looping = false
        else
            if mq.TLO.Spawn(ID).PctHPs() < item.damage_pct then
                looping = false
            end
        end
        mq.delay(50)
    end
    mq.cmd("/squelch /attack off")
    logger.log_info("\aoTarget has either despawned or has decreased below \ag%s \aohealth.", item.damage_pct)
    while mq.TLO.Spawn(ID)() ~= nil do
        logger.log_verbose("\aoWaiting for \aritem.npc \aoto despawn before continuing.", item.damage_pct)
        mq.delay(50)
    end
    if item.maxlevel ~= nil then
        if mq.TLO.Me.Level() >= item.maxlevel then
            logger.log_info("\aoReequiping weapons.")
            inv.restore_weapons()
        end
    end
end

function mob.npc_kill(item, class_settings, char_settings)
    manage.removeInvis()
    _G.State:setStatusText(string.format("Killing %s.", item.npc))
    logger.log_info("\aoKilling \ag%s\ao.", item.npc)
    manage.unpauseGroup(class_settings)
    mq.delay(200)
    local ID = mob.findNearestName(item.npc, item, class_settings, char_settings)
    if mq.TLO.Spawn(ID).Distance() ~= nil then
        if mq.TLO.Spawn(ID).Distance() > MAX_DISTANCE then
            logger.log_warn("\ar%s \aois over %s units away. Moving back to step \ar%s\ao.", item.npc, MAX_DISTANCE, _G.State.current_step)
            _G.State:handle_step_change(_G.State.current_step - 1)
            return
        end
    end
    local looted = false
    if item.what ~= nil then
        if inv.loot_check(item) then
            looted = inv.loot(item)
        end
        if inv.item_check(item) == true and looted == false then
            looted = true
        end
    end
    if looted == false then
        if ID ~= nil then
            _G.State:setStatusText(string.format("Killing %s (%s).", item.npc, ID))
            logger.log_info("\aoKilling \ag%s \ao(\ag%s\ao).", item.npc, ID)
            logger.log_verbose("\aoTargeting \ag%s \ao(\ag%s\ao).", item.npc, ID)
            mq.TLO.Spawn(ID).DoTarget()
        end
        mq.cmd("/squelch /stick")
        mq.delay(100)
        mq.cmd("/squelch /attack on")
        logger.log_super_verbose("\aoGenerating events to detect unhittable or bugged target.")
        mq.event("cannot_see", "You cannot see your target.", target_invalid_switch)
        mq.event("cannot_cast", "You cannot cast#*#on#*#", target_invalid_switch)
        while mq.TLO.Spawn(ID).Type() == 'NPC' or mq.TLO.Spawn(ID).Type() == 'Chest' do
            mq.doevents()
            if _G.State.should_skip == true then
                mq.unevent('cannot_see')
                mq.unevent('cannot_cast')
                _G.State.should_skip = false
                return
            end
            if _G.State.cannot_count > 9 then
                _G.State.cannot_count = 0
                table.insert(_G.State.bad_IDs, ID)
                mq.unevent('cannot_see')
                mq.unevent('cannot_cast')
                logger.log_warn('\aoUnable to hit this target. Adding \ar%s \aoto bad IDs and moving back to step \ar%s\ao.', ID, _G.State.current_step)
                _G.State:handle_step_change(_G.State.current_step - 1)
                return
            end
            if mq.TLO.Target.ID() ~= ID then
                logger.log_verbose("\aoRetargeting \ag%s\ao.", ID)
                mq.TLO.Spawn(ID).DoTarget()
            end
            if mq.TLO.Me.Combat() == false then
                logger.log_super_verbose("\aoAttack was off when it should have been on. Turning it back on.")
                mq.cmd("/squelch /attack on")
            end
            mq.delay(200)
            if item.what ~= nil then
                if inv.loot_check(item) then
                    looted = inv.loot(item)
                end
                if inv.item_check(item) == true and looted == false then
                    looted = true
                end
            end
            if looted then
                break
            end
        end
        mq.unevent('cannot_see')
        mq.unevent('cannot_cast')
        manage.pauseGroup(class_settings)
        mq.delay("2s")
        _G.State.cannot_count = 0
    end
    if item.what ~= nil then
        if inv.loot_check(item) then
            looted = inv.loot(item)
        end
        if inv.item_check(item) == true and looted == false then
            looted = true
        end
    end
    if item.gotostep ~= nil then
        _G.State:handle_step_change(item.gotostep)
    end
end

function mob.npc_kill_all(item, class_settings, char_settings)
    manage.removeInvis()
    _G.State:setStatusText(string.format("Killing all %s.", item.npc))
    logger.log_info("\aoKilling all \ag%s\ao.", item.npc)
    manage.unpauseGroup(class_settings)
    while true do
        if _G.State.should_skip == true then
            _G.State.should_skip = false
            return
        end
        if mq.TLO.Spawn('npc ' .. item.npc).ID() == 0 then
            logger.log_info("\aoNo \ar%s \ao found.", item.npc)
            break
        end
        mq.delay(500)
        if _G.State:readPaused() then
            _G.Actions.pauseTask(_G.State:readStatusText())
        end
        local ID = mob.findNearestName(item.npc, item, class_settings, char_settings)
        travel.general_travel(item, class_settings, char_settings, ID, _G.State:readGroupSelection())
        if mq.TLO.Spawn(ID).Distance() ~= nil then
            if mq.TLO.Spawn(ID).Distance() > MAX_DISTANCE then
                logger.log_warn("\ar%s \aois over %s units away. Moving closer.", item.npc, MAX_DISTANCE)
                _G.State:handle_step_change(_G.State.current_step)
                return
            end
        end
        logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
        mq.TLO.Spawn(ID).DoTarget()
        mq.cmd("/squelch /stick")
        mq.delay(100)
        mq.cmd('/squelch /attack on')
        while mq.TLO.Me.Casting() do
            mq.delay(100)
        end
        if item.zone ~= nil then
            local altID = mq.TLO.Me.AltAbility(item.zone)()
            mq.cmdf('/squelch /alt act %s', altID)
            logger.log_verbose("\aoCasting \ag%s \ao(\ag%s\ao) to pull.", item.zone, altID)
            mq.delay("1s")
        end
        local loopCount = 0
        while mq.TLO.Spawn(ID).Type() == 'NPC' do
            if _G.State.should_skip == true then
                manage.pauseGroup(class_settings)
                _G.State.should_skip = false
                return
            end
            mq.delay(200)
            if mq.TLO.Spawn(ID).Distance() ~= nil then
                if mq.TLO.Spawn(ID).Distance() > MAX_DISTANCE then
                    logger.log_warn("\ar%s \aois over %s units away. Moving closer.", item.npc, MAX_DISTANCE)
                    _G.State:handle_step_change(_G.State.current_step)
                    return
                end
            end
            logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
            mq.TLO.Spawn(ID).DoTarget()
            loopCount = loopCount + 1
            if loopCount == 20 then
                loopCount = 0
                if item.zone ~= nil then
                    local altID = mq.TLO.Me.AltAbility(item.zone)()
                    mq.cmdf('/squelch /alt act %s', altID)
                    logger.log_verbose("\aoCasting \ag%s \ao(\ag%s\ao) to pull.", item.zone, altID)
                    mq.delay("1s")
                end
                if mq.TLO.Me.Combat() == false then
                    logger.log_super_verbose("\aoAttack was off when it should have been on. Turning it back on.")
                    mq.cmd('/squelch /attack on')
                end
            end
        end
        if mq.TLO.FindItem("=" .. item.what)() == nil then
            inv.loot(item)
            _G.State:setStatusText(string.format("Killing all %s.", item.npc))
        end
    end
end

return mob
