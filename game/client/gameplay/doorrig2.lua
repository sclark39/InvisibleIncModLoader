----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include( "sim/simquery" )

----------------------------------------------------------------

local function createDoorLock( boardRig, kanimName, x1, y1, facing )
	local l1x,l1y = boardRig:cellToWorld( x1, y1 )
	local prop = boardRig:createHUDProp( kanimName, "sock_trap", "idle", boardRig:getLayer(), nil, l1x, l1y, facing )
	prop._facing = facing
    prop:setDebugName( string.format( "%s-%d-%d-%d", kanimName, x1, y1, facing ))
    prop:setVisible( false )
    return prop
end

----------------------------------------------------------------

local door_rig = class(  )

function door_rig:init( boardRig, x1, y1, simdir1, VBO )
	local N,E,S,W = simdefs.DIR_N, simdefs.DIR_E, simdefs.DIR_S, simdefs.DIR_W
	
	local x2, y2 = x1, y1
	local simdir2
	if simdir1 == E then
		x2 = x1+1
		simdir2 = W
	elseif simdir1 == N then
		y2 = y1+1
		simdir2 = S
	else
		assert( false )
	end

	local cellviz_1 = boardRig:getClientCellXY( x1, y1 )
	table.insert( cellviz_1._dependentRigs, self )

	local cellviz_2 = boardRig:getClientCellXY( x2, y2 )
	table.insert( cellviz_2._dependentRigs, self )
	
    local scell = boardRig:getSim():getCell( x1, y1 )
    if scell and simquery.cellHasTag( boardRig:getSim(), scell, "door_front" ) then
        -- Reverse the UVs, this door has a particular facing.
        self._wallUVs = cellviz_1:getSide( simdir1 ).altwallUVs
    end
    if self._wallUVs == nil then
        self._wallUVs = cellviz_1:getSide( simdir1 ).wallUVs
    end
                    
	self._boardRig = boardRig
	self._x1, self._y1 = x1, y1
	self._x2, self._y2 = x2, y2
	self._simdir1, self._simdir2 = simdir1, simdir2
	
	self._game = boardRig._game
	self._simdefs = simdefs
	self._layer = boardRig:getLayer()



	local mesh = MOAIMesh.new()
	mesh:setVertexBuffer( VBO )
	mesh:setPrimType( MOAIMesh.GL_TRIANGLES )
	mesh:setElementOffset( 0 )
	mesh:setElementCount( 0 )

	local zx, zy = boardRig:cellToWorld( -0.5, -0.5 )

	local prop = MOAIProp.new()
	prop:setDeck( mesh )
	prop:setDepthTest( false )
	prop:setDepthMask( false )
	prop:setCullMode( MOAIProp.CULL_NONE )
	prop:setLoc( zx, zy )
	prop:setShader( MOAIShaderMgr.getShader( MOAIShaderMgr.WALL_SHADER) )
	prop:getShaderUniforms():setUniformInt( "Type", 0 )
    prop:setDebugName( string.format( "door-%d-%d-%d", x1, y1, simdir1 ))
    prop:setVisible( false )

	self._layer:insertProp( prop )
	self._prop = prop
	self._mesh = mesh
	self._offsets = cellviz_1._doorGeoInfo[simdir1]

	self._secure = cellviz_1:getSide( simdir1 ).secure	
	if self._secure then		
        self.lock1 = createDoorLock( self._boardRig, "kanim_door_lock", x1, y1, simdir1 )
        self.lock2 = createDoorLock( self._boardRig, "kanim_door_lock", x2, y2, simdir2 )
    end

	self._vault_door = cellviz_1:getSide( simdir1 ).vault_door
	if self._vault_door then		
        self.lock1 = createDoorLock( self._boardRig, "kanim_vault_lock", x1, y1, simdir1 )
        self.lock2 = createDoorLock( self._boardRig, "kanim_vault_lock", x2, y2, simdir2 )
	end
end

function door_rig:destroy()

	if self.lock1 then		
		self._boardRig:getLayer():removeProp( self.lock1 )
	end
	if self.lock2 then		
		self._boardRig:getLayer():removeProp( self.lock2 )
	end

	self._layer:removeProp( self._prop )
	self._prop = nil
	self._mesh = nil

end

function door_rig:setUVTransform( uvInfo )
	local u,v,U,V = unpack( uvInfo )
	local uvTransform = MOAITransform.new()
	uvTransform:setScl( U-u, V-v )
	uvTransform:addLoc( u, v )

	self._mesh:setTexture( cdefs.WALLTILES_FILE )
	self._prop:setUVTransform( uvTransform )
end

function door_rig:getLocation1()
	return self._x1, self._y1
end
function door_rig:getLocation2()
	return self._x2, self._y2
end
function door_rig:getFacing1()
	return self._simdir1
end
function door_rig:getFacing2()
	return self._simdir2
end

function door_rig:onSimEvent( ev, eventType, eventData )
	if eventType == simdefs.EV_EXIT_MODIFIED then
		if eventData then
            self:refreshProp()
			if eventData.exitOp == simdefs.EXITOP_BREAK_DOOR then
				self:playEffect("fx/door_break_effect", "break", eventData.dir)
			end
		end
	end	
end

function door_rig:playEffect(effect, anim, dir)
	local x1,y1 = self:getLocation1()
	local x2,y2 = self:getLocation2()

	local facing1 = simquery.getDirectionFromDelta(x2-x1, y2-y1)
	local facing2 = simquery.getDirectionFromDelta(x1-x2, y1-y2)

	x1,y1 = self._boardRig:cellToWorld(x1, y1)
	x2,y2 = self._boardRig:cellToWorld(x2, y2)

	local orientation = self._boardRig._game:getCamera():getOrientation()
	dir = (dir - orientation*2) % simdefs.DIR_MAX
	facing1 = (facing1 - orientation*2) % simdefs.DIR_MAX
	facing2 = (facing2 - orientation*2) % simdefs.DIR_MAX
	local facingMask1 = 2^facing1
	local facingMask2 = 2^facing2

	if dir == facing2 then
		self._boardRig._game.fxmgr:addAnimFx( { kanim=effect, symbol="effect", anim=anim, x=x2, y=y2, facingMask=facingMask2, layer=self._boardRig:getLayer("main") } )
	else
		self._boardRig._game.fxmgr:addAnimFx( { kanim=effect, symbol="effect", anim=anim, x=x1, y=y1, facingMask=facingMask1, layer=self._boardRig:getLayer("main") } )
	end
end

function door_rig:refreshProp()
	local gfxOptions = self._game:getGfxOptions()
	local boardRig = self._boardRig
	local simdefs = boardRig._game.simCore:getDefs()
	local bMainFrameMode = gfxOptions.bMainframeMode or gfxOptions.bTacticalView
	local bShortWallMode = gfxOptions.bShortWallMode

	local x1,y1 = self:getLocation1()
	local x2,y2 = self:getLocation2()

	local ex, ey, EX, EY
	local nx, ny, NX, NY

	if x2-x1 == 1 then
		ex, ey = self._boardRig:cellToWorld( x1 + 0.5, y1 - 0.5 )
		EX, EY = self._boardRig:cellToWorld( x1 + 0.5, y1 + 0.5 )
		nx,ny = 0,1
		NX,NY = 0,-1
	elseif x1-x2 == 1 then
		ex, ey = self._boardRig:cellToWorld( x2 + 0.5, y2 - 0.5 )
		EX, EY = self._boardRig:cellToWorld( x2 + 0.5, y2 + 0.5 )
		nx,ny = 0,-1
		NX,NY = 0,1
	elseif y2-y1 == 1 then
		ex, ey = self._boardRig:cellToWorld( x1 - 0.5, y1 + 0.5 )
		EX, EY = self._boardRig:cellToWorld( x1 + 0.5, y1 + 0.5 )
		nx,ny = 1,0
		NX,NY = -1,0
	elseif y1-y2 == 1 then
		ex, ey = self._boardRig:cellToWorld( x1 - 0.5, y2 + 0.5 )
		EX, EY = self._boardRig:cellToWorld( x1 + 0.5, y2 + 0.5 )
		nx,ny = -1,0
		NX,NY = 1,0
	else
		crash()
	end

	local ccell_1 = boardRig:getLastKnownCell( x1,y1 )
	local ccell_2 = boardRig:getLastKnownCell( x2,y2 )

	local offset, count = 0, 0

	if ccell_1 or ccell_2 then

		--cell1 is not exit and cell2 is exit then 

		local exit1 = ccell_1 and ccell_1.exits[ self._simdir1 ]
		local exit2 = ccell_2 and ccell_2.exits[ self._simdir2 ]

		-- This is slightly complicated by the fact that either either of cell or to_cell may be ghosted (or non-existent)
		-- We want to use the *most up to date* information (eg. the non-ghosted info, or most recent newest ghosted info).
		assert( ccell_1 or ccell_2 ) -- One of these MUST be non-nil, otherwise we shouldn't be visible.
		local showClosed, showLocked
		if ccell_1 and not ccell_1.ghostID then
			showClosed, showLocked = exit1.closed, exit1.locked
		elseif ccell_2 and not ccell_2.ghostID then
			showClosed, showLocked = exit2.closed, exit2.locked
		elseif not ccell_1 then
			showClosed, showLocked = exit2.closed, exit2.locked
		elseif not ccell_2 then
			showClosed, showLocked = exit1.closed, exit1.locked
		elseif ccell_1.ghostID > ccell_2.ghostID then
			showClosed, showLocked = exit1.closed, exit1.locked
		else
			showClosed, showLocked = exit2.closed, exit2.locked
		end

        -- Show guard elevators and elevators in use as always locked.
        if exit1 and (exit1.keybits == simdefs.DOOR_KEYS.GUARD or exit1.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE) then
            showLocked = true
        elseif exit2 and (exit2.keybits == simdefs.DOOR_KEYS.GUARD or exit2.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE) then
            showLocked = true
	    end

		if (not bMainFrameMode and bShortWallMode) then
			self._prop:setScl(1,1,cdefs.SHORT_WALL_SCALE)
		else
			self._prop:setScl(1,1,1)
		end

		if bMainFrameMode then
            if showLocked then
                assert( self._offsets and self._offsets['mainframe_locked'] )
                offset, count = unpack( self._offsets['mainframe_locked'] )
            elseif showClosed then
                assert( self._offsets and self._offsets['mainframe_unlocked'] )
                offset, count = unpack( self._offsets['mainframe_unlocked'] )
            else
                assert( self._offsets and self._offsets['mainframe_open'] )
                offset, count = unpack( self._offsets['mainframe_open'] )
            end
			self:setUVTransform( cdefs.WALL_MAINFRAME )
		elseif showClosed and showLocked then
			if self._offsets and self._offsets['locked'] then
				offset, count = unpack( self._offsets['locked'] )
			end
			self:setUVTransform( self._wallUVs.locked )
		elseif showClosed then
			if self._offsets and self._offsets['unlocked'] then
				offset, count = unpack( self._offsets['unlocked'] )
			end
			self:setUVTransform( self._wallUVs.unlocked )
		elseif showLocked then
			if self._offsets and self._offsets['broken'] and self._wallUVs.broken then
				offset, count = unpack( self._offsets['broken'] )
				self:setUVTransform( self._wallUVs.broken )
			end
		end

		if self.lock1 then
			local orientation = self._boardRig._game:getCamera():getOrientation()

			self.lock1:setCurrentFacingMask( 2^((self.lock1._facing - orientation*2) % simdefs.DIR_MAX) )
			self.lock2:setCurrentFacingMask( 2^((self.lock2._facing - orientation*2) % simdefs.DIR_MAX) )

			if bMainFrameMode then
				self.lock1:setVisible(false)
				self.lock2:setVisible(false)
			elseif showClosed then
				self.lock1:setVisible(true)
				self.lock2:setVisible(true)
			else
				self.lock1:setVisible(false)
				self.lock2:setVisible(false)
			end

			if showLocked then
				self.lock1:setCurrentAnim( "idle" )
				self.lock2:setCurrentAnim( "idle" )
			else
				self.lock1:setCurrentAnim( "idle_unlocked" )
				self.lock2:setCurrentAnim( "idle_unlocked" )
			end			
		end	

	end

	local prop, mesh = self._prop, self._mesh
	mesh:setElementOffset( offset )
	mesh:setElementCount( count )
    prop:setVisible( count > 0 )
end

function door_rig:refresh( )
	self:refreshProp()
end

-----------------------------------------------------
-- Interface functions

return door_rig
