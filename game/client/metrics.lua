----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

include("class" )
local util = include( "modules/util" )

local MIN_IDLE_DELTA = 10 -- In seconds.

----------------------------------------------------------------
-- Base metrics class.

local base_metrics = class()

function base_metrics:init()
	self.stats = {}
end

function base_metrics:incStat( stat )
	self.stats[ stat ] = (self.stats[ stat ] or 0) + 1
end

function base_metrics:setStat( stat, value )
	self.stats[ stat ] = value
end

function base_metrics:send( ... )
	local user = savefiles.getCurrentGame()
	local userName = MOAIEnvironment.UserID
	local data =
	{
		user = userName,
		branch = MOAIEnvironment.Build_Branch,
		version = MOAIEnvironment.Build_Version,
		app_guid = APP_GUID,
	}

	self:onSend( data, user, ... )

	log:write( util.tostringl(data) )
	return cloud.sendMetricTask ( data )
end

----------------------------------------------------------------
-- Metrics for completing a level (independent of session).

local level_finished = class( base_metrics )

function level_finished:init()
	base_metrics.init( self )
end

function level_finished:onSend( data, user, params, num_actions, sim )
	log:write( " ### Sending level_finished..." )

	data.event = "level_finished"

	local result
	if sim:getWinner() then
		result = "win"
	elseif sim:isGameOver() then
		result = "lose"
	else
		result = "incomplete"
	end

	data.game_stats = util.extend( sim:getStats() )
	{
		credits = sim:getPC():getCredits(),
		num_actions = num_actions,
		num_turns = math.floor( sim:getTurnCount() / 2 ),
		result = result,
		play_t = sim.playTime
	}

	-- Don't bother including certain values for 'tutorial' levels.
	if params.world ~= nil then
		local agency = params.agency
		data.game_params =
		{
			game_number = user.data.num_games,
			seed = params.seed,
			progress = params.campaignHours,
			difficulty = params.difficulty,
			campaignDifficulty = params.campaignDifficulty,
			missionCount = params.missionCount,
			situationName = params.situationName,
			agency =
			{
				-- Note that at this point, agency does NOT have the updated stats from post-game
				agents = {},
			},
			location = params.location,
			world = params.world,
		}
		for i, agentDef in pairs( agency.unitDefs ) do
			table.insert( data.game_params.agency.agents, agentDef.template )
		end
	end
end

--------------------------------------------------------------------------------
-- App-level metrics, tracks stats for the duration of the application's launch.
-- This class has a lifetime that spans the duration of the process.

local app_metrics = class( base_metrics )

function app_metrics:init()
	base_metrics.init( self )
	self.startTime, self.idleTime, self.lastActivityTime = os.time(), 0, nil
end

function app_metrics:trackActivity()
	local now = os.time()
	local idleDelta = now - (self.lastActivityTime or now)
	if idleDelta > MIN_IDLE_DELTA then
		self.idleTime = self.idleTime + idleDelta
	end
	self.lastActivityTime = now
end

function app_metrics:sendLaunch()
	return self:send( "launch" )
end

function app_metrics:sendQuit()
	return self:send( "quit" )
end

function app_metrics:onSend( data, user, event )
	log:write( " ### Sending app_metrics (%s)...", event )

	data.event = event

	if event == "quit" then
		data.play_t = os.time() - self.startTime
		data.idle_t = self.idleTime
		util.tmerge( data, self.stats )
	elseif event == "launch" then
		data.os = MOAIEnvironment.OS
		data.os_version = MOAIEnvironment.OS_Version
		data.os_build = MOAIEnvironment.OS_Build
	end
end

----------------------------------------------------------------
-- Metrics interface classes.

return
{
	level_finished = level_finished,
	app_metrics = app_metrics(), -- Instantiate app-level metrics.
}
