----------------------------------------------------------------
-- Copyright (c) 2013 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------


require("class")

local post_process = class()

function post_process:init( )
	self._pp = KLEIPostProcess.new()
end

function post_process:destroy()
	self._pp = nil
    self._mt = nil
	self._span = nil
	self._lerp = nil
	self._timer = nil
end

function post_process:getRenderable()
	return self._pp
end

function post_process:passthrough( texture )
	self._pp:setEffect( KLEIPostProcess.PASS_THROUGH )
    self._pp:setTexture( texture )
	self._pp:getUniforms():clearUniforms()
end

function post_process:desaturation( texture, desat_ease )
    self._pp:setEffect( KLEIPostProcess.DESATURATION )
    self._pp:setTexture( texture )
    self._pp:getUniforms():clearUniforms()
	local t = type(desat_ease)
	if t == "function" then
		self._pp:getUniforms():setUniformDriver( desat_ease )
	elseif t == "number" then
		self._pp:getUniforms():setUniformFloat( "desat_ease", desat_ease )	
	end
end

function post_process:downsample( texture )
    self._pp:setEffect( KLEIPostProcess.DOWNSAMPLE )
    self._pp:setTexture( texture )
    self._pp:getUniforms():clearUniforms( )
end

function post_process:vertical_gaussian( texture )
    self._pp:setEffect( KLEIPostProcess.GAUSSIAN_VERTICAL )
    self._pp:setTexture( texture )
    self._pp:getUniforms():clearUniforms( )
end

function post_process:horizontal_gaussian( texture )
    self._pp:setEffect( KLEIPostProcess.GAUSSIAN_HORIZONTAL )
    self._pp:setTexture( texture )
    self._pp:getUniforms():clearUniforms( )
end

function post_process:dual_gaussian( texture )
    self._pp:setEffect( KLEIPostProcess.GAUSSIAN_DUAL )
    self._pp:setTexture( texture )
    self._pp:getUniforms():clearUniforms( )
end

function post_process:bloom_merge( texture, bloom, bloom_ease )
    self._mt = MOAIMultiTexture.new()
	self._mt:reserve( 2 )
    self._mt:setTexture( 1, texture )
    self._mt:setTexture( 2, bloom )

    self._pp:setEffect( KLEIPostProcess.BLOOM_MERGE )
    self._pp:setTexture( self._mt )
    self._pp:getUniforms():clearUniforms( )
    self._pp:getUniforms():setUniformFloat( "bloom_ease", bloom_ease )
end

function post_process:bloom_merge_desaturation( texture, bloom, bloom_ease, desat_ease )
    self._mt = MOAIMultiTexture.new()
	self._mt:reserve( 2 )
    self._mt:setTexture( 1, texture )
    self._mt:setTexture( 2, bloom )

    self._pp:setEffect( KLEIPostProcess.BLOOM_MERGE_DESATURATION )
    self._pp:setTexture( self._mt )
    self._pp:getUniforms():clearUniforms( )

    self._pp:getUniforms():setUniformFloat( "bloom_ease", bloom_ease )    
    local t = type(desat_ease)
	if t == "function" then
		self._pp:getUniforms():setUniformDriver( desat_ease )
	elseif t == "number" then
		self._pp:getUniforms():setUniformFloat( "desat_ease", desat_ease )	
	end

end

function post_process:pixelate( texture, UIDriver )
    self._pp:setEffect( KLEIPostProcess.PIXELATE )
	self._pp:setTexture( texture )
    self._pp:getUniforms():clearUniforms( )
end

function post_process:overlay( texture, overlay)
    self._mt = MOAIMultiTexture.new()
	self._mt:reserve( 2 )
    self._mt:setTexture( 1, texture )
    self._mt:setTexture( 2, overlay )

	self._pp:setEffect( KLEIPostProcess.OVERLAY )
	self._pp:setTexture( self._mt )
    self._pp:getUniforms():clearUniforms( )
end

function post_process:ascii( texture, ease )
	self._mt = MOAIMultiTexture.new()
	self._mt:reserve( 2 )
	self._mt:setTexture( 1, texture )
	self._mt:setTexture( 2, "data/images/ascii.png" )

	self._pp:setEffect( KLEIPostProcess.ASCII )
	self._pp:setTexture( self._mt )
    self._pp:getUniforms():clearUniforms()
    if type(ease) == 'function' then
        self._pp:getUniforms():setUniformDriver( ease )
    else
        self._pp:getUniforms():setUniformFloat( 'ease', ease )
    end
end

function post_process:fuzz( texture, UIEaseDriver )
	assert( UIEaseDriver )
	self._pp:setEffect( KLEIPostProcess.FUZZ )
    self._pp:setTexture( texture )
    self._pp:getUniforms():clearUniforms()
	self._pp:getUniforms():setUniformDriver( UIEaseDriver )
end

local color_correction = {
--Protanope -- Red cone deficiency
protanope = {	simulation = {	0.000000,  2.023440, -2.525810,  0.000000,
								0.000000,  1.000000,  0.000000,  0.000000,
								0.000000,  0.000000,  1.000000,  0.000000,
								0.000000,  0.000000,  0.000000,  1.000000 },
				correction = {  0.0, 0.5, 0.5, 0.0, 
								0.0, 1.0, 0.0, 0.0,
								0.0, 0.0, 1.0, 0.0,
								0.0, 0.0, 0.0, 1.0 },
			}, --protanope
--Deuteranope -- Green cone deficiency
deuteranope = { simulation = {	1.000000,  0.000000,  0.000000,  0.000000,
								0.494207,  0.000000,  1.248270,  0.000000,
								0.000000,  0.000000,  1.000000,  0.000000,
								0.000000,  0.000000,  0.000000,  1.000000 },
				correction = {	1.0, 0.0, 0.0, 0.0,
								0.5, 0.0, 0.5, 0.0,
								0.0, 0.0, 1.0, 0.0,
								0.0, 0.0, 0.0, 1.0 },
			  }, --deuteranope
--Tritanope -- Blue cone deficiency
tritanope = {	simulation = {  1.000000,  0.000000,  0.000000,  0.000000,
								0.000000,  1.000000,  0.000000,  0.000000,
							   -0.395913,  0.801109,  0.000000,  0.000000,
							    0.000000,  0.000000,  0.000000,  1.000000 },
				correction = {	1.0, 0.0, 0.0, 0.0,
								0.0, 1.0, 0.0, 0.0,
								0.5, 0.5, 0.0, 0.0,
								0.0, 0.0, 0.0, 1.0 },
			}, --tritanope
} --color_correction

function post_process:daltonize( texture, type )
	assert( type == 1 or type == 2 or type == 3 )
	self._pp:setEffect( KLEIPostProcess.DALTONIZE )
    self._pp:setTexture( texture )
    self._pp:getUniforms():clearUniforms()
	if type == 1 then --Protanope
		self._pp:getUniforms():setUniformMat4x4( "simulation", unpack(color_correction.protanope.simulation) )
		self._pp:getUniforms():setUniformMat4x4( "correction", unpack(color_correction.protanope.correction) )
	elseif type == 2 then --Deuteranope
		self._pp:getUniforms():setUniformMat4x4( "simulation", unpack(color_correction.deuteranope.simulation) )
		self._pp:getUniforms():setUniformMat4x4( "correction", unpack(color_correction.deuteranope.correction) )
	elseif type == 3 then --Tritanope
		self._pp:getUniforms():setUniformMat4x4( "simulation", unpack(color_correction.tritanope.simulation) )
		self._pp:getUniforms():setUniformMat4x4( "correction", unpack(color_correction.tritanope.correction) )
	end
end

function post_process:daltonize_fuzz( texture, daltonization, UIFuzzDriver )
	assert( daltonization == 1 or daltonization == 2 or daltonization == 3 )
	assert( UIFuzzDriver )
	self._pp:setEffect( KLEIPostProcess.DALTONIZE_FUZZ )
    self._pp:setTexture( texture )
    self._pp:getUniforms():clearUniforms()
	self._pp:getUniforms():setUniformDriver( UIFuzzDriver )

	if daltonization == 1 then --Protanope
		self._pp:getUniforms():setUniformMat4x4( "simulation", unpack(color_correction.protanope.simulation) )
		self._pp:getUniforms():setUniformMat4x4( "correction", unpack(color_correction.protanope.correction) )
	elseif daltonization == 2 then --Deuteranope
		self._pp:getUniforms():setUniformMat4x4( "simulation", unpack(color_correction.deuteranope.simulation) )
		self._pp:getUniforms():setUniformMat4x4( "correction", unpack(color_correction.deuteranope.correction) )
	elseif daltonization == 3 then --Tritanope
		self._pp:getUniforms():setUniformMat4x4( "simulation", unpack(color_correction.tritanope.simulation) )
		self._pp:getUniforms():setUniformMat4x4( "correction", unpack(color_correction.tritanope.correction) )
	end
end

function post_process:daltonize_ascii( texture, daltonization, ease )
	assert( daltonization == 1 or daltonization == 2 or daltonization == 3 )
	assert( ease )

	self._mt = MOAIMultiTexture.new()
	self._mt:reserve( 2 )
	self._mt:setTexture( 1, texture )
	self._mt:setTexture( 2, "data/images/ascii.png" )

	self._pp:setEffect( KLEIPostProcess.DALTONIZE_ASCII )
	self._pp:setTexture( self._mt )
    self._pp:getUniforms():clearUniforms()

    if type(ease) == 'function' then
	    self._pp:getUniforms():setUniformDriver( ease )
    else
        self._pp:getUniforms():setUniformFloat( 'ease', ease )
    end

	if daltonization == 1 then --Protanope
		self._pp:getUniforms():setUniformMat4x4( "simulation", unpack(color_correction.protanope.simulation) )
		self._pp:getUniforms():setUniformMat4x4( "correction", unpack(color_correction.protanope.correction) )
	elseif daltonization == 2 then --Deuteranope
		self._pp:getUniforms():setUniformMat4x4( "simulation", unpack(color_correction.deuteranope.simulation) )
		self._pp:getUniforms():setUniformMat4x4( "correction", unpack(color_correction.deuteranope.correction) )
	elseif daltonization == 3 then --Tritanope
		self._pp:getUniforms():setUniformMat4x4( "simulation", unpack(color_correction.tritanope.simulation) )
		self._pp:getUniforms():setUniformMat4x4( "correction", unpack(color_correction.tritanope.correction) )
	end
end

function post_process:colorCubeLerp( cube1, cube2, span, mode, start, stop )
	self._mt = MOAIMultiTexture.new()
	if self._overlay then
		self._mt:reserve( 4 )
		self._mt:setTexture( 1, self._diffuse )
		self._mt:setTexture( 2, self._overlay )
		self._mt:setTexture( 3, cube1 )
		self._mt:setTexture( 4, cube2 )
	else
		self._mt:reserve( 3 )
		self._mt:setTexture( 1, self._diffuse )
		self._mt:setTexture( 2, cube1 )
		self._mt:setTexture( 3, cube2 )
	end

	self._pp:setTexture( self._mt )
    self._pp:getUniforms():clearUniforms()

	start = start or 0
	stop = stop or 1

	local timer = MOAITimer.new()
	timer:setSpan( span )
	timer:setMode( mode )
	timer:start()
	local uniformDriver = function()
		local t = timer:getTime() / span
		self._pp:setUniformFloat( "cc_lerp", t * ( stop - start ) + start )
	end

	if self._overlay then
		self._pp:setEffect( KLEIPostProcess.COLOR_CUBE_OVERLAY )
	else
		self._pp:setEffect( KLEIPostProcess.COLOR_CUBE )
	end
	self._pp:getUniforms():setUniformDriver( uniformDriver )
end

------------------------------------------------------------------------------------------------------------

local post_process_manager = class()

function post_process_manager:init()
end

function post_process_manager:destroy()
end

function post_process_manager.create()
    return post_process()
end

function post_process_manager.passthrough( tex )
    local pp = post_process()
    pp:passthrough( tex )
    return pp
end

function post_process_manager.overlay( t1, t2 )
    local pp = post_process()
    pp:overlay( t1, t2 )
    return pp
end

function post_process_manager.downsample( tex )
    local pp = post_process()
    pp:downsample( tex )
    return pp
end

function post_process_manager.vertical_gaussian( tex )
    local pp = post_process()
    pp:vertical_gaussian( tex )
    return pp
end

function post_process_manager.horizontal_gaussian( tex )
    local pp = post_process()
    pp:horizontal_gaussian( tex )
    return pp
end

function post_process_manager.dual_gaussian( tex )
    local pp = post_process()
    pp:dual_gaussian( tex )
    return pp
end

function post_process_manager.bloom_merge( texture, bloom, bloom_ease )
    local pp = post_process()
    pp:bloom_merge( texture, bloom, bloom_ease )
    return pp
end

function post_process_manager.bloom_merge_desaturation( texture, bloom, bloom_ease, desat_ease )
    local pp = post_process()
    pp:bloom_merge_desaturation( texture, bloom, bloom_ease, desat_ease )
    return pp
end

return post_process_manager