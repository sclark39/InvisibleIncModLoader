---------------------------------------------------------------------
-- Invisible Inc. official DLC.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simunit = include( "sim/simunit" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )

-----------------------------------------------------
-- Local functions

local item_disguise = { ClassType = "item_disguise" }

function item_disguise:onSpawn( sim )
    print( "SPAWNED", self:getName() )
    sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
    sim:addTrigger( simdefs.TRG_START_TURN, self )
    
end

function item_disguise:onDespawn( sim )
    sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
    sim:removeTrigger( simdefs.TRG_START_TURN, self )
end


function item_disguise:onTrigger( sim, evType, evData )

    if evType == simdefs.TRG_UNIT_WARP then
	    local unitOwner = self:getUnitOwner()

	    if unitOwner and unitOwner:getTraits().disguiseOn then

	    	local enemyUnit, range = sim:getQuery().getNearestEnemy( unitOwner )
	       
		 	if range <=1.5 then
		 		unitOwner:setDisguise(false)	
		 		unitOwner:interruptMove( sim ) 		
		 	end

		end
	elseif evType == simdefs.TRG_START_TURN then
		local owner = self:getUnitOwner()
		local player = owner:getPlayerOwner()
		if player and sim:getCurrentPlayer() == player and owner:getTraits().disguiseOn  then
			local x,y owner:getLocation()
			if player:getCpus() >= self:getTraits().CPUperTurn then
				player:addCPUs( -self:getTraits().CPUperTurn, sim, x,y )
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=util.sformat( self:getTraits().warning ,self:getTraits().CPUperTurn), color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=nil } )
			else
				owner:setDisguise(false)
			end
		end
	end
end

-----------------------------------------------------
-- Interface functions


local function createItem( unitData, sim )
	return simunit.createUnit( unitData, sim, item_disguise )
end

simfactory.register( createItem )

return {
	createItem = createItem,
}
