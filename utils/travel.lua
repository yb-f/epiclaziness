--TODO: If we have an invalid connection in the path find an alternate straight path
local mq = require("mq")
local logger = require("utils/logger")
local dist = require("utils/distance")

local translocators = {
	"Magus",
	"Translocator",
	"Priest of Discord",
	"Nexus Scion",
	"Deaen Greyforge",
	"Ambassador Cogswald",
	"Madronoa",
	"Belinda",
	"Herald of Druzzil Ro",
}

local SELOS_BUFF = 3704
local CHEETAH_BUFF = 939
local SPIRIT_EAGELE_BUFF = 8600
local SPIRIT_FALCONS_BUFF = 8600
local FLIGHT_FALCONS_BUFF = 8601
local SHAURIS_BUFF = 231
local SHARED_CAMO_BUFF = 518
local GROUP_PERFECTED_INVIS = 1210
local GROUP_SILENT_PRESENCE = 630
local speed_classes = { "Bard", "Druid", "Ranger", "Shaman" }
local speed_buffs =
{ "Selo's Accelerato", "Communion of the Cheetah", "Spirit of Falcons", "Flight of Falcons", "Spirit of Eagle" }
---@class Travel
local travel = {}
travel.looping = false
travel.timeStamp = 0

travel.invalid_connections = {
	["Dragon Necropolis"] = {
		"The Breeding Grounds",
	},
}

-- Check if we are near a translocator npc before attempting to invis
---@return boolean
function travel.invisTranslocatorCheck()
	logger.log_verbose("\aoChecking if we are near a translocator npc before invising.")
	for _, name in ipairs(translocators) do
		if mq.TLO.Spawn("npc " .. name).Distance() ~= nil then
			if mq.TLO.Spawn("npc " .. name).Distance() < 50 then
				logger.log_super_verbose(
					"\aoWe are near \ag%s\ao. Skipping invis.",
					mq.TLO.Spawn("npc " .. name).DisplayName()
				)
				return true
			end
		end
	end
	return false
end

-- Face the indicated heading
---@param item Item
---@param choice number
---@param name string
function travel.face_heading(item, choice, name)
	_G.State:setStatusText("Facing heading %s.", item.what)
	logger.log_info("\aoFacing heading: \ag%s\ao.", item.what)
	if choice == 1 then
		mq.cmdf("/face heading %s", item.what)
	elseif choice == 2 then
		mq.cmdf("/dgga /face heading %s", item.what)
	else
		mq.cmdf("/face heading %s", item.what)
		mq.cmdf("/dex %s /face heading %s", name, item.what)
	end
	mq.delay(250)
end

-- Face the indicated location
---@param item Item
---@param choice number
---@param name string
function travel.face_loc(item, choice, name)
	local x = item.whereX
	local y = item.whereY
	local z = item.whereZ
	_G.State:setStatusText("Facing location: %s %s %s.", y, x, z)
	logger.log_info("\aoFacing location \ag%s, %s, %s\ao.", y, x, z)
	if choice == 1 then
		mq.cmdf("/face loc %s,%s,%s", y, x, z)
	elseif choice == 2 then
		mq.cmdf("/dgga /face loc %s,%s,%s", y, x, z)
	else
		mq.cmdf("/face loc %s,%s,%s", y, x, z)
		mq.cmdf("/dex %s /face loc %s,%s,%s", name, y, x, z)
	end
	mq.delay(250)
end

-- Move forward until we have zoned
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param choice number
---@param name string
function travel.forward_zone(item, class_settings, char_settings, choice, name)
	if char_settings.general.speedForTravel == true then
		local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
		if speedChar ~= "none" then
			travel.navPause()
			travel.doSpeed(speedChar, speedSkill)
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
	end
	if travel.invisCheck(item, char_settings, class_settings, item.invis) then
		travel.invis(class_settings)
	end
	_G.State:setStatusText("Traveling forward to zone: %s.", item.zone)
	logger.log_info("\aoTraveling forward to zone: \ag%s\ao.", item.zone)
	if choice == 1 then
		mq.cmd("/keypress forward hold")
		while mq.TLO.Zone.ShortName() ~= item.zone do
			mq.delay(500)
		end
	elseif choice == 2 then
		mq.cmd("/dgge /keypress forward hold")
		mq.cmd("/keypress forward hold")
		while mq.TLO.Zone.ShortName() ~= item.zone do
			mq.delay(500)
		end
		while mq.TLO.Group.AnyoneMissing() do
			mq.delay(500)
		end
	else
		mq.cmdf("/dex %s /keypress forward hold", name)
		mq.cmd("/keypress forward hold")
		while mq.TLO.Zone.ShortName() ~= item.zone and mq.TLO.Zone.Name() ~= item.zone do
			mq.delay(500)
		end
		while mq.TLO.Group.Member(name).OtherZone() do
			mq.delay(500)
		end
	end
	mq.delay("2s")
end

-- Gate the group
---@param choice number
---@param name string
function travel.gate_group(choice, name)
	---@diagnostic disable-next-line: redundant-parameter
	logger.log_info("\aoGating to \ag%s\ao.", mq.TLO.Me.BoundLocation(0)())
	if choice == 1 then
		mq.cmd("/relocate gate")
		mq.delay(500)
	elseif choice == 2 then
		mq.cmd("/dgga /relocate gate")
		mq.delay(500)
	else
		mq.cmd("/relocate gate")
		mq.cmdf("/dex %s /relocate gate", name)
	end
	local loopCount = 0
	while mq.TLO.Me.Casting() == nil do
		loopCount = loopCount + 1
		mq.delay(10)
		if loopCount >= 200 then
			logger.log_warn("\aoSpent 2 seconds waiting for gate to cast. Moving on.")
			break
		end
	end
	loopCount = 0
	while mq.TLO.Me.Casting() ~= nil do
		mq.delay(50)
	end
end

-- Travel to a location manually without using MQ2Nav
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param choice number
---@param name string
function travel.no_nav_travel(item, class_settings, char_settings, choice, name)
	local x = item.whereX
	local y = item.whereY
	local z = item.whereZ
	if char_settings.general.speedForTravel == true then
		local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
		if speedChar ~= "none" then
			travel.navPause()
			travel.doSpeed(speedChar, speedSkill)
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
	end
	if travel.invisCheck(item, char_settings, class_settings, item.invis) then
		travel.invis(class_settings)
	end
	_G.State:setStatusText("Traveling forward to location: %s %s %s.", y, x, z)
	logger.log_info("\aoTraveling without MQ2Nav to \ag%s, %s, %s\ao.", y, x, z)
	if choice == 1 then
		mq.cmd("/keypress forward hold")
		local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
		logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
		while distance > 5 do
			mq.delay(10)
			distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
			logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
			if _G.State.should_skip == true then
				_G.State.should_skip = false
				return
			end
		end
		mq.cmd("/keypress forward")
	elseif choice == 2 then
		mq.cmd("/dgge /keypress forward hold")
		mq.cmd("/keypress forward hold")
		local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
		logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
		while distance > 5 do
			mq.delay(10)
			distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
			logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
			if _G.State.should_skip == true then
				_G.State.should_skip = false
				return
			end
		end
		mq.cmd("/dgge /keypress forward")
		mq.cmd("/keypress forward")
	else
		mq.cmdf("/dex %s /keypress forward hold", name)
		mq.cmd("/keypress forward hold")
		local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
		logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
		while distance > 5 do
			mq.delay(10)
			distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), x, y)
			logger.log_super_verbose("\aoDistance: \ag%s\ao.", distance)
			if _G.State.should_skip == true then
				_G.State.should_skip = false
				return
			end
		end
		mq.cmdf("/dex %s /keypress forward", name)
		mq.cmd("/keypress forward")
	end
end

-- Open nearest door
---@return boolean
function travel.open_door()
	_G.State:setStatusText("Opening door.")
	mq.delay(200)
	mq.cmd("/doortarget")
	logger.log_info("\aoOpening door: \ar%s%s", mq.TLO.SwitchTarget(), mq.TLO.SwitchTarget.Name())
	mq.delay(200)
	if mq.TLO.Switch.Distance() ~= nil then
		if mq.TLO.Switch.Distance() < 20 then
			mq.cmd("/click left door")
			mq.delay(1000)
			return true
		end
	end
	return false
end

--Check the length of the path between two zones.
---@param start_short string
---@param end_short string
function travel.check_path(start_short, end_short)
	local zone_path = {}
	local start_long = mq.TLO.Zone(start_short)()
	local end_long = mq.TLO.Zone(end_short)()
	mq.TLO.Window("ZoneGuideWnd").DoOpen()
	mq.TLO.Window("ZoneGuideWnd/ZGW_ClearPath_Btn").LeftMouseUp()
	mq.TLO.Window("ZoneGuideWnd/ZGW_ClearZonesSearch_Btn").LeftMouseUp()
	local zone_count = mq.TLO.Window("ZoneGuideWnd/ZGW_Zones_ListBox").Items()
	---@diagnostic disable-next-line: param-type-mismatch
	if mq.TLO.Window("ZoneGuideWnd/ZGW_Zones_ListBox").List(start_long)() ~= nil then
		mq.cmdf(
			"/notify ZoneGuideWnd ZGW_Zones_ListBox Listselect %s",
			---@diagnostic disable-next-line: param-type-mismatch
			mq.TLO.Window("ZoneGuideWnd/ZGW_Zones_ListBox").List(start_long)()
		)
		mq.TLO.Window("ZoneGuideWnd/ZGW_SetStart_Btn").LeftMouseUp()
	end
	---@diagnostic disable-next-line: param-type-mismatch
	if mq.TLO.Window("ZoneGuideWnd/ZGW_Zones_ListBox").List(end_long)() ~= nil then
		mq.cmdf(
			"/notify ZoneGuideWnd ZGW_Zones_ListBox Listselect %s",
			---@diagnostic disable-next-line: param-type-mismatch
			mq.TLO.Window("ZoneGuideWnd/ZGW_Zones_ListBox").List(end_long)()
		)
		mq.TLO.Window("ZoneGuideWnd/ZGW_SetEnd_Btn").LeftMouseUp()
	end
	mq.TLO.Window("ZoneGuideWnd/ZGW_ViewPreviewPath_Btn").LeftMouseUp()
	zone_count = mq.TLO.Window("ZoneGuideWnd/ZGW_ZoneConnection_ListBox").Items()
	for i = 1, zone_count do
		local temp = {}
		temp.start_zone = mq.TLO.Window("ZoneGuideWnd/ZGW_ZoneConnection_ListBox").List(i, 1)()
		temp.end_zone = mq.TLO.Window("ZoneGuideWnd/ZGW_ZoneConnection_ListBox").List(i, 2)()
		if travel.invalid_connections[temp.start_zone] ~= nil then
			for _, to in ipairs(travel.invalid_connections[temp.start_zone]) do
				if temp.end_zone == to then
					logger.log_debug("\aoInvalid connection: \ag%s\ao -> \ag%s\ao.", temp.start_zone, temp.end_zone)
					return 0, nil
				end
			end
		end
		table.insert(zone_path, temp)
	end
	mq.TLO.Window("ZoneGuideWnd").DoClose()
	return zone_count, zone_path
end

-- Loop while traveling to a location
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param ID number|string
function travel.travelLoop(item, class_settings, char_settings, ID)
	local me = mq.TLO.Me
	_G.State:setLocation(me.X(), me.Y(), me.Z())
	ID = ID or 0
	local loopCount = 0
	local distance = 0
	_G.State:clearVelocityTable()
	travel.timeStamp = mq.gettime()
	_G.State.velocity = mq.TLO.Navigation.Velocity()
	while mq.TLO.Navigation.Active() do
		if mq.gettime() - travel.timeStamp > 1000 then
			_G.State:addVelocity(mq.TLO.Navigation.Velocity())
			_G.State.velocity = _G.State:getAverageVelocity()
		end
		mq.delay(200)
		if mq.TLO.EverQuest.GameState() ~= "INGAME" then
			logger.log_error("\arNot in game, closing.")
			mq.exit()
		end
		if mq.TLO.Navigation.Paused() == true then
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
		if _G.State.should_skip == true then
			travel.navPause()
			_G.State.should_skip = false
			return
		end
		if item.zone == nil then
			if _G.Mob.xtargetCheck(char_settings) then
				travel.navPause()
				_G.Mob.clearXtarget(class_settings, char_settings)
				travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
			end
		end
		if _G.State:readPaused() then
			travel.navPause()
			_G.Actions.pauseTask(_G.State:readStatusText())
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
		if char_settings.general.speedForTravel == true then
			local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
			if speedChar ~= "none" then
				travel.navPause()
				travel.doSpeed(speedChar, speedSkill)
				travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
			end
		end
		if travel.invisCheck(item, char_settings, class_settings, item.invis) then
			travel.navPause()
			travel.invis(class_settings)
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
		if loopCount == 10 then
			if item.radius == 1 then
				return
			end
			local temp = _G.State:readStatusText()
			local door = travel.open_door()
			mq.cmd("/keypress Page_Up")
			if door == false then
				---@diagnostic disable-next-line: undefined-field
				if mq.TLO.AutoSize.ResizeSelf() == false then
					mq.cmd("/autosize self on")
				end
				---@diagnostic disable-next-line: undefined-field
				if mq.TLO.AutoSize.Enabled() == false then
					mq.cmd("/autosize on")
					mq.cmdf("/autosize sizeself %s", _G.State.autosize_sizes[_G.State.autosize_choice])
				else
					_G.State.autosize_choice = _G.State.autosize_choice + 1
					if _G.State.autosize_choice == 6 then
						_G.State.autosize_choice = 1
					end
					mq.cmdf("/autosize sizeself %s", _G.State.autosize_sizes[_G.State.autosize_choice])
				end
			end
			loopCount = 0
			_G.State:setStatusText(temp)
		end
		if dist.GetDistance3D(me.X(), me.Y(), me.Z(), _G.State:readLocation()) < 30 then
			loopCount = loopCount + 1
		elseif dist.GetDistance3D(me.X(), me.Y(), me.Z(), _G.State:readLocation()) > 75 then
			logger.log_info("\aoWe seem to have crossed a teleporter, moving to next step.")
			_G.State.destType = ""
			_G.State.dest = ""
			_G.State.is_traveling = false
			---@diagnostic disable-next-line: undefined-field
			if mq.TLO.AutoSize.Enabled() == true then
				mq.cmd("/autosize off")
			end
			travel.navPause()
			_G.State:setLocation(me.X(), me.Y(), me.Z())
			return
		else
			_G.State:setLocation(me.X(), me.Y(), me.Z())
			loopCount = 0
			---@diagnostic disable-next-line: undefined-field
			if mq.TLO.AutoSize.Enabled() == true then
				mq.cmd("/autosize off")
			end
		end
	end
	if ID ~= 0 then
		local spawn = mq.TLO.Spawn(ID)
		distance = dist.GetDistance3D(me.X(), me.Y(), me.Z(), spawn.X(), spawn.Y(), spawn.Z())
	elseif item.whereX ~= 0 then
		distance = dist.GetDistance3D(me.X(), me.Y(), me.Z(), item.whereX, item.whereY, item.whereZ)
	end
	if distance > 30 and item.radius == nil then
		logger.log_warn("\aoStopped before reaching our destination. Attempting to restart navigation.")
		_G.State:handle_step_change(_G.State.current_step)
	end
	logger.log_verbose("\aoWe have reached our destination.")
	_G.State.destType = ""
	_G.State.dest = ""
	_G.State.is_traveling = false
	---@diagnostic disable-next-line: undefined-field
	if mq.TLO.AutoSize.Enabled() == true then
		mq.cmd("/autosize off")
	end
end

-- Travel to npc or location
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param ID number|string
---@param choice number
---@param name string
function travel.general_travel(item, class_settings, char_settings, ID, choice, name)
	ID = ID or _G.Mob.findNearestName(item.npc, item, class_settings, char_settings) or 0
	if char_settings.general.speedForTravel == true then
		local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
		if speedChar ~= "none" then
			travel.navPause()
			travel.doSpeed(speedChar, speedSkill)
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
	end
	if travel.invisCheck(item, char_settings, class_settings, item.invis) then
		travel.invis(class_settings)
	end
	_G.State:setStatusText("Waiting for %s.", item.npc)
	logger.log_info("\aoLooking for \ag%s\ao.", item.npc)
	while ID == 0 or ID == nil do
		mq.delay(500)
		if _G.State.should_skip == true then
			travel.navPause()
			_G.State.should_skip = false
			return
		end
		if _G.State:readPaused() then
			travel.navPause()
			_G.Actions.pauseTask(_G.State:readStatusText())
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
		ID = _G.Mob.findNearestName(item.npc, item, class_settings, char_settings) or 0
	end
	_G.State:setStatusText("Navigating to %s.", item.npc)
	if ID == 0 then
		ID = _G.Mob.findNearestName(item.npc, item, class_settings, char_settings) or 0
	end
	if
		dist.GetDistance3D(
			mq.TLO.Spawn(ID).X(),
			mq.TLO.Spawn(ID).Y(),
			mq.TLO.Spawn(ID).Z(),
			mq.TLO.Me.X(),
			mq.TLO.Me.Y(),
			mq.TLO.Me.Z()
		) < 10
	then
		logger.log_debug("\aoDistance to \ag%s \aois less than 10. Not traveling.", item.npc)
	end
	logger.log_info("\aoNavigating to \ag%s \ao(\ag%s\ao).", item.npc, ID)
	if choice == 1 then
		mq.cmdf("/nav id %s", ID)
	elseif choice == 2 then
		mq.cmdf("/dgga /nav id %s", ID)
	else
		mq.cmdf("/nav id %s", ID)
		mq.cmdf("/dex %s /nav id %s", name, ID)
	end
	_G.State.startDist = mq.TLO.Navigation.PathLength("id " .. ID)()
	_G.State.destType = "ID"
	_G.State.dest = ID
	mq.delay(200)
	travel.travelLoop(item, class_settings, char_settings, ID)
end

-- Use invis
---@param class_settings Class_Settings_Settings
function travel.invis(class_settings)
	local choice, name = _G.State:readGroupSelection()
	local temp = _G.State:readStatusText()
	_G.State:setStatusText("Using invis.")
	logger.log_info("\aoUsing invisibility.")
	local invis_type = {}
	if mq.TLO.Me.Combat() == true then
		mq.cmd("/attack off")
	end
	for word in string.gmatch(class_settings.class_invis[mq.TLO.Me.Class()], "([^|]+)") do
		table.insert(invis_type, word)
	end
	if mq.TLO.Me.Invis() == false then
		logger.log_debug("\aoI am using \ag%s \aoto invis myself.", invis_type[class_settings.invis[mq.TLO.Me.Class()]])
		if invis_type[class_settings.invis[mq.TLO.Me.Class()]] == "Potion" then
			logger.log_super_verbose("\aoUsing a cloudy potion.")
			mq.cmd('/useitem "Cloudy Potion"')
		elseif invis_type[class_settings.invis[mq.TLO.Me.Class()]] == "Circlet of Shadows" then
			logger.log_super_verbose("\aoUsing Circlet of Shadows.")
			mq.cmd('/useitem "Circlet of Shadows"')
		elseif invis_type[class_settings.invis[mq.TLO.Me.Class()]] == "Hide/Sneak" then
			logger.log_super_verbose("\aoUsing hide/sneak.")
			while mq.TLO.Me.Invis() == false do
				mq.delay(100)
				if mq.TLO.Me.AbilityReady("Hide")() == true then
					mq.cmd("/doability hide")
				end
			end
			if mq.TLO.Me.Sneaking() == false then
				while mq.TLO.Me.Sneaking() == false do
					mq.delay(100)
					if mq.TLO.Me.AbilityReady("Sneak")() == true then
						mq.cmd("/doability sneak")
					end
				end
			end
		else
			local ID = class_settings["skill_to_num"][invis_type[class_settings.invis[mq.TLO.Me.Class()]]]
			logger.log_super_verbose(
				"\aoUsing alt ability \ag%s \ao(\ag%s\ao).",
				invis_type[class_settings.invis[mq.TLO.Me.Class()]],
				ID
			)
			while mq.TLO.Me.AltAbilityReady(ID)() == false do
				mq.delay(50)
			end
			mq.cmdf("/alt act %s", ID)
			mq.delay(750)
			while mq.TLO.Me.Casting() and mq.TLO.Me.Class() ~= "Bard" do
				mq.delay(200)
			end
		end
	end
	if choice == 1 then
	elseif choice == 2 then
		for i = 1, mq.TLO.Group.Members() do
			invis_type = {}
			if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
				if mq.TLO.Group.Member(i).Invis() == false then
					for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(i).Class()], "([^|]+)") do
						table.insert(invis_type, word)
					end
					logger.log_debug(
						"\aoUsing \ag%s \aoon \ag%s \aoto invis them.",
						invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]],
						mq.TLO.Group.Member(i).DisplayName()
					)
					if invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == "Potion" then
						mq.cmdf(
							"/dquery %s -q FindItem[Cloudy Potion].TimerReady",
							mq.TLO.Group.Member(i).DisplayName()
						)
						if mq.TLO.DanNet.Query() == "TRUE" then
							logger.log_super_verbose(
								"\aoHaving \ag%s \aouse a cloudy potion.",
								mq.TLO.Group.Member(i).DisplayName()
							)
							mq.cmdf('/dex %s /useitem "Cloudy Potion"', mq.TLO.Group.Member(i).DisplayName())
						end
					elseif invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == "Hide/Sneak" then
						logger.log_super_verbose(
							"\aoHaving \ag%s \aouse hide/sneak.",
							mq.TLO.Group.Member(i).DisplayName()
						)
						mq.cmdf("/dquery %s -q Me.Sneaking", mq.TLO.Group.Member(i).DisplayName())
						if mq.TLO.DanNet.Query() == "FALSE" then
							mq.cmdf("/dobserve %s -q Me.AbilityReady[Sneak]", mq.TLO.Group.Member(i).DisplayName())
							while
								mq.TLO.DanNet(mq.TLO.Group.Member(i).DisplayName()).Observe("Me.AbilityReady[Sneak]")()
								== "FALSE"
							do
								mq.delay(50)
							end
							mq.cmdf("/dex %s /doability sneak", mq.TLO.Group.Member(i).DisplayName())
							mq.cmdf(
								"/dobserve %s -q Me.AbilityReady[Sneak] -drop",
								mq.TLO.Group.Member(i).DisplayName()
							)
						end
						if mq.TLO.Group.Member(i).Invis() == false then
							mq.cmdf("/dobserve %s -q Me.AbilityReady[Hide]", mq.TLO.Group.Member(i).DisplayName())
							while
								mq.TLO.DanNet(mq.TLO.Group.Member(i).DisplayName()).Observe("Me.AbilityReady[Hide]")()
								== "FALSE"
							do
								mq.delay(50)
							end
							mq.cmdf("/dex %s /doability hide", mq.TLO.Group.Member(i).DisplayName())
							mq.cmdf("/dobserve %s -q Me.AbilityReady[Hide] -drop", mq.TLO.Group.Member(i).DisplayName())
						end
					elseif invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]] == "Circlet of Shadows" then
						logger.log_super_verbose(
							"\aoHaving \ag%s \aouse circlet of shadows.",
							mq.TLO.Group.Member(i).DisplayName()
						)
						mq.cmdf('/dex %s /useitem "Circlet of Shadows"', mq.TLO.Group.Member(i).DisplayName())
					else
						local ID = class_settings["skill_to_num"][invis_type[class_settings.invis[mq.TLO.Group
						.Member(i)
						.Class()]]]
						logger.log_super_verbose(
							"\aoHaving \ag%s \aouse \ag%s \ao(\ag%s\ao).",
							mq.TLO.Group.Member(i).DisplayName(),
							invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]],
							ID
						)
						mq.cmdf('/dex %s /alt act "%s"', mq.TLO.Group.Member(i).DisplayName(), ID)
					end
				end
			end
		end
		mq.delay("4s")
	else
		if mq.TLO.Group.Member(name)() ~= nil then
			for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(name).Class()], "([^|]+)") do
				table.insert(invis_type, word)
			end
			if invis_type[class_settings.invis[mq.TLO.Group.Member(name).Class()]] == "Potion" then
				logger.log_super_verbose("\aoHaving \ag%s \aouse a cloudy potion.", name)
				mq.cmdf('/dex %s /useitem "Cloudy Potion"', name)
			elseif invis_type[class_settings.invis[mq.TLO.Group.Member(name).Class()]] == "Hide/Sneak" then
				logger.log_super_verbose("\aoHaving \ag%s \aouse hide/sneak.", name)
				mq.cmdf("/dquery %s -q Me.Sneaking", name)
				if mq.TLO.DanNet.Query() == "FALSE" then
					mq.cmdf("/dobserve %s -q Me.AbilityReady[Sneak] -drop", name)
					while mq.TLO.DanNet(name).Observe("Me.AbilityReady[Sneak]")() == "FALSE" do
						mq.delay(50)
					end
					mq.cmdf("/dex %s /doability sneak", name)
					mq.cmdf("/dobserve %s -q Me.AbilityReady[Sneak] -drop", name)
				end
				if mq.TLO.Group.Member(name).Invis() == false then
					mq.cmdf("/dobserve %s -q Me.AbilityReady[Hide] -drop", name)
					while mq.TLO.DanNet(name).Observe("Me.AbilityReady[Hide]")() == "FALSE" do
						mq.delay(50)
					end
					mq.cmdf("/dex %s /doability hide", name)
				end
			else
				local ID =
					class_settings["skill_to_num"][invis_type[class_settings.invis[mq.TLO.Group.Member(name).Class()]]]
				logger.log_super_verbose(
					"\aoHaving \ag%s \aouse \ag%s \ao(\ag%s\ao).",
					name,
					invis_type[class_settings.invis[mq.TLO.Group.Member(name).Class()]],
					ID
				)
				mq.cmdf('/dex %s /alt act "%s"', name, ID)
			end
		end
		mq.delay("4s")
	end
	mq.delay("1s")
	_G.State:setStatusText(temp)
end

--Check if we have group invis options
---@param char_settings Char_Settings_SaveState
---@param class_settings Class_Settings_Settings
---@param invis number
---@param choice number
---@param name string
---@return Group_Invis_Choice
function travel.groupInvisCheck(char_settings, class_settings, invis, choice, name)
	---@type Group_Invis_Choice
	local invisChoice = {
		["name"] = "",
		["class"] = "",
		["skill"] = 0,
	}
	if choice == 2 then
		local class = mq.TLO.Me.Class()
		---@type Group_Invis_Item[]
		local groupInvisTable = {}
		if _G.Common.match_list(class, { "Bard", "Ranger", "Druid", "Enchanter", "Magician", "Wizard", "Shaman" }) then
			groupInvisTable[#groupInvisTable + 1] = {
				["name"] = "me",
				["class"] = class,
			}
		end
		local distance = 0
		for i = 1, mq.TLO.Group.Members() do
			distance = math.max(distance, mq.TLO.Group.Member(i).Distance3D())
			name = mq.TLO.Group.Member(i).CleanName()
			class = mq.TLO.Group.Member(i).Class()
			if
				_G.Common.match_list(class, { "Bard", "Ranger", "Druid", "Enchanter", "Magician", "Wizard", "Shaman" })
			then
				logger.log_super_verbose("\aoWe found a %s in the group.", class)
				groupInvisTable[#groupInvisTable + 1] = {
					["name"] = name,
					["class"] = class,
				}
			end
		end
		for _, gInvis in ipairs(groupInvisTable) do
			--Return if we find a bard
			if gInvis.class == "Bard" then
				if invisChoice.class == "Bard" then
					--Do fuck all
				else
					invisChoice.name = gInvis.name
					invisChoice.class = gInvis.class
				end
			end
			if _G.Common.match_list(gInvis.class, { "Enchanter", "Magician", "Wizard" }) then
				if _G.Common.match_list(invisChoice.class, { "Enchanter", "Magician", "Wizard", "Bard" }) then
					--Do fuck all
				else
					invisChoice.name = gInvis.name
					invisChoice.class = gInvis.class
				end
			end
			if _G.Common.match_list(gInvis.class, { "Druid", "Ranger" }) then
				if
					_G.Common.match_list(invisChoice.class, { "Enchanter", "Magician", "Wizard", "Druid", "Ranger" })
				then
					--Do fuck all
				else
					invisChoice.name = gInvis.name
					invisChoice.class = gInvis.class
				end
			end
			if gInvis.class == "Shaman" then
				if
					_G.Common.match_list(
						invisChoice.class,
						{ "Enchanter", "Magician", "Wizard", "Druid", "Ranger", "Shaman" }
					)
				then
					--Do fuck all
				else
					invisChoice.name = gInvis.name
					invisChoice.class = gInvis.class
				end
			end
		end
		if distance < 100 then
			if invisChoice.class == "Bard" then
				invisChoice.skill = SHAURIS_BUFF
			elseif _G.Common.match_list(invisChoice.class, { "Enchanter", "Magician", "Wizard" }) then
				invisChoice.skill = GROUP_PERFECTED_INVIS
			elseif _G.Common.match_list(invisChoice.class, { "Druid", "Ranger" }) then
				invisChoice.skill = SHARED_CAMO_BUFF
			end
		end
		if distance < 50 then
			if invisChoice.class == "Shaman" then
				invisChoice.skill = GROUP_SILENT_PRESENCE
			end
		end
	else
		local classDriver = mq.TLO.Me.Class()
		local classFollower = mq.TLO.Group.Member(name).Class()
		local distance = mq.TLO.Group.Member(name).Distance3D()
		if distance < 100 then
			--Bard
			if classDriver == "Bard" then
				invisChoice.name = "me"
				invisChoice.class = "Bard"
				invisChoice.skill = SHAURIS_BUFF
			end
			if classFollower == "Bard" then
				invisChoice.name = name
				invisChoice.class = "Bard"
				invisChoice.skill = SHAURIS_BUFF
			end
			--Enchanter/Magician/Wizard
			if _G.Common.match_list(classDriver, { "Enchanter", "Magician", "Wizard" }) then
				invisChoice.name = "me"
				invisChoice.class = mq.TLO.Me.Class()
				invisChoice.skill = GROUP_PERFECTED_INVIS
			end
			if _G.Common.match_list(classFollower, { "Enchanter", "Magician", "Wizard" }) then
				invisChoice.name = name
				invisChoice.class = mq.TLO.Group.Member(name).Class()
				invisChoice.skill = GROUP_PERFECTED_INVIS
			end
			--Druid/Ranger
			if _G.Common.match_list(classDriver, { "Druid", "Ranger" }) then
				invisChoice.name = "me"
				invisChoice.class = mq.TLO.Me.Class()
				invisChoice.skill = SHARED_CAMO_BUFF
			end
			if _G.Common.match_list(classFollower, { "Druid", "Ranger" }) then
				invisChoice.name = name
				invisChoice.class = mq.TLO.Group.Member(name).Class()
				invisChoice.skill = SHARED_CAMO_BUFF
			end
		end
		if distance < 50 then
			--Shaman
			if classDriver == "Shaman" then
				invisChoice.name = name
				invisChoice.class = "Shaman"
				invisChoice.skill = GROUP_SILENT_PRESENCE
			end
			if classFollower == "Shaman" then
				invisChoice.name = "me"
				invisChoice.class = "Shaman"
				invisChoice.skill = GROUP_SILENT_PRESENCE
			end
		end
	end
	-- check if skill is ready
	if invisChoice.name == "me" then
		if mq.TLO.Me.AltAbilityReady(invisChoice.skill)() then
			logger.log_verbose("\aoGroup invis skill \ag%s will be cast by \ag%s.", invisChoice.skill, invisChoice.name)
			return invisChoice
		else
			logger.log_debug("\aoNo group invis skill is ready for \ag%s.", invisChoice.name)
			return { ["name"] = "", ["class"] = "", ["skill"] = 0 }
		end
	elseif invisChoice.name ~= "" then
		mq.cmdf("/dquery %s -q Me.AltAbilityReady[%s]", invisChoice.name, invisChoice.skill)
		if mq.TLO.DanNet.Q() ~= "FALSE" then
			logger.log_verbose(
				"\aoGroup invis skill \ag%s \aowill be cast by \ag%s.",
				invisChoice.skill,
				invisChoice.name
			)
			return invisChoice
		else
			logger.log_debug("\aoNo group invis skill is ready for \ag%s.", invisChoice.name)
			return { ["name"] = "", ["class"] = "", ["skill"] = 0 }
		end
	end
	return { ["name"] = "", ["class"] = "", ["skill"] = 0 }
end

--Use a group invisibility skill
---@param item Item
---@param char_settings Char_Settings_SaveState
---@param class_settings Class_Settings_Settings
---@param invisChoice Group_Invis_Choice
function travel.groupInvis(item, char_settings, class_settings, invisChoice)
	travel.navPause()
	if invisChoice.name == "me" then
		mq.cmdf("/alt act %s", invisChoice.skill)
		mq.delay(500)
		while mq.TLO.Me.Casting() do
			mq.delay(200)
		end
	else
		mq.cmdf("/dex %s /alt act %s", invisChoice.name, invisChoice.skill)
		while mq.TLO.Group.Member(invisChoice.name).Casting() do
			mq.delay(200)
		end
	end
	travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
end

-- Check if we are invis, or if we should be
---@param item Item
---@param char_settings Char_Settings_SaveState
---@param class_settings Class_Settings_Settings
---@param invis number
---@return boolean
function travel.invisCheck(item, char_settings, class_settings, invis)
	local choice, name = _G.State:readGroupSelection()
	if choice > 1 and char_settings.general["useGroupInvis"] == true and invis == 1 then
		local need_invis = false
		if mq.TLO.Me.Invis() == false then
			need_invis = true
		end
		if choice == 2 and need_invis == false then
			for i = 1, mq.TLO.Group.Members() do
				if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
					if mq.TLO.Group.Member(i).Invis() == false then
						need_invis = true
						break
					end
				end
			end
		end
		if choice > 2 and need_invis == false then
			if mq.TLO.Group.Member(name).Invis() == false then
				need_invis = true
			end
		end
		if travel.GroupZoneCheck(choice, name) == false then
			return false
		end
		if need_invis == true then
			logger.log_debug("\aoChecking if we should use a group invis skill.")
			local invisChoice = travel.groupInvisCheck(char_settings, class_settings, invis, choice, name)
			if invisChoice.skill ~= 0 then
				logger.log_debug("\aoUsing group invisibility instead of single target.")
				travel.groupInvis(item, char_settings, class_settings, invisChoice)
				return false
			end
		end
	end
	logger.log_super_verbose("\aoChecking if we should be invis.")
	if invis == 1 and char_settings.general.invisForTravel == true then
		local invis_types = {}
		for word in string.gmatch(class_settings.class_invis[mq.TLO.Me.Class()], "([^|]+)") do
			table.insert(invis_types, word)
		end
		local invis_type = invis_types[class_settings.invis[mq.TLO.Me.Class()]]
		if travel.checkInvisReady(invis_type, mq.TLO.Me.CleanName(), class_settings) and mq.TLO.Me.Invis() == false then
			logger.log_super_verbose("\aoYes, we should be invis.")
			return true
		end
		if choice == 2 then
			for i = 1, mq.TLO.Group.Members() do
				if mq.TLO.Group.Member(i).DisplayName() ~= mq.TLO.Me.DisplayName() then
					if mq.TLO.Group.Member(i).Invis() == false then
						invis_type = {}
						for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(i).Class()], "([^|]+)") do
							table.insert(invis_type, word)
						end
						if
							travel.checkInvisReady(
								invis_type[class_settings.invis[mq.TLO.Group.Member(i).Class()]],
								mq.TLO.Group.Member(i).CleanName(),
								class_settings
							)
						then
							logger.log_super_verbose(
								"\aoYes, \ag%s \aoshould be invis.",
								mq.TLO.Group.Member(i).DisplayName()
							)
							return true
						end
					end
				end
			end
		elseif choice > 2 then
			if mq.TLO.Group.Member(name).Invis() == false then
				invis_type = {}
				for word in string.gmatch(class_settings.class_invis[mq.TLO.Group.Member(name).Class()], "([^|]+)") do
					table.insert(invis_type, word)
				end
				if
					travel.checkInvisReady(
						invis_type[class_settings.invis[mq.TLO.Group.Member(name).Class()]],
						name,
						class_settings
					)
				then
					logger.log_super_verbose("\aoYes, \ag%s \aoshould be invis.", name)
					return true
				end
			end
		end
	end
	return false
end

---@param invis_type string
---@param character string
---@param class_settings Class_Settings_Settings
---@return boolean
function travel.checkInvisReady(invis_type, character, class_settings)
	if character == mq.TLO.Me.CleanName() then
		if invis_type == "Potion" then
			if mq.TLO.FindItem("=Cloudy Potion").TimerReady() ~= 0 then
				return false
			end
		elseif invis_type == "Circlet of Shadows" then
			if mq.TLO.FindItem("=Circlet of Shadows").TimerReady() ~= 0 then
				return false
			end
		elseif invis_type == "Hide/Sneak" then
			if mq.TLO.Me.AbilityReady("Sneak")() == false then
				return false
			end
			if mq.TLO.Me.AbilityReady("Hide")() == false then
				return false
			end
		else
			local aaNum = class_settings["skill_to_num"][invis_type]
			if mq.TLO.Me.AltAbilityReady(aaNum)() == false then
				return false
			end
		end
	else
		if invis_type == "Potion" then
			mq.cmdf('/dquery %s -q Me.ItemReady["Cloudy Potion"]', character)
			if mq.TLO.DanNet.Query() == "FALSE" then
				return false
			end
		elseif invis_type == "Circlet of Shadows" then
			mq.cmdf('/dquery %s -q Me.ItemReady["Circlet of Shadows"]', character)
			if mq.TLO.DanNet.Query() == "FALSE" then
				return false
			end
		elseif invis_type == "Hide/Sneak" then
			mq.cmdf("/dquery %s -q Me.AbilityReady[Sneak]", character)
			if mq.TLO.DanNet.Query() == "FALSE" then
				return false
			end
			mq.cmdf("/dquery %s -q Me.AbilityReady[Hide]", character)
			if mq.TLO.DanNet.Query() == "FALSE" then
				return false
			end
		else
			local aaNum = class_settings["skill_to_num"][invis_type]
			mq.cmdf("/dquery %s -q Me.AltAbilityReady[%s]", character, aaNum)
			if mq.TLO.DanNet.Query() == "FALSE" then
				return false
			end
		end
	end
	return true
end

-- Check if we have a class with a travel speed buff
---@param class string
---@param class_settings Class_Settings_Settings
---@param level number
---@return boolean
function travel.gotSpeedyClass(class, class_settings, level)
	if class == "Bard" and level < 76 then
		return false
	end
	if (class == "Shaman" or class == "Druid" or class == "Ranger") and level < 85 then
		return false
	end
	for _, speedy in ipairs(speed_classes) do
		if class == speedy then
			local speed_type = {}
			for word in string.gmatch(class_settings.move_speed[class], "([^|]+)") do
				table.insert(speed_type, word)
			end
			local speed_skill = speed_type[class_settings.speed[class]]
			return speed_skill ~= nil
		end
	end
	return false
end

-- Check if we are missing a travel speed buff, and should have one applied
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@return string, number|string
function travel.speedCheck(class_settings, char_settings)
	local choice, name = _G.State:readGroupSelection()
	if choice > 1 then
		if travel.GroupZoneCheck(choice, name) == false then
			return "none", "none"
		end
	end
	logger.log_super_verbose("\aoChecking if we are missing travel speed buff.")
	for _, buff in ipairs(speed_buffs) do
		if mq.TLO.Me.Buff(buff)() then
			logger.log_super_verbose("\aoWe currently have a travel speed buff active: \ag%s\ao.", buff)
			return "none", "none"
		end
	end
	local amSpeedy = false
	local aanums = {}
	local foundSpeed = false
	if choice == 1 then
		local class = mq.TLO.Me.Class()
		amSpeedy = travel.gotSpeedyClass(class, class_settings, mq.TLO.Me.Level())
		if amSpeedy == false then
			logger.log_verbose("\aoWe do not have a travel speed buff to cast.")
			return "none", "none"
		else
			local speed_type = {}
			for word in string.gmatch(class_settings.move_speed[class], "([^|]+)") do
				table.insert(speed_type, word)
			end
			local speed_skill = speed_type[class_settings.speed[class]]
			logger.log_verbose("\agI \aocan cast \ag%s\ao.", speed_skill)
			if speed_skill == "Spirit of Eagle" then
				if class == "Ranger" then
					speed_skill = "Spirit of Eagle(Ranger)"
				end
				if class == "Druid" then
					speed_skill = "Spirit of Eagles(Druid)"
				end
			end
			local aaNum = class_settings["speed_to_num"][speed_skill]
			if mq.TLO.Me.AltAbilityReady(aaNum)() == false then
				return "none", "none"
			end
			return mq.TLO.Me.DisplayName(), aaNum
		end
	elseif choice == 2 then
		for i = 1, mq.TLO.Group.Members() do
			local class = mq.TLO.Group.Member(i).Class()
			amSpeedy = travel.gotSpeedyClass(class, class_settings, mq.TLO.Group.Member(i).Level())
			if amSpeedy == true then
				local speed_type = {}
				for word in string.gmatch(class_settings.move_speed[class], "([^|]+)") do
					table.insert(speed_type, word)
				end
				if speed_type[class_settings.speed[class]] ~= "none" then
					local speed_skill = speed_type[class_settings.speed[class]]
					logger.log_verbose("\ag%s \aocan cast \ag%s\ao.", mq.TLO.Group.Member(i).DisplayName(), speed_skill)
					if speed_skill == "Spirit of Eagle" then
						if class == "Ranger" then
							speed_skill = "Spirit of Eagle(Ranger)"
						end
						if class == "Druid" then
							speed_skill = "Spirit of Eagles(Druid)"
						end
					end
					local aaNum = class_settings["speed_to_num"][speed_skill]
					aanums[mq.TLO.Group.Member(i).DisplayName()] = aaNum
					mq.cmdf("/dquery %s -q Me.AltAbilityReady[%s]", mq.TLO.Group.Member(i).DisplayName(), aaNum)
					if mq.TLO.DanNet.Q() ~= "FALSE" then
						foundSpeed = true
					end
					--return mq.TLO.Group.Member(i).DisplayName(), aaNum
				end
			end
		end
		if foundSpeed == false then
			logger.log_verbose("\aoWe do not have a travel speed buff to cast.")
			return "none", "none"
		else
			local aaNum = 0
			local casterName = ""
			for names, num in pairs(aanums) do
				if num == SELOS_BUFF then
					aaNum = num
					casterName = names
					break
				elseif num == CHEETAH_BUFF and aaNum ~= SELOS_BUFF then
					aaNum = num
					casterName = names
				elseif
					(num == SPIRIT_FALCONS_BUFF or num == FLIGHT_FALCONS_BUFF or num == SPIRIT_EAGELE_BUFF)
					and aaNum ~= SELOS_BUFF
					and aaNum ~= CHEETAH_BUFF
				then
					aaNum = num
					casterName = names
				end
			end
			return casterName, aaNum
		end
	else
		local aaNum = 0
		local casterName = ""
		local class = mq.TLO.Me.Class()
		amSpeedy = travel.gotSpeedyClass(class, class_settings, mq.TLO.Me.Level())
		if amSpeedy == true then
			local speed_type = {}
			for word in string.gmatch(class_settings.move_speed[class], "([^|]+)") do
				table.insert(speed_type, word)
			end
			local speed_skill = speed_type[class_settings.speed[class]]
			logger.log_verbose("\agI \aocan cast \ag%s\ao.", speed_skill)
			if speed_skill == "Spirit of Eagle" then
				if class == "Ranger" then
					speed_skill = "Spirit of Eagle(Ranger)"
				end
				if class == "Druid" then
					speed_skill = "Spirit of Eagles(Druid)"
				end
			end
			aaNum = class_settings["speed_to_num"][speed_skill]
			casterName = mq.TLO.Me.DisplayName()
			if mq.TLO.Me.AltAbilityReady(aaNum)() == false then
				amSpeedy = false
				aaNum = 0
				casterName = "none"
			end
			--return mq.TLO.Me.DisplayName(), aaNum
		end
		if aaNum == SELOS_BUFF then
			return casterName, aaNum
		end
		aanums[mq.TLO.Me.DisplayName()] = aaNum
		class = mq.TLO.Group.Member(name).Class()
		amSpeedy = travel.gotSpeedyClass(class, class_settings, mq.TLO.Group.Member(name).Level())
		if amSpeedy == true then
			local speed_type = {}
			for word in string.gmatch(class_settings.move_speed[class], "([^|]+)") do
				table.insert(speed_type, word)
			end
			local speed_skill = speed_type[class_settings.speed[class]]
			logger.log_verbose("\ag%s \aocan cast \ag%s\ao.", name, speed_skill)
			if speed_skill == "Spirit of Eagle" then
				if class == "Ranger" then
					speed_skill = "Spirit of Eagle(Ranger)"
				end
				if class == "Druid" then
					speed_skill = "Spirit of Eagles(Druid)"
				end
			end
			aaNum = class_settings["speed_to_num"][speed_skill]
			aanums[name] = aaNum
			for names, num in pairs(aanums) do
				if num == SELOS_BUFF then
					aaNum = num
					casterName = names
					break
				elseif num == CHEETAH_BUFF and aaNum ~= SELOS_BUFF then
					aaNum = num
					casterName = names
				elseif
					(num == SPIRIT_FALCONS_BUFF or num == FLIGHT_FALCONS_BUFF or num == SPIRIT_EAGELE_BUFF)
					and aaNum ~= SELOS_BUFF
					and aaNum ~= CHEETAH_BUFF
				then
					aaNum = num
					casterName = names
				end
			end
			mq.cmdf("/dquery %s -q Me.AltAbilityReady[%s]", casterName, aaNum)
			if mq.TLO.DanNet.Q() == "FALSE" then
				return "none", "none"
			end
			return casterName, aaNum
		else
			logger.log_verbose("\aoWe do not have a travel speed buff to cast.")
			return "none", "none"
		end
	end
end

-- Use the travel speed buff we found
---@param name string
---@param aaNum number|string
function travel.doSpeed(name, aaNum)
	if name == "none" then
		return
	end
	if name == mq.TLO.Me.DisplayName() then
		logger.log_verbose("\aoI am using my travel speed skill.")
		if mq.TLO.Me.Class() == "Ranger" then
			mq.TLO.Me.DoTarget()
			while mq.TLO.Target.DisplayName() ~= mq.TLO.Me.DisplayName() do
				mq.delay(200)
			end
		end
		mq.delay(500)
		mq.cmdf("/alt act %s", aaNum)
		mq.delay(500)
		while mq.TLO.Me.Casting() and mq.TLO.Me.Class() ~= "Bard" do
			mq.delay(200)
		end
	else
		logger.log_verbose("\aoHaving \ag%s \aouse their travel speed skill.", name)
		mq.delay(500)
		mq.cmdf("/dex %s /alt act %s", name, aaNum)
		mq.delay(500)
		while mq.TLO.Spawn(name).Casting() do
			mq.delay(200)
		end
	end
end

-- Travel to the indicated location
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param choice number
---@param name string
function travel.loc_travel(item, class_settings, char_settings, choice, name)
	local x = item.whereX
	local y = item.whereY
	local z = item.whereZ
	if dist.GetDistance3D(x, y, z, mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z()) < 10 then
		logger.log_debug("\aoDistance to \ag%s %s %s \aois less than 10, not moving.", y, x, z)
		return
	end
	_G.State:setStatusText("Traveling to location: %s %s %s.", y, x, z)
	logger.log_info("\aoTraveling to location \ag%s, %s, %s\ao.", y, x, z)
	if mq.TLO.Navigation.PathExists("loc " .. y .. " " .. x .. " " .. z) == false then
		_G.State:setStatusText("No path exists to location: %s %s %s.", y, x, z)
		logger.log_error("\aoNo path found to location \ag%s, %s, %s\ao.", y, x, z)
		_G.State:setTaskRunning(false)
		mq.cmd("/foreground")
		return
	end
	_G.State.is_traveling = true
	if choice == 1 then
		mq.cmdf("/nav loc %s %s %s", y, x, z)
	elseif choice == 2 then
		mq.cmdf("/dgga /nav loc %s %s %s", y, x, z)
	else
		mq.cmdf("/nav loc %s %s %s", y, x, z)
		mq.cmdf("/dex %s /nav loc %s %s %s", name, y, x, z)
	end
	local tempString = string.format("loc %s %s %s", y, x, z)
	_G.State.startDist = mq.TLO.Navigation.PathLength(tempString)()
	_G.State.destType = "loc"
	_G.State.dest = string.format("%s %s %s", y, x, z)
	mq.delay(100)
	travel.travelLoop(item, class_settings, char_settings, 0)
end

-- Pause navigation
function travel.navPause()
	local choice, name = _G.State:readGroupSelection()
	logger.log_info("\aoPausing navigation.")
	if choice == 1 then
		mq.cmd("/nav pause")
	elseif choice == 2 then
		mq.cmd("/dgga /nav pause")
	else
		mq.cmd("/nav pause")
		mq.cmdf("/dex %s /nav pause", name)
	end
	mq.delay(500)
end

-- Unpause navigation
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param choice number
---@param name string
function travel.navUnpause(item, class_settings, char_settings, choice, name)
	if item.whereX then
		local x = item.whereX
		local y = item.whereY
		local z = item.whereZ
		logger.log_info("\aoResuming navigation to location \ag%s, %s, %s\ao.", y, x, z)
		if choice == 1 then
			mq.cmdf("/nav loc %s %s %s", y, x, z)
		elseif choice == 2 then
			mq.cmdf("/dgga /nav loc %s %s %s", y, x, z)
		else
			mq.cmdf("/nav loc %s %s %s", y, x, z)
			mq.cmdf("/dex %s /nav loc %s %s %s", name, y, x, z)
		end
		local tempString = string.format("loc %s %s %s", y, x, z)
		_G.State.startDist = mq.TLO.Navigation.PathLength(tempString)()
		_G.State.destType = "loc"
		_G.State.dest = string.format("%s %s %s", y, x, z)
	elseif item.npc then
		logger.log_info("\aoResuming navigation to \ag%s\ao.", item.npc)
		if choice == 1 then
			mq.cmdf("/nav spawn %s", item.npc)
		elseif choice == 2 then
			mq.cmdf("/dgga /nav spawn %s", item.npc)
		else
			mq.cmdf("/nav spawn %s", item.npc)
			mq.cmdf("/dex %s /nav spawn %s", name, item.npc)
		end
		local tempString = string.format("spawn %s ", item.npc)
		_G.State.startDist = mq.TLO.Navigation.PathLength(tempString)()
		_G.State.destType = "spawn"
		_G.State.dest = item.npc
	elseif item.zone then
		logger.log_info("\aoResuming navigation to zone \ag%s\ao.", item.zone)
		if choice == 1 then
			mq.cmdf("/travelto %s", item.zone)
		elseif choice == 2 then
			mq.cmdf("/dgga /travelto %s", item.zone)
		else
			mq.cmdf("/travelto %s", item.zone)
			mq.cmdf("/dex %s /travelto %s", name, item.zone)
		end
	elseif item.what then
		logger.log_info("\aoResuming navigation to \ag%s\ao.", item.what)
		mq.cmdf("/itemtarget %s", item.what)
		mq.delay(100)
		mq.cmdf("/nav item")
	end
	mq.delay(500)
end

-- Event checking for the indicated phrase to stop following
function travel.follow_event()
	travel.looping = false
end

-- Folow the indicated NPC. Can follow to location, until event, or until otherwise stopped
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param event boolean
---@param choice number
---@param name string
function travel.npc_follow(item, class_settings, char_settings, event, choice, name)
	event = event or false
	if _G.Mob.xtargetCheck(char_settings) then
		travel.navPause()
		_G.Mob.clearXtarget(class_settings, char_settings)
		travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
	end
	if char_settings.general.speedForTravel == true then
		local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
		if speedChar ~= "none" then
			travel.navPause()
			travel.doSpeed(speedChar, speedSkill)
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
	end
	if travel.invisCheck(item, char_settings, class_settings, item.invis) then
		travel.invis(class_settings)
	end
	_G.State:setStatusText("Following %s.", item.npc)
	logger.log_info("\aoFollowing \ag%s\ao.", item.npc)
	if mq.TLO.Spawn("npc " .. item.npc).Distance() ~= nil then
		if mq.TLO.Spawn("npc " .. item.npc).Distance() > 100 then
			logger.log_warn(
				"\ar%s \aois over 100 units away. Moving back to step \ar%s\ao.",
				item.npc,
				_G.State.current_step
			)
			_G.State:handle_step_change(_G.State.current_step - 1)
			return
		end
	end
	if choice == 1 then
		mq.TLO.Spawn("npc " .. item.npc).DoTarget()
		mq.delay(300)
		mq.cmd("/afollow")
	elseif choice == 2 then
		mq.cmdf("/dgga /target id %s", mq.TLO.Spawn("npc " .. item.npc).ID())
		mq.delay(300)
		mq.cmd("/dgga /afollow")
	else
		mq.TLO.Spawn("npc " .. item.npc).DoTarget()
		mq.cmdf("/dex %s /target id %s", name, mq.TLO.Spawn("npc " .. item.npc).ID())
		mq.delay(300)
		mq.cmd("/afollow")
		mq.cmdf("/dex %s /afollow", name)
	end
	if item.whereX ~= nil then
		local distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), item.whereX, item.whereY)
		while distance > 50 do
			if _G.State.should_skip == true then
				if choice == 1 then
					mq.cmd("/afollow off")
					_G.State.should_skip = false
					return
				elseif choice == 2 then
					mq.cmd("/dgga /afollow off")
					_G.State.should_skip = false
					return
				else
					mq.cmd("/afollow off")
					mq.cmdf("/dex %s /afollow off", name)
				end
			end
			mq.delay(200)
			distance = dist.GetDistance(mq.TLO.Me.X(), mq.TLO.Me.Y(), item.whereX, item.whereY)
		end
		logger.log_info("\aoWe have reached our destination. Stopping follow.")
		travel.npc_stop_follow(item, choice, name)
	end
	travel.looping = true
	if event == true then
		mq.event("follow_event", item.phrase, travel.follow_event)
		while travel.looping == true do
			mq.delay(100)
			mq.doevents()
			if _G.Mob.xtargetCheck(char_settings) then
				mq.cmd("/afollow off")
				_G.Mob.clearXtarget(class_settings, char_settings)
				mq.TLO.Spawn("npc " .. item.npc).DoTarget()
				mq.delay(300)
				mq.cmd("/afollow")
			end
		end
		mq.cmd("/afollow off")
	end
end

-- Stop following the npc
---@param item Item
---@param choice number
---@param name string
function travel.npc_stop_follow(item, choice, name)
	_G.State:setStatusText("Stopping autofollow.")
	logger.log_info("\aoStopping autofollow.")
	if choice == 1 then
		mq.cmd("/afollow off")
	elseif choice == 2 then
		mq.cmd("/dgga /afollow off")
	else
		mq.cmd("/afollow off")
		mq.cmdf("/dex %s /afollow off", name)
	end
end

-- Travel to the indicated NPC
---@param item Item
---@param class_settings Class_Settings_Settings
---@param ignore_path_check boolean
---@param char_settings Char_Settings_SaveState
function travel.npc_travel(item, class_settings, ignore_path_check, char_settings)
	ignore_path_check = ignore_path_check or false
	if item.zone == nil then
		if _G.Mob.xtargetCheck(char_settings) then
			travel.navPause()
			_G.Mob.clearXtarget(class_settings, char_settings)
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
	end
	if char_settings.general.speedForTravel == true then
		local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
		if speedChar ~= "none" then
			travel.navPause()
			travel.doSpeed(speedChar, speedSkill)
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
	end
	if travel.invisCheck(item, char_settings, class_settings, item.invis) then
		travel.invis(class_settings)
	end
	if item.whereX ~= nil then
		travel.loc_travel(item, class_settings, char_settings, _G.State:readGroupSelection())
	else
		_G.State:setStatusText("Waiting for NPC %s.", item.npc)
		local ID = _G.Mob.findNearestName(item.npc, item, class_settings, char_settings) or 0
		travel.general_travel(item, class_settings, char_settings, ID, _G.State:readGroupSelection())
	end
end

-- Set guild portal to the indicated zone via Mq2PortalSetter
---@param item Item
function travel.portal_set(item)
	_G.State:setStatusText("Setting portal to %s.", item.zone)
	logger.log_info("\aoSetting portal to \ag%s\ao.", item.zone)
	mq.delay("1s")
	mq.cmdf("/portalset %s", item.zone)
	mq.delay("1s")
	while mq.TLO.PortalSetter.InProgress() == true do
		mq.delay(200)
	end
end

-- Find a relocation skill or item that is ready for use
--- @return string
function travel.findReadyRelocate()
	if mq.TLO.Me.AltAbilityReady("Gate")() then
		return "gate"
	end
	if mq.TLO.FindItem("=Drunkard's Stein").Timer() == 0 then
		return "pok"
	end
	if mq.TLO.Me.AltAbilityReady("Throne of Heroes")() then
		return "lobby"
	end
	if mq.TLO.Me.AltAbilityReady("Origin")() then
		return "origin"
	end
	if mq.TLO.FindItem("=Philter of Major Transloation")() then
		return "gate"
	end
	return "none"
end

-- Check if we can relocate (findReadyReloctate) and use MQ2Relocate to do so with the indicated relocation method
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param choice number
---@param name string
---@param relocate string
function travel.relocate(item, class_settings, char_settings, choice, name, relocate)
	local currentZone = mq.TLO.Zone.Name()
	if _G.Mob.xtargetCheck(char_settings) then
		travel.navPause()
		_G.Mob.clearXtarget(class_settings, char_settings)
		travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
	end
	_G.State:setStatusText("Relocating to %s.", relocate)
	logger.log_info("\aoRelocating to \ag%s\ao.", relocate)
	if choice == 1 then
		mq.cmdf("/relocate %s", relocate)
	elseif choice == 2 then
		mq.cmdf("/dgga /relocate %s", relocate)
	else
		mq.cmdf("/relocate %s", relocate)
		mq.cmdf("/dex %s /relocate %s", name, relocate)
	end
	local loopCount = 0
	while mq.TLO.Me.Casting() == nil do
		loopCount = loopCount + 1
		mq.delay(10)
		if _G.State.should_skip == true then
			travel.navPause()
			_G.State.should_skip = false
			return
		end
		if _G.State:readPaused() then
			travel.navPause()
			_G.Actions.pauseTask(_G.State:readStatusText())
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
		if loopCount >= 200 then
			logger.log_warn("\aoSpent 2 seconds waiting for relocate to \ar%s \aoto cast. Moving on.", relocate)
			break
		end
	end
	loopCount = 0
	while mq.TLO.Me.Casting() ~= nil do
		loopCount = loopCount + 1
		mq.delay(500)
		if _G.State.should_skip == true then
			travel.navPause()
			_G.State.should_skip = false
			return
		end
		if _G.State:readPaused() then
			travel.navPause()
			_G.Actions.pauseTask(_G.State:readStatusText())
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
	end
	mq.delay("2s")
	if currentZone == mq.TLO.Zone.Name() then
		logger.log_warn("\aoWe are still in \ag%s \aoattempting to relocate again.", currentZone)
		_G.State:handle_step_change(_G.State.current_step)
		return
	end
end

--Find the shortest path
---@param item Item
---@param char_settings Char_Settings_SaveState
---@return string
function travel.find_best_path(item, char_settings)
	local paths = {}
	--Straight travel
	local distance, path = travel.check_path(mq.TLO.Zone.ShortName(), item.zone)
	if path ~= nil then
		paths[#paths + 1] = {
			["method"] = "straight",
			["path"] = path,
			["distance"] = distance,
		}
	end
	--Lamp
	if mq.TLO.FindItem("Wishing Lamp").TimerReady() == 0 then
		distance, path = travel.check_path("stratos", item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "lamp_stratos",
				["path"] = path,
				["distance"] = distance,
			}
		end
	end
	--Gate
	if
		mq.TLO.Me.AltAbilityReady(1217)() == true
		or (
			mq.TLO.FindItem("=Philter of Major Translocation").TimerReady() == 0
			and char_settings.general["useGatePot"] == true
		)
	then
		distance, path = travel.check_path(mq.TLO.Me.ZoneBound.ShortName(), item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "gate",
				["path"] = path,
				["distance"] = distance,
			}
		end
	end
	--Stein
	if mq.TLO.FindItem("Drunkard's Stein").TimerReady() == 0 then
		distance, path = travel.check_path("poknowledge", item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "stein",
				["path"] = path,
				["distance"] = distance,
			}
		end
	end
	--Slide
	if mq.TLO.FindItem("Zueria Slide").TimerReady() == 0 then
		distance, path = travel.check_path("dreadlands", item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "slide_dreadlands",
				["path"] = path,
				["distance"] = distance,
			}
		end
		distance, path = travel.check_path("greatdivide", item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "slide_greatdivide",
				["path"] = path,
				["distance"] = distance,
			}
		end
		distance, path = travel.check_path("nektulos", item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "slide_nektulos",
				["path"] = path,
				["distance"] = distance,
			}
		end
		distance, path = travel.check_path("nro", item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "slide_nro",
				["path"] = path,
				["distance"] = distance,
			}
		end
		distance, path = travel.check_path("skyfire", item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "slide_skyfire",
				["path"] = path,
				["distance"] = distance,
			}
		end
		distance, path = travel.check_path("stonebrunt", item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "slide_stonebrunt",
				["path"] = path,
				["distance"] = distance,
			}
		end
	end
	--Throne of heroes
	if mq.TLO.Me.AltAbilityReady(511)() == true then
		distance, path = travel.check_path("guildlobby", item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "throne",
				["path"] = path,
				["distance"] = distance,
			}
		end
	end
	--Origin
	if mq.TLO.Me.AltAbilityReady(331)() == true and char_settings.general["useOrigin"] == true then
		distance, path = travel.check_path(mq.TLO.Me.Origin.ShortName(), item.zone)
		if path ~= nil then
			paths[#paths + 1] = {
				["method"] = "origin",
				["path"] = path,
				["distance"] = distance,
			}
		end
	end

	--Table has been populated, now lets pick the best path.
	local shortest_path = 1000
	local shortest_method = ""
	for _, p in pairs(paths) do
		if p.distance < shortest_path then
			shortest_path = p.distance
			shortest_method = p.method
		end
	end
	logger.log_info("\aoSelected path \ag%s\ao. Length: \ag%s", shortest_method, shortest_path)
	return shortest_method
end

-- Travel to the indicated zone. Return to bind first if returnToBind is true and continue is false
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param continue boolean
---@param choice number
---@param name string
function travel.zone_travel(item, class_settings, char_settings, continue, choice, name)
	if continue == false then
		local method = travel.find_best_path(item, char_settings)
		if method == "straight" then
			--do nothing, just travel
		elseif method == "gate" then
			travel.gate_group(choice, name)
		elseif method == "slide_dreadlands" then
			travel.relocate(item, class_settings, char_settings, choice, name, "dreadlands")
		elseif method == "slide_greatdivide" then
			travel.relocate(item, class_settings, char_settings, choice, name, "greatdivide")
		elseif method == "slide_nektulos" then
			travel.relocate(item, class_settings, char_settings, choice, name, "nek")
		elseif method == "slide_nro" then
			travel.relocate(item, class_settings, char_settings, choice, name, "nro")
		elseif method == "slide_skyfire" then
			travel.relocate(item, class_settings, char_settings, choice, name, "skyfire")
		elseif method == "slide_stonebrunt" then
			travel.relocate(item, class_settings, char_settings, choice, name, "stonebrunt")
		elseif method == "stein" then
			travel.relocate(item, class_settings, char_settings, choice, name, "pok")
		elseif method == "throne" then
			travel.relocate(item, class_settings, char_settings, choice, name, "lobby")
		elseif method == "origin" then
			travel.relocate(item, class_settings, char_settings, choice, name, "origin")
		elseif method == "lamp_stratos" then
			travel.relocate(item, class_settings, char_settings, choice, name, "air")
		end
	end
	if char_settings.general.speedForTravel == true then
		local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
		if speedChar ~= "none" then
			travel.navPause()
			travel.doSpeed(speedChar, speedSkill)
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
	end
	if travel.invisCheck(item, char_settings, class_settings, item.invis) then
		travel.navPause()
		travel.invis(class_settings)
		travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
	end
	_G.State:setStatusText("Traveling to %s.", item.zone)
	logger.log_info("\aoTraveling to \ag%s\ao.", item.zone)
	_G.State.is_traveling = true
	if choice == 1 then
		mq.cmdf("/travelto %s", item.zone)
	elseif choice == 2 then
		mq.cmdf("/dgga /travelto %s", item.zone)
	else
		mq.cmdf("/travelto %s", item.zone)
		mq.cmdf("/dex %s /travelto %s", name, item.zone)
	end
	local loopCount = 0
	_G.State:setLocation(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z())
	--[[_G.State.is_traveling = true
    _G.State.destType = 'ZONE'
    if mq.TLO.Navigation.CurrentPathDistance() ~= nil then
        _G.State.startDist = mq.TLO.Navigation.CurrentPathDistance()
    end--]]
	while mq.TLO.Zone.ShortName() ~= item.zone and mq.TLO.Zone.Name() ~= item.zone do
		if mq.TLO.EverQuest.GameState() ~= "INGAME" then
			logger.log_error("\arNot in game, closing.")
			mq.exit()
		end
		if mq.TLO.Navigation.Paused() == true then
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
		if _G.State.should_skip == true then
			travel.navPause()
			_G.State.should_skip = false
			return
		end
		mq.delay(500)
		if _G.Mob.xtargetCheck(char_settings) then
			travel.navPause()
			_G.Mob.clearXtarget(class_settings, char_settings)
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
		if _G.State:readPaused() then
			travel.navPause()
			_G.Actions.pauseTask(_G.State:readStatusText())
			travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
		end
		if char_settings.general.speedForTravel == true then
			local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
			if speedChar ~= "none" then
				travel.navPause()
				travel.doSpeed(speedChar, speedSkill)
				travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
			end
		end
		if travel.invisCheck(item, char_settings, class_settings, item.invis) then
			if travel.invisTranslocatorCheck() == false then
				travel.navPause()
				travel.invis(class_settings)
				travel.navUnpause(item, class_settings, char_settings, _G.State:readGroupSelection())
			end
		end
		if not mq.TLO.Navigation.Active() then
			if loopCount == 30 then
				loopCount = 0
				if mq.TLO.Cursor() ~= nil then
					if mq.TLO.Cursor() == "Spire Stone" then
						mq.cmd("/autoinv")
					end
				end
				if mq.TLO.FindItem("=Spire Stone")() == nil then
					logger.log_info("\aoTravel stopped. Starting travel to \ag%s \aoagain.", item.zone)
					if choice == 1 then
						mq.cmdf("/travelto %s", item.zone)
					elseif choice == 2 then
						mq.cmdf("/dgga /travelto %s", item.zone)
					else
						mq.cmdf("/travelto %s", item.zone)
						mq.cmdf("/dex %s /travelto %s", name, item.zone)
					end
				end
			end
			loopCount = loopCount + 1
		else
			if loopCount == 10 then
				if item.radius == 1 then
					return
				end
				local temp = _G.State:readStatusText()
				local door = travel.open_door()
				if door == false then
					---@diagnostic disable-next-line: undefined-field
					if mq.TLO.AutoSize.ResizeSelf() == false then
						mq.cmd("/autosize self on")
					end
					---@diagnostic disable-next-line: undefined-field
					if mq.TLO.AutoSize.Enabled() == false then
						mq.cmd("/autosize on")
						mq.cmdf("/autosize sizeself %s", _G.State.autosize_sizes[_G.State.autosize_choice])
					else
						_G.State.autosize_choice = _G.State.autosize_choice + 1
						if _G.State.autosize_choice == 6 then
							_G.State.autosize_choice = 1
						end
						mq.cmdf("/autosize sizeself %s", _G.State.autosize_sizes[_G.State.autosize_choice])
					end
				end
				loopCount = 0
				_G.State:setStatusText(temp)
			end
			if dist.GetDistance3D(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z(), _G.State:readLocation()) < 20 then
				loopCount = loopCount + 1
			else
				_G.State:setLocation(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z())
				loopCount = 0
				---@diagnostic disable-next-line: undefined-field
				if mq.TLO.AutoSize.Enabled() == true then
					mq.cmd("/autosize off")
				end
			end
		end
	end
	if choice > 1 then
		logger.log_verbose("\aoInsuring all managed group members are in zone.")
		while travel.GroupZoneCheck(choice, name) == false do
			mq.delay(500)
			if _G.State.should_skip == true then
				_G.State.should_skip = false
				return
			end
		end
		logger.log_debug(
			"\aoAll managed group members are in zone, waiting 5 seconds to allow all characters to load properly."
		)
		mq.delay("5s")
	end
	_G.State.destType = ""
	_G.State.dest = ""
	_G.State.is_traveling = false
	---@diagnostic disable-next-line: undefined-field
	if mq.TLO.AutoSize.Enabled() == true then
		mq.cmd("/autosize off")
	end
end

-- Check if group members are in the same zone as the player
---@param choice number
---@param name string
---@return boolean
function travel.GroupZoneCheck(choice, name)
	if choice == 1 then
		return true
	elseif choice == 2 then
		if mq.TLO.Group.AnyoneMissing() then
			return false
		end
	else
		if mq.TLO.Group.Member(name).OtherZone() then
			return false
		end
	end
	return true
end

-- Check the z loc of the indicated elevator
---@param item Item
function travel.elevator_check(item)
	_G.State:setStatusText("Checking elevator location.")
	logger.log_info("\aoChecking elevator location.")
	if item.npc == "above" then
		if mq.TLO.Switch(item.what).Z() > item.whereZ then
			mq.TLO.Switch(item.enviroslot).Toggle()
		end
		while mq.TLO.Switch(item.what).Z() > item.whereZ do
			mq.delay(75)
		end
	end
end

-- Click the indicated switch
---@param item Item
function travel.click_switch(item)
	_G.State:setStatusText("Clicking switch. (" .. item.what .. ").")
	logger.log_info("\aoClicking switch. (\ag%s\ao).", item.what)
	mq.TLO.Switch(item.what).Toggle()
	mq.delay(500)
end

--Wait until we have reached the indicated location on the z-axis
---@param item Item
function travel.wait_z_loc(item)
	_G.State:setStatusText("Waiting for correct Z location.")
	logger.log_info("\aoWaiting for correct Z location. (\ag%s\ao).", item.whereZ)
	if item.whereZ == nil then
		return
	end
	while math.abs(mq.TLO.Me.Z() - item.whereZ) > 0.5 do
		mq.delay(100)
	end
end

return travel
