----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

module ( "logger", package.seeall )

local util = include("modules/util")
local binops = include( "modules/binary_ops" )

----------------------------------------------------------------
-- log functions
----------------------------------------------------------------

local _log = { }

function _log:writep( flag, formatStr, ... )
	if not flag or self:isFlagged(flag) then
		local str = {}
		table.insert(str, "[LUA")
		if flag then
			table.insert(str, "|")
			table.insert(str, string.sub(flag, 5) )
		end
		table.insert(str, "] ")
		table.insert(str, string.format( formatStr, ... ) )
		str = table.concat(str)
		MOAILogMgr.log( str )
		print( str )
	end
end

function _log:write( flag, formatStr, ... )
	if string.sub(flag, 1, 4) == "LOG_" then
		self:writep(flag, formatStr, ... )
	else
		self:writep(nil, flag, formatStr, ... )
	end
end

function _log:setFlag( flag )
	config.LOG_FLAGS[flag] = true
end

function _log:clearFlag( flag )
	config.LOG_FLAGS[flag] = nil
end

function _log:isFlagged( flag )
	return config.LOG_FLAGS[flag] == true
end

function _log:close()
	MOAILogMgr.closeFile()
end

----------------------------------------------------------------
-- public functions
----------------------------------------------------------------

local function openLog()
	MOAILogMgr.setLogLevel( MOAILogMgr.LOG_ERROR )

	local log = util.tcopy( _log )

    local s = { "CONFIG OPTIONS:\n\tAPP_GUID: " ..tostring(APP_GUID) }
    for k, v in pairs(config) do
        table.insert( s, string.format( "\t%s = %s", tostring(k), tostring(v) ))
    end
    log:write( table.concat( s, "\n" ))

	return log
end

return
{
	openLog = openLog,
}
