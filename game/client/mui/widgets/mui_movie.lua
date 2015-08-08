-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local mui_widget = include( "mui/widgets/mui_widget" )
local mui_component = include( "mui/widgets/mui_component" )
local mui_defs = include( "mui/mui_defs" )

--------------------------------------------------------

local mui_movie_component = class( mui_component )

function mui_movie_component:init( mui, def )
    local theoraDeck = KLEITheoraDeck.new()
    if def.movieFile and #def.movieFile > 0 then
        theoraDeck:loadMovie( def.movieFile )
    end
    theoraDeck:setRect( -0.5, 0.5, 0.5, -0.5 )
    theoraDeck:setListener( KLEITheoraDeck.EVENT_MOVIE_END,
        function( deck )
        	self:dispatchEvent( { eventType = mui_defs.EVENT_MovieFinished, widget = self } )
        end )

    local theoraProp = MOAIProp2D.new()
    theoraProp:setDeck( theoraDeck )

	mui_component.init( self, theoraProp, def )
    self._deck = theoraDeck
end

function mui_movie_component:refreshProp()
	if self._screen then
		local x, y, w, h = self:calculateBounds()
		self._prop:setLoc( x, y )
		self._prop:setScl( self._sx, self._sy )
		self._prop:setBounds( -w/2, -h/2, 0, w/2, h/2, 0 )
		self._prop:forceUpdate()
        self._deck:setRect( -w/2, h/2, w/2, -h/2 )
	end
end

function mui_movie_component:play( filename )
    if filename then
        if not self._deck:loadMovie( filename ) then
            log:write( "mui_movie:playMovie( '%s' ) -- failed to load", filename )
        end
        self._deck:playMovie()
    else
        self._deck:playMovie()
    end
end

function mui_movie_component:stop()
    self._deck:stopMovie()
end

function mui_movie_component:pause()
    self._deck:pause()
end

--------------------------------------------------------

local mui_movie = class( mui_widget )

function mui_movie:init( mui, def )
	mui_widget.init( self, def )

	self._cont = mui_movie_component( mui, def )
	self._cont:addEventHandler( self, mui_defs.EVENT_ALL )
end

function mui_movie:playMovie( filename )
    --disable bloom
    KLEIRenderScene:setGaussianBlur(0)
    self._cont:play( filename )
end

function mui_movie:stopMovie()
    self._cont:stop()
end

function mui_movie:pauseMovie()
    self._cont:play()
end

function mui_movie:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_MovieFinished then
		if self.onFinished then
            --enable bloom
            local settings = savefiles.getSettings( "settings" ).data
            KLEIRenderScene:setGaussianBlur( settings.enableBloom and 1.0 or 0 )
			util.coDelegate( self.onFinished, self )
        end
    end
end

function mui_movie:stop()
    self:stopMovie()
end

return mui_movie

