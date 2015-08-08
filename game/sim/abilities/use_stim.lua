local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local use_injection = include( "sim/abilities/use_injection" )
local inventory = include("sim/inventory")

local use_stim = util.extend( use_injection )
	{
		name = STRINGS.ABILITIES.STIM,
		createToolTip = function( self )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.STIM, STRINGS.ABILITIES.STIM_DESC, simdefs.DEFAULT_COST)
		end,

		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_stim_small.png",

		isTarget = function( self, sim, userUnit, targetUnit )
			local canUse = targetUnit:getAP() or targetUnit:getMP()						
			canUse = canUse and targetUnit:getPlayerOwner() == userUnit:getPlayerOwner()
			canUse = canUse and not targetUnit:isDead()
			canUse = canUse and simquery.isAgent(targetUnit)
			return canUse
		end,
		
		doInjection = function( self, sim, unit, userUnit, target )
			local x1,y1 = target:getLocation()
			if target:isKO() then
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.REVIVED,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )

				target:setKO( sim, nil )

				sim:emitSpeech( target, speechdefs.EVENT_REVIVED )
			end
 			
			if unit:getTraits().combatRestored then 
				target:getTraits().ap = target:getTraits().apMax	
			end 

			if unit:getTraits().unlimitedAttacks then
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.AMPED,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} ) 
				target:getTraits().ap = target:getTraits().apMax
				target:getTraits().unlimitedAttacks = true
			end 

			target:getTraits().mp =target:getTraits().mp + unit:getTraits().mpRestored

			sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = userUnit } )
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.MOVEMENT_BOOSTED,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )
			
			if not sim:isVersion("0.17.5") then
				inventory.useItem( sim, userUnit, unit )
			end

			local cnt, augments = target:countAugments( "augment_subdermal_cloak" )
			if cnt > 0 then
				local pwrCost = augments[1]:getTraits().pwrCost
				if target:getPlayerOwner():getCpus() >= pwrCost then
					target:setInvisible(true, 1)	
		    		target:getPlayerOwner():addCPUs( -pwrCost, sim, x1, y1)	
		    	end
			end

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target  } )
		end,
	}
return use_stim