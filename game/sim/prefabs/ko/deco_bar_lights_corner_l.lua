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
        x = 1,
        y = 2,
        variant = 0,
    },
    {
        x = 1,
        y = 3,
        variant = 0,
    },
}
local walls =
{
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
}
local units =
{
}
local decos =
{
    {
        x = 1,
        y = 2,
        kanim = [[decor_ko_barracks_walllight1]],
        facing = 0,
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
        },
    },
    width = 1,
    height = 3,
    version = 1,
    tiles = tiles,
    walls = walls,
    units = units,
    decos = decos,
    lights = lights,
    sounds = sounds,
}
return export
