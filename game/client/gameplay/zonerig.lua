----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )

----------------------------------------------------------------

local DEFAULT_HILITE_CLR = { 1, 1, 1, 1 }

local INDIRECTION_TABLE =
{
	0x2F, 0x01, 0x02, 0x02, 0x03, 0x04, 0x02, 0x02, 0x05, 0x05, 0x06, 0x06, 0x07, 0x07, 0x06, 0x06, --0
	0x08, 0x09, 0x0A, 0x0A, 0x08, 0x09, 0x0A, 0x0A, 0x0B, 0x0B, 0x0C, 0x0C, 0x0B, 0x0B, 0x0C, 0x0C, --1
	0x0D, 0x0E, 0x0F, 0x0F, 0x10, 0x11, 0x0F, 0x0F, 0x05, 0x05, 0x06, 0x06, 0x07, 0x07, 0x06, 0x06, --2
	0x12, 0x13, 0x14, 0x14, 0x12, 0x13, 0x14, 0x14, 0x0B, 0x0B, 0x0C, 0x0C, 0x0B, 0x0B, 0x0C, 0x0C, --3
	0x15, 0x16, 0x17, 0x17, 0x18, 0x19, 0x17, 0x17, 0x1A, 0x1A, 0x1B, 0x1B, 0x1C, 0x1C, 0x1B, 0x1B, --4
	0x1D, 0x1E, 0x1F, 0x1F, 0x1D, 0x1E, 0x1F, 0x1F, 0x20, 0x20, 0x21, 0x21, 0x20, 0x20, 0x21, 0x21, --5
	0x15, 0x16, 0x17, 0x17, 0x18, 0x19, 0x17, 0x17, 0x1A, 0x1A, 0x1B, 0x1B, 0x1C, 0x1C, 0x1B, 0x1B, --6 COPY OF 4
	0x1D, 0x1E, 0x1F, 0x1F, 0x1D, 0x1E, 0x1F, 0x1F, 0x20, 0x20, 0x21, 0x21, 0x20, 0x20, 0x21, 0x21, --7 COPY OF 5
	0x22, 0x23, 0x24, 0x24, 0x25, 0x26, 0x24, 0x24, 0x27, 0x27, 0x28, 0x28, 0x29, 0x29, 0x28, 0x28, --8
	0x08, 0x09, 0x0A, 0x0A, 0x08, 0x09, 0x0A, 0x0A, 0x0B, 0x0B, 0x0C, 0x0C, 0x0B, 0x0B, 0x0C, 0x0C, --9 COPY OF 1
	0x2A, 0x2B, 0x2C, 0x2C, 0x2D, 0x2E, 0x2C, 0x2C, 0x27, 0x27, 0x28, 0x28, 0x29, 0x29, 0x28, 0x28, --A
	0x12, 0x13, 0x14, 0x14, 0x12, 0x13, 0x14, 0x14, 0x0B, 0x0B, 0x0C, 0x0C, 0x0B, 0x0B, 0x0C, 0x0C, --B COPY OF 3
	0x15, 0x16, 0x17, 0x17, 0x18, 0x19, 0x17, 0x17, 0x1A, 0x1A, 0x1B, 0x1B, 0x1C, 0x1C, 0x1B, 0x1B, --C COPY OF 4
	0x1D, 0x1E, 0x1F, 0x1F, 0x1D, 0x1E, 0x1F, 0x1F, 0x20, 0x20, 0x21, 0x21, 0x20, 0x20, 0x21, 0x21, --D COPY OF 5
	0x15, 0x16, 0x17, 0x17, 0x18, 0x19, 0x17, 0x17, 0x1A, 0x1A, 0x1B, 0x1B, 0x1C, 0x1C, 0x1B, 0x1B, --E COPY OF 4
	0x1D, 0x1E, 0x1F, 0x1F, 0x1D, 0x1E, 0x1F, 0x1F, 0x20, 0x20, 0x21, 0x21, 0x20, 0x20, 0x21, 0x21, --F COPY OF 5
}

local function drawHilites( self, cells )
	for i,x,y in util.xypairs(cells) do 
		local x0, y0 = self._board:cellToWorld( x + 0.4, y + 0.4 )
		local x1, y1 = self._board:cellToWorld( x - 0.4, y - 0.4 )
		MOAIDraw.fillRect( x0, y0, x1, y1 )
	end
end

local function drawZones( self, boardRig )
	local simCore = boardRig._game.simCore
	local w,h = simCore:getBoardSize()
    local ringCells = {}

	for hiliteID, hilite in pairs(self._hilites) do
		MOAIGfxDevice.setPenColor(unpack(hilite.clr or DEFAULT_HILITE_CLR))

		if hilite.duration then
			hilite.duration = hilite.duration - 1
			if hilite.duration <= 0 then
				self:unhiliteCells( hiliteID )
			end
		end

        if hilite.updateCells then
            if not hilite:updateCells( ringCells ) then
                self:unhiliteCells( hilite.id )
            end
        else
            drawHilites( self, hilite.cells )
        end
	end

    -- Draw all rings
    for cellID, clr in pairs( ringCells ) do
        local x, y = simquery.fromCellID( cellID )
		MOAIGfxDevice.setPenColor(unpack(clr))
		local x0, y0 = self._board:cellToWorld( x + 0.4, y + 0.4 )
		local x1, y1 = self._board:cellToWorld( x - 0.4, y - 0.4 )
		MOAIDraw.fillRect( x0, y0, x1, y1 )
    end
end

local function createFadeCurve( self, m)
	local curve = MOAIAnimCurve.new ()
	curve:reserveKeys ( 4 )
	curve:setKey ( 1, 0, 0.2 * m )
	curve:setKey ( 2, 0.5, 1 * m )
	curve:setKey ( 3, 2.5, 1 * m )
	curve:setKey ( 4, 3.0, 0.2 * m )


	local timer = MOAITimer.new ()
	timer:setSpan ( 0, 3)
	timer:setMode( MOAITimer.LOOP )
	timer:start()
	timer:setTime( self._timer:getTime() )

	curve:setAttrLink ( MOAIAnimCurve.ATTR_TIME, timer, MOAITimer.ATTR_TIME )

	return curve
end

local function destroyCurves( curves ) 
    if curves then
        for i, curve in ipairs(curves) do
            local timer = curve:getAttrLink( MOAIAnimCurve.ATTR_TIME )
            timer:stop()
        end
    end
end

-----------------------------------------------------
-- Interface functions

local zonerig = class()

function zonerig:init( layer, board )
	
	local ww, wh = board._game:getWorldSize()

	local scriptDeck = MOAIScriptDeck.new ()
	scriptDeck:setRect ( -ww / 2, -wh / 2, ww / 2, wh / 2 )
	scriptDeck:setDrawCallback ( 
		function( index, xOff, yOff, xFlip, yFlip )
			drawZones( self, board )
		end )

	local prop = MOAIProp2D.new ()
	prop:setPriority( cdefs.ZONES_PRIORITY ) -- behind evrything, but in front of the floors
	prop:setDeck ( scriptDeck )
	layer:insertProp ( prop )

	self._hiliteID = 1
	self._hilites = {}
	self._layer = layer
	self._board = board
	self._prop = prop

	self._timer = MOAITimer.new ()
	self._timer:setSpan ( 0, 3)
	self._timer:setMode( MOAITimer.LOOP )
	self._timer:start()


	local simCore = board._game.simCore
	local simdefs = simCore:getDefs()	

	self._simCore = simCore
	self._simDefs = simdefs

	local boardWidth, boardHeight = simCore:getBoardSize()

	local movementGrid = MOAIGrid.new()
	movementGrid:initRectGrid ( boardWidth, boardHeight, cdefs.BOARD_TILE_SIZE, cdefs.BOARD_TILE_SIZE )

	local gradDeck = MOAITileDeck2D.new()
	gradDeck:setTexture(resources.getPath("MovementTiles_Gradients.png") )
	gradDeck:setSize (	8,			--width in tiles
						8,			--height in tiles
						64/512,		--cellWidth
						64/512,		--cellHeight
						0.5/512,	--xOffset
						0.5/512,	--yOffset
						63/512,		--tileWidth
						63/512,		--tileHeight
						nil)
	gradDeck:setRect( -0.5, -0.5, 0.5, 0.5 )
	gradDeck:setUVRect( -0.5, 0.5, 0.5, -0.5 )

	local movementGradProp = MOAIProp2D.new()
	movementGradProp:setDeck( gradDeck )
	movementGradProp:setGrid( movementGrid )
	movementGradProp:setLoc( -boardWidth * cdefs.BOARD_TILE_SIZE / 2, -boardHeight * cdefs.BOARD_TILE_SIZE / 2)
	movementGradProp:setPriority( cdefs.ZONES_PRIORITY )
	layer:insertProp( movementGradProp )


	local lineDeck = MOAITileDeck2D.new()
	lineDeck:setTexture(resources.getPath("MovementTiles.png") )
	lineDeck:setSize (	8,			--width in tiles
						8,			--height in tiles
						64/512,		--cellWidth
						64/512,		--cellHeight
						0.5/512,	--xOffset
						0.5/512,	--yOffset
						63/512,		--tileWidth
						63/512,		--tileHeight
						nil)
	lineDeck:setRect( -0.5, -0.5, 0.5, 0.5 )
	lineDeck:setUVRect( -0.5, 0.5, 0.5, -0.5 )


	local movementLineProp = MOAIProp2D.new()
	movementLineProp:setDeck( lineDeck )
	movementLineProp:setGrid( movementGrid )
	movementLineProp:setLoc( -boardWidth * cdefs.BOARD_TILE_SIZE / 2, -boardHeight * cdefs.BOARD_TILE_SIZE / 2)
	movementLineProp:setPriority( cdefs.ZONES_PRIORITY )
	layer:insertProp( movementLineProp )

	local movementBits = {}
	for y=1,boardHeight,1 do
		local bitRow = {}
		for x=1,boardWidth,1 do
			bitRow[x] = 0
		end
		movementBits[y] = bitRow
	end

	self._movementGradProp = movementGradProp
	self._movementLineProp = movementLineProp
	self._movementGrid = movementGrid
	self._movementBits = movementBits


	--create cloak parts
	local cloakBits = {}
	for y=1,boardHeight,1 do
		local bitRow = {}
		for x=1,boardWidth,1 do
			bitRow[x] = 0
		end
		cloakBits[y] = bitRow
	end

	local cloakGrid = MOAIGrid.new()
	cloakGrid:initRectGrid ( boardWidth, boardHeight, cdefs.BOARD_TILE_SIZE, cdefs.BOARD_TILE_SIZE )

	local cloakGradProp = MOAIProp2D.new()
	cloakGradProp:setDeck( gradDeck )
	cloakGradProp:setGrid( cloakGrid )
	cloakGradProp:setLoc( -boardWidth * cdefs.BOARD_TILE_SIZE / 2, -boardHeight * cdefs.BOARD_TILE_SIZE / 2)
	cloakGradProp:setPriority( cdefs.ZONES_PRIORITY )
	layer:insertProp( cloakGradProp )

	local cloakLineProp = MOAIProp2D.new()
	cloakLineProp:setDeck( lineDeck )
	cloakLineProp:setGrid( cloakGrid )
	cloakLineProp:setLoc( -boardWidth * cdefs.BOARD_TILE_SIZE / 2, -boardHeight * cdefs.BOARD_TILE_SIZE / 2)
	cloakLineProp:setPriority( cdefs.ZONES_PRIORITY )
	layer:insertProp( cloakLineProp )


	self._cloakGradProp = cloakGradProp
	self._cloakLineProp = cloakLineProp
	self._cloakGrid = cloakGrid
	self._cloakBits = cloakBits	
end

function zonerig:destroy()
	self._layer:removeProp( self._prop )
	self._layer:removeProp( self._movementGradProp )
	self._layer:removeProp( self._movementLineProp )

	self._layer:removeProp( self._cloakGradProp )
	self._layer:removeProp( self._cloakLineProp )

    self._timer:stop()

    destroyCurves( self._movementCurves ) 
    destroyCurves( self._cloakCurves ) 

end

function zonerig:hiliteRadius( hilite )
    hilite.id = self._hiliteID

    self._hilites[ hilite.id ] = hilite
	self._hiliteID = self._hiliteID + 1

	return hilite.id
end

function zonerig:hiliteCells( cells, clr, duration, z )
	assert( duration == nil or duration > 0 )
	assert( cells )

	local hilite =
	{
		cells = cells,
		clr = clr,
		duration = duration,
		id = self._hiliteID
	}

	self._hilites[ hilite.id ] = hilite
	self._hiliteID = self._hiliteID + 1

	return hilite.id
end

function zonerig:unhiliteCells( hiliteID )
	if self._hilites[ hiliteID ] ~= nil then
		self._hilites[ hiliteID ] = nil
	end
end

function zonerig:clearMovementTiles()
	local grid = self._movementGrid
	local bits = self._movementBits
	local boardWidth, boardHeight = self._simCore:getBoardSize()
	for y=1,boardHeight,1 do
		for x=1,boardWidth,1 do
			grid:setTile( x, y, 0 )
			bits[y][x] = 0
		end
	end
end

function zonerig:setMovementTiles( tiles, grad, line)
	for _, cell in ipairs(tiles) do
		self:setGridTile( self._movementBits, cell.x, cell.y )
	end
	for _, cell in ipairs(tiles) do
		local twoscomp = 2^9 - 1 - self._movementBits[cell.y][cell.x]
		local idx = INDIRECTION_TABLE[ twoscomp + 1 ]
		self._movementGrid:setTile( cell.x, cell.y, idx + 1)
	end
	self._movementGradProp:setColor( grad:unpack() )
	self._movementLineProp:setColor( line:unpack() )
    
    local curves = { createFadeCurve( self, grad.r ), createFadeCurve( self, grad.g ), createFadeCurve( self, grad.b ), createFadeCurve( self, grad.a ) }

	self._movementGradProp:setAttrLink ( MOAIColor.ATTR_R_COL, curves[1], MOAIAnimCurve.ATTR_VALUE )
	self._movementGradProp:setAttrLink ( MOAIColor.ATTR_G_COL, curves[2], MOAIAnimCurve.ATTR_VALUE )
	self._movementGradProp:setAttrLink ( MOAIColor.ATTR_B_COL, curves[3], MOAIAnimCurve.ATTR_VALUE )
	self._movementGradProp:setAttrLink ( MOAIColor.ATTR_A_COL, curves[4], MOAIAnimCurve.ATTR_VALUE )

	self._movementLineProp:setAttrLink ( MOAIColor.ATTR_R_COL, curves[1], MOAIAnimCurve.ATTR_VALUE )
	self._movementLineProp:setAttrLink ( MOAIColor.ATTR_G_COL, curves[2], MOAIAnimCurve.ATTR_VALUE )
	self._movementLineProp:setAttrLink ( MOAIColor.ATTR_B_COL, curves[3], MOAIAnimCurve.ATTR_VALUE )
	self._movementLineProp:setAttrLink ( MOAIColor.ATTR_A_COL, curves[4], MOAIAnimCurve.ATTR_VALUE )

	destroyCurves( self._movementCurves ) 
	self._movementCurves = curves	
end



function zonerig:clearCloakTiles()
	local grid = self._cloakGrid
	local bits = self._cloakBits
	local boardWidth, boardHeight = self._simCore:getBoardSize()
	for y=1,boardHeight,1 do
		for x=1,boardWidth,1 do
			grid:setTile( x, y, 0 )
			bits[y][x] = 0
		end
	end
end


function zonerig:setCloakTiles( tiles, grad, line)
	for _, cell in ipairs(tiles) do
		self:setGridTile( self._cloakBits, cell.x, cell.y )
	end
	for _, cell in ipairs(tiles) do
		local twoscomp = 2^9 - 1 - self._cloakBits[cell.y][cell.x]
		local idx = INDIRECTION_TABLE[ twoscomp + 1 ]
		self._cloakGrid:setTile( cell.x, cell.y, idx + 1)
	end
	self._cloakGradProp:setColor( grad:unpack() )
	self._cloakLineProp:setColor( line:unpack() )

 	local curves = { createFadeCurve( self, grad.r ), createFadeCurve( self, grad.g ), createFadeCurve( self, grad.b ), createFadeCurve( self, grad.a ) }

	self._cloakGradProp:setAttrLink ( MOAIColor.ATTR_R_COL, curves[1], MOAIAnimCurve.ATTR_VALUE )
	self._cloakGradProp:setAttrLink ( MOAIColor.ATTR_G_COL, curves[2], MOAIAnimCurve.ATTR_VALUE )
	self._cloakGradProp:setAttrLink ( MOAIColor.ATTR_B_COL, curves[3], MOAIAnimCurve.ATTR_VALUE )
	self._cloakGradProp:setAttrLink ( MOAIColor.ATTR_A_COL, curves[4], MOAIAnimCurve.ATTR_VALUE )

	self._cloakLineProp:setAttrLink ( MOAIColor.ATTR_R_COL, curves[1], MOAIAnimCurve.ATTR_VALUE )
	self._cloakLineProp:setAttrLink ( MOAIColor.ATTR_G_COL, curves[2], MOAIAnimCurve.ATTR_VALUE )
	self._cloakLineProp:setAttrLink ( MOAIColor.ATTR_B_COL, curves[3], MOAIAnimCurve.ATTR_VALUE )
	self._cloakLineProp:setAttrLink ( MOAIColor.ATTR_A_COL, curves[4], MOAIAnimCurve.ATTR_VALUE )

	destroyCurves( self._cloakCurves ) 
	self._cloakCurves = curves	
end

function zonerig:setGridTile( bits, x, y )
	if bits[y][x] < 2^8 then
		local sim = self._simCore
		local boardWidth, boardHeight = sim:getBoardSize()
		local startCell = sim:getCell( x, y )
		local aRow = bits[y-1]
		local bRow = bits[y]
		local cRow = bits[y+1]

		if aRow then
			if x>1 then
				if simquery.canPathBetween( sim, nil, startCell, sim:getCell( x - 1, y - 1 )) then
					aRow[x-1] = aRow[x-1] + 2^7
				end
			end
			if simquery.canPathBetween( sim, nil, startCell, sim:getCell( x, y - 1 )) then
				aRow[x] = aRow[x] + 2^6
			end
			if x<boardWidth then
				if simquery.canPathBetween( sim, nil, startCell, sim:getCell( x + 1, y - 1 )) then
					aRow[x+1] = aRow[x+1] + 2^5
				end
			end
		end
		if x>1 then
			if simquery.canPathBetween( sim, nil, startCell, sim:getCell( x - 1, y )) then
				bRow[x-1] = bRow[x-1] + 2^4
			end
		end
		bRow[x] = bRow[x] + 2^8 --this bit is used to know if we've already tagged this element as passable
		if x<boardWidth then
			if simquery.canPathBetween( sim, nil, startCell, sim:getCell( x + 1, y )) then
				bRow[x+1] = bRow[x+1] + 2^3
			end
		end
		if cRow then
			if x>1 then
				if simquery.canPathBetween( sim, nil, startCell, sim:getCell( x - 1, y + 1 )) then
					cRow[x-1] = cRow[x-1] + 2^2
				end
			end
			if simquery.canPathBetween( sim, nil, startCell, sim:getCell( x, y + 1 )) then
				cRow[x] = cRow[x] + 2^1
			end
			if x<boardWidth then
				if simquery.canPathBetween( sim, nil, startCell, sim:getCell( x + 1, y + 1 )) then
					cRow[x+1] = cRow[x+1] + 2^0
				end
			end
		end
	end
end

function zonerig:printGrid()
	local boardWidth, boardHeight = self._simCore:getBoardSize()
	local bits = self._movementBits

	for y=1,boardHeight,1 do
		local bRow = bits[y]
		for x=1,boardWidth,1 do
			local bit = bRow[x] - 2^8
			if bit >= 0 then
				local twoscomp = 2^8 - 1 - bit
				local idx = INDIRECTION_TABLE[ twoscomp + 1 ]
				print(x,y, twoscomp, idx )
			end
		end
	end
end

return zonerig