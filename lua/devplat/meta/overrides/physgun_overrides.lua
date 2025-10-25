-- This override will make you able to Physgun anything as long as you have Devplat
-- Some hooks block Physgun Pickup on some entities

local hookAdd = hook.Add
local hookGetTable = hook.GetTable
local class = "long_devplat_revolver"

local function AllowPhysgun(ply, ent)
    return IsValid(ply) and ply:HasWeapon(class) or false
end

local function isvalid(ent)
    return ent and ent:IsValid() or false
end

hook.Add = function(eventName, identifier, call, ...)
    if eventName == "PhysgunPickup" then
        local old = call
        call = function(...)
            local args = {...}
            if !isvalid(args[1]) or !isvalid(args[2]) then return true end

            if AllowPhysgun(...) == true then old(...) return true end
            return old(...)
        end
    end
    return hookAdd(eventName, identifier, call, ...)
end