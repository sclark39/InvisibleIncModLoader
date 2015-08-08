----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )
local astar = include( "modules/astar" )
local util = include( "client_util" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local astar_handlers = include( "sim/astar_handlers" )

local DEFAULT_MAX_OCCLUSION = 20

---------------------------------------------------------------------------
-- Calculates occlusion parameters for a sound.

local function calculateOcclusion( boardRig, x0, y0, maxRange )
	if not config.SOUND_OCCLUSION then
		return nil
	end

	local player = boardRig:getLocalPlayer()
	if player == nil then
		return 0
	end

    maxRange = maxRange or DEFAULT_MAX_OCCLUSION

	local sim = boardRig:getSim()
	local st = sim:getCell( x0, y0 )
    if not st then
        return 1 -- No cell at this location -> max occluded!
    end
	local punits = {}

	for i, unit in pairs( player:getUnits() ) do
        local x1, y1 = unit:getLocation()
		if x1 and (simquery.canHear( unit ) or unit:getTraits().hasAttenuationHearing) and not unit:isKO() and mathutil.dist2d( x0, y0, x1, y1 ) <= maxRange then
			table.insert( punits, unit )
		end
	end

    local zz = KLEIProfiler.Push( "calculateOcclusion-"..#punits.."-"..maxRange )
	table.sort( punits, function( u1, u2 ) return mathutil.distSqr2d( st.x, st.y, u1:getLocation() ) <
												  mathutil.distSqr2d( st.x, st.y, u2:getLocation() ) end )

	local handler = astar_handlers.sound_handler:new( sim, maxRange )
	local pather = astar.AStar:new( handler )
	local minHeard = maxRange
	for i, unit in ipairs( punits ) do
		local ft = sim:getCell( unit:getLocation() )
		if ft == st then
			minHeard = 0
			break
		else
			handler:setMaxDist( minHeard )
			local path = pather:findPath( st, ft )
			if path and path:getTotalMoveCost() < minHeard then
				minHeard = path:getTotalMoveCost()
			end
		end
	end

    KLEIProfiler.Pop( zz )
	--print( "OCCLUSION: ", minHeard / maxRange, "TOOK:", (os.clock() - stime) * 1000 )
	return minHeard / maxRange
end

---------------------------------------------------------------------------
-- Manages persistent in-world sounds.  These sounds have their occlusion
-- parameters updated according to the local player.

local world_sounds = class()

function world_sounds:init( boardRig )
	self._boardRig = boardRig
	self._sounds = {}
	self._occlusion = {}
    MOAIFmodDesigner.setListener( MOAIFmodDesigner.EVENT_SOUND_FINISHED,
        function( alias )
            local i = 1
            while i <= #self._sounds do
                local sound = self._sounds[i]
                if sound.alias == alias then
                    if sound.onFinish then
                        sound.onFinish()
                    end
                    table.remove( self._sounds, i )
                else
                    i = i + 1
                end
            end
        end )
end

function world_sounds:destroy()
    MOAIFmodDesigner.setListener( MOAIFmodDesigner.EVENT_SOUND_FINISHED, nil )
	while #self._sounds > 0 do
		MOAIFmodDesigner.stopSound( table.remove( self._sounds ).alias )
	end
end

local occ_dirs =
{
	simdefs.DIR_N,
	simdefs.DIR_E,
	simdefs.DIR_S,
	simdefs.DIR_W,
}

function world_sounds:refreshOcclusionMap()
	if not config.SOUND_OCCLUSION then
		return
	end

	local id = KLEIProfiler.Push( "refreshOcclusionMap" )

	util.tclear(self._occlusion)

	local player = self._boardRig:getLocalPlayer()
	if player == nil then
		return 0
	end

	local sim = self._boardRig:getSim()

	local frontier = {}

	local punits = {}
	for i, unit in pairs( player:getUnits() ) do
        local x1, y1 = unit:getLocation()
		if x1 and (simquery.canHear( unit ) or unit:getTraits().hasAttenuationHearing) and not unit:isKO() then
			table.insert( punits, unit )

			local cell = sim:getCell( unit:getLocation() )
			frontier[cell] = true
			self._occlusion[cell] = 0
		end
	end

	local next_frontier = {}

	local iterations = 0
	local cells_considered = 0
	while next(frontier) do
		for cell,_ in pairs(frontier) do
			cells_considered = cells_considered + 1

			local cost_so_far = self._occlusion[cell]
			if cost_so_far < DEFAULT_MAX_OCCLUSION then
				-- i don't just want exits, need to check object locations an agent can't walk as well
				for _,dir in ipairs(occ_dirs) do
					local dx, dy = simquery.getDeltaFromDirection(dir)

					local nx, ny = cell.x + dx, cell.y + dy
					local neighbour = sim:getCell(nx, ny)
					if neighbour and not frontier[neighbour] then
						local cost = cost_so_far + 1
						if simquery.isClosedDoor( cell.exits[ dir ] ) then
							cost = cost + 4
						end
						if not self._occlusion[neighbour] or self._occlusion[neighbour] > cost then
							self._occlusion[neighbour] = cost
							next_frontier[neighbour] = true
						end
					end
				end
			end
		end

		local tmp = frontier
		util.tclear(tmp)
		frontier = next_frontier
		next_frontier = tmp

		iterations = iterations + 1
	end

	--log:write( "refreshOcclusionMap completed for %d units in %d iterations, %d cells", #punits, iterations, cells_considered )
 
	KLEIProfiler.Pop( id )
end

function world_sounds:checkOcclusion( boardRig, x0, y0, maxRange )
	if not config.SOUND_OCCLUSION then
		return nil
	end

	local player = boardRig:getLocalPlayer()
	if player == nil then
		return 0
	end

	local id = KLEIProfiler.Push( "checkOcclusion" )
    maxRange = maxRange or DEFAULT_MAX_OCCLUSION

	local sim = self._boardRig:getSim()
	local cell = sim:getCell( x0, y0 )

    if not cell or not self._occlusion[cell] then
	    --log:write( "checkOcclusion at (%d, %d) found no cell info. could be past max range.", x0, y0 )
	    KLEIProfiler.Pop( id )
        return 1 -- No cell at this location -> max occluded!
    end

    local occlusion = self._occlusion[cell] / maxRange
    occlusion = occlusion > 1 and 1 or occlusion

    KLEIProfiler.Pop( id )
    return occlusion
end

function world_sounds:refreshSounds()
	local id = KLEIProfiler.Push( "refreshSounds" )

	self:refreshOcclusionMap()

	-- Refresh sound parameters for all sounds.
	for i, sound in ipairs( self._sounds ) do
		-- local occlusion = calculateOcclusion( self._boardRig, sound.x, sound.y, sound.maxOcclusion )
		local occlusion = self:checkOcclusion( self._boardRig, sound.x, sound.y, sound.maxOcclusion )
		MOAIFmodDesigner.setSoundProperties( sound.alias, nil, nil, occlusion )
		--log:write("REFRESH SOUND: '%s' (%d, %d); OCCLUSION: %.2f", sound.alias, sound.x, sound.y, occlusion )
	end
	KLEIProfiler.Pop( id )
end

function world_sounds:generateAlias( prefix )
    -- Generate a unique alias string when alias collisions are undesirable.
    self._nextAliasID = (self._nextAliasID or 0) + 1
    return string.format( "%s-%d", prefix, self._nextAliasID )
end

-- Track an in-world sound.
function world_sounds:playSound( soundPath, soundAlias, x0, y0, onFinish, maxOcclusion )
	local id = KLEIProfiler.Push( "playSound:"..soundPath )
	-- local occlusion = calculateOcclusion( self._boardRig, x0, y0, maxOcclusion )
	local occlusion = self:checkOcclusion( self._boardRig, x0, y0, maxOcclusion )
	MOAIFmodDesigner.playSound( soundPath, soundAlias, nil, { x0, y0, 0 }, occlusion )
	--log:write("WORLD SOUND: '%s' (%d, %d); OCCLUSION: %.2f", soundPath, x0, y0, occlusion )

	if soundAlias then
        --assert( array.findIf( self._sounds, function(sp) return sp.alias == soundAlias end ) == nil, soundAlias )
		table.insert( self._sounds, { alias = soundAlias, path = soundPath, maxOcclusion = maxOcclusion, x = x0, y = y0, onFinish = onFinish } )
	end
	KLEIProfiler.Pop( id )
end

-- Plays the nearest rattle sound within range of <x0, y0>
function world_sounds:playRattles( x0, y0, range )
	-- Find nearby rattle sounds.
	if self._boardRig._levelData.sounds then
		local closestRattle, closestRange = nil, range * range
		for i, sound in ipairs(self._boardRig._levelData.sounds) do
			local dist = mathutil.distSqr2d( sound.x, sound.y, x0, y0 )
			if dist < closestRange and dist < (sound.rattleRange or 0) * (sound.rattleRange or 0) then
				closestRattle, closestRange = sound, dist
			end
		end
		if closestRattle then
			--log:write( "RATTLE SOUND: <%s, %d, %d> due to <%d, %d>", closestRattle.name, closestRattle.x, closestRattle.y, x0, y0 )
			self:playSound( closestRattle.name, nil, closestRattle.x, closestRattle.y )
		end
	end
end

-- Stop a previously played sound
function world_sounds:stopSound( soundAlias )
	MOAIFmodDesigner.stopSound( soundAlias )

	for i, sound in ipairs( self._sounds ) do
		if sound.alias == soundAlias then
			table.remove( self._sounds, i )
			break
		end
	end
end

function world_sounds:isSoundPlaying(soundAlias)
	for i, sound in ipairs( self._sounds ) do
		if sound.alias == soundAlias then
			return true
		end
	end
	return false
end

-- Dynamically update a sound position
function world_sounds:updateSound( soundAlias, x0, y0 )
	for i, sound in ipairs( self._sounds ) do
		if sound.alias == soundAlias then
			if sound.x ~= x0 or sound.y ~= y0 then
				sound.x, sound.y = x0, y0
				-- local occlusion = calculateOcclusion( self._boardRig, x0, y0, sound.maxOcclusion )
				local occlusion = self:checkOcclusion( self._boardRig, x0, y0, sound.maxOcclusion )
				MOAIFmodDesigner.setSoundProperties( soundAlias,nil,{sound.x,sound.y,0}, occlusion )
				--log:write("UPDATE SOUND: '%s' (%d, %d); OCCLUDE: %.2f", sound.alias, sound.x, sound.y, occlusion )
			end
			break
		end
	end
end

return world_sounds
