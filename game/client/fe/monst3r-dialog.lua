----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local game = include( "modules/game" )
local util = include("client_util")
local array = include( "modules/array" )
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local serverdefs = include( "modules/serverdefs" )
local agentdefs = include("sim/unitdefs/agentdefs")
local skilldefs = include( "sim/skilldefs" )
local modalDialog = include( "states/state-modal-dialog" )
local scroll_text = include("hud/scroll_text")
local unitdefs = include("sim/unitdefs")
local simfactory = include( "sim/simfactory" )
local guiex = include( "client/guiex" )
local cdefs = include( "client_defs" )
local rig_util = include( "gameplay/rig_util" )
local SCRIPTS = include('client/story_scripts')
local talkinghead = include('client/fe/talkinghead')

----------------------------------------------------------------
local MONST3R_DISCOUNT = 0.8
local MAX_INVENTORY = 4
----------------------------------------------------------------

local function onClickBuyFromMonst3r(self, itemData, value )

	if (not self._agency.upgrades or #self._agency.upgrades < MAX_INVENTORY) and self._agency.cash >= value then
		local result = modalDialog.showYesNo( util.sformat( STRINGS.UI.UPGRADE_SCREEN_CONFIRM_BUY, itemData.name,value), STRINGS.UI.BUY_FROM_MONST3R, nil, STRINGS.UI.BUY_FROM_MONST3R )
		if result == modalDialog.OK then

           	self.talkinghead:PlayScript( SCRIPTS.MONST3RSHOP.BUY_ITEM[math.random(#SCRIPTS.MONST3RSHOP.BUY_ITEM)])

			MOAIFmodDesigner.playSound(cdefs.SOUND_HUD_SELL)

			local oldCash = self._agency.cash 
			self._agency.cash= self._agency.cash - value 
			self._cashUpdateThreadMonster =  guiex.createCountUpThread( self.screen:findWidget("creditsTxt"), oldCash, self._agency.cash, 1, STRINGS.UI.UPGRADE_SCREEN_AVAILABLE_CREDITS)

			if not self._agency.upgrades then
				self._agency.upgrades = {}
			end
			table.insert(self._agency.upgrades, { upgradeName = itemData.id, upgradeParams = {} } )
			self._monst3r_sold = true
			self._textNum = nil
			self._agency.monst3rItem = nil
			self:refreshMonst3r()
			self:refreshAgencyUpgrades()
		else
           	self.talkinghead:PlayScript(SCRIPTS.MONST3RSHOP.NOBUY[math.random(#SCRIPTS.MONST3RSHOP.NOBUY)])
        end
	else
		if value > self._agency.cash then
			local result = modalDialog.show( STRINGS.UI.REASON.NOT_ENOUGH_CREDITS ) 
		else
			local result = modalDialog.show( STRINGS.UI.REASON.FULL_STASH ) 
		end
	end

end

local function onClickSellToMonst3r(self,itemData,upgradeIndex,rate)
    local sellValue = math.ceil(itemData.value * rate)
    local txt = util.sformat( STRINGS.UI.UPGRADE_SCREEN_CONFIRM_SELL, itemData.name, sellValue )
	local result = modalDialog.showYesNo( txt, STRINGS.UI.SELL_TO_MONST3R, nil, STRINGS.UI.SELL_TO_MONST3R )
	if result == modalDialog.OK then
        --print ("YOU SOLD TO MONSTER")
		MOAIFmodDesigner.playSound(cdefs.SOUND_HUD_SELL)

       	self.talkinghead:PlayScript(SCRIPTS.MONST3RSHOP.SELL_ITEM[math.random(#SCRIPTS.MONST3RSHOP.SELL_ITEM)])

		local oldCash = self._agency.cash 
		self._agency.cash = self._agency.cash + sellValue
		self._cashUpdateThreadMonster =  guiex.createCountUpThread( self.screen:findWidget("creditsTxt"), oldCash, self._agency.cash, 1, STRINGS.UI.UPGRADE_SCREEN_AVAILABLE_CREDITS)

		table.remove(self._agency.upgrades, upgradeIndex)
        
        self:refreshMonst3r()
		self:refreshAgencyUpgrades()
	else
        --print ("YOU DID NOT SELL TO MONSTER")
        self.talkinghead:PlayScript(SCRIPTS.MONST3RSHOP.NOSELL[math.random(#SCRIPTS.MONST3RSHOP.NOSELL)])
    end
end

local function onClickTaswellInfo(self)
	if self.taswellScriptIdx == 1 then
		self.taswellScriptIdx = 2
		self.screen:findWidget("taswellInfoBtn"):setText(STRINGS.UI.BACK)
	else
		self.taswellScriptIdx = 1
		self.screen:findWidget("taswellInfoBtn"):setText(STRINGS.UI.TASWELL_INFO_BTN)
	end

	self.talkinghead:PlayScript(SCRIPTS.MONST3RSHOP.TASWELL[self.taswellScriptIdx])
end

local function onClickCloseMonst3r(self)
    self:destroy()
end

----------------------------------------------------------------
--

local dialog = class()

function dialog:showMonst3rItem( templateName )
	local itemData = unitdefs.lookupTemplate( templateName )
	local itemUnit = simfactory.createUnit( itemData )
 	local widget = self.screen:findWidget("monst3rSellItem")
	local itemWidget = widget.binder.item
    local value = math.floor( itemData.value * MONST3R_DISCOUNT / 10 ) * 10

    guiex.updateButtonFromItem( self.screen, nil, widget, itemUnit )
	widget.binder.itemName:setText( util.toupper(string.format( itemData.name)))
    widget.binder.cost:setText( string.format( "-%d", value ))
	itemWidget.binder.btn.onClick = util.makeDelegate( nil, onClickBuyFromMonst3r, self, itemData, value )
    itemWidget.binder.btn.onDragStart = util.makeDelegate( self, "onDragMonst3r", itemData.profile_icon, itemWidget.binder.btn.onClick )
end

function dialog:refreshAgencyUpgrades()
	local sellPanel = self.screen:findWidget("sell")
	for i, widget in sellPanel.binder:forEach("item") do
		if self._agency.upgrades and self._agency.upgrades[i] then
			widget:setVisible(true)
			self:refreshAgencyUpgrade( self._agency.upgrades[i],widget,i)
		else
			guiex.updateButtonEmptySlot( widget )
			--widget:setVisible(false)
			widget.binder.cost:setVisible(false)
			widget.binder.itemName:setVisible(false)
		end
	end
end

function dialog:refreshAgencyUpgrade(upgrade,widget,upgradeIndex)
	local itemDef, upgradeParams
    if type(upgrade) == "string" then
        itemDef = unitdefs.lookupTemplate( upgrade )
    else
        upgradeParams = upgrade.upgradeParams
        itemDef = unitdefs.lookupTemplate( upgrade.upgradeName )
    end

	local itemUnit = simfactory.createUnit( util.extend( itemDef )( upgradeParams and util.tcopy( upgradeParams )), nil )
	local itemWidget = widget.binder.item

    guiex.updateButtonFromItem( self.screen, nil, itemWidget, itemUnit )

	widget.binder.cost:setVisible(true)
	widget.binder.itemName:setVisible(true)
  	widget.binder.cost:setText( string.format( "+%d", math.ceil(itemDef.value * 0.5)))
    widget.binder.itemName:setText( util.toupper(string.format( itemDef.name )))

	itemWidget.binder.btn.onClick = util.makeDelegate( nil, onClickSellToMonst3r, self,itemDef,upgradeIndex,0.5)
    itemWidget.binder.btn.onDragStart = util.makeDelegate( self, "onDragInventory", itemDef.profile_icon, itemWidget.binder.btn.onClick )
end

function dialog:refreshMonst3r()

	if self._agency.monst3rItem then
		self.screen:findWidget("monst3rSellItem"):setVisible(true)
		self:showMonst3rItem( self._agency.monst3rItem )
	else
		self.screen:findWidget("monst3rSellItem"):setVisible(false)
	end

	self.screen:findWidget("creditsTxt"):setText(string.format( STRINGS.UI.UPGRADE_SCREEN_AVAILABLE_CREDITS,self._agency.cash))
	self:refreshAgencyUpgrades()
end

function dialog:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_DragDrop and ev.dragData == nil then
       -- self.screen:findWidget( "itemBg" ):setColor( 0, 0, 0, 0.666 )
        self.screen:findWidget( "itemDrag" ).onDragDrop = nil
        self.screen:findWidget( "itemDragTxt" ):setVisible( false )
        self.screen:findWidget( "itemDragTone" ):setVisible( false )
       -- self.screen:findWidget( "sell.bg" ):setColor( 0, 0, 0, 0.666 )
        self.screen:findWidget( "sell.drag" ).onDragDrop = nil
	end
end

function dialog:onDragMonst3r( iconImg, onDragDrop )
    local widget = self.screen:startDragDrop( iconImg, "DragItem" )
    widget.binder.img:setImage( iconImg )
    widget.binder.img:setColor( cdefs.COLOR_DRAG_INVALID:unpack() )

--    self.screen:findWidget( "sell.bg" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
    self.screen:findWidget( "sell.drag" ).onDragDrop = function() util.coDelegate( onDragDrop ) end
    return true
end

function dialog:onDragInventory( iconImg, onDragDrop )
    local widget = self.screen:startDragDrop( iconImg, "DragItem" )
    widget.binder.img:setImage( iconImg )
 --   self.screen:findWidget( "itemBg" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
    self.screen:findWidget( "itemDragTxt" ):setVisible( true )
    self.screen:findWidget( "itemDragTone" ):setVisible( true )
    self.screen:findWidget( "itemDrag" ).onDragDrop = function() util.coDelegate( onDragDrop ) end
    return true
end

function dialog:show( campaign, agency )

	self.taswellEasterEgg = math.random() < (1/500)

	local screen = mui.createScreen( "modal-monst3r.lua" )
	mui.activateScreen( screen )
    self.talkinghead = talkinghead( nil, screen )
    self.talkinghead.notransitions = true

    screen:addEventHandler( self, mui_defs.EVENT_DragDrop )
	screen:findWidget("closeBtn").onClick = util.makeDelegate( nil, onClickCloseMonst3r, self)

    self._agency = agency
    self.screen = screen

    self:refreshMonst3r()

    screen:findWidget("taswellInfoBtn"):setVisible(self.taswellEasterEgg)

    if self.taswellEasterEgg then
    	self.taswellScriptIdx = 1
    	self.talkinghead:PlayScript(SCRIPTS.MONST3RSHOP.TASWELL[self.taswellScriptIdx])
    	screen:findWidget("taswellInfoBtn"):setText(STRINGS.UI.TASWELL_INFO_BTN)
    	screen:findWidget("taswellInfoBtn").onClick = util.makeDelegate( nil, onClickTaswellInfo, self)

    elseif self._agency.monst3rItem then
       	self.talkinghead:PlayScript(SCRIPTS.MONST3RSHOP.OPEN_SPECIAL[math.random(#SCRIPTS.MONST3RSHOP.OPEN_SPECIAL)])
    else
        local isEndless = campaign.difficultyOptions.maxHours == math.huge

        local plot_num = campaign.monsterPlotPoint or 0
        if not isEndless and plot_num <= campaign.currentDay and plot_num < 4 then
            --Monster tells you stories when he doesn't have anything special to sell. Until he runs out of stories for the day.
            plot_num = plot_num + 1
            self.talkinghead:PlayScript(SCRIPTS.MONST3RSHOP.PLOT_POINTS[plot_num])    
            campaign.monsterPlotPoint = plot_num
        else
            self.talkinghead:PlayScript(SCRIPTS.MONST3RSHOP.OPEN_NO_SPECIALS[math.random(#SCRIPTS.MONST3RSHOP.OPEN_NO_SPECIALS)])    
        end
    end
    
end

function dialog:destroy()
    if self._cashUpdateThreadMonster then
        self._cashUpdateThreadMonster:stop()
        self._cashUpdateThreadMonster = nil
    end
    mui.deactivateScreen( self.screen )
    if self.onClose then
        self.onClose()
    end
end


return dialog


