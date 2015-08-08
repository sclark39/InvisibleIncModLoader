local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local cdefs = include( "client_defs" )
local mission_util = include( "sim/missions/mission_util" )
local escape_mission = include( "sim/missions/escape_mission" )
local simfactory = include( "sim/simfactory" )
local unitdefs = include( "sim/unitdefs" )
local itemdefs = include( "sim/unitdefs/itemdefs" )
local SCRIPTS = include('client/story_scripts')

---------------------------------------------------------------------------------------------
-- Local helpers

local OBJECTIVE_ID = "ceoOffice"

local CEO_ALERTED = 
{
	trigger = simdefs.TRG_UNIT_ALERTED,
    fn = function( sim, evData )

        if evData.unit:hasTag("interrogate")  then
        	return true
		end
    end,
}
local CEO_ESCAPED = 
{
	trigger = "vip_escaped",
    fn = function( sim, evData )
    	return true
    end,
}
 
local PC_KNOCKOUT_CEO =
{
    trigger = simdefs.TRG_UNIT_KO,
    fn = function( sim, triggerData )
        if triggerData and (triggerData.ticks or 0) > 0 and triggerData.unit:getTraits().ko_trigger == "intimidate_guard" then
            return triggerData.unit
        end
    end
}
    

local function ceoalerted(script, sim, mission)
	script:waitFor( CEO_ALERTED )
    if not mission.lootspawned and not mission.failed then
	   script:queue( { script=SCRIPTS.INGAME.CENTRAL_CFO_RUNNING, type="newOperatorMessage" } )
	   local ceo = mission_util.findUnitByTag( sim, "interrogate" )
	   sim:getPC():glimpseUnit(sim, ceo:getID() )
    end
end

local function ceoescaped(script, sim, mission)
	script:waitFor( CEO_ESCAPED )
    if not mission.lootspawned and not mission.failed then
	   script:queue( { script=SCRIPTS.INGAME.CENTRAL_CFO_ESCAPED, type="newOperatorMessage" } )	
	   mission.failed = true
       sim.exit_warning = nil
    end
end




local function createVaultCard(script, sim)
	local target = nil
	sim:forEachUnit(
		function(unit)
			if unit:getTraits().ko_trigger == "intimidate_guard" then 
				target = unit				
			end
		end)
	if target then
		
		local cell = sim:getCell( target:getLocation() )
		local newUnit = simfactory.createUnit( unitdefs.lookupTemplate( "vault_passcard" ), sim )		
		sim:spawnUnit( newUnit )
		newUnit:addTag("access_card_obj")
		sim:warpUnit( newUnit, cell )

		sim:emitSound( simdefs.SOUND_ITEM_PUTDOWN, cell.x, cell.y)

	end
end

local function callReinforcement(script, sim)
	local target = nil

	sim:forEachUnit(
			function(unit)
				if unit:getTraits().ko_trigger == "intimidate_guard" then 
					target = unit				
				end
			end)
	if target then
		local newGuards = sim:getNPC():spawnGuards(sim, "npc_guard_enforcer_reinforcement", 1)
		for i, newUnit in ipairs(newGuards) do
			local x1,y1 = target:getLocation()
			newUnit:getBrain():spawnInterest(x1, y1, simdefs.SENSE_RADIO, simdefs.REASON_REINFORCEMENTS, target)
		end
		return true
	else
		return false
	end

end

local function brainScanBanter( script, sim )
	script:waitFor( mission_util.PC_START_TURN )
	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/transferData" )
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_CFO_BRAINSCAN_1, type="newOperatorMessage" } )		
    sim:incrementTimedObjective( "guard_finish" )
	script:waitFor( mission_util.PC_ANY )	
	script:queue( { type="clearOperatorMessage" } )
	script:waitFor( mission_util.PC_START_TURN )
	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/transferData" )
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_CFO_BRAINSCAN_2, type="newOperatorMessage" } )	
    sim:incrementTimedObjective( "guard_finish" )
	script:waitFor( mission_util.PC_ANY )	
	script:queue( { type="clearOperatorMessage" } )
	script:waitFor( mission_util.PC_START_TURN )
	sim:setClimax(true)
	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/transferData" )
	callReinforcement(script, sim) 
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_CFO_BRAINSCAN_3, type="newOperatorMessage" } )	
    sim:incrementTimedObjective( "guard_finish" )
	script:waitFor( mission_util.PC_ANY )	
	script:queue( { type="clearOperatorMessage" } )
	script:waitFor( mission_util.PC_START_TURN )
	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/transferData" )
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_CFO_BRAINSCAN_4, type="newOperatorMessage" } )
    sim:incrementTimedObjective( "guard_finish" )
	script:waitFor( mission_util.PC_ANY )	
	script:queue( { type="clearOperatorMessage" } )
	script:waitFor( mission_util.PC_START_TURN )
	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/transferData" )
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_CFO_BRAINSCAN_5, type="newOperatorMessage" } )
    sim:incrementTimedObjective( "guard_finish" )
	script:waitFor( mission_util.PC_ANY )	
	script:queue( { type="clearOperatorMessage" } )

	script:waitFor( mission_util.PC_START_TURN )
end

local function checkForTargetInRange( script, sim, guard, range)
	local x0,y0 = guard:getLocation()
	local closestUnit, closestDistance = simquery.findClosestUnit( sim:getPC():getAgents(), x0, y0, function( u ) return not u:isKO() end )
	if closestDistance > range then
		script:queue( { script=SCRIPTS.INGAME.CENTRAL_MOVE_INTO_RANGE, type="newOperatorMessage" } )
	end
end

local function followHeatSig( script, sim )
	local guardUnit = nil
	sim:forEachUnit(
	function(unit)
		if unit:getTraits().ko_trigger == "intimidate_guard" then 
			guardUnit = unit
			local x, y = unit:getLocation()
			script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.UTIL.HEAT_SIGNATURE_DETECTED, x=x, y=y } )
			script:queue( { type="pan", x=x, y=y } )
		end
	end)

	while true do 
		local ev, triggerData = script:waitFor( mission_util.UNIT_WARP )
		if triggerData.unit:getTraits().ko_trigger == "intimidate_guard" then
			script:queue( { type="hideHUDInstruction" } ) 
			local x, y = triggerData.unit:getLocation()
            if x and y then
			    script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.UTIL.HEAT_SIGNATURE_DETECTED, x=x, y=y } )
			    script:queue( { type="pan", x=x, y=y } )
            end
		end 
	end
end

local function followAccessCard( script, sim )
	local cardUnit = nil
	sim:forEachUnit(
	function(unit)
		if unit:hasTag("access_card_obj") then 
			cardUnit = unit
			local x, y = unit:getLocation()
			script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.UTIL.ACCESS_CARD_DETECTED, x=x, y=y } )
			script:queue( { type="pan", x=x, y=y } )
		end
	end)

	while true do 
		local ev, triggerData = script:waitFor( mission_util.UNIT_WARP )
		if triggerData.unit:hasTag("access_card_obj") then
			script:queue( { type="hideHUDInstruction" } ) 
			local x, y = triggerData.unit:getLocation()
            if x and y then
			    script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.UTIL.ACCESS_CARD_DETECTED, x=x, y=y } )
			    script:queue( { type="pan", x=x, y=y } )
            end
		end 
	end
end


local function checkInterrogateTargets( script, sim, mission )
	local _, guard = script:waitFor( mission_util.PC_SAW_UNIT("interrogate") )

    local function onFailInterrogation( script, sim )
	    sim:setMissionReward( 0 )
	   	sim:removeObjective( "get_near" )
	    sim:removeObjective( "stay_near" )
	    sim:removeObjective( "guard_finish" )
    	sim:removeObjective( "ko_target" )
        script:removeHook( checkInterrogateTargets )
        sim.exit_warning = nil
        mission.failed = true
    end

    local function checkNoGuardKill( script, sim )
	    script:waitFor( { trigger = "guard_dead" } )
        mission.killed_target = true
        onFailInterrogation( script, sim )
        script:queue( { script=SCRIPTS.INGAME.CENTRAL_FAILED_TARGET_DIED, type="newOperatorMessage" } )
	    script:waitFor( mission_util.PC_ANY )	
	    script:queue( { type="clearOperatorMessage" } )
    end

	script:addHook( checkNoGuardKill )
	script:addHook( followHeatSig )
	sim:removeObjective( OBJECTIVE_ID )
	sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_DISABLE_TARGET, "ko_target" )
	script:queue( 1*cdefs.SECONDS )	
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_SEEINTERROGATE, type="newOperatorMessage" } )

    if not guard:isKO() then
	    script:waitFor( PC_KNOCKOUT_CEO )
    end
	script:removeHook( checkNoGuardKill )

    assert( type(guard:getTraits().koTimer) == "number" )
    guard:getTraits().koTimer = 6 -- Override the ko time.
	
	script:removeHook( followHeatSig )
	script:queue( { type="hideHUDInstruction" } )

	local x0,y0 = guard:getLocation()

	local checkGuardDistance = nil
    checkGuardDistance = mission_util.createInterrogationHook( guard, onFailInterrogation )
	script:addHook( checkGuardDistance )    

 	local closestUnit, closestDistance = simquery.findClosestUnit( sim:getPC():getAgents(), x0, y0, function( u ) return not u:isKO() end )

 	if closestDistance > 3 then
		checkForTargetInRange(script, sim, guard, 3 )
  		script:waitFor( mission_util.PC_IN_RANGE_OF_TARGET( script, guard, 3 ) )	
  	end
	guard:getTraits().interrogationStarted = true

	sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_BRAINSCAN, "guard_finish", 6 )
	sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_STAYNEAR, "stay_near" )

	sim:removeObjective( "ko_target" )
	
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_INTERROGATE_START, type="newOperatorMessage" } )
	script:waitFor( mission_util.PC_ANY )	
	script:queue( { type="clearOperatorMessage" } )

    brainScanBanter( script, sim )

	guard:getTraits().interrogationFinished = true

    if checkGuardDistance then
	    script:removeHook( checkGuardDistance )
    end
	script:removeHook( checkNoGuardKill )
	sim:removeObjective( "guard_finish" )
	sim:removeObjective( "stay_near" )

	createVaultCard(script,sim)
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_INTERROGATE_END, type="newOperatorMessage" } )
	sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_RETRIEVE_ACCESS_CODE, "get_code")
	script:addHook( followAccessCard )


	local _, unit = script:waitFor( mission_util.PC_TOOK_UNIT_WITH_TAG("access_card_obj") )
	sim:removeObjective( "get_code" )	
	unit:removeTag("access_card_obj") 
	unit:addTag("mission_loot")
	mission.lootspawned = true
	script:removeHook( followAccessCard )
	script:queue( { type="hideHUDInstruction" } )

	script:queue( 16*cdefs.SECONDS )	
	script:queue( { type="clearOperatorMessage" } )
	
end


--keep track of when the loot gets teleported
local function gotloot(script, sim, mission)
    script:waitFor( mission_util.ESCAPE_WITH_LOOT("mission_loot") )
    mission.got_the_loot = true
end


---------------------------------------------------------------------------------------------
-- Begin!

local mission = class( escape_mission )

function mission:init( scriptMgr, sim )
    escape_mission.init( self, scriptMgr, sim )

    local miss = self
	sim.exit_warning = mission_util.CheckForLeftItem(sim, "mission_loot", STRINGS.UI.HUD_WARN_EXIT_CEO, function() return not miss.lootspawned end)
    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_CEO_OFFICE, OBJECTIVE_ID )			

	scriptMgr:addHook( "CEO", checkInterrogateTargets, nil, self )
	scriptMgr:addHook( "GOTLOOT", gotloot, nil, self )

    --This picks a reaction rant from Central on exit based upon whether or not an agent has escaped with the loot yet.
    local scriptfn = function()
        
        local scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.CFO.NOLOOT

        if self.got_the_loot then
        	scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.CFO.GOTLOOT
        elseif self.killed_target then
        	scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.CFO.KILLEDTHEGUY
        end
        local scr = scripts[sim:nextRand(1, #scripts)]

        return scr
    end
    scriptMgr:addHook( "FINAL", mission_util.CreateCentralReaction(scriptfn))

    scriptMgr:addHook( "RUN", ceoalerted, nil, self)
    scriptMgr:addHook( "escaped", ceoescaped, nil, self)
end


function mission.pregeneratePrefabs( cxt, tagSet )
    escape_mission.pregeneratePrefabs( cxt, tagSet )
    table.insert( tagSet[1], "ceo_office" )
end


return mission
