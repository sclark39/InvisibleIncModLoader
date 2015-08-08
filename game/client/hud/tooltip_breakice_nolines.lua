----------------------------------------------------------------
-- Copyright (c) 2015 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local level = include( "sim/level" )
local simdefs = include( "sim/simdefs" )
local tooltip_breakice = include( "hud/tooltip_breakice" )

------------------------------------------------------------------------------
-- Local functions

local breakIceTooltip = class( tooltip_breakice )

function breakIceTooltip:onDraw()

end

return breakIceTooltip