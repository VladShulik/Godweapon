local ENT = FindMetaTable( "Entity" )
local Health = ENT.Health
local MaxHealth = ENT.GetMaxHealth
local Class = ENT.GetClass

timer.Simple(1, function()
if CLIENT then
    surface.CreateFont("HEntInfoTitle", {
		font = "Roboto",
		size = ScreenScale(9),
        shadow = false,
        outline = true,
	})
    surface.CreateFont("HEntInfoBody", {
		font = "Roboto",
		size = ScreenScale(5),
		shadow = false,
        outline = true,
	})
end
end)

local function AddHook(name, id, func)
    local identifier = id
    local callback = func
    if isfunction(id) then
        identifier = "holidayzz_entinfo"
        callback = id
    end

    hook.Add(name, identifier, callback)
end

local function ValidEntClass(ent)
    return IsValid(ent) and ent:GetClass() or nil
end

local function PrintName(ent)
    return ent.PrintName ~= (nil or "") and ent.PrintName or (language.GetPhrase(Class(ent)) == Class(ent) and "" or language.GetPhrase(Class(ent)))
end

local function HeadPos(ent)
    return ent:GetAttachment(ent:LookupAttachment('eyes')) ~= nil and ent:GetAttachment(ent:LookupAttachment('eyes')).Pos or ent:GetPos()
end

local function DrawHZHud()
    local ply = LocalPlayer()
    local ent = ply:GetEyeTrace().Entity

    if not ply:GetNWBool("DevplatEntityInfo") then return end
    if not ent or not ent:IsValid() then return end
    if ent.IsWorld and ent:IsWorld() then return end

    local parent = ent:GetParent()
    local children = ent:GetChildren()
    local center = ent:OBBCenter()
    local pos = (ent:LocalToWorld(Vector(center.x, center.y, ent:OBBMaxs().z))):ToScreen()

    local printPos = 125
    local classPos = 90
    local healthPos = 50

    if PrintName(ent) == "" then
        classPos = 120
        healthPos = 85
    else
        classPos = 85
        healthPos = 45
    end

    draw.SimpleText(PrintName(ent), "HEntInfoTitle", pos.x, pos.y - printPos, Color( 0, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    draw.SimpleText(Class(ent), "HEntInfoTitle", pos.x, pos.y - classPos, Color( 0, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    draw.SimpleText(Health(ent).."/"..MaxHealth(ent), "HEntInfoTitle", pos.x, pos.y - healthPos, Color( 0, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

AddHook("HUDPaint", DrawHZHud)