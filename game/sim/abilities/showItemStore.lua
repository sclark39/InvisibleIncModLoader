local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local showItemStore = 
	{
		name = STRINGS.ABILITIES.STORE, 

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,

		onTooltip = abilityutil.onAbilityTooltip,
		
		--profile_icon = "gui/items/icon-action_open-safe.png",
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",

		proxy = true,
		alwaysShow = true,

		canUseAbility = function( self, sim, unit, userUnit )

			if unit:getPlayerOwner() ~= userUnit:getPlayerOwner() then
				return false, STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
			end

			if unit:getTraits().mainframe_status ~= "active" then
				return false, STRINGS.UI.REASON.OUT_OF_ORDER
			end

            if unit:isEmpty() then
                return false, STRINGS.UI.REASON.OUT_OF_STOCK
            end

            if userUnit:getTraits().inventoryMaxSize == nil then
                return false, STRINGS.UI.REASON.NO_INVENTORY
            end

            return simquery.canUnitReach( sim, userUnit, unit:getLocation() )
		end,

		executeAbility = function ( self, sim, unit, userUnit)
			assert( not unit:isGhost() )
			-- Create the store inventory.
			local overload = nil
			if unit:getTraits().inventoryMaxSize then
				math.max( userUnit:getInventoryCount() - userUnit:getTraits().inventoryMaxSize  ,0)
			end	
            sim:dispatchEvent( simdefs.EV_ITEMS_PANEL, { shopUnit = unit, shopperUnit = userUnit, overload = overload } )
            sim:triggerEvent(simdefs.TRG_CLOSE_NANOFAB, { unit=unit, sourceUnit=userUnit } )

            unit:clearBuyback()
		end, 

	}
return showItemStore