----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local mui_defs = include( "mui/mui_defs")
local inventory = include( "sim/inventory" )
local hudtarget = include( "hud/targeting")
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local level = include( "sim/level" )
local modalDialog = include( "states/state-modal-dialog" )
local items_panel = include( "hud/items_panel" )
local abilityutil = include( "sim/abilities/abilityutil" )
local mui_util = include( "mui/mui_util" )

------------------------------------------------------------------------------
-- Local functions
------------------------------------------------------------------------------


local function isPassiveAbility( ability )
	return ability.executeAbility == nil
end

local function shouldShowAbility( game, ability, abilityOwner, abilityUser )
	if ability.profile_icon == nil or ability.neverShow then
		return false
	end

	if isPassiveAbility( ability ) then
		return false
	end

	local enabled, reason = abilityUser:canUseAbility( game.simCore, ability, abilityOwner )
	if not enabled and reason == nil then
		-- If there's no reason displayed, the ability simply shouldn't show up.
		return false
	end

	return true
end

local function shouldShowProxyAbility( game, ability, abilityOwner, abilityUser, actions )
	if not ability.proxy then
		return false
	elseif type(ability.proxy) == "number" then
		local count = 0
		for i, action in ipairs(actions) do
			if action.ability and action.ability:getID() == ability:getID() then
				count = count + 1
			end
		end
		if count >= ability.proxy then
			return false
		end
	end

	if ability.profile_icon == nil or ability.neverShow then
		return false
	end

	if isPassiveAbility( ability ) then
		return false
	end

	local enabled, reason = abilityUser:canUseAbility( game.simCore, ability, abilityOwner )
	if not enabled and reason == nil then
		-- Never show for proxy abilities if they aren't actually available.
		return false
	end

	return true
end


local function performDoorAction( game, exitOp, unit, cell, dir )
	game.hud:transitionNull()
	game:doAction( "useDoorAction", exitOp, unit:getID(), cell.x, cell.y, dir )
end

local function canModifyExit( unit, exitop, cell, dir, sim )
	if not simquery.canReachDoor( unit, cell, dir ) then
		return false
	end

	local exit = cell.exits[dir]
	if exitop == simdefs.EXITOP_CLOSE and exit.no_close then 
		return false 
	end 

	return simquery.canModifyExit( unit, exitop, cell, dir )
end

local function checkForSingleDoor( game, exitOp, unit, cell, dir, sim )
	local availableDoors = 0

	local POTENTIAL_ACTIONS =
	{
		0, 0,
		1, 0,
		-1, 0,
		0, 1,
		0, -1,
		2, 0,
		-2, 0,
		0, 2,
		0, -2,
		1, 1,
		1, -1,
		-1, 1,
		-1, -1,
	}

	local localPlayer = game:getLocalPlayer()
	for i = 1, #POTENTIAL_ACTIONS, 2 do
		local dx, dy = POTENTIAL_ACTIONS[i], POTENTIAL_ACTIONS[i+1]
		local testCell = localPlayer:getCell( cell.x + dx, cell.y + dy )
	    if cell and testCell ~= nil then
			if unit:getTraits().canUseDoor ~= false then
				for dir, exit in pairs(testCell.exits) do						
					if exit.door then
						if exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR_INUSE and not exit.locked then
							local enabled, reason = canModifyExit( unit, simdefs.EXITOP_CLOSE, testCell, dir, sim )
							if enabled or reason then
								if reason ~= STRINGS.UI.DOORS.GUARD then 
									availableDoors = availableDoors +1
								end
							end
						end
					end
				end
			end
		end	
	end

	if availableDoors == 1 then 
		game.hud:transitionNull()
		game:doAction( "useDoorAction", exitOp, unit:getID(), cell.x, cell.y, dir )
	elseif availableDoors > 1 then
		-- too many door warning
		local level= "SpySociety/HUD/voice/level1/"
		MOAIFmodDesigner.playSound(level.."alarmvoice_warning")
   		game.hud:showWarning( STRINGS.UI.WARNING_CANT_USE, {r=1,g=1,b=1,a=1}, STRINGS.UI.WARNING_TOO_MANY_DOORS )
	else 
		-- no door warning
		local level= "SpySociety/HUD/voice/level1/"
		MOAIFmodDesigner.playSound(level.."alarmvoice_warning")
   		game.hud:showWarning( STRINGS.UI.WARNING_CANT_USE, {r=1,g=1,b=1,a=1}, STRINGS.UI.WARNING_NO_DOOR )
	end
end


local function performAbility( game, abilityOwner, abilityUser, ability, ... )
	local abilityIndex = util.indexOf( abilityOwner:getAbilities(), ability )
	assert( abilityIndex, ability:getID() )

	if ability and ability:getDef().confirmAbility then
		local confirmTxt = ability:getDef():confirmAbility( game.simCore, abilityOwner, abilityUser )
		if confirmTxt then
			local result = modalDialog.showYesNo( confirmTxt, STRINGS.UI.HUD_CONFIRM_ABILITY )
			if result ~= modalDialog.OK then
				return false
			end
		end
	end

	game.hud:transitionNull()
	game:doAction( "abilityAction", abilityOwner:getID(), abilityUser:getID(), abilityIndex, ... )
	return true
end

local function generateTooltip( header, body, reason )
	if reason then
		return string.format("<ttheader>%s</>\n<ttbody>%s</>\n<c:ff0000>%s</>", header, body, reason )
	else
		return string.format("<ttheader>%s</>\n<ttbody>%s</>", header, body )
	end
end

local function generateDoorTooltip( hud, exit, exitOp, reason, desc, overwatched )

	local tooltip = util.tooltip( hud._screen )
	local section = tooltip:addSection()
	local doorState = ""
	if exit.closed and exit.locked then
		doorState = STRINGS.UI.DOORS.LOCKED
	elseif exit.closed then
		doorState = STRINGS.UI.DOORS.CLOSED
	elseif exit.locked then
		doorState = STRINGS.UI.DOORS.BROKEN
	else
		doorState = STRINGS.UI.DOORS.OPEN
	end

	if exit.keybits and exit.keybits == simdefs.DOOR_KEYS.GUARD then 
		section:addLine( "<ttheader>"..STRINGS.UI.DOORS.GUARD_ELEVATOR.."</>", doorState )
	elseif exit.keybits and exit.keybits == simdefs.DOOR_KEYS.VAULT then 
		section:addLine( "<ttheader>"..STRINGS.UI.DOORS.TOOLTIP_VAULT.."</>", doorState )
	elseif exit.keybits and exit.keybits == simdefs.DOOR_KEYS.SPECIAL_EXIT then 
		section:addLine( "<ttheader>"..STRINGS.UI.DOORS.TOOLTIP_SPECIAL_EXIT.."</>", doorState )
	elseif exit.keybits and exit.keybits == simdefs.DOOR_KEYS.SECURITY then 
		section:addLine( "<ttheader>"..STRINGS.UI.DOORS.TOOLTIP_SECURITY.."</>", doorState )
	else
		section:addLine( "<ttheader>"..STRINGS.UI.DOORS.TOOLTIP.."</>", doorState )
	end 

	if exitOp == simdefs.EXITOP_CLOSE then
		section:addAbility( STRINGS.UI.DOORS.CLOSE, STRINGS.UI.DOORS.CLOSED_TT, "gui/icons/action_icons/Action_icon_Small/icon-action_door_close_small.png" )
	elseif exitOp == simdefs.EXITOP_OPEN then
		if exit.keybits and exit.keybits == simdefs.DOOR_KEYS.GUARD then 
			section:addAbility( STRINGS.UI.DOORS.NO_ENTRY, STRINGS.UI.DOORS.NO_ENTRY_TT, "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png" )
		else 
			section:addAbility( STRINGS.UI.DOORS.OPEN, STRINGS.UI.DOORS.OPEN_TT, "gui/icons/action_icons/Action_icon_Small/icon-action_door_open_small.png" )
		end 
	elseif exitOp == simdefs.EXITOP_LOCK then
		section:addAbility( STRINGS.UI.DOORS.LOCK, STRINGS.UI.DOORS.LOCK_TT, "gui/icons/action_icons/Action_icon_Small/icon-action_lock_small.png" )
	elseif exitOp == simdefs.EXITOP_UNLOCK then
		section:addAbility( STRINGS.UI.DOORS.UNLOCK, STRINGS.UI.DOORS.UNLOCK_TT, "gui/icons/action_icons/Action_icon_Small/icon-action_unlock_small.png" )
	elseif exitOp == simdefs.EXITOP_BREAK_DOOR then
		section:addAbility( STRINGS.UI.DOORS.BREAK, STRINGS.UI.DOORS.BREAK_TT, "gui/icons/action_icons/Action_icon_Small/icon-item_sneak_small.png" )

	elseif exitOp == simdefs.EXIT_DISARM then
		section:addAbility( "Disarm alarm", "COST: 3AP", "gui/icons/action_icons/Action_icon_Small/icon-item_sneak_small.png" )
	end

	if overwatched then 
		tooltip:addSection():addWarning( STRINGS.UI.DOOR_TRACKED, STRINGS.UI.DOOR_TRACKED_TT, "gui/hud3/hud3_tracking_icon_sm.png" , cdefs.COLOR_WATCHED_BOLD  )
	end 

	if reason then
		section:addRequirement( reason )
	end
	
	if desc then
		section:addDesc( desc )
	end

	local hotkey = nil
	if exitOp == simdefs.EXITOP_CLOSE then
		hotkey = STRINGS.UI.HOTKEYS.USE_CLOSE_DOOR
	end			

	if exitOp == simdefs.EXITOP_OPEN then
 		hotkey = STRINGS.UI.HOTKEYS.USE_OPEN_DOOR
	end			 

	if hotkey then
	        local binding = util.getKeyBinding( "abilityOpenDoor" )
        if binding then
			section:appendHeader( mui_util.getBindingName( binding ), hotkey )
        end	
    end       
	
	return tooltip
end

local function isSameDoor( a, cell, dir )
	if a.cell then
		if cell.x + 1 == a.cell.x and cell.y == a.cell.y and dir == simdefs.DIR_E and a.dir == simdefs.DIR_W then
			return true
		elseif cell.x - 1 == a.cell.x and cell.y == a.cell.y and dir == simdefs.DIR_W and a.dir == simdefs.DIR_E then
			return true
		elseif cell.x == a.cell.x and cell.y + 1 == a.cell.y and dir == simdefs.DIR_N and a.dir == simdefs.DIR_S then
			return true
		elseif cell.x == a.cell.x and cell.y - 1 == a.cell.y and dir == simdefs.DIR_S and a.dir == simdefs.DIR_N then	
			return true
		end
	end

	return false
end

	-- Generates a list of potential actions in a given direction.
local function generatePotentialExitActions( hud, actions, sim, unit, cell, dir )

	local overwatched = false 
	if unit and simquery.isUnitUnderOverwatch(unit) then
		overwatched = true 
	end 

	local exit = cell.exits[ dir ]
	if exit.door then
		if exit.closed and exit.locked and not array.findIf( actions, function( a ) return isSameDoor( a, cell, dir ) and a.exitop == simdefs.EXITOP_UNLOCK end ) then
			local enabled, reason, desc = canModifyExit( unit, simdefs.EXITOP_UNLOCK, cell, dir, sim )			
			if enabled or reason or desc then
				table.insert( actions,
				{	
					txt = STRINGS.UI.ACTIONS.UNLOCK_DOOR,
					icon = "gui/icons/action_icons/Action_icon_Small/icon-action_unlock_small.png",
					x = (cell.x + exit.cell.x) / 2, y = (cell.y + exit.cell.y) / 2,  z = 36, cell = cell, dir = dir, exitop = simdefs.EXITOP_UNLOCK,
					layoutID = string.format( "%d,%d-%d", cell.x, cell.y, dir ),
					reason = reason,					
					tooltip = generateDoorTooltip( hud, exit, simdefs.EXITOP_UNLOCK, reason, desc, overwatched ),
					enabled = enabled,
					onClick = function() performDoorAction( hud._game, simdefs.EXITOP_UNLOCK, unit, cell, dir ) end
				})
			end
			
		elseif not exit.closed and not array.findIf( actions, function( a ) return isSameDoor( a, cell, dir ) and a.exitop == simdefs.EXITOP_CLOSE end ) and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR_INUSE then
			local enabled, reason = canModifyExit( unit, simdefs.EXITOP_CLOSE, cell, dir, sim )
			if enabled or reason then
				table.insert( actions,
				{	
					txt = STRINGS.UI.ACTIONS.CLOSE_DOOR,
					icon = "gui/icons/action_icons/Action_icon_Small/icon-action_door_close_small.png",
					x = (cell.x + exit.cell.x) / 2, y = (cell.y + exit.cell.y) / 2,  z = 36, cell = cell, dir = dir, exitop = simdefs.EXITOP_CLOSE,
					layoutID = string.format( "%d,%d-%d", cell.x, cell.y, dir ),
					reason = reason,
					hotkey = "abilityOpenDoor",
					tooltip = generateDoorTooltip( hud, exit, simdefs.EXITOP_CLOSE, reason, nil, overwatched ),
					enabled = enabled,
					onClick = function() performDoorAction( hud._game, simdefs.EXITOP_CLOSE, unit, cell, dir ) end,
					onHotkey = function() checkForSingleDoor( hud._game, simdefs.EXITOP_CLOSE, unit, cell, dir, sim ) end,
				})
			end
		elseif not array.findIf( actions, function( a ) return isSameDoor( a, cell, dir ) and a.exitop == simdefs.EXITOP_OPEN end ) and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR_INUSE then 
			local enabled, reason = canModifyExit( unit, simdefs.EXITOP_OPEN, cell, dir, sim )
			if enabled or reason then
				if reason == STRINGS.UI.DOORS.GUARD then 
					table.insert( actions,
					{
						txt = STRINGS.UI.ACTIONS.NO_ENTRY,
						icon = "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png",
						x = (cell.x + exit.cell.x) / 2, y = (cell.y + exit.cell.y) / 2, z = 36, cell = cell, dir = dir, exitop = simdefs.EXITOP_OPEN,
						layoutID = string.format( "%d,%d-%d", cell.x, cell.y, dir ),
						reason = reason,
						tooltip = generateDoorTooltip( hud, exit, simdefs.EXITOP_OPEN ),
						enabled = enabled,
						onClick = function() performDoorAction( hud._game, simdefs.EXITOP_OPEN, unit, cell, dir ) end
					})
				else 
					table.insert( actions,
					{
						txt = STRINGS.UI.ACTIONS.OPEN_DOOR,
						icon = "gui/icons/action_icons/Action_icon_Small/icon-action_door_open_small.png",
						x = (cell.x + exit.cell.x) / 2, y = (cell.y + exit.cell.y) / 2, z = 36, cell = cell, dir = dir, exitop = simdefs.EXITOP_OPEN,
						layoutID = string.format( "%d,%d-%d", cell.x, cell.y, dir ),
						reason = reason,
						hotkey = "abilityOpenDoor",
						tooltip = generateDoorTooltip( hud, exit, simdefs.EXITOP_OPEN, reason, nil, overwatched ),
						enabled = enabled,
						onClick = function() performDoorAction( hud._game, simdefs.EXITOP_OPEN, unit, cell, dir ) end,
						onHotkey = function() checkForSingleDoor( hud._game, simdefs.EXITOP_OPEN, unit, cell, dir, sim ) end,
					})
				end 
			end
		end
		--[[
		if sim:getTags().doors_alarmOnOpen and not exit.door_disarmed then
			local enabled, reason, desc = canModifyExit( unit, simdefs.EXIT_DISARM, cell, dir, sim )			
			if enabled or reason or desc then
				table.insert( actions,
				{	
					txt = "DISARM ALARM",
					icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
					x = (cell.x + exit.cell.x) / 2, y = (cell.y + exit.cell.y) / 2,  z = 36, cell = cell, dir = dir, exitop = simdefs.EXIT_DISARM,
					layoutID = string.format( "%d,%d-%d", cell.x, cell.y, dir ),
					reason = reason,					
					tooltip = generateDoorTooltip( hud, exit, simdefs.EXIT_DISARM, reason, desc, overwatched ),
					enabled = enabled,
					onClick = function() performDoorAction( hud._game, simdefs.EXIT_DISARM, unit, cell, dir ) end
				})
			end		
		end
		]]
		
        --[[
		if cell == unit:getSim():getCell(unit:getLocation() ) and exit.closed and not exit.locked and not array.findIf( actions, function( a ) return isSameDoor( a, cell, dir ) and a.exitop == simdefs.EXITOP_BREAK_DOOR end ) and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR_INUSE then 
			local enabled, reason = canModifyExit( unit, simdefs.EXITOP_BREAK_DOOR, cell, dir )
			if enabled or reason then
				table.insert( actions,
				{
					txt = "Bash Door",
					icon = "gui/icons/action_icons/Action_icon_Small/icon-item_sneak_small.png",
					x = (cell.x + exit.cell.x) / 2, y = (cell.y + exit.cell.y) / 2, z = 36, cell = cell, dir = dir, exitop = simdefs.EXITOP_BREAK_DOOR,
					layoutID = string.format( "%d,%d-%d", cell.x, cell.y, dir ),
					reason = reason,
					tooltip = generateDoorTooltip( hud, exit, simdefs.EXITOP_BREAK_DOOR, reason ),
					enabled = enabled,
					onClick = function() performDoorAction( hud._game, simdefs.EXITOP_BREAK_DOOR, unit, cell, dir ) end
				})
			end
		end
        --]]
	end
end

-- Generates a list of potential actions that could be performed by 'unit' at
-- the given location.
local function generatePotentialActions( hud, actions, unit, cellx, celly )
	local sim = hud._game.simCore
	local localPlayer = hud._game:getLocalPlayer()
	local x0, y0 = unit:getLocation()
    if not cellx or not celly or localPlayer:getCell( cellx, celly ) == nil then
        return
    end

	local cell = sim:getCell( cellx, celly )

	-- Check actions on units in cell
	for i,cellUnit in ipairs(cell.units) do
		-- Check proxy abilities.
		for j, ability in ipairs( cellUnit:getAbilities() ) do
			if (cellUnit == unit and shouldShowAbility( hud._game, ability, cellUnit, unit )) or
				(cellUnit ~= unit and shouldShowProxyAbility( hud._game, ability, cellUnit, unit, actions )) then
				table.insert( actions, { ability = ability, abilityOwner = cellUnit, abilityUser = unit, priority = ability.HUDpriority } )
			end
		end

		-- Check loot special case.
		if simquery.canLoot( sim, unit, cellUnit ) then
			table.insert( actions,
			{
				txt = STRINGS.UI.ACTIONS.LOOT_BODY.NAME,
				icon = "gui/icons/action_icons/Action_icon_Small/icon-item_loot_small.png",
				x = cell.x, y = cell.y,
				enabled = true,
				layoutID = cellUnit:getID(),
				tooltip = string.format( "<ttheader>%s\n<ttbody>%s</>", STRINGS.UI.ACTIONS.LOOT_BODY.NAME, STRINGS.UI.ACTIONS.LOOT_BODY.TOOLTIP ),
				onClick =
					function()				
						local advancedSearch = unit:getTraits().anarchyItemBonus
						hud._game:doAction( "search", cellUnit:getID(),advancedSearch )
						hud:showItemsPanel( items_panel.loot( hud, unit, cellUnit ))
					end
			})
		elseif simquery.canGive( sim, unit, cellUnit ) then
			table.insert( actions,
			{
				txt = STRINGS.UI.ACTIONS.GIVE.NAME,
				icon = "gui/icons/action_icons/Action_icon_Small/icon-action_trade.png",
				x = cell.x, y = cell.y,
				enabled = true,
				layoutID = cellUnit:getID(),
				tooltip = STRINGS.UI.ACTIONS.GIVE.TOOLTIP,
				onClick =
					function()
                        local items_panel = include( "hud/items_panel" )
						hud:showItemsPanel( items_panel.transfer( hud, unit, cellUnit ))
					end
			})
		end
	end

	local count = 0
	for i,cellUnit in ipairs(cell.units) do
		if inventory.canCarry( unit, cellUnit ) then
			count = count + 1
		end
	end
	if count > 0 and not unit:isKO() then
		table.insert( actions,
			{	
				txt = STRINGS.UI.ACTIONS.PICKUP.NAME,
				icon = "gui/icons/action_icons/Action_icon_Small/icon-item_loot_small.png",
				x = cell.x, y = cell.y,
				enabled = true,
                tooltip = STRINGS.UI.ACTIONS.PICKUP.TOOLTIP,
				onClick = function()
					hud:onSimEvent( { eventType = simdefs.EV_ITEMS_PANEL, eventData = { unit = unit, x = cellx, y = celly } } )
				end
			})
	end

	if unit:getTraits().canUseDoor ~= false then
		for dir, exit in pairs(cell.exits) do
			generatePotentialExitActions( hud, actions, sim, unit, cell, dir )			
		end
	end
end

return
{
	isPassiveAbility = isPassiveAbility,
	shouldShowAbility = shouldShowAbility,
	shouldShowProxyAbility = shouldShowProxyAbility,
	generatePotentialActions = generatePotentialActions,

	performAbility = performAbility,
	performDoorAction = performDoorAction,
	checkForSingleDoor = checkForSingleDoor,
}
