----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local game = include( "modules/game" )
local util = include("client_util")
local array = include( "modules/array" )
local mui = include( "mui/mui" )
local serverdefs = include( "modules/serverdefs" )
local modalDialog = include( "states/state-modal-dialog" )
local rig_util = include( "gameplay/rig_util" )
local cdefs = include("client_defs")
local skilldefs = include( "sim/skilldefs" )
local tool_templates = include("sim/unitdefs/itemdefs")
local mainframe_abilities = include( "sim/abilities/mainframe_abilities" )
local scroll_text = include("hud/scroll_text")
local unitdefs = include( "sim/unitdefs" )
local metadefs = include( "sim/metadefs" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )

----------------------------------------------------------------

local SET_COLOR = {r=244/255,g=255/255,b=120/255, a=1}
local POSSIBLE_COLOR = {r=0/255,g=184/255,b=0/255, a=1}
local BLANK_COLOR = {r=56/255,g=96/255,b=96/255, a=200/255}
local HOVER_COLOR = {r=255/255,g=255/255,b=255/255, a=1}
local HOVER_COLOR_FAIL = {r=178/255,g=0/255,b=0/255, a=1}

local ACTIVE_TXT = { 61/255,81/255,83/255,1 }
local INACTIVE_TXT = { 1,1,1,1 }

local ACTIVE_BG = { 244/255, 255/255, 120/255,1 }
local INACTIVE_BG = { 78/255, 136/255, 136/255,1 }

local function stopVoice(self)
	MOAIFmodDesigner.stopSound("voice" )
	if self._voiceCoroutine then
		self._voiceCoroutine:stop()
		self._voiceCoroutine = nil
	end	
end

local function lookupLoadouts( template )
	return serverdefs.LOADOUTS[ template ]
end

local function lookupTemplate( name )
	return tool_templates[ name ] 
end

local function findAgentIdx( template )
	for k,v in ipairs(serverdefs.SELECTABLE_AGENTS) do 
		if v == template then 
			return k 
		end
	end
end 

local function onClickBioPrev(self, nextBtn, prevBtn, textWidget, text )

	textWidget:setText(text)
	nextBtn:setVisible(true)
	
	textWidget._pageNumber = textWidget._pageNumber -1

	for i=textWidget._pageNumber, 0, -1 do
		textWidget:nextPage()
	end
	
	if textWidget._pageNumber == 0 then
		prevBtn:setVisible(false)
	end

end


local function onClickBioNext(self, nextBtn, prevBtn, textWidget )
	textWidget:nextPage()
	if textWidget:hasNextPage() then
		nextBtn:setVisible(true)
	else 
		nextBtn:setVisible(false)
	end

	textWidget._pageNumber = textWidget._pageNumber +1


	prevBtn:setVisible(true)
end




local function onClickCampaign(self)

	stopVoice(self)

	local agentIDs = {}
	for k,v in ipairs(self._selectedAgents) do
		local agentName = serverdefs.SELECTABLE_AGENTS[v]
		local loadouts = lookupLoadouts( agentName )
		local agentTemplate = loadouts[ self._selectedLoadouts[k] ]
		if metadefs.isRewardUnlocked( agentTemplate ) then
			agentIDs[k] = agentTemplate
		else
			modalDialog.show( STRINGS.UI.TEAM_SELECT.LOCKED_LOADOUT )
			return
		end
	end

	local programIDs = {}
	for k, programName in ipairs(self._selectedPrograms) do
		if metadefs.isRewardUnlocked( programName ) then
			programIDs[k] = programName
		else
			modalDialog.show( STRINGS.UI.TEAM_SELECT.LOCKED_LOADOUT )
			return
		end
	end

	local selectedAgency = serverdefs.createAgency( agentIDs, programIDs )
	local campaign = serverdefs.createNewCampaign( selectedAgency, self._campaignDifficulty, self._campaignOptions )

	local user = savefiles.getCurrentGame()
	user.data.saveSlots[ user.data.currentSaveSlot ] = campaign
	user.data.num_campaigns = (user.data.num_campaigns or 0) + 1
    user.data.gamesStarted = true
	user:save()

	statemgr.deactivate( self )
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )

	local intro_screen = mui.createScreen( "modal-posttutorial.lua" )
	mui.activateScreen( intro_screen )

	local overlay = intro_screen:findWidget("overlay")
	
	local closeBtn = intro_screen.binder.closeBtn
	closeBtn:setHotkey( "pause" )
	closeBtn:setText( STRINGS.UI.NEW_GAME_CONFIRM )
	local clicked = false
	local fade_time = .5
	local c = 1
	closeBtn.onClick = function() 
		if not clicked then
			clicked = true
			overlay:setVisible(true)
			
			local t = c*fade_time
			while t < fade_time do
				t = t + 1/cdefs.SECONDS
				c = math.min(t / fade_time, 1)
				overlay:setColor(0, 0, 0, c)
				coroutine.yield()
			end

			mui.deactivateScreen( intro_screen ) 
			MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
			MOAIFmodDesigner.stopSound("theme")

			local stateMapScreen = include( "states/state-map-screen" )
			statemgr.activate( stateMapScreen(), campaign )
		end
	end
	
	overlay:setVisible(true)
	local t = 0
	while t < fade_time and not clicked do
		t = t + 1/cdefs.SECONDS
		c = 1- math.min(t / fade_time, 1)
		overlay:setColor(0, 0, 0, c)
		coroutine.yield()
	end
	
	if not clicked then
		overlay:setVisible(false)
	end



	if self._dialog then
		self._dialog:close()
		self._dialog = nil
	end
end

local function updateLoadoutButtons( self, agentIdx )
	local agentID = serverdefs.SELECTABLE_AGENTS[ self._selectedAgents[ agentIdx ] ]
	local agentDef = unitdefs.lookupTemplate( agentID )

	-- jl: bad code duplication

	local loadouts = lookupLoadouts( agentID )

	if agentIdx == 1 then
		for i, widget in self._panel.binder.agent1.binder:forEach( "loadoutBtn" ) do 
			local loadout = loadouts[ i ]
			if loadout and metadefs.isRewardUnlocked(agentID) then 
				local loadout = unitdefs.lookupTemplate(loadouts[ i ])
				widget:setVisible( true )

				if metadefs.isRewardUnlocked( loadouts[ i ] ) then 
					widget.binder.btn:setText( loadout.loadoutName )
					widget.binder.btn:setDisabled( false )
					widget.binder.btn:setVisible( true )
				else 
					widget.binder.btn:setText( STRINGS.LOCKED_AGENT_NAME )
					widget.binder.btn:setDisabled( true )
					widget.binder.btn:setVisible( false )
				end 

				if self._selectedLoadouts[ agentIdx ] == i then 
					widget.binder.btn:setColorInactive( unpack(ACTIVE_BG) )
					widget.binder.btn:updateImageState()
					widget.binder.arrow:setVisible( true )
				else 
					widget.binder.btn:setColorInactive( unpack(INACTIVE_BG) )
					widget.binder.btn:updateImageState()
					widget.binder.arrow:setVisible( false )
				end
			else
				widget:setVisible( false )
			end
		end
	else 
		for i, widget in self._panel.binder.agent2.binder:forEach( "loadoutBtn" ) do 
			local loadout = loadouts[ i ]
			if loadout and metadefs.isRewardUnlocked(agentID) then 
				local loadout = unitdefs.lookupTemplate(loadouts[ i ])
				widget:setVisible( true )

				if metadefs.isRewardUnlocked( loadouts[ i ] ) and metadefs.isRewardUnlocked( loadouts[ i ] ) then 
					widget.binder.btn:setText( loadout.loadoutName )
					widget.binder.btn:setDisabled( false )
					widget.binder.btn:setVisible( true )
				else 
					widget.binder.btn:setText( STRINGS.LOCKED_AGENT_NAME )
					widget.binder.btn:setDisabled( true )
					widget.binder.btn:setVisible( false )
				end 

				if self._selectedLoadouts[ agentIdx ] == i then 
					widget.binder.btn:setColorInactive( unpack(ACTIVE_BG) )
					widget.binder.btn:updateImageState()
					widget.binder.arrow:setVisible( true )
				else 
					widget.binder.btn:setColorInactive( unpack(INACTIVE_BG) )
					widget.binder.btn:updateImageState()
					widget.binder.arrow:setVisible( false )
				end
			else
				widget:setVisible( false )
			end
		end
	end
end 

local function onClickCancel(self)
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
	
	--don't show the movie again if you've already seen it
	config.SHOW_MOVIE = false

	local stateGenerationOptions = include( "states/state-generation-options" )
	statemgr.deactivate( self )
	statemgr.activate( stateGenerationOptions(), self._campaignDifficulty, self._campaignOptions )

	if self._dialog then
		self._dialog:close()
		self._dialog = nil
	end	
end

local function selectProgram( self, programIdx, programID )
	local programPanel = self._panel.binder["program"..programIdx]
	local programData =  mainframe_abilities[programID]
	local PWRtooltip = STRINGS.UI.TOOLTIPS.TEAM_SELECT_PWR_DESC

	programPanel.binder["firewallTooltip"]:setTooltip(PWRtooltip..STRINGS.UI.TOOLTIPS.TEAM_SELECT_NOPWR)

	if metadefs.isRewardUnlocked( programID ) then
		programPanel.binder["programIcon"]:setImage(programData.icon)
		programPanel.binder["programIcon"]:setColor(1,1,1)
		programPanel.binder["programName"]:setText(util.toupper(programData.name))
		programPanel.binder["programTxt"]:spoolText( programData.desc )
		programPanel.binder["programTxt"]:setColor(140/255,255/255,255/255)	

		if programData.cpu_cost > 0 or not programData.passive then
			programPanel.binder["powerTxt"]:setText(tostring(programData.cpu_cost))
			programPanel.binder["firewallTooltip"]:setTooltip(PWRtooltip..util.sformat(STRINGS.UI.TOOLTIPS.TEAM_SELECT_PWR,programData.cpu_cost))	
		else
			programPanel.binder["powerTxt"]:setText("-")
		end
	
	else
		programPanel.binder["programIcon"]:setImage(programData.icon)
		programPanel.binder["programIcon"]:setColor(0,0,0)
		programPanel.binder["programName"]:setText( STRINGS.UI.TEAM_SELECT.LOCKED_AGENT_NAME )

		if programData.lockedText then
			programPanel.binder["programTxt"]:setText( programData.lockedText )
		else
			programPanel.binder["programTxt"]:setText( STRINGS.UI.TEAM_SELECT.UNLOCK_TO_USE )
		end
		programPanel.binder["programTxt"]:setColor( 1, 1, 1 )

		programPanel.binder["powerTxt"]:setText("?")


		for i, widget in programPanel.binder:forEach( "power" ) do
			widget:setColor(17/255,29/255,29/255)
		end
	end


	programPanel:setVisible(true)

    self._selectedPrograms[ programIdx ] = programID
end

local function selectAgent( self, agentIdx, agentID, transition, noVoice )
	-- Show team info

	-- Show the agents on the team
	local agentDef = unitdefs.lookupTemplate( agentID )
	assert( agentDef )

	local agentWidget = self._panel.binder[ "agent" .. agentIdx ]

	self._selectedLoadouts[ agentIdx ] = 1
    self._selectedAgents[ agentIdx ] = findAgentIdx( agentID )

	updateLoadoutButtons( self, agentIdx )

	MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/popdown" )	

	if transition then
		agentWidget:createTransition( "transition_none" )
	end

	agentWidget:setVisible(true)
	--agentWidget.binder.fadeBox:blinkWhiteTransition()

	if metadefs.isRewardUnlocked( agentID ) then
		agentWidget.binder.agentName:spoolText(util.toupper(agentDef.name),15)

		if agentDef.team_select_img then
			agentWidget.binder.agentImg:setImage(agentDef.team_select_img[1])		
			agentWidget.binder.agentImg:setColor(1,1,1)
			agentWidget.binder.agentImg:createTransition("transition_none")
			agentWidget.binder.agentImgBG:createTransition("transition_none")
		end
	
    	local fluff = util.sformat( STRINGS.UI.BIO_FORMAT, agentDef.fullname, agentDef.age )
		agentWidget.binder.fluffTxt:spoolText(util.toupper(fluff))
		agentWidget.binder.agentNameBody:setText( util.toupper(agentDef.codename or agentDef.fullname) )

		-- item icons
		for i, widget in agentWidget.binder:forEach( "item" ) do
			if agentDef.upgrades[i] then
				widget:setVisible(true)

				local unitData = lookupTemplate( agentDef.upgrades[i] )
                local newItem = simfactory.createUnit( unitData, nil )						
				widget:setImage( unitData.profile_icon )

		        local tooltip = util.tooltip( self.screen )
		        local section = tooltip:addSection()
		        newItem:getUnitData().onTooltip( section, newItem )
		        widget:setTooltip( tooltip )
		        widget:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
			else
				widget:setVisible(false)
			end
		end
	
		-- skill bars
		for i, widget in agentWidget.binder:forEach( "skill" ) do			
			if agentDef.skills[i] then 

				skill = skilldefs.lookupSkill(agentDef.skills[i])
				
				widget.binder.costTxt:spoolText(skill.name,15)

				for i, barWidget in widget.binder:forEach( "bar" ) do
					barWidget.binder.meterbarSmall.binder.bar:setColor(BLANK_COLOR.r,BLANK_COLOR.g,BLANK_COLOR.b,BLANK_COLOR.a)					
				end

				widget.binder.bar1.binder.meterbarSmall.binder.bar:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
				widget:setVisible( true )

				local tooltip = "<c:F4FF78>".. skill.name.. "</>\n"..skill.description
				widget.binder.tooltip:setTooltip(tooltip)
				
			else 
				widget:setVisible(false)
			end
		end
		for i, skillUpgrade in pairs(agentDef.startingSkills) do
	  		for v, skill in ipairs(agentDef.skills) do
		  		for f=1,skillUpgrade-1 do
					if skill == i then
			     		 agentWidget.binder["skill"..v].binder["bar"..(1+f)].binder.meterbarSmall.binder.bar:setColor(POSSIBLE_COLOR.r,POSSIBLE_COLOR.g,POSSIBLE_COLOR.b,POSSIBLE_COLOR.a)
					end
				end
	  		end		
		end

		-- Specialties

		agentWidget.binder.agentDescBody:setText( agentDef.blurb )
		agentWidget.binder.prevBtn:setVisible(false)
		agentWidget.binder.agentDescBody._pageNumber = 0

		agentWidget.binder.prevBtn.onClick = util.makeDelegate( nil, onClickBioPrev, self, agentWidget.binder.nextBtn, agentWidget.binder.prevBtn, agentWidget.binder.agentDescBody, agentDef.blurb )		
		agentWidget.binder.nextBtn.onClick =  util.makeDelegate( nil, onClickBioNext, self, agentWidget.binder.nextBtn, agentWidget.binder.prevBtn, agentWidget.binder.agentDescBody )

		if agentWidget.binder.agentDescBody:hasNextPage() then
			agentWidget.binder.nextBtn:setVisible(true)
		else
			agentWidget.binder.nextBtn:setVisible(false)
		end
	

		for i, widget in agentWidget.binder:forEach( "iconSkill" ) do
			widget:setVisible(false)
			agentWidget.binder["skillTxt"..i]:setVisible(false)
		end

		if not noVoice then
			stopVoice(self)
			self._voiceCoroutine = MOAICoroutine.new()
			self._voiceCoroutine:run( function() 
				rig_util.wait(0.5*cdefs.SECONDS)
				self._voiceCoroutine:stop()
				MOAIFmodDesigner.playSound(agentDef.sounds.bio,"voice" )	
			end )
		end

	else
		agentWidget.binder.agentName:setText( STRINGS.UI.TEAM_SELECT.LOCKED_AGENT_NAME )
		agentWidget.binder.agentNameBody:setText( STRINGS.UI.TEAM_SELECT.LOCKED_AGENT_NAME )

		if agentDef.lockedText then
			agentWidget.binder.fluffTxt:setText( agentDef.lockedText )
		else
			agentWidget.binder.fluffTxt:setText( STRINGS.UI.TEAM_SELECT.UNLOCK_TO_USE )
		end
		agentWidget.binder.agentDescBody:setText( STRINGS.UI.TEAM_SELECT.LOCKED_AGENT_DESC )
		if agentDef.team_select_img then
			agentWidget.binder.agentImg:setImage(agentDef.team_select_img[1])		
			agentWidget.binder.agentImg:setColor(0,0,0)
			agentWidget.binder.agentImg:createTransition("transition_none")
			agentWidget.binder.agentImgBG:createTransition("transition_none")
		end

		for i, widget in agentWidget.binder:forEach( "item" ) do
			widget:setVisible( false )
		end
		for i, widget in agentWidget.binder:forEach( "skill" ) do
			if agentDef.skills[i] then 
                local skill = skilldefs.lookupSkill(agentDef.skills[i])
				widget.binder.costTxt:spoolText(skill.name,15)

				for i, barWidget in widget.binder:forEach( "bar" ) do
					barWidget.binder.meterbarSmall.binder.bar:setColor(BLANK_COLOR.r,BLANK_COLOR.g,BLANK_COLOR.b,BLANK_COLOR.a)					
				end
				widget:setVisible( true )
			else 
				widget:setVisible(false)
			end
		end
		for i, widget in agentWidget.binder:forEach( "iconSkill" ) do
			widget:setVisible( false )
		end
	end
end

local function selectLoadout( self, agentIdx, loadoutIdx )

	local agentWidget = self._panel.binder[ "agent" .. agentIdx ]
	local agentID = serverdefs.SELECTABLE_AGENTS[ self._selectedAgents[ agentIdx ] ]
	local loadouts = lookupLoadouts( agentID )
	local agentDef = unitdefs.lookupTemplate( loadouts[ loadoutIdx ] )

	for i, widget in agentWidget.binder:forEach( "item" ) do
		if agentDef.upgrades[i] then
			widget:setVisible(true)
			local unitData = lookupTemplate( agentDef.upgrades[i] )
            local newItem = simfactory.createUnit( unitData, nil )						
			widget:setImage( unitData.profile_icon )

	        local tooltip = util.tooltip( self.screen )
	        local section = tooltip:addSection()
	        newItem:getUnitData().onTooltip( section, newItem )
	        widget:setTooltip( tooltip )
		else
			widget:setVisible(false)
		end
	end

	updateLoadoutButtons( self, agentIdx )

    local fluff = util.sformat( STRINGS.UI.BIO_FORMAT, agentDef.fullname, agentDef.age )
	agentWidget.binder.fluffTxt:spoolText(util.toupper(fluff))

	agentWidget.binder.agentNameBody:setText( util.toupper( agentDef.codename or agentDef.fullname ) )
	agentWidget.binder.agentDescBody:setText( agentDef.blurb )
	agentWidget.binder.agentImg:setImage(agentDef.team_select_img[1])		
	agentWidget.binder.agentImg:setColor(1,1,1)
	agentWidget.binder.agentImg:createTransition("transition_none")
	agentWidget.binder.agentImgBG:createTransition("transition_none")

	agentWidget.binder.agentDescBody._pageNumber = 0
	agentWidget.binder.prevBtn.onClick = util.makeDelegate( nil, onClickBioPrev, self, agentWidget.binder.nextBtn, agentWidget.binder.prevBtn, agentWidget.binder.agentDescBody, agentDef.blurb )		
	agentWidget.binder.prevBtn:setVisible(false)
	agentWidget.binder.nextBtn.onClick =  util.makeDelegate( nil, onClickBioNext, self, agentWidget.binder.nextBtn, agentWidget.binder.prevBtn, agentWidget.binder.agentDescBody )
	agentWidget.binder.nextBtn:setVisible(true)

end 
----------------------------------------------------------------
--

local function updateSelectionState( self )
    local lb = self.screen:findWidget( "agentListbox" )
    for i = 1, lb:getItemCount() do
        local widget = lb:getItem( i ).widget
		if ( i == self._selectedAgents[1] or i == self._selectedAgents[2] ) and metadefs.isRewardUnlocked( serverdefs.SELECTABLE_AGENTS[ i ] ) then 
			widget:setVisible( true )
			widget.binder.img:setColor( 1, 1, 1, 1 )
			widget.binder.img:setVisible( true )
			widget.binder.bg:setVisible( true )
		elseif metadefs.isRewardUnlocked( serverdefs.SELECTABLE_AGENTS[ i ] ) and i <= #serverdefs.SELECTABLE_AGENTS then 
			widget:setVisible( true )
			widget.binder.img:setColor( 60/255, 60/255, 60/255, 0.9 )
			widget.binder.img:setVisible( true )
			widget.binder.bg:setVisible( true )
		elseif i <= #serverdefs.SELECTABLE_AGENTS and (i == self._selectedAgents[1] or i == self._selectedAgents[2]) then
			widget.binder.img:setColor( 0, 0, 0, 1)
			widget.binder.img:setVisible( true )
			widget.binder.bg:setVisible( true )
			widget:setVisible( true )
		elseif i <= #serverdefs.SELECTABLE_AGENTS then
			widget.binder.img:setColor( 0, 0, 0, 0.75)
			widget.binder.img:setVisible( true )
			widget.binder.bg:setVisible( true )
			widget:setVisible( true )
		else 
			widget:setVisible( false )
		end
    end
end

local function randomizeEverything( self )
	local loadoutTable = {}
	local agentTable = {}
	local pwrgenTable, breakerTable = {}, {}

	for i,agent in ipairs( serverdefs.SELECTABLE_AGENTS ) do 
		if metadefs.isRewardUnlocked( agent ) then 
			table.insert( agentTable, agent )
		end
	end

	for i,program in ipairs( serverdefs.SELECTABLE_PROGRAMS[1] ) do 
		if metadefs.isRewardUnlocked( program ) then 
			table.insert( pwrgenTable, program )
		end
	end

    for i,program in ipairs( serverdefs.SELECTABLE_PROGRAMS[2] ) do 
		if metadefs.isRewardUnlocked( program ) then 
			table.insert( breakerTable, program )
		end
	end

	util.shuffle( pwrgenTable )
	util.shuffle( breakerTable )
	util.shuffle( agentTable )

	selectAgent( self, 1, agentTable[1], true )
	selectAgent( self, 2, agentTable[2], true ) 

	selectProgram( self, 1, pwrgenTable[1] )
	selectProgram( self, 2, breakerTable[1] )

	local loadouts1 = util.tcopy(lookupLoadouts( agentTable[1] ))
	local loadouts2 = util.tcopy(lookupLoadouts( agentTable[2] ))

	local loadoutIdx1 = {}
	local loadoutIdx2 = {}

	for i,loadout in ipairs( loadouts1 ) do 
		if metadefs.isRewardUnlocked( loadout ) then 
			table.insert( loadoutIdx1, i )
		end
	end

	for i,loadout in ipairs( loadouts2 ) do 
		if metadefs.isRewardUnlocked( loadout ) then 
			table.insert( loadoutIdx2, i )
		end
	end

	util.shuffle( loadoutIdx1 )
	util.shuffle( loadoutIdx2 )

	self._selectedLoadouts = { loadoutIdx1[1], loadoutIdx2[1] }

	selectLoadout( self, 1, loadoutIdx1[1] )
	selectLoadout( self, 2, loadoutIdx2[1] )

	updateLoadoutButtons(self, 1)
	updateLoadoutButtons(self, 2)
	updateSelectionState( self )

end 


local function onClickLoadout( self, agentIdx, loadoutIdx )
	if self._selectedLoadouts[ agentIdx ] ~= loadoutIdx then 
		self._selectedLoadouts[ agentIdx ] = loadoutIdx 
		selectLoadout( self, agentIdx, loadoutIdx )
	end 
end 

local function onClickAgentSelect( self, selectionIdx )

	if selectionIdx == self._selectedAgents[1] or selectionIdx == self._selectedAgents[2] then 
		-- Do nothing 
	else 
		self._selectedAgents[ self._agentSelectIdx ]  = selectionIdx

		updateSelectionState( self )

		selectAgent( self, self._agentSelectIdx, serverdefs.SELECTABLE_AGENTS[selectionIdx], nil )
		self._agentSelectIdx = ( self._agentSelectIdx % 2 ) + 1
	end 
end 

local function onClickNextAgent( self, direction, agentIdx )

	local selectionIdx = self._selectedAgents[agentIdx] + direction 
	if selectionIdx <= 0 then
		selectionIdx = #serverdefs.SELECTABLE_AGENTS
	elseif selectionIdx > #serverdefs.SELECTABLE_AGENTS then
		selectionIdx = 1
	end

	self._selectedAgents[agentIdx] = selectionIdx

	updateSelectionState( self )

	if self._selectedAgents[1] == self._selectedAgents[2] then
		--skip this one and keep going
		onClickNextAgent( self, direction, agentIdx )
	else		
		selectAgent( self, agentIdx, serverdefs.SELECTABLE_AGENTS[selectionIdx], nil )
	end
end

local function onClickNextProgram( self, direction, programIdx )
    local programName = self._selectedPrograms[ programIdx ]
    local programs = serverdefs.SELECTABLE_PROGRAMS[ programIdx ]
    local selectionIdx = array.find( programs, programName ) - 1 -- 0-based
    selectionIdx = (selectionIdx + direction) % #programs + 1 -- back to 1-based
	selectProgram( self, programIdx, programs[ selectionIdx ] )
end

local teamPreview = class()

function teamPreview:init( campaignDifficulty, campaignOptions )
    assert( campaignDifficulty and campaignOptions )
    self._campaignOptions = campaignOptions
    self._campaignDifficulty = campaignDifficulty
    self._voiceCoroutine = nil
end

function teamPreview:onLoad()


	for i,program in ipairs(serverdefs.SELECTABLE_PROGRAMS[1]) do 
		programData =  mainframe_abilities[program]

		if programData.abilityOverride then
			serverdefs.SELECTABLE_PROGRAMS[1][i] = programData.abilityOverride
		end
	end

	for i,program in ipairs(serverdefs.SELECTABLE_PROGRAMS[2]) do 
		programData =  mainframe_abilities[program]

		if programData.abilityOverride then
			serverdefs.SELECTABLE_PROGRAMS[2][i] = programData.abilityOverride
		end
	end

	log:write("teamPreview:onLoad()")

	self.screen = mui.createScreen( "team_preview_screen.lua" )
	mui.activateScreen( self.screen )

	self._scroll_text = scroll_text.panel( self.screen.binder.bg )

	self._panel = self.screen.binder.pnl

	self._panel.binder.title_txt:setText("")
	self._panel.binder.title_txt:spoolText(STRINGS.UI.SCREEN_NAME_TEAM_SELECT)		

	self._panel.binder.acceptBtn.onClick = util.makeDelegate( nil,  onClickCampaign, self)
	self._panel.binder.acceptBtn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)
	
	self._panel.binder.cancelBtn.onClick = util.makeDelegate( nil,  onClickCancel, self)
	self._panel.binder.cancelBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)

	self._panel.binder.agent1.binder.arrowLeft.binder.btn.onClick = util.makeDelegate( nil,  onClickNextAgent, self, -1, 1 )
	self._panel.binder.agent1.binder.arrowRight.binder.btn.onClick = util.makeDelegate( nil,  onClickNextAgent, self, 1, 1 )
	self._panel.binder.agent2.binder.arrowLeft.binder.btn.onClick = util.makeDelegate( nil,  onClickNextAgent, self, -1, 2 )
	self._panel.binder.agent2.binder.arrowRight.binder.btn.onClick = util.makeDelegate( nil,  onClickNextAgent, self, 1, 2 )

	self._panel.binder.program1.binder.arrowLeft.binder.btn.onClick = util.makeDelegate( nil,  onClickNextProgram, self, -1, 1 )
	self._panel.binder.program1.binder.arrowRight.binder.btn.onClick = util.makeDelegate( nil,  onClickNextProgram, self, 1, 1 )
	self._panel.binder.program2.binder.arrowLeft.binder.btn.onClick = util.makeDelegate( nil,  onClickNextProgram, self, -1, 2 )
	self._panel.binder.program2.binder.arrowRight.binder.btn.onClick = util.makeDelegate( nil,  onClickNextProgram, self, 1, 2 )

	self._panel.binder.randomizeBtn.onClick = util.makeDelegate( nil, randomizeEverything, self )

	for i, widget in self._panel.binder.agent1.binder:forEach( "loadoutBtn" ) do 
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickLoadout, self, 1, i ) 
	end 

	for i, widget in self._panel.binder.agent2.binder:forEach( "loadoutBtn" ) do 
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickLoadout, self, 2, i ) 
	end 

	local gameModeStr = serverdefs.GAME_MODE_STRINGS[ self._campaignDifficulty ]
	local ironmanStr = STRINGS.UI.HUD_OFF
	if self._campaignOptions.rewindsLeft == 0 then
		ironmanStr = STRINGS.UI.HUD_ON
	end
	local difficultyStr = string.format("%s: <c:8CFFFF>%s</>    %s: <c:8CFFFF>%s</>",
		util.toupper(STRINGS.UI.DIFFICULTY_STR),
		util.toupper(gameModeStr), 
		STRINGS.UI.DIFF_OPTION_IRONMAN, 
		ironmanStr )
	self._panel.binder.gameOptions:setText( difficultyStr)

	local user = savefiles.getCurrentGame()
	self._selectedAgents = { 1, 2 }
	self._selectedPrograms = { 1, 2 }
	self._selectedLoadouts = { 1, 1 }
	self._agentSelectIdx = 1

	self._panel.binder.agent1:setVisible(false)
	self._panel.binder.agent2:setVisible(false)
	self._panel.binder.program1:setVisible(false)
	self._panel.binder.program2:setVisible(false)

    local lb = self.screen:findWidget( "agentListbox" )
    lb.onItemClicked = util.makeDelegate( nil, onClickAgentSelect, self )

	for i = 1, #serverdefs.SELECTABLE_AGENTS do
		local agentID = serverdefs.SELECTABLE_AGENTS[ i ]
		local agentDef = unitdefs.lookupTemplate( agentID )
        local widget = lb:addItem( agentID )
		widget.binder.img:setImage( agentDef.team_select_img[1] )
		widget.binder.img.onClick = util.makeDelegate( nil, onClickAgentSelect, self, i )
		if metadefs.isRewardUnlocked( serverdefs.SELECTABLE_AGENTS[ i ] ) then
			widget.binder.img:setTooltip( util.toupper(agentDef.name) )
		else
			widget.binder.img:setTooltip( util.toupper(STRINGS.UI.TEAM_SELECT.LOCKED_AGENT_NAME) )
		end
	end

	selectAgent( self, 1, serverdefs.SELECTABLE_AGENTS[1], true, true )
	selectAgent( self, 2, serverdefs.SELECTABLE_AGENTS[2], true, true )
	selectProgram( self, 1, serverdefs.SELECTABLE_PROGRAMS[1][1] )
	selectProgram( self, 2, serverdefs.SELECTABLE_PROGRAMS[2][1] )

	updateLoadoutButtons( self, 1 )
	updateLoadoutButtons( self, 2 )

	updateSelectionState( self )

	if not MOAIFmodDesigner.isPlaying("theme") then
		MOAIFmodDesigner.playSound("SpySociety/Music/music_map_AMB","theme")
	end

	-- show new DLC rewards
	for i,reward in ipairs(metadefs.DLC_INSTALL_REWARDS) do	
		local settings = savefiles.getSettings( "settings" )
		if not settings.data[reward.unlocks[1].name.."_unlocked"] then
			if reward.unlockType == metadefs.PROGRAM_UNLOCK then
			    modalDialog.showUnlockProgram( reward )
			elseif reward.unlockType == metadefs.AGENT_UNLOCK then
				modalDialog.showUnlockAgent( reward )
			end
			settings.data[reward.unlocks[1].name.."_unlocked"] = true
			settings:save()
		end
	end	
end

function teamPreview:onUnload()
	self._scroll_text:destroy()
    self._scroll_text = nil
    stopVoice(self)

	mui.deactivateScreen( self.screen )
    self.screen = nil
end

return teamPreview
