----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local color = include( "modules/color" )
local mui = include("mui/mui")
local mui_defs = include( "mui/mui_defs")
local mui_tooltip = include( "mui/mui_tooltip")
local hudtarget = include( "hud/targeting")
local world_hud = include( "hud/hud-inworld")
local cdefs = include( "client_defs" )
local rig_util = include( "gameplay/rig_util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

----------------------------------------------------------------
-- Local functions

local hud_tabs = class()

function hud_tabs:init( hud )
    self.hud = hud
    self._game = hud._game
    self._world_hud = hud._world_hud
    self._tabs = {}
end

function hud_tabs:destroyTab( tabID )
    local widget = self._tabs[ tabID ]
    if widget then
        self._tabs[ tabID ] = nil

	    widget.binder.anim:setAnim("out")
	    widget.binder.anim:getProp():setListener( KLEIAnim.EVENT_ANIM_END,
				    function( anim, animname )
					    if animname == "out" then
						    widget._world_hud:destroyWidget( "unitStatus", widget )
					    end
				    end )
    end
end

function hud_tabs:createTab( tabID, cellx, celly, tab )
    self:destroyTab( tabID )

    local text1, text2 = tab[1], tab[2]
	local wx, wy = self._game:cellToWorld( cellx, celly )
	local wz = 0
	local widget = self._world_hud:createWidget( "unitStatus", "unitStatus", { worldx = wx, worldy = wy, worldz = wz } )

    widget.tab = tab
	widget.binder.instructionsTxt:setVisible(false)	
	widget.binder.instructionsSubTxt:setVisible(false)	
	widget.binder.anim:setVisible(true)
	widget.binder.anim:setAnim("in")
	widget.binder.anim:getProp():setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim, animname )
					if animname == "in" then
						widget.binder.anim:setAnim("loop")
					end
				end )		

	widget.binder.instructionsTxt:setVisible(true)
	widget.binder.instructionsTxt:spoolText(util.toupper(text1),10)
	widget.binder.instructionsTxt:setColor(1,1,1,1)

	widget.binder.instructionsSubTxt:setVisible(true)
	widget.binder.instructionsSubTxt:spoolText(text2,10)

    self._tabs[ tabID ] = widget
	return widget	
end

function hud_tabs:refreshUnitTab( unit )
    local tab, unitID = unit:getTab(), unit:getID()
    if tab == nil then
        self:destroyTab( unitID )

    elseif self._tabs[ unitID ] == nil or self._tabs[ unitID ].tab ~= tab then
        local x0, y0 = unit:getLocation()
		self:createTab( unitID, x0, y0, tab )
    end
end

function hud_tabs:refreshAllTabs()
    local sim = self._game.simCore
    -- Find new/old tabs and refresh as necessary.
    for unitID, unit in pairs( sim:getAllUnits() ) do
        self:refreshUnitTab( unit )
    end

    -- TODO: Should destroy any tabs that shouldn't exist anymore.
    -- there shouldn't be any that are associated with despawned units though, atm.
end

return hud_tabs


