----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local unitrig = include( "gameplay/unitrig" )
local doorrig2 = include( "gameplay/doorrig2" )
local zonerig = include( "gameplay/zonerig" )
local itemrig = include( "gameplay/itemrig" )
local wallrig2 = include( "gameplay/wallrig2" )
local wall_vbo = include( "gameplay/wall_vbo" )
local postrig = include( "gameplay/postrig" )
local cellrig = include( "gameplay/cellrig" )
local coverrig = include( "gameplay/coverrig" )
local pathrig = include( "gameplay/pathrig" )
local agentrig = include( "gameplay/agentrig" )
local decorig = include( "gameplay/decorig" )
local lightrig = include( "gameplay/lightrig" )
local overlayrigs = include( "gameplay/overlayrigs" )
local sound_ring_rig = include( "gameplay/sound_ring_rig" )
local world_sounds = include( "gameplay/world_sounds" )
local fxbackgroundrig = include( "gameplay/fxbackgroundrig" )
local hilite_radius = include( "gameplay/hilite_radius" )
local viz_thread = include( "gameplay/viz_thread" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local animmgr = include( "anim-manager" )
local cdefs = include( "client_defs" )
local serverdefs = include( "modules/serverdefs" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local level = include( "sim/level" )
local modalDialog = include( "states/state-modal-dialog" )


-----------------------------------------------------
-- Board rig class, master class for managing all in-game viz.

local boardrig = class( )

function boardrig:getUnitRig( unitID )
	local unitRig = self._unitRigs[ unitID ]
	if unitRig and unitRig:getUnit() == nil then
		unitRig:destroy()
		self._unitRigs[ unitID ] = nil
		unitRig = nil
	elseif unitRig == nil then
		unitRig = self:createUnitRig( unitID ) -- Lazy rig creation.
	end

	return unitRig
end

function boardrig:getDoorRig( cell, dir )
	-- Lookup the door rig that is visible (a given door rig can be identified by one of two cell/dir pairs)
	if dir == simdefs.DIR_W or dir == simdefs.DIR_S then
		cell = cell.exits[ dir ].cell
		dir = dir - 4
	end

	for i,doorRig in ipairs(self._doorRigs) do
		local x, y = doorRig:getLocation1()
		if dir == doorRig:getFacing1() and x == cell.x and y == cell.y then
			return doorRig
		end
	end
end

function boardrig:refreshBackgroundFX()
	local currentPlayer = self:getSim():getCurrentPlayer()
	self._backgroundFX:refresh( currentPlayer and currentPlayer:isPC() )
end

function boardrig:refreshUnits( )
	local sim = self._game.simCore
	-- Need to create rigs for units that should exist.
	for unitID, unit in pairs(sim:getAllUnits()) do
		if self._unitRigs[ unitID ] == nil and unit:getLocation() then
			self:createUnitRig( unitID )
		end
	end

	-- Similarily, destroy rigs for units that no longer exist; or refresh those that do
	for unitID, unitRig in pairs(self._unitRigs) do
		if unitRig:getUnit() == nil then
			unitRig:destroy()
			self._unitRigs[ unitID ] = nil
		else
			unitRig:refresh()
		end
	end
end

function boardrig:refreshWalls( )
	for i,wallRig in ipairs(self._wallRigs) do
		wallRig:refresh( )
	end
end

function boardrig:refreshDoors( )
	for i,doorRig in ipairs(self._doorRigs) do
		doorRig:refresh( )
	end
end

function boardrig:refreshDecor( )
	self._decorig:refresh( )
end

function boardrig:refreshCells()
	local updatedRigs = {}

	for _, cellRig in pairs( self._cellRigs ) do
		cellRig:refresh()
		cellRig:refreshDependentRigs( updatedRigs )
	end
end

function boardrig:queryCellOcclusion( unit, x, y )
	if unit:isNPC() or not unit:getTraits().hidesInCover or unit:getTraits().disguiseOn then
		return false
	end
	
	local sim = self:getSim()
	local simquery = sim:getQuery()
	local simdefs = sim:getDefs()
	local camera = self._game:getCamera()
	local dx, dy = camera:orientVector(1,1)

	local cell = x and self:getLastKnownCell( x, y )
	if cell then
		--half cover close to me
		if 	simquery.checkIsHalfWall( sim, cell, camera:orientDirection( simdefs.DIR_N ) ) or 
			simquery.checkIsHalfWall( sim, cell, camera:orientDirection( simdefs.DIR_S ) ) or 
			simquery.checkIsHalfWall( sim, cell, camera:orientDirection( simdefs.DIR_W ) ) or 
			simquery.checkIsHalfWall( sim, cell, camera:orientDirection( simdefs.DIR_E ) ) then
			return true
		end

		--door close to me
		if simquery.checkIsDoor( sim, cell, camera:orientDirection( simdefs.DIR_N ) ) or simquery.checkIsDoor( sim, cell, camera:orientDirection( simdefs.DIR_E ) ) then
			return true
		end

		--corners
		for _, dir in ipairs( simdefs.DIR_SIDES ) do
			if simquery.agentShouldLean(sim, cell, dir) then
				return true
			end
		end
	end
	return false
end

function boardrig:canSeeLOS( seer )
    return simquery.canSeeLOS( self:getSim(), self:getLocalPlayer(), seer )
end

local function getLOSCasterSource( boardRig, seer )
    local x, y = seer:getLocation()
	local range = seer:getTraits().LOSrange

    if seer:getTraits().mainframe_camera then
        -- HAX
        local facing = seer:getFacing()
        if facing % 2 == 1 then
            local dx, dy = simquery.getDeltaFromDirection( facing )
            x, y = x - dx * 0.5, y - dy * 0.5
            if range then
            	range = range + mathutil.dist2d( 0, 0, dx, dy ) * 0.5
            end
        end
    end

    x, y = boardRig:cellToWorld( x, y )
    range = range and boardRig:cellToWorldDistance( range )

    return x, y, range
end

function boardrig:refreshLOSCaster( seerID )
	local seer = self._game.simCore:getUnit( seerID )
    local localPlayer = self:getLocalPlayer()

	-- The hasLOS condition needs to (unfortunately) be matched with whatever is determined in sim:refreshUnitLOS in order
	-- to correctly reflect the sim state.
	local hasLOS = seer and seer:getLocation() ~= nil
	hasLOS = hasLOS and seer:getTraits().hasSight and not seer:isKO() and not seer:getTraits().grappler
    hasLOS = hasLOS and self:canSeeLOS( seer )
    
	if hasLOS then
		local unitRig = self:getUnitRig( seerID )
        local bAgentLOS = (seer:getPlayerOwner() == localPlayer)
		local bEnemyLOS = not bAgentLOS and not seer:isPC()

		if unitRig == nil or unitRig.refreshLOSCaster == nil or not unitRig:refreshLOSCaster( seerID ) then
			local x0, y0, range = getLOSCasterSource( self, seer )
			local losArc = simquery.getLOSArc( seer )
			assert( losArc >= 0, losArc )

			local arcStart = seer:getFacingRad() - losArc/2
			local arcEnd = seer:getFacingRad() + losArc/2

			if bAgentLOS then
				self._game.shadow_map:insertLOS( KLEIShadowMap.ALOS_DIRECT, seerID, arcStart, arcEnd, range, x0, y0 )
			elseif bEnemyLOS then
				self._game.shadow_map:insertLOS( KLEIShadowMap.ELOS_DIRECT, seerID, arcStart, arcEnd, range, x0, y0 )
				if seer:getTraits().LOSperipheralArc then
					local range = seer:getTraits().LOSperipheralRange and self:cellToWorldDistance( seer:getTraits().LOSperipheralRange )
					local losArc = seer:getTraits().LOSperipheralArc
					local arcStart = seer:getFacingRad() - losArc/2
					local arcEnd = seer:getFacingRad() + losArc/2

					self._game.shadow_map:insertLOS( KLEIShadowMap.ELOS_PERIPHERY, seerID + simdefs.SEERID_PERIPHERAL, arcStart, arcEnd, range, x0, y0 )
				end
			end
        end

        if bEnemyLOS then
            self:refreshBlindSpots( seer )
        else
            self:clearBlindSpots( seerID )
        end
	else
        self:clearBlindSpots( seerID )
		
        self._game.shadow_map:removeLOS( seerID )
		self._game.shadow_map:removeLOS( seerID + simdefs.SEERID_PERIPHERAL )
	end
end

function boardrig:checkForAppearedSounds( cellx, celly )
    local player = self:getLocalPlayer()
    local sim = self:getSim()
    local cell = sim:getCell( cellx, celly )

    if cell and player and player:isPC() then
	    for i,unit in ipairs(cell.units) do
            if unit:getSounds().appeared and player:justSeenUnit( unit ) and sim:canPlayerSeeUnit( player, unit ) then
			    self:getUnitRig( unit:getID() ):addAnimFx( "fx/item_revealed", "whole", "idle", true )
			    self._world_sounds:playSound( unit:getSounds().appeared, nil, unit:getLocation() )
		    end

			if unit:getTraits().mainframe_program then
                self._game.hud:explainDaemons()
            end
	    end
    end
end

function boardrig:clearBlindSpots( seerID )
    if self._blindCells[ seerID ] then
        self._blindCells[ seerID ] = nil
        self:updateBlindSpots()
    end
end

function boardrig:isBlindSpot( cellx, celly )
    for seerID, vizCells in pairs( self._blindCells ) do
        for i = 1, #vizCells, 2 do
            if vizCells[i] == cellx and vizCells[i+1] == celly then
                return true
            end
        end
    end
    return false
end

function boardrig:refreshBlindSpots( seer )
    local sim = self._game.simCore
    local localPlayer = self:getLocalPlayer()
    local vizCells = {}
    if localPlayer then
        local cx0, cy0 = seer:getLocation()
        if seer:getTraits().LOSperipheralArc then
            sim:getLOS():getPeripheralVizCells( seer:getID(), vizCells )
        else
            sim:getLOS():getVizCells( seer:getID(), vizCells )
        end
        for i = #vizCells, 1, -2 do
            local cx, cy = vizCells[i-1], vizCells[i]
            local cell = sim:getCell( cx, cy )
            if not cell or cell.impass > 0 or not sim:canPlayerSee( localPlayer, cx, cy ) or not simquery.checkCellCover( sim, cx0, cy0, cx, cy ) then
                table.remove( vizCells, i-1 )
                table.remove( vizCells, i-1 )
            end
        end
    end
    self._blindCells[ seer:getID() ] = vizCells
    self:updateBlindSpots()
end

function boardrig:updateBlindSpots()
    if self._zoneRig == nil then
        return
    end

    local sim = self._game.simCore
    local localPlayer = self:getLocalPlayer()
    local count = 0
    local cover = {}
    if localPlayer and localPlayer:isPC() then
	    for seerID, vizCells in pairs( self._blindCells ) do
            for i = 1, #vizCells, 2 do
                local cell = sim:getCell( vizCells[i], vizCells[i+1] )
                if simquery.isCellWatched( sim, localPlayer, cell.x, cell.y ) == simdefs.CELL_HIDDEN then
                    local x,y = cell.x, cell.y
                    local mx,my = self:cellToWorld( x - 0.5, y - 0.5 )
                    local MX,MY = self:cellToWorld( x + 0.5, y + 0.5 )
                    cover[#cover+1] = mx
                    cover[#cover+1] = my
                    cover[#cover+1] = MX
                    cover[#cover+1] = MY
                end
		    end
            count = count + #vizCells / 2
        end
    end
        
	self._game.shadow_map:setCover( cover )
end

function boardrig:updateShadowMap()
	local segs = self:getSim():getLOS():getSegments()

	-- All we need to do is transform the coordinates to world-space.
	for i = 1, #segs, 2 do
		segs[i], segs[i+1] = self:cellToWorld( segs[i], segs[i+1] )
	end

    self._game.shadow_map:setSegments( segs )

	self._game.shadow_map:disableALOS( self:getLocalPlayer() == nil )
    self._game.shadow_map:disableELOS( self._game:getGfxOptions().bTacticalView == true )
end

function boardrig:createWallRigs( )
	assert( self._wallVBO == nil )

	local st = os.clock()	
	self._wallVBO = wall_vbo.generate3DWalls( self )
	log:write( "generate3DWalls() -- took %.1f ms", (os.clock() - st) * 1000 )
	self._game.shadow_map:setWorldInfo( cdefs.BOARD_TILE_SIZE * self._boardWidth, cdefs.BOARD_TILE_SIZE * self._boardHeight )
	self:updateShadowMap()

	local VALID_DIRS = { simdefs.DIR_N, simdefs.DIR_E }

	-- Create viz cells such that there is an outer buffer (wall generation requires it...)
	for i, cellviz in pairs(self._cellRigs ) do
		local wallOffsets = cellviz._wallGeoInfo
		local doorOffsets = cellviz._doorGeoInfo
		local postOffsets = cellviz._postGeoInfo

		for _,dir in pairs( VALID_DIRS ) do
			if wallOffsets and wallOffsets[ dir ] then
				local wallRig = wallrig2( self, cellviz._x, cellviz._y, dir, self._wallVBO )
				table.insert( self._wallRigs, wallRig )
			end
			if doorOffsets and doorOffsets[ dir ] then
				local doorRig = doorrig2( self, cellviz._x, cellviz._y, dir, self._wallVBO )
				table.insert( self._doorRigs, doorRig )
			end
		end
		local postRig = postrig( self, cellviz._x, cellviz._y, self._wallVBO )
		if postRig:isValid() then
			table.insert( self._wallRigs, postRig )
		else
			postRig:destroy()
		end
	end
end

function boardrig:createLightRigs( levelData )
	if levelData.lights then
		for i, lightInfo in ipairs( levelData.lights ) do
			table.insert( self._lightRigs, lightrig( self, lightInfo ))
		end
	end
end

function boardrig:createUnitRig( unitID )
	if ( self._unitRigs[ unitID ] ) then
		return self._unitRigs[ unitID ]
	end

	local sim = self._game.simCore
    local unit = self:getLastKnownUnit( unitID )
    if unit then
        local rig = nil
	    if unit:getUnitData().rig then
    		-- Allow units that specify for NO rig by using the empty string.
            if #unit:getUnitData().rig > 0 then
		        rig = include( "gameplay/" .. unit:getUnitData().rig )
	        end
        elseif sim:getQuery().isAgent( unit ) then
            rig = agentrig
	    elseif sim:getQuery().isItem( unit ) then
            rig = itemrig
	    end

	    if rig then
            if rig.createRig then
                rig = rig.createRig( self, unit )
            else
                rig = rig.rig( self, unit )
            end
            if rig then
		        self._unitRigs[ unit:getID() ] = rig
		        rig:refresh()
                return rig
            end
	    end
    end

    return nil
end

function boardrig:createCells( )
	local sim = self:getSim()
	for y=0,self._boardHeight+1 do
		for x=0,self._boardWidth+1 do
			local scell = sim:getCell( x, y )
			if scell == nil then
				for dir = 0, simdefs.DIR_MAX-1 do
					local dx, dy = simquery.getDeltaFromDirection( dir )
					scell = sim:getCell( x + dx, y + dy )
					if scell then
						break
					end
				end
			end
			if scell then
				local cellID = simquery.toCellID( x, y )
				self._cellRigs[cellID] = cellrig( self, x, y )
			end
		end
	end
end


function boardrig:createHUDProp(kanimName, symbolName, anim, layer, unitProp, x, y, facing)
	local prop, kanim = animmgr.createPropFromAnimDef( kanimName )

	prop:setCurrentSymbol(symbolName)

	if anim then	
		prop:setCurrentAnim( anim )
	end

	if unitProp then
		prop:setAttrLink( MOAIProp.INHERIT_LOC, unitProp, MOAIProp.TRANSFORM_TRAIT)
		prop:setAttrLink( MOAIProp.ATTR_VISIBLE, unitProp, MOAIProp.ATTR_VISIBLE)
	else
		if x and y then
			prop:setLoc( x, y )	
		end
	end

	animmgr.refreshIsoBounds( prop, kanim, facing )

	if (layer == true or layer == false) and unitProp then
		unitProp:insertProp( prop, layer )
	else
		layer:insertProp( prop )
	end

	return prop
end

local function handleEmittedSound( boardRig, x0, y0, sound, altVisTiles )
	local sim = boardRig:getSim()
	local closestUnit, closestRange = nil, math.huge

	if boardRig:getLocalPlayer() then
		closestUnit, closestRange = simquery.findClosestUnit( boardRig:getLocalPlayer():getUnits(), x0, y0, simquery.canHear )
	end

	local hasListener = closestUnit ~= nil and closestRange <= sound.range
	local canSeeSource = boardRig:canPlayerSee( x0, y0 ) 
	--altVisTiles is for doors.. the sound might originate from an unseen tile even though the door can be seen.
	if altVisTiles and not canSeeSource then
		for i,tile in ipairs(altVisTiles) do
			if boardRig:canPlayerSee( tile.x, tile.y ) then
				canSeeSource = true
				break
			end
		end
	end

	-- sound and listener, play the audio
	if sound.path and (hasListener or canSeeSource) then
		boardRig._world_sounds:playSound( sound.path, nil, x0, y0 )
	end

	-- listener or player's unit, show rings
	if sound.range > 0 then
		boardRig._world_sounds:playRattles( x0, y0, sound.range )
		if hasListener or canSeeSource then
        	local soundRingRig = sound_ring_rig( boardRig, x0, y0, sound.range, 0.5, {140/255, 255/255, 255/255, 0.3} )
	    	table.insert( boardRig._dynamicRigs, soundRingRig )
            if sound.hiliteCells then
                local hilite = hilite_radius( x0, y0, sound.range )
                hilite:setRate( 1, 40, 0.2 )
                hilite:setColor( { 0.05, 0.05, 0.05, 0.05 } )
                boardRig:hiliteRadius( hilite )
            end
		end
	end
end


local function handleFlashViz( self, eventData )
	self._game:cameraPanToCell( eventData.x, eventData.y )

    handleEmittedSound( self, eventData.x, eventData.y, {range=eventData.range, path="SpySociety/Grenades/flashbang_explo"} )

    local RING_PERIOD = 6
    local hilite = hilite_radius( eventData.x, eventData.y, eventData.range )
    hilite:setRate( RING_PERIOD )
	self:hiliteRadius( hilite )

    local wx, wy = self:cellToWorld( eventData.x, eventData.y )
	self._game.fxmgr:addAnimFx( {kanim="fx/flashbang", symbol="effect", anim="idle", x = wx, y = wy, facingMask = KLEIAnim.FACING_W } )
end

local function handleOverloadViz( self, eventData )
	if eventData.mainframe then
		self._game.hud:showMainframe()
	end
	self._game:cameraPanToCell( eventData.x, eventData.y )

    handleEmittedSound( self, eventData.x, eventData.y, {range=eventData.range, path="SpySociety/Actions/EMP_explo"} )

    local RING_PERIOD = 6
    local hilite = hilite_radius( eventData.x, eventData.y, eventData.range )
    hilite:setRate( RING_PERIOD )
	self:hiliteRadius( hilite )

    local wx, wy = self:cellToWorld( eventData.x, eventData.y )
	self._game.fxmgr:addAnimFx( { kanim = "fx/emp_explosion", symbol = "character", anim = "active", x = wx, y = wy, facingMask = KLEIAnim.FACING_W } )

    if eventData.units then
		local targetUnits = util.tdupe(eventData.units)
        table.sort(targetUnits,
            function(u1, u2) return mathutil.distSqr2d( eventData.x, eventData.y, u1:getLocation() ) <
                                    mathutil.distSqr2d( eventData.x, eventData.y, u2:getLocation() ) end )
        local lastRange = 0
        for i, unit in ipairs(targetUnits) do
            local range = math.floor( mathutil.dist2d( eventData.x, eventData.y, unit:getLocation() ) )
            if range > lastRange then
                self:wait( (range - lastRange) * RING_PERIOD )
                lastRange = range
            end
            if eventData.fx then
    			local wx1, wy1 = self:cellToWorld( unit:getLocation() )
				self._game.fxmgr:addAnimFx( { kanim = eventData.fx.kanim, symbol = eventData.fx.symbol, anim = eventData.fx.anim, x = wx1, y = wy1, facingMask = KLEIAnim.FACING_W } )
            else
            	self:getUnitRig( unit:getID() ):performEMP()
        	end
        end
	end

end

function boardrig:queFloatText( x0, y0, txt, color, sound, target, alwaysShow)
	table.insert(self._floatTxt,{x0=x0,y0=y0,txt=txt,color=color,sound=sound, alwaysShow=alwaysShow})
end

function boardrig:showFloatText( x0, y0, txt, color, sound, alwaysShow )
	if config.RECORD_MODE or not self._game.hud then
		return
	end	

	if self:canPlayerSee( math.floor(x0 + 0.5), math.floor(y0 + 0.5) ) or alwaysShow then	
    	local wx, wy = self:cellToWorld( x0, y0 )
        self._game.hud:showFloatText( wx, wy, txt, color )
		if sound then
			MOAIFmodDesigner.playSound( sound, nil, nil, {x0,y0,0}, nil )
		end
	end
end


function boardrig:revealAll( cellRigs )
    local updatedRigs = {}
    while #cellRigs > 0 do
        self:revealCell( table.remove(cellRigs), updatedRigs )
    end
end

function boardrig:revealCell( cellRig, updatedRigs )
	cellRig:refresh()
	cellRig:refreshDependentRigs( updatedRigs )

	self._decorig:refreshCell( cellRig._x, cellRig._y )
	self:checkForAppearedSounds( cellRig._x, cellRig._y )
end

-----------------------------------------------------
-- Interface functions

function boardrig:getLayer( name )
	if name ~= nil then
		return self._layers[name] or self._game.backgroundLayers[name]
	else
		return self._layer
	end
end
		
function boardrig:getLayers( )
	return self._layers
end

function boardrig:getSim( )
	return self._game.simCore
end

function boardrig:worldToCell( x, y )
				
	x, y = self._grid:worldToModel( x, y )

	x = math.floor(x / cdefs.BOARD_TILE_SIZE) + 1
	y = math.floor(y / cdefs.BOARD_TILE_SIZE) + 1

	if x > 0 and y > 0 and x <= self._boardWidth and y <= self._boardHeight then
		return x, y
	end
end

function boardrig:worldToSubCell( x, y )
				
	x, y = self._grid:worldToModel( x, y )

	x = x / cdefs.BOARD_TILE_SIZE + 1
	y = y / cdefs.BOARD_TILE_SIZE + 1

	return x, y
end

function boardrig:worldToWnd( x, y, z )
	local wnd_x, wnd_y = self._layer:worldToWnd( x, y, z )
	return wnd_x, wnd_y
end

function boardrig:wndToWorld( x, y )
	local world_x, world_y = self._layer:wndToWorld2D ( x, y )
	return world_x, world_y
end


function boardrig:cellToWorld( cellx, celly )
	
	local x = cellx * cdefs.BOARD_TILE_SIZE - 0.5 * cdefs.BOARD_TILE_SIZE
	local y = celly * cdefs.BOARD_TILE_SIZE - 0.5 * cdefs.BOARD_TILE_SIZE

	x, y = self._grid:modelToWorld( x, y )

	return x, y
end

function boardrig:cellToWnd( cellx, celly )
	local world_x, world_y = self:cellToWorld( cellx, celly )
	local wnd_x, wnd_y = self._layer:worldToWnd( world_x, world_y, 0 )
	return wnd_x, wnd_y
end

function boardrig:cellToWorldDistance( dist )
	local x0, y0 = self:cellToWorld( 0, 0 )
	local x1, y1 = self:cellToWorld( dist, 0 )
	return mathutil.dist2d( x0, y0, x1, y1 )
end

function boardrig:generateTooltip( debugMode, cellx, celly )	
	local tooltip = ""
	local cell = cellx and celly and self:getSim():getCell( cellx, celly )
	if cell then
		for i,unit in ipairs(cell.units) do
			local unitRig = self._unitRigs[ unit:getID() ]
			if unitRig and unitRig.generateTooltip then
				tooltip = tooltip .. unitRig:generateTooltip( debugMode ) .. "\n"
            else
                tooltip = tooltip .. string.format( "<debug>%s [%d]</>\n", util.toupper(unit:getName()), unit:getID())
			end
		end
	end

	return tooltip
end

function boardrig:getClientCellXY( x, y )
	if x and y then
		local cellID = simquery.toCellID( x, y )
		return self._cellRigs[ cellID ]
	end
end
	
function boardrig:getClientCell( cell )
	if cell then
		return self:getClientCellXY( cell.x, cell.y )
	end
end

function boardrig:getClientCells( coords )
    local cellRigs = {}
    for i = 1, #coords, 2 do
        table.insert( cellRigs, self:getClientCellXY( coords[i], coords[i+1] ))
    end
    return cellRigs
end

function boardrig:canPlayerHear( x, y, range )
	local localPlayer = self._game:getLocalPlayer()
	if not localPlayer then
		return true -- Spectator
	else
		local closestUnit, closestRange = simquery.findClosestUnit( self:getLocalPlayer():getUnits(), x, y, simquery.canHear )
		return closestUnit and closestRange <= range
	end
end

function boardrig:canPlayerSee( x, y )
	local localPlayer = self:getLocalPlayer()
	if not localPlayer then
		return true -- Spectator
	else
		return self:getSim():canPlayerSee( localPlayer, x, y )
	end
end

function boardrig:canPlayerSeeUnit( unit )
	local localPlayer = self:getLocalPlayer()
	if not localPlayer then
		return true -- Spectator
    else
        if unit:getTraits().noghost and localPlayer:isPC() and unit:getLocation() and localPlayer:getLastKnownCell( self._game.simCore, unit:getLocation() ) then
            return true -- Non-ghostables are always visible in presentation (not necessarily 'visible' sim-speaking)
	    else
		    return self:getSim():canPlayerSeeUnit( localPlayer, unit )
	    end
    end
end

function boardrig:chainCells( cells, clr, duration, dashed )
	local id = self._chainCellID or 1
	self._chainCellID = id + 1

	local localPlayer = self:getLocalPlayer()
	local dotTex, lineTex = resources.find( "dot" ), resources.find( "line" )

	if dashed then
		lineTex = resources.find( "line_dashed" )		
	end

	local props = {}
	local defaultColor = util.color.fromBytes( 140, 255, 255 )

	for i,cell in ipairs(cells) do
		local x,y = self:cellToWorld( cell.x, cell.y )
		local ncell = cells[i+1]
		
		local prop = MOAIProp2D.new ()
		prop:setDeck ( dotTex )
		prop:setLoc( x, y )
		
		if clr then
			prop:setColor(clr.r,clr.g,clr.b,clr.a)
		else
			local isWatched = localPlayer and simquery.isCellWatched( self:getSim(), localPlayer, cell.x, cell.y )
			if isWatched == simdefs.CELL_WATCHED then
				prop:setColor( cdefs.COLOR_WATCHED:unpack() )
			elseif isWatched == simdefs.CELL_NOTICED then
				prop:setColor( cdefs.COLOR_NOTICED:unpack() )
			else
				prop:setColor(defaultColor.r,defaultColor.g,defaultColor.b,defaultColor.a)
			end
		end

		table.insert(props, 1, prop)

		if ncell then
			local nx,ny = self:cellToWorld( ncell.x, ncell.y )
			local dx,dy = ncell.x-cell.x, ncell.y-cell.y

			local theta = math.atan2(dy,dx)
			local scale = math.sqrt( 2*dx*dx + 2*dy*dy)

			local prop = MOAIProp2D.new ()
			prop:setRot( math.deg(theta) )
			prop:setScl( scale, 1 )
			prop:setDeck ( lineTex )
			prop:setLoc( (x+nx)/2, (y+ny)/2 )
			if clr then
				prop:setColor(clr.r,clr.g,clr.b,clr.a)
			else
				local isWatched = localPlayer and simquery.isCellWatched( self:getSim(), localPlayer, ncell.x, ncell.y )
				if isWatched == simdefs.CELL_WATCHED then
					prop:setColor( cdefs.COLOR_WATCHED:unpack() )
				elseif isWatched == simdefs.CELL_NOTICED then
					prop:setColor( cdefs.COLOR_NOTICED:unpack() )
				else
					prop:setColor(defaultColor.r,defaultColor.g,defaultColor.b,defaultColor.a)
				end
			end

			table.insert(props, 1, prop)			
		end
	end

	local layer = self._layers["floor"]
	for _,prop in ipairs(props) do
		layer:insertProp(prop)
	end

	self._chainCells[ id ] = {props=props,duration=duration}

	return id
end
function boardrig:unchainCells( chain_id )
	local chain = self._chainCells[ chain_id ]
	if chain then
		self._chainCells[ chain_id ] = nil
		for _,prop in pairs( chain.props ) do
			self._layers["floor"]:removeProp ( prop )
		end
	end
end

function boardrig:hiliteRadius( ... )
    return self._zoneRig:hiliteRadius( ... )
end

function boardrig:hiliteCells( cells, clr, duration )
	return self._zoneRig:hiliteCells( cells, clr, duration )	
end

function boardrig:unhiliteCells( hiliteID )
	if hiliteID then
		self._zoneRig:unhiliteCells( hiliteID )
	end
end

function boardrig:selectUnit( unit )
	if unit ~= self.selectedUnit then
		if self.selectedUnit and self.selectedUnit:isValid() then
			local unitRig = self:getUnitRig( self.selectedUnit:getID() )
			if unitRig.selectedToggle then
				unitRig:selectedToggle( false )
			end
		end
		if unit and unit:isValid() and unit:getTraits().isAgent then	
			local unitRig = self:getUnitRig( unit:getID() )
			if unitRig.selectedToggle then
				unitRig:selectedToggle( true )
			end
		end
	end
	self.selectedUnit = unit
end

function boardrig:refreshFlags( cell )
	if cell then
		for i, cellUnit in ipairs( cell.units ) do
            local rig = self:getUnitRig( cellUnit:getID() )
            if rig and rig.refreshHUD then
                rig:refreshHUD( cellUnit )
            end
		end
	end
end

function boardrig:getSelectedUnit()
	return self.selectedUnit
end

function boardrig:getForeignPlayer( )
	return self._game:getForeignPlayer()
end

function boardrig:getLocalPlayer( )
	return self._game:getLocalPlayer()
end

function boardrig:getTeamColour( player )
	return self._game:getTeamColour( player )
end

function boardrig:getLastKnownCell( x, y )
	local localPlayer = self._game:getLocalPlayer()
	if localPlayer == nil then
		-- If there is no local player, just reveal everything (ie. the raw sim data)
		return self._game.simCore:getCell( x, y )
	else
		return localPlayer:getLastKnownCell( self._game.simCore, x, y )
	end
end

function boardrig:getLastKnownUnit( unitID )
	local localPlayer = self._game:getLocalPlayer()
	if localPlayer == nil then
		-- If there is no local player, just reveal everything (ie. the raw sim data)
		return self._game.simCore:getUnit( unitID )
	else
		return localPlayer:getLastKnownUnit( self._game.simCore, unitID )
	end
end

function boardrig:onTooltipCell( cellx, celly, oldx, oldy )
	local localPlayer = self._game:getLocalPlayer()
	if localPlayer then
		local oldcell = oldx and localPlayer:getCell( oldx, oldy )
		if oldcell then
			for i, unit in ipairs(oldcell.units) do
				local unitRig = self:getUnitRig( unit:getID() )
				if unitRig and unitRig.stopTooltip then
					unitRig:stopTooltip()
				end
			end
		end

		local cell = cellx and localPlayer:getCell( cellx, celly )
		if cell then
			for i, unit in ipairs(cell.units) do
				local unitRig = self:getUnitRig( unit:getID() )
				if unitRig and unitRig.startTooltip then
					unitRig:startTooltip()
				end
			end
		end
	end

	self._coverRig:refresh( cellx, celly )
	self._coverRig:setLocation( cellx, celly )
end

function boardrig:cameraFit( ... )
	self._game:getCamera():fitOnscreen( ... )
end

function boardrig:cameraCenterTwoPoints( x0,y0,x1,y1 )
	local x0w,y0w = self:cellToWorld( x0,y0 )
	local x1w,y1w = self:cellToWorld( x1,y1 )
    local camera = self._game:getCamera()
    local memento = camera:getMemento()
	camera:centerTwoPoints( x0w,y0w,x1w,y1w )
    camera:saveMemento( memento )
end


function boardrig:cameraLock( prop )
	self._game:getCamera():lockTo( prop )
end

function boardrig:cameraCentre()
	local units
	if self:getLocalPlayer() then
		units = self:getLocalPlayer():getUnits()
	else
		units = self._game.simCore:getAllUnits()
	end

	local cx, cy = simquery.calculateCentroid( self._game.simCore, units )
	if cx and cy then
		self._game:getCamera():zoomTo( 0.4 )
		self._game:cameraPanToCell( cx, cy )	
	end
end

function boardrig:wait( frames )
	while frames > 0 do
		frames = frames - 1
		coroutine.yield()
	end
end

function boardrig:onSimEvent( ev, eventType, eventData )

	local simdefs = self._game.simCore:getDefs()

	if eventType == simdefs.EV_UNIT_SPAWNED then
        -- ccc: 'stuff' DOES in fact happen before the EV_UNIT_SPAWN is dispatched, which happens at the end of the
        -- spawn sequence.  Therefore it is quite possible for the rig to already exist...
		--assert( self._unitRigs[ eventData.unit:getID() ] == nil )

	elseif eventType == simdefs.EV_UNIT_DESPAWNED then
		local unitRig = self:getUnitRig(  eventData.unitID )
		if unitRig then
			unitRig:refresh()
		end	

	elseif eventType == simdefs.EV_UNIT_REFRESH or
		   eventType == simdefs.EV_UNIT_CAPTURE or
		   eventType == simdefs.EV_UNIT_DEACTIVATE or
           eventType == simdefs.EV_UNIT_ACTIVATE or
		   eventType == simdefs.EV_UNIT_LOOKAROUND or
		   eventType == simdefs.EV_UNIT_SHOW_LABLE or
		   eventType == simdefs.EV_UNIT_RESET_ANIM_PLAYBACK or
		   eventType == simdefs.EV_UNIT_DRAG_BODY or
		   eventType == simdefs.EV_UNIT_DROP_BODY or
		   eventType == simdefs.EV_UNIT_BODYDROPPED or
		   eventType == simdefs.EV_UNIT_ADD_INTEREST or
		   eventType == simdefs.EV_UNIT_DEL_INTEREST or
		   eventType == simdefs.EV_UNIT_UPDATE_INTEREST or
		   eventType == simdefs.EV_UNIT_DONESEARCHING or
		   eventType == simdefs.EV_UNIT_TURN or	
		   eventType == simdefs.EV_UNIT_HIT_SHIELD or	   
		   eventType == simdefs.EV_UNIT_INSTALL_AUGMENT or
		   eventType == simdefs.EV_UNIT_HEAL or
		   eventType == simdefs.EV_UNIT_PLAY_ANIM or		   
		   eventType == simdefs.EV_UNIT_THROW or		   
		   eventType == simdefs.EV_GRENADE_EXPLODE or		   
		   eventType == simdefs.EV_UNIT_UNTIE or
		   eventType == simdefs.EV_UNIT_DEPLOY or
		   eventType == simdefs.EV_UNIT_PICKEDUP or
		   eventType == simdefs.EV_UNIT_UPDATE_SPOTSOUND or	
		   eventType == simdefs.EV_UNIT_TAGGED or			   	   
		   eventType == simdefs.EV_UNIT_RESCUED or			   	   
		   eventType == simdefs.EV_UNIT_GUNCHECK or		   
           eventType == simdefs.EV_UNIT_SPEAK or
           eventType == simdefs.EV_UNIT_ADD_FX or
           eventType == simdefs.EV_UNIT_DISGUISE or
           eventType == simdefs.EV_UNIT_TINKER_END or
           eventType == simdefs.EV_PULSE_SCAN or        
           eventType == simdefs.EV_UNIT_GOTO_STAND or  
           eventType == simdefs.EV_UNIT_SWTICH_FX or
           eventType == simdefs.EV_UNIT_MONST3R_CONSOLE then
           

		if eventData.unit:isValid() then
			local unitRig = self:getUnitRig(  eventData.unit:getID() )
			if unitRig then
				unitRig:onSimEvent( ev, eventType, eventData )		
			end
		end 
		
	elseif eventType == simdefs.EV_UNIT_MELEE then
		if eventData.finishMelee then
            self._game:getCamera():restoreMemento( 0.5 )
			self:wait( 60 )			

		elseif eventData.unit:isValid() then
			self:cameraLock( nil )

			local unitRig = self:getUnitRig(  eventData.unit:getID() )
			local targetRig = self:getUnitRig(  eventData.targetUnit:getID() )

		   	local x0,y0 = unitRig:getLocation()
		   	local x1,y1 = targetRig:getLocation()

		   	if x0 and y0 then
				self:cameraCenterTwoPoints(x0,y0,x1,y1)
				MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/markedForDeath_zoom")
			end	

            local blackout = include( "gameplay/viz_handlers/blackout" )
            local th = blackout( self, ev.viz, 180, targetRig, unitRig )
            th:unblock()
   	        ev.viz:addThread( th )

			self:wait( 15 )	
			if unitRig then
				unitRig:onSimEvent( ev, eventType, eventData )		
			end
		end
		

    elseif eventType == simdefs.EV_UNIT_KO then
        if self._shouldUnblockKO then
        	self._koUnits[eventData.unit:getID()] = eventData.unit
            ev.thread:unblock()
        end
		local unitRig = self:getUnitRig( eventData.unit:getID() )
        unitRig:onSimEvent( ev, eventType, eventData )
        if not self._shouldUnblockKO then
	        -- Refresh rigs on this location, as pinning status may have changed.
	        local cell = self:getSim():getCell( eventData.unit:getLocation() )
	        for _, cellUnit in ipairs( cell.units ) do
	            if cellUnit ~= eventData.unit then
	                local rig = self:getUnitRig( cellUnit:getID() )
	                if rig then
	                    ev.thread:waitForLocks( cellUnit:getID() )
	                    rig:refresh()
	                end
	            end
	        end
	    end

    elseif eventType == simdefs.EV_UNIT_SEEN or eventType == simdefs.EV_UNIT_UNSEEN then
        if eventData.player == self:getLocalPlayer() then
			local unitRig = self:getUnitRig( eventData.unit:getID() )
			if unitRig then
				unitRig:onSimEvent( ev, eventType, eventData )		
			end
        end

	elseif eventType == simdefs.EV_UNIT_WARPED then
		local unitID = eventData.unit:getID()
		local unitRig = self:getUnitRig( unitID )
		if unitRig then
			unitRig:onSimEvent( ev, eventType, eventData )
			if eventData.unit:getPlayerOwner() == self:getLocalPlayer() then
				if simquery.canHear( eventData.unit )  then
					self._world_sounds:refreshSounds()
				end
			else
				if eventData.unit:getTraits().movePath and self:canPlayerSeeUnit( unitRig:getUnit() ) then
					self:cameraLock( unitRig:getProp() )
				end
			end
		end
        
        -- Refresh flags for units at the previous and current location (for pinning indicator)
        self:refreshFlags( eventData.from_cell )
        self:refreshFlags( eventData.to_cell )

	elseif eventType == simdefs.EV_UNIT_RELOADED or
		   eventType == simdefs.EV_UNIT_DEATH then

		local unitID = eventData.unit:getID()
		local unitRig = self._unitRigs[ unitID ]
		unitRig:onSimEvent( ev, eventType, eventData )

		if eventData.to_cell and unitRig.getProp and self:canPlayerSeeUnit( unitRig:getUnit() ) then
			self:cameraLock( unitRig:getProp() )
		else
			self:cameraLock( nil )
		end

	elseif eventType == simdefs.EV_UNIT_START_WALKING or
		   eventType == simdefs.EV_UNIT_STOP_WALKING then

		local unitID = eventData.unit:getID()
		local unitRig = self._unitRigs[ unitID ]
		unitRig:onSimEvent( ev, eventType, eventData )

		if self:canPlayerSeeUnit( unitRig:getUnit() ) and eventType == simdefs.EV_UNIT_START_WALKING then
			self:cameraLock( unitRig:getProp() )
		else
			self:cameraLock( nil )
		end

	elseif eventType == simdefs.EV_UNIT_OVERWATCH or eventType == simdefs.EV_UNIT_OVERWATCH_MELEE then 

		self._game.hud:showMovementRange(self._game.hud:getSelectedUnit() )

		if eventData.unit:isValid() then
			local unitRig = self:getUnitRig( eventData.unit:getID() )

            if eventData.targetID then
                local targetRig = self:getUnitRig( eventData.targetID )
                if targetRig and unitRig then
                    local flash_units = include( "gameplay/viz_handlers/flash_units" )
        	        ev.viz:addThread( flash_units( self, ev.viz, unitRig, 60 ) )
    	            ev.viz:addThread( flash_units( self, ev.viz, targetRig, 60 ) )
                    local x0, y0 = eventData.unit:getLocation()
                    local x1, y1 = targetRig:getUnit():getLocation()
                    self:cameraCenterTwoPoints( x0, y0, x1, y1 )         
                    ev.thread:waitForLocks( eventData.targetID )
                    targetRig:refresh()
                end
            end
			
			if unitRig then
				unitRig:onSimEvent( ev, eventType, eventData )		
			end
		end


	elseif eventType == simdefs.EV_UNIT_INTERRUPTED then
		local unitRig = self:getUnitRig( eventData.unitID )
		unitRig:onSimEvent( ev, eventType, eventData )

	elseif eventType == simdefs.EV_UNIT_THROWN then
		local unitRig = self:getUnitRig(eventData.unit:getID() )
		if unitRig then

		   	local x0,y0 = unitRig:getLocation()
	   		if self:canPlayerSee(x0, y0) or self:canPlayerSee(eventData.x, eventData.y) then
				self:cameraLock(unitRig:getProp() )
			end

			unitRig:onSimEvent(ev, eventType, eventData)
		end


	elseif eventType == simdefs.EV_UNIT_START_SHOOTING then
		local unitRig = self:getUnitRig( eventData.unitID )
		local targetRig = nil
		if eventData.targetUnitID then
			targetRig = self:getUnitRig( eventData.targetUnitID )
            ev.thread:waitForLocks( eventData.targetUnitID )
		end

		unitRig:onSimEvent( ev, eventType, eventData )
        -- Setup camera pan.
		self:cameraLock( nil )

	   	local x0,y0 = unitRig:getLocation()
	   	local x1,y1 = nil,nil

	   	if eventData.targetUnitID then
	   	 	x1,y1 = targetRig:getLocation()			
	   	end
	   	if x1 and y1 then
            self:cameraCenterTwoPoints(x0,y0,x1,y1)
			MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/markedForDeath_zoom")
		end

		if eventType == simdefs.EV_UNIT_START_SHOOTING then

	        -- Setup shot UI display.
			local data = {
				isPC = unitRig:getUnit():isPC(),
				anim1 = unitRig:getUnit():getUnitData().profile_anim,
				attacker = util.toupper(unitRig:getUnit():getName()),
				defender = "",
			}

			if unitRig and unitRig:getUnit():getUnitData().profile_build then
				data.build1 = unitRig:getUnit():getUnitData().profile_build
	        else
	            data.build1 = data.anim1
			end
			if targetRig then				
	            data.anim2 = targetRig:getUnit():getUnitData().profile_anim
				data.defender = util.toupper(targetRig:getUnit():getName())
				if targetRig:getUnit():getUnitData().profile_build then
					data.build2 = targetRig:getUnit():getUnitData().profile_build	
	            else
	                data.build2 = data.anim2			
				end
			end

	    	if not unitRig:getUnit():isPC() then
	        	self._game.hud:showShotHaze( true )
	        end
			
			if unitRig then
				unitRig:playSound( "SpySociety/Attacks/aim" )
				MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/observe_guard" )			
			end

	        -- Flash the source and victim.
            local flash_units = include( "gameplay/viz_handlers/flash_units" )
	        ev.viz:addThread( flash_units( self, ev.viz, unitRig, 60 ) )
			if targetRig then
				targetRig:setPlayMode( KLEIAnim.STOP )
	   			ev.viz:addThread( flash_units( self, ev.viz, targetRig, 60 ) )
			end		  	

			self:wait( 60 )		 	
		
			self._game.hud:showShotHaze( false )
		end

    elseif eventType == simdefs.EV_UNIT_STOP_SHOOTING then
    	local unitRig = self:getUnitRig( eventData.unitID )
    	if unitRig then
    		unitRig:onSimEvent( ev, eventType, eventData )
    	end
        self._game:getCamera():restoreMemento()

	elseif eventType == simdefs.EV_UNIT_SHOT then
		self._unitRigs[ eventData.unitID ]:onSimEvent( ev, eventType, eventData )
		
	elseif eventType == simdefs.EV_UNIT_HIT then
		local unitRig = self:getUnitRig( eventData.unit:getID() )
		unitRig:onSimEvent( ev, eventType, eventData )		

	elseif eventType == simdefs.EV_UNIT_PEEK then
		self._unitRigs[ eventData.unitID ]:onSimEvent( ev, eventType, eventData )
		
	elseif eventType == simdefs.EV_UNIT_USEDOOR or eventType == simdefs.EV_UNIT_USEDOOR_PST then
		self._unitRigs[ eventData.unitID ]:onSimEvent( ev, eventType, eventData )

	elseif eventType == simdefs.EV_UNIT_PICKUP then
		self._unitRigs[ eventData.unitID ]:onSimEvent( ev, eventType, eventData )

	elseif eventType == simdefs.EV_UNIT_USECOMP then
		self._unitRigs[ eventData.unitID ]:onSimEvent( ev, eventType, eventData )

	elseif eventType == simdefs.EV_UNIT_MAINFRAME_UPDATE then	
		local zoom = self._game:getCamera():getZoom()	

		local sort = {}
		for i,unitID in pairs(eventData.units) do
			local unit = self:getSim():getUnit(unitID)
			local cell = self:getSim():getCell(unit:getLocation())
			local x0,y0 =self._game:cellToWnd(cell.x,cell.y)
			table.insert(sort,{x=x0,y=y0,item=unit:getID()})
		end

		table.sort( sort, function(l,r) return l.x < r.x end )

		local sorted = {}
		for i,set in ipairs(sort) do
			table.insert(sorted,set.item)
		end
		
		for i,unitID in ipairs( sorted )do	
			self._unitRigs[ unitID ]:onSimEvent( ev, eventType, eventData )
			if #sorted > 1 then
				self:wait( 30 )
			end
		end

    elseif eventType == simdefs.EV_MAINFRAME_INSTALL_NEW_DAEMON then
        local targetRig = self:getUnitRig( eventData.target:getID() )
        local params = {color ={{symbol="inner_line",r=1,g=0,b=0,a=0.75},{symbol="wall_digital",r=1,g=0,b=0,a=0.75},{symbol="boxy_tail",r=1,g=0,b=0,a=0.75},{symbol="boxy",r=1,g=0,b=0,a=0.75}} }
        targetRig:addAnimFx("fx/deamon_ko",  "effect",  "in",  true, params )
        targetRig:playSound("SpySociety/Actions/guard/MFghost_exitMF")
	elseif eventType == simdefs.EV_MAINFRAME_MOVE_DAEMON then
		local sourceRig = self:getUnitRig( eventData.source:getID() )
		local targetRig = self:getUnitRig( eventData.target:getID() )
		self:wait(18)


		local params = {color ={{symbol="inner_line",r=1,g=0,b=0,a=0.75},{symbol="wall_digital",r=1,g=0,b=0,a=0.75},{symbol="boxy_tail",r=1,g=0,b=0,a=0.75},{symbol="boxy",r=1,g=0,b=0,a=0.75}} }
		sourceRig:addAnimFx("fx/deamon_ko",  "effect",  "out",  true, params )
		sourceRig:playSound("SpySociety/Actions/guard/MFghost_enterMF")

		self:wait(80)
        local x0, y0 = eventData.source:getLocation()
        local x1, y1 = eventData.target:getLocation()
        self:cameraCenterTwoPoints(x1,y1,x1,y1)

		local params = {color ={{symbol="inner_line",r=1,g=0,b=0,a=0.75},{symbol="wall_digital",r=1,g=0,b=0,a=0.75},{symbol="boxy_tail",r=1,g=0,b=0,a=0.75},{symbol="boxy",r=1,g=0,b=0,a=0.75}} }
		targetRig:addAnimFx("fx/deamon_ko",  "effect",  "in",  true, params )
		targetRig:playSound("SpySociety/Actions/guard/MFghost_exitMF")
		self:wait(60)
        self._game:getCamera():restoreMemento()

	elseif eventType == simdefs.EV_UNIT_WIRELESS_SCAN then
		self._unitRigs[ eventData.unitID ]:onSimEvent( ev, eventType, eventData )				
	
	elseif eventType == simdefs.EV_UNIT_APPEARED then	
		self._unitRigs[ eventData.unitID ]:onSimEvent( ev, eventType, eventData )

	elseif eventType == simdefs.EV_SOUND_EMITTED then
		handleEmittedSound( self, eventData.x, eventData.y, eventData.sound, eventData.altVisTiles )
				
	elseif ev.eventType == simdefs.EV_SCANRING_VIS then
		if ev.eventData.unit == nil or (ev.eventData.unit:getPlayerOwner() == self:getSim():getCurrentPlayer() and self:getSim():getCurrentPlayer() == self:getLocalPlayer()) then
            local RING_PERIOD = 10
            local hilite = hilite_radius( ev.eventData.x, ev.eventData.y, ev.eventData.range )
            hilite:setRate( RING_PERIOD )
	        self:hiliteRadius( hilite )
		end

	elseif ev.eventType == simdefs.EV_OVERLOAD_VIZ then 
		handleOverloadViz( self, ev.eventData )
	elseif ev.eventType == simdefs.EV_FLASH_VIZ then 		
		handleFlashViz( self, eventData )
	elseif ev.eventType == simdefs.EV_CLOAK_IN then 
		--jcheng: wip cloak effect
		local x, y = ev.eventData.unit:getLocation()
		local wx, wy = self:cellToWorld( x, y )
		self._game.fxmgr:addAnimFx( { kanim = "fx/agent_cloak_fx", symbol = "effect", anim = "in", x = wx, y = wy, facingMask = KLEIAnim.FACING_W } )

	elseif ev.eventType == simdefs.EV_CLOAK_OUT then 
		--jcheng: wip cloak effect
		local x, y = ev.eventData.unit:getLocation()
		local wx, wy = self:cellToWorld( x, y )
		self._game.fxmgr:addAnimFx( { kanim = "fx/agent_cloak_fx", symbol = "effect", anim = "out", x = wx, y = wy, facingMask = KLEIAnim.FACING_W } )

	elseif ev.eventType == simdefs.EV_GAIN_AP then 
		--jcheng: wip cloak effect
		local x, y = ev.eventData.unit:getLocation()
		local wx, wy = self:cellToWorld( x, y )
		self._game.fxmgr:addAnimFx( { kanim = "fx/firewall_buff_fx", symbol = "effect", anim = "in", x = wx, y = wy, facingMask = KLEIAnim.FACING_W } )

	elseif eventType == simdefs.EV_EXIT_MODIFIED then
		if eventData then
			local doorRig = self:getDoorRig( eventData.cell, eventData.dir )
			if doorRig then
				doorRig:onSimEvent( ev, eventType, eventData )		
			end
		else
			self:refreshDoors()
		end
		self._world_sounds:refreshSounds()
		self:updateShadowMap()

	elseif ev.eventType == simdefs.EV_UNIT_GOALS_UPDATED then
        self._pathRig:regeneratePath( eventData.unitID )

	elseif eventType == simdefs.EV_LOS_REFRESH then
		if eventData.seer and eventData.seer:getPlayerOwner() == self:getLocalPlayer() then
			if #eventData.cells > 0 and eventData.seer:getLocation() then
                local reveal_los = include( "gameplay/viz_handlers/reveal_los" )
				self._game.viz:addThread( reveal_los( self, ev ) )
            else
                self:revealAll( self:getClientCells( eventData.cells ))
			end
			self._pathRig:refreshAllTracks()
		
		elseif eventData.player and eventData.player == self:getLocalPlayer() then
            self:revealAll( self:getClientCells( eventData.cells ) )
		end

		if eventData.seer then
			self:refreshLOSCaster( eventData.seer:getID() )
		end

	elseif eventType == simdefs.EV_HUD_REFRESH then
		self:refreshUnits()

	elseif eventType == simdefs.EV_WALL_REFRESH then
		self:refreshWalls()

    elseif eventType == simdefs.EV_KO_GROUP then
        -- Causes EV_UNIT_KO events to be handled in parallel (if eventData is true)
        if eventData then
        	if not self._koUnits then
        		self._koUnits = {}
        	end
        else
        	if self._koUnits then
	        	for id, unit in pairs(self._koUnits) do
		        	 -- Refresh rigs on this unit's location, as pinning status may have changed.
			        local cell = self:getSim():getCell(unit:getLocation() )
			        for _, cellUnit in ipairs( cell.units ) do
			            if not self._koUnits[cellUnit:getID()] then
			                local rig = self:getUnitRig( cellUnit:getID() )
			                if rig then
			                    ev.thread:waitForLocks( cellUnit:getID() )
			                    rig:refresh()
			                end
			            end
			        end

	                ev.thread:waitForLocks(id)
	            end
	          self._koUnits = nil
  	        end
        end
        self._shouldUnblockKO = eventData

	elseif eventType == simdefs.EV_TURN_END or eventType == simdefs.EV_TURN_START then
		self:refreshUnits( )
		self._pathRig:refreshAllTracks()

	elseif eventType == simdefs.EV_TELEPORT then
        local teleport_units = include( "gameplay/viz_handlers/teleport_units" )
		self._game.viz:addThread( teleport_units( self, ev ) )
	end
end

function boardrig:getSounds()
	return self._world_sounds
end

function boardrig:startSpotSounds( )
	assert( self._levelData.sounds )
	for i = 1, #self._levelData.sounds do
		local sound = self._levelData.sounds[i]
		if not sound.rattleRange then
			self._world_sounds:playSound( "SpySociety/"..sound.name, string.format("spot-%d", i ), sound.x, sound.y )
		end
	end
end

function boardrig:destroy( )
	self._world_sounds:destroy()

    local id, v = next( self._chainCells )
    while id do
        self:unchainCells( id )
        id, v = next( self._chainCells )
    end

	self._layers["floor"]:removeProp( self._grid )

	self._overlayRigs:destroy()
	self._overlayRigs = nil

	self._coverRig:destroy()
	self._coverRig = nil

	self._zoneRig:destroy()
	self._zoneRig = nil

	self._pathRig:destroy()
	self._pathRig = nil

	self._backgroundFX:destroy()

	while #self._dynamicRigs > 0 do
		table.remove( self._dynamicRigs ):destroy()
	end

	for id, cellRig in pairs(self._cellRigs) do
		cellRig:destroy()
	end
	self._cellRigs = nil

	for unitID,unitRig in pairs(self._unitRigs) do
		unitRig:destroy()
	end
	self._unitRigs = nil

	for i,wallRig in ipairs(self._wallRigs) do
		wallRig:destroy()
	end
	self._wallRigs = nil
	
	for i,doorRig in ipairs(self._doorRigs) do
		doorRig:destroy()
	end
	self._doorRigs = nil

	self._decorig:destroy()
	self._decorig = nil

	for i,lightRig in ipairs(self._lightRigs) do
		lightRig:destroy()
	end
	self._lightRigs = nil

	util.fullGC()
end

function boardrig:onUpdate()
	for i = #self._dynamicRigs,1,-1 do
		local dynamicRig = self._dynamicRigs[i]

		if not dynamicRig:onFrameUpdate() then
			dynamicRig:destroy()
			table.remove( self._dynamicRigs, i )
		end
	end


	self._floatTxtTimer = self._floatTxtTimer + 1
	if self._floatTxtTimer >= (60 * 1.8) then
		if self._floatTxt[1] then
			local data = table.remove( self._floatTxt, 1 )
			self:showFloatText( data.x0, data.y0, data.txt, data.color, data.sound, data.alwaysShow )
			self._floatTxtTimer = 0
		end
	end


	self._backgroundFX:update()
end

function boardrig:onStartTurn( isPC )
	
	self._game.boardRig._backgroundFX:transitionColor( isPC, 60 )
end

function boardrig:refresh( )
    local gfxOptions = self._game:getGfxOptions()
	if gfxOptions.bMainframeMode then
		self._grid:setShader( MOAIShaderMgr.getShader( MOAIShaderMgr.FLOOR_SHADER ) )
	else
		self._grid:setShader( MOAIShaderMgr.getShader( MOAIShaderMgr.FLOOR_SHADOW_SHADER ) )
        self._grid:getShaderUniforms():setUniformVector3( "ELOSC", 60.0/255.0, 95.0/255.0,100.0/255.0 )
	end

	self._world_sounds:refreshSounds()
	self:updateShadowMap()

	self:refreshBackgroundFX()
	self:refreshUnits( )
	self:refreshCells( )
	self:refreshDecor( )
	self._pathRig:refreshAllTracks()
end

function boardrig:setFocusCell( x, y )
	self._decorig:setFocusCell( x, y )
end

function boardrig:clearMovementTiles( )
	self._zoneRig:clearMovementTiles( )
end

function boardrig:setMovementTiles( tiles, grad, line )
	self._zoneRig:setMovementTiles( tiles, grad, line )
end

function boardrig:clearCloakTiles( )
	self._zoneRig:clearCloakTiles( )
end

function boardrig:setCloakTiles( tiles, grad, line )
	self._zoneRig:setCloakTiles( tiles, grad, line )
end

function boardrig:getPathRig()
	return self._pathRig
end

-----------------------------------------------------
-- create the boardRig

local function createGridProp( game, simCore, params )
	local boardWidth, boardHeight = simCore:getBoardSize()

	local grid = MOAIGrid.new ()
	grid:initRectGrid ( boardWidth, boardHeight, cdefs.BOARD_TILE_SIZE, cdefs.BOARD_TILE_SIZE )

	local tileDeck = MOAITileDeck2D.new ()
	local prop = MOAIProp2D.new ()

	if params.file then
		local mt = MOAIMultiTexture.new()
		mt:reserve( 6 )
		mt:setTexture( 1, params.file )
		mt:setTexture( 2, game.shadow_map )
		mt:setTexture( 3, "data/images/los_full.png" )
		mt:setTexture( 4, "data/images/los_partial.png" )
        mt:setTexture( 5, "data/images/los_full_cover.png" )
		mt:setTexture( 6, "data/images/los_partial_cover.png" )

		tileDeck:setShader( MOAIShaderMgr.getShader( MOAIShaderMgr.FLOOR_SHADER ) )
		tileDeck:setTexture ( mt )

	end
	tileDeck:setSize ( unpack(params) )
	tileDeck:setRect( -0.5, -0.5, 0.5, 0.5 )
	tileDeck:setUVRect( -0.5, -0.5, 0.5, 0.5 )

	
	prop:setDeck ( tileDeck )
	prop:setGrid ( grid )
	prop:setLoc( -boardWidth * cdefs.BOARD_TILE_SIZE / 2, -boardHeight * cdefs.BOARD_TILE_SIZE / 2)
	prop:setPriority( cdefs.BOARD_PRIORITY )
	prop:setDepthTest( false )

	prop:forceUpdate ()
	return prop, tileDeck
end

function boardrig:init( layers, levelData, game )
	local layer = layers["main"]   
	local simCore = game.simCore
	local boardWidth, boardHeight = simCore:getBoardSize()

	local sx,sy = 1.0 / (boardWidth * cdefs.BOARD_TILE_SIZE), 1.0 / (boardHeight * cdefs.BOARD_TILE_SIZE)
	MOAIGfxDevice.setShadowTransform( sx, sy, 0.5, 0.5)
	
	local grid = createGridProp( game, simCore, cdefs.LEVELTILES_PARAMS )
	layers["floor"]:insertProp ( grid )

	levelData = levelData:parseViz()

	self.BOARD_TILE_SIZE = cdefs.BOARD_TILE_SIZE
	self._levelData = levelData
	self._layers = layers
	self._layer = layer
	self._grid = grid
	self._game = game
	self._orientation = game:getCamera():getOrientation()
	self._zoneRig = nil
	self._unitRigs = {}
	self._wallRigs = {}
	self._doorRigs = {}
	self._lightRigs = {}
	self._cellRigs = {}
	self._chainCells = {}
    self._blindCells = {}
	self._boardWidth = boardWidth
	self._boardHeight = boardHeight

	self._floatTxt = {}
	self._floatTxtTimer = 0
	self._dynamicRigs = {}
			

	self:createCells( )
	self:createWallRigs( )	

	self._zoneRig = zonerig( layers["floor"], self )
	self._coverRig = coverrig.rig( self, layers["ceiling"] )
	self._pathRig = pathrig.rig( self, layers["floor"], layers["ceiling"] )

	self:createLightRigs( levelData )

	self._decorig = decorig( self, levelData, game.params )

	self._overlayRigs = overlayrigs( self, levelData )

	self._world_sounds = world_sounds( self )

	self._backgroundFX = fxbackgroundrig( self )

	-- Create rigs for pre-spawned units
	-- NOTE: the only reason we need to add this here is because there are
	-- units prespawned in sim:init(), before the rigs/viz is created, and therefore
	-- we cannot handle events as normal to initialize these guys.
	for unitID, unit in pairs(simCore:getAllUnits()) do
		local unitRig = self:createUnitRig( unitID )
	end
	
	-- Initialize board rig
	self:refresh()	

end

return boardrig
