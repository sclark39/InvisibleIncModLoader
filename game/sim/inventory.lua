----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )
local simfactory = include( "sim/simfactory" )
local mission_util = include( "sim/missions/mission_util" )
local util = include( "modules/util" )

--------------------------------------------------------------------------
-- Inventory functions

local function isCarryable( unit )
    return unit:hasAbility( "carryable" ) ~= nil
end

local function canCarry( unit, targetUnit )
	if unit == targetUnit then
		return false
	end

	if not simquery.isAgent( unit ) or unit:getTraits().isDrone then
		return false, STRINGS.UI.REASON.CANT_CARRY
	end

	if not isCarryable( targetUnit ) then
		return false, STRINGS.UI.REASON.NOT_CARRYABLE
	end

    if targetUnit:getTraits().anarchySpecialItem and not unit:getTraits().anarchyItemBonus then
        return false
    end

    if targetUnit:getTraits().largeSafeMapIntel and not unit:getTraits().largeSafeMapIntel then
        return false
    end    

	local x0, y0 = unit:getLocation()
	local x1, y1 = targetUnit:getLocation()
    if x0 and x1 and (x0 ~= x1 or y0 ~= y1) then
        if not targetUnit:getTraits().reachable or not simquery.canReach( unit:getSim(), x0, y0, x1, y1 ) then
    		return false, STRINGS.UI.REASON.CANT_REACH
        end
    end

	return true
end

local function pickupItem( sim, unit, item )
	assert( unit )
	assert( item )

	if item:getTraits().pickup_trigger then 
		sim:triggerEvent( item:getTraits().pickup_trigger )
	end
	unit._sim:dispatchEvent( simdefs.EV_UNIT_PICKEDUP, {unit=item} )
	if item:getTraits().deployed and item:getTraits().dynamicImpassOnDeploy then
		item:getTraits().dynamicImpass = nil
	end
	if item:getTraits().mainframe_icon_on_deploy then
		item:getTraits().mainframe_icon = nil
	end
	sim:triggerEvent(simdefs.TRG_UNIT_PICKEDUP, {item=item, unit=unit})
	item:getTraits().deployed = nil
	sim:warpUnit( item )
	unit:addChild( item )
	unit._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HUD/gameplay/HUD_ItemStorage_PutIn" )	
	unit._sim:dispatchEvent( simdefs.EV_UNIT_GET_ITEM, { item = item} )	

end

local function giftUnit( sim, unit, itemTemplate, showModal )
	if showModal == nil then 
		showModal = true
	end

    if type(itemTemplate) == "string" then
        local unitdefs = include( "sim/unitdefs" )
        itemTemplate = unitdefs.lookupTemplate( itemTemplate )
    end

	local newUnit= simfactory.createUnit( itemTemplate, sim )

	if not unit:getTraits().inventoryMaxSize or (unit:getInventoryCount() < 8) then
		sim:spawnUnit( newUnit )
		unit:addChild( newUnit )
		if unit:isPC() and showModal then	
			sim:dispatchEvent( simdefs.EV_SHOW_MODAL, {header=STRINGS.UI.DIALOGS.ITEM_RECEIVED, txt=util.sformat(STRINGS.UI.DIALOGS.INVENTORY_RECIEVED,unit:getName(),newUnit:getName()) } )	
		end

        return newUnit

	elseif unit:getLocation() then		
		sim:spawnUnit( newUnit )
		sim:warpUnit( newUnit, sim:getCell( unit:getLocation() ))
		if unit:isPC() and showModal then
			sim:dispatchEvent( simdefs.EV_SHOW_MODAL, {header=STRINGS.UI.DIALOGS.ITEM_RECEIVED, txt=util.sformat(STRINGS.UI.DIALOGS.INVENTORY_ON_FLOOR,unit:getName(),newUnit:getName()) } )	
		end

		return newUnit
	else
		return nil
	end
end

local function dropItem( sim, unit, item )
	assert( unit )
	assert( item )

	local cell = sim:getCell( unit:getLocation() )
	assert( cell )

	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HUD/gameplay/HUD_ItemStorage_TakeOut" )	
	sim:triggerEvent(simdefs.TRG_UNIT_DROPPED, {item=item, unit=unit})
	unit:removeChild( item )
	

	if item:getTraits().drop_dropdisguise then
		unit:setDisguise(false)
	end

	if item:getTraits().equipped then
		item:getTraits().equipped = nil
	end
	sim:warpUnit( item, cell )

end

local function dropAll( sim, unit )
	assert( unit )

	local cell = sim:getCell( unit:getLocation() )
	assert( cell )

	for i=#unit:getChildren(),1,-1 do
	
		local childUnit = unit:getChildren()[i]
		if isCarryable( childUnit ) then
			dropItem( sim, unit, childUnit )
		end
	end
end

local function unequipItem( userUnit, item )
	assert( array.find( userUnit:getChildren(), item ) ~= nil )
	assert( item:getTraits().equipped )
	
    userUnit:setAiming( false )
	item:getTraits().equipped = nil
end

local function equipItem( userUnit, item )
	assert( array.find( userUnit:getChildren(), item ) ~= nil ) -- Must be possessed
	assert( not item:getTraits().equipped ) -- Must not already be equipped
	assert( item:getTraits().slot ) -- Must specify an equip slot

	-- Must first unequip anything that is already equipped in this slot.
	for _,childUnit in pairs(userUnit:getChildren()) do
		if childUnit:getTraits().slot == item:getTraits().slot and childUnit:getTraits().equipped then
			unequipItem( userUnit, childUnit )
			break
		end
	end

	item:getTraits().equipped = true
end

local function autoEquip( unit )
	if simquery.getEquippedGun( unit ) == nil then
		for _,childUnit in pairs( unit:getChildren() ) do
			if childUnit:getTraits().slot == "gun" then
				equipItem( unit, childUnit )
				break
			end
		end
	end

	if simquery.getEquippedMelee( unit ) == nil then
		for _,childUnit in pairs( unit:getChildren() ) do
			if childUnit:getTraits().slot == "melee" then
				equipItem( unit, childUnit )
				break
			end
		end
	end
end


local function giveItem( unit, targetUnit, item )
	assert( array.find( unit:getChildren(), item ))

	if item:getTraits().equipped then
        unequipItem( unit, item )
	end
	unit:removeChild( item )

	if item:getTraits().drop_dropdisguise then
		unit:setDisguise(false)
	end

	targetUnit:addChild( item )
	if targetUnit:getPlayerOwner() == targetUnit._sim:getCurrentPlayer() then
		targetUnit._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HUD/gameplay/HUD_ItemStorage_PutIn" )	
	else
		targetUnit._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HUD/gameplay/HUD_ItemStorage_TakeOut" )	
	end

	targetUnit._sim:dispatchEvent( simdefs.EV_UNIT_GET_ITEM, { item = item} )	

end

local function giveAll( unit, targetUnit )
	while #unit:getChildren() > 0 do
		giveItem( unit, targetUnit, unit:getChildren()[1] )
	end
end

---------------------------------------------
-- Unequip (if equipped) and remove item from the unit's inventory.
-- The item is despawned from the sim, not dropped.

local function trashItem( sim, unit, item )
	local x1, y1 = unit:getLocation()
	local y1 = y1 - 0.75 
	local x1 = x1 - 0.75

	if item:getTraits().equipped then
		unequipItem( unit, item )
	end

	if item:getTraits().installed  then
		if item:getTraits().addAbilities then
			unit:removeAbility(item:getTraits().addAbilities)
		end	
		if item:getTraits().addTrait then
			for i,trait in ipairs(item:getTraits().addTrait)do
				unit:getTraits()[trait[1]] = nil
			end
		end
		if item:getTraits().modTrait then
			for i,trait in ipairs(item:getTraits().modTrait)do
				unit:getTraits()[trait[1]] = unit:getTraits()[trait[1]] + trait[2]
			end
		end	
		if item:getTraits().modSkill then
			local skill = unit:getSkills()[item:getTraits().modSkill]
			if skill then
				while skill._currentLevel > 1 do
					skill:levelDown( sim, unit )
				end
			end
			if item:getTraits().modSkillLock then
				for i,skill in ipairs(item:getTraits().modSkillLock) do
					unit:getTraits().skillLock[skill] = false
				end
			end				
		end
	end

	if item:getTraits().drop_dropdisguise then
		unit:setDisguise(false)
	end


	unit:removeChild( item )
	sim:despawnUnit( item )
end

local function useItem( sim, unit, item )
	local x1, y1 = unit:getLocation()

	if item:getTraits().cooldown then		
		local mod = 0
		if unit:countAugments( "augment_torque_injectors" ) > 0 then			
			mod = mod +1
		end

		item:getTraits().cooldown = math.max(item:getTraits().cooldownMax - mod, 0)		
		if mod > 0 then
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = STRINGS.ITEMS.AUGMENTS.TORQUE_INJECTORS, x = x1, y = y1,color={r=255/255,g=255/255,b=51/255,a=1}} )	
		end
		if unit:countAugments( "augment_tony_2" ) > 0 and not unit:getTraits().tonyBonus then			
			if item:getTraits().cooldownMax - mod > 2 then
				unit:getPlayerOwner():addCPUs(2, sim, x1,y1)
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = STRINGS.UI.FLY_TXT.THERMAL_GENERATOR, x = x1, y = y1,color={r=255/255,g=255/255,b=51/255,a=1}} )								
				unit:getTraits().tonyBonus = 1
			end
		end		
		if not sim:getTags().isTutorial then
			sim:dispatchEvent( simdefs.EV_SHOW_COOLDOWN, {})
		end
	end

	if item:getTraits().melee == true then 
		if unit:countAugments( "augment_nika_2" ) > 0 then 
			for _, item in pairs( unit:getChildren() ) do 
				if item:getTraits().cooldown then 
					item:getTraits().cooldown = math.max(item:getTraits().cooldown - 1, 0)	
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = STRINGS.ITEMS.AUGMENTS.NIKAS_2, x = x1, y = y1,color={r=255/255,g=255/255,b=51/255,a=1}} )
				end 
			end 
		end 
	end 

	if item:getTraits().usesCharges == true then 
		print("USE CHARGE",item:getTraits().charges)
		item:getTraits().charges =  item:getTraits().charges -1 
		print("AFTER",item:getTraits().charges)
	end 	

	if item:getTraits().pwrCost then
    	item:getPlayerOwner():addCPUs( -item:getTraits().pwrCost, sim, x1,y1)	
	end

   	if item:getTraits().ammo then
        item:getTraits().ammo = item:getTraits().ammo - 1
	end

	if item:getTraits().energyWeapon then
    	item:getTraits().energyWeapon = "active"
    end

    if item:getTraits().disposable and item:getUnitOwner() then
		trashItem( sim, item:getUnitOwner(), item )
	end

end

--------------------------------------------------------------------------

return
{
	isCarryable = isCarryable,
	canCarry = canCarry,

	giftUnit = giftUnit,
	giveItem = giveItem,
	giveAll = giveAll,
	pickupItem = pickupItem,
	dropItem = dropItem,
	dropAll = dropAll,

	equipItem = equipItem,
	unequipItem = unequipItem,
	autoEquip = autoEquip,

	trashItem = trashItem,
	useItem = useItem,
}
