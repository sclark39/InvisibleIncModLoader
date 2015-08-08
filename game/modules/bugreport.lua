----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

-- Table of reported tracebacks; tracked to avoid redundant sends.
-- Consists of <stack-hash> -> <traceback string>
local stackHashes = {}

local function reportTraceback( err )
    local util = include( "modules/util" )
	local stack = debug.traceback( err, 2 )
    local hash = util.hashMd5( stack )

	if hash and not stackHashes[ hash ] then
		local states = statemgr.getStates()
		local game = nil
		for i = 1, #states do
			if states[i].simCore and states[i].levelData then
				game = states[i] -- If it acts like a duck and quacks like a duck...
				break
			end
		end
		stackHashes[ hash ] = stack
		local util = include( "client_util" )
		local msg = string.format( "LUAERR %d--%s\n%s\n%s", util.tcount( stackHashes ), APP_GUID, util.formatGameInfo( game and game.params ), stack )
        if game then
            local simhistory = include( "sim/simhistory" )
            local ok, data = pcall( simhistory.packActions, game.params, game.simHistory )
            if ok and data and #data < 2048 then
                msg = msg.."\n"..data
            end
        end
		cloud.sendSlackTask( msg, config.CRASH_CHANNEL ) --channel )
	end
end

local function printLocals( thread )
    local util = include( "modules/util" )
    local str = { }
    for frame = 1, 3 do
        local info = debug.getinfo( thread, frame )
        if not info then
            break
        end
        if #str > 0 then
            table.insert( str, "\n" )
        end
        table.insert( str, tostring(frame).."] " )

        local k, v = nil, nil
        local i = 1
        repeat
	        k, v = debug.getlocal( thread, frame, i )
	        i = i + 1
            if k then
                if type(v) == "table" then
                    table.insert( str, string.format("%s=%s ", tostring(k), util.debugPrintTable(v, 0, false) ))
                    
                else
                    table.insert( str, string.format("%s=%s ", tostring(k), tostring(v)) )
                end
            end
        until k == nil
    end
    return table.concat( str )
end

return
{
    reportTraceback = reportTraceback,
    printLocals = printLocals,
}