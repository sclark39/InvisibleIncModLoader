----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )

-----------------------------------------------------
-- Local functions

local function getID( self )
	assert(self._id)
	return self._id
end

local function isValid( self )
	return self._id
end

local function getUnitData( self )
	return self._unitData
end

local function getSpeech( self )
	return nil
end

local function getPlayerOwner( self )
	
	if self._parent and self._parent.getPlayerOwner then
		return self._parent:getPlayerOwner()
	end

	return self._parent
end

local function getPather(self)
	return nil
end


local function getUnitOwner( self )
	
	if self._parent then
		if self._parent.getUnitOwner then
			return self._parent:getUnitOwner()
		else
			return self
		end
	end
end

local function isNPC( self )
	local playerOwner = self:getPlayerOwner()
	return playerOwner and playerOwner:isNPC()
end

local function isPC( self )
	local playerOwner = self:getPlayerOwner()
	return playerOwner and playerOwner:isPC()
end

local function getAbilities( self )
	return self._abilities
end

local function hasAbility( self, abilityID )
	return false -- ghosts have no abilities
end

local function canUseAbility( self )
    return false
end

local function hasSkill( self )
    return false -- ghosts have no skills
end

local function getTraits( self )
	return self._traits
end

local function getSounds( self )
	return self._sounds
end

local function getInventoryCount( self )
	return 0
end

local function getRequirements( self )
	return self._unitData.requirements
end

local function hasTrait( self, trait )
	return self._traits[trait] ~= nil
end

local function hasTag( self, tag )
	return self._unitData.tags and self._unitData.tags[ tag ] ~= nil
end

local function isGhost( self )
	return true
end

local function isKO( self )
	return self._traits.koTimer ~= nil
end

local function isAlerted(self)
	return self._traits.alerted == true
end

local function canAct( self )
	return false
end

local function canBeInterrupted( self )
    return false
end

local function canReact( self )
	return false
end

local function isDead( self )
	return self._traits.dead ~= nil
end

local function getBrain( self )
	return nil
end

local function getSim( self )
	return self._sim
end

local function getChildren( self )
	return self._children or {}
end

local function getFacing( self )
	return self._facing
end

local function getFacingRad( self )
	return math.pi / 4 * self._facing
end

local function getMP( self )
	return self:getTraits().mp
end

local function getAP( self )
	return self:getTraits().ap
end

local function isAiming( self )
	return self:getTraits().isAiming
end

local function getWounds( self )
	return self:getTraits().wounds
end

local function getName( self )
	--return "ghost of " .. self._unitData.name
	return  self._unitData.name
end

local function getLocation( self )
	return self._x, self._y
end

local function getSkillpoints()
	return 0
end

local function getArmor( self )
	local armor = 0
	if self:getTraits().armor then
		armor = self:getTraits().armor
	end
	if self:getTraits().firewallArmor then
		if self:getTraits().mainframe_ice > 0 and self:getTraits().mainframe_ice > armor and self:getTraits().mainframe_status ~= "off" then
			armor = self:getTraits().mainframe_ice
		end
	end
	return armor
end


-----------------------------------------------------
-- Interface functions

local _M = {}

function _M.createUnitGhost( simunit )
	local t =
	{
		ClassType = "unitghost",

		_x = nil,
		_y = nil,
		_id = nil,
		_facing = simdefs.DIR_E, -- one of DIR_*
		_unitData = nil,
		_children = nil, -- child units
		_traits = nil,
		_abilities = {},
		_parent = nil,	-- owning entity.  either a simunit or a simplayer

		getID = getID,
		getUnitData = getUnitData,
		getSpeech = getSpeech,
		getPlayerOwner = getPlayerOwner,
		getUnitOwner = getUnitOwner,
		isNPC = isNPC,
		isPC = isPC,

		getAbilities = getAbilities,
		hasAbility = hasAbility,
        canUseAbility = canUseAbility,
        hasSkill = hasSkill,
		getTraits = getTraits,
		getSounds = getSounds,
		hasTrait = hasTrait,
		hasTag = hasTag,
		isGhost = isGhost,
		isKO = isKO,
		isAlerted = isAlerted,
		canAct = canAct,
        canBeInterrupted = canBeInterrupted,
		isDead = isDead,
		isAiming = isAiming,

		getInventoryCount = getInventoryCount,
        getRequirements = getRequirements,

		getBrain = getBrain,
		getSim = getSim,
		getPather = getPather,

		getChildren = getChildren,

		getWounds = getWounds,
		getMP = getMP,
		getAP = getAP,

		isValid = isValid,

		getFacing = getFacing,
		getFacingRad = getFacingRad,

		getName = getName,

		getLocation = getLocation,
		getArmor = getArmor,
	}

	if simunit then
		t._id = simunit:getID()
		t._sim = simunit:getSim()
		t._x, t._y = simunit:getLocation()
		t._parent = simunit:getPlayerOwner()
		t._facing = simunit:getFacing()
		t._unitData = simunit:getUnitData()
		t._traits = util.tdupe( simunit:getTraits() )
		t._sounds = simunit:getSounds() and util.tdupe( simunit:getSounds() )
		for _, ability in ipairs( simunit:getAbilities() ) do
			if ability.ghostable then
				table.insert( t._abilities, ability )
			end
		end
		t._children = simunit:getChildren()
	end

	return t
end

simfactory.register( _M.createUnitGhost )

return _M
