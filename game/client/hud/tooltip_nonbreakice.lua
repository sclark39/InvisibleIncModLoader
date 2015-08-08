----------------------------------------------------------------
-- Copyright (c) 2015 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local level = include( "sim/level" )
local simdefs = include( "sim/simdefs" )

------------------------------------------------------------------------------
-- Local functions

local nonbreakIceTooltip = class( util.tooltip )

function nonbreakIceTooltip:init( mainframePanel, targetWidget, unit, reason )
	util.tooltip.init( self, mainframePanel._hud._screen )
	self._targetWidget = targetWidget
	self.mainframePanel = mainframePanel

	local localPlayer = mainframePanel._hud._game:getLocalPlayer()
    local equippedProgram = nil
	if localPlayer then 
		equippedProgram = localPlayer:getEquippedProgram()
		if equippedProgram then
			local programWidget = mainframePanel._panel.binder.programsPanel:findWidget( equippedProgram:getID() )		
            if programWidget and programWidget:isVisible() then            	
			    self._ux0, self._uy0 = programWidget.binder.btn:getAbsolutePosition()
                if equippedProgram:canUseAbility( mainframePanel._hud._game.simCore, localPlayer ) then
                    self.programWidget = programWidget
                    self.equippedProgram = equippedProgram
                end
            end
		end
	end

	local section = self:addSection()
    section:addLine( "<ttheader>"..util.sformat( STRINGS.UI.TOOLTIPS.MAINFRAME_TARGET_UNIT, unit:getName() ).."</>" )

    if equippedProgram then
    	section:addAbility( string.format(STRINGS.UI.TOOLTIPS.CURRENTLY_EQUIPPED, equippedProgram:getDef().name), string.format(equippedProgram:getDef().tipdesc, equippedProgram:getCpuCost()),  "gui/icons/arrow_small.png" )
    end 

	if reason then
		section:addRequirement( reason )
	end
end

function nonbreakIceTooltip:drawLine( x0, y0, x1, y1 )
	x0, y0 = self._targetWidget:getScreen():wndToUI( x0, y0 )
	x1, y1 = self._targetWidget:getScreen():wndToUI( x1, y1 )
	MOAIDraw.drawLine( x0, y0, x1, y0 )
	MOAIDraw.drawLine( x1, y0, x1, y1 )
end

function nonbreakIceTooltip:onDraw()
	local screen = self._targetWidget:getScreen()
	if screen then
		local x0, y0 = self._ux0 - 0.5, self._uy0 - 0.5
		local x1, y1 = self._targetWidget.binder.btn:getAbsolutePosition()
		x1, y1 = x1 - 0.5, y1 - 0.5
		x0, y0 = screen:uiToWnd( x0, y0 )
		x1, y1 = screen:uiToWnd( x1, y1 )

		local offset = 15

		self:drawLine( x0, y0 + 3 + offset, x1 + 6, y1 )
		self:drawLine( x0, y0 + 6 + offset, x1 , y1 )
		self:drawLine( x0, y0     + offset, x1+3, y1 )
		self:drawLine( x0, y0 - 3 + offset, x1 - 6, y1 )
		self:drawLine( x0, y0 - 6 + offset, x1 - 3, y1 )
	end
end

function nonbreakIceTooltip:activate( screen )
	util.tooltip.activate( self, screen )
	if self._ux0 and self._uy0 then
		table.insert( self.mainframePanel._iceBreaks, self )
	end

    if self.programWidget and self.equippedProgram then
		self.mainframePanel:programWidgetSetColor( self.programWidget, self.equippedProgram, util.color.YELLOW )
	end
end

function nonbreakIceTooltip:deactivate()
	if self._ux0 and self._uy0 then
		array.removeElement( self.mainframePanel._iceBreaks, self )
	end

	if self.programWidget and self.equippedProgram then
		self.mainframePanel:programWidgetSetColor( self.programWidget, self.equippedProgram )
	end

	util.tooltip.deactivate( self )
end

return nonbreakIceTooltip