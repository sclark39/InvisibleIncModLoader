local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local usable =
{
	name = "Usable",

	getName = function( self, sim, unit, userUnit )
        return unit:getTraits().useString or ("USE " .. unit:getName())
	end,

	onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
        if abilityOwner:getUnitData().onWorldTooltip then
        	local tooltip = util.tooltip( hud._screen )
            abilityOwner:getUnitData().onWorldTooltip( tooltip:addSection(), abilityOwner )
            return tooltip
        else
            return self:getName( sim, abilityOwner, abilityUser )
        end
    end,

	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",		
	proxy = true,
	alwaysShow = true,
	ghostable = true,

	canUseAbility = function( self, sim, unit, userUnit )			
		return simquery.canUnitReach( sim, userUnit, unit:getLocation() )
	end,

	executeAbility = function ( self, sim, unit, userUnit )
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = unit:getLocation()	
		local facing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
		sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), facing = facing, sound = simdefs.SOUNDPATH_SAFE_OPEN, soundFrame = 1 } )

		userUnit:setInvisible(false)

		if unit:getTraits().trigger then
			sim:triggerEvent( unit:getTraits().trigger, { unit = unit, userUnit = userUnit } )
		end
	end,
}
return usable