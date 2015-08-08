local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local unitdefs = include( "sim/unitdefs" )

-------------------------------------------------------------------
--

local function isKO( unit )
    return unit:isKO()
end

local function isNotKO( unit )
    return not unit:isKO()
end

local function canAbandon( unit )
    return not unit:getTraits().cant_abandon
end

local escape =
	{
		name = STRINGS.ABILITIES.ESCAPE,
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			return abilityutil.hotkey_tooltip( self, sim, abilityOwner, STRINGS.ABILITIES.ESCAPE_DESC )
		end,
		
		profile_icon = "gui/actions/escape1.png",
        canUseWhileDragging = true,

		getName = function( self, sim, unit )
			return self.name
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )		

			local cell = sim:getCell( abilityOwner:getLocation() )
			local units = {}
			if cell.exitID then
				table.insert( units, abilityOwner )	
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		confirmAbility = function( self, sim, ownerUnit )
			-- Check to see if escaping would leave anyone behind, and there is nobody remaining in the level.
            local fieldUnits, escapingUnits = simquery.countFieldAgents( sim )

            -- A partial escape means someone alive is left on the field.
            local isPartialEscape = array.findIf( fieldUnits, isNotKO ) ~= nil
			if isPartialEscape then
				return STRINGS.UI.HUD_CONFIRM_PARTIAL_ESCAPE			
			end

            -- Show what is being abandoned, if anything.
            local abandonedUnit = array.findIf( fieldUnits, isKO )
            local itemsInField = simquery.countDeployedUnits( sim )
			local txt = ""
			if abandonedUnit then
				txt =  string.format( STRINGS.UI.HUD_CONFIRM_ESCAPE, ownerUnit:getName(), abandonedUnit:getName() )			
			end
			if #itemsInField >0 then
				if abandonedUnit then
					txt = txt .."\n\n"
				end				
				txt = txt ..  STRINGS.UI.HUD_ITEMS_LEFT .. "\n"

				for i,item in ipairs(itemsInField) do
					txt = txt .. item:getName() .. "\n"
				end
			end
			if abandonedUnit or #itemsInField >0 then
				return txt
			end

            -- Defer to mission script warnings about escaping early.
			if type(sim.exit_warning) == "function" then
				return sim.exit_warning()
			end
				
			if type(sim.exit_warning) == "string" then
				return sim.exit_warning 
			end
		end,

		canUseAbility = function( self, sim, unit )
			local cell = sim:getCell( unit:getLocation() )
			if cell.exitID == nil then
				return false, STRINGS.UI.REASON.NOT_EXIT
			end

			if sim:hasTag( "no_escape" ) then
				return false, STRINGS.UI.REASON.CANT_ESCAPE
			end

			if sim:hasTag( "exit_reqiuired_item" ) then
				local agents = 0
				local agentsLeaving = 0
				local hasItem = false
				for _, unit in pairs( sim:getAllUnits() ) do			

					if unit:hasAbility( "escape" )	then
						agents = agents + 1
						local c = sim:getCell( unit:getLocation() )					
						if c and c.exitID  then
							agentsLeaving = agentsLeaving + 1


							for i,item in ipairs(unit:getChildren())do
								if item:getUnitData().id == sim:getTags().exit_reqiuired_item then
									hasItem = true
								end
							end
						end
					end
				end
				if agents <= agentsLeaving and not hasItem then
					local name =  unitdefs.lookupTemplate( sim:getTags().exit_reqiuired_item ).name
					return false, util.sformat(STRINGS.UI.REASON.NEED_ITEM_TO_LEAVE,name)
				end
			end

			if sim:hasTag( "monst3r_firstOut" ) then
				local monst3rIn = false
				local monst3rLeaving = false
				for _, unit in pairs( sim:getAllUnits() ) do

					if unit:getTraits().monst3r then
						monst3rIn = true
					end

					local c = sim:getCell( unit:getLocation() )
					if c and c.exitID and unit:hasAbility( "escape" ) then
						if unit:getTraits().monst3r then 
							monst3rLeaving = true
						end								
					end
				end
				if not monst3rLeaving and monst3rIn then
					return false, STRINGS.UI.REASON.MONST3R_MUST_LEAVE
				end
			end

            if unit:getTraits().cant_abandon then

                -- This unit cannot escape if others will be abandoned in the field,
                -- unless there exists a unit that CAN abandon who is escaping with us.
                local fieldUnits, escapingUnits = simquery.countFieldAgents( sim )
                local isPartialEscape = array.findIf( fieldUnits, isNotKO ) ~= nil
                if not isPartialEscape then
                    local isAbandoning = array.findIf( fieldUnits, isKO ) ~= nil
                    local canAbandon = array.findIf( escapingUnits, canAbandon )

                    local escapedAgents = 0
	            	local player = unit:getPlayerOwner()
	            	for i,deployed in pairs(player:getDeployed())do
	            		if deployed.escapedUnit and not deployed.escapedUnit:getTraits().cant_abandon then
	            			escapedAgents = escapedAgents + 1
	            		end
	            	end
                    if isAbandoning and not canAbandon and escapedAgents < 1 then
                        return false, STRINGS.UI.REASON.CANT_ABANDON
                    end
                end
            end

			return true
		end,

		executeAbility = function( self, sim, abilityOwner )
			local player = abilityOwner:getPlayerOwner()
			local cell = sim:getCell( abilityOwner:getLocation() )
            local escapedUnits = {}

			if cell.exitID then
				sim:closeElevator()
				local units = {}
				for _, unit in pairs( player:getUnits() ) do					
					local c = sim:getCell( unit:getLocation() )
					if c and c.exitID and unit:hasAbility( "escape" ) then
						table.insert(units,unit)
						if player then
							for agentID, deployData in pairs(player:getDeployed()) do
								if deployData.id == unit:getID() then
									deployData.escapedUnit = unit
									deployData.exitID = cell.exitID
								end
							end
						end						
					end
				end

				sim:dispatchEvent( simdefs.EV_TELEPORT, { units=units, warpOut =true } )		

				for i,unit in ipairs(units)do
		
					sim:warpUnit( unit, nil )
					sim:despawnUnit( unit )

					if unit:getTraits().hostage then 
						if player then 
							sim:triggerEvent( "hostage_escaped" )
						end
					end

                    table.insert( escapedUnits, unit )

					simlog( "%s escaped!", unit:getName())					
				end
				

                while #escapedUnits > 0 do
                    sim:triggerEvent( simdefs.TRG_UNIT_ESCAPED, table.remove( escapedUnits ))
                end
				
				sim:processReactions()
				sim:updateWinners()
			end
		end,
	}
return escape