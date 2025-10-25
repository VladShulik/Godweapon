-- Weapon Remover/Giver by FinFET
-- https://steamcommunity.com/sharedfiles/filedetails/?id=151564834

-- Allowing this addon to remove Devplat because someone asked
-- Global remove will only remove the command activators Devplat, no one elses
local StripWeapon = FindMetaTable('Player').StripWeapon
local StripWeapons = FindMetaTable('Player').StripWeapons
local addons = engine.GetAddons()
local class = "long_devplat_revolver"

local function PardonWeaponRemoverGiver()
    if CLIENT then return end

    local function awpn(ply)
        if !ply:IsPlayer() then return end
        local wpn = ply:GetActiveWeapon()

        return ply:Alive() and IsValid(ply) and IsValid(wpn) and wpn:GetClass() == class or false
    end

    local function RemoveCWpn(ply)
        local wpn = ply:GetActiveWeapon()
        if !IsValid(wpn) then return end

        if awpn(ply) then
            timer.Simple(0.05, function()
                if !IsValid(ply) then return end
                net.Start("DevplatRestoreColorMats")
                net.Send(ply)
            
                ply:SetWalkSpeed(200)
                ply:SetRunSpeed(500)
                ply:SetJumpPower(200)
            end)
        end

        StripWeapon(ply, class)
    end

    local function RemoveWpns(ply)
        if awpn(ply) then
            timer.Simple(0.05, function()
                if !IsValid(ply) then return end
                net.Start("DevplatRestoreColorMats")
                net.Send(ply)
            
                ply:SetWalkSpeed(200)
                ply:SetRunSpeed(500)
                ply:SetJumpPower(200)
            end)
        end

        StripWeapons(ply)
    end

    local function RemoveAllWpns(ply)
        for __, p in pairs(player.GetAll()) do
            if p:HasWeapon(class) and p == ply then
                if awpn(p) then
                    timer.Simple(0.05, function()
                        if !IsValid(p) then return end
                        net.Start("DevplatRestoreColorMats")
                        net.Send(p)
                    
                        p:SetWalkSpeed(200)
                        p:SetRunSpeed(500)
                        p:SetJumpPower(200)
                    end)
                end

                StripWeapons(p)
            else
                p:StripWeapons()
            end
        end
    end

    local ovrConList = {
        wrag_remcwep = RemoveCWpn,
        wrag_remwep = RemoveWpns,
        wrag_remgwep = RemoveAllWpns
    } 

    timer.Simple(3, function()
        for i, overridde in pairs(ovrConList) do
            concommand.Add(i, overridde)
        end
    end)
end

for __, addon in pairs(addons) do
    if addon.wsid and addon.wsid == "151564834" then
        PardonWeaponRemoverGiver()
    end
end