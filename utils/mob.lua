local mq = require("mq")
local manage = require("utils/manageautomation")
local inv = require("utils/inventory")
local travel = require("utils/travel")
local logger = require("utils/logger")
local dist = require("utils/distance")
local MAX_DISTANCE = 100
---@class Mob
local mob = {}
local searchFilter = ""

-- Event called when target cannot be hit or casted upon. Increments a counter that when 10 is reached will add the target to a bad ID list.
local function target_invalid_switch()
	_G.State.cannot_count = _G.State.cannot_count + 1
end

-- Backstab the indicated NPC
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
function mob.backstab(item, class_settings, char_settings)
	logger.log_info("\aoBackstabbing \ag%s\ao.", item.npc)
	local ID = mob.findNearestName(item.npc, item, class_settings, char_settings)
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
	mq.cmd("/stick behind")
	mq.delay("2s")
	logger.log_super_verbose("\aoPerforming backstab.")
	mq.cmd("/doability backstab")
	mq.delay(500)
end

-- Check xtargets to see if there are things we need to kill (based upon current settings)
---@param char_settings Char_Settings_SaveState
---@return boolean
function mob.xtargetCheck(char_settings)
	local choice, name = _G.State:readGroupSelection()
	if choice > 1 then
		if travel.GroupZoneCheck(choice, name) == false then
			return false
		end
	end
	logger.log_super_verbose("\aoPerforming xtarget check.")
	local ignore_list = {}
	local ignore_mob = _G.State:readXtargIgnore()
	if ignore_mob ~= "" then
		if string.find(ignore_mob, "|") then
			for word in string.gmatch(ignore_mob, "([^|]+)") do
				table.insert(ignore_list, word)
			end
			logger.log_info("\aoIgnoring xtarget check.")
			return false
		end
	end
	if mq.TLO.Me.XTarget() then
		if mq.TLO.Me.XTarget() >= char_settings.general.xtargClear then
			local haterCount = 0
			local should_hate = true
			for i = 1, mq.TLO.Me.XTargetSlots() do
				if mq.TLO.Me.XTarget(i).TargetType() == "Auto Hater" and mq.TLO.Me.XTarget(i)() ~= "" then
					if ignore_mob ~= nil then
						if #ignore_list > 0 then
							for _, mob in pairs(ignore_list) do
								if mq.TLO.Me.XTarget(i).CleanName() == mob then
									should_hate = false
									logger.log_info("\aoIgnore mob on xtarget check.")
								end
							end
						else
							if mq.TLO.Me.XTarget(i).CleanName() == ignore_mob then
								should_hate = false
								logger.log_info("\aoIgnore mob on xtarget check.")
							end
						end
					end
					if should_hate then
						haterCount = haterCount + 1
					end
				end
			end
			if haterCount >= char_settings.general.xtargClear then
				logger.log_info("\aoSuffecient auto hater targets found. Calling clear xtarget function.")
				return true
			end
		end
	end
	return false
end

-- Search for placeholder at the indicated location, goto gotostep if found, next step if not
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
function mob.ph_search(item, class_settings, char_settings)
	if mob.xtargetCheck(char_settings) then
		mob.clearXtarget(class_settings, char_settings)
	end
	_G.State:setStatusText(string.format("Searching for PH for %s.", item.npc))
	logger.log_info("\aoSearching for PH for \ag%s\ao.", item.npc)
	local spawn_search = "npc loc "
		.. item.whereX
		.. " "
		.. item.whereY
		.. " "
		.. item.whereZ
		.. " radius "
		.. item.radius
	if mq.TLO.Spawn(spawn_search).ID() ~= 0 then
		logger.log_info("\aoPH found. Moving to step: \ar%s\ao.", _G.State.current_step)
		_G.State:handle_step_change(item.gotostep)
	end
	mq.delay(500)
end

-- Clear the mobs from the Xtarget List
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
function mob.clearXtarget(class_settings, char_settings)
	logger.log_info("\aoClearing all auto hater targets from XTarget list.")
	local temp = _G.State:readStatusText()
	local max_xtargs = mq.TLO.Me.XTargetSlots()
	local looping = true
	local loopCount = 0
	local i = 0
	local idList = {}
	local ignore_list = {}
	local ignore_mob = _G.State:readXtargIgnore()
	local should_skip = false
	if ignore_mob ~= "" then
		if string.find(ignore_mob, "|") then
			for word in string.gmatch(ignore_mob, "([^|]+)") do
				table.insert(ignore_list, word)
			end
		end
	end
	while looping do
		local skip_count = 0
		mq.delay(200)
		i = i + 1
		loopCount = loopCount + 1
		if mq.TLO.Me.XTarget(i).CleanName() ~= nil and ignore_mob ~= "" then
			if #ignore_list > 0 then
				for _, mob in pairs(ignore_list) do
					if mq.TLO.Me.XTarget(i)() == mob then
						logger.log_info("\aoIgnore mob on xtarget check.")
						skip_count = skip_count + 1
						should_skip = true
					end
				end
			else
				if mq.TLO.Me.XTarget(i)() == ignore_mob then
					logger.log_info("\aoIgnore mob on xtarget check.")
					skip_count = skip_count + 1
					should_skip = true
				end
			end
		end
		if should_skip == false then
			if mq.TLO.Me.XTarget(i)() ~= "" and mq.TLO.Me.XTarget(i).TargetType() == "Auto Hater" then
				if mq.TLO.Me.XTarget(i).CleanName() ~= nil then
					if mq.TLO.Me.XTarget(i).TargetType() == "Auto Hater" and mq.TLO.Me.XTarget(i)() ~= "" then
						if mq.TLO.Me.XTarget(i).Distance() ~= nil then
							logger.log_verbose("\aoTargeting XTarget #\ag%s\ao.", i)
							mq.TLO.Me.XTarget(i).DoTarget()
							ID = mq.TLO.Me.XTarget(i).ID()
							_G.State:setStatusText(
								string.format("Clearing XTarget %s: %s (%s).", i, mq.TLO.Me.XTarget(i)(), ID)
							)
							logger.log_info(
								"\aoClearing XTarget \ag%s \ao: \ag%s \ao(\ag%s\ao).",
								i,
								mq.TLO.Me.XTarget(i)(),
								ID
							)
							manage.unpauseGroup(class_settings)
							mq.cmd("/stick")
							mq.delay(100)
							mq.cmd("/attack on")
							while mq.TLO.Spawn(ID).Type() == "NPC" do
								local breakout = true
								for j = 1, max_xtargs do
									if mq.TLO.Me.XTarget(j).ID() == ID then
										breakout = false
									end
								end
								if breakout == true then
									break
								end
								if mq.TLO.Target.ID() ~= ID then
									mq.TLO.Spawn(ID).DoTarget()
								end
								if mq.TLO.Me.Combat() == false then
									logger.log_super_verbose(
										"\aoAttack was off when it should have been on. Turning it back on."
									)
									mq.cmd("/attack on")
								end
								mq.delay(200)
							end
							i = 0
							loopCount = 0
							if i > mq.TLO.Me.XTarget() then
								i = 0
							end
						else
							i = 0
						end
					end
				end
			end
		end
		if loopCount == 20 then
			i = 0
			loopCount = 0
		end
		if mq.TLO.Me.XTarget() == 0 then
			looping = false
		end
		local continueLoop = false
		local target_count = 0
		for j = 1, max_xtargs do
			if mq.TLO.Me.XTarget(j).TargetType() == "Auto Hater" and mq.TLO.Me.XTarget(j)() ~= "" then
				target_count = target_count + 1
				continueLoop = true
			else
			end
		end
		if skip_count >= target_count then
			continueLoop = false
		end
		if continueLoop == false then
			looping = false
		end
	end
	manage.pauseGroup(class_settings)
	logger.log_info("\aoAll auto hater targets cleared from XTarget list.")
	if mq.TLO.Stick.Active() == true then
		mq.cmd("/stick off")
	end
	_G.State:setStatusText(temp)
end

-- Predicate for spawn filter matching
---@param spawn spawn
---@return boolean
local function matchFilters(spawn)
	if
		string.find(string.lower(spawn.CleanName()), string.lower(searchFilter))
		and (
			spawn.Type() == "NPC"
			or spawn.Type() == "Trigger"
			or spawn.Type() == "Chest"
			or spawn.Type() == "Corpse"
			or spawn.Type() == "Pet"
		)
	then
		for _, ID in pairs(_G.State.bad_IDs) do
			if spawn.ID() == ID then
				return false
			end
		end
		return true
	end
	return false
end

-- Create a list of spawns matching the filters
---@return spawn[]
local function create_spawn_list()
	logger.log_verbose("\aoCreating spawn list.")
	local mob_list = mq.getFilteredSpawns(matchFilters)
	return mob_list
end

--Check if spawn is up (for farm_radius function)
---@param item Item
---@return number
function mob.checkSpawn(item)
	if item.npc == nil then
		return 0
	end
	local ID = mq.TLO.Spawn("npc " .. item.npc).ID()
	return ID
end

-- find the nearest NPC by name
---@param npc string
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
---@return string|nil
function mob.findNearestName(npc, item, class_settings, char_settings)
	_G.State:setStatusText(string.format("Searching for nearest %s.", npc))
	searchFilter = npc
	logger.log_info("\aoSearching for nearest \ag%s\ao.", npc)
	local mob_list = create_spawn_list()
	local closest_distance = 25000
	local closest_ID = 0
	local loopCount = 0
	local looted = false
	while closest_ID == 0 do
		local foundCorpse = false
		loopCount = loopCount + 1
		if loopCount == 10 then
			loopCount = 0
			mob_list = create_spawn_list()
		end
		mq.delay(200)
		for _, spawn in pairs(mob_list) do
			if mq.TLO.Navigation.PathExists("id " .. spawn.ID())() then
				if mq.TLO.Navigation.PathLength("id " .. spawn.ID())() < closest_distance then
					if spawn.Type() == "Corpse" then
						foundCorpse = true
					else
						if item.whereX then
							local distance = dist.GetDistance3D(
								spawn.X(),
								spawn.Y(),
								spawn.Z(),
								item.whereX,
								item.whereY,
								item.whereZ
							)
							if distance > 50 then
								logger.log_verbose(
									"\aoFound \ag%s \aobut it is not the proper spawn, continuing search.",
									item.npc
								)
							else
								closest_distance = mq.TLO.Navigation.PathLength("id " .. spawn.ID())()
								closest_ID = spawn.ID()
							end
						else
							closest_distance = mq.TLO.Navigation.PathLength("id " .. spawn.ID())()
							closest_ID = spawn.ID()
						end
					end
				end
			else
			end
		end
		if _G.State.should_skip == true then
			return
		end
		if mob.xtargetCheck(char_settings) then
			mob.clearXtarget(class_settings, char_settings)
		end
		if _G.State:readPaused() then
			_G.Actions.pauseTask(_G.State:readStatusText())
		end
		if char_settings.general.speedForTravel == true then
			local speedChar, speedSkill = travel.speedCheck(class_settings, char_settings)
			if speedChar ~= "none" then
				travel.doSpeed(speedChar, speedSkill)
			end
		end
		if travel.invisCheck(item, char_settings, class_settings, item.invis) then
			travel.invis(class_settings)
		end
		if item.type == "NPC_KILL" then
			if item.what ~= nil then
				if inv.loot_check(item) then
					looted = inv.loot(item)
				end
				if inv.item_check(item) == true and looted == false then
					looted = true
				end
			end
			if looted then
				break
			end
			if item.named == 1 then
				if closest_ID == 0 then
					if mq.TLO.Spawn("corpse " .. item.npc).ID() ~= 0 then
						if item.gotostep ~= nil then
							logger.log_warn(
								"\ar%s \aohas already been killed. Advancing to step: \ag%s\ao.",
								item.npc,
								item.step + 1
							)
							_G.State:handle_step_change(item.gotostep)
						else
							logger.log_warn(
								"\ar%s \aohas already been killed. Advancing to step: \ag%s\ao.",
								item.npc,
								item.gotostep
							)
							_G.State:handle_step_change(item.step + 1)
						end
						_G.State:handle_step_change(item.gotostep)
						return nil
					end
				end
			end
		end
		if item.type == "NPC_SEARCH" then
			if closest_ID == 0 then
				logger.log_debug("\ar%s \ao not found. Advancing to next step.", item.npc)
				_G.State:handle_step_change(_G.State.current_step + 1)
				return nil
			end
		end
		--[[if closest_ID == 0 then
            logger.log_warn("\aoUnable to find \ar%s\ao.", npc)
            return nil
        end--]]
	end
	logger.log_verbose("\aoNearest ID found is \ag%s\ao.", closest_ID)
	return tostring(closest_ID) or nil
end

-- Find the nearest spawn, non-npc
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
function mob.general_search(item, class_settings, char_settings)
	if item.zone == nil then
		if mob.xtargetCheck(char_settings) then
			mob.clearXtarget(class_settings, char_settings)
		end
	end
	_G.State:setStatusText(string.format("Searching for %s.", item.npc))
	logger.log_info("\aoSearching for \ag%s\ao.", item.npc)
	local looping = true
	local i = 1
	while looping do
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		local ID = mob.findNearestName(item.npc, item, class_settings, char_settings) or 0
		if ID ~= 0 then
			logger.log_verbose(
				"\aoFound \ag%s \ao(\ag%s\ao) going to step \ar%s\ao.",
				item.npc,
				ID,
				_G.State.current_step
			)
			_G.State:handle_step_change(item.gotostep)
			return
		else
			--Does this ever trigger?
			if item.zone ~= nil then
				_G.State:handle_step_change(item.backstep)
				logger.log_warn(
					"\aoUnable to find \ar%s \aolooping back to step \ar%s\ao.",
					item.npc,
					_G.State.current_step
				)
			end
			return
		end
		i = i + 1
	end
end

-- Damage npc slowly
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
function mob.npc_slow_kill(item, class_settings, char_settings)
	local ID = 0
	if mq.TLO.Spawn("npc " .. item.npc).ID() ~= 0 then
		ID = mq.TLO.Spawn("npc " .. item.npc).ID()
	else
		logger.log_error("\aoThe NPC (\ar%s\ao) was not found.", item.npc)
		_G.State:setTaskRunning(false)
		mq.cmd("/foreground")
		return
	end
	mq.TLO.Spawn(ID).DoTarget()
	mq.cmd("/face away")
	mq.cmd("/keypress DUCK")
	local looping = true
	while looping do
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		if mq.TLO.Me.Ducking() == false then
			mq.cmd("/keypress DUCK")
		end
		if _G.State:readPaused() then
			_G.Actions.pauseTask(_G.State:readStatusText())
		end
		local remaining_pct = mq.TLO.Target.PctHPs() - item.damage_pct
		if item.count ~= nil then
			if remaining_pct < 20 then
				mob.cast_at(2, ID, item)
			else
				mob.cast_at(1, ID, item)
			end
		else
			if remaining_pct > 0 then
				mob.cast_at(1, ID, item)
			end
		end
		if mq.TLO.Spawn(ID)() == nil then
			mq.cmd("/stopcast")
			looping = false
		elseif mq.TLO.Spawn("npc " .. item.npc).PctHPs() < item.damage_pct then
			mq.cmd("/stopcast")
			local angle = mq.TLO.Target.HeadingTo.DegreesCCW() - mq.TLO.Me.Heading.DegreesCCW()
			if angle > 230 or angle < 130 then
				mq.cmd("/face away")
			end
			if mq.TLO.Me.Ducking() == false then
				mq.cmd("/keypress DUCK")
			end
			looping = false
		end
	end
end

---Cast a spell at the selected NPC (for npc_slow_kill)
---@param spell_slot number
---@param ID number
---@param item Item
function mob.cast_at(spell_slot, ID, item)
	if mq.TLO.Me.SpellReady(spell_slot)() then
		if mq.TLO.Me.Ducking() == true then
			if mq.TLO.Target() == nil then
				if mq.TLO.Spawn(ID)() ~= nil then
					mq.TLO.Spawn(ID).DoTarget()
				end
			end
			if mq.TLO.Target.CleanName() == item.npc then
				local angle = mq.TLO.Target.HeadingTo.DegreesCCW() - mq.TLO.Me.Heading.DegreesCCW()
				if angle > 230 or angle < 130 then
					mq.cmd("/face away")
				end
				mq.cmd("/stand")
				mq.cmdf("/cast %s", spell_slot)
				while mq.TLO.Me.Casting() == false do
					mq.delay(50)
				end
				while mq.TLO.Me.Casting() do
					mq.delay(100)
				end
			end
		end
	end
end

-- Check if we are too high of level and prepare a lower level skill/spell/song if so
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
function mob.pre_damage_until(item, class_settings, char_settings)
	logger.log_info("\aoChecking if level is higher than \ag%s\ao.", item.maxlevel)
	_G.State:setStatusText(string.format("Checking if level is higher than %s.", item.maxlevel))
	if mq.TLO.Me.Level() >= item.maxlevel then
		if item.npc ~= nil then
			logger.log_debug(
				"\aoLevel is higher than \ag%s\ao. Preparing low damage skills (\ag%s\ao - \ag%s\ao).",
				item.maxlevel,
				item.npc,
				item.what
			)
			_G.State:setStatusText(
				string.format(
					"Level is higher than %s. Preparing low damage skills (%s - %s).",
					item.maxlevel,
					item.npc,
					item.what
				)
			)
			mq.cmdf('/memspell 1 "%s"', item.npc)
			mq.delay("1s")
			while mq.TLO.Me.Gem(item.npc)() ~= 1 do
				logger.log_verbose("\aoWaiting for \ag%s \aoto memorize in spell slot \ag1\ao.", item.npc)
				if mob.xtargetCheck(char_settings) then
					mob.clearXtarget(class_settings, char_settings)
				end
				mq.delay("1s")
				mq.cmdf('/memspell 1 "%s"', item.npc)
			end
			mq.cmdf('/memspell 2 "%s"', item.what)
			mq.delay("1s")
			while mq.TLO.Me.Gem(item.what)() ~= 2 do
				logger.log_verbose("\aoWaiting for \ag%s \aoto memorize in spell slot \ag2\ao.", item.what)
				if mob.xtargetCheck(char_settings) then
					mob.clearXtarget(class_settings, char_settings)
				end
				mq.delay("1s")
				mq.cmdf('/memspell 2 "%s"', item.what)
			end
		else
			logger.log_debug(
				"\aoLevel is higher than \ag%s\ao. Preparing low damage skill (\ag%s\ao).",
				item.maxlevel,
				item.what
			)
			_G.State:setStatusText(
				string.format("Level is higher than %s. Preparing low damage skill (%s).", item.maxlevel, item.what)
			)
			mq.cmdf('/memspell 1 "%s"', item.what)
			while mq.TLO.Me.Gem(item.what)() ~= 1 do
				if mob.xtargetCheck(char_settings) then
					mob.clearXtarget(class_settings, char_settings)
				end
				mq.delay(100)
				mq.cmdf('/mem 1 "%s"', item.what)
			end
		end
	end
end

-- Damage npc until below a certain percentage of health
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
function mob.npc_damage_until(item, class_settings, char_settings)
	_G.State:setStatusText(string.format("Damaging %s to below %s%% health.", item.npc, item.damage_pct))
	logger.log_info("\aoDamaging \ag%s \aoto below \ag%s%% health\ao.", item.npc, item.damage_pct)
	ID = mq.TLO.Spawn("npc " .. item.npc).ID()
	if mq.TLO.Spawn(ID).Distance() ~= nil then
		if mq.TLO.Spawn(ID).Distance() > MAX_DISTANCE then
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
	logger.log_debug("\aoChecking buffs for any damage shields and removing them.")
	_G.Actions.RemoveDamageShields()
	if item.maxlevel ~= nil then
		if mq.TLO.Me.Level() >= item.maxlevel then
			logger.log_warn("\aoOur level is \ag%s \aoor higher. Being cautious.", item.maxlevel)
			mob.npc_slow_kill(item, class_settings, char_settings)
		end
	end
	mq.TLO.Spawn(ID).DoTarget()
	mq.cmd("/stick")
	mq.delay(100)
	mq.cmd("/attack on")
	local looping = true
	while looping do
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		if mq.TLO.Spawn(ID)() == nil then
			looping = false
		else
			if mq.TLO.Spawn(ID).PctHPs() < item.damage_pct then
				looping = false
			end
		end
		mq.delay(50)
	end
	mq.cmd("/attack off")
	logger.log_info("\aoTarget has either despawned or has decreased below \ag%s \aohealth.", item.damage_pct)
end

-- Kill the indicated npc, loot indicated items if present.
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
function mob.npc_kill(item, class_settings, char_settings)
	manage.removeInvis(item)
	_G.State:setStatusText(string.format("Killing %s.", item.npc))
	logger.log_info("\aoKilling \ag%s\ao.", item.npc)
	manage.unpauseGroup(class_settings)
	mq.delay(200)
	local ID = mob.findNearestName(item.npc, item, class_settings, char_settings) or 0
	if mq.TLO.Spawn(ID).Distance() ~= nil then
		if mq.TLO.Spawn(ID).Distance() > MAX_DISTANCE then
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
	local looted = false
	if item.what ~= nil then
		if inv.loot_check(item) then
			looted = inv.loot(item)
		end
		if inv.item_check(item) == true and looted == false then
			looted = true
		end
	end
	if looted == false then
		if ID ~= 0 then
			_G.State:setStatusText(string.format("Killing %s (%s).", item.npc, ID))
			logger.log_info("\aoKilling \ag%s \ao(\ag%s\ao).", item.npc, ID)
			logger.log_verbose("\aoTargeting \ag%s \ao(\ag%s\ao).", item.npc, ID)
			mq.TLO.Spawn(ID).DoTarget()
		end
		mq.cmd("/stick")
		mq.delay(100)
		mq.cmd("/attack on")
		logger.log_super_verbose("\aoGenerating events to detect unhittable or bugged target.")
		mq.event("cannot_see", "You cannot see your target.", target_invalid_switch)
		mq.event("cannot_cast", "You cannot cast#*#on#*#", target_invalid_switch)
		while mq.TLO.Spawn(ID).Type() == "NPC" or mq.TLO.Spawn(ID).Type() == "Chest" do
			mq.doevents()
			if _G.State.should_skip == true then
				mq.unevent("cannot_see")
				mq.unevent("cannot_cast")
				_G.State.should_skip = false
				return
			end
			if _G.State.cannot_count > 9 then
				_G.State.cannot_count = 0
				table.insert(_G.State.bad_IDs, ID)
				mq.unevent("cannot_see")
				mq.unevent("cannot_cast")
				logger.log_warn(
					"\aoUnable to hit this target. Adding \ar%s \aoto bad IDs and moving back to step \ar%s\ao.",
					ID,
					_G.State.current_step
				)
				if item.count == 1 then
					_G.State:handle_step_change(item.gotostep)
				end
				_G.State:handle_step_change(_G.State.current_step)
				return
			end
			if mq.TLO.Target.ID() ~= ID then
				logger.log_verbose("\aoRetargeting \ag%s\ao.", ID)
				mq.TLO.Spawn(ID).DoTarget()
			end
			if mq.TLO.Me.Combat() == false then
				logger.log_super_verbose("\aoAttack was off when it should have been on. Turning it back on.")
				mq.cmd("/attack on")
			end
			mq.delay(200)
			if item.what ~= nil then
				if inv.loot_check(item) then
					looted = inv.loot(item)
				end
				if inv.item_check(item) == true and looted == false then
					looted = true
				end
			end
			if looted then
				break
			end
		end
		mq.unevent("cannot_see")
		mq.unevent("cannot_cast")
		manage.pauseGroup(class_settings)
		mq.delay("2s")
		_G.State.cannot_count = 0
	end
	if item.what ~= nil then
		if inv.loot_check(item) then
			looted = inv.loot(item)
		end
		if inv.item_check(item) == true and looted == false then
			looted = true
		end
	end
	if item.gotostep ~= nil then
		_G.State:handle_step_change(item.gotostep)
	end
end

-- Kill all of the npc of the indicated name
---@param item Item
---@param class_settings Class_Settings_Settings
---@param char_settings Char_Settings_SaveState
function mob.npc_kill_all(item, class_settings, char_settings)
	manage.removeInvis(item)
	_G.State:setStatusText(string.format("Killing all %s.", item.npc))
	logger.log_info("\aoKilling all \ag%s\ao.", item.npc)
	manage.unpauseGroup(class_settings)
	while true do
		if _G.State.should_skip == true then
			_G.State.should_skip = false
			return
		end
		if mq.TLO.Spawn("npc " .. item.npc).ID() == 0 then
			logger.log_info("\aoNo \ar%s \ao found.", item.npc)
			break
		end
		mq.delay(500)
		if _G.State:readPaused() then
			_G.Actions.pauseTask(_G.State:readStatusText())
		end
		local ID = mob.findNearestName(item.npc, item, class_settings, char_settings) or 0
		travel.general_travel(item, class_settings, char_settings, ID, _G.State:readGroupSelection())
		if mq.TLO.Spawn(ID).Distance() ~= nil then
			if mq.TLO.Spawn(ID).Distance() > MAX_DISTANCE then
				logger.log_warn("\ar%s \aois over %s units away. Moving closer.", item.npc, MAX_DISTANCE)
				_G.State:handle_step_change(_G.State.current_step)
				return
			end
		end
		logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
		mq.TLO.Spawn(ID).DoTarget()
		mq.cmd("/stick")
		mq.delay(100)
		mq.cmd("/attack on")
		while mq.TLO.Me.Casting() do
			mq.delay(100)
		end
		if item.zone ~= nil then
			local altID = mq.TLO.Me.AltAbility(item.zone)()
			mq.cmdf("/alt act %s", altID)
			logger.log_verbose("\aoCasting \ag%s \ao(\ag%s\ao) to pull.", item.zone, altID)
			mq.delay("1s")
		end
		local loopCount = 0
		while mq.TLO.Spawn(ID).Type() == "NPC" do
			if _G.State.should_skip == true then
				manage.pauseGroup(class_settings)
				_G.State.should_skip = false
				return
			end
			mq.delay(200)
			if mq.TLO.Spawn(ID).Distance() ~= nil then
				if mq.TLO.Spawn(ID).Distance() > MAX_DISTANCE then
					logger.log_warn("\ar%s \aois over %s units away. Moving closer.", item.npc, MAX_DISTANCE)
					_G.State:handle_step_change(_G.State.current_step)
					return
				end
			end
			logger.log_verbose("\aoTargeting \ar%s\ao.", item.npc)
			mq.TLO.Spawn(ID).DoTarget()
			loopCount = loopCount + 1
			if loopCount == 20 then
				loopCount = 0
				if item.zone ~= nil then
					local altID = mq.TLO.Me.AltAbility(item.zone)()
					mq.cmdf("/alt act %s", altID)
					logger.log_verbose("\aoCasting \ag%s \ao(\ag%s\ao) to pull.", item.zone, altID)
					mq.delay("1s")
				end
				if mq.TLO.Me.Combat() == false then
					logger.log_super_verbose("\aoAttack was off when it should have been on. Turning it back on.")
					mq.cmd("/attack on")
				end
			end
		end
		if mq.TLO.FindItem("=" .. item.what)() == nil then
			inv.loot(item)
			_G.State:setStatusText(string.format("Killing all %s.", item.npc))
		end
	end
end

return mob
