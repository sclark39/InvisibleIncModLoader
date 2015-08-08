----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local cdefs = include( "client_defs" )
local mui = include("mui/mui")
local mui_defs = include( "mui/mui_defs")
local simquery = include( "sim/simquery" )

----------------------------------------------------------------
-- Local functions

local hud_warnings = class()

function hud_warnings:init( hud )
    self.hud = hud
    self.warningQueue = {}
end

function hud_warnings:queueWarning( ... )
    -- If nothing is up, show warning directly.
    if self._warningTimer == nil then
        self:showWarning( ... )
    else
        table.insert( self.warningQueue, {...} )
    end
end

function hud_warnings:showWarning( txt, color, subtext, timeinseconds, mainframe, programIcon )
	--jcheng:
	--if there's a subtext, use warningtxt
	--if no subtext, use the warningtxtCenter which is centered in the box

	if not timeinseconds then
		self._warningTimer = 3*cdefs.SECONDS
	else
		self._warningTimer = timeinseconds
	end

    local screen = self.hud._screen
		
	screen.binder.warning:setVisible(true)

	local warningTxt = screen.binder.warningTxtCenter
	if subtext then
		warningTxt = screen.binder.warningTxt
		screen.binder.warningSubTxt:spoolText(subtext)
		screen.binder.warningTxtCenter:setText("")
	else
		screen.binder.warningSubTxt:setText("")
		screen.binder.warningTxt:setText("")
	end

	warningTxt:spoolText(txt)

	if color then
		screen.binder.warningBG:setColor(color.r,color.g,color.b,color.a)
		warningTxt:setColor(color.r,color.g,color.b,color.a)
		if subtext then
			screen.binder.warningSubTxt:setColor(color.r,color.g,color.b,color.a)
		end
	else
		screen.binder.warningBG:setColor( 184/255, 13/255, 13/255, 1)
		warningTxt:setColor(184/255, 13/255, 13/255, 1)
		if subtext then
			screen.binder.warningSubTxt:setColor(184/255, 13/255, 13/255, 1)
		end
	end

	if mainframe then
		screen.binder.warning.binder.hazzard:setVisible(true)
		screen.binder.warning.binder.warningTxt:setColor(0,0,0,1)
		screen.binder.warning.binder.warningSubTxt:setColor(0,0,0,1)
		screen.binder.warning.binder.warningTxtCenter:setColor(0,0,0,1)
		screen.binder.warning.binder.warningBG:setVisible(false)
		screen.binder.warning.binder.fullBG:setVisible(true)
		screen.binder.warning.binder.fullBG:setColor(1,0,0,160/255)		
	else
		screen.binder.warning.binder.fullBG:setVisible(false)
		screen.binder.warning.binder.hazzard:setVisible(false)
		screen.binder.warning.binder.warningBG:setVisible(true)
	end	

	local programGrp = screen.binder.warning.binder.programGroup
	if programIcon then
		programGrp:setVisible(true)
		programGrp.binder.program:setImage(programIcon)
	else
		programGrp:setVisible(false)
	end

	if not screen.binder.warning:hasTransition() then
		screen.binder.warning:createTransition( "activate_left" )
	end

end

function hud_warnings:updateWarnings()
	if self._warningTimer then
		self._warningTimer = self._warningTimer - 1
		if self._warningTimer <= 0 then
			self._warningTimer = nil

            if #self.warningQueue > 0 then
                local warning = table.remove( self.warningQueue, 1 )
                self:showWarning( unpack(warning) )
            else
			    local widget = self.hud._screen.binder.warning
			    widget:createTransition( "deactivate_right",
				    function( transition )
					    widget:setVisible( false )
				    end,
			     { easeOut = true } )
            end
		end
	end
end

return hud_warnings
