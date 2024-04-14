local mq              = require('mq')
local manage          = require 'utils/manageautomation'

local inventory       = {}

--- @type number
inventory.slot        = 0
--- @type string
inventory.stored_item = ''

function inventory.tradeskill_window()
    return mq.TLO.Window('TradeskillWnd').Open()
end

function inventory.merchant_window()
    return mq.TLO.Window('MerchantWnd').Open()
end

function inventory.auto_inv()
    if mq.TLO.Cursor() ~= nil then
        State.status = "Moving " .. mq.TLO.Cursor() .. " to inventory"
        Logger.log_info("\aoMoving \ag%s\ao to inventory.", mq.TLO.Cursor())
    else
        return
    end
    mq.delay(200)
    while mq.TLO.Cursor() ~= nil do
        mq.cmd('/squelch /autoinv')
        mq.delay(200)
    end
    mq.delay("1s")
end

function inventory.combine_container(item, class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    State.status = "Preparing combine container (" .. item.what .. ")"
    Logger.log_info("\aoPreparing combine container (\ag%s\ao) for use.", item.what)
    if mq.TLO.InvSlot('pack8').Item.Container() then
        if mq.TLO.InvSlot('pack8').Item.Name() == item.what then
            Logger.log_info("\ag%s \aoalready in slot 8.", item.what)
            inventory.empty_bag(8)
            return
        end
        inventory.empty_bag(8)
        State.bagslot1, State.bagslot2 = inventory.move_bag(8)
    end
    inventory.move_combine_container(8, item.what)
end

function inventory.combine_item(item, class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    State.status = "Moving " .. item.what .. " to combine container"
    Logger.log_info("\aoMoving \ag%s \aoto combine container.", item.what)
    if mq.TLO.FindItem("=" .. item.what)() == nil then
        State.status = "Unable to find item for combine (" .. item.what .. ")"
        Logger.log_error("\aoUnable to find \ar%s \aofor combine.", item.what)
        State.task_run = false
        mq.cmd('/foreground')
        return
    end
    local slot2     = 0
    local itemslot  = mq.TLO.FindItem("=" .. item.what).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. item.what).ItemSlot2() + 1
    mq.cmdf("/squelch /nomodkey /ctrl /itemnotify in pack%s %s leftmouseup", itemslot, itemslot2)
    mq.delay(500)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    for j = mq.TLO.InvSlot('pack8').Item.Container(), 1, -1 do
        if mq.TLO.InvSlot('pack8').Item.Item(j)() == nil then
            slot2 = j
        end
    end
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack8 %s leftmouseup", slot2)
    mq.delay(500)
    while mq.TLO.Cursor() ~= nil do
        mq.delay(100)
    end
    Logger.log_verbose("\aoSuccessfully moved \ag%s \aoto combine container.", item.what)
end

function inventory.combine_do(class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    State.status = "Performing combine"
    Logger.log_info("\aoPerforming combine in container in slot \ag8\ao.")
    mq.cmdf("/squelch /combine pack8")
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
        mq.cmdf("/squelch /combine pack8")
    end
    mq.cmd("/squelch /autoinv")
    while mq.TLO.Cursor() ~= nil do
        mq.cmd("/squelch /autoinv")
        mq.delay(100)
    end
end

function inventory.combine_done(class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    if State.bagslot1 ~= 0 and State.bagslot2 ~= 0 then
        State.status = "Moving container back to slot 8"
        Logger.log_info("\aoRestoring container to slot 8.")
        mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", State.bagslot1, State.bagslot2)
        while mq.TLO.Cursor() == nil do
            mq.delay(100)
        end
        mq.cmd("/squelch /nomodkey /shiftkey /itemnotify pack8 leftmouseup")
        mq.delay(200)
        mq.cmd("/squelch /autoinv")
        State.bagslot1 = 0
        State.bagslot2 = 0
    end
end

function inventory.enviro_combine_container(item)
    State.status = "Moving to " .. item.what
    Logger.log_info("\aoMoving to \ag%s \aoto perform combine.", item.what)
    mq.cmdf("/squelch /itemtarget %s", item.what)
    if mq.TLO.ItemTarget.DisplayName() ~= item.what then
        State.task_run = false
        State.status = "Could not find item: " .. item.what
        mq.cmd('/foreground')
        Logger.log_error("\aoCould not find item \ar%s\ao.", item.what)
        return
    end
    mq.delay(500)
    mq.cmd("/squelch /nav item")
    while mq.TLO.Navigation.Active() do
        mq.delay(500)
    end
    State.status = "Opening " .. item.what .. " window"
    Logger.log_info("\aoOpening \ag%s \aowindow.", item.what)
    mq.cmd("/squelch /click left item")
    mq.delay("5s", inventory.tradeskill_window)
    Logger.log_verbose("\aoClicking experiment button.")
    mq.TLO.Window("TradeskillWnd/COMBW_ExperimentButton").LeftMouseUp()
    mq.delay("1s")
end

function inventory.enviro_combine_item(item)
    State.status = "Moving " .. item.what .. " to combine container slot " .. item.npc
    Logger.log_info("\aoMoving \ag%s \aoto combine container.", item.what)
    if mq.TLO.FindItem("=" .. item.what)() == nil then
        State.status = "Unable to find item for combine (" .. item.what .. ")"
        Logger.log_error("\aoUnable to find \ar%s \aofor combine.", item.what)
        State.task_run = false
        mq.cmd('/foreground')
        return
    end
    local itemslot  = mq.TLO.FindItem("=" .. item.what).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. item.what).ItemSlot2() + 1
    mq.cmdf("/squelch /nomodkey /ctrl /itemnotify in pack%s %s leftmouseup", itemslot, itemslot2)
    mq.delay(500)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf("/squelch /itemnotify enviro%s leftmouseup", item.npc)
    mq.delay(500)
    while mq.TLO.Cursor() ~= nil do
        mq.delay(100)
    end
    Logger.log_verbose("\aoSuccessfully moved \ag%s \aoto combine container in slot \ag%s\ao.", item.what, item.npc)
end

function inventory.enviro_combine_do()
    State.status = "Combining"
    Logger.log_info("\aoPerforming combine in enviromental container.")
    mq.delay("3s")
    mq.TLO.Window("ContainerWindow/Container_Combine").LeftMouseUp()
    mq.delay("1s")
    local i = 0
    while mq.TLO.Cursor() == nil do
        i = i + 1
        State.status = "Combining " .. i
        mq.delay(100)
        mq.TLO.Window("ContainerWindow/Container_Combine").LeftMouseUp()
    end
    inventory.auto_inv()
end

function inventory.equip_item(item)
    State.status = "Equiping " .. item.what
    Logger.log_info('\aoEquiping \ag%s\ao.', item.what)
    mq.delay("1s")
    inventory.slot = mq.TLO.FindItem('=' .. item.what).WornSlot(1)()
    inventory.stored_item = mq.TLO.Me.Inventory(inventory.slot)()
    Logger.log_verbose("\aoUnequiping \ag%s\ao.", inventory.stored_item)
    mq.cmdf("/squelch /itemnotify \"%s\" leftmouseup", item.what)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf('/squelch /itemnotify %s leftmouseup', inventory.slot)
    while mq.TLO.Me.Inventory(inventory.slot)() ~= item.what do
        mq.delay(100)
    end
    mq.cmd('/squelch /autoinv')
    while mq.TLO.Cursor() ~= nil do
        mq.delay(100)
        mq.cmd('/squelch /autoinv')
    end
end

function inventory.restore_item()
    Logger.log_info("\aoReequiping \ag%s\ao.", inventory.stored_item)
    mq.delay("1s")
    mq.cmdf("/squelch /itemnotify \"%s\" leftmouseup", inventory.stored_item)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf('/squelch /itemnotify %s leftmouseup', inventory.slot)
    while mq.TLO.Me.Inventory(inventory.slot)() ~= inventory.stored_item do
        mq.delay(100)
    end
    mq.cmd('/squelch /autoinv')
    while mq.TLO.Cursor() ~= nil do
        mq.delay(100)
        mq.cmd('/squelch /autoinv')
    end
end

function inventory.find_free_slot(exclude_bag)
    exclude_bag = exclude_bag or 15
    Logger.log_verbose("\aoFinding free slot to place item.")
    for i = mq.TLO.Me.NumBagSlots(), 1, -1 do
        if i ~= exclude_bag then
            if mq.TLO.InvSlot('pack' .. i).Item.Container() ~= 0 then
                if mq.TLO.InvSlot('pack' .. i).Item.Container() ~= nil then
                    for j = mq.TLO.InvSlot('pack' .. i).Item.Container(), 1, -1 do
                        if mq.TLO.InvSlot('pack' .. i).Item.Item(j)() == nil then
                            return i, j
                        end
                    end
                else
                    return i, 0
                end
            end
        end
    end
end

function inventory.loot(item, class_settings, char_settings)
    if Mob.xtargetCheck(char_settings) then
        Mob.clearXtarget(class_settings, char_settings)
    end
    State.status = "Looting " .. item.what
    mq.delay("2s")
    local looted = false
    if mq.TLO.AdvLoot.SCount() > 0 then
        for i = 1, mq.TLO.AdvLoot.SCount() do
            if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                mq.cmdf('/squelch /advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                looted = true
                Logger.log_info("\aoAttempting to loot \ag%s\ao.", item.what)
            end
        end
    end
    if mq.TLO.AdvLoot.PCount() > 0 then
        for i = 1, mq.TLO.AdvLoot.PCount() do
            if mq.TLO.AdvLoot.PList(i).Name() == item.what then
                mq.cmdf('/squelch /advloot personal %s loot', i, mq.TLO.Me.DisplayName())
                looted = true
                Logger.log_info("\aoAttempting to loot \ag%s\ao.", item.what)
            end
        end
    end
    mq.delay("1s")
    if mq.TLO.Window('ConfirmationDialogBox').Open() then
        Logger.log_verbose("\aoNo drop confirmation window open.  Clicking yes.")
        mq.TLO.Window('ConfirmationDialogBox/CD_Yes_Button').LeftMouseUp()
        mq.delay("1s")
    end
    if mq.TLO.FindItem("=" .. item.what)() ~= nil then
        Logger.log_info("\aoSuccessfully looted \ag%s\ao.", item.what)
        if item.gotostep ~= nil then
            Logger.log_verbose("\aoAdvancing to step \ar%s\ao.", item.gotostep)
            State.rewound = true
            State.step = item.gotostep
        end
        return
    else
        if looted == true then
            for i = 1, 10 do
                mq.delay(200)
                if mq.TLO.FindItem("=" .. item.what)() ~= nil then
                    if item.gotostep ~= nil then
                        State.step = item.gotostep - 1
                    end
                    return
                end
                if mq.TLO.AdvLoot.PCount() > 0 then
                    for i = 1, mq.TLO.AdvLoot.PCount() do
                        if mq.TLO.AdvLoot.PList(i).Name() == item.what then
                            mq.cmdf('/squelch /advloot personal %s loot', i, mq.TLO.Me.DisplayName())
                            looted = true
                        end
                        mq.delay("1s")
                        if mq.TLO.Window('ConfirmationDialogBox').Open() then
                            Logger.log_verbose("\aoNo drop confirmation window open.  Clicking yes.")
                            mq.TLO.Window('ConfirmationDialogBox/CD_Yes_Button').LeftMouseUp()
                            mq.delay("1s")
                        end
                    end
                end
                if i == 10 then
                    State.task_run = false
                    State.status = "Tried to loot " .. item.what .. "at step " .. State.step .. " but failed!"
                    Logger.log_error("\aoFailed to loot \ar%s \aoat step \ar%s\ao.", item.what, State.step)
                    mq.cmd('/foreground')
                    return
                end
            end
        end
    end
    if item.gotostep ~= nil then
        State.rewound = true
        State.step = item.gotostep
        Logger.log_verbose("\aoAdvancing to step \ar%s\ao.", item.gotostep)
    end
end

function inventory.move_combine_container(slot, container)
    if mq.TLO.FindItem("=" .. container)() == nil then
        State.status = "Unable to find combine container (" .. container .. ")"
        Logger.log_error("\aoUnable to find combine container (\ar%s\ao).", container)
        State.task_run = false
        mq.cmd('/foreground')
        return
    end
    local itemslot = mq.TLO.FindItem("=" .. container).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. container).ItemSlot2() + 1
    Logger.log_info("\aoMoving \ag%s \aoto bag slot \ag%s\ao.", container, slot)
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", itemslot, itemslot2)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify %s leftmouseup", slot + 22)
    mq.delay(250)
    mq.cmdf("/squelch /nomodkey /ctrl /itemnotify %s rightmouseup", slot + 22)
end

function inventory.move_bag(slot)
    local free_pack, free_slot = inventory.find_free_slot(slot)
    Logger.log_info("\aoMoving item from bag slot \ag%s \ao to bag \ag%s\ao slot \ag%s\ao.", slot, free_pack, free_slot)
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify pack%s leftmouseup", slot)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", free_pack, free_slot)
    return free_pack, free_slot
end

function inventory.npc_buy(item, class_settings, char_settings)
    manage.removeInvis()
    State.status = "Buying " .. item.what .. " from " .. item.npc
    Logger.log_info("\aoBuying \ag%s \ao from \ag%s\ao.", item.what, item.npc)
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
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
    end
    mq.TLO.Target.RightClick()
    mq.delay("5s", inventory.merchant_window)
    mq.delay("3s")
    mq.TLO.Merchant.SelectItem("=" .. item.what)
    mq.delay("1s")
    if item.count == nil then
        mq.TLO.Merchant.Buy(1)
    else
        mq.TLO.Merchant.Buy(item.count)
    end
    mq.delay("1s")
    mq.TLO.Window('MerchantWnd').DoClose()
end

function inventory.empty_bag(slot)
    mq.cmd("/squelch /keypress OPEN_INV_BAGS")
    if mq.TLO.InvSlot('pack' .. slot).Item.Container() then
        Logger.log_info("\aoEmptying bag in slot \ag%s\ao.", slot)
        for i = 1, mq.TLO.InvSlot('pack' .. slot).Item.Container() do
            if mq.TLO.InvSlot('pack' .. slot).Item.Item(i)() ~= nil then
                local free_pack, free_slot = inventory.find_free_slot(slot)
                mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", slot, i)
                while mq.TLO.Cursor() == nil do
                    mq.delay(100)
                end
                mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", free_pack, free_slot)
            end
        end
    end
end

return inventory
