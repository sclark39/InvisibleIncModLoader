----------------------------------------------------------------
-- Copyright (c) 2014 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------



local _M = 
{
	CELLBLOCK_1 = "Look for a cellblock, there may be someone useful in there.",
	CELLBLOCK_2 = "There's a high-security detention center on-site. I wonder who they're keeping in there.",
	CELLBLOCK_3 = "They're keeping someone under detention here. It's high security, so they must be important.",
	CELLBLOCK_4 = "There is a detention facility on the grounds. Keep an eye open for our agents.",

	GENERIC_1 = "We're not sure what is in there, but take whatever you can find.",
	GENERIC_2 = "We need to rebuild our strength. Take anything that isn't nailed down.",
	GENERIC_3 = "Try to find as much intel and valuables as you can, and get back to the elevator.",
	GENERIC_4 = "You'll have a small window of opportunity to grab as much materiel as you can.",
	GENERIC_5 = "Find anything of value that isn't bolted to the floor. Incognita will erase all records of our intrusion.",
	GENERIC_6 = "See what you can find. You never know what they're keeping at these unlisted sites.",
	GENERIC_7 = "See what you can find, and get back before they know you've been there. No risks.",

	GUARDROOM_1 = "There's a guard station here. You may be able to secure some weapons.",
	GUARDROOM_2 = "Keep an eye out for an armory. We could certainly use the firepower.",
	GUARDROOM_3 = "There are a large number of guards on staff. Keep an eye out for unsecured weaponry.",
	GUARDROOM_4 = "This is a training facility for new security staff. You may be able to steal some unlicensed firearms.",

	NANOFAB_1 = "There is a nanofab on-site. You should be able to re-stock our supplies.",
	NANOFAB_2 = "Records indicate a nanofab somewhere in the facility. We'll hack access, but you'll still need credits.",
	NANOFAB_3 = "Keep your eyes peeled for a nanofab. You should be able to override its security clearance.",
	NANOFAB_4 = "We think there's a nanofab in the building. That should be your highest priority.",

	SECURITYROOM_1 = "They've got a high-security data vault here. It may provide us with new mission targets.",
	SECURITYROOM_2 = "They use this facility for debriefings. Potential mission information is probably stored on-site.",
	SECURITYROOM_3 = "Look for a secure holding facility. They use them to deprogram contractors - it's a good way to find new vulnerabilities.",
	SECURITYROOM_4 = "Watch for a secure holding cell. There should be extracted target information nearby.",

	SERVER_1 = "There's an unusually powerful server in the building. Don't miss it.",
	SERVER_2 = "There's a lot of data going through that place. Look for a central server.",
	SERVER_3 = "They're hiding a central server there. We could use that data.",
	SERVER_4 = "They're keeping an off-grid server here. Interesting.",
	SERVER_5 = "It looks like a secret software development lab. See if there's anything interesting on their central server.",

	VAULT_1 = "There's a vault on-site. Probably an executive slush-fund.",
	VAULT_2 = "This facility handles payroll for the entire region. Look for a large stash of credits.",
	VAULT_3 = "The local executive has been embezzling credits. Find the vault, and they are ours.",
	VAULT_4 = "There have been anomalous financial transactions coming from this facility. Keep your eyes peeled for a credit vault.",

	-- KEVIN, these next two are the new locations since you wrote the above lines

	CEOOFFICE_1 = "Upper Management is putting in some overtime. It's a good chance for us to pick his brain.",
	CEOOFFICE_2 = "A top financial assistant has been followed to this site. He should have vault access codes on him.",
	CEOOFFICE_3 = "The CFO of this facility should be busy in a chess match. Nab his vault codes while he is preoccupied",
	CEOOFFICE_4 = "The first class suite in this facility has been hosting a financial seminar. At least one of the speakers will be around afterwards, for a chat.",

	CYBERLAB_1 = "A high ranking operative will be receiving an augment installation in the morning. Maybe we can grab it first.",
	CYBERLAB_2 = "The lab at this location is extremely busy. It's likely they will have augment stock on hand.",
	CYBERLAB_3 = "Several augment designs are being developed at this laboratory. Anything past the prototype stage is likely going to be quite useful.",
	CYBERLAB_4 = "This augment lab has just received a large shipment for quality control checks. If you get in quick and quietly enough, they may not even realize any stock is missing.",


	MISSION_DESCRIPTION_1 = "The <Corporation> satellite network is having technical issues and has no visibility in this sector.",
	MISSION_ENDER_1 = "Keep a low profile - we don't want them to know we've been here.",

	MISSION_DESCRIPTION_2 = "They're rebooting their regional servers, and aren't recording the security telemetry from this installation.",
	MISSION_ENDER_2 = "Information is power, Operator, so try to get as much intel as you can find.",

	MISSION_DESCRIPTION_3 = "Operator, we've gained one-time access to the facility here.",
	MISSION_ENDER_3 = "Grab what you can, but don't take any unnecessary risks. Good luck.",

	MISSION_DESCRIPTION_4 = "Incognita says that there's something interesting in this building.",
	MISSION_ENDER_4 = "There's no benefit in making a ruckus, Operator. Be subtle.",

	MISSION_DESCRIPTION_5 = "There's a gap in the security coverage at this facility. We can get a team inside before they know any better.",
	MISSION_ENDER_5 = "They'll sense an intrusion as soon as you hit the floor, so don't dally.",

	MISSION_DESCRIPTION_6 = "This is a by-the-numbers infiltration, Operator. You will be going here.",
	MISSION_ENDER_6 = "Play it cautiously - there's no sense in risking valuable assets on a fishing expedition.",

	MISSION_DESCRIPTION_7 = "I can't believe how sloppy they've become. Look at the grid around this building",
	MISSION_ENDER_7 = "Grab as much as you can, but don't take any stupid risks. A healthy agent is far more valuable than the contents of any safe.",

	MISSION_DESCRIPTION_8 = "We need resources. They have resources. The mathematics are quite simple.",
	MISSION_ENDER_8 = "Just make sure we come out ahead on the balance sheet, Operator.",

	MISSION_DESCRIPTION_9 = "Bureaucracy is a beautiful thing. They're decommissioning this facility and they started with the security grid.",
	MISSION_ENDER_9 = "The chopper will touch down momentarily. Bring us back something nice, will you?",

	MISSION_DESCRIPTION_10 =  "There has to be a pattern to Corp behaviour. We'll crack it, but first we need supplies.",
	MISSION_ENDER_10 = "Try not to lose any agents, Operator. We're barely hanging on as is.",

	MISSION_DESCRIPTION_11 =  "It looks like we've found a hole in the security here",
	MISSION_ENDER_11 = "The window on this won't last long. Get out before they can get reinforcements on site.",
	
	FIRST_LEVEL = {
		"Bad news, Operator.\n\nThey caught us completely by surprise, so we have no firepower with us. The guards' weapons are genecoded to their owner and useless to us.\n\nWe're going to have to make do with what we can find along the way.",
		"We've beamed you through the security grid. You should be somewhere near the target, but you'll need to look for it.\n\nGet the list, and find a transport pad to escape.",
		"But be quick about it - they noticed a disturbance when we ported in, and their alarm level is already rising.",
	},



-- hostage in guard stations.
	OPERATOR_SEEHOSTAGE = "Look at this Operator, I think we've caught them mid interrogation.",
	HOSTAGE_CONVO1 = "You. You're not one of them. Who.. who are you?",	
	OPERATOR_HOSTAGE_CONVO1 = "Polnet show this courier is a missing persons report. His contractor has a reward for intact data recovery. Feel like being a good Samaritan, Operator?",
	OPERATOR_HOSTAGE_ESCAPE = "Good job, team. We should be able to stabilize him in the jet. I'm sure his contractor will be rather thankful.",	
	CENTRAL_HOSTAGE_DEATH = "Damn it! There goes any bonus. We will discuss this further in debriefing.",
	
	OPERATOR_ESCAPE_PRISONER = "The Prisoner is clear, good work Operator. His finders fee will be a nice boost.",
	OPERATOR_SEEPRISONER = "Incognita has detected a prisoner in one of the cells. Enemies of our enemies may be our friends, as they say.",

	PRISONER_CONVO1 = "I don't know who you are, but if you get me out of here, you won't regret it.",
	OPERATOR_PRISONER_CONVO1 = "Incognita has scanned his identity - he has wealthy benefactors. It may be worth our while to help him.",

	CONNECTION_BROKEN = "You went out of range. His port will be fused now. We won't be getting any codes this time.",
	STAY_CLOSE = "Stop! Move any further away from the target and you'll sever our connection permanently.", 
	TARGET_DIED = "You let the target die! What a wasted opportunity.", 
	INTERROGATE_START = "We are digging in his cerebral implant now, but it will take a few minutes. Stay close to the target so I can keep the scan running.",
	SCAN_1 = "Cerebral implant is transmitting. Begin deepening the scan.",
	SCAN_2 = "Interesting, he's had memetic defence training. This is going to be trickier than expected.",
	SCAN_3 = "Dammit! He got a signal out. Expect more company soon.",	
	SCAN_4 = "Incognita is in! We've broken him down now. Almost there, Operator.",
	SCAN_5 = "The data is starting to come in now. Just a little longer.",
	INTERROGATE_END = "We've got the vault passcodes. I've ejected a mem chip from his port. Grab it and get the hell out of there.",
	TARGET_RUNNING_AWAY = "Our cover is blown and the target is running. Stop him - If he gets to a security entrance we're going home empty-handed.",
	TARGET_GOT_AWAY = "Damn it, the target got away. Recall our agents, and try not to mess anything else up. What a wasted opportunity.",
	MOVE_INTO_RANGE = "He's down, move into range to begin the cerebral scan.",
	TARGET_WOKEUP = "Damn it, the target woke up during the scan. We'll be locked out now.",

	USED_VAULT_CODE = "They will change their codes after this. That one is useless to us now.",

	OPERATOR_SEEINTERROGATE = "The executive has been located. Disable him and get his cerebral implant ready for the interrogation.",

	OPERATOR_ESCAPE_AGENT = "%s is out, excellent work Operator.",
	OPERATOR_SEEAGENT = "Incognita has detected an agent currently logged as MIA. They would be an incredible asset if you can get them back on the team.",

	OPERATOR_SCANNER_DETECTED_1 = "Incognita has detected an ECCM signal. There must be one of FTM's powerful scanning devices in the complex.",
	OPERATOR_SCANNER_DETECTED_2 = "It'll detect your team's location each alarm level, make sure to shut it down.",
	OPERATOR_SCANNER_DETECTED_3 = "Good job, Operator. At least you won't need to worry about that one anymore.",

	CAUGHT_BY_CAMERA = "That camera will keep making things harder for us Operator. Incognita has a program to deal with it.",

	COMPILE_STARTED = "That's got it. The code has started compiling, let's hope it doesn't take too long to finish.",

    SITE_PLANS_HEADER = "Choose a target to search for",
    SITE_PLANS_BODY = "The terminal is loaded with information that can be used to find locations for future incursions, but it's all encrypted.\n\nWhile Incognita downloads a large chunk of encrypted data, you've got time to dig for a site of your choosing.",

	-- OBJECTIVE TITLES
    OBJ_DISABLE_TARGET = "Get near and disable the target",
	OBJ_BRAINSCAN = "Brain scan in progress",
	OBJ_STAYNEAR = "Stay near the exec",
    OBJ_SCANNER = "Disable the scanner",
    OBJ_DISABLE_DRAIN = "Disable the PWR reversal node",
    OBJ_GET_NEAR = "Get near the target to activate scan",
    OBJ_EXIT_PASSCARD = "Find the exit passcard and get out alive",

    SECONDARY_OBJECTIVE = "Find and steal corporate credits",
	OBJECTIVE = "Get out alive",

	OBJ_SERVERFARM = "Access the Server Farm",
	OBJ_SECURITY = "Locate the secure locker",
	OBJ_SECURITY_2 = "Investigate locker contents",
	OBJ_NANO_FAB = "Access the Nanofab Vestibule",
	OBJ_TERMINALS = "Locate the Executive Terminals",
	OBJ_DETENTION_CENTER = "Recon the Detention Center",
	OBJ_GUARD_OFFICE = "Locate the Guard Office",
	OBJ_VAULT = "Recon the Vault",	
	OBJ_CEO_OFFICE = "Locate the Financial Suite",	
	OBJ_CYBERLAB = "Locate the Cyberlab",	
	OBJ_CYBERLAB_2 = "Augment agent with Grafter",	
	OBJ_RESCUE_PRISONER = "Rescue the prisoner",
	OBJ_RESCUE_HOSTAGE = "Rescue the hostage",
	OBJ_RESCUE_AGENT = "Rescue %s",

	OBJ_RETRIEVE_ACCESS_CODE = "Retrieve the access code",
	OBJ_RETRIEVE_MAP_LIST = "Retrieve encrypted data",

	-- OTHER
	INTERROGAGE_TARGET ="INTERROGATE TARGET",
	PRISONER_NAME = "Prisoner KSC2-303",

	HOSTAGE_NAME = "Hostage XX1",	

	AGENT_DOWN = {
		
		"That agent's down but not out. Give them a shot of medgel and they'll be good as new.", 
		"Agent down, Operator. Don't even think of leaving them behind.", -- REMOVED from scripts
		"We've lost contact with an agent. Move in our other assets to recover.", 
		"Damn it! We can't afford that loss. I don't care if you have to drag them to the elevator - do NOT leave anyone behind.", -- REMOVED from scripts
		"Shots fired. Agent down. Are you cracking under the pressure, Operator?", 
		"We don't want the corps interrogating our agents. Do not leave them bleeding on the field.", 
		"Agent down - use medgel to get them back on their feet.", 
		"Pay attention, Operator! We can't afford casualties!", 
		"Are you even paying attention? You let them walk right into that!", -- REMOVED from scripts
		"OK... It's OK. We can recover from this. Get some medgel into that agent and get them out of there.", 
		"Damn it, they've been tagged. New priority, Operator - begin evac procedures.",-- REMOVED from scripts
		"Do you know how much time and money has gone into that agent's training? I won't have you wasting company resources that way. Get them back to the jet!", 
		"Get that agent back on their feet, Operator! We need all hands on deck.",
		"Find some medgel and get get them going again.",-- REMOVED from scripts
		"Damn it, Operator. Be more careful with our assets!", 
		"We don't leave agents in the field, Operator. Get them back on their feet or drag them to the exit.", 
		"Agent down. They're stable, for now. Get some medgel into them or drag them back to the jet.",
		"Damn it, an agent has been compromised. Don't let them fall into enemy hands.", 
		"Agent down. Repeat, agent down. Your new priority should be recovery. We can't afford to lose any more personnel.", 
		"Operator! You are playing with people's lives here. Get that agent back on their feet!", 
	}
}

return _M

