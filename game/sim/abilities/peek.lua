local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )

local peek_tooltip = class( abilityutil.hotkey_tooltip )

function peek_tooltip:init( hud, unit, ... )
	abilityutil.hotkey_tooltip.init( self, ... )
	self._game = hud._game
	self._unit = unit
end

function peek_tooltip:activate( screen )
	abilityutil.hotkey_tooltip.activate( self, screen )
	self._game.hud:previewAbilityAP( self._unit, 1 )
end

function peek_tooltip:deactivate()
	abilityutil.hotkey_tooltip.deactivate( self )
	self._game.hud:previewAbilityAP( self._unit, 0 )
end

local peek = 
	{
		name = STRINGS.ABILITIES.PEEK,
		hotkey = "abilityPeek",
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			return peek_tooltip( hud, abilityUser, self, sim, abilityOwner, STRINGS.ABILITIES.PEEK_DESC )
		end,
		
		--profile_icon = "gui/items/icon-action_peek.png",

	    getProfileIcon = function( self, sim, abilityOwner, abilityUser, hasTarget )
	    	if hasTarget then
	    		return "gui/icons/action_icons/Action_icon_Small/icon-action_peek_door.png"
	    	else
	        	return "gui/icons/action_icons/Action_icon_Small/icon-action_peek_around.png"
	    	end
	    end,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_peek_small.png",
		HUDpriority = 2,
		alwaysShow = true,
		usesMP = true,
		eyeballs = {},
		trigger = false,

		getName = function( self, sim, unit )
			return self.name
		end,

		showTargets = function( self, targets, game, sim, abilityOwner, abilityUser )
			local exits = {}
			local fromCell = sim:getCell( abilityUser:getLocation() )
			local x0,y0 = fromCell.x, fromCell.y

			for i = 1, #simdefs.ADJACENT_EXITS, 3 do
				local dx, dy, dir = simdefs.ADJACENT_EXITS[i], simdefs.ADJACENT_EXITS[i+1], simdefs.ADJACENT_EXITS[i+2]
				local cell = sim:getCell( fromCell.x + dx, fromCell.y + dy )
				if (dx == 0 and dy == 0) or simquery.isOpenExit( fromCell.exits[ simquery.getDirectionFromDelta( dx, dy ) ] ) then
					local exit = cell and cell.exits[ dir ]
					if exit and exit.door and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR and exit.keybits ~= simdefs.DOOR_KEYS.GUARD then
						table.insert( exits, { x = cell.x, y = cell.y, dir = dir } )
					end
				end
			end

			return targets.exitTarget( game, exits, self, abilityOwner, abilityUser )
		end,


		canPeek = function( self, sim, fromCell, dx, dy )
			if sim:getCell( fromCell.x + dx, fromCell.y + dy ) == nil then
				return false
			end

			if math.abs(dx) ~= 1 or math.abs(dy) ~= 1 then
				return false -- Can only peek to cells on the diagonal
			end

			local e1, e2, e3, e4 = false, false, false, false -- Tracks open exits

			local testCell1 = sim:getCell( fromCell.x + dx, fromCell.y )
			if testCell1 then
				local facing1, facing2 = simquery.getDirectionFromDelta( -dx, 0 ), simquery.getDirectionFromDelta( 0, dy )
				e1 = testCell1.exits[ facing1 ] ~= nil 
				e2 = testCell1.exits[ facing2 ] ~= nil

				if testCell1.exits[ facing1 ] and testCell1.exits[ facing1 ].door and testCell1.exits[ facing1 ].closed then
					e1 = false
				end
				if testCell1.exits[ facing2 ] and testCell1.exits[ facing2 ].door and testCell1.exits[ facing2 ].closed then
					e2 = false
				end

			end
			
			local testCell2 = sim:getCell( fromCell.x, fromCell.y + dy )				
			if testCell2 then
				local facing1, facing2 = simquery.getDirectionFromDelta( 0, -dy ), simquery.getDirectionFromDelta( dx, 0 )
				e3 = testCell2.exits[ facing1 ] ~= nil
				e4 = testCell2.exits[ facing2 ] ~= nil


				if  testCell2.exits[ facing1 ] and  testCell2.exits[ facing1 ].door and testCell2.exits[ facing1 ].closed then
					e3 = false
				end
				if testCell2.exits[ facing2 ] and testCell2.exits[ facing2 ].door and testCell2.exits[ facing2 ].closed then
					e4 = false
				end

			end
				
			return (e3 and e4) or (e1 and e2)
		end,

        removePeek = function( self, sim )
            if #self.eyeballs > 0 then
			    while #self.eyeballs > 0 do
				    local eyeball = table.remove( self.eyeballs )
				    sim:warpUnit( eyeball )
				    sim:despawnUnit( eyeball )
			    end
			    sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
			    sim:removeTrigger( simdefs.TRG_UNIT_KO, self )
            end
        end,

		onTrigger = function( self, sim, evType, evData, unit )
			if (evType == simdefs.TRG_UNIT_WARP and evData.unit == unit) or (evType == simdefs.TRG_UNIT_KO and evData.unit == unit) then
                self:removePeek( sim )
			end
		end,
		
		doPeek = function( self, unit, view360, sim, x0,y0, peekInfo, dx, dy, exit )
			local eyeball = include( "sim/units/eyeball" )
			local eyeballUnit = eyeball.createEyeball( sim )
			eyeballUnit:setPlayerOwner( unit:getPlayerOwner() )
			eyeballUnit:setFacing( simquery.getDirectionFromDelta( dx, dy ) )
            eyeballUnit:getTraits().peekID = unit:getID()

			if view360 or unit:getTraits().doorPeek360 then
				eyeballUnit:getTraits().LOSarc = math.pi * 2	
			end

			local cell = sim:getCell( x0 + dx, y0 + dy )
			sim:spawnUnit( eyeballUnit )
			sim:warpUnit( eyeballUnit, cell)
			table.insert( self.eyeballs, eyeballUnit )

			--prefer to use the targeted exit (or lack of exit)
			if peekInfo.preferredExit and exit ~= peekInfo.preferredExit then
				return
			end

			local shoulder = simquery.getAgentShoulderDir(unit, cell.x, cell.y)
			if not peekInfo.preferredExit then
				--we're leaning on something, prefer to peek behind us, and out of those options prefer the least impass
				if (simquery.getAgentCoverDir(unit) or simquery.getAgentLeanDir(unit)) and not shoulder and peekInfo.shoulder then
					return
				elseif peekInfo.cell and peekInfo.cell.impass < cell.impass then
					return
				end
			end

--			print(string.format("PEEKING x=%d y=%d dx=%d dy=%d, exit=%s", x0, y0, dx, dy, util.debugPrintTable(exit) ) )
			if eyeballUnit:getTraits().cellvizCount > peekInfo.cellvizCount or peekInfo.cellvizCount == 0 then
				peekInfo.cellvizCount = eyeballUnit:getTraits().cellvizCount
				local unitX, unitY = unit:getLocation()
				local eyeballX, eyeballY = eyeballUnit:getLocation()
				peekInfo.dx = eyeballX-unitX
				peekInfo.dy = eyeballY-unitY
				peekInfo.cell = cell
				peekInfo.shoulder = shoulder
				peekInfo.exit = exit
				if x0 == peekInfo.x0 and y0 == peekInfo.y0 then
					if dx == 0 or dy == 0 then
						--peek direction is just the direction of dx, dy
						peekInfo.dir = simquery.getDirectionFromDelta( dx, dy )
					else
						--peek is a corner, but we might be better off picking a cardinal direction to peek in
						local baseCell = sim:getCell(peekInfo.x0, peekInfo.y0)
						local dirX1 = simquery.getDirectionFromDelta(dx, 0)
						local dirX2 = simquery.getDirectionFromDelta(0, dy)
						local clearX = baseCell.exits[dirX1] and not baseCell.exits[dirX1].closed
						 and baseCell.exits[dirX1].cell.exits[dirX2] and not baseCell.exits[dirX1].cell.exits[dirX2].closed
						local dirY1 = simquery.getDirectionFromDelta(0, dy)
						local dirY2 = simquery.getDirectionFromDelta(dx, 0)
						local clearY = baseCell.exits[dirY1] and not baseCell.exits[dirY1].closed
						 and baseCell.exits[dirY1].cell.exits[dirY2] and not baseCell.exits[dirY1].cell.exits[dirY2].closed
						if clearX and clearY then
							--diagonal is open
							peekInfo.dir = simquery.getDirectionFromDelta(dx, dy)
						elseif clearX then
							peekInfo.dir = simquery.getDirectionFromDelta(dx, 0)
						elseif clearY then
							peekInfo.dir = simquery.getDirectionFromDelta(0, dy)
						end
					end
				elseif exit then
					--we're peeking through a door we couldn't 'touch'. Peek in such a way it doesn't matter which side the door is on.
					peekInfo.dir = simquery.getDirectionFromDelta(x0-peekInfo.x0, y0-peekInfo.y0)
				end
			end
		end,

		canUseAbility = function( self, sim, unit )

			if unit:getMP() < 1 then
				return false, string.format(STRINGS.UI.REASON.REQUIRES_AP,1)
			end

			local x0, y0 = unit:getLocation()
			local fromCell = sim:getCell( x0, y0 )

			if self:canPeek( sim, fromCell, 1, 1 ) then
				return true
			end
			if self:canPeek( sim, fromCell, -1, -1 ) then
				return true
			end
			if self:canPeek( sim, fromCell, 1, -1 ) then
				return true
			end
			if self:canPeek( sim, fromCell, -1, 1 ) then
				return true
			end

			-- Any door peeks?
			for dir, exit in pairs( fromCell.exits ) do

				if exit.door and exit.closed then
					return true
				end
				
				for subDir, subExit in pairs(exit.cell.exits) do
					if subDir ~= dir then
						if subExit.door and subExit.closed then
							return true
						end
					end
				end
			end

			return false, STRINGS.UI.REASON.NO_PEEK
		end,
		
		executeAbility = function( self, sim, unit, userUnit, exitX, exitY, exitDir )
			
			local x0, y0 = unit:getLocation()
			local fromCell = sim:getCell( x0, y0 )

            self:removePeek( sim )

			sim:emitSpeech( unit, speechdefs.EVENT_PEEK )
			--unit:setAiming( false )
			sim:emitSound( simdefs.SOUND_PEEK, x0, y0, nil )		
			unit:useMP( simdefs.DEFAULT_COST,sim )

			-- Any door peeks?
			local peekInfo = { x0 = x0, y0 = y0, cellvizCount = 0}
			if exitX and exitY and exitDir then
				local exitCell = sim:getCell(exitX, exitY)
				if exitCell then
					peekInfo.preferredExit = exitCell.exits[exitDir]
				end
			end

            for i = 1, #simdefs.ADJACENT_EXITS, 3 do
				local dx, dy, dir = simdefs.ADJACENT_EXITS[i], simdefs.ADJACENT_EXITS[i+1], simdefs.ADJACENT_EXITS[i+2]
				local cell = sim:getCell( fromCell.x + dx, fromCell.y + dy )
				if (dx == 0 and dy == 0) or simquery.isOpenExit( fromCell.exits[ simquery.getDirectionFromDelta( dx, dy ) ] ) then
					local exit = cell and cell.exits[ dir ]
					if exit and exit.door and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR and exit.keybits ~= simdefs.DOOR_KEYS.GUARD then
						local peekDx, peekDy = simquery.getDeltaFromDirection( dir )
                        self:doPeek(unit, not exit.closed, sim, cell.x, cell.y, peekInfo, peekDx, peekDy, exit)
					end
				end
			end

			if self:canPeek( sim, fromCell, 1, 1 ) then
				self:doPeek( unit, true, sim, x0,y0, peekInfo, 1, 1 )
			end
			if self:canPeek( sim, fromCell, -1, 1 ) then
				self:doPeek( unit, true, sim, x0,y0, peekInfo, -1, 1 )
			end
			if self:canPeek( sim, fromCell, 1, -1 ) then
				self:doPeek( unit, true, sim, x0,y0, peekInfo, 1, -1 )
			end
			if self:canPeek( sim, fromCell, -1, -1 ) then
				self:doPeek( unit, true, sim, x0,y0, peekInfo, -1, -1 )
			end

			sim:dispatchEvent( simdefs.EV_UNIT_PEEK, { unitID = unit:getID(), peekInfo = peekInfo } )

			-- Add trigger for eyeball removal (notably, before processReactions)
			sim:addTrigger( simdefs.TRG_UNIT_WARP, self, unit )
            sim:addTrigger( simdefs.TRG_UNIT_KO, self, unit )

			sim:processReactions( unit )
		end,
	}
return peek
