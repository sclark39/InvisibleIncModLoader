local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local 	open_security_boxes = 
	{
		name = STRINGS.ABILITIES.OPEN_SECURE_BOXES,

		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.OPEN_SECURE_BOXES, STRINGS.ABILITIES.OPEN_SECURE_BOXES_DESC )
		end,

		proxy = true,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
			return self.name
		end,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",

		isTarget = function( self, abilityOwner, unit, targetUnit )
		
			if targetUnit:getTraits().mainframe_status ~= "active" then
				return false
			end

			return true
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isTarget( abilityOwner, unit, targetUnit ) and targetUnit:getTraits().open_secure_boxes and simquery.canUnitReach( sim, unit, x1, y1 ) then
					table.insert( units, targetUnit )
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )
			local userUnit = abilityOwner:getUnitOwner()

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
			end	

			if  abilityOwner:getTraits().mainframe_ice > 0 then 
				return false,  STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
			end

			return abilityutil.checkRequirements( abilityOwner, userUnit )
		end,

		-- Mainframe system.

		executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )
		
			local targetUnit = sim:getUnit( targetUnitID )			
			local x0,y0 = unit:getLocation()
			local x1, y1 = targetUnit:getLocation()

			local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )

			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), targetID= targetUnitID, facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )			
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HUD/mainframe/node_capture" )
			for i,simunit in pairs (sim:getAllUnits()) do
				if simunit:getTraits().security_box then
					simunit:getTraits().security_box_locked = false
					simunit:setPlayerOwner( unit:getPlayerOwner())

					sim:getCurrentPlayer():glimpseUnit( sim, simunit:getID() )
					
					
					sim:dispatchEvent( simdefs.EV_UNIT_CAPTURE, { unit = simunit, nosound = true} )	
				end
			end


			abilityOwner:getTraits().mainframe_status =  "inactive"
		end,

	}
return open_security_boxes