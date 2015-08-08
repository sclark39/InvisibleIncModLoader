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
local binops = include( "modules/binary_ops" )
local unitrig = include( "gameplay/unitrig" )
include("class")

-----------------------------------------------------------------------------------
-- Local

local simdefs = nil -- Lazy initialized after the sim is mounted.
local simquery = nil -- Lazy initialized after the sim is mounted.

-------------------------------------------------------------

local idle_state = class( unitrig.base_state )

function idle_state:init( rig )
	unitrig.base_state.init( self, rig, "idle" )
end

function idle_state:onEnter()
	local unit = self._rig:getUnit()
	local state = "idle"
    local hasLootFx = false
    local playUnlocked = false

	if unit:getTraits().open and unit:getTraits().open == true then
		state = "open"
	elseif unit:getTraits().mainframe_status == "off" then
		state = "idle_off"

		if unit:getTraits().moveToDevice then 
			playUnlocked = true
		end
		
		if unit:getTraits().credits or #unit:getChildren() > 0 then
            hasLootFx = true
		end 
	elseif unit:getPlayerOwner() == self._rig._boardRig:getSim():getPC() or unit:getTraits().mainframe_status == "off" then

		if unit:getTraits().moveToDevice then 
			playUnlocked = true
		end

		if unit:getTraits().credits or #unit:getChildren() > 0 then 
            hasLootFx = true
		end 

	end

	if playUnlocked and not self._hasPlayedUnlock then
        --also fly txt... omg players pls notice me!!!
		local x0,y0 = unit:getLocation()
		local txt = STRINGS.UI.FLY_TXT.UNLOCKED
		local color = {r=1,g=1,b=41/255,a=1}
		self._rig._boardRig:showFloatText( x0, y0, txt, color, nil , true)		
		self._hasPlayedUnlock = true
	end

    local fxmgr = self._rig._boardRig._game.fxmgr
	if hasLootFx and not self._lootIcon then
		local x0, y0 = self._rig._boardRig:cellToWorld(unit:getLocation() )
        self._lootIcon = fxmgr:addAnimFx( { kanim="fx/safe_money_icon", symbol="character", anim="idle", x=x0, y=y0, loop=true } )

    elseif not hasLootFx and self._lootIcon then 
        fxmgr:removeFx( self._lootIcon )
        self._lootIcon = nil
	end 

	self._rig:setCurrentAnim( state )
end

local corerig = class( unitrig.rig )

function corerig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )

	simdefs = boardRig:getSim():getDefs()
	simquery = boardRig:getSim():getQuery()

	self._idleState = idle_state( self )
	self:transitionUnitState( self._idleState )

	self._prop:setSymbolVisibility( "glow", "red", false )		
end

function corerig:onSimEvent( ev, eventType, eventData )
	self:_base().onSimEvent( self, ev, eventType, eventData )
end

function corerig:refresh()
	self:transitionUnitState( nil )
	self:transitionUnitState( self._idleState )
	self:_base().refresh( self )

	self:refreshSpotSound()

	local unit = self._boardRig:getLastKnownUnit( self._unitID )
	local playerOwner = unit:getPlayerOwner()

	local artifact = false
	for i,childunit in ipairs (unit:getChildren()) do
		if childunit:getTraits().artifact then
			artifact = true
		end
	end
	self._prop:setSymbolVisibility( "loot", artifact )

	if unit:getTraits().mainframe_status == "off" then
		if self._HUDIce then
			self._HUDIce:setVisible(false)
		end

		self._prop:setSymbolVisibility( "red", "internal_red", "ambientfx", "teal", false )
	else
		if playerOwner == nil or playerOwner:isNPC() then		
			self._prop:setSymbolVisibility( "red", true )
			self._prop:setSymbolVisibility( "teal", false )
		else
			self._prop:setSymbolVisibility( "red", false )
			self._prop:setSymbolVisibility( "teal", true )
		end	
	end	
end

return
{
	rig = corerig,
}

