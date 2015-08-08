----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local binops = include( "modules/binary_ops" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local level = include( "sim/level" )
local simdefs = include( "sim/simdefs" )
local simevents = include( "sim/simevents" )
local simunit = include( "sim/simunit" )
local pcplayer = include( "sim/pcplayer" )
local aiplayer = include( "sim/aiplayer" )
local line_of_sight = include( "sim/line_of_sight" )
local simquery = include( "sim/simquery" )
local simactions = include( "sim/simactions" )
local simfactory = include( "sim/simfactory" )
local simstats = include( "sim/simstats" )
local inventory = include( "sim/inventory" )
local abilitydefs = include( "sim/abilitydefs" )
local unitdefs = include( "sim/unitdefs" )
local skilldefs = include( "sim/skilldefs" )
local mainframe = include( "sim/mainframe" )
local rand = include ("modules/rand")
local speechdefs = include( "sim/speechdefs" )
local win_conditions = include( "sim/win_conditions" )
local cdefs = include( "client_defs" )
local simguard = include( "modules/simguard" )
local version = include( "modules/version" )
local alarm_states = include( "sim/alarm_states" )

--unit defs need to be included to register them in the simfactory
local simlaser = include( "sim/units/laser" )
local simturret = include( "sim/units/turret" )
local power_generator = include( "sim/units/power_generator" )
local simcamera = include( "sim/units/simcamera" )
local simgrenade = include( "sim/units/simgrenade" )
local simdisguiseitem = include( "sim/units/simdisguiseitem" )
local simsoundbug = include( "sim/units/simsoundbug" )
local simemppack = include( "sim/units/simemppack" )
local simtrap = include( "sim/units/simtrap" )
local simstore = include( "sim/units/store" )
local lock_decoder = include( "sim/units/lock_decoder" )
local simdrone = include( "sim/units/simdrone" )
local smoke_cloud = include( "sim/units/smoke_cloud" )
local simcameradrone = include( "sim/units/simcameradrone" )
local scanner = include( "sim/units/scanner" )
local usable_item = include( "sim/units/usable_item" )

--brain defs need to be included to register them in the simfactory
local guardbrain = include("sim/btree/guardbrain")
local guardbrainMelee = include("sim/btree/guardbrainMelee")
local dronebrain = include("sim/btree/dronebrain")
local pacifistbrain = include("sim/btree/pacifistbrain")
local wimpbrain = include("sim/btree/wimpbrain")

-----------------------------------------------------
-- Local functions

local function applyImpass( sim, unit, apply )

	local x, y = unit:getLocation()

	-- Remove impass from relevant cells
	local coords = {}

	if unit:getTraits().impass then
		coords = unit:getTraits().impass
	elseif unit:getTraits().cover then		
		coords = {0,0}
	end

	if coords then

		for i = 1,#coords,2 do
			local dx, dy = coords[i], coords[i+1]
			if dx ~= 0 or dy ~= 0 then
				dx, dy = simquery.rotateFacing( unit:getFacing(), dx, dy )
			end

			if i == 3 then
				local facing = unit:getFacing()
				if facing == simdefs.DIR_N then
					dx,dy = -1,0
				elseif facing == simdefs.DIR_E then
					dx,dy = 0,1
				elseif facing == simdefs.DIR_S then
					dx,dy = 1,0	
				else 
					dx,dy = 0,-1
				end
			end
			
			local coord_cell = sim:getCell( x + dx, y + dy )

		
			if coord_cell then
				-- Apply impass
				if unit:getTraits().impass then
					assert( coord_cell.impass + 1 * apply >= 0, string.format("Illegal impass: %d", coord_cell.impass + 1 * apply ))
					coord_cell.impass = coord_cell.impass + 1 * apply
				end
				-- Apply cover
				
				if unit:getTraits().cover then
					coord_cell.cover = (coord_cell.cover or 0) + 1 * apply
                    for dir, exit in pairs( coord_cell.exits ) do
                        if simquery.isOpenExit( exit ) then
                            for _, unit in ipairs( exit.cell.units ) do
                            	if unit:canHide() then
									sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit })
                        		end
                                sim:generateSeers( unit )
                            end
                        end
                    end
				end
			end
		end
	end
end

local function calculateUnitSeeUnit( sim, unit, targetUnit )
	if not unit:getLocation() or not targetUnit:getLocation() then
		return false
	end

	if not simquery.couldUnitSee( sim, unit, targetUnit ) then
		return false
	end

	local x, y = targetUnit:getLocation()
	if not x then
		return false
	end

	return sim._los:hasSight( unit, x, y )
end

local function calculatePlayerSeeUnit( sim, player, unit )
	-- Strictly speaking the player can only see a hidden unit if one if its units sees it.
	for i, playerUnit in ipairs( player:getUnits() ) do
		if calculateUnitSeeUnit( sim, playerUnit, unit ) then
			return true
		end
	end

	return false
end

-----------------------------------------------------
-- Sim interface

local simengine = class()


function simengine:init( params, levelData )
	
	self._resultTable = {credits_gained = {}, credits_lost = {}, agents = {}, new_programs = {}, loot = {}, guards = {}, devices = {}}

	self._players = {}
	self._units = {}
	self._stats = simstats()
	self._turnState = nil
	self._turn = 2 -- Uh, see _players table below; corresponds to PC.
	self._turnCount = 0
	self._actionCount = 0
	self._choiceCount = 0
	self._choices = {}
	self._nextID = 1000
	self._triggers = {}
	self._triggerDepth = 0
	self._tags = {}
    self._campaignTags = util.tcopy( params.tags or {} )
	self._winConditions = {}
	self._processTriggers = {}
    self._preSeers = {}
	self._tracker = 0
    self._trackerStage = 0
	self._cleaningKills = 0
	self._enforcersToSpawn = 0
	self._enforcerWavesSpawned = 0
	self._objectives = {}
    self._newLocations = {}
	self._missionReward = nil

	self._isClimax = false

	self._mainframeLockout = 0

	self._seed = params.seed or 0
	self._events = simevents( self )

	local levelOutput = levelData:parseBoard( params.seed, params )

	self._patrolGuard = levelOutput.patrolGuard

	self._params = params

	self._board = levelOutput.map

	self._los = line_of_sight( self )

    self:getTags().rewindsLeft = params.difficultyOptions.rewindsLeft

	self._levelScript = level.script_mgr( self )

	-- Create players.
    table.insert(self._players, aiplayer( self ))
    table.insert(self._players, pcplayer( self, params.agency ))

	self._icePrograms = util.tcopy( levelOutput.ice_programs or {} )
    self._rooms = levelOutput.rooms -- Procgen data DO NOT MODIFY.  Hey const would be nice!
    if self._rooms then
        self._mutableRooms = {}
        for i, procgenRoom in ipairs( self._rooms ) do
            self._mutableRooms[ i ] = {}
        end
    end

	-- Spawn level items.
	for i,levelUnit in ipairs(levelOutput.units) do
		local template = unitdefs.lookupTemplate( levelUnit.template )
		assert( template, string.format("Could not find template '%s'", levelUnit.template) )

		local unitData = util.extend( template )( levelUnit.unitData or {} )
		local unit = simfactory.createUnit( unitData, self )
		local player = nil
        if unit:getTraits().isGuard then
            player = self:getNPC()
        end

		if player then
			unit:setPlayerOwner( player )
		end

		local cell = self:getCell( levelUnit.x, levelUnit.y )
		if not cell then
			simlog( "Trying to spawn '%s' at non-existent cell (%d, %d)", levelUnit.template, levelUnit.x, levelUnit.y )
		end
		self:spawnUnit( unit )
		self:warpUnit( unit, cell )
		if player and player:isNPC() then
			unit:setPather(player.pather)
			if unit:getBrain() and player:getIdleSituation() then
				unit:getBrain():setSituation(player:getIdleSituation() )
                if unit:getTraits().patrolPath then
                    -- predefined patrol
                elseif unit:getTraits().nopatrol then
                    local x0, y0 = unit:getLocation()
                    unit:getTraits().patrolPath = { { x = x0, y = y0 } }
                elseif unit:getTraits().reconPatrol then 
                	-- つ ◕_◕ ༽つ give patrol path つ ◕_◕ ༽つ
                	--Hacky, but increase guard AP to make the path longer and then remove the extra AP. 
					local oldMP = unit:getTraits().mpMax
					unit:getTraits().mpMax = 25
					player:getIdleSituation():generatePatrolPath( unit, unit:getLocation() )
					unit:getTraits().mpMax = oldMP
                else 
	                if self:nextRand( 1, 3 ) > 1 then
		                -- 66% of guards have a patrol, otherwise they're stationary
                        player:getIdleSituation():generatePatrolPath( unit, unit:getLocation() )
                    else
                        player:getIdleSituation():generateStationaryPath( unit, unit:getLocation() )
                    end
                    local patrolPath = unit:getTraits().patrolPath
                    if patrolPath and #patrolPath > 0 and patrolPath[1].facing then
                        unit:updateFacing( patrolPath[1].facing )
                    end
                end
			end
		end
	end

	mainframe.init( self )

	if self:getCurrentPlayer() and not EDITOR then
        -- Initialize alarm state handlers according to difficulty.

        local alarmList = self:getAlarmTypes()
        
        for stage, alarmType in ipairs( simdefs.ALARM_TYPES[alarmList] ) do
            self:addTrigger( simdefs.TRG_ALARM_STATE_CHANGE, alarm_states[ alarmType ]( self, stage ) )
        end

		self:triggerEvent(simdefs.TRG_START_TURN, self:getCurrentPlayer() )		
		self:getCurrentPlayer():onStartTurn( self )		
		
	end

	for _, script in ipairs( params.scripts or {} ) do
		local path = "sim/missions/"
		if params.scriptPath then 
			path = params.scriptPath
		end
		self._levelScript:loadScript( path .. script )
	end
end

function simengine:getParams()
	return self._params
end

function simengine:isVersion( v1 )
    -- Is the mission parameter version at least v1?
    return version.isVersionOrHigher( self._params.missionVersion or "", v1 )
end

function simengine:getMainframeLockout()
    return self._mainframeLockout > 0
end

function simengine:setMainframeLockout( bool )
    if self:isVersion( "0.17.1" ) then
        if bool then
	        self._mainframeLockout = self._mainframeLockout + 1
        else
	        self._mainframeLockout = math.max( 0, self._mainframeLockout - 1 )
        end

    else
	    self._mainframeLockout = bool and 1 or 0
    end
end

function simengine:getHideDaemons( bool )
	if self._hideDaemons and self._hideDaemons > 0 then
		return true 
	end
	return false
end

function simengine:hideDaemons( bool )
	if bool == true then
		if self._hideDaemons then
		self._hideDaemons = self._hideDaemons + 1
		else
			self._hideDaemons = 1
		end
	else
		self._hideDaemons = self._hideDaemons - 1
	end
end

function simengine:setChoice( choice )
	--simlog( "CHOICE[ %d ] = %s", self._choiceCount, tostring(choice))
    assert( self._choices[ self._choiceCount ] == nil, "ILLEGAL CHOICE OVERRIDE" )
    assert( choice )
	self._choices[ self._choiceCount ] = choice
end

function simengine:getStats()
	return self._stats
end

function simengine:getCRC()
	local crc = self._nextID * self._seed
	for unitID, unit in pairs(self._units) do
		local cellx, celly = unit:getLocation()
		if cellx then
			crc = crc + unitID * (cellx + celly) % 101
		else
			crc = crc + unitID
		end
	end
	return crc -- Uh, not a crc by any means, but yeah.
end

local MAX_NEWCELL_DISTANCE = 10
function simengine:refreshUnitLOS( unit )
	assert( not unit:getTraits().refreshingLOS )
	unit:getTraits().refreshingLOS = true

	local x0, y0 = unit:getLocation()
	local losCoords = {}

	if x0 and simquery.couldUnitSee( self, unit ) then
		local cells = self._los:calculateUnitLOS( self:getCell( x0, y0 ), unit )
		for cellID, cell in pairs(cells) do
			table.insert( losCoords, cell.x )
			table.insert( losCoords, cell.y )
		end
	end

	local oldcells, newcells = self._los:refreshSight( unit:getID(), losCoords )	
    local updateCells = {}
	local playerOwner = unit:getPlayerOwner()
	local newCellCount = 0
	self._los:clearSight( unit:getID(), oldcells )
	if playerOwner then
		for i = 1, #oldcells, 2 do
			if not self:canPlayerSee( playerOwner, oldcells[i], oldcells[i+1] ) then
				playerOwner:markUnseen( self, oldcells[i], oldcells[i+1] )
                table.insert( updateCells, oldcells[i] )
                table.insert( updateCells, oldcells[i+1] )
			end
		end
		-- Haven't marked sight by new unit yet, otherwise we wouldn't be able to tell which cells are new to the PLAYER.
		-- This allows us to send TRG_APPEARED For newly appeared units.
		for i = 1, #newcells, 2 do
			if not self:canPlayerSee( playerOwner, newcells[i], newcells[i+1] ) then
				local cellWeight = 1
				if not playerOwner:getLastKnownCell(self, newcells[i], newcells[i+1]) then
					cellWeight = 5
				end
				playerOwner:markSeen( self, newcells[i], newcells[i+1] )
                if x0 then
                	local dist = mathutil.dist2d(x0, y0, newcells[i], newcells[i+1])
					newCellCount = newCellCount + cellWeight * math.max(0, MAX_NEWCELL_DISTANCE-dist)
				end

                table.insert( updateCells, newcells[i] )
                table.insert( updateCells, newcells[i+1] )
			end
		end
	end
	self._los:markSight( unit:getID(), newcells )

	-- Handle periphery sightedness.
    do
		local coords = {}
		local seerID = unit:getID() + simdefs.SEERID_PERIPHERAL
		if x0 and not unit:isKO() and unit:getTraits().LOSperipheralArc then
			local cells = self._los:calculatePeripheralLOS( self:getCell( x0, y0 ), unit )
			for cellID, cell in pairs(cells) do
				table.insert( coords, cell.x )
				table.insert( coords, cell.y )
			end
		end
		local oldcells, newcells = self._los:refreshSight( seerID, coords )
		self._los:clearSight( seerID, oldcells )
		self._los:markSight( seerID, newcells )
	end


	if #oldcells > 0 or #newcells > 0 then
		self:dispatchEvent( simdefs.EV_LOS_REFRESH, { seer = unit, cells = updateCells } )
	end

	local seeUnits = {}
	for i = 1, #losCoords, 2 do
		local cell = self:getCell( losCoords[i], losCoords[i+1] )
		for j, cellUnit in ipairs( cell.units ) do
			if simquery.couldUnitSee( self, unit, cellUnit ) and array.find( seeUnits, cellUnit ) == nil then
				table.insert( seeUnits, cellUnit )
			end
		end
	end

	unit:updateSeenUnits( seeUnits )
    if playerOwner then
    	playerOwner:updateSeenUnits()
    end

	unit:getTraits().cellvizCount = newCellCount
	unit:getTraits().refreshingLOS = nil
end


function simengine:win()
	local pc = self:getPC()
	for agentID, deployData in pairs( pc:getDeployed() ) do
		if not deployData.escapedUnit then
			local u = self:getUnit( deployData.id )
			if u and not u:isDead() then
				deployData.escapedUnit = u
				self:warpUnit( u, nil )
				self:despawnUnit( u )
			end
		end
	end

    -- Trigger escape, so that cheat-winning properly mimics escaping.
    for i, unit in ipairs( pc:getUnits() ) do
        if unit:hasAbility( "escape" ) then
            self:triggerEvent( simdefs.TRG_UNIT_ESCAPED, unit )
        end
    end

	self._winConditions = {}
	self:updateWinners()
end

function simengine:lose()
	self:addWinCondition( win_conditions.pcResigned )
	self:updateWinners()
end

function simengine:updateWinners()
    if self:isGameOver() then
        return
    end

	local passCount = 0
	for _, winFn in ipairs( self._winConditions ) do
		local result = winFn( self )
		if result == win_conditions.FAIL then
			self._turn = nil -- Game over.
		elseif result == win_conditions.PASS then
			passCount = passCount + 1
		end
	end
	if passCount == #self._winConditions then
		-- Game over
		simlog( "PC WINS!" )
		self._winner = util.indexOf( self._players, self:getPC() )
		self._turn = nil
	end

	if self:isGameOver() then
		self:triggerEvent( simdefs.TRG_GAME_OVER )
	end
end

function simengine:addWinCondition( fn )
	assert( type(fn) == "function" ) 
	table.insert( self._winConditions, fn )
end


function simengine:spawnUnit( unit )
	assert( unit:getLocation() == nil )

	assert( self._units[ unit:getID() ] == nil )
	self._units[ unit:getID() ] = unit

	if unit:hasTrait("hasSight") then
		self._los:registerSeer( unit:getID() )
	end
	if unit:getTraits().LOSperipheralArc then
		self._los:registerSeer( unit:getID() + simdefs.SEERID_PERIPHERAL )
	end

	for i,ability in ipairs(unit:getAbilities()) do
		ability:spawnAbility( self, unit )
	end

	for i,childUnit in ipairs(unit:getChildren()) do
		self:spawnUnit( childUnit )
	end

	if unit:getTraits().mainframe_ice and unit:getTraits().mainframe_iceMax then
		unit:getTraits().mainframe_ice = self:nextRand( unit:getTraits().mainframe_ice, unit:getTraits().mainframe_iceMax )
	end

	simlog( simdefs.LOG_SPAM, "SPAWN [%d] '%s'", unit:getID(), unit:getName())
	self:dispatchEvent( simdefs.EV_UNIT_SPAWNED, { unit = unit })

	if unit:getBrain() then
		unit:getBrain():onSpawned(self, unit)
	end

    if unit.onSpawn then
        unit:onSpawn( self )
    end

	if unit:getTraits().mainframe_item then
		self._resultTable.devices[unit:getID()] = { type = unit:getUnitData().id, hacked = false}
	end

	if unit:getTraits().isGuard then
		self._resultTable.guards[unit:getID()] = { type = unit:getUnitData().id, alerted = false, killed = false, distracted = false}
	end

	if unit:getTraits().mainframe_console then
		self._resultTable.total_consoles = self._resultTable.total_consoles and self._resultTable.total_consoles + 1 or 1 
	end

end

function simengine:despawnUnit( unit )
	assert( unit:getLocation() == nil )

    if unit.onDespawn then
        unit:onDespawn( self )
    end

	if unit:getBrain() then
		unit:getBrain():onDespawned()
	end

	if unit:getPlayerOwner() then
		unit:setPlayerOwner( nil )
	end

	self._units[ unit:getID() ] = nil

	if unit:hasTrait("hasSight") then
		self._los:unregisterSeer( unit:getID() )
	end
	if unit:getTraits().LOSperipheralArc then
		self._los:registerSeer( unit:getID() + 100000 )
	end
    if unit:getTraits().parasite then
        mainframe.removeParasite( self:getPC(), unit )
    end

	for i,ability in ipairs(unit:getAbilities()) do
		ability:despawnAbility( self, unit )
	end

	for i,childUnit in ipairs(unit:getChildren()) do
		self:despawnUnit( childUnit )
	end

	simlog( simdefs.LOG_SPAM, "DESPAWN '%s'", unit:getName())
	self:dispatchEvent( simdefs.EV_UNIT_DESPAWNED, { unitID = unit:getID() })

	unit:invalidate()
end

----------------------------------------------------------------------------------------
-- Warps a unit from its current location (if any) to a target location (if specified).
-- The unit is removed/added from the location(s) where applicable, and its LOS is refreshed.
--
-- => unit (the unit to warp)
-- => cell (the target location, may be nil)
-- => facing (optional facing to set)

function simengine:warpUnit( unit, cell, facing, reverse )
	assert( unit )
	assert( not unit:getTraits().isWarping )

	unit:getTraits().isWarping = true
	local wasHidden = simquery.checkIfNextToCover( unit:getSim(), unit )

	self:generateSeers( unit )
	local oldcell = self:getCell( unit:getLocation() )

	assert( oldcell ~= cell )
	if oldcell then
        local _, draggedBy = simquery.isUnitDragged( self, unit )
        if draggedBy then
            draggedBy:getTraits().movingBody = nil -- Really, stop moving me.
    		self:dispatchEvent( simdefs.EV_UNIT_BODYDROPPED, {unit = unit} )
        elseif cell == nil and unit:getTraits().movingBody then
    		local body = unit:getTraits().movingBody
            unit:getTraits().movingBody = nil -- Really, stop moving them.
    		self:dispatchEvent( simdefs.EV_UNIT_BODYDROPPED, {unit = body} )
        end

		applyImpass( self, unit, -1 )

		assert( array.find( oldcell.units, unit ))
		array.removeElement( oldcell.units, unit )

		unit:setLocation( nil, nil )
	else
		unit:getTraits().exitCell = nil
		unit:getTraits().entryCell = cell
	end

	if cell then
		table.insert(cell.units, unit)

		unit:setLocation( cell.x, cell.y )

		applyImpass( self, unit, 1 )
	else
		unit:getTraits().exitCell = cell
		unit:getTraits().entryCell = nil
	end

	unit:clearInvestigated()

	if unit:hasTrait("hasSight") then
		self:refreshUnitLOS( unit )
	end

	simquery.suggestAgentFacing(unit, facing)

	self:notifySeers()

	unit:getTraits().isWarping = nil

	-- Warp finally finished.  Viz should update!
	self:dispatchEvent( simdefs.EV_UNIT_WARPED, { unit = unit, from_cell = oldcell, to_cell = cell, facing = unit:getFacing(), reverse=reverse } )
                   
	if unit:getTraits().movingBody then
		self:warpUnit(unit:getTraits().movingBody, cell, facing, reverse)
	end
	
	-- At this point, the warp has effectively fully been established.
	-- Now provide hooks for this occurence; note that all bets are off if these hooks perform operations on 'unit',
	-- any recursive warping is strictly ILLEGAL!
	unit:onWarp(self, oldcell, cell)

	self:triggerEvent( simdefs.TRG_UNIT_WARP, { unit = unit, from_cell = oldcell, to_cell = cell } )
end


----------------------------------------------------------------------------------------
-- Locomotes a unit from its current cell through a sequence of adjacent connected cells.
-- Locomoting consumes the unit's AP, performs the actual warps and final facing, among
-- other things.
--
-- => unit (the unit to warp)
-- => moveTable (table of movements [x, y coordinates of connected cells])
-- => facing (final facing to set)

function simengine:moveUnit( unit, moveTable )
	moveTable = util.tdupe( moveTable )
	unit:getTraits().movePath = moveTable
	unit:getTraits().interrupted = nil
	unit:resetAllAiming()	

	if unit:getTraits().monster_hacking then 
		unit:getTraits().monster_hacking = false 
		unit:getSounds().spot = nil
		self:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit })
	end
	
    local zz = KLEIProfiler.Push( "moveUnit" )

	local steps, canMove, canMoveReason = nil, true, simdefs.CANMOVE_OK
	local totalMoves = #moveTable
	local moveCost = 0
	local door

	assert( totalMoves > 0 )
	local start_cell, end_cell
	
	self:startTrackerQueue(true)	

	local tilesMoved = 0


	if #moveTable > 0 and unit:getTraits().disguiseOn and not unit:getTraits().sneaking then
	 	unit:setDisguise(false)			
	end

	while #moveTable > 0 do
		local move = table.remove(moveTable, 1)
		start_cell = self:getCell( unit:getLocation() )
		end_cell = self:getCell( move.x, move.y )

		-- Must have sufficient movement available
		canMove, canMoveReason = simquery.canMoveUnit( self, unit, move.x, move.y )
		if not canMove then
			if canMoveReason == simdefs.CANMOVE_NOMP then
				end_cell = start_cell
				break
			end
		end

		local facing = simquery.getDirectionFromDelta( end_cell.x - start_cell.x, end_cell.y - start_cell.y )
		local reverse = math.abs(facing - unit:getFacing()) == 4
	
		if not steps and canMoveReason ~= simdefs.CANMOVE_NOMP and canMoveReason ~= simdefs.CANMOVE_DYNAMIC_IMPASS then
			steps = 0
			self:dispatchEvent( simdefs.EV_UNIT_START_WALKING, { unit = unit, reverse=reverse  } )
		end

		if facing ~= unit:getFacing() then	
			unit:updateFacing( facing )
		
			--the facing change might invalidate our unit
	 		if not unit:isValid() or unit:getTraits().interrupted or unit:isKO() then
				canMoveReason = simdefs.CANMOVE_INTERRUPTED
				break
			end
		end

		-- need to open door if its in the way
		for dir,exit in pairs(start_cell.exits) do
			if exit.cell == end_cell then
				if exit.door and exit.closed and simquery.canModifyExit( unit, simdefs.EXITOP_OPEN, start_cell, dir ) then
					local stealth  = unit:getTraits().sneaking
					self:modifyExit( start_cell, dir, simdefs.EXITOP_OPEN, unit , stealth )
					door = {cell=start_cell, dir=dir, stealth=stealth}
					if exit.keybits == simdefs.DOOR_KEYS.GUARD then
						door.forceClose = true
					end
				end
				break
			end
		end

		--the door opening might invalidate our unit
 		if not unit:isValid() or unit:getTraits().interrupted or unit:isKO() then
			canMoveReason = simdefs.CANMOVE_INTERRUPTED
			break
		end

	
		-- if possible, turn lasers off while moving
		canMove, canMoveReason = simquery.canMoveUnit( self, unit, move.x, move.y )
		if canMoveReason == simdefs.CANMOVE_DYNAMIC_IMPASS then
            for _, cellUnit in ipairs( end_cell.units ) do
                if cellUnit:getTraits().emitterID and cellUnit:canControl( unit ) then
                    cellUnit:deactivate( self )
                end
            end
            canMove, canMoveReason = simquery.canMoveUnit( self, unit, move.x, move.y )
        end

		--the laser changing might invalidate our unit
 		if not unit:isValid() or unit:getTraits().interrupted or unit:isKO() then
			canMoveReason = simdefs.CANMOVE_INTERRUPTED
			break
		end

		self:triggerEvent( simdefs.TRG_UNIT_WARP_PRE, { unit = unit, from_cell = start_cell, to_cell = end_cell } )
		--triggering a warp_pre might invalidate our unit
 		if not unit:isValid() or unit:getTraits().interrupted or unit:isKO() then
			canMoveReason = simdefs.CANMOVE_INTERRUPTED
			break
		end

		if not canMove then
			-- The move order is based on player-centric (limited) information, so it may not ACTUALLY be possible to do the move. If not, just abort.
			assert( canMoveReason and canMoveReason ~= simdefs.CANMOVE_OK )
			break
		end

		if unit:getPlayerOwner() ~= self:getPC() then
			if steps == 0 then
				self:getPC():trackFootstep( self, unit, start_cell.x, start_cell.y )
			end
			self:getPC():trackFootstep( self, unit, end_cell.x, end_cell.y )
		end
		
		-- Must consume MP before warping or it won't be consumed if an interrupt occurs!
		local moveCost = nil
		if unit:getTraits().movingBody then

			local dragCost = simdefs.DRAGGING_COST

			if unit:hasTrait("dragCostMod") then
				dragCost = dragCost -  unit:getTraits().dragCostMod
			end

			--easier to drag agents
			local body = unit:getTraits().movingBody
			if not body:getTraits().isGuard then
				dragCost = dragCost - 1
			end

			--never improve moving if you're dragging!
			dragCost = math.max(simdefs.MIN_DRAGGING_COST, dragCost)

			moveCost =  simquery.getMoveCost( start_cell, end_cell ) * dragCost
		elseif unit:getTraits().sneaking then
			moveCost = simquery.getMoveCost( start_cell, end_cell ) * simdefs.SNEAKING_COST
		else 
			moveCost = simquery.getMoveCost( start_cell, end_cell )
		end
		unit:useMP(moveCost, self )

		self:warpUnit( unit, end_cell, facing, reverse ) 		

		-- Warp unit can possibly trigger this unit to despawn
 		if not unit:isValid() then
			canMoveReason = simdefs.CANMOVE_INTERRUPTED
			break
		end

		self:emitSound( { hiliteCells = unit:isPC(), range = simquery.getMoveSoundRange( unit, start_cell ) }, end_cell.x, end_cell.y, unit )

		if unit:getTraits().cloakDistance and unit:getTraits().cloakDistance > 0 then
			unit:getTraits().cloakDistance = unit:getTraits().cloakDistance - moveCost
			if unit:getTraits().cloakDistance <= 0 then
				unit:setInvisible(false)
				unit:getTraits().cloakDistance = nil
			end
		end

		-- If interrupted or otherwise KO'd from warpUnit, abort now.
		if unit:getTraits().interrupted or unit:isKO() then
			canMoveReason = simdefs.CANMOVE_INTERRUPTED
			break
		end
		
		self:processReactions( unit )

		if unit:isValid() and #moveTable == 0 and move.facing then
			unit:updateFacing( move.facing )
		end
		
		steps = steps + 1

		-- Retaliatory actions taken during the move may invalidate this unit.
 		if not unit:isValid() or unit:getTraits().interrupted or unit:isKO() then
			canMoveReason = simdefs.CANMOVE_INTERRUPTED
			break
		end

		--close door if we just went through it
		if door and not door.cell.exits[door.dir].closed and unit:getTraits().closedoors and (unit:getTraits().walk == true or door.forceClose) then
			self:modifyExit( door.cell, door.dir, simdefs.EXITOP_CLOSE, unit , door.stealth )
			door = nil
		end
		tilesMoved = tilesMoved + 1
	end

	if unit:isValid() then
		unit:getTraits().movePath = nil
		unit:getTraits().interrupted = nil
		if steps then
			self:dispatchEvent( simdefs.EV_UNIT_STOP_WALKING, { unit = unit  } )
		end
	end
	self:startTrackerQueue(false)				

    KLEIProfiler.Pop( zz )

	return canMoveReason, end_cell
end

----------------------------------------------------------------------------------------
-- Generic function to modify an existing exit out of a cell.
-- Operations include things like opening/closing or locking doors, etc.  These operations
-- must be valid given the exit's current state.  This function's responsbiility is simply
-- to update that state accordingly.
--
-- => cell (the cell that contains the exit)
-- => dir (the direction of the exit, which must exist)
-- => exitOp (operation to perform)

function simengine:modifyExit( cell, dir, exitOp, unit, stealth) 
	local exit = cell.exits[dir]
	assert( exit )

	local rdir = simquery.getReverseDirection( dir )
	local reverseExit = exit.cell.exits[ rdir ]
	assert( reverseExit )

	if unit then
		unit:getTraits().modifyingExit = exit
	end

	local incAlarm = false 

	local altCell = cell.exits[dir].cell

	if exitOp == simdefs.EXITOP_OPEN then
		assert( exit.door and reverseExit.door )
		assert( exit.closed and reverseExit.closed )
		assert( not exit.locked and not reverseExit.locked )
		exit.closed, reverseExit.closed = nil, nil
		self:getLOS():removeSegments( cell, dir, exit.cell, rdir )
		self:emitSound( exit.openSound, cell.x, cell.y, unit, {{x=altCell.x,y=altCell.y}} )
		if self:getCurrentPlayer() ~= self:getNPC() then		
			self:getNPC().pather:invalidatePathsCrossingCell(cell.x, cell.y)		
			self:getNPC().pather:invalidatePathsCrossingCell(altCell.x, altCell.y)
			self:triggerEvent( simdefs.TRG_OPEN_DOOR, { unit = unit } )
		end

		if self:getTags().doors_alarmOnOpen and unit:isPC() and not exit.door_disarmed then
			incAlarm = true			
		end

	elseif exitOp == simdefs.EXITOP_CLOSE then
		assert( exit.door and reverseExit.door )
		assert( not exit.closed and not reverseExit.closed )
		exit.closed, reverseExit.closed = true, true
		self:getLOS():insertSegments( cell, dir, exit.cell, rdir )
		self:emitSound( exit.closeSound, cell.x, cell.y, unit, {{x=altCell.x,y=altCell.y}})		
		if self:getCurrentPlayer() ~= self:getNPC() then		
			self:getNPC().pather:invalidatePathsCrossingCell(cell.x, cell.y)		
			self:getNPC().pather:invalidatePathsCrossingCell(altCell.x, altCell.y)
			self:getNPC().pather:invalidatePathsWithThrows()
		end

	elseif exitOp == simdefs.EXITOP_TOGGLE_DOOR then
		assert( exit.door and reverseExit.door )
		if exit.closed then
			exit.closed, reverseExit.closed = nil, nil
			self:getLOS():removeSegments( cell, dir, exit.cell, rdir )
			self:emitSound( exit.openSound, cell.x, cell.y, unit, {{x=altCell.x,y=altCell.y}})
			self:triggerEvent( simdefs.TRG_OPEN_DOOR, { unit = unit } )	

			if self:getTags().doors_alarmOnOpen and unit:isPC() then
				self:trackerAdvance( 1 )
			end
		else
			exit.closed, reverseExit.closed = true, true
			self:getLOS():insertSegments( cell, dir, exit.cell, rdir )
			self:emitSound( exit.closeSound, cell.x, cell.y, unit, {{x=altCell.x,y=altCell.y}})
		end

	elseif exitOp == simdefs.EXITOP_LOCK then
		assert( exit.door and reverseExit.door )
		assert( exit.keybits and reverseExit.keybits )
		assert( not exit.locked and not reverseExit.locked )
		exit.locked, reverseExit.locked = true, true

	elseif exitOp == simdefs.EXITOP_UNLOCK then
		assert( exit.door and reverseExit.door )
		assert( exit.keybits and reverseExit.keybits )
		assert( exit.locked and reverseExit.locked )
		exit.locked, reverseExit.locked = nil

		if self:isVersion("0.17.5") then
					
			if exit.keybits == simdefs.DOOR_KEYS.VAULT then
				for i,item in ipairs(unit:getChildren()) do
					if item:getTraits().keybits == simdefs.DOOR_KEYS.VAULT then
						self:triggerEvent( simdefs.TRG_UNLOCK_DOOR, { cell = cell, tocell = exit.cell, unit = unit } )
						inventory.trashItem( self, unit, item )
						break
					end
				end
	        elseif exit.keybits == simdefs.DOOR_KEYS.SPECIAL_EXIT then
	        	local key = nil
				for i,item in ipairs(unit:getChildren()) do
					if item:getTraits().keybits == simdefs.DOOR_KEYS.SPECIAL_EXIT then
						key = item
						break
					elseif simquery.isKey( item, simdefs.DOOR_KEYS.SPECIAL_EXIT ) and not simquery.isKey( item, simdefs.DOOR_KEYS.VAULT )  then
						key = item
						-- Keep searching, we prioritize SPECIAL_EXIT keys precisely.
					end
				end
				if key then
					inventory.trashItem( self, unit, key )
				end            
			end	
		else
			---------------------------------------------------------------------------------------------------------------
			--#############################################################################################################			
			--#############################################################################################################			
			-- This is to replicate the old function of the keys for games before version 17.5 as simdefs was changed from :
			--				SPECIAL_EXIT = 32 + 256, to 
			--				SPECIAL_EXIT = 256
			if exit.keybits == simdefs.DOOR_KEYS.VAULT then
				for i,item in ipairs(unit:getChildren()) do
					if item:getTraits().keybits == simdefs.DOOR_KEYS.VAULT then
						self:triggerEvent( simdefs.TRG_UNLOCK_DOOR, { cell = cell, tocell = exit.cell, unit = unit } )
						inventory.trashItem( self, unit, item )
						break
					elseif item:getTraits().keybits == simdefs.DOOR_KEYS.SPECIAL_EXIT then
						self:triggerEvent( simdefs.TRG_UNLOCK_DOOR, { cell = cell, tocell = exit.cell, unit = unit } )
					end
				end
	        elseif exit.keybits == simdefs.DOOR_KEYS.SPECIAL_EXIT then
	        	local key = nil
				for i,item in ipairs(unit:getChildren()) do
					if item:getTraits().keybits == simdefs.DOOR_KEYS.SPECIAL_EXIT or item:getTraits().keybits == simdefs.DOOR_KEYS.VAULT then
						key = item
						break
					elseif simquery.isKey( item, simdefs.DOOR_KEYS.SPECIAL_EXIT ) or simquery.isKey( item, simdefs.DOOR_KEYS.VAULT ) then
						key = item
						-- Keep searching, we prioritize SPECIAL_EXIT keys precisely.
					end
				end
				if key then
					inventory.trashItem( self, unit, key )
				end            
			end			
			--#############################################################################################################
			--#############################################################################################################
			---------------------------------------------------------------------------------------------------------------
		end

		if unit then
			self:emitSound( simdefs.SOUND_DOOR_UNLOCK, cell.x, cell.y, unit)
		end

	elseif exitOp == simdefs.EXITOP_TOGGLE_LOCK then
		assert( exit.door and reverseExit.door )
		assert( exit.keybits and reverseExit.keybits )
		if exit.locked then
			exit.locked, reverseExit.locked = nil, nil
		else
			exit.locked, reverseExit.locked = true, true
		end

	elseif exitOp == simdefs.EXITOP_BREAK_DOOR then
		assert( exit.door and reverseExit.door )
		assert( exit.closed and reverseExit.closed )
		assert( not exit.locked and not reverseExit.locked )

		exit.closed, reverseExit.closed = nil, nil
		exit.locked, reverseExit.locked = true, true		
		self:getLOS():removeSegments( cell, dir, exit.cell, rdir )
		self:emitSound( exit.breakSound, cell.x, cell.y, unit, {{x=altCell.x,y=altCell.y}} )		
		if self:getCurrentPlayer() ~= self:getNPC() then		
			self:getNPC().pather:invalidatePathsCrossingCell(cell.x, cell.y)		
			self:getNPC().pather:invalidatePathsCrossingCell(altCell.x, altCell.y)
		end

	elseif exitOp == simdefs.EXIT_DISARM then	
		assert( exit.door and reverseExit.door )
		exit.door_disarmed = true
		reverseExit.door_disarmed = true
		unit:useMP( 3, self )
		local x1, y1 = unit:getLocation()
		self:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, {txt="ALARM DISABLED",x=x1,y=y1,color={r=163/255,g=0,b=0,a=1},alwaysShow=true} )		
	end

	self:dispatchEvent( simdefs.EV_EXIT_MODIFIED, { cell = cell, dir = dir, exitOp = exitOp } )

	-- Refresh LOS for any unit whose LOS arc intersects the exit.
	if exitOp == simdefs.EXITOP_TOGGLE_DOOR or exitOp == simdefs.EXITOP_CLOSE or exitOp == simdefs.EXITOP_OPEN or exitOp == simdefs.EXITOP_BREAK_DOOR then
		--use the door before refreshing LOS
		self:triggerEvent( simdefs.TRG_UNIT_USEDOOR_PRE, { exitOp = exitOp, cell = cell, tocell = exit.cell, unit = unit } )

        local seers = {}
        for unitID, seerUnit in pairs(self:getAllUnits()) do
        	local x0, y0 = seerUnit:getLocation()
            if seerUnit:getTraits().hasSight and x0 then
                local nx, ny = exit.cell.y - cell.y, exit.cell.x - cell.x  -- normal of exit.cell -> exit.cell
                local cx, cy = (cell.x + exit.cell.x) / 2, (cell.y + exit.cell.y) / 2
                if (x0 == cell.x and y0 == cell.y) or (x0 == exit.cell.x and y0 == exit.cell.y) or
                	self:getLOS():withinLOS( seerUnit, cx + nx/2, cy + ny/2, cx - nx/2, cy - ny/2 ) then
                    table.insert( seers, unitID )
                end
            end
        end

		for i, seerID in ipairs(seers) do
			local seerUnit
			if seerID >= simdefs.SEERID_PERIPHERAL then
				seerUnit = self:getUnit( seerID - simdefs.SEERID_PERIPHERAL )
			else
				seerUnit = self:getUnit( seerID )
			end

			if seerUnit then
				if seerUnit:hasTrait("hasSight") then
					self:refreshUnitLOS( seerUnit )
				end

				-- Make sure to also refresh the exit knowledge on either side of the exit.
				if seerUnit:getPlayerOwner() then
					seerUnit:getPlayerOwner():glimpseExit( cell.x, cell.y, dir )
				end
			end
		end

		self:triggerEvent( simdefs.TRG_UNIT_USEDOOR, { exitOp = exitOp, cell = cell, tocell = exit.cell, unit = unit } )
	end

	if exitOp == simdefs.EXITOP_BREAK_DOOR then
		--knock out any suckers on the other side of the door
		for i,targetUnit in ipairs(altCell.units) do
			if simquery.isAgent(targetUnit) and not targetUnit:isKO() and not targetUnit:isDead() and targetUnit:getArmor() == 0 then
				self:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.DOOR_SLAMMED,x=altCell.x,y=altCell.y,color={r=163/255,g=0,b=0,a=1},alwaysShow=true} )
				local koCount = 1
				if self:getCurrentPlayer() == targetUnit:getPlayerOwner() then
					--If a guard is knocked out on their own turn, they should still go down for a turn
					koCount = 2
				end
				if targetUnit:getTraits().canKO then
					targetUnit:setKO(self, koCount)
				elseif targetUnit:getTraits().isDrone and targetUnit.deactivate then
					targetUnit:deactivate(self)
				end
			end
		end
	end

	if unit and unit:isValid() and not unit:getTraits().interrupted then
		self:processReactions( unit )
	end

	if unit then
		unit:getTraits().modifyingExit = nil
	end

	if incAlarm then
		self:trackerAdvance( 1 )
	end
end

----------------------------------------------------------------------------------------
-- Causes sourceUnit to attempt to shoot at the location (x1, y1) with the given damage
-- parameters, which determines things like accuracy and damage.  The shot is raycast
-- from source unit's location, and may hit things that intersect along the way.

function simengine:tryShootAt( sourceUnit, targetUnit, dmgt0, equipped )

	sourceUnit:setInvisible( false )
	sourceUnit:setDisguise(false)
	
	local x0, y0 = sourceUnit:getLocation()
	local x1,y1 = targetUnit:getLocation()
	local evData = { unitID = sourceUnit:getID(), x0 = x0, y0 = y0, x1=x1, y1=y1, dmgt = dmgt0 } 	
	if x0 == x1 and y0 == y1 then
		evData.facing = targetUnit:getFacing()
	end
	
	self:dispatchEvent( simdefs.EV_UNIT_SHOT, evData )

	-- Copy table, will be modified.
	local dmgt = simquery.calculateShotSuccess( self, sourceUnit, targetUnit, equipped )

	if equipped:getTraits().canTag then
		targetUnit:setTagged()		
	end

	if not dmgt.armorBlocked then 
		self:hitUnit( sourceUnit, targetUnit, dmgt )
	end

	if targetUnit:isValid() and targetUnit:getPlayerOwner() then
		targetUnit:interruptMove( self )
		self:triggerEvent( simdefs.TRG_UNIT_SHOT, { targetUnit = targetUnit, sourceUnit = sourceUnit } )
	end

	-- Process emitting of sound of gun shot at the end. Actual audio is played through the shot anim.
	if not sourceUnit:getTraits().silencer then	
		self:emitSound( simdefs.SOUND_MED, x0, y0, sourceUnit )
	end
end

function simengine:processReactions( sourceUnit )
	self:triggerEvent( simdefs.TRG_OVERWATCH, sourceUnit )
    self:getNPC():processReactions( sourceUnit )
end

function simengine:getTags()
	return self._tags
end

function simengine:hasTag( tag )
	return self._tags[ tag ] ~= nil
end

function simengine:getCampaignTags()
	return self._campaignTags
end

function simengine:damageUnit( targetUnit, srcDamage, kodamage, fx, sourceUnit )
	local x1,y1 = targetUnit:getLocation()
	local damage = srcDamage

	targetUnit:setInvisible(false)
	targetUnit:setDisguise(false)


	if not targetUnit:getTraits().steadyAim then
		targetUnit:setAiming(false)
	end

	if targetUnit:getTraits().temporaryProtect then 
		targetUnit:getTraits().temporaryProtect = false
		self:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.PERSONAL_SHIELD,x=x1,y=y1,color={r=1,g=1,b=0,a=1}} )

	elseif targetUnit:isDead() then
		-- Already Critical?  Do nothing.

	else
		if targetUnit:getTraits().neutralize_shield then 
			if targetUnit:getTraits().neutralize_shield > 0 then 
				damage = 0 

				if targetUnit:getTraits().neutralize_shield >= 5 then 
					self:triggerEvent("started_shield")
				end

				targetUnit:getTraits().neutralize_shield = targetUnit:getTraits().neutralize_shield - 1 

				if targetUnit:getTraits().neutralize_shield <= 0 then 
					self:triggerEvent("broke_shield")
				end

				self:dispatchEvent( simdefs.EV_UNIT_HIT_SHIELD, {unit = targetUnit, sourceUnit = sourceUnit, shield = targetUnit:getTraits().neutralize_shield} )	
			end
		end 

		if (targetUnit:getTraits().shields or 0) > 0 then
			self:dispatchEvent( simdefs.EV_UNIT_HIT_SHIELD, {unit = targetUnit, sourceUnit = sourceUnit, shield = targetUnit:getTraits().shields} )			
		end

		if damage > 0 or (kodamage and kodamage > 0) then
    		self:dispatchEvent( simdefs.EV_UNIT_HIT, {unit = targetUnit, sourceUnit = sourceUnit, result = damage, kodamage = kodamage, fx = fx, pinned = simquery.isUnitPinned(self, targetUnit) })

			if (kodamage and kodamage > 0) then
				local koTime = math.max( targetUnit:getTraits().koTimer or 0, kodamage )
				targetUnit:setKO( self, koTime )
			end

            targetUnit:onDamage( damage, self)

			if targetUnit:isDead() and sourceUnit and sourceUnit:countAugments( "augment_sadochistic_pumps" ) > 0 then
				local x1, y1 = sourceUnit:getLocation()
				self:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt= STRINGS.ITEMS.AUGMENTS.SADOCHISTIC_PUMPS,x=x1,y=y1,color={r=1,g=1,b=41/255,a=1}} ) 
				sourceUnit:getTraits().mp = sourceUnit:getTraits().mp + 6
			end
		end
	end
end

function simengine:hitUnit( sourceUnit, targetUnit, dmgt )
	local kodamage = 0
	local fx = nil

	local x1,y1 = targetUnit:getLocation()

	if targetUnit:getTraits().improved_heart_monitor then
		self:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt= STRINGS.UI.FLY_TXT.IMPROVED_HEART_MONITOR,x=x1,y=y1,color={r=1,g=1,b=41/255,a=1}} ) 
	elseif sourceUnit and sourceUnit:countAugments("augment_anatomy_analysis") > 0 and sourceUnit:getPlayerOwner():getCpus() > 3 then 
		if targetUnit:getTraits().heartMonitor and ( not dmgt.ko or self:getParams().difficultyOptions.alarmRaisedOnKO ) and not dmgt.noTargetAlert and targetUnit:getTraits().heartMonitor ~= "disabled" then  			
			targetUnit:getTraits().heartMonitor = "disabled"			
			local x1, y1 = sourceUnit:getLocation()
			sourceUnit:getPlayerOwner():addCPUs(-3, self, x1, y1)
		end 
	end
	
	dmgt.damage = math.max(dmgt.damage,0)

	-- SET UP HEAVY GUARD POWER CELL EFFECTS
	if dmgt.dir == "rear" and targetUnit:isValid() and targetUnit:getTraits().backPowerPack then
		targetUnit:getTraits().backPowerPack = "hit"		
		kodamage = targetUnit:getTraits().backPowerPackoverloadKO
		fx = "emp"
	end

	if targetUnit:getTraits().movingBody then
		local body = targetUnit:getTraits().movingBody
		targetUnit:getTraits().movingBody = nil
		self:dispatchEvent( simdefs.EV_UNIT_BODYDROPPED, {unit = body} )
	end
	if sourceUnit and sourceUnit:getLocation() then
		local x0,y0 = sourceUnit:getLocation()
		targetUnit:getTraits().lastHit = { x=x0, y=y0, unit=sourceUnit, player=targetUnit:getPlayerOwner() }
		sourceUnit:getTraits().lastAttack = { x=x1, y=y1, unit=targetUnit, player=targetUnit:getPlayerOwner(), witnesses={} }
	end
	--Put to sleep if it's a sleep dart or shock
	if dmgt.ko and simquery.isAgent( targetUnit ) then 		
			
		if targetUnit:getTraits().canKO or dmgt.beatKO then
			if sourceUnit then
				self:emitSpeech( sourceUnit, speechdefs.EVENT_HIT_GUN_KO )
			end

			kodamage = math.max(kodamage,dmgt.damage)

			self:damageUnit( targetUnit, 0, kodamage, fx, sourceUnit )
			
		else 
			self:dispatchEvent( simdefs.EV_UNIT_HIT, {unit = targetUnit, result = dmgt.damage } )
		end
	else
		if sourceUnit then
			self:emitSpeech( sourceUnit, speechdefs.EVENT_HIT_GUN )
		end

		if dmgt.damage > 0 then
			self:damageUnit( targetUnit, dmgt.damage, kodamage, fx, sourceUnit )
		end 
	end

	self:triggerEvent(simdefs.TRG_UNIT_HIT, {targetUnit=targetUnit, sourceUnit=sourceUnit, x=x1, y=y1, noTargetAlert = dmgt.noTargetAlert })

end


function simengine:getAlarmTypes( )
	
	local alarmList = self._params.difficultyOptions.alarmTypes
	if self._params.missionEvents and self._params.missionEvents.advancedAlarm then
		if self._params.difficultyOptions.alarmTypes == "EASY" then
			alarmList = "ADVANCED_EASY"
		elseif self._params.difficultyOptions.alarmTypes == "NORMAL" then
			alarmList = "ADVANCED_NORMAL"
		end
    end
    return alarmList
end

function simengine:trackerDecrement( delta )
	self._tracker = math.max( 0, ( self._tracker - delta ) ) 
end

function simengine:setClimax( state )
	self._isClimax = state
end

function simengine:getClimax( state )
	return self._isClimax
end

function simengine:startDaemonQueue()
	self._daemonQueue = {}
end

function simengine:processDaemonQueue()
	local queue =  self._daemonQueue
	self._daemonQueue = nil
	if queue then
		for i, unitID in ipairs( queue ) do
			local unit = self:getUnit(unitID)
			if unit then
	 			self:moveDaemon(unit)
	 		end
	 	end
	end
end

function simengine:AOEbuffFirewalls(x,y,range,buff)

        local cells = simquery.rasterCircle( self, x, y, range )
        local targetUnits = {}
        for i, xc, yc in util.xypairs( cells ) do
            local cell = self:getCell( xc, yc )
            if cell then
                for _, cellUnit in ipairs(cell.units) do
                	if cellUnit and cellUnit:getTraits().mainframe_ice and ( not cellUnit:getPlayerOwner() or not cellUnit:getPlayerOwner():isPC()) then
                        if self:getCurrentPlayer():getLastKnownCell( self, xc, yc ) == nil then
 							--glipse 
                        end
                       
                        table.insert( targetUnits, cellUnit )
                    end
                end
            end
        end
        
        local fx = {
        	kanim = "gui/hud_fx",
        	symbol = "wireless_console_takeover",
        	anum = "idle",
    	}
		self:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = x, y = y, units = targetUnits, range = range, fx=fx, mainframe=true } )		

		for _, unit in ipairs(targetUnits) do
			unit:getTraits().mainframe_ice = unit:getTraits().mainframe_ice+buff
		end
end

function simengine:moveDaemon(unit)
	if self._daemonQueue then
		table.insert(self._daemonQueue, unit:getID() )
	else
	    -- Am I already hosted by something?
	    local currentDevice = self:getUnit( unit:getTraits().mainframe_device )
	    if unit:getTraits().mainframe_device then
	        mainframe.revokeDaemonHost( self, unit )
	    end

		local closestItem, closestDist
		for i,u in pairs(self:getAllUnits()) do
			if u:getTraits().mainframe_item
			 and u:getTraits().mainframe_ice
			 and u:getLocation()
			 and unit:getLocation()
			 and not u:getPlayerOwner()
			 and not u:getTraits().mainframe_program
			 and u:getTraits().mainframe_status ~= "off" and
	         u ~= currentDevice then
				local x0,y0 = u:getLocation()
				local x1,y1 = unit:getLocation()
				local dist = mathutil.dist2d( x0, y0, x1, y1 )
				if not closestDist or dist < closestDist then
					closestDist = dist
					closestItem = u
				end
			end
		end

		if closestItem then		
			local program = nil

			local daemon = nil
			local npc_abilities = include( "sim/abilities/npc_abilities" )
			local daemons = {}
			for k, v in pairs(npc_abilities) do
				if v.standardDaemon then
					table.insert(daemons, k)
				end
			end
			program = daemons[self:nextRand(1,#daemons)]

		
		    self:getPC():glimpseUnit( self, closestItem:getID() )

		    self:dispatchEvent( simdefs.EV_MAINFRAME_MOVE_DAEMON, { part="pre", source = unit, target = closestItem} )
		    self:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = closestItem, ice = closestItem:getTraits().mainframe_ice, delta = 0} )
				
		    closestItem:getTraits().mainframe_program = program
		    closestItem:getTraits().daemonHost = unit:getID()
		    closestItem:getTraits().daemon_sniffed = false
		    self:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_daemonmove")
		    self:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = closestItem, ice = closestItem:getTraits().mainframe_ice, delta = 0, refreshAll = true} )		    

			unit:getTraits().mainframe_device = closestItem:getID()
			
		end
	end
end

function simengine:startTrackerQueue(state)			
	if state then
		self._trackerQueue = {}
	else
		local tempList =  self._trackerQueue
		self._trackerQueue = nil
		if tempList then
			for i, tracker in ipairs( tempList ) do
		 		self:trackerAdvance( tracker.delta, tracker.txt, tracker.scan )
		 	end
		end
		
	end
end

function simengine:trackerAdvance( delta, txt, scan )
	if self._trackerQueue then
		table.insert(self._trackerQueue,{delta=delta, txt=txt, scan=scan})
	else
	    assert( delta > 0 )
	    delta = delta * self._params.difficultyOptions.alarmMultiplier
	    if delta > 0 then
	        local oldTracker = self._tracker

	        for i = 1, delta do
	            self._tracker = self._tracker + 1

 				self:triggerEvent( simdefs.TRG_ALARM_INCREASE )

	            local stage = self:getTrackerStage()
	            if stage > self._trackerStage then
	                self._trackerStage = stage
	    			self:dispatchEvent( simdefs.EV_ADVANCE_TRACKER, {txt=txt, delta = self._tracker - oldTracker, tracker = oldTracker })
	         	    self:triggerEvent( simdefs.TRG_ALARM_STATE_CHANGE, self._trackerStage )
	                oldTracker = self._tracker

	                --HANDLE PROTOCOL 78
	                if self:getTags().protocol78 then
	                	for _, unitRaw in pairs(self:getAllUnits() ) do
	                		if unitRaw:getTraits().safeUnit and unitRaw:getTraits().credits and unitRaw:getTraits().credits > 0 then
	                			unitRaw:getTraits().credits =  unitRaw:getTraits().credits +25
	                			local player = self:getPC()
	                			local x0,y0 = unitRaw:getLocation()
	                			if player:hasSeen(unitRaw) then									             											
									self:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = self:getTags().protocol78, x = x0, y = y0, color={r=163/255,g=243/255,b=248/255,a=1},skipQue=true} )									
	                			end
	                		end
	                	end
	                end

					local pc = self:getPC()
					for i, unit in pairs( pc:getAgents() ) do
						-- HANDLE THE REACTIVE MYOMER
						for c,child in ipairs(unit:getChildren())do
							if child:getTraits().alarmMPmod then
								self:dispatchEvent( simdefs.EV_GAIN_AP, { unit = unit  } )
					        	local x2,y2 = unit:getLocation()

							    self:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = child:getTraits().alarmMPmodTxt, x = x2, y = y2, color=cdefs.AUGMENT_TXT_COLOR} )
							    self:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )						
								unit:getTraits().mpMax = unit:getTraits().mpMax + child:getTraits().alarmMPmod
								unit:getTraits().mp = unit:getTraits().mp + child:getTraits().alarmMPmod
							end
						end			
					end

	            end
	        end

	        if self._tracker > oldTracker then
	            self:dispatchEvent( simdefs.EV_ADVANCE_TRACKER, {txt=txt, delta = self._tracker - oldTracker, tracker = oldTracker })
	        end
		end

		self._resultTable.max_alarm_level = self._resultTable.max_alarm_level and math.max(self._resultTable.max_alarm_level, self._tracker) or self._tracker
	    self:getStats():maxStat( "max_tracker", self._tracker )
	end
end

function simengine:getTracker()
	return self._tracker
end

function simengine:getTrackerStage( tracker )
    if not tracker then
        tracker = self:getTracker()
    end
    -- Note that self._tracker increases without cap; this is so alarm stages past TRACKER_MAXCOUNT continue to execute.
    -- The UI caps the tracker for display purposes only.  There is therefore no limit on the stage this function returns.
    return math.floor( tracker / simdefs.TRACKER_INCREMENT )
end

function simengine:getCleaningKills()
	return self._cleaningKills
end

function simengine:addCleaningKills(delta)
	self._cleaningKills = self._cleaningKills + delta 
end

function simengine:getEnforcersToSpawn()
	return self._enforcersToSpawn
end

function simengine:addEnforcersToSpawn(delta)
	self._enforcersToSpawn = self._enforcersToSpawn + delta 
end

function simengine:addObjective( txt, id, max )
	if max then 
		table.insert( self._objectives, { objType = "timed", id = id, txt = txt, current = 0, max = max } )
	else
		table.insert( self._objectives, { objType = "line", id = id or "all", txt = txt } )
	end
	self:dispatchEvent( simdefs.EV_REFRESH_OBJECTIVES, self._objectives )
end

function simengine:hasObjective( id )
	for _,objective in ipairs( self:getObjectives() ) do 
		if objective.id == id then 
			return objective
		end 
	end

	return false
end

function simengine:incrementTimedObjective( id )
	for _,objective in ipairs( self:getObjectives() ) do 
		if objective.id == id then 
			objective.current = objective.current + 1 
		end
	end
	self:dispatchEvent( simdefs.EV_REFRESH_OBJECTIVES, self._objectives )
end

function simengine:removeObjective( id )
    for i = #self._objectives, 1, -1 do
	    local objective = self._objectives[i]
		if objective.id == id then 
			table.remove( self._objectives, i )
		end
	end
	self:dispatchEvent( simdefs.EV_REFRESH_OBJECTIVES, self._objectives )
end

function simengine:clearObjectives()
	self._objectives = {}
end

function simengine:getObjectives()
	return self._objectives
end

function simengine:setMissionReward(missionReward)
	self._missionReward = missionReward
end

function simengine:addMissionReward(missionRewardDelta)
	if self._missionReward then
		self._missionReward = self._missionReward + missionRewardDelta
	else
		self._missionReward = missionRewardDelta
	end
end


function simengine:getMissionReward()
	return self._missionReward
end

function simengine:getEnforcerWavesSpawned()
	return self._enforcerWavesSpawned
end

function simengine:addEnforcerWavesSpawned(delta)
	self._enforcerWavesSpawned = self._enforcerWavesSpawned + delta 
end

function simengine:resetEnforcersToSpawn()
	self._enforcersToSpawn = 0 
end

function simengine:closeElevator( )
	self:forEachCell(
			function( c )
				for i, exit in pairs( c.exits ) do
					if exit.door and not exit.closed and (exit.keybits == simdefs.DOOR_KEYS.ELEVATOR or exit.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE)  then
						
						local reverseExit = exit.cell.exits[ simquery.getReverseDirection( i ) ]
						exit.keybits = simdefs.DOOR_KEYS.ELEVATOR_INUSE						
						reverseExit.keybits = simdefs.DOOR_KEYS.ELEVATOR_INUSE
						
						self._elevator_inuse = 2
						self:modifyExit( c, i, simdefs.EXITOP_CLOSE )
						self:modifyExit( c, i, simdefs.EXITOP_LOCK )
						self:dispatchEvent( simdefs.EV_EXIT_MODIFIED, {cell=c, dir=i} )
					elseif exit.door and not exit.closed and exit.keybits == simdefs.DOOR_KEYS.FINAL_LEVEL then 
						self:modifyExit( c, i, simdefs.EXITOP_CLOSE )
						self:modifyExit( c, i, simdefs.EXITOP_LOCK )
						self:dispatchEvent( simdefs.EV_EXIT_MODIFIED, {cell=c, dir=i} )
					end
				end
			end )	
end

function simengine:openElevator( )
	self:forEachCell(
			function( c )
				for i, exit in pairs( c.exits ) do
					if exit.door and exit.locked and (exit.keybits == simdefs.DOOR_KEYS.ELEVATOR or exit.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE)  then						
						
						local reverseExit = exit.cell.exits[ simquery.getReverseDirection( i ) ]
						exit.keybits = simdefs.DOOR_KEYS.ELEVATOR
						reverseExit.keybits = simdefs.DOOR_KEYS.ELEVATOR

						self:modifyExit( c, i, simdefs.EXITOP_UNLOCK )
						self:modifyExit( c, i, simdefs.EXITOP_OPEN )
						self:dispatchEvent( simdefs.EV_EXIT_MODIFIED, {cell=c, dir=i} )

					elseif exit.door and exit.locked and exit.keybits == simdefs.DOOR_KEYS.FINAL_LEVEL then 
						self:modifyExit( c, i, simdefs.EXITOP_UNLOCK )
						self:modifyExit( c, i, simdefs.EXITOP_OPEN )
						self:dispatchEvent( simdefs.EV_EXIT_MODIFIED, {cell=c, dir=i} )
					end
				end
			end )
end


function simengine:unlockAllSecurityDoors()
	self:forEachCell(
		function( c )
			for i,exit in pairs(c.exits) do
				if exit.locked and exit.keybits == simdefs.DOOR_KEYS.SECURITY then
					self:modifyExit( c, i, simdefs.EXITOP_UNLOCK)
                    self:getPC():glimpseExit( c.x, c.y, i )
				end
			end
		end )
end

function simengine:addTrigger( evType, obj, ... )
	
	if not self._triggers[ evType ] then
		self._triggers[ evType ] = {}
	end

	local trigger = {...}
	trigger._obj = obj

	assert( obj.onTrigger )
	assert( array.findIf( self._triggers[ evType ], function( t ) return t._obj == obj end ) == nil )

	table.insert(self._triggers[ evType ], trigger)
    return trigger
end

function simengine:removeTrigger( evType, obj )
    assert( obj )

	for i,trigger in ipairs(self._triggers[ evType ]) do
		if trigger._obj == obj then
			table.remove( self._triggers[ evType ], i )
			break
		end
	end

	for depth = 1, self._triggerDepth do
		for i, trigger in ipairs( self._processTriggers[ depth ] ) do
			if trigger._obj == obj then
				table.remove( self._processTriggers[ depth ], i )
				break
			end
		end
	end
end

function simengine:triggerEvent( evType, evData )
	assert( evType )

	if self._triggers[ evType ] then
		self._triggerDepth = self._triggerDepth + 1
		-- Add all the triggers to a temporary list.  It's done this way to be resilient to removals during iteration.
		if self._processTriggers[ self._triggerDepth ] == nil then
			self._processTriggers[ self._triggerDepth ] = {}
		end
		local processList = util.tmerge( self._processTriggers[ self._triggerDepth ], self._triggers[ evType ] )
        table.sort( processList, function( t1, t2 ) return (t1.priority or 0) < (t2.priority or 0) end )
		-- Keep triggering until we've triggered everything. 
		while next( processList ) do
			local trigger = table.remove( processList )
			trigger._obj:onTrigger( self, evType, evData, unpack(trigger) )
		end
		self._triggerDepth = self._triggerDepth - 1
	end

    return evData -- Only returning triggerData table for convenience.
end

function simengine:getIcePrograms()
	return self._icePrograms
end

function simengine:dispatchEvent( evType, evData, noSkip )
	assert( evType )

	if evType == simdefs.EV_UNIT_SHOT then
		self:getStats():incStat( "shots_fired" )

	elseif evType == simdefs.EV_UNIT_DEATH then

		local playerOwner = evData.unit:getPlayerOwner()
		if playerOwner == nil then
			self:getStats():incStat( "neutral_deaths" )
		elseif playerOwner:isNPC() then
			self:getStats():incStat( "npc_deaths" )
		else
			self:getStats():incStat( "pc_deaths" )
		end

	end

	return self._events:queueEvent( evType, evData, noSkip )
end

function simengine:dispatchChoiceEvent( evType, evData )
    self._choiceCount = self._choiceCount + 1
	local choice = self._choices[ self._choiceCount ]

	if not choice then
		-- Choice has not yet been made.
        self:dispatchEvent( evType, evData )

        if self._choices[ self._choiceCount ] == nil then
            -- Choice was skipped: fill with ABORT result.
            self._choices[ self._choiceCount ] = simdefs.CHOICE_ABORT
        end
		choice = self._choices[ self._choiceCount ]
	end

	return choice
end

function simengine:nextID()
    assert( simguard.isGuarded() )
	self._nextID = self._nextID + 1
	return self._nextID
end

function simengine:nextRand( a, b )

	assert( simguard.isGuarded() )

	local gen = rand.createGenerator( self._seed )
    local n
	if a and b then
        n = gen:nextInt( a, b )
	elseif a then
        n = gen:nextInt( 1, a )
	else
        n = gen:next()
	end

    self._seed = gen._seed
	return n
end

function simengine:getActionCount()
	return self._actionCount
end

function simengine:getTurnState()
	return self._turnState
end

function simengine:closeGuardDoors()
	local guardCells = self:getCells( "guard_spawn" )
    if guardCells then
	    for i, cell in ipairs(guardCells) do
		    for dir, exit in pairs( cell.exits ) do
			    if exit.door and not exit.closed and not simquery.checkDynamicImpass(self, cell) then
				    self:modifyExit(cell, dir, simdefs.EXITOP_CLOSE)
			    end
		    end
	    end 
    end
end

function simengine:endTurn()
	self._turnState = simdefs.TURN_ENDING

	self:dispatchEvent( simdefs.EV_TURN_END, self:getCurrentPlayer() )

	self:getTags().nextProgFree = nil

	-- Let players units do 'end turn' stuff.
	for i,player in ipairs(self._players) do
		player:onEndTurn( self )
	end

	-- unit:onEndTurn may modify self._units, so we want to ensure we iterate robustly.
	local units = util.tdupe( self._units )
	for unitID, unit in pairs( units ) do
        if unit:isValid() then
		    unit:onEndTurn( self )		   
        end
	end
    
    self:triggerEvent( simdefs.TRG_TIMER )

	self:triggerEvent( simdefs.TRG_END_TURN, self:getCurrentPlayer() )

	local prevTurn = self._turn
	self._turn = (self._turn % #self._players) + 1
	self._turnCount = self._turnCount + 1

	--Lock and close doors that are marked to be locked and closed. 
	self:forEachCell(
		function( c )
			for i, exit in pairs( c.exits ) do
				if exit.door then
                    if exit.closeEndTurn and not exit.closed then
    					self:modifyExit( c, i, simdefs.EXITOP_CLOSE )
                    end
                    if exit.lockEndTurn and not exit.locked then
    					self:modifyExit( c, i, simdefs.EXITOP_LOCK )
                    end
				end
			end
		end )
	self:closeGuardDoors()


	self._turnState = simdefs.TURN_STARTING
	if self:getCurrentPlayer() then
		self:dispatchEvent( simdefs.EV_TURN_START, {player = self:getCurrentPlayer() })
		self:getCurrentPlayer():onStartTurn( self )
		self:triggerEvent( simdefs.TRG_START_TURN, self:getCurrentPlayer() )
	end
	self._turnState = simdefs.TURN_PLAYING
end

function simengine:drawInterestPoints()
	return self:getParams().drawInterestPoints == true
end

function simengine:applyAction( action )
	local choiceCount = self._choiceCount

	--simlog( "APPLY: (%u) %s", self._seed, util.stringize(action) )

	-- Apply all the choices that are stored in this action.
	if action.choices then
		for i, choice in pairs( action.choices ) do
			assert( self._choices[ i ] == nil )
			self._choices[ i ] = choice
		end
	end

	-- Update the sim with the number of retries (for tutorial branching)
	self:getTags().retries = math.max( self:getTags().retries or 0, action.retries or 0 )
	self:getTags().rewindError = self:getTags().rewindError or action.rewindError
	self._actionCount = self._actionCount + 1

	local skipAction = self:triggerEvent( simdefs.TRG_ACTION, { pre = true, ClassType = action.name, unpack(action) } ).abort

    if not skipAction then
	    -- Be sure to copy the action before unpacking, as the action data should be immutable.
	    simactions[ action.name ]( self, unpack( util.tcopy(action) ) )

    	self:triggerEvent( simdefs.TRG_ACTION, { ClassType = action.name, unpack(action) } )
    end

	-- Update win conditions after every action	
	self:updateWinners()

    if self:getCurrentPlayer() and self:getCurrentPlayer():isNPC() then
        self:getCurrentPlayer():thinkHard( self )
   	    -- And again after AI moves.
	    self:updateWinners()
    end

	-- Store all the choices that were made.
    -- THIS MUST BE LAST.
	for i = choiceCount + 1, self._choiceCount do
		if action.choices == nil then
			action.choices = {}
		end
		action.choices[ i ] = self._choices[ i ]
	end
end

function simengine:canUnitSee( unit, x, y )
	if not unit:getLocation() then
		return false, false
	end

	if not simquery.couldUnitSee( self, unit, nil ) then
		return false, false
	end

	return self._los:hasSight( unit, x, y ), self._los:hasPeripheral( unit, x, y )
end

function simengine:canUnitSeeUnit( unit, targetUnit )
    if array.find( unit:getSeenUnits(), targetUnit ) then
        return true, false
    else
        -- Need to do a full calculation, to determine whether target is in peripheral sight. :(
	    if not unit:getLocation() or not targetUnit:getLocation() then
		    return false, false
	    end

	    if unit == targetUnit then
		    return true, false -- Can always see yourself
	    end

        local x0, y0 = unit:getLocation()
        -- First check couldUnitSee, without cover...
	    if not simquery.couldUnitSee( self, unit, targetUnit, true ) then
		    return false, false
	    end
        -- Then use the peripheral cell (since it may be different from unit's actual location)
        -- to properly query cover.
        if not unit:getTraits().seesHidden and simquery.checkIfNextToCover(targetUnit:getSim(), targetUnit) and simquery.checkCellCover( self, x0, y0, targetUnit:getLocation() ) then
		    return false, false
		end

	    local x, y = targetUnit:getLocation()
	    if not x then
		    return false, false
	    end

        return false, self._los:hasPeripheral( unit, x, y )
    end
end

function simengine:canPlayerSee( player, x, y )
	for i, playerUnit in ipairs( player:getUnits() ) do
		if self:canUnitSee( playerUnit, x, y ) then
			return true
		end
	end
	return false
end

function simengine:canPlayerSeeUnit( player, unit )
    return array.find( player:getSeenUnits(), unit ) ~= nil
end

function simengine:generateSeers( unit )
	local seers = { oldcell = self:getCell( unit:getLocation() ) }

	if unit:getLocation() then
		for i, player in ipairs(self._players) do
            if array.find( player:getSeenUnits(), unit ) then
				table.insert( seers, player:getID() )
			end
		end

		local seerUnits = self._los:getSeers( unit:getLocation() )
		for _, unitID in ipairs(seerUnits) do
			local seerUnit = self:getUnit( unitID )
			if seerUnit and seerUnit ~= unit and array.find( seerUnit:getSeenUnits(), unit ) then
				table.insert( seers, unitID )
			end
		end
	end
    
    self._preSeers[ unit ] = seers
	return seers
end

-- Make correct notifications to seers for a unit that has changed visibility status.
function simengine:notifySeers()
    for unit, preSeers in pairs(self._preSeers) do
    	local postSeers, newcell = {}, nil
	    if unit:getLocation() then
            newcell = self:getCell( unit:getLocation() )

		    for i, player in ipairs(self._players) do
			    if calculatePlayerSeeUnit( self, player, unit ) then
				    table.insert( postSeers, player:getID() )
			    end
		    end

		    local seerUnits = self._los:getSeers( unit:getLocation() )
		    for _, unitID in ipairs(seerUnits) do
			    local seerUnit = self:getUnit( unitID )
			    if seerUnit and seerUnit ~= unit and calculateUnitSeeUnit( self, seerUnit, unit ) then
				    table.insert( postSeers, unitID )
			    end
		    end
	    end

        -- Now compare the newly calculated list to the previous one that was passed in.
        -- Notify of any changes.
	    util.tdiff( preSeers, postSeers,
		    function( preSeer )
			    local player = self:getPlayerByID( preSeer )
			    if player then
				    player:removeSeenUnit( unit, preSeers.oldcell, newcell )
			    elseif self:getUnit( preSeer ) then
				    self:getUnit( preSeer ):removeSeenUnit( unit, preSeers.oldcell, newcell )
			    end
		    end,
		    function( postSeer )
			    local player = self:getPlayerByID( postSeer )
			    if player then
				    player:addSeenUnit( unit )
			    elseif self:getUnit( postSeer ) then
				    self:getUnit( postSeer ):addSeenUnit( unit )
			    end
		    end )
        self._preSeers[ unit ] = nil
    end
end

function simengine:emitSpeech( unit, speechIndex )
	if not unit:isDead() and unit:getSpeech() then
		local speechData = unit:getSpeech()[ speechIndex ]
		if speechData ~= nil then
			local p = speechData[1]
			if self:nextRand() <= p then
				-- Speech might or might not "make sound"
				if speechData.sound then
					local x0, y0 = unit:getLocation()
					self:emitSound( speechData.sound, x0, y0, unit )

					-- GLIMPSE UNIT IF HEARD
					local player =  self:getPC()
					local heard = false
					for i,unitListen in ipairs(player:getUnits()) do
						local x1,y1 = unitListen:getLocation()
						if x1 and y1 then
							local distance = mathutil.dist2d( x0, y0, x1, y1 )
							if distance <= simdefs.SOUND_RANGE_2 and simquery.canHear(unitListen) then
								heard = true
								break
							end
						end
					end
					if heard == true then
						player:glimpseUnit(self, unit:getID())
					end
					-- END GLIMPSE TEST

				end

				self:dispatchEvent( simdefs.EV_UNIT_SPEAK, { unit = unit, speech=speechData.speech, speechData = speechData[2], range = simdefs.SOUND_RANGE_2 } )
			end
		end
	end
end

function simengine:emitSound( sound, x0, y0, unit, altVisTiles )
	self:dispatchEvent( simdefs.EV_SOUND_EMITTED, { x = x0, y = y0, sound = sound, altVisTiles=altVisTiles} )

	if sound.range > 0 and not sound.innocuous then
		self:triggerEvent( simdefs.TRG_SOUND_EMITTED, { x = x0, y = y0, range = sound.range, sourceUnit = unit, ignoreSight=sound.ignoreSight}  )
	end
end

function simengine:showHUD( isVisible, ... )
	if self.vizTags == nil then
		self.vizTags = {}
	end

	for i, name in ipairs({...}) do
		self.vizTags[ name ] = isVisible
	end

	self:dispatchEvent( simdefs.EV_HUD_REFRESH )
end

function simengine:forEachCell( fn )

	local w, h = self:getBoardSize()

	for x = 1,w do
		for y = 1,h do
			local cell = self:getCell( x, y )			
			if cell then
				fn( cell )
			end
		end
	end
end

function simengine:forEachUnit( fn )
	for unitID,unit in pairs( self._units ) do
		fn( unit )
	end
end

function simengine:getTurn()
	return self._turn
end

function simengine:getTurnCount()
	return self._turnCount
end

function simengine:getBoardSize()
	return self._board.width, self._board.height
end

function simengine:getCell( x, y )
	if y and self._board[y] then
		return self._board[y][x]
	end
end

function simengine:getCellByID( id )
	local x, y = simquery.fromCellID( id )
	return self:getCell( x, y )
end

function simengine:getCells( tag )
	return self._board.cell_groups[ tag ]
end

function simengine:getUnit( unitID )
	return self._units[ unitID ]
end

function simengine:getAllUnits()
	return self._units
end

function simengine:getPlayers()
	return self._players
end

function simengine:getPlayerByID( ID )
	local player = nil

	for i,testPlayer in ipairs(self._players) do 
		if ID == testPlayer:getID() then
			player = testPlayer
			return player
		end
	end

	return player
end

function simengine:getCurrentPlayer()
	if self._turn then
		return self._players[ self._turn ]
	else
		return nil
	end
end

function simengine:getNPC()
	for i, player in ipairs( self._players ) do
		if player:isNPC() then
			return player
		end
	end
end

function simengine:getPC()
	for i, player in ipairs( self._players ) do
		if not player:isNPC() then
			return player
		end
	end
end

function simengine:getWinner()
	return self._winner
end

function simengine:isGameOver()
	return self:getCurrentPlayer() == nil
end

function simengine:isResigned()
    return array.find( self._winConditions, win_conditions.pcResigned ) ~= nil
end

function simengine:isAlarmed()
	return self._tracker >= simdefs.TRACKER_MAXCOUNT
end

function simengine:getAbilities()
	return abilitydefs
end

function simengine:getMainframe()
	return mainframe
end

function simengine:getEvents()
	return self._events
end

function simengine:getQuery()
	return simquery
end

function simengine:getDefs()
	return simdefs
end

function simengine:getSpeechDefs()
	return speechdefs
end

function simengine:getInventory()
	return inventory
end

function simengine:getLOS()
	return self._los
end

function simengine:getLevelScript()
	return self._levelScript
end

function simengine:getNewLocations()
	return self._newLocations
end

function simengine:addNewLocation( mission_tags, mission_difficulty )
    -- Tag and difficulty are optional
    table.insert( self._newLocations, { mission_tags = mission_tags, mission_difficulty = mission_difficulty } )
end

return simengine

