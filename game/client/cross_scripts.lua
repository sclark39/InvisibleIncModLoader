
local agentdefs = include("sim/unitdefs/agentdefs")

-- CROSS DIALOGUE SCRIPTS

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

local DECKAR = agentdefs.stealth_1.agentID
local XU =  agentdefs.engineer_1.agentID
local INTERNATIONALE =  agentdefs.engineer_2.agentID
local SHALEM = agentdefs.sharpshooter_1.agentID
local NIKA = agentdefs.sharpshooter_2.agentID
local SHARP = agentdefs.cyborg_1.agentID
local PRISM = agentdefs.disguise_1.agentID
local BANKS = agentdefs.stealth_2.agentID
-- the actual story scripts

-- 1 list of agent ID's in the script, 
-- 2 list of lines in a set of speaker ID and CROSS line number


-- 1 Decker
-- 2 Shalem
-- 3 Xu
-- 4 Banks
-- 5 Internationale
-- 6 Nika
-- 7 Sharp
-- 8 Prism

-- 100 Monster
-- 108 Central

-- 1000 Olivia
-- 1001 Derek
return 
{
    {id = 1,  -- keep track of which convos have been used in a game
     agents = {DECKAR,XU}, 
     dialogue = {  -- agent IDs
        {DECKAR,    1},  -- agnetID and BANTER.CROSS line
        {XU,        1},
        {DECKAR,    2},
        }        
    },

    {id = 2,
     agents = {DECKAR,XU},
     dialogue = {  -- agent IDs
        {XU,        2},  -- agnetID and BANTER.CROSS line
        {DECKAR,    3},
        {XU,        3},
        }
    },   

    {id = 3,
     agents = {DECKAR,XU},
     dialogue = {  -- agent IDs
        {DECKAR,    4},  -- agnetID and BANTER.CROSS line
        {XU,        4},
        {DECKAR,    5},
        {XU,        5},
        }
    },  

    {id = 4,
     agents = {DECKAR,XU},
     dialogue = {  -- agent IDs
        {DECKAR,    6},  -- agnetID and BANTER.CROSS line
        {XU,        6},
        {DECKAR,    7},
        }
    },       

    {id = 5,
     agents = {DECKAR,INTERNATIONALE},
     dialogue = {  -- agent IDs
        {INTERNATIONALE,                1},  -- agnetID and BANTER.CROSS line
        {DECKAR,                        8},        
        {INTERNATIONALE,                2},
        {DECKAR,                        9},        
        }
    }, 

    {id = 6,
     agents = {DECKAR,INTERNATIONALE},
     dialogue = {  -- agent IDs
        {DECKAR,                10},  -- agnetID and BANTER.CROSS line
        {INTERNATIONALE,         3},        
        {DECKAR,                11},     
        }
    },     

    {id = 7,
     agents = {DECKAR,INTERNATIONALE},
     dialogue = {  -- agent IDs
        {INTERNATIONALE,         4},   
        {DECKAR,                12},  -- agnetID and BANTER.CROSS line
        {INTERNATIONALE,         5},        
        {DECKAR,                13},     
        }
    },

    {id = 8,
     agents = {DECKAR,INTERNATIONALE},
     dialogue = {  -- agent IDs
        {DECKAR,                14},  -- agnetID and BANTER.CROSS line
        {INTERNATIONALE,         6},        
        {DECKAR,                15},     
        }
    },


    {id = 9,
     agents = {DECKAR,SHALEM},
     dialogue = {  -- agent IDs
        {SHALEM,                  1},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 16},        
        {SHALEM,                  2},     
        }
    },

    {id = 10,
     agents = {DECKAR,SHALEM},
     dialogue = {  -- agent IDs
        {DECKAR,                 17},             
        {SHALEM,                  3},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 18},        
        {SHALEM,                  4},     
        }
    },

    {id = 11,
     agents = {DECKAR,SHALEM},
     dialogue = {  -- agent IDs
        {DECKAR,                 19},             
        {SHALEM,                  5},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 20},        
        {SHALEM,                  6},     
        }
    },  

    {id = 12,
     agents = {DECKAR,SHALEM},
     dialogue = {  -- agent IDs            
        {SHALEM,                  7},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 21},        
        {SHALEM,                  8}, 
        {DECKAR,                 22}, 
        }
    },   

    {id = 13,
     agents = {DECKAR,NIKA},
     dialogue = {  -- agent IDs            
        {NIKA,                   1},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 23},        
        {NIKA,                   2}, 
        {DECKAR,                 24}, 
        }
    },              

    {id = 14,
     agents = {DECKAR,NIKA},
     dialogue = {  -- agent IDs    
        {DECKAR,                 25}, 
        {NIKA,                   3},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 26},        
        {NIKA,                   4},         
        }
    }, 

    {id = 15,
     agents = {DECKAR,NIKA},
     dialogue = {  -- agent IDs            
        {NIKA,                  5},  -- agnetID and BANTER.CROSS line
        {DECKAR,                27},        
        {NIKA,                  6},         
        }
    }, 

    {id = 15,
     agents = {DECKAR,NIKA},
     dialogue = {  -- agent IDs    
        {DECKAR,                 28}, 
        {NIKA,                   7},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 29},        
        {NIKA,                   8},         
        }
    }, 

    {id = 16,
     agents = {DECKAR,SHARP},
     dialogue = {  -- agent IDs    
        {SHARP,                   1},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 30},        
        {SHARP,                   2},         
        }
    }, 

    {id = 17,
     agents = {DECKAR,SHARP},
     dialogue = {  -- agent IDs    
        {DECKAR,                 31},       
        {SHARP,                   3},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 32},                
        }
    }, 

    {id = 18,
     agents = {DECKAR,SHARP},
     dialogue = {  -- agent IDs    
        {SHARP,                   4},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 33},        
        {SHARP,                   5},         
        }
    }, 

    {id = 19,
     agents = {DECKAR,SHARP},
     dialogue = {  -- agent IDs    
        {DECKAR,                 34},       
        {SHARP,                   6},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 35},                
        {SHARP,                   7},          
        }
    }, 

    {id = 20,
     agents = {DECKAR,PRISM},
     dialogue = {  -- agent IDs    
        {DECKAR,                 36},       
        {PRISM,                   1},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 37},                         
        }
    },     

    {id = 21,
     agents = {DECKAR,PRISM},
     dialogue = {  -- agent IDs    
        {PRISM,                   2},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 38}, 
        {PRISM,                   3},        
        {DECKAR,                 39},          
        }
    },     

    {id = 22,
     agents = {DECKAR,PRISM},
     dialogue = {  -- agent IDs    
        {DECKAR,                 40},       
        {PRISM,                   4},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 41},                         
        }
    },    

    {id = 23,
     agents = {DECKAR,PRISM},
     dialogue = {  -- agent IDs    
        {PRISM,                   5},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 42}, 
        {PRISM,                   6},        
        {DECKAR,                 43},          
        }
    },     

    {id = 24,
     agents = {DECKAR,BANKS},
     dialogue = {  -- agent IDs    
        {BANKS,                   1},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 44}, 
        {BANKS,                   2},        
        {DECKAR,                 45},          
        }
    }, 

    {id = 25,
     agents = {DECKAR,BANKS},
     dialogue = {  -- agent IDs    
        {BANKS,                   3},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 46}, 
        {BANKS,                   4},        
        {DECKAR,                 47},          
        }
    }, 

    {id = 26,
     agents = {DECKAR,BANKS},
     dialogue = {  -- agent IDs    
        {DECKAR,                 48},  
        {BANKS,                   5},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 49}, 
        {BANKS,                   6},        
        }
    },    

    {id = 27,
     agents = {DECKAR,BANKS},
     dialogue = {  -- agent IDs    
        {DECKAR,                 50},  
        {BANKS,                   7},  -- agnetID and BANTER.CROSS line
        {DECKAR,                 51}, 
        {BANKS,                   8},        
        }
    },   

    {id = 28,
     agents = {XU,INTERNATIONALE},
     dialogue = {  -- agent IDs    
        {INTERNATIONALE,       7},  
        {XU,                   7},  -- agnetID and BANTER.CROSS line
        {INTERNATIONALE,       8}, 
        {XU,                   8},        
        }
    },   

    {id = 29,
     agents = {XU,INTERNATIONALE},
     dialogue = {  -- agent IDs    
        {XU,                 9},  
        {INTERNATIONALE,     9},  -- agnetID and BANTER.CROSS line
        {XU,                 10}, 
        {INTERNATIONALE,     10},        
        }
    },

    {id = 30,
     agents = {XU,INTERNATIONALE},
     dialogue = {  -- agent IDs    
        {INTERNATIONALE,       11},  
        {XU,                   11},  -- agnetID and BANTER.CROSS line
        {INTERNATIONALE,       12}, 
        {XU,                   12},        
        }
    },   

    {id = 31,
     agents = {XU,INTERNATIONALE},
     dialogue = {  -- agent IDs    
        {XU,                 13},  
        {INTERNATIONALE,     13},  -- agnetID and BANTER.CROSS line
        {XU,                 14}, 
        {INTERNATIONALE,     14},        
        }
    },

    {id = 32,
     agents = {XU,SHALEM},
     dialogue = {  -- agent IDs    
        {SHALEM,            9},  -- agnetID and BANTER.CROSS line
        {XU,                 15},          
        {SHALEM,            10},        
        }
    },

    {id = 33,
     agents = {XU,SHALEM},
     dialogue = {  -- agent IDs    
        {XU,                 16}, 
        {SHALEM,            11},  -- agnetID and BANTER.CROSS line
        {XU,                 17},          
        {SHALEM,            12},        
        }
    },    

    {id = 34,
     agents = {XU,SHALEM},
     dialogue = {  -- agent IDs    
        {SHALEM,            13},  -- agnetID and BANTER.CROSS line
        {XU,                 18},          
        {SHALEM,            14},       
        {XU,                 19},          
        {SHALEM,            15},                
        }
    },    

    {id = 35,
     agents = {XU,SHALEM},
     dialogue = {  -- agent IDs    
        {SHALEM,            16},  -- agnetID and BANTER.CROSS line
        {XU,                 20},          
        {SHALEM,            17},        
        }
    },   

    {id = 36,
     agents = {XU,NIKA},
     dialogue = {  -- agent IDs    
        {NIKA,            9},  -- agnetID and BANTER.CROSS line
        {XU,                 21},          
        {NIKA,            10},        
        {XU,                 22},         
        }
    },        

    {id = 37,
     agents = {XU,NIKA},
     dialogue = {  -- agent IDs    
        {NIKA,            11},  -- agnetID and BANTER.CROSS line
        {XU,                 23},          
        {NIKA,            12},                
        }
    },

    {id = 38,
     agents = {XU,NIKA},
     dialogue = {  -- agent IDs    
        {XU,                 24},       
        {NIKA,            13},  -- agnetID and BANTER.CROSS line
        {XU,                 25},          
        {NIKA,            14},                
        }
    },          

    {id = 39,
     agents = {XU,NIKA},
     dialogue = {  -- agent IDs    
        {NIKA,            15},  -- agnetID and BANTER.CROSS line
        {XU,                 26},          
        {NIKA,            16},                
        }
    },

    {id = 40,
     agents = {XU,SHARP},
     dialogue = {  -- agent IDs    
        {XU,                 27},               
        {SHARP,            8},  -- agnetID and BANTER.CROSS line
        {XU,                 28},          
        {SHARP,            9},                
        }
    },  

    {id = 41,
     agents = {XU,SHARP},
     dialogue = {  -- agent IDs    
              
        {SHARP,            10},  -- agnetID and BANTER.CROSS line
        {XU,                 29},          
        {SHARP,            11},  
        {XU,                 30}, 
        }
    },

    {id = 42,
     agents = {XU,SHARP},
     dialogue = {  -- agent IDs  
        {XU,                 31},  
        {SHARP,            12},  -- agnetID and BANTER.CROSS line                             
        }
    },    

    {id = 43,
     agents = {XU,SHARP},
     dialogue = {  -- agent IDs          
        {SHARP,            13},  -- agnetID and BANTER.CROSS line                             
        {XU,                 32},          
        {SHARP,            14},          
        }
    },    

    {id = 44,
     agents = {XU,PRISM},
     dialogue = {  -- agent IDs          
        {XU,                 33},           
        {PRISM,            7},  -- agnetID and BANTER.CROSS line                             
        {XU,                 34},          
        {PRISM,            8},          
        }
    },  

    {id = 45,
     agents = {XU,PRISM},
     dialogue = {  -- agent IDs          
        {PRISM,            9},  -- agnetID and BANTER.CROSS line                             
        {XU,                 35},                  
        }
    }, 

    {id = 46,
     agents = {XU,PRISM},
     dialogue = {  -- agent IDs 
        {XU,                 36},                
        {PRISM,            10},  -- agnetID and BANTER.CROSS line                             
        {XU,                 37},          
        {PRISM,            11},                     
        }
    }, 

    {id = 47,
     agents = {XU,PRISM},
     dialogue = {  -- agent IDs 
        {PRISM,            12},           
        {XU,                 38},                
        {PRISM,            13},  -- agnetID and BANTER.CROSS line                             
        {XU,                 39},                         
        }
    },          


    {id = 48,
     agents = {XU,BANKS},
     dialogue = {  -- agent IDs          
        {XU,                 40},                
        {BANKS,            9},  -- agnetID and BANTER.CROSS line                                                   
        }
    },     

    {id = 49,
     agents = {XU,BANKS},
     dialogue = {  -- agent IDs                  
        {BANKS,            10},  -- agnetID and BANTER.CROSS line                                                   
        {XU,                 41},            
        {BANKS,            11},    
        }
    }, 

    {id = 50,
     agents = {XU,BANKS},
     dialogue = {  -- agent IDs                  
        {XU,                 42},        
        {BANKS,            12},  -- agnetID and BANTER.CROSS line                                                   
        {XU,                 43},            
        {BANKS,            13},    
        }
    }, 

    {id = 51,
     agents = {XU,BANKS},
     dialogue = {  -- agent IDs                        
        {BANKS,            14},  -- agnetID and BANTER.CROSS line                                                   
        {XU,                 44},            
        {BANKS,            15},    
        }
    },     

}

