----------------------------------------------------------------
-- Copyright (c) 2014 Klei Entertainment Inc.
-- All Rights Reserved.
-- INVISIBLE INC.
----------------------------------------------------------------

local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")

local baseAnim = class()
function baseAnim:init( bgrig, idx, type, symbol, baseRotation, screenAligned )
	local boardRig = bgrig._boardRig
	local simCore = boardRig._game.simCore
	local animDef = KLEIResourceMgr.GetResource( "data/anims/fx/background_void.adef" )
	local animBld = KLEIResourceMgr.GetResource( "data/anims/fx/background_void.abld" )
	local boardWidth, boardHeight = simCore:getBoardSize()

	local anim = KLEIAnim.new()
	self._boardRig = boardRig

	self._x = math.random( -boardWidth, boardWidth ) * 2 * cdefs.BOARD_TILE_SIZE
	self._y = math.random( -boardHeight, boardHeight ) * 2 * cdefs.BOARD_TILE_SIZE
	self._baseRotation = baseRotation
	self._symbol = symbol
	self._anim = anim
	self._type = type
	self._screenAligned = screenAligned
	self._layer = boardRig:getLayer( screenAligned and "void_fx1" or "void_fx2" )

	anim:bindAnim( animDef )
	anim:bindBuild( animBld )
	anim:setCurrentSymbol( symbol )
	anim:setCurrentAnim( "anim" )
	anim:setPlayMode( KLEIAnim.ONCE );
	anim:setDepthTest( false )
	anim:setDepthMask( false )
	anim:setLoc( self._x, self._y )
	anim:setSymbolModulate( "", unpack(self.PRIMARY_COLOR ) )

	local x0, y0, x1, y1 = anim:getExtents()
	anim:setBounds( x0, y0, 0, x1, y1, 0 )

	anim:setListener( KLEIAnim.EVENT_ANIM_END, function( anim ) bgrig:destroyElement( self, idx ) end )

	anim:forceUpdate()

	self._layer:insertProp( anim )
end
function baseAnim:destroy()
	self._layer:removeProp( self._anim )
	self._layer = nil
	self._boardRig = nil
	self._type = nil
end

local ROTATIONS =
{
	[0] = 180,
	[1] = 270,
	[2] = 0,
	[3] = 90,
}

function baseAnim:refresh( color )
	local orientation = self._screenAligned and 2 or self._boardRig._game:getCamera():getOrientation()
	local rotation = ROTATIONS[ orientation ] + self._baseRotation
	self._anim:setRot( 0, 0, rotation )
	if color then
		self._anim:setSymbolModulate( "", unpack(color) )
	end
	self._anim:forceUpdate()
end
function baseAnim:lerpColors( lerp )
	local pr,pg,pb,pa = unpack( self.PRIMARY_COLOR )
	local sr,sg,sb,sa = unpack( self.SECONDARY_COLOR )

	local r = (1-lerp) * pr + lerp * sr
	local g = (1-lerp) * pg + lerp * sg
	local b = (1-lerp) * pb + lerp * sb
	local a = (1-lerp) * pa + lerp * sa

	self._anim:setSymbolModulate( "", r, g, b, a )
end

function baseAnim:randomize()
	local frameCount = self._anim:getFrameCount()
	self._anim:setFrame( math.random(0, frameCount-1 ) )
	self._anim:forceUpdate()
end

local screenAnim = class( baseAnim )
screenAnim.PRIMARY_COLOR = {140/255,1,1, 0.3 }
screenAnim.SECONDARY_COLOR = { 1,50/255,50/255, 0.6 }

function screenAnim:init( bgrig, idx )
	local symbol = "screensAnim" .. math.random(1,16)
	baseAnim.init( self, bgrig, idx, "screenAnim", symbol, 0, false )
	self._anim:setScl( 0.4, 0.4, 0.4 )
	self:refresh()
end

local fileAnim = class( baseAnim )
fileAnim.PRIMARY_COLOR = {140/255,1,1, 0.4 }
fileAnim.SECONDARY_COLOR = { 1,50/255,50/255, 0.9 }

function fileAnim:init( bgrig, idx )
	local symbol = "file_anim" .. math.random(0,3)
	baseAnim.init( self, bgrig, idx, "fileAnim", symbol, 0, false )
	self._anim:setScl( 0.1, 0.1, 0.1 )
	self:refresh()
end

local lineAnim = class( baseAnim )
lineAnim.PRIMARY_COLOR =  {140/255,1,1,0.3}
lineAnim.SECONDARY_COLOR =  {1,50/255,50/255,0.6}

function lineAnim:init( bgrig, idx )
	local baseRotation = 0
	if( math.random( 0, 1 ) > 0.5 ) then
		baseRotation = 60 -- -45 for world aligned...
	end
	baseAnim.init( self, bgrig, idx, "lineAnim", "lineDrop", baseRotation, true )
	self._anim:setScl(1,1,1)
	self:refresh()
end


local CHANCE_FUNCTIONS =
{
	{30, screenAnim },
	{180, fileAnim },
	{2,	lineAnim },
}
	
local function createRandomElement( bgrig, idx )	
	local sum = 0;
	for _,v in ipairs( CHANCE_FUNCTIONS ) do
		sum = sum + v[1]
	end

	local r = math.random( 1, sum )

	sum = 0
	for k,v in ipairs( CHANCE_FUNCTIONS ) do
		sum = sum + v[1]
		if r <= sum then
			return v[2]( bgrig, idx )
		end
	end
	assert(false)
end

local _rig = class(  )
function _rig:init( boardRig )
	self._boardRig = boardRig
	self._elements = {}
	self._colorLerpPosition = 0
	self._colorLerpDelta = 0

	
	for i = 1,1500,1 do
		self._elements[i] = createRandomElement( self, i )
		self._elements[i]:randomize()
	end
	
end
function _rig:destroy()
	if not self._elements then return end
	for k,v in ipairs( self._elements ) do
		v:destroy()
	end
	self._elements = nil
end
function _rig:destroyElement( element, idx )
	assert( self._elements[ idx ] == element )
	element:destroy()
	element = createRandomElement( self, idx )
	element:lerpColors( self._colorLerpPosition )
	self._elements[ idx ] = element
end
function _rig:refresh( bPrimary )
	if not self._elements then return end
	for k,v in ipairs( self._elements ) do
		if bPrimary then
			v:refresh( v.PRIMARY_COLOR )
		else
			v:refresh( v.SECONDARY_COLOR )
		end
	end

	self._colorLerpPosition = 0
	self._colorLerpDelta = 0
end

function _rig:update()

	local newLerp = self._colorLerpPosition + self._colorLerpDelta
	if newLerp > 1 then
		newLerp = 1
		self._colorLerpDelta = 0
	elseif newLerp < 0 then
		newLerp = 0
		self._colorLerpDelta = 0
	end

	if newLerp ~= self._colorLerpPosition then
		for k,v in ipairs( self._elements ) do
			v:lerpColors( newLerp )
		end
	end

	self._colorLerpPosition = newLerp
end
function _rig:transitionColor( bPrimary, frameCount )
	local target = bPrimary and 0 or 1
	self._colorLerpDelta = (target - self._colorLerpPosition) / frameCount
end

return _rig