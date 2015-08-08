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

local STRINGS = include( "strings" )
local SCRIPTS = include('client/story_scripts')

---------------------------------------------------------------------------------------------
-- Local helpers


local HACK_VAULT = 
{
    action = "mainframeAction",
    fn = function( sim, updates )
        if updates and updates.action == "breakIce" then
            local unit = sim:getUnit(updates.unitID)
            return unit:hasTag("vault") and unit:getTraits().mainframe_ice == 0 and unit
        end
    end
}

local LOOT_OUTER_SAFE =
{
    action = "abilityAction",
    --pre = true,
    fn = function( sim, ownerID, userID, abilityIdx, ... )
        local unit, ownerUnit = sim:getUnit( userID ), sim:getUnit( ownerID )
        
        if not unit or not unit:isPC() or not ownerUnit then
            return nil
        end
        if ownerUnit:getAbilities()[ abilityIdx ]:getID() == "stealCredits" then
            if ownerUnit:hasTag("vault") and not ownerUnit:getTraits().inner_vault then
                return ownerUnit
            end
        end
    end,
}

local LOOT_INNER_SAFE =
{
    action = "abilityAction",
    --pre = true,
    fn = function( sim, ownerID, userID, abilityIdx, ... )
        local unit, ownerUnit = sim:getUnit( userID ), sim:getUnit( ownerID )
        
        if not unit or not unit:isPC() or not ownerUnit or not ownerUnit:getTraits().inner_vault then
            return nil
        end

        if ownerUnit:getAbilities()[ abilityIdx ]:getID() == "stealCredits" then
            if ownerUnit:hasTag("vault") and ownerUnit:getTraits().inner_vault then
                return ownerUnit
            end
        end
    end,
}

local function lootInner( script, sim, mission )
    local _, vault = script:waitFor( LOOT_INNER_SAFE )
    mission.loot_inner = true
end

local function lootOuter( script, sim, mission )
    local _, vault = script:waitFor( LOOT_OUTER_SAFE )
    mission.loot_outer = true
end

local function hackvault( script, sim, mission )

	local _, vault = script:waitFor( HACK_VAULT )
	
    mission.hacked_vault = true
	--script:waitFor( mission_util.UI_LOOT_CLOSED )
	--spawn an enforcer
    sim:dispatchEvent( simdefs.EV_SCRIPT_EXIT_MAINFRAME )
    local x, y = vault:getLocation()
    local newGuards = sim:getNPC():spawnGuards(sim, simdefs.TRACKER_SPAWN_UNIT_ENFORCER, 1)
    for i, newUnit in ipairs(newGuards) do
        newUnit:getBrain():spawnInterest(x, y, simdefs.SENSE_RADIO, simdefs.REASON_REINFORCEMENTS)
    end
   
    script:waitFrames( 1.0*cdefs.SECONDS )

    script:queue( { type="pan", x=x, y=y } )
    script:waitFrames( .25*cdefs.SECONDS )

    script:queue( { script=SCRIPTS.INGAME.AFTERMATH.VAULT[sim:nextRand(1, #SCRIPTS.INGAME.AFTERMATH.VAULT)], type="newOperatorMessage" } )    

end


local function checkVaultSafes( sim )
	for i,unit in pairs(sim:getAllUnits()) do
		if unit:hasTag("vaultSafe") then
			
			local loot = sim:getQuery().scaleCredits( sim, math.floor(sim:nextRand()*4)*25 + 200 )
			if unit:getTraits().credits then
				unit:getTraits().credits = unit:getTraits().credits + loot
			else
				unit:getTraits().credits = loot
			end
		end
	end
end

local function checkForVaultCodeUsed( script, sim, mission )
	script:waitFor( mission_util.PC_UNLOCK_DOOR() )
    mission.used_card = true
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_USED_VAULT_CODE, type="newOperatorMessage" } )	
	script:queue( 8*cdefs.SECONDS )	
	script:queue( { type="clearOperatorMessage" } )
end

local function checkVaultItem( script, sim )
	script:waitFor( mission_util.PC_SAW_UNIT("vault") )		
	sim:setClimax(true)
    sim:removeObjective( "vault" )
end

---------------------------------------------------------------------------------------------
-- Begin!

local mission = class( escape_mission )

function mission:init( scriptMgr, sim )
    escape_mission.init( self, scriptMgr, sim )
	checkVaultSafes( sim )

    sim.exit_warning = function()
        if not self.loot_outer and not self.loot_inner then
            return STRINGS.UI.HUD_WARN_EXIT_MISSION_VAULT
        end
    end
    
    
    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_VAULT, "vault" )
	scriptMgr:addHook( "VAULT-CODE", checkForVaultCodeUsed, nil, self )
	scriptMgr:addHook( "VAULT-ITEM", checkVaultItem )
    scriptMgr:addHook( "VAULT-LOOT", hackvault, nil, self )

    scriptMgr:addHook( "VAULT-LOOTINNER", lootInner, nil, self )
    scriptMgr:addHook( "VAULT-LOOTOUTER", lootOuter, nil, self )

    
    scriptMgr:addHook( "SEENANO", mission_util.DoReportObject(mission_util.PC_SAW_UNIT_WITH_TRAIT("open_secure_boxes"), SCRIPTS.INGAME.SEEOBJECTIVE.VAULT) )


 --This picks a reaction rant from Central on exit based upon whether or not an agent has escaped with the loot yet.
    local scriptfn = function()
        local scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.VAULT.NOLOOT 
        if self.loot_outer then scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.VAULT.EASYLOOT end
        if self.loot_inner then scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.VAULT.HARDLOOT end
        return scripts[sim:nextRand(1, #scripts)]
    end

    scriptMgr:addHook( "FINAL", mission_util.CreateCentralReaction(scriptfn))    
end


function mission.pregeneratePrefabs( cxt, tagSet )
    escape_mission.pregeneratePrefabs( cxt, tagSet )
    table.insert( tagSet[1], "vault" )
end


return mission
