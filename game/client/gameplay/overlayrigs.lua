----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local rand = include( "modules/rand" )
local cdefs = include( "client_defs" )
local animmgr = include( "anim-manager" )
local serverdefs = include( "modules/serverdefs" )

---------------------------------------------------------------

local Overlay = class()

function Overlay:init( boardRig, anim, x, y, facing, orientation )
	local wx, wy = boardRig:cellToWorld( x, y )
	
	

	local prop = KLEIAnim.new()
	prop:setDebugName('Overlay')
	prop:bindBuild( KLEIResourceMgr.GetResource( 'data/anims/general/overlay_glow.abld' ) )
	prop:bindAnim(  KLEIResourceMgr.GetResource( 'data/anims/general/overlay_glow.adef' ) )
	prop:setCurrentSymbol( 'overlay' )
	prop:setCurrentAnim( anim )
	prop:setScl( 0.25, 0.25, 0.25 )
	prop:setBillboard( MOAIProp.FLAGS_QUASI_BILLBOARD )
	prop:setDepthTest( false )
	prop:setDepthMask( false )

	prop:setLoc( wx, wy )
	prop:setVisible( true )	
	prop:setCurrentFacingMask( 2^( ( facing - orientation*2 ) % 8 ) )
	prop:setRenderFilter( 'zone_1' )
	prop:setPiv( 0, 0 )
	prop:setBounds( 0, 0, 0, 1, 1, 1 )

	local layer = boardRig:getLayer( "overlay" )
	layer:insertProp( prop )

	self._boardRig = boardRig
	self._layer = layer
	self._x = x
	self._y = y
	self._wx = wx
	self._wy = wy
	self._facing = facing
	self._prop = prop
end

function Overlay:destroy( )
	self._layer:removeProp( self._prop )
end

function Overlay:refresh( )
end

local overlayrigs = class()

function overlayrigs:init_cell_dst( )
	self._cells = { {} }
	local boardRig, cells = self._boardRig, self._cells
	local w, h = boardRig:getSim():getBoardSize()
	local todo = {}
	for x=1,w do
		for y=1,h do
			local cell = boardRig:getClientCellXY( x, y )
			if cell then
				if next(cell:getSides()) or x == 1 or x == w or y == 1 or y == h then
					cells[1][ x + y*w ] = 1
				else
					table.insert( todo, x + y*w )
				end
			end
		end
	end
	self:calc_cell_dst( todo, 1, w, 1, h )
end
function overlayrigs:updt_cell_dst( l, r, t, b )
	local boardRig, cells = self._boardRig, self._cells
	local w, h = boardRig:getSim():getBoardSize()
	l,r,t,b = math.max(l,1), math.min(r,w), math.max(t,1), math.min(b,h)
	local todo = {}
	for x=l,r do
		for y=t,b do
			if boardRig:getClientCellXY( x, y ) then
				for i=2,#cells do
					cells[i][ x + y*w] = nil
				end
				if not cells[1][ x + y*w ] then
					table.insert( todo, x + y*w )
				end
			end
		end
	end
	self:calc_cell_dst( todo, l, r, t, b )
end
function overlayrigs:calc_cell_dst( todo, l, r, t, b )
	local boardRig, cells = self._boardRig, self._cells
	local w, h = boardRig:getSim():getBoardSize()
	l,r,t,b = math.max(l,1), math.min(r,w), math.max(t,1), math.min(b,h)
	local i = 1
	while next(todo) do
		cells[i+1] = cells[i+1] or {}
--		print(i, util.tcount(todo) )
		local k, idx = next(todo)
		while k do
			if cells[i][idx-w-1] or
			   cells[i][idx-w+0] or
			   cells[i][idx-w+1] or
			   cells[i][idx+0-1] or
			   cells[i][idx+0+1] or
			   cells[i][idx+w-1] or
			   cells[i][idx+w+0] or
			   cells[i][idx+w+1] then
				todo[k] = nil
				cells[i+1][idx] = i+1
			end
			k, idx = next(todo, k)
		end
		i = i + 1
	end
	for i=#cells,2,-1 do
		if next( cells[i] ) then
			return
		end
		cells[i] = nil
	end
end

function overlayrigs:init( boardRig, levelData )

	self._boardRig = boardRig
	self._rand = rand.createGenerator( boardRig._game.params.seed )
	self._cells = {}
	self._overlays = {}

    local corpData = serverdefs.CORP_DATA[ boardRig._game.params.world ]
    if not corpData then
        return
    end

    local BLOB_CLASSES = corpData.overlayBlobStyles

	local w, h = boardRig:getSim():getBoardSize()

	self:init_cell_dst( )

	-- [[
	local blob_count = math.max(w,h)
	local CC = #self._cells
	for i=1,blob_count do
		local classIdx = 1
		local selectedSize = BLOB_CLASSES[classIdx].size
		for k,v in pairs(BLOB_CLASSES) do
			if (v.size <= CC) and (v.size > selectedSize) then
				classIdx, selectedSize = k, v.size
			end
		end
		local x, y, d, t = self:randXYgeD( selectedSize )
		if x and y and d then
			--print( 'ge', i, #self._overlays, x, y, d, t, selectedSize, CC )
			do
				local q = 3
				local lines = self:circleLines( q )
				for k,v in pairs( lines ) do
					for j=v.m,v.M do
						local x,y = j+x, k+y
						if boardRig:getClientCellXY( x, y ) then
							self._cells[1][ x + y*w ] = 1
						end
					end
				end
				self:updt_cell_dst( x-q-CC, x+q+CC, y-q-CC, y+q+CC )
			end
			CC = #self._cells
			
			local selected_class = BLOB_CLASSES[classIdx]
			local idx = self._rand:nextInt( 1, #selected_class.anims )
			local anim = selected_class.anims[ idx ]

			local facing = 0
			local orientation = 0
			local overlay = Overlay( boardRig, anim, x, y, facing, orientation )

			table.insert( self._overlays, overlay )
		end
	end
	--]]
end

function overlayrigs:circleLines( r )
	local x,y = r,0
	local dx = 1 - 2*r
	local dy = 0
	local e = 0
	local lines = {}

	while x >= y do
		lines[ y] = lines[ y] and {m=math.min(lines[ y].m, -x), M=math.max(lines[ y].M, x)} or {m=-x,M=x}
		lines[-y] = lines[-y] and {m=math.min(lines[-y].m, -x), M=math.max(lines[-y].M, x)} or {m=-x,M=x}
		lines[ x] = lines[ x] and {m=math.min(lines[ x].m, -y), M=math.max(lines[ x].M, y)} or {m=-y,M=y}
		lines[-x] = lines[-x] and {m=math.min(lines[-x].m, -y), M=math.max(lines[-x].M, y)} or {m=-y,M=y}
				
		y = y + 1
		e = e + dy
		dy = dy + 2
		if 2*e + dx > 0 then
			x = x - 1
			e = e + dx
			dx = dx + 2
		end
	end

	return lines
end

function overlayrigs:randXYeqD( D )
	local w, h = self._boardRig:getSim():getBoardSize()
	local cells = self._cells
	local indices = {}
	for k,v in pairs( cells[D] or {} ) do
		table.insert( indices, k )
	end
	if #indices > 0 then
		local i = self._rand:nextInt( 1, #indices )
		local I = indices[ i ]
		local x = (I-1) % w + 1
		local y = (I - x) / w
		return x, y, D, #indices
	end	
end

function overlayrigs:randXYgeD( D )
	local w, h = self._boardRig:getSim():getBoardSize()
	local cells = self._cells
	local indices = {}
	for d=D,#cells do
		for k,v in pairs( cells[d] ) do
			table.insert( indices, {k,d} )
		end
	end
	if #indices > 0 then
		local i = self._rand:nextInt( 1, #indices )
		local I = indices[i][1]
		local x = (I-1) % w + 1
		local y = (I - x) / w
		return x, y, indices[i][2], #indices
	end
end

function overlayrigs:randXY()
	local w, h = self._boardRig:getSim():getBoardSize()
	local cells = self._cells
	local try_count = 100
	while try_count > 0 do
		local x, y = self._rand:nextInt(1, w), self._rand:nextInt(1, h)
		local d
		for i=2,#cells do
			d = d or cells[i][ x + y*w ]
		end
		if d then return x,y,d,101-try_count end
		try_count = try_count - 1
	end
end

function overlayrigs:destroy()
	for k,v in pairs( self._overlays ) do
		v:destroy()
	end
	self._overlays = nil
	self._cells = nil
end

function overlayrigs:refresh( )
end


-----------------------------------------------------
-- Interface functions

return overlayrigs