local mq           = require('mq')
local manage       = require 'utils/manageautomation'
local inv          = require 'utils/inventory'
local travel       = require 'utils/travel'

local mob          = {}
local searchFilter = ''

local function target_invalid_switch()
    State.cannot_count = State.cannot_count + 1
end

function mob.backstab(item, class_settings, char_settings)
    Logger.log_info("\aoBackstabbing \ag%s\ao.", item.npc)
    local ID = mob.findNearestName(item.npc, item, class_settings, char_settings)
    if mq.TLO.Spawn(item.npc).Distance() ~= nil then
        if mq.TLO.Spawn(item.npc).Distance() > 100 then
            State.rewound = true
            State.step = State.step - 1
            Logger.log_warn("\ar%s \aois over 100 units away. Moving back to step \ar%s\ao.", item.npc, State.step)
            return
        end
    end
    Logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
    mq.TLO.Spawn(item.npc).DoTarget()
    mq.delay(300)
    mq.cmd('/squelch /stick behind')
    mq.delay("2s")
    Logger.log_super_verbose("\aoPerforming backstab.")
    mq.cmd('/squelch /doability backstab')
    mq.delay(500)
end

function mob.xtargetCheck(char_settings)
    Logger.log_super_verbose("\aoPerforming xtarget check.")
    if mq.TLO.Me.XTarget() >= char_settings.general.xtargClear then
        local haterCount = 0
        for i = 1, mq.TLO.Me.XTargetSlots() do
            if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                haterCount = haterCount + 1
            end
        end
        if haterCount >= char_settings.general.xtargClear then
            Logger.log_info("\aoSuffecient auto hater targets found. Calling clear xtarget function.")
            return true
        end
    end
    return false
end

function mob.ph_search(item, class_settings, char_settings)
    if mob.xtargetCheck(char_settings) then
        mob.clearXtarget(class_settings, char_settings)
    end
    State.status = 'Searching for PH for ' .. item.npc
    Logger.log_info("\aoSearching for PH for \ag%s\ao.", item.npc)
    local spawn_search = "npc loc " ..
        item.whereX .. " " .. item.whereY .. " " .. item.whereZ .. " radius " .. item.radius
    if mq.TLO.Spawn(spawn_search).ID() ~= 0 then
        State.rewound = true
        State.step = item.gotostep
        Logger.log_info("\aoPH found. Moving to step: \ar%s\ao.", State.step)
    end
    mq.delay(500)
end

function mob.clearXtarget(class_settings, char_settings)
    Logger.log_info("\aoClearing all auto hater targets from XTarget list.")
    local temp = State.status
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
                        Logger.log_verbose("\aoTargeting XTarget #\ag%s\ao.", i)
                        mq.TLO.Me.XTarget(i).DoTarget()
                        ID = mq.TLO.Me.XTarget(i).ID()
                        State.status = "Clearing XTarget " .. i .. ": " .. mq.TLO.Me.XTarget(i)() .. "(" .. ID .. ")"
                        Logger.log_info("\aoClearing XTarget \ag%s \ao: \ag%s \ao(\ag%s\ao).", i, mq.TLO.Me.XTarget(i)(), ID)
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
                                Logger.log_super_verbose("\aoAttack was off when it should have been on. Turning it back on.")
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
    Logger.log_info("\aoAll auto hater targets cleared from XTarget list.")
    if mq.TLO.Stick.Active() == true then
        mq.cmd('/squelch /stick off')
    end
    State.status = temp
end

local function matchFilters(spawn)
    if string.find(string.lower(spawn.CleanName()), string.lower(searchFilter)) and (spawn.Type() == 'NPC' or spawn.Type() == 'Trigger' or spawn.Type() == 'Chest' or spawn.Type() == 'Corpse') then
        for _, ID in pairs(State.bad_IDs) do
            if spawn.ID() == ID then
                return false
            end
        end
        return true
    end
    return false
end

local function create_spawn_list()
    Logger.log_verbose("\aoCreating spawn list.")
    local mob_list = mq.getFilteredSpawns(matchFilters)
    return mob_list
end

function mob.findNearestName(npc, item, class_settings, char_settings)
    State.status = "Searching for nearest " .. npc
    searchFilter = npc
    Logger.log_info("\aoSearching for nearest \ag%s\ao.", npc)
    local mob_list = create_spawn_list()
    local closest_distance = 25000
    local closest_ID = 0
    local loopCount = 0
    while closest_ID == 0 do
        local foundCorpse = false
        loopCount = loopCount + 1
        if loopCount == 40 then
            loopCount = 0
            mob_list = create_spawn_list()
        end
        mq.delay(50)
        for _, spawn in pairs(mob_list) do
            if mq.TLO.Navigation.PathExists('id ' .. spawn.ID())() then
                if mq.TLO.Navigation.PathLength('id ' .. spawn.ID())() < closest_distance then
                    if spawn.Type() == 'Corpse' then
                        foundCorpse = true
                    else
                        closest_distance = mq.TLO.Navigation.PathLength('id ' .. spawn.ID())()
                        closest_ID = spawn.ID()
                    end
                end
            else
            end
        end
        if State.skip == true then
            return
        end
        if Mob.xtargetCheck(char_settings) then
            Mob.clearXtarget(class_settings, char_settings)
        end
        if State.pause == true then
            Actions.pause(State.status)
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
                inv.loot_check(item)
            end
            if item.named == 1 then
                if closest_ID == 0 then
                    if mq.TLO.Spawn('corpse ' .. item.npc).ID() ~= 0 then
                        Logger.log_warn("\ar%s \aohas already been killed. Advancing to step: \ag%s\ao.", item.npc, item.gotostep)
                        State.step = item.gotostep
                        return nil
                    end
                end
            end
        end
        if item.type == "NPC_SEARCH" then
            if closest_ID == 0 then
                Logger.log_debug("\ar%s \ao not found. Advancing to next step.", item.npc)
                State.step = State.step + 1
                State.rewound = true
                State.skip = true
                return nil
            end
        end
        --[[if closest_ID == 0 then
            Logger.log_warn("\aoUnable to find \ar%s\ao.", npc)
            return nil
        end--]]
    end
    Logger.log_verbose("\aoNearest ID found is \ag%s\ao.", closest_ID)
    return closest_ID or nil
end

function mob.general_search(item, class_settings, char_settings)
    if item.zone == nil then
        if mob.xtargetCheck(char_settings) then
            mob.clearXtarget(class_settings, char_settings)
        end
    end
    State.status = "Searching for " .. item.npc
    Logger.log_info("\aoSearching for \ag%s\ao.", item.npc)
    local looping = true
    local i = 1
    while looping do
        if State.skip == true then
            State.skip = false
            return
        end
        local ID = mob.findNearestName(item.npc, item, class_settings, char_settings)
        if ID ~= nil then
            State.rewound = true
            State.step = item.gotostep
            Logger.log_verbose("\aoFound \ag%s \ao(\ag%s\ao) going to step \ar%s\ao.", item.npc, ID, State.step)
            return
        else
            --Does this ever trigger?
            if item.zone ~= nil then
                State.rewound = true
                State.step = item.backstep
                Logger.log_warn("\aoUnable to find \ar%s \aolooping back to step \ar%s\ao.", item.npc, State.step)
            end
            return
        end
        i = i + 1
    end
end

function mob.npc_damage_until(item)
    State.status = "Damaging " .. item.npc .. " to below " .. item.damage_pct .. "% health"
    Logger.log_info("\aoDamaging \ag%s \ao to below \ag%s%% health\ao.", item.npc, item.damage_pct)
    ID = mq.TLO.Spawn('npc ' .. item.npc).ID()
    if mq.TLO.Spawn(ID).Distance() ~= nil then
        if mq.TLO.Spawn(ID).Distance() > 100 then
            State.rewound = false
            State.step = State.step - 1
            Logger.log_warn("\ar%s \aois over 100 units away. Moving back to step \ar%s\ao.", item.npc, State.step)
            return
        end
    end
    local weapon1 = ''
    local weapon2 = ''
    if item.zone ~= nil then
        if mq.TLO.Me.Level() >= item.maxlevel then
            Logger.log_warn("\aoOur level is \ag%s \aoor higher. Removing weapons before engaging.", item.maxlevel)
            inv.remove_weapons()
        end
    end
    mq.TLO.Spawn(ID).DoTarget()
    mq.cmd("/squelch /stick")
    mq.delay(100)
    mq.cmd("/squelch /attack on")
    local looping = true
    while looping do
        if State.skip == true then
            State.skip = false
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
    Logger.log_info("\aoTarget has either despawned or has decreased below \ag%s \aohealth.", item.damage_pct)
    while mq.TLO.Spawn(ID)() ~= nil do
        Logger.log_verbose("\aoWaiting for \aritem.npc \aoto despawn before continuing.", item.damage_pct)
        mq.delay(50)
    end
    if item.maxlevel ~= nil then
        if mq.TLO.Me.Level() >= item.maxlevel then
            Logger.log_info("\aoReequiping weapons.")
            inv.restore_weapons()
        end
    end
end

function mob.npc_kill(item, class_settings, char_settings, loot)
    manage.removeInvis()
    State.status = "Killing " .. item.npc
    Logger.log_info("\aoKilling \ag%s\ao.", item.npc)
    manage.unpauseGroup(class_settings)
    mq.delay(200)
    local ID = mob.findNearestName(item.npc, item, class_settings, char_settings)
    if mq.TLO.Spawn(ID).Distance() ~= nil then
        if mq.TLO.Spawn(ID).Distance() > 100 then
            State.rewound = true
            State.step = State.step - 1
            Logger.log_warn("\ar%s \aois over 100 units away. Moving back to step \ar%s\ao.", item.npc, State.step)
            return
        end
    end
    if item.what ~= nil then
        inv.loot_check(item)
    end
    if ID ~= nil then
        State.status = "Killing " .. item.npc .. " (" .. ID .. ")"
        Logger.log_info("\aoKilling \ag%s \ao(\ag%s\ao).", item.npc, ID)
        Logger.log_verbose("\aoTargeting \ag%s \ao(\ag%s\ao).", item.npc, ID)
        mq.TLO.Spawn(ID).DoTarget()
    end
    mq.cmd("/squelch /stick")
    mq.delay(100)
    mq.cmd("/squelch /attack on")
    Logger.log_super_verbose("\aoGenerating events to detect unhittable or bugged target.")
    mq.event("cannot_see", "You cannot see your target.", target_invalid_switch)
    mq.event("cannot_cast", "You cannot cast#*#on#*#", target_invalid_switch)
    while mq.TLO.Spawn(ID).Type() == 'NPC' or mq.TLO.Spawn(ID).Type() == 'Chest' do
        mq.doevents()
        if State.skip == true then
            mq.unevent('cannot_see')
            mq.unevent('cannot_cast')
            State.skip = false
            return
        end
        if State.cannot_count > 9 then
            State.cannot_count = 0
            table.insert(State.bad_IDs, ID)
            State.rewound = true
            State.step = State.step - 1
            mq.unevent('cannot_see')
            mq.unevent('cannot_cast')
            Logger.log_warn('\aoUnable to hit this target. Adding \ar%s \aoto bad IDs and moving back to step \ar%s\ao.', ID, State.step)
            return
        end
        if mq.TLO.Target.ID() ~= ID then
            Logger.log_verbose("\aoRetargeting \ag%s\ao.", ID)
            mq.TLO.Spawn(ID).DoTarget()
        end
        if mq.TLO.Me.Combat() == false then
            Logger.log_super_verbose("\aoAttack was off when it should have been on. Turning it back on.")
            mq.cmd("/squelch /attack on")
        end
        mq.delay(200)
    end
    mq.unevent('cannot_see')
    mq.unevent('cannot_cast')
    manage.pauseGroup(class_settings)
    mq.delay("2s")
    if mq.TLO.AdvLoot.SCount() > 0 then
        if loot ~= 'LOOT' then
            Logger.log_info("\aoIgnoring unneeded loot.")
        else
            Logger.log_info("\aoLooting necessary items only.")
        end
    end
    State.cannot_count = 0
    if item.gotostep ~= nil then
        State.rewound = true
        State.step = item.gotostep
        Logger.log_info("\aoSetting step to \ar%s\ao.", State.step)
    end
end

function mob.npc_kill_all(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Killing All " .. item.npc
    Logger.log_info("\aoKilling all \ag%s\ao.", item.npc)
    manage.unpauseGroup(class_settings)
    while true do
        if State.skip == true then
            State.skip = false
            return
        end
        if mq.TLO.Spawn('npc ' .. item.npc).ID() == 0 then
            Logger.log_info("\aoNo \ar%s \ao found.", item.npc)
            break
        end
        mq.delay(500)
        if State.pause == true then
            Actions.pause(State.status)
        end
        local ID = mob.findNearestName(item.npc, item, class_settings, char_settings)
        travel.general_travel(item, class_settings, char_settings, ID)
        if mq.TLO.Spawn(ID).Distance() ~= nil then
            if mq.TLO.Spawn(ID).Distance() > 100 then
                State.step = State.step
                Logger.log_warn("\ar%s \aois over 100 units away. Moving closer.", item.npc)
                return
            end
        end
        Logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
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
            Logger.log_verbose("\aoCasting \ag%s \ao(\ag%s\ao) to pull.", item.zone, altID)
            mq.delay("1s")
        end
        local loopCount = 0
        while mq.TLO.Spawn(ID).Type() == 'NPC' do
            if State.skip == true then
                manage.pauseGroup(class_settings)
                State.skip = false
                return
            end
            mq.delay(200)
            if mq.TLO.Spawn(ID).Distance() ~= nil then
                if mq.TLO.Spawn(ID).Distance() > 100 then
                    State.rewound = true
                    State.step = State.step
                    Logger.log_warn("\ar%s \aois over 100 units away. Moving closer.", item.npc)
                    return
                end
            end
            Logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
            mq.TLO.Spawn(ID).DoTarget()
            loopCount = loopCount + 1
            if loopCount == 20 then
                loopCount = 0
                if item.zone ~= nil then
                    local altID = mq.TLO.Me.AltAbility(item.zone)()
                    mq.cmdf('/squelch /alt act %s', altID)
                    Logger.log_verbose("\aoCasting \ag%s \ao(\ag%s\ao) to pull.", item.zone, altID)
                    mq.delay("1s")
                end
                if mq.TLO.Me.Combat() == false then
                    Logger.log_super_verbose("\aoAttack was off when it should have been on. Turning it back on.")
                    mq.cmd('/squelch /attack on')
                end
            end
        end
        if mq.TLO.FindItem("=" .. item.what)() == nil then
            inv.loot(item, class_settings, char_settings)
            State.status = "Killing All " .. item.npc
        end
    end
end

return mob
