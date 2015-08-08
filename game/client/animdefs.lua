----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local cdefs = include( "client_defs" )
local util = include( "client_util" )
local commonanims = include("common_anims")
local commondefs = include( "sim/unitdefs/commondefs" )

local AGENT_ANIMS = commondefs.AGENT_ANIMS
local GUARD_ANIMS = commondefs.GUARD_ANIMS
local HOSTAGE_ANIMS = commondefs.HOSTAGE_ANIMS
local DRONE_ANIMS = commondefs.DRONE_ANIMS
local FLOAT_DRONE_ANIMS = commondefs.FLOAT_DRONE_ANIMS
local FLOAT_DRONE_TANK_ANIMS = commondefs.FLOAT_DRONE_TANK_ANIMS
local Layer = commondefs.Layer
local BoundType = commondefs.BoundType

-------------------------------------------------------------------
-- Data for anim definitions.

local animdefs =
{

	kanim_stealth_male =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_deckard.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/agent_deckard.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	
			"data/anims/characters/anims_male/stealth_basic_a_04.abld",				
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_deckard.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},
		peekBranchSet = 1,
	},

	kanim_stealth_male_a =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_deckard.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/agent_deckard2.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	
			"data/anims/characters/anims_male/stealth_basic_a_04.abld",				
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_deckard2.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},
		peekBranchSet = 1,
	},

	kanim_hacker_male =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_tony.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/agent_tony.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",		 
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_tony.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = util.tconcat(
			{"data/anims/characters/anims_male/shared_basic_b_01.adef"},
			commonanims.male.anims_1h,
			commonanims.male.anims,
			commonanims.male.attacks_1h,
			commonanims.male.tech,
			{"data/anims/characters/anims_male/tech_basic_a_03.adef"}),
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,
	},	

	kanim_hacker_male_a =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_tony.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/agent_tony2.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",		 
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_tony2.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = util.tconcat(
			{"data/anims/characters/anims_male/shared_basic_b_01.adef"},
			commonanims.male.anims_1h,
			commonanims.male.anims,
			commonanims.male.attacks_1h,
			commonanims.male.tech,
			{"data/anims/characters/anims_male/tech_basic_a_03.adef"}),
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,
	},	

	
	kanim_sharpshooter_male =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_shalem.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/agent_shalem.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_shalem.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,	
	},

	kanim_sharpshooter_male_a =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_shalem.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/agent_shalem2.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_shalem2.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,	
	},


	kanim_female_engineer_2 =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_international.abld",
		},
		build = 
		{ 			
			"data/anims/characters/anims_female/shared_female_hits_01.abld",		 
			"data/anims/characters/anims_female/shared_female_attacks_a_01.abld",	
			"data/anims/characters/agents/agent_international.abld",
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_international.abld",
		},
		grp_anims = commonanims.female.grp_anims,

		anims = commonanims.female.default_anims_unarmed,
		anims_1h = commonanims.female.default_anims_1h,
		anims_2h = commonanims.female.default_anims_2h,

		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet =  2,
	},

	kanim_female_engineer_2_a =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_international.abld",
		},
		build = 
		{ 			
			"data/anims/characters/anims_female/shared_female_hits_01.abld",		 
			"data/anims/characters/anims_female/shared_female_attacks_a_01.abld",		
			"data/anims/characters/agents/agent_international2.abld",			
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_international2.abld",
		},
		grp_anims = commonanims.female.grp_anims,

		anims = commonanims.female.default_anims_unarmed,
		anims_1h = commonanims.female.default_anims_1h,
		anims_2h = commonanims.female.default_anims_2h,

		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet =  2,
	},

	kanim_female_stealth_2 =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_banks.abld",
		},
		build = 
		{ 			
			"data/anims/characters/anims_female/shared_female_hits_01.abld",		 
			"data/anims/characters/anims_female/shared_female_attacks_a_01.abld",	
			"data/anims/characters/agents/agent_banks.abld",
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_banks.abld",
		},
		grp_anims = commonanims.female.grp_anims,

		anims = commonanims.female.default_anims_unarmed,
		anims_1h = commonanims.female.default_anims_1h,
		anims_2h = commonanims.female.default_anims_2h,

		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,
	},

	kanim_female_stealth_2_a =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_banks.abld",
		},
		build = 
		{ 
			
			"data/anims/characters/anims_female/shared_female_hits_01.abld",		 
			"data/anims/characters/anims_female/shared_female_attacks_a_01.abld",	
			"data/anims/characters/agents/agent_banks2.abld",			
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_banks.abld",
		},
		grp_anims = commonanims.female.grp_anims,

		anims = commonanims.female.default_anims_unarmed,
		anims_1h = commonanims.female.default_anims_1h,
		anims_2h = commonanims.female.default_anims_2h,

		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,
	},


	kanim_female_sharpshooter_2 =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_nika.abld",
		},
		build = 
		{ 			
			"data/anims/characters/anims_female/shared_female_hits_01.abld",		 
			"data/anims/characters/anims_female/shared_female_attacks_a_01.abld",	
			"data/anims/characters/agents/agent_nika.abld",			
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_nika.abld",
		},
		grp_anims = commonanims.female.grp_anims,

		anims = commonanims.female.default_anims_unarmed,
		anims_1h = commonanims.female.default_anims_1h,
		anims_2h = commonanims.female.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,
	},

	kanim_female_sharpshooter_2_a =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_nika.abld",
		},
		build = 
		{ 			
			"data/anims/characters/anims_female/shared_female_hits_01.abld",		 
			"data/anims/characters/anims_female/shared_female_attacks_a_01.abld",	
			"data/anims/characters/agents/agent_nika2.abld",			
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_nika.abld",
		},
		grp_anims = commonanims.female.grp_anims,

		anims = commonanims.female.default_anims_unarmed,
		anims_1h = commonanims.female.default_anims_1h,
		anims_2h = commonanims.female.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,
	},

	kanim_cyborg_male =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_sharp.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/agent_sharp.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_sharp.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,	
	},

	kanim_cyborg_male_a =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_sharp.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/agent_sharp2.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_sharp2.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,	
	},	

	kanim_disguise_female =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_prism.abld",
		},
		build = 
		{ 
			"data/anims/characters/anims_female/shared_female_hits_01.abld",		 
			"data/anims/characters/anims_female/shared_female_attacks_a_01.abld",	
			"data/anims/characters/agents/agent_prism.abld",
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_prism.abld",
		},
		grp_anims = commonanims.female.grp_anims,

		anims = commonanims.female.default_anims_unarmed,
		anims_1h = commonanims.female.default_anims_1h,
		anims_2h = commonanims.female.default_anims_2h,

		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,
	},

	kanim_disguise_female_a =
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_prism.abld",
		},
		build = 
		{ 
			"data/anims/characters/anims_female/shared_female_hits_01.abld",		 
			"data/anims/characters/anims_female/shared_female_attacks_a_01.abld",	
			"data/anims/characters/agents/agent_prism2.abld",
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_prism2.abld",
		},
		grp_anims = commonanims.female.grp_anims,

		anims = commonanims.female.default_anims_unarmed,
		anims_1h = commonanims.female.default_anims_1h,
		anims_2h = commonanims.female.default_anims_2h,

		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		peekBranchSet = 1,
	},
-----------------------------------------------------------------------

	kanim_guard_male =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_neutral/guard.abld",  "data/anims/characters/corp_FTM/ftm_med_overlay.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_FTM/ftm_med.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_neutral/grp_guard.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_guard_male_ftm =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_FTM/ftm_med.abld", 
		},
		build = 
		{ 
			"data/anims/characters/corp_FTM/ftm_med.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_FTM/grp_ftm_med.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},	

	kanim_guard_grenade_ftm =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld", --"data/anims/characters/corp_FTM/ftm_grenadier.abld", 
		},
		build = 
		{ 
			"data/anims/characters/corp_FTM/ftm_grenadier.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_FTM/grp_ftm_grenadier.abld",
		},	
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},


	kanim_guard_tier2_male_ftm =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld", --"data/anims/characters/corp_FTM/ftm_med_02.abld", 
		},
		build = 
		{ 
			"data/anims/characters/corp_FTM/ftm_med_02.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_FTM/grp_ftm_med_02.abld",
		},	
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_barrier_guard_ftm =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_FTM/ftm_barrier.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_FTM/ftm_barrier.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_FTM/grp_ftm_barrier.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},	


	kanim_guard_male_plastek =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_PLAS/plastech_med.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_PLAS/plastech_med.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_PLAS/grp_plastech_med.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,	
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		

	},



	kanim_guard_tier2_male_plastek =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_PLAS/plastech_med_2.abld", 
		},
		build = 
		{ 
			"data/anims/characters/corp_PLAS/plastech_med_2.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_PLAS/grp_plastech_med_2.abld",
		},	
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_psi_male_plastek =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_PLAS/plastech_psi.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_PLAS/plastech_psi.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_PLAS/grp_plastech_psi.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		

	},

	kanim_ghost_male_plastek =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_PLAS/plastech_cloak.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_PLAS/plastech_cloak.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_PLAS/grp_plastech_cloak.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},	


	kanim_guard_male_sankaku =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_SK/sankaku_med.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_SK/sankaku_med.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_SK/grp_sankaku_med.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		

	},



	kanim_guard_tier2_male_sankaku =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_SK/sankaku_med_2.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_SK/sankaku_med_2.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_SK/grp_sankaku_med_2.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_guard_omni_soldier  =
	{
		wireframe =
		{
			"data/anims/characters/corp_OMNI/overlay_omni_med_01.abld",--"data/anims/characters/corp_SK/sankaku_med_2.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_OMNI/omni_heavy.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_OMNI/grp_omni_heavy.abld",
		},	
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_guard_omni_barrier  =
	{
		wireframe =
		{
			"data/anims/characters/corp_OMNI/overlay_omni_med_01.abld",--"data/anims/characters/corp_SK/sankaku_med_2.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_OMNI/omni_barrier.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_OMNI/grp_omni_barrier.abld",
		},	
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_guard_omni_crier  =
	{
		wireframe =
		{
			"data/anims/characters/corp_OMNI/overlay_omni_med_01.abld",--"data/anims/characters/corp_SK/sankaku_med_2.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_OMNI/omni_med_01.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_OMNI/grp_omni_med_01.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_guard_male_ko =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_KO/ko_med.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_KO/ko_med.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_KO/grp_ko_med.abld",
		},	
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_guard_grenade_ko =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_KO/ko_grenadier.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_KO/ko_grenadier.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_KO/grp_ko_grenadier.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_specops_ko =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_KO/ko_spec_ops.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_KO/ko_spec_ops.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_KO/grp_ko_spec_ops.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_2h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},			
	},

	kanim_guard_tier2_male_ko =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_KO/ko_med_2.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_KO/ko_med_2.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_KO/grp_ko_med_2.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	
	kanim_guard_male_enforcer =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_neutral/enforcer.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_neutral/enforcer.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_neutral/grp_enforcer.abld",
		},		
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_2h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_guard_male_enforcer_2 =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_neutral/enforcer_2.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_neutral/enforcer_2.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_neutral/grp_enforcer_2.abld",
		},			
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_2h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	kanim_guard_male_ko_heavy =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_KO/ko_heavy.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_KO/ko_heavy.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_KO/grp_ko_heavy.abld",
		},			
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},


	kanim_guard_male_dummy =
	{
		wireframe =
		{
			"data/anims/characters/corp_FTM/ftm_med_overlay.abld",--"data/anims/characters/corp_neutral/bot_male.abld",
		},
		build = 
		{ 
			"data/anims/characters/corp_neutral/bot_male.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/corp_neutral/grp_bot_male.abld",
		},		
		grp_anims = commonanims.male.grp_anims,
		
		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},



	kanim_courier_male =
	{
		wireframe =
		{
			"data/anims/characters/agents/courier_overlay.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/courier.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",				
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_courier.abld",
		},		

		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},
		peekBranchSet = 1,
	},

	kanim_prisoner_male =
	{
		wireframe =
		{
			"data/anims/characters/agents/prisoner_overlay.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/prisoner.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",				
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_prisoner.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},
		peekBranchSet = 1,
	},	

-----------------------------------------------------------------------------------------
	kanim_drone_SA =
	{
		build = 
		{ 
			"data/anims/characters/corp_SK/sankaku_droid.abld",	 
		},
		anims =
		{		
			"data/anims/characters/corp_SK/sankaku_droid.adef",
		},
		anims_1h =
		{
			"data/anims/characters/corp_SK/sankaku_droid.adef",
		},
		anims_2h =
		{	
			"data/anims/characters/corp_SK/sankaku_droid.adef",
		},


		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_closed" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		animMap = DRONE_ANIMS,
	},

	kanim_drone_tier2_SA =
	{
		build = 
		{ 
			"data/anims/characters/corp_SK/sankaku_droid_heavy_2.abld",	 
		},
		anims =
		{		
			"data/anims/characters/corp_SK/sankaku_droid_heavy_2.adef",
		},
		anims_1h =
		{
			"data/anims/characters/corp_SK/sankaku_droid_heavy_2.adef",
		},
		anims_2h =
		{	
			"data/anims/characters/corp_SK/sankaku_droid_heavy_2.adef",
		},


		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_closed" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		animMap = DRONE_ANIMS,
	},

	kanim_drone_null_SA =
	{
		build = 
		{ 
			"data/anims/characters/corp_SK/sankaku_droid_null.abld",	 
		},
		anims =
		{		
			"data/anims/characters/corp_SK/sankaku_droid_null.adef",
		},
		anims_1h =
		{
			"data/anims/characters/corp_SK/sankaku_droid_null.adef",
		},
		anims_2h =
		{	
			"data/anims/characters/corp_SK/sankaku_droid_null.adef",
		},


		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_closed" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		animMap = FLOAT_DRONE_ANIMS,
		filterSymbols = {{symbol="scan",filter="default"},{symbol="camera_ol_line",filter="default"}},
	},

	kanim_drone_camera_SA =
	{
		build = 
		{ 
			"data/anims/characters/corp_SK/sankaku_droid_camera.abld",	 
		},
		anims =
		{		
			"data/anims/characters/corp_SK/sankaku_droid_camera.adef",
		},
		anims_1h =
		{
			"data/anims/characters/corp_SK/sankaku_droid_camera.adef",
		},
		anims_2h =
		{	
			"data/anims/characters/corp_SK/sankaku_droid_camera.adef",
		},


		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_closed" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		animMap = FLOAT_DRONE_ANIMS,
		filterSymbols = {{symbol="scan",filter="default"},{symbol="camera_ol_line",filter="default"}},

	},

	kanim_drone_akuma_SA =
	{
		build = 
		{ 
			"data/anims/characters/corp_SK/sankaku_droid_tank.abld",
			"data/anims/characters/corp_SK/sankaku_droid_tank_2.abld",
		},
		anims =
		{		
			"data/anims/characters/corp_SK/sankaku_droid_tank.adef",
			"data/anims/characters/corp_SK/sankaku_droid_tank_2.adef",
		},
		anims_1h =
		{
			"data/anims/characters/corp_SK/sankaku_droid_tank.adef",
			"data/anims/characters/corp_SK/sankaku_droid_tank_2.adef",
		},
		anims_2h =
		{	
			"data/anims/characters/corp_SK/sankaku_droid_tank.adef",
			"data/anims/characters/corp_SK/sankaku_droid_tank_2.adef",
		},


		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_closed" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
		animMap = FLOAT_DRONE_TANK_ANIMS,
	},

	kanim_business_man =
	{
		wireframe =
		{
			"data/anims/characters/agents/executive.abld", --"data/anims/characters/corp_FTM/ftm_med_overlay.abld",
		},
		build = 
		{ 
			"data/anims/characters/agents/executive.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	 	 
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_executive.abld",
		},
		anims = commonanims.male.default_anims_1h,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		anims_panic = commonanims.male.default_anims_panic,
		animMap = GUARD_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		shouldFlipOverrides = {
			{anim="peek_fwrd", shouldFlip=false},
			{anim="peek_pst_fwrd", shouldFlip=false},
		},
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},		
	},

	----------------------------------------------------------------------------------------
	kanim_hud_agent_hud =
	{
		build = { "data/anims/gui/hud_agent_hud.abld" },
		anims = { "data/anims/gui/hud_agent_hud.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},
	
	kanim_tutorial_tile_arrow =
	{
		build = { "data/anims/fx/tutorial_arrow_fx.abld" },
		anims = { "data/anims/fx/tutorial_arrow_fx.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},	
	

	kanim_monst3r_console_fx =
	{
		build = { "data/anims/fx/monster_security_room_hologram.abld" },
		anims = { "data/anims/fx/monster_security_room_hologram.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},
	

	kanim_hud_fx =
	{
		build = { "data/anims/gui/hud_fx.abld" },
		anims = { "data/anims/gui/hud_fx.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},
	
	kanim_hud_tag =
	{
		build = { "data/anims/fx/tag_effect.abld" },
		anims = { "data/anims/fx/tag_effect.adef" },
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},

	kanim_hud_interest_point_fx =
	{
		build = { "data/anims/gui/hud_interest_point_fx.abld" },
		anims = { "data/anims/gui/hud_interest_point_fx.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},

	kanim_used_console_fx =
	{
		build = { "data/anims/fx/unused_console_fx.abld" },
		anims = { "data/anims/fx/unused_console_fx.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
		filterSymbols = {{symbol="veins",filter="default"},},
	},

	kanim_hud_drone_scan =
	{
		build = { "data/anims/fx/drone_scan_fx.abld" },
		anims = { "data/anims/fx/drone_scan_fx.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},

	kanim_null_fx =
	{
		build = { "data/anims/fx/null_drone_fx.abld" },
		anims = { "data/anims/fx/null_drone_fx.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},	

	kanim_hud_turret_ol =
	{
		build = { "data/anims/gui/hud_turret_ol.abld" },
		anims = { "data/anims/gui/hud_turret_ol.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},

	kanim_sleep_zees_fx =
	{
		build = { "data/anims/fx/sleep_zees.abld" },
		anims = { "data/anims/fx/sleep_zees.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},

	kanim_emp_explosion_fx =
	{
		build = { "data/anims/fx/emp_explosion.abld" },
		anims = { "data/anims/fx/emp_explosion.adef" },
		--symbol = "APMeter",
		anim = "active_N_E_W_S_",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},

	kanim_shield_fx =
	{
		build = { "data/anims/fx/shield_fx.abld" },
		anims = { "data/anims/fx/shield_fx.adef" },
		--symbol = "APMeter",
		anim = "default",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character, -- this doesn't really apply to HUD stuff...
	},	

	kanim_camera_overlay_alarm =
	{
		build = { "data/anims/mainframe/camera_overlay_alarm.abld" },
		anims = { "data/anims/mainframe/camera_overlay_alarm.adef" },
		symbol = "alarm_light",
		anim = "alarm",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
	},	

	

	kanim_soundbug_overlay_alarm =
	{
		build = { "data/anims/fx/security_object_alarm_fx.abld" },
		anims = { "data/anims/fx/security_object_alarm_fx.adef" },
		symbol = "character",
		anim = "alarm",
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
	},		

-------------------------------------------------------------------------------------------------
	kanim_light_revolver =
	{
		wireframe = {"data/anims/characters/guns/gun_pistol_lowbore_overlay.abld"},
		build = "data/anims/characters/guns/gun_pistol_lowbore.abld",		
		grp_build = "data/anims/characters/guns/grp_gun_pistol_lowbore.abld",
		anims = {},
	},
	kanim_light_rifle =
	{
		wireframe = {"data/anims/characters/guns/gun_rifle_lowbore_overlay.abld"},
		build = "data/anims/characters/guns/gun_rifle_lowbore.abld",
		grp_build = "data/anims/characters/guns/grp_gun_rifle_lowbore.abld",
		anims = {},
	},
	kanim_light_smg =
	{
		wireframe = {"data/anims/characters/guns/gun_smg.abld"},
		build = "data/anims/characters/guns/gun_smg.abld",
		grp_build = "data/anims/characters/guns/grp_gun_smg.abld",
		anims = {},
	},
	kanim_precise_smg =
	{
		wireframe = {"data/anims/characters/guns/gun_smg_precise_overlay.abld"},
		build = "data/anims/characters/guns/gun_smg_precise.abld",
		grp_build = "data/anims/characters/guns/grp_gun_smg_precise.abld",
		anims = {},
	},	

	kanim_precise_revolver =
	{
		wireframe = {"data/anims/characters/guns/gun_pistol_precise_overlay.abld"},	
		build = "data/anims/characters/guns/gun_pistol_precise.abld",
		grp_build = "data/anims/characters/guns/grp_gun_pistol_precise.abld",
		anims = {},
	},
	kanim_precise_rifle =
	{
		wireframe = {"data/anims/characters/guns/gun_rifle_precise_overlay.abld"},
		build = "data/anims/characters/guns/gun_rifle_precise.abld",
		grp_build = "data/anims/characters/guns/grp_gun_rifle_precise.abld",
		anims = {},
	},

	kanim_console =
	{
		build = "data/anims/mainframe/lab_object_1x1computer.abld",
		anims = { "data/anims/mainframe/lab_object_1x1computer.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="outline",filter="default"},{symbol="tile_outline",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"},{symbol="Highlight",filter="default"}},
	},

	kanim_console_hilite =
	{
		build = "data/anims/fx/highlight_lab_object_1x1computer.abld",
		anims = { "data/anims/fx/highlight_lab_object_1x1computer.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="Highlight",filter="default"}},
	},



	kanim_laptop =
	{
		build = "data/anims/mainframe/suitcase_computer.abld",
		anims = { "data/anims/mainframe/suitcase_computer.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="outline",filter="default"},{symbol="tile_outline",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"},{symbol="Highlight",filter="default"}},
	},

	kanim_laptop2 =
	{
		build = "data/anims/mainframe/suitcase_computer_2.abld",
		anims = { "data/anims/mainframe/suitcase_computer_2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="outline",filter="default"},{symbol="tile_outline",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"},{symbol="Highlight",filter="default"}},
	},

	kanim_stickycam =
	{
		build = "data/anims/fx/grenade.abld",
		anims = { "data/anims/fx/grenade.adef" },
		symbol = "character",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="outline",filter="default"},{symbol="tile_outline",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"},{symbol="Highlight",filter="default"}},
	},

	kanim_flashgrenade =
	{
		build = "data/anims/fx/grenade.abld",
		anims = { "data/anims/fx/grenade.adef" },
		symbol = "character",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="outline",filter="default"},{symbol="tile_outline",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"},{symbol="Highlight",filter="default"}},
	},

	kanim_hologrenade =
	{
		build = "data/anims/fx/hologrenade_cart.abld",
		anims = { "data/anims/fx/hologrenade_cart.adef" },
		symbol = "character",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="outline",filter="default"},{symbol="tile_outline",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"},{symbol="Highlight",filter="default"}},
	},

	kanim_scangrenade =
	{
		build = "data/anims/fx/grenade_scanner.abld",
		anims = { "data/anims/fx/grenade_scanner.adef" },
		symbol = "character",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="outline",filter="default"},{symbol="tile_outline",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"},{symbol="Highlight",filter="default"}},
	},

	kanim_office_1x1_alarm_1=
	{
		build = "data/anims/mainframe/security_alarm.abld",
		anims = { "data/anims/mainframe/security_alarm.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"},{symbol="alarm",filter="default"}},
	},	

	kanim_office_2x1_coffee_table=
	{
		build = { "data/anims/FTM_office/office_object_2x1coffeetable.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/office_object_2x1coffeetable.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_office_2x1_couch=
	{
		build = { "data/anims/FTM_office/office_object_2x1couch.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/office_object_2x1couch.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},		

	kanim_office_2x1_desk=
	{
		build = { "data/anims/FTM_office/office_object_2x1desk.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/office_object_2x1desk.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	kanim_office_1x1_side_table=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1sidetable1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1sidetable1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
	
	kanim_office_1x1_chair_1=
	{
		build = { "data/anims/FTM_office/office_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/office_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	
	
	kanim_office_1x1_planter=
	{
		build = { "data/anims/FTM_office/office_object_1x1planter.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/office_object_1x1planter.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},		

	kanim_office_2x1_Bookshelf=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1shortbookshelf.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1shortbookshelf.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	kanim_office_1x1_closet_1=
	{
		build = { "data/anims/FTM_office/office_object_1x1closet1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/office_object_1x1closet1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_Office_1x1_PrinterSideTable=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1printersidetable.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1printersidetable.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_Office_2x3_BoardroomTable=
	{
		build = { "data/anims/FTM_office/office_object_2x3boardroomtable.abld", "data/anims/general/mf_coverpieces_2x3.abld" },
		anims = { "data/anims/FTM_office/office_object_2x3boardroomtable.adef", "data/anims/general/mf_coverpieces_2x3.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x3,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_lab_1x1_Closet1=
	{
		build = { "data/anims/FTM_lab/lab_object_1x1closet1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/lab_object_1x1closet1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_lab_1x1_Gear1=
	{
		build = { "data/anims/FTM_lab/lab_object_1x1gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/lab_object_1x1gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_lab_1x1_Gear2=
	{
		build = { "data/anims/FTM_lab/lab_object_1x1gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/lab_object_1x1gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_lab_1x1_Gear3=
	{
		build = { "data/anims/FTM_lab/lab_object_1x1gear3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/lab_object_1x1gear3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_lab_2x1_Console=
	{
		build = { "data/anims/FTM_lab/lab_object_2x1console.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_lab/lab_object_2x1console.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_lab_1x1_Console_2=
	{
		build = { "data/anims/FTM_lab/lab_object_2x1console_2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/lab_object_2x1console_2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_lab_2x1_Console_3=
	{
		build = { "data/anims/FTM_lab/lab_object_2x1console_3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_lab/lab_object_2x1console_3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	kanim_lab_2x2_Table=
	{
		build = { "data/anims/FTM_lab/lab_object_2x2table.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/FTM_lab/lab_object_2x2table.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x2,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	kanim_security_2x1_desk=
	{
		build = { "data/anims/FTM_security/security_object_2x1desk.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/security_object_2x1desk.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
	
	kanim_hall_1x1_chair_1=
	{
		build = { "data/anims/FTM_hall/hall_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/hall_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	kanim_hall_1x1_plant_1=
	{                        
		build = { "data/anims/FTM_hall/hall_object_1x1plant1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/hall_object_1x1plant1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	
	kanim_hall_1x1_sculpt_1=
	{
		build = { "data/anims/FTM_hall/hall_object_1x1sculpt1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/hall_object_1x1sculpt1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	}	,
	kanim_hall_1x1_sculpt_2=
	{
		build = { "data/anims/FTM_hall/hall_object_1x1sculpt2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/hall_object_1x1sculpt2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	}	,
	kanim_hall_1x1_sculpt_3=
	{
		build = { "data/anims/FTM_hall/hall_object_1x1sculpt3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/hall_object_1x1sculpt3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	
	kanim_hall_2x1_sculpt_4=
	{
		build = { "data/anims/FTM_hall/hall_object_2x1sculpt1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_hall/hall_object_2x1sculpt1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	
	kanim_hall_2x1_couch_1=
	{
		build = { "data/anims/FTM_hall/hall_object_2x1couch1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_hall/hall_object_2x1couch1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

--SECURITY ITEMS
	kanim_security_1x1_gear_1=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
	kanim_security_1x1_gear_2=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	kanim_security_1x1_cabinet=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1cabinet.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1cabinet.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
	kanim_security_1x1_filingcabinet=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1filingcabinet.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1filingcabinet.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	
	kanim_security_2x2_interrogationtable=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1interrogationtable1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1interrogationtable1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x2,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	
	kanim_security_2x1_kitchen=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1kitchen.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1kitchen.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},		
	kanim_security_1x1_locker=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1locker.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1locker.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_verytall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},			
	kanim_security_1x1_shelf=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1shelf.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1shelf.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},		
	kanim_security_1x1_watercooler=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1watercooler.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1watercooler.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},		
	kanim_security_2x1_bench=
	{
		build = { "data/anims/FTM_security/ftm_security_object_2x1bench.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_2x1bench.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	
	kanim_security_2x1_console1=
	{
		build = { "data/anims/FTM_security/ftm_security_object_2x1console1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_2x1console1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},	
	kanim_security_2x1_console2=
	{
		build = { "data/anims/FTM_security/ftm_security_object_2x1console2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_2x1console2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},		
-- SECURITY END

	kanim_laser_2 =
	{
		build = { "data/anims/mainframe/office_object_1x1lasers_red_teal.abld"},
		anims = { "data/anims/mainframe/office_object_1x1lasers_red_teal.adef"},
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="internal",filter="default"},{symbol="lines_new",filter="default"},{symbol="internal_teal",filter="default"},{symbol="lines_new_teal",filter="default"}},
	},

	kanim_infrared_beam_2 =
	{
		build = { "data/anims/mainframe/office_object_1x1lasers_light_red_teal.abld"},
		anims = { "data/anims/mainframe/office_object_1x1lasers_light_red_teal.adef"},
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="internal",filter="default"},{symbol="lines",filter="default"},{symbol="lines_new",filter="default"},{symbol="internal_teal",filter="default"},{symbol="lines_teal",filter="default"},{symbol="lines_new_teal",filter="default"}},
	},

	kanim_infrared_wall_2 =
	{
		build = { "data/anims/mainframe/office_object_1x1laserswall_red_teal.abld" },
		anims = { "data/anims/mainframe/office_object_1x1laserswall_red_teal.adef"},
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="wallbeam",filter="default"},{symbol="wallbeam_red",filter="default"},{symbol="lines_new",filter="default"},{symbol="lines_new_teal",filter="default"}},
	},

	kanim_turret =
	{
		build = "data/anims/mainframe/office_security_1x1turret_new.abld",
		anims = { "data/anims/mainframe/office_security_1x1turret_new.adef" },
		symbol = "character",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="fire",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},

	kanim_powersource =
	{
		build = "data/anims/mainframe/office_security_1x1turret_powersource.abld",
		anims = { "data/anims/mainframe/office_security_1x1turret_powersource.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},
		
	
	kanim_walllight =
	{
		build = "data/anims/FTM_office/officewalllight_1x1.abld",
		anims = { "data/anims/FTM_office/officewalllight_1x1.adef" },
		symbol = "character",
		anim = "N",
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.Wall
	},	
	
	kanim_wall_laser_emitter =
	{
		build = "data/anims/mainframe/security_laser_emitters_1x1.abld",
		anims = { "data/anims/mainframe/security_laser_emitters_1x1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="glow",filter="default"}},
	},

	kanim_wall_laser_emitter_tall =
	{
		build = "data/anims/mainframe/security_laser_emitterstall_1x1.abld",
		anims = { "data/anims/mainframe/security_laser_emitterstall_1x1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="glow",filter="default"}},
	},	

	kanim_core =
	{
		build = "data/anims/mainframe/mainframe_core01_1x1.abld",
		anims = { "data/anims/mainframe/mainframe_core01_1x1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},

	kanim_serverTerminal =
	{
		build = "data/anims/Unique_serverroom/serverroom_terminal_1x1.abld",
		anims = { "data/anims/Unique_serverroom/serverroom_terminal_1x1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},

	kanim_monsterConsole =
	{
		build = "data/anims/Final_monster/monsterroom_1x1_centerconsole1.abld",
		anims = { "data/anims/Final_monster/monsterroom_1x1_centerconsole1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},

	kanim_finalConsole =
	{
		build = "data/anims/Final_room/finalroom_1x1_centerconsole1.abld",
		anims = { "data/anims/Final_room/finalroom_1x1_centerconsole1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},

	kanim_preFinalConsole =
	{
		build = "data/anims/prefinal/prefinal_1x1_console1.abld",
		anims = { "data/anims/prefinal/prefinal_1x1_console1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},

	kanim_public_terminal =
	{ 
		build = "data/anims/Unique_publicterminal/publicterminal_1x1_interactiveconsole1.abld",
		anims = { "data/anims/Unique_publicterminal/publicterminal_1x1_interactiveconsole1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},


	kanim_scanner =
	{
		build = "data/anims/KO_lab/ko_lab_object_1x1scanner1.abld",
		anims = { "data/anims/KO_lab/ko_lab_object_1x1scanner1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},

	kanim_power_reversal =
	{
		build = "data/anims/mainframe/mainframe_power_reversal_node.abld",
		anims = { "data/anims/mainframe/mainframe_power_reversal_node.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},




	kanim_celldoor1 =
	{                            
		build = { "data/anims/Unique_holdingcell/holdingcell_1x1_celldoor1.abld", "data/anims/general/mf_coverpieces_1x1.abld"},
		anims = { "data/anims/Unique_holdingcell/holdingcell_1x1_celldoor1.adef", "data/anims/general/mf_coverpieces_1x1.adef"},
		symbol = "character",		
		layer = Layer.Decor,
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},			



	kanim_server =
	{
		build = "data/anims/mainframe/mainframe_server.abld",
		anims = { "data/anims/mainframe/mainframe_server.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},
	},

	kanim_safe =
	{
		build = "data/anims/mainframe/mainframe_safe_1x1.abld",
		anims = { "data/anims/mainframe/mainframe_safe_1x1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},		
	},

	kanim_safe2 =
	{
		build = "data/anims/mainframe/mainframe_safe2_1x1.abld",
		anims = { "data/anims/mainframe/mainframe_safe2_1x1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},		
	},

	kanim_guard_locker =
	{
		build = "data/anims/Unique_guardoffice/guardoffice_1x1_fridgesafe1.abld",
		anims = { "data/anims/Unique_guardoffice/guardoffice_1x1_fridgesafe1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},		
	},


	kanim_vault_safe_1 =
	{
		build = "data/anims/Unique_Vault/vault_1x1_locker1.abld",
		anims = { "data/anims/Unique_Vault/vault_1x1_locker1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},		
	},

	kanim_vault_safe_2 =
	{
		build = "data/anims/Unique_Vault/vault_1x1_podium1.abld",
		anims = { "data/anims/Unique_Vault/vault_1x1_podium1.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},		
	},

	kanim_vault_safe_3 =
	{
		build = "data/anims/Unique_Vault/vault_1x1_podium2.abld",
		anims = { "data/anims/Unique_Vault/vault_1x1_podium2.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},		
	},


	kanim_augment_grafter =
	{
		build = "data/anims/Unique_cybernetics/cybernetics_1x1_augmenter.abld",
		anims = { "data/anims/Unique_cybernetics/cybernetics_1x1_augmenter.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="red",filter="default"},{symbol="teal",filter="default"}},		
	},

	kanim_shop =
	{
		build = "data/anims/mainframe/mainframe_1x1_store.abld",
		anims = { "data/anims/mainframe/mainframe_1x1_store.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"}},
	},	

	kanim_printer =
	{
		build = "data/anims/mainframe/mainframe_1x1_3dprinter.abld",
		anims = { "data/anims/mainframe/mainframe_1x1_3dprinter.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_tall_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"}},
	},		

	kanim_stockexchange =
	{
		build = "data/anims/mainframe/mainframe_1x1_stockexchange.abld",
		anims = { "data/anims/mainframe/mainframe_1x1_stockexchange.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"}},
	},		


	kanim_security_camera =
	{
		build = "data/anims/mainframe/security_object_1x1camera.abld",
		anims = { "data/anims/mainframe/security_object_1x1camera.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.Ceiling_1x1,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="teal",filter="default"},{symbol="red",filter="default"}},
	},

	kanim_shock_trap_door = 
	{
		build = "data/anims/fx/door_shock_trap.abld",
		anims = { "data/anims/fx/door_shock_trap.adef" },
		symbol = "sock_trap",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.WallFlip,
		filterSymbols = {{symbol="light",filter="default"},{symbol="blast",filter="default"},{symbol="elec_door",filter="default"}},
	},

	kanim_lock_decoder = 
	{
		build = "data/anims/fx/doordecoder1.abld",
		anims = { "data/anims/fx/doordecoder1.adef" },
		symbol = "sock_trap",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.WallFlip,
		filterSymbols = {{symbol="light",filter="default"},{symbol="blast",filter="default"},{symbol="elec_door",filter="default"}},
	},


	kanim_smoke_plume =
	{
		build = "data/anims/fx/smoke_grenade.abld",
		anims = { "data/anims/fx/smoke_grenade.adef" },
		symbol = "effect",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_tall_med,
	},		
        
    kanim_door_lock = 
	{
		build = "data/anims/general/door_security_lock.abld",
		anims = { "data/anims/general/door_security_lock.adef" },
		symbol = "sock_trap",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.WallFlip,
		filterSymbols = {{symbol="light",filter="default"},{symbol="blast",filter="default"},{symbol="elec_door",filter="default"}},
	},

	kanim_vault_lock = 
	{
		build = "data/anims/Unique_ceooffice/ceooffice_vaultlock1.abld",
		anims = { "data/anims/Unique_ceooffice/ceooffice_vaultlock1.adef" },
		symbol = "sock_trap",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.WallFlip,
		filterSymbols = {{symbol="light",filter="default"},{symbol="blast",filter="default"},{symbol="elec_door",filter="default"}},
	},

	kanim_hostage = 
	{
		build = 
		{ 
			"data/anims/characters/agents/courier.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	
			"data/anims/characters/anims_male/stealth_basic_a_04.abld",			
		},

		anims =
		{
			"data/anims/characters/anims_male/shared_basic_a_01.adef",			
			"data/anims/characters/anims_male/shared_basic_a_02.adef",
			"data/anims/characters/anims_male/shared_basic_a_03.adef",
			"data/anims/characters/anims_male/shared_basic_a_04.adef",
			"data/anims/characters/anims_male/shared_hits_01.adef",			
			"data/anims/characters/anims_male/shared_attacks_a_01.adef",
			"data/anims/characters/anims_male/shared_attacks_a_02.adef",
			"data/anims/characters/anims_male/stealth_basic_a_01.adef",
			"data/anims/characters/anims_male/stealth_basic_a_02.adef",
			"data/anims/characters/anims_male/stealth_basic_a_03.adef",		
			"data/anims/characters/anims_male/stealth_basic_a_04.adef",			
		},	
	--	animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "untie_idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},
		peekBranchSet = 1,	
		animMap = HOSTAGE_ANIMS,		

	},	

	kanim_monst3r = 
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_monst3r.abld",
		},	
		build = 
		{ 
			"data/anims/characters/agents/agent_monst3r.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	
			"data/anims/characters/anims_male/stealth_basic_a_04.abld",				
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_monst3r.abld",
		},
		grp_anims = commonanims.male.grp_anims,

		anims = commonanims.male.default_anims_unarmed,
		anims_1h = commonanims.male.default_anims_1h,
		anims_2h = commonanims.male.default_anims_2h,
		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},
		peekBranchSet = 1,	

	},	

	kanim_central = 
	{
		wireframe =
		{
			"data/anims/characters/agents/overlay_agent_central.abld",
		},	
		build = 
		{ 			
			"data/anims/characters/anims_female/shared_female_hits_01.abld",	
			"data/anims/characters/anims_female/shared_female_attacks_a_01.abld",	
			"data/anims/characters/agents/agent_central.abld",
		},
		grp_build = 
		{
			"data/anims/characters/agents/grp_agent_central.abld",
		},
		grp_anims = commonanims.female.grp_anims,
		anims = commonanims.female.default_anims_unarmed,
		anims_1h = commonanims.female.default_anims_1h,
		anims_2h = commonanims.female.default_anims_2h,

		animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},
		peekBranchSet = 1,			

	},	

	kanim_prisoner = 
	{
		build = 
		{ 
			"data/anims/characters/agents/prisoner.abld",
			"data/anims/characters/anims_male/shared_hits_01.abld",	
			"data/anims/characters/anims_male/shared_attacks_a_01.abld",	
			"data/anims/characters/anims_male/stealth_basic_a_04.abld",			
		},

		anims =
		{
			"data/anims/characters/anims_male/shared_basic_a_01.adef",			
			"data/anims/characters/anims_male/shared_basic_a_02.adef",
			"data/anims/characters/anims_male/shared_basic_a_03.adef",
			"data/anims/characters/anims_male/shared_basic_a_04.adef",
			"data/anims/characters/anims_male/shared_hits_01.adef",			
			"data/anims/characters/anims_male/shared_attacks_a_01.adef",
			"data/anims/characters/anims_male/shared_attacks_a_02.adef",
			"data/anims/characters/anims_male/stealth_basic_a_01.adef",
			"data/anims/characters/anims_male/stealth_basic_a_02.adef",
			"data/anims/characters/anims_male/stealth_basic_a_03.adef",		
			"data/anims/characters/anims_male/stealth_basic_a_04.adef",			
		},	
	--	animMap = AGENT_ANIMS,

		symbol = "character",
		anim = "idle",
		shouldFlip = true,
		scale = 0.25,
		layer = Layer.Unit,
		boundType = BoundType.Character,
		boundTypeOverrides = {			
			{anim="idle_ko" ,boundType= BoundType.CharacterFloor},
			{anim="dead" ,boundType= BoundType.CharacterFloor},
		},
		peekBranchSet = 1,	
		animMap = HOSTAGE_ANIMS,		

	},	


	kanim_security_soundbug =
	{
		build = "data/anims/mainframe/security_object_1x1soundbug.abld",
		anims = { "data/anims/mainframe/security_object_1x1soundbug.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="1",filter="default"},{symbol="red",filter="default"},{symbol="waves_red",filter="default"},{symbol="ring_red",filter="default"},{symbol="teal",filter="default"},{symbol="waves_teal",filter="default"},{symbol="1_teal",filter="default"},{symbol="ring",filter="default"}},	
	},

	-- DECOR --

	decor_ko_lab_dirtstain1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_dirtstain1.abld",  },
		anims = { "data/anims/KO_lab/ko_lab_object_dirtstain1.adef",  },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
		setlayer = "floor",
	},	
	
	decor_ko_lab_dirtstain2 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_dirtstain2.abld",  },
		anims = { "data/anims/KO_lab/ko_lab_object_dirtstain2.adef",  },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
		setlayer = "floor",
	},

	decor_ko_lab_dirtstain3 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_dirtstain3.abld",  },
		anims = { "data/anims/KO_lab/ko_lab_object_dirtstain3.adef",  },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
		setlayer = "floor",
	},	
	
	decor_ko_lab_paperscrap1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_paperscrap1.abld",  },
		anims = { "data/anims/KO_lab/ko_lab_object_paperscrap1.adef",  },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
		setlayer = "floor",
	},	

	decor_ko_lab_paperscrap2 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_paperscrap2.abld",  },
		anims = { "data/anims/KO_lab/ko_lab_object_paperscrap2.adef",  },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
		setlayer = "floor",
	},			
	decor_elevator_arrows =
	{
		build = { "data/anims/fx/exit_arrow_effect.abld" },
		anims = { "data/anims/fx/exit_arrow_effect.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
        nonOptional = true,
	},

	kanim_temp_engineer =
	{
		build = "data/anims/characters/temp_engineer.abld",
		anims = { "data/anims/characters/temp_engineer.adef" },
		symbol = "character",		
		scale = 0.25,
		layer = Layer.Decor,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="glow",filter="default"},{symbol="Highlight",filter="default"},{symbol="screen_red",filter="default"},{symbol="screen",filter="default"}},
	},	


	decor_final_floor_lights =
	{
		build = { "data/anims/Final_room/finalroom_1x1_lights.abld" },
		anims = { "data/anims/Final_room/finalroom_1x1_lights.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},

	decor_final_floor_lights_beam =
	{
		build = { "data/anims/Final_room/finalroom_1x1_lightbeam.abld" },
		anims = { "data/anims/Final_room/finalroom_1x1_lightbeam.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

-- FTM OFFICE --------------------------------------------------------------------------------------------


	
	ftm_office_2x1_coffee_table=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1coffeetable.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1coffeetable.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	ftm_office_2x1_couch=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1couch.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1couch.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},		


	ftm_office_1x1_side_table1=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1sidetable1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1sidetable1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	ftm_office_1x1_side_table2=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1sidetable2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1sidetable2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	ftm_office_1x1_side_table3=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1sidetable3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1sidetable3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	ftm_office_1x1_side_table4=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1sidetable4.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1sidetable4.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	ftm_office_1x1_side_table5=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1sidetable5.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1sidetable5.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	
	ftm_office_1x1_chair_1=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	
	
	ftm_office_1x1_planter=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1planter.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1planter.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},		

	ftm_office_2x1_Bookshelf=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1shortbookshelf.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1shortbookshelf.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_office_1x1_closet_1=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1closet1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1closet1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	ftm_Office_1x1_PrinterSideTable=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1printersidetable.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1printersidetable.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	ftm_office_2x1_coffee_table=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1coffeetable.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1coffeetable.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	
	ftm_office_2x1_coffee_table2=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1coffeetable2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1coffeetable2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	
	ftm_office_2x1_coffee_table2_items1=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1coffeetable2_items1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1coffeetable2_items1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	ftm_office_2x1_couch=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1couch.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1couch.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},		

	ftm_office_2x1_desk1_items2=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1desk1_items2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1desk1_items2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},


	ftm_office_2x1_desk2_items1=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1desk2_items1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1desk2_items1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},	


	ftm_office_2x1_desk2_items2=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1desk2_items2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1desk2_items2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},


	ftm_office_2x1_desk3=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1desk3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1desk3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},


	ftm_Office_1x1_verticalfilecabinet1=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
		skins = { "FTM_office_filecabinet" },   
	},	


	ftm_Office_1x1_verticalfilecabinet2=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
		skins = { "FTM_office_filecabinet" },   
	},



	ftm_Office_1x1_verticalfilecabinet3=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
		skins = { "FTM_office_filecabinet" },   
	},



	ftm_Office_1x1_verticalfilecabinet4=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet4.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet4.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
		skins = { "FTM_office_filecabinet" },   
	},



	ftm_Office_1x1_verticalfilecabinet5=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet5.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1verticalfilecabinet5.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
		skins = { "FTM_office_filecabinet" },   
	},


	ftm_Office_1x1_filecart=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1filecart.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1filecart.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},



	ftm_Office_1x1_tvcamera=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1tvcamera.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1tvcamera.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},



	ftm_Office_2x3_BoardroomTable=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x3boardroomtable1.abld", "data/anims/general/mf_coverpieces_2x3.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x3boardroomtable1.adef", "data/anims/general/mf_coverpieces_2x3.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x3,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	

	ftm_office_planter_2_2x1 =
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1planter_2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1planter_2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},
	

	ftm_office_benchtable1 =
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1benchtable1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1benchtable1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},
	
	

	ftm_office_horizontalfilecabinet1 =
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1horizontalfilecabinet1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1horizontalfilecabinet1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},
	

	ftm_elevator_panel =
	{
		build = { "data/anims/mainframe/elevatorpanel1.abld" },
		anims = { "data/anims/mainframe/elevatorpanel1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	
	

	ftm_office_ftmbanner1 =
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1ftmbanner1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1ftmbanner1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},
				
	ftm_office_paintings1 =
	{
		build = { "data/anims/FTM_office/ftm_office_decor_paintings1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_decor_paintings1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "FTM_office_painting" },
	},

	ftm_office_paintings2 =
	{
		build = { "data/anims/FTM_office/ftm_office_decor_paintings2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_decor_paintings2.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "FTM_office_painting" },
	},

	ftm_office_vent1 =
	{
		build = { "data/anims/FTM_office/ftm_office_decor_vent1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_decor_vent1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	ftm_office_walllight1 =
	{
		build = { "data/anims/FTM_office/ftm_office_decor_walllight1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_decor_walllight1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

-- FTM HALL ----------------------------------------------------------------------------------------------


	ftm_hall_curtains1 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_decor_curtains1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_decor_curtains1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	ftm_hall_ottoman1=
	{
		build = { "data/anims/FTM_hall/ftm_hall_decor_ottoman1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_decor_ottoman1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
				
	ftm_hall_painting1 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_decor_painting1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_decor_painting1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "FTM_hall_painting" },
	},
				
	ftm_hall_painting2 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_decor_painting2.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_decor_painting2.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "FTM_hall_painting" },
	},
				
	ftm_hall_painting3 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_decor_painting3.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_decor_painting3.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "FTM_hall_painting" },
	},
				
	ftm_hall_painting4 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_decor_painting4.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_decor_painting4.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "FTM_hall_painting" },
	},
				
	ftm_hall_painting5 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_decor_painting5.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_decor_painting5.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "FTM_hall_painting" },
	},
				
	ftm_hall_walllight1 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_decor_walllight1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_decor_walllight1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
	},

	ftm_hall_chair1=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
				

	ftm_hall_plant1=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1plant1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1plant1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
				
				

	ftm_hall_plant2=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1plant2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1plant2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
				

	ftm_hall_sculpt1=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1sculpt1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1sculpt1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
							

	ftm_hall_sculpt2=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1sculpt2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1sculpt2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
				

	ftm_hall_sculpt3=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1sculpt3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1sculpt3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
				
				

	ftm_hall_sidetable1=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1sidetable1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1sidetable1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_hall_sidetable2=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1sidetable2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1sidetable2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_hall_bookshelf =
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_2x1bookshelf.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_2x1bookshelf.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_hall_couch1 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_2x1couch1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_2x1couch1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},



-- FTM LAB -----------------------------------------------------------------------------------------------

					
	elevatorpanel1 =
	{
		build = { "data/anims/mainframe/elevatorpanel1.abld" },
		anims = { "data/anims/mainframe/elevatorpanel1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
	},
			
	ftm_lab_bulletinboard1 =
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_bulletinboard1.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_bulletinboard1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
	},

	ftm_lab_cabinet1 =
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_cabinet1.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_cabinet1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
	},

	ftm_lab_coats =
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_coats.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_coats.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
	},

	ftm_lab_paintings2 =
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_paintings2.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_paintings2.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "painting" },
	},

	ftm_lab_picture1 =
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_picture1.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_picture1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "painting" },
	},

	ftm_lab_poster1 =
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_poster1.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_poster1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
	},

	ftm_lab_postgizmo1=
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_postgizmo1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_postgizmo1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_lab_sink1 =
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_sink1.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_sink1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
	},

	ftm_lab_trashcan1=
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_trashcan1.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_trashcan1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_lab_wallblackboard1 =
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_wallblackboard1.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_wallblackboard1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},

	ftm_lab_wallgizmo1 =
	{
		build = { "data/anims/FTM_lab/ftm_decor_lab_wallgizmo1.abld" },
		anims = { "data/anims/FTM_lab/ftm_decor_lab_wallgizmo1.adef" },
		symbol = "character",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
	},

	ftm_lab_closet1=
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_1x1closet1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_1x1closet1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_lab_gear1=
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_1x1gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_1x1gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_lab_gear2=
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_1x1gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_1x1gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_lab_gear3=
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_1x1gear3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_1x1gear3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_lab_stool1=
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_1x1stool1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_1x1stool1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_lab_stool2=
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_1x1stool2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_1x1stool2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_lab_blackboard2 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x1blackboard_2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x1blackboard_2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_console1 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x1console1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x1console1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_console2 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x1console2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x1console2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_console3 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x1console3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x1console3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_horizontalfilecabinet1 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x1horizontalfilecabinet1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x1horizontalfilecabinet1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_horizontalfilecabinet1_items1 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x1horizontalfilecabinet1_items1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x1horizontalfilecabinet1_items1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_steeltable1 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x1steeltable1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x1steeltable1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_steeltable2 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x1steeltable2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x1steeltable2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_table1_items1 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x2table1_items1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x2table1_items1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x2,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_table1_items2 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x2table1_items2.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x2table1_items2.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x2,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_lab_table1_items3 =
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_2x2table1_items3.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_2x2table1_items3.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x2,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},



-- FTM SECURITY ------------------------------------------------------------------------------------------





	ftm_security_bulletinboard1 =
	{
		build = { "data/anims/FTM_security/ftm_security_decor_bulletinboard1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_decor_bulletinboard1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.Wall_Painting,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_mapscreen1 =
	{
		build = { "data/anims/FTM_security/ftm_security_decor_mapscreen1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_decor_mapscreen1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_securitypanel1 =
	{
		build = { "data/anims/FTM_security/ftm_security_decor_securitypanel1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_decor_securitypanel1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.Wall_Painting,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_uniformshirtsonhook =
	{
		build = { "data/anims/FTM_security/ftm_security_decor_uniformshirtsonhook.abld" },
		anims = { "data/anims/FTM_security/ftm_security_decor_uniformshirtsonhook.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.Wall_Painting,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_wallbox1 =
	{
		build = { "data/anims/FTM_security/ftm_security_decor_wallbox1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_decor_wallbox1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.Wall_Painting,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_wallbox2 =
	{
		build = { "data/anims/FTM_security/ftm_security_decor_wallbox2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_decor_wallbox2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_wallscreen1 =
	{
		build = { "data/anims/FTM_security/ftm_security_decor_wallscreen1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_decor_wallscreen1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_1x1cabinet=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1cabinet.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1cabinet.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_security_1x1filingcabinet=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1filingcabinet.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1filingcabinet.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_security_1x1gear1=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_security_1x1gear2=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_security_1x1interrogationtable1=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1interrogationtable1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1interrogationtable1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_security_1x1locker=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1locker.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1locker.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_security_1x1shelf=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1shelf.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1shelf.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_security_1x1watercooler=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1watercooler.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1watercooler.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_security_1x1woodenstool=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1woodenstool.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1woodenstool.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_security_bench =
	{
		build = { "data/anims/FTM_security/ftm_security_object_2x1bench.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_2x1bench.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_bench_withtowel =
	{
		build = { "data/anims/FTM_security/ftm_security_object_2x1bench_withtowel.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_2x1bench_withtowel.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_console1 =
	{
		build = { "data/anims/FTM_security/ftm_security_object_2x1console1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_2x1console1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_console2 =
	{

		build = { "data/anims/FTM_security/ftm_security_object_2x1console2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_2x1console2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},

	ftm_security_steeltable1 =
	{
		build = { "data/anims/FTM_security/ftm_security_object_2x1steeltable1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_2x1steeltable1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
	},


-- KO OFFICE ---------------------------------------------------------------------------------------------

	decor_ko_office_flag1 =
	{
		build = { "data/anims/KO_office/ko_office_decor_flag1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_decor_flag1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_office_lamp =
	{
		build = { "data/anims/KO_office/ko_office_decor_lamp1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_decor_lamp1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_office_picture1 =
	{
		build = { "data/anims/KO_office/ko_office_decor_picture1.abld" },
		anims = { "data/anims/KO_office/ko_office_decor_picture1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "KO_office_painting" },
	},	

	decor_ko_office_picture2 =
	{
		build = { "data/anims/KO_office/ko_office_decor_picture2.abld" },
		anims = { "data/anims/KO_office/ko_office_decor_picture2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "KO_office_painting" },
	},	

	decor_ko_office_picture3 =
	{
		build = { "data/anims/KO_office/ko_office_decor_picture3.abld" },
		anims = { "data/anims/KO_office/ko_office_decor_picture3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "KO_office_painting" },
	},	

	decor_ko_office_picture4 =
	{
		build = { "data/anims/KO_office/ko_office_decor_picture4.abld" },
		anims = { "data/anims/KO_office/ko_office_decor_picture4.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "KO_office_painting" },
	},	

	decor_ko_office_wallshield1 =
	{
		build = { "data/anims/KO_office/ko_office_decor_wallshield1.abld" },
		anims = { "data/anims/KO_office/ko_office_decor_wallshield1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_ko_office_chair1 =
	{
		build = { "data/anims/KO_office/ko_office_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_ko_office_chest1 =
	{
		build = { "data/anims/KO_office/ko_office_object_1x1chest1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_object_1x1chest1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	
	
	decor_ko_office_filecabinet1 =
	{
		build = { "data/anims/KO_office/ko_office_object_1x1filecabinet1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_object_1x1filecabinet1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_office_globe1 =
	{
		build = { "data/anims/KO_office/ko_office_object_1x1globe1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_object_1x1globe1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_ko_office_planter1 =
	{
		build = { "data/anims/KO_office/ko_office_object_1x1planter1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_object_1x1planter1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_big,
	},	

	decor_ko_office_podium1 =
	{
		build = { "data/anims/KO_office/ko_office_object_1x1podium1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_object_1x1podium1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_office_bookshelf1 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1bookshelf1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1bookshelf1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},

	decor_ko_office_bookshelf2 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1bookshelf2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1bookshelf2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},

	decor_ko_office_couch1 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1couch1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1couch1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_office_couch2 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x2couch2.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x2couch2.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},	

	decor_ko_office_desk1 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1desk1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1desk1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_office_desk2 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1desk2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1desk2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_office_glasscabinet1 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1glasscabinet1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1glasscabinet1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		

	decor_ko_office_cabinet1 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1tvcabinet1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1tvcabinet1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	
	

-- KO LAB ---------------------------------------------------------------------------------------------


	decor_ko_lab_wallbox1 =
	{
		build = { "data/anims/KO_lab/ko_lab_decor_wallbox1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_decor_wallbox1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		skins = { "KO_lab_tech" },

	},	

	decor_ko_lab_wallladder1 =
	{
		build = { "data/anims/KO_lab/ko_lab_decor_wallladder.abld" },
		anims = { "data/anims/KO_lab/ko_lab_decor_wallladder.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		skins = { "KO_lab_tech" },		
	},	

	decor_ko_lab_wallpanel1 =
	{
		build = { "data/anims/KO_lab/ko_lab_decor_wallpanel1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_decor_wallpanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},	

	decor_ko_lab_barrel1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1barrel1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1barrel1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		
	
	decor_ko_lab_rockets1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1rockets1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1rockets1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},		
	
	
	decor_ko_lab_tallcase1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1tallcase1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1tallcase1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},		
	

	decor_ko_lab_case1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1case1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1case1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_ko_lab_buckets1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1buckets1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1buckets1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		
	
	decor_ko_lab_cabinet1 =
	{                                
		build = { "data/anims/KO_lab/ko_lab_object_1x1cabinet1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1cabinet1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	
	
	decor_ko_lab_cabinetscreen1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1cabinetscreen1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1cabinetscreen1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	
	
	decor_ko_lab_console1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1console1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1console1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	
	
	decor_ko_lab_crane1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1crane1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1crane1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		
	
	decor_ko_lab_locker1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1locker1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1locker1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_lab_machine1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1machine1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1machine1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_ko_lab_pillar1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1pillar1item1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1pillar1item1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_verytall_med,
	},	

	decor_ko_lab_weldinggear1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1weldinggear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1weldinggear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_ko_lab_catwalk1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x1catwalk1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x1catwalk1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		

	decor_ko_lab_longcase1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x1longcase.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x1longcase.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},			

	decor_ko_lab_rocketbench1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x1rocketbench.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x1rocketbench.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		

	decor_ko_lab_draftingtable1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x1draftingtable2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x1draftingtable2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		

	decor_ko_lab_pushcart1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x1pushcart1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x1pushcart1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_lab_rebar1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x1rebar1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x1rebar1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_lab_reobotarm1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x1robotarm1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x1robotarm1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_lab_weldingtable1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x1weldingtable1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x1weldingtable1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_lab_workbench1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x1workbench1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x1workbench1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		

	decor_ko_lab_pit1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x3pit1.abld", "data/anims/general/mf_coverpieces_2x3.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x3pit1.adef", "data/anims/general/mf_coverpieces_2x3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
	},	

	decor_ko_lab_pit2 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x3pit2.abld", "data/anims/general/mf_coverpieces_2x3.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x3pit2.adef", "data/anims/general/mf_coverpieces_2x3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
	},	


	-- KO BARRACKS ---------------------------------------------------------------------------------------------


	decor_ko_barracks_calendar1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_decor_calendar1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_decor_calendar1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_ko_barracks_poster1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_decor_poster1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_decor_poster1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_ko_barracks_walllight1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_decor_walllight1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_decor_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_ko_barracks_walldivider1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1walldivider1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1walldivider1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_barracks_walldividerguns1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1walldividerguns1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1walldividerguns1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_ko_barracks_armourlocker1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1armourlocker1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1armourlocker1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_barracks_chair1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_barracks_exercisebike1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1exercisebike1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1exercisebike1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_barracks_footlocker1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1footlocker1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1footlocker1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_barracks_freeweights1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1freeweights1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1freeweights1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_barracks_fridge1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1fridge1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1fridge1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},		

	decor_ko_barracks_laundryhamper1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1laundryhamper1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1laundryhamper1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_ko_barracks_punchingdummy1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1punchingdummy1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1punchingdummy1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_barracks_walllocker1 = 
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_2x1walllocker1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_2x1walllocker1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	


	decor_ko_barracks_vendingmachine1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1vendingmachine1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1vendingmachine1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_barracks_weights1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1weights1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1weights1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_barracks_bench1 = 
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_2x1bench1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_2x1bench1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_barracks_bunk1 = 
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_2x1bunk1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_2x1bunk1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},		

	decor_ko_barracks_table1 = 
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_2x1table1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_2x1table1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_ko_barracks_treadmill1 = 
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_2x1treadmill1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_2x1treadmill1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},


	decor_ko_barracks_weightbench1 = 
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_2x1weightbench1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_2x1weightbench1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		

	decor_ko_barracks_weightrack1 = 
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_2x1weightrack1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_2x1weightrack1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	



	-- KO HALL ---------------------------------------------------------------------------------------------


	decor_ko_hall_picture1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_decor_picture1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_decor_picture1.adef" },
		anim = "idle",
		scale = 0.25,
		--layer = Layer.Decor,
		boundType = BoundType.Wall_Painting,
		skins = { "KO_hall_painting" },
	},	

	decor_ko_hall_picture2 =
	{
		build = { "data/anims/KO_Hall/ko_hall_decor_picture2.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_decor_picture2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "KO_hall_painting" },
	},	

	decor_ko_hall_walllamp1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_decor_walllamp.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_decor_walllamp.adef" },
		anim = "idle",
		scale = 0.25,
		--layer = Layer.Decor,
		boundType = BoundType.Wall,
	},	

	decor_ko_hall_chair1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_hall_cornershelf1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1cornershelf1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1cornershelf1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_hall_grandfatherclock1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1grandfatherclock1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1grandfatherclock1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_hall_planter1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1planter1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1planter1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_hall_podium1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1podium1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1podium1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_ko_hall_podium2 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1podium2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1podium2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_ko_hall_sidetable1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1sidetable3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1sidetable3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_ko_hall_sittingbox1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1sittingbox1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1sittingbox1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_hall_smallplanter1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1smallplanter1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1smallplanter1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_ko_hall_standinglamp1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_1x1standinglamp1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_1x1standinglamp1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_hall_bookshelf1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_2x1bookshelf1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_2x1bookshelf1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	

	decor_ko_hall_chest1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_2x1chest1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_2x1chest1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_hall_couch1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_2x1couch1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_2x1couch1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_ko_hall_sidetable1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_2x1sidetable1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_2x1sidetable1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_ko_hall_sidetable2 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_2x1sidetable2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_2x1sidetable2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	


	-- SEIKAKU LAB ---------------------------------------------------------------------------------------------

	decor_sk_lab_barrel1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1barrel.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1barrel.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_lab_bookshelf1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1bookshelf.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1bookshelf.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},

	decor_sk_lab_boxes1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1boxes.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1boxes.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_lab_chair1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1chair.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1chair.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_lab_computer1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1computer.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1computer.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_lab_crane1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1crane.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1crane.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_sk_lab_drafting_table1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1drafting_table.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1drafting_table.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},				
	
	decor_sk_lab_gear1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1lab_gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1lab_gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	
	
	decor_sk_lab_gear2 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1lab_gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1lab_gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	
	
	decor_sk_lab_gear4 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1lab_gear4.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1lab_gear4.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	
	
	decor_sk_lab_recording_computer1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1recording_computer.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1recording_computer.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	
	
	decor_sk_lab_scrap_bin1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1scrap_bin.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1scrap_bin.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	
	
	decor_sk_lab_stand1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1stand.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1stand.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},
	
	decor_sk_lab_standing_tower1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1standing_tower.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1standing_tower.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	
	
	decor_sk_lab_wall_processor1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1wall_processor.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1wall_processor.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		
	
	decor_sk_lab_welding_machine1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1welding_machine.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_1x1welding_machine.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	
	
	decor_sk_lab_conveyor_belt1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1conveyor_belt.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1conveyor_belt.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		
	
	decor_sk_lab_desk1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1desk.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1desk.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},
	
	decor_sk_lab_gunrack1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1gunrack.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1gunrack.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},
	
	decor_sk_lab_gear3 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1lab_gear3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1lab_gear3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	
	
	decor_sk_lab_table2 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1table2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1table2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	
	
	decor_sk_lab_turbine_box1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1turbine_box.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_lab_object_2x1turbine_box.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	


	decor_sk_lab_wall_folders1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_office_decor_folders.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_office_decor_folders.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_sk_lab_wall_phonepanel1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_office_decor_phonepanel1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_office_decor_phonepanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_sk_lab_wall_light1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_office_decor_wall_light_1.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_office_decor_wall_light_1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	decor_sk_lab_wall_light2 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_office_decor_wall_light_2.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_office_decor_wall_light_2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	decor_sk_lab_wall_light3 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_office_decor_wall_light_3.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_office_decor_wall_light_3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	decor_sk_lab_wall_panel1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_office_decor_wall_panel.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_office_decor_wall_panel.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},	

	decor_sk_lab_wall_whiteboard1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_office_decor_whiteboard.abld" },
		anims = { "data/anims/Seikaku_lab/seikaku_office_decor_whiteboard.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},			





	decor_sk_office_wall_paintings1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_decor_paintings1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_decor_paintings1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "SK_office_painting" },
	},	

	decor_sk_office_wall_paintings2 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_decor_paintings2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_decor_paintings2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "SK_office_painting" },
	},	

	decor_sk_office_wall_paintings3 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_decor_paintings3.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_decor_paintings3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
		skins = { "SK_office_painting" },
	},

	decor_sk_office_wall_paintings4 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_decor_paintings4.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_decor_paintings4.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall_Painting,
	},	

	decor_sk_office_wall_tv1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_decor_wall_tv.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_decor_wall_tv.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_sk_office_wall_light1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_decor_walllight.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_decor_walllight.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	


	decor_sk_office_podium1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1_podium1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1_podium1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
		skins = {"SK_office_podium"},
	},	

	decor_sk_office_podium2 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1_podium2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1_podium2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
		skins = {"SK_office_podium"},
	},	

	decor_sk_office_chair1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1chair.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1chair.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_office_lamp1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1lamp.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1lamp.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_sk_office_pillar1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1pillar.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1pillar.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_verytall_med,
	},	

	decor_sk_office_planter1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1planter.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1planter.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_office_planter2 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1planter2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1planter2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_office_shelf1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1shelf1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1shelf1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_sk_office_walldivider1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1walldivider.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1walldivider.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_office_ceo_desk1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_2x1ceodesk.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_2x1ceodesk.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_sk_office_cofeetable1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_2x1cofeetable.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_2x1cofeetable.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_sk_office_couch1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_2x1couch.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_2x1couch.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_sk_office_fishtank1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_2x1fishtank.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_2x1fishtank.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},

	decor_sk_office_desk1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_2x1officedesk.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_2x1officedesk.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_sk_office_shelf2 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_2x1shelf2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_2x1shelf2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},		

	decor_sk_office_tv1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_2x1tv.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_2x1tv.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	

	decor_sk_office_koipond1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_2x2koi_pond.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_2x2koi_pond.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},			


	decor_sk_bay_walllights1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_decor_walllights1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_decor_walllights1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_sk_bay_wallpanel1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_decor_wallpanel1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_decor_wallpanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_sk_bay_wallpanel2 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_decor_wallpanel2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_decor_wallpanel2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	
	
	decor_sk_bay_wallpanel3 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_decor_wallpanel3.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_decor_wallpanel3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},		

	decor_sk_bay_computerrack1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1computerrack.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1computerrack.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},

	decor_sk_bay_drone2 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1drone2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1drone2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_sk_bay_drone3 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1drone3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1drone3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_sk_bay_gear1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_bay_gear2 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_sk_bay_gear3 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1gear3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1gear3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_sk_bay_gear4 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1gear4.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1gear4.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_sk_bay_ionizer1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1ionizer1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1ionizer1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_bay_shortcrate1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1shortcrate.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1shortcrate.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_sk_bay_tallcrate1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1tallcrate.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1tallcrate.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},

	decor_sk_bay_bodyshop1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1bodyshop1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1bodyshop1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},			

	decor_sk_bay_cannontester1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1cannontester1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1cannontester1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_sk_bay_crate1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1crate1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1crate1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_sk_bay_drone1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1drone1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1drone1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_sk_bay_fendermaker1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1fendermaker1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1fendermaker1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_sk_bay_roboliftdownempty1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1roboliftdownempty1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1roboliftdownempty1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_sk_bay_roboliftupdrone1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1roboliftupdrone1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1roboliftupdrone1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},						

	decor_sk_bay_roboliftupempty1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1roboliftupempty1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1roboliftupempty1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_sk_bay_worktable1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1worktable1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_2x1worktable1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		


	decor_plastek_office_wall_picture1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_decor_1x1picture1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_decor_1x1picture1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_plastek_office_wall_picture2 =
	{
		build = { "data/anims/Plastek_office/plastek_office_decor_1x1picture2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_decor_1x1picture2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	
	
	decor_plastek_office_wall_reeltoreel1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_decor_1x1reeltoreel1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_decor_1x1reeltoreel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},
	
	decor_plastek_office_wall_grate1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_decor_1x1wallgrate1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_decor_1x1wallgrate1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	
	
	decor_plastek_office_wall_light1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_decor_1x1walllight1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_decor_1x1walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},		
	
	decor_plastek_office_wall_panel1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_decor_1x1wallpanel1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_decor_1x1wallpanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	decor_plastek_office_wall_panel2 =
	{
		build = { "data/anims/Plastek_office/plastek_office_decor_1x1wallpanel2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_decor_1x1wallpanel2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	decor_plastek_office_wall_screen2 =
	{
		build = { "data/anims/Plastek_office/plastek_office_decor_2x1wallscreen2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_decor_2x1wallscreen2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},	

	decor_plastek_office_chair1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_office_chair2 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1chair2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1chair2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_office_computer1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1computer1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1computer1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_office_filecabinet2 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1filecabinet2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1filecabinet2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	


	decor_plastek_office_floorlamp1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1floorlamp1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1floorlamp1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_plastek_office_office_chair1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1officechair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1officechair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			

	decor_plastek_office_planter1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1planter1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1planter1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_plastek_office_planter2 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1planter2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1planter2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_office_podium1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1podium1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1podium1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_plastek_office_sidetable1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1sidetable1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1sidetable1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_plastek_office_walldivider1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_1x1walldivider1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_1x1walldivider1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_office_bench1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1bench1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1bench1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_office_coffeetable1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1coffeetable1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1coffeetable1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},							

	decor_plastek_office_coffeetable2 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1coffeetable2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1coffeetable2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_office_coffeetable3 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1coffeetable3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1coffeetable3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_office_couch1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1couch1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1couch1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		

	decor_plastek_office_desk1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1desk1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1desk1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_office_desk2 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1desk2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1desk2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_office_2x1filecabinet1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1filecabinet1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1filecabinet1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_office_shelf1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1shelf1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1shelf1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},		

	decor_plastek_office_standingscreen1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x1standingscreen1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x1standingscreen1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},		

	decor_plastek_office_tree1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_object_2x2tree1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/Plastek_office/plastek_office_object_2x2tree1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},	






	decor_plastek_psilab_wall_light1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_decor_1x1walllight.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_decor_1x1walllight.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_plastek_psilab_wall_piece1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_decor_1x1wallpiece1.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_decor_1x1wallpiece1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_plastek_psilab_wall_monitor1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_decor_2x1wallmonitor1.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_decor_2x1wallmonitor1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},		

	decor_plastek_psilab_bedsidemonitor1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1bedsidemonitor1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1bedsidemonitor1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_plastek_psilab_cabinet1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1cabinet1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1cabinet1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_plastek_psilab_gurneyup1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1gurneyup1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1gurneyup1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_psilab_gear1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1psilabgear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1psilabgear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_psilab_sidetable1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1sidetable1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1sidetable1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_psilab_standingmonitor1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1standingmonitor1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1standingmonitor1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_psilab_bed1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1bed1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1bed1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_psilab_bookshelf1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1bookshelf1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1bookshelf1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	

	decor_plastek_psilab_gurneyflat1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1gurneyflat1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1gurneyflat1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_psilab_gear2 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1psilabgear2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1psilabgear2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_psilab_tank1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1psitank1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1psitank1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},		

	decor_plastek_psilab_tankgear1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1psitankgear1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1psitankgear1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},		

	decor_plastek_psilab_reeducator =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1reeducator.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1reeducator.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		

	decor_plastek_psilab_table1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1table1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1table1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		







	decor_plastek_lab_wall_box1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_decor_1x1wallbox1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_decor_1x1wallbox1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_plastek_lab_wall_grate1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_decor_1x1wallgrate1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_decor_1x1wallgrate1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_plastek_lab_wall_panel1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_decor_1x1wallpanel1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_decor_1x1wallpanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},	

	decor_plastek_lab_wall_panel2 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_decor_1x1wallpanel2.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_decor_1x1wallpanel2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},		

	decor_plastek_lab_cabinet1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_1x1cabinet1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_1x1cabinet1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_lab_chair1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_lab_computer1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_1x1computer1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_1x1computer1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_plastek_lab_machine1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_1x1machine1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_1x1machine1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_plastek_lab_machine2 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_1x1machine2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_1x1machine2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_plastek_lab_machine4 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_1x1machine4.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_1x1machine4.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_lab_processor1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_1x1processor1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_1x1processor1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_plastek_lab_processor2 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_1x1processor2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_1x1processor2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},

	decor_plastek_lab_console1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_2x1console1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_2x1console1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_lab_console2 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_2x1console2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_2x1console2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_lab_desk1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_2x1desk1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_2x1desk1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_plastek_lab_floorhatch1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_2x1floorhatch1.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_2x1floorhatch1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},	

	decor_plastek_lab_machine3 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_2x1machine3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_2x1machine3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	decor_plastek_lab_machine5 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_2x1machine5.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_2x1machine5.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_plastek_lab_machine6 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_2x1machine6.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_2x1machine6.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},

	decor_plastek_lab_processor3 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_2x1processor3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_2x1processor3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},						

	decor_plastek_lab_floorhatch2 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_2x2floorhatch2.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_2x2floorhatch2.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},		






	decor_plastek_hall_wall_picture1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_decor_1x1picture1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_decor_1x1picture1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},		

	decor_plastek_hall_wall_picture2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_decor_1x1picture2.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_decor_1x1picture2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},		

	decor_plastek_hall_wall_picture3 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_decor_1x1picture3.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_decor_1x1picture3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_plastek_hall_wall_picture4 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_decor_1x1picture4.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_decor_1x1picture4.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_plastek_hall_wall_light1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_decor_1x1walllights1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_decor_1x1walllights1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	decor_plastek_hall_wall_light2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_decor_1x1walllights2.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_decor_1x1walllights2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	decor_plastek_hall_bookshelf1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1bookshelf1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1bookshelf1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},		

	decor_plastek_hall_chair1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_hall_coffeetable1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1coffeetable1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1coffeetable1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_plastek_hall_floorlamp1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1floorlamp1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1floorlamp1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_hall_planter1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1planter1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1planter1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_hall_planter2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1planter2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1planter2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_hall_sculpture1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1sculpture1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1sculpture1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},		

	decor_plastek_hall_sculpture2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1sculpture2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1sculpture2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},												

	decor_plastek_hall_sidetable1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1sidetable1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1sidetable1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_hall_sidetable2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1sidetable2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1sidetable2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_hall_sidetable3 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1sidetable3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1sidetable3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			

	decor_plastek_hall_walldivider1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1walldivider1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1walldivider1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			

	decor_plastek_hall_bookshelf2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_2x1bookshelf2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_2x1bookshelf2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	

	decor_plastek_hall_coffeetable2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_2x1coffeetable2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_2x1coffeetable2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},				

	decor_plastek_hall_lowcabinet1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_2x1lowcabinet1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_2x1lowcabinet1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},				

	decor_plastek_hall_lowcabinet2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_2x1lowcabinet2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_2x1lowcabinet2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},		

	decor_plastek_hall_sofa1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_2x1sofa1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_2x1sofa1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	


	serverroom_1x1_bigcomp1 =
	{                            
		build = { "data/anims/Unique_serverroom/serverroom_1x1_bigcomp1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_serverroom/serverroom_1x1_bigcomp1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			

	serverroom_1x1_gear1 =
	{
		build = { "data/anims/Unique_serverroom/serverroom_1x1_gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_serverroom/serverroom_1x1_gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			

	serverroom_1x3_gear2 =
	{
		build = { "data/anims/Unique_serverroom/serverroom_1x3_gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_serverroom/serverroom_1x3_gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_3x1_tall_med,
	},			

	serverroom_1x1_gear3 =
	{
		build = { "data/anims/Unique_serverroom/serverroom_1x1_gear3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_serverroom/serverroom_1x1_gear3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			

	serverroom_walllight1 =
	{
		build = { "data/anims/Unique_serverroom/serverroom_walllight1.abld" },
		anims = { "data/anims/Unique_serverroom/serverroom_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	serverroom_wallscreen1 =
	{
		build = { "data/anims/Unique_serverroom/serverroom_wallscreen1.abld" },
		anims = { "data/anims/Unique_serverroom/serverroom_wallscreen1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},

	serverroom_wallslats1 =
	{
		build = { "data/anims/Unique_serverroom/serverroom_wallslats1.abld" },
		anims = { "data/anims/Unique_serverroom/serverroom_wallslats1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},


	serverroom_flooring_wiring1 =
	{
		build = { "data/anims/Unique_serverroom/serverroom_flooring_wiring1.abld"},
		anims = { "data/anims/Unique_serverroom/serverroom_flooring_wiring1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
		setlayer = "floor",
	},	

	serverroom_flooring_wiring2 =
	{
		build = { "data/anims/Unique_serverroom/serverroom_flooring_wiring2.abld"},
		anims = { "data/anims/Unique_serverroom/serverroom_flooring_wiring2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
		setlayer = "floor",
	},	

	serverroom_flooring_wiring3 =
	{
		build = { "data/anims/Unique_serverroom/serverroom_flooring_wiring3.abld"},
		anims = { "data/anims/Unique_serverroom/serverroom_flooring_wiring3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
		setlayer = "floor",
	},	




	guardoffice_1x1_chair1 =
	{                            
		build = { "data/anims/Unique_guardoffice/guardoffice_1x1_chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_1x1_chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	guardoffice_1x1_gear1 =
	{                            
		build = { "data/anims/Unique_guardoffice/guardoffice_1x1_gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_1x1_gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			
		


	guardoffice_1x1_fridgesafe1 =
	{                            
		build = { "data/anims/Unique_guardoffice/guardoffice_1x1_fridgesafe1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_1x1_fridgesafe1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			
		





	guardoffice_1x1_gear2 =
	{                            
		build = { "data/anims/Unique_guardoffice/guardoffice_1x1_gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_1x1_gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			
		

	guardoffice_2x1_bench1 =
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_2x1_bench1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_2x1_bench1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	guardoffice_2x1_desk1 =
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_2x1_desk1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_2x1_desk1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	guardoffice_2x2_interogationtable1=
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_2x2_interogationtable1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_2x2_interogationtable1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x2,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	guardoffice_walllight1 =
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_walllight1.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},



	guardoffice_walldecal1 =
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_walldecal1.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_walldecal1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},



	guardoffice_1x1_floorpanel1 =
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_1x1_floorpanel1.abld"},
		anims = { "data/anims/Unique_guardoffice/guardoffice_1x1_floorpanel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},	



	guardoffice_1x1_floorpanel2 =
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_1x1_floorpanel2.abld"},
		anims = { "data/anims/Unique_guardoffice/guardoffice_1x1_floorpanel2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},	


	guardoffice_wallphone1 =
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_wallphone1.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_wallphone1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	guardoffice_wallslat1 =
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_wallslat1.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_wallslat1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	guardoffice_wallwindow1 =
	{
		build = { "data/anims/Unique_guardoffice/guardoffice_wallwindow1.abld" },
		anims = { "data/anims/Unique_guardoffice/guardoffice_wallwindow1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},




	vault_1x1_paintings1 =
	{                            
		build = { "data/anims/Unique_Vault/vault_1x1_paintings1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_Vault/vault_1x1_paintings1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			

	vault_1x1_podium1 =
	{                            
		build = { "data/anims/Unique_Vault/vault_1x1_podium1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_Vault/vault_1x1_podium1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			

	vault_1x1_podium2 =
	{                            
		build = { "data/anims/Unique_Vault/vault_1x1_podium2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_Vault/vault_1x1_podium2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},			


	vault_2x1_paintings2 =
	{
		build = { "data/anims/Unique_Vault/vault_2x1_paintings2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_Vault/vault_2x1_paintings2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	


	vault_2x1_standinglocker1 =
	{
		build = { "data/anims/Unique_Vault/vault_2x1_standinglocker1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_Vault/vault_2x1_standinglocker1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	vault_2x1_standinglocker2 =
	{
		build = { "data/anims/Unique_Vault/vault_2x1_standinglocker2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_Vault/vault_2x1_standinglocker2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	

	vault_walllockerbig1 =
	{
		build = { "data/anims/Unique_Vault/vault_walllockerbig1.abld" },
		anims = { "data/anims/Unique_Vault/vault_walllockerbig1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},

	vault_walllockersmall1 =
	{
		build = { "data/anims/Unique_Vault/vault_walllockersmall1.abld" },
		anims = { "data/anims/Unique_Vault/vault_walllockersmall1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},

	publicterminal_1x1_planter1 =
	{                                                  
		build = { "data/anims/Unique_publicterminal/publicterminal_1x1_planter1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_publicterminal/publicterminal_1x1_planter1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			

	publicterminal_1x1_standingterminal1 =
	{                            
		build = { "data/anims/Unique_publicterminal/publicterminal_1x1_standingterminal1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_publicterminal/publicterminal_1x1_standingterminal1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			


	publicterminal_1x1_wallterminal1 =
	{                            
		build = { "data/anims/Unique_publicterminal/publicterminal_1x1_wallterminal1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_publicterminal/publicterminal_1x1_wallterminal1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			


	publicterminal_1x1_wallterminal2 =
	{                            
		build = { "data/anims/Unique_publicterminal/publicterminal_1x1_wallterminal2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_publicterminal/publicterminal_1x1_wallterminal2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			


	publicterminal_2x1_desk1 =
	{
		build = { "data/anims/Unique_publicterminal/publicterminal_2x1_desk1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_publicterminal/publicterminal_2x1_desk1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	



	publicterminal_2x3_couch1=
	{
		build = { "data/anims/Unique_publicterminal/publicterminal_2x3_couch1.abld", "data/anims/general/mf_coverpieces_2x3.abld" },
		anims = { "data/anims/Unique_publicterminal/publicterminal_2x3_couch1.adef", "data/anims/general/mf_coverpieces_2x3.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_2x3,
		filterSymbols = {{symbol="icon",filter="default"}},
	},	


	publicterminal_bookshelf1 =
	{
		build = { "data/anims/Unique_publicterminal/publicterminal_bookshelf1.abld" },
		anims = { "data/anims/Unique_publicterminal/publicterminal_bookshelf1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall3,
	},
		
	publicterminal_flooring_1x1rug1 =
	{
		build = { "data/anims/Unique_publicterminal/publicterminal_flooring_1x1rug1.abld"},
		anims = { "data/anims/Unique_publicterminal/publicterminal_flooring_1x1rug1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x3,
		setlayer = "floor",
	},		
		
	publicterminal_flooring_1x1rug2 =
	{
		build = { "data/anims/Unique_publicterminal/publicterminal_flooring_1x1rug2.abld"},
		anims = { "data/anims/Unique_publicterminal/publicterminal_flooring_1x1rug2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x3,
		setlayer = "floor",
	},		


	publicterminal_glasswall1 =
	{
		build = { "data/anims/Unique_publicterminal/publicterminal_glasswall1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_publicterminal/publicterminal_glasswall1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},	

	holdingcell_1x1_celldoor1 =
	{                            
		build = { "data/anims/Unique_holdingcell/holdingcell_1x1_celldoor1.abld", "data/anims/general/mf_coverpieces_1x1.abld"},
		anims = { "data/anims/Unique_holdingcell/holdingcell_1x1_celldoor1.adef", "data/anims/general/mf_coverpieces_1x1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},			


	holdingcell_1x1_cellwall1 =
	{                            
		build = { "data/anims/Unique_holdingcell/holdingcell_1x1_cellwall1.abld" },
		anims = { "data/anims/Unique_holdingcell/holdingcell_1x1_cellwall1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},			


	holdingcell_2x1_cellwall2 =
	{
		build = { "data/anims/Unique_holdingcell/holdingcell_2x1_cellwall2.abld" },
		anims = { "data/anims/Unique_holdingcell/holdingcell_2x1_cellwall2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},	


	holdingcell_2x1_securecell1 =
	{
		build = { "data/anims/Unique_holdingcell/holdingcell_2x1_securecell1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_holdingcell/holdingcell_2x1_securecell1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	


	holdingcell_2x1_bunk1 =
	{
		build = { "data/anims/Unique_holdingcell/holdingcell_2x1_bunk1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_holdingcell/holdingcell_2x1_bunk1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	








	nanofab_1x1_computerpedestal1 =
	{                            
		build = { "data/anims/Unique_nanofab/nanofab_1x1_computerpedestal1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_nanofab/nanofab_1x1_computerpedestal1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			

	nanofab_1x1_cornerscreenl1 =
	{                            
		build = { "data/anims/Unique_nanofab/nanofab_1x1_cornerscreenl1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_nanofab/nanofab_1x1_cornerscreenl1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			

	nanofab_1x1_pillar1 =
	{                            
		build = { "data/anims/Unique_nanofab/nanofab_1x1_pillar1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_nanofab/nanofab_1x1_pillar1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_big,
	},			

	nanofab_1x1_standingterminal1 =
	{                            
		build = { "data/anims/Unique_nanofab/nanofab_1x1_standingterminal1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_nanofab/nanofab_1x1_standingterminal1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			

	nanofab_2x1_displaycase1 =
	{
		build = { "data/anims/Unique_nanofab/nanofab_2x1_displaycase1.abld" },
		anims = { "data/anims/Unique_nanofab/nanofab_2x1_displaycase1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall3,
	},	

	nanofab_2x1_largerprinter1 =
	{
		build = { "data/anims/Unique_nanofab/nanofab_2x1_largerprinter1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_nanofab/nanofab_2x1_largerprinter1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	


	nanofab_2x2_catalog1 =
	{
		build = { "data/anims/Unique_nanofab/nanofab_2x2_catalog1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/Unique_nanofab/nanofab_2x2_catalog1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},	


	nanofab_2x2_flooring_panel1 =
	{
		build = { "data/anims/Unique_nanofab/nanofab_2x2_flooring_panel1.abld"},
		anims = { "data/anims/Unique_nanofab/nanofab_2x2_flooring_panel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},
				

	nanofab_1x1_specialfab1 =
	{                            
		build = { "data/anims/Unique_nanofab/nanofab_1x1_specialfab1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_nanofab/nanofab_1x1_specialfab1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},			







-- KO floor crap  ---------------------------------------------------------------------------------------------



	decor_KO_lab_flooring_manhole1 =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1manhole1.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1manhole1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},
				

	decor_KO_lab_flooring_panel1 =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel1.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},
	
	decor_KO_lab_flooring_panel2off =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel2off.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel2off.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},
	
	decor_KO_lab_flooring_panel2on =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel2on.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel2on.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},
				
		
	decor_KO_lab_flooring_panel3off =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel3off.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel3off.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_5x3,
		setlayer = "floor",
	},		
		
	decor_KO_lab_flooring_panel3on =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel3on.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel3on.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x3,
		setlayer = "floor",
	},		
	
	decor_KO_lab_flooring_panel4off =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel4off.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel4off.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x3,
		setlayer = "floor",
	},
	
	decor_KO_lab_flooring_panel4on =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel4on.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel4on.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},
	
	decor_KO_lab_flooring_panel5on =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel5on.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel5on.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
		setlayer = "floor",
	},	
	
	decor_KO_lab_flooring_panel6off =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel6off.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel6off.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x4,
		setlayer = "floor",
	},
	
	decor_KO_lab_flooring_panel6on =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel6on.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel6on.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x3,
		setlayer = "floor",
	},	

	decor_KO_lab_flooring_panel7off =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel7off.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel7off.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},	
	
	decor_KO_lab_flooring_panel7on =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel7on.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel7on.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x1,
		setlayer = "floor",
	},
	
	decor_KO_lab_flooring_panel8on =
	{
		build = { "data/anims/KO_lab/ko_lab_flooring_1x1panel8on.abld"},
		anims = { "data/anims/KO_lab/ko_lab_flooring_1x1panel8on.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x3,
		setlayer = "floor",
	},
	
	decor_KO_Hall_flooring_doormat1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_flooring_1x1doormat1.abld"},
		anims = { "data/anims/KO_Hall/ko_hall_flooring_1x1doormat1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_KO_Hall_flooring_rug1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_flooring_1x1rug1.abld"},
		anims = { "data/anims/KO_Hall/ko_hall_flooring_1x1rug1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x3,
		setlayer = "floor",
	},


	decor_KO_hall_flooring_rug2 =
	{
		build = { "data/anims/KO_Hall/ko_hall_flooring_1x1rug2.abld"},
		anims = { "data/anims/KO_Hall/ko_hall_flooring_1x1rug2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_KO_hall_flooring_rug3 =
	{
		build = { "data/anims/KO_Hall/ko_hall_flooring_1x1rug3.abld"},
		anims = { "data/anims/KO_Hall/ko_hall_flooring_1x1rug3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x4,
		setlayer = "floor",
	},


	decor_KO_hall_flooring_rug4 =
	{
		build = { "data/anims/KO_Hall/ko_hall_flooring_1x1rug4.abld"},
		anims = { "data/anims/KO_Hall/ko_hall_flooring_1x1rug4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x4,
		setlayer = "floor",
	},


	decor_KO_office_flooring_rug1 =
	{
		build = { "data/anims/KO_office/ko_office_flooring_1x1rug1.abld"},
		anims = { "data/anims/KO_office/ko_office_flooring_1x1rug1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_KO_office_flooring_rug2 =
	{
		build = { "data/anims/KO_office/ko_office_flooring_1x1rug2.abld"},
		anims = { "data/anims/KO_office/ko_office_flooring_1x1rug2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_6x4,
		setlayer = "floor",
	},

	decor_KO_office_flooring_rug3 =
	{
		build = { "data/anims/KO_office/ko_office_flooring_1x1rug3.abld"},
		anims = { "data/anims/KO_office/ko_office_flooring_1x1rug3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x4,
		setlayer = "floor",
	},

	decor_KO_office_flooring_rug4 =
	{
		build = { "data/anims/KO_office/ko_office_flooring_1x1rug4.abld"},
		anims = { "data/anims/KO_office/ko_office_flooring_1x1rug4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_5x3,
		setlayer = "floor",
	},

	decor_KO_office_flooring_rugoff1 =
	{
		build = { "data/anims/KO_office/ko_office_flooring_1x1rugoff1.abld"},
		anims = { "data/anims/KO_office/ko_office_flooring_1x1rugoff1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x3,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_alt2 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1alt2.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1alt2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_alt3 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1alt3.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1alt3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_alt4 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1alt4.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1alt4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x2,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_dark1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark1.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},


	decor_Seikaku_lab_flooring_dark2 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark2.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_dark3 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark3.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_dark4 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark4.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_dark5 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark5.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1dark5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_light1 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light1.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},


	decor_Seikaku_lab_flooring_light2 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light2.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},


	decor_Seikaku_lab_flooring_light3 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light3.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x2,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_light4 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light4.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_light5 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light5.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_light6 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light6.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light6.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_lab_flooring_light7 =
	{
		build = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light7.abld"},
		anims = { "data/anims/Seikaku_lab/seikaku_lab_flooring_1x1light7.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_alt1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1alt1.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1alt1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_alt3 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1alt3.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1alt3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_alt4 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1alt4.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1alt4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x2,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_dark1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark1.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_dark2 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark2.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_dark3 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark3.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_dark4 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark4.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_dark5 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark5.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1dark5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_light2 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light2.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_light3 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light3.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x2,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_light4 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light4.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_light5 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light5.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_light6 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light6.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light6.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_robobay_flooring_light7 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light7.abld"},
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_flooring_1x1light7.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1off_alt1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1alt1.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1alt1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_5x2,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1off_alt2 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1alt2.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1alt2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_5x2,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1off_tatami1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1tatami1.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1tatami1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x4,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1off_tatami2 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1tatami2.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1tatami2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_5x3,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1off_tatami3 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1tatami3.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1tatami3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x4,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1off_tatami4 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1tatami4.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1off_1x1tatami4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1on_alt1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1alt1.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1alt1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_5x2,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1on_alt2 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1alt2.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1alt2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_5x2,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1on_tatami1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1tatami1.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1tatami1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1on_tatami2 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1tatami2.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1tatami2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x4,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1on_tatami3 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1tatami3.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1tatami3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x3,
		setlayer = "floor",
	},

	decor_Seikaku_office_flooring1on_tatami4 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1tatami4.abld"},
		anims = { "data/anims/Seikaku_office/seikaku_office_flooring1on_1x1tatami4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x2,
		setlayer = "floor",
	},

	decor_plastek_office_flooring_1x1rug1 =
	{
		build = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug1.abld"},
		anims = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x4,
		setlayer = "floor",
	},

	decor_plastek_office_flooring_1x1rug2 =
	{
		build = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug2.abld"},
		anims = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x3,
		setlayer = "floor",
	},

	decor_plastek_office_flooring_1x1rug3 =
	{
		build = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug3.abld"},
		anims = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x3,
		setlayer = "floor",
	},

	decor_plastek_office_flooring_1x1rug4 =
	{
		build = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug4.abld"},
		anims = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x2,
		setlayer = "floor",
	},

	decor_plastek_office_flooring_1x1rug5 =
	{
		build = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug5.abld"},
		anims = { "data/anims/Plastek_office/plastek_office_flooring_1x1rug5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x1,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1dark1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark1.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x1,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1dark2 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark2.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1dark3 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark3.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1dark4 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark4.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1dark5 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark1.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1dark6 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark1.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1dark1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1light1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light1.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1light2 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light2.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1light3 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light3.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x1,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1light4 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light4.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x1,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1light5 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light5.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1light6 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light6.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light6.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_plastek_lab_flooring_1x1light7 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light7.abld"},
		anims = { "data/anims/Plastek_Lab/plastek_lab_flooring_1x1light7.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_plastek_hall_flooring_1x1rug1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug1.abld"},
		anims = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x4,
		setlayer = "floor",
	},

	decor_plastek_hall_flooring_1x1rug2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug2.abld"},
		anims = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_4x3,
		setlayer = "floor",
	},


	decor_plastek_hall_flooring_1x1rug3 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug3.abld"},
		anims = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x4,
		setlayer = "floor",
	},

	decor_plastek_hall_flooring_1x1rug4 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug4.abld"},
		anims = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x3,
		setlayer = "floor",
	},

	decor_plastek_hall_flooring_1x1rug5 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug5.abld"},
		anims = { "data/anims/Plastek_hall/plastek_hall_flooring_1x1rug5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_plastek_psilab_flooring_1x1alt1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1alt1.abld"},
		anims = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1alt1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_plastek_psilab_flooring_1x1alt2 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1alt2.abld"},
		anims = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1alt2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x3,
		setlayer = "floor",
	},

	decor_plastek_psilab_flooring_1x1alt3 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1alt3.abld"},
		anims = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1alt3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x1,
		setlayer = "floor",
	},

	decor_plastek_psilab_flooring_1x1alt4 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1alt4.abld"},
		anims = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1alt4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_plastek_psilab_flooring_1x1main1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1main1.abld"},
		anims = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1main1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x3,
		setlayer = "floor",
	},

	decor_plastek_psilab_flooring_1x1main2 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1main2.abld"},
		anims = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1main2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_plastek_psilab_flooring_1x1main3 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1main3.abld"},
		anims = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1main3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x2,
		setlayer = "floor",
	},

	decor_plastek_psilab_flooring_1x1main4 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1main4.abld"},
		anims = { "data/anims/Plastek_psilab/plastek_psilab_flooring_1x1main4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1caution1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1caution1.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1caution1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_5x3,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1caution2 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1caution2.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1caution2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1panel1 =
	{                             
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel1.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1panel2 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel2.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1panel3 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel3.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1panel4 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel4.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1panel5 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel5.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x1,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1panel6 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel6.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel6.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x1,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1panel7 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel7.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1panel7.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1wood1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1wood1.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1wood1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1wood2 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1wood2.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1wood2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x1,
		setlayer = "floor",
	},

	decor_ko_barracks_flooring_1x1wood3 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1wood3.abld"},
		anims = { "data/anims/KO_Barracks/ko_barracks_flooring_1x1wood3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x1,
		setlayer = "floor",
	},

	decor_ftm_hall_flooring_1x1rug1 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_flooring_1x1_rug1.abld"},
		anims = { "data/anims/FTM_hall/ftm_hall_flooring_1x1_rug1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_ftm_hall_flooring_1x1rug2 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_flooring_1x1_rug2.abld"},
		anims = { "data/anims/FTM_hall/ftm_hall_flooring_1x1_rug2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_ftm_hall_flooring_1x1rug3 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_flooring_1x1_rug3.abld"},
		anims = { "data/anims/FTM_hall/ftm_hall_flooring_1x1_rug3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_ftm_hall_flooring_1x1rug4 =
	{
		build = { "data/anims/FTM_hall/ftm_hall_flooring_1x1_rug_4.abld"},
		anims = { "data/anims/FTM_hall/ftm_hall_flooring_1x1_rug_4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1alt1=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt1.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x3,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1alt2=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt2.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x2,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1alt3=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt3.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x1,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1alt4=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt4.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1alt5=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt5.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_alt5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1panel0=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel0.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel0.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1panel1=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel1.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x2,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1panel2=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel2.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x2,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1panel3=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel3.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x1,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1panel4=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel4.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_ftm_lab_flooring_1x1panel5=
	{
		build = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel5.abld"},
		anims = { "data/anims/FTM_lab/ftm_lab_flooring_1x1_panel5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_ftm_office_flooring_1x1rug1=
	{
		build = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug1.abld"},
		anims = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
		setlayer = "floor",
	},

	decor_ftm_office_flooring_1x1rug2=
	{
		build = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug2.abld"},
		anims = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x2,
		setlayer = "floor",
	},

	decor_ftm_office_flooring_1x1rug3=
	{
		build = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug3.abld"},
		anims = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x2,
		setlayer = "floor",
	},

	decor_ftm_office_flooring_1x1rug4=
	{
		build = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug4.abld"},
		anims = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x2,
		setlayer = "floor",
	},

	decor_ftm_office_flooring_1x1rug5=
	{
		build = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug5.abld"},
		anims = { "data/anims/FTM_office/ftm_office_flooring_1x1_rug5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x3,
		setlayer = "floor",
	},

	decor_ftm_office_object_1x1tvcamera=
	{
		build = { "data/anims/FTM_office/ftm_office_object_1x1tvcamera.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_1x1tvcamera.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.OneByOne,
	},

	decor_ftm_office_object_2x1desk3=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1desk3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1desk3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_ftm_office_object_2x1ftmbanner1=
	{
		build = { "data/anims/FTM_office/ftm_office_object_2x1ftmbanner1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/FTM_office/ftm_office_object_2x1ftmbanner1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },

		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
	},




	decor_ceooffice_object_1x1chair1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_1x1_chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_1x1_chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_ceooffice_object_1x1chessboard1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_1x1_chessboard1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_1x1_chessboard1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_ceooffice_object_1x1planter1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_1x1_planter1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_1x1_planter1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_ceooffice_object_1x1podium1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_1x1_podium1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_1x1_podium1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_ceooffice_object_1x1sculpture1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_1x1_sculpture1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_1x1_sculpture1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_ceooffice_object_1x1sidetable1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_1x1_sidetable1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_1x1_sidetable1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_ceooffice_object_1x1statue1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_1x1_statue1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_1x1_statue1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_ceooffice_object_1x1stool1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_1x1_stool1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_1x1_stool1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_ceooffice_object_2x1couch1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_2x1_couch1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_2x1_couch1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_ceooffice_object_2x1fireplace1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_2x1_fireplace1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_2x1_fireplace1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med, 
	},

	decor_ceooffice_object_2x1liquorcabinet1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_2x1_liquorcabinet1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_2x1_liquorcabinet1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_ceooffice_object_3x1_ceodesk1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_3x1_ceodesk1.abld", "data/anims/general/mf_coverpieces_1x3.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_3x1_ceodesk1.adef", "data/anims/general/mf_coverpieces_1x3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_3x1_med_big, 
	},

	decor_ceooffice_object_3x2boardroomtable1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_3x2_boardroomtable1.abld", "data/anims/general/mf_coverpieces_2x3.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_3x2_boardroomtable1.adef", "data/anims/general/mf_coverpieces_2x3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x3, 
	},

	decor_ceooffice_object_ceooffice_walllight1 =
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_walllight1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	decor_ceooffice_object_ceooffice_vaultlockside1 =
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_vaultlockside1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_vaultlockside1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_ceooffice_object_ceooffice_vaultlockside2 =
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_vaultlockside2.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_vaultlockside2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_ceooffice_object_ceooffice_wallpanel1 =
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_wallpanel1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_wallpanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_ceooffice_object_ceooffice_wallscreen1 =
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_wallscreen1.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_wallscreen1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	decor_ceooffice_object_ceooffice_wallscreen2 =
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_wallscreen2.abld" },
		anims = { "data/anims/Unique_ceooffice/ceooffice_wallscreen2.adef" },
		anim = "idle",
		scale = 0.25,    		       
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_ceooffice_flooring_rug1=
	{
		build = { "data/anims/Unique_ceooffice/ceooffice_flooring_rug1.abld"},
		anims = { "data/anims/Unique_ceooffice/ceooffice_flooring_rug1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_3x3,
		setlayer = "floor",
	},

	decor_cybernetics_object_1x1cyborgtorso1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_1x1_cyborgtorso1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_1x1_cyborgtorso1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_cybernetics_object_1x1gear1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_1x1_gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_1x1_gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_cybernetics_object_1x1gear2=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_1x1_gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_1x1_gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_cybernetics_object_1x1gear4=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_1x1_gear4.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_1x1_gear4.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_cybernetics_object_1x1holoprojector1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_1x1_holoprojector1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_1x1_holoprojector1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_cybernetics_object_1x1rechargestation1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_1x1_rechargestation1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_1x1_rechargestation1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_cybernetics_object_1x1standingscreen1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_1x1_standingscreen1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_1x1_standingscreen1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_cybernetics_object_2x1chest1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_2x1_chest1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_2x1_chest1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_cybernetics_object_2x1chest2=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_2x1_chest2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_2x1_chest2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_cybernetics_object_2x1gear3=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_2x1_gear3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_2x1_gear3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_cybernetics_object_2x1liquidpool1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_2x1_liquidpool1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_2x1_liquidpool1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_cybernetics_object_2x1operatingtable1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_2x1_operatingtable1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_2x1_operatingtable1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},


	decor_cybernetics_object_walllight1 =
	{                                            
		build = { "data/anims/Unique_cybernetics/cybernetics_walllight1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_cybernetics_object_walllocker1 =
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_walllocker1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_walllocker1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_cybernetics_object_wallscreen1 =
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_wallscreen1.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_wallscreen1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_cybernetics_object_wallscreen2 =
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_wallscreen2.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_wallscreen2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	decor_cybernetics_flooring_1x1glassfloorpanel1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_1x1_glassfloorpanel1.abld"},
		anims = { "data/anims/Unique_cybernetics/cybernetics_1x1_glassfloorpanel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},


	decor_cybernetics_flooring_floordecal1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_floordecal1.abld"},
		anims = { "data/anims/Unique_cybernetics/cybernetics_floordecal1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_cybernetics_flooring_floordecal2=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_floordecal2.abld"},
		anims = { "data/anims/Unique_cybernetics/cybernetics_floordecal2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},





  
	decor_engineroom_1x1_gear2=
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_1x1_gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


  
	decor_engineroom_1x1_gear3=
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_gear3.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_1x1_gear3.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

  
	decor_engineroom_1x1_gear4=
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_gear4.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_1x1_gear4.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

  
	decor_engineroom_1x1_gear5=
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_gear5.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_1x1_gear5.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_engineroom_1x1_wallgear1 =
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_wallgear1.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_1x1_wallgear1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	decor_engineroom_2x1_floorpanel1=
	{
		build = { "data/anims/Final_engineroom/engineroom_2x1_floorpanel1.abld"},
		anims = { "data/anims/Final_engineroom/engineroom_2x1_floorpanel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x1,
		setlayer = "floor",
	},


	decor_engineroom_2x1_gear1=
	{
		build = { "data/anims/Final_engineroom/engineroom_2x1_gear1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_2x1_gear1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},


	decor_engineroom_2x1_gear6=
	{
		build = { "data/anims/Final_engineroom/engineroom_2x1_gear6.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_2x1_gear6.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},


	decor_engineroom_2x1_gear7=
	{
		build = { "data/anims/Final_engineroom/engineroom_2x1_gear7.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_2x1_gear7.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},


	decor_engineroom_2x1_gear8=
	{
		build = { "data/anims/Final_engineroom/engineroom_2x1_gear8.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_2x1_gear8.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_engineroom_2x1_stackedpipes1=
	{
		build = { "data/anims/Final_engineroom/engineroom_2x1_stackedpipes1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_2x1_stackedpipes1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},


	decor_engineroom_2x2_biggear1=
	{
		build = { "data/anims/Final_engineroom/engineroom_2x2_biggear1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_2x2_biggear1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},	


	decor_engineroom_2x2_biggear2=
	{
		build = { "data/anims/Final_engineroom/engineroom_2x2_biggear2.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_2x2_biggear2.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},	


	decor_engineroom_1x1_walllight1 =
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_walllight1.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_1x1_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_engineroom_1x1_wallpanel1 =
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_wallpanel1.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_1x1_wallpanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_engineroom_1x1_wallpanel2 =
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_wallpanel2.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_1x1_wallpanel2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	decor_engineroom_1x1_wallpanel3 =
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_wallpanel3.abld" },
		anims = { "data/anims/Final_engineroom/engineroom_1x1_wallpanel3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_engineroom_1x1_floorpanel2=
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_floorpanel2.abld"},
		anims = { "data/anims/Final_engineroom/engineroom_1x1_floorpanel2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_engineroom_1x1_floorpanel3=
	{
		build = { "data/anims/Final_engineroom/engineroom_1x1_floorpanel3.abld"},
		anims = { "data/anims/Final_engineroom/engineroom_1x1_floorpanel3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},






  
	decor_holostorage_1x1_chair1=
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

  
	decor_holostorage_1x1_cranegear1=
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_cranegear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_cranegear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

  
	decor_holostorage_1x1_gear1=
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_gear1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_gear1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},
  
	decor_holostorage_1x1_gear2=
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_gear2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_gear2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

  
	decor_holostorage_1x1_gear5=
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_gear5.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_gear5.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_big,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	decor_holostorage_1x1_wallgear2 =
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_wallgear2.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_wallgear2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_holostorage_1x1_wallgear3 =
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_wallgear3.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_wallgear3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_holostorage_2x1_desk1=
	{
		build = { "data/anims/Final_holostorage/holostorage_2x1_desk1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_2x1_desk1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_holostorage_2x1_desk2=
	{
		build = { "data/anims/Final_holostorage/holostorage_2x1_desk2.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_2x1_desk2.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_holostorage_2x1_desk3=
	{
		build = { "data/anims/Final_holostorage/holostorage_2x1_desk3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_2x1_desk3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},


	decor_holostorage_2x1_gear3=
	{
		build = { "data/anims/Final_holostorage/holostorage_2x1_gear3.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_2x1_gear3.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med, 
	},

	decor_holostorage_2x1_gear4=
	{
		build = { "data/anims/Final_holostorage/holostorage_2x1_gear4.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_2x1_gear4.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med, 
	},

	decor_holostorage_1x1_wallgear1 =
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_wallgear1.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_wallgear1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_holostorage_1x1_floorpanel1=
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_floorpanel1.abld"},
		anims = { "data/anims/Final_holostorage/holostorage_1x1_floorpanel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_holostorage_1x1_floorpanel2=
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_floorpanel2.abld"},
		anims = { "data/anims/Final_holostorage/holostorage_1x1_floorpanel2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_holostorage_1x1_floorpanel3=
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_floorpanel3.abld"},
		anims = { "data/anims/Final_holostorage/holostorage_1x1_floorpanel3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_holostorage_1x1_floorpanel4=
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_floorpanel4.abld"},
		anims = { "data/anims/Final_holostorage/holostorage_1x1_floorpanel4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_holostorage_1x1_wallpanel1 =
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_wallpanel1.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_wallpanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_holostorage_1x1_walllight1 =
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_walllight1.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_holostorage_1x1_walllight2 =
	{
		build = { "data/anims/Final_holostorage/holostorage_1x1_walllight2.abld" },
		anims = { "data/anims/Final_holostorage/holostorage_1x1_walllight2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},








  
	decor_missioncontrol_1x1_atm1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_atm1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_atm1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_missioncontrol_1x1_chair1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_chair1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_chair1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_missioncontrol_1x1_chair2=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_chair2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_chair2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_missioncontrol_1x1_holopodium1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_holopodium1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_holopodium1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_missioncontrol_1x1_holopodium2=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_holopodium2.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_holopodium2.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_missioncontrol_1x1_podiumcomp1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_podiumcomp1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_podiumcomp1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_missioncontrol_1x1_processorunit1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_processorunit1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_processorunit1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_missioncontrol_1x1_wallgear1 =
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_wallgear1.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_wallgear1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_missioncontrol_1x1_walllight1 =
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_walllight1.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_missioncontrol_2x1_bench1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_2x1_bench1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_2x1_bench1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_missioncontrol_2x1_console1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_2x1_console1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_2x1_console1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_missioncontrol_2x1_wallgear2 =
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_2x1_wallgear2.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_2x1_wallgear2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_missioncontrol_2x1_wallgear3 =
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_2x1_wallgear3.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_2x1_wallgear3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_missioncontrol_2x2_bigdesk1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_2x2_bigdesk1.abld", "data/anims/general/mf_coverpieces_2x2.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_2x2_bigdesk1.adef", "data/anims/general/mf_coverpieces_2x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x2,
	},	

	decor_missioncontrol_3x2_bigtable1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_3x2_bigtable1.abld", "data/anims/general/mf_coverpieces_2x3.abld" },
		anims = { "data/anims/Final_missioncontrol/missioncontrol_3x2_bigtable1.adef", "data/anims/general/mf_coverpieces_2x3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x3, 
	},

	decor_missioncontrol_1x1_floorpanel1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorpanel1.abld"},
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorpanel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_missioncontrol_1x1_floorpanel2=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorpanel2.abld"},
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorpanel2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_missioncontrol_1x1_floorpanel3=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorpanel3.abld"},
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorpanel3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_missioncontrol_1x1_floorpanel4=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorpanel4.abld"},
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorpanel4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_missioncontrol_1x1_floorvent1=
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorvent1.abld"},
		anims = { "data/anims/Final_missioncontrol/missioncontrol_1x1_floorvent1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_missioncontrol_6x4_bigfloorpiece1 =
	{
		build = { "data/anims/Final_missioncontrol/missioncontrol_6x4_bigfloorpiece1.abld"},
		anims = { "data/anims/Final_missioncontrol/missioncontrol_6x4_bigfloorpiece1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_6x4,
		setlayer = "floor",
	},






	decor_finalhall_1x1_crate1=
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_crate1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_crate1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_finalhall_1x1_doublecrate1=
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_doublecrate1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_doublecrate1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	decor_finalhall_2x1_bench1=
	{
		build = { "data/anims/Final_finalhall/finalhall_2x1_bench1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_2x1_bench1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

	decor_finalhall_1x1_floordecal1=
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_floordecal1.abld"},
		anims = { "data/anims/Final_finalhall/finalhall_1x1_floordecal1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_finalhall_1x1_floordecal2=
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_floordecal2.abld"},
		anims = { "data/anims/Final_finalhall/finalhall_1x1_floordecal2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_finalhall_2x1_floorpanel1=
	{
		build = { "data/anims/Final_finalhall/finalhall_2x1_floorpanel1.abld"},
		anims = { "data/anims/Final_finalhall/finalhall_2x1_floorpanel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x1,
		setlayer = "floor",
	},

	decor_finalhall_1x1_floorpanel2=
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_floorpanel2.abld"},
		anims = { "data/anims/Final_finalhall/finalhall_1x1_floorpanel2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_finalhall_1x1_floorpanel3=
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_floorpanel3.abld"},
		anims = { "data/anims/Final_finalhall/finalhall_1x1_floorpanel3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_finalhall_1x1_floorpanel5=
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_floorpanel5.abld"},
		anims = { "data/anims/Final_finalhall/finalhall_1x1_floorpanel5.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	decor_finalhall_1x1_wallgear1 =
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_wallgear1.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_wallgear1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_finalhall_1x1_wallgear2 =
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_wallgear2.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_wallgear2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	decor_finalhall_2x1_wallgear3 =
	{
		build = { "data/anims/Final_finalhall/finalhall_2x1_wallgear3.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_2x1_wallgear3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	decor_finalhall_1x1_wallgear4 =
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_wallgear4.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_wallgear4.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_finalhall_1x1_wallgear5 =
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_wallgear5.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_wallgear5.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_finalhall_1x1_wallgear6 =
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_wallgear6.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_wallgear6.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_finalhall_1x1_walllight1 =
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_walllight1.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_finalhall_2x1_wallpanel1 =
	{
		build = { "data/anims/Final_finalhall/finalhall_2x1_wallpanel1.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_2x1_wallpanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	decor_finalhall_1x1_wallpanel5 =
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_wallpanel5.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_wallpanel5.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_finalhall_1x1_wallpanel6 =
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_wallpanel6.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_wallpanel6.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_finalhall_1x1_wallpanel7 =
	{
		build = { "data/anims/Final_finalhall/finalhall_1x1_wallpanel7.abld" },
		anims = { "data/anims/Final_finalhall/finalhall_1x1_wallpanel7.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
		filterSymbols = {{symbol="light",filter="default"}},
	},








	finalroom_1x1_centerconsole1=
	{
		build = { "data/anims/Final_room/finalroom_1x1_centerconsole1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_room/finalroom_1x1_centerconsole1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	finalroom_1x1_farleftspine1=
	{
		build = { "data/anims/Final_room/finalroom_1x1_farleftspine1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_room/finalroom_1x1_farleftspine1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	finalroom_1x1_farrightspine1=
	{
		build = { "data/anims/Final_room/finalroom_1x1_farrightspine1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_room/finalroom_1x1_farrightspine1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	finalroom_1x1_floorpeice1=
	{
		build = { "data/anims/Final_room/finalroom_1x1_floorpeice1.abld"},
		anims = { "data/anims/Final_room/finalroom_1x1_floorpeice1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	finalroom_1x1_leftspine1=
	{
		build = { "data/anims/Final_room/finalroom_1x1_leftspine1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_room/finalroom_1x1_leftspine1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	finalroom_1x1_rightspine1=
	{
		build = { "data/anims/Final_room/finalroom_1x1_rightspine1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/Final_room/finalroom_1x1_rightspine1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	finalroom_2x1_bigspine1=
	{
		build = { "data/anims/Final_room/finalroom_2x1_bigspine1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_room/finalroom_2x1_bigspine1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},


	monsterroom_2x1_wedge1 =
	{
		build = { "data/anims/Final_monster/monsterroom_2x1_wedge1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/Final_monster/monsterroom_2x1_wedge1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	


	monsterroom_bigwallscreen1=
	{
		build = { "data/anims/Final_monster/monsterroom_bigwallscreen1.abld" },
		anims = { "data/anims/Final_monster/monsterroom_bigwallscreen1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall5,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	monsterroom_medwallscreen1=
	{
		build = { "data/anims/Final_monster/monsterroom_medwallscreen1.abld" },
		anims = { "data/anims/Final_monster/monsterroom_medwallscreen1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall3,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	monsterroom_walllight1=
	{
		build = { "data/anims/Final_monster/monsterroom_walllight1.abld" },
		anims = { "data/anims/Final_monster/monsterroom_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	monsterroom_1x1_flooring1=
	{
		build = { "data/anims/Final_monster/monsterroom_1x1_flooring1.abld"},
		anims = { "data/anims/Final_monster/monsterroom_1x1_flooring1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	monsterroom_1x1_flooring2=
	{
		build = { "data/anims/Final_monster/monsterroom_1x1_flooring2.abld"},
		anims = { "data/anims/Final_monster/monsterroom_1x1_flooring2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	monsterroom_1x1_flooring3=
	{
		build = { "data/anims/Final_monster/monsterroom_1x1_flooring3.abld"},
		anims = { "data/anims/Final_monster/monsterroom_1x1_flooring3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},







	decor_elevator_1x1_wallpiece1 =
	{
		build = { "data/anims/mainframe/elevator_wallpiece1.abld" },
		anims = { "data/anims/mainframe/elevator_wallpiece1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_elevator_1x1_wallpiece2 =
	{
		build = { "data/anims/mainframe/elevator_wallpiece2.abld" },
		anims = { "data/anims/mainframe/elevator_wallpiece2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},

	decor_elevator_floorpiece1=
	{
		build = { "data/anims/mainframe/elevator_floorpiece1.abld"},
		anims = { "data/anims/mainframe/elevator_floorpiece1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},







	prefinal_3x1_standingscreen1=
	{
		build = { "data/anims/prefinal/prefinal_3x1_standingscreen1.abld", "data/anims/general/mf_coverpieces_1x3.abld" },
		anims = { "data/anims/prefinal/prefinal_3x1_standingscreen1.adef", "data/anims/general/mf_coverpieces_1x3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_3x1_med_big, 
	},

	prefinal_2x1_gear1 =
	{
		build = { "data/anims/prefinal/prefinal_2x1_gear1.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
		anims = { "data/anims/prefinal/prefinal_2x1_gear1.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med,
	},	


	prefinal_1x1_console1=
	{
		build = { "data/anims/prefinal/prefinal_1x1_console1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/prefinal/prefinal_1x1_console1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	prefinal_1x1_pillar1=
	{
		build = { "data/anims/prefinal/prefinal_1x1_pillar1.abld", "data/anims/general/mf_coverpieces_1x1.abld" },
		anims = { "data/anims/prefinal/prefinal_1x1_pillar1.adef", "data/anims/general/mf_coverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},


	prefinal_1x1_floordecal1=
	{
		build = { "data/anims/prefinal/prefinal_1x1_floordecal1.abld"},
		anims = { "data/anims/prefinal/prefinal_1x1_floordecal1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	prefinal_1x1_floordecal2=
	{
		build = { "data/anims/prefinal/prefinal_1x1_floordecal2.abld"},
		anims = { "data/anims/prefinal/prefinal_1x1_floordecal2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	prefinal_1x1_floordecal3=
	{
		build = { "data/anims/prefinal/prefinal_1x1_floordecal3.abld"},
		anims = { "data/anims/prefinal/prefinal_1x1_floordecal3.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	prefinal_1x1_floordecal4=
	{
		build = { "data/anims/prefinal/prefinal_1x1_floordecal4.abld"},
		anims = { "data/anims/prefinal/prefinal_1x1_floordecal4.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},


	prefinal_1x1_floorpipes1=
	{
		build = { "data/anims/prefinal/prefinal_1x1_floorpipes1.abld"},
		anims = { "data/anims/prefinal/prefinal_1x1_floorpipes1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},


	prefinal_1x1_floorpipes2=
	{
		build = { "data/anims/prefinal/prefinal_1x1_floorpipes2.abld"},
		anims = { "data/anims/prefinal/prefinal_1x1_floorpipes2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},


	prefinal_1x1_floorpanel1=
	{
		build = { "data/anims/prefinal/prefinal_1x1_floorpanel1.abld"},
		anims = { "data/anims/prefinal/prefinal_1x1_floorpanel1.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	prefinal_2x1_floorpanel2=
	{
		build = { "data/anims/prefinal/prefinal_2x1_floorpanel2.abld"},
		anims = { "data/anims/prefinal/prefinal_2x1_floorpanel2.adef"},
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_1x1,
		setlayer = "floor",
	},

	prefinal_1x1_walllight1 =
	{
		build = { "data/anims/prefinal/prefinal_1x1_walllight1.abld" },
		anims = { "data/anims/prefinal/prefinal_1x1_walllight1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},


	prefinal_1x1_wallpanel1 =
	{
		build = { "data/anims/prefinal/prefinal_1x1_wallpanel1.abld" },
		anims = { "data/anims/prefinal/prefinal_1x1_wallpanel1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall2,
		filterSymbols = {{symbol="light",filter="default"}},
	},




}


return
{
	defs = animdefs,
	BoundType = BoundType
}
