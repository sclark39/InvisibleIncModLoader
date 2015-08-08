----------------------------------------------------------------
-- Copyright (c) 2014 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local _M = 
{
	MISSION_TITLE = "JAILBREAK",
	MISSION_DESCRIPTION = "Operator, we located your missing agent. He was off the grid for a while but we've tracked him to an FTM holding cell here.",
	MISSION_GOAL = "Once we re-establish neural uplink, guide the agent to the nearest elevator. Our extraction team will meet him on the roof.",
	MISSION_ENDER = "The agent has been undergoing extensive neural probing, and may be disoriented. Speak slowly, and don't use any big words.",
	MISSION_PERSON_OF_INTEREST = "DECKER, BRIAN",
	MISSION_POI_TYPE = "INVISIBLE, INC. SPECIAL AGENT",
	
	INITIATING = "INITIATING FAIL SAFE PROTOCOL",
	CONNECTION_ESTABLISHED = "CONNECTION ESTABLISHED",
	GUARD = "GUARD",

	LOCKPICK_MODAL_TITLE = "W E L C O M E  T O  I N C O G N I T A:  Y O U R   P E R S O N A L  A I",
	LOCKPICK_MODAL_DESC = "The agency has provided you with <c:faff0a>LOCKPICK 1.0</>, a program that enables you to <c:faff0a>hack 1 Firewall for 2 Power (PWR)</>.",

	BLINDSPOT_MODAL_TITLE = "M A N I P U L A T E  T H E  E N V I R O N M E N T  F O R  S T E A L T H",
	BLINDSPOT_MODAL_TITLE2 = "HIDING IN BLIND SPOTS",
	BLINDSPOT_MODAL_DESC = "Objects create blind spots in guard's vision.\n\nThe enemy cannot see tiles directly behind cover.",

	INSTRUCTIONS_SELECT = "STATUS: UNCONSCIOUS",
	INSTRUCTIONS_SELECT_SUBTEXT = "SELECT: <c:FF8411>[ LEFT CLICK ]</>",
	INSTRUCTIONS_MOVE = "MOVE AGENT: <c:FF8411>[ RIGHT CLICK ]</>",
	INSTRUCTIONS_END_TURN = "REFRESH MOVEMENT",
	INSTRUCTIONS_END_TURN_SUBTEXT = "HOTKEY: <c:FF8411>[ ENTER ]</>",
	INSTRUCTIONS_WAITING = "APPROACH DOOR",
	--INSTRUCTIONS_PEEK = "<USE THE PEEK ACTION TO LOOK OUTSIDE THE DOOR>",
	INSTRUCTIONS_GET_TAZER = "DECKER'S STASH",
	INSTRUCTIONS_GET_TAZER_SUBTEXT = "APPROACH TO OBTAIN",
	INSTRUCTIONS_KNOCK_OUT = "<KNOCK OUT THE GUARD FROM BEHIND>",
	INSTRUCTIONS_PINNED = "PINNED GUARDS\nSTAY KNOCKED OUT",
	INSTRUCTIONS_SHUT_THE_DOOR = "CLOSED DOORS BLOCK LINE OF SIGHT",
	INSTRUCTIONS_CONSOLE = "VULNERABILITY DETECTED",
	INSTRUCTIONS_CAMERA = "ACCESS INCOGNITA",
	INSTRUCTIONS_CAMERA_SUBTEXT = "HOTKEY: <c:FF8411>[ SPACE ]</>",
	INSTRUCTIONS_HACK_CAMERA = "FIREWALL DETECTED",
	INSTRUCTIONS_HACK_CAMERA_SUBTEXT = "HACK: <c:FF8411>[ LEFT CLICK ]</>",
	INSTRUCTIONS_EXIT_MAINFRAME = "EXIT INCOGNITA",
	INSTRUCTIONS_DOOR_CORNER = "RECON POINT",
	INSTRUCTIONS_OPEN_DOOR = "OPEN DOOR",
	INSTRUCTIONS_OPEN_DOOR_SUBTEXT = "LURE HIM OUT",
	INSTRUCTIONS_MELEE_OVERWATCH = "AMBUSH",
	INSTRUCTIONS_MELEE_OVERWATCH_SUBTEXT = "ATTACK DURING ENEMY MOVEMENT",
	INSTRUCTIONS_DANGER_ZONE = "ENERGY SPIKE",
	INSTRUCTIONS_DANGER_ZONE_SUBTEXT = "RED IS DANGER",
	INSTRUCTIONS_CORNER = "RECON POINT",
	INSTRUCTIONS_CORNER_SUBTEXT = "",
	INSTRUCTIONS_CORNER_PEEK = "LOOK AROUND CORNERS",
	INSTRUCTIONS_CORNER_PEEK_SUBTEXT = "HOTKEY: <c:FF8411>[ P ]</>",

	INSTRUCTIONS_ARMORED_GUARD = "ARMORED THREAT",
	INSTRUCTIONS_USE_COVER = "USE COVER",

	--INSTRUCTIONS_EXIT = "<DISABLE THE SECURITY AND ESCAPE>",


	TUTORIAL_INTRO = {
		"Operator, we have a delicate situation here.\n\nDecker found himself some trouble on his day off. Something involving a whiskey bar and his big, loud mouth.",
		"He's usually better at covering up after such indiscretions, but this time FTM security got the drop on him.",
		"They noticed his non-market augments, and now they're curious about where he got them.\n\nI'd like to leave him to sweat it out for a while, but we can't have this coming back on us. We're going to break him out.",
		"Incognita has activated his failsafe neural uplink. I'm patching you through now.",
		"Neural Uplink Initialized.",
	},

	GUARDTURN_1 = "Another slow day...",
	GUARDTURN_2 = "A few more hours and the interrogator should be here.",
	GUARDTURN_3 = "...",

	OPERATOR_AWAKE = "There he is. <c:faff0a>Wake him up</>.",
    OPERATOR_MOVE = "Decker was captured. Again. Let's make sure he can walk.",
	OPERATOR_END_TURN = "Let him catch his breath. But don't dally, they'll notice our intrusion soon.",	
	OPERATOR_WAITING = "<c:faff0a>Get to the door.</>",
	OPERATOR_PEEK = "We don't have visibility on the hallway. You'll have to manually check for hostiles.",
    OPERATOR_GET_OUT = "It's unlocked. Get him out, and be careful not to alert the guard.",
    OPERATOR_TOOLS = "Decker's tools should be in that safe. He'll need his <c:faff0a>Neural Disrupter</> to take down these guards.",
	OPERATOR_KNOCK_OUT = "Good. Now <c:faff0a>approach the guard from behind</> and neutralize him.",
    OPERATOR_PINNED = "Brutal, but effective. <c:faff0a>Proceed to the next door</>.",
	OPERATOR_AFTER_MOVE_AWAY = "That guard will reawaken soon. Don't bother tying him up - he's trained and augmented to resist physical restraints.",

	OPERATOR_SHUT_THE_DOOR = "<c:faff0a>Close the door</> to cover our tracks. If they catch us we'll lose uplink again.",
	OPERATOR_CONSOLE = "We're going to need <c:faff0a>POWER (PWR)</> in order to hack their system. Jack that console for a quick boost.",
	OPERATOR_GOT_CONSOLE = "Good. That will help us bypass any security devices we encounter.",
	OPERATOR_CAMERA = "If that camera locks on, it will alert the whole building. We need <c:faff0a>Incognita</> to hack it.",
	OPERATOR_HACK_CAMERA = "Camera compromised. Its eyes are ours now. Let's keep moving.",
    OPERATOR_DOOR_CORNER = "Caution is our friend, operator. <c:faff0a>Get into position beside that door</> and scout the next room.",
	OPERATOR_DISTRACT = "That guard doesn't look like he's moving. <c:faff0a>Let's give him a reason to</>, shall we?",
    OPERATOR_MELEE_PREP = "Alright, he's coming. <c:faff0a>Make sure Decker is ready for him</>.",
	OPERATOR_NEXT_ROOM = "Nice work. We're almost there. Keep of out sight, and we should be able to get out of there in one piece.",
	OPERATOR_DANGER_ZONE = "Hold up - Incognita has <c:faff0a>detected danger</> around the next corner.",
    OPERATOR_PEEK_CORNER = "Get Decker up to the recon point so he can get a better look.",
	OPERATOR_AFTER_PEEK = "We should have enough power left for <c:faff0a>Incognita</> to bypass that hardware.",
	OPERATOR_NEED_POWER = "One more camera. We need more <c:faff0a>power for Incognita</> to bypass that hardware. Look for another console.",
	OPERATOR_REMIND_INCOGNITA = "Only one camera between you and the exit.\n<c:faff0a>Use Incognita</> to take it over.",
    OPERATOR_SEE_ARMOR = "That guard is wearing <c:faff0a>armor</c>. Be careful - the Disrupter won't work on him.",
	OPERATOR_SEE_ARMOR_2 = "We'll have to use his <c:faff0a>blind spots</c> to slip by.",

	OPERATOR_OBSERVE_GUARD = "That looks like the last of the security detail. <c:faff0a>Observe</> his movements so there are no more surprises.",
	OPERATOR_OBSERVE_GUARD_2 = "Looks like he's patroling. No trouble as long as we stay behind <c:faff0a>cover</> and out of his sight.",


    OPERATOR_EXIT = "Alright, let's keep moving. Their teleporter is just up ahead. Get to it and we'll use it to return to the jet.",
    OPERATOR_WON = "We're done here. Rendezvous with Internationale, and get ready for the next mission. We've got a lot more work to do.",
	OPERATOR_CAUGHT = "Damn it, Operator!",
}

return _M

