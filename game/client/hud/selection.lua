----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local cdefs = include( "client_defs" )
local mui_util = include( "mui/mui_util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local serverdefs = include( "modules/serverdefs" )

----------------------------------------------------------------
-- Local functions

----------------------------------------------------------------
-- Selection state handling

local selection = class()

function selection:init( hud )
    self.hud, self.game = hud, hud._game
    self.selectedUnit, self.lastSelectedUnitID = nil, nil
end

function selection:canSelect( unit )
	local localPlayer = self.game:getLocalPlayer()

	if localPlayer and unit:getUnitData().profile_icon == nil and unit:getUnitData().profile_anim == nil then
		return false
	end

	if localPlayer and ((unit:getTraits().selectpriority or 1) <= 0) then
		return false
	end

    if localPlayer and (unit:getPlayerOwner() ~= localPlayer or not simquery.isAgent( unit )) then
        return false
    end
	
	if unit:getLocation() == nil then
		return false
	end

	return unit:isGhost() or localPlayer == nil or
            localPlayer == unit:getPlayerOwner() or self.game.simCore:canPlayerSeeUnit( localPlayer, unit )
end

function selection:selectUnitAtCell( cellx, celly )
    if not cellx or not celly then
        return
    end

	local selectedUnit = nil
    local cell = nil
	local localPlayer = self.game:getLocalPlayer()
	if localPlayer == nil then
		cell = self.game.simCore:getCell( cellx, celly )
	else
		cell = localPlayer:getCell( cellx, celly )
	end

	if cell then
		local idx = util.indexOf( cell.units, self.selectedUnit )

		if idx == nil then
			-- Select the highest priority unit.
			local candidates = {}
			for _,unit in ipairs(cell.units) do
				if self:canSelect( unit ) then
					table.insert( candidates, unit )
				end
			end
			table.sort( candidates, function( lu, ru ) return (lu:getTraits().selectpriority or 1) > (ru:getTraits().selectpriority or 1) end )
			selectedUnit = candidates[1]
		else
			-- Each selection attempt cycles through the selectable units in the cell.
			for i = 1,#cell.units do
					
				idx = (idx or 0) - 1
				if idx <= 0 then
					idx = #cell.units
				end

				local unit = cell.units[idx]
				if self:canSelect( unit ) then						
					selectedUnit = unit
					break
				end
			end			
		end
	end

	if selectedUnit then
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_SELECT_UNIT )
		self:selectUnit( selectedUnit )		
	end
end

function selection:selectInitialUnit() 
	local sim = self.game.simCore
	-- Selects the first valid (non-KO) unit of the local player, or nil otherwise.
	local selectUnit = sim:getUnit( self.lastSelectedUnitID )
	if selectUnit and self:canSelect( selectUnit ) and not selectUnit:isKO() then
        return selectUnit -- Last selected unit still OK.
	end

	if self.game:getLocalPlayer() and not sim:getTags().isTutorial then
        -- Find first available selectable unit for the local player.
		local units = self.game:getLocalPlayer():getUnits()
		for i, unit in ipairs(units) do
			if self:canSelect( unit ) and not unit:isKO() then
				selectUnit = unit
				break
			end
		end
		
		self:selectUnit( selectUnit )
        if selectUnit then
		    MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_SELECT_UNIT )
            self.game:getCamera():fitOnscreen( self.game:cellToWorld( selectUnit:getLocation() ))
        end

        return selectUnit
	end
end

function selection:selectNextUnit( )
	if not self.game:getLocalPlayer() then
        return
    end

	local units = self.game:getLocalPlayer():getUnits()
	if #units > 0 then
		local idx = util.indexOf( units, self:getSelectedUnit() ) or 0
		local count = 0

		repeat
			idx = (idx % #units) + 1
			count = count + 1
			local unit = units[idx]
			if unit:getLocation() and simquery.isAgent( unit ) then
				self:selectUnit( unit )
				MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_SELECT_UNIT )
				self.game:getCamera():fitOnscreen( self.game:cellToWorld( unit:getLocation()) )
				break
			end
		until count >= #units
	end
end

function selection:selectUnit( selectedUnit )
    if selectedUnit == nil or self:canSelect( selectedUnit ) then
	    local prevUnit = self.selectedUnit
		if prevUnit ~= selectedUnit then
	        self.lastSelectedUnitID = selectedUnit and selectedUnit:getID()
	        self.selectedUnit = selectedUnit
	        self.hud:onSelectUnit( prevUnit, self.selectedUnit )
	    end
	end
end

function selection:getSelectedUnit()
    return self.selectedUnit
end

return selection


