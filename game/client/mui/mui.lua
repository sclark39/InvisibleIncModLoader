-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_screen = require( "mui/mui_screen" )
local mui_defs = require( "mui/mui_defs" )
local mui_label = require( "mui/widgets/mui_label" )
local mui_lineleader = require( "mui/widgets/mui_lineleader" )
local mui_script = require( "mui/widgets/mui_script" )
local mui_editbox = require( "mui/widgets/mui_editbox" )
local mui_image = require( "mui/widgets/mui_image" )
local mui_imagebutton = require( "mui/widgets/mui_imagebutton" )
local mui_checkbox = require( "mui/widgets/mui_checkbox" )
local mui_spinner = require( "mui/widgets/mui_spinner" )
local mui_group = require( "mui/widgets/mui_group" )
local mui_listbox = require( "mui/widgets/mui_listbox" )
local mui_combobox = require( "mui/widgets/mui_combobox" )
local mui_tabs = require( "mui/widgets/mui_tabs" )
local mui_radial = require( "mui/widgets/mui_radial" )
local mui_slider = require( "mui/widgets/mui_slider" )
local mui_scrollbar = require( "mui/widgets/mui_scrollbar" )
local mui_anim = require( "mui/widgets/mui_anim" )
local mui_progressbar = require( "mui/widgets/mui_progressbar" )
local mui_dragzone = require( "mui/widgets/mui_dragzone" )
local mui_movie = require( "mui/widgets/mui_movie" )

----------------------------------------------------------------

local SCALED_FONT = 1	-- Denotes a font that stretches according to the resolution
local UNIFORM_FONT = 2	-- Denotes a font that maintains its aspect ratio independent of resolution

local MUI =
{
	-- List of active screens
	_activeScreens = {},
	-- Loaded filenames
	_files = {},
	-- Factory for creating widgets
	_widgetFactory = {},
	-- resolves resource paths
	_fileResolver = nil,
	-- table for internal interface
	_internals = nil,
	-- for hiding/showing the entire UI
	_isVisible = true,
	-- used as a replacement for having to mess directly with the MOAIRenderMgr
	_renderables = {},
}

local function resolveFilename( filename )
	if MUI._fileResolver then
		return MUI._fileResolver( filename )
	end

	return filename
end

local function getResolution()
	return MUI._width, MUI._height
end

local function lookupSkin( ui, skinName )
	if ui._skins[ skinName ] then
		return ui._skins[ skinName ]
	end

	for _, dependent in ipairs( ui.dependents ) do
		local skin = lookupSkin( dependent, skinName )
		if skin then
			return skin
		end
	end

	return nil
end

local function lookupTextStyle( ui, textStyleName, textMode )
	textMode = textMode or UNIFORM_FONT
	if ui._textStyles[ textStyleName ] then
		assert( ui._textStyles[ textStyleName ][ textMode ] )
		return ui._textStyles[ textStyleName ][ textMode ]
	end

	for _, dependent in ipairs( ui.dependents ) do
		local textStyle = lookupTextStyle( dependent, textStyleName, textMode )
		if textStyle then
			return textStyle 
		end
	end

	return nil
end

local function processWidgetDef( def, ui )

	if def.skin then
		local skin = lookupSkin( ui, def.skin )
		assert(skin, "Skin not found: " ..def.skin)
		def = util.inherit( skin )( def )
	end
	
	return def
end

local function createWidget( def, ui, screen )
	def = processWidgetDef( def, ui )
	local ctor = MUI._widgetFactory[ def.ctor ]
	assert( ctor ~= nil,
		string.format( "No factory for widget '%s', type '%s'", 
		tostring(def.name), tostring(def.ctor)))

	local widget = ctor( screen, def )
	assert( widget )

	if def.isVisible == false then
		widget:setVisible( false )
	end

	return widget
end

local function loadUI( filename )
	filename = resolveFilename( filename )
	assert( filename ) -- Important assert, since loadfile's behaviour for nil filename is to read from stdin (can you say HANG?)
	local f,e = loadfile( filename )
	assert( f, e )

	-- Setup an environment to load the UI in so as to not clobber the global env.
	local envmt = { __index = _G }
	setfenv(f, setmetatable({}, envmt))

	return f()
end

local function parseUI( key, t )

	MUI._files[ key ] = t

	if t.dependents then
		for i,filename in ipairs(t.dependents) do
			local dependent = MUI._files[ filename ]
			if not dependent then
				dependent = loadUI( filename )
				parseUI( filename, dependent )
			end
			t.dependents[i] = dependent
		end
	end

	-- Create any specified text styles
	if t.text_styles then
		t._textStyles = {}
		for k,styledef in pairs(t.text_styles) do
			local fontfile = resolveFilename(styledef.font)
			if fontfile then
				local font = MOAIFont.new ()
				assert( MOAIFileSystem.checkFileExists( fontfile ), styledef.font .. " does not exist!" )
				font:loadFromBMFont( fontfile )
				if fontfile:find( ".sdf" ) then
					font:setFlags( MOAIFont.FONT_SIGNED_DISTANCE_FIELD )
				end
				local scale = (styledef.size or font:getDefaultSize()) / font:getDefaultSize()
			
				local scaledStyle = MOAITextStyle.new()
				scaledStyle:setColor( unpack(styledef.color) )
				scaledStyle:setFont( font )
				scaledStyle:setScale( scale / 1920, scale / 1080)

				local uniformStyle = MOAITextStyle.new()
				uniformStyle:setColor( unpack(styledef.color) )
				uniformStyle:setFont( font )
				uniformStyle:setScale( scale / MUI._width, scale / MUI._height )

				t._textStyles[ k ] = { [SCALED_FONT] = scaledStyle, [UNIFORM_FONT] = uniformStyle }
			end
		end
	end

	-- Create a dictionary of skins.	
	if t.skins then
		t._skins = {}
		for i,skin in ipairs(t.skins) do
			assert( skin.name )
			assert( t._skins[ skin.name ] == nil, "Loading duplicate skin " ..skin.name )
			t._skins[ skin.name ] = skin
		end
	end
end

local function setVisible( isVisible )
	if isVisible then
		MUI._isVisible = true
	else
		MUI._isVisible = false
	end
	
	for i = #MUI._activeScreens,1,-1 do
		local screen = MUI._activeScreens[i]
		if not screen:getProperties().alwaysVisible or isVisible then
			array.removeElement( MUI._renderables, screen:getLayer() )
			if MUI._isVisible then
				table.insert( MUI._renderables, screen:getLayer() )
			end
		end
	end	
end

local function isVisible()
	return MUI._isVisible
end

local function wasHandled()
	return MUI._wasHandled
end

local function createScreen( filename )

	-- Load if it doesn't already exist.
	if type(filename) == "string" and not MUI._files[ filename ] then
		parseUI( filename, loadUI( filename ))
	end

	-- Instantiate the widgets.
	if MUI._files[ filename ] then
		assert( MUI._files[ filename ].widgets, "Creating screen for " ..filename.. ", but no widgets specified.")

		local screen = mui_screen( MUI._internals, MUI._files[ filename ], filename )
		for i,def in ipairs(MUI._files[ filename ].widgets) do
			local widget = screen:createWidget( def )
			screen:addWidget( widget )
		end

		return screen
	end
end

local function updateTooltip( tooltipScreen )
	local tooltipWidget = tooltipScreen and tooltipScreen:getTooltip()
	if MUI._tooltip ~= tooltipWidget then
		if MUI._tooltip then
			MUI._tooltip:deactivate()
		end
		MUI._tooltip = tooltipWidget
		if MUI._tooltip then
			MUI._tooltip:activate( tooltipScreen )
		end
	end
	if MUI._tooltip then
		MUI._tooltip:setPosition( inputmgr:getMouseXY() )
	end
end

local function activateScreenInternal( screen )
	local topMost = MUI._activeScreens[1]

	screen:onActivate( MUI._width, MUI._height )
	
	assert( array.find( MUI._activeScreens, screen ) == nil )
	table.insert( MUI._activeScreens, 1, screen )
	table.sort( MUI._activeScreens,
		function( screen1, screen2 )
			return screen1:getPriority() > screen2:getPriority()
		end )

	for i = #MUI._activeScreens,1,-1 do
		local screen = MUI._activeScreens[i]
		array.removeElement( MUI._renderables, screen:getLayer() )
		if MUI._isVisible or screen:getProperties().alwaysVisible then
			table.insert( MUI._renderables, screen:getLayer() )
		end
	end

	-- If the topmost screen changes, need some updatin'.
	if topMost and topMost ~= MUI._activeScreens[1] then
		topMost:onLostTopmost()
	end
end

local function deactivateScreenInternal( screen )
	local topMost = MUI._activeScreens[1]

	array.removeElement( MUI._renderables, screen:getLayer() )
	screen:onDeactivate()

	assert( array.find( MUI._activeScreens, screen ) ~= nil )
	array.removeElement( MUI._activeScreens, screen )
end

local function activateScreen( screen )
	if screen:isActive() then
		-- If this screen is already active, then check to see whether it's currently transitioning for activation/deactivation.
		if screen:hasTransition( screen:getProperties().deactivateTransition, MOAITimer.NORMAL ) then
			screen:reverseTransition() -- Reverse deactivation.

		elseif screen:hasTransition( screen:getProperties().activateTransition, MOAITimer.REVERSE ) then
			screen:reverseTransition() -- Reactivate.

		else
			-- Screen is active but not transitioning; this is a redundant activation.  Ignore.
		end
	else
		if screen:getProperties().activateTransition then
			local function onTransition( transition )
				-- If activation was reversed, we must deactivate.
				if transition.mode == MOAITimer.REVERSE then
					deactivateScreenInternal( screen )
				end
			end

			screen:createTransition( screen:getProperties().activateTransition, onTransition )
		end

		activateScreenInternal( screen )
	end
end

local function deactivateScreen( screen )
	if screen:getTooltip() == MUI._tooltip then
		updateTooltip( nil )
	end

	if screen:getProperties().deactivateTransition ~= nil and screen:hasTransition( screen:getProperties().deactivateTransition ) then
		if screen:hasTransition( screen:getProperties().deactivateTransition, MOAITimer.REVERSE ) then
			screen:reverseTransition() -- Reverse re-activation.
		end

	elseif screen:getProperties().activateTransition ~= nil and screen:hasTransition( screen:getProperties().activateTransition ) then
		if screen:hasTransition( screen:getProperties().activateTransition, MOAITimer.NORMAL ) then
			screen:reverseTransition() -- Reverse activation.
		end

	elseif screen:getProperties().deactivateTransition then
		local function onTransition( transition )
			if transition.mode == MOAITimer.NORMAL then
				deactivateScreenInternal( screen )
			end
		end

		screen:createTransition( screen:getProperties().deactivateTransition, onTransition, { easeOut = true } )
		-- Transitioning, don't officially deactivate yet.

	else
		deactivateScreenInternal( screen )
	end
end


local function onResize( width, height )
	MUI._width, MUI._height = math.max(1,width), math.max(1,height)
	
	for key, ui in pairs( MUI._files ) do
		for k,style in pairs( ui._textStyles ) do
			style[ UNIFORM_FONT ]:setScale( 1 / MUI._width, 1 / MUI._height )
			style[ UNIFORM_FONT ]:setFont( style[ UNIFORM_FONT ]:getFont() )
		end
	end
	
	for i,screen in ipairs(MUI._activeScreens) do
		screen:onResize( width, height )
	end	
end

local function handleInputEvent( self, event )

	local handled = false
	local tooltipScreen = nil

	for i,screen in ipairs(MUI._activeScreens) do
		if screen:handlesInput() then
			event.x, event.y = screen:wndToUI( event.wx, event.wy )
			event.screen = screen

			handled = screen:handleInputEvent( event )

			if screen:handlesInput() and tooltipScreen == nil and screen:getTooltip() then
				tooltipScreen = screen
			end

			if handled then
				break
			end
		end
	end

	updateTooltip( tooltipScreen )

	MUI._wasHandled = handled -- Keep track of whether the last input event was handled.

	return handled
end

local function initMui( width, height, fn )

	assert( #MUI._activeScreens == 0 )
	
	MUI._width, MUI._height = width, height
	
	MUI._files = {}
	
	if KLEIRenderScene then -- Tools don't have a KLEIRenderSceneClass.
		KLEIRenderScene:setHudRenderTable( MUI._renderables )
	end

	-- Factory methods for instantiating widgets.  Invoked from loadUI.
	MUI._widgetFactory["button"] = mui_imagebutton
	MUI._widgetFactory["label"] = mui_label
	MUI._widgetFactory["lineleader"] = mui_lineleader
	MUI._widgetFactory["script"] = mui_script
	MUI._widgetFactory["editbox"] = mui_editbox
	MUI._widgetFactory["image"] = mui_image
	MUI._widgetFactory["checkbox"] = mui_checkbox
	MUI._widgetFactory["spinner"] = mui_spinner
	MUI._widgetFactory["group"] = mui_group
	MUI._widgetFactory["listbox"] = mui_listbox
	MUI._widgetFactory["combobox"] = mui_combobox
	MUI._widgetFactory["tabs"] = mui_tabs
	MUI._widgetFactory["radial"] = mui_radial
	MUI._widgetFactory["slider"] = mui_slider
	MUI._widgetFactory["scrollbar"] = mui_scrollbar
	MUI._widgetFactory["anim"] = mui_anim
	MUI._widgetFactory["dragzone"] = mui_dragzone
	MUI._widgetFactory["progressbar"] = mui_progressbar
    MUI._widgetFactory["movie"] = mui_movie

	MUI._fileResolver = fn

	if MUI.onInputEvent == nil then
		MUI.onInputEvent = handleInputEvent
		inputmgr.addListener( MUI )
	end
end

-- Setup internal interface.  This table is exposed to internal mui systems.
-- Would prefer a more straightforward way of doing this?
MUI._internals =
{
	createWidget = createWidget,
	resolveFilename = resolveFilename,
	getResolution = getResolution,
}

return
{
	loadUI = loadUI,
	parseUI = parseUI,

	setVisible = setVisible,
	isVisible = isVisible,
	wasHandled = wasHandled,
	updateTooltip = updateTooltip,

	createScreen = createScreen,
	activateScreen = activateScreen,
	deactivateScreen = deactivateScreen,

	lookupTextStyle = lookupTextStyle,

	onResize = onResize,
	initMui = initMui,
	
	internals = MUI
}
