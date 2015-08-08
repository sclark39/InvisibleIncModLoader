----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simunit = include( "sim/simunit" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local mathutil = include( "modules/mathutil" )

-----------------------------------------------------
-- Local functions


local function toggle( self, sim )
	if self:getTraits().mainframe_status == "active" then
		self:deactivate( sim )
	else
		self:activate( sim )
	end
end

local function activate( self, sim )
	if  self:getTraits().mainframe_status == "inactive" then
		self:getTraits().mainframe_status = "active"
		
		self:getTraits().hasHearing = true      

	end
end

local function deactivate( self, sim )	
	if self:getTraits().mainframe_status == "active" then
		self:getTraits().mainframe_status = "inactive"

		self:getTraits().hasHearing = false      

	end
end


local function performTracking( self, sim, x1, y1, seenPlayer, seenUnit )	

	if self._triggered == false and (seenPlayer == nil or seenPlayer:isPC()) then

		self._triggered = true
		if seenPlayer ~= nil then
			seenPlayer:glimpseUnit( sim, self:getID() )
		end
		self:getTraits().tracker_alert = true

		local x0,y0 = self:getLocation()
		sim:emitSound( simdefs.SOUND_SECURITY_ALERTED, x0, y0, self )
		sim:triggerEvent( simdefs.TRG_NEW_INTEREST, { x = x0, y = y0, range = simdefs.SOUND_RANGE_3, interest = {x= x1,y = y1} })
	
		sim:dispatchEvent( simdefs.EV_UNIT_ALERTED, { unitID = self:getID() } )

		sim:trackerAdvance( 1, STRINGS.UI.ALARM_SOUND )	
	end	
end

local function onWarp(self, sim, oldcell, cell )
	if oldcell == nil then
		sim:addTrigger( simdefs.TRG_SOUND_EMITTED, self)
		sim:addTrigger( simdefs.TRG_START_TURN, self )
		sim:addTrigger( simdefs.TRG_OVERWATCH, self )

	elseif cell == nil then
		sim:removeTrigger( simdefs.TRG_SOUND_EMITTED, self)
		sim:removeTrigger( simdefs.TRG_START_TURN, self )
		sim:removeTrigger( simdefs.TRG_OVERWATCH, self )
	end
end 

local function onTrigger( self, sim, evType, evData )
	if evType == simdefs.TRG_SOUND_EMITTED and evData.sourceUnit then
		local isActive = self:getTraits().mainframe_status == "active" and (self:getPlayerOwner() == nil or self:getPlayerOwner():isNPC())
		if isActive then
			local x1,y1 =  self:getLocation()
			local x0,y0 =  evData.x, evData.y
			local range =  math.sqrt( mathutil.distSqr2d( x0, y0, x1, y1 ) )
			if range <= evData.range then
				local playerOwner = sim:getCurrentPlayer()
				if evData.sourceUnit ~= nil then
					playerOwner = evData.sourceUnit:getPlayerOwner()
				end

				self.sound = {x=x0, y=y0, playerOwner=playerOwner, sourceUnit=evData.sourceUnit}
			end
		end

	elseif evType == simdefs.TRG_OVERWATCH then
		if self.sound then
			performTracking( self, sim, self.sound.x, self.sound.y, self.sound.playerOwner, self.sound.sourceUnit)
			self.sound = nil
		end

	elseif evType == simdefs.TRG_START_TURN then
		local glimpse = false
		if self:getTraits().tracker_alert then
			glimpse = true
		end
		self._triggered = false
		self:getTraits().tracker_alert = false
		
		if glimpse then

			for i,player in ipairs(sim:getPlayers()) do			
				if player ~= self:getPlayerOwner() then
					player:glimpseUnit( sim, self:getID() )
				end
			end
			
		end

		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self} ) 		
	end
end

-----------------------------------------------------
-- Interface functions

local function createSoundBug( unitData, sim )
	local t = simunit.createUnit( unitData, sim )
	t.ClassType = "simsoundbug"
	t._triggered = false
	t._trackedUnits = {}
	t._trackTurn = -1
	t.onTrigger = onTrigger
	t.onWarp = onWarp

	t.toggle = toggle
	t.activate = activate
	t.deactivate = deactivate

	return t
end

simfactory.register( createSoundBug )

return
{
	createSoundBug = createSoundBug,
}

