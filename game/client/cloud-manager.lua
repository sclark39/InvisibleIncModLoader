----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

module ( "cloud", package.seeall )
local util = include( "modules/util" )

----------------------------------------------------------------
-- variables
----------------------------------------------------------------
local CLOUD_CLIENT_KEY	= ""
local DEBUG_HTTP = false
local USE_CLIENT_KEY = false

HTTP_OK = 200

--------------------------------------------------------------------
-- global helpers
--------------------------------------------------------------------
function escape ( str )

	str = string.gsub ( str, "([&=+%c])", 
		function ( c )
		  return string.format( "%%%02X", string.byte ( c ))
		end
	)
	
	str = string.gsub ( str, " ", "+" )

	return str
end

----------------------------------------------------------------
function encode ( t )

	local s = ""
	
	for k,v in pairs ( t ) do
		s = s .. "&" .. escape ( k ) .. "=" .. escape ( v )
	end
	
	return string.sub ( s, 2 ) -- remove first '&'
end
--------------------------------------------------------------------
-- local helpers
--------------------------------------------------------------------
local function createTask ()
	
	local task = {}
	
	task.isFinished = false
	
	task.waitFinish = function ( self )
		while ( not self.isFinished ) do
			coroutine.yield ()
		end
		return self.result, self.responseCode
	end
	
	task.callback = function ( self )
		return function ( task, responseCode )
			self.responseCode = responseCode

			if task:getString() then
				self.result = MOAIJsonParser.decode ( task:getString ())
			end

			if responseCode ~= HTTP_OK then
				self.result = self.result or {}
				self.result.msg = self.result.msg or "Unspecified error."
			end
				
			log:write("HTTP %d: %d bytes (%s) ", responseCode, task:getSize(), tostring(self.result and self.result.msg) )
			--log:write("HTTP Received: result %s", util.tostringl(self.result) )

			self.isFinished = true
		end
	end
	
	return task
end

--------------------------------------------------------------------
-- exposed functions
--------------------------------------------------------------------
function createGetTask ( urlExt, data, sync, timeoutSec )
	if not MOAIHttpTask then return end
	local task = createTask ()
	
	if not data then
		data = {}
	end
	
	if USE_CLIENT_KEY then
		data.clientkey = CLOUD_CLIENT_KEY
	end
	
	task.httptask = MOAIHttpTask.new ()
	task.httptask:setCallback ( task:callback ())
	task.httptask:setUserAgent ( "Moai" )
	if timeoutSec then
		task.httptask:setTimeout( timeoutSec )
	end
	
	if DEBUG_HTTP then
		print ( config.CLOUD_URL .. urlExt .. "?" .. encode ( data ))
	end
	
	task.httptask:setUrl ( config.CLOUD_URL .. urlExt .. "?" .. encode ( data ))

	if sync then
		task.httptask:performSync()
	else
		task.httptask:performAsync()
	end

	return task
end

----------------------------------------------------------------

function createPostTask( URL, data )
	assert( MOAIHttpTask and URL and data )

	local task = createTask ()
	task.httptask = MOAIHttpTask.new ()
	task.httptask:setCallback ( task:callback ())

	task.httptask:setUrl ( URL )
	task.httptask:setBody ( data )
	task.httptask:setFailOnError( false )

	task.httptask:performAsync ()
	
	return task
end

function sendSlackTask( msg, channel )
	if not MOAIHttpTask or not config.REPORT_URL or #config.REPORT_URL == 0 then
		return
	end
	local settingsFile = savefiles.getSettings( "settings" )
	if settingsFile.data.suppressMetricsData then
		return -- Metrics are disabled by choice.
	end

	local data =
	{
		text = msg,
		username = "Incognita",
		icon_emoji = ":incognita:",
		channel = channel
	}
	return cloud.createPostTask( config.REPORT_URL, MOAIJsonParser.encode( data ) )
end

function sendMetricTask ( data )
	if not KLEIMetric or not config.METRIC_URL or #config.METRIC_URL == 0 then
		return -- Metrics are disabled.
	end
	local settingsFile = savefiles.getSettings( "settings" )
	if settingsFile.data.suppressMetricsData then
		log:write( "\tMETRICS DISABLED BY USER" )
		return -- Metrics are disabled by choice.
	end

	-- NOTE: config must use 'https' instead of http
	local task = createTask ()
	
	task.httptask = KLEIMetric.new ()
	task.httptask:setCallback ( task:callback ())

	local body = {}
	body.metricData = data
		
	task.httptask:setUrl ( config.METRIC_URL )
	task.httptask:setBody ( MOAIJsonParser.encode ( body ) )
	task.httptask:setFailOnError( false )

	task.httptask:performAsync ()
	
	return task
end

function sendSubscribe( email, bday, country )
	if not KLEIMetric or not config.SIGNUP_URL or #config.SIGNUP_URL == 0 then
		return -- Signups are disabled.
	end

	local task = createTask ()
	
	task.httptask = KLEIMetric.new ()
	task.httptask:setCallback ( task:callback ())

	local body = {}
	body.metricData = { method = "listSubscribe", email_address = email, ["merge_vars[MMERGE1]"] = bday, ["merge_vars[MMERGE2]"] = country }
		
	task.httptask:setUrl ( config.SIGNUP_URL )
	task.httptask:setBody ( MOAIJsonParser.encode ( body ) )
	task.httptask:setFailOnError( false )

	task.httptask:performAsync ()
	
	return task
end
