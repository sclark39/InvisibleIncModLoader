local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "client_util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local cdefs = include( "client_defs" )
local mainframe = include( "sim/mainframe" )
local modifiers = include( "sim/modifiers" )
local mission_util = include( "sim/missions/mission_util" )
local serverdefs = include("modules/serverdefs")
local mainframe_common = include("sim/abilities/mainframe_common")

-------------------------------------------------------------------------------
-- These are PC mainframe abilities.  They are owned and executed by the player.
local DEFAULT_ABILITY = mainframe_common.DEFAULT_ABILITY

local WRENCH_TEMPLATE = util.extend( DEFAULT_ABILITY )
{
	icon = "gui/icons/programs_icons/icon-program-wrench.png",
	icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_wrench.png",
	cpu_cost = 2,
	break_firewalls = 0, 
	equip_program = true,
	equipped = false, 
	wrench = true, 
}

local PARASITE_TEMPLATE = util.extend( DEFAULT_ABILITY )
{
	name = STRINGS.PROGRAMS.PARASITE.NAME,
	desc = STRINGS.PROGRAMS.PARASITE.DESC,
	huddesc = STRINGS.PROGRAMS.PARASITE.HUD_DESC,
	shortdesc = STRINGS.PROGRAMS.PARASITE.SHORT_DESC,

	icon = "gui/icons/programs_icons/icon-program-parasite.png",
	icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_parasite.png",
	cpu_cost = 0,
    break_firewalls = 0,
    parasite_strength = 1,
	equip_program = true, 
	equipped = false, 
	firewallDisplay = "X",
	parasite_hosts = {},

	getCpuCost = function( self )
        self.cpu_cost = #self.parasite_hosts
        return DEFAULT_ABILITY.getCpuCost( self )
	end,

	onSpawnAbility = function( self, sim )
		sim:addTrigger( simdefs.TRG_START_TURN, self )		
	end, 

    onDespawnAbility = function( self, sim )
    		-- overide despawn for parasite
    end,

	onTrigger = function( self, sim, evType, evData )
		if evType == simdefs.TRG_START_TURN and evData:isPC() then
			
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			local parasiteCount = 0
            local hosts = util.tdupe(self.parasite_hosts)
            for i, hostID in ipairs(hosts) do
                local hostUnit = sim:getUnit( hostID )
                if hostUnit and hostUnit:getTraits().parasite and hostUnit:getTraits().mainframe_ice > 0 then
					mainframe.breakIce( sim, hostUnit, self.parasite_strength )
					parasiteCount = parasiteCount + 1
                end
            end
			if parasiteCount > 0 then
				sim:dispatchEvent( simdefs.EV_MAINFRAME_PARASITE )
			end
		end
	end,


	canUseAbility = function( self, sim, abilityOwner, targetUnit )
		if targetUnit and targetUnit:getTraits().parasite then
			return false, STRINGS.PROGRAMS.PARASITE.ALREADY_HOSTED
		end

		return DEFAULT_ABILITY.canUseAbility( self, sim, abilityOwner, targetUnit )
	end,

	executeAbility = function( self, sim, targetUnit )
        if not targetUnit:getTraits().parasite then
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_HOST_PARASITE.path )
			self:setCooldown( sim )
            self:useCPUs( sim )
			targetUnit:getTraits().parasite = true 
			if self.parasiteV2 then
				targetUnit:getTraits().parasiteV2 = true 
			end
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_parasite_installed")
			table.insert(self.parasite_hosts,targetUnit:getID())
        end
	end,		
}

local mainframe_abilities =
{
	remoteprocessor = util.extend( DEFAULT_ABILITY ) 
	{
		name = STRINGS.PROGRAMS.POWER_DRIP.NAME,
		desc = STRINGS.PROGRAMS.POWER_DRIP.DESC,
		shortdesc = STRINGS.PROGRAMS.POWER_DRIP.SHORT_DESC,
		huddesc = STRINGS.PROGRAMS.POWER_DRIP.HUD_DESC,
		icon = "gui/icons/programs_icons/icon-program-powerdrip.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_drip.png",
		credit_cost = 0, 
		value = 300,

		passive = true,
		
		executeAbility = function( self, sim )
			local player = sim:getCurrentPlayer()			
			if not player:isNPC() then
				--jcheng: no longer tell them about power drip
				--[[
				if sim:getParams().missionCount == 0 and sim:getTurnCount() == 2 and not sim:getTags().isTutorial then
                    local dialogParams =
                    {
                        STRINGS.PROGRAMS.POWER_DRIP.MODAL_1,
                        STRINGS.PROGRAMS.POWER_DRIP.MODAL_2,
                        STRINGS.PROGRAMS.POWER_DRIP.MODAL_3,
                        "gui/icons/programs_icons/store_icons/StorePrograms_drip.png"
                    }
					sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "programDialog", dialogParams = dialogParams } )
				end	
				]]

				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_MAINFRAME_PROGRAM_AUTO_RUN )
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.PROGRAMS.POWER_DRIP.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
				player:addCPUs( 1 )
			end
		end,

		canUseAbility = function( self, sim )
			return false 	
		end,

		onSpawnAbility = function( self, sim )
			DEFAULT_ABILITY.onSpawnAbility( self, sim )	
		end,


		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			if evType == simdefs.TRG_START_TURN then
				self:executeAbility(sim)	
			end
		end,
	},

	emergency_drip = util.extend( DEFAULT_ABILITY ) 
	{
		name = STRINGS.PROGRAMS.EMERGENCY_DRIP.NAME,
		desc = STRINGS.PROGRAMS.EMERGENCY_DRIP.DESC,
		shortdesc = STRINGS.PROGRAMS.EMERGENCY_DRIP.SHORT_DESC,
		huddesc = STRINGS.PROGRAMS.EMERGENCY_DRIP.HUD_DESC,
		icon = "gui/icons/programs_icons/Program0016.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_0016.png",
		cpu_cost = nil,
		credit_cost = 0, 
		value = 300,
        MIN_CPU = 4,
        cooldown = 0,        
        maxCooldown = 3, 

        passive = true,

		executeAbility = function( self, sim )
			local player = sim:getCurrentPlayer()			
			if not player:isNPC() and player:getCpus() < self.MIN_CPU and self.cooldown <= 0 then
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=util.sformat( STRINGS.PROGRAMS.EMERGENCY_DRIP.WARNING, 5 ), color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
				player:addCPUs( 5 )
				self:setCooldown( sim )				
			end
		end,

		canUseAbility = function( self, sim )
			return false 	
		end,

		onSpawnAbility = function( self, sim )
			DEFAULT_ABILITY.onSpawnAbility( self, sim )		
		end,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			if evType == simdefs.TRG_START_TURN and evData:isPC() then				
				if self.cooldown <= 0 then 
					self:executeAbility( sim )
				end 
			end
		end,
	},

	lockpick_1 = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.LOCKPICK.NAME,
		desc = STRINGS.PROGRAMS.LOCKPICK.DESC,
		huddesc = STRINGS.PROGRAMS.LOCKPICK.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.LOCKPICK.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.LOCKPICK.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-lockpick.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_lockpick.png",
		cpu_cost = 2,
		break_firewalls = 1, 
		equip_program = true, 
		equipped = false, 
		value = 300,
	},

	lockpick_2 = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.LOCKPICK_2.NAME,
		desc = STRINGS.PROGRAMS.LOCKPICK_2.DESC,
		huddesc = STRINGS.PROGRAMS.LOCKPICK_2.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.LOCKPICK_2.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.LOCKPICK_2.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-lockpick_2.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_lockpick_2.png",
		cpu_cost = 3,
		break_firewalls = 2, 
		equip_program = true, 
		noexecute = true, 
		equipped = false, 
		value = 700,
	},

	wrench_2 = util.extend( WRENCH_TEMPLATE )
	{
		name = STRINGS.PROGRAMS.WRENCH_2.NAME,
		desc = STRINGS.PROGRAMS.WRENCH_2.DESC,
		huddesc = STRINGS.PROGRAMS.WRENCH_2.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.WRENCH_2.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.WRENCH_2.TIP_DESC,
		break_firewalls = 2,
		value = 600,
	},

	wrench_3 = util.extend( WRENCH_TEMPLATE )
	{
		name = STRINGS.PROGRAMS.WRENCH_3.NAME,
		desc = STRINGS.PROGRAMS.WRENCH_3.DESC,
		huddesc = STRINGS.PROGRAMS.WRENCH_3.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.WRENCH_3.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.WRENCH_3.TIP_DESC,
		break_firewalls = 3,
		cpu_cost = 3,
		value = 600,
	},

	wrench_4 = util.extend( WRENCH_TEMPLATE )
	{
		name = STRINGS.PROGRAMS.WRENCH_4.NAME,
		desc = STRINGS.PROGRAMS.WRENCH_4.DESC,
		huddesc = STRINGS.PROGRAMS.WRENCH_4.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.WRENCH_4.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.WRENCH_4.TIP_DESC,
		break_firewalls = 4,
		cpu_cost = 4,
		value = 600,
	},

	wrench_5 = util.extend( WRENCH_TEMPLATE )
	{
		name = STRINGS.PROGRAMS.WRENCH_5.NAME,
		desc = STRINGS.PROGRAMS.WRENCH_5.DESC,
		huddesc = STRINGS.PROGRAMS.WRENCH_5.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.WRENCH_5.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.WRENCH_5.TIP_DESC,
		break_firewalls = 5,
		cpu_cost = 4,
		value = 600,
	},

	hammer = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.HAMMER.NAME,
		desc = STRINGS.PROGRAMS.HAMMER.DESC,
		huddesc = STRINGS.PROGRAMS.HAMMER.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.HAMMER.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.HAMMER.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-hammer.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_hammer.png",
		cpu_cost = 5,
		break_firewalls = 5, 
		equip_program = true, 
		equipped = false, 
		cooldown = 0,
		maxCooldown = 3,
		value = 600,

	},

	dagger = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.DAGGER.NAME,
		desc = STRINGS.PROGRAMS.DAGGER.DESC,
		huddesc = STRINGS.PROGRAMS.DAGGER.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.DAGGER.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.DAGGER.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-dagger.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_dagger.png",
		cpu_cost = 1,
		break_firewalls = 3, 
		equip_program = true, 
		equipped = false, 
		cooldown = 0,
		maxCooldown = 5,
		value = 450,

	},

	brimstone = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.BRIMSTONE.NAME,
		desc = STRINGS.PROGRAMS.BRIMSTONE.DESC,
		huddesc = STRINGS.PROGRAMS.BRIMSTONE.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.BRIMSTONE.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.BRIMSTONE.TIP_DESC,

		icon = "gui/icons/programs_icons/Program0025.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_brimstone.png",
		cpu_cost = 3,
		break_firewalls = 1, 
		equip_program = true, 
		equipped = false, 
		value = 450,
		daemonReversalAdd = 10,
		lockedText = STRINGS.UI.TEAM_SELECT.UNLOCK_CENTRAL_MONSTER,
	},

	dagger_2 = util.extend( DEFAULT_ABILITY )
	{


		name = STRINGS.PROGRAMS.DAGGER_2.NAME,
		desc = STRINGS.PROGRAMS.DAGGER_2.DESC,
		huddesc = STRINGS.PROGRAMS.DAGGER_2.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.DAGGER_2.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.DAGGER_2.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-dagger_2.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_dagger_2.png",
		cpu_cost = 3,
		break_firewalls = 5, 
		equip_program = true, 
		noexecute = true, 
		equipped = false, 
		cooldown = 0,
		maxCooldown = 4,
		value = 650,

	},

	parasite = util.extend( PARASITE_TEMPLATE )
	{
		value = 400,
		tipdesc = STRINGS.PROGRAMS.PARASITE.TIP_DESC,
    },

	parasite_2 = util.extend( PARASITE_TEMPLATE )
	{

		name = STRINGS.PROGRAMS.PARASITE_2.NAME,
		desc = STRINGS.PROGRAMS.PARASITE_2.DESC,
		huddesc = STRINGS.PROGRAMS.PARASITE_2.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.PARASITE_2.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.PARASITE_2.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-parasite_2.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_parasite_2.png",
		cpu_cost = 2,
        parasite_strength = 2,
        value = 500,
        parasiteV2 = true,

	    getCpuCost = function( self )
            self.cpu_cost = #self.parasite_hosts + 2
            return DEFAULT_ABILITY.getCpuCost( self )
	    end,
	},

	sniffer = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.SNIFFER.NAME,
		desc = STRINGS.PROGRAMS.SNIFFER.DESC,
		huddesc = STRINGS.PROGRAMS.SNIFFER.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.SNIFFER.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.SNIFFER.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-sniffer.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_sniffer.png",
		cpu_cost = 0,
		break_firewalls = 0, 
		equip_program = true, 
		equipped = false,
		sniffer = true,  
		cooldown = 0,
		maxCooldown = 3,
		value = 350,


		executeAbility = function( self, sim, targetUnit )
			targetUnit:getTraits().daemon_sniffed = true 
			self:setCooldown( sim )
            self:useCPUs( sim )
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_DAEMON_REVEAL.path )
		end,
	},

	hunter = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.HUNTER.NAME,
		desc = STRINGS.PROGRAMS.HUNTER.DESC,
		huddesc = STRINGS.PROGRAMS.HUNTER.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.HUNTER.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.HUNTER.TIP_DESC,

		icon = "gui/icons/programs_icons/Programs0013.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_program13.png",
		cpu_cost = 5,
		break_firewalls = 0, 
		equip_program = true, 
		equipped = false,
		daemon_killer = true,   
		cooldown = 0,
		maxCooldown = 3,
		value = 550,

		executeAbility = function( self, sim, targetUnit )

			if targetUnit:getTraits().mainframe_program == nil then
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_HUD_INCIDENT_NEGATIVE.path )
				mission_util.showDialog( sim, STRINGS.UI.DIALOGS.NO_DAEMON_TITLE, STRINGS.UI.DIALOGS.NO_DAEMON_BODY )
			else
			
				targetUnit:getTraits().mainframe_program = nil
				sim:dispatchEvent( simdefs.EV_KILL_DAEMON, {unit = targetUnit})
				
				if targetUnit:getTraits().daemonHost then
					sim:getUnit(targetUnit:getTraits().daemonHost):killUnit(sim)
					targetUnit:getTraits().daemonHost =nil
				end

				self:setCooldown( sim )
				
                self:useCPUs( sim )

				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_DAEMON_REVEAL.path )
			end
		end,
	},

	mainframePing = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.PING.NAME,
		desc = STRINGS.PROGRAMS.PING.DESC,
		huddesc = STRINGS.PROGRAMS.PING.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.PING.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.PING.TIP_DESC,


		icon = "gui/icons/programs_icons/icon-program-ping.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_ping.png",
		cpu_cost = 1,
		credit_cost = 0,
		cooldown = 0,
		maxCooldown = 4,
		value = 450,

		acquireTargets = function( self, targets, game, sim, unit )
			return targets.simpleAreaTarget( game, simdefs.SOUND_MAINFRAME_PING.range, sim )
		end, 

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			local player = sim:getCurrentPlayer()
			local cellx, celly = unpack(targetCell)

			self:setCooldown( sim )

			sim:dispatchEvent( simdefs.EV_SCANRING_VIS, { x= cellx,y= celly, range= simdefs.SOUND_MAINFRAME_PING.range } )		

			sim:emitSound( simdefs.SOUND_MAINFRAME_PING, cellx, celly, nil, {{ x = cellx, y = celly }} )
			sim:processReactions()
			-- Always want to hear the sound played
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_MAINFRAME_PING.path )
            self:useCPUs( sim )
			player:addCredits( -self.credit_cost )
		end,
	},

	-- NOTE: this Fusion has been replaced with fusion_17_5 after version 0.17.5
	fusion = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.FUSION.NAME,
		desc = STRINGS.PROGRAMS.FUSION.DESC,
		huddesc = STRINGS.PROGRAMS.FUSION.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.FUSION.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.FUSION.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-fusion.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_fusion.png",
		cpu_cost = 5,
		credit_cost = 0,
		cooldown = 0,
		maxCooldown = 4,
		value = 300,

		abilityOverride = "fusion_17_5",

		onTrigger = function( self, sim, evType, evData )

			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			if evType == simdefs.TRG_START_TURN and evData:isPC() then
				if self.cooldown > 0 then 
					evData:addCPUs( 3 )
					sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_MAINFRAME_PROGRAM_AUTO_RUN )
					sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.PROGRAMS.FUSION.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
				end 
			end

		end,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			local player = sim:getCurrentPlayer()
			self:setCooldown( sim )
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_run_fusion" )
            self:useCPUs( sim )
		end,
	},

	fusion_17_5 = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.FUSION_17_5.NAME,
		desc = STRINGS.PROGRAMS.FUSION_17_5.DESC,
		huddesc = STRINGS.PROGRAMS.FUSION_17_5.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.FUSION_17_5.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.FUSION_17_5.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-fusion.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_fusion.png",
		cpu_cost = 5,
		credit_cost = 0,
		cooldown = 0,
		maxCooldown = 3,
		value = 300,

		onTrigger = function( self, sim, evType, evData )

			if evType == simdefs.TRG_START_TURN and evData:isPC() then
				if self.cooldown > 0 then 
					evData:addCPUs( 3 )
					sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_MAINFRAME_PROGRAM_AUTO_RUN )
					sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.PROGRAMS.FUSION.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
				end 
			end
			
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )
		end,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			local player = sim:getCurrentPlayer()
			self:setCooldown( sim )
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_run_fusion" )
            self:useCPUs( sim )
		end,
	},	

	seed = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.SEED.NAME,
		desc = STRINGS.PROGRAMS.SEED.DESC,
		huddesc = STRINGS.PROGRAMS.SEED.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.SEED.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.SEED.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-seed.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_seed.png",
		cpu_cost = 0,
		credit_cost = 0,
		cooldown = 0,
		maxCooldown = 1,
		passive = true,
		value = 350,

		canUseAbility = function( self, sim )
			return false 
		end,

        executeAbility = function( self, sim )
            self:setCooldown( sim )

            sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_MAINFRAME_PROGRAM_AUTO_RUN )
		    sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.PROGRAMS.SEED.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )

            sim:getTags().nextProgFree = (sim:getTags().nextProgFree or 0) - 1
            if sim:getTags().nextProgFree <= 0 then
                sim:getTags().nextProgFree = nil
            end
        end,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )
			if evType == simdefs.TRG_START_TURN and evData:isPC() then
                if self.cooldown == 0 then
        			sim:getTags().nextProgFree = (sim:getTags().nextProgFree or 0) + 1
                end
			end
		end,
	},


	faust = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.FAUST.NAME,
		desc = STRINGS.PROGRAMS.FAUST.DESC,
		huddesc = STRINGS.PROGRAMS.FAUST.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.FAUST.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.FAUST.TIP_DESC,
		lockedText = STRINGS.UI.TEAM_SELECT.UNLOCK_CENTRAL_MONSTER,

		icon = "gui/icons/programs_icons/icon-program-faust.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_faust.png",
		credit_cost = 0, 
		value = 300,
		daemonChance = 20,
		lastTurnDaemon = false,

		passive = true,
		
		executeAbility = function( self, sim )
			--don't execute on first turn
			if sim:isVersion("0.17.5") then 
				if sim:getTurnCount() == 0 then
					return
				end
			else	
				if sim:getTurnCount() == 1 then
					return
				end		
			end

			local player = sim:getCurrentPlayer()			
			if not player:isNPC() then

				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_MAINFRAME_PROGRAM_AUTO_RUN )
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.PROGRAMS.FAUST.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
				player:addCPUs( 2 )
				local rand = sim:nextRand( 0, 100 )
				if rand <= self.daemonChance then 

					local programList = nil
					local daemon = nil
					if sim:isVersion("0.17.5") then
						programList = sim:getIcePrograms()
						daemon = programList:getChoice( sim:nextRand( 1, programList:getTotalWeight() ))
					else
						programList = serverdefs.PROGRAM_LIST
						daemon = programList[sim:nextRand(1, #programList)]			
					end	

					sim:getNPC():addMainframeAbility( sim, daemon )
					self.lastTurnDaemon = true 
				end 
			end
		end,

		canUseAbility = function( self, sim )
			return false 	
		end,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )
			if evType == simdefs.TRG_START_TURN then
				self:executeAbility(sim)	
			end
		end,
	},

	love = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.LOVE.NAME,
		desc = STRINGS.PROGRAMS.LOVE.DESC,
		huddesc = STRINGS.PROGRAMS.LOVE.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.LOVE.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.LOVE.TIP_DESC,

		icon = "gui/icons/programs_icons/Program0024.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_love.png",
		cpu_cost = 5,
		credit_cost = 0,
		cooldown = 0,
		maxCooldown = 3,
		program_strength = 2, 
		--color = util.color( 39/255, 215/255, 39/255, 1 ),

        
        getTargetUnits = function( self, sim )
            local units = {}
            local x0, y0
            for unitID, unit in pairs( sim:getAllUnits() ) do
                local x, y = unit:getLocation()
                if x and y and sim:getCurrentPlayer():getLastKnownCell( sim, x, y ) ~= nil then
                    if unit:getTraits().central then
                        x0, y0 = x, y
                    elseif mainframe.canBreakIce( sim, unit, self ) then
                        table.insert( units, unit )
                    end
                end
            end

            if not x0 then
                return -- No ground zero.
            end

            local range = -math.huge
            if x0 and y0 then
                for i, unit in ipairs(units) do
                    range = math.max( range, mathutil.dist2d( x0, y0, unit:getLocation() ))
                end
            end
            return units, x0, y0, math.ceil( range )
        end,

		executeAbility = function( self, sim, unit, userUnit )
			local player = sim:getCurrentPlayer()
            local currentProgram = player:getEquippedProgram()

    		player:equipProgram( sim, self:getID() )

            sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_turing_use" )

            local targetUnits, x0, y0, range = self:getTargetUnits( sim )
            if not x0 then
                return
            end
            -- For effect, ensure range is at least reasonably large...
            range = math.max( range, 16 )
           	sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = x0, y = y0, units = targetUnits, range = range } )		

            local daemonUnits = {}
            for _, unit in ipairs(targetUnits) do
                -- Keep track of daemons that *Would* be invoked, so that we can invoke them only after
                -- everything has been broken.
                local daemonProgram = unit:getTraits().mainframe_program

                unit:getTraits().mainframe_program = nil
                mainframe.breakIce( sim, unit, self.program_strength )
                unit:getTraits().mainframe_program = daemonProgram

                if daemonProgram and unit:getTraits().mainframe_ice <= 0 then
                    table.insert( daemonUnits, unit )
                end
	        end

            self:useCPUs( sim )
    		player:equipProgram( sim, currentProgram and currentProgram:getID() )

            for i, unit in ipairs( daemonUnits ) do
                mainframe.invokeDaemon( sim, unit )
            end
            self:setCooldown( sim )

            sim:triggerEvent( "used_turing" )            
		end,
	},

	wildfire = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.WILDFIRE.NAME,
		desc = STRINGS.PROGRAMS.WILDFIRE.DESC,
		huddesc = STRINGS.PROGRAMS.WILDFIRE.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.WILDFIRE.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.WILDFIRE.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-wildfire.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_wildfire.png",
		cpu_cost = 0,
		credit_cost = 0,
		cooldown = 0,
		maxCooldown = 1,
		value = 400,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			local player = sim:getCurrentPlayer()
			self:setCooldown( sim )
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_run_fusion" )
            self:useCPUs( sim )
			player:addCPUs( 5 )
			sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.PROGRAMS.WILDFIRE.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
			
			for _, unit in pairs( sim:getAllUnits() ) do			
		    	unit:increaseIce(sim,1)
			end

		end,
	},


	oracle = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.ORACLE.NAME,
		desc = STRINGS.PROGRAMS.ORACLE.DESC,
		huddesc = STRINGS.PROGRAMS.ORACLE.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.ORACLE.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.ORACLE.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-oracle.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_oracle.png",
		cpu_cost = 4,
		credit_cost = 0,
		value = 500,

		canUseAbility = function( self, sim, abilityOwner )
			local player = sim:getCurrentPlayer()
			if player ~= abilityOwner or player == nil then
				return false
			end
			--Are there any uncaptured cameras left? 
			local cameras = false
			for _, unit in pairs( sim:getAllUnits() ) do 	
				if unit:getTraits().mainframe_camera then 
					if unit:getPlayerOwner() ~= player and unit:getTraits().mainframe_status == "active" then 
						cameras = true 
					end
				end
			end

			if not cameras then 
				return false, STRINGS.UI.REASON.NO_CAMERAS
			end

			return DEFAULT_ABILITY.canUseAbility( self, sim, abilityOwner )
		end,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			local player = sim:getCurrentPlayer()
            self:useCPUs( sim )
			local availableCameras = {}

			for _, unit in pairs( sim:getAllUnits() ) do 
				if unit:getTraits().mainframe_camera then 
					if unit:getPlayerOwner() ~= player and unit:getTraits().mainframe_status == "active" then 
						table.insert( availableCameras, unit )
					end
				end
			end

			local camera = availableCameras[ sim:nextRand( 1, #availableCameras ) ]
            mainframe.breakIce( sim, camera, camera:getTraits().mainframe_ice )

    		sim:dispatchEvent( simdefs.EV_CAM_PAN, { camera:getLocation() } )	
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_object_camera" )

			if sim:isVersion("0.17.6") then
				self:setCooldown( sim ) 
			end
		end,
	},

	rapier = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.RAPIER.NAME,
		desc = STRINGS.PROGRAMS.RAPIER.DESC,
		huddesc = STRINGS.PROGRAMS.RAPIER.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.RAPIER.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.RAPIER.TIP_DESC,

		icon = "gui/icons/programs_icons/Program0017.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_0017.png",
		cpu_cost = 1,
		break_firewalls = 1, 
		equip_program = true, 
		noexecute = true, 
		equipped = false, 
		value = 600,
		current_alarm = 0,

		getCpuCost = function( self )
            local trackerStage = 0
            if self._sim then
        	    trackerStage = self._sim:getTrackerStage( math.min( simdefs.TRACKER_MAXCOUNT, self._sim:getTracker() ))
            end
            self.cpu_cost = 1 + trackerStage

            return DEFAULT_ABILITY.getCpuCost( self )
		end,

		onSpawnAbility = function( self, sim )
			DEFAULT_ABILITY.onSpawnAbility( self, sim )	
            self._sim = sim
		end,
	},

	wings = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.WINGS.NAME,
		desc = STRINGS.PROGRAMS.WINGS.DESC,
		huddesc = STRINGS.PROGRAMS.WINGS.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.WINGS.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.WINGS.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-wings.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_wings.png",
		cpu_cost = 1,
		cooldown = 0,
		maxCooldown = 2,
		value = 500,

		executeAbility = function( self, sim )
			self:setCooldown( sim )
			local player = sim:getCurrentPlayer()
            self:useCPUs( sim )

            sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_wings_activate")

			for _, unit in pairs(sim:getAllUnits()) do
				if unit:getPlayerOwner() == player and simquery.isAgent( unit ) then
					unit:getTraits().mp = unit:getTraits().mp + 2
					local x0,y0 = unit:getLocation()
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(STRINGS.FORMATS.PLUS_AP,2),x=x0,y=y0,color={r=1,g=1,b=1,a=1}} )		

					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )

					local x1, y1 = unit:getLocation()
					sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = unit } )
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = STRINGS.PROGRAMS.WINGS.NAME, x = x1, y = y1,color={r=255/255,g=255/255,b=51/255,a=1}} )	
				end
			end
		end,
	},

	shade = util.extend( DEFAULT_ABILITY )
	{


		name = STRINGS.PROGRAMS.SHADE.NAME,
		desc = STRINGS.PROGRAMS.SHADE.DESC,
		huddesc = STRINGS.PROGRAMS.SHADE.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.SHADE.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.SHADE.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program-shade.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_shade.png",
		cpu_cost = 1,
		cooldown = 0,
		maxCooldown = 2,
		value = 500,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )
			local player = sim:getCurrentPlayer()
			if self.used then 
				for _, unit in pairs(sim:getAllUnits()) do
                    if unit:getModifiers():remove( "shade" ) then
                        sim:refreshUnitLOS( unit )
						sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
					end
				end
				self.used = false 
			end
		end,

		executeAbility = function( self, sim )
			self.used = true 
			local player = sim:getCurrentPlayer()
            self:useCPUs( sim )
			for _, unit in pairs(sim:getAllUnits()) do
				if unit:getPlayerOwner() ~= player and unit:getTraits().isGuard and unit:getTraits().hasSight then
                    unit:getModifiers():add( "LOSrange", "shade", modifiers.ADD, -3 )
                    sim:refreshUnitLOS( unit )
				end
			end
			self:setCooldown( sim )
		end,

	},

    
	leash = util.extend( DEFAULT_ABILITY ) 
	{
		name = STRINGS.PROGRAMS.LEASH.NAME,
		desc = STRINGS.PROGRAMS.LEASH.DESC,
		huddesc = STRINGS.PROGRAMS.LEASH.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.LEASH.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.LEASH.TIP_DESC,
		passive = true,

		icon = "gui/icons/programs_icons/Programs0014.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_0014.png",
		value = 500,

		canUseAbility = function( self, sim )
			return false 	
		end,

    	onDespawnAbility = function( self, sim, player )
    		DEFAULT_ABILITY.onDespawnAbility( self, sim )	    		
    		if sim:isVersion("0.17.5") then	
            	player:getTraits().controlTicks = (player:getTraits().controlTicks or 0) - 1
        	end
    	end,

		onSpawnAbility = function( self, sim, player )
			DEFAULT_ABILITY.onSpawnAbility( self, sim, player )
            player:getTraits().controlTicks = (player:getTraits().controlTicks or 0) + 1
		end,
	},

	dataBlast = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.DATA_BLAST.NAME,
		desc = STRINGS.PROGRAMS.DATA_BLAST.DESC,
		huddesc = STRINGS.PROGRAMS.DATA_BLAST.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.DATA_BLAST.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.DATA_BLAST.TIP_DESC,
 
		icon = "gui/icons/programs_icons/Programs0015.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_0015.png",
		cpu_cost = 3,
        range = 5,
        value = 400,

		acquireTargets = function( self, targets, game, sim, unit )
            local targetHandler = targets.areaCellTarget( game, self.range, sim, sim:getPC() )
            targetHandler:setUnitPredicate(
                function( u )
                    return mainframe.canBreakIce( sim, u, self )
                end )
            targetHandler:setHiliteColor( { 0.33, 0.33, 0.33, 0.33 } )
            return targetHandler
		end, 

        startTargeting = function( self, sim, unit, userUnit, targetCell )
    		MOAIFmodDesigner.playSound( "SpySociety/Actions/mainframe_datablast_select" )
        end,

        getTargetUnits = function( self, sim, cellx, celly )
            local cells = simquery.rasterCircle( sim, cellx, celly, self.range )
            local units = {}
            for i, x, y in util.xypairs( cells ) do
                local cell = sim:getCell( x, y )
                if cell then
                    for _, cellUnit in ipairs(cell.units) do
                        if sim:getCurrentPlayer():getLastKnownCell( sim, x, y ) ~= nil then
                            if mainframe.canBreakIce( sim, cellUnit, self ) then
                                table.insert( units, cellUnit )
                            end
                        end
                    end
                end
            end
            return units
        end,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			
			local player = sim:getCurrentPlayer()
            local currentProgram = player:getEquippedProgram()

    		player:equipProgram( sim, self:getID() )

			local cellx, celly = unpack(targetCell)
            sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_datablast_use" )

            local targetUnits = self:getTargetUnits( sim, cellx, celly )

           	sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = cellx, y = celly, units = targetUnits, range = self.range } )		

            local daemonUnits = {}
            for _, unit in ipairs(targetUnits) do
                -- Keep track of daemons that *Would* be invoked, so that we can invoke them only after
                -- everything has been broken.
                local daemonProgram = unit:getTraits().mainframe_program

                unit:getTraits().mainframe_program = nil
                mainframe.breakIce( sim, unit, 1 )
                unit:getTraits().mainframe_program = daemonProgram

                if daemonProgram and unit:getTraits().mainframe_ice <= 0 then
                    table.insert( daemonUnits, unit )
                end
	        end

            self:useCPUs( sim )
    		player:equipProgram( sim, currentProgram and currentProgram:getID() )

            for i, unit in ipairs( daemonUnits ) do
                mainframe.invokeDaemon( sim, unit )
            end

            if sim:isVersion("0.17.6") then
				self:setCooldown( sim ) 
			end
		end,
	},

	esp = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.ESP.NAME,
		desc = STRINGS.PROGRAMS.ESP.DESC,
		huddesc = STRINGS.PROGRAMS.ESP.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.ESP.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.ESP.TIP_DESC,

		icon = "gui/icons/programs_icons/Program0018.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_program18.png",
		cpu_cost = 3,
		credit_cost = 0,
		value = 300,

		canUseAbility = function( self, sim, abilityOwner )
			local player = sim:getCurrentPlayer()
			if player ~= abilityOwner or player == nil then
				return false
			end
			--Are there any untagged guards left? 
			local taggedguards = true
			for _, unit in pairs( sim:getAllUnits() ) do 	
				if sim:canPlayerSeeUnit( player, unit ) then
					if unit:getPlayerOwner() ~= player and unit:getTraits().isGuard and not unit:getTraits().tagged then 
						taggedguards = false 
					end
				end
			end

			if taggedguards then 
				return false, STRINGS.UI.REASON.NO_TAGGED_GUARDS
			end

			return DEFAULT_ABILITY.canUseAbility( self, sim, abilityOwner )
		end,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			local player = sim:getCurrentPlayer()
				
			local guards = {}

			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_wisp_activate" )
			-- sound for spawning the tag effect on the guards "SpySociety/Actions/mainframe_wisp_reveal"

			for _, unit in pairs( sim:getAllUnits() ) do 
				if sim:canPlayerSeeUnit( player, unit ) then
					if unit:getPlayerOwner() ~= player and unit:getTraits().isGuard and not unit:getTraits().tagged then 										
				    	unit:setTagged()				    	
				    	sim:dispatchEvent( simdefs.EV_UNIT_TAGGED, {unit = unit} )
					end
				end
			end
		
            self:useCPUs( sim )
		end,

	},	

	pwr_manager = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.PWR_MANAGER.NAME,
		desc = STRINGS.PROGRAMS.PWR_MANAGER.DESC,
		huddesc = STRINGS.PROGRAMS.PWR_MANAGER.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.PWR_MANAGER.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.PWR_MANAGER.TIP_DESC,
 
 		passive = true,

		icon = "gui/icons/programs_icons/Program0019.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_0019.png",
        value = 400,

		canUseAbility = function( self, sim )
			return false 	
		end,

		onSpawnAbility = function( self, sim, player )
			DEFAULT_ABILITY.onSpawnAbility( self, sim )	
            if not player:getTraits().extraStartingPWR then
            	player:getTraits().extraStartingPWR = 0
            end
            player:getTraits().extraStartingPWR = player:getTraits().extraStartingPWR + 4
		end,
	},

	pwr_manager_2 = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.PWR_MANAGER_2.NAME,
		desc = STRINGS.PROGRAMS.PWR_MANAGER_2.DESC,
		huddesc = STRINGS.PROGRAMS.PWR_MANAGER_2.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.PWR_MANAGER_2.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.PWR_MANAGER_2.TIP_DESC,
 		
 		passive = true,

		icon = "gui/icons/programs_icons/Program0019.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_0019.png",
        value = 550,

		canUseAbility = function( self, sim )
			return false 	
		end,

		onSpawnAbility = function( self, sim, player )
			DEFAULT_ABILITY.onSpawnAbility( self, sim )	
            if not player:getTraits().extraStartingPWR then
            	player:getTraits().extraStartingPWR = 0
            end
            player:getTraits().extraStartingPWR = player:getTraits().extraStartingPWR + 6
		end,
	},	


	taurus = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.TAURUS.NAME,
		desc = STRINGS.PROGRAMS.TAURUS.DESC,
		huddesc = STRINGS.PROGRAMS.TAURUS.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.TAURUS.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.TAURUS.TIP_DESC,

		icon = "gui/icons/programs_icons/Program0020.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_0020.png",
		cpu_cost = 2,
		break_firewalls = 0, 
		equip_program = true, 
		equipped = false,
		daemon_killer = true,   -- because it targets a daemon		
		value = 400,

		canUseAbility = function( self, sim, abilityOwner )
			
			--Are there any places the Daemon can go? 
			local possibleUnits = {}
			for _, unit in pairs( sim:getAllUnits() ) do
				if unit:getTraits().mainframe_iceMax and unit:getTraits().mainframe_iceMax > 0 and unit:getTraits().mainframe_ice and unit:getTraits().mainframe_ice > 0 and unit:getPlayerOwner() ~= sim:getPC() and not unit:getTraits().mainframe_program then
					table.insert( possibleUnits, unit )		
				end
			end

			if #possibleUnits == 0 then 
				return false, STRINGS.UI.REASON.NO_ROOM_FOR_DAEMON
			end

			return DEFAULT_ABILITY.canUseAbility( self, sim, abilityOwner )
		end,

		executeAbility = function( self, sim, targetUnit )
            self:useCPUs( sim )

            if targetUnit:getTraits().daemonHost then
                -- Its a daemon host... punt it somewhere else.
                local host = sim:getUnit( targetUnit:getTraits().daemonHost )
                sim:moveDaemon( host )

            else
			    local possibleUnits = {}
			    for _, unit in pairs( sim:getAllUnits() ) do
				    if unit:getTraits().mainframe_item and unit:getTraits().mainframe_ice > 0 and unit:getPlayerOwner() ~= sim:getPC() and not unit:getTraits().mainframe_program then
					    table.insert( possibleUnits, unit )		
				    end
			    end

			    for k=1,1,1 do 
				    if #possibleUnits > 0 then 
					    local index = sim:nextRand(1, #possibleUnits)
					    local unit = possibleUnits[ index ]
					    table.remove( possibleUnits, index )

					    local program = targetUnit:getTraits().mainframe_program 
					    targetUnit:getTraits().mainframe_program = nil

					    sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_daemonmove")
					    sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = unit, ice = unit:getTraits().mainframe_ice, delta = 0, refreshAll = true} )

					    sim:dispatchEvent(simdefs.EV_MAINFRAME_MOVE_DAEMON, {source=targetUnit, target=unit})
					
					    unit:getTraits().mainframe_program = program
					    sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_daemon_spawned" )
					    sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = unit, ice = unit:getTraits().mainframe_ice, delta = 0} )									
				    end 
			    end
            end
            if sim:isVersion("0.17.6") then
				self:setCooldown( sim ) 
			end
		end,
	},


	flare = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.FLARE.NAME,
		desc = STRINGS.PROGRAMS.FLARE.DESC,
		huddesc = STRINGS.PROGRAMS.FLARE.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.FLARE.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.FLARE.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Flare.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Flare.png",
		cpu_cost = 0,
		break_firewalls = 4, 
		equip_program = true, 
		equipped = false, 
		cooldown = 0,
		maxCooldown = 3,
		value = 450,

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)

			for _, unit in pairs( sim:getAllUnits() ) do			
		    	unit:increaseIce(sim,1)
			end
		end,			
	},

	overdrive = util.extend( DEFAULT_ABILITY ) 
	{
		name = STRINGS.PROGRAMS.OVERDRIVE.NAME,
		desc = STRINGS.PROGRAMS.OVERDRIVE.DESC,
		huddesc = STRINGS.PROGRAMS.OVERDRIVE.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.OVERDRIVE.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.OVERDRIVE.TIP_DESC,
		passive = true,

		coolDownMod = -2,
		pwrMod = 1,

		icon = "gui/icons/programs_icons/icon-program-overdrive.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_overdrive.png",
		value = 700,

		canUseAbility = function( self, sim )
			return false 	
		end,
		
	},	

	charge = util.extend( DEFAULT_ABILITY ) 
	{
		name = STRINGS.PROGRAMS.CHARGE.NAME,
		desc = STRINGS.PROGRAMS.CHARGE.DESC,
		huddesc = STRINGS.PROGRAMS.CHARGE.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.CHARGE.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.CHARGE.TIP_DESC,
		passive = true,

		coolDownMod = 1,
		pwrMod = -2,

		icon = "gui/icons/programs_icons/icon-program-charge.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_charge.png",
		value = 900,

		canUseAbility = function( self, sim )
			return false 	
		end,
	
	},	


	halt = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.HALT.NAME,
		desc = STRINGS.PROGRAMS.HALT.DESC,
		huddesc = STRINGS.PROGRAMS.HALT.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.HALT.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.HALT.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Halt.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Halt.png",

		cpu_cost = 3,
		equip_program = true, 
		equipped = false, 
		value = 500,
		
		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			if targetUnit and targetUnit:getTraits().mainframe_ice > 3 then
				return false, STRINGS.PROGRAMS.HALT.TOO_MANY_FIREWALLS
			end
			return DEFAULT_ABILITY.canUseAbility( self, sim, abilityOwner, targetUnit )
		end,

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)			
			targetUnit:processEMP( 1 )
		end,			
	},	


	root = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.ROOT.NAME,
		desc = STRINGS.PROGRAMS.ROOT.DESC,
		huddesc = STRINGS.PROGRAMS.ROOT.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.ROOT.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.ROOT.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Root.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Root.png",
		cpu_cost =  0,
		credit_cost = 0,
		cooldown = 0,
		maxCooldown = 6,
		value = 300,

		onTrigger = function( self, sim, evType, evData )
			
			if evType == simdefs.TRG_START_TURN and evData:isPC() then
				if self.cooldown > 0 then 
					evData:addCPUs( -1 )
					sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_MAINFRAME_PROGRAM_AUTO_RUN )
					sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.PROGRAMS.ROOT.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_PWRreverse_off",icon=self.icon } )
				end 
			end
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )
		end,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			local player = sim:getCurrentPlayer()			
			self:setCooldown( sim )
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_gainCPU" )
            self:useCPUs( sim )
            player:addCPUs( 6 )
		end,
	},

	fool = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.FOOL.NAME,
		desc = STRINGS.PROGRAMS.FOOL.DESC,
		huddesc = STRINGS.PROGRAMS.FOOL.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.FOOL.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.FOOL.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Jester.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Jester.png",
		cooldown = 0,
		maxCooldown = 1,
		cpu_cost = 0,
		equip_program = true, 
		equipped = false, 
		value = 100,
		
		onSpawnAbility = function( self, sim, player  )
			DEFAULT_ABILITY.onSpawnAbility( self, sim )	
			player:getTraits().daemonDurationModd = (player:getTraits().daemonDurationModd or 0) + 1
		end,

    	onDespawnAbility = function( self, sim, player )
    		DEFAULT_ABILITY.onDespawnAbility( self, sim )	
           	player:getTraits().daemonDurationModd = (player:getTraits().daemonDurationModd or 0) - 1
    	end,

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)			
			targetUnit:processEMP( 1 )

			local programList = nil
			local daemon = nil
			if sim:isVersion("0.17.5") then
				programList = sim:getIcePrograms()
				daemon = programList:getChoice( sim:nextRand( 1, programList:getTotalWeight() ))
			else
				programList = serverdefs.PROGRAM_LIST
				daemon = programList[sim:nextRand(1, #programList)]			
			end	

			sim:getNPC():addMainframeAbility( sim, daemon )			
		end,			
	},	

	rogue = util.extend( DEFAULT_ABILITY )
	{

		name = STRINGS.PROGRAMS.ROGUE.NAME,
		desc = STRINGS.PROGRAMS.ROGUE.DESC,
		huddesc = STRINGS.PROGRAMS.ROGUE.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.ROGUE.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.ROGUE.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_rogue.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_rogue.png",
		cpu_cost = 2,
		credit_cost = 0,
		cooldown = 0,
		maxCooldown = 2,		
		value = 300,
		locatedNoSafes = false,


		canUseAbility = function( self, sim, abilityOwner )
			local player = sim:getCurrentPlayer()
			if player ~= abilityOwner or player == nil then
				return false
			end

			if self.locatedNoSafes then 
				return false, STRINGS.PROGRAMS.ROGUE.WARNING
			end

			return DEFAULT_ABILITY.canUseAbility( self, sim, abilityOwner )
		end,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			local player = sim:getCurrentPlayer()
            self:useCPUs( sim )
            self:setCooldown( sim )
			local availableSafes = {}

			for _, unit in pairs( sim:getAllUnits() ) do 
				if unit:getTraits().safeUnit then 
					if unit:getPlayerOwner() ~= player and not player:hasSeen(unit) then 
						table.insert( availableSafes, unit )
					end
				end
			end

			if #availableSafes > 0 then
				local safe = availableSafes[ sim:nextRand( 1, #availableSafes ) ]	            
				sim:getPC():glimpseUnit(sim, safe:getID() )
    			sim:dispatchEvent( simdefs.EV_CAM_PAN, { safe:getLocation() } )	
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_object_camera" )
				sim:dispatchEvent( simdefs.EV_UNIT_MAINFRAME_UPDATE, {units={safe:getID()},reveal = true} )
			else 
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.PROGRAMS.ROGUE.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_wisp_activate",icon=self.icon } )
				self.locatedNoSafes = true
			end
		end,
	},

	lightning = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.LIGHTNING.NAME,
		desc = STRINGS.PROGRAMS.LIGHTNING.DESC,
		huddesc = STRINGS.PROGRAMS.LIGHTNING.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.LIGHTNING.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.LIGHTNING.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_lightning.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_lightning.png",
		cpu_cost = 8,		
		equip_program = true, 
		equipped = false, 
		value = 800,	
		targetGuard = true,	

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			if targetUnit then
				if not targetUnit:getTraits().isGuard then 				
					return false
				end	

				if not targetUnit:getTraits().heartMonitor then 				
					return false
				end	

				if not targetUnit:getTraits().tagged then
					return false, STRINGS.UI.REASON.UNIT_NOT_TAGGED 
				end
				if targetUnit:getTraits().mainframe_ice and targetUnit:getTraits().mainframe_ice > 0 then 				
					return false
				end
			end

			local player = sim:getCurrentPlayer()
			if player == nil or player ~= abilityOwner then
				return false
			end

			if player:getCpus() < self:getCpuCost() then 
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if sim:getMainframeLockout() then 
				return false, STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN
			end 

			return true	
		end,

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)
			
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_lightning_strike" )			

			targetUnit:setKO( sim, 2, "emp" )
			targetUnit:setTagged("dissable")
		end,			
	},	

	dynamo = util.extend( DEFAULT_ABILITY ) 
	{
		name = STRINGS.PROGRAMS.DYNAMO.NAME,
		desc = STRINGS.PROGRAMS.DYNAMO.DESC,
		shortdesc = STRINGS.PROGRAMS.DYNAMO.SHORT_DESC,
		huddesc = STRINGS.PROGRAMS.DYNAMO.HUD_DESC,
		icon = "gui/icons/programs_icons/ProgramDynamo.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Dynamo.png",
		credit_cost = 0, 
		value = 1000,

		passive = true,
		
		executeAbility = function( self, sim )
			local player = sim:getCurrentPlayer()			
			if not player:isNPC() and sim._trackerStage > 1 then
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_MAINFRAME_PROGRAM_AUTO_RUN )
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.PROGRAMS.DYNAMO.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
				player:addCPUs( 2 )
			end
		end,

		canUseAbility = function( self, sim )
			return false 	
		end,

		onSpawnAbility = function( self, sim )
			DEFAULT_ABILITY.onSpawnAbility( self, sim )		
		end,


		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			if evType == simdefs.TRG_START_TURN then
				self:executeAbility(sim)	
			end
		end,
	},

	feast = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.FEAST.NAME,
		desc = STRINGS.PROGRAMS.FEAST.DESC,
		huddesc = STRINGS.PROGRAMS.FEAST.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.FEAST.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.FEAST.TIP_DESC,

		icon = "gui/icons/programs_icons/ProgramFeast.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Feast.png",
		cpu_cost = 0,
		break_firewalls = 4, 
		equip_program = true, 
		equipped = false, 
		cooldown = 0,
		maxCooldown = 3,
		value = 600,

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)

			for i=1,2 do
				
				local programList = nil
				local daemon = nil
				if sim:isVersion("0.17.5") then
					programList = sim:getIcePrograms()
					daemon = programList:getChoice( sim:nextRand( 1, programList:getTotalWeight() ))
				else
					programList = serverdefs.PROGRAM_LIST
					daemon = programList[sim:nextRand(1, #programList)]			
				end	

				sim:getNPC():addMainframeAbility( sim, daemon )
			end
		end,			
	},		

	mercenary = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.MERCENARY.NAME,
		desc = STRINGS.PROGRAMS.MERCENARY.DESC,
		huddesc = STRINGS.PROGRAMS.MERCENARY.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.MERCENARY.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.MERCENARY.TIP_DESC,

		icon = "gui/icons/programs_icons/ProgramMercenary.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_mercenary.png",
		cpu_cost = 0,
		break_firewalls = 2, 
		equip_program = true, 
		--noexecute = true, 
		equipped = false, 
		value = 600,
		current_alarm = 0,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )
			if evType == simdefs.TRG_ALARM_STATE_CHANGE then				
				self.cpu_cost = 0
			end
		end,

		onSpawnAbility = function( self, sim )
			DEFAULT_ABILITY.onSpawnAbility( self, sim )
            self._sim = sim
            sim:addTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
		end,

		onDespawnAbility = function( self, sim, unit )
			DEFAULT_ABILITY.onDespawnAbility( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
		end,

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)
			self.cpu_cost = self.cpu_cost + 2
		end,
	},


	aces = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.PROGRAMS.ACES.NAME,
		desc = STRINGS.PROGRAMS.ACES.DESC,
		huddesc = STRINGS.PROGRAMS.ACES.HUD_DESC,
		shortdesc = STRINGS.PROGRAMS.ACES.SHORT_DESC,
		tipdesc = STRINGS.PROGRAMS.ACES.TIP_DESC,

		icon = "gui/icons/programs_icons/ProgramAces.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Aces.png",
		cpu_cost = 2,
		--noexecute = true, 
		value = 600,
		current_alarm = 0,
		cooldown = 0,
		maxCooldown = 3,		

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)	
			local daemon = "acesDaemon"
			sim:getNPC():addMainframeAbility( sim, daemon )	
		end,
	},	
}
 
return mainframe_abilities
