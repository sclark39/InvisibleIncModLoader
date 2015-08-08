----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local _M = {}

function _M.create( x, y, z )
	return setmetatable( { _x=tonumber(x) or 0,_y=tonumber(y) or 0,_z=tonumber(z) or 0,_isVec=true }, { __tostring = function(v) return string.format("{%f,%f,%f}", v._x, v._y, v._z ) end } )
end
function _M.add( v1, v2 )
	assert(v1._isVec and v2._isVec)
	return _M.create( v1._x + v2._x, v1._y + v2._y, v1._z + v2._z )
end
function _M.sub( v1, v2 )
	assert(v1._isVec and v2._isVec)
	return _M.create( v1._x - v2._x, v1._y - v2._y, v1._z - v2._z )
end
function _M.mul( v1, s )
	assert(v1._isVec)
	s = tonumber(s) or 0
	return _M.create( v1._x * s, v1._y * s, v1._z * s )
end
function _M.len( v1 )
	assert(v1._isVec)
	return (v1._x^2 + v1._y^2 + v1._z^2)^0.5
end
function _M.norm( v1 )
	local len = _M.len( v1 )
	len = (len > 0) and len or 1
	return _M.mul( v1, 1/len )
end
function _M.dot( v1, v2 )
	assert(v1._isVec and v2._isVec)
	return v1._x * v2._x + v1._y * v2._y + v1._z * v2._z
end
function _M.cross( v1, v2 )
	assert(v1._isVec and v2._isVec)
	local x = v1._y * v2._z - v1._z * v2._y
	local y = v1._z * v2._x - v1._x * v2._z
	local z = v1._x * v2._y - v1._y * v2._x
	return _m.create( x, y, z )
end
function _M.equal( v1, v2 )
	assert(v1._isVec and v2._isVec)
	return v1._x == v2._x and v1._y == v2._y
end
function _M.unPack( v1 )
	assert(v1._isVec)
	return v1._x, v1._y, v1._z
end
function _M.tostring( v1 )
	assert(v1._isVec)
	return string.format("{%f,%f,%f}", v1._x, v1._y, v1._z)
end

return _M
