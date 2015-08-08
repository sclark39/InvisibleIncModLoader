----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simdefs = include( "sim/simdefs" )
local unitdefs = include( "sim/unitdefs" )

----------------------------------------------------------------
-- Local functions

local function createItem( name, template )
	return util.extend(
		{
			apply = function( unitData, params )
				table.insert( unitData.children, util.extend( template )( params and util.tcopy( params )))
			end,
		} )
end

local upgrade_templates =
{
	augmentUpgradeSlot = {
		apply = function( unitData, params )
			unitData.traits.augmentMaxSize = unitData.traits.augmentMaxSize + 1
		end,		
	}
}

-- Auto-create upgrades for tools
for k, unitData in pairs(unitdefs.tool_templates) do
	upgrade_templates[ k ] = createItem( unitData.name, unitData )( nil )
	unitData.upgradeName = k
end

local function applyUpgrade( upgradeName, unitData, upgradeParams )
	local upgradeDef = upgrade_templates[ upgradeName ]

	if upgradeDef == nil then
		log:write("Missing upgrade '%s' when applying to unitData id=%s, name=%s", tostring(upgradeName), tostring(unitData.id), unitData.name)
	elseif upgradeDef.apply then
		upgradeDef.apply( unitData, upgradeParams )
	end
end

return
{
	upgrade_templates = upgrade_templates,
	applyUpgrade = applyUpgrade,
}

