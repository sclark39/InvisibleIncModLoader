----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local world_hud = include( "hud/hud-inworld" )

--------------------------------------------------------------------
-- Local functions
local LOWER_BRAIN_Y = -35
local NORMAL_BRAIN_Y = -2

local function onUpdateFlag( screen, widget )
	local self = widget.flag
	local rig = self._rig
	local unit = widget.unit

	-- Zoom scaling.
	--[[ ccc: disabling; scaling destroys the 2-pixel border around the flag and looks fugly.
	local zoom = self._rig._boardRig._game:getCamera():getZoom()
	zoom = math.max( 0.5, math.min( 2, math.sqrt( 0.4 / zoom )))
	self._widget:setScale( zoom, zoom )
	--]]

	if (unit:isKO() and not unit:isDead()) or unit:getTraits().takenDrone then
		self._framet = self._framet + 1
		if self._framet % 120 == 0 then
			-- Show KO marker.
			widget.binder.statusImg:setVisible( true )
			widget.binder.timerTxt:setVisible( false )
		elseif self._framet % 60 == 0 then
			-- Show KO timer.
			widget.binder.statusImg:setVisible( false )
			widget.binder.timerTxt:setVisible( true )
		end
	else
		widget.binder.statusImg:setVisible( true )
		widget.binder.timerTxt:setVisible( false )
	end

	local x, y = rig._prop:getLoc()
	local wx, wy = rig._boardRig._game:worldToWnd( x, y, 64 )


	widget:setPosition( screen:wndToUI( wx, wy ))
    if self._speechWidget then
        self._speechWidget:setPosition( screen:wndToUI( wx, wy ))
    end
end

--------------------------------------------------------------------
-- flag UI

local flagui = class()

function flagui:init( rig, unit )
	self._rig = rig
	self._framet = 0
	self._selected = false
	self._widget = self:getWorldHud():createWidget( world_hud.FLAGS, "Flag", { flag = self, unit = unit }, onUpdateFlag )
	self._widget:setAlias("flag"..unit:getID())
end

function flagui:getWorldHud()
	local game = self._rig._boardRig._game
	if game.hud then
		return game.hud._world_hud -- omg.
	end
end

function flagui:destroy()
	local hud = self:getWorldHud()
	if hud then	-- hud is destroyed before boardRigs, so on shutdown this might not exist
		hud:destroyWidget( world_hud.FLAGS, self._widget )
		self._widget = nil
	end
end

function flagui:setVisible( isVisible )
	self._widget:setVisible( isVisible )
end

function flagui:previewMovement( moveCost )
	self._moveCost = moveCost
	self:refreshFlag()
end

function flagui:refreshFlag( unit, isSelected )

	unit = unit or self._rig:getUnit()

	local gfxOptions = self._rig._boardRig._game:getGfxOptions()
	local flagVisible = not gfxOptions.bMainframeMode and self._rig:isVisible()
	self:setVisible( flagVisible )
	if not flagVisible then
		return
	end

	self._widget.binder.brain.binder.shieldIcon:setVisible(false)
	self._widget.binder.brain.binder.shadowShield:setVisible(false)
	self._widget.binder.brain.binder.armorTxt:setVisible(false)

	-- Refresh hp and maxhp.
	self._widget.binder.brain:setVisible(false)
	if  unit:getArmor() > 0 then
		self._widget.binder.armor:setVisible(true)		
		self._widget.binder.armor.binder.armorTxt:setVisible(true)
		self._widget.binder.armor.binder.armorTxt:setText(unit:getArmor())
	
		self._widget.binder.brain.binder.shieldIcon:setVisible(true)
		self._widget.binder.brain.binder.shadowShield:setVisible(true)
		self._widget.binder.brain.binder.armorTxt:setVisible(true)
		self._widget.binder.brain.binder.armorTxt:setText(unit:getArmor())		
	else
		self._widget.binder.armor:setVisible(false)
	end
	local showSubBG = false

	-- CHECK FOR WHICH ICON TO DISPLAY IF ANY
	if unit:isDead() then
		self._widget.binder.brain.binder.statusImg:setImageState( "dead" )
		self._widget.binder.brain.binder.ring:setTooltip(STRINGS.UI.FLAG_DEAD_TT)
		showSubBG = true
	elseif unit:isKO() then
		if simquery.isUnitPinned( self._rig._boardRig._game.simCore, unit ) or simquery.isUnitDragged( self._rig._boardRig._game.simCore, unit ) then 
			self._widget.binder.brain.binder.statusImg:setImageState( "pinned" )
			self._widget.binder.brain.binder.ring:setTooltip( util.sformat( STRINGS.UI.FLAG_KO_PIN_TT, unit:getTraits().koTimer ))
		else
			self._widget.binder.brain.binder.statusImg:setImageState( "ko" )
			self._widget.binder.brain.binder.ring:setTooltip( util.sformat( STRINGS.UI.FLAG_KO_TT, unit:getTraits().koTimer ))
		end
		if unit:getTraits().paralyzed then
			self._widget.binder.brain.binder.timerTxt:setText( tostring("--") )
		else
			self._widget.binder.brain.binder.timerTxt:setText( tostring(unit:getTraits().koTimer) )
		end
		showSubBG = true
	elseif unit:getTraits().takenDrone then 
		self._widget.binder.brain.binder.statusImg:setImageState( "channeling" )
		self._widget.binder.brain.binder.ring:setTooltip( util.sformat( STRINGS.UI.FLAG_CONTROL_TT, unit:getTraits().controlTimer ))
		self._widget.binder.brain.binder.timerTxt:setText( tostring(unit:getTraits().controlTimer) )
		showSubBG = true
	elseif unit:getTraits().thoughtVis then
		self._widget.binder.brain.binder.statusImg:setImageState( unit:getTraits().thoughtVis )
		self._widget.binder.brain.binder.ring:setTooltip( STRINGS.UI.THOUGHTVIS_TOOLTIPS[ unit:getTraits().thoughtVis ])
		showSubBG = true
	else
		self._widget.binder.brain.binder.statusImg:setImageState( "none" )
        showSubBG = self._speechWidget ~= nil
	end


	if unit:getPlayerOwner():isNPC() or unit:isKO() or unit:getTraits().takenDrone then
		self._widget.binder.meters:setVisible(false)

		--move it down if you are KO
		local x, y = self._widget.binder.brain:getPosition()
		if unit:isKO() then
			self._widget.binder.brain:setPosition(x, LOWER_BRAIN_Y)
		else
			self._widget.binder.brain:setPosition(x, NORMAL_BRAIN_Y)
		end

		if showSubBG == true then
			self._widget.binder.brain:setVisible(true)
			self._widget.binder.armor:setVisible(false)
			
			if unit:getArmor() > 0  then
				self._widget.binder.brain.binder.armor:setVisible(false)
			else
				self._widget.binder.brain.binder.armor:setVisible(false)
			end
			
			if unit:getPlayerOwner():isNPC() then
				if simquery.isUnitPinned( self._rig._boardRig._game.simCore, unit ) then 
					self._widget.binder.brain.binder.ring:setColor(0/255,255/255,0/255,1)
					self._widget.binder.brain.binder.statusImg:setColor(255/255,255/255,255/255,1)
					self._widget.binder.brain.binder.timerTxt:setColor(255/255,255/255,255/255,1)
				else 
					if unit:getTraits().thoughtVis and unit:getTraits().thoughtVis == "investigating" then
						self._widget.binder.brain.binder.ring:setColor(255/255,255/255,0/255,1)
						self._widget.binder.brain.binder.statusImg:setColor(0/255,0/255,0/255,1)
						self._widget.binder.brain.binder.timerTxt:setColor(0/255,0/255,0/255,1)
					else
						self._widget.binder.brain.binder.ring:setColor(255/255,0/255,0/255,1)
						self._widget.binder.brain.binder.statusImg:setColor(255/255,255/255,255/255,1)
						self._widget.binder.brain.binder.timerTxt:setColor(255/255,255/255,255/255,1)
						--self._widget.binder.brain.binder.statusImg:setColor(245/255,127/255,16/255,1)
						--self._widget.binder.brain.binder.timerTxt:setColor(245/255,127/255,16/255,1)
					end
				end 
			else				
				self._widget.binder.brain.binder.ring:setColor(140/255,255/255,255/255,1)
				self._widget.binder.brain.binder.statusImg:setColor(1,1,1,1)
				self._widget.binder.brain.binder.timerTxt:setColor(1,1,1,1)				
			end				
		end
	else		
		self._widget.binder.meters:setVisible(true)

		local sim = self._rig._boardRig._game.simCore

		if sim:getCurrentPlayer() == unit:getPlayerOwner() then
			local ap = math.floor( math.max( 0, unit:getMP() - (self._moveCost or 0) ))
			self._widget.binder.meters.binder.APnum:setText( ap )

		else
			self._widget.binder.meters.binder.APnum:setText( "--" )
		end

		local color
		local hud = self._rig._boardRig._game.hud
		
		self._widget.binder.meters.binder.selected:setVisible(false)
		if hud and hud:getSelectedUnit() == unit then
			color = {r=1,g=1,b=1,a=1}
			self._widget.binder.meters.binder.selected:setVisible(true)
		else
			if unit:isAiming() or unit:getTraits().isMeleeAiming then
				color = {r=244/255,g=128/255,b=17/255,a=1}
			else							
				color = {r=140/255,g=255/255,b=255/255,a=1}
			end
		end
		



		if unit:isAiming() or unit:getTraits().isMeleeAiming then
			self._widget.binder.meters.binder.overwatch:setVisible(true)
			self._widget.binder.meters.binder.overwatch:setColor(color.r,color.g,color.b,color.a)
		else 
			self._widget.binder.meters.binder.overwatch:setVisible(false)
		end

		if (self._moveCost or 0) < 0 then 
			self._widget.binder.meters.binder.APnum:setColor( cdefs.AP_COLOR_PREVIEW_BONUS:unpack() )
			self._widget.binder.meters.binder.APtxt:setColor( cdefs.AP_COLOR_PREVIEW_BONUS:unpack() )
		elseif (self._moveCost or 0) ~= 0 then
			self._widget.binder.meters.binder.APnum:setColor( cdefs.AP_COLOR_PREVIEW:unpack() )
			self._widget.binder.meters.binder.APtxt:setColor( cdefs.AP_COLOR_PREVIEW:unpack() )
		else
			self._widget.binder.meters.binder.APnum:setColor(color.r,color.g,color.b,color.a)
			self._widget.binder.meters.binder.APtxt:setColor(color.r,color.g,color.b,color.a)
		end

		self._widget.binder.meters.binder.bg:setColor(color.r,color.g,color.b,color.a)
	end

	-- Selection Color
	if isSelected ~= nil then
		self._selected = isSelected
	end

end

function flagui:moveToFront()
	self:getWorldHud():moveToFront( self._widget )
end

function flagui:showSpeech()
	self._widget.binder.brain.binder.speech:setVisible(true)

    self:refreshFlag()

end

function flagui:hideSpeech()
	self._widget.binder.brain.binder.speech:setVisible(false)
	self:refreshFlag()
end

return flagui
