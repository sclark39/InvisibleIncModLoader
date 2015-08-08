----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simunit = include( "sim/simunit" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )
local inventory = include( "sim/inventory" )
local abilitydefs = include( "sim/abilitydefs" )

-----------------------------------------------------
-- Local functions

local scanner = { ClassType = "scanner" }

function scanner:onWarp( sim, oldcell, cell )
	if oldcell then
		self:deactivate( sim )
	end

	if cell and self:getTraits().startOn == true then
		self:activate( sim )
	end
end


function scanner:activate( sim )
	if  self:getTraits().mainframe_status == "inactive" then
		self:getTraits().mainframe_status = "active"

		if self:getSounds().spot_old then
			self:getSounds().spot = self:getSounds().spot_old		
			self:getSounds().spot_old = nil
		end

        sim:addTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )

		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_object_on" )
	end
end

function scanner:deactivate( sim )	
	if self:getTraits().mainframe_status == "active" then
		self:getTraits().mainframe_status = "inactive"

		self:getSounds().spot_old = self:getSounds().spot		
		self:getSounds().spot = nil			

        sim:removeTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
        self:destroyTab()
		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_object_off" )
	end
end

function scanner:onTrigger( sim, evType, evData )
	if evType == simdefs.TRG_ALARM_STATE_CHANGE then
		local x1,y1 = self:getLocation()
        local closestAgent = simquery.findClosestUnit( sim:getPC():getUnits(), x1, y1, simquery.isAgent )        

		simlog ("%s [%d] spawned an interest on : %s", self:getName(), self:getID(), closestAgent and closestAgent:getName() )
		if closestAgent then
			local x2,y2 = closestAgent:getLocation()
			sim:getNPC():spawnInterest(x2,y2, simdefs.SENSE_RADIO, simdefs.REASON_CAMERA, closestAgent)

            local dialogParams =
            {
                STRINGS.UI.SCANNER_ALERT_HEAD,
                STRINGS.UI.SCANNER_ALERT_TITLE,
                STRINGS.UI.SCANNER_ALERT_TXT,
                "gui/icons/item_icons/icon-item_FTM_scanner.png",
                color = {r=1,g=0,b=0,a=1}
            }
			sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { speech="SpySociety/HUD/gameplay/scan_line", dialog = "programDialog", dialogParams = dialogParams } )

			sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "locationDetectedDialog", dialogParams = { closestAgent }} )
		end
    end
end

function scanner:removeChild( childUnit )
    simunit.removeChild( self, childUnit )
    if childUnit:getTraits().artifact then
        self:processEMP( nil )
    end
end

-----------------------------------------------------
-- Interface functions

local function createScanner( unitData, sim )
	return simunit.createUnit( unitData, sim, scanner )
end

simfactory.register( createScanner )

return
{
	createScanner = createScanner,
}
