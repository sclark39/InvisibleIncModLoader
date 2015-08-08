local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

-------------------------------------------------------------------------
-- Trigger wireless onselect.

local function triggerWirelessScan( script, sim, abilityOwner )
    local level = include( "sim/level" )
    local userUnit = abilityOwner:getUnitOwner()
    if userUnit == nil then
        return -- Only triggers if carried by somebody.
    end

    local wirelessAbility = abilityOwner:hasAbility( "wireless_scan" )
    if not wirelessAbility:canUseAbility( sim, abilityOwner, userUnit ) then
        return
    end
    
    script:waitFor( { uiEvent = level.EV_UNIT_SELECTED,
        fn = function( sim, unitID )
            return userUnit:isValid() and unitID == userUnit:getID()
        end } )

    local cell = sim:getCell( userUnit:getLocation() )
    if cell then
        wirelessAbility:performScan( sim, abilityOwner, cell )
    end
end

-------------------------------------------------------------------------
-- Passive wireless scan; scans devices whenever the owning unit warps.

local wireless_scan =
{
	name = STRINGS.ABILITIES.WIRELESS_SCAN,
	getName = function( self, sim, unit )
		return self.name
	end,
		
	onSpawnAbility = function( self, sim, unit )
        self.abilityOwner = unit
        sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
        self.hook = sim:getLevelScript():addHook( "FIRST-WIRELESS", triggerWirelessScan, nil, unit )
	end,
        
	onDespawnAbility = function( self, sim, unit )
        sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
        self.abilityOwner = nil
        sim:getLevelScript():removeHook( self.hook )
	end,

    canUseAbility = function( self, sim, abilityOwner, abilityUser )
        return abilityutil.checkRequirements( abilityOwner, abilityUser )
    end,

    onTrigger = function( self, sim, evType, evData )
        if self.abilityOwner and evData.unit == self.abilityOwner:getUnitOwner() and evData.unit:getPlayerOwner() and evData.to_cell then
            if self:canUseAbility( sim, self.abilityOwner, evData.unit ) then
                self:performScan( sim, self.abilityOwner, evData.to_cell )
            end
        end
    end,
	
    performScan = function( self, sim, abilityOwner, cell )
        local player = abilityOwner:getPlayerOwner()
		sim:forEachUnit(
		    function( mainframeUnit )
			    local x1, y1 = mainframeUnit:getLocation()
			    if x1 and y1 and (mainframeUnit:getTraits().mainframe_item or mainframeUnit:getTraits().mainframe_console) and not mainframeUnit:getTraits().scanned then
				    local distance = mathutil.dist2d( cell.x, cell.y, x1, y1 )
				    if distance < abilityOwner:getTraits().wireless_range then
					    player:glimpseUnit( sim, mainframeUnit:getID() )
					    mainframeUnit:getTraits().scanned = true
					    sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = mainframeUnit, reveal = true } )      
                        
                        if mainframeUnit:getTraits().mainframe_program then
                            sim:dispatchEvent( simdefs.EV_DAEMON_TUTORIAL )       
                        end
				    end
			    end
		    end )
	end,
}

return wireless_scan