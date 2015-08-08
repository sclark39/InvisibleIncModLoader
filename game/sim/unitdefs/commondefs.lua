----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local speechdefs = include( "sim/speechdefs" )
----------------------------------------------------------------
-- Common definition tables re-used/extended elsewhere.

local HOTKEY_COLOUR = "<c:ffffff>"
local FLAVOUR_COLOUR = "<c:61AAAA>"
local ITEM_HEADER_COLOUR = "<ttheader>"
local DESC_COLOUR = "<c:ffffff>"
local EQUIPPED_COLOUR = "<c:FF8411>"
local NOTINSTALLED_COLOUR = "<c:FF8411>"
--local SPECIAL_INFO_COLOUR = "<c:F4FF78>"
local SPECIAL_INFO_COLOUR = "<c:ffffff>"




local AGENT_ANIMS =
{
	idle_ko = "dead",
	ko = "death",
	body_drag_idle_pre = "body_drag_idle",
    walk180 = "walk",
    tinker_loop_pre = "tinker_loop",
}

local GUARD_ANIMS =
{
	idle_ko = "dead",
	ko = "death",
	overwatch_pre = "shoot_pre",
	overwatch = "shoot_pre",
}

local HOSTAGE_ANIMS = 
{
	idle = "untie_idle",
}

local DRONE_ANIMS =
{
	idle_ko = "idle_closed",
	cover = "idle",
	pin = "idle",

	walk_pre = "move_pre",
	cover_run = "move_pre",
	walk = "move",
	snk = "move",
	run = "move",
	walk_pst = "move_pst",
	run_pst = "move_pst",
    snk_pst = "move_pst",
	pin_pre = "",

	shoot1 = "shoot",
	shoot2 = "shoot",
	shoot3 = "shoot",
	overwatch_pre = "shoot_pre",
	overwatch = "shoot_pre",
    pinshoot_pre = "shoot_pre",
    pinshoot = "shoot",
    pinshoot_pst = "shoot_pst",
    pin_stand = "",

	hitfrt = "hit",
	hitbck = "hit",
	hitfrt_pst = "",
	hitbck_pst = "",
	cover_pre = "",

	ko = "close",
	get_up = "open",
	get_up_pst = "open",
	idle_pre = "idle",

    hide_pst = "",
    use_comp = "",

	shrug = "",
}

local FLOAT_DRONE_ANIMS = util.extend( DRONE_ANIMS )
{
	idle_ko = "idle_closed",

	walk_pre = "idle",
	cover_run = "idle",
	walk = "idle",
	snk = "idle",
	run = "idle",
	walk_pst = "idle",
	run_pst = "idle",
    snk_pst = "idle",

	shoot1 = "idle",
	shoot2 = "idle",
	shoot3 = "idle",
	overwatch_pre = "idle",
	overwatch = "idle",

	hitfrt = "idle",
	hitbck = "idle",

	ko = "close",
	get_up = "idle",
	get_up_pst = "idle",
	idle_pre = "idle",
}

local FLOAT_DRONE_TANK_ANIMS = util.extend( DRONE_ANIMS )
{
	idle_ko = "idle_closed",

	walk_pre = "idle",
	cover_run = "idle",
	walk = "idle",
	snk = "idle",
	run = "idle",
	walk_pst = "idle",
	run_pst = "idle",
    snk_pst = "idle",

	shoot1 = "attack",
	shoot2 = "attack",
	shoot3 = "attack",
    shoot_pre = "",
    shoot_pst = "",
    pinshoot_pre = "attack",
    pinshoot = "attack",
    pinshoot_pst = "attack",
	overwatch_pre = "alert_pre",
	overwatch = "alert_idle",

	ko = "close",
	hitfrt = "idle",
	hitbck = "idle",

}

local Layer =
{
	Floor = 0,
	Wall = 1,
	Decor = 2,
	Object = 3,
	Unit = 4,
	FX = 5,
}

local BoundType =
{
	Character			=	1,
	CharacterFloor		=	2,
	Wall				=	3,
	Wall_Painting 		=   4,
	WallFlip			=	5,
	Wall2				=	6,
	Wall3				=	7,
	bound_1x1_med_med	=	8,
	bound_1x1_med_big	=	9,
	bound_1x1_tall_med 	=   10,
	bound_1x1_verytall_med 	=   11,	
	bound_1x1_tall_big 	=   12,	
	bound_2x1_med_med	=	13,
	bound_2x1_tall_med	=	14,
	bound_2x2			=	15,
	bound_2x3			=	16,
	bound_3x1_med_med			=	17,
	bound_3x1_tall_med			=	18,
	bound_3x1_med_big			=	19,
	Floor_1x1			=	20,
	Floor_1x2			=	21,
	Floor_2x1			=	22,
	Floor_2x2			=	23,	
	Floor_2x3			=	24,
    Floor_2x4           =   25,
	Floor_3x2			=	26,
	Floor_3x3			=	27,
	Floor_3x4			=	28,
	Floor_4x3			=	29,
	Floor_4x4			=	30,
    Ceiling_1x1         =   31,
    Wall5				=	32,
}






local function onAgentTooltip( tooltip, unit )
	local unitInfo = string.format( "" ) -- "HP: %d/%d", unit:getTraits().woundsMax - unit:getTraits().wounds, unit:getTraits().woundsMax 
	if unit:isPC() then
		tooltip:addLine( ITEM_HEADER_COLOUR..util.toupper(unit:getName()).."</>", unitInfo )
		if unit:isKO() then
			tooltip:addAbility( STRINGS.UI.TOOLTIP_AGENT_DOWN, STRINGS.UI.TOOLTIP_AGENT_DOWN_DESC, "gui/icons/item_icons/items_icon_small/icon-item_medigel_small.png" )
		end
	else
		if unit:isKO() then
			if unit:getTraits().paralyzed then
				unitInfo = string.format( STRINGS.UI.TOOLTIP_NAME_PARALYZED, unitInfo )
			else
				unitInfo = string.format( STRINGS.UI.TOOLTIP_NAME_KO_TIME, unitInfo, unit:getTraits().koTimer )
			end
		end
		tooltip:addLine( ITEM_HEADER_COLOUR..util.toupper(unit:getName()).."</>", unitInfo )

		if unit:getTraits().tagged then
			tooltip:addLine(  string.format( "<c:F4FF78>%s</>",STRINGS.UI.TOOLTIP_TAGGED) )
		end

		
		if unit:getTraits().unlimitedAttacks then
			tooltip:addLine(  string.format( "<c:F4FF78>%s</>",STRINGS.UI.TOOLTIP_TAGGED) )
		end		
	end
end

local function onItemWorldTooltip( tooltip, unit )
    tooltip:addLine( ITEM_HEADER_COLOUR..unit:getName().."</>" )

    if unit:getUnitData().flavor then
        tooltip:addDesc(  string.format("<c:61AAAA>"..unit:getUnitData().flavor).."</c>" )
    end	
    
    if unit:getUnitData().desc then
        tooltip:addDesc( unit:getUnitData().desc )
    end

    if unit:getTraits().pickupOnly then
        tooltip:addDesc( util.sformat(STRINGS.UI.TOOLTIPS.PICK_UP_CONDITION_DESC, util.toupper(unit:getTraits().pickupOnly) ) )
    end
end

local function onItemTooltip( tooltip, unit, userUnit )
    local simquery = include( "sim/simquery" )
    local name = util.toupper( unit:getName() )
	if unit:getTraits().ammo and unit:getTraits().maxAmmo then
		tooltip:addLine( ITEM_HEADER_COLOUR..name.."</>", string.format(STRINGS.ITEMS.AMMO,unit:getTraits().ammo,unit:getTraits().maxAmmo) )
	--elseif unit:getTraits().augment then
	--	tooltip:addLine( "<c:CCCC00>"..name.."</>" )
    else
		tooltip:addLine( ITEM_HEADER_COLOUR..name.."</>" )
	end

    if unit:getUnitData().flavor then
        tooltip:addDesc(  FLAVOUR_COLOUR..unit:getUnitData().flavor.."</>" )
    end	

   	if unit:getTraits().augment and unit:getTraits().installed == false then		
		tooltip:addLine( NOTINSTALLED_COLOUR.. STRINGS.UI.TOOLTIPS.NOT_INSTALLED .."</c>" )
	end

    if unit:getUnitData().desc then
        tooltip:addDesc( unit:getUnitData().desc )
    end

	if unit:getTraits().equipped then
		tooltip:addLine( EQUIPPED_COLOUR.. STRINGS.UI.TOOLTIPS.EQUIPPED .."</c>") 
	end
   	
	if unit:getUnitData().keyword then
		local keywordStrings = STRINGS.ITEMS.KEYWORDS[ unit:getUnitData().keyword ]
        if keywordStrings and keywordStrings.NAME and keywordStrings.DESC then
            tooltip:addAbility( keywordStrings.NAME, keywordStrings.DESC, "gui/items/icon-item_implant.png",nil,true )
        end
	end

	if unit:getTraits().cooldownMax then
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.RECHARGE, util.sformat(STRINGS.ITEMS.TOOLTIPS.RECHARGE_DESC, unit:getTraits().cooldownMax), "gui/icons/arrow_small.png" )
	end

	if not unit:getTraits().slot and unit:getTraits().damage then
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE, util.sformat(STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE_DESC, unit:getTraits().damage), "gui/icons/arrow_small.png" )
	end

	if unit:getTraits().range then
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.RANGE, util.sformat(STRINGS.ITEMS.TOOLTIPS.RANGE_DESC, unit:getTraits().range), "gui/icons/arrow_small.png" )
	end

	if unit:getTraits().disposable then
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.DISPOSABLE, STRINGS.ITEMS.TOOLTIPS.DISPOSABLE_DESC, "gui/icons/arrow_small.png" )
	end

	if unit:getTraits().cashInReward then
		tooltip:addLine( util.sformat( SPECIAL_INFO_COLOUR.. STRINGS.UI.TOOLTIPS.RETURN_FOR_CREDIT .."</c>", unit:getTraits().cashInReward) )
	end


	if unit:getTraits().pwrCost then
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.COSTPOWER, util.sformat(STRINGS.ITEMS.TOOLTIPS.COSTPOWER_DESC, unit:getTraits().pwrCost), "gui/icons/arrow_small.png" )
	end	
	if unit:getTraits().usesCharges then
		tooltip:addAbility( util.sformat(STRINGS.ITEMS.TOOLTIPS.USE_CHARGES, unit:getTraits().charges,unit:getTraits().chargesMax), STRINGS.ITEMS.TOOLTIPS.USE_CHARGES_DESC, "gui/icons/arrow_small.png" )
	end		

	if unit:getTraits().CPUperTurn then
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.DRAINPOWER, util.sformat(STRINGS.ITEMS.TOOLTIPS.DRAINPOWER_DESC, unit:getTraits().CPUperTurn), "gui/icons/arrow_small.png" )
	end	

	if unit:getTraits().PWRuse then
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.COSTPOWER_ACTIVATE, util.sformat(STRINGS.ITEMS.TOOLTIPS.COSTPOWER_ACTIVATE_DESC, unit:getTraits().PWRuse), "gui/icons/arrow_small.png" )
	end	

	if unit:getTraits().coolDownUse then
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.RECHARGE_ACTIVATE, util.sformat(STRINGS.ITEMS.TOOLTIPS.RECHARGE_ACTIVATE_DESC, unit:getTraits().coolDownUse), "gui/icons/arrow_small.png" )
	end	


	if unit:getTraits().restrictedUse then
		local  agentList = ""
		for i,agent in ipairs(unit:getTraits().restrictedUse) do			
			agentList = agentList .. agent.name.."\n"
		end
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.RESTRICTED_USE, util.sformat(STRINGS.ITEMS.TOOLTIPS.RESTRICTED_USE_DESC, agentList), "gui/icons/arrow_small.png" )
	end	

	if unit:getTraits().augment then
		if unit:getTraits().stackable then
			tooltip:addDesc( SPECIAL_INFO_COLOUR.. STRINGS.UI.TOOLTIPS.STACKABLE .."</>")
		else
			tooltip:addDesc( SPECIAL_INFO_COLOUR.. STRINGS.UI.TOOLTIPS.NOT_STACKABLE .."</>")
		end
	end

    local canUseAnyItem = false

    if userUnit and userUnit:getTraits() and userUnit:getTraits().useAnyItem then 
		canUseAnyItem= true
	end


	if unit:getRequirements() and userUnit then
		for skill,level in pairs( unit:getRequirements() ) do
            if not userUnit:hasSkill( skill, level ) and not canUseAnyItem then
            	local skilldefs = include( "sim/skilldefs" )
            	local skillDef = skilldefs.lookupSkill( skill )            	
			    tooltip:addRequirement( string.format( STRINGS.UI.TOOLTIP_REQUIRES_SKILL_LVL, util.toupper(skillDef.name), level ))
            else
            	local skilldefs = include( "sim/skilldefs" )
            	local skillDef = skilldefs.lookupSkill( skill )            	
			    tooltip:addLine( string.format( STRINGS.UI.TOOLTIP_REQUIRES_SKILL_LVL, util.toupper(skillDef.name), level ))             	
            end
        end
	end

    if unit:getTraits().installed and unit:getTraits().installed == false then		
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.INSTALL, STRINGS.ITEMS.TOOLTIPS.INSTALL_DESC, "gui/icons/arrow_small.png" )
	end


    if unit:getTraits().pickupOnly then
        tooltip:addDesc( util.sformat(STRINGS.UI.TOOLTIPS.PICK_UP_CONDITION_DESC, util.toupper(unit:getTraits().pickupOnly) ) )
    end	
end


local corpse_template =
{
	type = "simunit",
	name = "Corpse",
	onWorldTooltip = function( tooltip, unit )
		tooltip:addLine( unit:getName() )
		if unit:getInventoryCount() > 0 then
			tooltip:addAbility( STRINGS.UI.ACTIONS.LOOT_CORPSE.NAME, STRINGS.UI.ACTIONS.LOOT_CORPSE.TOOLTIP, "gui/icons/arrow_small.png" )
		end
	    if unit:getTraits().neural_scanned then
			tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.NEURAL_SCANNED ), string.format( STRINGS.UI.TOOLTIPS.NEURAL_SCANNED_DESC), "gui/icons/arrow_small.png" )
	    end    		
	end,
	kanim = "", -- Generated dynamically

	traits = { iscorpse=true, sightable=true, hidesInCover=true, interestSource=true },

	rig = "corpserig",
}

local basic_agent_traits =
{
	isAgent = true,
	hasSight = true, sightable = true,
	dynamicImpass = true,
	hasHearing = true,
	apMax = 1, 
	mpMax=8,
	mp=8,	
	ap = 1,
	silencer = true,
	meleeDamage = 0,
	maxThrow = 10,

	inventoryMaxSize = 3,
	augmentMaxSize = 0,

	skillsInjected = false,  

	corpseTemplate = corpse_template,
	
	canBeShot = true,
	canBeCritical = true,
	canKO = true,

	baseDamage = 0, 

	wounds = 0,	
	woundsMax = 1,

	hits = "blood",
	
	dashSoundRange = 5,
 
	isAiming=false, 
	selectpriority = 1,	
	sneaking = false,

	dragCostMod = 0,
}

local basic_guard_traits = util.extend( basic_agent_traits )
{
	canBeCritical = false,
	woundsMax = 1, 
	isGuard = true,
    cleanup = true, 	
	cashOnHand = 80,
	LOSrange = 8,
	LOSarc = math.pi / 4,
	LOSperipheralRange = 10,
	LOSperipheralArc = math.pi / 2,
	closedoors = true,

	patrolObserved = nil, 
	observablePatrol = true,
	noLoopOverwatch = true,
}

local basic_robot_traits =
{
	isAgent = true,
	isDrone = true,
	isMetal = true,
	sightable = true,
	hasSight = true,
	hasHearing = false,
	dynamicImpass = true,
	isGuard = true,
	noDoorAnim = true, 

	LOSrange = 8,
	LOSarc = math.pi / 2,

	notDraggable = true, 

	patrolObserved = nil, 
	observablePatrol = true,

	apMax = 1, 
	mpMax= 6,
	mp= 6,
	ap = 1, 
	wounds = 0,	
	woundsMax = 1,
	meleeDamage = 3,
	dashSoundRange = 6,

	mainframe_item = true,
    mainframe_ice = 1,
    mainframe_iceMax = 1,
	mainframe_status = "active",
    mainframe_no_recapture = true,
	
    corpseTemplate = corpse_template,
	
	canBeShot = true,
    canBeFriendlyShot = true,
	canBeCritical = false,
	canKO = false,
    empKO = 4, -- 4 ticks KO when EMP'd.
	
	baseDamage = 0, 

	controlTimer = 0, 
	controlTimerMax = 1, 

	hits = "spark",
	
	thoughtVis = nil,
 
	cleanup = true, 
	isAiming=false, 
	selectpriority = 1,	
	sneaking = false,

	walk=true,
	enforcer = false,
	noLoopOverwatch = true,
}

local DEFAULT_AGENT_ABILITIES = { "shootOverwatch", "jackin", "overwatch", "peek", "escape", "melee", "disarmtrap", "overwatchMelee" , "meleeOverwatch", "observePath", "moveBody", "lastWords"  }
local DEFAULT_AGENT_SKILLS = {"stealth", "hacking", "inventory", "anarchy" }
local DEFAULT_AGENT_TRAITS = util.extend( basic_agent_traits )
{
	seesHidden = true,
	sneaking = true,
	hidesInCover = true,
	calcAutoFacing = true,
	LOSarc = math.pi * 2,
	selectpriority = 10,
	ap=1,
	apMax = 1,
	inventoryMaxSize = 3,
	augmentMaxSize = 2,
	home_panel = true
}

local item_template = 
{
    type = "simunit",
	traits = { selectpriority = 0 },
    onWorldTooltip = onItemWorldTooltip,
    onTooltip = onItemTooltip,
}

local weapon_template = util.extend(item_template)
{
	traits =
	{
		equipped = false,
		slot = "gun"
	},
	abilities = { "carryable", "shootSingle", "equippable" },
	onTooltip = function( tooltip, unit, userUnit )
        onItemTooltip( tooltip, unit, userUnit )

--		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.AIM, STRINGS.ITEMS.TOOLTIPS.AIM_DESC, "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )
		local sim = unit._sim 
		local armorPiercing = unit:getTraits().armorPiercing or 0
		local damage = unit:getTraits().baseDamage or 0

		if unit:getTraits().ignoreArmor then
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.IGNORES_ARMOR, STRINGS.ITEMS.TOOLTIPS.IGNORES_ARMOR_DESC, "gui/icons/arrow_small.png" )
		else
			if armorPiercing > 0 then
				tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.ARMOR_PIERCING, string.format(STRINGS.ITEMS.TOOLTIPS.ARMOR_PIERCING_DESC, armorPiercing), "gui/icons/arrow_small.png" )
			else			
				tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.ARMOR_PIERCING_NONE, STRINGS.ITEMS.TOOLTIPS.ARMOR_PIERCING_NONE_DESC, "gui/icons/arrow_small.png" )
			end
		end

		if damage > 0 and unit:getTraits().canSleep then
			tooltip:addAbility(  STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE, util.sformat(STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE_DESC, damage), "gui/icons/arrow_small.png" )
		end

		if unit:getTraits().canTag then
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.CANTAG, string.format(STRINGS.ITEMS.TOOLTIPS.CANTAG_DESC), "gui/icons/arrow_small.png" )
		end	
	end,
	createUpgradeParams = function( self, unit )
        local params = { traits = { autoEquip = (unit:getTraits().equipped == true) } }
		if not unit:getTraits().energyWeapon then 
			params.traits.ammo = unit:getTraits().ammo
		end
        return params
	end,
}

local weapon_reloadable_template = util.extend(weapon_template){}
table.insert( weapon_reloadable_template.abilities, "reload" )

local melee_template = util.extend(item_template)
{
	traits = { slot = "melee" },
	abilities = { "carryable", "recharge", "equippable" },

	onTooltip = function( tooltip, unit, userUnit )
        onItemTooltip( tooltip, unit, userUnit )

        local simquery = include( "sim/simquery" )
		local armorPiercing = unit:getTraits().armorPiercing or 0
		local damage = simquery.calculateMeleeDamage( unit:getSim(), unit )
		
		if unit:getTraits().drainsAllPWR then 
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.MASS_PWR_DRAIN, string.format(STRINGS.ITEMS.TOOLTIPS.MASS_PWR_DRAIN_DESC, armorPiercing), "gui/icons/arrow_small.png" )
		end 
				
		if armorPiercing > 0 then
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.ARMOR_PIERCING, string.format(STRINGS.ITEMS.TOOLTIPS.ARMOR_PIERCING_DESC, armorPiercing), "gui/icons/arrow_small.png" )
		end

		if unit:getTraits().armorPWRcost  then
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.ARMOR_PWR_COST, string.format(STRINGS.ITEMS.TOOLTIPS.ARMOR_PWR_COST_DESC, unit:getTraits().armorPWRcost), "gui/icons/arrow_small.png" )
		end

		if damage > 0 then
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE, util.sformat(STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE_DESC, damage), "gui/icons/arrow_small.png" )
		end	

		if userUnit and userUnit:getTraits().tempMeleeBoost and  userUnit:getTraits().tempMeleeBoost > 0 then
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.MELEE_BOOST, util.sformat(STRINGS.ITEMS.TOOLTIPS.MELEE_BOOST_DESC, userUnit:getTraits().tempMeleeBoost ), "gui/icons/arrow_small.png" )
		end			
	end,
	createUpgradeParams = function( self, unit )
        return { traits = { autoEquip = (unit:getTraits().equipped == true) } }
	end,
}

local grenade_template = util.extend(item_template)
{
	type = "simgrenade",
	rig = "grenaderig",
	traits = {disposable = true},
	abilities = { "carryable", "throw" },

	onTooltip = function( tooltip, unit, userUnit )
        onItemTooltip( tooltip, unit, userUnit )

		local damage = unit:getTraits().damage or 0

		if damage > 0 then
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE, util.sformat(STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE_DESC, damage), "gui/icons/arrow_small.png" )
		end
	end
}

local npc_weapon_template =
{
	type = "simunit",
	traits =
	{
		slot = "gun",
	},
	abilities = { "shootSingle", "equippable" },
	value = 1,
}

local npc_grenade_template = 
{
	type = "simgrenade",
	rig = "grenaderig",
	traits =
	{
		slot = "grenade",
		shouldNpcThrow = true,
	},
	abilities = { "throw" },
	value = 1,
}

local DEFAULT_AUGMENT_TRAITS = {augment = true, installed = false, }
 
local augment_template = 
{
	type = "simunit", 
	traits = DEFAULT_AUGMENT_TRAITS,
    onWorldTooltip = onItemWorldTooltip,
	onTooltip = onItemTooltip,
	abilities = { "carryable", "installAugment" }, 
	icon = "itemrigs/FloorProp_AmmoClip.png",
	profile_icon = "gui/icons/item_icons/icon-item_augment2.png",
    profile_icon_100 = "gui/icons/item_icons/icon-item_augment2.png",

	createUpgradeParams = function( self, unit )
		return { traits = { installed = unit:getTraits().installed, augment=true } } 
	end,
	value = 650, 
}

local SOUNDS = {
	GUARD = { 		appeared="SpySociety/HUD/gameplay/peek_negative", 
					alert ="SpySociety/Actions/guard/guard_alerted", 
					speech="SpySociety/Agents/dialogue_KO", 
					stealthstep = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL, 
					step = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL,

					getup = "SpySociety/Movement/foley_guard/getup",
					fall = "SpySociety/Movement/foley_guard/fall",
					fall_knee = "SpySociety/Movement/bodyfall_agent_knee_hardwood",
					fall_kneeframe = 9,
					fall_hand = "SpySociety/Movement/bodyfall_agent_hand_hardwood",
					fall_handframe = 20,
					land = "SpySociety/Movement/deathfall_agent_hardwood",
					land_frame = 34,					
					grabbed = "SpySociety/Movement/foley_guard/grabbed",
					pin = "SpySociety/Movement/foley_guard/pin_guard",
					pinned = "SpySociety/Movement/foley_guard/pinned",
					move ="SpySociety/Movement/foley_guard/move",
					hit = "SpySociety/HitResponse/hitby_ballistic_flesh",	
					
					die = "die",
					hurt_small = "SpySociety/Agents/<voice>/hurt_small",	
					hurt_large = "SpySociety/Agents/<voice>/hurt_large",	
				},
	ARMORED = { 	appeared="SpySociety/HUD/gameplay/peek_negative",  
					alert ="SpySociety/Actions/guard/guard_alerted", 
					speech="SpySociety/Agents/dialogue_KO" , 
					stealthstep = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL, 
					step = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL,

					getup = "SpySociety/Movement/foley_armoured/getup",
					fall = "SpySociety/Movement/foley_armoured/fall",
					fall_knee = "SpySociety/Movement/bodyfall_agent_knee_hardwood",
					fall_kneeframe = 9,
					fall_hand = "SpySociety/Movement/bodyfall_agent_hand_hardwood",
					fall_handframe = 20,	
					land = "SpySociety/Movement/deathfall_agent_hardwood",
					land_frame = 34,					
					grabbed = "SpySociety/Movement/foley_armoured/grabbed",
					pin = "SpySociety/Movement/foley_armoured/pin_guard",
					pinned = "SpySociety/Movement/foley_armoured/pinned",
					move ="SpySociety/Movement/foley_armoured/move",
					hit = "SpySociety/HitResponse/hitby_ballistic_flesh",

					die = "die",
					hurt_small = "SpySociety/Agents/<voice>/hurt_small",	
					hurt_large = "SpySociety/Agents/<voice>/hurt_large",	
				},
	HEAVY = { 		appeared="SpySociety/HUD/gameplay/peek_negative", 
					alert ="SpySociety/Actions/guard/guard_alerted", 
					speech="SpySociety/Agents/dialogue_KO", 
					stealthstep = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL, 
					step = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL,

					getup = "SpySociety/Movement/foley_heavy/getup",
					fall = "SpySociety/Movement/foley_heavy/fall",
					fall_knee = "SpySociety/Movement/bodyfall_agent_knee_hardwood",
					fall_kneeframe = 9,
					fall_hand = "SpySociety/Movement/bodyfall_agent_hand_hardwood",
					fall_handframe = 20,
					land = "SpySociety/Movement/deathfall_agent_hardwood",
					land_frame = 34,
					grabbed = "SpySociety/Movement/foley_heavy/grabbed",
					pin = "SpySociety/Movement/foley_heavy/pin_guard",
					pinned = "SpySociety/Movement/foley_heavy/pinned",
					move ="SpySociety/Movement/foley_heavy/move",
					hit = "SpySociety/HitResponse/hitby_ballistic_flesh",

					die = "die",
					hurt_small = "SpySociety/Agents/<voice>/hurt_small",	
					hurt_large = "SpySociety/Agents/<voice>/hurt_large",	
				},
	DRONE = { 		appeared="SpySociety/HUD/gameplay/peek_negative", 
					
					alert ="SpySociety/Actions/guard/guard_alerted", 
					--stealthstep = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL, 
					--step = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL,
					move_loop = "SpySociety/Objects/drone/drone_move_LP",
					reboot_end="SpySociety/Agents/Drone/Agitated/Wakeup",
					scan="SpySociety/Actions/Engineer/wireless_emitter",
					hit = "SpySociety/HitResponse/hitby_ballistic_metal",
					explode2 = "SpySociety/Objects/drone/drone_shutdown",
					explode2_frame =1,
				},		
	DRONE_WALK = { 	appeared="SpySociety/HUD/gameplay/peek_negative", 
					alert ="SpySociety/Actions/guard/guard_alerted", 
					stealthstep = simdefs.SOUNDPATH_FOOTSTEP_DRONE_HARDWOOD_NORMAL, 
					step = simdefs.SOUNDPATH_FOOTSTEP_DRONE_HARDWOOD_NORMAL,
					getup = "SpySociety/Movement/foley_walkingdrone/getup",
					fall = "SpySociety/Movement/foley_walkingdrone/fall",
					land = "SpySociety/Objects/drone/drone_hitground",
					land_frame = 9,					
					grabbed = "SpySociety/Movement/foley_walkingdrone/grabbed",
					pin = "SpySociety/Movement/foley_walkingdrone/pin_guard",
					pinned = "SpySociety/Movement/foley_walkingdrone/pinned",
					move ="SpySociety/Movement/foley_walkingdrone/move",
					reboot_end="SpySociety/Agents/Drone/Agitated/Wakeup",					
					scan="SpySociety/Actions/Engineer/wireless_emitter",
					hit = "SpySociety/HitResponse/hitby_ballistic_metal",
					explode = "SpySociety/Objects/drone/drone_explo",					
					explode_frame = 1,
					open = "SpySociety/Objects/drone/drone_open",
					open_frame = 12,
					close = "SpySociety/Objects/drone/drone_close",
					close_frame = 10,
					walk_pre = "SpySociety/Objects/drone/drone_close",
					walk_pst = "SpySociety/Objects/drone/drone_open",
					run_pst = "SpySociety/Objects/drone/drone_open",
					snk_pst = "SpySociety/Objects/drone/drone_open",

				},	
	DRONE_HOVER = { appeared="SpySociety/HUD/gameplay/peek_negative", 
					getko = "SpySociety/Objects/drone/drone_sleep",
					alert ="SpySociety/Actions/guard/guard_alerted", 
					--stealthstep = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL, 
					--step = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL,
					spot = "SpySociety/Objects/drone/drone_hover_LP",	

					move_loop_param = "move",		
					fall = "SpySociety/Objects/drone/drone_shutdown",
					land = "SpySociety/Objects/drone/drone_hitground",
					land_frame = 13,
					drop = "SpySociety/Objects/drone/drone_hitground",
					drop_frame = 11,	
					reboot_end="SpySociety/Agents/Drone/Agitated/Wakeup",						
					scan="SpySociety/Actions/Engineer/wireless_emitter",
					hit = "SpySociety/HitResponse/hitby_ballistic_metal",
					explode = "SpySociety/Objects/drone/drone_explo",
					explode_frame = 1,					
				},
	DRONE_HOVER_HEAVY = { appeared="SpySociety/HUD/gameplay/peek_negative", 
					getko = "SpySociety/Objects/drone/drone_sleep",
					
					alert ="SpySociety/Actions/guard/guard_alerted", 
					--stealthstep = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL, 
					--step = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL,
					spot = "SpySociety/Objects/drone/drone_hover_large_LP",	
					move_loop_param = "move",
					fall = "SpySociety/Objects/drone/drone_shutdown",
					land = "SpySociety/Objects/drone/drone_hitground",
					land_frame = 24,
					drop = "SpySociety/Objects/drone/drone_hitground",
					drop_frame = 15,					
					burst={{sound="SpySociety/Weapons/Precise/shoot_turret",soundFrames=1},{sound="SpySociety/Weapons/Precise/shoot_turret",soundFrames=5},{sound="SpySociety/Weapons/Precise/shoot_turret",soundFrames=6},{sound="SpySociety/Weapons/Precise/shoot_turret",soundFrames=7},{sound="SpySociety/Weapons/Precise/shoot_turret",soundFrames=8}},
					overwatch_pre = "SpySociety/Objects/drone/drone_gun_large_open",
					overwatch_pst = "SpySociety/Objects/drone/drone_gun_large_close",
					reboot_end="SpySociety/Agents/Drone/Agitated/Wakeup",		
					scan="SpySociety/Actions/Engineer/wireless_emitter",
					hit = "SpySociety/HitResponse/hitby_ballistic_metal",
					explode = "SpySociety/Objects/drone/drone_explo",
					explode_frame = 1,					
				},
}

local DEFAULT_IDLES =
{
	{
		pre="smoke_pre", idle="smoke_idle", action="smoke", pst="smoke_pst",
		sounds={{event="inhale", sound="SpySociety/Actions/guard/smoke_inhale"}, {event="exhale", sound="SpySociety/Actions/guard/smoke_exhale"}},
		idleCounts={min=8, max=15}
	},
	{
		pre="phone_pre", idle="phone_idle", action="phone", pst="phone_pst",
		sounds={{event="buzz", sound="SpySociety/Actions/guard/play_with_phone"}},
		idleCounts={min=8, max=15}
	},
}

local DEFAULT_ABILITIES = { "shootOverwatch", "overwatch", "breakDoor" }

local function onGuardTooltip( tooltip, unit )
	onAgentTooltip( tooltip, unit )

    local traits = unit:getTraits()

    if traits.isSupportGuard then 
    	tooltip:addAbility( STRINGS.UI.TOOLTIPS.GRENADE_GUARD, STRINGS.UI.TOOLTIPS.GRENADE_GUARD_DESC,  "gui/icons/arrow_small.png" )
    end 

    if traits.mainframe_suppress_rangeMax then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.NULL_ZONE ), util.sformat( STRINGS.UI.TOOLTIPS.NULL_ZONE_DESC, traits.mainframe_suppress_rangeMax ), "gui/icons/arrow_small.png" )
    end     

    if traits.isDrone then
	    tooltip:addAbility( STRINGS.UI.TOOLTIPS.CONTROLLABLE, STRINGS.UI.TOOLTIPS.CONTROLLABLE_DESC,  "gui/icons/arrow_small.png"  )				
    end

    if not traits.hasHearing then
	    tooltip:addAbility( STRINGS.UI.TOOLTIPS.NO_HEARING, STRINGS.UI.TOOLTIPS.NO_HEARING_DESC,  "gui/icons/arrow_small.png"  )				
    end
    if not traits.canKO then
	    tooltip:addAbility( STRINGS.UI.TOOLTIPS.KO_IMMUNE, STRINGS.UI.TOOLTIPS.KO_IMMUNE_DESC,  "gui/icons/arrow_small.png"  )									
    end
    if traits.heartMonitor == "enabled" then
        tooltip:addAbility( STRINGS.UI.TOOLTIPS.HEART_MONITOR, STRINGS.UI.TOOLTIPS.HEART_MONITOR_DESC, "gui/icons/item_icons/items_icon_small/icon-item_heart_monitor_small.png" )		
    end
    if traits.shieldArmor then
		tooltip:addAbility( STRINGS.UI.TOOLTIPS.BARRIER, STRINGS.UI.TOOLTIPS.BARRIER_DESC, "gui/icons/item_icons/items_icon_small/icon-item_personal_shield_small.png" )
    elseif traits.armor and traits.armor > 0 then
        tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.HEAVY_ARMOR, traits.armor ), STRINGS.UI.TOOLTIPS.HEAVY_ARMOR_DESC,  "gui/hud3/hud3_armor_tutorial_icon.png"  )
    end
    if traits.resistKO then
        tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.KO_RESISTANT, traits.resistKO ), STRINGS.UI.TOOLTIPS.KO_RESISTANT_DESC,  "gui/icons/arrow_small.png"  )
    end
    if (traits.LOSarc or 0) > (math.pi / 2) then
    	if traits.LOSarc <= math.pi then 
        	tooltip:addAbility( STRINGS.UI.TOOLTIPS.PERIPHERAL_BOOST, STRINGS.UI.TOOLTIPS.PERIPHERAL_BOOST_DESC,  "gui/icons/arrow_small.png"  )
        end 
    end
    if traits.neutralize_shield then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.PROTECTIVE_SHIELDS, traits.neutralize_shield),  STRINGS.UI.TOOLTIPS.PROTECTIVE_SHIELDS_DESC, "gui/icons/item_icons/items_icon_small/icon-item_personal_shield_small.png",nil,true )
    end
	if traits.empDeath then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.EMP_VULNERABLE ), STRINGS.UI.TOOLTIPS.EMP_VULNERABLE_DESC, "gui/icons/arrow_small.png",nil,true )
    end 

    if traits.mainframeRecapture then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.COUNTER_HACK ), util.sformat( STRINGS.UI.TOOLTIPS.COUNTER_HACK_DESC, traits.mainframeRecapture), "gui/icons/arrow_small.png" )
    end 
    if traits.koDaemon then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.KO_DEAMON ), string.format( STRINGS.UI.TOOLTIPS.KO_DEAMON_DESC), "gui/icons/arrow_small.png" )
    end 

    if traits.lookaroundRange and not traits.no_look_around then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.DRONE_SCAN ), string.format( STRINGS.UI.TOOLTIPS.DRONE_SCAN_DESC), "gui/icons/arrow_small.png" )
    end     

    if traits.magnetic_reinforcement then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.MAGNETIC_REINFOREMENTS ), string.format( STRINGS.UI.TOOLTIPS.MAGNETIC_REINFOREMENTS_DESC), "gui/icons/arrow_small.png" )
    end     

    local abilities = unit:getAbilities()

    for i, ability in ipairs( abilities ) do 
    	if ability.buffAbility then 
    		tooltip:addAbility( string.format( ability.name ), string.format( ability.buffDesc ), "gui/icons/arrow_small.png" )
    	end 
    end    

    --NEW TOOLTIPS
    if traits.neural_scanned then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.NEURAL_SCANNED ), string.format( STRINGS.UI.TOOLTIPS.NEURAL_SCANNED_DESC), "gui/icons/arrow_small.png" )
    end
    if traits.pulseScan then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.PULSE_SCANNER ), util.sformat(STRINGS.UI.TOOLTIPS.PULSE_SCANNER_DESC,traits.range ), "gui/icons/arrow_small.png" )
    end  
    if traits.AOEFirewallsBuff then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.AOE_FIREWALL_BUFF ), util.sformat(  STRINGS.UI.TOOLTIPS.AOE_FIREWALL_BUFF_DESC,traits.AOEFirewallsBuffRange,traits.AOEFirewallsBuff ), "gui/icons/arrow_small.png" )
    end      
    if traits.noInterestDistraction then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.FOCUSED_AI ), util.sformat( STRINGS.UI.TOOLTIPS.FOCUSED_AI_DESC), "gui/icons/arrow_small.png" )
    end  
    if traits.buffArmorOnKO then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.KO_ARMOR_BUFF ), util.sformat( STRINGS.UI.TOOLTIPS.KO_ARMOR_BUFF_DESC,traits.buffArmorOnKO), "gui/icons/arrow_small.png" )
    end  

    if traits.searchedAnarchy5 then
    	tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.SEARCHED_ADVANCED ), util.sformat( STRINGS.UI.TOOLTIPS.SEARCHED_ADVANCED_DESC ), "gui/icons/arrow_small.png" )
    elseif traits.searched then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.SEARCHED ), util.sformat( STRINGS.UI.TOOLTIPS.SEARCHED_DESC ), "gui/icons/arrow_small.png" )
    end  

end

local DEFAULT_DRONE = 
{
	type = "simdrone",
	profile_icon = "gui/profile_icons/character-head-drone.png",
	onWorldTooltip = onGuardTooltip,
	kanim = "kanim_drone_SA",
	rig = "dronerig",
	traits =  util.extend( basic_robot_traits )
	{
		mainframe_no_daemon_spawn = true,
		PWROnHand = 2,
		lookaroundRange = 4,
	},   

	voices = {"Drone"},
	speech = speechdefs.NPC,
	skills = {},
	abilities = {  "shootOverwatch", "overwatch" },
	brain = "DroneBrain",
	children = {},	
}


-- FOR PROPDEFS

local MAINFRAME_TRAITS =
{
	mainframe_item = true,		-- if the item is used in the mainframe
	mainframe_icon = true,		-- does the item have an idle_icon state in mainframe mode (can be specified for non-mainframe items)
	mainframe_ice = 1,			-- current FIREWALL level
	mainframe_iceMax = 1,		-- max FIREWALL level
	mainframe_status = "active",		-- active, inactive or off 
}

local SAFE_TRAITS =
{
	cover = true,
	impass = {0,0},
	safeUnit = true,
	sightable = true,
	open = false,
}

local function onMainframeTooltip( tooltip, unit )
    if unit:getTraits().mainframe_status == "off" and unit:getTraits().mainframe_booting then
    	tooltip:addLine( "<ttheader>"..unit:getName().."</>", string.format( STRINGS.UI.TOOLTIPS.MAINFRAME_REBOOT, unit:getTraits().mainframe_booting ))
    else
    	if unit:getTraits().mainrame_status == "inactive" then 
    		tooltip:addLine( "<ttheader>"..unit:getName().."</>", STRINGS.UI.TOOLTIPS.MAINFRAME_INACTIVE )
    	elseif unit:getTraits().mainframe_status == "active" then  
    		tooltip:addLine( "<ttheader>"..unit:getName().."</>", STRINGS.UI.TOOLTIPS.MAINFRAME_ACTIVE )
    	else 
    		tooltip:addLine( "<ttheader>"..unit:getName().."</>", STRINGS.UI.TOOLTIPS.MAINFRAME_OFF )
    	end
    end

    if unit:getTraits().powerGridName then
        tooltip:addAbility( string.format(STRINGS.UI.TOOLTIPS.MAINFRAME_GRID, unit:getTraits().powerGridName ),
                            string.format(STRINGS.UI.TOOLTIPS.MAINFRAME_LINKED_TO_POWER_GRID, unit:getTraits().powerGridName ) )
    end

    local txt = STRINGS.UI.TOOLTIP_HACK_MAINFRAME_DEVICE
	local icon ="gui/hud3/hud3_incognita_LG.png"
	if unit:isPC() then
		txt = STRINGS.UI.TOOLTIP_HACK_MAINFRAME_DEVICE_CAPTURED 
	end
	if unit:getTraits().revealUnits then
		if unit:getTraits().revealUnits ==  "mainframe_camera" then
			txt = STRINGS.UI.TOOLTIP_HACK_CAMERA_DB
		elseif unit:getTraits().revealUnits == "mainframe_console" then
			txt = STRINGS.UI.TOOLTIP_HACK_CONSOLE_DB
		elseif unit:getTraits().revealUnits == "mainframe_guard"  then
			txt = STRINGS.UI.TOOLTIP_HACK_GUARD_DB
		end	
	end
	if unit:getTraits().showOutline then
		txt = STRINGS.UI.TOOLTIP_HACK_MAP_DB
		icon ="gui/hud3/hud3_incognita_LG.png"	
	end	
	if unit:getTraits().revealDaemons then
		txt = STRINGS.UI.TOOLTIP_HACK_DAEMON_DB
		icon ="gui/hud3/hud3_incognita_LG.png"		
	end		
	if (unit:getTraits().mainframe_iceMax or 0) > 0  then
		if not unit:getTraits().dead then
			if not unit:isPC() then
				tooltip:addAbility(STRINGS.UI.TOOLTIP_HACK_WITH_INCOGNITA, txt, icon)											 
			else
				tooltip:addAbility(STRINGS.UI.TOOLTIP_HACKED, txt, icon)			
			end
		end
	end	


 
	if unit:getTraits().mainframe_status == "off" and not unit:getTraits().mainframe_booting and unit:getTraits().mainframe_camera and not unit:getTraits().dead then
		tooltip:addAbility(STRINGS.UI.TOOLTIP_INACTIVE, STRINGS.UI.TOOLTIP_INACTIVE_DESC, "gui/icons/arrow_small.png")					
	end	

	if unit:getTraits().dead then
		tooltip:addAbility(STRINGS.UI.TOOLTIP_DESTROYED, STRINGS.UI.TOOLTIP_DESTROYED_DESC, "gui/icons/arrow_small.png")					
	end	

--operatable_device

	if unit:getTraits().scanner then
		local txt = STRINGS.UI.TOOLTIP_SCANNER_DESC
		local icon ="gui/icons/item_icons/items_icon_small/icon-item_scanner_small.png"		
		tooltip:addAbility(STRINGS.UI.TOOLTIP_SCANNER, txt, icon)	
	end	

    if unit:getTraits().magnetic_reinforcement then
		tooltip:addAbility( string.format( STRINGS.UI.TOOLTIPS.MAGNETIC_REINFOREMENTS ), string.format( STRINGS.UI.TOOLTIPS.MAGNETIC_REINFOREMENTS_DESC), "gui/icons/arrow_small.png" )
    end     
end

local function onSoundBugTooltip( tooltip, unit)
	onMainframeTooltip( tooltip, unit )
	
	if unit:getTraits().toolTipNote then
		tooltip:addDesc(unit:getTraits().toolTipNote)
	end
end

local function onBeamTooltip( tooltip, unit)
	tooltip:addLine( unit:getName() )	
	if unit:getTraits().toolTipNote then
		tooltip:addDesc(unit:getTraits().toolTipNote)
	end
end

local function onConsoleTooltip( tooltip, unit, hud )
	tooltip:addLine( unit:getName() )

    if (unit:getTraits().cpus or 0) > 0 then
        local selectedUnit = hud:getSelectedUnit()
        if selectedUnit then
            local ability = selectedUnit:hasAbility( "jackin" )
            if ability then
				tooltip:addAbility( ability:getName( unit:getSim(), selectedUnit, selectedUnit, unit:getID()),
					STRINGS.ABILITIES.HIJACK_CONSOLE_DESC, "gui/items/icon-action_hack-console.png" )
            end
	    end
    end
end

local function onStoreTooltip( tooltip, unit )
    onMainframeTooltip( tooltip, unit )
	tooltip:addAbility( STRINGS.UI.TOOLTIPS.SHOP,  STRINGS.UI.TOOLTIPS.SHOP_DESC, "gui/items/icon-action_open-safe.png" )
end

local function onDeviceTooltip( tooltip, unit )
    onMainframeTooltip( tooltip, unit )	
	if unit:isPC() then
		tooltip:addAbility( STRINGS.UI.ACTIONS.OPERATE_DEVICE.NAME, STRINGS.UI.ACTIONS.OPERATE_DEVICE.TOOLTIP_NOFIREWALLS, "gui/items/icon-action_open-safe.png" )
	else
		tooltip:addAbility( STRINGS.UI.ACTIONS.OPERATE_DEVICE.NAME, STRINGS.UI.ACTIONS.OPERATE_DEVICE.TOOLTIP, "gui/items/icon-action_open-safe.png" )
	end	
end

local function onSafeTooltip( tooltip, unit )
    onMainframeTooltip( tooltip, unit )	
	if unit:isPC() then
		tooltip:addAbility( STRINGS.UI.ACTIONS.SEARCH_SAFE.NAME, STRINGS.UI.ACTIONS.SEARCH_SAFE.TOOLTIP_NOFIREWALLS, "gui/items/icon-action_open-safe.png" )
	else
		tooltip:addAbility( STRINGS.UI.ACTIONS.SEARCH_SAFE.NAME, STRINGS.UI.ACTIONS.SEARCH_SAFE.TOOLTIP, "gui/items/icon-action_open-safe.png" )
	end	
	if unit:getTraits().emp_safe then
		tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.EMP_SAFE, STRINGS.ITEMS.TOOLTIPS.EMP_SAFE_DESC, "gui/items/icon-action_open-safe.png" )
	end
end



return 
{
	MAINFRAME_TRAITS = MAINFRAME_TRAITS,
	SAFE_TRAITS =SAFE_TRAITS,
	onMainframeTooltip = onMainframeTooltip,
	onSoundBugTooltip = onSoundBugTooltip,
	onBeamTooltip = onBeamTooltip,
	onConsoleTooltip = onConsoleTooltip,
	onStoreTooltip = onStoreTooltip,
	onDeviceTooltip = onDeviceTooltip,
	onSafeTooltip = onSafeTooltip,

	SOUNDS = SOUNDS,
	DEFAULT_IDLES = DEFAULT_IDLES,
	DEFAULT_ABILITIES = DEFAULT_ABILITIES,
	onGuardTooltip = onGuardTooltip,
	DEFAULT_DRONE = DEFAULT_DRONE,


	AGENT_ANIMS = AGENT_ANIMS,
	GUARD_ANIMS = GUARD_ANIMS,
	HOSTAGE_ANIMS = HOSTAGE_ANIMS,
    DRONE_ANIMS = DRONE_ANIMS,
    FLOAT_DRONE_ANIMS = FLOAT_DRONE_ANIMS,
    FLOAT_DRONE_TANK_ANIMS = FLOAT_DRONE_TANK_ANIMS,
    Layer = Layer,
    BoundType = BoundType,

	corpse_template = corpse_template,
	basic_agent_traits = basic_agent_traits,
	basic_guard_traits = basic_guard_traits,
	basic_robot_traits = basic_robot_traits,
	onAgentTooltip = onAgentTooltip,
    onItemTooltip = onItemTooltip,
    onItemWorldTooltip = onItemWorldTooltip,
    DEFAULT_AGENT_ABILITIES = DEFAULT_AGENT_ABILITIES,
    DEFAULT_AGENT_SKILLS = DEFAULT_AGENT_SKILLS,
    DEFAULT_AGENT_TRAITS = DEFAULT_AGENT_TRAITS,
    -- itemdefs
    DEFAULT_AUGMENT_TRAITS = DEFAULT_AUGMENT_TRAITS,
    augment_template = augment_template,
    grenade_template = grenade_template,
    npc_grenade_template = npc_grenade_template,
    npc_weapon_template = npc_weapon_template,
    melee_template = melee_template,
    weapon_template = weapon_template,
    weapon_reloadable_template = weapon_reloadable_template,
    item_template = item_template,
}
	





