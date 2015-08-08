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

local breakIceTooltip = class( util.tooltip )

function breakIceTooltip:init( mainframePanel, iceWidget, unit, reason )
	util.tooltip.init( self, mainframePanel._hud._screen )
	self._iceWidget = iceWidget
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
    section:addLine( "<ttheader>"..util.sformat( STRINGS.UI.TOOLTIPS.MAINFRAME_HACK_UNIT, unit:getName() ).."</>" )

    section:addAbility( string.format(STRINGS.UI.TOOLTIPS.FIREWALLS, unit:getTraits().mainframe_ice), STRINGS.UI.TOOLTIPS.FIREWALLS_DESC,  "gui/icons/action_icons/Action_icon_Small/icon-action_lock_small.png" )

    if equippedProgram then
    	section:addAbility( string.format(STRINGS.UI.TOOLTIPS.CURRENTLY_EQUIPPED, equippedProgram:getDef().name), util.sformat(equippedProgram:getDef().tipdesc, equippedProgram:getCpuCost()),  "gui/icons/arrow_small.png" )
    end 

	if unit:getTraits().parasite then 
		if unit:getTraits().parasiteV2 then
			section:addLine( STRINGS.UI.TOOLTIPS.MAINFRAME_PARASITE_V2 )
		else
			section:addLine( STRINGS.UI.TOOLTIPS.MAINFRAME_PARASITE )
		end
	end

	local sim = mainframePanel._hud._game.simCore
	if sim:getHideDaemons() and not unit:getTraits().daemon_sniffed then
		section:addRequirement( STRINGS.UI.TOOLTIPS.MAINFRAME_MASKED )
	else	
		if unit:getTraits().mainframe_program then
			section:addRequirement( STRINGS.UI.TOOLTIPS.MAINFRAME_DAEMON)
			local npc_abilities = include( "sim/abilities/npc_abilities" )
			local ability = npc_abilities[ unit:getTraits().mainframe_program ]
			if unit:getTraits().daemon_sniffed then 
				section:addAbility( ability.name, ability.desc, ability.icon )
			else
				section:addAbility( STRINGS.UI.TOOLTIPS.MAINFRAME_HIDDEN_DAEMON, "?????????", "gui/items/item_quest.png" )
			end
		end
	end

	if reason then
		section:addRequirement( reason )
	end
end

function breakIceTooltip:drawLine( x0, y0, x1, y1 )
	x0, y0 = self._iceWidget:getScreen():wndToUI( x0, y0 )
	x1, y1 = self._iceWidget:getScreen():wndToUI( x1, y1 )
	MOAIDraw.drawLine( x0, y0, x1, y0 )
	MOAIDraw.drawLine( x1, y0, x1, y1 )
end

function breakIceTooltip:onDraw()
	local screen = self._iceWidget:getScreen()
	if screen then
		local x0, y0 = self._ux0 - 0.5, self._uy0 - 0.5
		local x1, y1 = self._iceWidget.binder.btn:getAbsolutePosition()
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

function breakIceTooltip:activate( screen )
	util.tooltip.activate( self, screen )
	if self._ux0 and self._uy0 then
		table.insert( self.mainframePanel._iceBreaks, self )
	end

    if self.programWidget and self.equippedProgram then
		self.mainframePanel:programWidgetSetColor( self.programWidget, self.equippedProgram, util.color.YELLOW )
	end
end

function breakIceTooltip:deactivate()
	if self._ux0 and self._uy0 then
		array.removeElement( self.mainframePanel._iceBreaks, self )
	end

	if self.programWidget and self.equippedProgram then
		self.mainframePanel:programWidgetSetColor( self.programWidget, self.equippedProgram )
	end

	util.tooltip.deactivate( self )
end

return breakIceTooltip