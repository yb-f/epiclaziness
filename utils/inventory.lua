local mq                    = require('mq')
local manage                = require('utils/manageautomation')
local logger                = require('utils/logger')
local dist                  = require 'utils/distance'
local MAX_DISTANCE          = 100
local inventory             = {}

--- @type number
inventory.slot              = 0
--- @type string
inventory.stored_item       = ''

inventory.stored_item_table = {}
inventory.weapon1           = {
    ['name']  = '',
    ['slot1'] = 0,
    ['slot2'] = 0
}
inventory.weapon2           = {
    ['name']  = '',
    ['slot1'] = 0,
    ['slot2'] = 0
}

function inventory.tradeskill_window()
    return mq.TLO.Window('TradeskillWnd').Open()
end

function inventory.merchant_window()
    return mq.TLO.Window('MerchantWnd').Open()
end

function inventory.auto_inv(item)
    if mq.TLO.Cursor() ~= nil then
        _G.State:setStatusText(string.format("Moving %s to inventory.", mq.TLO.Cursor()))
        logger.log_info("\aoMoving \ag%s\ao to inventory.", mq.TLO.Cursor())
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

function inventory.find_best_bag_slot(item)
    _G.State.combineSlot = 0
    logger.log_info("\aoFinding best bag slot for combine container.")
    local bagSlots = mq.TLO.Me.NumBagSlots()
    local freeSlots = mq.TLO.Me.FreeInventory()
    local mySlot = 0
    local lowestItems = 99
    if freeSlots < 10 then
        logger.log_warn("\aoYou have \ag%s \ao free inventory slots. This may cause issues with the combine.")
    end
    for i = 1, bagSlots do
        if mq.TLO.Me.Inventory(i + 22).Name() == item.what then
            mySlot = i
            break
        end
        if mq.TLO.Me.Inventory(i + 22).Container() == 0 then
            mySlot = i
            break
        end
        if mq.TLO.Me.Inventory(i + 22).Items() ~= nil then
            if lowestItems == 99 then
                lowestItems = mq.TLO.Me.Inventory(i + 22).Items()
                mySlot = i
            elseif mq.TLO.Me.Inventory(i + 22).Items() < lowestItems then
                lowestItems = mq.TLO.Me.Inventory(i + 22).Items()
                mySlot = i
            end
        end
    end
    _G.State.combineSlot = mySlot
    return mySlot
end

function inventory.loot_check(item)
    logger.log_verbose("\aoChecking if \ag%s \aois in the loot window.", item.what)
    if mq.TLO.AdvLoot.SCount() > 0 then
        for i = 1, mq.TLO.AdvLoot.SCount() do
            if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                return true
            end
        end
    elseif mq.TLO.AdvLoot.PCount() > 0 then
        for i = 1, mq.TLO.AdvLoot.PCount() do
            if mq.TLO.AdvLoot.PList(i).Name() == item.what then
                return true
            end
        end
    end
    return false
end

function inventory.combine_container(item, class_settings, char_settings)
    if _G.Mob.xtargetCheck(char_settings) then
        _G.Mob.clearXtarget(class_settings, char_settings)
    end
    _G.State:setStatusText(string.format("Preparing combine container (%s).", item.what))
    logger.log_info("\aoPreparing combine container (\ag%s\ao) for use.", item.what)
    local mySlot = inventory.find_best_bag_slot(item)
    logger.log_debug("\aoSlot \ag%s \aochosen.", mySlot)
    if mq.TLO.Me.Inventory('pack' .. mySlot).Container() then
        if mq.TLO.Me.Inventory('pack' .. mySlot).Name() == item.what then
            logger.log_info("\ag%s \aoalready in slot \ag%s.", item.what, mySlot)
            inventory.empty_bag(mySlot)
            return
        end
        inventory.empty_bag(mySlot)
        _G.State.bagslot1, _G.State.bagslot2 = inventory.move_bag(mySlot)
    end
    inventory.move_combine_container(mySlot, item.what)
    inventory.empty_bag(mySlot)
end

function inventory.find_duplicate_item(item, slot)
    for i = 1, mq.TLO.Me.NumBagSlots() do
        if i ~= slot then
            if mq.TLO.Me.Inventory('pack' .. i).Container() ~= nil then
                if mq.TLO.Me.Inventory('pack' .. i).Name() == item then
                    return i, 0
                end
                if mq.TLO.Me.Inventory('pack' .. i).Container() ~= 0 then
                    for j = mq.TLO.Me.Inventory('pack' .. i).Container(), 1, -1 do
                        if mq.TLO.Me.Inventory('pack' .. i).Item(j)() == item then
                            return i, j
                        end
                    end
                end
            end
        end
    end
    return 0, 0
end

function inventory.combine_item(item, class_settings, char_settings, slot)
    if _G.Mob.xtargetCheck(char_settings) then
        _G.Mob.clearXtarget(class_settings, char_settings)
    end
    _G.State:setStatusText(string.format("Moving %s to combine container.", item.what))
    logger.log_info("\aoMoving \ag%s \aoto combine container.", item.what)
    if mq.TLO.FindItem("=" .. item.what)() == nil then
        _G.State:setStatusText(string.format("Unable to find item for combine (%s)", item.what))
        logger.log_error("\aoUnable to find \ar%s \aofor combine.", item.what)
        _G.State:setTaskRunning(false)
        mq.cmd('/foreground')
        return
    end
    local slot2     = 0
    local itemslot  = mq.TLO.FindItem("=" .. item.what).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. item.what).ItemSlot2() + 1
    if itemslot == slot and item.count >= 2 then
        itemslot, itemslot2 = inventory.find_duplicate_item(item.what, slot)
        if itemslot == 0 and itemslot2 == 0 then
            _G.State:setStatusText(string.format("Unable to find item for combine (%s).", item.what))
            logger.log_error("\aoUnable to find \ar%s \aofor combine.", item.what)
            _G.State:setTaskRunning(false)
            mq.cmd('/foreground')
            return
        end
    end
    mq.cmdf("/squelch /nomodkey /ctrl /itemnotify in pack%s %s leftmouseup", itemslot, itemslot2)
    mq.delay(500)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmd("/keypress OPEN_INV_BAGS")
    if mq.TLO.Me.Inventory('pack' .. slot).Container() ~= nil then
        for j = mq.TLO.Me.Inventory('pack' .. slot).Container(), 1, -1 do
            if mq.TLO.Me.Inventory('pack' .. slot).Item(j)() == nil then
                slot2 = j
            end
        end
    else
        slot2 = 0
    end
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", slot, slot2)
    mq.delay(500)
    while mq.TLO.Cursor() ~= nil do
        mq.delay(100)
    end
    logger.log_verbose("\aoSuccessfully moved \ag%s \aoto combine container.", item.what)
end

function inventory.combine_do(item, class_settings, char_settings, slot)
    if _G.Mob.xtargetCheck(char_settings) then
        _G.Mob.clearXtarget(class_settings, char_settings)
    end
    _G.State:setStatusText("Performing combine.")
    logger.log_info("\aoPerforming combine in container in slot \ag%s\ao.", slot)
    mq.cmdf("/squelch /combine pack%s", slot)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
        mq.cmdf("/squelch /combine pack%s", slot)
    end
    mq.cmd("/squelch /autoinv")
    while mq.TLO.Cursor() ~= nil do
        mq.cmd("/squelch /autoinv")
        mq.delay(100)
    end
end

function inventory.combine_done(item, class_settings, char_settings)
    if _G.Mob.xtargetCheck(char_settings) then
        _G.Mob.clearXtarget(class_settings, char_settings)
    end
    if _G.State.bagslot1 ~= 0 and _G.State.bagslot2 ~= 0 then
        _G.State:setStatusText("Moving container back to previous slot.")
        logger.log_info("\aoRestoring container to previous slot.")
        mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", _G.State.bagslot1, _G.State.bagslot2)
        while mq.TLO.Cursor() == nil do
            mq.delay(100)
        end
        mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify pack%s leftmouseup", _G.State.combineSlot)
        mq.delay(200)
        mq.cmd("/squelch /autoinv")
        _G.State.bagslot1 = 0
        _G.State.bagslot2 = 0
    end
end

function inventory.enviro_combine_container(item)
    _G.State:setStatusText(string.format("Moving to %s.", item.what))
    logger.log_info("\aoMoving to \ag%s \aoto perform combine.", item.what)
    mq.cmdf("/squelch /itemtarget %s", item.what)
    if mq.TLO.ItemTarget.DisplayName() ~= item.what then
        _G.State:setTaskRunning(false)
        _G.State:setStatusText(string.format("Could not find item: %s.", item.what))
        mq.cmd('/foreground')
        logger.log_error("\aoCould not find item \ar%s\ao.", item.what)
        return
    end
    mq.delay(500)
    local y = mq.TLO.ItemTarget.Y()
    local x = mq.TLO.ItemTarget.X()
    local z = mq.TLO.ItemTarget.Z()
    if dist.GetDistance3D(x, y, z, mq.TLO.ItemTarget.X(), mq.TLO.ItemTarget.Y(), mq.TLO.ItemTarget.Z()) > 20 then
        mq.cmd("/squelch /nav item")
        local tempString = string.format("loc %s %s %s", y, x, z)
        _G.State.startDist = mq.TLO.Navigation.PathLength(tempString)()
        _G.State.destType = 'loc'
        _G.State.dest = string.format("%s %s %s", y, x, z)
        while mq.TLO.Navigation.Active() do
            mq.delay(500)
        end
    end
    mq.cmd("/squelch /nav item")
    local tempString = string.format("loc %s %s %s", y, x, z)
    _G.State.startDist = mq.TLO.Navigation.PathLength(tempString)()
    _G.State.destType = 'loc'
    _G.State.dest = string.format("%s %s %s", y, x, z)
    while mq.TLO.Navigation.Active() do
        mq.delay(500)
    end
    _G.State:setStatusText(string.format("Opening %s window.", item.what))
    logger.log_info("\aoOpening \ag%s \aowindow.", item.what)
    mq.cmd("/squelch /click left item")
    mq.delay("5s", inventory.tradeskill_window)
    logger.log_verbose("\aoClicking experiment button.")
    mq.TLO.Window("TradeskillWnd/COMBW_ExperimentButton").LeftMouseUp()
    mq.delay("1s")
    while mq.TLO.Window("TradeskillWnd").Open() do
        mq.TLO.Window("TradeskillWnd/COMBW_ExperimentButton").LeftMouseUp()
        mq.delay("1s")
    end
end

function inventory.enviro_combine_item(item)
    _G.State:setStatusText(string.format("Moving %s to combine container slot %s.", item.what, item.enviroslot))
    logger.log_info("\aoMoving \ag%s \aoto combine container.", item.what)
    if mq.TLO.FindItem("=" .. item.what)() == nil then
        _G.State:setStatusText(string.format("Unable to find item for combine (%s).", item.what))
        logger.log_error("\aoUnable to find \ar%s \aofor combine.", item.what)
        _G.State:setTaskRunning(false)
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
    mq.cmdf("/squelch /itemnotify enviro%s leftmouseup", item.enviroslot)
    mq.delay(500)
    while mq.TLO.Cursor() ~= nil do
        mq.delay(100)
    end
    logger.log_verbose("\aoSuccessfully moved \ag%s \aoto combine container in slot \ag%s\ao.", item.what, item.enviroslot)
end

function inventory.enviro_combine_do(item)
    _G.State:setStatusText("Combining.")
    logger.log_info("\aoPerforming combine in enviromental container.")
    mq.delay("3s")
    mq.TLO.Window("ContainerWindow/Container_Combine").LeftMouseUp()
    mq.delay("1s")
    local i = 0
    while mq.TLO.Cursor() == nil do
        i = i + 1
        _G.State:setStatusText(string.format("Combining %s.", i))
        mq.delay(100)
        mq.TLO.Window("ContainerWindow/Container_Combine").LeftMouseUp()
    end
    inventory.auto_inv()
end

function inventory.equip_item(item)
    if item.count == nil then
        _G.State:setStatusText(string.format("Equiping %s.", item.what))
        logger.log_info('\aoEquiping \ag%s\ao.', item.what)
        mq.delay("1s")
        inventory.slot = mq.TLO.FindItem('=' .. item.what).WornSlot(1)()
        logger.log_verbose("\aoUnequiping slot \ag%s\ao.", inventory.slot)
        inventory.stored_item = mq.TLO.Me.Inventory(inventory.slot)()
        logger.log_verbose("\aoUnequiping \ag%s\ao.", inventory.stored_item)
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
    else
        _G.State:setStatusText(string.format("Equiping %s (%s).", item.what, item.enviroslot))
        logger.log_info('\aoEquiping \ag%s\ao(\ag%s\ao).', item.what, item.enviroslot)
        mq.delay("1s")
        inventory.stored_item_table[item.count] = {}
        inventory.stored_item_table[item.count].slot = item.enviroslot
        inventory.stored_item_table[item.count].stored_item = mq.TLO.Me.Inventory(item.enviroslot)()
        logger.log_verbose("\aoUnequiping \ag%s\ao.", inventory.stored_item_table[item.count].stored_item)
        mq.cmdf("/squelch /itemnotify \"%s\" leftmouseup", item.what)
        while mq.TLO.Cursor() == nil do
            mq.delay(100)
        end
        mq.cmdf('/squelch /itemnotify %s leftmouseup', item.enviroslot)
        while mq.TLO.Me.Inventory(item.enviroslot)() ~= item.what do
            mq.delay(100)
        end
        mq.cmd('/squelch /autoinv')
        while mq.TLO.Cursor() ~= nil do
            mq.delay(100)
            mq.cmd('/squelch /autoinv')
        end
    end
end

function inventory.restore_item(item)
    if item.count == nil then
        logger.log_info("\aoReequiping \ag%s\ao.", inventory.stored_item)
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
    else
        logger.log_info("\aoReequiping \ag%s\ao (\ag%s\ao).", inventory.stored_item_table[item.count].stored_item, inventory.stored_item_table[item.count].slot)
        mq.delay("1s")
        mq.cmdf("/squelch /itemnotify \"%s\" leftmouseup", inventory.stored_item_table[item.count].stored_item)
        while mq.TLO.Cursor() == nil do
            mq.delay(100)
        end
        mq.cmdf('/squelch /itemnotify %s leftmouseup', inventory.stored_item_table[item.count].slot)
        while mq.TLO.Me.Inventory(inventory.stored_item_table[item.count].slot)() ~= inventory.stored_item_table[item.count].stored_item do
            mq.delay(100)
        end
        mq.cmd('/squelch /autoinv')
        while mq.TLO.Cursor() ~= nil do
            mq.delay(100)
            mq.cmd('/squelch /autoinv')
        end
    end
end

function inventory.clear_stored_items(item)
    inventory.stored_item_table = {}
end

function inventory.pickup_key(item)
    mq.cmdf("/squelch /itemnotify \"%s\" leftmouseup", item.what)
end

function inventory.remove_weapons(item)
    _G.State:setStatusText("Removing weapons.")
    logger.log_info("\aoRemoving weapons.")
    inventory.weapon1.name = mq.TLO.InvSlot(13).Item.Name()
    if mq.TLO.InvSlot(14).Item() ~= nil then
        inventory.weapon2.name = mq.TLO.InvSlot(14).Item.Name()
    else
        inventory.weapon2.name = 'none'
    end
    inventory.weapon1.slot1, inventory.weapon1.slot2 = inventory.find_free_slot()
    mq.cmd('/itemnotify 13 leftmouseup')
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    while mq.TLO.Cursor() ~= nil do
        mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", inventory.weapon1.slot1, inventory.weapon1.slot2)
        mq.delay(100)
    end
    if inventory.weapon2.name ~= 'none' then
        inventory.weapon2.slot1, inventory.weapon2.slot2 = inventory.find_free_slot()
        mq.cmd('/itemnotify 14 leftmouseup')
        while mq.TLO.Cursor() == nil do
            mq.delay(100)
        end
        while mq.TLO.Cursor() ~= nil do
            mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", inventory.weapon2.slot1, inventory.weapon2.slot2)
            mq.delay(100)
        end
    end
end

function inventory.restore_weapons()
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", inventory.weapon1.slot1, inventory.weapon1.slot2)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    while mq.TLO.Cursor() == inventory.weapon1.name do
        mq.cmd('/itemnotify 13 leftmouseup')
        mq.delay(100)
    end
    if mq.TLO.Me.Inventory(13).Name() ~= inventory.weapon1.name then
        logger.log_warn("\aoThe main hand weapon does not seem to have been properly restored.")
    end
    mq.cmdf("/squelch /autoinv")
    if inventory.weapon2.name ~= 'none' then
        mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", inventory.weapon2.slot1, inventory.weapon2.slot2)
        while mq.TLO.Cursor() == nil do
            mq.delay(100)
        end
        while mq.TLO.Cursor() ~= nil do
            mq.cmd('/itemnotify 14 leftmouseup')
            mq.delay(100)
        end
        if mq.TLO.Me.Inventory(14).Name() ~= inventory.weapon2.name then
            logger.log_warn("\aoThe main hand weapon does not seem to have been properly restored.")
        end
    end
    inventory.weapon1.name = ''
    inventory.weapon2.name = ''
end

function inventory.find_free_slot(exclude_bag)
    exclude_bag = exclude_bag or 15
    logger.log_verbose("\aoFinding free slot to place item.")
    for i = mq.TLO.Me.NumBagSlots(), 1, -1 do
        if i ~= exclude_bag then
            if mq.TLO.Me.Inventory('pack' .. i).Type() ~= "Quiver" then
                if mq.TLO.Me.Inventory('pack' .. i).Container() ~= 0 then
                    if mq.TLO.Me.Inventory('pack' .. i).Container() ~= nil then
                        for j = mq.TLO.Me.Inventory('pack' .. i).Container(), 1, -1 do
                            if mq.TLO.Me.Inventory('pack' .. i).Item(j)() == nil then
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
end

function inventory.item_check(item)
    if item.count == nil then
        logger.log_super_verbose("\aoChecking inventory for \ag%s\ao.", item.what)
        if mq.TLO.FindItem("=" .. item.what)() ~= nil then
            logger.log_info("\ag%s \aois already looted.", item.what)
            return true
        end
    else
        logger.log_super_verbose("\aoChecking inventory for \ag%s\ao(\ag%s\ao).", item.what, item.count)
        if mq.TLO.FindItemCount("=" .. item.what)() >= item.count then
            logger.log_info("\ag%s\ao(\ag%s\ao) \aois already looted.", item.what, item.count)
            return true
        end
    end
    return false
end

function inventory.loot(item)
    _G.State:setStatusText(string.format("Looting %s.", item.what))
    local looted = false
    if mq.TLO.AdvLoot.SCount() > 0 then
        for i = 1, mq.TLO.AdvLoot.SCount() do
            if mq.TLO.AdvLoot.SList(i).Name() == item.what then
                mq.cmdf('/squelch /advloot shared %s giveto %s', i, mq.TLO.Me.DisplayName())
                looted = true
                logger.log_info("\aoAttempting to loot \ag%s\ao.", item.what)
            end
        end
    end
    mq.delay("2s")
    if mq.TLO.AdvLoot.PCount() > 0 then
        for i = 1, mq.TLO.AdvLoot.PCount() do
            if mq.TLO.AdvLoot.PList(i).Name() == item.what then
                mq.cmdf('/squelch /advloot personal %s loot', i, mq.TLO.Me.DisplayName())
                looted = true
                logger.log_info("\aoAttempting to loot \ag%s\ao.", item.what)
            end
        end
    end
    mq.delay("2s")
    while mq.TLO.Window('ConfirmationDialogBox').Open() do
        mq.delay(200)
        logger.log_verbose("\aoNo drop confirmation window open.  Clicking yes.")
        mq.TLO.Window('ConfirmationDialogBox/CD_Yes_Button').LeftMouseUp()
    end
    mq.delay("1s")
    if mq.TLO.FindItem("=" .. item.what)() ~= nil then
        logger.log_info("\aoSuccessfully looted \ag%s\ao.", item.what)
        if item.gotostep ~= nil then
            _G.State:handle_step_change(item.gotostep)
        end
        return true
    else
        if looted == true then
            for i = 1, 10 do
                mq.delay(200)
                if mq.TLO.FindItem("=" .. item.what)() ~= nil then
                    logger.log_info("\aoSuccessfully looted \ag%s\ao.", item.what)
                    if item.gotostep ~= nil then
                        _G.State:handle_step_change(item.gotostep - 1)
                    end
                    return true
                end
            end
            --_G.State:setTaskRunning(false)
            _G.State:setStatusText(string.format("Tried to loot %s at step %s but failed!", item.what, _G.State.current_step))
            logger.log_error("\aoFailed to loot \ar%s \aoat step \ar%s\ao.", item.what, _G.State.current_step)
            mq.cmd('/foreground')
            return false
        end
    end
    if item.gotostep ~= nil then
        _G.State:handle_step_change(item.gotostep)
    end
end

function inventory.move_combine_container(slot, container)
    if mq.TLO.FindItem("=" .. container)() == nil then
        _G.State:setStatusText(string.format("Unable to find combine container (%s).", container))
        logger.log_error("\aoUnable to find combine container (\ar%s\ao).", container)
        _G.State:setTaskRunning(false)
        mq.cmd('/foreground')
        return
    end
    local itemslot = mq.TLO.FindItem("=" .. container).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. container).ItemSlot2() + 1
    logger.log_info("\aoMoving \ag%s \aoto bag slot \ag%s\ao.", container, slot)
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", itemslot, itemslot2)
    while string.lower(mq.TLO.Cursor.Name()) ~= string.lower(container) do
        mq.delay(100)
    end
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify %s leftmouseup", slot + 22)
    local loopCount = 0
    while mq.TLO.Cursor() == container do
        loopCount = loopCount + 1
        mq.delay(100)
        if loopCount == 10 then
            logger.log_debug("\ag%s \aodid not move to slot \ag%s \ao. Trying again.", container, slot)
            mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify %s leftmouseup", slot + 22)
        end
    end
    mq.delay(250)
    if string.lower(mq.TLO.Me.Inventory(slot + 22).Name()) ~= string.lower(container) then
        logger.log_warn("\ar%s \aodid not move to slot \ar%s\ao. Trying again.", container, slot)
        _G.State:handle_step_change(_G.State.current_step)
        return
    end
    mq.cmdf("/squelch /nomodkey /ctrl /itemnotify %s rightmouseup", slot + 22)
    mq.delay(250)
end

function inventory.move_bag(slot)
    local free_pack, free_slot = inventory.find_free_slot(slot)
    logger.log_info("\aoMoving item from bag slot \ag%s \ao to bag \ag%s\ao slot \ag%s\ao.", slot, free_pack, free_slot)
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify pack%s leftmouseup", slot)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", free_pack, free_slot)
    return free_pack, free_slot
end

function inventory.npc_buy(item, class_settings, char_settings)
    manage.removeInvis()
    _G.State:setStatusText(string.format("Buying %s from %s.", item.what, item.npc))
    logger.log_info("\aoBuying \ag%s \ao from \ag%s\ao.", item.what, item.npc)
    if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
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
    end
    mq.TLO.Target.RightClick()
    mq.delay("5s", inventory.merchant_window)
    while mq.TLO.Window('MerchantWnd/MW_ItemList').Items() == 0 do
        mq.delay(50)
    end
    mq.delay("1s")
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
    if mq.TLO.Me.Inventory('pack' .. slot).Container() then
        logger.log_info("\aoEmptying bag in slot \ag%s\ao.", slot)
        for i = 1, mq.TLO.Me.Inventory('pack' .. slot).Container() do
            if mq.TLO.Me.Inventory('pack' .. slot).Item(i)() ~= nil then
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
