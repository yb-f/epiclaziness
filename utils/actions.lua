--[[
	Functions which perform an action within the game
--]]

local mq = require("mq")
local inv = require("utils/inventory")
local manage = require("utils/manageautomation")
local travel = require("utils/travel")
local logger = require("lib/logger")
local dist = require("lib/distance")

local DESIRED_CHIPS = 1900
local MAX_DISTANCE = 100
---@class Actions
local actions = {}

actions.farm_event_triggered = false
local waiting = false
local gamble_done = false
local forage_trash = {
	"Fruit",
	"Roots",
	"Vegetables",
	"Pod of Water",
	"Berries",
	"Rabbit Meat",
	"Fishing Grubs",
	"Brasha Berries",
	"Green Radish",
	"Straggle Grass",
	"Chameleon Rat",
	"Yergan Frog",
	"Spikerattle Fruit",
	"Stonewood Root",
	"Spikerattle Root",
	"Tuf of Fox Fur",
	"Plant Shoot",
	"Shadowjade Fern Leaves",
}
local fishing_trash = {
	"Fish Scales",
	"Tattered Cloth Sandal",
	"Rusty Dagger",
	"Moray Eel",
	"Gunthak Gourami",
	"Deep Sea Urchin",
	"Fresh Fish",
	"Gunthak Mackerel",
	"Saltwater Seaweed",
	"Dark Fish's Scales",
}

-- Event to determine when gambling has reached the desired number of chips for Rogue Pre 1.5
--- @param line string
--- @param arg1 string
local function gamble_event(line, arg1)
	logger.log_info("\aoGambling has reached the desired number of chips. Moving on.")
	gamble_done = true
end

-- Event function to determine if the set line has been received in chat and continue if so
---@param line string
local function event_wait(line)
	logger.log_verbose("\aoEvent Triggered: %s", line)
	waiting = false
	mq.unevent("wait_event")
end

-- Callback to determine if Adventure Window is open
--- @return boolean
function actions.adventure_window()
	return mq.TLO.Window("AdventureRequestWnd").Open()
end

-- Callback to determine if Adventure Accept Button is enabled in Adventure Window
--- @return boolean
function actions.adventure_button()
	return mq.TLO.Window("AdventureRequestWnd/AdvRqst_AcceptButton").Enabled()
end

-- Callback to determine if we have the proper adventure type selected
--- @return boolean
function actions.adventure_type_selection()
	if mq.TLO.Window("AdventureRequestWnd/AdvRqst_TypeCombobox").GetCurSel() == 3 then
		return true
	end
	return false
end

-- Callback to determine if the proper difficulty is selected
---@return boolean
function actions.adventure_risk_selection()
	if mq.TLO.Window("AdventureRequestWnd/AdvRqst_RiskCombobox").GetCurSel() == 2 then
		return true
	end
	return false
end

-- Callback to determine if the Give window is open
---@return boolean
function actions.give_window()
	return mq.TLO.Window("GiveWnd").Open()
end

--Callback to determine if the Merchant window is open
---@return boolean
function actions.merchant_window()
	return mq.TLO.Window("MerchantWnd").Open()
end

-- Callback to determine if the Inventory window is open
---@return boolean
function actions.inventory_window()
	return mq.TLO.Window("InventoryWindow").Open()
end

-- Callback to determine if the Tradeskill window is open
---@return boolean
function actions.tradeskill_window()
	return mq.TLO.Window("TradeskillWnd").Open()
end

-- Callback to determine if there is an item on the cursor
---@return boolean
function actions.got_cursor()
	if mq.TLO.Cursor() ~= nil then
		return true
	end
	return false
end

-- Cast the supplied alternate ability
---@param item Item
function actions.cast_alt(item)
	manage.removeInvis(item)
	_G.State:setStatusText("Casting %s", item.what)
	local ID = mq.TLO.Me.AltAbility(item.what)()
	logger.log_info("\aoCasting alternate ability: %s (%s)", item.what, ID)
	mq.cmdf("/alt act %s", ID)
	mq.delay(200)
	while mq.TLO.Me.Casting() ~= nil and mq.TLO.Me.Class() ~= "Bard" do
		mq.delay(100)
	end
	logger.log_super_verbose("\aoFinished casting: %s (%s)", item.what, ID)
end

-- Check if we received the correct dynamic zone (instance)
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.dz_check(item, common_settings, char_settings)
	if mq.TLO.DynamicZone.Name() ~= item.zone then
		logger.log_verbose("\aoDid not receive the correct dynamic zone. Moving to step \ar%s\ao.", item.backstep)
		_G.State:handle_step_change(item.backstep)
	else
		logger.log_verbose("\aoReceived the correct dynamic zone. Moving to step \ag%s\ao.", item.gotostep)
		_G.State:handle_step_change(item.gotostep)
	end
end

-- Check if we have the desired item in our inventory. If true goto gotostep, if false goto backstep
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.farm_check(item, common_settings, char_settings)
	if _G.Mob.xtargetCheck(char_settings) then
		_G.Mob.clearXtarget(common_settings, char_settings)
	end
	mq.delay("2s")
	local check_list = {}
	local not_found = false
	if item.count ~= nil then
		logger.log_verbose("\aoChecking if we have \ag%s \aoof \ag%s\ao.", item.count, item.what)
		_G.State:setStatusText("Checking if we have %s of %s.", item.count, item.what)
		if mq.TLO.FindItemCount("=" .. item.what)() < item.count then
			logger.log_super_verbose("\aoWe do not have \ar%s \aoof \aar%s\ao.", item.count, item.what)
			not_found = true
		end
	else
		_G.State:setStatusText("Checking if we have %s.", item.what)
		logger.log_verbose("\aoChecking if we have \ag%s\ao.", item.what)
		for word in string.gmatch(item.what, "([^|]+)") do
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
		logger.log_verbose("\aoAll items found. Moving to step \ag%s\ao.", item.gotostep)
		_G.State:handle_step_change(item.gotostep)
	else
		--using item.zone as a filler slot for split goto for this function
		logger.log_verbose("\aoOne or more items missing. Moving to step \ar%s\ao.", item.backstep)
		_G.State:handle_step_change(item.backstep)
	end
end

--Check LDON adventure text to determine where we need to enter
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.adventure_entrance(item, common_settings, char_settings)
	while string.find(mq.TLO.Window("AdventureRequestWnd/AdvRqst_NPCText").Text(), item.zone) do
		mq.delay(50)
	end
	logger.log_verbose('\aoSearching for string "\ag%s\ao" in adventure text.', item.what)
	if string.find(mq.TLO.Window("AdventureRequestWnd/AdvRqst_NPCText").Text(), item.what) then
		mq.delay(50)
		travel.loc_travel(item, common_settings, char_settings, _G.State:readGroupSelection())
		_G.State:handle_step_change(item.gotostep)
	end
end

-- Drop the curently active LDON adventure
---@param item Item
function actions.drop_adventure(item)
	while mq.TLO.Window("AdventureRequestWnd").Open() == false do
		mq.TLO.Window("AdventureRequestWnd").DoOpen()
		mq.delay(50)
	end
	mq.TLO.Window("AdventureRequestWnd/AdvRqst_RequestButton").LeftMouseUp()
	mq.cmd("/dgga /invoke ${Window[AdventureRequestWnd].DoOpen")
	mq.delay(200)
	mq.cmd("/dgga /invoke ${Window[AdventureRequestWnd/AdvRqst_RequestButton].LeftMouseUp}")
	mq.delay("1s")
	_G.State:handle_step_change(item.gotostep)
end

-- Check if we have the desired item in our inventory, if not pause the task
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.farm_check_pause(item, common_settings, char_settings)
	if _G.Mob.xtargetCheck(char_settings) then
		_G.Mob.clearXtarget(common_settings, char_settings)
	end
	_G.State:setStatusText("Checking for %s.", item.what)
	local check_list = {}
	local not_found = false
	if item.count then
		logger.log_verbose(
			"\aoChecking if we have \ag%s \aoof \ag%s\ao. Pausing if not present.",
			item.count,
			item.what
		)
		if mq.TLO.FindItemCount("=" .. item.what)() < item.count then
			not_found = true
		end
	else
		logger.log_verbose("\aoChecking if we have \ag%s\ao. Pausing if not present.", item.what)
		for word in string.gmatch(item.what, "([^|]+)") do
			table.insert(check_list, word)
			for _, check in pairs(check_list) do
				if not mq.TLO.FindItem("=" .. check)() then
					not_found = true
				end
			end
		end
	end
	--if one or more of the items are not present this will be true, so on false advance to the desired step
	if not_found == true then
		logger.log_error("\aoMissing \ar%s\ao. Stopping at step: \ar%s\ao.", item.what, _G.State.current_step)
		_G.State:setStatusText(item.status)
		_G.State:setTaskRunning(false)
		mq.cmd("/foreground")
	end
end

-- Event function to determine if we have received the correct message yet
---@param line string
function actions.farm_event(line)
	actions.farm_event_triggered = true
end

-- Farm for items at a specific location/radius
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param event boolean|nil
function actions.farm_radius(item, common_settings, char_settings, event)
	event = event or false
	if not event then
		if item.count then
			_G.State:setStatusText("Farming for %s (%s).", item.what, item.count)
			logger.log_info("\aoFarming for \ag%s \ao(\ag%s\ao).", item.what, item.count)
		else
			_G.State:setStatusText("Farming for %s.", item.what)
			logger.log_info("\aoFarming for \ag%s\ao.", item.what)
		end
	else
		actions.farm_event_triggered = false
		_G.State:setStatusText("Killing mobs in radius %s until event.", item.radius)
		logger.log_info("\aoKilling mobs in radius \ag%s \aountil event.", item.radius)
		--logger.log_debug("\aoEvent trigger is \ag%s\ao.", item.what)
		mq.event("farm_event", item.phrase, actions.farm_event)
	end
	travel.loc_travel(item, common_settings, char_settings, _G.State:readGroupSelection())
	local distance =
		dist.GetDistance3D(mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z(), item.whereX, item.whereY, item.whereZ)
	if distance > 30 then
		logger.log_verbose(
			"\aoDistance to location is \ar%s\ao. Moving to step \ar%s\ao.",
			distance,
			_G.State.current_step
		)
		_G.State:handle_step_change(_G.State.current_step)
		return
	end
	manage.campGroup(item.radius, item.zradius, common_settings, char_settings)
	manage.unpauseGroup(common_settings)
	local item_list = {}
	local item_status = ""
	local looping = true
	local loop_check = true
	if not event then
		if item.count then
			_G.State:setStatusText("Farming for %s (%s).", item.what, item.count)
		else
			_G.State:setStatusText("Farming for %s.", item.what)
		end
		for word in string.gmatch(item.what, "([^|]+)") do
			table.insert(item_list, word)
		end
	end
	manage.removeInvis(item)
	if not event then
		if not item.count then
			while looping do
				if _G.State.should_skip then
					travel.navPause()
					manage.uncampGroup(common_settings)
					manage.pauseGroup(common_settings)
					_G.State.should_skip = false
					return
				end
				if _G.State:readPaused() then
					manage.pauseGroup(common_settings)
					actions.pauseTask(_G.State:readStatusText())
					manage.unpauseGroup(common_settings)
				end
				item_status = ""
				loop_check = true
				local item_remove = 0
				for i, name in pairs(item_list) do
					if mq.TLO.FindItem("=" .. name)() == nil then
						loop_check = false
						item_status = item_status .. "|" .. name
					else
						logger.log_verbose("\aoRemoving \ar%s\ao from list.", name)
						item_remove = i
					end
				end
				if item_remove > 0 then
					table.remove(item_list, item_remove)
				end
				_G.State:setStatusText("Farming for %s.", item_status)
				if loop_check then
					looping = false
				end
				if mq.TLO.AdvLoot.SCount() > 0 then
					for i = 1, mq.TLO.AdvLoot.SCount() do
						for _, name in pairs(item_list) do
							if mq.TLO.AdvLoot.SList(i).Name() == name then
								mq.cmdf("/advloot shared %s giveto %s", i, mq.TLO.Me.DisplayName())
								logger.log_info("\aoLooting: \ag%s", name)
							end
							if item.secondary_loot ~= nil then
								if mq.TLO.AdvLoot.SList(i).Name() == item.secondary_loot then
									mq.cmdf("/advloot shared %s giveto %s", i, mq.TLO.Me.DisplayName())
									logger.log_info("\aoLooting: \ag%s", item.secondary_loot)
								end
							end
						end
					end
				end
				mq.delay(250)
				if mq.TLO.AdvLoot.PCount() > 0 then
					for i = 1, mq.TLO.AdvLoot.PCount() do
						for _, name in pairs(item_list) do
							if mq.TLO.AdvLoot.PList(i).Name() == name then
								mq.cmdf("/advloot personal %s loot", i)
								logger.log_info("\aoLooting: \ag%s", name)
							end
							if item.secondary_loot ~= nil then
								if mq.TLO.AdvLoot.SList(i).Name() == item.secondary_loot then
									mq.cmdf("/advloot shared %s giveto %s", i, mq.TLO.Me.DisplayName())
									logger.log_info("\aoLooting: \ag%s", item.secondary_loot)
								end
							end
						end
					end
				end
				mq.delay("1s")
				if mq.TLO.Window("ConfirmationDialogBox").Open() then
					logger.log_verbose("\aoNo drop confirmation window open.  Clicking yes.")
					mq.TLO.Window("ConfirmationDialogBox/CD_Yes_Button").LeftMouseUp()
					mq.delay("1s")
				end
				if item.npc ~= nil then
					local ID = _G.Mob.checkSpawn(item)
					if ID ~= 0 then
						manage.pauseGroup(common_settings)
						travel.npc_travel(item, common_settings, false, char_settings)
						_G.Mob.npc_kill(item, common_settings, char_settings)
						mq.delay(500)
						manage.unpauseGroup(common_settings)
					end
				end
			end
		else
			while mq.TLO.FindItemCount("=" .. item.what)() < item.count do
				if _G.State.should_skip then
					travel.navPause()
					manage.uncampGroup(common_settings)
					manage.pauseGroup(common_settings)
					_G.State.should_skip = false
					return
				end
				if _G.State:readPaused() then
					manage.pauseGroup(common_settings)
					actions.pauseTask(_G.State:readStatusText())
					manage.unpauseGroup(common_settings)
				end
				if mq.TLO.AdvLoot.SCount() > 0 then
					for i = 1, mq.TLO.AdvLoot.SCount() do
						if mq.TLO.AdvLoot.SList(i).Name() == item.what then
							mq.cmdf("/advloot shared %s giveto %s", i, mq.TLO.Me.DisplayName())
							logger.log_info("\aoLooting: \ag%s", item.what)
						end
					end
				end
				if mq.TLO.AdvLoot.PCount() > 0 then
					for i = 1, mq.TLO.AdvLoot.PCount() do
						for _, name in pairs(item_list) do
							if mq.TLO.AdvLoot.PList(i).Name() == name then
								mq.cmdf("/advloot personal %s loot", i)
								logger.log_info("\aoLooting: \ag%s", item.what)
							end
						end
					end
				end
				mq.delay("1s")
				if mq.TLO.Window("ConfirmationDialogBox").Open() then
					logger.log_verbose("\aoNo drop confirmation window open.  Clicking yes.")
					mq.TLO.Window("ConfirmationDialogBox/CD_Yes_Button").LeftMouseUp()
					mq.delay("1s")
				end
				if item.npc ~= nil then
					local ID = _G.Mob.checkSpawn(item)
					if ID ~= 0 then
						manage.pauseGroup(common_settings)
						travel.npc_travel(item, common_settings, false, char_settings)
						_G.Mob.npc_kill(item, common_settings, char_settings)
						mq.delay(500)
						manage.unpauseGroup(common_settings)
					end
				end
			end
		end
	else
		while looping do
			if _G.State.should_skip then
				travel.navPause()
				manage.uncampGroup(common_settings)
				manage.pauseGroup(common_settings)
				_G.State.should_skip = false
				return
			end
			if _G.State:readPaused() then
				manage.pauseGroup(common_settings)
				actions.pauseTask(_G.State:readStatusText())
				manage.unpauseGroup(common_settings)
			end
			if item.npc ~= nil then
				local ID = _G.Mob.checkSpawn(item)
				if ID ~= 0 then
					manage.pauseGroup(common_settings)
					travel.npc_travel(item, common_settings, false, char_settings)
					_G.Mob.npc_kill(item, common_settings, char_settings)
					mq.delay(500)
					manage.unpauseGroup(common_settings)
				end
			end
			mq.delay(250)
			mq.doevents()
			if actions.farm_event_triggered then
				_G.State:setStatusText("Event triggered. Moving on.")
				logger.log_info("\aoEvent triggered, moving on.")
				logger.log_verbose("Removing farm_event trigger")
				mq.unevent("farm_event")
				looping = false
			end
		end
	end
	manage.uncampGroup(common_settings)
	manage.pauseGroup(common_settings)
end

-- Farm at location while NPC is nearby
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.farm_while_near(item, common_settings, char_settings)
	_G.State:setStatusText("Killing nearby mobs until %s moves.", item.npc)
	logger.log_info("\aoKilling nearby mobs until \ag%s \aomoves.", item.npc)
	travel.loc_travel(item, common_settings, char_settings, _G.State:readGroupSelection())
	manage.campGroup(item.radius, item.zradius, common_settings, char_settings)
	manage.unpauseGroup(common_settings)
	manage.removeInvis(item)
	local not_found_count = 0
	local distance = mq.TLO.Spawn("npc " .. item.npc).Distance() or 0
	while distance < tonumber(item.what) do
		distance = mq.TLO.Spawn("npc " .. item.npc).Distance() or 0
		if distance == 0 then
			not_found_count = not_found_count + 1
			if not_found_count >= 15 then
				logger.log_error("\aoWe have not seen \ar%s \ao for \ar3 \aoseconds.", item.npc)
				_G.State:setTaskRunning(false)
				mq.cmd("/foreground")
				return
			end
		else
			not_found_count = 0
		end
		mq.delay(200)
	end
	logger.log_info("\ag%s \aohas moved, proceeding.", item.npc)
	manage.uncampGroup(common_settings)
	manage.pauseGroup(common_settings)
end

-- Fish for a specific item
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@param once boolean|nil
function actions.fish_farm(item, common_settings, char_settings, once)
	once = once or false
	if item.count ~= nil then
		_G.State:setStatusText("Fishing for %s (%s).", item.what, item.count)
		logger.log_info("\aoFishing for \ag%s \ao(\ag%s\ao).", item.what, item.count)
	else
		_G.State:setStatusText("Fishing for %s.", item.what)
		logger.log_info("\aoFishing for \ag%s\ao.", item.what)
	end
	local weapon1 = mq.TLO.InvSlot("13").Item.Name()
	local slot1, slot2 = 0, 0
	if weapon1 ~= "Fishing Pole" then
		logger.log_verbose("\aoFishing pole not currently equiped. Removing \ar%s\ao and equiping a pole.", weapon1)
		mq.cmd('/itemnotify "Fishing Pole" leftmouseup')
		while mq.TLO.Cursor() == nil do
			mq.delay(100)
		end
		mq.cmd("/itemnotify 13 leftmouseup")
		mq.delay(500)
		while mq.TLO.Cursor() ~= nil do
			slot1, slot2 = inv.find_free_slot(20)
			logger.log_verbose("\aoDropping \ar%s \aoin bag \ar%s \aoslot \ar%s\ao.", weapon1, slot1, slot2)
			mq.cmdf("/itemnotify in pack%s %s leftmouseup", slot1, slot2)
			mq.delay(100)
		end
	end
	if item.count == nil then
		local item_list = {}
		local item_status = ""
		local looping = true
		local loop_check = true
		for word in string.gmatch(item.what, "([^|]+)") do
			table.insert(item_list, word)
		end
		while looping do
			mq.delay(200)
			if _G.State.should_skip == true then
				_G.State.should_skip = false
				return
			end
			if _G.State:readPaused() then
				actions.pauseTask(_G.State:readStatusText())
			end
			if _G.Mob.xtargetCheck(char_settings) then
				_G.Mob.clearXtarget(common_settings, char_settings)
			end
			item_status = ""
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
			_G.State:setStatusText("Fishing for %s.", item_status)
			if loop_check then
				looping = false
			end
			if mq.TLO.Cursor() ~= nil then
				for i, name in pairs(fishing_trash) do
					if mq.TLO.Cursor.Name() == name then
						mq.cmd("/destroy")
						mq.delay(200)
					end
				end
				if mq.TLO.Cursor.Name() ~= nil then
					mq.cmd("/autoinv")
				end
				if once then
					break
				end
			end
			mq.delay(100)
			local did_once = false
			if mq.TLO.Me.AbilityReady("Fishing")() then
				if did_once == true then
					if once then
						logger.log_super_verbose("\aoSet to fish only once. Stopping.")
						break
					end
				end
				did_once = true
				mq.cmd("/doability Fishing")
				logger.log_verbose("\aoCasting line.")
				mq.delay(500)
			end
		end
	else
	end
	if weapon1 ~= "Fishing Pole" then
		logger.log_verbose("\aoReequiping \ar\ao.", weapon1)
		mq.cmdf("/itemnotify in pack%s %s leftmouseup", slot1, slot2)
		while mq.TLO.Cursor() == nil do
			mq.delay(100)
		end
		mq.cmd("/itemnotify 13 leftmouseup")
		mq.delay(500)
		while mq.TLO.Cursor() ~= nil do
			mq.cmd("/autoinv")
			mq.delay(100)
		end
	end
end

-- Forage for specific items
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.forage_farm(item, common_settings, char_settings)
	if item.count == nil then
		_G.State:setStatusText("Foraging for %s.", item.what)
		logger.log_info("\aoForaging for \ag%s\ao.", item.what)
		local item_list = {}
		local item_status = ""
		local looping = true
		local loop_check = true
		local unpause_automation = false
		for word in string.gmatch(item.what, "([^|]+)") do
			table.insert(item_list, word)
		end
		while looping do
			mq.delay(200)
			if _G.State.should_skip == true then
				_G.State.should_skip = false
				return
			end
			if _G.State:readPaused() then
				actions.pauseTask(_G.State:readStatusText())
			end
			if _G.Mob.xtargetCheck(char_settings) then
				_G.Mob.clearXtarget(common_settings, char_settings)
			end
			item_status = ""
			loop_check = true
			local item_remove = 0
			for i, name in pairs(item_list) do
				if mq.TLO.FindItem("=" .. name)() == nil then
					loop_check = false
					item_status = item_status .. "|" .. name
				else
					logger.log_verbose("\aoRemoving \ar%s\ao from list.", name)
					item_remove = i
				end
			end
			if item_remove > 0 then
				table.remove(item_list, item_remove)
			end
			_G.State:setStatusText("Foraging for %s.", item_status)
			if loop_check then
				looping = false
			end
			if mq.TLO.Me.AbilityReady("Forage")() then
				mq.cmd("/doability Forage")
				while mq.TLO.Me.AbilityReady("Forage")() do
					mq.delay(200)
				end
				mq.delay(500)
				for i, name in pairs(forage_trash) do
					if mq.TLO.Cursor.Name() == name then
						logger.log_verbose("\aoForage trash \ar%s\ao found on cursor. Destroying.", name)
						mq.cmd("/destroy")
						mq.delay(200)
					end
				end
				if mq.TLO.Cursor.Name() ~= nil then
					logger.log_info("\aoFound \ag%s\ao on cursor. Moving to inventory.", mq.TLO.Cursor.Name())
					mq.cmd("/autoinv")
				end
			end
		end
	else
		_G.State:setStatusText("Foraging for %s (%s).", item.what, item.count)
		logger.log_info("\aoForaging for \ag%s\ao (\ag%s\ao).", item.what, item.count)
		local looping = true
		while looping do
			mq.delay(200)
			if _G.State.should_skip == true then
				_G.State.should_skip = false
				return
			end
			if _G.State:readPaused() then
				actions.pauseTask(_G.State:readStatusText())
			end
			if _G.Mob.xtargetCheck(char_settings) then
				_G.Mob.clearXtarget(common_settings, char_settings)
			end
			_G.State:setStatusText(
				"Foraging for %s (%s/%s).",
				item.what,
				mq.TLO.FindItemCount("=" .. item.what)(),
				item.count
			)
			if mq.TLO.Me.AbilityReady("Forage")() then
				logger.log_info(
					"\aoForaging for \ag%s\ao (\ag%s\ao/\ag%s\ao).",
					item.what,
					mq.TLO.FindItemCount("=" .. item.what)(),
					item.count
				)
				mq.cmd("/doability Forage")
				while mq.TLO.Me.AbilityReady("Forage")() do
					mq.delay(200)
				end
				mq.delay(500)
				while mq.TLO.Cursor() ~= nil do
					actions.forage_cursor_check(item)
				end
			end
			if mq.TLO.FindItemCount("=" .. item.what)() >= item.count then
				looping = false
			end
		end
	end
end

-- Check cursor for foraged items
---@param item Item
---@return boolean|nil
function actions.forage_cursor_check(item)
	if mq.TLO.Cursor() == nil then
		return false
	end
	while mq.TLO.Cursor() ~= nil do
		mq.delay(200)
		if mq.TLO.Cursor() == nil then
			return
		end
		for i, name in pairs(forage_trash) do
			if mq.TLO.Cursor.Name() == name then
				logger.log_verbose("\aoForage trash \ar%s\ao found on cursor. Destroying.", name)
				mq.cmd("/destroy")
				mq.delay(200)
				return
			end
		end
		if mq.TLO.Cursor.Name() ~= nil then
			logger.log_info("\aoFound \ag%s\ao on cursor. Moving to inventory.", mq.TLO.Cursor.Name())
			mq.cmd("/autoinv")
			return
		end
	end
end

-- Move to location and pick up ground spawn
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.ground_spawn(item, common_settings, char_settings)
	_G.State:setStatusText("Traveling to ground spawn @ %s %s %s.", item.whereX, item.whereY, item.whereZ)
	travel.loc_travel(item, common_settings, char_settings, _G.State:readGroupSelection())
	if dist.GetDistance3D(item.whereX, item.whereY, item.whereZ, mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z()) > 15 then
		logger.log_warn(
			"\aoWe are to far away from the necessary location (\ar%s %s %s\ao). Reseting step.",
			item.whereX,
			item.whereY,
			item.whereZ
		)
		_G.State:handle_step_change(_G.State.current_step)
		return
	end
	_G.State:setStatusText("Picking up ground spawn %s.", item.what)
	mq.cmd("/itemtarget")
	mq.delay(200)
	mq.cmd("/click left itemtarget")
	logger.log_info("\aoPicking up \ag%s\ao.", item.what)
	while mq.TLO.Cursor.Name() ~= item.what do
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		mq.delay(200)
		mq.cmd("/itemtarget")
		mq.delay(200)
		mq.cmd("/click left itemtarget")
	end
	inv.auto_inv(item)
end

-- Farm ground spawns in the zone until we obtain desired item
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.ground_spawn_farm(item, common_settings, char_settings)
	_G.State:setStatusText("Farming for ground spawns: %s.", item.what)
	logger.log_info("\aoFarming for \ag%s", item.what)
	local item_list = {}
	local item_status = ""
	local looping = true
	local loop_check = true
	for word in string.gmatch(item.what, "([^|]+)") do
		table.insert(item_list, word)
	end
	while looping == true do
		loop_check = true
		if _G.State.should_skip == true then
			travel.navPause()
			manage.uncampGroup(common_settings)
			manage.pauseGroup(common_settings)
			_G.State.should_skip = false
			return
		end
		if _G.State:readPaused() then
			manage.pauseGroup(common_settings)
			actions.pauseTask(_G.State:readStatusText())
			manage.unpauseGroup(common_settings)
		end
		item_status = ""
		local item_remove = 0
		for i, name in pairs(item_list) do
			if mq.TLO.FindItem("=" .. name)() == nil then
				loop_check = false
				item_status = item_status .. "|" .. name
			else
				logger.log_verbose("\aoRemoving \ar%s\ao from list.", name)
				item_remove = i
			end
		end
		if item_remove > 0 then
			table.remove(item_list, item_remove)
		end
		_G.State:setStatusText("Farming for %s.", item_status)
		if loop_check then
			looping = false
		end
		mq.cmdf('/itemtarget "%s"', item.npc)
		mq.delay(50)
		if mq.TLO.ItemTarget() ~= nil then
			item.whereX = mq.TLO.ItemTarget.X()
			item.whereY = mq.TLO.ItemTarget.Y()
			item.whereZ = mq.TLO.ItemTarget.Z()
			item.whereZ = item.whereZ * 100
			item.whereZ = math.floor(item.whereZ)
			item.whereZ = item.whereZ / 100
			travel.loc_travel(item, common_settings, char_settings, _G.State:readGroupSelection())
			mq.delay(200)
			mq.cmd("/click left itemtarget")
			mq.delay(200)
			if mq.TLO.Cursor() ~= nil then
				logger.log_debug("\aoWe have picked up a \ag%s\ao.", mq.TLO.Cursor())
			end
			mq.cmd("/autoinv")
		end
	end
end

-- Check if we have the necessary number of group members, and if they are in zone if necessary
---@param item Item
---@param same_zone boolean|nil
function actions.group_size_check(item, same_zone)
	same_zone = same_zone or false
	logger.log_super_verbose("\aoChecking group size (\ag%s \aoplayers needed).", item.count)
	if same_zone == true then
		if mq.TLO.Group.GroupSize() == nil then
			_G.State:setStatusText(item.status)
			logger.log_error(
				"\aoYou will require \ar%s \aoplayers in your party and within the same zone to progress through this step.",
				item.count
			)
			_G.State:setTaskRunning(false)
			return
		end
		if mq.TLO.Group.GroupSize() < item.count then
			_G.State:setStatusText(item.status)
			logger.log_error(
				"\aoYou will require \ar%s \aoplayers in your party and within the same zone  to progress through this step.",
				item.count
			)
			_G.State:setTaskRunning(false)
			return
		end
		if mq.TLO.Group.Present() + 1 < item.count then
			_G.State:setStatusText(item.status)
			logger.log_error(
				"\aoYou will require \ar%s \aoplayers in your party and within the same zone to progress through this step.",
				item.count
			)
			_G.State:setTaskRunning(false)
			return
		end
	end
	if not mq.TLO.Group.GroupSize() then
		_G.State:setStatusText(item.status)
		logger.log_error(
			"\aoYou will require \ar%s \aoplayers in your party to progress through this step.",
			item.count
		)
		_G.State:setTaskRunning(false)
		return
	end
	if mq.TLO.Group.GroupSize() < item.count then
		_G.State:setStatusText(item.status)
		logger.log_error(
			"\aoYou will require \ar%s \aoplayers in your party to progress through this step.",
			item.count
		)
		_G.State:setTaskRunning(false)
		return
	end
end

-- Add mob to the ignore list for class automation
---@param item Item
---@param common_settings Common_Settings_Settings
function actions.ignore_mob(item, common_settings)
	logger.log_verbose("\aoAdding \ag%s\ao to mob ignore list.", item.npc)
	if common_settings.class[mq.TLO.Me.Class()] == 1 then
		mq.cmdf('/%s ignore "%s"', mq.TLO.Me.Class.ShortName(), item.npc)
	elseif common_settings.class[mq.TLO.Me.Class()] == 2 then
		mq.cmdf('/rgl pulldeny "%s"', item.npc)
	elseif common_settings.class[mq.TLO.Me.Class()] == 3 then
		mq.TLO.Spawn("npc " .. item.npc).DoTarget()
		mq.delay(200)
		mq.cmd("/addignore")
	elseif common_settings.class[mq.TLO.Me.Class()] == 4 then
		mq.cmdf('/addignore "%s"', item.npc)
	elseif common_settings.class[mq.TLO.Me.Class()] == 5 then
		mq.cmdf('/addignore "%s"', item.npc)
	end
end

-- Remove mob from the ignore list for class automation
---@param item Item
---@param common_settings Common_Settings_Settings
function actions.unignore_mob(item, common_settings)
	logger.log_verbose("\aoRemoving \ag%s\ao from mob ignore list.", item.npc)
	if common_settings.class[mq.TLO.Me.Class()] == 1 then
		mq.cmdf('/%s unignore "%s"', mq.TLO.Me.Class.ShortName(), item.npc)
	elseif common_settings.class[mq.TLO.Me.Class()] == 2 then
		mq.cmdf('/rgl pulldenyrm "%s"', item.npc)
	elseif common_settings.class[mq.TLO.Me.Class()] == 3 then
		mq.TLO.Spawn("npc " .. item.npc).DoTarget()
		mq.delay(200)
		mq.cmd("/clearignore")
		--[[elseif common_settings.class[mq.TLO.Me.Class()] == 4 then
        mq.cmdf('/addignore "%s"', item.npc)
    elseif common_settings.class[mq.TLO.Me.Class()] == 5 then
        mq.cmdf('/addignore "%s"', item.npc)--]]
	end
end

-- Pause the script and restore previous status text when unpaused
---@param status string
---@return boolean|nil
function actions.pauseTask(status)
	_G.State:setStatusText("Paused.")
	logger.log_info("\aoPausing on step \ar%s\ao.", _G.State.current_step)
	while _G.State:readPaused() do
		mq.delay(200)
		if mq.TLO.EverQuest.GameState() ~= "INGAME" then
			logger.log_error("\arNot in game, closing.")
			mq.exit()
		end
		if _G.State:readTaskRunning() == false then
			return
		end
	end
	_G.State:setStatusText(status)
	return true
end

-- Cycle through buffs and remove any damage shields (spa 59)
function actions.RemoveDamageShields()
	while mq.TLO.Me.FindBuff("spa 59")() ~= nil do
		mq.TLO.Me.FindBuff("spa 59").Remove()
	end
end

-- Give the indicated item to the indicated npc
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.npc_give(item, common_settings, char_settings)
	manage.removeInvis(item)
	_G.State:setStatusText("Giving %s to %s.", item.what, item.npc)
	logger.log_info("\aoGiving \ag%s\ao to \ag%s\ao.", item.what, item.npc)

	logger.log_warn("\aoWaiting for \ag%s \aoto spawn.", item.npc)
	while mq.TLO.Spawn(item.npc).ID == 0 do
		mq.delay(100)
	end
	if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
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
		logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
		mq.TLO.Spawn(item.npc).DoTarget()
		mq.delay(750)
	end
	if item.itemID ~= nil then
		if mq.TLO.FindItem(item.itemID)() == nil then
			logger.log_error("\ar%s \aowas not found in inventory.", item.what)
			_G.State:setStatusText("%s should be handed to %s but is not found in inventory.", item.what, item.npc)
			_G.State:setTaskRunning(false)
			mq.cmd("/foreground")
			return
		end
		mq.cmdf("/nomodkey /shift /itemnotify #%s leftmouseup", item.itemID)
		mq.delay("5s", actions.got_cursor)
		mq.TLO.Target.LeftClick()
		mq.delay("10s", actions.give_window)
	else
		if mq.TLO.FindItem("=" .. item.what)() == nil then
			logger.log_error("\ar%s \aowas not found in inventory.", item.what)
			_G.State:setStatusText("%s should be handed to %s but is not found in inventory.", item.what, item.npc)
			_G.State:setTaskRunning(false)
			mq.cmd("/foreground")
			return
		end
		mq.cmdf('/nomodkey /shift /itemnotify "%s" leftmouseup', item.what)
		mq.delay("5s", actions.got_cursor)
		mq.TLO.Target.LeftClick()
		mq.delay("10s", actions.give_window)
	end
	local looping = true
	local loopCount = 0
	while looping do
		logger.log_super_verbose("\aoVerifying that \ar%s\ao has been moved to the give window.", item.what)
		loopCount = loopCount + 1
		mq.delay(200)
		for i = 0, 3 do
			if
				string.lower(mq.TLO.Window("GiveWnd").Child("GVW_MyItemSlot" .. i).Tooltip()) == string.lower(item.what)
			then
				logger.log_super_verbose("\ar%s \aowas found in give window.", item.what)
				looping = false
			end
		end
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		if loopCount == 10 then
			logger.log_error(
				"\aoFailed to give \ar%s \ao to \ar%s \aoon step \ar%s\ao.",
				item.what,
				item.npc,
				_G.State.current_step
			)
			_G.State:setStatusText("Failed to give %s to %s on step %s.", item.what, item.npc, _G.State.current_step)
			_G.State:setTaskRunning(false)
			mq.cmd("/foreground")
			return
		end
	end
	mq.TLO.Window("GiveWnd").Child("GVW_Give_Button").LeftMouseUp()
	mq.delay(100)
	while mq.TLO.Window("GiveWnd").Open() do
		mq.delay(250)
		mq.TLO.Window("GiveWnd").Child("GVW_Give_Button").LeftMouseUp()
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
	end
	logger.log_super_verbose("\aoSuccessfully gave \ag%s \aoto \ag%s\ao.", item.what, item.npc)
	mq.delay("1s")
end

-- Add an item to the give window with the indicated NPC
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.npc_give_add(item, common_settings, char_settings)
	manage.removeInvis(item)
	_G.State:setStatusText("Giving %s to %s.", item.what, item.npc)
	logger.log_info("\aoAdding \ag%s\ao to give window with \ag%s\ao.", item.what, item.npc)
	if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
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
		logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
		mq.TLO.Spawn(item.npc).DoTarget()
		mq.delay(300)
	end
	mq.cmdf('/ctrl /itemnotify "%s" leftmouseup', item.what)
	mq.delay("2s", actions.got_cursor)
	mq.TLO.Target.LeftClick()
	mq.delay("5s", actions.give_window)
	local looping = true
	while looping do
		for i = 0, 3 do
			logger.log_verbose("\aoVerifying \ar%s \aohas been added to give window.", item.what)
			if
				string.lower(mq.TLO.Window("GiveWnd").Child("GVW_MyItemSlot" .. i).Tooltip()) == string.lower(item.what)
			then
				logger.log_verbose("\ag%s \aosuccessfully added to give window with \ag%s\ao.", item.what, item.npc)
				looping = false
			end
		end
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
	end
end

-- Click the give button on the give window
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.npc_give_click(item, common_settings, char_settings)
	manage.removeInvis(item)
	_G.State:setStatusText("Giving items.")
	mq.TLO.Window("GiveWnd").Child("GVW_Give_Button").LeftMouseUp()
	mq.delay(100)
	logger.log_info("\aoClicking give button.")
	while mq.TLO.Window("GiveWnd").Open() do
		mq.delay(100)
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
	end
	mq.delay("1s")
end

-- Give money to NPC
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.npc_give_money(item, common_settings, char_settings)
	manage.removeInvis(item)
	_G.State:setStatusText("Giving %spp to %s.", item.what, item.npc)
	logger.log_info("\aoGiving \ag%s\ao platinum to \ag%s\ao.", item.what, item.npc)
	if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
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
		logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
		mq.TLO.Spawn(item.npc).DoTarget()
		mq.delay(300)
	end
	if mq.TLO.Window("InventoryWindow").Open() == false then
		mq.TLO.Window("InventoryWindow").DoOpen()
	end
	mq.delay("5s", actions.inventory_window)
	mq.TLO.Window("InventoryWindow").Child("IW_Money0").LeftMouseUp()
	mq.delay(200)
	mq.TLO.Window("QuantityWnd").Child("QTYW_SliderInput").SetText(item.what)
	mq.delay(200)
	mq.TLO.Window("QuantityWnd").Child("QTYW_Accept_Button").LeftMouseUp()
	mq.delay(200)
	mq.TLO.Target.LeftClick()
	mq.delay("5s", actions.give_window)
	mq.TLO.Window("GiveWnd").Child("GVW_Give_Button").LeftMouseUp()
	mq.delay(100)
	while mq.TLO.Window("GiveWnd").Open() do
		mq.delay(100)
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
	end
	mq.TLO.Window("InventoryWindow").DoClose()
	logger.log_verbose("\aoSuccessfully gave \ag%s \aoplatinum to \ag%s\ao.", item.what, item.npc)
	mq.delay("1s")
end

-- Hail the NPC
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.npc_hail(item, common_settings, char_settings)
	manage.removeInvis(item)
	_G.State:setStatusText("Hailing %s.", item.npc)
	logger.log_info("\aoHailing \ag%s\ao.", item.npc)
	if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
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
		logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
		mq.TLO.Spawn(item.npc).DoTarget()
		mq.delay(300)
	end
	mq.cmd("/keypress HAIL")
	mq.delay(300)
end

-- Say the indicted phrase to the NPC
---@param item Item
function actions.npc_talk(item)
	manage.removeInvis(item)
	_G.State:setStatusText("Talking to %s (%s).", item.npc, item.phrase)
	logger.log_info("\aoSaying \ag%s \aoto \ag%s\ao.", item.phrase, item.npc)
	if item.npc == "SELF" then
		mq.TLO.Me.DoTarget()
		mq.cmdf("/say %s", item.phrase)
		mq.delay(750)
		return
	end
	if mq.TLO.Target.ID() ~= mq.TLO.Spawn(item.npc).ID() then
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
		logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
		mq.TLO.Spawn(item.npc).DoTarget()
		mq.delay(300)
	end
	mq.cmdf("/say %s", item.phrase)
	mq.delay(750)
end

-- Wait for the NPC to spawn
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.npc_wait(item, common_settings, char_settings)
	_G.State:setStatusText("Waiting for %s (%s).", item.npc, item.waittime)
	logger.log_info("\aoWaiting for \ag%s\ao. This may take \ag%s\ao.", item.npc, item.waittime)
	while mq.TLO.Spawn("npc " .. item.npc).ID() == 0 do
		if mq.TLO.Spawn("corpse " .. item.npc).ID() ~= 0 then
			logger.log_warn("\ar%s \aohas a corpse present, continuing.")
			return
		end
		if _G.Mob.xtargetCheck(char_settings) then
			_G.Mob.clearXtarget(common_settings, char_settings)
		end
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		if _G.State:readPaused() then
			actions.pauseTask(_G.State:readStatusText())
		end
		mq.delay(200)
	end
end

-- Wait for the NPC to despawn
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.npc_wait_despawn(item, common_settings, char_settings)
	_G.State:setStatusText("Waiting for %s to despawn (%s).", item.npc, item.waittime)
	logger.log_info("\aoWaiting for \ag%s\ao to despawn. This may take \ag%s\ao.", item.npc, item.waittime)
	local unpause_automation = false
	while mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 do
		if _G.Mob.xtargetCheck(char_settings) then
			_G.Mob.clearXtarget(common_settings, char_settings)
		end
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		if _G.State:readPaused() then
			actions.pauseTask(_G.State:readStatusText())
		end
		mq.delay(200)
	end
end

-- Pickpocket the indicated item from the NPC
---@param item Item
function actions.pickpocket(item)
	_G.State:setStatusText("Pickpocketing %s from %s.", item.what, item.npc)
	logger.log_info("\aoPickpocketing \ag%s \aofrom \ag%s\ao.", item.what, item.npc)
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
	logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
	mq.TLO.NearestSpawn("npc " .. item.npc).DoTarget()
	local looping = true
	while looping do
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		if mq.TLO.Me.AbilityReady("Pick Pockets")() then
			mq.cmd("/doability Pick Pockets")
			mq.delay(500)
			if mq.TLO.Cursor.Name() == item.what then
				logger.log_info("\aoSuccessfully pickpocketed \ag%s\ao.", item.what)
				mq.cmd("/autoinv")
				mq.delay(200)
				looping = false
			else
				mq.cmd("/autoinv")
				mq.delay(200)
			end
		end
	end
end

-- Check if we have the desired item, if so advance to gotostep
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.pre_farm_check(item, common_settings, char_settings)
	if _G.Mob.xtargetCheck(char_settings) then
		_G.Mob.clearXtarget(common_settings, char_settings)
	end
	_G.State:setStatusText("Checking for pre-farmable items (%s).", item.what)
	logger.log_info("\aoChecking for prefarmable items (\ag%s\ao).", item.what)
	mq.delay("1s")
	local check_list = {}
	local not_found = false
	if item.count ~= nil then
		if mq.TLO.FindItemCount("=" .. item.what)() < item.count then
			not_found = true
		end
	else
		for word in string.gmatch(item.what, "([^|]+)") do
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
		logger.log_info("\aoAll necessary items found. Moving to step \ar%s\ao.", item.gotostep)
		_G.State:handle_step_change(item.gotostep)
	end
end

-- Gamble until event triggeres (rogue pre 1.5)
---@param item Item
function actions.rog_gamble(item)
	logger.log_verbose("\aoCreating rogue gambling event.")
	mq.event("chips", "#*#Guard Kovan turns his attention to the nobles#*#", gamble_event)
	while gamble_done == false do
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		actions.npc_talk(item)
		mq.delay("7s")
		mq.doevents()
	end
	local talk_param = {
		npc = item.npc,
		phrase = "cash out",
	}
	actions.npc_talk(talk_param)
	gamble_done = false
end

-- Check if we are sneaking, if not sneak
---@param item Item
function actions.sneak(item)
	if mq.TLO.Me.Sneaking() == false then
		while mq.TLO.Me.Sneaking() == false do
			mq.delay(100)
			if mq.TLO.Me.AbilityReady("Sneak")() == true then
				mq.cmd("/doability sneak")
			end
		end
	end
end

-- Check group size and start LDON Adventure
---@param item Item
function actions.start_adventure(item)
	if mq.TLO.Me.Grouped() == false then
		logger.log_error("\aoYou must be in a group with 3 members to request an LDON adventure.")
		_G.State:setStatusText("Please be a part of a group to continue.")
		_G.State:setTaskRunning(false)
		mq.cmd("/foreground")
		return
	end
	_G.State:setStatusText("Requesting adventure from %s.", item.npc)
	logger.log_info("\aoRequesting adventure from \ag%s\ao.", item.npc)
	mq.TLO.Spawn("npc " .. item.npc).DoTarget()
	mq.delay(200)
	mq.TLO.Target.RightClick()
	mq.delay("5s", actions.adventure_window)
	mq.TLO.Window("AdventureRequestWnd/AdvRqst_TypeCombobox").Select(3)()
	mq.delay("5s", actions.adventure_type_selection)
	mq.TLO.Window("AdventureRequestWnd/AdvRqst_RiskCombobox").Select(2)()
	mq.delay("5s", actions.adventure_risk_selection)
	mq.delay("2s")
	mq.TLO.Window("AdventureRequestWnd/AdvRqst_RequestButton").LeftMouseUp()
	mq.delay("5s", actions.adventure_button)
	mq.TLO.Window("AdventureRequestWnd/AdvRqst_AcceptButton").LeftMouseUp()
	mq.delay("2s")
end

-- Check if we have completed this LDON Adventure
---@param item Item
function actions.ldon_count_check(item)
	local timeString = mq.TLO.Window("AdventureRequestWnd/AdvRqst_CompleteTimeLeftLabel").Text()
	local progressString = mq.TLO.Window("AdventureRequestWnd/AdvRqst_ProgressTextLabel").Text()
	if timeString == "" and progressString == "" then
		logger.log_info("\aoCompleted LDON adventure!")
		_G.State:handle_step_change(item.gotostep)
	else
		logger.log_super_verbose("\aoAdventure not yet complete.")
		_G.State:handle_step_change(item.backstep)
	end
end

-- Wait for the specified amount of time (in ms)
---@param item Item
---@param common_settings Common_Settings_Settings
---@param char_settings Char_Settings_SaveState
function actions.wait(item, common_settings, char_settings)
	_G.State:setStatusText("Waiting for %s seconds.", item.wait / 1000)
	logger.log_info("Waiting for \ag%s \ao seconds.", item.wait / 1000)
	local waiting = true
	local start_wait = os.clock() * 1000
	local distance = 0
	if item.whereZ ~= nil then
		distance = math.abs(mq.TLO.Me.Z() - item.whereZ)
	end
	local loopCount = 0
	while waiting do
		mq.delay(50)
		if _G.Mob.xtargetCheck(char_settings) then
			_G.Mob.clearXtarget(common_settings, char_settings)
		end
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		if _G.State:readPaused() then
			actions.pauseTask(_G.State:readStatusText())
		end
		mq.delay(200)
		if os.clock() * 1000 > start_wait + item.wait then
			waiting = false
		end
		loopCount = loopCount + 1
		if loopCount == 10 and item.whereZ ~= nil then
			if distance - math.abs(mq.TLO.Me.Z() - item.whereZ) < 10 then
				if math.abs(mq.TLO.Me.Z() - item.whereZ) < 1 then
					logger.log_info("\aoWe have reached our destination. Stopping paused state early.")
					break
				end
				logger.log_warn(
					"\aoWe should be moving on the z-axis and we are not. Backing up to step \ar%s\ao.",
					_G.State.current_step
				)
				_G.State:handle_step_change(_G.State.current_step - 2)
				return
			else
				distance = math.abs(mq.TLO.Me.Z() - item.whereZ)
				if math.abs(mq.TLO.Me.Z() - item.whereZ) < 5 then
					logger.log_info("\aoWe have reached our destination. Stopping paused state early.")
					break
				end
				loopCount = 0
			end
		end
	end
	if item.gotostep ~= nil then
		_G.State:handle_step_change(item.gotostep)
	end
end

-- Wait for an event to occur
---@param item Item
function actions.wait_event(item)
	mq.event("wait_event", item.phrase, event_wait)
	_G.State:setStatusText("Waiting for event (%s) before continuing.", item.phrase)
	--logger.log_info("\aoWaiting for event (\ag%s\ao) before continuing.", item.phrase)
	logger.log_info("\aoWaiting for event before continuing.")
	waiting = true
	while waiting do
		if _G.State.should_skip == true then
			mq.unevent("wait_event")
			_G.State.should_skip = false
			return
		end
		mq.delay(200)
		mq.doevents()
	end
end

-- Wait for an item to be on the cursor
---@param item Item
function actions.wait_cursor(item)
	while true do
		_G.State:setStatusText("Waiting for " .. item.what .. " on cursor.")
		logger.log_info("\aoWaiting for \ag%s \aoon cursor.", item.what)
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		while mq.TLO.Cursor() == nil do
			if _G.State.should_skip == true then
				_G.State.should_skip = false
				return
			end
			mq.delay(200)
		end
		if mq.TLO.Cursor.Name() == item.what then
			logger.log_info("\aoFound \ag%s \aoon cursor.", item.what)
			mq.cmd("/autoinv")
			return
		end
		mq.cmd("/autoinv")
	end
end

--Wait for a specific in game time of day
---@param item Item
function actions.wait_for(item)
	local looping = true
	local cur_eq_hour = mq.TLO.GameTime.Hour()
	local cur_eq_min = mq.TLO.GameTime.Minute()
	while looping do
		if cur_eq_hour == item.wait and cur_eq_min >= 0 then
			looping = false
		end
		mq.delay(500)
		cur_eq_hour = mq.TLO.GameTime.Hour()
		cur_eq_min = mq.TLO.GameTime.Minute()
		if cur_eq_hour < item.wait then
			local hour_calc = item.wait - cur_eq_hour
			local min_calc = 60 - cur_eq_min
			min_calc = min_calc + (hour_calc * 60)
			local real_time = math.floor(min_calc / 20)
			_G.State:setStatusText("Waiting for EQ Time: %s:00 (%s minutes).", item.wait, real_time)
		elseif cur_eq_hour >= item.wait then
			local hour_calc = 24 - cur_eq_hour + item.wait
			local min_calc = 60 - cur_eq_min
			min_calc = min_calc + (hour_calc * 60)
			local real_time = math.floor(min_calc / 20)
			_G.State:setStatusText("Waiting for EQ Time: %s:00 (%s minutes).", item.wait, real_time)
		end
	end
end

return actions
