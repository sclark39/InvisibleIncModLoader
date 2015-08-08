local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local level = include( "sim/level" )
local mission_util = include( "sim/missions/mission_util" )

---------------------------------------------------------------------------------------------
-- Default level script for pre-designed levels.

local premade_level = class()

function premade_level:init( scriptMgr )
	local sim = scriptMgr.sim
    local win_conditions = include( "sim/win_conditions" )
	sim:addWinCondition( win_conditions.neverLose )
end

return premade_level
