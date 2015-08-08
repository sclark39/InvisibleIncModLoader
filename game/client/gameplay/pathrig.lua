----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local color = include( "modules/color" )
local resources = include( "resources" )
local mathutil = include( "modules/mathutil" )
local geo_util = include( "geo_util" )
local level = include( "sim/level" )

local PATH_COLOR = color( 1, 1, 1, 1 ) --color( 1, .1, .1, 1 )
local TRACKS_COLOR = color( 1, 1, .2, 1 )

local function refreshLineProp( boardRig, x0, y0, x1, y1, prop, clr )
	local x, y = boardRig:cellToWorld( x0, y0 )
	local nx,ny = boardRig:cellToWorld( x1, y1 )
	local dx,dy = x1 - x0, y1 - y0
	local theta = math.atan2(dy,dx)
	local scale = math.sqrt( 2*dx*dx + 2*dy*dy)

	prop:setRot( math.deg(theta) )
	prop:setScl( scale, 1 )
	prop:setLoc( (x+nx)/2, (y+ny)/2 )
	prop:setColor( clr:unpack() )
end

local function getTrackProp( pathrig )
	local prop = table.remove( pathrig._propPool )
	if prop == nil then
		prop = MOAIProp2D.new()
		prop:setDeck( resources.find( "Footprint" ) )
		prop:setColor( 1, 1, 0, 1 )
	end

	pathrig._layer:insertProp( prop )

	return prop
end

---------------------------------------------------------------

local pathrig = class()

function pathrig:init( boardRig, layer, throwLayer )
	self._boardRig = boardRig
	self._layer = layer
	self._throwLayer = throwLayer
	self._tracks = {} -- Table of unitID -> track props
	self._plannedPaths = {}
	self._plannedPathProps = {} -- Table of unitID -> path props
	self._plannedThrowProps = {} -- Table of unitID -> throw props
	self._propPool = {}
end

function pathrig:freeTracks( props )
	for i, trackProp in ipairs( props ) do
		self._layer:removeProp( trackProp )
		table.insert( self._propPool, trackProp )
	end
end

function pathrig:regeneratePath( unitID, maxDist)
	local sim = self._boardRig:getSim()
	local simquery = sim:getQuery()
	local unit = sim:getUnit( unitID )

	local st = os.clock()

	if unit ~= nil
	 and unit:getPather()
     and unit:getBrain()
	 and unit:getBrain():getDestination()
	 and not unit:getBrain():getDestination().unit
	 and (unit:getTraits().patrolObserved or unit:getTraits().tagged or self._boardRig:getLocalPlayer() == nil or self._boardRig:getLocalPlayer():isNPC() ) then
		local plannedPath = {}
		local movePoints = maxDist and math.min(unit:getTraits().mpMax, maxDist) or unit:getTraits().mpMax
		local path = unit:getPather():getPath(unit)
		if path and path.path and not path.result then
			local action, prevNode
			if path.currentNode then
				action = unit:getPather():getActionForNode(path, path.currentNode)
				prevNode = path.currentNode
				table.insert( plannedPath, {x=path.currentNode.location.x, y=path.currentNode.location.y, action=action, alwaysSeen = true } )
			end
			for i, node in ipairs(path.path:getNodes() ) do
				if movePoints and node and prevNode then
					local moveCost = simquery.getMoveCost(prevNode.location, node.location)
					movePoints = movePoints - moveCost
					if movePoints < 0 then
						break	--that's all the path we have time for right now
					end
				end
				action = unit:getPather():getActionForNode(path, node)
				table.insert( plannedPath, { x = node.location.x, y = node.location.y, action=action, alwaysSeen = true } )
				prevNode = node
			end
		end
		self._plannedPaths[ unitID ] = plannedPath
	else
		self._plannedPaths[ unitID ] = nil	
	end
	-- Refresh props
	self:refreshPlannedPath( unitID )
end

function pathrig:refreshPlannedPath( unitID )
	self._plannedPathProps[ unitID ] = self._plannedPathProps[ unitID ] or {}

	self:refreshProps( self._plannedPaths[ unitID ], self._plannedPathProps[ unitID ], PATH_COLOR )
	self:refreshThrowProp(unitID, PATH_COLOR)
end

function pathrig:refreshTracks( unitID, tracks )
	if config.NO_AI_TRACKS then
        tracks = nil
	end

	if tracks or self._tracks[ unitID ] then
		self._tracks[ unitID ] = self._tracks[ unitID ] or {}
		self:refreshProps( tracks, self._tracks[ unitID ], TRACKS_COLOR )
	end
end

function pathrig:refreshThrowProp(unitID, clr)
	local localPlayer = self._boardRig:getLocalPlayer()
	local path = self._plannedPaths[unitID]
	local throwPoint = nil
	if path then
		for i, pathPoint in ipairs(path) do
			if pathPoint.action and pathPoint.action.ability and pathPoint.action.ability == "throw" then
				throwPoint = pathPoint
				break
			end
		end
	end

	local prop = self._plannedThrowProps[unitID]
	if throwPoint then
		if not prop then
			prop = MOAIProp.new()
			self._throwLayer:insertProp( prop )
		end

		--todo: possible optimisation, don't regenerate throw mesh if it hasn't changed?
		local target = throwPoint.action.params[1]
	    local x0, y0 = self._boardRig:cellToWorld(throwPoint.x, throwPoint.y)
	    local x1, y1 = self._boardRig:cellToWorld(unpack(target) )

	    local clr = clr or color( 1, 1, 1, 1 )
		local msh = geo_util.generateArcMesh(self._boardRig, x0, y0, 0, x1, y1, 0, 30, 10)
		prop:setDeck(msh)
		prop:setLoc(x0, y0)
	else
		if prop then
			--clear the throw prop
			self._throwLayer:removeProp( prop )
			prop = nil
		end
	end
	self._plannedThrowProps[unitID] = prop
end


function pathrig:refreshProps( pathPoints, props, clr )
	-- Update extant tracks
	local localPlayer = self._boardRig:getLocalPlayer()
	local j = 1
	if pathPoints then
		for i = 2, #pathPoints do
			local prevPathPoint, pathPoint = pathPoints[i-1], pathPoints[i]
			local isSeen
			if prevPathPoint.alwaysSeen or pathPoint.alwaysSeen then
				-- Show track as long as long as the cell isn't blacked out
				isSeen = localPlayer == nil or localPlayer:getCell( pathPoint.x, pathPoint.y ) ~= nil or localPlayer:getCell( prevPathPoint.x, prevPathPoint.y ) ~= nil
			else
				-- Show track only if currently seen or previously seen/heard
				isSeen = pathPoint.isSeen or pathPoint.isHeard or self._boardRig:canPlayerSee( pathPoint.x, pathPoint.y ) 
			end
			if isSeen then
				props[j] = props[j] or getTrackProp( self )
				refreshLineProp( self._boardRig, prevPathPoint.x, prevPathPoint.y, pathPoint.x, pathPoint.y, props[j], clr )
				j = j + 1
			end
		end
	end

	-- Free the unused props.
	while j <= #props and #props > 0 do
		local prop = table.remove( props )
		self._layer:removeProp( prop )
		table.insert( self._propPool, prop )
	end
end

function pathrig:refreshAllTracks( )
    local sim = self._boardRig:getSim()
	local player = sim:getPC()
	for unitID, track in ipairs( player:getTracks() ) do
		if self._tracks[ unitID ] == nil then
			self._tracks[ unitID ] = {}
		end
	end

	for unitID, trackProps in pairs( self._tracks ) do
		self:refreshTracks( unitID, player:getTracks() )
	end

    for unitID, path in pairs( sim:getNPC().pather:getPaths() ) do
        if self._plannedPaths[ unitID ] == nil then
            self._plannedPaths[ unitID ] = {}
        end
    end

	for unitID, pathProps in pairs( self._plannedPaths ) do
		self:regeneratePath( unitID )
	end

end

function pathrig:destroy()
	for unitID, trackProps in pairs( self._tracks ) do
		self:freeTracks( trackProps )
	end
	for unitID, pathProps in pairs( self._plannedPathProps ) do
		self:freeTracks( pathProps )
	end
	for unitID, throwProp in pairs( self._plannedThrowProps ) do
		self._throwLayer:removeProp(throwProp)
	end

	self._tracks = nil
	self._plannedPathProps = nil
	self._plannedThrowProps = nil
	self._trackPool = nil
end


-----------------------------------------------------
-- Interface functions

return
{
	rig = pathrig
}
