local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local speechdefs = include("sim/speechdefs")
local mathutil = include( "modules/mathutil" )

local jackin =
	{
		name = STRINGS.ABILITIES.HIJACK_CONSOLE,
        proxy = true,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )
	        section:addLine( targetUnit:getName() )
			if (targetUnit:getTraits().cpus or 0) > 0 then
				if abilityOwner:getTraits().PWR_conversion then 
					section:addAbility( self:getName(sim, abilityOwner, abilityUser, targetUnitID),
						util.sformat(STRINGS.ABILITIES.HIJACK_CONSOLE_DESC_CONVERT_TO_CRED, abilityOwner:getName()), "gui/items/icon-action_hack-console.png" )
				else
					section:addAbility( self:getName(sim, abilityOwner, abilityUser, targetUnitID),
						STRINGS.ABILITIES.HIJACK_CONSOLE_DESC, "gui/items/icon-action_hack-console.png" )
				end
			end
			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )
			if targetUnit then
                local cpus, bonus = self:calculateCPUs( abilityOwner, abilityUser, targetUnit )
                if abilityOwner:getTraits().PWR_conversion then 
                	if bonus > 0 then
                		return util.sformat( STRINGS.ABILITIES.HIJACK_CONSOLE_NAMES.CONVERT_TO_CREDIT_BONUS, cpus, bonus, (cpus + bonus) * abilityOwner:getTraits().PWR_conversion  )
                	else
                		return util.sformat( STRINGS.ABILITIES.HIJACK_CONSOLE_NAMES.CONVERT_TO_CREDIT, cpus, cpus * abilityOwner:getTraits().PWR_conversion )
                	end
	            else
					if bonus > 0 then
	    				return util.sformat( STRINGS.ABILITIES.HIJACK_CONSOLE_NAMES.GET_PWR_BONUS, cpus, bonus )
	                else
	    				return util.sformat( STRINGS.ABILITIES.HIJACK_CONSOLE_NAMES.GET_PWR, cpus )
					end
				end
			else
				return string.format( STRINGS.ABILITIES.HIJACK_CONSOLE_INSTALL_VIRUS)
			end
		end,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",

        getProfileIcon = function( self, sim, abilityOwner )
            return abilityOwner:getUnitData().profile_icon or self.profile_icon
        end,

		calculateCPUs = function( self, abilityOwner, unit, targetUnit )
			local bonus = unit:getTraits().hacking_bonus or 0
            if unit ~= abilityOwner then
                bonus = bonus + (abilityOwner:getTraits().hacking_bonus or 0)
            end
			return math.ceil( targetUnit:getTraits().cpus ), bonus
		end,

		isTarget = function( self, abilityOwner, unit, targetUnit )
			if not targetUnit:getTraits().mainframe_console then
				return false
			end

			if targetUnit:getTraits().mainframe_status ~= "active" then
				return false
			end

			if (targetUnit:getTraits().cpus or 0) == 0 then
				return false
			end

			return true
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )

			local maxRange = abilityOwner:getTraits().wireless_range
			local x0, y0 = unit:getLocation()
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isTarget( abilityOwner, unit, targetUnit ) then
					local range = mathutil.dist2d( x0, y0, x1, y1 )
					if maxRange then
						-- This handles wireless jack-ins.
						if range <= maxRange then
							targetUnit = unit:getPlayerOwner():getLastKnownUnit( sim, targetUnit:getID() )
							if targetUnit:isGhost() or sim:canPlayerSeeUnit( unit:getPlayerOwner(), targetUnit ) then
								table.insert( units, targetUnit )
							end
						end
					else
						-- This handles manual jacking. (heh)
						if range <= 1 and simquery.isConnected( sim, sim:getCell( x0, y0 ), sim:getCell( x1, y1 ) ) then
							table.insert( units, targetUnit )
						end
					end
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )
            -- This is a proxy ability, but only usable if the proxy is in the inventory of the user.
            if abilityOwner ~= unit and abilityOwner:getUnitOwner() ~= unit then
                return false
            end

			local targetUnit = sim:getUnit( targetUnitID )
			if targetUnit then
				assert( self:isTarget( abilityOwner, unit, targetUnit ))
				if targetUnit:getTraits().mainframe_console_lock > 0 then
					return false, STRINGS.UI.REASON.CONSOLE_LOCKED
				end
			end
			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end	

			if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end	

			return abilityutil.checkRequirements( abilityOwner, unit )
		end,

		-- Mainframe system.

		executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )
			sim:emitSpeech( unit, speechdefs.EVENT_HIJACK )

			sim._resultTable.consoles_hacked = sim._resultTable.consoles_hacked and sim._resultTable.consoles_hacked + 1 or 1 

			if unit:getTraits().wireless_range then
				sim:dispatchEvent( simdefs.EV_UNIT_WIRELESS_SCAN, { unitID = unit:getID(), targetUnitID = targetUnitID, hijack = true } )
			end

			local targetUnit = sim:getUnit( targetUnitID )
			assert( targetUnit, "No target : "..tostring(targetUnitID))
			local x1, y1 = targetUnit:getLocation()

			if not unit:getTraits().wireless_range then
    			local x0,y0 = unit:getLocation()
				local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )
				sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), targetID= targetUnit:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )
			end

            local triggerData = sim:triggerEvent(simdefs.TRG_UNIT_HIJACKED, { unit=targetUnit, sourceUnit=unit } )
            if not triggerData.abort then

			    local cpus, bonus = self:calculateCPUs( abilityOwner, unit, targetUnit )
			    
			    if abilityOwner:getTraits().PWR_conversion then
			    	local credits = (cpus + bonus)*abilityOwner:getTraits().PWR_conversion
			    	unit:getPlayerOwner():addCredits( credits ,sim,x1,y1)
					sim._resultTable.credits_gained.econchip = sim._resultTable.credits_gained.econchip and sim._resultTable.credits_gained.econchip + credits or credits
			    else
			    	unit:getPlayerOwner():addCPUs( cpus + bonus, sim, x1,y1 )
				end

			    if abilityOwner:getTraits().disposable then
				    inventory.trashItem( sim, unit, abilityOwner )
				else
				    inventory.useItem( sim, unit, abilityOwner )			    
			    end
--[[
			    if abilityOwner:getTraits().charges then
				    abilityOwner:getTraits().charges = abilityOwner:getTraits().charges - 1
				    if abilityOwner:getTraits().charges <= 0 then
					    inventory.trashItem( sim, unit, abilityOwner )
				    end
			    end
]]
				targetUnit:getTraits().hijacked = true
                targetUnit:getTraits().mainframe_suppress_range = nil
				targetUnit:setPlayerOwner(abilityOwner:getPlayerOwner())			
			    targetUnit:getTraits().cpus = 0
            end
			if not unit:getTraits().wireless_range then
				sim:processReactions( abilityOwner )
			end

			sim:getCurrentPlayer():glimpseUnit( sim, targetUnit:getID() )
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit } )
		end,
	}
return jackin