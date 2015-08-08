----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------
-- Client/server shared definitions and utility functions for
-- online functionality.
----------------------------------------------------------------

local array = include("modules/array")
local util = include("client_util")
local mathutil = include( "modules/mathutil" )
local agentdefs = include("sim/unitdefs/agentdefs")
local skilldefs = include( "sim/skilldefs" )
local simdefs = include( "sim/simdefs" )



----------------------------------------------------------------

local BASE_TRAVEL_TIME = 3

local TUTORIAL_SITUATION = "tutorial"

local function createGeneralSecondaryMissionObj()
	return string.format("<c:777777>> %s</>", STRINGS.MISSIONS.ESCAPE.SECONDARY_OBJECTIVE)
end

local function createGeneralMissionObj( txt, txt2 )

	return string.format("> %s\n> %s", 
		txt, 
		STRINGS.MISSIONS.ESCAPE.OBJECTIVE)
end


local GENERAL_MISSIONS = {

	SERVER_FARM = {
		moreInfo = STRINGS.MISSIONS.LOCATIONS.SERVER_FARM.MORE_INFO,
		insetTitle = STRINGS.MISSIONS.LOCATIONS.SERVER_FARM.INSET_TITLE,
		insetTxt =  STRINGS.MISSIONS.LOCATIONS.SERVER_FARM.INSET_TXT,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.SERVER_FARM.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.SERVER_FARM.REWARD,
        locationName = STRINGS.MISSIONS.LOCATIONS.SERVER_FARM.NAME,
		insetVoice = {
			"SpySociety/VoiceOver/Missions/MapScreen/Location_ServerFarms",
			"SpySociety/VoiceOver/Missions/MapScreen/Location_ServerFarms_2",
		},
		insetImg = "gui/menu pages/corp_select/New_mission_icons/10008.png",
		icon = "gui/mission_previews/server_farm.png",
		objectives = createGeneralMissionObj( STRINGS.MISSIONS.ESCAPE.OBJ_SERVERFARM ),
		secondary_objectives = createGeneralSecondaryMissionObj(),
	},
	SECURITY = {
		moreInfo = STRINGS.MISSIONS.LOCATIONS.SECURITY.MORE_INFO,
		insetTitle = STRINGS.MISSIONS.LOCATIONS.SECURITY.INSET_TITLE,
		insetTxt = STRINGS.MISSIONS.LOCATIONS.SECURITY.INSET_TXT,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.SECURITY.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.SECURITY.REWARD,
        locationName = STRINGS.MISSIONS.LOCATIONS.SECURITY.NAME,
		insetVoice = {
			"SpySociety/VoiceOver/Missions/MapScreen/Location_SecureSite",
			"SpySociety/VoiceOver/Missions/MapScreen/Location_SecureSite_2",
		},
		insetImg = "gui/menu pages/corp_select/New_mission_icons/terminal thing.png",
		icon = "gui/mission_previews/security_dispatch.png",
		objectives = createGeneralMissionObj( STRINGS.MISSIONS.ESCAPE.OBJ_SECURITY),
		secondary_objectives = createGeneralSecondaryMissionObj(),
	},	
	NANO_FAB = {
		moreInfo = STRINGS.MISSIONS.LOCATIONS.NANO_FAB.MORE_INFO,
		insetTitle =  STRINGS.MISSIONS.LOCATIONS.NANO_FAB.INSET_TITLE,
		insetTxt = STRINGS.MISSIONS.LOCATIONS.NANO_FAB.INSET_TXT,
        locationName = STRINGS.MISSIONS.LOCATIONS.NANO_FAB.NAME,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.NANO_FAB.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.NANO_FAB.REWARD,
		insetVoice = {
			"SpySociety/VoiceOver/Missions/MapScreen/Location_Nanofab",
			"SpySociety/VoiceOver/Missions/MapScreen/Location_Nanofab_2",
			},
		insetImg = "gui/menu pages/corp_select/New_mission_icons/10007.png",
		icon = "gui/mission_previews/nanofab_vestribule.png",
		objectives = createGeneralMissionObj( STRINGS.MISSIONS.ESCAPE.OBJ_NANO_FAB ),
		secondary_objectives = createGeneralSecondaryMissionObj(),
	},
	TERMINALS = {
		moreInfo = STRINGS.MISSIONS.LOCATIONS.TERMINALS.MORE_INFO,
		insetTitle =  STRINGS.MISSIONS.LOCATIONS.TERMINALS.INSET_TITLE,
		insetTxt = STRINGS.MISSIONS.LOCATIONS.TERMINALS.INSET_TXT,
        locationName = STRINGS.MISSIONS.LOCATIONS.TERMINALS.NAME,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.TERMINALS.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.TERMINALS.REWARD,
		insetVoice = {
			"SpySociety/VoiceOver/Missions/MapScreen/Location_ExecutiveTerminal",
			"SpySociety/VoiceOver/Missions/MapScreen/Location_ExecutiveTerminal_2",
		},
		first_insetvoice = "SpySociety/VoiceOver/Missions/MapScreen/Location_FirstMission",
		insetImg = "gui/menu pages/corp_select/New_mission_icons/10001.png",
		icon = "gui/mission_previews/executive_terminals.png",
		objectives = createGeneralMissionObj( STRINGS.MISSIONS.ESCAPE.OBJ_TERMINALS ),
		secondary_objectives = createGeneralSecondaryMissionObj(),
	},	
	DETENTION_CENTER = {
		moreInfo = STRINGS.MISSIONS.LOCATIONS.DETENTION_CENTER.MORE_INFO,
		insetTitle = STRINGS.MISSIONS.LOCATIONS.DETENTION_CENTER.INSET_TITLE,
		insetTxt = STRINGS.MISSIONS.LOCATIONS.DETENTION_CENTER.INSET_TXT,
        locationName = STRINGS.MISSIONS.LOCATIONS.DETENTION_CENTER.NAME,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.DETENTION_CENTER.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.DETENTION_CENTER.REWARD,
		insetVoice = {
			"SpySociety/VoiceOver/Missions/MapScreen/Location_DetentionCenter",
			"SpySociety/VoiceOver/Missions/MapScreen/Location_DetentionCenter_2",
		},
		insetImg = "gui/menu pages/corp_select/New_mission_icons/10005.png",
		icon = "gui/mission_previews/detention_center.png",
		objectives = createGeneralMissionObj( STRINGS.MISSIONS.ESCAPE.OBJ_DETENTION_CENTER ),
		secondary_objectives = createGeneralSecondaryMissionObj(),
	},	
	GUARD_OFFICE = {
		moreInfo = STRINGS.MISSIONS.LOCATIONS.GUARD_OFFICE.MORE_INFO,
		insetTitle = STRINGS.MISSIONS.LOCATIONS.GUARD_OFFICE.INSET_TITLE,
		insetTxt = STRINGS.MISSIONS.LOCATIONS.GUARD_OFFICE.INSET_TXT,
        locationName = STRINGS.MISSIONS.LOCATIONS.GUARD_OFFICE.NAME,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.GUARD_OFFICE.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.GUARD_OFFICE.REWARD,
		insetVoice = {
			"SpySociety/VoiceOver/Missions/MapScreen/Location_RegionalSecurityOffice",
			"SpySociety/VoiceOver/Missions/MapScreen/Location_RegionalSecurityOffice_2",
		},
		insetImg = "gui/menu pages/corp_select/New_mission_icons/terminal thing.png",
		icon = "gui/mission_previews/security_dispatch.png",
		objectives = createGeneralMissionObj( STRINGS.MISSIONS.ESCAPE.OBJ_GUARD_OFFICE ),
		secondary_objectives = createGeneralSecondaryMissionObj(),
	},	
	VAULT = {
		moreInfo = STRINGS.MISSIONS.LOCATIONS.VAULT.MORE_INFO,
		insetTitle = STRINGS.MISSIONS.LOCATIONS.VAULT.INSET_TITLE,
		insetTxt = STRINGS.MISSIONS.LOCATIONS.VAULT.INSET_TXT,
        locationName = STRINGS.MISSIONS.LOCATIONS.VAULT.NAME,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.VAULT.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.VAULT.REWARD,
		insetVoice = {
			"SpySociety/VoiceOver/Missions/MapScreen/Location_Vault",
			"SpySociety/VoiceOver/Missions/MapScreen/Location_Vault_2",
		},
		insetImg = "gui/menu pages/corp_select/New_mission_icons/10002.png",
		icon = "gui/mission_previews/vault.png",
		objectives = createGeneralMissionObj( STRINGS.MISSIONS.ESCAPE.OBJ_VAULT ),
		secondary_objectives = createGeneralSecondaryMissionObj(),
	},	

	CEO_OFFICE = {
		moreInfo = STRINGS.MISSIONS.LOCATIONS.CEO_OFFICE.MORE_INFO,
		insetTitle = STRINGS.MISSIONS.LOCATIONS.CEO_OFFICE.INSET_TITLE,
		insetTxt = STRINGS.MISSIONS.LOCATIONS.CEO_OFFICE.INSET_TXT,
        locationName = STRINGS.MISSIONS.LOCATIONS.CEO_OFFICE.NAME,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.CEO_OFFICE.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.CEO_OFFICE.REWARD,
		insetVoice = {
			"SpySociety/VoiceOver/Missions/MapScreen/Location_CEO",		
			"SpySociety/VoiceOver/Missions/MapScreen/Location_CEO_2",		
		},
		insetImg = "gui/menu pages/corp_select/New_mission_icons/10003.png",
		icon = "gui/mission_previews/chief_financial_suite.png",
		objectives = createGeneralMissionObj( STRINGS.MISSIONS.ESCAPE.OBJ_CEO_OFFICE ),
		secondary_objectives = createGeneralSecondaryMissionObj(),
	},	

	CYBERLAB = {
		moreInfo = STRINGS.MISSIONS.LOCATIONS.CYBERLAB.MORE_INFO,
		insetTitle = STRINGS.MISSIONS.LOCATIONS.CYBERLAB.INSET_TITLE,
		insetTxt = STRINGS.MISSIONS.LOCATIONS.CYBERLAB.INSET_TXT,
        locationName = STRINGS.MISSIONS.LOCATIONS.CYBERLAB.NAME,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.CYBERLAB.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.CYBERLAB.REWARD,
		insetVoice = {
			"SpySociety/VoiceOver/Missions/MapScreen/Location_Cyberlab",	
			"SpySociety/VoiceOver/Missions/MapScreen/Location_Cyberlab_2",
		},	
		insetImg = "gui/menu pages/corp_select/New_mission_icons/10009.png",
		icon = "gui/mission_previews/cybernetics_lab.png",
		objectives = createGeneralMissionObj( STRINGS.MISSIONS.ESCAPE.OBJ_CYBERLAB ),
		secondary_objectives = createGeneralSecondaryMissionObj(),
	},			

    FINALMISSION = {
    	moreInfo = STRINGS.MISSIONS.LOCATIONS.FINALMISSION.MORE_INFO,
        insetTitle = STRINGS.MISSIONS.LOCATIONS.FINALMISSION.INSET_TITLE,
        insetTxt = STRINGS.MISSIONS.LOCATIONS.FINALMISSION.INSET_TXT,
        locationName = STRINGS.MISSIONS.LOCATIONS.FINALMISSION.NAME,
        playerdescription = STRINGS.MISSIONS.LOCATIONS.FINALMISSION.DESCRIPTION,
        reward = STRINGS.MISSIONS.LOCATIONS.FINALMISSION.REWARD,
        insetVoice = {"SpySociety/VoiceOver/Central/Story/Day4/FinalMissionBrief_1"},  
        insetImg = "gui/menu pages/corp_select/New_mission_icons/final_mission.png",
        icon = "gui/mission_previews/final_omni_location.png",
        objectives = "> "..STRINGS.MISSIONS.ENDING_1.FIND_CONSOLE.."\n> "..STRINGS.MISSIONS.ENDING_1.BRING_CENTRAL.."\n> "..STRINGS.MISSIONS.ENDING_1.UPLOAD_INCOGNITA,
        secondary_objectives = STRINGS.MISSIONS.ENDING_1.ALIVE_OPTIONAL,
        tip = STRINGS.LOADING_TIP_FINAL,
    },
}

--------------------------------------------------------------------
-- Map locations: Indexed in campaign save game data.
-- DO NOT CHANGE ORDER OR REMOVE INDICES
-- To add a location: APPEND A NEW TABLE.
-- To remove a location: REMOVE ENTRIES FROM THE TABLE, DO NOT REMOVE THE TABLE.
local MAP_LOCATIONS = {
	{ x=-408, y=137, name=STRINGS.MAP_NAMES.ANCHORAGE, corpName="ftm" },
	{ x=-319, y=81, name=STRINGS.MAP_NAMES.VANCOUVER, corpName="ftm" },
	{ x=-308, y=30, name=STRINGS.MAP_NAMES.SAN_FRANCISCO, corpName="ftm" },
	{ x=-245, y=-28, name=STRINGS.MAP_NAMES.MEXICO_CITY, corpName="ftm" },
	{ x=-219, y=30, name=STRINGS.MAP_NAMES.KANSAS_CITY, corpName="ftm" },
	{ x=-210, y=75, name=STRINGS.MAP_NAMES.THUNDER_BAY, corpName="ftm" },
	{ x=-100, y=75, name=STRINGS.MAP_NAMES.ST_JOHNS, corpName="ftm" },
	{ x=-163, y=48, name=STRINGS.MAP_NAMES.NEW_YORK, corpName="ftm" },
	{ x=-202, y=31, name=STRINGS.MAP_NAMES.ATLANTA, corpName="ftm" },
	{ x=-189, y=-16, name=STRINGS.MAP_NAMES.HAVANA, corpName="ftm" },
	{ x=-161, y=-71, name=STRINGS.MAP_NAMES.BOGOTA, corpName="plastech" },
	{ x=-178, y=-122, name=STRINGS.MAP_NAMES.LIMA, corpName="plastech" },
	{ x=-178, y=-122, name=STRINGS.MAP_NAMES.LIMA, corpName="plastech" },
	{ x=-132, y=-144, name=STRINGS.MAP_NAMES.SANTA_CRUZ, corpName="plastech" },
	{ x=-79, y=-132, name=STRINGS.MAP_NAMES.BRASILIA, corpName="plastech" },
	{ x=-94, y=-186, name=STRINGS.MAP_NAMES.PORTO_ALEGRE, corpName="plastech" },
	{ x=-140, y=-206, name=STRINGS.MAP_NAMES.SANTA_ROSA, corpName="plastech" },
	{ x=-6, y=145, name=STRINGS.MAP_NAMES.REYKJAVIK, corpName="ko" },
	{ x=63, y=88, name=STRINGS.MAP_NAMES.LONDON, corpName="ko" },
	{ x=49, y=45, name=STRINGS.MAP_NAMES.MADRID, corpName="ko"  },
	{ x=118, y=118, name=STRINGS.MAP_NAMES.STOCKHOLM, corpName="ko"  },
	{ x=109, y=49, name=STRINGS.MAP_NAMES.ROME, corpName="ko"  },
	{ x=125, y=69, name=STRINGS.MAP_NAMES.BUDAPEST, corpName="ko"  },
	{ x=83, y=34, name=STRINGS.MAP_NAMES.ALGIERS, corpName="plastech" },
	{ x=37, y=16, name=STRINGS.MAP_NAMES.CASABLANCA, corpName="plastech"  },
	{ x=163, y=11, name=STRINGS.MAP_NAMES.CAIRO, corpName="plastech" },
	{ x=36, y=-66, name=STRINGS.MAP_NAMES.MONROVIA, corpName="plastech"  },
	{ x=128, y=-194, name=STRINGS.MAP_NAMES.CAPE_TOWN, corpName="plastech"  },
	{ x=213, y=-149, name=STRINGS.MAP_NAMES.ANTANANARIVO, corpName="plastech"  },
	{ x=190, y=-91, name=STRINGS.MAP_NAMES.MOMBASA, corpName="plastech"  },
	{ x=137, y=-142, name=STRINGS.MAP_NAMES.GABORONE, corpName="plastech"  },
	{ x=238, y=-10, name=STRINGS.MAP_NAMES.DUBAI, corpName="ko" },
	{ x=178, y=22, name=STRINGS.MAP_NAMES.BEIRUT, corpName="ko" },
	{ x=154, y=49, name=STRINGS.MAP_NAMES.ISTANBUL, corpName="ko" },
	{ x=182, y=103, name=STRINGS.MAP_NAMES.MOSCOW, corpName="ko" },
	{ x=276, y=12, name=STRINGS.MAP_NAMES.KABUL, corpName="sankaku" },
	{ x=343, y=-14, name=STRINGS.MAP_NAMES.DHAKA, corpName="sankaku" },
	{ x=307, y=-17, name=STRINGS.MAP_NAMES.NEW_DELHI, corpName="sankaku" },
	{ x=318, y=-67, name=STRINGS.MAP_NAMES.COLOMBO, corpName="sankaku" },
	{ x=386, y=-41, name=STRINGS.MAP_NAMES.BANGKOK, corpName="sankaku" },
	{ x=390, y=-81, name=STRINGS.MAP_NAMES.SINGAPORE, corpName="sankaku" },
	{ x=406, y=-109, name=STRINGS.MAP_NAMES.JAKARTA, corpName="sankaku" },
	{ x=444, y=-39, name=STRINGS.MAP_NAMES.MANILA, corpName="sankaku" },
	{ x=427, y=-182, name=STRINGS.MAP_NAMES.PERTH, corpName="ko" },
	{ x=536, y=-198, name=STRINGS.MAP_NAMES.SYDNEY, corpName="ko" },
	{ x=607, y=-228, name=STRINGS.MAP_NAMES.CHRISTCHURCH, corpName="sankaku" },
	{ x=537, y=-168, name=STRINGS.MAP_NAMES.BRISBANE, corpName="ko" },
	{ x=502, y=28, name=STRINGS.MAP_NAMES.TOKYO, corpName="sankaku" },
	{ x=463, y=33, name=STRINGS.MAP_NAMES.SEOUL, corpName="sankaku" },
	{ x=397, y=16, name=STRINGS.MAP_NAMES.CHENGDU, corpName="sankaku" },
	{ x=276, y=85, name=STRINGS.MAP_NAMES.ASTANA, corpName="sankaku" },
	{ x=422, y=-17, name=STRINGS.MAP_NAMES.HONG_KONG, corpName="sankaku" },
}

local BLOB_STYLES =
{
	FTM =
	{
		{
			size = 2,
			anims = { 'r3','p3' },
		},
		{
			size = 3,
			anims = { 'r4','p4' },
		},
		{
			size = 4,
			anims = { 'r5','p5' },
		},
		{
			size = 5,
			anims = { 'r5','p5' },
		},
	},
    KO =
	{
		{
			size = 2,
			anims = { 'g3','m3' },
		},
		{
			size = 3,
			anims = { 'g4','m4' },
		},
		{
			size = 4,
			anims = { 'g5','m5' },
		},
		{
			size = 5,
			anims = { 'g5','m5' },
		},
	},
    OMNI =
	{
		{
			size = 2,
			anims = { 'j3','y3' },
		},
		{
			size = 3,
			anims = { 'j4','y4' },
		},
		{
			size = 4,
			anims = { 'j5','y5' },
		},
		{
			size = 5,
			anims = { 'j5','y5' },
		},
	},
    SANKAKU =
	{
		{
			size = 2,
			anims = { 'c3','b3','p3' },
		},
		{
			size = 3,
			anims = { 'c4','b4','p4' },
		},
		{
			size = 4,
			anims = { 'c5','b5','p5' },
		},
		{
			size = 5,
			anims = { 'c5','b5','p5' },
		},
	},
    PLASTECH =
	{
		{
			size = 2,
			anims = { 'j3','y3' },
		},
		{
			size = 3,
			anims = { 'j4','y4' },
		},
		{
			size = 4,
			anims = { 'j5','y5' },
		},
		{
			size = 5,
			anims = { 'j5','y5' },
		},
	},
}

local HEAD_CORP_TEMPLATES = {
	ftm =
	{
        stringTable = STRINGS.CORP.FTM,
		shortname = "FTM", -- Not a UI string, used for debug and path concatenation purposes.
		logo = "gui/corp_preview/logo_sankaku.png",
		
        corpColor={ r=63/255,g=74/255,b=107/255 },
		imgs = {shop="gui/store/STORE_FTM_bg.png",logo="gui/menu pages/corp_select/CP_FTMLogo1.png",logoLarge = "gui/corps/logo_FTM.png"},
		music = "SpySociety/Music/music_FTM",
        region = "na",
        world = "ftm",		
		overlayBlobStyles = BLOB_STYLES.FTM,
	},

	omni = 
	{
        stringTable = STRINGS.CORP.OMNI,
		shortname = "OMNI", -- Not a UI string, used for debug and path concatenation purposes.
		logo = "gui/corp_preview/logo_sankaku.png",
		
		corpColor={r=148/255,g=12/255,b=12/255,a=1},	
		imgs = {shop="gui/store/STORE_Sankaku_bg.png",logo="gui/menu pages/corp_select/CP_SankakuLogo1.png",logoLarge = "gui/corps/logo_omni.png"},
		music = "SpySociety/Music/music_FinalLevel",
        region = "omni",
        world = "omni",
		overlayBlobStyles = BLOB_STYLES.OMNI,
	},	
	omni2 = 
	{
        stringTable = STRINGS.CORP.OMNI,
		shortname = "OMNI", -- Not a UI string, used for debug and path concatenation purposes.
		logo = "gui/corp_preview/logo_sankaku.png",
		
		corpColor={r=148/255,g=12/255,b=12/255,a=1},	
		imgs = {shop="gui/store/STORE_Sankaku_bg.png",logo="gui/menu pages/corp_select/CP_SankakuLogo1.png",logoLarge = "gui/corps/logo_omni.png"},
		music = "SpySociety/Music/music_FinalLevel",
        region = "omni",
        world = "omni2",
		overlayBlobStyles = BLOB_STYLES.OMNI,
	},		

	sankaku = 
	{
        stringTable = STRINGS.CORP.SANKAKU,
		shortname = "SANKAKU", -- Not a UI string, used for debug and path concatenation purposes.
		logo = "gui/corp_preview/logo_sankaku.png",
		
		corpColor={r=23/255,g=142/255,b=161/255,a=1},
		imgs = {shop="gui/store/STORE_Sankaku_bg.png",logo="gui/menu pages/corp_select/CP_SankakuLogo1.png",logoLarge = "gui/corps/logo_sankaku.png"},
		music = "SpySociety/Music/music_Sankaku",
        region = "asia",
        world = "sankaku",
		overlayBlobStyles = BLOB_STYLES.SANKAKU,
	},	

	ko = {
        stringTable = STRINGS.CORP.KO,
		shortname = "KO", -- Not a UI string, used for debug and path concatenation purposes.
		logo = "gui/corp_preview/logo_k&o.png",
			
		corpColor={r=120/255,g=40/255,b=40/255,a=1},
		imgs = {shop="gui/store/STORE_KO_bg.png",logo="gui/menu pages/corp_select/CP_KOLogo1.png",logoLarge = "gui/corps/logo_KandO.png"},
		music = "SpySociety/Music/music_KandO",
        region = "europe",
        world = "ko",
		overlayBlobStyles = BLOB_STYLES.KO,
	},	

	plastech = {
        stringTable = STRINGS.CORP.PLASTECH,
		shortname = "PLASTECH", -- Not a UI string, used for debug and path concatenation purposes.
		logo = "gui/corp_preview/logo_sankaku.png",

		corpColor={r=242/255,g=234/255,b=162/255,a=1},
		imgs = {shop="gui/store/STORE_Plastech_bg.png",logo="gui/menu pages/corp_select/CP_PlastechLogo1.png",logoLarge = "gui/corps/logo_plastech.png"},
		music = "SpySociety/Music/music_Plastek",
        region = "sa",
        world = "plastech",
		overlayBlobStyles = BLOB_STYLES.PLASTECH,
	}
}

------------------------------------------------------------------------------------------------------
--

local SITUATIONS_DEFAULT =
{
	tutorial =
	{
		levelFile = "lvl_tutorial",
        ui =
        {
            locationName = STRINGS.MISSIONS.LOCATIONS.TUTORIAL.NAME,
		    profileAnim = "portraits/stealth_guy_face",
    		strings = STRINGS.MISSIONS.JAILBREAK,
        },
		scripts = { "tutorial_script" },
        tags = { "tutorial" },
	},
    vault =
    {
        levelFile = "lvl_procgen",
        ui = GENERAL_MISSIONS.VAULT,
        strings = STRINGS.MISSIONS.ESCAPE,
        scripts = { "mission_vault" },
        tags = { "vault" },
    },
    server_farm =
    {
        levelFile = "lvl_procgen",
        ui = GENERAL_MISSIONS.SERVER_FARM,
        strings = STRINGS.MISSIONS.ESCAPE,
        scripts = { "mission_server_farm" },
        tags = { "server_farm" },
    },
    nanofab =
    {
        levelFile = "lvl_procgen",
        ui = GENERAL_MISSIONS.NANO_FAB,
        strings = STRINGS.MISSIONS.ESCAPE,
        scripts = { "mission_nanofab" },
        tags = { "nanofab" },
    },
    detention_centre =
    {
        levelFile = "lvl_procgen",
        ui = GENERAL_MISSIONS.DETENTION_CENTER,
        strings = STRINGS.MISSIONS.ESCAPE,
        scripts = { "mission_detention_centre" },
        tags = { "detention_centre" },
    },
    security =
    {
        levelFile = "lvl_procgen",
        ui = GENERAL_MISSIONS.GUARD_OFFICE,
        strings = STRINGS.MISSIONS.ESCAPE,
        scripts = { "mission_security" },
        tags = { "security" },
    },
    ceo_office =
    {
        levelFile = "lvl_procgen",
        ui = GENERAL_MISSIONS.CEO_OFFICE,
        strings = STRINGS.MISSIONS.ESCAPE,
        scripts = { "mission_ceo_office" },
        tags = { "ceo_office" },
    },
    cyberlab =
    {
        levelFile = "lvl_procgen",
        ui = GENERAL_MISSIONS.CYBERLAB,
        strings = STRINGS.MISSIONS.ESCAPE,
        scripts = { "mission_cyberlab" },
        tags = { "cyberlab" },
    },
    executive_terminals =
    {
        levelFile = "lvl_procgen",
        ui = GENERAL_MISSIONS.TERMINALS,
        strings = STRINGS.MISSIONS.ESCAPE,
        scripts = { "mission_executive_terminals" },
        tags = { "executive_terminals" },
    },
	ending_1 =
	{
        levelFile = "lvl_procgen",
        ui = GENERAL_MISSIONS.FINALMISSION,
		strings = STRINGS.MISSIONS.FINALMISSION,
		scripts = { "ending_1" },
		tags = { "ending_1"  },
		finalMission = true, 
	},
}

local SITUATIONS = {}

local ESCAPE_MISSION_TAGS = { "vault", "ceo_office", "security", "executive_terminals", "server_farm", "nanofab", "cyberlab", "detention_centre" }
local NO_CFO_MISSION_TAGS = { "vault", "security", "executive_terminals", "server_farm", "nanofab", "cyberlab", "detention_centre" }
local ALL_LOCATION_TAGS = { "ftm", "ko", "plastech", "sankaku" }

local DEFAULT_MISSION_TAGS = util.tmerge( { "2max" }, ALL_LOCATION_TAGS, ESCAPE_MISSION_TAGS ) -- All escape missions, all corps
local DEFAULT_MISSION_TAGS_FIRST = util.tmerge( { "2max" }, ALL_LOCATION_TAGS, NO_CFO_MISSION_TAGS ) -- All missions but CFO, all corps
local INITIAL_MISSION_TAGS = { "executive_terminals", "ftm", "ko", "plastech", "not_close" }

-------------------------------------------------------------------------------
-- Creates situation data for storage in the campaign data, based on the level index and seed.
local function countSituations( campaign, situationName )
    local count = 0
    for i = 1, #campaign.situations do
        if campaign.situations[i].name == situationName then
            count = count + 1
        end
    end
    return count
end

local function checkTags( situationTags, tags )
	local tagCount = 0
    -- Each situation tag must exist in 'tags' for it to be a valid choice.
	for i, tag in ipairs(situationTags) do
		if array.find( tags, tag ) then
			tagCount = tagCount + 1
		end
	end

    return tagCount == #situationTags
end

local function chooseSituation( campaign, tags, gen )
    local MAX_DUPLICATE_SITUATION = math.huge
    if array.find( tags, "2max" ) then
        MAX_DUPLICATE_SITUATION = 2
    end

	local situationNames = util.weighted_list()
	for name, situationData in pairs( SITUATIONS ) do
		if checkTags( situationData.tags, tags ) and countSituations( campaign, name ) < MAX_DUPLICATE_SITUATION then
            situationNames:addChoice( name, situationData.weight or 1 )
		end
	end

	-- Pick a random situation.
	if situationNames:getTotalWeight() > 0 then
	    local wt = gen:nextInt( 1, situationNames:getTotalWeight())
	    return situationNames:getChoice( wt )
    end
end


-- fromLocation, toLocation are both actual table entries of MAP_LOCATIONS, or indices therein.
local function calculateTravelTime( fromLocation, toLocation )
	if not toLocation then 
		return 	0
	end
    if type(fromLocation) == "number" then
        fromLocation = MAP_LOCATIONS[ fromLocation ]
    end
    if type(toLocation) == "number" then
        toLocation = MAP_LOCATIONS[ toLocation ]
    end
	local TRAVEL_UNIT = 40
	local WORLD_WIDTH = 1170 -- based on the widget size
	local TRAVEL_CEILING = 9 
	local x0, y0 = fromLocation.x, fromLocation.y
	local x1, y1 = toLocation.x, toLocation.y
	-- TODO: this distance should take into account a spherical Earth.  Boy we're old school here.
	local dist = math.min( mathutil.dist2d( x0, y0, x1, y1 ), mathutil.dist2d( x0 + WORLD_WIDTH, y0, x1, y1 ), mathutil.dist2d( x0, y0, x1 + WORLD_WIDTH, y1 ))
	local hours = math.ceil(dist/TRAVEL_UNIT)
	hours = math.min( TRAVEL_CEILING, hours )
	return hours
end

local function calculateCurrentHours(campaign)

	--calculate the current hours including the current mission
	if campaign.location and campaign.situation then
		situationTime = 0
		if campaign.situation.mapLocation then
			situationTime = calculateTravelTime( campaign.location, campaign.situation.mapLocation ) + BASE_TRAVEL_TIME
		end
		return campaign.hours + situationTime
	else
		return campaign.hours
	end
end

local function defaultMapSelector( campaign, tags, tempLocation )
    if array.find( tags, tempLocation.corpName ) == nil then
        return false -- Not allowed corp.
    end

	local MIN_TRAVEL = 1
    if array.find( tags, "not_close" ) then
        MIN_TRAVEL = 6
    end

	local safeDist = true
	local dist = calculateTravelTime( MAP_LOCATIONS[ campaign.location ], tempLocation )
	if dist <= MIN_TRAVEL then
		safeDist = false
	end

	for i,situation in ipairs( campaign.situations ) do
		local travelTime = calculateTravelTime( MAP_LOCATIONS[ situation.mapLocation ], tempLocation )
		if travelTime <= MIN_TRAVEL then
		 	safeDist = false
		 	break
		end
	end

    return safeDist
end

local function getCorpData( situation )
    if situation.corpName then
        -- situation can override corp data.
        return HEAD_CORP_TEMPLATES[ situation.corpName ]
    end

    if situation.mapLocation == nil then
    	if situation.corpData then 
    		return HEAD_CORP_TEMPLATES[situation.corpData]
    	else
        	return HEAD_CORP_TEMPLATES.omni
    	end
    else
        local mapLocation = MAP_LOCATIONS[ situation.mapLocation ]
        assert( mapLocation ) -- Situation must be located somewhere in the world!
        assert( mapLocation.corpName )
        return HEAD_CORP_TEMPLATES[ mapLocation.corpName ]
    end
end

local function getDifficulty( campaign, gen )
    local MAX_DIFFICULTY = 10
    local difficulty = 1 + math.floor( campaign.hours / 24)
    if campaign.campaignDifficulty == simdefs.NORMAL_DIFFICULTY and campaign.hours < 24 then
        -- No chance for increased difficulty on beginner: day 1
    else
	    if gen:nextInt( 1, 10 ) <= 3 then
            difficulty = difficulty + 1
        end
    end
    return math.min( MAX_DIFFICULTY, difficulty )
end

local function createNewSituation(campaign, gen, tags, difficulty )
    assert( tags and #tags > 0 )

    -------------------------------------
    -- Choose from serverdefs.SITUATIONS.
	local situationName = chooseSituation( campaign, tags, gen )
    if situationName == nil then
		log:write( "No situations found for: hour %d, %s", campaign.hours, util.stringize(tags) )
        return nil
    end

    -------------------------------------
	-- Determine difficulty from hours into the campaign.
    difficulty = difficulty or getDifficulty( campaign, gen )

    -------------------------------------
    -- Determine map location (which in turn implies CORP)
    local situationData = SITUATIONS[ situationName ]
    local mapLocation = nil
    local availableLocations = {}
    for i, location in ipairs( MAP_LOCATIONS) do
        assert( location.name )
        if defaultMapSelector( campaign, tags, location ) then
            table.insert( availableLocations, i )
        end
    end
    if #availableLocations > 0 then
        mapLocation = availableLocations[ gen:nextInt(1,#availableLocations) ]
    end
    
    if mapLocation then
        log:write( "NEW SITUATION{ %s } -- %s, %d, %s", util.stringize(tags), situationName, difficulty, MAP_LOCATIONS[ mapLocation ].name )
	    return { name = situationName, difficulty = difficulty, mapLocation = mapLocation, new = true }
    else
        log:write( "\tCould not find map location: %s", util.stringize( tags ) )
    end
end

-------------------------------------------------------------------------------
-- Assigns an agent from the potential list to the actual roster.

local function createAgent( templateName, upgrades )
    local unitDef = agentdefs[ templateName ]
    local agent = 
    {
	    id = unitDef.agentID,
	    template = templateName,
	    upgrades = upgrades or {},
    }
    assert( agent.id and agent.template )
    return agent
end

local function assignAgent( agency, agentDef )
	--Remove all potentials with the same ID.
    for i = #agency.unitDefsPotential, 1, -1 do
        local def2 = agency.unitDefsPotential[ i ]
        if def2.id == agentDef.id then
			table.remove( agency.unitDefsPotential, i )
		end
	end
    assert( array.find( agency.unitDefs, agentDef ) == nil )
    table.insert( agency.unitDefs, agentDef )
end

local function createCustomFinalSituation( campaign, customFinalSituation )
	assert(customFinalSituation)
	local rand = include( "modules/rand" )
	local gen = rand.createGenerator( campaign.seed )
	local returnSituations = {}
	local situation = {}

	situation = createNewSituation( campaign, gen, util.tmerge( { customFinalSituation.name }, ALL_LOCATION_TAGS ), 2 + math.floor( campaign.hours / 24)  )
	if customFinalSituation.corp then
		situation.corpName = customFinalSituation.corp
	end

	table.insert(returnSituations, situation )
	return returnSituations
end

local function createFinalSituations( campaign )
	local rand = include( "modules/rand" )
	local gen = rand.createGenerator( campaign.seed )
	local returnSituations = {}

	local difficulty = math.max(2 + math.floor( campaign.hours / 24),5)

    local situation = createNewSituation( campaign, gen, util.tmerge( { "ending_1" }, ALL_LOCATION_TAGS ), difficulty )
    situation.corpName = "omni"
	table.insert(returnSituations, situation )

	return returnSituations
end

local function createCampaignSituations( campaign, count, tags, difficulty )
	local rand = include( "modules/rand" )
	local gen = rand.createGenerator( campaign.seed )

	for i = 1, count do
        local situationTags = nil 
        if campaign.missionCount == 0 and campaign.campaignDifficulty == simdefs.NORMAL_DIFFICULTY then 
        	situationTags = tags or DEFAULT_MISSION_TAGS_FIRST
        else 
        	situationTags = tags or DEFAULT_MISSION_TAGS
        end 
		local situation = createNewSituation( campaign, gen, situationTags, difficulty )
		if situation then
			table.insert( campaign.situations, situation )
			campaign.missionTotal = campaign.missionTotal + 1

        else
            log:write( "Found no mission with tags '%s'", util.stringize(situationTags) )
		end
	end

    campaign.seed = gen._seed
end

local function advanceCampaignTime( campaign, hours )
	local NUM_MISSIONS_TO_SPAWN = 4
	local HOURS_BEFORE_SPAWN = 24
	local ENDLESS_ALERT_DAYS = 4 -- number of days between endless alerts (0-based)

	if campaign.hours >= campaign.difficultyOptions.maxHours then
	    return -- No more advancement!
	end

	local adjustmentHours = hours

    campaign.previousDay, campaign.currentDay = math.floor(campaign.hours / HOURS_BEFORE_SPAWN), math.floor((campaign.hours + adjustmentHours) / HOURS_BEFORE_SPAWN)
	campaign.hours = campaign.hours + adjustmentHours
	campaign.seed = campaign.seed + 1
	campaign.lastEndlessAlert = false

    -- Determine if a new day has dawned: if so, add new situations.
    if campaign.hours >= campaign.difficultyOptions.maxHours then
        -- If if it's not a new day, but we've exceeded total hours... start the final leg.

        local customFinalSituation = nil
        if campaign.campaignEvents then
	        for i,event in ipairs( campaign.campaignEvents ) do
	        	if event.eventType == simdefs.CAMPAIGN_EVENTS.CUSTOM_FINAL then
	        		customFinalSituation = event.data
	        		print("Removing campaign event",i,"CUSTOM_FINAL")
	        		table.remove(campaign.campaignEvents,i)

	        		local eventNew = {
				        eventType = simdefs.CAMPAIGN_EVENTS.CUSTOM_SCRIPT,
				        data = event.data.name,    
	        		}
					table.insert(campaign.campaignEvents,eventNew)
   					
   					break
	        	end	       
	        end
    	end
        if customFinalSituation then
	        campaign.situations = createCustomFinalSituation( campaign,  customFinalSituation )
    	else
			campaign.situations = createFinalSituations( campaign )
		end

	elseif campaign.currentDay > campaign.previousDay then
		
		if campaign.customScriptIndex then
			if campaign.customScriptIndexDay then
				campaign.customScriptIndexDay = campaign.customScriptIndexDay +1
			else
				campaign.customScriptIndexDay = 1
			end				
		end

		campaign.missionsPlayedThisDay = 0
		
        local MAX_DIFFICULTY = (campaign.difficultyOptions.maxHours == math.huge and 10 or 4)
		for i,situation in ipairs(campaign.situations) do
            situation.difficulty = math.min( MAX_DIFFICULTY, situation.difficulty + 1 )
		end 

        if campaign.campaignDifficulty == simdefs.NORMAL_DIFFICULTY and campaign.currentDay == 1 then
            -- Day 2 beginner: only difficulty 2.
    		createCampaignSituations( campaign, NUM_MISSIONS_TO_SPAWN, nil, 2 )	
        else
    		createCampaignSituations( campaign, NUM_MISSIONS_TO_SPAWN )	
        end

		if campaign.difficultyOptions.maxHours == math.huge and campaign.currentDay >= ENDLESS_ALERT_DAYS then 
			campaign.endlessAlert = true 
		end
    end

	--If no situations left, "monst3r inject"
	if #campaign.situations <= 0 then
        createCampaignSituations( campaign, 2 )
        campaign.monst3rInject = true
	else
        campaign.monst3rInject = false
    end
end

local function updateStats( agency, sim )
	local player = sim:getPC()

	-- Transfer cash
	agency.cash =  player:getCredits()

	--Transfer cpus 
	agency.cpus =  player:getCpus()
	
	local stats = sim:getStats()

	if not agency.missions_completed then
		agency.security_hacked = 0
		agency.guards_kod = 0
		agency.safes_looted = 0
		agency.credits_earned = 0 
		agency.programs_earned = 0 
		agency.items_earned = 0 
		agency.missions_completed = 0 
		agency.missions_completed_1 = 0
		agency.missions_completed_2 = 0
		agency.missions_completed_3 = 0
	end 

	agency.security_hacked = agency.security_hacked + (stats['security_hacked'] or 0)
	agency.guards_kod = agency.guards_kod + (stats['guards_kod'] or 0)
	agency.safes_looted = agency.safes_looted + (stats['safes_looted'] or 0)
	agency.credits_earned = agency.credits_earned + (stats['credits_gained'] or 0)
	agency.programs_earned = agency.programs_earned + (stats['programs_earned'] or 0)
	agency.items_earned = agency.items_earned + (stats['items_earned'] or 0)
	agency.missions_completed = sim:getParams().missionCount
	agency.missions_completed_1 = agency.missions_completed_1 + (stats['missions_completed_1'] or 0)
	agency.missions_completed_2 = agency.missions_completed_2 + (stats['missions_completed_2'] or 0)
	agency.missions_completed_3 = agency.missions_completed_3 + (stats['missions_completed_3'] or 0)
end

local function updateCompatibility( campaign )
    local version = include( "modules/version" )
    while version.isIncompatible( campaign.version ) do
        log:write( "UPDATING CAMPAIGN: v%s", tostring( campaign.version ))
        local major, minor, build = version.parseVersion( campaign.version )
        local updateFile = string.format( "%s/modules/updates/%d.%d.0.lua", config.SRC_MEDIA, major, minor )
	    local res, fn = pcall( dofile, updateFile )
        if not res then
            log:write( "Could not find update file: '%s'", updateFile )
            break

        else
            local newVersion = fn( campaign )
            if newVersion and newVersion ~= campaign.version then
                campaign.version = newVersion
                if campaign.sim_history then
                    log:write( "\tSUCCESS: v%s [cleared sim_history]", tostring( campaign.version ))
                    campaign.sim_history, campaign.wasUpdated = nil, true
                else
                    log:write( "\tSUCCESS: v%s", tostring( campaign.version ))
                end
            else
                log:write( "\tFAILED" )
            end
        end
    end

    -- Do a pass of updating difficulty options, so we don't have to ++version everytime we add a setting.
    if campaign.version == version.VERSION then
        campaign.previousDay = campaign.previousDay or (math.floor(campaign.hours / 24))
        campaign.currentDay = campaign.currentDay or (math.floor(campaign.hours / 24))
        campaign.missionsPlayedThisDay = campaign.missionsPlayedThisDay or 0
        campaign.miniserversSeen = campaign.miniserversSeen or 0
        -- Base missing settings off normal difficulty.  Eh.
        for setting, value in pairs( simdefs.DIFFICULTY_OPTIONS[ simdefs.NORMAL_DIFFICULTY ] ) do
            if campaign.difficultyOptions[ setting ] == nil then
                campaign.difficultyOptions[ setting ] = value
                log:write( "\tAssigning difficulty option: %s = %s", tostring(setting), tostring(value) )
            end
        end
    end

    -- TODO: remove me.  fail safe for bugs causing 0 missions.
    if #campaign.situations == 0 and campaign.situation == nil then
        createCampaignSituations( campaign, 1 )
    end
end


local function CalculateNetWorth( campaign )
	local unitdefs = include("sim/unitdefs")
	local abilitydefs = include( "sim/abilitydefs" )
	
	local total = 0

	--cash
	total = total +	campaign.agency.cash
	--print ("\tcash", campaign.agency.cash)

	--programs
	for _, abilityID in pairs(campaign.agency.abilities) do
		local ability = abilitydefs.lookupAbility( abilityID )
		total = total + ( ability.value or 0 )
		--print ("\tprogram", ability.value)
	end

	--the stash
	if campaign.agency.upgrades then
		for _, item in pairs(campaign.agency.upgrades) do
			local itemDef
		    if type(item) == "string" then
		        itemDef = unitdefs.lookupTemplate( item )
		    else
		        itemDef = unitdefs.lookupTemplate( item.upgradeName )
		    end

	        if itemDef then
			    total = total + ( itemDef.value or 0 )
			    --print ("\tstash item", itemDef.value)
	        end
	    end
	end


	--stuff on agents
	for _, agentDef in pairs(campaign.agency.unitDefs) do
		--print ("**** agent")

		--upgrade levels
		if agentDef.skills then
			for _, skill in pairs(agentDef.skills) do
				local skillDef = skilldefs.lookupSkill( skill.skillID )
				for k = 1, skill.level do
					total = total + ( skillDef[k].cost or 0 )
					--print ("\tupgrade", skillDef[k].cost)
				end
			end
		else
			--agents that haven't gone through a mission yet don't have a skill table, so we have to look at the template values.
			local template = agentdefs[agentDef.template]
			for skillname, level in pairs(template.startingSkills) do
				local skillDef = skilldefs.lookupSkill( skillname )
				for k = 1, level do
					total = total + ( skillDef[k].cost or 0 )
					--print ("\tupgrade", skillDef[k].cost)
				end
				
			end

		end

		--augments and inventory
		for _,item in pairs(agentDef.upgrades) do
			local itemDef
		    if type(item) == "string" then
		        itemDef = unitdefs.lookupTemplate( item )
		    else
		        itemDef = unitdefs.lookupTemplate( item.upgradeName )
		    end

	        if itemDef then
			    total = total + (itemDef.value or 0)
			    --print ("\titem", itemDef.value)
	        end
		end		

	end


	return total
end


local function isTimeAttackMode( campaign )
	return campaign.difficultyOptions.timeAttack and campaign.difficultyOptions.timeAttack > 0
end

local function isFinalMission( campaign )
    return campaign.hours >= campaign.difficultyOptions.maxHours and #campaign.situations == 0
end

local function createNewCampaign( agency, campaignDifficulty, difficultyOptions )
	local version = include( "modules/version" )
	local campaign =
	{
		agency = agency,
		location = agency.startLocation,
		play_t = 0,
		hours = 0,
        previousDay = -1,
        currentDay = 0,
	    version = version.VERSION,
		situations = {},
		missionCount = 0,
		missionTotal = 0,
        miniserversSeen = 0,
		missionsPlayedThisDay = 0,
		recent_build_number = util.formatGameInfo(),
		save_time = os.time(),
		creation_time = os.time(),
		missionEvents = {},
	}

	campaign.seed = config.LOCALSEED()

	if not difficultyOptions then
        -- Initializes the campaign situation to the tutorial level.
        campaign.campaignDifficulty = simdefs.TUTORIAL_DIFFICULTY
        campaign.difficultyOptions = util.tcopy( simdefs.DIFFICULTY_OPTIONS[ simdefs.TUTORIAL_DIFFICULTY ])
		campaign.situation = { name = TUTORIAL_SITUATION, difficulty = 1, mapLocation = 2 } -- Starts in FTM (Vancouver)
        campaign.missionVersion = version.VERSION
    else
        -- Standard campaign startup.
        campaign.campaignDifficulty = campaignDifficulty
        campaign.difficultyOptions = util.tcopy( difficultyOptions )
        campaign.agency.cash = difficultyOptions.startingCredits
        campaign.agency.cpus = difficultyOptions.startingPower

        createCampaignSituations( campaign, 1, INITIAL_MISSION_TAGS, 1 )
	end

	campaign.campaignEvents = mod_manager:getCampaignEvents()

	return campaign
end

-------------------------------------------------------------------------------
-- Creates a default agency (constructed for new campaigns)
--


-- These are potential rescueable units. DONT ADD ANYTHING THAT ISN'T RESCUEABLE.
-- and give them ONLY WHAT WILL BE AVAILABLE TO RESCUED UNITS.	
local DEFAULT_UNITDEFS_POTENTIAL = {
	createAgent( "stealth_1", { "augment_deckard" } ),
	createAgent( "engineer_2", { "augment_international_v1" } ),
	createAgent( "sharpshooter_1", { "augment_shalem" } ),
	createAgent( "stealth_2", { "augment_banks" } ),
	createAgent( "sharpshooter_2", { "augment_nika" } ),
	createAgent( "engineer_1", { "augment_tony" } ),
	createAgent( "disguise_1", { "augment_prism_2" } ),
	createAgent( "cyborg_1", { "augment_sharp_1" } ),	
}

local TEMPLATE_AGENCY =
{
	name = "",
	nextID = 100,
	unitDefs = {},
	unitDefsPotential = util.tcopy(DEFAULT_UNITDEFS_POTENTIAL),
	cash = 500,
	cpus = 10, 
	blocker = false, 
}

local function createTutorialAgency()
	local agency = util.extend(TEMPLATE_AGENCY)
	{
		name = "Tutorial Agency",
		abilities = { "lockpick_1" },
		startLocation = 23,
		cpus = 0, 
		unitDefsPotential =
		{
		},		
		cash = 350,
	}

    assignAgent( agency, createAgent( "tutorial" ))

	return agency
end

local function createAgency( agentIDs, programIDs )
    agentIDs = agentIDs or { "stealth_1", "engineer_2" }
    programIDs = programIDs or { "remoteprocessor", "lockpick_1" }

	local agency = util.extend(TEMPLATE_AGENCY)
	{
		id = 1,
		abilities = programIDs,
		alwaysUnlocked = true, 
		startLocation = 23,
	}

	for k,v in ipairs(agentIDs) do
		assignAgent( agency, createAgent( v, util.tcopy( agentdefs[v].upgrades )))
	end

	return agency
end

local function findAgent( agency, agentID )
	local pred = function( agentDef ) return agentDef.id == agentID end
	return array.findIf( agency.unitDefs, pred )
end

local DEFAULT_SELECTABLE_AGENTS = 
{
	"stealth_1",
	"engineer_2",
	"sharpshooter_1",
	"stealth_2",
	"engineer_1",
	"sharpshooter_2",
	"cyborg_1",
	"disguise_1",
	"central_pc",
	"monst3r_pc",
}

local SELECTABLE_AGENTS = {}

function ResetSelectableAgents()
	log:write("ResetSelectableAgents()")
	util.tclear(SELECTABLE_AGENTS)
	util.tmerge(SELECTABLE_AGENTS, DEFAULT_SELECTABLE_AGENTS)
end

local DEFAULT_SELECTABLE_PROGRAMS = 
{
    [1] = -- Power generators
    {
    	"remoteprocessor",
    	"fusion",
    	"seed",
    	"faust",
    	"dynamo",    
    },
    [2] = -- Breakers
    {
    	"lockpick_1",
    	"parasite",
    	"rapier",
    	"brimstone",
    	"mercenary",    	
    },
}

local SELECTABLE_PROGRAMS = {}

function ResetSelectablePrograms()
	log:write("ResetSelectablePrograms()")
	util.tclear(SELECTABLE_PROGRAMS)
	for k,v in pairs( DEFAULT_SELECTABLE_PROGRAMS ) do
		SELECTABLE_PROGRAMS[k] = util.tdupe(v)
	end
end

local DEFAULT_LOADOUTS = 
{
	stealth_1 = {"stealth_1", "stealth_1_a"},
	engineer_2 = {"engineer_2", "engineer_2_a"}, 
	sharpshooter_1 = {"sharpshooter_1","sharpshooter_1_a"},
	stealth_2 = {"stealth_2","stealth_2_a"},   
	engineer_1 = {"engineer_1","engineer_1_a"}, 
	sharpshooter_2 = {"sharpshooter_2","sharpshooter_2_a"},    
	cyborg_1 = {"cyborg_1","cyborg_1_a"}, 
	disguise_1 = {"disguise_1","disguise_1_a"},
	monst3r_pc = {"monst3r_pc"},    
	central_pc = {"central_pc"}    
}

local LOADOUTS = {}

function ResetAgentLoadouts()
	log:write("ResetAgentLoadouts()")
	util.tclear(LOADOUTS)
	util.tmerge(LOADOUTS, DEFAULT_LOADOUTS)
end


local DEFAULT_ENDLESS_DAEMONS = 
{
	"alertBruteForce", 
	"alertModulate", 
	"alertDuplicator",
	"alertPulse",
}
local ENDLESS_DAEMONS = {}

local DEFAULT_PROGRAM_LIST = 
{
	"fortify", 
	"bruteForce", 
	"duplicator",
	"incognitaKiller",
	"validate",
	"siphon",
	"agent_sapper",
 	"modulate",
    "authority",
    "damonHider",
    "creditTaker",
}
local PROGRAM_LIST = {}

local DEFAULT_OMNI_PROGRAM_LIST_EASY = 
{
	"fortify", 
	"bruteForce", 
	"duplicator",
	"incognitaKiller",
	--"validate",
	"siphon",
	"agent_sapper",
 	"modulate",
    --"authority",
    --"damonHider",
    --"creditTaker",
}
local OMNI_PROGRAM_LIST_EASY = {}

local DEFAULT_OMNI_PROGRAM_LIST = 
{
	"fortify", 
	"bruteForce", 
	"duplicator",
	"incognitaKiller",
	"validate",
	"siphon",
	"agent_sapper",
 	"modulate",
    --"authority",
    --"damonHider",
    --"creditTaker",
}
local OMNI_PROGRAM_LIST = {}

local DEFAULT_REVERSE_DAEMONS =
{
	"order",
	"attune",
	"energize",
}

local REVERSE_DAEMONS = {}

function ResetDaemonAbilities()
	log:write("ResetDaemonAbilities()")

	util.tclear(ENDLESS_DAEMONS)
	util.tmerge(ENDLESS_DAEMONS, DEFAULT_ENDLESS_DAEMONS)

	util.tclear(PROGRAM_LIST)
	util.tmerge(PROGRAM_LIST, DEFAULT_PROGRAM_LIST)

	util.tclear(OMNI_PROGRAM_LIST_EASY)
	util.tmerge(OMNI_PROGRAM_LIST_EASY, DEFAULT_OMNI_PROGRAM_LIST_EASY)

	util.tclear(OMNI_PROGRAM_LIST)
	util.tmerge(OMNI_PROGRAM_LIST, DEFAULT_OMNI_PROGRAM_LIST)

	util.tclear(REVERSE_DAEMONS)
	util.tmerge(REVERSE_DAEMONS, DEFAULT_REVERSE_DAEMONS)

end

function ResetUnitDefsPotential()
	log:write("ResetUnitDefsPotential()")
	util.tclear(TEMPLATE_AGENCY.unitDefsPotential)
	util.tmerge(TEMPLATE_AGENCY.unitDefsPotential, DEFAULT_UNITDEFS_POTENTIAL)
end

function ResetSituations()
	log:write("ResetSituations()")
	util.tclear(SITUATIONS)
	util.tmerge(SITUATIONS, SITUATIONS_DEFAULT)
end

--
local GAME_MODE_STRINGS =
{
    [ simdefs.CUSTOM_DIFFICULTY ] = STRINGS.UI.CUSTOM_DIFFICULTY,
    [ simdefs.TUTORIAL_DIFFICULTY ] = STRINGS.UI.TUTORIAL_DIFFICULTY,
    [ simdefs.NORMAL_DIFFICULTY ] = STRINGS.UI.NORMAL_DIFFICULTY,
    [ simdefs.EXPERIENCED_DIFFICULTY ] = STRINGS.UI.EXPERIENCED_DIFFICULTY,
    [ simdefs.HARD_DIFFICULTY ] = STRINGS.UI.HARD_DIFFICULTY,
    [ simdefs.VERY_HARD_DIFFICULTY ] = STRINGS.UI.VERY_HARD_DIFFICULTY,
    [ simdefs.ENDLESS_DIFFICULTY ] = STRINGS.UI.ENDLESS_DIFFICULTY,
    [ simdefs.ENDLESS_PLUS_DIFFICULTY ] = STRINGS.UI.ENDLESS_PLUS_DIFFICULTY,
    [ simdefs.TIME_ATTACK_DIFFICULTY ] = STRINGS.UI.TIME_ATTACK_DIFFICULTY,
}

ResetSelectablePrograms()
ResetSelectableAgents()
ResetAgentLoadouts()
ResetDaemonAbilities()
ResetUnitDefsPotential()
ResetSituations()

worldPrefabts = {}

local function addWorldPrefabts(world,prefabt)
	worldPrefabts[world] = prefabt
end

return
{

	TEMPLATE_AGENCY = TEMPLATE_AGENCY,
	BASE_TRAVEL_TIME =BASE_TRAVEL_TIME,

    CORP_DATA = HEAD_CORP_TEMPLATES,
    CORP_NAMES = ALL_LOCATION_TAGS, -- Same as keys from CORP_DATA, but minus OMNI.

	MAP_LOCATIONS = MAP_LOCATIONS,

	TUTORIAL_SITUATION = TUTORIAL_SITUATION,
	SITUATIONS = SITUATIONS,
    ESCAPE_MISSION_TAGS = ESCAPE_MISSION_TAGS,

    -- Mission management
    createGeneralMissionObj = createGeneralMissionObj,
    createGeneralSecondaryMissionObj = createGeneralSecondaryMissionObj,

	-- Campaign management	
	createNewCampaign = createNewCampaign,
	createCampaignSituations = createCampaignSituations,
    getCorpData = getCorpData,
	advanceCampaignTime = advanceCampaignTime,
	calculateTravelTime = calculateTravelTime,
	calculateCurrentHours = calculateCurrentHours,
	isFinalMission = isFinalMission,
	isTimeAttackMode = isTimeAttackMode,
	updateStats = updateStats,
    updateCompatibility = updateCompatibility,
    CalculateNetWorth = CalculateNetWorth,

	-- Agency management.
	findAgent = findAgent,
	assignAgent = assignAgent,
    createAgent = createAgent,

	createAgency = createAgency,
    createTutorialAgency = createTutorialAgency,
	SELECTABLE_AGENTS = SELECTABLE_AGENTS,
	SELECTABLE_PROGRAMS = SELECTABLE_PROGRAMS,
	LOADOUTS = LOADOUTS,
	ENDLESS_DAEMONS = ENDLESS_DAEMONS, 
	PROGRAM_LIST = PROGRAM_LIST, 
	OMNI_PROGRAM_LIST = OMNI_PROGRAM_LIST,
	OMNI_PROGRAM_LIST_EASY = OMNI_PROGRAM_LIST_EASY,
	REVERSE_DAEMONS = REVERSE_DAEMONS,
	GAME_MODE_STRINGS = GAME_MODE_STRINGS,

	--world prefab management
	worldPrefabts = worldPrefabts,
	addWorldPrefabts = addWorldPrefabts,
}



