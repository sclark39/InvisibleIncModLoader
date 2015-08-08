----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local cdefs = include( "client_defs" )
local util = include( "client_util" )
local animdefs = include( "animdefs" )

local BoundType = animdefs.BoundType

--These delta coordinates are defined in facing=0 and orientation=0 space
--Orientation=0 means that +x is down-left, while +y is down-right
--As facing increments (we increment by 2 for each facing), we rotate CCW, hence facing=2 for bound_2x1_med_med would transform from from { {0,0}, {0,1} } to { {0,0}, {-1,0} }
local CellCoverage =
{
	[ BoundType.Character ]				= { {0,0} },
	[ BoundType.CharacterFloor ]		= { {0,0} },
	[ BoundType.Wall ]					= { {0,0} },
	[ BoundType.Wall_Painting ]			= { {0,0} },
	[ BoundType.WallFlip ]				= { {0,0} },
	[ BoundType.Wall2 ]					= { {0,0}, {0,-1} },
	[ BoundType.Wall3 ]					= { {0,0}, {0,-1}, {0,-2} },
	[ BoundType.Wall5 ]					= { {0,0}, {0,-1}, {0,-2}, {0,-3}, {0,-4} },	
	[ BoundType.bound_1x1_med_med ]		= { {0,0} },
	[ BoundType.bound_1x1_med_big ]		= { {0,0} },
	[ BoundType.bound_1x1_tall_med ]	= { {0,0} },
	[ BoundType.bound_1x1_verytall_med ]= { {0,0} },
	[ BoundType.bound_1x1_tall_big ]	= { {0,0} },
	[ BoundType.bound_2x1_med_med ]		= { {0,0}, {0,1} },
	[ BoundType.bound_2x1_tall_med ]	= { {0,0}, {0,1} },
	[ BoundType.bound_2x2 ]				= { {0,0}, {0,1}, {-1,0}, {-1,1} },
	[ BoundType.bound_2x3 ]				= { {0,0}, {0,1}, {0,2}, {-1,0}, {-1,-1}, {-1,2} },
	[ BoundType.bound_3x1_med_med ]		= { {0,0}, {0,1}, {0,2} },
	[ BoundType.bound_3x1_tall_med ]	= { {0,0}, {0,1}, {0,2} },	
	[ BoundType.bound_3x1_med_big ]		= { {0,0}, {0,1}, {0,2} },	
	[ BoundType.Ceiling_1x1 ]				=  { {0,0} },
	[ BoundType.Floor_1x1 ]				=  { {0,0} },
	[ BoundType.Floor_2x1 ]				=  { {0,0}, {0,1} },
	[ BoundType.Floor_1x2 ]				=  { {0,0}, {1,0} },
	[ BoundType.Floor_2x2 ]				=  { {0,0}, {0,1}, {-1,0}, {-1,1} },
	[ BoundType.Floor_2x3 ]				=  { {0,0}, {0,1}, {0,2}, {-1,0}, {-1,-1}, {-1,2} },	
	[ BoundType.Floor_2x4 ]				=  { {0,0}, {0,1}, {0,2}, {0,3}, {-1,0}, {-1,-1}, {-1,2}, {-1,3} },	
	[ BoundType.Floor_3x2 ]				=  { {0,0}, {0,1}, {-1,0}, {-1,1}, {-2,0}, {-2,1} },
	[ BoundType.Floor_3x3 ]				=  { {0,0}, {0,1}, {0,2}, {-1,0}, {-1,1}, {-1,2}, {-2,0}, {-2,1}, {-2,2} },
	[ BoundType.Floor_4x3 ]				=  { {0,0}, {0,1}, {0,2}, {0,3}, {-1,0}, {-1,1}, {-1,2}, {-1,3}, {-2,0}, {-2,1}, {-2,2}, {-2,3} },
	[ BoundType.Floor_3x4 ]				=  { {0,0}, {0,1}, {0,2}, {-1,0}, {-1,1}, {-1,2}, {-2,0}, {-2,1}, {-2,2}, {-3,0}, {-3,1}, {-3,2} },
	[ BoundType.Floor_4x4 ]				=  { {0,0}, {0,1}, {0,2}, {0,3}, {-1,0}, {-1,1}, {-1,2}, {-1,3}, {-2,0}, {-2,1}, {-2,2}, {-2,3}, {-3,0}, {-3,1}, {-3,2}, {-3,3} },	
}

-----------------------------------------------------------------------
-- Iso specifications for common layouts.

local iso_dim = cdefs.BOARD_TILE_SIZE * 4
local character_dim = iso_dim/1.23 -- characters need to be scaled up 23% to match the ISO blocks

local A1 = 0.3     -- cube foot size
local A2 = 0.43  

local B = 0.44     -- wall outside
local C = 0.445		-- wall facing wall side

local D0 = 0.010 	-- super low
local D1 = 1 		-- height medium
local D2 = 1.3 		-- height tall 
local D3 = 2 		-- height tall 

local E = 0.5 		-- height from floor ( for things like paintings. )

local Bounds = {}
Bounds[ BoundType.Wall ] =
 --{ mx = -A, my = -A, mz = 0, MX = A, MY = A, MZ = 1, iso_dim = iso_dim }
 {
	[4] = { mx = B, my = -A2, mz = 0, MX = C, MY = A2, MZ = 3, iso_dim = iso_dim },
	[6] = { mx = -A2, my = B, mz = 0, MX = A2, MY = C, MZ = 3, iso_dim = iso_dim },
	[0] = { mx = -C, my = -A2, mz = 0, MX = -B, MY = A2, MZ = 3, iso_dim = iso_dim },
	[2] = { mx = -A2, my = -C, mz = 0, MX = A2, MY = -B, MZ = 3, iso_dim = iso_dim },
}

Bounds[ BoundType.Wall_Painting ] =
 --{ mx = -A, my = -A, mz = 0, MX = A, MY = A, MZ = 1, iso_dim = iso_dim }
 {
	[4] = { mx = B, my = -A2, mz = E, MX = C, MY = A2, MZ = 3, iso_dim = iso_dim },
	[6] = { mx = -A2, my = B, mz = E, MX = A2, MY = C, MZ = 3, iso_dim = iso_dim },
	[0] = { mx = -C, my = -A2, mz = E, MX = -B, MY = A2, MZ = 3, iso_dim = iso_dim },
	[2] = { mx = -A2, my = -C, mz = E, MX = A2, MY = -B, MZ = 3, iso_dim = iso_dim },
}

Bounds[ BoundType.WallFlip ] =
 --{ mx = -A, my = -A, mz = 0, MX = A, MY = A, MZ = 1, iso_dim = iso_dim }
 {
	[4] = { mx = -B, my = -A1, mz = 0, MX = -C, MY = A1, MZ = 3, iso_dim = iso_dim },
	[6] = { mx = -A1, my = -B, mz = 0, MX = A1, MY = -C, MZ = 3, iso_dim = iso_dim },
	[0] = { mx = C, my = -A1, mz = 0, MX = B, MY = A1, MZ = 3, iso_dim = iso_dim },
	[2] = { mx = -A1, my = C, mz = 0, MX = A1, MY = B, MZ = 3, iso_dim = iso_dim },
}

Bounds[ BoundType.Wall2 ] =
{
	[4] = { mx = B, my = -A2, mz = 0, MX = C, MY = (A2+1), MZ = 2, iso_dim = iso_dim },
	[6] = { mx = -(A2+1), my = B, mz = 0, MX = A1, MY = C, MZ = 2, iso_dim = iso_dim },
	[0] = { mx = -C, my = -(A2+1), mz = 0, MX = -B, MY = A2, MZ = 2, iso_dim = iso_dim },
	[2] = { mx = -A2, my = -C, mz = 0, MX = (A2+1), MY = -B, MZ = 2, iso_dim = iso_dim },
}
Bounds[ BoundType.Wall3 ] =
{
	[4] = { mx = B, my = -A2, mz = 0, MX = C, MY = (A2+2), MZ = 2, iso_dim = iso_dim },
	[6] = { mx = -(A2+2), my = B, mz = 0, MX = A1, MY = C, MZ = 2, iso_dim = iso_dim },
	[0] = { mx = -C, my = -(A2+2), mz = 0, MX = -B, MY = A2, MZ = 2, iso_dim = iso_dim },
	[2] = { mx = -A2, my = -C, mz = 0, MX = (A2+2), MY = -B, MZ = 2, iso_dim = iso_dim },
}

Bounds[ BoundType.Wall5 ] =
{
	[4] = { mx = B, my = -A2, mz = 0, MX = C, MY = (A2+4), MZ = 3, iso_dim = iso_dim },
	[6] = { mx = -(A2+4), my = B, mz = 0, MX = A1, MY = C, MZ = 3, iso_dim = iso_dim },
	[0] = { mx = -C, my = -(A2+4), mz = 0, MX = -B, MY = A2, MZ = 3, iso_dim = iso_dim },
	[2] = { mx = -A2, my = -C, mz = 0, MX = (A2+4), MY = -B, MZ = 3, iso_dim = iso_dim },
}

Bounds[ BoundType.Character ] = { mx = -A2, my = -A2, mz = 0.1, MX = A2, MY = A2, MZ = 2, iso_dim = character_dim }
Bounds[ BoundType.CharacterFloor ] = { mx = -A1 * 0.8, my = -A1 * 0.8, mz = 0, MX = A1*0.8, MY = A1*0.8, MZ = 0.05, iso_dim = character_dim }


Bounds[ BoundType.bound_1x1_med_med ] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY = A1, MZ = D1, iso_dim = iso_dim }

Bounds[ BoundType.bound_1x1_med_big ] = { mx = -A2, my = -A2, mz = 0, MX = A2, MY = A2, MZ = D1, iso_dim = iso_dim }

Bounds[ BoundType.bound_1x1_tall_med ] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY = A1, MZ = D3, iso_dim = iso_dim }

Bounds[ BoundType.bound_1x1_verytall_med ] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY = A1, MZ = D3, iso_dim = iso_dim }

Bounds[ BoundType.bound_1x1_tall_big ] = { mx = -A2, my = -A2, mz = 0, MX = A2, MY = A2, MZ = D3, iso_dim = iso_dim }

Bounds[ BoundType.bound_2x1_med_med ] =
{
	[0] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY = (A1+1), MZ = D1, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  0, frontY =  1 },
	[2] = { mx = -(A1+1), my = -A1, mz = 0, MX = A1, MY = A1, MZ = D1, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+1), mz = 0, MX = A1, MY =A1, MZ = D1, iso_dim = iso_dim, backX =  0, backY = -1, frontX =  0, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+1), MY = A1, MZ = D1, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  0 },
}

Bounds[ BoundType.bound_2x1_tall_med ] =
{
	[0] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY = (A1+1), MZ = D2, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  0, frontY =  1 },
	[2] = { mx = -(A1+1), my = -A1, mz = 0, MX = A1, MY = A1, MZ = D2, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+1), mz = 0, MX = A1, MY =A1, MZ = D2, iso_dim = iso_dim, backX =  0, backY = -1, frontX =  0, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+1), MY = A1, MZ = D2, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  0 },
}

Bounds[ BoundType.bound_2x2 ] =
{
	[0] = { mx = -(A1+1), my = -A1, mz = 0, MX = A1, MY = (A1+1), MZ = D3, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  1 },
	[2] = { mx = -(A1+1), my = -(A1+1), mz = 0, MX = A1, MY = A1, MZ = D3, iso_dim = iso_dim, backX = -1, backY = -1, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+1), mz = 0, MX = (A1+1), MY = A1, MZ = D3, iso_dim = iso_dim, backX =  0, backY = -1, frontX =  1, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+1), MY = (A1+1), MZ = D3, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  1 },
}
Bounds[ BoundType.bound_2x3 ] =
{
	[0] = { mx = -(A1+1), my = -A1, mz = 0, MX = A1, MY = (A1+2), MZ = 1, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  2 },
	[2] = { mx = -(A1+2), my = -(A1+1), mz = 0, MX = A1, MY = A1, MZ = 1, iso_dim = iso_dim, backX = -2, backY = -1, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+2), mz = 0, MX = (A1+1), MY = A1, MZ = 1, iso_dim = iso_dim, backX =  0, backY = -2, frontX =  1, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+2), MY = (A1+1), MZ = 1, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  2, frontY =  1 },
}


Bounds[ BoundType.bound_3x1_med_med ] =
{
	[0] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY = (A1+2), MZ = D1, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  0, frontY =  1 },
	[2] = { mx = -(A1+2), my = -A1, mz = 0, MX = A1, MY = A1, MZ = D1, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+2), mz = 0, MX = A1, MY =A1, MZ = D1, iso_dim = iso_dim, backX =  0, backY = -1, frontX =  0, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+2), MY = A1, MZ = D1, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  0 },
}


Bounds[ BoundType.bound_3x1_tall_med ] =
{
	[0] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY = (A1+2), MZ = D3, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  0, frontY =  1 },
	[2] = { mx = -(A1+2), my = -A1, mz = 0, MX = A1, MY = A1, MZ = D3, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+2), mz = 0, MX = A1, MY =A1, MZ = D3, iso_dim = iso_dim, backX =  0, backY = -1, frontX =  0, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+2), MY = A1, MZ = D3, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  0 },
}

Bounds[ BoundType.bound_3x1_med_big ] =
{
	[0] = { mx = -A2, my = -A2, mz = 0, MX = A2, MY = (A2+2), MZ = D1, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  0, frontY =  1 },
	[2] = { mx = -(A2+2), my = -A2, mz = 0, MX = A2, MY = A2, MZ = D1, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  0 },
	[4] = { mx = -A2, my = -(A2+2), mz = 0, MX = A2, MY =A2, MZ = D1, iso_dim = iso_dim, backX =  0, backY = -1, frontX =  0, frontY =  0 },
	[6] = { mx = -A2, my = -A2, mz = 0, MX = (A2+2), MY = A2, MZ = D1, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  0 },
}

Bounds[ BoundType.Ceiling_1x1 ] = { mx = -A1, my = -A1, mz = D2, MX = A1, MY = A1, MZ = D3, iso_dim = iso_dim }

Bounds[ BoundType.Floor_1x1 ] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim }

Bounds[ BoundType.Floor_2x1 ] =
{
	[0] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY = (A1+1), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  0, frontY =  1 },
	[2] = { mx = -(A1+1), my = -A1, mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+1), mz = 0, MX = A1, MY =A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY = -1, frontX =  0, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+1), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  0 },
}

Bounds[ BoundType.Floor_1x2 ] =
{
	[0] = { mx = -A1, my = -A1, mz = 0, MX =(A1+1), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  0 },
	[2] = { mx = -A1, my = -(A1+1), mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = 0, backY =  -1, frontX =  0, frontY =  0 },
	[4] = { mx = -(A1+1), my = -A1, mz = 0, MX = A1, MY =A1, MZ = D0, iso_dim = iso_dim, backX =  -1, backY = 0, frontX =  0, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = A1, MY =  (A1+1), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  0, frontY =  1 },
}

Bounds[ BoundType.Floor_2x2 ] =
{
	[0] = { mx = -(A1+1), my = -A1, mz = 0, MX = A1, MY = (A1+1), MZ = D0, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  1 },
	[2] = { mx = -(A1+1), my = -(A1+1), mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = -1, backY = -1, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+1), mz = 0, MX = (A1+1), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY = -1, frontX =  1, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+1), MY = (A1+1), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  1 },
}

Bounds[ BoundType.Floor_2x3 ] =
{
	[0] = { mx = -(A1+1), my = -A1, mz = 0, MX = A1, MY = (A1+2), MZ = D0, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  2 },
	[2] = { mx = -(A1+2), my = -(A1+1), mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = -2, backY = -1, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+2), mz = 0, MX = (A1+1), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY = -2, frontX =  1, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+2), MY = (A1+1), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  2, frontY =  1 },
}

Bounds[ BoundType.Floor_2x4 ] =
{
	[0] = { mx = -(A1+1), my = -A1, mz = 0, MX = A1, MY = (A1+3), MZ = D0, iso_dim = iso_dim, backX = -1, backY =  0, frontX =  0, frontY =  3 },
	[2] = { mx = -(A1+3), my = -(A1+1), mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = -3, backY = -1, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+3), mz = 0, MX = (A1+1), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY = -3, frontX =  1, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+3), MY = (A1+1), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  3, frontY =  1 },
}

Bounds[ BoundType.Floor_3x2 ] =
{
	[0] = { mx = -(A1+2), my = -A1, mz = 0, MX = A1, MY = (A1+1), MZ = D0, iso_dim = iso_dim, backX = -2, backY =  0, frontX =  0, frontY =  1 },
	[2] = { mx = -(A1+1), my = -(A1+2), mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = -1, backY = -2, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+1), mz = 0, MX = (A1+2), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY = -1, frontX =  2, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+1), MY = (A1+2), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  1, frontY =  2 },
}

Bounds[ BoundType.Floor_3x3 ] =
{
	[0] = { mx = -(A1+2), my = -A1, mz = 0, MX = A1, MY = (A1+2), MZ = D0, iso_dim = iso_dim, backX = -2, backY =  0, frontX =  0, frontY =  2 },
	[2] = { mx = -(A1+2), my = -(A1+2), mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = -2, backY = -2, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+2), mz = 0, MX = (A1+2), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY = -2, frontX =  2, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+2), MY = (A1+2), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  2, frontY =  2 },
}

Bounds[ BoundType.Floor_4x3 ] =
{
	[0] = { mx = -(A1+3), my = -A1, mz = 0, MX = A1, MY = (A1+2), MZ = D0, iso_dim = iso_dim, backX = -3, backY =  0, frontX =  0, frontY =  3 },
	[2] = { mx = -(A1+2), my = -(A1+3), mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = -3, backY = -3, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+2), mz = 0, MX = (A1+3), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY = -3, frontX =  3, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+2), MY = (A1+3), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  3, frontY =  3 },
}

Bounds[ BoundType.Floor_3x4 ] =
{
	[0] = { mx = -(A1+2), my = -A1, mz = 0, MX = A1, MY = (A1+3), MZ = D0, iso_dim = iso_dim, backX = -2, backY =  0, frontX =  0, frontY =  3 },
	[2] = { mx = -(A1+3), my = -(A1+2), mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = -3, backY = -2, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+3), mz = 0, MX = (A1+2), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY = -3, frontX =  2, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+3), MY = (A1+2), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  3, frontY =  2 },
}

Bounds[ BoundType.Floor_4x4 ] =
{
	[0] = { mx = -(A1+3), my = -A1, mz = 0, MX = A1, MY = (A1+3), MZ = D0, iso_dim = iso_dim, backX = -3, backY =  0, frontX =  0, frontY =  3 },
	[2] = { mx = -(A1+3), my = -(A1+3), mz = 0, MX = A1, MY = A1, MZ = D0, iso_dim = iso_dim, backX = -3, backY = -3, frontX =  0, frontY =  0 },
	[4] = { mx = -A1, my = -(A1+3), mz = 0, MX = (A1+3), MY = A1, MZ = D0, iso_dim = iso_dim, backX =  0, backY = -3, frontX =  3, frontY =  0 },
	[6] = { mx = -A1, my = -A1, mz = 0, MX = (A1+3), MY = (A1+3), MZ = D0, iso_dim = iso_dim, backX =  0, backY =  0, frontX =  3, frontY =  3 },
}

local function lookupAnimDef( name )
	return animdefs.defs[ name ]
end

local function refreshIsoBounds( prop, kanim, facing )
	local boundType = kanim.boundType or BoundType.OneByOne
	local bounds = Bounds[ boundType ]
	if facing and bounds[ facing ] then
		bounds = bounds[ facing ]
	end

	if kanim.boundTypeOverrides then
		for i,set in ipairs(kanim.boundTypeOverrides) do
			if set.anim == prop:getCurrentAnim() then
				bounds = Bounds[ set.boundType ]
				break
			end
		end
	end

	local mx, my, mz, MX, MY, MZ = bounds.mx, bounds.my, bounds.mz, bounds.MX, bounds.MY, bounds.MZ
	local iso_dim = bounds.iso_dim
	prop:setBounds( mx * iso_dim, my * iso_dim, mz * iso_dim, MX * iso_dim, MY * iso_dim, MZ * iso_dim )
end

local function orientVector( orientation, dx, dy )
	if orientation == 0 then
		return  dx, dy
	elseif orientation == 1 then
		return -dy, dx
	elseif orientation == 2 then
		return -dx, -dy
	elseif orientation == 3 then
		return  dy, -dx
	end
end

local function refreshPropPivot( prop, animdef, facing, orientation, front, boundType)
	local oriented_facing = (facing - orientation*2 ) % 8
	local oriented_bounds = Bounds[ animdef.boundType ][ oriented_facing ] or Bounds[ animdef.boundType ]
	local cx, cy
	if front then
		cx = oriented_bounds.frontX or 0
		cy = oriented_bounds.frontY or 0
	else
		cx = oriented_bounds.backX or 0
		cy = oriented_bounds.backY or 0
	end	

	cx, cy = orientVector( orientation, cx, cy )
	local dx, dy = cx*1 + cy*-1, cx*-1 + cy*-1
	dx, dy = orientVector( orientation, dx, dy )
	prop:setPiv( -dx*84, dy*48 )


	local e = 0.0
	local bounds = Bounds[ animdef.boundType ][ facing ] or Bounds[ animdef.boundType ]
	local mx, my, mz, MX, MY, MZ = bounds.mx + e - cx, bounds.my + e - cy, bounds.mz, bounds.MX - e - cx, bounds.MY - e - cy, bounds.MZ
	prop:setBounds( mx * iso_dim, my * iso_dim, mz * iso_dim, MX * iso_dim, MY * iso_dim, MZ * iso_dim )
	
	return cx,cy
end

local function getPropCellCoverage( animdef, facing )
	local cellCoverage = CellCoverage[ animdef.boundType ]
	local transformedTbl = {}
	for i,v in ipairs(cellCoverage) do
		transformedTbl[i] = { orientVector( facing/2, v[1], v[2] ) }
	end
	return transformedTbl
end

local function createXPropFromAnimDef( kanim, name )
	local prop = KLEIAnimX.new()
	prop:setDebugName(name)
	if type(kanim.build) == "table" then
		for i,build in ipairs(kanim.build) do
			local build = string.gsub( build, "data/anims/characters/", "data/xanims/characters/" )
			build = string.gsub( build, ".abld", ".xanm" )
			print('bindBuild', build)
			prop:bindBuild( KLEIResourceMgr.GetResource(build) )
		end
	else
		local build = string.gsub( kanim.build, "data/anims/characters/", "data/xanims/characters/" )
		build = string.gsub( build, ".abld", ".xanm" )
		print('bindBuild', build)
		prop:bindBuild( KLEIResourceMgr.GetResource(build) )
	end
	for _,v in ipairs(kanim.wireframe or {}) do
		local build = string.gsub( v, "data/anims/characters/", "data/xanims/characters/" )
		build = string.gsub( build, ".abld", ".xanm" )
		print('bindWireframe', build)
		prop:bindWireframeBuild( KLEIResourceMgr.GetResource(build) )
	end
	for i,v in ipairs(kanim.anims) do
		local build = string.gsub( v, "data/anims/characters/", "data/xanims/characters/" )
		build = string.gsub( build, ".adef", ".xanm" )
		print('bindAnim', build)
		prop:bindAnim( KLEIResourceMgr.GetResource(build) )
	end
	if kanim.symbol then
		prop:setCurrentSymbol( kanim.symbol )
	end
	prop:setCurrentAnim( kanim.anim or "idle" )
	prop:setCurrentFacingMask(KLEIAnim.FACING_E)
	prop:setScl(kanim.scale, kanim.scale, kanim.scale)
	prop:setBillboard( MOAIProp.FLAGS_QUASI_BILLBOARD )
	prop:setDepthTest( false )
	prop:setDepthMask( false )

	return prop, kanim
end

local function createPropFromAnimDef( name )
	local kanim = lookupAnimDef( name )
	if kanim then
		if gSupportNewXANIM and kanim.anims_1h then
			return createXPropFromAnimDef( kanim, name )
		end
		local prop = KLEIAnim.new()
		prop:setDebugName(name)
		if type(kanim.build) == "table" then
			for i,build in ipairs(kanim.build) do
				prop:bindBuild( KLEIResourceMgr.GetResource(build) )
			end
		else
			prop:bindBuild( KLEIResourceMgr.GetResource(kanim.build) )
		end
		for _,v in ipairs(kanim.wireframe or {}) do
			prop:bindWireframeBuild( KLEIResourceMgr.GetResource(v) )
		end
		for i,v in ipairs(kanim.anims) do
			prop:bindAnim( KLEIResourceMgr.GetResource(v) )
		end
		if kanim.symbol then
			prop:setCurrentSymbol( kanim.symbol )
		end
		prop:setCurrentAnim( kanim.anim or "idle" )
		prop:setCurrentFacingMask(KLEIAnim.FACING_E)
		prop:setScl(kanim.scale, kanim.scale, kanim.scale)
		prop:setBillboard( MOAIProp.FLAGS_QUASI_BILLBOARD )
		prop:setDepthTest( false )
		prop:setDepthMask( false )

		return prop, kanim
	else
		log:write("Could not find anim: '%s'", tostring(name) )
	end
end

local function createSkinsTable()
	local allSkins = {}
	for name, kanim in pairs( animdefs.defs ) do
		if kanim.skins then
			for i, skinName in ipairs(kanim.skins) do
				if allSkins[ skinName ] == nil then
					allSkins[ skinName ] = { boundType = kanim.boundType }
				end
				table.insert( allSkins[ skinName ], name )
				-- Ensure the properties are the same.
				assert( kanim.boundType == allSkins[ skinName ].boundType )
			end
		end
	end
	return allSkins
end

local anim_skins = createSkinsTable()

local function lookupAnimSkin( skinName, skinIdx )
	local skins = anim_skins[ skinName ]
	local kanimName = nil
	if skins then
		kanimName = skins[ (skinIdx % #skins) + 1 ]
	end
	if kanimName == nil then
		log:write( "Could not skin anim: '%s[%d]'", skinName, skinIdx )
	end
	return kanimName
end

return
{
	anim_skins = anim_skins, -- For debug access

	orientVector = orientVector,
	lookupAnimDef = lookupAnimDef,
	createPropFromAnimDef = createPropFromAnimDef,
	refreshIsoBounds = refreshIsoBounds,
	refreshPropPivot = refreshPropPivot,
	getPropCellCoverage = getPropCellCoverage,
	lookupAnimSkin = lookupAnimSkin,
}