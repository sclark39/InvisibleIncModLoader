----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------
gSupportNewXANIM = false
----------------------------------------------------------------
-- This table is used to collate config settings in a single table rather than
-- a bunch of polluting globals.  This aids searching, and allows for
-- defaulting values, as well as servicing as a form of code documentation.
----------------------------------------------------------------
function updateConfig()
	config =
	{
		WATERMARK = "",
		LOG_FLAGS = {},
        SRC_MEDIA = "game", -- scripts.zip
		SOUND_MEDIA = "",
		SOUND_DBG_FILTER = "HUD/",
        NOSAVES = false,
        CLOUDSAVES = true,
		GUI_MEDIA = "data/gui",
        SHOW_CONSOLE = false,
		NOSOUND = false,
        NOSPLASH = false,
		SOUND_OCCLUSION = true,
		LAUNCHLVL = "",
        SIM_DATA = "",
		LOCALSEED = function() return math.floor(math.random()*2^32) end,
		SAVE_MAP_PNGS = false,
		DEFAULTLVL = "",
		WARPSPEED = 1,
		FORUM_URL = "http://forums.kleientertainment.com/index.php?/forum/41-incognita-beta-general-discussion/",
		SIGNUP_URL = "https://clientservice.kleientertainment.com/maillist",
		METRIC_URL = "https://metric.kleientertainment.com/write",
		REPORT_URL = "https://klei.slack.com/services/hooks/incoming-webhook?token=Bp6RZllRKiKSAOwp2DSDTgX8",
		PATCHNOTES_URL = "http://invisibleincgame.com/updates",
        CRASH_CHANNEL = "#invinc-crashes-dev",
		DBG_FILE = "",
        CAMPAIGN_HOURS = 72,
		DEV = false,
		RECORD_MODE = false,
		MANUAL_CAM = false,
        DBG_CAM = false,
		NO_AI_TRACKS = false,
		TUNING = {},
		SHOW_MOVIE = true,
		NEXT_UPDATE_TIME = { year = 2015, month = 1, day = 20 },
		LAST_UPDATE_TIME = { year = 2015, month = 1, day = 20 },
	}

    -- DEV is determined by MOAIEnvironment.DEV firstly; then overridden by global DEV if it exists.
	local DEV = (rawget( _G, "DEV" ) ~= nil or MOAIEnvironment.DEV) and rawget( _G, "DEV" ) ~= false
	if DEV then
		-- Default dev-environment settings.
		config.WATERMARK = "DEV"
		config.SIGNUP_URL = "https://analytics-staging.office.kleientertainment.com/maillist"
		config.METRIC_URL = "https://analytics-staging.office.kleientertainment.com/write"
		config.DBG_FILE = "debug.lua"
        config.CLOUDSAVES = false
		config.DEV = true
        config.NOSPLASH = true
        config.CRASH_CHANNEL = "#invinc-crashes-dev"
	end

	for k,v in pairs( config ) do
		local vv = rawget( _G, k )
		if vv ~= nil then
			config[k] = vv
			rawset( _G, k, nil )
		end
	end

	if #(config.SOUND_DBG_FILTER or "") > 0 then
		MOAIFmodDesigner.setDebugFilter( config.SOUND_DBG_FILTER )
	end
end

updateConfig()

----------------------------------------------------------------

MOAIFileSystem.mountVirtualDirectory( "game", "scripts_ml.zip" )
dofile( string.format( "%s/client/include.lua", config.SRC_MEDIA ))

----------------------------------------------------------------

local strictify = require( "client/strict" )
strictify( _G )

local logger = include("logger")

---------------------------------------------------------------------
-- Generate unique GUID for this instance of the application.

APP_GUID = MOAIEnvironment.generateGUID()
EDITOR = false
DBG_STATE = {} -- Persistent debug state.

log = logger.openLog()

KLEIResourceMgr.MountPackage( "sound.kwad", "data" )
KLEIResourceMgr.MountPackage( "gui.kwad", "data" )
KLEIResourceMgr.MountPackage( "anims.kwad", "data" )
KLEIResourceMgr.MountPackage( "characters.kwad", "data/anims" )
KLEIResourceMgr.MountPackage( "images.kwad", "data" )
KLEIResourceMgr.MountPackage( "errata.kwad", "data" )
KLEIResourceMgr.MountPackage( "movies.kwad", "data" )
if gSupportNewXANIM then
    KLEIResourceMgr.MountPackage( "xanims.kwad", "data" )
end

local bugreport = include( "modules/bugreport" )
MOAISim.setTraceback( bugreport.reportTraceback )

---------------------------------------------------------------------
-- Localization and string translation

STRINGS = include( "strings" )

------------------------------------------------------------------------
-- MOD init. This should be right after the string table is initialized,
-- to ensure language mods localize the string table before any systems
-- can reference it.

include("savefile-manager")
savefiles.initSettings()

mod_manager = include( "mod-manager" )()

---------------------------------------------------------------------
-- Sound init

if #(config.SOUND_MEDIA or "") > 0 then
	MOAIFmodDesigner.setMediaPath( config.SOUND_MEDIA )
end

if not config.NOSOUND then
	SOUND_ENABLED = MOAIFmodDesigner.loadFEV("SpySociety.fev")
else
    SOUND_ENABLED = false
end

MOAISim.showConsole( config.DEV or config.SHOW_CONSOLE )

local fmod_mixer = include("fmod_mixer")
FMODMixer = fmod_mixer()
local fmod_mixes = include("fmod_mixes")
fmod_mixes:createMixes()

---------------------------------------------------------------------
-- Global event handling

include("cloud-manager")
include("state-manager")
include("input-manager")

statemgr.begin ()

local globalEventListeners = {}

function addGlobalEventListener( func )
	local idx = #globalEventListeners + 1
	globalEventListeners[idx] = func
	return idx
end
function delGlobalEventListener( idx )
	globalEventListeners[idx] = nil
end

local function handleGlobalEvent( name, val )
	for _,func in pairs(globalEventListeners) do
		func( name, val )
	end
end

MOAIEnvironment.setListener( MOAIEnvironment.EVENT_VALUE_CHANGED, handleGlobalEvent )

addGlobalEventListener(
	function(name, val)
		if name == "resolutionChanged" then
			VIEWPORT_WIDTH, VIEWPORT_HEIGHT = val[1], val[2]
            if KLEIRenderScene then
			    KLEIRenderScene:resizeRenderTargets()
            end
            local mui = include("mui/mui")
			mui.onResize( VIEWPORT_WIDTH, VIEWPORT_HEIGHT )

		elseif name == "gfxmodeChanged" then
			VIEWPORT_IS_FULLSCREEN = val
		end
	end
)

---------------------------------------------------------------------
-- Global render target etc

function CreateRenderTarget( width, height, samplecount )
	local rt = KLEIRenderTarget.new()
	rt:init ( width or VIEWPORT_WIDTH, height or VIEWPORT_HEIGHT, MOAIFrameBuffer.RTF_R8G8B8A8, samplecount )
	return rt
end

function CreateShadowMap( )
    local settings = savefiles.getSettings( "settings" )
    local pow = math.min( 5, settings.data.shadowQuality or 3 )
    local dim = 128 * math.pow(2, pow)
	local rt = KLEIShadowMap.new()
	rt:init ( dim, dim, MOAIFrameBuffer.RTF_R8G8B8A8_D24_S8 )
	return rt
end

---------------------------------------------------------------------

-- Resource paths - search through these for specified resources
local filesystem = include("modules/filesystem")
local resources = include("resources")
resources.addToPath(filesystem.pathJoin("data", "images"))
resources.initGlobalResources()

math.randomseed( os.time() )

----------------------------------------------------------------
-- Create the main window

local util = include( "client_util" )
VIEWPORT_WIDTH, VIEWPORT_HEIGHT, VIEWPORT_IS_FULLSCREEN = 0, 0, false
KLEIRenderScene = false

local function openWindow()
    local settings = savefiles.getSettings( "settings" )
    log:write( "settings.data = \n%s", util.stringize( settings.data ))

    MOAISim.openWindow ( STRINGS.APPNAME, settings.data.gfx )
    MOAIGfxDevice.setClearColor ( 0, 0, 0, 1 )

    local KLEIRenderSceneClass = include( "render_scene" )
    KLEIRenderScene = KLEIRenderSceneClass()
    KLEIRenderScene:initRT( 0 )
    local filter = math.max( 0, math.min( 4, settings.data.colorFilter or 0 ))
	KLEIRenderScene:setDaltonizationType( filter )

    settings.data.gfx = MOAISim.getGfxCurrentDisplayMode()
end

openWindow()

----------------------------------------------------------------
-- Create the GUI subsystem

local mui = include("mui/mui")
mui.initMui( VIEWPORT_WIDTH, VIEWPORT_HEIGHT,
	function( filename )
		if filename:find( ".lua" ) then
			if filename == "options_dialog_screen.lua" then
				return filesystem.pathJoin( "game/gui", filename)
			end
			return filesystem.pathJoin( config.GUI_MEDIA, filename)
		elseif filename:find( ".png" ) then
			return filesystem.pathJoin("data/gui/images", filename)
		elseif filename:find(".ttf") or filename:find(".fnt") then
			return filesystem.pathLookup("data_locale/fonts", filename)
		end
		return filename
	end )

inputmgr.init( )

----------------------------------------------------------------
-- Start the game!

local stateSplash = include("states/state-splash")
statemgr.activate( stateSplash() )




