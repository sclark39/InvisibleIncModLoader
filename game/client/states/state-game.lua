----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local boardrig = include( "gameplay/boardrig" )
local gameobj = include( "modules/game" )
local util = include( "modules/util" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local cdefs = include( "client_defs" )
local camhandler = include( "gameplay/camhandler" )
local hud = include( "hud/hud" )
local modalDialog = include( "states/state-modal-dialog" )
local stateDebug = include( "states/state-debug" )
local mui_defs = include( "mui/mui_defs" )
local fxmgr = include( "gameplay/fx_manager" )
local serializer = include( "modules/serialize" )
local simguard = include( "modules/simguard" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local viz_manager = include( "gameplay/viz_manager" )

local post_process_manager = include( "post_process_manager" )

-----------------------------------------------------------------

local SOUNDCAM_VELOCITY = {0, 0, 0}
local SOUNDCAM_FWD = {1/-1.4142135623730950488016887242097, 1/-1.4142135623730950488016887242097, 0}
local SOUNDCAM_UP = {0, 0, -1}

local OVERLAY_DIMS = 256

local DBG_CONDITIONS =
{
    ["Step 1"] = function( game, ev )
        return true
    end,

    ["Step 10"] = function( game, ev )
        game.debugStepCount = (game.debugStepCount or 0) + 1
        if game.debugStepCount >= 10 then
            game.debugStepCount = nil
            return true
        end
        return false
    end,

    ["Unit Warped"] = function( game, ev )
        return ev.eventType == simdefs.EV_UNIT_WARPED
    end,

    ["Start Walking"] = function( game, ev )
        return ev.eventType == simdefs.EV_UNIT_START_WALKING
    end,

    ["Unit Interrupt"] = function( game, ev )
        return ev.eventType == simdefs.EV_UNIT_INTERRUPTED
    end,
}

local game = class()

function game:init()
    -- refs to MOAI rendering layers
    self.layers = nil

    -- the main window for the game HUD
    self.hud = nil

    -- mode for debug rendering
    self.debugMode = cdefs.DBG_NONE
    self.debugConditionals = DBG_CONDITIONS

    -- refs to the rigs representing the game board itself
    self.boardRig = nil

    -- fx system
    self.fxmgr = nil

    -- ref to the client-side game simulation logic and state
    self.simCore = nil
    -- history of sim actions, for playback
    self.simHistory = nil
    -- index into current location of simHistory (index represents the last action applied to simCore)
    self.simHistoryIdx = 0

    -- sim coroutine
    self.simThread = nil
end

----------------------------------------------------------------

local function event_error_handler( err )
	moai.traceback( "sim:goto() failed with err:\n" ..err )
	return err
end

local function getReplayPanel()
    local stateDebug = include( "states/state-debug" )
    return stateDebug.replayPanel
end

function game:getDebugConditionals()
    return self.debugConditionals
end

function game:setDebugConditional( name )
    self.debugCondition = self.debugConditionals[ name ]
end

function game:generateTooltip( x, y )
	if self.debugMode ~= cdefs.DBG_NONE then
		local wx, wy = self.layers["main"]:wndToWorld2D ( x, y )
		local cellx, celly = self:worldToCell( wx, wy )
		local tooltipTxt = self.boardRig:generateTooltip( self.debugMode, cellx, celly )
	
		if cellx and celly then
			tooltipTxt = tooltipTxt .. string.format("c(%d, %d) w(%.1f, %.1f)\n", tostring(cellx), tostring(celly), wx, wy )
		end
        local cell = self.simCore:getCell( cellx, celly )
        if cell then
            local seerIDs = self.simCore:getLOS():getSeers( cellx, celly )
            if #seerIDs > 0 then
                tooltipTxt = tooltipTxt .. "Seers: "
                for i, seerID in ipairs(seerIDs) do
                    tooltipTxt = tooltipTxt .. seerID .. ", "
                end
            end
            local unit = self.hud:getSelectedUnit()
            if unit and unit:isValid() and unit.getLocation then
                local x0, y0 = unit:getLocation()
                if x0 then
                    if unit:getTraits().hasSight then
                        local vis1, ps1 = self.simCore:getLOS():raycastToCell( x0, y0, cellx, celly, unit:getFacingRad(), simquery.getLOSArc( unit )/2, unit:getTraits().LOSrange )
                        tooltipTxt = tooltipTxt .. string.format( "\n[%d]: %%%.2f direct vision samples (%s)", unit:getID(), ps1*100, vis1 and "YES" or "NO" )
                    end
                    if unit:getTraits().LOSperipheralArc then
                        local vis1, ps1 = self.simCore:getLOS():raycastToCell( x0, y0, cellx, celly, unit:getFacingRad(), unit:getTraits().LOSperipheralArc/2, unit:getTraits().LOSperipheralRange )
                        tooltipTxt = tooltipTxt .. string.format( "\n[%d]: %%%.2f peripheral samples (%s)", unit:getID(), ps1*100, vis1 and "YES" or "NO" )
                    end
                end
            end
        end

		return tooltipTxt
	end
end

local function processSim( self )
	if self.simThread == nil then
		return nil

	else
		simguard.start()
		local result, ev = coroutine.resume( self.simThread )
		if not result then
			moai.traceback( "Sim returned:\n" .. tostring(ev), self.simThread )
			ev = nil
		end
		simguard.finish()

		if ev == nil then
			-- Done processing the simulation!  No more events to process.
			self.simThread = nil
			self.simCore:getEvents():setThread( nil  )
			self:onPlaybackDone()

        elseif ev.eventType == simdefs.EV_CLEAR_QUEUE then
            if self.hud and self.hud._missionPanel then
                self.hud._missionPanel:skip()
            end

		elseif ev.eventType == simdefs.EV_CHECKPOINT then
			self:saveCheckpoint()
		end

		return ev
	end
end

function game:saveCheckpoint()
	if #self.simHistory > 0 then
		self.simHistory[ #self.simHistory ].checkpoint = true
	end
	log:write( "CHECKPOINT: %d", #self.simHistory )
end

function game:restoreCheckpoint()
	-- Clear out the actions after the latest checkpoint, then goto.
	while #self.simHistory > 0 and not self.simHistory[ #self.simHistory ].checkpoint do
		table.remove( self.simHistory )
	end

	log:write( "RESTORE CHECKPOINT: %d", #self.simHistory )

	if #self.simHistory > 0 then
		self.simHistory[ #self.simHistory ].retries = (self.simCore:getTags().retries or 0) + 1
	end

	self:goto( #self.simHistory )

	local unit = self.simCore:getPC():getUnits()[1] 
	self.hud:selectUnit( unit )

	self:getCamera():fitOnscreen( self:cellToWorld( unit:getLocation() ))
	self:getCamera():zoomTo( 0.4 )
end

function game:dispatchScriptEvent( eventType, eventData )
	if self.simCore:getLevelScript() then
		self.simCore:getLevelScript():queueScriptEvent( eventType, eventData )
	end
end

local function refreshViz( game )
    if game.boardRig then
	    game.boardRig:refresh()
    end
	if game.hud then
		game.hud:refreshHud()
	end
	game:getCamera():disableControl( false ) -- In case viz events locked the camera, make sure its unlocked
end

local function validateReplay( game )
	local old_crc = game.simCore:getCRC()
	local old_sim = game.simCore

	local tmpSim = gameobj.constructSim( game.params, game.levelData )
	local simHistoryIdx = 0
	
	simguard.start()
	while simHistoryIdx < #game.simHistory do
		simHistoryIdx = simHistoryIdx + 1
		local res, err = xpcall( function() tmpSim:applyAction( game.simHistory[simHistoryIdx] ) end, event_error_handler )
		if not res then
			log:write( "[%d/%d] %s returned %s:\n",
				simHistoryIdx, #game.simHistory, game.simHistory[simHistoryIdx].name, err )
		end
	end
	simguard.finish()

	local new_crc = tmpSim:getCRC()

	assert( old_crc == new_crc or error( string.format( "%d ~= %d", old_crc, new_crc )))
end

----------------------------------------------------------------

function game:getLocalPlayer()
	return self.simCore:getPlayers()[ self.playerIndex ]
end

function game:getForeignPlayer()
    return self.simCore:getNPC()
end

function game:isLocal()
	-- True if this is a local game (not online).
	return true
end

function game:getWorldSize()
    local w, h = self.simCore:getBoardSize()
	return w * cdefs.BOARD_TILE_SIZE, h * cdefs.BOARD_TILE_SIZE
end

function game:cellToWorld( x, y )
	return self.boardRig:cellToWorld( x, y )
end

function game:worldToCell( x, y )
	return self.boardRig:worldToCell( x, y )
end

function game:worldToSubCell( x, y )
	return self.boardRig:worldToSubCell( x, y )
end

function game:wndToSubCell( x, y )
	if x and y then
		x, y = self.layers["main"]:wndToWorld2D ( x, y )
		return self.boardRig:worldToSubCell( x, y )
	end
end

function game:wndToCell( x, y )
	if x and y then
		x, y = self.layers["main"]:wndToWorld2D ( x, y )
		return self.boardRig:worldToCell( x, y )
	end
end

function game:cellToWnd( x, y )
	x, y = self.boardRig:cellToWorld( x, y )
	return self.layers["main"]:worldToWnd( x, y )
end

function game:worldToWnd( x, y, z )
	return self.layers["main"]:worldToWnd( x, y, z )
end

function game:wndToWorld( x, y )
	if x and y then
		return self.layers["main"]:wndToWorld2D ( x, y )
	end
end

function game:cameraPanToCell( x, y )
	local camera = self:getCamera()
	local x, y = self:cellToWorld( x, y )
	camera:panTo( x, y )
end

function game:getGfxOptions()
	return self._gfxOptions
end

function game:setLocalPlayer( simplayer )

	local playerIndex = util.indexOf( self.simCore:getPlayers(), simplayer )

	if self.playerIndex ~= playerIndex then
		self.hud:selectUnit( nil )

		self.playerIndex = playerIndex

		refreshViz( self )
	end
end

function game:getTeamColour( simplayer )
	if not simplayer then
		return cdefs.TEAMCLR_NEUTRAL
	elseif simplayer == self:getLocalPlayer() then
		return cdefs.TEAMCLR_SELF
	else
		return cdefs.TEAMCLR_ENEMY
	end
end


function game:play()
	if self.debugStep then
		return
	end

	assert( self.simHistoryIdx < #self.simHistory )
	assert( self.simThread == nil )

    self.viz:destroy()
    self.modalControl = self.modalControl:abort()

	self.simHistoryIdx = self.simHistoryIdx + 1

	self.simThread = coroutine.create( 
		function()
			local action = self.simHistory[ self.simHistoryIdx ]
			assert( action )
			self.simCore:applyAction( action )
		end )

	debug.sethook( self.simThread,
		function()
			error( "INFINITE LOOP DETECTED" )
		end, "", 1000000000 ) -- 1 billion instructions is... too much.

	self.simCore:getEvents():setThread( self.simThread )

	self.hud:transitionReplay( true )
	if getReplayPanel() then
		getReplayPanel():updatePanel()
	end
end

function game:rewindTurns()
    local numTurns = 2

    local rewindsLeft = self.simCore:getTags().rewindsLeft
	-- Go back 'numTurns'.
    -- What this means is to pop-back to the Nth endTurnAction (without actually removing it), where N = numTurns. 
	while #self.simHistory > 1 and numTurns > 0 do
        local action = table.remove( self.simHistory )
        if action.name == "endTurnAction" then
            numTurns = numTurns - 1
            if numTurns <= 0 then
                table.insert( self.simHistory, action )
            end
        end
	end
	self:goto( #self.simHistory )
	self:doAction( "rewindAction", rewindsLeft - 1 )
end

function game:doAction( actionName, ... )
	if self:isReplaying() then
		log:write("WARNING: attempting action '%s' during replay", actionName )
		if not self:skip() then
            log:write( "\tCould not skip." )
            return
        end

	elseif self.simCore:isGameOver() then
		log:write("WARNING: attempting action '%s' during game over", actionName )
		return

    elseif self.simCore:getCurrentPlayer():isNPC() then
		log:write("WARNING: attempting action during NPC turn" )
        return

	elseif self.simHistoryIdx < #self.simHistory then
		log:write("WARNING: Overwrite simhistory at %d/%d", self.simHistoryIdx, #self.simHistory )
		while self.simHistoryIdx < #self.simHistory do
			table.remove( self.simHistory )
		end
	end

	-- Construct the serialiable action table and dispatch it.
	local action = { name = actionName, crc = self.simCore:getCRC(), playerIndex = self.simCore:getTurn(), ... }

	-- Queue it in the rewind history.
	table.insert( self.simHistory, action )

	-- Play!
	if self.debugStep ~= nil then
		self.debugStep = false
	end
	self:play()
end

function game:stepBack()
	self:goto( math.max( 1, self.simHistoryIdx - 1 ))
	self.debugStep = true
end

function game:step()
	self.debugStep = false
end

function game:skip()
	if self.simThread then
		self.viz:destroy()
        self.modalControl = self.modalControl:abort()

		local ev = self.simCore:getEvents():getCurrentEvent()
		while self.simThread and (ev == nil or ev.noSkip == nil) do
			ev = processSim( self )
		end

		-- Either sim thread completed, or we aborted due to an interrupt event.
		refreshViz( self )

		if self.simThread then
			self.viz:processViz( ev )
			return false -- Interrupted, did not fully skip.
		end
	end

	return true
end

function game:goto( idx )
	assert( idx >= 0 and idx <= #self.simHistory )
	local startTime = os.clock()
	local oldIdx = self.simHistoryIdx
		
	self:skip()

	if oldIdx ~= idx then
        self.modalControl = self.modalControl:abort()
		self.viz:destroy()
		self.fxmgr:destroy()
		self.hud:destroyHud()
        self.hud = nil
		self.boardRig:destroy()
        self.boardRig = nil
	end

	if self.simHistoryIdx > idx then
		-- We are goto'ing some action in the past.  Regenerate the sim to the origin.
		self.simCore, self.levelData = gameobj.constructSim( self.params, self.levelData )
		self.simHistoryIdx = 0
	end
	
	if self.simHistoryIdx < idx then
		-- We are goto'ing some action in the future.
        local errCount = 0
		simguard.start()
		while self.simHistoryIdx < idx do
			self.simHistoryIdx = self.simHistoryIdx + 1
            local errHandler = errCount == 0 and event_error_handler
			local res, err = xpcall( function() self.simCore:applyAction( self.simHistory[self.simHistoryIdx] ) end, errHandler )
			if not res then
				log:write( "[%d/%d] %s returned %s:\n",
					self.simHistoryIdx, #self.simHistory, self.simHistory[self.simHistoryIdx].name, err )
                errCount = errCount + 1 
			end
		end
		simguard.finish()
	end

	if oldIdx ~= idx then
		self.boardRig = boardrig( self.layers, self.levelData, self )
		self.hud = hud.createHud( self )

		self:onPlaybackDone()

    	self.simCore:getLevelScript():queue( { type="fadeIn" } )

        if self.simHistoryIdx == 0 then
        	local level = include( "sim/level" )
            self:dispatchScriptEvent( level.EV_UI_INITIALIZED )
        end
	end

	util.fullGC()
	log:write( "Goto %d from %d (%d actions).  Took %.2f ms", idx, oldIdx, #self.simHistory, (os.clock() - startTime) * 1000.0 )
end

function game:fastForward( idx )
	self:goto( idx or #self.simHistory )
end

function game:isReplaying()
	return self.simThread ~= nil
end

function game:isVizBusy()
    if self.viz:isBusy() then
        return true
    end

    if self.hud and self.hud._missionPanel:isBusy() then
        return true
    end

    return false
end

function game:onPlaybackDone()
	if self.hud then -- During a goto, the hud has been destroyed.
		self.hud:transitionReplay( false )
	end
	if getReplayPanel() then
		getReplayPanel():updatePanel()
	end
end

function game:doEndTurn()
    self.hud:abortChoiceDialog()
    self.hud:hideItemsPanel()
    self.hud:hideRegenLevel()
    self:doAction( "endTurnAction" )
end

function game:regenerateLevel()
    log:write( "Regenerating level..." )
    statemgr.deactivate( self )
    local user = savefiles.getCurrentGame()
    local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
    if campaign then
        local version = include( "modules/version" )
	    campaign.seed = campaign.seed + 1
	    campaign.uiMemento = nil
	    campaign.sim_history = nil
        campaign.missionVersion = version.VERSION
	    user:save()
    end
	local stateLoading = include( "states/state-loading" )
	stateLoading:loadCampaign( campaign )
end

----------------------------------------------------------------
function game:onInputEvent( event )

	if event.eventType == mui_defs.EVENT_KeyUp and event.key == mui_defs.K_SNAPSHOT then
		local image = MOAIImage.new()
		local function callback()
			local path = KLEIPersistentStorage.getScreenCaptureFolder() .. "/snapshot_" .. os.date('%d-%m-%Y-%H-%M-%S') .. ".png"
			image:writePNG(path)
		end
		if event.controlDown then
			self.diffuse_rt:grabNextFrame( image, callback )
		else
			MOAIRenderMgr.grabNextFrame( image, callback )
		end
	end

	return self.hud and self.hud:onInputEvent( event )
end

local function createLayer( viewPort, debugName )
	local layer = MOAILayer.new ()
	layer:setViewport ( viewPort )
	layer:setDebugName( debugName )
	return layer
end

function game:setupRenderTable( settings )
	local userSettings = settings or savefiles.getSettings( "settings" ).data
	
	local wireframeProps = {}
	local function beginWireframePass()
		local props = self.layers["wireframeProp"]:propList() or {}
		for _,prop in ipairs( props ) do
			prop:setWireframe( true )
			table.insert( wireframeProps, prop )
		end
	end
	local function endWireframePass()
		for _,prop in ipairs( wireframeProps ) do
			prop:setWireframe( false )
		end
		wireframeProps = {}
	end

	local diffuse_rt_table =
		{	self.layers["background"],
			self.layers["floor"],
			self.layers["main"],
			beginWireframePass, self.layers["wireframeProp"], endWireframePass,
			self.layers["ceiling"] }

	if userSettings.enableBackgroundFX then
		table.insert( diffuse_rt_table, 1, self.layers["void_fx2"] )
		table.insert( diffuse_rt_table, 1, self.backgroundLayers["void_fx1"] )
	end

    --render target used for composing the diffuse texture used in bloom and color cube post process effects	
	self.diffuse_rt = self.diffuse_rt or CreateRenderTarget()
	self.diffuse_rt:setRenderTable( diffuse_rt_table )
	self.diffuse_rt:setClearColor( 0, 0, 0, 0 )
	--self.diffuse_rt:setClearStencil( 0 )
	--self.diffuse_rt:setClearDepth( true )

	self.shadow_map = self.shadow_map or CreateShadowMap()

	if self.post_process then
		self.post_process:destroy()
		self.post_process = nil
	end
	util.tclear( self.renderTable )

	if userSettings.enableLightingFX then
		local overlay_rt_table = { self.layers['overlay'] }
		self.overlay_rt = self.overlay_rt or CreateRenderTarget( OVERLAY_DIMS, OVERLAY_DIMS )
		self.overlay_rt:setRenderTable( overlay_rt_table )
		self.overlay_rt:setClearColor( 0.5, 0.5, 0.5, 1.0 )

		self.post_process = post_process_manager.overlay( self.diffuse_rt, self.overlay_rt )

		self.renderTable[1] = { self.shadow_map, CONST = true, MSAA = false }
		self.renderTable[2] = { self.diffuse_rt, CONST = false, MSAA = true }
		self.renderTable[3] = { self.overlay_rt, CONST = true, MSAA = false }
		self.renderTable[4] = { self.post_process:getRenderable(), CONST = false, MSAA = false }
	else
		self.post_process = post_process_manager.passthrough( self.diffuse_rt )

		self.renderTable[1] = { self.shadow_map, CONST = true, MSAA = false }
		self.renderTable[2] = { self.diffuse_rt, CONST = false, MSAA = true }
		self.renderTable[3] = { self.post_process:getRenderable(), CONST = false, MSAA = false }
	end
end

function game:insertWireframeProp( prop )
	self.layers["wireframeProp"]:insertProp( prop )
end
function game:removeWireframeProp( prop )
	self.layers["wireframeProp"]:removeProp( prop )
end

----------------------------------------------------------------
function game:onLoad( params, simCore, levelData, simHistory, simHistoryIdx, uiMemento )
	self.simCore = simCore
	self.levelData = levelData
	self.onLoadTime = os.time()
	self.playerIndex = array.find( simCore:getPlayers(), simCore:getPC() )
	self.params = params
	self.debugMode = stateDebug.mode
    self.modalControl = modalDialog.modalControl()

	local userSettings = savefiles.getSettings( "settings" ).data

	self._gfxOptions =
	{
		bMainframeMode = false,
		bFOWEnabled = true,				--Option used by board_rig to toggle FOW rendering
		FOWFilter = "fog_of_war",		--Currently selected render filter to apply to rigs in FOW (not in LOS)
		KAnimFilter = "default",		--Currently selected render filter to apply to rigs when not in FOW or FOW is disabled
		enableOptionalDecore = userSettings.enableOptionalDecore,
		bTacticalView = false,
	}

	inputmgr.addListener( self )

	local largeView = MOAIViewport.new()
	largeView:setSize( VIEWPORT_WIDTH, VIEWPORT_HEIGHT )
	largeView:setScale( VIEWPORT_WIDTH, 0 )

	local overlayView = MOAIViewport.new()
	overlayView:setSize( OVERLAY_DIMS, OVERLAY_DIMS )
	overlayView:setScale( VIEWPORT_WIDTH, 0 )

	self._eventID = addGlobalEventListener(
		function(name, val)
			if name == "resolutionChanged" then
				largeView:setSize( val[1], val[2] )
				largeView:setScale( val[1], 0 )
				overlayView:setScale( val[1], val[2] )
			elseif name == "gfxmodeChanged" then
				self:getCamera():enableEdgePan( val )
			end
		end
		)

	do
		local camera2D = MOAICamera2D.new()
		camera2D:setScl( 1, 1 )
		camera2D:setLoc( 0, 0 )
		camera2D:forceUpdate()

		local layer = MOAILayer2D.new ()
		layer:setDebugName( "void_fx1_layer" )
		layer:setViewport ( largeView )
		layer:setCamera( camera2D )

		self.backgroundLayers = {}
		self.backgroundLayers["void_fx1"] = layer
		self.backgroundLayers["void_fx1"]:setParallax( 0, 0, 0 )
	end

	self.layers = {}
	self.layers["background"] = createLayer ( largeView, "background_layer" )
	self.layers["floor"] = createLayer ( largeView, "floor_layer" )
	self.layers["main"] = createLayer ( largeView, "main_layer" )
	self.layers["main"]:setSortMode( MOAILayer.SORT_ISO )
	self.layers["ceiling"] = createLayer ( largeView, "ceiling_layer" )
	self.layers["overlay"] = createLayer ( overlayView, "overlay_layer" )

	self.layers["void_fx2"] = createLayer ( largeView, "void_fx2_layer" )
	self.layers["void_fx2"]:setParallax( 0.7, 0.7, 1 )

	self.layers["wireframeProp"] = createLayer( largeView, "wireframeProp" )


	
	
	self.renderTable = {}
	KLEIRenderScene:setGameRenderTable( self.renderTable )
	self:setupRenderTable()

	self.simHistory = simHistory or {}
	self.simHistoryIdx = simHistoryIdx or #self.simHistory
    if self.simHistoryIdx < #self.simHistory then
        if config.DEV then
        	self.debugStep = true
        else
            while self.simHistoryIdx < #self.simHistory do
                table.remove( self.simHistory )
            end
        end
    end

	self.fxmgr = fxmgr( self.layers["ceiling"] )
    
    local camhandler = include( "gameplay/camhandler" )
	self.cameraHandler = camhandler( self.layers["main"], self, uiMemento )
    if uiMemento and uiMemento.cameraState then
        self.cameraHandler:setMemento( uiMemento.cameraState )
    end

	self.boardRig = boardrig( self.layers, self.levelData, self )
	self.boardRig:startSpotSounds()
	self.viz = viz_manager( self )
	self.hud = hud.createHud( self )

	if uiMemento then
		self.hud:selectUnit( self.simCore:getUnit( uiMemento.selectedUnitID ) )
    else
        self.boardRig:cameraCentre()
	end

	local level = include( "sim/level" )
    if self.simCore:hasTag( "isTutorial" ) then
        -- Stupid tutorial starts in a special orientation..
    	self.simCore:getLevelScript():queue( { type="fadeIn", orientation = 1 } )
    else
    	self.simCore:getLevelScript():queue( { type="fadeIn" } )
    end
    self:dispatchScriptEvent( level.EV_UI_INITIALIZED )
end

----------------------------------------------------------------
function game:onUnload()
	if self._eventID then
		delGlobalEventListener( self._eventID )
		self._eventID = nil
	end
	inputmgr.removeListener( self )

    self.modalControl:abort()
    self.modalControl = nil

	if self.viz then
		self.viz:destroy()
		self.viz = nil
	end

	if self.hud then
		self.hud:destroyHud()
		self.hud = nil
	end

	self.boardRig:destroy()
	self.boardRig = nil

	self.fxmgr:destroy()
	self.fxmgr = nil

	if self.cameraHandler then
		self.cameraHandler:destroy()
		self.cameraHandler = nil
	end

	self.layers = nil
    util.tclear( self.backgroundLayers )

	self.simThread = nil
	self.simCore = nil

	self.simHistory = nil
	self.simHistoryIdx = 0

	util.tclear( self.renderTable )
	if self.post_process then
		self.post_process:destroy()
		self.post_process = nil
	end
	self.overlay_rt, self.diffuse_rt = nil, nil

	MOAIFmodDesigner.stopAllSounds()
end


function game:updateSound()
	local framesSampled = 30
	local samplesPerFrame = 20
	local ambientCellSamples = self.ambientCellSamples or { }
	local ambientIdx = self.ambientIdx or -1
	ambientIdx = (ambientIdx + 1) % framesSampled
	
	local samples = {}
	for i=1,samplesPerFrame do
		local x,y = math.random(0,1280), math.random(0, 720)
		local cellrig = self.boardRig:getClientCellXY( self:wndToCell( x, y ) )
		if cellrig ~= nil and cellrig.tileIndex ~= nil then
			local ambientSoundType = cdefs.MAPTILES[ cellrig.tileIndex ].ambientSound
			samples[ ambientSoundType ] = 1 + (samples[ ambientSoundType ] or 0)
		else
			samples[ 0 ] = 1 + ( samples[ 0 ] or 0 )
		end
	end
	
	ambientCellSamples[ambientIdx+1] = samples
	
	local counts = {}
	for _,v in ipairs( ambientCellSamples ) do
		for t,c in pairs( v ) do 
			counts[t] = c + (counts[t] or 0)
		end
	end
	
	self.ambientCellSamples = ambientCellSamples
	self.ambientIdx = ambientIdx
	
	local avg = 1/(framesSampled*samplesPerFrame)
	
	if self.hud._isMainframe == true then
		MOAIFmodDesigner.setVolume( "AMB1", 0 )
		MOAIFmodDesigner.setVolume( "AMB2", 1 )
	else
		MOAIFmodDesigner.setVolume( "AMB1", avg*(counts[1] or 0 ) )
		MOAIFmodDesigner.setVolume( "AMB2", 0 )
	end
	
	local x, y = self:getCamera():getLoc()
	local cx, cy = self:worldToSubCell(x,y)
	self.prevCam = self.prevCam or {-1, -1}
	if cx and cy and cx ~= self.prevCam[1] and cy ~= self.prevCam[2] then
		self.prevCam[1], self.prevCam[2] = cx, cy
		MOAIFmodDesigner.setCameraProperties( { cx, cy, -10 }, SOUNDCAM_VELOCITY, SOUNDCAM_FWD, SOUNDCAM_UP )
	end
	--print( avg*(counts[0] or 0), avg*(counts[1] or 0), avg*(counts[2] or 0), avg*(counts[3] or 0) )
end
----------------------------------------------------------------

local FRAME_EV = { eventType = simdefs.EV_FRAME_UPDATE }

function game:onUpdate()

	local ev = FRAME_EV
	while not self.debugStep and ev and self.viz:processViz( ev ) do
		-- Ok.  viz is non-blocking.  Simulate if necessary.
		ev = processSim( self )

		if ev and self.debugStep ~= nil and getReplayPanel() then --SIMEVENT
			-- log:write( ">%s: %s", simdefs:stringForEvent(ev.eventType), util.debugPrintTable( ev, 2 ) )
			-- log:write( debug.traceback( self.simThread ))
            if self.debugCondition then
    			self.debugStep = self.debugCondition( self, ev )
            else
    			self.debugStep = true
            end
			getReplayPanel():addEvent(ev, debug.traceback( self.simThread ) )
			getReplayPanel():updatePanel()
			self.viz:processViz( ev )
			break
		end
	end

	self.fxmgr:updateFx()
	
	self:updateSound()
	
	self:getCamera():onUpdate()

	if not self:isReplaying() then
		if self.simHistoryIdx < #self.simHistory then
			self:play()

		elseif self.simCore:getLevelScript() then
			self.simCore:getLevelScript():dispatchScriptEvents( self )
		end
	end

	self.boardRig:onUpdate()

	self.hud:updateHud()
end

return game
