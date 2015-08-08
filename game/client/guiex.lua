----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include("client_util")
local array = include( "modules/array" )
local cdefs = include( "client_defs" )
local modalDialog = include( "states/state-modal-dialog" )
local mui_defs = include( "mui/mui_defs" )

----------------------------------------------------------------
-- Create an asynch task with a wait dialog.

local function createDialogTask( dialogStr, task, cb, ... )
	assert( task )
	assert( dialogStr )

	local thread = MOAICoroutine.new ()
	thread:run ( function( ... )

		local startTime = os.clock()

		local modalDialog = modalDialog.createBusyDialog( dialogStr )
		statemgr.activate( modalDialog )

		while ( not task.isFinished ) do
			local progress = math.floor(task.httptask:getProgress())
			modalDialog:setText( string.format( "%s (%.2f) [%%%d]", dialogStr, os.clock() - startTime, progress ))
			coroutine.yield ()
		end

		statemgr.deactivate( modalDialog )

		local endTime = os.clock()
		log:write( "Task '" ..dialogStr.. "' took: " ..1000 * (endTime - startTime).. " ms")
		--log:write( util.stringize( task.result ))

		cb( task.result, task.responseCode, ... )
	end, ... )
end

local function createCountUpThread( widget, numStart, numEnd, duration, format )
	
	local thread = MOAICoroutine.new()
	thread:run( function() 
		local num = numStart
		local speed = (numEnd - numStart)/(60*duration)

		widget:setText(num)
		
		while (numStart < numEnd and num < numEnd) or (numStart > numEnd and num < numEnd) do
			num = num + speed

            if format then
                widget:setText( string.format( format, math.floor(num) ) )
			else
				widget:setText( math.floor(num) )
			end

			coroutine.yield()
		end

        if format then
            widget:setText( string.format( format, math.floor(numEnd) ) )
        else
            widget:setText( tostring(numEnd) )
        end
	end)

	return thread

end

local function createCountDownThread( widget, numStart, numEnd, duration, format )
	
	local thread = MOAICoroutine.new()
	thread:run( function() 
		local num = numStart
		local speed = (numEnd - numStart)/(60*duration)

		widget:setText(num)
		
		while (numStart > numEnd and num > numEnd) or (numStart < numEnd and num > numEnd) do
			num = math.max(math.max(0,num + speed),numEnd)

			if format then
				widget:setText( util.sformat( format, math.floor(num) ) )
			else
				widget:setText( math.floor(num) )
			end

			coroutine.yield()
		end

			if format then
				widget:setText( util.sformat( format, math.floor(numEnd) ) )
			else
				widget:setText( math.floor(numEnd) )
			end
        
	end)

	return thread

end

local function canUseItem( item, unit )
    local inventory = include( "sim/inventory" )

    local restricted = false

	if item:getTraits().restrictedUse then
		restricted= true
		local userUnitAgentID = nil 
		if unit.agentDef then
			userUnitAgentID = unit.agentDef.id
		else
			userUnitAgentID = unit:getUnitData().agentID
		end
		for i,set in pairs(item:getTraits().restrictedUse )do
			if set.agentID == userUnitAgentID then
				restricted=false
			end
		end
	end

	if item:getTraits().restrictedUse and restricted then
		return true, true
	elseif item:getTraits().installed and item:getTraits().augment then
		return false, false
    elseif not item:getUnitData().program and not inventory.isCarryable( item ) then
        return false, false
	elseif item:getRequirements() and not unit:getTraits().useAnyItem then 
		for skill,level in pairs( item:getRequirements() ) do
			if not unit:hasSkill(skill, level) then 
				return true, true
			end 
		end
    end

    return true, false
end

local SAFE_RED = { 245/255, 81/255, 32/255 }
local DEFAULT_AMMO_CLR = { 140/255, 255/255, 255/255 }
local ACTIVE_AMMO_CLR = { 1, 1, 0 }

local function updateButtonFromAbility( screen, widget, ability, hotkey, unit )
	
	local enabled, requirement = true, false
	
	widget._item = ability

	widget:setVisible( true )
	widget:setAlias( ability.name )
    if widget.binder.btn:getSize() > 36 then
    	widget.binder.btn:setImage( ability.icon_100 )
    else
    	widget.binder.btn:setImage( ability.icon )
    end
	widget.binder.btn:setDisabled( not enabled )
	widget.binder.btn.onClick = nil -- Caller-defined.

    if ability.onTooltip then
		widget.binder.btn:setTooltip( function() return ability:onTooltip( screen, nil, unit ) end )
    else
        widget.binder.btn:setTooltip( nil )
	end
	
    widget.binder.btn:setHotkey( hotkey and string.byte(hotkey) )
	widget.binder.equipImg:setVisible( false )


	widget.binder.btn:setColor(cdefs.COLOR_PROGRAM:unpack())			
	widget.binder.btn:setColorInactive(cdefs.COLOR_PROGRAM:unpack())
	widget.binder.btn:setColorActive(cdefs.COLOR_PROGRAM_HOVER:unpack())
	widget.binder.btn:setColorHover(cdefs.COLOR_PROGRAM_HOVER:unpack())	

    widget.binder.ammoTxt:setText( "")
	widget.binder.ammoBG:setVisible( false )	
	widget.binder.encumbered:setVisible(false)
end

local function updateButtonFromItem( screen, game, widget, item, unit, encumbered)	
	local itemData = item:getUnitData()
	
	local enabled, requirement = true, false
	if unit then
	 	enabled, requirement = canUseItem( item, unit )
	end

	widget._item = item

	widget:setVisible( true )
	widget:setAlias( item:getName() )
    if widget.binder.btn:getSize() > 36 then
    	widget.binder.btn:setImage( itemData.profile_icon_100 )
    else
    	widget.binder.btn:setImage( itemData.profile_icon )
    end
    
	widget.binder.btn:setDisabled( not enabled )

	widget.binder.btn.onClick = nil -- Caller-defined.
	if item:getUnitData().onTooltip then
        widget.binder.btn:setTooltip(
            function()
		        local tooltip = util.tooltip( screen, game )
		        local section = tooltip:addSection()
		        item:getUnitData().onTooltip( section, item, unit, game )
		        if encumbered then
		        	local section = tooltip:addSection()
		        	section:addLine( util.sformat( STRINGS.UI.TOOLTIPS.ENCUMBERED, 1 ))
		    	end
                return tooltip
            end )

    else
        widget.binder.btn:setTooltip( nil )
	end
	widget.binder.equipImg:setVisible( item:getTraits().equipped == true )

	if enabled == true then
		if requirement then 
			widget.binder.btn:setColor(cdefs.COLOR_REQ:unpack())
			widget.binder.btn:setColorInactive(cdefs.COLOR_REQ:unpack())
			widget.binder.btn:setColorActive(cdefs.COLOR_REQ_HOVER:unpack())
			widget.binder.btn:setColorHover(cdefs.COLOR_REQ_HOVER:unpack())	

        elseif itemData.program then
			widget.binder.btn:setColor(cdefs.COLOR_PROGRAM:unpack())			
			widget.binder.btn:setColorInactive(cdefs.COLOR_PROGRAM:unpack())
			widget.binder.btn:setColorActive(cdefs.COLOR_PROGRAM_HOVER:unpack())
			widget.binder.btn:setColorHover(cdefs.COLOR_PROGRAM_HOVER:unpack())	

		else 
			widget.binder.btn:setColor(cdefs.COLOR_FREE:unpack())			
			widget.binder.btn:setColorInactive(cdefs.COLOR_FREE:unpack())
			widget.binder.btn:setColorActive(cdefs.COLOR_FREE_HOVER:unpack())
			widget.binder.btn:setColorHover(cdefs.COLOR_FREE_HOVER:unpack())	
		end

	else
		widget.binder.img:setColor(0.5,0.5,0.5,1)
		widget.binder.btn:setColor(0.5,0.5,0.5,1)
	end

    local ammoTxt, ammoClr = "", DEFAULT_AMMO_CLR
	if item:getTraits().energyWeapon == "active" then
        ammoTxt, ammoClr = STRINGS.UI.HUD_WEAPON_ACTIVE, ACTIVE_AMMO_CLR

    elseif item:getTraits().energyWeapon == "used" then
        ammoTxt, ammoClr = STRINGS.UI.HUD_WEAPON_USED, SAFE_RED
            
	elseif itemData.traits.maxAmmo then
        ammoTxt = util.sformat( STRINGS.UI.HUD_WEAPON_AMMO, item:getTraits().ammo, itemData.traits.maxAmmo )
        if item:getTraits().ammo <= 0 then
    		ammoClr = SAFE_RED
        end

	elseif (item:getTraits().cooldown or 0) > 0 then		
        ammoTxt, ammoClr = tostring(item:getTraits().cooldown), SAFE_RED
	elseif item:getTraits().usesCharges then
		ammoTxt = util.sformat( STRINGS.UI.HUD_WEAPON_AMMO, item:getTraits().charges, itemData.traits.chargesMax )        
        if item:getTraits().charges < 1 then
    		ammoClr = SAFE_RED
        end     
	end

    widget.binder.ammoTxt:setText( ammoTxt )
    widget.binder.ammoTxt:setColor( 0, 0, 0 )
	widget.binder.ammoBG:setVisible( #ammoTxt > 0 )
	widget.binder.ammoBG:setColor( unpack(ammoClr) )
    local encumberedWidget = widget.binder:tryBind( "encumbered" )
	if encumberedWidget then
        if encumbered then
		    widget.binder.encumbered:setVisible(true)
		    widget.binder.encumbered:setColor(cdefs.COLOR_ENCUMBERED:unpack())
	    else
		    widget.binder.encumbered:setVisible(false)
	    end
    end
end

local function updateButtonEmptySlot( widget, encumbered)
	widget:setVisible( true )
	widget:setAlias(nil)
	widget.binder.equipImg:setVisible( false )
	widget.binder.btn:setImage( "" )
	widget.binder.btn:setDisabled( true )
	local tooltip = util.sformat(STRINGS.UI.TOOLTIPS.EMPTY_SLOT,1)
	if encumbered then
		tooltip = tooltip .. "\n" .. util.sformat(STRINGS.UI.TOOLTIPS.WILL_ENCUMBER,1)
		widget.binder.encumbered:setVisible(true)
		widget.binder.encumbered:setColor(cdefs.COLOR_ENCUMBERED:unpack())
	else
		widget.binder.encumbered:setVisible(false)
	end
	widget.binder.btn:setTooltip( tooltip )
	widget.binder.ammoBG:setVisible(false)
	widget.binder.ammoTxt:setText("")

end

local function updateButtonUpgradeInventory( widget )
	widget:setVisible( true )
	widget:setAlias(nil)
	widget.binder.equipImg:setVisible( false )
    widget.binder.btn:setDisabled( false )
    widget.binder.btn:setTooltip( STRINGS.UI.TOOLTIPS.UPGRADE_INVENTORY )
    widget.binder.btn:setImage( "gui/hud3/SHOP_new_inventory_slot.png" )
	widget.binder.ammoBG:setVisible(false)
	widget.binder.ammoTxt:setText("")
end

local function updateButtonCredits( widget, credits, bonus, targetUnit )
	widget:setVisible( true )
	widget:setAlias(nil)
	widget.binder.equipImg:setVisible( false )
    widget.binder.btn:setDisabled( false )
    widget.binder.btn:setImage( cdefs.CREDITS_ICON )		
	local tt = ""
	if targetUnit:getTraits().isGuard then
		tt = util.sformat( STRINGS.UI.TOOLTIPS.ANARCHY_STEAL, credits )
		if bonus and bonus > 0 then
			tt = tt .. util.sformat( STRINGS.UI.TOOLTIPS.ANARCHY_BONUS, bonus )
		end
	else
		tt = util.sformat( STRINGS.UI.TOOLTIPS.LOOT_TOOLTIP, credits )
	end
	widget.binder.btn:setColor(cdefs.COLOR_FREE:unpack())			
	widget.binder.btn:setColorInactive(cdefs.COLOR_FREE:unpack())
	widget.binder.btn:setColorActive(cdefs.COLOR_FREE_HOVER:unpack())
	widget.binder.btn:setColorHover(cdefs.COLOR_FREE_HOVER:unpack())	

	widget.binder.btn:setTooltip( tt )
	widget.binder.ammoBG:setVisible(false)
	widget.binder.ammoTxt:setText("")
	widget.binder.encumbered:setVisible(false)
end


local function updateButtonPWR( widget, pwr )
	widget:setVisible( true )
	widget:setAlias(nil)
	widget.binder.equipImg:setVisible( false )
    widget.binder.btn:setDisabled( false )
    widget.binder.btn:setImage( cdefs.PWR_ICON )		
	local tt = util.sformat( STRINGS.UI.TOOLTIPS.PWR_STEAL, pwr )

	widget.binder.btn:setColor(cdefs.COLOR_FREE:unpack())			
	widget.binder.btn:setColorInactive(cdefs.COLOR_FREE:unpack())
	widget.binder.btn:setColorActive(cdefs.COLOR_FREE_HOVER:unpack())
	widget.binder.btn:setColorHover(cdefs.COLOR_FREE_HOVER:unpack())	

	widget.binder.btn:setTooltip( tt )
	widget.binder.ammoBG:setVisible(false)
	widget.binder.ammoTxt:setText("")
	widget.binder.encumbered:setVisible(false)
end
----------------------------------------------------------------

return
{
	createDialogTask = createDialogTask,
	createCountUpThread = createCountUpThread,
	createCountDownThread = createCountDownThread,
    updateButtonFromItem = updateButtonFromItem,
    updateButtonFromAbility = updateButtonFromAbility,
    updateButtonEmptySlot = updateButtonEmptySlot,
    updateButtonUpgradeInventory = updateButtonUpgradeInventory,
    updateButtonCredits = updateButtonCredits,
    updateButtonPWR = updateButtonPWR,
}


