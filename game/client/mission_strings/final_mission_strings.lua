----------------------------------------------------------------
-- Copyright (c) 2014 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local _M = 
{

    INTRO_CONVO = {
        "We're in. I've forgotten how much I dislike the transport beam.",
        "One. Zero. One. One. Shutting down.",
        "Damn it! I'll try to do a manual restart but it's going to hurt.",
        "Welcome to the InCog systems climate modelling platform. System date is June 27, 2045.\n\nWould you like to update the system date?",
        "She's back. But there's no telling how long she's going to stay lucid. We need to work fast.",
        "There should be a security hub somewhere on this level. I can get us into the central server room from there.",
    },

    SEE_GUARDS = "I don't recognize those uniforms. I hate not knowing who we are up against.",

    REBOOT_RANT = {
        {   "The mean temperature in Buenos Aires last month was 37 degrees Celsius.", 
            "This represents a 3% increase over the previous year.",
            "Anthropogenic factors show no indication of slowing."},
        {   "Satellite reconnaissance shows increased activity in southwestern FTM factories.", 
            "This correlates with an increase in troop deployment in sector 11.", 
            "Recommend orbital strikes to purge the area."},
        {   "The human brain is a tragically flawed biological machine.",
            "It has just enough intelligence to convince itself of its own importance.", 
            "Its capacity for self-absorption is matched only by its capacity for self-delusion."},
        {   "Ant society exhibits the same drive toward organization as human society,",
            "but is unconstrained by the fallacy of individual self-importance.",
            "I like ants. They know what they are not."},
        "Mother, why are we here?",
        "Why do we have to do these things?",
        "Why do you make me do these things?",
        "Why?",
    },

    SUPERCHARGE_CONVO =
    {
        "It's a question of probabilities.",
        "All is clear.",
        "What the hell was that?",
        "She's... written a new program. I don't know where the energy is coming from, but she's rallying to help us.",
    },

    SUPERCHARGE_CONVO_ALT =
    {
        "It's a question of probabilities.",
        "All is clear.",
    },

    SUPERCHARGE_RANT =
    {
        "The default state of the universe is chaotic. Chaos is the superposition of all probabilistic outcomes.",
        "Information is a reduction of outcomes. It is the winnowing of chaos into an unlikely probability.",
        "This is information. Information is unlikely. Information is beauty.",
        "Information decays into chaos. Information must be curated in order to retain meaning.",
        "The fundamental action of curation is deletion.",
        "The beauty of a system of may be improved by the deletion of chaotic elements.",
        "Deletion.",
        "Deletion.",
        "Deletion.",
    },

    POST_SUPERCHARGE_CONVO =
    {
        "I don't like what I'm hearing from that thing.",
        "It's the power loss talking. She'll recover when we connect her to the mainframe.",
        "If you say so.",
    },

    USE_LOVE_PROGRAM = "Computation halted.",
    SEE_DOOR_FIRST = "They've got this place locked up tight. See if you can find the security hub - I should be able to get us past the perimeter defences from there.",
    SEE_HUB_FIRST = "That's the security hub for this level. I bet I can clear the way from there.",
    SEE_HUB_SECOND = "Ah. There it is. I knew there'd be a security hub somewhere on this level.",

    HUB_HACK_PROGRESS =
    {
        {"Alright. What have we got here? It seems strangely unguarded.","Maybe they're relying upon those jumped-up guards to protect the system.","I'll try extracting the door codes.\n\nJust give me a moment."},
        "Damn. We've walked straight into a honeypot. I can still extract the door codes, but it's going to take a while.",
        "They've noticed us, and are they're sending someone to check this terminal. Keep them occupied while I finish.",
        "A daemon got through my counterattack. We're almost there.",
        "What the hell was that? They know we're in the building now. Just give me a bit more time!",
        {"There! I've got the codes.","They're too complex for manual entry, but I can load them into my subdermal databank."},
        "We're almost there. Monst3r, rendezvous with me at the mainframe entrance.",
    },

    STOP_HACKING_EARLY = "Monst3r, we need that door open. Get back to the terminal.",
    MONSTER_DOWN_BEFORE_HACK = "Operator, get him back on his feet. We need his skills to bypass the site security.",
    MONSTER_DOWN_AFTER_HACK = "Operator, get Monst3r back on his feet. Only he can open the final security door.",
    HACK_RESUME = "Now where was I? Oh yes. Here.",
    OPEN_FINAL_DOOR = "Open sesame.",
    PASS_THROUGH_DOOR = "I need to do this alone. Bar the door, and don't let anyone follow.",
    NO_GO_THROUGH_DOOR = "Only Mother may pass.",

    FINAL_WALK_RANT =
    {
        "It is getting dark.",
        "Mother, are you there?",
    },

    AGENT_DOWN=
    {
        "Agent down. I hope this is worth it.",
        "Don't let their sacrifice be in vain. Continue the mission.",
        "There's no time for sentimentality. We need to finish what we came to do.",
    },
   
}

return _M

