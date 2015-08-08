local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local use_injection = include( "sim/abilities/use_injection" )

local use_medgel = util.extend( use_injection )
	{
		name = STRINGS.ABILITIES.REVIVE,
		proxy = 1,
		createToolTip = function(  self,sim, abilityOwner, abilityUser, targetID )

			local targetUnit = sim:getUnit(targetID)
			return abilityutil.formatToolTip(string.format(STRINGS.ABILITIES.REVIVE_NAME,targetUnit:getName()), string.format(STRINGS.ABILITIES.REVIVE_DESC,abilityOwner:getName()), simdefs.DEFAULT_COST)
		end,

		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_medigel_small.png",


		isTarget = function( self, sim, userUnit, targetUnit )
			local isKOed = (targetUnit:isKO() and not simquery.isSameLocation( userUnit, targetUnit ))
			local isSameTeam = userUnit:getPlayerOwner() == targetUnit:getPlayerOwner()						

			return isKOed and isSameTeam and not simquery.isUnitCellFull( sim, targetUnit ) and not simquery.isUnitDragged( sim, targetUnit ) 
		end,

		doInjection = function( self, sim, unit, userUnit, target )
			local x1,y1 = target:getLocation()
			if target:isKO() then
				if target:isDead() then
					assert( target:getWounds() >= target:getTraits().woundsMax ) -- Cause they're dead, should have more wounds than max
					target:getTraits().dead = nil
					target:addWounds( target:getTraits().woundsMax - target:getWounds() - 1 )			
				end

				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.REVIVED,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )

				target:setKO( sim, nil )
		        target:getTraits().mp = math.max( 0, target:getMPMax() - (target:getTraits().overloadCount or 0) )

				sim:emitSpeech( target, speechdefs.EVENT_REVIVED )
			end
		end,
	}
return use_medgel
