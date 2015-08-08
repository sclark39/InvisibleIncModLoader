-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_text = require( "mui/widgets/mui_text" )
require( "class" )

--------------------------------------------------------

local mui_label = class( mui_widget )

function mui_label:init( screen, def )
	mui_widget.init( self, def )

	self._cont = mui_text( screen, def )
end

function mui_label:getBounds()
	local x, y, w, h = self._cont:calculateBounds()
	return x, y, w, h
end

function mui_label:getStringBounds()
	return self._cont:getStringBounds()
end

function mui_label:setSize( w, h )
	self._cont:setSize( w, h )
end

function mui_label:setColor( r, g, b, a )
	self._cont:setColor( r, g, b, a )
end

function mui_label:seekColor( rGoal, gGoal, bGoal, aGoal, length, mode )
	self._cont:getProp():seekColor( rGoal, gGoal, bGoal, aGoal, length, mode)
end

function mui_label:setText( str )
	self._cont:setText( str )
end

function mui_label:nextPage()
    self._cont:getProp():nextPage( true )
end

function mui_label:hasNextPage()
    self._cont:getProp():forceUpdate()
    return self._cont:getProp():more()
end

function mui_label:getText()
	return self._cont:getText()
end

function mui_label:isSpooling()
	return self._cont:isSpooling()
end

function mui_label:spoolText( str, speed )
	self._cont:spoolText( str, speed )
end

function mui_label:setReveal( numChars )
	self._cont:setReveal( numChars )
end

function mui_label:setLineSpacing( spacing )
	self._cont:setLineSpacing( spacing )
end

function mui_label:setAlignment( hAlign, vAlign )
	self._cont:setAlignment( hAlign, vAlign )
end

function mui_label:handleTooltip( ... )
    local tt = mui_widget.handleTooltip( self, ... )
    if not tt and not self._cont._noInput then
        return false -- if no tt, sink it here.
    end
    return tt
end

return mui_label

