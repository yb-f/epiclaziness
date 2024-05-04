local mq             = require('mq')
local class_settings = require 'utils/class_settings'
local loadsave       = require 'utils/loadsave'
local inv            = require 'utils/inventory'
local travel         = require 'utils/travel'
local manage         = require 'utils/manageautomation'
class_settings.loadSettings()
loadsave.loadState()

local task_functions = {
    ADVENTURE_ENTRANCE       = {
        func   = Actions.adventure_entrance,
        params = { class_settings.settings, loadsave.SaveState }
    },
    AUTO_INV                 = {
        func   = inv.auto_inv,
        params = {}
    },
    BACKSTAB                 = {
        func   = Mob.backstab,
        params = { class_settings.settings, loadsave.SaveState }
    },
    CAST_ALT                 = {
        func   = Actions.cast_alt,
        params = { class_settings.settings, loadsave.SaveState }
    },
    COMBINE_CONTAINER        = {
        func   = inv.combine_container,
        params = { class_settings.settings, loadsave.SaveState }
    },
    COMBINE_DO               = {
        func   = inv.combine_do,
        params = { class_settings.settings, loadsave.SaveState, State.combineSlot }
    },
    COMBINE_DONE             = {
        func   = inv.combine_done,
        params = { class_settings.settings, loadsave.SaveState }
    },
    COMBINE_ITEM             = {
        func   = inv.combine_item,
        params = { class_settings.settings, loadsave.SaveState, State.combineSlot }
    },
    DROP_ADVENTURE           = {
        func   = Actions.drop_adventure,
        params = {}
    },
    ENVIRO_COMBINE_CONTAINER = {
        func   = inv.enviro_combine_container,
        params = {}
    },
    ENVIRO_COMBINE_DO        = {
        func   = inv.enviro_combine_do,
        params = {}
    },
    ENVIRO_COMBINE_ITEM      = {
        func   = inv.enviro_combine_item,
        params = {}
    },
    EQUIP_ITEM               = {
        func   = inv.equip_item,
        params = {}
    },
    EXCLUDE_NPC              = {
        func   = State.exclude_npc,
        params = {}
    },
    EXECUTE_COMMAND          = {
        func   = State.execute_command,
        params = {}
    },
    FACE_HEADING             = {
        func   = travel.face_heading,
        params = {}
    },
    FACE_LOC                 = {
        func   = travel.face_loc,
        params = {}
    },
    FARM_CHECK               = {
        func   = Actions.farm_check,
        params = { class_settings.settings, loadsave.SaveState }
    },
    FARM_CHECK_PAUSE         = {
        func   = Actions.farm_check_pause,
        params = { class_settings.settings, loadsave.SaveState }
    },
    FARM_RADIUS              = {
        func   = Actions.farm_radius,
        params = { class_settings.settings, loadsave.SaveState }
    },
    FARM_RADIUS_EVENT        = {
        func   = Actions.farm_radius,
        params = { class_settings.settings, loadsave.SaveState, true }
    },
    FARM_WHILE_NEAR          = {
        func   = Actions.farm_while_near,
        params = { class_settings.settings, loadsave.SaveState }
    },
    FISH_FARM                = {
        func   = Actions.fish_farm,
        params = { class_settings.settings, loadsave.SaveState }
    },
    FISH_ONCE                = {
        func   = Actions.fish_farm,
        params = { class_settings.settings, loadsave.SaveState, true }
    },
    FORAGE_FARM              = {
        func   = Actions.forage_farm,
        params = { class_settings.settings, loadsave.SaveState }
    },
    FORWARD_ZONE             = {
        func   = travel.forward_zone,
        params = { class_settings.settings, loadsave.SaveState }
    },
    GENERAL_SEARCH           = {
        func   = Mob.general_search,
        params = { class_settings.settings, loadsave.SaveState }
    },
    GENERAL_TRAVEL           = {
        func   = travel.general_travel,
        params = { class_settings.settings, loadsave.SaveState }
    },
    GROUND_SPAWN             = {
        func   = Actions.ground_spawn,
        params = { class_settings.settings, loadsave.SaveState }
    },
    GROUND_SPAWN_FARM        = {
        func   = Actions.ground_spawn_farm,
        params = { class_settings.settings, loadsave.SaveState }
    },
    GROUP_SIZE_CHECK         = {
        func   = Actions.group_size_check,
        params = {}
    },
    IGNORE_MOB               = {
        func   = Actions.group_size_check,
        params = { class_settings.settings }
    },
    LDON_COUNT_CHECK         = {
        func   = Actions.ldon_count_check,
        params = {}
    },
    LOC_TRAVEL               = {
        func   = travel.loc_travel,
        params = { class_settings.settings, loadsave.SaveState }
    },
    LOOT                     = {
        func   = inv.loot,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NO_NAV_TRAVEL            = {
        func   = travel.no_nav_travel,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_BUY                  = {
        func   = inv.npc_buy,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_DAMAGE_UNTIL         = {
        func   = Mob.npc_damage_until,
        params = {}
    },
    NPC_FOLLOW               = {
        func   = travel.npc_follow,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_FOLLOW_EVENT         = {
        func   = travel.npc_follow,
        params = { class_settings.settings, loadsave.SaveState, true }
    },
    NPC_GIVE                 = {
        func   = Actions.npc_give,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_GIVE_ADD             = {
        func   = Actions.npc_give_add,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_GIVE_CLICK           = {
        func   = Actions.npc_give_click,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_GIVE_MONEY           = {
        func   = Actions.npc_give_money,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_HAIL                 = {
        func   = Actions.npc_hail,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_KILL                 = {
        func   = Mob.npc_kill,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_KILL_ALL             = {
        func   = Mob.npc_kill_all,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_SEARCH               = {
        func   = Mob.general_search,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_STOP_FOLLOW          = {
        func   = travel.npc_stop_follow,
        params = {}
    },
    NPC_TALK                 = {
        func   = Actions.npc_talk,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_TALK_ALL             = {
        func   = Actions.npc_talk_all,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_TRAVEL               = {
        func   = travel.npc_travel,
        params = { class_settings.settings, false, loadsave.SaveState }
    },
    NPC_TRAVEL_NO_PATH_CHECK = {
        func   = travel.npc_travel,
        params = { class_settings.settings, true, loadsave.SaveState }
    },
    NPC_WAIT                 = {
        func   = Actions.npc_wait,
        params = { class_settings.settings, loadsave.SaveState }
    },
    NPC_WAIT_DESPAWN         = {
        func   = Actions.npc_wait_despawn,
        params = { class_settings.settings, loadsave.SaveState }
    },
    OPEN_DOOR                = {
        func   = travel.open_door,
        params = {}
    },
    OPEN_DOOR_ALL            = {
        func   = inv.loot,
        params = { class_settings.settings, loadsave.SaveState }
    },
    PAUSE                    = {
        func   = State.pause,
        params = {}
    },
    PH_SEARCH                = {
        func   = Mob.ph_search,
        params = { class_settings.settings, loadsave.SaveState }
    },
    PICK_DOOR                = {
        func   = manage.picklockGroup,
        params = {}
    },
    PICK_POCKET              = {
        func   = Actions.pickpocket,
        params = {}
    },
    PICKUP_KEY               = {
        func   = inv.pickup_key,
        params = {}
    },
    PORTAL_SET               = {
        func   = travel.portal_set,
        params = {}
    },
    PRE_FARM_CHECK           = {
        func   = Actions.pre_farm_check,
        params = { class_settings.settings, loadsave.SaveState }
    },
    RELOCATE                 = {
        func   = travel.relocate,
        params = { class_settings.settings, loadsave.SaveState }
    },
    REMOVE_INVIS             = {
        func   = manage.removeInvis,
        params = {}
    },
    RESTORE_ITEM             = {
        func   = inv.restore_item,
        params = {}
    },
    ROG_GAMBLE               = {
        func   = Actions.rogue_gamble,
        params = {}
    },
    SAVE                     = {
        func   = State.save,
        params = {}
    },
    START_ADVENTURE          = {
        func   = Actions.start_adventure,
        params = {}
    },
    SEND_YES                 = {
        func   = manage.sendYes,
        params = {}
    },
    SNEAK                    = {
        func   = Actions.sneak,
        params = {}
    },
    UNIGNORE_MOB             = {
        func   = Actions.unignore_mob,
        params = { class_settings.settings }
    },
    WAIT                     = {
        func   = Actions.wait,
        params = { class_settings.settings, loadsave.SaveState }
    },
    WAIT_EVENT               = {
        func   = Actions.wait_event,
        params = {}
    },
    WAIT_FOR                 = {
        func   = Actions.wait_for,
        params = {}
    },
    ZONE_CONTINUE_TRAVEL     = {
        func   = travel.zone_travel,
        params = { class_settings.settings, loadsave.SaveState, true }
    },
    ZONE_TRAVEL              = {
        func   = travel.zone_travel,
        params = { class_settings.settings, loadsave.SaveState, true }
    },
}

return task_functions
