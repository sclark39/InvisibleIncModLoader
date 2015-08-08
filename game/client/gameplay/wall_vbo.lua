----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local cdefs = include( "client_defs" )
local util = include( "modules/util" )
local array = include( "modules/array" )
local binops = include( "modules/binary_ops" )

-----------------------------------------------------
-- Local

local simdefs = include( "sim/simdefs" )
--we divide the cell into four corners where their bounds are determined by moving epsilon along x & y towards the internal region
--         y      N
--         |  4-2---3-4
--         |  |1|   |2|
--         |  3-1   1-2
--         | W|       |E
--         |  2-1   1-3
--         |  |4|   |3|
--         |  4-3---2-4
--         |      S
--         0------------x
--each quadrant of the cell is further divided into 4 points and 3 levels
--         y
--         |  A--B
--         |  |  |
--         |  C--D
--         0--------x
--We extend outside the cell to support the mainframe floors pieces for doors
--         y 9-7-5   6-8-9
--         | | | | N | | |
--         | 8-4-2---3-4-7
--         | | |1|   |2| |
--         | 6-3-1   1-2-5
--         |  W|   C   |E
--         | 5-2-1   1-3-6
--         | | |4|   |3| |
--         | 7-4-3---2-4-8
--         | | | | S | | |
--         | 9-8-6   5-7-9
--         0-------------x


local alpha = {0,0,0,0}
local white = {1,1,1,1}
local black = {0,0,0,1}
local grey = {0.2,0.2,0.2,1}
local red = {1,0,0,1}
local green = {0,1,0,1}
local blue = {0,0,0.25,0.5}
local yellow = {1,1,0,1}
local top_color = grey
local bottom_color = black
local mainframe_color = {82/255, 114/255, 115/255, 1}
local tactical_color = {128/255, 128/255, 128/255, 1}

local N,E,S,W = simdefs.DIR_N, simdefs.DIR_E, simdefs.DIR_S, simdefs.DIR_W
local NE,NW,SE,SW = simdefs.DIR_NE, simdefs.DIR_NW, simdefs.DIR_SE, simdefs.DIR_SW

--C is a continuation, W is a wall, D is a door, L is left, R is right. Add to get the wall geo type
local CR,WR,PR = 1*4^0, 2*4^0, 3*4^0
local CL,WL,PL = 1*4^1, 2*4^1, 3*4^1
local EMPTY,WALL,DOOR,POST= 0,1*4^2, 2*4^2, 3*4^2
local NAME = {}
for k1,v1 in pairs( {[""] = 0, WALL = WALL, DOOR = DOOR, POST = POST } ) do
	for k2,v2 in pairs( { [""] = 0, CL = CL, WL = WL, PL = PL } ) do
		for k3,v3 in pairs( { [""] = 0, CR = CR, WR = WR, PR = PR } ) do
			local str = k1
			if k2 ~= "" then str = (str ~= "") and (str .. "+" .. k2) or k2 end
			if k3 ~= "" then str = (str ~= "") and (str .. "+" .. k3) or k3 end
			NAME[v1+v2+v3] = str
		end
	end
end

local C0,C1,C2,C3 = 0,1,2,3 --camera orientations

local T_MAIN, T_FLOR, T_CEIL, T_CORN, T_HALF, T_WALL = 100, 200, 300, 400, 500, 600
local u0,u1,u2,u3,u4,u5,u6,u7,u8 = 0/8, 1/8, 2/8, 3/8, 4/8, 5/8, 6/8, 7/8, 8/8
local h = 0.5
local wall_height = 2.25
local e = 0.05
local c = 1.0
local t = 1.0 - e
local z = 2.5
local POSITIONS =
{
	[1] =
	{
		[1] = { { e,1-e,0}, { e,1-e,c}, { e,1-e,t}, { e,1-e,z} },	--inside
		[2] = { { e,  1,0}, { e,  1,c}, { e,  1,t}, { e,  1,z} },	--inside-CCW
		[3] = { { 0,1-e,0}, { 0,1-e,c}, { 0,1-e,t}, { 0,1-e,z} },	--inside-CW
		[4] = { { 0,  1,0}, { 0,  1,c}, { 0,  1,t}, { 0,  1,z} },	--outside
		[5] = { { e,1+e,0}, { e,1+e,c}, { e,1+e,t}, { e,1+e,z} },	--above [2]
		[6] = { {-e,1-e,0}, {-e,1-e,c}, {-e,1-e,t}, {-e,1-e,z} },	--left [3]
		[7] = { { 0,1+e,0}, { 0,1+e,c}, { 0,1+e,t}, { 0,1+e,z} },	--above [4]
		[8] = { {-e,  1,0}, {-e,  1,c}, {-e,  1,t}, {-e,  1,z} },	--left [4]
		[9] = { {-e,1+e,0}, {-e,1+e,c}, {-e,1+e,t}, {-e,1+e,z} },	--above[8]
	},
	[2] =
	{
		[1] = { {1-e,1-e,0}, {1-e,1-e,c}, {1-e,1-e,t}, {1-e,1-e,z} }, --inside
		[2] = { {  1,1-e,0}, {  1,1-e,c}, {  1,1-e,t}, {  1,1-e,z} }, --inside-CCW
		[3] = { {1-e,  1,0}, {1-e,  1,c}, {1-e,  1,t}, {1-e,  1,z} }, --inside-CW
		[4] = { {  1,  1,0}, {  1,  1,c}, {  1,  1,t}, {  1,  1,z} }, --outside
		[5] = { {1+e,1-e,0}, {1+e,1-e,c}, {1+e,1-e,t}, {1+e,1-e,z} }, --right [2]
		[6] = { {1-e,1+e,0}, {1-e,1+e,c}, {1-e,1+e,t}, {1-e,1+e,z} }, --above [3]
		[7] = { {1+e,  1,0}, {1+e,  1,c}, {1+e,  1,t}, {1+e,  1,z} }, --right [4]
		[8] = { {  1,1+e,0}, {  1,1+e,c}, {  1,1+e,t}, {  1,1+e,z} }, --above [4]
		[9] = { {1+e,1+e,0}, {1+e,1+e,c}, {1+e,1+e,t}, {1+e,1+e,z} }, --right [8]
	},
	[3] =
	{
		[1] = { {1-e, e,0}, {1-e, e,c}, {1-e, e,t}, {1-e, e,z} }, --inside
		[2] = { {1-e, 0,0}, {1-e, 0,c}, {1-e, 0,t}, {1-e, 0,z} }, --inside-CCW
		[3] = { {  1, e,0}, {  1, e,c}, {  1, e,t}, {  1, e,z} }, --inside-CW
		[4] = { {  1, 0,0}, {  1, 0,c}, {  1, 0,t}, {  1, 0,z} }, --outside
		[5] = { {1-e,-e,0}, {1-e,-e,c}, {1-e,-e,t}, {1-e,-e,z} }, --below [2]
		[6] = { {1+e, e,0}, {1+e, e,c}, {1+e, e,t}, {1+e, e,z} }, --right [3]
		[7] = { {  1,-e,0}, {  1,-e,c}, {  1,-e,t}, {  1,-e,z} }, --below [4]
		[8] = { {1+e, 0,0}, {1+e, 0,c}, {1+e, 0,t}, {1+e, 0,z} }, --right [4]
		[9] = { {1+e,-e,0}, {1+e,-e,c}, {1+e,-e,t}, {1+e,-e,z} }, --below [8]
	},
	[4] =
	{
		[1] = { { e, e,0}, { e, e,c}, { e, e,t}, { e, e,z} }, --inside
		[2] = { { 0, e,0}, { 0, e,c}, { 0, e,t}, { 0, e,z} }, --inside-CCW
		[3] = { { e, 0,0}, { e, 0,c}, { e, 0,t}, { e, 0,z} }, --inside-CW
		[4] = { { 0, 0,0}, { 0, 0,c}, { 0, 0,t}, { 0, 0,z} }, --outside
		[5] = { {-e, e,0}, {-e, e,c}, {-e, e,t}, {-e, e,z} }, --left [2]
		[6] = { { e,-e,0}, { e,-e,c}, { e,-e,t}, { e,-e,z} }, --below [3]
		[7] = { {-e, 0,0}, {-e, 0,c}, {-e, 0,t}, {-e, 0,z} }, --left [4]
		[8] = { { 0,-e,0}, { 0,-e,c}, { 0,-e,t}, { 0,-e,z} }, --below [4]
		[9] = { {-e,-e,0}, {-e,-e,c}, {-e,-e,t}, {-e,-e,z} }, --left [8]
	},		
}

local NORMAL =
{
	[N] = {0,-1,0},	--normal of a north wall
	[E] = {-1,0,0}, --normal of a east wall
	[S] = {0,1,0},	--normal of a south wall
	[W] = {1,0,0},	--normal of a west wall
	[8] = {0,0,1},	--normal of a floor
}

local function norm_from_q( q1 )
		if q1 == 1 then return N
	elseif q1 == 2 then return E
	elseif q1 == 3 then return S
	elseif q1 == 4 then return W
	else assert( false ) end
end
local function dec_norm( norm )
		if norm == N then return W
	elseif norm == E then return N
	elseif norm == S then return E
	elseif norm == W then return S
	else assert( false ) end
end

	
--***************************************WALL*******************************************************************
local function make_wall_type( dir, q1, q2, L, R )
	assert( dir == N or dir == E or dir == S or dir == W )
	assert( (L == CL or L == WL or L == PL) and (R == CR or R == WR or R == PR), "UNEXPECTED TYPE " .. NAME[L] .. " " .. NAME[R])
	--L and R control which points in q1 and q2 to select from when generating the geo
	--    p2         p4
	--  q1             q2
	--    p1         p3
	local n = norm_from_q( q1 )
	local P = { [CL] = {3,4}, [WL] = {1,4}, [PL] = {1,2}, [CR] = {2,4}, [WR] = {1,4}, [PR] = {1,3} }
	local p1,p2 = unpack( P[L] )
	local p3,p4 = unpack( P[R] )
	local wall_modes = {}
	wall_modes.mainframe =
		{
			--Floor piece
			{{POSITIONS[q1][p1][1], NORMAL[8], {0,0,T_MAIN}, alpha, mainframe_color},
				{POSITIONS[q2][p3][1], NORMAL[8], {0,0,T_MAIN}, alpha, mainframe_color},
				{POSITIONS[q1][p2][1], NORMAL[8], {0,0,T_MAIN}, alpha, mainframe_color},
				{POSITIONS[q2][p4][1], NORMAL[8], {0,0,T_MAIN}, alpha, mainframe_color},},
		} --wall_modes.mainframe
    wall_modes.tactical =
		{
			--Floor piece
			{{POSITIONS[q1][p1][1], NORMAL[8], {0,0,T_MAIN}, alpha, tactical_color},
				{POSITIONS[q2][p3][1], NORMAL[8], {0,0,T_MAIN}, alpha, tactical_color},
				{POSITIONS[q1][p2][1], NORMAL[8], {0,0,T_MAIN}, alpha, tactical_color},
				{POSITIONS[q2][p4][1], NORMAL[8], {0,0,T_MAIN}, alpha, tactical_color},},
		} --wall_modes.mainframe
	wall_modes.normal =
		{
			--Floor piece
			{{POSITIONS[q1][p1][1], NORMAL[8], {0,0,T_FLOR}, alpha, bottom_color},
				{POSITIONS[q2][p3][1], NORMAL[8], {0,0,T_FLOR}, alpha, bottom_color},
				{POSITIONS[q1][p2][1], NORMAL[8], {0,0,T_FLOR}, alpha, bottom_color},
				{POSITIONS[q2][p4][1], NORMAL[8], {0,0,T_FLOR}, alpha, bottom_color},},
			--Vertical piece
			{{POSITIONS[q1][p1][1], NORMAL[n], {0,0,T_WALL,1}, white, alpha},
				{POSITIONS[q2][p3][1], NORMAL[n], {1,0,T_WALL,1}, white, alpha},
				{POSITIONS[q1][p1][2], NORMAL[n], {0,1,T_WALL,1}, white, alpha},
				{POSITIONS[q2][p3][2], NORMAL[n], {1,1,T_WALL,1}, white, alpha},},
			--Ceiling piece
			{{POSITIONS[q1][p1][2], NORMAL[8], {0,0,T_CEIL}, alpha, top_color},
				{POSITIONS[q2][p3][2], NORMAL[8], {0,0,T_CEIL}, alpha, top_color},
				{POSITIONS[q1][p2][2], NORMAL[8], {0,0,T_CEIL}, alpha, top_color},
				{POSITIONS[q2][p4][2], NORMAL[8], {0,0,T_CEIL}, alpha, top_color},},
		} --wall_modes.normal
	return wall_modes
end
local function make_wall_crossbeam( dir, q1, q2, L, R )
	assert( dir == N or dir == E or dir == S or dir == W )
	assert( (L == CL or L == PL) and (R == CR or R == PR), "UNEXPECTED TYPE " .. NAME[L] .. " " .. NAME[R] )
	local n = norm_from_q( q1 )
	local P = { [CL] = {3,4}, [PL] = {1,2}, [CR] = {2,4}, [PR] = {1,3} }
	local p1,p2 = unpack( P[L] )
	local p3,p4 = unpack( P[R] )
	local wall_modes = {}
	wall_modes.mainframe = {}
	wall_modes.normal =
		{
			--Vertical piece
			{{POSITIONS[q1][p1][3], NORMAL[n], {e,t,T_WALL,1}, white, alpha},
				{POSITIONS[q2][p3][3], NORMAL[n], {1,t,T_WALL,1}, white, alpha},
				{POSITIONS[q1][p1][2], NORMAL[n], {e,1,T_WALL,1}, white, alpha},
				{POSITIONS[q2][p3][2], NORMAL[n], {1,1,T_WALL,1}, white, alpha},},
			--Ceiling piece
			{{POSITIONS[q1][p1][2], NORMAL[8], {0,0,T_CEIL}, alpha, top_color},
				{POSITIONS[q2][p3][2], NORMAL[8], {0,0,T_CEIL}, alpha, top_color},
				{POSITIONS[q1][p2][2], NORMAL[8], {0,0,T_CEIL}, alpha, top_color},
				{POSITIONS[q2][p4][2], NORMAL[8], {0,0,T_CEIL}, alpha, top_color},},
		} --wall_modes.normal
	return wall_modes
end
local function make_wall_direction( dir, q1, q2 )
	local wall_types = {}
	for _,L in pairs( {CL,WL,PL} ) do
		for _,R in pairs( {CR,WR,PR} ) do
			wall_types[ WALL + L + R ] = make_wall_type( dir, q1, q2, L, R )
		end
	end
	wall_types[ DOOR + PL + PR ] = make_wall_crossbeam( dir, q1, q2, PL, PR )
	wall_types[ DOOR + PL + CR ] = make_wall_crossbeam( dir, q1, q2, PL, CR )
	wall_types[ DOOR + CL + PR ] = make_wall_crossbeam( dir, q1, q2, CL, PR )
	wall_types[ DOOR + CL + CR ] = make_wall_crossbeam( dir, q1, q2, CL, CR )
	return wall_types
end

--	   Q1	    Q4
--		/-------\
--		| 2 | 1 |
--		|1 4|3 2|
--		| 3 | 4 |
--		|---+---|
--		| 4 | 3 |
--		|2 3|4 1|
--		| 1 | 2 |
--		\-------/
--	   Q2	    Q3
local subwall_PN_patterns = {
	[1] =	--Q1
	{
		[1] = {6,3,E},
		[2] = {8,6,S},
		[3] = {3,4,N},
		[4] = {4,8,W},
	},
	[2] =	--Q2
	{
		[1] = {1,2,N},
		[2] = {3,1,E},
		[3] = {2,4,W},
		[4] = {4,3,S},
	},
	[3] =	--Q3
	{
		[1] = {5,7,W},
		[2] = {2,5,N},
		[3] = {7,4,S},
		[4] = {4,2,E},
	},
	[4] =	--Q4
	{
		[1] = {9,8,S},
		[2] = {7,9,W},
		[3] = {8,4,E},
		[4] = {4,7,N},
	},
}
local subwall_UV_patterns = {
	[T_WALL] =
	{
		[1] =	--Q1
		{--  [d] = {u0,u1,tex_idx}
			[1] = {1-e,1,2},
			[2] = {0,e,2},
		},
		[2] =	--Q2
		{
			[1] = {1-e,1,1},
			[2] = {0,e,1},
		},
		[3] =	--Q3
		{
			[1] = {1-e,1,4},
			[2] = {0,e,4},
		},
		[4] =	--Q4
		{
			[1] = {1-e,1,3},
			[2] = {0,e,3},
		},
	},
	[T_CORN] =
	{
		[1] =	--Q1
		{
			[1] = {0/8,1/8},
			[2] = {7/8,8/8},
		},
		[2] =	--Q2
		{
			[1] = {2/8,3/8},
			[2] = {1/8,2/8},
		},
		[3] =	--Q3
		{
			[1] = {4/8,5/8},
			[2] = {3/8,4/8},
		},
		[4] =	--Q4
		{
			[1] = {6/8,7/8},
			[2] = {5/8,6/8},
		},
	},
	[T_HALF] =
	{
		[1] =	--Q1
		{
			[1] = {0,h},
			[2] = {h,1},
			[3] = {0,h},
			[4] = {h,1},
		},
		[2] =	--Q2
		{
			[1] = {0,h},
			[2] = {h,1},
			[3] = {0,h},
			[4] = {h,1},
		},
		[3] =	--Q3
		{
			[1] = {0,h},
			[2] = {h,1},
			[3] = {0,h},
			[4] = {h,1},
		},
		[4] =	--Q4
		{
			[1] = {0,h},
			[2] = {h,1},
			[3] = {0,h},
			[4] = {h,1},
		},
	},
}
local function make_subwall(q,w,t)
	return {q,w,t}
end
local function make_wall( rotation, view, sub_walls )
	local subwall_PN_patterns, subwall_UV_patterns = subwall_PN_patterns, subwall_UV_patterns --optimize up-values
	--transform the sub_walls by the rotation
	for _,sub_wall in ipairs(sub_walls) do
		sub_wall[1] = (sub_wall[1] - 1 + rotation - 1 ) % 4 + 1
	end
	
	--sort sub_wall in-place for the selected rotation
	local view_order =
	{
		[1] = { [2] = 1, [3] = 2, [1] = 3, [4] = 4 },
		[2] = { [3] = 1, [4] = 2, [2] = 3, [1] = 4 },
		[3] = { [4] = 1, [1] = 2, [3] = 3, [2] = 4 },
		[4] = { [1] = 1, [2] = 2, [4] = 3, [3] = 4 },
	}
	local view_sub_order =
	{
		[1] = { [1] = 1, [2] = 2, [3] = 3, [4] = 4 },
		[2] = { [2] = 1, [4] = 2, [1] = 3, [3] = 4 },
		[3] = { [4] = 1, [3] = 2, [2] = 3, [1] = 4 },
		[4] = { [3] = 1, [1] = 2, [4] = 3, [2] = 4 },
	}
	local function view_sort( sub_wall_a, sub_wall_b )
		local view_order, view_sub_order = view_order, view_sub_order --optimize up-values
		local a,b = sub_wall_a[1], sub_wall_b[1]
		local A,B = view_order[view][a], view_order[view][b]
		if A == B then
			local c,d = sub_wall_a[2], sub_wall_b[2]
			local C,D = view_sub_order[a][c], view_sub_order[b][d]
			return C < D
		else
			return A < B
		end
	end
	table.sort( sub_walls, view_sort )
	
	
	local output = {}
	--transform the sub_walls into vertices
	for _,sub_wall in ipairs(sub_walls) do
		--select and copy the wall from the set of walls
		local q, w, t = unpack( sub_wall )
		local PN_pattern = subwall_PN_patterns[q][w]
		local UV_pattern = subwall_UV_patterns[t][q][w]
		
		local cm, ca = white, alpha
		local p0,p1,n = unpack( PN_pattern )
		local u0,u1 = unpack( UV_pattern )
		
		table.insert( output, {POSITIONS[2][p0][1], NORMAL[n], {u0,0,t,q}, cm, ca} )
		table.insert( output, {POSITIONS[2][p1][1], NORMAL[n], {u1,0,t,q}, cm, ca} )
		table.insert( output, {POSITIONS[2][p0][2], NORMAL[n], {u0,1,t,q}, cm, ca} )
		table.insert( output, {POSITIONS[2][p1][2], NORMAL[n], {u1,1,t,q}, cm, ca} )
		table.insert( output, {reset=true} )
	end
	return output
end
local function make_floor( rotation, type, ... )
	local input = {...}
	
	local rot_tot =
	{
		[1] = { 1,2,3,4,5,6,7,8,9 }, --base '0' rotation
		[2] = { 5,7,2,4,9,1,8,3,6 },
		[3] = { 9,8,7,4,6,5,3,2,1 },
		[4] = { 6,3,8,4,1,9,2,7,5 },
	}
	
	local cm, ca, z
		if type == T_MAIN then
			cm, ca, z = alpha, mainframe_color, 1
	elseif type == T_FLOR then
			cm, ca, z = alpha, bottom_color, 1
	elseif type == T_CEIL then
			cm, ca, z = alpha, top_color, 2
	else
		assert( false, "unexpected type " .. tostring(type) )
	end
	
	local output = {}
	for _,p in ipairs( input ) do
		table.insert( output, {POSITIONS[2][ rot_tot[rotation][p] ][z], NORMAL[8], {0,0,type}, cm, ca} )
	end
	return output
end
local function make_caps_rotation()
	local make_floor, make_wall, make_subwall = make_floor, make_wall, make_subwall --optimize up-values
	local caps = {}
	for t=1,21 do
		caps[t] = { {}, {}, {}, {} }
	end
	for r=1,4 do
		for v=1,4 do
			caps[1][r][v] = --DOOR PATTERN 1
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 5, 6, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 5, 6, 9 ),
					make_wall( r, v, {make_subwall(1,1,T_CORN), make_subwall(1,2,T_CORN), make_subwall(2,1,T_CORN), make_subwall(2,2,T_CORN), make_subwall(3,1,T_CORN), make_subwall(3,2,T_CORN), make_subwall(4,1,T_CORN), make_subwall(4,2,T_CORN)} ),
					make_floor( r, T_CEIL, 1, 5, 6, 9 ),
				},
			}
			caps[2][r][v] = --DOOR PATTERN 2
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 5, 6, 9 )
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 5, 6, 9 ),
					make_wall( r, v, {make_subwall(1,1,T_CORN), make_subwall(1,2,T_CORN), make_subwall(2,1,T_CORN), make_subwall(2,2,T_CORN), make_subwall(3,2,T_WALL), make_subwall(4,1,T_WALL)} ),
					make_floor( r, T_CEIL, 1, 5, 6, 9 ),
				},
			}
			caps[3][r][v] = --DOOR PATTERN 3
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 5, 6, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 5, 6, 9 ),
					make_wall( r, v, {make_subwall(1,1,T_WALL), make_subwall(2,1,T_CORN), make_subwall(2,2,T_CORN), make_subwall(3,2,T_WALL)} ),
					make_floor( r, T_CEIL, 1, 5, 6, 9 ),
				},
			}
			caps[4][r][v] = --DOOR PATTERN 4
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 5, 6, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 5, 6, 9 ),
					make_wall( r, v, {make_subwall(2,1,T_WALL), make_subwall(3,2,T_WALL)} ),
					make_floor( r, T_FLOR, 1, 5, 6, 9 ),
				},
			}
			caps[5][r][v] = --DOOR PATTERN 5
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 2, 6, 8 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 2, 6, 8 ),
					make_wall( r, v, {make_subwall(1,2,T_WALL), make_subwall(1,4,T_HALF), make_subwall(2,1,T_WALL), make_subwall(2,3,T_HALF)} ),
					make_floor( r, T_CEIL, 1, 2, 6, 8 ),
				},
			}
			caps[6][r][v] = --DOOR PATTERN 6
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 5, 6, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 5, 6, 9 ),
					make_wall( r, v, {make_subwall(1,2,T_WALL), make_subwall(2,1,T_WALL), make_subwall(3,2,T_WALL), make_subwall(4,1,T_WALL)} ),
					make_floor( r, T_CEIL, 1, 5, 6, 9 ),
				},
			}
			caps[7][r][v] = --WALL PATTERN 7
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 5, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 5, 9 ),
					make_wall( r, v, {make_subwall(2,1,T_WALL), make_subwall(3,2,T_CORN), make_subwall(3,1,T_CORN), make_subwall(4,2,T_WALL)} ),
					make_floor( r, T_CEIL, 1, 5, 9 ),
				},
			}
			caps[8][r][v] = --WALL PATTERN 8
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 4, 5, 9 ),					
				},
				normal =
				{
					make_floor( r, T_FLOR, 4, 5, 9 ),
					make_wall( r, v, {make_subwall(3,1,T_WALL), make_subwall(4,2,T_WALL)} ),
					make_floor( r, T_CEIL, 4, 5, 9 ),
				},
			}
			caps[9][r][v] = --WALL PATTERN 9
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 6, 4, 9, 7 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 6, 4, 9, 7 ),
					make_wall( r, v, {make_subwall(1,2,T_WALL), make_subwall(4,1,T_CORN), make_subwall(4,2,T_CORN)} ),
					make_floor( r, T_CEIL, 6, 4, 9, 7 ),
				},
			}
			caps[10][r][v] = --WALL PATTERN 10
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 4, 3 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 4, 3 ),
					make_wall( r, v, {make_subwall(2,2,T_WALL), make_subwall(2,4,T_HALF), make_subwall(3,3,T_HALF)} ),
					make_floor( r, T_CEIL, 1, 4, 3 ),
				},
			}
			caps[11][r][v] = --WALL PATTERN 11
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 6, 3, 4 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 6, 3, 4 ),
					make_wall( r, v, {make_subwall(1,1,T_WALL), make_subwall(1,3,T_HALF), make_subwall(4,4,T_HALF)} ),
					make_floor( r, T_CEIL, 6, 3, 4 ),
				},
			}
			caps[12][r][v] = --WALL PATTERN 12
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 5, 4, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 5, 4, 9 ),
					make_wall( r, v, {make_subwall(2,1,T_WALL), make_subwall(3,2,T_CORN), make_subwall(3,1,T_CORN)} ),
					make_floor( r, T_CEIL, 1, 5, 4, 9 ),
				},
			}
			caps[13][r][v] = --WALL PATTERN 13
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 6, 4, 9, 7 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 6, 4, 9, 7 ),
					make_wall( r, v, {make_subwall(1,2,T_HALF), make_subwall(4,1,T_HALF), make_subwall(4,2,T_WALL)} ),
					make_floor( r, T_CEIL, 6, 4, 9, 7 ),
				},
			}
			caps[14][r][v] = --WALL PATTERN 14
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 5, 4, 7 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 5, 4, 7 ),
					make_wall( r, v, {make_subwall(2,1,T_HALF), make_subwall(3,2,T_HALF), make_subwall(3,1,T_WALL)} ),
					make_floor( r, T_CEIL, 1, 5, 4, 7 ),
				},
			}
			caps[15][r][v] = --WALL PATTERN 15
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 4, 7, 8, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 4, 7, 8, 9 ),
					make_wall( r, v, {make_subwall(4,1,T_CORN), make_subwall(4,2,T_CORN)} ),
					make_floor( r, T_CEIL, 4, 7, 8, 9 ),
				},
			}
			caps[16][r][v] = --WALL PATTERN 16
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 4, 6, 7, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 4, 6, 7, 9 ),
					make_wall( r, v, {make_subwall(1,1,T_CORN), make_subwall(1,2,T_CORN), make_subwall(2,2,T_WALL), make_subwall(4,1,T_CORN), make_subwall(4,2,T_CORN)} ),
					make_floor( r, T_CEIL, 1, 4, 6, 7, 9 ),
				},
			}
			caps[17][r][v] = --WALL PATTERN 17
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 4, 6, 7, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 4, 6, 7, 9 ),
					make_wall( r, v, {make_subwall(1,1,T_HALF), make_subwall(1,2,T_WALL), make_subwall(2,2,T_HALF), make_subwall(4,1,T_CORN), make_subwall(4,2,T_CORN)} ),
					make_floor( r, T_CEIL, 1, 4, 6, 7, 9 ),
				},
			}
			caps[18][r][v] = --WALL PATTERN 18
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 4, 5, 8, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 4, 5, 8, 9 ),
					make_wall( r, v, {make_subwall(2,1,T_HALF), make_subwall(3,2,T_HALF), make_subwall(3,1,T_WALL), make_subwall(4,2,T_CORN), make_subwall(4,1,T_CORN)} ),
					make_floor( r, T_CEIL, 1, 4, 5, 8, 9 ),
				},
			}
			caps[19][r][v] = --WALL PATTERN 19
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 1, 4, 5, 8, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 1, 4, 5, 8, 9 ),
					make_wall( r, v, {make_subwall(2,1,T_WALL), make_subwall(3,2,T_CORN), make_subwall(3,1,T_CORN), make_subwall(4,2,T_CORN), make_subwall(4,1,T_CORN)} ),
					make_floor( r, T_CEIL, 1, 4, 5, 8, 9 ),
				},
			}
			caps[20][r][v] = --WALL PATTERN 20
			{
				mainframe =
				{
				},
				normal =
				{
					make_wall( r, v, {make_subwall(2,4,T_HALF), make_subwall(3,3,T_HALF) } ),
				}
			}
			caps[21][r][v] = --WALL PATTERN 21
			{
				mainframe =
				{
					make_floor( r, T_MAIN, 3, 7, 6, 9 ),
				},
				normal =
				{
					make_floor( r, T_FLOR, 3, 7, 6, 9 ),
					make_wall( r, v, {make_subwall(1,1,T_CORN), make_subwall(1,2,T_CORN), make_subwall(4,1,T_CORN), make_subwall(4,2,T_CORN)} ),
					make_floor( r, T_CEIL, 3, 7, 6, 9 ),
				},
			}
		end
	end
	return caps
end
--***************************************DOOR*******************************************************************
local function make_door_normal( dir, q1, q2, L, R )
	local P = { [CL] = 4, [PL] = 2, [CR] = 4, [PR] = 3 }
	local p1 = P[L]
	local p2 = P[R]
	local n = norm_from_q( q1 )
	local stripes = {
		{{POSITIONS[q1][p1][1], NORMAL[8], {0,0}, white, alpha},
			{POSITIONS[q2][p2][1], NORMAL[8], {1,0}, white, alpha},
			{POSITIONS[q1][p1][2], NORMAL[8], {0,1}, white, alpha},
			{POSITIONS[q2][p2][2], NORMAL[8], {1,1}, white, alpha},},
			} --stripes
	return stripes
end
local function make_door_mainframe( dir, q1, q2, L, R, clr )
	assert( (L == CL or L == PL) and (R == CR or R == PR), "UNEXPECTED TYPE " .. NAME[L] .. " " .. NAME[R] )
	local P = { [CL] = {3,7}, [PL] = {1,5}, [CR] = {2,8}, [PR] = {1,6} }
	local p1,p2 = unpack( P[L] )
	local p3,p4 = unpack( P[R] )
	local stripes = {
		{{POSITIONS[q1][p1][1], NORMAL[8], {0,0}, alpha, clr},
			{POSITIONS[q2][p3][1], NORMAL[8], {0,0}, alpha, clr},
			{POSITIONS[q1][p2][1], NORMAL[8], {0,0}, alpha, clr},
			{POSITIONS[q2][p4][1], NORMAL[8], {0,0}, alpha, clr},},
			} --stripes
	return stripes
end
local function make_door_direction( dir, q1, q2 )
	local door_types = {}
	for _,L in pairs( {CL,PL} ) do
		for _,R in pairs( {CR,PR} ) do
			door_types[ DOOR + L + R ] = {}
			door_types[ DOOR + L + R ].mainframe_locked = make_door_mainframe( dir, q1, q2, L, R, red )
			door_types[ DOOR + L + R ].mainframe_unlocked = make_door_mainframe( dir, q1, q2, L, R, yellow )
			door_types[ DOOR + L + R ].mainframe_open = make_door_mainframe( dir, q1, q2, L, R, green )
			door_types[ DOOR + L + R ].locked = make_door_normal( dir, q1, q2, L, R )
			door_types[ DOOR + L + R ].unlocked = make_door_normal( dir, q1, q2, L, R )
			door_types[ DOOR + L + R ].broken = make_door_normal( dir, q1, q2, L, R )
		end
	end
	return door_types
end	


local geo_walls = {}
geo_walls[N]  = make_wall_direction( N, 1, 2 )
geo_walls[E]  = make_wall_direction( E, 2, 3 )
geo_walls[S]  = make_wall_direction( S, 3, 4 )
geo_walls[W]  = make_wall_direction( W, 4, 1 )
local geo_caps = make_caps_rotation( )
local geo_doors = {}
geo_doors[N] = make_door_direction( N, 1, 2 )
geo_doors[E] = make_door_direction( E, 2, 3 )

--Some helper functions for constructing the VB
local function transformUV( UVInfo, UV )
	if UVInfo then
		local u,v,t,q = unpack(UV)
		local transform = {0,0,1,1}
		if t == T_MAIN or t == T_FLOR or t == T_CEIL then
		elseif t == T_CORN then
			transform = cdefs.POST_DEFAULT
		elseif t == T_HALF then
			transform = cdefs.HALF_WALL
		elseif t == T_WALL then
			local tileIndex = UVInfo[q]
			transform = tileIndex and cdefs.MAPTILES[ tileIndex ].zone.wallUV or cdefs.WALL_EXTERNAL
		else
			assert(false, "type is " .. tostring(t))
		end
		u = u*(transform[3] - transform[1]) + transform[1]
		v = v*(transform[4] - transform[2]) + transform[2]
		return {u,v}
	else
		return UV
	end
end
local function transformPosition( position, x, y )
	local x = (position[1] + x) * cdefs.BOARD_TILE_SIZE
	local y = (position[2] + y) * cdefs.BOARD_TILE_SIZE
	local z = position[3] * cdefs.BOARD_TILE_SIZE * wall_height
	return { x, y, z }
end
local function addStripeToVB( VB, stripe, x, y, UVInfo )
	for i=1,#stripe-2,1 do
		local i1, i2, i3 = i+(i+1)%2, i+i%2, i+2
		local v1, v2, v3 = stripe[i1], stripe[i2], stripe[i3]
		local skip = v1.reset or v2.reset or v3.reset
		if not skip then
			local p1, p2, p3 = transformPosition(v1[1], x, y), transformPosition(v2[1], x, y), transformPosition(v3[1], x, y)
			local n1, n2, n3 = v1[2], v2[2], v3[2]
			local u1, u2, u3 = transformUV(UVInfo, v1[3]), transformUV(UVInfo, v2[3]), transformUV(UVInfo, v3[3])
			local m1, m2, m3 = v1[4], v2[4], v3[4]
			local a1, a2, a3 = v1[5], v2[5], v3[5]
			v1, v2, v3 = {p1,n1,u1,m1,a1}, {p2,n2,u2,m2,a2}, {p3,n3,u3,m3,a3}
			table.insert( VB, v1 )
			table.insert( VB, v2 )
			table.insert( VB, v3 )
		end
	end
end

--visibility bits
local function bits_to_value( bits )
	local value = 0
	for i=1,4 do
		value = value + bits[i]*2^(i-1)
	end
	return value
end

local TMP_BITS = {0,0,0,0}
local function rotate_value_bits( value, r )
	for i=1,4 do
		TMP_BITS[(i+r-1)%4+1] = (value % 2^i >= 2^(i-1)) and 1 or 0
	end
--	print( util.stringize(TMP_BITS))
	local new_value = 0
	for i=1,4 do
		new_value = new_value + TMP_BITS[i]*2^(i-1)
	end
	return new_value
end

local IIII = bits_to_value({0,0,0,0})
local IIIV = bits_to_value({0,0,0,1})
local IIVI = bits_to_value({0,0,1,0})
local IIVV = bits_to_value({0,0,1,1})
local IVII = bits_to_value({0,1,0,0})
local IVIV = bits_to_value({0,1,0,1})
local IVVI = bits_to_value({0,1,1,0})
local IVVV = bits_to_value({0,1,1,1})
local VIII = bits_to_value({1,0,0,0})
local VIIV = bits_to_value({1,0,0,1})
local VIVI = bits_to_value({1,0,1,0})
local VIVV = bits_to_value({1,0,1,1})
local VVII = bits_to_value({1,1,0,0})
local VVIV = bits_to_value({1,1,0,1})
local VVVI = bits_to_value({1,1,1,0})
local VVVV = bits_to_value({1,1,1,1})

local patterns =
{
	{ {WALL,WALL,WALL,WALL}, { [VIII] = {7,1}, [IVII] = {7,0}, [IIVI] = {7,3}, [IIIV] = {7,2}, [VVII] = {8,0}, [IVVI] = {8,3}, [IIVV] = {8,2}, [VIIV] = {8,1}, default = nil } },
	{ {WALL,WALL,WALL,EMPTY}, { [VIII] = {9,0}, [IVII] = {12,0},[IIVI] = {11,0},[IIIV] = {10,0},[VVII] = false, [IVVI] = {14,0},[IIVV] = {8,2}, [VIIV] = {13,0},default = nil } },
	{ {WALL,WALL,EMPTY,EMPTY}, { [VIII] = {15,0},[IVII] = {19,0},[IIVI] = false, [IIIV] = {16,0},[VVII] = {15,0},[IVVI] = {18,0},[IIVV] = {17,0},[VIIV] = {15,0},default = {15,0} } },
	{ {WALL,EMPTY,WALL,EMPTY}, { [VIII] = {20,0},[IVII] = {20,2},[IIVI] = {20,2},[IIIV] = {20,0},[VVII] = false, [IVVI] = {20,2},[IIVV] = false, [VIIV] = {20,0},default = nil } },
	{ {WALL,EMPTY,EMPTY,EMPTY}, { [VIII] = {21,0},[IVII] = false, [IIVI] = false, [IIIV] = {21,0},[VVII] = {21,0},[IVVI] = false, [IIVV] = {21,0},[VIIV] = {21,0},default = {21,0} } },
		
	{ {DOOR,WALL,EMPTY,EMPTY}, { [VIII] = {1,0}, [IVII] = {2,2}, [IIVI] = false, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
	{ {DOOR,EMPTY,WALL,EMPTY}, { [VIII] = {1,0}, [IVII] = {2,1}, [IIVI] = {2,1}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {2,1}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
	{ {DOOR,EMPTY,EMPTY,WALL}, { [VIII] = {1,0}, [IVII] = false, [IIVI] = {2,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {2,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
		
	{ {DOOR,WALL,WALL,EMPTY}, { [VIII] = {1,0}, [IVII] = {3,1}, [IIVI] = {2,1}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {3,1}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
	{ {DOOR,WALL,EMPTY,WALL}, { [VIII] = {1,0}, [IVII] = {5,0}, [IIVI] = {5,2}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {6,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
	{ {DOOR,EMPTY,WALL,WALL}, { [VIII] = {1,0}, [IVII] = {2,1}, [IIVI] = {3,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {3,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
		
	{ {DOOR,WALL,WALL,WALL}, { [VIII] = {1,0}, [IVII] = {3,1}, [IIVI] = {3,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {4,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
		
	{ {DOOR,DOOR,EMPTY,EMPTY}, { [VIII] = {1,0}, [IVII] = {1,0}, [IIVI] = false, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
		
	{ {DOOR,DOOR,WALL,EMPTY}, { [VIII] = {1,0}, [IVII] = {1,0}, [IIVI] = {2,1}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },		
	{ {DOOR,DOOR,EMPTY,WALL}, { [VIII] = {1,0}, [IVII] = {1,0}, [IIVI] = {2,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
		
	{ {DOOR,DOOR,WALL,WALL}, { [VIII] = {1,0}, [IVII] = {1,0}, [IIVI] = {3,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
		
	{ {DOOR,EMPTY,DOOR,WALL}, { [VIII] = {1,0}, [IVII] = {1,0}, [IIVI] = {1,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
	{ {DOOR,WALL,DOOR,WALL}, { [VIII] = {1,0}, [IVII] = {1,0}, [IIVI] = {1,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
	{ {DOOR,DOOR,DOOR,EMPTY}, { [VIII] = {1,0}, [IVII] = {1,0}, [IIVI] = {1,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
	{ {DOOR,DOOR,DOOR,WALL}, { [VIII] = {1,0}, [IVII] = {1,0}, [IIVI] = {1,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
	{ {DOOR,DOOR,DOOR,DOOR}, { [VIII] = {1,0}, [IVII] = {1,0}, [IIVI] = {1,0}, [IIIV] = {1,0}, [VVII] = {1,0}, [IVVI] = {1,0}, [IIVV] = {1,0}, [VIIV] = {1,0}, default = {1,0} } },
}

local function rmatch( input )
	local inputs = { [1] = {input[1],input[2],input[3],input[4]},
						[2] = {input[4],input[1],input[2],input[3]},
						[3] = {input[3],input[4],input[1],input[2]},
						[4] = {input[2],input[3],input[4],input[1]},}
	for _,pattern in pairs( patterns ) do
		for i = 1,4 do
			if inputs[i][1] == pattern[1][1] and inputs[i][2] == pattern[1][2] and inputs[i][3] == pattern[1][3] and inputs[i][4] == pattern[1][4] then
				return i, pattern
			end
		end
	end
end

local function addWallCapsToCell( cell, x, y, input, VB, UVInfo )
	local rotation, pattern = rmatch( input )
	if rotation and pattern then
		local wall_pattern = pattern[1]
		local vis_patterns = pattern[2]
		
		local cached_info = {}
		
		local geoInfo = {}
		for vis_mask=1,15 do
			local vis_pattern = vis_patterns[ vis_mask ] or (vis_patterns[ vis_mask ] == nil) and vis_patterns[ 'default' ]
			if vis_pattern then
				local geo_mask = rotate_value_bits( vis_mask, -(rotation-1) )
				local geo_type = vis_pattern[1]
				local geo_rot = (vis_pattern[2] + rotation - 1)%4 + 1
				
				local info = cached_info[geo_type] and cached_info[geo_type][geo_rot]
				if not info then
					info = {}
					local geo_pattern = geo_caps[geo_type][geo_rot]
					for i,view in ipairs( geo_pattern ) do
						local offset = #VB
						for _,stripe in ipairs( view.mainframe ) do
							addStripeToVB( VB, stripe, x, y, UVInfo )
						end
						local mainframe = { offset, #VB - offset }
						
						offset = #VB
						for _,stripe in ipairs( view.normal ) do
							addStripeToVB( VB, stripe, x, y, UVInfo )
						end
						local normal = { offset, #VB - offset }
						
						--print( 'geoCapInfo', x, y, geo_mask, geo_type, geo_rot, mainframe[1], mainframe[2], normal[1], normal[2] )
						info[i] = { mainframe = mainframe, normal = normal }
					end
					
					cached_info[geo_type] = cached_info[geo_type] or {}
					cached_info[geo_type][geo_rot] = info
				end
				geoInfo[ geo_mask ] = info
				
			end
		end
		cell._capsGeoInfo = geoInfo
	end
end
local function addWallToCell( cell, x, y, dir, type, VB, UVInfo ) --type is one of CL+CR, CL+WR, CL+DR, WL+CR, WL+WR, WL+DR, PL+CR, PL+WR, or PL+PR
	cell._wallGeoInfo = cell._wallGeoInfo or {}
	assert( cell._wallGeoInfo[dir] == nil )
	cell._wallGeoInfo[dir] = {}
	for geo_type, geo_info in pairs( geo_walls[dir][type] ) do --geo_type could be 'mainframe' geo_info is a stripe array
		assert( cell._wallGeoInfo[dir][geo_type] == nil )
		local offset = #VB
		for _,stripe in ipairs( geo_info ) do
			addStripeToVB( VB, stripe, x, y, UVInfo )
		end
		cell._wallGeoInfo[dir][geo_type] = { offset, #VB - offset }
	end
end
local function addDoorToCell( cell, x, y, dir, type, VB )
	local offsets = {}

	local offset = #VB
	for _,stripe in ipairs( geo_doors[dir][type].mainframe_locked ) do
		addStripeToVB( VB, stripe, x, y )
	end
	offsets.mainframe_locked = { offset, #VB - offset }

	offset = #VB
    for _,stripe in ipairs( geo_doors[dir][type].mainframe_unlocked ) do
		addStripeToVB( VB, stripe, x, y )
	end
	offsets.mainframe_unlocked = { offset, #VB - offset }

	offset = #VB
    for _,stripe in ipairs( geo_doors[dir][type].mainframe_open ) do
		addStripeToVB( VB, stripe, x, y )
	end
	offsets.mainframe_open = { offset, #VB - offset }

	offset = #VB
	for _,stripe in ipairs( geo_doors[dir][type].unlocked ) do
		addStripeToVB( VB, stripe, x, y )
	end
	offsets.unlocked = { offset, #VB - offset }

	offset = #VB
	for _,stripe in ipairs( geo_doors[dir][type].locked ) do
		addStripeToVB( VB, stripe, x, y )
	end
	offsets.locked = { offset, #VB - offset }

	offset = #VB
	for _,stripe in ipairs( geo_doors[dir][type].broken ) do
		addStripeToVB( VB, stripe, x, y )
	end
	offsets.broken = { offset, #VB - offset }

	cell._doorGeoInfo = cell._doorGeoInfo or {}
	assert( cell._doorGeoInfo[dir] == nil )
	cell._doorGeoInfo[dir] = offsets
end

local function generate3DWalls( boardRig )
	--print('generate3DWalls')
	top_color = boardRig._levelData.walltop_color or grey

	--Sample positions for wall types, each one can be nil, wall or door
	--      |E   F|
	--      |  n  |
	--  ----nw---ne----
	--   G  |  A  |  I
	--     w|D   B|e
	--   H  |  C  |  J
	--  ----sw---se----
	--      |  s  |
	--      |K   L|

	--Lets iterate over the board and fill out the VB with our vertices, keeping track of vertex offset and count for each cell
	local VB = {}
	local boardWidth, boardHeight = boardRig:getSim():getBoardSize()
	local C = 8
	local T1 = { A={C,N}, B={C,E}, C={C,S}, D={C,W}, E={N,W}, F={N,E}, G={W,N}, H={W,S}, I={E,N}, J={E,S}, K={S,W}, L={S,E} }
	local T2 = {[NW]={'A','D','G','E'},[NE]={'B','A','F','I'},[SE]={'C','B','J','L'},[SW]={'D','C','K','H'}}
	local T3 = { [N] = {'A',NW,NE,'D','B'}, [E] = {'B',NE,SE,'A','C'}, [S] = {'C',SE,SW,'B','D'}, [W] = {'D',SW,NW,'C','A'} } 
	local T4 = { [N] = {'A',NW,NE}, [E] = {'B',NE,SE} }
	local cells = {}
	for x= 0, boardWidth+1 do
		for y= 0, boardHeight+1 do
			local ccell = boardRig:getClientCellXY( x    , y     )	-- center cell
			if ccell then
				cells[C] = ccell
				cells[N] = boardRig:getClientCellXY( x    , y + 1 )	-- north cell
				cells[E] = boardRig:getClientCellXY( x + 1, y     ) -- east cell
				cells[S] = boardRig:getClientCellXY( x    , y - 1 ) -- south cell
				cells[W] = boardRig:getClientCellXY( x - 1, y     ) -- west cell
				cells[NE] = boardRig:getClientCellXY( x + 1, y + 1) -- north-east cell

				local w,d,b = {}, {}, {}
				for k,v in pairs( T1 ) do
					local cell = cells[ v[1] ]
					if cell then
						local side = cell:getSide( v[2] )
						w[ k ] = side and not side.door and true or false
						d[ k ] = side and side.door and true or false
						b[ k ] = w[k] or d[k]
					end
				end

				local posts = {}
				for k,v in pairs( T2 ) do
					local A,B,C,D = v[1], v[2], v[3], v[4]
					posts[k] = ((d[A] and (b[B] or w[C] or b[D])) or (d[B] and (b[C] or w[D] or b[A])) or (d[A] and not d[C]) or (not d[A] and d[C]) or (d[B] and not d[D]) or (not d[B] and d[D]) or (not b[A] and not b[B] and (b[C] or b[D])) ) and POST
					posts[k] = posts[k] or nil
				end

				local walls = {}
				for k,v in pairs( T3 ) do
					if w[v[1]] or d[v[1]] then
						local D = d[v[1]] and DOOR or WALL
						local L = posts[v[2]] and PL or w[v[4]] and WL or CL
						local R = posts[v[3]] and PR or w[v[5]] and WR or CR
						local value = D + L + R --compose the values, this works because the source number are shifted by a base
						assert( value < DOOR or value == DOOR+PL+PR or value == DOOR+CL+PR or value == DOOR+CL+CR or value == DOOR+PL+CR, value )
						walls[k] = value
					end
				end

				local doors = {}
				for k,v in pairs( T4 ) do
					if d[v[1]] then
						local L = posts[v[2]] and PL or CL
						local R = posts[v[3]] and PR or CR
						doors[k] = DOOR + L + R
					end
				end

				
				for dir,type in pairs( walls ) do
					addWallToCell( cells[C], x, y, dir, type, VB, { cells[C].tileIndex } )
				end
				for dir,type in pairs( doors ) do
					addDoorToCell( cells[C], x, y, dir, type, VB )
				end
				
				local capPattern =
				{
					[1] = (w.B and WALL) or (d.B and DOOR) or EMPTY,
					[2] = (w.A and WALL) or (d.A and DOOR) or EMPTY,
					[3] = (w.F and WALL) or (d.F and DOOR) or EMPTY,
					[4] = (w.I and WALL) or (d.I and DOOR) or EMPTY,
				}
				local UVInfo =
				{
					[1] = cells[N] and cells[N].tileIndex,
					[2] = cells[C] and cells[C].tileIndex,
					[3] = cells[E] and cells[C].tileIndex,
					[4] = cells[NE] and cells[NE].tileIndex,
				}
				addWallCapsToCell( cells[C], x, y, capPattern, VB, UVInfo )
			end
		end
	end

	--print( 'VB size', #VB )

	--Now we generate the actual vbo
	local vertexFormat = MOAIVertexFormat.new()
	vertexFormat:declareCoord	( 1, MOAIVertexFormat.GL_FLOAT, 3 )
	vertexFormat:declareNormal	( 2, MOAIVertexFormat.GL_FLOAT, 3 )
	vertexFormat:declareUV		( 3, MOAIVertexFormat.GL_FLOAT, 2 )
	vertexFormat:declareColor	( 4, MOAIVertexFormat.GL_UNSIGNED_BYTE )
	vertexFormat:declareColor	( 5, MOAIVertexFormat.GL_UNSIGNED_BYTE )

	local vbo = MOAIVertexBuffer.new()
	vbo:setFormat( vertexFormat )
	vbo:reserveVerts( #VB )
	for _,v in ipairs( VB ) do
		vbo:writeFloat   ( v[1][1],   v[1][2], v[1][3] )
		vbo:writeFloat   ( v[2][1],   v[2][2], v[2][3] )
		vbo:writeFloat   ( v[3][1],   v[3][2] )
		vbo:writeColor32 ( v[4][1],   v[4][2], v[4][3], v[4][4] )
		vbo:writeColor32 ( v[5][1],   v[5][2], v[5][3], v[5][4] )
	end
	vbo:bless()
	--print( '#VB = ', #VB)
	
	return vbo
end

-----------------------------------------------------
-- Interface functions

return
{
	generate3DWalls = generate3DWalls
}
