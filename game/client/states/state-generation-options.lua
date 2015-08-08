----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include("client_util")
local array = include( "modules/array" )
local mui = include( "mui/mui" )
local serverdefs = include( "modules/serverdefs" )
local modalDialog = include( "states/state-modal-dialog" )
local rig_util = include( "gameplay/rig_util" )
local cdefs = include("client_defs")
local scroll_text = include("hud/scroll_text")
local unitdefs = include( "sim/unitdefs" )
local metadefs = include( "sim/metadefs" )
local simdefs = include( "sim/simdefs" )
local movieScreen = include('client/fe/moviescreen')
local stateTeamPreview = include( "states/state-team-preview" )
local SCRIPTS = include('client/story_scripts')
----------------------------------------------------------------

local CHARACTER_IMAGES = 
{
    { png="spec_ops" },
    { png="internationale", unlock="sharpshooter_1" }, --lock them to the first unlocks
    { png="character", unlock="sharpshooter_1" }, --lock them to the first unlocks
    { png="shalem", unlock="sharpshooter_1" },
    { png="banks", unlock="stealth_2" },    
    { png="nika", unlock="sharpshooter_2" },    
    { png="tony", unlock="engineer_1" },    
    { png="sharp", unlock="cyborg_1" },
    { png="prism", unlock="disguise_1" },
    { png="central", unlock="central_pc" },
    { png="monst3r", unlock="monst3r_pc" },
}

local ACTIVE_TXT = { 61/255,81/255,83/255,1 }
local INACTIVE_TXT = { 1,1,1,1 }

local ACTIVE_BG = { 244/255, 255/255, 120/255,1 }
local INACTIVE_BG = { 78/255, 136/255, 136/255,1 }

local MENU_UNSELECTED = { 78/255, 136/255, 136/255 }
local MENU_SELECTED = { 122/255, 215/255, 215/255 }

local DEFAULT_DIFF = simdefs.NORMAL_DIFFICULTY

local DIFFICULTY_MENU = {	
		{diff=simdefs.NORMAL_DIFFICULTY,name=util.toupper(STRINGS.UI.NORMAL_DIFFICULTY), desc=STRINGS.UI.NORMAL_DESC, short_desc=STRINGS.UI.NORMAL_SHORT_DESC},
        {diff=simdefs.EXPERIENCED_DIFFICULTY,name=util.toupper(STRINGS.UI.EXPERIENCED_DIFFICULTY), desc=STRINGS.UI.EXPERIENCED_DESC, short_desc=STRINGS.UI.EXPERIENCED_SHORT_DESC},
		{diff=simdefs.HARD_DIFFICULTY,name=util.toupper(STRINGS.UI.HARD_DIFFICULTY), desc=STRINGS.UI.HARD_DESC, short_desc=STRINGS.UI.HARD_SHORT_DESC},
		{diff=simdefs.VERY_HARD_DIFFICULTY,name=util.toupper(STRINGS.UI.VERY_HARD_DIFFICULTY), desc=STRINGS.UI.VERY_HARD_DESC, short_desc=STRINGS.UI.VERY_HARD_SHORT_DESC},
		{diff=simdefs.ENDLESS_DIFFICULTY,name=util.toupper(STRINGS.UI.ENDLESS_DIFFICULTY), desc=STRINGS.UI.ENDLESS_DESC, short_desc=STRINGS.UI.ENDLESS_SHORT_DESC},		
        {diff=simdefs.ENDLESS_PLUS_DIFFICULTY,name=util.toupper(STRINGS.UI.ENDLESS_PLUS_DIFFICULTY), desc=STRINGS.UI.ENDLESS_PLUS_DESC, short_desc=STRINGS.UI.ENDLESS_PLUS_SHORT_DESC},     
        {diff=simdefs.TIME_ATTACK_DIFFICULTY,name=util.toupper(STRINGS.UI.TIME_ATTACK_DIFFICULTY), desc=STRINGS.UI.TIME_ATTACK_DESC, short_desc=STRINGS.UI.TIME_ATTACK_SHORT_DESC},     
		{diff=simdefs.CUSTOM_DIFFICULTY,name=util.toupper(STRINGS.UI.CUSTOM_DIFFICULTY), desc=STRINGS.UI.CUSTOM_DESC, short_desc=STRINGS.UI.CUSTOM_SHORT_DESC},
	}


local function FindIndexOf(val, array)
    for k,v in pairs(array) do 
        if v == val then return k end
    end
end

-- This table maps widgetNames to the sets of options that are modified by it.
-- WARNING: order matters, at least for the rewinds option
local CUSTOM_OPTIONS =
{
  
    ------------------------------------
    --BROAD STROKE DIFFICULTY SETTINGS--
    ------------------------------------
    {
    	name = STRINGS.UI.DIFF_OPTION_REWINDS,
    	tip = STRINGS.UI.DIFF_OPTION_REWINDS_TIP,
        ironManCheck = true,
        values = { 0,1,3,5,10,99 },
        strings = STRINGS.UI.GENOPTIONS.REWINDS,
        apply = function( self, options, index )
            options.rewindsLeft = self.values[index]
        end,
        retrieve = function( self, options )
            return self.strings[FindIndexOf(options.rewindsLeft, self.values)]
        end,
    },

    {
        name = STRINGS.UI.DIFF_OPTION_LEVEL_RETRIES,
        tip = STRINGS.UI.DIFF_OPTION_LEVEL_RETRIES_TIP,
        check = true,
        apply = function( self, options, value )
            options.savescumming = value
        end,
        retrieve = function( self, options )
            return options.savescumming
        end
    },
    
    {
    	name = STRINGS.UI.DIFF_OPTION_AUTOALARM,
    	tip = STRINGS.UI.DIFF_OPTION_AUTOALARM_TIP,
    	check = true,
        apply = function( self, options, value )
            options.autoAlarm = value
        end,
        retrieve = function( self, options )
            return options.autoAlarm
        end
    },

    ------------------------------------
    -----------TWEAKY SETTINGS----------
    ------------------------------------
    {
    	name = STRINGS.UI.DIFF_OPTION_HOURS,
    	tip = STRINGS.UI.DIFF_OPTION_HOURS_TIP,
        strings = STRINGS.UI.GENOPTIONS.HOURS,
        values = { 24,48,72,120, math.huge},
        apply = function( self, options, index )
            options.maxHours = self.values[index]
        end,
        retrieve = function( self, options )
            return self.strings[FindIndexOf(options.maxHours, self.values)]
        end,
    },    

    {
    	name = STRINGS.UI.DIFF_OPTION_STARTPWR,
    	tip = STRINGS.UI.DIFF_OPTION_STARTPWR_TIP,
        values = { 0, 5, 10, 20 },
        apply = function( self, options, idx )
            options.startingPower = self.values[idx]
        end,
        retrieve = function( self, options )
            return tostring(options.startingPower)
        end
    },   
  
    {
    	name = STRINGS.UI.DIFF_OPTION_ALARMTYPE,
    	tip = STRINGS.UI.DIFF_OPTION_ALARMTYPE_TIP,
        strings = STRINGS.UI.GENOPTIONS.ALARMTYPE,
        values = { "EASY", "NORMAL" },
        apply = function( self, options, idx )
            options.alarmTypes = self.values[idx]
        end,
        retrieve = function( self, options )
            return self.strings[FindIndexOf(options.alarmTypes, self.values)]
        end
    }, 

    {
    	name = STRINGS.UI.DIFF_OPTION_CREDITS,
    	tip = STRINGS.UI.DIFF_OPTION_CREDITS_TIP,
        values = { 0.5, 0.75, 1, 1.25, 1.5, 2 },
        apply = function( self, options, idx )
            options.creditMultiplier = self.values[idx]
        end,
        retrieve = function( self, options )
            return tostring(options.creditMultiplier)
        end
    },

    {
    	name = STRINGS.UI.DIFF_OPTION_GUARDSPAWNS,
    	tip = STRINGS.UI.DIFF_OPTION_GUARDSPAWNS_TIP,
        values = { "LESS", "NORMAL", "MORE" },
        strings = STRINGS.UI.GENOPTIONS.GUARDSPAWNS,
        apply = function( self, options, idx )
            options.spawnTable = self.values[idx]
        end,
        retrieve = function( self, options )
            return self.strings[FindIndexOf(options.spawnTable, self.values)]
        end
    }, 
    
    {
    	name = STRINGS.UI.DIFF_OPTION_BEGINNER_PATROLS,
    	tip = STRINGS.UI.DIFF_OPTION_BEGINNER_PATROLS_TIP,
    	check = true,
        apply = function( self, options, value )
            options.beginnerPatrols = value
        end,
        retrieve = function( self, options )
            return options.beginnerPatrols
        end
    }, 
    
    {
    	name = STRINGS.UI.DIFF_OPTION_KOTIME,
    	tip = STRINGS.UI.DIFF_OPTION_KOTIME_TIP,
        strings = STRINGS.UI.GENOPTIONS.KOTIME,
        values = {99,4,2,1,0,-1},
        apply = function( self, options, idx )
            options.koDuration = self.values[idx]
        end,
        retrieve = function( self, options )

            return self.strings[FindIndexOf(options.koDuration, self.values)]
        end,
    },

    {
    	name = STRINGS.UI.DIFF_OPTION_ALARMKO,
    	tip = STRINGS.UI.DIFF_OPTION_ALARMKO_TIP,
    	check = true,
        apply = function( self, options, value )
            options.alarmRaisedOnKO = value
        end,
        retrieve = function( self, options )
            return options.alarmRaisedOnKO
        end
    }, 
    
    {
    	name = STRINGS.UI.DIFF_OPTION_DANGERZONE,
    	tip = STRINGS.UI.DIFF_OPTION_DANGERZONE_TIP,
    	check = true,
        apply = function( self, options, value )
            options.dangerZones = value
        end,
        retrieve = function( self, options )
            return options.dangerZones
        end
    },    

    {
        name = STRINGS.UI.DIFF_OPTION_MELEEFRONT,
        tip = STRINGS.UI.DIFF_OPTION_MELEEFRONT_TIP,
        check = true,
        apply = function( self, options, value )
            options.meleeFromFront = value
        end,
        retrieve = function( self, options )
            return options.meleeFromFront
        end
    },

    {
        name = STRINGS.UI.DIFF_OPTION_COUNTERMEASURES,
        tip = STRINGS.UI.DIFF_OPTION_COUNTERMEASURES_TIP,
        check = true,
        apply = function( self, options, value )
            options.countermeasuresFinal = value
        end,
        retrieve = function( self, options )
            return options.countermeasuresFinal
        end
    },        

    {
    	name = STRINGS.UI.DIFF_OPTION_ALARM,
    	tip = STRINGS.UI.DIFF_OPTION_ALARM_TIP,
        values = { 0, 1, 2, 3, 4, 5 },
        apply = function( self, options, idx )
            options.alarmMultiplier =  self.values[idx]
        end,
        retrieve = function( self, options )
            return tostring(options.alarmMultiplier)
        end
    },

    {
    	name = STRINGS.UI.DIFF_OPTION_MONEY,
    	tip = STRINGS.UI.DIFF_OPTION_MONEY_TIP,
        values = { 0, 500, 1000, 2000, 10000 },
        apply = function( self, options, idx )
            options.startingCredits = self.values[idx]
        end,
        retrieve = function( self, options )
            return tostring(options.startingCredits)
        end
    },    
    
    {
    	name = STRINGS.UI.DIFF_OPTION_CONSOLES,
    	tip = STRINGS.UI.DIFF_OPTION_CONSOLES_TIP,
        values = { 0, 3, 5, 7, 15 },
        strings = STRINGS.UI.GENOPTIONS.PROPSPAWNS,
        apply = function( self, options, idx )
            options.consolesPerLevel = self.values[idx]
            options.powerPerLevel = tonumber(options.consolesPerLevel) * 2
        end,
        retrieve = function( self, options )
            return self.strings[ FindIndexOf(options.consolesPerLevel, self.values)]
        end
    },
   
    {
    	name = STRINGS.UI.DIFF_OPTION_SAFES,
    	tip = STRINGS.UI.DIFF_OPTION_SAFES_TIP,
        values = { 0, 3, 5, 7, 15 },
        strings = STRINGS.UI.GENOPTIONS.PROPSPAWNS,
        apply = function( self, options, idx )
            options.safesPerLevel = self.values[idx]
        end,
        retrieve = function( self, options )
            return self.strings[ FindIndexOf(options.safesPerLevel, self.values)]
        end
    },

    {
    	name = STRINGS.UI.DIFF_OPTION_ROOMS,
    	tip = STRINGS.UI.DIFF_OPTION_ROOMS_TIP,
        values = { 8, 10, 12, 14, 16, 18, 20 },
        apply = function( self, options, idx )
            options.roomCount = self.values[idx]
        end,
        retrieve = function( self, options )
            return tostring(options.roomCount)
        end
    },
   
    {
    	name = STRINGS.UI.DIFF_OPTION_DAEMONS,
    	tip = STRINGS.UI.DIFF_OPTION_DAEMONS_TIP,
        values = { "LESS", "NORMAL", "MORE" },
        strings = STRINGS.UI.GENOPTIONS.DAEMONS,
        apply = function( self, options, idx )
            options.daemonQuantity = self.values[idx]
        end,
        retrieve = function( self, options )
            return self.strings[FindIndexOf(options.daemonQuantity, self.values)]
        end
    },

    ------------------------------------
    -----------OTHER SETTINGS-----------
    ------------------------------------
    {
        name = STRINGS.UI.DIFF_OPTION_TIMEATTACK,
        tip = STRINGS.UI.DIFF_OPTION_TIMEATTACK_TIP,
        strings = STRINGS.UI.GENOPTIONS.TIMEATTACK,
        values = { 0, 30*cdefs.SECONDS, 60*cdefs.SECONDS, 2*60*cdefs.SECONDS, 5*60*cdefs.SECONDS },
        apply = function( self, options, index )
            options.timeAttack = self.values[index]
        end,
        retrieve = function( self, options )
            return self.strings[FindIndexOf(options.timeAttack, self.values)]
        end
    },    
}

local DLC_SETTING = 
{
    check = true,
    apply = function( self, options, value )
        options[self.dlc_id].options[self.dlc_option].enabled = value
    end,
    retrieve = function( self, options )
        return options[self.dlc_id].options[self.dlc_option].enabled
    end
}

local function updateRewinds( self )
    local item = self._screen:findWidget("list"):getItem(self.rewindIndex)
    local widget = item.widget.binder.widget

    self._panel:findWidget( "numRewinds" ):selectIndex( widget:getIndex() )
end

local function updateRetries( self )
    local item = self._screen:findWidget("list"):getItem(self.retriesIndex)
    local widget = item.widget.binder.widget

    self._panel:findWidget( "levelRetriesBtn" ):setChecked( widget:isChecked() )
end

local function onClickLevelRetries( self, checkBox )
    local item = self._screen:findWidget("list"):getItem(self.retriesIndex)
    local widget = item.widget.binder.widget
    
    widget:setChecked( checkBox:isChecked() )
end

local function onChangedRewindOption( self )
    local item = self._screen:findWidget("list"):getItem(self.rewindIndex)
    local widget = item.widget.binder.widget
    
    widget:selectIndex( self._panel:findWidget( "numRewinds" ):getIndex() )
end

local function onChangedOption( self, setting, widget )
    if not self.updatingDifficulty then
        -- If current difficulty is not CUSTOM, and an option was change to the non-default value...
        -- automatically switch to CUSTOM DIFFICULTY.
        self:selectDifficulty( simdefs.CUSTOM_DIFFICULTY )
    end

    updateRetries(self)
end

local function onChangedComboOption( self, setting, widget )
    -- Iron man setting is special: it links to the iron man checkbox, and does not imply custom difficulty.
    if setting.ironManCheck then
        local options = {}
        setting:apply( options, widget:getIndex()  )

        updateRewinds(self)
    elseif not self.updatingDifficulty then
        -- If current difficulty is not CUSTOM, and an option was change to the non-default value...
        -- automatically switch to CUSTOM DIFFICULTY.
        self:selectDifficulty( simdefs.CUSTOM_DIFFICULTY )
    end

    updateRetries(self)
end

local function onClickDiff( self, difficulty)
    self:selectDifficulty( difficulty )
end

local function addGenerationOption(self, setting)
	local list =  self._screen:findWidget("list")
    local widget

    if setting.check then
	    widget = list:addItem( setting, "CheckOption" )
		widget.binder.widget:setText( setting.name )
        widget.binder.widget.onClick = util.makeDelegate( nil, onChangedOption, self, setting, widget.binder.widget )

    elseif setting.values then
	    widget = list:addItem( setting, "ComboOption" )
        for i, item in ipairs(setting.values) do

            widget.binder.widget:addItem( setting.strings and setting.strings[i] or item )
        end
        widget.binder.widget.onTextChanged = util.makeDelegate( nil, onChangedComboOption, self, setting, widget.binder.widget )
        widget.binder.dropTxt:setText( setting.name )
    elseif setting.section then
        widget = list:addItem( setting, "SectionHeader" )
        widget.binder.label:setText( setting.section )
    end

    setting.list_index = list:getItemCount()
    assert(setting.list_index > 0)

    if setting.name == STRINGS.UI.DIFF_OPTION_REWINDS then
        self.rewindIndex = setting.list_index
    end
    if setting.name == STRINGS.UI.DIFF_OPTION_LEVEL_RETRIES then
        self.retriesIndex = setting.list_index
    end

    widget:setTooltip(setting.tip)
    
    return widget
end

local function onClickCancelBtn(self)
    MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
    statemgr.deactivate( self )
	local stateMainMenu = include( "states/state-main-menu" )
	statemgr.activate( stateMainMenu() )
end

local function onClickShowOptionsBtn(self) 
    self:showDifficultyOptions( self._screen.binder.showOptionsBtn:isChecked() )
end

local function onClickSelectDLCBtn(self)
    local restoreOptions = self:retrieveOptions()

    local dlcDialog = include( "fe/select-dlc-dialog" )
    local dlc_res = dlcDialog:show(self._dlcSelections)
    if dlc_res then
        self:refreshGenerationOptions()
        self:restoreGenerationOptionSelections(restoreOptions)
        self:applyDLCOptions(mod_manager:getModContentDefaults())
    end
end

local function launchGame( self )
    local settings = savefiles.getSettings( "settings" )
    settings.data.lastdiff = self._diff
    settings:save()

    MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )

	local options = self:retrieveOptions()
    options.enabledDLC = self:retrieveDLCOptions()

    statemgr.deactivate( self )
    MOAIFmodDesigner.stopSound("theme")

    print ("HOURS", options.maxHours, config.CAMPAIGN_HOURS)
    if config.CAMPAIGN_HOURS ~= 72 then
        options.maxHours = config.CAMPAIGN_HOURS
    end

    mod_manager:resetContent()
    mod_manager:loadModContent( options.enabledDLC )

    local endless = options.maxHours == math.huge
    if endless or not config.SHOW_MOVIE then
        statemgr.activate( stateTeamPreview( self._diff, options ) )
    else        
        
        movieScreen("data/movies/IntroCinematic.ogv", function() 
            statemgr.activate( stateTeamPreview(  self._diff, options ))
        end,  SCRIPTS.SUBTITLES.INTRO )

    end
end

local function onClickStartBtn(self) 
	launchGame(self)
end


-- #################################################################################################

local generationOptions = class()

function generationOptions:init()    
end

function generationOptions:onLoad( difficulty, difficultyOptions )

	self._screen = mui.createScreen( "generation-options.lua" )
	mui.activateScreen( self._screen )

    -- failsafe
    FMODMixer:popMix("nomusic")

    local imgs = {}
    for i = 1, #CHARACTER_IMAGES do
        if CHARACTER_IMAGES[i].unlock == nil then
            table.insert(imgs, CHARACTER_IMAGES[i].png)
        elseif metadefs.isRewardUnlocked(CHARACTER_IMAGES[i].unlock) then
            table.insert(imgs, CHARACTER_IMAGES[i].png)
        end
    end

    local idx = math.random(1,#imgs)
    log:write( "\tmainmenu:onLoad() - assigning agent image '%s'", imgs[idx] )
    self._screen.binder.agent:setImage( "gui/menu pages/main/"..imgs[idx]..".png")
    self._screen.binder.agent:createTransition("activate_left")
    
	self._scroll_text = scroll_text.panel( self._screen.binder.bg )

	self._panel = self._screen.binder.pnl

    local installedMods = mod_manager:getInstalledMods()
    if next(installedMods) then
        self._panel.binder.dlcBtn:setVisible(true)
        self._panel.binder.dlcTitle:setVisible(true)

        self._dlcSelections = (difficultyOptions and difficultyOptions.enabledDLC) or mod_manager:getModContentDefaults()
    end

    self:refreshGenerationOptions()

    -- Setup difficulty buttons
    self._difficultyButtons = {}
	for i, widget in self._panel.binder:forEach( "menuBtn" ) do 
		if not DIFFICULTY_MENU[i] then
			widget:setVisible(false)
		else
			widget.binder.btn:setText( DIFFICULTY_MENU[i].name )
			widget.binder.btn.onClick = util.makeDelegate( nil, onClickDiff, self, DIFFICULTY_MENU[i].diff )
            self._difficultyButtons[ DIFFICULTY_MENU[i].diff ] = widget
		end
	end 

    for i, v in ipairs( STRINGS.UI.GENOPTIONS.REWINDS ) do
        self._panel:findWidget( "numRewinds" ):addItem( v )
    end

    updateRewinds( self )
    updateRetries( self )
    self._panel:findWidget("numRewinds").onTextChanged = util.makeDelegate( nil, onChangedRewindOption, self )
    self._panel:findWidget("numRewindsTxt"):setTooltip(STRINGS.UI.DIFF_OPTION_REWINDS_TIP)

    self._panel:findWidget("levelRetriesBtn").onClick = util.makeDelegate( nil, onClickLevelRetries, self) 
    self._panel:findWidget("levelRetriesBtn"):setTooltip(STRINGS.UI.DIFF_OPTION_LEVEL_RETRIES_TIP)
    self._panel:findWidget("levelRetriesBtn"):setClickSound(cdefs.SOUND_HUD_MENU_CLICK)

	self._panel.binder.showOptionsBtn.onClick = util.makeDelegate( nil, onClickShowOptionsBtn, self) 
    self._panel.binder.showOptionsBtn:setTooltip(STRINGS.UI.DIFF_OPTION_SHOW_SETTINGS_TIP)
    self._panel.binder.showOptionsBtn:setClickSound(cdefs.SOUND_HUD_MENU_CLICK)

	self._panel.binder.startBtn.onClick = util.makeDelegate( nil, onClickStartBtn, self) 
    self._panel.binder.startBtn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)

    self._panel.binder.dlcBtn.binder.btn.onClick = util.makeDelegate( nil, onClickSelectDLCBtn, self) 
    self._panel.binder.dlcBtn.binder.btn:setText(STRINGS.UI.SELECT_DLC)
    self._panel.binder.dlcBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CLICK)

	self._panel.binder.cancelBtn.binder.btn.onClick = util.makeDelegate( nil, onClickCancelBtn, self) 
    self._panel.binder.cancelBtn.binder.btn:setHotkey( "pause" )
	self._panel.binder.cancelBtn.binder.btn:setText(STRINGS.UI.EXIT)
    self._panel.binder.cancelBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)

    self._panel.binder.pnl_options:setVisible(false)	

	if not MOAIFmodDesigner.isPlaying("theme") then
		MOAIFmodDesigner.playSound("SpySociety/Music/music_title","theme")
	end

	self._screen.binder.agent:createTransition("activate_left")
	
	self._panel.binder.title_txt:spoolText(STRINGS.UI.SCREEN_NAME_GENERATION_OPTIONS)

    -- Setup initial difficulty setting
    self:selectDifficulty( difficulty or DEFAULT_DIFF ) 
    self:restoreGenerationOptionSelections(difficultyOptions)

    assert(self._diff)
    if self._diff ~= simdefs.CUSTOM_DIFFICULTY and difficultyOptions then
        --rewinds is a special case first-class option if we are coming here from a retry scenario, so seek it out specifically and apply it
        self.updatingDifficulty = true
        local setting = CUSTOM_OPTIONS[1]
        local item = self._screen:findWidget("list"):getItem(self.rewindIndex)
        local widget = item.widget.binder.widget
        local val = setting:retrieve( difficultyOptions )        
        if val then
            widget:setValue(val)
        end
        self.updatingDifficulty = nil
    end

end

function generationOptions:refreshGenerationOptions()
    log:write("generationOptions:refreshGenerationOptions()")

    local list =  self._screen:findWidget("list")
    list:clearItems()

    self.rewindIndex = nil
    self.retriesIndex = nil
    local showGeneralHeader = false

    if self._dlcSelections then
        util.tprint(self._dlcSelections)
        --log:write("   %s", util.stringize(self._dlcSelections))
     
        for id,info in pairs(self._dlcSelections) do
            if info.enabled then
                showGeneralHeader = true
                addGenerationOption(self, { section = util.sformat( STRINGS.UI.DLC_OPTIONS_HEADER, info.name ) })

                local mod_opts = mod_manager:getModGenerationOptions(id)
                --log:write("   mod_opts = %s", util.stringize(mod_opts))
                if mod_opts then
                    for i, opt_info in ipairs(mod_opts) do
                        local opt_setting = util.tcopy(DLC_SETTING)

                        opt_setting.name = opt_info.name
                        opt_setting.dlc_id = id
                        opt_setting.dlc_option = opt_info.option
                        opt_setting.tip = opt_info.tip

                        addGenerationOption(self, opt_setting)
                    end
                end
            end
        end

    end
    
    if showGeneralHeader then
        addGenerationOption(self, { section = STRINGS.UI.GENERAL_OPTIONS_HEADER })    
    end
    
    -- Setup custom generation options. 
    for i, setting in ipairs( CUSTOM_OPTIONS ) do
        addGenerationOption(self, setting)
    end 

    assert(self.rewindIndex)
    assert(self.retriesIndex)
end

function generationOptions:restoreGenerationOptionSelections(difficultyOptions)
    if self._diff == simdefs.CUSTOM_DIFFICULTY then
        self:applyOptions( difficultyOptions or simdefs.DIFFICULTY_OPTIONS[ simdefs.NORMAL_DIFFICULTY ] )
        self:applyDLCOptions(self._dlcSelections)
    else
        self:applyOptions( simdefs.DIFFICULTY_OPTIONS[ self._diff ] )
        self:applyDLCOptions(mod_manager:getModContentDefaults())
    end
end

function generationOptions:retrieveOptions()
    --log:write("generationOptions:retrieveOptions()")

	local options = nil

	if self._diff ~= simdefs.CUSTOM_DIFFICULTY then
		options = util.tcopy( simdefs.DIFFICULTY_OPTIONS[ self._diff ] )
    else
		options = util.tcopy( simdefs.DIFFICULTY_OPTIONS[ simdefs.NORMAL_DIFFICULTY ] )
    end

    for i, setting in ipairs( CUSTOM_OPTIONS ) do
    	local item = self._screen:findWidget("list"):getItem(setting.list_index)
        -- All option list box items have a child named 'widget' which holds the value.
    	local widget = item.widget.binder.widget
        if setting.check then
            setting:apply( options, widget:getValue() )
        else
            setting:apply( options, widget:getIndex() )
        end
    end

    --log:write("   options = %s", util.debugPrintTable(options))

    return options
end

function generationOptions:retrieveDLCOptions()

    self.updatingDifficulty = true

    local list = self._screen:findWidget("list")
    local items = list:getItems()

    -- Assign these options to the UI.
    for i, item in ipairs( items ) do
        local setting = item.user_data
        if setting.dlc_option then
            local widget = item.widget.binder.widget
            setting:apply( self._dlcSelections, widget:getValue() )
        end
    end

    self.updatingDifficulty = nil

    return self._dlcSelections
end

function generationOptions:applyOptions( options )
    self.updatingDifficulty = true
    -- Assign these options to the UI.
    for i, setting in ipairs( CUSTOM_OPTIONS ) do
        local item = self._screen:findWidget("list"):getItem(setting.list_index)
        local widget = item.widget.binder.widget
        widget:setValue( setting:retrieve( options ))
    end
    self.updatingDifficulty = nil
end

function generationOptions:applyDLCOptions( options )
    log:write("generationOptions:applyDLCOptions")
    self.updatingDifficulty = true

    local list = self._screen:findWidget("list")
    local items = list:getItems()

    -- Assign these options to the UI.
    for i, item in ipairs( items ) do
        local setting = item.user_data
        if setting.dlc_option then
            local widget = item.widget.binder.widget
            widget:setValue( setting:retrieve( options ) )
        end
    end

    self.updatingDifficulty = nil
end

function generationOptions:showDifficultyOptions( show )
	if show and not self._panel.binder.pnl_options:isVisible() then
        MOAIFmodDesigner.playSound(cdefs.SOUND_HUD_MENU_POPUP)
		self._panel.binder.pnl_options:createTransition("activate_above")
		self._panel.binder.pnl_options:setVisible(true)	

	elseif not show and self._panel.binder.pnl_options:isVisible() then
        MOAIFmodDesigner.playSound(cdefs.SOUND_HUD_MENU_POPDOWN)
		self._panel.binder.pnl_options:createTransition("deactivate_above",
			function( transition )
				self._panel.binder.pnl_options:setVisible( false )
			end,
			{ easeOut = true } )
	end

    self._panel.binder.showOptionsBtn:setChecked( show )
end

function generationOptions:selectDifficulty( diff )
    log:write("generationOptions:selectDifficulty")
    if diff == self._diff then
        log:write("   no change: %s", tostring(diff))
        return
    end

    local widget = self._difficultyButtons[ diff ]
    assert( widget, tostring(diff) )
    local difficultyMenu = nil
    for i, menu in ipairs( DIFFICULTY_MENU ) do
        if menu.diff == diff then
            difficultyMenu = menu
            break
        end
    end

    log:write("   selected: %s", difficultyMenu.name)

    for i, widgetSub in self._panel.binder:forEach( "menuBtn" ) do
        widgetSub.binder.btn:setColorInactive( unpack(MENU_UNSELECTED) )
        widgetSub.binder.btn:setTextColorInactive( unpack(INACTIVE_TXT) )
        widgetSub.binder.btn:updateImageState()
    end

    widget.binder.btn:setColorInactive( unpack(MENU_SELECTED) )
    widget.binder.btn:setTextColorInactive( unpack(ACTIVE_TXT) )
    widget.binder.btn:updateImageState()

    self._screen:findWidget( "diff_title" ):spoolText( difficultyMenu.short_desc )
    self._screen:findWidget( "diff_txt" ):setText( difficultyMenu.desc )

    self._diff = diff

    if diff == simdefs.CUSTOM_DIFFICULTY then
        self:showDifficultyOptions( true )
    else
        -- Reset the difficulty options to the custom options widgets.
        self:applyOptions( simdefs.DIFFICULTY_OPTIONS[ diff ] )
        self:applyDLCOptions( mod_manager:getModContentDefaults() )
    end
end

function generationOptions:onUnload()
	self._scroll_text:destroy()
    self._scroll_text = nil

	mui.deactivateScreen( self._screen )
    self._screen = nil
end

generationOptions._CHARACTER_IMAGES = CHARACTER_IMAGES

return generationOptions
