--

local function hasdevplat(e)
    if !isentity(e) or !e:IsPlayer() then return end
    local wep = e:GetActiveWeapon()

    return (IsValid(wep) and wep:GetClass() == 'long_devplat_revolver') or false
end

local function npc_playerkillers()
    for k,v in pairs({'NPC','NextBot'}) do
        local meta = FindMetaTable(v)
        local old = meta['__index']

        meta['__index'] = function(ent,k,...)
            local _old = old(ent,k,...)

            if isentity(ent) and isfunction(_old) then
                return function(t,n,...)
                    if hasdevplat(n) then return end
                    return _old(t,n,...)
                end
            end

            return _old
        end
    end
end

timer.Simple(0.2,npc_playerkillers)