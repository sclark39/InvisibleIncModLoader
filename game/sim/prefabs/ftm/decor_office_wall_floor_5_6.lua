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
        impass = 1,
        cover = 1,
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
    {
        x = 5,
        y = 0,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 5,
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
        x = 4,
        y = 1,
        kanim = [[ftm_office_vent1]],
        facing = 2,
    },
    {
        x = 4,
        y = 1,
        kanim = [[ftm_office_2x1_coffee_table]],
        facing = 2,
    },
    {
        x = 2,
        y = 1,
        kanim = [[ftm_office_1x1_chair_1]],
        facing = 0,
    },
    {
        x = 3,
        y = 1,
        kanim = [[ftm_office_paintings2]],
        facing = 2,
    },
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
                x0 = 3,
                y0 = 0,
                id1 = 101,
                x1 = 3,
                y1 = 1,
            },
            {
                id0 = 6,
                x0 = 4,
                y0 = 2,
                id1 = 101,
                x1 = 4,
                y1 = 1,
            },
            {
                id0 = 7,
                x0 = 5,
                y0 = 1,
                id1 = 101,
                x1 = 4,
                y1 = 1,
            },
            {
                id0 = 8,
                x0 = 4,
                y0 = 0,
                id1 = 101,
                x1 = 4,
                y1 = 1,
            },
        },
    },
    width = 5,
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
