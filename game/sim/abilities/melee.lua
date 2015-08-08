local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local speechdefs = include("sim/speechdefs")
local mathutil = include( "modules/mathutil" )
local inventory = include("sim/inventory")

local melee_tooltip = class()

function melee_tooltip:init( hud, abilityOwner, abilityUser, targetUnitID )
	self._hud = hud
	self._abilityOwner = abilityOwner
	self._abilityUser = abilityUser
	self._targetUnitID = targetUnitID
end

function melee_tooltip:setPosition( wx, wy )
	self._panel:setPosition( self._hud._screen:wndToUI( wx, wy ))
end

function melee_tooltip:getScreen()
	return self._hud._screen
end

function melee_tooltip:activate( screen )
	local combat_panel = include( "hud/combat_panel" )
	local sim = self._hud._game.simCore

	self._panel = combat_panel( self._hud, self._hud._screen )
	self._panel:refreshMelee( self._abilityOwner, self._abilityUser, sim:getUnit( self._targetUnitID ))
end

function melee_tooltip:deactivate()
	self._hud._game.boardRig:getUnitRig( self._targetUnitID )._prop:setRenderFilter( nil )
	self._panel:setVisible( false )
end




local melee = 
	{
		name = STRINGS.ABILITIES.MELEE,
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_ko.png",
		usesAction = true,
		alwaysShow = true,
		getName = function( self, sim, unit )
			return self.name
		end,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			return melee_tooltip( hud, abilityOwner, abilityUser, targetUnitID )
		end,

		acquireTargets = function( self, targets, game, sim, unit )
			-- Check adjacent tiles
			local targetUnits = {}
			local cell = sim:getCell( unit:getLocation() )
			--check for pinned guards
			for i,cellUnit in ipairs(cell.units) do
				if self:isValidTarget( sim, unit, unit, cellUnit ) then
					table.insert( targetUnits,cellUnit )
				end
			end
            for i = 1, #simdefs.OFFSET_NEIGHBOURS, 2 do
    			local dx, dy = simdefs.OFFSET_NEIGHBOURS[i], simdefs.OFFSET_NEIGHBOURS[i+1]
                local targetCell = sim:getCell( cell.x + dx, cell.y + dy )
                if simquery.isConnected( sim, cell, targetCell ) then
					for _,cellUnit in ipairs( targetCell.units ) do
						if self:isValidTarget( sim, unit, unit, cellUnit ) then
							table.insert( targetUnits,cellUnit )
						end
					end
				end
			end

			return targets.unitTarget( game, targetUnits, self, unit, unit )
		end,

		isValidTarget = function( self, sim, unit, userUnit, targetUnit )
			if targetUnit == nil or targetUnit:isGhost() then
				return false
			end

			if not simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) then
				return false
			end
			
			if not targetUnit:getTraits().canKO then
				return false
			end

			local pinned, pinner = simquery.isUnitPinned(sim, targetUnit)
			if targetUnit:isKO() and pinner ~= userUnit then
				return false
			end

			return true
		end,

		canUseAbility = function( self, sim, unit, userUnit, targetID )

            local tazerUnit = simquery.getEquippedMelee( unit )
            if tazerUnit == nil then
				if sim:getTags().isTutorial then
					return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_NO_GEAR
				else
					return false
				end

			elseif tazerUnit:getTraits().cooldown and tazerUnit:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.COMBAT_PANEL_COOLDOWN,tazerUnit:getTraits().cooldown), STRINGS.UI.COMBAT_PANEL_COOLDOWN_2			
			elseif tazerUnit:getTraits().usesCharges and tazerUnit:getTraits().charges < 1 then
				return false, STRINGS.UI.COMBAT_PANEL_NEED_CHARGES, STRINGS.UI.COMBAT_PANEL_NEED_CHARGES_2			
			end				


			if unit:getAP() < 1 then 
				return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_NO_ATTACK
			end 

			if targetID then
				local targetUnit = sim:getUnit( targetID )
				local pinning, pinnee = simquery.isUnitPinning(sim, userUnit)
				if pinning and pinnee ~= targetUnit then
					return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_PINNING
				end

				if not self:isValidTarget( sim, unit, userUnit, targetUnit ) then
					return false, STRINGS.UI.REASON.INVALID_TARGET 
				end
                if not simquery.canUnitReach( sim, userUnit, targetUnit:getLocation() ) then
				    return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_NO_RANGE
			    end

				if not sim:getParams().difficultyOptions.meleeFromFront and not targetUnit:getTraits().modifyingExit and not targetUnit:getTraits().turning and not targetUnit:getTraits().movePath and sim:canUnitSeeUnit( targetUnit, userUnit ) then
					return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_SEEN
				end

				local dmg = simquery.calculateMeleeDamage(sim,  simquery.getEquippedMelee( userUnit ), targetUnit)
				if dmg <= 0 and targetUnit:getArmor() > 0 then
					return false, STRINGS.UI.COMBAT_PANEL_ARMORED
				end	

				if tazerUnit:getTraits().armorPWRcost and  unit:getPlayerOwner():getCpus() < tazerUnit:getTraits().armorPWRcost * targetUnit:getArmor() then
					return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_NO_PWR, STRINGS.UI.FLY_TXT.NOT_ENOUGH_PWR
				end							
			end
			
			if tazerUnit:getTraits().pwrCost and  unit:getPlayerOwner():getCpus() < tazerUnit:getTraits().pwrCost then
				return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_NO_PWR, STRINGS.UI.FLY_TXT.NOT_ENOUGH_PWR
			end				

			return true
		end,

		executeAbility = function( self, sim, unit, userUnit, target )
			local targetUnit = sim:getUnit(target)

			local x0,y0 = unit:getLocation()
			local x1,y1 = targetUnit:getLocation()
			local distance = mathutil.dist2d( x0, y0, x1, y1 )
			local tazer = simquery.getEquippedMelee(unit)

			if distance > 1 then 
				local cell = simquery.findNearestEmptyCell( sim, x0, y0, targetUnit )
				sim:warpUnit( targetUnit, cell )
				x1,y1 = targetUnit:getLocation()
			end

			local dir = simquery.getDirectionFromDelta(x1-x0,y1-y0)
			unit:setFacing(dir)

			if not unit:isValid() then
				return
			end
			unit:setInvisible( false )
			unit:setDisguise(false)
			if not unit:isValid() then
				return
			end

			

			sim:emitSpeech( unit, speechdefs.EVENT_ATTACK_MELEE )		

			local meleeDamage = simquery.calculateMeleeDamage(sim, simquery.getEquippedMelee( userUnit ), targetUnit)
			local pinning, pinnee = simquery.isUnitPinning(sim, userUnit)
			if pinning and pinnee ~= targetUnit then
				pinning = false
			end
			local grapple = not userUnit:getPlayerOwner():isNPC() and meleeDamage > 0 and not pinning
			local lethal = false


			if simquery.getEquippedMelee( userUnit ):getTraits().lethalMelee then
				grapple = false
				lethal = true
			end

			if grapple then
				targetUnit:getTraits().grappler = unit:getID()
				sim:refreshUnitLOS( targetUnit )
                targetUnit:destroyTab()
			end

			sim:dispatchEvent( simdefs.EV_UNIT_MELEE, { unit = unit, targetUnit = targetUnit, grapple = grapple, pinning = pinning, lethal = lethal} )	

			local facing = (unit:getFacing() + 4) % simdefs.DIR_MAX
			if grapple == true then
				targetUnit:getTraits().grappler = nil
				unit:setFacing(facing)
				targetUnit:setFacing(facing)
			end
			if lethal == true then
				unit:setFacing(facing)
			end
							
			if meleeDamage > 0 then
				if lethal == true then
					targetUnit:killUnit(sim)
				else
					local koTime = math.max( 0, meleeDamage )
					if tazer:getTraits().drainsAllPWR then 
						local player = unit:getPlayerOwner()
						local cpus = player:getCpus()
						player:addCPUs( -cpus )
						local x0, y0 = unit:getLocation()
						sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=util.sformat(STRINGS.UI.FLY_TXT.MINUS_PWR, cpus), x=x0,y=y0, color={r=163/255,g=243/255,b=248/255,a=1},} )
					end 
					if unit:isPC() and not pinning then
                        local hadSight = targetUnit:getTraits().hasSight
                        targetUnit:getTraits().hasSight = nil
						sim:warpUnit( targetUnit, sim:getCell(unit:getLocation()), targetUnit:getFacing())
                        targetUnit:getTraits().hasSight = hadSight
					end
					targetUnit:setKO( sim, koTime )
					if pinning then
						sim:dispatchEvent( simdefs.EV_UNIT_HIT, {unit = targetUnit, taze=true} )
					end
					targetUnit:getTraits().lastHit = { x=x0, y=y0, unit=unit }

					if unit:getTraits().convertKOtoPWR then

						unit:getPlayerOwner():addCPUs(koTime, sim, x0,y0 )
						sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(unit:getTraits().convertKOtoPWR, koTime), x=x0,y=y0, color=cdefs.AUGMENT_TXT_COLOR} )
					end

				end

				if unit:countAugments( "augment_predictive_brawling" ) > 0 then
					local BRAWLING_BONUS = 6
					if unit:getPlayerOwner() ~= sim:getCurrentPlayer() then
						if not unit:getTraits().floatTxtQue then
							unit:getTraits().floatTxtQue = {}
						end
						table.insert(unit:getTraits().floatTxtQue,{txt=util.sformat(STRINGS.UI.FLY_TXT.PREDICTIVE_BRAWLING,BRAWLING_BONUS),color={r=1,g=1,b=41/255,a=1}})
					else
						sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = unit } )
						sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(STRINGS.UI.FLY_TXT.PREDICTIVE_BRAWLING,BRAWLING_BONUS),x=x0,y=y0,color={r=1,g=1,b=41/255,a=1}} ) 
					end
					unit:addMP( BRAWLING_BONUS )
				end

				if tazer:getTraits().armorPWRcost and targetUnit:getArmor() then
					tazer:getPlayerOwner():addCPUs( -(tazer:getTraits().armorPWRcost * targetUnit:getArmor()), sim, x1,y1)	
				end

				inventory.useItem( sim, userUnit, tazer )

				if unit:getTraits().tempMeleeBoost then
					unit:getTraits().tempMeleeBoost = 0
				end
			end

			if meleeDamage <= 0 or (grapple == false and lethal == false and pinning == false) then
				sim:dispatchEvent( simdefs.EV_UNIT_HIT, {unit = targetUnit, result = 0} )
			end
			if grapple then
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, {unit = unit} )
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, {unit = targetUnit} )
			end

			sim:dispatchEvent( simdefs.EV_UNIT_MELEE, { finishMelee=true })
			
			sim:triggerEvent(simdefs.TRG_UNIT_HIT, {targetUnit=targetUnit, sourceUnit=unit, x=x1, y=y1, melee=true})
		
			unit:useAP( sim )
		end,
	}
return melee
