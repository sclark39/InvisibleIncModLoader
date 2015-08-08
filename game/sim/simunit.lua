----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )
local weighted_list = include( "modules/weighted_list" )
local simdefs = include( "sim/simdefs" )
local unitdefs = include( "sim/unitdefs" )
local speechdefs = include( "sim/speechdefs" )
local simquery = include( "sim/simquery" )
local modifiers = include( "sim/modifiers" )
local simability = include( "sim/simability" )
local abilityutil = include( "sim/abilities/abilityutil" )
local simskill = include( "sim/simskill" )
local simfactory = include( "sim/simfactory" )
local inventory = include( "sim/inventory" )
local mainframe = include( "sim/mainframe" )
local cdefs = include( "client_defs" )
-----------------------------------------------------
-- Prototype table

local DEFAULT_FACING = simdefs.DIR_E
local SKILL_COST = simdefs.BASE_SKILL_COST
local AUGMENT_TXT_COLOR = {r=255/255,g=255/255,b=51/255,a=1 }

local simunit =
{
	ClassType = "simunit",

	-- Cell location in the world this unit exists at.  Could be nil, if for example the
	-- unit is in the inventory, or somewhere else not "on the board"
	_x = nil,
	_y = nil,
	_id = nil,
	_facing = DEFAULT_FACING,
	_brain = nil,
	_unitData = nil,
	_children = nil, -- child units
	_abilities = nil,
	_traits = {},
	_skills = nil,
	_sounds = {},
	_seenUnits = nil,
	_parent = nil,	-- owning entity.  either a simunit or a simplayer
	_pather = nil,
	_skillCost = SKILL_COST, 
}

-----------------------------------------------------
-- Local functions

function simunit:getID( )
	assert(self._id, self:getName())
	return self._id
end

function simunit:getUnitData(  )
	return self._unitData
end

function simunit:getPlayerOwner( )
	
	if self._parent and self._parent.getPlayerOwner then
		return self._parent:getPlayerOwner()
	end

	return self._parent
end


function simunit:setPlayerOwner( player )
	if player ~= self._parent then
		if self._parent and self._parent.onUnitRemoved then
			self._parent:onUnitRemoved(self)
		end

		self._parent = player

		if self._parent then
			self._parent:onUnitAdded(self)
		end
	end
end

function simunit:getUnitOwner( )
	if self._parent and self._parent.getUnitOwner then
		return self._parent
	end

	-- No parent, or parent is a player (not a unit)
	return nil
end

function simunit:isNPC( )
	local playerOwner = self:getPlayerOwner()
	return playerOwner ~= nil and playerOwner:isNPC()
end

function simunit:isPC( )
	local playerOwner = self:getPlayerOwner()
	return playerOwner ~= nil and playerOwner:isPC()
end

function simunit:getPather()
	return self._pather
end

function simunit:setPather(pather)
	self._pather = pather
end

function simunit:getModifiers( )
    return self._modifiers
end

function simunit:getAbilities( )
	return self._abilities or {}
end

function simunit:hasAbility( abilityID )
	if self._abilities then
		for i,ability in ipairs(self._abilities) do
			if ability:getID() == abilityID then
				return ability
			end
		end
	end

	return nil
end

function simunit:ownsAbility(abilityID)
	local ability = self:hasAbility(abilityID)
	if ability then
		return ability, self
	end

	for i, child in ipairs(self:getChildren() ) do
		ability = child:hasAbility(abilityID) 
		if ability then
			return ability, child
		end
	end

	return nil
end

function simunit:removeAbility( sim, abilityID )
	-- We permit abilityID to be a string (the ability key) or the ability table itself.
	for i, ability in ipairs( self._abilities ) do
		if ability == abilityID or ability:getID() == abilityID then	
			ability:despawnAbility( sim, self )		
			table.remove( self._abilities, i )
			break
		end
	end
end

function simunit:canUseAbility( sim, abilityDef, abilityOwner, ... )
	local playerOwner = self:getPlayerOwner()
	if playerOwner and sim:getCurrentPlayer() ~= playerOwner then
		return false
	end

	if not self:canAct() then
		return false
	end

	local canUse, reason = abilityDef:canUseAbility( sim, abilityOwner, self, ... )
    if not canUse then
        return canUse, reason
    end

	if self:getTraits().movingBody and not abilityDef.canUseWhileDragging then
		return false, STRINGS.UI.REASON.DROP_BODY_TO_USE
	end

    return true
end

function simunit:getArmor( )
	local armor = 0
	if self:getTraits().armor then
		armor = self:getTraits().armor
	end

	if self:getPlayerOwner() and self:getPlayerOwner():getTraits().boostArmor then
		armor = armor + self:getPlayerOwner():getTraits().boostArmor
	end

	if self:getTraits().firewallArmor then
		if self:getTraits().mainframe_ice > 0 and self:getTraits().mainframe_ice > armor and self:getTraits().mainframe_status ~= "off" then
			armor = self:getTraits().mainframe_ice
		end
	end

	if self:getPlayerOwner() then 
		if self:getPlayerOwner():isNPC() then
			if self:getSim():getPC():getTraits().taggedArmorMod and self:getTraits().tagged then
				armor = math.max( armor + self:getSim():getPC():getTraits().taggedArmorMod, 0)
			end
			if self:getPlayerOwner():getTraits().armorBuff then
				armor = armor + self:getPlayerOwner():getTraits().armorBuff 
			end
		end
	end	

	return armor
end

				
function simunit:getTraits( )
	return self._traits
end

function simunit:getRequirements( )
	return self._unitData.requirements
end

function simunit:getGender(  )
	return self._unitData.gender
end

function simunit:getSpeech( )
	return self._unitData.speech
end

function simunit:getSkills( )
	return self._skills or {}	
end

function simunit:getInventoryCount( )
	local count = 0
	for _, childUnit in ipairs(self:getChildren()) do
		if childUnit:hasAbility( "carryable" ) and (not childUnit:getTraits().augment or not childUnit:getTraits().installed) then
			count = count + 1
		end
	end
	return count
end


function simunit:getAugmentCount( )
	local count = 0
	for _, childUnit in ipairs(self:getChildren()) do
		if childUnit:hasAbility( "carryable" ) and childUnit:getTraits().augment and childUnit:getTraits().installed then
			count = count + 1
		end
	end
	return count
end

function simunit:getAugments( )
	local augments = {}
	for _, childUnit in ipairs(self:getChildren()) do
		if childUnit:hasAbility( "carryable" ) and childUnit:getTraits().augment and childUnit:getTraits().installed then
			table.insert( augments, childUnit )
		end
	end
	return augments 
end



function simunit:doAugmentUpgrade(childUnit, useAbilityIndex)
	childUnit:getTraits().installed = true

    if self._sim and not childUnit:getUnitData().traits.installed then
        -- Don't count special auto-installed augments.
        self._sim:getStats():incStat( "times_augmented" )
    end

	if childUnit:getTraits().addAbilities then
		if useAbilityIndex then
			self:giveAbility(childUnit:getTraits().addAbilities, self._abilityIndex)
			self._abilityIndex = self._abilityIndex + 1
		else
			self:giveAbility(childUnit:getTraits().addAbilities)
		end
		
	end

	if childUnit:getTraits().addTrait then
		for i,trait in ipairs(childUnit:getTraits().addTrait) do
			if trait[2] then
				self:getTraits()[trait[1]] = trait[2]
			else
				self:getTraits()[trait[1]] = true
			end
		end
	end

	if childUnit:getTraits().modSkill then
		local skill = self:getSkills()[childUnit:getTraits().modSkill]

		if skill then
			while skill._currentLevel > childUnit:getTraits().modSkillStat do
				skill:levelDown( self._sim, self )
			end

			while skill._currentLevel < childUnit:getTraits().modSkillStat do
				skill:levelUp( self._sim, self )
			end
		end
	end

	if childUnit:getTraits().modSkillLock then
		if not self:getTraits().skillLock then
			self:getTraits().skillLock = {}
		end		
		for i,skill in ipairs(childUnit:getTraits().modSkillLock) do
			self:getTraits().skillLock[skill] = true
		end
	end
	
	if childUnit:getTraits().modTrait then
		for i,trait in ipairs(childUnit:getTraits().modTrait) do
			if not self:getTraits()[trait[1]] then
				self:getTraits()[trait[1]] = 0
			end
			self:getTraits()[trait[1]] = self:getTraits()[trait[1]] + trait[2]			
			if trait[1] == "mpMax" then
				self:getTraits().mp = self:getTraits().mp + trait[2]
			end
		end	
	end


	if childUnit:getTraits().addInventory then
		self:getTraits().inventoryMaxSize = self:getTraits().inventoryMaxSize + childUnit:getTraits().addInventory
	end

    if self._sim and self:getAugmentCount() >= simdefs.DEFAULT_AUGMENT_CAPACITY then
        self._sim:dispatchEvent( simdefs.EV_ACHIEVEMENT, "MEAT_MACHINE" )
    end
end

function simunit:getSounds( )
	return self._sounds
end

function simunit:hasTrait( trait )
	return self._traits[trait] ~= nil
end

--In Endless mode, we use this for cost instead of base costs.
function simunit:getSkillCost()
	return self._skillCost
end

function simunit:increaseSkillCost()
	local skillLevels = self:getTotalSkillLevels()
	self._skillCost = simdefs.BASE_SKILL_COST * math.pow(skillLevels, simdefs.SKILL_COST_EXP)
end

function simunit:getTotalSkillLevels()
	local skillLevels = 1
	for i,skill in ipairs( self._skills ) do 
		if skill:getCurrentLevel() > 1 then 
			skillLevels = skillLevels + (skill:getCurrentLevel() - 1)
		end
	end
	return skillLevels
end 

function simunit:hasSkill( skillID, level )
	if self._skills then
		for i,skill in ipairs(self._skills) do
			if skill:getID() == skillID and (level == nil or skill:getCurrentLevel() >= level) then
				return skill
			end
		end
	end

	return nil
end

function simunit:getSkillLevel( skillID )
    local skill = self:hasSkill( skillID )
    return skill and skill:getCurrentLevel() or 0
end

function simunit:hasTag( tag )
	if self._tags and (self._tags[ tag ] ~= nil or array.find( self._tags, tag )) then
        return true
    end

	if self._unitData.tags and (self._unitData.tags[ tag ] ~= nil or array.find( self._unitData.tags, tag )) then
        return true
    end

    return false
end

function simunit:addTag( tag )
    if self._tags == nil then
        self._tags = {}
    end
    table.insert( self._tags, tag )
end

function simunit:removeTag( tag )
    if self._tags == nil then
        self._tags = {}
    end

    local idx = nil
    for i,tagData in pairs(self._tags)do
    	if tag == tagData then
    		idx = i
    	end
    end
    if idx then
    	self._tags[idx] = nil
    --	table.remove( self._tags, idx )
    end
end

function simunit:isGhost( )
	return false
end

function simunit:setAlerted(alerted)

	if self._sim._resultTable.guards[self:getID()] then
		self._sim._resultTable.guards[self:getID()].alerted = true
	end


	if alerted ~= self:getTraits().alerted then
		assert(alerted, "cannot set an agent to not be alerted once alerted")
		self:getTraits().alerted = alerted
		self:getSim():triggerEvent(simdefs.TRG_UNIT_ALERTED, {unit=self})
        return true
    else
        return false
	end
end

function simunit:isAlerted()
	return self:getTraits().alerted
end

function simunit:isKO( )
	return self._traits.koTimer ~= nil
end

function simunit:getKOTimer( )
	return self._traits.koTimer 
end 

function simunit:isDead( )
	return self._traits.dead ~= nil
end

function simunit:isDown( )
	return self:isDead() or self:isKO()
end

function simunit:isNeutralized()
    return self:isDead() or simquery.isUnitPinned( self._sim, self )
end

function simunit:canAct()
	return self:isValid() and not self:isKO()
end

function simunit:canReact()
	return self:canAct()
	 and self:getSim():getCurrentPlayer() == self:getPlayerOwner()
	 and (not self:getPlayerOwner():getCurrentAgent() or self:getPlayerOwner():getCurrentAgent() == self)
	 and self:getSim():getTurnState() == simdefs.TURN_PLAYING
end

function simunit:canHide()
	return self:getTraits().hidesInCover or (self:isNPC() and self:isKO())
end

function simunit:getBrain()
	return self._brain
end

function simunit:getSim()
	return self._sim
end

function simunit:emptyChildren( )
	self._children = {}
end

function simunit:getChildren( )
	return self._children or {}
end

function simunit:hasChild( childID )
	if self._children then
		for i,child in ipairs(self._children) do
			if child:getID() == childID then
				return child
			end
		end
	end

	return nil
end

function simunit:countAugments( augmentName )
	local count = 0
	local augments = {}
	if self._children then
		for i,child in ipairs(self._children) do
			if augmentName and (child:getUnitData().id == augmentName or child:getTraits()[augmentName]) and child:getTraits().installed then
				count = count + 1 
				table.insert(augments,child)
			end		
		end
	end
	return count,augments
end

function simunit:countArmorPiercingUpgrades( traitName )
	local count = self:getTraits().genericPiercing or 0
	if self._children then
		for i,child in ipairs(self._children) do
			if child:getTraits()[ traitName ]then
				count = count + child:getTraits()[ traitName ]			
			end
		end
	end
	return count
end

function simunit:addChild( childUnit )
	assert( childUnit )	

	if childUnit._parent then
		-- setPlayerOwner expects _parent to be a player: we should never be adding childUnit if its _parent is another unit.
		childUnit:setPlayerOwner( nil )
	end

	if self._children == nil then
		self._children = { childUnit }
	else
		assert( util.indexOf( self._children, childUnit ) == nil )
		table.insert( self._children, childUnit )
	end

	if childUnit:getTraits().autoEquip or
       (childUnit:getTraits().slot == "melee" and not simquery.getEquippedMelee( self )) or
	   (childUnit:getTraits().slot == "gun" and not simquery.getEquippedGun( self )) then
		inventory.equipItem( self, childUnit )
		if self._sim then
			self._sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )
		end
	end
	

	childUnit._parent = self
end

function simunit:removeChild( childUnit )
	assert( childUnit )
	assert( childUnit._parent == self )
	assert( util.indexOf( self._children, childUnit ) ~= nil )

	array.removeElement( self._children, childUnit )
	childUnit._parent = nil
end

function simunit:getFacing( )
	return self._facing
end

function simunit:getFacingRad( )
    return self._traits.LOSrads or (math.pi / 4 * self._facing)
end

function simunit:setFacing( facing )
	if facing >= 0 and facing < simdefs.DIR_MAX and self._facing ~= facing then
		self._facing = facing
	end
end

function simunit:updateFacing( facing )
	if self:getTraits().refreshingLOS then
		--simlog( "%s [%d] NOT updating facing to %d because already refreshing LOS at <%d, %d: %d>",
		--	self:getName(), self:getID(), facing, self._x, self._y, self._facing )
		return
	end

	if facing >= 0 and facing < simdefs.DIR_MAX and self._facing ~= facing then
		--self:resetAllAiming()
		self:getTraits().turning = true
		self._facing = facing
		self._sim:dispatchEvent( simdefs.EV_UNIT_TURN, { unit = self, facing = facing } )

		if self:isValid() and self:hasTrait("hasSight") then
			self._sim:refreshUnitLOS( self )
		end
		if self:getPlayerOwner():isNPC() then
			self._sim:processReactions(self)
		end
		self:getTraits().turning = nil
	end
end

-- Helper to call updateFacing based on a target location
function simunit:turnToFace(x, y, floatTxt)
	local x1, y1 = self:getLocation()
	local sim = self:getSim()
	if not x1 or not y1 then	--we're not actually in the level
		return
	end
	if x ~= x1 or y ~= y1 then
		local facing = simquery.getDirectionFromDelta(x - x1, y - y1)
		if facing ~= self:getFacing() then
			self:updateFacing( facing ) --this could invalidate the unit

			if floatTxt then
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, { txt=floatTxt, x=x1,y=y1, color={r=1,g=1,b=41/255,a=1}, skipQue=true } )
			end
		end
	end	
end


function simunit:processKOresist( damage )
	local resistance = 0
	if self:getTraits().resistKO then
		resistance = resistance + self:getTraits().resistKO
	end
	if self:getPlayerOwner() and self:getPlayerOwner():getTraits().boostKOresist then
		resistance = resistance + self:getPlayerOwner():getTraits().boostKOresist
	end	    	
    return math.max( 1, damage - resistance )
end

function simunit:getWounds( )
	return self:getTraits().wounds
end

function simunit:addWounds( delta )
	self:getTraits().wounds = math.max( 0, math.min( self:getTraits().woundsMax, self:getTraits().wounds + delta ))
end

function simunit:getAP( )
	return self:getTraits().ap
end

function simunit:resetAP( )
	if self:hasTrait("apMax")  then
		self:getTraits().ap = self:getTraits().apMax	
	end
end

function simunit:useAP( sim )
	local x1,y1 = self:getLocation()
	local apTxt = STRINGS.UI.FLY_TXT.ATTACK_USED

	sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=apTxt,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )
	sim:dispatchEvent( simdefs.EV_HUD_MPUSED, self )

	if self:getTraits().actionAP then 
		local ADRENAL_BONUS=3
		if self:getPlayerOwner()  ~= sim:getCurrentPlayer() then
			if not self:getTraits().floatTxtQue then
				self:getTraits().floatTxtQue = {}
			end
			table.insert(self:getTraits().floatTxtQue,{txt=util.sformat(STRINGS.UI.FLY_TXT.ADRENAL_REGULATOR,ADRENAL_BONUS),color={r=255/255,g=178/255,b=102/255,a=1}})		
		else
			local x1,y1 = self:getLocation()
			sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = self } )		
			sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, { unit = self , txt=util.sformat(STRINGS.UI.FLY_TXT.ADRENAL_REGULATOR,ADRENAL_BONUS), x=x1,y=y1,color={r=255/255,g=178/255,b=102/255,a=1}  } )	-- 
		end
		self:addMP( ADRENAL_BONUS )
	end 

	local apUsed = false	
	for i,unit in ipairs(self:getChildren( )) do
		if unit:getTraits().extraAP and unit:getTraits().extraAP > 0 then
			unit:getTraits().extraAP = unit:getTraits().extraAP -1 
			apUsed = true
			local x1,y1 = self:getLocation()
		--	sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, { unit = self , txt=STRINGS.UI.FLY_TXT.EXTRA_ATTACK, sound = "SpySociety/Objects/drone/drone_mainfraimeshutdown", x=x1,y=y1,color={r=255/255,g=178/255,b=102/255,a=1}  } )	-- 
			break
		end
	end	

	if self:getTraits().unlimitedAttacks then
		apUsed = true
	end

	if apUsed == false then
		self:getTraits().ap = self:getTraits().ap - 1
	end

	if self:getTraits().monster_hacking then 
		self:getTraits().monster_hacking = false
		self:getSounds().spot = nil
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self })
	end
	self:resetAllAiming()
	

	sim:processReactions( self )
end

function simunit:checkOverload(sim)
	if self:getTraits().inventoryMaxSize then
		local overload = self:getInventoryCount() - self:getTraits().inventoryMaxSize
		if overload > (self:getTraits().overloadCount or 0) then
            self:useMP(overload,sim)
			local x1,y1 = self:getLocation()
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(STRINGS.UI.FLY_TXT.ENCUMBERED,overload),x=x1,y=y1,color={r=163/255,g=0,b=0,a=1}} )
            self:getTraits().overloadCount = overload
		end	
	end
end

function simunit:getMP( )
	if self:getTraits().movingBody then
		local dragCost = simdefs.DRAGGING_COST

		if self:hasTrait("dragCostMod") then
			dragCost = dragCost -  self:getTraits().dragCostMod
		end

		--easier to drag agents
		local body = self:getTraits().movingBody
		if not body:getTraits().isGuard then
			dragCost = dragCost - 1
		end

		--never improve moving if you're dragging!
		dragCost = math.max(simdefs.MIN_DRAGGING_COST, dragCost)

		--print( self:getTraits().mp / dragCost )
		return self:getTraits().mp / dragCost
	elseif self:getTraits().sneaking then
		return self:getTraits().mp / simdefs.SNEAKING_COST
	else
		return self:getTraits().mp
	end
end

function simunit:getMPMax( )
	local count = 0
	for i,unit in ipairs(self:getChildren( )) do
		if unit:getTraits().addMP then
			count = count + unit:getTraits().addMP
		end
	end

	return self:getTraits().mpMax + count
end

function simunit:addMPMax( delta )
	 self:getTraits().mpMax = math.max( self:getTraits().mpMax + delta, 0 )
end

function simunit:addMP( delta )
	 self:getTraits().mp = math.max( self:getTraits().mp + delta, 0 )
end

function simunit:useMP( delta, sim )
	if not self:getTraits().alwaysFullMP then
		self:getTraits().mp = math.max( 0, self:getTraits().mp - delta )
	    self:getTraits().mpUsed = math.max( 0, (self:getTraits().mpUsed or 0) + delta )
		sim:dispatchEvent( simdefs.EV_HUD_MPUSED, self )
	end
end

function simunit:setAiming( aiming )
	if aiming ~= self:getTraits().isAiming then
		local abilityDef = self:ownsAbility("shootOverwatch")
		if abilityDef then	
			if self:getTraits().isAiming then
				self:getSim():removeTrigger( simdefs.TRG_OVERWATCH, abilityDef )
			end

			if aiming then
				self:getSim():addTrigger(simdefs.TRG_OVERWATCH, abilityDef, self )			
			end
		end
	end

	self:getTraits().isAiming = aiming
end

function simunit:isAiming()
	return self:getTraits().isAiming
end

function simunit:resetAllAiming()
    if self:isAiming() or self:getTraits().isMeleeAiming then
	    self:setAiming(false)
	    self:getTraits().isMeleeAiming = false
	    self._sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self })
    end
end

function simunit:takeControl( player )
	self:setPlayerOwner( player )	
    player:glimpseUnit( self._sim, self:getID() )

	self._sim:dispatchEvent( simdefs.EV_UNIT_CAPTURE, { unit = self } )	

	if self:getTraits().partnerID then
		local partner = self._sim:getUnit( self:getTraits().partnerID )
        partner:takeControl( player )
        if player:isNPC() then 
        	self._sim:getPC():glimpseUnit( self._sim, partner:getID() )
        end 
	end

	if self:getTraits().mainframe_autodeactivate then
		self:deactivate( self._sim )
	end

	self._sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self} )

end

function simunit:processEMP( bootTime, noEmpFX )

	local empResisted = false
	local doEMPeffect = false


	if self:getTraits().mainframe_status == "off" then
		if self:getTraits().mainframe_booting then
        	self:getTraits().mainframe_booting = bootTime -- Restart boot timer.
    	end
      
	elseif self:getTraits().mainframe_status ~= nil and self:getTraits().mainframe_status ~= "off" then

		local EMP_FIREWALL_BREAK_STRENGTH = 2
		if self:getTraits().magnetic_reinforcement and self:getTraits().mainframe_ice > 2 then
			empResisted = true
			local x1,y1 = self:getLocation()
			local sim = self._sim 
			mainframe.breakIce( sim, self, EMP_FIREWALL_BREAK_STRENGTH )
			self._sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.TOOLTIPS.MAGNETIC_REINFOREMENTS,x=x1,y=y1,color={r=255/255,g=255/255,b=255/255,a=1}} )
		else
			self:getTraits().mainframe_status_old = self:getTraits().mainframe_status
	        if self.deactivate then
			    self:deactivate( self._sim )
			end

			if self:getTraits().firewallShield then
				self:getTraits().shields = 0			
			end	
			self:getTraits().mainframe_status = "off"
	        self:getTraits().mainframe_booting = bootTime

			doEMPeffect = true
	    end
	elseif not empResisted and self:getTraits().heartMonitor == "enabled" then
		doEMPeffect = true
	end
	if doEMPeffect then
		if not noEmpFX then
	   		local x0,y0 = self:getLocation()
			self._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/HitResponse/hitby_distrupter_flesh", x=x0,y=y0} )
			self._sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self, fx = "emp" } )			
	    end		
	    self._sim:triggerEvent( simdefs.TRG_UNIT_EMP, self )
	end

	if not empResisted and self:getTraits().heartMonitor=="enabled" then
		local x1,y1 = self:getLocation()

		if self:getTraits().improved_heart_monitor then
			self._sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.IMPROVED_HEART_MONITOR,x=x1,y=y1,color={r=1,g=1,b=41/255,a=1}} ) 
		else
			self:getTraits().heartMonitor="disabled"
			self._sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.MONITOR_DISABLED,x=x1,y=y1,color={r=255/255,g=255/255,b=255/255,a=1}} )			
		end
	end

    self._sim:getPC():glimpseUnit( self._sim, self:getID() )
end

function simunit:setTagged(dissable)
	if dissable then 
		self:getTraits().tagged = false
		local x1,y1 = self:getLocation()
		self._sim :dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.TAG_REMOVED,x=x1,y=y1,color={r=255/255,g=255/255,b=255/255,a=1}} )
	else

	    if self:getBrain() == nil then
	        return
	    end

		self:getTraits().tagged = true
		
		local x1,y1 = self:getLocation()
	    self._sim :dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.TAGGED,x=x1,y=y1,color={r=255/255,g=255/255,b=255/255,a=1}} )
		self._sim :dispatchEvent( simdefs.EV_UNIT_GOALS_UPDATED, { unitID = self:getID() } )	

		self:getTraits().patrolObserved = true
	end
end


function simunit:changeKanim(  kanim, delay )

	local sim = self._sim 

	self:getTraits().tempKanim = kanim
	sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )

	if delay then
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, delay * cdefs.SECONDS )
	end

end

function simunit:setDisguise( state, kanim )

	local sim = self._sim 

	if (self:getTraits().disguiseOn == true) ~= (state == true) then
		local cell = sim:getCell(self:getLocation() )
		
		

		local params = {}
		local x1,y1 = self:getLocation()
		
		
		self:getTraits().walk = state
		

		if kanim then
			
			sim:dispatchEvent( simdefs.EV_UNIT_GOTO_STAND, { unit = self, stand = true})
			self:getTraits().hidesInCover = not state
			self:getTraits().disguiseOn = state
			local seers = sim:generateSeers( self )

			self._sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.DISGUISED,x=x1,y=y1,color={r=255/255,g=255/255,b=255/255,a=1}} )	
			sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = self, kanim = "fx/agent_cloak_fx", symbol = "effect", anim="in", above=true, params=params} )
			
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/holocover_activate", x=x1,y=y1} )

			self:changeKanim(  kanim , 0.05 )
			self:changeKanim(  nil , 0.1 )
			self:changeKanim(  kanim , 0.05 )
			self:changeKanim(  nil , 0.05 )
			self:changeKanim(  kanim , 0.1 )
			self:changeKanim(  nil , 0.05 )
			self:changeKanim(  kanim )			
			sim:processReactions(self)
		else
			self:getTraits().disguiseOn = state
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/holocover_deactivate", x=x1,y=y1} )
			sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = self, kanim = "fx/agent_cloak_fx", symbol = "effect", anim="out", above=true, params=params} )				

			local default = self:getTraits().tempKanim
			self:changeKanim(  nil , 0.05 )
			self:changeKanim(  default , 0.1 )
			self:changeKanim(  nil , 0.05 )
			self:changeKanim(  default , 0.05 )
			self:changeKanim(  nil , 0.1 )
			self:changeKanim(  default , 0.05 )
			self:changeKanim(  nil )	
				
	        self:getTraits().hidesInCover = not state
			local seers = sim:generateSeers( self ) 

	        for i,seer in ipairs(seers) do
	     
	        	local unit = sim:getUnit(seer)
	        	if unit then
				    if simquery.couldUnitSee( sim, unit, self, true ) then
				    	local x0,y0 = unit:getLocation()
				    	-- if unit is in a visible tile and not behind cover do the APPEARED trigger
				        if  unit:getTraits().seesHidden or not simquery.checkIfNextToCover(sim, self) or not simquery.checkCellCover( sim, x0, y0, self:getLocation() ) then
						   	sim:triggerEvent( simdefs.TRG_UNIT_APPEARED, { seerID = seer, unit = self } )
						end					   
				    end

				end

	        end			     
	        sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )   

	        sim:dispatchEvent( simdefs.EV_UNIT_GOTO_STAND, { unit = self, stand = false})
	        sim:processReactions(self)
	     	       
		end
 	end	
end


function simunit:setInvisible( state, duration )

	local sim = self._sim 

	if (self:getTraits().invisible == true) ~= (state == true) then
		local cell = self:getSim():getCell(self:getLocation() )
		self._sim:generateSeers( self )

		self:getTraits().invisible = state

		local x2, y2 = self:getLocation()
		if state then
			sim:emitSound( simdefs.SOUND_CLOAK, x2, y2, nil )
		else
			sim:dispatchEvent( simdefs.EV_CLOAK_OUT, { unit = self  } )
		--	sim:emitSound( simdefs.SOUND_UNHIDE, x2, y2, nil )
		end

        -- Refresh before notifying seers, so that the unit appears correct if 'stuff' happens.
        sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )
		
        self._sim:notifySeers()

		if self:getTraits().invisible then
			--Run CLOAK Augments 
			sim:dispatchEvent( simdefs.EV_CLOAK_IN, { unit = self  } )
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = STRINGS.ABILITIES.CLOAKED, x = x2, y = y2, color={r=255/255,g=255/255,b=51/255,a=1}} )

			if self:countAugments( "augment_chameleon_movement" ) > 0 then
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = STRINGS.ITEMS.AUGMENTS.CHAMELEON_MOVEMENT, x = x2, y = y2, color={r=255/255,g=255/255,b=51/255,a=1}} )
				self:getTraits().mp = self:getTraits().mp + 6
			end

			if self:countAugments( "augment_holocircuit_overloaders" ) > 0 then
				sim:startTrackerQueue(true)				
				sim:startDaemonQueue()			
				if sim:isVersion("0.17.5") then
					sim:emitSound( simdefs.SOUND_HOLOCIRCUIT_OVERLOAD, x2, y2, self )
				else
					sim:emitSound( simdefs.SOUND_OVERLOAD, x2, y2, self )
				end
				
				sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = x2, y = y2, range = simdefs.HOLOCIRCUIT_RANGE } )
                sim:dispatchEvent( simdefs.EV_KO_GROUP, true )
				
				local x2, y2 = self:getLocation()
				local cells = simquery.fillCircle( sim, x2, y2, simdefs.HOLOCIRCUIT_RANGE, 0)
				for i, cell in ipairs(cells) do
					for i, cellUnit in ipairs( cell.units ) do
						if simquery.isEnemyAgent(self:getPlayerOwner(), cellUnit) and not cellUnit:isKO() then
							if cellUnit:getTraits().canKO then
								cellUnit:setKO( sim, simdefs.HOLOCIRCUIT_KO )
							elseif cellUnit:getTraits().isDrone and cellUnit.deactivate then
								cellUnit:deactivate(sim)
							end
						end
					end
				end
                sim:dispatchEvent( simdefs.EV_KO_GROUP, false )
			
				sim:startTrackerQueue(false)				
				sim:processDaemonQueue()			
			end
		end			
 	end

	if self:getTraits().invisible then
		if duration ~= nil then
			self:getTraits().invisDuration = math.max( self:getTraits().invisDuration or 0, duration or 0 )
		end
	else
		self:getTraits().invisDuration = nil
	end
end

function simunit:setInvestigated(unit)
	assert(unit)
	if not self:getTraits().investigated then
		self:getTraits().investigated = {}
	elseif type(self:getTraits().investigated) == "table" then
		self:getTraits().investigated[unit:getID()] = true
	end
end

function simunit:clearInvestigated()
	self:getTraits().investigated = nil
end

function simunit:hasBeenInvestigated(unit)
	if unit and self:getTraits().investigated and type(self:getTraits().investigated) == "table" then
		return self:getTraits().investigated[unit:getID()]
	end
	return self:getTraits().investigated ~= nil
end

function simunit:setSwitchStage(sim,stage)
--	self:getTraits().switch_stage = stage
	--sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_SPOTSOUND, { unit = self,  stop = true } )
--	self:getSounds().spot = self:getSounds().activeSpot
--	local x1,y1= self:getLocation()
--	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound= self:getSounds().activate, x=x1,y=y1} )
--	sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_SPOTSOUND, { unit = self,  stop = false } )
	sim:dispatchEvent(simdefs.EV_UNIT_SWTICH_FX,{unit=self,transition=stage})
end

function simunit:setMonst3rConsoleStage(sim,stage)
	self:getTraits().monst3rConsole_stage = stage
	sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_SPOTSOUND, { unit = self,  stop = true } )
	self:getSounds().spot = self:getSounds().activeSpot
	local x1,y1= self:getLocation()
	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound= self:getSounds().activate, x=x1,y=y1} )
	sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_SPOTSOUND, { unit = self,  stop = false } )
	sim:dispatchEvent(simdefs.EV_UNIT_MONST3R_CONSOLE,{unit=self})
end

function simunit:buffArmor(sim,armorBuff)
	local x1,y1= self:getLocation()
	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound= "SpySociety/Weapons/LowBore/reload_shotgun", x=x1,y=y1} )
	if not self:getTraits().armor then
		self:getTraits().armor = 0
	end
 	self:getTraits().armor = self:getTraits().armor + armorBuff
 	sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt= util.sformat(STRINGS.UI.FLY_TXT.ARMOR_UP,armorBuff),x=x1,y=y1,color={r=1,g=1,b=41/255,a=1}} ) 
 	local params = {color ={{symbol="wall",r=1,g=0,b=0,a=1}} }
 	sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = self, kanim = "fx/firewall_buff_fx_2", symbol = "character", anim = "in", above=true, params=params} )	
end



function simunit:setKO( sim, ticks, fx )
    assert( ticks == nil or (type(ticks) == "number" and ticks > 0))

	if self._sim._resultTable.guards[self:getID()] then
		self._sim._resultTable.guards[self:getID()].alerted = true
		self._sim._resultTable.guards[self:getID()].ko = true
	end


    if self:getTraits().koTimer and ticks then
        -- If applying a new duration but the unit is already KO, always use the larger value.
        self:getTraits().koTimer = math.max( self:getTraits().koTimer, ticks )      

	elseif self:getTraits().koTimer ~= ticks then
		local wasHidden = simquery.checkIfNextToCover( sim, self )
        -- KO status has changed...
		self:getTraits().koTimer = ticks

		if ticks then
			self:getTraits().dynamicImpass = nil -- Allow passthru of sleeping units
			self:clearInvestigated() --new body, don't be noticed
            self:getTraits().movingBody = nil -- Really, stop moving any bodies.
			self:useMP( self:getMP(), sim )
            self:setAiming( nil )
            self:destroyTab()

			if self:getTraits().isGuard then 
				sim:getStats():incStat("guards_kod")
			end

			sim:dispatchEvent( simdefs.EV_UNIT_KO, { unit = self, fx = fx} )
			sim:refreshUnitLOS( self )		

			--dissable null zone
			if self:getTraits().mainframe_suppress_range then
				self:getTraits().mainframe_suppress_range = 0
			end	                

            
			if self:getTraits().consciousness_monitor then 
				local alarmInc = 2
				
				local x0,y0 = self:getLocation()
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt= STRINGS.UI.FLY_TXT.CONSCIOUSNESS_MONITOR,x=x0,y=y0,color={r=1,g=1,b=41/255,a=1}} ) 
				sim:trackerAdvance( alarmInc, STRINGS.UI.WARNING_CONSCIOUSNESS_MONITOR )
    			sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT,
                    { txt = util.sformat( STRINGS.UI.ALARM_ADD, alarmInc ),
                      x=x0,y=y0, color={r=1,g=0,b=0,a=1},
                      target="alarm"} )
			
            --ALARM on KO code
			elseif self:getTraits().heartMonitor == "enabled" and sim:getParams().difficultyOptions.alarmRaisedOnKO then

				local alarmInc, text
				
				if self:getTraits().improved_heart_monitor then 
					local x1,y1 = self:getLocation()
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt= STRINGS.UI.FLY_TXT.IMPROVED_HEART_MONITOR,x=x1,y=y1,color={r=1,g=1,b=41/255,a=1}} ) 
					alarmInc = 2
					text = STRINGS.UI.ALERT_IMPROVED_HEART
	            else
				    alarmInc = 1
				    text = STRINGS.UI.ALERT_HEART
				end 

				local x0,y0 = self:getLocation()
				sim:trackerAdvance( alarmInc, text )
	    		sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT,
	                { txt = util.sformat( STRINGS.UI.ALARM_ADD, alarmInc ),
	                    x=x0,y=y0, color={r=1,g=0,b=0,a=1},
	                    target="alarm"} )
			end

		    if self:getTraits().koDaemon and not self:getTraits().mainframe_device then
				sim:moveDaemon(self)
		    end

		    if self:getTraits().AOEFirewallsBuff then
		    	local x1,y1 = self:getLocation()
		    	local range = self:getTraits().AOEFirewallsBuffRange
		    	local buff = self:getTraits().AOEFirewallsBuff
		    	sim:AOEbuffFirewalls(x1,y1,range,buff)
		    end
		     if self:getTraits().buffArmorOnKO then
		     	self:buffArmor(sim,self:getTraits().buffArmorOnKO)
		     end		    

		else
			self:getTraits().dynamicImpass = self:getUnitData().traits.dynamicImpass -- Restore dynamicImpass
			self:clearInvestigated()	--don't be a noticed interest anymore			

			sim:refreshUnitLOS( self )
			if self:isNPC() then
				sim:emitSpeech(self, speechdefs.HUNT_WAKEUP)
			end
			sim:dispatchEvent( simdefs.EV_UNIT_KO, { unit = self, stand = true } )
			sim:getPC():glimpseUnit(sim, self:getID())

			if self:getTraits().shieldArmor then
				self:getTraits().mainframe_ice = self:getTraits().mainframe_iceMax
				self:getTraits().shields = 1
				local x0, y0 = self:getLocation()
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/mainframe_object_on", x=x0,y=y0} )
			end

		end

		sim:triggerEvent( simdefs.TRG_UNIT_KO, { unit = self, ticks = ticks }) --could result in reactions
		if self:getTraits().monster_hacking then 
			self:getTraits().monster_hacking = false
			self:getSounds().spot = nil
			sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_SPOTSOUND, { unit = self,  stop = true } )
		end 

		if wasHidden ~= simquery.checkIfNextToCover( sim, self ) then
            sim:generateSeers( self )
			sim:notifySeers()
		end
	end


end

function simunit:tickKO( sim )
	if self:isKO() and not self:isDead() and not self:getTraits().paralyzed then
		local cell = sim:getCell( self:getLocation() )
		-- Don't tick KO if there is another agent standing in this cell that is not us, and is not KO.
		for i, cellUnit in ipairs( cell.units ) do
			if simquery.isAgent( cellUnit ) and not cellUnit:isKO() then
				return
			end
		end

		self:getTraits().koTimer = self:getTraits().koTimer - 1
			
		if self:getTraits().koTimer <= 0 then

			--enable null zone
			if self:getTraits().mainframe_suppress_rangeMax then
				if not self:getPlayerOwner():isPC() then
					self:getTraits().mainframe_suppress_range = self:getTraits().mainframe_suppress_rangeMax
				end
			end

            if self:getSounds().reboot_end then
	        	local x0,y0 = self:getLocation()
				self._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound=self:getSounds().reboot_end, x=x0,y=y0} )                
        	end

			--return daemon to hosting unit
 			if self:getTraits().koDaemon and self:getTraits().mainframe_device then 				
                mainframe.revokeDaemonHost( sim, self )
 			end		

			self:setKO( sim, nil )
	
			sim:processReactions(self)

			if self:getPlayerOwner() ~= sim:getPC() then
				local pc = sim:getPC()
				for i, unit in pairs( pc:getAgents() ) do

					local count, augments = unit:countAugments( "boost_AP_on_wakeup" )
					if count > 0 then
			        	sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = unit  } )
			        	local x2,y2 = unit:getLocation()

					    sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt =augments[1]:getTraits().boost_AP_on_wakeup_txt, x = x2, y = y2, color=AUGMENT_TXT_COLOR} )
					    sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )						
						unit:getTraits().mp = unit:getTraits().mp + 2
					end
				end
			end			
		end
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )			
	end
end

function simunit:killUnit( sim )
	if self._sim._resultTable.guards[self:getID()] then
		self._sim._resultTable.guards[self:getID()].killed = true
	end

	self:getTraits().dead = true
	if self:getBrain() then
		self:getBrain():getSenses():clearTargets()
	end
    self:destroyTab()


	local mainframe = include( "sim/mainframe" )
	if sim:isVersion("0.17.5") and self:getTraits().parasite then
		mainframe.removeParasite(sim:getPC(),self)
	end

	sim:dispatchEvent( simdefs.EV_UNIT_DEATH, { unit = self } )

	local removeDaemon = false

	-- Generate a corpse.
    local corpseUnit = nil
	if self:getTraits().corpseTemplate then
		local corpseTemplate = util.extend( self:getTraits().corpseTemplate )
		{
			name = string.format(STRINGS.UI.CORPSE_OF, self:getName() ),
			kanim = self:getUnitData().kanim,
			profile_anim = self:getUnitData().profile_anim,
			profile_build = self:getUnitData().profile_build,
		}

		corpseUnit = simfactory.createUnit( corpseTemplate, sim )

		corpseUnit:getTraits().unitID = self:getID() -- Track the original unit ID, for debugging mostly.
		corpseUnit:getTraits().cashOnHand = self:getTraits().cashOnHand
		if self:getTraits().PWROnHand then
			corpseUnit:getTraits().PWROnHand = self:getTraits().PWROnHand
		end
		corpseUnit:getTraits().notDraggable = self:getTraits().notDraggable
		corpseUnit:getTraits().wasDrone = self:getTraits().isDrone

		corpseUnit:getTraits().neural_scanned = self:getTraits().neural_scanned 

		sim:spawnUnit( corpseUnit )
		sim:warpUnit( corpseUnit, sim:getCell( self:getLocation()), self:getFacing() )

		inventory.giveAll( self, corpseUnit )

		if self:getTraits().cleanup then
			sim:addCleaningKills( 1 )
		end

		if self:getTraits().enforcer then 
			sim:addEnforcersToSpawn( 1 )
		end
        
	else
		inventory.dropAll( sim, self )
	end

	-- Remove from current location
    local x0, y0 = self:getLocation()
	sim:warpUnit( self, nil )

	-- Final removal.
	sim:despawnUnit( self )
	sim:triggerEvent( simdefs.TRG_UNIT_KILLED, { unit = self, corpse = corpseUnit } )

    -- Crazy death ramifications below.
    if 	self:getTraits().heartMonitor then					
		local alarmInc, text
		if self:getTraits().heartMonitor == "disabled" then
			alarmInc = 0
			text = STRINGS.UI.ALERT_DAMAGED_HEART
		elseif self:getTraits().improved_heart_monitor then 
			alarmInc = 4
			text = STRINGS.UI.ALERT_IMPROVED_HEART
        else
			alarmInc = 2
			text = STRINGS.UI.ALERT_HEART
		end 

		if alarmInc > 0 then 
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(  STRINGS.UI.ALARM_ADD, alarmInc ),x=x0,y=y0,color={r=255/255,g=10/255,b=10/255,a=1}} )
			sim:trackerAdvance( alarmInc, text )					
	    end 
	end

	if self:getTraits().kill_trigger then 
		sim:triggerEvent( self:getTraits().kill_trigger )
	end

	if self:getTraits().mainframe_device then
		local mainFrameDevice = sim:getUnit(self:getTraits().mainframe_device)
	    sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = mainFrameDevice, ice = mainFrameDevice:getTraits().mainframe_ice, delta = 0} )	
				
		local delay = 0.5
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)
		
		local params = {color ={{symbol="inner_line",r=1,g=0,b=0,a=0.75},{symbol="wall_digital",r=1,g=0,b=0,a=0.75},{symbol="boxy_tail",r=1,g=0,b=0,a=0.75},{symbol="boxy",r=1,g=0,b=0,a=0.75}} }
		sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = mainFrameDevice, kanim = "fx/deamon_ko", symbol = "effect", anim="break", above=true, params=params} )			
		local x1,y1 = mainFrameDevice:getLocation()
		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/guard/MFghost_enterMF", x=x1,y=y1} )			
		
		local delay = 0.5
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)

		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_DAEMON_REVEAL.path )
		mainFrameDevice:getTraits().mainframe_program = nil
        mainFrameDevice:getTraits().daemonHost = nil
		sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = mainFrameDevice, ice = mainFrameDevice:getTraits().mainframe_ice, delta = 0} )	
	end
end

function simunit:isValid( )
	return self._id ~= nil and self._sim:getUnit( self._id ) ~= nil 
end

function simunit:invalidate( )
	self._id = nil
	self._sim = nil
end

function simunit:increaseIce(sim,iceInc)

	if self:getTraits().mainframe_iceMax then
        sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = self, ice = self:getTraits().mainframe_ice, delta = iceInc } )

		local raiseIce = true
		if self:getTraits().noRaiseIfIceZero and self:getTraits().mainframe_ice <= 0 then
			raiseIce = false
		end

		if self:getTraits().mainframe_iceMax and not self:getTraits().mainframe_console and ( not self:getPlayerOwner() or not self:getPlayerOwner():isPC() ) then

			if raiseIce then
				self:getTraits().mainframe_ice = self:getTraits().mainframe_ice+iceInc
			end

			self:getTraits().mainframe_iceMax = self:getTraits().mainframe_iceMax+iceInc					
		end
	end
end

function simunit:recaptureMainframeItems(sim,range)
	local items = {}

	local player = sim:getPC()
	for i,u in ipairs(player:getUnits()) do
		local x0,y0 = u:getLocation()
		local x1,y1 = self:getLocation()
		local dist = mathutil.dist2d( x0, y0, x1, y1 )
        if mainframe.canRevertIce( sim, u ) and dist <= range then
			table.insert(items,u)
		end
	end

	if #items > 0 then
		local item = items[sim:nextRand(1,#items)]
		if item  then
			mainframe.revertIce( sim, item )
		end
	end

end

function simunit:getAreaCells()
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


function simunit:scanCell(sim, cell)
	local player = self:getPlayerOwner()
	local x0,y0 = self:getLocation()

	for i, cellUnit in ipairs( cell.units ) do
        if player:isNPC() then
		    if simquery.isEnemyAgent(player, cellUnit) then

				local guard = nil
				local dist = 9999
				
				for i, child in pairs(sim:getAllUnits())do

					if child:getPlayerOwner() and child:getPlayerOwner():isNPC() and not child:isKO() and not child:isDead() and child ~= self then
						local x1,y1 = child:getLocation()	
						if x1 and y1 then
							local distTest = mathutil.dist2d( x0, y0, x1, y1 )
							if distTest < dist then
							 	guard = child
							 	dist = distTest
							end
						end
					end
				end

				if guard then
		        	guard:getBrain():getSenses():addInterest( cell.x, cell.y, simdefs.SENSE_SIGHT, simdefs.REASON_SCANNED, cellUnit)
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

function simunit:onStartTurn( sim )



	if sim:isVersion("0.17.5") then
		if self:getPlayerOwner() == sim:getPC() then
			self:tickKO( sim )
		end
	end

	if self:getTraits().unlimitedAttacks then
		self:getTraits().unlimitedAttacks = nil
	end

	if self:getTraits().tempMeleeBoost then
		self:getTraits().tempMeleeBoost = 0
	end

    if self:getBrain() then
        self:getBrain():onStartTurn( sim )
    end

	if self._abilities then
		for i,ability in ipairs(self._abilities) do
			if ability.automatic then
				ability:executeAbility( sim, self, self)			
			end		
		end
	end

	local traits = self:getTraits()

	if traits.shieldsMax ~= nil then
		if traits.shields < traits.shieldsMax then
			traits.shields = traits.shields + 1 
		end
	end
	
	if traits.apMax then
		traits.ap = traits.apMax
	end

    if self:getPlayerOwner() ~= nil then
	    for i = 1, self:countAugments( "augment_distributed_processing" ) do
		    if sim:nextRand(0, 100) <= 50 then
			    sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = util.sformat( STRINGS.UI.FLY_TXT.PLUS_PWR, 1), unit = self, color={r=255/255,g=255/255,b=51/255,a=1}} )
			    self:getPlayerOwner():addCPUs( 1 )
		    end
	    end
    end

	if traits.invisDuration then
		traits.invisDuration = traits.invisDuration - 1
		if traits.invisDuration <= 0 then
			traits.invisDuration = nil
			self:setInvisible( false )
		end		
	end
	if traits.cloakDistance then
		traits.cloakDistance = nil
	end

	if traits.genericPiercing then 
		traits.genericPiercing = nil
	end 

	for i,childUnit in ipairs(self:getChildren()) do
		local childTraits = childUnit:getTraits()

		if (childTraits.cooldown or 0) > 0 then
			childTraits.cooldown = childTraits.cooldown - 1
		end

		if childTraits.energyWeapon == "active" then
            childTraits.energyWeapon = "used"
		end

		if childTraits.nopwr_guards then 
			childTraits.nopwr_guards = {}
		end 
	
		if childTraits.extraAPMax then		
			childTraits.extraAP = childTraits.extraAPMax
		end
	end

	if traits.mainframeRecapture and not self:isKO() then
		self:recaptureMainframeItems(sim,traits.mainframeRecapture)
	end


	traits.temporaryProtect = nil	

    self:getTraits().overloadCount = nil
	self:checkOverload(sim)

	if self:getTraits().floatTxtQue then
		for i,floatItem in ipairs(self:getTraits().floatTxtQue) do
			local x0,y0 = self:getLocation()
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=floatItem.txt,x=x0,y=y0,color=floatItem.color} ) 

			--jcheng: assuming all floattexts are for gaining AP
			sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = self } )
		end
		self:getTraits().floatTxtQue = {}
	end

	if traits.pulseScan and not self:isKO() and self:getPlayerOwner():isNPC() then		
	    local cells = self:getAreaCells()
	    sim:dispatchEvent( simdefs.EV_PULSE_SCAN, {unit=self, cells=cells} ) 
		for i, cell in ipairs(cells) do
			for i, cellUnit in ipairs( cell.units ) do
				self:scanCell(sim, cell)
			end
		end		
	end
end

function simunit:canActivate( sim )
    if self:getTraits().powerGrid and self:getTraits().powerGrid ~= self:getID() then
        local generator = sim:getUnit( self:getTraits().powerGrid )
        if not generator or generator:getTraits().mainframe_status ~= "active" then
            return false
        end
    end
    return true
end

function simunit:onEndTurn( sim )
	local traits = self:getTraits()

	traits.movePath = nil
	traits.interrupted = nil

	if traits.controlTimer and sim:getCurrentPlayer():isNPC() then 
		traits.controlTimer = traits.controlTimer - 1 
		if traits.controlTimer <= 0 then 
			if self.loseControl then 
				self:loseControl( sim )
			end
		end
	end

    if traits.mainframe_booting and traits.mainframe_status == "off" then
        if sim:getCurrentPlayer() and sim:getCurrentPlayer():isPC() then
            traits.mainframe_booting = traits.mainframe_booting - 1

            if traits.mainframe_booting <= 0 then
                traits.mainframe_booting = nil

                if self:getSounds().reboot_end then
		        	local x0,y0 = self:getLocation()
					self._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound=self:getSounds().reboot_end, x=x0,y=y0} )                
            	end

				if traits.firewallShield and traits.mainframe_ice > 0 then
					traits.shields = 1
				end	

				if traits.unArmor then 
					traits.armor = 0
					traits.unArmor = false 
				end 

                if self.activate then                	
                    traits.mainframe_status = "inactive"
                    if traits.mainframe_status_old and traits.mainframe_status_old == "active" and self:canActivate( sim ) then
                    	self:activate( sim )
                	end
                else
                    traits.mainframe_status = "active"
                    self._sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )
                end

                -- enable Null zone 
				if traits.mainframe_suppress_rangeMax then					
					if self:getPlayerOwner():isNPC() then
						traits.mainframe_suppress_range = traits.mainframe_suppress_rangeMax
						sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )	
					end
				end	

                if sim:getPC():hasSeen( self ) then
				    sim:getPC():glimpseUnit( sim, self:getID() )
                end
            end
        end
    end

    if traits.patrolObserved then
        traits.patrolObserved = nil
        self:destroyTab()
    end

    if not traits.isDrone or self:getPlayerOwner():isNPC() then 
    	traits.sneaking = self:getUnitData().traits.sneaking
    end

    if traits.investigated then
    	traits.investigated = true
	end
    
    if sim:getCurrentPlayer() == self:getPlayerOwner() then
	    if traits.mpMax then
		    traits.mp = self:getMPMax()
            traits.netDownlinkMp = nil
            traits.mpUsed = nil
            if self:getPlayerOwner() ~= nil and self:getPlayerOwner() == sim:getPC() then 
        	    sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )
            end 
	    end

        traits.prismBonus = nil -- augment_prism_2.
        traits.tonyBonus = nil -- augment_tony_2.

		if sim:isVersion("0.17.5") then
			if self:getPlayerOwner() ~= sim:getPC() then
				self:tickKO( sim )
			end
		else 
			self:tickKO( sim )
		end
	end

	if traits.switched and not traits.unlocked then
		traits.switched = nil		
		traits.mainframe_status = "active"	
		local x0,y0 = self:getLocation()
		sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=traits.switch_reset_text,x=x0,y=y0,color={r=1,g=1,b=41/255,a=1}, skipQue=true} )
		self:setSwitchStage(sim,"fail")
	end	
end

function simunit:getName( )
	return self._unitData.name
end

function simunit:setLocation( x, y )
	self._x, self._y = x, y
end

function simunit:getNumSkills(  )
	return #self._skills
end

function simunit:removeAbility( abilityID )
	local remove = {}
	for i,ability in pairs( self._abilities )do
		if ability._abilityID == abilityID then
			table.insert(remove,i)
		end
	end
	for i,idx in ipairs(remove)do
		table.remove(self._abilities,idx)
	end
end

function simunit:giveAbility( abilityID, abilityIndex)
	if not self:hasAbility( abilityID ) then
        if self._abilities == nil then
            self._abilities = {}
        end
		local ability = simability.create( abilityID )
        if ability then
        	-- this check is because version 0.17.4 had abilities in a different order. Children were added before abilites, but that has been reversed. 
        	if abilityIndex then
		    	table.insert( self._abilities, abilityIndex, ability )
			else
				table.insert( self._abilities, ability )
			end
		    if self:isValid() then 
			    ability:spawnAbility( self._sim, self )
		    end
        end
	end
end

function simunit:giveDebuff( abilityID )
	local ability = simability.create( abilityID )
	table.insert( self._abilities, ability )
	if self:isValid() then 
		ability:spawnAbility( self._sim, self )
	end
end

function simunit:giveBuff( abilityID )
	local ability = simability.create( abilityID )
	table.insert( self._abilities, ability )
	if self:isValid() then 
		ability:spawnAbility( self._sim, self )
	end
end

function simunit:giveSkill( skillID )
	if not self:hasSkill( skillID ) then
		local skill = simskill( skillID )
		table.insert( self._skills, skill )
	end
end

function simunit:createTab( headerTxt, bodyTxt )
    assert( headerTxt and bodyTxt )
    self._tab = { headerTxt, bodyTxt }
    self._sim:dispatchEvent( simdefs.EV_UNIT_TAB, self )
end

function simunit:destroyTab()
    if self._tab then
        self._tab = nil
        self._sim:dispatchEvent( simdefs.EV_UNIT_TAB, self )
    end
end

function simunit:getTab()
    return self._tab
end

function simunit:getLocation( )
	return self._x, self._y
end

function simunit:onDamage( damage )
	self:getTraits().wounds = self:getTraits().wounds + damage

	if self:getTraits().wounds >= self:getTraits().woundsMax then
		self:getTraits().dead = true		
	end

	if self:isDead() then
		if self:getTraits().canBeCritical then					
			self:setKO( self._sim, 3 )
            self._sim:dispatchEvent( simdefs.EV_SHOW_MODAL_REWIND )
            if self._sim:getTags().rewindsLeft > 0 and not self._sim:getPC():isNeutralized( self._sim ) then    	
            	if self._sim:getCurrentPlayer():isPC() then
            		self._sim:dispatchEvent( simdefs.EV_BLINK_REWIND )
        		else
					self._sim:getTags().blinkAtStartTurn = true
				end            	
        	end
		elseif self:getTraits().regenerative_nanocells then 
			self:setKO( self._sim, 1 )
		else 
			self:killUnit( self._sim )	
		end
	end
end


function simunit:onWarp(sim, oldcell, cell)
	if self:getPlayerOwner() and self:getPlayerOwner():isNPC() and self:getTraits().isGuard then
		for i,checkUnit in pairs( sim:getAllUnits() ) do
			if checkUnit:getTraits().hologram then
				local x0,y0 = self:getLocation()
				local x1,y1 = checkUnit:getLocation()
				if x0 and y0 and x1 and y1 then
					local distance = mathutil.dist2d( x0, y0, x1, y1 )
					local checkDist = 2
					if not self:getTraits().hasHearing then
						checkDist = 1
					end
					if distance < checkDist then
						local brain = self:getBrain()
						if brain then
							brain:getSenses():addInterest( x1, y1, simdefs.SENSE_HEARING, simdefs.REASON_FOUNDOBJECT, checkUnit)
						end
					end
				end

			end
		end
	end
end
	
function simunit:updateSeenUnits( units )
	local tmp = nil
	if self._seenUnits == nil then
		tmp = {}
	else
		tmp = util.tdupe( self._seenUnits )
	end

	util.tdiff( tmp, units,
		function( seenUnit )
			if self:isValid() then
				local cell = self._sim:getCell( seenUnit:getLocation() )
				self:removeSeenUnit( seenUnit, cell, cell )
			end
		end,
		function( seeUnit )
			if self:isValid() then
				self:addSeenUnit( seeUnit )
			end
		end )
end

function simunit:removeSeenUnit( unit, oldcell, newcell )
	--simlog( "VISCH: %s [%d] no longer sees %s [%d]", self:getName(), self:getID(), unit:getName(), unit:getID() )
	assert( not unit:isGhost() )
	if not array.find( self._seenUnits, unit ) then
		return
	end
	array.removeElement( self._seenUnits, unit )
	if unit:getTraits().sightable then
		self._sim:triggerEvent( simdefs.TRG_UNIT_DISAPPEARED, { seerID = self:getID(), unit = unit, from_cell = oldcell, to_cell = newcell } )
	end
end

function simunit:addSeenUnit( unit )
	if self._seenUnits == nil then
		self._seenUnits = {}
	end
	if array.find( self._seenUnits, unit ) then
        return
    end
	--simlog( "VISCH: %s [%d] saw %s [%d]\n%s", self:getName(), self:getID(), unit:getName(), unit:getID(), debug.traceback() )
	assert( not unit:isGhost() )
	table.insert( self._seenUnits, unit )
	if unit:getTraits().sightable then
        if not self:isPC() and simquery.isEnemyAgent( self:getPlayerOwner(), unit ) then
            self._sim:getStats():incStat( "times_seen" )
        end
		self._sim:triggerEvent( simdefs.TRG_UNIT_APPEARED, { seerID = self:getID(), unit = unit } )
	end
end

function simunit:getSeenUnits()
    return self._seenUnits
end

function simunit:canBeInterrupted()
	if self:getTraits().interrupted then
		return false
	end
	return self:getTraits().movePath or self:getTraits().modifyingExit or self:getTraits().lookingAround or self:getTraits().throwing
end

function simunit:interruptMove( sim, unitSeen )
	if self:canBeInterrupted() then
		self:getTraits().interrupted = true

		if self:getSpeech() then
			sim:emitSpeech( self, speechdefs.EVENT_INTERRUPTED )
		end	

		sim:dispatchEvent( simdefs.EV_UNIT_INTERRUPTED, {unitID=self._id, unitSeen=unitSeen})
	end
end

-----------------------------------------------------
-- Interface functions

function simunit.createUnit( unitData, sim, ... )


	if sim and sim:isVersion("0.17.5") and unitData.upgradeOverride then
		unitData = unitdefs.lookupTemplate( unitData.upgradeOverride )
	end

	local t = util.prototypeInit( simunit )

	t._sim = sim
	t._unitData = unitData

	if sim then
		t._id = sim:nextID()
	end

	if unitData then
		-- Initialize traits from defaults
		if unitData.traits then

			if (not sim or sim:isVersion("0.17.5")) and  unitData.traits_17_5 then
				t._traits = util.tcopy( unitData.traits_17_5 )				
			else
				t._traits = util.tcopy( unitData.traits )
			end
		end	

		if t._traits and sim then 
			if sim:getParams().campaignDifficulty == simdefs.NORMAL_DIFFICULTY and unitData.beginnerTraits then 
				t._traits = util.tmerge( t._traits, unitData.beginnerTraits )
			end
		end

		if unitData.sounds then
			t._sounds = util.tcopy( unitData.sounds )		
		end	

        if unitData.patrolPath then
            t._traits.patrolPath = {}
            for i, coord in ipairs(unitData.patrolPath) do
                table.insert( t._traits.patrolPath, { x = coord[1], y = coord[2] } )
            end
        end

		-- Create ability instances.
		if unitData.abilities then
			for i,abilityID in ipairs(unitData.abilities) do
                t:giveAbility( abilityID )
			end
		end

		-- Create skill instances
		if unitData.skills then 
			t._skills = {}
			for i,skillData in ipairs(unitData.skills) do
				if type(skillData) == "string" then
					local level = 1
					if unitData.startingSkills then
						level = unitData.startingSkills[ skillData ] or 1
					end
					table.insert( t._skills, simskill( skillData, level, sim, t ) )
				else
					table.insert( t._skills, simskill( skillData.skillID, skillData.level, sim, t ) )
				end
			end
		end
		t._abilityIndex = 1
		-- Create children specified by unit definition and instance them as child units.
		if unitData.children then
			for i,unitDataChild in ipairs(unitData.children) do
				if type(unitDataChild) == "string" then
					unitDataChild = unitdefs.lookupTemplate( unitDataChild )
				end

				local childUnit = simfactory.createUnit( unitDataChild, sim )
				t:addChild( childUnit )
                if childUnit:getTraits().installed then
                    t:doAugmentUpgrade( childUnit, true )
                end
            end
		end

		inventory.autoEquip( t )

		if unitData.dropTable then
			local dropTable = weighted_list( unitData.dropTable )
			for i = 1, (unitData.lootCount or 1) do
				local w = sim:nextRand( 1, dropTable:getTotalWeight() )
				local template = unitdefs.lookupTemplate( dropTable:getChoice( w ) )
				if template then
					local childUnit = simfactory.createUnit( template, sim )
					t:addChild( childUnit )
				end
			end
		end

		if unitData.anarchyDropTable then
			local dropTable = weighted_list( unitData.anarchyDropTable )
			for i = 1, (unitData.lootCount or 1) do
				local w = sim:nextRand( 1, dropTable:getTotalWeight() )
				local template = unitdefs.lookupTemplate( dropTable:getChoice( w ) )
				if template then
					local childUnit = simfactory.createUnit( template, sim )
					childUnit:getTraits().anarchySpecialItem = true
					t:addChild( childUnit )
				end
			end
		end		


		if unitData.traits.tier2safe then
			if sim:isVersion("0.17.5") then
				local template = unitdefs.lookupTemplate( "item_corpdata_extra" )
				if template then
					local childUnit = simfactory.createUnit( template, sim )
					childUnit:getTraits().largeSafeMapIntel = true
					t:addChild( childUnit )
					childUnit:getTraits().newLocations = { {} }
				end	
			end
		end


		t._facing = unitData.facing or DEFAULT_FACING

		if unitData.voices and next(unitData.voices) and not t._traits.voice then
			t._traits.voice = unitData.voices[sim:nextRand(1, #unitData.voices) ]
		end
		
		if unitData.brain and not EDITOR then
			t._brain = simfactory.createBrain(unitData.brain, sim, t)
		end

	end

    t._modifiers = modifiers( t._traits )

    if sim and t._traits.mainframe_program == nil and mainframe.canHaveDaemon( t ) then
        local daemonList = sim:getIcePrograms()
        if t._traits.mainframe_always_daemon_spawn and daemonList:getCount() > 0 then
            t._traits.mainframe_program = daemonList:getChoice( sim:nextRand( 1, daemonList:getTotalWeight() ))
        end
    end

    for i, interface in ipairs({...}) do
        util.tmerge( t, util.tcopy( interface ))
    end

	return t
end

simfactory.register( simunit.createUnit )

return simunit
