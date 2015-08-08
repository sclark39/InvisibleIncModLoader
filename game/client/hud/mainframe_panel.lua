----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local mui_defs = include( "mui/mui_defs")
local world_hud = include( "hud/hud-inworld" )
local hudtarget = include( "hud/targeting")
local rig_util = include( "gameplay/rig_util" )
local level = include( "sim/level" )
local mainframe = include( "sim/mainframe" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )



local MODE_HIDDEN = 0
local MODE_VISIBLE = 1

local BREAKICE_COLOR_TT = util.color( 244/255, 255/255, 120/255, 200/255 ) -- Tooltip color of break ice lines


local null_tooltip = class()

function null_tooltip:init( hud, str, str2 )
	self._hud = hud
	self._str = str
	self._str2 = str2  
end

function null_tooltip:setPosition( wx, wy )
	self._panel:setPosition( self._hud._screen:wndToUI( wx, wy ))
end

function null_tooltip:getScreen()
	return self._hud._screen
end

function null_tooltip:activate( screen )
	local combat_panel = include( "hud/combat_panel" )
	local COLOR_GREY = util.color(180/255,180/255,180/255,150/255)

	self._panel = combat_panel( self._hud, self._hud._screen )
	self._panel:refreshPanelFromStr( self._str, self._str2, COLOR_GREY )
end

function null_tooltip:deactivate()
	self._panel:setVisible( false )
end

------------------------------------------------------------------------------
-- Local functions

local function setFirewallIdleAnim( widget, unit )
	if unit:getTraits().parasite then
		widget.binder.anim:setAnim( "idle_bugged" )
	else
		widget.binder.anim:setAnim( "idle" )
	end
end

local function destroyIceWidget( widget )
	if widget.iceBreak then
		widget.iceBreak:destroy()
		widget.iceBreak = nil
	end
end

local function findWidget( widgets, unit )
	for _, widget in ipairs( widgets ) do		
		if widget.ownerID == unit:getID() then
			return widget
		end
	end

	return nil
end
 
local function createActivateTooltip( hud, unit, useData )

	local tooltip = util.tooltip( hud._screen )
	local section = tooltip:addSection()

    if unit:getTraits().mainrame_status == "inactive" then
        section:addLine( unit:getName(), STRINGS.UI.TOOLTIPS.MAINFRAME_INACTIVE )
    elseif unit:getTraits().mainframe_status == "active" then  
        section:addLine( unit:getName(), STRINGS.UI.TOOLTIPS.MAINFRAME_ACTIVE )
    else 
        section:addLine( unit:getName(), STRINGS.UI.TOOLTIPS.MAINFRAME_OFF )
    end

	section:addAbility( useData.name, useData.tooltip, "gui/items/swtich.png" )

	if useData.canToggle then
		local enabled,reason = useData.canToggle(unit)
		if reason then
			 section:addLine( util.sformat("<c:ff0000>{1}</>",reason))
		end
	end

	if unit:getTraits().range then

		tooltip.activate = function ( )
			local screen = hud._screen
			for _, section in ipairs( tooltip._sections ) do
				section:activate( screen )
			end

			local x0, y0 = unit:getLocation()
			local coords = simquery.rasterCircle( hud._game.simCore, x0, y0, unit:getTraits().range )
			tooltip._hiliteID = hud._game.boardRig:hiliteCells( coords, {0.2,0.2,0.2,0.2} )			
		end

		tooltip.deactivate = function( )
			for _, section in ipairs( tooltip._sections ) do
				section:deactivate()
			end

			hud._game.boardRig:unhiliteCells( tooltip._hiliteID )
			tooltip._hiliteID = nil			
		end
	end

	return tooltip
end

local function playDaemonDeathFX(panel,unit)
	local widgets = util.tdupe( panel._hud._world_hud:getWidgets( world_hud.MAINFRAME ) or {} )
	local widget = findWidget( widgets, unit )
	widget.binder.program.binder.daemonDead:setVisible(true)
	widget.binder.program.binder.daemonDead:setAnim("idle")
	widget.binder.program.binder.daemonDead:getProp():setListener( KLEIAnim.EVENT_ANIM_END,
		function( anim, animname )
			if animname == "idle" then
				widget.binder.program.binder.daemonDead:setVisible(false)
			end		
		end)	
end


local function createTargetButton( panel, widgets, unit )
	local sim = panel._hud._game.simCore
    local program = panel:getCurrentProgram()
	local canUse, reason = mainframe.canTargetUnit( sim, unit, program ) -- <<<<<<<  THIS FUNCTION
    if (not canUse and not reason) or not program.targetGuard then
        return
    end

	local wx, wy = panel._hud._game:cellToWorld( unit:getLocation() )
	local widget = findWidget( widgets, unit )
	if widget == nil then
		local wz = 12
		if unit:getTraits().breakIceOffset then
			wz = unit:getTraits().breakIceOffset
		end
		widget = panel._hud._world_hud:createWidget( world_hud.MAINFRAME, "Target", { worldx = wx, worldy = wy, worldz = wz, ownerID = unit:getID() } )
	else
		array.removeElement( widgets, widget )
	end

    panel:refreshTargetButton( widget, unit )  -- <<<<<<<  THIS FUNCTION

	return widget
end

local function createBreakIceButton( panel, widgets, unit )
	local sim = panel._hud._game.simCore
    local program = panel:getCurrentProgram()
	local canUse, reason = mainframe.canBreakIce( sim, unit, panel:getCurrentProgram() )
    if not canUse and not reason then
        return
    end

	local wx, wy = panel._hud._game:cellToWorld( unit:getLocation() )
	local widget = findWidget( widgets, unit )
	if widget == nil then
		local wz = 12
		if unit:getTraits().breakIceOffset then
			wz = unit:getTraits().breakIceOffset
		end

		local cell = sim:getCell(unit:getLocation())
		local iconUnits = {}
		for i,cellUnit in pairs(cell.units) do
			if cellUnit:getPlayerOwner() ~= sim:getPC() and cellUnit:getTraits().mainframe_ice and cellUnit:getTraits().mainframe_ice > 0 then
				if cellUnit:getTraits().breakIceOffset == unit:getTraits().breakIceOffset then
					iconUnits[cellUnit:getID()]={unit=cellUnit}
				end
			end
		end

		local idx = 0
		for i,unitIDs in pairs(iconUnits)do
			if unitIDs.unit == unit then
				break
			end
			idx = idx + 1
		end

		wz = wz + (idx*12)

		widget = panel._hud._world_hud:createWidget( world_hud.MAINFRAME, "BreakIce", { worldx = wx, worldy = wy, worldz = wz, ownerID = unit:getID() }, nil, destroyIceWidget )
	else
		array.removeElement( widgets, widget )
	end

    panel:refreshBreakIceButton( widget, unit )

	return widget
end


local function drawIceBreakers( panel )
	MOAIGfxDevice.setPenColor( BREAKICE_COLOR_TT:unpack() )

	for i, iceBreak in ipairs( panel._iceBreaks ) do
		iceBreak:onDraw()
	end
end

local function createRebootingLabel( panel, unit )
	local wx, wy = panel._hud._game:cellToWorld( unit:getLocation() )
	local wz = 16
	if unit:getTraits().breakIceOffset then
		wz =  unit:getTraits().breakIceOffset-30
	end
	local widget = panel._hud._world_hud:createWidget( world_hud.MAINFRAME, "Rebooting", { worldx = wx, worldy = wy, worldz = wz } )

	widget.binder.label:setText( STRINGS.UI.TOOLTIPS.MAINFRAME_REBOOTING )
	widget.binder.label:setColor(250/255, 253/255, 104/255,1)

	widget.binder.ring:setColor(250/255, 253/255, 104/255,1)

	widget._rebootBlinkThread = MOAICoroutine.new()
	widget._rebootBlinkThread:run( function() 
		local i = 1
		while widget:getScreen() do
			i = i - 1
			if i == 0 then
				widget.binder.label:spoolText( STRINGS.UI.TOOLTIPS.MAINFRAME_REBOOTING, 8 )
                i = 150
			end
			coroutine.yield()
		end
	end )
	widget._rebootBlinkThread:resume()

	local time = ""
	if unit:isKO() then
		time = unit:getKOTimer( )
	elseif unit:getTraits().mainframe_status then
		time = tostring(unit:getTraits().mainframe_booting )
	end

	widget.binder.timerTxt:setText( time )
	widget.binder.timerTxt:setColor(0,0,0,1)

end

local function createActivateButton( panel, unit, useName, useData, useIndex )

	local sim = panel._hud._game.simCore
	local wx, wy = panel._hud._game:cellToWorld( unit:getLocation() )
	local widget = panel._hud._world_hud:createWidget( world_hud.MAINFRAME, "Activate", { worldx = wx, worldy = wy, worldz = 16 * useIndex } )

	--emp_tooltip( hud, abilityUser, abilityOwner, self, sim, abilityOwner, STRINGS.ABILITIES.PRIME_EMP_DESC )

								 
	widget.binder.btn:setTooltip( function() return createActivateTooltip( panel._hud, unit, useData ) end )
	widget.binder.btn.onClick = util.makeDelegate( nil,
		function() 
			MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MAINFRAME_CONFIRM_ACTION )
			panel._hud._game:doAction( "mainframeAction", {action = "use", unitID = unit:getID(), fn = useData.fn } )
		end )
	widget.binder.label:setText( util.toupper(useData.name) )

	if useData.canToggle then
		widget.binder.btn:setDisabled(not useData.canToggle(unit))
	end
	return widget
end

local function refreshBreakIce( panel, primeRefresh) 
	-- Mark and sweep.
	local widgets = util.tdupe( panel._hud._world_hud:getWidgets( world_hud.MAINFRAME ) or {} )
	local localPlayer = panel._hud._game:getLocalPlayer()
	if localPlayer and localPlayer:isPC() then
		local sim = panel._hud._game.simCore
		if sim:getMainframeLockout() then
			if primeRefresh then
				panel._hud:showWarning( STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN, nil, nil, nil, true )
				MOAIFmodDesigner.playSound( "SpySociety/Actions/mainframe_deterrent_action" )
			end
		end

		for _, unitRaw in pairs(sim:getAllUnits() ) do
            if unitRaw:getTraits().mainframe_status then
                local unit = localPlayer:getLastKnownUnit( sim, unitRaw:getID() )
			    local canSee = sim:canPlayerSeeUnit( localPlayer, unit )

                if unitRaw:getLocation() and ((unitRaw:getTraits().mainframe_status == "off" and unitRaw:getTraits().mainframe_booting ) or (unitRaw:getTraits().mainframe_item and unitRaw:isKO() )) and (canSee or unit:isGhost()) then
                    createRebootingLabel( panel, unitRaw )
			    end
			
			    if unitRaw:getTraits().mainframe_item then
				    if unit:getPlayerOwner() == sim:getCurrentPlayer() and not panel._hud._game:isReplaying() then
					    if unit:getUnitData().uses_mainframe and unitRaw:getTraits().mainframe_status ~= "off" then
						    local i = 1
						    for useName, useData in pairs(unit:getUnitData().uses_mainframe) do
							    createActivateButton( panel, unit, useName, useData, i )
							    i = i + 1
						    end
					    end		

				    elseif unit:isGhost() or canSee then
                        if sim:getCell( unitRaw:getLocation() ) ~= sim:getCell( unit:getLocation() ) then
                            -- Units not in their ghosted position cannot be hacked.
                        else
					        createBreakIceButton( panel, widgets, unitRaw )
                        end
				    end
			    end
		    end	

		    if unitRaw:getTraits().isGuard and localPlayer:getEquippedProgram() and localPlayer:getEquippedProgram().targetGuard then 														    	
		    	local unit = localPlayer:getLastKnownUnit( sim, unitRaw:getID() )
			    local canSee = sim:canPlayerSeeUnit( localPlayer, unit )
		    	if unit:isGhost() or canSee then
                    if sim:getCell( unitRaw:getLocation() ) ~= sim:getCell( unit:getLocation() ) then
                        -- Units not in their ghosted position cannot be hacked.
                    else
				        createTargetButton( panel, widgets, unitRaw )
                    end
			    end
			end
        end
	end

	-- Sweep any widgets that no longer exist.
	for i, widget in ipairs(widgets) do
		if widget.iceBreak == nil then
			panel._hud._world_hud:destroyWidget( world_hud.MAINFRAME, table.remove( widgets ) )
		end
	end
end

local function onClickMainframeAbility( panel, ability, abilityOwner )
    if ability.equip_program and abilityOwner:getEquippedProgram() ~= ability then
        MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MAINFRAME_SELECT_PROGRAM )
    end

	panel._hud:transitionAbilityTarget( abilityOwner, abilityOwner, ability )
end

local function onClickDaemonIcon( panel )
    if not panel._hud:isMainframe() then
        panel._hud:showMainframe()
    end
end

local function setDaemonPanel( self, widget, ability, player )
	local sim = self._hud._game.simCore
    local clr = ability.reverseDaemon and { 0/255, 164/255, 0/255, 1 } or { 140/255, 0, 0, 1 }

    widget:setVisible( true )
    widget.binder.btn.onClick = util.makeDelegate( nil, onClickDaemonIcon, self )
	widget.binder.btn:setTooltip( ability:onTooltip( self._hud, sim, player ) )
    widget.binder.btn:setColor(unpack(clr) )
	widget.binder.icon:setImage( ability:getDef().icon )
	
    if ability.turns then
		widget.binder.firewallNum:setText(ability.turns)									
	elseif ability.duration then
		widget.binder.firewallNum:setText(ability.duration)				
    else
		widget.binder.firewallNum:setText("-")				
	end
end


local function updateButtonFromProgram( self, widget, ability, abilityOwner )
	local sim = self._hud._game.simCore
	local enabled, reason = ability:canUseAbility( sim, abilityOwner )

    local isEquipped = false
    if self._hud._state == self._hud.STATE_ABILITY_TARGET then
        isEquipped = ability == self._hud._stateData.ability
    else
        isEquipped = ability.equipped
    end

	widget:setVisible( true )
	widget.binder.powerTxt:setVisible(true)

	widget.binder.turnsTxt:setVisible(true)
	if isEquipped then
		widget.binder.powerTxt:setColor(1,1,1,1)
		widget.binder.turnsTxt:setColor(1,1,1,1)
	else
		widget.binder.powerTxt:setColor(72/255,128/255,128/255)
		widget.binder.turnsTxt:setColor(72/255,128/255,128/255)		
	end


	widget.binder.powerTxt:setText( ability:getDef():getCpuCost() or 0 )
	if ability.passive then
		widget.binder.powerTxt:setText("-")		
		widget.binder.turnsTxt:setVisible(false)
	end
	widget.binder.turnsTxt:setText(STRINGS.PROGRAMS.PWR)
	
	widget.binder.hazzardBG:setVisible(false)
	if ability.cooldown then
		if ability.cooldown > 0 then 
			widget.binder.powerTxt:setColor(140/255,1,1,1)
			widget.binder.turnsTxt:setColor(140/255,1,1,1)
		
			widget.binder.turnsTxt:setVisible(true)
			widget.binder.turnsTxt:setText(STRINGS.PROGRAMS.TURNS)
			widget.binder.powerTxt:setVisible(true)
			widget.binder.powerTxt:setText( ability.cooldown )
			widget.binder.hazzardBG:setVisible(true)
		end		
	end

	local txt = ability:getDef().huddesc 
	if ability:getDef().maxCooldown then
		txt	= txt.. "\n" .. util.sformat( STRINGS.PROGRAMS.COOLDOWN, ability:getDef().maxCooldown)
		--widget.binder.costTxt:setText(  )	
	end
	widget.binder.descTxt:setText(txt)	

	if ability:getDef():getCpuCost() then 
		for i, widget in widget.binder:forEach( "power" ) do	
			if i<=ability:getDef():getCpuCost() then
				if isEquipped then					
					widget:setColor(140/255,255/255,255/255)
				else
					widget:setColor(72/255,128/255,128/255)
				end
			else
				widget:setColor(17/255,29/255,29/255)
			end
		end
	else
		for i, widget in widget.binder:forEach( "power" ) do	
			widget:setColor(17/255,29/255,29/255)
		end
	end
	
	widget:setAlias( ability:getID() )
	widget.binder.btn:setTooltip( function() return ability:onTooltip( self._hud._screen, sim, abilityOwner ) end )
	widget.binder.btn:setDisabled( not enabled )

	self:programWidgetSetColor( widget, ability )

	if enabled then	
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickMainframeAbility, self, ability, abilityOwner )
	end
		
	if ability:getDef().icon then
		widget.binder.img:setVisible(true)
		widget.binder.img:setImage(  ability:getDef().icon )
	end
end 


local function updateProgramButtons( self, widgetName, player, primeRefresh )
	-- Show all actionables owned by unit.



	local panel = self._panel
	local sim = self._hud._game.simCore
	local programMod = sim:getParams().agency.extraPrograms or 0

	local MAX_EMPTY = 5 + programMod

	for i, widget in panel.binder.programsPanel.binder:forEach( "program" ) do
		if i > MAX_EMPTY then
			panel.binder.programsPanel.binder["empty"..i]:setVisible(false)
		else
			panel.binder.programsPanel.binder["empty"..i]:setVisible(true)
			if primeRefresh then
				panel.binder.programsPanel.binder["empty"..i]:createTransition( "activate_above")
			end		
		end
		widget:setVisible( false )
	end

	for i, ability in ipairs(player:getAbilities())do

		local widget = panel.binder.programsPanel.binder["program"..i]
		panel.binder.programsPanel.binder["empty"..i]:setVisible(false)
		updateButtonFromProgram( self, widget, ability, player )
		widget:setVisible( not sim:getMainframeLockout()  )
		widget:setVisible( true )
		if primeRefresh then
			widget:createTransition( "activate_above")
		end

	end

--[[
	for i, widget in panel.binder.programsPanel.binder:forEach( "program" ) do
		local ability
		if player then
			ability = player:getAbilities()[i]
		end

		if ability == nil or i == self._hiddenProgram then 
			
			if i <= MAX_EMPTY then 
				panel.binder.programsPanel.binder["empty"..i]:setTooltip(STRINGS.UI.TOOLTIPS.EMPTY_PROGRAM_SLOT)
				panel.binder.programsPanel.binder["empty"..i]:setVisible(true)	
				if primeRefresh then
					panel.binder.programsPanel.binder["empty"..i]:createTransition( "activate_above")
				end
			end
		else
			updateButtonFromProgram( self, widget, ability, player )
			widget:setVisible( not sim:getMainframeLockout()  )
			widget:setVisible( true )
			if primeRefresh then
				widget:createTransition( "activate_above")
			end
		end
	end
]]

end

local function updateDaemonButtons( self, widgetName, player )
	local sim = self._hud._game.simCore

	local isBusy = false

	local panel = self._panel

   	for i, widget in panel.binder.daemonPanel.binder:forEach( widgetName ) do
		isBusy = isBusy or (widget.thread and widget.thread:isBusy())
   	end
   	if isBusy then
		return
   	end

   	local pnlVisible = false 

	for i, widget in panel.binder:forEach( widgetName ) do
		local ability
		if player then
			ability = player:getAbilities()[i]
		end

		local installing = false

		for i,abilityI in ipairs( self._installing) do
			if ability == abilityI then
				installing = true
			end
		end

		if ability == nil or installing or sim:getCurrentPlayer() == nil then
			widget:setVisible( false )
		else
			setDaemonPanel( self, widget, ability, player )

			widget:setVisible( true )
			pnlVisible = true
		end
	end

	panel.binder.daemonPnlTitle:setVisible(pnlVisible)

end


------------------------------------------------------------------------------

local panel = class()

function panel:init( screen, hud )
	self._screen = screen
	self._hud = hud
	self._panel = screen.binder.mainframePnl
	self._mode = MODE_HIDDEN
	self._installing = {}
	self._iceBreaks = {}
	self._hiddenProgram = -1

	self:hide()
end

function panel:getCurrentProgram()
    local currentProgram = nil
    if self._hud._state == self._hud.STATE_ABILITY_TARGET then
        currentProgram = self._hud._stateData.ability
    else
	    local localPlayer = self._hud._game:getLocalPlayer()
	    if localPlayer then
            currentProgram = localPlayer:getEquippedProgram()
        end
    end

    return currentProgram
end


function panel:refreshTargetButton( widget, unit )
	local sim = self._hud._game.simCore
    local program = self:getCurrentProgram()
	local canUse, reason = mainframe.canTargetUnit( sim, unit, program )
    if self._hud._game:isReplaying() then
        canUse, reason = false, nil
    end

    local tooltipWidget = widget.binder.btn
    local daemonTooltip = nil
    widget:setAlias( "Target"..unit:getID() )

	widget.binder.btn:setDisabled( not canUse )
 

	widget:setVisible( true )
	widget.binder.btn:setImage( "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )
	widget.binder.btn:setDisabled( not canUse )

	if canUse then
	    widget.binder.btn:setColor(cdefs.COLOR_FREE:unpack())			
	    widget.binder.btn:setColorInactive(cdefs.COLOR_FREE:unpack())
	    widget.binder.btn:setColorActive(cdefs.COLOR_FREE_HOVER:unpack())
	    widget.binder.btn:setColorHover(cdefs.COLOR_FREE_HOVER:unpack())	

    else
		widget.binder.btn:setColor(0.5,0.5,0.5,1)		
		widget.binder.img:setColor(0.5,0.5,0.5,1)
	end

    if not canUse or program == nil or program.acquireTargets then
        widget.binder.btn.onClick = nil
        tooltipWidget:setTooltip( nil )
    else
	    widget.binder.btn.onClick = 
		    function( widget, ie )
                if unit:isValid() and mainframe.canTargetUnit( sim, unit, program ) then
				    MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MAINFRAME_CONFIRM_ACTION )
				    self._hud._game:doAction( "mainframeAction", {action = "targetUnit", unitID = unit:getID() } )
			    end
		    end
    end

    tooltipWidget:setTooltip( function()
        local nonbreakIceTooltip = include( "hud/tooltip_nonbreakice" )
        return nonbreakIceTooltip( self, widget, unit, reason )
    end )

 
end

function panel:refreshBreakIceButton( widget, unit )
	local sim = self._hud._game.simCore
    local program = self:getCurrentProgram()
	local canUse, reason = mainframe.canBreakIce( sim, unit, program )
    if self._hud._game:isReplaying() then
        canUse, reason = false, nil
    end
    
    local tooltipWidget = widget.binder.btn
    local daemonTooltip = nil
    widget:setAlias( "BreakIce"..unit:getID() )
    if not widget.iceBreak then
	    widget.binder.btn:setText(unit:getTraits().mainframe_ice)
    end
	widget.binder.btn:setDisabled( not canUse )
	if not canUse then		
		widget.binder.anim:getProp():setRenderFilter( cdefs.RENDER_FILTERS["desat"] )
	else
		widget.binder.anim:getProp():setRenderFilter( cdefs.RENDER_FILTERS["normal"] )
	end

	setFirewallIdleAnim( widget, unit )

    local programWidget = widget.binder.program
	if sim:getHideDaemons() and not unit:getTraits().daemon_sniffed then
    	programWidget:setVisible( true )
		programWidget.binder.daemonUnknown:setVisible(false)
        programWidget.binder.daemonKnown:setVisible(false)
		programWidget.binder.daemonHidden:setVisible(true)

	elseif unit:getTraits().mainframe_program ~= nil then
        programWidget:setVisible( true )

		local npc_abilities = include( "sim/abilities/npc_abilities" )
		local ability = npc_abilities[ unit:getTraits().mainframe_program ]
		if unit:getTraits().daemon_sniffed then 
			programWidget.binder.daemonUnknown:setVisible(false)
			programWidget.binder.daemonKnown:setVisible(true)
			if unit:getTraits().daemon_sniffed_revealed == nil then
				unit:getTraits().daemon_sniffed_revealed = true
				programWidget.binder.daemonKnown.binder.txt:spoolText(ability.name, 12)			
			else
				programWidget.binder.daemonKnown.binder.txt:setText(ability.name)			
			end
            daemonTooltip = programWidget.binder.daemonKnown.binder.bg
        else
			programWidget.binder.daemonKnown:setVisible(false)
    		programWidget.binder.daemonUnknown:setVisible(true)
		end	
        programWidget.binder.daemonHidden:setVisible(false)
    else
        programWidget:setVisible( false )
	end

    if not canUse or program == nil or program.acquireTargets then
        widget.binder.btn.onClick = nil
        tooltipWidget:setTooltip( nil )
    else
	    widget.binder.btn.onClick = 
		    function( widget, ie )
                if unit:isValid() and mainframe.canBreakIce( sim, unit, program ) then
				    MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MAINFRAME_CONFIRM_ACTION )
				    self._hud._game:doAction( "mainframeAction", {action = "breakIce", unitID = unit:getID() } )
			    end
		    end
    end
	if reason == "nulldrone" then
		tooltipWidget:setTooltip( function()
			local str = STRINGS.UI.REASON.SECURED
			local str2 = STRINGS.UI.REASON.SECURED_2
	        return null_tooltip( self._hud, str, str2 )
	    end )
	    widget.binder.btn:setText("-")
	else  
	    tooltipWidget:setTooltip( function()
	        local breakIceTooltip = include( "hud/tooltip_breakice" )
	        return breakIceTooltip( self, widget, unit, reason )
	    end )
	    
        if daemonTooltip then 
        	daemonTooltip:setTooltip( function() 
        		local breakIceTooltip = include( "hud/tooltip_breakice_nolines" )
            	return breakIceTooltip( self, widget, unit, reason )
        	end )
        end 
	end   
end

function panel:programWidgetSetColor( widget, ability, colorOb )
	local sim = self._hud._game.simCore
	local enabled, reason = ability:canUseAbility( sim, sim:getCurrentPlayer() )
    local isEquipped = self:getCurrentProgram() == ability
    local colorImg = util.color.WHITE
    local activeColor = colorOb

    if not colorOb then
	    if enabled then
		    if isEquipped then
                colorOb, activeColor = util.color.ORANGE, util.color.ORANGE
		    elseif ability.color then
                colorOb, activeColor, colorImg = ability.color, util.color.MID_BLUE, ability.color
		    else 
                colorOb, activeColor = util.color.MID_BLUE, util.color.WHITE
		    end	
	    else
            colorOb, activeColor = util.color.GRAY, util.color.GRAY
            colorImg = ability.color or util.color.GRAY
	    end
    end

    widget.binder.img:setColor(colorImg:unpack())

	widget.binder.btn:setColor(colorOb:unpack())
	widget.binder.btn:setColorInactive(colorOb:unpack())

	widget.binder.btn:setColorActive(activeColor:unpack())
	widget.binder.btn:setColorHover(activeColor:unpack())

	widget.binder.powerTxt:setColor(colorOb:unpack())
	widget.binder.turnsTxt:setColor(colorOb:unpack())
	widget.binder.digi:setColor( colorOb.r,colorOb.g,colorOb.b, 100/255 )
	widget.binder.descTxt:setColor(colorOb:unpack())	
end

function panel:destroyUI()
	if self._iceThread then
		self._iceThread:stop()
		self._iceThread = nil
	end
	self._hud._world_hud:destroyWidgets( world_hud.MAINFRAME )
end

function panel:hide()
	self._mode = MODE_HIDDEN
--	self._panel:setVisible( false )
	self._hud._world_hud:setMainframe( true, function() drawIceBreakers( self ) end  )
	self:destroyUI()
	self:refresh()
end

function panel:show()
	local localPlayer = self._hud._game:getLocalPlayer()
	if localPlayer == nil or self._hud._game.simCore:isGameOver() then
		return
	end

	self._mode = MODE_VISIBLE
	self._hud._world_hud:setMainframe( true )

	self:refresh(true)
end

function panel:refresh(primeRefresh)

	updateDaemonButtons( self, "enemyAbility", self._hud._game.simCore:getNPC() )
	
	if self._mode == MODE_HIDDEN then
		 self._panel.binder.programsPanel:setVisible( false )
		return
	end
    self._panel.binder.programsPanel:setVisible( true )
	updateProgramButtons( self, "program", self._hud._game.simCore:getPC(), primeRefresh)

	refreshBreakIce( self, primeRefresh)

end

function panel:onSimEvent( ev )
	local simdefs = include( "sim/simdefs" )

	if ev.eventType == simdefs.EV_UNIT_UPDATE_ICE then
		-- Acquire list of widgets that are associated with ice
		local widgets = util.tdupe( self._hud._world_hud:getWidgets( world_hud.MAINFRAME ) or {}) 
		-- Search for the widget associated with this particular ice!		
		local widget = findWidget( widgets, ev.eventData.unit )
		if ev.eventData.delta and widget and widget.iceBreak == nil then
            local breakIceThread = include( "gameplay/viz_handlers/break_ice" )
			widget.iceBreak = breakIceThread( self, widget, ev.eventData.unit )
        elseif not ev.eventData.delta and widget then
            self:refreshBreakIceButton( widget, ev.eventData.unit )
		end

		if ev.eventData.refreshAll then
			refreshBreakIce( self )
		end

	elseif ev.eventType == simdefs.EV_MAINFRAME_INSTALL_PROGRAM then
		local sim = self._hud._game.simCore
		local player = sim:getCurrentPlayer()
		MOAIFmodDesigner.playSound("SpySociety/Actions/mainframe_deterrentinstall")
		self:addMainframeProgram(  player, ev.eventData.ability, ev.eventData.idx)

	elseif ev.eventType == simdefs.EV_HIDE_PROGRAM then
		self._hiddenProgram = ev.eventData.idx

	elseif ev.eventType == simdefs.EV_SLIDE_IN_PROGRAM then
		local sim = self._hud._game.simCore
		self:slideMainframeProgram( ev.eventData.idx )

	elseif ev.eventType == simdefs.EV_MAINFRAME_PARASITE then
		rig_util.wait( 120 )
		self._hud:hideMainframe()
	elseif ev.eventType == simdefs.EV_KILL_DAEMON then
		playDaemonDeathFX(self, ev.eventData.unit)		
	end
end

function panel:addMainframeProgram( player, ability, idx)
	local widget = self._panel.binder:tryBind( "enemyAbility"..idx )
    if widget then
	    setDaemonPanel( self, widget, ability, player )

	    if not widget:hasTransition() then
		    widget:createTransition( "activate_left" )
	    end
    end
end

function panel:slideMainframeProgram( idx )
	if idx == self._hiddenProgram then 
		self._hiddenProgram = -1 
	end 

	local widget = self._panel.binder:tryBind( "program"..idx )
	if not widget:hasTransition() then
	    widget:createTransition( "activate_left" )
    end
	self:refresh() 
end 

function panel:onHudTooltip( screen, cell )
    for i, cellUnit in ipairs( cell.units ) do
        if (cellUnit:getTraits().mainframe_suppress_range or 0) > 0 then
            local nullZoneTooltip = include( "hud/tooltip_nullzone" )
            return nullZoneTooltip( self._hud, cellUnit )
        end
    end

	return nil
end


return
{
	panel = panel
}

