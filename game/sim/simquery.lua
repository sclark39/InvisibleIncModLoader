----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local simdefs = include( "sim/simdefs" )
local unitdefs = include( "sim/unitdefs" )
local astar_handlers = include("sim/astar_handlers")
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local binops = include( "modules/binary_ops" )
local astar = include( "modules/astar" )

--------------------------------------------------------------------------

local _M = {}


--------------------------------------------------------------------------
-- Unit queries

function _M.isAgent( unit )
	return unit and unit:hasTrait("isAgent")
end

function _M.canHear( unit )
	local canHear = false
	if unit and unit:getTraits().hasHearing and not unit:isKO() then
		canHear = true
	end
	return canHear
end

-- LOS-independent sight check; should return true if targetUnit could be seen assuming a LOS-check succeeds
-- unit: The unit doing the sight check
-- targetUnit: The target unit; may be nil if only wish to check whether unit can see (at all)
-- ignoreCover: if false, do not check cover status of targetUnit.
function _M.couldUnitSee( sim, unit, targetUnit, ignoreCover, targetCell )
	if not unit:getTraits().hasSight then
		return false
	end
    if unit:isKO() then
        return false
    end
    if unit:getTraits().grappler then
    	return false
	end

	if targetUnit and targetUnit ~= unit then

		if not targetUnit:getLocation() then
			return false
		end

		if targetUnit:getTraits().invisible and targetUnit:getPlayerOwner() ~= unit:getPlayerOwner() then
			-- Could add invisible-detection code here.
			return false
		end
        
        ignoreCover = ignoreCover or unit:isPC()
        if not ignoreCover then
        	if not targetCell then
        		targetCell = sim:getCell(targetUnit:getLocation() )
    		end
		    if not unit:getTraits().seesHidden and targetUnit:canHide() and
		     _M.checkIfCellNextToCover(sim, targetCell) and _M.checkCover( sim, unit, targetCell.x, targetCell.y ) then
			    return false
		    end
        end
	end

	return true
end

-- facing-independent sight check. Returns true if the cell would be within LOS if the unit turned to face it
function _M.couldUnitSeeCell(sim, unit, cell)
	local x0, y0 = unit:getLocation()

	if unit:getTraits().LOSrange and mathutil.dist2d(x0, y0, cell.x, cell.y) > unit:getTraits().LOSrange then
		return false
	end

	local raycastX, raycastY = sim:getLOS():raycast(x0, y0, cell.x, cell.y)
	if raycastX ~= cell.x or raycastY ~= cell.y then
		return false
	end

	return true
end

function _M.canSeeLOS( sim, player, seer )
    if sim:getParams().difficultyOptions.dangerZones then
        return true
    end
    
    if player == seer:getPlayerOwner() then
        return true
    end

    if player ~= nil and sim:canPlayerSeeUnit( player, seer ) then
        return true
    end

    return false
end

function _M.isCellWatched( sim, player, cellx, celly )
	local isWatched, isNoticed ,isHidden = false, false, false

	if sim:canPlayerSee( player, cellx, celly ) then
		local seers = sim:getLOS():getSeers( cellx, celly )
		for _, seerID in ipairs(seers) do
			local seerUnit
			if seerID >= simdefs.SEERID_PERIPHERAL then
				seerUnit = sim:getUnit( seerID - simdefs.SEERID_PERIPHERAL )
			else
				seerUnit = sim:getUnit( seerID )
			end

			if seerUnit and seerUnit:getPlayerOwner() ~= player and _M.canSeeLOS( sim, player, seerUnit ) then
				if _M.checkCover( sim, seerUnit, cellx, celly ) then
					isHidden = true
				elseif seerID >= simdefs.SEERID_PERIPHERAL then
					isNoticed = true
				else
					isWatched = true
					break
				end
			end
		end
	end

	if isWatched then
		return simdefs.CELL_WATCHED
	elseif isNoticed then
		return simdefs.CELL_NOTICED
	elseif isHidden then
		return simdefs.CELL_HIDDEN
	end
end

function _M.getLOSArc( unit )
	return unit:getTraits().LOSarc or (math.pi / 2)
end

function _M.getNearestEnemy( unit, LOSnotNeeded, includeKO )

	local range = 9999 
	local unitPlayer = unit:getPlayerOwner()
	local x1,y1 = unit:getLocation()
	local nearestUnit = nil
	local sim = unit:getSim()
	for i,simUnit in pairs(sim:getAllUnits()) do
		if simUnit:getPlayerOwner() and simUnit:getPlayerOwner() ~= unitPlayer and not simUnit:isDead() and (not simUnit:isKO() or includeKO) then
			if LOSnotNeeded or sim:canUnitSee(simUnit, x1,y1) then 
				
				local x2,y2 = simUnit:getLocation()
				local distance = math.floor( mathutil.dist2d( x1,y1,x2,y2 ) )
				if distance < range then
					nearestUnit = simUnit
					range = distance
				end
			end
		end
	end

	return nearestUnit, range
end


function _M.isEnemyAgent( player, unit, ignoreDisguise)

	if not unit:hasTrait("isAgent") then
		return false
	end
	
	return _M.isEnemyTarget( player, unit, ignoreDisguise )
end

function _M.isEnemyTarget( player, unit, ignoreDisguise )
	if unit == nil or unit:getPlayerOwner() == nil then
		return false -- Nothing is aggressive to neutrals.
	end

	if unit:getPlayerOwner() == player then
		return false -- Nothing is aggressive to itself!
	end
	
	if unit:getTraits().disguiseOn and not ignoreDisguise then
		return false -- disguised unit is not a threat, disguise is removed when they move too close to an enemy, handled in onWarp
	end	
	
	if player == nil and unit:getPlayerOwner():isNPC() then
		return false -- Neutral isn't aggressive to NPCs.
	end

	if not unit:getWounds() then
		return false -- Nothing is aggressive to anything without a wound counter.
	end

	local lastAttackedPlayer = unit:getTraits().lastAttack and unit:getTraits().lastAttack.player
	if unit:getTraits().mainframe_turret then
		--ignore turrets unless they're armed or have been aggressive
		if unit:getTraits().isArmed and lastAttackedPlayer and lastAttackedPlayer == player then
			return true
		end
		return false 
	end

	if unit:getTraits().takenDrone then
		return false -- Nothing is aggressive to taken-over drones
	end

	return true
end

function _M.isKnownTraitor(unit, checkingUnit)
	local lastAttack = unit:getTraits().lastAttack
	if lastAttack and lastAttack.player and lastAttack.player == checkingUnit:getPlayerOwner() and lastAttack.witnesses[checkingUnit:getID()] then
		return true
	end

	return false
end

function _M.isShootable( unit, targetUnit )
	if not targetUnit:getTraits().canBeShot or targetUnit:isDead() then
        return false
	end

    if not targetUnit:getTraits().canBeFriendlyShot and targetUnit:getPlayerOwner() == unit:getPlayerOwner() then
        return false
    end

    if unit == targetUnit then
        return false
    end

	return true
end

function _M.canGive( sim, unit, targetUnit )
	if targetUnit == nil or targetUnit:isGhost() then
		return false
	end
	
	if unit == targetUnit then
		return false
	end

	if unit:getTraits().isDrone or targetUnit:getTraits().isDrone then
		return false
	end

	if not _M.isAgent( unit ) or not _M.isAgent( targetUnit ) then
		return false
	end

	if not unit:canAct() then
		return false
	end

	if unit:getTraits().movingBody == targetUnit then
		return false
	end

	if unit:getPlayerOwner() ~= targetUnit:getPlayerOwner() then
		return false
	end

	if not _M.canUnitReach( sim, unit, targetUnit:getLocation() ) then
		return false
	end

	return true
end

function _M.canSteal( sim, unit, targetUnit )
	if unit:getTraits().isDrone then
		return false
	end

	if targetUnit == nil or targetUnit:isGhost() then	
		return false
	end

	if not unit:canAct() then
		return false
	end

	if unit:getTraits().movingBody == targetUnit then
		return false
	end

	local inventoryCount = targetUnit:getInventoryCount()
	if not unit:getTraits().anarchyItemBonus then
		for i,child in ipairs(targetUnit:getChildren()) do
			if child:getTraits().anarchySpecialItem and child:hasAbility( "carryable" ) then
				inventoryCount = inventoryCount -1
			end
		end
	end

	if not unit:getTraits().largeSafeMapIntel then
		for i,child in ipairs(targetUnit:getChildren()) do
			if child:getTraits().largeSafeMapIntel and child:hasAbility( "carryable" ) then
				inventoryCount = inventoryCount -1
			end
		end
	end	
	if inventoryCount == 0 then 
		return false
	end

	local cell = sim:getCell( unit:getLocation() )
	local found = (cell == sim:getCell( targetUnit:getLocation() ))
	for simdir, exit in pairs( cell.exits ) do
		if _M.isOpenExit( exit ) then
			found = found or array.find( exit.cell.units, targetUnit ) ~= nil
		end
	end
	if not found then
		return false, STRINGS.UI.REASON.CANT_REACH
	end

	return true
end

function _M.canLoot( sim, unit, targetUnit )
	if unit:getTraits().isDrone then
		return false
	end

	if targetUnit == nil or targetUnit:isGhost() then
		return false
	end

	if not unit:canAct() then
		return false
	end

	if unit:getTraits().movingBody == targetUnit then
		return false
	end

	if not targetUnit:getTraits().iscorpse then
		if _M.isEnemyTarget( unit:getPlayerOwner(), targetUnit ) then
			if not targetUnit:isKO() and not unit:hasSkill("anarchy", 2) then 
				return false
			end

			if not targetUnit:isKO() and sim:canUnitSeeUnit(targetUnit, unit) then
				return false
			end
		else
			if not targetUnit:isKO() then
				return false
			end
		end
	end

	local inventoryCount = targetUnit:getInventoryCount()
	if not unit:getTraits().anarchyItemBonus then
		for i,child in ipairs(targetUnit:getChildren()) do
			if child:getTraits().anarchySpecialItem and child:hasAbility( "carryable" ) then
				inventoryCount = inventoryCount -1
			end
		end
	end

	
	if not unit:getTraits().largeSafeMapIntel then
		for i,child in ipairs(targetUnit:getChildren()) do
			if child:getTraits().largeSafeMapIntel and child:hasAbility( "carryable" ) then
				inventoryCount = inventoryCount -1
			end
		end
	end	
	if _M.calculateCashOnHand( sim, targetUnit ) <= 0 and _M.calculatePWROnHand( sim, targetUnit ) <=0 and inventoryCount == 0 then 
		return false
	end

	local cell = sim:getCell( unit:getLocation() )
	local found = (cell == sim:getCell( targetUnit:getLocation() ))
	for simdir, exit in pairs( cell.exits ) do
		if _M.isOpenExit( exit ) then
			found = found or array.find( exit.cell.units, targetUnit ) ~= nil
		end
	end
	if not found then
		return false, STRINGS.UI.REASON.CANT_REACH
	end

	return true
end

function _M.calculateCashOnHand( sim, unit )
	local value = unit:getTraits().cashOnHand or 0
	if value > 0 and not unit:getTraits().noRandomCash then
		-- Hardcode some randomosity.  May need to data-drive these parameters a bit more.
		local vmin, vmax = 0, math.floor(value / 2)
		local add = (unit:getID() * 10 % (vmax - vmin)) + vmin
		value = _M.scaleCredits( sim, value + add )
	end
	return value
end

function _M.calculatePWROnHand( sim, unit )
	local value = unit:getTraits().PWROnHand or 0
	if value > 0 and not unit:getTraits().noRandomPWR then
		-- Hardcode some randomosity.  May need to data-drive these parameters a bit more.
	--	local vmin, vmax = 0, math.floor(value / 2)
--		local add = (unit:getID() * 10 % (vmax - vmin)) + vmin
		-- no PWR scaler yet
		--value = _M.scaleCredits( sim, value + add )  
	end
	return value
end

function _M.isUnitUnderOverwatch(unit )
    local aiPlayer = unit:getSim():getNPC()
    local situation = aiPlayer and aiPlayer:findExistingCombatSituation(unit)
    if situation and situation:isValid() then
    	for k,unit in pairs(situation.units) do
    		if not unit:isDown() and not unit:getTraits().pacifist then
    			return true
			end
		end
    end
    return false
end

function _M.isUnitWatched(unit )
    local aiPlayer = unit:getSim():getNPC()
    local situation = aiPlayer and aiPlayer:findExistingCombatSituation(unit)
    if situation and situation:isValid() then
    	return true
    end
    return false
end

function _M.isUnitPinning( sim, unit )
	if unit:getTraits().movingBody then
		return false
	end
	local cell = sim:getCell( unit:getLocation() )
	if cell then
		for i, cellUnit in ipairs(cell.units) do
			if cellUnit:isKO() and not cellUnit:isDead() and _M.isEnemyAgent( unit:getPlayerOwner(), cellUnit ) then
				return true, cellUnit
			end
		end
	end

	return false
end

function _M.isUnitPinned( sim, unit )
	if unit:isKO() then
		local cell = sim:getCell( unit:getLocation() )

		if cell then
			for i, cellUnit in ipairs(cell.units) do
				if not cellUnit:isKO() and (_M.isEnemyAgent( unit:getPlayerOwner(), cellUnit ) and  cellUnit:getTraits().dynamicImpass ) and not cellUnit:getTraits().movingBody then
					return true, cellUnit
				end
			end
		end
	end

	return false
end

function _M.isUnitCellFull( sim, unit )
	if unit:isKO() then
		local cell = sim:getCell( unit:getLocation() )

		if cell then
			for i, cellUnit in ipairs(cell.units) do
				if not cellUnit:isKO() and cellUnit:getTraits().dynamicImpass then
					return true, cellUnit
				end
			end
		end
	end

	return false
end

function _M.isUnitDragged( sim, unit )
	local cell = sim:getCell( unit:getLocation() )
	if cell then
		for i, cellUnit in ipairs(cell.units) do
			if cellUnit:getTraits().movingBody == unit then
				return true, cellUnit
			end
		end
	end

	return false
end

function _M.isItem( unit )
	return not _M.isAgent( unit )
end

function _M.isKey( unit, keybits )
	if keybits == nil then
		return unit:hasTrait("keybits")
	else
		return binops.b_and( keybits, unit:getTraits().keybits or 0 ) ~= 0
	end
end

function _M.hasKey( unit, keybits )

	for _,childUnit in pairs(unit:getChildren()) do
		if _M.isKey( childUnit, keybits ) then
			return true
		end
	end

	if unit:getTraits().passiveKey then 
		if binops.b_and( keybits, unit:getTraits().passiveKey ) ~= 0 then
			return true 
		end 
	end 

	return false
end

function _M.getEquippedGun( unit )
	if unit and unit:getChildren() then
		for _,childUnit in pairs( unit:getChildren() ) do
			if childUnit:getTraits().equipped and childUnit:getTraits().slot =="gun" then
				return childUnit
			end
		end
	end
end

function _M.getEquippedMelee( unit )
	if unit and unit:getChildren() then
		for _,childUnit in pairs( unit:getChildren() ) do
			if childUnit:getTraits().equipped and childUnit:getTraits().melee then
				return childUnit
			end
		end
	end
end

function _M.scaleCredits( sim, amount )
    local s1 = simdefs.MONEY_SCALAR[ sim:getParams().difficulty ]
    local s2 = sim:getParams().difficultyOptions.creditMultiplier

    return math.ceil( amount * s1 * s2 / 10 ) * 10
end


--------------------------------------------------------------------------
-- Cells and exits

function _M.findUnit( units, fn )
	for _, unit in pairs(units) do
		if fn(unit) then
			return unit
		end
	end
	return nil
end

function _M.findAgentInList( units, exceptUnit )
	if units then
		return array.findIf( units,
			function( u ) return u ~= exceptUnit and u:hasTrait("isAgent") end )
	end
end

function _M.findItemInList( units )

	if units then
		return array.findIf( units, _M.isItem )
	end
end

function _M.findClosestUnit( units, x0, y0, fn )
	local closestRange = math.huge
	local closestUnit = nil
	for i,unit in pairs(units) do
		if fn == nil or fn( unit ) then
			local x1, y1 = unit:getLocation()
			if x1 then
				local range = mathutil.distSqr2d( x0, y0, x1, y1 )
				if range < closestRange then
					closestRange = range
					closestUnit = unit
				end
			end
		end
	end

	return closestUnit, math.sqrt( closestRange )
end

-- Returns a unique cellID for (x, y).
-- Standard way of linearizing grid cells uses the grid width, but we don't care that our IDs are consecutive, so
-- we save a parameter by using an arbitrary value >> the grid width :)
function _M.toCellID( x, y )
	-- Note that x, y are 1-based (not that it really matters...)
	return y * 1000 + x
end

-- Reverse function of toCellID
function _M.fromCellID( cellid )
	return  (cellid % 1000), math.floor( cellid / 1000 )
end

function _M.cellHasTag(sim, cell, tag)
	local group = sim._board.cell_groups[ tag ]
	if not group then
		return false
	end
	for i,v in ipairs(group) do
		if v == cell then
			return true
		end
	end
	return false
end

function _M.findExitCells( sim )
	local exitCells = {}
	sim:forEachCell(
		function( c )
			if c.exitID then
				table.insert( exitCells, c )
			end
		end )
	return exitCells
end

function _M.isSameLocation( u1, u2 )
	local x0, y0 = u1:getLocation()
	local x1, y1 = u2:getLocation()
	return x0 and x1 and x0 == x1 and y0 == y1
end

function _M.canReach( sim, x0, y0, x1, y1 )
	if x0 ~= x1 or y0 ~= y1 then
		local cell = sim:getCell( x0, y0 )
		local distance = mathutil.dist2d( x0, y0, x1, y1 )
		if distance > 1 then
			return false, util.sformat( STRINGS.UI.REASON.CANT_REACH_BY, math.ceil(distance - 1) )
		end

		local dir = _M.getDirectionFromDelta( x1 - x0, y1 - y0 )
		if not _M.isOpenExit( cell.exits[ dir ]) then
			return false, STRINGS.UI.REASON.BLOCKED
		end
	end

	return true
end

function _M.canUnitReach( sim, unit, x1, y1 )
	local x0, y0 = unit:getLocation()
	return _M.canReach( sim, x0, y0, x1, y1 )
end

function _M.rotateFacing( facing, dx, dy )
	-- Rotates <dx, dy> (which is understood to be in the default frame, eg. facing == simdefs.DIR_N) to the facing frame
	if facing == simdefs.DIR_N then
		return dx, dy
	elseif facing == simdefs.DIR_W then
		return -dy, dx
	elseif facing == simdefs.DIR_S then
		return -dx, -dy
	elseif facing == simdefs.DIR_E then
		return dy, -dx
	else
		assert(false, "Illegal orientation " ..tostring(facing))
	end
end

function _M.addFacing(f1,f2)
	local fr = f1 + f2
	if fr >= simdefs.DIR_MAX then
		fr = fr - simdefs.DIR_MAX
	elseif fr < simdefs.DIR_E then
		fr = fr + simdefs.DIR_MAX
	end
	return fr
end

function _M.getAgentCoverDir(unit)
	if not unit:getTraits().hidesInCover or unit:getTraits().movePath or unit:getTraits().iscorpse then
		return nil
	end
	local cell = unit:getSim():getCell(unit:getLocation() )
	-- Any half-wall covers to hide behind?
	for _, dir in ipairs(simdefs.DIR_SIDES) do
		if _M.checkIsHalfWall(unit:getSim(), cell, dir ) then
			return _M.getReverseDirection(dir)
		end
	end
end

function _M.getAgentLeanDir(unit)
	if not unit:getTraits().hidesInCover or unit:getTraits().movePath or unit:getTraits().iscorpse then
		return nil
	end
	local cell = unit:getSim():getCell(unit:getLocation() )
	for _, dir in ipairs(simdefs.DIR_SIDES) do
		if _M.checkIsWall(unit:getSim(), cell,dir) then
			local ldir, rdir = ( dir - 2 ) % simdefs.DIR_MAX, ( dir + 2 ) % simdefs.DIR_MAX

			if cell.exits[ldir] and not _M.checkIsWall(unit:getSim(), cell.exits[ldir].cell, dir) then
				return _M.getReverseDirection(dir) -- It's open to the left!
			end

			if cell.exits[rdir] and not _M.checkIsWall(unit:getSim(), cell.exits[rdir].cell, dir) then
				return _M.getReverseDirection(dir) -- It's open to the right!
			end
		end
	end
end

function _M.getAgentShoulderDir(unit, x, y)
	if not unit:getTraits().hidesInCover then
		return nil
	end
	local facingDir = _M.getAgentCoverDir(unit) or _M.getAgentLeanDir(unit) or unit:getFacing()
	local x0, y0 = unit:getLocation()
	local facingX, facingY = _M.getDeltaFromDirection(facingDir)
	local sideX, sideY = -facingY, facingX
	local x1, y1 = x0+facingX, y0+facingY
	local x2, y2 = x0+sideX, y0+sideY

	--let's check to see that the point is actually on the correct side of the cover
	local side_det = (x2-x0)*(y-y0) - (y2-y0)*(x-x0)
	if side_det > 0 then
		--let's check which side of the cover it's on
		local det = (x1-x0)*(y-y0) - (y1-y0)*(x-x0)
		if det > 0 then
			return simdefs.SHOULDER_LEFT
		elseif det <= 0 then
			return simdefs.SHOULDER_RIGHT
		end
	end
end

function _M.suggestAgentFacing(unit, facing)
	local sim = unit:getSim()

	if not unit or not facing then
		return
	end

	if not unit:canAct() or not unit:getLocation() or unit:getTraits().movingBody then
		return
	end
	
	local dir = _M.getAgentCoverDir(unit)
	if not dir then
		dir = _M.getAgentLeanDir(unit)
	end
	if not dir then
		dir = facing
	end
		
	if dir and dir ~= unit:getFacing() then
		unit:setFacing(dir)
	end

end

function _M.getFacingRads( facing )
	return math.pi / 4 * facing
end

function _M.getReverseDirection( dir )

	if dir == simdefs.DIR_N then
		return simdefs.DIR_S
	elseif dir == simdefs.DIR_S then
		return simdefs.DIR_N
	elseif dir == simdefs.DIR_E then
		return simdefs.DIR_W
	elseif dir == simdefs.DIR_W then
		return simdefs.DIR_E
	elseif dir == simdefs.DIR_NE then
		return simdefs.DIR_SW
	elseif dir == simdefs.DIR_SE then
		return simdefs.DIR_NW
	elseif dir == simdefs.DIR_NW then
		return simdefs.DIR_SE
	elseif dir == simdefs.DIR_SW then
		return simdefs.DIR_NE
	else
		assert(false, "Illegal direction or no reverse: " .. tostring(dir))
	end
end

-- Returns the discrete signed difference between two simdir values.
-- The range is from [-3, 4] (since any two directions can differ by at most 4 steps),
-- where negative implies d1 is anti-clockwise from d0, while positive is clockwise.
function _M.dirDiff( d0, d1 )
	local dd = d0 - d1
	if dd > 4 then
		dd = dd - 8
	elseif dd <= -4 then
		dd = dd + 8
	end
	return dd
end

function _M.getDirectionFromDelta( dx, dy )
	if dx == 0 and dy == 0 then
		return simdefs.DIR_MAX
	end

	local r = math.atan2( dx, dy )
	if r >= -math.pi / 8 and r <= math.pi / 8 then
		return simdefs.DIR_N
	elseif r >= math.pi / 8 and r <= 3 * math.pi / 8 then
		return simdefs.DIR_NE
	elseif r >= 3 * math.pi / 8 and r <= 5 * math.pi / 8 then
		return simdefs.DIR_E
	elseif r >= 5 * math.pi / 8 and r <= 7 * math.pi / 8 then
		return simdefs.DIR_SE
	elseif r >= 7 * math.pi / 8 or r <= -7 * math.pi / 8 then
		return simdefs.DIR_S
	elseif r <= -5 * math.pi / 8 and r >= -7 * math.pi / 8 then
		return simdefs.DIR_SW
	elseif r <= -3 * math.pi / 8 and r >= -5 * math.pi / 8 then
		return simdefs.DIR_W
	elseif r <= -1 * math.pi / 8 and r >= -3 * math.pi / 8 then
		return simdefs.DIR_NW
	end
end

function _M.getDeltaFromDirection( dir )
	if dir == simdefs.DIR_E then
		return 1, 0
	elseif dir == simdefs.DIR_NE then
		return 1, 1
	elseif dir == simdefs.DIR_NW then
		return -1, 1
	elseif dir == simdefs.DIR_N then
		return 0, 1
	elseif dir == simdefs.DIR_W then
		return -1, 0
	elseif dir == simdefs.DIR_SW then
		return -1, -1
	elseif dir == simdefs.DIR_S then
		return 0, -1
	elseif dir == simdefs.DIR_SE then
		return 1, -1
	end
end

function _M.isOpenExit( exit )
	return exit ~= nil and not exit.closed
end

function _M.isDoorExit( exit )
	return exit ~= nil and exit.door
end

function _M.isClosedDoor( exit )
	return exit ~= nil and exit.door and exit.closed
end

function _M.isSecurityExit( exit )
	return _M.isClosedDoor( exit ) and exit.locked and exit.keybits == simdefs.DOOR_KEYS.SECURITY
end

--------------------------------------------------------------------------------
-- Determines whether a pair of cells are connected.  Cells are connected if they
-- have an open exit between them, or are diagonally connected (blech special cases)
-- (eg. a unit can 'move' from cell1 to cell2)
--
-- cell1, cell2 => a pair of cells
-- returns => true/false (if cell1 and cell2 are connected)

function _M.isConnected( cellQuery, cell1, cell2 )
	if not cell1 or not cell2 then
		return false
	end
	if cell1.sightblock then
		return false
	end

	if (cell1.x + 1 == cell2.x or cell1.x - 1 == cell2.x) and (cell1.y + 1 == cell2.y or cell1.y - 1 == cell2.y) then
		-- Diagonal coordinates
		local cell3 = cellQuery:getCell( cell1.x, cell2.y )
		local cell4 = cellQuery:getCell( cell2.x, cell1.y )

		return (_M.isConnected( cellQuery, cell1, cell3 ) and _M.isConnected( cellQuery, cell3, cell2 )) and
				(_M.isConnected( cellQuery, cell1, cell4 ) and _M.isConnected( cellQuery, cell4, cell2 ))
	
	else
		for k,exit in pairs(cell1.exits) do
			-- Note that it is not sufficient to compare exit.cell == cell2; if cell2 is a ghost, that equality will incorrectly fail
			if exit.cell.x == cell2.x and exit.cell.y == cell2.y and not exit.closed then
				return true
			end
		end
	end

	return false
end

--------------------------------------------------------------------------
-- Action queries

function _M.is360viewClear(sim,unit,unitRange,x,y)
    assert( unit and unitRange )
	local ux, uy = unit:getLocation()
	local dist = mathutil.dist2d(ux, uy, x, y)
	if dist > unitRange then
		return false
	end
	local raycastX, raycastY = sim:getLOS():raycast(ux, uy, x, y)
	if raycastX ~= x or raycastY ~= y then
		return false
	end
	return true
end

function _M.findPath( sim, unit, startcell, endcell, maxMP, goalFn )
	local pather = astar.AStar:new( astar_handlers.handler:new( sim, unit, maxMP, goalFn ))
	if not startcell or startcell == endcell then
		return nil
	end
	-- If a goalFn exists, then presumably there are other goal cells than endcell, hence don't fail
	-- just because endcell is impassable.
	if goalFn == nil and not _M.canPath( unit:getPlayerOwner() or sim, unit, nil, endcell ) then
		return nil
	end

	local path = pather:findPath( startcell, endcell )

	if path then
		local moveTable = {}
		for i,node in pairs(path:getNodes()) do
			local cell = node.location
			table.insert( moveTable, { x = cell.x, y = cell.y } )
		end

		return moveTable, path:getTotalMoveCost()
	end
end

function _M.getOwnedLaserEmitter( sim, unit, cellUnit )
    if unit == nil then
        return nil
    end
    local movingBody = unit:getTraits().movingBody
	if cellUnit:getTraits().emitterID then
		local emitterUnit = sim:getUnit( cellUnit:getTraits().emitterID )
		if emitterUnit then
            if emitterUnit:isPC() and unit:isPC() then
                return emitterUnit
            elseif emitterUnit:getPlayerOwner() == nil and unit:isNPC() then
                return emitterUnit
            elseif movingBody and movingBody:isNPC() and emitterUnit:getPlayerOwner() == nil then
                return emitterUnit
            end
		end
	end

    return nil
end


function _M.canPath( cellquery, unit, startcell, endcell )
	-- Check for dynamic impass.  Note that even if dynamicImpass exists, if the unit owner doesn't know it's there, this won't fail.
    if unit == nil or unit:getTraits().dynamicImpass then
	    for i,cellUnit in ipairs(endcell.units) do
		    if cellUnit:getTraits().dynamicImpass then
                -- Owned emitters will turn themselves off, so they are not considered impassable.
                if cellUnit:getTraits().emitterID == nil or cellUnit:isGhost() or not cellUnit:canControl( unit ) then
				    return false, simdefs.CANMOVE_DYNAMIC_IMPASS
			    end
		    end
	    end
    end

	return _M.canStaticPath( cellquery, unit, startcell, endcell )
end

-- Soft pathing is used by the AI as a kind of broad phase to determine not whether a
-- path can actually be followed without failure, but whether a path is appropriate to try
-- to reach a given destination.  For example, if the route is obstructed by a PC, canSoftPath
-- will still return true, since presumably the AI will take measures to remove the obstruction:
-- the alternative taking the long way around is undesirable in this case.
-- Note that this means the query is based on raw sim data, not the NPC-centric view.  Yes, this
-- means the AI technically "cheats"... but I think it's not very noticeable, and the alternative
-- is silly looking behaviour.
function _M.canSoftPath( sim, unit, startcell, endcell )
	-- Check for dynamic impass that is not removable by player.
    assert( not endcell.ghostID )
    assert( not startcell.ghostID )
    assert( unit:isNPC() ) -- This fn is not expected to be used by non-NPCs.
	local isDiagonal = (startcell.x + 1 == endcell.x or startcell.x - 1 == endcell.x) and (startcell.y + 1 == endcell.y or startcell.y - 1 == endcell.y)

	for i,cellUnit in ipairs(endcell.units) do
		if unit and cellUnit:getTraits().dynamicImpass then
            if cellUnit:getTraits().emitterID and cellUnit:canControl( unit ) then
                -- Owned emitters will turn themselves off, so they are not considered impassable.
			elseif _M.isEnemyAgent(unit:getPlayerOwner(), cellUnit) and not isDiagonal then
                -- Allow pathing through enemy agents on the cardinal directions, but not diagonally.
            elseif cellUnit:getPlayerOwner() == unit:getPlayerOwner() then
                -- Allow pathing through same owners.
			else
				return false, simdefs.CANMOVE_DYNAMIC_IMPASS
			end
		end
	end

	return _M.canStaticPath( sim, unit, startcell, endcell )
end

function _M.canPathBetween( cellquery, unit, startcell, endcell )
	if endcell == nil then
		return false
	end

	local dx, dy = endcell.x - startcell.x, endcell.y - startcell.y
	if (startcell.x + 1 == endcell.x or startcell.x - 1 == endcell.x) and (startcell.y + 1 == endcell.y or startcell.y - 1 == endcell.y) then
		-- diagonal.  both exits to the diagonal must be open.
		local cell3 = cellquery:getCell( startcell.x, endcell.y )
		local cell4 = cellquery:getCell( endcell.x, startcell.y )
		if cell3 == nil or cell4 == nil then
			return false
		end
		local d1, d2 = _M.getDirectionFromDelta( cell3.x - startcell.x, cell3.y - startcell.y ), _M.getDirectionFromDelta( endcell.x - cell3.x, endcell.y - cell3.y )
		local d3, d4 = _M.getDirectionFromDelta( cell4.x - startcell.x, cell4.y - startcell.y ), _M.getDirectionFromDelta( endcell.x - cell4.x, endcell.y - cell4.y )

		if not (_M.isOpenExit( startcell.exits[ d1 ] ) and _M.isOpenExit( cell3.exits[ d2 ] ) and
				_M.isOpenExit( startcell.exits[ d3 ] ) and _M.isOpenExit( cell4.exits[ d4 ] )) then
			return false
		end
	
	else
		local dir = _M.getDirectionFromDelta( dx, dy )
		local exit = startcell.exits[ dir ]
		local found = exit and exit.cell.x == endcell.x and exit.cell.y == endcell.y
		if unit then
			found = found and (not (exit.closed and exit.locked) or _M.canModifyExit( unit, simdefs.EXITOP_UNLOCK, startcell, dir ))
			found = found and (not exit.closed or _M.canModifyExit( unit, simdefs.EXITOP_OPEN, startcell, dir ))
		else
			found = found and not (exit.locked and exit.closed)
		end
		if not found then
			return false
		end
	end
	
	return true
end

-- startcell, endcell are "adjacent".  This query does NOT do a pathfind between arbitrary cells.
-- Determines whether the connection between startcell and endcell is passable, and whether endcell
-- itself is statically passable
function _M.canStaticPath( cellquery, unit, startcell, endcell )
	if endcell.impass > 0 then
		return false, simdefs.CANMOVE_STATIC_IMPASS
	end

	if startcell and not _M.canPathBetween( cellquery, unit, startcell, endcell ) then
		return false, simdefs.CANMOVE_NOEXIT
	end

	return true, simdefs.CANMOVE_OK
end

-- cell1, cell2 should be connected cells (adjacent or diagonal)
function _M.getMoveCost( cell1, cell2 )
	assert( math.abs(cell1.x - cell2.x) <= 1 and math.abs(cell1.y - cell2.y) <= 1 or error(string.format( "<%d, %d> -> <%d, %d>", cell1.x, cell1.y, cell2.x, cell2.y )))
	return mathutil.dist2d( cell1.x, cell1.y, cell2.x, cell2.y )
end



function _M.getManhattanMoveCost( cell1, cell2)
	-- if there is a closed door, this increases the cost.
	-- NOTE: since cell1 or cell2 may be ghosted cells, do NOT use a table compare to see if exit.cell == cell2!
	for k,exit in pairs(cell1.exits) do
		if exit.cell.x == cell2.x and exit.cell.y == cell2.y and _M.isOpenExit( exit ) then
			return 1
		end
	end

	return math.huge
end

function  _M.canMoveUnit( sim, unit, x, y )

	-- Unit must be located on the board.
	local startcell = sim:getCell( unit:getLocation() )
	if not startcell then
		return false, simdefs.CANMOVE_NOEXIT
	end

	-- Target location must exist
	local endcell = sim:getCell( x, y )
	if not endcell then
		return false, simdefs.CANMOVE_NOEXIT
	end

	-- Must have sufficient movement available
	if unit:getTraits().mp < _M.getMoveCost( startcell, endcell ) then
		return false, simdefs.CANMOVE_NOMP
	end

	-- Must be open exit that can be opened (NOTE: its likely this check should be moved into canPath, but
	-- canPath doesn't take a unit parameter ... )
	local dir = _M.getDirectionFromDelta( endcell.x - startcell.x, endcell.y - startcell.y )
	local exit = startcell.exits[ dir ]
	if exit and exit.closed and unit:getTraits().movingBody then
		return false, simdefs.CANMOVE_STATIC_IMPASS
	elseif exit and exit.closed and (exit.keybits == simdefs.DOOR_KEYS.GUARD or exit.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE or exit.keybits == simdefs.DOOR_KEYS.ELEVATOR) then
		return false, simdefs.CANMOVE_STATIC_IMPASS
	end

    if unit:getTraits().dynamicImpass then
	    return _M.canPath( sim, unit, startcell, endcell)
    else
	    return _M.canStaticPath( sim, unit, startcell, endcell )
    end
end

function _M.findNearestEmptyCell( sim, x, y, unit )

	local cell = sim:getCell(x, y)

	local resultCell = nil
	for dx = -1,1 do
	for dy = -1,1 do
		local testCell = sim:getCell( cell.x + dx, cell.y + dy )
		if testCell and _M.canPath( sim, nil, nil, testCell ) then
			if not resultCell then
				resultCell = testCell
			elseif unit then
				local unitX,unitY = unit:getLocation()
				if unitX == x and unitY == y then
					--pick a cell close to the current unit facing
					local cell1Dir = _M.getDirectionFromDelta(testCell.x - unitX, testCell.y - unitY)
					local cell2Dir = _M.getDirectionFromDelta(resultCell.x - unitX, resultCell.y - unitY)
					if math.abs(_M.dirDiff(cell1Dir, unit:getFacing() ) ) < math.abs(_M.dirDiff(cell2Dir, unit:getFacing() ) ) then
						resultCell = testCell
					end
				else
					--pick the closest cell
					local cell1Dist = mathutil.dist2d( testCell.x, testCell.y, unitX, unitY )
					local cell2Dist = mathutil.dist2d( resultCell.x, resultCell.y, unitX, unitY )
					if cell1Dist < cell2Dist then
						resultCell = testCell
					end
				end
			end
		end
	end
	end

	return resultCell
end

function _M.findNearestEmptyReachableCell( sim, x, y, unit )

	local cell = sim:getCell(x, y)

	local resultCell = nil
	for dx = -1,1 do
	for dy = -1,1 do
		local testCell = sim:getCell( cell.x + dx, cell.y + dy )
		if testCell and _M.canReach(sim, x, y, testCell.x, testCell.y) and _M.canPath( sim, nil, nil, testCell ) then
			if not resultCell then
				resultCell = testCell
			elseif unit then
				local unitX,unitY = unit:getLocation()
				if unitX == x and unitY == y then
					--pick a cell close to the current unit facing
					local cell1Dir = _M.getDirectionFromDelta(testCell.x - unitX, testCell.y - unitY)
					local cell2Dir = _M.getDirectionFromDelta(resultCell.x - unitX, resultCell.y - unitY)
					if math.abs(_M.dirDiff(cell1Dir, unit:getFacing() ) ) < math.abs(_M.dirDiff(cell2Dir, unit:getFacing() ) ) then
						resultCell = testCell
					end
				else
					--pick the closest cell
					local cell1Dist = mathutil.dist2d( testCell.x, testCell.y, unitX, unitY )
					local cell2Dist = mathutil.dist2d( resultCell.x, resultCell.y, unitX, unitY )
					if cell1Dist < cell2Dist then
						resultCell = testCell
					end
				end
			end
		end
	end
	end

	return resultCell
end

-- Determines if unit can reach the door at cell.exits[ dir ] (must be a valid door)
function _M.canReachDoor( unit, cell, dir )

	local x0,y0 = unit:getLocation()
	if x0 == cell.x and y0 == cell.y then
		return true
	else
		-- Only cells whose direction is normal to the door are reachable.
		local dir1 = (dir + 2) % simdefs.DIR_MAX
		if _M.isOpenExit( cell.exits[ dir1 ] ) and cell.exits[ dir1 ].cell.x == x0 and cell.exits[ dir1 ].cell.y == y0 then
			return true
		end
		local dir2 = (dir + 6) % simdefs.DIR_MAX
		if _M.isOpenExit( cell.exits[ dir2 ] ) and cell.exits[ dir2 ].cell.x == x0 and cell.exits[ dir2 ].cell.y == y0 then
			return true
		end
	end

	return false
end


local function getKeyReason( exit )
	if exit.keybits == simdefs.DOOR_KEYS.ELEVATOR then
		return false, STRINGS.UI.DOORS.ELEVATOR
	elseif exit.keybits == simdefs.DOOR_KEYS.OFFICE then
		return false, STRINGS.UI.DOORS.OFFICE
	elseif exit.keybits == simdefs.DOOR_KEYS.SECURITY then
		return false, STRINGS.UI.DOORS.SECURITY, STRINGS.UI.DOORS.SECURITY_LONGDESC
	elseif exit.keybits == simdefs.DOOR_KEYS.VAULT then
		return false, STRINGS.UI.DOORS.VAULT, STRINGS.UI.DOORS.VAULT_LONGDESC
	elseif exit.keybits == simdefs.DOOR_KEYS.SPECIAL_EXIT then
		return false, STRINGS.UI.DOORS.SPECIAL_EXIT, STRINGS.UI.DOORS.SPECIAL_EXIT_LONGDESC
	elseif exit.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE then
		return false, STRINGS.UI.DOORS.INUSE		
	elseif exit.keybits == simdefs.DOOR_KEYS.GUARD then
		return false, STRINGS.UI.DOORS.GUARD
    elseif exit.keybits == simdefs.DOOR_KEYS.DISABLED then
        return false, STRINGS.UI.DOORS.DISABLED
	end
end

function _M.canModifyExit( unit, exitOp, cell, dir )
	local exit = cell.exits[ dir ]
	assert( exit and exit.door )

	if unit:getTraits().canUseDoor == false then
		return false, STRINGS.UI.DOORS.CANT_USE
	end

	if unit:getTraits().movingBody then
		return false, STRINGS.UI.DOORS.DROP_BODY
	end
	
	if not unit:canAct() then
		return false
	end

	if exit.keybits == simdefs.DOOR_KEYS.GUARD and unit:isPC() then
		return false, STRINGS.UI.DOORS.GUARD
 	end
	if exit.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE or exit.keybits == simdefs.DOOR_KEYS.ELEVATOR then		
		return false
	end

	if exitOp == simdefs.EXITOP_OPEN then
		if not exit.closed then
			return false, STRINGS.UI.DOORS.NOT_CLOSED
		elseif exit.locked then
			return getKeyReason(exit)
		end

	elseif exitOp == simdefs.EXITOP_CLOSE then
		if exit.closed then
			return false, STRINGS.UI.DOORS.NOT_OPEN
		elseif exit.locked then
			return false, STRINGS.UI.DOORS.BROKEN
		end

	elseif exitOp == simdefs.EXITOP_TOGGLE_DOOR then
		if exit.locked then
			return false, STRINGS.UI.DOORS.SECURITY
		end

	elseif exitOp == simdefs.EXITOP_BREAK_DOOR then
		if not exit.closed and exit.locked then
			return false, STRINGS.UI.DOORS.BROKEN
		elseif not exit.closed then
			return false, STRINGS.UI.DOORS.NOT_CLOSED
		elseif exit.keybits == simdefs.DOOR_KEYS.GUARD then
			return false, STRINGS.UI.DOORS.CANT_BREAK
		elseif exit.locked then
			return getKeyReason(exit)
		end

	elseif exitOp == simdefs.EXITOP_LOCK then
		if not exit.closed then
			return false, STRINGS.UI.DOORS.NOT_CLOSED
		elseif exit.locked then
			return false, STRINGS.UI.DOORS.ALREADY_LOCKED
		elseif exit.keybits == nil then
			return false, STRINGS.UI.DOORS.NOT_LOCKED
		elseif not _M.hasKey( unit, exit.keybits ) then
			return getKeyReason(exit)
		end

	elseif exitOp == simdefs.EXITOP_UNLOCK then
		if not exit.closed then
			return false, STRINGS.UI.DOORS.NOT_CLOSED
		elseif not exit.locked then
			return false, STRINGS.UI.DOORS.NOT_LOCKED
		elseif not _M.hasKey( unit, exit.keybits ) then
			return getKeyReason(exit)
		end

	elseif exitOp == simdefs.EXITOP_TOGGLE_LOCK then
		if not exit.closed then
			return false, STRINGS.UI.DOORS.NOT_CLOSED
		elseif exit.keybits == nil then
			return false, STRINGS.UI.DOORS.NOT_LOCKED
		elseif not _M.hasKey( unit, exit.keybits ) then
			return getKeyReason(exit)
		end

	elseif exitOp == simdefs.EXIT_DISARM then	
		if unit:getMP() < 3 then
			return false, "NOT ENOUGH AP"
		end
	end

	return true
end

function _M.getPeekWall(sim,unit,direction)
	local wallDir, side = nil, nil
	local cell = sim:getCell(unit:getLocation())
 
	local dir1 = direction +1
	local dir2 = direction -1

	if dir1 > 7 then
		dir1 = 0
	end


	-- corner booleans: can peek around the corner in two ways
	local e1, e2 , e3, e4 = false, false, false, false
	local p1, p2 = false, false

	e1 = cell.exits[dir2]
	if e1 then
		e2 = cell.exits[dir2].cell.exits[dir1]
		p1 = cell.exits[dir2].cell.impass > 0
	end
	p1 = p1 or not e1 or not e2

	e3 = cell.exits[dir1]
	if e3 then
		e4 = cell.exits[dir1].cell.exits[dir2]
		p2 = cell.exits[dir1].cell.impass > 0
	end
	p2 = p2 or not e3 or not e4

	if e1 and e2 and p2 then
		wallDir = dir1
		if wallDir == 6 or wallDir == 0 then
			side = "R"
		else 
			side = "L"
		end
	elseif e3 and e4 and p1 then
		wallDir = dir2
		if wallDir == 6 or wallDir == 0 then
			side = "L"
		else 
			side = "R"
		end
		
	end

	return wallDir, side
end


function _M.checkDynamicImpass(sim, cell)
	for i,unit in ipairs(cell.units) do
		if unit:getTraits().dynamicImpass then
			return true
		end
	end
    return false
end


function _M.checkIsWall( sim, cell, dir )
	if not cell.exits[ dir ] then
		return true
	elseif cell.exits[ dir ] and (cell.exits[ dir ].cell.sightblock or 0) > 0 then
		return true			
	else
		return false
	end		
end


function _M.checkIsCover( sim, cell, dir )
	if not cell.exits[ dir ] or (cell.exits[ dir ].door and cell.exits[ dir ].closed) or (cell.exits[ dir ].cell.cover or 0) > 0 then
		return true
	else
		return false
	end
end

function _M.checkIsDoor( sim, cell, dir )
	if cell.exits[ dir ] and cell.exits[ dir ].closed then
		return true
	else
		return false
	end
end

function _M.checkIsHalfWall( sim, cell, dir )
	if not cell.exits[ dir ] or (cell.exits[ dir ].cell.cover or 0) > 0 then
		if not _M.checkIsWall( sim, cell, dir ) then
			return true
		end
	end

	return false
end

function _M.checkIfNextToCover( sim, unit )
	if not unit:getTraits().walk or unit:getTraits().koTimer then
		local cell = sim:getCell( unit:getLocation() )
		if cell == nil then
			return false
		end

		return _M.checkIfCellNextToCover(sim, cell)
	end

	return false
end

function _M.checkIfCellNextToCover(sim, cell)
	for i, dir in ipairs(simdefs.DIR_SIDES) do
		if _M.checkIsCover( sim, cell, dir ) then
			return true
		end
	end
    return false
end

function _M.checkCover( sim, sourceUnit, targetX, targetY )
	local x0, y0 = sourceUnit:getLocation()
    if _M.checkCellCover( sim, x0, y0, targetX, targetY ) then
        return true
    end

    return false
end

function _M.checkCellCover( sim, x0, y0, x1, y1 )
	local targetCell = sim:getCell( x1, y1 )
	
    if math.abs(x1 - x0) + math.abs(y1 - y0) > 1 then
	    if _M.checkIsCover( sim, targetCell, simdefs.DIR_N ) and y0 > y1 then
		    return true
	    end
	    if _M.checkIsCover( sim, targetCell, simdefs.DIR_E ) and x0 > x1 then
		    return true
	    end	
	    if _M.checkIsCover( sim, targetCell, simdefs.DIR_S ) and y1 > y0 then
		    return true
	    end	
	    if _M.checkIsCover( sim, targetCell, simdefs.DIR_W ) and x1 > x0 then
		    return true
	    end
    end

	return false
end

function _M.agentShouldLean(sim, cell, dir )
	if not _M.checkIsWall(sim,cell,dir) then
		return false -- Need a wall in the lean direction obviously
	end
	local ldir, rdir = ( dir - 2 ) % simdefs.DIR_MAX, ( dir + 2 ) % simdefs.DIR_MAX

	if cell.exits[ldir] and not _M.checkIsWall(sim,cell.exits[ldir].cell, dir) then
		return true -- It's open to the left!
	end

	if cell.exits[rdir] and not _M.checkIsWall(sim,cell.exits[rdir].cell, dir) then
		return true -- It's open to the right!
	end

	return false
end


--
-- Calculates the chance of success of shooting from source to target, given accuracy.
-- This does *not* take into account any level geometery (walls), cover, or intervening units.

-- Returns one dmgt. for each shot type. dmgt. has 

function _M.calculateShotSuccess( sim, sourceUnit, targetUnit, equipped )
	if not equipped then
		return nil -- A shot with no weapon is no shot at all.
	end
	 	
	local shot =
	{
		damage = equipped:getTraits().baseDamage or 1,
		ko = equipped:getTraits().canSleep,
		noTargetAlert = equipped:getTraits().noTargetAlert
	}
	
    if equipped:getTraits().canTag then
        -- Ignore armor calculation if it is a tagging weapon.
    else
	    local armor = 0
	    for i,childUnit in ipairs(targetUnit:getChildren()) do 
		    if childUnit:getTraits().armor and childUnit:getTraits().armor > armor then 
			    armor = childUnit:getTraits().armor 
		    end
	    end

	    if targetUnit:getArmor() then
		    armor = armor + targetUnit:getArmor()
	    end

	    armor = math.max( 0, armor - sourceUnit:countArmorPiercingUpgrades("addArmorPiercingRanged") )

	    if shot.ko then
	    	shot.damage = targetUnit:processKOresist( shot.damage )	
	    end

	    --OTK system
	    shot.armorBlocked = false 
	    local armorPiercing = equipped:getTraits().armorPiercing or 0
	    if armor > armorPiercing then 
		    shot.armorBlocked = true 
	    end
    end

	return shot
end

function _M.calculateMeleeDamage(sim, sourceUnit, targetUnit)
	if not sourceUnit then
		return 0
	end

	local meleeDamage, armorPiercing = 0, 0
    local unitOwner = sourceUnit:getUnitOwner()

    -- Take into account the weapon OWNER first.
	if _M.isAgent( unitOwner ) then
		meleeDamage = meleeDamage + (unitOwner:getTraits().meleeDamage or 0)
        armorPiercing = armorPiercing + unitOwner:countArmorPiercingUpgrades("addArmorPiercingMelee") 

        -- KINETIC CAPACITOR
        if unitOwner:getTraits().kinetic_capacitor_bonus and not unitOwner:getTraits().sneaking and not unitOwner:getTraits().walking then
        	armorPiercing = armorPiercing + unitOwner:getTraits().kinetic_capacitor_bonus
        	meleeDamage = meleeDamage + unitOwner:getTraits().kinetic_capacitor_bonus
        end
	end
    -- Take into account the WEAPON.
	meleeDamage = meleeDamage + (sourceUnit:getTraits().damage or 0)
    armorPiercing = armorPiercing + (sourceUnit:getTraits().armorPiercing or 0)

    -- Take into account if the unit has a melee damage bonus from their augment
	if _M.isAgent( unitOwner ) and unitOwner:countAugments( "augment_sharp_1" ) > 0 then    
    	local augmentCount = unitOwner:getAugmentCount()
		meleeDamage = meleeDamage + math.floor( augmentCount / 3 )    	
	end

    -- Take into account if the unit has a melee damage bonus from their augment
	if _M.isAgent( unitOwner ) and unitOwner:countAugments( "augment_sharp_2" ) > 0 then    
    	local augmentCount = unitOwner:getAugmentCount()
		armorPiercing = armorPiercing + math.floor( augmentCount / 3 )    	
	end


    if sim then
        -- TODO: somehow need to correctly calculate this for tooltips outside the sim (eg. team preview)
   	    meleeDamage = meleeDamage + sim:getParams().difficultyOptions.koDuration 
    end

    -- Take into account the TARGET.
	if targetUnit then
		if sourceUnit:getTraits().lethalMelee then
			meleeDamage = 1
		else
    		meleeDamage = targetUnit:processKOresist( meleeDamage )
		end

		local armor = targetUnit:getArmor()
		
        if (armor or 0) - armorPiercing > 0 then
            meleeDamage = 0 -- Having armor nullifies damage.
        end
	end

	return meleeDamage
end

function _M.getMoveSoundRange( unit, cell )
	local range = 0
	if not unit:getTraits().sneaking then             
		range = unit:getTraits().dashSoundRange
	else
		range = simdefs.SOUND_RANGE_0
	end
	return range + (cell.noiseRadius or 0)	
end

function _M.floodFill( sim, unit, start_cell, range, costFn, pathFn , maxRangeOnly, cellquery )

	local open_list = { [start_cell.id] = range }
	local close_list = {}
	costFn = costFn or _M.getMoveCost
	pathFn = pathFn or _M.canPath
    if cellquery == nil then
	    if unit and unit:getPlayerOwner() then
		    cellquery = unit:getPlayerOwner()
        else
            cellquery = sim
	    end
    end

	while not util.tempty(open_list) do
		local cellid, cost = next( open_list )
		local cell = sim:getCellByID( cellid )
		open_list[cell.id] = nil
		close_list[cell.id] = cost

		for dx = -1,1 do
			for dy = -1,1 do
				local target_cell = cellquery:getCell( cell.x + dx, cell.y + dy )
				if target_cell then
					local target_cost = cost - costFn( cell, target_cell )

					if target_cost >= 0 and target_cell ~= cell and pathFn( cellquery, unit, cell, target_cell ) then
						if open_list[target_cell.id] ~= nil then
							open_list[target_cell.id] = math.max( open_list[target_cell.id], target_cost )
						else
							-- see if its in the closed list already
							if close_list[target_cell.id] == nil then
								open_list[target_cell.id] = target_cost
							elseif close_list[target_cell.id] < target_cost then
								close_list[target_cell.id] = nil
								open_list[target_cell.id] = target_cost
							end
						end
					end
				end
			end
		end
	end

	local cells = {}
	for cellid,cost in pairs(close_list) do
		if not maxRangeOnly or cost <= 1 then
			table.insert( cells, sim:getCellByID( cellid ) )
		end
	end
	return cells
end


function _M.fillCircle( sim, xOrigin, yOrigin, rangeMax, rangeMin )
	local cells = {}
	local x0 = math.min((xOrigin - rangeMax), 0)
	local y0 = math.min((yOrigin - rangeMax), 0)  
	local x1 = xOrigin + rangeMax
	local y1 = yOrigin + rangeMax

	for x = x0, x1 do 
		for y = y0, y1 do
			local distance = math.floor( mathutil.dist2d( xOrigin, yOrigin, x, y ) )
			local cell = sim:getCell( x, y )
			if distance >= rangeMin and distance <= rangeMax and cell then
				table.insert( cells, sim:getCell( x, y ))
			end
		end
	end

	return cells
end

function _M.rasterCircle( sim, xOrigin, yOrigin, rangeMax )
	local cells = {}
	local x0 = math.min((xOrigin - rangeMax), 0)
	local y0 = math.min((yOrigin - rangeMax), 0)  
	local x1 = xOrigin + rangeMax
	local y1 = yOrigin + rangeMax

	for x = x0, x1 do 
		for y = y0, y1 do
			local distance = mathutil.dist2d( xOrigin, yOrigin, x, y )
			if distance <= rangeMax then
				table.insert( cells, x )
				table.insert( cells, y )
			end
		end
	end

	return cells
end

function _M.calculateCentroid( sim, units )
	local totalViz = {}
	for i, unit in pairs( units ) do
		local vizCells = {}
		sim:getLOS():getVizCells( unit:getID(), vizCells )
		for i = 1, #vizCells, 2 do
			local cellID = _M.toCellID( vizCells[i], vizCells[i+1] )
			if array.find( totalViz, cellID ) == nil then
				table.insert( totalViz, cellID )
			end
		end
	end
	if #totalViz > 0 then
		local avgx, avgy = 0, 0
		for i, cellID in ipairs(totalViz) do
			local x, y = _M.fromCellID( cellID )
			avgx, avgy = avgx + x, avgy + y
		end
		avgx, avgy = avgx / #totalViz, avgy / #totalViz
		return avgx, avgy
	end
end

-- How many agents are still in the field, and how many are escaping?
-- Note these are mutually exclusive lists.
function _M.countFieldAgents( sim )
    local fieldUnits, escapingUnits = {}, {}
    for _, unit in pairs( sim:getPC():getUnits() ) do
        if unit:hasAbility( "escape" ) then
            local cell = sim:getCell( unit:getLocation() )
            if cell and cell.exitID then
                table.insert( escapingUnits, unit )
            else
                table.insert( fieldUnits, unit )
            end
        end
    end
    return fieldUnits, escapingUnits
end

-- How many deployable units are in the field?
function _M.countDeployedUnits( sim )
    local deployedUnits = {}
    for _, unit in pairs( sim:getPC():getUnits() ) do
        if unit:hasAbility( "deployable" ) or unit:getTraits().deployable then
            table.insert( deployedUnits, unit )
        end
    end
    return deployedUnits
end

return _M

