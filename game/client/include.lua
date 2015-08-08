----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

package.path = string.format("%s/?.lua;%s/client/?.lua;?.lua;", config.SRC_MEDIA, config.SRC_MEDIA )

function include( filename )
	return require(filename)
end

function reinclude( filename )
	if package.loaded[ filename ] and config.DEV then
		log:write( "Reloading: '%s' (from: %s)", filename, config.SRC_MEDIA )
		package.loaded[ filename ] = nil
		local result = require( filename )
		return result
	else
		return require( filename )
	end
end

function simlog( ... )
	log:write( ... )
end
