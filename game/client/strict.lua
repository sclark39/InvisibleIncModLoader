--
-- strict.lua
-- checks uses of undeclared global variables
-- All global variables must be 'declared' through a regular assignment
-- (even assigning nil will do) in a main chunk before being used
-- anywhere or assigned to inside a function.
--

local function what ()
	local d = debug.getinfo(3, "S")
	return d and d.what or "C"
end

local STRICT_MT =
{
    __newIndex = function(t, n, v)
	    local w = what()
	    if w ~= "main" and w ~= "C" then
		    assert(nil, "assign to undeclared variable '"..n.."'")
	    end
	    rawset(t, n, v)
    end,
 
    __index = function(t, n)
	    if what() ~= "C" then
		    assert(nil, "variable '"..tostring(n).."' is not declared")
	    end
	    return rawget(t, n)
    end
}

local function strictify( t, recurse )
    local mt = getmetatable( t )
    if mt == nil then
        setmetatable(t, STRICT_MT )
        if recurse then
            for k, v in pairs(t) do
                if type(v) == "table" then
                    strictify( v, recurse )
                end
            end
        end
    end
end

return strictify

