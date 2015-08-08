-- Autogenerated lua file by the Spyface tool
-- 'Wimps and posers -- leave the hall! -- ManOwaR
--
-- DO NOT HAND EDIT.
--
local tiles =
{
    {
        x = 1,
        y = 1,
        variant = 0,
    },
    {
        x = 2,
        y = 1,
        variant = 0,
        impass = 1,
        cover = 1,
    },
    {
        x = 3,
        y = 1,
        variant = 0,
        impass = 1,
        cover = 1,
    },
    {
        x = 4,
        y = 1,
        variant = 0,
    },
}
local walls =
{
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
        x = 1,
        y = 0,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 1,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 4,
        y = 0,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 4,
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
    {
        x = 3,
        y = 1,
        kanim = [[ftm_lab_gear2]],
        facing = 4,
    },
    {
        x = 2,
        y = 1,
        kanim = [[ftm_lab_gear1]],
        facing = 2,
    },
}
local lights =
{
}
local sounds =
{
    {
        name = [[Objects/FTM/gear_1]],
        x = 2,
        y = 1,
    },
    {
        name = [[Objects/FTM/gear_2]],
        x = 3,
        y = 1,
    },
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
                id1 = 101,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 2,
                x0 = 2,
                y0 = 0,
                id1 = 101,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 3,
                x0 = 1,
                y0 = 1,
                id1 = 101,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 4,
                x0 = 3,
                y0 = 2,
                id1 = 101,
                x1 = 3,
                y1 = 1,
            },
            {
                id0 = 5,
                x0 = 4,
                y0 = 1,
                id1 = 101,
                x1 = 3,
                y1 = 1,
            },
            {
                id0 = 6,
                x0 = 3,
                y0 = 0,
                id1 = 101,
                x1 = 3,
                y1 = 1,
            },
        },
    },
    width = 4,
    height = 1,
    version = 1,
    tiles = tiles,
    walls = walls,
    units = units,
    decos = decos,
    lights = lights,
    sounds = sounds,
}
return export
