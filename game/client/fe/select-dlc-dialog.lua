----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local mui_util = include( "mui/mui_util" )
local cdefs = include( "client_defs" )
local util = include( "client_util" )
local array = include( "modules/array" )
local modalDialog = include( "states/state-modal-dialog" )
local strings = include( "strings" )

----------------------------------------------------------------
-- Local functions


local function onClickAccept( dialog )
	log:write("select_dlc_dialog:onClickAccept()")
	dialog:getModStates()
	dialog.result = true
end

local function onClickCancel( dialog )
	log:write("select_dlc_dialog:onClickCancel()")
	dialog.result = false
end

----------------------------------------------------------------
-- Interface functions

local select_dlc_dialog = class()

function select_dlc_dialog:init()
	log:write("select_dlc_dialog:init()")

	local screen = mui.createScreen( "modal-select-dlc.lua" )
	self._screen = screen

	screen.binder.okBtn.onClick = util.makeDelegate( nil, onClickAccept, self )
	--screen.binder.okBtn:setText(STRINGS.UI.BUTTON_ACCEPT)
	--screen.binder.okBtn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)
	
	screen.binder.cancelBtn.onClick = util.makeDelegate( nil, onClickCancel, self )  
	--screen.binder.cancelBtn:setText(STRINGS.UI.BUTTON_CANCEL)
	--screen.binder.cancelBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
	screen.binder.cancelBtn:setHotkey( "pause" )

	local installedMods = mod_manager:getInstalledMods()
	for _, modID in ipairs(installedMods) do
		self:addModOption(modID)
	end

end

function select_dlc_dialog:onLoad()
	log:write("select_dlc_dialog:onLoad()")
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
	mui.activateScreen( self._screen )
end

function select_dlc_dialog:onUnload()
	log:write("select_dlc_dialog:onUnload()")
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPDOWN  )
	mui.deactivateScreen( self._screen )
end

function select_dlc_dialog:show(selections)
	log:write("select_dlc_dialog:show()")

	self.result = nil

	if not self._screen then
		self:init()
	end

	self.selections = selections

	local list =  self._screen:findWidget("list")
	for i, item in ipairs(list:getItems()) do
		local widget = item.widget.binder.widget

		assert(selections[item.user_data])
		widget:setValue(selections[item.user_data].enabled)
	end

	statemgr.activate( self )
	while self.result == nil do
		coroutine.yield()
	end
    statemgr.deactivate( self )

	return self.result
end

function select_dlc_dialog:isActive()
	return self._screen and self._screen:isActive()
end

local function onChangedOption( self, modID )
	log:write("CHANGED: %s", modID)
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_CLICK )
end

function select_dlc_dialog:addModOption(modID)
	local list =  self._screen:findWidget("list")
	local widget

	widget = list:addItem( modID, "CheckOption" )
	widget.binder.widget:setText( mod_manager:getModName(modID) )
	widget.binder.widget.onClick = util.makeDelegate( nil, onChangedOption, self, modID )

	return widget
end

function select_dlc_dialog:getModStates()
	log:write("select_dlc_dialog:getModStates")
	local list =  self._screen:findWidget("list")

	for i, item in ipairs(list:getItems()) do
		local widget = item.widget.binder.widget
		log:write("   %s %s", item.user_data, tostring(widget:getValue()))
		self.selections[item.user_data].enabled = widget:getValue()
	end
end

return select_dlc_dialog
