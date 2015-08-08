----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local mui_util = include( "mui/mui_util" )
local util = include( "client_util" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local gameobj = include( "modules/game" )
local cdefs = include("client_defs")
local modalDialog = include( "states/state-modal-dialog" )
local strings = include( "strings" )

----------------------------------------------------------------
-- Local functions

local EDGE_PAN_DIST_FACTOR = 4
local EDGE_PAN_SPEED_FACTOR = 4

local function populateGfxRefreshCmb( dialog, gfxOptions )
    --print('populateGfxRefreshCmb')
	local combo = dialog._screen.binder.gfxRefreshCmb
	combo:clearItems()

	if gfxOptions.bFullscreen then
		local displaylist = MOAISim.getGfxDeviceDisplayModes()
        local currentDisplay = array.findIf( displaylist, function( display ) return display.name == gfxOptions.sDisplay end ) or displaylist[1]
        local currentMode = array.findIf( currentDisplay.modes, function( mode ) return mode.width == gfxOptions.width and mode.height == gfxOptions.height end ) or currentDisplay.modes[1]
        local freqIdx = 1
		for i,frequency in ipairs( currentMode.frequencys ) do
			combo:addItem( frequency )
			if frequency == gfxOptions.iFrequency then
            	freqIdx = i
			end
		end
        combo:selectIndex( freqIdx )
    	combo:setDisabled( false )
	else
        local displayMode = MOAISim.getGfxCurrentDisplayMode()
        combo:setText(displayMode.iFrequency)
    	combo:setDisabled( true )
	end
end

local function populateGfxModeCmb( dialog, gfxOptions )
    --print('populateGfxModeCmb')
	local combo = dialog._screen.binder.gfxModeCmb
	combo:clearItems()

	if gfxOptions.bFullscreen then
		local displaylist = MOAISim.getGfxDeviceDisplayModes()
        local currentDisplay = array.findIf( displaylist, function( display ) return display.name == gfxOptions.sDisplay end ) or displaylist[1]
        local modeIdx = 1
		for i,mode in ipairs( currentDisplay.modes ) do
			combo:addItem( mode.width .. "x" .. mode.height )
			if mode.width == gfxOptions.width and mode.height == gfxOptions.height then
                modeIdx = i
			end
		end
        combo:selectIndex( modeIdx )
	    combo:setDisabled( false )
	else
        local displayMode = MOAISim.getGfxCurrentDisplayMode()
        combo:setText(displayMode.width.."x"..displayMode.height)
	    combo:setDisabled( true )
	end
end

local function populateGfxDisplayCmb( dialog, gfxOptions )
    --print('populateGfxDisplayCmb')
	local combo = dialog._screen.binder.gfxDisplayCmb
	combo:clearItems()

	if gfxOptions.bFullscreen then
		local displaylist = MOAISim.getGfxDeviceDisplayModes()
        local displayIdx = 1
		for i,display in ipairs( displaylist ) do
			combo:addItem( display.name )
			if display.name == gfxOptions.sDisplay then
                displayIdx = i
			end
		end
        combo:selectIndex( displayIdx )
	    combo:setDisabled( false )
	else
        local displayMode = MOAISim.getGfxCurrentDisplayMode()
        combo:setText(displayMode.sDisplay)
	    combo:setDisabled( true )
	end
end

local function populateLanguageMods( dialog, settings )
    local languageMods = mod_manager:getLanguageMods()
    local cmb = dialog._screen.binder.localeCmb
    cmb:clearItems()
    cmb:addItem( STRINGS.UI.MODS_DEFAULT_LOCALE )
    for i, mod in ipairs(languageMods) do
        cmb:addItem( mod.name, mod.id )
    end
    cmb:selectIndex( 1 )

    local modData = mod_manager:findMod( settings.localeMod )
    if modData then
        dialog._screen.binder.localeCmb:setText( modData.locale )
    else
        dialog._screen.binder.localeCmb:selectIndex( 1 ) -- English, default
    end

    if KLEISteamWorkshop then
        cmb:addItem( STRINGS.UI.MODS_FIND_MORE, "VIEW_WORKSHOP" )
    end

    dialog._last_selected_mod_idx = dialog._screen.binder.localeCmb:getIndex()
end


-- Update Controls tab UI to reflect key bindings.
local function refreshControls( dialog, keybindings )
    local lb = dialog._screen.binder.controlsList
    lb:clearItems()
    
    for i, binding in pairs(cdefs.ALL_KEYBINDINGS) do
        if not binding.name then
            local widget = lb:addItem( nil, "HeaderBinding" )
            widget.binder.headerTxt:setText( binding.txt )
        else
            local user_data = { idx = i, name = binding.name, binding = keybindings and keybindings[ binding.name ] or binding.defaultBinding }
            local widget = lb:addItem( user_data )
            local clr, tt = "", ""
            if not util.tequal( user_data.binding, binding.defaultBinding ) then
                clr = "<font1_16b>"
            end
            if keybindings then
                for name, v in pairs(keybindings) do
                    if name ~= binding.name and util.tequal( v, user_data.binding ) then
                        local bindingInfo = array.findIf( cdefs.ALL_KEYBINDINGS, function( x ) return x.name == name end )
                        if bindingInfo then
                            clr = "<font1_16b><c:ff0000>"
                            tt = tt .. "\n" .. bindingInfo.txt
                        end
                    end
                end
            end
            widget.binder.bindingTxt:setText( binding.txt )
            widget.binder.keyTxt:setText( clr .. mui_util.getBindingName( user_data.binding ) .. "</>" )
            if #tt > 0 then
                widget.binder.keyTxt:setTooltip( string.format( "<ttheader>%s</><ttbody>%s</>", STRINGS.OPTIONS.KEY_CONFLICTS, tt ))
            end
        end
    end
end

-- Update GFX UI to reflect GFX settings.
local function refreshGfx( dialog, settings )
    local gfx = settings.gfx
	dialog._screen.binder.gfxFullscreenBtn:setChecked( gfx.bFullscreen )
    dialog._screen.binder.gfxWidescreenBtn:setChecked( gfx.aspectConstraint > 0 )
	dialog._screen.binder.gfxVsyncBtn:setChecked( gfx.bVsync )
	dialog._screen.binder.lightingFXbtn:setChecked( settings.enableLightingFX )
	dialog._screen.binder.backgroundFXbtn:setChecked( settings.enableBackgroundFX )
	dialog._screen.binder.decorebtn:setChecked( settings.enableOptionalDecore )
    dialog._screen.binder.bloombtn:setChecked( settings.enableBloom )
    dialog._screen.binder.daltonismCmb:selectIndex( (settings.colorFilter or 0) + 1 )
	dialog._screen.binder.gfxShadowQualityCmb:selectIndex( settings.shadowQuality or 3 )

    populateGfxDisplayCmb( dialog, gfx )
    populateGfxModeCmb( dialog, gfx )
	populateGfxRefreshCmb( dialog, gfx )
end

-- Update UI to reflect settings.
local function refresh( dialog, settings )
	dialog._screen.binder.volumeSfx:setText(tostring(math.floor(settings.volumeSfx*100)))
	dialog._screen.binder.volumeMusic:setText(tostring(math.floor(settings.volumeMusic*100)))
	dialog._screen.binder.musicBar:setValue( settings.volumeMusic * 100 )
	dialog._screen.binder.soundBar:setValue( settings.volumeSfx * 100 )

	dialog._screen.binder.fastModeBtn:setChecked( settings.fastMode )
	dialog._screen.binder.metricsBtn:setChecked( not settings.suppressMetricsData )
	dialog._screen.binder.manualCamBtn:setChecked( settings.manualCam )
	dialog._screen.binder.subtitlesBtn:setChecked( settings.showSubtitles )
    dialog._screen.binder.gfxSubtitleBtn:setChecked( settings.showMovieSubtitles )    
	dialog._screen.binder.edgePanDistTxt:setText( string.format( "%.2fx", settings.edgePanDist ))
	dialog._screen.binder.edgePanDistBar:setValue( settings.edgePanDist * 100 / EDGE_PAN_DIST_FACTOR )
	dialog._screen.binder.edgePanSpeedTxt:setText( string.format( "%.2fx", settings.edgePanSpeed ))
	dialog._screen.binder.edgePanSpeedBar:setValue( settings.edgePanSpeed * 100 / EDGE_PAN_SPEED_FACTOR )



    populateLanguageMods( dialog, settings )
end

local function retrieveControlSettings( dialog )
    local keybindings = {}
    local lb = dialog._screen.binder.controlsList
    for i = 1, lb:getItemCount() do
        local item = lb:getItem( i )
        if item.user_data then
            keybindings[ item.user_data.name ] = item.user_data.binding
        end
    end
    return keybindings
end

local function retrieveGfxSettings( dialog )
    local binder = dialog._screen.binder
    local gfx = MOAISim.getGfxCurrentDisplayMode()
    gfx.bVsync = binder.gfxVsyncBtn:isChecked()
    gfx.bFullscreen = binder.gfxFullscreenBtn:isChecked()
    gfx.aspectConstraint = binder.gfxWidescreenBtn:isChecked() and 16/9 or 0
    if gfx.bFullscreen then
        local width, height = binder.gfxModeCmb:getText():match( "(%d+)x(%d+)" )
        gfx.width, gfx.height = tonumber( width ), tonumber( height )
        gfx.iFrequency = tonumber( binder.gfxRefreshCmb:getText() )
        gfx.sDisplay = binder.gfxDisplayCmb:getText()
    end
    return gfx
end

local function retrieveSettings( dialog )
    local binder = dialog._screen.binder
    local settings = util.tcopy( dialog._originalSettings )
    settings.volumeMusic = math.max( 0, math.min( 1, binder.musicBar:getValue() /100 ))
    settings.volumeSfx = math.max( 0, math.min( 1, binder.soundBar:getValue() /100 ))
    settings.fastMode = binder.fastModeBtn:isChecked()
    settings.suppressMetricsData = not binder.metricsBtn:isChecked()
    settings.manualCam = binder.manualCamBtn:isChecked()
    settings.showSubtitles = binder.subtitlesBtn:isChecked()  
    settings.showMovieSubtitles = binder.gfxSubtitleBtn:isChecked()   
    settings.edgePanDist = math.max( 0, math.min( 1, binder.edgePanDistBar:getValue()/100 )) * EDGE_PAN_DIST_FACTOR
    settings.edgePanSpeed = math.max( 0, math.min( 1, binder.edgePanSpeedBar:getValue()/100 )) *  EDGE_PAN_SPEED_FACTOR
    settings.localeMod = binder.localeCmb:getUserData()

    settings.enableLightingFX = binder.lightingFXbtn:isChecked()
    settings.enableBackgroundFX = binder.backgroundFXbtn:isChecked()
    settings.enableOptionalDecore = binder.decorebtn:isChecked()
    settings.enableBloom = binder.bloombtn:isChecked()
    settings.colorFilter = binder.daltonismCmb:getIndex() - 1
	settings.shadowQuality = binder.gfxShadowQualityCmb:getIndex()

    settings.gfx = retrieveGfxSettings( dialog )
    settings.keybindings = retrieveControlSettings( dialog )
    return settings
end

local function handleGlobalEvent( self, name, value )
    if name == "gfxmodeChanged" or name == "resolutionChanged" or name == "screenPosChanged" then
        self._originalSettings.gfx = MOAISim.getGfxCurrentDisplayMode()
        refreshGfx( self, self._originalSettings )
    end
end

-- Apply actual settings to the application.
local function applyGfxSettings( dialog, settings )
	delGlobalEventListener( dialog._listenerID )

	if dialog._game then
		if settings.enableLightingFX ~= dialog._appliedSettings.enableLightingFX or settings.enableBackgroundFX ~= dialog._appliedSettings.enableBackgroundFX then
			dialog._game:setupRenderTable( settings )
		end
		
		if dialog._game.boardRig and settings.enableOptionalDecore ~= dialog._appliedSettings.enableOptionalDecore then
			dialog._game:getGfxOptions().enableOptionalDecore = settings.enableOptionalDecore
			dialog._game.boardRig:refreshDecor()
		end
		
		if dialog._game.shadow_map and settings.shadowQuality ~= dialog._appliedSettings.shadowQuality then
			local dim = 128 * math.pow(2, math.min( 5, settings.shadowQuality or 3 ))
			--print("shadow_map:init", dim, dim )
			dialog._game.shadow_map:init( dim, dim )
		end
	end

	if KLEIRenderScene then
        KLEIRenderScene:setGaussianBlur( settings.enableBloom and 1.0 or 0 )

        local filter = math.max( 0, math.min( 4, settings.colorFilter or 0 ))
		KLEIRenderScene:setDaltonizationType( filter )
	end
	
	if MOAISim.setGfxDisplayMode( settings.gfx ) then
        -- Settings applied correctly: make it so.
        dialog._appliedSettings = util.tcopy(settings)
    end
    
	dialog._listenerID = addGlobalEventListener( function(...) handleGlobalEvent( dialog, ... ) end )
end

local function onClickAccept( dialog )
    local original = util.tcopy( dialog._originalSettings )
    local settings = retrieveSettings( dialog )
    applyGfxSettings( dialog, settings )
    util.applyUserSettings( settings )

    local needsConfirm = not util.tequal( settings.gfx, original.gfx ) or
				settings.colorFilter ~= original.colorFilter or
				settings.shadowQuality ~= original.shadowQuality
    if not needsConfirm or modalDialog.showYesNo( STRINGS.OPTIONS.CONFIRM, STRINGS.OPTIONS.CONFIRM_TITLE ) == modalDialog.OK then
        -- Currently applied settings are accepted.  Save them to file.
	    local settingsFile = savefiles.getSettings( "settings" )
	    settingsFile.data = settings
	    settingsFile:save()
    	dialog:hide()	-- Kill this dialog.

        if settings.localeMod ~= original.localeMod then
            modalDialog.show( STRINGS.UI.LOCALE_CHANGED_BODY, STRINGS.UI.LOCALE_CHANGED_HEADER )
        end
    else
        -- Not accepted, revert.
        applyGfxSettings( dialog, original )
        util.applyUserSettings( original )
        refresh( dialog, original )
        refreshGfx( dialog, original )
        refreshControls( dialog, original.keybindings )
    end
end

local function onClickCancel( dialog )
    util.applyUserSettings( dialog._originalSettings)

	dialog:hide()	-- Kill this dialog.
end

local function onClickFullscreenBtn( dialog, widget )
    -- Toggling fullscreen changes the contents of the display and mode combo boxes.
    local settings = retrieveSettings( dialog )
    refreshGfx( dialog, settings )
end

local function refreshModsButton( widget )
    if not KLEISteamWorkshop then
        widget:setVisible( false ) -- No Steam.
        return
    end

    local status = KLEISteamWorkshop:getWorkshopUpdateStatus()
    if not status then
        widget:setDisabled( true )
        widget:setText( STRINGS.UI.MODS_OFFLINE )
        return false

    elseif status.state == "idle" then
        widget:setDisabled( false )
        widget:setText( STRINGS.UI.MODS_UPDATE )
        return false

    else
        widget:setDisabled( true )
        widget:setText( util.sformat( STRINGS.UI.MODS_UPDATING, math.floor(status.progress * 100) ))
        return true
    end
end

local function onClickRefreshMods( dialog )
    mod_manager:updateMods()
    dialog.refreshLanguages = true
end

local function onClickViewWorkshop( dialog )
    if KLEISteamWorkshop then
        log:write( "Showing Steam Workshop..." )
        KLEISteamWorkshop:showWorkshop()
    else
        log:write( "No Steam Overlay" )
    end
end

local function onGfxDisplayCmb( dialog, text )
    -- Changing displays changes the contents of the display-mode combos.
    local settings = retrieveSettings( dialog )
    --print('onGfxDisplayCmb', settings.gfx.bFullscreen )
    if settings.gfx.bFullscreen then
        populateGfxModeCmb( dialog, settings.gfx )  --Display change can trigger a mode and refresh change when selecting fullscreen modes.
    end
end

local function onGfxModeCmb( dialog, text )
    local settings = retrieveSettings( dialog )
    --print('onGfxModeCmb', settings.gfx.bFullscreen )
    if settings.gfx.bFullscreen then
        populateGfxRefreshCmb( dialog, settings.gfx ) --Mode change can trigger a refresh change when selecting fullscreen modes.
    end
end

local function onLocaleCmb( dialog, text )
    local cmb = dialog._screen.binder.localeCmb
    local sel_data = cmb:getUserData()
    if sel_data == "VIEW_WORKSHOP" then
        onClickViewWorkshop(dialog)
        cmb:selectIndex( dialog._last_selected_mod_idx or 1 )
    else
        dialog._last_selected_mod_idx = cmb:getIndex()
    end
end

local function onClickResetBindingsBtn( dialog )
    if (modalDialog.showYesNo( STRINGS.OPTIONS.CONFIRM_RESET, STRINGS.OPTIONS.RESET_BINDINGS ) == modalDialog.OK ) then
        refreshControls( dialog, nil )
    end
end

-- Can create no bindings using these keys.
local ILLEGAL_KEYBINDS = { mui_defs.K_LEFTARROW, mui_defs.K_RIGHTARROW, mui_defs.K_DOWNARROW, mui_defs.K_UPARROW }
local function onInputEvent( inputDialog, event )
	if event.eventType == mui_defs.EVENT_KeyUp then
        if array.find( ILLEGAL_KEYBINDS, event.key ) == nil and #mui_util.getKeyName( event.key ) > 0 then
            inputDialog.binding = mui_util.makeBindingFromInput( event )
            inputDialog.result = modalDialog.OK
        end
    end

    return not mui_util.isMouseEvent( event )
end

local function onClickKeyBinding( dialog, i, user_data )
    if not user_data then
        return -- Clicked on a 'header' list item, not an actual key binding entry, so ignore.
    end

	local thread = MOAICoroutine.new()
	thread:run( function()
        local bodyTxt = util.sformat( STRINGS.OPTIONS.ENTER_BINDING,
            cdefs.ALL_KEYBINDINGS[ user_data.idx ].txt,
            mui_util.getBindingName( user_data.binding ),
            mui_util.getBindingName( cdefs.ALL_KEYBINDINGS[ user_data.idx ].defaultBinding ))
	    local inputDialog = modalDialog.createModalDialog( bodyTxt, STRINGS.OPTIONS.SELECT_INPUT )
        inputDialog.onInputEvent = onInputEvent

	    statemgr.activate( inputDialog )
        inputmgr.addListener( inputDialog, 1 )
	    while inputDialog.result == nil do
		    coroutine.yield()
	    end
        inputmgr.removeListener( inputDialog )
	    statemgr.deactivate( inputDialog )

        -- Assign the new key binding to the list box item's user data for temporary storage.
        if inputDialog.binding then
            user_data.binding = inputDialog.binding
            local keybindings = retrieveControlSettings( dialog )
            refreshControls( dialog, keybindings )
        end
    end )
	thread:resume()
end

----------------------------------------------------------------
-- Interface functions

local options_dialog = class()

function options_dialog:init(game)
	local screen = mui.createScreen( "options_dialog_screen.lua" )
	self._game = game
	self._screen = screen

	screen.binder.acceptBtn.binder.btn.onClick = util.makeDelegate( nil, onClickAccept, self )
	screen.binder.acceptBtn.binder.btn:setText(STRINGS.UI.BUTTON_ACCEPT)
    screen.binder.acceptBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)
    
    screen.binder.cancelBtn.binder.btn.onClick = util.makeDelegate( nil, onClickCancel, self )	
    screen.binder.cancelBtn.binder.btn:setText(STRINGS.UI.BUTTON_CANCEL)
    screen.binder.cancelBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
	screen.binder.cancelBtn.binder.btn:setHotkey( "pause" )

    screen.binder.refreshModsBtn.onClick = util.makeDelegate( nil, onClickRefreshMods, self )
    screen.binder.viewWorkshopBtn.onClick = util.makeDelegate( nil, onClickViewWorkshop, self )

    local function forceRefreshUI( )
        local settings = retrieveSettings( self )
		util.applyUserSettings( settings )
        refresh( self, settings )
    end
	
	local SHADOW_QUALITYS =
	{
		STRINGS.OPTIONS.QUALITY.LOW,
		STRINGS.OPTIONS.QUALITY.MEDIUM,
		STRINGS.OPTIONS.QUALITY.NORMAL,
		STRINGS.OPTIONS.QUALITY.HIGH,
		STRINGS.OPTIONS.QUALITY.VERY_HIGH,
		--STRINGS.OPTIONS.QUALITY.ULTRA,
	}
	for i,v in ipairs( SHADOW_QUALITYS ) do
		local size = 128 * math.pow(2, i )
		local sizeTxt = util.sformat( "{1}x{1}", size )
		local txt = util.sformat( v, sizeTxt )
		screen.binder.gfxShadowQualityCmb:addItem( txt )
	end
	screen.binder.gfxShadowQualityCmb.selectIndex(1)
	
	local DALTONISM = { STRINGS.OPTIONS.DEFAULT, STRINGS.OPTIONS.FILTER1, STRINGS.OPTIONS.FILTER2, STRINGS.OPTIONS.FILTER3 }
	for i, type in ipairs( DALTONISM ) do
		screen.binder.daltonismCmb:addItem( type )
	end
	screen.binder.daltonismCmb:selectIndex(1)

	screen.binder.gfxFullscreenBtn.onClick = util.makeDelegate( nil, onClickFullscreenBtn, self )
	screen.binder.gfxDisplayCmb.onTextChanged = util.makeDelegate( nil, onGfxDisplayCmb, self )
    screen.binder.gfxModeCmb.onTextChanged = util.makeDelegate( nil, onGfxModeCmb, self )
    --

	screen.binder.musicBar.onValueChanged = forceRefreshUI
	screen.binder.soundBar.onValueChanged = forceRefreshUI
	screen.binder.edgePanDistBar.onValueChanged = forceRefreshUI
	screen.binder.edgePanSpeedBar.onValueChanged = forceRefreshUI

    screen.binder.localeCmb.onTextChanged = util.makeDelegate( nil, onLocaleCmb, self )

    

    -- Controls tab --
    screen.binder.resetBindingsBtn.onClick = util.makeDelegate( nil, onClickResetBindingsBtn, self )
    screen.binder.controlsList.onItemClicked = util.makeDelegate( nil, onClickKeyBinding, self )

	screen.binder.tabs:selectTab( 1 )
end

function options_dialog:show()
    MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
	mui.activateScreen( self._screen )
	
	local settingsFile = savefiles.getSettings( "settings" )
	self._originalSettings = util.tcopy(settingsFile.data)
    self._originalSettings.gfx = MOAISim.getGfxCurrentDisplayMode()
	self._appliedSettings = util.tcopy( self._originalSettings )

	refresh( self, self._appliedSettings )
    refreshGfx( self, self._appliedSettings )
    refreshControls( self, self._appliedSettings.keybindings )

    if not KLEISteamWorkshop then
        self._screen.binder.viewWorkshopBtn:setVisible( false ) -- No Steam.
        self._screen.binder.refreshModsBtn:setVisible( false )

    else
        self.modStatus = MOAICoroutine.new()
        self.modStatus:run(
            function()
                while true do
                    if not refreshModsButton( self._screen.binder.refreshModsBtn ) then
                        if self.refreshLanguages then
                            log:write( "Re-populating language mods..." )
                            populateLanguageMods( self, self._appliedSettings )
                            self.refreshLanguages = nil

                            modalDialog.show( STRINGS.UI.MODS_REFRESH_COMPLETE )
                        end
                    end

                    coroutine.yield()
                end
            end )
        self.modStatus:resume()
    end

    -- If the user moves/resizes the window while in the options screen, these should be reflected
    -- in the original settings, so that new dimensions aren't reverted.
	self._listenerID = addGlobalEventListener( function(...) handleGlobalEvent( self, ... ) end )
end

function options_dialog:isActive()
	return self._screen and self._screen:isActive()
end

function options_dialog:hide()
    if self.modStatus then
        self.modStatus:stop()
        self.modStatus = nil
    end
    self.refreshLanguages = nil

    if self._listenerID ~= nil then
        MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPDOWN  )
	    delGlobalEventListener( self._listenerID )
	    self._listenerID = nil

	    self._screen.binder.tabs:selectTab( 1 )

	    if self._screen:isActive() then
		    mui.deactivateScreen( self._screen )
	    end
    end
end

return options_dialog
