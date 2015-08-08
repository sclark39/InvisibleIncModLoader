----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local unitdefs = include( "sim/unitdefs" )
local simunit = include( "sim/simunit" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )

-----------------------------------------------------
-- Grenade item

local simgrenade = { ClassType = "simgrenade" }

function simgrenade:throw(throwingUnit, targetCell)
	local sim = self:getSim()
	local player = throwingUnit:getPlayerOwner()
	local x0, y0 = throwingUnit:getLocation()

    assert( player )
	self:setPlayerOwner(player)
	
	sim:dispatchEvent( simdefs.EV_UNIT_THROWN, { unit = self, x=targetCell.x, y=targetCell.y } )

	if x0 ~= targetCell.x or y0 ~= targetCell.y then
		sim:warpUnit(self, targetCell)
	end

    self:getTraits().throwingUnit = throwingUnit:getID()
    self:getTraits().cooldown = self:getTraits().cooldownMax

    self:activate()

    if self:getTraits().keepPathing == false and throwingUnit:getBrain() then
    	throwingUnit:useMP(throwingUnit:getMP(), sim)
    end
    
	sim:processReactions()
end

function simgrenade:explode()
    assert( self:getTraits().deployed )

    -- A deployed grenade can explode. This will deactivate AND despawn it.
    local sim = self:getSim()
    local x, y = self:getLocation()
    local cells = self:getExplodeCells()
	sim:dispatchEvent(simdefs.EV_GRENADE_EXPLODE, { unit = self, cells = cells } )
	if self.onExplode then
        self:onExplode(cells )
    end

    self:deactivate()
    local unitID = self:getID()
 	sim:warpUnit(self, nil)
	sim:despawnUnit( self )
	--make sure all players glimpse to remove the ghosts
	for i,player in ipairs(sim:getPlayers()) do			
		player:glimpseUnit(sim, unitID)
	end
end

function simgrenade:getExplodeCells()
    local x0, y0 = self:getLocation()
	local currentCell = self:getSim():getCell( x0, y0 )
	local cells = {currentCell}
	if self:getTraits().range then
		local fillCells = simquery.fillCircle( self._sim, x0, y0, self:getTraits().range, 0)

		for i, cell in ipairs(fillCells) do
			if cell ~= currentCell then
				local raycastX, raycastY = self._sim:getLOS():raycast(x0, y0, cell.x, cell.y)
				if raycastX == cell.x and raycastY == cell.y then
					table.insert(cells, cell)
				end
			end
		end
	end
    return cells
end

function simgrenade:activate()
    assert( not self:getTraits().deployed )

    local sim = self:getSim()

	if self:getTraits().camera then
		self:getTraits().hasSight = true
		sim:getLOS():registerSeer(self:getID() )
		sim:refreshUnitLOS(self)
	end

	if self:getTraits().holoProjector then
		self:getTraits().hologram=true
		self:getSounds().spot = self:getSounds().activeSpot
		sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_SPOTSOUND, { unit = self,  stop = false } )
	end

	if self:getTraits().cryBaby or self:getTraits().transporterBeacon then
		self:getTraits().mainframe_item = true
		self:getTraits().mainframe_status = "on"
	end

    self:getTraits().deployed = true
    local cells = self:getExplodeCells()
	sim:dispatchEvent( simdefs.EV_UNIT_ACTIVATE, { unit = self, cells=cells } )

    if self:getTraits().explodes == 0 then
        self:explode()
    else
        if self:getTraits().explodes then
            self:getTraits().timer = self:getTraits().explodes
        	sim:addTrigger( simdefs.TRG_START_TURN, self ) -- Explodes later
        end
        sim:addTrigger( simdefs.TRG_UNIT_PICKEDUP, self )
        sim:triggerEvent( simdefs.TRG_UNIT_DEPLOYED, { unit = self })
    end
end

function simgrenade:deactivate()
    assert( self:getTraits().deployed )

    -- This defuses (deactivates) a deployed grenade.
	local sim = self:getSim()
	local x0,y0 = self:getLocation()

	if self:getTraits().camera then
		self:getTraits().hasSight = false	
		sim:refreshUnitLOS(self)
		sim:getLOS():unregisterSeer(self:getID() )
	end

	if self:getTraits().cryBaby or self:getTraits().transporterBeacon then
		self:getTraits().mainframe_item = nil
		self:getTraits().mainframe_status = nil
	end

	if self:getTraits().holoProjector then
		sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_SPOTSOUND, { unit = self, stop = true } )
		self:getSounds().spot = nil
		self:getTraits().hologram=false
	end

    self:getTraits().deployed = nil

    if self:getTraits().explodes == nil then
        sim:removeTrigger( simdefs.TRG_UNIT_PICKEDUP, self )
    elseif self:getTraits().explodes > 0 then
        sim:removeTrigger( simdefs.TRG_START_TURN, self )
        sim:removeTrigger( simdefs.TRG_UNIT_PICKEDUP, self )
    end

	sim:dispatchEvent( simdefs.EV_UNIT_DEACTIVATE, { unit = self } )
end

function simgrenade:onWarp( sim, oldcell, cell)
	if not oldcell and cell then
		sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
	elseif not cell and oldcell then
		sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
	end
end

function simgrenade:scanCell(sim, cell)
	local player = self:getPlayerOwner()
	local x0,y0 = self:getLocation()

	for i, cellUnit in ipairs( cell.units ) do
        if player:isNPC() then
		    if simquery.isEnemyAgent(player, cellUnit) then
                local throwingUnit = sim:getUnit( self:getTraits().throwingUnit )
			    if throwingUnit then
			        throwingUnit:getBrain():getSenses():addInterest( cell.x, cell.y, simdefs.SENSE_SIGHT, simdefs.REASON_SCANNED, cellUnit)
		        else
				    sim:triggerEvent( simdefs.TRG_NEW_INTEREST, { x = x0, y = y0, range = simdefs.SOUND_RANGE_3, interest = { x= cell.x, y = cell.y, reason=simdefs.REASON_SCANNED} })
			    end
		    end

        else
		    if (cellUnit:getTraits().mainframe_item or cellUnit:getTraits().mainframe_console) and not cellUnit:getTraits().scanned then
			    cellUnit:getTraits().scanned = true
			    sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = cellUnit, reveal = true } )
		    end
        end
	end
end

function simgrenade:onTrigger( sim, evType, evData )
	if evType == simdefs.TRG_UNIT_PICKEDUP and evData.item == self then
		self:deactivate()

	elseif evType == simdefs.TRG_UNIT_WARP and evData.unit ~= self then
		local x0,y0 = self:getLocation()

		if evData.to_cell == sim:getCell(self:getLocation()) or evData.from_cell == sim:getCell(self:getLocation()) then
			if evData.unit:getTraits().isAgent then
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )
			end
		end
	elseif evType == simdefs.TRG_START_TURN then
		if evData:isNPC() then
            self:getTraits().timer = self:getTraits().timer - 1
            if self:getTraits().timer <= 0 then
                self:explode()
            end
		end
	end
end

function simgrenade:toggle( sim )

	if self:getTraits().cryBaby then
		local x0, y0 = self:getLocation()		    
		sim:emitSound( { path = "SpySociety/Actions/agent_discovered", range = self:getTraits().range }, x0, y0, self )
  		sim:processReactions(self)		
  		
		self:getTraits().mainframe_item = nil
		self:getTraits().mainframe_status = nil  		
	end

	if self:getTraits().transporterBeacon then
		sim:getPC():addCPUs(- self:getTraits().PWRuse)
		local agent = nil
		for i,unit in pairs(sim:getAllUnits())do
			if unit:countAugments( "augment_particle_envelope" ) > 0 then
				agent = unit
			end
		end
		if agent then
			local cell = sim:getCell(self:getLocation())
			sim:dispatchEvent( simdefs.EV_UNIT_APPEARED, { unitID = agent:getID(), noSightingFx=true } )
			sim:dispatchEvent( simdefs.EV_TELEPORT, { units={agent}, warpOut =true } )
			sim:warpUnit( agent, cell )
			sim:dispatchEvent( simdefs.EV_UNIT_APPEARED, { unitID = agent:getID(), noSightingFx=true } )
			sim:dispatchEvent( simdefs.EV_TELEPORT, { units={agent}, warpOut =false } )
			sim:processReactions( agent )
		end
		self:getTraits().cooldown = self:getTraits().coolDownUse
		self:getTraits().mainframe_item = nil
		self:getTraits().mainframe_status = nil  	

	end	
end
-----------------------------------------------------
-- Scan grenade 

local scan_grenade = { ClassType = "scan_grenade" }

function scan_grenade:onExplode( cells )
    local sim, player = self:getSim(), self:getPlayerOwner()

	for i, cell in ipairs(cells) do
		for i, cellUnit in ipairs( cell.units ) do
			self:scanCell(sim, cell)
		end
	end
end

-----------------------------------------------------
-- Stun grenade 

local stun_grenade = { ClassType = "stun_grenade" }

function stun_grenade:onExplode( cells )
    local sim, player = self:getSim(), self:getPlayerOwner()

	sim:startTrackerQueue(true)				
	sim:startDaemonQueue()			
    sim:dispatchEvent( simdefs.EV_KO_GROUP, true )

	for i, cell in ipairs(cells) do
		for i, cellUnit in ipairs( cell.units ) do
			if self:getTraits().baseDamage and simquery.isEnemyAgent( player, cellUnit) and not cellUnit:getTraits().isDrone then
				if self:getTraits().canSleep then
					local damage = self:getTraits().baseDamage

					if sim:isVersion("0.17.5") then
						damage = cellUnit:processKOresist( damage )
				    end		

					cellUnit:setKO(sim, damage)
				else
					sim:damageUnit(cellUnit, self:getTraits().baseDamage)
				end
			end
		end
	end

    sim:dispatchEvent( simdefs.EV_KO_GROUP, false )
	sim:startTrackerQueue(false)				
	sim:processDaemonQueue()			
end

-----------------------------------------------------
-- Stun grenade 

local smoke_grenade = { ClassType = "smoke_grenade" }

function smoke_grenade:onExplode( cells )
    assert( self:getTraits().on_spawn )
    local sim = self:getSim()
	local newUnit = simfactory.createUnit( unitdefs.lookupTemplate( self:getTraits().on_spawn ), sim )
	sim:spawnUnit( newUnit )
	sim:warpUnit( newUnit, sim:getCell( self:getLocation() ) )
end
    

-----------------------------------------------------
-- Interface functions

local function createGrenade( unitData, sim )
	return simunit.createUnit( unitData, sim, simgrenade )
end

local function createScanGrenade( unitData, sim )
	return simunit.createUnit( unitData, sim, simgrenade, scan_grenade )
end

local function createStunGrenade( unitData, sim )
	return simunit.createUnit( unitData, sim, simgrenade, stun_grenade )
end

local function createSmokeGrenade( unitData, sim )
	return simunit.createUnit( unitData, sim, simgrenade, smoke_grenade )
end

simfactory.register( createGrenade )
simfactory.register( createScanGrenade )
simfactory.register( createStunGrenade )
simfactory.register( createSmokeGrenade )

return
{
	createGrenade = createGrenade,
}


