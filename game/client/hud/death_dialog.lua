----------------------------------------------------------------
-- Copyright (c) 2014 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local util = include( "client_util" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local gameobj = include( "modules/game" )
local cdefs = include("client_defs")
local agentdefs = include("sim/unitdefs/agentdefs")
local rig_util = include( "gameplay/rig_util" )
local metadefs = include( "sim/metadefs" )
local modalDialog = include( "states/state-modal-dialog" )
local simdefs = include( "sim/simdefs" )

----------------------------------------------------------------
-- Local functions

local POSITIVE_COLOR = { 140/255, 1, 1, 1 }

local WIN_STRINGS =
{
    [ simdefs.CUSTOM_DIFFICULTY ] = STRINGS.WIN_TIPS.CUSTOM,
    [ simdefs.NORMAL_DIFFICULTY ] = STRINGS.WIN_TIPS.BEGINNER,
    [ simdefs.EXPERIENCED_DIFFICULTY ] = STRINGS.WIN_TIPS.EXPERIENCED,
    [ simdefs.HARD_DIFFICULTY ] = STRINGS.WIN_TIPS.EXPERT,
    [ simdefs.VERY_HARD_DIFFICULTY ] = STRINGS.WIN_TIPS.EXPERT_PLUS,
    [ simdefs.ENDLESS_DIFFICULTY ] = "",
    [ simdefs.ENDLESS_PLUS_DIFFICULTY ] = "",
    [ simdefs.TIME_ATTACK_DIFFICULTY ] = "",
    [ simdefs.TUTORIAL_DIFFICULTY ] = "",
}

----------------------------------------------------------------

local death_dialog = class()


function death_dialog:OnClickRetry( option )
	self:hide()	-- Kill this screen.
	
	if self.onfinishfn then
		self.onfinishfn( option )
	end

end


function death_dialog:init()
	local screen = mui.createScreen( "death-dialog.lua" )

	self._screen = screen
	self._campaignWin = false
end 

function death_dialog:show( campaignWin, onfinishfn )
	mui.activateScreen( self._screen ) 

	MOAIFmodDesigner.stopSound("alarm")
	MOAIFmodDesigner.playSound( "SpySociety/Music/stinger_victory")
	MOAIFmodDesigner.stopMusic()

	self.onfinishfn = onfinishfn
	self._analysisIdx = 1
	self._campaignWin = campaignWin

	--Get/set initial XP, XP Ratio. 
	for i, widget in self._screen.binder.pnl.binder:forEach( "stat" ) do
		widget:setVisible( false )
	end

	FMODMixer:pushMix("frontend")

	self:populate( )
end

function death_dialog:hide()
	if self._screen:isActive() then
		mui.deactivateScreen( self._screen )
		FMODMixer:popMix("frontend")

		if self._updateThread then
			self._updateThread:stop()
			self._updateThread = nil
		end

		MOAIFmodDesigner.stopSound( "tally" )
	end
end

function death_dialog:addAnalysisStat( leftText, countNum, constantNum, color, png )

	local widget = nil

	widget = self._screen:findWidget( "stat" .. self._analysisIdx )
	self._analysisIdx = self._analysisIdx + 1


	widget.binder.leftTxt:setColor( unpack(color) )
	widget.binder.countTxt:setColor( unpack(color) )
	widget.binder.multiply:setColor( unpack(color) )
	widget.binder.constantTxt:setColor( unpack(color) )
	widget.binder.rightTxt:setColor( unpack(color) )

	widget.binder.leftTxt:setText( leftText )
	widget.binder.countTxt:setText( countNum )
	widget.binder.multiply:setVisible( true )
	widget.binder.constantTxt:setText( constantNum )

	widget.binder.difficulty:setImage( "gui/menu pages/map_screen/"..png)

	local rightNum = countNum * constantNum
	widget.binder.rightTxt:setText( rightNum )

	widget:setVisible( true )

	MOAIFmodDesigner.playSound("SpySociety/HUD/menu/mission_end_count")
	rig_util.wait(0.25*cdefs.SECONDS)

	return rightNum
end

function death_dialog:setCurrentProgress( currentXP, newXP )

	local currentLevel = metadefs.GetLevelForXP( currentXP )
	local prevXP, deltaXP = metadefs.GetXPForLevel( currentLevel )
	local nextXP = prevXP + deltaXP

	while currentXP < newXP do
		currentXP = math.min( newXP, nextXP )

		self._screen.binder.pnl.binder.xpTxt:setText( util.sformat( STRINGS.UI.EXP_GAINED, currentXP, nextXP ) )
		self._screen.binder.pnl.binder.progressBar:setProgress( (currentXP - prevXP) / deltaXP )

		if currentXP >= nextXP then
			-- Gained a level.  Unlocked the thing!
			MOAIFmodDesigner.stopSound( "tally" )

			local rewardData = metadefs.GetRewardForLevel( currentLevel )

			if rewardData.unlockType == metadefs.PROGRAM_UNLOCK then
				modalDialog.showUnlockProgram(rewardData)
			else
				modalDialog.showUnlockAgent(rewardData)
			end

			MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/tally_LP", "tally" )

			currentLevel = currentLevel + 1
			prevXP, deltaXP = metadefs.GetXPForLevel( currentLevel )
			nextXP = prevXP + deltaXP				
		end
	end

	if currentXP >= metadefs.GetXPCap() then
		self._screen.binder.pnl.binder.xpTxt:setText( util.sformat( STRINGS.UI.EXP_CAP, currentXP ) )
		self._screen.binder.pnl.binder.progressBar:setProgress( 1 )
	else
		self._screen.binder.pnl.binder.xpTxt:setText( util.sformat( STRINGS.UI.EXP_GAINED, currentXP, nextXP ) )
		self._screen.binder.pnl.binder.progressBar:setProgress( (currentXP - prevXP) / deltaXP )
	end
end

function death_dialog:updateProgress( agency, oldXp, newXp ) 
	assert( newXp >= oldXp, tostring(newXp)..">="..tostring(oldXp) )

	self:addAnalysisStat( STRINGS.UI.MISSIONS_COMPLETED, (agency.missions_completed_1 or 0), metadefs.GetXPPerMission(1, self._campaign.campaignDifficulty), POSITIVE_COLOR, "shield1.png" )
	self:addAnalysisStat( STRINGS.UI.MISSIONS_COMPLETED, (agency.missions_completed_2 or 0), metadefs.GetXPPerMission(2, self._campaign.campaignDifficulty), POSITIVE_COLOR, "shield2.png" )
	self:addAnalysisStat( STRINGS.UI.MISSIONS_COMPLETED, (agency.missions_completed_3 or 0), metadefs.GetXPPerMission(3, self._campaign.campaignDifficulty), POSITIVE_COLOR, "shield3.png" )
	
	local currentXp = oldXp
	local totalXpGain = 0

	--debug xp
	--newXp = 20000

	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/tally_LP", "tally" )
	while currentXp < newXp do
		local currentLevel = metadefs.GetLevelForXP( currentXp )
		local prevXP, deltaXP = metadefs.GetXPForLevel( currentLevel )
		local xpDelta = deltaXP / (2 * cdefs.SECONDS)
		local xpGain = math.min( math.ceil(xpDelta), newXp - currentXp )

		self._screen:findWidget("totalRightTxt"):setText( totalXpGain + xpGain )

		self:setCurrentProgress( currentXp, currentXp + xpGain )
		currentXp = currentXp + xpGain
		totalXpGain = totalXpGain + xpGain
		
		coroutine.yield()
	end

	self._screen:findWidget("totalRightTxt"):setText( totalXpGain )

	MOAIFmodDesigner.stopSound( "tally" )

	if self._campaign.difficultyOptions.savescumming and not self._campaignWin then
		self._screen:findWidget("retryLevel"):setVisible(true)
		self._screen:findWidget("retryLevel").onClick = function() self:OnClickRetry( 1 ) end

		self._screen:findWidget("restartDay"):setVisible(true)
		self._screen:findWidget("restartDay").onClick = function() self:OnClickRetry( 2 ) end
	else
		local x, y = self._screen:findWidget("retryLevel"):getPosition()
		self._screen:findWidget("restartCampaign"):setPosition( x, y )
	end

	self._screen:findWidget("restartCampaign"):setVisible(true)
	self._screen:findWidget("restartCampaign").onClick = function() self:OnClickRetry( 3 ) end

	self._screen:findWidget("tipTxt"):setVisible( true )

	if not self._campaignWin then
		local idx = math.random(1, #STRINGS.DEATH_TIPS)
		
		if self._campaign.campaignDifficulty == 1 and not self._campaign.hasShownInitialDeathTip then 
			idx = 1
		end

		local deathtip = STRINGS.DEATH_TIPS[ idx ]
		self._screen:findWidget("tipTxt"):spoolText(deathtip)		
	else
		self._screen:findWidget("tipTxt"):spoolText(WIN_STRINGS[ self._difficulty ])		
		self._screen:findWidget("restartCampaign"):setText( STRINGS.UI.NEW_GAME )

		--[[
		if self.showRateUsButton and KLEISteamWorkshop and KLEISteamWorkshop:isOverlayEnabled() then
			self._screen:findWidget("rateUs"):setVisible(true)
			self._screen:findWidget("rateUs").onClick = function() 
				KLEISteamWorkshop:showOverlayWithURL( "http://store.steampowered.com/app/243970/#review_container" ) 
			end
		end
		]]
	end

	self._screen:findWidget("netWorthOrTime"):setVisible( true )

	if serverdefs.isTimeAttackMode( self._campaign ) then
	    local totalTime = self._campaign.chessTimeTotal or 0
		local hr = math.floor( totalTime / (60*60*60) )
		local min = math.floor( totalTime / (60*60) ) - hr*60
		local sec = math.floor( totalTime / 60 ) % 60
		self._screen:findWidget("netWorthOrTime"):setText( string.format( STRINGS.UI.MAP_SCREEN_TOTAL_PLAY_TIME, hr, min, sec ) )
	else
		self._screen:findWidget("netWorthOrTime"):setText( string.format( STRINGS.UI.NET_WORTH, serverdefs.CalculateNetWorth(self._campaign) ) )
	end

end

function death_dialog:populate( )
	local user = savefiles.getCurrentGame()
	local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]

	self._campaign = campaign

	self._difficulty = user.data.saveSlots[ user.data.currentSaveSlot ].campaignDifficulty
	
	local oldXp = math.min( metadefs.GetXPCap(), user.data.xp or 0)
	self:setCurrentProgress( oldXp, oldXp )

	self._screen.binder.pnl.binder.statFinal:setVisible( false )

	self._screen:findWidget("retryLevel"):setVisible(false)
	self._screen:findWidget("restartDay"):setVisible(false)
	self._screen:findWidget("restartCampaign"):setVisible(false)
	self._screen:findWidget("rateUs"):setVisible(false)
	self._screen:findWidget("tipTxt"):setVisible( false )
	self._screen:findWidget("netWorthOrTime"):setVisible( false )

	-- Officially update and clear the campaign data from the savegame.  Also assigns XPs/rewards.

	self._screen.binder.pnl.binder.statFinal:setVisible(true)
	self._screen:findWidget("totalRightTxt"):setText( 0 )

	if self._campaignWin == true then

		local diffStr = util.toupper( serverdefs.GAME_MODE_STRINGS[ self._difficulty ] )
		self._screen:findWidget("titleTxt"):setText( string.format( STRINGS.UI.CAMPAIGN_COMPLETE, diffStr ) )

		if not user.data.storyExperiencedWins and self._difficulty > simdefs.NORMAL_DIFFICULTY then
			--only show this the first time you beat the game in experienced or higher
			self.showRateUsButton = true
			modalDialog.showUnlockAgent( metadefs.CAMPAIGN_COMPLETE_REWARD )
			modalDialog.showUnlockProgram( metadefs.CAMPAIGN_COMPLETE_REWARD_2 )
		end
		savefiles.addCompletedGame( "VICTORY" )
		
	else
		savefiles.addCompletedGame( "FAILURE" )
	end

	self._updateThread = MOAICoroutine.new()
	self._updateThread:run( self.updateProgress, self, campaign.agency, oldXp, user.data.xp )
end

return death_dialog
