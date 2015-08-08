-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_container = require( "mui/widgets/mui_container" )
local mui_binder = require("mui/mui_binder")

--------------------------------------------------------
-- Local Functions


--------------------------------------------------------

local mui_group = class( mui_widget )

function mui_group:init( screen, def )
	mui_widget.init( self, def )

	self._cont = mui_container( def )
	self._children = {}
	
	for i,childdef in ipairs(def.children) do
		local child = screen:createWidget( childdef )
		self:addChild( child )
	end

	self.binder = mui_binder.create( self )
end

return mui_group
