----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local _M = { }

function _M.contains(t, element)
	return t[element]
end

function _M.insert(t, element)
	t[element] = true
end

function _M.erase(t, element)
	t[element] = nil
end

function _M.copy(t1)
	local t = {}
	for k,v in pairs(t1) do
		t[k]=v
	end
	return t
end

function _M.empty(t1)
	for _,_ in pairs(t1) do
		return false
	end
	return true
end

function _M.keys(t1)
	local t = {}
	for k,_ in pairs(t1) do
		table.insert(t, k)
	end
	return t
end

function _M.inplace_union(t1, t2)
	for k,v in pairs(t2) do
		t1[k]=v
	end
end

function _M.union(t1, t2)
	local t = _M.copy(t1)
	_M.inplace_union(t, t2)
	return t
end

function _M.inplace_intersection(t1, t2)
	for k,v in pairs(t1) do
		if not t2[k] then
			t1[k] = nil
		end
	end
end
function _M.intersection(t1, t2)
	local t = {}
	for k,v in pairs(t1) do
		if t2[k] then
			t[k] = v
		end
	end
	return t
end

function _M.inplace_difference(t1, t2)
	for k,v in pairs(t1) do
		if t2[k] then
			t[k] = nil
		end
	end
end

function _M.difference(t1, t2)
	local t = {}
	for k,v in pairs(t1) do
		if not t2[k] then
			t[k]=v
		end
	end
	return t
end

function _M.inplace_symmetric_difference(t1, t2)
	for k,v in pairs(t2) do
		if t1[k] then
			t1[k]=nil
		else
			t1[k]=v
		end
	end
end

function _M.symmetric_difference(t1, t2)
	local t = {}
	for k,v in pairs(t1) do
		if not t2[k] then
			t[k]=v
		end
	end
	for k,v in pairs(t2) do
		if not t1[k] then
			t[k]=v
		end
	end
	return t
end

return _M
