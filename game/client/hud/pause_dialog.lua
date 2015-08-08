----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local util = include( "client_util" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local gameobj = include( "modules/game" )
local cdefs = include("client_defs")
local modalDialog = include( "states/state-modal-dialog" )
local options_dialog = include( "hud/options_dialog" )
local tutorialDialog = include( "fe/tutorial-dialog" )    
local unitdefs = include( "sim/unitdefs" )

----------------------------------------------------------------
-- Local functions

local PAUSE_RESUME = 0
local PAUSE_QUIT = 1
local PAUSE_RETIRE = 2

local function onClickResume( dialog )
	dialog:hide()	-- Kill this dialog.
    dialog.result = PAUSE_RESUME
end

local function onClickOptions( dialog )
    if dialog._options_dialog and dialog._options_dialog:isActive() then
        dialog._options_dialog:hide()
    end

    dialog._options_dialog = options_dialog( dialog._game )
 	dialog._options_dialog:show()
end

local function onClickHelp( dialog )
    if dialog._help_dialog and dialog._help_dialog:isActive() then
        dialog._help_dialog:destroy()
    end

    dialog._help_dialog = tutorialDialog()
    dialog._help_dialog:show()
end

local function onClickQuit( dialog )
	local result = modalDialog.showYesNo( STRINGS.UI.SAVE_AND_EXIT_CONFIRM, STRINGS.UI.SAVE_AND_EXIT, nil, STRINGS.UI.SAVE_AND_EXIT )
	if result == modalDialog.OK then
	    dialog:hide()
        dialog.result = PAUSE_QUIT
	end	
end

local function onClickRetire( dialog )
	local result = modalDialog.showYesNo( STRINGS.UI.RETIRE_AGENCY_CONFIRM, STRINGS.UI.RETIRE_AGENCY, nil, STRINGS.UI.RETIRE_AGENCY )
	if result == modalDialog.OK then
        dialog:hide()
        dialog.result = PAUSE_RETIRE
	end	
end

local function onClickAbort( dialog )
	local result = modalDialog.showYesNo( "Are you SURE you want to abort the mission? Agents in the field will be lost.", STRINGS.UI.ABORT_MISSION, nil, STRINGS.UI.ABORT_MISSION )
	if result == modalDialog.OK then
    	dialog:hide()
        dialog._game:doAction( "abortMission" )
    end
end

local function checkTeam( game )

	local player = game.simCore:getPC()

	local allInField = true

	for agentID, deployData in pairs( player:getDeployed() ) do
		if deployData.escapedUnit then
			allInField = false
        end
    end

    if allInField == true then
		return "all_in"
	end
	return false
end

local function getTeamStatus( self )

	local player = self._game.simCore:getPC()
	local title = string.format( "<c:8CFFFF>%s</c>", STRINGS.UI.TEAM_STATUS )
	local txt = "<ttbody><c:8CFFFF>"
	
	local escaped = {}
	local notEscaped = {}

	for agentID, deployData in pairs( player:getDeployed() ) do		
		
		if deployData.id then
            local unit = self._game.simCore:getUnit(deployData.id)
			if deployData.escapedUnit then
				local templateData = unitdefs.lookupTemplate( deployData.agentDef.template )
				table.insert(escaped,templateData.name)
				--txt = txt .. name .. "\t\t ESCAPED\n" 
			elseif unit then
				table.insert(notEscaped, unit:getName() )
				--txt = txt ..  name .. "\t\t IN FACILITY\n" 
			end
        end
    end


	if #notEscaped then	
		if checkTeam(self._game) ~= "all_in" then
			txt = txt .. string.format( "<c:ff0000>%s</c>", STRINGS.UI.AGENTS_WILLBE_LOST )
		else
	    	txt = txt .. STRINGS.UI.AGENTS_IN_FIELD
		end

	    for i,name in ipairs(notEscaped) do
	    	txt = txt .. "\n     <c:ffffff>"..name .. "</c>"
	    end
			    
	end

    if #escaped > 0 then
    	txt = txt .."\n\n"
	    txt = txt .. STRINGS.UI.AGENTS_ESCAPED

	    for i,name in ipairs(escaped) do
	    	txt = txt .. "\n     <c:ffffff>"..name .. "</c>"
	    end
	end

	if checkTeam(self._game) == "all_in" then
		txt = txt .. STRINGS.UI.ABORT_DISABLED		
	end

	txt = txt .. "</c></>"
	return txt
end




----------------------------------------------------------------
-- Interface functions

local pause_dialog = class()

function pause_dialog:init(game)
	local screen = mui.createScreen( "pause_dialog_screen.lua" )
	self._game = game
	self._screen = screen

    self.RESUME = PAUSE_RESUME
    self.QUIT = PAUSE_QUIT
    self.RETIRE = PAUSE_RETIRE

	screen.binder.pnl.binder.resumeBtn.onClick = util.makeDelegate( nil, onClickResume, self )
	screen.binder.pnl.binder.optionsBtn.onClick = util.makeDelegate( nil, onClickOptions, self )
	screen.binder.pnl.binder.quitBtn.onClick = util.makeDelegate( nil, onClickQuit, self )
	screen.binder.pnl.binder.helpBtn.onClick = util.makeDelegate( nil, onClickHelp, self )
    if not self._game or self._game.simCore:hasTag( "isTutorial" ) then
	    screen.binder.pnl.binder.abortBtn:setVisible( false )
	    screen.binder.pnl.binder.retireBtn:setVisible( false )
    else
	    screen.binder.pnl.binder.abortBtn.onClick = util.makeDelegate( nil, onClickAbort, self )
    	screen.binder.pnl.binder.retireBtn.onClick = util.makeDelegate( nil, onClickRetire, self )
    end
end


function pause_dialog:show()
	mui.activateScreen( self._screen )
	FMODMixer:pushMix( "quiet" )
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_POPUP )

    if self._game then
        local isGameOver = self._game.simCore:isGameOver()

    	self._screen.binder.pnl.binder.abortBtn:setTooltip( getTeamStatus(self) )    

        self._screen.binder.pnl.binder.abortBtn:setDisabled( isGameOver or checkTeam(self._game) == "all_in" )
        self._screen.binder.pnl.binder.retireBtn:setDisabled( isGameOver )
    end

    self.result = nil

    while self.result == nil do
        coroutine.yield()
    end

    return self.result
end

function pause_dialog:updateHeader( txt )
    self._screen:findWidget( "header" ):setText( txt )
end

function pause_dialog:hide()
    if self._options_dialog and self._options_dialog:isActive() then
        self._options_dialog:hide()
    end
    self._options_dialog = nil

    if self._help_dialog and self._help_dialog:isActive() then
        self._help_dialog:destroy()
    end
    self._help_dialog = nil

	if self._screen:isActive() then
		mui.deactivateScreen( self._screen )
		FMODMixer:popMix( "quiet" )
	end
end


return pause_dialog
