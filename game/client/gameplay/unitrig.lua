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
local binops = include( "modules/binary_ops" )
local array = include( "modules/array" )
local rig_util = include( "gameplay/rig_util" )
local animdefs = include( "animdefs" )
include("class")

---------------------------------------------------------------
-- Local

local simdefs = nil -- Lazy initialized after the sim is mounted.
local simquery = nil -- Lazy initialized after the sim is mounted.

---------------------------------------------------------------
local function lookupAnimDef( name )
	return animdefs.defs[ name ]
end

-------------------------------------------------------------
-- Base unit state.  This should be pretty agnostic about the
-- unit, supporting common functionality features common to
-- state implementations for any unit type.

local base_state = class()

function base_state:init( rig, name )
	assert(rig)
	self._name = name
	self._rig = rig
	self._targetX, self.targetY	= nil,nil
end

function base_state:onEnter()
end


function base_state:waitForAnim( ... )
	self._rig:waitForAnim( ... )
end

function base_state:wait( ... )
	self._rig:wait( ... )
end

function base_state:waitDuration( duration )
	local timer = MOAITimer.new ()
	timer:setSpan( 0, duration )
	timer:start()
	self:wait( timer )
end

function base_state:onExit()
end

function base_state:onSimEvent( ev, eventType, eventData )
	if eventType == simdefs.EV_UNIT_SHOW_LABLE then		
		local fxmgr = self._rig._boardRig._game.fxmgr
		local x0, y0 = ev.eventData.unit:getLocation()
		x0, y0 = self._rig._boardRig:cellToWorld( x0, y0 )
		
		fxmgr:addFloatLabel( x0, y0, ev.eventData.txt, 2 )			

		if ev.eventData.sound then
			self:playSound(ev.eventData.sound)
		end	
	end
end

function base_state:generateTooltip()
	local str = string.format("State: %s\n", self._name )

	for k,v in pairs(self) do
		if type(v) ~= "function" then
			str = str .. tostring(k) .. " = " .. tostring(v) .. "\n"
		end
	end

	return str
end

------------------------------------------------------

local unitrig = class()

function unitrig:init( boardRig, unit )
	--log:write( "UNIT RIG -- %s", unitData.name )
	local unitID = unit:getID()
	local unitData = unit:getUnitData()

	simdefs = boardRig:getSim():getDefs()
	simquery = boardRig:getSim():getQuery()

	local prop, animdef = animmgr.createPropFromAnimDef( unitData.kanim )
    prop:setShadowMap( boardRig._game.shadow_map )
	prop:setDebugName( unitData.name .. "_" .. tostring(unitID) )
	boardRig:getLayer():insertProp( prop )

	if animdef.filterSymbols then
		for i,set in ipairs(animdef.filterSymbols) do
			prop:setRenderFilter( set.symbol, cdefs.RENDER_FILTERS[set.filter] )	
		end
	end
	self._defaultKanim = animdef
	self._spotSound = nil	
	self._boardRig = boardRig
	self._prop = prop
	self._unitID = unitID
	self._kanim = animdef
	self._x = nil
	self._y = nil
	self._facing = nil
	self._visible = nil
	self._state = nil
	self._playMode = KLEIAnim.LOOP	

	self._prop:setSymbolVisibility( "outline", "tile_outline", false )	

	if unit:getTraits().mainframe_suppress_rangeMax then
		self._nullFX = self:createHUDProp("kanim_null_fx", "effect", "idle", boardRig:getLayer("floor"), self._prop )
		self._nullFX:setSymbolModulate("innercicrle",1,1,1,0.75)
		self._nullFX:setSymbolModulate("innerring",1,1,1,0.75)
		if unit:getTraits().mainframe_suppress_range > 0 then
			self._nullFX:setVisible(true)
		else
			self._nullFX:setVisible(false)
		end
	end

	if unit:getUnitData().locator then
		local COLOR = { 121/255, 218/255, 217/255, 1 }
		self._HUDlocated = self:createHUDProp("kanim_hud_agent_hud", "item", "start", boardRig:getLayer("ceiling"), self._prop )
		self._HUDlocated:setListener( KLEIAnim.EVENT_ANIM_END,
					function( anim, animname )
						if animname == "start" then
							anim:setCurrentAnim("loop")
						end
					end )
		self._HUDlocated:setSymbolModulate("shockwave", unpack(COLOR) )
		self._HUDlocated:setSymbolModulate("ring5", unpack(COLOR) )
		self._HUDlocated:setVisible(false)
	end


end



function unitrig:setFlash(param)
	--[[
	local time = 30
	local blinkTime = 5
	local blink_state = false

	while time > 0 do

		if blink_state == true then
			selfrefreshRenderFilter()
		else
			self._prop:setRenderFilter( cdefs.RENDER_FILTERS["focus_highlite"] )
		end
		wait(blinkTime)
		time = time - blinkTime
	end

	selfrefreshRenderFilter()
]]
	if param then
		if not self._highliteBlinkThread then
			self._highliteBlinkThread = MOAICoroutine.new()
			self._highliteBlinkThread:run( function() 
				local i = 20
				while true do							
					if i == 20 then
						self._prop:setRenderFilter( cdefs.RENDER_FILTERS["focus_highlite"] )
					elseif i == 10 then
						self:refreshRenderFilter() 								
					elseif i == 0 then						
						i = 21
					end
					i = i - 1
					coroutine.yield()
				end
			end )
			self._highliteBlinkThread:resume()
			
		end
	else	
		if self._highliteBlinkThread then
			self._highliteBlinkThread:stop()
			self._highliteBlinkThread = nil
			self:refreshRenderFilter()
		end

	end
	
end




function unitrig:orientationToFacingMask( orientation, facing )
	facing = facing or self:getFacing()
	local orientation = (facing - orientation*2) % 8
	return 2^orientation
end

function unitrig:getProp()
	return self._prop
end

function unitrig:getUnit()
	return self._boardRig:getLastKnownUnit( self._unitID )
end

function unitrig:getRawUnit()
	-- Note that this MAY be nil even if the rig exists!  (we could be rigging a ghost)
	return self._boardRig:getSim():getUnit( self._unitID )
end

function unitrig:getLocation()
	return self._x, self._y
end

function unitrig:setLocation( x, y )
	if self._x ~= x or self._y ~= y then
		self._x = x
		self._y = y
	end
end

function unitrig:getFacing()
	return self._facing
end

function unitrig:isVisible()
	return self._visible
end

function unitrig:setPlayMode( playMode )	
	self._playMode = playMode
	self._prop:setPlayMode( playMode )
end

function unitrig:playSound( soundPath, alias )
	local unit = self:getUnit()
	local x1,y1 = unit:getLocation()
	if unit:getTraits().voice then
		soundPath = string.gsub(soundPath, "<voice>", unit:getTraits().voice)
	end
	self._boardRig:getSounds():playSound( soundPath, alias, x1, y1 )
end

function unitrig:addAnimFx( kanim, symbol, anim, above, params)
	
	local fxmgr = self._boardRig._game.fxmgr
	local x, y = self._boardRig:cellToWorld( self:getLocation() )
	local args = util.extend(
	{
		x = x,
		y = y,
		kanim = kanim,
		symbol = symbol,
		anim = anim,
		above = above,
	})( params )

	if above == true then
		args.aboveProp = self._prop
	elseif above == false then
		args.belowProp = self._prop
	else
		-- spawn on the fx layer (as of right now, this is the "ceiling" layer)
	end

	return fxmgr:addAnimFx( args )
end

function unitrig:directionToAnimMask( currentAnim, dir, orientation )

	dir = (dir - orientation*2) % simdefs.DIR_MAX
	local flip, facing_mask = false, 2^dir

	local shouldFlip = self._kanim.shouldFlip

	if self._kanim.shouldFlipOverrides then
		for i,set in ipairs(self._kanim.shouldFlipOverrides) do
			if set.anim == currentAnim then
				shouldFlip = set.shouldFlip
				break
			end
		end
	end

	if shouldFlip then
		if dir == simdefs.DIR_N then
			facing_mask = KLEIAnim.FACING_E
			flip = true
		elseif dir == simdefs.DIR_NW then
			facing_mask = KLEIAnim.FACING_SE
			flip = true
		elseif dir == simdefs.DIR_W then
			facing_mask = KLEIAnim.FACING_S
			flip = true
		end
	end

	return flip, facing_mask
end


function unitrig:generateTooltip( debugMode )
	local unit = self:getUnit()
	local tooltip = string.format( "<debug>%s [%d]</>\n", util.toupper(unit:getName()), self._unitID )
	if debugMode == cdefs.DBG_RIGS then
		if self._state then
			tooltip = tooltip .. self._state:generateTooltip()
		end
	end

	return tooltip
end

function unitrig:destroy()
	self:transitionUnitState( nil )
	self._boardRig:getLayer():removeProp( self._prop )
	self._boardRig:refreshLOSCaster( self._unitID )

	if self._spotSound then
		self._boardRig:getSounds():stopSound( self._spotSound )
		self._spotSound = nil
	end

	if self._nullFX then
		self._boardRig:getLayer("floor"):removeProp( self._nullFX  )			
	end

	if self._HUDlocated then
		self._boardRig:getLayer("ceiling"):removeProp( self._HUDlocated )
	end

	if self._monst3rConsole then
		self._prop:removeProp( self._monst3rConsole, true)	
	end

	if self._switchFx then
		self._prop:removeProp( self._switchFx , true)	
	end
end
	

function unitrig:refreshSpotSound(remove)
	local unit = self:getUnit()
    local x, y
    if unit then
        x, y = unit:getLocation()
    end

	if self._spotSound then
		if not unit or remove or not x or unit:isKO() or unit:getTraits().mainframe_status == "off" then
			self._boardRig:getSounds():stopSound( self._spotSound )
			self._spotSound = nil
		elseif unit:getTraits().monst3r and not unit:getTraits().monster_hacking then  
			self._boardRig:getSounds():stopSound( self._spotSound )
			self._spotSound = nil
		else 
			self._boardRig:getSounds():updateSound( self._spotSound, unit:getLocation() )
		end

	elseif unit and unit:getSounds() and unit:getSounds().spot and x and not unit:isKO() then
		self._spotSound = "unitSound-" .. unit:getID()
		self._boardRig:getSounds():playSound( unit:getSounds().spot, self._spotSound, x, y, nil, unit:getTraits().maxOcclusion )
	end
end

function unitrig:performEMP()
    self:addAnimFx( "fx/emp_effect", "character", "idle", true )
    self._prop:setSymbolVisibility( "red", "internal_red", "highlight", "teal", false )
    self._prop:setRenderFilter( cdefs.RENDER_FILTERS[ "mainframe_fused" ] )
end

function unitrig:getIdleAnim()
    return "idle"
end

function unitrig:refreshMonst3rConsoleFx(transition)

	local unit = self:getUnit()
	local stage = (unit:getTraits().monst3rConsole_stage or 0)
	if not self._monst3rConsole and stage > 0 then
		--local x0,y0 = unit:getLocation()
		--local xw0, yw0 = boardrig:cellToWorld( x0,y0)
		self._monst3rConsole = self:createHUDProp("kanim_monst3r_console_fx", "effect", "stage1_in", true,  self:getProp() )--boardrig:getLayer("ceiling")

		self._monst3rConsole:setListener( KLEIAnim.EVENT_STRING,
			function( anim, eventStr )
				if eventStr == "stackIn" then
					self:playSound("SpySociety/Objects/Monst3rConsole/Monst3rConsole_open")	
				elseif eventStr == "screenOn" then
					self:playSound("SpySociety/Objects/Monst3rConsole/Monst3rConsole_open")	
				elseif eventStr == "ringSwap" then
					self:playSound("SpySociety/Objects/Monst3rConsole/Monst3rConsole_RingsSWAP")						
				elseif eventStr == "screenOff" then
					self:playSound("SpySociety/Objects/Monst3rConsole/Monst3rConsole_screenDOWN")						
				elseif eventStr == "screenOn" then
					self:playSound("SpySociety/Objects/Monst3rConsole/Monst3rConsole_screenUP")
				elseif eventStr == "stackEnd" then
					self:playSound("SpySociety/Objects/Monst3rConsole/Monst3rConsole_complete")	
				end
			end )
	end
	if transition then
		self._monst3rConsole:setCurrentAnim("stage"..stage.."_in")	
		self._monst3rConsole:setListener( KLEIAnim.EVENT_ANIM_END,
			function( anim, animname )
				if animname == "stage"..stage.."_in" then
					self._monst3rConsole:setCurrentAnim("stage"..stage.."_loop")	
				end
			end )				
	else
		self._monst3rConsole:setCurrentAnim("stage"..stage.."_loop")	
	end
end

function unitrig:refreshSwitchFx(transition)

	local unit = self:getUnit()
	local stage = (unit:getTraits().switch_stage or 0)
	if not self._switchFx then
		self._switchFx = self:createHUDProp("kanim_switch_fx", "effect", "idle_in", true,  self:getProp() )--boardrig:getLayer("ceiling")	
	end
	if transition then
		if transition == "fail" then
			self._switchFx:setCurrentAnim("stage_"..transition)	

			self._switchFx:setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim, animname )
					if animname == "stage_"..transition then
						self._switchFx:setCurrentAnim(transition.."_fadeout")	
						self._switchFx:setPlayMode( KLEIAnim.ONCE )						
					end
				end )	
		elseif transition == "pass" then
			self._switchFx:setCurrentAnim("stage_"..transition)	

			self._switchFx:setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim, animname )
					if animname == "stage_"..transition then
						self._switchFx:setCurrentAnim(transition.."_loop")	
						self._switchFx:setPlayMode( KLEIAnim.ONCE )						
					end
				end )		
		elseif transition == "pass_loop" then
			self._switchFx:setCurrentAnim("pass_loop")	
		elseif transition == "idle_loop" then
			self._switchFx:setCurrentAnim("idle_loop")				
		end

	else
		self._switchFx:setCurrentAnim("idle_in")	
		self._switchFx:setListener( KLEIAnim.EVENT_ANIM_END,
			function( anim, animname )
				if animname == "idle_in" then
					self._switchFx:setCurrentAnim("idle_loop")	
				end
			end )		
	end
end


function unitrig:onSimEvent( ev, eventType, eventData )
    ev.thread:waitForLocks( self._unitID )

	-- Handle sim events if the rig state does not.
	if self._state == nil or not self._state:onSimEvent( ev, eventType, eventData ) then
		if eventType == simdefs.EV_UNIT_WARPED then
			local unit = self:getUnit()

			if unit:getTraits().warp_in_anim then
				if unit:getLocation() then
					self._state:waitForAnim(unit:getTraits().warp_in_anim)
					self:setCurrentAnim(self:getIdleAnim()) 
				else 				
					self._state:waitForAnim(unit:getTraits().warp_out_anim)
				end
			end
			self:refreshLocation()
			self:refreshProp()			

		elseif eventType == simdefs.EV_UNIT_REFRESH then
			local unit = self:getUnit()
			if eventData.reveal and not unit:getTraits().revealed_scan then
				self:addAnimFx( "gui/hud_fx", "aquire_console", "front", true )
				MOAIFmodDesigner.playSound("SpySociety/Actions/Engineer/wireless_emitter_reveal")			
				unit:getTraits().revealed_scan = true

        		local x0,y0 = unit:getLocation()
        		local txt = "<font1_18_r>"..STRINGS.ABILITIES.WIRELESS_SCAN.."</>"
        		local color = {r=1,g=1,b=41/255,a=0.7}
        		self._boardRig:showFloatText( x0, y0, txt, color, nil , true)
			end

			if eventData.fx and eventData.fx == "emp" and self._boardRig:canPlayerSeeUnit( eventData.unit ) then
				self:addAnimFx( "fx/emp_effect", "character", "idle", true )
			end	

			self:refresh( ev )

        elseif eventType == simdefs.EV_UNIT_HIT then
            if eventData.unit:getTraits().hit_metal then
                self:addAnimFx( "fx/hit_fx", "character", "idle", nil, eventData.unit:getUnitData().hit_fx )
       	 	end

		elseif eventType == simdefs.EV_UNIT_SEEN or eventType == simdefs.EV_UNIT_UNSEEN then
			self:refresh( ev )

		elseif eventType == simdefs.EV_UNIT_CAPTURE then
			self:refresh( ev )
			if not ev.eventData.nosound then				
				MOAIFmodDesigner.playSound("SpySociety/HUD/mainframe/node_capture")		
			end
			self:addAnimFx( "gui/hud_fx", "takeover_console", "front", true )

			local unit = self:getUnit()
			if unit:getTraits().spotSoundPowerDown then
				
				self:refreshSpotSound(true)				
				unit:getSounds().spot = nil			
			end

		elseif eventType == simdefs.EV_UNIT_MAINFRAME_UPDATE then

			if eventData.reveal then
				MOAIFmodDesigner.playSound("SpySociety/Actions/mainframe_objectsreveled")
				self:addAnimFx( "gui/hud_fx", "aquire_console", "front", true )
        		self._boardRig:cameraFit( self._boardRig:cellToWorld( self:getLocation() )  )
        		local unit = self:getUnit()
        		local x0,y0 = unit:getLocation()
        		local txt = STRINGS.UI.FLY_TXT.REVEALED
        		local color = {r=1,g=1,b=41/255,a=1}
        		self._boardRig:showFloatText( x0, y0, txt, color, nil , true)
			end
	
			self:refresh( ev )
		elseif eventType == simdefs.EV_UNIT_PLAY_ANIM then
			if eventData.sound then
				local x1,y1 = self:getLocation()
				self:playSound(eventData.sound,x1,y1)		
			end
			self._state:waitForAnim(eventData.anim)

		elseif eventType == simdefs.EV_UNIT_ADD_FX then
			local unit = self:getUnit()
			self:addAnimFx( eventData.kanim,  eventData.symbol,  eventData.anim,  eventData.above, eventData.params )

		elseif eventType == simdefs.EV_UNIT_UPDATE_SPOTSOUND then
			self:refreshSpotSound(eventData.stop)

		elseif eventType == simdefs.EV_UNIT_MONST3R_CONSOLE then
			local unit = self:getUnit()
			self:refreshMonst3rConsoleFx(true)
		elseif eventType == simdefs.EV_UNIT_SWTICH_FX then
			local unit = self:getUnit()
			self:refreshSwitchFx(eventData.transition)			
		end
	end
end

function unitrig:transitionUnitState( state, ... )

	if state ~= self._state then
		if self._state then
			self._state:onExit()
		end

		self._state = state

		if self._state then
			self._state:onEnter( ... )
		end

	end
end

function unitrig:setCurrentAnim( animName, facing, sounds)
	local unit = self:getUnit()

	if not facing then
		facing = unit:getFacing()
	end

	if not facing then
		return
	end

	-- Remap the anim if a mapping exists.
	if self._kanim.animMap then
		animName = self._kanim.animMap[ animName ] or animName
		if #animName == 0 then
			return -- (anim not available)
		end
	end

   	local gfxOptions = self._boardRig._game:getGfxOptions()
	local simCore = self._boardRig:getSim()
	local orientation = self._boardRig._game:getCamera():getOrientation()
	local flip, facing_mask = self:directionToAnimMask( animName, facing, orientation )

	self._prop:setCurrentFacingMask( facing_mask )

	--if we're playing a flipped over-the shoulder animation (_R or _L) then we need to use the other shoulder
	if flip and string.find(animName, "_[RL]$", -2) then
		animName = string.gsub(animName, "_([RL])$", function(s) if s == "R" then return "_L" else return "_R" end end)
	end

	if (gfxOptions.bMainframeMode or gfxOptions.bTacticalView) and unit:getTraits().mainframe_icon == true then
		animName = animName .. "_icon"
	end


	self._prop:setCurrentAnim( animName )
    animmgr.refreshIsoBounds( self._prop, self._kanim, facing )

	local scale = self._kanim.scale
	if flip then
		self._prop:setScl( -scale, scale, scale )
	else
		self._prop:setScl( scale, scale, scale )
	end

	local prop = self._prop
	if sounds then
		prop:setListener( KLEIAnim.EVENT_STRING,
			function( anim, eventStr )
				for i,sound in ipairs(sounds) do
					if sound.event and sound.event == eventStr then
						local x0, y0 = self:getUnit():getLocation()
						local sourceRig = sound.source or self
						sourceRig:playSound( sound.sound, nil, x0, y0 )
					end
				end
			end )
	else
		prop:setListener( KLEIAnim.EVENT_STRING, nil)
	end
end

function unitrig:waitForAnim( animname,facing,exitFrame,sounds )
	assert( animname )

	local lastFrame = 0
	if not facing then
		facing = self:getFacing()
	end

    local prop = self._prop
	if prop:shouldDraw() then

		self:setPlayMode( KLEIAnim.ONCE )
		self:setCurrentAnim( animname, facing)

		assert(prop:getFrameCount() ~= nil or error( string.format("Missing Animation: %s, %s:%s(%d)",
            self:getUnit():getUnitData().kanim, animname, prop:getAnimFacing(), facing ) )) --throw an error if the animation is missing
		if prop:getFrameCount() and prop:getFrame() + 1 < prop:getFrameCount() then
			local animDone = false
			prop:setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim, animname )
					animDone = true
				end )

			while not animDone and prop:shouldDraw() do
				if exitFrame  and  prop:getFrame() >= exitFrame then
					animDone = true
				end

				if sounds then
					for i,sound in pairs(sounds)do
						if sound.sound and sound.soundFrames then
							local frame = prop:getFrame() % prop:getFrameCount()
							if sound.soundFrames == frame and lastFrame ~= frame then

								local x0, y0 = self:getUnit():getLocation()
								local sourceRig = sound.source or self
								sourceRig:playSound( sound.sound, nil, x0, y0 )
								lastFrame = frame
							end					
						end	
					end
				end

				coroutine.yield()
			end

			prop:setListener( KLEIAnim.EVENT_ANIM_END )
		end
	end
end

function unitrig:wait( action, soundlist )
	local currentFrame = 0
	while action and action:isActive() do
		local x0, y0 = self:getUnit():getLocation()
		currentFrame = currentFrame + 1
		if soundlist then
			for _, info in ipairs(soundlist) do
				local frames = info.frames			
				if array.find( frames, currentFrame) then
					local sounds = info.sounds
					for _,sound in ipairs(sounds) do
						self:playSound( sound, nil, soundlist.x or x0, soundlist.y or y0 )
					end
				end
			end
		end
		coroutine.yield()
	end
end

function unitrig:startTooltip()
	self._prop:setSymbolVisibility( "outline", "tile_outline", true )
end

function unitrig:stopTooltip()
	self._prop:setSymbolVisibility( "outline", "tile_outline", false )
end

function unitrig:refresh()
	local unit = self:getUnit()
	self:refreshLocation()
	self:refreshProp()
	self:refreshHUD(unit)
end

function unitrig:refreshProp( refreshLoc )

	local x, y = self:getLocation()
	local unit = self:getUnit()
	if x and y then
		if not refreshLoc then
			-- Set the actual prop to our current location!
			self._prop:setLoc( self._boardRig:cellToWorld( x, y ) )
		end

		-- Set the correct facing on the anim prop!
		local orientation = self._boardRig._game:getCamera():getOrientation()

		local flip, facing_mask = self:directionToAnimMask( self._prop:getCurrentAnim(), self:getFacing(), orientation)

		self._prop:setCurrentFacingMask( facing_mask )

		local scale = self._kanim.scale
		if flip then
			self._prop:setScl( -scale, scale, scale )
		else
			self._prop:setScl( scale, scale, scale )
		end
		
		animmgr.refreshIsoBounds( self._prop, self._kanim, self:getFacing() )

		self._boardRig:refreshLOSCaster( self._unitID )

		self:refreshRenderFilter()
		self:refreshSpotSound()

		if self._nullFX then		
			if unit:getTraits().mainframe_suppress_range > 0 then
				self._nullFX:setVisible(true)
			else
				self._nullFX:setVisible(false)
			end
		end

		if self._HUDlocated then
			if self._boardRig:canPlayerSee(x,y) and not unit:getTraits().deployed then
				if not self._HUDlocated:getVisible() then
					self._HUDlocated:setVisible(true)
					self._HUDlocated:setCurrentAnim("start")
				end
			else
				self._HUDlocated:setVisible(false)
			end
		end

		if unit and unit:getTraits().monst3rConsole_stage then
			self:refreshMonst3rConsoleFx()
		end

		if unit and unit:getTraits().multiLockSwitch then
			if unit:getTraits().switched then
				self._prop:setSymbolVisibility( "handle_down", true )
				self._prop:setSymbolVisibility( "handle_up", false )
			else
				self._prop:setSymbolVisibility( "handle_up", true )
				self._prop:setSymbolVisibility( "handle_down", false )
			end
		end
		if unit and unit:getTraits().switched then		
			if not unit:getTraits().unlocked then
				self:refreshSwitchFx("idle_loop")
			else
				self:refreshSwitchFx("pass_loop")
			end
		end		

	end
end

function unitrig:setHidden( isHidden )
    if isHidden ~= self._isHidden then
        self._isHidden = isHidden
        self:refreshLocation()
    end
end

function unitrig:refreshLocation( facing )

	local unit = self:getUnit()
	local x, y = unit:getLocation()
	facing = facing or unit:getFacing()

	local gfxOptions = self._boardRig._game:getGfxOptions()
	local isVisible = not self._isHidden and (not gfxOptions.bMainframeMode or not unit:getTraits().noMainframe)
    isVisible = isVisible and (unit:isGhost() or self._boardRig:canPlayerSeeUnit( unit ))
    isVisible = isVisible and not simquery.isUnitDragged( self._boardRig:getSim(), unit )
    isVisible = isVisible and x ~= nil
	self._prop:setVisible( isVisible )
	self._visible = isVisible

	if x ~= self._x or y ~= self._y or facing ~= self._facing then
		-- Remove rig from its old locations and add to the new location.
		self:setLocation( x, y )
		self._facing = facing
	end
end


function  unitrig:createHUDProp(kanim, symbolName, anim, layer, unitProp, x, y )
	return self._boardRig:createHUDProp(kanim, symbolName, anim, layer, unitProp, x, y )
end

function unitrig:refreshHUD( unit )	
	local rawUnit = self._boardRig:getSim():getUnit(self._unitID)
	if rawUnit == nil then
		-- Unit may have been despawned.  We may only exist as a ghost rig.
		return
	end
	
	local teamClr = self._boardRig:getTeamColour(rawUnit:getPlayerOwner()).primary
	local gfxOptions = self._boardRig._game:getGfxOptions()
	
	if rawUnit:getTraits().mainframe_item == true then
		if rawUnit:getTraits().mainframe_status == "off" then
			self._prop:setSymbolVisibility( "red", "internal_red", "highlight", "teal", false )

		elseif not rawUnit:getTraits().mainframe_console then
			if rawUnit:isPC() then
				self._prop:setSymbolVisibility( "red", "internal_red", false )
				self._prop:setSymbolVisibility( "highlight", "teal", true )
            else
				self._prop:setSymbolVisibility( "red", "internal_red", true )
				self._prop:setSymbolVisibility( "highlight", "teal", false )
			end
		end

	end
end


function unitrig:refreshRenderFilter() 
	local cell = self._boardRig:getLastKnownCell( self:getLocation() )
	if cell then
		local gfxOptions = self._boardRig._game:getGfxOptions()
		local cellrig = self._boardRig:getClientCellXY( cell.x, cell.y )

		local render_filter
		if gfxOptions.bMainframeMode or gfxOptions.bTacticalView then
			local unit = self:getUnit()
			local playerOwner = unit:getPlayerOwner()

			if unit:getTraits().mainframe_status == "off" then
				render_filter = 'mainframe_fused'
			elseif unit:getTraits().agent_filter then
				render_filter = 'mainframe_agent'
			elseif playerOwner == nil or playerOwner:isNPC() then
				render_filter = 'mainframe_npc'
			else
				render_filter = 'default'
			end

		else
			if gfxOptions.bFOWEnabled then
				if cell and not cell.ghostID  then
					render_filter = cdefs.MAPTILES[ cellrig.tileIndex ].render_filter.dynamic or "shadowlight"
				else
					render_filter = cdefs.MAPTILES[ cellrig.tileIndex ].render_filter.fow or gfxOptions.FOWFilter
				end
			else
				render_filter = cdefs.MAPTILES[ cellrig.tileIndex ].render_filter.normal or gfxOptions.KAnimFilter
			end
		end
		self._prop:setRenderFilter( cdefs.RENDER_FILTERS[ render_filter ] )
	
	end
	
end

return
{
	rig = unitrig,
	base_state = base_state,
}

