----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local version = include( "modules/version" )
local mui = include("mui/mui")
local mui_defs = include("mui/mui_defs")
local mui_util = include("mui/mui_util")
local cdefs = include( "client_defs" )
local modalDialog = include( "states/state-modal-dialog" )
local cheatmenu = include( "fe/cheatmenu" )
local serializer = include( "modules/serialize" )

----------------------------------------------------------------

local statedebug =
{
	screen = nil,
	keybindings = {},

	mode = cdefs.DBG_NONE,
	selectedUnit = nil,
	simHistoryIndex = 1,
	soundMarkers = {},
	pathMarkers = {},
	pathReserves = {},

	roomHilites = {},

	huntHilites = {},

	-- For calculating elapsed time
 	startTime = 0,
	-- Profiler
	profiler = nil,
	-- Number of reports made.
	reportCount = 0,
}

-- A local "environment" for managing debug state
local debugenv =
{
	__index = function( t, k )
		local v = rawget(_G, k)
		if v then
			return v
		end
	end,

	getCurrentGame = function( self )
        local states = statemgr.getStates()
        for i = 1, #states do
            if states[i].simCore and states[i].levelData then
                return states[i] -- If it acts like a duck and quacks like a duck...
            end
        end
	end,

	updateEnv = function( self )
		self.game = self:getCurrentGame()
		self.boardRig = self.game and self.game.boardRig
		self.sim = self.game and self.game.simCore
		self.simquery = self.sim and self.sim:getQuery()
		self.simdefs = self.sim and self.sim:getDefs()
		self.currentPlayer = self.sim and self.sim:getCurrentPlayer()
		self.localPlayer = self.game and self.game:getLocalPlayer()
        if self.game then
            self.cx, self.cy = self.game:wndToSubCell( inputmgr.getMouseXY() )
            self.cx, self.cy = math.floor(self.cx), math.floor(self.cy)
        end
		self.statedebug = statedebug

		setmetatable( self, self )
	end,
}

local function toggleVisible()
	if statedebug.screen:isActive() then
		for cellID, fx in pairs( statedebug.soundMarkers ) do
			fx:destroy()
		end
		statedebug.soundMarkers = {}
		mui.deactivateScreen( statedebug.screen )
        statedebug.cheatMenu = nil

	else
		statedebug.startTime = MOAISim.getDeviceTime ()
		statedebug.screen:setPriority( math.huge )
		mui.activateScreen( statedebug.screen )

        local cheatmenu = reinclude( "fe/cheatmenu" )
        statedebug.cheatMenu = cheatmenu.menu( statedebug.screen, debugenv )

		if statedebug.replayPanel then
            statedebug.replayPanel:updatePanel()
        end
	end
end

local function reloadConfig()
	log:write("-Reloading config.lua and cheatmenu.lua ------------")
	local res, err = pcall( dofile, "config.lua" )
	if not res then
		log:write( "ERR: %s", err )
	else
		updateConfig()
	end
	log:write("-DONE-----------------------")
end

local function gameReset()
	if game then
		reloadConfig()
	
		reinclude( "hud/mission_panel" )
        reinclude( "sim/missions/mission_util" )

		game:goto( 0 )
		game.simHistory = { game.simHistory[1] } -- Keep 'reserve' action only.
	end
end

local function printMemoryUsage()
	local usage = MOAISim.getMemoryUsage()

	log:write("=== MEMORY USAGE ===")
	log:write( "Lua Objects : " .. MOAISim.getLuaObjectCount() )

	for k,v in pairs(usage) do
		log:write( k .. " : " ..v )
	end
end

local function saveGame( game )
	-- Save the current campaign game progress, if the game isn't over, and this isn't a 'debug' level.
	if game and game.saveCampaign then
        local user = savefiles.getCurrentGame()
        if not game:saveCampaign() then
            return "Save failed!"
        else
        	return string.format( "Game save to slot %d.", user.data.currentSaveSlot )
		end
    else
        log:write( "Not a campaign game: not saving." )
	end
end

local function saveGameBinding()
    return saveGame( game )
end

local function copyToClipboard()
	-- Save the current campaign game progress, if the game isn't over, and this isn't a 'debug' level.
    saveGame( game )

	local clipboardStr = util.formatGameInfo( game and game.params )

	-- Copy to debug location
	if config.DEV then
		statedebug.reportCount = statedebug.reportCount + 1
		local gamePath = KLEIPersistentStorage.getGameFolder()
		local targetPath = string.format( [[X:\klei\InvisibleInc\%s-%s-%d]], MOAIEnvironment.UserID, APP_GUID, statedebug.reportCount )
		MOAILogMgr.flush()
		MOAIFileSystem.affirmPath( targetPath )
		local filesCopied = MOAIFileSystem.copy( gamePath, targetPath )
        if filesCopied then
            filesCopied = MOAIFileSystem.copy( "scripts.zip", targetPath.."/scripts.zip" )
        end
		log:write( "COPY: '%s' to '%s' (%s)", gamePath, targetPath, tostring( filesCopied ) )
        clipboardStr = string.format( "%s-%d (%s)\n%s", APP_GUID, statedebug.reportCount, filesCopied and "Files copied" or "No files", clipboardStr )
		cloud.sendSlackTask( clipboardStr, "#invisible_inc" )
	end

	MOAISim.copyToClipboard( clipboardStr )
	return "Copied to clipboard:\n" .. clipboardStr
end

local function loadSimHistory()
    if game then
	    reinclude( "sim/simhistory" )
	    local simhistory = include( "sim/simhistory" )
	    config.SIM_DATA = simhistory.packActions( game.params, game.simHistory )
        MOAISim.copyToClipboard( config.SIM_DATA )
    end
end


local function toggleISOAlgorithm()
    if game then
        local sortMode = game.layers.main:getSortMode()
        if sortMode == MOAILayer.SORT_ISO then
            sortMode = MOAILayer.SORT_ISO_DBG
            log:write( "selected FAST DBG iso sort" )
            statedebug:setDebugMode( cdefs.DBG_ISOSORT )
	        statedebug.showWorldBounds = false

        elseif sortMode == MOAILayer.SORT_ISO_DBG then
            sortMode = MOAILayer.SORT_ISO_SLOW
            log:write( "selected SLOW iso sort" )
	        statedebug.showWorldBounds = false

        else
            sortMode = MOAILayer.SORT_ISO
            log:write( "selected FAST iso sort" )
	        statedebug.showWorldBounds = false
        end
        assert( sortMode )
        game.layers.main:setSortMode( sortMode )
        game.layers.main:showDebugLines( statedebug.showWorldBounds )
	    MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, 1, 0.0, 0.75, 0.75 )
	    MOAIDebugLines.showStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, true )
    end
end

local timer = MOAITimer.new()
timer:setSpan( 1.0 )
timer:setMode( MOAITimer.PING_PONG )
timer:start()
local function easeFunc( uniforms )
	local t = timer:getTime()
	uniforms:setUniformFloat( "desat_ease", t )
end

local function testColorBlindness()
    if KLEIRenderScene then
        KLEIRenderScene._ColorBindTest = ((KLEIRenderScene._ColorBindTest or 0) + 1) % 4
        KLEIRenderScene:setDaltonizationType( KLEIRenderScene._ColorBindTest )
    end
end

local function testDesaturation()
    if KLEIRenderScene then
        if not KLEIRenderScene._DesaturationTest then
			KLEIRenderScene._DesaturationTest = true
            KLEIRenderScene:setDesaturation( easeFunc )
        else
			KLEIRenderScene._DesaturationTest = false
            KLEIRenderScene:setDesaturation( )
        end
    end
end

local function testBloom()
    if KLEIRenderScene then
        if not KLEIRenderScene._BloomTest then
			KLEIRenderScene._BloomTest = true
            KLEIRenderScene:setGaussianBlur( 1.0 )
        else
			KLEIRenderScene._BloomTest = false
            KLEIRenderScene:setGaussianBlur( )
        end
    end
end

local function testPixelate()
    if KLEIRenderScene then
        if not KLEIRenderScene._PixelateTest then
			KLEIRenderScene._PixelateTest = true
            KLEIRenderScene:setPixelate( 20, 20 )
        else
			KLEIRenderScene._PixelateTest = false
            KLEIRenderScene:setPixelate( )
        end
    end    
end

local function testUIFuzz()
    if KLEIRenderScene then
        KLEIRenderScene:pulseUIFuzz( 10 )
    end
end

local function testUIAscii()
    if KLEIRenderScene then
        KLEIRenderScene._AsciiTest = 0.1 + (KLEIRenderScene._AsciiTest or 0)
        if KLEIRenderScene._AsciiTest > 1 then KLEIRenderScene._AsciiTest = 0 end
        KLEIRenderScene:setAscii( KLEIRenderScene._AsciiTest )
    end
end

local function testUIShutter()
    if KLEIRenderScene then
        KLEIRenderScene:pulseUIShutter( 10, 10 )
    end
end

local function toggleWorldBounds()
	if not game then
		return
	end

	statedebug.showWorldBounds = not statedebug.showWorldBounds

	--MOAIDebugLines.setStyle ( MOAIDebugLines.PARTITION_CELLS, 1, 1, 1, 1 )
	--MOAIDebugLines.setStyle ( MOAIDebugLines.PARTITION_PADDED_CELLS, 1, 0.5, 0.0, 0.5 )
	MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, 1, 0.0, 0.75, 0.75 )
	MOAIDebugLines.showStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, true )
	--MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, 1, 0.5, 0.5, 0.75 )
	--MOAIDebugLines.showStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, true )
	--MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, 1, 0.0, 0.0, 0.75 )

	game.boardRig:getLayer():showDebugLines( statedebug.showWorldBounds )
	--game.boardRig:getLayer("floor"):showDebugLines( statedebug.showWorldBounds )
	--game.boardRig:getLayer("ceiling"):showDebugLines( statedebug.showWorldBounds )
end

local function printThreads()
	if game and game.simThread then
		print( "### SIM THREAD" )
		print( debug.traceback( game.simThread ))
	end
	
	if game and game.viz then
		print( "### VIZ THEAD" )
		game.viz:print()
	end

    if game and game.hud and game.hud._missionPanel then
        print ( "### MISSION PANEL" )
        game.hud._missionPanel:printDebug()
    end
end

local function toggleProfile()
	KLEIProfiler.ToggleRecording()
	local id = KLEIProfiler.Push( "test" )
	KLEIProfiler.Pop( id )
--[[
	include( "profiler" )

	if statedebug.profiler == nil then
		log:write( "### PROFILE START")
		statedebug.profiler = newProfiler()
		statedebug.profiler:start()
	else
		statedebug.profiler:stop()
		log:write( "### PROFILE STOP")

		local outfile = io.open( "profile.txt", "w+" )
		statedebug.profiler:report( outfile )
		outfile:close()

		statedebug.profiler = nil
	end
--]]
end

local function printGarbageCollection()
	util.fullGC()
end

local function executeDbgFile()
	print( "Executing: ", config.DBG_FILE )
	if config.DBG_FILE then
		local f,e = loadfile( config.DBG_FILE )
		if not f then error(e, 2) end
		setfenv(f, getfenv())
		return f()
	end
end

local function toggleALOSDebug()
	print( 'toggleALOSDebug' )
	if game and game.shadow_map then
		statedebug.ALOS_Debug = not statedebug.ALOS_Debug
		game.shadow_map:enableALOSDebug( statedebug.ALOS_Debug )
	end
end
local function toggleELOSDebug()
	print( 'toggleELOSDebug' )
	if game and game.shadow_map then
		statedebug.ELOS_Debug = not statedebug.ELOS_Debug
		game.shadow_map:enableELOSDebug( statedebug.ELOS_Debug )
	end
end

local function showLogFolder()
	MOAISim.showLogFolder()
end

local function cycleLocalPlayer()
	if sim and not game:isReplaying() then
		if game:getLocalPlayer() == nil then
			game:setLocalPlayer( sim:getPlayers()[1] )
		else
			local nextPlayer = sim:getPlayers()[ game.playerIndex + 1 ]
			-- nextPlayer may wrap to nil; this means watch as an observer
			game:setLocalPlayer( nextPlayer )
		end
	end
end

local function cycleDebugMode()
	statedebug:setDebugMode( (statedebug.mode + 1) % cdefs.DBG_MAX )
end

local function addCpuPoints()
	if game then
		game:doAction( "debugAction",
			function( sim )
				sim:getPC():addCPUs(1)
			end )
		end
end

local function addMoney()
	if game then
		game:doAction( "debugAction",
			function( sim )
				sim:getPC():addCredits(100)
			end )
	end
end

local function toggleRooms()
	if game and sim then
		local mode
		local sampleHilite = next(statedebug.roomHilites)
		if not sampleHilite then
			mode = "rooms"
		elseif statedebug.roomHilites[sampleHilite].edges then
			mode = "exits"
		elseif statedebug.roomHilites[sampleHilite].exits then
			mode = nil
		else
			mode = "edges"
		end
		if mode then
			--highlight all the rooms
			sim:forEachCell(function(cell)
				if cell.procgenRoom then
					local roomID = cell.procgenRoom.roomIndex
					if not statedebug.roomHilites[roomID] then
						statedebug.roomHilites[roomID] = {cells={} }
						statedebug.roomHilites[roomID].color = {r=math.random(), g=math.random(), b=math.random()}
					end
					if mode == "exits" then
						if not statedebug.roomHilites[roomID].exits then
							statedebug.roomHilites[roomID].exits = {}
							statedebug.roomHilites[roomID].barriers = {}
						end
						for i,exit in ipairs(cell.procgenRoom.exits) do	
							if cell.x >= exit.x0 and cell.x <= exit.x1 and cell.y >= exit.y0 and cell.y <= exit.y1 then
								if exit.barrier then
									table.insert(statedebug.roomHilites[roomID].barriers, cell)
								else
									table.insert(statedebug.roomHilites[roomID].exits, cell)
								end
								return
							end
						end
					else
						statedebug.roomHilites[roomID].exits = nil
						statedebug.roomHilites[roomID].barriers = nil
					end

					if mode == "edges" then
						if not statedebug.roomHilites[roomID].edges then
							statedebug.roomHilites[roomID].edges = {}
							statedebug.roomHilites[roomID].cells = {}
						end
						if cell.x ~= cell.procgenRoom.xmin and cell.x ~= cell.procgenRoom.xmax
						 and cell.y ~= cell.procgenRoom.ymin and cell.y ~= cell.procgenRoom.ymax
						 and cell.impass == 0 then
							table.insert(statedebug.roomHilites[roomID].cells, cell)
						else
							table.insert(statedebug.roomHilites[roomID].edges, cell)
						end
					else
						if statedebug.roomHilites[roomID].edges then
							statedebug.roomHilites[roomID].edges = nil
							statedebug.roomHilites[roomID].cells = {}
						end
						table.insert(statedebug.roomHilites[roomID].cells, cell)
					end
				end
			end)
		end

		for k,cellHilites in pairs(statedebug.roomHilites) do
			game.boardRig:unhiliteCells(cellHilites.cellHilites)
			if cellHilites.edgeHilites then
				game.boardRig:unhiliteCells(cellHilites.edgeHilites)
				cellHilites.edgeHilites = nil
			end
			if cellHilites.exitHilites then
				game.boardRig:unhiliteCells(cellHilites.exitHilites)
				cellHilites.exitHilites = nil
				game.boardRig:unhiliteCells(cellHilites.barrierHilites)
				cellHilites.barrierHilites = nil
			end
			if mode then
				local color = cellHilites.color
				local exitColor = {r=1, g=0, b=1, a=1}
				local barrierColor = {r=1, g=0, b=0, a=1}
				local alpha = {cells=0.4, edges=0.2, exits=1, barriers=1}
				cellHilites.cellHilites = game.boardRig:hiliteCells(cellHilites.cells, {alpha.cells*color.r, alpha.cells*color.g, alpha.cells*color.b, alpha.cells})
				if cellHilites.edges then
					cellHilites.edgeHilites = game.boardRig:hiliteCells(cellHilites.edges, {alpha.edges*color.r, alpha.edges*color.g, alpha.edges*color.b, alpha.edges})
				end
				if cellHilites.exits then
					cellHilites.exitHilites = game.boardRig:hiliteCells(cellHilites.exits, {alpha.exits*exitColor.r, alpha.exits*exitColor.g, alpha.exits*exitColor.b, alpha.exits})
					cellHilites.barrierHilites = game.boardRig:hiliteCells(cellHilites.barriers, {alpha.barriers*barrierColor.r, alpha.barriers*barrierColor.g, alpha.barriers*barrierColor.b, alpha.barriers})
				end
			else
				statedebug.roomHilites[k] = nil
			end
		end
	end
end


local function toggleReplayPanel()
    local isActive = statedebug.screen:isActive() 
     if statedebug.mode ~= cdefs.DBG_REPLAY or not isActive then
        -- Replay mode either not set and/or debug screen not visible
        statedebug.previousMode = statedebug.mode
        statedebug.previousVis = isActive
    	statedebug:setDebugMode( cdefs.DBG_REPLAY )
        if not isActive then
            toggleVisible()
        end
    else
        -- Revert to previous mode/visibility.
    	statedebug:setDebugMode( statedebug.previousMode )
        if isActive ~= statedebug.previousVis then
            toggleVisible()
        end
   end
end

local function toggleReplayPause()
	if game then
		if game.debugStep ~= nil then
			game.debugStep = nil
		else
			game.debugStep = true
		end
		if statedebug.replayPanel then
			statedebug.replayPanel:updatePanel()
		end
	end
end

local function addAlarm()
	if sim then
		game:doAction("debugAction",
			function(sim)
				sim:trackerAdvance(1)
			end)
	end
end

local function maxAlarm()
	if sim then
		game:doAction("debugAction",
			function(sim)
				sim:trackerAdvance( math.max( 1, sim.getDefs().TRACKER_MAXCOUNT - sim:getTracker() ))
			end)
	end
end

local function simNextTurn()
	if sim and not game:isReplaying() then
		local oldPlayerIndex = game.playerIndex
		game.playerIndex = sim:getTurn()	-- Bypass local player check.
		game:doEndTurn()
		game.playerIndex = oldPlayerIndex
	end
end

local function simWin()
	if sim and not game:isReplaying() and not sim:isGameOver() then
		game:doAction( "debugAction",
			function( sim )
				sim:win()
			end)
	end
end

local function simLose()
	if sim and not game:isReplaying() and not sim:isGameOver() then
		game:doAction( "debugAction",
			function( sim )
				sim:lose()
			end)
	end
end

local function simCreateInterest()
	if sim then

		local selectedUnitID = game.hud:getSelectedUnit() and game.hud:getSelectedUnit():getID()
		if selectedUnitID then

			local x, y = game:wndToCell( inputmgr:getMouseXY() )
			local function fn( sim, unitID, x, y )
				local unit = sim:getUnit( unitID )
				if unit and unit:getBrain() then
					unit:getBrain():spawnInterest(x, y, sim:getDefs().SENSE_DEBUG, sim:getDefs().REASON_NOTICED)
				end
			end
			game:doAction( "debugAction", fn, selectedUnitID, x, y )
		end
			
	end
end

local function simKillOthers()
	if sim then
		local x, y = game:wndToCell( inputmgr:getMouseXY() )
		local function fn( sim, x, y )
			local cell = sim:getCell( x, y )
			local survivor = cell and cell.units[1]
			if survivor then
				sim:forEachUnit(function(unit)
					if unit:getPlayerOwner() == survivor:getPlayerOwner() and unit ~= survivor then
						unit:killUnit(sim)
					end
				end)
			end
		end
		game:doAction( "debugAction", fn, x, y )
	end
end

local BINDINGS =
{
	DEV =
	{
        {{ mui_defs.K_A, mui_defs.K_CONTROL }, addAlarm },
		{{ mui_defs.K_A, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, maxAlarm },
        {{ mui_defs.K_B, mui_defs.K_CONTROL }, toggleWorldBounds },
        {{ mui_defs.K_B, mui_defs.K_CONTROL, mui_defs.K_SHIFT  }, toggleISOAlgorithm },
        {{ mui_defs.K_C, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, reloadConfig },
		{{ mui_defs.K_D, mui_defs.K_CONTROL }, executeDbgFile },
        {{ mui_defs.K_E, mui_defs.K_CONTROL }, cycleDebugMode },
        {{ mui_defs.K_G, mui_defs.K_CONTROL }, printGarbageCollection },
        {{ mui_defs.K_I, mui_defs.K_CONTROL }, simCreateInterest },
		{{ mui_defs.K_K, mui_defs.K_CONTROL }, cheatmenu.simKill },
		{{ mui_defs.K_K, mui_defs.K_SHIFT }, cheatmenu.simKO },
		{{ mui_defs.K_K, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, simKillOthers },
        {{ mui_defs.K_L, mui_defs.K_CONTROL }, simLose },
        {{ mui_defs.K_L, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, showLogFolder },
        {{ mui_defs.K_M, mui_defs.K_CONTROL }, printMemoryUsage },
        {{ mui_defs.K_N, mui_defs.K_CONTROL }, simNextTurn },
        {{ mui_defs.K_P, mui_defs.K_SHIFT }, toggleProfile },
		{{ mui_defs.K_R, mui_defs.K_CONTROL }, toggleReplayPanel },
		{{ mui_defs.K_R, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, toggleRooms },
		{{ mui_defs.K_T, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, printThreads },
		{{ mui_defs.K_T, mui_defs.K_CONTROL }, cheatmenu.teleportSelected },		
        {{ mui_defs.K_U, mui_defs.K_CONTROL }, cheatmenu.unlockAllRewards },
        {{ mui_defs.K_V, mui_defs.K_CONTROL }, addCpuPoints },
		{{ mui_defs.K_V, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, cheatmenu.seeEverything },
		{{ mui_defs.K_W, mui_defs.K_CONTROL }, simWin },
        {{ mui_defs.K_Z, mui_defs.K_CONTROL }, addMoney },
        {{ mui_defs.K_F1 }, copyToClipboard },
        {{ mui_defs.K_F2 }, loadSimHistory },
		{{ mui_defs.K_F3 }, saveGameBinding },
		{{ mui_defs.K_F5 }, gameReset },
        {{ mui_defs.K_F8, mui_defs.K_CONTROL }, toggleALOSDebug },
        {{ mui_defs.K_F9, mui_defs.K_CONTROL }, toggleELOSDebug },
        {{ mui_defs.K_BREAK }, toggleReplayPause },
        {{ mui_defs.K_ENTER, mui_defs.K_CONTROL }, cycleLocalPlayer },

        {{ mui_defs.K_F1, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, testBloom },
        {{ mui_defs.K_F2, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, testDesaturation },
        {{ mui_defs.K_F3, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, testPixelate },
        {{ mui_defs.K_F4, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, testColorBlindness },
        {{ mui_defs.K_F5, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, testUIAscii },
        {{ mui_defs.K_F6, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, testUIShutter },
        {{ mui_defs.K_F7, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, testUIFuzz },

	},
	RELEASE =
	{
		{{ mui_defs.K_F1 }, copyToClipboard },
		{{ mui_defs.K_L, mui_defs.K_CONTROL, mui_defs.K_SHIFT }, showLogFolder },
	},
}


local function onDebugModeChanged( str, cmb )
	statedebug:setDebugMode( cdefs[ str ] )
end

----------------------------------------------------------------
-- statedebug Interface

function statedebug:addKeyBinding( keys, fn )
    local newBinding = mui_util.makeBinding( keys )
	for i, dbgBinding in ipairs( self.keybindings ) do
        if mui_util.isBinding( dbgBinding.binding, newBinding ) then
			log:write("Replacing duplicate key binding: %s", mui_util.getBindingName( newBinding ))
			binding.fn = fn
			return
        end
	end

    --log:write( "Debug binding: %s", mui_util.getBindingName( newBinding ))
	table.insert( self.keybindings, { binding = newBinding, fn = fn } )
end

function statedebug:onInputEvent( event )
	if event.eventType == mui_defs.EVENT_KeyDown or event.eventType == mui_defs.EVENT_KeyRepeat then
		if event.key == mui_defs.K_BACKQUOTE and event.controlDown then
			toggleVisible()
		else
			for i, dbgBinding in ipairs( self.keybindings ) do
                if mui_util.isBinding( event, dbgBinding.binding ) then
                    assert( type(dbgBinding.fn) == "function" )
                    local bindingTxt = mui_util.getBindingName( dbgBinding.binding )
                    cheatmenu.executeBinding( bindingTxt, debugenv, dbgBinding.fn )
					return true
				end
			end
		end
	end

    if self.cheatMenu then
        if self.cheatMenu:onInputEvent( event ) then
            return true
        end
    end

	if (statedebug.ALOS_Debug or statedebug.ELOS_Debug) and event.eventType == mui_defs.EVENT_MouseMove then
		local game = debugenv:getCurrentGame()
		local shadow_map = game and game.shadow_map
		if shadow_map then
			local x,y = game:wndToWorld( event.wx, event.wy )
			if x and y then
				--print( 'mouse', event.wx, event.wy, x,y )
				if statedebug.ALOS_Debug then
					shadow_map:setALOSDebugPos( x, y )
				end
				if statedebug.ELOS_Debug then
					shadow_map:setELOSDebugPos( x, y )
				end
			end
		end
	end

	return false
end

function statedebug:setDebugMode( mode )
	self.mode = mode or cdefs.DBG_NONE
	log:write( "DBG MODE: [%s]", tostring(self.mode))

	for i = 1, self.screen.binder.modeCmb:getItemCount() do
		local modeName = self.screen.binder.modeCmb:getItem( i )
		if cdefs[ modeName ] == self.mode then
			self.screen.binder.modeCmb:selectIndex( i )
			break
		end
	end
    self.screen.binder.modeCmb:setVisible( config.DEV )

	local game = debugenv:getCurrentGame()
	if game then
		game.debugMode = statedebug.mode
	end
end

function statedebug:getBuildText()
	local game = debugenv:getCurrentGame()
	return string.format(  'BUILD TAG : %s\nBUILD DATE : %s\n%s',
		MOAIEnvironment.Build_Tag, MOAIEnvironment.Build_Date, util.formatGameInfo( game and game.params ) )
end

local function addSoundMarker( cellID, x, y, markers, oldMarkers )
	-- Create a sound marker for this badboy.
	markers[ cellID ], oldMarkers[ cellID ] = oldMarkers[ cellID ] or markers[ cellID ], nil
	if debugenv.game and markers[ cellID ] == nil then
		local wx, wy = debugenv.game:cellToWorld( x, y )
		markers[ cellID ] = debugenv.game.fxmgr:addLabel( tostring(cellID), wx, wy )
	end

end

function statedebug:updateSoundMarkers()
	if self.mode == cdefs.DBG_SOUND then
		local markers = {}
		local soundDbg = MOAIFmodDesigner.getDebugInfo()
		local simquery = include( "sim/simquery" )

		for i, event in ipairs(soundDbg) do
			if event.x and event.y then
				local cellID = simquery.toCellID( event.x, event.y )
				addSoundMarker( cellID, event.x, event.y, markers, self.soundMarkers )
			end
		end

		for i, event in ipairs(soundDbg.recent) do
			if event.x and event.y then
				local cellID = simquery.toCellID( event.x, event.y )
				addSoundMarker( cellID, event.x, event.y, markers, self.soundMarkers )
			end
		end

		-- Update sound markers.
		for cellID, fx in pairs( self.soundMarkers ) do
			fx:destroy()
		end
		self.soundMarkers = markers		
	else
		for cellID, fx in pairs( self.soundMarkers ) do
			fx:destroy()
		end
		self.soundMarkers = {}
	end
end

function statedebug:updateHunts()
	if not debugenv.game or not debugenv.sim then
		return
	end
	local aiPlayer = debugenv.sim:getNPC()
	local hunt = nil
	if self.mode == cdefs.DBG_SITUATION then
		local selectedUnitID = debugenv.game.hud:getSelectedUnit() and debugenv.game.hud:getSelectedUnit():getID()
		if selectedUnitID and debugenv.sim:getUnit( selectedUnitID ) then
			local selectedUnit = debugenv.sim:getUnit( selectedUnitID )
			if selectedUnit:getBrain() and selectedUnit:getBrain():getSituation().ClassType == debugenv.simdefs.SITUATION_HUNT then
				hunt = selectedUnit:getBrain():getSituation()
			end
		end
	end

	if hunt then
		debugenv.sim:forEachCell(function(cell)
			if cell.procgenRoom then
				local roomID = cell.procgenRoom.roomIndex
				if not self.huntHilites[roomID] then
					self.huntHilites[roomID] = {}
				end
				if hunt.openRooms[roomID] then
					if not self.huntHilites[roomID].open then
						self.huntHilites[roomID].open = {}
					end
					if not self.huntHilites[roomID].openHilites then
						table.insert(self.huntHilites[roomID].open, cell)
					end
				else
					self.huntHilites[roomID].open = nil
				end
				if hunt.closedRooms[roomID] then
					if not self.huntHilites[roomID].closed then
						self.huntHilites[roomID].closed = {}
					end
					if not self.huntHilites[roomID].closedHilites then
						table.insert(self.huntHilites[roomID].closed, cell)
					end
				else
					self.huntHilites[roomID].closed = nil
				end
			end
		end)
	end

	for k,cellHilites in pairs(self.huntHilites) do
		if hunt then
			local openColor = {r=0, g=1, b=0, a=1}
			local closedColor = {r=1, g=0, b=0, a=1}
			if cellHilites.open and not cellHilites.openHilites then
				cellHilites.openHilites = debugenv.game.boardRig:hiliteCells(cellHilites.open, {openColor.r, openColor.g, openColor.b, 1})
			elseif not cellHilites.open then
				debugenv.game.boardRig:unhiliteCells(cellHilites.openHilites)
				cellHilites.openHilites = nil
			end
			if cellHilites.closed and not cellHilites.closedHilites then
				cellHilites.closedHilites = debugenv.game.boardRig:hiliteCells(cellHilites.closed, {closedColor.r, closedColor.g, closedColor.b, 1})
			elseif not cellHilites.closed then
				debugenv.game.boardRig:unhiliteCells(cellHilites.closedHilites)
				cellHilites.closedHilites = nil
			end
		else
			if cellHilites.openHilites then
				debugenv.game.boardRig:unhiliteCells(cellHilites.openHilites)
			end
			if cellHilites.closedHilites then
				debugenv.game.boardRig:unhiliteCells(cellHilites.closedHilites)
			end
			self.huntHilites[k] = {}
		end
	end
end


function statedebug:getSoundText()
	local simquery = include( "sim/simquery" )
	local soundDbg = MOAIFmodDesigner.getDebugInfo()
	local txt = {}

	table.insert( txt, "<c:CCFFCC>MIXES: " )
	for _, mix in ipairs( FMODMixer:getMixes() ) do
		table.insert( txt, mix._name.." " )
	end
	table.insert( txt, "</>\n" )

	table.insert( txt, string.format( "<c:CCFFCC>FRAME: %d, FILTER: '%s'</>\n\n", soundDbg.frame, soundDbg.filter ))

	table.insert( txt, "<c:CCFFCC>== CURRENT SOUNDS:</>\n")
	for i, event in ipairs(soundDbg) do
		table.insert( txt, string.format( "%02d] %s [%s]\n", i, event.soundPath, event.alias ))
		if event.x and event.y then
			local cellID = simquery.toCellID( event.x, event.y )
			table.insert( txt, string.format( "    id=<c:ffffff>%d</>vol=%.2f, occ=%.2f, pos = <%d, %d>\n", cellID, event.volume, event.occlusion, event.x, event.y ))
		end
	end

	table.insert( txt, "\n<c:CCFFCC>== RECENT SOUNDS:</>\n" )

	for i, event in ipairs(soundDbg.recent) do
		if soundDbg.frame - event.frame < 60 then
			table.insert( txt, "<c:77FF77>" )
		end
		table.insert( txt, string.format( "%02d] %s\n", i, event.soundPath ))
		if event.x and event.y then
			local cellID = simquery.toCellID( event.x, event.y )
			table.insert( txt, string.format( "    id=<c:ffffff>%d</> vol=%.2f, occ=%.2f, pos=<%d, %d>, frame=%d\n", cellID, event.volume, event.occlusion, event.x, event.y, event.frame ))
		end
		if event.frame - soundDbg.frame < 60 then
			table.insert( txt, "</>" )
		end
	end

	return table.concat( txt )
end

function statedebug:updatePaths(selectedUnit)
	if not debugenv.sim then
		return
	end
	local pather = debugenv.sim:getNPC().pather

	if self.mode == cdefs.DBG_PATHING and debugenv.game.simHistoryIdx == self.simHistoryIndex then
		if self.selectedUnit ~= selectedUnit then
			for k,v in pairs(self.pathMarkers) do
				if v.unit == self.selectedUnit or v.unit == selectedUnit then
					debugenv.game.boardRig:unchainCells(v.chain)
					for kk,action in pairs(v.actions) do
						action:destroy()
					end
					self.pathMarkers[k] = nil
					for kk,vv in pairs(self.pathReserves) do
						local reserve = pather._pathReserves[kk]
						if reserve and reserve.path.id == k then
							vv:destroy()
							self.pathReserves[kk] = nil
						end
					end
				end
			end
		end
		--create any new paths
		for k,v in pairs(pather._paths) do
			if v.path then
				if not self.pathMarkers[v.id] then
					local nodes = {}
					local actions = {}
					local color = {r=math.random(),g=math.random(),b=math.random(),a=1}
					if v.unit == selectedUnit then
						color = {r=1.0,g=1.0,b=0,a=1}
					end
					table.insert(nodes, v.path.startNode.location)
					if v.actions and v.actions[v.path.startNode.lid] then
						local wx, wy = debugenv.game:cellToWorld(v.path.startNode.location.x, v.path.startNode.location.y)
						table.insert(actions, debugenv.game.fxmgr:addLabel( tostring(v.actions[v.path.startNode.lid].ability), wx, wy, nil, color ) )
					end
					for i,node in ipairs(v.path.nodes) do
						table.insert(nodes, node.location)
						if v.actions and v.actions[node.lid] then
							local wx, wy = debugenv.game:cellToWorld(node.location.x, node.location.y)
							table.insert(actions, debugenv.game.fxmgr:addLabel( tostring(v.actions[node.lid].ability), wx, wy, nil, color ) )
						end
					end
					self.pathMarkers[v.id] = {unit=v.unit, color=color, chain=debugenv.game.boardRig:chainCells(nodes, color), actions=actions }
				end
			end
		end

		--remove any unneeded paths
		for k,v in pairs(self.pathMarkers) do
			if not v.unit:isValid() or not pather._paths[v.unit:getID()] or pather._paths[v.unit:getID()].id ~= k then
				debugenv.game.boardRig:unchainCells(v.chain)
				for kk,action in pairs(v.actions) do
					action:destroy()
				end
				self.pathMarkers[k] = nil
			end
		end

		--create any new path reserves
		for k,v in pairs(pather._pathReserves) do
			if not self.pathReserves[k] then
				local wx, wy = debugenv.game:cellToWorld(v.node.location.x, v.node.location.y)
				local offset = 12
				wx, wy = wx+offset*math.sin(v.node.t*(math.pi/6)), wy+offset*math.cos(v.node.t*(math.pi/6))
				local color = self.pathMarkers[v.path.id] and self.pathMarkers[v.path.id].color
				if v.path.unit == selectedUnit then
					color = {r=1.0,g=1.0,b=0,a=1}
				end
				self.pathReserves[k] = debugenv.game.fxmgr:addLabel( "t"..tostring(v.node.t), wx, wy, nil, color )
			end
		end

		--remove any unneeded path reserves
		for k,v in pairs(self.pathReserves) do
			if not pather._pathReserves[k] then
				v:destroy()
				self.pathReserves[k] = nil
			end
		end
	else
		for k,v in pairs(self.pathMarkers) do
			debugenv.game.boardRig:unchainCells(v.chain)
			for kk,action in pairs(v.actions) do
				action:destroy()
			end
			self.pathMarkers[k] = nil
		end
		for k,v in pairs(self.pathReserves) do
			v:destroy()
			self.pathReserves[k] = nil
		end
	end

end


function statedebug:getPathingText(selectedUnit)
	if not debugenv.sim then
		return
	end
	local txt = {}

	local pather = debugenv.sim:getNPC().pather

	local function printPath(txt, path, selectedUnit)
		if selectedUnit and path.unit == selectedUnit then
			table.insert(txt, "<c:ffff00>")
		end
		table.insert(txt, string.format("%d", path.id) )
		if path.unit == path.unit:getPlayerOwner():getCurrentAgent() then
			table.insert(txt, ">>")
		else
			table.insert(txt, "  ")
		end
		table.insert(txt, string.format("Unit:[%s] Priority:%d", tostring(path.unit:getID() ), path.priority ) )
		if path.path then
			table.insert(txt, string.format(" From:(%d,%d) To:(%d,%d)", path.path.startNode.location.x, path.path.startNode.location.y, path.goalx, path.goaly) )
			if path.goaldir then
				table.insert(txt, string.format(" Face:%s", debugenv.simdefs:stringForDir(path.goaldir) ) )
			end
			if path.targetUnit then
				table.insert(txt, string.format(" TargetUnit:[%d]", path.targetUnit:isValid() and path.targetUnit:getID() or -1 ) )
			end
			if path.result then
				table.insert(txt, string.format(" Result:%s", path.result ) )
			end
		end
		if selectedUnit and path.unit == selectedUnit then
			table.insert(txt, "</>")
		end
	end

	local allPaths = util.tdupe(pather._paths)
	for i,path in ipairs(pather._prioritisedPaths) do
		allPaths[path.unit:getID()] = nil
		table.insert(txt, tostring(i)..": ")
		printPath(txt, path, selectedUnit)
		table.insert(txt, "\n")
	end
	if next(allPaths) then
		table.insert(txt, "--UNPRIORITISED--\n")
		for k,path in pairs(allPaths) do
			printPath(txt, path, selectedUnit)
			table.insert(txt, "\n")
		end
	end

	return table.concat(txt)
end

function statedebug:getMissionText()
	if not debugenv.sim then
		return
	end
	local txt = {}

	local ls = debugenv.sim:getLevelScript()

    table.insert( txt, string.format( "%d mission hooks\n", #ls.hooks ))

	--create any new paths
	for i, hook in pairs( ls.hooks ) do
		table.insert( txt, string.format( "\n<c:ffffff>%d] %s</>", i, hook.name ))
		table.insert( txt, debug.traceback(hook.thread, "", 2) )
		table.insert( txt, "\n" )
	end

	return table.concat(txt)
end

function statedebug:getAIPlayerText(selectedUnit)
	local txt = {}

	local aiPlayer = debugenv.sim:getNPC()

	local function printUnit(unit, txt, selectedUnit)
		if selectedUnit and selectedUnit == unit then
			table.insert(txt, "<c:ffff00>")
		end
		table.insert(txt, "["..tostring(unit:getID() ).."]")
		if unit == aiPlayer:getCurrentAgent() then
			table.insert(txt, ">>")
		else
			table.insert(txt, "  ")
		end
		table.insert(txt, string.format("Unit:%s", unit:getUnitData().name) )
		if selectedUnit and selectedUnit == unit then
			table.insert(txt, "</>")
		end
	end

	if aiPlayer:getCurrentAgent() then
		printUnit(aiPlayer:getCurrentAgent(), txt, selectedUnit)
		table.insert(txt, "\n")
	end

	if aiPlayer.bunits then
		for i,unit in ipairs(aiPlayer.bunits) do
			printUnit(unit, txt, selectedUnit)
			table.insert(txt, "\n")
		end
	end

	if next(aiPlayer.processedUnits) then
		table.insert(txt, "--PROCESSED--\n")
		for i, unit in ipairs(aiPlayer.processedUnits) do
			printUnit(unit, txt, selectedUnit)
			table.insert(txt, "\n")
		end
	end

	return table.concat(txt)
end

function statedebug:getDebugText(unit, debugMode)
	local unitrig = debugenv.boardRig:getUnitRig(unit:getID() )
	if not unitrig or not unit.getUnitData then
		return
	end

	local unitText = {}

	if debugMode == cdefs.DBG_PATHING then
		table.insert(unitText, self:getPathingText(unit) )
		table.insert(unitText, "\n----------------------------------\n")
	elseif debugMode == cdefs.DBG_BTREE then
		table.insert(unitText, self:getAIPlayerText() )
		table.insert(unitText, "\n----------------------------------\n")
	else
		table.insert(unitText, string.format("UNIT: %s (%s)[%d]\n", unit:getUnitData().name, tostring(unit:getUnitData().class or "guard"), unit:getID() ) )
		table.insert(unitText, string.format("FACING:%s (%s)\n", tostring(unit:getFacing() ), unit:getSim():getDefs():stringForDir(unit:getFacing() ) ) )
		table.insert(unitText, string.format("AP:%s MP:%s\n", tostring(unit.getAP and unit:getAP()), tostring(unit.getMP and unit:getMP() ) ) )
		table.insert(unitText, string.format("Owner:%s\n", util.debugPrintTableWithColours(unit.getPlayerOwner and unit:getPlayerOwner() ) ) )
	end

	if debugMode == cdefs.DBG_TRAITS then
		table.insert(unitText, "TRAITS:\n"..util.debugPrintTableWithColours(unit:getTraits(), 2) )
		table.insert(unitText, "\nCHILDREN:\n"..util.debugPrintTableWithColours(unit:getChildren(), 1) )
	elseif debugMode == cdefs.DBG_DATA then
		table.insert(unitText, "DATA:\n")
		for k,v in pairs(unit:getUnitData() ) do
			if k ~= "speech" and k ~= "sounds" and k ~= "traits" and k ~= "children" and k ~= "blurb" and type(k) ~= "function" then
				table.insert(unitText, tostring(k) )
				table.insert(unitText, "=")
				if type(v) == "table" then
					table.insert(unitText, util.debugPrintTableWithColours(v, 3) )
				else
					table.insert(unitText, tostring(v) )
				end
				table.insert(unitText, "\n")
			end
		end
	elseif debugMode == cdefs.DBG_RIGS then
		table.insert(unitText, "\nRIG INFO:\n"..(unitrig._state and unitrig._state:generateTooltip() or "") )
		if unitrig._prop and unitrig._prop.getCurrentAnim then
			local flipped = unitrig._prop:getScl() < 0
			table.insert(unitText, string.format("\nANIM:%s (%s) %s", unitrig._prop:getCurrentAnim(), unitrig._prop:getAnimFacing(), flipped and "(flipped)" or "" ) )
		end
		table.insert(unitText, string.format("\nFACING:%s, VISIBLE:%s SHOULDDRAW:%s", unit:getSim():getDefs():stringForDir(unitrig:getFacing() ), tostring(unitrig._prop:getVisible() ), tostring(unitrig._prop:shouldDraw() ) ) )
        
	elseif debugMode == cdefs.DBG_BTREE then
		if unit.getBrain and unit:getBrain() then
			table.insert(unitText, "\nBRAIN:\n"..(unit:getBrain():getBTreeString() ) )
		end
	elseif debugMode == cdefs.DBG_SITUATION then
		if unit.getBrain and unit:getBrain() then
			if unit:isAlerted() then
				table.insert(unitText, "<c:ff0000>!!ALERTED!!</>\n")
			end
			table.insert(unitText, string.format("Destination:%s\nTarget:%s\nInterest:%s\nSituation\n%s",
				util.debugPrintTableWithColours(unit:getBrain():getDestination() ),
				util.debugPrintTableWithColours(unit:getBrain():getTarget() ),
				util.debugPrintTableWithColours(unit:getBrain():getInterest() ),
				util.debugPrintTableWithColours(unit:getBrain():getSituation(), 2) ) )
			if unit:getBrain():getSenses() then
				if unit:getBrain():getSenses():checkDisabled() then
					table.insert(unitText, string.format("\nSENSES DISABLED\n") )
				end
				if unit:getBrain():getSenses():shouldUpdate() then
					table.insert(unitText, string.format("\nSENSES NEED UPDATE\n") )
				end
				table.insert(unitText, string.format("\n---------------\nTargets\n") )
				for k,v in pairs(unit:getBrain():getSenses().targets) do
					if v.unit == unit:getBrain():getSenses():getCurrentTarget() then
						table.insert(unitText, ">  ")
					end
					table.insert(unitText, util.debugPrintTableWithColours(v) )
					table.insert(unitText, "\n")
				end
				table.insert(unitText, string.format("\n---------------\nInterests\n") )
				for i,v in ipairs(unit:getBrain():getSenses().interests) do
					if v == unit:getBrain():getSenses():getCurrentInterest() then
						table.insert(unitText, ">  ")
					end
					table.insert(unitText, util.debugPrintTableWithColours(v) )
					table.insert(unitText, "\n")
				end
			end
		end
	elseif debugMode == cdefs.DBG_PATHING then
		local pather = unit:getPather()
		if pather then
			local path = pather:getPath(unit)
			if path then
				if inputmgr.keyIsDown( mui_defs.K_SHIFT ) then
					local reservations = {}
					table.insert(unitText, "Reservations:\n")
					for k,v in pairs(pather._pathReserves) do
						if v.path == path then
							table.insert(reservations, {key=k, reservation=v} )
						end
					end
					table.sort(reservations, function(a,b) return a.reservation.node.t < b.reservation.node.t end)
					for i,v in ipairs(reservations) do
						table.insert(unitText, tostring(i)..". "..tostring(v.key).." = ")				
						table.insert(unitText, util.debugPrintTableWithColours(v.reservation, 1) )
						table.insert(unitText, "\n")				
					end
				elseif inputmgr.keyIsDown( mui_defs.K_CONTROL ) then
					table.insert(unitText, "Actions:\n")
					if next(path.actions) then
						for k,v in pairs(path.actions) do
							table.insert(unitText, tostring(k))
							table.insert(unitText, ": ")
							table.insert(unitText, util.debugPrintTableWithColours(v, 2) )
							table.insert(unitText, "\n")
						end
					end
				else
					if path.path then
						local pathNodes = {}
						table.insert(unitText, "Path:\n")
						table.insert(pathNodes, path.path.startNode)
						if path.path.nodes then
							for k,v in ipairs(path.path.nodes) do
								table.insert(pathNodes, v)
							end
						end
						for i,v in ipairs(pathNodes) do
							table.insert(unitText, util.debugPrintTableWithColours(v, 1) )
							table.insert(unitText, "\n")				
						end
					end
				end
			end
		end
	end
	return table.concat(unitText)
end

----------------------------------------------------------------
statedebug.onLoad = function ( self )

	inputmgr.addListener( self, 1 )

	self.startTime = MOAISim.getDeviceTime ()

	self.screen = mui.createScreen( "debug-panel.lua" )
    self.screen:getProperties().alwaysVisible = true

	self.fpsText = self.screen:findWidget("fpsTxt")
	self.debugTxt = self.screen:findWidget("txt")
	self.debugBg = self.screen:findWidget( "txtBg" )

	self.screen.binder.modeCmb:addItem( "DBG_NONE" )
	self.screen.binder.modeCmb:addItem( "DBG_TRAITS" )
	self.screen.binder.modeCmb:addItem( "DBG_DATA" )
	self.screen.binder.modeCmb:addItem( "DBG_RIGS" )
	self.screen.binder.modeCmb:addItem( "DBG_BTREE" )
	self.screen.binder.modeCmb:addItem( "DBG_SITUATION" )
	self.screen.binder.modeCmb:addItem( "DBG_PROCGEN" )
	self.screen.binder.modeCmb:addItem( "DBG_SOUND" )
	self.screen.binder.modeCmb:addItem( "DBG_PATHING" )
	self.screen.binder.modeCmb:addItem( "DBG_MISSIONS" )
	self.screen.binder.modeCmb:addItem( "DBG_REPLAY" )
	self.screen.binder.modeCmb:addItem( "DBG_ISOSORT" )
	self.screen.binder.modeCmb.onTextChanged = onDebugModeChanged
	self:setDebugMode( self.mode )

    local bindings = config.DEV and BINDINGS.DEV or BINDINGS.RELEASE
	for i, binding in ipairs( bindings ) do
		self:addKeyBinding( binding[1], binding[2] )
	end

    if config.DEV then
        local replay_panel = include( "hud/replay_panel" )
        self.replayPanel = replay_panel( self.screen )
    end
end

----------------------------------------------------------------
statedebug.onUnload = function ( self )

	inputmgr.removeListener( self )
	if self.screen:isActive() then
		mui.deactivateScreen( self.screen )
	end
    self.replayPanel = nil
	self.screen = nil
	self.fpsText = nil
end

----------------------------------------------------------------

local recentUpdateTimes = {}
local recentRenderTimes = {}
local RECENT_TIMES = 120

local function UpdateRunning( arr, val )
	table.insert(arr, val)
	if #arr > RECENT_TIMES then
		table.remove(arr, 1)
	end

	local max = 0
	for i,v in ipairs(arr) do
		max = math.max(max, v)
	end
	return max
end

----------------------------------------------------------------
statedebug.onUpdate = function ( self )

	debugenv:updateEnv()
	local selectedUnit = debugenv.game and debugenv.game.hud and debugenv.game.hud:getSelectedUnit()
	self:updatePaths(selectedUnit)
	self:updateSoundMarkers()
	self:updateHunts()

	if self.screen:isActive() then
		local elapsedSecs = MOAISim.getDeviceTime () - self.startTime

		local lastUpdate, lastSimSteps = MOAISim.getTimings()
		local lastRender = MOAIRenderMgr.getPerformanceTimings()
		local maxUpdate = UpdateRunning(recentUpdateTimes, lastUpdate)
		local maxRender = UpdateRunning(recentRenderTimes, lastRender)

		local fpsText = string.format( "FPS: %.0f, T: %.2f, LU: %.2f, SS: %d, LR: %.2f, MU: %.2f, MR: %.2f", MOAISim.getPerformance(), elapsedSecs, lastUpdate, lastSimSteps, lastRender, maxUpdate, maxRender )
		self.fpsText:setText( fpsText )

		if self.mode == cdefs.DBG_NONE then
			self.debugTxt:setVisible(true)
            local txt = self:getBuildText()
            if self.cheatMenu then
                txt = txt .. "\n" .. self.cheatMenu:getHeader()
            end
			self.debugTxt:setText( txt )

		elseif self.mode == cdefs.DBG_SOUND then
			self.debugTxt:setVisible(true)
			self.debugTxt:setText( self:getSoundText() )

		elseif self.mode == cdefs.DBG_MISSIONS then
			self.debugTxt:setVisible(true)
			self.debugTxt:setText( self:getMissionText() )

        elseif self.mode == cdefs.DBG_REPLAY then
			self.debugTxt:setVisible(true)
            if self.replayPanel then
                local events = self.replayPanel:getEventsText()
				self.debugTxt:setText( events )
            else
                self.debugTxt:setText( "NO GAME IN SESSION" )
            end

		elseif self.mode == cdefs.DBG_PROCGEN and debugenv.game then
			local cellx, celly = debugenv.game:wndToCell( inputmgr.getMouseXY() )
			local cell = debugenv.sim:getCell( cellx, celly )
			local txt = ""
			if config.PATTERN then
				local flagStr, bits = config.PATTERN:getFlags( cellx, celly )
				txt = string.format( "FLAGS [%d]: %s\n", bits, flagStr )
			end
			if cell and cell.procgenRoom then
				if inputmgr.keyIsDown( mui_defs.K_SHIFT ) then
					txt = txt.. string.format( "Room Walls:\n%s\n", util.stringize( cell.procgenRoom.walls, 2 ) )
				elseif inputmgr.keyIsDown( mui_defs.K_CONTROL ) then
					txt = txt.. string.format( "Room Exits:\n%s\n", util.debugPrintTableWithColours(cell.procgenRoom.exits, 2) )
				else
					txt = txt.. string.format( "Zone %s: %s\n",
						tostring(cell.procgenRoom.zoneID), cell.procgenRoom.zone and cell.procgenRoom.zone.name or "nozone")
					if self.roomHilites[cell.procgenRoom.roomIndex] then
						local color = self.roomHilites[cell.procgenRoom.roomIndex].color
						txt = txt..string.format("<c:%s>Room %d (%d->%d, %d->%d):\n%s</>\n", util.stringizeRGBFloat(color.r, color.g, color.b),
						cell.procgenRoom.roomIndex, cell.procgenRoom.xmin, cell.procgenRoom.xmax, cell.procgenRoom.ymin, cell.procgenRoom.ymax,
						util.stringize( cell.procgenRoom, 1 ) )
					else
						txt = txt..string.format("Room (%d->%d, %d->%d) containing %d rects:\n%s\n",
						cell.procgenRoom.xmin, cell.procgenRoom.xmax, cell.procgenRoom.ymin, cell.procgenRoom.ymax, #cell.procgenRoom.rects, util.stringize( cell.procgenRoom, 1 ) )
					end
					txt = txt..string.format( "Prefab: %s", util.stringize(cell.procgenPrefab) )
				end
			elseif cell then
				txt = txt .. string.format( "Prefab: %s", util.stringize(cell.procgenPrefab) )
			end
			self.debugTxt:setVisible(true)
			self.debugTxt:setText( txt )

        elseif self.mode == cdefs.DBG_ISOSORT and debugenv.game then
            local lines = {}
            local wx, wy = debugenv.game:wndToWorld( inputmgr.getMouseXY() )
            local ps = debugenv.game.layers.main:propListForPoint( wx, wy, 0, MOAILayer.SORT_ISO )
            local t = debugenv.game.layers.main:getDebugIso()
            table.insert( lines, util.stringize(t) )
            if not ps then
	            table.insert( lines, "NO PROPS" )
            else
	            for k, v in pairs(ps) do
		            if not v:getBounds() then
			            table.insert( lines, string.format( "%d) %s [%s] (NO BOUNDS)", v:getPriority(), tostring(v), v:getDebugName() ))
		            else
                        local x, y, z, X, Y, Z = v:getWorldBounds()
			            table.insert( lines, string.format( "%d) %s [%s]", v:getPriority(), tostring(v), v:getDebugName() ))
                        table.insert( lines, string.format("\tX: %f -> %f", x, X ))
                        table.insert( lines, string.format("\tY: %f -> %f", y, Y ))
                        table.insert( lines, string.format("\tZ: %f -> %f", z, Z ))
		            end
	            end
            end
            self.debugTxt:setVisible( true )
            self.debugTxt:setText( table.concat( lines, "\n" ))

		else
			if selectedUnit then
				self.debugTxt:setText(self:getDebugText(selectedUnit, self.mode ) )
				self.debugTxt:setVisible(true)
			elseif self.mode == cdefs.DBG_PATHING then
				self.debugTxt:setVisible(true)
				self.debugTxt:setText(self:getPathingText() )
			elseif self.mode == cdefs.DBG_BTREE then
				self.debugTxt:setVisible(true)
				self.debugTxt:setText(self:getAIPlayerText() )
			else
				self.debugTxt:setVisible(false)
			end
		end

		if self.debugTxt:isVisible() then
			local W, H = self.screen:getResolution()
			local xmin, ymin, xmax, ymax = self.debugTxt:getStringBounds()
			self.debugBg:setPosition( W * (xmax + xmin) / 2, H * (ymax + ymin) / 2 )
			self.debugBg:setSize( W * (xmax - xmin), H * (ymax - ymin) )
			self.debugBg:setVisible( true )
		else
			self.debugBg:setVisible( false )
		end

        if self.cheatMenu then
            self.cheatMenu:setVisible( self.mode == cdefs.DBG_NONE and config.DEV )
        end
    end

    self.selectedUnit = selectedUnit
    self.simHistoryIndex = debugenv and debugenv.game and debugenv.game.simHistoryIdx or 1
end

return statedebug
