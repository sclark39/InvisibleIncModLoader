----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local guiex = include( "client/guiex" )
local array = include( "modules/array" )
local gameobj = include( "modules/game" )
local mui_defs = include( "mui/mui_defs")
local mui_util = include( "mui/mui_util" )
local targets = include( "hud/targeting" )
local world_hud = include( "hud/hud-inworld" )
local agent_actions = include( "hud/agent_actions" )
local simquery = include( "sim/simquery" )
local level = include( "sim/level" )
local upgrade_dialog = include("hud/upgrade_dialog")

--------------------------------------------------------------------
--

local buttonLocator = class()

function buttonLocator:init( hud )
	self.cells = {}
	self.hud = hud
end

function buttonLocator:findLocation( worldx, worldy, worldz )
	local cellx, celly = self.hud._game:worldToCell( worldx, worldy )
	local cell = self.hud._game.simCore:getCell( cellx, celly )
	self.cells[ cell ] = (self.cells[ cell ] or -1) + 1

	return worldx, worldy, (worldz or 0) -- + 18 * self.cells[ cell ]
end

local function getProfileIcon( ability, sim, abilityOwner, abilityUser, hasTarget )
	if ability.getProfileIcon then
        return ability:getProfileIcon( sim, abilityOwner, abilityUser, hasTarget )
    else
        return ability.profile_icon
    end
end

local function generateTooltipReason( tooltip, reason )
	if reason then
		return tooltip .. "\n<c:ff0000>" .. reason .. "</>"
	else
		return tooltip
	end
end

local function canUseAbility( self, sim, ability, abilityOwner, abilityUser, ... )
	return abilityUser:canUseAbility( sim, ability, abilityOwner, ... )
end

local function canUseAction( self, action )
	return action.enabled, action.reason
end


local function onClickAbilityAction( self, widget, abilityOwner, abilityUser, ability )
	self._hud._game:dispatchScriptEvent( level.EV_HUD_CLICK_BUTTON, widget:getAlias() )
	self._hud:transitionAbilityTarget( abilityOwner, abilityUser, ability )
end


local function onClickMainframeAbility( self, ability, abilityOwner )
	self._hud:transitionAbilityTarget( abilityOwner, abilityOwner, ability )
end


local function onClickAgentProfileBtn( self )
	local upgradeDialog = upgrade_dialog(self._hud._game)
	upgradeDialog:show(self.hud,self._unit)
end



local function refreshItemTargetting( self, item )
	local cellTargets = buttonLocator( self._hud )
	local iterfn = util.tnext( item:getAbilities(), function( ability ) return agent_actions.shouldShowAbility( self._hud._game, ability, item, self._unit ) end )
	local ability = iterfn()
	while ability do
		assert( item:getUnitOwner() or error( item:getName() ))
		local result, target = self:addAbilityTargets( cellTargets, ability, item, item:getUnitOwner() )
		if target then
			self._hud._stateData.targetHandler = target
			self._hud._stateData.ability = ability
		end
		ability = iterfn()
	end
end

local function onClickAbilityHotkey( self, reason )
    -- Should only be called if the widget is in fact disabled.
	local sim = self._hud._game.simCore
    local isEndless = sim:getParams().difficultyOptions.maxHours == math.huge
    local campaignHours = sim:getParams().campaignHours
        
    local level= "SpySociety/HUD/voice/level1/"

    MOAIFmodDesigner.playSound(level.."alarmvoice_warning")
    self._hud:showWarning( STRINGS.UI.WARNING_CANT_USE, {r=1,g=1,b=1,a=1}, reason )
end

local function onClickItem( self, widget, item, itemUser)
    if self._hud._game:isReplaying() then
        -- Don't allow item use during replay, as this item may no longer be valid after replay is complete.
    else
	    self._hud._game:dispatchScriptEvent( level.EV_HUD_CLICK_BUTTON, widget:getAlias() )
	    self._hud:transitionItemTarget( item, itemUser )
    end
end

local function updateButtonFromActionTarget( self, widget, item )
	local enabled, reason = canUseAction( self, item )

	widget:setVisible( true )
	widget.binder.btn:setImage( item.icon )
	widget.binder.label:setText( util.toupper( item.txt ))
	widget:setAlias( item.txt )-- Name this widget so it can be searched for by tutorial.
	widget.binder.btn:setTooltip( item.tooltip )
	widget.binder.btn.onClick = item.onClick
	widget.binder.btn:setDisabled( not enabled )
	widget.binder.btn:setHotkey( item.hotkey )

	if item.onHotkey then
		widget.binder.btn.onHotkey = util.makeDelegate( nil, item.onHotkey, self, reason )
	end			

	if enabled then
	    widget.binder.btn:setColor(cdefs.COLOR_FREE:unpack())			
	    widget.binder.btn:setColorInactive(cdefs.COLOR_FREE:unpack())
	    widget.binder.btn:setColorActive(cdefs.COLOR_FREE_HOVER:unpack())
	    widget.binder.btn:setColorHover(cdefs.COLOR_FREE_HOVER:unpack())	

    else
		widget.binder.btn:setColor(0.5,0.5,0.5,1)		
		widget.binder.img:setColor(0.5,0.5,0.5,1)
	end
end



local function updateButtonFromAbilityTarget( self, widget, ability, abilityOwner, abilityUser, ... )
	local sim = self._hud._game.simCore
	local profileIcon = getProfileIcon( ability, sim, abilityOwner, abilityUser, true )
	local enabled, reason = canUseAbility( self, sim, ability, abilityOwner, abilityUser, ... )
	local abilityTargets = {...}

	widget:setVisible( true )

	widget:setAlias( ability:getID() )-- Name this widget so it can be searched for by tutorial.
	widget.binder.btn:setImage( profileIcon )
	widget.binder.btn:setDisabled( not enabled )
	widget.binder.btn:setHotkey( ability.hotkey )

	widget.binder.label:setText( util.toupper( ability:getName( sim, abilityOwner, abilityUser, ... )))
	if ability.onTooltip then
		widget.binder.btn:setTooltip( function() return ability:onTooltip( self._hud, sim, abilityOwner, abilityUser, unpack(abilityTargets) ) end )

	elseif ability.createToolTip then
		widget.binder.btn:setTooltip( generateTooltipReason( ability:createToolTip( sim, abilityOwner, abilityUser, ... ), reason ))
	else
		widget.binder.btn:setTooltip(nil)
	end

	widget.binder.btn.onClick = util.makeDelegate( nil,
		function( btn )
			if agent_actions.performAbility( self._hud._game, abilityOwner, abilityUser, ability, unpack(abilityTargets) ) then
                btn.onClick = nil
				self:clearTargets()
				self._hud._game:dispatchScriptEvent( level.EV_HUD_CLICK_BUTTON, ability:getID() )
			end
		end )

	if enabled then

		if ability.iconColor then
			widget.binder.img:setColor(ability.iconColor:unpack())
			widget.binder.btn:setColor(ability.iconColor:unpack())
			widget.binder.btn:setColorInactive(ability.iconColor:unpack())
			widget.binder.btn:setColorActive(ability.iconColorHover:unpack())
			widget.binder.btn:setColorHover(ability.iconColorHover:unpack())	

		elseif ability.usesAction then
			widget.binder.img:setColor(cdefs.COLOR_ATTACK:unpack())
			widget.binder.btn:setColor(cdefs.COLOR_ATTACK:unpack())
			widget.binder.btn:setColorInactive(cdefs.COLOR_ATTACK:unpack())
			widget.binder.btn:setColorActive(cdefs.COLOR_ATTACK_HOVER:unpack())
			widget.binder.btn:setColorHover(cdefs.COLOR_ATTACK_HOVER:unpack())			

		elseif ability.usesMP then
			widget.binder.img:setColor(cdefs.COLOR_ACTION:unpack())
			widget.binder.btn:setColor(cdefs.COLOR_ACTION:unpack())
			widget.binder.btn:setColorInactive(cdefs.COLOR_ACTION:unpack())
			widget.binder.btn:setColorActive(cdefs.COLOR_ACTION_HOVER:unpack())
			widget.binder.btn:setColorHover(cdefs.COLOR_ACTION_HOVER:unpack())				
		else
			widget.binder.img:setColor(cdefs.COLOR_FREE:unpack())
			widget.binder.btn:setColor(cdefs.COLOR_FREE:unpack())			
			widget.binder.btn:setColorInactive(cdefs.COLOR_FREE:unpack())
			widget.binder.btn:setColorActive(cdefs.COLOR_FREE_HOVER:unpack())
			widget.binder.btn:setColorHover(cdefs.COLOR_FREE_HOVER:unpack())				
		end
	else
		widget.binder.btn:setColor(0.5,0.5,0.5,1)
		widget.binder.img:setColor(0.5,0.5,0.5,1)
	end
end

local function updateButtonAbilityPopup( self, widget, ability, abilityOwner, abilityUser, ... )

	local buttonWidget = nil
	for i, widget in self._hud._screen.binder.agentPanel.binder.inventory.binder:forEach( "inv" ) do
		if widget._item then
			local abilities = widget._item:getAbilities()
			for i,itemAbility in ipairs(abilities) do
				if itemAbility == ability then
					buttonWidget = widget
					break
				end
			end			
		end
	end

	updateButtonFromAbilityTarget( self, widget, ability, abilityOwner, abilityUser, ...)

	buttonWidget._popUps = buttonWidget._popUps + 1
	local bx, by = buttonWidget:getAbsolutePosition()
	local bx1,by1 = self._hud._screen.binder.agentPanel:getAbsolutePosition()
	by = by + (buttonWidget._popUps*0.05)

	widget:setPosition(bx,by)
end

local function checkforSamePopup(self)
	if not self._popUpsSelected or #self._popUpsSelected ~= #self._popUps then
		return false
	else

		for i,element in ipairs(self._popUps)do

			if not self._popUpsSelected[i] or element.ability:getID() ~= self._popUpsSelected[i].ability:getID() then
				return false
			end
		end

		return true
	end
end

local function refreshPopUp(self)
	local group = self._hud._screen.binder.agentPanel.binder.inventoryGroup
	
	if checkforSamePopup(self) then
		
		for i, widget in group.binder.inventory.binder.popUp.binder:forEach( "action" ) do		
			if  self._popUpsSelected[i] then
				widget:setVisible(true)
				widget:createTransition( "deactivate_below_popup",
						function( transition )
							widget:setVisible( false )
						end,
					 { easeOut = true } )				
			else 
				widget:setVisible(false)
			end
		end
		self._popUps = {}
		self._popUpsSelected = nil
		self._hud:transitionNull()
	else

		if #self._popUps > 0 then	
			
			group.binder.inventory_title:setVisible(false)
			group.binder.inventory.binder.popUp:setVisible(true)
			
			local abilityBtn = nil

			for i, widget in group.binder.inventory.binder.popUp.binder:forEach( "action" ) do		
				if i<= #self._popUps then
					widget:createTransition( "activate_below_popup" )
					widget:setVisible(true)


					local ability = self._popUps[i].ability
					local abilityOwner = self._popUps[i].abilityOwner
					local abilityUser = self._popUps[i].abilityUser
					local unitID = self._popUps[i].unitID

					abilityBtn = ability

					updateButtonFromAbilityTarget( self, widget, ability, abilityOwner, abilityUser, unitID)
				else
					widget:setVisible(false)
				end
			end

			local buttonWidget = nil
			for i, widget in self._hud._screen.binder.agentPanel.binder.inventory.binder:forEach( "inv" ) do
				if widget._item then
					local abilities = widget._item:getAbilities()
					for i,itemAbility in ipairs(abilities) do
						if itemAbility == abilityBtn then
							buttonWidget = widget
							break
						end
					end			
				end
			end

            if buttonWidget then
			    local lx,ly = buttonWidget:getPosition()
			    local lx1,ly1 = group.binder.inventory.binder.popUp:getPosition()
			    group.binder.inventory.binder.popUp:setPosition(lx,ly1)
            end

			self._popUpsSelected = self._popUps

		else
			group.binder.inventory_title:setVisible(true)
			group.binder.inventory.binder.popUp:setVisible(false)		
		end

	end
end

local function updateButtonFromAbility( self, widget, ability, abilityOwner )
	local sim = self._hud._game.simCore
	local enabled, reason = canUseAbility( self, sim, ability, abilityOwner, self._unit)

	widget:setVisible( true )

	widget:setAlias( ability:getID() )
	assert(abilityOwner)
	widget.binder.btn:setImage( getProfileIcon( ability, sim, abilityOwner, self._unit) )
	widget.binder.btn:setDisabled( not enabled )

	if ability.createToolTip then	
		widget.binder.btn:setTooltip( function()
            if self._unit and not self._unit._isPlayer then
                return generateTooltipReason( ability:createToolTip( sim, abilityOwner, self._unit ), reason )
            end
        end )
	elseif ability.onTooltip then
		widget.binder.btn:setTooltip( function()
            if self._unit and not self._unit._isPlayer then
                return ability:onTooltip( self._hud, sim, abilityOwner, self._unit )
            end
        end )
	else
		widget.binder.btn:setTooltip( nil )
	end

    if not enabled then
	    widget.binder.btn.onHotkey = util.makeDelegate( nil, onClickAbilityHotkey, self, reason )
    else
        widget.binder.btn.onHotkey = nil
    end
	widget.binder.btn.onClick = util.makeDelegate( nil, onClickAbilityAction, self, widget, abilityOwner, self._unit, ability )
	widget.binder.btn:setHotkey( ability.hotkey )

	if enabled then
		if ability.iconColor then
			widget.binder.img:setColor(ability.iconColor:unpack())
			widget.binder.btn:setColor(ability.iconColor:unpack())
			widget.binder.btn:setColorInactive(ability.iconColor:unpack())
			widget.binder.btn:setColorActive(ability.iconColorHover:unpack())
			widget.binder.btn:setColorHover(ability.iconColorHover:unpack())	
			
		elseif ability.usesAction then
			
			widget.binder.btn:setColor(cdefs.COLOR_ATTACK:unpack())
			widget.binder.btn:setColorInactive(cdefs.COLOR_ATTACK:unpack())
			widget.binder.btn:setColorActive(cdefs.COLOR_ATTACK_HOVER:unpack())
			widget.binder.btn:setColorHover(cdefs.COLOR_ATTACK_HOVER:unpack())			

		elseif ability.usesMP then
			
			widget.binder.btn:setColor(cdefs.COLOR_ACTION:unpack())
			widget.binder.btn:setColorInactive(cdefs.COLOR_ACTION:unpack())
			widget.binder.btn:setColorActive(cdefs.COLOR_ACTION_HOVER:unpack())
			widget.binder.btn:setColorHover(cdefs.COLOR_ACTION_HOVER:unpack())		

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
end

local function updateButtonFromItem( self, widget, item, unit, encumbered )
    guiex.updateButtonFromItem( self._hud._screen, self._hud._game, widget, item, unit, encumbered )
	widget.binder.btn.onClick = util.makeDelegate( nil, onClickItem, self, widget, item, unit )
end

local function updateButtonFromAction( self, widget, action )
	local enabled, reason = canUseAction( self, action )
	widget:setVisible( true )
	widget.binder.btn:setImage( action.icon )
	widget.binder.btn:setDisabled( not enabled )
	widget.binder.btn.onClick = action.onClick
	widget.binder.btn:setTooltip( generateTooltipReason( action.tooltip, reason ) )
	widget.binder.btn:setHotkey( nil )

	if ability.iconColor then
		widget.binder.img:setColor(ability.iconColor:unpack())
		widget.binder.btn:setColor(ability.iconColor:unpack())
		widget.binder.btn:setColorInactive(ability.iconColor:unpack())
		widget.binder.btn:setColorActive(ability.iconColorHover:unpack())
		widget.binder.btn:setColorHover(ability.iconColorHover:unpack())	
			
	elseif action.usesAction then
		
		widget.binder.btn:setColor(cdefs.COLOR_ATTACK:unpack())
		widget.binder.btn:setColorInactive(cdefs.COLOR_ATTACK:unpack())
		widget.binder.btn:setColorActive(cdefs.COLOR_ATTACK_HOVER:unpack())
		widget.binder.btn:setColorHover(cdefs.COLOR_ATTACK_HOVER:unpack())		
	else		
		
		widget.binder.btn:setColor(cdefs.COLOR_FREE:unpack())			
		widget.binder.btn:setColorInactive(cdefs.COLOR_FREE:unpack())
		widget.binder.btn:setColorActive(cdefs.COLOR_FREE_HOVER:unpack())
		widget.binder.btn:setColorHover(cdefs.COLOR_FREE_HOVER:unpack())	
	end
end

local function refreshPlayerInfo( unit, binder )
	binder.bioIcon:setVisible(false)
	-- Updates the agent information for the current unit (profile image, brief info text)
	
	--binder.agentProfileImg:setVisible(true)
	--binder.agentProfileImg:setImage("gui/profile_icons/profile_incognita.png")
	--binder.agentProfileAnim:setVisible(false)
    binder.agentInfo:setVisible( true )
	binder.agentName:setText( STRINGS.UI.INCOGNITA_NAME )
	binder.agentProfileBtn:setDisabled(true)
	binder.agentProfileBtn.onClick = nil
	binder.agentProfileBtn:setTooltip()

	binder.agentProfileAnim:getProp():setRenderFilter( nil )
	binder.agentProfileImg:setVisible(false)
	binder.agentProfileAnim:setVisible(true)
	binder.agentProfileAnim:bindAnim( "portraits/incognita_face" )
	binder.agentProfileAnim:bindBuild( "portraits/incognita_face" )

end

local function refreshAgentInfo( unit, binder, self )
	-- Updates the agent information for the current unit (profile image, brief info text)
    binder.agentInfo:setVisible( true )
	if unit:getUnitData().profile_anim then
		binder.agentProfileImg:setVisible(false)
		binder.agentProfileAnim:setVisible(true)
		binder.agentProfileAnim:bindBuild( unit:getUnitData().profile_build or unit:getUnitData().profile_anim )
		binder.agentProfileAnim:bindAnim( unit:getUnitData().profile_anim )
		if unit:isKO() or unit:getTraits().iscorpse then
			binder.agentProfileAnim:getProp():setRenderFilter( cdefs.RENDER_FILTERS.desat )
			binder.agentProfileAnim:setPlayMode( KLEIAnim.STOP )
		else
			binder.agentProfileAnim:getProp():setRenderFilter( nil )
			binder.agentProfileAnim:setPlayMode( KLEIAnim.LOOP )
		end
	else
		binder.agentProfileImg:setVisible(true)
		binder.agentProfileAnim:setVisible(false)
		binder.agentProfileImg:setImage( unit:getUnitData().profile_icon )	
	end
	
	binder.bioIcon:setVisible(false)

	if not unit:isGhost() and unit:isPC() and unit:getPlayerOwner():findAgentDefByID( unit:getID() ) ~= nil then
		binder.bioIcon:setVisible(true)
		binder.agentProfileBtn.onClick = util.makeDelegate( nil,  onClickAgentProfileBtn, self )
		binder.agentProfileBtn:setTooltip(STRINGS.UI.AGENT_PANEL_CLICK_FOR_DETAILS)
		binder.agentProfileBtn:setDisabled(false)
	else	
		binder.agentProfileBtn.onClick = nil
		binder.agentProfileBtn:setTooltip()
		binder.agentProfileBtn:setDisabled(true)
	end

	binder.agentName:setText( util.toupper( unit:getName() ) )
end

local function refreshAbilityTargetting( self )
	self:addAbilityTargets( buttonLocator( self._hud ), self._hud._stateData.ability, self._hud._stateData.abilityOwner, self._hud._stateData.abilityUser )
	self._hud._stateData.targetHandler = self._targets[ #self._targets ]
end

local POTENTIAL_ACTIONS =
{
	0, 0,
	1, 0,
	-1, 0,
	0, 1,
	0, -1,
	2, 0,
	-2, 0,
	0, 2,
	0, -2,
	1, 1,
	1, -1,
	-1, 1,
	-1, -1,
}

local function refreshContextActions( self, sim, unit, binder )
	local actions = {}
	local cellTargets = buttonLocator( self._hud )

	if not self._hud._game:isReplaying() and unit:getPlayerOwner() ~= nil and
        unit:getPlayerOwner() == sim:getCurrentPlayer() and
        unit:getPlayerOwner() == self._hud._game:getLocalPlayer() and not unit:isGhost() then
		-- List context sensitive actions
		local x, y = unit:getLocation()
		for i = 1, #POTENTIAL_ACTIONS, 2 do
			local dx, dy = POTENTIAL_ACTIONS[i], POTENTIAL_ACTIONS[i+1]
			agent_actions.generatePotentialActions( self._hud, actions, unit, x + dx, y + dy )
		end

		-- Check actions on units in cell
		for i,childUnit in ipairs(unit:getChildren()) do
			-- Check proxy abilities.
			for j, ability in ipairs( childUnit:getAbilities() ) do
				if agent_actions.shouldShowProxyAbility( self._hud._game, ability, childUnit, unit, actions ) then
					table.insert( actions, { ability = ability, abilityOwner = childUnit, abilityUser = unit, priority = ability.HUDpriority } )
				end
			end
		end
	end
	table.sort( actions, function( a0, a1 ) return (a0.priority or math.huge) > (a1.priority or math.huge) end )

	-- Show all actionables owned by unit.
	for i, widget in binder:forEach( "dynaction" ) do
		local item = table.remove( actions )
		while true do
			if item and item.ability then
				if self:addAbilityTargets( cellTargets, item.ability, item.abilityOwner, item.abilityUser ) then
					item = table.remove( actions )
				else
					if self._hud:canShowElement( "abilities" ) then
						updateButtonFromAbility( self, widget, item.ability, unit )						
					else
						widget:setVisible(false)
					end
					break
				end
			elseif item then
				if self:addActionTargets( cellTargets, item ) then
					item = table.remove( actions )
				else
					if self._hud:canShowElement( "abilities" ) then
						updateButtonFromAction( self, widget, item )						
					else
						widget:setVisible(false)
					end
					break
				end
			else
				widget:setVisible(false)
				break
			end
		end
	end
end


local function refreshItemPanel( self, unit, items, maxItems, widgetGroup )
    local slotCount = 0
    local hasEncumbered = false
	for i, widget in widgetGroup.binder:forEach( "inv" ) do
		local item = items[i]
		if unit:getPlayerOwner() ~= self._hud._game:getLocalPlayer() then			
			widget:setVisible(false)

		elseif item then
			local encumbered = false
			if unit:getTraits().inventoryMaxSize and 
				i > unit:getTraits().inventoryMaxSize and 
				not (item:getTraits().augment and item:getTraits().installed) then
				encumbered = true
				hasEncumbered = true
			end
			updateButtonFromItem( self, widget, item, unit, encumbered )
            slotCount = slotCount + 1

		elseif i <= maxItems then
			-- Open slot
            guiex.updateButtonEmptySlot( widget )
			widget._item = nil
            slotCount = slotCount + 1

		else
			widget._item = nil
			widget:setVisible(false)
		end
	end
    return slotCount, hasEncumbered
end

local function refreshInventory( self, unit, binder )
	local items, augments = {}, {}
	-- List items
	for i, childUnit in ipairs( unit:getChildren() ) do
		if childUnit:getTraits().augment and childUnit:getTraits().installed then
			table.insert( augments, childUnit )	
		else
			table.insert( items, childUnit )
		end
	end

	self._panel.binder.inventory_title:setVisible(true)
	self._panel.binder.inventory:setVisible(true)

    local augmentCount = refreshItemPanel( self, unit, augments, unit:getTraits().augmentMaxSize or 0, self._panelAugments.binder.augments )
    local invCount, encumbered = refreshItemPanel( self, unit, items, unit:getTraits().inventoryMaxSize or 0, self._panelInventory.binder.inventory )

    if encumbered then
    	self._panel.binder.titletxt:setText( STRINGS.UI.HUD_INVENTORY_ENCUMBERED )
    else
    	self._panel.binder.titletxt:setText( STRINGS.UI.HUD_INVENTORY )
    end

	for i, widget in self._panelInventory.binder.inventory.binder:forEach( "inv" ) do
        widget.binder.btn:setHotkey( string.byte(i) )
    end

    -- Dynamically nudge inventory panel next to augment panel.
    self._panelInventory:setBoundsHandler(
        function( component )
	        local x0, y0 = self._panelAugments:getPosition()
	        if augmentCount == 0 then
	        	component._x, component._y = x0, y0
	        else
            	component._x, component._y = x0 + 42 * augmentCount + 42, y0
        	end
        end )
end

-----------------------------------------------------------------------------------------
--

local agent_panel = class()

function agent_panel:init( hud, screen )
	self._hud = hud
	self._screen = screen
	self._panel = screen.binder.agentPanel
	self._panelInventory = screen.binder.inventoryGroup
	self._panelAugments = screen.binder.augmentGroup
	self._panelActions = screen.binder.actionsGroup
	self._panelDead = screen.binder.deadpanel
	self._targets = {}
	self._popUps = {}
	self._popUpsSelected = nil

	self:refreshPanel( nil )
end

function agent_panel:addActionTargets( cellTargets, item )
	local game, sim = self._hud._game, self._hud._game.simCore
	local wx, wy, wz = game:cellToWorld( item.x, item.y )
	wx, wy, wz = cellTargets:findLocation( wx, wy, (item.z or 0) )
	local widget = self._hud._world_hud:createWidget( world_hud.HUD, "Target", { worldx = wx, worldy = wy, worldz = wz, layoutID = item.layoutID } )
	updateButtonFromActionTarget( self, widget, item )
	return true
end

function agent_panel:addAbilityTargets( cellTargets, ability, abilityOwner, abilityUser )
	local game, sim = self._hud._game, self._hud._game.simCore
	local target
	if ability.acquireTargets then
		-- Targetted ability.  Show all targets.
		target = ability:acquireTargets( targets, game, sim, abilityOwner, abilityUser )
	elseif ability.showTargets then
		target = ability:showTargets( targets, game, sim, abilityOwner, abilityUser )
	end

	if target and not ability.noTargetUI then
		if target:hasTargets() then
			if target.startTargeting then
				target:startTargeting( cellTargets )
			end
			table.insert( self._targets, target )
		end
		if ability.showTargets then
			return false, target
		end
		return true, target

	elseif abilityOwner ~= abilityUser then
		local cell
	
		if abilityOwner:getLocation() then
			cell = sim:getCell( abilityOwner:getLocation() )

			local wx, wy, wz = game:cellToWorld( cell.x, cell.y )
			wx, wy, wz = cellTargets:findLocation( wx, wy )
			local widget = self._hud._world_hud:createWidget( world_hud.HUD, "Target",{ worldx = wx, worldy = wy, worldz = wz, layoutID = abilityOwner:getID() } )

			updateButtonFromAbilityTarget( self, widget, ability, abilityOwner, abilityUser )			
		else
			table.insert(self._popUps,{ ability=ability, abilityOwner=abilityOwner, abilityUser=abilityUser})
		end

		return true
	end



	return false
end

function agent_panel:clearTargets()
	while #self._targets > 0 do
		local target = table.remove( self._targets )
		if target.endTargeting then
			target:endTargeting( self._hud )
		end
	end

	self._hud._world_hud:destroyWidgets( world_hud.HUD )
end

function agent_panel:refreshPanel( swipein )
	self._popUps, self._popUpsSelected = {}, nil
	-- Refreshes the entire panel with information about 'unit'.  If unit == nil, this implies hiding the panel.
	local sim = self._hud._game.simCore
	
	self:clearTargets()

    local unit
    if not self._hud._game:isReplaying() then
        if self._hud:isMainframe() then
            unit = self._hud._game:getLocalPlayer()
        else
            unit = self._hud:getSelectedUnit()
        end
    end

	if unit and (unit._isPlayer or unit:getLocation()) then
		local button_layout = include( "hud/button_layout" )
		self._unit = unit
		if unit.getLocation then
            local wx, wy = self._hud._game:cellToWorld( unit:getLocation() )
            local layout = button_layout( wx, wy )
            layout:addStaticLayout( wx, wy, 0 )
            layout:addStaticLayout( wx, wy, config.TUNING.FLAG_HEIGHT or 64 )

			self._hud._world_hud:setLayout( world_hud.HUD, layout )
		end
	else
		self._unit = nil
	end

	if self._unit == nil  then
		self._panel:setVisible( false )	
        self._panel.binder.agentInfo:setVisible( false )
		self._panelInventory:setVisible( false )	
		self._panelAugments:setVisible( false )			
		self._panelActions:setVisible( false )
		self._panelDead:setVisible(false)


		if self._hud._state == self._hud.STATE_ABILITY_TARGET then
			refreshAbilityTargetting( self )
		end

	else
		self._panel:setVisible(  self._hud:canShowElement( "agentPanel" ) )

		if unit._isPlayer then
			refreshPlayerInfo( unit, self._panel.binder )

			self._panelInventory:setVisible(false)
			self._panelAugments:setVisible(false)
			self._panelActions:setVisible(false)
			self._panelDead:setVisible(false)


		else
			refreshAgentInfo( unit, self._panel.binder, self )

            -- Abilities panel
		    if self._hud:canShowElement( "abilities" ) and unit:isPC() then

				
				if unit:isKO() then
					self._panelActions:setVisible(false)
					self._panelDead:setVisible(true)
				    if swipein then
					    self._panelDead:createTransition( "activate_left" )
				    end
				elseif #unit:getAbilities() > 0 then
					self._panelDead:setVisible(false)
				    self._panelActions:setVisible( true )
				    if swipein then
					    self._panelActions:createTransition( "activate_left" )
				    end
				else
					self._panelDead:setVisible(false)
					self._panelActions:setVisible( false )
				end

            else
    			self._panelActions:setVisible(false)
    			self._panelDead:setVisible(false)
		    end

            -- Inventory panel
            if self._hud:canShowElement( "inventoryPanel" ) and unit:isPC() then

            	if unit:getTraits().inventoryMaxSize and unit:getTraits().inventoryMaxSize > 0 then
    				self._panelInventory:setVisible(true)
    			else
    				self._panelInventory:setVisible(false)
    			end
    			if unit:getTraits().augmentMaxSize and unit:getTraits().augmentMaxSize > 0 then
			    	self._panelAugments:setVisible(true)
				else
					self._panelAugments:setVisible(false)
				end

			    refreshInventory( self, unit, self._panel.binder )
			    if swipein then
				    self._panelAugments:createTransition( "activate_left" )
				    self._panelInventory:createTransition( "activate_left" )
			    end
            else
            	self._panelInventory:setVisible(false)
			    self._panelAugments:setVisible(false)
    		end

            if self._hud._state == self._hud.STATE_ABILITY_TARGET then
				refreshAbilityTargetting( self )
			elseif self._hud._state == self._hud.STATE_ITEM_TARGET then
				refreshItemTargetting( self, self._hud._stateData.item )
			else
				refreshContextActions( self, sim, unit, self._panel.binder )
			end
		end
	end
	refreshPopUp(self)
end

return
{
	agent_panel = agent_panel,
	refreshAgentInfo = refreshAgentInfo,
	updateButtonFromAbilityTarget = updateButtonFromAbilityTarget,
	buttonLocator = buttonLocator
}

