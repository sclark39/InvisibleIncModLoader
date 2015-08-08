local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

-------------------------------------------------------------------------
-- Passive wireless scan; scans devices whenever the owning unit warps.

local centralaugment =
{
	name = STRINGS.ITEMS.AUGMENTS.CENTRALS,
	getName = function( self, sim, unit )
		return self.name
	end,
		
	onSpawnAbility = function( self, sim, unit )
        self.abilityOwner = unit
        sim:addTrigger( simdefs.TRG_DAEMON_INSTALL, self )
	end,
        
	onDespawnAbility = function( self, sim, unit )
        sim:removeTrigger( simdefs.TRG_DAEMON_INSTALL, self )
        self.abilityOwner = nil
	end,

    onTrigger = function( self, sim, evType, evData )
    	local ADD_CPUS = 5 
        if evType == simdefs.TRG_DAEMON_INSTALL then
            if not self.abilityOwner:isKO() then
                local x0, y0 = self.abilityOwner:getLocation()
                self.abilityOwner:getPlayerOwner():addCPUs( ADD_CPUS )
				sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=util.sformat(STRINGS.UI.FLY_TXT.PLUS_PWR, ADD_CPUS), x=x0,y=y0, color={r=163/255,g=243/255,b=248/255,a=1},} )
            end
        end
    end,
}

return centralaugment