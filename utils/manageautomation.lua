local mq = require('mq')
local dist = require 'utils/distance'

local manage = {}
local elheader = "\ay[\agEpic Laziness\ay]"

function manage.campGroup(radius, class_settings, char_settings)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'camp', char_settings)
    manage.setRadius(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(), class_settings.class[mq.TLO.Me.Class.Name()],
        radius, char_settings)
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'camp', char_settings)
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'camp',
            char_settings)
    end
end

function manage.doAutomation(character, class, script, action, char_settings)
    if action == 'start' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s mode 0 nosave', class)
                mq.cmdf('/squelch /%s usestick on nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /lua run rgmercs")
            elseif script == 3 then
                mq.cmd("/squelch /mac rgmercs")
            elseif script == 4 then
                mq.cmd("/squelch /mac kissassist")
            elseif script == 5 then
                mq.cmd("/squelch /mac muleassist")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s mode 2 nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /lua run rgmercs", character)
                mq.delay(500)
                mq.cmdf('/dex %s /squelch /rgl chaseon %s', character, mq.TLO.Me.DisplayName())
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /mac rgmercs", character)
                mq.delay(500)
                mq.cmdf('/dex %s /squelch /rg chaseon %s', character, mq.TLO.Me.DisplayName())
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /mac kissassist", character)
                mq.cmdf("/dex %s /squelch /chase on %s", character, mq.TLO.Me.DisplayName())
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /mac muleassist", character)
                mq.cmdf("/dex %s /squelch /chase on %s", character, mq.TLO.Me.DisplayName())
            end
        end
    elseif action == 'pause' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s pause on nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /rgl pause")
            elseif script == 3 then
                mq.cmd("/squelch /rg off")
            elseif script == 4 then
                mq.cmd("/squelch /mqp on")
            elseif script == 5 then
                mq.cmd("/squelch /mqp on")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s pause on nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /rgl pause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /rg off", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /mqp on", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /mqp on", character)
            end
        end
    elseif action == 'unpause' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s pause off nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /rgl unpause")
            elseif script == 3 then
                mq.cmd("/squelch /rg on")
            elseif script == 4 then
                mq.cmd("/squelch /mqp off")
            elseif script == 5 then
                mq.cmd("/squelch /mqp off")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s pause off nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /rgl unpause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /rg on", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /mqp off", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /mqp off", character)
            end
        end
    elseif action == 'camp' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s resetcamp nosave', class)
                mq.cmdf('/squelch /%s mode HunterTank nosave', class)
                mq.cmdf('/squelch /%s pause off nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /rgl unpause")
                mq.cmd("/squelch /rgl set pullmode 3")
                mq.cmd("/squelch /rgl set dopull on")
            elseif script == 3 then
                mq.cmd("/squelch /rg camphere")
                mq.cmd("/squelch /rg on")
            elseif script == 4 then
                mq.cmd("/squelch /mqp off")
                mq.cmd("/squelch /camphere on")
            elseif script == 5 then
                mq.cmd("/squelch /mqp off")
                mq.cmd("/squelch /camphere on")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s resetcamp nosave', character, class)
                mq.cmdf('/dex %s /squelch /%s mode 1 nosave', character, class)
                mq.cmdf('/dex %s /squelch /%s pause off nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /rgl campon", character)
                mq.cmdf("/dex %s /squelch /rgl unpause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /rg camphere", character)
                mq.cmdf("/dex %s /squelch /rg on", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /mqp off", character)
                mq.cmdf("/dex %s /squelch /camphere on", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /mqp off", character)
                mq.cmdf("/dex %s /squelch /camphere on", character)
            end
        end
    elseif action == 'uncamp' then
        if character == mq.TLO.Me.DisplayName() then
            if script == 1 then
                mq.cmdf('/squelch /%s mode 0 nosave', class)
                mq.cmdf('/squelch /%s pause on nosave', class)
            elseif script == 2 then
                mq.cmd("/squelch /rgl campoff")
                mq.cmd("/squelch /rgl pause")
            elseif script == 3 then
                mq.cmd("/squelch /rg campoff")
                mq.cmd("/squelch /rg off")
            elseif script == 4 then
                mq.cmd("/squelch /camphere off")
                mq.cmd("/squelch /mqp on")
            elseif script == 5 then
                mq.cmd("/squelch /camphere off")
                mq.cmd("/squelch /mqp on")
            end
        else
            if script == 1 then
                mq.cmdf('/dex %s /squelch /%s mode 2 nosave', character, class)
                mq.cmdf('/dex %s /squelch /%s pause on nosave', character, class)
            elseif script == 2 then
                mq.cmdf("/dex %s /squelch /rgl campoff", character)
                mq.cmdf('/dex %s /squelch /rgl chaseon %s', character, mq.TLO.Me.DisplayName())
                mq.cmdf("/dex %s /squelch /rgl pause", character)
            elseif script == 3 then
                mq.cmdf("/dex %s /squelch /rg camphere", character)
                mq.cmdf('/dex %s /squelch /rg chaseon %s', character, mq.TLO.Me.DisplayName())
                mq.cmdf("/dex %s /squelch /rg off", character)
            elseif script == 4 then
                mq.cmdf("/dex %s /squelch /camphere off", character)
                mq.cmdf("/dex %s /squelch /chaseon", character)
                mq.cmdf("/dex %s /squelch /mqp on", character)
            elseif script == 5 then
                mq.cmdf("/dex %s /squelch /camphere off", character)
                mq.cmdf("/dex %s /squelch /chaseon", character)
                mq.cmdf("/dex %s /squelch /mqp on", character)
            end
        end
    end
end

function manage.groupTalk(npc, phrase)
    if mq.TLO.Spawn(npc).Distance() ~= nil then
        if mq.TLO.Spawn(npc).Distance() > 100 then
            State.rewound = true
            State.step = State.step - 1
            return
        end
    end
    if State.group_choice == 1 then
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(npc).ID() then
            mq.TLO.Spawn(npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                mq.cmdf("/dex %s /squelch /target id %s", mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Spawn(npc).ID())
                mq.delay(300)
                mq.cmdf("/dex %s /say %s", mq.TLO.Group.Member(i).DisplayName(), phrase)
            end
            math.randomseed(os.time())
            local wait = math.random(4000, 10000)
            mq.delay(wait)
        end
        math.randomseed(os.time())
        local wait = math.random(4000, 10000)
        mq.delay(wait)
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(npc).ID() then
            mq.TLO.Spawn(npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    else
        mq.cmdf("/dex %s /squelch /target id %s", State.group_combo[State.group_choice], mq.TLO.Spawn(npc).ID())
        mq.delay(300)
        mq.cmdf("/dex %s /say %s", State.group_combo[State.group_choice], phrase)
        math.randomseed(os.time())
        local wait = math.random(4000, 10000)
        mq.delay(wait)
        if mq.TLO.Target.ID() ~= mq.TLO.Spawn(npc).ID() then
            mq.TLO.Spawn(npc).DoTarget()
            mq.delay(300)
        end
        mq.cmdf("/say %s", phrase)
        mq.delay(750)
    end
end

function manage.invis(class_settings, char_settings)
    State.status = "Using invis"
    local invis_type = {}
    if mq.TLO.Me.Combat() == true then
        mq.cmd('/squelch /attack off')
    end
    for word in string.gmatch(class_settings.class_invis[mq.TLO.Me.Class()], '([^|]+)') do
        table.insert(invis_type, word)
    end
    if invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Potion' then
        mq.cmd('/squelch /useitem "Cloudy Potion"')
    elseif invis_type[class_settings.invis[mq.TLO.Me.Class()]] == 'Hide/Sneak' then
        while mq.TLO.Me.AbilityReady('Hide')() == false do
            mq.delay(100)
            if mq.TLO.Me.Invis() == true then
                break
            end
        end
        mq.cmd("/squelch /doability hide")
        while mq.TLO.Me.Invis() == false do
            mq.delay(100)
            if mq.TLO.Me.AbilityReady('Hide')() == true then
                mq.cmd("/squelch /doability hide")
            end
        end
        if mq.TLO.Me.Sneaking() == false then
            while mq.TLO.Me.AbilityReady('Sneak')() == false do
                mq.delay(100)
            end
            mq.cmd("/squelch /doability sneak")
            while mq.TLO.Me.Sneaking() == false do
                mq.delay(100)
                if mq.TLO.Me.AbilityReady('Sneak')() == true then
                    mq.cmd("/squelch /doability sneak")
                end
            end
        end
    else
        local ID = class_settings['skill_to_num'][invis_type[class_settings.invis[mq.TLO.Me.Class()]]]
        mq.cmdf('/squelch /alt act %s', ID)
        mq.delay(500)
        while mq.TLO.Me.Casting() == true do
            mq.delay(200)
        end
    end
    if State.group_choice == 1 then
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                local invis_type = {}
                for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(i).Class()], '([^|]+)') do
                    table.insert(invis_type, word)
                end
                if invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == 'Potion' then
                    mq.cmdf('/dex %s /squelch /useitem "Cloudy Potion"', mq.TLO.Group.Member(i).DisplayName())
                elseif invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == 'Hide/Sneak' then
                    mq.cmdf("/dex %s /squelch /doability hide", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(250)
                    mq.cmdf("/dex %s /squelch /doability sneak", mq.TLO.Group.Member(i).DisplayName())
                else
                    local ID = class_settings['skill_to_num']
                        [invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]]]
                    mq.cmdf('/dex %s /squelch /alt act "%s"', mq.TLO.Group.Member(i).DisplayName(),
                        ID)
                end
            end
        end
        mq.delay("4s")
    else
        local invis_type = {}
        for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()], '([^|]+)') do
            table.insert(invis_type, word)
        end
        if invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]] == 'Potion' then
            mq.cmdf('/dex %s /squelch /useitem "Cloudy Potion"',
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
        elseif invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]] == 'Hide/Sneak' then
            mq.cmdf("/dex %s /squelch /doability hide",
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
            mq.delay(250)
            mq.cmdf("/dex %s /squelch /doability sneak",
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName())
        else
            local ID = class_settings['skill_to_num']
                [invis_type[class_settings.invis[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class()]]]
            mq.cmdf('/dex %s /squelch /alt act "%s"',
                mq.TLO.Group.Member(State.group_combo[State.group_choice]).DisplayName(), ID)
        end
        mq.delay("4s")
    end
    mq.delay(100)
end

function manage.openDoorAll()
    if State.group_choice == 1 then
        mq.delay(200)
        mq.cmd("/squelch /doortarget")
        mq.delay(200)
        mq.cmd("/squelch /click left door")
        mq.delay(1000)
    elseif State.group_choice == 2 then
        mq.delay(200)
        mq.cmd("/dgga /squelch /doortarget")
        mq.delay(200)
        mq.cmd("/dgga /squelch /click left door")
        mq.delay(1000)
    else
        local name = State.group_combo[State.group_choice]
        mq.delay(200)
        mq.cmd("/squelch /doortarget")
        mq.cmdf("/dex %s /squelch /doortarget", name)
        mq.delay(200)
        mq.cmdf("/dex %s /squelch /click left door", name)
        mq.cmd("/squelch /click left door")
        mq.delay(100)
    end
end

function manage.pauseGroup(class_settings)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'pause')
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'pause')
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'pause')
    end
end

function manage.picklockGroup()
    State.status = "Lockpicking door"
    if State.group_choice == 1 then
        if mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
        else
            printf("%s \aoI am not a class that is able to pick locks.", elheader)
            State.status = "I require a lockpicker to proceed. (" .. State.step .. ")"
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    elseif State.group_choice == 2 then
        local pickerFound = false
        if mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
            pickerFound = true
        else
            for i = 0, mq.TLO.Group.GroupSize() - 1 do
                if mq.TLO.Group.Member(i).Class.ShortName() == 'BRD' or mq.TLO.Group.Member(i).Class.ShortName() == 'ROG' then
                    mq.cmdf("/dex %s /squelch /itemnotify lockpicks leftmouseup", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(200)
                    mq.cmdf("/dex %s /squelch /doortarget", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(200)
                    mq.cmdf("/dex %s /squelch /click left door", mq.TLO.Group.Member(i).DisplayName())
                    mq.delay(200)
                    mq.cmdf("/dex %s /squelch /autoinv", mq.TLO.Group.Member(i).DisplayName())
                    pickerFound = true
                    break
                end
            end
        end
        if pickerFound == false then
            State.status = "I require a lockpicker to proceed. (" .. State.step .. ")"
            printf("%s \aoI require a class that is able to pick locks.", elheader)
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    else
        local name = State.group_combo[State.group_choice]
        if mq.TLO.Group.Member(name).Class.ShortName() == 'BRD' or mq.TLO.Group.Member(name).Class.ShortName() == 'ROG' then
            mq.cmdf("/dex %s /squelch /itemnotify lockpicks leftmouseup", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /doortarget", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /click left door", name)
            mq.delay(200)
            mq.cmdf("/dex %s /squelch /autoinv", name)
        elseif mq.TLO.Me.Class.ShortName() == 'BRD' or mq.TLO.Me.Class.ShortName() == 'ROG' then
            mq.cmd("/squelch /itemnotify lockpicks leftmouseup")
            mq.delay(200)
            mq.cmd("/squelch /doortarget")
            mq.delay(200)
            mq.cmd("/squelch /click left door")
            mq.delay(200)
            mq.cmd("/squelch /autoinv")
        else
            State.status = "I require a lockpicker to proceed. (" .. State.step .. ")"
            printf("%s \aoI require a class that is able to pick locks.", elheader)
            State.task_run = false
            mq.cmd('/foreground')
            return
        end
    end
end

function manage.removeInvis()
    State.status = "Removing invis"
    if State.group_choice == 1 then
        mq.cmd("/squelch /makemevis")
    elseif State.group_choice == 2 then
        mq.cmd("/dgga /squelch /makemevis")
    else
        mq.cmdf("/squelch /makemevis")
        mq.cmdf("/dex %s /squelch /makemevis", State.group_combo[State.group_choice])
    end
end

function manage.removeLev()
    --State.status = "Removing levitate"
    if State.group_choice == 1 then
        mq.cmd("/squelch /removelev")
    elseif State.group_choice == 2 then
        mq.cmd("/dgga /squelch /removelev")
    else
        mq.cmdf("/squelch /removelev")
        mq.cmdf("/dex %s /squelch /removelev", State.group_combo[State.group_choice])
    end
end

function manage.sendYes()
    State.status = "Removing levitate"
    if State.group_choice == 1 then
        mq.cmd("/squelch /yes")
    elseif State.group_choice == 2 then
        mq.cmd("/dgga /squelch /yes")
    else
        mq.cmdf("/squelch /yes")
        mq.cmdf("/dex %s /squelch /yes", State.group_combo[State.group_choice])
    end
end

function manage.setRadius(character, class, script, radius, char_settings)
    if script == 1 then
        mq.cmdf('/squelch /%s pullradius %s nosave', class, radius)
    elseif script == 2 then
        mq.cmdf("/squelch /rgl set pullradiushunt %s", radius)
    elseif script == 3 then
        mq.cmd("/squelch /rg pullrad %s", radius)
    elseif script == 4 then
        mq.cmd("/squelch /maxradius %s", radius)
    elseif script == 5 then
        mq.cmd("/squelch /maxradius %s", radius)
    end
end

function manage.startGroup(class_settings, char_settings)
    if mq.TLO.Me.Grouped() == true and mq.TLO.Group.Leader() == mq.TLO.Me.DisplayName() then
        mq.cmdf("/squelch /grouprole set %s 1", mq.TLO.Me.DisplayName())
        mq.cmdf("/squelch /grouprole set %s 2", mq.TLO.Me.DisplayName())
        --mq.cmdf("/grouprole set %s 3", mq.TLO.Me.DisplayName())
    end
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'start', char_settings)
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'start', char_settings)
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'start',
            char_settings)
    end
end

function manage.uncampGroup(class_settings)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()],
        'uncamp')
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        for i = 0, mq.TLO.Group.GroupSize() - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'uncamp')
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'uncamp')
    end
end

function manage.unpauseGroup(class_settings)
    manage.doAutomation(mq.TLO.Me.DisplayName(), mq.TLO.Me.Class.ShortName(),
        class_settings.class[mq.TLO.Me.Class.Name()], 'unpause')
    if State.group_choice == 1 then
        return
    elseif State.group_choice == 2 then
        local groupSize = 1
        if mq.TLO.Group.GroupSize() ~= nil then
            groupSize = mq.TLO.Group.GroupSize()
        end
        for i = 0, groupSize - 1 do
            if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
                manage.doAutomation(mq.TLO.Group.Member(i).DisplayName(), mq.TLO.Group.Member(i).Class.ShortName(),
                    class_settings.class[mq.TLO.Group.Member(i).Class.Name()],
                    'unpause')
            end
        end
    else
        manage.doAutomation(State.group_combo[State.group_choice],
            mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.ShortName(),
            class_settings.class[mq.TLO.Group.Member(State.group_combo[State.group_choice]).Class.Name()], 'unpause')
    end
end

return manage
