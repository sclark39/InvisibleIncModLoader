local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

-------------------------------------------------------------------------
-- Passive wireless scan; scans devices whenever the owning unit warps.

local decker_2_augment =
{
	name = STRINGS.ITEMS.AUGMENTS.DECKER_2,
	getName = function( self, sim, unit )
		return self.name
	end,
		
	onSpawnAbility = function( self, sim, unit )
        self.seerUnits = {}
        self.abilityOwner = unit
        sim:addTrigger( simdefs.TRG_UNIT_NEWINTEREST, self )
        sim:addTrigger( simdefs.TRG_UNIT_NEWTARGET, self )
        sim:addTrigger( simdefs.TRG_START_TURN, self )
	end,
        
	onDespawnAbility = function( self, sim, unit )
        sim:removeTrigger( simdefs.TRG_UNIT_NEWINTEREST, self )
        sim:removeTrigger( simdefs.TRG_UNIT_NEWTARGET, self )
        sim:removeTrigger( simdefs.TRG_START_TURN, self )
        self.abilityOwner = nil
	end,

    onTrigger = function( self, sim, evType, evData )
        if evType == simdefs.TRG_UNIT_NEWINTEREST or evType == simdefs.TRG_UNIT_NEWTARGET then

            --check that it's peripheral as well
            local ignore = false
            local target = nil
            if evType == simdefs.TRG_UNIT_NEWINTEREST then
                ignore = evData.interest.sense ~= simdefs.SENSE_PERIPHERAL
                target = evData.interest.sourceUnit
            else
                target = evData.target
            end

            local seer = evData.unit
            if not ignore and self.abilityOwner == target and array.find( self.seerUnits, seer ) == nil then

                table.insert( self.seerUnits, seer )
                if not self.abilityOwner:isKO() then
                    local AP_BONUS = 2
                    local x0, y0 = self.abilityOwner:getLocation()
                    self.abilityOwner:addMP( AP_BONUS )

                    sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = self.abilityOwner } )        
                    sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, { unit = self.abilityOwner , txt=STRINGS.ITEMS.AUGMENTS.DECKER_2, x=x0,y=y0,color={r=255/255,g=178/255,b=102/255,a=1}  } ) -- 
                end
            end
        elseif evType == simdefs.TRG_START_TURN then
            --reset who's seen me
            self.seerUnits = {}
        end
    end,
}

return decker_2_augment