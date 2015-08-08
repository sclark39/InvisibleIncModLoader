-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_group = require( "mui/widgets/mui_group" )
local mui_texture = require( "mui/widgets/mui_texture" )
local mui_container = require( "mui/widgets/mui_container" )
local mui_scroller = require( "mui/widgets/mui_scroller" )
require( "class" )

--------------------------------------------------------
-- Local Functions

local function updateItemPositions( radial )
	-- First item is at +y.  Items follow counter-clockwise at intervals of 2pi / #items.
	local r = radial._item_radius
	local a0 = math.pi / 2
	local da = 2 * math.pi / #radial._children

	for i,widget in ipairs( radial._children ) do
		local a = a0 + (i-1) * da
		local x, y = r * math.cos(a), r * math.sin(a)
		widget:setPosition( x, y )
	end
end

--------------------------------------------------------

local mui_radial = class( mui_group )

function mui_radial:init( screen, def )
	mui_group.init( self, screen, util.extend( def ){ children = {} } )

	self._item_ctor = function() return screen:createFromSkin( def.item_template ) end
	self._item_radius = def.item_radius
	self._items = {}
end

function mui_radial:addItem( user_data )
	local widget = self._item_ctor()
	self:addChild( widget )
	table.insert( self._items, user_data )

	updateItemPositions( self )
		
	return widget
end

function mui_radial:removeItem( idx )
	if idx > 0 and idx <= #self._items then
		self:removeChild( self._children[idx] )
		table.remove( self._items, idx )
		
		updateItemPositions( self )
	end
end

function mui_radial:getItemCount()
	return #self._items
end

function mui_radial:clearItems()
	while #self._items > 0 do
		self:removeItem( 1 )
	end
end

function mui_radial:handleTooltip()
	return nil -- radial menus themselves can't have tooltips, let it pass through
end

return mui_radial
