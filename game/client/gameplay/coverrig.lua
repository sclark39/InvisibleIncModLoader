----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local animmgr = include( "anim-manager" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local unitrig = include( "gameplay/unitrig" )
include("class")

-------------------------------------------------------------

local coverrig = class()

function coverrig:init( boardRig, owner )
	local simdefs = boardRig:getSim():getDefs()
	self._boardRig = boardRig
	self._owner = owner
	self._HUDcover =
	{
		[simdefs.DIR_E] = boardRig:createHUDProp("kanim_hud_agent_hud", "coverMarker", "E", true, owner ),
		[simdefs.DIR_N] = boardRig:createHUDProp("kanim_hud_agent_hud", "coverMarker", "N", true, owner ),
		[simdefs.DIR_W] = boardRig:createHUDProp("kanim_hud_agent_hud", "coverMarker", "W", false, owner ),
		[simdefs.DIR_S] = boardRig:createHUDProp("kanim_hud_agent_hud", "coverMarker", "S", false, owner ),
	}

	for k,v in pairs(self._HUDcover) do
		v:setVisible( false )
	end
end

function coverrig:destroy()
	local simdefs = self._boardRig:getSim():getDefs()
	for i, dir in ipairs(simdefs.DIR_SIDES) do
		self._owner:removeProp( self._HUDcover[dir] )
	end
end

function coverrig:refresh( x, y )
	local sim = self._boardRig:getSim()
	local simquery = sim:getQuery()
	local simdefs = sim:getDefs()
	local orientation = self._boardRig._game:getCamera():getOrientation()*2
	local cell = x and self._boardRig:getLastKnownCell( x, y )

	for i, dir in ipairs(simdefs.DIR_SIDES) do
		local isCover = false
        if cell and (cell.impass or 0) == 0 then
            isCover = simquery.checkIsCover( sim, cell, simquery.addFacing( dir, orientation ) )
        end
		self._HUDcover[dir]:setVisible( isCover )
	end
end

function coverrig:setLocation( x, y )
	if x and y then
		local simdefs = self._boardRig:getSim():getDefs()
		for i, dir in ipairs(simdefs.DIR_SIDES) do
			local wx, wy = self._boardRig:cellToWorld( x, y )
			self._HUDcover[dir]:setLoc( wx, wy )
		end
	end
end

return
{
	rig = coverrig,
}

