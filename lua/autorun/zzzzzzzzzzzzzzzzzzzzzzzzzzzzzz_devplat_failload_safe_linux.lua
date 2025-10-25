-- Devplat Fail Load Safe (tm)
-- If Devplat Files didn't load correctly, this will load them.

-- [Linux, as the order is Descending]
if system.IsLinux() and not DEVPLAT_INIT_FINISHED then
    DEVPLAT_INIT_FINISHED = true

    AddCSLuaFile('devplat/devplat_init.lua')
    include('devplat/devplat_init.lua')
end
