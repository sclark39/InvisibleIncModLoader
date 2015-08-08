local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local level = include( "sim/level" )
local abilitydefs = include( "sim/abilitydefs" )
local mission_util = include( "sim/missions/mission_util" )
local SCRIPTS = include('client/story_scripts')
local rig_util = include( "gameplay/rig_util" )

---------------------------------------------------------------------------------------------
-- Local helpers

LOX = 2 
LOY = 17

local function findCell( sim, tag )
	local cells = sim:getCells( tag )
	return cells and cells[1]
end

local function unlockDoor(sim,cell)

	for i,exit in pairs (cell.exits) do
		if exit.locked then			
			sim:modifyExit( cell, i, simdefs.EXITOP_UNLOCK )
		end
	end
end

---------------------------------------------------------------------------------------------
-- Wait objects.

local PC_SELECTED =
{
	uiEvent = level.EV_UNIT_SELECTED,
	fn = function( sim, unitID )
		local unit = sim:getUnit( unitID )
		return unit and unit:isPC()
	end
}

local PC_TOGGLED_MAINFRAME =
{
	uiEvent = level.EV_HUD_MAINFRAME_TOGGLE,
}

local function PC_CLICKED_BUTTON( name )
	return
	{
		uiEvent = level.EV_HUD_CLICK_BUTTON,
		fn = function( sim, eventData )
			return eventData == name
		end,
	}
end

local PC_MOVED =
{
	action = "moveAction",
	fn = function( sim, unitID, moveTable )
		return unitID and sim:getUnit( unitID ):isPC()
	end,
}

local PC_USED_DOOR =
{
	action = "useDoorAction",
	pre = true,
	fn = function( sim, exitOp, unitID, x0, y0, facing )
		return unitID and sim:getUnit( unitID ):isPC()
	end,
}

local PC_USED_MP =
{
	action = "moveAction",
	fn = function( sim, unitID, moveTable )
		local unit = sim:getPC():getUnits()[1]
		return unit and unit:getMP() < 1
	end,
}

local PC_STARTED_MOVE =
{
	action = "moveAction",
	pre = true,
	fn = function( sim, unitID, moveTable )
		local unit = sim:getUnit( unitID )
		return unit and unit:isPC()
	end,
}

local PEEK_DOOR_OPEN = 
{		
	action = "",
	fn = function( sim, evData )

		local cell = findCell( sim, "peekTutorialDoor" )
		local doorexit = nil
		for i,exit in pairs( cell.exits ) do
		 	if exit.door then
		 		doorexit = exit
		 		break
		 	end
		end
		if not doorexit.closed then
			return true
		end
	end,	
}

local PC_USED_MELEE_OVERWATCH =
{
	action = "abilityAction",
	post = true,
	fn = function( sim, ownerID, userID, abilityIdx, ... )
		-- Just watch for melee overwatch status directly, in case the user is already in that state.
		local ownerUnit = sim:getUnit( ownerID ) or sim:getPC():getUnits()[1]
		return ownerUnit and ownerUnit:getTraits().isMeleeAiming
	end,
}


local function PC_SAW_UNIT( tag )
	return
	{
		trigger = simdefs.TRG_UNIT_APPEARED,
		fn = function( sim, evData )
			if not tag or evData.unit:hasTag(tag) then
				return true
			else
				return false
			end
		end,
	}
end

local function UNIT_SAW_PC()
	return
	{
		trigger = simdefs.TRG_UNIT_APPEARED,
		fn = function( sim, evData )
			local seer, seen = sim:getUnit(evData.seerID), evData.unit
			if seer and seen:isPC() and simquery.isAgent(seen) and simquery.isEnemyAgent( seer:getPlayerOwner(), seen ) then
				return true
			else
				return false
			end
		end,
	}
end

local function PC_TOOK_UNIT()
	return
	{
		action = "lootItem",
		fn = function( sim, unitID, itemID )
			local unit, item = sim:getUnit( unitID ), sim:getUnit( itemID )
			if unit and unit:isPC() and item then
				return true
			end
		end
	}
end

local function PC_BUYITEM()
	return
	{
		action = "buyItem",
		fn = function( sim, shopper, shopitem)			
			if shopper then
				return true
			end
		end
	}
end

local function PC_HACKED_CAMERA()
	return
	{
		action = "mainframeAction",
		fn = function( sim, updates )
			if updates and updates.action == "breakIce" then
				local unit = sim:getUnit(updates.unitID)
				return unit:getTraits().mainframe_camera and unit:getTraits().mainframe_ice == 0
			end
		end
	}
end
local function PC_ENTERING_DANGER()
	return
	{
		trigger = simdefs.TRG_UNIT_WARP_PRE,
		fn = function( sim, eventData )
			local unit = eventData.unit
			local cell = eventData.to_cell
			if unit:getPlayerOwner():isPC() and cell then
				local watched = simquery.isCellWatched(sim, sim:getPC(), cell.x, cell.y)
				if watched == simdefs.CELL_WATCHED or watched == simdefs.CELL_NOTICED then
					unit:interruptMove( sim )
					return true
				end
			end
		end
	}
end
local function PC_ENTERED_REGION( tileList, interrupt )
	return
	{
		trigger = simdefs.TRG_UNIT_WARP,
		fn = function( sim, eventData )
			--loop over all agents
			for i,v in ipairs(sim:getPC():getUnits()) do
				local unit = eventData.unit
				if unit:getID() == v:getID() and v:getName() ~= "Eyeball" then
					local x, y = unit:getLocation()
					for i,tile in ipairs( tileList )do
						if x == tile[1] and y == tile[2] then
							if interrupt then
								unit:interruptMove( sim )
							end 
							return true
						end
					end
				end
			end
		end
	}
end

local NPC_KO =
{
	trigger = simdefs.TRG_UNIT_KO
}

---------------------------------------------------------------------------------------------
-- Tutorial hook functions.


local function wasSpotted1( script, sim )
	script:waitFor( UNIT_SAW_PC())
	script:clearQueue()
	
	script:queue( 1.5*cdefs.SECONDS )
    script:queue( { type="desaturation", enable=true } )		
    script:queue( 1.5*cdefs.SECONDS )
    script:queue( { type="desaturation", enable=false } )		
	script:restore()
end

local function willBeSpotted( script, sim )
	script:waitFor( PC_ENTERING_DANGER())
	script:clearQueue()
	script:queue( { type="showWarning", txt1=STRINGS.UI.WARNING_MOVE_INTO_SIGHT, txt2 =STRINGS.UI.WARNING_MOVE_INTO_SIGHT_2, sound="SpySociety/HUD/gameplay/HUD_Monster_ForSale"  } )
	
	script:addHook( willBeSpotted )
end

local function closeDoor( script, sim )
	script:waitFor( PC_USED_DOOR )
	script:clearQueue()
	script:queue( { type="hideHUDInstruction" } )
	script:queue( { type="clearOperatorMessage" } )
end

local function guardTurn( script, sim )

	local guard = mission_util.findUnitByTag(sim, "guard1")
	local guard1x, guard1y = mission_util.findUnitByTag(sim, "guard1"):getLocation()
	script:waitFor( mission_util.NPC_START_TURN )
	script:clearQueue()
	script:queue( { type="pan", x=guard1x, y=guard1y } )
	script:queue( 1*cdefs.SECONDS )
	if not guard:isKO() then
		script:queue( { body=STRINGS.MISSIONS.JAILBREAK.GUARDTURN_1, instructions="", header=STRINGS.MISSIONS.JAILBREAK.GUARD, type="enemyMessage", 
			profileAnim="portraits/portrait_animation_template",
			profileBuild="portraits/portrait_security_build",
		} )
	else 
		script:queue( { body=STRINGS.MISSIONS.JAILBREAK.GUARDTURN_2, instructions="", header=STRINGS.MISSIONS.JAILBREAK.GUARD, type="enemyMessage", 
			profileAnim="portraits/portrait_animation_template",
			profileBuild="portraits/portrait_security_build",
		} )
	end 

	script:queue( 2.5*cdefs.SECONDS )
	script:queue( { type="clearEnemyMessage" } )
	script:waitFor( mission_util.PC_START_TURN )
	local unit = sim:getPC():getUnits()[1]
	local x, y = unit:getLocation()
	script:queue( { type="pan", x=x, y=y } )
	script:waitFor( mission_util.NPC_START_TURN )
	if guard:isKO() then 

	else 
		script:clearQueue()
		script:queue( { type="pan", x=guard1x, y=guard1y } )
		script:queue( 1*cdefs.SECONDS )
		script:queue( { body=STRINGS.MISSIONS.JAILBREAK.GUARDTURN_3, instructions="", header=STRINGS.MISSIONS.JAILBREAK.GUARD, type="enemyMessage", 
			profileAnim="portraits/portrait_animation_template",
			profileBuild="portraits/portrait_security_build",
		} )
		script:queue( 3.2*cdefs.SECONDS )
		script:queue( { type="clearEnemyMessage" } )
		script:waitFor( mission_util.PC_START_TURN )
		local unit = sim:getPC():getUnits()[1]
		local x, y = unit:getLocation()
		script:queue( { type="pan", x=x, y=y } )
		script:waitFor( mission_util.NPC_START_TURN )
	end 
end 

local function getTazerHook( script, sim )
	local safe = mission_util.findUnitByTag(sim, "tazerSafe")
	sim._resultTable.devices[safe:getID()].hacked = true
	local x, y = safe:getLocation()
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_GET_TAZER, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_GET_TAZER_SUBTEXT, x=x, y=y } )

	--got to the safe? Clear the message
	script:waitFor( PC_ENTERED_REGION( {
		{40+LOX,6+LOY},
		{39+LOX,5+LOY}
	} )) 
	script:queue( { type="hideHUDInstruction" } )

	--left the safe? Add the message
	script:waitFor( PC_ENTERED_REGION( {
		{39+LOX,6+LOY}, 
		{39+LOX,7+LOY}, 
		{40+LOX,7+LOY}, 
		{40+LOX,7+LOY},

		{38+LOX,5+LOY},	
		{38+LOX,6+LOY},	
	} )) 

	script:addHook(getTazerHook)
end

local function guardTurnSimPauser( script, sim )

	script:waitFor( mission_util.NPC_START_TURN )
	script:waitFrames( 4.5 * cdefs.SECONDS )
	local guard = mission_util.findUnitByTag(sim, "guard1")
	script:waitFor( mission_util.NPC_START_TURN )
	if guard:isKO() then 

	else 
		script:waitFrames( 4.5 * cdefs.SECONDS )
	end 
end 

local function startPhase( script, sim )

    script:waitFor( mission_util.UI_INITIALIZED )
    script:queue( 2*cdefs.SECONDS )
	----------------------------------------
	-- START -------------
	----------------------------------------

	local unit = sim:getPC():getUnits()[1]
	unit:getTraits().isLyingDown = true
	unit:useMP( 4, sim )

	script:addHook( wasSpotted1, true )
	script:addHook( willBeSpotted )

	----------------------------------------
	-- SELECT AGENT -------------
	----------------------------------------

	script:queue( { script=SCRIPTS.INGAME.TUTORIAL_INTRO, type="modalConversation" } )	
	script:queue( 1*cdefs.SECONDS )

	local x, y = unit:getLocation()
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_SELECT, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_SELECT_SUBTEXT, x=x, y=y } )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_AWAKE, type="newOperatorMessage" } )	

	script:waitFor( PC_SELECTED )

	----------------------------------------
	-- MOVE AGENT -------------
	----------------------------------------
	script:clearQueue()	

	unit:useMP( 1, sim )
	sim:showHUD( true, "agentFlags" )

	script:queue( { type="hideHUDInstruction" } )

	unit:getTraits().isLyingDown = nil
	sim:dispatchEvent( simdefs.EV_UNIT_KO, { unit = unit, stand = true } )

	sim:showHUD( false, "tooltips" )

	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_MOVE, subtext="", followMovement=true, rightclick=true } )
	script:queue( { type = "ui", widget="homePanel",visible=true })

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_MOVE, type="newOperatorMessage" } )		

	script:waitFor( PC_STARTED_MOVE )
	script:queue( { type="hideHUDInstruction" } )

	----------------------------------------
	-- END TURN -------------
	----------------------------------------
	script:waitFor( PC_USED_MP )

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_END_TURN, type="newOperatorMessage" } )	

	script:queue( { type="showTurnbaseDialog" } )
	
	script:queue( { type = "ui", widget="endTurnBtn",visible=true } )
	script:queue( { type = "blink", target="endTurnBtn", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_END_TURN, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_END_TURN_SUBTEXT, widget="endTurnBtn", offset={x=-80, y=-2} } ) 
	script:queue( { type="displayHUDpulse", widget="endTurnBtn", offset={x=-50, y=0} } )

	sim:showHUD( true, "endTurnBtn" )

	script:waitFor( mission_util.PC_END_TURN )
	script:clearQueue()

	script:queue( { type="hideHUDpulse" } )
	script:queue( { type="hideHUDInstruction" } )
	script:queue( { type = "blink", target="endTurnBtn", blink={ period=0 }})

	script:queue( 2.2*cdefs.SECONDS )

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_WAITING, type="newOperatorMessage" } )	
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_WAITING, x=41+LOX, y=9+LOY } )

	----------------------------------------
	-- MOVE TO DOOR -------------
	----------------------------------------
	script:waitFor( PC_ENTERED_REGION( {{41+LOX,9+LOY}} )) 
	script:clearQueue()

	----------------------------------------
	-- PEEK THROUGH DOOR -------------
	----------------------------------------
	script:clearQueue()	
	script:queue( { type="hideHUDInstruction" } )

	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_PEEK, type="newOperatorMessage" } )

	--script:queue( { type = "blink", target="peek", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})

	script:waitFor( PC_SAW_UNIT( "guard1" ))

	script:addHook( guardTurnSimPauser )
	script:addHook( guardTurn )

	--first checkpoint before you can die
	script:clearQueue()	
	script:checkpoint()	

	local guard1x, guard1y = mission_util.findUnitByTag(sim, "guard1"):getLocation()
	script:queue( { type="pan", x=guard1x, y=guard1y } )

	----------------------------------------
	-- OPEN DOOR -------------
	----------------------------------------
	script:queue( { type="clearOperatorMessage" } )
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { type="unlockDoor", x=41+LOX, y=9+LOY } )

	unlockDoor( sim, findCell( sim, "peekDoor" ) )
	local safe = mission_util.findUnitByTag(sim, "tazerSafe")
	safe:setPlayerOwner( sim:getPC() )

	script:queue( 1*cdefs.SECONDS )

	----------------------------------------
	-- GRAB THE NEURAL DISRUPTER -----------
	----------------------------------------

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_GET_OUT, type="newOperatorMessage" } )	
	script:waitFor( PC_ENTERED_REGION( {{40+LOX,9+LOY}} )) 
	script:clearQueue()

	--in case it didn't clear previously
	script:queue( { type="clearEnemyMessage" } )	
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_TOOLS, type="newOperatorMessage", parallel = true } )	

	script:queue( 0.5*cdefs.SECONDS )

	script:addHook( getTazerHook )

	script:waitFor( PC_TOOK_UNIT() )
	script:removeHook( getTazerHook )
	script:clearQueue()

	----------------------------------------
	-- KNOCK OUT THE GUARD -------------
	----------------------------------------
	script:queue( { type="clearOperatorMessage" } )
	script:queue( { type="hideHUDInstruction" } )
	script:queue( 1*cdefs.SECONDS )

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_KNOCK_OUT, type="newOperatorMessage" } )		
	
	script:waitFor( mission_util.PC_USED_ABILITY( "melee" ))
	script:clearQueue()

	script:queue( 3.7*cdefs.SECONDS )
	script:queue( { type="modalPinning" } )

	sim:showHUD( true, "tooltips" )
	--use up all their actions on purpose
	--jcheng: actually, don't use up their mp
	--unit:useMP( unit:getMP(), sim )

	script:queue( { type="clearOperatorMessage" } )
	script:queue( 3.5*cdefs.SECONDS )

	x, y = unit:getLocation()
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_PINNED, x=x, y=y } )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_PINNED, type="newOperatorMessage" } )				

	script:waitFor( PC_STARTED_MOVE )
	script:clearQueue()	
	script:queue( { type="clearOperatorMessage" } )
	script:queue( { type="hideHUDInstruction" } )
	
	----------------------------------------
	-- CLOSE THE DOOR BEHIND YOU -----------
	----------------------------------------
	script:waitFor( PC_ENTERED_REGION( {
		{33+LOX,9+LOY},
		{33+LOX,10+LOY},
		{33+LOX,11+LOY},
	}, true )) 

	script:queue( 0.5*cdefs.SECONDS )

	local x, y = unit:getLocation()
	script:queue( { type="pan", x=x, y=y } )
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_SHUT_THE_DOOR, x=34+LOX, y=10+LOY, offset={x=50,y=145} } )

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_SHUT_THE_DOOR, type="newOperatorMessage" } )
	
	script:addHook( closeDoor )

	----------------------------------------
	-- GET SOME CPU -----------
	----------------------------------------
	script:waitFor( PC_SAW_UNIT( "tutorial_console" ))
	script:removeHook( closeDoor )
	x, y = mission_util.findUnitByTag(sim, "tutorial_console"):getLocation()
	script:queue( { type="pan", x=x+4, y=y-2 } )
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CONSOLE, x=x, y=y } )

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_CONSOLE, type="newOperatorMessage" } )	

	script:waitFor( mission_util.PC_USED_ABILITY( "jackin" ))
	script:clearQueue()	

	script:queue( { type="clearOperatorMessage" } )
	script:queue( { type="hideHUDInstruction" } )

	sim:showHUD( true, "mainframe", "agentSelection" )
	sim:showHUD( true, "resourcePnl" )

	script:queue( 2.5*cdefs.SECONDS )

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_GOT_CONSOLE, type="newOperatorMessage" } )		
	local check = sim:getPC():hasSeen(mission_util.findUnitByTag(sim, "tutorial_cam1"))
	if not check then
		script:queue( { type="modalPeekOpenPeek" } )
	end
	
	if not PEEK_DOOR_OPEN.fn( sim ) then		
		script:waitFor( PEEK_DOOR_OPEN )
	end

	script:queue( { type="displayPeekpulse" } )	
	script:queue( { type = "blink", target="peek", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})
		
	----------------------------------------
	-- SEE THE CAMERA -----------
	----------------------------------------
	script:checkpoint()	
	check = sim:getPC():hasSeen(mission_util.findUnitByTag(sim, "tutorial_cam1"))
	if not check then
		script:waitFor( PC_SAW_UNIT( "tutorial_cam1" ) )
		script:clearQueue()
	end
	script:queue( { type="hidePeekpulse" } )	
	script:queue( { type = "blink", target="peek", blink={ period=0 }})		

	local cam_unit = mission_util.findUnitByTag(sim, "tutorial_cam1")
	script:queue( { type="pan", x=25+LOX, y=9+LOY } )
	script:queue( 1.0*cdefs.SECONDS )
	script:queue( { type="modalPopupIncognita" } )
	script:queue( { type = "blink", target="incognitaBtn", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CAMERA, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CAMERA_SUBTEXT, widget="incognitaBtn", offset={x=77,y=-18} } )
	script:queue( { type="displayHUDpulse", widget="incognitaBtn", offset={x=-23, y=-2}, fly_image=cam_unit })

	script:queue( 1.0*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_CAMERA, type="newOperatorMessage", parallel = true} )		

	----------------------------------------
	-- HACK THE CAMERA -----------
	----------------------------------------
	script:waitFor( PC_TOGGLED_MAINFRAME )	
	script:clearQueue()
	script:queue( { type="clearOperatorMessage" } )

	script:queue( { type = "blink", target="incognitaBtn", blink={ period=0}})	
	script:queue( { type="clearOperatorMessage" } )
	script:queue( { type="hideHUDpulse" } )
	script:queue( { type="hideHUDInstruction" } )
	script:queue( 1.0*cdefs.SECONDS )
	
	script:queue( { type="modalPopupLockpick" } )

	script:queue( 0.5*cdefs.SECONDS )

	script:queue( { type="displayICEpulse" } )	
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_HACK_CAMERA, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_HACK_CAMERA_SUBTEXT, widget="BreakIce.btn", offset={x=10,y=0} } )
	script:queue( { type = "blink", target="BreakIce.btn", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})	
	script:waitFor( PC_HACKED_CAMERA() )


	script:clearQueue()				
	script:queue( { type="hideHUDInstruction" } )	
	script:queue( { type="hideICEpulse" } )		
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_EXIT_MAINFRAME, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CAMERA_SUBTEXT, widget="incognitaBtn",  offset={x=77,y=-18} } )
	script:queue( { type="displayHUDpulse", widget="incognitaBtn", offset={x=-23, y=-2} } )	
	script:queue( { type = "blink", target="incognitaBtn", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})

	script:waitFor( PC_TOGGLED_MAINFRAME )
	script:clearQueue()	
	script:queue( { type = "blink", target="incognitaBtn", blink={ period=0}})	
	script:queue( { type="hideHUDpulse" } )
	script:queue( { type="hideHUDInstruction" } )	

	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_HACK_CAMERA, type="newOperatorMessage" } )	
	

	script:waitFor( PC_STARTED_MOVE )
	script:clearQueue()	
	script:queue( { type="clearOperatorMessage" } )

	----------------------------------------
	-- MELEE OVERWATCH -----------
	----------------------------------------
	script:waitFor( PC_ENTERED_REGION( {
		{23+LOX,7+LOY},
		{23+LOX,8+LOY},
		{23+LOX,9+LOY},
		{23+LOX,10+LOY}
	} )) 

	script:clearQueue()
	script:checkpoint()	

	script:queue( { type="displayHUDInstruction", x=16+LOX, y=7+LOY, text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_DOOR_CORNER, offset={x=0,y=0} } )--x=-12,y=-10
	script:queue( { type="pan", x=19+LOX, y=7+LOY } )	
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_DOOR_CORNER, type="newOperatorMessage" } )		


	script:waitFor( PC_ENTERED_REGION( {{16+LOX,7+LOY}}, true ) )
	script:clearQueue()	
	sim:getTags().blockMovePeek = true

	script:queue( { type="hideHUDInstruction" } )	
	script:queue( 1*cdefs.SECONDS )

	script:waitFor( PC_SAW_UNIT( "guard2" ))

	script:clearQueue()	
	sim:getTags().blockMovePeek = false

	sim:showHUD( false, "endTurnBtn" )
	unit:useMP( 10, sim )

	script:queue( 1.5*cdefs.SECONDS )
	script:queue( { type="modalPopupManipulate" } )

	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_OPEN_DOOR, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_OPEN_DOOR_SUBTEXT,  x=15+LOX, y=7+LOY, offset={x=130,y=122}  } )-- widget="Open Door",offset={x=-30,y=0}
	script:queue( { type="unlockDoor", x=15+LOX, y=7+LOY } )
	unlockDoor( sim, findCell( sim, "meleeDoor" ) )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_DISTRACT, type="newOperatorMessage" } )

	----------------------------------------
	-- DISTRACTION -----------
	----------------------------------------

	script:waitFor( PC_USED_DOOR )
	script:clearQueue()	
	script:queue( { type="hideHUDInstruction" } )	

	sim:showHUD( true, "abilities" )
	
	script:queue( 1*cdefs.SECONDS )
	
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_MELEE_OVERWATCH, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_MELEE_OVERWATCH_SUBTEXT, widget="overwatchMelee", offset={x=10,y=0} } )
	script:queue( { type="displayOverwatchMeleePulse" } )
	script:queue( { type = "blink", target="overwatchMelee", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})	
	unit:useMP( unit:getMP(), sim )

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_MELEE_PREP, type="newOperatorMessage", parallel = true } )	

	script:waitFor( PC_USED_MELEE_OVERWATCH )
	script:clearQueue()	
	script:queue( { type = "blink", target="overwatchMelee", blink={ period=0 }})	
	sim:showHUD( true, "endTurnBtn" )

	script:queue( { type="hideOverwatchMeleePulse" } )
	script:queue( { type="clearOperatorMessage" } )
	script:queue( { type="hideHUDInstruction" } )	

	script:queue( { type = "blink", target="endTurnBtn", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})

	script:waitFor( mission_util.PC_END_TURN )
	script:clearQueue()
	script:queue( { type = "blink", target="endTurnBtn", blink={ period=0 }})

	script:waitFor( NPC_KO )
	script:clearQueue()	

	----------------------------------------
	-- PENTULTIMATE ROOM -----------
	----------------------------------------

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_NEXT_ROOM, type="newOperatorMessage" } )	

	script:waitFor( mission_util.PC_ANY )
	script:clearQueue()	
	script:queue( { type="clearOperatorMessage" } )

	----------------------------------------
	-- FINAL ROOM -----------
	----------------------------------------
	local finalTiles = {}
	for i = 7+LOX, 11+LOX, 1 do
		for j = 7+LOY, 11+LOY, 1 do
			table.insert(finalTiles,{i,j})
		end
	end

	script:waitFor( PC_ENTERED_REGION( finalTiles ))
	script:clearQueue()
	script:checkpoint()	

	----------------------------------------
	-- PEEK AROUND THE CORNER -----------
	----------------------------------------
	script:queue( { type="displayHUDInstruction", x=5+LOX, y=8+LOY, text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_DANGER_ZONE, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_DANGER_ZONE_SUBTEXT } )

	script:queue( { type="pan", x=7+LOX, y=7+LOY } )	
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_DANGER_ZONE, type="newOperatorMessage" } )			

	script:queue( 2*cdefs.SECONDS )
	script:queue( { type="hideHUDInstruction" } )	
	script:queue( 0.5*cdefs.SECONDS )

	local peekpos = findCell( sim, "tutorial_peektile" )
	script:queue( { type="displayHUDInstruction", x=peekpos.x, y=peekpos.y, text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CORNER, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CORNER_SUBTEXT } )

	script:waitFor( PC_ENTERED_REGION( {
		{7+LOX,7+LOY},
		{7+LOX,7+LOY},
		{7+LOX,7+LOY},
	} )) 
	script:clearQueue()		

	script:queue( { type="hideHUDInstruction" } )	

	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { type="showCornerPeekDialog" } )

	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CORNER_PEEK, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CORNER_PEEK_SUBTEXT, widget="peek", offset={x=0,y=0} } )
	script:queue( { type="displayHUDpulse", widget="peek", offset={x=0,y=0} } )	
	script:queue( { type = "blink", target="peek", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})
	
	----------------------------------------
	-- HACK THE FINAL BITS -----------
	----------------------------------------
	script:waitFor( PC_SAW_UNIT( "tutorial_cam2" ))
	script:clearQueue()		

	script:queue( { type="hideHUDpulse" } )
	script:queue( { type = "blink", target="peek", blink={ period=0 }})
	script:queue( { type="hideHUDInstruction" } )	

	x, y = mission_util.findUnitByTag(sim, "tutorial_cam2"):getLocation()
	script:queue( { type="pan", x=x, y=y } )

	script:queue( 0.5*cdefs.SECONDS )



	local cpus = sim:getPC():getCpus()
	if cpus == 0 then
		x, y = mission_util.findUnitByTag(sim, "tutorial_console2"):getLocation()

		script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CONSOLE, x=x, y=y } )


		script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_NEED_POWER, type="newOperatorMessage" } )			

		script:waitFor( mission_util.PC_USED_ABILITY( "jackin" ))
		script:clearQueue()	
		script:queue( { type="clearOperatorMessage" } )
		script:queue( { type="hideHUDInstruction" } )

		script:queue( 2*cdefs.SECONDS )

		script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_REMIND_INCOGNITA, type="newOperatorMessage" } )		
	else
		script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_AFTER_PEEK, type="newOperatorMessage" } )			
	end

	--mention incognita everytime until they do it now

	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CAMERA, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_CAMERA_SUBTEXT, widget="incognitaBtn", offset={x=77,y=-18} } )
	script:queue( { type="displayHUDpulse", widget="incognitaBtn", offset={x=-23, y=-2} } )

	script:waitFor( PC_TOGGLED_MAINFRAME )
	script:clearQueue()	
	script:queue( { type="hideHUDpulse" } )
	script:queue( { type="hideHUDInstruction" } )
	script:queue( { type="clearOperatorMessage" } )	

	script:queue( 0.5*cdefs.SECONDS )

	script:waitFor( PC_HACKED_CAMERA() )
	script:waitFor( PC_TOGGLED_MAINFRAME )

	script:checkpoint()	


	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_EXIT, type="newOperatorMessage" } )

	script:waitFor( mission_util.PC_ANY )
	script:clearQueue()	
	script:queue( { type="clearOperatorMessage" } )	

	script:waitFor( PC_SAW_UNIT( "guard3" ))
	local guard = mission_util.findUnitByTag(sim, "guard3")
	local x, y = guard:getLocation()
	script:queue( { type="displayHUDInstruction", text=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_ARMORED_GUARD, subtext=STRINGS.MISSIONS.JAILBREAK.INSTRUCTIONS_USE_COVER, x=x, y=y } )


	script:queue( 2*cdefs.SECONDS )
	script:queue( { type="modalPopupBlindSpots" } )	

	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_COVER, type="newOperatorMessage" } )	

	script:waitFor( PC_ENTERED_REGION( {
		{4+LOX,-6+LOY}
	} )) 	
	script:clearQueue()	
	script:checkpoint()	
	script:queue( { type="hideHUDInstruction" } )	

	script:waitFor( PC_SAW_UNIT( "guard4" ))

	local guard4x, guard4y = mission_util.findUnitByTag(sim, "guard4"):getLocation()
	script:queue( { type="pan", x=guard4x, y=guard4y } )

	sim:getTags().blockMoveObserve = true
	script:queue( 0.5*cdefs.SECONDS )

	script:queue( { type="displayObservePulse" } )	
	script:queue( { type = "blink", target="observePath", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_OBSERVE_GUARD, type="newOperatorMessage" } )		

	script:waitFor( mission_util.PC_USED_ABILITY( "observePath" ))
	sim:getTags().blockMoveObserve = false
	script:queue( { type="hideObservePulse" } )	
	script:queue( { type = "blink", target="observePath", blink={ period=0 }})

	script:queue( 0.5*cdefs.SECONDS )

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_OBSERVE_GUARD_2, type="newOperatorMessage" } )	
	
	--script:clearQueue()

	script:waitFor( mission_util.PC_WON )
	script:removeAllHooks( script )
	script:clearQueue()
	script:queue( { type="clearEnemyMessage" } )
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_TUTORIAL_OPERATOR_WON, type="newOperatorMessage" } )			
	script:queue(1*cdefs.SECONDS)
end

---------------------------------------------------------------------------------------------
-- Main script.  init() gets executed as part of engine:init(), within the sim thread.

local tutorial = class()

function tutorial:init( scriptMgr )
	local sim = scriptMgr.sim

	local player = sim:getPC()
	player:addCPUs(-player:getCpus())

	sim:getTags().isTutorial = true
	sim:getTags().retries = 0

	sim:openElevator()

	-- SET FLAGS FOR SPEICAL HUD ELEMENTS TO NOT DISPLAY
	sim:showHUD( false, "inventoryPanel", "endTurnBtn", "abilities", "mainframe", "agentSelection", "alarm", "agentFlags", "resourcePnl", "statsPnl", "topPnl" )
	
	scriptMgr:addHook( "START", startPhase )

    local win_conditions = include( "sim/win_conditions" )
	sim:addWinCondition( win_conditions.neverLose )
end

return tutorial
