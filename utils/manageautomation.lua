--[[
	Functions for managing ourself and group members
--]]

local mq = require("mq")
local logger = require("lib/logger")

local RANDOM_MIN = 300
local RANDOM_MAX = 3000
local MAX_DISTANCE = 100
---@class ManageAutomation
local manage = {}
local me = mq.TLO.Me
local group = mq.TLO.Group

-- Set class automation script to camp and kill in a certain radius
---@param radius number
---@param zradius number
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function manage.campGroup(radius, zradius, common_settings, char_settings)
	local choice, name = _G.State:readGroupSelection()
	logger.log_info("\aoSetting camp mode with radius \ag%s\ao.", radius)
	manage.doAutomation(me.DisplayName(), me.Class.ShortName(), common_settings.class[me.Class.Name()], "camp")
	manage.setRadius(
		me.DisplayName(),
		me.Class.ShortName(),
		common_settings.class[me.Class.Name()],
		radius,
		zradius,
		char_settings
	)
	if choice == 1 then
		return
	elseif choice == 2 then
		for i = 1, group.Members() do
			if group.Member(i).DisplayName() ~= me.DisplayName() then
				manage.doAutomation(
					group.Member(i).DisplayName(),
					group.Member(i).Class.ShortName(),
					common_settings.class[group.Member(i).Class.Name()],
					"camp"
				)
			end
		end
	else
		manage.doAutomation(
			name,
			group.Member(name).Class.ShortName(),
			common_settings.class[group.Member(name).Class.Name()],
			"camp"
		)
	end
end

-- Issue commands to class automation scripts for self and group members.
---@param character string
---@param class string
---@param script number
---@param action string
function manage.doAutomation(character, class, script, action)
	local commands_self = {
		[1] = {
			start = function()
				return {
					string.format("/%s mode 0 n osave", class),
					string.format("/%s usestick on nosave", class),
					string.format("/%s zhigh 100 nosave", class),
					string.format("/%s zlow 100 nosave", class),
				}
			end,
			pause = function()
				return {
					string.format("/%s pause on nosave", class),
				}
			end,
			unpause = function()
				return {
					string.format("/%s pause off nosave", class),
				}
			end,
			camp = function()
				return {
					string.format("/%s resetcamp nosave", class),
					string.format("/%s pause off nosave", class),
					string.format("/%s mode HunterTank nosave", class),
				}
			end,
			uncamp = function()
				return {
					string.format("/%s mode 0 nosave", class),
					string.format("/%s pause on nosave", class),
				}
			end,
		},
		[2] = {
			start = function()
				return {
					string.format("/lua run rgmercs %s", mq.TLO.Me.CleanName()),
					string.format("/lua run rgmercs %s", mq.TLO.Me.CleanName()),
					string.format("/rgl set PullZRadius 100"),
					string.format("/rgl set pullmincon 1"),
				}
			end,
			pause = function()
				return {
					string.format("/rgl pause"),
				}
			end,
			unpause = function()
				return {
					string.format("/rgl unpause"),
				}
			end,
			camp = function()
				return {
					string.format("/rgl unpause"),
					string.format("/rgl set pullmode 3"),
					string.format("/rgl set dopull on"),
				}
			end,
			uncamp = function()
				return {
					string.format("/rgl dopull off"),
					string.format("/rgl pause"),
				}
			end,
		},
		[3] = {
			start = function()
				return {
					string.format("/mac rgmercs/rgmerc"),
				}
			end,
			pause = function()
				return {
					string.format("/rg off"),
				}
			end,
			unpause = function()
				return {
					string.format("/rg on"),
				}
			end,
			camp = function()
				return {
					string.format("/rg camphere"),
					string.format("/rg on"),
				}
			end,
			uncamp = function()
				return {
					string.format("/rg campoff"),
					string.format("/rg off"),
				}
			end,
		},
		[4] = {
			start = function()
				return {
					string.format("/mac kissassist %s", mq.TLO.Me.DisplayName()),
					string.format("/maxzrange 100"),
				}
			end,
			pause = function()
				return {
					string.format("/mqp on"),
				}
			end,
			unpause = function()
				return {
					string.format("/mqp off"),
				}
			end,
			camp = function()
				return {
					string.format("/camphere on"),
					string.format("/mqp off"),
				}
			end,
			uncamp = function()
				return {
					string.format("/camphere off"),
					string.format("/mqp on"),
				}
			end,
		},
		[5] = {
			start = function()
				return {
					string.format("/mac muleassist %s", mq.TLO.Me.DisplayName()),
					string.format("/maxzrange 100"),
				}
			end,
			pause = function()
				return {
					string.format("/mqp on"),
				}
			end,
			unpause = function()
				return {
					string.format("/mqp off"),
				}
			end,
			camp = function()
				return {
					string.format("/camphere on"),
					string.format("/mqp off"),
				}
			end,
			uncamp = function()
				return {
					string.format("/camphere off"),
					string.format("/mqp on"),
				}
			end,
		},
	}
	local commands_group = {
		[1] = {
			start = function()
				return {
					string.format("/dex %s /%s mode 2 nosave", character, class),
				}
			end,
			pause = function()
				return {
					string.format("/dex %s /%s pause on nosave", character, class),
				}
			end,
			unpause = function()
				return {
					string.format("/dex %s /%s pause off nosave", character, class),
				}
			end,
			camp = function()
				return {
					string.format("/dex %s /%s resetcamp nosave", character, class),
					string.format("/dex %s /%s mode 1 nosave", character, class),
					string.format("/dex %s /%s pause off nosave", character, class),
				}
			end,
			uncamp = function()
				return {
					string.format("/dex %s /%s mode 2 nosave", character, class),
					string.format("/dex %s /%s pause on nosave", character, class),
				}
			end,
		},
		[2] = {
			start = function()
				return {
					string.format("/dex %s /lua run rgmercs", character),
					string.format("/dex %s /rgl chaseon %s", character, mq.TLO.Me.CleanName()),
				}
			end,
			pause = function()
				return {
					string.format("/dex %s /rgl pause", character),
				}
			end,
			unpause = function()
				return {
					string.format("/dex %s /rgl unpause", character),
				}
			end,
			camp = function()
				return {
					string.format("/dex %s /rgl chaseon %s", character, mq.TLO.Me.CleanName()),
					string.format("/dex %s /rgl pause", character),
				}
			end,
			uncamp = function()
				return {
					string.format("/dex %s /rgl chaseon %s", character, mq.TLO.Me.CleanName()),
					string.format("/dex %s /rgl pause", character),
				}
			end,
		},
		[3] = {
			start = function()
				return {
					string.format("/dex %s /mac rgmercs", character),
					string.format("/dex %s /rg chaseon %s", character, mq.TLO.Me.DisplayName()),
				}
			end,
			pause = function()
				return {
					string.format("/dex %s /rg off", character),
				}
			end,
			unpause = function()
				return {
					string.format("/dex %s /rg on", character),
				}
			end,
			camp = function()
				return {
					string.format("/dex %s /rg camphere", character),
					string.format("/dex %s /rg on", character),
				}
			end,
			uncamp = function()
				return {
					string.format("/dex %s /rg camphere", character),
					string.format("/dex %s /rg chaseon %s", character, mq.TLO.Me.DisplayName()),
					string.format("/dex %s /rg off", character),
				}
			end,
		},
		[4] = {
			start = function()
				return {
					string.format("/dex %s /mac kissassist %s", character, mq.TLO.Me.DisplayName()),
					string.format("/dex %s /chase on %s", character, mq.TLO.Me.DisplayName()),
				}
			end,
			pause = function()
				return {
					string.format("/dex %s /mqp on", character),
				}
			end,
			unpause = function()
				return {
					string.format("/dex %s /mqp off", character),
				}
			end,
			camp = function()
				return {
					string.format("/dex %s /mqp off", character),
					string.format("/dex %s /camphere on", character),
				}
			end,
			uncamp = function()
				return {
					string.format("/dex %s /camphere off", character),
					string.format("/dex %s /chaseon", character),
					string.format("/dex %s /mqp on", character),
				}
			end,
		},
		[5] = {
			start = function()
				return {
					string.format("/dex %s /mac muleassist %s", character, mq.TLO.Me.DisplayName()),
					string.format("/dex %s /chase on %s", character, mq.TLO.Me.DisplayName()),
				}
			end,
			pause = function()
				return {
					string.format("/dex %s /mqp on", character),
				}
			end,
			unpause = function()
				return {
					string.format("/dex %s /mqp off", character),
				}
			end,
			camp = function()
				return {
					string.format("/dex %s /mqp off", character),
					string.format("/dex %s /camphere on", character),
				}
			end,
			uncamp = function()
				return {
					string.format("/dex %s /camphere off", character),
					string.format("/dex %s /chaseon", character),
					string.format("/dex %s /mqp on", character),
				}
			end,
		},
	}
	if character == mq.TLO.Me.DisplayName() then
		if commands_self[script] and commands_self[script][action] then
			local cmds = commands_self[script][action]()
			for _, cmd in ipairs(cmds) do
				mq.cmd(cmd)
			end
		end
	else
		if commands_group[script] and commands_group[script][action] then
			local cmds = commands_group[script][action]()
			for _, cmd in ipairs(cmds) do
				mq.cmd(cmd)
			end
		end
	end
end

-- Have the entire group say a phrase to an NPC
---@param item Item
---@param choice number
---@param name string
function manage.groupTalk(item, choice, name)
	manage.removeInvis(item)
	_G.State:setStatusText("Talking to %s (%s).", item.npc, item.phrase)
	logger.log_info("\aoHaving all grouped characters say \ag%s \ao to \ag%s\ao.", item.phrase, item.npc)
	if mq.TLO.Spawn(item.npc).Distance() ~= nil then
		if mq.TLO.Spawn(item.npc).Distance() > MAX_DISTANCE then
			logger.log_warn(
				"\ar%s \aois over %s units away. Moving back to step \ar%s\ao.",
				item.npc,
				MAX_DISTANCE,
				_G.State.current_step
			)
			_G.State:handle_step_change(_G.State.current_step - 1)
			return
		end
	end
	if choice == 1 then
		if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
			logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
			mq.TLO.Spawn(item.npc).DoTarget()
			mq.delay(300)
		end
		mq.cmdf("/say %s", item.phrase)
		mq.delay(750)
	elseif choice == 2 then
		for i = 1, group.Members() do
			if group.Member(i).DisplayName() ~= me.DisplayName() then
				mq.cmdf("/dex %s /target id %s", group.Member(i).DisplayName(), mq.TLO.Spawn(item.npc).ID())
				mq.delay(300)
				mq.cmdf("/dex %s /say %s", group.Member(i).DisplayName(), item.phrase)
			end
			math.randomseed(os.time())
			local wait = math.random(RANDOM_MIN, RANDOM_MAX)
			mq.delay(wait)
		end
		math.randomseed(os.time())
		local wait = math.random(RANDOM_MIN, RANDOM_MAX)
		mq.delay(wait)
		if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
			mq.TLO.Spawn(item.npc).DoTarget()
			mq.delay(300)
		end
		mq.cmdf("/say %s", item.phrase)
		mq.delay(750)
	else
		mq.cmdf("/dex %s /target id %s", name, mq.TLO.Spawn(item.npc).ID())
		mq.delay(300)
		mq.cmdf("/dex %s /say %s", name, item.phrase)
		math.randomseed(os.time())
		local wait = math.random(RANDOM_MIN, RANDOM_MAX)
		mq.delay(wait)
		if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
			mq.TLO.Spawn(item.npc).DoTarget()
			mq.delay(300)
		end
		mq.cmdf("/say %s", item.phrase)
		mq.delay(750)
	end
end

-- Have all group members click a door (ie to zone in)
---@param item Item
---@param choice number
---@param name string
function manage.openDoorAll(item, choice, name)
	logger.log_info("\aoHaving group click door.")
	if choice == 1 then
		mq.delay(200)
		mq.cmd("/doortarget")
		mq.delay(200)
		mq.cmd("/click left door")
		mq.delay(1000)
	elseif choice == 2 then
		mq.delay(200)
		mq.cmd("/dgga /doortarget")
		mq.delay(200)
		mq.cmd("/dgga /click left door")
		mq.delay(1000)
	else
		mq.delay(200)
		mq.cmd("/doortarget")
		mq.cmdf("/dex %s /doortarget", name)
		mq.delay(200)
		mq.cmdf("/dex %s /click left door", name)
		mq.cmd("/click left door")
		mq.delay(100)
	end
end

-- Pause class automation for all group members
---@param common_settings Common_Settings_Settings
function manage.pauseGroup(common_settings)
	local choice, name = _G.State:readGroupSelection()
	logger.log_info("\aoPausing class automation for all group members.")
	manage.doAutomation(me.DisplayName(), me.Class.ShortName(), common_settings.class[me.Class.Name()], "pause")
	if choice == 1 then
		return
	elseif choice == 2 then
		for i = 1, group.Members() do
			if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
				manage.doAutomation(
					group.Member(i).DisplayName(),
					group.Member(i).Class.ShortName(),
					common_settings.class[group.Member(i).Class.Name()],
					"pause"
				)
			end
		end
	else
		manage.doAutomation(
			name,
			group.Member(name).Class.ShortName(),
			common_settings.class[group.Member(name).Class.Name()],
			"pause"
		)
	end
end

-- Find a group member (or self) to pick a lock
---@param item Item
---@param choice number
---@param name string
function manage.picklockGroup(item, choice, name)
	_G.State:setStatusText("Lockpicking door.")
	logger.log_info("\aoLockpicking door.")
	mq.cmd("/doortarget")
	if choice == 1 then
		if me.Class.ShortName() == "BRD" or me.Class.ShortName() == "ROG" then
			logger.log_verbose("\aoI am able to pick locks, doing so now.")
			mq.cmd("/itemnotify lockpicks leftmouseup")
			mq.delay(200)
			mq.cmd("/doortarget")
			mq.delay(200)
			mq.cmd("/click left door")
			mq.delay(200)
			mq.cmd("/autoinv")
		else
			logger.log_error(
				"\aoI am not a class that is able to pick locks. Stopping script at step \ar%s \ao.",
				_G.State.current_step
			)
			_G.State:setStatusText("I require a lockpicker to proceed. (%s).", _G.State.current_step)
			_G.State:setTaskRunning(false)
			mq.cmd("/foreground")
			return
		end
	elseif choice == 2 then
		local pickerFound = false
		if me.Class.ShortName() == "BRD" or me.Class.ShortName() == "ROG" then
			logger.log_verbose("\aoI am able to pick locks, doing so now.")
			mq.cmd("/itemnotify lockpicks leftmouseup")
			mq.delay(200)
			mq.cmd("/doortarget")
			mq.delay(200)
			mq.cmd("/click left door")
			mq.delay(200)
			mq.cmd("/autoinv")
			pickerFound = true
		else
			for i = 1, group.Members() do
				if group.Member(i).Class.ShortName() == "BRD" or group.Member(i).Class.ShortName() == "ROG" then
					logger.log_verbose(
						"\ag%s \aois able to pick locks. Having them do so.",
						group.Member(i).DisplayName()
					)
					mq.cmdf("/dex %s /itemnotify lockpicks leftmouseup", group.Member(i).DisplayName())
					mq.delay(200)
					mq.cmdf("/dex %s /doortarget", group.Member(i).DisplayName())
					mq.delay(200)
					mq.cmdf("/dex %s /click left door", group.Member(i).DisplayName())
					mq.delay(200)
					mq.cmdf("/dex %s /autoinv", group.Member(i).DisplayName())
					pickerFound = true
					break
				end
			end
		end
		if pickerFound == false then
			_G.State:setStatusText("I require a lockpicker to proceed. (%s).", _G.State.current_step)
			logger.log_error(
				"\aoNo one in my group is a class that is able to pick locks. Stopping script at step \ar%s \ao.",
				_G.State.current_step
			)
			_G.State:setTaskRunning(false)
			mq.cmd("/foreground")
			return
		end
	else
		if group.Member(name).Class.ShortName() == "BRD" or group.Member(name).Class.ShortName() == "ROG" then
			logger.log_verbose("\ag%s \aois able to pick locks. Having them do so.", group.Member(name).DisplayName())
			mq.cmdf("/dex %s /itemnotify lockpicks leftmouseup", name)
			mq.delay(200)
			mq.cmdf("/dex %s /doortarget", name)
			mq.delay(200)
			mq.cmdf("/dex %s /click left door", name)
			mq.delay(200)
			mq.cmdf("/dex %s /autoinv", name)
		elseif mq.TLO.Me.Class.ShortName() == "BRD" or mq.TLO.Me.Class.ShortName() == "ROG" then
			logger.log_verbose("\aoI am able to pick locks, doing so now.")
			mq.cmd("/itemnotify lockpicks leftmouseup")
			mq.delay(200)
			mq.cmd("/doortarget")
			mq.delay(200)
			mq.cmd("/click left door")
			mq.delay(200)
			mq.cmd("/autoinv")
		else
			_G.State:setStatusText("I require a lockpicker to proceed. (%s).", _G.State.current_step)
			logger.log_error(
				"\aoI am not a class that is able to pick locks, nor is \ag%s\ao. Stopping script at step \ar%s \ao.",
				group.Member(name).DisplayName(),
				_G.State.current_step
			)
			_G.State:setTaskRunning(false)
			mq.cmd("/foreground")
			return
		end
	end
	local loopCount = 0
	while mq.TLO.DoorTarget.Open() == false do
		mq.delay(200)
		loopCount = loopCount + 1
		if loopCount > 60 then
			logger.log_error("\aoDoor did not open after 12 seconds. Repeating step \ar%s\ao.", _G.State.current_step)
			_G.State:setStatusText("Door did not open after 12 seconds. (%s).", _G.State.current_step)
			_G.State:handle_step_change(_G.State.current_step)
			return
		end
	end
end

-- Remove invisibility
---@param item Item
function manage.removeInvis(item)
	local choice, name = _G.State:readGroupSelection()
	local temp = _G.State:readStatusText()
	_G.State:setStatusText("Removing invis.")
	if me.Invis() then
		logger.log_info("\aoRemoving invisibility.")
		if choice == 1 then
			mq.cmd("/makemevis")
		elseif choice == 2 then
			mq.cmd("/dgga /makemevis")
		else
			mq.cmdf("/makemevis")
			mq.cmdf("/dex %s /makemevis", name)
		end
	end
	_G.State:setStatusText(temp)
end

-- Remove levitate
function manage.removeLev()
	local choice, name = _G.State:readGroupSelection()
	_G.State:setStatusText("Removing levitate.")
	logger.log_info("\aoRemoving levitate.")
	if mq.TLO.Me.Buff("Spirit of Eagle")() ~= nil then
		_G.State:setStatusText("Found Spirit of Eagle, not removing.")
		logger.log_info("\aoFound Spirit of Eagle, not removing.")
		return
	end
	if choice == 1 then
		mq.cmd("/removelev")
	elseif choice == 2 then
		mq.cmd("/dgga /removelev")
	else
		mq.cmdf("/removelev")
		mq.cmdf("/dex %s /removelev", name)
	end
end

-- Have everyone click yes on popup window
---@param item Item
---@param choice number
---@param name string
function manage.sendYes(item, choice, name)
	logger.log_info("\aoGive me a yes!")
	if choice == 1 then
		mq.cmd("/yes")
	elseif choice == 2 then
		mq.cmd("/dgga /yes")
	else
		mq.cmdf("/yes")
		mq.cmdf("/dex %s /yes", name)
	end
end

-- Set radius for class automation script to farm in
---@param character string
---@param class string
---@param script number
---@param radius number
---@param zradius number
---@param char_settings Char_Settings_SaveState
function manage.setRadius(character, class, script, radius, zradius, char_settings)
	logger.log_verbose("\aoSetting radius to \ag%s\ao.", radius)
	if script == 1 then
		mq.cmdf("/%s pullradius %s nosave", class, radius)
		mq.cmdf("/%s zradius %s nosave", class, zradius)
	elseif script == 2 then
		mq.cmdf("/rgl set pullradiushunt %s", radius)
		mq.cmdf("/rgl set pullzradius %s", zradius)
	elseif script == 3 then
		mq.cmd("/rg pullrad %s", radius)
	elseif script == 4 then
		mq.cmd("/maxradius %s", radius)
	elseif script == 5 then
		mq.cmd("/maxradius %s", radius)
	end
end

-- Start class automation for group
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function manage.startGroup(common_settings, char_settings)
	local choice, name = _G.State:readGroupSelection()
	logger.log_verbose("\aoStarting class automation for group and setting group roles.")
	if me.Grouped() == true and group.Leader() == me.DisplayName() then
		logger.log_super_verbose("\aoSetting self to MA and MT.")
		mq.cmdf("/grouprole set %s 1", mq.TLO.Me.DisplayName())
		mq.cmdf("/grouprole set %s 2", mq.TLO.Me.DisplayName())
	end
	manage.doAutomation(me.DisplayName(), me.Class.ShortName(), common_settings.class[me.Class.Name()], "start")
	if choice == 1 then
		return
	elseif choice == 2 then
		for i = 1, group.Members() do
			if group.Member(i).DisplayName() ~= me.DisplayName() then
				manage.doAutomation(
					group.Member(i).DisplayName(),
					group.Member(i).Class.ShortName(),
					common_settings.class[group.Member(i).Class.Name()],
					"start"
				)
			end
		end
	else
		manage.doAutomation(
			name,
			group.Member(name).Class.ShortName(),
			common_settings.class[group.Member(name).Class.Name()],
			"start"
		)
	end
end

-- Stop class automation from farming the current area
---@param common_settings Common_Settings_Settings
function manage.uncampGroup(common_settings)
	local choice, name = _G.State:readGroupSelection()
	logger.log_info("\aoEnding camp mode.")
	manage.doAutomation(me.DisplayName(), me.Class.ShortName(), common_settings.class[me.Class.Name()], "uncamp")
	if choice == 1 then
		return
	elseif choice == 2 then
		for i = 1, group.Members() do
			if group.Member(i).DisplayName() ~= me.DisplayName() then
				manage.doAutomation(
					group.Member(i).DisplayName(),
					group.Member(i).Class.ShortName(),
					common_settings.class[group.Member(i).Class.Name()],
					"uncamp"
				)
			end
		end
	else
		manage.doAutomation(
			name,
			group.Member(name).Class.ShortName(),
			common_settings.class[group.Member(name).Class.Name()],
			"uncamp"
		)
	end
end

-- Unpause class automation for group
---@param common_settings Common_Settings_Settings
function manage.unpauseGroup(common_settings)
	local choice, name = _G.State:readGroupSelection()
	logger.log_info("\aoUnpausing class automation for group.")
	manage.doAutomation(me.DisplayName(), me.Class.ShortName(), common_settings.class[me.Class.Name()], "unpause")
	if choice == 1 then
		return
	elseif choice == 2 then
		for i = 1, group.Members() do
			if group.Member(i).DisplayName() ~= me.DisplayName() then
				manage.doAutomation(
					group.Member(i).DisplayName(),
					group.Member(i).Class.ShortName(),
					common_settings.class[group.Member(i).Class.Name()],
					"unpause"
				)
			end
		end
	else
		manage.doAutomation(
			name,
			group.Member(name).Class.ShortName(),
			common_settings.class[group.Member(name).Class.Name()],
			"unpause"
		)
	end
end

return manage
