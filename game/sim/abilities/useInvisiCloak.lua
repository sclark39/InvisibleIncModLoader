local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local inventory = include("sim/inventory")

-------------------------------------------------------------
--
local function getTargetUnits( sim, userUnit, x0, y0, range )
    local units = {}
	local cells = simquery.fillCircle( sim, x0, y0, range, 0)

	for i, cell in ipairs(cells) do
		for i, cellUnit in ipairs( cell.units ) do
			if not simquery.isEnemyAgent(userUnit:getPlayerOwner(), cellUnit) and simquery.isAgent( cellUnit ) and cellUnit ~= userUnit then
                table.insert( units, cellUnit )
			end
		end
	end
    return units
end

-------------------------------------------------------------
-- Special cloak tooltip for showing range

local cloak_tooltip = class( abilityutil.hotkey_tooltip )

function cloak_tooltip:init( hud, unit, range, ... )
	abilityutil.hotkey_tooltip.init( self, ... )
	self._game = hud._game
	self._unit = unit
	self._range = range
    if range then
        local x0, y0 = unit:getLocation() 
        self._targets = getTargetUnits( hud._game.simCore, unit, x0, y0, range)
    end
end

function cloak_tooltip:activate( screen )
	abilityutil.hotkey_tooltip.activate( self, screen )
	if self._range then
		local x0, y0 = self._unit:getLocation()
		local coords = simquery.rasterCircle( self._game.simCore, x0, y0, self._range )
		self._hiliteID = self._game.boardRig:hiliteCells( coords, cdefs.HILITE_TARGET_COLOR )
        for i, target in ipairs( self._targets ) do
            self._game.boardRig:getUnitRig( target:getID() ):getProp():setRenderFilter( cdefs.RENDER_FILTERS["focus_target"] )
        end
	end
end

function cloak_tooltip:deactivate()
	abilityutil.hotkey_tooltip.deactivate( self )
	if self._range then
		self._game.boardRig:unhiliteCells( self._hiliteID )	
		self._hiliteID = nil
        for i, target in ipairs( self._targets ) do
            self._game.boardRig:getUnitRig( target:getID() ):refreshRenderFilter()
        end
	end
end


local useInvisiCloak =
	{
		name = STRINGS.ABILITIES.CLOAK,
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			return cloak_tooltip( hud, abilityUser, abilityOwner:getTraits().range, self, sim, abilityOwner, STRINGS.ABILITIES.CLOAK_DESC )
		end,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
		alwaysShow = true,
		getName = function( self, sim, unit )
			if unit:getTraits().cooldown == 0 then
				return STRINGS.ABILITIES.CLOAK_USE
			else 
				if unit:getTraits().duration > 0 then
					return string.format(STRINGS.ABILITIES.CLOAK_DURATION,unit:getTraits().duration)
				else
					return string.format(STRINGS.ABILITIES.CLOAK_COOLDOWN,unit:getTraits().cooldown)
				end
			end
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

			if not unit:getTraits().cloakInVision then 
				if sim:canPlayerSeeUnit( sim:getNPC(), userUnit ) then 
					return false, STRINGS.UI.REASON.CANT_CLOAK_IN_VISION
				end
			end
					
			return abilityutil.checkRequirements( unit, userUnit )
		end,

		executeAbility = function( self, sim, unit )
			local userUnit = unit:getUnitOwner()

			userUnit:setInvisible(true, unit:getTraits().duration)
			userUnit:resetAllAiming()

			if unit:getTraits().cloakDistanceMax then
				userUnit:getTraits().cloakDistance = unit:getTraits().cloakDistanceMax
			end

			if unit:getTraits().range then
                local x0, y0 = userUnit:getLocation()
                local units = getTargetUnits( sim, userUnit, x0, y0, unit:getTraits().range )
                for i, cellUnit in ipairs( units ) do
                    cellUnit:setInvisible( true, unit:getTraits().duration )
                end
			end
			
			inventory.useItem( sim, userUnit, unit )

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )

			sim:processReactions(userUnit)			
		end,
	}
return useInvisiCloak