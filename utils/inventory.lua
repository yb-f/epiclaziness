--- @type Mq
local mq = require('mq')

local inventory = {}

function inventory.find_free_slot(exclude_bag)
    for i = 10, 1, -1 do
        if i ~= exclude_bag then
            for j = mq.TLO.InvSlot('pack' .. i).Item.Container(), 1, -1 do
                if mq.TLO.InvSlot('pack' .. i).Item.Item(j)() == nil then
                    return i, j
                end
            end
        end
    end
end

function inventory.move_item_to_combine(name, slot)
    local slot2     = 0
    local itemslot  = mq.TLO.FindItem("=" .. name).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. name).ItemSlot2() + 1
    mq.cmdf("/nomodkey /ctrl /itemnotify in pack%s %s leftmouseup", itemslot, itemslot2)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    for j = mq.TLO.InvSlot('pack' .. slot).Item.Container(), 1, -1 do
        if mq.TLO.InvSlot('pack' .. slot).Item.Item(j)() == nil then
            slot2 = j
        end
    end
    mq.cmdf("/nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", slot, slot2)
    mq.delay("1s")
end

function inventory.move_combine_container(slot, container)
    local itemslot = mq.TLO.FindItem("=" .. container).ItemSlot() - 22
    local itemslot2 = mq.TLO.FindItem("=" .. container).ItemSlot2() + 1
    mq.cmdf("/nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", itemslot, itemslot2)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf("/nomodkey /shiftkey /itemnotify %s leftmouseup", slot + 22)
    mq.delay(250)
    mq.cmdf("/nomodkey /ctrl /itemnotify %s rightmouseup", slot + 22)
end

function inventory.move_bag(slot)
    local free_pack, free_slot = inventory.find_free_slot(slot)
    mq.cmdf("/nomodkey /shiftkey /itemnotify pack%s leftmouseup", slot)
    while mq.TLO.Cursor() == nil do
        mq.delay(100)
    end
    mq.cmdf("/nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", free_pack, free_slot)
    return free_pack, free_slot
end

function inventory.empty_bag(slot)
    mq.cmd("/keypress OPEN_INV_BAGS")
    if mq.TLO.InvSlot('pack' .. slot).Item.Container() then
        for i = 1, mq.TLO.InvSlot('pack' .. slot).Item.Container() do
            if mq.TLO.InvSlot('pack' .. slot).Item.Item(i)() ~= nil then
                local free_pack, free_slot = inventory.find_free_slot(slot)
                mq.cmdf("/nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", slot, i)
                while mq.TLO.Cursor() == nil do
                    mq.delay(100)
                end
                mq.cmdf("/nomodkey /shiftkey /itemnotify in pack%s %s leftmouseup", free_pack, free_slot)
            end
        end
    end
end

return inventory
