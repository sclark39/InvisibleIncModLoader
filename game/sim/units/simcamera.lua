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
local cdefs = include( "client_defs" )

-----------------------------------------------------
-- Local functions

local simcamera =
{
    ClassType = "simcamera",
}

function simcamera:checkParasites( sim )

	local mainframe = include( "sim/mainframe" )
	if sim:isVersion("0.17.5") then
		if self:getTraits().parasite then
			mainframe.removeParasite(sim:getPC(),self)
		end
	end
end

function simcamera:activate( sim )
	if  self:getTraits().mainframe_status == "inactive" then
		self:getTraits().mainframe_status = "active"
		self:getTraits().hasSight = true
		sim:refreshUnitLOS( self )
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )
        for i, targetUnit in ipairs( self:getSeenUnits() ) do
            if self:canTrackTarget( targetUnit ) then
                self:performTracking( sim, targetUnit )
                break
            end
        end
	end
end

function simcamera:deactivate( sim )	
	if self:getTraits().mainframe_status == "active" then
		self:getTraits().mainframe_status = "inactive"
		self:getTraits().hasSight = nil
		sim:refreshUnitLOS( self )
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )
	end
end


function simcamera:performTracking( sim, seenUnit )
    -- Flag that we tracked already this turn.
    self:getTraits().tracker_alert = true

	local x0, y0 = self:getLocation()
	if not self:getTraits().camera_drone then 
		sim:emitSound( simdefs.SOUND_SECURITY_ALERTED, x0, y0, self )
	end
    if self.addTrackingInterest then
        self:addTrackingInterest( sim, seenUnit )
    else
		local x1, y1 = seenUnit:getLocation()
		if self:getTraits().camera_drone then 
			sim:triggerEvent( simdefs.TRG_NEW_INTEREST, { x = x0, y = y0, range = 0, interest = { x= x1, y = y1, reason=simdefs.REASON_CAMERA} })
		else 
			sim:triggerEvent( simdefs.TRG_NEW_INTEREST, { x = x0, y = y0, range = simdefs.SOUND_RANGE_3, interest = { x= x1, y = y1, reason=simdefs.REASON_CAMERA} })
		end 
    end

	sim:dispatchEvent( simdefs.EV_UNIT_ALERTED, { unitID = self:getID() } )

	if self:getTraits().camera_drone then
		local x1, y1 = seenUnit:getLocation()
		sim:getNPC():spawnInterest(x1,y1, simdefs.SENSE_RADIO, simdefs.REASON_CAMERA )
		sim:dispatchEvent( simdefs.EV_UNIT_ENGAGED, self )
	else 
		sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(  STRINGS.UI.ALARM_ADD, 1 ),x=x0,y=y0,color={r=255/255,g=10/255,b=10/255,a=1}} )		
		sim:trackerAdvance( 1, STRINGS.UI.ALARM_CAMERA_SCAN )
		sim:triggerEvent( simdefs.TRG_CAUGHT_BY_CAMERA)
	end 

	if seenUnit then
	    if seenUnit:getPlayerOwner() then
            seenUnit:getPlayerOwner():glimpseUnit( sim, self:getID() )
        end
		sim:dispatchEvent( simdefs.EV_CAM_PAN, { seenUnit:getLocation() } )	
		sim:dispatchEvent( simdefs.EV_UNIT_RESET_ANIM_PLAYBACK, { unit = seenUnit } ) 
	end
end

function simcamera:onDamage( damage, sim)


	self:checkParasites(sim)


	self:getTraits().dead = true
    self:deactivate( self._sim )
	self:getTraits().mainframe_status = "off" -- Broken.
	self:getTraits().mainframe_booting = nil

	local x1,y1 = self:getLocation()	
	sim:emitSound( simdefs.SOUND_CAMERA_DESTROYED, x1, y1, self )
	sim:dispatchEvent( simdefs.EV_UNIT_DEATH, { unit = self } )


end

function simcamera:onWarp( sim, oldcell, cell)
	if not oldcell and cell then
		sim:addTrigger( simdefs.TRG_START_TURN, self )
	else
		if not cell and oldcell then
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
            sim:removeTrigger( simdefs.TRG_OVERWATCH, self )
		end
	end
end 

function simcamera:onEndTurn( sim )
    simunit.onEndTurn( self, sim )
    sim:removeTrigger( simdefs.TRG_OVERWATCH, self )
end

function simcamera:canTrackTarget( targetUnit )
	if not self:isPC() and not self:getTraits().tracker_alert then
        if targetUnit and simquery.isEnemyAgent( self:getPlayerOwner(), targetUnit ) and not targetUnit:isKO() then
            if self._sim:canUnitSeeUnit( self, targetUnit ) then
                return true
            end
        end
    end
    return false
end

function simcamera:onTrigger( sim, evType, evData )
    if self:getTraits().mainframe_status ~= "active" or self:isPC() then
        return
    end
    
	if evType == simdefs.TRG_START_TURN then
		if evData ~= nil and not evData:isNPC() then
			self:getTraits().tracker_alert = false
    		sim:addTrigger( simdefs.TRG_OVERWATCH, self )
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )
		end

    elseif evType == simdefs.TRG_OVERWATCH then
        if self:canTrackTarget( evData ) then
            evData:interruptMove( sim, self )
            self:performTracking( sim, evData )
        end
	end
end

-----------------------------------------------------
-- Interface functions

local function createCamera( unitData, sim )
	return simunit.createUnit( unitData, sim, simcamera )
end

simfactory.register( createCamera )

return simcamera
