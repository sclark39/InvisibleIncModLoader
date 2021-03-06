-- Autogenerated lua file by the Spyface tool
-- 'Wimps and posers -- leave the hall! -- ManOwaR
--
-- DO NOT HAND EDIT.
--
local tiles =
{
    {
        x = 2,
        y = 2,
        variant = 1,
    },
    {
        x = 2,
        y = 3,
        variant = 1,
    },
    {
        x = 2,
        y = 4,
        variant = 1,
    },
    {
        x = 2,
        y = 5,
        variant = 1,
    },
    {
        x = 2,
        y = 6,
        variant = 1,
    },
    {
        x = 3,
        y = 2,
        variant = 0,
    },
    {
        x = 3,
        y = 3,
        variant = 0,
    },
    {
        x = 3,
        y = 4,
        variant = 0,
    },
    {
        x = 3,
        y = 5,
        variant = 0,
    },
    {
        x = 3,
        y = 6,
        variant = 0,
    },
    {
        x = 1,
        y = 2,
        variant = 0,
    },
    {
        x = 1,
        y = 3,
        variant = 0,
    },
    {
        x = 1,
        y = 4,
        variant = 0,
    },
    {
        x = 1,
        y = 5,
        variant = 0,
    },
    {
        x = 1,
        y = 6,
        variant = 0,
    },
    {
        x = 3,
        y = 1,
        variant = 0,
    },
    {
        x = 2,
        y = 1,
        zone = [[solid]],
        variant = 0,
        impass = 1,
    },
    {
        x = 1,
        y = 1,
        variant = 0,
    },
    {
        x = 3,
        y = 7,
        variant = 0,
    },
    {
        x = 2,
        y = 7,
        zone = [[solid]],
        variant = 0,
        impass = 1,
    },
    {
        x = 1,
        y = 7,
        variant = 0,
    },
}
local walls =
{
    {
        x = 2,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 2,
        y = 2,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 2,
        y = 6,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 2,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 3,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 2,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 2,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 1,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 0,
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
        y = 7,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 2,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 2,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 2,
        y = 8,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 2,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 1,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 0,
    },
}
local units =
{
    {
        maxCount = 1,
        spawnChance = 1,
        {
            {
                x = 2,
                y = 2,
                template = [[security_infrared_emitter_1x1]],
                unitData =
                {
                    facing = 2, traits = { startOn = true },
                },
            },
            1,
        },
    },
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
                id0 = 100,
                x0 = 2,
                y0 = 1,
                id1 = 1,
                x1 = 2,
                y1 = 2,
            },
            {
                id0 = 1,
                x0 = 2,
                y0 = 6,
                id1 = 102,
                x1 = 2,
                y1 = 7,
            },
            {
                id0 = 100,
                x0 = 2,
                y0 = 1,
                id1 = 1,
                x1 = 1,
                y1 = 1,
            },
            {
                id0 = 3,
                x0 = 2,
                y0 = 0,
                id1 = 100,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 102,
                x0 = 2,
                y0 = 7,
                id1 = 4,
                x1 = 2,
                y1 = 8,
            },
            {
                id0 = 102,
                x0 = 2,
                y0 = 7,
                id1 = 1,
                x1 = 1,
                y1 = 7,
            },
            {
                id0 = 1,
                x0 = 2,
                y0 = 2,
                id1 = 100,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 1,
                x0 = 3,
                y0 = 1,
                id1 = 100,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 3,
                x0 = 2,
                y0 = 0,
                id1 = 100,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 1,
                x0 = 1,
                y0 = 1,
                id1 = 100,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 4,
                x0 = 2,
                y0 = 8,
                id1 = 102,
                x1 = 2,
                y1 = 7,
            },
            {
                id0 = 1,
                x0 = 3,
                y0 = 7,
                id1 = 102,
                x1 = 2,
                y1 = 7,
            },
            {
                id0 = 1,
                x0 = 2,
                y0 = 6,
                id1 = 102,
                x1 = 2,
                y1 = 7,
            },
            {
                id0 = 1,
                x0 = 1,
                y0 = 7,
                id1 = 102,
                x1 = 2,
                y1 = 7,
            },
        },
    },
    width = 3,
    height = 7,
    version = 1,
    tiles = tiles,
    walls = walls,
    units = units,
    decos = decos,
    lights = lights,
    sounds = sounds,
}
return export
