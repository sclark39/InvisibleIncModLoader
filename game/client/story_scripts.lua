
local util = include( "client_util" )

local FINAL_LEVEL_SCRIPT = 10000

--per-character UI defs. Call these to represent individual lines
local function Central(text, voice, timing)
    return {
        text = text or "",
        anim = "portraits/central_face",
        name = STRINGS.UI.CENTRAL_TITLE,
        voice = voice,
        timing = timing,
        delay = 0.25,
    }    
end

local function Monster(text, voice)
    return {
        text = text,
        anim = "portraits/monst3r_face",
        name = STRINGS.UI.MONST3R_TITLE,
        voice = voice,
    }    
end

local function Incognita(text, voice)
    return {
        text = text,
        anim = "portraits/incognita_face",
        name = STRINGS.UI.INCOGNITA_TITLE,
        voice = voice,
    }    
end

local function Taswell(text, voice)
    return {
        text = text,
        img = "gui/profile_icons/taswell.png",
        --anim = "portraits/incognita_face",
        name = STRINGS.UI.TASWELL_TITLE,
        voice = voice,
    }    
end



-- the actual story scripts
local STORY_SCRIPTS_DEFAULT = 
{

    Central = Central,
    Monster = Monster,
    Incognita = Incognita,
    Taswell = Taswell,
    FINAL_LEVEL_SCRIPT = FINAL_LEVEL_SCRIPT,

    MONST3RSHOP = 
    {

        --ryan davis easter egg
        TASWELL=
        {
            {Taswell(STRINGS.UI.TASWELL_QUOTE)},
            {Taswell(STRINGS.UI.TASWELL_INFO)},
        },

        -- When Monster has nothing to sell
        OPEN_NO_SPECIALS=
        {
            {Monster(STRINGS.UI.MONST3R.OPEN_NO_SPECIALS[1],"SpySociety/VoiceOver/Monst3r/Shop/OpenNoSpecial_1")},
            {Monster(STRINGS.UI.MONST3R.OPEN_NO_SPECIALS[2],"SpySociety/VoiceOver/Monst3r/Shop/OpenNoSpecial_2")},
            {Monster(STRINGS.UI.MONST3R.OPEN_NO_SPECIALS[3],"SpySociety/VoiceOver/Monst3r/Shop/OpenNoSpecial_3")},
        },

        OPEN_SPECIAL =
        {
            {Monster(STRINGS.UI.MONST3R.OPEN_SPECIAL[1],"SpySociety/VoiceOver/Monst3r/Shop/OpenSpecial_1")},
            {Monster(STRINGS.UI.MONST3R.OPEN_SPECIAL[2],"SpySociety/VoiceOver/Monst3r/Shop/OpenSpecial_2")},
            {Monster(STRINGS.UI.MONST3R.OPEN_SPECIAL[3],"SpySociety/VoiceOver/Monst3r/Shop/OpenSpecial_3")},
            
            --[[{Monster(STRINGS.UI.MONST3R.OPEN_SPECIAL[4],"SpySociety/VoiceOver/Monst3r/Shop/OpenSpecial_4")},
            {Monster(STRINGS.UI.MONST3R.OPEN_SPECIAL[5],"SpySociety/VoiceOver/Monst3r/Shop/OpenSpecial_5")},
            {Monster(STRINGS.UI.MONST3R.OPEN_SPECIAL[6],"SpySociety/VoiceOver/Monst3r/Shop/OpenSpecial_6")},
            {Monster(STRINGS.UI.MONST3R.OPEN_SPECIAL[7],"SpySociety/VoiceOver/Monst3r/Shop/OpenSpecial_7")},--]]
       },

        SELL_ITEM =
        { 
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[1],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_1")},
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[2],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_2")},
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[3],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_3")},
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[4],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_4")},
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[5],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_5")},
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[6],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_6")},
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[7],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_7")},
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[8],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_8")},
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[9],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_9")},
            {Monster(STRINGS.UI.MONST3R.SELL_ITEM[10],"SpySociety/VoiceOver/Monst3r/Shop/SellItem_10")},
        },

        BUY_ITEM =
        {
            {Monster(STRINGS.UI.MONST3R.BUY_ITEM[1],"SpySociety/VoiceOver/Monst3r/Shop/BuylItem_1")},
            {Monster(STRINGS.UI.MONST3R.BUY_ITEM[2],"SpySociety/VoiceOver/Monst3r/Shop/BuylItem_2")},
            {Monster(STRINGS.UI.MONST3R.BUY_ITEM[3],"SpySociety/VoiceOver/Monst3r/Shop/BuylItem_3")},
            {Monster(STRINGS.UI.MONST3R.BUY_ITEM[4],"SpySociety/VoiceOver/Monst3r/Shop/BuylItem_4")},
            {Monster(STRINGS.UI.MONST3R.BUY_ITEM[5],"SpySociety/VoiceOver/Monst3r/Shop/BuylItem_5")},
            {Monster(STRINGS.UI.MONST3R.BUY_ITEM[6],"SpySociety/VoiceOver/Monst3r/Shop/BuylItem_6")},
            {Monster(STRINGS.UI.MONST3R.BUY_ITEM[7],"SpySociety/VoiceOver/Monst3r/Shop/BuylItem_7")},
            {Monster(STRINGS.UI.MONST3R.BUY_ITEM[8],"SpySociety/VoiceOver/Monst3r/Shop/BuylItem_8")},
            {Monster(STRINGS.UI.MONST3R.BUY_ITEM[9],"SpySociety/VoiceOver/Monst3r/Shop/BuylItem_9")},
        },

        NOBUY =
        {
            {Monster(STRINGS.UI.MONST3R.NOBUY[1],"SpySociety/VoiceOver/Monst3r/Shop/NoBuy_1")},
            {Monster(STRINGS.UI.MONST3R.NOBUY[2],"SpySociety/VoiceOver/Monst3r/Shop/NoBuy_2")},
            {Monster(STRINGS.UI.MONST3R.NOBUY[3],"SpySociety/VoiceOver/Monst3r/Shop/NoBuy_3")},
            {Monster(STRINGS.UI.MONST3R.NOBUY[4],"SpySociety/VoiceOver/Monst3r/Shop/NoBuy_4")},
            {Monster(STRINGS.UI.MONST3R.NOBUY[5],"SpySociety/VoiceOver/Monst3r/Shop/NoBuy_5")},
            {Monster(STRINGS.UI.MONST3R.NOBUY[6],"SpySociety/VoiceOver/Monst3r/Shop/NoBuy_6")},
            {Monster(STRINGS.UI.MONST3R.NOBUY[7],"SpySociety/VoiceOver/Monst3r/Shop/NoBuy_7")},
        },

        NOSELL =
        {
            {Monster(STRINGS.UI.MONST3R.NOSELL[1],"SpySociety/VoiceOver/Monst3r/Shop/NoSell_1")},
            {Monster(STRINGS.UI.MONST3R.NOSELL[2],"SpySociety/VoiceOver/Monst3r/Shop/NoSell_2")},
            {Monster(STRINGS.UI.MONST3R.NOSELL[3],"SpySociety/VoiceOver/Monst3r/Shop/NoSell_3")},
            {Monster(STRINGS.UI.MONST3R.NOSELL[4],"SpySociety/VoiceOver/Monst3r/Shop/NoSell_4")},
            {Monster(STRINGS.UI.MONST3R.NOSELL[5],"SpySociety/VoiceOver/Monst3r/Shop/NoSell_5")},
            {Monster(STRINGS.UI.MONST3R.NOSELL[6],"SpySociety/VoiceOver/Monst3r/Shop/NoSell_6")},
            {Monster(STRINGS.UI.MONST3R.NOSELL[7],"SpySociety/VoiceOver/Monst3r/Shop/NoSell_7")},
        },

        
        PLOT_POINTS =
        {
            {Monster(STRINGS.UI.MONST3R.PLOT_POINTS[1],"SpySociety/VoiceOver/Monst3r/Shop/Plot_Points_1")},
            {Monster(STRINGS.UI.MONST3R.PLOT_POINTS[2],"SpySociety/VoiceOver/Monst3r/Shop/Plot_Points_2")},
            {Monster(STRINGS.UI.MONST3R.PLOT_POINTS[3],"SpySociety/VoiceOver/Monst3r/Shop/Plot_Points_3")},
            {Monster(STRINGS.UI.MONST3R.PLOT_POINTS[4],"SpySociety/VoiceOver/Monst3r/Shop/Plot_Points_4")},
        },
    },    
    INGAME = 
    {


        AGENT_DOWN = {
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[1],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_1")},
        --  {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[2],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_2")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[3],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_3")},
        --  {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[4],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_4")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[5],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_5")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[6],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_6")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[7],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_7")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[8],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_8")},
        --  {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[9],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_9")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[10],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_10")},
        --  {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[11],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_11")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[12],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_12")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[13],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_13")},
        --  {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[14],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_14")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[15],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_15")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[16],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_16")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[17],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_17")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[18],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_18")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[19],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_19")},
            {Central(STRINGS.MISSIONS.ESCAPE.AGENT_DOWN[20],"SpySociety/VoiceOver/Missions/GenericLines/Operator_AgentDown_20")},
        },

        --MONST3R_DOWN = { Central(STRINGS.UI.MONST3R_DOWN, "SpySociety/VoiceOver/Central/Story/Day4/FinalMission_Ingame_Central_57" ) },
        CENTRAL_DOWN = { Monster(STRINGS.UI.CENTRAL_DOWN, "SpySociety/VoiceOver/Monst3r/Story/Day4/FinalMission_Ingame_Monst3r_58" ) },
        BOTH_CRITICAL_DOWN = { Incognita(STRINGS.UI.BOTH_CRITICAL_DOWN, "SpySociety/VoiceOver/Incognita/Story/Day4/FinalMission_Incognita_59" ) },
        INTRO_2 = { Central(STRINGS.UI.INGAME_FINALE_3.INTRO, "SpySociety/VoiceOver/Central/Story/Day4/FinalMission_Ingame_Central_56" ) },
        ELEVATOR_AGENT = { Central(STRINGS.UI.INGAME_FINALE_3.ELEVATOR_AGENT, "SpySociety/VoiceOver/Central/Story/Day4/FinalMission_Ingame_Central_60" ) },
        ELEVATOR_CENTRAL = { Central(STRINGS.UI.INGAME_FINALE_3.ELEVATOR_CENTRAL, "SpySociety/VoiceOver/Central/Story/Day4/FinalMission_Ingame_Central_61" ) },
        ELEVATOR_CENTRAL_DEAD = { Central(STRINGS.UI.INGAME_FINALE_3.ELEVATOR_CENTRAL_DEAD, "SpySociety/VoiceOver/Central/Story/Day4/FinalMission_Ingame_Central_62" ) },


        CENTRAL_STAY_CLOSE = { Central(STRINGS.MISSIONS.ESCAPE.STAY_CLOSE,"SpySociety/VoiceOver/Missions/Escape/Stay_Close")},
        CENTRAL_FAILED_TARGET_DIED = { Central(STRINGS.MISSIONS.ESCAPE.TARGET_DIED,"SpySociety/VoiceOver/Missions/Escape/Target_Died")},
        CENTRAL_FAILED_TARGET_WOKEUP = { Central(STRINGS.MISSIONS.ESCAPE.TARGET_WOKEUP,"SpySociety/VoiceOver/Missions/Interogate/TargetWokeUp")},
        CENTRAL_FAILED_CONNECTION_BROKEN = { Central(STRINGS.MISSIONS.ESCAPE.CONNECTION_BROKEN,"SpySociety/VoiceOver/Missions/Escape/Connection_Broken")},
        CENTRAL_MOVE_INTO_RANGE = { Central(STRINGS.MISSIONS.ESCAPE.MOVE_INTO_RANGE,"SpySociety/VoiceOver/Missions/Interogate/TargetDown")},

        CENTRAL_SEEINTERROGATE = { Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_SEEINTERROGATE,"SpySociety/VoiceOver/Missions/Escape/Operator_SeeInterrogate")},
        CENTRAL_INTERROGATE_START = { Central(STRINGS.MISSIONS.ESCAPE.INTERROGATE_START,"SpySociety/VoiceOver/Missions/Escape/Interrogate_Start")},
        CENTRAL_INTERROGATE_END = { Central(STRINGS.MISSIONS.ESCAPE.INTERROGATE_END,"SpySociety/VoiceOver/Missions/Escape/Interrogate_End")},
       

       TUTORIAL_INTRO = {
            Central(STRINGS.MISSIONS.JAILBREAK.TUTORIAL_INTRO[1],"SpySociety/VoiceOver/Central/Tutorial/Mission_Brief_1"),
            Central(STRINGS.MISSIONS.JAILBREAK.TUTORIAL_INTRO[2],"SpySociety/VoiceOver/Central/Tutorial/Mission_Brief_2"),
            Central(STRINGS.MISSIONS.JAILBREAK.TUTORIAL_INTRO[3],"SpySociety/VoiceOver/Central/Tutorial/Mission_Brief_3"),
            Central(STRINGS.MISSIONS.JAILBREAK.TUTORIAL_INTRO[4],"SpySociety/VoiceOver/Central/Tutorial/Mission_Brief_4"),
            --Incognita(STRINGS.MISSIONS.JAILBREAK.TUTORIAL_INTRO[5],"SpySociety/VoiceOver/Incognita/Pickups/Tutorial_Connection"),
       },

        MONSTERCAT_PRE =
        {
            {Monster(STRINGS.MISSIONS.MONSTERCAT.PRE[1],"SpySociety/VoiceOver/Monst3r/Shop/FindShopcat_1")},
            {Monster(STRINGS.MISSIONS.MONSTERCAT.PRE[2],"SpySociety/VoiceOver/Monst3r/Shop/FindShopcat_2")},
            {Monster(STRINGS.MISSIONS.MONSTERCAT.PRE[3],"SpySociety/VoiceOver/Monst3r/Shop/FindShopcat_3")},
            --{Monster(STRINGS.MISSIONS.MONSTERCAT.PRE[4],"SpySociety/VoiceOver/Monst3r/Shop/FindShopcat_4")},
        },
        MONSTERCAT_POST=
        {
            {Monster(STRINGS.MISSIONS.MONSTERCAT.POST[1],"SpySociety/VoiceOver/Monst3r/Shop/BurnedByShopcat_1")},
            {Monster(STRINGS.MISSIONS.MONSTERCAT.POST[2],"SpySociety/VoiceOver/Monst3r/Shop/BurnedByShopcat_2")},
            {Monster(STRINGS.MISSIONS.MONSTERCAT.POST[3],"SpySociety/VoiceOver/Monst3r/Shop/BurnedByShopcat_3")},
            {Monster(STRINGS.MISSIONS.MONSTERCAT.POST[4],"SpySociety/VoiceOver/Monst3r/Shop/BurnedByShopcat_4")},
            {Monster(STRINGS.MISSIONS.MONSTERCAT.POST[5],"SpySociety/VoiceOver/Monst3r/Shop/BurnedByShopcat_5")},
        },


        CENTRAL_TUTORIAL_AWAKE = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_AWAKE,"SpySociety/VoiceOver/Central/Tutorial/Operator_Awake")},
        CENTRAL_TUTORIAL_MOVE = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_MOVE,"SpySociety/VoiceOver/Central/Tutorial/Operator_Move")},
        CENTRAL_TUTORIAL_END_TURN = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_END_TURN,"SpySociety/VoiceOver/Central/Tutorial/Operator_EndTurn")},       
        CENTRAL_TUTORIAL_WAITING = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_WAITING,"SpySociety/VoiceOver/Central/Tutorial/Operator_Waiting")},      
        CENTRAL_TUTORIAL_PEEK = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_PEEK,"SpySociety/VoiceOver/Central/Tutorial/Operator_Peek")},             
        CENTRAL_TUTORIAL_GET_OUT = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_GET_OUT,"SpySociety/VoiceOver/Central/Tutorial/Operator_GetOut")},             
        CENTRAL_TUTORIAL_TOOLS = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_TOOLS,"SpySociety/VoiceOver/Central/Tutorial/Operator_Tools")},             
        CENTRAL_TUTORIAL_KNOCK_OUT = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_KNOCK_OUT,"SpySociety/VoiceOver/Central/Tutorial/Operator_KnockOut")},          
        CENTRAL_TUTORIAL_PINNED = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_PINNED,"SpySociety/VoiceOver/Central/Tutorial/Operator_Pinned")},
        CENTRAL_TUTORIAL_SHUT_THE_DOOR = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_SHUT_THE_DOOR,"SpySociety/VoiceOver/Central/Tutorial/Operator_ShutTheDoor")},        
        CENTRAL_TUTORIAL_CONSOLE = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_CONSOLE,"SpySociety/VoiceOver/Central/Tutorial/Operator_Console")},                
        CENTRAL_TUTORIAL_GOT_CONSOLE = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_GOT_CONSOLE,"SpySociety/VoiceOver/Central/Tutorial/Operator_GotConsole")},                
        CENTRAL_TUTORIAL_OPERATOR_CAMERA = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_CAMERA,"SpySociety/VoiceOver/Central/Tutorial/Operator_Camera")},                
        CENTRAL_TUTORIAL_HACK_CAMERA = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_HACK_CAMERA,"SpySociety/VoiceOver/Central/Tutorial/Operator_HackCamera")},                
        CENTRAL_TUTORIAL_DOOR_CORNER = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_DOOR_CORNER,"SpySociety/VoiceOver/Central/Tutorial/Operator_DoorCorner")},                   
        CENTRAL_TUTORIAL_OPERATOR_DISTRACT = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_DISTRACT,"SpySociety/VoiceOver/Central/Tutorial/Operator_Distract")},                        
        CENTRAL_TUTORIAL_OPERATOR_MELEE_PREP = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_MELEE_PREP,"SpySociety/VoiceOver/Central/Tutorial/Operator_MeleePrep")},                        
        CENTRAL_TUTORIAL_OPERATOR_NEXT_ROOM = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_NEXT_ROOM,"SpySociety/VoiceOver/Central/Tutorial/Operator_NextRoom")},                           
        CENTRAL_TUTORIAL_OPERATOR_DANGER_ZONE = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_DANGER_ZONE,"SpySociety/VoiceOver/Central/Tutorial/Operator_DangerZone")},                                   
        CENTRAL_TUTORIAL_OPERATOR_NEED_POWER = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_NEED_POWER,"SpySociety/VoiceOver/Central/Tutorial/Operator_NeedPower")},                                           
        CENTRAL_TUTORIAL_OPERATOR_REMIND_INCOGNITA = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_REMIND_INCOGNITA,"SpySociety/VoiceOver/Central/Tutorial/Operator_RemindIncognita")},                                           
        CENTRAL_TUTORIAL_OPERATOR_AFTER_PEEK = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_AFTER_PEEK,"SpySociety/VoiceOver/Central/Tutorial/Operator_AfterPeek")},
        CENTRAL_TUTORIAL_OPERATOR_EXIT = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_EXIT,"SpySociety/VoiceOver/Central/Tutorial/Operator_Exit")},
        CENTRAL_TUTORIAL_COVER = { 
            Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_SEE_ARMOR,"SpySociety/VoiceOver/Central/Tutorial/Operator_SeeArmor"),
            Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_SEE_ARMOR_2,"SpySociety/VoiceOver/Central/Tutorial/Operator_SeeArmor2"),
        },
       
        CENTRAL_TUTORIAL_OPERATOR_OBSERVE_GUARD = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_OBSERVE_GUARD,"SpySociety/VoiceOver/Central/Tutorial/Operator_Observe_Guard")},
        CENTRAL_TUTORIAL_OPERATOR_OBSERVE_GUARD_2 = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_OBSERVE_GUARD_2,"SpySociety/VoiceOver/Central/Tutorial/Operator_Observe_Guard_2")},
        CENTRAL_TUTORIAL_OPERATOR_WON = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_WON,"SpySociety/VoiceOver/Central/Tutorial/Operator_Won")},        
        CENTRAL_TUTORIAL_OPERATOR_CAUGHT = { Central(STRINGS.MISSIONS.JAILBREAK.OPERATOR_CAUGHT,"SpySociety/VoiceOver/Central/Tutorial/Operator_Caught")},        

        CENTRAL_CAUGHT_BY_CAMERA = { Central(STRINGS.MISSIONS.ESCAPE.CAUGHT_BY_CAMERA,"SpySociety/VoiceOver/Missions/GenericLines/FirstMission_CaughtByCamera")},        

        CENTRAL_FIRST_LEVEL =
        {
            Central(STRINGS.MISSIONS.ESCAPE.FIRST_LEVEL[1],"SpySociety/VoiceOver/Central/Story/Day1/FirstMission_Briefing_1" ),
            Central(STRINGS.MISSIONS.ESCAPE.FIRST_LEVEL[2],"SpySociety/VoiceOver/Central/Story/Day1/FirstMission_Briefing_2" ),
            Central(STRINGS.MISSIONS.ESCAPE.FIRST_LEVEL[3],"SpySociety/VoiceOver/Central/Story/Day1/FirstMission_Briefing_3" ),
        },

        CENTRAL_TEAM_DOWN ={ Central(STRINGS.CENTRAL_BARKS.TEAM_DOWN,"SpySociety/VoiceOver/Central/Tutorial/Operator_Caught")},

        INCOGNITA_TEAM_DOWN =  {
            {Incognita(STRINGS.INCOGNITA_TEAM_DOWN[1], "SpySociety/VoiceOver/Incognita/Pickups/Team_Eliminated_1" )},
            {Incognita(STRINGS.INCOGNITA_TEAM_DOWN[2], "SpySociety/VoiceOver/Incognita/Pickups/Team_Eliminated_2" )},
            {Incognita(STRINGS.INCOGNITA_TEAM_DOWN[3], "SpySociety/VoiceOver/Incognita/Pickups/Team_Eliminated_3" )},
        },
        
        CENTRAL_SCANNER_DETECTED =
        {
            Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_SCANNER_DETECTED_1, "SpySociety/VoiceOver/Missions/Escape/Operator_Scanner_Detected_1" ),
            Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_SCANNER_DETECTED_2, "SpySociety/VoiceOver/Missions/Escape/Operator_Scanner_Detected_2" ),          
        },

        CENTRAL_SCANNER_DETECTED_2 ={ Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_SCANNER_DETECTED_3, "SpySociety/VoiceOver/Missions/Escape/Operator_Scanner_Detected_3" )},        
        
        CENTRAL_CFO_RUNNING = { Central(STRINGS.MISSIONS.ESCAPE.TARGET_RUNNING_AWAY,"SpySociety/VoiceOver/Missions/GenericLines/Operator_CEO_TargetRunning")},                
        CENTRAL_CFO_ESCAPED = { Central(STRINGS.MISSIONS.ESCAPE.TARGET_GOT_AWAY,"SpySociety/VoiceOver/Missions/GenericLines/Operator_CEO_TargetGotAway")},                
        
        CENTRAL_CFO_BRAINSCAN_1 ={ Central(STRINGS.MISSIONS.ESCAPE.SCAN_1, "SpySociety/VoiceOver/Missions/Escape/Scan_1" )},                
        CENTRAL_CFO_BRAINSCAN_2 ={ Central(STRINGS.MISSIONS.ESCAPE.SCAN_2, "SpySociety/VoiceOver/Missions/Escape/Scan_2" )},                
        CENTRAL_CFO_BRAINSCAN_3 ={ Central(STRINGS.MISSIONS.ESCAPE.SCAN_3, "SpySociety/VoiceOver/Missions/Escape/Scan_3" )},                
        CENTRAL_CFO_BRAINSCAN_4 ={ Central(STRINGS.MISSIONS.ESCAPE.SCAN_4, "SpySociety/VoiceOver/Missions/Escape/Scan_4" )},                
        CENTRAL_CFO_BRAINSCAN_5 ={ Central(STRINGS.MISSIONS.ESCAPE.SCAN_5, "SpySociety/VoiceOver/Missions/Escape/Scan_5" )},                


        CENTRAL_HOSTAGE_DEATH = { Central(STRINGS.MISSIONS.ESCAPE.CENTRAL_HOSTAGE_DEATH,"SpySociety/VoiceOver/Missions/Hostage/Operator_NoBonus")},
        CENTRAL_SEE_HOSTAGE = { Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_SEEHOSTAGE,"SpySociety/VoiceOver/Missions/Hostage/Operator_MidInterrogation")},
        CENTRAL_HOSTAGE_CONV = { Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_HOSTAGE_CONVO1,"SpySociety/VoiceOver/Missions/Hostage/Operator_MissingCourier")},
        CENTRAL_HOSTAGE_ESCAPE = { Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_HOSTAGE_ESCAPE,"SpySociety/VoiceOver/Missions/Hostage/Operator_GoodJob")},


        CENTRAL_USED_VAULT_CODE = { Central(STRINGS.MISSIONS.ESCAPE.USED_VAULT_CODE,"SpySociety/VoiceOver/Missions/Escape/Used_Vault_Code")},

        
        CENTRAL_SEE_AGENT = { Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_SEEAGENT,"SpySociety/VoiceOver/Missions/Escape/Operator_SeeAgent")},

        CENTRAL_AGENT_ESCAPE_DECKARD = { Central(string.format(STRINGS.MISSIONS.ESCAPE.OPERATOR_ESCAPE_AGENT,"Deckard"),"SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Deckard")},       
        CENTRAL_AGENT_ESCAPE_INTERNATIONALE = { Central(string.format(STRINGS.MISSIONS.ESCAPE.OPERATOR_ESCAPE_AGENT,"Internationale"),"SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Internationale")},               
        CENTRAL_AGENT_ESCAPE_TONY = { Central(string.format(STRINGS.MISSIONS.ESCAPE.OPERATOR_ESCAPE_AGENT,"Dr Xu"),"SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_DrXu")},               
        CENTRAL_AGENT_ESCAPE_BANKS = { Central(string.format(STRINGS.MISSIONS.ESCAPE.OPERATOR_ESCAPE_AGENT,"Banks"),"SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Banks")},               
        CENTRAL_AGENT_ESCAPE_NIKA = { Central(string.format(STRINGS.MISSIONS.ESCAPE.OPERATOR_ESCAPE_AGENT,"Nika"),"SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Nika")},               
        CENTRAL_AGENT_ESCAPE_SHALEM11 = { Central(string.format(STRINGS.MISSIONS.ESCAPE.OPERATOR_ESCAPE_AGENT,"Shalem 11"),"SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Shalem11")},                       
        CENTRAL_AGENT_ESCAPE_SHARP = { Central(string.format(STRINGS.MISSIONS.ESCAPE.OPERATOR_ESCAPE_AGENT,"Sharp"),"SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Sharp")},                       
        CENTRAL_AGENT_ESCAPE_PRISM = { Central(string.format(STRINGS.MISSIONS.ESCAPE.OPERATOR_ESCAPE_AGENT,"Prism"),"SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Prism")},                           
        

        CENTRAL_SEE_PRISONER = { Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_SEEPRISONER,"SpySociety/VoiceOver/Missions/Escape/Operator_SeePrisoner")},
        CENTRAL_PRISONER_CONV = { Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_PRISONER_CONVO1 ,"SpySociety/VoiceOver/Missions/Escape/Operator_Prisoner_Conv01")},
        CENTRAL_PRISONER_ESCAPE = { Central(STRINGS.MISSIONS.ESCAPE.OPERATOR_ESCAPE_PRISONER ,"SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Prisoner")},

        CENTRAL_DAEMON_REVERSE ={
            {Central(STRINGS.MISSIONS.DAEMON_REVERSE[1], "SpySociety/VoiceOver/Missions/GenericLines/Operator_DaemonReversal_1")},
            {Central(STRINGS.MISSIONS.DAEMON_REVERSE[2], "SpySociety/VoiceOver/Missions/GenericLines/Operator_DaemonReversal_2")},
            {Central(STRINGS.MISSIONS.DAEMON_REVERSE[3], "SpySociety/VoiceOver/Missions/GenericLines/Operator_DaemonReversal_3")},
            {Central(STRINGS.MISSIONS.DAEMON_REVERSE[4], "SpySociety/VoiceOver/Missions/GenericLines/Operator_DaemonReversal_4")},
        },
        CENTRAL_JUDGEMENT =
        {   
            TERMS = {
                HASLIST =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.TERMS.HASLIST[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ExecTerms_GotLocation_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.TERMS.HASLIST[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ExecTerms_GotLocation_2")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.TERMS.HASLIST[3],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ExecTerms_GotLocation_3")},
                },
                NOLIST =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.TERMS.NOLIST[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ExecTerms_NoLocation_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.TERMS.NOLIST[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ExecTerms_NoLocation_2")},
                },
            },
            DISPATCH= {
                HASLOOT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DISPATCH.HASLOOT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Dispatch_GetThing_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DISPATCH.HASLOOT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Dispatch_GetThing_2")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DISPATCH.HASLOOT[3],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Dispatch_GetThing_3")},
                },
                NOLOOT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DISPATCH.NOLOOT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Dispatch_DidntGetThing_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DISPATCH.NOLOOT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Dispatch_DidntGetThing_2")},
                },

            },
            VAULT= {
                EASYLOOT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.VAULT.EASYLOOT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Vault_EasyLoot_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.VAULT.EASYLOOT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Vault_EasyLoot_2")},
                },
                HARDLOOT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.VAULT.HARDLOOT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Vault_UsedKeyCard_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.VAULT.HARDLOOT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Vault_UsedKeyCard_2")},
                },
                NOLOOT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.VAULT.NOLOOT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Vault_NoVault_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.VAULT.NOLOOT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Vault_NoVault_2")},
                },
            },
            SERVERFARM= {
                BOUGHT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.SERVERFARM.BOUGHT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ServerFarm_Bought_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.SERVERFARM.BOUGHT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ServerFarm_Bought_2")},
                },
                SAW =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.SERVERFARM.SAW[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ServerFarm_NoBuy_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.SERVERFARM.SAW[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ServerFarm_NoBuy_2")},
                },
                MISSED =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.SERVERFARM.MISSED[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ServerFarm_NoTerminal_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.SERVERFARM.MISSED[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_ServerFarm_NoTerminal_2")},
                },
            },
            NANOFAB= {
                BOUGHT =
            {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.NANOFAB.BOUGHT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Nanofab_Bought_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.NANOFAB.BOUGHT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Nanofab_Bought_2")},
                },
                SAW =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.NANOFAB.SAW[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Nanofab_DidntBuy")},
                },
                MISSED =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.NANOFAB.MISSED[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Nanofab_DidntUse_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.NANOFAB.MISSED[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Nanofab_DidntUse_2")},
                },
            },
            CYBERLAB= {
                BOUGHT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CYBERLAB.BOUGHT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Cyberlab_Augment_1")},
                    { 
                        Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CYBERLAB.BOUGHT[2][1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Cyberlab_Augment_2", 3 ),
                        Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CYBERLAB.BOUGHT[2][2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Cyberlab_Augment_3")
                    },
                },
                SAW =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CYBERLAB.SAW[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Cyberlab_FoundLab")},
                },
                MISSED =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CYBERLAB.MISSED[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Cyberlab_NoLab_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CYBERLAB.MISSED[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Cyberlab_NoLab_2")},
                },
            },  
            CFO= {
                GOTLOOT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CFO.GOTLOOT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_CEO_GotCard_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CFO.GOTLOOT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_CEO_GotCard_2")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CFO.GOTLOOT[3],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_CEO_GotCard_3")},
                },
                NOLOOT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CFO.NOLOOT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_CEO_NoCard_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CFO.NOLOOT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_CEO_NoCard_2")},                    
                },
                KILLEDTHEGUY=
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.CFO.KILLEDTHEGUY[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_CEO_KilledCEOnoCard")},
                }
            },  

            DETENTION=
            {
                GOTAGENT =
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DETENTION.GOTAGENT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Detention_GotAgent_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DETENTION.GOTAGENT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Detention_GotAgent_2")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DETENTION.GOTAGENT[3],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Detention_GotAgent_3")},
                },

                GOTOTHER=
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DETENTION.GOTOTHER[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Detention_GotOther_1")},
                },
                GOTNOTHING=
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DETENTION.GOTNOTHING[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Detention_NoCells")},
                },
                LOSTAGENT=
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DETENTION.LOSTAGENT[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Detention_NoAgent_1")},
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DETENTION.LOSTAGENT[2],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Detention_NoAgent_2")},
                },
                LOSTOTHER=
                {
                    {Central(STRINGS.MISSIONS.CENTRAL_JUDGEMENT.DETENTION.LOSTOTHER[1],"SpySociety/VoiceOver/Missions/PostMission/MissionComplete_Detention_NoOther_1")},
                },
            },                  
        },

        --These VO lines will need to be updated once they are recorded
        AFTERMATH =
        {
            TERMS=
            {
                {Central(STRINGS.MISSIONS.AFTERMATH.TERMS[1],"SpySociety/VoiceOver/Missions/GenericLines/Operator_Exec_PatrolChange_1")},
                {Central(STRINGS.MISSIONS.AFTERMATH.TERMS[2],"SpySociety/VoiceOver/Missions/GenericLines/Operator_Exec_PatrolChange_2")},
            },
            VAULT=
            {
                {Central(STRINGS.MISSIONS.AFTERMATH.VAULT[1],"SpySociety/VoiceOver/Missions/GenericLines/Operator_Vault_ExtraGuard_1")},
                {Central(STRINGS.MISSIONS.AFTERMATH.VAULT[2],"SpySociety/VoiceOver/Missions/GenericLines/Operator_Vault_ExtraGuard_2")},
            },
            SERVERFARM=
            {
                {Central(STRINGS.MISSIONS.AFTERMATH.SERVERFARM[1],"SpySociety/VoiceOver/Missions/GenericLines/Operator_Server_ExtraDaemon_1")},
                {Central(STRINGS.MISSIONS.AFTERMATH.SERVERFARM[2],"SpySociety/VoiceOver/Missions/GenericLines/Operator_Server_ExtraDaemon_2")},
            },
            DISPATCH=
            {
                {Central(STRINGS.MISSIONS.AFTERMATH.DISPATCH[1],"SpySociety/VoiceOver/Missions/GenericLines/Operator_Regional_GuardsToLocation_1")},
                {Central(STRINGS.MISSIONS.AFTERMATH.DISPATCH[2],"SpySociety/VoiceOver/Missions/GenericLines/Operator_Regional_GuardsToLocation_2")},
            },
            CYBERNANO=
            {
                {Central(STRINGS.MISSIONS.AFTERMATH.CYBERNANO[1],"SpySociety/VoiceOver/Missions/GenericLines/Operator_CyberlabNanofab_Reclaim_1")},
                {Central(STRINGS.MISSIONS.AFTERMATH.CYBERNANO[2],"SpySociety/VoiceOver/Missions/GenericLines/Operator_CyberlabNanofab_Reclaim_2")},
            },
        },

        --These VO lines will need to be updated once they are recorded
        SEEOBJECTIVE =
        {
            TERMS=
            {
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.TERMS[1],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Terminal_1")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.TERMS[2],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Terminal_2")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.TERMS[3],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Terminal_3")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.TERMS[4],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Terminal_4")},
                
            },
            VAULT=
            {
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.VAULT[1],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Vault_1")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.VAULT[2],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Vault_2")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.VAULT[3],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Vault_3")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.VAULT[4],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Vault_4")},
            },
            SERVERFARM=
            {
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.SERVERFARM[1],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Server_1")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.SERVERFARM[2],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Server_2")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.SERVERFARM[3],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Server_3")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.SERVERFARM[4],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Server_4")},
            },
            DISPATCH=
            {
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.DISPATCH[1],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Dispatch_1")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.DISPATCH[2],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Dispatch_2")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.DISPATCH[3],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Dispatch_3")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.DISPATCH[4],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Dispatch_4")},
            },
            CYBERLAB=
            {
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.CYBERLAB[1],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Cyberlab_1")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.CYBERLAB[2],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Cyberlab_2")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.CYBERLAB[3],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Cyberlab_3")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.CYBERLAB[4],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Cyberlab_4")},
            },
            NANOFAB=
            {
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.NANOFAB[1],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Nanofab_1")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.NANOFAB[2],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Nanofab_2")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.NANOFAB[3],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Nanofab_3")},
                {Central(STRINGS.MISSIONS.OBJECTIVE_SIGHTED.NANOFAB[4],"SpySociety/VoiceOver/Missions/GenericLines/ObjectiveSighted_Nanofab_4")},
            },
        },        


        FINALMISSION = 
        {
            INTRO =
            {
                Central(STRINGS.MISSIONS.FINALMISSION.INTRO_CONVO[1],"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_1"),
                                                                            --"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_2"
                Incognita(STRINGS.MISSIONS.FINALMISSION.INTRO_CONVO[2],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_2"),
                Central(STRINGS.MISSIONS.FINALMISSION.INTRO_CONVO[3],"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_3"),
                Incognita(STRINGS.MISSIONS.FINALMISSION.INTRO_CONVO[4],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_4"),
                Central(STRINGS.MISSIONS.FINALMISSION.INTRO_CONVO[5],"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_5"),
                Monster(STRINGS.MISSIONS.FINALMISSION.INTRO_CONVO[6],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_6"),
            },
            SEE_GUARDS = { Central(STRINGS.MISSIONS.FINALMISSION.SEE_GUARDS,"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_7") },
            REBOOT_RANT =
            {
                {   Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[1][1],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_8"),
                    Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[1][2],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_9"),
                    Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[1][3],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_10") },

                {   Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[2][1],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_11"),
                    Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[2][2],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_12"),
                    Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[2][3],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_13") },

                {   Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[3][1],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_14"),
                    Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[3][2],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_15"),
                    Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[3][3],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_16") },

                {   Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[4][1],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_17"),
                    Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[4][2],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_18"),
                    Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[4][3],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_19") },
                
                { Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[5],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_20") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[6],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_21") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[7],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_22") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.REBOOT_RANT[8],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_23") },
            },
            SUPERCHARGE_CONVO =
            {
                Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_CONVO[1],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_24"),
                Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_CONVO[2],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_25"),
                Monster(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_CONVO[3],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_26"),
                Central(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_CONVO[4],"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_27"),
            },
            SUPERCHARGE_CONVO_ALT =
            {
                Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_CONVO[1],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_24"),
                Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_CONVO[2],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_25"),
            },
            SUPERCHARGE_RANT =
            {
                { Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_RANT[1],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_28") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_RANT[2],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_29") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_RANT[3],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_30") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_RANT[4],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_31") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_RANT[5],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_32") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_RANT[6],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_33") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_RANT[7],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_34") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_RANT[8],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_34") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.SUPERCHARGE_RANT[9],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_34") },
            },
            POST_SUPERCHARGE_CONVO =
            {
                Monster(STRINGS.MISSIONS.FINALMISSION.POST_SUPERCHARGE_CONVO[1],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_35"),
                Central(STRINGS.MISSIONS.FINALMISSION.POST_SUPERCHARGE_CONVO[2],"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_36"),
                Monster(STRINGS.MISSIONS.FINALMISSION.POST_SUPERCHARGE_CONVO[3],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_37"),
            },

            USE_LOVE_PROGRAM = { Incognita(STRINGS.MISSIONS.FINALMISSION.USE_LOVE_PROGRAM,"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_38") },
            SEE_DOOR_FIRST = { Monster(STRINGS.MISSIONS.FINALMISSION.SEE_DOOR_FIRST,"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_39") },
            SEE_HUB_FIRST = { Monster(STRINGS.MISSIONS.FINALMISSION.SEE_HUB_FIRST,"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_40") },
            SEE_HUB_SECOND = { Monster(STRINGS.MISSIONS.FINALMISSION.SEE_HUB_SECOND,"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_41") },

            HUB_HACK_PROGRESS =
            {
                {   Monster(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[1][1],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_42_1"), 
                    Monster(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[1][2],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_42_2"),
                    Monster(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[1][3],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_42_3")},
                {   Monster(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[2],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_43") },
                {   Monster(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[3],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_44") },
                {   Monster(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[4],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_45") },
                {   Monster(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[5],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_46") },

            },

            HUB_HACK_FINISHED = 
            {
                Monster(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[6][1],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_47_1"),
                Monster(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[6][2],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_47_2"),
                Central(STRINGS.MISSIONS.FINALMISSION.HUB_HACK_PROGRESS[7],"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_48") 
            },

            AGENT_DOWN =
            {
                {Central(STRINGS.MISSIONS.FINALMISSION.AGENT_DOWN[1],"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_58")},
                {Central(STRINGS.MISSIONS.FINALMISSION.AGENT_DOWN[2],"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_59")},
                {Central(STRINGS.MISSIONS.FINALMISSION.AGENT_DOWN[3],"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_60")},
            },

            STOP_HACKING_EARLY = { Central(STRINGS.MISSIONS.FINALMISSION.STOP_HACKING_EARLY,"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_49") },
            MONSTER_DOWN_BEFORE_HACK = { Central(STRINGS.MISSIONS.FINALMISSION.MONSTER_DOWN_BEFORE_HACK,"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_50") },
            MONSTER_DOWN_AFTER_HACK  = { Central(STRINGS.MISSIONS.FINALMISSION.MONSTER_DOWN_AFTER_HACK,"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_51") },
            HACK_RESUME = { Monster(STRINGS.MISSIONS.FINALMISSION.HACK_RESUME,"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_52") },
            OPEN_FINAL_DOOR = { Monster(STRINGS.MISSIONS.FINALMISSION.OPEN_FINAL_DOOR,"SpySociety/VoiceOver/Monst3r/Story/Pickups/FinalMission_Most3r_53") },
            PASS_THROUGH_DOOR = { Central(STRINGS.MISSIONS.FINALMISSION.PASS_THROUGH_DOOR,"SpySociety/VoiceOver/Central/Story/FinalMission/FinalMission_Central_54") },
            NO_GO_THROUGH_DOOR = { Incognita(STRINGS.MISSIONS.FINALMISSION.NO_GO_THROUGH_DOOR,"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_55") },

            FINAL_WALK_RANT =
            {
                { Incognita(STRINGS.MISSIONS.FINALMISSION.FINAL_WALK_RANT[1],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_56") },
                { Incognita(STRINGS.MISSIONS.FINALMISSION.FINAL_WALK_RANT[2],"SpySociety/VoiceOver/Incognita/Final_Mission/FinalMission_Incognita_57") },
            },

        },


    },

    CAMPAIGN_MAP =
    {
        GENERIC = 
        {
            Central(STRINGS.UI.MAP_DIALOG_1, "SpySociety/VoiceOver/Central/Story/Generic/GenericStory_1"),
        },
        GENERIC_NEWDAY = 
        {
            Central(STRINGS.UI.CENTRAL_MISSION_DIFFICULTY, "SpySociety/VoiceOver/Central/Story/Generic/GenericStory_2"),
        },

        MONSTER_INJECT = {Monster(STRINGS.UI.MAP_DAY_1_MISSION_2_NEW_LOCATIONS[1],"SpySociety/VoiceOver/Monst3r/Story/Pickups/FirstMission_NoDisk")},

        
        LAST_MISSION = {Central(STRINGS.UI.LAST_MISSION, "SpySociety/VoiceOver/Central/Story/Day3/Mission3_Central_37_alt")},

        --NOTE: the "mission number" when the script was written doesn't neccessarily match the mission number of the final game - things got shuffled on day 2 and 3.
        MISSIONS = 
        {
            [1] = --day one
            {
                [1] = --mission 1
                {
                    Central(STRINGS.UI.MAP_DAY_1_MISSION_1[1], "SpySociety/VoiceOver/Central/Story/Day1/Mission1_Central_1"),
                    Central(STRINGS.UI.MAP_DAY_1_MISSION_1[2], "SpySociety/VoiceOver/Central/Story/Day1/Mission1_Central_2"),
                    Central(STRINGS.UI.MAP_DAY_1_MISSION_1[3], "SpySociety/VoiceOver/Central/Story/Day1/Mission1_Central_3"),
                    Central(STRINGS.UI.MAP_DAY_1_MISSION_1[4], "SpySociety/VoiceOver/Central/Story/Day1/Mission1_Central_4"),
                },

                [2] = --mission 2
                {
                    Central(STRINGS.UI.MAP_DAY_1_MISSION_2[1], "SpySociety/VoiceOver/Central/Story/Day1/Mission2_Central_6"),
                    Monster(STRINGS.UI.MAP_DAY_1_MISSION_2[2], "SpySociety/VoiceOver/Monst3r/Story/Day1/Mission2_Monst3r_7"),
                    Central(STRINGS.UI.MAP_DAY_1_MISSION_2[3], "SpySociety/VoiceOver/Central/Story/Day1/Mission2_Central_8"),
                },


                [3] = --optional?
                {
                    Incognita(STRINGS.UI.MAP_DAY_1_MISSION_3[1], "SpySociety/VoiceOver/Incognita/Story/Day1/Mission3_Incognita_9"),
                    Central(STRINGS.UI.MAP_DAY_1_MISSION_3[2],   "SpySociety/VoiceOver/Central/Story/Day1/Mission3_Central_10"),
                    Incognita(STRINGS.UI.MAP_DAY_1_MISSION_3[3], "SpySociety/VoiceOver/Incognita/Story/Day1/Mission3_Incognita_11"),
                    Central(STRINGS.UI.MAP_DAY_1_MISSION_3[4],   "SpySociety/VoiceOver/Central/Story/Day1/Mission3_Central_12"),
                },
            },

            [2] = --day two
            {
                [1] = --mission 1
                {
                    Central(STRINGS.UI.MAP_DAY_2_MISSION_1[1], "SpySociety/VoiceOver/Central/Story/Day2/Mission1_Central_13"),
                    Monster(STRINGS.UI.MAP_DAY_2_MISSION_1[2], "SpySociety/VoiceOver/Monst3r/Story/Day2/Mission1_Monst3r_14"),
                    Central(STRINGS.UI.MAP_DAY_2_MISSION_1[3], "SpySociety/VoiceOver/Central/Story/Day2/Mission1_Central_15"),
                    Monster(STRINGS.UI.MAP_DAY_2_MISSION_1[4], "SpySociety/VoiceOver/Monst3r/Story/Day2/Mission1_Monst3r_16"),
                    Central(STRINGS.UI.MAP_DAY_2_MISSION_1[5], "SpySociety/VoiceOver/Central/Story/Day2/Mission1_Central_18"),
                    Monster(STRINGS.UI.MAP_DAY_2_MISSION_1[6], "SpySociety/VoiceOver/Monst3r/Story/Day2/Mission1_Monst3r_19"),
                    Central(STRINGS.UI.MAP_DAY_2_MISSION_1[7], "SpySociety/VoiceOver/Central/Story/Day2/Mission1_Central_20"),
                    Monster(STRINGS.UI.MAP_DAY_2_MISSION_1[8], "SpySociety/VoiceOver/Monst3r/Story/Day2/Mission1_Monst3r_21"),
                    Monster(STRINGS.UI.MAP_DAY_2_MISSION_1[9], "SpySociety/VoiceOver/Monst3r/Story/Day2/Mission1_Monst3r_22"),
                    Monster(STRINGS.UI.MAP_DAY_2_MISSION_1[10], "SpySociety/VoiceOver/Monst3r/Story/Day2/Mission1_Monst3r_23"),
                    Central(STRINGS.UI.MAP_DAY_2_MISSION_1[11], "SpySociety/VoiceOver/Central/Story/Day2/Mission1_Central_24"),
                    Central(STRINGS.UI.MAP_DAY_2_MISSION_1[12], "SpySociety/VoiceOver/Central/Story/Day2/Mission1_Central_25"),
                },

                    
                [2] =
                {
                    Incognita(STRINGS.UI.MAP_DAY_2_MISSION_3[1], "SpySociety/VoiceOver/Incognita/Story/Day2/Mission3_Incognita_26"),
                    Monster(STRINGS.UI.MAP_DAY_2_MISSION_3[2],   "SpySociety/VoiceOver/Monst3r/Story/Day2/Mission3_Monst3r_27"),
                    Central(STRINGS.UI.MAP_DAY_2_MISSION_3[3],   "SpySociety/VoiceOver/Central/Story/Day2/Mission3_Central_28"),
                    Monster(STRINGS.UI.MAP_DAY_2_MISSION_3[4],   "SpySociety/VoiceOver/Monst3r/Story/Day2/Mission3_Monst3r_29"),
                    Central(STRINGS.UI.MAP_DAY_2_MISSION_3[5],   "SpySociety/VoiceOver/Central/Story/Day2/Mission3_Central_30"),
                    Monster(STRINGS.UI.MAP_DAY_2_MISSION_3[6],   "SpySociety/VoiceOver/Monst3r/Story/Day2/Mission3_Monst3r_31"),
                },
            },
            [3] = --day three
            {

                [1] = --mission 1
                {
                    Incognita(STRINGS.UI.MAP_DAY_3_MISSION_2[1], "SpySociety/VoiceOver/Incognita/Story/Day3/Mission3_Incognita_32"),
                    Monster(STRINGS.UI.MAP_DAY_3_MISSION_2[2], "SpySociety/VoiceOver/Monst3r/Story/Day3/Mission2_Monst3r_33"),
                    Central(STRINGS.UI.MAP_DAY_3_MISSION_2[3], "SpySociety/VoiceOver/Central/Story/Day3/Mission2_Central_34"),
                    Monster(STRINGS.UI.MAP_DAY_3_MISSION_2[4],"SpySociety/VoiceOver/Monst3r/Story/Pickups/MidlMission_Most3r_GearUp"),
                },

                [2] = --mission 2
                {
                    Monster(STRINGS.UI.MAP_DAY_3_MISSION_3[1], "SpySociety/VoiceOver/Monst3r/Story/Day3/Mission3_Monst3r_35"),
                    Monster(STRINGS.UI.MAP_DAY_3_MISSION_3[2], "SpySociety/VoiceOver/Monst3r/Story/Day3/Mission3_Monst3r_36"),
                    Central(STRINGS.UI.MAP_DAY_3_MISSION_3[3], "SpySociety/VoiceOver/Central/Story/Day3/Mission3_Central_37"),
                },
            },            
            [FINAL_LEVEL_SCRIPT] = 
            {
                [1] =
                {                                               
                    Monster(STRINGS.UI.MAP_DAY_4_MISSION_1[1], "SpySociety/VoiceOver/Monst3r/Story/Day4/Premission_Monst3r_38"),
                    Incognita(STRINGS.UI.MAP_DAY_4_MISSION_1[2], "SpySociety/VoiceOver/Incognita/Story/Day4/Premission_Incognita_39"),
                    Monster(STRINGS.UI.MAP_DAY_4_MISSION_1[3], "SpySociety/VoiceOver/Monst3r/Story/Day4/Premission_Monst3r_40"),
                    Central(STRINGS.UI.MAP_DAY_4_MISSION_1[4], "SpySociety/VoiceOver/Central/Story/Day4/Premission_Central_41"),
                    Monster(STRINGS.UI.MAP_DAY_4_MISSION_1[5], "SpySociety/VoiceOver/Monst3r/Story/Day4/Premission_Monst3r_42"),
                    Central(STRINGS.UI.MAP_DAY_4_MISSION_1[6], "SpySociety/VoiceOver/Central/Story/Day4/Premission_Central_43"),
                },
            }

        },
    },
    ENDLESS_MAP =
    {
        MISSIONS = 
        {
            [1] =
            {
                [1] = {
                        Central(STRINGS.UI.MAP_DIALOG_INFINITE_INTRO[1], "SpySociety/VoiceOver/Missions/MapScreen/Intro_infinite_1"),
                        Central(STRINGS.UI.MAP_DIALOG_INFINITE_INTRO[2], "SpySociety/VoiceOver/Missions/MapScreen/Intro_infinite_2"),
                        Central(STRINGS.UI.MAP_DIALOG_INFINITE_INTRO[3], "SpySociety/VoiceOver/Missions/MapScreen/Intro_infinite_3"),
                },
            },
            [2] = { [1] = {Central(STRINGS.UI.MAP_DIALOG_INFINITE_DAYS[2],"SpySociety/VoiceOver/Central/Endless/Endless_Story_Day1")}, },
            [3] = { [1] = {Central(STRINGS.UI.MAP_DIALOG_INFINITE_DAYS[3],"SpySociety/VoiceOver/Central/Endless/Endless_Story_Day2")}, },
            [4] = { [1] = {Central(STRINGS.UI.MAP_DIALOG_INFINITE_DAYS[4],"SpySociety/VoiceOver/Central/Endless/Endless_Story_Day3")}, },
            [5] = { [1] = {Central(STRINGS.UI.MAP_DIALOG_INFINITE_DAYS[5],"SpySociety/VoiceOver/Central/Endless/Endless_Story_Day4")}, },
            [6] = { [1] = {Central(STRINGS.UI.MAP_DIALOG_INFINITE_DAYS[6],"SpySociety/VoiceOver/Central/Endless/Endless_Story_Day5")}, },
        }
    },


    SUBTITLES =
    {
        INTRO = {
            {STRINGS.MOVIE_SUBS.INTRO_1,4.4,8.3},
            {STRINGS.MOVIE_SUBS.INTRO_2,8.3,10},
            {STRINGS.MOVIE_SUBS.INTRO_3,10.4,12},
            {STRINGS.MOVIE_SUBS.INTRO_4,15.4,16.1},
            {STRINGS.MOVIE_SUBS.INTRO_5,16.8,18},
            {STRINGS.MOVIE_SUBS.INTRO_6,18.2,21},
            {STRINGS.MOVIE_SUBS.INTRO_7,23.6,27.6},
            {STRINGS.MOVIE_SUBS.INTRO_8,28,29.8},
            {STRINGS.MOVIE_SUBS.INTRO_9,29.9,33},
            {STRINGS.MOVIE_SUBS.INTRO_10,33.6,36},
            {STRINGS.MOVIE_SUBS.INTRO_11,40,42},
            {STRINGS.MOVIE_SUBS.INTRO_12,42.5,46},
            {STRINGS.MOVIE_SUBS.INTRO_13,73.6,77},
            {STRINGS.MOVIE_SUBS.INTRO_14,79,82},
            {STRINGS.MOVIE_SUBS.INTRO_15,82,84},
            {STRINGS.MOVIE_SUBS.INTRO_16,93,94},
            {STRINGS.MOVIE_SUBS.INTRO_17,97.8,99.6},
            {STRINGS.MOVIE_SUBS.INTRO_18,99.7,101},
            {STRINGS.MOVIE_SUBS.INTRO_19,118,119.8},
            {STRINGS.MOVIE_SUBS.INTRO_20,131,133},
        },


        END = {
            {STRINGS.MOVIE_SUBS.END_1,4,6.7},
            {STRINGS.MOVIE_SUBS.END_2,6.9,8.6},
            {STRINGS.MOVIE_SUBS.END_3,9.1,12.5},
            {STRINGS.MOVIE_SUBS.END_4,12.6,15.6},
            {STRINGS.MOVIE_SUBS.END_5,15.8,18.1},
            {STRINGS.MOVIE_SUBS.END_6,20.1,22.8},
            {STRINGS.MOVIE_SUBS.END_7,22.8,24.2},
            {STRINGS.MOVIE_SUBS.END_8,24.2,27.8},
            {STRINGS.MOVIE_SUBS.END_9,28.3,29.5},
            {STRINGS.MOVIE_SUBS.END_10,29.6,34},
            {STRINGS.MOVIE_SUBS.END_11,38,39.5},
            {STRINGS.MOVIE_SUBS.END_12,42,43.5},
            {STRINGS.MOVIE_SUBS.END_13,44,46},
            {STRINGS.MOVIE_SUBS.END_14,50,52},
            {STRINGS.MOVIE_SUBS.END_15,53.3,56.8},
            {STRINGS.MOVIE_SUBS.END_16,56.8,59},
            {STRINGS.MOVIE_SUBS.END_17,59,62},
            {STRINGS.MOVIE_SUBS.END_18,63,66},
            {STRINGS.MOVIE_SUBS.END_19, 66.3,68.6},
            {STRINGS.MOVIE_SUBS.END_20,69,72},
            {STRINGS.MOVIE_SUBS.END_21,75,77},
            {STRINGS.MOVIE_SUBS.END_22,77,78},
            {STRINGS.MOVIE_SUBS.END_23,78,80},
            {STRINGS.MOVIE_SUBS.END_24,80,82},
            {STRINGS.MOVIE_SUBS.END_25,82,84},
            {STRINGS.MOVIE_SUBS.END_26,88,93},
            {STRINGS.MOVIE_SUBS.END_27,98,101},
            {STRINGS.MOVIE_SUBS.END_28,108,111},
            {STRINGS.MOVIE_SUBS.END_29,111,114},
            {STRINGS.MOVIE_SUBS.END_30,115,117},
            {STRINGS.MOVIE_SUBS.END_31,136, 137.4},
            {STRINGS.MOVIE_SUBS.END_32,137.5,144.3},
            {STRINGS.MOVIE_SUBS.END_33,144.4,148.5},
            {STRINGS.MOVIE_SUBS.END_34,147.8,150},
            {STRINGS.MOVIE_SUBS.END_35,151.3,154},
            {STRINGS.MOVIE_SUBS.END_36,155,161}, 
        },

    }

}


local STORY_SCRIPTS = {}

function ResetStoryScripts()
    log:write("ResetStoryScripts()")   
    util.tclear(STORY_SCRIPTS)
    util.tmerge(STORY_SCRIPTS, util.tcopy(STORY_SCRIPTS_DEFAULT))
end

ResetStoryScripts()

return STORY_SCRIPTS