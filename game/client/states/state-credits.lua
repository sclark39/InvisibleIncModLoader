----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include("modules/util")
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local mui_util = include( "mui/mui_util" )
local rig_util = include( "gameplay/rig_util" )
local cdefs = include("client_defs")

----------------------------------------------------------------
local CREDIT_COLOR = { 244/255, 255/255, 120/255, 255/255 }
local HEADER_COLOR = { 244/255, 255/255, 120/255, 255/255 }
local EXTERNAL_COLOR = { 1,1,1,1 }

local HELP_LINES =
{
    "help",
    "cls",
    "quit",
    "version",
    "localize",
}
local PROMPT_STR = "> "
local MAX_LINES = 18
local FADE_TIME = 0.5*cdefs.SECONDS

local function onClickDone( self )
    MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
	statemgr.deactivate( self )
end

local function clearLines( self )
    util.tclear( self.lines )
    self.screen.binder.creditNames:setText( "" )
end

local function addLine( self, line )
    table.insert( self.lines, line )
    while #self.lines > MAX_LINES do
        table.remove( self.lines, 1 )
    end

    self.screen.binder.creditNames:setText( table.concat( self.lines, "\n" ))
    self.screen.binder.creditNames:spoolText()
end

local function addLines( self, lines )
    for i, line in ipairs( lines ) do
        table.insert( self.lines, line )
    end
    while #self.lines > MAX_LINES do
        table.remove( self.lines, 1 )
    end
    self.screen.binder.creditNames:setText( table.concat( self.lines, "\n" ))
    self.screen.binder.creditNames:spoolText()
end

local function onEditCommand( self, txt )
    addLine( self, "" )
    addLine( self, txt )

    local cmd = txt:match( "^" .. PROMPT_STR .. "%s*([^%s]+)" )
    print( "CMD:", txt )

    if cmd == "?" or cmd == "help" then
        addLines( self, HELP_LINES )
    elseif cmd == "quit" then
    	statemgr.deactivate( self )
    elseif cmd == "cls" then
        clearLines( self )
    elseif cmd == "version" then
        addLine( self, util.formatGameInfo() )
    elseif cmd == "localize" then
        local loc_translator = include( "loc_translator" )
        loc_translator.generatePot()
        addLine( self, "Generated strings.pot in the game directory." )
    elseif cmd == "unlockall" then
        local user = savefiles.getCurrentGame()
	    local metadefs = include( "sim/metadefs" )
	    user.data.xp = metadefs.GetXPCap()
        user.data.storyWins = math.max( user.data.storyWins or 0, 1 )
        user.data.storyExperiencedWins = math.max( user.data.storyExperiencedWins or 0, 1 )
	    user:save()
        addLine( self, "Unlocked all rewards." )

    else
        addLine( self, "Unknown command." )
    end

    self.editTxt:setText( PROMPT_STR )
	self.editTxt:startEditing( mui_defs.EDIT_CMDPROMPT )
end

--------------------------------------------------------------------
-- 

-- Wait for some time.
local function creditsWait( seconds )
    rig_util.wait( cdefs.SECONDS * seconds )
end

-- Fade some widgets over time
local function creditsFade( alphaStep, color, ... )
    local alpha = 0
    if alphaStep < 0 then
        alpha = 255 -- Fading out!
    end

    while (alphaStep < 0 and alpha >= 0) or (alphaStep > 0 and alpha <= 255) do
        for i, widget in ipairs({...}) do
            for j, child in widget.binder:forEach( "child" ) do
                if child.setColor then
                    child:setColor( color[1], color[2], color[3], alpha/255 )
                end
            end
            for k, header in widget.binder:forEach( "header" ) do
                if header.setColor then
                    header:setColor( HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3], alpha/255 )
                end
            end
        end
        alpha = alpha + alphaStep
        coroutine.yield()
    end
end

-- Spawn a widget template for a duration.
local function creditsTemplate( screen, duration, wx, wy, skinName, txt )
    local widget = screen:createFromSkin( skinName, { xpx = true, ypx = true, anchor = 0 } )
    widget:setPosition( wx, wy )
    screen:addWidget( widget )

    creditsFade( 10, EXTERNAL_COLOR, widget )

    while duration > 0 do
        coroutine.yield()
        duration = duration - 1
    end

    local fadeStep = 255 / FADE_TIME
    creditsFade( -fadeStep, EXTERNAL_COLOR, widget )

    screen:removeWidget( widget )
end

-- Spool a list of names.
local function creditsNames( screen, duration, wx, wy, anchor, lines )
    local SPOOL_SPEED = 30 -- no idea; higher is faster
    local NAMES_SPACING_Y = -52 -- pixels
    local NAMES_SPACING_X = 46 -- pixels

    local widgets = {}
    for i, line in ipairs(lines) do
        local widget = screen:createFromSkin( "CreditsLine", { xpx = true, ypx = true, anchor = anchor } )
        widget.binder.child1:spoolText( line, SPOOL_SPEED )
        widget:setPosition( wx + (i-1) * NAMES_SPACING_X, wy + (i-1) * NAMES_SPACING_Y )
        screen:addWidget( widget )
        widget.binder.child1:setColor(unpack(CREDIT_COLOR))
        table.insert( widgets, widget )
    end

    --creditsFade( 10, unpack(widgets) )

    while duration > 0 do
        coroutine.yield()
        duration = duration - 1
    end

    local fadeStep = 255 / FADE_TIME
    creditsFade( -fadeStep, CREDIT_COLOR, unpack(widgets) )

    while #widgets > 0 do
        screen:removeWidget( table.remove( widgets ))
    end
end

local function creditsNamesList( screen, allNames, namesCount, forceIdx )
    local CREDIT_WAIT_TIME = 2*cdefs.SECONDS
    local NAMES_POSITIONS = {
        -- xpos, ypos, anchor (see mui_component.lua)
        { 50, 100, 0, },
        { 150, 100, 6, },
        { 450, 100, 2, },
    }
    
    local function displayNames( posIndex )
        local count, lines = namesCount, {}
        local continue = true

        if #allNames <= namesCount then
            continue = false
        end

        while count > 0 and #allNames > 0 do
            count = count - 1
            table.insert( lines, 1, table.remove( allNames, 1 ) )
        end

        local loc = NAMES_POSITIONS[ forceIdx or posIndex ]   
        posIndex = posIndex + 1
        creditsNames( screen, CREDIT_WAIT_TIME, loc[1], loc[2], loc[3], lines )

        return continue
    end

    local FRAMES = 60/30 --movie runs at 30fps
    local PACING = 
    {
        { 15*FRAMES, 2 },
        { 107*FRAMES, 3 },
        { 220*FRAMES, 1 },
        { 313*FRAMES, 2 },
        { 424*FRAMES, 3 },
        { 517*FRAMES, 1 },
        { 634*FRAMES, 2 },
        { 727*FRAMES, 3 },
    }        

    local totalTime = 0
    for _, v in ipairs(PACING) do
        local waitTime = v[1] - totalTime
        rig_util.wait( waitTime )
        if not displayNames( v[2] ) then
            break
        end
        totalTime = v[1] + CREDIT_WAIT_TIME + FADE_TIME
    end

end

--------------------------------------------------------------------
--  Responsible for sequencing the credits.

local sequencer = class()

function sequencer:init( screen )
    self.screen = screen
    self.thread = MOAICoroutine.new()
    self.thread:run( self.onResume, self )
end

function sequencer:destroy()
    self.thread:stop()
    self.thread = nil
end

function sequencer:onResume()

    creditsNamesList( self.screen, { STRINGS.CREDIT_ROLL.DEVELOPED_BY }, 4, 1 )

    -- default credit roll
    local names = util.tcopy( STRINGS.CREDIT_ROLL.NAMES )
	util.shuffle( names, function( n ) return math.random( 1, n ) end )
    creditsNamesList( self.screen, names, 4 )

    -- 3rd party
    creditsTemplate( self.screen, 5 * cdefs.SECONDS, 0, 0, "CreditsExternal" )
    creditsWait( 1 )

    creditsTemplate( self.screen, 5 * cdefs.SECONDS, 0, 0, "CreditsSpecialThanks" )
    creditsWait( 1 )

    creditsTemplate( self.screen, 5 * cdefs.SECONDS, 0, 0, "CreditsMoai" )
    creditsWait( 1 )
    creditsTemplate( self.screen, math.huge, 0, 0, "CreditsThankYou" )
end

--------------------------------------------------------------------
-- 

local creditsScreen = class()

function creditsScreen:startSequence()
    self.credits = sequencer( self.screen )
end

function creditsScreen:onInputEvent( ev )
    if ev.eventType == mui_defs.EVENT_KeyDown then
        if mui_util.isBinding( ev, { mui_defs.K_INSERT, mui_defs.K_CONTROL }) then
            self.screen:findWidget( "console" ):setVisible( not self.screen:findWidget( "console" ):isVisible() )
            return true

        elseif config.DEV and mui_util.isBinding( ev, { mui_defs.K_F5, mui_defs.K_SHIFT } ) then
            reinclude( "states/state-credits" )
            return true
        end
    end
end

function creditsScreen:onLoad()
	self.screen = mui.createScreen( "credits.lua" )
	mui.activateScreen( self.screen )

    MOAIFmodDesigner.stopSound("theme")

    inputmgr.addListener( self, 1 )

    self.lines = {}

    self.editTxt = self.screen:findWidget( "editTxt" )
    self.editTxt:setText( PROMPT_STR )
    self.editTxt.onEditComplete = util.makeDelegate( nil, onEditCommand, self )
	self.screen.binder.creditNames:spoolText("")
	self.screen.binder.backBtn.binder.btn.onClick = util.makeDelegate( nil, onClickDone, self )
    self.screen.binder.backBtn.binder.btn:setText( STRINGS.UI.BACK )
    self.screen.binder.backBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)

    self.screen.binder.movie:playMovie()

    self:startSequence()
end

function creditsScreen:onUnload()
    inputmgr.removeListener( self )
	mui.deactivateScreen( self.screen )
    MOAIFmodDesigner.playSound("SpySociety/Music/music_title","theme")
    self.credits:destroy()
    self.credits = nil
end

return creditsScreen
