if SERVER then return end
-- Some entities obfuscate their true info with random garbage
-- These overrides will show their real information (usually on Entity Info addons) if you are holding Devplat

local ENT = FindMetaTable("Entity")
local LocalPlayer = LocalPlayer
local GetClass = ENT.GetClass
local Health = ENT.Health
local GetMaxHealth = ENT.GetMaxHealth

local class = "long_devplat_revolver"
local function awpn(ply)
    if !ply:IsPlayer() then return end
    local wpn = ply:GetActiveWeapon()

    return ply:Alive() and IsValid(ply) and IsValid(wpn) and GetClass(wpn) == class or false
end

local function OverrideAll()
    local old = ENT.GetClass
    ENT.GetClass = function(self, ...)
        if awpn(LocalPlayer()) then
            return GetClass(self, ...)
        end
    
        return old(self, ...)
    end

    local old = ENT.Health
    ENT.Health = function(self, ...)
        if awpn(LocalPlayer()) then
            return Health(self, ...)
        end
    
        return old(self, ...)
    end

    local old = ENT.GetMaxHealth
    ENT.GetMaxHealth = function(self, ...)
        if awpn(LocalPlayer()) then
            return GetMaxHealth(self, ...)
        end
    
        return old(self, ...)
    end
end

timer.Simple(0.5, OverrideAll)