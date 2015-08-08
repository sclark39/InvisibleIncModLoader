local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local commondefs = include("sim/unitdefs/commondefs")
local tool_templates = include("sim/unitdefs/itemdefs")

-------------------------------------------------------------
--


local MAINFRAME_TRAITS = commondefs.MAINFRAME_TRAITS
local SAFE_TRAITS = commondefs.SAFE_TRAITS
local onMainframeTooltip = commondefs.onMainframeTooltip
local onSoundBugTooltip = commondefs.onSoundBugTooltip
local onBeamTooltip = commondefs.onBeamTooltip
local onConsoleTooltip = commondefs.onConsoleTooltip
local onStoreTooltip = commondefs.onStoreTooltip
local onDeviceTooltip = commondefs.onDeviceTooltip
local onSafeTooltip = commondefs.onSafeTooltip 

local prop_templates_default =
{

	-----------------------------------------------------
	-- Level Props

	laser_beam =
	{
		type = "laserbeam",
		name = STRINGS.PROPS.LASER_BEAM,
		kanim = "kanim_laser_2",
		facing = simdefs.DIR_N,
		traits = { dynamicImpass = true, noghost = true, damage = 3 , toolTipNote = STRINGS.PROPS.LASER_BEAM_TOOLTIP, mainframe_icon = true, redSymbols={"red","innerbeam","line","lines_new"},tealSymbols={"teal", "innerbeam_teal","lines_new_teal", "line"}},	
		onWorldTooltip = onBeamTooltip,
		rig = "beamrig",
	},
	
	infrared_beam =
	{
		type = "laserbeam",
		name = STRINGS.PROPS.INFRARED_BEAM,
		kanim = "kanim_infrared_beam_2",
		facing = simdefs.DIR_N,
		traits = { isAlarm = true, noghost = true, toolTipNote =STRINGS.PROPS.INFRARED_BEAM_TOOLTIP, mainframe_icon = true, redSymbols={"red","innerbeam","line","lines_new"},tealSymbols={"teal", "innerbeam_teal","lines_new_teal", "line"}},
		onWorldTooltip = onBeamTooltip,
		rig = "beamrig",		
	},

	infrared_wall =
	{
		type = "laserbeam",
		name = STRINGS.PROPS.INFRARED_WALL, 
		kanim = "kanim_infrared_wall_2",
		facing = simdefs.DIR_N,
		traits = { tripsDaemon = true, noghost = true, toolTipNote =STRINGS.PROPS.INFRARED_WALL_TOOLTIP, mainframe_icon = true, redSymbols={"red","wallbeam_red","wallBeamSymbol_red","lines_new"},tealSymbols={"teal","wallbeam","wallBeamSymbol","lines_new_teal"}},
		onWorldTooltip = onBeamTooltip,
		rig = "beamrig",		
	},
	
	item_corpdata =
	{
		type = "simunit",
		name =  STRINGS.PROPS.SITE_PLANS,
        onWorldTooltip = commondefs.onItemWorldTooltip,
        onTooltip = commondefs.onItemTooltip,	
		icon = "itemrigs/FloorProp_DataDisc.png",		
		profile_icon =     "gui/icons/item_icons/items_icon_small/icon-item_location_map_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_location_map.png",
		desc = STRINGS.PROPS.SITE_PLANS_DESC,
		traits = { showOnce = "corp_map" },
        tags = { "corp_map" },
		abilities = { "carryable" },
	},	
	
	item_corpdata_extra =
	{
		type = "simunit",
		name =  STRINGS.PROPS.SITE_LOCATION,
        onWorldTooltip = commondefs.onItemWorldTooltip,
        onTooltip = commondefs.onItemTooltip,	
		icon = "itemrigs/FloorProp_DataDisc.png",		
		profile_icon =     "gui/icons/item_icons/items_icon_small/icon-item_location_map_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_location_map.png",
		desc = STRINGS.PROPS.SITE_LOCATION_DESC,
		traits = { showOnce = "corp_map" },
		abilities = { "carryable" },
	},	

	item_corpIntel =
	{
		type = "simunit",
		name =  STRINGS.PROPS.CORP_INTEL,
        onWorldTooltip = commondefs.onItemWorldTooltip,
        onTooltip = commondefs.onItemTooltip,	
		desc = STRINGS.PROPS.CORP_INTEL_DESC,
		icon = "itemrigs/FloorProp_DataDisc.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_data_disk_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_data_disk.png",
		traits = {corpIntel = true, selectpriority = 0, score = 300, cashInReward = 300, showOnce = "corp_intel" },
		abilities = { "carryable" },
	},

	item_artifact =
	{
		type = "simunit",
		name =  STRINGS.PROPS.ARTIFACT,
        onWorldTooltip = commondefs.onItemWorldTooltip,
        onTooltip = commondefs.onItemTooltip,	
		desc = STRINGS.PROPS.ARTIFACT_DESC,
		icon = "itemrigs/FloorProp_Artifact_1.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_relic_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_relic.png",
		traits = { artifact= true, selectpriority = 0,  showOnce = "corp_intel", cashInReward=500 },
		abilities = { "carryable" },
	},		


	item_generic_usable =
	{
		type = "simunit",
		name = STRINGS.PROPS.GENERIC_USABLE,
		icon = "itemrigs/empty.png",		
		traits = { selectpriority = 0 },
		abilities = { "usable" },
	},

	item_radio =
	{
		type = "radio",
		name = STRINGS.ITEMS.RADIO,
		flavor = STRINGS.ITEMS.RADIO_FLAVOR,			
        onWorldTooltip = commondefs.onItemWorldTooltip,
		icon = "itemrigs/empty.png",		
		traits = { selectpriority = 0 },
		abilities = { "usable" },
	},
    
    item_valuable_tech =
	{
		type = "simunit",
		name = STRINGS.PROPS.VALUABLE_TECH,
        onWorldTooltip = commondefs.onItemWorldTooltip,
        onTooltip = commondefs.onItemTooltip,	
		desc = STRINGS.PROPS.VALUABLE_TECH_DESC,
		icon = "itemrigs/floor_prop_tech_loot.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tech_loot_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tech_loot.png",
		traits = { artifact= true, selectpriority = 0,  showOnce = "corp_intel", cashInReward=300 },
		abilities = { "carryable" },
	},		

	item_valuable_tech_2 =
	{
		type = "simunit",
		name =  STRINGS.PROPS.ARTIFACT,
        onWorldTooltip = commondefs.onItemWorldTooltip,
        onTooltip = commondefs.onItemTooltip,	
		desc = STRINGS.PROPS.ARTIFACT_DESC,
		icon = "itemrigs/FloorProp_Artifact_2.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tech_loot_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tech_loot.png",
		traits = { artifact= true, selectpriority = 0,  showOnce = "corp_intel", cashInReward=500 },
		abilities = { "carryable" },
	},		

	item_valuable_tech_3 =
	{
		type = "simunit",
		name =  STRINGS.PROPS.ARTIFACT,
        onWorldTooltip = commondefs.onItemWorldTooltip,
        onTooltip = commondefs.onItemTooltip,	
		desc = STRINGS.PROPS.ARTIFACT_DESC,
		icon = "itemrigs/FloorProp_Artifact_3.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tech_loot_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tech_loot.png",
		traits = { artifact= true, selectpriority = 0,  showOnce = "corp_intel", cashInReward=500 },
		abilities = { "carryable" },
	},	

	eyeball =
	{
		type = "eyeball",
		name = STRINGS.PROPS.EYEBALL,
		facing = simdefs.DIR_N,	
		rig = "eyeballrig",
		traits = { hasSight = true, seesHidden = true, LOSarc = math.pi / 2 },
	},

	eyeball360 =
	{
		type = "eyeball",
		name = STRINGS.PROPS.EYEBALL,
		facing = simdefs.DIR_N,	
		rig = "eyeballrig",
		traits = { hasSight = true, seesHidden = true, LOSarc = math.pi * 2, LOSrange = 3, },
	},

    smoke_cloud =
    {
        type = "smoke_cloud",
        name = STRINGS.PROPS.SMOKE,
        rig = "smokerig",
		kanim = "kanim_smoke_plume",
        traits = { radius = 3, lifetime = 2, noghost = true }
    },

	smoke_edge =
	{
		type = "simunit",
		name = STRINGS.PROPS.SMOKE_EDGE,
        rig = "",
		traits = { smokeEdge = true, sightable = true, noghost = true },
	},

	key =
	{
		type = "simunit",
		name = STRINGS.PROPS.KEY,
		icon = "itemrigs/FloorProp_Key.png",
		profile_icon = "gui/items/Item_Key.png",
		abilities = { "carryable" },
		traits = { keybits = simdefs.DEFAULT_KEYID }, 
	},

	passcard =
	{
		type = "simunit",
		name = STRINGS.ITEMS.PASS_CARD,
		desc = STRINGS.ITEMS.PASS_CARD_TOOLTIP,
		flavor = STRINGS.ITEMS.PASS_CARD_FLAVOR,			
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/item_icons/icon-item_passcard.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_passcard.png",
		tooltip = "<ttbody><ttheader2>PASS CARD</> Unlock secure doors.",
    	onWorldTooltip = commondefs.onItemWorldTooltip,
    	onTooltip = commondefs.onItemTooltip,		
		abilities = { "carryable" },
		traits = { keybits = simdefs.DOOR_KEYS.SECURITY, noDestroy = true }, 
	},

	red_passcard =
	{
		type = "simunit",
		name = STRINGS.ITEMS.FINAL_RED,
		desc = STRINGS.ITEMS.FINAL_RED_TIP,
		flavor = STRINGS.ITEMS.FINAL_RED_FLAVOR,			
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/item_icons/icon-item_passcard.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_passcard.png",
		tooltip = "<ttbody><ttheader2>RED CARD</> Use with the yellow card to unlock the security elevator.",
    	onWorldTooltip = commondefs.onItemWorldTooltip,
    	onTooltip = commondefs.onItemTooltip,		
		abilities = { "carryable" },
		traits = { keybits = simdefs.DOOR_KEYS.FINAL_RED, noDestroy = true }, 
		tags = { "final_card" },
	},

	yellow_passcard =
	{
		type = "simunit",
		name = STRINGS.ITEMS.FINAL_YELLOW,
		desc = STRINGS.ITEMS.FINAL_YELLOW_TIP,
		flavor = STRINGS.ITEMS.FINAL_YELLOW_FLAVOR,			
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/item_icons/icon-item_passcard.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_passcard.png",
		tooltip = "<ttbody><ttheader2>YELLOW CARD</> Use with the red card to unlock the security elevator.",
    	onWorldTooltip = commondefs.onItemWorldTooltip,
    	onTooltip = commondefs.onItemTooltip,		
		abilities = { "carryable" },
		traits = { keybits = simdefs.DOOR_KEYS.FINAL_LEVEL, noDestroy = true, }, 
		tags = { "final_card" },
	},


	note =
	{
		type = "simunit",
		name = STRINGS.PROPS.NOTE,
		icon = "itemrigs/note.png",
		nolocator = true,
		tooltip = nil,
		abilities = { "readable" },
		traits = { noteType = "NOTE", },
	},

	poster =
	{
		type = "simunit",
		name = STRINGS.PROPS.POSTER,
		rig = "",
		nolocator = true,
		tooltip = nil,
		abilities = { "readable" },
		traits = { noteType = "POSTER", },
	},

	security_laser_emitter_1x1_partner =
	{
		type = "laser_emitter",
		name = STRINGS.PROPS.LASER_EMITTER,
		kanim = "kanim_wall_laser_emitter",
		onWorldTooltip = onMainframeTooltip,
		facing = simdefs.DIR_N,
		rig = "laserrig",
		traits = { mainframe_icon = true, mainframe_status = "inactive", },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative"},
	},	

	security_laser_emitter_1x1 =
	{
		type = "laser_emitter",
		name = STRINGS.PROPS.LASER_EMITTER,
		kanim = "kanim_wall_laser_emitter",
		onWorldTooltip = onMainframeTooltip,
		facing = simdefs.DIR_N,
		rig = "laserrig",
		traits =
        {
            mainframe_laser=true,
            mainframe_icon = true,
            mainframe_spawnprop = "laser_beam",
            mainframe_spawnpartner = "security_laser_emitter_1x1_partner",
            mainframe_status = "inactive",
            mainframe_autodeactivate = true,
        },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative"},
	},	

	security_infrared_emitter_1x1 =
	{
		type = "laser_emitter",
		name = STRINGS.PROPS.BEAM_EMITTER,
		kanim = "kanim_wall_laser_emitter",
		onWorldTooltip = onMainframeTooltip,
		facing = simdefs.DIR_N,
		rig = "laserrig",
		traits =
		{
            mainframe_laser=true,
            mainframe_icon = true,
            mainframe_spawnprop = "infrared_beam",
            mainframe_spawnpartner = "security_laser_emitter_1x1_partner",
            mainframe_status = "inactive",
            mainframe_autodeactivate = true,
        },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative"},
	},	


	security_laser_emitter_tall_1x1_partner =
	{
		type = "laser_emitter",
		name = STRINGS.PROPS.LASER_EMITTER,
		kanim = "kanim_wall_laser_emitter_tall",
		onWorldTooltip = onMainframeTooltip,
		facing = simdefs.DIR_N,
		rig = "laserrig",
		traits = { mainframe_icon = true, mainframe_status = "inactive" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative"},
	},	

	security_infrared_wall_emitter_1x1 =
	{
		type = "laser_emitter",
		name =  STRINGS.PROPS.WALL_EMITTER,
		kanim = "kanim_wall_laser_emitter_tall",
		onWorldTooltip = onMainframeTooltip,
		facing = simdefs.DIR_N,
		rig = "laserrig",
		traits =
    	{
            empWhenTripped = 1,
            mainframe_icon = true,
            mainframe_laser=true,
            mainframe_spawnprop = "infrared_wall",
            mainframe_spawnpartner = "security_laser_emitter_tall_1x1_partner",
            mainframe_status = "inactive",
            mainframe_autodeactivate = true,
        },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative"},
	},	

	
	security_camera_1x1 =
	{
		type = "simcamera",
		name = STRINGS.PROPS.SECURITY_CAMERA,
		kanim = "kanim_security_camera",
		onWorldTooltip = onMainframeTooltip,
		profile_anim = "portraits/camera_portrait",		
		facing = simdefs.DIR_N,	
		rig = "camerarig",
        hit_fx = { z = 64 },
		traits = util.extend( MAINFRAME_TRAITS )
			{ mainframe_camera = true, mainframe_no_daemon_spawn = true, hasSight = true, canBeShot = true, hit_metal = true, LOSrange = 8, breakIceOffset = 56, hasAttenuationHearing=true },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative",reboot_start="SpySociety/Actions/reboot_initiated_camera",reboot_end="SpySociety/Actions/reboot_complete_camera"},		
	},	

	security_soundBug_1x1 =
	{
		type = "simsoundbug",
		name =  STRINGS.PROPS.SOUND_BUG,
		kanim = "kanim_security_soundbug",
		onWorldTooltip = onSoundBugTooltip,
		facing = simdefs.DIR_N,	
		rig = "soundbugrig",
		traits = util.extend( MAINFRAME_TRAITS )
			{ hasHearing = true, breakIceOffset = 4, toolTipNote =STRINGS.PROPS.SOUND_BUG_TOOLTIP  },				
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative",reboot_start="SpySociety/Actions/reboot_initiated_soundbug",reboot_end="SpySociety/Actions/reboot_complete_soundbug"},
	},	

	turret =
	{
		type = "simturret",
		name = STRINGS.PROPS.TURRET,
		onWorldTooltip = onMainframeTooltip,
		profile_anim = "portraits/turret_portrait",
		kanim = "kanim_turret",
		rig = "turretrig",
		facing = simdefs.DIR_E,		
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative", shoot="SpySociety/Attacks/shoot_thompsonSM_single",reboot_start="SpySociety/Actions/reboot_initiated_turret",reboot_end="SpySociety/Actions/reboot_complete_turret"},
		traits = util.extend( MAINFRAME_TRAITS )
		{ 	
			mainframe_turret = true, 
            mainframe_status = "inactive",

			impass = {0,0}, 
			cover = true,
					
			hasSight=true, 	
	
			ap = 0,
			apMax = 0, 

			sightable = true,

			wounds =0,
			woundsMax = 2,

			hit_metal = true,

			canKO = false,
			steadyAim = true,
			canBeShot = true,
			anchorShot = true,
			on = false,
		},
		abilities = { "shootOverwatch" },
		children = { tool_templates.item_turretgun },
	},

	turret_generator = 
	{
		type = "turret_generator", 
		name =  STRINGS.PROPS.TURRET_GENERATOR,
		rig = "corerig",
		onWorldTooltip = onMainframeTooltip,
		kanim = "kanim_powersource", 
		uses_mainframe =
		{
			toggle =
			{
				name = STRINGS.PROPS.TURRET_GENERATOR_TOGGLE,
				tooltip = STRINGS.PROPS.TURRET_GENERATOR_TOGGLE_TIP,
				fn = "toggle" -- global script function
			}
		},		
		traits = util.extend( MAINFRAME_TRAITS )
			{ cover = true, impass = {0,0}, mainframe_autodeactivate=true },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator"}
	},	

	laser_generator = 
	{
		type = "laser_generator", 
		name =  STRINGS.PROPS.LASER_GENERATOR, 
		rig = "corerig",
		onWorldTooltip = onMainframeTooltip,
		kanim = "kanim_powersource", 
		uses_mainframe =
		{
			toggle =
			{
				name = STRINGS.PROPS.LASER_GENERATOR_TOGGLE,
				tooltip = STRINGS.PROPS.LASER_GENERATOR_TOGGLE_TIP,
				fn = "toggle" -- global script function
			}
		},		
		traits = util.extend( MAINFRAME_TRAITS )
			{ cover = true, impass = {0,0}, mainframe_autodeactivate=true, laser_gen = true },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator"}
	},	

	item_store = 
	{ 
		type = "store", 
		name =  STRINGS.PROPS.STORE, 
		onWorldTooltip = onStoreTooltip,
		kanim = "kanim_printer", 
		rig ="corerig",
		traits = util.extend( MAINFRAME_TRAITS ) { moveToDevice=true, cover = true, impass = {0,0}, storeType="standard"},
		abilities = { "showItemStore" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", }
	},

	item_store_large = 
	{ 
		type = "store", 
		name =  STRINGS.PROPS.STORE_LARGE, 
		onWorldTooltip = onStoreTooltip,
		kanim = "kanim_printer", 
		rig ="corerig",
		traits = util.extend( MAINFRAME_TRAITS ) { moveToDevice=true, cover = true, impass = {0,0}, storeType="large", sightable = true, largenano=true},
		abilities = { "showItemStore" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", }
	},	

	hostage_capture = 
	{ 
		type = "simunit", 
		name = STRINGS.PROPS.HOSTAGE,
		rig = "hostagerig",	
		onWorldTooltip = function( tooltip, unit )
			tooltip:addLine( unit:getName() )
			tooltip:addAbility( STRINGS.ABILITIES.RESCUE, STRINGS.ABILITIES.RESCUE_HOSTAGE_DESC, "gui/items/icon-action_open-safe.png",nil,true )
		end,
		tags = { "hostage" },
		kanim = "kanim_hostage", 

		traits = { impass = {0,0}, rescue_incident = "hostage_rescued", template="hostage",  mp=5, mpMax =5, sightable = true, hostage = true, untie_anim = true,  vitalSigns = 2, agent_filter= true }, 
		abilities = { "hostage_rescuable" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", }
	},

	prisoner_capture = 
	{ 
		type = "simunit", 
		name =  STRINGS.PROPS.PRISONER,
		rig = "unitrig",
		onWorldTooltip = function( tooltip, unit )
			tooltip:addLine( unit:getName() )
			tooltip:addAbility( STRINGS.ABILITIES.RESCUE, STRINGS.ABILITIES.RESCUE_PRISONER_DESC, "gui/items/icon-action_open-safe.png" )
		end,
		tags = { "hostage" },
		kanim = "kanim_prisoner", 

		traits = { impass = {0,0}, template="prisoner", sightable = true, hostage = true, agent_filter= true },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", }
	},	

	agent_capture = 
	{ 
		type = "simunit", 
		name = STRINGS.PROPS.CAPTURED_AGENT,
		rig = "unitrig",
		onWorldTooltip = function( tooltip, unit )
			tooltip:addLine( unit:getName() )
			tooltip:addAbility( STRINGS.ABILITIES.RESCUE, STRINGS.ABILITIES.RESCUE_DESC, "gui/items/icon-action_open-safe.png" )
		end,
		kanim = "kanim_sharpshooter_male", 
		traits = { impass = {0,0}, sightable = true, agentRescue=true, hostage = true, agent_filter= true},
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", }
	},

	lab_safe = 
	{ 
		type = "simunit", 
		name =  STRINGS.PROPS.SAFE,
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_safe", 
		rig ="corerig",
		traits = util.extend( SAFE_TRAITS, MAINFRAME_TRAITS ) { moveToDevice=true, },
		abilities = { "stealCredits" },
		lootTable = "lab_safe",
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",reboot_start="SpySociety/Actions/reboot_initiated_safe",reboot_end="SpySociety/Actions/reboot_complete_safe" }
	},

	lab_safe_tier2 =
	{ 
		type = "simunit", 
		name =  STRINGS.PROPS.SAFE,
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_safe2",
		rig ="corerig",
		traits = util.extend( SAFE_TRAITS, MAINFRAME_TRAITS ) { moveToDevice=true, mainframe_iceBonus = 1, tier2safe=true },
		abilities = { "stealCredits" },
		lootTable = "lab_safe",
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",reboot_start="SpySociety/Actions/reboot_initiated_safe",reboot_end="SpySociety/Actions/reboot_complete_safe" }
	},

	guard_locker = 
	{ 
		type = "simunit", 
		name =  STRINGS.PROPS.GUARD_LOCKER,
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_guard_locker", 
		rig ="corerig",
		traits = util.extend( SAFE_TRAITS, MAINFRAME_TRAITS ) { moveToDevice=true, },
		abilities = { "stealCredits" },
		lootTable = "lab_safe",
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",reboot_start="SpySociety/Actions/reboot_initiated_safe",reboot_end="SpySociety/Actions/reboot_complete_safe", open_safe="SpySociety/Objects/securitysafe_open" }
	},


	augment_grafter = 
	{ 
		type = "simunit", 
		name =  STRINGS.PROPS.AUGMENT_GRAFTER,
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_augment_grafter", 
		rig ="corerig",

		traits = util.extend( MAINFRAME_TRAITS ) {	moveToDevice=true, cover = true, impass = {0,0}, sightable = true, mainframe_no_recapture = true },

		abilities = { "useAugmentMachine" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", }
	},

	augment_drill = 
	{ 
		type = "simunit", 
		name =  STRINGS.PROPS.AUGMENT_DRILL,
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_augment_grafter", 
		rig ="corerig",

		traits = util.extend( MAINFRAME_TRAITS ) {	moveToDevice=true, cover = true, impass = {0,0}, sightable = true, mainframe_no_recapture = true, drill=true },

		abilities = { "useAugmentMachine" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", }
	},

	inhibitor_charger = 
	{ 
		type = "simunit", 
		name =  STRINGS.PROPS.INHIBITOR,
		onWorldTooltip = function( tooltip, unit )
			tooltip:addLine( unit:getName() )
			tooltip:addAbility( STRINGS.UI.ACTIONS.CHARGE_INHIBITOR.NAME, STRINGS.UI.ACTIONS.CHARGE_INHIBITOR.TOOLTIP, "gui/items/icon-action_open-safe.png" )
		end,
		kanim = "kanim_augment_grafter", 
		rig ="corerig",
		traits = util.extend( MAINFRAME_TRAITS ) { },
		tags = { },
		abilities = { "useInhibitorCharger" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", }
	},

	server_terminal = 
	{
		type = "store", 
		name =  STRINGS.PROPS.SERVER_TERMINAL,
		rig ="corerig",
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_serverTerminal", 
		abilities = { "showItemStore" },
		traits = util.extend( MAINFRAME_TRAITS )
			{ moveToDevice=true, sightable=true, cover = true, impass = {0,0}, storeType="server", noMandatoryItems = true, bigshopcat = true  },

		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",spot="SpySociety/Objects/shopcat" }
	},

	mini_server_terminal = 
	{
		type = "store", 
		name =  STRINGS.PROPS.MINI_SERVER_TERMINAL,
		rig ="corerig",
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_serverTerminal", 
		abilities = { "showItemStore" },
		traits = util.extend( MAINFRAME_TRAITS )
			{ moveToDevice=true, sightable=true, cover = true, impass = {0,0}, storeType="miniserver", noMandatoryItems = true  },

		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",spot="SpySociety/Objects/shopcat" }
	},

	camera_core = 
	{
		type = "simunit", 
		name = STRINGS.PROPS.CAMERA_CORE,
		rig ="corerig",
		onWorldTooltip = onMainframeTooltip,
		kanim = "kanim_core", 
		traits = util.extend( MAINFRAME_TRAITS )
			{ cover = true, impass = {0,0}, revealUnits = "mainframe_camera" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator" }
	},

	map_core = 
	{
		type = "simunit", 
		name = STRINGS.PROPS.MAP_CORE,
		rig ="corerig",
		onWorldTooltip = onMainframeTooltip,
		kanim = "kanim_core", 
		traits = util.extend( MAINFRAME_TRAITS )
			{ cover = true, impass = {0,0}, showOutline=true },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator" }
	},

	console_core = 
	{
		type = "simunit", 
		name = STRINGS.PROPS.CONSOLE_CORE,
		rig ="corerig",
		onWorldTooltip = onMainframeTooltip,
		kanim = "kanim_core", 
		traits = util.extend( MAINFRAME_TRAITS )
			{ cover = true, impass = {0,0}, revealUnits = "mainframe_console" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator"}
	},

	daemon_core = 
	{
		type = "simunit", 
		name = STRINGS.PROPS.DAEMON_CORE,
		rig ="corerig",
		onWorldTooltip = onMainframeTooltip,
		kanim = "kanim_core", 
		traits = util.extend( MAINFRAME_TRAITS )
			{ cover = true, impass = {0,0}, revealDaemons = true },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator"}
	},

	console =
	{
		type = "simunit",
		name =  STRINGS.PROPS.CONSOLE,
		onWorldTooltip = onConsoleTooltip,
		kanim = "kanim_console",
		traits =		  
			{ cover = true, impass = {0,0}, mainframe_status="active", mainframe_console=true, mainframe_icon=true, mainframe_console_lock = 0, maxcpus=1, cpus=1, maxOcclusion = 4, hijacked=false },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", spot="SpySociety/Objects/computer_types_occlude", spotend="SpySociety/Objects/computer_shutdown", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator"}, --use="SpySociety/Actions/console_use",
		rig = "consolerig",
	},

	yellow_level_console =
	{
		type = "simunit",
		name =  STRINGS.PROPS.YELLOW_LEVEL_CONSOLE,
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_preFinalConsole",
		tags = {"yellow_level_console"},
		abilities = { "activate_locked_console" },
		traits = util.extend( MAINFRAME_TRAITS ) { moveToDevice=true, cover = true, impass = {0,0}, sightable = true, keybits = simdefs.DOOR_KEYS.FINAL_LEVEL, maxOcclusion = 4, mainframe_no_recapture = true },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", spot="SpySociety/Objects/computer_types_occlude", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator"}, --use="SpySociety/Actions/console_use",
		rig = "corerig",
	},

	final_console =
	{
		type = "simunit",
		name = STRINGS.PROPS.FINAL_CONSOLE,
		kanim = "kanim_finalConsole",
		tags = {"final_console"},
		abilities = { "activate_final_console" },
		traits = { moveToDevice=true, cover = true, impass = {0,0}, sightable = true, keybits = simdefs.DOOR_KEYS.FINAL_RED, maxOcclusion = 4, mainframe_iceMax = nil, mainframe_ice = nil, mainframe_item = false, mainframe_icon = false, mainframe_no_recapture = true},
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", spot="SpySociety/Objects/computer_types_occlude", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator"}, --use="SpySociety/Actions/console_use",
		rig = "corerig",
	},

	ending_jackin =
	{
		type = "simunit",
		name = STRINGS.PROPS.ENDING_JACKIN,
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_monsterConsole",
		tags = {"ending_jackin"},
		abilities = { "jackin_root_console" },

		traits = util.extend( MAINFRAME_TRAITS ) { moveToDevice=true, cover = true, impass = {0,0}, sightable = true, maxOcclusion = 4, mainframe_no_recapture = true },

		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", spot="SpySociety/Objects/computer_types_occlude", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator",activate="SpySociety/Actions/holocover_activate", deactivate="SpySociety/Actions/holocover_deactivate", activeSpot="SpySociety/Actions/holocover_run_LP"}, --use="SpySociety/Actions/console_use",
		rig = "corerig",
	},

	data_core =
	{
		type = "simunit",
		name = STRINGS.PROPS.DATA_CORE,
		onWorldTooltip = function( tooltip, unit )
			tooltip:addLine( unit:getName(), unit:getTraits().core_name )
		end,
		kanim = "kanim_server",
		traits = util.extend( MAINFRAME_TRAITS )	
		  { cover = true, impass = {0,0}, core_order = 0, mainframe_core=true, core_name = "", mainframe_icon= true, mainframe_shard = true, operatable_device=true },
		sounds = { appeared="SpySociety/HUD/gameplay/peek_positive", spot="SpySociety/Objects/computer_types", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator" },
		abilities = { "usb_upload" },
		rig = "corerig",
	},

	trap_shock_door = 
	{ 
		type = "simtrap", 
		name =  STRINGS.PROPS.SHOCK_TRAP,
		onWorldTooltip = function( tooltip, unit ) 
			tooltip:addLine( unit:getName() )
			tooltip:addAbility( STRINGS.ABILITIES.DISARM, STRINGS.ABILITIES.DISARM_TRAP, "gui/icons/action_icons/Action_icon_Small/icon-action_drop_give_small.png" )
		end,
		kanim = "kanim_shock_trap_door", 
		rig ="traprig",
		traits = {trap=true, noMainframe = true},
		abilities = {},
	},

	door_decoder =
	{
		type = "lock_decoder", 
		name = STRINGS.PROPS.DOOR_DECODER,
		onWorldTooltip = function( tooltip, unit ) 
			tooltip:addLine( unit:getName() )
			tooltip:addAbility( STRINGS.ABILITIES.DECODING, util.sformat( STRINGS.ABILITIES.DECODING_DESC, unit:getTraits().turns ), "gui/icons/action_icons/Action_icon_Small/icon-action_drop_give_small.png" )
		end,
		kanim = "kanim_lock_decoder", 
		rig ="traprig",
		traits = { turns = 2, noMainframe = true },
		abilities = {},
	},

	alarm =
	{
		type = "simunit",
		name = STRINGS.PROPS.ALARM,
		kanim = "kanim_office_1x1_alarm_1",
		traits = util.extend( MAINFRAME_TRAITS )
			{ impass = {0,0}, alarm=true, alarmOn= false, mainframe_status = "inactive" },
		sounds = {use="SpySociety/Actions/console_use",spot="SpySociety/Objects/computer"},
		rig = "alarmrig",
		uses_mainframe =
		{
			deactivateAlarm =
			{
				name = "DEACTIVATE\nACTION",
				tooltip = "Turn off the alarm",
				fn = "alarmOff" -- global script function
			},
			activateAlarm =
			{
				name = "ACTIVATE\nACTION",
				tooltip = "Turn on the alarm",
				fn = "alarmOn" -- global script function
			},			
		},
	},	


	detention_processor = 
	{
		type = "simunit", 
		name = STRINGS.PROPS.DETENTION_PROCESSOR,
		rig ="corerig",
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_serverTerminal", 
		abilities = { "open_detention_cells" },
		traits = util.extend( MAINFRAME_TRAITS )
			{ moveToDevice=true, cover = true, impass = {0,0}, sightable=true },
		tags = { "detention_processor" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator" }
	},


	vault_processor = 
	{
		type = "simunit", 
		name = STRINGS.PROPS.VAULT_PROCESSOR,
		rig ="corerig",
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_serverTerminal", 
		abilities = { "open_security_boxes" },
		traits = util.extend( MAINFRAME_TRAITS )
			{ moveToDevice=true, cover = true, impass = {0,0}, sightable=true, open_secure_boxes=true},
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator" }
	},

	research_processor = 
	{
		type = "simunit", 
		name = STRINGS.PROPS.RESEARCH_PROCESSOR,
		rig ="corerig",
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_serverTerminal", 
		abilities = { "stealCredits" },
		traits = util.extend( MAINFRAME_TRAITS )
			{ moveToDevice=true, cover = true, impass = {0,0}, sightable=true, research_program=true},
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator" }
	},

	vault_safe_1 = 
	{ 
		type = "simunit", 
		name = STRINGS.PROPS.DEPOSIT_BOXES,
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_vault_safe_1", 
		rig ="corerig",
		traits = util.extend( SAFE_TRAITS  ) {  moveToDevice=true, mainframe_status = "active", security_box=true, security_box_locked=true, mainframe_icon=true, emp_safe=true},
		abilities = { "stealCredits" },

		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_safe",reboot_end="SpySociety/Actions/reboot_complete_safe" }
	},	

	vault_safe_2 = 
	{ 
		type = "simunit", 
		name = STRINGS.PROPS.SECURE_CASE,
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_vault_safe_2", 
		rig ="corerig",
		traits = util.extend( SAFE_TRAITS, MAINFRAME_TRAITS ) {moveToDevice=true, },
		abilities = { "stealCredits" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",reboot_start="SpySociety/Actions/reboot_initiated_safe",reboot_end="SpySociety/Actions/reboot_complete_safe" }
	},	

	vault_safe_3 = 
	{ 
		type = "simunit", 
		name = STRINGS.PROPS.SECURE_CASE,
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_vault_safe_3", 
		rig ="corerig",
		traits = util.extend( SAFE_TRAITS, MAINFRAME_TRAITS ) {moveToDevice=true, },
		abilities = { "stealCredits" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",reboot_start="SpySociety/Actions/reboot_initiated_safe",reboot_end="SpySociety/Actions/reboot_complete_safe" }
	},		


	cell_door = 
	{
		type = "simunit", 
		name =  STRINGS.PROPS.CELL_DOOR,
		rig ="corerig",
		onWorldTooltip = function( tooltip, unit )
			tooltip:addLine( unit:getName() )
		end,
		kanim = "kanim_celldoor1", 
		traits = {  impass = {0,0}, sightable=true, cell_door=true },
		sounds = { }
	},	

	public_terminal = 
	{
		type = "simunit", 
		name =  STRINGS.PROPS.PUBLIC_TERMINAL,
		rig ="corerig",
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_public_terminal", 
        abilities = { "stealCredits" },
		traits = util.extend( MAINFRAME_TRAITS )
			{ moveToDevice=true, cover = true, impass = {0,0}, sightable=true, public_term = true, noOpenAnim=true },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator" }
	},	

	ftm_scanner = 
	{
		type = "scanner", 
		name =  STRINGS.PROPS.FTM_SCANNER,
		rig = "corerig",
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_scanner",
        abilities = { "stealCredits" },
		traits = util.extend( MAINFRAME_TRAITS )
			{ 	
				moveToDevice=true, 
				cover = true, 
				impass = {0,0},  
            	mainframe_status = "inactive", -- So that it activates on spwan.
				mainframe_autodeactivate=true, 
				scanner = true,
				sightable = true,
				canKO = false,
				spotSoundPowerDown = true,	
                startOn = true,
			},
        children = { "item_valuable_tech" },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative", spot="SpySociety/Objects/KO/level_scanner",reboot_start="SpySociety/Actions/reboot_initiated_scanner",reboot_end="SpySociety/Actions/reboot_complete_scanner"}, --use="SpySociety/Actions/console_use",					
	},	

	final_terminal = 
	{
		type = "simunit", 
		name = STRINGS.PROPS.FINAL_TERMINAL,
		rig ="corerig",
		onWorldTooltip = onDeviceTooltip,
		kanim = "kanim_serverTerminal", 
		abilities = { "install_incognita" },
		traits = util.extend( MAINFRAME_TRAITS )
			{ moveToDevice=true, cover = true, impass = {0,0}, sightable=true, install_incognita= true},
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_generator",reboot_end="SpySociety/Actions/reboot_complete_generator" }
	},		

}

local prop_templates = {}


function ResetPropDefs()
	log:write("ResetPropDefs()")	
	util.tclear(prop_templates)
	util.tmerge(prop_templates, prop_templates_default)

	-- Reassign key name to value table.
	for id, template in pairs(prop_templates) do
		if type(template) == "table" then
			template.id = id
		end
	end	
end

ResetPropDefs()

return prop_templates
