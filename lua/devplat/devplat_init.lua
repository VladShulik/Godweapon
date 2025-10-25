DEVPLAT_INIT_FINISHED = true

local dir = "devplat/meta/"
local include = include
local AddCSLuaFile = AddCSLuaFile

local function IncludeAddCS(file)
    AddCSLuaFile(file)
    include(file)
end

if SERVER then MsgC(Color(0,255,255), "[Long Devplat Revolver] Initializing...\n") end

-- Server (and Client)
IncludeAddCS(dir..'overrides/meta_overrides.lua')

IncludeAddCS(dir..'overrides/main_overrides.lua')
IncludeAddCS(dir..'overrides/physgun_overrides.lua')
IncludeAddCS(dir..'overrides/addon/boolit.lua')
IncludeAddCS(dir..'overrides/addon/npc_playerkillers.lua')
IncludeAddCS(dir..'overrides/addon/weapon_giver_remover.lua')

-- Client
IncludeAddCS(dir..'entinfo.lua')
IncludeAddCS(dir..'devplatMenu.lua')
IncludeAddCS(dir..'overrides/show_real_info.lua')

local e = FindMetaTable( "Entity" )
local gc = e.GetClass

hook.Add("OnEntityCreated","devplat_getrealmodel_init",function(ent)
    ent.GetRealClass = function(self)
        return gc(self)
    end
end)

if SERVER then MsgC(Color(0,255,255), "[Long Devplat Revolver] All files loaded!\n") end
