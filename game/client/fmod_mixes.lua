----------------------------------------------------------------
-- Copyright (c) 2013 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local function createMixes()
	FMODMixer:addMix( "default", 2, 1, -- name, fade-in-time, priority
	{
		["music/game"]		= 0.9,
		["sfx/Ambience"]	= 0.7,
		["sfx/Movement"]	= 0.9,
		["sfx/Objects"]		= 0.9,
		["sfx/Attacks"]		= 0.9,
		["sfx/HitResponse"]	= 0.9,
		["sfx/HUD"]			= 0.9,
		["sfx/Actions"]		= 0.9,
		["sfx/Voice"]		= 0.9,
		["sfx/Mainframe"]	= 0.0,
		["sfx/Station"]		= 0.9,
		["sfx/Actions_2D"]		= 0.9,
		["sfx/VoiceOver"]		= 0.9,
	})

	FMODMixer:addMix( "quiet", .5, 2,
	{
		["music/game"]			= 0.3,
		["sfx/Ambience"]	= 0.0,
		["sfx/Movement"]	= 0.3,
		["sfx/Objects"]		= 0.0,
		["sfx/Attacks"]		= 0.6,
		["sfx/HitResponse"]	= 0.5,
		["sfx/HUD"]			= 0.9,
		["sfx/Actions"]		= 0.3,
		["sfx/Voice"]		= 0.3,
		["sfx/Mainframe"]	= 0.9,
		["sfx/Station"]		= 0.9,
		["sfx/Actions_2D"]		= 0.3,
		["sfx/VoiceOver"]		= 0.9,
	})

	FMODMixer:addMix( "mainframe", .5, 3,
	{
		["music/game"]			= 0.9,
		["sfx/Ambience"]	= 0.0,
		["sfx/Movement"]	= 0.1,
		["sfx/Objects"]		= 0.0,
		["sfx/Attacks"]		= 0.4,
		["sfx/HitResponse"]	= 0.3,
		["sfx/HUD"]			= 0.9,
		["sfx/Actions"]		= 0.1,
		["sfx/Voice"]		= 0.2,
		["sfx/Mainframe"]	= 0.9,
		["sfx/Station"]		= 0.0,
		["sfx/Actions_2D"]		= 0.1,
		["sfx/VoiceOver"]		= 0.9,
	},
    {
        ["sfx/VoiceOver"] = 0.95
    })

	FMODMixer:addMix( "frontend", .5, 2,
	{
		["music/game"]			= 0.8,
		["sfx/Ambience"]	= 0.0,
		["sfx/Movement"]	= 0.0,
		["sfx/Objects"]		= 0.0,
		["sfx/Attacks"]		= 0.0,
		["sfx/HitResponse"]	= 0.0,
		["sfx/HUD"]			= 0.9,
		["sfx/Actions"]		= 0.0,
		["sfx/Voice"]		= 0.9,
		["sfx/Mainframe"]	= 0.0,
		["sfx/Station"]		= 0.9,
		["sfx/Actions_2D"]		= 0.9,
		["sfx/VoiceOver"]		= 0.9,
	})

	FMODMixer:addMix( "nomusic", 0, 2,
	{
		["music/game"]			= 0.0,
		["sfx/Ambience"]	= 0.5,
		["sfx/Movement"]	= 0.0,
		["sfx/Objects"]		= 0.0,
		["sfx/Attacks"]		= 0.0,
		["sfx/HitResponse"]	= 0.0,
		["sfx/HUD"]			= 0.9,
		["sfx/Actions"]		= 0.0,
		["sfx/Voice"]		= 0.0,
		["sfx/Mainframe"]	= 0.0,
		["sfx/Station"]		= 0.0,
		["sfx/Actions_2D"]		= 0.0,
		["sfx/VoiceOver"]		= 0.9,
	})

	FMODMixer:addMix( "missionbrief", 3, 2,
	{
		["music/game"]			= 0.3,
		["sfx/Ambience"]	= 0.2,
		["sfx/Movement"]	= 0.9,
		["sfx/Objects"]		= 0.9,
		["sfx/Attacks"]		= 0.9,
		["sfx/HitResponse"]	= 0.9,
		["sfx/HUD"]			= 0.9,
		["sfx/Actions"]		= 0.9,
		["sfx/Voice"]		= 0.9,
		["sfx/Mainframe"]	= 0.0,
		["sfx/Station"]		= 0.9,
		["sfx/Actions_2D"]		= 0.0,
		["sfx/VoiceOver"]		= 0.9,
	})
	
	FMODMixer:addMix( "music_duck", 1, 2,
	{
		["music/game"]			= 0.5,
		["sfx/Ambience"]	= 0.2,
		["sfx/Movement"]	= 0.8,
		["sfx/Objects"]		= 0.8,
		["sfx/Attacks"]		= 0.8,
		["sfx/HitResponse"]	= 0.8,
		["sfx/HUD"]			= 0.9,
		["sfx/Actions"]		= 0.8,
		["sfx/Voice"]		= 0.7,
		["sfx/Mainframe"]	= 0.0,
		["sfx/Station"]		= 0.9,
		["sfx/Actions_2D"]		= 0.0,
		["sfx/VoiceOver"]		= 0.9,
	})
	FMODMixer:pushMix( "default" )
end

return
{
	createMixes = createMixes
}
