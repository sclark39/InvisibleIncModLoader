local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local speechdefs = include("sim/speechdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local breakDoor = 
	{

		name = STRINGS.ABILITIES.BREAK_DOOR,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_sneak_small.png",
		
		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.BREAK_DOOR, STRINGS.ABILITIES.BREAK_DOOR_DESC, 0)
		end,

		canUseAbility = function( self, sim, unit, userUnit, cell, direction)
			if not simquery.isAgent(unit) then
				return false
			end

			if unit:getPlayerOwner() and unit:getPlayerOwner():isPC() and unit:getMP() < 1 then
				return false, string.format(STRINGS.UI.REASON.REQUIRES_AP,1)
			end

			local fromCell = cell or sim:getCell( unit:getLocation() )
			local doorExit = direction and fromCell.exits[direction] or nil

			if not doorExit then
				for dir, exit in pairs(fromCell.exits) do
	                if simquery.isClosedDoor(exit) and not simquery.isSecurityExit(exit) then
	                    doorExit = exit
	                    direction = dir
					end
				end
			end

			if not doorExit then
				return false
			end

			if not simquery.canModifyExit( unit, simdefs.EXITOP_BREAK_DOOR, fromCell, direction) then
				return false
			end

			return abilityutil.checkRequirements( unit, userUnit )
		end,
		
		executeAbility = function( self, sim, unit, userUnit, cell, direction)
			unit:resetAllAiming()

			cell = cell or sim:getCell( unit:getLocation() )
			assert( cell )
			local doorExit = direction and cell.exits[direction] or nil

			if not doorExit then
				for dir, exit in pairs(cell.exits) do
	                if simquery.isClosedDoor(exit) and not simquery.isSecurityExit(exit) then
	                    doorExit, direction = exit, dir
					end
				end
			end
			assert(doorExit)
			assert( simquery.canModifyExit( unit, simdefs.EXITOP_BREAK_DOOR, cell, direction ))
			assert( simquery.canReachDoor( unit, cell, direction ))


			simquery.suggestAgentFacing(userUnit, direction)
			if userUnit:isNPC() then
				sim:emitSpeech(unit, speechdefs.HUNT_BREAKDOOR)
			end
			if not unit:getTraits().noDoorAnim then 
				sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = unit:getID(), facing = direction, exitOp=simdefs.EXITOP_BREAK_DOOR } )	
			end
			sim:getPC():glimpseUnit(sim, unit:getID() )
			sim:startTrackerQueue(true)				
			sim:startDaemonQueue()			
			sim:dispatchEvent( simdefs.EV_KO_GROUP, true )
			sim:modifyExit(cell, direction, simdefs.EXITOP_BREAK_DOOR, unit, false)
			if unit:isValid() and not unit:getTraits().noDoorAnim then
				sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = unit:getID(), facing = direction, exitOp=simdefs.EXITOP_BREAK_DOOR } )
			end
			sim:dispatchEvent( simdefs.EV_KO_GROUP, false )
			sim:startTrackerQueue(false)				
			sim:processDaemonQueue()			
			if unit:isValid() and not unit:getTraits().noDoorAnim and not unit:getTraits().interrupted then
				sim:dispatchEvent( simdefs.EV_UNIT_GUNCHECK, { unit = unit, facing = direction } )
			end

		end,
	}

return breakDoor
