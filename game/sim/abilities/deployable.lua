local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local deployable =
	{
		name = STRINGS.ABILITIES.DEPLOYABLE,
		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.DEPLOYABLE, STRINGS.ABILITIES.DEPLOYABLE_DESC, 0)
		end,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
		alwaysShow = true,

		getName = function( self, sim, unit, userUnit )
			return STRINGS.ABILITIES.DEPLOY
		end,


		canUseAbility = function( self, sim, abilityOwner, abilityUser )

			if abilityOwner == abilityUser then
				return false
			end

			local cell = sim:getCell(abilityUser:getLocation() )

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end
			
			if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end				

			if cell then
				for i,unit in ipairs(cell.units) do
					if unit:hasAbility("deployable") and unit:getTraits().deployed then
						return false, STRINGS.UI.REASON.ALREADY_DEPLOYED
					end
				end
			end

			if array.find( abilityUser:getChildren(), abilityOwner ) == nil then
				return false, STRINGS.UI.REASON.NOT_CARRIED
			end
            
			return abilityutil.checkRequirements( abilityOwner, abilityUser )
		end,
		
		executeAbility = function( self, sim, abilityOwner, abilityUser )
			local cell = sim:getCell( abilityUser:getLocation() )
			assert( cell )
			assert( not abilityOwner:getTraits().equipped )

			abilityUser:removeChild( abilityOwner )

			-- Deployed items are owned by the user unit's player
			abilityOwner:setPlayerOwner( abilityUser:getPlayerOwner() )
			abilityOwner:getTraits().deployed = true

			local facing = simquery.getReverseDirection(abilityUser:getFacing() )
			if facing % 2 ~= 0 then
				facing = simquery.addFacing(facing, 1)
			end
			sim:emitSound( simdefs.SOUND_ITEM_PUTDOWN, cell.x, cell.y, abilityUser )		
			sim:dispatchEvent( simdefs.EV_UNIT_PICKUP, { unitID = abilityUser:getID(), facing=simquery.getReverseDirection(facing) } )	
			abilityOwner:setFacing( facing  ) 
			sim:warpUnit( abilityOwner, cell )
			sim:dispatchEvent(simdefs.EV_UNIT_DEPLOY, {unit=abilityOwner, x=cell.x,y=cell.y})

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldownMax then 
				abilityOwner:getTraits().cooldown = abilityOwner:getTraits().cooldownMax
			end 

			if abilityOwner:getTraits().mainframe_icon_on_deploy then
				abilityOwner:getTraits().mainframe_icon = true
			end

			sim:triggerEvent( simdefs.TRG_UNIT_DEPLOYED, { unit = abilityOwner })

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = abilityOwner } )
		end,
	}
return deployable
