local mq = require('mq')
local dist = require 'utils/distance'
local inv = require 'utils/inventory'
local manage = require 'utils/manageautomation'

local Actions = {}
local elheader = "\ay[\agEpic Laziness\ay]"
local waiting = false

local function target_invalid_switch()
    State.cannot_count = State.cannot_count + 1
end

function Actions.give_window()
    return mq.TLO.Window('GiveWnd').Open()
end

function Actions.merchant_window()
    return mq.TLO.Window('MerchantWnd').Open()
end

function Actions.inventory_window()
    return mq.TLO.Window('InventoryWindow').Open()
end

function Actions.got_cursor()
    if mq.TLO.Cursor() ~= nil then
        return true
    end
    return false
end

local function event_wait(line)
    waiting = false
    mq.unevent('wait_event')
end

function Actions.auto_inv(item)
    State.status = "Moving items to inventory"
    mq.delay(200)
    while mq.TLO.Cursor() ~= nil do
        mq.cmd('/autoinv')
        mq.delay(200)
    end
end

function Actions.cast_alt(item)
    manage.removeInvis(State.group_choice)
    State.status = "Casting " .. item.what
    mq.cmdf('/casting "%s"', item.what)
    mq.delay(200)
    while mq.TLO.Me.Casting() ~= nil do
        mq.delay(100)
    end
end

function Actions.combine_container(item)
    State.status = "Preparing combine container"
    if mq.TLO.InvSlot('pack10').Item.Container() then
        inv.empty_bag(10)
        State.bagslot1, State.bagslot2 = inv.move_bag(10)
    end
    inv.move_combine_container(10, item.what)
end

function Actions.combine_do(item)
    State.status = "Combining"
    mq.cmdf("/combine pack10")
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmd("/autoinv")
end

function Actions.combine_done(item)
    State.status = "Moving container back to slot 10"
    mq.cmdf("/nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", State.bagslot1, State.bagslot2)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmd("/nomodkey /shiftkey /itemnotify pack10 leftmouseup")
    mq.delay(200)
    mq.cmd("/autoinv")
end

function Actions.combine_item(item)
    State.status = "Moving " .. item.what .. " to combine container"
    inv.move_item_to_combine(item.what, 10)
end

function Actions.face_heading(item)
    State.status = "Facing heading " .. item.what
    manage.faceHeading(State.group_choice, item.what)
    mq.delay(250)
end

function Actions.face_loc(item)
    State.status = "Facing " .. item.whereX .. ", " .. item.whereY .. ", " .. item.whereZ
    manage.faceLoc(State.group_choice, item.whereX, item.whereY, item.whereZ)
    mq.delay(250)
end

function Actions.farm_check(item)
    State.status = "Checking if we have " .. item.count .. " of " .. item.what
    local not_found = false
    if mq.TLO.FindItem("=" .. item.what)() == nil then
        not_found = true
    else
        if mq.TLO.FindItemCount("=" .. item.what)() < item.count then
            not_found = true
        end
    end
    --if one or more of the items are not present this will be true, so on false advance to the desired step
    if not_found == false then
        State.step = item.gotostep - 1
    else
        --using item.zone as a filler slot for split goto for this function
        State.step = item.zone - 1
    end
end

function Actions.farm_check_pause(item)
    State.status = "Checking for " .. item.what
    if mq.TLO.FindItem("=" .. item.what)() == nil then
        State.status = item.npc
        State.task_run = false
    end
end

function Actions.farm_radius(item, class_settings)
    manage.removeInvis(State.group_choice)
    if item.count ~= nil then
        State.status = "Farming for " .. item.what .. " (" .. item.count .. ")"
    else
        State.status = "Farming for " .. item.what
    end
    manage.locTravelGroup(State.group_choice, item.whereX, item.whereY, item.whereZ)
    manage.campGroup(State.group_choice, item.radius, class_settings)
    manage.unpauseGroup(State.group_choice, class_settings)
    local item_list = {}
    local item_status = ''
    local looping = true
    local loop_check = true
    for word in string.gmatch(item.what, '([^|]+)') do
        table.insert(item_list, word)
    end
    if item.count == nil then
        while looping do
            item_status = ''
            loop_check = true
            local item_remove = 0
            for i, name in pairs(item_list) do
                if mq.TLO.FindItem("=" .. name)() == nil then
                    loop_check = false
                    item_status = item_status .. "|" .. name
                else
                    item_remove = i
                end
            end
            if item_remove > 0 then
                table.remove(item_list, item_remove)
            end
            State.status = "Farming for " .. item_status
            if loop_check then
                looping = false
            end
            if mq.TLO.AdvLoot.SCount() > 0 then
                for i = 1, mq.TLO.AdvLoot.SCount() do
                    for _, name in pairs(item_list) do
                        if mq.TLO.AdvLoot.SList(i).Name() == name then
                            mq.cmdf('/advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                            printf('%s \aoLooting: \ar%s', elheader, name)
                        end
                    end
                end
            end
            if mq.TLO.AdvLoot.PCount() > 0 then
                for i = 1, mq.TLO.AdvLoot.PCount() do
                    for _, name in pairs(item_list) do
                        if mq.TLO.AdvLoot.PList(i).Name() == name then
                            mq.cmdf('/advloot personal %s loot', i)
                            printf('%s \aoLooting: \ar%s', elheader, name)
                        end
                    end
                end
            end
            mq.delay(200)
        end
    else
        while mq.TLO.FindItemCount("=" .. item.what)() < item.count do
            if mq.TLO.AdvLoot.SCount() > 0 then
                for i = 1, mq.TLO.AdvLoot.SCount() do
                    if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                        mq.cmdf('/advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                        printf('%s \aoLooting: %s', elheader, item.what)
                    end
                end
            end
            if mq.TLO.AdvLoot.PCount() > 0 then
                for i = 1, mq.TLO.AdvLoot.PCount() do
                    for _, name in pairs(item_list) do
                        if mq.TLO.AdvLoot.PList(i).Name() == name then
                            mq.cmdf('/advloot personal %s loot', i)
                            printf('%s \aoLooting: %s', elheader, name)
                        end
                    end
                end
            end
            mq.delay(200)
        end
    end
    manage.uncampGroup(State.group_choice, class_settings)
    manage.pauseGroup(State.group_choice, class_settings)
end

function Actions.forward_zone(item, class_settings)
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    State.status = "Traveling forward to zone: " .. item.zone
    manage.forwardZone(State.group_choice, item.zone)
end

function Actions.ground_spawn(item, class_settings)
    State.status = "Picking up ground spawn " .. item.what
    Actions.loc_travel(item, class_settings)
    mq.cmd("/itemtarget")
    mq.delay(200)
    mq.cmd("/click left itemtarget")
    while mq.TLO.Cursor.Name() ~= item.what do
        mq.delay(200)
        mq.cmd("/itemtarget")
        mq.delay(200)
        mq.cmd("/click left itemtarget")
    end
    Actions.auto_inv(item)
end

function Actions.ignore_mob(item, class_settings)
    if class_settings.class[mq.TLO.Me.Class()] == 1 then
        mq.cmdf('/%s ignore "%s"', mq.TLO.Me.Class.ShortName(), item.npc)
    elseif class_settings.class[mq.TLO.Me.Class()] == 2 then
        mq.cmdf('/rgl pulldeny "%s"', item.npc)
    elseif class_settings.class[mq.TLO.Me.Class()] == 3 then
        mq.TLO.Spawn('npc ' .. item.npc).DoTarget()
        mq.delay(200)
        mq.cmd('/addignore')
    elseif class_settings.class[mq.TLO.Me.Class()] == 4 then
        mq.cmdf('/addignore "%s"', item.npc)
    elseif class_settings.class[mq.TLO.Me.Class()] == 5 then
        mq.cmdf('/addignore "%s"', item.npc)
    end
end

function Actions.loc_travel(item, class_settings)
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    State.status = "Traveling to  " .. item.whereX .. ", " .. item.whereY .. ", " .. item.whereZ
    if mq.TLO.Navigation.PathExists('locxyz ' .. item.whereX .. ' ' .. item.whereY .. ' ' .. item.whereZ) == false then
        State.status = "No path exists to loc X: " .. item.whereX .. " Y: " .. item.whereY .. " Z: " .. item.whereZ
        State.task_run = false
        return
    end
    State.traveling = true
    manage.locTravelGroup(State.group_choice, item.whereX, item.whereY, item.whereZ)
    State.traveling = false
end

function Actions.loot(item)
    State.status = "Looting " .. item.what .. " from " .. item.npc
    mq.delay("2s")
    if mq.TLO.AdvLoot.SCount() > 0 then
        for i = 1, mq.TLO.AdvLoot.SCount() do
            if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                mq.cmdf('/advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                printf('%s \aoLooting: \ar%s', elheader, item.what)
            end
        end
    end
    if mq.TLO.AdvLoot.PCount() > 0 then
        for i = 1, mq.TLO.AdvLoot.PCount() do
            if mq.TLO.AdvLoot.PList(i).Name() == item.what then
                mq.cmdf('/advloot personal %s loot', i, mq.TLO.Me.DisplayName())
                printf('%s \aoLooting: \ar%s', elheader, item.what)
            end
        end
    end
    if mq.TLO.FindItem("=" .. item.what)() ~= nil then
        return
    else
        printf("%s \aoDid not loot \ar%s", elheader, item.what)
    end
    if item.gotostep ~= nil then
        State.step = item.gotostep - 1
    end
end

function Actions.no_nav_travel(item, class_settings)
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    State.status = "Traveling forward to  " .. item.whereX .. ", " .. item.whereY .. ", " .. item.whereZ
    manage.noNavTravel(State.group_choice, item.whereX, item.whereY, item.whereZ)
end

function Actions.npc_buy(item)
    manage.removeInvis(State.group_choice)
    State.status = "Buying " .. item.what .. " from " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    mq.delay("5s", Actions.merchant_window)
    mq.delay("1s")
    mq.TLO.Merchant.SelectItem("=" .. item.what)
    mq.delay("1s")
    mq.TLO.Merchant.Buy(1)
    mq.delay("1s")
end

function Actions.npc_follow(item, class_settings)
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    State.status = "Following " .. item.npc
    if item.whereX == nil then
        manage.followGroup(State.group_choice, item.npc)
    else
        manage.followGroupLoc(State.group_choice, item.npc, item.whereX, item.whereY)
    end
end

function Actions.npc_give(item)
    manage.removeInvis(State.group_choice)
    State.status = "Giving " .. item.what .. " to " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    mq.cmdf('/nomodkey /shift /itemnotify "%s" leftmouseup', item.what)
    mq.delay("2s", Actions.got_cursor)
    mq.TLO.Target.LeftClick()
    mq.delay("5s", Actions.give_window)
    mq.TLO.Window('GiveWnd').Child('GVW_Give_Button').LeftMouseUp()
    mq.delay(100)
    while mq.TLO.Window('GiveWnd').Open() do
        mq.delay(100)
    end
    mq.delay("1s")
end

function Actions.npc_give_add(item)
    manage.removeInvis(State.group_choice)
    State.status = "Giving " .. item.what .. " to " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    mq.cmdf('/itemnotify "%s" leftmouseup', item.what)
    mq.delay("2s", Actions.got_cursor)
    mq.TLO.Target.LeftClick()
    mq.delay("1s")
end

function Actions.npc_give_click(item)
    manage.removeInvis(State.group_choice)
    State.status = "Giving items"
    mq.TLO.Window('GiveWnd').Child('GVW_Give_Button').LeftMouseUp()
    mq.delay(100)
    while mq.TLO.Window('GiveWnd').Open() do
        mq.delay(100)
    end
    mq.delay("1s")
end

function Actions.npc_give_money(item)
    manage.removeInvis(State.group_choice)
    State.status = "Giving " .. item.what .. "pp to " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    if mq.TLO.Window('InventoryWindow').Open() == false then
        mq.TLO.Window('InventoryWindow').DoOpen()
    end
    mq.delay("5s", Actions.inventory_window)
    mq.TLO.Window('InventoryWindow').Child('IW_Money0').LeftMouseUp()
    mq.delay(200)
    mq.TLO.Window('QuantityWnd').Child('QTYW_SliderInput').SetText(item.what)
    mq.delay(200)
    mq.TLO.Window('QuantityWnd').Child('QTYW_Accept_Button').LeftMouseUp()
    mq.delay(200)
    mq.TLO.Target.LeftClick()
    mq.delay("5s", Actions.give_window)
    mq.TLO.Window('GiveWnd').Child('GVW_Give_Button').LeftMouseUp()
    mq.delay(100)
    while mq.TLO.Window('GiveWnd').Open() do
        mq.delay(100)
    end
    mq.TLO.Window('InventoryWindow').DoClose()
    mq.delay("1s")
end

function Actions.npc_hail(item)
    manage.removeInvis(State.group_choice)
    State.status = "Hailing " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    mq.cmd("/keypress HAIL")
    mq.delay(300)
end

function Actions.npc_kill(item, class_settings, loot)
    manage.removeInvis(State.group_choice)
    State.status = "Killing " .. item.npc
    manage.unpauseGroup(State.group_choice, class_settings)
    if item.what == nil then
        mq.delay(200)
        local ID = mq.TLO.NearestSpawn("npc " .. item.npc).ID()
        mq.TLO.Spawn(ID).DoTarget()
        mq.cmd("/stick")
        mq.delay(100)
        mq.cmd("/attack on")
        mq.event("cannot_see", "You cannot see your target.", target_invalid_switch)
        mq.event("cannot_cast", "You cannot cast#*#on#*#", target_invalid_switch)
        while mq.TLO.Spawn(ID).Type() == 'NPC' do
            mq.doevents()
            if State.cannot_count > 9 then
                State.cannot_count = 0
                table.insert(State.bad_IDs, ID)
                State.step = State.step - 2
                mq.unevent('cannot_see')
                mq.unevent('cannot_cast')
                return
            end
            if mq.TLO.Target.ID ~= ID then
                mq.TLO.Spawn(ID).DoTarget()
            end
            if mq.TLO.Me.Combat() == false then
                mq.cmd("/attack on")
            end
            mq.delay(200)
        end
        mq.unevent('cannot_see')
        mq.unevent('cannot_cast')
    else
        if mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 then
            local ID = mq.TLO.Spawn("npc " .. item.npc).ID()
            mq.TLO.Spawn(ID).DoTarget()
            mq.cmd("/stick")
            mq.delay(100)
            mq.cmd("/attack on")
            while mq.TLO.Spawn(ID).Type() == 'NPC' do
                if mq.TLO.Target.ID ~= ID then
                    mq.TLO.Spawn(ID).DoTarget()
                end
                if mq.TLO.Me.Combat() == false then
                    mq.cmd("/attack on")
                end
                mq.delay(200)
            end
        else
            local ID = mq.TLO.Spawn("npc " .. item.what).ID()
            mq.TLO.Spawn(ID).DoTarget()
            mq.cmd("/stick")
            mq.delay(100)
            mq.cmd("/attack on")
            while mq.TLO.Spawn(ID).Type() == 'NPC' do
                mq.delay(200)
            end
        end
    end
    manage.pauseGroup(State.group_choice, class_settings)
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
        State.step = item.gotostep - 1
    end
end

function Actions.npc_kill_all(item, class_settings)
    manage.removeInvis(State.group_choice)
    State.status = "Killing All " .. item.npc
    manage.unpauseGroup(State.group_choice, class_settings)
    while true do
        if mq.TLO.Spawn('npc ' .. item.npc).ID() == 0 then
            break
        end
        local ID = mq.TLO.NearestSpawn('npc ' .. item.npc).ID()
        mq.cmdf('/nav id %s', ID)
        while mq.TLO.Navigation.Active() do
            mq.delay(200)
        end
        mq.TLO.Spawn(ID).DoTarget()
        mq.cmd("/stick")
        mq.delay(100)
        mq.cmd('/attack on')
        while mq.TLO.Me.Casting() do
            mq.delay(100)
        end
        if item.zone ~= nil then
            mq.cmdf('/casting "%s"', item.zone)
            mq.delay("1s")
        end
        local loopCount = 0
        while mq.TLO.Spawn(ID).Type() == 'NPC' do
            mq.delay(200)
            mq.TLO.Spawn(ID).DoTarget()
            loopCount = loopCount + 1
            if loopCount == 20 then
                loopCount = 0
                if item.zone ~= nil then
                    mq.cmdf('/casting "%s"', item.zone)
                    mq.delay("1s")
                end
                if mq.TLO.Me.Combat() == false then
                    mq.cmd('/attack on')
                end
            end
        end
        if mq.TLO.FindItem("=" .. item.what)() == nil then
            Actions.loot(item)
            State.status = "Killing All " .. item.npc
        end
    end
end

function Actions.ph_search(item)
    State.status = 'Searching for PH for ' .. item.npc
    local spawn_search = "npc loc " ..
        item.whereX .. " " .. item.whereY .. " " .. item.whereZ .. " radius " .. item.radius
    if mq.TLO.Spawn(spawn_search).ID() ~= 0 then
        State.step = item.gotostep - 1
    end
    mq.delay(500)
end

function Actions.npc_search(item)
    State.status = "Searching for " .. item.npc
    if mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 then
        State.step = item.gotostep - 1
    end
    mq.delay(500)
end

function Actions.npc_stop_follow(item)
    State.status = "Stopping autofollow"
    manage.stopfollowGroup(State.group_choice)
end

function Actions.npc_talk(item)
    manage.removeInvis(State.group_choice)
    State.status = "Talking to " .. item.npc .. " (" .. item.what .. ")"
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    mq.cmdf("/say %s", item.what)
    mq.delay(750)
end

function Actions.npc_talk_all(item)
    manage.removeInvis(State.group_choice)
    State.status = "Talking to " .. item.npc .. " (" .. item.what .. ")"
    manage.groupTalk(State.group_choice, item.npc, item.what)
end

function Actions.npc_travel(item, class_settings)
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    if item.what == nil then
        State.status = "Waiting for NPC " .. item.npc
        local ID = mq.TLO.NearestSpawn(1, "npc " .. item.npc).ID()
        if mq.TLO.Navigation.PathExists('id ' .. ID)() == false then
            table.insert(State.bad_IDs, ID)
        end
        local mob_loop = true
        local loop_count = 1
        while mob_loop do
            mq.delay(200)
            for _, bad_id in pairs(State.bad_IDs) do
                if ID == bad_id then
                    State.nextmob = true
                end
            end
            if State.nextmob == true then
                ID = mq.TLO.NearestSpawn(loop_count + 1, "npc " .. item.npc).ID()
                if mq.TLO.Navigation.PathExists('id ' .. ID)() == false then
                    table.insert(State.bad_IDs, ID)
                end
                State.nextmob = false
                loop_count = loop_count + 1
            else
                break
            end
        end
        while mq.TLO.Spawn("npc " .. item.npc).ID() == 0 do
            if State.skip == true then
                return
            end
            mq.delay(200)
        end
        State.status = "Navigating to " .. item.npc
        if item.whereX == nil then
            manage.navGroup(State.group_choice, item.npc, ID)
        else
            manage.navGroupLoc(State.group_choice, item.npc, item.whereX, item.whereY, item.whereZ)
        end
    else
        if mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 then
            if item.whereX == nil then
                manage.navGroup(State.group_choice, item.npc, 0)
            else
                manage.navGroupLoc(State.group_choice, item.npc, item.whereX, item.whereY, item.whereZ)
            end
        else
            if item.whereX == nil then
                manage.navGroup(State.group_choice, item.what, 0)
            else
                manage.navGroupLoc(State.group_choice, item.what, item.whereX, item.whereY, item.whereZ)
            end
        end
    end
end

function Actions.npc_wait(item)
    State.status = "Waiting for " .. item.npc .. " (" .. item.waittime .. ")"
    while mq.TLO.Spawn("npc " .. item.npc).ID() == 0 do
        mq.delay(200)
    end
end

function Actions.npc_wait_despawn(item)
    State.status = "Waiting for " .. item.npc .. " to despawn (" .. item.waittime .. ")"
    while mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 do
        mq.delay(200)
    end
end

function Actions.open_door(item)
    State.status = "Opening door"
    mq.delay(200)
    mq.cmd("/doortarget")
    mq.delay(200)
    mq.cmd("/click left door")
    mq.delay(200)
end

function Actions.picklock_door(item)
    State.status = "Lockpicking door"
    mq.delay(1500)
    manage.picklockGroup(State.group_choice)
    mq.delay(100)
end

function Actions.portal_set(item)
    mq.cmdf("/portalset %s", item.zone)
    mq.delay(500)
    while mq.TLO.PortalSetter.InProgress() == true do
        mq.delay(200)
    end
end

function Actions.pre_farm_check(item)
    State.status = "Checking for pre-farmable items"
    local check_list = {}
    local not_found = false
    if item.count ~= nil then
        if mq.TLO.FindItemCount("=" .. item.what) < item.count then
            not_found = true
        end
    else
        for word in string.gmatch(item.what, '([^|]+)') do
            table.insert(check_list, word)
            for check in pairs(check_list) do
                if mq.TLO.FindItem("=" .. check)() == nil then
                    not_found = true
                end
            end
        end
    end
    --if one or more of the items are not present this will be true, so on false advance to the desired step
    if not_found == false then
        State.step = item.gotostep - 1
    end
end

function Actions.send_yes(item)
    manage.sendYes(State.group_choice)
end

function Actions.wait_event(item)
    mq.event('wait_event', item.what, event_wait)
    waiting = true
    while waiting do
        mq.delay(200)
        mq.doevents()
    end
end

function Actions.zone_continue_travel(item, class_settings)
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    State.status = "Traveling to " .. item.zone
    State.traveling = true
    manage.zoneGroup(State.group_choice, item.zone)
    State.traveling = false
end

function Actions.zone_travel(item, class_settings)
    if class_settings.general.returnToBind == true then
        State.status = "Returning to bind point"
        while mq.TLO.Zone.ShortName() ~= mq.TLO.Me.BoundLocation('0')() do
            manage.gateGroup(State.group_choice)
            mq.delay("15s")
        end
    end
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    State.status = "Traveling to " .. item.zone
    State.traveling = true
    manage.zoneGroup(State.group_choice, item.zone)
    State.traveling = false
end

return Actions
