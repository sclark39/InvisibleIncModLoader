local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local icebreak =
{
	name = STRINGS.ABILITIES.ICEBREAK,
	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
    proxy = true,

	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		local headerTxt = string.format( STRINGS.ABILITIES.TOOLTIPS.HACK, util.toupper( targetUnit:getName() ) )
		local bodyTxt = util.sformat( STRINGS.ABILITIES.TOOLTIPS.BREAKS_FIREWALLS, abilityOwner:getTraits().icebreak )
		return abilityutil.formatToolTip( headerTxt, bodyTxt, simdefs.DEFAULT_COST )
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.ABILITIES.ICEBREAK
	end,

    getProfileIcon = function( self, sim, abilityOwner )
        return abilityOwner:getUnitData().profile_icon or self.profile_icon
    end,

	acquireTargets = function( self, targets, game, sim, unit )
		local userUnit = unit:getUnitOwner()
        assert( userUnit, tostring(unit and unit:getName())..", "..tostring(unit:getLocation()) )
		local cell = sim:getCell( userUnit:getLocation() )
        local cells = { cell }
		for dir, exit in pairs(cell.exits) do
            if simquery.isOpenExit( exit ) then
                table.insert( cells, exit.cell )
            end
        end

		local units = {}
		for i, cell in pairs(cells) do
			for _, cellUnit in ipairs( cell.units ) do
				if (cellUnit:getTraits().mainframe_ice or 0) > 0 and cellUnit:getTraits().mainframe_status ~= "off" and not cellUnit:isKO() then
					table.insert( units, cellUnit )
				end
			end
		end

		return targets.unitTarget( game, units, self, unit, userUnit )
	end,
		
	canUseAbility = function( self, sim, unit )

		-- Must have a user owner.
		local userUnit = unit:getUnitOwner()
		if not userUnit then
			return false
		end
		if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
		end
		if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
			return false, util.sformat(STRINGS.UI.REASON.CHARGES)
		end		
        if (unit:getTraits().icebreak or 0) <= 0 then
            return false
        end
		
        return abilityutil.checkRequirements( unit, userUnit)
	end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local mainframe = include( "sim/mainframe" )
		local userUnit = unit:getUnitOwner()
		local target = sim:getUnit(target)			
			
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = target:getLocation()
  		local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 

		sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), facing = newFacing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )
			
		local iceCount = unit:getTraits().icebreak
        if unit:getTraits().maxIcebreak then
            unit:getTraits().icebreak = math.max( 0, unit:getTraits().icebreak - target:getTraits().mainframe_ice )
        end
		mainframe.breakIce( sim, target, math.min( target:getTraits().mainframe_ice, iceCount ) )

		inventory.useItem( sim, userUnit, unit )

		if userUnit:isValid() then
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
		end
	end,
}

return icebreak