----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )

-----------------------------------------------------
-- The modifiers class manages a set of modifiers (operator & operand) that act on
-- generic traits.  The traits table is a reference to any table that you may wish
-- to apply modifiers to.  Evaluating for a given trait calculates all applied
-- modifiers and returns the resultant value.
--
-- NOTE: (1) modifiers are applied in order of application.
-- NOTE: (2) adding a modifier that sets a trait to nil is okay; any subsequent modifiers are simply ignored
-- NOTE: (3) whenever the modifier list for a given trait is changed, the actual trait itself is updated,
--      so it is sufficient to refer to the trait directly in the traits value which doubles as a cache mechanism.

-----------------------------------------------------
-- Modifier operator types.

local ADD = '+' -- Adds to a numeric trait
local MULT = '*' -- Multiplies a numeric trait 
local SET = '=' -- Sets a trait

local modifiers = class()

modifiers.ADD = ADD
modifiers.MULT = MULT
modifiers.SET = SET

function modifiers:init( traits )
    self.traits = traits
	self.modifiers = {}
end

function modifiers:eval( trait )
	local val = nil
	for i, modifier in ipairs( self.modifiers[ trait ] ) do
		if modifier.op == SET then
			val = modifier.val
		elseif modifier.op == ADD and type(val) == "number" then
			val = val + modifier.val
		elseif modifier.op == MULT and type(val) == "number" then
			val = val * modifier.val
		end
	end
	return val
end
	
function modifiers:has( trait, name )
    local modifiers = self.modifiers[ trait ]
    if modifiers then
		for i = #modifiers, 1, -1 do
			if modifiers[i].name == name then
                return true
            end
        end
    end

    return false
end

function modifiers:add( trait, name, op, val )
    assert( trait )
    assert( op == ADD or op == MULT or op == SET )
    assert( not self:has( trait, name )) -- I'm assuming duplicate modifiers are a bug.

	local modifier = { name = name, op = op, val = val }
	if self.modifiers[ trait ] == nil then
		self.modifiers[ trait ] = { { op = SET, val = self.traits[ trait ] } }
	end
	table.insert( self.modifiers[ trait ], modifier )
	self.traits[ trait ] = self:eval( trait )
end
	
function modifiers:remove( name )
	assert( name )

    local count = 0
	for trait, modifiers in pairs( self.modifiers ) do
		for i = #modifiers, 1, -1 do
			if modifiers[i].name == name then
				table.remove( modifiers, i )
                count = count + 1
			end
		end
		self.traits[ trait ] = self:eval( trait )
		if #modifiers == 1 then
			self.modifiers[ trait ] = nil
		end
	end

    return count > 0
end

function modifiers:print()
    local str = {}
	for trait, modifiers in pairs( self.modifiers ) do
        table.insert( str, trait..": " )
		for i = 1, #modifiers do
            table.insert( str, string.format( "[%s%s, %s]", tostring(modifiers[i].op), tostring(modifiers[i].val), modifiers[i].name or "base" ))
        end
        table.insert( str, string.format( "=> %s (%s)", tostring(self.traits[ trait ]), tostring(self:eval( trait ))))
        table.insert( str, "\n" )
    end
    return table.concat( str )
end


return modifiers

