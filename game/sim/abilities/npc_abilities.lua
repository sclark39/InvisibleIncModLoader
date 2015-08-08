local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local cdefs = include( "client_defs" )
local serverdefs = include( "modules/serverdefs" )
local mainframe_common = include("sim/abilities/mainframe_common")


-------------------------------------------------------------------------------
-- These are NPC abilities.
local PROGRAM_LIST = serverdefs.PROGRAM_LIST

local DEFAULT_ABILITY = mainframe_common.DEFAULT_ABILITY_DAEMON

local createDaemon = mainframe_common.createDaemon

local createReverseDaemon = mainframe_common.createReverseDaemon

local createCountermeasureInterest = mainframe_common.createCountermeasureInterest

local npc_abilities =
{

	--MONST3R REVERSALS 
	order = util.extend( createReverseDaemon( STRINGS.REVERSE_DAEMONS.ORDER ) )
	{
		icon = "gui/icons/daemon_icons/Program0023.png",

		onSpawnAbility = function( self, sim, player )
			self.duration =  sim:nextRand(2, 3) 
			sim:dispatchEvent( simdefs.EV_SHOW_REVERSE_DAEMON, { name = self.name, icon=self.icon, txt = self.activedesc } )	

            self._affectedUnits = {}
            for i, unit in pairs(sim:getPC():getUnits()) do
		        if unit:getMP() then
		        	local x1, y1 = unit:getLocation()
					sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = unit } )		
					sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, { unit = unit , txt=util.sformat(STRINGS.REVERSE_DAEMONS.ORDER.NAME), x=x1,y=y1,color={r=255/255,g=255/255,b=51/255,a=1 }  } )	-- 

			        unit:addMP( 3 )
			        unit:addMPMax( 3 )
                    table.insert( self._affectedUnits, unit )
		        end
	        end

			sim:addTrigger( simdefs.TRG_END_TURN, self )	
		end,

		onDespawnAbility = function( self, sim )
            for i, unit in pairs( self._affectedUnits) do
                if unit:getMP() and unit:isValid() then
			        unit:addMP( -3 )
			        unit:addMPMax( -3 )
                end
            end

			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},

	attune = util.extend( createReverseDaemon( STRINGS.REVERSE_DAEMONS.ATTUNE ) )
	{
		icon = "gui/icons/daemon_icons/Program0022.png",

		onSpawnAbility = function( self, sim, player )
			self.duration = sim:nextRand(2, 3)
			sim:dispatchEvent( simdefs.EV_SHOW_REVERSE_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )
            sim:getPC():getTraits().program_cost_modifier = (sim:getPC():getTraits().program_cost_modifier or 0) - 1
			sim:addTrigger( simdefs.TRG_END_TURN, self )	
        end,

		onDespawnAbility = function( self, sim )
            sim:getPC():getTraits().program_cost_modifier = (sim:getPC():getTraits().program_cost_modifier or 0) + 1
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},

	energize = util.extend( createReverseDaemon( STRINGS.REVERSE_DAEMONS.ENERGIZE ) )
	{
		icon = "gui/icons/daemon_icons/Program0021.png",

		onSpawnAbility = function( self, sim, player )
			local credits = 200
			sim:dispatchEvent( simdefs.EV_SHOW_REVERSE_DAEMON, { name = self.name, icon = self.icon, txt = self.activedesc } )

			local pcplayer = sim:getPC()
			
			sim._resultTable.credits_gained.energize = sim._resultTable.credits_gained.energize and sim._resultTable.credits_gained.energize + credits or credits

			pcplayer:addCredits( credits )

			player:removeAbility(sim, self )						
		end,

		onDespawnAbility = function( self, sim )			
		end,	
	},

	acesDaemon = util.extend( createReverseDaemon( STRINGS.REVERSE_DAEMONS.ACES ) )
	{
		icon = "gui/icons/daemon_icons/Daemons_reverse_aces.png",
		title = STRINGS.REVERSE_DAEMONS.ACES.TITLE,

		onSpawnAbility = function( self, sim, player )
			self.duration = 1
			sim:dispatchEvent( simdefs.EV_SHOW_REVERSE_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ), title = self.title } )
            sim:getPC():getTraits().taggedArmorMod = (sim:getPC():getTraits().taggedArmorMod or 0) - 1
			sim:addTrigger( simdefs.TRG_END_TURN, self )	
        end,

		onDespawnAbility = function( self, sim )
            sim:getPC():getTraits().taggedArmorMod = (sim:getPC():getTraits().taggedArmorMod or 0) + 1
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},


	--ALERT DAEMONS
	--********************************
	--********************************

	alertModulate = util.extend( createDaemon( STRINGS.DAEMONS.ALERTMODULATE ) )
	{
		icon = "gui/icons/daemon_icons/Daemons00013.png",
		standardDaemon = false,

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, 20)

			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )
            sim:getPC():getTraits().program_cost_modifier = (sim:getPC():getTraits().program_cost_modifier or 0) + 2
			sim:addTrigger( simdefs.TRG_END_TURN, self )	
		end,

		onDespawnAbility = function( self, sim )
            sim:getPC():getTraits().program_cost_modifier = (sim:getPC():getTraits().program_cost_modifier or 0) - 2
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	}, 

	alertDuplicator = util.extend( createDaemon( STRINGS.DAEMONS.ALERTFRACTAL ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0009.png",
		standardDaemon = false,

		onSpawnAbility = function( self, sim, player )
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = self.activedesc, } )	

			local possibleUnits = {}
			for _, unit in pairs( sim:getAllUnits() ) do
				if unit:getTraits().mainframe_item and unit:getPlayerOwner() ~= sim:getPC() and not unit:getTraits().mainframe_program then
					table.insert( possibleUnits, unit )		
				end
			end

			for k=1,30,1 do 
				if #possibleUnits > 0 then 
					local index = sim:nextRand(1, #possibleUnits)
					local unit = possibleUnits[ index ]
					table.remove( possibleUnits, index )

					if sim:isVersion("0.17.5") then
						local programList = sim:getIcePrograms()
						unit:getTraits().mainframe_program = programList:getChoice( sim:nextRand( 1, programList:getTotalWeight() ))
					else
						unit:getTraits().mainframe_program = PROGRAM_LIST[ sim:nextRand(1, #PROGRAM_LIST) ]
					end	

					sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = unit, ice = unit:getTraits().mainframe_ice, delta = 0} )
				end 
			end 

			player:removeAbility(sim, self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,
	},

	alertPulse = util.extend( createDaemon( STRINGS.DAEMONS.ALERTPULSE ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0009.png",
		standardDaemon = false,

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, 20)
			local pcplayer = sim:getPC()
			self.items = {}

			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = self.activedesc, } )	

			local pcplayer = sim:getPC()
			for i, unit in pairs( pcplayer:getUnits() ) do 
				for i, item in pairs( unit:getChildren() ) do 
					table.insert( self.items, item )
				end 
			end 

			for _, item in ipairs(self.items) do
				if item:getTraits().cooldownMax then 
					item:getTraits().cooldownMax = item:getTraits().cooldownMax + 3
				end 
			end

			sim:addTrigger( simdefs.TRG_END_TURN, self )	
		end,

		onDespawnAbility = function( self, sim, unit )
			for _, item in ipairs(self.items) do
				if item:getTraits().cooldownMax then 
					item:getTraits().cooldownMax = item:getTraits().cooldownMax - 3
				end 
			end
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},

	alertBruteForce = util.extend( createDaemon( STRINGS.DAEMONS.ALERTBLOWFISH ) )
	{
		icon = "gui/icons/daemon_icons/Daemons00010.png",
		standardDaemon = false,

		onSpawnAbility = function( self, sim, player )
			local trackerCount = 10
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon = self.icon, txt = util.sformat(self.activedesc, trackerCount )} )

			sim:trackerAdvance( trackerCount )
			player:removeAbility(sim, self )						
		end,

		onDespawnAbility = function( self, sim )			
		end,		
	},

	alertPanic = util.extend( createDaemon( STRINGS.DAEMONS.PANIC ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0007.png",
		standardDaemon = false,

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, 4)
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )
            sim:getNPC():doTrackerSpawn(sim, 1, simdefs.TRACKER_SPAWN_UNIT_ENFORCER_2 )

            local npcPlayer = sim:getNPC()
			for _, unit in ipairs(npcPlayer:getUnits() ) do
				if unit:getBrain() and not unit:getTraits().enforcer then
					unit:setAlerted(true)
				end
			end		

			local agent = nil
    		local agents = sim:getPC():getAgents()
    		agent = agents[ sim:nextRand( 1, #agents ) ] 

    		self._guardsTagged = {}

			sim:addTrigger( simdefs.TRG_END_TURN, self )
			sim:addTrigger( simdefs.TRG_START_TURN, self )	
        end,

        onTrigger = function( self, sim, evType, evData, userUnit )
	    	if evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isPC() then
	    		local agent = nil
	    		local agents = sim:getPC():getAgents()
	    		agent = agents[ sim:nextRand( 1, #agents ) ] 

	    		createCountermeasureInterest( self, sim, agent )
            else
                DEFAULT_ABILITY.onTrigger( self, sim, evType, evData, userUnit )
            end
        end,

		onDespawnAbility = function( self, sim )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end		
	},

	panic = util.extend( createDaemon( STRINGS.DAEMONS.PANIC ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0007.png",
		standardDaemon = false,

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, 3)
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )

            if sim:getParams().campaignDifficulty == simdefs.HARD_DIFFICULTY then 
            	sim:getNPC():doTrackerSpawn(sim, 1, simdefs.TRACKER_SPAWN_UNIT_ENFORCER_2 )
            elseif sim:getParams().campaignDifficulty == simdefs.VERY_HARD_DIFFICULTY then 
            	for i=1, 2 do 
            		sim:getNPC():doTrackerSpawn(sim, 1, simdefs.TRACKER_SPAWN_UNIT_ENFORCER_2 )
            	end
            end 

            local npcPlayer = sim:getNPC()
			for _, unit in ipairs(npcPlayer:getUnits() ) do
				if unit:getBrain() and not unit:getTraits().enforcer then
					unit:setAlerted(true)
				end
			end		

			self._guardsTagged = {}

			local agent = nil
				for _, unit in pairs( sim:getPC():getAgents() ) do
					if unit:getTraits().monst3r then 
						agent = unit
					end 
				end 

			createCountermeasureInterest( self, sim, agent )

			sim:addTrigger( simdefs.TRG_END_TURN, self )
			sim:addTrigger( simdefs.TRG_START_TURN, self )	
        end,

        onTrigger = function( self, sim, evType, evData, userUnit )
	    	if evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isPC() then
    			local agent = nil
				for _, unit in pairs( sim:getPC():getAgents() ) do
					if unit:getTraits().monst3r then 
						agent = unit
					end 
				end 

				createCountermeasureInterest( self, sim, agent )
            else
                DEFAULT_ABILITY.onTrigger( self, sim, evType, evData, userUnit )
            end
        end,

		onDespawnAbility = function( self, sim )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end		
	},

	--REGULAR DAEMONS
	--////////////////////////////////
	--////////////////////////////////

	failsafe = util.extend( createDaemon( STRINGS.DAEMONS.FAILSAFE ) )
	{
		icon = "gui/icons/daemon_icons/Daemons00014.png",
		standardDaemon = false,

		-- This ability doesn't do anything. It just provides strings for the logic that runs in the ENDING_1 script.  

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, 3)
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )
			sim:addTrigger( simdefs.TRG_END_TURN, self )
        end,

		onDespawnAbility = function( self, sim )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end			
	},


	bruteForce = util.extend( createDaemon( STRINGS.DAEMONS.BLOWFISH ) )
	{
		icon = "gui/icons/daemon_icons/Daemons00010.png",
		xValues = {1, 2, 3},

		onSpawnAbility = function( self, sim, player )
			local trackerCount = self.xValues[ sim:nextRand(1, #self.xValues) ]
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon = self.icon, txt = util.sformat(self.activedesc, trackerCount )} )

			sim:trackerAdvance( trackerCount )
			player:removeAbility(sim, self )						
		end,

		onDespawnAbility = function( self, sim )			
		end,		
	},

	fortify = util.extend( createDaemon( STRINGS.DAEMONS.RUBIKS ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0001.png",

		onSpawnAbility = function( self, sim, player )
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = self.activedesc, } )	
            sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 0.5 * cdefs.SECONDS )
			for _, unit in pairs( sim:getAllUnits() ) do
				unit:increaseIce(sim,1)
			end
			player:removeAbility(sim, self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,
	},

	validate = util.extend( createDaemon( STRINGS.DAEMONS.VALIDATE ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0004.png",

		onSpawnAbility = function( self, sim, player )
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = self.activedesc } )	

			if sim._params.difficulty < 3 then
				sim:getNPC():doTrackerSpawn(sim, 1, simdefs.TRACKER_SPAWN_UNIT_ENFORCER )
			else
				sim:getNPC():doTrackerSpawn(sim, 1, simdefs.TRACKER_SPAWN_UNIT_ENFORCER_2 )
			end
			player:removeAbility(sim, self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,
	},

	siphon = util.extend( createDaemon( STRINGS.DAEMONS.SIPHON ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0005.png",

		onSpawnAbility = function( self, sim, player )
			self._cpu = sim:nextRand(2, 5)
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self._cpu ), } )	

			sim:getCurrentPlayer():addCPUs( -self._cpu )
			player:removeAbility(sim, self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,
	},

	duplicator = util.extend( createDaemon( STRINGS.DAEMONS.FRACTAL ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0009.png",

		onSpawnAbility = function( self, sim, player )
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = self.activedesc, } )	

			local possibleUnits = {}
			for _, unit in pairs( sim:getAllUnits() ) do
				if unit:getTraits().mainframe_iceMax and unit:getTraits().mainframe_ice and unit:getPlayerOwner() ~= sim:getPC() and not unit:getTraits().mainframe_program then
					table.insert( possibleUnits, unit )		
				end
			end

			for k=1,2,1 do 
				if #possibleUnits > 0 then 
					local index = sim:nextRand(1, #possibleUnits)
					local unit = possibleUnits[ index ]
					table.remove( possibleUnits, index )

					if sim:isVersion("0.17.5") then
						local programList = sim:getIcePrograms()
						unit:getTraits().mainframe_program = programList:getChoice( sim:nextRand( 1, programList:getTotalWeight() ))
					else
						unit:getTraits().mainframe_program = PROGRAM_LIST[ sim:nextRand(1, #PROGRAM_LIST) ]						
					end						
					
					sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = unit, ice = unit:getTraits().mainframe_ice, delta = 0} )
				end 
			end 

			player:removeAbility(sim, self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,
	},

	incognitaKiller = util.extend( createDaemon( STRINGS.DAEMONS.PARADOX ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0008.png",

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim,sim:nextRand(2, 3))
			sim:setMainframeLockout( true )
			sim:addTrigger( simdefs.TRG_END_TURN, self )	

			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )	
		end,

		onDespawnAbility = function( self, sim )
			sim:setMainframeLockout( false )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},

	agent_sapper = util.extend( createDaemon( STRINGS.DAEMONS.LABYRINTH ) )
	{
		icon = "gui/icons/daemon_icons/Daemons00012.png",

		drain = 2,

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, sim:nextRand(3, 5))
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = self.activedesc } )	

            self._affectedUnits = {}
            for i, unit in pairs(sim:getPC():getUnits()) do
		        if unit:getMP() then
			        unit:addMP( -2 )
			        unit:addMPMax( -2 )
                    table.insert( self._affectedUnits, unit )
		        end
	        end

			sim:addTrigger( simdefs.TRG_END_TURN, self )	
		end,

		onDespawnAbility = function( self, sim )
            for i, unit in pairs( self._affectedUnits) do
                if unit:getMP() and unit:isValid() then
			        unit:addMP( 2 )
			        unit:addMPMax( 2 )
                end
            end

			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},	

	modulate = util.extend( createDaemon( STRINGS.DAEMONS.MODULATE ) )
	{
		icon = "gui/icons/daemon_icons/Daemons00013.png",

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, sim:nextRand(4, 5))
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )
            sim:getPC():getTraits().program_cost_modifier = (sim:getPC():getTraits().program_cost_modifier or 0) + 2
			sim:addTrigger( simdefs.TRG_END_TURN, self )	
        end,

		onDespawnAbility = function( self, sim )
            sim:getPC():getTraits().program_cost_modifier = (sim:getPC():getTraits().program_cost_modifier or 0) - 2
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},	

    authority = util.extend( createDaemon( STRINGS.DAEMONS.AUTHORITY ) )
    {
		icon = "gui/icons/daemon_icons/Daemons0003.png",

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, sim:nextRand(4, 5))
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )
			sim:addTrigger( simdefs.TRG_SAFE_LOOTED, self )	
			sim:addTrigger( simdefs.TRG_END_TURN, self )	
		end,

		onDespawnAbility = function( self, sim )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
			sim:removeTrigger( simdefs.TRG_SAFE_LOOTED, self )	
		end,

    	onTrigger = function( self, sim, evType, evData, userUnit )
	    	if evType == simdefs.TRG_SAFE_LOOTED and evData.targetUnit:getTraits().safeUnit then
    	        local x0, y0 = evData.unit:getLocation()
	            sim:getNPC():spawnInterest(x0, y0, simdefs.SENSE_RADIO, simdefs.REASON_ALARMEDSAFE, evData.unit)
	            sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.DAEMONS.AUTHORITY.WARNING, color=cdefs.COLOR_CORP_WARNING, sound = "SpySociety/Actions/mainframe_deterrent_action" } )

	            --also raise the alarm
				local trackerCount = 1
				sim:trackerAdvance( trackerCount )

            else
                DEFAULT_ABILITY.onTrigger( self, sim, evType, evData, userUnit )
            end
        end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
    },

	damonHider = util.extend( createDaemon( STRINGS.DAEMONS.MASK ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0002.png",

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, sim:nextRand(3, 4))
			sim:addTrigger( simdefs.TRG_END_TURN, self )	
			sim:hideDaemons(true)
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_mask" )
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )	
			
		end,

		onDespawnAbility = function( self, sim )
			sim:hideDaemons(false)
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},

	creditTaker = util.extend( createDaemon( STRINGS.DAEMONS.FELIX ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0006.png",

		onSpawnAbility = function( self, sim, player, host )

			self._credit = sim:nextRand(1,4)*50 * (sim._params.difficulty or 1)
			
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_blackcat" )	
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self._credit ), } )	
			
			if host then
				local x,y =  host:getLocation()
				if x and y then
					sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=string.format("- %d CR",self._credit), x=x,y=y, color={r=1,g=1,b=1,a=1},target="credits"} )	
				end
			end

			sim._resultTable.credits_lost.felix = sim._resultTable.credits_lost.felix and sim._resultTable.credits_lost.felix + self._credit or self._credit

			sim:getCurrentPlayer():addCredits( -self._credit )
			player:removeAbility(sim, self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,	
	},	

	creditTaker_new = util.extend( createDaemon( STRINGS.DAEMONS.FELIX_NEW ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0006.png",

		mult = 2,

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, sim:nextRand(3, 5))
			if sim._params.difficulty > 3 then 
				self.mult = 3
			end

			for i, unit in pairs(sim:getAllUnits()) do
				if unit:getTraits().safeUnit and unit:getPlayerOwner() ~= sim:getPC() and not unit:getTraits().open then
					unit:getTraits().mainframe_ice = unit:getTraits().mainframe_ice * self.mult
					if unit:getTraits().credits then
						unit:getTraits().credits = math.floor(unit:getTraits().credits * 1.1)+1
					end
					local x1, y1 = unit:getLocation()
					sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, { unit = unit , txt=STRINGS.DAEMONS.FELIX_NEW.ALERT, x=x1,y=y1,color={r=255/255,g=10/255,b=10/255,a=1 },skipQue=true  } )	-- 
				end
			end
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.mult  ) } )
			sim:addTrigger( simdefs.TRG_END_TURN, self )	
		end,

		onDespawnAbility = function( self, sim )		
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
			for i, unit in pairs(sim:getAllUnits()) do
				if unit:getTraits().safeUnit and unit:getPlayerOwner() ~= sim:getPC() and not unit:getTraits().open then
					unit:getTraits().mainframe_ice = math.floor(unit:getTraits().mainframe_ice / self.mult)+1
					if unit:getTraits().credits then
						unit:getTraits().credits = math.floor(unit:getTraits().credits / 1.1)+1
					end
					local x1, y1 = unit:getLocation()
					sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, { unit = unit , txt=STRINGS.DAEMONS.FELIX_NEW.ALERT_FINISH, x=x1,y=y1,color={r=255/255,g=255/255,b=51/255,a=1 },skipQue=true  } )	-- 					
				end
			end	
		end,
	
		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},		

}

for k, v in pairs(npc_abilities) do
    assert( v.name ) -- DO NOT ADD ANYTHING TO THE TABLE THAT IS NOT AN ABILITY.
end

return npc_abilities
