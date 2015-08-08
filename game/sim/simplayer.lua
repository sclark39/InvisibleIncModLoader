----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simunit = include( "sim/simunit" )
local simfactory = include( "sim/simfactory" )
local simability = include( "sim/simability" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local serverdefs = include( "modules/serverdefs" )
local unitdefs = include( "sim/unitdefs" )
local unitghost = include( "sim/unitghost" )
local inventory = include( "sim/inventory" )
local mathutil = include( "modules/mathutil" )

-----------------------------------------------------
-- Prototype table

local simplayer = class()

function simplayer:init( sim )
	self._sim = sim
	self._id = sim:nextID()

	-- Units deployed onto the battlefield.
	self._units = {}
	-- IDs of units that can be deployed by this player
	self._deployed = {}
    -- Player traits
    self._traits = {}

	self._escapedWithDisk = false 

	self._equippedProgram = nil 

	self._isPlayer = true

	self._credits = 0
	self._cpus = 0
	self._maxCpus = 20 
	self._mainframeAbilities = {}
	self._lockedMainframeAbilities = {}
		
	-- Ghost data, encapsulating information about the last-seen state of cells
	self._ghost_cells = {}
	self._ghost_units = {}
	-- Footsteps tracked
	self._footsteps = {}
    -- List of seen units
    self._seenUnits = {}
end

-----------------------------------------------------
-- Local functions

local function getCellGhost( player, cellx, celly )
	assert( player._ghost_cells, util.stringize( player, 1 ))
	return player._ghost_cells[ simquery.toCellID( cellx, celly ) ]
end

local function addUnitGhost( ghost_units, ghost_cell, unit )
	local ghost_unit = ghost_units[ unit:getID() ]
	if ghost_unit ~= nil then
		return false -- Never update ghost info if it's already ghosted.
	end
    if unit:getTraits().noghost then
        return false
    end

	ghost_unit = unitghost.createUnitGhost( unit )

	table.insert( ghost_cell.units, ghost_unit )
	ghost_units[ unit:getID() ] = ghost_unit

	return true
end

local function removeUnitGhost( player, cellghost, sim, unitID )
	local ghost_units = player._ghost_units
	local ghost = ghost_units[ unitID ]

	if ghost then
		if cellghost == nil then
			cellghost = getCellGhost( player, ghost:getLocation() )
		end

		assert( array.find( cellghost.units, ghost ))  -- If a unit ghost it exists, it must exist in a ghosted cell.

		array.removeElement( cellghost.units, ghost )
		local unit = player._sim:getUnit(unitID)
		ghost_units[ unitID ] = nil

	-- Handle the unghosting (whether or not a ghost actually existed).
	-- A unit is unghosted because (1) it was seen (2) its ghost was seen, in either case,
	-- its viz state must be updated.  Unghosting a unit is NOT equivalent to that unit becoming seen,
	-- but note that a unit becoming seen DOES always result in unghosting.

		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = ghost } )	
	end

end


local function addCellGhost( self, sim, cell )
	local ghost_units, ghost_cells = self._ghost_units, self._ghost_cells
	if ghost_cells[ cell.id ] ~= nil then
		return 		-- Never update ghost info if it's already ghosted.
	end

    self._nextGhostID = (self._nextGhostID or 0) + 1
	local cellghost = {}
	cellghost.id = cell.id
	cellghost.x = cell.x
	cellghost.y = cell.y
	cellghost.impass = cell.impass
	cellghost.exits = {}
	cellghost.units = {}	
	cellghost.exitID = cell.exitID
	-- keep track of relative ages of ghosts, given that nextID() is monotonically increasing.
 	cellghost.ghostID = self._nextGhostID

	for dir,exit in pairs(cell.exits) do
		-- Only ghost doors.  Other stuff doesn't change, so reference the raw exit.  Reduces table junk.
		if exit.door then
			cellghost.exits[ dir ] = util.tmerge( {}, exit )
		else
			cellghost.exits[ dir ] = exit
		end
	end

	ghost_cells[ cell.id ] = cellghost
    return cellghost
end

local function removeCellGhost( player, sim, cellx, celly )
	local ghost_units, ghost_cells = player._ghost_units, player._ghost_cells
	local cellid = sim:getCell( cellx, celly ).id
	local ghost_cell = ghost_cells[ cellid ]
	if ghost_cell then
		-- Ghost cell must be removed before unit ghosts so that canSee queries for this cell will reflect that.
		ghost_cells[ cellid ] = nil

		-- Dispel ghost information regarding exits into this location.  If for example this cell has a door,
		-- adjacent ghost cells should reflect that new knowledge.
		local cell = sim:getCell( cellx, celly )
		for dir, exit in pairs( cell.exits ) do
			if exit.door then
				local rdir = simquery.getReverseDirection( dir )
				player:glimpseExit( exit.cell.x, exit.cell.y, rdir )
			end
		end

		-- Dispel ghosts at this location.
		while #ghost_cell.units > 0 do
			removeUnitGhost( player, ghost_cell, sim, ghost_cell.units[1]:getID() )
		end

		return true
	end
end


-----------------------------------------------------
-- Interface functions

function simplayer:getID( )
	return self._id
end

function simplayer:getTraits()
    return self._traits
end

function simplayer:getAbilities()
	return self._mainframeAbilities
end

function simplayer:hasMainframeAbility( abilityID )
	if self._mainframeAbilities then
		for i,ability in ipairs(self._mainframeAbilities) do
			if ability:getID() == abilityID then
				return ability
			end
		end
	end

	return nil
end

function simplayer:lockdownMainframeAbility( num )
	local prevLocked = self._lockedMainframeAbilities
	self._lockedMainframeAbilities = {}
	local abilitiesTotal = #self:getAbilities()
	if #prevLocked > 0 then 
		for _, abilityNum in ipairs(prevLocked) do 
			table.insert( self._lockedMainframeAbilities, (abilityNum % abilitiesTotal) + 1 )
		end 
	else 
		table.insert(self._lockedMainframeAbilities, 1) 
		if num == 2 then
			table.insert(self._lockedMainframeAbilities, 3)
		end 
	end 

	for i, ability in ipairs( self:getAbilities() ) do 
		ability.color = nil
		for k, locked in ipairs( self._lockedMainframeAbilities ) do 
			if i == locked and not ability.passive then 
				ability.color = {215/255, 39/255, 39/255, 1}
			end 
		end 
	end 
end 

function simplayer:unlockAllMainframe()
	self._lockedMainframeAbilities = {}
end 

function simplayer:getLockedAbilities()
	return self._lockedMainframeAbilities
end

function simplayer:addMainframeAbility(sim, abilityID, hostUnit, reversalOdds )
	-- How many instances of this ability do we already have?
	local monst3rReverseOdds = reversalOdds or 10

	--Add daemon reversal odds (BRIMSTONE)
	if self:isNPC() then 
		for _, ability in ipairs( sim:getPC():getAbilities() ) do 
			if ability.daemonReversalAdd and monst3rReverseOdds > 0 then 
				monst3rReverseOdds = monst3rReverseOdds + ability.daemonReversalAdd
			end 
		end 
	end

	local count = 0
	for _, ability in ipairs( self._mainframeAbilities ) do
		if ability:getID() == abilityID then
			count = count + 1
		end
	end

	local ability = simability.create( abilityID )
	if ability and count < (ability.max_count or math.huge) then
		local monst3rReverse = nil 
		if sim:nextRand( 1, 100 ) < monst3rReverseOdds and self:isNPC() then 
			monst3rReverse = true 
		end		

		if monst3rReverse then 
			local newAbilityID = serverdefs.REVERSE_DAEMONS[ sim:nextRand( 1, #serverdefs.REVERSE_DAEMONS ) ] 
			ability = simability.create( newAbilityID )
			sim:triggerEvent( simdefs.TRG_DAEMON_REVERSE )
		end 
		
		table.insert( self._mainframeAbilities, ability )
		ability:spawnAbility( self._sim, self, hostUnit )

		if self:isNPC() then			
			sim:dispatchEvent( simdefs.EV_MAINFRAME_INSTALL_PROGRAM, {idx = #self._mainframeAbilities, ability=ability} )	
			sim:triggerEvent( simdefs.TRG_DAEMON_INSTALL )		
		end		
	end
end

function simplayer:getEquippedProgram()
    return self._equippedProgram
end


function simplayer:equipProgram( sim, abilityID )
    local ability = self:hasMainframeAbility( abilityID )
    if ability ~= self._equippedProgram then
        if self._equippedProgram then
            self._equippedProgram:setEquipped( false )
            self._equippedProgram = nil
        end
	
	    if ability then 
		    self._equippedProgram = ability
		    ability:setEquipped( true )
	    end
    end
end

function simplayer:removeAbility(sim, abilityID )
	-- We permit abilityID to be a string (the ability key) or the ability table itself.
	for i, ability in ipairs( self._mainframeAbilities ) do
		if ability == abilityID or ability:getID() == abilityID then
            if self._equippedProgram == ability then
                self:equipProgram( sim, nil )
            end

			ability:despawnAbility( self._sim, self )		
			if ability.ice then
				sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = ability, ice = ability.ice, delta = -ability.ice } )
			end
		
			table.remove( self._mainframeAbilities, i )
			break
		end
	end
end

function simplayer:canUseAbility( sim, ability, ... )
	return ability:canUseAbility( sim, self, ... )
end

function simplayer:getCredits( )
	return self._credits
end

function simplayer:getEscapedWithDisk() 
	if self._escapedWithDisk then 
		return true 
	else
		return false 
	end
end

function simplayer:setEscapedWithDisk(bool)
	self._escapedWithDisk = bool 
end


function simplayer:addCredits( credits ,sim,x,y)
	self._credits = math.floor( self._credits + credits )
	
	if credits > 0 then
		self._sim:getStats():sumStat( "credits_gained", credits )
	else
		self._sim:getStats():sumStat( "credits_lost", credits )
	end

	if self._credits < 0 then 
		self._credits = 0 
	end 
	self._sim:dispatchEvent( simdefs.EV_CREDITS_REFRESH )

	if x and y then
		sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt= util.sformat( STRINGS.FORMATS.CREDITS, credits ), x=x,y=y, color={r=1,g=1,b=1,a=1},target="credits"} )				
	end
end

function simplayer:resetCredits( credits )
	self._credits = 0
end

function simplayer:getCpus( )
	return self._cpus 
end

function simplayer:getEquippedProgram( )
	return self._equippedProgram
end

function simplayer:getMaxCpus( )
	return self._maxCpus + (self._traits.PWRmaxBouns or 0)
end

function simplayer:addCPUs( delta, sim,x,y )
	local old_cpus = self._cpus
	self._cpus = math.max( 0, self._cpus + delta )
	self._cpus = math.min( self:getMaxCpus( ), self._cpus )
	local actual_delta = self._cpus - old_cpus

	if delta < 0 then
		self._sim:dispatchEvent( simdefs.EV_HUD_SUBTRACT_CPU, {delta = delta} )
	end

	if actual_delta > 0 then
		self._sim._resultTable.pwr_gained = self._sim._resultTable.pwr_gained and self._sim._resultTable.pwr_gained + delta or delta 
	elseif actual_delta < 0 then
		self._sim._resultTable.pwr_used = self._sim._resultTable.pwr_used and self._sim._resultTable.pwr_used - delta or -delta 
	end

	
	if x and y then
		local sound = "SpySociety/HUD/gameplay/gain_pwr"
        local floatTxt
		if delta < 0 then
			sound = "SpySociety/HUD/gameplay/lose_pwr"
            floatTxt = util.sformat( STRINGS.FORMATS.PWR, delta )
        else
            floatTxt = util.sformat( STRINGS.FORMATS.PLUS_PWR, delta )
		end

	    sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=floatTxt, x=x,y=y, color={r=1,g=1,b=1,a=1}, sound=sound, soundDelay=1.5} )
	else
		self._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HUD/gameplay/gain_pwr" )
	end
end


function simplayer:checkForFireWallSupport( sim )
	-- Process mainframe items to see if they should be buffed by Plastech guards.
	local units = {}
	for i,unit in ipairs(self:getUnits())do
		if unit:getTraits().firewallSupport then			
			table.insert(units,unit)
		end
	end

	local mainframeItems = {}
	for i,unit in pairs(sim:getAllUnits())do
		if unit:getTraits().mainframe_item and unit:getTraits().mainframe_ice and not unit:isPC() then
			table.insert(mainframeItems,unit)
		end
	end
	for i,unit in ipairs(mainframeItems)do
		if unit:getTraits().mainframe_ice > unit:getTraits().mainframe_iceMax then			
			unit:getTraits().debuffed = true
			unit:getTraits().mainframe_ice = unit:getTraits().mainframe_iceMax
		end
	end

	for i,unit in ipairs(units)do
		local x0,y0 = unit:getLocation()
		for j,mainframeUnit in ipairs(mainframeItems) do
			local x1,y1 = mainframeUnit:getLocation()			
			local distance = mathutil.dist2d( x0, y0, x1, y1 )
			if distance <= unit:getTraits().firewallSupportRange then
				unit:getTraits().debuffed = nil
				mainframeUnit:getTraits().mainframe_ice = math.min( mainframeUnit:getTraits().mainframe_ice + 2,  mainframeUnit:getTraits().mainframe_iceMax + 2)				
				sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = mainframeUnit, ice = mainframeUnit:getTraits().mainframe_ice, delta = 2} )						
			end
		end
	end
end				

function simplayer:onEndTurn( sim )
	-- for actions only when it's the end of THIS players turn..
	if sim:getCurrentPlayer() == self then
		if self:isNPC() then	
			self:checkForFireWallSupport(sim)		
		end

		self._footsteps = {}		

		-- Dispel all ghosts.
		for unitID, ghostUnit in pairs( self._ghost_units ) do
			if simquery.isAgent( ghostUnit ) then
				removeUnitGhost( self, nil, sim, unitID )
			end
		end
	end

end

function simplayer:getCurrentAgent()
	return self.currentAgent
end

function simplayer:setCurrentAgent(agent)
	self.currentAgent = agent
end

function simplayer:onStartTurn( sim )
	local units = util.tdupe( self._units )
	for i,unit in ipairs( units ) do
		if unit:isValid() then
			unit:onStartTurn( sim )
		end
	end

	if sim:getTags().clearPWREachTurn then			
		self:addCPUs( -self:getCpus( ), sim )
	end
end

function simplayer:onUnitAdded( unit )
	assert(array.find( self._units, unit ) == nil)
	table.insert( self._units, unit )

	local vizcells = {}
	if unit:getTraits().hasSight then
		self._sim:getLOS():getVizCells( unit:getID(), vizcells )
		for i = 1, #vizcells, 2 do
			self:markSeen( self._sim, vizcells[i], vizcells[i+1] )
		end
        self:updateSeenUnits()
        self._sim:refreshUnitLOS( unit )
		self._sim:dispatchEvent( simdefs.EV_LOS_REFRESH, { player = self, cells = vizcells } )
	end
end

function simplayer:onUnitRemoved( unit )
	local idx = util.indexOf( self._units, unit )
	assert( idx )
	table.remove( self._units, idx )
	
	local vizcells = {}
	if unit:getTraits().hasSight then
		self._sim:getLOS():getVizCells( unit:getID(), vizcells )
		for i = 1, #vizcells, 2 do
			if not self._sim:canPlayerSee( self, vizcells[i], vizcells[i+1] ) then
				self:markUnseen( self._sim, vizcells[i], vizcells[i+1] )
			end
		end
        self:updateSeenUnits()
        -- ccc: shouldnt this be here?
		--self._sim:dispatchEvent( simdefs.EV_LOS_REFRESH, { player = self, newcells = vizcells } )
	end
end

function simplayer:deployUnits( sim, agentDefs )
	local deploy_cell, deploycells = nil, {}
	sim:forEachCell(
		function( deploycell )
			if deploycell.deployID and #deploycell.units == 0 then
				table.insert(deploycells,deploycell)
			end
		end )	

	-- Deploy the agents as ther last thing we do!
	for _, agentDef in ipairs( agentDefs ) do
		local i
		deploy_cell, i = array.findIf( deploycells, function( c ) return c.deployID == (agentDef.deployID or simdefs.DEFAULT_EXITID) end )
        if deploy_cell then
		    deploy_cell = table.remove(deploycells, i)
		    self:deployUnit( sim, agentDef.id, deploy_cell, deploy_cell.deployFacing )
        else
            log:write( "WARNING: couldn't deploy %s, no deploy_cells", agentDef.template )
        end
	end
end

function simplayer:deployUnit( sim, agentID, cell, facing )
	local agentDef = self._deployed[ agentID ].agentDef
	assert( agentDef )

	local unitData = unitdefs.createUnitData( agentDef )

	local unit = simfactory.createUnit( unitData, sim )
	unit:setPlayerOwner( self )

	-- Spawn and warp the unit
	sim:spawnUnit( unit )
	sim:warpUnit( unit, cell, facing )

	self._deployed[ agentDef.id ].id = unit:getID()

	return unit
end

function simplayer:getUnits( )
	return self._units
end

function simplayer:getDeployed( )
	return self._deployed
end

function simplayer:isNeutralized( sim )
	-- A player is neutralized if all of its units that have escape no longer exist or are KO'd.
	for _, unit in ipairs( self._units ) do
		if unit:hasAbility( "escape" ) and not unit:isNeutralized() then
			return false
		end
	end

	return true -- No deployed units remain.
end

-- Called whenever a cell is seen, should NOT already be visible
function simplayer:markSeen( sim, cellx, celly )
	-- Any ghosts that are here are dispelled.	
	removeCellGhost( self, sim, cellx, celly )
end

-- Called to clear visibility status of a cell (the cell may be not visible, visible, or ghosted)
function simplayer:markUnseen( sim, cellx, celly )
	addCellGhost( self, sim, sim:getCell( cellx, celly ) )
end


function simplayer:updateSeenUnits()
    -- List all units currently seen by seers owned by this player.
    local units = {}
    for _, playerUnit in pairs(self:getUnits()) do
        array.uniqueMerge( units, playerUnit:getSeenUnits() )
    end

	local tmp = util.tdupe( self._seenUnits )
	util.tdiff( tmp, units,
		function( seenUnit )
			local cell = self._sim:getCell( seenUnit:getLocation() )
			self:removeSeenUnit( seenUnit, cell, cell )
		end,
		function( seeUnit )
			self:addSeenUnit( seeUnit )
		end )
end

function simplayer:removeSeenUnit( unit, oldcell, newcell )
	assert( not unit:isGhost() )
	if not array.find( self._seenUnits, unit ) then
		return
	end

	--simlog( "VISCH: [%d] no longer sees %s [%d]", self:getID(), unit:getName(), unit:getID() )
	array.removeElement( self._seenUnits, unit )

	if newcell then
		local cellghost = getCellGhost( self, newcell.x, newcell.y )
		if cellghost then
			addUnitGhost( self._ghost_units, cellghost, unit )
		elseif not self._sim:canPlayerSee( self, newcell.x, newcell.y ) then
			cellghost = addCellGhost( self, self._sim, newcell )
			addUnitGhost( self._ghost_units, cellghost, unit )
		end
	end
	if unit:getTraits().sightable then
		self._sim:triggerEvent( simdefs.TRG_UNIT_DISAPPEARED, { seerID = self:getID(), unit = unit } )
	end
	self._sim:dispatchEvent( simdefs.EV_UNIT_UNSEEN, { player = self, unit = unit } )
end

function simplayer:addSeenUnit( unit )
	assert( not unit:isGhost() )
	if array.find( self._seenUnits, unit ) then
        return -- warp -> refreshLOS (see self), notifySeers (see self again)
    end

	--simlog( "VISCH: [%d] saw %s [%d]", self:getID(), unit:getName(), unit:getID() )
	table.insert( self._seenUnits, unit )

	removeUnitGhost( self, nil, self._sim, unit:getID() )
	if unit:getTraits().sightable then
		self._sim:triggerEvent( simdefs.TRG_UNIT_APPEARED, { seerID = self:getID(), unit = unit } )
	end
	-- Don't track footsteps for visible units.
	self:clearTracks( unit:getID() )

	self._sim:dispatchEvent( simdefs.EV_UNIT_SEEN, { player = self, unit = unit } )
end

function simplayer:getSeenUnits()
    return self._seenUnits
end

function simplayer:trackFootstep( sim, unit, cellx, celly )
	if sim:canPlayerSeeUnit( self, unit ) then
		return
	end

	local closestUnit, closestRange = simquery.findClosestUnit( self._units, cellx, celly, simquery.canHear )
	local footstep =
	{
		x = cellx,
		y = celly,
		isSeen = sim:canPlayerSee( self, cellx, celly ),
		isHeard = closestRange <= simquery.getMoveSoundRange( unit, sim:getCell( cellx, celly ) )
	}

	if unit:getTraits().tagged then
		footstep.isHeard = true
	end

	if self._footsteps[ unit:getID() ] == nil then
		self._footsteps[ unit:getID() ] = {}
	end
	table.insert( self._footsteps[ unit:getID() ], footstep )

	sim:dispatchEvent( simdefs.EV_UNIT_REFRESH_TRACKS, unit:getID() )
end

function simplayer:clearTracks( unitID )
	self._footsteps[ unitID ] = nil
	self._sim:dispatchEvent( simdefs.EV_UNIT_REFRESH_TRACKS, unitID )
end

function simplayer:getTracks( unitID )
	if unitID == nil then
		return self._footsteps -- nil unitID means we are querying ALL tracks
	else
		return self._footsteps[ unitID ]
	end
end

function simplayer:glimpseCell( sim, cell )
	if not sim:canPlayerSee( self, cell.x, cell.y ) then
		self:markSeen( sim, cell.x, cell.y )
		self:markUnseen( sim, cell.x, cell.y )
	end
end

function simplayer:glimpseUnit( sim, unitID )
	local unit = sim:getUnit( unitID )
    if unit == nil then
	    removeUnitGhost( self, nil, sim, unitID )
    elseif array.find( self._seenUnits, unit ) == nil then
        local cell = sim:getCell( unit:getLocation() )
        self:addSeenUnit( unit )
        self:removeSeenUnit( unit, cell, cell )
    end
end

function simplayer:glimpseExit( cellx, celly, dir )
	local cellghost = getCellGhost( self, cellx, celly )
	if cellghost then
		local cell = self._sim:getCell( cellx, celly )
		local exit = cell.exits[ dir ]
		cellghost.exits[ dir ] = util.tmerge( {}, exit )
	end

	-- And the adjacent ghost info should match.
	local dx, dy = simquery.getDeltaFromDirection( dir )
	local rdir = simquery.getReverseDirection( dir )
	local cellghost = getCellGhost( self, cellx + dx, celly + dy )
	if cellghost then
		local cell = self._sim:getCell( cellx + dx, celly + dy )
		cellghost.exits[ rdir ] = util.tmerge( {}, cell.exits[ rdir ] )
	end
end

function simplayer:getLastKnownCell( sim, cellx, celly )
	assert( cellx and celly )
	local cell_ghost = self._ghost_cells[ simquery.toCellID( cellx, celly ) ]
	if cell_ghost then
		return cell_ghost
	elseif sim:canPlayerSee( self, cellx, celly ) then
		return sim:getCell( cellx, celly ) -- This cell is visible, return the raw data
	else
		return nil -- Completely blacked out.  No cell data.
	end
end

function simplayer:getLastKnownUnit( sim, unitID )
	-- FIXME: should only return sim:getUnit if the unit is visible, to be consistent with getLastKnownCell.
	local ghost_unit = self._ghost_units[ unitID ]	
	return ghost_unit or sim:getUnit( unitID )
end

function simplayer:getCell( cellx, celly )
	return self:getLastKnownCell( self._sim, cellx, celly )
end

return simplayer



