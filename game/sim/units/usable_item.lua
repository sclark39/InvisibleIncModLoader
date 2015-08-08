----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simunit = include( "sim/simunit" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )
local propdefs = include( "sim/unitdefs/propdefs" )

-----------------------------------------------------
-- Local functions

-----------------------------------------------------
-- Interface functions

local function spawnItem( sim, useString )
	local unit = simunit.createUnit( propdefs.item_generic_usable, sim )
    unit:getTraits().useString = useString

    sim:spawnUnit( unit )
    unit:getTraits().trigger = string.format( "used_%d", unit:getID() )

    return unit
end

local radio = { ClassType = "radio" }

function radio:onWarp( sim)
    self:getTraits().trigger = "used_radio"
    self:getTraits().useString = string.format( "<font1_16_sb>%s</>\n%s", STRINGS.ITEMS.RADIO, STRINGS.ITEMS.RADIO_FLAVOR )
	if self:getLocation() then
		sim:addTrigger( "used_radio", self )
	else
		sim:removeTrigger( "used_radio", self )		
	end
end 

function radio:onTrigger( sim, evType, evData )
    local tracker = math.min( simdefs.TRACKER_MAXCOUNT, (self:getTraits().tracker or sim:getTracker()) + simdefs.TRACKER_INCREMENT )
	sim:dispatchEvent( "used_radio", { tracker = tracker } )
    self:getTraits().tracker = tracker
end

simfactory.register( function( unitData, sim ) return simunit.createUnit( unitData, sim, radio ) end )

-----------------------------------------------------
-- Interface functions
return
{
	spawnItem = spawnItem,
}
