-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local util = require( "modules/util" )
local array = require( "modules/array" )
local mui_defs = require( "mui/mui_defs" )
local mui_util = require("mui/mui_util")
local mui_binder = require("mui/mui_binder")

-- Name of the default tooltip skin used for displaying tooltips.
local DEFAULT_TOOLTIP_SKIN = "tooltip"
-- Quite literally the global tooltip widget, because I'd rather not
-- recreate widgets everytime there's a tooltip (and there needs to be only one)
local DEFAULT_TOOLTIP = nil
----------------------------------------------------------
-- Base tooltip class
----------------------------------------------------------



local mui_tooltip = class()


mui_tooltip.TOOLTIPOFFSETX = 50
mui_tooltip.TOOLTIPOFFSETY = 30

mui_tooltip.TOOLTIP_PRIORITY = 10000000

function mui_tooltip:init( header, body, hotkey )
	self._headerTxt = header
	self._bodyTxt = body
    self._hotkey = hotkey
end

function mui_tooltip:activate( screen )
	self._screen = screen
	if DEFAULT_TOOLTIP == nil then
		DEFAULT_TOOLTIP = screen:createFromSkin( DEFAULT_TOOLTIP_SKIN )
	end
	self._tooltipWidget = DEFAULT_TOOLTIP

	self._screen:addWidget( self._tooltipWidget )
	self._tooltipWidget:updatePriority( self.TOOLTIP_PRIORITY )

	local tooltipLabel = self._tooltipWidget.binder.label
	if self._headerTxt then
		tooltipLabel:setText( string.format( "<ttheader>%s</>\n%s", self._headerTxt, self._bodyTxt or "" ))
	else
		tooltipLabel:setText( self._bodyTxt )
	end

	local hotkeyLabel = self._tooltipWidget.binder.hotkey
	if self._hotkey then
        local binding = util.getKeyBinding( self._hotkey )
        if binding then
            local hotkeyName = mui_util.getBindingName( binding )
		    hotkeyLabel:setText( string.format( "%s: <tthotkey>[ %s ]</>", STRINGS.UI.HUD_HOTKEY, hotkeyName ))
        else
            hotkeyLabel:setText( nil )
        end
	else
		hotkeyLabel:setText( nil )
	end
	local xmin_hotkey, ymin_hotkey, xmax_hotkey, ymax_hotkey = hotkeyLabel:getStringBounds()

	local W, H = self._screen:getResolution()
	-- String content bounds
	local xmin, ymin, xmax, ymax = tooltipLabel:getStringBounds()
	local x, y, w, h = tooltipLabel:calculateBounds()
	-- Full tooltip width and height, based off string contents bounds, in normalized UI space.
	local X_FUDGE_FACTOR = 6 / W -- This one exists because the string bounds may be inset from the actual label, a delta not easily determined here.
	local tw, th = math.max( xmax - xmin, xmax_hotkey - xmin_hotkey ), ymax - ymin
	tw = tw + 2 * math.abs(x) - w + X_FUDGE_FACTOR
	th = th + 2 * math.abs(y) - h

	local tooltipBg = self._tooltipWidget.binder.bg
	tooltipBg:setSize( W * tw, H * th )
	tooltipBg:setPosition( (W * tw) / 2, H * -th / 2 )
	--tooltipBg:setPosition( 0,0 )

	local footer = self._tooltipWidget.binder.border
	if #hotkeyLabel:getText() > 0 then
		footer:setVisible(true)
		th = th + 2 * (ymax_hotkey - ymin_hotkey)
		footer:setSize( W * tw, H * (ymax_hotkey - ymin_hotkey)+ 8 )	
		footer:setPosition(W * tw / 2, H * (-th + math.abs(ymax_hotkey - ymin_hotkey))  )
		hotkeyLabel:setPosition( nil, H * (-th + math.abs(ymax_hotkey - ymin_hotkey)) )
	else
		footer:setVisible(false)
	end

	

	self._tw, self._th = tw, th
end

function mui_tooltip:deactivate()
	self._screen:removeWidget( self._tooltipWidget )
	self._screen = nil
end

function mui_tooltip:fitOnscreen( tw, th, tx, ty )
	local XBUFFER, YBUFFER = 0.02, 0.02 -- Buffer from the edge of the screen

	local ox, oy = self._screen:wndToUI(mui_tooltip.TOOLTIPOFFSETX,mui_tooltip.TOOLTIPOFFSETY)
	-- Ensure the tooltip bounds are on screen.
	if tx < XBUFFER then
		tx = XBUFFER
	elseif tx + tw > 1.0 - XBUFFER then
		tx = tx - tw - XBUFFER - ox
	end
	if ty - th < YBUFFER then
		ty = ty + th + YBUFFER
	elseif ty > 1.0 - YBUFFER then
		ty = 1.0 - YBUFFER
	end

	-- Also ensure tx, ty are EVEN.  This is a horrible ramification of choosing widget positions to represent the
	-- centre: if the tooltip segments have an even width/height and their centre is chosen on an odd-pixel, then
	-- the widget extents land on a half-pixel boundary resulting usually in a one-pixel distortion.
	local W, H = self._screen:getResolution()
	tx, ty = math.floor(tx * W / 2) * (2 / W), math.floor(ty * H / 2) * (2 / H)

	return tx, ty
end

function mui_tooltip:setPosition( wx, wy )
	local tx, ty = self:fitOnscreen( self._tw, self._th, self._screen:wndToUI( wx + mui_tooltip.TOOLTIPOFFSETX, wy + mui_tooltip.TOOLTIPOFFSETY ))
	self._tooltipWidget:setPosition( tx, ty )

	if config.RECORD_MODE then
		self._tooltipWidget:setPosition(-1000,-1000)
	end
end

function mui_tooltip:getText()
	return self._tooltipWidget.binder.label:getText()
end

return mui_tooltip
