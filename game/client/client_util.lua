----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

--
-- Client-side helper functions.  Mostly these deal with MOAI userdata, as the
-- server will not support these.
-- For convenience, these are merged into the general util table.

local util = include( "modules/util" )
local mui_tooltip = include( "mui/mui_tooltip" )
----------------------------------------------------------------
-- Local functions

local tooltip_section  = class()

function tooltip_section:init( tooltip )
	self._tooltip = tooltip
	self._widget = tooltip._screen:createFromSkin( "tooltip_section" )
	self._children = {}
end

function tooltip_section:appendHeader( actionTxt, infoTxt )
	self:addLine( string.format( "%s: <tthotkey>[ %s ]</>", infoTxt, actionTxt))
end

function tooltip_section:addLine( txt, lineRight )
	local widget = self._tooltip._screen:createFromSkin( "tooltip_section_line" )
	widget.binder.line:setText( txt )
	widget.binder.lineRight:setText( lineRight )
	self._widget:addChild( widget )
	widget.activate = function( self, screen )
		local TOP_BUFFER = 4
		local W, H = screen:getResolution()
		local rxmin, rymin, rxmax, rymax = widget.binder.lineRight:getStringBounds()
		local xmin, ymin, xmax, ymax = widget.binder.line:getStringBounds()
        local xpos = nil
        if rxmax > rxmin and xmax >= rxmin then
            local tw = math.ceil( W * (rxmin - xmin ))
            widget.binder.line:setSize( tw )
            xpos = tw / 2 + 8 -- HACK: +8 mimics the slight left-padding that normally is inherited from the default line's position
        end
		local xmin, ymin, xmax, ymax = widget.binder.line:getStringBounds()
		local th = math.ceil(H * (ymax - ymin) / 2) * 2 + TOP_BUFFER
		widget.binder.line:setSize( nil, th )
		widget.binder.line:setPosition( xpos, (th / -2) - TOP_BUFFER )
	end
	table.insert( self._children, widget )
end

function tooltip_section:addDesc( txt )
	local widget = self._tooltip._screen:createFromSkin( "tooltip_section_desc" )
	widget.binder.desc:setText( txt )
	self._widget:addChild( widget )
	widget.activate = function( self, screen )
		local TOP_BUFFER = 4
		local W, H = screen:getResolution()
		local xmin, ymin, xmax, ymax = widget.binder.desc:getStringBounds()
		local th = math.ceil(H * (ymax - ymin) / 2) * 2 + TOP_BUFFER
		widget.binder.desc:setSize( nil, th )
		widget.binder.desc:setPosition( nil, (th / -2) - TOP_BUFFER )
	end
	
	table.insert( self._children, widget )
end

function tooltip_section:addRequirement( txt )
    self:addDesc( "<c:ff0000>" .. txt .. "</>" )
end

function tooltip_section:addRange( range, x0, y0, clr )
    if self._tooltip._game then
        assert( range and x0 and y0 )
        self._rangeHilite = { x = x0, y = y0, range = range, color = clr }
    end
end

function tooltip_section:addUnitHilites( units )
    if self._tooltip._game then
        self._hiliteUnits = units
    end
end

function tooltip_section:addAbility( line1, line2, icon )
	
	local widget = self._tooltip._screen:createFromSkin( "tooltip_section_ability" )	
	widget.binder.desc:setText( string.format( "<c:8CFFFF>%s</>\n%s", util.toupper(line1),line2 or "" ))

	widget.binder.img:setImage( icon or "gui/icons/arrow_small.png" )
	self._widget:addChild( widget )

	self._abilityCount = (self._abilityCount or 0) + 1

	widget.activate = function( self, screen )
		local W, H = screen:getResolution()
        local TOP_SPACE, BOTTOM_SPACE = 4, 4
		local xmin, ymin, xmax, ymax = widget.binder.desc:getStringBounds()		
		local th = math.floor(H * (ymax - ymin) / 2) * 2 + BOTTOM_SPACE
		widget.binder.desc:setSize( nil, th )
		widget.binder.desc:setPosition( nil, -(TOP_SPACE + math.floor(th / 2)) )
	end

	table.insert( self._children, widget )
end

function tooltip_section:addWarning( title, line, icon, color )
	local widget = self._tooltip._screen:createFromSkin( "tooltip_section_warning" )	
	widget.binder.desc:setText( string.format( "<font1_16_r>%s</>\n%s", util.toupper(title), line ))
	self._widget:addChild( widget )

	if color then
		widget.binder.bg:setColor(color:unpack())
		widget.binder.desc:setColor(color:unpack())
		widget.binder.img:setColor(color:unpack())
	end
	
	if icon then
		widget.binder.img:setImage(icon)		
	end

	table.insert( self._children, widget )
end

function tooltip_section:activate( screen )
	self._screen = screen
	screen:addWidget( self._widget )

	self._widget:updatePriority( mui_tooltip.TOOLTIP_PRIORITY )
	local W, H = screen:getResolution()

	if self._w == nil or self._W ~= W or self._H ~= H then
        self._W, self._H = W, H
		local ty = 0
		for _, child in ipairs( self._children ) do
			if child.activate then
				child:activate( screen )
			end

			child:setPosition( nil, ty )
			local x, y, w, h = child:calculateBounds()
			ty = math.floor((y - h/2) * H ) / H
		end

		--jcheng: hack to give it a tiny bit more room at the bottom
		local BOTTOM_BUFFER = 1
		ty = ty - BOTTOM_BUFFER/H

		if #self._children > 0 then
			self._widget.binder.bg:setSize( nil, math.floor( H * math.abs(ty) ) )
			self._widget.binder.bg:setPosition( nil, math.floor( H * -math.abs(ty) / 2 ) )
		end

		local x, y, w, h = self._widget:calculateBounds()
		self._w, self._h = w, h
	end

    if self._rangeHilite then
        local simquery = include( "sim/simquery" )
        local x, y, range = self._rangeHilite.x, self._rangeHilite.y, self._rangeHilite.range
        local cells = simquery.rasterCircle( self._tooltip._game.simCore, x, y, range )
        self._hiliteID = self._tooltip._game.boardRig:hiliteCells( cells, self._rangeHilite.color )
    end
    if self._hiliteUnits then
        local cdefs = include( "client_defs" )
        for i, unitID in ipairs( self._hiliteUnits ) do
            local ur = self._tooltip._game.boardRig:getUnitRig( unitID )
            if ur then
                ur:getProp():setRenderFilter( cdefs.RENDER_FILTERS["focus_target"] )
            end
        end
    end
end

function tooltip_section:deactivate( )
	self._screen:removeWidget( self._widget )
    if self._hiliteID then
        self._tooltip._game.boardRig:unhiliteCells( self._hiliteID )
        self._hiliteID = nil
    end
    if self._hiliteUnits then
        for i, unitID in ipairs( self._hiliteUnits ) do
            local ur = self._tooltip._game.boardRig:getUnitRig( unitID )
            if ur then
                ur:refreshRenderFilter()
            end
        end
    end
end

function tooltip_section:getSize()
	return self._w, self._h
end

function tooltip_section:setPosition( tx, ty )
	self._widget:setPosition( tx, ty )
end


local tooltip = class( mui_tooltip )

function tooltip:init( screen, game )
	self._screen = screen
	self._sections = {}
    self._game = game
end

function tooltip:clear()
	while #self._sections > 0 do
		table.remove( self._sections ):deactivate()
	end
end

function tooltip:addSection()
	local section = tooltip_section( self )
	table.insert( self._sections, section )
	return section
end

function tooltip:activate( screen )
	for _, section in ipairs( self._sections ) do
		section:activate( screen )
	end
end

function tooltip:deactivate()
	for _, section in ipairs( self._sections ) do
		section:deactivate()
	end
end

function tooltip:setPosition( wx, wy )	
	if #self._sections > 0 then
		local W, H = self._screen:getResolution()
		local YSPACING =  4 / H

		-- Need to calculate the total tooltip bound so we can fit it on screen.
		local tw, th = 0, 0
		for _, section in ipairs( self._sections ) do
			local sectionw, sectionh = section:getSize()
			tw = math.max( tw, sectionw )
			th = th + sectionh + YSPACING
		end

		-- Now position each tooltip section accordingly.
		local tx, ty = self:fitOnscreen( tw, th, self._screen:wndToUI( wx + mui_tooltip.TOOLTIPOFFSETX, wy + mui_tooltip.TOOLTIPOFFSETY ))
	
		for _, section in ipairs( self._sections ) do
			section:setPosition( tx, ty )
			local sectionw, sectionh = section:getSize()
			ty = ty - sectionh - YSPACING			
		end
	end
end

local function formatParamsInfo( params )
    if params.campaignDifficulty then
	    return string.format("GAME [%s].%d.%d.%d.%d.%s.%s.%u", tostring(params.missionVersion), params.difficulty, params.campaignDifficulty, params.missionCount, params.miniserversSeen, params.situationName, params.world, params.seed )
    else
        return string.format( "GAME %s", params.levelFile )
    end
end

local function formatCampaignInfo( campaign )
	local info = { "campaign = {" }
	for k, v in pairs(campaign) do
		if type(v) == "string" and #v > 64 then
			table.insert( info, string.format("\t%s = <strlen=%d>", tostring(k), #v))
		else
			table.insert( info, string.format("\t%s = %s", tostring(k), tostring(v)))
		end
	end
	table.insert( info, "}" )
	return table.concat( info, "\n" )
end

local function formatGameInfo( params )
    local version = include( "modules/version" )
    local isModified = not MOAIEnvironment.isVerified() or config.SRC_MEDIA ~= "game"
	local str = string.format( "BUILD[%s.%s] LUA[%s%s] USER[%s]",
		MOAIEnvironment.Build_Branch, MOAIEnvironment.Build_Version,
        version.REVISION,
		isModified and "*" or "",
		MOAIEnvironment.UserID or "" )
	str = str .. string.format( "\nOS: %s.%s.%s", MOAIEnvironment.OS, MOAIEnvironment.OS_Version, MOAIEnvironment.OS_Build )
	if params then
		str = str .. "\n" .. formatParamsInfo( params )
	end
	return str
end

local function colorToRGBA( color )
	local r = color:getAttr( MOAIColor.ATTR_R_COL )
	local g = color:getAttr( MOAIColor.ATTR_G_COL )
	local b = color:getAttr( MOAIColor.ATTR_B_COL )
	local a = color:getAttr( MOAIColor.ATTR_A_COL )

	return r, g, b, a
end

local function applyUserSettings( settings )
	--log:write( "applyUserSettings: music: %f, SFX: %f", settings.volumeMusic, settings.volumeSfx )
	MOAIFmodDesigner.setCategoryVolume( "music", settings.volumeMusic )
	MOAIFmodDesigner.setCategoryVolume( "sfx", settings.volumeSfx )
end

local function getKeyBinding( name )
    local cdefs = include( "client_defs" )
    local settings = savefiles.getSettings( "settings" )
    if settings.data.keybindings and settings.data.keybindings[ name ] then
        return settings.data.keybindings[ name ]
    else
        for i, binding in ipairs( cdefs.ALL_KEYBINDINGS ) do
            if binding.name == name then
                return binding.defaultBinding
            end
        end

        return nil
    end
end

local function isKeyBindingEvent( name, inputEvent )
    local mui_util = include( "mui/mui_util" )
    local binding = getKeyBinding( name )
    return binding and mui_util.isBinding( inputEvent, binding )
end

local function isKeyBindingDown( name )
    local mui_util = include( "mui/mui_util" )
    local binding = getKeyBinding( name )
    return binding and mui_util.isBindingDown( binding )
end

----------------------------------------------------------------
-- Export table

return util.tmerge( util,
{
	applyUserSettings = applyUserSettings,
    getKeyBinding = getKeyBinding,
    isKeyBindingEvent = isKeyBindingEvent,
    isKeyBindingDown = isKeyBindingDown,
	colorToRGBA = colorToRGBA,
	formatParamsInfo = formatParamsInfo,
	formatCampaignInfo = formatCampaignInfo,
	formatGameInfo = formatGameInfo,
	tooltip = tooltip,
})
