----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local npc_abilities = include( "sim/abilities/npc_abilities" )
local passive_abilities = include( "sim/abilities/passive_abilities" )
local mainframe_abilities = include( "sim/abilities/mainframe_abilities" )

------------------------------------------------------------------------------------------
-- Specialized tooltip definitions


local _abilities =
{
	activate_locked_console = include("sim/abilities/activate_locked_console"), 
	activate_final_console = include("sim/abilities/activate_final_console"), 
	alarmCPU = include("sim/abilities/alarmCPU"),
	carryable = include("sim/abilities/carryable"),
	centralaugment = include("sim/abilities/centralaugment"),
	decker_2_augment = include("sim/abilities/decker_2_augment"),
	console_lvl = include("sim/abilities/console_lvl"),
	deployable = include("sim/abilities/deployable"),
	disarmtrap = include("sim/abilities/disarmtrap"),
	equippable = include("sim/abilities/equippable"),
	escape = include("sim/abilities/escape"),
	generateCPU = include("sim/abilities/generateCPU"),
	hostage_rescuable = include("sim/abilities/hostage_rescuable"),
	icebreak = include("sim/abilities/icebreak"),
	scandevice = include("sim/abilities/scandevice"),
	manualHack = include("sim/abilities/manualHack"),
	installAugment = include("sim/abilities/installAugment"),
	jackin = include("sim/abilities/jackin"),
	jackin_charge = include("sim/abilities/jackin_charge"),
	jackin_root_console = include("sim/abilities/jackin_root_console"),
	melee = include("sim/abilities/melee"),
	meleeOverwatch = include("sim/abilities/meleeOverwatch"),
	moveBody = include("sim/abilities/moveBody"),
	observePath = include("sim/abilities/observePath"),
	open_detention_cells = include("sim/abilities/open_detention_cells"),
	open_security_boxes = include("sim/abilities/open_security_boxes"),
	overwatch = include("sim/abilities/overwatch"),
	overwatchMelee = include("sim/abilities/overwatchMelee"),
	paralyze = include("sim/abilities/paralyze"),
	peek = include("sim/abilities/peek"),
	prime_emp = include("sim/abilities/prime_emp"),
	readable = include("sim/abilities/readable"),
	reload = include("sim/abilities/reload"),
	recharge = include("sim/abilities/recharge"),
	sprint = include("sim/abilities/sprint"),
	doorMechanism = include("sim/abilities/doorMechanism"),
	shootOverwatch = include("sim/abilities/shootOverwatch"),
	shootSingle = include("sim/abilities/shootSingle"),
	showItemStore = include("sim/abilities/showItemStore"),
	stealCredits = include("sim/abilities/stealCredits"),
	useAugmentMachine = include("sim/abilities/useAugmentMachine"),
	useInhibitorCharger = include("sim/abilities/useInhibitorCharger"),
	usable = include("sim/abilities/usable"),
	usb_upload = include("sim/abilities/usb_upload"),
	useInvisiCloak = include("sim/abilities/useInvisiCloak"),
	use_injection = include("sim/abilities/use_injection"),
	use_medgel = include("sim/abilities/use_medgel"),
	use_stim = include("sim/abilities/use_stim"),
	use_aggression = include("sim/abilities/use_aggression"),
	wireless_scan = include("sim/abilities/wireless_scan"),
	throw = include("sim/abilities/throw"),
	breakDoor = include("sim/abilities/breakDoor"),
	install_incognita = include("sim/abilities/install_incognita"),
	lastWords = include("sim/abilities/lastWords"),
	compile_software = include("sim/abilities/compile_software"),
	disguise = include("sim/abilities/disguise"),
}

local function lookupAbility( abilityID )
	assert( abilityID )
	return _abilities[abilityID] or npc_abilities[abilityID] or passive_abilities[abilityID] or
			mainframe_abilities[abilityID]
end


return
{
	lookupAbility = lookupAbility,
	_abilities = _abilities,
}

