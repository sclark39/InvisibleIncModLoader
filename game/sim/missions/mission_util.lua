local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local level = include( "sim/level" )
local unitdefs = include("sim/unitdefs")
local serverdefs = include( "modules/serverdefs" )
local mathutil = include( "modules/mathutil" )
local simfactory = include( "sim/simfactory" )
local rig_util = include( "gameplay/rig_util" )
local SCRIPTS = include('client/story_scripts')
local mainframe = include( "sim/mainframe" )

---------------------------------------------------------------------------------------------
-- Local helpers



local function findUnitByTag( sim, tag )
	for _, unit in pairs( sim:getAllUnits() ) do
		if unit:hasTag( tag ) then
			return unit
		end
	end
	assert( false, "Couldn't find unit:" .. tag )
end


local OK_OPTIONS = { STRINGS.UI.BUTTON_OK }

local function showDialog( sim, headerTxt, bodyTxt )
    return sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "messageDialog", dialogParams = { headerTxt, bodyTxt }})
end

local function showAugmentInstallDialog( sim, item, unit )
    return sim:dispatchChoiceEvent( simdefs.EV_INSTALL_AUGMENT_DIALOG, { item = item, unit = unit })
end

local function showGrafterDialog( sim, itemDef, userUnit, drill )
    return sim:dispatchChoiceEvent( simdefs.EV_GRAFTER_DIALOG, { itemDef = itemDef, userUnit = userUnit, drill = drill })
end

local function showExecDialog( sim, headerTxt, bodyTxt, options, corps, names )
    return sim:dispatchChoiceEvent( simdefs.EV_EXEC_DIALOG, { headerTxt = headerTxt, bodyTxt = bodyTxt, options = options, corps = corps, names = names})
end

local function spawnItem( sim, templateName, cell )
    local simfactory = include( "sim/simfactory" )
	local newUnit = simfactory.createUnit( unitdefs.lookupTemplate( templateName ), sim )
	sim:spawnUnit( newUnit )
    newUnit:warpUnit( newUnit, cell )
end

local function getListOfKeyItems(sim, tag)

	local keyItems = {}
	local acquired = {}

	for unitID, unit in pairs(sim:getAllUnits()) do
		if unit:hasTag(tag) then
			table.insert(keyItems,unit)

			local owner = unit:getUnitOwner()
			local x1,y1 = unit:getLocation()

			if owner then
				if owner:isPC() and owner:hasAbility("escape") then
					local cell = sim:getCell( owner:getLocation() )
                    if cell and cell.exitID == simdefs.DEFAULT_EXITID then
                    	-- carried by unit exiting level.
                        table.insert(acquired,unit)
                    end						
				end
			else
				if not x1 or not y1 then
					-- it had no owner and no location, it was sold
					table.insert(acquired,unit)
				end
			end
		end
	end

	return keyItems,acquired

end

 local function CheckForLeftItem(sim, tag, warnstring, additionalcheck) 
    return function()

		local keyItems, acquired = getListOfKeyItems(sim, tag)

        if #keyItems ~= #acquired then
        	return warnstring
        end

        if additionalcheck and additionalcheck() then
            return warnstring
        end
    end
end

local GUARD_FINISH = 
{
	trigger = "guard_finish"
}


local mission_util =
{
	showDialog = showDialog,
	showGrafterDialog = showGrafterDialog,
	showAugmentInstallDialog = showAugmentInstallDialog,
	showExecDialog = showExecDialog, 

	findUnitByTag = findUnitByTag,
    spawnItem = spawnItem,
    CheckForLeftItem = CheckForLeftItem,

    UI_LOOT_CLOSED =
    {
        uiEvent = level.EV_CLOSE_LOOT_UI,
        fn = function( sim )
            return true
        end
    },

    UI_SHOP_CLOSED =
    {
        uiEvent = level.EV_CLOSE_SHOP_UI,
        fn = function( sim, shopID )
            return sim:getUnit( shopID )
        end
    },

    UI_INITIALIZED =
    {
	    uiEvent = level.EV_UI_INITIALIZED,
    },

    DAEMON_REVERSE =
    {       
        trigger = simdefs.TRG_DAEMON_REVERSE,
        fn = function( sim, evData )
            return true
        end,
    },

    RECAPTURE_DEVICES =
    {       
        trigger = simdefs.TRG_RECAPTURE_DEVICES,
        fn = function( sim, evData )
            return evData.reboots
        end,
    },

    
	PC_LOST =
	{		
		trigger = simdefs.TRG_GAME_OVER,
		fn = function( sim, evData )
			if sim:getWinner() then
				return sim:getPlayers()[sim:getWinner()]:isNPC()
			else
				return true
			end
		end,
	},
    

	PC_WON =
	{		
		trigger = simdefs.TRG_GAME_OVER,
		fn = function( sim, evData )
			if sim:getWinner() then
				return sim:getPlayers()[sim:getWinner()]:isPC()
			else
				return false
			end
		end,
	},

   	ESCAPE_WITH_LOOT = function(tag)
        return 
        {
            trigger = simdefs.TRG_UNIT_ESCAPED,
            fn = function( sim, escapedUnit )
            	
                for _,childUnit in ipairs( escapedUnit:getChildren() ) do
                    if childUnit:hasTag(tag) then
                        return true
                    end
                end

				local keyItems, acquired = getListOfKeyItems(sim, tag)

		        if #acquired > 0 then
		        	return true
		        end
            end,
        }
    end,

	PC_TOOK_UNIT_WITH_TAG = function( tag )
		return
		{
			action = "lootItem",
			fn = function( sim, unitID, itemID )
				local unit, item = sim:getUnit( unitID ), sim:getUnit( itemID )
				if unit and unit:isPC() and item and item:hasTag(tag) then
					return item, unit
				end
			end
		}
	end,	

	PC_MOVED =
	{
		action = "moveAction",
	},

	PC_ANY =
	{
		action = "", -- Any action.
        pre = true,
		fn = function( sim, ... )
            return true
		end,
	},

    PC_PROGRAM_USED = function( abilityName )
        return
        {
            action = "mainframeAction",
            fn = function( sim, updates )
                local program = sim:getPC():getEquippedProgram()
                if program and program:getID() == abilityName then
                    if updates and updates.action == "breakIce" then
                        return program
                    end
                end
            end,
        }
    end,

	PC_STARTED_MOVE =
	{
		action = "moveAction",
		pre = true,
		fn = function( sim, unitID, moveTable )
			local unit = sim:getUnit( unitID )
			return unit and unit:isPC()
		end,
	},

	ALARM_INC = function()
		return
		{
			trigger = simdefs.TRG_ALARM_INCREASE,
			fn = function( sim, evData )
				return true
			end,
		}
	end,


	PC_UNLOCK_DOOR = function( tag )
		return
		{
			trigger = simdefs.TRG_UNLOCK_DOOR,
			fn = function( sim, evData )
				return true
			end,
		}
	end,

	PC_OPEN_DOOR = function( tag )
		return
		{
			trigger = simdefs.TRG_OPEN_DOOR,
			fn = function( sim, evData )
				return true
			end,
		}
	end,


	PC_SAW_UNIT = function( tag )
		return
		{
			trigger = simdefs.TRG_UNIT_APPEARED,
			fn = function( sim, evData )
			
				local seer = sim:getUnit( evData.seerID )
				if not seer or not seer:isPC() then
					return false
				end
				
				if not tag or evData.unit:hasTag(tag) then
					return evData.unit, seer
				else
					return false
				end
			end,
		}
	end,

	PC_SAW_UNIT_WITH_MARKER = function( script, tag, marker )
		return
		{
			trigger = simdefs.TRG_UNIT_APPEARED,
			fn = function( sim, evData )
				local seer = sim:getUnit( evData.seerID )
				if not seer or not seer:isPC() then
					return false
				end

				if not tag or evData.unit:hasTag(tag) and sim:getCurrentPlayer():isPC() then
					local x, y = evData.unit:getLocation()
					script:queue( { type="displayHUDInstruction", text=marker, x=x, y=y } )
					return true 
				else
					return false
				end
			end,
		}
	end,
    PC_SAW_UNIT_WITH_TRAIT = function( trait )
        return
        {
            trigger = simdefs.TRG_UNIT_APPEARED,
            fn = function( sim, evData )
                local seer = sim:getUnit( evData.seerID )
                if not seer or not seer:isPC() then
                    return false
                end
                
                if trait and evData.unit:getTraits()[trait] then
                    return evData.unit, seer
                else
                    return false
                end
            end,
        }
    end,

	SAW_SPECIAL_TAG = function( script, tag, text, subtext )
		return
		{
			trigger = simdefs.TRG_UNIT_APPEARED,
			fn = function( sim, evData )
				local x, y = evData.unit:getLocation()
				if evData.unit:hasTag(tag) and sim:getUnit(evData.seerID) and sim:getUnit(evData.seerID):isPC() then
                    evData.unit:createTab( text, subtext )
					return evData.unit
				else
					return nil
				end
			end
		}
	end,

	PC_IN_RANGE_OF_TARGET = function(script, target, range )
		return
		{
            action = "", -- ANY
			fn = function( sim )
			 	local x0, y0 = target:getLocation()
		        if x0 and y0 and target:isKO() then
					local closestUnit, closestDistance = simquery.findClosestUnit( sim:getPC():getAgents(), x0, y0, function( u ) return not u:isKO() end )
					if closestDistance <= range then 
						script._waitForInterrogationStart = nil
						return true
					end
				end
			end
		}
	end,	

    AGENT_DOWN =
    {
        trigger = simdefs.TRG_UNIT_KO,
        fn = function( sim, triggerData )
            if triggerData and (triggerData.ticks or 0) > 0 and triggerData.unit:isPC() then
                return triggerData.unit
            end
        end
    },

	PC_END_TURN =
	{
		pre = true,
		action = "endTurnAction",
	},

	PC_START_TURN =
	{
		trigger = simdefs.TRG_START_TURN,
		fn = function( sim, evData )
			if evData:isPC() then 
				return true 
			else
				return false 
			end  
		end,
	},

	NPC_START_TURN =
	{
		trigger = simdefs.TRG_START_TURN,
		fn = function( sim, evData )
			if evData:isPC() then 
				return false 
			else
				return true 
			end  
		end,
	},

	PC_HIJACKED = function( consoleID )
		return
		{
			trigger = simdefs.TRG_UNIT_HIJACKED,
			fn = function( sim, evData )
				if evData.sourceUnit:isPC() and (consoleID == nil or evData.unit:getID() == consoleID) then
					return evData
				end
			end
		}
	end,




	PC_CAUGHT_BY_CAMERA =
	{
		trigger = simdefs.TRG_CAUGHT_BY_CAMERA,
		fn = function( sim, evData )
				return true 
	
		end,
	},

    PC_LOOTED_SAFE = function( safeID )
	    return
	    {
		    trigger = simdefs.TRG_SAFE_LOOTED,
		    fn = function( sim, triggerData )
                if triggerData.targetUnit:getID() == safeID then
                    return triggerData 
                end
		    end,
	    }
    end,

    PC_USED = function( unit )
        return
        {
            trigger = unit:getTraits().trigger,
            fn = function( sim, triggerData )
                return triggerData.userUnit
            end,
        }
    end,

    UNIT_DEACTIVATED = function( unit )
        return
        {
            action = "", -- any
            fn = function( sim )
                return not unit:isValid() or (unit:getTraits().mainframe_status ~= "active" and not unit:getTraits().mainframe_booting)
            end
        }
    end,

    PC_USED_ABILITY = function( name )
	    return
	    {
		    action = "abilityAction",
		    pre = true,
		    fn = function( sim, ownerID, userID, abilityIdx, ... )

			    local unit, ownerUnit = sim:getUnit( userID ), sim:getUnit( ownerID )

			    if not unit or not unit:isPC() or not ownerUnit then
				    return nil
				end

			    return ownerUnit:getAbilities()[ abilityIdx ]:getID() == name
		    end,
	    }
    end,
    
    UNIT_WARP = 
    {
	    trigger = simdefs.TRG_UNIT_WARP
    },

    NPC_WARP = 
    {
	    trigger = simdefs.TRG_UNIT_WARP,
	    fn = function( sim, triggerData )
	    	if triggerData.unit and triggerData.unit:isNPC() and triggerData.unit:getTraits().dynamicImpass then
	    		return sim:getCurrentPlayer() == sim:getNPC()
	    	end
	    end,
	},

	NPC_KO = 
	{
		trigger=simdefs.TRG_UNIT_KO,
	    fn = function( sim, triggerData )
	    	if triggerData.unit and triggerData.unit:isNPC() and triggerData.unit:getTraits().dynamicImpass then
	    		return sim:getCurrentPlayer() ~= sim:getNPC()
	    	end
	    end,
	},

	NPC_KILLED = 
	{
		trigger=simdefs.TRG_UNIT_KILLED,
	    fn = function( sim, triggerData )
	    	if triggerData.unit and triggerData.unit:isNPC() and triggerData.unit:getTraits().dynamicImpass then
	    		return sim:getCurrentPlayer() ~= sim:getNPC()
	    	end
	    end,
	},

}

function mission_util.createInterrogationHook( importantGuard, onFailInterrogate )
    local function checkGuardDistance( script, sim )
        assert( importantGuard )
	    local warned, queued, failed = false, false, false
        local lastDistance = 0

	    while not failed do
		    local ev, triggerData = script:waitFor( mission_util.UNIT_WARP )
		    if queued then 
			    script:queue( { type="clearOperatorMessage" } )
			    queued = false 
		    end 

		    local x0, y0 = importantGuard:getLocation()
            if x0 == nil then
                failed = SCRIPTS.INGAME.CENTRAL_FAILED_TARGET_DIED
            else
				if importantGuard:getTraits().interrogationStarted and not importantGuard:getTraits().interrogationFinished then
		          	if not importantGuard:isKO() then
	            		
		                failed = SCRIPTS.INGAME.CENTRAL_FAILED_TARGET_WOKEUP

					else
				        local closestUnit, closestDistance = simquery.findClosestUnit( sim:getPC():getAgents(), x0, y0, function( u ) return not u:isKO() end )
		                if closestDistance > lastDistance then
		            	
				            if closestDistance > 5 then
		                        failed = SCRIPTS.INGAME.CENTRAL_FAILED_CONNECTION_BROKEN     
				            elseif closestDistance > 3 and not warned then
				            	script:queue( { script=SCRIPTS.INGAME.CENTRAL_STAY_CLOSE, type="newOperatorMessage" } )
					            triggerData.unit:interruptMove( sim )
					            warned = true 
					            queued = true 
				            else 
					            warned = false 
				            end
				        end
				        lastDistance = closestDistance
			    	end
            	end
            end
	    end

        -- Failed!
        onFailInterrogate( script, sim )
        script:queue( { script=failed, type="newOperatorMessage" } )
	    script:waitFor( mission_util.PC_ANY )
	    script:queue( { type="clearOperatorMessage" } )
    end

    return checkGuardDistance

end 

mission_util.doAgentBanter = function(script,sim)

	local agents = sim:getCurrentPlayer():getAgents()
	if #agents	> 0 and sim:getParams().world ~= "omni" then

		local cross_script = include('client/cross_scripts')
		local cross_set = util.tcopy(cross_script) -- make an editable list
		local speechQue = {}
		local agentList = {} -- the list of agent IDs on the mission
		for i,agent in ipairs(agents) do
			table.insert(agentList,agent._unitData.agentID)			
		end

		if #agents > 1 and sim:isVersion("0.17.5") then -- do if there are more than 1 agent
			for p=1,2 do  -- filter out the dialogue that wont be used.
				local randAgent = math.floor(sim:nextRand()*#agentList)+1

				for i=#cross_set,1,-1 do

					local set = cross_set[i]					
					local keep = false
					for t,agent in ipairs(set.agents)do						
						if agent == agentList[randAgent] then
							keep = true
						end
					end		
					if not keep  then
						table.remove(cross_set,i)
					end
				end
				table.remove(agentList,randAgent)				
			end
		
			local dialogueSet = nil
			local agency = sim:getParams().agency

			while #cross_set > 0 and dialogueSet == nil do -- find a set not already used
				local rand = math.floor(sim:nextRand()*#cross_set)+1
				dialogueSet = cross_set[rand]

				for i,crossId in ipairs(agency.crossIds or {})do
					if dialogueSet and crossId == dialogueSet.id then
						dialogueSet = nil
						table.remove(cross_set,rand)
					end
				end				
			end
			if dialogueSet and sim:nextRand() < 0.2 then
			
				if not agency.crossIds then
					agency.crossIds = {}
				end
				table.insert(agency.crossIds,dialogueSet.id)

				for i,event in ipairs(dialogueSet.dialogue) do				
					agentDef = {}
					for i,agent in ipairs(agents) do
						if agent._unitData.agentID == event[1] then
							agentDef = agent._unitData
						end
					end
					local enemy = false
					if (i % 2 == 0)then
						enemy = true
					end
			        local speech={ 
			            {
			                text = agentDef.speech.CROSS[event[2]] or "",
			                anim = agentDef.profile_anim,
			                name = util.toupper(agentDef.name),
			                timing = 5,
			                enemy = enemy,
			            } 
			        }				
					table.insert(speechQue,speech)
				end			
			end
		end
		local selection = math.floor(sim:nextRand()*#agents)+1
		local agentDef = agents[selection]:getUnitData()
		local speechSet = agents[selection]:getSpeech()
		local text = speechSet.START[math.floor(sim:nextRand()*#speechSet.START)+1]

		if #speechQue == 0 then
   		
	        local speech={ 
	            {
	                text = text or "",
	                anim = agentDef.profile_anim,
	                name = util.toupper(agentDef.name),
	                timing = 5,
	            } 
	        }

	        table.insert(speechQue,speech)
    	end

		script:queue( 1*cdefs.SECONDS )
    	for i,que in ipairs(speechQue)do

    		if que[1].enemy then
		    	script:queue( { body=que[1].text, header=que[1].name, type="enemyMessage", 
					profileAnim=que[1].anim,
					profileBuild=que[1].anim,
				} )	
				script:queue( 5*cdefs.SECONDS )					
				script:queue( { type="clearEnemyMessage" } )
			else
        		script:queue( { script=que, type="newOperatorMessage" } )        		
        	end        	
        end

	end
end

mission_util.makeAgentConnection = function( script, sim )
    
    script:waitFor( mission_util.UI_INITIALIZED )
    script:queue( { type = "hideInterface" })

    sim:dispatchEvent( simdefs.EV_TELEPORT, { units = sim:getPC():getAgents(), warpOut = false } )		

	local isEndless = sim:getParams().difficultyOptions.maxHours == math.huge

    local settingsFile = savefiles.getSettings( "settings" )
	if sim:getParams().missionCount == 0 and not isEndless then
        --sim:dispatchEvent( simdefs.EV_SHOW_ALARM_FIRST )    
        script:queue( 1*cdefs.SECONDS )
        script:queue( { script=SCRIPTS.INGAME.CENTRAL_FIRST_LEVEL, type="modalConversation" } ) 

	    script:queue( { type = "showInterface" })

	    script:queue( 0.5*cdefs.SECONDS )
	    script:queue( { type = "showMissionObjectives" })

    else
        script:queue( 1.5*cdefs.SECONDS )
        script:queue( { type = "showInterface" })

        script:queue( 0.5*cdefs.SECONDS )
        script:queue( { type = "showMissionObjectives" })

		script:addHook( mission_util.doAgentBanter )		
	end

	if sim:getParams().endlessAlert then
		local daemon = serverdefs.ENDLESS_DAEMONS[ sim:nextRand(1, #serverdefs.ENDLESS_DAEMONS) ]  
		sim:getNPC():addMainframeAbility(sim, daemon, sim:getNPC(), 0 )
	end

	--jcheng: swipe work in progress
    --sim:dispatchEvent( simdefs.EV_TURN_START, {player = sim:getCurrentPlayer() })
end

local function doRecapturePresentation(script, sim, cyberlab, agent, climax, numItems)

    local possibleUnits = {}
    local num = numItems or 3 

    for _, unit in pairs( sim:getPC():getUnits() ) do
        if mainframe.canRevertIce( sim, unit ) then
            table.insert( possibleUnits, unit )     
        end
    end

    local relocked = #possibleUnits > 0    

    if relocked then
        script:waitFrames( .75*cdefs.SECONDS )
        script:queue({type="showIncognitaWarning", txt= STRINGS.UI.WARNING_RECAPTURE, vo="SpySociety/VoiceOver/Incognita/Pickups/Warning_Recapture"})
        if climax then 
       		sim:setClimax(true)
       	end 
        script:waitFrames( .75*cdefs.SECONDS )

        for k = 1 , num do 
            if #possibleUnits > 0 then
                local idx = sim:nextRand(1,#possibleUnits)
                local item = possibleUnits[idx]
                if item  then
                    mainframe.revertIce( sim, item )
                    local x, y = item:getLocation()
                    script:queue( { type="pan", x=x, y=y } )
                    script:waitFrames( 1*cdefs.SECONDS )
                end
                table.remove(possibleUnits, idx)
            end
        end
        if agent then 
	        local x, y = agent:getLocation()
	        sim:dispatchEvent( simdefs.EV_SCRIPT_EXIT_MAINFRAME )
	        script:queue( { type="pan", x=x, y=y } )

	        script:waitFrames( 1*cdefs.SECONDS )
	        script:queue( { script=SCRIPTS.INGAME.AFTERMATH.CYBERNANO[sim:nextRand(1, #SCRIPTS.INGAME.AFTERMATH.CYBERNANO)], type="newOperatorMessage" } ) 
	    end   
    end
end
mission_util.doRecapturePresentation = function(script, sim, cyberlab, agent, climax, numItems)
	doRecapturePresentation(script, sim, cyberlab, agent, climax, numItems)
end

mission_util.recaptureDevices = function( script, sim )
	local _,reboots = script:waitFor( mission_util.RECAPTURE_DEVICES )
	doRecapturePresentation(script, sim, nil, nil, nil, reboots)
	script:addHook(mission_util.recaptureDevices, true)
end

mission_util.checkCaughtByCamera = function( script, sim )
	script:waitFor( mission_util.PC_CAUGHT_BY_CAMERA )	
	script:queue( 1*cdefs.SECONDS )
    script:queue( { script=SCRIPTS.INGAME.CENTRAL_CAUGHT_BY_CAMERA, type="newOperatorMessage" } )       
	script:queue( { type = "blink", target="incognitaBtn", blink={ period=0.2, blinkCountPerPeriod=2, periodInterval=2 }})
	script:queue( 6*cdefs.SECONDS )	
	script:queue( { type = "blink", target="incognitaBtn", blink={ period=0 }})	

end

mission_util.checkAgentDown = function( script, sim )
    local _, agent = script:waitFor( mission_util.AGENT_DOWN )
    if not sim:getWinner() and agent:isDead() then

        local dead_central = false
        local activeAgents = 0

        for _, unit in pairs( sim:getPC():getAgents() ) do
            if unit:isKO() and unit:getTraits().central then
                dead_central = true                
            end

            if unit:getTraits().isAgent and not unit:isKO() and not unit:isDead() then
            	activeAgents = activeAgents + 1
            end
        end

        if not dead_central and activeAgents > 0 then
            script:queue( 1*cdefs.SECONDS )
            script:queue( { script=SCRIPTS.INGAME.AGENT_DOWN[sim:nextRand(1, #SCRIPTS.INGAME.AGENT_DOWN)], type="newOperatorMessage" } )       
        end
        script:addHook(mission_util.checkAgentDown, true)
    end
end

mission_util.checkAlarmTutorial = function( script, sim )
    script:waitFor( mission_util.PC_START_TURN )

    script:waitFrames( 30 )
    script:queue( { type="showAlarmFirst" } ) 
end


mission_util.checkTacticalTut = function( script, sim )
    local settings = savefiles.getSettings("settings" )
    for k = 1, 2 do
        script:waitFor( mission_util.PC_START_TURN )
    end

    script:waitFrames( 30 )
    sim:dispatchEvent( simdefs.EV_SHOW_DIALOG,
     { showOnce = "seenTacticalTut", dialog = "generalDialog", dialogParams = { "modal-tactical-view.lua" }} )
end




mission_util.checkDaemonReverse = function( script, sim )

    local _, agent = script:waitFor( mission_util.DAEMON_REVERSE )
    script:queue( 3*cdefs.SECONDS )
    script:queue( { script=SCRIPTS.INGAME.CENTRAL_DAEMON_REVERSE[sim:nextRand(1, #SCRIPTS.INGAME.CENTRAL_DAEMON_REVERSE)], type="newOperatorMessage" } )       
    script:addHook(mission_util.checkDaemonReverse, true)
end

mission_util.CreateCentralReaction = function(scriptgenfn)
    
    return function(script, sim)
        script:waitFor( mission_util.PC_WON )
        script:removeAllHooks( script )
        script:clearQueue()
        script:queue( { type = "hideInterface" })
        script:queue( { type="clearEnemyMessage" } )
        script:queue( { type="clearOperatorMessage" } )
        script:queue( { script=scriptgenfn(), type="newOperatorMessage" } )
        script:queue( 1*cdefs.SECONDS )
    end
end


mission_util.checkGameOver = function( script, sim )
    script:waitFor( mission_util.PC_LOST )

	script:removeAllHooks( script )
	sim:getTags().delayPostGame = true

	script:clearQueue()
	script:queue( { type="clearEnemyMessage" } )
	--script:queue( { script=SCRIPTS.INGAME.CENTRAL_TEAM_DOWN, type="newOperatorMessage" } ) 

	script:waitFrames( 30 )
    script:queue( { script=SCRIPTS.INGAME.INCOGNITA_TEAM_DOWN[sim:nextRand(1, #SCRIPTS.INGAME.INCOGNITA_TEAM_DOWN)], type="modalConversation" } )  
	sim:getTags().delayPostGame = false
end

mission_util.checkFtmScanner = function( script, sim )
	local _, scanner = script:waitFor( mission_util.PC_SAW_UNIT("ftmScanner") )	
	script:queue( { type="clearOperatorMessage" } )
    scanner:createTab( STRINGS.PROPS.ADVANCED_CORP_EQUIP, STRINGS.PROPS.FTM_SCANNER_TAB )
end

mission_util.closeDoorsOnKO = function(script, sim)
    script:waitFor(mission_util.NPC_KO)
	sim:closeGuardDoors()
    script:addHook(mission_util.closeDoorsOnKO, true)
end

mission_util.closeDoorsOnKill = function(script, sim)
    script:waitFor(mission_util.NPC_KILLED)
	sim:closeGuardDoors()
    script:addHook(mission_util.closeDoorsOnKill, true)
end

mission_util.closeDoorsOnWarp = function(script, sim)
    script:waitFor(mission_util.NPC_WARP)
	sim:closeGuardDoors()
    script:addHook(mission_util.closeDoorsOnWarp, true)
end

mission_util.findCellsAwayFromTag = function( sim, tag, dist )
	local cells = sim:getCells( tag )
	local cell = cells[1]
	local foundCells = {}

	if cell then
		local x0,y0= cell.x,cell.y
		local possibleCells = {}		
		sim:forEachCell( function( c ) 
			if math.abs(x0-c.x) > dist or math.abs(y0-c.y) > dist then
				if not simquery.checkDynamicImpass(sim, c) and simquery.canStaticPath( sim, nil, nil, cell) then
		 			table.insert(foundCells,c)
		 		end
			end
		end )
	end
	return foundCells
end

mission_util.calculatePrefabDistance = function( cxt, x, y, ... )
    local distances = {}

    for i, c in ipairs(cxt.candidates) do
        for j, str in ipairs( {...} ) do
            if c.filename:find( str ) then
                table.insert( distances, mathutil.dist2d( x, y, c.tx, c.ty ))
                break
            end
        end
    end

    -- This weird stuff here prefers distances that are similar in magnitude, over those
    -- that might sum to be longer, but vary widely (generally, you don't want one distance to
    -- be ultra short, for example).
    -- THIS IS VERY MAGIC TUNING.

    local diff = 0
    for i, d in ipairs(distances) do
        diff = diff + (math.max( unpack(distances) ) - d) + (d - math.min( unpack(distances) ))
    end
    local total = mathutil.sum( unpack(distances) )

    return math.max( 0, total - diff )
end


local function scannerDetected( script, sim )
	script:waitFor( mission_util.PC_START_TURN )
    -- Verify it hasn't been immediately hacked.
    local scannerUnit = simquery.findUnit( sim:getAllUnits(), function( u ) return u:getTraits().scanner and u:getPlayerOwner() == nil end )
    if scannerUnit then
    	script:queue( { script=SCRIPTS.INGAME.CENTRAL_SCANNER_DETECTED, type="newOperatorMessage" } )	
	    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_SCANNER, "scanner" )
	    script:waitFor( mission_util.UNIT_DEACTIVATED( scannerUnit ))
	    sim:removeObjective( "scanner" )
	    script:queue( 2*cdefs.SECONDS )
		script:queue( { script=SCRIPTS.INGAME.CENTRAL_SCANNER_DETECTED_2, type="newOperatorMessage" } )		    
    end
end



--------------------------------------------------------------------------------------------
-- Base campaign mission script.  Any stuff that is shared to ALL campaign missions should be
-- included here.

mission_util.campaign_mission = class()

function mission_util.campaign_mission:init( scriptMgr, sim, finalMission )
	self.scriptMgr = scriptMgr

	scriptMgr:addHook( "GAMEOVER", mission_util.checkGameOver, true )
	scriptMgr:addHook("CLOSEDOORS-KO", mission_util.closeDoorsOnKO, true)
	scriptMgr:addHook("CLOSEDOORS-KILL", mission_util.closeDoorsOnKill, true)
	scriptMgr:addHook("CLOSEDOORS-WARP", mission_util.closeDoorsOnWarp, true)

	local player = sim:getPC()
	player:addCPUs(-player:getCpus())
	local extraPWR = 0
	if player:getTraits().extraStartingPWR then
		extraPWR = player:getTraits().extraStartingPWR
	end
	player:addCPUs( sim._params.difficultyOptions.startingPower + extraPWR )

    --init this to ignore all of the setup deltas
    sim._resultTable.pwr_gained = player:getCpus()
    sim._resultTable.pwr_used = 0

    if sim:getParams().campaignDifficulty ==1 and sim:getParams().missionCount == 0 then
		scriptMgr:addHook( "CAUGHTBYCAMERA", mission_util.checkCaughtByCamera, true )
    end

    -- Add special hooks for special campaign spawns.
	for k,unit in pairs(sim:getAllUnits()) do
		if unit:getTraits().scanner then
			scriptMgr:addHook( "SCANNER-DETECT", scannerDetected )
		end
	end

	local win_conditions = include( "sim/win_conditions" )
	sim:addWinCondition( win_conditions.pcHasEscaped )

	if not self.finalMission then
        scriptMgr:addHook("AGENT_DOWN", mission_util.checkAgentDown, true)
	end

	if sim:getParams().missionCount == 0 then
		scriptMgr:addHook("ALARM_TUT", mission_util.checkAlarmTutorial, true)
	end

    local settings = savefiles.getSettings("settings" )
    if not settings.data.seenTacticalTut then
        scriptMgr:addHook("TACTICAL_TUT", mission_util.checkTacticalTut, true)
    end
    
    scriptMgr:addHook("RECAPTURE_DEVICES", mission_util.recaptureDevices, true)
    scriptMgr:addHook("DAEMON_REVERSE", mission_util.checkDaemonReverse, true)
end


function mission_util.DoReportObject( waiter, report, prefn, pstfn )
    return function (script, sim)
        local _, target, agent = script:waitFor( waiter )

        if prefn then
            prefn(script, sim, target, agent)
        end

        local x, y = target:getLocation()
        script:queue( { type="pan", x=x, y=y } )
        
        if type(report) == "table" and not report.txt and not report.vo and report[1] then --this is fuuuuuuuugly, but it works
            report = report[sim:nextRand(1, #report)]
        end
        script:queue( .25*cdefs.SECONDS )
        script:queue( { script=report, type="newOperatorMessage" } )


        if pstfn then
            pstfn(script, sim, target, agent)
        end
        
    end
end



return mission_util

