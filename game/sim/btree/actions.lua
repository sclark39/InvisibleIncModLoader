local abilitydefs = include( "sim/abilitydefs" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local btree = include("sim/btree/btree")
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local abilitydefs = include( "sim/abilitydefs" )
local speechdefs = include( "sim/speechdefs" )
local inventory = include("sim/inventory")

local function checkForDeployedItem(unit)
	local cell = unit:getSim():getCell(unit:getLocation() )

	local units = {}
		for i,checkUnit in ipairs(cell.units) do
			if checkUnit ~= unit and checkUnit:getTraits().deployed and inventory.canCarry(unit, checkUnit) then
				table.insert(units,checkUnit)
			end
		end
	return units
end

local function doTrackerAlert(sim, unit)
    if unit:getTraits().trackerAlert then
        local tracker, text, x0, y0 = unpack( unit:getTraits().trackerAlert )
		sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat( STRINGS.UI.ALARM_ADD, tracker ),x=x0,y=y0,color={r=255/255,g=10/255,b=10/255,a=1}} )
		sim:trackerAdvance( tracker, text )
        unit:getTraits().trackerAlert = nil
    end

end

local Actions = {}

--[[
Actions are the nodes of a behaviour tree that make changes in the world. There are two types:

Simple actions use the btree.Action class to create a node that has a function to call when the
action should happen. They are just functions that get passed a sim, the current unit and the current
memory and can then do something with it. Action functions should return what behaviour state they are
in: BSTATE_COMPLETE if the action happens successfully, BSTATE_FAILED if the action could not be completed
, BSTATE_WAITING if the action should be tried again later and BSTATE_RUNNING if the action should be called again immediately.

Class actions are classes based on the btree.BaseAction class. They can define onInitialise, update and 
onTerminate functions, and save their own state.

Generally, it's preferable to save state in the persistent memory that inside the action itself, and so
simple actions should be used most of the time
]]--

--Simple Actions
function Actions.MeleeTarget(sim, unit)  
	if not unit:getBrain():getTarget() then
		return simdefs.BSTATE_FAILED
	end

	local abilityDef = unit:ownsAbility( "melee" )
	if unit:canUseAbility( sim, abilityDef, unit, unit:getBrain():getTarget():getID() ) then
		abilityDef:executeAbility( sim, unit, unit, unit:getBrain():getTarget():getID() )
		return simdefs.BSTATE_COMPLETE
	end
end

function Actions.ShootAtTarget(sim, unit)
	if not unit:getBrain():getTarget() then
		return simdefs.BSTATE_FAILED
	end
	local target = unit:getBrain():getTarget()	--we should only have the target if we can see them
	local canShoot = unit:canReact() or unit:getBrain():getSenses():hasLostTarget(target) --if they run into cover and then back out, they need to get shot
	if canShoot and unit:isAiming() and target:isValid() then
    	local abilityDef = unit:ownsAbility( "shootSingle" )
        if abilityDef and abilityDef:canUseAbility( sim, unit, unit, target:getID() ) then
		    abilityDef:executeAbility( sim, unit, unit, target:getID() )
		    --This could result in getting overwatch shot in return
		    if not unit:isValid() then
		    	return simdefs.BSTATE_FAILED
		    end
		    if target:isDead() or target:isKO() or not target:isValid() then
				if target:getTraits().mainframe_turret then
					unit:getSim():emitSpeech( unit, speechdefs.COMBAT_TURRETDESTROYED )
				else
					unit:getSim():emitSpeech( unit, speechdefs.COMBAT_TARGETDESTROYED )
				end
		    end
		    return simdefs.BSTATE_COMPLETE
        end
	else
		if not unit:isAiming() then
			local abilityDef = unit:ownsAbility("overwatch")
			if abilityDef then
				abilityDef:executeAbility(sim, unit, unit, target:getID())
				doTrackerAlert(sim, unit)
				if sim:getCurrentPlayer() == unit:getPlayerOwner() then
					return simdefs.BSTATE_WAITINGFORPCTURN
				end
			end
		end
	end
    return simdefs.BSTATE_WAITINGFORCORPTURN
end

function Actions.MarkInterestInvestigated(sim, unit)
	if not unit:getBrain():getInterest() then
		return simdefs.BSTATE_FAILED
	end	
	sim:dispatchEvent( simdefs.EV_UNIT_DEL_INTEREST, {unit = unit, interest = unit:getBrain():getInterest()} )

	if unit:getBrain():getSituation().ClassType == simdefs.SITUATION_HUNT then
		unit:getBrain():getSituation():markHuntTargetSearched(unit)
	elseif unit:getBrain():getSituation().ClassType == simdefs.SITUATION_INVESTIGATE then
		unit:getBrain():getSituation():markInterestInvestigated(unit)
	end

	local units = checkForDeployedItem(unit)

	if #units > 0 then

		local pickedUpUnit
		local destroyedUnit = false
		for i,pickUpUnit in ipairs(units) do
			local abilityDef = pickUpUnit:ownsAbility( "carryable" )
	        if abilityDef and abilityDef:canUseAbility( sim, pickUpUnit, unit) then	        
			    abilityDef:executeAbility( sim, pickUpUnit, unit )
			    pickedUpUnit = pickUpUnit	
	     	elseif unit:getTraits().isDrone then
				sim:warpUnit( pickUpUnit )
				sim:despawnUnit( pickUpUnit )
				destroyedUnit = true
	     	end
    	end	
    	if destroyedUnit then
			local params = {color ={{symbol="inner_line",r=1,g=0,b=0,a=0.75},{symbol="wall_digital",r=1,g=0,b=0,a=0.75},{symbol="boxy_tail",r=1,g=0,b=0,a=0.75},{symbol="boxy",r=1,g=0,b=0,a=0.75}} }
			sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = unit, kanim = "fx/emp_effect", symbol = "character", anim="idle", above=true, params=params} )
			local x1, y1 = unit:getLocation()
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/HitResponse/hitby_tazer_flesh", x=x1,y=y1} )				    		
    	end
    end

	return simdefs.BSTATE_COMPLETE
end

function Actions.RemoveInterest(sim, unit)
	if not unit:getBrain():getInterest() then
		return simdefs.BSTATE_FAILED
	end

	sim:dispatchEvent( simdefs.EV_UNIT_DEL_INTEREST, {unit = unit, interest = unit:getBrain():getInterest()} )
	sim:triggerEvent( simdefs.TRG_DEL_INTEREST, {unit = unit, interest = unit:getBrain():getInterest()} )

	return simdefs.BSTATE_COMPLETE
end

function Actions.FinishSearch(sim, unit)
	sim:emitSpeech(unit, speechdefs.INVESTIGATE_FINISH )
	sim:dispatchEvent( simdefs.EV_UNIT_DONESEARCHING, {unit = unit} )

	return simdefs.BSTATE_COMPLETE
end

local function checkLookaround( sim, unit, delta )
    local x0, y0 = unit:getLocation()
    local dir = unit:getFacing()
    local probeCells = {}
    if unit:getTraits().no_look_around then
    	-- reserved for units that don't peek or drone scan
    elseif unit:getTraits().lookaroundRange then
		local fillCells = simquery.fillCircle( sim, x0, y0, unit:getTraits().lookaroundRange, 0)

		for i, cell in ipairs(fillCells) do
			if cell.x ~= x0 or cell.y ~= y0 then
				local raycastX, raycastY = sim:getLOS():raycast(x0, y0, cell.x, cell.y)
				if raycastX == cell.x and raycastY == cell.y then
					table.insert(probeCells, cell)
				end
			end
		end
	else
		local cell = sim:getCell( x0, y0 )
	    if (dir % 2) == 0 then
	        local dx, dy = simquery.getDeltaFromDirection( dir )
	        local facing = (dir + delta*2) % simdefs.DIR_MAX
	        if simquery.isOpenExit( cell.exits[ dir ] ) then
	        	-- If possible, probe orthogonally to our current facing.
		        probeCells = sim:getLOS():probeLOS( x0 + dx, y0 + dy, facing, unit:getTraits().LOSrange )
		    end
	        if #probeCells == 0 and simquery.isOpenExit( cell.exits[ facing ] ) then
	        	-- If you can't probe that way, probe a cell over down the axis of our actual facing.
	            local dx, dy = simquery.getDeltaFromDirection( facing )
	            probeCells = sim:getLOS():probeLOS( x0 + dx, y0 + dy, dir, unit:getTraits().LOSrange )
	        end
	    else
	    	-- On a diagonal, probe a cell in front down the cardinal axis to the left/right
	        local dx, dy = simquery.getDeltaFromDirection( dir )
	        if simquery.isConnected( sim, cell, sim:getCell( x0 + dx, y0 + dy )) then
		        local facing = (dir + delta) % simdefs.DIR_MAX
		        probeCells = sim:getLOS():probeLOS( x0 + dx, y0 + dy, facing, unit:getTraits().LOSrange )
		    end
	    end
    end

    for i, cell in ipairs(probeCells) do
        for j, targetUnit in ipairs(cell.units) do
		    if simquery.isEnemyAgent(unit:getPlayerOwner(), targetUnit) and simquery.couldUnitSee(sim, unit, targetUnit, true) then
			    if not sim:canUnitSeeUnit(unit, targetUnit) then
				    unit:getBrain():getSenses():addInterest(cell.x, cell.y, simdefs.SENSE_PERIPHERAL, simdefs.REASON_NOTICED, targetUnit)
			    end
            end
        end
    end
    return probeCells
end

local function overrideUnitLOS(sim, unit, facingRad, losArc, delta )
    local oldRads = unit:getTraits().LOSrads
    local oldArc = unit:getTraits().LOSarc
    local oldPeripheralArc = unit:getTraits().LOSperipheralArc
    local oldRange = unit:getTraits().LOSrange

    unit:getTraits().LOSrads = facingRad
    unit:getTraits().LOSarc = losArc
    unit:getTraits().LOSperipheralArc = nil

    sim:refreshUnitLOS( unit )
    checkLookaround( sim, unit, delta )
	sim:processReactions(unit)

    unit:getTraits().LOSrads = oldRads
    unit:getTraits().LOSarc = oldArc
    unit:getTraits().LOSperipheralArc = oldPeripheralArc
end

function Actions.DoLookAround(sim, unit )
	local cell = sim:getCell(unit:getLocation())
	local exitDir = unit:getFacing()
	local exit = cell.exits[exitDir]
	if exit and exit.door and exit.closed and not exit.locked then
		sim:modifyExit(cell, exitDir, simdefs.EXITOP_OPEN, unit)		
	end

	if unit:isValid() and not unit:isKO() and not unit:getTraits().no_look_around then
		if unit:isAlerted() then
			sim:emitSpeech( unit, speechdefs.HUNT_SEARCH )
		else
			sim:emitSpeech( unit, speechdefs.INVESTIGATE_SEARCH )
		end

		unit:setAiming( false )
		unit:getTraits().lookingAround = true

		if unit:getTraits().lookaroundRange then
			local cells = checkLookaround( sim, unit )
			if #cells > 0 then
				sim:dispatchEvent( simdefs.EV_UNIT_LOOKAROUND, { unit = unit, part="scan", cells=cells} )
			end
			sim:processReactions(unit)
		else
	        -- Quarter circle, minus half the default guard's LOS arc, so that its edge aligns with 180.
	        local FACING_OFFSET = unit:getTraits().lookaroundOffset or (math.pi/4 - math.pi/16)
	        local lookaroundArc = unit:getTraits().lookaroundArc or (math.pi/2 + math.pi/8)
			local dir = unit:getFacing()

			sim:dispatchEvent( simdefs.EV_UNIT_LOOKAROUND, { unit = unit, part="right" } )
			overrideUnitLOS( sim, unit, unit:getFacingRad() - FACING_OFFSET, lookaroundArc, -1)

			if unit:isValid() and not unit:getTraits().interrupted then
				sim:dispatchEvent( simdefs.EV_UNIT_LOOKAROUND, { unit = unit, part="right_post" } )
		    end

			if unit:isValid() and not unit:getTraits().interrupted then
				sim:dispatchEvent( simdefs.EV_UNIT_LOOKAROUND, { unit = unit, part="left" } )
				overrideUnitLOS( sim, unit, unit:getFacingRad() + FACING_OFFSET, lookaroundArc, 1)
			end

			if unit:isValid() then
	            if not unit:getTraits().interrupted then
	    			sim:dispatchEvent( simdefs.EV_UNIT_LOOKAROUND, { unit = unit, part="left_post" } )
					sim:dispatchEvent( simdefs.EV_UNIT_LOOKAROUND, { unit = unit, part="post" } )
				end
				sim:refreshUnitLOS(unit) --return to normal LOS
	            if not unit:getTraits().interrupted then
	    			sim:processReactions(unit)
	    		end
			end
		end

		unit:getTraits().lookingAround = nil
		if unit:getTraits().interrupted then
            -- ccc: don't want to walk any further if we saw something, so consume all MP.
            --- (but shouldn't there a way to prevent further behaviours just by returning the correct BSTATE_FAILED?)
            if unit:isValid() then
                unit:useMP( unit:getMP(), sim )
            end
			return simdefs.BSTATE_FAILED
		end
		return simdefs.BSTATE_COMPLETE
	end
end

function Actions.ReactToTarget(sim, unit)
	local target = unit:getBrain():getTarget()
	if not target or not target:isValid() then
		return simdefs.BSTATE_FAILED
	end

	local x0,y0 = unit:getLocation()
	local x1,y1 = target:getLocation()

	if not x1 or not y1 then --it's possible our target is in someone's inventory
		return simdefs.BSTATE_FAILED
	end

	unit:turnToFace(x1, y1)
	--turning could change our target
	target = unit:getBrain():getTarget()
	if unit:isValid() and target and target:isValid() and target:getLocation() and unit:getTraits().camera_drone then 
		sim:dispatchEvent( simdefs.EV_UNIT_ALERTED, { unitID = unit:getID() } )
		sim:triggerEvent( simdefs.TRG_NEW_INTEREST, { x=x0, y=y0, range=0, target=target, interest={x=x1, y=y1, sourceUnit=unit} })
		target:interruptMove(sim, unit)
	elseif unit:isValid() and target and target:isValid() and target:getLocation() then
		sim:dispatchEvent( simdefs.EV_UNIT_ALERTED, { unitID = unit:getID() } )
		if target:getTraits().mainframe_turret then
			unit:getSim():emitSpeech( unit, speechdefs.COMBAT_NEWTURRET )
		else
			unit:getSim():emitSpeech( unit, speechdefs.COMBAT_NEWTARGET )
		end
		sim:triggerEvent( simdefs.TRG_NEW_INTEREST, { x=x0, y=y0, range=simdefs.SOUND_RANGE_2, target=target, interest={x=x1, y=y1, sourceUnit=unit} })
		target:interruptMove(sim, unit)
		sim:dispatchEvent( simdefs.EV_UNIT_ENGAGED, unit )
	end


	return simdefs.BSTATE_COMPLETE
end

function Actions.WatchTarget(sim, unit)
	if not unit:getBrain():getTarget() then
		return simdefs.BSTATE_FAILED
	end

	local x1,y1 = unit:getBrain():getTarget():getLocation()
	unit:turnToFace(x1, y1)

	doTrackerAlert(sim, unit)

	if not unit:canReact() then
		return simdefs.BSTATE_WAITINGFORCORPTURN
	end

	return simdefs.BSTATE_COMPLETE
end

function Actions.MarkHuntTargetSearched(sim, unit)
	if unit:getBrain():getSituation().ClassType ~= simdefs.SITUATION_HUNT then
		return simdefs.BSTATE_FAILED
	end

	sim:dispatchEvent( simdefs.EV_UNIT_DEL_INTEREST, {unit = unit, interest = unit:getBrain():getInterest()} )
	sim:triggerEvent( simdefs.TRG_DEL_INTEREST, {unit = unit, interest = unit:getBrain():getInterest()} )
	unit:getBrain():getSituation():markHuntTargetSearched(unit)

	return simdefs.BSTATE_COMPLETE
end

function Actions.RequestNewHuntTarget(sim, unit)
	if unit:getBrain():getSituation().ClassType ~= simdefs.SITUATION_HUNT then
		return simdefs.BSTATE_FAILED
	end

	local rememberedInterest = unit:getBrain():getSenses():getRememberedInterest()
	if rememberedInterest then
		unit:getBrain():getSituation():overrideHuntTarget(unit, rememberedInterest)
	else
		unit:getBrain():getSituation():requestNewHuntTarget(unit)
	end

	return simdefs.BSTATE_COMPLETE
end

function Actions.ReactToInterest(sim, unit)
	local interest = unit:getBrain():getInterest()
	if not interest then
		return simdefs.BSTATE_FAILED
	end

	if interest.noticed then	--we already reacted!
		return simdefs.BSTATE_COMPLETE
	end

	sim:dispatchEvent( simdefs.EV_UNIT_ALERTED, { unitID = unit:getID() } )

	if interest.reason == simdefs.REASON_WITNESS then
		if not interest.sourceUnit:getPlayerOwner() or interest.sourceUnit:getPlayerOwner() == unit:getPlayerOwner() then
			unit:getSim():emitSpeech( unit, speechdefs.HUNT_SAW )
		end
	elseif interest.reason == simdefs.REASON_KO then
		--no need for speech, they already spoke when they woke up		
	elseif interest.reason == simdefs.REASON_PATROLCHANGED then
		--no need to say anything, Central talks about it
	elseif interest.reason == simdefs.REASON_REINFORCEMENTS then
		if unit:isAlerted() then
			unit:getSim():emitSpeech( unit, speechdefs.HUNT_REINFORCEMENT )
		else
			unit:getSim():emitSpeech( unit, speechdefs.INVESTIGATE_REINFORCEMENT )
		end
	elseif interest.reason == simdefs.REASON_NOISE then
		if unit:isAlerted() then
			unit:getSim():emitSpeech( unit, speechdefs.HUNT_NOISE)
		else
			unit:getSim():emitSpeech( unit, speechdefs.INVESTIGATE_NOISE )
		end
	elseif interest.reason == simdefs.REASON_FOUNDCORPSE then
		if interest.sourceUnit:getPlayerOwner() and interest.sourceUnit:getPlayerOwner() ~= unit:getPlayerOwner() then
			if interest.sourceUnit:getTraits().mainframe_turret then
				unit:getSim():emitSpeech( unit, speechdefs.COMBAT_TURRETDESTROYED )
			else
				unit:getSim():emitSpeech( unit, speechdefs.COMBAT_TARGETDESTROYED )
			end
			if unit:isAiming() then
				unit:setAiming(false)
				unit:getSim():dispatchEvent(simdefs.EV_UNIT_OVERWATCH, { cancel=true, unit = unit} )
			end
		else
			if interest.sourceUnit:getTraits().wasDrone then
				unit:getSim():emitSpeech( unit, speechdefs.HUNT_DRONE)
			else
				unit:getSim():emitSpeech( unit, speechdefs.HUNT_CORPSE )
			end
		end
	elseif interest.reason == simdefs.REASON_FOUNDDRONE then
		if unit:isAlerted() then
			unit:getSim():emitSpeech( unit, speechdefs.HUNT_DRONE)
		else
			unit:getSim():emitSpeech( unit, speechdefs.INVESTIGATE_DRONE)
		end
	elseif interest.reason == simdefs.REASON_DOOR then
		if unit:isAlerted() then
			unit:getSim():emitSpeech( unit, speechdefs.HUNT_SAW)
		else
			unit:getSim():emitSpeech( unit, speechdefs.INVESTIGATE_SAW )
		end
	elseif interest.reason == simdefs.REASON_LOSTTARGET then
		--a bit of wizardry! Guards will magically know if a target is down and not say anything
		if not interest.sourceUnit:isKO() and not  interest.sourceUnit:isDead() then
			unit:getSim():emitSpeech( unit, speechdefs.HUNT_LOSTTARGET )
		end
	elseif interest.reason == simdefs.REASON_FOUNDOBJECT or interest.reason == simdefs.REASON_SMOKE then
		unit:getSim():emitSpeech( unit, speechdefs.HUNT_FOUNDOBJECT)
	else 	--generic
		if unit:isAlerted() then
			unit:getSim():emitSpeech( unit, speechdefs.HUNT_GENERIC )
		else
			unit:getSim():emitSpeech( unit, speechdefs.INVESTIGATE_GENERIC )
		end
	end

	if unit:canReact() then
		unit:turnToFace(interest.x, interest.y)
	end

	interest.noticed = true

	doTrackerAlert(sim, unit)

	return simdefs.BSTATE_COMPLETE
end

function Actions.FaceNextPatrolPoint(sim, unit)
	local patrolPoint = unit:getBrain():getPatrolPoint()
	if patrolPoint then
		unit:turnToFace(patrolPoint.x, patrolPoint.y)
		return simdefs.BSTATE_COMPLETE
	end
end

function Actions.Panic(sim, unit)
	sim:dispatchEvent( simdefs.EV_UNIT_ALERTED, { unitID = unit:getID() } )

	if unit:getBrain():getTarget() then
		unit:getSim():emitSpeech( unit, speechdefs.FLEE_STARTLED )
	elseif unit:getBrain():getInterest() and not unit:getBrain():getInterest().noticed then
		unit:getSim():emitSpeech( unit, speechdefs.FLEE_PANIC )
		unit:getBrain():getInterest().noticed = true
	end

	sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )

	doTrackerAlert(sim, unit)

	return simdefs.BSTATE_COMPLETE
end

function Actions.Cower(sim, unit)

	unit:getSim():emitSpeech( unit, speechdefs.FLEE_COWER )

	if unit:getBrain():getInterest() then
		unit:getBrain():getInterest().investigated = true
	end

	return simdefs.BSTATE_COMPLETE
end

function Actions.ExitLevel(sim, unit)

	local cell = sim:getCell(unit:getLocation() )
	if not cell then
		return simdefs.BSTATE_FAILED
	end

	if not simquery.cellHasTag(sim, cell, "guard_spawn") then
		return simdefs.BSTATE_FAILED
	end

	if unit:getTraits().vip then
		local units = {unit}
		sim:dispatchEvent( simdefs.EV_TELEPORT, { units=units, warpOut =true } )
		sim:triggerEvent( "vip_escaped" )
	end

	sim:warpUnit( unit, nil )
	sim:despawnUnit( unit )
	return simdefs.BSTATE_COMPLETE
end


--------------------------------------------------------------------------------------------------------------------
-- Class actions

-------------------------------------------------------------------------------------------------
Actions.UseAbility = class(btree.BaseAction, function(self, abilityID)
	local abilityDef = abilitydefs.lookupAbility( abilityID )
	local name = abilityDef and abilityDef.name
	if name then
		--some actions have an unnecessary addition to them
		name = name:gsub("\nACTION", "")
	end
	btree.BaseAction.init(self, name or "Unknown Ability")
	self.ability = abilityID
end)

function Actions.UseAbility:update()
	local abilityDef = self.unit:hasAbility( self.ability )
	if abilityDef and self.unit:canUseAbility( self.sim, abilityDef, self.unit ) then
		abilityDef:executeAbility( self.sim, self.unit, self.unit )
		return simdefs.BSTATE_COMPLETE
	end
	return simdefs.BSTATE_FAILED
end

------------------------------------------------------------------------------------------------------

Actions.MoveTo = class(btree.BaseAction, function(self, name)
	btree.BaseAction.init(self, name or "Base Move Action")
end)


function Actions.MoveTo:calculatePath(unit)
	unit:getPather():calculatePath(unit)
	local path = unit:getPather():getPath(unit)
	if path and path.path then
		if unit:getTraits().dynamicImpass then
			unit:getPather():reservePath(path)
		end
	else
		if self.onNoPath then
			return self:onNoPath()
		end
	end
	unit:getSim():dispatchEvent( simdefs.EV_UNIT_GOALS_UPDATED, {unitID = unit:getID()} )
	return simdefs.BSTATE_RUNNING
end

function Actions.MoveTo:executePath(unit)
	local path = unit:getPather():getPath(unit)
	if not path then
		return simdefs.BSTATE_FAILED
	end
	if not path.path then
		return simdefs.BSTATE_WAITING
	end

	simlog(simdefs.LOG_PATH, "(%d) - Executing Path", unit:getID() )
	local sim = unit:getSim()

	path.iter = path.iter + 1

	if not unit or not unit:isValid() or unit:isKO() or unit:isDead() then
		-- Unit must have perished during path execution.
		path.result = simdefs.CANMOVE_FAILED
	elseif path.result then
		-- Path already has a result, fuck it.  Probably failed early.
		-- ccc: this clause is dumb, why is there a path.result and yet we are in the processing list?  Should be mutually exclusive.
		-- Currently it's because of the else clause of 'if #moveTable > 0'
		assert( false, string.format( "[%d] PATH has result %s", unit:getID(), path.result ))
	elseif path.iter > 10 then
		log:write("%d] PATH - bailing; not complete after %d iterations", unit:getID(), path.iter)
		path.result = simdefs.CANMOVE_FAILED
		unit:getPather():unreservePath(path)
	else
		local x0, y0 = unit:getLocation()
		local nodes = path.path:getNodes()
		local actions = path.actions
		--simlog( simdefs.LOG_PATH, "%d] EXECUTE PATH from (%d, %d) -> (%d, %d) [%d nodes]", unit:getID(), x0, y0, path.goalx, path.goaly, #nodes )

		-- Assume success; if an error occurs, path.result will be overwritten with the reason.
		path.result = simdefs.CANMOVE_OK
		local moveTable = {}
		local moveAction = nil

		assert( #nodes > 0 )
		while #nodes > 0 do
			local pathNode = table.remove( nodes, 1 )


			-- is already reserved at pathNode's location, but at a lower t? then wait
			if pathNode.location.x == path.currentNode.location.x and pathNode.location.y == path.currentNode.location.y then
				-- If this path node is a PAUSE (same location as the previous node) then don't bother checking for reservations,
				-- or we'll HALT on ourselves.
			else
				for i = 0, pathNode.t-1 do
					local reservation = unit:getPather():checkPathReservation(pathNode.location.x, pathNode.location.y, i)
					if reservation then
						--simlog( simdefs.LOG_PATH, "\tHALTING -- for reservation at (%d, %d, t = %d > %d)", pathNode.location.x, pathNode.location.y, pathNode.t, i )
						table.insert( nodes, 1, pathNode )
						path.result = nil -- Clear result, otherwise this path will bail on reprocessing.
						pathNode = nil
						break
					end
				end
			end

			if pathNode then
				local action = unit:getPather():getActionForNode(path, path.currentNode)
				if action then
					table.insert( nodes, 1, pathNode )
					path.actions[path.currentNode.lid] = nil
					moveAction = action
					if moveAction.keepPathing then
						path.result = nil
					end
					break
				end
				local prevx, prevy = x0, y0
				if #moveTable > 0 then
					prevx, prevy = moveTable[ #moveTable ].x, moveTable[ #moveTable ].y
				end
				if pathNode.location.x ~= prevx or pathNode.location.y ~= prevy then
					table.insert( moveTable, { x = pathNode.location.x, y = pathNode.location.y, lid = pathNode.lid } )
				end
				-- Unreserve the previous node immediately, even before we know whether the move can be completed.
				-- If the movement fails below, we still unreserve the entire path anyways (no point in keeping
				-- reservations we can't honor!)
				unit:getPather():unreserveNode(path, path.currentNode)
				path.currentNode = pathNode
			else
				break
			end
		end

		if #moveTable > 0 then
			if path.goaldir then
				moveTable[#moveTable].facing = path.goaldir
			end

			local canMoveReason, end_cell = sim:moveUnit( unit, moveTable)
			x0, y0 = unit:getLocation()

			if not unit:isValid() or unit:getPather():getPath(unit) ~= path then
				-- The movement resulted in this path being eradicated, so we literally care about nothing from here on out, and it has
				-- already been cleaned up.
				-- simlog("\tPATH [%d] REMOVED (aborting)", path.unit:getID() );
				return simdefs.BSTATE_FAILED

			elseif canMoveReason ~= simdefs.CANMOVE_OK then
				assert( canMoveReason )
				--simlog( simdefs.LOG_PATH, "\tFAIL: (%d, %d) -> (%d, %d) (reason = %s)", x0, y0, moveTable[ #moveTable ].x, moveTable[ #moveTable ].y, canMoveReason )
				path.result = canMoveReason

				-- Unreserve the rest of the nodes, if they're still valid
				unit:getPather():unreservePath(path)

				if canMoveReason == simdefs.CANMOVE_NOMP then	--ran out of MP
					return self:onPathNoMP()
                elseif canMoveReason == simdefs.CANMOVE_DYNAMIC_IMPASS then
                    -- Only continue behaviours if i was blocked by an enemy.  If I'm blocked by a friendly, presumably something has
                    -- gone wrong with co-op pathfinding and I need to stop.
                    local blocker = simquery.findUnit(end_cell.units, function( u ) return u:getTraits().dynamicImpass end)
                    if blocker then
						return self:onPathBlocked(blocker)
                    end
				end

				return simdefs.BSTATE_FAILED

			elseif #nodes == 0 then
				-- Consumed the entire path!
				-- Not necessarily at the FINAL goal, as we will return partial results (the cooperative astar has a bounded search depth).
				unit:getPather():unreserveNode(path, path.currentNode)
				path.currentNode = nil

				if moveAction then
			    	local abilityDef = abilitydefs.lookupAbility(moveAction.ability)
			        if abilityDef and abilityDef:canUseAbility( sim, moveAction.owner, moveAction.user, unpack(moveAction.params) ) then
			        	abilityDef:executeAbility(sim, moveAction.owner, moveAction.user, unpack(moveAction.params) )
		        	end
		        	if unit:getTraits().interrupted then
		        		return simdefs.BSTATE_FAILED
	        		end
		        	if not moveAction.keepPathing then
	        			return simdefs.BSTATE_WAITINGFORPCTURN
	        		end
				end
				if path.goalx == x0 and path.goaly == y0 then
					path.result = simdefs.CANMOVE_OK
					self.unit:getBrain():setDestination(nil)
					return simdefs.BSTATE_COMPLETE
				else
					path.result = simdefs.CANMOVE_PARTIAL_PATH
					return simdefs.BSTATE_WAITING
				end

			else
				if moveAction then
			    	local abilityDef = abilitydefs.lookupAbility(moveAction.ability)
			        if abilityDef and abilityDef:canUseAbility( sim, moveAction.owner, moveAction.user, unpack(moveAction.params) ) then
			        	abilityDef:executeAbility(sim, moveAction.owner, moveAction.user, unpack(moveAction.params) )
		        	end
		        	if unit:getTraits().interrupted then
		        		return simdefs.BSTATE_FAILED
	        		end
		        	if moveAction.keepPathing then
		        		return simdefs.BSTATE_RUNNING
	        		else
	        			return simdefs.BSTATE_WAITINGFORPCTURN
        			end
				end

				simlog( simdefs.LOG_PATH, "(%d) - waiting for path to clear", path.unit:getID(), path.result )
				-- Still have path to process.  This can only happen if we are waiting for a path reservation;
				-- Read ourselves for reprocessing (the blocking path should hopefully have processed itself and unreserved by then)
				return simdefs.BSTATE_WAITING
			end
		else
			if #nodes > 0 then
				if moveAction then
			    	local abilityDef = abilitydefs.lookupAbility(moveAction.ability)
			        if abilityDef and abilityDef:canUseAbility( sim, moveAction.owner, moveAction.user, unpack(moveAction.params) ) then
			        	abilityDef:executeAbility(sim, moveAction.owner, moveAction.user, unpack(moveAction.params) )
		        	end
		        	if unit:getTraits().interrupted then
		        		return simdefs.BSTATE_FAILED
	        		end
		        	if moveAction.keepPathing then
		        		return simdefs.BSTATE_RUNNING
	        		else
	        			--get rid of the rest of our path
                        path.result = simdefs.CANMOVE_PARTIAL_PATH
						unit:getPather():unreservePath(path)
	        			return simdefs.BSTATE_WAITINGFORPCTURN
	        		end
				end
				return simdefs.BSTATE_WAITING
			else
                assert( path.currentNode, unit:getID().."\n"..util.stringize(path, 3))
				unit:getPather():unreserveNode(path, path.currentNode)
				path.currentNode = nil
				self.unit:getBrain():setDestination(nil)
                if path.goaldir then
                    unit:updateFacing( path.goaldir )
			    end
				return simdefs.BSTATE_COMPLETE
			end
		end
	end

	return simdefs.BSTATE_FAILED
end

function Actions.MoveTo:shouldRecalculate()
	local path = self.unit:getPather():getPath(self.unit)
	local dest = self.unit:getBrain():getDestination()
	if path then
		if path.result ~= nil then
			simlog( simdefs.LOG_PATH, "(%d) - recalculating path with existing result (%s)", path.unit:getID(), path.result )
			return true
		end
		if dest and (path.goalx ~= dest.x or path.goaly ~= dest.y) then
			simlog( simdefs.LOG_PATH, "(%d) - recalculating path after destination changed", path.unit:getID(), path.result )
			return true
		end
		if path.path then
			local startNode = path.path:getStartNode()
			local currentNode = path.currentNode
			local x,y = self.unit:getLocation()
			if not (x == startNode.location.x and y == startNode.location.y) and not (x == currentNode.location.x and y == currentNode.location.y) then
				simlog( simdefs.LOG_PATH, "(%d) - recalculating path after starting location changed", path.unit:getID(), path.result )
				return true
			end
		end
	end
	return false
end

function Actions.MoveTo:onPathBlocked(blocker)
	local x0, y0 = self.unit:getLocation()
	local x1, y1 = blocker:getLocation()
	if simquery.isEnemyTarget(self.unit:getPlayerOwner(), blocker) then
		if mathutil.distSqr2d(x0, y0, x1, y1) <= 1 or not simquery.checkCover(self.unit:getSim(), self.unit, x1, y1) then
			self.unit:getBrain():getSenses():addInterest(x0, y0, simdefs.SENSE_PERIPHERAL, simdefs.REASON_NOTICED)
		end
		return simdefs.BSTATE_RUNNING -- Keep trying
	end
	return simdefs.BSTATE_FAILED
end

function Actions.MoveTo:onPathNoMP()
	return simdefs.BSTATE_WAITINGFORPCTURN
end

function Actions.MoveTo:update()
	if not self:isRunning() or self:shouldRecalculate() then
		self.status = simdefs.BSTATE_RUNNING
		if self.getDestination then
			local dest = self:getDestination(self.unit)
			if not dest then
				if self.onNoDestination then
					self.status = self:onNoDestination()
				else
					local x,y = self.unit:getLocation()	--by default we just try to path to where we're standing
					local facing = self.unit:getFacing()
					dest = {x=x, y=y, facing=facing}
				end
			end
			if dest then
				self.unit:getBrain():setDestination(dest)
				self.status = self:calculatePath(self.unit)
			end
		end
	end
	if self:isRunning() then
		if self.unit:canReact() then
			self.status = self:executePath(self.unit)
		else
			self.status = simdefs.BSTATE_WAITINGFORCORPTURN
		end
	end
	return self.status
end

function Actions.MoveTo:cancel()
	self.unit:interruptMove(self.unit:getSim() )
	self.unit:getBrain():setDestination(nil)
	--cancel our path
	self.unit:getPather():removePath(self.unit)
end

-----------------------------------------------------------------------------------------

Actions.MoveToTarget = class(Actions.MoveTo, function(self, name)
	btree.BaseAction.init(self, name or "MoveToTarget")
end)

function Actions.MoveToTarget:getDestination()
	local target = self.unit:getBrain():getTarget()
	local x, y = target:getLocation()
	local dest = { x = x, y = y, unit = target}
	return dest
end

-----------------------------------------------------------------------------------------

Actions.MoveBesideTarget = class(Actions.MoveTo, function(self, name)
	btree.BaseAction.init(self, name or "MoveBesideTarget")
end)

function Actions.MoveBesideTarget:getDestination()
	local target = self.unit:getBrain():getTarget()
	local x, y = target:getLocation()
	if simquery.canUnitReach(self.sim, self.unit, x, y) then	--already close enough
		return nil
	end

	local neighbour = simquery.findNearestEmptyReachableCell(self.sim, x, y, self.unit )
	if neighbour then
		local facing = simquery.getDirectionFromDelta(x - neighbour.x, y - neighbour.y)
		return {x = neighbour.x, y = neighbour.y, facing=facing, unit=target}
	end
end

-----------------------------------------------------------------------------------------

Actions.MoveToInterest = class(Actions.MoveTo, function(self, name)
	btree.BaseAction.init(self, name or "MoveToInterest")
end)

function Actions.MoveToInterest:getDestination()

	local interest = self.unit:getBrain():getInterest()
	local situation = self.unit:getBrain():getSituation()
	local path = self.unit:getPather():getPath(self.unit)
	if path and path.result == simdefs.CANMOVE_NOPATH and interest == self.unit:getBrain():getDestination() then
		if situation.ClassType == simdefs.SITUATION_HUNT then
			situation:requestNewHuntTarget(self.unit)
		end
		local x, y = self.unit:getLocation()
		return {x=x, y=y, reason="Could not path"}
	end
	return interest
end

function Actions.MoveToInterest:onPathBlocked(blocker)
	local interest = self.unit:getBrain():getInterest()
	if blocker:getPlayerOwner() == self.unit:getPlayerOwner() and self.unit:getBrain():getDestination() == interest then
		local x, y = self.unit:getLocation()
		local x1, y1 = blocker:getLocation()
		local sim = self.unit:getSim()
		if x1==interest.x and y1==interest.y and simquery.canPathBetween(sim, self.unit, sim:getCell(x,y), sim:getCell(x1,y1) ) then
			--close enough!
			self:cancel()
			return simdefs.BSTATE_COMPLETE
		end
		-- if interest.reason == simdef.REASON_FOUNDCORPSE and simquery.isEnemyAgent(self.unit:getPlayerOwner(), interest.sourceUnit)
		--  and (interest.sourceUnit:isDead() or interest.sourceUnit:getTraits().iscorpse or simquery.isUnitPinned(sim, interest.sourceUnit)
		if interest.sourceUnit and sim:canUnitSeeUnit(self.unit, interest.sourceUnit) then
			--also close enough!
			self:cancel()
			return simdefs.BSTATE_COMPLETE
		end
	end
	return Actions.MoveTo.onPathBlocked(self, blocker)
end

function Actions.MoveToInterest:onPathNoMP()
	local interest = self.unit:getBrain():getInterest()
	local x0, y0 = self.unit:getLocation()
	if interest and self.unit:isAlerted() and (interest.x ~= x0 or interest.y ~= y0) then
		local interestCell = self.unit:getSim():getCell(interest.x, interest.y)
		local dir = simquery.getDirectionFromDelta(interest.x - x0, interest.y - y0)
		if interestCell and self.unit:getFacing() ~= dir and simquery.couldUnitSeeCell(self.unit:getSim(), self.unit, interestCell) then
			self.unit:turnToFace(interest.x, interest.y)
			return simdefs.BSTATE_RUNNING
		end
	end

	return Actions.MoveTo.onPathNoMP(self)
end

function Actions.MoveToInterest:addDoorBreakActions(sim, path)

	local abilityDef = self.unit:ownsAbility("breakDoor")
	if not abilityDef then
		return
	end

	if not self.unit:isAlerted() then
		return
	end

	local interest = self.unit:getBrain():getInterest()
	if self.unit:getBrain():getDestination() ~= interest then
		return
	end

	--don't kick doors down for these reasons
	if interest.reason == simdefs.REASON_HUNTING or
	 interest.reason == simdefs.REASON_PATROLCHANGED then
		return
	end


	local finalNode = path.path:getNodes()[#path.path:getNodes()]
	local finalCell = sim:getCell(finalNode.location.x, finalNode.location.y)

	--don't kick doors down if our interest doesn't lie on the other side of it
	if finalCell.x ~= interest.x or finalCell.y ~= interest.y then
		return
	end

	local secondLastNode = path.path:getStartNode()
	if #path.path:getNodes() > 1 then
		--step back through the path trying to find a node that isn't the finish
		for i = #path.path:getNodes(), 1, -1 do
			local node = path.path:getNodes()[i]
			if node.location ~= finalNode.location then
				secondLastNode = node
				break
			end
		end
	end
	if not secondLastNode then
		simlog( simdefs.LOG_PATH, "(%d) path not long enough to break door", path.unit:getID())
		return
	end
	local secondLastCell = sim:getCell(secondLastNode.location.x, secondLastNode.location.y)
	local doorDir = simquery.getDirectionFromDelta(finalCell.x-secondLastCell.x, finalCell.y-secondLastCell.y)
	if simquery.checkIsDoor(sim, secondLastCell, doorDir) and abilityDef:canUseAbility(sim, self.unit, self.unit, secondLastCell, doorDir) then
		--add a breakDoor action to the path
		simlog( simdefs.LOG_PATH, "(%d) path adding breakDoor action at (%d, %d) %s", path.unit:getID(), secondLastCell.x, secondLastCell.y, simdefs:stringForDir(doorDir))
		self.unit:getPather():addActionToPath(path, secondLastNode, {ability="breakDoor", owner=self.unit, user=self.unit, params={}, keepPathing=true } ) 
	end
end

function Actions.MoveToInterest:addThrowGrenadeActions(sim, path)

	local abilityDef, grenadeUnit = self.unit:ownsAbility("throw")
	if not abilityDef or not grenadeUnit then
		return
	end

	local x0, y0 = self.unit:getLocation()
	local destination = self.unit:getBrain():getDestination()
	if destination ~= self.unit:getBrain():getInterest() then
		return
	end

	if destination.x == x0 and destination.y == y0 then
		return
	end



	if self.unit:getBrain():getInterest().grenadeHit then
		return
	end


	--find the first part of the path that gives us LOS to the interest
	local throwRange = self.unit:getTraits().maxThrow or 0
	local minThrowRange = self.unit:getTraits().minThrow or 0
	local targetCell = sim:getCell(path.goalx, path.goaly)

	local cellsInRange = {}
	table.insert(cellsInRange, targetCell)
	local aimRange = grenadeUnit:getTraits().aimRange or grenadeUnit:getTraits().range
	if aimRange and aimRange > 0 then
		--only cells in range with LOS to the targetcell should be considered
		for i,testCell in ipairs(simquery.fillCircle( sim, targetCell.x, targetCell.y, aimRange, 0) ) do
			if testCell ~= targetCell then
				local raycastX, raycastY = sim:getLOS():raycast(testCell.x, testCell.y, targetCell.x, targetCell.y)
				if raycastX == targetCell.x and raycastY == targetCell.y then
					table.insert(cellsInRange, testCell)
				end
			end
		end
	end
	local node = path.path:getStartNode()
	local i = 1
	repeat
		local startCell = sim:getCell(node.location.x, node.location.y)
		local closestCell, closestDist
		if startCell ~= targetCell then
			for k, endCell in ipairs(cellsInRange) do
				local throwDistSq = mathutil.distSqr2d(startCell.x, startCell.y, endCell.x, endCell.y)
				if throwDistSq < throwRange*throwRange and throwDistSq > minThrowRange*minThrowRange then
					local raycastX, raycastY = sim:getLOS():raycast(startCell.x, startCell.y, endCell.x, endCell.y)
					if raycastX == endCell.x and raycastY == endCell.y then
						--it's a valid cell to throw to
						local distSqFromTarget = mathutil.distSqr2d(endCell.x, endCell.y, targetCell.x, targetCell.y)
						if not closestCell or distSqFromTarget < closestDist then 
							closestCell = endCell
							closestDist = distSqFromTarget
						end
					end
				end
			end
		end
		if closestCell then
			--add a ThrowGrenade action to the path
			local target = {closestCell.x, closestCell.y}
			simlog( simdefs.LOG_PATH, "(%d) path adding throw action from (%d, %d) to (%d, %d)", path.unit:getID(), node.location.x, node.location.y, closestCell.x, closestCell.y) 
			self.unit:getPather():addActionToPath(path, node, {ability="throw", owner=grenadeUnit, user=self.unit, params={target}, keepPathing = grenadeUnit:getTraits().keepPathing } ) 
			break
		end


		node = path.path:getNodes()[i]
		i = i + 1
	until not node
	
end

-----------------------------------------------------------------------------------------

Actions.MoveToNextPatrolPoint = class(Actions.MoveTo, function(self, name)
	btree.BaseAction.init(self, name or "MoveToNextPatrolPoint")
end)

function Actions.MoveToNextPatrolPoint:getDestination()
	return self.unit:getBrain():getPatrolPoint()
end

-----------------------------------------------------------------------------------------

Actions.MoveToNearestExit = class(Actions.MoveTo, function(self, name)
	btree.BaseAction.init(self, name or "MoveToNearestExit")
end)

function Actions.MoveToNearestExit:getDestination()
	local sim = self.unit:getSim()
	local startCell = sim:getCell(self.unit:getLocation() )
	local guardCells = sim:getCells("guard_spawn")

	--to do: reduce the cells we path to down to just the closest ones for each guard elevator

	local astar = include ("modules/astar" )
	local astar_handlers = include("sim/astar_handlers")
	local pather = astar.AStar:new(astar_handlers.aihandler:new(self.unit) )
	local closestCell, closestPathDist
	for i, cell in ipairs(guardCells) do
		local path = pather:findPath( startCell, cell )

		if path then
			--make sure our path doesn't go through 
			local pathDist = path:getTotalMoveCost()
			if not closestCell or pathDist < closestPathDist then
				closestCell = cell
				closestPathDist = pathDist
			end
		end
	end

	if closestCell then
		return {x=closestCell.x, y=closestCell.y}
	end
end

-----------------------------------------------------------------------------------------

Actions.MoveAwayFromAgent = class(Actions.MoveTo, function(self, name)
	btree.BaseAction.init(self, name or "MoveAwayFromAgent")
end)

function Actions.MoveAwayFromAgent:onNoDestination()
	return simdefs.BSTATE_FAILED
end

function Actions.MoveAwayFromAgent:onNoPath()
	return simdefs.BSTATE_FAILED
end



function Actions.MoveAwayFromAgent:getDestination()
	local sim = self.unit:getSim()
	local x0, y0 = self.unit:getLocation()

	local target = self.unit:getBrain():getTarget()
	if not target and self.unit:getBrain():getInterest()
	 and self.unit:getBrain():getInterest().reason == simdefs.REASON_LOSTTARGET and not self.unit:getBrain():getInterest().investigated then
		target = self.unit:getBrain():getInterest().sourceUnit
	end
	if target then 
		local x1, y1 = target:getLocation()
		local deltaX, deltaY = x0-x1, y0-y1
		local raycastX, raycastY = sim:getLOS():raycast(x1, y1, x1+20*deltaX, y1+20*deltaY)

		raycastX = deltaX < 0 and math.ceil(raycastX) or math.floor(raycastX)
		raycastY = deltaY < 0 and math.ceil(raycastY) or math.floor(raycastY)


		local cell = sim:getCell(raycastX, raycastY)
		if cell and not (cell.x == x0 and cell.y == y0) then
			if cell.impass == 0 then
				return {x=cell.x, y=cell.y}
			else
				--check all the nearby cells for ones we can hide in
				for i, v in ipairs(cell.exits) do
					if not v.door and v.cell.impass == 0 then
						return {x=v.cell.x, y=v.cell.y}
					end
				end
			end
		end
	end

end

-----------------------------------------------------------------------------------------

Actions.MoveAroundTarget = class(Actions.MoveTo, function(self, name)
	btree.BaseAction.init(self, name or "MoveAroundTarget")
end)

function Actions.MoveAroundTarget:getDestination()
	local x, y = self.unit:getBrain():getTarget():getLocation()
	local sim = self.unit:getSim()
	local neighbour = simquery.findNearestEmptyCell( sim, x, y, self.unit)
	if neighbour then
		local facing = simquery.getDirectionFromDelta(x - neighbour.x, y - neighbour.y)
		return {x = neighbour.x, y = neighbour.y, facing=facing}
	end
end

-----------------------------------------------------------------------------------------

return Actions
