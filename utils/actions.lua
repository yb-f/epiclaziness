local mq = require('mq')
local inv = require 'utils/inventory'
local manage = require 'utils/manageautomation'
local travel = require 'utils/travel'

local Actions = {}
local elheader = "\ay[\agEpic Laziness\ay]"
local waiting = false
local gamble_done = false
local forage_trash = { 'Fruit', 'Roots', 'Vegetables', 'Pod of Water', 'Berries', 'Rabbit Meat', 'Fishing Grubs' }
local fishing_trash = { 'Fish Scales', 'Tattered Cloth Sandal', 'Rusty Dagger', "Moray Eel", "Gunthak Gourami",
    "Deep Sea Urchin", "Fresh Fish", "Gunthak Mackerel", "Saltwater Seaweed", "Dark Fish's Scales" }

local function gamble_event(line, arg1)
    if arg1 == '1900' then
        gamble_done = true
    end
end

function Actions.adventure_window()
    return mq.TLO.Window('AdventureRequestWnd').Open()
end

function Actions.adventure_button()
    return mq.TLO.Window('AdventureRequestWnd/AdvRqst_AcceptButton').Enabled()
end

function Actions.adventure_selection()
    if mq.TLO.Window('AdventureRequestWnd/AdvRqst_TypeCombobox').GetCurSel() == 2 then
        return true
    end
    return false
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

function Actions.tradeskill_window()
    return mq.TLO.Window('TradeskillWnd').Open()
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

function Actions.cast_alt(item)
    manage.removeInvis()
    State.status = "Casting " .. item.what
    local ID = mq.TLO.Me.AltAbility(item.what)()
    mq.cmdf('/squelch /alt act %s', ID)
    mq.delay(200)
    while mq.TLO.Me.Casting() ~= nil do
        mq.delay(100)
    end
end

function Actions.farm_check(item, class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    mq.delay("2s")
    local check_list = {}
    local not_found = false
    if item.count ~= nil then
        State.status = "Checking if we have " .. item.count .. " of " .. item.what
        if mq.TLO.FindItemCount("=" .. item.what)() < item.count then
            not_found = true
        end
    else
        State.status = "Checking if we have " .. item.what
        for word in string.gmatch(item.what, '([^|]+)') do
            table.insert(check_list, word)
            for _, check in pairs(check_list) do
                if mq.TLO.FindItem("=" .. check)() == nil then
                    not_found = true
                end
            end
        end
    end
    --if one or more of the items are not present this will be true, so on false advance to the desired step
    if not_found == false then
        State.rewound = true
        State.step = item.gotostep
    else
        --using item.zone as a filler slot for split goto for this function
        State.rewound = true
        State.step = tonumber(item.zone)
    end
end

function Actions.adventure_entrance(item, class_settings, char_settings)
    while string.find(mq.TLO.Window('AdventureRequestWnd/AdvRqst_NPCText').Text(), item.zone) do
        mq.delay(50)
    end
    if string.find(mq.TLO.Window('AdventureRequestWnd/AdvRqst_NPCText').Text(), item.what) then
        travel.loc_travel(item, class_settings, char_settings)
        State.step = item.gotostep
        State.rewound = true
    end
end

function Actions.farm_check_pause(item, class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    State.status = "Checking for " .. item.what
    local check_list = {}
    local not_found = false
    if item.count ~= nil then
        if mq.TLO.FindItemCount("=" .. item.what)() < item.count then
            not_found = true
        end
    else
        for word in string.gmatch(item.what, '([^|]+)') do
            table.insert(check_list, word)
            for _, check in pairs(check_list) do
                if mq.TLO.FindItem("=" .. check)() == nil then
                    not_found = true
                end
            end
        end
    end
    --if one or more of the items are not present this will be true, so on false advance to the desired step
    if not_found == true then
        State.status = item.npc
        State.task_run = false
        mq.cmd('/foreground')
    end
end

function Actions.farm_radius(item, class_settings, char_settings)
    if item.count ~= nil then
        State.status = "Farming for " .. item.what .. " (" .. item.count .. ")"
    else
        State.status = "Farming for " .. item.what
    end
    travel.loc_travel(item, class_settings, char_settings)
    manage.campGroup(item.radius, class_settings, char_settings)
    manage.unpauseGroup(class_settings)
    if item.count ~= nil then
        State.status = "Farming for " .. item.what .. " (" .. item.count .. ")"
    else
        State.status = "Farming for " .. item.what
    end
    local item_list = {}
    local item_status = ''
    local looping = true
    local loop_check = true
    for word in string.gmatch(item.what, '([^|]+)') do
        table.insert(item_list, word)
    end
    if item.count == nil then
        while looping do
            if State.skip == true then
                travel.navPause()
                manage.uncampGroup(class_settings)
                manage.pauseGroup(class_settings)
                State.skip = false
                return
            end
            if State.pause == true then
                manage.pauseGroup(class_settings)
                Actions.pause(State.status)
                manage.unpauseGroup(class_settings)
            end
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
                            mq.cmdf('/squelch /advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                            printf('%s \aoLooting: \ar%s', elheader, name)
                        end
                    end
                end
            end
            mq.delay(250)
            if mq.TLO.AdvLoot.PCount() > 0 then
                for i = 1, mq.TLO.AdvLoot.PCount() do
                    for _, name in pairs(item_list) do
                        if mq.TLO.AdvLoot.PList(i).Name() == name then
                            mq.cmdf('/squelch /advloot personal %s loot', i)
                            printf('%s \aoLooting: \ar%s', elheader, name)
                        end
                    end
                end
            end
            mq.delay("1s")
            if mq.TLO.Window('ConfirmationDialogBox').Open() then
                mq.TLO.Window('ConfirmationDialogBox/CD_Yes_Button').LeftMouseUp()
                mq.delay("1s")
            end
        end
    else
        while mq.TLO.FindItemCount("=" .. item.what)() < item.count do
            if State.skip == true then
                travel.navPause()
                manage.uncampGroup(class_settings)
                manage.pauseGroup(class_settings)
                State.skip = false
                return
            end
            if State.pause == true then
                manage.pauseGroup(class_settings)
                Actions.pause(State.status)
                manage.unpauseGroup(class_settings)
            end
            if mq.TLO.AdvLoot.SCount() > 0 then
                for i = 1, mq.TLO.AdvLoot.SCount() do
                    if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                        mq.cmdf('/squelch /advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                        printf('%s \aoLooting: %s', elheader, item.what)
                    end
                end
            end
            if mq.TLO.AdvLoot.PCount() > 0 then
                for i = 1, mq.TLO.AdvLoot.PCount() do
                    for _, name in pairs(item_list) do
                        if mq.TLO.AdvLoot.PList(i).Name() == name then
                            mq.cmdf('/squelch /advloot personal %s loot', i)
                            printf('%s \aoLooting: %s', elheader, name)
                        end
                    end
                end
            end
            mq.delay("1s")
            if mq.TLO.Window('ConfirmationDialogBox').Open() then
                mq.TLO.Window('ConfirmationDialogBox/CD_Yes_Button').LeftMouseUp()
                mq.delay("1s")
            end
        end
    end
    manage.uncampGroup(class_settings)
    manage.pauseGroup(class_settings)
end

function Actions.fish_farm(item, class_settings, char_settings, once)
    once = once or false
    if item.count ~= nil then
        State.status = "Fishing for " .. item.what .. " (" .. item.count .. ")"
    else
        State.status = "Fishing for " .. item.what
    end
    local weapon1 = mq.TLO.InvSlot('13').Item.Name()
    local slot1, slot2 = 0, 0
    if weapon1 ~= 'Fishing Pole' then
        mq.cmd('/itemnotify "Fishing Pole" leftmouseup')
        while mq.TLO.Cursor() == nil do
            mq.delay(100)
        end
        mq.cmd('/itemnotify 13 leftmouseup')
        mq.delay(500)
        while mq.TLO.Cursor() ~= nil do
            slot1, slot2 = inv.find_free_slot(20)
            mq.cmdf('/itemnotify in pack%s %s leftmouseup', slot1, slot2)
            mq.delay(100)
        end
    end
    if item.count == nil then
        local item_list = {}
        local item_status = ''
        local looping = true
        local loop_check = true
        for word in string.gmatch(item.what, '([^|]+)') do
            table.insert(item_list, word)
        end
        while looping do
            mq.delay(200)
            if State.skip == true then
                State.skip = false
                return
            end
            if State.pause == true then
                Actions.pause(State.status)
            end
            if Mob.xtargetCheck(char_settings) then
                Mob.clearXtarget(class_settings, char_settings)
            end
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
            State.status = "Fishing for " .. item_status
            if loop_check then
                looping = false
            end
            if mq.TLO.Cursor() ~= nil then
                for i, name in pairs(fishing_trash) do
                    if mq.TLO.Cursor.Name() == name then
                        mq.cmd('/squelch /destroy')
                        mq.delay(200)
                    end
                end
                if mq.TLO.Cursor.Name() ~= nil then
                    mq.cmd('/autoinv')
                end
                if once then break end
            end
            mq.delay(100)
            local did_once = false
            if mq.TLO.Me.AbilityReady('Fishing')() then
                if did_once == true then
                    if once then break end
                end
                did_once = true
                mq.cmd('/squelch /doability Fishing')
                mq.delay(500)
            end
        end
    else
    end
    if weapon1 ~= 'Fishing Pole' then
        mq.cmdf('/itemnotify in pack%s %s leftmouseup', slot1, slot2)
        while mq.TLO.Cursor() == nil do
            mq.delay(100)
        end
        mq.cmd('/itemnotify 13 leftmouseup')
        mq.delay(500)
        while mq.TLO.Cursor() ~= nil do
            mq.cmd('/autoinv')
            mq.delay(100)
        end
    end
end

function Actions.forage_farm(item, class_settings, char_settings)
    if item.count == nil then
        State.status = "Foraging for " .. item.what
        local item_list = {}
        local item_status = ''
        local looping = true
        local loop_check = true
        local unpause_automation = false
        for word in string.gmatch(item.what, '([^|]+)') do
            table.insert(item_list, word)
        end
        while looping do
            mq.delay(200)
            if State.skip == true then
                State.skip = false
                return
            end
            if State.pause == true then
                Actions.pause(State.status)
            end
            if Mob.xtargetCheck(char_settings) then
                Mob.clearXtarget(class_settings, char_settings)
            end
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
            State.status = "Foraging for " .. item_status
            if loop_check then
                looping = false
            end
            if mq.TLO.Me.AbilityReady('Forage')() then
                mq.cmd('/squelch /doability Forage')
                mq.delay(500)
                for i, name in pairs(forage_trash) do
                    if mq.TLO.Cursor.Name() == name then
                        mq.cmd('/squelch /destroy')
                        mq.delay(200)
                    end
                end
                if mq.TLO.Cursor.Name() ~= nil then
                    mq.cmd('/autoinv')
                end
            end
        end
    else
        State.status = "Foraging for " .. item.what .. " (" .. item.count .. ")"
    end
end

function Actions.ground_spawn(item, class_settings, char_settings)
    State.status = "Traveling to ground spawn @ " .. item.whereX .. " " .. item.whereY .. " " .. item.whereZ
    travel.loc_travel(item, class_settings, char_settings)
    State.status = "Picking up ground spawn " .. item.what
    mq.cmd("/squelch /itemtarget")
    mq.delay(200)
    mq.cmd("/squelch /click left itemtarget")
    while mq.TLO.Cursor.Name() ~= item.what do
        if State.skip == true then
            State.skip = false
            return
        end
        mq.delay(200)
        mq.cmd("/squelch /itemtarget")
        mq.delay(200)
        mq.cmd("/squelch /click left itemtarget")
    end
    inv.auto_inv()
end

function Actions.ignore_mob(item, class_settings)
    if class_settings.class[mq.TLO.Me.Class()] == 1 then
        mq.cmdf('/squelch /%s ignore "%s"', mq.TLO.Me.Class.ShortName(), item.npc)
    elseif class_settings.class[mq.TLO.Me.Class()] == 2 then
        mq.cmdf('/squelch /rgl pulldeny "%s"', item.npc)
    elseif class_settings.class[mq.TLO.Me.Class()] == 3 then
        mq.TLO.Spawn('npc ' .. item.npc).DoTarget()
        mq.delay(200)
        mq.cmd('/squelch /addignore')
    elseif class_settings.class[mq.TLO.Me.Class()] == 4 then
        mq.cmdf('/squelch /addignore "%s"', item.npc)
    elseif class_settings.class[mq.TLO.Me.Class()] == 5 then
        mq.cmdf('/squelch /addignore "%s"', item.npc)
    end
end

function Actions.pause(status)
    State.status = 'Paused'
    while State.pause == true do
        mq.delay(200)
    end
    State.status = status
    return true
end

function Actions.npc_give(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Giving " .. item.what .. " to " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        if mq.TLO.Spawn(item.npc).Distance() ~= nil then
            if mq.TLO.Spawn(item.npc).Distance() > 100 then
                State.step = State.step - 2
                return
            end
        end
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    if mq.TLO.FindItem('=' .. item.what) == nil then
        State.status = item.what .. " should be handed to " .. item.npc .. "but is not found in inventory."
        State.task_run = false
        mq.cmd('/foreground')
        return
    end
    mq.cmdf('/squelch /nomodkey /shift /itemnotify "%s" leftmouseup', item.what)
    mq.delay("2s", Actions.got_cursor)
    mq.TLO.Target.LeftClick()
    mq.delay("5s", Actions.give_window)
    local looping = true
    local loopCount = 0
    while looping do
        loopCount = loopCount + 1
        mq.delay(200)
        for i = 0, 3 do
            if string.lower(mq.TLO.Window('GiveWnd').Child('GVW_MyItemSlot' .. i).Tooltip()) == string.lower(item.what) then
                looping = false
            end
        end
        if State.skip == true then
            State.skip = false
            return
        end
        if loopCount == 10 then
            State.status = "Failed to give " .. item.what .. " to " .. item.npc .. " on step " .. State.step
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    end
    mq.TLO.Window('GiveWnd').Child('GVW_Give_Button').LeftMouseUp()
    mq.delay(100)
    while mq.TLO.Window('GiveWnd').Open() do
        mq.delay(100)
        if State.skip == true then
            State.skip = false
            return
        end
    end
    mq.delay("1s")
end

function Actions.npc_give_add(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Giving " .. item.what .. " to " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        if mq.TLO.Spawn(item.npc).Distance() ~= nil then
            if mq.TLO.Spawn(item.npc).Distance() > 100 then
                State.step = State.step - 2
                return
            end
        end
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    mq.cmdf('/squelch /itemnotify "%s" leftmouseup', item.what)
    mq.delay("2s", Actions.got_cursor)
    mq.TLO.Target.LeftClick()
    mq.delay("5s", Actions.give_window)
    local looping = true
    while looping do
        for i = 0, 3 do
            if string.lower(mq.TLO.Window('GiveWnd').Child('GVW_MyItemSlot' .. i).Tooltip()) == string.lower(item.what) then
                looping = false
            end
        end
        if State.skip == true then
            State.skip = false
            return
        end
    end
end

function Actions.npc_give_click(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Giving items"
    mq.TLO.Window('GiveWnd').Child('GVW_Give_Button').LeftMouseUp()
    mq.delay(100)
    while mq.TLO.Window('GiveWnd').Open() do
        mq.delay(100)
        if State.skip == true then
            State.skip = false
            return
        end
    end
    mq.delay("1s")
end

function Actions.npc_give_money(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Giving " .. item.what .. "pp to " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        if mq.TLO.Spawn(item.npc).Distance() ~= nil then
            if mq.TLO.Spawn(item.npc).Distance() > 100 then
                State.step = State.step - 2
                return
            end
        end
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
        if State.skip == true then
            State.skip = false
            return
        end
    end
    mq.TLO.Window('InventoryWindow').DoClose()
    mq.delay("1s")
end

function Actions.npc_hail(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Hailing " .. item.npc
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        if mq.TLO.Spawn(item.npc).Distance() ~= nil then
            if mq.TLO.Spawn(item.npc).Distance() > 100 then
                State.step = State.step - 2
                return
            end
        end
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    mq.cmd("/squelch /keypress HAIL")
    mq.delay(300)
end

function Actions.npc_talk(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Talking to " .. item.npc .. " (" .. item.what .. ")"
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
        if mq.TLO.Spawn(item.npc).Distance() ~= nil then
            if mq.TLO.Spawn(item.npc).Distance() > 100 then
                State.step = State.step - 2
                return
            end
        end
        mq.TLO.Spawn(item.npc).DoTarget()
        mq.delay(300)
    end
    mq.cmdf("/say %s", item.what)
    mq.delay(750)
end

function Actions.npc_talk_all(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Talking to " .. item.npc .. " (" .. item.what .. ")"
    manage.groupTalk(item.npc, item.what)
end

function Actions.npc_wait(item, class_settings, char_settings)
    State.status = "Waiting for " .. item.npc .. " (" .. item.waittime .. ")"
    while mq.TLO.Spawn("npc " .. item.npc).ID() == 0 do
        if Mob.xtargetCheck(char_settings) then
            Mob.clearXtarget(class_settings, char_settings)
        end
        if State.skip == true then
            State.skip = false
            return
        end
        if State.pause == true then
            Actions.pause(State.status)
        end
        mq.delay(200)
    end
end

function Actions.npc_wait_despawn(item, class_settings, char_settings)
    State.status = "Waiting for " .. item.npc .. " to despawn (" .. item.waittime .. ")"
    local unpause_automation = false
    while mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 do
        if Mob.xtargetCheck(char_settings) then
            Mob.clearXtarget(class_settings, char_settings)
        end
        if State.skip == true then
            State.skip = false
            return
        end
        if State.pause == true then
            Actions.pause(State.status)
        end
        mq.delay(200)
    end
end

function Actions.pickpocket(item)
    if mq.TLO.Spawn(item.npc).Distance() ~= nil then
        if mq.TLO.Spawn(item.npc).Distance() > 100 then
            State.rewound = true
            State.step = State.step - 1
            return
        end
    end
    mq.TLO.NearestSpawn("npc " .. item.npc).DoTarget()
    local looping = true
    while looping do
        if State.skip == true then
            State.skip = false
            return
        end
        if mq.TLO.Me.AbilityReady('Pick Pockets')() then
            mq.cmd('/squelch /doability Pick Pockets')
            mq.delay(500)
            if mq.TLO.Cursor.Name() == item.what then
                mq.cmd('/autoinv')
                mq.delay(200)
                looping = false
            else
                mq.cmd('/autoinv')
                mq.delay(200)
            end
        end
    end
end

function Actions.pre_farm_check(item, class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    State.status = "Checking for pre-farmable items (" .. item.what .. ")"
    mq.delay("1s")
    local check_list = {}
    local not_found = false
    if item.count ~= nil then
        if mq.TLO.FindItemCount("=" .. item.what)() < item.count then
            not_found = true
        end
    else
        for word in string.gmatch(item.what, '([^|]+)') do
            table.insert(check_list, word)
            for _, check in pairs(check_list) do
                if mq.TLO.FindItem("=" .. check)() == nil then
                    not_found = true
                end
            end
        end
    end
    --if one or more of the items are not present this will be true, so on false advance to the desired step
    if not_found == false then
        State.rewound = true
        State.step = item.gotostep
    end
end

function Actions.rog_gamble(item)
    mq.event('chips', "#*#You now have #1# chips#*#", gamble_event)
    while gamble_done == false do
        if State.skip == true then
            State.skip = false
            return
        end
        Actions.npc_talk(item)
        mq.delay("5s")
        mq.doevents()
    end
    gamble_done = false
end

function Actions.start_adventure(item)
    if mq.TLO.Me.Grouped() == false then
        printf("%s \aoYou must be grouped in order to request an LDON adventure.", elheader)
        State.status = "Please be a part of a group to continue."
        State.task_run = false
        return
    end
    State.status = "Requesting adventure from " .. item.npc
    mq.TLO.Spawn('npc ' .. item.npc).DoTarget()
    mq.delay(200)
    mq.TLO.Target.RightClick()
    mq.delay("5s", Actions.adventure_window)
    mq.TLO.Window('AdventureRequestWnd/AdvRqst_TypeCombobox').Select(2)()
    mq.delay("5s", Actions.adventure_selection)
    mq.TLO.Window('AdventureRequestWnd/AdvRqst_RequestButton').LeftMouseUp()
    mq.delay("5s", Actions.adventure_button)
    mq.TLO.Window('AdventureRequestWnd/AdvRqst_AcceptButton').LeftMouseUp()
    mq.delay(1500)
end

function Actions.wait(item, class_settings, char_settings)
    local waiting = true
    local start_wait = os.clock() * 1000
    local distance = 0
    local unpause_automation = false
    if item.whereZ ~= nil then
        distance = math.abs(mq.TLO.Me.Z() - item.whereZ)
    end
    local loopCount = 0
    while waiting do
        mq.delay(50)
        if Mob.xtargetCheck(char_settings) then
            Mob.clearXtarget(class_settings, char_settings)
        end
        if State.skip == true then
            State.skip = false
            return
        end
        if State.pause == true then
            Actions.pause(State.status)
        end
        mq.delay(200)
        if os.clock() * 1000 > start_wait + tonumber(item.what) then
            waiting = false
        end
        loopCount = loopCount + 1
        if loopCount == 10 and item.whereZ ~= nil then
            if distance - math.abs(mq.TLO.Me.Z() - item.whereZ) < 10 then
                if math.abs(mq.TLO.Me.Z() - item.whereZ) < 1 then
                    break
                end
                State.step = State.step - 3
                return
            else
                distance = math.abs(mq.TLO.Me.Z() - item.whereZ)
                if math.abs(mq.TLO.Me.Z() - item.whereZ) < 5 then
                    break
                end
                loopCount = 0
            end
        end
    end
end

function Actions.wait_event(item)
    mq.event('wait_event', item.what, event_wait)
    waiting = true
    while waiting do
        if State.skip == true then
            mq.unevent('wait_event')
            State.skip = false
            return
        end
        mq.delay(200)
        mq.doevents()
    end
end

return Actions
