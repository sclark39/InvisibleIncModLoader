----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local gameobj = include( "modules/game" )
local simquery = include( "sim/simquery" )
local mui_defs = include( "mui/mui_defs")

-----------------------------------------------------------------------------------------
--

local COLOR_BLUE_DARK = util.color(50/255,87/255,87/255,150/255)
local COLOR_BLUE_LIGHT = util.color(150/255,255/255,255/255,1)

local COLOR_RED_DARK = util.color(80/255,0/255,0/255,150/255)
local COLOR_RED_LIGHT = util.color(163/255,0/255,0/255,1)

-----------------------------------------------------------------------------------------
--

local combat_panel = class()

function combat_panel:init( hud, screen )
	self._hud = hud
	self._screen = screen
	self._panel = screen.binder.combatPanel
end

function combat_panel:setPosition( x0, y0 )
	local width,height = self._screen:getResolution()
	local offset = 100/width 
	if x0 > 0.70 then
		offset=  - 100/width
	end
	y0 = math.min(math.max(y0,0.15),0.7)
	self._panel:setPosition(x0-0.5+ offset,y0-0.15)
end

function combat_panel:setVisible( visible )
    self._panel:setVisible( visible )
end

function combat_panel:refreshPanelFromStr( str, str2, bgcolor )
	local COLOR_RED_DARK = util.color(80/255,0/255,0/255,150/255)
	local COLOR_RED_LIGHT = util.color(163/255,0/255,0/255,1)

	self._panel:setVisible( true )
	self._panel.binder.damageTxt:setText( str )
	self._panel.binder.targetTxt:setText( str2 )
	
	if bgcolor then
		self._panel.binder.hitBackground:setColor( bgcolor:unpack() )  
	else
		self._panel.binder.hitBackground:setColor( COLOR_RED_DARK:unpack() )  
	end
	self._panel.binder.targetTxt:setColor(COLOR_RED_LIGHT:unpack())
	self._panel.binder.damageTxt:setColor(COLOR_RED_LIGHT:unpack())
end 

function combat_panel:refreshMelee( abilityOwner, unit, targetUnit )
    assert( unit and targetUnit )

	local sim = self._hud._game.simCore
	local color, textColor = COLOR_BLUE_DARK, COLOR_BLUE_LIGHT
    local meleeAbility = unit:hasAbility( "melee" )
    assert( meleeAbility ) -- Why are here with no melee ability?

    local ok, reason1, reason2 = meleeAbility:canUseAbility( sim, unit, unit, targetUnit:getID() )
    if ok then
        local weaponUnit = simquery.getEquippedMelee( unit )
    	local koDamage = simquery.calculateMeleeDamage(sim, weaponUnit, targetUnit)
		self._panel.binder.damageTxt:setText( util.sformat( STRINGS.FORMATS.AMT_KO, koDamage ))
    	self._panel.binder.targetTxt:setText( targetUnit:getName())

	else
        color, textColor = COLOR_RED_DARK, COLOR_RED_LIGHT
		self._panel.binder.damageTxt:setText( reason1 )
		self._panel.binder.targetTxt:setText( reason2 or targetUnit:getName() )
    end

	self._panel:setVisible( true )
    self._panel.binder.hitBackground:setColor(color:unpack())  
    self._panel.binder.targetTxt:setColor(textColor:unpack())
    self._panel.binder.damageTxt:setColor(textColor:unpack())
end

function combat_panel:refreshShoot( weaponUnit, unit, targetUnit )
    assert( unit and targetUnit )

	local sim = self._hud._game.simCore
	local color, textColor = COLOR_BLUE_DARK, COLOR_BLUE_LIGHT
	local shot = sim:getQuery().calculateShotSuccess( sim, unit, targetUnit, weaponUnit )

	local immune = false
	if shot.ko and not targetUnit:getTraits().canKO then 
		immune = true 
	end 

	if not sim:canUnitSeeUnit( unit, targetUnit ) then 
		self._panel.binder.damageTxt:setText( STRINGS.UI.COMBAT_PANEL_NO_LOS )		
		color = COLOR_RED_DARK
		textColor = COLOR_RED_LIGHT
	elseif weaponUnit:getTraits().canTag then
		self._panel.binder.damageTxt:setText( STRINGS.UI.COMBAT_PANEL_TAG )
	elseif immune then 
		self._panel.binder.damageTxt:setText( STRINGS.UI.COMBAT_PANEL_IMMUNE )
		color = COLOR_RED_DARK
		textColor = COLOR_RED_LIGHT		
	elseif shot.armorBlocked then 
		self._panel.binder.damageTxt:setText( STRINGS.UI.COMBAT_PANEL_ARMORED )
		color = COLOR_RED_DARK
		textColor = COLOR_RED_LIGHT		
	elseif shot.ko then
		self._panel.binder.damageTxt:setText( util.sformat( STRINGS.FORMATS.AMT_KO, shot.damage ))
	else 
		self._panel.binder.damageTxt:setText( STRINGS.UI.COMBAT_PANEL_KILL )
	end
	self._panel.binder.targetTxt:setText( targetUnit:getName())

	self._panel:setVisible( true )
    self._panel.binder.hitBackground:setColor(color:unpack())  
    self._panel.binder.targetTxt:setColor(textColor:unpack())
    self._panel.binder.damageTxt:setColor(textColor:unpack())
end

return combat_panel

