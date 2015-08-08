-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_component = require( "mui/widgets/mui_component" )

--------------------------------------------------------

local function createTextBox( screen, def )
	local textStyle = screen:getAllTextStyles()[ def.text_style ]
	if not textStyle then
		log:write( "MISSING TEXT STYLE: '%s' on '%s'", tostring(def.text_style), tostring(def.name) )
	elseif def.wpx or def.hpx then
		textStyle = textStyle[ 2 ] -- UNIFORM_FONT
	else
		textStyle = textStyle[ 1 ]
	end

	local prop = MOAITextBox.new()
	prop:setStyle( textStyle )
	prop:setAlignment( def.halign, def.valign )
	prop:setYFlip ( true )
    if def.line_spacing then
	    prop:setLineSpacing( def.line_spacing / 72 )
    end
	
	for k,v in pairs(screen:getAllTextStyles()) do
		if def.wpx or def.hpx then
			prop:setStyle( k, v[ 2 ]) -- UNIFORM_FONT
		else
			prop:setStyle( k, v[ 1 ]) -- SCALED_FONT
		end
	end

	return prop
end


-----------------------------------------------------------------------------
-- Edit functions

-- Legal edit box keys, in lua pattern matching form.
local LEGAL_KEYS ='[%w%p\n ]'

local function isLegalKey( keychar )
	return keychar:match( LEGAL_KEYS ) ~= nil
end

local function insertAtCursor( self, str )
	local cursor = self._prop:getCursor()
	if cursor >= 0 and cursor <= #self._str and #self._str < self._maxEditChars then
		self._str = self._str:sub(0, cursor) .. str .. self._str:sub( cursor + 1, #self._str )
		self:refresh()
		self:moveCursor( cursor + 1 )
	end
end

local function deleteAtCursor( self, cursor )
	if cursor >= 1 and cursor <= #self._str then
		self._str = self._str:sub(0, cursor - 1) .. self._str:sub( cursor + 1, #self._str )
		self:refresh()
	end
end

local function insertInput( self, str )
	if #self._input < self._maxEditChars then
		self._input = self._input .. str
		insertAtCursor( self, str )
	end
end

local function deleteInput( self )
	if #self._input > 0 then
		self._input = self._input:sub( 1, #self._input - 1 )
		deleteAtCursor( self, self._prop:getCursor() )
	end
end

local function commitInput( self, screen )
	assert( self._mode == mui_defs.EDIT_CMDPROMPT )
	self:dispatchEvent( { eventType = mui_defs.EVENT_EditComplete, widget = self, input = self._input, screen = screen } )
	self._input = ""
end

--------------------------------------------------------

local mui_text = class( mui_component )

function mui_text:init( screen, def )
	mui_component.init( self, createTextBox( screen, def ), def)

	self._maxEditChars = def.maxEditChars or 0
	self._isMultiline = def.isMultiline
    self._line_spacing = def.line_spacing

    if def.str then
        local locstr = STRINGS.SCREENS[ def.str ]
        if type(locstr) == "string" then
	    	self:setText( locstr )
        else
            -- missing! replace with the locstr key
            log:write( "MISSING LOCSTR: %s (%s)", def.str, tostring(def.name) )
            self:setText( def.rawstr or def.str )
        end
	elseif def.rawstr then
		self:setText( def.rawstr )
	else
		self:setText()
	end

	if def.color then
		self._prop:setColor( unpack(def.color ))
	end
end

function mui_text:getStringBounds()
	local xmin, ymin, xmax, ymax = self._prop:getLineBounds()
	xmin, ymin = self._prop:modelToWorld( xmin, ymin )
	xmax, ymax = self._prop:modelToWorld( xmax, ymax )

	return math.min( xmin, xmax ), math.min( ymin, ymax ), math.max( xmin, xmax ), math.max( ymin, ymax )
end

function mui_text:refreshProp()
	if self._screen == nil then
		return
	end

	local x, y, w, h = self:calculateBounds()
	-- This epsilon is a dirty hack to fix text cropping issues during resizing due to FP precision.
	-- In particular, if the text label has the same height as its font in pixels, the height comparison
	-- between the prop height and the glyph height during layout will shimmer between < and > dependin on the
	-- vertical resolution.  Dunno the proper fix.
	local epsilon = 0.00001
	-- Need to uber-careful with text pixel alignment.  Ensure loc is in the centre of a pixel.
	-- Depending on whether width/height is odd or even, may have to ensure the bounds are slightly offset to land on
	-- pixel boundaries.
	local W, H = self._screen:getResolution()
	self._prop:setLoc( x + 0.5/W, y + 0.5/H )

	local left, right, bottom, top = -w/2, w/2, -h/2 - epsilon, h/2 + epsilon
	if (w * W) % 2 == 0 then
		left, right = left + 0.5/W, right + 0.5/W
	end
	if (h * H) % 2 == 0 then
		bottom, top = bottom + 0.5/H, top + 0.5/H
	end

	self._prop:setRect( left, bottom, right, top )

	self._prop:setStyle( self._prop:getStyle() )
	self._prop:forceUpdate()

    if self._line_spacing then
        self._prop:setLineSpacing( self._line_spacing * (720/H) / 72 )
    end
end

function mui_text:setColor( r, g, b, a )
	self._prop:setColor( r, g, b, a )
end

function mui_text:setText( str )
	self._str = tostring(str or "")

	local displayStr
	if self._pwchar then
		displayStr = self._pwchar:rep( #self._str )
	else
		displayStr = self._str
	end

	self._prop:setString( displayStr )

	if self._mode == mui_defs.EDIT_CMDPROMPT then
		self._prop:setCursor( #self._str )
	end
end

function mui_text:isSpooling(  )
	return self._prop:isBusy()
end

function mui_text:spoolText( str, speed )
    if str then
	    self:setText( str )
	    self._prop:spool()
	    if speed then
		    self._prop:setSpeed( speed )
	    end
    else
        self._prop:stop()
    end
end

function mui_text:setReveal( numChars )
    self._prop:setReveal(numChars)
end

function mui_text:setLineSpacing( spacing )
	self._prop:setLineSpacing( spacing )
end

function mui_text:setAlignment( hAlign, vAlign )
	self._prop:setAlignment( hAlign, vAlign )
end

function mui_text:getText()
	return self._str
end

function mui_text:onActivate( screen, widget )
	mui_component.onActivate( self, screen, widget )
	self._screen = screen
end

function mui_text:onDeactivate( screen )
	mui_component.onDeactivate( self, screen )
    self._prop:stop()
	self._screen = nil
end

function mui_text:handleInputEvent( ev )
	if self._maxEditChars > 0 then
		if ev.eventType == mui_defs.EVENT_KeyDown or ev.eventType == mui_defs.EVENT_KeyRepeat or ev.eventType == mui_defs.EVENT_KeyChar then
			return self:handleEvent( ev )

		elseif ev.eventType == mui_defs.EVENT_MouseDown and ev.button == mui_defs.MB_Left then
			if self._mode ~= mui_defs.EDIT_CMDPROMPT then
				if self._prop:inside( ev.x, ev.y ) then
					if not self:isEditing() then
						self:startEditing( ev.screen )
					else
						local x, y = self._prop:worldToModel( ev.x, ev.y )
						local idx = self._prop:findGlyphIndex( x, y )
						self:moveCursor( idx )
					end
					return true
				else
					self:finishEditing( ev.screen )
					return false -- allow this to be handled as normal elsewhere
				end
			end
		end
	end

	return false
end

function mui_text:refresh()
	self:setText( self._str )
end

function mui_text:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_OnLostLock then
		self:finishEditing( self._screen )

	elseif ev.eventType == mui_defs.EVENT_KeyDown or ev.eventType == mui_defs.EVENT_KeyRepeat then
		if self._mode == mui_defs.EDIT_CMDPROMPT then
			if ev.key == mui_defs.K_BACKSPACE then
				deleteInput( self )
			elseif ev.key == mui_defs.K_ENTER then
				commitInput( self, ev.screen )
			end

		else
			if ev.key == mui_defs.K_BACKSPACE then
				deleteAtCursor( self, self._prop:getCursor() )
				self:moveCursor( self._prop:getCursor() - 1 )
			elseif ev.key == mui_defs.K_DELETE then
				deleteAtCursor( self, self._prop:getCursor() + 1 )
			elseif ev.key == mui_defs.K_ENTER then
				if self._isMultiline then
					insertAtCursor( self, "\n" )
				else
					self:finishEditing( ev.screen )
				end
			elseif ev.key == mui_defs.K_LEFTARROW then
				self:moveCursor( self._prop:getCursor() - 1 )
			elseif ev.key == mui_defs.K_RIGHTARROW then
				self:moveCursor( self._prop:getCursor() + 1 )
			end
		end
		return true

    elseif ev.eventType == mui_defs.EVENT_KeyChar and isLegalKey( ev.keychar ) then
		if self._mode == mui_defs.EDIT_CMDPROMPT then
			insertInput( self, ev.keychar )
        else
			insertAtCursor( self, ev.keychar )
        end

	elseif ev.eventType == mui_defs.EVENT_OnResize then
		self:refreshProp()
	end
end

function mui_text:setPasswordChar( pwchar )
	assert(pwchar == nil or (type(pwchar) == "string" and #pwchar == 1))

	self._pwchar = pwchar
	self:refresh()
end

function mui_text:isEditing( screen )
	return self._prop:getCursor() >= 0
end

function mui_text:startEditing( screen, mode )
	if not self._isDisabled and self._mode == nil then
		screen:lockInput( self )
		self._oldStr = self._str
		self._input = ""
		self._mode = mode or mui_defs.EDIT_DEFAULT
		self._prop:setCursor( #self._str )
	end
end

function mui_text:finishEditing( screen )
	screen:unlockInput( self )
	self._prop:clearCursor()

	local hasChanged = self._oldStr ~= self._str
	local input = self._input
	self._oldStr = nil
    self._mode = nil

	if hasChanged then
		self:dispatchEvent( { eventType = mui_defs.EVENT_EditComplete, widget = self, screen = screen } )
	end
end

function mui_text:moveCursor( idx )
	self._prop:setCursor( idx )
end

return mui_text

