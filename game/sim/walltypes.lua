----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local simdefs = include( "sim/simdefs" )

local cdefs = include( "client_defs" )

local WALL_TYPES =
{
	default_wall =
    {
        door = false,
        locked = false,
        keybits = simdefs.DOOR_KEYS.WALL,	
    },
	office_door =
    {
        door = true,
		closed = true,
        locked = false,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.OFFICE,
		wallUVs = { unlocked = cdefs.WALL_DOOR_UNLOCKED, locked = cdefs.WALL_DOOR_LOCKED, broken = cdefs.WALL_DOOR_BROKEN },
    },
	security_door =
    {
        door = true,
		closed = true,
        locked = true,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        secure = true,
        keybits =  simdefs.DOOR_KEYS.SECURITY,
		wallUVs = { unlocked = cdefs.WALL_DOOR_UNLOCKED, locked = cdefs.WALL_DOOR_LOCKED, broken = cdefs.WALL_DOOR_BROKEN },
	},
    guard_door =
    {
        door = true,
        closed = true,
        locked = false,
        guarddoor = true,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,                
        keybits =  simdefs.DOOR_KEYS.GUARD,
        wallUVs = { unlocked = cdefs.WALL_SECURITY_UNLOCKED, locked = cdefs.WALL_SECURITY_LOCKED },
        altwallUVs = { unlocked = cdefs.WALL_SECURITY_UNLOCKED_ALT, locked = cdefs.WALL_SECURITY_LOCKED_ALT },
    },    
    guard_door_alt =
    {
        door = true,
        closed = true,
        locked = false,
        guarddoor = true,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,                
        keybits =  simdefs.DOOR_KEYS.GUARD,
        wallUVs = { unlocked = cdefs.WALL_SECURITY_UNLOCKED_ALT, locked = cdefs.WALL_SECURITY_LOCKED_ALT },
        altwallUVs = { unlocked = cdefs.WALL_SECURITY_UNLOCKED, locked = cdefs.WALL_SECURITY_LOCKED },
    },        
    elevator =
    {
        door = true,
        closed = true,
        locked = true,
        openSound = simdefs.SOUND_ELEVATOR_OPEN,
        closeSound = simdefs.SOUND_ELEVATOR_CLOSE,        
        keybits =  simdefs.DOOR_KEYS.ELEVATOR,
        wallUVs = { unlocked = cdefs.WALL_ELEVATOR_UNLOCKED, locked = cdefs.WALL_ELEVATOR_LOCKED },
        altwallUVs = { unlocked = cdefs.WALL_ELEVATOR_UNLOCKED_ALT, locked = cdefs.WALL_ELEVATOR_LOCKED_ALT },
    },
    elevator_alt =
    {
        door = true,
        closed = true,
        locked = true,
        openSound = simdefs.SOUND_ELEVATOR_OPEN,
        closeSound = simdefs.SOUND_ELEVATOR_CLOSE,        
        keybits =  simdefs.DOOR_KEYS.ELEVATOR,
        wallUVs = { unlocked = cdefs.WALL_ELEVATOR_UNLOCKED_ALT, locked = cdefs.WALL_ELEVATOR_LOCKED_ALT },
        altwallUVs = { unlocked = cdefs.WALL_ELEVATOR_UNLOCKED, locked = cdefs.WALL_ELEVATOR_LOCKED },
    },

    vault_door =
    {
        door = true,
        closed = true,
        locked = true,
        vault_door = true,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.VAULT,
        wallUVs = { unlocked = cdefs.WALL_DOOR_UNLOCKED, locked = cdefs.WALL_DOOR_LOCKED, broken = cdefs.WALL_DOOR_BROKEN },
    },

    special_exit_door =
    {
        door = true,
        closed = true,
        locked = true,
        vault_door = true,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.SPECIAL_EXIT,
        wallUVs = { unlocked = cdefs.WALL_DOOR_UNLOCKED, locked = cdefs.WALL_DOOR_LOCKED, broken = cdefs.WALL_DOOR_BROKEN },
    },

    final_door =
    {
        door = true,
        
        closed = true,
        locked = true,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.FINAL_LEVEL,
        no_close = true, 
        wallUVs = { unlocked = cdefs.WALL_DOOR_FINAL, locked = cdefs.WALL_DOOR_FINAL, broken = cdefs.WALL_DOOR_BROKEN },
    },
    final_door_alt =
    {
        door = true,
        closed = true,
        locked = true,
        no_close = true, 
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.FINAL_LEVEL,
        wallUVs = { unlocked = cdefs.WALL_DOOR_FINAL_ALT, locked = cdefs.WALL_DOOR_FINAL_ALT, broken = cdefs.WALL_DOOR_BROKEN },
        altwallUVs = { unlocked = cdefs.WALL_DOOR_FINAL_ALT2, locked = cdefs.WALL_DOOR_FINAL_ALT2, broken = cdefs.WALL_DOOR_BROKEN },
    },
    final_door_alt2 =
    {
        door = true,
        closed = true,
        locked = true,
        no_close = true, 
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.FINAL_LEVEL,
        wallUVs = { unlocked = cdefs.WALL_DOOR_FINAL_ALT2, locked = cdefs.WALL_DOOR_FINAL_ALT2, broken = cdefs.WALL_DOOR_BROKEN },
        altwallUVs = { unlocked = cdefs.WALL_DOOR_FINAL_ALT, locked = cdefs.WALL_DOOR_FINAL_ALT, broken = cdefs.WALL_DOOR_BROKEN },
    },    

    blast_door =
    {
        door = true,
        closed = true,
        locked = true,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.BLAST_DOOR,
        wallUVs = { unlocked = cdefs.WALL_DOOR_FINAL_ALT2, locked = cdefs.WALL_DOOR_FINAL_ALT2, broken = cdefs.WALL_DOOR_BROKEN },
        altwallUVs = { unlocked = cdefs.WALL_DOOR_FINAL_ALT, locked = cdefs.WALL_DOOR_FINAL_ALT, broken = cdefs.WALL_DOOR_BROKEN },
    },    


    --SPECIAL DOORS

    jones_door =
    {
        door = true,
        closed = true,
        locked = false,
        closeEndTurn = true,
        lockEndTurn = true,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.SECURITY,
        wallUVs = { unlocked = cdefs.WALL_DOOR_UNLOCKED, locked = cdefs.WALL_DOOR_LOCKED, broken = cdefs.WALL_DOOR_BROKEN },
    },

    grizzly_door =
    {
        door = true,
        closed = true,
        locked = false,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.OFFICE,
        wallUVs = { unlocked = cdefs.WALL_DOOR_UNLOCKED, locked = cdefs.WALL_DOOR_LOCKED, broken = cdefs.WALL_DOOR_BROKEN },
    },

    mud_door =
    {
        door = true,
        closed = true,
        locked = false,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.OFFICE,
        wallUVs = { unlocked = cdefs.WALL_DOOR_UNLOCKED, locked = cdefs.WALL_DOOR_LOCKED, broken = cdefs.WALL_DOOR_BROKEN },
    },

    hardwire_door =
    {
        door = true,
        closed = true,
        locked = true,
        openSound = simdefs.SOUND_DOOR_OPEN,
        closeSound = simdefs.SOUND_DOOR_CLOSE,
        breakSound = simdefs.SOUND_DOOR_BREAK,
        keybits =  simdefs.DOOR_KEYS.HARDWIRE,
        wallUVs = { unlocked = cdefs.WALL_DOOR_UNLOCKED, locked = cdefs.WALL_DOOR_LOCKED, broken = cdefs.WALL_DOOR_BROKEN },
    },


}

return WALL_TYPES
