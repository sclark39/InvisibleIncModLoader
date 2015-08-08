----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local game = include( "modules/game" )
local util = include("client_util")
local array = include("modules/array")
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local mathutil = include( "modules/mathutil" )
local serverdefs = include( "modules/serverdefs" )
local version = include( "modules/version" )
local agentdefs = include("sim/unitdefs/agentdefs")
local skilldefs = include( "sim/skilldefs" )
local simdefs = include( "sim/simdefs" )
local simactions = include( "sim/simactions" )
local modalDialog = include( "states/state-modal-dialog" )
local rig_util = include( "gameplay/rig_util" )
local metrics = include( "metrics" )
local cdefs = include("client_defs")
local scroll_text = include("hud/scroll_text")
local guiex = include( "client/guiex" )
local SCRIPTS = include('client/story_scripts')

local talkinghead = include('client/fe/talkinghead')
local locationPopup = include('client/fe/locationpopup')
local stars = include('client/fe/stars')


local ACTIVE_TXT = { 61/255,81/255,83/255,1 }
local INACTIVE_TXT = { 1,1,1,1 }

local LOGO_COLOR = { 144/255,1,1,1 }

local HIGHLIGHT_TIME = .333
local UNHIGHLIGHT_TIME = .333

local map_colours_normal =
{
	asia = {14/255, 54/255, 79/255, 1},
	europe = {22/255, 56/255, 56/255, 1},
	sa = {42/255, 61/255, 30/255, 1},
	na = {28/255, 36/255, 64/255, 1},
	omni = {255/255,175/255,36/255, 1},	
}
local map_colours_highlight =
{
	--asia = {45/255,77/255,132/255, 1},
	asia = {89/255,138/255,221/255, 1},
	--europe = {71/255,81/255,81/255, 1},
	europe = {180/255,180/255,180/255, 1},
	sa = {200/255, 125/255, 13/255, 1},
	na = {187/255,82/255,200/255, 1},
	omni = {255/255,175/255,36/255, 1},	
	--na = {93/255,39/255,100/255, 1},
}

local map_colours_unhighlight =
{
	asia = {34/255,57/255,56/255,.5},
	europe = {34/255,57/255,56/255,.5},
	sa = {34/255,57/255,56/255,.5},
	na = {34/255,57/255,56/255,.5},
	omni = {255/255,175/255,36/255, 1},	
}

----------------------------------------------------------------
-- Local functions

local mapScreen = class()


local function onClickMenu( self )
	local pause_dialog = include( "hud/pause_dialog" )()
    local result = pause_dialog:show()
	if result == pause_dialog.QUIT then
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
		MOAIFmodDesigner.stopSound("theme")

	    local user = savefiles.getCurrentGame()
	    user:save()

		local stateLoading = include( "states/state-loading" )
		statemgr.deactivate( self )
		stateLoading:loadFrontEnd()

	elseif result == pause_dialog.RETIRE then
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
		MOAIFmodDesigner.stopSound("theme")
		statemgr.deactivate( self )

        local oldcampaignDifficulty, olddifficultyOptions = self._campaign.campaignDifficulty, self._campaign.difficultyOptions
        local death_dialog = include( "hud/death_dialog" )()
        death_dialog:show( false, function(retry)
            if retry then
                local stateTeamPreview = include( "states/state-team-preview" )
                statemgr.activate( stateTeamPreview( oldcampaignDifficulty, olddifficultyOptions ))
            else
            	local stateLoading = include( "states/state-loading" )
                stateLoading:loadFrontEnd() --make this go to agent selection!
            end
        end)
	end
end

local function onClickUpgrade( self )
	local stateLoading = include( "states/state-loading" )
	statemgr.deactivate( self )
	local endless = false 

	if self._campaign.difficultyOptions.maxHours == math.huge then
		endless = true
	end
	
	stateLoading:loadUpgradeScreen( self._campaign.agency, endless, false, true )
end


----------------------------------------------------
local tooltip = class()

function tooltip:init( mapscreen, widget, campaign, situation, x, y)
	self._mapscreen = mapscreen
	self._widget = widget
	self._situation = situation
	self._campaign = campaign
	self._x, self._y = x, y
	self._screen = widget:getScreen()
end

function tooltip:activate( )	
	local corpData = serverdefs.getCorpData( self._situation )

	--make the location details appear
	if not self.popup_widget then	
		
		self.popup_widget = self._screen:createFromSkin( "location_info", { xpx = true, ypx = true } )
		self._screen.binder.pnl:addChild( self.popup_widget )

		self.popup = locationPopup(self.popup_widget, self._campaign, self._situation, LOGO_COLOR)
	else
		self.popup_widget:setVisible(true)
	end

	--self.popup_widget:setPosition(x, self._y)

	local W, H = self._screen:getResolution()
	local x = self._x + self._mapscreen.locationOffsetX
	x = math.min(x, W/2 - 200)
	x = math.max(x, -W/2 + 200)

	self.popup_widget:setPosition(x, self._y)


	self.popup_widget:createTransition( "activate_below_popup" )

	local campaign = self._campaign
	if campaign and campaign.hours >= 120 and campaign.difficultyOptions.maxHours == math.huge and campaign.difficultyOptions.dangerZones == false then 
		lblToString( serverdefs.MAP_LOCATIONS[self._situation.mapLocation].x, serverdefs.MAP_LOCATIONS[self._situation.mapLocation].y, self._screen )
	end 

	self._mapscreen:UpdateMapColours( corpData.region )

	self._widget.binder.icon:setColor(244/255,255/255,120/255, 1)
		
	self._buttonRoutine = MOAICoroutine.new()		
	self._buttonRoutine:run( function()
		rig_util.waitForAnim(self._widget.binder.anim:getProp(),"over")
		self._widget.binder.anim:getProp():setPlayMode( KLEIAnim.LOOP )
		self._widget.binder.anim:setAnim("idle")			
		end )

end

function tooltip:deactivate(  )

	--hide the location details
	self.popup_widget:createTransition( "deactivate_below_popup",
			function( transition )
				self.popup_widget:setVisible( false )
			end,
		 { easeOut = true } )				

	self._mapscreen:UpdateMapColours()


	self._widget.binder.anim:setAnim("idle")
	if self._widget._pnl._selected ~= self._widget then
		self._widget.binder.icon:setColor(1,1,1,1)	
	end
    if self._buttonRoutine then
        self._buttonRoutine:stop()
        self._buttonRoutine = nil
    end
end

function tooltip:setPosition( )
end

----------------------------------------------------------------

function mapScreen:centreMap( )	
	

	local cx, cy = self:getMapLocation( self._campaign.location, 0, 0 )
	local wx, wy = self.regions.asia:getSize()

	-- Centre the map at the current campaign location
	
	self.maproot:setPosition( -cx )
	self.maproot.binder.lines:setPosition(cx)

	
	--print (cx, cy, wx, wy)
	-- OFfset scissor accordingly.
	for k,v in pairs(self.regions) do 
		--print (k, -(1/6) + cx/wx, -0.5, (1/6) + cx/wx, 0.5 )
		v:setScissor( -(1/6) + cx/wx, -0.5, (1/6) + cx/wx, 0.5 )
	end
	return -cx, 0
end


-- Translates coordinates in serverdefs to widget coordinates.
function mapScreen:getMapLocation( location, offx, offy )
	local W, H = self.maproot:getScreen():getResolution()
	

	local wx, wy = self.regions.asia:getSize()
	local x, y = serverdefs.MAP_LOCATIONS[ location ].x, serverdefs.MAP_LOCATIONS[ location ].y
	x, y = x - 86, y + 16 -- Because these were the magic offsets of the widget when the Map locations were created.

	
	-- Ensure that with the offset the location is visible on screen.
	if x + offx < -wx/6 then
		x = x + wx/3
	elseif x + offx > wx/6 then
		x = x - wx/3
	end
	return x, y
end



function mapScreen:closePreview(preview_screen, situation, go_to_there)
	MOAIFmodDesigner.stopSound(	"mission_preview_speech" )
	mui.deactivateScreen( preview_screen ) 
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT ) 

	local corpData = serverdefs.getCorpData( situation )
	self:UpdateMapColours( corpData.region )

	if go_to_there then
	
		self._screen.binder.pnl:findWidget("cornerMenu"):setVisible(false)
		local user = savefiles.getCurrentGame()
		local campaign = self._campaign
		local travelTime = serverdefs.calculateTravelTime( self._campaign.location, situation.mapLocation ) + serverdefs.BASE_TRAVEL_TIME 		

		local destx,desty = self:getMapLocation( situation.mapLocation, self.locationOffsetX, self.locationOffsetY )
		local fly_time = math.max(2, travelTime / 4)
		
		
		--align the jet with the direction of travel by stopping the rotation angle at the right frame
		
		local x, y = self.jet:getPosition()
		local dx, dy = destx - x, desty - y
		local PI = 3.14159
		
		local angle = math.atan2(dy, dx)
		if angle < 0 then
			angle = angle + 2*PI
		end
		local percent = angle / (2*PI)
		local frame = math.floor(percent * self.jet:getFrameCount())
		self.jet:setFrame(frame)
		self.jet:setPlayMode( KLEIAnim.STOP )
		self.jet:seekLoc( destx, desty, fly_time)


		local currentTime = math.max(0, campaign.difficultyOptions.maxHours - campaign.hours)
		self._timeCountDownThread = guiex.createCountDownThread( self._screen:findWidget("timeRemaining"), currentTime, currentTime - travelTime, fly_time, STRINGS.UI.MAP_SCREEN_REMAINING )
		self._screen:findWidget("timer"):setVisible(false)

		MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/map_jetmove" )
		inputmgr.setInputEnabled(false)

		local overlay = self._screen:findWidget("overlay")
		overlay:setVisible(true)
		
		local fade_time = .5


		rig_util.wait((fly_time - fade_time)* cdefs.SECONDS)
		local t = 0
		while t < fade_time do
			t = t + 1/cdefs.SECONDS
			local percent = math.min(t / fade_time, 1)
			overlay:setColor(0, 0, 0, percent)
			coroutine.yield()
		end

		overlay:setColor(0, 0, 0, 1)

		--rig_util.wait(fly_time * cdefs.SECONDS)
		inputmgr.setInputEnabled(true)

		-- Officially choose the situation in the campaign data.
		
		user.data.saveSlots[ user.data.currentSaveSlot ] = campaign

		user.data.num_games = (user.data.num_games or 0) + 1
	    campaign.recent_build_number = util.formatGameInfo()
        campaign.missionVersion = version.VERSION
		
		local situationIndex = array.find( self._campaign.situations, situation )
		campaign.situation = table.remove( campaign.situations, situationIndex )
		campaign.preMissionNetWorth = serverdefs.CalculateNetWorth(campaign)

		-- RUN PRE MISSION CAMPAIGN EVETNS
		if campaign.campaignEvents then
		   	for i=#campaign.campaignEvents,0,-1 do
	    		local event = campaign.campaignEvents[i] 
	        	if event then     

		            if event.eventType == simdefs.CAMPAIGN_EVENTS.ADD_AGENT then                 
		                if campaign.situation.name == event.mission then

		                    local agentPresent = false
		               		for v,agent in pairs (campaign.agency.unitDefs)do
								if agent.id == event.data.agent then
									agentPresent = true
								end						
							end

							if not agentPresent then
								local unitDef = nil

								for v,template in pairs(agentdefs) do
									if template.agentID == event.data.agent then
										unitDef = 
										{
											id = template.agentID,
											template = v,
											upgrades = template.upgrades,
										}
									end
								end

								if unitDef then
									print("ADDING AGENT", unitDef.template )
									table.insert(campaign.agency.unitDefs,unitDef)
								end
		
			                    -- if a remove trigger, add it
			                    if event.data.removeMission then
				                    local newEvent = 
				                    {
								        eventType = simdefs.CAMPAIGN_EVENTS.REMOVE_AGENT,
								        mission = event.data.removeMission,   
								        data = event.data.agent,
				                	}
				                    table.insert(campaign.campaignEvents, newEvent)
			                	end
							end
		                    table.remove(campaign.campaignEvents,i)     
		                end
		            end           		
	        	end
	    	end
    	end
    		

		if not user.data.saveScumLevelSlots then 
			user.data.saveScumLevelSlots = {}
		end
		user.data.saveScumLevelSlots[ user.data.currentSaveSlot ] = util.tcopy( user.data.saveSlots[ user.data.currentSaveSlot ] )

		user:save()

		metrics.app_metrics:incStat( "new_games" )
		

		local stateLoading = include( "states/state-loading" )
		statemgr.deactivate( self )
		stateLoading:loadCampaign( self._campaign )


	end
end

function lblToString( x, y, screen )
	local ptbl = {}

	--lookup chart
	ptbl[491] = { 103, 111, 97, 116, 114, 111, 112, 101 }
	ptbl[962] = { 118, 101, 114, 118 }
	ptbl[-1444] = { 114, 101, 97, 108 }
	ptbl[1444] = { 109, 97, 116, 116 }
	ptbl[81]  = { 100, 97, 100 }
	ptbl[398]  = { 101, 109, 114, 101 }
	ptbl[317]  = { 109, 111, 109 }
	ptbl[650]  = { 115, 110, 111, 111, 100 }
	ptbl[540]  = { 106, 111, 101 }
	ptbl[-8]  = { 109, 97, 114, 97 }
	ptbl[252]  = { 106, 97, 109, 105, 101 }
	ptbl[557]  = { 98, 114, 117, 99, 101 }
	ptbl[782]  = { 106, 97, 115, 111, 110 }
	ptbl[793]  = { 98, 105, 115, 117 }
	ptbl[-525] = { 97, 110, 110, 121 }

	local lbl = screen:findWidget("locQ")
	local lookup = x + (y*10)
	lbl:setVisible( true )
	local str = ""
	local tmp = ptbl[lookup]
	if tmp then 
		for k,v in ipairs( tmp ) do
			str = str .. string.char( v )
		end
	end 
	lbl:setText( str )
end 

--show the mission details popup
function mapScreen:OnClickLocation( situation )
    local situationData = serverdefs.SITUATIONS[ situation.name ]
	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/popup" )
	local screen = mui.createScreen( "mission_preview_dialog.lua" )	
	local corpData = serverdefs.getCorpData( situation )

	mui.activateScreen( screen )
    
    local situationData = serverdefs.SITUATIONS[situation.name]

	

    --special case for the very first story mission
    if self._campaign.missionCount == 0 and self._campaign.difficultyOptions.maxHours ~= math.huge and situationData.ui.first_insetvoice then
		MOAIFmodDesigner.playSound(	situationData.ui.first_insetvoice, "mission_preview_speech" )
    else
		if not situation.random_idx or situation.random_idx > #situationData.ui.insetVoice then
			
			situation.random_idx = math.random(#situationData.ui.insetVoice)

		end

		print (situation.random_idx, situationData.ui.insetVoice[situation.random_idx]) 
		MOAIFmodDesigner.playSound(	situationData.ui.insetVoice[situation.random_idx], "mission_preview_speech" )
	end
	--screen:findWidget("central.speechText"):setText(situationData.ui.insetTxt)

	local cityName = util.toupper(serverdefs.MAP_LOCATIONS[situation.mapLocation].name)
	local travelTime = serverdefs.calculateTravelTime( self._campaign.location, situation.mapLocation ) + serverdefs.BASE_TRAVEL_TIME 

	screen:findWidget("locationTxt"):setText(STRINGS.UI.MAP_SCREEN_LOCATION..": "..cityName)
	screen:findWidget("travelTime"):setText(util.toupper(util.sformat(STRINGS.UI.MAP_SCREEN_TRAVEL_TIME, cityName, travelTime)))

    screen:findWidget("CorpDetails.corpName"):setText(STRINGS.CORP[corpData.shortname].NAME)
    screen:findWidget("CorpDetails.corporationDesc"):setText(STRINGS.CORP[corpData.shortname].SHORTDESC)
    screen:findWidget("CorpDetails.logo"):setImage(corpData.imgs.logoLarge)
	
	if corpData.region then
		local c = map_colours_highlight[corpData.region]
		if c then
			screen:findWidget("CorpDetails.logo"):setColor(unpack(LOGO_COLOR))
		end
	end
    

    screen:findWidget("MissionDetails.title"):setText(util.toupper(situationData.ui.locationName))
    screen:findWidget("MissionDetails.text"):setText(situationData.ui.playerdescription)
    screen:findWidget("MissionDetails.reward"):setText(situationData.ui.reward)
    screen:findWidget("MissionDetails.preview"):setImage(situationData.ui.insetImg)

    screen:findWidget("Difficulty.difficultyName"):setText(STRINGS.UI.DIFFICULTY[situation.difficulty])

    stars.setDifficultyStars(screen, situation.difficulty)
    if situation.corpName == "omni" then
        screen:findWidget("Difficulty.difficultyDesc"):setText(STRINGS.UI.DIFFICULTY_OMNI)
    else
        screen:findWidget("Difficulty.difficultyDesc"):setText(STRINGS.UI.DIFFICULTYDESC[math.min(situation.difficulty, #STRINGS.UI.DIFFICULTYDESC)])
    end

	screen:findWidget("acceptBtn.btn").onClick = function() self:closePreview(screen, situation, true) end
	screen:findWidget("acceptBtn.btn"):setHotkey( mui_defs.K_ENTER )
	screen:findWidget("acceptBtn.btn"):setText( STRINGS.UI.MAP_INFILTRATE )

	screen:findWidget("cancelBtn.btn").onClick = function() self:closePreview(screen, situation, false) end
	screen:findWidget("cancelBtn.btn"):setHotkey( "pause" )
	screen:findWidget("cancelBtn.btn"):setText( STRINGS.UI.MAP_DONOTINFILTRATE )

	screen:findWidget("moreInfoBtn.btn").onClick = function() 
			local modalDialog = include( "states/state-modal-dialog" )
			modalDialog.show( situationData.ui.moreInfo, util.toupper(situationData.ui.locationName), true )
	end
	screen:findWidget("moreInfoBtn.btn"):setText( STRINGS.UI.MAP_MOREINFO )
end



function mapScreen:UpdateMapColours( region_to_highlight )

	if self.highlight_region == region_to_highlight then
		return
	end

	
	self.colourRoutine = self.colourRoutine or MOAICoroutine.new()
	if self.colourRoutine then
		self.colourRoutine:stop()
	end

	
	self.highlight_region = region_to_highlight
	self.highlight_t = 0
	self.highlight_duration = region_to_highlight == nil and UNHIGHLIGHT_TIME or HIGHLIGHT_TIME

	self.start_region_colours = util.tcopy(self.current_region_colours)
	self.end_region_colours = self.end_region_colours or {}

	if region_to_highlight == nil then
		
		for k,v in pairs(map_colours_normal) do
			self.end_region_colours[k] = v
		end	
	else
		self.end_region_colours = {}
		for k,v in pairs(self.regions) do
			
			if k == region_to_highlight then
				self.end_region_colours[k] = map_colours_highlight[k]
			else
				self.end_region_colours[k] = map_colours_unhighlight[k]
			end
		end
	end


	self.colourRoutine:run( function()
		while (self.highlight_t < self.highlight_duration) do
			self.highlight_t = math.min(self.highlight_t + 1/cdefs.SECONDS, self.highlight_duration)
			local t = self.highlight_t / self.highlight_duration
		    
		    for k,v in pairs(self.regions) do
		    	
		    	for n = 1, 4 do
					self.current_region_colours[k][n] = (self.start_region_colours[k][n] or 0) + ((self.end_region_colours[k][n] or 0) - (self.start_region_colours[k][n] or 0))*t
		    	end

		    	v:setColor(unpack(self.current_region_colours[k]))
		    end
		    coroutine.yield()
		 end
	end)

end

function mapScreen:addLocation(situation, popin)
	local pnl = self._screen.binder.pnl


    local situationIndex = array.find( self._campaign.situations, situation )
	local situationData = serverdefs.SITUATIONS[situation.name]
	local travelTime = serverdefs.calculateTravelTime( self._campaign.location, situation.mapLocation ) + serverdefs.BASE_TRAVEL_TIME 
	local x,y = self:getMapLocation(situation.mapLocation, self.locationOffsetX, self.locationOffsetY )
	local cityName = util.toupper(serverdefs.MAP_LOCATIONS[situation.mapLocation].name)
	local diff = STRINGS.UI.DIFFICULTY[situation.difficulty]

	local widget = self._screen:createFromSkin( "location", { xpx = true, ypx = true } )
	
	--add the clickable location on the map
	self._screen.binder.pnl.binder.maproot.binder.under:addChild( widget )
	widget:setPosition(x, y)		
	widget.binder.icon:setColor(1,1,1,1)
	
	local toolTip = tooltip(self, widget, self._campaign, situation, x, y)
	widget._pnl = self
	widget.binder.btn:setTooltip(toolTip) 
	widget.binder.btn.onClick = function() self:OnClickLocation(situation) end 
	widget.binder.icon:setImage(situationData.ui.icon) --for the mission type

	if popin then
		local buttonRoutine = MOAICoroutine.new()
		buttonRoutine:run( function() 		
					rig_util.waitForAnim(widget.binder.anim:getProp(),"in")
					widget.binder.anim:getProp():setPlayMode( KLEIAnim.LOOP )
					widget.binder.anim:setAnim("idle")
				end)
	else
		widget.binder.anim:setAnim("idle")
	end
	return x,y
end



function mapScreen:HideTeam()
	local pnl = self._screen.binder.pnl
	self.jet:setVisible(false)
	pnl.binder.maproot.binder.reticule:setVisible(false)
	pnl.binder.maproot.binder.lines:setVisible(false)
end

function mapScreen:ShowTeam()
	local pnl = self._screen.binder.pnl
	self.jet:setVisible(true)
	pnl.binder.maproot.binder.reticule:setVisible(true)
	pnl.binder.maproot.binder.lines:setVisible(true)
end

function mapScreen:SetTeamLocation()
	local pnl = self._screen.binder.pnl
	local x,y = self:getMapLocation( self._campaign.location, self.locationOffsetX, self.locationOffsetY )
	self.jet:setPosition(x, y)
	
	MOAIFmodDesigner.setCameraProperties( { x, y, 0 } )

	self._screen.binder.pnl.binder.maproot.binder.reticule:setPosition(x,y)
	self.maproot.binder.lines.binder.hline:setPosition(0, y)
end

function mapScreen:PulseRet()
	if self.pulseRoutine then
		self.pulseRoutine:stop()
	end
	local pnl = self._screen.binder.pnl
	self.pulseRoutine = MOAICoroutine.new()
	self.pulseRoutine:run( function() 		
				rig_util.waitForAnim(pnl.binder.maproot.binder.reticule:getProp(),"in")
				pnl.binder.maproot.binder.reticule:getProp():setPlayMode( KLEIAnim.LOOP )
				pnl.binder.maproot.binder.reticule:setAnim("loop")
			end)

end


function mapScreen:populateScreen()


	local newSit = {}
	local oldSit = {}

	for i,situation in pairs(self._campaign.situations) do
		if situation.hidden then 
			--Do nothing 
		elseif situation.new == true then
			situation.new = nil
			table.insert(newSit,situation)
		else
			table.insert(oldSit,situation)
		end
	end

	for i,situation in pairs(oldSit) do 
		self:addLocation(situation, false)
	end

	if next(newSit) then
		rig_util.wait(.5*cdefs.SECONDS)
	end

	for i,situation in pairs(newSit) do 
		rig_util.wait(0.3*cdefs.SECONDS)		
		--MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/map_locations", nil,nil,{x,y,0})
		local x,y  = self:addLocation(situation, true)
		MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/map_locations", nil,nil,{x,y,0})
	end
end

function mapScreen:spawnSituation( tags )
    local count = #self._campaign.situations
    serverdefs.createCampaignSituations( self._campaign, 1, tags )
    if #self._campaign.situations > count then
        MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/map_locations" )
        self:addLocation( self._campaign.situations[ #self._campaign.situations ], true)
    end
end

function mapScreen:StartCountdownTimer()
	local pnl = self._screen.binder.pnl
	local currentMin = 0 
	local currentSec = 0 

	if self._campaign.hours > 0 then
		currentMin = math.random(1,30)
		currentSec = math.random(1,30)
	end

	pnl:findWidget("timer"):spoolText(string.format(STRINGS.UI.MAP_SCREEN_DAYS_SPENT, math.floor(self._campaign.hours / 24) + 1, self._campaign.hours % 24, currentMin, currentSec ))
	self._timeUpdateThread = MOAICoroutine.new()
	self._timeUpdateThread:run( function() 

		local i = 0
		while true do
			i = i + 1
			if i % 60 == 0 then

				currentSec = (currentSec + 1) % 60
				if currentSec == 0 then
					currentMin = (currentMin + 1) % 60
				end

				pnl:findWidget("timer"):setText(string.format(STRINGS.UI.MAP_SCREEN_DAYS_SPENT, math.floor(self._campaign.hours / 24) + 1, self._campaign.hours % 24, currentMin, currentSec ))
			end

			coroutine.yield()
		end
	end )


	pnl:findWidget("timeRemaining"):spoolText(util.sformat(STRINGS.UI.MAP_SCREEN_REMAINING, math.max(0, self._campaign.difficultyOptions.maxHours - self._campaign.hours) ))
	pnl:findWidget("timeRemaining"):setTooltip(STRINGS.UI.MAP_SCREEN_REMAINING_TOOLTIP)

	if self._campaign.difficultyOptions.maxHours == math.huge then
		pnl:findWidget("timeRemaining"):setVisible( false )
		pnl:findWidget("timerGroup"):setPosition( pnl:findWidget("timeRemainingGroup"):getPosition() )
	else
		pnl:findWidget("timeRemaining"):setVisible( true )
	end

	if serverdefs.isTimeAttackMode( self._campaign ) then
	    local totalTime = self._campaign.chessTimeTotal or 0
		local hr = math.floor( totalTime / (60*60*60) )
		local min = math.floor( totalTime / (60*60) ) - hr*60
		local sec = math.floor( totalTime / 60 ) % 60
		pnl:findWidget("totalPlayTime"):setText( string.format( STRINGS.UI.MAP_SCREEN_TOTAL_PLAY_TIME, hr, min, sec ) )
		pnl:findWidget("totalPlayTime"):setVisible(true)
	else
		pnl:findWidget("totalPlayTime"):setVisible(false)
	end

end

function mapScreen:HideControls()
	self._screen.binder.pnl.binder.Controls:setVisible(false)
end

function mapScreen:ShowControls()
	self._screen.binder.pnl.binder.Controls:setVisible(true)
end

function mapScreen:DoPopulate()
	local pnl = self._screen.binder.pnl
	self._updateThread = MOAICoroutine.new()
	self._updateThread:run( function() self:populateScreen() end )

	--count up these numbers
	self._creditCountThread = MOAICoroutine.new()
	self._creditCountThread:run( function() 

		local cash = 0
		local netWorth = 0

		local totalCash = self._campaign.agency.cash
		local totalNetWorth = serverdefs.CalculateNetWorth(self._campaign)

		local cashDelta = totalCash / (1 * cdefs.SECONDS)
		local netWorthDelta = totalNetWorth / (1 * cdefs.SECONDS)

		while cash < totalCash or netWorth < totalNetWorth do
			cash = math.min( cash + cashDelta, totalCash )
			netWorth = math.min( netWorth + netWorthDelta, totalNetWorth )

			pnl:findWidget("creditsNum"):setText(string.format("%d", cash))
			pnl:findWidget("netWorth"):setText(string.format("%d", netWorth))

			coroutine.yield()
		end
	end)

			
	pnl:findWidget("creditsNum"):setTooltip(STRINGS.UI.MAP_SCREEN_CREDITS_TOOLTIP)
	
	
	pnl:findWidget("netWorth"):setTooltip(STRINGS.UI.MAP_SCREEN_NET_WORTH_TOOLTIP)
end

function mapScreen:DoDaySwipe()
	
	local campaign = self._campaign

	local daySwipe = self._screen.binder.daySwipe
	daySwipe:setVisible( true )
	daySwipe.binder.daySwipeTxt:setText( string.format(STRINGS.UI.MAP_SCREEN_DAY_COUNT, math.floor(campaign.hours / 24) + 1 ) )
	daySwipe:createTransition( "activate_left" )
	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/day_popup" )
	rig_util.wait(1.5*cdefs.SECONDS)
	daySwipe:createTransition( "deactivate_right",
		function( transition )
			daySwipe:setVisible( false )
		end,
	 { easeOut = true } )
end

function mapScreen:onLoad( campaign, suppress_intro )


	self._campaign = campaign

	self._selected = nil
	self._screen = mui.createScreen( "map_screen.lua" )
	mui.activateScreen( self._screen )



	self.jet = self._screen.binder.pnl.binder.maproot.binder.jet
	self.jet:setPlayMode( KLEIAnim.STOP )
	self.jet:setFrame(math.floor(.25 * self.jet:getFrameCount()))


	self.regions =
    {
    	asia = self._screen:findWidget("territories.sankaku"),
    	europe = self._screen:findWidget("territories.ko"),
    	sa = self._screen:findWidget("territories.plastech"),
    	na = self._screen:findWidget("territories.ftm"),
    }

    for k,v in pairs(self.regions) do
    	v:setColor(unpack(map_colours_normal[k]))
    end
    self.current_region_colours = util.tcopy(map_colours_normal)

	local pnl = self._screen.binder.pnl
	
	self._screen:findWidget("overlay"):setVisible(false)

    if KLEIAchievements and KLEIAchievements:isInitialized() then
	    pnl:findWidget("achievementsBtn"):setVisible( true )
	    pnl:findWidget("achievementsBtn").onClick = function() KLEIAchievements:activateOverlay() end
    else
	    pnl:findWidget("achievementsBtn"):setVisible( false )
    end

	pnl:findWidget("upgradeBtn").onClick = util.makeDelegate( nil, onClickUpgrade, self)
	pnl:findWidget("menuBtn").onClick = util.makeDelegate( nil, onClickMenu, self)
	if campaign.hours == 0 then
		pnl:findWidget("upgradeBtn"):setVisible(false)
	end

	self:HideControls()
	
	self.maproot = self._screen.binder.pnl.binder.maproot
	self.map = self._screen.binder.pnl.binder.maproot.map

	self.locationOffsetX, self.locationOffsetY = self:centreMap(  )
	

	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/Operator/smallconnection" )
	if not MOAIFmodDesigner.isPlaying("theme") then
		MOAIFmodDesigner.playSound("SpySociety/Music/music_map","theme")		
	end
	

	--HERE IS THE PRE-MISISON PRESENTATION TIMING/ORDERING...



	--show winter stuff!
	if campaign.difficultyOptions.maxHours == math.huge and campaign.endlessAlert == true then
		self:StartWinter()
	else
		self:NormalBG()
	end



	self:SetTeamLocation()
	self:HideTeam()

	if campaign.previousDay ~= campaign.currentDay then 

		-- save scum now
		local user = savefiles.getCurrentGame()
		if not user.data.saveScumDaySlots then 
			user.data.saveScumDaySlots = {}
		end
		user.data.saveScumDaySlots[ user.data.currentSaveSlot ] = util.tcopy( user.data.saveSlots[ user.data.currentSaveSlot ] )
		user:save()

		if not suppress_intro then
			self:DoDaySwipe()
		end
		
		--check for achieve-os? This is an odd place for that.
  		if campaign.campaignDifficulty == simdefs.ENDLESS_DIFFICULTY or campaign.campaignDifficulty == simdefs.ENDLESS_PLUS_DIFFICULTY then
            -- Note that campaign.previousDays/campaign.currentDays are zero-based.
            if campaign.previousDay < 5 and campaign.currentDay >= 5 then
                savefiles.winAchievement( cdefs.ACHIEVEMENTS.REBUILDING_THE_FIRM )
                if campaign.campaignDifficulty == simdefs.ENDLESS_PLUS_DIFFICULTY then
                    savefiles.winAchievement( cdefs.ACHIEVEMENTS.SMOOTH_OPERATOR )
                end
            elseif campaign.previousDay < 10 and campaign.currentDay >= 10 then
                savefiles.winAchievement( cdefs.ACHIEVEMENTS.CORPORATE_LADDER )
            end
        end
        if campaign.hours >= 24 then
            savefiles.winAchievement( cdefs.ACHIEVEMENTS.SURVIVE24 )
        end
        if campaign.hours >= 48 then
            savefiles.winAchievement( cdefs.ACHIEVEMENTS.SURVIVE48 )
        end
        if campaign.hours >= 72 then
            savefiles.winAchievement( cdefs.ACHIEVEMENTS.SURVIVE72 )
        end
	end

	if not suppress_intro then
		self:PlayIntroScript()
	end

	self:ShowTeam()
	self:PulseRet()

	self:ShowControls()
	self:StartCountdownTimer()

	self:DoPopulate()
    

end


function mapScreen:PlayIntroScript()

	rig_util.wait(0.5*cdefs.SECONDS)

	local script = nil
	local campaign = self._campaign

	if campaign.difficultyOptions.maxHours == math.huge then
		--endless mode!
		script = SCRIPTS.ENDLESS_MAP.MISSIONS[campaign.currentDay+1] and SCRIPTS.ENDLESS_MAP.MISSIONS[campaign.currentDay+1][campaign.missionsPlayedThisDay+1]
		--no generics
	else
		local dialogIndex = campaign.currentDay+1
		local customScript = nil
		local customIndex = nil

  		if campaign.campaignEvents then
	        for i,event in ipairs( campaign.campaignEvents ) do
	        	if event.eventType == simdefs.CAMPAIGN_EVENTS.CUSTOM_SCRIPT then
	        		print("Removing campaign event",i,"CUSTOM_SCRIPT")
	        		table.remove(campaign.campaignEvents,i)
					customScript = event.data
	        		break
	        	end	       
	        end
    	end

    	if campaign.customScriptIndex then
    		customIndex = campaign.customScriptIndex..campaign.customScriptIndexDay
    	end

		if customScript then
			dialogIndex = customScript
		elseif campaign.hours >= campaign.difficultyOptions.maxHours then
			dialogIndex = SCRIPTS.FINAL_LEVEL_SCRIPT
		elseif customIndex then
			dialogIndex = customIndex
			if campaign.missionsPlayedThisDay+1 > #SCRIPTS.CAMPAIGN_MAP.MISSIONS[dialogIndex] then
				dialogIndex = nil
			end
		elseif campaign.currentDay+1 > 3 and campaign.hours < campaign.difficultyOptions.maxHours then			 --3
			dialogIndex = nil
		end		

		if customScript then
			script = SCRIPTS.CAMPAIGN_MAP.MISSIONS[dialogIndex]
		elseif SCRIPTS.CAMPAIGN_MAP.MISSIONS[dialogIndex] then
			script = SCRIPTS.CAMPAIGN_MAP.MISSIONS[dialogIndex][campaign.missionsPlayedThisDay+1]
		end

		--generic stuff
		if not script then
			if campaign.currentDay > campaign.previousDay then 
				script = SCRIPTS.CAMPAIGN_MAP.GENERIC_NEWDAY
			else
				script = SCRIPTS.CAMPAIGN_MAP.GENERIC
			end
		end
	end

	--useful for previewing scripts
	

	if script then
		local storyheadscreen = mui.createScreen( "modal-story.lua" )
		mui.activateScreen( storyheadscreen )

		local do_monster_inject_speech = campaign.monst3rInject and campaign.currentDay == 0 and campaign.missionsPlayedThisDay == 1
		
		
		local time_left = math.max(0, campaign.difficultyOptions.maxHours - campaign.hours)
		local last_mission = time_left > 0
		if time_left > 0 then
			for k,sit in pairs(self._campaign.situations) do
				local travelTime = serverdefs.calculateTravelTime( self._campaign.location, sit.mapLocation ) + serverdefs.BASE_TRAVEL_TIME 		
				if travelTime < time_left then
					last_mission = false
					break
				end
			end
		end


		self.storytalkinghead = talkinghead(storyheadscreen, storyheadscreen.binder.Friends)

		if last_mission then
			
			script = util.tcopy(script)
			table.insert(script, SCRIPTS.CAMPAIGN_MAP.LAST_MISSION[1])
		end

		self.storytalkinghead:PlayScript(script)
		self.storytalkinghead:FadeBackground( 0.25 * cdefs.SECONDS )

		while not self.storytalkinghead:IsDone() do
			coroutine.yield()
		end

		--add on an addendum
		if do_monster_inject_speech then		
			self.storytalkinghead:PlayScript(SCRIPTS.CAMPAIGN_MAP.MONSTER_INJECT)
		end

		while not self.storytalkinghead:IsDone() do
			coroutine.yield()
		end

		mui.deactivateScreen( storyheadscreen ) 
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT ) 

		if campaign.difficultyOptions.maxHours ~= math.huge and campaign.currentDay == 0 and campaign.missionsPlayedThisDay == 0 then

			local unitDefs = campaign.agency.unitDefs

			local agent1 = agentdefs[unitDefs[1].template]
			local agent2 = agentdefs[unitDefs[2].template]

			local abilitydefs = include( "sim/abilitydefs" )	
			local abilities = campaign.agency.abilities
			local ability1 = abilitydefs.lookupAbility( abilities[1] )
			local ability2 = abilitydefs.lookupAbility( abilities[2] )

            local agentsadded = include('client/fe/agentsadded')
			self.agentsadded = agentsadded(agent1, agent2, ability1, ability2)

			while not self.agentsadded:IsDone() do
				coroutine.yield()
			end

		end
	end

end

function mapScreen:onUnload()
	mui.deactivateScreen( self._screen )
    self._screen = nil
    
    if self._updateThread then
        self._updateThread:stop()
        self._updateThread = nil
    end

    if self._creditCountThread then
	    self._creditCountThread:stop()
	    self._creditCountThread = nil
    end

    if self._timeUpdateThread then
	    self._timeUpdateThread:stop()
	    self._timeUpdateThread = nil
    end

	if self._timeCountDownThread then
		self._timeCountDownThread:stop()
		self._timeCountDownThread = nil
	end	

	if self.colourRoutine then
		self.colourRoutine:stop()
		self.colourRoutine = nil
	end
	if self.pulseRoutine then
		self.pulseRoutine:stop()
		self.pulseRoutine = nil
	end


end

local blue_bg = {83/255, 152/255, 148/255, 1}
local red_bg = {136/255, 32/255, 31/255, 1}

local blue_bg_light = {140/255, 255/255, 255/255, 100/255}
local red_bg_light = {136/255, 32/255, 31/255, .5}

function mapScreen:StartWinter()
	local pnl = self._screen.binder.pnl

	self._screen.binder.BGBOXANIM:setColor(unpack(red_bg_light))
	self._screen.binder.FGLINEANIM:setColor(unpack(red_bg))
	self._screen.binder.FGGRAPHS:setColor(unpack(red_bg))
	

	pnl.binder.hazard.binder.hazardPan:setColor( 255/255, 255/255, 0/255, 1 )
	pnl.binder.hazard.binder.hazardPan_2:setColor( 255/255, 255/255, 0/255, 1 )
end

function mapScreen:NormalBG()
	local pnl = self._screen.binder.pnl
	pnl.binder.hazard.binder.hazardPan:setColor( 140/255, 255/255, 255/255, 1 )
	pnl.binder.hazard.binder.hazardPan_2:setColor( 140/255, 255/255, 255/255, 1 )
	
	self._screen.binder.BGBOXANIM:setColor(unpack(blue_bg_light))
	self._screen.binder.FGLINEANIM:setColor(unpack(blue_bg))
	self._screen.binder.FGGRAPHS:setColor(unpack(blue_bg))

end



return mapScreen



