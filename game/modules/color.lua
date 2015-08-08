include( "class" )

local color = class()

color.fromBytes = function( r, g, b, a )
	return color( r / 255, g / 255, b / 255, (a or 255) / 255 )
end

function color:init( r, g, b, a )
	self.r, self.g, self.b, self.a = r, g, b, a or 1
end

function color:unpack()
	return self.r, self.g, self.b, self.a
end

function color:__mul( x )
	if type(x) == "number" then
		return color( self.r * x, self.g * x, self.b * x, self.a * x )
	elseif type(self) == "number" then
		return color( x.r * self, x.g * self, x.b * self, x.a * self )
	else
		error( "Cannot multiply color: " .. type(x) .. " * " .. type(self) )
	end
end

color.WHITE = color( 255/255, 255/255, 255/255 )
color.LIGHT_BLUE = color( 140/255, 255/255, 255/255 )
color.MID_BLUE = color( 78/255, 136/255, 136/255 )

color.DARK_BLUE = color( 34/255, 57/255, 57/255 )
color.GRAY = color( 0.5, 0.5, 0.5 )

color.ORANGE = color( 245/255, 127/255, 16/255 )
color.YELLOW = color( 244/255, 255/255, 120/255 )

return color