-- Autogenerated lua file by the Spyface tool
-- 'Wimps and posers -- leave the hall! -- ManOwaR
--
-- DO NOT HAND EDIT.
--
local tiles =
{
    {
        x = 3,
        y = 1,
        variant = 0,
        dynamic_impass = 1,
    },
    {
        x = 3,
        y = 2,
        variant = 0,
    },
    {
        x = 4,
        y = 1,
        variant = 0,
    },
    {
        x = 4,
        y = 2,
        variant = 0,
    },
    {
        x = 2,
        y = 1,
        variant = 0,
    },
    {
        x = 2,
        y = 2,
        variant = 0,
    },
    {
        x = 5,
        y = 1,
        variant = 0,
    },
    {
        x = 1,
        y = 1,
        variant = 0,
    },
}
local walls =
{
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
        x = 5,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 4,
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
}
local units =
{
    {
        maxCount = 1,
        spawnChance = 1,
        {
            {
                x = 3,
                y = 1,
                template = [[mini_server_terminal]],
                unitData =
                {
                    facing = 2,
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
                id0 = 0,
                x0 = 5,
                y0 = 1,
                id1 = 1,
                x1 = 4,
                y1 = 1,
            },
            {
                id0 = 1,
                x0 = 2,
                y0 = 1,
                id1 = 2,
                x1 = 1,
                y1 = 1,
            },
            {
                id0 = 1,
                x0 = 3,
                y0 = 2,
                id1 = 103,
                x1 = 3,
                y1 = 1,
            },
            {
                id0 = 1,
                x0 = 4,
                y0 = 1,
                id1 = 103,
                x1 = 3,
                y1 = 1,
            },
            {
                id0 = 4,
                x0 = 3,
                y0 = 0,
                id1 = 103,
                x1 = 3,
                y1 = 1,
            },
            {
                id0 = 1,
                x0 = 2,
                y0 = 1,
                id1 = 103,
                x1 = 3,
                y1 = 1,
            },
        },
    },
    width = 5,
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
