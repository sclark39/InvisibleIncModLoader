----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local mui_defs = include("mui/mui_defs")
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local simdefs = include( "sim/simdefs" )

local STATE_NULL = 0
local STATE_PANNING = 1

local ZOOM_FACTOR = 0.1
local ZOOM_MIN = 0.25  --0.05
local ZOOM_MAX = 1.1  -- 4

local function getEdgePanParams()
    local settings = savefiles.getSettings( "settings" )
    local EDGEPAN_BUFFERX = 40
    local EDGEPAN_BUFFERY = 30
    local EDGEPAN_SPEED = 0.4 -- Factor that determines edge panning speed, bigger is faster.

    local bufferX = math.max( 0, EDGEPAN_BUFFERX * settings.data.edgePanDist )
    local bufferY = math.max( 0, EDGEPAN_BUFFERY * settings.data.edgePanDist )
    local panSpeed = math.max( 0, EDGEPAN_SPEED * settings.data.edgePanSpeed )

    return bufferX, bufferY, panSpeed
end

local camhandler = class()

function camhandler:init( layer, game )

	local camera = MOAICamera.new ()
	
	--MOAIGfxDevice.setClearDepth( true )
	
	self._game = game
	self._ortho = false
	self._layer = layer
	self._camera = camera
	self._state = STATE_NULL
	self._panStartX = nil
	self._panStartY = nil
	self._lockProp = nil
	self._disabled = false
	self._orientation = 0
	self._targetX = 0
	self._targetY = 0
	self._targetZ = 0
	self._targetZoom = 1

	self:snapOrientation(0)
	self:setOrtho( true )
	self:enableEdgePan( VIEWPORT_IS_FULLSCREEN )

	for _,layer in pairs( game.layers ) do
		layer:setCamera( self._camera )
	end

	local xform = MOAITransform.new()
	xform:setRot( 0, 0, self._orientation * -90 )
	self._layer:setSortTransform( xform )
end

function camhandler:destroy()
    if self._state == STATE_PANNING then
        inputmgr.removeListener( self )
    end

	if self._orientEaser then
		self._orientEaser:stop()
		self._orientEaser = nil
	end
	if self._orientTimer then
		self._orientTimer:stop()
		self._orientTimer = nil
	end
end

function camhandler:zoom( factor, x0, y0 )

	self._camera:forceUpdate()

	local wx, wy, wz
	if x0 and y0 then
		wx, wy, wz = self._layer:worldToWnd( x0, y0, 0 )
	end

    if config.DBG_CAM then
    	self._targetZoom = math.max( 0.02, math.min( 4, self._targetZoom + self._targetZoom * factor ))
    else
    	self._targetZoom = math.max( ZOOM_MIN, math.min( ZOOM_MAX, self._targetZoom + self._targetZoom * factor ))
    end

    self._targetEase, self._lastMemento = nil, nil
	--self._camera:setScl( self._targetZoom, self._targetZoom, self._targetZoom )

	-- If specified, we want to zoom such that the world coordinates x0, y0 is invariant (maps to the same window coordinates)
	if wx and wy then
		self._camera:forceUpdate()
		local x1, y1, z1 = self._layer:wndToWorld( wx, wy, wz )
		self._targetX = self._targetX + (x0 - x1)
		self._targetY = self._targetY + (y0 - y1)
		self._targetZ = self._targetZ + ( 0 - z1)
		self._camera:setLoc( self._targetX, self._targetY, self._targetZ )
	end
end

function camhandler:zoomTo( targetZoom )
	if self:isManualCam() then
		return
	end

	self._camera:forceUpdate()
    if not config.DBG_CAM then
    	self._targetZoom = math.max( ZOOM_MIN, math.min( ZOOM_MAX, targetZoom ))
    end
    self._targetEase, self._lastMemento = nil, nil
end

function camhandler:getZoom()
	return self._targetZoom
end

function camhandler:centerTwoPoints( x0,y0,x1,y1 )
	local x, y, z = self._camera:getLoc()
	local sx = self._camera:getScl()

	local targetX = (x0 + x1) /2
	local targetY = (y0 + y1) /2

	local FIT_BUFFER = 0.25
	local VIEW_MINX, VIEW_MAXX, VIEW_MINY, VIEW_MAXY = VIEWPORT_WIDTH * FIT_BUFFER, VIEWPORT_WIDTH * (1-FIT_BUFFER), VIEWPORT_HEIGHT * FIT_BUFFER, VIEWPORT_HEIGHT * (1-FIT_BUFFER)
	local xmin, xmax, ymin, ymax = math.huge, -math.huge, math.huge, -math.huge

	-- points in the world of the inset window box based on the current zoom
	local p0x,p0y = self._layer:wndToWorld( VIEW_MINX, VIEW_MINY, 0 )
	local p1x,p1y = self._layer:wndToWorld( VIEW_MAXX, VIEW_MINY, 0 )
	local p2x,p2y = self._layer:wndToWorld( VIEW_MINX, VIEW_MAXY, 0 )

	-- world distance of window box at current zoom
	local worldX1 = math.abs(p0x - p1x)
	local worldY1 = math.abs(p0y - p2y)

	-- world distance of targets
	local worldX0 = math.abs(x0-x1)
	local worldY0 = math.abs(y0-y1)	

	-- inset window dimensions
	local winX1 = VIEW_MAXX - VIEW_MINX
	local winY1 = VIEW_MAXY - VIEW_MINY

	-- factor of the zoom
	local xFactor = worldX1/(winX1*self._targetZoom)
	local yFactor = worldY1/(winY1*self._targetZoom)

	--find what zoom is needed useing the factor
	local newZoomX =  worldX0/(winX1 * xFactor)
	local newZoomY =  worldY0/(winY1 * yFactor)

	-- choose the zoom level from the X and Y zooms
	local targetZoom =  math.max( ZOOM_MIN, math.min( ZOOM_MAX,  math.min(newZoomX,newZoomY)  ))    

	self._targetZoom = targetZoom 
    self._targetEase, self._lastMemento = nil, nil
	self._targetX, self._targetY = targetX, targetY
end

function camhandler:fitToPoints( ... )
	local x, y, z = self._camera:getLoc()
	local sx = self._camera:getScl()

	local FIT_BUFFER = 0.33
	local VIEW_MINX, VIEW_MAXX, VIEW_MINY, VIEW_MAXY = VIEWPORT_WIDTH * FIT_BUFFER, VIEWPORT_WIDTH * (1-FIT_BUFFER), VIEWPORT_HEIGHT * FIT_BUFFER, VIEWPORT_HEIGHT * (1-FIT_BUFFER)
	local xmin, xmax, ymin, ymax = math.huge, -math.huge, math.huge, -math.huge
	for i = 1, select( "#", ... ), 2 do
		local x, y = select( i, ... )
		local wx, wy = self._layer:worldToWnd( x, y )
		xmin, xmax = math.min( xmin, wx ), math.max( xmax, wx )
		ymin, ymax = math.min( ymin, wy ), math.max( ymax, wy )
	end

	-- Discover necessary zoom to fit all points.
	local targetZoom = 1
	if xmax - xmin > VIEW_MAXX - VIEW_MINX then
		targetZoom = math.max( (xmax - xmin) / (VIEW_MAXX - VIEW_MINX), targetZoom )
	end
	if ymax - ymin > VIEW_MAXY - VIEW_MINY then
		targetZoom = math.max( (ymax - ymin) / (VIEW_MAXY - VIEW_MINY), targetZoom )
	end

	-- Discover minimum translation needed to fit all points, given required zoom.
	local tx, ty = 0, 0
	local zoomWidth, zoomHeight = VIEWPORT_WIDTH * targetZoom - VIEWPORT_WIDTH, VIEWPORT_HEIGHT * targetZoom - VIEWPORT_HEIGHT
	for i = 1, select( "#", ... ), 2 do
		local x, y = select( i, ... )
		local wx, wy = self._layer:worldToWnd( x, y )
		if wx < VIEW_MINX - zoomWidth / 2 then
			tx = math.min( tx, wx - (VIEW_MINX - zoomWidth / 2))
		elseif wx > VIEW_MAXX + zoomWidth / 2 then
			tx = math.max( tx, wx - (VIEW_MAXX + zoomWidth / 2))
		end
		if wy < VIEW_MINY - zoomHeight / 2 then
			ty = math.min( ty, wy - (VIEW_MINY - zoomHeight / 2))
			--log:write("ITS ABOVE; %.2f < %2f, z=%.2f (%.2f, %.2f)", wy, VIEW_MINY - zoomHeight / 2, targetZoom, select(i, ...) )
		elseif wy > VIEW_MAXY + zoomHeight / 2 then
			ty = math.max( ty, wy - (VIEW_MAXY + zoomHeight / 2))
			--log:write("ITS BELOW; %.2f > %2f, z=%.2f (%.2f, %.2f)", wy, VIEW_MAXY + zoomHeight / 2, targetZoom, select(i, ...) )
		end
	end
	local targetX, targetY = self._layer:wndToWorld2D( (VIEWPORT_WIDTH) / 2 + tx, (VIEWPORT_HEIGHT) / 2 + ty )
	return sx * targetZoom, targetX, targetY
end

function camhandler:fitOnscreen( ... )
	if self:isManualCam() then
		return
	end
	self._targetZoom, self._targetX, self._targetY = self:fitToPoints( ... )
    self._targetEase, self._lastMemento = nil, nil
end

function camhandler:fitOnscreenNoZoom( ... )
	if self:isManualCam() then
		return
	end
    local targetZoom, targetX, targetY = self:fitToPoints( ... )
    self._targetX, self._targetY  = targetX, targetY
    self._targetEase, self._lastMemento = nil, nil
end

function camhandler:isOnscreen( prop )
	return self._layer:isOnscreen( prop )
end

function camhandler:panTo( x, y, z )
	if self:isManualCam() then
		return
	end

	self:lockTo( nil )
	self._targetX, self._targetY, self._targetZ = x or self._targetX, y or self._targetY, z or self._targetZ
    self._targetEase, self._lastMemento = nil, nil
end

function camhandler:warpTo( x, y, z )
	self:lockTo( nil )
	self._targetX, self._targetY, self._targetZ = x or self._targetX, y or self._targetY, z or self._targetZ
    self._targetEase, self._lastMemento = nil, nil
	self:updateConstraints()
	self._camera:setLoc( self._targetX, self._targetY, self._targetZ )
end

function camhandler:lockTo( prop )
	if self:isManualCam() then
		return
	end

	self._lockProp = prop
end

function camhandler:updateConstraints()
	local boardWidth, boardHeight = self._game.simCore:getBoardSize()
	local minx, miny = -boardWidth/1.75 * cdefs.BOARD_TILE_SIZE, -boardHeight/1.75 * cdefs.BOARD_TILE_SIZE
	local maxx, maxy = boardWidth/1.75 * cdefs.BOARD_TILE_SIZE, boardHeight/1.75 * cdefs.BOARD_TILE_SIZE
			
	self._targetX = math.max( minx, math.min( maxx, self._targetX ))
	self._targetY = math.max( miny, math.min( maxy, self._targetY ))
end

function camhandler:getOrientation()
	return self._orientation
end

function camhandler:orientVector( dx, dy )
	if self._orientation == 0 then
		return  dx, dy
	elseif self._orientation == 1 then
		return -dy, dx
	elseif self._orientation == 2 then
		return -dx, -dy
	elseif self._orientation == 3 then
		return  dy, -dx
	end
end

function camhandler:orientDirection( direction )
	direction = direction + self._orientation * 2
	return direction % simdefs.DIR_MAX
end

function camhandler:snapOrientation( orientation )
	if self._orientEaser then
		self._orientEaser:stop()
		self._orientEaser = nil
	end
	if self._orientTimer then
		self._orientTimer:stop()
		self._orientTimer = nil
	end

	self._orientation = orientation % 4
	
	--angle = 45 or 135 or 225 or 315
	local x = 55.150095420953515588519482280099
	local y = 0
	local z = (orientation*90 + 45 + 90 ) % 360
	self._camera:setRot( x, y, z )

	local xform = MOAITransform.new()
	xform:setRot( 0, 0, orientation * -90 )
	self._layer:setSortTransform( xform )

	local x = 0.85084252988186
	local y = 0.52542077361314
	if self._orientation == 1 then
		x, y = -y, x
	elseif self._orientation == 2 then
		x, y = -x, -y
	elseif self._orientation == 3 then
		x, y = y, -x
	end
	MOAIGfxDevice.setLightDirection( x, y )	
end

function camhandler:rotateOrientation( orientation )
	local time = 0.25
	if orientation == nil then
		-- No orientation specified, then do a rotate effect to the current orientation.
		orientation = self._orientation
		self:snapOrientation( (self._orientation - 1) % 4 )
	end

	orientation = orientation % 4

	if self._orientation == orientation then
		return
	end

	KLEIRenderScene:pulseUIFuzz( time )	

	local _x, _y, _z = self._camera:getRot()
	
	--angle = 45 or 135 or 225 or 315
	local x = 55.150095420953515588519482280099
	local y = 0
	local z = (orientation*90 + 45 + 90 ) % 360
	
	local postSnap = false
	if _z - z < -180 then
		z = z - 360
		postSnap = true
	elseif _z - z > 180 then
		z = z + 360
		postSnap = true			
	end

	if self._orientEaser then
		self._orientEaser:stop()
	end
	self._orientEaser = self._camera:seekRot( x, y, z, time, MOAIEaseType.SOFT_SMOOTH  )
	
	local function setSortXForm( timer, executed )
		if executed == 0 then
			self._orientation = orientation
			local xform = MOAITransform.new()
			xform:setRot( 0, 0, orientation * -90 )
			self._layer:setSortTransform( xform )

			local x = 0.85084252988186
			local y = 0.52542077361314
			if self._orientation == 1 then
				x, y = -y, x
			elseif self._orientation == 2 then
				x, y = -x, -y
			elseif self._orientation == 3 then
				x, y = y, -x
			end
			MOAIGfxDevice.setLightDirection( x, y )
			if self._game and self._game.boardRig then
				self._game.boardRig:refresh()
			end
		else
			if postSnap then
				self:snapOrientation( orientation )
			end
			timer:stop()
		end
	end

	if self._orientTimer then
		self._orientTimer:stop()
	end
	local timer = MOAITimer.new ()
	timer:setSpan ( time/2 )
	timer:setMode ( MOAITimer.LOOP )
	timer:setListener ( MOAITimer.EVENT_TIMER_END_SPAN, setSortXForm )	
	timer:start()
	self._orientTimer = timer

--[[	
		local wndx, wndy = inputmgr.getMouseXY() 
		local width,height = MOAIGfxDevice.getViewSize()	
		MOAISim.setFocus( wndx, height - wndy, 128, 2/3 )
		local x0, y0 = self._layer:wndToWorld2D( wndx, wndy )
		local x1, y1 = self._game.boardRig:worldToCell( x0, y0 )
		self._game.boardRig:setFocusCell( x1, y1 )
		]]
end

function camhandler:onInputEvent( event )
	if self._disabled then
		return
	end

	if event.eventType == mui_defs.EVENT_MouseMove then
		local width,height = MOAIGfxDevice.getViewSize()	
		MOAISim.setFocus( event.wx, height - event.wy, 128, 2/3 )

		local x0, y0 = self._layer:wndToWorld2D( event.wx, event.wy )
		local x1, y1 = self._game.boardRig:worldToCell( x0, y0 )
		self._game.boardRig:setFocusCell( x1, y1 )
	end

	if event.eventType == mui_defs.EVENT_KeyUp then
		if event.key == mui_defs.K_BACKSPACE and not event.controlDown then
			self:snapOrientation( self._orientation )
			self:panTo( 0, 0, self._targetZ)
			return true

		elseif event.key == mui_defs.K_MINUS then
			self:zoom( -ZOOM_FACTOR, 0, 0 )	
			return true

		elseif event.key == mui_defs.K_PLUS then
			self:zoom( ZOOM_FACTOR, 0, 0 )		
			return true
		end

	elseif event.eventType == mui_defs.EVENT_MouseWheel then
			local x0, y0 = self._layer:wndToWorld2D( event.wx, event.wy )
			self:zoom( -event.delta * ZOOM_FACTOR, x0, y0 )		

	elseif self._state == STATE_NULL then
		if event.eventType == mui_defs.EVENT_MouseDown and event.button == mui_defs.MB_Left then
			self._panStartX, self._panStartY = event.wx, event.wy
			self._state = STATE_PANNING
			mui.updateTooltip( nil )
			inputmgr.addListener( self, 1 ) -- Ensure we trap mouse input for the duration of the pan, so its not intercepted by other UI.
		elseif self._enableEdgePan then
            local bufferX, bufferY, panSpeed = getEdgePanParams()
            if event.eventType == mui_defs.EVENT_MouseMove then
                local currentTimerTick = MOAISim.getElapsedTime()
                local lastTimerTick = self._lastTimerTick or currentTimerTick
                self._lastTimerTick = currentTimerTick
                if lastTimerTick ~= currentTimerTick then
			        if event.wx < bufferX then
				        local x0, y0 = self._layer:wndToWorld2D( math.max(0, event.wx), event.wy )
				        local x1, y1 = self._layer:wndToWorld2D( bufferX, event.wy )
				        self:warpTo( self._targetX + (x0 - x1) * panSpeed, self._targetY + (y0 - y1) * panSpeed)
			        elseif event.wx > VIEWPORT_WIDTH - bufferX then
				        local x0, y0 = self._layer:wndToWorld2D( math.min(VIEWPORT_WIDTH, event.wx), event.wy )
				        local x1, y1 = self._layer:wndToWorld2D( VIEWPORT_WIDTH - bufferX, event.wy )
				        self:warpTo( self._targetX + (x0 - x1) * panSpeed, self._targetY + (y0 - y1) * panSpeed)
			        elseif event.wy < bufferY then
				        local x0, y0 = self._layer:wndToWorld2D( event.wx, math.max(0, event.wy) )
				        local x1, y1 = self._layer:wndToWorld2D( event.wx, bufferY )
				        self:warpTo( self._targetX + (x0 - x1) * panSpeed, self._targetY + (y0 - y1) * panSpeed)
			        elseif event.wy > VIEWPORT_HEIGHT - bufferY then
				        local x0, y0 = self._layer:wndToWorld2D( event.wx, math.min(VIEWPORT_HEIGHT, event.wy) )
				        local x1, y1 = self._layer:wndToWorld2D( event.wx, VIEWPORT_HEIGHT - bufferY )
				        self:warpTo( self._targetX + (x0 - x1) * panSpeed, self._targetY + (y0 - y1) * panSpeed)
			        end
                end
            end
		end

	elseif self._state == STATE_PANNING then
		if event.eventType == mui_defs.EVENT_MouseMove then
			if event.controlDown and config.DBG_CAM then				
				local x,y,z = self._camera:getRot()
				x = x - event.wy + self._panStartY
				z = z + event.wx - self._panStartX
				self._camera:setRot( x, y, z )
			else
				if self._ortho then
					local x0, y0 = self._layer:wndToWorld2D( self._panStartX, self._panStartY )
					local x1, y1 = self._layer:wndToWorld2D( event.wx, event.wy )
					if x0 ~= x1 or y0 ~= y1 then				
						self:warpTo( self._targetX + (x0 - x1), self._targetY + (y0 - y1) )
					end
				else
					local x0, y0 = self._panStartX, self._panStartY
					local x1, y1 = event.wx, event.wy

					if x0 ~= x1 or y0 ~= y1 then
						local xx,xy,xz,xw = self._camera:getXBasis()
						local yx,yy,yz,yw = self._camera:getYBasis()
						local zx,zy,zz,zw = self._camera:getZBasis()
						local wx,wy,wz,ww = self._camera:getWBasis()

						local dx = x1 - x0
						local dy = y0 - y1
						local dz = 0
						if event.altDown then
							dy,dz = dz,dy
						end

						local x = self._targetX + xx * dx + yx * dy + zx * dz
						local y = self._targetY + xy * dx + yy * dy + zy * dz
						local z = self._targetZ + xz * dx + yz * dy + zz * dz

						self:warpTo( x, y, z )
					end
				end
			end
			self._panStartX, self._panStartY = event.wx, event.wy
			return true

		elseif event.eventType == mui_defs.EVENT_MouseUp then
			self._state = STATE_NULL
			inputmgr.removeListener( self )
			-- if we return true, we sink this MouseUp entirely since the camera is first handler.
			-- The hud however would like to handle mouse up (for radial menu)
 			return false
		end
	end
end

function camhandler:onUpdate()
	self._camera:forceUpdate()
	local x, y, z = self._camera:getLoc()
	local sx = self._camera:getScl()
	local modifierDown = inputmgr.keyIsDown( mui_defs.K_SHIFT ) or inputmgr.keyIsDown( mui_defs.K_CONTROL )

	if self._lockProp then
		local x, y = self._lockProp:getLoc()
		self._targetZoom, self._targetX, self._targetY = self:fitToPoints( x, y )
	end

	if not modifierDown then
		if util.isKeyBindingDown( "cameraPanL" ) or inputmgr.keyIsDown( mui_defs.K_LEFTARROW ) then
			local x0, y0 = self._layer:wndToWorld2D( 0, 0 )
			local x1, y1 = self._layer:wndToWorld2D( 10, 0 )
			self:warpTo( self._targetX + (x0 - x1), self._targetY + (y0 - y1) )
		elseif util.isKeyBindingDown( "cameraPanR" ) or inputmgr.keyIsDown( mui_defs.K_RIGHTARROW ) then
			local x0, y0 = self._layer:wndToWorld2D( 0, 0 )
			local x1, y1 = self._layer:wndToWorld2D( -10, 0 )
			self:warpTo( self._targetX + (x0 - x1), self._targetY + (y0 - y1) )
		end
		if util.isKeyBindingDown( "cameraPanU" ) or inputmgr.keyIsDown( mui_defs.K_UPARROW ) then
			local x0, y0 = self._layer:wndToWorld2D( 0, 0 )
			local x1, y1 = self._layer:wndToWorld2D( 0, 10 )
			self:warpTo( self._targetX + (x0 - x1), self._targetY + (y0 - y1) )
		elseif util.isKeyBindingDown( "cameraPanD" ) or inputmgr.keyIsDown( mui_defs.K_DOWNARROW ) then
			local x0, y0 = self._layer:wndToWorld2D( 0, 0 )
			local x1, y1 = self._layer:wndToWorld2D( 0, -10 )
			self:warpTo( self._targetX + (x0 - x1), self._targetY + (y0 - y1) )
		end
	end

	local EASE_FACTOR = 1/10 * (self._targetEase or 1)

	self:updateConstraints()

	x = mathutil.deltaApproach( x, self._targetX, EASE_FACTOR * (self._targetX - x))
	y = mathutil.deltaApproach( y, self._targetY, EASE_FACTOR * (self._targetY - y))
	z = mathutil.deltaApproach( z, self._targetZ, EASE_FACTOR * (self._targetZ - z))
	sx = mathutil.deltaApproach( sx, self._targetZoom, EASE_FACTOR * (self._targetZoom - sx))

	self._camera:setLoc( x, y, z )
	self._camera:setScl( sx, sx, sx )
    self._camera:forceUpdate()
end

function camhandler:getLoc()
	return self._camera:getLoc( )
end

function camhandler:setOrtho( ortho )
	if ortho and not self._ortho then
		self._ortho = true
		self._camera:setOrtho     (   true )
		self._camera:setFarPlane  (  10000 )
		self._camera:setNearPlane ( -10000 )
	elseif not ortho and self._ortho then
		self._ortho = false
		self._camera:setOrtho     (  false )
		self._camera:setFarPlane  (  10000 )
		self._camera:setNearPlane (      1 )
	end
end

function camhandler:disableControl( isDisabled )
	self._disabled = isDisabled
end

function camhandler:enableEdgePan( isEnabled )
	self._enableEdgePan = isEnabled
end

function camhandler:isManualCam()
    local settings = savefiles.getSettings( "settings" )
    return settings.data.manualCam or config.MANUAL_CAM
end

function camhandler:getMemento()
	return
	{
		targetX = self._targetX,
		targetY = self._targetY,
		targetZ = self._targetZ,
		targetZoom = self._targetZoom,
		orientation = self._orientation
	}
end

function camhandler:setMemento( memento )
	assert( memento.targetX and memento.targetY and memento.targetZ and memento.targetZoom and memento.orientation )
	self._targetX = memento.targetX
	self._targetY = memento.targetY
	self._targetZ = memento.targetZ
	self._targetZoom = memento.targetZoom
	self:snapOrientation( memento.orientation )
    self:lockTo( nil )
end

function camhandler:saveMemento( memento )
    -- Internally save camera state; can be restored with :restoreMemento() if a new camera target hasn't been specified in the meantime.
    self._lastMemento = memento
end

function camhandler:restoreMemento( targetEase )
    if self._lastMemento then
        self:setMemento( self._lastMemento )
        self._lastMemento = nil
        self._targetEase = targetEase
    end
end

return camhandler