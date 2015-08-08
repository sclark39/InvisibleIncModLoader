----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local util = include( "client_util" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local gameobj = include( "modules/game" )
local cdefs = include("client_defs")
local modalDialog = include( "states/state-modal-dialog" )
local simfactory = include( "sim/simfactory" )
local guiex = include( "client/guiex" )
local skilldefs = include( "sim/skilldefs" )

----------------------------------------------------------------
-- Local functions

local SET_COLOR = {r=244/255,g=255/255,b=120/255, a=1}
local POSSIBLE_COLOR = {r=0/255,g=184/255,b=0/255, a=1}
local BLANK_COLOR = {r=56/255,g=96/255,b=96/255, a=200/255}
local HOVER_COLOR = {r=255/255,g=255/255,b=255/255, a=1}
local HOVER_COLOR_FAIL = {r=178/255,g=0/255,b=0/255, a=1}
local LOCKED_COLOR = {r=255/255,g=150/255,b=19/255, a=1}
local LOCKED_BLANK = {r=12/255,g=17/255,b=17/255, a=1}
local TEMP_COLOR = {r=0/255,g=184/255,b=0/255, a=1}

local function onClickNextAgent( self, adj, agent )
	
		local units = self._game:getLocalPlayer():getUnits()
		local sim = self._game.simCore
		local simquery = sim:getQuery()

		local idx = util.indexOf( units, self._currentAgent ) or 0
		local newAgent = agent 
		
		while true do 		
			idx = idx + adj

			if idx > #units then
				idx = idx - #units
			end
			if idx < 1 then
				idx = idx + #units
			end	

			newAgent = units[idx]

			if sim:getPC():findAgentDefByID( newAgent:getID() ) ~= nil then
				break
			end
		end

		self:updateAgent(newAgent)
		self._currentAgent = newAgent
end

local function onClickClose( self )
	self:hide()
end

----------------------------------------------------------------
-- Interface functions

local upgrade_dialog = class()

function upgrade_dialog:init(game)
	local screen = mui.createScreen( "upgrade-dialog.lua" )
	self._game = game
	self._screen = screen	

	self._screen.binder.panel.binder.closeBtn.onClick = util.makeDelegate( nil,  onClickClose, self )

	self._screen.binder.panel.binder.arrowLeft.binder.btn.onClick = util.makeDelegate( nil,  onClickNextAgent, self, -1 )
	self._screen.binder.panel.binder.arrowRight.binder.btn.onClick = util.makeDelegate( nil,  onClickNextAgent, self, 1 )	
end

function upgrade_dialog:updateAgent(agent)
	local file = "FILE #00-**45**A-******88"
	if agent:getUnitData() and agent:getUnitData().file then
		file = agent:getUnitData().file
	end
	
	--self._screen:findWidget("topTxt"):setText( util.toupper(file) )
	self._screen:findWidget("agentName"):setText( util.toupper( agent:getName() ) )
    self._screen:findWidget("apTxt"):setText( agent:getTraits().mpMax )

	local inventory ={}
	local augments = {}
	local invSize = agent:getTraits().inventoryMaxSize 
	local augSize = agent:getTraits().augmentMaxSize 

	for i,childUnit in ipairs(agent:getChildren())do
		if childUnit:getTraits().augment and childUnit:getTraits().installed then
			table.insert(augments,childUnit)
		else
			table.insert(inventory,childUnit)
		end
	end


	for i, widget in self._screen.binder:forEach( "inv_" ) do
		if inventory[i] then
				
			local itemUnit = inventory[i]

            guiex.updateButtonFromItem( self._screen, nil, widget, itemUnit,  agent )
			widget.binder.btn.onClick = nil
		else

			if i > invSize then 
				widget:setVisible(false)
			else
                guiex.updateButtonEmptySlot( widget )
			end
		end
	end	

	for i, widget in self._screen.binder:forEach( "aug_" ) do
		if augments[i] then
				
			local itemUnit = augments[i]

            guiex.updateButtonFromItem( self._screen, nil, widget, itemUnit, agent )
			widget.binder.btn.onClick = nil
		else

			if i > augSize then 
				widget:setVisible(false)
			else
                guiex.updateButtonEmptySlot( widget )
			end
		end
	end	

	if agent:getUnitData().profile_anim then
		self._screen:findWidget("agentProfileImg"):setVisible(false)
		self._screen:findWidget("agentProfileAnim"):setVisible(true)
		self._screen:findWidget("agentProfileAnim"):bindBuild( agent:getUnitData().profile_build or agent:getUnitData().profile_anim )
		self._screen:findWidget("agentProfileAnim"):bindAnim( agent:getUnitData().profile_anim )
		if agent:isKO() or agent:getTraits().iscorpse then
			self._screen:findWidget("agentProfileAnim"):getProp():setRenderFilter( cdefs.RENDER_FILTERS.desat )
			self._screen:findWidget("agentProfileAnim"):setPlayMode( KLEIAnim.STOP )
		else
			self._screen:findWidget("agentProfileAnim"):getProp():setRenderFilter( nil )
			self._screen:findWidget("agentProfileAnim"):setPlayMode( KLEIAnim.LOOP )
		end
	else
		self._screen:findWidget("agentProfileImg"):setVisible(true)
		self._screen:findWidget("agentProfileAnim"):setVisible(false)
		self._screen:findWidget("agentProfileImg"):setImage( agent:getUnitData().profile_icon )	
	end

	for t, widget in self._screen.binder:forEach( "skill" ) do
		local skills = agent:getSkills()
		local skill = skills[t]
		
		local tempPoints = 0
		if agent:getTraits().temp_skill_points then
			for p,tempskill in ipairs(agent:getTraits().temp_skill_points) do
				if tempskill == t then
					tempPoints = tempPoints +1
				end
			end
		end

		if skill then
			local skillDef = skilldefs.lookupSkill( skill._skillID )
			widget:setVisible(true)
			widget.binder.tipTitle:setText( util.toupper(skillDef.name) )

			for i, bar in widget.binder:forEach( "metterBar" ) do 

				if i <= skill._currentLevel then					
					if agent:getTraits().skillLock and agent:getTraits().skillLock[t] then
						bar.binder.bar:setColor(LOCKED_COLOR.r,LOCKED_COLOR.g,LOCKED_COLOR.b,LOCKED_COLOR.a)
					else
						bar.binder.bar:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
					end
					if i > skill._currentLevel - tempPoints then
						bar.binder.bar:setColor(TEMP_COLOR.r,TEMP_COLOR.g,TEMP_COLOR.b,TEMP_COLOR.a)
					end
						

				elseif i <= skillDef.levels then
					if agent:getTraits().skillLock and agent:getTraits().skillLock[t] then
						bar.binder.bar:setColor(LOCKED_BLANK.r,LOCKED_BLANK.g,LOCKED_BLANK.b,LOCKED_BLANK.a)
					else
						bar.binder.bar:setColor(BLANK_COLOR.r,BLANK_COLOR.g,BLANK_COLOR.b,BLANK_COLOR.a)
					end
				else
					bar.binder.bar:setColor(0.1,0.1,0.1,1)
				end


				if i <= skillDef.levels then
					bar.binder.cost:setVisible(false)
			--		bar.binder.cost:setVisible(true)
					bar.binder.txt:setVisible(true)
					bar.binder.cost:setText( util.sformat( STRINGS.FORMATS.CREDS, skillDef[i].cost ))
					bar.binder.txt:setText(skillDef[i].tooltip)	

					if i <= skill._currentLevel then
						bar.binder.cost:setColor(0,0,0,1)
					else
						bar.binder.cost:setColor(140/255,1,1,1)
					end
				else
					bar.binder.cost:setVisible(false)
					bar.binder.txt:setVisible(false)				
				end		
			end
		else
			widget:setVisible(false)
		end

	end




end


function upgrade_dialog:show(hud,agent)
	mui.activateScreen( self._screen )
	self._hud = hud
	self._currentAgent = agent
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_POPUP )
	self:updateAgent(agent)
end

function upgrade_dialog:hide()
	if self._screen:isActive() then
		mui.deactivateScreen( self._screen )
		
	end
end


return upgrade_dialog
