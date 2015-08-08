----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local serverdefs = include( "modules/serverdefs" )
local array = include( "modules/array" )
local util = include("client_util")
local rand = include( "modules/rand" )
local simdefs = include("sim/simdefs")


----------------------------------------------------------------
-- Parameters to sim construction.  All input that derives a unique
-- simulation should be encapsulated in this table.

local function createCampaign( campaignData )
	assert( campaignData )

	local situationData = serverdefs.SITUATIONS[ campaignData.situation.name ]
	assert( situationData, campaignData.situation.name )
	local corpData = serverdefs.getCorpData( campaignData.situation )	

	local params =
	{
		-- The level file to load.  If loading pre-designed level, this specifies that level.  Otherwise,
		-- this should specify 'lvl_procgen' for procedurally generated levels.
		levelFile = situationData.levelFile or "lvl_procgen",
		difficulty = math.max( 1, campaignData.situation.difficulty ),
        campaignDifficulty = campaignData.campaignDifficulty,
        difficultyOptions = util.tcopy( campaignData.difficultyOptions ),
		campaignHours = serverdefs.calculateCurrentHours( campaignData ),
		missionCount = campaignData.missionCount,
        miniserversSeen = campaignData.miniserversSeen,
		endlessAlert = campaignData.endlessAlert,
		music = corpData.music,
		world = corpData.world,
		-- Mainly for metrics.
		situationName = campaignData.situation.name,
		-- Mission scripts
		scripts = situationData.scripts,
		scriptPath = situationData.scriptPath,
        tags = util.tcopy( campaignData.tags or {} ),
		-- Players table.  Kind of weird cause we're SP now, but ....
        agency = campaignData.agency,
		-- The initial rand seed.  This seed informs all random parameters.
		seed = campaignData.seed,
        missionVersion = campaignData.missionVersion,
		foundPrisoner = campaignData.foundPrisoner,
		agentsFound = campaignData.agentsFound,
		--advancedAlarm = campaignData.advancedAlarm,
		missionEvents = campaignData.missionEvents
	}

    if serverdefs.isTimeAttackMode( campaignData ) then
        params.chessTimer = campaignData.chessTimer or 0
        params.chessTimeTotal = campaignData.chessTimeTotal or 0
    end

    return params
end


local function createParams( levelFile )
	-- This match string is derived from the output of client_util.formatGameInfo.
	local missionVersion, difficulty, campaignDifficulty, missionCount, miniserversSeen, situationName, corpName, seed =
        levelFile:match( "GAME [[]([^]]+)[]][.](%d)[.](%d)[.](%d[.])(%d[.])([_%w]+)[.]([_%w]+)[.](%d+)$" )

	if seed == nil then
		-- Create params for a pre-designed level.  Most campaign parameters are not necessary.
		return
		{
			levelFile = levelFile,
			seed = config.LOCALSEED(),
            difficultyOptions = util.tcopy( simdefs.DIFFICULTY_OPTIONS[ simdefs.NORMAL_DIFFICULTY ] ),
            agency = serverdefs.createAgency(),
            scripts = { "premade_level" }
		}

	else	
		local situationData = serverdefs.SITUATIONS[ situationName ]
		local corpData = serverdefs.CORP_DATA[ corpName ]
		return
		{
			-- The level file to load.  If loading pre-designed level, this specifies that level.  Otherwise,
			-- this should specify 'lvl_procgen' for procedurally generated levels.
			levelFile = situationData.levelFile or "lvl_procgen",
			difficulty = tonumber(difficulty),
            campaignDifficulty = tonumber(campaignDifficulty),
            difficultyOptions = util.tcopy( simdefs.DIFFICULTY_OPTIONS[ tonumber(campaignDifficulty) ] ),
			campaignHours = nil, -- Not an actual campaign
            miniserversSeen = miniserversSeen,
			missionCount = missionCount, -- Not an actual campaign
			music = corpData.music,
			world = corpData.world,
			situationName = situationName,
			-- Mission scripts
			scripts = situationData.scripts,		
			-- Players table.  Kind of weird cause we're SP now, but ....
            agency = serverdefs.createAgency(),
			-- The initial rand seed.  This seed informs all random parameters.
			seed = tonumber(seed),
            missionVersion = missionVersion,
		}
	end
end

return
{
	createCampaign = createCampaign,
	createParams = createParams,
}
