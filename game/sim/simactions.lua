----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local serverdefs = include( "modules/serverdefs" )
local array = include( "modules/array" )
local simquery = include("sim/simquery")
local simdefs = include( "sim/simdefs" )
local unitdefs = include( "sim/unitdefs" )
local inventory = include( "sim/inventory" )
local abilitydefs = include( "sim/abilitydefs" )
local skilldefs = include( "sim/skilldefs" )
local inventory = include( "sim/inventory" )
local mainframe = include( "sim/mainframe" )
local mission_util = include( "sim/missions/mission_util" )

-----------------------------------------------------
-- Action functions

local function doMoveAction( sim, unitID, moveTable )
	local player = sim:getCurrentPlayer()
	local unit = sim:getUnit( unitID )
	
	sim:moveUnit( unit, moveTable ) 
end

local function doUseDoorAction( sim, exitOp, unitID, x0, y0, facing )
	local player = sim:getCurrentPlayer()
	local unit = sim:getUnit( unitID )
	local cell = sim:getCell(x0, y0)

	assert( unit:getPlayerOwner() == player, unit:getName()..","..tostring(unit:getPlayerOwner())..","..tostring(exitOp) )
	assert( cell )
	if sim:isVersion("0.17.5") then
		assert( simquery.canModifyExit( unit, exitOp, cell, facing ))
	end
	assert( simquery.canReachDoor( unit, cell, facing ))

	--unit:resetAllAiming()

	--face the door correctly if it's not in the same cell
	local vizFacing = facing
	local x1,y1 = unit:getLocation()
	if x0 ~= x1 or y0 ~= y1 then
		vizFacing = simquery.getDirectionFromDelta(x0-x1,y0-y1)
	end
	unit:setFacing(vizFacing)
	if not unit:getTraits().noDoorAnim then 
		sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = unitID, facing = vizFacing, exitOp=exitOp } )	
	end
	sim:modifyExit( cell, facing, exitOp, unit,  unit:getTraits().sneaking )
    if unit:isValid() then
	    if not unit:getTraits().noDoorAnim then 
		    sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = unitID, facing = vizFacing, exitOp=exitOp } )
	    end
	    if exitOp == simdefs.EXITOP_BREAK_DOOR and not unit:getTraits().interrupted then
		    sim:dispatchEvent( simdefs.EV_UNIT_GUNCHECK, { unit = unit, facing = vizFacing } )
	    end
    end
	unit:getTraits().interrupted = nil
end

local function doAbilityAction( sim, ownerID, userID, abilityIdx, ... )
	local player = sim:getCurrentPlayer()
	local abilityOwner = sim:getUnit( ownerID ) or array.findIf( sim:getPlayers(), function( p ) return p:getID() == ownerID end )
	local abilityUser = sim:getUnit( userID ) or array.findIf( sim:getPlayers(), function( p ) return p:getID() == userID end )

	local ability = abilityOwner:getAbilities()[ abilityIdx ]
	assert( ability, string.format("Ability index %s not found!", tostring(abilityIdx) ) )
	
	if ability:getDef().equip_program then
        player:equipProgram( sim, ability:getID() )
	else		
		ability:executeAbility( sim, abilityOwner, abilityUser, ... )
	end

end

local function doMainframeAction( sim, updates )
	
	if updates.action == "breakIce" then
		local player = sim:getCurrentPlayer()
        local program = player:getEquippedProgram()
		if updates.unitID then
        	local unit = sim:getUnit(updates.unitID)
            program:executeAbility( sim, unit )
		else
            program:executeAbility( sim, updates.ability )
		end

		if program.cooldown and program.cooldown> 0 then
			player:equipProgram( sim, nil )			
		end
	
	elseif updates.action == "targetUnit" then
		local player = sim:getCurrentPlayer()
        local program = player:getEquippedProgram()
		if updates.unitID then
        	local unit = sim:getUnit(updates.unitID)
            program:executeAbility( sim, unit )
		else
            program:executeAbility( sim, updates.ability )
		end

		if program.cooldown and program.cooldown> 0 then
			player:equipProgram( sim, nil )			
		end

	elseif updates.action == "use" then
		sim:getCurrentPlayer():glimpseUnit( sim, updates.unitID )
		sim:dispatchEvent( simdefs.EV_UNIT_MAINFRAME_UPDATE, {units = {updates.unitID}} )	
		
    	local unit = sim:getUnit(updates.unitID)
		if type( unit[updates.fn] ) == "function" then
			unit[ updates.fn ]( unit, sim )
		end
	end

end

local function doBuyItem( sim, unitID, shopUnitID, itemIndex, discount, itemType, buyback )
	local unit = sim:getUnit( unitID ) or sim:getPlayerByID(unitID)
	local shopUnit = sim:getUnit( shopUnitID )
	local player = sim:getCurrentPlayer()
	assert( unit )
	assert( unit == player or unit:getPlayerOwner() == player )

	-- Remove the option from the store.
	local item = nil
	if buyback then 
		if itemType == "item" then 
			item = table.remove( shopUnit.buyback.items, itemIndex )
		elseif itemType == "weapon" then 
			item = table.remove( shopUnit.buyback.weapons, itemIndex )
		elseif itemType == "augment" then 
			item = table.remove( shopUnit.buyback.augments, itemIndex )
		end 
	else 
		if itemType == "item" then 
			item = table.remove( shopUnit.items, itemIndex )
		elseif itemType == "weapon" then 
			item = table.remove( shopUnit.weapons, itemIndex )
		elseif itemType == "augment" then 
			item = table.remove( shopUnit.augments, itemIndex )
		end 
	end 

	sim:getStats():incStat( "items_earned" )
	
	-- Pay up.
	local credits = item:getUnitData().value * discount
	assert( player:getCredits() >= credits )
	player:addCredits( -credits )
	sim._resultTable.credits_lost.buying = sim._resultTable.credits_lost.buying and sim._resultTable.credits_lost.buying + credits or credits

	
	sim:getStats():sumStat( itemType .. "_purchases", -credits )

	-- Items with 'def' are mainframe programs, not simunits. Gross!
	if item:getTraits().mainframe_program then
		table.insert(sim._resultTable.new_programs, item:getTraits().mainframe_program)
		assert( not player:hasMainframeAbility( item:getTraits().mainframe_program ) )
		sim:getStats():incStat( "programs_earned" )
		
		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/VoiceOver/Incognita/Pickups/NewProgram" )

		player:addMainframeAbility( sim, item:getTraits().mainframe_program )
		local mainframeDef = abilitydefs.lookupAbility(item:getTraits().mainframe_program)
        local dialogParams =
        {
            STRINGS.PROGRAMS.PURCHASED,
            item:getName(),
            string.format( STRINGS.PROGRAMS.PURCHASED_DESC, mainframeDef.desc),
            mainframeDef.icon_100,
            color = {r=1,g=0,b=0,a=1}
        }
		sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "programDialog", dialogParams = dialogParams } )

	else
		if buyback then 
			unit:addChild( item )
			inventory.autoEquip( unit )
		else 
			sim:spawnUnit( item )
			unit:addChild( item )
			inventory.autoEquip( unit )
		end 

		if itemType == "augment" then 
							
			local result = mission_util.showAugmentInstallDialog( sim, item, unit )
			if result == 2 then
				local abilityDef = unit:ownsAbility( "installAugment" )
				if abilityDef:canUseAbility( sim, item, unit ) then 
					abilityDef:executeAbility( sim, item, unit )
				else 
					mission_util.showDialog( sim, STRINGS.UI.INSTALL_AUGMENT, STRINGS.UI.PUTTING_AUGMENT_IN_INVENTORY )
				end 
			end 
		end
        unit:checkOverload( sim )
	end

	sim:triggerEvent( simdefs.TRG_BUY_ITEM, {shopUnit = shopUnit, unit = unit, item = item} )

	sim:dispatchEvent( simdefs.EV_ITEMS_PANEL ) -- Triggers refresh.
end

local function doSellItem( sim, unitID, shopUnitID, itemIndex )
	local unit = sim:getUnit( unitID )
	local shopUnit = sim:getUnit( shopUnitID )
	local player = sim:getCurrentPlayer()

	assert( unit:getPlayerOwner() == player )

	local item = unit:getChildren()[ itemIndex ]

	if item:hasAbility("equippable") then 
		table.insert( shopUnit.buyback.weapons, item )
	elseif item:hasTrait("augment") then
		table.insert( shopUnit.buyback.augments, item )
	else
		table.insert( shopUnit.buyback.items, item )
	end 

	if item:getTraits().equipped then
        inventory.unequipItem( unit, item )
    end
	unit:removeChild( item )

	local credits = math.ceil( item:getUnitData().value * 0.5 )
	player:addCredits( credits )
	sim._resultTable.credits_gained.selling = sim._resultTable.credits_gained.selling and sim._resultTable.credits_gained.selling + credits or credits

	sim:dispatchEvent( simdefs.EV_ITEMS_PANEL )
end

local function doSellAbility( sim, index )
	local player = sim:getCurrentPlayer()
	local ability = player:getAbilities()[index]
	assert(ability)

 	player:removeAbility( sim, ability )

	if ability.value then
		local credits = math.ceil( ability.value * 0.5 )
		player:addCredits( credits )
	end
	sim:dispatchEvent( simdefs.EV_ITEMS_PANEL )
end

local function doTransferItem( sim, unitID, targetID, itemIndex )
	local unit = sim:getUnit( unitID )
	local targetUnit = sim:getUnit( targetID )
	local player = sim:getCurrentPlayer()
	assert( unit:getPlayerOwner() == player )

	local item = unit:getChildren()[ itemIndex ]
    if targetUnit then
	    inventory.giveItem( unit, targetUnit, item )
        targetUnit:checkOverload( sim )
    else
	    inventory.dropItem( sim, unit, item )
        unit:checkOverload( sim )
    end

	sim:dispatchEvent( simdefs.EV_ITEMS_PANEL )
end

local function doSearch( sim, unitID, searchTypeAnarchy5 )
	if searchTypeAnarchy5 then
		sim:getUnit(unitID):getTraits().searchedAnarchy5 = true
	end
	sim:getUnit(unitID):getTraits().searched = true
end

local function doLootItem( sim, unitID, itemID )
	local unit = sim:getUnit( unitID )
	local item = sim:getUnit( itemID )
	assert( unit:getPlayerOwner() == sim:getCurrentPlayer() )

	local cell = sim:getCell( item:getLocation() )
	if cell then
		if item:hasAbility( "carryable" ) then
			inventory.pickupItem( sim, unit, item )
			sim:emitSound( simdefs.SOUND_ITEM_PICKUP, cell.x, cell.y, unit )				
		
		elseif item:getTraits().cashOnHand then
			
			local credits = math.floor( simquery.calculateCashOnHand( sim, item ) * (1 + (unit:getTraits().stealBonus or 0)) )
			sim._resultTable.credits_gained.pickpocket = sim._resultTable.credits_gained.pickpocket and sim._resultTable.credits_gained.pickpocket + credits or credits
			unit:getPlayerOwner():addCredits( credits, sim, cell.x, cell.y )
			item:getTraits().cashOnHand = nil
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_CREDITS_PICKUP.path )

		elseif item:getTraits().credits then

			local credits = item:getTraits().credits
			sim._resultTable.credits_gained.safes = sim._resultTable.credits_gained.safes and sim._resultTable.credits_gained.safes + credits or credits
			unit:getPlayerOwner():addCredits( credits, sim, cell.x, cell.y )
			item:getTraits().credits = nil
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_CREDITS_PICKUP.path )

		elseif item:getTraits().PWROnHand then
			local PWR = simquery.calculatePWROnHand( sim, item )  
			unit:getPlayerOwner():addCPUs( PWR, sim, cell.x, cell.y)
			item:getTraits().PWROnHand = nil	
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/item_pickup" )		
		end
	else
		local itemOwner = item:getUnitOwner()
		inventory.giveItem( itemOwner, unit, item)

		local itemDef = item:getUnitData()
		if itemDef.traits.showOnce then
            local dialogParams =
            {
                STRINGS.UI.ITEM_ACQUIRED, itemDef.name, itemDef.desc, itemDef.profile_icon_100,
            }
			sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { showOnce = itemDef.traits.showOnce, dialog = "programDialog", dialogParams = dialogParams } )
		end
	end

    item:getTraits().anarchySpecialItem = nil
    item:getTraits().largeSafeMapIntel = nil

	inventory.autoEquip( unit )
	unit:resetAllAiming()
	unit:checkOverload( sim )

	sim:dispatchEvent( simdefs.EV_ITEMS_PANEL ) -- Triggers refresh.
end

local function doEndTurnAction( sim )
    sim:getTags().rewindError = nil
	sim:endTurn()
end

local function doTriggerAction( sim, triggerType, triggerData )
	sim:triggerEvent( triggerType, triggerData )
end

local function doDebugAction( sim, fn, ... )
	-- Serializing debug functions only works if the function has no upvalues.  Hence this assert.
	-- Ensure all upvalues are converted to actual function parameters if you hit this assert.
	assert( debug.getupvalue( fn, 1 ) == nil )
	fn( sim, ... )
end

local function rewindAction( sim, rewindsLeft )
    sim:getTags().rewindsLeft = rewindsLeft
    log:write( "SIM REWOUND: %d", rewindsLeft )
end

local function doAbortMission( sim )
    local escapeCount = 0
    for agentID, deployData in pairs(sim:getPC():getDeployed()) do
        if deployData.escapedUnit then
            escapeCount = escapeCount + 1
        else
            local unit = sim:getUnit( deployData.id )
            if unit then
                unit:killUnit( sim )
            end
        end
    end

    if escapeCount == 0 then
        -- Force resignation; this is so we don't query for rewind if there is one left, since the player already chose to abort.
        sim:lose()
    else
    	sim:updateWinners()
    end
end

local function doResignMission( sim )
    sim:lose()
end

-----------------------------------------------------------------------------
-- register factory functions

return
{
	moveAction = doMoveAction,
	useDoorAction = doUseDoorAction,
	abilityAction = doAbilityAction,
	mainframeAction = doMainframeAction,
	endTurnAction = doEndTurnAction,
	triggerAction = doTriggerAction,
	debugAction = doDebugAction,
	buyItem = doBuyItem,
	sellItem = doSellItem,
	sellAbility = doSellAbility,
	transferItem = doTransferItem,
	search = doSearch,
	lootItem = doLootItem,
    rewindAction = rewindAction,
    abortMission = doAbortMission,
    resignMission = doResignMission,
}

