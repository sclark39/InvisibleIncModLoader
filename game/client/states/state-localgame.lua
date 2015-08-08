----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local basegame = include( "states/state-game" )
local gameobj = include( "modules/game" )
local serializer = include('modules/serialize')
local serverdefs = include( "modules/serverdefs" )
local mui = include("mui/mui")
local mui_defs = include("mui/mui_defs")
local metrics = include( "metrics" )

----------------------------------------------------------------
--

local localgame = class( basegame )

function localgame:getCamera()
	if self.cameraHandler == nil then
		local camhandler = include( "gameplay/camhandler" )
		self.cameraHandler = camhandler( self.layers["main"], self )
	end

	return self.cameraHandler
end

function localgame:quitToMainMenu()
	statemgr.deactivate( self )
	local stateLoading = include( "states/state-loading" )
	stateLoading:loadFrontEnd()
end

function localgame:onLoad( ... )
	basegame.onLoad( self, ... )
end

function localgame:onUpdate()
	basegame.onUpdate( self )

	if self.simCore:isGameOver() and not self:isReplaying() then
		self:quitToMainMenu()
	end
end

----------------------------------------------------------------

return localgame
