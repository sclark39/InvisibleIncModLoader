----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local array = include( "modules/array" )
local basegame = include( "states/state-game" )
local modalDialog = include( "states/state-modal-dialog" )
local gameobj = include( "modules/game" )
local serializer = include('modules/serialize')
local serverdefs = include( "modules/serverdefs" )
local mui = include("mui/mui")
local mui_defs = include("mui/mui_defs")
local metrics = include( "metrics" )
local rig_util = include( "gameplay/rig_util" )
local simdefs = include( "sim/simdefs" )

----------------------------------------------------------------
--

local POSTGAME_NONE = 0
local POSTGAME_REWIND = 1
local POSTGAME_RESULTS = 2

local campaigngame = class( basegame )

function campaigngame:getCamera()
	return self.cameraHandler
end

function campaigngame:saveCampaign()
    if config.NOSAVES then
        return false
    end

	-- Save the current campaign game progress, if the game isn't over, and this isn't a 'debug' level.
	if self.params.campaignHours ~= nil then
		local user = savefiles.getCurrentGame()

		if not self.simCore:isGameOver() then
			local selectedUnit = self.hud:getSelectedUnit()
			local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
			local playTime = os.time() - self.onLoadTime
			local res, err = pcall(
				function()
					campaign.sim_history = serializer.serialize( self.simHistory )
					campaign.play_t = campaign.play_t + playTime
                    campaign.chessTimer = self.chessTimer
                    campaign.chessTimeTotal = self.chessTimeTotal
					campaign.recent_build_number = util.formatGameInfo()
					campaign.uiMemento =
						{
							cameraState = self:getCamera():getMemento(),
							selectedUnitID = selectedUnit and selectedUnit:getID()
						}
					user:save()
				end )
            if res then
                return true -- Success!
            end
            log:write( "Failed to save slot %s:\n%s", tostring(user.data.currentSaveSlot), err )
		end
	end
    return false
end

function campaigngame:quitToMainMenu()
	local stateLoading = include( "states/state-loading" )

	self:saveCampaign()

	statemgr.deactivate( self )
	stateLoading:loadFrontEnd()
end

function campaigngame:onLoad( ... )
	basegame.onLoad( self, ... )

    self.chessTimer, self.chessTimeTotal = self.params.chessTimer, self.params.chessTimeTotal
end

function campaigngame:doAction( ... )
    basegame.doAction( self, ... )

    if not config.DEV then
    	self:saveCampaign()
    end
end

function campaigngame:onUpdate()
	basegame.onUpdate( self )

    if self.chessTimer then
        self:updateTimeAttack()
    end

    if self.simCore:isGameOver() and not self:isVizBusy() then
        self:showPostGame()
    end
end

function campaigngame:updateTimeAttack()
    if self.debugStep then
        return
    end

    if not self.simCore:isGameOver() and self.simCore:getCurrentPlayer():isPC() then
        self.chessTimer = math.min( self.params.difficultyOptions.timeAttack, self.chessTimer + 1 )
        if self.chessTimer >= self.params.difficultyOptions.timeAttack and not self:isReplaying() then
            self:doEndTurn()
        end
    end
end

function campaigngame:doEndTurn()
    if self.chessTimer then
        self.chessTimeTotal = self.chessTimeTotal + self.chessTimer
        self.chessTimer = 0
    end
    basegame.doEndTurn( self )
end

function campaigngame:showPostGame()
    local user = savefiles.getCurrentGame()
    local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
    local campaignPlayTime = campaign.play_t or 0
    
    self.simCore.playTime = os.time() - self.onLoadTime + campaignPlayTime
    if self.chessTimer then
        campaign.chessTimeTotal = self.chessTimeTotal + self.chessTimer
        campaign.chessTimer = 0
    end

    local sim, params, actionCount = self.simCore, self.params, #self.simHistory
    statemgr.deactivate( self )

    local statePostGame = include( "states/state-postgame" )
    statemgr.activate( statePostGame, sim, params, actionCount )
end

----------------------------------------------------------------


return campaigngame
