local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local commondefs = include("sim/unitdefs/commondefs")
local itemdefs = include("sim/unitdefs/itemdefs")
local speechdefs = include( "sim/speechdefs" )

---------------------------------------------------------------------------------------------------------
-- NPC templates

local SOUNDS = commondefs.SOUNDS

local DEFAULT_IDLES = commondefs.DEFAULT_IDLES

local DEFAULT_ABILITIES = commondefs.DEFAULT_ABILITIES

local onGuardTooltip = commondefs.onGuardTooltip

local DEFAULT_DRONE = commondefs.DEFAULT_DRONE


local npc_templates =
{
	npc_business_man =
	{
		type = "simunit",
		name = STRINGS.GUARDS.CEO,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/executive_build",	
		profile_image = "executive.png",
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_business_man",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,
			cashOnHand = 450, 
			ko_trigger = "intimidate_guard",
			kill_trigger = "guard_dead",
			vip=true,
            pacifist = true,
		},
		dropTable =
		{
			{ "item_adrenaline" ,5},
			{nil,75}
		},
		anarchyDropTable =
		{
			{ "item_laptop",5},
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_adrenaline" ,35},
			{nil,150}
		},		
		speech = speechdefs.NPC,
		voices = {"Executive"},
		skills = {},
		abilities = { },
		children = { },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "WimpBrain",		
	},

	npc_scientist =
	{
		type = "simunit",
		name = STRINGS.GUARDS.SCIENTIST,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/executive_build",	
		profile_image = "executive.png",
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_business_man",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,
			cashOnHand = 0, 
			ko_trigger = "intimidate_guard",
			kill_trigger = "guard_dead",
			vip=true,
            pacifist = true,
            lockScientistDoor=true,
		},
		dropTable =
		{	
			{ "item_stim" ,5},
			{nil,75}
		},
		anarchyDropTable =
		{
			{ "item_laptop",5},
		    { "item_hologrenade",5},
			{ "item_stickycam" ,35},
			{nil,150}
		},		
		speech = speechdefs.NPC,
		voices = {"Executive"},
		skills = {},
		abilities = { },
		children = { itemdefs.item_compiler_key }, 
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "WimpBrain",		
	},

	npc_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/portrait_security_build",	
		profile_image = "portrait_security.png",
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8
		},
		dropTable =
		{			
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,150}
		},			
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",		
	},

	ftm_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/portrait_security_build",
		profile_image = "portrait_security.png",
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male_ftm",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8
		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,150}
		},			
					
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",		
		blurb = "<ttheader>EMPLOYED</>\nIt is corporate policy to invest in life insurance for each an every one of it's valued employees. In event of accident causing injury or permanent system failure, dependents will receive insurance benefits in an order as noted by form CSF_312.\n<ttrule>Read all fine Print</>\n",
	},


	ftm_grenade_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.SUPPORT_GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/ftm_grenadier_build",
		profile_image = "FTM_grenadier.png",
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_grenade_ftm",

		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8
		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{ "item_flashgrenade" ,50},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_flashgrenade" ,50},	    
			{ "item_adrenaline" ,15},
			{nil,150}
		},			
					
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol, itemdefs.item_npc_flashgrenade },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",		
		blurb = "<ttheader>EMPLOYED</>\nIt is corporate policy to invest in life insurance for each an every one of it's valued employees. In event of accident causing injury or permanent system failure, dependents will receive insurance benefits in an order as noted by form CSF_312.\n<ttrule>Read all fine Print</>\n",
	},

	ftm_guard_tier_2 =
	{
		type = "simunit",
		name = STRINGS.GUARDS.ELITE_GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/ftm_med_2_build",	
		profile_image = "FTM_med_2.png",

    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_tier2_male_ftm",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			armor = 1,	
			cashOnHand = 110, 

			LOSrange = 8,
			LOSarc = math.pi / 4,
			LOSperipheralRange = 10,
			LOSperipheralArc = math.pi / 2,
            lookaroundArc = math.pi / 2 + math.pi / 4,
            lookaroundOffset = math.pi / 4 - math.pi / 8
		},
		dropTable =
		{
			{ "item_emp_pack", 15 },
			{ "item_emp_pack_2", 6},
			{ "item_emp_pack_3", 4 },
			{ "item_shocktrap_2", 4 },
			{ "item_shocktrap_3", 4 },
			{nil, 68}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{ "item_emp_pack", 15 },
			{nil,150}
		},			
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol2 },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},	


	barrier_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/ftm_barrier_build",	
		profile_image = "FTM_barrier.png",

    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_barrier_guard_ftm",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,

			mainframe_item = true,
			mainframe_ice = 3,		
			mainframe_iceMax = 3,		
			mainframe_status = "active",	

			shieldArmor = true,
			firewallArmor = true,
			firewallShield = true,
			shields = 1,
			armor = 0,
			noTakeover = true,
			noRaiseIfIceZero = true,
			mainframe_ice_set_in_def = true,
			mainframe_no_daemon_spawn = true,
		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{ "item_emp_pack", 15 },
			{nil,150}
		},		
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",		
	},

	sankaku_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/sankaku_med_build",
		profile_image = "sankaku_med.png",	
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male_sankaku",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,
			cashOnHand = 110,
		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,150}
		},		
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",		
	},

	sankaku_guard_tier_2 =
	{
		type = "simunit",
		name = STRINGS.GUARDS.ELITE_GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/sankaku_med_2_build",
		profile_image = "sankaku_med_2.png",			
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_tier2_male_sankaku",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			armor = 1,	
			cashOnHand = 110, 

			LOSrange = 8,
			LOSarc = math.pi / 4,
			LOSperipheralRange = 10,
			LOSperipheralArc = math.pi / 2,					
            lookaroundArc = math.pi / 2 + math.pi / 4,
            lookaroundOffset = math.pi / 4 - math.pi / 8
		},
		dropTable =
		{
			{ "item_emp_pack", 15 },
			{ "item_emp_pack_2", 6},
			{ "item_emp_pack_3", 4 },
			{ "item_shocktrap_2", 4 },
			{ "item_shocktrap_3", 4 },
			{nil, 68}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{ "item_emp_pack", 15 },
			{nil,150}
		},		
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol2 },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},

	important_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.CAPTAIN,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/enforcer2_build",	
		profile_image = "enforcer_2.png",
		profile_icon_36x36= "gui/profile_icons/security_36.png",
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male_enforcer_2",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			kill_trigger = "guard_dead",
			enforcer = false,
			dashSoundRange = 8, 
			sightable = true,
		},
		speech = speechdefs.NPC,
		voices = {"KO_Heavy"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol },
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",		
	},

	plastek_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/plastech_med_build",	
		profile_image = "Plastech_med.png",	
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male_plastek",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,150}
		},		
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",
	},

	plastek_guard_tier2 =
	{
		type = "simunit",
		name = STRINGS.GUARDS.ELITE_GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/plastech_med_2_build",			
		profile_image = "Plastech_med_2.png",	
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_tier2_male_plastek",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			armor = 1,	
			cashOnHand = 90, 

			LOSrange = 8,
			LOSarc = math.pi / 4,
			LOSperipheralRange = 10,
			LOSperipheralArc = math.pi / 2,					
            lookaroundArc = math.pi / 2 + math.pi / 4,
            lookaroundOffset = math.pi / 4 - math.pi / 8
		},
		dropTable =
		{
			{ "item_clip" , 10},
			{ "item_laptop", 3 },
			{ "item_tazer_2" ,5},
			{ "item_tazer_3", 2 },
			{nil,80}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{ "item_emp_pack", 15 },
			{nil,135}
		},		
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol2 },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},

	plastek_recapture_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.MKI,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/plastech_cloack_build",		
		profile_image = "Plastech_cloack.png",	
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_ghost_male_plastek",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			mainframeRecapture = 6,	
			koDaemon = true,	

		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,150}
		},		
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",
	},	


	plastek_firewall_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.MKII,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/plastech_psi_build",	
		profile_image = "Plastech_psi.png",		
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_psi_male_plastek",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			firewallSupport = 2,
			firewallSupportRange = 8,
			investigateHackedDevices = true,
			armor = 1,	
			cashOnHand = 90, 

			LOSrange = 8,
			LOSarc = math.pi / 4,
			LOSperipheralRange = 10,
			LOSperipheralArc = math.pi / 2,					
            lookaroundArc = math.pi / 2 + math.pi / 4,
            lookaroundOffset = math.pi / 4 - math.pi / 8
		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,150}
		},		
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",
	},	


	ko_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/ko_med_build",
		profile_image = "KO_med.png",	
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male_ko",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	

		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,150}
		},		
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		abilities = util.extend(DEFAULT_ABILITIES){},
		skills = {},
		children = { itemdefs.item_npc_pistol },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",
	},


	ko_grenade_guard =
	{
		type = "simunit",
		name = STRINGS.GUARDS.SUPPORT_GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/ko_grenadier_build",
		profile_image = "KO_grenadier.png",	
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_grenade_ko",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8
		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_adrenaline" ,5},
			{ "item_flashgrenade" ,50},
			{nil,90}
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_flashgrenade" ,50},	    
			{ "item_adrenaline" ,15},
			{nil,150}
		},			
					
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol, itemdefs.item_npc_flashgrenade },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",		
		blurb = "<ttheader>EMPLOYED</>\nIt is corporate policy to invest in life insurance for each an every one of it's valued employees. In event of accident causing injury or permanent system failure, dependents will receive insurance benefits in an order as noted by form CSF_312.\n<ttrule>Read all fine Print</>\n",
	},


	ko_guard_tier2 =
	{
		type = "simunit",
		name = STRINGS.GUARDS.ELITE_GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/ko_med_2_build",
		profile_image = "KO_med_2.png",			
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_tier2_male_ko",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			armor = 1,		
			cashOnHand = 90, 

			LOSrange = 8,
			LOSarc = math.pi / 4,
			LOSperipheralRange = 10,
			LOSperipheralArc = math.pi / 2,					
            lookaroundArc = math.pi / 2 + math.pi / 4,
            lookaroundOffset = math.pi / 4 - math.pi / 8
		},
		dropTable =
		{
			{ "item_clip" , 8},
			{ "item_stim", 7},
			{ "item_stim_2", 3},
			{nil,79},
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,135}
		},		
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_pistol2 },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},

	ko_guard_heavy =
	{
		type = "simunit",
		name = STRINGS.GUARDS.HEAVY_GUARD,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/ko_heavy_build",
		profile_image = "KO_heavy.png",					
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male_ko_heavy",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,
			mpMax=6,
			mp=6,		
			wounds = 0,	
			armor = 2,
            resistKO = 1,
			backPowerPack = true,
			backPowerPackoverloadKO = 6,
			cashOnHand = 90,
		},
		dropTable =
		{
			{ "item_clip" , 8},
			{ "item_stim", 7},
			{ "item_stim_2", 6},
			{ "item_stim_3", 5 },
			{ nil, 74 },
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,135}
		},		
		speech = speechdefs.NPC,
		voices = {"KO_Heavy",},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_smg },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.HEAVY,
		brain = "GuardBrain",
	},	

	ko_specops =
	{
		type = "simunit",
		name = STRINGS.GUARDS.SPEC_OPS,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/ko_spec_ops_build",
		profile_image = "KO_spec_ops.png",		
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_specops_ko",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 6,	
			LOSarc = math.pi,
            lookaroundArc = math.pi + math.pi / 4,
            lookaroundOffset = math.pi / 8
		},
		dropTable =
		{
			{ "item_clip" ,5},
			{ "item_stim_2", 6},
			{ "item_stim_3", 5 },
			{ "item_cloakingrig_3", 10 },
			{nil, 74},
		},
		anarchyDropTable =
		{
			{ "item_tazer",5},
		    { "item_stim",5},
			{ "item_clip" ,25},		    
			{ "item_adrenaline" ,15},
			{nil,135}
		},		
		speech = speechdefs.NPC,
		voices = {"KO_SpecOps",},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_rifle },
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",
	},

	npc_guard_enforcer =
	{
		type = "simunit",
		name = STRINGS.GUARDS.ENFORCER,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/enforcer_build",
		profile_image = "enforcer.png",	
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male_enforcer",
		traits = util.extend( commondefs.basic_guard_traits )
		{
			heartMonitor="enabled",
			enforcer = true,
			dashSoundRange = 8,
		},
		speech = speechdefs.NPC,
		voices = {"KO_Heavy",},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_smg, itemdefs.item_npc_scangrenade},
		brain = "GuardBrain",
		sounds = SOUNDS.ARMORED,
	},
	
	npc_guard_enforcer_reinforcement =
	{
		type = "simunit",
		name = STRINGS.GUARDS.ENFORCER,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/enforcer2_build",
		profile_image = "enforcer_2.png",		
		profile_icon_36x36= "gui/profile_icons/security_36.png",
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male_enforcer_2",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			heartMonitor="enabled",
			enforcer = true,
			dashSoundRange = 8, 
		},
		speech = speechdefs.NPC,
		voices = {"KO_Heavy"},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_smg, itemdefs.item_npc_scangrenade},
		sounds = SOUNDS.GUARD,
		brain = "GuardBrain",		
	},


	npc_guard_enforcer_reinforcement_2 =
	{
		type = "simunit",
		name = STRINGS.GUARDS.ELITE_ENFORCER,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/enforcer_build",
		profile_image = "enforcer.png",	
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_male_enforcer",
		traits = util.extend( commondefs.basic_guard_traits ) 
		{
			heartMonitor="enabled",
			enforcer = true,
			dashSoundRange = 8,
			armor = 1,
		},
		speech = speechdefs.NPC,
		voices = {"KO_Heavy",},
		skills = {},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = { itemdefs.item_npc_smg, itemdefs.item_npc_scangrenade},
		brain = "GuardBrain",
		sounds = SOUNDS.ARMORED,
	},	
	
	drone = util.extend( DEFAULT_DRONE )
	{
		name = STRINGS.GUARDS.OBAKE_DRONE,
		profile_anim = "portraits/sankaku_drone_face_new",
		profile_build = "portraits/sankaku_drone_face_new",
		profile_image = "sankaku_drone.png",		
		kanim = "kanim_drone_SA",
		sounds = SOUNDS.DRONE_WALK,
		children = {itemdefs.item_drone_turret},	
	},

	drone_tier2 = util.extend( DEFAULT_DRONE )
	{
		name = STRINGS.GUARDS.OBAKE_DRONE2,
		profile_anim = "portraits/sankaku_drone_heavy_face_new",
		profile_build = "portraits/sankaku_drone_heavy_face_new",
		profile_image = "sankaku_drone_heavy.png",					
		kanim = "kanim_drone_tier2_SA",
		sounds = SOUNDS.DRONE_WALK,
    	onWorldTooltip = onGuardTooltip,
		traits = util.extend( DEFAULT_DRONE.traits )   
		{
			mainframe_ice = 2,	
			mainframe_iceMax = 2,
			armor = 1,
            lookaroundPeripheralArc = math.pi,
		},
		children = {itemdefs.item_drone_turret},	
	},

	null_drone = util.extend( DEFAULT_DRONE )
	{
		name = STRINGS.GUARDS.NULL_DRONE,
		kanim = "kanim_drone_null_SA",
		sounds = SOUNDS.DRONE_HOVER,
		profile_anim = "portraits/sankaku_drone_null_new",
		profile_image = "sankaku_drone_null.png",		
		brain = "PacifistBrain",
		abilities = { _OVERRIDE = true },
		children = { _OVERRIDE = true },
		traits = util.extend( DEFAULT_DRONE.traits )
		{
            mainframe_no_daemon_spawn = false,
			mainframe_always_daemon_spawn = true,
			mainframe_suppress_rangeMax = 4,
			mainframe_suppress_range = 4,
			mainframe_ice = 3,
			mainframe_iceMax = 3,

            dynamicImpass = false,
			scanSweeps = true,
            pacifist = true,
		},
		dropTable = 
		{
			{ "item_portabledrive", 25 },
			{ "item_portabledrive_2", 5 },
			{ "item_portabledrive_3", 3 },
			{nil, 67}
		},
	},

	camera_drone = util.extend( DEFAULT_DRONE )
	{
		type = "simcameradrone",
		name = STRINGS.GUARDS.CAMERA_DRONE,
		kanim = "kanim_drone_camera_SA",
		brain = "PacifistBrain",
		sounds = SOUNDS.DRONE_HOVER, 
		profile_anim = "portraits/sankaku_drone_camera_new",
		profile_image = "sankaku_drone_camera.png",		
		children = { _OVERRIDE = true },
		abilities = { _OVERRIDE = true },
		traits = util.extend( DEFAULT_DRONE.traits )
		{
			camera_drone = true, 
			controlTimerMax = 2, 
			dashSoundRange = 0,
            dynamicImpass = false,
            empDeath = true,

            scanSweeps = true,
            pacifist = true,
            PWROnHand = 1,
		},
		dropTable = 
		{
			{nil, 67}
		},
	},

	drone_akuma = 
	{
		type = "simdrone",
		name = STRINGS.GUARDS.AKUMA_DRONE,
		profile_icon = "gui/profile_icons/character-head-drone.png",
		profile_anim = "portraits/sankaku_drone_tank_face_new",
		profile_build = "portraits/sankaku_drone_tank_face_new",
		profile_image = "sankaku_drone_tank.png",		
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_drone_akuma_SA",
		rig = "dronerig",
		traits = util.extend( commondefs.basic_robot_traits )   
		{
			walk=true,
			enforcer = false,
			dashSoundRange = 8,		
			mpMax=4,
			mp=4,			
			
			mainframe_no_daemon_spawn = false,
			mainframe_always_daemon_spawn = true,
            mainframe_ice = 4,
            mainframe_iceMax = 4,
            empKO = 2,

			LOSarc = 3*math.pi/4,

			armor = 2,
			PWROnHand = 4,
            lookaroundPeripheralArc = math.pi,
		},

		voices = {"Drone"},
		speech = speechdefs.NPC,
		skills = {},
		dropTable = 
		{
			{ "item_icebreaker", 25 },
			{ "item_icebreaker_2", 5 },
			{ "item_icebreaker_3", 3 },
			{nil, 67}
		},
		abilities = util.extend(DEFAULT_ABILITIES){},
		children = {itemdefs.item_npc_smg_drone},
		sounds = SOUNDS.DRONE_HOVER_HEAVY,
		brain = "DroneBrain",
	},	

	omni_observer = 
	{
		type = "simunit",
		name = STRINGS.GUARDS.OMNI_OBSERVER,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/sankaku_med_2_build",
		profile_image = "sankaku_med_2.png",					
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_tier2_male_sankaku",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			armor = 0,	
            seesHidden = true, 
            detect_cloak = true, 
            omni = true,
		},
		dropTable = 
		{
			{nil, 67}
		},
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = {"shootOverwatch", "overwatch", "breakDoor", "peripheral_expansion_passive", "ultrasonic_echolocation_passive", "ultraviolet_spectrometer_passive" },
		children = { itemdefs.item_npc_pistol2 },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},
	
	omni_hunter = 
	{
		type = "simunit",
		name = STRINGS.GUARDS.OMNI_HUNTER,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/sankaku_med_2_build",
		profile_image = "sankaku_med_2.png",								
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_tier2_male_sankaku",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			mpMax = 6, 
			mp = 6, 
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			armor = 0,	
            omni = true,

			sensors = 1, 
			sensorsMax = 1, 
		},
		dropTable = 
		{
			{nil, 67}
		},
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = {"shootOverwatch", "overwatch", "breakDoor", "long_range_sensors_passive", "sprint_pads_passive", "regenerative_nanocells_passive" },
		children = { itemdefs.item_npc_pistol2 },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},

	omni_crier = 
	{
		type = "simunit",
		name = STRINGS.GUARDS.OMNI_CRIER,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/omni_med_build",
		profile_image = "sankaku_med_2.png",								
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_omni_crier",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			armor = 1,	
            omni = true,
		},
		dropTable = 
		{
			{nil, 67}
		},
		beginnerTraits = 
		{
			armor = 0, 
		},
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = {"shootOverwatch", "overwatch", "breakDoor", "improved_heart_monitor_passive", "recon_protocol_passive", "consciousness_monitor_passive" },
		children = { itemdefs.item_npc_pistol2 },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},

	omni_killer = 
	{
		type = "simunit",
		name = STRINGS.GUARDS.OMNI_KILLER,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/sankaku_med_2_build",
		profile_image = "sankaku_med_2.png",								
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_tier2_male_sankaku",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,	
			armor = 0,	
            omni = true,

		},
		dropTable = 
		{
			{nil, 67}
		},
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = {"shootOverwatch", "overwatch", "breakDoor", "overtuned_reflexes_passive", },
		children = { itemdefs.item_npc_pistol2 },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},

	omni_protector = 
	{
		type = "simunit",
		name = STRINGS.GUARDS.OMNI_PROTECTOR,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/omni_barrier_build",
		profile_image = "sankaku_med_2.png",								
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_omni_barrier",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,

			mainframe_item = true,
			mainframe_ice = 8,
			mainframe_iceMax = 8,		
			mainframe_status = "active",	

			shieldArmor = true,
			firewallArmor = true,
			firewallShield = true,
			shields = 1,
			armor = 0,
			noTakeover = true,
			noRaiseIfIceZero = true,
			mainframe_ice_set_in_def = true,
			mainframe_no_daemon_spawn = true,

            omni = true,			
		},
		dropTable = 
		{
			{nil, 67}
		},
		beginnerTraits = 
		{
			mainframe_ice = 6, 
			mainframe_iceMax = 6, 
		},
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = {"shootOverwatch", "overwatch", "breakDoor", "mainframe_attunement_passive", },
		children = { itemdefs.item_npc_rifle },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},

	omni_soldier = 
	{
		type = "simunit",
		name = STRINGS.GUARDS.OMNI_SOLDIER,
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/omni_heavy_build",
		profile_image = "sankaku_med_2.png",								
    	onWorldTooltip = onGuardTooltip,
		kanim = "kanim_guard_omni_soldier",
		traits = util.extend( commondefs.basic_guard_traits )   
		{
			walk=true,
			heartMonitor="enabled",
			enforcer = false,
			dashSoundRange = 8,
			armor = 3,
			omniArmorGuard = true, 
            omni = true,
		},
		dropTable = 
		{
			{nil, 67}
		},
		speech = speechdefs.NPC,
		voices = {"Guard_1", "Guard_2", "Guard_3"},
		skills = {},
		abilities = {"shootOverwatch", "overwatch", "breakDoor",  },
		children = { itemdefs.item_npc_smg_omni },
		idles = DEFAULT_IDLES,
		sounds = SOUNDS.ARMORED,
		brain = "GuardBrain",
	},

}

npc_templates.dummy_guard = util.extend( npc_templates.npc_guard )
{
	dropTable = nil
}


-- Reassign key name to value table.
for id, template in pairs(npc_templates) do
	template.id = id
end


return npc_templates
