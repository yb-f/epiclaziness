local mq = require('mq')
local manage = require 'utils/manageautomation'
local inv = require 'utils/inventory'
local travel = require 'utils/travel'

local mob = {}

local elheader = "\ay[\agEpic Laziness\ay]"
local searchFilter = ''

local function target_invalid_switch()
    State.cannot_count = State.cannot_count + 1
end

function mob.backstab(item)
    local ID = mob.findNearestName(item)
    mq.TLO.Spawn("id " .. ID).DoTarget()
    mq.cmd('/squelch /stick behind')
    mq.delay("2s")
    mq.cmd('/squelch /doability backstab')
    mq.delay(500)
end

function mob.xtargetCheck(char_settings)
    if mq.TLO.Me.XTarget() >= char_settings.general.xtargClear then
        local haterCount = 0
        for i = 1, mq.TLO.Me.XTargetSlots() do
            if mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' and mq.TLO.Me.XTarget(i)() ~= '' then
                haterCount = haterCount + 1
            end
        end
        if haterCount >= char_settings.general.xtargClear then
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
    local spawn_search = "npc loc " ..
        item.whereX .. " " .. item.whereY .. " " .. item.whereZ .. " radius " .. item.radius
    if mq.TLO.Spawn(spawn_search).ID() ~= 0 then
        State.rewound = true
        State.step = item.gotostep
    end
    mq.delay(500)
end

function mob.clearXtarget(class_settings, char_settings)
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
                        if mq.TLO.Me.XTarget(i).Distance() < 300 and mq.TLO.Me.XTarget(i).LineOfSight() == true then
                            mq.TLO.Me.XTarget(i).DoTarget()
                            ID = mq.TLO.Me.XTarget(i).ID()
                            State.status = "Clearing XTarget " .. i .. ": " .. mq.TLO.Me.XTarget(i)() .. "(" .. ID .. ")"
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
    if mq.TLO.Stick.Active() == true then
        mq.cmd('/squelch /stick off')
    end
    State.status = temp
end

local function matchFilters(spawn)
    if string.find(string.lower(spawn.CleanName()), string.lower(searchFilter)) then
        for ID in pairs(State.bad_IDs) do
            if spawn.ID() == ID then
                return false
            end
        end
        return true
    end
    return false
end

local function create_spawn_list()
    local mob_list = mq.getFilteredSpawns(matchFilters)
    return mob_list
end

function mob.findNearestName(npc)
    State.status = "Searching for nearest " .. npc
    searchFilter = npc
    local mob_list = create_spawn_list()
    local closest_distance = 25000
    local closest_ID = 0
    for _, spawn in pairs(mob_list) do
        if mq.TLO.Navigation.PathExists('id ' .. spawn.ID())() then
            if mq.TLO.Navigation.PathLength('id ' .. spawn.ID())() < closest_distance then
                closest_distance = mq.TLO.Navigation.PathLength('id ' .. spawn.ID())()
                closest_ID = spawn.ID()
            end
        else
        end
    end
    return closest_ID or nil
end

function mob.general_search(item, class_settings, char_settings)
    if mob.xtargetCheck(char_settings) then
        manage.clearXtarget(State.group_choice, class_settings, char_settings)
    end
    State.status = "Searching for " .. item.npc
    local looping = true
    local i = 1
    while looping do
        if State.skip == true then
            State.skip = false
            return
        end
        local ID = mob.findNearestName(item.npc)
        if ID ~= nil then
            State.rewound = true
            State.step = item.gotostep
            return
        else
            if item.zone ~= nil then
                State.rewound = true
                State.step = item.zone
            end
            return
        end
        i = i + 1
    end
end

function mob.npc_damage_until(item)
    State.status = "Damaging " .. item.npc .. " to below " .. item.what .. "% health"
    ID = mq.TLO.Spawn('npc ' .. item.npc).ID()
    if mq.TLO.Spawn(ID).Distance() ~= nil then
        if mq.TLO.Spawn(ID).Distance() > 100 then
            State.step = State.step - 2
            return
        end
    end
    local weapon1 = ''
    local weapon2 = ''
    if item.zone ~= nil then
        if mq.TLO.Me.Level() >= tonumber(item.zone) then
            weapon1 = mq.TLO.InvSlot(13).Item.Name()
            if mq.TLO.InvSlot(14).Item() ~= nil then
                weapon2 = mq.TLO.InvSlot(14).Item.Name()
            else
                weapon2 = 'none'
            end
            mq.cmd('/itemnotify 13 leftmouseup')
            while mq.TLO.Cursor() == nil do
                mq.delay(100)
            end
            local slot1, slot2 = inv.find_free_slot()
            while mq.TLO.Cursor() ~= nil do
                mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", slot1, slot2)
                mq.delay(100)
            end
            if weapon2 ~= 'none' then
                mq.cmd('/itemnotify 14 leftmouseup')
                while mq.TLO.Cursor() == nil do
                    mq.delay(100)
                end
                slot1, slot2 = inv.find_free_slot()
                while mq.TLO.Cursor() ~= nil do
                    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", slot1, slot2)
                    mq.delay(100)
                end
            end
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
            if mq.TLO.Spawn(ID).PctHPs() < 80 then
                looping = false
            end
        end
        mq.delay(50)
    end
    mq.cmd("/squelch /attack off")
    if item.zone ~= nil then
        if mq.TLO.Me.Level() >= tonumber(item.zone) then
            mq.cmdf('/itemnotify "%s" leftmouseup', weapon1)
            while mq.TLO.Cursor() == nil do
                mq.delay(100)
            end
            while mq.TLO.Cursor() ~= nil do
                mq.cmd('/itemnotify 13 leftmouseup')
                mq.delay(100)
            end
            if weapon2 ~= 'none' then
                mq.cmdf('/itemnotify "%s" leftmouseup', weapon2)
                while mq.TLO.Cursor() == nil do
                    mq.delay(100)
                end
                while mq.TLO.Cursor() ~= nil do
                    mq.cmd('/itemnotify 14 leftmouseup')
                    mq.delay(100)
                end
            end
        end
    end
end

function mob.npc_kill(item, class_settings, loot)
    manage.removeInvis()
    State.status = "Killing " .. item.npc
    manage.unpauseGroup(class_settings)
    if item.what == nil then
        mq.delay(200)
        local ID = mob.findNearestName(item.npc)
        if mq.TLO.Spawn(ID).Distance() ~= nil then
            if mq.TLO.Spawn(ID).Distance() > 100 then
                State.rewound = true
                State.step = State.step - 1
                return
            end
        end
        mq.TLO.Spawn(ID).DoTarget()
        mq.cmd("/squelch /stick")
        mq.delay(100)
        mq.cmd("/squelch /attack on")
        mq.event("cannot_see", "You cannot see your target.", target_invalid_switch)
        mq.event("cannot_cast", "You cannot cast#*#on#*#", target_invalid_switch)
        while mq.TLO.Spawn(ID).Type() == 'NPC' do
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
                return
            end
            if mq.TLO.Target.ID() ~= ID then
                mq.TLO.Spawn(ID).DoTarget()
            end
            if mq.TLO.Me.Combat() == false then
                mq.cmd("/squelch /attack on")
            end
            mq.delay(200)
        end
        mq.unevent('cannot_see')
        mq.unevent('cannot_cast')
    else
        if mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 then
            local ID = mob.findNearestName(item.npc)
            if mq.TLO.Spawn(ID).Distance() ~= nil then
                if mq.TLO.Spawn(ID).Distance() > 100 then
                    State.rewound = true
                    State.step = State.step - 1
                    return
                end
            end
            mq.TLO.Spawn(ID).DoTarget()
            mq.cmd("/squelch /stick")
            mq.delay(100)
            mq.cmd("/squelch /attack on")
            while mq.TLO.Spawn(ID).Type() == 'NPC' do
                if State.skip == true then
                    State.skip = false
                    return
                end
                if mq.TLO.Target.ID() ~= ID then
                    mq.TLO.Spawn(ID).DoTarget()
                end
                if mq.TLO.Me.Combat() == false then
                    mq.cmd("/squelch /attack on")
                end
                mq.delay(200)
            end
        else
            local ID = mob.findNearestName(item.what)
            if mq.TLO.Spawn(ID).Distance() ~= nil then
                if mq.TLO.Spawn(ID).Distance() > 100 then
                    State.step = State.step - 2
                    return
                end
            end
            mq.TLO.Spawn(ID).DoTarget()
            mq.cmd("/squelch /stick")
            mq.delay(100)
            mq.cmd("/squelch /attack on")
            while mq.TLO.Spawn(ID).Type() == 'NPC' do
                if State.skip == true then
                    State.skip = false
                    return
                end
                mq.delay(200)
            end
        end
    end
    manage.pauseGroup(class_settings)
    mq.delay("2s")
    if mq.TLO.AdvLoot.SCount() > 0 then
        if loot ~= 'LOOT' then
            printf("%s \aoIgnoring unneeded loot.", elheader)
        else
            printf("%s \aoLooting necessary items only.", elheader)
        end
    end
    State.cannot_count = 0
    if item.gotostep ~= nil then
        State.rewound = true
        State.step = item.gotostep
    end
end

function mob.npc_kill_all(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Killing All " .. item.npc
    manage.unpauseGroup(class_settings)
    local unpause_automation = false
    while true do
        if State.skip == true then
            State.skip = false
            return
        end
        if mq.TLO.Spawn('npc ' .. item.npc).ID() == 0 then
            break
        end
        mq.delay(500)
        if State.pause == true then
            Actions.pause(State.status)
        end
        local ID = mob.findNearestName(item.npc)
        travel.general_travel(item, class_settings, char_settings, ID)
        if mq.TLO.Spawn(ID).Distance() ~= nil then
            if mq.TLO.Spawn(ID).Distance() > 100 then
                State.step = State.step - 1
                return
            end
        end
        mq.TLO.Spawn(ID).DoTarget()
        mq.cmd("/squelch /stick")
        mq.delay(100)
        mq.cmd('/squelch /attack on')
        while mq.TLO.Me.Casting() do
            mq.delay(100)
        end
        if item.zone ~= nil then
            local ID = mq.TLO.Me.AltAbility(item.zone)()
            mq.cmdf('/squelch /alt act %s', ID)
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
                    State.step = State.step - 1
                    return
                end
            end
            mq.TLO.Spawn(ID).DoTarget()
            loopCount = loopCount + 1
            if loopCount == 20 then
                loopCount = 0
                if item.zone ~= nil then
                    local ID = mq.TLO.Me.AltAbility(item.zone)()
                    mq.cmdf('/squelch /alt act %s', ID)
                    mq.delay("1s")
                end
                if mq.TLO.Me.Combat() == false then
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
