----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local binops = include("modules/binary_ops")
local color = include("modules/color")
local weighted_list = include( "modules/weighted_list" )
local strictify = include( "strict" )

local g_lastYieldTick  = 0

----------------------------------------------------------------

local function indexOf( t, val )
	assert( type(t) == "table" )

	for k,v in pairs(t) do
		if v == val then
			return k
		end
	end
	
	return nil
end

local function indexPairs( t, idx )
	assert( type(t) == "table" )

	for k,v in pairs(t) do
		if idx == 1 then
			return k,v
		else
			idx = idx - 1
		end
	end
end

local function tkeys( t )
	local keys = {}
	for k,v in pairs(t) do
		table.insert( keys, k )
	end
	return keys
end

local function tnext( t, fn )
	local idx = 1
	local function iter()
		local v = t[idx]
		while v do
			idx = idx + 1
			if fn( v ) then
				return v
			end
			v = t[idx]
		end
	end

	return iter
end

local function terase( t, val )
	assert( type(t) == "table" )

	for k,v in pairs(t) do
		if v == val then
			t[k] = nil
			return
		end
	end
end

local function tclear( t )
	local k, v = next(t)
	while k do
		t[k] = nil
		k, v = next(t)
	end
end

local function tcount( t )
	assert( type(t) == "table" )

	local count = 0
	for k,v in pairs(t) do
		if v ~= nil then
			count = count + 1
		end
	end
	
	return count
end

local function tempty( t )
	return next(t) == nil
end

local function toupper(s)
    return lua_utf8.upper( s )
end


local function tolower(s)	
    return lua_utf8.lower( s )
end

-- Similar to string.format, this is meant to be used for localization so that the arguments can
-- supplied in constant order, but placed in the string based on the numeric indices.  Works like this:
-- util.sformat( "Argument {2} comes first, then comes {1}.", "blue", 5.0 )
-- results in: "Argument 5.0 comes first, then comes blue."
-- Format specifiers can also be "selectors", which allow an argument to index which string should be selected:
-- util.sformat( "Jason ran, and {1:he|she} fell over and hurt {1:him|her}self.", 1 )
-- results in: "Jason ran, and he fell over and hurt himself."
-- Plural forms can also be denoted this way:
-- util.sformat( "{1} picked up {2} {2:apple|apples}", "John", 1 )
-- results in: "John picked up 1 apple."

local function consume_token( str )
	local i, j, w, rest = str:find( "^([^|}]+)[|}]?(.*)" )
	return w, rest
end

local function sformat( format, ... )
    local loc_translator = include( "loc_translator" )
    if type(format) == "table" then
        format = table.concat( format )
    end
	for i = 1, select("#", ...) do
		local v = select(i, ... )
		local j, k, options
		repeat
			j, k, options = format:find( "{"..i..":([^}]+)}" )
			if options then
                local pluralForm = loc_translator.convertPlurality( v )
				local option
				for n = 1, pluralForm do
					option, options = consume_token( options )
					if not option then break end
				end
				format = format:sub( 1, j - 1 ) .. tostring(option) .. format:sub( k + 1 )

			else
				format, j = format:gsub( "{"..i.."}", tostring(v) )
			end
		until j == 0
	end
	return format
end

local function stringize( t, maxRecurse, tlist, indent )

	if indent == nil then indent = 0 end
	maxRecurse = maxRecurse or -1

	if type(t) == "table" and maxRecurse ~= 0 then
		local s = tostring(t) .. "\n" .. string.rep(" ", indent) .. "{\n"
		indent = indent + 4
		for k,v in pairs(t) do
			if tlist == nil or indexOf(tlist, v) == nil then
				if tlist == nil then tlist = {} end
				tlist[#tlist + 1] = v
				s = s .. string.rep(" ", indent) .. tostring(k) .." = " ..stringize(v, maxRecurse - 1, tlist, indent) ..",\n"
			else
				s = s .. string.rep(" ", indent) .. tostring(k) .." = " ..tostring(v) .. ",\n"
			end
		end
		indent = indent - 4
		s = s .. string.rep(" ", indent) .. "}"
		return s
	else
		return tostring(t)
	end
end

local function tostringl( t, maxRecurse )

	maxRecurse = maxRecurse or 3

	if type(t) == "table" and maxRecurse ~= 0 then
		local s = "{ "
		local c = ""
		for k,v in pairs(t) do
			if type(v) ~= "function" then
				if type(k) == "number" then
					s = s .. c .. tostringl( v, maxRecurse - 1 )
				else
					s = s .. c .. tostring(k) .." = " ..tostringl( v, maxRecurse - 1 )
				end
				c = ", "
			end
		end
		s = s .. " }"
		return s
	else
		return tostring(t)
	end
end

-- returns a shallow copy of the table parameter
local function tdupe( tt )
	local dupe = {}
	for k,v in pairs( tt ) do
		dupe[k] = v
	end
	return dupe
end

-- returns a deep copy of the table parameter
local function tcopy( tt )

	local copy = {}

	for k,v in pairs( tt ) do
		if( type(v) == "table" ) then
			copy[k] = tcopy( v )
		else
			copy[k] = v
		end
	end

	return setmetatable( copy, getmetatable( tt ))
end

-- concatenates fields (deep copy) of several tables together
local function tconcat(... )
	local result = {}
	for _,t in ipairs( arg ) do
		for k,v in pairs( t ) do
			if type(v) == "table" then
				v = tcopy( v )
			end
			if type(k) == "number" then
				table.insert( result, v )
			else
				result[ k ] = v
			end
		end
	end
	return result
end

-- concatenates fields (shallow copy) of t2...tn to t1
local function tmerge( t1, ... )
	for _, t2 in ipairs( arg ) do
		for k,v in pairs( t2 ) do
			if type(k) == "number" then
				table.insert( t1, v )
			else
				t1[k] = v
			end
		end
	end

	return t1
end

-- moves all fields (shallow copy) from t2 to t1
local function tmove( t1, t2 )
	local k, v = next(t2)
	while k do
		t1[k], t2[k] = v, nil
		k, v = next(t2)
	end

	return t1
end

local function tjoin( ... )
	local input = {...}
	local output = {}
	for _,t in pairs(input) do
		assert( type(t) == "table" )
		for k,v in pairs(t) do
			output[k] = v
		end
	end
	return output
end

-- executes functions for each element in two sets
local function tdiff( t1, t2, f1, f2, fUnion )
	for _, v in pairs(t1) do
		if f1 and indexOf( t2, v ) == nil then
			f1( v )
		end
	end

	for _, v in pairs(t2) do
		if f2 and indexOf( t1, v ) == nil then
			f2( v )
		elseif fUnion then
			fUnion( v )
		end
	end
end

local function tequal( t1, t2 )
    for k, v in pairs(t1) do
        if t2[k] ~= v then
            return false
        end
    end
    for k, v in pairs(t2) do
        if t1[k] ~= v then
            return false
        end
    end
    return true
end

-- Determine whether a predicate holds for all table elements.
local function allValues( t, pred )
	for k,v in pairs(t) do
		if not pred(k, v) then
			return false
		end
	end

	return true
end

-- Determine whether a predicate holds for any table element.
local function anyValues( t, pred )
	for k,v in pairs(t) do
		if pred(k, v) then
			return true
		end
	end

	return false
end

local function tprint( t, prepend )
	for k,v in pairs( t ) do
		if prepend then
			print( prepend, k, v )
		else
			print( k, v )
		end
	end
end

local function tlog( t, prepend )
	for k,v in pairs( t ) do
		if type(v) == "table" then
			tlog(v, tostring(prepend)..tostring(k).." = ")
		else
			if prepend then
				log:write("%s\t%s\t%s", tostring(prepend), tostring(k), tostring(v) )
			else
				log:write("%s\t%s", tostring(k), tostring(v) )
			end
		end
	end
end

local function prototypeInit( prototypeTable )
	setmetatable( prototypeTable, nil )
	local t = tcopy( prototypeTable )
	setmetatable( prototypeTable,
		{
			__index = function( t, k )
				assert(false, "Accessing read-only prototype table for key '"..tostring(k).."'") 
			end,

			__newindex = function( t, k, v )
				assert(false, "Accessing read-only prototype table for key '"..tostring(k).."'") 
			end
		} )
	return t
end

-- "inherits" a table.
local function inherit( tbase )

	return function( t )
		tbase.__index = tbase
		return setmetatable( t, tbase )
	end
end

-- "extends" a table.  Recursively copies all elements of tbase into an overrides table
-- Usage: t = extend( tbase ) { a = "override", c = { "override" } }

local function extend( ... )
	local function tcopy( t1, t2 )
		assert( type(t1) == "table" and type(t2) == "table", string.format("type(t1) == %s, type(t2) == %s", type(t1), type(t2)) )
		-- Deep-merge all of t1 into t2
		for k,v in pairs( t1 ) do
			if type(v) == "table" then
				if t2[k] == nil then
					t2[k] = tcopy( v, {} )
				elseif not t2[k]._OVERRIDE then
					tcopy( v, t2[k] )
				end
			else
				if t2[k] == nil then
					t2[k] = v
				else
					assert( type(t2[k]) == type(v), tostring(k) )
				end
			end
		end
			
		return t2
	end
	local tbases = { ... }
	
	return function( t )
		for _, tbase in ipairs( tbases ) do
			t = tcopy( tbase, t or {} )
		end
		return t
	end
end

-- performs a binary search on a sorted array (t), returning an index range where the value is located
-- t : a table with numeric indices where the elements follow a total orderering
-- v : the value to search.  elements are compared with the < or > operator, unless the comparator function is passed
-- fn : a comparator function that compares two values, returning < 0, 0, or > 0 respectively if the left parameter is ordered before the right

local function defaultfn( lhs, rhs )
	if lhs == rhs then
		return 0
	elseif lhs < rhs then
		return -1
	else
		return 1
	end
end

local function binarySearch( t, v, fn )
	
	if fn == nil then
		fn = defaultfn
	end

	local a, b, mid = 1, #t, 0

	while a <= b do
		-- calculate mid
		mid = math.floor((a + b)/2)

		-- compare elements
		local cmp = fn( t[mid], v )
		if cmp < 0 then -- t[mid] < v, search above mid
			a = mid + 1
		elseif cmp > 0 then -- t[mid] > v, search below mid
			b = mid - 1
		else -- equal values
			local l, r = mid, mid + 1

			while l > 1 and fn(t[l - 1], v) == 0 do
				l = l - 1
			end

			while r < #t and fn(t[r], v) == 0 do
				r = r + 1
			end

			return l,r
		end
	end

	return a,a
end

local function accum( t, fn, n )
	local sum = n or 0
	for k, v in pairs(t) do
		sum = sum + fn(k, v)
	end
	return sum
end

local function shuffle( t, randfn )
	-- Modern version of the Fisher-Yates shuffling algorithm.
    local iterations = #t
    local j
    for i = iterations, 2, -1 do
        j = (randfn or math.random)(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function formatTime( secs )
	local hours = math.floor( secs / 3600 )
	secs = secs - hours * 3600
	local mins = math.floor( secs / 60 )
	secs = secs - mins * 60

	return string.format( "%d : %02d : %02d", hours, mins, secs )
end

local function makeDelegate( obj, fn, ... )
	return { _obj = obj, _fn = fn, ... }
end

local function sleep( secs )
	-- Busy wait.
	local t0 = os.clock()
	while os.clock() - t0 <= secs do end
end

local function timeYield( dt )
	local now = os.clock()
	if now - g_lastYieldTick > (dt or (1/30)) then
		--[[
		if now - g_lastYieldTick > 0.1 then
			print( "YO!... That took a while.. ", now - g_lastYieldTick, " sec.")
			print(debug.traceback())
		end
		--]]

		g_lastYieldTick = now
		coroutine.yield()
	end
end

local function fullGC()
	local st = MOAISim.getDeviceTime()
	local preBytes = collectgarbage("count")
	collectgarbage()
	local tt = MOAISim.getDeviceTime()
	local postBytes = collectgarbage("count")

	log:write("fullGC(): Took %.1f ms for %d KB", (tt - st) * 1000, preBytes - postBytes )
end

local function discreteSpiral( n )
	-- Returns discrete coordinates in an outward spiral from the origin.
	-- Some values for i are: { 1 -> (1, 1), 2 -> (1, 0), 9 -> (2, 2) ... }
	local r = math.floor(math.ceil(math.sqrt(n+1)) / 2)
	if r == 0 then
		return 0, 0
	end
	local n1, n2 = ((2 * r) - 1) * ((2 * r) -1), ((2 * r) + 1) * ((2 * r) + 1)
	local dn = n - n1
	local d4 = (n2 - n1) / 4
	local dt = math.mod( dn / d4, 1.0 )
	
	local dx, dy
	if dn < d4 then
		dx, dy = r, math.floor(r * (1-dt) - r * dt + 0.5)
	elseif dn < 2 * d4 then
		dx, dy = math.floor(r * (1-dt) - r * dt + 0.5), -r
	elseif dn < 3 * d4 then
		dx, dy = -r, math.floor(r * dt - r * (1-dt) + 0.5)
	else
		dx, dy = math.floor( r * (dt) - r * (1-dt) + 0.5 ), r
	end
	
	return dx, dy
end

local function xypairsIterator( state, i )
	i = i + 1
	if state.t[i] == nil then
		return nil
	elseif type(state.t[i]) == "table" then
		return i, state.t[i].x, state.t[i].y
	elseif state.t[i * 2 - 1] == nil then
		return nil
	else
		return i, state.t[i * 2 - 1], state.t[i * 2]
	end
end

local function xypairs( t, i )
	return xypairsIterator, { t = t, i = i or 0 }, i or 0
end

--Iterates over a table after sorting it by key
local function pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
		table.sort(a, f)
		local i = 0      -- iterator variable
		local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

local function hashMd5( str )
    local stream = MOAIMemStream.new ()
	stream:open()
	stream:write( str )

	local hashWriter = MOAIHashWriter.new()
	hashWriter:openMD5( stream )
	local hash = hashWriter:close()
	stream:close()

    return hash
end

local function callDelegate( delegate, ...)
	if type( delegate ) == "function" then
		return delegate( ... )
	end

	local t = {}
	for k,v in pairs(delegate) do
		if type(k) == "number" then
			t[k] = v
		end
	end
	local n = #t
	for k,v in pairs({...}) do
		t[k + n] = v
	end
		
	if delegate._obj then
		assert(delegate._obj[delegate._fn], tostring(delegate._obj) .. " doesn't have function " ..tostring(delegate._fn))
		return delegate._obj[delegate._fn]( delegate._obj, unpack(t, 1, table.maxn(t)) )
	else
		return delegate._fn( unpack(t, 1, table.maxn(t)) )
	end
end


local function coDelegate( delegate, ... )
	local thread = MOAICoroutine.new()
	thread:run( callDelegate, delegate, ... )
	thread:resume()
end

local function toRGBA( n )
	local r = binops.shiftr(n, 24)
	local g = binops.b_and( binops.shiftr(n, 16), 0x000000FF )
	local b = binops.b_and( binops.shiftr(n, 8), 0x000000FF )
	local a = binops.b_and( binops.shiftr(n, 0), 0x000000FF )

	-- Return as float components.
	return r / 255, g / 255, b / 255, a / 255
end

local function stringizeRGBA( r, g, b, a )
	return string.format("%02X", r or 1 ) .. string.format("%02X", g or 1 ) .. string.format("%02X", b or 1 ) .. string.format("%02X", a or 1 )
end

local function stringizeRGBFloat(r, g, b)
	return string.format("%02X", 256*r or 0 ) .. string.format("%02X", 256*g or 0 ) .. string.format("%02X", 256*b or 0 )
end

local function addTableToMemstring(tab, memstring, maxDepth, depth, colours)
	if not tab or type(tab) ~= "table" then
		table.insert(memstring, tostring(tab) )
		return
	end

	if tab.getID then	--for units
		table.insert(memstring, "[" )
		if tab.isValid and tab:isValid() then
			table.insert(memstring, tab:getID() )
		elseif tab.isPC and tab:isPC() then
			table.insert(memstring, "PC Player")
		elseif tab.isNPC and tab:isNPC() then
			table.insert(memstring, "AI Player")
		else
			table.insert(memstring, tab.getName and tab:getName() or "UNKNOWN" )
			table.insert(memstring, "(limbo)")
		end
		table.insert(memstring, "]" )
	elseif tab.roomIndex then	--for rooms
		table.insert(memstring, "[Room:" )
		table.insert(memstring, tostring(tab.roomIndex)  )
		table.insert(memstring, "]" )
	elseif tab.x and tab.y and tab.exits then --cells
		table.insert(memstring, "[Cell(")
		table.insert(memstring, tostring(tab.x)  )
		table.insert(memstring, "," )
		table.insert(memstring, tostring(tab.y)  )
		table.insert(memstring, ")]" )
	elseif tab.location and tab.t then --nodes
		table.insert(memstring, "[Node(")
		table.insert(memstring, tostring(tab.location.x)  )
		table.insert(memstring, "," )
		table.insert(memstring, tostring(tab.location.y)  )
		table.insert(memstring, ",t=" )
		table.insert(memstring, tostring(tab.t)  )
		table.insert(memstring, ")]" )
	elseif depth > maxDepth then
		table.insert(memstring, tostring(tab))
	else
		table.insert(memstring, "{" )
		local entryCount = 1
		for k, v in pairsByKeys(tab) do
			if string.sub(k, 1, 1) ~= "_" and type(v) ~= "function" then
				if entryCount > 1 then 
					table.insert(memstring, ", " )
				end
				if colours and colours[depth] then
					table.insert(memstring, "<c:")
					if colours[depth].keys_alt and entryCount % 2 == 0 then
						table.insert(memstring, colours[depth].keys_alt)
					else
						table.insert(memstring, colours[depth].keys)
					end
					table.insert(memstring, ">")
				end
				table.insert(memstring, tostring(k))
				if colours and colours[depth] then
					table.insert(memstring, "</>" )
				end
				table.insert(memstring, "=" )
				if colours and colours[depth] then
					table.insert(memstring, "<c:")
					if colours[depth].vals_alt and entryCount % 2 == 0 then
						table.insert(memstring, colours[depth].vals_alt)
					else
						table.insert(memstring, colours[depth].vals)
					end
					table.insert(memstring, ">")
				end
				if type(v) == "table" then
					addTableToMemstring(v, memstring, maxDepth, depth+1, colours)
				else
					local simdefs = include( "sim/simdefs" )
					if simdefs then
						if k == "dir" then
							v = simdefs:stringForDir(v) or v
						elseif k == "eventType" then
							v = simdefs:stringForDir(v) or v
						end
					end
					table.insert(memstring, tostring(v) )
				end
				if colours and colours[depth] then
					table.insert(memstring, "</>" )
				end
			end
			entryCount = entryCount + 1
		end
		table.insert(memstring, "}" )
	end
end

local defaultColours = 
{
	{keys="FF7700", vals="0077FF", keys_alt="FF5500", vals_alt="0055FF"},
	{keys="FFAA00", vals="00AAFF", keys_alt="FF8800", vals_alt="0088FF"},
	{keys="FFFF00", vals="00FFFF", keys_alt="FFDD00", vals_alt="00DDFF"},
}
local function debugPrintTable(printTable, maxDepth, colours)
	local memstring = {}
	addTableToMemstring(printTable, memstring, maxDepth or 1, 1, colours)
	return table.concat(memstring)
end

local function debugPrintTableWithColours(printTable, maxDepth)
	return debugPrintTable(printTable, maxDepth or 1, defaultColours)
end

return
{
	indexOf = indexOf,
	indexPairs = indexPairs,
	tkeys = tkeys,
	tnext = tnext,
	tcount = tcount,
	tempty = tempty,
	tclear = tclear,
	terase = terase,
	toupper = toupper,
	tolower = tolower,
	stringize = stringize,
    sformat = sformat,
	tostringl = tostringl,
	tdupe = tdupe,
	tcopy = tcopy,
	tconcat = tconcat,
    tmerge = tmerge,
	tmove = tmove,
	tjoin = tjoin,
	tdiff = tdiff,
    tequal = tequal,
	allValues = allValues,
	anyValues = anyValues,
	tprint = tprint,
	tlog = tlog,
	prototypeInit = prototypeInit,
	inherit = inherit,
	extend = extend,
	binarySearch = binarySearch,
	accum = accum,
	shuffle = shuffle,
	formatTime = formatTime,
	timeYield = timeYield,
	sleep = sleep,
	fullGC = fullGC,
	discreteSpiral = discreteSpiral,
    xypairs = xypairs,
    pairsByKeys = pairsByKeys,

    hashMd5 = hashMd5,

	color = color,
	weighted_list = weighted_list,
	toRGBA = toRGBA,
	stringizeRGBA = stringizeRGBA,
	stringizeRGBFloat = stringizeRGBFloat,

	debugPrintTable = debugPrintTable,
	debugPrintTableWithColours = debugPrintTableWithColours,

	makeDelegate = makeDelegate,
	callDelegate = callDelegate,
	coDelegate = coDelegate,

    strictify = strictify,
}
