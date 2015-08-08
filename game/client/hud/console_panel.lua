----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local mui = include( "mui/mui")
local mui_defs = include( "mui/mui_defs")
include("class")

------------------------------------------------------------------------------
-- Local functions

local PROMPT_STR = "> "
local MAX_LINES = 30

local function onEditComplete( panel, str, cmd )
	if cmd then
		--panel:clear()
		panel:displayLine( PROMPT_STR .. cmd )
		panel._mod:processInput( cmd )
	end
end

------------------------------------------------------------------------------

local console_panel = class()

function console_panel:init( hud, mod )

	local screen = mui.createScreen( "modal-console.lua" )
	mui.activateScreen( screen )
	self._txt = screen.binder.txt
	self._txt.onEditComplete = util.makeDelegate( nil, onEditComplete, self )
	self._screen = screen
	self._hud = hud
	self._lines = {}
	self:clear()

	self._txt:setText( PROMPT_STR )
	self._txt:startEditing( mui_defs.EDIT_CMDPROMPT )

	inputmgr.addListener( self, 1 )

	if mod == nil then
		self._mod = KLEITextModule.new()
		self._mod:setListener( KLEITextModule.EVENT_STDOUT,
			function( mod, txt )
				self:displayLine( txt )
			end )
		self._mod:loadModule( "Adventure2.5.dll" )
	else
		self._mod = mod
		self._mod:setPanel( self )
	end
end

function console_panel:clear()
	for i = 1, MAX_LINES do
		self._lines[i] = ""
	end
	self._startLine, self._endLine = 1, 2
end


function console_panel:displayLine( txt )
	self._lines[ self._endLine ] = txt
	self._endLine = self._endLine + 1
	if self._endLine > MAX_LINES then
		self._endLine = 1
	end
	if self._endLine == self._startLine then
		self._startLine = self._startLine + 1
	end

	local str
	if self._endLine > self._startLine then
		str = table.concat( self._lines, "\n", self._startLine, self._endLine - 1 )
	else
		str = table.concat( self._lines, "\n", self._startLine, MAX_LINES )
		str = str .. table.concat( self._lines, "\n", 1, self._endLine - 1 )
	end

	-- Always append a prompt.
	str = str .. "\n" .. PROMPT_STR

	self._txt:setText( str )
end

function console_panel:onInputEvent( event )
	if event.eventType == mui_defs.EVENT_KeyDown then
		if event.key == mui_defs.K_C and event.controlDown then
			print( "CTRL-C" )
			self:destroy()
			return true
		end
	end
end

function console_panel:destroy()
	inputmgr.removeListener( self )

	mui.deactivateScreen( self._screen )
	self._screen = nil

	if self._mod then
		self._mod = nil
	end
end

return
{
	panel = console_panel
}

