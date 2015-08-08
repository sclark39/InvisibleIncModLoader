----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )

local SCROLLTEXT_FILES =
{
    string.format( "%s/modules/util.lua", config.SRC_MEDIA ),
    string.format( "%s/modules/mathutil.lua", config.SRC_MEDIA ),
}

local function getFileText( files )
    if #files == 0 then
        return "NO CODE"
    end

	local file = files[math.floor(math.random()*#files)+1]
	local lines = {}
	for line in io.lines( file ) do
		table.insert( lines, line )
		if #lines > 100 then
			break
		end
	end

	return table.concat( lines, "\n" )
end

------------------------------------------------------------------------------
-- Local functions


local panel = class()

function panel:init( bg)

	bg.binder.text1:setText("")
	bg.binder.text2:setText("")
	bg.binder.text3:setText("")
	bg.binder.text4:setText("")
	bg.binder.text5:setText("")

	bg.binder.text1:setLineSpacing( 0.05/72 )
	bg.binder.text2:setLineSpacing( 0.05/72 )
	bg.binder.text3:setLineSpacing( 0.05/72 )
	bg.binder.text4:setLineSpacing( 0.05/72 )
	bg.binder.text5:setLineSpacing( 0.05/72 )

	self._scrollingtextRoutine = MOAICoroutine.new()
	self._scrollingtextRoutine:run( function() 
		local i = 0
		while true do
			
			if i==0 then
				local txt = getFileText( SCROLLTEXT_FILES )
				local num = math.floor(math.random()*5)+1
				bg.binder["text"..num]:spoolText(txt, 100)
			end
			i = i + 1

			if i > 5*cdefs.SECONDS then
				i = 0
			end
			coroutine.yield()
		end
	end )
	
end

function panel:destroy()
	self._scrollingtextRoutine:stop()
end

return
{
	panel = panel
}

