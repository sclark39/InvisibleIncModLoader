----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local animmgr = include( "anim-manager" )
local cdefs = include( "client_defs" )
local util = include( "modules/util" )
local binops = include( "modules/binary_ops" )
local unitrig = include( "gameplay/unitrig" )
local rig_util = include( "gameplay/rig_util" )

--------------------------------------------------------------------------------------
-- new school

local item_rig = class( unitrig.rig )

function item_rig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )
end

function item_rig:refresh( )
	self:_base().refresh( self )
	local gfxOptions = self._boardRig._game:getGfxOptions()
	if gfxOptions.bMainframeMode or gfxOptions.bTacticalView then
		self._prop:setCurrentAnim( "Icon" )
	else
		self._prop:setCurrentAnim( self._kanim.anim or "idle" )
	end
end

--------------------------------------------------------------------------------------
-- Old school

local itemtex_rig = class()

function itemtex_rig:init( boardRig, unitData, unitID )
	local unitTex = resources.find( unitData.icon )
	if unitTex == nil then
		unitTex = MOAIGfxQuad2D.new ()
		assert( unitData.icon, string.format("%s does not have an icon specified.", unitData.name))
		unitTex:setTexture ( resources.getPath(unitData.icon) )
		unitTex:setRect ( -16, -16, 16, 16 )
		resources.insertResource( unitData.icon, unitTex )
	end

	local prop = MOAIProp2D.new ()
	prop:setDeck(unitTex)
	prop:setBillboard( true )
		
	prop:setDebugName( unitData.name )

	self._boardRig = boardRig
	self._prop = prop
	self._unitID = unitID
	self._isVisible = nil

	if not unitData.nolocator then
		local COLOR = { 121/255, 218/255, 217/255, 1 }
		self._HUDlocated = self:createHUDProp("kanim_hud_agent_hud", "item", "start", boardRig:getLayer("ceiling"), self._prop )
		self._HUDlocated:setListener( KLEIAnim.EVENT_ANIM_END,
					function( anim, animname )
						if animname == "start" then
							anim:setCurrentAnim("loop")
						end

					end )
		self._HUDlocated:setSymbolModulate("shockwave", unpack(COLOR) )
		self._HUDlocated:setSymbolModulate("ring5", unpack(COLOR) )
		self._HUDlocated:setVisible(false)
	end
end

function itemtex_rig:getLocation( )
	return self._x, self._y
end

function itemtex_rig:setLocation( x, y )
	if self._x ~= x or self._y ~= y then
		self._x = x
		self._y = y
	end
end

function itemtex_rig:isVisible()
	return self._isVisible
end

function itemtex_rig:getUnit( )
	return self._boardRig:getLastKnownUnit( self._unitID )
end

function itemtex_rig:destroy()
	if self._HUDlocated then
		self._boardRig:getLayer("ceiling"):removeProp( self._HUDlocated )
	end
	if self._isVisible then
		self._boardRig:getLayer("floor"):removeProp( self._prop )
	end
end

function itemtex_rig:generateTooltip( debugMode )
	local unit = self:getUnit()
	return string.format( "<debug>%s [%d]</>\n", util.toupper(unit:getName()), self._unitID )
end


function itemtex_rig:refresh( )
	self:refreshLocation()
	self:refreshHUD()
    self:refreshProp()
end

function itemtex_rig:refreshProp()
    self:refreshRenderFilter()
end

function itemtex_rig:refreshHUD()
	if self._HUDlocated then
		local x, y = self:getLocation()
		if x and y and self._boardRig:canPlayerSee(x,y) then
			if not self._HUDlocated:getVisible() then
				self._HUDlocated:setVisible(true)
				self._HUDlocated:setCurrentAnim("start")
			end
		else
			self._HUDlocated:setVisible(false)
		end
	end
end

function itemtex_rig:refreshRenderFilter()
	if self:getLocation() then
		local cell = self._boardRig:getLastKnownCell( self:getLocation() )

		if cell then
			local gfxOptions = self._boardRig._game:getGfxOptions()

            if gfxOptions.bTacticalView then
                self._prop:setShader( MOAIShaderMgr.getShader( MOAIShaderMgr.FLAT_SHADER ))
                self._prop:setColor( 0.5, 0.5, 0, 1 )

            else
                self._prop:setShader( nil )

			    if not cell.ghostID or not gfxOptions.bFOWEnabled then
				    self._prop:setColor( 1, 1, 1 )
			    else
				    self._prop:setColor( 1, 0.2, 0.2 )
			    end
            end
		end
	end
end

function  itemtex_rig:createHUDProp(kanim, symbolName, anim, layer, unitProp )

	local prop = animmgr.createPropFromAnimDef( kanim )
	prop:setCurrentSymbol(symbolName)
	if anim then	
		prop:setCurrentAnim( anim )
	end
	prop:setAttrLink( MOAIProp.INHERIT_LOC, unitProp, MOAIProp.TRANSFORM_TRAIT)
	prop:setAttrLink( MOAIProp.ATTR_VISIBLE, unitProp, MOAIProp.ATTR_VISIBLE)
	prop:setBounds( -cdefs.BOARD_TILE_SIZE, -cdefs.BOARD_TILE_SIZE, 0, cdefs.BOARD_TILE_SIZE, cdefs.BOARD_TILE_SIZE, 0 )

	if layer == true or layer == false then
		unitProp:insertProp( prop, layer )
	else
		layer:insertProp( prop )
	end

	return prop
end

function itemtex_rig:startTooltip()
end

function itemtex_rig:stopTooltip()
end

function itemtex_rig:refreshLocation()
	local unit = self:getUnit()

	self._facing = unit:getFacing()
	self:setLocation( unit:getLocation() )

	local isVisible = self._x ~= nil
	if isVisible and unit:getPlayerOwner() ~= self._boardRig:getLocalPlayer() then
		isVisible = not unit:getTraits().invisible and self._boardRig:canPlayerSee( unit:getLocation() )
	end

	if self._x and self._y then
		self._prop:setLoc( self._boardRig:cellToWorld( self._x, self._y ) )
	end

	isVisible = isVisible or unit:isGhost()

	local gfxOptions = self._boardRig._game:getGfxOptions()
	if gfxOptions.bMainframeMode and unit:getUnitData().nolocator then
		isVisible = false
	end

	if isVisible and not self._isVisible then
		self._boardRig:getLayer("floor"):insertProp( self._prop )
	elseif not isVisible and self._isVisible then
		self._boardRig:getLayer("floor"):removeProp( self._prop )
	end

	self._isVisible = isVisible
end

function itemtex_rig:onSimEvent( ev, eventType, eventData )
	local simCore = self._boardRig._game.simCore
	local simdefs = simCore:getDefs()
	
    if eventType == simdefs.EV_UNIT_REFRESH or eventType == simdefs.EV_UNIT_WARPED then
		self:refresh()
		self:refreshRenderFilter()

	elseif eventType == simdefs.EV_UNIT_THROWN then
		local x1, y1 = self._boardRig:cellToWorld(eventData.x, eventData.y)
		rig_util.throwToLocation(self, x1, y1)
		local unit = self:getUnit()
		if unit:getSounds() and unit:getSounds().bounce then
			self._boardRig:getSounds():playSound(unit:getSounds().bounce)
		end
		self:refreshHUD()
	end
end


--------------------------------------------------------------------------------------
--

local function createRig( boardRig, unit )
	--log:write( "ITEM RIG -- %s", unitData.name )	

	if animmgr.lookupAnimDef( unit:getUnitData().kanim ) then
		return item_rig( boardRig, unit )
	else
		return itemtex_rig( boardRig, unit:getUnitData(), unit:getID() )
	end
end

return
{
    createRig = createRig
}

