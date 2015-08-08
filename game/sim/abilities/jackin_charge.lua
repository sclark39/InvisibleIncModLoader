local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local speechdefs = include("sim/speechdefs")
local mathutil = include( "modules/mathutil" )

local jackin_charge =
	{
		name = STRINGS.ABILITIES.HIJACK_STORE_PWR,
        proxy = true,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )			
			targetUnit:getUnitData().onWorldTooltip( section, targetUnit, hud )
			if (targetUnit:getTraits().cpus or 0) > 0 then
				section:addAbility( self:getName(sim, abilityOwner, abilityUser, targetUnitID),
					STRINGS.ABILITIES.HIJACK_STORE_PWR_DESC, "gui/items/icon-action_hack-console.png" )
			end
			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
            return self.name
		end,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",

        getProfileIcon = function( self, sim, abilityOwner )
            return abilityOwner:getUnitData().profile_icon or self.profile_icon
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
			local x0, y0 = unit:getLocation()
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isTarget( abilityOwner, unit, targetUnit ) then
                    local ok = simquery.canReach( sim, x0, y0, x1, y1 )
                    if ok then
						table.insert( units, targetUnit )
					end
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		calculateCPUs = function( self, abilityOwner, unit, targetUnit )
			local bonus = unit:getTraits().hacking_bonus or 0
            if unit ~= abilityOwner then
                bonus = bonus + (abilityOwner:getTraits().hacking_bonus or 0)
            end
			return math.ceil( targetUnit:getTraits().cpus ), bonus
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

		executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )
			sim:emitSpeech( unit, speechdefs.EVENT_HIJACK )
            
			local targetUnit = sim:getUnit( targetUnitID )
			assert( targetUnit, "No target : "..tostring(targetUnitID))
			local x1, y1 = targetUnit:getLocation()
   			local x0,y0 = unit:getLocation()
			local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), targetID= targetUnit:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )

            local triggerData = sim:triggerEvent(simdefs.TRG_UNIT_HIJACKED, { unit=targetUnit, sourceUnit=unit } )
            if not triggerData.abort then
			    local cpus, bonus = self:calculateCPUs( abilityOwner, unit, targetUnit )
                abilityOwner:getTraits().icebreak = math.min( abilityOwner:getTraits().icebreak + cpus + bonus, abilityOwner:getTraits().maxIcebreak )
    			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT,
                    { txt= util.sformat( STRINGS.FORMATS.PWR, cpus + bonus ), x=x0,y=y0 } )
				targetUnit:getTraits().hijacked = true
                targetUnit:getTraits().mainframe_suppress_range = nil
				targetUnit:setPlayerOwner(abilityOwner:getPlayerOwner())
			    targetUnit:getTraits().cpus = 0
            end

            sim:processReactions( abilityOwner )
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit } )
		end,
	}
return jackin_charge