local util = include( "modules/util" )

local common =
{
	female =
	{
		anims = 
		{
			"data/anims/characters/anims_female/shared_female_hits_01.adef",
		},


		grp_anims = 
		{
			anims = 
			{
				male = "data/anims/characters/anims_female/shared_female_drag_01.adef",			
				female = "data/anims/characters/anims_female/shared_female_drag_02.adef",			
			},
			anims_1h = 
			{
				male = "data/anims/characters/anims_female/shared_female_drop_a_01.adef",			
				female = "data/anims/characters/anims_female/shared_female_drop_a_02.adef",			
			},
			anims_2h =
			{
				male = "data/anims/characters/anims_female/shared_female_drop_b_01.adef",			
				female = "data/anims/characters/anims_female/shared_female_drop_b_02.adef",			
			},
			anims_unarmed = 
			{
				male = "data/anims/characters/anims_female/shared_female_drop_c_01.adef",			
				female = "data/anims/characters/anims_female/shared_female_drop_c_02.adef",			
			},
		},

		psi = 
		{
			"data/anims/characters/anims_female/psi_basic_a_01.adef",
			"data/anims/characters/anims_female/psi_basic_a_02.adef",
			"data/anims/characters/anims_female/psi_basic_a_03.adef",
			"data/anims/characters/anims_female/psi_basic_a_04.adef",
		},

		martial = 
		{
			"data/anims/characters/anims_female/martial_female_basic_b_01.adef",
			"data/anims/characters/anims_female/martial_female_basic_b_02.adef",
			"data/anims/characters/anims_female/martial_female_basic_b_03.adef",
			"data/anims/characters/anims_female/martial_female_basic_b_04.adef",
		},

		anims_1h = 
		{
			"data/anims/characters/anims_female/shared_female_basic_a_01.adef",
			"data/anims/characters/anims_female/shared_female_basic_a_02.adef",
			"data/anims/characters/anims_female/shared_female_basic_a_03.adef",
			"data/anims/characters/anims_female/shared_female_basic_a_04.adef",
			"data/anims/characters/anims_female/shared_female_basic_a_05.adef",
			"data/anims/characters/anims_female/shared_female_basic_a_07.adef",
			"data/anims/characters/anims_female/shared_female_basic_c_04.adef",
		},

		attacks_1h = 
		{
			"data/anims/characters/anims_female/shared_female_attacks_a_01.adef",
			"data/anims/characters/anims_female/shared_female_attacks_a_02.adef",
			"data/anims/characters/anims_female/shared_female_attacks_a_03.adef",
			"data/anims/characters/anims_female/shared_female_attacks_a_04.adef",
		},

		anims_2h = 
		{
			"data/anims/characters/anims_female/shared_female_basic_b_01.adef",
			"data/anims/characters/anims_female/shared_female_basic_b_02.adef",
			"data/anims/characters/anims_female/shared_female_basic_b_03.adef",
			"data/anims/characters/anims_female/shared_female_basic_b_04.adef",
			"data/anims/characters/anims_female/shared_female_basic_b_05.adef",
			"data/anims/characters/anims_female/shared_female_basic_b_07.adef",
			"data/anims/characters/anims_female/shared_female_basic_c_04.adef",					
		},

		attacks_2h = 
		{
			"data/anims/characters/anims_female/shared_female_attacks_b_01.adef",
			"data/anims/characters/anims_female/shared_female_attacks_b_02.adef",	 	
			"data/anims/characters/anims_female/shared_female_attacks_b_03.adef",	 	
			"data/anims/characters/anims_female/shared_female_attacks_b_04.adef",	 	
		},

		anims_unarmed = 
		{
			"data/anims/characters/anims_female/shared_female_basic_c_01.adef",
			"data/anims/characters/anims_female/shared_female_basic_c_02.adef",
			"data/anims/characters/anims_female/shared_female_basic_c_03.adef",						
			"data/anims/characters/anims_female/shared_female_basic_c_04.adef",
			"data/anims/characters/anims_female/shared_female_basic_c_05.adef",
			"data/anims/characters/anims_female/shared_female_basic_c_05.adef",
			"data/anims/characters/anims_female/shared_female_basic_c_07.adef",
			"data/anims/characters/anims_female/female_unarmed_basic_a_01.adef",
			"data/anims/characters/anims_female/female_unarmed_basic_a_02.adef",
			"data/anims/characters/anims_female/female_unarmed_basic_a_03.adef",						
			"data/anims/characters/anims_female/female_unarmed_basic_a_04.adef",						
		},

		attacks_unarmed = 
		{
			"data/anims/characters/anims_female/shared_female_attacks_c_01.adef",		
			"data/anims/characters/anims_female/shared_female_attacks_c_02.adef",		
		},

	},
	male =
	{
		anims = 
		{
			"data/anims/characters/anims_male/shared_hits_01.adef",			
		},

		grp_anims = 
		{
			anims = 
			{
				male = "data/anims/characters/anims_male/shared_drag_01.adef",			
				female = "data/anims/characters/anims_male/shared_drag_02.adef",			
			},
			anims_1h = 
			{
				male = "data/anims/characters/anims_male/shared_drop_a_01.adef",			
				female = "data/anims/characters/anims_male/shared_drop_a_02.adef",			
			},
			anims_2h =
			{
				male = "data/anims/characters/anims_male/shared_drop_b_01.adef",			
				female = "data/anims/characters/anims_male/shared_drop_b_02.adef",			
			},
			anims_unarmed = 
			{
				male = "data/anims/characters/anims_male/shared_drop_c_01.adef",			
				female = "data/anims/characters/anims_male/shared_drop_c_02.adef",			
			},
		},

		stealth = 
		{
			"data/anims/characters/anims_male/stealth_basic_a_01.adef",
			"data/anims/characters/anims_male/stealth_basic_a_02.adef",
			"data/anims/characters/anims_male/stealth_basic_a_03.adef",	
			"data/anims/characters/anims_male/stealth_basic_a_04.adef",	
		},

		martial = 
		{
			"data/anims/characters/anims_male/martial_basic_b_01.adef",
			"data/anims/characters/anims_male/martial_basic_b_02.adef",
			"data/anims/characters/anims_male/martial_basic_b_03.adef",
			"data/anims/characters/anims_male/martial_basic_b_04.adef",
		},

		tech = 
		{
			"data/anims/characters/anims_male/tech_basic_a_01.adef",
			"data/anims/characters/anims_male/tech_basic_a_02.adef",
			"data/anims/characters/anims_male/tech_basic_a_03.adef",			
			"data/anims/characters/anims_male/tech_basic_a_04.adef",			
		},

		anims_1h = 
		{
			"data/anims/characters/anims_male/shared_basic_a_01.adef",
			"data/anims/characters/anims_male/shared_basic_a_02.adef",
			"data/anims/characters/anims_male/shared_basic_a_03.adef",						
			"data/anims/characters/anims_male/shared_basic_a_04.adef",						
			"data/anims/characters/anims_male/shared_basic_a_05.adef",						
			"data/anims/characters/anims_male/shared_basic_a_06.adef",						
			"data/anims/characters/anims_male/shared_basic_a_07.adef",						
			"data/anims/characters/anims_male/shared_basic_c_04.adef",		
		},

		attacks_1h = 
		{
			"data/anims/characters/anims_male/shared_attacks_a_01.adef",
			"data/anims/characters/anims_male/shared_attacks_a_02.adef",	 
			"data/anims/characters/anims_male/shared_attacks_a_03.adef",	
			"data/anims/characters/anims_male/shared_attacks_a_04.adef",	
		},

		anims_2h = 
		{
			"data/anims/characters/anims_male/shared_basic_b_01.adef",
			"data/anims/characters/anims_male/shared_basic_b_02.adef",
			"data/anims/characters/anims_male/shared_basic_b_03.adef",						
			"data/anims/characters/anims_male/shared_basic_b_04.adef",						
			"data/anims/characters/anims_male/shared_basic_b_05.adef",						
			"data/anims/characters/anims_male/shared_basic_b_06.adef",						
			"data/anims/characters/anims_male/shared_basic_b_07.adef",						
			"data/anims/characters/anims_male/shared_basic_c_04.adef",				
		},

		attacks_2h = 
		{
			"data/anims/characters/anims_male/shared_attacks_b_01.adef",		
			"data/anims/characters/anims_male/shared_attacks_b_02.adef",	
			"data/anims/characters/anims_male/shared_attacks_b_03.adef",	
			"data/anims/characters/anims_male/shared_attacks_b_04.adef",	
		},


		anims_unarmed = 
		{
			"data/anims/characters/anims_male/shared_basic_c_01.adef",
			"data/anims/characters/anims_male/shared_basic_c_02.adef",
			"data/anims/characters/anims_male/shared_basic_c_03.adef",						
			"data/anims/characters/anims_male/shared_basic_c_04.adef",						
			"data/anims/characters/anims_male/shared_basic_c_05.adef",						
			"data/anims/characters/anims_male/shared_basic_c_06.adef",						
			"data/anims/characters/anims_male/shared_basic_c_07.adef",						
			"data/anims/characters/anims_male/unarmed_basic_a_01.adef",
			"data/anims/characters/anims_male/unarmed_basic_a_02.adef",
			"data/anims/characters/anims_male/unarmed_basic_a_03.adef",						
			"data/anims/characters/anims_male/unarmed_basic_a_04.adef",						
		},

		attacks_unarmed =
		{
			"data/anims/characters/anims_male/shared_attacks_c_01.adef",					
			"data/anims/characters/anims_male/shared_attacks_c_02.adef",					
		},

		anims_panic = 
		{
			"data/anims/characters/anims_male/panic_basic_c_01.adef",
			"data/anims/characters/anims_male/panic_basic_c_02.adef",
			"data/anims/characters/anims_male/panic_basic_c_03.adef",						
			"data/anims/characters/anims_male/shared_basic_c_06.adef",						
		},
	},
	-------------------------------------------------------------------------------------------
}

common.female.default_anims_1h = util.tconcat(
	common.female.anims_1h,
	common.female.psi,
	common.female.attacks_1h,
	common.female.anims)

common.female.default_anims_2h = util.tconcat(
	common.female.anims_2h,
	common.female.anims,
	common.female.attacks_2h,
	common.female.martial)

common.female.default_anims_unarmed = util.tconcat(
	common.female.anims_unarmed,
	common.female.anims,
	common.female.attacks_unarmed)
-------------------
common.male.default_anims_1h = util.tconcat(
	common.male.anims_1h,
	common.male.anims,
	common.male.attacks_1h,
	common.male.stealth)

common.male.default_anims_2h = util.tconcat(
	common.male.anims_2h,
	common.male.anims,
	common.male.attacks_2h,
	common.male.martial)

common.male.default_anims_unarmed = util.tconcat(
	common.male.anims_unarmed,
	common.male.anims,
	common.male.attacks_unarmed)

common.male.default_anims_panic = util.tconcat(
	common.male.anims_unarmed,
	common.male.anims,
	common.male.anims_panic)


return common
