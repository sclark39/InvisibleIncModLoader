local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local mission_util = include( "sim/missions/mission_util" )
local escape_mission = include( "sim/missions/escape_mission" )
local unitdefs = include( "sim/unitdefs" )
local simfactory = include( "sim/simfactory" )
local itemdefs = include( "sim/unitdefs/itemdefs" )
local serverdefs = include( "modules/serverdefs" )
local cdefs = include( "client_defs" )

local SCRIPTS = include('client/story_scripts')

---------------------------------------------------------------------------------------------
-- Local helpers

local SITE_PLANS_TAG = "corp_map"
local OBJECTIVE_ID = "terminals"


local function doAftermath(script, sim)
    
    script:queue( 1*cdefs.SECONDS )
    script:queue( { script=SCRIPTS.INGAME.AFTERMATH.TERMS[sim:nextRand(1, #SCRIPTS.INGAME.AFTERMATH.TERMS)], type="newOperatorMessage" } )
    
    --shift guard patrols
    local idle = sim:getNPC():getIdleSituation()
    local guards = sim:getNPC():getUnits()


    for i,guard in ipairs(guards) do
       if guard:getBrain() and guard:getBrain():getSituation().ClassType == simdefs.SITUATION_IDLE then
            idle:generatePatrolPath( guard )
            if guard:getTraits().patrolPath and #guard:getTraits().patrolPath > 1 then
                local firstPoint = guard:getTraits().patrolPath[1]
                guard:getBrain():getSenses():addInterest(firstPoint.x, firstPoint.y, simdefs.SENSE_RADIO, simdefs.REASON_PATROLCHANGED, guard)
            end
        end
    end
    sim:processReactions()
end


local LOOT_TERMINAL =
{
	action = "abilityAction",
	pre = true,
	fn = function( sim, ownerID, userID, abilityIdx, ... )
		local unit, ownerUnit = sim:getUnit( userID ), sim:getUnit( ownerID )
		if not unit or not unit:isPC() or not ownerUnit or not ownerUnit:getTraits().public_term then
			return nil
		end

		if ownerUnit:getAbilities()[ abilityIdx ]:getID() == "stealCredits" then
            return ownerUnit
        end
	end,
}

local function chooseRandomLocations( count, sim )
    local tags = {}
    -- newLocation data is used in mission_complete, passing through to servers.createCampaignSituations
    local missionTags = util.tcopy( serverdefs.ESCAPE_MISSION_TAGS )
    for i = 1, count do
        local corpName = serverdefs.CORP_NAMES[ sim:nextRand( 1, #serverdefs.CORP_NAMES )]
        local missionTag = table.remove( missionTags, sim:nextRand( 1, #missionTags ))
        table.insert( tags, corpName )
        table.insert( tags, missionTag )
    end
    return tags
end

local function checkTookPlans( script, sim )
    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_RETRIEVE_MAP_LIST, "get_list")
    script:waitFor( mission_util.PC_TOOK_UNIT_WITH_TAG("corp_map") )
    sim:removeObjective( "get_list" )           
end

local function checkNewLocationItem( script, sim )
	local _, terminal = script:waitFor( LOOT_TERMINAL )
    terminal:destroyTab()

    local newLocations = nil
    if sim:getParams().missionCount > 0 then
        -- select ONE from a random choice of 4, and add TWO more random missions.
        local tags = chooseRandomLocations( 4, sim )
        local options = {}
        local corps = {}
        local names = {}
        for i = 1, #tags, 2 do
            local corpString = serverdefs.CORP_DATA[ tags[i] ].stringTable.SHORTNAME
            local missionString = serverdefs.SITUATIONS[ tags[i+1] ].ui.locationName
            table.insert( options, corpString .. " " .. missionString )
            table.insert( corps, tags[i] )
            table.insert( names, tags[i+1] )
        end
        local choice = mission_util.showExecDialog( sim, STRINGS.MISSIONS.ESCAPE.SITE_PLANS_HEADER, STRINGS.MISSIONS.ESCAPE.SITE_PLANS_BODY, options, corps, names )
        if choice == simdefs.CHOICE_ABORT then
            choice = sim:nextRand( 1, #options )
        end
        local newLocation = { mission_tags = { "escape", tags[2 * choice - 1], tags[ 2 * choice ] } }
        newLocations = { newLocation, {}, {} }
    else
        -- Just add FOUR random missions
        newLocations = { {}, {}, {}, {} }
    end

    for i, childUnit in ipairs( terminal:getChildren() ) do
        if childUnit:hasTag( SITE_PLANS_TAG ) then
            childUnit:getTraits().newLocations = newLocations
            break
        end
    end

	sim:setClimax(true)

    script:waitFor( mission_util.UI_LOOT_CLOSED )
    doAftermath(script, sim)
end

--keep track of when the loot gets teleported
local function gotloot(script, sim, mission)
    script:waitFor( mission_util.ESCAPE_WITH_LOOT(SITE_PLANS_TAG) )
    mission.got_the_loot = true
end



---------------------------------------------------------------------------------------------
-- Mission

local mission = class( escape_mission )

function mission:init( scriptMgr, sim )
    escape_mission.init( self, scriptMgr, sim )

    local isEndless = sim:getParams().difficultyOptions.maxHours == math.huge
    
    --this is a test to see if we should warn on attempted exit. 
    sim.exit_warning = mission_util.CheckForLeftItem(sim, SITE_PLANS_TAG, STRINGS.UI.HUD_WARN_EXIT_EXECTERM)

    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_TERMINALS, OBJECTIVE_ID )			
    scriptMgr:addHook( "TERMINAL", checkNewLocationItem )

    local prefn = function(script, sim, item)
        item:createTab( STRINGS.MISSIONS.UTIL.ENCRYPTED_DATA, "" )
        sim:removeObjective( OBJECTIVE_ID )
        scriptMgr:addHook( "TOOK-PLANS", checkTookPlans )
    end
    scriptMgr:addHook( "SEE", mission_util.DoReportObject(mission_util.PC_SAW_UNIT_WITH_TRAIT("public_term"), SCRIPTS.INGAME.SEEOBJECTIVE.TERMS, prefn) )

    scriptMgr:addHook("ESCAPEWITHLOOT", gotloot, nil, self)

    --This picks a reaction rant from Central on exit based upon whether or not an agent has escaped with the loot yet.
    local scriptfn = function()
        local scripts = self.got_the_loot and SCRIPTS.INGAME.CENTRAL_JUDGEMENT.TERMS.HASLIST or SCRIPTS.INGAME.CENTRAL_JUDGEMENT.TERMS.NOLIST
        local scr = scripts[sim:nextRand(1, #scripts)]
        return scr
    end
    scriptMgr:addHook( "FINAL", mission_util.CreateCentralReaction(scriptfn))
end


function mission.pregeneratePrefabs( cxt, tagSet )
    escape_mission.pregeneratePrefabs( cxt, tagSet )
    table.insert( tagSet[1], "terminals" )
end

return mission
