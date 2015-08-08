----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local animmgr = include( "anim-manager" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local rig_util = include( "gameplay/rig_util" )
local rand = include( "modules/rand" )
local binops = include( "modules/binary_ops" )
local unitrig = include( "gameplay/unitrig" )
local coverrig = include( "gameplay/coverrig" )
local world_hud = include( "hud/hud-inworld" )
local flagui = include( "hud/flag_ui" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local modalDialog = include( "states/state-modal-dialog" )
local animdefs = include( "animdefs" )

-----------------------------------------------------------------------------------
-- Local

local function lookupAnimDef( name )
	return animdefs.defs[ name ]
end

local function GetAnimResource( build )
    if gSupportNewXANIM then
	    build = string.gsub( build, "data/anims/characters/", "data/xanims/characters/" )
	    build = string.gsub( build, ".adef", ".xanm" )
	    build = string.gsub( build, ".abld", ".xanm" )
    end
	return KLEIResourceMgr.GetResource(build)
end

local function applyKanim( kanim, prop )
	if type(kanim.build) == "table" then
		for i,build in ipairs(kanim.build) do
			prop:bindBuild( GetAnimResource(build) )
		end
	elseif type(kanim.build) == "string" then
		prop:bindBuild( GetAnimResource(kanim.build) )
	end

	for i,anim in ipairs(kanim.anims) do
		prop:bindAnim( GetAnimResource(anim) )
	end

	for _,build in ipairs(kanim.wireframe or {}) do
		prop:bindWireframeBuild( GetAnimResource(build) )
	end
end

local function unapplyKanim( kanim, prop )
	if type(kanim.build) == "table" then
		for i,build in ipairs(kanim.build) do
			prop:unbindBuild( GetAnimResource(build) )
		end
	elseif type(kanim.build) == "string" then
		prop:unbindBuild( GetAnimResource(kanim.build) )
	end

	for i,anim in ipairs(kanim.anims) do
		prop:unbindAnim( GetAnimResource(anim) )
	end

	for _,build in ipairs(kanim.wireframe or {}) do
		prop:unbindWireframeBuild( GetAnimResource(build) )
	end
end

local function getLeanDir(unit)
	if unit:getTraits().disguiseOn then
		return nil
	end	
	return simquery.getAgentLeanDir(unit)
end

local function getCoverDir(unit)
	if unit:getTraits().disguiseOn then
		return nil
	end	
	return simquery.getAgentCoverDir(unit)
end

local function getIdleFacing(sim, unit)
	if unit:isPC() and unit:getLocation() and not unit:getTraits().takenDrone and not unit:getTraits().movingBody then
		-- Should lean against cover?
		local dir = getCoverDir(unit) 
		if dir then
			return dir
		end

		-- Should lean against a wall?
		dir = getLeanDir(unit)
		if dir then
			return dir
		end
	end
	return unit:getFacing()
end

local function doKOanim(self, thread, fx )

	local unit = self._rig:getUnit()
	if unit:getSounds().getko then
		self._rig:playSound( unit:getSounds().getko )
	end

	if fx then
		if fx == "emp" then
			self._rig:addAnimFx( "fx/emp_effect", "character", "idle", true )	
		end
	end

	local sounds = {{sound=unit:getSounds().land,soundFrames=unit:getSounds().land_frame}}	

	if unit:getSounds().fall_knee then
		table.insert(sounds,{sound=unit:getSounds().fall_knee ,soundFrames=unit:getSounds().fall_kneeframe})
	end
	if unit:getSounds().fall_hand then
		table.insert(sounds,{sound=unit:getSounds().fall_hand ,soundFrames=unit:getSounds().fall_handframe})
	end	

	if unit:getSounds().fall then
		table.insert(sounds,{sound=unit:getSounds().fall,soundFrames=3})
	end

	if unit:getSounds().close then
		table.insert(sounds,{sound=unit:getSounds().close,soundFrames=unit:getSounds().close_frame})
	end

    self:waitForAnim( "ko", nil,nil, sounds )
end


local function getIdleAnim( sim, unit )
	local coverDir, leanDir = getCoverDir(unit), getLeanDir(unit)
	
	if unit:isDead() or unit:getTraits().iscorpse then
		return "dead"

	elseif unit:isKO() then		
		return "idle_ko"
		
	elseif unit:getTraits().isMeleeAiming then
		if coverDir then
			return "overwatchcrouch_melee_idle", coverDir
		else
			return "overwatch_melee", leanDir
		end

	elseif unit:isAiming() then
		if coverDir then
			return "overwatchcrouch_idle", coverDir
		else
			return "overwatch", leanDir
		end

	elseif unit:getTraits().isLyingDown then
		return "idle_ko"

	elseif unit:getTraits().monster_hacking then 
		return "tinker_loop"

	elseif unit:getTraits().movingBody then
		return "body_drag_idle"

    elseif unit:isPC() and not unit:getTraits().takenDrone and simquery.isUnitUnderOverwatch(unit) then
        return "overwatch_melee" -- shrug.. this is the anim we want when you're targetted!

	elseif simquery.isUnitPinning( sim, unit ) then						
		return "pin",nil,unit:getSounds().pin

    elseif unit:getTraits().movePath ~= nil and unit:isGhost() then
        return "walk" -- This should only happen for ghosts.

	elseif unit:isPC() and unit:getLocation() and not unit:getTraits().takenDrone then
		local cell = sim:getCell( unit:getLocation() )
		-- Any half-wall covers to hide behind?
		if coverDir then
			return "hide", coverDir, unit:getSounds().crouchcover
		end
		-- Should lean against a wall?
		if leanDir then
			return "lean", leanDir, unit:getSounds().wallcover
		end
	end

	return "idle"
end

local function waitForIdlePre(state, unit, standing)
	local idleAnim, idleFacing, foleySnd = getIdleAnim(unit:getSim(), unit )

	if idleAnim == "idle" then 
		local currentAnim = state._rig._prop:getCurrentAnim()
		if currentAnim == "shoot_pst" or currentAnim == "use_door_pst" or currentAnim == "shoot_pst" then
			--these animations don't need to play idle_pre
			return
		end
	end

	if idleAnim ~= "dead" and idleAnim ~= "idle_ko" and idleAnim ~= "body_drag_idle" then	
		if foleySnd then
			state._rig:playSound(foleySnd)
		end
		if idleAnim == "overwatchcrouch_melee_idle"
		 or idleAnim == "overwatchcrouch_idle" then
			state:waitForAnim("pin_pre", idleFacing, 5)
		else
			state:waitForAnim(idleAnim.."_pre", idleFacing)
		end
	end
	
end

local function getShoulderDir(unit, x, y)
	if not unit:getTraits().hidesInCover then
		return nil
	end
	local facingDir = getIdleFacing(unit:getSim(), unit)
	local x0, y0 = unit:getLocation()
	local facingX, facingY = simquery.getDeltaFromDirection(facingDir)
	local sideX, sideY = -facingY, facingX
	local x1, y1 = x0+facingX, y0+facingY
	local x2, y2 = x0+sideX, y0+sideY

	--let's check to see that the point is actually on the correct side of the cover
	local side_det = (x2-x0)*(y-y0) - (y2-y0)*(x-x0)
	if side_det > 0 then
		--let's check which side of the cover it's on
		local det = (x1-x0)*(y-y0) - (y1-y0)*(x-x0)
		if det > 0 then
			return "L"
		elseif det <= 0 then
			return "R"
		end
	end
end


-----------------------------------------------------------------------------------
-- agentrig FSM

local function handleUseComp( self, unit, ev )
	

    if simquery.isUnitPinning(unit:getSim(), unit ) then
		self:waitForAnim("pin_stand")
	elseif getCoverDir(unit) then
		self:waitForAnim( "hide_pst", getIdleFacing(unit:getSim(), unit) )
	elseif getLeanDir(unit) then
		self:waitForAnim( "lean_pst", getIdleFacing(unit:getSim(), unit) )
	end

	local sounds = {{sound=ev.eventData.sound,soundFrames=ev.eventData.soundFrame}}

	local anim = "use_comp"
	if ev.eventData.useTinker then
		anim = "tinker"
	elseif ev.eventData.useTinkerMonst3r then
		anim = "tinker_loop"
	end

	if ev.eventData.useTinkerMonst3r then 
		self:waitForAnim( "tinker", ev.eventData.facing, nil, sounds)

		ev.thread:unblock()
		
		if ev.eventData.useTinker then
			self:waitForAnim( "tinker_pst", ev.eventData.facing, nil)
		end

		if ev.eventData.targetID then
			MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/node_capture")
			self._rig._boardRig:getUnitRig( ev.eventData.targetID ):addAnimFx( "gui/hud_fx", "wireless_console_takeover", "idle" )
		end

		--waitForIdlePre(self, unit)

		self._rig:setPlayMode( KLEIAnim.LOOP )
		self._rig:setCurrentAnim(anim, ev.eventData.facing)
	else 
		self:waitForAnim( anim, ev.eventData.facing, nil, sounds)

		ev.thread:unblock()
		
		if ev.eventData.useTinker then
			self:waitForAnim( "tinker_pst", ev.eventData.facing, nil)
		end

		if ev.eventData.targetID then
			MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/node_capture")
			self._rig._boardRig:getUnitRig( ev.eventData.targetID ):addAnimFx( "gui/hud_fx", "wireless_console_takeover", "idle" )
		end

		waitForIdlePre(self, unit, true)

		self._rig:refresh()
	end 

end

local function getSpeechParams(unit, speech)
    if speech:find("<voice>") then
	    speech = string.gsub(speech, "<voice>", unit:getTraits().voice)
    end
    local speechAlias = "speech"..unit:getID()
    return speech, speechAlias
end

local function handleSpeechEvent(self, unit, speech, speechData)
    if speech then
	    local x0,y0 = unit:getLocation()
	    local speech, speechAlias = getSpeechParams(unit, speech)
		if speechData and speechData.neverInterrupt and self._boardRig:getSounds():isSoundPlaying(speechAlias) then
			return
		end
        self._boardRig:getSounds():stopSound(speechAlias)
	    self._boardRig:getSounds():playSound( speech, speechAlias, x0, y0,
            function()
                if self._flagUI then
                    self._flagUI:hideSpeech()
                end
            end )
        if self._flagUI then
            self._flagUI:showSpeech()
        end
    end
end

local function waitForSpeech(self, unit, speech, speechData)
    if speech then
	    local x0,y0 = unit:getLocation()
	    local speech, speechAlias = getSpeechParams(unit, speech)
		if speechData and speechData.neverInterrupt and self._boardRig:getSounds():isSoundPlaying(speechAlias) then
			return
		end
        self._boardRig:getSounds():stopSound(speechAlias)
        local speechDone = false
		if self._flagUI then
		    self._flagUI:showSpeech()
		end
	    self._boardRig:getSounds():playSound( speech, speechAlias, x0, y0,
            function()
            	speechDone = true
            end )
		while not speechDone do
			coroutine.yield()
		end
		if self._flagUI then
		    self._flagUI:hideSpeech()
		end
    end
end

local function handlePeek( self, unit, ev )

	ev.thread:unblock()

	local peekInfo = ev.eventData.peekInfo
	local x0, y0 = self._rig._boardRig:cellToWorld(peekInfo.x0, peekInfo.y0)
	local x1, y1 = self._rig._boardRig:cellToWorld(peekInfo.x0 + peekInfo.dx, peekInfo.y0 + peekInfo.dy)
	if peekInfo and peekInfo.cellvizCount > 0 then
		self._rig._boardRig._game:cameraPanToCell( peekInfo.x0 + peekInfo.dx * 2, peekInfo.y0 + peekInfo.dy * 2 )
	end

	--foley
	if unit:getSounds().peek_fwd then
		self._rig:playSound( unit:getSounds().peek_fwd )
	end

	--print("PEEKINFO "..util.debugPrintTable(peekInfo, 2) )
	if peekInfo.exit and peekInfo.exit.closed and (peekInfo.dx == 0 or peekInfo.dy == 0) then
		if not simquery.isUnitPinning(unit:getSim(), unit ) then
			if getCoverDir(unit) then
				self:waitForAnim( "hide_pst", getIdleFacing(unit:getSim(), unit) )
			elseif getLeanDir(unit) then
				self:waitForAnim( "lean_pst", getIdleFacing(unit:getSim(), unit) )
			else
				self:waitForAnim( "door_peek_pre", peekInfo.dir )
			end
		end
		self._rig:playSound( "SpySociety/Actions/door_peek")

		self:waitForAnim( "door_peek_pst", peekInfo.dir )

		waitForIdlePre(self, unit, true)
	else
		local shoulder = not simquery.isUnitPinning(unit:getSim(), unit) and getShoulderDir(unit, peekInfo.x0 + peekInfo.dx, peekInfo.y0 + peekInfo.dy)
		if shoulder and getCoverDir(unit) then
			self:waitForAnim("hide_peek_pre_"..shoulder, getIdleFacing(unit:getSim(), unit) )
			self:waitForAnim("peek_"..shoulder, getIdleFacing(unit:getSim(), unit) )

			if unit:getSounds().peek_bwd then
				self._rig:playSound( unit:getSounds().peek_bwd )
			end

			if simquery.isUnitPinning(unit:getSim(), unit ) then
				waitForIdlePre(self, unit)
			else
				self:waitForAnim("hide_peek_pst_"..shoulder, getIdleFacing(unit:getSim(), unit) )
			end
		elseif shoulder and getLeanDir(unit) then
			self:waitForAnim("lean_peek_pre_"..shoulder, getIdleFacing(unit:getSim(), unit) )
			self:waitForAnim("peek_"..shoulder, getIdleFacing(unit:getSim(), unit) )

			if unit:getSounds().peek_bwd then
				self._rig:playSound( unit:getSounds().peek_bwd )
			end
			if simquery.isUnitPinning(unit:getSim(), unit ) then
				waitForIdlePre(self, unit, true)
			else
				self:waitForAnim("lean_peek_pst_"..shoulder, getIdleFacing(unit:getSim(), unit) )
			end
		elseif shoulder then
			if simquery.isUnitPinning(unit:getSim(), unit ) then
				self:waitForAnim("pin_stand") 
			end
			self:waitForAnim( "peek_bwrd", simquery.getReverseDirection(peekInfo.dir) or getIdleFacing(unit:getSim(), unit) )

			if unit:getSounds().peek_bwd then
				self._rig:playSound( unit:getSounds().peek_bwd )
			end

			self:waitForAnim( "peek_pst_bwrd", simquery.getReverseDirection(peekInfo.dir) or getIdleFacing(unit:getSim(), unit) )

			waitForIdlePre(self, unit, true)
		else
			if simquery.isUnitPinning(unit:getSim(), unit ) then
				self:waitForAnim("pin_stand") 
			end
			self:waitForAnim( "peek_fwrd", peekInfo.dir or getIdleFacing(unit:getSim(), unit) )

			if unit:getSounds().peek_fwd then
				self._rig:playSound( unit:getSounds().peek_fwd )
			end

			self:waitForAnim( "peek_pst_fwrd", peekInfo.dir or getIdleFacing(unit:getSim(), unit) )

			waitForIdlePre(self, unit, true)
		end
	end

end

local function handleStand( self, unit )
	if unit:getSounds().getup then
		self._rig:playSound(unit:getSounds().getup)
	end

	if unit:getSounds().wakeup then
		self._rig:playSound(unit:getSounds().wakeup)
	end

	local oldFacing = self._rig:getFacing()	

	local sounds = {}
	if unit:getSounds().open then
		table.insert(sounds,{sound=unit:getSounds().open,soundFrames=unit:getSounds().open_frame})
	end

	self:waitForAnim( "get_up",oldFacing, nil, sounds)

	local orientation = self._rig._boardRig._game:getCamera():getOrientation()*2
	oldFacing = oldFacing - orientation

	if oldFacing < 0 then
		oldFacing = oldFacing + simdefs.DIR_MAX
	end
	
	local branchTimes = {11,9,9,17,nil,15,13,11}
	local branch = branchTimes[oldFacing+1]

	self:waitForAnim( "get_up_pst",nil,branch)
	waitForIdlePre(self, unit)

	self._rig:transitionUnitState( self._rig._idleState )
end

-------------------------------------------------------------
local idle_state = class( unitrig.base_state )

function idle_state:init( rig )
	unitrig.base_state.init( self, rig, "idle" )
end

function idle_state:onEnter()
	local isCrouching = false
	local unit = self._rig:getUnit()

	local idleAnim, idleFacing, folleySnd = getIdleAnim( self._rig._boardRig:getSim(), unit )
	self._rig:setCurrentAnim( idleAnim, idleFacing )

	if self:shouldPlayCustomIdles(unit) then
		if self.idle then
			self._rig:setCurrentAnim(self.idle.idle)
		end

		self.idleCount = self.idleCount or 0
		self._rig._prop:setListener( KLEIAnim.EVENT_ANIM_END,
			function( anim, animName )
				self:animDone(anim, animName)
			end )
	end

	if unit:isGhost() then
		self._rig:setPlayMode( KLEIAnim.STOP )
	else
		if idleAnim == "overwatch" and unit:isNPC() then
		 	self._rig:setPlayMode( KLEIAnim.ONCE )
		else
			self._rig:setPlayMode( KLEIAnim.LOOP )
		end
	end
end

function idle_state:shouldPlayCustomIdles(unit)

	if unit:isPC() then
		return getIdleAnim(unit:getSim(), unit) == "idle"
		 and unit:getUnitData().idles
	else
		return getIdleAnim(unit:getSim(), unit) == "idle"
		 and (unit:isGhost() or not unit:isAlerted()) and unit:getBrain() and not unit:getBrain():getInterest()
		 and unit:getUnitData().idles
		 and ((unit:getTraits().patrolPath and #unit:getTraits().patrolPath == 1) or not unit:getTraits().patrolPath )
         and (getIdleFacing(unit:getSim(), unit) % 2 == 0)
	end
end

function idle_state:onExit()
	self._rig._prop:setListener( KLEIAnim.EVENT_ANIM_END, nil)
end

function idle_state:animDone(anim, animName)
	if not self.idleCount then
		return
	end
	local unit = self._rig:getUnit()
	local nextAnim, sounds
	local facing = getIdleFacing(unit:getSim(), unit)
	if self.idleCount == 0 then
		if self.idle then
			local min, max = self.idle.idleCounts and self.idle.idleCounts.min or 8, self.idle.idleCounts and self.idle.idleCounts.max or 15
			self.nextIdle = math.random(min, max)
			nextAnim = self.idle.idle
			sounds = self.idle.sounds
		else
			if self:shouldPlayCustomIdles(unit) then
				self.nextIdle = math.random(5, 10)
			else
				self.nextIdle = nil
				self.idleCount = nil
			end
			nextAnim, facing = getIdleAnim(unit:getSim(), unit)
		end
		self._rig:setCurrentAnim(nextAnim, facing, sounds)
		if not self.nextIdle then
			return
		end
	end
	if not self.idle or animName == self.idle.idle then
		self.idleCount = self.idleCount + 1
	end
	if self.idleCount >= self.nextIdle or not self:shouldPlayCustomIdles(unit) then
		self.idleCount = 0
		if self.idle or not self:shouldPlayCustomIdles(unit) then	--go back to default idle
			if self.idle then
				nextAnim = self.idle.pst
				sounds = self.idle.sounds
			else
				nextAnim, facing = getIdleAnim(unit:getSim(), unit)
			end
			self.idle = nil
			self.nextAction = nil
		else --go into a random idle
			self.idle = unit:getUnitData().idles[math.random(#unit:getUnitData().idles) ]
			nextAnim = self.idle.pre
			sounds = self.idle.sounds
			if self.idle.action then
				self.nextAction = math.random(1, 5)
			end
		end
		self._rig:setCurrentAnim(nextAnim, facing, sounds)
	elseif self.idle and self.idle.action and self.idleCount >= self.nextAction then
		self.nextAction = self.idleCount + math.random(1, 5)
		self._rig:setCurrentAnim(self.idle.action, facing, self.idle.sounds)
	elseif self.idle and animName == self.idle.action then
		self._rig:setCurrentAnim(self.idle.idle, facing, self.idle.sounds)
	end
end

function idle_state:onSimEvent( ev, eventType, eventData )
	local unit = self._rig:getUnit()
	if unit:isGhost() then
		if eventType == simdefs.EV_UNIT_START_WALKING then
			self._rig:transitionUnitState( self._rig._walkState, ev )
		end

	else
		unitrig.base_state.onSimEvent( self, ev, eventType, eventData )
	
		if eventType == simdefs.EV_UNIT_START_WALKING then
			self._rig:transitionUnitState( self._rig._walkState, ev )

		elseif eventType == simdefs.EV_UNIT_START_SHOOTING then
			self._rig:refreshLocation()	
			self._rig:transitionUnitState( self._rig._shootState, ev )
		
		elseif eventType == simdefs.EV_UNIT_HIT then
			self._rig:transitionUnitState( self._rig._hitState, ev, self._rig._idleState )	
			
        elseif eventType == simdefs.EV_UNIT_REFRESH then
			if eventData.fx and eventData.fx == "emp" and self._rig._boardRig:canPlayerSeeUnit( eventData.unit ) then				
				self._rig:addAnimFx( "fx/emp_effect", "character", "idle", true )
			end	
            self._rig:refresh()
            return true

		elseif eventType == simdefs.EV_UNIT_RELOADED then
			self._rig:transitionUnitState( self._rig._reloadState, ev )				

		elseif eventType == simdefs.EV_UNIT_USEDOOR then
			self._rig:refreshLocation()	
			self._rig:transitionUnitState( self._rig._usedoorState, ev )	

		elseif eventType == simdefs.EV_UNIT_HEAL then
			self._rig:refreshLocation()	
			self._rig:transitionUnitState( self._rig._healState, ev )

		elseif eventType == simdefs.EV_UNIT_RESCUED then
			self._rig:refreshLocation()
			waitForIdlePre(self, eventData.unit)

		elseif eventType == simdefs.EV_UNIT_INSTALL_AUGMENT then 
			self._rig:addAnimFx( "fx/emp_effect", "character", "idle", true )	

		elseif eventType == simdefs.EV_UNIT_PICKUP then
			self._rig:refreshLocation()	
			self._rig:transitionUnitState( self._rig._pickupState, ev )	

		elseif eventType == simdefs.EV_UNIT_KO then
            if eventData.stand then
                handleStand( self, eventData.unit )
            else
    			self._rig:eraseInterest()
				doKOanim( self, ev.thread, eventData.fx )
            end

		elseif eventType == simdefs.EV_UNIT_MELEE then		
			self._rig:refreshLocation()
			self._rig:transitionUnitState( self._rig._meleeState, ev )	

		elseif eventType == simdefs.EV_UNIT_DEATH then
			local sounds = {{sound=unit:getSounds().land,soundFrames=unit:getSounds().land_frame}}	
			if unit:getSounds().explode then
				table.insert(sounds,{sound=unit:getSounds().explode,soundFrames=unit:getSounds().explode_frame})
			end
			if unit:getSounds().explode2 then
				table.insert(sounds,{sound=unit:getSounds().explode2,soundFrames=unit:getSounds().explode2_frame})
			end			
			if unit:getSounds().fall then
				table.insert(sounds,{sound=unit:getSounds().fall,soundFrames=3})
			end

			if unit:getSounds().die then
				self._rig:playSound( "SpySociety/Agents/"..unit:getTraits().voice .."/"..unit:getSounds().die)
			end

			if not unit:isKO() then
				self:waitForAnim( "death", nil,nil, sounds )
			end

            self._rig:refresh( ev )
			self._rig:eraseInterest()
		
		elseif eventType == simdefs.EV_UNIT_USECOMP then
			handleUseComp( self, unit, ev )

		elseif eventType == simdefs.EV_UNIT_LOOKAROUND then
			self._rig:refreshLocation()	
			self._rig:transitionUnitState( self._rig._lookaroundState, ev )	

		elseif eventType == simdefs.EV_UNIT_DRAG_BODY then
			self._rig:refreshLocation()
			self._rig:refreshHUD( unit )
			self._rig:transitionUnitState( self._rig._dragBodyState, ev )

		elseif eventType == simdefs.EV_UNIT_DROP_BODY then
			self._rig:refreshLocation()	
			self._rig:refreshHUD( unit )
			self._rig:transitionUnitState( self._rig._dropBodyState, ev )	

		elseif eventType == simdefs.EV_UNIT_BODYDROPPED then
			self._rig:refreshLocation()	
			self._rig:refreshProp()
			self._rig:transitionUnitState( self._rig._bodyDropState, ev )	

		elseif eventType == simdefs.EV_UNIT_DONESEARCHING then
			self._rig:refreshLocation()	
			self._rig:transitionUnitState( self._rig._shrugState, ev )	

		elseif eventType == simdefs.EV_UNIT_TURN then
			self._rig:refreshLocation()
			self._rig:refreshProp()

		elseif eventType == simdefs.EV_UNIT_PEEK then
			handlePeek( self, unit, ev )
			self:onEnter()

		elseif eventType == simdefs.EV_UNIT_THROW then
			self._rig:refreshLocation()	
			self._rig:transitionUnitState( self._rig._throwState, ev )	

		elseif eventType == simdefs.EV_UNIT_OVERWATCH_MELEE then
			local coverDir, leanDir = getCoverDir(unit), getLeanDir(unit)	
			if eventData.cancel then
				if coverDir then
					self:waitForAnim("overwatchcrouch_melee_pst", coverDir)
				elseif leanDir then
					self:waitForAnim("lean_meleeoverwatch_pst", leanDir)					
				else
				-- 	self:waitForAnim( "overwatch_melee_pst", leanDir) --anim doesn't exist yet?
					waitForIdlePre(self, unit)
				end
			else
				if coverDir then
					self:waitForAnim("overwatchcrouch_melee_pre", coverDir)
				elseif leanDir then
					self:waitForAnim("lean_meleeoverwatch_pre", leanDir)					
				else
					self:waitForAnim( "overwatch_melee_pre")
				end
			end
			self:onEnter()

		elseif eventType == simdefs.EV_UNIT_OVERWATCH then			
			local coverDir, leanDir = getCoverDir(unit), getLeanDir(unit)	
			local sounds = {}
			if eventData.cancel then
				if unit:getSounds().overwatch_pst then
					table.insert(sounds, {sound=unit:getSounds().overwatch_pst, soundFrames=2})	
				end

				if coverDir then
					self:waitForAnim( "overwatchcrouch_pst",coverDir,nil,sounds)
				elseif leanDir then
					self:waitForAnim("lean_overwatch_pst", leanDir,nil,sounds)					
				else
					self:waitForAnim( "shoot_pst",nil,nil,sounds )
					waitForIdlePre(self, unit)
				end
			else		
				if unit:getSounds().overwatch_pre then
					table.insert(sounds, {sound=unit:getSounds().overwatch_pre, soundFrames=2})	
				end

				if coverDir then
					self:waitForAnim( "overwatchcrouch_pre",coverDir,nil,sounds )
				elseif leanDir then
					self:waitForAnim("lean_overwatch_pre", leanDir,nil,sounds )					
				else
					self:waitForAnim( "overwatch_pre",nil,nil,sounds )
				end
			end		
			self:onEnter()

		elseif eventType == simdefs.EV_UNIT_GUNCHECK then
			if simquery.getEquippedGun(unit) and not unit:isKO() then
				self:waitForAnim("shoot_pre", eventData.facing)
				self:waitForAnim("shoot_pst", eventData.facing)
				self:onEnter()				
			end
		elseif eventType == simdefs.EV_UNIT_TINKER_END then
			self:waitForAnim( "tinker_pst")
			local unit = self._rig:getUnit()
			waitForIdlePre(self, unit, true)
		elseif eventType == simdefs.EV_UNIT_GOTO_STAND then
			if eventData.stand then
				if not simquery.isUnitPinning(unit:getSim(), unit ) and not unit:getTraits().movingBody then
					if getCoverDir(unit) then
						self:waitForAnim( "hide_pst", getIdleFacing(unit:getSim(), unit) )
					elseif getLeanDir(unit) then
						self:waitForAnim( "lean_pst", getIdleFacing(unit:getSim(), unit) )				
					end
				end	
			else 
				waitForIdlePre(self, unit, true)
			end	

		end
	end
end

-------------------------------------------------------------

local walking_state = class( unitrig.base_state )

function walking_state:init( rig )
	unitrig.base_state.init( self, rig, "walking" )
end

function walking_state:onEnter( ev )
	unitrig.base_state.onEnter( self )
	
	self._wasSeen = self._rig._boardRig:canPlayerSee( self._rig:getLocation() )
	self._beenSeen = self._wasSeen

	-- Only perform preamble if visible, not if invisible or ghosted.
	local unit = self._rig:getUnit()

	if self._wasSeen then
		if unit:getPlayerOwner() == self._rig._boardRig:getLocalPlayer() then
			self._rig._boardRig:cameraLock( self._rig:getProp() )
		end

		if unit:getUnitData().sounds.walk_pre then
			self._rig:playSound( unit:getUnitData().sounds.walk_pre )
		end	

		if unit:getTraits().walk and not unit:getTraits().movingBody then
			-- Note: ev may be nil if we entered not because of EV_START_WALKING, but perhaps some other event (eg. EV_UNIT_HIT)
			if ev and ev.eventData.reverse and not unit:getTraits().isDrone then
				self._rig:setCurrentAnim( "walk180")
			else
				self:waitForAnim( "walk_pre" )
			end
		end
	end

	if unit:getSounds().move_loop then
		self._rig:playSound( unit:getUnitData().sounds.move_loop, "move_loop" )
 	end			

	if unit:getSounds().move_loop_param then
		MOAIFmodDesigner.setSoundProperty( self._rig._spotSound, unit:getSounds().move_loop_param,1 )
	end

	if unit:getTraits().movingBody then
		self._dragSound = "drag_loop"
		self._rig:playSound(simdefs.SOUNDPATH_DRAG_HARDWOOD, self._dragSound )
 	end			
end

function walking_state:onExit()
	unitrig.base_state.onExit( self )

	self._rig._boardRig:cameraLock( nil )

	if self._easeDriver ~= nil then
		self._easeDriver:stop()
		self._easeDriver = nil
	end

	if self._losDriver ~= nil then
		self._losDriver:stop()
		self._losDriver = nil
	end
	if self._losProp then
		self._rig._boardRig:refreshLOSCaster( self._rig._unitID )
		self._losProp = nil
	end
	
    local unit = self._rig:getUnit()
    if unit then
	    self._rig:refreshProp( true )
	    if unit:getSounds().move_loop then
		    MOAIFmodDesigner.stopSound( "move_loop")
	    end	

	    if unit:getSounds().move_loop_param then
		    MOAIFmodDesigner.setSoundProperty( self._rig._spotSound, unit:getSounds().move_loop_param,0 )
	    end
    end


	if self._dragSound then
    	self._rig._boardRig:getSounds():stopSound( self._dragSound )
		self._dragSound = nil
	end	

	self:destroyGhostFade()
end

function walking_state:onSimEvent( ev, eventType, eventData )

	if eventType == simdefs.EV_UNIT_STOP_WALKING then
		if self._rig:getUnit():getSounds().move_loop then
			MOAIFmodDesigner.stopSound( "move_loop")
		end	
		if self._rig:getUnit():getTraits().movingBody then
			MOAIFmodDesigner.stopSound( "drag_loop")
		end	
		if self._rig:getUnit():getSounds().move_loop_param then
			MOAIFmodDesigner.setSoundProperty(self._rig._spotSound, self._rig:getUnit():getSounds().move_loop_param,0 )
		end		

		if self._wasSeen then
			
			self._rig:refreshLocation()

			local unit = self._rig:getUnit()
			if unit:getTraits().movingBody then
				self:waitForAnim("body_drag_pst")
			elseif unit:getTraits().walk then
				if unit:getUnitData().sounds.walk_pst then
					self._rig:playSound( unit:getUnitData().sounds.walk_pst )
				end	
				self:waitForAnim( "walk_pst" )
			elseif not simquery.checkIfNextToCover( unit:getSim(), unit ) or unit:getTraits().isDrone then
				if unit:getTraits().sneaking or unit:getTraits().isGuard then
					if unit:getUnitData().sounds.snk_pst then
						self._rig:playSound( unit:getUnitData().sounds.snk_pst )
					end						
					self:waitForAnim( "snk_pst" )
				else 
					if unit:getUnitData().sounds.run_pst then
						self._rig:playSound( unit:getUnitData().sounds.run_pst )
					end						
					self:waitForAnim("run_pst")
				end
			elseif not unit:isKO() and not unit:isDead() then
				waitForIdlePre(self, unit)
			end
			if simquery.isUnitPinning( self._rig._boardRig:getSim(), unit ) then
				self:waitForAnim( "pin_pre" )
			end
		end

		self._rig:transitionUnitState( self._rig._idleState )
		return true

	elseif eventType == simdefs.EV_UNIT_REFRESH or eventType == simdefs.EV_UNIT_SEEN or eventType == simdefs.EV_UNIT_UNSEEN then
		-- Don't do a full refresh, we're in the middle of walking.
		self._rig:refreshHUD( self._rig:getUnit() )

		if not self._wasSeen then
			self._rig:refreshLocation()
        end
        self._rig:refreshProp( false )

		return true
        
	elseif eventType == simdefs.EV_UNIT_WARPED then
		self._rig:refreshLocation()	
		-- Don't just warp, continue ambulating!
		if ev.eventData.from_cell ~= ev.eventData.to_cell then
			self:performStep( ev )
		end
		return true

	elseif eventType == simdefs.EV_UNIT_DEATH then
		self._rig:eraseInterest()
		self._rig:transitionUnitState( self._rig._idleState )
		return true

	elseif eventType == simdefs.EV_UNIT_HIT then
		self._rig:transitionUnitState( self._rig._hitState, ev, self._rig._walkState )
		return true
	end
end

function walking_state:refreshLOSCaster( seerID )
	if self._losProp then
		local seer = self._rig:getUnit()
		local bAgentLOS = (seer:getPlayerOwner() == self._rig._boardRig:getLocalPlayer())

        if not self._rig._boardRig:canSeeLOS( seer ) then
            return false
        end

		local type = bAgentLOS and KLEIShadowMap.ALOS_DIRECT or KLEIShadowMap.ELOS_DIRECT
		local arcStart = seer:getFacingRad() - simquery.getLOSArc( seer )/2
		local arcEnd = seer:getFacingRad() + simquery.getLOSArc( seer )/2
		local range = seer:getTraits().LOSrange and self._rig._boardRig:cellToWorldDistance( seer:getTraits().LOSrange )

		self._rig._boardRig._game.shadow_map:insertLOS( type, seerID, arcStart, arcEnd, range, self._losProp )

		if seer:getTraits().LOSperipheralArc then
			local range = seer:getTraits().LOSperipheralRange and self._rig._boardRig:cellToWorldDistance( seer:getTraits().LOSperipheralRange )
			local losArc = seer:getTraits().LOSperipheralArc
			local arcStart = seer:getFacingRad() - losArc/2
			local arcEnd = seer:getFacingRad() + losArc/2

			self._rig._boardRig._game.shadow_map:insertLOS( KLEIShadowMap.ELOS_PERIPHERY, seerID + simdefs.SEERID_PERIPHERAL, arcStart, arcEnd, range, self._losProp )
		end
		return true
	end
end

function walking_state:destroyGhostFade()
	if self._fadeTimer then
		self._rig._prop:clearAttrLink( KLEIAnim.ATTR_A_FILTER_COL )
		self._fadeTimer:stop()
		self._fadeTimer = nil
		self._rig._renderFilterOverride = nil
		self._rig:refreshRenderFilter()
	end
end

function walking_state:createGhostFade( walkTime, a, b )
	local curve = MOAIAnimCurve.new()
	curve:reserveKeys ( 2 )
	curve:setKey ( 1, 0, a )
	curve:setKey ( 2, walkTime, b )

	local timer = MOAITimer.new()
	timer:setSpan ( 0, curve:getLength() )
	timer:setMode( MOAITimer.NORMAL )

	curve:setAttrLink ( MOAIAnimCurve.ATTR_TIME, timer, MOAITimer.ATTR_TIME )

	timer:start()

	self._rig._prop:setAttrLink(KLEIAnim.ATTR_A_FILTER_COL, curve, MOAIAnimCurve.ATTR_VALUE )

	if self._fadeTimer ~= nil then
		self._fadeTimer:stop()
	end

	self._fadeTimer = timer

	self._rig._renderFilterOverride = cdefs.RENDER_FILTERS["ghost"]
end

function walking_state:performStep( ev )
	local from_cell = ev.eventData.from_cell
	local to_cell = ev.eventData.to_cell
	local isStealth = ev.eventData.unit:getTraits().sneaking

	local soundRange = simdefs.SOUND_RANGE_1
	if ev.eventData.unit:getPlayerOwner():isNPC() then
		soundRange = simdefs.SOUND_RANGE_2		
	elseif isStealth then
		soundRange = simdefs.SOUND_RANGE_0
	end

	local isSeen = self._rig._boardRig:canPlayerSeeUnit( ev.eventData.unit )
	local WALKSPEED = 0.13 -- In cells/second
	if ev.eventData.unit:getTraits().movingBody then
		WALKSPEED = 0.36
	elseif ev.eventData.unit:getTraits().walk then
		WALKSPEED = 0.32
	elseif ev.eventData.unit:getTraits().sneaking then
		WALKSPEED = 0.16
	end
	local settingsFile = savefiles.getSettings( "settings" )
	if settingsFile.data.fastMode then
		WALKSPEED = WALKSPEED * 0.5
	end

	local walkTime = mathutil.dist2d( from_cell.x, from_cell.y, to_cell.x, to_cell.y ) * config.WARPSPEED * WALKSPEED

	-- Need to make flag frontmost, in case we're walking past some dead dudes.
	if self._rig._flagUI then
		self._rig._flagUI:moveToFront()
	end

	local foot_frames = simdefs.FOOTSTEP_FRAMES_RUN
	if isSeen then
		self._rig:setPlayMode( KLEIAnim.LOOP )

		if self._rig:getUnit():getTraits().movingBody then
			self._rig:setCurrentAnim("body_drag", simquery.getReverseDirection(self._rig:getUnit():getFacing() ) )
		elseif self._rig:getUnit():getTraits().walk then
			if not ev.eventData.reverse then
				if self._rig._prop:getCurrentAnim() == "walk180" and self._rig._prop:getFrame() < self._rig._prop:getFrameCount()-1 then
					self._rig._prop:setListener( KLEIAnim.EVENT_ANIM_END,
						function( anim, animname )
							self._rig._prop:setListener( KLEIAnim.EVENT_ANIM_END, nil )
							self._rig:setCurrentAnim( "walk" )
						end )
				else
					self._rig:setCurrentAnim( "walk" )
				end
				foot_frames = simdefs.FOOTSTEP_FRAMES_WALK
			end
		elseif self._rig:getUnit():getTraits().sneaking then
			self._rig:setCurrentAnim( "snk" )
			foot_frames = simdefs.FOOTSTEP_FRAMES_SNK
		else
			self._rig:setCurrentAnim( "run" )
			foot_frames = simdefs.FOOTSTEP_FRAMES_RUN
		end
	end
		
	if isSeen and not self._wasSeen then
		self:createGhostFade( walkTime * 0.7, 0.8, 1 ) -- Fade in from FOW
	elseif not isSeen and self._wasSeen then
		self:createGhostFade( walkTime * 0.7, 1, 0.8 ) -- Fade out into FOW
	end

	-- Update correct anim facing and render filter according to rig location (if visibility changes, we may become ghosted)
	if self._wasSeen or isSeen then
		self._rig:setLocation( to_cell.x, to_cell.y )
		self._rig._facing = simquery.getDirectionFromDelta( to_cell.x - from_cell.x, to_cell.y - from_cell.y )

		self._rig:refreshProp( true )
	end

	if self._wasSeen or isSeen or self._rig._boardRig:canPlayerHear( to_cell.x, to_cell.y, soundRange ) or self._rig:getUnit():getTraits().tagged then

		if self._wasSeen or isSeen then
			-- Perform the actual movement interpolation if we are or were visible.
			local x0, y0 = self._rig._boardRig:cellToWorld( from_cell.x, from_cell.y )
			local x1, y1 = self._rig._boardRig:cellToWorld( to_cell.x, to_cell.y )
			self._rig._prop:setLoc( x0, y0 )

			local ease = MOAIEaseType.LINEAR
			if ev.eventData.reverse then
				ease = MOAIEaseType.LINEAR
			end

			self._easeDriver = self._rig._prop:seekLoc( x1, y1, 0, walkTime, ease )

			if self._losProp == nil then
				self._losProp = MOAITransform.new()
				self:refreshLOSCaster( self._rig._unitID )
			end
			self._losProp:setLoc( x0, y0 )
			self._losDriver = self._losProp:seekLoc( x1, y1, 0, walkTime, ease )

		else
			-- Otherwise, just fake the timing; we need to play sounds.
			local timer = MOAITimer.new ()
			timer:setSpan( 0, walkTime )
			timer:start()
			self._easeDriver = timer
		end

		if ev.eventData.unit:getSounds().move_loop then
			local x1, y1 = self._rig._boardRig:cellToWorld( to_cell.x, to_cell.y )
			MOAIFmodDesigner.setSoundProperties( "move_loop", nil, {x1,y1,0}, nil )
		end	
		if ev.eventData.unit:getTraits().movingBody then
			local x1, y1 = self._rig._boardRig:cellToWorld( to_cell.x, to_cell.y )
			MOAIFmodDesigner.setSoundProperties( "drag_loop", nil, {x1,y1,0}, nil )
		end	

		local stepSound
		if isStealth then
			stepSound = ev.eventData.unit:getSounds().stealthStep			
		else
			stepSound = ev.eventData.unit:getSounds().step
		end

		local frames = foot_frames
		local sounds =  { stepSound	}

		if self._rig:getUnit():getSounds().move then
			table.insert(frames,2)
			table.insert(sounds,self._rig:getUnit():getSounds().move)
		end

		self:wait(self._easeDriver,{ 
									{
										frames = frames,
										sounds = sounds,
										x = to_cell.x,
										y = to_cell.y,
									},
									} )

		self._easeDriver = nil

	elseif self._beenSeen then
		self:waitDuration( walkTime )
	end

	self._rig:refreshHUD( self._rig:getUnit() )
	self:destroyGhostFade()

	self._wasSeen = isSeen
	self._beenSeen = self._beenSeen or isSeen
end

-------------------------------------------------------------

local shoot_state = class( unitrig.base_state )

function shoot_state:init( rig )
	unitrig.base_state.init( self, rig, "shoot")	
	--save cam location
end

function shoot_state:onSimEvent( ev, eventType, eventData )

	if eventType == simdefs.EV_UNIT_STOP_SHOOTING then
		local unit = self._rig:getUnit()

		if eventData.pinning then
			self:waitForAnim("pinshoot_pst", eventData.facing)
		else
			self:waitForAnim("shoot_pst", eventData.facing)
		end

		self._rig:refreshLocation()	
		self._rig:refreshProp( false)
		
		waitForIdlePre(self, unit)
		self._rig:transitionUnitState( self._rig._idleState )

	elseif eventType == simdefs.EV_UNIT_SHOT then

		ev.thread:unblock()

		local branch = nil
		if eventData.dmgt.shots > 1 then
			branch = 2
		end
		local shotAnim = 1
		local x0,y0 = self._rig._boardRig:cellToWorld(ev.eventData.x0, ev.eventData.y0)
		local x1, y1 = self._rig._boardRig:cellToWorld(ev.eventData.x1, ev.eventData.y1)
		local facing = simquery.getDirectionFromDelta(x1-x0, y1-y0)
		local unit = self._rig:getUnit()
		for shotNum = 1, eventData.dmgt.shots do
			
			local sounds = unit:getSounds().burst
			if not sounds then				
				self._rig:playSound( eventData.dmgt.sound )
			end

			if shotNum == eventData.dmgt.shots and not unit:isPC() then
				self._rig:playSound( "SpySociety/Weapons/Shells/shoot_death" )
			end

			local targetRig = self._rig._boardRig:getUnitRig(self._targetUnitID)
 			if targetRig then
 				targetRig:playSound( "SpySociety/Weapons/Shells/shoot_whiz" )
 			end

			if shotNum > 1 then
				shotAnim = math.random(1,3)
			end

			local animName = "shoot" .. shotAnim

			if x0 == x1 and y0 == y1 then
				animName = "pinshoot"
				facing = eventData.facing
			end
			self._rig:setCurrentAnim( animName, facing )
			self._rig._prop:setFrame( 0 )
			self:waitForAnim(animName, facing, branch, sounds)
		end

		local weapon = simquery.getEquippedGun(unit)
		local sound = weapon:getSounds().shell
		if sound then
			self._rig:playSound( sound )
		end
		-- used to be a pan here.. do we need this wait now? 
		self._rig._boardRig:wait( 30 )
	end
end

function shoot_state:onEnter( ev )
	local unit = self._rig:getUnit()
	local facing = ev.eventData.newFacing
	local oldFacing = ev.eventData.oldFacing
	local pinning = ev.eventData.pinning

	self._targetUnitID = ev.eventData.targetUnitID

	if getCoverDir(unit) and not pinning then
		self:waitForAnim("hide_pst", getIdleFacing(unit:getSim(), unit) )
	elseif getLeanDir(unit) and not pinning then
		self:waitForAnim("lean_pst", getIdleFacing(unit:getSim(), unit) )
	end

	if not ev.eventData.overwatch then
		if pinning then
			self:waitForAnim("pinshoot_pre", facing)
		else
			self:waitForAnim( "shoot_pre" , facing )
		end
	elseif not unit:getPlayerOwner():isNPC() and not unit:getTraits().isDrone then

		local orientation = self._rig._boardRig._game:getCamera():getOrientation()*2
		facing = facing - orientation
		if facing < 0 then
			facing = facing + simdefs.DIR_MAX
		end
		oldFacing = oldFacing - orientation
		if oldFacing < 0 then
			oldFacing = oldFacing + simdefs.DIR_MAX
		end
		
		if oldFacing == 2 or oldFacing == 3 or oldFacing == 4 then
			if facing == 6 then
				facing = 4 
			elseif facing == 4 then
				facing = 6
			elseif facing == 7 then
				facing= 3 
			elseif facing == 3 then
				facing = 7
			elseif facing == 0 then
				facing = 2
			elseif facing == 2 then
				facing = 0
			end
		end

	 	self:waitForAnim( "overwatch_switch_"..facing, oldFacing)
	end
end

function shoot_state:onExit()
	unitrig.base_state.onExit( self )
end

-------------------------------------------------------------

local throw_state = class( unitrig.base_state )

function throw_state:init( rig )
	unitrig.base_state.init( self, rig, "throw")
end

function throw_state:onEnter( ev )
	local unit = self._rig:getUnit()

	local x0,y0 = self._rig._boardRig:cellToWorld(unit:getLocation() )
	local x1, y1 = self._rig._boardRig:cellToWorld(ev.eventData.x1, ev.eventData.y1)
	local dir = getShoulderDir(unit, ev.eventData.x1, ev.eventData.y1)
	if dir and getCoverDir(unit) then
		if dir then 
			self._rig:playSound( "SpySociety/Grenades/throw")
			self:waitForAnim( "hide_throw_"..dir, getIdleFacing(unit:getSim(), unit) )
			ev.thread:unblock()
			self:waitForAnim("hide_throw_pst_"..dir, getIdleFacing(unit:getSim(), unit) )
		end
	elseif dir and getLeanDir(unit) then
		if dir then
			self._rig:playSound( "SpySociety/Grenades/throw")
			self:waitForAnim( "lean_throw_"..dir, getIdleFacing(unit:getSim(), unit) )
			ev.thread:unblock()
			self:waitForAnim("lean_throw_pst_"..dir, getIdleFacing(unit:getSim(), unit) )
		end
	else
		if simquery.isUnitPinning(unit:getSim(), unit ) then
			self:waitForAnim("pin_stand")
		elseif getCoverDir(unit) then
			self:waitForAnim("hide_pst", getIdleFacing(unit:getSim(), unit) )
		elseif getLeanDir(unit) then
			self:waitForAnim("lean_pst", getIdleFacing(unit:getSim(), unit) )
		end

		self._rig:playSound( "SpySociety/Grenades/throw")
		self:waitForAnim("throw", ev.eventData.facing)
		ev.thread:unblock()
		self:waitForAnim("throw_pst", ev.eventData.facing)
		waitForIdlePre(self, unit )
	end
	self._rig:transitionUnitState(self._rig._idleState)

end

function throw_state:onSimEvent( ev, eventType, eventData )
	local unit = self._rig:getUnit()
	unitrig.base_state.onSimEvent( self, ev, eventType, eventData )

	if eventType == simdefs.EV_UNIT_START_WALKING then
		self._rig:transitionUnitState( self._rig._walkState, ev )
	end
end


-------------------------------------------------------------

local hit_state = class( unitrig.base_state )

function hit_state:init( rig )
	unitrig.base_state.init( self, rig, "hit" )
end


function hit_state:onEnter( ev, previousState, ... )
	unitrig.base_state.onEnter( self )

	if previousState then
		self._previousState = previousState
		self._previousStateArgs = { ... }
	else
		self._previousState, self._previousStateArgs = nil, nil
	end
	
	self:doHit(ev)
end

function hit_state:doHit(ev)
	local unit = self._rig:getUnit()
	local sourceUnit = ev.eventData.sourceUnit
	local x1, y1 = unit:getLocation()
	local prop  = self._rig._prop

	if (ev.eventData.kodamage or 0) > 0 then
		if self._rig._boardRig._shouldUnblockKO then
			self._rig._boardRig:showFloatText( x1, y1, util.sformat( STRINGS.FORMATS.KO_AMT, ev.eventData.kodamage) )
		else
			self._rig._boardRig:queFloatText( x1, y1, util.sformat( STRINGS.FORMATS.KO_AMT, ev.eventData.kodamage) )
		end
	end

	self._rig:refreshHUD( unit )

	if ev.eventData.fx == "emp" then
		self._rig:addAnimFx( "fx/emp_effect", "character", "idle", true )
	end

	if unit:getSounds().hit and not unit:isKO() then
		self._rig:playSound( unit:getSounds().hit)		
	end

	if sourceUnit and sourceUnit:getTraits().stun then
		if unit:getSounds().hurt_large and not unit:isKO() then
			self._rig:playSound(unit:getSounds().hurt_large)
		end
	else
		if unit:getSounds().hurt_small and not unit:isKO() then
			self._rig:playSound(unit:getSounds().hurt_small)
		end
	end

	if ev.eventData.crit == true then
		if unit:getTraits().hits == "blood" then
			prop:setSymbolVisibility( "blood_crit", true)	
		elseif unit:getTraits().hits == "spark" then
			prop:setSymbolVisibility( "sparks2", true )	
		end
	else
		prop:setSymbolVisibility( "sparks2", "blood_crit", false )	
	end

	if ev.eventData.pinned and not unit:getTraits().isDrone then
		self:waitForAnim( "downed_hit" )
		self._rig:transitionUnitState( self._rig._idleState )
	elseif (ev.eventData.kodamage or 0) > 0 or (ev.eventData.result or 0) > 0 then
		self._rig:transitionUnitState( self._rig._idleState )
	elseif ev.eventData.taze then
		self:waitForAnim( "downed_taze" )
		self._rig:transitionUnitState( self._rig._idleState )
	else
		if ev.eventData.dir == "frt" then 
			self:waitForAnim( "hitfrt" )
			self:waitForAnim( "hitfrt_pst" )
		else
			self:waitForAnim( "hitbck" )
			self:waitForAnim( "hitbck_pst" )
		end

		waitForIdlePre(self, unit)

		self._rig:transitionUnitState( self._previousState, unpack( self._previousStateArgs ) )			
	end

end

-------------------------------------------------------------

local reload_state = class( unitrig.base_state )

function reload_state:init( rig )
	unitrig.base_state.init( self, rig, "reload" )
end

function reload_state:onEnter( ev )
	unitrig.base_state.onEnter( self )

	
	local unit = self._rig:getUnit()
	if getCoverDir(unit) then
		self:waitForAnim( "hide_reload", getCoverDir(unit) )
	elseif getLeanDir(unit) then
		self:waitForAnim( "lean_reload", getLeanDir(unit) )
	else
		self:waitForAnim( "shoot_pre" )
		self:waitForAnim( "reload")
		self:waitForAnim( "shoot_pst" )
	end

	self._rig:transitionUnitState( self._rig._idleState )
end

--------------------------------------------------------------------

local usedoor_state = class( unitrig.base_state )

function usedoor_state:init( rig )	
	unitrig.base_state.init( self, rig, "usedoor" )		
end

function usedoor_state:onSimEvent( ev, eventType, eventData )
	local unit = self._rig:getUnit()
	if eventType == simdefs.EV_UNIT_USEDOOR_PST then
		if eventData.exitOp == simdefs.EXITOP_BREAK_DOOR then
			self:waitForAnim("door_kick_pst", eventData.facing)
		else
			self:waitForAnim( "use_door_pst", eventData.facing )
			waitForIdlePre(self, unit, true)
		end

		self._rig:transitionUnitState( self._rig._idleState )

	elseif eventType == simdefs.EV_UNIT_REFRESH then
		--this usually happens when we open a door to a room with a camera/other agent in it, and they call refresh on us because we became seen
		--do nothing with it for now, and hope that doesn't lead to werid behaviour later if we actually need to refresh
		return true
	elseif eventType == simdefs.EV_UNIT_HIT then
		self._rig:transitionUnitState( self._rig._hitState, ev, self._rig._idleState )
		return true		
	elseif eventType == simdefs.EV_UNIT_KO then
		doKOanim(self, ev.thread)

        self._rig:refresh( ev )
		self._rig:eraseInterest()
		self._rig:transitionUnitState( self._rig._idleState )
	end
end

function usedoor_state:onEnter( ev )
	unitrig.base_state.onEnter( self )


	local unit = self._rig:getUnit()
	if simquery.isUnitPinning(unit:getSim(), unit ) then
		self:waitForAnim("pin_stand")
	elseif getCoverDir(unit) then
		self:waitForAnim( "hide_pst", getIdleFacing(unit:getSim(), unit) )
	elseif getLeanDir(unit) then
		self:waitForAnim( "lean_pst", getIdleFacing(unit:getSim(), unit) )
	end

	local sounds = {{sound=ev.eventData.sound ,soundFrames=ev.eventData.soundFrame}}
	if ev.eventData.exitOp == simdefs.EXITOP_BREAK_DOOR then
		self:waitForAnim( "door_kick_pre", ev.eventData.facing, nil, sounds )
	else
		self:waitForAnim( "use_door", ev.eventData.facing, nil, sounds )
	end
end


--------------------------------------------------------------------

local heal_state = class( unitrig.base_state )

function heal_state:init( rig )	
	unitrig.base_state.init( self, rig, "heal" )		
end

function heal_state:onEnter( ev )
	unitrig.base_state.onEnter( self )

	local sound = "SpySociety/Actions/heal"

	if ev.eventData.revive then
		self:waitForAnim( "revive", ev.eventData.facing,nil,{{sound=sound,soundFrames=13}}  ) --13
		waitForIdlePre(self, self._rig:getUnit())
	elseif ev.eventData.unit ==  ev.eventData.target then
		self:waitForAnim( "heal", ev.eventData.facing,nil,{{sound=sound,soundFrames=14}}  )
		waitForIdlePre(self, self._rig:getUnit())
	else
		local x0, y0 = ev.eventData.unit:getLocation()
		local x1, y1 = ev.eventData.target:getLocation()
		if x0 == x1 and y0 == y1 then
			self:waitForAnim( "pin_stab", ev.eventData.facing,nil,{{sound=sound,soundFrames=13}} )
		else
			self:waitForAnim( "heal_team", ev.eventData.facing,nil,{{sound=sound,soundFrames=12}} )
			waitForIdlePre(self, self._rig:getUnit())
		end
	end
	

	self._rig:transitionUnitState( self._rig._idleState )
end
--------------------------------------------------------------------

local pickup_state = class( unitrig.base_state )

function pickup_state:init( rig )	
	unitrig.base_state.init( self, rig, "pickup" )		
end

function pickup_state:onEnter( ev )
	unitrig.base_state.onEnter( self )

	self._rig:refreshProp()
	self:waitForAnim( "pick_up" )


	self._rig:transitionUnitState( self._rig._idleState )
end

--------------------------------------------------------------------

local grappled_state = class( unitrig.base_state )

function grappled_state:init( rig )	
	unitrig.base_state.init( self, rig, "grappled" )		
end

function grappled_state:onSimEvent( ev, eventType, eventData )
	if eventType == simdefs.EV_UNIT_DEATH then
		self._rig:transitionUnitState( self._rig._idleState )
	else
		unitrig.base_state.onSimEvent( ev, eventType, eventData )
		if eventType == simdefs.EV_UNIT_KO then
            if not eventData.stand then
    			self._rig:eraseInterest()
				self._rig:transitionUnitState( self._rig._idleState )
            end
        end
	end
end
--------------------------------------------------------------------

local melee_state = class( unitrig.base_state )

function melee_state:init( rig )	
	unitrig.base_state.init( self, rig, "melee" )		
end

function melee_state:onEnter( ev )
	unitrig.base_state.onEnter( self )

	local unit = self._rig:getUnit()
	local targetUnitID = ev.eventData.targetUnit:getID()
	local targetRig = self._rig._boardRig:getUnitRig(targetUnitID)

	if ev.eventData.grapple == true then 
		targetRig:transitionUnitState( grappled_state( targetRig ))

		local presounds = {}
		if self._rig:getUnit():getUnitData().gender == "male" then
			presounds = {
				{sound="SpySociety/HitResponse/hitby_grab_flesh",soundFrames=4},
				{sound="SpySociety/Agents/<voice>/grabbed_vocals",soundFrames=5, source=targetRig}
			}
		end

		self:waitForAnim( "melee_grp_pre",nil,nil,presounds )

		local grp_build = targetRig._kanim[ "grp_build" ][1]
		self._rig._prop:bindBuild(GetAnimResource(grp_build))

        local enemyWpn = simquery.getEquippedGun(targetRig:getUnit())
        if enemyWpn then
            local weaponAnim = animmgr.lookupAnimDef( enemyWpn:getUnitData().weapon_anim )
            if weaponAnim and weaponAnim.grp_build then
        		self._rig._prop:bindBuild(KLEIResourceMgr.GetResource(weaponAnim.grp_build))
            end
        end

		self._rig._boardRig:refreshLOSCaster(targetUnitID)
		targetRig._prop:setVisible(false)


		if unit:getSounds().grab then
			self._rig:playSound( unit:getSounds().grab)
		end

		local targetUnit = targetRig:getUnit()
		if targetUnit:getSounds().grabbed then
			self._rig:playSound( targetUnit:getSounds().grabbed)
		end		



		local sounds = {}
		if self._rig:getUnit():getUnitData().gender == "male" then
			sounds = {
				{sound="SpySociety/HitResponse/hitby_energy_flesh",soundFrames=5},
				{sound="SpySociety/Agents/<voice>/hurt_small",soundFrames=6, source=targetRig},
				{sound="SpySociety/Movement/bodyfall_agent_hardwood",soundFrames=47},
                {sound="SpySociety/HitResponse/hitby_floor_flesh",soundFrames=48}
            }
		else
			sounds = {
				{sound="SpySociety/HitResponse/hitby_grab_flesh",soundFrames=1},
				{sound="SpySociety/Agents/<voice>/grabbed_vocals",soundFrames=2, source=targetRig},
		        {sound="SpySociety/HitResponse/hitby_floor_flesh",soundFrames=17},
				{sound="SpySociety/Movement/bodyfall_agent_hardwood",soundFrames=18},
				{sound="SpySociety/HitResponse/hitby_energy_flesh",soundFrames=27},
				{sound="SpySociety/Agents/<voice>/hurt_small",soundFrames=36, source=targetRig},
			}
		end			
	
		if unit:getSounds().fall then
			table.insert(sounds,{sound=unit:getSounds().fall,soundFrames=12})
		end

		self:waitForAnim( "melee_grp",nil, nil, sounds )

		self._rig._prop:unbindBuild(GetAnimResource(grp_build))
		targetRig:setCurrentAnim( "idle_ko" )

		targetRig._prop:setVisible(true)

		self._rig:transitionUnitState( self._rig._idleState )
	elseif ev.eventData.pinning then
		local thread = ev.viz:spawnViz(
			function()
				local sounds = {
					{sound="SpySociety/HitResponse/hitby_energy_flesh",soundFrames=20},
					{sound="SpySociety/Agents/<voice>/hurt_small",soundFrames=21, source=targetRig},
				}
				self:waitForAnim( "ground_taze",nil, nil, sounds )
				self._rig:transitionUnitState( self._rig._idleState )
			end )
		thread:unblock()
	else
		self._rig:playSound("SpySociety/HitResponse/hitby_punch_flesh")
		self:waitForAnim( "melee" )

		if not ev.eventData.meleeSuccess then 
			local x1, y1 = ev.eventData.targetUnit:getLocation()		
			self._rig._boardRig:queFloatText( x1, y1, STRINGS.UI.FLY_TXT.ARMORED )
		end

		local thread = ev.viz:spawnViz(
			function()
				self:waitForAnim( "melee_pst" )
				self:waitForAnim( "idle_pre" )
				self._rig:transitionUnitState( self._rig._idleState )
			end )
		thread:unblock()
	end
end

--------------------------------------------------------------------
local dragbody_state = class( unitrig.base_state )

function dragbody_state:init( rig )	
	unitrig.base_state.init( self, rig, "dragbody" )		
end

function dragbody_state:onEnter( ev )
	unitrig.base_state.onEnter( self )

	local targetUnitID = ev.eventData.targetUnit:getID()
	local targetRig = self._rig._boardRig:getUnitRig(targetUnitID)
	local targetUnit = targetRig:getUnit()
	local unit = self._rig:getUnit()



	local grp_build = targetRig._kanim[ "grp_build" ][1]
	self._rig._prop:bindBuild(GetAnimResource(grp_build))
	targetRig._prop:setVisible(false)

	local gender = targetUnit:getUnitData().gender or "male"
	self._rig._prop:bindAnim(GetAnimResource(self._rig._kanim.grp_anims["anims"][gender]) )
	if self._rig._weaponUnitData then
		self._rig._prop:bindAnim(GetAnimResource(self._rig._kanim.grp_anims[self._rig._weaponUnitData.agent_anim][gender]) )
	else
		self._rig._prop:bindAnim(GetAnimResource(self._rig._kanim.grp_anims["anims_unarmed"][gender]) )
	end


	local sounds = {}
		sounds = {
			{sound=unit:getSounds().getup,soundFrames=1},
			{sound=targetUnit:getSounds().getup,soundFrames=1}
        }

	self._rig:setPlayMode( KLEIAnim.ONCE )	
	self:waitForAnim("body_pick_up", targetUnit:getFacing(), nil, sounds)

	-- self._rig:transitionUnitState(self._rig._idleState)
end

function dragbody_state:onExit()
end

function dragbody_state:onSimEvent( ev, eventType, eventData )
	local unit = self._rig:getUnit()
	if unit:isGhost() then
		if eventType == simdefs.EV_UNIT_START_WALKING then
			self._rig:transitionUnitState( self._rig._walkState, ev )
		end

	else
		unitrig.base_state.onSimEvent( self, ev, eventType, eventData )
	
		if eventType == simdefs.EV_UNIT_START_WALKING then
			self._rig:transitionUnitState( self._rig._walkState, ev )
		elseif eventType == simdefs.EV_UNIT_DROP_BODY then
			self._rig:refreshLocation()
			self._rig:refreshHUD( unit )
			self._rig:transitionUnitState( self._rig._dropBodyState, ev )	
		end
	end
end


--------------------------------------------------------------------
local dropbody_state = class( unitrig.base_state )

function dropbody_state:init( rig )	
	unitrig.base_state.init( self, rig, "dropbody" )		
end

function dropbody_state:onEnter( ev )
	unitrig.base_state.onEnter( self )

	local unit = self._rig:getUnit()
	local targetUnitID = ev.eventData.targetUnit and ev.eventData.targetUnit:getID()
	local targetRig = self._rig._boardRig:getUnitRig(targetUnitID)
	local targetUnit = targetRig:getUnit()

	local targetGender = targetUnit:getUnitData().gender or "male"
	local sound = {sound="SpySociety/Movement/bodyfall_agent_hardwood",soundFrames=7}
	if self._rig:getUnit():getUnitData().gender == "female" then
		if targetGender ~= "female" and not (self._rig._weaponUnitData and self._rig._weaponUnitData.agent_anim == "anims_2h") then
			sound.soundFrames = 9
		end
	else
		sound.soundFrames = 7
		if targetGender == "female" and not (self._rig._weaponUnitData and self._rig._weaponUnitData.agent_anim == "anims_2h") then
			sound.soundFrames = 5
		end
	end			
	self:waitForAnim("body_drop", simquery.getReverseDirection(unit:getFacing() ), nil, {sound})
	local grp_build = targetRig._kanim.grp_build[1]
	self._rig._prop:unbindBuild(GetAnimResource(grp_build))
	local targetAnim = getIdleAnim(targetUnit:getSim(), targetUnit)
	targetRig._prop:setVisible(true)
	targetRig:setCurrentAnim(targetAnim)

	if not simquery.isUnitPinning(unit:getSim(), unit) then
		self:waitForAnim("pin_stand", unit:getFacing() )
		waitForIdlePre(self, unit, true)		
	end

	self._rig:transitionUnitState(self._rig._idleState)
end
--------------------------------------------------------------------

local bodydrop_state = class( unitrig.base_state )

function bodydrop_state:init( rig )	
	unitrig.base_state.init( self, rig, "bodydrop" )		
end

function bodydrop_state:onEnter( ev )
	unitrig.base_state.onEnter( self )

	local sounds = {}
	self._rig:setCurrentAnim("body_fall", nil, nil, sounds)
	self._rig._prop:setListener( KLEIAnim.EVENT_ANIM_END,
		function( anim, animname )
			self._rig._prop:setListener( KLEIAnim.EVENT_ANIM_END, nil )
			self._rig:transitionUnitState(self._rig._idleState)
		end )

end

--------------------------------------------------------------------

local lookaround_state = class( unitrig.base_state )

function lookaround_state:init( rig )	
	unitrig.base_state.init( self, rig, "lookaround" )
end

function lookaround_state:onSimEvent( ev, eventType, eventData )
	if eventType == simdefs.EV_UNIT_LOOKAROUND then
		if eventData.part == "left" then
			self:performLeft(ev)
		elseif eventData.part == "left_post" then
			self:performLeftPost(ev)
		elseif eventData.part == "right_post" then
			self:performRightPost(ev)
		elseif eventData.part == "post" then
			self:performPost(ev)
		end
		return true
	elseif eventType == simdefs.EV_UNIT_INTERRUPTED then
		self._rig:transitionUnitState( self._rig._idleState )
	end
end

function lookaround_state:refreshLOSCaster(seerID)
	if not self.status then
		return false
	end

	local seer = self._rig:getUnit()
    if not self._rig._boardRig:canSeeLOS( seer ) then
        return false
    end

	local losArc = seer:getTraits().lookaroundArc or (math.pi/2 + math.pi/8)
	local range = seer:getTraits().LOSrange and self._rig._boardRig:cellToWorldDistance( seer:getTraits().LOSrange )
	local facingRad = seer:getFacingRad()
    local facingOffset = seer:getTraits().lookaroundOffset or (math.pi/4 - math.pi/16)

	local arcLeftStart = facingRad - facingOffset + losArc/2
	local arcLeftEnd = facingRad + facingOffset + losArc/2
	local arcRightStart = facingRad + facingOffset - losArc/2
	local arcRightEnd = facingRad - facingOffset - losArc/2

	if string.find(self.status, "right") then
		if string.find(self.status, "pre") then
			self._rig:animateLOS{left=arcLeftStart, right={start=arcRightStart, finish=arcRightEnd, time=0.3} }
		elseif string.find(self.status, "post") then
			self._rig:animateLOS{left=arcLeftStart, right={start=arcRightEnd, finish=arcRightStart, time=0.3} }
		else
			self._rig:animateLOS{left=arcLeftStart + facingOffset, right=arcRightEnd + facingOffset }
		end	
		return true
	elseif string.find(self.status, "left") then
		if string.find(self.status, "pre") then
			self._rig:animateLOS{left={start=arcLeftStart, finish=arcLeftEnd, time=0.3}, right=arcRightStart }
		elseif string.find(self.status, "post") then
			self._rig:animateLOS{left={start=arcLeftEnd, finish=arcLeftStart, time=0.3}, right=arcRightStart }
		else
			self._rig:animateLOS{left=arcLeftEnd - facingOffset, right=arcRightStart - facingOffset }
		end
		return true
	end
end

function lookaround_state:onEnter( ev )
	unitrig.base_state.onEnter( self )
	local unit = ev.eventData.unit
	if simquery.isUnitPinning(unit:getSim(), unit ) then
		self:waitForAnim("pin_stand")
	end

	self:performRight(ev)	--requires anim updates
end

function lookaround_state:performLeft(ev)
	self.status = "left_pre"
	local isSeen = self._rig._boardRig:canPlayerSeeUnit( ev.eventData.unit )
	if self._wasSeen or isSeen then
		self:refreshLOSCaster( self._rig._unitID )
	end
	rig_util.wait(16)
	self.status = "left"
end

function lookaround_state:performRight(ev)
	self.status = "right_pre"
	self:waitForAnim("peek_fwrd")	--3 frames
	local isSeen = self._rig._boardRig:canPlayerSeeUnit( ev.eventData.unit )
	if self._wasSeen or isSeen then
		self:refreshLOSCaster( self._rig._unitID )
	end
	self._rig:setCurrentAnim( "peek_pst_fwrd" )
	rig_util.wait(13)
	self.status = "right"
end

function lookaround_state:performRightPost(ev)
	self.status = "right_post"
	local isSeen = self._rig._boardRig:canPlayerSeeUnit( ev.eventData.unit )
	if self._wasSeen or isSeen then
		self:refreshLOSCaster( self._rig._unitID )
	end
	rig_util.wait(16)
	self.status = nil
end

function lookaround_state:performLeftPost(ev)
	self.status = "left_post"
	local isSeen = self._rig._boardRig:canPlayerSeeUnit( ev.eventData.unit )
	if self._wasSeen or isSeen then
		self:refreshLOSCaster( self._rig._unitID )
	end
	rig_util.wait(13)
	self.status = nil
end

function lookaround_state:performPost(ev)
	local isSeen = self._rig._boardRig:canPlayerSeeUnit( ev.eventData.unit )
	if (self._wasSeen or isSeen) and self._rig._prop:getFrame() < self._rig._prop:getFrameCount()-1 then
		local animDone = false
		self._rig._prop:setListener( KLEIAnim.EVENT_ANIM_END,
			function( anim, animname )
				animDone = true
			end )
		while not animDone do
			coroutine.yield()
		end
		self._rig._prop:setListener( KLEIAnim.EVENT_ANIM_END, nil )
	end

	waitForIdlePre(self, ev.eventData.unit)	
	self._rig:transitionUnitState( self._rig._idleState )
end
--------------------------------------------------------------------

local shrug_state = class( unitrig.base_state )

function shrug_state:init( rig )	
	unitrig.base_state.init( self, rig, "shrug" )		
end

function shrug_state:onEnter( ev )
	unitrig.base_state.onEnter( self )
	self:waitForAnim( "shrug" )
	self._rig:transitionUnitState( self._rig._idleState )
end

--------------------------------------------------------------------
-- agentrig

local agentrig = class( unitrig.rig )

function agentrig:init( boardRig, unit )
	unitrig.rig.init( self, boardRig, unit )

	if unit:getPlayerOwner() and not unit:getPlayerOwner():isNPC() then
	--	self._coverRig = coverrig.rig( boardRig, self._prop )
	end

	self._HUDteamCircle = self:createHUDProp("kanim_hud_agent_hud", "CharacterRing", "0", false, self._prop )
	
	self._HUDzzz = self:createHUDProp("kanim_sleep_zees_fx", "character", "sleep", boardRig:getLayer("ceiling"), self._prop )
	self._HUDzzz:setVisible(false)

	self._HUD_shield = self:createHUDProp("kanim_shield_fx", "shield", "idle", true, self._prop )
	self._HUD_shield:setVisible(false)

	self._idleState = idle_state( self )
	self._walkState = walking_state( self )
	self._shootState = shoot_state( self )
	self._throwState = throw_state( self )
	self._reloadState = reload_state( self )
	self._hitState = hit_state( self )
	self._usedoorState = usedoor_state( self )
	self._healState = heal_state( self )
	self._pickupState = pickup_state( self )
	self._meleeState = melee_state( self )
	self._lookaroundState = lookaround_state( self )
	self._shrugState = shrug_state( self )
	self._dragBodyState = dragbody_state( self )
	self._dropBodyState = dropbody_state( self )
	self._bodyDropState = bodydrop_state( self )

	local prop = self._prop

	if self:getUnit():getTraits().hits == "blood" then
		prop:setSymbolVisibility( "blood", true )
		prop:setSymbolVisibility( "blood_crit", "sparks2", "effect", "electricity", "hit", "blood_pool", "oil_pool", false )	
	elseif self:getUnit():getTraits().hits == "spark" then
		prop:setSymbolVisibility( "blood", "blood_crit", "sparks2", "blood_pool", "oil_pool", false )
		prop:setSymbolVisibility( "electricity", "hit", true )
	end

end

function agentrig:destroy()

	if self._bWireframe then		
		self._boardRig._game:removeWireframeProp( self._prop )
	end
	
	self._boardRig:getLayer("ceiling"):removeProp( self._HUDzzz )

	self._prop:removeProp(self._HUDteamCircle )
	self._prop:removeProp( self._HUD_shield, true)	

	if self._flagUI then
		self._flagUI:destroy()
		self._flagUI = nil
	end
	if self._coverRig then
		self._coverRig:destroy()	
		self._coverRig = nil
	end

	if self.interestProp then
		self._boardRig:getLayer("ceiling"):removeProp( self.interestProp )
	end


	unitrig.rig.destroy( self )
end



function agentrig:onSimEvent( ev, eventType, eventData )
	unitrig.rig.onSimEvent( self, ev, eventType, eventData )
	
	if eventType == simdefs.EV_UNIT_INTERRUPTED then
		local fxmgr = self._boardRig._game.fxmgr
		local x0, y0 = self:getUnit():getLocation()
		if self:getUnit():getPlayerOwner() == self._boardRig:getLocalPlayer() and self._boardRig:canPlayerSee( x0, y0 ) then
			x0, y0 = self._boardRig:cellToWorld( x0, y0 )
			--jcheng: remove this ugly text altogether
			--if eventData.unitSeen and  eventData.unitSeen:isNPC() then
			--	fxmgr:addFloatLabel( x0, y0, "Enemy Sighted!", 2 )			
			--else
				--don't do this... it looks ugly and it almost never is good
				--fxmgr:addFloatLabel( x0, y0, "Interrupted!", 2 )			
			--end
		end

	elseif eventType == simdefs.EV_UNIT_ADD_INTEREST then
		if self:getRawUnit() and self:getRawUnit():getBrain() and self:shouldDrawInterest(self:getUnit(), eventData.interest) then
			self:drawInterest(eventData.interest, self:getUnit():isAlerted() )
		end

	elseif eventType == simdefs.EV_UNIT_UPDATE_INTEREST then
        self:refreshInterest()

	elseif eventType == simdefs.EV_UNIT_DEL_INTEREST then
		self:eraseInterest()
	elseif eventType == simdefs.EV_UNIT_RESET_ANIM_PLAYBACK then		
		self:setPlayMode( KLEIAnim.LOOP )
	
	elseif eventType == simdefs.EV_UNIT_WIRELESS_SCAN then
	
		self:playSound("SpySociety/Actions/Engineer/wireless_emitter")
		
		if eventData.hijack then
			self:addAnimFx( "gui/hud_fx", "wireless_console_takeover", "idle" )
			local x0, y0 = self:getUnit():getLocation()
			local color = {r=1,g=1,b=41/255,a=0.7}
			self._boardRig:queFloatText( x0, y0, STRINGS.UI.FLY_TXT.WIRELESS_HIJACK, color )
			self._boardRig:getUnitRig( eventData.targetUnitID ):addAnimFx( "gui/hud_fx", "wireless_console_takeover", "idle" )
		else	
			self:addAnimFx( "gui/hud_fx", "wireless", "idle" )
		end
	elseif eventType == simdefs.EV_UNIT_TAGGED then	

		local gfxOptions = self._boardRig._game:getGfxOptions()
		if gfxOptions.bMainframeMode then
		   	if eventData.unit:getTraits().tagged then
		   		if not self._tagged then
					MOAIFmodDesigner.playSound( "SpySociety/Actions/mainframe_wisp_reveal" )
		   			self._tagged = self:createHUDProp("kanim_hud_tag", "effect", "loop", self._boardRig:getLayer("ceiling"), self._prop )		
		   			rig_util.waitForAnim( self._tagged, "in")		   				
		   			self._tagged:setCurrentAnim("loop")	
		   		end
		   	end
		end

	elseif eventType == simdefs.EV_UNIT_HIT_SHIELD then	
		
		self:playSound( "SpySociety/HitResponse/hitby_ballistic_shield")
		self:addAnimFx( "fx/shield_fx", "shield", "break", true )

		self:refreshHUD( eventData.unit )

	elseif eventType == simdefs.EV_UNIT_APPEARED then		
		local sim =  self._boardRig:getSim()
		local unit = sim:getUnit(ev.eventData.unitID)
		local x0,y0 = unit:getLocation()
		self._boardRig:cameraFit( self._boardRig:cellToWorld( x0, y0 ) )
		
		if not ev.eventData.noSightingFx then
			local fx = self:addAnimFx( "gui/hud_agent_hud", "enemy_sighting", "front" )
			-- UGLY: just set these colours in the anim directly, so we can delete this
			fx._prop:setSymbolModulate("wall",1, 0, 0, 1 )
			fx._prop:setSymbolModulate("outline_side",1, 0, 0, 1 )
		end

	elseif eventType == simdefs.EV_UNIT_SPEAK then
		local sim =  self._boardRig:getSim()
		local x0, y0 = eventData.unit:getLocation()
		if self._boardRig:canPlayerSee( x0, y0 ) then
			handleSpeechEvent(self, eventData.unit, eventData.speech, eventData.speechData)
		else
			local closestUnit, closestRange = simquery.findClosestUnit( self._boardRig:getLocalPlayer():getUnits(), x0, y0, simquery.canHear )
			if closestUnit ~= nil and closestRange <= eventData.range then
				if sim:getCurrentPlayer() == eventData.unit:getPlayerOwner() then
					waitForSpeech(self, eventData.unit, eventData.speech, eventData.speechData)
				else
					handleSpeechEvent(self, eventData.unit, eventData.speech, eventData.speechData)
				end
			end
		end

	elseif eventType == simdefs.EV_UNIT_DISGUISE then
		local unit = ev.eventData.unit
    end
end

function agentrig:refreshLOSCaster( seerID )
	if self._state and self._state.refreshLOSCaster then
		return self._state:refreshLOSCaster( seerID )
	end
	return false
end

function agentrig:shouldDrawInterest(unit, interest)

	if not unit or not interest then
		return false
	end

	if unit:isDead() or unit:isKO() then		
		return false
	end

	if interest.investigated then
		return false
	end

	if unit:isAlerted() and unit:getTraits().vip then
		return false
	end

	return true
end

function agentrig:refreshInterest()
    local rawUnit = self._boardRig:getSim():getUnit( self._unitID )
	if rawUnit and rawUnit:getBrain() and self:shouldDrawInterest( rawUnit, rawUnit:getBrain():getInterest() ) then
		self:drawInterest(rawUnit:getBrain():getInterest(), rawUnit:isAlerted() )
	else		
		self:eraseInterest()
	end
end

function agentrig:drawInterest(interest, alerted)
	local x0,y0 =  self._boardRig:cellToWorld(interest.x, interest.y) 
	local sim = self._boardRig:getSim()

	if sim:drawInterestPoints()
	 or self:getUnit():getTraits().patrolObserved
	 or interest.alwaysDraw
	 or self._boardRig:getLocalPlayer() == nil
	 or self._boardRig:getLocalPlayer():isNPC() then 

		if not self.interestProp then
			self._boardRig._game.fxmgr:addAnimFx( { kanim="gui/guard_interest_fx", symbol="effect", anim="in", x=x0, y=y0 } )
		
			self.interestProp = self:createHUDProp("kanim_hud_interest_point_fx", "interest_point", "in", self._boardRig:getLayer("ceiling"), nil, x0, y0  )
			self.interestProp:setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim, animname )
					if animname == "in" then
						self.interestProp:setCurrentAnim("idle")	
					end
				end )

			self.interestProp:setSymbolModulate("interest_border",255/255,255/255,0/255,1 )
			self.interestProp:setSymbolModulate("down_line",255/255,255/255,0/255,1 )
			self.interestProp:setSymbolModulate("down_line_moving",255/255,255/255,0/255,1 )
			self.interestProp:setSymbolModulate("interest_line_moving",255/255,255/255,0/255,1 )
		end

		if interest.alerted or alerted then
			self.interestProp:setSymbolVisibility("thought_alert", true)
			self.interestProp:setSymbolVisibility("thought_investigate", false)
			self.interestProp:setSymbolVisibility("thought_bribe", false)
		else
			self.interestProp:setSymbolVisibility("thought_alert", false)
			self.interestProp:setSymbolVisibility("thought_investigate", true)
			self.interestProp:setSymbolVisibility("thought_bribe", false)
		end

	 	self.interestProp:setVisible( true )
		self.interestProp:setLoc( x0, y0 )	
	end 
end

function agentrig:eraseInterest()

	if self.interestProp then
		self._boardRig:getLayer("ceiling"):removeProp( self.interestProp )
		self.interestProp = nil
	end
end

function agentrig:animateLOS(params)

	local seer = self:getUnit()
	local facingRad = seer:getFacingRad()
	local losArc = simquery.getLOSArc( seer )

	--fill in any missing params
	params.range = seer:getTraits().LOSrange and self._boardRig:cellToWorldDistance( seer:getTraits().LOSrange )
	params.left = params.left or facingRad + losArc/2
	params.right = params.right or facingRad - losArc/2

	if type(params.left) == "table" then
		local arcLeftCurve = MOAIAnimCurve.new ()
		arcLeftCurve:reserveKeys ( 2 )
		arcLeftCurve:setKey ( 1, 0.0, params.left.start )
		arcLeftCurve:setKey ( 2, params.left.time, params.left.finish )

		local arcLeftCurveTimer = MOAITimer.new ()
		arcLeftCurveTimer:setSpan ( 0, arcLeftCurve:getLength())
		arcLeftCurveTimer:setMode( MOAITimer.NORMAL )
		arcLeftCurve:setAttrLink ( MOAIAnimCurve.ATTR_TIME, arcLeftCurveTimer, MOAITimer.ATTR_TIME )
		arcLeftCurveTimer:start()

		params.left = arcLeftCurve
	end

	if type(params.right) == "table" then
		local arcRightCurve = MOAIAnimCurve.new ()
		arcRightCurve:reserveKeys ( 2 )
		arcRightCurve:setKey ( 1, 0.0, params.right.start )
		arcRightCurve:setKey ( 2, params.right.time, params.right.finish )

		local arcRightCurveTimer = MOAITimer.new ()
		arcRightCurveTimer:setSpan ( 0, arcRightCurve:getLength())
		arcRightCurveTimer:setMode( MOAITimer.NORMAL )
		arcRightCurve:setAttrLink ( MOAIAnimCurve.ATTR_TIME, arcRightCurveTimer, MOAITimer.ATTR_TIME )
		arcRightCurveTimer:start()

		params.right = arcRightCurve
	end

	local seerID = seer:getID()
	local shadowMap = KLEIShadowMap.ELOS_DIRECT
	if params.peripheral then
		shadowMap = KLEIShadowMap.ELOS_PERIPHERY
		seerID = seerID + simdefs.SEERID_PERIPHERAL
	end

	self._boardRig._game.shadow_map:insertLOS(shadowMap, seerID, params.right, params.left, params.range, self._prop)
end

function agentrig:previewMovement( moveCost )
	if self._flagUI then
		self._flagUI:previewMovement( moveCost )
	end
end

function agentrig:generateTooltip( debugMode )
	local tooltip = unitrig.rig.generateTooltip( self, debugMode ) 
	return tooltip	
end

function agentrig:refreshAnim( unit )
	local weapon = simquery.getEquippedGun(unit)

	if weapon and weapon:getUnitData() ~= self._weaponUnitData then

		local rawUnit = unit:getSim():getUnit(unit:getID() )
		local unloadedAnims = {}
		if self._weaponUnitData then
			unapplyKanim( animmgr.lookupAnimDef( self._weaponUnitData.weapon_anim ), self._prop )
			util.tmerge( unloadedAnims, self._kanim[ self._weaponUnitData.agent_anim ] )
		elseif rawUnit and rawUnit:isNPC() then
			util.tmerge( unloadedAnims, self._kanim[ "anims_1h" ] )
		end

		for _,anim in pairs(unloadedAnims) do
			assert(GetAnimResource(anim), anim)
			self._prop:unbindAnim( GetAnimResource(anim) )
		end

		self._weaponUnitData = weapon:getUnitData()

		local loadedAnims = {}
		if self._weaponUnitData then
			applyKanim( animmgr.lookupAnimDef( self._weaponUnitData.weapon_anim ), self._prop )
			util.tmerge( loadedAnims, self._kanim[ self._weaponUnitData.agent_anim ] )		
		end

		for _,anim in pairs(loadedAnims) do
			assert(GetAnimResource(anim), anim)
			self._prop:bindAnim( GetAnimResource(anim) )
		end

	elseif not weapon then
		local rawUnit = unit:getSim():getUnit(unit:getID() )
		local unloadedAnims = {}
		if self._weaponUnitData then
			unapplyKanim( animmgr.lookupAnimDef( self._weaponUnitData.weapon_anim ), self._prop )
			util.tmerge( unloadedAnims, self._kanim[ self._weaponUnitData.agent_anim ] )

		elseif rawUnit and rawUnit:getPlayerOwner():isNPC() then
			util.tmerge( unloadedAnims, self._kanim[ "anims" ] )
		end

		for _,anim in pairs(unloadedAnims) do
			assert(GetAnimResource(anim), anim)
			self._prop:unbindAnim( GetAnimResource(anim) )
		end

		self._weaponUnitData = nil

		local loadedAnims = {}
		local defaultAnims = "anims"
		if rawUnit and rawUnit:getPlayerOwner():isNPC() and rawUnit:getTraits().vip and rawUnit:isAlerted() then
			defaultAnims = "anims_panic"
		end
		util.tmerge( loadedAnims, self._kanim[ defaultAnims ] )

		for _,anim in pairs(loadedAnims) do
			assert(GetAnimResource(anim), anim)
			self._prop:bindAnim( GetAnimResource(anim) )
		end

	end

    local movingBodyID = unit:getTraits().movingBody and unit:getTraits().movingBody:getID()
	if self._draggingBodyID ~= movingBodyID then
		if self._draggingBodyID then
			local bodyRig = self._boardRig:getUnitRig( self._draggingBodyID )
			if bodyRig then
				local grp_build = bodyRig._kanim.grp_build[1]
				self._prop:unbindBuild(GetAnimResource(grp_build))
                self._prop:setCurrentAnim( "dead" )
				local bodyUnit = bodyRig:getUnit()
				local gender = bodyUnit:getUnitData().gender or "male"
				if bodyUnit:getTraits().disguiseOn then
					gender = "male"
				end				
				self._prop:unbindAnim(GetAnimResource(self._kanim.grp_anims["anims"][gender]) )
				if self._weaponUnitData then
					self._prop:unbindAnim(GetAnimResource(self._kanim.grp_anims[self._weaponUnitData.agent_anim][gender]) )
				else
					self._prop:unbindAnim(GetAnimResource(self._kanim.grp_anims["anims_unarmed"][gender]) )
				end
			end
		end

		if movingBodyID then
			local bodyRig = self._boardRig:getUnitRig( movingBodyID )
			if bodyRig then
				local grp_build = bodyRig._kanim.grp_build[1]
				self._prop:bindBuild(GetAnimResource(grp_build))
				local bodyUnit = bodyRig:getUnit()
				local gender = bodyUnit:getUnitData().gender or "male"
				if bodyUnit:getTraits().disguiseOn then
					gender = "male"
				end
				self._prop:bindAnim(GetAnimResource(self._kanim.grp_anims["anims"][gender]) )
				if self._weaponUnitData then
					self._prop:bindAnim(GetAnimResource(self._kanim.grp_anims[self._weaponUnitData.agent_anim][gender]) )
				else
					self._prop:bindAnim(GetAnimResource(self._kanim.grp_anims["anims_unarmed"][gender]) )
				end
			end
		end

		self._draggingBodyID = movingBodyID
	end


end

function agentrig:refreshRenderFilter()
	if self._renderFilterOverride then
		self._prop:setRenderFilter( self._renderFilterOverride )
	else
		local unit = self._boardRig:getLastKnownUnit( self._unitID )
		if unit then
			local gfxOptions = self._boardRig._game:getGfxOptions()
			if gfxOptions.bMainframeMode or gfxOptions.bTacticalView then
				self._prop:setRenderFilter( cdefs.RENDER_FILTERS["mainframe_agent"] )
			elseif unit:isGhost() then
				self._prop:setPlayMode( KLEIAnim.STOP )
				assert(self._prop:getFrameCount() ~= nil or error( string.format("Missing Animation: %s, %s:%s", unit:getUnitData().kanim, self._prop:getCurrentAnim(), self._prop:getAnimFacing() ) )) --throw an error if the animation is missing
				self._prop:setFrame( self._prop:getFrameCount() - 1 ) -- Always want to be ghosted at the last frame (aim, death, etc.)
				self._prop:setRenderFilter( cdefs.RENDER_FILTERS["ghost"] )
			else
				self._prop:setPlayMode( self._playMode )

				if unit:getTraits().invisible then
					self._prop:setRenderFilter( cdefs.RENDER_FILTERS["cloak"] )
				elseif unit:isPC() then
					self._prop:setRenderFilter( cdefs.RENDER_FILTERS["default"] )
                else
					self._prop:setRenderFilter( cdefs.RENDER_FILTERS["shadowlight"] )
				end
				
			end
		end
	end
end

function agentrig:selectedToggle( toggle )
	if self._flagUI then
		if toggle == true then
			self._flagUI:moveToFront()
			self._flagUI:refreshFlag( nil, true )
		else
			self._flagUI:refreshFlag( nil, false )
		end
	end
end

function agentrig:onUnitAlerted( viz, eventData )
	local x,y = self:getLocation()
	if self._boardRig:canPlayerSee(x, y ) then		
		self._boardRig:cameraFit( self._boardRig:cellToWorld( x, y )  )
	end
end

function agentrig:refreshHUD( unit )

	local unitOwner = unit:getPlayerOwner()

	self._HUDzzz:setVisible(false)
	if unit:isKO() and not unit:isDead() then
		self._HUDzzz:setVisible(true)
	end

	self._HUD_shield:setVisible( (unit:getTraits().shields or 0) > 0 and not unit:isKO() )

	local gfxOptions = self._boardRig._game:getGfxOptions()
	if gfxOptions.bMainframeMode then

	   	if unit:getTraits().tagged then
	   		if not self._tagged then
	   			self._tagged = self:createHUDProp("kanim_hud_tag", "effect", "loop", self._boardRig:getLayer("ceiling"), self._prop )				
	   		end
	   	end

	else
	   	if self._tagged then
	   		self._boardRig:getLayer("ceiling"):removeProp( self._tagged  )	
	   		self._tagged = nil	
	   	end
	   	
		if self._coverRig then
			self._coverRig:refresh( unit:getLocation() )			
		end
		
        self:refreshInterest()
	end

	if self._flagUI then
		self._flagUI:refreshFlag( unit )
	end
end

function agentrig:changeKanim(newKanim, unit)

	self._oldKanim = self._kanim
	self._kanim = newKanim
	local prop = self._prop

	unapplyKanim( self._oldKanim, prop )
	if self._weaponUnitData then
		for i,v in ipairs(self._oldKanim[self._weaponUnitData.agent_anim]) do
			prop:unbindAnim( KLEIResourceMgr.GetResource(v) )
		end
	end

	applyKanim( self._kanim, prop )
	if self._weaponUnitData then
		for i,v in ipairs(self._kanim[self._weaponUnitData.agent_anim]) do
			prop:bindAnim( KLEIResourceMgr.GetResource(v) )
		end
	end
	self._draggingBodyID = nil
	--prop:setCurrentAnim( self._kanim.anim or "idle" )		
end

function agentrig:refreshProp( refreshLoc )

	local unit = self:getUnit()
	if unit:getTraits().tempKanim then
		if self._kanim ~= unit:getTraits().tempKanim then				
			self:changeKanim(lookupAnimDef(unit:getTraits().tempKanim))
		end
	else
		if self._kanim ~= self._defaultKanim then
			self:changeKanim( self._defaultKanim )
		end
	end

	unitrig.rig.refreshProp( self, refreshLoc )

	self:refreshAnim( self:getUnit() )
end

function agentrig:refreshLocation( facing )
	unitrig.rig.refreshLocation( self, facing)
	
	local x, y = self:getLocation()
	local occluded = self._boardRig:queryCellOcclusion( self:getUnit(), x, y )
	
	if occluded and not self._bWireframe then
		self._bWireframe = true
		self._boardRig._game:insertWireframeProp( self._prop )
	elseif not occluded and self._bWireframe then
		self._bWireframe = false
		self._boardRig._game:removeWireframeProp( self._prop )
	end
end


function agentrig:refresh( ev )
	unitrig.rig.refresh( self )

	local unit = self:getUnit()
    if not ev then
	    -- Determine what state the unit should be in.
	    self:transitionUnitState( nil )
        if unit:isValid() and unit:getLocation() then
	        self:transitionUnitState( self._idleState )
        end
    end

	local hud = self._boardRig._game.hud
	if hud ~= nil and hud:canShowElement( "agentFlags" ) and unit:getLocation() and unit:getPlayerOwner() ~= nil then
		if self._flagUI == nil then
			self._flagUI = flagui( self, self:getRawUnit() or unit )
		end

	elseif self._flagUI then
		self._flagUI:destroy()
		self._flagUI = nil
	end

	if self._flagUI then
		self._flagUI:refreshFlag( unit )
	end
end


function agentrig:setLocation( x, y )
	
	if x and y and ( self._x ~= x or self._y ~= y )then
		self._x, self._y = x, y
	end
end

return
{
	rig = agentrig,
    getIdleAnim = getIdleAnim,
}

