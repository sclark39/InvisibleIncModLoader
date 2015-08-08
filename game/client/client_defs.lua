----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include("modules/util")
local mui_defs = include( "mui/mui_defs" )
local mui_util = include( "mui/mui_util" )

--
-- Client-side definitions and constants, shared across multiple modules.

local cdefs = {}

-- Global, remappable key bindings.
-- NOTE: The order that the bindings show up here reflects the order they are listed in the UI.
-- NOTE2: Entries with txt but no name/binding show up as 'header' entries in the UI.
--  name: unique identifier for this keybinding; used to query the binding and stored in save data (DO NOT THEREFORE CHANGE)
--  txt: localized text to represent this key binding in the controls mapping UI
--  defaultBinding: default key binding.
----------------------------------------
cdefs.ALL_KEYBINDINGS =
{
    { txt = STRINGS.UI.HOTKEYS.GAMEPLAY },
    { name = "pause", txt = STRINGS.UI.HOTKEYS.PAUSE, defaultBinding = mui_util.makeBinding( mui_defs.K_ESCAPE ) },
    { name = "nextTurn", txt = STRINGS.UI.HOTKEYS.NEXT_TURN, defaultBinding = mui_util.makeBinding( mui_defs.K_ENTER ) },
    { name = "mainframeMode", txt = STRINGS.UI.HOTKEYS.MAINFRAME, defaultBinding = mui_util.makeBinding( mui_defs.K_SPACE ) },
    { name = "cycleSelection",  txt = STRINGS.UI.HOTKEYS.CYCLE_SELECT, defaultBinding = mui_util.makeBinding( mui_defs.K_TAB ) },
    { name = "showCharacter", txt = STRINGS.UI.HOTKEYS.CHAR_SHEET, defaultBinding = mui_util.makeBinding( mui_defs.K_C ) },
    { name = "abilityOverwatch", txt = STRINGS.UI.HOTKEYS.USE_OVERWATCH, defaultBinding = mui_util.makeBinding( mui_defs.K_O ) },
    { name = "abilityReaction", txt = STRINGS.UI.HOTKEYS.USE_MELEE, defaultBinding = mui_util.makeBinding( mui_defs.K_M ) },
    { name = "abilityPeek", txt = STRINGS.UI.HOTKEYS.USE_PEEK, defaultBinding = mui_util.makeBinding( mui_defs.K_P ) },
    { name = "abilityOpenDoor", txt = STRINGS.UI.HOTKEYS.USE_OPEN_DOOR, defaultBinding = mui_util.makeBinding( mui_defs.K_F ) },
    { name = "abilitySprint", txt = STRINGS.UI.HOTKEYS.USE_SPRINT, defaultBinding = mui_util.makeBinding( mui_defs.K_R ) },

    { txt = STRINGS.UI.HOTKEYS.CAMERA_CONTROLS },
    { name = "toggleTactical", txt = STRINGS.UI.HOTKEYS.TOGGLE_VIEW, defaultBinding = mui_util.makeBinding( mui_defs.K_ALT ) },
    { name = "wallToggle", txt = STRINGS.UI.HOTKEYS.TOGGLE_WALLS, defaultBinding = mui_util.makeBinding( mui_defs.K_T ) },
    { name = "cameraRotateL", txt = STRINGS.UI.HOTKEYS.CAMERA_ROTATE_LEFT, defaultBinding = mui_util.makeBinding( mui_defs.K_Q ) },
    { name = "cameraRotateR", txt = STRINGS.UI.HOTKEYS.CAMERA_ROTATE_RIGHT, defaultBinding = mui_util.makeBinding( mui_defs.K_E ) },
    { name = "cameraPanU", txt = STRINGS.UI.HOTKEYS.CAMERA_UP, defaultBinding = mui_util.makeBinding( mui_defs.K_W ) },
    { name = "cameraPanD", txt = STRINGS.UI.HOTKEYS.CAMERA_DOWN, defaultBinding = mui_util.makeBinding( mui_defs.K_S ) },
    { name = "cameraPanL", txt = STRINGS.UI.HOTKEYS.CAMERA_LEFT, defaultBinding = mui_util.makeBinding( mui_defs.K_A ) },
    { name = "cameraPanR", txt = STRINGS.UI.HOTKEYS.CAMERA_RIGHT, defaultBinding = mui_util.makeBinding( mui_defs.K_D ) },
}

-----------------------------------------
-- Debug mode constants for state-game.

cdefs.DBG_NONE = 0
cdefs.DBG_TRAITS = 1
cdefs.DBG_DATA = 2
cdefs.DBG_RIGS = 3
cdefs.DBG_BTREE = 4
cdefs.DBG_SITUATION = 5
cdefs.DBG_PROCGEN = 6
cdefs.DBG_SOUND = 7
cdefs.DBG_PATHING = 8
cdefs.DBG_MISSIONS = 9
cdefs.DBG_REPLAY = 10
cdefs.DBG_ISOSORT = 11
cdefs.DBG_MAX = 12

-----------------------------------------------------
-- Achievement names.  Should match server-side IDs.

cdefs.ACHIEVEMENTS =
{
    TRAINING_WHEELS = "TRAINING_WHEELS", -- Beat the game on NORMAL_DIFFICULTY (Beginner)
    ANT_SOCIETY = "ANT_SOCIETY", -- Beat the game on EXPERIENCED_DIFFICULTY (Experienced)
    INVISIBLE_INC = "INVISIBLE_INC", -- Beat the game on HARD_DIFFICULTY (Expert)
    ACCEPTABLE_HOST = "ACCEPTABLE_HOST", -- Beat the game on VERY_HARD_DIFFICULTY (Expert+)
    FULLY_EQUIPPED = "FULLY_EQUIPPED", -- Unlock every agent and mainframe program
    THE_LIMIT = "THE_LIMIT", -- Beat a level after reaching alarm level 6 on normal.
    GHOST_MOVES = "GHOST_MOVES", -- Beat a level without ever being spotted
    NEVER_LOOK_BACK = "NEVER_LOOK_BACK", -- Beat the game with no rewinds on HARD_DIFFICULTY
    MEAT_MACHINE = "MEAT_MACHINE", -- Install 4 augments on an agent.
    REBUILDING_THE_FIRM = "REBUILDING_THE_FIRM", -- Survive 5 days in Endless.
    CORPORATE_LADDER = "CORPORATE_LADDER", -- Survive 10 days in Endless.
    SMOOTH_OPERATOR = "SMOOTH_OPERATOR", -- Survive 5 days in Endless+.
    DAEMON_CODE = "DAEMON_CODE", -- Beat the game with Faust and Brimstone.
    SURVIVE24 = "CONTACT", -- Survive hours
    SURVIVE48 = "NEARING_THRESHOLD", -- Survive hours
    SURVIVE72 = "TARGET_RESOLVED", -- Survive hours
    ATTENTION_TO_DETAIL = "ATTENTION_TO_DETAIL", -- Loot every safe on a level
    TIME_ATTACK = "TIME_ATTACK", -- Defeat time attack
}

-----------------------------------------
-- Sound constants

cdefs.SOUND_HUD_MENU_CANCEL = "SpySociety/HUD/menu/cancel"
cdefs.SOUND_HUD_MENU_CLICK = "SpySociety/HUD/menu/click"
cdefs.SOUND_HUD_MENU_CONFIRM = "SpySociety/HUD/menu/confirm"
cdefs.SOUND_HUD_MENU_POPUP = "SpySociety/HUD/menu/popup"
cdefs.SOUND_HUD_MENU_POPDOWN = "SpySociety/HUD/menu/popdown"
cdefs.SOUND_HUD_GAME_POPUP = "SpySociety/HUD/gameplay/popup"
cdefs.SOUND_HUD_GAME_POPDOWN = "SpySociety/HUD/menu/popdown"
cdefs.SOUND_HUD_GAME_WOOSHOUT = "SpySociety/HUD/menu/whoosh_out"


if config.RECORD_MODE then
	cdefs.SOUND_HUD_GAME_SELECT_UNIT = ""
	cdefs.SOUND_HUD_GAME_CONFIRM = ""
	cdefs.SOUND_HUD_MENU_ROLLOVER = ""
	cdefs.SOUND_HUD_GAME_SELECT_ITEM = ""
else
	cdefs.SOUND_HUD_MENU_ROLLOVER = "SpySociety/HUD/menu/rollover"
	cdefs.SOUND_HUD_GAME_SELECT_UNIT = "SpySociety/HUD/gameplay/select_unit"
	cdefs.SOUND_HUD_GAME_CONFIRM = "SpySociety/HUD/gameplay/confirm_action"
	cdefs.SOUND_HUD_GAME_SELECT_ITEM = "SpySociety/HUD/gameplay/select_item"
end

cdefs.SOUND_HUD_GAME_SELECT_ACTION = "SpySociety/HUD/gameplay/select_action"

cdefs.SOUND_HUD_GAME_NEWTURN = "SpySociety/HUD/gameplay/new_turn"
cdefs.SOUND_HUD_GAME_CANCEL = "SpySociety/HUD/gameplay/cancel_action"
cdefs.SOUND_HUD_GAME_MODE_SWITCH = "SpySociety/HUD/gameplay/mode_switch"
cdefs.SOUND_HUD_GAME_ENDTURN = "SpySociety/HUD/gameplay/end_turn"
cdefs.SOUND_HUD_GAME_DESELECT_UNIT = "SpySociety/HUD/gameplay/deselect_unit"
cdefs.SOUND_HUD_GAME_ACTIVITY_CORP = "SpySociety/HUD/gameplay/activity_corp"
cdefs.SOUND_HUD_GAME_ACTIVITY_AGENT = "SpySociety/HUD/gameplay/activity_agent"
cdefs.SOUND_HUD_GAME_CLICK = "SpySociety/HUD/gameplay/click"

cdefs.SOUND_HUD_MAINFRAME_SELECT_UNIT = "SpySociety/HUD/mainframe/select_unit" --click on consoles
cdefs.SOUND_HUD_MAINFRAME_SELECT_ACTION = "SpySociety/HUD/mainframe/select_action" -- if there was a targeting option for the radial item, this would play when the radial was clicked instead of confirm
cdefs.SOUND_HUD_MAINFRAME_CONFIRM_ACTION = "SpySociety/HUD/mainframe/confirm_action" -- select radial option
cdefs.SOUND_HUD_MAINFRAME_SELECT_ITEM = "SpySociety/HUD/mainframe/select_item" -- right click to bring up radial 
cdefs.SOUND_HUD_MAINFRAME_CANCEL_ACTION = "SpySociety/HUD/mainframe/cancel_action" 
cdefs.SOUND_HUD_MAINFRAME_MODE_SWITCH = "SpySociety/HUD/mainframe/mode_switch" -- goto mainframe mode
cdefs.SOUND_HUD_MAINFRAME_DESELECT_UNIT = "SpySociety/HUD/mainframe/deselect_unit" --deselect a console.
cdefs.SOUND_HUD_MAINFRAME_SELECT_PROGRAM = "SpySociety/HUD/mainframe/select_program" 

cdefs.SOUND_HUD_MAINFRAME_PROGRAM_AUTO_RUN = "SpySociety/Actions/mainframe_run_program" 



cdefs.SOUND_HUD_ADVANCE_TRACKER = "SpySociety/HUD/gameplay/activity_alarm_increase"
cdefs.SOUND_HUD_ADVANCE_TRACKER_NUMBER = "SpySociety/HUD/gameplay/activity_alarm_increase_number"

cdefs.SOUND_HUD_BUY = "SpySociety/HUD/gameplay/purchase"
cdefs.SOUND_HUD_SELL = "SpySociety/HUD/gameplay/sell"
cdefs.SOUND_HUD_INSTALL = "SpySociety/HUD/gameplay/install_augment"

cdefs.SOUND_VO_GENERIC_ENDERS = 
{
	"SpySociety/VoiceOver/Missions/Generic/Ender_goodluck",
	"SpySociety/VoiceOver/Missions/Generic/Ender_yourstokeep",
	"SpySociety/VoiceOver/Missions/Generic/Ender_OPgoodluck"
}

----------------------------------------------------------------
-- constant magic numbers

cdefs.SECONDS = 60 --frames per second

----------------------------------------------------------------
-- Magic layer priorities

cdefs.BOARD_PRIORITY = -100			-- ie. the floors
cdefs.ZONES_PRIORITY = 1000000		-- in front of pretty much everything, but in front of the board (floors)

--this magic 316 number is derived from 2x*x = 448*448 and solving for x
--we get the formula from realizing that our 448:256 tile block in flash must be formed by rotation of a square in world space
--so a rotation of 45 degrees around the z axis will make the hypotenuse of the square a horizontal line, and the since this is
--exactly in the center of the square the subsequent 55.15 degree rotation around the x axis will not cause any scale to be applied
--so we can use the formula x*x + y*y = h*h with h = 448 and x=y to get 2x*x = 448*448
--solving for x gives us 316.78383797157329093157827422297 which is the length of the square along the x and y dimensions in world space
--that when rotated by the camera into ISO space gives us our 448:256 tile
--cdefs.BOARD_TILE_SIZE = math.sqrt(448*448/2) / 4 --316.78383797157329093157827422297 / 4
cdefs.BOARD_TILE_SIZE = math.sqrt(168*168/2) / 4 --316.78383797157329093157827422297 / 4

---------------------
-- UI/game viz defs

cdefs.CURSOR_DEFAULT = 0
cdefs.CURSOR_TARGET = 1
cdefs.CURSOR_CANT_MOVE = 2

--List of possible render filters that can be applied to kanim rendering
cdefs.RENDER_FILTERS =
{
	default =			{ shader=KLEIAnim.SHADER_NORMAL },
	green =				{ shader=KLEIAnim.SHADER_FOW,			r=255/255,	g=255/255,	b=255/255,	a=1.0,	lum=1.0-0.46 },
	fog_of_war =		{ shader=KLEIAnim.SHADER_FOW,			r=60/255,	g=95/255,	b=100/255,	a=1.0,	lum=1.0-0.62 },
	shadowlight =		{ shader=KLEIAnim.SHADER_SHADOWLIGHT,	r=60/255,	g=95/255,	b=100/255,	a=1.0,	lum=1.0-0.62 },

	zone_1_dynamic =	{ shader=KLEIAnim.SHADER_SHADOWLIGHT,	r=60/255,	g=95/255,	b=100/255,	a=1.0,	lum=1.0-0.14 }, -- office/lab
	zone_1_fog =		{ shader=KLEIAnim.SHADER_FOW,			r=60/255,	g=95/255,	b=100/255,	a=1.0,	lum=1.0-0.14 },
	zone_1 =			{ shader=KLEIAnim.SHADER_OVERLAY,		r=54/255,	g= 95/255,	b= 191/255,	a=1.0,	lum=0.25 },

	zone_2_dynamic =	{ shader=KLEIAnim.SHADER_SHADOWLIGHT,	r=60/255,	g=95/255,	b=100/255,	a=1.0,	lum=1.0-0.41 }, -- hall
	zone_2_fog =		{ shader=KLEIAnim.SHADER_FOW,			r=60/255,	g=95/255,	b=100/255,	a=1.0,	lum=1.0-0.41 },
	zone_2 =			{ shader=KLEIAnim.SHADER_OVERLAY,		r=222/255,	g= 107/255,	b= 43/255,	a=1.0,	lum=0.25 },

	zone_3_dynamic =	{ shader=KLEIAnim.SHADER_SHADOWLIGHT,	r=60/255,	g=95/255,	b=100/255,	a=1.0,	lum=1.0-0.36 }, -- security
	zone_3_fog =		{ shader=KLEIAnim.SHADER_FOW,			r=60/255,	g=95/255,	b=100/255,	a=1.0,	lum=1.0-0.36 },
	zone_3 =			{ shader=KLEIAnim.SHADER_NORMAL },

	ghost =				{ shader=KLEIAnim.SHADER_FOW,			r=    0.8,	g=    0.0,	b=    0.0,	a=0.5,	lum=1.0-0.62 },
	mainframe =			{ shader=KLEIAnim.SHADER_FOW,			r=    0.9,	g=    0.9,	b=    0.9,	a=0.1,	lum=1.0-0.62 },
	cloak = 			{ shader=KLEIAnim.SHADER_FOW,			r=	  0.9,  g=    0.8,  b=      1,  a=0.3,  lum=1.0-0.0 },
	desat =				{ shader=KLEIAnim.SHADER_DESAT },

	mainframe_npc =		{ shader=KLEIAnim.SHADER_FOW,			r=255/255,	g= 0/255,	b= 0/255,	a=1.0,	lum=1.0-0.41 },
	mainframe_pc =		{ shader=KLEIAnim.SHADER_FOW,			r=0/255,	g= 255/255,	b= 255/255,	a=1.0,	lum=1.0-0.41 },
	mainframe_fused =	{ shader=KLEIAnim.SHADER_FOW,			r=100/255,	g= 100/255,	b= 100/255,	a=1.0,	lum=1.0-0.41 },
	mainframe_agent =	{ shader=KLEIAnim.SHADER_FOW,			r=255/255,	g= 255/255,	b= 0/255,	a=0.2,	lum=1.0-0.41 },

	focus_highlite =	{ shader=KLEIAnim.SHADER_HILITE,		r=255/255,	g= 0/255,	b= 0/255,	a=0.5, lum = 1.0 },
	focus_target =	    { shader=KLEIAnim.SHADER_HILITE,		r=65/255,	g= 255/255,	b= 65/255,	a=0.8, lum = 1.0 },
}

cdefs.MOVECLR_SNEAK = util.color( 142/255, 247/255, 247/255, 1 )
cdefs.MOVECLR_DEFAULT = util.color( 247/255, 247/255, 142/255, 1 )
cdefs.MOVECLR_INVIS = util.color( 1,1,1, 1 )

--------------------------------------------------------------------------------
-- Wall texture data

cdefs.WALLTILES_FILE = "data/images/walls.png"

local function UVCustomTex( left, bottom, right, top )
	local TOTALW, TOTALH = 2048, 2048 -- Total texture size of cdefs.WALLTILES_FILE
	return { (left+0.5) / TOTALW, (bottom+0.5) / TOTALH, (right+0.5) / TOTALW, (top+0.5) / TOTALH }
end

local function UVTex( rowx, rowy )
	local CELLW, CELLH = 256, 256 -- Tile size in cdefs.WALLTILES_FILE
	local left, top = rowx * CELLW, rowy * CELLH
	local right, bottom = (rowx + 1) * CELLW - 1, (rowy + 1) * CELLH - 1
	return UVCustomTex( left, bottom, right, top )
end

local function UVPostTex( rowx, rowy )
	local CELLW, CELLH = 256, 256 -- Tile size in cdefs.WALLTILES_FILE
	local left, top = rowx * CELLW, (rowy + 1) * CELLH - 9
	local right, bottom = (rowx + 1) * CELLW - 1, (rowy + 1) * CELLH - 1
	return UVCustomTex( left, bottom, right, top )
end

cdefs.WALL_MAINFRAME = UVCustomTex( 2032, 2047, 2047, 2032 )
cdefs.WALL_EXTERNAL = UVTex( 0, 4 )
cdefs.WALL_DOOR_LOCKED = UVTex( 0, 0 )
cdefs.WALL_DOOR_UNLOCKED = UVTex( 1, 0 )
cdefs.WALL_DOOR_BROKEN = UVTex( 0, 1 )

cdefs.WALL_SECURITY_LOCKED = UVTex( 3, 0 )
cdefs.WALL_SECURITY_LOCKED_ALT = UVTex( 2, 0 )
cdefs.WALL_SECURITY_UNLOCKED = UVTex( 3, 0 )
cdefs.WALL_SECURITY_UNLOCKED_ALT = UVTex( 2, 0 )

cdefs.WALL_ELEVATOR_LOCKED = UVTex( 4, 0 )
cdefs.WALL_ELEVATOR_LOCKED_ALT = UVTex( 5, 0 )
cdefs.WALL_ELEVATOR_UNLOCKED = UVTex( 4, 0 )
cdefs.WALL_ELEVATOR_UNLOCKED_ALT = UVTex( 5, 0 )

cdefs.WALL_DOOR_FINAL = UVTex( 1, 1 )
cdefs.WALL_DOOR_FINAL_ALT = UVTex( 2, 1 )
cdefs.WALL_DOOR_FINAL_ALT2 = UVTex( 3, 1 )

cdefs.POST_DEFAULT = UVPostTex( 0, 4 )
cdefs.HALF_WALL = UVPostTex( 0, 4 )

--------------------------------------------------------------------------------
-- Tile texture data

cdefs.LEVELTILES_PARAMS =
{
	file = "data/images/leveltiles.png",
	21,			--width in tiles
	21,			--height in tiles
	48/1008,		--cellWidth
	48/1008,		--cellHeight
	0.5/1008,	--xOffset
	0.5/1008,	--yOffset
	47/1008,		--tileWidth
	47/1008,		--tileHeight
}


-- Valid zonings for level generation.  Each room should receive be zoned according to one of these entries.
-- The pattern-string is used to match suitable prefabs into that zone.  The name is used by tiles in prefabs
-- if they need to match into a specific MAPTILE (also for debugging)


-- NEUTRAL ZONES
cdefs.ZONE_SECURITY = { name = "security", pattern = "security", wallUV = UVTex( 4, 6 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_SERVER = { name = "server", pattern = "server", wallUV = UVTex( 6, 6 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_GUARD_ROOM_1 = { name = "guard_room_1", pattern = "guard", wallUV = UVTex( 0, 7 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_GUARD_ROOM_2 = { name = "guard_room_2", pattern = "guard", wallUV = UVTex( 7, 6 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_VAULT = { name = "vault", pattern = "vault", wallUV = UVTex( 1, 7 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_TERMINALS_1 = { name = "terminals1", pattern = "terminals1", wallUV = UVTex( 2, 7 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_TERMINALS_2 = { name = "terminals2", pattern = "terminals2", wallUV = UVTex( 3, 7 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_DETENTION = { name = "detention", pattern = "detention", wallUV = UVTex( 4, 7 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_NANOFAB = { name = "nanofab", pattern = "nanofab", wallUV = UVTex( 5, 7 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_CEO_OFFICE = { name = "ceo_office", pattern = "ceo_office", wallUV = UVTex( 0, 3 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_AUGMENT_LAB = { name = "augment_lab", pattern = "augment_lab", wallUV = UVTex( 1, 3 ), postUV = UVPostTex( 0, 4 ) }



-- FTM TV STUDIO
cdefs.ZONE_FTM_TV_OFFICE = { name = "ftm_TV_office", pattern = "office", wallUV = UVTex( 0, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_FTM_TV_STUDIO = { name = "ftm_TV_studio", pattern = "office", wallUV = UVTex( 1, 6 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_FTM_TV_HALL = { name = "ftm_TV_hall", pattern = "hall", wallUV = UVTex( 0, 6 ), postUV = UVPostTex( 0, 4 ) }

-- FTM SECURITY HUB
cdefs.ZONE_FTM_SECURITY_OFFICE = { name = "ftm_security_office", pattern = "office", wallUV = UVTex( 0, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_FTM_SECURITY_SECURITY = { name = "ftm_security_security", pattern = "security", wallUV = UVTex( 4, 6 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_FTM_SECURITY_HALL = { name = "ftm_security_hall", pattern = "hall", wallUV = UVTex( 0, 6 ), postUV = UVPostTex( 0, 4 ) }


cdefs.ZONE_TRIAL_ZONE_1 = { name = "tiral_zone_1", pattern = "office", wallUV = UVTex( 0, 6 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_TRIAL_ZONE_2 = { name = "tiral_zone_2", pattern = "hall", wallUV = UVTex( 0, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_TRIAL_ZONE_3 = { name = "tiral_zone_3", pattern = "security", wallUV = UVTex( 4, 6 ), postUV = UVPostTex( 0, 4 ) }


--OLD BORING ZONES
cdefs.ZONE_FTM_OFFICE = { name = "ftm_office", pattern = "office", wallUV = UVTex( 0, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_FTM_LAB = { name = "ftm_lab", pattern = "lab", wallUV = UVTex( 1, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_FTM_HALL = { name = "ftm_hall", pattern = "hall", wallUV = UVTex( 0, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_FTM_SECURITY = { name = "ftm_security", pattern = "security", wallUV = UVTex( 4, 6 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_SK_OFFICE = { name = "sk_office", pattern = "office", wallUV = UVTex( 0, 5 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_SK_LAB = { name = "sk_lab", pattern = "lab", wallUV = UVTex( 7, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_SK_BAY = { name = "sk_security", pattern = "bay", wallUV = UVTex( 2, 5 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_OM_OFFICE = { name = "sk_office", pattern = "office", wallUV = UVTex( 0, 5 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_OM_LAB = { name = "sk_lab", pattern = "lab", wallUV = UVTex( 7, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_OM_BAY = { name = "sk_security", pattern = "bay", wallUV = UVTex( 2, 5 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_TECH_OFFICE = { name = "tech_office", pattern = "office", wallUV = UVTex( 4, 5 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_TECH_HALL = { name = "tech_hall", pattern = "hall", wallUV = UVTex( 5, 5 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_TECH_LAB = { name = "tech_lab", pattern = "lab", wallUV = UVTex( 7, 5 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_TECH_PSI = { name = "tech_psi", pattern = "psi", wallUV = UVTex( 6, 5 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_KO_BARRACKS = { name = "ko_barracks", pattern = "barracks", wallUV = UVTex( 4, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_KO_HALL = { name = "ko_hall", pattern = "hall", wallUV = UVTex( 3, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_KO_FACTORY = { name = "ko_factory", pattern = "factory", wallUV = UVTex( 5, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_KO_OFFICE = { name = "ko_office", pattern = "office", wallUV = UVTex( 6, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_KO_SECURITY = { name = "ko_security", pattern = "security", wallUV = UVTex( 2, 4 ), postUV = UVPostTex( 0, 4 ) }



cdefs.ZONE_OM_MISSION = { name = "om_mission", pattern = "mission", wallUV = UVTex( 4, 3 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_OM_HOLO = { name = "om_holo", pattern = "holo", wallUV = UVTex( 2, 4 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_OM_HALL = { name = "om_hall", pattern = "hall", wallUV = UVTex( 3, 5 ), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_OM_FINAL = { name = "om_final", pattern = "final", wallUV = UVTex( 6, 3), postUV = UVPostTex( 0, 4 ) }
cdefs.ZONE_OM_PRE_FINAL = { name = "om_pre_final", pattern = "pre_final", wallUV = UVTex( 7, 2), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_OM_ENGINE = { name = "om_engine", pattern = "engine", wallUV = UVTex( 3, 4 ), postUV = UVPostTex( 0, 4 ) }

cdefs.ZONE_OM_MISSION2 = { name = "om_mission2", pattern = "mission2", wallUV = UVTex( 4, 3 ), postUV = UVPostTex( 0, 4 ) }


cdefs.ZONE_OM_HUB = { name = "om_hub", pattern = "hub", wallUV = UVTex( 7, 3), postUV = UVPostTex( 0, 4 ) }



-- These are indices into the grid texture referred to by cdefs.LEVELTILES_FILE.
-- NOTE: Indices start at 1, and progress incrementally row-wise.
cdefs.BLACKOUT_CELL = 441 - 3 -- Tile index for blacked out (never seen)
cdefs.UNKNOWN_CELL = 441 - 4 -- Tile content exists, but is unknown
cdefs.MAINFRAME_CELL = 420 - 3 -- Tile index for 'mainframe cell'
cdefs.MAINFRAME_UNKNOWN_CELL = 420 - 4
cdefs.WATCHED_CELL = 441 - 5 -- Tactical view: cell is watched
cdefs.COVER_CELL = 441 - 6 -- Tactical view: cell is watched/noticed but in cover
cdefs.NOTICED_CELL = 441 - 7 -- Tactical view: cell is noticed
cdefs.SAFE_CELL = 441 - 8 -- Tactical view: cell is safe

cdefs.MAPTILES =
{
	{ -- UNKNOWN TILE (should be blatantly visible so it can be fixed)
		zone = { wallUV = UVTex( 0, 4 ), postUV = UVPostTex( 0, 4 ) },
		tileStart = 441 - 2, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{	-- SOLID TILE
		zone = { name = "solid", wallUV = UVTex( 0, 4 ), postUV = UVPostTex( 0, 4 ) }, variant = 0,
		tileStart = 441, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = { name = "elevator", wallUV = UVTex( 5, 6 ), postUV = UVPostTex( 0, 4 ) },
		variant = { [0] = 2, [2] = 0, [4] = 1, [6] = 3 }, -- map of direction to variant index
		tileStart = 21+21+21+21+21 + 5, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = { name = "elevator", wallUV = UVTex( 5, 6 ), postUV = UVPostTex( 0, 4 ) },
		variant = { [0] = 0, [2] = 1, [4] = 3, [6] = 2 }, -- map of direction to variant index
		tileStart = 21+21+21+21+21 + 6, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = { name = "elevator", wallUV = UVTex( 5, 6 ), postUV = UVPostTex( 0, 4 ) },
		variant = { [0] = 3, [2] = 2, [4] = 0, [6] = 1 }, -- map of direction to variant index
		tileStart = 21+21+21+21+21 + 7, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = { name = "elevator", wallUV = UVTex( 5, 6 ), postUV = UVPostTex( 0, 4 ) },
		variant = { [0] = 1, [2] = 3, [4] = 2, [6] = 0 }, -- map of direction to variant index
		tileStart = 21+21+21+21+21 + 8, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},


	{
		zone = { name = "elevator_guard", wallUV = UVTex( 6, 7 ), postUV = UVPostTex( 0, 4 ) },
		variant = { [0] = 2, [2] = 0, [4] = 1, [6] = 3 }, -- map of direction to variant index
		tileStart = 21+21+21+21+21+21 + 14, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = { name = "elevator_guard", wallUV = UVTex( 6, 7 ), postUV = UVPostTex( 0, 4 ) },
		variant = { [0] = 0, [2] = 1, [4] = 3, [6] = 2 }, -- map of direction to variant index
		tileStart = 21+21+21+21+21+21 + 15, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = { name = "elevator_guard", wallUV = UVTex( 6, 7 ), postUV = UVPostTex( 0, 4 ) },
		variant = { [0] = 3, [2] = 2, [4] = 0, [6] = 1 }, -- map of direction to variant index
		tileStart = 21+21+21+21+21+21 + 16, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = { name = "elevator_guard", wallUV = UVTex( 6, 7 ), postUV = UVPostTex( 0, 4 ) },
		variant = { [0] = 1, [2] = 3, [4] = 2, [6] = 0 }, -- map of direction to variant index
		tileStart = 21+21+21+21+21+21 + 17, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},



	--	OMNI

	{
		zone = cdefs.ZONE_OM_MISSION2, variant = 0,
		tileStart = 21+21+21+21+21+21+21+11, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	


	{
		zone = cdefs.ZONE_OM_MISSION, variant = 0,
		tileStart = 21+21+21+21+21+21+21+11, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	

	{
		zone = cdefs.ZONE_OM_HOLO, variant = 0,
		tileStart = 21+21+21+21+21+21+21+8, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	

	{
		zone = cdefs.ZONE_OM_ENGINE, variant = 0,
		tileStart = 21+21+21+21+21+21+21+14, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	

	{
		zone = cdefs.ZONE_OM_HALL, variant = 0,
		tileStart = 21+21+21+21+21+21+21+17, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	

	{
		zone = cdefs.ZONE_OM_FINAL, variant = 0,
		tileStart = 21+21+21+21+21+21+21+21+1, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_OM_FINAL, variant = 1,
		tileStart = 21+21+21+21+21+21+21+21+2, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_OM_FINAL, variant = 2,
		tileStart = 21+21+21+21+21+21+21+21+3, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},			

	{
		zone = cdefs.ZONE_OM_PRE_FINAL, variant = 0,
		tileStart = 21+21+21+21+21+21+21+21+5, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},			



	{
		zone = cdefs.ZONE_OM_HUB, variant = 2,
		tileStart = 21+21+21+21+21+21+21+21+4, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},			


	-- NEUTRAL
	{
		zone = cdefs.ZONE_SECURITY, variant = 0,
		tileStart = 21+21+21+21+21+1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_SECURITY, variant = 1,
		tileStart = 21+21+21+21+21+4, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	


	{
		zone = cdefs.ZONE_SERVER, variant = 0,
		tileStart = 21+21+21+21+21+9, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_SERVER, variant = 1,
		tileStart = 21+21+21+21+21+10, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_SERVER, variant = 2,
		tileStart = 21+21+21+21+21+11, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		
	{
		zone = cdefs.ZONE_SERVER, variant = 3,
		tileStart = 21+21+21+21+21+12, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		

	{
		zone = cdefs.ZONE_GUARD_ROOM_1, variant = 0,
		tileStart = 21+21+21+21+21+13, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	--[[
	{
		zone = cdefs.ZONE_GUARD_ROOM_1, variant = 1,
		tileStart = 21+21+21+21+21+21+21+20, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	]]
	{
		zone = cdefs.ZONE_GUARD_ROOM_2, variant = 0,
		tileStart = 21+21+21+21+21+16, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		



	{
		zone = cdefs.ZONE_VAULT, variant = 0,
		tileStart = 21+21+21+21+21+17, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_VAULT, variant = 1,
		tileStart = 21+21+21+21+21+18, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_VAULT, variant = 2,
		tileStart = 21+21+21+21+21+19, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_VAULT, variant = 3,
		tileStart = 21+21+21+21+21+20, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	

	{
		zone = cdefs.ZONE_TERMINALS_1, variant = 0,
		tileStart = 21+21+21+21+21+21+1,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_1, variant = 1,
		tileStart = 21+21+21+21+21+21+2,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_1, variant = 2,
		tileStart = 21+21+21+21+21+21+3,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_1, variant = 3,
		tileStart = 21+21+21+21+21+21+4,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_1, variant = 4,
		tileStart = 21+21+21+21+21+21+5,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_1, variant = 5,
		tileStart = 21+21+21+21+21+21+6,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		

	{
		zone = cdefs.ZONE_TERMINALS_2, variant = 0,
		tileStart = 21+21+21+21+21+21+1,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_2, variant = 1,
		tileStart = 21+21+21+21+21+21+2,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_2, variant = 2,
		tileStart = 21+21+21+21+21+21+3,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_2, variant = 3,
		tileStart = 21+21+21+21+21+21+4,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_2, variant = 4,
		tileStart = 21+21+21+21+21+21+5,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TERMINALS_2, variant = 5,
		tileStart = 21+21+21+21+21+21+6,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},			


	{
		zone = cdefs.ZONE_DETENTION, variant = 0,
		tileStart = 21+21+21+21+21+21+7,patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_DETENTION, variant = 1,
		tileStart = 21+21+21+21+21+21+10,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
		
	{
		zone = cdefs.ZONE_NANOFAB, variant = 0,
		tileStart = 21+21+21+21+21+21+11,patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
		

		
	{
		zone = cdefs.ZONE_CEO_OFFICE, variant = 0,
		tileStart = 21+21+21+21+21+21 + 18 ,patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
		

	{
		zone = cdefs.ZONE_AUGMENT_LAB, variant = 0,
		tileStart =  21+21+21+21+21+21+21+1,patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_AUGMENT_LAB, variant = 1,
		tileStart = 21+21+21+21+21+21+21+4,patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_AUGMENT_LAB, variant = 2,
		tileStart = 21+21+21+21+21+21+21+7,patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
		



	-- ftm-corp tiles

	-- TV STUIO
	{
		zone = cdefs.ZONE_FTM_TV_OFFICE, variant = 0,
		tileStart = 1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_FTM_TV_OFFICE, variant = 1,
		tileStart = 21+2, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	

	{
		zone = cdefs.ZONE_FTM_TV_STUDIO, variant = 0,
		tileStart = 21+21+21+21+7, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_FTM_TV_STUDIO, variant = 1,
		tileStart = 21+21+21+21+10, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	

	{
		zone = cdefs.ZONE_FTM_TV_HALL, variant = 0,
		tileStart = 21+21+21+21+1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_FTM_TV_HALL, variant = 1,
		tileStart = 21+21+21+21+4, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		

	-- SECURITY HUB
	{
		zone = cdefs.ZONE_FTM_SECURITY_OFFICE, variant = 0,
		tileStart = 1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_FTM_SECURITY_OFFICE, variant = 1,
		tileStart = 21+2, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	

	{
		zone = cdefs.ZONE_FTM_SECURITY_SECURITY, variant = 0,
		tileStart = 21+21+21+21+21+1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_FTM_SECURITY_SECURITY, variant = 1,
		tileStart = 21+21+21+21+21+4, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	

	{
		zone = cdefs.ZONE_FTM_SECURITY_HALL, variant = 0,
		tileStart = 21+21+21+21+1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_FTM_SECURITY_HALL, variant = 1,
		tileStart = 21+21+21+21+4, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		




--- TRIAL ZONES

	{
		zone = cdefs.ZONE_TRIAL_ZONE_1, variant = 0,
		tileStart = 1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TRIAL_ZONE_2, variant = 0,
		tileStart = 13, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TRIAL_ZONE_3, variant = 0,
		tileStart = 21+21+21+21+1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	




-- OLD ZONES

	{
		zone = cdefs.ZONE_FTM_OFFICE, variant = 0,
		tileStart = 1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_FTM_OFFICE, variant = 1,
		tileStart = 21+2, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		
	{
		zone = cdefs.ZONE_FTM_LAB, variant = 0,
		tileStart = 10, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_FTM_LAB, variant = 1,
		tileStart = 21 + 2, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_FTM_HALL, variant = 0,
		tileStart = 7, patternLen = 2, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_FTM_HALL, variant = 1,
		tileStart = 9, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		
	{
		zone = cdefs.ZONE_FTM_SECURITY, variant = 0,
		tileStart = 21+21+21+21+21+1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_FTM_SECURITY, variant = 1,
		tileStart = 21+21+21+21+21+4, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},



	-- K&O tiles --
	{
		zone = cdefs.ZONE_KO_FACTORY, variant = 0,
		tileStart = 21 + 21 + 10, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
--		noiseRadius = 3,
	},
	{
		zone = cdefs.ZONE_KO_FACTORY, variant = 1,
		tileStart = 21 + 21 + 11, patternLen = 1,
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
--		noiseRadius = 3,
	},
	{
		zone = cdefs.ZONE_KO_HALL, variant = 0,
		tileStart = 21 + 21 + 7, patternLen = 2,
		render_filter = { fow = "zone_2_fog", normal = "zone_2", dynamic = "zone_2_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_KO_HALL, variant = 1,
		tileStart = 21 + 21 + 9, patternLen = 1,
		render_filter = { fow = "zone_2_fog", normal = "zone_2", dynamic = "zone_2_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_KO_BARRACKS, variant = 0,
		tileStart = 21 + 21 + 4, patternLen = 2, 
		render_filter = { fow = "zone_3_fog", normal = "zone_3", dynamic = "zone_3_dynamic" },
		ambientSound = 1, 
	},
	{
		zone = cdefs.ZONE_KO_BARRACKS, variant = 1,
		tileStart = 21 + 21 + 6, patternLen = 1, 
		render_filter = { fow = "zone_3_fog", normal = "zone_3", dynamic = "zone_3_dynamic" },
		ambientSound = 1, 
	},
	{
		zone = cdefs.ZONE_KO_OFFICE, variant = 0,
		tileStart = 21 + 21 + 21 + 10, patternLen = 2, 
		render_filter = { fow = "zone_3_fog", normal = "zone_3", dynamic = "zone_3_dynamic" },
		ambientSound = 1, 
	},
	{
		zone = cdefs.ZONE_KO_OFFICE, variant = 1,
		tileStart = 21 + 21 + 21 + 12, patternLen = 1, 
		render_filter = { fow = "zone_3_fog", normal = "zone_3", dynamic = "zone_3_dynamic" },
		ambientSound = 1, 
	},	
	{
		zone = cdefs.ZONE_KO_SECURITY, variant = 0,
		tileStart = 4, patternLen = 3, 
		render_filter = { fow = "zone_3_fog", normal = "zone_3", dynamic = "zone_3_dynamic" },
		ambientSound = 1, 
	},	
	{
		zone = cdefs.ZONE_KO_SECURITY, variant = 1,
		tileStart = 21 + 7, patternLen = 3, 
		render_filter = { fow = "zone_3_fog", normal = "zone_3", dynamic = "zone_3_dynamic" },
		ambientSound = 1, 
	},	

	-- Sankaku tiles
	{
		zone = cdefs.ZONE_SK_OFFICE, variant = 0,
		tileStart = 21 + 10, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_SK_OFFICE, variant = 1,
		tileStart = 21 + 21 + 1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_SK_LAB, variant = 0,
		tileStart =13, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_SK_LAB, variant = 1,
		tileStart = 16, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_SK_BAY, variant = 0,
		tileStart =21+13, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_SK_BAY, variant = 1,
		tileStart = 21+16, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		

	-- Omni tiles
	{
		zone = cdefs.ZONE_OM_OFFICE, variant = 0,
		tileStart = 21 + 10, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_OM_OFFICE, variant = 1,
		tileStart = 21 + 21 + 1, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_OM_LAB, variant = 0,
		tileStart =13, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_OM_LAB, variant = 1,
		tileStart = 16, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_OM_BAY, variant = 0,
		tileStart =21+13, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_OM_BAY, variant = 1,
		tileStart = 21+16, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		





	-- Plastech
	{
		zone = cdefs.ZONE_TECH_OFFICE, variant = 0,
		tileStart = 21+21+21+2, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TECH_OFFICE, variant = 1,
		tileStart = 21+21+21+5, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		
	{
		zone = cdefs.ZONE_TECH_LAB, variant = 0,
		tileStart = 21+21+21+13, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_TECH_LAB, variant = 1,
		tileStart = 21+21+21+9, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
	{
		zone = cdefs.ZONE_TECH_HALL, variant = 0,
		tileStart = 21+21+21+16, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TECH_HALL, variant = 1,
		tileStart = 21+21+21+1, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},		
	{
		zone = cdefs.ZONE_TECH_PSI, variant = 0,
		tileStart = 21+21+13, patternLen = 3, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},	
	{
		zone = cdefs.ZONE_TECH_PSI, variant = 1,
		tileStart = 21+21+16, patternLen = 1, 
		render_filter = { fow = "zone_1_fog", normal = "zone_1", dynamic = "zone_1_dynamic" },
		ambientSound = 1,
	},
}

cdefs.TILE_UNKNOWN = 1 -- Index into MAPTILES for the unknown tile
cdefs.TILE_SOLID = 2 -- Index into MAPTILES for the solid tile
cdefs.TILE_OFFICE = 20 -- Index into MAPTILES for a reasonable default tile.

----------------------------------------------------------------
-- Available team colours in RGB.  DO NOT EDIT -- referenced in save data.

cdefs.TEAMCLR_NEUTRAL =
{
	name = "Neutral",
	primary = { r = 250/255, g = 250/255, b = 250/255, a = 1, str = util.stringizeRGBA( 250, 250, 250, 255 ) },
}

cdefs.TEAMCLR_SELF =
{
	name = "Self",
	primary = { r = 254/255, g = 189/255, b = 9/255, a = 1, str = util.stringizeRGBA( 254, 189, 9, 255 ) },
}

cdefs.TEAMCLR_ENEMY =
{
	name = "Enemy",
	primary = { r = 244/255, g = 24/255, b = 24/255, a = 1, str = util.stringizeRGBA( 244, 24, 24, 255 ) },
}

cdefs.TRACKER_COLOURS =
{
	util.color.fromBytes( 250, 253, 105 ),
	util.color.fromBytes( 250, 253, 105 ),
	util.color.fromBytes( 251, 203, 98 ),
	util.color.fromBytes( 225, 152, 45 ),
	util.color.fromBytes( 246, 90, 21 ),
	util.color.fromBytes( 205, 24, 10 ),
	util.color.fromBytes( 205, 24, 10 ),
}


cdefs.COLOR_ATTACK = util.color( 255/255, 132/255, 17/255 )  
cdefs.COLOR_ATTACK_HOVER = util.color( 1, 1, 1 )   

cdefs.COLOR_ACTION = util.color( 140/255, 255/255, 255/255 )
cdefs.COLOR_ACTION_HOVER = util.color( 1, 1, 1 )   

cdefs.COLOR_PROGRAM = util.color( 220/255, 220/255, 255/255 )
cdefs.COLOR_PROGRAM_HOVER = util.color( 255/255, 255/255, 255/255 )

cdefs.COLOR_REQ = util.color( 220/255, 60/255, 0/255 )
cdefs.COLOR_REQ_HOVER = util.color( 255/255, 130/255, 0/255 )

cdefs.COLOR_FREE = util.color( 244/255, 255/255, 120/255 )
cdefs.COLOR_FREE_HOVER = util.color( 1, 1, 1 )

cdefs.COLOR_EQUIPPED = util.color( 17/255, 255/255, 17/255 )
cdefs.COLOR_EQUIPPED_HOVER = util.color( 1, 1, 1 )

cdefs.COLOR_WATCHED = util.color( 184/255, 13/255, 13/255 )
cdefs.COLOR_WATCHED_BOLD = util.color( 255/255, 1/255, 1/255 )
cdefs.COLOR_NOTICED = util.color( 220/255, 220/255, 50/255 )
cdefs.COLOR_NOTICED_BOLD = util.color( 178/255, 178/255, 0 )

cdefs.COLOR_PLAYER_WARNING = { r=140/255,g=255/255 ,b=255/255,a=255/255 }
cdefs.COLOR_CORP_WARNING = { r=184/255,g=13/255,b=13/255,a=190/255 }

cdefs.AP_COLOR_NORMAL = util.color( 140/255,1,1,1 )
cdefs.AP_COLOR_PREVIEW = util.color( 0.8, 0.8, 0.1, 1 )
cdefs.AP_COLOR_PREVIEW_BONUS = util.color( 0.1, 1, 0.1, 1 )

cdefs.COLOR_HUD_YELLOW_1 = { r=240/255,g=255/255,b=120/255,a=255/255 }

cdefs.COLOR_DRAG_DROP = util.color( 10/255, 10/255, 10/255, 0.666 ) -- Color of the drag destination area
cdefs.COLOR_DRAG_VALID = util.color.WHITE -- Color of the drag icon when hovered over a valid drag drop target
cdefs.COLOR_DRAG_INVALID = util.color.GRAY -- Color of the drag icon when drag-drop is not valid

cdefs.COLOR_ENCUMBERED = util.color(180/255,50/255,50/255,0.2)

cdefs.HILITE_TARGET_COLOR = { 0.1, 120/255, 0.1, 20/255 } -- Cell hilite colour


cdefs.AUGMENT_TXT_COLOR = {r=255/255,g=255/255,b=51/255,a=1 }


cdefs.CREDITS_ICON = "gui/icons/item_icons/icon-item_credit_chip.png"
cdefs.PWR_ICON = "gui/icons/item_icons/icon-item_PWR_chip.png"

cdefs.SHORT_WALL_SCALE = .25

cdefs.INTEREST_TOOLTIPS = {
	investigating = {line= STRINGS.UI.INTEREST_INVESTIGATING, icon="gui/hud3/interest_icon.png"},	
	hunting = {line= STRINGS.UI.INTEREST_HUNTING, icon="gui/hud3/interest_icon_hunt.png"},
}

util.strictify( cdefs )

-------------------------------------------------------------
return cdefs



