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
    },
    {
        x = 4,
        y = 1,
        variant = 0,
    },
    {
        x = 5,
        y = 1,
        variant = 0,
    },
    {
        x = 2,
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
        x = 3,
        y = 0,
        wallIndex = [[office_door]],
        dir = 2,
    },
    {
        x = 3,
        y = 1,
        wallIndex = [[office_door]],
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
}
local units =
{
}
local decos =
{
    {
        x = 2,
        y = 1,
        kanim = [[ftm_hall_curtains1]],
        facing = 2,
    },
    {
        x = 4,
        y = 1,
        kanim = [[ftm_hall_curtains1]],
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
