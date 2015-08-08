local util = include( "modules/util" )
local commondefs = include("sim/unitdefs/commondefs")
local speechdefs = include( "sim/speechdefs" )
local simdefs = include("sim/simdefs")
local SCRIPTS = include('client/story_scripts')
-----------------------------------------------------
-- Agent templates

local DECKARD_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Decker",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Deckard",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,
					
	wallcover = "SpySociety/Movement/foley_trench/wallcover",
	crouchcover = "SpySociety/Movement/foley_trench/crouchcover",
	fall = "SpySociety/Movement/foley_trench/fall",					
	fall_knee = "SpySociety/Movement/bodyfall_agent_knee_hardwood",
	fall_kneeframe = 9,
	fall_hand = "SpySociety/Movement/bodyfall_agent_hand_hardwood",
	fall_handframe = 20,
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 35,						
	getup = "SpySociety/Movement/foley_trench/getup",
	grab = "SpySociety/Movement/foley_trench/grab_guard",
	pin = "SpySociety/Movement/foley_trench/pin_guard",
	pinned = "SpySociety/Movement/foley_trench/pinned",	
	peek_fwd = "SpySociety/Movement/foley_trench/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_trench/peek_back",	
	move = "SpySociety/Movement/foley_trench/move",
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",
}

local SHALEM_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Shalem",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Shalem11",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,  

	wallcover = "SpySociety/Movement/foley_suit/wallcover",
	crouchcover = "SpySociety/Movement/foley_suit/crouchcover",
	fall = "SpySociety/Movement/foley_suit/fall",	
	fall_knee = "SpySociety/Movement/bodyfall_agent_knee_hardwood",
	fall_kneeframe = 9,
	fall_hand = "SpySociety/Movement/bodyfall_agent_hand_hardwood",
	fall_handframe = 20,
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 35,						
	getup = "SpySociety/Movement/foley_suit/getup",	
	grab = "SpySociety/Movement/foley_suit/grab_guard",	
	pin = "SpySociety/Movement/foley_suit/pin_guard",
	pinned = "SpySociety/Movement/foley_suit/pinned",
	peek_fwd = "SpySociety/Movement/foley_suit/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_suit/peek_back",					
	move = "SpySociety/Movement/foley_suit/move",		
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",			
}

local XU_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/DrXu",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_DrXu",
    speech="SpySociety/Agents/dialogue_player",  
    step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
    stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT, 
					
    wallcover = "SpySociety/Movement/foley_suit/wallcover",
    crouchcover = "SpySociety/Movement/foley_suit/crouchcover",
    fall = "SpySociety/Movement/foley_suit/fall",	
    fall_knee = "SpySociety/Movement/bodyfall_agent_knee_hardwood",
    fall_kneeframe = 9,
    fall_hand = "SpySociety/Movement/bodyfall_agent_hand_hardwood",
    fall_handframe = 20,
    land = "SpySociety/Movement/deathfall_agent_hardwood",
    land_frame = 35,						
    getup = "SpySociety/Movement/foley_suit/getup",	
    grab = "SpySociety/Movement/foley_suit/grab_guard",	
    pin = "SpySociety/Movement/foley_suit/pin_guard",
    pinned = "SpySociety/Movement/foley_suit/pinned",
    peek_fwd = "SpySociety/Movement/foley_suit/peek_forward",	
    peek_bwd = "SpySociety/Movement/foley_suit/peek_back",	
    move = "SpySociety/Movement/foley_suit/move",	
    hit = "SpySociety/HitResponse/hitby_ballistic_flesh",
}

local BANKS_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Banks",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Banks",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_SOFT, 

	wallcover = "SpySociety/Movement/foley_trench/wallcover",
	crouchcover = "SpySociety/Movement/foley_trench/crouchcover",
	fall = "SpySociety/Movement/foley_trench/fall",
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 16,						
	getup = "SpySociety/Movement/foley_trench/getup",	
	grab = "SpySociety/Movement/foley_trench/grab_guard",
	pin = "SpySociety/Movement/foley_trench/pin_guard",
	pinned = "SpySociety/Movement/foley_trench/pinned",
	peek_fwd = "SpySociety/Movement/foley_trench/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_trench/peek_back",	
	move = "SpySociety/Movement/foley_trench/move",
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",
}

local INTERNATIONALE_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Internationale",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Internationale",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_SOFT,

	wallcover = "SpySociety/Movement/foley_suit/wallcover", 
	crouchcover = "SpySociety/Movement/foley_suit/crouchcover",
	fall = "SpySociety/Movement/foley_suit/fall",
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 16,						
	getup = "SpySociety/Movement/foley_suit/getup",
	grab = "SpySociety/Movement/foley_suit/grab_guard",
	pin = "SpySociety/Movement/foley_suit/pin_guard",
	pinned = "SpySociety/Movement/foley_suit/pinned",
	peek_fwd = "SpySociety/Movement/foley_suit/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_suit/peek_back",
	move = "SpySociety/Movement/foley_suit/move",		
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",		
}

local NIKA_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Muratova",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Nika",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_SOFT,

	wallcover = "SpySociety/Movement/foley_suit/wallcover", 
	crouchcover = "SpySociety/Movement/foley_suit/crouchcover",
	fall = "SpySociety/Movement/foley_suit/fall",	
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 16,	
	getup = "SpySociety/Movement/foley_suit/getup",
	grab = "SpySociety/Movement/foley_suit/grab_guard",
	pin = "SpySociety/Movement/foley_suit/pin_guard",
	pinned = "SpySociety/Movement/foley_suit/pinned",
	peek_fwd = "SpySociety/Movement/foley_suit/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_suit/peek_back",
	move = "SpySociety/Movement/foley_suit/move",		
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",
}

local SHARP_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Sharp",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Sharp",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,

	wallcover = "SpySociety/Movement/foley_cyborg/wallcover", 
	crouchcover = "SpySociety/Movement/foley_cyborg/crouchcover",
	fall = "SpySociety/Movement/foley_cyborg/fall",	
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 35,	
	getup = "SpySociety/Movement/foley_cyborg/getup",
	grab = "SpySociety/Movement/foley_cyborg/grab_guard",
	pin = "SpySociety/Movement/foley_cyborg/pin_guard",
	pinned = "SpySociety/Movement/foley_cyborg/pinned",
	peek_fwd = "SpySociety/Movement/foley_cyborg/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_cyborg/peek_back",
	move = "SpySociety/Movement/foley_cyborg/move",						
	hit = "SpySociety/HitResponse/hitby_ballistic_cyborg",
}

local PRISM_SOUNDS =
{
	bio = "SpySociety/VoiceOver/Missions/Bios/Esther",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Prism",    
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_SOFT, 

	wallcover = "SpySociety/Movement/foley_trench/wallcover",
	crouchcover = "SpySociety/Movement/foley_trench/crouchcover",
	fall = "SpySociety/Movement/foley_trench/fall",
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 16,						
	getup = "SpySociety/Movement/foley_trench/getup",	
	grab = "SpySociety/Movement/foley_trench/grab_guard",
	pin = "SpySociety/Movement/foley_trench/pin_guard",
	pinned = "SpySociety/Movement/foley_trench/pinned",
	peek_fwd = "SpySociety/Movement/foley_trench/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_trench/peek_back",	
	move = "SpySociety/Movement/foley_trench/move",
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",    
}

local CENTRAL_SOUNDS = util.extend(PRISM_SOUNDS)
{
	bio = "SpySociety/VoiceOver/Missions/Bios/Central",
}

local MONST3R_SOUNDS = util.extend(DECKARD_SOUNDS)
{
	bio = "SpySociety/VoiceOver/Missions/Bios/Monst3r",
}

local default_agent_templates =
{
	stealth_1 =
	{
		type = "simunit",
        agentID = 1,
		name = STRINGS.AGENTS.DECKARD.NAME,
		fullname = STRINGS.AGENTS.DECKARD.ALT_1.FULLNAME,
		codename = STRINGS.AGENTS.DECKARD.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		file =STRINGS.AGENTS.DECKARD.FILE,
		yearsOfService = STRINGS.AGENTS.DECKARD.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.DECKARD.AGE,
		homeTown =  STRINGS.AGENTS.DECKARD.HOMETOWN,
		gender = "male",
		class = "Stealth",
		toolTip = STRINGS.AGENTS.DECKARD.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/stealth_36.png",
		profile_icon_64x64= "gui/profile_icons/stealth1_64x64.png",
		splash_image = "gui/agents/deckard_1024.png",

		team_select_img = {
			"gui/agents/team_select_1_deckard.png",
		},
		
		profile_anim = "portraits/stealth_guy_face",
		kanim = "kanim_stealth_male",
		hireText = STRINGS.AGENTS.DECKARD.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_DECKARD,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8, },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { stealth = 2},
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = DECKARD_SOUNDS,
		speech = speechdefs.stealth_1,
		blurb = STRINGS.AGENTS.DECKARD.ALT_1.BIO,
		upgrades = { "augment_deckard","item_tazer", "item_cloakingrig_deckard"},
	},

	stealth_1_a =
	{
		type = "simunit",
        agentID = 1,
		name = STRINGS.AGENTS.DECKARD.NAME,
		codename = STRINGS.AGENTS.DECKARD.ALT_2.FULLNAME,
		fullname = STRINGS.AGENTS.DECKARD.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		file = STRINGS.AGENTS.DECKARD.FILE,
		yearsOfService = STRINGS.AGENTS.DECKARD.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.DECKARD.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.DECKARD.HOMETOWN,
		gender = "male",
		class = "Stealth",
		toolTip = STRINGS.AGENTS.DECKARD.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/stealth_36.png",
		profile_icon_64x64= "gui/profile_icons/stealth2_64x64.png",
		splash_image = "gui/agents/deckard2_1024.png",

		team_select_img = {
			"gui/agents/team_select_2_deckard.png",
		},
		
		profile_anim = "portraits/stealth_guy_face",
		kanim = "kanim_stealth_male_a",
		hireText = STRINGS.AGENTS.DECKARD.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_DECKARD,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8, },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { stealth = 2},
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = DECKARD_SOUNDS,
		speech = speechdefs.stealth_1,
		blurb = STRINGS.AGENTS.DECKARD.ALT_2.BIO,
		upgrades = { "augment_decker_2", "item_tazer", "item_revolver_deckard"},
	},

	sharpshooter_1 =
	{
		type = "simunit", 
        agentID = 2,
		name = STRINGS.AGENTS.SHALEM.NAME,
		file = STRINGS.AGENTS.SHALEM.FILE,
		fullname = STRINGS.AGENTS.SHALEM.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.SHALEM.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.SHALEM.AGE,
		homeTown = STRINGS.AGENTS.SHALEM.HOMETOWN,
		gender = "male",
		class = "Sharpshooter",
		toolTip =  STRINGS.AGENTS.SHALEM.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/sharpshooter_36.png",
		profile_icon_64x64= "gui/profile_icons/shalem_64x64.png",		
		splash_image = "gui/agents/shalem_1024.png",
		team_select_img = {
			"gui/agents/team_select_1_shalem.png",
		},

		profile_anim = "portraits/sharpshooter_face",
		kanim = "kanim_sharpshooter_male",
		hireText =  STRINGS.AGENTS.SHALEM.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_SHALEM11,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { inventory = 2, },
		abilities = util.tconcat( { "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = { }, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = SHALEM_SOUNDS,
		speech = speechdefs.sharpshooter_1,
		blurb =  STRINGS.AGENTS.SHALEM.ALT_1.BIO,
		upgrades = { "augment_shalem","item_tazer_shalem", "item_light_rifle_shalem" },		
	},	


	sharpshooter_1_a =
	{
		type = "simunit",
        agentID = 2,
		name =  STRINGS.AGENTS.SHALEM.NAME,
		file =  STRINGS.AGENTS.SHALEM.FILE,
		codename = STRINGS.AGENTS.SHALEM.ALT_2.FULLNAME,
		fullname = STRINGS.AGENTS.SHALEM.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService =  STRINGS.AGENTS.SHALEM.YEARS_OF_SERVICE,
		age =  STRINGS.AGENTS.SHALEM.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.SHALEM.HOMETOWN,
		gender = "male",
		class = "Sharpshooter",
		toolTip = STRINGS.AGENTS.SHALEM.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/sharpshooter_36.png",
		profile_icon_64x64= "gui/profile_icons/shalem2_64x64.png",	
		splash_image = "gui/agents/shalem_1024_2.png",
		team_select_img = {
			"gui/agents/team_select_2_shalem.png",
		},

		profile_anim = "portraits/sharpshooter_face",
		kanim = "kanim_sharpshooter_male_a",
		hireText =  STRINGS.AGENTS.SHALEM.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_SHALEM11,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { inventory = 2, },
		abilities = util.tconcat( { "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = { }, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = SHALEM_SOUNDS,
		speech = speechdefs.sharpshooter_1,
		blurb =  STRINGS.AGENTS.SHALEM.ALT_2.BIO,
		upgrades = {"item_tazer", "item_light_pistol_ammo","item_defiblance" },
	},	


	engineer_1 =
	{
		type = "simunit",
        agentID = 3,
		name = STRINGS.AGENTS.XU.NAME,
		file = STRINGS.AGENTS.XU.FILE,
		fullname = STRINGS.AGENTS.XU.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.XU.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.XU.AGE,
		homeTown = STRINGS.AGENTS.XU.HOMETOWN,
		gender = "male",

		class = "Engineer",
		toolTip = STRINGS.AGENTS.XU.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/tony_36.png",
		profile_icon_64x64= "gui/profile_icons/tony_64x64.png",		
		splash_image = "gui/agents/tony_1024.png",
		team_select_img = {
			"gui/agents/team_select_1_tony.png",
		},		

		profile_anim = "portraits/dr_tony_face",
		kanim = "kanim_hacker_male",
		hireText = STRINGS.AGENTS.XU.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_TONY,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8, },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {},
		startingSkills = { },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = XU_SOUNDS,
		speech = speechdefs.engineer_1,
		blurb = STRINGS.AGENTS.XU.ALT_1.BIO,
		upgrades = { "augment_tony","item_tazer","item_shocktrap_tony" },	
	},	

	engineer_1_a =
	{
		type = "simunit",
        agentID = 3,
		name = STRINGS.AGENTS.XU.NAME,
		file = STRINGS.AGENTS.XU.FILE,
		codename = STRINGS.AGENTS.XU.ALT_2.FULLNAME,
		fullname = STRINGS.AGENTS.XU.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService = STRINGS.AGENTS.XU.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.XU.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.XU.HOMETOWN,
		gender = "male",

		class = "Engineer",
		toolTip = STRINGS.AGENTS.XU.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/tony_36.png",
		profile_icon_64x64= "gui/profile_icons/tony2_64x64.png",		
		splash_image = "gui/agents/tony2_1024.png",
		team_select_img = {
			"gui/agents/team_select_2_tony.png",
		},		

		profile_anim = "portraits/dr_tony_face",
		kanim = "kanim_hacker_male_a",
		hireText = STRINGS.AGENTS.XU.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_TONY,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8, },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {},
		startingSkills = { },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = XU_SOUNDS,
		speech = speechdefs.engineer_1,
		blurb = STRINGS.AGENTS.XU.ALT_2.BIO,
		upgrades = { "augment_tony_2","item_tazer","item_emp_pack_tony"},	
	},		

	stealth_2 =
	{
		type = "simunit",
        agentID = 4,
		name = STRINGS.AGENTS.BANKS.NAME,
		file =  STRINGS.AGENTS.BANKS.FILE,
		fullname = STRINGS.AGENTS.BANKS.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.BANKS.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.BANKS.AGE,
		homeTown = STRINGS.AGENTS.BANKS.HOMETOWN,
		gender = "female",
		class = "Stealth",
		toolTip = STRINGS.AGENTS.BANKS.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/lady_stealth_36.png",
		profile_icon_64x64= "gui/profile_icons/banks_64x64.png",
		splash_image = "gui/agents/banks_1024.png",
		team_select_img = {
			"gui/agents/team_select_1_banks.png",
		},

		profile_anim = "portraits/lady_stealth_face",
		kanim = "kanim_female_stealth_2",
		hireText = STRINGS.AGENTS.BANKS.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_BANKS,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8 },	--passiveKey = simdefs.DOOR_KEYS.SECURITY
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { anarchy = 2 },
		abilities = util.tconcat( { "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ), -- "stealth"
		children = { }, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = BANKS_SOUNDS,
		speech = speechdefs.stealth_2,
		blurb = STRINGS.AGENTS.BANKS.ALT_1.BIO,
		upgrades = { "augment_banks","item_tazer", "item_paralyzer_banks" },
	},

	stealth_2_a =
	{
		type = "simunit",
        agentID = 4,
		name = STRINGS.AGENTS.BANKS.NAME,
		file =  STRINGS.AGENTS.BANKS.FILE,
		codename = STRINGS.AGENTS.BANKS.ALT_2.FULLNAME,
		fullname = STRINGS.AGENTS.BANKS.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService = STRINGS.AGENTS.BANKS.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.BANKS.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.BANKS.HOMETOWN,
		gender = "female",
		class = "Stealth",
		toolTip = STRINGS.AGENTS.BANKS.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/lady_stealth_36.png",
		profile_icon_64x64= "gui/profile_icons/banks2_64x64.png",
		splash_image = "gui/agents/banks2_1024.png",
		team_select_img = {
			"gui/agents/team_select_1_banks2.png",
		},

		profile_anim = "portraits/lady_stealth_face",
		kanim = "kanim_female_stealth_2_a",
		hireText = STRINGS.AGENTS.BANKS.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_BANKS,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8 },	--passiveKey = simdefs.DOOR_KEYS.SECURITY
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { anarchy = 2 },
		abilities = util.tconcat( { "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ), -- "stealth"
		children = { }, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = BANKS_SOUNDS,
		speech = speechdefs.stealth_2,
		blurb = STRINGS.AGENTS.BANKS.ALT_2.BIO,
		upgrades = { "item_dartgun", "item_econchip_banks" },
	},	

	engineer_2 =
	{
		type = "simunit",
        agentID = 5,
		name = STRINGS.AGENTS.INTERNATIONALE.NAME,
		file = STRINGS.AGENTS.INTERNATIONALE.FILE,
		fullname = STRINGS.AGENTS.INTERNATIONALE.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.INTERNATIONALE.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.INTERNATIONALE.AGE,
		homeTown = STRINGS.AGENTS.INTERNATIONALE.HOMETOWN,
		gender = "female",
		class = "Engineer",
		toolTip = STRINGS.AGENTS.INTERNATIONALE.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/lady_tech_36.png",
		profile_icon_64x64= "gui/profile_icons/engineer2_64x64.png",
		splash_image = "gui/agents/red_1024.png",

		team_select_img = {
			"gui/agents/team_select_1_red.png",
		},


		profile_anim = "portraits/lady_tech_face",
		kanim = "kanim_female_engineer_2",
		hireText = STRINGS.AGENTS.INTERNATIONALE.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_INTERNATIONALE,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 2},
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = INTERNATIONALE_SOUNDS,
		speech = speechdefs.engineer_2,
		blurb = STRINGS.AGENTS.INTERNATIONALE.ALT_1.BIO,
		upgrades = { "augment_international_v1", "item_tazer" },
	},

	engineer_2_a =
	{
		type = "simunit",
        agentID = 5,
		name = STRINGS.AGENTS.INTERNATIONALE.NAME,
		file = STRINGS.AGENTS.INTERNATIONALE.FILE,
		codename = STRINGS.AGENTS.INTERNATIONALE.ALT_2.FULLNAME,
		fullname = STRINGS.AGENTS.INTERNATIONALE.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE, 
		yearsOfService = STRINGS.AGENTS.INTERNATIONALE.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.INTERNATIONALE.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.INTERNATIONALE.HOMETOWN,
		gender = "female",
		class = "Engineer",
		toolTip = STRINGS.AGENTS.INTERNATIONALE.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/lady_tech_36.png",
		profile_icon_64x64= "gui/profile_icons/engineer2a_64x64.png",
		splash_image = "gui/agents/red2_1024.png",

		team_select_img = {
			"gui/agents/team_select_2_red.png",
		},


		profile_anim = "portraits/lady_tech_face",
		kanim = "kanim_female_engineer_2_a",
		hireText = STRINGS.AGENTS.INTERNATIONALE.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_INTERNATIONALE,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 2},
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
        children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = INTERNATIONALE_SOUNDS,
		speech = speechdefs.engineer_2,
		blurb = STRINGS.AGENTS.INTERNATIONALE.ALT_2.BIO,
		upgrades = { "augment_international_2", "item_tazer" },
	},		

	sharpshooter_2 =
	{
		type = "simunit",
        agentID = 6,
		name =  STRINGS.AGENTS.NIKA.NAME,
		file =  STRINGS.AGENTS.NIKA.FILE,
		fullname =  STRINGS.AGENTS.NIKA.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService =  STRINGS.AGENTS.NIKA.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.NIKA.AGE,
		homeTown = STRINGS.AGENTS.NIKA.HOMETOWN,
		gender = "female",
		class = "Sharpshooter",
		toolTip = STRINGS.AGENTS.NIKA.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,

		profile_icon_36x36= "gui/profile_icons/lady_sharpshooter_36.png",
		profile_icon_64x64= "gui/profile_icons/nika_64x64.png",
		splash_image = "gui/agents/nika_1024.png",
		profile_anim = "portraits/lady_sharpshooter_face",	
		team_select_img = {
			"gui/agents/team_select_1_nika.png"
		},

		kanim = "kanim_female_sharpshooter_2",
		hireText = STRINGS.AGENTS.NIKA.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_NIKA,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { shields = 0, shieldsMax = 0, mp=8, mpMax = 8 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to te upgrades table in createDefaultAgency()
		sounds = NIKA_SOUNDS,
		speech = speechdefs.sharpshooter_2,
		blurb = STRINGS.AGENTS.NIKA.ALT_1.BIO,
		upgrades = { "augment_nika","item_power_tazer_nika" },	
	},

	sharpshooter_2_a =
	{
		type = "simunit",
        agentID = 6,
		name =  STRINGS.AGENTS.NIKA.NAME,
		file =  STRINGS.AGENTS.NIKA.FILE,
		fullname =  STRINGS.AGENTS.NIKA.ALT_1.FULLNAME,
		codename = STRINGS.AGENTS.NIKA.ALT_2.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService =  STRINGS.AGENTS.NIKA.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.NIKA.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.NIKA.HOMETOWN,
		gender = "female",
		class = "Sharpshooter",
		toolTip = STRINGS.AGENTS.NIKA.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,

		profile_icon_36x36= "gui/profile_icons/lady_sharpshooter_36.png",
		profile_icon_64x64= "gui/profile_icons/nika2_64x64.png",
		splash_image = "gui/agents/nika2_1024.png",
		profile_anim = "portraits/lady_sharpshooter_face",	
		team_select_img = {
			"gui/agents/team_select_1_nika2.png"
		},

		kanim = "kanim_female_sharpshooter_2_a",
		hireText = STRINGS.AGENTS.NIKA.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_NIKA,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { shields = 0, shieldsMax = 0, mp=8, mpMax = 8 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = NIKA_SOUNDS,
		speech = speechdefs.sharpshooter_2,
		blurb = STRINGS.AGENTS.NIKA.ALT_2.BIO,
		upgrades = { "augment_nika_2", "item_tazer" },	
	},


	cyborg_1 =
	{
		type = "simunit",
        agentID = 7,
		name =  STRINGS.AGENTS.SHARP.NAME,
		file =  STRINGS.AGENTS.SHARP.FILE,
		fullname =  STRINGS.AGENTS.SHARP.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService =  STRINGS.AGENTS.SHARP.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.SHARP.AGE,
		homeTown = STRINGS.AGENTS.SHARP.HOMETOWN,
		gender = "male",
		class = "Cyborg",
		toolTip = STRINGS.AGENTS.SHARP.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,

		profile_icon_36x36= "gui/profile_icons/sharp_36.png",
		profile_icon_64x64= "gui/profile_icons/sharp_64x64.png",
		splash_image = "gui/agents/sharp_1024.png",
		profile_anim = "portraits/robo_alex_face",	
		team_select_img = {
			"gui/agents/team_select_1_sharp.png"
		},

		kanim = "kanim_cyborg_male",
		hireText = STRINGS.AGENTS.SHARP.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_SHARP,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { shields = 0, shieldsMax = 0, mp=8, mpMax = 8, augmentMaxSize=6 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 2 },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = SHARP_SOUNDS,
		speech = speechdefs.cyborg_1,
		blurb = STRINGS.AGENTS.SHARP.ALT_1.BIO,
		upgrades = {  "augment_sharp_1","item_tazer" },	
	},
	cyborg_1_a =
	{

		type = "simunit",
        agentID = 7,
		name =  STRINGS.AGENTS.SHARP.NAME,
		file =  STRINGS.AGENTS.SHARP.FILE,
		fullname =  STRINGS.AGENTS.SHARP.ALT_1.FULLNAME,
		codename = STRINGS.AGENTS.SHARP.ALT_2.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService =  STRINGS.AGENTS.SHARP.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.SHARP.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.SHARP.HOMETOWN,
		gender = "male",
		class = "Cyborg",
		toolTip = STRINGS.AGENTS.SHARP.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,

		profile_icon_36x36= "gui/profile_icons/sharp2_36.png",
		profile_icon_64x64= "gui/profile_icons/sharp2_64x64.png",
		splash_image = "gui/agents/sharp2_1024.png",
		profile_anim = "portraits/robo_alex_face",	
		team_select_img = {
			"gui/agents/team_select_1_sharp2.png"
		},

		kanim = "kanim_cyborg_male_a",
		hireText = STRINGS.AGENTS.SHARP.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_SHARP,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { shields = 0, shieldsMax = 0, mp=8, mpMax = 8, augmentMaxSize=6 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 2 },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = SHARP_SOUNDS,
		speech = speechdefs.cyborg_1,
		blurb = STRINGS.AGENTS.SHARP.ALT_2.BIO,
		upgrades = {  "augment_sharp_2","item_tazer" },	
	},	

	disguise_1 =
	{
		type = "simunit",
        agentID = 8,
		name =  STRINGS.AGENTS.PRISM.NAME,
		file =  STRINGS.AGENTS.PRISM.FILE,
		fullname =  STRINGS.AGENTS.PRISM.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService =  STRINGS.AGENTS.PRISM.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.PRISM.AGE,
		homeTown = STRINGS.AGENTS.PRISM.HOMETOWN,
		gender = "female",
		class = "Disguise",
		toolTip = STRINGS.AGENTS.PRISM.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,

		profile_icon_36x36= "gui/profile_icons/prism_36.png",
		profile_icon_64x64= "gui/profile_icons/prism1_64x64.png",
		splash_image = "gui/agents/prism_1024.png",
		profile_anim = "portraits/prism_face",	
		team_select_img = {
			"gui/agents/team_select_1_prism.png"
		},

		kanim = "kanim_disguise_female",
		hireText = STRINGS.AGENTS.PRISM.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_PRISM,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { shields = 0, shieldsMax = 0, mp=8, mpMax = 8},
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {},		
		startingSkills = { anarchy = 2 },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = PRISM_SOUNDS,
		speech = speechdefs.disguise_1,
		blurb = STRINGS.AGENTS.PRISM.ALT_1.BIO,
		upgrades = { "augment_prism_2","item_tazer" },	
	},

	disguise_1_a =
	{
		type = "simunit",
        agentID = 8,
		name =  STRINGS.AGENTS.PRISM.NAME,
		file =  STRINGS.AGENTS.PRISM.FILE,
		fullname =  STRINGS.AGENTS.PRISM.ALT_1.FULLNAME,
		codename = STRINGS.AGENTS.PRISM.ALT_2.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService =  STRINGS.AGENTS.PRISM.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.PRISM.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.PRISM.HOMETOWN,
		gender = "female",
		class = "Disguise",
		toolTip = STRINGS.AGENTS.PRISM.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,

		profile_icon_36x36= "gui/profile_icons/prism2_36.png",
		profile_icon_64x64= "gui/profile_icons/prism2_64x64.png",
		splash_image = "gui/agents/prism2_1024.png",
		profile_anim = "portraits/prism_face",	
		team_select_img = {
			"gui/agents/team_select_1_prism2.png"
		},

		kanim = "kanim_disguise_female_a",
		hireText = STRINGS.AGENTS.PRISM.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_PRISM,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { shields = 0, shieldsMax = 0, mp=8, mpMax = 8, augmentMaxSize = 0  },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {},		
		startingSkills = { anarchy = 2 },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = PRISM_SOUNDS,
		speech = speechdefs.disguise_1,
		blurb = STRINGS.AGENTS.PRISM.ALT_2.BIO,
		upgrades = { "item_prism_1", "item_icebreaker" },	
	},	

	tutorial =
	{
		type = "simunit",
        agentID = 0,
		name =  STRINGS.AGENTS.DECKARD.NAME,
		fullname = STRINGS.AGENTS.DECKARD.ALT_1.FULLNAME,
		file = STRINGS.AGENTS.DECKARD.FILE,
		yearsOfService = STRINGS.AGENTS.DECKARD.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.DECKARD.AGE,
		homeTown = STRINGS.AGENTS.DECKARD.HOMETOWN,
		gender = "male",
		class = "Stealth",
		toolTip = "Speedy.",
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/stealth_36.png",
		profile_icon_64x64= "gui/profile_icons/stealth1_64x64.png",
		splash_image = "gui/agents/deckard_1024.png",
		profile_anim = "portraits/stealth_guy_face",

		team_select_img = {"gui/agents/team_select_1_deckard.png",},
		

		kanim = "kanim_stealth_male",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8 },	
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),		
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = { 	
					speech="SpySociety/Agents/dialogue_player",  
					step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
					stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,
					
					wallcover = "SpySociety/Movement/foley_trench/wallcover",
					crouchcover = "SpySociety/Movement/foley_trench/crouchcover",
					fall = "SpySociety/Movement/foley_trench/fall",	
					land = "SpySociety/Movement/deathfall_agent_hardwood",
					land_frame = 35,						
					getup = "SpySociety/Movement/foley_trench/getup",
					grab = "SpySociety/Movement/foley_trench/grab_guard",	
					pin = "SpySociety/Movement/foley_trench/pin_guard",
					pinned = "SpySociety/Movement/foley_trench/pinned",	
					peek_fwd = "SpySociety/Movement/foley_trench/peek_forward",	
					peek_bwd = "SpySociety/Movement/foley_trench/peek_back",
					move = "SpySociety/Movement/foley_trench/move",
				},-- 
		speech = speechdefs.stealth_1,
		blurb = STRINGS.AGENTS.DECKARD.ALT_1.BIO,
		upgrades = {},
	},	

	--NPCs
	hostage =
	{
		type = "simunit",
		name = STRINGS.AGENTS.HOSTAGE.NAME,
		fullname = STRINGS.AGENTS.HOSTAGE.ALT_1.FULLNAME,
		yearsOfService = STRINGS.AGENTS.HOSTAGE.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.HOSTAGE.AGE,
		homeTown = STRINGS.AGENTS.HOSTAGE.HOMETOWN,
		toolTip = STRINGS.AGENTS.HOSTAGE.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/courrier_36.png",
		splash_image = "gui/agents/agentDeckard_768.png",
		profile_anim = "portraits/courier_face",
		kanim = "kanim_courier_male",
		gender = "male",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { inventoryMaxSize = 1, mp=5, mpMax =5, noUpgrade = true, hostage = true, kill_trigger = "hostage_dead", vitalSigns=10, rescued=true, canBeCritical=false },	
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		abilities =  commondefs.DEFAULT_AGENT_ABILITIES ,
		sounds = { 
					speech="SpySociety/Agents/dialogue_player",  
					step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
					stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,
					
					wallcover = "SpySociety/Movement/foley_suit/wallcover",
					crouchcover = "SpySociety/Movement/foleyfoley_suit_trench/crouchcover",
					fall = "SpySociety/Movement/foley_suit/fall",	
					land = "SpySociety/Movement/deathfall_agent_hardwood",
					land_frame = 35,						
					getup = "SpySociety/Movement/foley_suit/getup",
					grab = "SpySociety/Movement/foley_suit/grab_guard",
					pin = "SpySociety/Movement/foley_suit/pin_guard",
					pinned = "SpySociety/Movement/foley_suit/pinned",	
					peek_fwd = "SpySociety/Movement/foley_suit/peek_forward",	
					peek_bwd = "SpySociety/Movement/foley_suit/peek_back",				
					move = "SpySociety/Movement/foley_suit/move",
				},--
		speech = speechdefs.stealth_1,
		blurb = "",
	},	

	--stating monst3r, instead of the on given to you at the end of the game
	monst3r_pc =
	{
		type = "simunit",
        agentID = 100,
		name = STRINGS.AGENTS.MONST3R.NAME,
		fullname = STRINGS.AGENTS.MONST3R.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.MONST3R.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.MONST3R.AGE,
		homeTown =STRINGS.AGENTS.MONST3R.HOMETOWN,
		toolTip = STRINGS.AGENTS.MONST3R.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/monst3r_36.png",
		profile_icon_64x64= "gui/profile_icons/monst3r_64x64.png",		
		gender = "male",
		splash_image = "gui/agents/monst3r_1024.png",
		profile_anim = "portraits/monst3r_face",
		team_select_img = {
			"gui/agents/team_select_1_monst3r.png",
		},
		lockedText = STRINGS.UI.TEAM_SELECT.UNLOCK_CENTRAL_MONSTER,
		kanim = "kanim_monst3r",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { inventoryMaxSize = 3, mp=8, mpMax=8, noUpgrade = true, monst3rUnit = true, monst3r = true },	
		tags = { "monst3r" },
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 3 },
		sounds = MONST3R_SOUNDS,
		speech = speechdefs.monst3r,
		hireText = STRINGS.AGENTS.MONST3R.RESCUED,
		blurb = STRINGS.AGENTS.MONST3R.ALT_1.BIO,
		upgrades = { "augment_monst3r", "item_monst3r_gun" },	
	},	

	--stating monst3r, instead of the on given to you at the end of the game
	central_pc =
	{
		type = "simunit",
		name = STRINGS.AGENTS.CENTRAL.NAME,
        agentID = 108,
		fullname = STRINGS.AGENTS.CENTRAL.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.CENTRAL.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.CENTRAL.AGE,
		homeTown = STRINGS.AGENTS.CENTRAL.HOMETOWN,
		toolTip = STRINGS.AGENTS.CENTRAL.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/central_36.png",
		profile_icon_64x64= "gui/profile_icons/central_64x64.png",	
		splash_image = "gui/agents/central_1024.png",
		profile_anim = "portraits/central_face",
		gender = "female",
		team_select_img = {
			"gui/agents/team_select_1_central.png",
		},
		kanim = "kanim_central",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { inventoryMaxSize = 3, mp=8, mpMax=8, noUpgrade = true, central=true  },	
		tags = { "central" },
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { anarchy = 3 },
		sounds = CENTRAL_SOUNDS,
		speech = speechdefs.central,
		blurb = STRINGS.AGENTS.CENTRAL.ALT_1.BIO,
		hireText = STRINGS.AGENTS.CENTRAL.RESCUED,
		lockedText = STRINGS.UI.TEAM_SELECT.UNLOCK_CENTRAL_MONSTER,
		upgrades = { "augment_central", "item_tazer" },	
	},	

	monst3r =
	{
		type = "simunit",
        agentID = 99,
		name = STRINGS.AGENTS.MONST3R.NAME,
		fullname = STRINGS.AGENTS.MONST3R.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.MONST3R.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.MONST3R.AGE,
		homeTown =STRINGS.AGENTS.MONST3R.HOMETOWN,
		toolTip = STRINGS.AGENTS.MONST3R.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/monst3r_36.png",
		profile_icon_64x64= "gui/profile_icons/monst3r_64x64.png",		
		gender = "male",
		splash_image = "gui/agents/monst3r_1024.png",
		profile_anim = "portraits/monst3r_face",
		team_select_img = {
			"gui/agents/team_select_1_monst3r.png",
		},
		kanim = "kanim_monst3r",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { inventoryMaxSize = 3, mp=8, mpMax=8, noUpgrade = true, monst3rUnit = true, monst3r = true },	
        tags = { "monst3r" },
		children =  { "augment_monst3r", "item_monst3r_gun" },	
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 3, stealth = 1 },
		sounds = MONST3R_SOUNDS,
		speech = speechdefs.monst3r,
		blurb = STRINGS.AGENTS.MONST3R.ALT_1.BIO,
	},	

	central =
	{
		type = "simunit",
		name = STRINGS.AGENTS.CENTRAL.NAME,
        agentID = 107,
		fullname = STRINGS.AGENTS.CENTRAL.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.CENTRAL.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.CENTRAL.AGE,
		homeTown = STRINGS.AGENTS.CENTRAL.HOMETOWN,
		toolTip = STRINGS.AGENTS.CENTRAL.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/central_36.png",
		profile_icon_64x64= "gui/profile_icons/central_64x64.png",	
		splash_image = "gui/agents/central_1024.png",
		profile_anim = "portraits/central_face",
		gender = "female",
		team_select_img = {
			"gui/agents/team_select_1_central.png",
		},
		kanim = "kanim_central",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { inventoryMaxSize = 3, mp=8, mpMax=8, noUpgrade = true, central=true  },	
        tags = { "central" },
		children = { "augment_central", "item_tazer" },	
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { anarchy = 4, stealth = 1 },
		sounds = CENTRAL_SOUNDS,
		speech = speechdefs.central,
		blurb = STRINGS.AGENTS.CENTRAL.ALT_1.BIO,
	},	

	--NPCs
	prisoner =
	{
		type = "simunit",
		name = STRINGS.AGENTS.PRISONER.NAME,
		fullname = STRINGS.AGENTS.PRISONER.ALT_1.FULLNAME,
		yearsOfService = STRINGS.AGENTS.PRISONER.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.PRISONER.AGE,
		hometown = STRINGS.AGENTS.PRISONER.HOMETOWN,
		toolTip = STRINGS.AGENTS.PRISONER.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/prisoner_64.png",
		splash_image = "gui/agents/agentDeckard_768.png",
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/portrait_prisoner_build",		
		kanim = "kanim_prisoner_male",
		gender = "male",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { cant_abandon = true, inventoryMaxSize = 1, mp=6, mpMax=6, noUpgrade = true, rescued=true},	
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		sounds = { 	
					speech="SpySociety/Agents/dialogue_player",  
					step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
					stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,
					
					wallcover = "SpySociety/Movement/foley_suit/wallcover",
					crouchcover = "SpySociety/Movement/foley_suit/crouchcover",
					fall = "SpySociety/Movement/foley_suit/fall",	
					land = "SpySociety/Movement/deathfall_agent_hardwood",
					land_frame = 35,						
					getup = "SpySociety/Movement/foley_suit/getup",
					grab = "SpySociety/Movement/foley_suit/grab_guard",
					pin = "SpySociety/Movement/foley_suit/pin_guard",
					pinned = "SpySociety/Movement/foley_suit/pinned",	
					peek_fwd = "SpySociety/Movement/foley_suit/peek_forward",	
					peek_bwd = "SpySociety/Movement/foley_suit/peek_back",				
					move = "SpySociety/Movement/foley_suit/move",
				},--
		speech = speechdefs.prisoner,
		blurb = "",
	},	

	hostage_2 =
	{
		type = "simunit",
		name = STRINGS.AGENTS.HOSTAGE_2.NAME,
		fullname = STRINGS.AGENTS.HOSTAGE_2.ALT_1.FULLNAME,
		yearsOfService = STRINGS.AGENTS.HOSTAGE_2.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.HOSTAGE_2.AGE,
		homeTown = STRINGS.AGENTS.HOSTAGE_2.HOMETOWN,
		toolTip = STRINGS.AGENTS.HOSTAGE_2.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/prisoner_64.png",
		splash_image = "gui/agents/agentDeckard_768.png",
		profile_anim = "portraits/portrait_animation_template",
		profile_build = "portraits/portrait_prisoner_build",		
		kanim = "kanim_business_man",
		gender = "male",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { cant_abandon = true, inventoryMaxSize = 1, mp=8, mpMax =8, noUpgrade = true , canBeCritical=false},	
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		abilities =  commondefs.DEFAULT_AGENT_ABILITIES ,
		sounds = { 	
					speech="SpySociety/Agents/dialogue_player",  
					step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
					stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,
					
					wallcover = "SpySociety/Movement/foley_suit/wallcover",
					crouchcover = "SpySociety/Movement/foley_suit/crouchcover",
					fall = "SpySociety/Movement/foley_suit/fall",	
					land = "SpySociety/Movement/deathfall_agent_hardwood",
					land_frame = 35,						
					getup = "SpySociety/Movement/foley_suit/getup",
					grab = "SpySociety/Movement/foley_suit/grab_guard",
					pin = "SpySociety/Movement/foley_suit/pin_guard",
					pinned = "SpySociety/Movement/foley_suit/pinned",	
					peek_fwd = "SpySociety/Movement/foley_suit/peek_forward",	
					peek_bwd = "SpySociety/Movement/foley_suit/peek_back",					
					move = "SpySociety/Movement/foley_suit/move",
				},--
		speech = speechdefs.prisoner,
		blurb = "",
	},			

}


local agent_templates = {}

function ResetAgentDefs()
	log:write("ResetAgentDefs()")	
	util.tclear(agent_templates)
	util.tmerge(agent_templates, default_agent_templates)
end

ResetAgentDefs()

return agent_templates
