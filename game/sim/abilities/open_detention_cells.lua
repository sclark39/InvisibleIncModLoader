local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local open_detention_cells = 
	{
		name = STRINGS.ABILITIES.OPEN_DETENTION_CELLS,

		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip( STRINGS.ABILITIES.OPEN_DETENTION_CELLS,  STRINGS.ABILITIES.OPEN_DETENTION_CELLS_DESC )
		end,

		proxy = true,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
			return self.name
		end,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
            if simquery.canUnitReach( sim, unit, abilityOwner:getLocation() ) then
			    return targets.unitTarget( game, { abilityOwner }, self, abilityOwner, unit )
            end
		end,

		canUseAbility = function( self, sim, abilityOwner, unit )
            if abilityOwner:getTraits().mainframe_status ~= "active" then
                return false
            end

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end	

			if abilityOwner:getTraits().mainframe_ice > 0 then 
				return false, STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
			end

            if not simquery.canUnitReach( sim, unit, abilityOwner:getLocation() ) then
			    return false
            end

            return true
		end,

		-- Mainframe system.

		executeAbility = function( self, sim, abilityOwner, unit )
			local x0,y0 = unit:getLocation()
			local x1, y1 = abilityOwner:getLocation()

			local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )

			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), targetID= abilityOwner:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )			
			
			for i,simunit in pairs (sim:getAllUnits()) do
				if simunit:getTraits().cell_door then
					sim:dispatchEvent( simdefs.EV_UNIT_PLAY_ANIM, {unit= simunit, anim="open", sound="SpySociety/Objects/detention_door_shutdown" } )			
					sim:warpUnit( simunit, nil )
					sim:despawnUnit( simunit )
				end
			end

			local hostageList = {} 
			for i,simunit in pairs (sim:getAllUnits()) do
				if simunit:getTraits().hostage == true then
					table.insert(hostageList,simunit)
				end
			end

			for i,hostageUnit in ipairs (hostageList) do
				local cell = sim:getCell( hostageUnit:getLocation() )
				local newUnit = nil
				if hostageUnit:getTraits().rescueID then
					newUnit = unit:getPlayerOwner():hireUnit( sim, hostageUnit, cell, hostageUnit:getFacing() )					
				else
					newUnit = unit:getPlayerOwner():rescueHostage( sim, hostageUnit, cell, hostageUnit:getFacing(), unit )
				end
				if newUnit then
					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = newUnit } )
					sim:dispatchEvent(simdefs.EV_UNIT_RESCUED, { unit = newUnit } )						
				end
			end

			abilityOwner:getTraits().mainframe_status =  "inactive"
		end,

	}
return open_detention_cells