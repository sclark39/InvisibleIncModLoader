-- Autogenerated lua file by the Spyface tool
-- 'Wimps and posers -- leave the hall! -- ManOwaR
--
-- DO NOT HAND EDIT.
--
local tiles =
{
    {
        x = 2,
        y = 1,
        zone = [[elevator_guard]],
        variant = 2,
        tags =
        {
            "guard_spawn",
            "noguard",
        },
    },
    {
        x = 2,
        y = 2,
        zone = [[elevator_guard]],
        variant = 0,
        tags =
        {
            "guard_spawn",
            "noguard",
        },
    },
    {
        x = 3,
        y = 1,
        zone = [[elevator_guard]],
        variant = 3,
        tags =
        {
            "guard_spawn",
            "noguard",
        },
    },
    {
        x = 3,
        y = 2,
        zone = [[elevator_guard]],
        variant = 1,
        tags =
        {
            "guard_spawn",
            "noguard",
        },
    },
    {
        x = 1,
        y = 1,
        variant = 0,
        tags =
        {
            "door_front",
        },
    },
    {
        x = 1,
        y = 2,
        variant = 0,
        tags =
        {
            "door_front",
        },
    },
}
local walls =
{
    {
        x = 2,
        y = 1,
        wallIndex = [[guard_door]],
        dir = 4,
    },
    {
        x = 1,
        y = 1,
        wallIndex = [[guard_door]],
        dir = 0,
    },
    {
        x = 2,
        y = 2,
        wallIndex = [[guard_door_alt]],
        dir = 4,
    },
    {
        x = 1,
        y = 2,
        wallIndex = [[guard_door_alt]],
        dir = 0,
    },
    {
        x = 4,
        y = 2,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 3,
        y = 2,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 4,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 3,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 2,
        y = 2,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 2,
        y = 3,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 3,
        y = 2,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 3,
        y = 3,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 2,
        y = 0,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 2,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 3,
        y = 0,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 3,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 6,
    },
}
local units =
{
}
local decos =
{
}
local lights =
{
}
local sounds =
{
}
local export =
{
    cgraph =
    {
        edges =
        {
            {
                id0 = 0,
                x0 = 2,
                y0 = 2,
                id1 = 1,
                x1 = 2,
                y1 = 3,
            },
            {
                id0 = 0,
                x0 = 3,
                y0 = 2,
                id1 = 2,
                x1 = 3,
                y1 = 3,
            },
            {
                id0 = 3,
                x0 = 2,
                y0 = 0,
                id1 = 0,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 4,
                x0 = 3,
                y0 = 0,
                id1 = 0,
                x1 = 3,
                y1 = 1,
            },
        },
    },
    width = 4,
    height = 2,
    version = 1,
    tiles = tiles,
    walls = walls,
    units = units,
    decos = decos,
    lights = lights,
    sounds = sounds,
}
return export
