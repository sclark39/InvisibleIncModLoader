----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local unitdefs = include( "sim/unitdefs" )
local simunit = include( "sim/simunit" )
local simdrone = include( "sim/units/simdrone" )
local simcamera = include( "sim/units/simcamera" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )


-----------------------------------------------------
-- Interface functions

local simcameradrone = { ClassType = "simcameradrone" }

function simcameradrone:deactivate( sim )
    -- Don't run simcamera.deactivate, as the drone version doesn't want that behaviour:
    -- KO basically handles loss of sight for this guy.
    simdrone.deactivate( self, sim )
end

function simcameradrone:onDamage( ... )
    simunit.onDamage( self, ... )
end

function simcameradrone:addTrackingInterest( sim, seenUnit )
    local x0, y0 = self:getLocation()
	local x1, y1 = seenUnit:getLocation()
    local evData =
    {
        x = x0, y = y0,
        range = simdefs.SOUND_RANGE_2,
        interest =
        {
            sourceUnit = self,
            x = x1,
            y = y1,
            reason = simdefs.REASON_CAMERA
        },
    }

	sim:triggerEvent( simdefs.TRG_NEW_INTEREST, evData )
end

-----------------------------------------------------
-- Interface functions

local function createCameraDrone( unitData, sim )
	return simunit.createUnit( unitData, sim, simdrone, simcamera, simcameradrone )
end

simfactory.register( createCameraDrone )

return simcameradrone

