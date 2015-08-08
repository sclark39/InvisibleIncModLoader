----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local unitdefs = include( "sim/unitdefs" )
local simunit = include( "sim/simunit" )
local mainframe_abilities = include( "sim/abilities/mainframe_abilities" )

-----------------------------------------------------
-- 

local function createProgramUnitData( abilityName, sim )
    local abilityDef = mainframe_abilities[ abilityName ]

	assert( abilityDef )
    assert( sim )

    if sim:isVersion("0.17.5") then
    	if abilityDef.abilityOverride then
			abilityDef =  mainframe_abilities[abilityDef.abilityOverride]
		end
	end
	

    return
	{
		type = "simunit", 
		name = abilityDef.name,
		program = true,
		traits = 
		{
			mainframe_program = abilityName, 
		},
		onTooltip = function( tooltip, unit )
			-- FIXME: should delegate to ability, but the parameters are different! (No hud access here)
			tooltip:addLine( abilityDef.name, util.sformat( STRINGS.PROPS.STORE_PROGRAM_TOOLTIP, abilityDef:getCpuCost() ))
			tooltip:addAbility( abilityDef.shortdesc, abilityDef.desc, "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )
        end,

		profile_icon_100 = abilityDef.icon_100,
		value = abilityDef.value
	}
end


local function createStoreItems( store, storeUnit, sim )
	local soldItems = {}
	local soldWeapons = {}
	local soldAugments = {}

	-- These are the potentially added units
	local itemsList = util.tdupe( store.itemList )
	local weaponsList = util.tdupe( store.weaponList )
	local augmentsList = util.tdupe( store.augmentList )
		
	--Take out items that shouldn't be sold yet 
    local campaignHours = sim:getParams().campaignHours
    if campaignHours then
	    local i = 1
	    while i <= #itemsList do
		    local item = itemsList[i]
		    if item.soldAfter and campaignHours <= item.soldAfter then 
			    table.remove( itemsList, i )
		    elseif item.notSoldAfter and campaignHours > item.notSoldAfter then
			    table.remove( itemsList, i )
		    else 
			    i = i + 1
		    end
	    end	

	    local i = 1
	    while i <= #weaponsList do
		    local item = weaponsList[i]
		    if item.soldAfter and campaignHours <= item.soldAfter then 
			    table.remove( weaponsList, i )
		    elseif item.notSoldAfter and campaignHours > item.notSoldAfter then
			    table.remove( weaponsList, i )
		    else 
			    i = i + 1
		    end
	    end	

	    local i = 1
	    while i <= #augmentsList do
		    local item = augmentsList[i]
		    if item.soldAfter and campaignHours <= item.soldAfter then 
			    table.remove( augmentsList, i )
		    elseif item.notSoldAfter and campaignHours > item.notSoldAfter then
			    table.remove( augmentsList, i )
		    else 
			    i = i + 1
		    end
	    end	
    end

	-- Generate the actual shop items: First include all mandatory items.
	if not storeUnit:getTraits().noMandatoryItems then
		soldItems = util.tdupe( store.mandatoryList )
	end

	local maxWeight = 1
	local weightedItems = {}

	for i=1, #itemsList do 
		if itemsList[i].floorWeight then 
			local floorWeight = itemsList[i].floorWeight
			local floor = sim:getParams().difficulty
			local index = ( 4 - math.abs( math.min(floor, 4) - floorWeight ) ) ^ 5
			maxWeight = maxWeight + index 
			weightedItems[maxWeight] = itemsList[i] 
		end
	end

	local itemsLeft = math.max( store.storeType[storeUnit:getTraits().storeType].itemAmount - #soldItems, 0 )

	for i= 1, itemsLeft do 
		local rand = sim:nextRand(1, maxWeight)
		local item = nil 
		local recentKey = maxWeight+1

		for k,v in pairs(weightedItems) do
			if k >= rand then 
				if k < recentKey then
					item = v 
					recentKey = k 
				end 
			end
		end

		table.insert( soldItems, item )
	end

	local weaponsLeft = store.storeType[storeUnit:getTraits().storeType].weaponAmount
	for i= 1, weaponsLeft do 
		local rand = sim:nextRand(1, #weaponsList)
		table.insert( soldWeapons, weaponsList[rand] )
	end

	local augmentsLeft = store.storeType[storeUnit:getTraits().storeType].augmentAmount
	for i= 1, augmentsLeft do 
		local rand = sim:nextRand(1, #augmentsList)
		table.insert( soldAugments, augmentsList[rand] )
	end

	

	if store.progList then
		local progList = nil
		local progList1 = nil 
		local progList2 = nil
		if sim:getParams().campaignDifficulty == simdefs.NORMAL_DIFFICULTY then
			if store.storeType[storeUnit:getTraits().storeType].noBreakers then 
				progList1 = util.tcopy( store.beginner_breakers )
				progList2 = util.tcopy( store.beginner_nobreakers )
				if sim:isVersion("0.17.5") then
					progList1:addList( store.beginner_breakers_17_5 )
					progList2:addList( store.beginner_nobreakers_17_5 )					
				end
			else
				progList = util.tcopy( store.progList )
				if sim:isVersion("0.17.5") then
					progList:addList( store.progList_17_5 )		
				end				
			end 
		else 
			if store.storeType[storeUnit:getTraits().storeType].noBreakers then 
				progList = util.tcopy( store.noBreakerProgList )
				if sim:isVersion("0.17.5") then
					progList:addList( store.noBreakerProgList_17_5 )		
				end					
			else
				progList = util.tcopy( store.progList )
				if sim:isVersion("0.17.5") then
					progList:addList( store.progList_17_5 )		
				end					
			end 
		end 
		local programsLeft = store.storeType[storeUnit:getTraits().storeType].progAmount
		if progList1 and progList2 then 
			local alternate = true
	        while programsLeft > 0 do
	        	if alternate and progList1:getCount() > 0 then 
		            local w = sim:nextRand(1, progList1:getTotalWeight() )
		            local programName = progList1:removeChoice( w )
		            local programUnit = createProgramUnitData( programName, sim )
					table.insert( soldItems, programUnit )
		            programsLeft = programsLeft - 1
		            alternate = not alternate
		        elseif not alternate and progList2:getCount() > 0 then 
		        	local w = sim:nextRand(1, progList2:getTotalWeight() )
		            local programName = progList2:removeChoice( w )
		            local programUnit = createProgramUnitData( programName, sim )
					table.insert( soldItems, programUnit )
		            programsLeft = programsLeft - 1
		            alternate = not alternate
		        else
		        	programsLeft = 0
		        end
			end
		else 
			while programsLeft > 0 and progList:getCount() > 0 do				
	            local w = sim:nextRand(1, progList:getTotalWeight() )
	            local programName = progList:removeChoice( w )
	            local programUnit = createProgramUnitData( programName, sim )
				table.insert( soldItems, programUnit )
	            programsLeft = programsLeft - 1
			end
		end
	end

	-- Instantiate actual simunits for the shop items that are unit templates.
	for i, item in ipairs( soldItems ) do
		soldItems[i] = simfactory.createUnit( item, sim )
	end

	for i, item in ipairs( soldWeapons ) do
		soldWeapons[i] = simfactory.createUnit( item, sim )
	end

	for i, item in ipairs( soldAugments ) do
		soldAugments[i] = simfactory.createUnit( item, sim )
	end

	return soldItems, soldWeapons, soldAugments
end

local all_stores = 
{
	STORE_ITEM = {},
}

function ResetStoreItems()
	log:write("ResetStoreItems()")

	local DEFAULT_STORE_ITEM =
	{
		storeType = "item",

		mandatoryList = 
		{
			unitdefs.tool_templates.item_clip,
			unitdefs.tool_templates.item_adrenaline,
		},

		itemList =
		{
		
			unitdefs.tool_templates.item_adrenaline,
			unitdefs.tool_templates.item_clip,
			unitdefs.tool_templates.item_icebreaker,
			unitdefs.tool_templates.item_icebreaker_2,
			unitdefs.tool_templates.item_icebreaker_3,
			unitdefs.tool_templates.item_portabledrive,
			unitdefs.tool_templates.item_portabledrive_2, 
			unitdefs.tool_templates.item_portabledrive_3, 
			unitdefs.tool_templates.item_lockdecoder,
			unitdefs.tool_templates.item_shocktrap,
			unitdefs.tool_templates.item_shocktrap_2, 
			unitdefs.tool_templates.item_shocktrap_3, 
			unitdefs.tool_templates.item_laptop,
			unitdefs.tool_templates.item_laptop_2, 
			unitdefs.tool_templates.item_laptop_3,
			unitdefs.tool_templates.item_paralyzer,
			unitdefs.tool_templates.item_paralyzer_2, 
			unitdefs.tool_templates.item_paralyzer_3, 
			unitdefs.tool_templates.item_emp_pack,
			unitdefs.tool_templates.item_emp_pack_2, 
			unitdefs.tool_templates.item_emp_pack_3,
			unitdefs.tool_templates.item_cloakingrig_1,
			unitdefs.tool_templates.item_cloakingrig_2,
			unitdefs.tool_templates.item_cloakingrig_3,
			unitdefs.tool_templates.item_stim,
			unitdefs.tool_templates.item_stim_2,
			unitdefs.tool_templates.item_stim_3,	
			unitdefs.tool_templates.item_stickycam,
			unitdefs.tool_templates.item_hologrenade,
			unitdefs.tool_templates.item_smokegrenade,
            unitdefs.tool_templates.item_defiblance,
            unitdefs.tool_templates.item_econchip,
            unitdefs.tool_templates.item_scanchip,
		},
		weaponList = 
		{
			unitdefs.tool_templates.item_dartgun,
			unitdefs.tool_templates.item_dartgun_ammo, 
			unitdefs.tool_templates.item_dartgun_dam, 
			unitdefs.tool_templates.item_light_pistol,
			unitdefs.tool_templates.item_light_pistol_ammo, 
			unitdefs.tool_templates.item_light_pistol_dam,
			unitdefs.tool_templates.item_bio_dartgun,
			unitdefs.tool_templates.item_energy_pistol,
			unitdefs.tool_templates.item_tazer, 
			unitdefs.tool_templates.item_tazer_2, 
			unitdefs.tool_templates.item_tazer_3, 
			unitdefs.tool_templates.item_power_tazer_1,
			unitdefs.tool_templates.item_power_tazer_2,
			unitdefs.tool_templates.item_power_tazer_3,		
			unitdefs.tool_templates.item_tag_pistol,		
		},
		augmentList = 
		{
			unitdefs.tool_templates.augment_net_downlink, 
			unitdefs.tool_templates.augment_distributed_processing, 
			unitdefs.tool_templates.augment_torque_injectors,		
			unitdefs.tool_templates.augment_titanium_rods,
			unitdefs.tool_templates.augment_holocircuit_overloaders,
			unitdefs.tool_templates.augment_predictive_brawling,	
			unitdefs.tool_templates.augment_piercing_scanner,
			unitdefs.tool_templates.augment_penetration_scanner,
 			unitdefs.tool_templates.augment_chameleon_movement, 
			unitdefs.tool_templates.augment_anatomy_analysis, 
			unitdefs.tool_templates.augment_skeletal_suspension, 
			unitdefs.tool_templates.augment_subdermal_cloak, 
		},
		progList = util.weighted_list(
        {
			wrench_2 = 5,
			wrench_3 = 5,
			wrench_4 = 5,
			wrench_5 = 5,
			hammer = 20,
			parasite = 20,
			parasite_2 = 20,
			sniffer = 20,
			hunter = 20,
			dagger = 20,
			dagger_2 = 20,
			lockpick_1 = 20,
			lockpick_2 = 20,
			mainframePing = 20,
			oracle = 20,
			wings = 2,
			shade = 10,
			leash = 20,
			dataBlast = 20,
			rapier = 20,
			esp = 20,
			pwr_manager = 20,
			pwr_manager_2 = 5,
			taurus = 20,
			emergency_drip = 20,
			wildfire = 20, 
			brimstone = 20,
		}),		

		progList_17_5 = util.weighted_list(
		{
			lightning = 10,
			rogue = 20,
			fool = 10,
			flare = 20,
			overdrive = 20,
			charge = 20,
			root = 20,
		}),

		noBreakerProgList = util.weighted_list(
        {
			wrench_2 = 5,
			wrench_3 = 5,
			wrench_4 = 5,
			wrench_5 = 5,
			dagger = 10,
			parasite = 10,
			lockpick_1 = 10,
			lockpick_2 = 10,
			sniffer = 20,
			hunter = 20,
			mainframePing = 20,
			oracle = 20,
			wings = 1,
			shade = 1,
			leash = 20,
			dataBlast = 20,
			esp = 20,
			pwr_manager = 20,
			pwr_manager_2 = 5,
			taurus = 20,
			emergency_drip = 5,
			wildfire = 20, 
			brimstone = 5, 
			lockpick_2 = 10, 
		}),

		noBreakerProgList_17_5 = util.weighted_list(
		{
			lightning = 10,
			rogue = 20,
			overdrive = 20,
			charge = 20,
			root = 20,
		}),		

		beginner_breakers = util.weighted_list(
		{
			dagger = 10,
            dagger_2 = 10,
            wrench_3 = 10,
            parasite = 10,
            lockpick_2 = 10,
            dataBlast = 10,
            emergency_drip = 5,            
		}),

		beginner_breakers_17_5 = util.weighted_list(
		{
            flare = 10,                  
		}),

		beginner_nobreakers = util.weighted_list(
		{
			taurus = 20,
			wildfire = 20,
			pwr_manager = 20,
			pwr_manager_2 = 5, 
			esp = 20,
			sniffer = 20,
			hunter = 20,
			mainframePing = 20,
			oracle = 20,
			wings = 1,
			shade = 1,
			leash = 20,
		}),

		beginner_nobreakers_17_5 = util.weighted_list(
		{
			overdrive = 20,
			charge = 20,		
			lightning = 10,	
			rogue = 20,
		}),

		storeType = {
			large = {
				itemAmount = 8, 
				progAmount = 0, 
				weaponAmount = 4, 
				augmentAmount = 4, 
			},
			standard = {
				itemAmount = 4, 
				progAmount = 0, 				
				weaponAmount = 1, 
				augmentAmount = 1, 

			},
			server = {
				itemAmount = 0, 
				progAmount = 8, 				
				weaponAmount = 0, 
				augmentAmount = 0, 
			},
			miniserver = {
				itemAmount = 0, 
				progAmount = 2, 				
				weaponAmount = 0, 
				augmentAmount = 0,
				noBreakers = true  
			},
		},
	}

	util.tclear(all_stores.STORE_ITEM)
	util.tmerge(all_stores.STORE_ITEM, DEFAULT_STORE_ITEM)

end

ResetStoreItems()




--------------------------------------------------------------------------------------
-- Instantiation of a store and its stock.

local store = { ClassType = "store" }

function store:onWarp( sim, oldcell, cell )
    if self.items == nil then
        self.items, self.weapons, self.augments = createStoreItems( all_stores.STORE_ITEM, self, sim )
        self:clearBuyback()
    end
end

function store:clearBuyback()
    self.buyback = {}
    self.buyback.items = {}
    self.buyback.weapons = {}
    self.buyback.augments = {}
end

function store:isEmpty()
    return #self.items == 0 and #self.weapons == 0 and #self.augments == 0
end

function store:addItem( newItem )
    if newItem:getTraits().slot == "gun" or newItem:getTraits().slot == "melee" then
        table.insert( self.weapons, newItem )
    elseif newItem:getTraits().augment then
        table.insert( self.augments, newItem )
    else
        table.insert( self.items, newItem )
    end
end

-----------------------------------------------------
-- Interface functions

local function createStore( unitData, sim )
	return simunit.createUnit( unitData, sim, store )
end

simfactory.register( createStore )

return
{
	STORE_ITEM = all_stores.STORE_ITEM,
	createStore = createStore,
}


