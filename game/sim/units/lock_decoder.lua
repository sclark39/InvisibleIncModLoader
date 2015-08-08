----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local unitdefs = include( "sim/unitdefs" )
local simunit = include( "sim/simunit" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )

-----------------------------------------------------
-- Local functions

local lock_decoder = { ClassType = "lock_decoder" }

function lock_decoder:onWarp( sim, oldcell, cell )
	if oldcell == nil and cell ~= nil then
		sim:addTrigger( simdefs.TRG_UNIT_USEDOOR, self )
		sim:addTrigger( simdefs.TRG_START_TURN, self )

	elseif oldcell ~= nil and cell == nil then
		sim:removeTrigger( simdefs.TRG_UNIT_USEDOOR, self )
		sim:removeTrigger( simdefs.TRG_START_TURN, self )
	end
end

function lock_decoder:decode( sim )
    self:getTraits().turns = self:getTraits().turns - 1
    if self:getTraits().turns <= 0 then

    	           
	    local x0,y0 = self:getLocation()
		self._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/door_passcardunlock", x=x0,y=y0} )                
		sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.DECODING_COMPLETE,x=x0,y=y0,color={r=1,g=1,b=1,a=1}} )
	


        local cell = sim:getCell( self:getLocation() )
        if simquery.isSecurityExit( cell.exits[ self:getFacing() ] ) then
            sim:modifyExit( cell, self:getFacing(), simdefs.EXITOP_UNLOCK )
        end
        sim:warpUnit( self, nil )
        sim:despawnUnit( self )
    else
    	local x0,y0 = self:getLocation()
		self._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/lockDecoder_working", x=x0,y=y0} )       
		sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(STRINGS.UI.FLY_TXT.DECODING,self:getTraits().turns),x=x0,y=y0,color={r=1,g=1,b=1,a=1}} )
         
    end
end

function lock_decoder:onTrigger( sim, evType, evData )
	if evType == simdefs.TRG_UNIT_USEDOOR then
		local cell = sim:getCell( self:getLocation() )
		if evData.cell == cell or evData.tocell == cell then
            sim:warpUnit( self, nil ) -- Just remove.
            sim:despawnUnit( self )
		end

    elseif evType == simdefs.TRG_START_TURN and evData == sim:getCurrentPlayer() and evData:isPC() then
        self:decode( sim )
	end
end

-----------------------------------------------------
-- Interface functions

local function applyToDoor( sim, cell, direction, unit, userUnit )
	assert( simquery.isDoorExit( cell.exits[ direction ] ))

	local decoder = simfactory.createUnit( unitdefs.prop_templates.door_decoder, sim )
	decoder:setFacing( direction )
	sim:spawnUnit( decoder )
	sim:warpUnit( decoder, cell)
	decoder:setPlayerOwner( userUnit:getPlayerOwner() )
end

local function createDoorDecoder( unitData, sim )
	return simunit.createUnit( unitData, sim, lock_decoder )
end

simfactory.register( createDoorDecoder )

return
{
	applyToDoor = applyToDoor,
}


