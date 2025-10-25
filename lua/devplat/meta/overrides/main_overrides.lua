local d = FindMetaTable( "CTakeDamageInfo" )
local ply = FindMetaTable( "Player" )
local ENT = FindMetaTable( "Entity" )
local NextBot = FindMetaTable( "NextBot" )

local Remove = ENT.Remove
local TakeDamageInfo = ENT.TakeDamageInfo
local SetPos = ENT.SetPos
local GetClass = ENT.GetClass
local Input = ENT.Input

local NextThink = ENT.NextThink

local BlockRagdollList = {}
local Overrided = {}
local HookNoOverride = {}
local HookList = {}
local class = "long_devplat_revolver"

local hookAdd = hook.Add
local hookRemove = hook.Remove

local random = math.random
local char = string.char

local function BlockRagdoll(ent)
    BlockRagdollList[ent] = true
    ent:SetShouldServerRagdoll(false)

    for k,v in pairs(ent:GetTable()) do
        if string.find(string.lower(k), "ragdoll") then
            if isbool(v) or isentity(v) then ent[k] = false end
            if isfunction(v) then ent[k] = function() return end end
        end
    end
end

local old = NextBot.BecomeRagdoll
NextBot.BecomeRagdoll = function(self, ...)
    if BlockRagdollList[self] then return end
    return old(self, ...)
end

hook.Add = function(name, id, ...)
    if HookNoOverride[id] then return end
    return hookAdd(name, id, ...)
end

hook.Remove = function(name, id, ...)
    if HookNoOverride[id] then return end
    return hookRemove(name, id, ...)
end

local function isdevplat(w)
    if not IsValid(w) then return false end

    return w:GetClass() == class or false
end

local function awpn(ply)
    if not ply:IsPlayer() then return false end
    local w = ply:GetActiveWeapon()
    if not IsValid(ply) or not IsValid(w) or not ply:Alive() then return false end

    return isdevplat(w)
end

timer.Simple(0.5, function()
    net.Receive("PlayerKilled", function()
        local victim = net.ReadEntity()
        if not IsValid(victim) then return end
        if awpn(victim) then return end

        local inflictor	= net.ReadString()
        local attacker	= "#" .. net.ReadString()

        GAMEMODE:AddDeathNotice( attacker, -1, inflictor, victim:Name(), victim:Team() )
    end)
end)

if SERVER then
    util.AddNetworkString("DevplatEntityKarma")
elseif CLIENT then
    net.Receive("DevplatEntityKarma", function()
        local pos = net.ReadVector()

        local emitter = ParticleEmitter(pos, false)
        local particle = emitter:Add( Material("devplat/devplat_karma"), pos)
        if particle then
            particle:SetVelocity(Vector( 0, 0, 7.5 ))
            particle:SetColor(255,255,255)
            particle:SetLifeTime(0)
            particle:SetDieTime(1.5)
            particle:SetStartSize(14.5)
            particle:SetEndSize(14.5)
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)
            particle:SetGravity(Vector(0,0,0))
        end
    end)
end

local function RepeatOverlaySound(data, num)
    for i = 1, num do
        data.entity:EmitSound(data.sound, data.soundlevel, data.pitch, data.volume, data.channel)
    end
end

local function OverrideEntity(ent)
    local old = GAMEMODE.EntityTakeDamage
    GAMEMODE.EntityTakeDamage = function(self, e, ...)
        if IsValid(e) and e == ent then return end
        return old(self, e, ...)
    end

    local old = GAMEMODE.EntityRemoved
    GAMEMODE.EntityRemoved = function(e, ...)
        if IsValid(e) and e == ent then return end
        return old(e, ...)
    end
end

local invalidList = {}
local function SetInvalid(ent)
    invalidList[ent] = true
end

local _IsValid = IsValid
IsValid = function(ent, ...)
    if not _IsValid(ent) or invalidList[ent] or isfunction(ent) or (ent and ent.GetNWBool and ent:GetNWBool("hdzzdevplat_invalid")) then return false end
    return _IsValid(ent, ...)
end

local _isv = ENT.IsValid
ENT.IsValid = function(self, ...)
    if invalidList[self] then return false end
    return _isv(self, ...)
end

local function randomchars()
    local r = ""

    for i=1, 25 do
        r = r..char(random(32,164))
    end

    return r
end

local function RemoveNilDRGEntity(ent)
    if not DrGBase or not DrGBase._SpawnedNextbots then return end

	local tbl = DrGBase._SpawnedNextbots
	local tbl_2 = DrGBase.GetNextbots()
	table.RemoveByValue(tbl, ent)
	table.RemoveByValue(tbl_2, ent)
end

local function DKill(ply, ent, force, Ragdoll)
    RemoveNilDRGEntity(ent)

    net.Start("PlayerKilledNPC")
    net.WriteString(GetClass(ent))
    net.WriteString(GetClass(ent))
    net.WriteEntity(ply)
    net.Broadcast()

    local skin = ent:GetSkin() or 0

    ent.AcceptInput = function() return false end
    ent.OnRemove = function(self) Remove(self) return end
    ent.CustomThink = function(self) return end
    ent.Think = function(self) return end

    BlockRagdoll(ent) -- So it doesn't create two ragdolls
    Ragdoll(ent, ply, skin, force)

    local DT = DamageInfo()
    DT:SetDamageType(bit.bor(DMG_BULLET,DMG_BLAST))
    DT:SetDamage(1e9)
    DT:SetAttacker(ply)
    DT:SetDamageForce(force)

    ent:SetNWBool("DEVPLATSilentKilled",true)
    ent:SetNWBool("DevplatRemoved", true)
    ent:Fire("SelfDestruct")

    if ent:GetClass() == "npc_stalker" then
        ent:TakeDamage(1e9, ply)
        hook.Run("EntityTakeDamage", ent, DT)
        hook.Run("PostEntityTakeDamage", ent, DT)

        -- When stalkers damage you with laser, TakeDamageInfo crashes for some reason
    else
        TakeDamageInfo(ent, DT)
    end

    OverrideEntity(ent)
    SetInvalid(ent)
    Remove(ent)
    Input(ent, "Kill")
end

hookAdd("DevplatEntityKilledSelf_36483", randomchars(), function(ply, ent, dmginfo, Ragdoll)
    OverrideEntity(ent)
    SetInvalid(ent)
    Remove(ent)
    Input(ent, "Kill")
end)

hookAdd("DevplatEntityTakeDamage_36483", randomchars(), function(ent, dmginfo, Ragdoll)
    if not ent:GetNWBool("DevplatAttackerKarma") or not awpn(ent) or not IsValid(dmginfo:GetAttacker()) then return end

    local attacker = dmginfo:GetAttacker()
    local c = attacker:OBBCenter()
    if attacker:IsNPC() or attacker:IsNextBot() then
        net.Start("DevplatEntityKarma")
		net.WriteVector( attacker:LocalToWorld( Vector(c.x, c.y, attacker:OBBMaxs().z + 10 ) ) )
		net.Broadcast()

        RepeatOverlaySound({
            entity = attacker,
            sound = "devplatgun/devplat_karma.wav",
            soundlevel = 75,
            pitch = 100,
            volume = 5,
            channel = CHAN_VOICE_BASE,
        }, 50)

        local force = attacker:GetPos() - attacker:GetForward() * 1e9
        DKill(ent, attacker, force, Ragdoll)
    end
end)

hookAdd("Devplat_EntityKilled99362", randomchars(), function(ply, ent, Ragdoll)
    local force = ent:GetPos() - ply:GetPos() + ply:GetForward() * 1e9
    DKill(ply, ent, force, Ragdoll)
end)

hookAdd("DevplatTeleportEntities_263635", randomchars(), function(ent, pos)
    if not IsValid(ent) then return end

    SetPos(ent, pos)
    NextThink(ent, CurTime() + 1e9)

    timer.Simple(0.01, function()
        if not IsValid(ent) then return end
        NextThink(ent, CurTime() +0)
    end)
end)