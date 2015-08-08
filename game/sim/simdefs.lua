
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local SOUND_RANGE_0 = 0
local SOUND_RANGE_1 = 4
local SOUND_RANGE_2 = 8
local SOUND_RANGE_3 = 12
local SOUND_RANGE_MAX = 100

local util = include( "modules/util" )
local cdefs = include( "client_defs" )

----------------------------------------------------------------
-- These are the 'default' difficulty options, AKA 'Hard' mode.
-- Assign default settings here, override them below for other difficulties
-- in simdefs.DIFFICULTY_OPTIONS.

local DEFAULT_DIFFICULTY_OPTIONS =
{
	--no restarting of levels
	savescumming = false,
	-- timeAttack mode on?
	timeAttack = 0,
    -- Are corp names hidden on the map screen?
    hideMapDestinations = false,
    -- Are interest points drawn without observing guards?
    drawInterestPoints = false,
    -- Are danger zones for enemy LOS rendered?
    dangerZones = true,
    -- Are you allowed to melee from the front?
    meleeFromFront = true,
    -- Is the alarm auto-incremented each PC turn?
    autoAlarm = true,
    -- Alarm multiplier, each tracker increases is multiplied by this factor.
    alarmMultiplier = 1,
    -- How many "rooms" are spawned during level-gen; roughly determines level size.
    roomCount = 10,
    -- Agency starting credits.
    startingCredits = 500,
    -- Agency starting power.
    startingPower = 10,
    -- Determines how patrols are generated
    beginnerPatrols = false,
    -- How many total CPUs are dispersed to consoles per level.
    powerPerLevel = 10,
    -- How many total consoles exist per level.
    consolesPerLevel = 5,
    -- How many total safes exist per level.
    safesPerLevel = 5,
    --- Daemon profusion in the level
    daemonQuantity = "NORMAL",
    -- Multiplier to credits gained.
    creditMultiplier = 0.75,
    -- Multiplier to the number of firewalls assigned to mainframe items.
    firewallMultiplier = 2.0,
    -- Rewinds available per level
    rewindsLeft = 1,
    -- Additive multiplier to KO duration for guards
    koDuration = 0,
	-- Determines the alarm types
	alarmTypes = "NORMAL",
    -- Hours in teh campaign ( math.huge implies endless mode )
    maxHours = config.CAMPAIGN_HOURS,
    -- Does the alarm raise 1 when units are KOed?
    alarmRaisedOnKO = false,
    -- Determines the guard spawn table
    spawnTable = "NORMAL",   
    -- Does the final level have the countermeasures daemon? 
    countermeasuresFinal = true, 
}

local _M =
{
	-- Logging flags
	LOG_SPAM = "LOG_SPAM",
	LOG_PATH = "LOG_PATH", -- AI pathfinding
	LOG_AI = "LOG_AI", -- AI behaviour
	LOG_SIT = "LOG_SIT",	--situations
	LOG_TUTORIAL = "LOG_TUTORIAL", -- Tutorial
	LOG_PROCGEN = "LOG_PROCGEN", -- Level procgen spew
	LOG_SENSE = "LOG_SENSE", -- AI senses spew

	AGENT_LIMIT = 4,

	DEFAULT_EXITID = 1,
	EXITID_VENT = 3, 

	MAX_AUGMENT_CAPACITY = 6, -- Absolute max capacity.
    DEFAULT_AUGMENT_CAPACITY = 4, -- Default capacity.
	BASE_SKILL_COST = 200,
	SKILL_COST_EXP = 1.25,

	-- should be contiguous and east should start at 0 (for conversion to radians)
	DIR_E = 0,
	DIR_NE = 1,
	DIR_N = 2,
	DIR_NW = 3,
	DIR_W = 4,
	DIR_SW = 5,
	DIR_S = 6,
	DIR_SE = 7,
	DIR_MAX = 8, -- not a valid direction

	DIR_SIDES = { 0, 2, 4, 6 }, -- E/N/W/S
	OFFSET_NEIGHBOURS = { -1, -1, 0, -1, 1, -1, -1, 0, 1, 0, -1, 1, 0, 1, 1, 1 },

	--shoulder directions
	SHOULDER_LEFT = "L",
	SHOULDER_RIGHT = "R",

	-- offsets and direction (dx, dy, dir) for all exits adjacent to a cell.
	ADJACENT_EXITS =
	{
		0, 0, 0,
		0, 0, 2,
		0, 0, 4,
		0, 0, 6,
		1, 0, 2,
		1, 0, 6,
		0, 1, 0,
		0, 1, 4,
		-1, 0, 2,
		-1, 0, 6,
		0, -1, 0,
		0, -1, 4,
	},

	SEERID_PERIPHERAL = 100000, -- Offset added to unitID to get the seer's periphal seerID.

	-----------------------
	-- returns to simquery.isWatchedCell
	
	CELL_WATCHED = 1, -- Cell in direct vision
	CELL_NOTICED = 2, -- Cell in peripheral vision
	CELL_HIDDEN = 3, -- Cell in direct or peripheral vision, but hidden due to cover

	-----------------------
	-- returns from simquery.canMove

	CANMOVE_OK = "OK",
	CANMOVE_DYNAMIC_IMPASS = "Dynamic Impass",
	CANMOVE_STATIC_IMPASS = "Static Impass",
	CANMOVE_NOMP = "No MP",
	CANMOVE_NOEXIT = "No Exit",
	CANMOVE_INTERRUPTED = "Interrupted",
	CANMOVE_INVALIDATED = "Invalidated",
	CANMOVE_NOPATH = "No Path",
	CANMOVE_PARTIAL_PATH = "Partial Path",
	CANMOVE_FAILED = "Failed", -- generic failure

	---------------
	-- Action costs	

	DEFAULT_COST = 1, -- Default cost for most things
	DISABLE_HEART_METER_CPUS = 1,
	SNEAKING_COST = 1, 
	DRAGGING_COST = 3, 
	MIN_DRAGGING_COST = 1.5, 
	--IMP_DRAGGING_COST = 2, 
	
	-------------------------------------------------------
	-- Constants to specify the operation of sim:modifyExit

	EXITOP_OPEN = 1,
	EXITOP_CLOSE = 2,
	EXITOP_TOGGLE_DOOR = 3,
	EXITOP_LOCK = 4,
	EXITOP_UNLOCK = 5,
	EXITOP_TOGGLE_LOCK = 6,
	EXITOP_BREAK_DOOR = 7,
	EXIT_DISARM = 8,

	------------------
	-- Alarm tracker

	TRACKER_SPAWN_UNIT_ENFORCER = "npc_guard_enforcer_reinforcement", -- Unitdef to spawn in
	TRACKER_SPAWN_UNIT_ENFORCER_2 = "npc_guard_enforcer_reinforcement_2", -- Unitdef to spawn in

    CUSTOM_DIFFICULTY = -1,
    TUTORIAL_DIFFICULTY = 0,
	NORMAL_DIFFICULTY = 1,
	EXPERIENCED_DIFFICULTY = 2,
	HARD_DIFFICULTY = 3,
	VERY_HARD_DIFFICULTY = 4,
	ENDLESS_DIFFICULTY  = 5,
	ENDLESS_PLUS_DIFFICULTY  = 6,
	TIME_ATTACK_DIFFICULTY  = 7,

    DIFFICULTY_OPTIONS =
    {
        [0] = util.extend( DEFAULT_DIFFICULTY_OPTIONS )
        {
        	savescumming = true,
            hideMapDestinations = false,
            drawInterestPoints = true,
            alarmMultiplier = 0,
            creditMultiplier = 1.0,
            firewallMultiplier = 0.5,
            rewindsLeft = 0,
            koDuration = 1,
            alarmTypes = "NONE",
            spawnTable = "NONE",
        },
        [1] = util.extend( DEFAULT_DIFFICULTY_OPTIONS )
        {
        	savescumming = true,
            hideMapDestinations = false,
            drawInterestPoints = true,
            creditMultiplier = 1.0,
            firewallMultiplier = 0.5,
            rewindsLeft = 5,
            beginnerPatrols = true,
            koDuration = 1,
		    alarmTypes = "EASY",
            spawnTable = "LESS",
            daemonQuantity = "LESS",
            countermeasuresFinal = false, 
        },
        [2] = util.extend( DEFAULT_DIFFICULTY_OPTIONS )
        {
        	savescumming = false,
            hideMapDestinations = false,
            drawInterestPoints = true,
            creditMultiplier = 1.0,
            firewallMultiplier = 0.5,
            rewindsLeft = 3,
            koDuration = 1,
        },
        [3] = DEFAULT_DIFFICULTY_OPTIONS,
        [4] = util.extend( DEFAULT_DIFFICULTY_OPTIONS )
        {
			alarmRaisedOnKO = true,
			startingPower = 5,
			dangerZones = false,
			meleeFromFront = false,
			spawnTable = "MORE",
        },
        [5] = util.extend( DEFAULT_DIFFICULTY_OPTIONS )
        {
			maxHours = math.huge,
        },
        [6] = util.extend( DEFAULT_DIFFICULTY_OPTIONS )
        {
			maxHours = math.huge,
			alarmRaisedOnKO = true,
			startingPower = 5,
			dangerZones = false,
			meleeFromFront = false,
			spawnTable = "MORE",
        },
        [7] = util.extend( DEFAULT_DIFFICULTY_OPTIONS )
        {
        	timeAttack = 2*60*cdefs.SECONDS
        },
   
    },

	ALARM_TYPES = 
	{
		EASY =  { "booting", "cameras", "firewalls", "guards", "enforcers", "enforcers" }, 
		NORMAL = { "cameras", "firewalls", "guards", "guards", "enforcers", "enforcers" },
		NONE = {},
	},

    DAEMON_TABLE =
    {
        -- Each entry is #of daemons for a given level difficulty. If the level difficulty exceeds the
        -- length of the table (eg. level 10 endless level difficulties), then the last entry is used.
        LESS = { 0, 2, 4, 4 },
        NORMAL = { 0, 4, 4, 4 },
        MORE = { 0, 6, 6, 6 },
    },

    DAEMON_TABLE_17_5 =
    {
        -- Each entry is #of daemons for a given level difficulty. If the level difficulty exceeds the
        -- length of the table (eg. level 10 endless level difficulties), then the last entry is used.
               --  1  2  3  4  5  6  7  8  9  10
        LESS =   { 0, 2, 4, 4, 4, 4, 5, 5, 5, 6 },
        NORMAL = { 0, 4, 4, 5, 5, 6, 6, 6, 7, 8 },
        MORE =   { 0, 6, 6, 7, 7, 7, 8, 8, 8, 9 },
    },


	SPAWN_TABLE = 
	{
		LESS =  {
					[1] = { "COMMON", "COMMON", "COMMON"},
                	[2] = { "COMMON", "COMMON", "COMMON", "ELITE" },
	                [3] = { "COMMON", "COMMON", "COMMON", "ELITE", "CAMERA_DRONE" },
    	            [4] = { "COMMON", "COMMON", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [5] = { "COMMON", "ELITE", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" }, 
			        [6] = { "OMNI", "ELITE", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [7] = { "OMNI", "OMNI", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [8] = { "OMNI", "OMNI", "OMNI", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [9] = { "OMNI", "OMNI", "OMNI", "OMNI", "ELITE", "CAMERA_DRONE" },
			        [10] = { "OMNI", "OMNI", "OMNI", "OMNI", "OMNI", "CAMERA_DRONE" },    	            
    	        }, 
		NORMAL = {
			        [1] = { "COMMON", "COMMON", "COMMON"},
			        [2] = { "COMMON", "COMMON", "COMMON", "ELITE", "CAMERA_DRONE" },
			        [3] = { "COMMON", "COMMON", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [4] = { "COMMON", "ELITE", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [5] = { "ELITE", "ELITE", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [6] = { "OMNI", "ELITE", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [7] = { "OMNI", "OMNI", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [8] = { "OMNI", "OMNI", "OMNI", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [9] = { "OMNI", "OMNI", "OMNI", "OMNI", "ELITE", "CAMERA_DRONE" },
			        [10] = { "OMNI", "OMNI", "OMNI", "OMNI", "OMNI", "CAMERA_DRONE" },
    			},
		MORE = {
			        [1] = { "COMMON", "COMMON", "COMMON","COMMON"},
			        [2] = { "COMMON", "COMMON", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [3] = { "COMMON", "COMMON", "COMMON", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [4] = { "ELITE", "ELITE", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [5] = { "OMNI", "ELITE", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [6] = { "OMNI", "OMNI", "ELITE", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [7] = { "OMNI", "OMNI", "OMNI", "ELITE", "ELITE", "CAMERA_DRONE" },
			        [8] = { "OMNI", "OMNI", "OMNI", "OMNI", "ELITE", "CAMERA_DRONE" },
			        [9] = { "OMNI", "OMNI", "OMNI", "OMNI", "OMNI", "CAMERA_DRONE" },
			        [10] = { "OMNI", "OMNI", "OMNI", "OMNI", "OMNI", "CAMERA_DRONE" },	
    			},    			
		NONE = {
			        [1] = {},
			        [2] = {},
			        [3] = {},
			        [4] = {},
			        [5] = {},
			        [6] = {},
			        [7] = {},
			        [8] = {},
			        [9] = {},
			        [10] = {},		
				},
	},

    OMNI_SPAWN_TABLE =
    {
		LESS = { "PROTECTOR", "SOLDIER", "CRIER", "OMNI_NON_SOLDIER", "CAMERA_DRONE" }, 
		NORMAL = { "PROTECTOR", "SOLDIER", "CRIER", "OMNI", "OMNI", "CAMERA_DRONE" },
		MORE = { "PROTECTOR", "SOLDIER", "CRIER", "OMNI", "OMNI", "OMNI", "CAMERA_DRONE" },
		NONE = { }
    },

	TRACKER_FIREWALLS = {
		[1] = 1,
		[2] = 1,
		[3] = 1,
		[4] = 1,
	},



	TRACKER_GUARDS = {
		[1] = 1,
		[2] = 1,
		[3] = 1,
		[4] = 1,
	},

	TRACKER_CAMERAS = {
		[1] = 3,
		[2] = 3,
		[3] = 3,
		[4] = 3,
	},

    MISSION_REPUTATION = 
    {
	    [1] = 200, 
	    [2] = 400, 
	    [3] = 600, 
	    [4] = 1000, 
	    [5] = 1200, 
	    [6] = 1600, 
	    [7] = 2400, 
	    [8] = 3000, 
	    [9] = 4000, 
	    [10] = 5000, 
    },

    GAME_COMPLETION_REPUTATION = 1000,

    MONEY_SCALAR = 
    {
	    [1] = 1.00, 
	    [2] = 1.25, 
	    [3] = 1.50, 
	    [4] = 1.75,
	    [5] = 1.75,
	    [6] = 1.75,
	    [7] = 1.75,
	    [8] = 1.75,
	    [9] = 1.75,
	    [10] = 1.75,
    },

	TRACKER_MAXCOUNT = 30, -- Max tracker count before reinforcements start spawning in
	TRACKER_INCREMENT = 5,  
    TRACKER_MAXSTAGE = 6, -- MAXCOUNT / INCREMENT

    HOLOCIRCUIT_KO = 2,
    HOLOCIRCUIT_RANGE = 2,

	--- PROGRAMS
	----------------- 
	MAX_PROGRAMS = 5,

	-----------------
	-- Behaviour States
	BSTATE_INVALID = "INVALID",
	BSTATE_COMPLETE = "COMPLETE",
	BSTATE_FAILED = "FAILED",
	BSTATE_RUNNING = "RUNNING",
	BSTATE_WAITING = "PROCESSING",
	BSTATE_WAITINGFORCORPTURN = "WAITING FOR CORP",
    BSTATE_WAITINGFORPCTURN = "WAITING FOR PC",


	------------------
	-- INVESTIGATION REASONS
	REASON_NOISE = "HEARD NOISE",
	REASON_SHARED = "SHARED",
	REASON_DOOR = "DOOR",
	REASON_KO = "KNOCKEDOUT",
	REASON_FOUNDCORPSE = "FOUND CORPSE",
	REASON_FOUNDOBJECT = "FOUND OBJECT",
	REASON_FOUNDDRONE = "FOUND DRONE",
	REASON_WITNESS = "WITNESS",
	REASON_REINFORCEMENTS = "REINFORCEMENTS",
	REASON_LOSTTARGET = "LOST TARGET",
	REASON_SENSEDTARGET = "SENSED TARGET",
	REASON_NOTICED = "NOTICED",
	REASON_HUNTING = "HUNTING",
	REASON_CAMERA = "CAMERA",
	REASON_PATROLCHANGED = "PATROLCHANGED",
	REASON_SCANNED = "SCANNED",
	REASON_ALARMEDSAFE = "ALARMED SAFE",
	REASON_SMOKE = "SMOKE",

	-------------------
	-- SENSES
	SENSE_HEARING = "HEARING",
	SENSE_SIGHT = "SIGHT",
	SENSE_PERIPHERAL = "PERIPHERAL",
	SENSE_HIT = "HIT",
	SENSE_RADIO = "RADIO",
	SENSE_DEBUG = "DEBUG",

	-------------------
	-- SITUATIONS
	SITUATION_IDLE = "IdleSituation",
	SITUATION_INVESTIGATE = "InvestigateSituation",
	SITUATION_HUNT = "HuntSituation",
	SITUATION_COMBAT = "CombatSituation",
	SITUATION_FLEE = "FleeSituation",

	---------------------
	-- Patrol modes
	PATROL_LOOPING = "Looping",
	PATROL_FORWARD = "Forward",
	PATROL_BACK = "Back",

	---------------------
	-- Investigation Roles
	INVESTIGATE_DETECTIVE = "DETECTIVE",
	INVESTIGATE_SENTRY = "SENTRY",
	INVESTIGATE_BYSTANDER = "BYSTANDER",

	----------------------
	-- Turn States
	TURN_STARTING = "Starting",
	TURN_PLAYING = "Playing",
	TURN_ENDING = "Ending",

	------------------
	-- Trigger types.

	TRG_NONE = 0,
	TRG_OVERWATCH = 1,
	TRG_UI_ACTION = 2,
	TRG_SOUND_EMITTED = 3,
	TRG_ACTION = 4,
	TRG_UNIT_DISAPPEARED = 5,
	TRG_UNIT_APPEARED = 6,
	TRG_UNIT_USEDOOR = 7,
	TRG_ALARM_ON = 8,
	TRG_ALARM_OFF = 9,
	TRG_UNIT_SHOT = 10,
	TRG_UNIT_WARP = 11,
	TRG_UNIT_CHILDED = 12,
	TRG_UNIT_WARP_PRE = 13,
	TRG_UNIT_USEDOOR_PRE = 14,
	TRG_UNIT_HIT = 15,
	TRG_UNIT_MISSED = 16,
	TRG_UNIT_KILLED = 17,
	TRG_UNIT_ALERTED = 18,
	TRG_UNIT_RESCUED = 19,
	TRG_START_TURN = 20,
    TRG_UNIT_ESCAPED = 21,
	TRG_UNIT_HIJACKED = 22,
	TRG_END_TURN = 23,
	TRG_UNIT_KO = 24,
	TRG_UNIT_PARALYZED = 25,
	TRG_NEW_INTEREST = 30,
	TRG_DEL_INTEREST = 31,
	TRG_UPDATE_HUNT = 32,
	TRG_SITUATION_CHANGE = 40,
	TRG_UNLOCK_DOOR = 42,
	TRG_UNIT_PICKEDUP = 50,
	TRG_UNIT_DROPPED = 51,
	TRG_UNIT_DEPLOYED = 52,
    TRG_UNIT_EMP = 53,
    TRG_SAFE_LOOTED = 66,
    TRG_ICE_BROKEN = 67, 
    TRG_CLOSE_NANOFAB = 68, 
    TRG_SET_OVERWATCH = 69,
    TRG_DAEMON_INSTALL = 70, 
    TRG_CLOSE_AUGMENT_MACHINE = 71,
    TRG_CAUGHT_BY_CAMERA = 72,
	TRG_LAST_WORDS = 73,
    TRG_BUY_ITEM = 74,
    TRG_USE_AUGMENT_MACHINE = 75,
    TRG_UNIT_NEWINTEREST = 76,
    TRG_UNIT_NEWTARGET = 77,
    TRG_DAEMON_REVERSE = 78,
    TRG_OPEN_DOOR = 79,
    TRG_COMPILE_START = 80,
    TRG_RECAPTURE_DEVICES = 81,
    TRG_MAP_EVENT = 82,
    TRG_ALARM_INCREASE = 83,

	MAP_EVENTS =
	{	
		SWITCH = 1,
	},


	TRG_ALARM_STATE_CHANGE = 60, 

	TRG_TIMER = 100,
	TRG_GAME_OVER = 999,

	--------------------------------------------------------------------
	-- sim events
	EV_FRAME_UPDATE = 0,
	EV_UNIT_WARPED = 1,
	EV_UNIT_START_WALKING = 2,
	EV_UNIT_STOP_WALKING = 3,
	EV_UNIT_INTERRUPTED = 4,
	EV_UNIT_RELOADED = 5,
	EV_UNIT_UNSEEN = 6,
	EV_UNIT_SEEN = 7,
	EV_UNIT_START_SHOOTING = 8,
	EV_UNIT_STOP_SHOOTING = 9,
	EV_UNIT_SHOT = 10,
	EV_UNIT_THROW = 11,
	EV_UNIT_THROWN = 12,
	EV_UNIT_DEPLOY = 14,
	EV_UNIT_PICKEDUP = 15,
	EV_UNIT_PEEK = 18,	
	EV_UNIT_USECOMP = 19,
	EV_UNIT_PICKUP = 20,
	EV_UNIT_USEDOOR = 21,
	EV_UNIT_DEATH = 22,
	EV_UNIT_ALERTED = 23,
	EV_UNIT_APPEARED = 26,
	EV_UNIT_OVERWATCH = 27,
	EV_UNIT_OVERWATCH_MELEE = 28,	
	EV_UNIT_KO = 29,	
	EV_UNIT_MELEE = 30,	
	EV_UNIT_TURN = 31,
	EV_UNIT_USEDOOR_PST = 32,
	EV_UNIT_UNTIE = 36,
	EV_UNIT_DRAG_BODY = 37,
	EV_UNIT_DROP_BODY = 38,
	EV_UNIT_BODYDROPPED = 39,
	EV_UNIT_PLAY_ANIM = 40,
	EV_UNIT_GUNCHECK = 41,
	EV_UNIT_STOP_THROW = 43,
	EV_UNIT_DISGUISE = 44,

	EV_UNIT_SPAWNED = 50,
	EV_UNIT_DESPAWNED = 51,
	EV_UNIT_REFRESH = 52,    -- refreshes units HUD
	EV_UNIT_REFRESH_TRACKS = 53,
	EV_UNIT_CAPTURE = 54,
    EV_UNIT_REFRESH_SITUATION = 55,
	
	EV_UNIT_FLOAT_TXT = 56,
	EV_UNIT_HIT = 57,
	EV_UNIT_HIT_SHIELD = 60,
	EV_UNIT_INSTALL_AUGMENT = 62, 
	EV_UNIT_FLY_TXT = 64,
	EV_UNIT_ADD_FX = 65,

	EV_SCRIPT_EXIT_MAINFRAME = 66,
	EV_SCRIPT_ENTER_MAINFRAME = 67,

	EV_UNIT_WIRELESS_SCAN = 100,
	EV_UNIT_HEAL = 102,
	EV_UNIT_SHOW_LABLE = 104,
	EV_UNIT_RESET_ANIM_PLAYBACK = 105,
	EV_UNIT_ADD_INTEREST = 107,
	EV_UNIT_DEL_INTEREST = 108,
	EV_UNIT_UPDATE_INTEREST = 109,
	EV_UNIT_SPEAK = 110,
	EV_UNIT_START_PIN = 111,
	EV_UNIT_ENGAGED = 112,
	EV_UNIT_GOALS_UPDATED = 113,
	EV_UNIT_LOOKAROUND = 114,
	EV_UNIT_DONESEARCHING = 115,
	EV_UNIT_GET_ITEM = 120,
	EV_UNIT_ACTIVATE = 121,
	EV_UNIT_DEACTIVATE = 122,
	EV_UNIT_UPDATE_SPOTSOUND = 123,
	EV_UNIT_TAGGED = 124,
	EV_UNIT_RESCUED = 125,
	EV_UNIT_OBSERVED = 126,
	EV_UNIT_MONST3R_CONSOLE = 127,
	EV_UNIT_TINKER_END = 128,
	EV_UNIT_GOTO_STAND = 129,
	EV_UNIT_SWTICH_FX = 130,

	EV_EXIT_MODIFIED = 200,
	
	EV_LOS_REFRESH = 300,	
	EV_CAM_PAN = 301,	
	EV_PLAY_SOUND = 302,
	EV_SET_MUSIC_PARAM = 303,

	EV_UNIT_MAINFRAME_UPDATE = 350,
	EV_UNIT_UPDATE_ICE = 351,
	EV_MAINFRAME_INSTALL_PROGRAM = 361,
	EV_MAINFRAME_UNINSTALL_PROGRAM = 362,
	EV_MAINFRAME_PARASITE = 363,	
	EV_MAINFRAME_MOVE_DAEMON = 364,	
	EV_MAINFRAME_INSTALL_NEW_DAEMON = 365,

	EV_HUD_MPUSED = 401,
	EV_HUD_SUBTRACT_CPU = 402,
	EV_HUD_REFRESH = 403,
	EV_WALL_REFRESH = 404,

	EV_TURN_END = 500,
	EV_TURN_START = 502,
    EV_ACHIEVEMENT = 505,

	EV_SOUND_EMITTED = 601,
	EV_SCANRING_VIS = 602,
	EV_ADVANCE_TRACKER = 603,
	EV_ALERT = 604,
	EV_LOOT_ACQUIRED = 605,
	EV_ITEMS_PANEL = 610, 
	EV_CMD_DIALOG = 611,
	EV_AGENT_LIMIT = 613, 
	EV_CLOAK_IN = 614, 
	EV_CLOAK_OUT = 615, 
	EV_GAIN_AP = 616, 

	EV_SHOW_WARNING = 621,
	EV_CREDITS_REFRESH = 623, 
	EV_OVERLOAD_VIZ = 624,
	EV_GRENADE_EXPLODE = 625,
	EV_THREATS_DIALOG = 630,
	EV_KO_GROUP = 633,
	EV_WAIT_DELAY = 634,
	EV_REFRESH_OBJECTIVES = 637,
	EV_SKILL_LEVELED = 638,
	EV_SHOW_DAEMON = 639,
	EV_SHOW_ALARM = 640,
	EV_SHOW_ALARM_FIRST = 642, 
	EV_KILL_DAEMON = 645,
	EV_SHOW_MODAL = 646,
    EV_SHOW_MODAL_REWIND = 647,
	EV_SHOW_REVERSE_DAEMON = 648, 
	EV_SHOW_DIALOG = 649,

	EV_PATHNODE_RESERVE = 650,
	EV_PATHNODE_UNRESERVE = 651,
 	EV_TELEPORT = 652,
 	EV_FLY_IMAGE = 653,
 	EV_PUSH_QUIET_MIX = 654, 
 	EV_FADE_TO_BLACK = 655, 
 	EV_UNIT_TAB = 656,
 	EV_SHORT_WALLS = 657, 
 	EV_HIDE_PROGRAM = 658, 
 	EV_SLIDE_IN_PROGRAM = 659, 
 	EV_GRAFTER_DIALOG = 660,
 	EV_EXEC_DIALOG = 661,  
 	EV_INSTALL_AUGMENT_DIALOG = 662,  
 	EV_BLINK_REWIND = 663,
	EV_SHOW_COOLDOWN = 664,
	EV_FLASH_VIZ = 665,
    EV_DAEMON_TUTORIAL = 666,
	
	EV_PULSE_SCAN = 667,

	EV_CHECKPOINT = 701,
    EV_CLEAR_QUEUE = 702, -- skip & clear mission panel queue 

	--------------------
	-- TRAP DEFS 

	TRAP_SHOCK = 1, 
	
    --------------------
    -- This choice is made when a choice dialog aborts.

    CHOICE_ABORT = 0,

	---------------------
	-- SOUND DEFS
	
	SOUND_RANGE_0 = SOUND_RANGE_0,
	SOUND_RANGE_1 = SOUND_RANGE_1,
	SOUND_RANGE_2 = SOUND_RANGE_2,
	SOUND_RANGE_3 = SOUND_RANGE_3,
	SOUND_RANGE_MAX = SOUND_RANGE_MAX,

	SOUND_GAMEPLAY_POPUP = "SpySociety/HUD/gameplay/popup",

	FOOTSTEP_FRAMES_WALK = {1, 13},
	FOOTSTEP_FRAMES_RUN = {4, 14},
	FOOTSTEP_FRAMES_SNK = {7, 17},

	SOUNDPATH_USE_CONSOLE = "SpySociety/Actions/console_use",
	SOUNDPATH_SAFE_OPEN = "SpySociety/Objects/safe_open",

	-- famale agent footsteps
	SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_NORMAL = "SpySociety/Movement/footstep_female_hardwood_occlude",
	SOUNDPATH_FOOTSTEP_FEMALE_CARPET_NORMAL = "SpySociety/Movement/footstep_female_carpet_occlude",
	SOUNDPATH_FOOTSTEP_FEMALE_METAL_NORMAL = "SpySociety/Movement/footstep_female_metal_occlude",

	SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_SOFT = "SpySociety/Movement/footstep_female_soft_hardwood_occlude",
	SOUNDPATH_FOOTSTEP_FEMALE_CARPET_SOFT = "SpySociety/Movement/footstep_female_soft_carpet_occlude",
	SOUNDPATH_FOOTSTEP_FEMALE_METAL_SOFT = "SpySociety/Movement/footstep_female_soft_metal_occlude",
	-- male agent footsteps
	SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL = "SpySociety/Movement/footstep_male_hardwood_occlude",
	SOUNDPATH_FOOTSTEP_MALE_CARPET_NORMAL = "SpySociety/Movement/footstep_male_carpet_occlude",
	SOUNDPATH_FOOTSTEP_MALE_METAL_NORMAL = "SpySociety/Movement/footstep_male_metal_occlude",

	SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT = "SpySociety/Movement/footstep_male_soft_hardwood_occlude",
	SOUNDPATH_FOOTSTEP_MALE_CARPET_SOFT = "SpySociety/Movement/footstep_male_soft_carpet_occlude",
	SOUNDPATH_FOOTSTEP_MALE_METAL_SOFT = "SpySociety/Movement/footstep_male_soft_metal_occlude",
	-- guard footsteps
	SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL = "SpySociety/Movement/footstep_guard_hardwood_occlude",
	SOUNDPATH_FOOTSTEP_GUARD_CARPET_NORMAL = "SpySociety/Movement/footstep_guard_carpet_occlude",
	SOUNDPATH_FOOTSTEP_GUARD_METAL_NORMAL = "SpySociety/Movement/footstep_guard_metal_occlude",
	-- walking drone
	SOUNDPATH_FOOTSTEP_DRONE_HARDWOOD_NORMAL = "SpySociety/Movement/footstep_drone_hardwood_occlude",
	SOUNDPATH_FOOTSTEP_DRONE_CARPET_NORMAL = "SpySociety/Movement/footstep_drone_carpet_occlude",
	SOUNDPATH_FOOTSTEP_DRONE_METAL_NORMAL = "SpySociety/Movement/footstep_drone_metal_occlude",
	-- dragging bodies
	SOUNDPATH_DRAG_HARDWOOD = "SpySociety/Movement/drag_hardwood",
	SOUNDPATH_DRAG_CARPET = "SpySociety/Movement/drag_metal",
	SOUNDPATH_DRAG_METAL = "SpySociety/Movement/drag_carpet",

	SOUNDPATH_DEATH_HARDWOOD = "SpySociety/Movement/deathfall_agent_hardwood",  
	SOUNDPATH_HIT_BALLISTIC_FLESH = "SpySociety/HitResponse/hitby_ballistic_flesh",
	SOUNDPATH_HIT_BALLISTIC_METAL = "SpySociety/HitResponse/hitby_ballistic_metal",
	SOUNDPATH_HIT_BALLISTIC_CYBORG = "SpySociety/HitResponse/hitby_ballistic_cyborg",
	SOUNDPATH_TURRET_SCAN = "SpySociety/Objects/turret/gunturret_scan_LP",
	
	SOUND_SMALL = { path = nil, range = SOUND_RANGE_1 },
	SOUND_MED = { path = nil, range = SOUND_RANGE_2 },
	SOUND_LARGE = { path = nil, range = SOUND_RANGE_3 },
	SOUND_KICK_DOOR = { path = "SpySociety/Actions/door_kickedopen", range = 2 },

	SOUND_DOOR_OPEN = { path = "SpySociety/Actions/door_open_quiet", range = SOUND_RANGE_0 },	
	SOUND_DOOR_CLOSE = { path = "SpySociety/Actions/door_close_quiet", range = SOUND_RANGE_0 },
	SOUND_DOOR_BREAK = { path = "SpySociety/Actions/door_smashed", range = SOUND_RANGE_2 },
	
	SOUND_ELEVATOR_OPEN = { path = "SpySociety/Objects/elevator_open", range = SOUND_RANGE_1, innocuous = true   },
	SOUND_ELEVATOR_CLOSE = { path = "SpySociety/Objects/elevator_close", range = SOUND_RANGE_1, innocuous = true  },

	SOUND_DOOR_UNLOCK = { path = "SpySociety/Actions/door_passcardunlock", range = 0 },
	SOUND_DOOR_LOCK = { path = "SpySociety/Actions/door_lock", range = 0 },
	SOUND_CREDITS_PICKUP = { path = "SpySociety/HUD/gameplay/gain_money", range = SOUND_RANGE_0 },
	SOUND_PWR_PICKUP = { path = "SpySociety/HUD/gameplay/gain_pwr", range = SOUND_RANGE_0 },
	SOUND_ITEM_PICKUP = { path = "SpySociety/Actions/item_pickup", range = SOUND_RANGE_0 },
	SOUND_ITEM_PUTDOWN = { path = "SpySociety/Actions/item_place", range = SOUND_RANGE_0 },
	SOUND_PRIME_EMP = { path = "SpySociety/Actions/emp_activate", range = SOUND_RANGE_0 },
	SOUND_PLACE_TRAP = { path = "SpySociety/Actions/place_doortrap", range = SOUND_RANGE_0 },	
	SOUND_HIT_LASERS_FLESH = { path = "SpySociety/HitResponse/hitby_laser_flesh", range = SOUND_RANGE_0 },
	SOUND_HIT_ENERGY_FLESH = { path = "SpySociety/HitResponse/hitby_energy_flesh", range = SOUND_RANGE_0 },
	SOUND_HIT_BALLISTIC_FLESH = { path = "SpySociety/HitResponse/hitby_ballistic_flesh", range = SOUND_RANGE_0 },
	SOUND_HIT_BALLISTIC_METAL = { path = "SpySociety/HitResponse/hitby_ballistic_metal", range = SOUND_RANGE_0 },	
	SOUND_HIT_ENERGY_FLESH = { path = "SpySociety/HitResponse/hitby_energy_flesh", range = SOUND_RANGE_0 },
	SOUND_DEATH_HARDWOOD = { path = "SpySociety/HitResponse/deathfall_agent_hardwood", range = SOUND_RANGE_2 },
	SOUND_SECURITY_ALERTED = { path = "SpySociety/Objects/securitycamera_spotplayer", range = SOUND_RANGE_3, innocuous = true },
	SOUND_DOOR_ALARM = { path = "SpySociety/Objects/securitycamera_spotplayer", range = SOUND_RANGE_2 },
	SOUND_MAINFRAME_PING = { path = "SpySociety/Actions/mainframe_noisemaker", range = SOUND_RANGE_1, distanceOffset = -5, ignoreSight = true },
	SOUND_DAEMON_REVEAL = { path = "SpySociety/HUD/mainframe/node_capture", range = SOUND_RANGE_0 },
	SOUND_HOST_PARASITE = { path = "SpySociety/HUD/mainframe/node_capture", range = SOUND_RANGE_0 },

	SOUND_MAINFRAME_REVEAL = { path = "SpySociety/Actions/mainframe_objectsreveled", range = SOUND_RANGE_MAX, innocuous = true },
	
	SOUND_EMP_EXPLOSION = { path = "SpySociety/Actions/EMP_explo", range = SOUND_RANGE_2 },
	SOUND_OVERLOAD =  { path = "SpySociety/Actions/mainframe_soundbugoverload", range = SOUND_RANGE_2 },
	SOUND_HOLOCIRCUIT_OVERLOAD =  { path = "SpySociety/Actions/mainframe_soundbugoverload", range = SOUND_RANGE_2, innocuous = true },
	SOUND_SHOCKTRAP =  { path = "SpySociety/HitResponse/hitby_shocktrap", range = SOUND_RANGE_1 },
	SOUND_ANTIVIRUS = { path = nil, range = SOUND_RANGE_1, innocuous = true },

	SOUND_UNHIDE = { path = "SpySociety/Actions/agent_discovered", range = SOUND_RANGE_0, innocuous = true },
	SOUND_CLOAK = { path = "SpySociety/Actions/agent_cloaked", range = SOUND_RANGE_0, innocuous = true },

	SOUND_PEEK = { path = "SpySociety/Actions/agent_peek", range = SOUND_RANGE_0, innocuous = true },

	SOUND_TURRET_ARM = { path = "SpySociety/Objects/turret/gunturret_arm", range = SOUND_RANGE_2, innocuous = true },
	SOUND_TURRET_LOAD = { path = "SpySociety/Objects/turret/gunturret_load", range = SOUND_RANGE_2, innocuous = true },

	SOUND_CAMERA_DESTROYED = { path = "SpySociety/Objects/Camera_destroyed", range = SOUND_RANGE_2 },
	SOUND_TURRET_DESTROYED = { path = "SpySociety/Objects/turret/gunturret_explo", range = SOUND_RANGE_2 },

	SOUND_SPEECH_GUARD_INVESTIGATE = "SpySociety/Agents/<voice>/Suspicious/Investigate_Generic",
	SOUND_SPEECH_GUARD_INVESTIGATE_NOISE = "SpySociety/Agents/<voice>/Suspicious/Investigate_Heard",
	SOUND_SPEECH_GUARD_INVESTIGATE_SAW = "SpySociety/Agents/<voice>/Suspicious/Investigate_Saw",
	SOUND_SPEECH_GUARD_INVESTIGATE_DRONE = "SpySociety/Agents/<voice>/Suspicious/drone_down",
	SOUND_SPEECH_GUARD_INVESTIGATE_SEARCH = "SpySociety/Agents/<voice>/Suspicious/Investigating",
	SOUND_SPEECH_GUARD_INVESTIGATE_FINISH = "SpySociety/Agents/<voice>/Suspicious/Investigating_Stop",
	SOUND_SPEECH_GUARD_INVESTIGATE_REINFORCEMENT = "SpySociety/Agents/<voice>/Suspicious/Reinforcement_Arrival",

	SOUND_SPEECH_GUARD_HUNT = "SpySociety/Agents/<voice>/Agitated/Investigate_Generic",
	SOUND_SPEECH_GUARD_HUNT_NOISE = "SpySociety/Agents/<voice>/Agitated/Investigate_Generic",
	SOUND_SPEECH_GUARD_HUNT_SAW = "SpySociety/Agents/<voice>/Agitated/Investigate_Generic",
	SOUND_SPEECH_GUARD_HUNT_FOUNDOBJECT = "SpySociety/Agents/<voice>/Agitated/FindObject",
	SOUND_SPEECH_GUARD_HUNT_SEARCH = "SpySociety/Agents/<voice>/Agitated/Investigating",
	SOUND_SPEECH_GUARD_HUNT_FINISH = "SpySociety/Agents/<voice>/Agitated/Investigate_Stop",
	SOUND_SPEECH_GUARD_HUNT_LOSTTARGET = "SpySociety/Agents/<voice>/Agitated/Lost_Target",
	SOUND_SPEECH_GUARD_HUNT_CORPSE = "SpySociety/Agents/<voice>/Agitated/Found_Guard",
	SOUND_SPEECH_GUARD_HUNT_DRONE = "SpySociety/Agents/<voice>/Agitated/drone_down",
	SOUND_SPEECH_GUARD_HUNT_WAKEUP = "SpySociety/Agents/<voice>/Agitated/Wakeup",
	SOUND_SPEECH_GUARD_HUNT_REINFORCEMENT = "SpySociety/Agents/<voice>/Agitated/Reinforcement_Arrival",
	SOUND_SPEECH_GUARD_HUNT_BREAKDOOR = "SpySociety/Agents/<voice>/Agitated/AboutToKickInDoor",
	SOUND_SPEECH_GUARD_HUNT_GRENADE = "SpySociety/Agents/<voice>/Agitated/Throwing_Grenade",

	SOUND_SPEECH_GUARD_COMBAT_NEWTARGET = "SpySociety/Agents/<voice>/Agitated/Spotted_Agent",
	SOUND_SPEECH_GUARD_COMBAT_TARGETDOWN = "SpySociety/Agents/<voice>/Agitated/After_Shooting",
	SOUND_SPEECH_GUARD_COMBAT_NEWTURRET = "SpySociety/Agents/<voice>/Agitated/TargetTurret",
	SOUND_SPEECH_GUARD_COMBAT_TURRETDOWN = "SpySociety/Agents/<voice>/Agitated/EliminateTurret",

	SOUND_SPEECH_GUARD_FLEE_PANIC = "SpySociety/Agents/<voice>/Agitated/panic",
	SOUND_SPEECH_GUARD_FLEE_COWER = "SpySociety/Agents/<voice>/Agitated/cower",
	SOUND_SPEECH_GUARD_FLEE_STARTLED = "SpySociety/Agents/<voice>/Agitated/startled",

	SOUND_DRONE_GENERIC = "SpySociety/Objects/drone/drone_emote",

	SOUND_HUD_INCIDENT_POPUP = 	{ path = "SpySociety/HUD/gameplay/console_popup", range = SOUND_RANGE_0 },
	SOUND_HUD_INCIDENT_POSITIVE = { path = "SpySociety/HUD/gameplay/console_result_good", range = SOUND_RANGE_0 },
	SOUND_HUD_INCIDENT_NEGATIVE = { path = "SpySociety/HUD/gameplay/console_result_bad", range = SOUND_RANGE_0 },

	DOOR_KEYS = {
		OFFICE 			= 1,
		SECURITY 		= 2,
		ELEVATOR 		= 4,
		ELEVATOR_INUSE 	= 8,
		GUARD   		= 16,
		VAULT   		= 32,
		FINAL_LEVEL	    = 64, 
		FINAL_RED       = 128, 
        SPECIAL_EXIT    = 256, 
        BLAST_DOOR      = 512, 
	},

	DEFAULT_KEYID = 1,

	ITEMS_SPECIAL_DAY_1 ={
		{ "vault_passcard", 15 },
		{ "item_defiblance", 10 },
		{ "item_lockdecoder", 10 },
		{ "augment_distributed_processing", 10 },
		{ "item_icebreaker", 10 },

		{ "augment_predictive_brawling", 10 },

		{ "item_hologrenade", 10 },
		{ "item_stickycam", 10 },
		{ "augment_microslam_apparatus", 10 },
		{ "item_light_pistol_ammo", 10 },
		{ "item_smokegrenade", 10 },
	},

	ITEMS_SPECIAL_DAY_2 = {
		{ "vault_passcard", 15 },
		{ "item_defiblance", 10 },
		{ "item_lockdecoder", 10 },
		{ "augment_distributed_processing", 10 },

		{ "item_icebreaker_2", 10 },
		{ "item_bio_dartgun", 10 },
		{ "item_power_tazer_2", 10 },
		{ "item_light_pistol_dam", 10 },
		
		{ "augment_penetration_scanner", 10 },

		{ "item_hologrenade", 10 },
		{ "item_stickycam", 10 },
		--{ "augment_microslam_apparatus", 10 },
	},

	ITEMS_SPECIAL_DAY_4 = {
		{ "item_defiblance", 10 },
		{ "item_lockdecoder", 10 },
		{ "augment_distributed_processing", 10 },

		{ "item_icebreaker_2", 10 },
		{ "item_bio_dartgun", 10 },
		{ "item_power_tazer_2", 10 },
		{ "item_light_pistol_dam", 10 },
		
		{ "augment_penetration_scanner", 10 },

		{ "item_hologrenade", 10 },
		{ "item_stickycam", 10 },
	},	

	BEGINNER_ITEMS_SPECIAL_DAY_2 = 
	{
		{ "augment_distributed_processing", 15 },
		{ "item_emp_pack_2", 10 },
		{ "item_icebreaker_2", 10 },
		{ "item_laptop_2", 10 },
	},

	BEGINNER_ITEMS_SPECIAL_DAY_3 = 
	{
		{ "item_defiblance", 10 },
		{ "augment_penetration_scanner", 10 },
		{ "augment_piercing_scanner", 10 },
		{ "item_tazer_3", 10 },
		{ "item_bio_dartgun", 15 },
	},

	BEGINNER_ITEMS_SPECIAL_VARIETY = 
	{
		{ "augment_net_downlink", 10 },
		{ "augment_predictive_brawling", 10 },
		{ "augment_holocircuit_overloaders", 10 },
		{ "item_emp_pack", 10 },
		{ "item_tazer_2", 10 },
	},

	CAMPAIGN_EVENTS = 
	{
		CUSTOM_FINAL = 1,
		ADD_MORE_HOURS = 2,
		GOTO_MISSION = 3,
		SET_CAMPAIGN_PARAM = 4,
		CUSTOM_SCRIPT= 5,
		ADVANCE_TO_NEXT_DAY = 6,
		SET_CUSTOM_SCRIPT_INDEX = 7,
		REMOVE_AGENT = 8,
		ADD_AGENT = 9,
		INJECT_PREFABS = 10,
	},
	
}

function _M:stringForEvent(eventType)
	for k,v in pairs(self) do
		if type(k) == "string" and type(v) == "number" and string.sub(k, 1, 3) == "EV_" and v == eventType then
			return k
		end
	end
    return eventType
end

function _M:stringForTrigger(eventType)
	for k,v in pairs(self) do
		if type(k) == "string" and type(v) == "number" and string.sub(k, 1, 4) == "TRG_" and v == eventType then
			return k
		end
	end
end

function _M:stringForDir(dir)
	for k,v in pairs(self) do
		if type(k) == "string" and type(v) == "number" and string.sub(k, 1, 4) == "DIR_" and v == dir then
			return k
		end
	end
end

util.strictify( _M )

return _M
