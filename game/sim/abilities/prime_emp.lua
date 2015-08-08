local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local unitdefs = include("sim/unitdefs")
local simfactory = include( "sim/simfactory" )
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )


local emp_tooltip = class( abilityutil.hotkey_tooltip )

function emp_tooltip:init( hud, unit, abilityOwner, ... )
	abilityutil.hotkey_tooltip.init( self, ... )
	self._game = hud._game
	self._unit = unit
    self._emp = abilityOwner
	self._range = abilityOwner:getTraits().range
end

function emp_tooltip:activate( screen )
	abilityutil.hotkey_tooltip.activate( self, screen )

	local x0, y0 = self._unit:getLocation()
	local coords = simquery.rasterCircle( self._game.simCore, x0, y0, self._range )
	self._hiliteID = self._game.boardRig:hiliteCells( coords, {0.2,0.2,0.2,0.2} )

    local targets = self._emp:getTargets( x0, y0 )
    for i, target in ipairs(targets) do
        self._game.boardRig:getUnitRig( target:getID() ):getProp():setRenderFilter( cdefs.RENDER_FILTERS["focus_target"] )
    end
end

function emp_tooltip:deactivate()
	abilityutil.hotkey_tooltip.deactivate( self )
	self._game.boardRig:unhiliteCells( self._hiliteID )
	self._hiliteID = nil

    local targets = self._emp:getTargets( self._unit:getLocation() )
    for i, target in ipairs(targets) do
        self._game.boardRig:getUnitRig( target:getID() ):refreshRenderFilter()
    end
end    

local prime_emp = 
	{
		name = STRINGS.ABILITIES.PRIME_EMP,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			if abilityOwner:getTraits().flash_pack then
				return emp_tooltip( hud, abilityUser, abilityOwner, self, sim, abilityOwner, STRINGS.ABILITIES.PRIME_FLASH_PACK_DESC )
			else
				return emp_tooltip( hud, abilityUser, abilityOwner, self, sim, abilityOwner, STRINGS.ABILITIES.PRIME_EMP_DESC )
			end
		end,

		usesAction = true,
		alwaysShow = true,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",

		getName = function( self, sim, unit )
			if unit:getTraits().flash_pack then
				return STRINGS.ABILITIES.PRIME_FLASH_PACK
			else
				return STRINGS.ABILITIES.PRIME_EMP
			end
		end,

		canUseAbility = function( self, sim, abilityOwner, abilityUser )
			if not abilityUser then
				return false
			end

			if abilityOwner:getTraits().primed then
				return false, STRINGS.UI.REASON.ALREADY_PRIMED
			end

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end
			if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end				

            local ok, reason = abilityutil.checkRequirements( abilityOwner, abilityUser )
            if not ok then 
                return false, reason
            end

			local cell = sim:getCell( abilityOwner:getLocation() )
			if cell then
				-- On the ground.
				return cell == sim:getCell( abilityUser:getLocation() )
			else
				-- Carried. (can be dropped)
				if array.find( abilityUser:getChildren(), abilityOwner ) ~= nil then
					return true
				end
			end

		end,
		
		executeAbility = function( self, sim, unit, userUnit )
			local cell = sim:getCell( unit:getLocation() ) or sim:getCell( userUnit:getLocation() )
			local newUnit = simfactory.createUnit( unitdefs.lookupTemplate( unit:getUnitData().id ), sim )
			sim:dispatchEvent( simdefs.EV_UNIT_PICKUP, { unitID = userUnit:getID() } )	

			sim:spawnUnit( newUnit )
			sim:warpUnit( newUnit, cell )
			newUnit:removeAbility(sim, "carryable")

			sim:emitSound( simdefs.SOUND_ITEM_PUTDOWN, cell.x, cell.y, userUnit)
			sim:emitSound( simdefs.SOUND_PRIME_EMP, cell.x, cell.y, userUnit)
			
			newUnit:getTraits().primed = true

			if newUnit:getTraits().trigger_mainframe then
				newUnit:getTraits().mainframe_item = true
				newUnit:getTraits().mainframe_status = "on"
				newUnit:setPlayerOwner( userUnit:getPlayerOwner() )
			end
			
			userUnit:resetAllAiming()

			inventory.useItem( sim, userUnit, unit )
			
			if userUnit:isValid() then
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )		
			end
		end,
	}
return prime_emp