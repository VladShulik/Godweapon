local fmt = FindMetaTable
local lwr = string.lower
local fnd = string.find

local ent = fmt('Entity')
local ply = fmt('Player')
local nbt = fmt('NextBot')
local dmg = fmt('CTakeDamageInfo')
local isv = ent.IsValid
local getclass = ent.GetClass
local hookadd = hook.Add
local hookremove = hook.Remove
local info = debug.getinfo
local tmrsmp = timer.Simple

local cls = "long_devplat_revolver"
local devplat_hooks = {}

local function IsValid(ent)
    return isentity(ent) and isv(ent) or nil
end

local function override(meta, key, t, returns)
    if not meta then meta = _G end

    local _key = meta[key]
    if not _key then return end

    meta[key] = function(...)
        local args = {...}
        local self = args[1]

        local wpn = IsValid(self) and self:IsPlayer() and self:GetActiveWeapon() or nil
        if IsValid(self) then
            if t == "ply" and IsValid(wpn) and getclass(wpn) == cls then
                return (istable(returns) and unpack(returns)) or returns and returns or nil
            elseif t == "wpn" and getclass(self) == cls then
                return (istable(returns) and unpack(returns)) or returns and returns or nil
            end
        end

        return _key(...)
    end
end

local function q_override(meta, key, ovr)
    if not meta then meta = _G end

    local _key = meta[key]
    if not _key then return end

    meta[key] = function(...)
        local r, returns = ovr(...)
        if r then return (istable(returns) and unpack(returns)) or returns and returns or nil end

        return _key(...)
    end
end

local function awpn(ply)
    return IsValid(ply) and ply:IsPlayer() and IsValid(ply:GetActiveWeapon()) and getclass(ply:GetActiveWeapon()) == cls or false
end

override(ply, "Kill", "ply")
override(ply, "KillSilent", "ply")
override(ply, "StripWeapons", "ply")
override(ply, "SwitchToDefaultWeapon", "ply")
override(ply, "SelectWeapon", "ply")
override(ply, "SetUserGroup", "ply")
override(ent, "Fire", "wpn")
override(ent, "Input", "wpn")
override(ent, "TakeDamage", "ply")
override(ent, "TakeDamageInfo", "ply")

q_override(ent, "Remove", function(ent)
    if IsValid(ent) and getclass(ent) == cls or ent.IsFromDevplat then return true end
end)

q_override(ply, "ConCommand", function(ply, cmd)
    if awpn(ply) and fnd(lwr(cmd), "kill") then return true end
end)

q_override(ply, "StripWeapon", function(ply, wpn)
    if wpn == cls then return true end
end)

q_override(dmg, "ScaleDamage", function(self)
    local attacker = self:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() and awpn(attacker) then return true, self:GetDamage() end
end)

function hook.Remove(...)
    local r = {...}
    local i = r[2]

    if devplat_hooks[i] then return end
    return hookremove(...)
end

function hook.Add(...)
    local r = {...}
    local call = r[3]

    if devplat_hooks[r[2]] then
        return
    elseif isfunction(call) and fnd(lwr(info(call).source), "devplat/meta/overrides/main_overrides") and not devplat_hooks[r[2]] then
        devplat_hooks[r[2]] = true
    end

    return hookadd(...)
end