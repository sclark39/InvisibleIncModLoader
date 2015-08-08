----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local serverdefs = include( "modules/serverdefs" )
local mathutil = include( "modules/mathutil" )
local simfactory = include( "sim/simfactory" )

--------------------------------------------------------------------------
-- Base class alarm handler

local alarm_handler = class()

function alarm_handler:init( sim, stage )
    self._stage = stage
end

function alarm_handler:onTrigger( sim, evType, evData )
    if self._stage == nil or evData == self._stage then
        self:executeAlarm( sim, evData )
    end
end

local alarm_level_vo = 
{
    "SpySociety/VoiceOver/Incognita/Pickups/Alarm_level_1",
    "SpySociety/VoiceOver/Incognita/Pickups/Alarm_level_2",
    "SpySociety/VoiceOver/Incognita/Pickups/Alarm_level_3",
    "SpySociety/VoiceOver/Incognita/Pickups/Alarm_level_4",
    "SpySociety/VoiceOver/Incognita/Pickups/Alarm_level_5",
    "SpySociety/VoiceOver/Incognita/Pickups/Alarm_level_6",
}

local alarm_level_event = 
{
    CAMERAS = "SpySociety/VoiceOver/Incognita/Pickups/Alarm_Camera_1",
    FIREWALLS = "SpySociety/VoiceOver/Incognita/Pickups/Alarm_Firewalls_1",
    ENFORCERS = "SpySociety/VoiceOver/Incognita/Pickups/Alarm_Enforcers_1",
    REINFORCEMENTS = "SpySociety/VoiceOver/Incognita/Pickups/Alarm_Reinforcements_1",
    PATROLS = "SpySociety/VoiceOver/Incognita/Pickups/Alarm_Patrols_1",
}

local alarm_level_crazies = 
{
    CAMERAS = {"SpySociety/VoiceOver/Incognita/Pickups/Alarm_Camera_2","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Camera_3","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Camera_4","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Camera_5"},
    FIREWALLS = {"SpySociety/VoiceOver/Incognita/Pickups/Alarm_Firewalls_2","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Firewalls_3","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Firewalls_4","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Firewalls_5"},
    ENFORCERS = {"SpySociety/VoiceOver/Incognita/Pickups/Alarm_Enforcers_2","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Enforcers_3","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Enforcers_4","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Enforcers_5"},
    REINFORCEMENTS = {"SpySociety/VoiceOver/Incognita/Pickups/Alarm_Reinforcements_2","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Reinforcements_3","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Reinforcements_4","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Reinforcements_5"},
    PATROLS = {"SpySociety/VoiceOver/Incognita/Pickups/Alarm_Patrols_2","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Patrols_3","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Patrols_4","SpySociety/VoiceOver/Incognita/Pickups/Alarm_Patrols_5"},
}

local alarm_level_tips = 
{
    booting = STRINGS.UI.ALARM_NEXT_BOOTING,
    cameras = STRINGS.UI.ALARM_NEXT_CAMERAS,
    firewalls = STRINGS.UI.ALARM_NEXT_FIREWALLS,
    guards = STRINGS.UI.ALARM_NEXT_PATROL,
    enforcers = STRINGS.UI.ALARM_NEXT_ENFORCERS,
}


local function buildAlarmSpeech(alarm_level, event)

    local ret = {}
    if alarm_level_vo[alarm_level] then
        table.insert(ret, alarm_level_vo[alarm_level])
        
        if event and alarm_level_event[event] then
            table.insert(ret, alarm_level_event[event])

            local user = savefiles.getCurrentGame()
            local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
            local endless_mode = campaign and campaign.difficultyOptions.maxHours == math.huge
            local daylevel = 1
            if campaign and not endless_mode then
                daylevel = math.min(campaign.currentDay+1, 4)
            end
            table.insert(ret, alarm_level_crazies[event][daylevel])
        end
    end

    return ret
end

--------------------------------------------------------------------------
-- Alarm functions


local increaseFirewalls = class( alarm_handler )

function increaseFirewalls:executeAlarm( sim, stage )

    sim:dispatchEvent( simdefs.EV_SHOW_ALARM,
        { txt = string.format( STRINGS.UI.ALARM_LEVEL_NUM, stage ),
          txt2 = string.format( STRINGS.UI.ALARM_FIREWALLS, simdefs.TRACKER_FIREWALLS[stage] ),
          stage = stage,
          speech =  buildAlarmSpeech(stage, "FIREWALLS"),
        } )	
    sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 30 )

    sim:dispatchEvent( simdefs.EV_SCRIPT_ENTER_MAINFRAME )
	for _, unit in pairs( sim:getAllUnits() ) do			
        unit:increaseIce(sim,1)
	end
end

local activateCameras = class( alarm_handler )

function activateCameras:init( sim, stage )
    alarm_handler.init( self, sim, stage )
    
	--Assign some cameras to be off initially.
    local numCameras = simdefs.TRACKER_CAMERAS[stage]

	sim:forEachUnit(
	    function( cameraUnit ) 
		    if cameraUnit:getTraits().mainframe_camera and numCameras > 0 then 
                numCameras = numCameras - 1
			    cameraUnit:deactivate( sim )
                cameraUnit:getTraits().mainframe_status = "off" -- Because we don't want them hackable.
		    end 
	    end ) 
end

function activateCameras:executeAlarm( sim, stage )
	sim:dispatchEvent( simdefs.EV_SHOW_ALARM,
        { txt = string.format( STRINGS.UI.ALARM_LEVEL_NUM, stage ),
          txt2 = string.format( STRINGS.UI.ALARM_CAMERAS, simdefs.TRACKER_CAMERAS[stage] ),
          stage = stage,
          speech = buildAlarmSpeech(stage, "CAMERAS"),
        } )	

  for _, cameraUnit in pairs( sim:getAllUnits() ) do
    if cameraUnit:getTraits().mainframe_camera and cameraUnit:getTraits().mainframe_status =="off" and
        not cameraUnit:getTraits().mainframe_booting and not cameraUnit:getTraits().dead then
          cameraUnit:getTraits().mainframe_status_old = "active"
          cameraUnit:getTraits().mainframe_booting = 1
          sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = cameraUnit } )
    end
  end
end

local spawnGuards = class( alarm_handler )

function spawnGuards:executeAlarm( sim, stage )
  local params = sim:getParams()
  if sim:getTags().endless_countermeasures == nil and params.difficulty >= 5 and params.world ~= "omni" then 
    local daemon = "alertPanic"
    sim:getNPC():addMainframeAbility( sim, daemon, nil, 0 )
    sim:getTags().endless_countermeasures = true 
  end 

	sim:dispatchEvent( simdefs.EV_SHOW_ALARM,
        { txt = string.format( STRINGS.UI.ALARM_LEVEL_NUM, stage ),
          txt2 = util.sformat( STRINGS.UI.ALARM_PATROLS, simdefs.TRACKER_GUARDS[stage] ),
          stage = stage,
          speech = buildAlarmSpeech(stage, "PATROLS"),
        } )	

    local wt = util.weighted_list( sim._patrolGuard )
    local templateName = wt:getChoice( sim:nextRand( 1, wt:getTotalWeight() ))
	sim:getNPC():doTrackerSpawn( sim, simdefs.TRACKER_GUARDS[stage], templateName, true )
end

local spawnEnforcers = class( alarm_handler )

function spawnEnforcers:executeAlarm( sim, stage )
    local npcPlayer = sim:getNPC()
    local spawnCount = 1

    if stage >= 6 then
        spawnCount = 2
    end
    sim:addEnforcerWavesSpawned( spawnCount ) -- KILL?
  
  	sim:dispatchEvent( simdefs.EV_SHOW_ALARM,
          { txt = string.format( STRINGS.UI.ALARM_LEVEL_NUM, stage ),
            txt2 = util.sformat( STRINGS.UI.ALARM_ENFORCERS, spawnCount, math.min(sim:getEnforcerWavesSpawned(),2) ),
            stage = stage,
            speech = buildAlarmSpeech(stage, "ENFORCERS"),
          } )	

    if sim._params.difficulty < 3 then
      for i=1,spawnCount do 
        npcPlayer:doTrackerSpawn(sim, 1, simdefs.TRACKER_SPAWN_UNIT_ENFORCER )
      end  
    else
      for i=1,spawnCount do 
        npcPlayer:doTrackerSpawn(sim, 1, simdefs.TRACKER_SPAWN_UNIT_ENFORCER_2 )
      end  
    end


	
	if sim:getEnforcerWavesSpawned() < 3 then
		for _, unit in ipairs(npcPlayer:getUnits() ) do
			if unit:getBrain() and not unit:getTraits().enforcer then
				if not unit:isAlerted() then
					unit:setAlerted(true)
					npcPlayer:joinEnforcerHuntSituation(unit)
				else
					npcPlayer:joinEnforcerHuntSituation(unit, unit:getBrain():getInterest() )
  				end
			end
		end
	end
    npcPlayer:huntAgents( math.min(sim:getEnforcerWavesSpawned(),2) )
end

local booting = class( alarm_handler )

function booting:executeAlarm( sim, stage )
	sim:dispatchEvent( simdefs.EV_SHOW_ALARM,
        { txt = string.format( STRINGS.UI.ALARM_LEVEL_NUM, stage ),
          txt2 = string.format( STRINGS.UI.ALARM_BOOTING, 5 ),
          stage = stage,
          speech = buildAlarmSpeech(stage),
        } )	
end

return
{
    alarm_level_tips = alarm_level_tips,
    alarm_handler = alarm_handler,
    alarm_level_crazies = alarm_level_crazies,
    alarm_level_event = alarm_level_event,
    alarm_level_vo = alarm_level_vo,
    buildAlarmSpeech = buildAlarmSpeech,

    firewalls = increaseFirewalls,
    cameras = activateCameras,
    guards = spawnGuards,
    enforcers = spawnEnforcers,
    booting = booting,
}
