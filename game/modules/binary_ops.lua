----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local function binary_op( a, b, OP )
	local pow = 1
	local c = 0
	while a > 0 or b > 0 do
		c = c + (OP[(a % 2)+1][(b % 2)+1] * pow)
		a = math.floor(a/2)
		b = math.floor(b/2)
		pow = pow * 2
	end
	return c
end

local XOR_OP =
{
	{0,1},
	{1,0},
}

local OR_OP =
{
	{0,1},
	{1,1},
}

local AND_OP =
{
	{0,0},
	{0,1},
}

local NAND_OP =
{
	{1,0},
	{0,0},
}

local function b_or( a, b )
	return binary_op( a, b, OR_OP )
end

local function b_and( a, b )
	return binary_op( a, b, AND_OP )
end

local function b_xor( a, b )
	return binary_op( a, b, XOR_OP )
end

local function b_nand( a, b )
	return binary_op( a, b, NAND_OP )
end

local function b_not( a )
	return binary_op( a, a, NAND_OP )
end

local function test(set, flag)
  return set % (2*flag) >= flag
end

local function set(set, flag)
  if set % (2*flag) >= flag then	
    return set
  end  
  return set + flag
end

local function clr(set, flag) -- clear flag
  if set % (2*flag) >= flag then
    return set - flag
  end
  return set
end

local function count(set, n)
	-- count how many of the first n bits are set
	local count = 0
	for i=0,n do
		if test(set, 2^i) then
			count = count + 1
		end
	end

	return count
end

local function init( ... )
	local n = 0
	for i,flag in ipairs({...}) do
		n = set( n, 2^flag )
	end

	return n
end

local function fill(bits)
	return 2^bits - 1
end

local function shiftr( n, bits )
	for i=0,31 do
		if test( n, 2^(i+bits)) then
			n = set( n, 2^i )
		else
			n = clr( n, 2^i )
		end
	end
	return n
end

local function shiftl( n, bits )
	for i=31,0,-1 do
		if i >= bits and test( n, 2^(i-bits)) then
			n = set( n, 2^i )
		else
			n = clr( n, 2^i )
		end
	end
	return n
end


local function tostr(n)
	local s = ""
	for i=31,0,-1 do
		if test(n, 2^i) then
			s = s .. "1"
		else
			s = s .. "0"
		end
	end

	return s
end

local function fromstr(s)
	local n = 0
	for i = 1,#s do
		local c = s:sub(i,i)
		if c ~= "0" then
			n = set( n, 2^(#s-i) )
		end
	end
	return n
end

return
{
	b_or = b_or,
	b_and = b_and,
	b_xor = b_xor,
	b_nand = b_nand,
	b_not = b_not,
	
	shiftr = shiftr,
	shiftl = shiftl,

	test = test,
	set = set,
	clr = clr,
	count = count,
	init = init,
	fill = fill,

	tostr = tostr,
	fromstr = fromstr,
}
