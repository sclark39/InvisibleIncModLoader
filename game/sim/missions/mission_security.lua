local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local mission_util = include( "sim/missions/mission_util" )
local escape_mission = include( "sim/missions/escape_mission" )
local unitdefs = include( "sim/unitdefs" )
local itemdefs = include( "sim/unitdefs/itemdefs" )
local cdefs = include( "client_defs" )
local SCRIPTS = include('client/story_scripts')

---------------------------------------------------------------------------------------------
-- Local helpers

local OBJECTIVE_ID = "guardOffice"

local HOSTAGE_DEAD =
{
	trigger = "hostage_dead",
}

local PRISONER_ESCAPED = 
{
    trigger = simdefs.TRG_UNIT_ESCAPED,
	fn = function( sim, triggerData )
		local unit = triggerData
        if unit and unit:getTraits().rescued then
            return true -- note that unit has escaped so it is DESPAWNED and not actually valid.
        end
	end,
}


local PC_LOOTED_SECURE_SAFE =
{
    trigger = simdefs.TRG_SAFE_LOOTED,
    fn = function( sim, triggerData )
        if triggerData.targetUnit:hasTag("topGear") then
            return triggerData 
        end
    end,
}


local function checkTopGearSafes( sim )
	local itemList = {}
	for k,v in pairs(itemdefs) do
		if (v.floorWeight or 0) > 2 then
			table.insert(itemList,v)				
		end
	end

	for i,unit in pairs(sim:getAllUnits()) do
		if unit:hasTag("topGear") then
            -- Add a random item to unit (presumably a safe)
			local item = itemList[ sim:nextRand( 1, #itemList ) ]
			local newItem = simfactory.createUnit( item, sim )						
            newItem:addTag("topGearItem") -- For the UI loot hook
			sim:spawnUnit( newItem )
			unit:addChild( newItem )
		end
	end
end

local function checkTopGearItem( script, sim )	
	local _, item, agent = script:waitFor( mission_util.PC_TOOK_UNIT_WITH_TAG( "topGearItem" ))
	local topGearSafe = mission_util.findUnitByTag( sim, "topGear" )
    topGearSafe:destroyTab()

	sim:setClimax(true)
    script:waitFor( mission_util.UI_LOOT_CLOSED )
    script:waitFrames( .5*cdefs.SECONDS )

	if agent then
		local x2,y2 = agent:getLocation()
		sim:getNPC():spawnInterest(x2,y2, simdefs.SENSE_RADIO, simdefs.REASON_ALARMEDSAFE, agent)		
		
	end

	script:waitFrames( 1.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.AFTERMATH.DISPATCH[sim:nextRand(1, #SCRIPTS.INGAME.AFTERMATH.DISPATCH)], type="newOperatorMessage" } )

end

local function checkHostageDeath( script, sim )

	while true do
		script:waitFor( HOSTAGE_DEAD )

		script:queue( 2*cdefs.SECONDS )
		script:queue( { script=SCRIPTS.INGAME.CENTRAL_HOSTAGE_DEATH, type="newOperatorMessage" } )
		sim:setMissionReward( 0 )

		script:waitFor( mission_util.PC_ANY )	
		script:queue( { type="clearOperatorMessage" } )

	end

end

local function checkForHostage( script, sim, mission )
    local _, hostage = script:waitFor( mission_util.SAW_SPECIAL_TAG(script, "hostage", STRINGS.MISSIONS.UTIL.HEAT_SIGNATURE_DETECTED, STRINGS.MISSIONS.UTIL.RAPID_PULSE_READING ) )				

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_SEE_HOSTAGE, type="newOperatorMessage" } )	
	sim:removeObjective( "detentionCenter" )

	script:waitFor( mission_util.PC_USED_ABILITY( "hostage_rescuable" ))
	sim:setClimax(true)
    hostage:destroyTab()

	script:queue( { type="hideHUDInstruction" } )
	script:queue( { body=STRINGS.MISSIONS.ESCAPE.HOSTAGE_CONVO1, header=STRINGS.MISSIONS.ESCAPE.HOSTAGE_NAME, type="enemyMessage", 
			profileAnim="portraits/portrait_animation_template",
			profileBuild="portraits/courier_face",
		} )
	script:queue( 190 )	

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_HOSTAGE_CONV, type="newOperatorMessage" } )	

	sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_RESCUE_HOSTAGE )	
	script:queue( { type="clearEnemyMessage" } )
	script:queue( { type="clearOperatorMessage" } )

	script:addHook( checkHostageDeath )	

	script:waitFor( PRISONER_ESCAPED )
    mission.prisoner_escape = true
	sim:setMissionReward( simquery.scaleCredits( sim, 400 ))
end



--keep track of when the loot gets teleported
local function gotloot(script, sim, mission)
    script:waitFor( mission_util.ESCAPE_WITH_LOOT("topGearItem") )
    mission.got_the_loot = true
end


---------------------------------------------------------------------------------------------
-- Begin!

local mission = class( escape_mission )

function mission:init( scriptMgr, sim )
    escape_mission.init( self, scriptMgr, sim )

    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_SECURITY, OBJECTIVE_ID )			
	checkTopGearSafes( sim )

	sim.exit_warning = mission_util.CheckForLeftItem(sim, "topGearItem", STRINGS.UI.HUD_WARN_EXIT_MISSION_DISPATCH)
	scriptMgr:addHook( "TOPGEAR", checkTopGearItem )
	scriptMgr:addHook( "HOSTAGE", checkForHostage, nil, self)	
	
    local function prefn( script, sim, item )
        item:createTab( STRINGS.MISSIONS.UTIL.ADVANCED_TECHNOLOGY, "" )
        sim:removeObjective( OBJECTIVE_ID )              
    end

 	local function pstfn( script, sim, item )
        sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_SECURITY_2, OBJECTIVE_ID )
        script:waitFor( PC_LOOTED_SECURE_SAFE ) 
    end

	scriptMgr:addHook( "SEE", mission_util.DoReportObject(mission_util.PC_SAW_UNIT("topGear"), SCRIPTS.INGAME.SEEOBJECTIVE.DISPATCH, prefn, pstfn ) )

    scriptMgr:addHook("ESCAPEWITHLOOT", gotloot, nil, self)
    --This picks a reaction rant from Central on exit based upon whether or not an agent has escaped with the loot yet.
    local scriptfn = function()
        
        if self.prisoner_escape then
            return SCRIPTS.INGAME.CENTRAL_HOSTAGE_ESCAPE
        end

        local scripts = self.got_the_loot and SCRIPTS.INGAME.CENTRAL_JUDGEMENT.DISPATCH.HASLOOT or SCRIPTS.INGAME.CENTRAL_JUDGEMENT.DISPATCH.NOLOOT
        return scripts[sim:nextRand(1, #scripts)]
    end
    scriptMgr:addHook( "FINAL", mission_util.CreateCentralReaction(scriptfn))


end


function mission.pregeneratePrefabs( cxt, tagSet )
    escape_mission.pregeneratePrefabs( cxt, tagSet )
    table.insert( tagSet[1], "guard_office" )
end


return mission
