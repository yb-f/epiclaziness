local class_settings = require('utils/class_settings')
local loadsave       = require('utils/loadsave')
local inv            = require('utils/inventory')
local travel         = require('utils/travel')
local manage         = require('utils/manageautomation')
local mob            = require('utils/mob')
local logger         = require('utils/logger')

class_settings.loadSettings()
loadsave.loadState()

local task_functions = {
    ADVENTURE_ENTRANCE       = {
        func   = _G.Actions.adventure_entrance,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = 'Determine which LDON Entrance to use.',
    },
    AUTO_INV                 = {
        func   = inv.auto_inv,
        params = {},
        desc   = 'Move item on cursor to inventory.',
    },
    BACKSTAB                 = {
        func   = mob.backstab,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Backstab' .. item.npc end
    },
    CAST_ALT                 = {
        func   = _G.Actions.cast_alt,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Cast alt ability ' .. item.what end
    },
    CLEAR_STORED_ITEMS       = {
        func   = inv.clear_stored_items,
        params = {},
        desc   = 'Clear list of stored items.'
    },
    CLICK_SWITCH             = {
        func   = travel.click_switch,
        params = {},
        desc   = 'Click switch'
    },
    COMBINE_CONTAINER        = {
        func   = inv.combine_container,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Prepare to combine items in ' .. item.what end
    },
    COMBINE_DO               = {
        func   = inv.combine_do,
        params = function() return { class_settings.settings, loadsave.SaveState, _G.State.combineSlot } end,
        desc   = 'Perform combine'
    },
    COMBINE_DONE             = {
        func   = inv.combine_done,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = 'Combine complete, restore item to previous bag slot.'
    },
    COMBINE_ITEM             = {
        func   = inv.combine_item,
        params = function() return { class_settings.settings, loadsave.SaveState, _G.State.combineSlot } end,
        desc   = function(item) return 'Add ' .. item.what .. ' to combine container' end
    },
    DROP_ADVENTURE           = {
        func   = _G.Actions.drop_adventure,
        params = {},
        desc   = 'Leave current adventure.'
    },
    DZ_CHECK                 = {
        func   = _G.Actions.dz_check,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Check if we received the proper DZ (' .. item.zone .. ')' end
    },
    ELEVATOR_CHECK           = {
        func   = travel.elevator_check,
        params = {},
        desc   = 'Check location of elevator.'
    },
    ENVIRO_COMBINE_CONTAINER = {
        func   = inv.enviro_combine_container,
        params = {},
        desc   = function(item) return 'Travel to ' .. item.what .. ' and prepare combine' end
    },
    ENVIRO_COMBINE_DO        = {
        func   = inv.enviro_combine_do,
        params = {},
        desc   = 'Perform combine in enviromental container'
    },
    ENVIRO_COMBINE_ITEM      = {
        func   = inv.enviro_combine_item,
        params = {},
        desc   = function(item) return 'Add ' .. item.what .. ' to enviromental combine container' end
    },
    EQUIP_ITEM               = {
        func   = inv.equip_item,
        params = {},
        desc   = function(item) return 'Equip ' .. item.what end
    },
    EXCLUDE_NPC              = {
        func   = _G.State.exclude_npc,
        params = {},
        desc   = function(item) return 'Exclude ' .. item.npc .. ' from pull list' end
    },
    EXECUTE_COMMAND          = {
        func   = _G.State.execute_command,
        params = {},
        desc   = function(item) return 'Execute command: ' .. item.what end
    },
    FACE_HEADING             = {
        func   = travel.face_heading,
        params = function() return { _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Face the heading ' .. item.what end
    },
    FACE_LOC                 = {
        func   = travel.face_loc,
        params = function() return { _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Face location ' .. item.whereY .. ', ' .. item.whereX .. ', ' .. item.whereZ end
    },
    FARM_CHECK               = {
        func   = _G.Actions.farm_check,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Check if we have the items we need: ' .. item.what end
    },
    FARM_CHECK_PAUSE         = {
        func   = _G.Actions.farm_check_pause,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Check if we have ' .. item.what .. ' pause script of we do not' end
    },
    FARM_RADIUS              = {
        func   = _G.Actions.farm_radius,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Farm for ' .. item.what end
    },
    FARM_RADIUS_EVENT        = {
        func   = _G.Actions.farm_radius,
        params = function() return { class_settings.settings, loadsave.SaveState, true } end,
        desc   = function(item) return 'Farm until event occurs. (' .. item.phrase .. ')' end
    },
    FARM_WHILE_NEAR          = {
        func   = _G.Actions.farm_while_near,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Farm until ' .. item.npc .. ' moves away.' end
    },
    FISH_FARM                = {
        func   = _G.Actions.fish_farm,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Fish for ' .. item.what end
    },
    FISH_ONCE                = {
        func   = _G.Actions.fish_farm,
        params = function() return { class_settings.settings, loadsave.SaveState, true } end,
        desc   = 'Fish for one cast'
    },
    FORAGE_FARM              = {
        func   = _G.Actions.forage_farm,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Forage for ' .. item.what end
    },
    FORWARD_ZONE             = {
        func   = travel.forward_zone,
        params = function() return { class_settings.settings, loadsave.SaveState, _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Move forward to zone into ' .. item.zone end
    },
    GENERAL_SEARCH           = {
        func   = mob.general_search,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Searching for ' .. item.npc end
    },
    GENERAL_TRAVEL           = {
        func   = travel.general_travel,
        params = function() return { class_settings.settings, loadsave.SaveState, _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Travel to ' .. item.npc end
    },
    GROUND_SPAWN             = {
        func   = _G.Actions.ground_spawn,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Pickup ground spawn at ' .. item.whereY .. ', ' .. item.whereX .. ', ' .. item.whereZ end
    },
    GROUND_SPAWN_FARM        = {
        func   = _G.Actions.ground_spawn_farm,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Pickup ground spawns until we obtain ' .. item.what end
    },
    GROUP_SIZE_CHECK         = {
        func   = _G.Actions.group_size_check,
        params = {},
        desc   = function(item) return 'Making sure group has at least ' .. item.count .. ' players.' end
    },
    IGNORE_MOB               = {
        func   = _G.Actions.ignore_mob,
        params = function() return { class_settings.settings } end,
        desc   = function(item) return 'Add ' .. item.npc .. ' to pull ignore list' end
    },
    LDON_COUNT_CHECK         = {
        func   = _G.Actions.ldon_count_check,
        params = {},
        desc   = 'Check if LDON adventure is complete'
    },
    LOC_TRAVEL               = {
        func   = travel.loc_travel,
        params = function() return { class_settings.settings, loadsave.SaveState, _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Travel to ' .. item.whereY .. ', ' .. item.whereX .. ', ' .. item.whereZ end
    },
    LOOT                     = {
        func   = inv.loot,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Attempt to loot ' .. item.what end
    },
    NO_NAV_TRAVEL            = {
        func   = travel.no_nav_travel,
        params = function() return { class_settings.settings, loadsave.SaveState, _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Travel without using MQ2Nav to ' .. item.whereY .. ', ' .. item.whereX .. ', ' .. item.whereZ end
    },
    NPC_BUY                  = {
        func   = inv.npc_buy,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Purchase ' .. item.what .. ' from ' .. item.npc end
    },
    NPC_DAMAGE_UNTIL         = {
        func   = mob.npc_damage_until,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Damage ' .. item.npc .. ' to ' .. item.damage_pct .. '% health' end
    },
    NPC_FOLLOW               = {
        func   = travel.npc_follow,
        params = function() return { class_settings.settings, loadsave.SaveState, false, _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Follow ' .. item.npc end
    },
    NPC_FOLLOW_EVENT         = {
        func   = travel.npc_follow,
        params = function() return { class_settings.settings, loadsave.SaveState, true, _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Follow ' .. item.npc .. ' until event: ' .. item.phrase end
    },
    NPC_GIVE                 = {
        func   = _G.Actions.npc_give,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Give ' .. item.what .. ' to ' .. item.npc end
    },
    NPC_GIVE_ADD             = {
        func   = _G.Actions.npc_give_add,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Add ' .. item.what .. ' to give window with ' .. item.npc end
    },
    NPC_GIVE_CLICK           = {
        func   = _G.Actions.npc_give_click,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = 'Click give button'
    },
    NPC_GIVE_MONEY           = {
        func   = _G.Actions.npc_give_money,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Give money (' .. item.what .. ') to ' .. item.npc end
    },
    NPC_HAIL                 = {
        func   = _G.Actions.npc_hail,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Hail ' .. item.npc end
    },
    NPC_KILL                 = {
        func   = mob.npc_kill,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Kill ' .. item.npc end
    },
    NPC_KILL_ALL             = {
        func   = mob.npc_kill_all,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Kill all ' .. item.npc end
    },
    NPC_SEARCH               = {
        func   = mob.general_search,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Look for ' .. item.npc end
    },
    NPC_STOP_FOLLOW          = {
        func   = travel.npc_stop_follow,
        params = function() return { _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Stop following ' .. item.npc end
    },
    NPC_TALK                 = {
        func   = _G.Actions.npc_talk,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Say ' .. item.phrase .. ' to ' .. item.npc end
    },
    NPC_TALK_ALL             = {
        func   = manage.groupTalk,
        params = function() return { _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Have all characters say ' .. item.phrase .. ' to ' .. item.npc end
    },
    NPC_TRAVEL               = {
        func   = travel.npc_travel,
        params = function() return { class_settings.settings, false, loadsave.SaveState } end,
        desc   = function(item) return 'Move to ' .. item.npc end
    },
    NPC_TRAVEL_NO_PATH_CHECK = {
        func   = travel.npc_travel,
        params = function() return { class_settings.settings, true, loadsave.SaveState } end,
        desc   = function(item) return 'Move to ' .. item.npc .. ' (ignore path)' end
    },
    NPC_WAIT                 = {
        func   = _G.Actions.npc_wait,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Wait for ' .. item.npc .. ' to spawn' end
    },
    NPC_WAIT_DESPAWN         = {
        func   = _G.Actions.npc_wait_despawn,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Wait for ' .. item.npc .. ' to despawn' end
    },
    OPEN_DOOR                = {
        func   = travel.open_door,
        params = {},
        desc   = 'Open door'
    },
    OPEN_DOOR_ALL            = {
        func   = manage.openDoorAll,
        params = function() return { _G.State:readGroupSelection() } end,
        desc   = 'Group click door'
    },
    PAUSE                    = {
        func   = _G.State.pauseTask,
        params = {},
        desc   = 'Pause the script.'
    },
    PH_SEARCH                = {
        func   = mob.ph_search,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Search for PH ' .. item.npc end
    },
    PICK_DOOR                = {
        func   = manage.picklockGroup,
        params = function() return { _G.State:readGroupSelection() } end,
        desc   = 'Attempt to lockpick door'
    },
    PICK_POCKET              = {
        func   = _G.Actions.pickpocket,
        params = {},
        desc   = function(item) return 'Pickpocket ' .. item.what .. ' from ' .. item.npc end
    },
    PICKUP_KEY               = {
        func   = inv.pickup_key,
        params = {},
        desc   = function(item) return 'Move item (' .. item.what .. ') from inventory to cursor' end
    },
    PORTAL_SET               = {
        func   = travel.portal_set,
        params = {},
        desc   = function(item) return 'Set guild portal location to ' .. item.zone end
    },
    PRE_DAMAGE_UNTIL         = {
        func   = mob.pre_damage_until,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = 'Check if we need to ready a lower level skill to not kill mob.'
    },
    PRE_FARM_CHECK           = {
        func   = _G.Actions.pre_farm_check,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = 'Check if we have the items to skip the next steps'
    },
    RELOCATE                 = {
        func   = travel.relocate,
        params = function() return { class_settings.settings, loadsave.SaveState, _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Relocate to ' .. item.what end
    },
    REMOVE_INVIS             = {
        func   = manage.removeInvis,
        params = {},
        desc   = 'Remove invisibility'
    },
    REMOVE_WEAPONS           = {
        func   = inv.remove_weapons,
        params = {},
        desc   = 'Remove equiped weapons'
    },
    RESTORE_ITEM             = {
        func   = inv.restore_item,
        params = {},
        desc   = 'Reequip item'
    },
    RESTORE_WEAPONS          = {
        func   = inv.restore_weapons,
        params = {},
        desc   = 'Reequip weapons'
    },
    ROG_GAMBLE               = {
        func   = _G.Actions.rog_gamble,
        params = {},
        desc   = 'Gamble to 1900 chips'
    },
    SAVE                     = {
        func   = _G.State.save,
        params = {},
        desc   = 'Save progress'
    },
    START_ADVENTURE          = {
        func   = _G.Actions.start_adventure,
        params = {},
        desc   = function(item) return 'Request LDON adventure from ' .. item.npc end
    },
    SEND_YES                 = {
        func   = manage.sendYes,
        params = function() return { _G.State:readGroupSelection() } end,
        desc   = 'Select yes in confirmation box'
    },
    SNEAK                    = {
        func   = _G.Actions.sneak,
        params = {},
        desc   = 'Activate sneak'
    },
    UNIGNORE_MOB             = {
        func   = _G.Actions.unignore_mob,
        params = function() return { class_settings.settings } end,
        desc   = function(item) return 'Remove ' .. item.npc .. ' from pull ignore list.' end
    },
    WAIT                     = {
        func   = _G.Actions.wait,
        params = function() return { class_settings.settings, loadsave.SaveState } end,
        desc   = function(item) return 'Wait for ' .. item.wait / 1000 .. ' seconds' end
    },
    WAIT_CURSOR              = {
        func   = _G.Actions.wait_cursor,
        params = {},
        desc   = function(item) return 'Waiting for ' .. item.what .. ' on cursor.' end
    },
    WAIT_EVENT               = {
        func   = _G.Actions.wait_event,
        params = {},
        desc   = function(item) return 'Wait for event in chat to continue (' .. item.phrase .. ')' end
    },
    WAIT_FOR                 = {
        func   = _G.Actions.wait_for,
        params = {},
        desc   = function(item) return 'Wait until EQ Time: ' .. item.wait .. ':00.' end
    },
    WAIT_Z_LOC               = {
        func   = travel.wait_z_loc,
        params = {},
        desc   = function(item) return 'Wait until Z location is ' .. item.whereZ end
    },
    ZONE_CONTINUE_TRAVEL     = {
        func   = travel.zone_travel,
        params = function() return { class_settings.settings, loadsave.SaveState, true, _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Travel to ' .. item.zone end
    },
    ZONE_TRAVEL              = {
        func   = travel.zone_travel,
        params = function() return { class_settings.settings, loadsave.SaveState, false, _G.State:readGroupSelection() } end,
        desc   = function(item) return 'Travel to ' .. item.zone end
    },
}

return task_functions
