----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )

local npc_templates = include("sim/unitdefs/guarddefs")
local agent_templates = include("sim/unitdefs/agentdefs")
local tool_templates = include("sim/unitdefs/itemdefs")
local prop_templates = include("sim/unitdefs/propdefs")
local quest_templates = include("sim/unitdefs/questdefs")
-----------------------------------------------------------------
--

local function lookupTemplate( name )
	return tool_templates[ name ] or prop_templates[ name ] or agent_templates[ name ] or npc_templates[ name ] or quest_templates[ name ]
end

-------------------------------------------------------------------------------
-- This function is responsible for generating a valid unit data from a unit
-- definition, which references a base unit template.  Because unit definitions
-- are stored server-side in the user database, it contain old/obsolete/missing/etc.
-- fields which must be accomodated by this function, for backwards compatability.
-- Unit data is consumed directly by the simulation engine.
-- 
local function createUnitData( agentDef )
	local upgradedefs = include( "sim/upgradedefs" )
	local unitTemplate = lookupTemplate( agentDef.template )

	assert( unitTemplate, tostring(agentDef.template) .. " not found!" )

	local unitData = util.tcopy( unitTemplate )

	-- Override name
	unitData.name = agentDef.name or unitData.name

	-- Upgrades
	for i, upgrade in ipairs(agentDef.upgrades) do
		if type(upgrade) == "string" then
			upgradedefs.applyUpgrade( upgrade, unitData )
		else
			upgradedefs.applyUpgrade( upgrade.upgradeName, unitData, upgrade.upgradeParams )
		end
	end

	-- Skills
	if agentDef.skills then
		unitData.skills = util.tcopy( agentDef.skills )
	end

	return unitData
end

return
{
	tool_templates = tool_templates,
	agent_templates = agent_templates,

	lookupTemplate = lookupTemplate,
	createUnitData = createUnitData,
	npc_templates = npc_templates,
	prop_templates = prop_templates,
	quest_templates = quest_templates, 
}

