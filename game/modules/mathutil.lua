----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

----------------------------------------------------------------
-- Returns the roots to a quadratic equation ax^2 + bc + c = 0
--
-- a, b, c => quadratic coefficients
-- returns => nil (no roots)
-- returns => t0, t1 (roots to the quadratic)

local function solveQuadratic( A, B, C )

	local discr = B * B - 4.0 * A * C
	if discr < 0 then
		return nil -- No roots
	end

	local rootDiscr = math.sqrt(discr)
	local q

	if B < 0.0 then
		q = -0.5 * (B - rootDiscr)
	else
		q = -0.5 * (B + rootDiscr)
	end

	local t0, t1 = q / A, C / q

	if t0 > t1 then
		return t1, t0
	else
		return t0, t1
	end
end

-----------------------------------------------------------------
-- Normalizes the parameter into the range [0, 2pi)
--
-- rads => the angle to normalize in radians
-- returns => rads (the normalized angle)

local function normalizeRadians( rads )

	while rads < 0 do
		rads = rads + 2 * math.pi
	end

	while rads >= 2 * math.pi do
		rads = rads - 2 * math.pi
	end
	
	return rads
end

---------------------------------------------------------------------
-- Approach but not overshoot a scalar limit xlim by adding a delta.
-- If the value is already equal to the limit, then no delta is applied.
--
-- x0 => approaching value
-- xlim => the limiting value
-- dx => the delta to approach by, added to x0
-- returns => x1 (the approaching value after the delta has been applied)

local function deltaApproach( x0, xlim, dx )
	if x0 < xlim then
		assert( dx > 0 )
		return math.min( xlim, x0 + dx )
	elseif x0 > xlim then
		assert( dx < 0 )
		return math.max( xlim, x0 + dx )
	else
		return xlim
	end
end

--------------------------------------------------------------------------
-- Rotate a 2D vector <vx, vy> by radians.
--
-- vx, vy => the components of the vector to rotate
-- rads => the angle to rotate by, in radians
-- returns => vx', vy' (the rotated vector)

local function rotateVect2( vx, vy, rads )
	local c = math.cos( rads );
	local s = math.sin( rads );
	local t = vx * c - vy * s;
	
	return (vx * c - vy * s), (vx * s + vy * c)
end

local function normVect2( vx, vy )
	local mag = math.sqrt(vx * vx + vy * vy)
	return vx / mag, vy / mag
end

local function fequals( x1, x2, eps )
	return math.abs( x1 - x2 ) <= (eps or 1e-6)
end

local function dist2d( x0, y0, x1, y1 )
	return math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
end

local function distSqr2d( x0, y0, x1, y1 )
	return (x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)
end

local function distToSegment( x, y, x1, y1, x2, y2 )
	local denom = (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1)
	if denom <= 0 then
		--our line points are the same
		return dist2d( x, y, x1, y1 ), 0
	end

	local nom = (x - x1)*(x2 - x1) + (y - y1)*(y2 - y1)
	local t = math.max(0, math.min(1, nom/denom))
	local px, py = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
	return dist2d( px, py, x, y ), t
end

local function angleDiff( a1, a2 )
	
	local da = a1 - a2

	while da <= -math.pi do
		da = da + 2 * math.pi;
	end

	while da >= math.pi do
		da = da - 2 * math.pi
	end

	return da
end

local function sum( ... )
    local a = 0
    for i = 1, select( '#', ... ) do
        a = a + select( i, ... )
    end
    return a
end

local function lerp( a, b, t )
	if t > 1 then t = 1 end
	return a+(b-a)*t
end

local function inQuad( a, b, t )
	if t > 1 then t = 1 end
	return a+(b-a)*t*t
end

local function outQuad(b, c, t)
	if t > 1 then t = 1 end
	return -c * t * (t - 2) + b
end

-------------------------------------------------------------------------
-- Returns the result of math.atan2 converted to standard angle, where the
-- terminal angle is along the +x axis.
-- eg: <1, 0> is 0, <0, 1> is PI/2, <-1, 0> is PI, <0, -1> is 3PI/2

local function atan2t( x, y )
	local a = math.pi / 2 - math.atan2( x, y )
	if a < 0 then a = a + 2 * math.pi end
	return a
end
--------------------------------------------------------------------------
-- Finds the intersection point between two line segments.  If the segments
-- are colinear, no solution is returned.
--
-- p1x, p1y, p2x, p2y => the coordinates of the first line segment
-- q1x, q1y, q2x, q2y => the coordinates of the second line segment
-- returns => nil (if segments are colinear or non-interescting)
-- returns => t0, t1 (parameters of ntersection for the respective segments)

local function intersectLineLine( p1x, p1y, p2x, p2y, q1x, q1y, q2x, q2y )

	local eps = 0.000001
	local denom = (q2y - q1y) * (p2x - p1x) - (q2x - q1x) * (p2y - p1y)

	-- check parallel
	if denom > eps or denom < -eps then
		local t0 = ((q2x - q1x) * (p1y - q1y) - (q2y - q1y) * (p1x - q1x)) / denom
		if t0 < 0 or t0 > 1.0 then
			return nil
		end

		local t1 = ((p2x - p1x) * (p1y - q1y) - (p2y - p1y) * (p1x - q1x)) / denom
		if t1 < 0 or t1 > 1.0 then
			return nil
		end

		-- intersect.  where?
		return t1 * (q2x - q1x) + q1x, t1 * (q2y - q1y) + q1y
	end
end

local function intersectsCirclePoint( qx, qy, qr, px, py )

	local dx, dy = qx - px, qy - py
	return (dx * dx + dy * dy) < (qr * qr)
end

local function intersectsLineCircle( p1x, p1y, p2x, p2y, qx, qy, qr )

	local dx, dy = p2x - p1x, p2y - p1y

	local a = (dx*dx) + (dy*dy)
	local b = 2 * ((dx)*(p1x-qx) + (dy)*(p1y-qy))
	local c = (qx*qx) + (qy*qy) + (p1x*p1x) + (p1y*p1y) - 2 * (qx*p1x + qy*p1y) - qr*qr

	local t0, t1 = solveQuadratic(a, b, c)
	if t0 then
		local cx, cy = p1x + (p2x - p1x) * t0, p1y + (p2y - p1y) * t0
		return cx, cy
	end
end

return
{
	normalizeRadians = normalizeRadians,
	deltaApproach = deltaApproach,
	rotateVect2 = rotateVect2,
	normVect2 = normVect2,
	fequals = fequals,
	dist2d = dist2d,
	distSqr2d = distSqr2d,
	distToSegment = distToSegment,
	angleDiff = angleDiff,
	atan2t = atan2t,
	intersectLineLine = intersectLineLine,
	intersectsCirclePoint = intersectsCirclePoint,
	intersectsLineCircle = intersectsLineCircle,
    sum = sum,
	lerp = lerp,
	outQuad = outQuad,
	inQuad = inQuad,
}
