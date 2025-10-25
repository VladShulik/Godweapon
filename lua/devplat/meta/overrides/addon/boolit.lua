-- Boolit by Parakeet
-- https://steamcommunity.com/sharedfiles/filedetails/?id=476913992

-- Blocking Boolit overrides for Devplat
local addons = engine.GetAddons()
local class = "long_devplat_revolver"

local function BlockBoolit()
    if CLIENT then return end

    local function awpn(ply)
        if not ply:IsPlayer() then return end
        local wpn = ply:GetActiveWeapon()

        return ply:Alive() and IsValid(ply) and IsValid(wpn) and wpn:GetClass() == class or false
    end

    local function StopBoolit(ply, bulletData)
        if awpn(ply) then return true end
    end

    local hookAdd = hook.Add
    hook.Add = function(eventName, identifier, func, ...)
        if eventName == "EntityFireBullets" and identifier == "boolit_override" then
            local old = func or function() end

            func = function(...)
                local block = StopBoolit(...)

                if block ~= nil and block == true then return end
                return old(...)
            end
        end
        -- Stop Boolit overrides for Devplat

        if eventName == "EntityTakeDamage" and identifier == "boolit_fix_xbow" then
            local old = func or function() end

            func = function(ent, dmginfo)
                local inflictor = dmginfo:GetInflictor()

                if not IsValid(inflictor) then return end
                return old(ent, dmginfo)
            end
        end
        -- This one is a bugfix for the original addon

        return hookAdd(eventName, identifier, func, ...)
    end
end

for __, addon in pairs(addons) do
    if addon.wsid and addon.wsid == "476913992" then
        BlockBoolit()
    end
end