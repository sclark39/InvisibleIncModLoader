local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )

local scandevice =
{
	name = STRINGS.ABILITIES.SCAN_DEVICE,
	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
    proxy = true,

	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		return abilityutil.formatToolTip(STRINGS.ABILITIES.SCAN, string.format( STRINGS.ABILITIES.TOOLTIPS.SCAN, targetUnit:getName() ))
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.ABILITIES.SCAN_DEVICE
	end,

    getProfileIcon = function( self, sim, abilityOwner )
        return abilityOwner:getUnitData().profile_icon or self.profile_icon
    end,

	acquireTargets = function( self, targets, game, sim, unit )
		local userUnit = unit:getUnitOwner()
		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 
        assert( userUnit, tostring(unit and unit:getName())..", "..tostring(unit:getLocation()) )
		local cell = sim:getCell( userUnit:getLocation() )
		local units = {}
		for dir, exit in pairs(cell.exits) do
			for _, cellUnit in ipairs( exit.cell.units ) do
				if (cellUnit:getTraits().mainframe_ice or 0) > 0 and ( cellUnit:getTraits().mainframe_program or sim:getHideDaemons()) and not cellUnit:getTraits().daemon_sniffed  then
					table.insert( units, cellUnit )
				end
			end
		end

		return targets.unitTarget( game, units, self, unit, userUnit )
	end,
		
	canUseAbility = function( self, sim, unit )

		-- Must have a user owner.
		local userUnit = unit:getUnitOwner()

		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 

		if not userUnit then
			return false
		end
		-- has a target in range
		local cell = sim:getCell( userUnit:getLocation() )
		local count = 0
		for dir, exit in pairs(cell.exits) do

			local unit = array.findIf( exit.cell.units, function( u ) return u:getTraits().mainframe_program end )
			if unit then
				count = count + 1
			end					
		end

		if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
		end

		if count == 0 and not sim:getHideDaemons() then
			return false, STRINGS.UI.REASON.NO_DAEMONS
		end

		return abilityutil.checkRequirements( unit, userUnit)
	end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local mainframe = include( "sim/mainframe" )
		local userUnit = unit:getUnitOwner()
		local target = sim:getUnit(target)	

		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 		
			
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = target:getLocation()
  		local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 

		sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), facing = newFacing, sound="SpySociety/Actions/use_scanchip", soundFrame=10} )
		sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = target, ice = target:getTraits().mainframe_ice, delta = 0} )			
		local delay = 0.5
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)

		if not target:getTraits().mainframe_program then
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_HUD_INCIDENT_NEGATIVE.path )
        mission_util.showDialog( sim, STRINGS.UI.DIALOGS.NO_DAEMON_TITLE, STRINGS.UI.DIALOGS.NO_DAEMON_BODY )
			target:getTraits().daemon_sniffed = true	
			sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = target, ice = target:getTraits().mainframe_ice, delta = 0} )	
		else
			target:getTraits().daemon_sniffed = true	
			sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = target, ice = target:getTraits().mainframe_ice, delta = 0} )		
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_DAEMON_REVEAL.path )
		end

		inventory.useItem( sim, userUnit, unit )

		if userUnit:isValid() then
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
		end

	end,
}

return scandevice