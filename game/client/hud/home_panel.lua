----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local mui_defs = include( "mui/mui_defs")
local mui_tooltip = include( "mui/mui_tooltip")
local agent_panel = include( "hud/agent_panel" )
local simquery = include( "sim/simquery" )

------------------------------------------------------------------------------
-- Local functions


local function onClickMainframeBtn( hud , player)
	hud:onClickMainframeBtn()
end

local function generateAgentTooltip( hud, unit )
	return mui_tooltip( util.toupper(unit:getName()), unit:getUnitData().toolTip, "cycleSelection" )
end

local function generateMainframeTooltip( hud )
	return mui_tooltip( STRINGS.UI.INCOGNITA_NAME, STRINGS.UI.INCOGNITA_TT, "mainframeMode" )
end

local function onClickUnitBtn( panel, unit )
	if not unit._isPlayer and unit:getLocation() ~= nil then
		panel._hud._game:cameraPanToCell( unit:getLocation() )
    	panel._hud:selectUnit( unit )
    end
end

------------------------------------------------------------------------------

local panel = class()

function panel:init( screen, hud )
	self._hud = hud
	self._panel = screen.binder.homePanel
	self._panel_top = screen.binder.homePanel_top
	self:refresh()
end

function panel:findAgentWidget( unitID )
	local localPlayer = self._hud._game:getLocalPlayer()
	if not localPlayer or localPlayer:isNPC() then
		return
	end
	local simquery = include( "sim/simquery" )

	local j = 1
	for i,unit in ipairs(localPlayer:getUnits()) do
		if localPlayer:findAgentDefByID( unit:getID() ) or unit:getTraits().home_panel then
			if unit:getID() == unitID  then
				return self._panel.binder:tryBind( "agent" .. j )
			else
				j = j + 1
			end
		end
	end

	return nil
end


function panel:refreshAgent( unit )
	local widget = self:findAgentWidget( unit:getID() )
	if widget == nil then
		return
	end

	-- Updates the agent information for the current unit (profile image, brief info text)
	widget.binder.agentProfile:setImage( unit:getUnitData().profile_icon_36x36 )

	if self._hud:getSelectedUnit() == unit then
		widget.binder.agentProfile:setColor(1,1,1,1)
	else
		widget.binder.agentProfile:setColor(1,1,1,0.65)
	end

	widget:setTooltip( generateAgentTooltip( self._hud, unit ) )
	widget.binder.btn.onClick = util.makeDelegate( nil, onClickUnitBtn, self, unit )
	widget.binder.selected:setVisible( self._hud:getSelectedUnit() == unit )					
	widget.binder.border:setVisible(true)

	local clr = cdefs.AP_COLOR_NORMAL
	local ap = unit:getMP()
	if self._hud._movePreview and self._hud._movePreview.unitID == unit:getID() and ap > self._hud._movePreview.pathCost then
		clr = cdefs.AP_COLOR_PREVIEW
		ap = ap - self._hud._movePreview.pathCost
	end

	local showAgentDown = unit:isDown()
	widget.binder.agentDown:setVisible( showAgentDown )	
	widget.binder.apTxt:setVisible( not showAgentDown )
	widget.binder.apNum:setVisible( not showAgentDown )

	widget.binder.apTxt:setColor( clr:unpack() )
	widget.binder.apNum:setColor( clr:unpack() )
	widget.binder.apNum:setText( math.floor( ap ))

	if not self._hud:canShowElement( "agentSelection" ) or self._hud._isMainframe == true then
		widget:setVisible( false )
	else	
		widget:setVisible( true )
	end

end


function panel:refresh()
	local localPlayer = self._hud._game:getLocalPlayer()

	for j, agentGrp in self._panel.binder:forEach( "agent" ) do
		agentGrp:setVisible( false )
	end

	if not localPlayer or localPlayer:isNPC() then
		return
	end

	local item =  self._panel_top.binder.incognitaBtn
	item:setAlias("mainframe")
	item:setTooltip( generateMainframeTooltip( self._hud ) )
	item:setHotkey( "mainframeMode" )
	item.onClick = util.makeDelegate( nil, onClickMainframeBtn, self._hud,localPlayer)

	if self._hud:isMainframe() then
		item:setText(STRINGS.UI.HUD_INCOGNITA_MAINFRAME)
	else
		item:setText(STRINGS.UI.HUD_INCOGNITA_NORMAL)
	end	
	item:setVisible( self._hud:canShowElement( "mainframe" ) )
	self._panel_top.binder.bg:setVisible( self._hud:canShowElement( "mainframe" ) )
	self._panel_top.binder.incognitaFace:setVisible( self._hud:canShowElement( "mainframe" ) )

	--AGENTS	
	for i,unit in ipairs(localPlayer:getUnits()) do
		if localPlayer:findAgentDefByID( unit:getID() ) or unit:getTraits().home_panel then
			self:refreshAgent( unit )
		end
	end
end

return
{
	panel = panel
}

