-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_texture = require( "mui/widgets/mui_texture" )
require( "class" )

--------------------------------------------------------

local mui_anim = class( mui_widget )

function mui_anim:init( mui, def )
	mui_widget.init( self, def )

	self._cont = mui_texture( mui, def )
	self._buildFile, self._animFile = def.animfile
end

function mui_anim:setAnim( anim )
	self._cont._prop:setCurrentAnim( anim )
end

function mui_anim:setPlayMode( playMode )
	self._cont._prop:setPlayMode( playMode )
end

function mui_anim:setFrame( frame )
	self._cont._prop:setFrame( frame )
end

function mui_anim:getFrameCount(  )
	return self._cont._prop:getFrameCount( )
end

function mui_anim:bindBuild( build )
	if self._buildFile then
		local buildFile = "data/anims/" .. self._buildFile .. ".abld"
		self._cont._prop:unbindBuild( KLEIResourceMgr.GetResource( buildFile ) )
	end

	self._buildFile = build

	if self._buildFile then
		local buildFile = "data/anims/" .. self._buildFile .. ".abld"
		KLEIResourceMgr.LoadResource( buildFile )
		self._cont._prop:bindBuild( KLEIResourceMgr.GetResource( buildFile ) )
	end
end

function mui_anim:bindAnim( build )
	if self._animFile then
		local buildFile = "data/anims/" .. self._animFile .. ".adef"
		self._cont._prop:unbindAnim( KLEIResourceMgr.GetResource( buildFile ) )
	end

	self._animFile = build

	if self._animFile then
		local buildFile = "data/anims/" .. self._animFile .. ".adef"
		KLEIResourceMgr.LoadResource( buildFile )
		self._cont._prop:bindAnim( KLEIResourceMgr.GetResource( buildFile ) )
	end
end

function mui_anim:setColor( r, g, b, a )
	self._cont:setColor( r, g, b, a )
end

function mui_anim:getProp()
	return self._cont._prop
end

function mui_anim:seekLoc( xGoal, yGoal, length, mode )
    local w, h = self:getScreen():getResolution()
    if self._cont._xpx then
        xGoal = xGoal / w
    end
    if self._cont._ypx then
        yGoal = yGoal / h
    end
    
    self._cont:getProp():seekLoc( xGoal, yGoal, 0, length, mode)
end

return mui_anim

