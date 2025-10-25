-- Devplat Fail Load Safe (tm)
-- If Devplat Files didn't load correctly, this will load them.

if !DEVPLAT_INIT_FINISHED then
    DEVPLAT_INIT_FINISHED = true

    AddCSLuaFile('devplat/devplat_init.lua')
    include('devplat/devplat_init.lua')
end