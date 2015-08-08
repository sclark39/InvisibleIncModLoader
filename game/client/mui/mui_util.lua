-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local util = include( "modules/util" )
local mui_defs = require("mui/mui_defs")

local function isMouseEvent( ev )
	return
		ev.eventType == mui_defs.EVENT_MouseDown or
		ev.eventType == mui_defs.EVENT_MouseUp or
		ev.eventType == mui_defs.EVENT_MouseMove or
		ev.eventType == mui_defs.EVENT_MouseWheel
end

local function isModifierKey( key )
    return key == mui_defs.K_CONTROL or key == mui_defs.K_SHIFT or key == mui_defs.K_ALT
end

local function setVisible( condition, ... )
	for i = 1, select( "#", ... ) do
		local widget = select( i, ... )
		widget:setVisible( condition )
	end
end

local KEY_NAMES =
{
	[ mui_defs.K_A ] = "A",
	[ mui_defs.K_B ] = "B",
	[ mui_defs.K_C ] = "C",
	[ mui_defs.K_D ] = "D",
	[ mui_defs.K_E ] = "E",
	[ mui_defs.K_F ] = "F",
	[ mui_defs.K_G ] = "G",
	[ mui_defs.K_H ] = "H",
	[ mui_defs.K_I ] = "I",
	[ mui_defs.K_J ] = "J",
	[ mui_defs.K_K ] = "K",
	[ mui_defs.K_L ] = "L",
	[ mui_defs.K_M ] = "M",
	[ mui_defs.K_N ] = "N",
	[ mui_defs.K_O ] = "O",
	[ mui_defs.K_P ] = "P",
	[ mui_defs.K_Q ] = "Q",
	[ mui_defs.K_R ] = "R",
	[ mui_defs.K_S ] = "S",
	[ mui_defs.K_T ] = "T",
	[ mui_defs.K_U ] = "U",
	[ mui_defs.K_V ] = "V",
	[ mui_defs.K_W ] = "W",
	[ mui_defs.K_X ] = "X",
	[ mui_defs.K_Y ] = "Y",
	[ mui_defs.K_Z ] = "Z",

	[ mui_defs.K_1 ] = "1",
	[ mui_defs.K_2 ] = "2",
	[ mui_defs.K_3 ] = "3",
	[ mui_defs.K_4 ] = "4",
	[ mui_defs.K_5 ] = "5",
	[ mui_defs.K_6 ] = "6",
	[ mui_defs.K_7 ] = "7",
	[ mui_defs.K_8 ] = "8",
	[ mui_defs.K_9 ] = "9",
	[ mui_defs.K_0 ] = "0",

	[ mui_defs.K_F1 ] = "F1",
	[ mui_defs.K_F2 ] = "F2",
	[ mui_defs.K_F3 ] = "F3",
	[ mui_defs.K_F4 ] = "F4",
	[ mui_defs.K_F5 ] = "F5",
	[ mui_defs.K_F6 ] = "F6",
	[ mui_defs.K_F7 ] = "F7",
	[ mui_defs.K_F8 ] = "F8",
	[ mui_defs.K_F9 ] = "F9",

	[ mui_defs.K_BACKSPACE ] = "BACKSPACE",
    [ mui_defs.K_BREAK ] = "BREAK",
	[ mui_defs.K_TAB ] = "TAB",
    [ mui_defs.K_CAPSLOCK ] = "CAPSLOCK",
	[ mui_defs.K_ENTER ] = "ENTER",

	[ mui_defs.K_LEFTARROW ] = "LEFT",
	[ mui_defs.K_UPARROW ] = "UP",
	[ mui_defs.K_RIGHTARROW ] = "RIGHT",
	[ mui_defs.K_DOWNARROW ] = "DOWN",

	[ mui_defs.K_ESCAPE ] = "ESC",
	[ mui_defs.K_SPACE ] = "SPACE",
	[ mui_defs.K_SNAPSHOT ] = "PRINTSCREEN",
	[ mui_defs.K_DELETE ] = "DEL",
    [ mui_defs.K_INSERT ] = "INS",
    [ mui_defs.K_LBRACKET ] = "L-BRACKET",
    [ mui_defs.K_RBRACKET ] = "R-BRACKET",
    [ mui_defs.K_SEMICOLON ] = "SEMICOLON",
	[ mui_defs.K_COMMA ] = "COMMA",
	[ mui_defs.K_MINUS ] = "-",
	[ mui_defs.K_PERIOD ] = "PERIOD",
	[ mui_defs.K_SLASH ] = "SLASH",
	[ mui_defs.K_BACKQUOTE ] = "BACKQUOTE",
    [ mui_defs.K_MENU ] = "MENU",
    [ mui_defs.K_BACKSLASH ] = "BACKSLASH",
    [ mui_defs.K_EQUALS ] = "=",
    [ mui_defs.K_QUOTE ] = "QUOTE",
    [ mui_defs.K_NUM_SLASH ] = "NUM /",
    [ mui_defs.K_NUM_ADD ] = "NUM +",
    [ mui_defs.K_NUM_SUB ] = "NUM -",
    [ mui_defs.K_NUM_ASTERISK ] = "NUM *",

    [ mui_defs.K_PAGEUP ] = "PAGEUP",
    [ mui_defs.K_PAGEDOWN ] = "PAGEDOWN",
    [ mui_defs.K_HOME ] = "HOME",
    [ mui_defs.K_END ] = "END",
    [ mui_defs.K_SCROLLLOCK ] = "SCROLL-LOCK",
    
	[ mui_defs.K_SHIFT ] = "SHIFT",
	[ mui_defs.K_CONTROL ] = "CTRL",
	[ mui_defs.K_ALT ] = "ALT",
}

local function getKeyName( keyCode )
	return KEY_NAMES[ keyCode ] or ""
end

local function getBindingName( binding )
    if type(binding) == "number" then
        return getKeyName( binding )
    else
        local str = ""
        for i = #binding, 1, -1 do
            local key = binding[i]
            if #str > 0 then
                if isModifierKey( key ) then
                    str = str .. "-"
                else
                    str = str .. " "
                end
            end
            str = str .. getKeyName( key )
        end
        return str
    end
end

local function makeBinding( keys )
    if type(keys) == "number" then
        return { keys }
    else
        table.sort( keys )
        return keys
    end
end

local function makeBindingFromInput( inputEvent )
    local binding = { inputEvent.key }
    if inputEvent.shiftDown and inputEvent.key ~= mui_defs.K_SHIFT then
        table.insert( binding, mui_defs.K_SHIFT )
    end
    if inputEvent.controlDown and inputEvent.key ~= mui_defs.K_CONTROL then
        table.insert( binding, mui_defs.K_CONTROL )
    end
    return makeBinding( binding )
end

local function isBinding( inputEvent, binding )
    assert( inputEvent )
    if type(binding) == "number" then
        return inputEvent.key == binding and not inputEvent.shiftDown and not inputEvent.controlDown
    else
        local shiftDown = util.indexOf( binding, mui_defs.K_SHIFT ) ~= nil
        local controlDown = util.indexOf( binding, mui_defs.K_CONTROL ) ~= nil
        if shiftDown ~= (inputEvent.shiftDown == true) or controlDown ~= (inputEvent.controlDown == true) then
            return false
        end
        for i, key in ipairs(binding) do
            if key == mui_defs.K_SHIFT or key == mui_defs.K_CONTROL then
                -- handleda bove.
            elseif key ~= inputEvent.key then
                return false
            end
        end
        return #binding > 0 -- binding must be non-empty to be valid
    end
end

local function isBindingDown( binding )
    if type(binding) ~= "table" then
        return false
    end
    for i, key in ipairs(binding) do
        if not inputmgr.keyIsDown( key ) then
            return false
        end
    end
    return #binding > 0  -- binding must be non-empty to be valid
end

local function loopSpool( widget, frame )
    if frame % 240 == 0 then
        widget:spoolText( widget:getText() )
    end
    return true
end

return
{
	TOP_PRIORITY = 1000000,
	isMouseEvent = isMouseEvent,
	getKeyName = getKeyName,
    getBindingName = getBindingName,
    makeBinding = makeBinding,
    makeBindingFromInput = makeBindingFromInput,
    isBinding = isBinding,
    isBindingDown = isBindingDown,
	setVisible = setVisible,
    loopSpool = loopSpool
}

