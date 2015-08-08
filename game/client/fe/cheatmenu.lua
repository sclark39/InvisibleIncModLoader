----------------------------------------------------------------
-- Copyright (c) 2014 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local version = include( "modules/version" )
local mui = include("mui/mui")
local mui_defs = include("mui/mui_defs")
local mui_util = include("mui/mui_util")
local cdefs = include( "client_defs" )
local modalDialog = include( "states/state-modal-dialog" )
local unitdefs = include( "sim/unitdefs" )

----------------------------------------------------------------
-- Cheat functions

local CHEATS =
{
    toggleUI =
    {
        set = function( value )
            mui.setVisible( value )
        end,

        get = function()
            return mui.isVisible()
        end,
    },   

    toggleLeakTracking =
    {
        set = function( value )
            DBG_STATE.isLeakTracking = value
           	MOAISim.setLeakTrackingEnabled( DBG_STATE.isLeakTracking )
            if not DBG_STATE.isLeakTracking then
           	    MOAISim.reportLeaks()
            end
        end,
        
        get = function()
            return DBG_STATE.isLeakTracking == true
        end,
    },

    printWidgets = function()
        local screens = mui.internals._activeScreens
        for k, screen in pairs(screens) do
	        print( k, screen._filename )
            local mx, my = inputmgr.getMouseXY()
            local x, y = screen:wndToUI( mx, my )
            local ev =  { x = x, y = y, screen = screen, eventType = mui_defs.EVENT_MouseMove }
            local props = screen._layer:propListForPoint( x, y, 0, MOAILayer.SORT_PRIORITY_DESCENDING)
            if props then
	            for i,prop in ipairs(props) do
		            if prop:shouldDraw() then
			            local cmp = screen._propToWidget[ prop ]
			            local widget = cmp._widget
			            local h = cmp:handleInputEvent( ev, prop )
                        local tt = widget:handleTooltip( ev.x, ev.y )
			            print( "\t", i, h, tostring(tt), cmp, widget:getPath(), prop )
		            end
	            end
            end
        end
    end,

    unlockAllRewards = function()
	    local user = savefiles.getCurrentGame()
	    local metadefs = include( "sim/metadefs" )

	    user.data.xp = metadefs.GetXPCap()
        user.data.storyWins = math.max( user.data.storyWins or 0, 1 )
        user.data.storyExperiencedWins = math.max( user.data.storyExperiencedWins or 0, 1 )
	    user:save()

	    return "Unlocked all rewards!"
    end,

    seeEverything = function()
	    if game then
		    game:doAction( "debugAction",
			    function( sim )
				    local cells = {}
				    sim:forEachCell(function(cell)
					    sim:getPC():glimpseCell( sim, cell )
					    table.insert( cells, cell.x )
					    table.insert( cells, cell.y )
				    end)
                    sim:forEachUnit(function(u)
                        sim:getPC():glimpseUnit( sim, u:getID() )
                    end)
				    sim:dispatchEvent( sim:getDefs().EV_LOS_REFRESH, { player = sim:getCurrentPlayer(), cells = cells } )
			    end )
	    end
    end,

    spawnUnit = function( templateName )
        if sim then
            local function fn( sim, templateName, x, y )
                local simfactory = include( "sim/simfactory" )
                local unitdefs = include( "sim/unitdefs" )
                local unitData = unitdefs.lookupTemplate( templateName )
		        local newItem = simfactory.createUnit( unitData, sim )
                if newItem:getTraits().isGuard then
                    newItem:setPlayerOwner(sim:getNPC() )
                    newItem:setPather(sim:getNPC().pather)
                elseif newItem:getTraits().isAgent then
                    newItem:setPlayerOwner(sim:getPC() )
                end					
                local cell = sim:getCell( x, y )
                if cell then
		            sim:spawnUnit( newItem )
		            sim:warpUnit( newItem, cell )
                end
                if newItem:getTraits().isGuard then
                    sim:getNPC():returnToIdleSituation(newItem)
                end                 
            end
            game:doAction( "debugAction", fn, templateName, cx, cy )
        end
    end,

    spawnProgram = function( programName )
        if sim then
            local function fn( sim, programName )
                
                local maxPrograms = sim:getDefs().MAX_PROGRAMS  + (sim:getParams().agency.extraPrograms or 0)

            	if #sim:getPC():getAbilities() < maxPrograms then
                    sim:getPC():addMainframeAbility( sim, programName )
                end
            end
            game:doAction( "debugAction", fn, programName )
        end
    end,

    spawnDaemon = function( daemonName )
        if sim then
            local function fn( sim, daemonName )
                sim:getNPC():addMainframeAbility(sim, daemonName, sim:getNPC() )
            end
            game:doAction( "debugAction", fn, daemonName )
        end
    end,

    spawnLocation = function( tags )
        local states = statemgr.getStates()
        for i = 1, #states do
            if states[i].spawnSituation then
                states[i]:spawnSituation( tags )
                break
            end
        end
    end,

    teleportSelected = function()
	    if game then
		    local selectedUnitID = game.hud:getSelectedUnit() and game.hud:getSelectedUnit():getID()
		    if selectedUnitID and sim:getUnit( selectedUnitID ) then
			    local x, y = game:wndToCell( inputmgr:getMouseXY() )
			    local function fn( sim, unitID, x, y )
				    local unit = sim:getUnit( unitID )
				    local cell = sim:getCell( x, y )
				    if cell and cell ~= sim:getCell( unit:getLocation() ) then
					    sim:warpUnit(unit, cell)
				    end
				    sim:processReactions(unit)
			    end

			    game:doAction( "debugAction", fn, selectedUnitID, x, y )
		    end
	    end
    end,

    simKill = function()
	    if sim then
		    local function fn( sim, x, y )
			    local cell = sim:getCell( x, y )
			    if cell and cell.units[1] then
				    cell.units[1]:killUnit( sim )
			    end
		    end
		    game:doAction( "debugAction", fn, cx, cy )
	    end
    end,

    simKO = function()
        if sim then
            local function fn( sim, x, y )
                local cell = sim:getCell( x, y )
                if cell and cell.units[1] then
                    cell.units[1]:setKO(sim, 3)
                end
            end
            game:doAction( "debugAction", fn, cx, cy )
        end
    end,
}


----------------------------------------------------------------
-- Locals

local cheat_item = class()

function cheat_item:init( name, fn, ... )
    self.name = name
    self.fn = fn
    self.fnParams = { ... }
end

function cheat_item:getName()
    return self.name
end

function cheat_item:createWidget( cheatmenu )
    local widget = cheatmenu.listbox:addItem( self )
    widget.binder.txt:setText( self:getName() )
    return widget
end

function cheat_item:onActivate( cheatmenu )
    cheatmenu:executeBinding( self:getName(), self.fn, self.fnParams )
end

local cheat_toggle = class( cheat_item )

function cheat_toggle:init( name, toggleFn )
    assert( type(toggleFn.get) == "function" and type(toggleFn.set) == "function" )

    cheat_item.init( self, name )
    self.toggleFn = toggleFn
end

function cheat_toggle:createWidget( cheatmenu )
    local widget = cheatmenu.listbox:addItem( self )
    setfenv( self.toggleFn.get, cheatmenu.debugenv )
    if self.toggleFn.get() then
        widget.binder.txt:setText( "[X] "..self:getName() )
    else
        widget.binder.txt:setText( "[ ] "..self:getName() )
    end
    return widget
end

function cheat_toggle:onActivate( cheatmenu )
    cheatmenu:executeBinding( self:getName(), self.toggleFn.set, { not self.toggleFn.get() } )
    cheatmenu:refreshListbox()
end

function cheat_toggle:onClick( cheatmenu )
    self:onActivate( cheatmenu )
end


local cheat_submenu = class( cheat_item )

function cheat_submenu:init( name, submenu )
    self.name = name
    self.submenu = submenu
end

function cheat_submenu:getName()
    return self.name .. " >>"
end

function cheat_submenu:getChild( i )
    if type(self.submenu[i]) == "string" then
        return cheat_item( self.submenu[i] )
    else
        return self.submenu[i]
    end   
end

function cheat_submenu:onClick( cheatmenu )
    self:onActivate( cheatmenu )
end

function cheat_submenu:onActivate( cheatmenu )
    cheatmenu:pushMenu( self )
end

local spawn_menu = class( cheat_submenu )

function spawn_menu:init( name, defs )
    local submenu = {}
    for k, unitData in pairs( defs ) do
        table.insert( submenu, cheat_item( string.format( "%s (%s)", k, unitData.name ), CHEATS.spawnUnit, k ))
    end
    table.sort( submenu, function( s1, s2 ) return s1:getName() < s2:getName() end )

    cheat_submenu.init( self, name, submenu )
end

local spawn_program_menu = class( cheat_submenu )

function spawn_program_menu:init( name )
    local submenu = {}
    local mainframe_abilities = include( "sim/abilities/mainframe_abilities" )
    for programName, ability in pairs( mainframe_abilities ) do
        table.insert( submenu, cheat_item( string.format( "%s (%s)", programName, ability.name ), CHEATS.spawnProgram, programName ))
    end
    table.sort( submenu, function( s1, s2 ) return s1:getName() < s2:getName() end )

    cheat_submenu.init( self, name, submenu )
end

local spawn_daemon_menu = class( cheat_submenu )

function spawn_daemon_menu:init( name )
    local submenu = {}
    local npc_abilities = include( "sim/abilities/npc_abilities" )
    for daemonName, ability in pairs( npc_abilities ) do
        table.insert( submenu, cheat_item( string.format( "%s (%s)", daemonName, ability.name ), CHEATS.spawnDaemon, daemonName ))
    end
    table.sort( submenu, function( s1, s2 ) return s1:getName() < s2:getName() end )

    cheat_submenu.init( self, name, submenu )
end

local spawn_location_menu = class( cheat_submenu )

function spawn_location_menu:init( name )
    local submenu = {}
    local serverdefs = include( "modules/serverdefs" )
    for j, corpName in pairs( serverdefs.CORP_NAMES ) do
        for i, tag in ipairs( serverdefs.ESCAPE_MISSION_TAGS ) do
            local tags = { tag, corpName }
            table.insert( submenu, cheat_item( corpName.." "..tag, CHEATS.spawnLocation, tags ))
        end
    end
    table.sort( submenu, function( s1, s2 ) return s1:getName() < s2:getName() end )

    cheat_submenu.init( self, name, submenu )
end

----------------------------------------------------------------
-- Cheat menu definition

local CHEAT_MENU = cheat_submenu( "*",
{
    cheat_item( "Unlock Rewards", CHEATS.unlockAllRewards ),
    cheat_item( "Reveal All", CHEATS.seeEverything ),
    cheat_item( "Teleport Unit (Selected)", CHEATS.teleportSelected ),
    cheat_item( "Kill Unit (Mouse Over)", CHEATS.simKill ),
    cheat_item( "KO Unit (Mouse Over)", CHEATS.simKO ),
    cheat_submenu( "Spawn Units",
        {
            spawn_menu( "Items", unitdefs.tool_templates ),
            spawn_menu( "Props", unitdefs.prop_templates ),
            spawn_menu( "Guards", unitdefs.npc_templates ),
            spawn_menu( "Agents", unitdefs.agent_templates ),
        }),
    spawn_program_menu( "Spawn Programs" ),
    spawn_daemon_menu( "Spawn Daemons" ),
    spawn_location_menu( "Spawn Location" ),
    cheat_submenu( "UI",
        {
            cheat_toggle( "Show UI", CHEATS.toggleUI ),
            cheat_item( "Print Widgets (Mouse Over)", CHEATS.printWidgets ),
        }),
    cheat_submenu( "Programmer",
        {
            cheat_toggle( "Track Leaks", CHEATS.toggleLeakTracking )
        })
})

local function onItemSelected( cheatmenu, old_idx, new_idx, cheatItem )
    local item = cheatmenu.listbox:getItem( old_idx )
    if item then
        item.widget.binder.bg:setColor( 0, 0, 0, 0.4 )
    end

    local item = cheatmenu.listbox:getItem( new_idx )
    if item then
        item.widget.binder.bg:setColor( 1, 0, 0, 0.4 )
    end
    
    -- Preserve last selected index for this menu
    local menu = cheatmenu.menuStack[ #cheatmenu.menuStack ]
    cheatmenu.lastSelection[ menu ] = new_idx
end


local function onItemClicked( cheatmenu, idx, cheatItem )
    if cheatItem.onClick then
        cheatmenu.debugenv:updateEnv()
        cheatItem:onClick( cheatmenu, cheatmenu.debugenv )
    end
end

function executeBinding( name, debugenv, fn, fnParams )
	log:write("-START BINDING [%s]---", name )
	setfenv( fn, debugenv )
	local res, msg = xpcall(
		function()
            if fnParams then
                return fn( unpack(fnParams) )
            else
                return fn()
            end
        end,
		function( msg )	log:write( "ERR: %s", tostring(msg) ) log:write( debug.traceback() ) end )

	if res and msg then
		local thread = MOAICoroutine.new()
		thread:run( modalDialog.show, msg, "Debug" )
		thread:resume()
	end

	log:write("-END BINDING-----------------------")    
end
----------------------------------------------------------------
-- Cheat menu

local cheatmenu = class()

function cheatmenu:init( screen, debugenv )
    self.screen = screen
    self.debugenv = debugenv
    self.listbox = screen.binder.listbox
    self.listbox.onItemSelected = util.makeDelegate( nil, onItemSelected, self )
    self.listbox.onItemClicked = util.makeDelegate( nil, onItemClicked, self )

    self.menuStack = {}
    self.lastSelection = {}

    self:pushMenu( CHEAT_MENU )
    self:refresh()
end

function cheatmenu:getHeader()
    local headerTxt = ""
    for i, menu in ipairs( self.menuStack ) do
        headerTxt = headerTxt .. menu:getName() .. " "
    end
    return headerTxt
end

function cheatmenu:refreshListbox()
    local menu = self.menuStack[ #self.menuStack ]
    local lastSelection = self.lastSelection[ menu ] or 1
    self.listbox:clearItems()

    local i, menuItem = 1, menu:getChild( 1 )
    while menuItem ~= nil do
        local widget = menuItem:createWidget( self )
        i, menuItem = i + 1, menu:getChild( i + 1 )
    end

    self.listbox:selectIndex( lastSelection )
end

function cheatmenu:setVisible( isVisible )
    self.listbox:setVisible( isVisible )
end

function cheatmenu:clear()
    self.listbox:clearItems()
end

function cheatmenu:refresh()
    self:refreshListbox()
end

function cheatmenu:executeBinding( name, fn, fnParams )
    executeBinding( name, self.debugenv, fn, fnParams )
end

function cheatmenu:pushMenu( menu )
    assert( type(menu) == "table" )
    table.insert( self.menuStack, menu )
    self:refresh()
end

function cheatmenu:popMenu()
    table.remove( self.menuStack )
    self:refresh()
end

function cheatmenu:onInputEvent( event )
    if self.listbox:isVisible() then
	    if event.eventType == mui_defs.EVENT_KeyDown and event.key == mui_defs.K_BACKSPACE then
            if #self.menuStack > 1 then
                self:popMenu()
            end
            return true

        elseif event.eventType == mui_defs.EVENT_KeyDown and event.key == mui_defs.K_DOWNARROW then
            local idx = self.listbox:getSelectedIndex()
            local itemCount = self.listbox:getItemCount()
            self.listbox:selectIndex( math.max( 1, math.min( itemCount, (idx or 0) + 1 )))
            return true

        elseif event.eventType == mui_defs.EVENT_KeyDown and event.key == mui_defs.K_UPARROW then
            local idx = self.listbox:getSelectedIndex()
            local itemCount = self.listbox:getItemCount()
            self.listbox:selectIndex( math.max( 1, math.min( itemCount, (idx or itemCount) - 1)))
            return true

        elseif event.eventType == mui_defs.EVENT_KeyDown and event.key == mui_defs.K_ENTER then
            local cheatItem = self.listbox:getSelectedUserData()
            if cheatItem then
                self.debugenv:updateEnv()
                cheatItem:onActivate( self  )
            end
            return true
        end
    end

    return false
end

return util.extend( CHEATS )
{
    menu = cheatmenu,
    executeBinding = executeBinding,
}

