local mq = require('mq')
local dist = require 'utils/distance'
local inv = require 'utils/inventory'
local manage = require 'utils/manageautomation'

local Actions = {}
local elheader = "\ay[\agEpic Laziness\ay]"

function Actions.give_window()
    return mq.TLO.Window('GiveWnd').Open()
end

function Actions.got_cursor()
    if mq.TLO.Cursor() ~= nil then
        return true
    end
    return false
end

function Actions.zone_travel(item, class_settings)
    if class_settings.general.returnToBind == true then
        State.status = "Returning to bind point"
        manage.gateGroup(State.group_choice)
        mq.delay("15s")
    end
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    State.status = "Traveling to " .. item.zone
    manage.zoneGroup(State.group_choice, item.zone)
end

function Actions.zone_continue_travel(item, class_settings)
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    State.status = "Traveling to " .. item.zone
    manage.zoneGroup(State.group_choice, item.zone)
end

function Actions.npc_travel(item, class_settings)
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    if item.what == nil then
        State.Status = "Waiting for NPC " .. item.npc
        while mq.TLO.Spawn("npc " .. item.npc).ID() == 0 do
            mq.delay(200)
        end
        State.status = "Navigating to " .. item.npc
        if item.whereX == nil then
            manage.navGroup(State.group_choice, item.npc)
        else
            manage.navGroupLoc(State.group_choice, item.npc, item.whereX, item.whereY, item.whereZ)
        end
    else
        if mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 then
            if item.whereX == nil then
                manage.navGroup(State.group_choice, item.npc)
            else
                manage.navGroupLoc(State.group_choice, item.npc, item.whereX, item.whereY, item.whereZ)
            end
        else
            if item.whereX == nil then
                manage.navGroup(State.group_choice, item.what)
            else
                manage.navGroupLoc(State.group_choice, item.what, item.whereX, item.whereY, item.whereZ)
            end
        end
    end
end

function Actions.npc_kill(item, class_settings, loot)
    manage.removeInvis(State.group_choice)
    State.status = "Killing " .. item.npc
    manage.unpauseGroup(State.group_choice, class_settings)
    if item.what == nil then
        mq.delay(200)
        local ID = mq.TLO.Spawn("npc " .. item.npc).ID()
        mq.cmdf("/target id %s", ID)
        mq.delay(100)
        mq.cmd("/keypress AUTOPRIM")
        while mq.TLO.Spawn(ID).Type() == 'NPC' do
            if mq.TLO.Target.ID ~= ID then
                mq.cmdf("/target id %s", ID)
            end
            if mq.TLO.Me.Combat() == false then
                mq.cmd("/keypress AUTOPRIM")
            end
            mq.delay(200)
        end
    else
        if mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 then
            local ID = mq.TLO.Spawn("npc " .. item.npc).ID()
            mq.cmdf("/target id %s", ID)
            mq.cmd("/keypress AUTOPRIM")
            while mq.TLO.Spawn(ID).Type() == 'NPC' do
                if mq.TLO.Target.ID ~= ID then
                    mq.cmdf("/target id %s", ID)
                end
                if mq.TLO.Me.Combat() == false then
                    mq.cmd("/keypress AUTOPRIM")
                end
                mq.delay(200)
            end
        else
            local ID = mq.TLO.Spawn("npc " .. item.what).ID()
            mq.cmdf("/target id %s", ID)
            mq.cmd("/keypress AUTOPRIM")
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
    if item.gotostep ~= nil then
        State.step = item.gotostep - 1
    end
end

function Actions.npc_wait(item)
    State.status = "Waiting for " .. item.npc .. " (" .. item.waittime .. ")"
    while mq.TLO.Spawn("npc " .. item.npc).ID() == 0 do
        mq.delay(200)
    end
end

function Actions.npc_talk(item)
    manage.removeInvis(State.group_choice)
    State.status = "Talking to " .. item.npc .. " (" .. item.what .. ")"
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.cmdf('/target id %s', mq.TLO.Spawn(item.npc).ID())
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

function Actions.npc_give_money(item)
    manage.removeInvis(State.group_choice)
    State.status = "Giving " .. item.what .. "pp to " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.cmdf('/target id %s', mq.TLO.Spawn(item.npc).ID())
        mq.delay(300)
    end
    if mq.TLO.Window('InventoryWindow').Open == false then
        mq.cmd('/keypress INVENTORY')
    end
    mq.delay(200)
    mq.cmd('/notify InventoryWindow IW_Money0 leftmouseup')
    mq.delay(200)
    mq.cmd('/notify QuantityWnd QTYW_slider newvalue 1000')
    mq.delay(200)
    mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
    mq.delay(200)
    mq.cmd('/usetarget')
    mq.delay("5s", Actions.give_window)
    mq.cmd('/notify GiveWnd GVW_Give_Button leftmouseup')
    mq.delay(100)
    while mq.TLO.Window('GiveWnd').Open() do
        mq.delay(100)
    end
    mq.delay("1s")
end

function Actions.npc_give(item)
    manage.removeInvis(State.group_choice)
    State.status = "Giving " .. item.what .. " to " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.cmdf('/target id %s', mq.TLO.Spawn(item.npc).ID())
        mq.delay(300)
    end
    mq.cmdf('/nomodkey /shift /itemnotify "%s" leftmouseup', item.what)
    mq.delay("2s", Actions.got_cursor)
    mq.cmd('/usetarget')
    mq.delay("5s", Actions.give_window)
    mq.cmd('/notify GiveWnd GVW_Give_Button leftmouseup')
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
        mq.cmdf('/target id %s', mq.TLO.Spawn(item.npc).ID())
        mq.delay(300)
    end
    mq.cmdf('/itemnotify "%s" leftmouseup', item.what)
    mq.delay("2s", Actions.got_cursor)
    mq.cmd('/usetarget')
    mq.delay("1s")
end

function Actions.npc_give_click(item)
    manage.removeInvis(State.group_choice)
    State.status = "Giving items"
    mq.cmd('/notify GiveWnd GVW_Give_Button leftmouseup')
    mq.delay(100)
    while mq.TLO.Window('GiveWnd').Open() do
        mq.delay(100)
    end
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

function Actions.npc_stop_follow(item)
    State.status = "Stopping autofollow"
    manage.stopfollowGroup(State.group_choice)
end

function Actions.npc_hail(item)
    manage.removeInvis(State.group_choice)
    State.status = "Hailing " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        mq.cmdf('/target id %s', mq.TLO.Spawn(item.npc).ID())
        mq.delay(300)
    end
    mq.cmd("/keypress HAIL")
    mq.delay(300)
end

function Actions.auto_inv(item)
    State.status = "Moving items to inventory"
    mq.delay(200)
    while mq.TLO.Cursor() ~= nil do
        mq.cmd('/autoinv')
        mq.delay(200)
    end
end

function Actions.pre_farm_check(item)
    State.status = "Checking for pre-farmable items"
    local check_list = {}
    local not_found = false
    for word in string.gmatch(item.what, '([^|]+)') do
        table.insert(check_list, word)
        for check in pairs(check_list) do
            if mq.TLO.FindItem("=" .. check)() == nil then not_found = true end
        end
        --if one or more of the items are not present this will be true, so on false advance to the desired step
        if not_found == false then
            State.step = item.gotostep - 1
        end
    end
end

function Actions.loot(item)
    State.status = "Looting " .. item.what .. " from " .. item.npc
    mq.delay("2s")
    if mq.TLO.AdvLoot.SCount() > 0 then
        for i = 1, mq.TLO.AdvLoot.SCount() do
            if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                mq.cmdf('/advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
            end
        end
    end
    if mq.TLO.FindItem("=" .. item.what) then
        return
    else
        printf("Did not loot %s", item.what)
    end
end

function Actions.combine_container(item)
    State.status = "Preparing combine container"
    if mq.TLO.InvSlot('pack10').Item.Container() then
        inv.empty_bag(10)
        inv.move_bag(10)
        State.bagslot1, State.bagslot2 = inv.move_combine_container(10, item.what)
    end
end

function Actions.combine_item(item)
    State.status = "Moving " .. item.what .. " to combine container"
    inv.move_item_to_combine(item.what, 10)
end

function Actions.combine_do(item)
    State.status = "Combining"
    mq.cmdf("/combine pack10")
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmd("/autoinv")
    --[[State.status = "Moving container back to slot 10"
    mq.cmdf("/nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", State.bagslot1, State.bagslot2)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmd("/nomodkey /shiftkey /itemnotify pack10 leftmouseup")--]]
end

function Actions.farm(item, class_settings)
    manage.removeInvis(State.group_choice)
    State.status = "Farming for " .. item.what
    State.farming = true
    manage.unpauseGroup(State.group_choice, class_settings)
    if mq.TLO.FindItem("=" .. item.what)() ~= nil then return end
    while mq.TLO.FindItem("=" .. item.what)() == nil do
        local ID = 0
        if item.npc == nil then
            ID = mq.TLO.NearestSpawn("npc zradius 50").ID()
        else
            ID = mq.TLO.Spawn("=" .. item.npc).ID()
        end
        mq.cmdf("/nav id %s", ID)
        mq.delay(200)
        while mq.TLO.Nav.Active() do
            if State.nextmob == true then
                break
            end
            mq.delay(200)
        end
        if State.nextmob == true then
            State.nextmob = false
        else
            mq.cmdf("/tar id %s", ID)
            mq.cmd("/stick")
            mq.cmd("/keypress AUTOPRIM")
            while mq.TLO.Spawn(ID).Type() == "NPC" do
                mq.delay(200)
            end
            mq.delay(1000)
            if mq.TLO.AdvLoot.LootInProgress() then
                for i = 1, mq.TLO.AdvLoot.SCount() do
                    if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                        mq.cmdf('/advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                    end
                end
            end
            mq.delay(200)
        end
    end
    manage.pauseGroup(State.group_choice, class_settings)
    State.farming = false
end

function Actions.farm_radius(item, class_settings)
    manage.removeInvis(State.group_choice)
    State.status = "Farming for " .. item.what
    manage.locTravelGroup(State.group_choice, item.whereX, item.whereY, item.whereZ)
    manage.campGroup(State.group_choice, item.radius, class_settings)
    manage.unpauseGroup(State.group_choice, class_settings)
    if item.count == nil then
        while mq.TLO.FindItem("=" .. item.what)() == nil do
            if mq.TLO.AdvLoot.LootInProgress() then
                for i = 1, mq.TLO.AdvLoot.SCount() do
                    if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                        mq.cmdf('/advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                    end
                end
            end
            mq.delay(200)
        end
    else
        while mq.TLO.FindItemCount("=" .. item.what)() < item.count do
            if mq.TLO.AdvLoot.LootInProgress() then
                for i = 1, mq.TLO.AdvLoot.SCount() do
                    if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                        mq.cmdf('/advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                    end
                end
            end
            mq.delay(200)
        end
    end
    manage.uncampGroup(State.group_choice, class_settings)
    manage.pauseGroup(State.group_choice, class_settings)
end

function Actions.ground_spawn(item)
    State.status = "Picking up ground spawn " .. item.what
    Actions.loc_travel(item)
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

function Actions.npc_search(item)
    State.status = "Searching for " .. item.npc
    if mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 then
        State.step = item.gotostep - 1
    end
    mq.delay(500)
end

function Actions.loc_travel(item, class_settings)
    if class_settings.general.invisForTravel == true then
        if item.invis == 1 then
            manage.invis(State.group_choice, class_settings)
        end
    end
    State.status = "Traveling to  " .. item.whereX .. ", " .. item.whereY .. ", " .. item.whereZ
    manage.locTravelGroup(State.group_choice, item.whereX, item.whereY, item.whereZ)
    while mq.TLO.Nav.Active() do
        mq.delay(200)
    end
end

function Actions.face_heading(item)
    State.status = "Facing " .. item.what
    mq.cmdf("/face heading %s", item.what)
    mq.delay(250)
end

function Actions.face_loc(item)
    State.status = "Facing " .. item.whereX .. ", " .. item.whereY .. ", " .. item.whereZ
    manage.faceLoc(State.group_choice, item.whereX, item.whereY, item.whereZ)
    mq.delay(250)
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

function Actions.cast_alt(item)
    manage.removeInvis(State.group_choice)
    State.status = "Casting " .. item.what
    mq.cmdf('/casting "%s"', item.what)
    mq.delay(200)
    while mq.TLO.Me.Casting() ~= nil do
        mq.delay(100)
    end
end

return Actions
