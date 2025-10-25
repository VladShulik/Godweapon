local e = FindMetaTable( "Entity" )
local Remove = e.Remove
local game_CleanUpMap = game.CleanUpMap
local ents_GetAll = ents.GetAll
local DevplatMenu = {}

local function CreateFont(name, font, size, weight)
    if not CLIENT then return end

    surface.CreateFont(name, {font = font, size = size, weight = weight})
end

if SERVER then
    util.AddNetworkString("DevplatChangeFireMode")
    util.AddNetworkString("DevplatOpenFireMenu")
    util.AddNetworkString("DevplatSetNWBool353727")
    util.AddNetworkString("DevplatSetNWInt362783")
    util.AddNetworkString("DevplatSuperClean3627")

    net.Receive("DevplatChangeFireMode", function()
        local int = net.ReadInt(32)
        local wpn = net.ReadEntity()

        wpn:SetNWInt("DevplatSecondaryTab",int)
    end)

    net.Receive("DevplatSetNWBool353727", function()
        local ent = net.ReadEntity()
        local bool = net.ReadString()
        local r = net.ReadBool()

        ent:SetNWBool(bool, r)
    end)

    net.Receive("DevplatSetNWInt362783", function()
        local ent = net.ReadEntity()
        local int = net.ReadString()
        local r = net.ReadInt(32)

        ent:SetNWInt(int, r)
    end)

    net.Receive("DevplatSuperClean3627", function()
        for k,v in pairs(ents_GetAll()) do
            if v:IsNPC() or v:IsNextBot() then
                Remove(v)
            end
        end

        game_CleanUpMap()
    end)
end

local function SetNWBoolServer(ent, i, value)
    net.Start("DevplatSetNWBool353727")
    net.WriteEntity(ent)
    net.WriteString(i)
    net.WriteBool(value)
    net.SendToServer()
end

local function SetNWIntServer(ent, i, value)
    net.Start("DevplatSetNWInt362783")
    net.WriteEntity(ent)
    net.WriteString(i)
    net.WriteInt(value, 32)
    net.SendToServer()
end

timer.Simple(0.5, function()
if CLIENT then
    CreateFont("DevPMenuFont", "Roboto", ScreenScale(5), ScreenScale(5))
    CreateFont("DevPMenuInfoFont", "Roboto", ScreenScale(4), ScreenScale(5))
    CreateFont("DevPMenuInfoFontM", "Roboto", ScreenScale(8), ScreenScale(5))

    if !file.Exists("devplatcolors", "DATA") then
        file.CreateDir("devplatcolors")
    end

    function DevplatMenu:Open(self)
        if !IsValid(self) or !self:IsPlayer() then return end

        --local plyNick = "(" .. self:Nick() .. ")"
        --print("DevplatMenu Opened " .. plyNick)

        local fW, fH, aT, aD, aE = 1000, 500, 1, 0, 0.1
        local oColor = Color(45, 50, 65)
        local bColor = Color(35, 40, 55)
        local cColor = Color(30, 34, 50)
        local ButtonList = {}
        local ButtonLabels = {}

        local SettingsList = {}

        local OtherButtons = {}
        local OtherButtonsLabels = {}

        local isSizing = true

        if IsValid(DevplatMenu.Menu) then DevplatMenu.Menu:Remove() return end
        DevplatMenu.Menu = vgui.Create("DFrame")

        if file.Exists("devplatcolors", "DATA") then
            local colorTab = file.Read("devplatcolors/colorfor" .. LocalPlayer():AccountID() .. ".txt", "DATA")
            if colorTab then
                colorTab = util.JSONToTable(colorTab)

                oColor = Color(colorTab.r, colorTab.g, colorTab.b, colorTab.a) or oColor
                bColor = Color(colorTab.r-10, colorTab.g-10, colorTab.b-10, colorTab.a) or bColor
                cColor = Color(colorTab.r-15, colorTab.g-8, colorTab.b-8, colorTab.a) or cColor

                if bColor.r <= 0 then bColor.r = 0 end
                if bColor.g <= 0 then bColor.g = 0 end
                if bColor.b <= 0 then bColor.b = 0 end
    
                if cColor.r <= 0 then cColor.r = 0 end
                if cColor.g <= 0 then cColor.g = 0 end
                if cColor.b <= 0 then cColor.b = 0 end
            end
        end

        local DMenu = DevplatMenu.Menu
        DMenu:MakePopup(true)
        DMenu:SetTitle('')
        DMenu:SetSize(0,0)
        DMenu:Center()
        DMenu:SizeTo(fW, fH, aT, aD, aE, function() isSizing = false end)
        DMenu:ShowCloseButton(false)

        DMenu.Paint = function(panel, w, h)
            surface.SetDrawColor(oColor)
            surface.DrawRect(0,0,w,h)
        end

        DMenu.OnSizeChanged = function(panel)
            if isSizing then panel:Center() end
        end

        local CButton = DMenu:Add("DButton")
        CButton:Dock(BOTTOM)
        CButton:SetText('')

        CButton.DoClick = function() DMenu:Remove() end
        CButton.Paint = function(panel, w, h)
            surface.SetDrawColor(bColor)
            surface.DrawRect(0,0,w,h)
            draw.SimpleText("Close", "DevPMenuFont", w*.5, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        OtherButtonsLabels[CButton] = "Close"

        DMenu.Scroll = DMenu:Add('DScrollPanel')
        DMenu.Scroll:Dock(FILL)

        local Scroll = DMenu.Scroll
        local function AddButton(data)
            local fb = Scroll:Add("DButton")
            fb:Dock(TOP)
            fb:DockMargin(0,0,0,5)
            fb:SetSize(ScreenScale(15), ScreenScale(8))
            fb:SetText('')

            fb.Paint = function(panel, w, h)
                surface.SetDrawColor(cColor)
                surface.DrawRect(0,0,w,h)
                draw.SimpleText(data.Label, "DevPMenuFont", w*.5, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            fb.DoClick = function()
                data.Callback(LocalPlayer())

                if data.CloseOnClick then
                    DMenu:Remove()
                end
            end

            table.insert(ButtonList, fb)
            ButtonLabels[fb] = data.Label
        end

        local wpn = LocalPlayer():GetActiveWeapon()
        local function AddCheckBox(data)
            local lp = LocalPlayer()

            local cBL = DMenu:Add("DCheckBoxLabel")
            cBL:SetVisible(false)
            cBL:SetText(data.Label)
            cBL:SetPos(data.x, data.z)
            cBL.OnChange = function(self, val)
                if data.Callback and isfunction(data.Callback) then
                    data.Callback(lp, val)
                end
                if data.Identifier then
                    lp:SetNWBool(data.Identifier, val)
                    SetNWBoolServer(lp, data.Identifier, val)
                end
            end

            if data.Identifier then
                if lp:GetNWBool(data.Identifier) then
                    cBL:SetChecked(lp:GetNWBool(data.Identifier))
                end
            end

            table.insert(SettingsList, cBL)
        end

        DMenu.OnClose = function()
            SetNWBoolServer(self, "DevplatMenuIsOpened", false)
        end

        DMenu.OnRemove = function()
            SetNWBoolServer(self, "DevplatMenuIsOpened", false)
        end

        local Mixer = DMenu:Add("DColorMixer")
        Mixer:SetSize(fW / 5, fH / 2.5)
        Mixer:SetPos(7,240)
        Mixer:SetPalette(true)
        Mixer:SetAlphaBar(true)
        Mixer:SetWangs(false)
        Mixer:SetColor(Color(45, 50, 65, 255))
        Mixer:SetVisible(false)
        Mixer:SetWangs(true)

        if file.Exists("devplatcolors", "DATA") then
            local colorTab = file.Read("devplatcolors/colorfor" .. LocalPlayer():AccountID() .. ".txt", "DATA")
            if colorTab then
                colorTab = util.JSONToTable(colorTab)
                Mixer:SetColor(Color(colorTab.r, colorTab.g, colorTab.b, colorTab.a))
            end
        end

        Mixer.ValueChanged = function(self, color)
            if Color(color.r, color.g, color.b, color.a) == Color(45, 50, 65, 255) then
                oColor = Color(45, 50, 65)
                bColor = Color(35, 40, 55)
                cColor = Color(30, 34, 50)

                return
            end

            local ply = LocalPlayer()
            local t = {
                r = color.r,
                g = color.g,
                b = color.b,
                a = color.a
            }

            local tab = util.TableToJSON( t, true )
            file.Write( "devplatcolors/colorfor" .. ply:AccountID() .. ".txt", tab)

            oColor = Color(color.r, color.g, color.b, color.a) or oColor
            bColor = Color(color.r-10, color.g-10, color.b-10, color.a) or bColor
            cColor = Color(color.r-15, color.g-8, color.b-10, color.a) or cColor

            if bColor.r <= 0 then bColor.r = 0 end
            if bColor.g <= 0 then bColor.g = 0 end
            if bColor.b <= 0 then bColor.b = 0 end

            if cColor.r <= 0 then cColor.r = 0 end
            if cColor.g <= 0 then cColor.g = 0 end
            if cColor.b <= 0 then cColor.b = 0 end

            for k,v in pairs(ButtonList) do
                local old = v.Paint
                v.Paint = function(panel, w, h)
                    surface.SetDrawColor(cColor)
                    surface.DrawRect(0,0,w,h)
                    draw.SimpleText(ButtonLabels[v], "DevPMenuFont", w*.5, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            for k,v in pairs(OtherButtons) do
                v.Paint = function(panel, w, h)
                    surface.SetDrawColor(cColor)
                    surface.DrawRect(0,0,w,h)
                    draw.SimpleText(OtherButtonsLabels[v], "DevPMenuFont", w*.5, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            local oldD = DMenu.Paint
            DMenu.Paint = function(panel, w, h)
                surface.SetDrawColor(oColor)
                surface.DrawRect(0,0,w,h)
            end
        end

        local ResetB = DMenu:Add("DButton")
        ResetB:SetVisible(false)
        ResetB:SetSize(192,20)
        ResetB:SetPos(7,446)
        ResetB:SetText('')
        ResetB.DoClick = function()
            local oldoColor = Color(45, 50, 65)
            local oldbColor = Color(35, 40, 55)
            local oldcColor = Color(30, 34, 50)

            for k,v in pairs(ButtonList) do
                v.Paint = function(panel, w, h)
                    surface.SetDrawColor(oldcColor)
                    surface.DrawRect(0,0,w,h)
                    draw.SimpleText(ButtonLabels[v], "DevPMenuFont", w*.5, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            for k,v in pairs(OtherButtons) do
                v.Paint = function(panel, w, h)
                    surface.SetDrawColor(oldbColor)
                    surface.DrawRect(0,0,w,h)
                    draw.SimpleText(OtherButtonsLabels[v], "DevPMenuFont", w*.5, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            DMenu.Paint = function(panel, w, h)
                surface.SetDrawColor(oldoColor)
                surface.DrawRect(0,0,w,h)
            end
            Mixer:SetColor(Color(45, 50, 65, 255))
            file.Delete( "devplatcolors/colorfor" .. LocalPlayer():AccountID() .. ".txt", tab)
        end

        ResetB.Paint = function(panel, w, h)
            surface.SetDrawColor(cColor)
            surface.DrawRect(0,0,w,h)
            draw.SimpleText("Reset Colors", "DevPMenuFont", w*.5, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local DEntry = DMenu:Add("DNumberWang")
        DEntry:SetSize(120,20)
        DEntry:SetPos(9,140)
        DEntry:SetVisible(false)
        DEntry:SetMin(1)
        DEntry:SetMax(100)
        DEntry:SetValue(LocalPlayer():GetNWInt("DevplatSpeedBoost") or 1)

        DEntry.OnValueChanged = function(self, val)
            SetNWIntServer(LocalPlayer(), "DevplatSpeedBoost", val)
        end

        local TextLabel1 = DMenu:Add("DLabel")
        TextLabel1:SetText('(Speed boost when holding)')
        TextLabel1:SetFont("DevPMenuInfoFont")
        TextLabel1:SetSize(200,22)
        TextLabel1:SetPos(9,160)
        TextLabel1:SetVisible(false)

        local DEntry2 = DMenu:Add("DNumberWang")
        DEntry2:SetSize(120,20)
        DEntry2:SetPos(9,188)
        DEntry2:SetVisible(false)
        DEntry2:SetMin(1)
        DEntry2:SetMax(100)
        DEntry2:SetValue(LocalPlayer():GetNWInt("DevplatJumpBoost") or 1)

        DEntry2.OnValueChanged = function(self, val)
            SetNWIntServer(LocalPlayer(), "DevplatJumpBoost", val)
        end

        local TextLabel2 = DMenu:Add("DLabel")
        TextLabel2:SetText('(Jump boost when holding)')
        TextLabel2:SetFont("DevPMenuInfoFont")
        TextLabel2:SetSize(200,22)
        TextLabel2:SetPos(9,208)
        TextLabel2:SetVisible(false)

        table.insert(SettingsList, Mixer)
        table.insert(SettingsList, ResetB)
        table.insert(SettingsList, DEntry)
        table.insert(SettingsList, DEntry2)
        table.insert(SettingsList, TextLabel1)
        table.insert(SettingsList, TextLabel2)
        table.insert(ButtonList, ResetB)
        ButtonLabels[ResetB] = "Reset Colors"

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

        for i = 1, #modeList do
            local ply = LocalPlayer()
            AddButton({
                Label = modeList[i],
                CloseOnClick = true,
                Callback = function(ply)
                    local wpn = ply:GetActiveWeapon()
                    net.Start("DevplatChangeFireMode")
                    net.WriteInt(i, 32)
                    net.WriteEntity(wpn)
                    net.SendToServer()
                end,
            })
        end

        AddCheckBox({
            Label = "Explode Killed Entities?",
            x = ScreenScale(2),
            z = ScreenScale(8),
            Identifier = "DevplatExplodeEnts",
        })

        AddCheckBox({
            Label = "RGB Devplat?",
            x = ScreenScale(2),
            z = ScreenScale(13),
            Identifier = "DevplatRGB",
        })

        AddCheckBox({
            Label = "Light up Dark Areas?",
            x = ScreenScale(2),
            z = ScreenScale(18),
            Identifier = "DevplatLightUpDark",
        })

        AddCheckBox({
            Label = "Entities Take Karma?",
            x = ScreenScale(2),
            z = ScreenScale(23),
            Identifier = "DevplatAttackerKarma",
        })

        AddCheckBox({
            Label = "Enable Devplat Entity Info?",
            x = ScreenScale(2),
            z = ScreenScale(28),
            Identifier = "DevplatEntityInfo",
        })

        local Clean = DMenu:Add("DButton")
        Clean:SetText('')
        Clean:SetSize(ScreenScale(35),ScreenScale(5))
        Clean:SetPos(850,446)
        Clean.Paint = function(panel, w, h)
            surface.SetDrawColor(bColor)
            surface.DrawRect(0,0,w,h)
            draw.SimpleText("Super Clean-Up", "DevPMenuFont", w*.55, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        Clean.DoClick = function()
            if LocalPlayer() == player.GetAll()[1] then
                net.Start("DevplatSuperClean3627")
                net.SendToServer()

                timer.Simple(0, function()
                    LocalPlayer():EmitSound("buttons/lightswitch2.wav", 75)
                    notification.AddLegacy("Super Cleaned everything!", 4, 3)
                end)
            else
                notification.AddLegacy("Only the server host can use this", 1, 3)
            end
        end
        table.insert(SettingsList, Clean)

        local Clean2 = DMenu:Add("DImage")
        Clean2:SetSize(ScreenScale(5),ScreenScale(5))
        Clean2:SetPos(850,446)
        Clean2:SetImage("vgui/notices/cleanup")
        table.insert(SettingsList, Clean2)

        Clean:SetVisible(false)
        Clean2:SetVisible(false)

        local Tab1 = DMenu:Add("DButton")
        Tab1:SetText('')
        Tab1:SetSize(ScreenScale(41),ScreenScale(5))
        Tab1:SetPos(ScreenScale(1),ScreenScale(1))
        Tab1.Paint = function(panel, w, h)
            surface.SetDrawColor(bColor)
            surface.DrawRect(0,0,w,h)
            draw.SimpleText("Secondary Fire-Types", "DevPMenuFont", w*.5, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        Tab1.DoClick = function()
            for k,v in pairs(ButtonList) do
                v:SetVisible(true)
            end
            DMenu.Scroll:SetVisible(true)
            for k,v in pairs(SettingsList) do
                v:SetVisible(false)
            end
        end

        local Tab2 = DMenu:Add("DButton")
        Tab2:SetText('')
        Tab2:SetSize(ScreenScale(20),ScreenScale(5))
        Tab2:SetPos(ScreenScale(42),ScreenScale(1))
        Tab2.Paint = function(panel, w, h)
            surface.SetDrawColor(cColor)
            surface.DrawRect(0,0,w,h)
            draw.SimpleText("Settings", "DevPMenuFont", w*.5, h*.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        Tab2.DoClick = function()
            for k,v in pairs(ButtonList) do
                v:SetVisible(false)
            end
            for k,v in pairs(SettingsList) do
                v:SetVisible(true)
            end
            DMenu.Scroll:SetVisible(false)
        end

        table.insert(OtherButtons, Tab1)
        table.insert(OtherButtons, Tab2)
        table.insert(OtherButtons, CButton)

        OtherButtonsLabels[Tab1] = "Secondary Fire-Types"
        OtherButtonsLabels[Tab2] = "Settings"
    end

    net.Receive("DevplatOpenFireMenu", function()
        DevplatMenu:Open(LocalPlayer())
    end)
end
end)