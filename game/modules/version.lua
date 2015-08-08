----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

----------------------------------------------------------------------------
-- The current version of the client.  To remain compatible with online features,
-- the major and minor version numbers should match what the server requests.
-- Either the minor or major version should change after publishing to the server.
local VERSION = "0.17.6"
local REVISION = "unknown"

local function parseVersion( v )
    if type(v) == "string" then
	    local i, j, major, minor, build = v:find( "([%d]+).([%d]+).([%d]+)" )
	    return tonumber(major or 0), tonumber(minor or 0), tonumber(build or 0)
    end
end

local function isVersionOrHigher( v1, v2 )
    local major1, minor1, build1 = parseVersion( v1 )
    local major2, minor2, build2 = parseVersion( v2 )

    -- Query if v1 >= v2
    if major1 ~= major2 then
        return major1 > major2
    end
    if minor1 ~= minor2 then
        return minor1 > minor2
    end

    return build1 >= build2
end

local function isIncompatible( v )
	local major, minor, build = parseVersion( v or "" )
	local currentMajor, currentMinor, currentBuild = parseVersion( VERSION )

	-- Determine if the version argument is incompatible with VERSION
	return major ~= currentMajor or minor ~= currentMinor
end

local fl = io.open( "build.txt", "r" )
if fl then
    for line in fl:lines() do
        REVISION = line:match( "(%d+)" )
        break
    end
end

return
{
	VERSION = VERSION,
    REVISION = REVISION,
	parseVersion = parseVersion,
    isVersionOrHigher = isVersionOrHigher,
	isIncompatible = isIncompatible,
}
