----------------------------------------------------------------
-- Copyright (c) 2013 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

--
-- Client-side helper functions.  Mostly these deal with MOAI userdata, as the
-- server will not support these.
-- For convenience, these are merged into the general util table.

local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )

----------------------------------------------------------------
-- Local functions

local EPSILON = 0.0001

local function isNumber( n )
	return type(n) == "number"
end

local function isVec3( v )
	return isNumber(v.x) and isNumber(v.y) and isNumber(v.z)
end

local function Vec3( x, y, z )
	assert( isNumber(x) and isNumber(y) and isNumber(z) )
	return setmetatable( { x = x, y = y, z = z }, { __tostring = function(v) return string.format("{%f,%f,%f}", v.x, v.y, v.z ) end } )
end

local function Vec3Add( v0, v1 )
	return Vec3(v0.x + v1.x, v0.y + v1.y, v0.z + v1.z )
end

local function Vec3Diff( v0, v1 )
	return Vec3(v0.x - v1.x, v0.y - v1.y, v0.z - v1.z )
end

local function Vec3LenSqr( v )
	return v.x * v.x + v.y * v.y + v.z * v.z
end

local function Vec3Dot( v0, v1 )
	return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z
end
local function Vec3Len( v )
	return math.sqrt( v.x * v.x + v.y * v.y + v.z * v.z )
end

local function isColor( c )
	return c.r >= 0 and c.r <= 1 and c.g >= 0 and c.g <= 1 and c.b >= 0 and c.b <= 1 and c.a >= 0 and c.a <= 1
end

local function Color( r, g, b, a )
	r = (r <= 0 and 0) or (r >= 1 and 1) or r
	g = (g <= 0 and 0) or (g >= 1 and 1) or g
	b = (b <= 0 and 0) or (b >= 1 and 1) or b
	a = (a <= 0 and 0) or (a >= 1 and 1) or a
	return setmetatable( { r = r, g = g, b = b, a = a }, { __tostring = function(c) return string.format("{%f,%f,%f,%f}", c.r, c.g, c.b, c.a ) end } )
end

local function ColorModulate( c0, c1 )
	return Color( c0.r * c1.r, c0.g * c1.g, c0.b * c1.b, c0.a * c1.a )
end

local function generateCirclePoints( radius, segment_count )
	local points = {}
	for i = 0, segment_count do
		local theta0 = (i + 0) * 2 * math.pi / (segment_count + 1)
		table.insert( points, { x = radius * math.cos( theta0 ), y = radius * math.sin( theta0 ) } )
	end
	return points
end

local function generateParabolaPoints(x0, y0, z0, x1, y1, z1, height, segments)
	local points = {}

	--parabola is of the form y = a(x-h)^2 + k
	--where (mid,height) is the vertex and we assume the parabola passes through (0, z0) at the start point
	local throwDist = mathutil.dist2d(x0, y0, x1, y1)
	local h = 0.5*throwDist
	local k = height
	local a = (z0-k)/(h*h)

	for i=0, segments do
		local t = i/segments
		local x = mathutil.lerp(x0, x1, t)
		local y = mathutil.lerp(y0, y1, t)

		--to calculate the z-value, we solve the parabolic equation for y
		--when figuring out the y-value of the parabola, the x-value is actually the straight line distance from the start point
		local d = mathutil.dist2d(x0, y0, x, y)
		local dMinusH = d-h
		local z = a*(dMinusH*dMinusH) + k
		table.insert(points, {x=x, y=y, z=z})
	end
	return points
end


local function writePolyPC ( vbo, p1, p2, p3, c1, c2, c3 )
	assert( isVec3( p1 ), "p1 is not vec3" )
	assert( isColor( c1 ), "c1 is not color" )
	vbo:writeFloat ( p1.x, p1.y, p1.z )
	vbo:writeColor32 ( c1.r, c1.g, c1.b, c1.a )
	
	assert( isVec3( p2 ), "p2 is not vec3" )
	assert( isColor( c2 ), "c2 is not color" )
	vbo:writeFloat ( p2.x, p2.y, p2.z )
	vbo:writeColor32 ( c2.r, c2.g, c2.b, c2.a )

	assert( isVec3( p3 ), "p3 is not vec3" )
	assert( isColor( c3 ), "c3 is not color" )
	vbo:writeFloat ( p3.x, p3.y, p3.z )
	vbo:writeColor32 ( c3.r, c3.g, c3.b, c3.a )
end

local function generateConeMesh( radius, color_func, segment_count, radial_count, fuzz, vertical_length, vertical_offset )
	local circle_points = generateCirclePoints( radius, segment_count )

	local vertexFormat = MOAIVertexFormat.new()
	vertexFormat:declareCoord	( 1, MOAIVertexFormat.GL_FLOAT, 3 )
	vertexFormat:declareColor	( 2, MOAIVertexFormat.GL_UNSIGNED_BYTE )
	
	local triangulator = KLEITriangulator2D.new()
	
	triangulator:addPoint( 0, 0 )
	for i = 1, fuzz or 0 do
		local theta = 2 * math.pi * math.random()
		local r = radius * math.sqrt( math.random() ) -- the sqrt on the rand gives us uniformity of the random sampling over the surface of the circle
		local x = r * math.cos( theta )
		local y = r * math.sin( theta )
		triangulator:addPoint( x, y )
	end
	for _,point in ipairs(circle_points) do
		for i = 1, radial_count or 1 do
			local f = i / radial_count
			triangulator:addPoint( point.x * f, point.y * f )
		end
	end

	local points = triangulator:getPoints()
	local triangles = triangulator:getTriangles()

	local vbo = MOAIVertexBuffer.new()
	vbo:setFormat( vertexFormat )

	--[[
	vbo:reserveVerts( #triangles*3 + 6 )
	local p1 = Vec3( 0, 0, 0 )
	local p2 = Vec3( 100, 0, 0 )
	local p3 = Vec3( 0, 0, -200 )
	local p4 = Vec3( 0, 100, 0 )
	local c1 = Color(1,1,1,1)
	local c2 = Color(1,0,0,1)
	local c3 = Color(0,1,0,1)
	local c4 = Color(0,0,1,1)	
	writePolyPC( vbo, p1, p2, p3, c1, c2, c4 )
	writePolyPC( vbo, p1, p3, p4, c1, c4, c3 )
	--]]

	-- [=[
	vbo:reserveVerts( #triangles )
	--print( #triangles )
	for i = 1, #triangles, 3 do
		local a, b, c = triangles[i], triangles[i+1], triangles[i+2]
		--store local copies of the x,y coords for each point in this triangle
		local x1, y1 = points[ a * 2 - 1 ], points[ a * 2 ]
		local x2, y2 = points[ b * 2 - 1 ], points[ b * 2 ]
		local x3, y3 = points[ c * 2 - 1 ], points[ c * 2 ]

		--r1 to r3 are normalized to [0..1]
		local r1 = (x1^2 + y1^2)^0.5 / radius
		local r2 = (x2^2 + y2^2)^0.5 / radius
		local r3 = (x3^2 + y3^2)^0.5 / radius

		--phi1 to phi3 are normalized to [0..2PI)
		local phi1 = math.atan2( y1, x1 )
		local phi2 = math.atan2( y2, x2 )
		local phi3 = math.atan2( y3, x3 )
		if phi1 < 0 then phi1 = phi1 + math.pi*2 end
		if phi2 < 0 then phi2 = phi2 + math.pi*2 end
		if phi3 < 0 then phi3 = phi3 + math.pi*2 end

		--the cone starts at vertical_offset then moves down as it expands radially out
		local p1 = Vec3( x1, y1, vertical_offset + r1 * vertical_length )
		local p2 = Vec3( x2, y2, vertical_offset + r2 * vertical_length )
		local p3 = Vec3( x3, y3, vertical_offset + r3 * vertical_length )

		--sample the colour from the passed in function for each point
		local c1 = color_func( phi1, r1, p1 )
		local c2 = color_func( phi2, r2, p2 )
		local c3 = color_func( phi3, r3, p3 )

		--write this triangle to the VBO
		writePolyPC( vbo, p1, p2, p3, c1, c2, c3 )
	end
	--]=]
	vbo:bless()

	local mesh = MOAIMesh.new()
	--mesh:setTexture( 'data/images/side_wall.png' ) we may want to have a texture added later, that would mean generating uv coords
	mesh:setVertexBuffer( vbo )
	mesh:setPrimType( MOAIMesh.GL_TRIANGLES )	
	return mesh
end

local function generateArcMesh(boardRig, x0, y0, z0, x1, y1, z1, height, segments)
	local arcPoints = generateParabolaPoints(x0, y0, z0, x1, y1, z1, height, segments)

	local firstPoint = util.tcopy(arcPoints[1])
	local xMin, yMin, xMax, yMax
	for i, point in ipairs(arcPoints) do
		point.x, point.y, point.z = point.x-firstPoint.x, point.y-firstPoint.y, point.z-firstPoint.z
		if not xMin or point.x < xMin then
			xMin = point.x
		end
		if not yMin or point.y < yMin then
			yMin = point.y
		end
		if not xMax or point.x > xMax then
			xMax = point.x
		end
		if not yMax or point.y > yMax then
			yMax = point.y
		end
	end
	local onDraw = function(index, xOff, yOff, xScale, yScale )
	    local points = {}
	    for i,point in ipairs(arcPoints) do
		    local x, y = boardRig:worldToWnd(point.x, point.y, point.z)
		    x, y = boardRig:wndToWorld(x, y)
		    table.insert(points, x)
		    table.insert(points, y)
	    end
	    MOAIDraw.drawLine(points)
	end


	-- local vertexFormat = MOAIVertexFormat.new()
	-- vertexFormat:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)
	-- vertexFormat:declareColor(2, MOAIVertexFormat.GL_UNSIGNED_BYTE)

	-- local vbo = MOAIVertexBuffer.new()
	-- vbo:setFormat( vertexFormat )

	-- local firstPoint = util.tcopy(arcPoints[1])
	-- vbo:reserveVerts(#arcPoints)
	-- for i, point in ipairs(arcPoints) do
	-- 	point.x, point.y, point.z = point.x-firstPoint.x, point.y-firstPoint.y, point.z-firstPoint.z
	-- 	vbo:writeFloat(point.x, point.y, point.z)
	-- 	vbo:writeColor32(clr.r, clr.g, clr.b, clr.a)
	-- end
	-- vbo:bless()

	-- local mesh = MOAIMesh.new()
	-- mesh:setVertexBuffer(vbo)
	-- mesh:setPrimType(MOAIMesh.GL_LINE_STRIP)
	-- mesh:setShader(MOAIShaderMgr.getShader ( MOAIShaderMgr.LINE3D_SHADER ) )
	-- return mesh

	local script = MOAIScriptDeck.new()
	script:setDrawCallback(onDraw)
	script:setRect(xMin, yMin, xMax, yMax)
	return script
end

return {
	generateCirclePoints = generateCirclePoints,
	generateConeMesh = generateConeMesh,
	generateParabolaPoints = generateParabolaPoints,
	generateArcMesh = generateArcMesh,
}