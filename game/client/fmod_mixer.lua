----------------------------------------------------------------
-- Copyright (c) 2013 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local PITCH_SHIFT_FFT = 256
local array = include( "modules/array" )
----------------------------------------------------------------
--

local Mix = class()

function Mix:init( name, fadetime, priority, categoryVolumes, pitchShifts )
	self._name = name
	self._fadetime = fadetime or 1
	self._priority = priority or 0
	self._categoryVolumes = categoryVolumes or {}
    self._pitchShifts = pitchShifts or {}
end

function Mix:destroy()
end

function Mix:applyBlend( from, t )
    t = math.min( 1.0, t )

	for category,volume in pairs( from._categoryVolumes ) do
		local target_volume = self:getCategoryVolume( category )
		local eased_volume = volume * (1 - t) + target_volume * t
		MOAIFmodDesigner.setCategoryVolume( category, eased_volume )
	end

    -- Blend dsp effects from source.
    for category, sourcePitch in pairs( from._pitchShifts ) do
        local targetPitch = self._pitchShifts[ category ] or 1.0
        local pitchShift = sourcePitch * (1 - t) + targetPitch * t
        if pitchShift == 1.0 then
            MOAIFmodDesigner.clearDSP( category )
        else
            MOAIFmodDesigner.setPitchShift( category, pitchShift, PITCH_SHIFT_FFT )
        end
    end
   -- Blend remaining dsp effects in self. (only ones taht werne't already blended)
    for category, targetPitch in pairs( self._pitchShifts ) do
        if from._pitchShifts[ category ] == nil then
            local sourcePitch = 1.0
            local pitchShift = sourcePitch * (1 - t) + targetPitch * t
            if pitchShift == 1.0 then
                MOAIFmodDesigner.clearDSP( category )
            else
                MOAIFmodDesigner.setPitchShift( category, pitchShift, PITCH_SHIFT_FFT )
            end
        end
    end
end

function Mix:setCategoryVolume( category, volume )
	self._categoryVolumes[ category ] = volume
end

function Mix:getCategoryVolume( category )
	return self._categoryVolumes[ category ] or 0
end

function Mix:setPitchShift( category, pitchShift )
    self._pitchShifts[ category ] = pitchShift
end

----------------------------------------------------------------

local Mixer = class()

function Mixer:init()
	self._mixes = {}
	self._stack = {}
    self._autoMixes = {}
	self._updateThread = MOAICoroutine.new()
	self._updateThread:run( function() while true do self:update() coroutine.yield() end end )
	
end

function Mixer:destroy()
	self._updateThread:stop()
end

function Mixer:addMix( name, ... )
	self._mixes[ name ] = Mix( name, ... )
end

function Mixer:getMixes()
	return self._stack
end

function Mixer:pushMix( name )
	local mix = self._mixes[ name ]
	if mix then
		local top = self._stack[1]

		table.insert( self._stack, mix )
		table.sort( self._stack, function(l,r) return l._priority > r._priority end )

		if top and top ~= self._stack[1] then
			self:startBlend( self._snapshot or top )
		end
	end
end

function Mixer:popMix( name )
	local top = self._stack[1]
	for i,mix in ipairs( self._stack ) do
		if name == mix._name then
			table.remove( self._stack, i )
			if top ~= self._stack[1] then
				self:startBlend( self._snapshot or top )
			end
			break;
		end
	end
end

function Mixer:startBlend( fromMix )
	self._snapshot = self:createSnapshot( fromMix )
	self._fadetimer = 0
end

function Mixer:createSnapshot( top )
	if top then
		local snapshot = Mix()
		for category,volume in pairs( top._categoryVolumes ) do
			snapshot:setCategoryVolume( category, MOAIFmodDesigner.getCategoryVolume( category ) )
		end
        for category, pitchShift in pairs( top._pitchShifts ) do
            snapshot:setPitchShift( category, MOAIFmodDesigner.getPitchShift( category ))
        end
		return snapshot
	end
end

function Mixer:update()
	local top = self._stack[1]
	if self._snapshot and top then
		self._fadetimer = self._fadetimer + 1/60
		local lerp = self._fadetimer / top._fadetime
        top:applyBlend( self._snapshot, lerp )
		if lerp >= 1 then
			self._snapshot = nil
		end
	end

    for i, autoMix in ipairs( self._autoMixes ) do
        if autoMix.enabled ~= MOAIFmodDesigner.isPlaying( autoMix.alias ) then
            if autoMix.enabled then
                self:popMix( autoMix.mixName )
            else
                self:pushMix( autoMix.mixName )
            end
            autoMix.enabled = not autoMix.enabled
        end
    end
end

function Mixer:addAutoMix( alias, mixName )
    table.insert( self._autoMixes, { alias = alias, mixName = mixName, enabled = false } )
end

function Mixer:removeAutoMix( alias )
    for i = #self._autoMixes, 1, -1 do
        local autoMix = self._autoMixes[i]
        if autoMix.alias == alias then
            if autoMix.enabled then
                self:popMix( autoMix.mixName )
            end
            table.remove( self._autoMixes, i )
        end
    end
end

return Mixer