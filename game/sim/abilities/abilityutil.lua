local array = include( "modules/array" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local mui_tooltip = include( "mui/mui_tooltip" )
local mui_util = include( "mui/mui_util" )
local inventory = include("sim/inventory")

local abilityutil = {}

abilityutil.hotkey_tooltip = class( mui_tooltip )

function abilityutil.hotkey_tooltip:init( ability, sim, abilityOwner, tooltip )
	local enabled, reason = ability:canUseAbility( sim, abilityOwner )
	if reason then
		mui_tooltip.init( self, util.toupper( ability.name ), string.format( "%s\n<tthotkey><c:FF0000>%s</>", tooltip, reason ), ability.hotkey )
	else
		mui_tooltip.init( self, util.toupper( ability.name ), tooltip, ability.hotkey )
	end
end


abilityutil.overwatch_tooltip = class( abilityutil.hotkey_tooltip )

function abilityutil.overwatch_tooltip:init( hud, ... )
	abilityutil.hotkey_tooltip.init( self, ... )
end

function abilityutil.overwatch_tooltip:activate( screen )
	abilityutil.hotkey_tooltip.activate( self, screen )
end

function abilityutil.onAbilityTooltip( self, hud, sim, abilityOwner, abilityUser, ... )
	local tooltip = util.tooltip( hud._screen )
	local section = tooltip:addSection()
	local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, ... )
    if abilityOwner:getUnitData().onWorldTooltip then
	    abilityOwner:getUnitData().onWorldTooltip( section, abilityOwner )
    end
	if not canUse and reason then
		section:addRequirement( reason )
	end
	return tooltip
end

function abilityutil.formatToolTip( header, body, apCost )
	local txt = string.format( "<ttheader>%s\n<ttbody>%s", util.toupper(header), body )
	txt = txt .. "</>"
	return txt
end

function abilityutil.createShotDamage( unit, userUnit )
	local dmgt =
	{		
		unitID = unit:getID(),	
		sound = unit:getUnitData().sounds.shoot,	
		shots = unit:getTraits().shots or 1,
	}
	return dmgt 
end

function abilityutil.doReload( sim, weaponUnit )
    local userUnit = weaponUnit:getUnitOwner()

	local ammoConsumed = false 
	if weaponUnit:getTraits().infiniteAmmo then
		ammoConsumed = true
	elseif weaponUnit:getTraits().noReload then 
		ammoConsumed = false 
	elseif userUnit then
		local ammoClip = array.findIf( userUnit:getChildren(), function( u ) return u:getTraits().ammo_clip ~= nil end )
		if ammoClip then
			ammoClip:getTraits().ammo_clip = ammoClip:getTraits().ammo_clip - 1
			if ammoClip:getTraits().ammo_clip <= 0 then
				inventory.trashItem( sim, userUnit, ammoClip )
			end
			ammoConsumed = true
		end
	end

	if ammoConsumed then
		weaponUnit:getTraits().ammo = weaponUnit:getTraits().maxAmmo
        if userUnit then
		    local x0, y0 = userUnit:getLocation()		    
		    sim:emitSound( { path = weaponUnit:getUnitData().sounds.reload, range = simdefs.SOUND_RANGE_0 }, x0, y0, userUnit )
            if weaponUnit == simquery.getEquippedGun( userUnit ) then
		        sim:dispatchEvent( simdefs.EV_UNIT_RELOADED, { unit = userUnit } )
		    end
        end
	end

	return ammoConsumed
end
	
function abilityutil.doRecharge( sim, itemUnit )
    local userUnit = itemUnit:getUnitOwner()

	local ammoConsumed = false 
	if itemUnit:getTraits().infiniteAmmo then
		ammoConsumed = true
	elseif itemUnit:getTraits().noReload then 
		ammoConsumed = false 
	elseif userUnit then
		local ammoClip = array.findIf( userUnit:getChildren(), function( u ) return u:getTraits().ammo_clip ~= nil end )
		if ammoClip then
			ammoClip:getTraits().ammo_clip = ammoClip:getTraits().ammo_clip - 1
			if ammoClip:getTraits().ammo_clip <= 0 then
				inventory.trashItem( sim, userUnit, ammoClip )
			end
			ammoConsumed = true
		end
	end

	if ammoConsumed then

		if itemUnit:getTraits().usesCharges then
			itemUnit:getTraits().charges = itemUnit:getTraits().chargesMax
		else		
			itemUnit:getTraits().cooldown = math.max(itemUnit:getTraits().cooldown - 2,0)
		end

        if userUnit then
		    local x0, y0 = userUnit:getLocation()
		    sim:emitSound( { path = "SpySociety/Actions/recharge_item", range = simdefs.SOUND_RANGE_0 }, x0, y0, userUnit )
        end
	end

	return ammoConsumed
end

-- Returns false if the required ammo/resources are not available.
function abilityutil.canConsumeAmmo( sim, weaponUnit, consume )
   	if weaponUnit:getTraits().ammo then
        if weaponUnit:getTraits().ammo <= 0 then
            return false, STRINGS.UI.REASON.NO_AMMO
        end
	end

    if weaponUnit:getTraits().cooldown then
        if weaponUnit:getTraits().cooldown > 0 then
            return false, util.sformat( STRINGS.UI.REASON.COOLDOWN, weaponUnit:getTraits().cooldown )        
        end
    end

	if weaponUnit:getTraits().energyWeapon == "used" then
        return false, STRINGS.UI.REASON.ALREADY_USED

	end

	if weaponUnit:getTraits().pwrCost then
        if weaponUnit:getPlayerOwner():getCpus() < weaponUnit:getTraits().pwrCost then
            return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR, STRINGS.UI.FLY_TXT.NOT_ENOUGH_PWR
        end
	end

    return true
end

function abilityutil.checkRequirements( abilityOwner, abilityUser )
	if abilityOwner:getRequirements() then 
		for skill,level in pairs( abilityOwner:getRequirements() ) do
			if not abilityUser:hasSkill(skill, level) and not abilityUser:getTraits().useAnyItem then 

            	local skilldefs = include( "sim/skilldefs" )
            	local skillDef = skilldefs.lookupSkill( skill )            	

				return false, string.format( STRINGS.UI.TOOLTIP_REQUIRES_SKILL_LVL, util.toupper(skillDef.name), level )
			end 
		end
	end

    return true
end

return abilityutil