-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_button = require( "mui/widgets/mui_button" )
local mui_imagebutton = require( "mui/widgets/mui_imagebutton" )
local mui_texture = require( "mui/widgets/mui_texture" )
local mui_container = require( "mui/widgets/mui_container" )
local mui_group = require( "mui/widgets/mui_group" )

--------------------------------------------------------
-- Local Functions

local TAB_ImageStates =
{
	[false] = { [mui_button.BUTTON_Inactive] = 1, [mui_button.BUTTON_Hover] = 2, [mui_button.BUTTON_Active] = 3 },
	[true] = { [mui_button.BUTTON_Inactive] = 4, [mui_button.BUTTON_Hover] = 5, [mui_button.BUTTON_Active] = 6 },
}

local function _updateImageState( self )
	local isSelected = self._tabs:getSelectedTab() == self._index
	if self._button:getState() == mui_button.BUTTON_Disabled then
		self._image:setImageIndex( TAB_ImageStates[ isSelected ][ self._button:getState() ] )
		self._image:setShader( MOAIShaderMgr.DESATURATION_SHADER )
	else
		self._image:setImageIndex( TAB_ImageStates[ isSelected ][ self._button:getState() ] )
		self._image:setShader()
	end
end

local function onClickTabButton( tabs, index )
	tabs:selectTab( index )
end

--------------------------------------------------------
-- mui_tabs interface

local mui_tabs = class( mui_widget )

function mui_tabs:init( screen, def )
	mui_widget.init( self, def )

	self._cont = mui_container( def )
	self._cont._prop:setBounds( -def.w / 2, -def.h / 2, 0, def.w / 2, def.h / 2, 0 )
	self._selectedTab = def.selectedTab

	self._tabs = {}
	self._pages = {}

	for i,tabpage in ipairs(def.tabs) do
		local tab = screen:createWidget( tabpage[1] )
		-- HACKZORS
		tab._button = tab:findWidget("tabButton")
		tab._button.updateImageState = _updateImageState
		tab._button.onClick = util.makeDelegate( nil, onClickTabButton, self, i )
		tab._button._tabs = self
		tab._button._index = i
		_updateImageState( tab._button )

		local page = screen:createWidget( tabpage[2] )
		self:addTabPage( tab, page )
	end
end

function mui_tabs:findWidget( name )
	if self._name == name then
		return self
	end

	local found = nil
	for i,pageWidget in ipairs(self._pages) do
		found = pageWidget:findWidget( name )
		if found then
			break
		end
	end

	return found
end

function mui_tabs:addTabPage( tabWidget, pageWidget )
	table.insert( self._tabs, tabWidget )
	self:addChild( tabWidget )

	table.insert( self._pages, pageWidget )
	if #self._pages == self._selectedTab then
		self:addChild( pageWidget )
	end
end

function mui_tabs:getTabCount()
	return #self._tabs
end

function mui_tabs:getSelectedTab()
	return self._selectedTab
end

function mui_tabs:selectTab( index )
	assert( index >= 1 and index <= #self._tabs )

	if index ~= self._selectedTab then
		local oldTab = self._selectedTab
		self._selectedTab = index

		-- Update old tab state.
		if oldTab >= 1 and oldTab <= #self._tabs then
			self._tabs[ oldTab ]._button:updateImageState()
			self:removeChild( self._pages[ oldTab ] )
		end

		-- Update new tab state
		if self._selectedTab >= 1 and self._selectedTab <= #self._tabs then
			self._tabs[ self._selectedTab ]._button:updateImageState()
			self:addChild( self._pages[ self._selectedTab ] )
		end

		if self.onSelectedTab then
			util.callDelegate( self.onSelectedTab, self, oldTab, index )
		end
	end
end

function mui_tabs:handleTooltip()
	return nil -- tab controls themselves can't have tooltips, let it pass through
end

function mui_tabs:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_ButtonClick then
		for i = 1,#self._tabs do
			if self._tabs[ i ]._button == ev.widget then
				selectTab( i )
				break
			end
		end
	end

	return mui_widget.handleEvent( self, ev )
end

return mui_tabs
