local class = "long_devplat_revolver"
local r = math.random
local skey = r(1e9)..r(1e9)..r(1e9)..r(1e9)..r(1e9)..r(1e9)..r(1e9)..r(1e9)..r(1e9)..r(1e9)..r(1e9)..r(1e9)

local invulnerableList = {}
local rocketList = {}

local ForceRagdoll = {
	["npc_combinedropship"] = true,
	["npc_combinegunship"] = true,
}

local P = FindMetaTable("Player")
local W = FindMetaTable("Weapon")
local E = FindMetaTable("Entity")
local HardInput = E.Input

local function Awpn(self)
	if not IsValid(self) or not self:IsPlayer() then return end
	local weapon = self:GetActiveWeapon()

	return (IsValid(weapon) and weapon:GetClass() == class) and true or false
end

local SWEP = {
	Primary = {},
	Secondary = {},
}

SWEP.PrintName = "Long Devplat Revolver"
SWEP.Author = "DerHobbyRoller"
-- The original author of the Long Revolver

SWEP.Instructions = "Destroy everything."
SWEP.Spawnable = true
SWEP.AdminOnly = true


SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Ammo = "357"
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 1
SWEP.Primary.Spread = 0
SWEP.Primary.Cone = 0
SWEP.Primary.Delay = 0


SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = true


SWEP.Weight			= 7
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Slot			= 1
SWEP.SlotPos			= 2
SWEP.DrawAmmo			= true
SWEP.DrawCrosshair		= true


SWEP.ViewModel			= "models/weapons/devplat/c_357.mdl"
SWEP.WorldModel			= "models/weapons/devplat/w_357.mdl"

SWEP.Category = "Long Revolver"
SWEP.UseHands = true

SWEP.SetHoldType = "pistol"

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("VGUI/entities/iconGold")
	SWEP.IconOverride = "materials/entities/longRevolverDevplat.png"
end

local ShootSound = Sound("Weapon_357.single")

local function ClassName(ent)
	if not IsValid(ent) then return end
	local class = tostring(ent)
	class = string.TrimLeft(class, type(ent))
	class = string.TrimLeft(class, " [" .. ent:EntIndex() .. "]")
	class = string.TrimLeft(class, "[")
	class = string.TrimRight(class, "]")
	return class
end

local function AddUndoEntity(ply, self, msg, func, ...)
	undo.Create(msg)
    undo.AddEntity(self)
    undo.SetPlayer(ply)
	if func then
		undo.AddFunction(func, ...)
	end
  	undo.Finish()
  	gamemode.Call("PlayerSpawnedSENT", ply, self)
  	ply:AddCount("sents", self)
  	ply:AddCleanup("sents", self)
end

local function IsValidEntity(ent)
	for k,v in pairs(ents.GetAll()) do
		if v == ent then return true end
	end
	return false
end

local function grm(ent)
	if not SERVER then return '' end

	return ent:GetInternalVariable('model')
end

local function CreateEntityRagdoll(ent, ply, skin, force)
    if not IsValid(ent) or IsValid(ent.CorpseRag) then return end

	local model = grm(ent)
	local clr = Color(ent:GetColor().r, ent:GetColor().g, ent:GetColor().b)
    if SERVER and (model and util.IsValidRagdoll(model)) then
        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll:SetModel(model)
        ragdoll:SetSkin(skin or 0)
        ragdoll:SetPos(ent:GetPos())
        ragdoll:SetAngles(ent:GetAngles())
		ragdoll:SetColor(clr)
		ragdoll:SetMaterial(ent:GetMaterial())
        ragdoll:Spawn()

		ragdoll.isdevplatentity = true

		if IsValid(ply) then
			AddUndoEntity(ply, ragdoll, ClassName(ent))
		end

        for i = 0, ragdoll:GetPhysicsObjectCount()-1 do
            local bone = ragdoll:GetPhysicsObjectNum(i)
            local pos, ang = ent:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
            if bone and pos and ang then
                bone:SetAngles(ang)
                bone:SetPos(pos)
            end

			if force then
				bone:SetVelocity(force)
			end
        end

		ent.CorpseRag = true
    end
end

local function NPCKilledNPC(self, enemy, shouldCreateRagdoll, notice, force)
        enemy.AcceptInput = function() return false end
        enemy.OnRemove = function(self,...) self:Remove() end
        enemy.CustomThink = function(self,...) self:Remove() return end
        enemy.Think = function(self,...) self:Remove() return end
        enemy:SetNWBool("DevplatRemoved", true)
	enemy:SetNWBool("DEVPLATSilentKilled",true)

	enemy:SetShouldServerRagdoll(false)

	for k,v in pairs(enemy:GetTable()) do
		if string.find(string.lower(k), "ragdoll") then
			if isbool(v) or isentity(v) then enemy[k] = false end
			if isfunction(v) then enemy[k] = function() return end end
		end
	end

        if shouldCreateRagdoll then
                CreateEntityRagdoll(enemy, self, nil, force)
        end

	net.Start("NPCKilledNPC")
	net.WriteString( ClassName(enemy) or '' )
	net.WriteString( ClassName(enemy) or '' )
	net.WriteString( ClassName(enemy) or '' )
	net.Broadcast()

	hook.Call("EntityRemoved", {}, enemy)
	hook.Run("DevplatEntityKilledSelf_36483", self, enemy)
end

local function ExplodeEntity(ent)
	if not IsValid(ent) then return end
	if ent:IsNPC() or ent:IsNextBot() then
		local effectdata = EffectData()
		effectdata:SetOrigin(ent:GetPos())
		util.Effect( "Explosion", effectdata )
	end
end

local function MainAttack(self, enemy, ragdoll)
	if not SERVER then return end
	if IsValid(enemy) then
		enemy:SetNoDraw(false)

		if enemy:IsVehicle() then
			local effectdata = EffectData()
			effectdata:SetOrigin(enemy:GetPos())
			util.Effect( "Explosion", effectdata )
			enemy:Ignite(math.huge)
		end

		if enemy:IsNPC() or enemy:IsNextBot() then
			local model = enemy:GetModel()
			local clr = Color(enemy:GetColor().r, enemy:GetColor().g, enemy:GetColor().b)
			enemy:SetNWBool("DevplatRemoved", true)
			enemy.AcceptInput = function() return false end
			enemy.OnRemove = function(self,...) self:Remove() end
			enemy.CustomThink = function(self,...) self:Remove() return end
			enemy.Think = function(self,...) self:Remove() return end

			enemy:SetShouldServerRagdoll(false)

			for k,v in pairs(enemy:GetTable()) do
				if string.find(string.lower(k), "ragdoll") then
					if isbool(v) or isentity(v) then enemy[k] = false end
					if isfunction(v) then enemy[k] = function() return end end
				end
			end

			local shouldRagdoll = CreateEntityRagdoll
			if ragdoll == false then shouldRagdoll = function() end end
			hook.Run("Devplat_EntityKilled99362", self, enemy, shouldRagdoll)
		end
	end
end

local function GetNPCNextBotTable()
	local t = {}
	for k,v in pairs(ents.GetAll()) do
		if v:IsNextBot() or v:IsNPC() then
			table.insert(t, v)
		end
	end
	return t
end

local function SetInvalid(ent, value) end
local function IsInvalid(ent) end

local function HaloEntity(self, ent)
	if not IsValid(self) then return end

	local w = self:GetActiveWeapon()
	if not IsValid(w) then return end

	if self:GetNWBool("GRRevealEnts") and self:Alive() and w:GetClass() == class then

		if ent:IsNPC() then
			ent:SetNWBool("dispoHaloGR", true)
			if ent:Disposition(self) == D_LI then
				ent:SetNWString("dispositionColor", "0 255 0 255")
			elseif ent:Disposition(self) == D_NU then
				ent:SetNWString("dispositionColor", "255 255 255 255")
			elseif ent:Disposition(self) == D_HT then
				ent:SetNWString("dispositionColor", "255 0 0 255")
			end
		elseif ent:IsNextBot() then
			ent:SetNWBool("dispoHaloGR", true)
			if IsValid(ent.Enemy) then
				if ent.Enemy == self then
					ent:SetNWString("dispositionColor", "255 0 0 255")
				end
			elseif ent.GetEnemy and IsValid(ent:GetEnemy()) then
				if ent.Enemy == self or ent:GetEnemy() == self then
					ent:SetNWString("dispositionColor", "255 0 0 255")
				end
			elseif ent.GetClassRelationship then
				if ent:GetClassRelationship("player") == D_HT then
					ent:SetNWString("dispositionColor", "255 0 0 255")
				end
			else
				ent:SetNWString("dispositionColor", "0 255 0 255")
			end
		end
	else
		ent:SetNWBool("dispoHaloGR", false)
	end
end

local function GoodEnemyPosition(e)
	return e:LocalToWorld(e:OBBCenter()) or e:GetAttachment(e:LookupAttachment("eyes")).Pos
end

local function FilterEntities(ent)
	local t = {}
	for k,v in pairs(ents.GetAll()) do
		if v ~= ent then
			table.insert(t, v)
		end
	end
	return t
end

local function IsClassValid(value)
	for k,v in pairs(ents.FindByClass(value)) do
		if IsValid(v) and not v:GetNWBool("fakePropGR") then return true end
	end
	return false
end

local function DoEntsExistAll()
	for k,v in pairs(ents.GetAll()) do
		if v:IsNPC() or v:IsNextBot() then return true end
	end
	for k,v in pairs(ents.FindByClass("prop_*")) do
		if IsValid(v) and not v:GetNWBool("fakePropGR") then return true end
	end
	return false
end

local function Morph(ent)
	for i = 0, ent:GetBoneCount() do
		local r = math.random
		ent:ManipulateBoneScale(i, Vector( r(1,5), r(1,5), r(1,5) ))
		ent:ManipulateBonePosition(i, Vector( r(1,5), r(1,10), r(1,15) ))
		ent:ManipulateBoneAngles(i, Angle( r(1,50), r(1,50), r(1,50) ))
	end
end

local function EntityRemoveFX(ent)
    local efx = EffectData()
    efx:SetOrigin(ent:GetPos())
    efx:SetEntity(ent)
    util.Effect("entity_remove", efx, true, true)
end

local function SendLegacy(ply, txt, type, length)
	if not SERVER then return end
	net.Start("plySendLegacyGLR")
	net.WriteString(txt)
	net.WriteInt(type, 32)
	net.WriteInt(length, 32)
	net.Send(ply)
end

local function DoEntsExist()
	for k,v in pairs(ents.GetAll()) do
		if v:IsNPC() or v:IsNextBot() then
			return true
		end
	end
	return false
end

local function DeleteMenu(self)
	local removeTbl = {}
	local msg = ""
	local f = vgui.Create("DFrame")
	f:SetTitle("Remove Entities From Class... (example: prop_physics)")
	f:SetSize(ScreenScale(100),ScreenScale(20))
	f:MakePopup()
	f:Center()

	self:EmitSound("buttons/button24.wav")

	local e = vgui.Create("DTextEntry", f)
	e:SetPos(ScreenScale(2),ScreenScale(10))
	e:SetSize(ScreenScale(95),ScreenScale(5))
	e.OnEnter = function(value)
		value = value:GetText()
		if IsClassValid(value) then
			for k,v in pairs(ents.FindByClass(value)) do
				if not v:IsPlayer() then
					net.Start("LDLRemoveOnClient")
					net.WriteEntity(v)
					net.SendToServer()
					if string.EndsWith(value, "*") and IsValid(v) then
						removeTbl[ClassName(v)] = #ents.FindByClass(ClassName(v))
					else
						if IsValid(v) then
							self:PrintMessage(HUD_PRINTCENTER, "Removed " .. #ents.FindByClass(value) .. " of " .. ClassName(v))
						end
					end
					f:Close()
				else
					if value == "player" then
						self:PrintMessage(HUD_PRINTCENTER, "Can not remove players.")
						self:EmitSound("buttons/button2.wav")
					end
				end
			end
			if string.EndsWith(value, "*") and IsClassValid(value) then
				for k,v in pairs(removeTbl) do
					msg = msg .. "\n" .. "Removed " .. v .. " of " .. k
					self:PrintMessage(HUD_PRINTCENTER, msg)
					removeTbl[k] = nil
				end
			end
			self:EmitSound("buttons/button15.wav")
			self:EmitSound("buttons/button9.wav",75,100,1,CHAN_AUTO)
		else
			self:PrintMessage(HUD_PRINTCENTER, "Couldn't find any entities with that class.")
			self:EmitSound("buttons/button2.wav")
		end
	end
end

local oldTimestop = oldTimestop or {}
local timeStopData = timeStopData or {}
local timeStopDataStates = timeStopDataStates or {}
local timestopN = timestopN or false

local function TimeStopEntity(v)
	if SERVER then
		if v.IsDrGNextbot then
		else
			if v:IsNPC() or v:IsNextBot() then
				local tK = {}
				local t = v:GetTable()
				for key, i in pairs(t) do
					if key ~= "OnDieFunctions" and isfunction(i) then
						tK[key] = i
						oldTimestop[v] = tK
						v[key] = function() return end
						v:SetVar("oldTablesTimestopGLR", oldTimestop)
					end
				end
			end
		end
		v:NextThink(CurTime() + 1e9)

		local p = v:GetPhysicsObject()
		local avel = Vector(0,0,0)

		timeStopData[v] = {TPos = v:GetPos(), TAngle = v:GetAngles(), TVel = v:GetVelocity(), TAVel = avel}
		if v:GetCollisionGroup() == COLLISION_GROUP_DEBRIS then
			timeStopData[v].DebrisProp = true
		end

		for i = 0, v:GetPhysicsObjectCount() - 1 do
			local p = v:GetPhysicsObjectNum(i)
			timeStopData[v].TAVel = p:GetAngleVelocity()
			if IsValid(p) and not p:IsAsleep() then
				p:EnableMotion(false)
			end
		end

		if IsValid(p) and not p:IsAsleep() then
			if p:IsMotionEnabled() then
				p:EnableMotion(false)
			end
		end
	end
end

local function UnTimeStopEntity(v)
	if SERVER then
		local t = v:GetVar("oldTablesTimestopGLR")

		if t then
			for k, ky in pairs(t[v]) do
				v[k] = ky
			end
		end
		if timeStopData and timeStopData[v] then
			local p = v:GetPhysicsObject()
			if IsValid(p) then
				p:EnableMotion(true)

				if v:CreatedByMap() then
					if not p:IsAsleep() or timeStopData[v].DebrisProp or timeStopData[v].TVel:Length() > 0 then
						p:Wake()
						p:SetVelocity(timeStopData[v].TVel)
						if timeStopData[v].TAVel then
							p:AddAngleVelocity(timeStopData[v].TAVel)
						end
					end
				else
					p:SetVelocity(timeStopData[v].TVel)
					if timeStopData[v].TAVel then
						p:AddAngleVelocity(timeStopData[v].TAVel)
					end
				end
			end
			for i = 0, v:GetPhysicsObjectCount() - 1 do
				local p = v:GetPhysicsObjectNum(i)
				if IsValid(p) then
					p:EnableMotion(true)

					if v:CreatedByMap() then
						if not p:IsAsleep() or timeStopData[v].DebrisProp or timeStopData[v].TVel:Length() > 0 then
							p:Wake()
							p:SetVelocity(timeStopData[v].TVel)
							if timeStopData[v].TAVel then
								p:AddAngleVelocity(timeStopData[v].TAVel)
							end
						end
					else
						p:SetVelocity(timeStopData[v].TVel)
						if timeStopData[v].TAVel then
							p:AddAngleVelocity(timeStopData[v].TAVel)
						end
					end
				end
			end
			timeStopData[v] = nil
		end
		v:NextThink(CurTime())
	end
end

local function TimeStop(value)
	if SERVER then
		if value then
			for k,v in pairs(ents.GetAll()) do
				if not ( v:IsPlayer() and Awpn(v) ) then
					TimeStopEntity(v)
				end
			end
			timestopN = true
		else
			for k,v in pairs(ents.GetAll()) do
				UnTimeStopEntity(v)
			end
			timestopN = false
		end
	end
end

if SERVER then
	util.AddNetworkString("LDLRemoveOnClient")
	util.AddNetworkString("LDLOpenDeleteEntMenu")
	util.AddNetworkString("plySendLegacyGLR")
	util.AddNetworkString("GetENTDisposition")
	util.AddNetworkString("OutlineEntitiesGR")
	util.AddNetworkString("DevplatEntityKilled")
	util.AddNetworkString("DevplatRestoreColorMats")

	net.Receive("GetENTDisposition", function()
		local ent = net.ReadEntity()
		local ply = net.ReadEntity()
		if ent:IsNPC() then
			if ent:Disposition(ply) == D_LI then
				ent:SetNWString("dispositionColor", "0 255 0 255")
			elseif ent:Disposition(ply) == D_NU then
				ent:SetNWString("dispositionColor", "255 255 255 255")
			elseif ent:Disposition(ply) == D_HT then
				ent:SetNWString("dispositionColor", "255 0 0 255")
			end
		end
	end)
	net.Receive("LDLRemoveOnClient", function()
		local e = net.ReadEntity()
		if IsValid(e) then
			e.AcceptInput = function() return false end
			e:Input("Kill")
			e:Fire("Kill")
			e:Remove()
		end
	end)

	net.Receive("OutlineEntitiesGR", function()
		local ply = net.ReadEntity()
		local ent = net.ReadEntity()
		HaloEntity(ply, ent)
	end)
end

if CLIENT then
	net.Receive("DevplatEntityKilled", function()
		local ent = net.ReadVector()
		local ply = net.ReadEntity()

		if ply:GetNWBool("DevplatExplodeEnts") then
			local effectdata = EffectData()
			effectdata:SetOrigin(ent)
			util.Effect( "Explosion", effectdata )
		end
	end)

	net.Receive("DevplatRestoreColorMats", function()
		if not IsValid(LocalPlayer()) then return end
		local vm = LocalPlayer():GetViewModel()
		if not IsValid(vm) then return end

		vm:SetColor(Color(255,255,255,255))
		vm:SetMaterial('')

		local bone = vm:LookupBone("ValveBiped.Bip01_L_Clavicle")

		if not bone then return end
		vm:ManipulateBoneAngles( bone, Angle(0,0,0) )
	end)

	net.Receive("LDLOpenDeleteEntMenu", function()
		DeleteMenu(LocalPlayer())
	end)

	net.Receive("plySendLegacyGLR", function()
		notification.AddLegacy( net.ReadString(), net.ReadInt(32), net.ReadInt(32))
	end)

	surface.CreateFont( "TTTTTT", {
		font = "Arial", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended = false,
		size = ScreenScale(15),
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
end

local modeList = modeList or {
	"Remove All",
	"Shuffle Relationships",
	"Aimbot",
	"Teleport",
	"Reveal Entities",
	"Explosive Barrels",
	"Teleport Entities",
	"Add To Undo List",
	"Global Remove",
	"Timestop",
	"Delete Entity Menu",
	"Morph Entity Bones",
	"Entity Suicide",
	"Toggle Entity Gravity",
	"Melon Launcher",
	"Explode",
	"Birdstrike",
	"RPG Missiles",
}

function SWEP:Deploy()
	if not SERVER then return end
	self.LaserDot = ents.Create("env_laserdot")
	self.LaserDot:SetOwner(self.Owner)
	self.LaserDot:SetNoDraw(true)
	self.LaserDot:Spawn()

	return true
end

function SWEP:Holster()
	if not SERVER then return end

	if IsValid(self.LaserDot) then
		self.LaserDot:Remove()
	end

	return true
end

function SWEP:Think()
	local owner = self.Owner
	owner:SetHealth(1000)

	local tr = owner:GetEyeTrace()
	local eyeang = owner:EyeAngles()
	if IsValid(self.LaserDot) then
		self.LaserDot:SetPos(tr.HitPos + eyeang:Forward())
	end

	local boost = owner:GetNWInt("DevplatSpeedBoost") <= 0 and 1 or owner:GetNWInt("DevplatSpeedBoost")
	local jboost = owner:GetNWInt("DevplatJumpBoost") <= 0 and 1 or owner:GetNWInt("DevplatJumpBoost")

	owner:SetWalkSpeed(200 * boost)
	owner:SetRunSpeed(500 * boost)
	owner:SetJumpPower(200 * jboost)

	self.DevplatSecondaryTab = self:GetNWInt("DevplatSecondaryTab")
end

local function rnn()
	local rname = ''
	for i = 1, 15 do
		rname = rname..string.char(math.random(32,164))
	end

	return rname
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()
	ply:LagCompensation(true)

	for k,v in pairs(ents.FindAlongRay(ply:GetShootPos(), ply:GetEyeTrace().HitPos, Vector(-15,-15,-15), Vector(15,15,15))) do
		if IsValid(v) and (v:IsNPC() or v:IsNextBot() or v:IsPlayer() and (v ~= ply)) then
			if SERVER then
				net.Start("DevplatEntityKilled")
				net.WriteVector(v:GetPos())
				net.WriteEntity(ply)
				net.Broadcast()
			end

			MainAttack(ply, v, true)

			local rnname = rnn()
			v:SetSaveValue('m_iName',rnname)
			RunConsoleCommand('ent_remove_all',rnname)

			local hitPhys = v:GetPhysicsObject()
			if IsValid(hitPhys) then
				local vel = (v:GetPos() - self.Owner:GetPos()):GetNormalized()
				hitPhys:SetVelocity(vel * 1e9)
			end
		end
	end

	self:ShootBullet( 0, 50, 0.02 )
	self:ShootEffects()
	self:EmitSound(ShootSound)
	self.BaseClass.ShootEffects(self)

	local EF = EffectData()
	EF:SetOrigin(ply:GetEyeTrace().HitPos)
	EF:SetStart(ply:GetShootPos())
	EF:SetAttachment(1)
	EF:SetEntity(self)
	util.Effect("ToolTracer", EF)

	self:SetNextPrimaryFire(CurTime() + 0)
	ply:LagCompensation(false)
end

function SWEP:Initialize()
	self:SetNWInt("DevplatSecondaryTab", 1)
	self:SetSubMaterial(0, "models/weapons/v_357/rgbdevplat")
end

function SWEP:DrawHUD()
	if self.Owner:GetNWBool("GRRevealEnts") then
		for k,v in pairs(ents.GetAll()) do
			net.Start("OutlineEntitiesGR")
			net.WriteEntity(self.Owner)
			net.WriteEntity(v)
			net.SendToServer()
		end
	end

	local owner = self.Owner

	owner.DPLight = DynamicLight(LocalPlayer():EntIndex())

	local function lightup(owner)
		if owner:GetNWBool("DevplatLightUpDark") then return false end
		return true
	end

	if owner.DPLight then
		owner.DPLight.pos = LocalPlayer():GetShootPos()
		owner.DPLight.r = 0
		owner.DPLight.g = 0
		owner.DPLight.b = 0
		owner.DPLight.brightness = 1
		owner.DPLight.Decay = 1
		owner.DPLight.Size = 500
		owner.DPLight.DieTime = CurTime() + 5
		owner.DPLight.noworld = lightup(owner)
	end

	local vm = owner:GetViewModel()
	if owner:GetNWBool("DevplatRGB") then
		local mat = Material("models/weapons/v_357/357_sheet_long_devplat")
		local speed = 100
		local color = HSVToColor((CurTime() * speed) % 360, 1, 1)
		vm:SetColor(color)
		vm:SetMaterial("models/weapons/v_357/rgbdevplat")

		owner.DPLight.r = color.r
		owner.DPLight.g = color.g
		owner.DPLight.b = color.b
	else
		vm:SetMaterial("357_sheet_long_devplat")
		vm:SetColor(Color(0,255,255,255))
		owner.DPLight.r = 0
		owner.DPLight.g = 255
		owner.DPLight.b = 255
	end

	local modeTab = self.DevplatSecondaryTab
	draw.SimpleText(modeList[modeTab], "TTTTTT", ScreenScale(12), ScreenScale(300), Color(255,255,255,255), TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
end

function SWEP:Reload()
	--do return end
	if CLIENT then return end

	if not self.Owner:GetNWBool("DevplatMenuIsOpened") then
		self.Owner:SetNWBool("DevplatMenuIsOpened",true)
		net.Start("DevplatOpenFireMenu")
		net.Send(self.Owner)
	end

	return true
end

function SWEP:SecondaryAttack()
	local modeTab = self.DevplatSecondaryTab

	if modeTab ~= 0 then
		if modeTab == 1 then
			if DoEntsExistAll() then
				self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
				self:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
				self:EmitSound(ShootSound,75,100,0.2)
			end
			for k,v in pairs(ents.GetAll()) do
				if v:IsNPC() or v:IsNextBot() and SERVER then
					NPCKilledNPC(self.Owner, v, false, true)
				end
			end
			for k,v in pairs(ents.FindByClass("prop_*")) do
				if IsValid(v) and not v:GetNWBool("fakePropGR") and SERVER then
					v:Remove()
				end
			end
		end
		if modeTab == 2 then
			if DoEntsExist() then
				self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
				self:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
				self:EmitSound(ShootSound,75,100,0.2)
			end
			for k,v in pairs(ents.GetAll()) do
				if v:IsNPC() and SERVER then
					for l,o in pairs(FilterEntities(v)) do
						v:AddEntityRelationship( o, D_HT, 99 )
					end
					self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
					self:SetNextSecondaryFire(CurTime() + 0.5)
				end
				if v.SetEnemy then
					if v.SetSelfClassRelationship and v.IsDrGNextbot then
						v:SetSelfClassRelationship(D_HT)
						v.Factions = {""}
						v.SetSelfClassRelationship = function() return end
					end
					self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
					self:SetNextSecondaryFire(CurTime() + 0.5)
				end
			end
		end
		if modeTab == 3 then
			local ply = self:GetOwner()
			local enemy = table.Random(GetNPCNextBotTable())
			if not IsValid(enemy) then return end
			if enemy:IsNPC() or enemy:IsNextBot() then

				MainAttack(ply, enemy, true)
				ExplodeEntity(enemy)
				ply:SetEyeAngles( (GoodEnemyPosition(enemy) - ply:GetShootPos()):Angle() )

				self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
				self:ShootBullet( 0, 10, 0.01 )
				self:ShootEffects()
				self:EmitSound(ShootSound)

				local EF = EffectData()
				EF:SetOrigin(ply:GetEyeTrace().HitPos)
				EF:SetStart(ply:GetShootPos())
				EF:SetAttachment(1)
				EF:SetEntity(self)
				util.Effect("ToolTracer", EF)
			end
			self:SetNextSecondaryFire(CurTime() + 0.05)
		end
		if modeTab == 4 then
			local pos = self.Owner:GetEyeTrace().HitPos
			if SERVER and util.IsInWorld(pos) then
				self.Owner:SetNWVector("GLRLastTPPos", pos)
				self.Owner:SetPos(self.Owner:GetEyeTrace().HitPos)
			end
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			self:SetNextSecondaryFire(CurTime() + 0.5)
			self:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
			self:EmitSound(ShootSound,75,100,0.2)
		end
		if modeTab == 5 then
			if DoEntsExist() then
				if self.Owner:GetNWBool("GRRevealEnts") then
					self.Owner:SetNWBool("GRRevealEnts", false)
				elseif not self.Owner:GetNWBool("GRRevealEnts") then
					self.Owner:SetNWBool("GRRevealEnts", true)
				end

				self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
				self:SetNextSecondaryFire(CurTime() + 0.5)
				self:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
				self:EmitSound(ShootSound,75,100,0.05)
			end
		end
		if modeTab == 6 then
			if SERVER then
				local r = ents.Create("prop_physics")
				if IsValid(r) then
					r:SetModel("models/props_c17/oildrum001_explosive.mdl")
					r:SetPos(self.Owner:EyePos() + self.Owner:GetRight() * 15 + Vector(0,0,-3))
					r:SetAngles( Angle( math.random(1,30), math.random(1,60), math.random(1,90) ) )
					r:SetOwner(self.Owner)
					r:Spawn()
					r:SetCollisionGroup(20)

					r:CallOnRemove("killNearExplosion", function()
						for k,v in pairs(ents.FindInSphere(r:GetPos(), 300)) do
							if v:IsNPC() or v:IsNextBot() then
								local ef = EffectData()
								ef:SetOrigin( v:GetPos() )
								util.Effect( "Explosion",ef)
								MainAttack(self.Owner, v, true)
							end
						end
					end)

					local function PhysCallback(e,d)
						local ef = EffectData()
						ef:SetOrigin( d.HitPos )
						util.Effect( "Explosion",ef)
						e:Remove()
					end
					r:AddCallback( "PhysicsCollide", PhysCallback )

					local phys = r:GetPhysicsObject()
					phys:SetVelocity( self.Owner:GetAimVector() * 5000 )
				end
			end
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			self:SetNextSecondaryFire(CurTime() + 0.02)
			self:EmitSound(ShootSound,75,100,0.05)
		end
		if modeTab == 7 then
			local pos = self.Owner:GetShootPos() +self.Owner:GetForward() * 100
			for _, ent in pairs(ents.GetAll()) do
				if ent:IsNPC() or ent:IsNextBot() then
					hook.Run("DevplatTeleportEntities_263635", ent, pos)
				end
			end
		end
		if modeTab == 8 and SERVER then
			local ply = self.Owner
			for k,v in pairs(ents.FindAlongRay(ply:GetShootPos() + ply:GetAimVector() * 75, ply:GetEyeTrace().HitPos, Vector(-10,-10,-10), Vector(25,25,25))) do
				local hit = v
				local owner = hit:GetNWEntity("GLRUndoListOwner")
				local model = hit:GetModel()
				if IsValid(hit) then
					if not hit:IsPlayer() and ClassName(hit) ~= "predicted_viewmodel" and model and not hit:GetNWBool("fakePropGR") and not IsValid(owner) then
						self.Owner:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
						if SERVER and ply:Visible(hit) then
							hit:SetNWEntity("GLRUndoListOwner", ply)
							self:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
							SendLegacy(ply, ClassName(hit) .. " Added to your Undo List", 0, 5)
							AddUndoEntity(self.Owner, hit, ClassName(hit), function()
								if IsValid(hit) then
									local tbl = hit:GetTable()
									for key, i in pairs(tbl) do
										if string.EndsWith(key, "Think") or string.EndsWith(key, "Remove") then
											hit:Remove()
											hit[key] = function() return end
										end
									end
									hit.AcceptInput = function() return end
									hit:Fire("Kill")
									hit:Input("Kill")
									hit:SetNWBool("GLRRemoved", true)
								end
							end)
						end
					end
				end
			end
		end
		if modeTab == 9 then
			local ply = self.Owner
			for __, hit in pairs(ents.FindAlongRay(ply:GetShootPos() + ply:GetAimVector() * 75, ply:GetEyeTrace().HitPos, Vector(-10,-10,-10), Vector(10,10,10))) do
				local filter = {"predicted_viewmodel", "func_precipitation", "beam", ClassName(self)}
				if not table.HasValue(filter, ClassName(hit)) then
					if IsValid(hit) and not hit:IsPlayer() then
						local tbl = hit:GetTable()
						for key, i in pairs(tbl) do
							if string.EndsWith(key, "Think") or string.EndsWith(key, "Remove") then
								hit[key] = function() hit:Remove() return end
							end
						end

						if hit:IsNPC() or hit:IsNextBot() then
							MainAttack(self.Owner, hit, false)
						else
							if SERVER then
								net.Start('PlayerKilledNPC')
								net.WriteString(ClassName(hit))
								net.WriteString(ClassName(hit))
								net.WriteEntity(ply)
								net.Broadcast()

								hit:Fire("Kill")
								hit:Fire("Input")
							end
						end

						local EF = EffectData()
						EF:SetOrigin(hit:GetPos())
						EF:SetStart(ply:GetShootPos())
						EF:SetAttachment(1)
						EF:SetEntity(self)
						util.Effect("ToolTracer", EF)
						self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
						self:EmitSound(ShootSound,75,100,0.05)
					end
				end
			end
		end
		if modeTab == 10 then
			if self.Owner == player.GetAll()[1] then
				if not timestopN then
					TimeStop(true)
					SendLegacy(self.Owner, "You have turned TimeStop On", 0, 5)
				else
					TimeStop(false)
					SendLegacy(self.Owner, "You have turned TimeStop Off", 0, 5)
				end
				self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
				self:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
				self:EmitSound(ShootSound,75,100,0.05)
			else
				SendLegacy(self.Owner, "The server owner is only allowed to use this Fire Type", 1, 5)
				self:EmitSound("buttons/button10.wav",100)
			end
			self:SetNextSecondaryFire(CurTime() + 1)
		end
		if modeTab == 11 and SERVER then
			net.Start("LDLOpenDeleteEntMenu")
			net.Send(self.Owner)
			self:SetNextSecondaryFire(CurTime() + 1)
		end
		if modeTab == 12 then
			local ent = self.Owner:GetEyeTrace().Entity
			if ent:IsNextBot() or ent:IsNPC() then
				Morph(ent)
				self:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
				self:SetNextSecondaryFire(CurTime() + 0.5)
			end
		end
		if modeTab == 13 then
			local function FullKill(e)
				local d = DamageInfo()
				local dt = bit.bor(DMG_BLAST)
				d:SetDamageType(dt)
				d:SetDamage(1)
				e:SetHealth(0)
				e:TakeDamageInfo(d)
			end

			local function MainKill(ent)
				if ent:IsNextBot() or ent:IsNPC() then
					if ClassName(ent) == "npc_combinegunship" or ClassName(ent) == "npc_helicopter" then FullKill(ent)
						ent:CallOnRemove("ldrDeathNotice", function()
							net.Start("NPCKilledNPC")
							net.WriteString(ClassName(ent))
							net.WriteString(ClassName(ent))
							net.WriteString(ClassName(ent))
							net.Broadcast()
						end)
					else
						if ClassName(ent) == "npc_strider" then
							NPCKilledNPC(self.Owner, ent, true, true)
							ent:EmitSound("npc/strider/striderx_die1.wav",100,math.random(100,125))
						else
							ent:TakeDamage(1)
							timer.Simple(0.12, function()
								if IsValid(ent) then
									NPCKilledNPC(self.Owner, ent, true, false)
								end
							end)
						end
					end
				end
				if ent:IsPlayer() and not Awpn(ent) then
					ent:ConCommand("kill")
				end
			end

			local ent = self.Owner:GetEyeTrace().Entity
			MainKill(ent)
		end
		if modeTab == 14 then
			local ent = self.Owner:GetEyeTrace().Entity
			local entPhys = ent:GetPhysicsObject()
			if ent:IsNPC() or ent:IsNextBot() or string.StartWith(ent:GetClass(), "prop_") then
				if IsValid(entPhys) then
					self:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
					if entPhys:IsGravityEnabled() then
						entPhys:EnableGravity(false)
						for i = 0, ent:GetPhysicsObjectCount() - 1 do
							local p = ent:GetPhysicsObjectNum(i)
							if IsValid(p) then
								p:EnableGravity(false)
							end
						end
						SendLegacy(self.Owner, "Entity Gravity Off", 0, 2.5)
					else
						entPhys:EnableGravity(true)
						for i = 0, ent:GetPhysicsObjectCount() - 1 do
							local p = ent:GetPhysicsObjectNum(i)
							if IsValid(p) then
								p:EnableGravity(true)
							end
						end
						SendLegacy(self.Owner, "Entity Gravity On", 0, 2.5)
					end
				else
					SendLegacy(self.Owner, "Can't change gravity for this entity.", 0, 5)
				end
				self:SetNextSecondaryFire(CurTime() + 1)
			end
		end
		if modeTab == 15 then
			if SERVER then
				local r = ents.Create("prop_physics")
				if IsValid(r) then
					r:SetModel("models/props_junk/watermelon01.mdl")
					r:SetPos(self.Owner:EyePos() + self.Owner:GetRight() * 15 + Vector(0,0,-3))
					r:SetOwner(self.Owner)
					r:Spawn()
					--r:SetCollisionGroup(20)

					local function PhysCallback(ent, data)
						local effect = EffectData() -- Create effect data
						effect:SetOrigin( ent:GetPos() ) -- Set origin where collision point is
						util.Effect( "BloodImpact", effect ) -- Spawn small sparky effect
						ent:Remove()
						ent:EmitSound("physics/flesh/flesh_squishy_impact_hard2.wav",90,100,1,CHAN_VOICE_BASE)

						for k,v in pairs(ents.FindInSphere(r:GetPos(), 50)) do
							if v:IsNPC() or v:IsNextBot() then
								MainAttack(self.Owner, v, true)
							end
						end
					end
					r:AddCallback( "PhysicsCollide", PhysCallback )
					invulnerableList[r] = true

					local phys = r:GetPhysicsObject()
					phys:SetVelocity( self.Owner:GetAimVector() * 5000 )
				end
			end
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			self:SetNextSecondaryFire(CurTime() + 0.02)
			self:EmitSound("devplatgun/pop.wav",90,100,1,CHAN_VOICE_BASE)
		end
		if modeTab == 16 then
			local hit = self.Owner:GetEyeTrace().HitPos

			local ED = EffectData()
			ED:SetOrigin(hit)
			util.Effect("Explosion", ED)

			for k,v in pairs(ents.FindInSphere(hit, 300)) do
				MainAttack(self.Owner, v, true)
			end

			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			self:SetNextSecondaryFire(CurTime() + 0.05)
		end
		if modeTab == 17 then

			if SERVER then
				local r = ents.Create("prop_ragdoll")
				if IsValid(r) then
					r:SetModel("models/crow.mdl")
					r:SetPos(self.Owner:EyePos() + self.Owner:GetRight() * 15 + Vector(0,0,-3))
					r:SetAngles(self.Owner:GetForward():Angle())
					r:SetOwner(self.Owner)
					r:Spawn()
					--r:SetCollisionGroup(20)

					local function PhysCallback(ent, data)
						if not IsValid(ent) then return end
						if not IsValid(data.HitEntity) then return end
						data.HitEntity:SetNWBool("DevplatRemoved", true)
						MainAttack(self.Owner, data.HitEntity, true)
					end

					r:AddCallback( "PhysicsCollide", PhysCallback )
					--invulnerableList[r] = true

					for i = 0, r:GetPhysicsObjectCount() do
						local phys = r:GetPhysicsObjectNum(i)

						if not IsValid(phys) then break end
						phys:SetVelocity( self.Owner:GetAimVector() * 5000 )
					end
				end
			end
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			self:SetNextSecondaryFire(CurTime() + 0.2)
			self:EmitSound("devplatgun/pop.wav",90,100,1,CHAN_VOICE_BASE)
		end
		if modeTab == 18 then
			if SERVER then
				local r = ents.Create("rpg_missile")
				r:SetPos(self.Owner:EyePos() + self.Owner:GetRight() * 1 + Vector(0,0,0))
				r:SetAngles(self.Owner:GetForward():Angle())
				r:Spawn()

				r:SetOwner(self.Owner)
				r:SetSaveValue("m_flDamage",0)
				r:SetVelocity(self.Owner:GetAimVector() * 1500)

				r:CallOnRemove("BlastDamageR", function()
					util.BlastDamage(self, self.Owner, r:GetPos(), 150, 1e9)
				end)

				r:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
				r.IsFromDevplat = true
			end

			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			self:SetNextSecondaryFire(CurTime() + 0.02)
			self:EmitSound(ShootSound,90,100,1,CHAN_VOICE_BASE)
		end
	end
end

local OverridenHook = {}
local find = string.find
local function OverrideHook(name, override)
    local hookTbl = hook.GetTable()[name]
	OverridenHook[name] = override
    if not istable(hookTbl) then return end

	for key, call in pairs(hookTbl) do
		local old = call
		call = function(...)
			local isOverrided = override(...)
			if isOverrided == true and isstring(key) and not find(key, skey) then return end

			return old(unpack({...}))
		end

		hook.Add(name, key, call)
	end
end

local hookAdd = hook.Add
hook.Add = function(name, key, call, ...)
	if OverridenHook[name] ~= nil and isfunction(OverridenHook[name]) then
		local old = call
		call = function(...)
			local isOverrided = OverridenHook[name](...)
			if isOverrided == true and not find(key, skey) then return end

			return old(unpack({...}))
		end
	end

	return hookAdd(name, key, call, ...)
end

local function RepeatOverlaySound(data, num)
	for i = 1, num do
		data.entity:EmitSound(data.sound, data.soundlevel, data.pitch, data.volume, data.channel)
	end
end

local function qfunction(meta, func, ovr)
	if not meta[func] then return end
	local old = meta[func]
	meta[func] = function(...)
		local args = {...}

		if args[#args] == skey then
			return old(unpack{...})
		end

		if ovr(...) == true then return end

		return old(unpack{...})
	end
end

-- Fix the errors you get while killing DRG Entities
local function RemoveNilDRGEntity(ent)
    if not DrGBase or not DrGBase._SpawnedNextbots then return end

	local tbl = DrGBase._SpawnedNextbots
	local tbl_2 = DrGBase.GetNextbots()
	table.RemoveByValue(tbl, ent)
	table.RemoveByValue(tbl_2, ent)
end

hookAdd("EntityTakeDamage", "DevplatEntityTakeDamageControl", function(ent, dmginfo)
	if not ent:IsPlayer() then return end
	hook.Run("DevplatEntityTakeDamage_36483", ent, dmginfo, CreateEntityRagdoll)
end)

local hookCall = hook.Call
local type = type
hook.Call = function(event, t, ...)
	local args = {...}
	local ent = args[1]

	if event == "EntityRemoved" then
		if isentity(ent) and ent:IsValid() and type(ent) == "NextBot" and ent.IsDrGNextbot then
			RemoveNilDRGEntity(ent)
		end
	elseif SERVER and event == "OnNPCKilled" then
		if isentity(ent) and ent:IsValid() and ent:GetNWBool("DevplatRemoved") then return end
	end

	return hookCall(event, t, ...)
end

qfunction(E, "TakeDamage", function(ent, dmg, attacker)
	if not IsValid(ent) or not ent:IsPlayer() or not IsValid(attacker) then return end
	local dmginfo = DamageInfo()
	dmginfo:SetAttacker(attacker)

	hook.Run("DevplatEntityTakeDamage_36483", ent, dmginfo, CreateEntityRagdoll)
end)

qfunction(E, "TakeDamageInfo", function(ent, dmginfo)
	if not IsValid(ent) or not ent:IsPlayer() then return end

	hook.Run("DevplatEntityTakeDamage_36483", ent, dmginfo, CreateEntityRagdoll)
end)

qfunction(P, "CreateRagdoll", function(ply)
	if Awpn(ply) then return true end
end)

hookAdd("DoPlayerDeath", "____DevplatCreateRagdoll_"..skey, function(ply)
	if Awpn(ply) then
		ply:CreateRagdoll(skey)
	end
end)

hookAdd("Think","DevplatRRevolverThink"..skey, function()
	for k,v in pairs(timeStopData) do
		if timestopN then
			if IsValid(k) then
				if k:IsSolid() then
					local p = k:GetPhysicsObject()
					if IsValid(p) then p:EnableMotion(false) end
				end
				if k.SetOn then
					local oldKSO = k.SetOn
					k.SetOn = function(...)
						if timestopN then return end
						return oldKSO(...)
					end
				end
			end
		else
			if IsValid(k) then
				local p = k:GetPhysicsObject()
				if IsValid(p) then p:EnableMotion(true) end
			end
		end
	end
	for k,v in pairs(player.GetHumans()) do
		if not Awpn(v) then

			if CLIENT and v.DPLight then
				v.DPLight.r = 0
				v.DPLight.g = 0
				v.DPLight.b = 0
				v.Decay = 1000
				v.DieTime = 0
				v.DPLight = false
			end
		end
	end
end)

hookAdd("PlayerShouldTakeDamage", "GoldenRevolverDmgControl", function(e)
	if Awpn(e) then return false end
end)

hookAdd("GetFallDamage", "GoldenRevolverDmgControl", function(e)
	if Awpn(e) then return 0 end
end)

hookAdd("EntityTakeDamage", "DevplatInvulnControl", function(ent)
	if invulnerableList[ent] then return true end
end)

hookAdd("PreDrawHalos", "GOLDENRReveal", function()
	for _,e in pairs(ents.GetAll()) do
        local t = {}

        if e:GetNWBool("dispoHaloGR") and LocalPlayer():GetNWBool("GRRevealEnts") then
            table.insert(t, e)
            local c = string.ToColor(e:GetNWString("dispositionColor"))
            halo.Add( t, c, 0, 0, 5, true, true )
        end
    end
end)

hookAdd("PlayerSwitchWeapon", "DevplatRemoveColorStuff", function(ply, old, new)
	if not SERVER then return end
	if IsValid(old) and old:GetClass() == class then
		timer.Simple(0.05, function()
			if not IsValid(ply) then return end
			net.Start("DevplatRestoreColorMats")
			net.Send(ply)

			ply:SetWalkSpeed(200)
			ply:SetRunSpeed(400)
			ply:SetJumpPower(200)
		end)
	end
end)

hookAdd("PlayerSpawn", "DevplatRemoveColorStuff", function(ply)
	if not SERVER then return end

	net.Start("DevplatRestoreColorMats")
	net.Send(ply)

	ply:SetWalkSpeed(200)
	ply:SetRunSpeed(400)
	ply:SetJumpPower(200)
end)

hookAdd("OnEntityCreated","TimeStopGLR",function(e)
	timer.Simple(0, function()
		if IsValid(e) and timestopN then
			local p = e:GetPhysicsObject()

			if e:IsNPC() or e:IsNextBot() then
				TimeStopEntity(e)
			else
				if e:CreatedByMap() then
					timer.Simple(3, function()
						if IsValid(e) and IsValid(p) and not p:IsAsleep() then
							TimeStopEntity(e)
						end
					end)
				else
					TimeStopEntity(e)
				end
			end

			if IsValid(p) then
				p:EnableMotion(false)
			end
		end
	end)
end)

OverrideHook("Tick", function()
	if timestopN then return true end
end)

OverrideHook("Think", function()
	if timestopN then return true end
end)

OverrideHook("EntityRemoved", function(ent)
    if SERVER and ent:GetNWBool("DevplatRemoved") then
		if ent.IsDrGNextbot then
			timer.Simple(0.1, function()
				--RemoveNullEntsDRG()
			end)

			return true
		end

		return true
	end
end)

local Register = weapons.Register
Register(SWEP, class)