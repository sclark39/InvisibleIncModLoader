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
        zone = [[server]],
        variant = 3,
        impass = 1,
        cover = 1,
    },
    {
        x = 1,
        y = 2,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 1,
        y = 3,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 1,
        y = 4,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 1,
        y = 5,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 1,
        y = 6,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 1,
        y = 7,
        zone = [[server]],
        variant = 3,
        impass = 1,
        cover = 1,
    },
    {
        x = 2,
        y = 1,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 2,
        y = 2,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 2,
        y = 3,
        zone = [[server]],
        variant = 1,
        impass = 1,
        cover = 1,
    },
    {
        x = 2,
        y = 4,
        zone = [[server]],
        variant = 1,
        impass = 1,
        cover = 1,
    },
    {
        x = 2,
        y = 5,
        zone = [[server]],
        variant = 1,
        impass = 1,
        cover = 1,
    },
    {
        x = 2,
        y = 6,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 2,
        y = 7,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 3,
        y = 1,
        zone = [[server]],
        variant = 0,
        impass = 1,
        cover = 1,
    },
    {
        x = 3,
        y = 2,
        zone = [[server]],
        variant = 1,
    },
    {
        x = 3,
        y = 3,
        zone = [[server]],
        variant = 2,
    },
    {
        x = 3,
        y = 4,
        zone = [[server]],
        variant = 3,
        dynamic_impass = 1,
    },
    {
        x = 3,
        y = 5,
        zone = [[server]],
        variant = 2,
    },
    {
        x = 3,
        y = 6,
        zone = [[server]],
        variant = 1,
    },
    {
        x = 3,
        y = 7,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 4,
        y = 1,
        zone = [[server]],
        variant = 0,
        dynamic_impass = 1,
    },
    {
        x = 4,
        y = 2,
        zone = [[server]],
        variant = 1,
    },
    {
        x = 4,
        y = 3,
        zone = [[server]],
        variant = 2,
    },
    {
        x = 4,
        y = 4,
        zone = [[server]],
        variant = 2,
    },
    {
        x = 4,
        y = 5,
        zone = [[server]],
        variant = 2,
    },
    {
        x = 4,
        y = 6,
        zone = [[server]],
        variant = 1,
        dynamic_impass = 1,
    },
    {
        x = 4,
        y = 7,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 5,
        y = 1,
        zone = [[server]],
        variant = 0,
        impass = 1,
        cover = 1,
    },
    {
        x = 5,
        y = 2,
        zone = [[server]],
        variant = 1,
    },
    {
        x = 5,
        y = 3,
        zone = [[server]],
        variant = 2,
    },
    {
        x = 5,
        y = 4,
        zone = [[server]],
        variant = 3,
        dynamic_impass = 1,
    },
    {
        x = 5,
        y = 5,
        zone = [[server]],
        variant = 2,
    },
    {
        x = 5,
        y = 6,
        zone = [[server]],
        variant = 1,
    },
    {
        x = 5,
        y = 7,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 6,
        y = 1,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 6,
        y = 2,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 6,
        y = 3,
        zone = [[server]],
        variant = 1,
        impass = 1,
        cover = 1,
    },
    {
        x = 6,
        y = 4,
        zone = [[server]],
        variant = 1,
        impass = 1,
        cover = 1,
    },
    {
        x = 6,
        y = 5,
        zone = [[server]],
        variant = 1,
        impass = 1,
        cover = 1,
    },
    {
        x = 6,
        y = 6,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 6,
        y = 7,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 7,
        y = 1,
        zone = [[server]],
        variant = 3,
        impass = 1,
        cover = 1,
    },
    {
        x = 7,
        y = 2,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 7,
        y = 3,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 7,
        y = 4,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 7,
        y = 5,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 7,
        y = 6,
        zone = [[server]],
        variant = 0,
    },
    {
        x = 7,
        y = 7,
        zone = [[server]],
        variant = 3,
        impass = 1,
        cover = 1,
    },
}
local walls =
{
    {
        x = 1,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 0,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 1,
        y = 2,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 0,
        y = 2,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 1,
        y = 3,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 0,
        y = 3,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 1,
        y = 4,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 0,
        y = 4,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 1,
        y = 5,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 0,
        y = 5,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 1,
        y = 6,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 0,
        y = 6,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 1,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 0,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 0,
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
    {
        x = 6,
        y = 0,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 6,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 7,
        y = 0,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 7,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 8,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 7,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 8,
        y = 6,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 7,
        y = 6,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 8,
        y = 5,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 7,
        y = 5,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 8,
        y = 4,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 7,
        y = 4,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 8,
        y = 3,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 7,
        y = 3,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 8,
        y = 2,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 7,
        y = 2,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 8,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 4,
    },
    {
        x = 7,
        y = 1,
        wallIndex = [[default_wall]],
        dir = 0,
    },
    {
        x = 7,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 7,
        y = 8,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 6,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 6,
        y = 8,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 5,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 5,
        y = 8,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 3,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 3,
        y = 8,
        wallIndex = [[default_wall]],
        dir = 6,
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
        x = 1,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 1,
        y = 8,
        wallIndex = [[default_wall]],
        dir = 6,
    },
    {
        x = 4,
        y = 7,
        wallIndex = [[default_wall]],
        dir = 2,
    },
    {
        x = 4,
        y = 8,
        wallIndex = [[default_wall]],
        dir = 6,
    },
}
local units =
{
    {
        maxCount = 4,
        spawnChance = 1,
        {
            {
                x = 4,
                y = 6,
                template = [[console_core]],
                unitData =
                {
                    facing = 0,
                },
            },
            1,
        },
        {
            {
                x = 3,
                y = 4,
                template = [[console]],
                unitData =
                {
                    facing = 0,
                },
            },
            1,
        },
        {
            {
                x = 5,
                y = 4,
                template = [[console]],
                unitData =
                {
                    facing = 4,
                },
            },
            1,
        },
        {
            {
                x = 4,
                y = 1,
                template = [[server_terminal]],
                unitData =
                {
                    facing = 2,
                    tags =
                    {
                        "serverFarm",
                    },
                },
            },
            1,
        },
    },
}
local decos =
{
    {
        x = 1,
        y = 2,
        kanim = [[serverroom_walllight1]],
        facing = 0,
    },
    {
        x = 1,
        y = 6,
        kanim = [[serverroom_walllight1]],
        facing = 0,
    },
    {
        x = 7,
        y = 7,
        kanim = [[serverroom_flooring_wiring2]],
        facing = 2,
    },
    {
        x = 1,
        y = 7,
        kanim = [[serverroom_flooring_wiring1]],
        facing = 4,
    },
    {
        x = 7,
        y = 1,
        kanim = [[serverroom_1x1_gear3]],
        facing = 4,
    },
    {
        x = 1,
        y = 7,
        kanim = [[serverroom_1x1_gear3]],
        facing = 4,
    },
    {
        x = 7,
        y = 7,
        kanim = [[serverroom_1x1_gear3]],
        facing = 4,
    },
    {
        x = 5,
        y = 1,
        kanim = [[serverroom_1x1_gear1]],
        facing = 6,
    },
    {
        x = 7,
        y = 1,
        kanim = [[serverroom_walllight1]],
        facing = 2,
    },
    {
        x = 5,
        y = 1,
        kanim = [[serverroom_wallscreen1]],
        facing = 2,
    },
    {
        x = 2,
        y = 1,
        kanim = [[serverroom_wallscreen1]],
        facing = 2,
    },
    {
        x = 1,
        y = 3,
        kanim = [[serverroom_wallslats1]],
        facing = 0,
    },
    {
        x = 1,
        y = 4,
        kanim = [[serverroom_wallslats1]],
        facing = 0,
    },
    {
        x = 1,
        y = 5,
        kanim = [[serverroom_wallslats1]],
        facing = 0,
    },
    {
        x = 7,
        y = 2,
        kanim = [[serverroom_walllight1]],
        facing = 4,
    },
    {
        x = 7,
        y = 6,
        kanim = [[serverroom_walllight1]],
        facing = 4,
    },
    {
        x = 7,
        y = 5,
        kanim = [[serverroom_wallslats1]],
        facing = 4,
    },
    {
        x = 7,
        y = 4,
        kanim = [[serverroom_wallslats1]],
        facing = 4,
    },
    {
        x = 7,
        y = 3,
        kanim = [[serverroom_wallslats1]],
        facing = 4,
    },
    {
        x = 6,
        y = 3,
        kanim = [[serverroom_flooring_wiring3]],
        facing = 0,
    },
    {
        x = 3,
        y = 7,
        kanim = [[serverroom_walllight1]],
        facing = 6,
    },
    {
        x = 5,
        y = 7,
        kanim = [[serverroom_walllight1]],
        facing = 6,
    },
    {
        x = 2,
        y = 7,
        kanim = [[serverroom_wallslats1]],
        facing = 6,
    },
    {
        x = 6,
        y = 7,
        kanim = [[serverroom_wallslats1]],
        facing = 6,
    },
    {
        x = 2,
        y = 3,
        kanim = [[serverroom_flooring_wiring3]],
        facing = 0,
    },
    {
        x = 1,
        y = 1,
        kanim = [[serverroom_1x1_gear3]],
        facing = 0,
    },
    {
        x = 6,
        y = 3,
        kanim = [[serverroom_1x3_gear2]],
        facing = 0,
    },
    {
        x = 2,
        y = 3,
        kanim = [[serverroom_1x3_gear2]],
        facing = 0,
    },
    {
        x = 3,
        y = 1,
        kanim = [[serverroom_1x1_gear1]],
        facing = 2,
    },
    {
        x = 4,
        y = 1,
        kanim = [[serverroom_walllight1]],
        facing = 2,
    },
    {
        x = 1,
        y = 1,
        kanim = [[serverroom_walllight1]],
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
                id0 = 100,
                x0 = 1,
                y0 = 1,
                id1 = 1,
                x1 = 0,
                y1 = 1,
            },
            {
                id0 = 100,
                x0 = 1,
                y0 = 2,
                id1 = 2,
                x1 = 0,
                y1 = 2,
            },
            {
                id0 = 100,
                x0 = 1,
                y0 = 3,
                id1 = 3,
                x1 = 0,
                y1 = 3,
            },
            {
                id0 = 100,
                x0 = 1,
                y0 = 4,
                id1 = 4,
                x1 = 0,
                y1 = 4,
            },
            {
                id0 = 100,
                x0 = 1,
                y0 = 5,
                id1 = 5,
                x1 = 0,
                y1 = 5,
            },
            {
                id0 = 100,
                x0 = 1,
                y0 = 6,
                id1 = 6,
                x1 = 0,
                y1 = 6,
            },
            {
                id0 = 100,
                x0 = 1,
                y0 = 7,
                id1 = 7,
                x1 = 0,
                y1 = 7,
            },
            {
                id0 = 8,
                x0 = 1,
                y0 = 0,
                id1 = 100,
                x1 = 1,
                y1 = 1,
            },
            {
                id0 = 9,
                x0 = 2,
                y0 = 0,
                id1 = 100,
                x1 = 2,
                y1 = 1,
            },
            {
                id0 = 10,
                x0 = 3,
                y0 = 0,
                id1 = 100,
                x1 = 3,
                y1 = 1,
            },
            {
                id0 = 11,
                x0 = 4,
                y0 = 0,
                id1 = 100,
                x1 = 4,
                y1 = 1,
            },
            {
                id0 = 12,
                x0 = 5,
                y0 = 0,
                id1 = 100,
                x1 = 5,
                y1 = 1,
            },
            {
                id0 = 13,
                x0 = 6,
                y0 = 0,
                id1 = 100,
                x1 = 6,
                y1 = 1,
            },
            {
                id0 = 14,
                x0 = 7,
                y0 = 0,
                id1 = 100,
                x1 = 7,
                y1 = 1,
            },
            {
                id0 = 15,
                x0 = 8,
                y0 = 7,
                id1 = 100,
                x1 = 7,
                y1 = 7,
            },
            {
                id0 = 16,
                x0 = 8,
                y0 = 6,
                id1 = 100,
                x1 = 7,
                y1 = 6,
            },
            {
                id0 = 17,
                x0 = 8,
                y0 = 5,
                id1 = 100,
                x1 = 7,
                y1 = 5,
            },
            {
                id0 = 18,
                x0 = 8,
                y0 = 4,
                id1 = 100,
                x1 = 7,
                y1 = 4,
            },
            {
                id0 = 19,
                x0 = 8,
                y0 = 3,
                id1 = 100,
                x1 = 7,
                y1 = 3,
            },
            {
                id0 = 20,
                x0 = 8,
                y0 = 2,
                id1 = 100,
                x1 = 7,
                y1 = 2,
            },
            {
                id0 = 21,
                x0 = 8,
                y0 = 1,
                id1 = 100,
                x1 = 7,
                y1 = 1,
            },
            {
                id0 = 100,
                x0 = 7,
                y0 = 7,
                id1 = 22,
                x1 = 7,
                y1 = 8,
            },
            {
                id0 = 100,
                x0 = 6,
                y0 = 7,
                id1 = 23,
                x1 = 6,
                y1 = 8,
            },
            {
                id0 = 100,
                x0 = 5,
                y0 = 7,
                id1 = 24,
                x1 = 5,
                y1 = 8,
            },
            {
                id0 = 100,
                x0 = 3,
                y0 = 7,
                id1 = 25,
                x1 = 3,
                y1 = 8,
            },
            {
                id0 = 100,
                x0 = 2,
                y0 = 7,
                id1 = 26,
                x1 = 2,
                y1 = 8,
            },
            {
                id0 = 100,
                x0 = 1,
                y0 = 7,
                id1 = 27,
                x1 = 1,
                y1 = 8,
            },
            {
                id0 = 100,
                x0 = 4,
                y0 = 7,
                id1 = 28,
                x1 = 4,
                y1 = 8,
            },
            {
                id0 = 8,
                x0 = 1,
                y0 = 0,
                id1 = 100,
                x1 = 1,
                y1 = 1,
            },
            {
                id0 = 1,
                x0 = 0,
                y0 = 1,
                id1 = 100,
                x1 = 1,
                y1 = 1,
            },
            {
                id0 = 27,
                x0 = 1,
                y0 = 8,
                id1 = 100,
                x1 = 1,
                y1 = 7,
            },
            {
                id0 = 7,
                x0 = 0,
                y0 = 7,
                id1 = 100,
                x1 = 1,
                y1 = 7,
            },
            {
                id0 = 10,
                x0 = 3,
                y0 = 0,
                id1 = 100,
                x1 = 3,
                y1 = 1,
            },
            {
                id0 = 11,
                x0 = 4,
                y0 = 0,
                id1 = 100,
                x1 = 4,
                y1 = 1,
            },
            {
                id0 = 12,
                x0 = 5,
                y0 = 0,
                id1 = 100,
                x1 = 5,
                y1 = 1,
            },
            {
                id0 = 21,
                x0 = 8,
                y0 = 1,
                id1 = 100,
                x1 = 7,
                y1 = 1,
            },
            {
                id0 = 14,
                x0 = 7,
                y0 = 0,
                id1 = 100,
                x1 = 7,
                y1 = 1,
            },
            {
                id0 = 22,
                x0 = 7,
                y0 = 8,
                id1 = 100,
                x1 = 7,
                y1 = 7,
            },
            {
                id0 = 15,
                x0 = 8,
                y0 = 7,
                id1 = 100,
                x1 = 7,
                y1 = 7,
            },
        },
    },
    width = 7,
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