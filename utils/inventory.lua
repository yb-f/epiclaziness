--- @type Mq
local mq = require('mq')

local inventory = {}

inventory.slot = 0
inventory.stored_item = ''

function inventory.equip_item(item)
    State.status = "Equiping " .. item.what
    mq.delay("1s")
    inventory.slot = mq.TLO.FindItem('=' .. item.what).WornSlot(1)()
    inventory.stored_item = mq.TLO.Me.Inventory(inventory.slot)()
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

function inventory.move_item_to_combine(name, slot)
    if mq.TLO.FindItem("=" .. name)() == nil then
        State.status = "Unable to find item for combine (" .. name .. ")"
        State.task_run = false
        return
    end
    local slot2     = 0
    local itemslot  = mq.TLO.FindItem("=" .. name).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. name).ItemSlot2() + 1
    mq.cmdf("/squelch /nomodkey /ctrl /itemnotify in pack%s %s leftmouseup", itemslot, itemslot2)
    mq.delay(500)
    print(mq.TLO.Cursor())
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    for j = mq.TLO.InvSlot('pack' .. slot).Item.Container(), 1, -1 do
        if mq.TLO.InvSlot('pack' .. slot).Item.Item(j)() == nil then
            slot2 = j
        end
    end
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", slot, slot2)
    mq.delay(500)
    print(mq.TLO.Cursor())
    while mq.TLO.Cursor() ~= nil do
        mq.delay(100)
    end
end

function inventory.move_item_to_enviro_combine(name, slot)
    if mq.TLO.FindItem("=" .. name)() == nil then
        State.status = "Unable to find item for combine (" .. name .. ")"
        State.task_run = false
        return
    end
    local itemslot  = mq.TLO.FindItem("=" .. name).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. name).ItemSlot2() + 1
    mq.cmdf("/squelch /nomodkey /ctrl /itemnotify in pack%s %s leftmouseup", itemslot, itemslot2)
    mq.delay(500)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf("/squelch /itemnotify enviro%s leftmouseup", slot)
    mq.delay(500)
    while mq.TLO.Cursor() ~= nil do
        mq.delay(100)
    end
end

function inventory.move_combine_container(slot, container)
    if mq.TLO.FindItem("=" .. container)() == nil then
        State.status = "Unable to find combine container (" .. container .. ")"
        State.task_run = false
        return
    end
    local itemslot = mq.TLO.FindItem("=" .. container).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. container).ItemSlot2() + 1
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
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify pack%s leftmouseup", slot)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf("/squelch /nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", free_pack, free_slot)
    return free_pack, free_slot
end

function inventory.empty_bag(slot)
    mq.cmd("/squelch /keypress OPEN_INV_BAGS")
    if mq.TLO.InvSlot('pack' .. slot).Item.Container() then
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
