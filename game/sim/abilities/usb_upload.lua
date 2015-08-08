local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local usb_upload = 
	{
		name = STRINGS.ABILITIES.USABLE,

		getName = function( self, sim, unit, userUnit )
			return string.format("Upload virus to ",unit:getName())
		end,

		--profile_icon = "gui/items/icon-action_open-safe.png",
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",		
		proxy = true,
		alwaysShow = true,
		ghostable = true,

		canUseAbility = function( self, sim, unit, userUnit )			
			if not simquery.canUnitReach( sim, userUnit, unit:getLocation() ) then
				return false 
			end 

			if unit:getTraits().mainframe_status == "inactive" then 
				return false 
			end 
			
			local hasVirus = false

			for i,childUnit in ipairs( userUnit:getChildren() ) do
				if childUnit:getTraits().virus_drive then 
					hasVirus = true
				end
			end

			if not hasVirus then 
				return false 
			end

			return true
		end,

		executeAbility = function ( self, sim, unit, userUnit )
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = unit:getLocation()	
			local facing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), facing = facing, sound = simdefs.SOUNDPATH_SAFE_OPEN, soundFrame = 1 } )
			unit:getTraits().mainframe_status = "inactive"
			userUnit:setInvisible(false)

			sim:triggerEvent( "usb_upload" )
		end,
	}
return usb_upload