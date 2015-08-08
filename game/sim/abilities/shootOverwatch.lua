local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local inventory = include("sim/inventory")
local serverdefs = include( "modules/serverdefs" )

local shootOverwatch =
	{
		name = STRINGS.ABILITIES.OVERWATCH_SHOOT,
		createToolTip = function( self )
			return abilityutil.formatToolTip( STRINGS.ABILITIES.OVERWATCH_SHOOT, STRINGS.ABILITIES.OVERWATCH_SHOOT_DESC, 1 )
		end,

		getName = function( self, sim, unit )
			return self.name
		end,

		onDespawnAbility = function( self, sim, unit )
            if unit:isAiming() then
			    sim:removeTrigger( simdefs.TRG_OVERWATCH, self )
            end
		end,
		
		onTrigger = function( self, sim, evType, evData, userUnit )
            assert( evType == simdefs.TRG_OVERWATCH and userUnit )
            
            if userUnit:isAiming() or userUnit:getTraits().skipOverwatch then
            	
            	if userUnit:getTraits().skipOverwatch then
            		userUnit:setAiming(false)
            	end 

				local targetUnit = evData
				local unit = simquery.getEquippedGun( userUnit )
				local userPlayer = unit and unit:getPlayerOwner()

				local legitTarget = true
			    if targetUnit then
	            	local shot =  simquery.calculateShotSuccess( sim, userUnit, targetUnit, unit )
                    if not shot then
                        legitTarget = false

                    else
                        if shot.armorBlocked == true then
		                    legitTarget = false
		                end

		                if shot.ko and not targetUnit:getTraits().canKO then 
						    legitTarget = false
					    end 
                    end
				end				

				if unit and targetUnit and not targetUnit:isKO() and legitTarget then
					if simquery.isEnemyAgent( userPlayer, targetUnit ) and self:canUseAbility( sim, userUnit ) and sim:canUnitSeeUnit( userUnit, targetUnit ) then											
						self:executeAbility( sim, unit, userUnit, targetUnit )			
					end
				end
			end
		end,

		canUseAbility = function( self, sim, userUnit ) 
			local unit = simquery.getEquippedGun( userUnit )
			if not unit then
				return false, STRINGS.UI.REASON.NO_WEAPON
			end

			return true
		end,

		executeAbility = function( self, sim, unit, userUnit, targetUnit)
			local x1, y1 = targetUnit:getLocation()

			userUnit:setInvisible(false)
			userUnit:setDisguise(false)
			local oldFacing = userUnit:getFacing()
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = targetUnit:getLocation()
			local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0)

			if targetUnit:getPlayerOwner() then
				targetUnit:getPlayerOwner():glimpseUnit( sim, userUnit:getID() )
				local lastKnownUnit = targetUnit:getPlayerOwner():getLastKnownUnit(sim,userUnit:getID())

				if  lastKnownUnit:isGhost() then
					lastKnownUnit:getTraits().isAiming = true   -- put the ghost into aiming animation
					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =userUnit } )	-- refresh it so it shows up				
				end
			end

			if userUnit:getBrain() and userUnit:getBrain():getTarget() ~= targetUnit then
				userUnit:getBrain():setTarget(targetUnit)
			end

            local ok, reason, floatTxt = abilityutil.canConsumeAmmo( sim, unit, true )
            if not ok then
            	if floatTxt then
            		local displayPwr = true  
            		if unit:getTraits().nopwr_guards then 
            			for _, guardID in ipairs(unit:getTraits().nopwr_guards) do 
            				if guardID == targetUnit:getID() then 
            					displayPwr = false 
            				end 
            			end 
            		end 
            		if displayPwr then 
            			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, { txt = floatTxt, unit = userUnit, color={r=1,g=0,b=0,a=1}, skipQue=true } )
            			if unit:getTraits().nopwr_guards then 
            				table.insert( unit:getTraits().nopwr_guards, targetUnit:getID() )
            			end 
            		end
            		return 
            	else 
	                sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, { txt = reason, unit = userUnit, color={r=1,g=0,b=0,a=1}} )
	                return
	            end
            else
            	inventory.useItem( sim, userUnit, unit )
            end

			sim:dispatchEvent( simdefs.EV_UNIT_START_SHOOTING, { unitID = userUnit:getID(), newFacing = newFacing, oldFacing = oldFacing, overwatch = true, targetUnitID = targetUnit:getID() } )	

			local dmgt = abilityutil.createShotDamage( unit, userUnit )
			dmgt.shotType = "overwatch"

			sim:tryShootAt( userUnit, targetUnit, dmgt,unit )				

			if userUnit:isValid() then
				simquery.suggestAgentFacing(userUnit, newFacing)
               	userUnit:resetAllAiming()

				if unit:getTraits().spawnsDaemon then 
					--sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=STRINGS.ITEMS.DARTGUN_MONST3R, x=x0,y=y0, color={r=163/255,g=243/255,b=248/255,a=1},} )
					local programList = serverdefs.OMNI_PROGRAM_LIST

					if sim and sim:getParams().difficultyOptions.daemonQuantity == "LESS" then
						programList = serverdefs.OMNI_PROGRAM_LIST_EASY
					end

					local daemon = programList[sim:nextRand(1, #programList)]
					sim:getNPC():addMainframeAbility( sim, daemon, nil, 0 )
				end 

			end
			sim:dispatchEvent( simdefs.EV_UNIT_STOP_SHOOTING, { unitID = userUnit:getID(), facing=newFacing } )		

		end
	}

return shootOverwatch

