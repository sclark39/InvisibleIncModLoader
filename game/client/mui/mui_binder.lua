-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )

local mui_binder = {}

local function _bindingWarning() end

local function _tryBind( self, name )
    local widget = self._bindings[name]
    if widget and not widget.isnull then
        return widget
    end
	
    self._bindings[name] = self._container:findWidget(name)
    return self._bindings[name]
end

local function _forEachIterator( state, i )
	local widget = state.binder:tryBind( state.name .. tostring(i + 1) )
	if widget == nil then
		return nil
	else
		return i + 1, widget
	end
end

local function _forEach( self, name, i )
	return _forEachIterator, { name = name, binder = self }, i or 0
end

local function _exists( self, name )
	return self._container:findWidget(name) ~= nil
end

local nullBindingMt =
{
	__index = function( t, k )
		log:write("WARNING: failed bind '%s' accessing '%s'\n%s", t.name, tostring(k), debug.traceback())

		-- Typically only functions are accessed by widgets, so return a null function
		return _bindingWarning
	end,

	__newindex = function( t, k, v )
		log:write("WARNING: failed bind '%s' assigning '%s'\n%s", t.name, tostring(k), debug.traceback())
	end
}

local function createNullBinding( name )
	return setmetatable( { name = name, isnull = true }, nullBindingMt )
end

function mui_binder.__index( t, k )
	-- Trying to bind a widget named 'k'.
	if t._bindings[k] == nil then
		local widget = t._container:findWidget(k)
		if not widget then
			widget = createNullBinding( k )
		end
		t._bindings[k] = widget
	end

	return t._bindings[k]
end

function mui_binder.__newindex( t, k, v )
	assert(false, "This table cannot be assigned to.")
end

function mui_binder.create( container )
	local binder = {}
	binder._container = container
	binder._bindings = {}
	binder.tryBind = _tryBind
	binder.forEach = _forEach
	binder.exists = _exists

	setmetatable( binder, mui_binder )
	return binder
end

return mui_binder
