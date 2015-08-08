-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_component = require( "mui/widgets/mui_component" )
require( "class" )

--------------------------------------------------------

local DEFAULT_IMAGE = "default.png"
local EMPTY_IMAGE = "empty.png"

local function loadImage( screen, imageState )
	local img = { name = imageState.name, color = imageState.color }
	if imageState.file and #imageState.file > 0 then
		local imagefile = screen:resolveFilename( imageState.file )
		if not KLEIResourceMgr.GetResource( imagefile ) then
			imagefile = screen:resolveFilename( DEFAULT_IMAGE )
		end
		
		img.image = imagefile
	else
		img.image = screen:resolveFilename( EMPTY_IMAGE )
	end

	return img
end

local function loadImages( screen, imageFiles )

	local images = {}
	if type(imageFiles) == "string" then
		images[1] = loadImage( screen, { file = imageFiles })
	elseif type(imageFiles) == "table" then
		for i,imageState in ipairs(imageFiles) do
			images[i] = loadImage( screen, imageState )
		end
	end

	return images
end

local function createImage( images )

	local gfxQuad = MOAIGfxQuad2D.new ()
	gfxQuad:setUVRect ( 0, 0, 1, 1 )

	local prop = MOAIProp2D.new ()
	prop:setDepthMask( false )
	prop:setBlendMode( MOAIProp.BLEND_NORMAL )

	return prop, gfxQuad
end

local function createLoopImage( images, w, h, tilew, tileh )

	local gfxQuad = MOAIGfxQuad2D.new ()
	gfxQuad:setTexture( images[1].image )
	gfxQuad:setUVRect ( 0, 0, 1, 1 )
	gfxQuad:setRect( -0.5, 0.5, 0.5, -0.5 )

	local grid = MOAIGrid.new ()
	grid:setSize ( tilew, tileh, w, h, 0, 0 )
	for x = 1, tilew do
		for y = 1, tileh do
			grid:setTile( x, y, 1 )
		end
	end

	local prop = MOAIProp2D.new ()
	prop:setDepthMask( false )
	prop:setBlendMode( MOAIProp.BLEND_NORMAL )
	prop:setGrid( grid )
	if images[1] then
		prop:setDeck( gfxQuad )
	end

	return prop, gfxQuad, grid
end

local function createAnim( def )
	local buildFile = "data/anims/" .. def.animfile .. ".abld"
	local animFile = "data/anims/" .. def.animfile.. ".adef" 

	KLEIResourceMgr.LoadResource( buildFile )
	KLEIResourceMgr.LoadResource( animFile )
	
	local prop = KLEIAnim.new()
	prop:bindBuild( KLEIResourceMgr.GetResource( buildFile ) )
	prop:bindAnim( KLEIResourceMgr.GetResource( animFile ) )
	prop:setCurrentSymbol( def.symbol )
	prop:setCurrentAnim( def.anim )
	prop:setCurrentFacingMask(KLEIAnim.FACING_E)
	prop:setBillboard(true)
	prop:setPlayMode( KLEIAnim.LOOP )
	if def.color then
		prop:setSymbolModulate( "", unpack( def.color ))
	end

	return prop
end

--------------------------------------------------------

local mui_texture = class( mui_component )

function mui_texture:init( screen, def )

	self._screen = screen

	local prop
	if def.anim then
		prop = createAnim( def )
	else
		self._images = loadImages( screen, def.images )

		if def.tilew and def.tileh then
			prop, self._deck, self._grid = createLoopImage( self._images, def.w, def.h, def.tilew, def.tileh )
			self._tilew, self._tileh = def.tilew, def.tileh
			self._tileOffsetX, self._tileOffsetY = 0, 0 -- Offset in normalized tile coordinates.
		else
			prop, self._deck = createImage( self._images )
		end
	end
	
	if def.scissor then
		self._scissor = MOAIScissorRect.new()
		self._scissor:setAttrLink(MOAIProp.INHERIT_TRANSFORM, prop, MOAIProp.TRANSFORM_TRAIT)
		self._scissorRect = def.scissor
		prop:setScissorRect( self._scissor )
	end

	mui_component.init( self, prop, def )
    
    if self._images and self._images[1] then
        self:setImageIndex( 1 )
    end
end

function mui_texture:setRotation( angle )
	self._r = angle
	self:refreshProp()
end


function mui_texture:refreshProp()
	if self._screen == nil then
		return
	end

	local x, y, w, h = self:calculateBounds()

	if self._deck then
		self._prop:setLoc( x, y )

		if self._r then
			self._prop:setRot(self._r)
		end

		if self._grid then
			self._grid:setSize ( self._tilew, self._tileh, w / self._tilew, h / self._tileh, -w/2 + self._tileOffsetX*w, -h/2 + self._tileOffsetY*h )
			for x = 1, self._tilew do
				for y = 1, self._tileh do
					self._grid:setTile( x, y, 1 )
				end
			end
		else
			self._deck:setRect( -w/2, h/2, w/2, -h/2 )
		end
		if self._scissor then
			local x0, y0, x1, y1 = unpack( self._scissorRect )
			self._scissor:setRect( x0 * w, y0 * h, x1 * w, y1 * h )
			self._scissor:forceUpdate()
		end

	else
		-- AABB in UI space.
		local x0, y0, x1, y1
		if self._scissor then
			x0, y0, x1, y1 = unpack( self._scissorRect )
			self._scissor:setRect( x0, y0, x1, y1 )
			self._scissor:forceUpdate()
		else
			x0, y0, x1, y1 = self._prop:getExtents()
		end

		assert( x1 > x0 and y1 > y0 )
		-- Calculate scale necessary for desired size
		local sx, sy = w / (x1 - x0), h / (y1 - y0)
		local tx, ty = -(x1 + x0) * 0.5 * sx, -(y1 + y0) * 0.5 * sy
		
		self._prop:setScl( sx, sy )
		self._prop:setLoc( x + tx, y + ty )
		self._prop:setBounds( x0, y0, 0, x1, y1, 0 )
	end

	self._prop:forceUpdate() -- ccc: why is there a wierd update lag when drag-resizing the window?
end

function mui_texture:setColor( r, g, b, a )
	if self._prop.setSymbolModulate then
		self._prop:setSymbolModulate( "", r, g, b, a )
	else
		-- Prop color uses pre-multiplied alpha.
		a = a or 1
		self._prop:setColor( r * a, g * a, b * a, a )
	end
end

function mui_texture:setShader( shaderID )
	local shader = MOAIShaderMgr.getShader( shaderID )
	self._prop:setShader( shader )
end

function mui_texture:setUVRect( u0, v0, u1, v1 )
	self._deck:setUVRect ( u0, v0, u1, v1 )
end

function mui_texture:setScissor( x0, y0, x1, y1 )
	self._scissorRect = { x0, y0, x1, y1 }
	self:refreshProp()
end

function mui_texture:setTiles( tilew, tileh, offsetx, offsety )
	self._tilew, self._tileh = tilew, tileh -- How many tiles
	self._tileOffsetX, self._tileOffsetY = offsetx, offsety -- Offset in normalized tile coordinates.
	self:refreshProp()
end

function mui_texture:setImage( imagefile )
	if imagefile then
		local image = loadImage( self._screen, { file = imagefile })
		assert(image)
		self._deck:setTexture( image.image )
		self._prop:setDeck( self._deck )
	else
		self._prop:setDeck(nil)
	end
end

function mui_texture:setImageIndex( idx )
	if self._images[idx] then
		self._deck:setTexture( self._images[idx].image )
		self._prop:setDeck( self._deck )
		if self._images[idx].color then
			self._prop:setColor( unpack(self._images[idx].color) )
		end
	else
		self._prop:setDeck(nil)
	end
end

function mui_texture:setImageAtIndex( imagefile, idx )
	if imagefile then
		self._images[idx] = loadImage( self._screen, { file = imagefile } )
	else
		self._images[idx] = nil
	end
end

-- clr is an array of { r, g, b, a }
function mui_texture:setColorAtIndex( clr, idx )
    self._images[idx].color = clr
end

function mui_texture:getColorAtIndex( idx )
    if self._images[idx] then
        return self._images[idx].color
    end
end

function mui_texture:setImageState( name )
	for i, imageState in ipairs(self._images) do
		if imageState.name == name then
			self:setImageIndex( i )
			break
		end
	end
end

return mui_texture

