----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )


-----------------------------------------------------
-- Local functions

local function canTargetUnit( sim, targetUnit, equippedProgram )
	local player = sim:getCurrentPlayer()
    if player == nil then
        return false
    end
    if sim:getMainframeLockout() then
        return false, STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN
    end

    if equippedProgram == nil then
	    equippedProgram = player:getEquippedProgram()
    end

	if equippedProgram == nil then 
		return false, STRINGS.UI.REASON.NO_PROGRAM
	end 

	if sim:getCurrentPlayer() == nil or equippedProgram:getCpuCost() > player:getCpus() then
		return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
	end

    local ok, result = equippedProgram:canUseAbility( sim, player, targetUnit )
    if not ok then
		return ok, result	
	end

	return true
end

local function canBreakIce( sim, targetUnit, equippedProgram )
	local player = sim:getCurrentPlayer()
    if player == nil then
        return false
    end

    if sim:getMainframeLockout() then
        return false, STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN
    end

    if (targetUnit:getTraits().mainframe_ice or 0) <= 0 then
        return false
    end

    if targetUnit:getTraits().isDrone and targetUnit:isKO() then
        return false -- KO'd drones actually may have ice, so the previous conditional is not sufficient :(
    end

    if targetUnit:getTraits().mainframe_status == "off" then
        -- Curiously enough, booting cameras are hackable!
        if not (targetUnit:getTraits().mainframe_camera and targetUnit:getTraits().mainframe_booting) then
            return false
        end
    end

    if equippedProgram == nil then
	    equippedProgram = player:getEquippedProgram()
    end

	if equippedProgram == nil then 
		return false, STRINGS.UI.REASON.NO_PROGRAM
	end 

	if sim:getCurrentPlayer() == nil or equippedProgram:getCpuCost() > player:getCpus() then
		return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
	end

    local ok, result = equippedProgram:canUseAbility( sim, player, targetUnit )
    if not ok then
		return result	
	end

	if equippedProgram.sniffer then 
		if not sim:getHideDaemons() and not targetUnit:getTraits().mainframe_program then 
			return false, STRINGS.UI.REASON.NO_DAEMON
		elseif targetUnit:getTraits().daemon_sniffed then 
			return false, STRINGS.UI.REASON.DAEMON_REVEALED
		end
	end

	if equippedProgram.daemon_killer then 
		if not sim:getHideDaemons() and not targetUnit:getTraits().mainframe_program then 
			return false, STRINGS.UI.REASON.NO_DAEMON
		end
	end

	if equippedProgram.wrench then 
		if targetUnit:getTraits().mainframe_ice ~= equippedProgram.break_firewalls then 

			return false, util.sformat( STRINGS.UI.REASON.WRONG_WRENCH, equippedProgram.break_firewalls )
		end 
	end

	-- May need to improve this linear search, if canBreakIce is called a lot.
	local x0, y0 = targetUnit:getLocation()
	for unitID, unit in pairs( sim:getAllUnits() ) do
		local range = unit:getTraits().mainframe_suppress_range
		if range and not unit:isKO() and unit:getLocation() and unit ~= targetUnit then
			local distSqr = mathutil.distSqr2d( x0, y0, unit:getLocation() )
			if distSqr <= range * range then
				return false, "nulldrone"
			end
		end
	end

	return true
end

local AUGMENT_TXT_COLOR = {r=255/255,g=255/255,b=51/255,a=1 }

local function runBreakIceAugments( sim, sourceUnit )
	local x2, y2 = sourceUnit:getLocation()
	if sourceUnit:countAugments( "augment_net_downlink" ) > 0 and not sourceUnit:isKO() then
        local MAX_DOWNLINK_AP, BONUS_DOWNLINK_AP = 6, 2
        local gainMp = math.min( BONUS_DOWNLINK_AP, MAX_DOWNLINK_AP - (sourceUnit:getTraits().netDownlinkMp or 0))
        if gainMp > 0 then
        	sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = sourceUnit  } )
		    sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = STRINGS.ITEMS.AUGMENTS.NET_DOWNLINK, x = x2, y = y2, color=AUGMENT_TXT_COLOR} )
		    sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = sourceUnit } )
            sourceUnit:getTraits().netDownlinkMp = (sourceUnit:getTraits().netDownlinkMp or 0) + gainMp
		    sourceUnit:getTraits().mp = sourceUnit:getTraits().mp + gainMp
        end
	end 

	local MAX_PRISM_BONUS = 2
	local prismBonus = sourceUnit:getTraits().prismBonus or 0
	if sourceUnit:countAugments( "augment_prism_2" ) > 0 and not sourceUnit:isKO() and prismBonus < MAX_PRISM_BONUS then
		sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = STRINGS.ITEMS.AUGMENTS.PRISM_2, x = x2, y = y2 ,color=AUGMENT_TXT_COLOR} )
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = sourceUnit } )
		sourceUnit:getPlayerOwner():addCPUs( 1, sim,x2,y2)
        sourceUnit:getTraits().prismBonus = ( sourceUnit:getTraits().prismBonus or 0 )+ 1
	end
end

local function removeParasite(player,hostUnit)

	for i,ability in ipairs(player:getAbilities()) do
		if ability.parasite_hosts then
            array.removeElement( ability.parasite_hosts, hostUnit:getID() )
		end
	end
	hostUnit:getTraits().parasite = nil
end

local function revokeDaemonHost( sim, host )
    local device = sim:getUnit( host:getTraits().mainframe_device )
	sim:dispatchEvent(simdefs.EV_MAINFRAME_MOVE_DAEMON, {source=device, target=host})

    device:getTraits().daemonHost = nil
    device:getTraits().mainframe_program = nil
    host:getTraits().mainframe_device = nil

	sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = device } )	
end

-- Invokes an installed daemon on a mainframe device.
-- The daemon is removed from the device, and if it is a daemon-host, it is moved to another device.
local function invokeDaemon( sim, unit )
	if unit:getTraits().mainframe_program then
		sim:getNPC():addMainframeAbility(sim, unit:getTraits().mainframe_program, unit )

		if unit:getTraits().daemonHost then
    		--if possessed by a daemon-host, it jumps to a new system
            local host = sim:getUnit( unit:getTraits().daemonHost )
   			sim:moveDaemon( host )
        else
            -- Otherwise, simply remove the installed program.
            unit:getTraits().mainframe_program = nil
		end	
	end
end

local function canRevertIce( sim, unit )
    if not unit:isPC() then
        return false
    end

    if not unit:getTraits().mainframe_item or not unit:getTraits().mainframe_iceMax then
        return false
    end

    if unit:getTraits().mainframe_no_recapture then
        return false
    end

    if unit:getTraits().mainframe_status == "off" then
        return false -- Cannot reboot devices that are disabled.
    end

    return true
end

local function revertIce( sim, unit )
    if not canRevertIce( sim, unit ) then
        return
    end

	unit:processEMP(1, true,true)

    unit:getTraits().mainframe_status_old = "active" -- So that the device will re-activate after booting.
	unit:getTraits().mainframe_ice = 1
	
	sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = unit, ice = unit:getTraits().mainframe_ice, delta = 1} )

	local x1,y1 = unit:getLocation()

	-- dont forget to account for Barrier Guards..
	if unit:getTraits().tracker_alert == false then
		unit:getTraits().tracker_alert = true
	end
		
	if unit:getTraits().showOutline then 
		sim._showOutline = false
		sim:dispatchEvent( simdefs.EV_WALL_REFRESH )
	end

	-- for items that can be deactivated when controlled.
	if not unit:getTraits().noTakeover then
		unit:takeControl( sim:getNPC() )
	end

	local player = sim:getPC()

	if unit:getTraits().powerGrid and unit:getTraits().laser_gen then
		for i,u in ipairs( player:getUnits() ) do 
			if u:getTraits().powerGrid then 
				if u:getTraits().powerGrid == unit:getTraits().powerGrid then 
					u:takeControl( sim:getNPC() )
					player:glimpseUnit( sim, u:getID() )
				end 
			end 
		end 
	end 

	sim:getPC():glimpseUnit( sim, unit:getID() )
	sim:dispatchEvent( simdefs.EV_UNIT_MAINFRAME_UPDATE, {units={unit:getID()}} )
	sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.RECAPTURED,x=x1,y=y1,color={r=1,g=0,b=0,a=1},alwaysShow=true} )

end

local function breakIce( sim, unit, cost )
    local currentPlayer = sim:getPC()

	sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = unit, ice = unit:getTraits().mainframe_ice, delta = -cost } )

	unit:getTraits().mainframe_ice = unit:getTraits().mainframe_ice - cost

	if cost then 
		sim:triggerEvent( simdefs.TRG_ICE_BROKEN, { unit = unit } )
	end 

	if unit:getTraits().mainframe_ice > 0 then
		sim:getCurrentPlayer():glimpseUnit( sim, unit:getID() )
		sim:dispatchEvent( simdefs.EV_UNIT_MAINFRAME_UPDATE, {units={unit:getID()}} )

	else

		if sim._resultTable.devices[unit:getID()] then
			sim._resultTable.devices[unit:getID()].hacked = true
		end

		for _, unit in pairs( currentPlayer:getUnits() ) do
			-- Check augments and perform their behaviours -- which better not modify the currentPlayer units list!
			runBreakIceAugments( sim, unit )
		end

		if unit:getTraits().shieldArmor then
			unit:getTraits().shields = 0
			sim:dispatchEvent( simdefs.EV_UNIT_HIT_SHIELD,  {unit = unit, shield = unit:getTraits().shields} )
			sim:getCurrentPlayer():glimpseUnit( sim, unit:getID() )
		end

		sim:getStats():incStat( "security_hacked" )

		if unit:getTraits().tracker_alert == true then
			unit:getTraits().tracker_alert = false
		end

		if unit:getTraits().revealUnits then 
			local unitlist = {}
			sim:forEachUnit(
				function ( u )
					if u:getTraits()[ unit:getTraits().revealUnits ] ~= nil then
						table.insert(unitlist,u:getID())		
						currentPlayer:glimpseUnit( sim, u:getID() )				
					end
				end )

			sim:dispatchEvent( simdefs.EV_UNIT_MAINFRAME_UPDATE, {units=unitlist,reveal = true} )
		end
		
		if unit:getTraits().showOutline then 
			sim._showOutline = true
			sim:dispatchEvent( simdefs.EV_WALL_REFRESH )

    		local x0,y0 = unit:getLocation()
    		local color = {r=1,g=1,b=41/255,a=1}
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.FACILITY_REVEALED,x=x0,y=y0,color=color,alwaysShow=true} )

		end
		
		if unit:getTraits().revealDaemons then 
				sim:forEachUnit(
				function ( u )
					if u:getTraits().mainframe_program ~= nil then
						u:getTraits().daemon_sniffed = true 
					end
				end )
		end

		-- for items that can be deactivated when controlled.
		if not unit:getTraits().noTakeover then
			unit:takeControl( currentPlayer )
		end

		-- for items infested with parasite
		if unit:getTraits().parasite then
			removeParasite(currentPlayer,unit)
		end

        invokeDaemon( sim, unit )
	end
end

local function canHaveDaemon( unit )
    local traits = unit:getTraits()
    return traits.mainframe_item and not traits.mainframe_no_daemon_spawn
end

-----------------------------------------------------
-- Interface functions

local function init( sim )
    local daemonList = sim:getIcePrograms()
    if daemonList:getCount() == 0 then
        return
    end

    local daemonCounts = simdefs.DAEMON_TABLE[ sim:getParams().difficultyOptions.daemonQuantity ]
    if sim:isVersion("0.17.5") then
    	daemonCounts = simdefs.DAEMON_TABLE_17_5[ sim:getParams().difficultyOptions.daemonQuantity ]
    end
    local totalDaemons = daemonCounts[ sim:getParams().difficulty ] or daemonCounts[ #daemonCounts ]

    -- Initialize ice.
    local wt = util.weighted_list()
    for unitID, unit in pairs( sim:getAllUnits() ) do
        if unit:getTraits().mainframe_program == nil and canHaveDaemon( unit ) then
            wt:addChoice( unit, 1 )
        end
    end

    --log:write( "Installing %d daemons for %d candidates", totalDaemons, wt:getCount() )

    while totalDaemons > 0 and wt:getTotalWeight() > 0 do
        -- Pick a candidate, then pick a daemon.
        local unit = wt:removeChoice( sim:nextRand( 1, wt:getTotalWeight() ) )
        unit:getTraits().mainframe_program = daemonList:getChoice( sim:nextRand( 1, daemonList:getTotalWeight() ))
        totalDaemons = totalDaemons - 1
        --log:write( "\t%d [%s] installed '%s'", unit:getID(), unit:getName(), unit:getTraits().mainframe_program )
    end
end

return
{
	init = init,
	canTargetUnit = canTargetUnit,
	canBreakIce = canBreakIce,
	breakIce = breakIce,
    canRevertIce = canRevertIce,
	revertIce = revertIce,
    canHaveDaemon = canHaveDaemon,
    invokeDaemon = invokeDaemon,
	removeParasite = removeParasite,
    revokeDaemonHost = revokeDaemonHost,
}
