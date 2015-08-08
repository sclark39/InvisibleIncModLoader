local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local carryable =
	{
		name = STRINGS.ABILITIES.CARRYABLE,
		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.CARRYABLE, STRINGS.ABILITIES.CARRYABLE_DESC, 0)
		end,

		ghostable = true,
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_drop_give_small.png",

		--getName = function( self, sim, unit, userUnit )
		getName = function( self, sim, abilityOwner, abilityUser )
			if abilityOwner:getUnitOwner() ~= nil then
				 return STRINGS.ABILITIES.DROP
			else
				return string.format(STRINGS.ABILITIES.PICKUP,abilityOwner:getName())
			end
		end,

		canUseAbility = function( self, sim, abilityOwner, abilityUser )

			if abilityOwner:getTraits().cantdrop == true then
				return false				
			end

			if not abilityUser or abilityUser == abilityOwner then
				return false
			end

			if abilityUser:getTraits().isDrone then
				return false
			end

			local cell = sim:getCell( abilityOwner:getLocation() )
			if cell then
				if sim:getCell( abilityUser:getLocation() ) ~= cell then
					return false
				end		
	
				if abilityUser:getInventoryCount() >= (abilityUser:getTraits().inventoryMaxSize or 0) then
					return false, STRINGS.UI.REASON.INVENTORY_FULL
				end
			else
				-- Carried. (can be dropped/given)
				if not array.find( abilityUser:getChildren(), abilityOwner ) then
					return false, STRINGS.UI.REASON.NOT_CARRIED
				end
				if abilityOwner:getTraits().impass or abilityOwner:getTraits().dynamicImpass then
					return false,  STRINGS.UI.REASON.CANT_DROP
				end
			end

			return true
		end,
		
		executeAbility = function( self, sim, unit, userUnit )
			local cell = sim:getCell( unit:getLocation() )
			if cell then
				-- Pickup
				inventory.pickupItem( sim, userUnit, unit )
				sim:dispatchEvent( simdefs.EV_UNIT_PICKUP, { unitID = userUnit:getID() } )	

			else
				-- Drop
				inventory.dropItem( sim, userUnit, unit )
				local x0, y0 = userUnit:getLocation()			
				sim:emitSound( simdefs.SOUND_ITEM_PUTDOWN, x0, y0, userUnit)
				sim:dispatchEvent( simdefs.EV_UNIT_PICKUP, { unitID = userUnit:getID() } )	
			end

			userUnit:resetAllAiming()
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit } )
		end,
	}
return carryable