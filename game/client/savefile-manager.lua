----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

module ( "savefiles", package.seeall )

local array = include( "modules/array" )

----------------------------------------------------------------
----------------------------------------------------------------
-- variables
----------------------------------------------------------------
local files = { [KLEIPersistentStorage.PST_SaveGame] = {}, [KLEIPersistentStorage.PST_Settings] = {} }
local saveFiles = {}
local currentSaveFile = nil
local settingsFile = nil

----------------------------------------------------------------
-- local functions
----------------------------------------------------------------
local function makeFile ( type, filename )

	local savefile = {}
	
	savefile.filename = filename
	savefile.fileexist = false
	savefile.data = nil
	savefile.type = type
	
	----------------------------------------------------------------
	function savefile:load()
		local save = KLEIPersistentStorage.loadFile( self.type, self.filename, config.CLOUDSAVES == true )
		if save then
			local fn, err = loadstring(save)
			if fn then
                local res, data = pcall( fn )
                if res then
				    self.data = data
				    self.fileexist = true
                    err = nil
                else
                    err = data
                end
            end

			if err then
                -- Copy the bad save file.
                local filePath = KLEIPersistentStorage.getFilePath( self.type, self.filename )
                MOAIFileSystem.copy( filePath, string.format( "%s.%s.bak", filePath, tostring(os.time())) )
                local bugreport = include( "modules/bugreport" )
                self.err = string.format( "savefile.load( %s ) failed with err:\n%s", self.filename, err )
                log:write( self.err )
                bugreport.reportTraceback( self.err )
			end
		end

		if not self.data then
			self.data = {}
			self.fileexist = false
		end
		
		--self.data.lastSaveSlot = self.data.currentSaveSlot
        self.data.currentSaveSlot = nil
		
        setmetatable( self,
			{
				__newindex = function( t, k, v )
					assert(false, "Use the data sub-table to store actual save data for key '"..tostring(k).."'") 
				end
			} )

		return self.fileexist
	end
	
	----------------------------------------------------------------
	function savefile:save()
        if not config.NOSAVES then
            
            --update the current campaign's save time
			if self.data.currentSaveSlot then
            	local campaign = self.data.saveSlots[ self.data.currentSaveSlot ]
                if campaign then
                    campaign.save_time = os.time()
                end
            end

		    local serializer = MOAISerializer.new ()

		    self.fileexist = true
		    serializer:serialize ( self.data )
		    local gamestateStr = serializer:exportToString ()

            if config.CLOUDSAVES then
                -- Save to cloud.
    		    KLEIPersistentStorage.saveFile( self.type, self.filename, gamestateStr, true )
            end
            -- Save to disk, all the time.
            KLEIPersistentStorage.saveFile( self.type, self.filename, gamestateStr, false )
        end
	end

	return savefile
end

----------------------------------------------------------------
-- exposed functions
----------------------------------------------------------------

function getFile ( type, filename )
	if not files[type][filename] then
		files[type][filename] = makeFile( type, filename .. ".lua" )
		files[type][filename]:load()
	end
	return files[type][filename]
end

function getGame ( filename )
	return getFile( KLEIPersistentStorage.PST_SaveGame, filename )
end

function getCurrentGame()
	return currentSaveFile
end

function makeCurrentGame( filename )

	local savefile = getGame( filename )
	if savefile.fileexist then
		currentSaveFile = savefile
	end

	return currentSaveFile
end

function getSettings( filename )
	return getFile( KLEIPersistentStorage.PST_Settings, filename )
end

function winAchievement( name )
    log:write( "ACHIEVEMENT: %s", name )
    if KLEIAchievements then
        KLEIAchievements:achieve( name )
    end
end

function checkAchievements( user, campaign, result )
    local cdefs = include( "client_defs" )
    local simdefs = include( "sim/simdefs" )
	local metadefs = include( "sim/metadefs" )
    local serverdefs = include( "modules/serverdefs" )

    if user.data.xp >= metadefs.GetXPCap() then
        winAchievement( cdefs.ACHIEVEMENTS.FULLY_EQUIPPED )
    end

	if result == "VICTORY" then
        if campaign.campaignDifficulty == simdefs.VERY_HARD_DIFFICULTY then
            winAchievement( cdefs.ACHIEVEMENTS.ACCEPTABLE_HOST )
        end
        if campaign.campaignDifficulty >= simdefs.EXPERIENCED_DIFFICULTY then
            winAchievement( cdefs.ACHIEVEMENTS.ANT_SOCIETY )
        end
        if campaign.campaignDifficulty == simdefs.TIME_ATTACK_DIFFICULTY then
            winAchievement( cdefs.ACHIEVEMENTS.TIME_ATTACK )
        end
        if (campaign.campaignDifficulty >= simdefs.HARD_DIFFICULTY and campaign.campaignDifficulty <= simdefs.VERY_HARD_DIFFICULTY) or campaign.campaignDifficulty == simdefs.TIME_ATTACK_DIFFICULTY  then
            winAchievement( cdefs.ACHIEVEMENTS.INVISIBLE_INC )
            if campaign.difficultyOptions.rewindsLeft == 0 then
                winAchievement( cdefs.ACHIEVEMENTS.NEVER_LOOK_BACK )
            end
        end
        if (campaign.campaignDifficulty >= simdefs.NORMAL_DIFFICULTY and campaign.campaignDifficulty <= simdefs.VERY_HARD_DIFFICULTY) or campaign.campaignDifficulty == simdefs.TIME_ATTACK_DIFFICULTY then
            winAchievement( cdefs.ACHIEVEMENTS.TRAINING_WHEELS )
        end

        if array.find( campaign.agency.abilities, "brimstone" ) ~= nil and
           array.find( campaign.agency.abilities, "faust" ) ~= nil then
           winAchievement( cdefs.ACHIEVEMENTS.DAEMON_CODE )
        end
	end
end

------------------------------------------------------------------------------
-- Save game helpers.

MAX_TOP_GAMES = 6

-- Initializes default savegame data.
function initSaveGame()
    local user = makeCurrentGame( "savegame" )
    if not user or not user.data.retail then
        local old_xp = user and user.data.xp
        user = savefiles.getGame( "savegame" )
        user.data = {}
        user.data.name = "default"
        user.data.top_games = {}
        user.data.num_games = 0
        user.data.saveSlots = {}
        user.data.saveScumDaySlots = {}
        user.data.saveScumLevelSlots = {}
        user.data.xp = 0
        user.data.old_xp = old_xp
        user.data.retail = true
        user:save()
        makeCurrentGame( "savegame" )
    end
end

function initSettings()
    local SETTINGS_VERSION = 3
	local settingsFile = savefiles.getSettings( "settings" )
    if settingsFile.data.version ~= SETTINGS_VERSION then
        log:write( "Settings version changed: reinitializing" )
        settingsFile.data = {}
	    settingsFile.data.enableLightingFX = true
	    settingsFile.data.enableBackgroundFX = true
	    settingsFile.data.enableOptionalDecore = true
        settingsFile.data.enableBloom = true
	    settingsFile.data.volumeMusic = 1
        settingsFile.data.edgePanDist = 1
        settingsFile.data.edgePanSpeed = 1
	    settingsFile.data.volumeSfx = 1
        settingsFile.data.showSubtitles = true
        settingsFile.data.version = SETTINGS_VERSION
	    settingsFile:save()
    end

	if config.RECORD_MODE then
		settingsFile.data.volumeMusic = 0
	end

    return settingsFile
end

local function compareCampaigns( campaign1, campaign2 )
	-- Should be based on some score factor?
	if campaign1.hours == campaign2.hours then
		return campaign1.agency.cash > campaign2.agency.cash
	else
		return (campaign1.hours or 0) > (campaign2.hours or 0)
	end
end

-- Adds the current campaign to the list of completed games, then clears the current campaign.
function addCompletedGame( result )
	local metadefs = include( "sim/metadefs" )
    local simdefs = include( "sim/simdefs" )
	local user = getCurrentGame()
	assert( user and user.data.currentSaveSlot )
	local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]

	-- Add xpgain
	local xpgained = 0
	xpgained = xpgained + (campaign.agency.missions_completed_1 or 0) * metadefs.GetXPPerMission(1, campaign.campaignDifficulty)
	xpgained = xpgained + (campaign.agency.missions_completed_2 or 0) * metadefs.GetXPPerMission(2, campaign.campaignDifficulty)
	xpgained = xpgained + (campaign.agency.missions_completed_3 or 0) * metadefs.GetXPPerMission(3, campaign.campaignDifficulty)

	local oldXp = (user.data.xp or 0)
	user.data.xp = math.min( metadefs.GetXPCap(), oldXp + xpgained )

	-- See if fits within the top scores.
	campaign.complete_time = os.time()
	campaign.result = result
	table.insert( user.data.top_games, campaign )

	if result == "VICTORY" then
		user.data.storyWins = (user.data.storyWins or 0) + 1
		if campaign.campaignDifficulty > simdefs.NORMAL_DIFFICULTY then
			user.data.storyExperiencedWins = (user.data.storyExperiencedWins or 0) + 1 
		end
 	end

    checkAchievements( user, campaign, result )

	table.sort( user.data.top_games, compareCampaigns )
	while #user.data.top_games > MAX_TOP_GAMES do
		table.remove( user.data.top_games )
	end

	user.data.saveSlots[ user.data.currentSaveSlot ] = nil

	user:save()
end
