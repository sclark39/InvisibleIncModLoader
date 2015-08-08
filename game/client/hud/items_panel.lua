----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )
local guiex = include( "guiex" )
local array = include( "modules/array" )
local mui = include( "mui/mui")
local serverdefs = include( "modules/serverdefs" )
local simquery = include( "sim/simquery" )
local modalDialog = include( "states/state-modal-dialog" )
local inventory = include( "sim/inventory" )
local strings = include( "strings" )
local simdefs = include( "sim/simdefs" )
local mui_defs = include( "mui/mui_defs" )
local level = include( "sim/level" )

--------------------------------------------------------------------
-- In-game item management.  The item panel shows items that can be
-- placed in an agent's inventory, and triggers the appropriate pickup
-- simactions.

local function onClickPickupItem( panel, item )
	if panel._unit:getInventoryCount() >= 8 then  
		modalDialog.show(STRINGS.UI.TOOLTIP_INVENTORY_FULL )
		return
	end

	panel._hud._game:doAction( "lootItem", panel._unit:getID(), item:getID() )
end

local function onClickStealCredits( panel )
	panel._hud._game:doAction( "lootItem", panel._unit:getID(), panel._targetUnit:getID() )
end

local function onClickTransferItem( panel, unit, targetUnit, item )
	if targetUnit:getInventoryCount() >= (8 or math.huge) then
		modalDialog.show(STRINGS.UI.TOOLTIP_INVENTORY_FULL )
		return
	end

	local itemIndex = array.find( unit:getChildren(), item )
	panel._hud._game:doAction( "transferItem", unit:getID(), targetUnit:getID(), itemIndex )
	panel:refresh()

end

local function onClickDropItem( panel, unit, item )
	local itemIndex = array.find( unit:getChildren(), item )
	panel._hud._game:doAction( "transferItem", unit:getID(), -1, itemIndex )
	panel:refresh()
end

local function onClickClose( panel )
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_POPDOWN )
    local game = panel._hud._game
    panel:destroy()
end

local function setProfileImage( unit, panel )
	if unit and unit:getUnitData().profile_anim then

		panel.binder.profile:setVisible( true )
		panel.binder.agentProfileAnim:bindBuild( unit:getUnitData().profile_build or unit:getUnitData().profile_anim )
		panel.binder.agentProfileAnim:bindAnim( unit:getUnitData().profile_anim )
		panel.binder.agentProfileImg:setVisible( false )

		if unit:isKO() or unit:getTraits().iscorpse then
			panel.binder.agentProfileAnim:getProp():setRenderFilter( cdefs.RENDER_FILTERS.desat )
			panel.binder.agentProfileAnim:setPlayMode( KLEIAnim.STOP )
		else
			panel.binder.agentProfileAnim:getProp():setRenderFilter( nil )
			panel.binder.agentProfileAnim:setPlayMode( KLEIAnim.LOOP )
		end
		
	else
		panel.binder.profile:setVisible( false )
	end
end

local function setupWidgets( panelBinder, panel, unit )
	panelBinder.sell.binder.titleLbl:setText(STRINGS.UI.SHOP_INVENTORY)
	panelBinder.inventory.binder.titleLbl:setText(STRINGS.UI.SHOP_INVENTORY)
    panelBinder.inventory_bg.binder.closeBtn.onClick = util.makeDelegate( nil, onClickClose, panel )
	panelBinder.inventory_bg:setVisible(true)
	panelBinder.inventory:setVisible(true)
	panelBinder.shop_bg:setVisible(false)
    panelBinder.shop:setVisible(false)
end

-----------------------------------------------------------------------
-- Base class for items panel

local items_panel = class()

function items_panel:init( hud, unit )
	local screen = mui.createScreen( "shop-dialog.lua" )	
	mui.activateScreen( screen )

	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_POPUP )

	self._hud = hud
	self._screen = screen
    screen:addEventHandler( self, mui_defs.EVENT_DragDrop )

    local panelBinder = self._screen.binder
	setProfileImage( unit, panelBinder.sell )
end

function items_panel:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_DragDrop and ev.dragData == nil then
        self:onDragFinished()
	end
end

function items_panel:onDragFromTop( iconImg, onDragDrop )
    local widget = self._screen:startDragDrop( iconImg, "DragItem" )
    widget.binder.img:setImage( iconImg )

    local panelBinder = self._screen.binder
    panelBinder.inventory.binder.drag.onDragDrop = function() util.coDelegate( onDragDrop ) end
    return true
end

function items_panel:onDragFromBottom( iconImg, onDragDrop )
    local widget = self._screen:startDragDrop( iconImg, "DragItem" )
    widget.binder.img:setImage( iconImg )

    local panelBinder = self._screen.binder
    panelBinder.sell.binder.drag.onDragDrop = function() util.coDelegate( onDragDrop ) end
    return true
end

function items_panel:onDragFinished()
    -- Cleanup drag drop -- this happens whether or not the thing was dropped or not.
    local panelBinder = self._screen.binder
    panelBinder.sell.binder.drag.onDragDrop = nil
    panelBinder.inventory.binder.drag.onDragDrop = nil
end

function items_panel:findWidget( widgetName )
	return self._screen:findWidget( widgetName )
end

function items_panel:refreshCredits()
	local player = self._hud._game.simCore:getCurrentPlayer()
    local txt = util.sformat( STRINGS.FORMATS.CREDITS, player:getCredits() )
	self._screen:findWidget( "creditsTxt" ):setText( txt )
end

function items_panel:refresh()
	local screen = self._screen
	local lootWidget = screen:findWidget( "inventory" )
    local userWidget = screen:findWidget( "sell" )

	-- Fill out the LOOT panel.
	local itemCount = 0
	for i, widget in lootWidget.binder:forEach( "item" ) do
		if self:refreshItem( widget, i, "item" ) then
			itemCount = itemCount + 1
		end
	end

    -- Fill out the UNIT's inventory.
	local items = {}
	for i,childUnit in ipairs(self._unit:getChildren()) do
		if not childUnit:getTraits().augment or not childUnit:getTraits().installed then
			table.insert(items,childUnit)
		end
	end
	for i, widget in userWidget.binder:forEach( "item" ) do 
		self:refreshUserItem( self._unit, items[i], widget, i )
	end

    self:refreshCredits()

    -- Auto-close
	if itemCount == 0 or not self._unit:canAct() then
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_POPDOWN )
        local game = self._hud._game
		self:destroy()
	end
end

function items_panel:destroy()

	if self._targetUnit and self._hud._game.boardRig then
		self._hud._game.boardRig:getUnitRig(self._targetUnit:getID()):refresh()
	end

	self._hud._itemsPanel = nil
	mui.deactivateScreen( self._screen )
	self._screen = nil

    if self.closeevent then
        self._hud._game:dispatchScriptEvent( self.closeevent )
    end
end


function items_panel:refreshUserItem( unit, item, widget, i )

	local encumberedSpace = i > unit:getTraits().inventoryMaxSize

	if item == nil then
        guiex.updateButtonEmptySlot( widget, encumberedSpace )
		widget.binder.cost:setVisible(false)
		widget.binder.itemName:setVisible(false)
		return false

	else
        guiex.updateButtonFromItem( self._screen, nil, widget, item, unit, encumberedSpace )

		widget.binder.itemName:setVisible(true)
		local name = nil
		if item.program then
			name = item.name
		else
			name = item:getName()
		end

		widget.binder.itemName:setText( util.toupper(name) )
		widget.binder.cost:setVisible(false)

		return true
	end
end

-----------------------------------------------------------------------
-- Items panel

local loot_panel = class( items_panel )


function loot_panel:init( hud, unit, targetUnit )
	items_panel.init( self, hud, unit )
    self.closeevent = level.EV_CLOSE_LOOT_UI
	self._unit = unit
	self._targetUnit = targetUnit

    local panelBinder = self._screen.binder
    setupWidgets( panelBinder , self, unit )
	panelBinder.headerTxt:spoolText(string.format(STRINGS.UI.SHOP_LOOT, util.toupper(targetUnit:getName())))
	setProfileImage( targetUnit, panelBinder.inventory )
end


function loot_panel:refreshUserItem( unit, item, widget, i )
	if items_panel.refreshUserItem( self, unit, item, widget, i ) then
        local onTransfer = util.makeDelegate( nil, onClickTransferItem, self, unit, self._targetUnit, item )
		widget.binder.btn.onClick = onTransfer
        widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromTop", item:getUnitData().profile_icon, onTransfer )
	end

	return true
end

function loot_panel:refreshItem( widget, i )
	widget.binder.btn:setColorInactive(244/255, 255/255, 120/255)
	widget.binder.btn:setColorActive(1,1,1)
	widget.binder.btn:setColorHover(1,1,1)		

	local items = {}

	for i,childUnit in ipairs(self._targetUnit:getChildren()) do
		if not childUnit:getTraits().augment or not childUnit:getTraits().installed then
			table.insert(items,childUnit)
		end
	end
	
	local item = nil
	for _, cellUnit in ipairs( items ) do
		if inventory.canCarry( self._unit, cellUnit ) then
			i = i - 1
			if i == 0 then
				item = cellUnit
				break
			end
		end
	end

	-- Check special 'credits item'
	if i == 1 then
		local credits = simquery.calculateCashOnHand( self._hud._game.simCore, self._targetUnit )

        if credits == 0 then
            credits = self._targetUnit:getTraits().credits or 0
        end
        local bonus = 0
        if self._targetUnit:getTraits().isGuard then
			bonus = math.floor( credits * (self._unit:getTraits().stealBonus or 0))
			credits = credits + bonus
		end

		if credits > 0 then
            guiex.updateButtonCredits( widget, credits, bonus, self._targetUnit )
			
			widget.binder.itemName:setText( util.toupper(STRINGS.ITEMS.CREDCHIP) )
			widget.binder.cost:setText( util.sformat( STRINGS.FORMATS.PLUS_CREDS, credits ) )
			widget.binder.btn.onClick = util.makeDelegate( nil, onClickStealCredits, self )
            widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromBottom", cdefs.CREDITS_ICON, widget.binder.btn.onClick )
			return true
		end
	end

	-- Check special 'PWR item'
	if i == 1 then
		local PWR = simquery.calculatePWROnHand( self._hud._game.simCore, self._targetUnit )
		
		if (PWR or 0) > 0 then
            guiex.updateButtonPWR( widget, PWR )
			
			widget.binder.itemName:setText( util.sformat( STRINGS.FORMATS.PWR, PWR ))
			widget.binder.cost:setText( "" )
			widget.binder.btn.onClick = util.makeDelegate( nil, onClickStealCredits, self )
            widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromBottom", cdefs.PWR_ICON, widget.binder.btn.onClick )
			return true
		end
	end	

	if item == nil then
		widget:setVisible( false )
		return false
	else

        guiex.updateButtonFromItem( self._screen, nil, widget, item, self._unit )
		widget.binder.itemName:setText( util.toupper(item:getName() ) )
		widget.binder.cost:setText( "" )
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickPickupItem, self, item )
        widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromBottom", item:getUnitData().profile_icon, widget.binder.btn.onClick )

		return true
	end
end

-----------------------------------------------------------------------
-- Transfer panel (inventories between two units)

local transfer_panel = class( items_panel )

function transfer_panel:init( hud, unit, targetUnit )
	items_panel.init( self, hud, unit )

	self._unit = unit
	self._targetUnit = targetUnit

    local panelBinder = self._screen.binder
    setupWidgets( panelBinder, self, unit )
	panelBinder.headerTxt:spoolText( util.toupper(STRINGS.UI.ACTIONS.GIVE.TOOLTIP) )
	setProfileImage( targetUnit, panelBinder.inventory )
end

function transfer_panel:refreshItem( widget, i )
	local inventory = {}
	for i,childUnit in ipairs(self._targetUnit:getChildren()) do
		if not childUnit:getTraits().augment or not childUnit:getTraits().installed then
			table.insert(inventory,childUnit)
		end
	end		
	return self:refreshUserItem( self._targetUnit, inventory[i], widget, i )
end

function transfer_panel:refreshUserItem( unit, item, widget, i )
	if items_panel.refreshUserItem( self, unit, item, widget, i ) then
		if unit == self._unit then
            -- Transfer from SELF to OTHER.

			local enabled,reason = true, nil
			
			if self._hud._game.simCore:isVersion("0.17.5") and item:getTraits().pickupOnly and not self._targetUnit:hasTag( item:getTraits().pickupOnly ) then
				enabled = false
				reason = util.sformat(STRINGS.UI.TOOLTIPS.PICK_UP_CONDITION_DESC, util.toupper(item:getTraits().pickupOnly) )
			end

            local onTransfer = util.makeDelegate( nil, onClickTransferItem, self, unit, self._targetUnit, item )
			widget.binder.btn.onClick = onTransfer
            widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromTop", item:getUnitData().profile_icon, onTransfer )
	    
	        if reason then
	        	widget.binder.btn:setDisabled(not enabled)
	        	widget.binder.btn:setTooltip(reason)
	        end   

		elseif unit == self._targetUnit then

			local enabled,reason = true, nil
			
			if self._hud._game.simCore:isVersion("0.17.5") and item:getTraits().pickupOnly and not self._unit:hasTag( item:getTraits().pickupOnly ) then
				enabled = false
				reason = util.sformat(STRINGS.UI.TOOLTIPS.PICK_UP_CONDITION_DESC, util.toupper(item:getTraits().pickupOnly) )
			end

            -- Transfer from OTHER to SELF.
            local onTransfer = util.makeDelegate( nil, onClickTransferItem, self, unit, self._unit, item )
			widget.binder.btn.onClick = onTransfer
            widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromBottom", item:getUnitData().profile_icon, onTransfer )

	        if reason then
	        	widget.binder.btn:setDisabled(not enabled)
	        	widget.binder.btn:setTooltip(reason)
	        end               
		end
	end

	return true
end

-----------------------------------------------------------------------
-- Item pickup panel

local pickup_panel = class( items_panel )

function pickup_panel:init( hud, unit, cellx, celly )
	items_panel.init( self, hud, unit )

	self._unit = unit
	self._cellx, self._celly = cellx, celly

    local panelBinder = self._screen.binder
    setupWidgets( panelBinder , self, unit )
	panelBinder.headerTxt:setText( nil )
	setProfileImage( nil, panelBinder.inventory )
end

function pickup_panel:refreshItem( widget, i )
	widget.binder.btn:setColorInactive(244/255, 255/255, 120/255)
	widget.binder.btn:setColorActive(1,1,1)
	widget.binder.btn:setColorHover(1,1,1)		
	
	local cell = self._hud._game.simCore:getCell( self._cellx, self._celly )
	local item
	for _, cellUnit in ipairs( cell.units ) do
		if inventory.canCarry( self._unit, cellUnit ) then
			i = i - 1
			if i == 0 then
				item = cellUnit
				break
			end
		end
	end

	if item == nil then
		widget:setVisible( false )
		return false
	else

		local enabled,reason = true, nil
		
		if item:getTraits().pickupOnly and not self._unit:hasTag( item:getTraits().pickupOnly ) then
			enabled = false
			reason = util.sformat(STRINGS.UI.TOOLTIPS.PICK_UP_CONDITION_DESC, util.toupper(item:getTraits().pickupOnly) )
		end

        guiex.updateButtonFromItem( self._screen, nil, widget, item, self._unit )
		widget.binder.itemName:setText( util.toupper(item:getName() ) )
		widget.binder.cost:setText( "" )
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickPickupItem, self, item )
        widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromBottom", item:getUnitData().profile_icon, widget.binder.btn.onClick )

        if reason then
        	widget.binder.btn:setDisabled(not enabled)
        	widget.binder.btn:setTooltip(reason)
        end        
		return true
	end
end

function pickup_panel:refreshUserItem( unit, item, widget, i )
	if items_panel.refreshUserItem( self, unit, item, widget, i ) then
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickDropItem, self, unit, item )
        widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromTop", item:getUnitData().profile_icon, widget.binder.btn.onClick )
	end
	return true
end

return
{
    base = items_panel,
	loot = loot_panel,
	transfer = transfer_panel,
	pickup = pickup_panel,
}


