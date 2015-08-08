----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local rand = include( "modules/rand" )
local animmgr = include( "anim-manager" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local logger = include( "logger" )
---------------------------------------------------------------

local VIS_NONE = 0
local VIS_FOW = 1
local VIS_CURRENT = 2



local function skinDecor( sim, rnd, decorInfo )
	local kanimName
	if decorInfo.skin then
		kanimName = animmgr.lookupAnimSkin( decorInfo.skin, rnd:nextInt( 1, 2^32 ) )
	else
		kanimName = decorInfo.kanim
	end

    local animdef = animmgr.lookupAnimDef( kanimName )
    if animdef == nil then
        return false
    end
    if animdef.boundType >= 3 and animdef.boundType <= 7 then
        local cells = animmgr.getPropCellCoverage( animdef, decorInfo.facing )
	    for i = 1, #cells do
            local dx, dy = cells[i][1], cells[i][2]
            local cell = sim:getCell( decorInfo.x + dx, decorInfo.y + dy )
            local dir = simquery.getReverseDirection( decorInfo.facing ) -- interested in the exit opposite what the decor is facing.
            if not cell then
                return
            elseif cell.exits[ dir ] and cell.exits[ dir ].door then
                return -- Suppress decor where doors are.
            end
        end
	end

    return kanimName
end


---------------------------------------------------------------
--

local Decore = class()

function Decore:init( boardRig, decorInfo, kanimName, orientation )	
	local x, y = decorInfo.x, decorInfo.y
	local facing = decorInfo.facing
	local wx, wy = boardRig:cellToWorld( x, y )
	local prop, animdef = animmgr.createPropFromAnimDef( kanimName )
    self.name = kanimName
	prop:setShadowMap( boardRig._game.shadow_map )
	prop:setLoc( wx, wy )
	prop:setCurrentAnim( "idle" )
	prop:setCurrentSymbol( "character" )
	prop:setVisible( false )
	prop:setCurrentFacingMask( 2^( ( facing - orientation*2 ) % 8 ) )

	if animdef.setlayer == "floor" then
		prop:setPeriphery( "data/images/los_full.png", "data/images/los_partial.png", "data/images/los_full_cover.png", "data/images/los_partial_cover.png" )
		prop:setRenderFilter( { shader=KLEIAnim.SHADER_FLOOR } )
	end
	local layer = boardRig:getLayer(animdef.setlayer)
	layer:insertProp( prop )

	self._boardRig = boardRig
	self._layer = layer
	self._x = x
	self._y = y
	self._facing = facing
	self._prop = prop
	self._animdef = animdef
	self._optional = (animdef.boundType >= 3) and (animdef.boundType <= 7) and not animdef.nonOptional
	self._cells = animmgr.getPropCellCoverage( self._animdef, self._facing )
	for i = 1, #self._cells do
		local cell = self._cells[i]
		cell[1], cell[2], cell[3] = cell[1] + x, cell[2] + y, VIS_NONE
	end
end

function Decore:getCells()
	return self._cells
end

function Decore:destroy( )
	self._layer:removeProp( self._prop )
end

function Decore:disableFocus()
	local uniforms = self._prop:getShaderUniforms()
	uniforms:setUniformVector3( "FocusRegion", 0.0, 0.0, 0.0 )
	uniforms:setUniformVector4( "FocusA", 1.0, 1.0, 1.0, 1.0 )
	uniforms:setUniformVector4( "FocusB", 1.0, 1.0, 1.0, 1.0 )
end

function Decore:enableFocus( xc, dx0, dx1 )
	local uniforms = self._prop:getShaderUniforms()
	uniforms:setUniformVector3( "FocusRegion", xc, dx0, dx1 )
	uniforms:setUniformVector4( "FocusA", 0.5, 0.5, 0.5, 0.5 )
	uniforms:setUniformVector4( "FocusB", 1.0, 1.0, 1.0, 1.0 )
end

function Decore:refreshVisibility( cellx, celly, visStatus )
	local currentVis = VIS_NONE
	for i = 1, #self._cells do
		local x, y = self._cells[i][1], self._cells[i][2]
		if x == cellx and y == celly then
			self._cells[i][3] = visStatus
		end
		currentVis = math.max( currentVis, self._cells[i][3] )
	end

	local gfxOptions = self._boardRig._game:getGfxOptions()
	local short_walls_active = gfxOptions.bShortWallMode and not gfxOptions.bMainframeMode and not gfxOptions.bTacticalView

	if currentVis == VIS_NONE or (self._optional and (not gfxOptions.enableOptionalDecore or short_walls_active)) then
		self._prop:setVisible( false )
	else
		self._prop:setVisible( true )
		if self._animdef.setlayer == "floor" then
			self._prop:setRenderFilter( { shader=KLEIAnim.SHADER_FLOOR } )
		elseif not self._animdef.nonOptional then
			self._prop:setRenderFilter( cdefs.RENDER_FILTERS[ 'shadowlight' ] )
		end
	end

	return currentVis ~= VIS_NONE
end

function Decore:refresh( orientation, gfxOptions )
	local prop = self._prop
	local facing = self._facing
	prop:setCurrentFacingMask( 2^(( facing - orientation*2 ) % 8) )

	if gfxOptions.bMainframeMode then
		prop:setCurrentAnim( "idle_icon" )
		prop:setRenderFilter( cdefs.RENDER_FILTERS[ 'default' ] )
	elseif gfxOptions.bTacticalView then
		prop:setCurrentAnim( "idle_tac" )
		prop:setRenderFilter( cdefs.RENDER_FILTERS[ 'default' ] )
	else
		prop:setCurrentAnim( "idle" )
	end
	
	local count = 0
	for i = 1, #self._cells do
		local x, y = self._cells[i][1], self._cells[i][2]
		local cellviz = self._boardRig:getClientCellXY( x, y )
        if cellviz == nil then
            log:write( "NO CELL VIZ AT: %d, %d for decor %s", x, y, self.name )
            return
        end
		for simDir,sideType in pairs(cellviz:getSides()) do
			local orientedFacing = (simDir - orientation*2) % 8
			if not sideType.door then
				if (orientedFacing == simdefs.DIR_E or orientedFacing == simdefs.DIR_N) then
					count = count + 2
				else
					count = count - 1
				end
			end
		end
	end

	local dx, dy = animmgr.refreshPropPivot( prop, self._animdef, facing, orientation, count <= 0 )
	local wx, wy = self._boardRig:cellToWorld( self._x + dx, self._y + dy )
	prop:setLoc( wx, wy )
end




local decorig = class()

function decorig:init( boardRig, levelData, params )
	self._boardRig = boardRig
	self._cells = {}
	self._decos = {}
	self._rnd = rand.createGenerator( params.seed )

	local orientation = boardRig._game:getCamera():getOrientation()

	for i,decorInfo in ipairs( levelData.decos ) do
	    self:createDeco(boardRig, decorInfo, orientation) 
    end
end

function decorig:createDeco(boardRig, decorInfo, orientation)

  	local kanimName = skinDecor( boardRig._game.simCore, self._rnd, decorInfo )
    if kanimName then
		local decor = Decore( boardRig, decorInfo, kanimName, orientation )		
		local localCells = decor:getCells()
		for i = 1, #localCells do
			local x, y = localCells[i][1], localCells[i][2]
			local cellid = simquery.toCellID( x, y )
			if self._cells[ cellid ] == nil then
			   self._cells[ cellid ] = { x = x, y = y }
			end
			table.insert( self._cells[ cellid ], decor )
		end 

		table.insert( self._decos, decor )
	end
end

function decorig:queryCellDecorFocusList( x, y )
	local dx, dy = self._boardRig._game:getCamera():orientVector(1,1)
	local focusRegion = {
	--			 {x, y, height_cut_off}
		[1] = { x+1*dx, y+0*dy, 1 },
		[2] = { x+2*dx, y+0*dy, 2 },
		[3] = { x+0*dx, y+1*dy, 1 },
		[4] = { x+1*dx, y+1*dy, 2 },
		[5] = { x+2*dx, y+1*dy, 3 },
		[6] = { x+0*dx, y+2*dy, 2 },
		[7] = { x+1*dx, y+2*dy, 3 },
		[8] = { x+2*dx, y+2*dy, 4 },
	}

	local cellid = simquery.toCellID( x, y )
	local decors = self._cells[ cellid ] or {}
	local excluded = {}
	for _,decor in ipairs( decors ) do
		excluded[decor] = true
	end

	local array = {}
	local included = {}
	for _,region in ipairs( focusRegion ) do
		local x, y, h = unpack( region )
		cellid = simquery.toCellID( x, y )
		decors = self._cells[ cellid ] or {}
		for _,decor in ipairs( decors ) do
			if not excluded[decor] and not included[decor] then
				included[decor] = true
				table.insert( array, decor )
			end
		end
	end
	return array
end

function decorig:setFocusCell( x, y )
	local wx0 = 0
	local wx2 = 0
	local dx1 = 0
	local dx0 = 0
	if x and y then
		local boardRig = self._boardRig
		wx0 = boardRig:cellToWnd( x, y )
		wx2 = boardRig:cellToWnd( x, y + 2 )
		dx1 = math.abs(wx2 - wx0)
		dx0 = dx1/2
	end

	if self._focusCell then
		if	self._focusCell[1] == x and
			self._focusCell[2] == y and
			self._focusCell[3] == wx0 and
			self._focusCell[4] == dx0 and
			self._focusCell[5] == dx1 then
			return
		end
		local decors = self:queryCellDecorFocusList( unpack(self._focusCell) )
		for _,decor in ipairs( decors ) do
			decor:disableFocus()
		end
		self._focusCell = nil
	end
	if not x or not y then
		return
	end

	self._focusCell = {x,y,wx0,dx0,dx1}

	local decors = self:queryCellDecorFocusList( x, y )
	for _,decor in ipairs( decors ) do
		decor:enableFocus( wx0, dx0, dx1 )
	end
end

function decorig:refreshCell( x, y )
	local cellid = simquery.toCellID( x, y )
	local decors = self._cells[ cellid ]
	if decors then
		local gfxOptions = self._boardRig._game:getGfxOptions()
		local orientation = self._boardRig._game:getCamera():getOrientation()
		local cell = self._boardRig:getLastKnownCell( x, y )
		local visStatus = VIS_NONE

		if cell and not cell.ghostID then
			visStatus = VIS_CURRENT
		elseif cell then
			visStatus = VIS_FOW
		end

		for i,decor in ipairs( decors ) do
			if decor:refreshVisibility( x, y, visStatus ) then
				decor:refresh( orientation, gfxOptions )
			end
		end
	end
end

function decorig:refresh( )
	for _, decors in pairs( self._cells ) do
		self:refreshCell( decors.x, decors.y )
	end
end

function decorig:destroy()
	for _, decor in pairs( self._decos ) do
		decor:destroy()
	end

	self._cells = nil
	self._decors = nil
end


-----------------------------------------------------
-- Interface functions

return decorig