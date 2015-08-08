local util = include( "modules/util" )
local commondefs = include( "sim/unitdefs/commondefs" )
local simdefs = include( "sim/simdefs" )

local NEVER_SOLD = 10000

local function onHolocircuitTooltip( tooltip, unit, userUnit )
    local cdefs = include( "client_defs" )
    local simquery = include( "sim/simquery" )
    commondefs.item_template.onTooltip( tooltip, unit, userUnit )
    if unit:getTraits().installed and userUnit and unit:getSim() then
        local x0, y0 = userUnit:getLocation()
        tooltip:addRange( simdefs.HOLOCIRCUIT_RANGE, x0, y0, cdefs.HILITE_TARGET_COLOR )

        local hiliteUnits = {}
		local cells = simquery.fillCircle( unit:getSim(), x0, y0, simdefs.HOLOCIRCUIT_RANGE, 0)
		for i, cell in ipairs(cells) do
			for i, cellUnit in ipairs( cell.units ) do
				if simquery.isEnemyAgent( userUnit:getPlayerOwner(), cellUnit) and not cellUnit:isKO() then
                    table.insert( hiliteUnits, cellUnit:getID() )
				end
			end
		end
        tooltip:addUnitHilites( hiliteUnits )
    end
end


local tool_templates =
{
	-----------------------------------------------------
	-- Augment item templates

	


	augment_skeletal_suspension = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.SKELETAL_SUSPENSION,
		desc = STRINGS.ITEMS.AUGMENTS.SKELETAL_SUSPENSION_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.SKELETAL_SUSPENSION_FLAVOR, 		
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			modTrait = {{"dragCostMod", 0.5}},	
		},				
		value = 300, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_arm_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_arm.png",			
	},

	augment_sadochistic_pumps = util.extend( commondefs.augment_template )
	{ 
		name = STRINGS.ITEMS.AUGMENTS.SADOCHISTIC_PUMPS, 
		desc = STRINGS.ITEMS.AUGMENTS.SADOCHISTIC_PUMPS_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.SADOCHISTIC_PUMPS_FLAVOR, 
		value = 300, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_leg_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_leg.png",			
	},

	augment_net_downlink = util.extend( commondefs.augment_template )
	{
		name =STRINGS.ITEMS.AUGMENTS.NET_DOWNLINK,
		desc = STRINGS.ITEMS.AUGMENTS.NET_DOWNLINK_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.NET_DOWNLINK_FLAVOR, 
		keyword = "NETWORK", 
		value = 650, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",			
	},	

	augment_anatomy_analysis = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.ANATOMY_ANALYSIS,
		desc = STRINGS.ITEMS.AUGMENTS.ANATOMY_ANALYSIS_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.ANATOMY_ANALYSIS_FLAVOR,  
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_torso_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_torso.png",			
	},	

	augment_distributed_processing = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.DISTRIBUTED_PROCESSING,
		desc = STRINGS.ITEMS.AUGMENTS.DISTRIBUTED_PROCESSING_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.DISTRIBUTED_PROCESSING_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			stackable = true,
		},			
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",			
	},	

	augment_torque_injectors = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.TORQUE_INJECTORS,
		desc = STRINGS.ITEMS.AUGMENTS.TORQUE_INJECTORS_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.TORQUE_INJECTORS_FLAVOR, 
		keyword = "ITEM", 
		value = 300, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_torso_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_torso.png",			
	},	

	augment_titanium_rods = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.TITANIUM_RODS,
		desc = STRINGS.ITEMS.AUGMENTS.TITANIUM_RODS_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.TITANIUM_RODS_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			modTrait = {{"meleeDamage",1}},	
			stackable = true,
		},			
		value = 400, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_arm_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_arm.png",	
	},	

	augment_subdermal_cloak = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.SUBDERMAL_CLOAK,
		desc = STRINGS.ITEMS.AUGMENTS.SUBDERMAL_CLOAK_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.SUBDERMAL_CLOAK_FLAVOR,
		keyword = "STIM", 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			pwrCost = 5,
		},			
		value = 400,
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_torso_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_torso.png",			
	},	

	augment_holocircuit_overloaders = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.HOLOCIRCUIT,
		desc = STRINGS.ITEMS.AUGMENTS.HOLOCIRCUIT_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.HOLOCIRCUIT_FLAVOR,
        onTooltip = onHolocircuitTooltip,
		keyword = "CLOAK", 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_torso_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_torso.png",			
	},	

	augment_predictive_brawling = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.PREDICTIVE_BRAWLING,
		desc = STRINGS.ITEMS.AUGMENTS.PREDICTIVE_BRAWLING_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.PREDICTIVE_BRAWLING_FLAVOR,
		keyword = "MELEE", 
		value = 300, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_leg_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_leg.png",			
	},	

	augment_chameleon_movement = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.CHAMELEON_MOVEMENT,
		desc = STRINGS.ITEMS.AUGMENTS.CHAMELEON_MOVEMENT_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.CHAMELEON_MOVEMENT_FLAVOR, 
		keyword = "CLOAK", 
		value = 300, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_leg_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_leg.png",			
	},	

	augment_piercing_scanner = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.PIERCING_SCANNER,
		desc = STRINGS.ITEMS.AUGMENTS.PIERCING_SCANNER_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.PIERCING_SCANNER_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addArmorPiercingRanged = 1,
			stackable = true,
		},
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",			
	},

	augment_penetration_scanner = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.PENETRATION_SCANNER,
		desc = STRINGS.ITEMS.AUGMENTS.PENETRATION_SCANNER_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.PENETRATION_SCANNER_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addArmorPiercingMelee = 1,
			stackable = true,
		},	
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_arm_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_arm.png",	
	},

	augment_microslam_apparatus = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.MICROSLAM_APPARATUS,
		desc = STRINGS.ITEMS.AUGMENTS.MICROSLAM_APPARATUS_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.MICROSLAM_APPARATUS_FLAVOR,
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",			
	},
    
	augment_carbon_myomer = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.CARBON_MYOMER,
		desc = STRINGS.ITEMS.AUGMENTS.CARBON_MYOMER_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.CARBON_MYOMER_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addInventory = 1,
		},
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_torso_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_torso.png",	
    	value = 200, 
	},	



-- agent unique augments
	augment_central = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.CENTRALS,
		desc = STRINGS.ITEMS.AUGMENTS.CENTRALS_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.CENTRALS_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addAbilities = "centralaugment",
			installed = true,
			finalStartItem = true,
		},		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",	
	},
	augment_monst3r = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.MONSTERS,
		desc = STRINGS.ITEMS.AUGMENTS.MONSTERS_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.MONSTERS_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			installed = true,
			shopDiscount = 0.15, 
		},		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",	
	},
	augment_deckard = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.DECKARDS,
		desc = STRINGS.ITEMS.AUGMENTS.DECKARDS_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.DECKARDS_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addAbilities = "scandevice",
			installed = true,
		},		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",	
	},
	augment_decker_2 = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.DECKER_2,
		desc = STRINGS.ITEMS.AUGMENTS.DECKER_2_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.DECKER_2_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addAbilities = "decker_2_augment",
			installed = true,
		},		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",	
	},
	augment_international_v1 = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.INTERNATIONALS,
		desc = STRINGS.ITEMS.AUGMENTS.INTERNATIONALS_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.INTERNATIONALS_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addTrait = {{"wireless_range",6}},			
			installed = true,
			wireless_range = 6,
		},
        abilities = util.tconcat( commondefs.augment_template.abilities, { "wireless_scan" }),
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_internationale_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_internationale.png",			
	},
	augment_international_2 = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.INTERNATIONALS_2,
		desc = STRINGS.ITEMS.AUGMENTS.INTERNATIONALS_2_TIP,
		flavor = STRINGS.ITEMS.AUGMENTS.INTERNATIONALS_2_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			cpus = 1, 
			maxcpus = 1, 
			cpuTurn = 1, 
			cpuTurnMax = 2, 
			installed = true,
            addAbilities = "alarmCPU",
		},		
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_internationale_small_alt.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_internationale_alt.png",			
	},
	augment_shalem = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.SHALEMS,
		desc = STRINGS.ITEMS.AUGMENTS.SHALEMS_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.SHALEMS_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addArmorPiercingRanged = 1,
			installed = true,
		},
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_shalem_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_shalem.png",					
	},
   	augment_banks = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.BANKS,
		desc = STRINGS.ITEMS.AUGMENTS.BANKS_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.BANKS_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addTrait = {{"passiveKey",simdefs.DOOR_KEYS.SECURITY}},
			installed = true,
		},
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_banks_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_banks.png",							
	},
   	augment_tony = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.TONYS,
		desc = STRINGS.ITEMS.AUGMENTS.TONYS_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.TONYS_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addAbilities = "manualHack",
			modTrait = {{"mpMax",-1}},			
			installed = true,
		},	
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_tony_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_tony.png",		
	},
   	augment_nika = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.NIKAS,
		desc = STRINGS.ITEMS.AUGMENTS.NIKAS_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.NIKAS_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			extraAP = 1,	
			extraAPMax = 1,
			installed = true,
			addTrait = {{"actionAP",true}},			
		},		
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_nika_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_nika.png",		
	},	
	augment_nika_2 = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.NIKAS_2,
		desc = STRINGS.ITEMS.AUGMENTS.NIKAS_2_TIP, 
		flavor = STRINGS.ITEMS.AUGMENTS.NIKAS_2_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			installed = true,
		},		
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_nika_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_nika.png",		
	},	    

   	augment_tony_2 = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.TONYS_2,
		desc = STRINGS.ITEMS.AUGMENTS.TONYS_TIP_2, 
		flavor = STRINGS.ITEMS.AUGMENTS.TONYS_FLAVOR_2,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			installed = true,
		},
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_banks_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_banks.png",		
	},


	augment_prism_2 = util.extend(commondefs.augment_template)
	{
		name = STRINGS.ITEMS.AUGMENTS.PRISM_2,
		desc = STRINGS.ITEMS.AUGMENTS.PRISM_2_TOOLTIP,
		flavor = STRINGS.ITEMS.AUGMENTS.PRISM_2_FLAVOR,
		traits = { 
			installed = true,
		},
		keyword = "NETWORK", 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_torso_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_torso.png",		
	},


	augment_sharp_1 = util.extend(commondefs.augment_template)
	{
		name = STRINGS.ITEMS.AUGMENTS.SHARP_1,
		desc = STRINGS.ITEMS.AUGMENTS.SHARP_1_TOOLTIP,
		flavor = STRINGS.ITEMS.AUGMENTS.SHARP_1_FLAVOR,
		traits = { 
			installed = true,
		}, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_torso_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_torso.png",		
	},	

	augment_sharp_2 = util.extend(commondefs.augment_template)
	{
		name = STRINGS.ITEMS.AUGMENTS.SHARP_2,
		desc = STRINGS.ITEMS.AUGMENTS.SHARP_2_TOOLTIP,
		flavor = STRINGS.ITEMS.AUGMENTS.SHARP_2_FLAVOR,
		traits = { 
			installed = true,
			modTrait = {{"mpMax",-1}},	
		}, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_augment_sharp_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_augment_sharp.png",		
	},		

	augment_final_level = util.extend(commondefs.augment_template)
	{
		name = STRINGS.ITEMS.AUGMENTS.FINAL_LEVEL,
		desc = STRINGS.ITEMS.AUGMENTS.FINAL_LEVEL_TOOLTIP,
		flavor = STRINGS.ITEMS.AUGMENTS.FINAL_LEVEL_FLAVOR,
		traits = { 
			installed = true,
			finalAugmentKey = true,
			keybits = simdefs.DOOR_KEYS.FINAL_LEVEL 
		}, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_torso_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_torso.png",		
	},	
    -----------------------------------------------------
	-- Quest item templates

	quest_material = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.QUEST_MATERIAL,
		desc = STRINGS.ITEMS.QUEST_MATERIAL_TIP,
		flavor = STRINGS.ITEMS.QUEST_MATERIAL_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/items/item_quest.png",
		traits = {  },
		abilities = { "carryable" },	
		value = 400,	
	},

	-----------------------------------------------------
	-- Ammo templates 

	item_clip = util.extend(commondefs.item_template)
	{
		name =  STRINGS.ITEMS.CLIP,
		desc = STRINGS.ITEMS.CLIP_TIP,
		flavor = STRINGS.ITEMS.CLIP_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/item_ammo.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_magazine_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_magazine.png",	
												
		traits = { ammo_clip = 1, disposable = true },
		abilities = { "carryable" },
		value = 400,
	},

	-----------------------------------------------------
	-- Weapon templates		
	-- accuracy is the amount of INaccuracy a weapon has. 
	-- aim is the amount that INaccuracy is reduced by	

	-- DART GUNS
	
	item_dartgun = util.extend( commondefs.weapon_reloadable_template )
	{
		name = STRINGS.ITEMS.DART_GUN1_NAME,
		desc = STRINGS.ITEMS.DART_GUN1_TOOLTIP,
		flavor = STRINGS.ITEMS.DART_GUN1_FLAVOR,
		icon = "itemrigs/FloorProp_Precision_Pistol.png",	
		--profile_icon = "gui/items/icon-item_gun_pistol.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_dart_small.png",			
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_dart.png",	
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 2, canSleep = true, ammo = 2, maxAmmo = 2, },
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_dart", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_dartgun_wood"},
		weapon_anim = "kanim_precise_revolver",
		agent_anim = "anims_1h",		
		value = 450,
	},

	item_dartgun_dam = util.extend( commondefs.weapon_reloadable_template )
	{
		name =  STRINGS.ITEMS.DART_GUN_DAM,
		desc =  STRINGS.ITEMS.DART_GUN_DAM_TOOLTIP,
		flavor =  STRINGS.ITEMS.DART_GUN_DAM_FLAVOR,
		icon = "itemrigs/FloorProp_Precision_Rifle.png",	
		--profile_icon = "gui/items/icon-item_gun_pistol.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_rifle_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_rifle.png",	
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 3, canSleep = true, ammo = 2, maxAmmo = 2, armorPiercing = 1,  },
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_dart", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_dartgun_wood"},
		weapon_anim = "kanim_precise_rifle",
		agent_anim = "anims_2h",
		value = 950,
	},

	item_dartgun_ammo = util.extend( commondefs.weapon_reloadable_template )
	{
		name =  STRINGS.ITEMS.DART_GUN_AMMO,
		desc =  STRINGS.ITEMS.DART_GUN_AMMO_TOOLTIP,
		flavor = STRINGS.ITEMS.DART_GUN_AMMO_FLAVOR,
		icon = "itemrigs/FloorProp_Precision_Pistol.png",	
		--profile_icon = "gui/items/icon-item_gun_pistol.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_dart_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_dart.png",				
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 2, canSleep = true, ammo = 3, maxAmmo = 3, },
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_dart", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_dartgun_wood"},
		weapon_anim = "kanim_precise_revolver",
		agent_anim = "anims_1h",
		value = 900,
	},

	-- PISTOLS 

	item_light_pistol = util.extend( commondefs.weapon_reloadable_template )
	{
		name = STRINGS.ITEMS.PISTOL,
		desc = STRINGS.ITEMS.PISTOL_TOOLTIP,
		flavor = STRINGS.ITEMS.PISTOL_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_pistol_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_pistol.png",	
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 1, ammo = 1, maxAmmo = 1,},
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun_silenced", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_handgun_wood"},
		weapon_anim = "kanim_light_revolver",
		agent_anim = "anims_1h",
		value = 300,
	},

	item_light_pistol_dam = util.extend( commondefs.weapon_reloadable_template )
	{
		name = STRINGS.ITEMS.PISTOL_DAM,
		desc = STRINGS.ITEMS.PISTOL_DAM_TOOLTIP,
		flavor = STRINGS.ITEMS.PISTOL_DAM_FLAVOR,
		icon = "itemrigs/FloorProp_Rifle.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_rifle_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_rifle.png",			
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 1, ammo = 1, maxAmmo = 1, armorPiercing = 1, },
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun_silenced", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_handgun_wood"},
		weapon_anim = "kanim_light_rifle",
		agent_anim = "anims_2h",
		value = 700,
	},

	item_revolver_deckard = util.extend( commondefs.weapon_reloadable_template )
	{
		name = STRINGS.ITEMS.REVOLVER_DECKARD,
		desc = STRINGS.ITEMS.REVOLVER_DECKARD_TOOLTIP,
		flavor = STRINGS.ITEMS.REVOLVER_DECKARD_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_revolver_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_revolver.png",			
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 1, ammo = 6, maxAmmo = 6, noReload = true },
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun_silenced", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_light_revolver",
		agent_anim = "anims_1h",
		value = 0,
	},

	item_light_pistol_ammo = util.extend( commondefs.weapon_reloadable_template )
	{
		name = STRINGS.ITEMS.PISTOL_AMMO,
		desc = STRINGS.ITEMS.PISTOL_AMMO_TOOLTIP,
		flavor = STRINGS.ITEMS.PISTOL_AMMO_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_pistol_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_pistol.png",			
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 1, ammo = 3, maxAmmo = 3 },
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun_silenced", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_handgun_wood"},
		weapon_anim = "kanim_light_revolver",
		agent_anim = "anims_1h",
		value = 900,
	},

	item_light_pistol_KO = util.extend( commondefs.weapon_reloadable_template )
	{
		name = STRINGS.ITEMS.PISTOL_KO,
		desc = STRINGS.ITEMS.PISTOL_KO_TOOLTIP,
		flavor = STRINGS.ITEMS.PISTOL_KO_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_pistol_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_pistol.png",			
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 1, ammo = 2, maxAmmo = 2 },
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun_silenced", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_handgun_wood"},
		weapon_anim = "kanim_light_revolver",
		agent_anim = "anims_1h",
		value = 600,
	},

	--RIFLES 

	item_light_rifle_shalem = util.extend( commondefs.weapon_reloadable_template )
	{
		name = STRINGS.ITEMS.RIFLE_SHALEM,
		desc = STRINGS.ITEMS.RIFLE_SHALEM_TOOLTIP,
		flavor = STRINGS.ITEMS.RIFLE_SHALEM_FLAVOR, 
		icon = "itemrigs/FloorProp_Rifle.png",		
		--profile_icon = "gui/items/item_rifle_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_rifle_small.png",			
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_rifle.png",			
		equipped_icon = "gui/items/equipped_rifle.png",
		traits = { weaponType="rifle", baseDamage = 1, ammo = 2, maxAmmo = 2, armorPiercing = 1,},
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_rifle_silenced", reload="SpySociety/Weapons/Precise/reload_rifle", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_rifle_wood"},
		weapon_anim = "kanim_light_rifle",
		agent_anim = "anims_2h",
		value =600,
		soldAfter = NEVER_SOLD,
	},


	--Epic Weapons

	item_xray_rifle = util.extend( commondefs.weapon_reloadable_template )
	{
		name = STRINGS.ITEMS.RIFLE_XRAY,
		desc = STRINGS.ITEMS.RIFLE_XRAY_TOOLTIP,
		flavor = STRINGS.ITEMS.RIFLE_XRAY_FLAVOR,
		icon = "itemrigs/FloorProp_Rifle.png",		
		--profile_icon = "gui/items/item_rifle_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_rifle_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_rifle.png",			
		equipped_icon = "gui/items/equipped_rifle.png",
		traits = { weaponType="rifle", baseDamage = 1, ammo = 2, maxAmmo = 2, armorPiercing = 1, xray = true },
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_rifle_silenced", reload="SpySociety/Weapons/Precise/reload_rifle", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_rifle_wood"},
		weapon_anim = "kanim_light_rifle",
		agent_anim = "anims_2h",
		value = 1800,
		soldAfter = 24, 
	},

	item_bio_dartgun = util.extend( commondefs.weapon_template )
	{
		name = STRINGS.ITEMS.DART_GUN_BIO,
		desc = STRINGS.ITEMS.DART_GUN_BIO_TOOLTIP,
		flavor = STRINGS.ITEMS.DART_GUN_BIO_FLAVOR,
		icon = "itemrigs/FloorProp_Precision_Pistol.png",	
		--profile_icon = "gui/items/icon-item_gun_pistol.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_dart_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_dart.png",				
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 2, armorPiercing = 2, cooldown = 0, cooldownMax = 7, canSleep = true },
        abilities = util.tmerge( { "recharge" }, commondefs.weapon_template.abilities ),
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_dart", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_precise_revolver",
		agent_anim = "anims_1h",
		value = 1200,
		soldAfter = 24, 
		floorWeight = 3,
	},

	item_energy_pistol = util.extend( commondefs.weapon_template )
	{
		name = STRINGS.ITEMS.PISTOL_ENERGY,
		desc = STRINGS.ITEMS.PISTOL_ENERGY_TOOLTIP,
		flavor = STRINGS.ITEMS.PISTOL_ENERGY_FLAVOR,
		icon = "itemrigs/FloorProp_Precision_SMG.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_SMG_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_smg.png",			
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 1, pwrCost = 4, energyWeapon = "idle", armorPiercing = 2, shots=3, nopwr_guards = {}},
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun_silenced", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_precise_smg",
		agent_anim = "anims_2h",
		value = 1250,
		soldAfter = 24,
		floorWeight = 3,
	},

	item_npc_smg = util.extend( commondefs.npc_weapon_template )
	{
		name = STRINGS.ITEMS.SMG,
		desc = STRINGS.ITEMS.SMG_TOOLTIP,
		flavor = STRINGS.ITEMS.SMG_FLAVOR,
		icon = "itemrigs/FloorProp_SMG.png",		
		--profile_icon = "gui/items/item_smg-56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_SMG_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_SMG.png",	
		equipped_icon = "gui/items/equipped_smg.png",
		traits = { weaponType="smg", baseDamage = 4, shots = 7, armorPiercing = 1 },
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_smg", reload="SpySociety/Weapons/LowBore/reload_smg", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_SMG_wood"},
		weapon_anim = "kanim_light_smg",
		agent_anim = "anims_2h",
	},

	item_npc_smg_hvy = util.extend( commondefs.npc_weapon_template )
	{
		name = STRINGS.ITEMS.SMG,
		desc = STRINGS.ITEMS.SMG_TOOLTIP,
		flavor = STRINGS.ITEMS.SMG_FLAVOR,
		icon = "itemrigs/FloorProp_SMG.png",		
		--profile_icon = "gui/items/item_smg-56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_SMG_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_SMG.png",	
		equipped_icon = "gui/items/equipped_smg.png",
		traits = { weaponType="smg", baseDamage = 4, shots = 7, armorPiercing = 2},
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_smg", reload="SpySociety/Weapons/LowBore/reload_smg", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_SMG_wood"},
		weapon_anim = "kanim_light_smg",
		agent_anim = "anims_2h",
	},

	item_npc_smg_omni = util.extend( commondefs.npc_weapon_template )
	{
		name = STRINGS.ITEMS.SMG,
		desc = STRINGS.ITEMS.SMG_TOOLTIP,
		flavor = STRINGS.ITEMS.SMG_FLAVOR,
		icon = "itemrigs/FloorProp_SMG.png",		
		--profile_icon = "gui/items/item_smg-56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_SMG_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_SMG.png",	
		equipped_icon = "gui/items/equipped_smg.png",
		traits = { weaponType="smg", baseDamage = 4, shots = 7, armorPiercing = 2},
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_smg", reload="SpySociety/Weapons/LowBore/reload_smg", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_SMG_wood"},
		weapon_anim = "kanim_precise_smg",
		agent_anim = "anims_2h",
	},

	item_npc_smg_drone= util.extend( commondefs.npc_weapon_template )
	{
		name = STRINGS.ITEMS.SMG,
		desc = STRINGS.ITEMS.SMG_TOOLTIP,
		flavor = STRINGS.ITEMS.SMG_FLAVOR,
		icon = "itemrigs/FloorProp_SMG.png",		
		--profile_icon = "gui/items/item_smg-56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_SMG_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_SMG.png",	
		equipped_icon = "gui/items/equipped_smg.png",
		traits = { weaponType="smg", baseDamage = 4,  armorPiercing = 2},
		sounds = { reload="SpySociety/Weapons/LowBore/reload_smg", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_light_smg",
		agent_anim = "anims_2h",
	},

	item_npc_pistol = util.extend( commondefs.npc_weapon_template )
	{
		name = STRINGS.ITEMS.PISTOL,
		desc = STRINGS.ITEMS.PISTOL_TOOLTIP,
		flavor = STRINGS.ITEMS.PISTOL_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_pistol_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_pistol.png",	
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 1 },
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_handgun_wood"},
		weapon_anim = "kanim_light_revolver",
		agent_anim = "anims_1h",
	},

	item_drone_turret = util.extend( commondefs.npc_weapon_template )
	{
		name = STRINGS.ITEMS.DRONE_TURRET,
		desc = STRINGS.ITEMS.DRONE_TURRET_TOOLTIP,
		flavor = STRINGS.ITEMS.DRONE_TURRET_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_pistol_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_pistol.png",	
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 1, ammo = 2, maxAmmo = 2 },
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_light_revolver",
		agent_anim = "anims_1h",
	},

	item_npc_pistol2 = util.extend( commondefs.npc_weapon_template )
	{
		name = STRINGS.ITEMS.PISTOL,
		desc = STRINGS.ITEMS.PISTOL_TOOLTIP,
		flavor = STRINGS.ITEMS.PISTOL_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_pistol_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_pistol.png",			
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 2 },
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_handgun_wood"},
		weapon_anim = "kanim_light_revolver",
		agent_anim = "anims_1h",
	},


	item_npc_rifle = util.extend( commondefs.npc_weapon_template )
	{
		name = STRINGS.ITEMS.RIFLE_SNIPER,
		desc = STRINGS.ITEMS.RIFLE_SNIPER_TOOLTIP, 
		flavor = STRINGS.ITEMS.RIFLE_SNIPER_FLAVOR,
		icon = "itemrigs/FloorProp_Rifle.png",		
		--profile_icon = "gui/items/item_rifle_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_rifle_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_rifle.png",			
		equipped_icon = "gui/items/equipped_rifle.png",
		traits = { weaponType="rifle", baseDamage = 1 },
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_rifle", reload="SpySociety/Weapons/Precise/reload_rifle", use="SpySociety/Actions/item_pickup",shell="SpySociety/Weapons/Shells/shell_rifle_wood"},
		weapon_anim = "kanim_precise_rifle",
		agent_anim = "anims_2h",
		value =1000,
	},

	item_turretgun = util.extend( commondefs.npc_weapon_template )
	{
		type = "simunit",
		name = STRINGS.ITEMS.TURRET,
		desc = STRINGS.ITEMS.TURRET_TOOLTIP,
		flavor = STRINGS.ITEMS.TURRET_FLAVOR,
		icon = "itemrigs/revolver.png",
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="smg", baseDamage = 2, ammo = 2, maxAmmo = 2, shots=3 , cantdrop = true, armorPiercing = 2},
		abilities = {},
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_turret", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_revolver",
		agent_anim = "anims_1h",
	},

	item_tag_pistol = util.extend( commondefs.weapon_template )
	{
		name =  STRINGS.ITEMS.TAGGER_GUN,
		desc =  STRINGS.ITEMS.TAGGER_GUN_TIP,
		flavor = STRINGS.ITEMS.TAGGER_GUN_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",	
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_microchip_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_microchip.png",				
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 0, pwrCost= 1, canTag= true, noTargetAlert=true, ignoreArmor=true, nopwr_guards = {} },
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_dart", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_precise_revolver",
		agent_anim = "anims_1h",
		value = 300,
	},	

	-----------------------------------------------------
	-- Grenade templates
	item_flashgrenade = util.extend( commondefs.grenade_template)
	{
        type = "stun_grenade",
		name = STRINGS.ITEMS.GRENADE_FLASH,
		desc = STRINGS.ITEMS.GRENADE_FLASH_TOOLTIP,
		flavor = STRINGS.ITEMS.GRENADE_FLASH_FLAVOR,
		--icon = "itemrigs/FloorProp_Bandages.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_flash_grenade_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_flash_grenade.png",		
		kanim = "kanim_flashgrenade",		
		sounds = {explode="SpySociety/Grenades/flashbang_explo", bounce="SpySociety/Grenades/bounce"},
		traits = { baseDamage = 2, canSleep = true, range=3, explodes = 0 },
		value = 600,
		floorWeight = 2,
		locator=true,
	},

	item_stickycam = util.extend( commondefs.grenade_template )
	{
		name = STRINGS.ITEMS.GRENADE_CAMERA,
		desc = STRINGS.ITEMS.GRENADE_CAMERA_TOOLTIP,
		flavor = STRINGS.ITEMS.GRENADE_CAMERA_FLAVOR,
		--icon = "itemrigs/FloorProp_Bandages.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_Sticky_Cam_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_Sticky_Cam.png",
		kanim = "kanim_stickycam",		
		sounds = {activate="SpySociety/Grenades/stickycam_deploy", bounce="SpySociety/Grenades/bounce"},
		traits = { cooldown = 0, cooldownMax = 1, camera=true, LOSarc = math.pi * 2, disposable= false },
		value = 300,
		floorWeight = 2, 
		locator=true,
	},

	item_hologrenade = util.extend( commondefs.grenade_template )
	{
		name = STRINGS.ITEMS.GRENADE_HOLO,
		desc = STRINGS.ITEMS.GRENADE_HOLO_TOOLTIP,
		flavor = STRINGS.ITEMS.GRENADE_HOLO_FLAVOR,
		--icon = "itemrigs/FloorProp_Bandages.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_holo_grenade_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_holo_grenade.png",	
		kanim = "kanim_hologrenade",
		sounds = {activate="SpySociety/Actions/holocover_activate", deactivate="SpySociety/Actions/holocover_deactivate", activeSpot="SpySociety/Actions/holocover_run_LP", bounce="SpySociety/Grenades/bounce"},
		traits = { cooldown = 0, cooldownMax = 1, cover=true, holoProjector=true, disposable = false},	
		abilities = { "recharge","carryable", "throw" },
		value = 600,
		floorWeight = 2, 		
		locator=true,
	},
    
	item_smokegrenade = util.extend( commondefs.grenade_template )
	{
        type = "smoke_grenade",
		name = STRINGS.ITEMS.GRENADE_SMOKE,
		desc = STRINGS.ITEMS.GRENADE_SMOKE_TOOLTIP,
		flavor = STRINGS.ITEMS.GRENADE_SMOKE_FLAVOR,
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_smoke_grenade_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_smoke_grenade.png",	
		kanim = "kanim_stickycam",		
		sounds = {explode="SpySociety/Grenades/smokegrenade_explo", bounce="SpySociety/Grenades/bounce_smokegrenade"},
		traits = { on_spawn = "smoke_cloud" , range=3, noghost = true, explodes = 0 },
		value = 300,
		floorWeight = 2, 
		locator=true,
	},


	item_npc_flashgrenade = util.extend( commondefs.npc_grenade_template )
	{
        type = "stun_grenade",
		name = STRINGS.ITEMS.GRENADE_FLASH,
		desc = STRINGS.ITEMS.GRENADE_FLASH_TOOLTIP,
		--icon = "itemrigs/FloorProp_Bandages.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_flash_grenade_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_flash_grenade.png",		
		kanim = "kanim_flashgrenade",		
		sounds = {explode="SpySociety/Grenades/flashbang_explo", bounce="SpySociety/Grenades/bounce"},
		traits = { baseDamage = 2, canSleep = true, explodes = 1, range=3, throwUnit="item_npc_flashgrenade", keepPathing=false },
		value = 600,
		floorWeight = 2, 
	},

	item_npc_scangrenade = util.extend( commondefs.npc_grenade_template )
	{
        type = "scan_grenade",
		name = STRINGS.ITEMS.GRENADE_SCAN,
		desc = STRINGS.ITEMS.GRENADE_SCAN_TOOLTIP,
		--icon = "itemrigs/FloorProp_Bandages.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_scanner_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_scanner.png",		
		kanim = "kanim_scangrenade",		
		sounds = {activate = "SpySociety/Grenades/stickycam_deploy", explode="SpySociety/Actions/Engineer/wireless_emitter", bounce="SpySociety/Grenades/bounce" },
		traits = { range=5, aimRange = 3, scan=true, explodes = 0, throwUnit="item_npc_scangrenade", keepPathing=false },
		value = 600,
		floorWeight = 2, 
	},


	-----------------------------------------------------
	-- Equipment templates


--- INJECTIONS
	item_adrenaline = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.MED_GEL,
		desc = STRINGS.ITEMS.MED_GEL_TOOLTIP,
		flavor = STRINGS.ITEMS.MED_GEL_FLAVOR,
		icon = "itemrigs/FloorProp_Bandages.png",
		--profile_icon = "gui/items/icon-adrenalin.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_medigel_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_med_gel.png",	
		traits = { disposable = true },
		abilities = { "carryable","use_medgel" },
		value = 275,
	},

	item_stim = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.STIM_1,
		desc = STRINGS.ITEMS.STIM_1_TOOLTIP,
		flavor = STRINGS.ITEMS.STIM_1_FLAVOR,
		icon = "itemrigs/FloorProp_Bandages.png",
		--profile_icon = "gui/items/icon-stims.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_stim_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_stim.png",
		traits = { cooldown = 0, cooldownMax = 9, mpRestored = 4, },
		requirements = { stealth = 2 },
		abilities = { "carryable","recharge","use_stim" },
		value = 400,
		floorWeight = 1, 
	},

	item_stim_2 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.STIM_2,
		desc = STRINGS.ITEMS.STIM_2_TOOLTIP,
		flavor = STRINGS.ITEMS.STIM_2_FLAVOR,
		icon = "itemrigs/FloorProp_Bandages.png",
		--profile_icon = "gui/items/icon-stims.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_stim_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_stim.png",
		traits = { cooldown = 0, cooldownMax = 7, mpRestored = 6, },
		requirements = { stealth = 3 },
		abilities = { "carryable","recharge","use_stim" },
		value = 800,
		floorWeight = 2, 
	},	

	item_stim_3 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.STIM_3,
		desc = STRINGS.ITEMS.STIM_3_TOOLTIP,
		flavor = STRINGS.ITEMS.STIM_3_FLAVOR,
		icon = "itemrigs/FloorProp_Bandages.png",
		--profile_icon = "gui/items/icon-stims.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_stim_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_stim.png",
		traits = { cooldown = 0, cooldownMax = 4, mpRestored = 8, combatRestored = true, },
		requirements = { stealth = 4 },
		abilities = { "carryable","recharge","use_stim" },
		value = 1000,
		floorWeight = 3,
	},	

	item_paralyzer_banks = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.PARALYZER_BANKS,
		desc = STRINGS.ITEMS.PARALYZER_BANKS_TOOLTIP,
		flavor = STRINGS.ITEMS.PARALYZER_BANKS_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-paralyzer.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_paralyzerdose_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_paralyzer_dose.png",	
		abilities = { "carryable","recharge","paralyze" },
		requirements = { anarchy = 2 },
		traits = { cooldown = 0, cooldownMax = 6, koTime = 3 },
		value = 400,
		floorWeight = 1,
		notSoldAfter = NEVER_SOLD, 
	},	

    item_paralyzer = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.PARALYZER_1,
		desc = STRINGS.ITEMS.PARALYZER_1_TOOLTIP,
		flavor = STRINGS.ITEMS.PARALYZER_1_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-paralyzer.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_paralyzerdose_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_paralyzer_dose.png",	
		abilities = { "carryable","recharge","paralyze" },
		requirements = { anarchy = 2 },
		traits = { cooldown = 0, cooldownMax = 6, koTime = 2 },
		value = 300,
		floorWeight = 1,
	},

	item_paralyzer_2 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.PARALYZER_2,
		desc = STRINGS.ITEMS.PARALYZER_2_TOOLTIP,
		flavor = STRINGS.ITEMS.PARALYZER_2_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-paralyzer.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_paralyzerdose_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_paralyzer_dose.png",	
		abilities = { "carryable","recharge","paralyze" },
		requirements = { anarchy = 3 },
		traits = { cooldown = 0, cooldownMax = 6, koTime = 3 },
		value = 500,
		floorWeight = 2,
	},

	item_paralyzer_3 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.PARALYZER_3,
		desc = STRINGS.ITEMS.PARALYZER_3_TOOLTIP,
		flavor = STRINGS.ITEMS.PARALYZER_3_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-paralyzer.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_paralyzerdose_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_paralyzer_dose.png",	
		abilities = { "carryable","recharge","paralyze" },
		requirements = { anarchy = 4 },
		traits = { cooldown = 0, cooldownMax = 6, koTime = 4 },
		value = 700,
		floorWeight = 3,
	},

------ CHARGED ITEMS

	item_laptop = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.PORTABLE_SERVER_1,
		desc = STRINGS.ITEMS.PORTABLE_SERVER_1_TOOLTIP,
		flavor = STRINGS.ITEMS.PORTABLE_SERVER_1_FLAVOR,
		icon = "console.png",		
		--profile_icon = "gui/items/icon-laptop.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_laptop_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_laptop.png",
		kanim = "kanim_laptop",
		traits = { laptop=true, mainframe_icon_on_deploy=true, mainframe_status = "active", sightable = true, cpus = 1, maxcpus = 1, cpuTurn = 1, cpuTurnMax = 2, hidesInCover = true,  cooldown = 0, cooldownMax = 2 },
		requirements = { hacking = 2 },
		abilities = {"deployable", "generateCPU", "carryable"},
		sounds = {spot="SpySociety/Objects/computer_types", deploy="SpySociety/Objects/SuitcaseComputer_open",pickUp="SpySociety/Objects/SuitcaseComputer_close"},
		rig = "consolerig",
		value = 500,
		floorWeight = 1,
		notSoldAfter = 48,
		locator = true,
	},

	item_laptop_internationale = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.LAPTOP_INTERNATIONALE,
		desc = STRINGS.ITEMS.LAPTOP_INTERNATIONALE_TOOLTIP,
		flavor = STRINGS.ITEMS.LAPTOP_INTERNATIONALE_FLAVOR,
		icon = "console.png",		
		--profile_icon = "gui/items/icon-laptop.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_laptop1_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_laptop1.png",
		kanim = "kanim_laptop",
		traits = { laptop=true, mainframe_icon_on_deploy=true, mainframe_status = "active", sightable = true, cpus = 1, maxcpus = 1, cpuTurn = 1, cpuTurnMax = 2, hidesInCover = true, cooldown = 0, cooldownMax = 2 },
		requirements = { hacking = 2 },
		abilities = {"deployable", "alarmCPU", "carryable"},
		sounds = {spot="SpySociety/Objects/computer_types", deploy="SpySociety/Objects/SuitcaseComputer_open",pickUp="SpySociety/Objects/SuitcaseComputer_close"},
		rig = "consolerig",
		value = 500,
		floorWeight = 1,
		notSoldAfter = 48, 
		locator = true,
	},

	item_laptop_2 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.PORTABLE_SERVER_2,
		desc = STRINGS.ITEMS.PORTABLE_SERVER_2_TOOLTIP,
		flavor = STRINGS.ITEMS.PORTABLE_SERVER_2_FLAVOR,
		icon = "console.png",
		--profile_icon = "gui/items/icon-laptop.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_laptop_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_laptop.png",
		kanim = "kanim_laptop",
		traits = { laptop=true, mainframe_icon_on_deploy=true, mainframe_status = "active", sightable = true, cpus = 1, maxcpus = 1, cpuTurn = 1, cpuTurnMax = 1, hidesInCover = true, cooldown = 0, cooldownMax = 2 },
		requirements = { hacking = 3 },
		abilities = {"deployable", "generateCPU", "carryable"},
		sounds = {spot="SpySociety/Objects/computer_types", deploy="SpySociety/Objects/SuitcaseComputer_open",pickUp="SpySociety/Objects/SuitcaseComputer_close"},
		rig = "consolerig",
		value = 1000,
		floorWeight = 2,
		locator = true,
	},

	item_laptop_3 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.PORTABLE_SERVER_3,
		desc = STRINGS.ITEMS.PORTABLE_SERVER_3_TOOLTIP,
		flavor = STRINGS.ITEMS.PORTABLE_SERVER_3_FLAVOR,
		icon = "console.png",
		--profile_icon = "gui/items/icon-laptop.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_laptop_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_laptop.png",
		kanim = "kanim_laptop",
		traits = { laptop=true, mainframe_icon_on_deploy=true, mainframe_status = "active", sightable = true, cpus = 2, maxcpus = 2, cpuTurn = 1, cpuTurnMax = 1, hidesInCover = true, cooldown = 0, cooldownMax = 2 },
		requirements = { hacking = 4 },
		abilities = {"deployable", "generateCPU", "carryable"},
		sounds = {spot="SpySociety/Objects/computer_types", deploy="SpySociety/Objects/SuitcaseComputer_open",pickUp="SpySociety/Objects/SuitcaseComputer_close"},
		rig = "consolerig",
		value = 1500,
		floorWeight = 3,
		locator = true,
	},

	item_cloakingrig_deckard = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.CLOAK_DECKARD,
		desc = STRINGS.ITEMS.CLOAK_DECKARD_TOOLTIP,
		flavor = STRINGS.ITEMS.CLOAK_DECKARD_FLAVOR,
		icon = "itemrigs/FloorProp_InvisiCloakTimed.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_invisicloak_small.png",			
		profile_icon_100 = "gui/icons/item_icons/icon-item_invisi_cloak.png",
		traits = { disposable = false, duration = 1,cooldown = 0, cooldownMax = 8,  cloakInVision = true },
		requirements = { stealth = 2 },
		abilities = { "carryable","recharge","useInvisiCloak" },
		value = 400,
		floorWeight = 1,
		notSoldAfter = NEVER_SOLD, 
	},

	item_cloakingrig_1 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.CLOAK_1,
		desc = STRINGS.ITEMS.CLOAK_1_TOOLTIP,
		flavor = STRINGS.ITEMS.CLOAK_1_FLAVOR,
		icon = "itemrigs/FloorProp_InvisiCloakTimed.png",
		--profile_icon = "gui/items/icon-cloak.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_invisicloak_small.png",			
		profile_icon_100 = "gui/icons/item_icons/icon-item_invisi_cloak.png",
		traits = { disposable = false, duration = 1,cooldown = 0, cooldownMax = 10,  cloakDistanceMax=5, cloakInVision = true },
		requirements = { stealth = 2 },
		abilities = { "carryable","recharge","useInvisiCloak" },
		value = 400,
		floorWeight = 1,
		notSoldAfter = 48, 
	},

	item_cloakingrig_2 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.CLOAK_2,
		desc = STRINGS.ITEMS.CLOAK_2_TOOLTIP,
		flavor = STRINGS.ITEMS.CLOAK_2_FLAVOR,
		icon = "itemrigs/FloorProp_InvisiCloakTimed.png",
		--profile_icon = "gui/items/icon-cloak.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_invisicloak_small.png",			
		profile_icon_100 = "gui/icons/item_icons/icon-item_invisi_cloak.png",
		traits = { disposable = false, duration = 1,cooldown = 0, cooldownMax = 8, cloakInVision = true },
		requirements = { stealth = 3 },
		abilities = { "carryable","recharge","useInvisiCloak" },
		value = 700,
		floorWeight = 2,
	},

	item_cloakingrig_3 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.CLOAK_3,
		desc = STRINGS.ITEMS.CLOAK_3_TOOLTIP,
		flavor = STRINGS.ITEMS.CLOAK_3_FLAVOR,

		icon = "itemrigs/FloorProp_InvisiCloakTimed.png",
		--profile_icon = "gui/items/icon-cloak.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_invisicloak_small.png",			
		profile_icon_100 = "gui/icons/item_icons/icon-item_invisi_cloak.png",
		traits = { disposable = false, duration = 1,cooldown = 0, cooldownMax = 8, cloakInVision = true, range = 4 },
		traits_17_5 = { disposable = false, duration = 2, cooldown = 0, cooldownMax = 8, cloakInVision = true },
		requirements = { stealth = 4 },
		abilities = { "carryable","recharge","useInvisiCloak" },
		value = 850,
		floorWeight = 3,
		upgradeOverride = "item_cloakingrig_3_17_5", 
	},

	item_cloakingrig_3_17_5 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.CLOAK_3_17_5,
		desc = STRINGS.ITEMS.CLOAK_3_17_5_TOOLTIP,
		flavor = STRINGS.ITEMS.CLOAK_3_17_5_FLAVOR,

		icon = "itemrigs/FloorProp_InvisiCloakTimed.png",
		--profile_icon = "gui/items/icon-cloak.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_invisicloak_small.png",			
		profile_icon_100 = "gui/icons/item_icons/icon-item_invisi_cloak.png",
		traits = { disposable = false, duration = 2, cooldown = 0, cooldownMax = 8, cloakInVision = true },
		requirements = { stealth = 4 },
		abilities = { "carryable","recharge","useInvisiCloak" },
		value = 850,
		floorWeight = 3,
	},


	item_icebreaker= util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.BUSTER_1,
		desc = STRINGS.ITEMS.BUSTER_1_TOOLTIP,
		flavor = STRINGS.ITEMS.BUSTER_1_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_ice_breaker.png",		
		traits = { icebreak = 2,cooldown = 0, cooldownMax = 5,  },
		requirements = { anarchy = 2, },
		abilities = { "icebreak","recharge","carryable" },
		value = 250,
		floorWeight = 1,
		notSoldAfter = 48, 
	},

	item_icebreaker_2 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.BUSTER_2,
		desc = STRINGS.ITEMS.BUSTER_2_TOOLTIP,
		flavor = STRINGS.ITEMS.BUSTER_2_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_ice_breaker.png",		
		traits = { icebreak = 3,cooldown = 0, cooldownMax = 4,  },
		requirements = { anarchy = 3, },
		abilities = { "icebreak","recharge","carryable" },
		value = 400,
		floorWeight = 2,
	},

	item_icebreaker_3 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.BUSTER_3,
		desc = STRINGS.ITEMS.BUSTER_3_TOOLTIP,
		flavor = STRINGS.ITEMS.BUSTER_3_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_ice_breaker.png",		
		traits = { icebreak = 4,cooldown = 0, cooldownMax = 3,  },
		requirements = { anarchy = 4, },
		abilities = { "icebreak","recharge","carryable" },
		value = 600,
		floorWeight = 3,
	},
    
	item_prototype_drive = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.PROTOCHIP,
		desc = STRINGS.ITEMS.PROTOCHIP_TOOLTIP,
		flavor = STRINGS.ITEMS.PROTOCHIP_FLAVOR,
        onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
			tooltip:addAbility( STRINGS.ITEMS.PROTOCHIP_HEADER,
				string.format( STRINGS.ITEMS.PROTOCHIP_FORMAT, unit:getTraits().icebreak, unit:getTraits().maxIcebreak ), "gui/items/icon-action_hack-console.png" )
        end,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_proto_chip_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_proto_chip.png",	
		traits = { icebreak = 0, maxIcebreak = 10 },
		abilities = { "carryable","recharge","jackin_charge", "icebreak" },
		value = 700,
		createUpgradeParams = function( self, unit )
			return { traits = { icebreak = unit:getTraits().icebreak } }
		end,
        floorWeight = 3,
	},

	item_portabledrive = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.ACCELERATOR_1,
		desc = STRINGS.ITEMS.ACCELERATOR_1_TOOLTIP,
		flavor = STRINGS.ITEMS.ACCELERATOR_1_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_accellerator_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_accellerator.png",	
		traits = { hacking_bonus = 1,  cooldown = 0, cooldownMax = 2,  },
		requirements = { anarchy = 2, },
		abilities = { "carryable","recharge","jackin" },
		value = 300,
		floorWeight = 1,
		notSoldAfter = 48, 
	},

	item_portabledrive_2 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.ACCELERATOR_2,
		desc = STRINGS.ITEMS.ACCELERATOR_2_TOOLTIP,
		flavor = STRINGS.ITEMS.ACCELERATOR_2_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_accellerator_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_accellerator.png",	
		traits = { hacking_bonus = 2,  cooldown = 0, cooldownMax = 2,  },
		requirements = { anarchy = 3, },
		abilities = { "carryable","recharge","jackin" },
		value = 550,
		floorWeight = 2,
	},

	item_portabledrive_3 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.ACCELERATOR_3,
		desc = STRINGS.ITEMS.ACCELERATOR_3_TOOLTIP,
		flavor = STRINGS.ITEMS.ACCELERATOR_3_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_accellerator_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_accellerator.png",	
		traits = { hacking_bonus = 4,  cooldown = 0, cooldownMax = 2,  },
		requirements = { anarchy = 4, },
		abilities = { "carryable","recharge","jackin" },
		value = 800,
		floorWeight = 3,
	},

	item_econchip = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.ECON_CHIP,
		desc = STRINGS.ITEMS.ECON_CHIP_TOOLTIP,
		flavor = STRINGS.ITEMS.ECON_CHIP_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_econ_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_econ.png",	
		traits = { cooldown = 0, cooldownMax = 5, PWR_conversion = 50 },
		requirements = { stealth = 2, },
		abilities = { "carryable","recharge","jackin" },
		value = 800,
		floorWeight = 1,
	},

	item_econchip_banks = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.ECON_CHIP_BANKS,
		desc = STRINGS.ITEMS.ECON_CHIP_BANKS_TOOLTIP,
		flavor = STRINGS.ITEMS.ECON_CHIP_BANKS_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_econ_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_econ.png",	
		traits = { cooldown = 0, cooldownMax = 4, PWR_conversion = 50 },
		requirements = { stealth = 1, },
		abilities = { "carryable","recharge","jackin" },
		value = 800,
		floorWeight = 1,
	},	

	item_scanchip = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.SCAN_CHIP,
		desc = STRINGS.ITEMS.SCAN_CHIP_TOOLTIP,
		flavor = STRINGS.ITEMS.SCAN_CHIP_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_daemonscan_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_daemonscan.png",	
		traits = { cooldown = 0, cooldownMax = 2, PWR_conversion = 50 },
		requirements = { stealth = 2, },
		abilities = { "carryable","recharge","scandevice" },
		value = 100,
		floorWeight = 1,
	},

	item_monst3r_gun = util.extend( commondefs.weapon_template )
	{
		name = STRINGS.ITEMS.DARTGUN_MONST3R,
		desc = STRINGS.ITEMS.DARTGUN_MONST3R_TOOLTIP,
		flavor = STRINGS.ITEMS.DARTGUN_MONST3R_FLAVOR,
		icon = "itemrigs/FloorProp_Precision_Pistol.png",	
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_gun_dart_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_gun_dart.png",				
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { finalStartItem = true, weaponType="pistol", baseDamage = 2, armorPiercing = 3, cooldown = 0, cooldownMax = 8, canSleep = true, spawnsDaemon = true },
        abilities = util.tmerge( { "recharge" }, commondefs.weapon_template.abilities ),
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_dart", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		requirements = { hacking = 3 },
		weapon_anim = "kanim_precise_revolver",
		agent_anim = "anims_1h",
		value = 600,
		floorWeight = 1,
	},

	item_tazer_shalem = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.TAZER_SHALEM,
		desc = STRINGS.ITEMS.TAZER_SHALEM_TOOLTIP,
		flavor = STRINGS.ITEMS.TAZER_SHALEM_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		requirements = {  },
		traits = { damage = 2,  cooldown = 0, cooldownMax = 5, melee = true, level = 1 },
		value = 300,
		floorWeight = 1,
	},

	item_tazer = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.TAZER_1,
		desc = STRINGS.ITEMS.TAZER_1_TOOLTIP,
		flavor = STRINGS.ITEMS.TAZER_1_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		requirements = {  },
		traits = { damage = 2,  cooldown = 0, cooldownMax = 3, melee = true, level = 1 },
		value = 500,
		floorWeight = 1,
	},

	item_tazer_2 = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.TAZER_2,
		desc = STRINGS.ITEMS.TAZER_2_TOOLTIP,
		flavor = STRINGS.ITEMS.TAZER_2_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		requirements = {  },
		traits = { damage = 2,  cooldown = 0, armorPiercing = 1, cooldownMax = 3, melee = true, tazer = true, level = 2 },
		value = 700,
		floorWeight = 2,
	},

	item_tazer_3 = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.TAZER_3,
		desc = STRINGS.ITEMS.TAZER_3_TOOLTIP,
		flavor = STRINGS.ITEMS.TAZER_3_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		requirements = {  },
		traits = { damage = 3,  cooldown = 0, cooldownMax = 4, armorPiercing = 2, melee = true, tazer = true, level = 3 },
		value = 900,
		floorWeight = 3,
		soldAfter = 24, 
	},

	item_power_tazer_nika = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.TAZER_PWR_NIKA,
		desc = STRINGS.ITEMS.TAZER_PWR_NIKA_TOOLTIP,
		flavor = STRINGS.ITEMS.TAZER_PWR_NIKA_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_pwr_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer_pwr.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		abilities = { "carryable"},
		requirements = {  },
		traits = { damage = 2,  pwrCost = 2, melee = true, tazer = true, level = 1 },
		value = 500,
		floorWeight = 1,		
	},	


	item_power_tazer_1 = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.TAZER_PWR_1,
		desc = STRINGS.ITEMS.TAZER_PWR_1_TOOLTIP,
		flavor = STRINGS.ITEMS.TAZER_PWR_1_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_pwr_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer_pwr.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		abilities = { "carryable"},
		requirements = {  },
		traits = { damage = 2,  pwrCost = 3, melee = true, tazer = true, level = 1 },
		value = 500,
		floorWeight = 1,		
	},	

	item_power_tazer_2 = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.TAZER_PWR_2,
		desc = STRINGS.ITEMS.TAZER_PWR_2_TOOLTIP,
		flavor = STRINGS.ITEMS.TAZER_PWR_2_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_pwr_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer_pwr.png",	
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		abilities = { "carryable"},
		requirements = {  },
		traits = { damage = 2, pwrCost = 4, armorPiercing = 1, melee = true, tazer = true, level = 2 },
		value = 700,
		floorWeight = 2,		
	},	

	item_power_tazer_3 = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.TAZER_PWR_3,
		desc = STRINGS.ITEMS.TAZER_PWR_3_TOOLTIP,
		flavor = STRINGS.ITEMS.TAZER_PWR_3_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_pwr_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer_pwr.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		abilities = { "carryable" },
		requirements = {  },
		traits = { damage = 3, pwrCost = 5, armorPiercing = 2, melee = true, tazer = true, level = 3 },
		value = 900,
		floorWeight = 3,	
		soldAfter = 24, 	
	},
			
--------- ONE USE 

	item_lockdecoder = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.LOCK_DECODER_1,
		desc = STRINGS.ITEMS.LOCK_DECODER_1_TOOLTIP,
		flavor = STRINGS.ITEMS.LOCK_DECODER_1_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_lock_decoder_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_lock_decoder.png",		
		traits = { cooldown = 0, cooldownMax = 3, applyFn = "isSecurityExit", doorDevice = "lock_decoder", profile_icon="gui/icons/item_icons/items_icon_small/icon-item_lock_decoder_small.png" },
		requirements = { },
		abilities = { "doorMechanism", "carryable" },
		value = 400,		
		floorWeight = 1,
	},


	item_shocktrap_tony = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.SHOCK_TRAP_TONY,
		desc = STRINGS.ITEMS.SHOCK_TRAP_TONY_TOOLTIP,
		flavor = STRINGS.ITEMS.SHOCK_TRAP_TONY_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-shocktrap-.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_shocktrap_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_shock trap.png",		
		traits = { cooldown = 0, cooldownMax = 7, damage = 3, stun = 3, applyFn = "isClosedDoor", doorDevice = "simtrap" },
		abilities = { "doorMechanism","recharge", "carryable" },
		value = 400,
		floorWeight = 1,
	},

	item_shocktrap = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.SHOCK_TRAP_1,
		desc = STRINGS.ITEMS.SHOCK_TRAP_1_TOOLTIP,
		flavor = STRINGS.ITEMS.SHOCK_TRAP_1_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-shocktrap-.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_shocktrap_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_shock trap.png",		
		traits = { cooldown = 0, cooldownMax = 7, damage = 3, stun = 3, applyFn = "isClosedDoor", doorDevice = "simtrap" },
		requirements = { anarchy = 2 },
		abilities = { "doorMechanism","recharge", "carryable" },
		value = 400,
		floorWeight = 1,
		notSoldAfter = 48, 
	},

	item_shocktrap_2 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.SHOCK_TRAP_2,
		desc = STRINGS.ITEMS.SHOCK_TRAP_2_TOOLTIP,
		flavor = STRINGS.ITEMS.SHOCK_TRAP_2_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-shocktrap-.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_shocktrap_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_shock trap.png",		
		traits = { cooldown = 0, cooldownMax = 6, damage = 4, stun = 4, applyFn = "isClosedDoor", doorDevice = "simtrap" },
		requirements = { anarchy = 3 },
		abilities = { "doorMechanism","recharge","carryable" },
		value = 700,
		floorWeight = 2,
	},

	item_shocktrap_3 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.SHOCK_TRAP_3,
		desc = STRINGS.ITEMS.SHOCK_TRAP_3_TOOLTIP,
		flavor = STRINGS.ITEMS.SHOCK_TRAP_3_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-shocktrap-.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_shocktrap_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_shock trap.png",		
		traits = { cooldown = 0, cooldownMax = 5,  damage = 5, stun = 5, range = 5, applyFn = "isClosedDoor", doorDevice = "simtrap" },
		requirements = { anarchy = 4 },
		abilities = { "doorMechanism","recharge","carryable" },
		value = 1000,
		floorWeight = 3,
	},

	item_shocktrap_mod = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.SHOCK_TRAP_MOD,
		desc = STRINGS.ITEMS.SHOCK_TRAP_MOD_TOOLTIP,
		flavor = STRINGS.ITEMS.SHOCK_TRAP_MOD_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-shocktrap-.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_shocktrap_mod_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_shock trap_mod.png",		
		traits = { disposable = true, damage = 3, stun = 3, applyFn = "isClosedDoor", doorDevice = "simtrap" },
		requirements = { anarchy = 1 },
		abilities = { "doorMechanism", "carryable" },
		value = 200,
		floorWeight = 1,
		notSoldAfter = 48, 
	},

	item_emp_pack_tony = util.extend(commondefs.item_template)
	{
		type = "simemppack",
		name = STRINGS.ITEMS.EMP_TONY,
		desc = STRINGS.ITEMS.EMP_TONY_TOOLTIP,
		flavor = STRINGS.ITEMS.EMP_TONY_FLAVOR,
		icon = "itemrigs/FloorProp_emp.png",
		--profile_icon = "gui/items/icon-emp.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_emp_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_emp.png",	
		abilities = { "carryable","recharge","prime_emp", },
		traits = { cooldown = 0, cooldownMax = 8, range = 3, emp_duration = 2 },
		value = 600,
		floorWeight = 1, 
	},

	item_emp_pack = util.extend(commondefs.item_template)
	{
		type = "simemppack",
		name = STRINGS.ITEMS.EMP_1,
		desc = STRINGS.ITEMS.EMP_1_TOOLTIP,
		flavor = STRINGS.ITEMS.EMP_1_FLAVOR,
		icon = "itemrigs/FloorProp_emp.png",
		--profile_icon = "gui/items/icon-emp.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_emp_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_emp.png",	
		abilities = { "carryable","recharge","prime_emp", },
		requirements = { hacking = 2 },
		traits = { cooldown = 0, cooldownMax = 8, range = 3, emp_duration = 2 },
		value = 500,
		floorWeight = 1,
		notSoldAfter = 48, 
	},

	item_emp_pack_2 = util.extend(commondefs.item_template)
	{
		type = "simemppack",
		name = STRINGS.ITEMS.EMP_2,
		desc = STRINGS.ITEMS.EMP_2_TOOLTIP,
		flavor = STRINGS.ITEMS.EMP_2_FLAVOR,
		icon = "itemrigs/FloorProp_emp.png",
		--profile_icon = "gui/items/icon-emp.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_emp_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_emp.png",	
		abilities = { "carryable","recharge","prime_emp", },
		requirements = { hacking = 3 },
		traits = { cooldown = 0, cooldownMax = 8, range = 5, emp_duration = 2 },
		value = 800,
		floorWeight = 2,
	},

	item_emp_pack_3 = util.extend(commondefs.item_template)
	{
		type = "simemppack",
		name = STRINGS.ITEMS.EMP_3,
		desc = STRINGS.ITEMS.EMP_3_TOOLTIP,
		flavor = STRINGS.ITEMS.EMP_3_FLAVOR,
		icon = "itemrigs/FloorProp_emp.png",
		--profile_icon = "gui/items/icon-emp.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_emp_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_emp.png",	
		abilities = { "carryable","recharge","prime_emp", },
		requirements = { hacking = 4 },
		traits = { cooldown = 0, cooldownMax = 8, range = 7, emp_duration = 2 },
		value = 1200,
		floorWeight = 3,
	},

	vault_passcard = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.VAULT_PASS,
		desc = STRINGS.ITEMS.VAULT_PASS_TOOLTIP,
		flavor = STRINGS.ITEMS.VAULT_PASS_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_vault_key_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_vault_key.png",
		abilities = { "carryable" },
		value = 500,
		traits = { keybits = simdefs.DOOR_KEYS.VAULT }, 
	},

	special_exit_passcard = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.EXIT_PASS,
		desc = STRINGS.ITEMS.EXIT_PASS_TOOLTIP,
		flavor = STRINGS.ITEMS.EXIT_PASS_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_exit_key_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_exit_key.png",
		abilities = { "carryable" },
		value = 500,
		traits = { keybits = simdefs.DOOR_KEYS.SPECIAL_EXIT }, 
	},
    
    item_daemon_blocker = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.DAEMON_BLOCKER, 
		desc = STRINGS.ITEMS.DAEMON_BLOCKER_TOOLTIP,
		flavor = STRINGS.ITEMS.DAEMON_BLOCKER_FLAVOR,  
		icon = "itemrigs/FloorProp_KeyCard.png", 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_vault_key_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_vault_key.png",
		tooltip = "<ttbody><ttheader2>ARCHDAEMON INHIBITOR</> Use a charge to block an Archdaemon from activating.",
		abilities = { "carryable" },
		value = 0, 
		traits = { daemon_blocker = true, maxAmmo = 8, ammo = 0 },
		createUpgradeParams = function( self, unit )
			return { traits = { ammo = unit:getTraits().ammo } }
		end,
	},

	item_wireless_scanner_1 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.WIRELESS_SCANNER, 
		desc = STRINGS.ITEMS.WIRELESS_SCANNER_TOOLTIP, 
        flavor = STRINGS.ITEMS.WIRELESS_SCANNER_FLAVOR,
		icon = "itemrigs/FloorProp_MotionDetector.png", 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_scanner_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_scanner.png",
		requirements = { hacking = 2 },
		abilities = { "carryable", "wireless_scan" },
		value = 600,
		traits = { wireless_range = 4 },
		floorWeight = 3,
	},

	item_wireless_scanner_custom = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.WIRELESS_SCANNER_CUSTOM, 
		desc = STRINGS.ITEMS.WIRELESS_SCANNER_TOOLTIP, 
        flavor = STRINGS.ITEMS.WIRELESS_SCANNER_FLAVOR,
		icon = "itemrigs/FloorProp_MotionDetector.png", 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_scanner_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_scanner.png",
		requirements = { hacking = 2 },		
		abilities = { "carryable", "wireless_scan" },
		value = 600,
		traits = { range = 5 },
	},

	item_defiblance = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.DEFIBRILLATOR, 
		desc = STRINGS.ITEMS.DEFIBRILLATOR_TOOLTIP, 
        flavor = STRINGS.ITEMS.DEFIBRILLATOR_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",

		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_defibulator_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_defibulator.png",	
		traits = { cooldown = 0, cooldownMax = 6 },
		abilities = { "carryable","use_aggression" },
		value = 700,	
		floorWeight = 2,	
	},	

	item_baton = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.BATON,
		desc = STRINGS.ITEMS.BATON_TOOLTIP,
		flavor = STRINGS.ITEMS.BATON_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		requirements = {  },
		traits = { damage = 1, melee = true, lethalMelee = true},
		value = 500,
		floorWeight = 1,
	},	

	item_incognita = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.INCOGNITA_DRIVE,
		desc = STRINGS.ITEMS.INCOGNITA_DRIVE_TOOLTIP,
		flavor = STRINGS.ITEMS.INCOGNITA_DRIVE_FLAVOR,
		icon = "itemrigs/disk.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_incognita_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_incognita.png",
		abilities = { "carryable"  },
		traits = { cantdrop = true, pickupOnly="central"}, 
	},

	item_compiler_key = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.COMPILER_KEY,
		desc = STRINGS.ITEMS.COMPILER_KEY_TOOLTIP,
		flavor = STRINGS.ITEMS.COMPILER_KEY_FLAVOR,
		icon = "itemrigs/disk.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_incognita_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_incognita.png",
		abilities = { "carryable","compile_software" },
		traits = {disposable=true}, 
	},

	item_prism_1 = util.extend(commondefs.item_template)
	{
		type = "item_disguise",
		name = STRINGS.ITEMS.HOLO_MESH,
		desc = STRINGS.ITEMS.HOLO_MESH_TOOLTIP,
		flavor = STRINGS.ITEMS.HOLO_MESH_FLAVOR,
		icon = "itemrigs/disk.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_holomesh_Prism.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_holomesh_Prism.png",		
    	abilities = { "carryable" , "disguise" },
    	value = 500,
    	traits = {  CPUperTurn=2, pwrCost=2, warning=STRINGS.ITEMS.HOLO_MESH_WARNING, restrictedUse={{agentID=8,name=STRINGS.AGENTS.PRISM.NAME}}, drop_dropdisguise=true },	
	},	
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates
