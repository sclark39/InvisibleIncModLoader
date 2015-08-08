----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local util = include( "client_util" )  
local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )
local modalDialog = include( "states/state-modal-dialog" )
local rig_util = include( "gameplay/rig_util" )
local level = include( "sim/level" )
local cdefs = include( "client_defs" )
local talkinghead_ingame = include( "client/fe/talkinghead_ingame" )

----------------------------------------------------------------
---  in-world hilite arrow

local hilite_arrow = class()

function hilite_arrow:init( hud, name, scale, x, y )	
	self._boardrig = hud._game.boardRig
	self._name = name
	self._prop = self._boardrig:createHUDProp("kanim_tutorial_tile_arrow", "character", "idle", self._boardrig:getLayer("ceiling"), nil, x, y )
end

function hilite_arrow:destroy( screen )
	self._boardrig:getLayer("ceiling"):removeProp( self._prop )
end

function hilite_arrow:getName()
	return self._name
end

----------------------------------------------------------------
---  widget hilite

local function hiliteAnimHandler( anim, animname )
	if animname == "in" then
		anim:setCurrentAnim( "loop" )
	end
end

local hilite_widget = class()

function hilite_widget:init( hud, name, scale, widgetName )
	assert( type(widgetName) == "string" )

	self._name = name
	self._scale = scale or 1
	
	self._widget = hud._world_hud._screen:createFromSkin( "Pulse" )

	self._widget:setTopmost( true )

	self._parent = nil -- The parent widget it is anchored to
	self._parentName = widgetName

	self:refresh( hud )
end

function hilite_widget:refresh( hud )
	local parent = hud._screen:findWidget( self._parentName ) or hud._world_hud._screen:findWidget( self._parentName )
	if parent == nil and hud._itemsPanel then
		parent = hud._itemsPanel:findWidget( self._parentName )
	end

	if parent and self._parent == parent then
		return -- still attached to ther right thing!
	
	else
		if self._parent then
			-- Had a parent, but it's no longer active
			self._parent:removeChild( self._widget )
			self._parent = nil
		end

		if parent then
			self._parent = parent
			self._parent:addChild( self._widget )
			self._widget:setScale( self._scale, self._scale )
		end
	end
end

function hilite_widget:destroy( screen )
	if self._parent then
		self._parent:removeChild( self._widget )
		self._parent = nil
	end
end

function hilite_widget:getName()
	return self._name
end


local blink_widget = class()

function blink_widget:init( hud, widgetName, blinkData )
	assert( type(widgetName) == "string" )

	self._blinkData = blinkData
	self._parentName = widgetName
	self:refresh( hud )
end

function blink_widget:refresh( hud )
	local parent = hud._screen:findWidget( self._parentName ) or hud._world_hud._screen:findWidget( self._parentName )
	if parent == nil and hud._itemsPanel then
		parent = hud._itemsPanel:findWidget( self._parentName )
	end

	if parent and self._parent == parent then
		return -- still attached to ther right thing!
	
	else
		if self._parent then
			-- Had a parent, but it's no longer active
			local btn = self._parent
			if self._parent.binder and self._parent.binder.btn then
				btn = self._parent.binder.btn
			end

			btn:blink( nil )
			self._parent = nil
		end

		if parent then
			self._parent = parent
			local btn = self._parent
			if self._parent.binder and self._parent.binder.btn then
				btn = self._parent.binder.btn
			end
			btn:blink( self._blinkData.period, self._blinkData.blinkCountPerPeriod, self._blinkData.periodInterval, {r=1,g=1,b=1,a=1} )
		end
	end
end

function blink_widget:destroy( screen )
	if self._parent then
		local btn = self._parent
		if self._parent.binder and self._parent.binder.btn then
			btn = self._parent.binder.btn
		end

		btn:blink( nil )
		self._parent = nil
	end
end

function blink_widget:getName()
	return "blink-"..self._parentName
end

local function setupWidgetAnims( self, widgetName )
	local animWidget = self._hud._screen:findWidget(widgetName)
	animWidget:getProp():setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim, animname )
					if animname == "in" then
						animWidget:setAnim("loop")
					elseif animname == "out" then
						animWidget:setVisible(false)
					end
				end )
end	
----------------------------------------------------------------
-- Interface functions

local mission_panel = class()

function mission_panel:init( hud, screen )
	self._hud = hud
	self._screen = screen
	self._screen._operator_screen = mui.createScreen( "operator-message.lua" )
	self._screen._enemy_screen = mui.createScreen( "enemy-message.lua" )
	self._screen._black_screen = mui.createScreen( "black.lua" )
	self.talkinghead = talkinghead_ingame( self._screen._operator_screen.binder.Friends, function() return hud._isMainframe end )

	--for glowing instructional text
	self._instructionsHighlightTimer = 0
	self._guardStatusHighlightTimer = 0
	
	self._instructionsHighlightDirection = 1
	self._guardStatusHighlightDirection = 1

	self._instructionsHighlightColor1 ={r=255/255,g=255/255,b=255/255,a=1}
	self._instructionsHighlightColor2 ={r=255/255,g=255/255,b=255/255,a=0.6}

	self.hiliteObjects = {}

	-- Mission panel event queue handled in its own coroutine.
	self._thread = MOAICoroutine.new()
	self._thread:run( function() self:processQueue() end )

    -- Ignore any events at the time of creation... except for the magical RESTORE checkpoint event,
    -- because that simply *must* be handled.
	local eventQueue = hud._game.simCore:getLevelScript():getQueue()
    array.removeIf( eventQueue, function( event ) return type(event) ~= "table" or event.type ~= "restoreCheckpoint" end )

	-- make the anim in the insturction widget loop after it finished coming in
	setupWidgetAnims( self, "instructionGroup.anim" )
	setupWidgetAnims( self, "guardStatusGroup.anim" )

    FMODMixer:addAutoMix( "talkinghead_voice", "music_duck" )
end	

function mission_panel:startBlackScreen()
	if not self._screen._black_screen:isActive() then
		mui.activateScreen( self._screen._black_screen )
		self._screen._black_screen:findWidget("black"):setColor(0,0,0,1)
		MOAIFmodDesigner.setAmbientReverb( "mainframe" )
		FMODMixer:pushMix("nomusic")
	end
end

function mission_panel:deleteObject(name)	
	for i,object in ipairs (self.hiliteObjects) do 
	 	if name == object:getName() then
	 		object:destroy( self._screen )
	 		table.remove(self.hiliteObjects,i)
	 		break
	 	end				 	
	end
end

function mission_panel:ShowTalkingHeadIfStillVO()
	self.talkinghead:TryResume()
end

function mission_panel:HideTalkingHeadButRetainVO(  )
	self.talkinghead:Hide()
end

function mission_panel:stopTalkingHead(  )
	self.talkinghead:Halt()
end

function mission_panel:skip()
    self._skipping = true
end

function mission_panel:yield()
    if not self._skipping then
        coroutine.yield()
    end
end

function mission_panel:processEvent( event )
	--log:write("processEvent( %s )", util.stringize(event,2))

    -- Clear skip flag.
    self._skipping = nil

	if type(event) == "number" then
		while event > 0 do
            self:yield()
			event = event - 1
		end

    elseif event.type == "restoreCheckpoint" then
        local stateLoading = include( "states/state-loading" )
        if statemgr.isActive( stateLoading ) then
            self._hud._game:restoreCheckpoint() -- if already loading into game which has a restore event on the queue.
        else
    		statemgr.activate( stateLoading, function() self._hud._game:restoreCheckpoint() end )
        end

	elseif event.type == "ui" then
		local w = self._hud._screen.binder[event.widget]
		w:setVisible( event.visible )

	elseif event.type == "blink" then
		local object = blink_widget( self._hud, event.target, event.blink )
		table.insert( self.hiliteObjects, object )

	elseif event.type == "arrow" then
		local x, y
		if event.unit then
			x, y = event.unit:getLocation()
		elseif event.pos then
			x, y = event.pos.x, event.pos.y
		end
		x, y = self._hud._game.boardRig:cellToWorld( x, y )

		local object = hilite_arrow ( self._hud, event.name, event.scale, x, y )
		table.insert( self.hiliteObjects, object )

	elseif event.type == "tutorialCircle" then
		local object = hilite_widget( self._hud, event.name, event.scale, event.target , event.rectangle)
		table.insert( self.hiliteObjects, object )

	elseif event.type == "cameraCentre" then
		self._hud._game.boardRig:cameraCenterTwoPoints( event.x0,event.y0,event.x1,event.y1)

	elseif event.type == "pan" then
		self._hud._game:cameraPanToCell( event.x, event.y )
		if event.zoom then
			self._hud._game:getCamera():zoomTo( event.zoom )
		end

		if event.orientation then

			local facing = event.orientation
			local camera = self._hud._game:getCamera()				
			local orientation = 3
			if facing ~= 0 then
				orientation = facing/2 -1
			end

			camera:rotateOrientation( orientation )
		end

	elseif event.type == "unlockDoor" then		
		MOAIFmodDesigner.playSound( "SpySociety/Actions/door_passcardunlock", nil, nil, {event.x, event.y,0}, nil )

	elseif event.type == "stopVO" then	
		MOAIFmodDesigner.stopSound( "VO" )

	elseif event.type == "operatorVO" then	
		MOAIFmodDesigner.stopSound( "VO" )
		MOAIFmodDesigner.playSound( event.soundPath, "VO" )

	elseif event.type =="hideInterface" then
		self._hud:hideInterface()
	elseif event.type =="showInterface" then
		self._hud:showInterface()
	elseif event.type =="showMissionObjectives" then

		local serverdefs = include( "modules/serverdefs" )
	    local corpData = serverdefs.CORP_DATA[ self._hud._game.params.world ]
	    local situationData = serverdefs.SITUATIONS[ self._hud._game.params.situationName ]
	    local missionTxt = corpData.stringTable.SHORTNAME .." " .. situationData.ui.locationName

		modalDialog.showObjectivesDialog( missionTxt, situationData.ui.objectives, situationData.ui.secondary_objectives, situationData.ui.insetImg, corpData.imgs.logoLarge )
		
	elseif event.type =="showAlarmFirst" then
		modalDialog.showAlarmFirstDialog()

	elseif event.type =="showLoveProgram" then
		modalDialog.showLoveProgram()
		self._hud._mainframe_panel:slideMainframeProgram( 6 )

	elseif event.type == "modalConversation" then
		if event.script then 
			self._hud._screen:setVisible(false)
			MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/radiospeech_start")
			local storyheadscreen = mui.createScreen( "modal-story.lua" )
			mui.activateScreen( storyheadscreen )

            local talkinghead = include( "fe/talkinghead" )
			local modaltalkinghead = talkinghead( storyheadscreen, storyheadscreen.binder.Friends, true)
			modaltalkinghead:PlayScript(event.script)
            modaltalkinghead:FadeBackground( 0.25 * cdefs.SECONDS )
            self.modalTalkinghead = modaltalkinghead

			--wait for convo to finish
			while not modaltalkinghead:IsDone() and not self._skipping do
                self:yield()
			end
            
			modaltalkinghead:Hide()

            MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT ) 
            MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/radiospeech_stop")
            self._hud._screen:setVisible(true)	
            mui.deactivateScreen( storyheadscreen )
            self.modalTalkinghead = nil
        end

	elseif event.type == "newOperatorMessage" then 

		if event.debug then 
			print(event.debug)
		end 

		if event.script then 

			--if the talking head has a doNotQueue flag, don't play it if other things are already playing
			if not event.doNotQueue or self.talkinghead:IsDone() then
				mui.activateScreen( self._screen._operator_screen )
				self._screen._operator_screen:findWidget("instructionsTxt"):setText("")
				self._screen._operator_screen:findWidget("profileAnim"):setVisible(true)
				self.talkinghead:setOnFinishedFn(function() 
	        		if self._screen._operator_screen:isActive() then
	        			self._screen._operator_screen:findWidget("profileAnim"):setVisible(false)
	    				mui.deactivateScreen( self._screen._operator_screen )
	                end
					if self.talkinghead:shouldShowSubtitles() then 
						MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/radiospeech_stop")
						--MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT ) 
					end 
				end)
				MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/radiospeech_start")
				self.talkinghead:PlayScript( event.script )

				while not self.talkinghead:IsDone() and not event.parallel and not self._skipping do
                    self:yield()
				end

                if self._skipping then
                    self:stopTalkingHead()
                end
			end
		end 

	elseif event.type == "displayICEpulse" then
		local widget = self._hud._world_hud._screen:findWidget("BreakIce")
        if widget then
            local pulse = self._hud._world_hud._screen:createFromSkin( "Pulse" )
            widget.binder.btn:addChild( pulse )
        end
	elseif event.type == "hideICEpulse" then
		local widget = self._hud._world_hud._screen:findWidget("Pulse")
        if widget then
            widget._parent:removeChild( widget )
        end

	elseif event.type == "displayPeekpulse" then
		local object = hilite_widget( self._hud, "peek", 1, "peek" )
		table.insert( self.hiliteObjects, object )
	elseif event.type == "hidePeekpulse" then
		self:deleteObject("peek")

	elseif event.type == "displayObservePulse" then
		local object = hilite_widget( self._hud, "observePath", 1, "observePath" )
		table.insert( self.hiliteObjects, object )
	elseif event.type == "hideObservePulse" then
		self:deleteObject("observePath")	

	elseif event.type == "displayOverwatchMeleePulse" then
		local object = hilite_widget( self._hud, "overwatchMelee", 1, "overwatchMelee" )
		table.insert( self.hiliteObjects, object )
	elseif event.type == "hideOverwatchMeleePulse" then
		self:deleteObject("overwatchMelee")	

	elseif event.type == "displayHUDpulse" then
	
		self._pulse = self._hud._screen:findWidget("pulse")				

		self._pulseOffset = {x=0,y=0}
		if event.offset then
			--transform to UI space
			self._pulseOffset.x, self._pulseOffset.y = self._hud._screen:wndToUI( event.offset.x, event.offset.y )
			self._pulseOffset.y = 1 - self._pulseOffset.y
		end		

		local widget = self._hud._screen:findWidget(event.widget) or self._hud._world_hud._screen:findWidget(event.widget)

		if widget then
			local x, y = widget:getAbsolutePosition()
			self._pulse:setPosition( x + self._pulseOffset.x, y + self._pulseOffset.y )
		end
		
	 	self._pulse:setVisible(true)	
		self._pulse:getProp():setCurrentAnim("idle")

		if event.fly_image then
			local DURATION =2
		    self._flyImage = MOAICoroutine.new()
		    self._flyImage:run( function() 
				local duration = 0
		        while true do
		        	if duration <=  0 then
						local x1,y1 = event.fly_image:getLocation()
						local wx, wy = self._hud._game:cellToWorld(  x1, y1 )	

				 		self._hud:showFlyImage(  wx, wy, "incognitaFace", DURATION)	
				 		duration = DURATION * 60
				 	else
				 		duration = duration - 1
				 	end
                    self:yield()
		        end
		    end)
		end

	elseif event.type == "showIncognitaWarning" then
        self._hud:showWarning( event.txt )
        MOAIFmodDesigner.playSound(event.vo)
	elseif event.type == "hideHUDpulse" then
		self._pulse = self._hud._screen:findWidget("pulse")			
		self._pulse:setVisible(false)
 		if self._flyImage then
 			self._flyImage:stop()
 			self._flyImage = nil
 		end

	elseif event.type == "displayHUDInstruction" then

		self._hud._screen:findWidget("instructionGroup.instructionsTxt"):setVisible(false)
		self._hud._screen:findWidget("instructionGroup.instructionsTxtDrop"):setVisible(false)
		self._hud._screen:findWidget("instructionGroup.instructionsTxtNoLine"):setVisible(false)
		self._hud._screen:findWidget("instructionGroup.instructionsTxtNoLineDrop"):setVisible(false)
		self._hud._screen:findWidget("instructionGroup.instructionsSubTxtNoLine"):setVisible(false)
		self._hud._screen:findWidget("instructionGroup.instructionsSubTxtNoLineDrop"):setVisible(false)
		self._hud._screen:findWidget("instructionGroup.instructionsSubTxt"):setVisible(false)

		self._instructionOffset = {x=0,y=0}
		if event.offset then
			--transform to UI space
			self._instructionOffset.x, self._instructionOffset.y = self._hud._screen:wndToUI( event.offset.x, event.offset.y )
			self._instructionOffset.y = 1 - self._instructionOffset.y
		end

		local anim = self._hud._screen:findWidget("instructionGroup.anim")

		self._hideInstruction = false
		self._instructionTxt = nil
		self._instructionTxtDrop = nil
		self._instructionSubText = nil
		self._instructionSubTextDrop = nil
		self._followMovement = event.followMovement
		self._followWidget = event.widget
		if self._followMovement then
			self._instructionTxt = self._hud._screen:findWidget("instructionGroup.instructionsTxtNoLine")
			self._instructionTxtDrop = self._hud._screen:findWidget("instructionGroup.instructionsTxtNoLineDrop")
			anim:setVisible(false)

			--move the widget behind the hud elements
			local w = self._hud._screen:findWidget("instructionGroup")
			self._hud._screen:reorderWidget( w, 1 )
		elseif event.x and event.y then
			self._instructionOnCell = { x=event.x, y=event.y }
			self._instructionTxt = self._hud._screen:findWidget("instructionGroup.instructionsTxt")
			self._instructionTxtDrop = self._hud._screen:findWidget("instructionGroup.instructionsTxtDrop")
			anim:setVisible(true)
			anim:setAnim("in")

			--move the widget behind the hud elements
			local w = self._hud._screen:findWidget("instructionGroup")
			self._hud._screen:reorderWidget( w, 1 )
		elseif event.widget then
			self._followWidget = event.widget
			self._instructionTxt = self._hud._screen:findWidget("instructionGroup.instructionsTxt")
			self._instructionTxtDrop = self._hud._screen:findWidget("instructionGroup.instructionsTxtDrop")
			anim:setVisible(true)
			anim:setAnim("in")

			--move the widget in front of the hud elements
			local w = self._hud._screen:findWidget("instructionGroup")
			self._hud._screen:reorderWidget( w, nil )
		else
			error("NO PROPER DISPLAY TYPE:" .. util.stringize( event, 1 ))
		end

		self._instructionTxt:setVisible(true)
		self._instructionTxtDrop:setVisible(true)
		self._instructionTxt:spoolText(event.text,10)
		self._instructionTxtDrop:spoolText(event.text,10)

		if event.subtext then
			if self._followMovement then
				self._instructionSubText = self._hud._screen:findWidget("instructionGroup.instructionsSubTxtNoLine")
				self._instructionSubTextDrop = self._hud._screen:findWidget("instructionGroup.instructionsSubTxtNoLineDrop")
			else
				self._instructionSubText = self._hud._screen:findWidget("instructionGroup.instructionsSubTxt")
				self._instructionSubTextDrop = nil
			end

			if self._instructionSubTextDrop then
				self._instructionSubTextDrop:spoolText(event.subtext, 10)
				self._instructionSubTextDrop:setVisible(true)
				self._instructionSubTextDrop:setColor(0,0,0)
			end

			self._instructionSubText:spoolText(event.subtext, 10)
			self._instructionSubText:setVisible(true)
			self._instructionSubText:setColor(1,1,1,1)
		end

		self._hud._screen:findWidget("instructionGroup.leftclick"):setVisible(false)
		self._hud._screen:findWidget("instructionGroup.rightclick"):setVisible(false)

	elseif event.type == "hideHUDInstruction" then
		self._hideInstruction = true
		self._hud._screen:findWidget("instructionGroup.leftclick"):setVisible(false)
		self._hud._screen:findWidget("instructionGroup.rightclick"):setVisible(false)
		if self._instructionOnCell or self._followWidget then
			local anim = self._hud._screen:findWidget("instructionGroup.anim")		
			anim:setAnim("out")
		end
		self._instructionOnCell = nil
		self._followMovement = false
		self._followWidget = nil
		self._instructionsHighlightTimer = 0
		--self._hud._screen:findWidget("instructionGroup"):setVisible(false)

	elseif event.type == "enemyMessage" then	
		if not event.nosound then
			MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/Operator/textbox2" )
		end
		
		mui.activateScreen( self._screen._enemy_screen )
		
		self._screen._enemy_screen:findWidget("bodyTxt"):spoolText( event.body )
		self._screen._enemy_screen:findWidget("headerTxt"):setText( event.header )
		if not event.notransition then
			self._screen._enemy_screen:findWidget("Enemies"):createTransition( "activate_left" )
		end
		self._hud:showElement( false, "alarm" )

		if event.profileAnim then
			self._screen._enemy_screen:findWidget("profileAnim"):bindBuild( event.profileBuild )
			self._screen._enemy_screen:findWidget("profileAnim"):bindAnim( event.profileAnim )
		end

	elseif event.type == "clearEnemyMessage" then
		if self._screen._enemy_screen:isActive() then
			mui.deactivateScreen( self._screen._enemy_screen )	
			if not self._hud._game.simCore:getTags().isTutorial then
        		self._hud:showElement( true, "alarm" )
			end
		end

	elseif event.type == "clearOperatorMessage" then
		self:stopTalkingHead()

	elseif event.type == "fadeIn" then
		local camera = self._hud._game:getCamera()
		camera:rotateOrientation( event.orientation )

		self:startBlackScreen()
		self._fadingIn = true
		self._fadeInIndex = 0
		KLEIRenderScene:pulseUIFuzz( 0.5 )
		self._screen._black_screen:findWidget("black"):setColor(1,1,1,1)

		MOAIFmodDesigner.setAmbientReverb( "office" )

		FMODMixer:popMix("nomusic")
		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/Operator/largeconnection" )

	elseif event.type == "modalPopupBlindSpots" then

		local simdefs = include( "sim/simdefs" )

		if event.sound then
			MOAIFmodDesigner.playSound( event.sound )
		end
		if event.speech then
			MOAIFmodDesigner.playSound( event.speech )
		end			

		modalDialog.showBlindSpots()

	elseif event.type == "modalPopupManipulate" then

		local simdefs = include( "sim/simdefs" )

		if event.sound then
			MOAIFmodDesigner.playSound( event.sound )
		end
		if event.speech then
			MOAIFmodDesigner.playSound( event.speech )
		end			
		
		modalDialog.showManipulateDialog()


	elseif event.type == "showTurnbaseDialog" then


		local simdefs = include( "sim/simdefs" )

		if event.sound then
			MOAIFmodDesigner.playSound( event.sound )
		end
		if event.speech then
			MOAIFmodDesigner.playSound( event.speech )
		end			
		
		modalDialog.showTurnbaseDialog()

	elseif event.type == "showCornerPeekDialog" then

		local simdefs = include( "sim/simdefs" )

		if event.sound then
			MOAIFmodDesigner.playSound( event.sound )
		end
		if event.speech then
			MOAIFmodDesigner.playSound( event.speech )
		end			
		
		modalDialog.showCornerPeekDialog()



	elseif event.type == "modalPopupIncognita" then

		local simdefs = include( "sim/simdefs" )

		if event.sound then
			MOAIFmodDesigner.playSound( event.sound )
		end
		if event.speech then
			MOAIFmodDesigner.playSound( event.speech )
		end			
		
		modalDialog.showIncognitaDialog()


	elseif event.type == "modalPeekOpenPeek" then

		local simdefs = include( "sim/simdefs" )

		if event.sound then
			MOAIFmodDesigner.playSound( event.sound )
		end
		if event.speech then
			MOAIFmodDesigner.playSound( event.speech )
		end			
		
		modalDialog.showPeekOpenPeekDialog()

	elseif event.type == "modalPinning" then

		local simdefs = include( "sim/simdefs" )

		if event.sound then
			MOAIFmodDesigner.playSound( event.sound )
		end
		if event.speech then
			MOAIFmodDesigner.playSound( event.speech )
		end			
		
		modalDialog.showPinningDialog()

	elseif event.type == "modalPopupLockpick" then

		local simdefs = include( "sim/simdefs" )

		if event.sound then
			MOAIFmodDesigner.playSound( event.sound )
		end
		if event.speech then
			MOAIFmodDesigner.playSound( event.speech )
		end			
		
		modalDialog.showLockpickDialog()

	elseif event.type == "showWarning" then
		self._hud:showWarning( event.txt1, {r=1,g=1,b=1,a=1},  event.txt2 )
		MOAIFmodDesigner.playSound( event.sound ) 		
	elseif event.type == "desaturation" then
		if event.enable then
            KLEIRenderScene:setDesaturation( rig_util.linearEase("desat_ease") )
		    MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/HUD_undoAction" )
		else
			KLEIRenderScene:setDesaturation()
		end
	elseif event.type == "monst3rConsoleFx" then
			local boardrig = self._hud._game.boardRig
			if not self._monst3rConsole then
				local sim = self._hud._game.simCore

				local unit = nil
				for unitID, checkUnit in pairs(sim:getAllUnits()) do
					if checkUnit:hasTag("ending_jackin")then
						unit = checkUnit
					end				
				end
				if unit then
					local x0,y0 = unit:getLocation()
					local xw0, yw0 = boardrig:cellToWorld( x0,y0)
					self._monst3rConsole = boardrig:createHUDProp("kanim_monst3r_console_fx", "effect", "stage1_in", true,  boardrig:getUnitRig( unit:getID() ):getProp(), xw0, yw0  )--boardrig:getLayer("ceiling")
				end
			end
			self._monst3rConsole:setCurrentAnim("stage"..event.stage.."_in")	
			self._monst3rConsole:setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim, animname )
					if animname == "stage"..event.stage.."_in" then
						self._monst3rConsole:setCurrentAnim("stage"..event.stage.."_loop")	
					end
				end )
	elseif event.type == "finalHallLight" then			

		assert(event.cell)
		local x0,y0 = event.cell.x,event.cell.y
		MOAIFmodDesigner.playSound( "SpySociety/Objects/FinalRoom_lightON",  nil, nil, {x0,y0,0}, nil )
		local boardrig = self._hud._game.boardRig
		local orientation = boardrig._game:getCamera():getOrientation()

		local facing = event.console:getFacing() + 4
		if facing >= 8 then facing = facing - 8 end
		local decorInfo = {
	        x = x0, 
	        y = y0,
	        kanim = [[decor_final_floor_lights]],--
	        facing = facing,
		}
		local decorInfo2 = {
	        x = x0, 
	        y = y0,
	        kanim = [[decor_final_floor_lights_beam]],--
	        facing = facing,
		}		
		boardrig._decorig:createDeco(boardrig, decorInfo, orientation)
		boardrig._decorig:createDeco(boardrig, decorInfo2, orientation)
		boardrig._decorig:refreshCell( x0,y0 )

	else
		assert( false, event.type )
	end
end

function mission_panel:onUpdate()
	for i, hilite in ipairs( self.hiliteObjects ) do
		if hilite.refresh then
			hilite:refresh( self._hud )
		end
	end

	if self._fadingIn == true then
		self._fadeInIndex = self._fadeInIndex + 3
		if self._fadeInIndex < 100 then
			local t = self._fadeInIndex / 100
			self._screen._black_screen:findWidget("black"):setColor(1,1,1,mathutil.lerp(1,0,t))
		else
			self._fadingIn = false
			mui.deactivateScreen( self._screen._black_screen )
			--KLEIRenderScene:pulseUIFuzz( 0.2 )
		end
	end

	--jcheng: update the instructions so it glows
	if self._instructionTxt then
		if self._hideInstruction then
			self._instructionsHighlightTimer = self._instructionsHighlightTimer + 4
			local t = self._instructionsHighlightTimer / 100
			if t >=1 then t = 1 end

			self._instructionTxt:setColor(
				mathutil.inQuad( self._instructionsHighlightColor1.r , self._instructionsHighlightColor2.r ,t),
				mathutil.inQuad( self._instructionsHighlightColor1.g , self._instructionsHighlightColor2.g ,t),
				mathutil.inQuad( self._instructionsHighlightColor1.b , self._instructionsHighlightColor2.b ,t),
				mathutil.inQuad( self._instructionsHighlightColor1.a , 0 ,t)
			)
			self._instructionTxtDrop:setColor(0,0,0,
				mathutil.inQuad( self._instructionsHighlightColor1.a , 0 ,t)
			)

			if self._instructionSubText then
				self._instructionSubText:setColor(1,1,1,
					mathutil.inQuad( self._instructionsHighlightColor1.a , 0 ,t)
				)
			end

			if self._instructionSubTextDrop then
				self._instructionSubTextDrop:setColor(0,0,0,
					mathutil.inQuad( self._instructionsHighlightColor1.a , 0 ,t)
				)
			end

			if t >= 1 then
				--done fading out, set everything to nil
				self._hideInstruction = false
				self._instructionTxt = nil
				self._instructionTxtDrop = nil
				--self._hud._screen:findWidget("instructionGroup"):setVisible(false)
			end
		else
			if self._instructionsHighlightDirection > 0 then
				self._instructionsHighlightTimer = self._instructionsHighlightTimer + 2
				if self._instructionsHighlightTimer >= 100 then
					self._instructionsHighlightTimer = 100
					self._instructionsHighlightDirection = -1
				end
			else
				self._instructionsHighlightTimer = self._instructionsHighlightTimer - 2
				if self._instructionsHighlightTimer <= 0 then
					self._instructionsHighlightTimer = 0
					self._instructionsHighlightDirection = 1
				end
			end

			local t = self._instructionsHighlightTimer / 100

			self._instructionTxt:setColor(
				mathutil.inQuad( self._instructionsHighlightColor1.r , self._instructionsHighlightColor2.r ,t),
				mathutil.inQuad( self._instructionsHighlightColor1.g , self._instructionsHighlightColor2.g ,t),
				mathutil.inQuad( self._instructionsHighlightColor1.b , self._instructionsHighlightColor2.b ,t),
				mathutil.inQuad( self._instructionsHighlightColor1.a , self._instructionsHighlightColor2.a ,t)
			)
			self._instructionTxtDrop:setColor(0,0,0,
				mathutil.inQuad( self._instructionsHighlightColor1.a , self._instructionsHighlightColor2.a ,t)
			)
		end
	end

	--instructions
	if self._followMovement then

		local widget = self._hud._screen:findWidget("instructionGroup")
		if self._hud._bValidMovement then
			--local cell = self._hud._game.simCore:getCell( self._hud._game:wndToCell( inputmgr.getMouseXY() ) )
			--local wx, wy = self._hud._game:cellToWorld( cell.x, cell.y )
			local wndx, wndy = inputmgr.getMouseXY() --self._hud._game:worldToWnd( wx, wy )
			local uix, uiy = self._hud._screen:wndToUI( wndx, wndy )
			widget:setPosition( uix + self._instructionOffset.x, uiy + self._instructionOffset.y )
			widget:setVisible(true)
		else
			widget:setVisible(false)
		end

	elseif self._instructionOnCell then

		local wx, wy = self._hud._game:cellToWorld( self._instructionOnCell.x, self._instructionOnCell.y )
		local wndx, wndy = self._hud._game:worldToWnd( wx, wy )
		local widget = self._hud._screen:findWidget("instructionGroup")
		local uix, uiy = self._hud._screen:wndToUI( wndx, wndy )
		widget:setPosition( uix + self._instructionOffset.x, uiy + self._instructionOffset.y )
		widget:setVisible(true)

	elseif self._followWidget then

		local instructionWidget = self._hud._screen:findWidget("instructionGroup")
		local widget = self._hud._screen:findWidget(self._followWidget) or self._hud._world_hud._screen:findWidget(self._followWidget)
		
		if widget then
			local x, y = widget:getAbsolutePosition()

			instructionWidget:setPosition( x + self._instructionOffset.x, y + self._instructionOffset.y )
			instructionWidget:setVisible(true)
		else
			instructionWidget:setVisible(false)
		end
	end
end

function mission_panel:isBusy()
	local eventQueue = self._hud._game.simCore:getLevelScript():getQueue()
    return self._busy or #eventQueue > 0
end

function mission_panel:processQueue( eventQueue )
	local eventQueue = self._hud._game.simCore:getLevelScript():getQueue()

	while true do
        self._busy = #eventQueue > 0
		if #eventQueue > 0 then
			local event = table.remove( eventQueue, 1 )
			self:processEvent( event )
		else
			coroutine.yield()
		end
	end
end

function mission_panel:printDebug()
	local eventQueue = self._hud._game.simCore:getLevelScript():getQueue()
    for i, ev in ipairs( eventQueue ) do
        print( i, util.stringize(ev,1) )
    end
    print( debug.traceback( self._thread:getThread() ))
end

function mission_panel:clear()
	self._fadingIn = nil

    if self.modalTalkinghead then
        self.modalTalkinghead:Hide()
        mui.deactivateScreen( self.modalTalkinghead.screen )
        self.modalTalkinghead = nil
    end

	if self._screen._operator_screen and self._screen._operator_screen:isActive() then
		mui.deactivateScreen( self._screen._operator_screen )
	end
	self._screen._operator_screen = nil

	if self._screen._enemy_screen and self._screen._enemy_screen:isActive() then
		mui.deactivateScreen( self._screen._enemy_screen )
	end

	if self._screen._black_screen and self._screen._black_screen:isActive() then
		mui.deactivateScreen( self._screen._black_screen )
	end
	
	while #self.hiliteObjects > 0 do
		self:deleteObject( self.hiliteObjects[1]:getName() )
	end
end

function mission_panel:destroy()
    FMODMixer:removeAutoMix( "talkinghead_voice" )

	self:clear()
	
	self.talkinghead:Stop()
	
	if self._flyImage then
		self._flyImage:stop()
		self._flyImage = nil
	end

	self._thread:stop()
	self._thread = nil
end

return mission_panel
