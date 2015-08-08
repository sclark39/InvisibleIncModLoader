--[[
* The MIT License
* Copyright (C) 2011 Derick Dong (derickdong@hotmail.com).  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	FILE: array.lua
	DESCRIPTION: Some utilities functions for dealing with arrays
	AUTHOR: Derick Dong
	VERSION: 0.1
	MOAI VERSION: 0.7
	CREATED: 9-9-11

	UPDATED: 4-27-12
	VERSION: 0.2
	MOAI VERSION: v1.0 r3
]]

local _M = {}

function _M.find(t, element)
	for i, v in ipairs(t) do
		if (v == element) then
			return i
		end
	end
	
	return nil
end

function _M.findIf(t, fn)
	for i, v in ipairs(t) do
		if fn(v) then
			return v, i
		end
	end
	
	return nil
end


function _M.count(t, element)
	local total = 0
	for i, v in ipairs(t) do
		if (v == element) then
			total = total + 1
		end
	end

	return total
end

function _M.slice( t, n0, n1 )
	local t2 = {}
	for i = n0, n1 do
		table.insert( t2, t[i] )
	end
	return t2
end

function _M.concat(t1, t2)
	for i, v in ipairs(t2) do
		t1[#t1 + 1] = v
	end
end

function _M.concatIf(t1, t2, fn)
	for i, v in ipairs(t2) do
		if fn(v) then
			t1[#t1 + 1] = v
		end
	end
	return t1
end

function _M.uniqueMerge( t1, t2 )
    if t2 then
        for i, v in ipairs(t2) do
            if _M.find( t1, v ) == nil then
                table.insert( t1, v )
            end
        end
    end
    return t1
end

function _M.copy(t)
	local t1 = {}
	for k, v in ipairs(t) do
		t1[#t1 + 1] = v
	end

	return t1
end

function _M.reverse(t)
	local temp
	for i = 1, #t * 0.5 do
		temp = t[i]
		t[i] = t[#t - i + 1]
		t[#t - i + 1] = temp
	end
end

function _M.removeElement(t, obj)
	for i, v in ipairs(t) do
		if (obj == v) then
			table.remove(t, i)
			return
		end
	end
end

function _M.removeIf(t, fn)
	local i = 1
	while i <= #t do
		if fn(t[i]) then
			table.remove( t, i )
		else
			i = i + 1
		end
	end
end

function _M.removeAllElements(t, t2)
	for i, v in ipairs(t2) do
		_M.removeElement(t, v)
	end
end

--returns a copy of an array rotated left by 'n' elements
function _M.rotl( tbl, n )
	local N, cpy = #tbl, {}
	n = n % N
	for i=1,N do
		table.insert( cpy, tbl[ (i+n-1)%N+1 ] )
	end
	return cpy
end
--returns a copy of an array rotated right by 'n' elements
function _M.rotr( tbl, n )
	local N, cpy = #tbl, {}
	n = n % N
	for i=1,N do
		table.insert( cpy, tbl[ (i-n-1)%N+1 ] )
	end
	return cpy
end

return _M
