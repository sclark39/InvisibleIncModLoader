----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

--
-- Client-side helper functions related to gameplay visualization and rendering.

local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local geo_util = include( "geo_util" )

----------------------------------------------------------------
-- Local functions

local function wait( frames )
	while frames > 0 do
		frames = frames - 1
		coroutine.yield()
	end
end

local function waitForAnim( prop, anim )
	prop:forceUpdate() -- Ensures visible flag is updated; otherwise we will enter the if block but subsequently fail to render (hence infinite loop)
	if prop:shouldDraw() then
		prop:setPlayMode( KLEIAnim.ONCE )
		prop:setCurrentAnim( anim )

		if prop:getFrame() + 1 < prop:getFrameCount() then
			local animDone = false
			prop:setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim, animname )
					animDone = true
				end )

			-- Wait for the end event to be triggered.
			while not animDone do
				coroutine.yield()
			end

			prop:setListener( KLEIAnim.EVENT_ANIM_END, nil )
		end
	end
end

local function throwToLocation(rig, x1, y1)
	local x0, y0 = rig._prop:getLoc()
	if x0 == x1 and y0 == y1 then
		return
	end
	local throwDist = mathutil.dist2d(x0, y0, x1, y1)
	local height = 30
	local segments = 10
	local throwTime = throwDist/400 --todo: make this vary by distance
	local xCurve = MOAIAnimCurve.new()
	local yCurve = MOAIAnimCurve.new()
	local zCurve = MOAIAnimCurve.new()
	xCurve:reserveKeys(segments+1)
	yCurve:reserveKeys(segments+1)
	zCurve:reserveKeys(segments+1)
	local timer = MOAITimer.new()

	timer:setSpan (0, throwTime)
	timer:setMode(MOAITimer.NORMAL)
	timer:start()
	xCurve:setAttrLink(MOAIAnimCurve.ATTR_TIME, timer, MOAITimer.ATTR_TIME)
	yCurve:setAttrLink(MOAIAnimCurve.ATTR_TIME, timer, MOAITimer.ATTR_TIME)
	zCurve:setAttrLink(MOAIAnimCurve.ATTR_TIME, timer, MOAITimer.ATTR_TIME)

	local points = geo_util.generateParabolaPoints(x0, y0, 0, x1, y1, 0, height, segments)
	for i, point in ipairs(points) do
		local t = (i-1)/segments
		xCurve:setKey(i, t*throwTime, point.x, MOAIEaseType.LINEAR)
		yCurve:setKey(i, t*throwTime, point.y, MOAIEaseType.LINEAR)
		zCurve:setKey(i, t*throwTime, point.z, MOAIEaseType.LINEAR)
	end



	rig._prop:setAttrLink(MOAIProp2D.ATTR_X_LOC, xCurve, MOAIAnimCurve.ATTR_VALUE)
	rig._prop:setAttrLink(MOAIProp2D.ATTR_Y_LOC, yCurve, MOAIAnimCurve.ATTR_VALUE)
	rig._prop:setAttrLink(MOAIProp2D.ATTR_Z_LOC, zCurve, MOAIAnimCurve.ATTR_VALUE)

	MOAICoroutine.blockOnAction(timer)

end

local function linearEase(var_name)
    local timer = MOAITimer.new()
    timer:setSpan( 0.5 )
    timer:setMode( MOAITimer.NORMAL )
    timer:start()

    return function( uniforms )
        local var_name = var_name --up value optimization
        local timer = timer --up value optimization
        local t = timer:getTime()
        uniforms:setUniformFloat( var_name, 2*t ) -- 2 * (0 .. 0.5)
    end
end

----------------------------------------------------------------
-- Export table

return
{
	wait = wait,
	waitForAnim = waitForAnim,
	throwToLocation = throwToLocation,
    linearEase = linearEase,
}
