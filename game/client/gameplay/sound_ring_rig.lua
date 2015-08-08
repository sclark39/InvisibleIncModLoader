----------------------------------------------------------------
-- Copyright (c) 2014 Klei Entertainment Inc.
-- All Rights Reserved.
-- Invisible Inc.
----------------------------------------------------------------

local resources = include( "resources" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
include("class")

local function createSoundRingMesh( radius )
	local r = radius

	local bresenham = {}
	table.insert( bresenham, {0,r} )
	local p = 5/4 - r

	local k, x, y = 0, 0, r
	while x < y do
		if p < 0 then
			x = x + 1
			p = p + 2*x + 1
		else
			x = x + 1
			y = y - 1
			p = p + 2*x + 1 - 2*y
		end
		table.insert( bresenham, {x,y} )
	end

	local B = #bresenham
	local b = B-1
	local octants =
	{--	[0] = { d,  j, k,   {x},      {y}
		[1] = { 1, 1, B, { 1, 0}, { 0, 1} },
		[2] = {-1, b, 1, { 0, 1}, { 1, 0} },
		[3] = { 1, 2, B, { 0, 1}, {-1, 0} },
		[4] = {-1, b, 1, { 1, 0}, { 0,-1} },
		[5] = { 1, 2, B, {-1, 0}, { 0,-1} },
		[6] = {-1, b, 1, { 0,-1}, {-1, 0} },
		[7] = { 1, 2, B, { 0,-1}, { 1, 0} },
		[8] = {-1, b, 2, {-1, 0}, { 0, 1} },
	}
	local cells = {}
	for o=1,8 do
		local l,j,k = octants[o][1], octants[o][2], octants[o][3]
		for i=j,k,l do
			local x = octants[o][4][1] * bresenham[i][1] + octants[o][4][2] * bresenham[i][2]
			local y = octants[o][5][1] * bresenham[i][1] + octants[o][5][2] * bresenham[i][2]
			if (#cells == 0) or not (cells[#cells][1] == x and cells[#cells][2] == y) and not (cells[1][1] == x and cells[1][2] == y) then
				table.insert( cells, {x,y,o} )
			end
		end
	end
	

	local dd = 0.4	--center of cell to displaced edge

	local points = {}

	--The origin f{0.0,0.0} is the center of the center i{0,0} pixel
	--Edge contains the clock-wise points of the rasterized circle starting from the top-middle position
	local nc = #cells
	for i=1,nc do
		local i0 = (i + nc - 2) % nc + 1
		local i1 = i
		local i2 = i % nc + 1

		local p0 = cells[ i0 ]
		local p1 = cells[ i1 ]
		local p2 = cells[ i2 ]

		local Ldx = p0[1] - p1[1]
		local Ldy = p0[2] - p1[2]

		local Rdx = p2[1] - p1[1]
		local Rdy = p2[2] - p1[2]

			if Ldx == -1 and Ldy ==  0 then	--     left
			table.insert( points, { p1[1] - dd, p1[2] + dd } )
			table.insert( points, { p1[1] + dd, p1[2] + dd } )
		elseif Ldx == -1 and Ldy ==  1 then	--  up-left
			table.insert( points, { p0[1] + dd, p1[2] + dd } )
			table.insert( points, { p1[1] - dd, p1[2] + dd } )
			table.insert( points, { p1[1] + dd, p1[2] + dd } )
		elseif Ldx ==  0 and Ldy ==  1 then	--  up
			table.insert( points, { p1[1] + dd, p1[2] + dd } )
			table.insert( points, { p1[1] + dd, p1[2] - dd } )
		elseif Ldx ==  1 and Ldy ==  1 then --  up-right
			table.insert( points, { p1[1] + dd, p0[2] - dd } )
			table.insert( points, { p1[1] + dd, p1[2] + dd } )
			table.insert( points, { p1[1] + dd, p1[2] - dd } )
		elseif Ldx ==  1 and Ldy ==  0 then --     right
			table.insert( points, { p1[1] + dd, p1[2] - dd } )
			table.insert( points, { p1[1] - dd, p1[2] - dd } )
		elseif Ldx ==  1 and Ldy == -1 then --down-right
			table.insert( points, { p0[1] - dd, p1[2] - dd } )
			table.insert( points, { p1[1] + dd, p1[2] - dd } )
			table.insert( points, { p1[1] - dd, p1[2] - dd } )
		elseif Ldx ==  0 and Ldy == -1 then --down
			table.insert( points, { p1[1] - dd, p1[2] - dd } )
			table.insert( points, { p1[1] - dd, p1[2] + dd } )
		elseif Ldx == -1 and Ldy == -1 then --down-left
			table.insert( points, { p1[1] - dd, p0[2] + dd } )
			table.insert( points, { p1[1] - dd, p1[2] - dd } )
			table.insert( points, { p1[1] - dd, p1[2] + dd } )
		else
			assert( false, 'unexpected L' )
		end

			if Rdx == -1 and Rdy ==  0 then	--     left
			table.insert( points, { p1[1] - dd, p1[2] - dd } )
		elseif Rdx == -1 and Rdy ==  1 then	--  up-left
			table.insert( points, { p1[1] - dd, p1[2] + dd } )
		elseif Rdx ==  0 and Rdy ==  1 then	--  up
			table.insert( points, { p1[1] - dd, p1[2] + dd } )
		elseif Rdx ==  1 and Rdy ==  1 then --  up-right
			table.insert( points, { p1[1] + dd, p1[2] + dd } )
		elseif Rdx ==  1 and Rdy ==  0 then --     right
			table.insert( points, { p1[1] + dd, p1[2] + dd } )
		elseif Rdx ==  1 and Rdy == -1 then --down-right
			table.insert( points, { p1[1] + dd, p1[2] - dd } )
		elseif Rdx ==  0 and Rdy == -1 then --down
			table.insert( points, { p1[1] + dd, p1[2] - dd } )
		elseif Rdx == -1 and Rdy == -1 then --down-left
			table.insert( points, { p1[1] - dd, p1[2] - dd } )
		else
			assert( false, 'unexpected R' )
		end

	end


	local vertexFormat = MOAIVertexFormat.new()
	vertexFormat:declareCoord	( 1, MOAIVertexFormat.GL_FLOAT, 2 )
	vertexFormat:declareUV		( 2, MOAIVertexFormat.GL_FLOAT, 2 )

	local p0 = {0,0}

	--print( 'sound_ring', radius )

	local vbo = MOAIVertexBuffer.new()
	vbo:setFormat( vertexFormat )
	vbo:reserveVerts( 3 * #points )
	for i,p1 in ipairs( points ) do
		local p2 = points[ i % #points + 1 ]

		--print( i-1, p1[1], p1[2] )

		vbo:writeFloat( p0[1],   p0[2] )
		vbo:writeFloat( p0[1]/(r+dd),   p0[2]/(r+dd) )

		vbo:writeFloat( p1[1],   p1[2] )
		vbo:writeFloat( p1[1]/(r+dd),   p1[2]/(r+dd) )

		vbo:writeFloat( p2[1],   p2[2] )
		vbo:writeFloat( p2[1]/(r+dd),   p2[2]/(r+dd) )
	end
	vbo:bless()

	local mesh = MOAIMesh.new()
	--mesh:setTexture( mt )
	mesh:setVertexBuffer( vbo )
	mesh:setPrimType( MOAIMesh.GL_TRIANGLES )
	--mesh:setElementOffset( 0 )
	--mesh:setElementCount( #points - 1 )

	return mesh
end

local soundRingMeshes = {}
local function getSoundRingMesh( radius )
	local mesh = soundRingMeshes[ radius ]
	if not mesh then
		mesh = createSoundRingMesh( radius )
		soundRingMeshes[ radius ] = mesh
	end
	return mesh
end

local sound_ring_rig = class()

function sound_ring_rig:init( boardRig, x, y, radius, life_span, color)

	local wx, wy = boardRig:cellToWorld( x, y )

	local mesh = getSoundRingMesh( radius )

	local prop = MOAIProp.new()
	prop:setDeck( mesh )
	prop:setDepthTest( false )
	prop:setDepthMask( false )
	prop:setCullMode( MOAIProp.CULL_NONE )
	prop:setBlendMode( MOAIProp.BLEND_ADD )
	prop:setLoc( wx, wy )
	prop:setScl( cdefs.BOARD_TILE_SIZE, cdefs.BOARD_TILE_SIZE )
	prop:setShader( MOAIShaderMgr.getShader( MOAIShaderMgr.SOUNDRING_SHADER ) )

	self._boardRig = boardRig
	self._prop = prop
	self._lifeSpan = life_span
	self._startTime = MOAISim.getElapsedTime()
	self._radialSpan = 1/radius
	self._x = x
	self._y = y
	self._color = color or {140/255, 255/255, 255/255, 0.75}

	self._layer = boardRig:getLayer( 'ceiling' )
	self._layer:insertProp( prop )
end

function sound_ring_rig:destroy()
	self._layer:removeProp( self._prop )
	
	self._boardRig = nil
	self._prop = nil
	self._layer = nil
end

function sound_ring_rig:onFrameUpdate()
	local localTime = MOAISim.getElapsedTime() - self._startTime

	localTime = localTime / self._lifeSpan

	if localTime > 1 then
		return false
	end

	local uniforms = self._prop:getShaderUniforms()
	uniforms:setUniformVector4( 'params', localTime, self._radialSpan, 0.0, 1.0 )
	uniforms:setUniformColor( 'color', unpack( self._color ) )

	return true
end

return sound_ring_rig