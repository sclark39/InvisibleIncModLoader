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

----------------------------------------------------------------
-- Locals

local SET_COLOR = {r=244/255,g=255/255,b=120/255, a=1}
local POSSIBLE_COLOR = {r=56/255,g=96/255,b=96/255, a=1}
local BLANK_COLOR = {r=12/255,g=17/255,b=16/255, a=1}
local HOVER_COLOR = {r=255/255,g=255/255,b=255/255, a=1}
local HOVER_COLOR_FAIL = {r=178/255,g=0/255,b=0/255, a=1}
local TEST_COLOR = {r=0/255,g=184/255,b=0/255, a=1}
local LOCKED_COLOR = {r=255/255,g=150/255,b=19/255, a=1}
local LOCKED_BLANK = {r=12/255,g=17/255,b=17/255, a=1}

local ACTIVE_BG = { 140/255, 255/255, 255/255,1 }
local INACTIVE_BG = { 78/255, 136/255, 136/255,1 }
local SELECTED_BG = { 140/255, 255/255, 255/255,1 }

----------------------------------------------------------------
-- Adapts an agentDef to a unitDef.

local skillOwner = class()

function skillOwner:init( agentDef )
    assert( agentDef )
    self.agentDef = agentDef
end

function skillOwner:getTraits()
    local unitdefs = include ( "sim/unitdefs" )
	return unitdefs.lookupTemplate( self.agentDef.template ).traits
end

function skillOwner:getLocation()
    return nil
end

function skillOwner:hasSkill( skillID, level )
    return array.findIf( self.agentDef.skills, function( s ) return s.skillID == skillID and s.level >= level end )
end

----------------------------------------------------------------
-- Encapsulates a set of skill changes

local skillChanges = class()

function skillChanges:init( upgradeScreen )
    self.changes = {}
    self.upgradeScreen = upgradeScreen
end

function skillChanges:countChanges( agentIdx, skillIdx )
    local count = 0
    for i, change in ipairs( self.changes ) do
        if change.skillIdx == skillIdx and change.agentIdx == agentIdx then
            count = count + 1
        end
    end
    return count
end

function skillChanges:hasChanges( agentIdx, skillIdx )
    return self:countChanges( agentIdx, skillIdx ) > 0
end

function skillChanges:learnSkill( agentIdx, skillIdx )
    local agency = self.upgradeScreen._agency
    local agentDef = agency.unitDefs[ agentIdx ]
    local skill = agentDef.skills[ skillIdx ]
	local skillDef = skilldefs.lookupSkill( skill.skillID )
    local cost = skillDef[ skill.level + 1 ].cost

    -- Subtract cost, increase skill.
    if agency.cash >= cost then
        table.insert( self.changes, { skillIdx = skillIdx, agentIdx = agentIdx } )
        skill.level = skill.level + 1
	    agency.cash = agency.cash - cost
        return true

    else
        return false
    end
end

function skillChanges:undoSkill( agentIdx, skillIdx )
    for i, change in ipairs( self.changes ) do
        if change.skillIdx == skillIdx and change.agentIdx == agentIdx then
            local agency = self.upgradeScreen._agency
            local agentDef = agency.unitDefs[ agentIdx ]
            local skill = agentDef.skills[ skillIdx ]
        	local skillDef = skilldefs.lookupSkill( skill.skillID )
            local cost = skillDef[ skill.level ].cost

            -- Return cost, decrease skill
            skill.level = skill.level - 1
        	agency.cash = agency.cash + cost

            table.remove( self.changes, i )
            break
        end
    end
end

function skillChanges:undoAll()
    while #self.changes > 0 do
        local change = self.changes[1]
        self:undoSkill( change.skillIdx, change.agentIdx )
    end
end

----------------------------------------------------------------
local upgradeScreen = {}

local function onEnterSpool( widget )
	widget:spoolText( widget:getText() )
end

local function countInstalledAugments( agentDef, templateName )
    local count = 0
    for i, upgrade in ipairs(agentDef.upgrades) do
    	local unitData
        if type(upgrade) == "string" and (templateName == nil or upgrade == templateName) then
            unitData = unitdefs.lookupTemplate( upgrade )
        elseif (templateName == nil or upgrade.upgradeName == templateName) then
            unitData = unitdefs.lookupTemplate( upgrade.upgradeName )
        end
        if unitData and unitData.traits.augment then
            if unitData.traits.installed or (upgrade.upgradeParams and upgrade.upgradeParams.traits and upgrade.upgradeParams.traits.installed) then
                count = count + 1
            end
        end
    end
    return count
end

local function getMaxAug( agentDef, index )
    local augmentMaxSize = unitdefs.lookupTemplate( agentDef.template ).traits.augmentMaxSize
    for i, upgrade in ipairs(agentDef.upgrades) do
        if upgrade == "augmentUpgradeSlot" then
            augmentMaxSize = augmentMaxSize + 1
        end
    end
    return augmentMaxSize
end

local function onClickUndoSkill( self, agentIdx, skillIdx )
	MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/upgrade_cancel_unit")

	local oldCash = self._agency.cash 
    self.changes:undoSkill( agentIdx, skillIdx )

    if self._cashUpdateThread then
        self._cashUpdateThread:stop()
    end
    self._cashUpdateThread = guiex.createCountUpThread( self.screen:findWidget("agencyCredits"), oldCash, self._agency.cash, 1, STRINGS.UI.UPGRADE_SCREEN_AVAILABLE_CREDITS)

	self:refreshSkills( self._agency.unitDefs[ agentIdx ], agentIdx )
	self:refreshInventory( self._agency.unitDefs[ agentIdx ], agentIdx )
end

local function onClickLearnSkill( self, agentIdx, skillIdx )
    if self.changes:learnSkill( agentIdx, skillIdx ) then
		MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/upgrade_select_unit")

        self:refreshCredits()
	    self:refreshSkills( self._agency.unitDefs[ agentIdx ], agentIdx )
	    self:refreshInventory( self._agency.unitDefs[ agentIdx ], agentIdx )
	else
		MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/upgrade_cancel_unit")
		modalDialog.show( STRINGS.UI.REASON.NOT_ENOUGH_CREDITS )
	end
end

local function onClickMonst3r(self)
	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/HUD_Monster_Open" )

	if self._incomingBlinkThread then
		self._incomingBlinkThread:stop()
	end	

	self.screen:findWidget("monst3rIncoming"):setVisible(false)

    local dialog = include( "fe/monst3r-dialog" )
    dialog.onClose = function()
        self:refreshCredits()
        self:refreshInventory( self._agency.unitDefs[ self._selectedIndex ], self._selectedIndex )
    end
	
	local user = savefiles.getCurrentGame()
	local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
    dialog:show( campaign, self._agency )
end

local function onClickInv(self, unit, unitDef, upgrade, index, itemIndex, stash )

	if stash then
		if self._agency.upgrades and #self._agency.upgrades >= 4 then
			MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/upgrade_cancel_unit")
			modalDialog.show( STRINGS.UI.REASON.FULL_STASH )
		else
			MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/HUD_ItemStorage_PutIn")
			if not self._agency.upgrades then
				self._agency.upgrades ={}
			end
			table.insert(self._agency.upgrades,upgrade)
			table.remove(unitDef.upgrades,itemIndex)
		end
	else
		if unit:getInventoryCount( ) >= 8 then
			MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/upgrade_cancel_unit")
			modalDialog.show( STRINGS.UI.REASON.INVENTORY_FULL )
		else	
			MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/HUD_ItemStorage_TakeOut")		
			table.insert(unitDef.upgrades,upgrade)
			table.remove(self._agency.upgrades,itemIndex)
		end		
	end
	self:refreshInventory(unitDef,index)
end

local function onClickMap(self)
	statemgr.deactivate( upgradeScreen )

	local user = savefiles.getCurrentGame()
	local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]

	local stateMapScreen = include( "states/state-map-screen" )
	statemgr.activate( stateMapScreen(), campaign, self.suppress_map_intro )
end

local function onRollOver(self,skill,skillDef,index,k)
	self:displaySkill(skillDef, skill.level)
end

local function onRollOut(self,skill,skillDef,index,k)
	self:clearCurrentlyDisplayedSkill()
end


local function onRollOverPlus(self,skill,skillDef,index,k)
	local level = skill.level + 1
	if skill.level < skillDef.levels then
		if self._agency.cash >= skillDef[level].cost then 				
			self.screen:findWidget("skill"..index..".bar"..level..".bar"):setColor(HOVER_COLOR.r,HOVER_COLOR.g,HOVER_COLOR.b,HOVER_COLOR.a)			
		else
			self.screen:findWidget("skill"..index..".bar"..level..".bar"):setColor(HOVER_COLOR_FAIL.r,HOVER_COLOR_FAIL.g,HOVER_COLOR_FAIL.b,HOVER_COLOR_FAIL.a)			
		end	
	end
end

local function onRollOutPlus(self,skill,skillDef,index,k)
	local level = skill.level + 1
	if skill.level < skillDef.levels then
		self.screen:findWidget("skill"..index..".bar"..level..".bar"):setColor(POSSIBLE_COLOR.r,POSSIBLE_COLOR.g,POSSIBLE_COLOR.b,POSSIBLE_COLOR.a)
	end
end


local function onRollOverMinus(self,skill,skillDef,index,k)
	local level = skill.level
    if self.changes:hasChanges( k, index ) then
		self.screen:findWidget("skill"..index..".bar"..level..".bar"):setColor(HOVER_COLOR.r,HOVER_COLOR.g,HOVER_COLOR.b,HOVER_COLOR.a)			
	end
end

local function onRollOutMinus(self,skill,skillDef,index,k)
	local level = skill.level 
    if self.changes:hasChanges( k, index ) then
		self.screen:findWidget("skill"..index..".bar"..level..".bar"):setColor(TEST_COLOR.r,TEST_COLOR.g,TEST_COLOR.b,TEST_COLOR.a)
	end
end

local function refreshAgentButton( widget, isSelected )
    if isSelected then
        widget.binder.img:setColor( 1, 1, 1, 1 )
        widget.binder.btn:setColorInactive( unpack(SELECTED_BG) )
    else
        widget.binder.img:setColor( 1, 1, 1, 0.5 )
        widget.binder.btn:setColorInactive( unpack(INACTIVE_BG) )
    end
    widget.binder.btn:updateImageState()
end

----------------------------------------------------
local tooltip = class()

function tooltip:init( panel,skill,skillDef,index, k )
	self._panel = panel
 	self._skill = skill
 	self._skillDef = skillDef
 	self._index = index
 	self._k = k 
end

function tooltip:activate( screen )
	onRollOver(self._panel, self._skill, self._skillDef, self._index, self._k)	
end

function tooltip:deactivate( screen )
	onRollOut(self._panel, self._skill, self._skillDef, self._index, self._k)
end

function tooltip:setPosition( )
end

----------------------------------------------------
local tooltipBtnPlus = class()

function tooltipBtnPlus:init( panel,skill,skillDef,index, k )
	self._panel = panel
 	self._skill = skill
 	self._skillDef = skillDef
 	self._index = index
 	self._k = k 
end

function tooltipBtnPlus:activate( screen )
	onRollOver(self._panel, self._skill, self._skillDef, self._index, self._k)
	onRollOverPlus(self._panel, self._skill, self._skillDef, self._index, self._k)
end

function tooltipBtnPlus:deactivate( screen )
	onRollOut(self._panel, self._skill, self._skillDef, self._index, self._k)
	onRollOutPlus(self._panel, self._skill, self._skillDef, self._index, self._k)
end

function tooltipBtnPlus:setPosition( )
end


----------------------------------------------------
local tooltipBtnMinus = class()

function tooltipBtnMinus:init( panel,skill,skillDef,index, k )
	self._panel = panel
 	self._skill = skill
 	self._skillDef = skillDef
 	self._index = index
 	self._k = k 
end

function tooltipBtnMinus:activate( screen )
	onRollOver(self._panel, self._skill, self._skillDef, self._index, self._k)
	onRollOverMinus(self._panel, self._skill, self._skillDef, self._index, self._k)
end

function tooltipBtnMinus:deactivate( screen )
	onRollOut(self._panel, self._skill, self._skillDef, self._index, self._k)
	onRollOutMinus(self._panel, self._skill, self._skillDef, self._index, self._k)
end

function tooltipBtnMinus:setPosition( )
end


----------------------------------------------------------------


upgradeScreen.clearCurrentlyDisplayedSkill = function(self)
	self.screen.binder.tipTitle:setText(STRINGS.UI.UPGRADE_SCREEN_SELECT_UPGRADE)

	for i, bar in self.screen.binder:forEach( "metterBar" ) do 
		bar.binder.bar:setColor(POSSIBLE_COLOR.r,POSSIBLE_COLOR.g,POSSIBLE_COLOR.b,100/255)
		bar.binder.cost:setVisible(false)
		bar.binder.level:setVisible(false)
		bar.binder.txt:setVisible(false)				
	end
end

upgradeScreen.displaySkill = function(self, skillDef, level)

	self.screen.binder.tipTitle:setText( util.sformat(STRINGS.UI.UPGRADE_SCREEN_UPGRADE_TITLE, util.toupper(skillDef.name)) )

	for i, bar in self.screen.binder:forEach( "metterBar" ) do 
		if i <= level then
			bar.binder.bar:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
		elseif i <= skillDef.levels then
			bar.binder.bar:setColor(POSSIBLE_COLOR.r,POSSIBLE_COLOR.g,POSSIBLE_COLOR.b,POSSIBLE_COLOR.a)
		else
			bar.binder.bar:setColor(BLANK_COLOR.r,BLANK_COLOR.g,BLANK_COLOR.b,BLANK_COLOR.a)
		end

		if i <= skillDef.levels then
			bar.binder.cost:setVisible(true)
			bar.binder.level:setVisible(true)
			bar.binder.txt:setVisible(true)

			bar.binder.cost:setText( util.sformat( STRINGS.FORMATS.CREDS, skillDef[i].cost ))
			bar.binder.level:setText( util.sformat( STRINGS.FORMATS.LEVEL, i ))
			bar.binder.txt:setText(skillDef[i].tooltip)	

			if i <= level then
				bar.binder.cost:setColor(0,0,0,1)
			else
				bar.binder.cost:setColor(140/255,1,1,1)
			end
		else
			bar.binder.cost:setVisible(false)
			bar.binder.level:setVisible(false)
			bar.binder.txt:setVisible(false)				
		end		
	end
end

upgradeScreen.refreshSkills = function( self, unitDef, k )

	local skills = unitDef.skills

	for i, skillWidget in self.screen.binder.skillGroup.binder:forEach( "skill" ) do 
		if i <= #skills then
			skillWidget:setVisible(true)
			local skill = skills[i]
			local skillDef = skilldefs.lookupSkill( skill.skillID )

			skillWidget.binder.skillTitle:setText(util.toupper(skillDef.name))
			skillWidget.binder.btnBack.onClick = util.makeDelegate( nil, onClickUndoSkill, self, k, i )	
			skillWidget.binder.btnFwd.onClick = util.makeDelegate( nil, onClickLearnSkill, self, k, i )	
			
			if skill.level < skillDef.levels and not self._lockedSkills[i] then 			
				local currentLevel = skillDef[ skill.level +1 ]
				skillWidget.binder.costTxt:setText( util.sformat( STRINGS.FORMATS.CREDITS, currentLevel.cost ))
				skillWidget.binder.btn:setDisabled(true) 							
				skillWidget.binder.btnFwd:setVisible(true)
							
			else 
				skillWidget.binder.btnFwd:setVisible(false)
				skillWidget.binder.costTxt:setText( STRINGS.UI.UPGRADE_SCREEN_MAX )
				skillWidget.binder.btn:setDisabled(true) 				
			end

            skillWidget.binder.btnBack:setVisible( self.changes:hasChanges( k, i ) )

			for j,bar in skillWidget.binder:forEach( "bar" ) do
				if j <=  skill.level - self.changes:countChanges( k, i ) then
					if self._lockedSkills[i] then
						bar.binder.bar:setColor(LOCKED_COLOR.r,LOCKED_COLOR.g,LOCKED_COLOR.b,LOCKED_COLOR.a)
					else
						bar.binder.bar:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
					end
				elseif j <= skill.level  then
					bar.binder.bar:setColor(TEST_COLOR.r,TEST_COLOR.g,TEST_COLOR.b,TEST_COLOR.a)
				elseif j <= skillDef.levels then
					if self._lockedSkills[i] then
						bar.binder.bar:setColor(LOCKED_BLANK.r,LOCKED_BLANK.g,LOCKED_BLANK.b,LOCKED_BLANK.a)
					else
						bar.binder.bar:setColor(POSSIBLE_COLOR.r,POSSIBLE_COLOR.g,POSSIBLE_COLOR.b,POSSIBLE_COLOR.a)
					end
				else
					bar.binder.bar:setColor(BLANK_COLOR.r,BLANK_COLOR.g,BLANK_COLOR.b,BLANK_COLOR.a)
				end
			end
			skillWidget.binder.btn:setColor(1,0,0,1)
		
			local toolTip = tooltip(self,skill,skillDef,i, k)
			skillWidget:setTooltip(toolTip) 

			local tooltipBtnPlus = tooltipBtnPlus(self,skill,skillDef,i, k)
			skillWidget.binder.btnFwd:setTooltip(tooltipBtnPlus) 
			local tooltipBtnMinus = tooltipBtnMinus(self,skill,skillDef,i, k)
			skillWidget.binder.btnBack:setTooltip(tooltipBtnMinus) 

		else
			skillWidget:setVisible(false)
			if not self._firstTime then
				for i, widget in self.screen.binder.skillGroup.binder:forEach("num") do 
					local x0, y0 = widget:getPosition()
					widget:setPosition(x0, y0+40)
				end
			end
		end
	end

	self._firstTime = true
end

function upgradeScreen:refreshCredits()
    if self._cashUpdateThread then
        self._cashUpdateThread:stop()
        self._cashUpdateThread = nil
    end

    local cashAvailable = string.format(STRINGS.UI.UPGRADE_SCREEN_AVAILABLE_CREDITS, self._agency.cash)
	self.screen:findWidget("agencyCredits"):setText( cashAvailable )
end

function upgradeScreen:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_DragDrop and ev.dragData == nil then
        self.screen:findWidget( "storageDragHilite" ):setColor( 0, 0, 0, 0.666 )
        self.screen:findWidget( "dragHilite" ):setColor( 0, 0, 0, 0.666 )
        self.screen:findWidget( "drag" ).onDragDrop = nil
        self.screen:findWidget( "storageDrag" ).onDragDrop = nil
	end
end

function upgradeScreen:onDragToAugments( upgrade, item )
    if item:getTraits().augment then
        local agentDef = self._agency.unitDefs[ self._selectedIndex ]
		if countInstalledAugments( agentDef ) >= getMaxAug( agentDef, self._selectedIndex ) then
            modalDialog.show( STRINGS.ABILITIES.TOOLTIPS.NO_AUGMENT_SLOTS_AVAILABLE )
            return
        end

		if not item:getTraits().stackable and countInstalledAugments( agentDef, item:getUnitData().id ) > 0 then
            modalDialog.show( STRINGS.ABILITIES.TOOLTIPS.AUGMENT_ALREADY_INSTALLED )
            return
        end

        local result = modalDialog.showYesNo( util.sformat( STRINGS.UI.UPGRADE_SCREEN_AUGMENT_CONFIRM, item:getName() ))
        if result == modalDialog.OK then
            if upgrade.upgradeParams.traits == nil then
                upgrade.upgradeParams.traits = {}
            end
            upgrade.upgradeParams.traits.installed = true
            if self._agency.upgrades and array.find( self._agency.upgrades, upgrade ) ~= nil then
                -- Installing from Storage: transfer item.
                array.removeElement( self._agency.upgrades, upgrade )
                table.insert( agentDef.upgrades, upgrade )
            end

			if item:getTraits().modSkill then
				local oldCash = self._agency.cash 
				local changes = self.changes:countChanges( self._selectedIndex, item:getTraits().modSkill )
				if changes > 0 then
					for n=1,changes do
						self.changes:undoSkill( self._selectedIndex, item:getTraits().modSkill )
					end
				end
				if oldCash ~= self._agency.cash then
		        	self._cashUpdateThread = guiex.createCountUpThread( self.screen:findWidget("agencyCredits"), oldCash, self._agency.cash, 1, STRINGS.UI.UPGRADE_SCREEN_AVAILABLE_CREDITS)
		        end

				agentDef.skills[item:getTraits().modSkill].level = item:getTraits().modSkillStat
				
			end

            --MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_INSTALL )
            MOAIFmodDesigner.playSound( "SpySociety/VoiceOver/Incognita/Pickups/Augment_Installed" )
            self:refreshInventory( agentDef, self._selectedIndex )
            self:refreshSkills( agentDef, self._selectedIndex )
        end
    end
end

function upgradeScreen:onDragStorage( upgrade, item, onDragDrop )
    local widget = self.screen:startDragDrop( item, "DragItem" )
    widget.binder.img:setImage( item:getUnitData().profile_icon )
    self.screen:findWidget( "dragHilite" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
    self.screen:findWidget( "drag" ).onDragDrop = function() util.coDelegate( onDragDrop ) end
    self.screen:findWidget( "dragAugment" ).onDragDrop = function() util.coDelegate( self.onDragToAugments, self, upgrade, item ) end
    return true
end

function upgradeScreen:onDragInventory( upgrade, item, onDragDrop )
    local widget = self.screen:startDragDrop( item, "DragItem" )
    widget.binder.img:setImage( item:getUnitData().profile_icon )
    self.screen:findWidget( "storageDragHilite" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
    self.screen:findWidget( "storageDrag" ).onDragDrop = function() util.coDelegate( onDragDrop ) end
    self.screen:findWidget( "dragAugment" ).onDragDrop = function() util.coDelegate( self.onDragToAugments, self, upgrade, item ) end
    return true
end

upgradeScreen.refreshInventory = function( self, unitDef, index )
	self._lockedSkills = {}
	local inventory, augments = {}, {}
	local augLimit = getMaxAug( unitDef, index )
    local unit = simfactory.createUnit( unitdefs.createUnitData( unitDef ), nil )

	for i,item in ipairs(unitDef.upgrades) do
		local itemDef, upgradeParams
	    if type(unitDef.upgrades[i]) == "string" then
	        itemDef = unitdefs.lookupTemplate( unitDef.upgrades[i] )
	    else
	        upgradeParams = unitDef.upgrades[i].upgradeParams
	        itemDef = unitdefs.lookupTemplate( unitDef.upgrades[i].upgradeName )
	    end
        if itemDef then
		    local itemUnit = simfactory.createUnit( util.extend( itemDef )( upgradeParams and util.tcopy( upgradeParams )), nil )
	        if itemUnit:getTraits().augment and itemUnit:getTraits().installed then
	        	if itemUnit:getTraits().modSkillLock then
	        		for p,skill in ipairs(itemUnit:getTraits().modSkillLock) do
	        			self._lockedSkills[skill] = true
	        		end
	        	end
	            table.insert(augments,itemUnit)
	        else
	            table.insert(inventory,{item=itemUnit,upgrade=unitDef.upgrades[i],index = i })
	        end
        end
	end

	local invLimit = unit:getTraits().inventoryMaxSize
	for i, widget in self.screen.binder:forEach( "inv_" ) do
		local encumbered = i > invLimit
		if inventory[i] then
            guiex.updateButtonFromItem( self.screen, nil, widget, inventory[i].item, skillOwner( unitDef ), encumbered )
			widget.binder.btn.onClick = util.makeDelegate( nil, onClickInv, self, unit, unitDef, inventory[i].upgrade, index, inventory[i].index, true )
            widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragInventory", inventory[i].upgrade, inventory[i].item, widget.binder.btn.onClick )
		else	
            guiex.updateButtonEmptySlot( widget, encumbered )
		end
	end	

	
	for i, widget in self.screen.binder:forEach( "aug_" ) do
		if augments[i] then
            guiex.updateButtonFromItem( self.screen, nil, widget, augments[i], skillOwner( unitDef ) )			
		else
			if i > augLimit then
				widget:setVisible(false)
			else
                guiex.updateButtonEmptySlot( widget )
			end
		end
	end	


	for i, widget in self.screen.binder:forEach( "agency_inv_" ) do
		if self._agency.upgrades and  self._agency.upgrades[i] then
			local itemDef, upgradeParams
            if type(self._agency.upgrades[i]) == "string" then
                itemDef = unitdefs.lookupTemplate( self._agency.upgrades[i] )
            else
                upgradeParams = self._agency.upgrades[i].upgradeParams
                itemDef = unitdefs.lookupTemplate( self._agency.upgrades[i].upgradeName )
            end
			local itemUnit = simfactory.createUnit( util.extend( itemDef )( upgradeParams and util.tcopy( upgradeParams )), nil )

            guiex.updateButtonFromItem( self.screen, nil, widget, itemUnit, skillOwner( unitDef ) )
			widget.binder.btn.onClick = util.makeDelegate( nil, onClickInv, self, unit, unitDef, self._agency.upgrades[i], index, i, false)			
            widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragStorage", self._agency.upgrades[i], itemUnit, widget.binder.btn.onClick )

		else
            guiex.updateButtonEmptySlot( widget )
		end
	end	
end


upgradeScreen.selectIncognita = function( self, unitDef )

	self.screen:findWidget("programPnl"):setVisible(true)
	self.screen:findWidget("agentPnl"):setVisible(false)

	self.screen:findWidget("incognitaSplash"):createTransition("activate_left")
	self.screen:findWidget("incognitaTitle"):spoolText(util.toupper(STRINGS.UI.INCOGNITA_TITLE))

	local widget = self.screen:findWidget("progList")
	local abilitydefs = include( "sim/abilitydefs" )	

	for i, abilityID in ipairs(self._agency.abilities)do

		local ability = abilitydefs.lookupAbility( abilityID )
		local newwidget = widget:addItem(ability.name)	


		newwidget.binder.nameTxt:setText(ability.name)
		newwidget.binder.programTip1:setText(ability.desc)
		newwidget.binder.programTip2:setVisible(false)

		if ability.cpu_cost and ability.cpu_cost >= 1 then
			newwidget.binder.powerTxt:setText(ability.cpu_cost)
		else
			newwidget.binder.powerTxt:setText("-")
		end

		if ability.icon then
			newwidget.binder.img:setVisible(true)
			newwidget.binder.img:setImage(  ability.icon )
		end

	end



	for i, widget in self.screen:findWidget("programPnl").binder:forEach( "prog" ) do	
		
			widget:setVisible(false)

			widget.binder.nameTxt:setColor(17/255,29/255,29/255)
			widget.binder.programTip1:setColor(17/255,29/255,29/255)
			widget.binder.programTip2:setVisible(false)

			widget.binder.img:setVisible(false)		
			widget.binder.digi:setVisible(false)	
			widget.binder.PWR:setVisible(false)	
			widget.binder.powerTxt:setVisible(false)	
			widget.binder.frame:setColor(1,1,1,0.5)
		--[[
		local abilitydefs = include( "sim/abilitydefs" )	

		if i <= #self._agency.abilities then

			widget.binder.programTip1:setColor(253/255,250/255,104/255)
			widget.binder.programTip2:setColor(1140/255,255/255,255/255)
			local abilityID = self._agency.abilities[i]
			local ability = abilitydefs.lookupAbility( abilityID )

			widget:setVisible( true )
			widget.binder.nameTxt:setText(ability.name)
			widget.binder.programTip1:setText(ability.desc)
			widget.binder.programTip2:setVisible(false)

			if ability.cpu_cost >= 1 then
				widget.binder.powerTxt:setText(ability.cpu_cost)
			else
				widget.binder.powerTxt:setText("-")
			end

			if ability.icon then
				widget.binder.img:setVisible(true)
				widget.binder.img:setImage(  ability.icon )
			end
		else
			
			widget.binder.nameTxt:setColor(17/255,29/255,29/255)
			widget.binder.programTip1:setColor(17/255,29/255,29/255)
			widget.binder.programTip2:setVisible(false)

			widget.binder.img:setVisible(false)		
			widget.binder.digi:setVisible(false)	
			widget.binder.PWR:setVisible(false)	
			widget.binder.powerTxt:setVisible(false)	
			widget.binder.frame:setColor(1,1,1,0.5)
		end
		]]
	end
	

    for i, widget in self.screen.binder:forEach( "agent" ) do
        refreshAgentButton( widget, false )
    end
    refreshAgentButton( self.screen:findWidget( "incognita" ), true )
end

upgradeScreen.selectAgent = function( self, unitDef, index )

	self.screen:findWidget("programPnl"):setVisible(false)
	self.screen:findWidget("agentPnl"):setVisible(true)

    if self._selectedIndex == index then
        return
    end

    self._selectedIndex = index 
	local data = agentdefs[unitDef.template]
	self.screen:findWidget("agentTitle"):spoolText(util.toupper(data.name))
	self.screen:findWidget("splashImage"):setImage(data.splash_image)

	self.screen:findWidget("splashImage"):createTransition("activate_left")


	self:clearCurrentlyDisplayedSkill()
	
	self.refreshInventory(self,unitDef,index)
	self:refreshSkills( unitDef, index )
    
    for i, widget in self.screen.binder:forEach( "agent" ) do
        refreshAgentButton( widget, i == index )
    end
    refreshAgentButton( self.screen:findWidget( "incognita" ), false )
end

upgradeScreen.populateScreen = function( self )
	--loop over all members of the agency
    for i, widget in self.screen.binder:forEach( "agent" ) do
        local agentDef = self._agency.unitDefs[ i ]
        if agentDef then
		    local data = agentdefs[ agentDef.template ]
    		widget.binder.img:setImage(data.profile_icon_64x64)
    		widget.binder.btn.onClick = util.makeDelegate( nil, upgradeScreen.selectAgent, self, self._agency.unitDefs[i], i )
        else
            widget.binder.btn:setDisabled( true )
        end
	end

	-- INCOGNITA
	local widget = self.screen:findWidget("incognita")
    widget.binder.img:setImage("gui/profile_icons/incognita_64x64.png")
    widget.binder.btn.onClick = util.makeDelegate( nil, upgradeScreen.selectIncognita, self )

    if self._cashUpdateThread then
        self._cashUpdateThread:stop()
    end
	self._cashUpdateThread = guiex.createCountUpThread( self.screen:findWidget("agencyCredits"), 0, self._agency.cash, 1, STRINGS.UI.UPGRADE_SCREEN_AVAILABLE_CREDITS)

	self:selectAgent(self._agency.unitDefs[1], 1 )
end

function upgradeScreen:hideMonst3r()
	self.screen:findWidget("monst3r"):setVisible(false)
	self.screen:findWidget("monst3rBtn"):setVisible(false)
	self.screen:findWidget("monst3rIncoming"):setVisible(false)
end

function upgradeScreen:showMonst3r()
	self.screen:findWidget("monst3rIncoming"):setVisible(false)
	if self._agency.monst3rItem then
		self._blinkTimes = 0
		self._incomingBlinkThread = MOAICoroutine.new()
		self._incomingBlinkThread:run( function() 
			local i = 0
			while true do
				i = i + 1
				if i % 60 == 0 then
					if self._blinkTimes <= 5 then
						MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/HUD_Monster_ForSale" )
					end
					self._blinkTimes = self._blinkTimes + 1
					self.screen:findWidget("monst3rIncoming"):setVisible(true)

				elseif i % 30 == 0 then
					self.screen:findWidget("monst3rIncoming"):setVisible(false)
				end

				coroutine.yield()
			end
		end )
		self._incomingBlinkThread:resume()	
	end

	self.screen:findWidget("monst3rBtn").onClick = util.makeDelegate( nil, onClickMonst3r, self)
end

function upgradeScreen:onLoad( agency, endless, is_post_mission, suppress_map_intro )

	self.suppress_map_intro = suppress_map_intro
	self.screen = mui.createScreen( "upgrade_screen.lua" )
	mui.activateScreen( self.screen )
	
    self._selectedIndex = nil
	self._agency = agency
	self.changes = skillChanges( self )

	self._scroll_text = scroll_text.panel( self.screen.binder.bg )

	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )

	if not MOAIFmodDesigner.isPlaying("theme") then
		MOAIFmodDesigner.playSound("SpySociety/Music/music_map","theme")		
	end

	self.screen:findWidget("acceptBtn.btn").onClick = util.makeDelegate( nil, onClickMap, self)
	self.screen:findWidget("acceptBtn.btn"):setText(STRINGS.UI.MAP)

	local user = savefiles.getCurrentGame()	
	local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
	
	if not endless and is_post_mission and campaign.missionCount == 1 then
		--hide monster if we haven't met him yet
        self:hideMonst3r()
	else
        self:showMonst3r()
	end

    self.screen:addEventHandler( self, mui_defs.EVENT_DragDrop )
	
	self:populateScreen()
end

upgradeScreen.onUnload = function ( self )
	MOAIFmodDesigner.stopSound("voice" )
	if self._voiceCoroutine then
		self._voiceCoroutine:stop()
		self._voiceCoroutine = nil
	end	
    if self._cashUpdateThread then
        self._cashUpdateThread:stop()
        self._cashUpdateThread = nil
    end
    if self._incomingBlinkThread then
    	self._incomingBlinkThread:stop()
    	self._incomingBlinkThread = nil
    end
	self._scroll_text:destroy()
	mui.deactivateScreen( self.screen )
end

return upgradeScreen
