----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local animmgr = include( "anim-manager" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local util = include( "client_util" )
local array = include( "modules/array" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local unitrig = include( "gameplay/unitrig" )

-----------------------------------------------------------------------------------
-- Helper functions

local function createSmokeFx( rig, kanim, x, y )
   	local fxmgr = rig._boardRig._game.fxmgr
	x, y = rig._boardRig:cellToWorld( x, y )

    local args =
	{
		x = x,
		y = y,
		kanim = kanim,
		symbol = "effect",
		anim = "loop",
        scale = 0.1,
        loop = true,
        layer = rig._boardRig:getLayer()
	}
    
    return fxmgr:addAnimFx( args )
end

-----------------------------------------------------------------------------------
-- Manages smoke FX for a smoke cloud.

local smokerig = class( unitrig.rig )

function smokerig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )
    self.smokeFx = {}
end

function smokerig:destroy()
    for _, fx in pairs(self.smokeFx) do
        fx:postLoop( "pst" )
    end
    self.smokeFx = nil
end

function smokerig:onSimEvent( ev, eventType, eventData )
	-- Handle sim events if the rig state does not.
    if eventType == simdefs.EV_UNIT_WARPED then
        self:refresh()
    else
        self:_base().onSimEvent( self, ev, eventType, eventData )
    end
end

function smokerig:refresh()
	self:_base().refresh( self )

    -- Smoke aint got no ghosting behaviour.
    local unit = self:getUnit()
    local cells = unit:getSmokeCells() or {}
    for i, cell in ipairs(cells) do
        if self.smokeFx[ cell ] == nil then
            local fx = createSmokeFx( self, "fx/smoke_grenade", cell.x, cell.y )
            fx._prop:setFrame( math.random( 1, fx._prop:getFrameCount() ))
            self.smokeFx[ cell ] = fx
            if self:getUnit():getTraits().gasColor then
                local color = self:getUnit():getTraits().gasColor
                fx._prop:setColor(color.r,color.g,color.b,1)
                fx._prop:setSymbolModulate("smoke_particles_lt0",color.r,color.g,color.b,1)
            end
        end
    end
    local edgeUnits = unit:getSmokeEdge() or {}
    for i, unitID in ipairs(edgeUnits) do
        if self.smokeFx[ unitID ] == nil then
            local fx = createSmokeFx( self, "fx/smoke_grenade_test2", self._boardRig:getSim():getUnit( unitID ):getLocation() )
            fx._prop:setFrame( math.random( 1, fx._prop:getFrameCount() ) )
            self.smokeFx[ unitID ] = fx
            if self:getUnit():getTraits().gasColor then
                local color = self:getUnit():getTraits().gasColor
                fx._prop:setColor(color.r,color.g,color.b,1)
                fx._prop:setSymbolModulate("smoke_particles_lt0",color.r,color.g,color.b,1)
            end            
        end
    end

    -- Remove any smoke that no longer exists.
    for k, fx in pairs(self.smokeFx) do
        if array.find( cells, k ) == nil and array.find( edgeUnits, k ) == nil then
            fx:postLoop( "pst" )
        end
    end

    local gfxOptions = self._boardRig._game:getGfxOptions()
    for cell, fx in pairs(self.smokeFx) do
        fx._prop:setVisible( not gfxOptions.bMainframeMode )
    end
    
    
end


local function createRig( boardRig, unit )
    if not unit:isGhost() then
        return smokerig( boardRig, unit )
    end
end

return
{
	rig = smokerig,
    createRig = createRig
}

