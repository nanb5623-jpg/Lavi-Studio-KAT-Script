if getgenv().LAVI_STUDIO_LOADED then return end
getgenv().LAVI_STUDIO_LOADED = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui
pcall(function() CoreGui = cloneref(game:GetService("CoreGui")) end)
if not CoreGui then CoreGui = game:GetService("CoreGui") end

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local V2 = Vector2.new
local V3 = Vector3.new
local CF = CFrame.new
local C3 = Color3.fromRGB
local C3HSV = Color3.fromHSV
local FLOOR = math.floor
local HUGE = math.huge
local CLAMP = math.clamp
local ABS = math.abs

local BRAND = C3(0, 255, 0)
local WHITE = C3(255, 255, 255)
local RED = C3(255, 50, 50)
local YELLOW = C3(255, 255, 0)
local GREEN = C3(0, 255, 0)
local GREY = C3(180, 180, 180)
local DARK = C3(20, 20, 20)

local Config = {
    ESP = {
        Enabled = false, Box = true, BoxOutline = true, BoxFilled = false,
        BoxFilledTransparency = 0.8, Name = true, Distance = true,
        HealthBar = true, HealthText = true, Weapon = true, Tracers = false,
        HeadDot = false, TeamCheck = false, TeamColors = false, RainbowMode = false,
        MaxDistance = 2000, NameColor = WHITE, TracerColor = BRAND,
        HeadDotColor = WHITE, BoxThickness = 1, TracerThickness = 1,
    },
    Aimbot = {
        Enabled = false, AimPart = "Head", FOV = 150, ShowFOV = true, TeamCheck = false,
    },
    Triggerbot = {
        Enabled = false, Delay = 0,
    },
    Hitbox = {
        Enabled = false, Size = 15, Visible = true,
    },
    Noclip = false,
    Fly = { Enabled = false, Speed = 60 },
    InfiniteJump = false,
    AntiAFK = false,
    SpeedBoost = { Enabled = false, Speed = 32 },
    FOVChanger = { Enabled = false, FOV = 70 },
    Fullbright = false,
    RemoveBarriers = false,
    AutoFarm = { Enabled = false, Mode = "Melee" },
}

local ESPObjects = {}
local CurrentTarget = nil
local AimbotActive = false
local HueValue = 0
local GUIVisible = true
local AimbotConnection = nil

local function NewDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function WorldToScreen(pos)
    local s, on = Camera:WorldToViewportPoint(pos)
    return V2(s.X, s.Y), on, s.Z
end

local function GetChar(plr) return plr and plr.Character end
local function GetHum(char) return char and char:FindFirstChildOfClass("Humanoid") end
local function GetRoot(char) return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")) end
local function GetHead(char) return char and char:FindFirstChild("Head") end

local function IsAlive(plr)
    local c = GetChar(plr)
    local h = GetHum(c)
    local r = GetRoot(c)
    return c and h and r and h.Health > 0
end

local function HasForceField(plr)
    local c = GetChar(plr)
    if not c then return false end
    return c:FindFirstChildOfClass("ForceField") ~= nil
end

local function GetTool(char)
    if not char then return "None" end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then return v.Name end
    end
    return "None"
end

local function GetToolObject(char)
    if not char then return nil end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then return v end
    end
    return nil
end

local function IsTeammate(plr)
    if LocalPlayer.Team and plr.Team then
        return LocalPlayer.Team == plr.Team
    end
    return false
end

local function GetTeamColor(plr)
    if plr.Team then return plr.TeamColor.Color end
    return BRAND
end

local function GetDist(pos)
    local r = GetRoot(GetChar(LocalPlayer))
    if r then return (r.Position - pos).Magnitude end
    return HUGE
end

local function AutoEquipTool()
    local char = GetChar(LocalPlayer)
    local hum = GetHum(char)
    if not char or not hum then return end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not bp then return end
    for _, tool in pairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            hum:EquipTool(tool)
            return
        end
    end
end

local function CreateESP(plr)
    if plr == LocalPlayer or ESPObjects[plr] then return end
    ESPObjects[plr] = {
        Box = NewDrawing("Square", {Thickness=1, Color=BRAND, Filled=false, Transparency=1, Visible=false}),
        BoxOutline = NewDrawing("Square", {Thickness=3, Color=C3(0,0,0), Filled=false, Transparency=1, Visible=false}),
        BoxFilled = NewDrawing("Square", {Thickness=1, Color=BRAND, Filled=true, Transparency=0.8, Visible=false}),
        Name = NewDrawing("Text", {Size=13, Font=Drawing.Fonts.UI, Color=WHITE, Center=true, Outline=true, OutlineColor=C3(0,0,0), Transparency=1, Visible=false}),
        Distance = NewDrawing("Text", {Size=13, Font=Drawing.Fonts.UI, Color=GREY, Center=true, Outline=true, OutlineColor=C3(0,0,0), Transparency=1, Visible=false}),
        HealthBarBG = NewDrawing("Line", {Thickness=4, Color=C3(0,0,0), Transparency=1, Visible=false}),
        HealthBar = NewDrawing("Line", {Thickness=2, Color=GREEN, Transparency=1, Visible=false}),
        HealthText = NewDrawing("Text", {Size=12, Font=Drawing.Fonts.UI, Color=GREEN, Center=false, Outline=true, OutlineColor=C3(0,0,0), Transparency=1, Visible=false}),
        Weapon = NewDrawing("Text", {Size=12, Font=Drawing.Fonts.UI, Color=GREY, Center=true, Outline=true, OutlineColor=C3(0,0,0), Transparency=1, Visible=false}),
        Tracer = NewDrawing("Line", {Thickness=1, Color=BRAND, Transparency=1, Visible=false}),
        HeadDot = NewDrawing("Circle", {Thickness=1, Color=WHITE, Filled=true, NumSides=30, Transparency=1, Visible=false}),
    }
end

local function RemoveESP(plr)
    local o = ESPObjects[plr]
    if o then
        for _, d in pairs(o) do pcall(function() d:Remove() end) end
        ESPObjects[plr] = nil
    end
end

local function HideESP(o)
    for _, d in pairs(o) do d.Visible = false end
end

local function UpdateESP(plr)
    local o = ESPObjects[plr]
    if not o then return end
    if not Config.ESP.Enabled then HideESP(o) return end

    local char = GetChar(plr)
    local hum = GetHum(char)
    local root = GetRoot(char)
    local head = GetHead(char)
    if not (char and hum and root and head and hum.Health > 0) then HideESP(o) return end
    if Config.ESP.TeamCheck and IsTeammate(plr) then HideESP(o) return end

    local dist = GetDist(root.Position)
    if dist > Config.ESP.MaxDistance then HideESP(o) return end

    local rPos, rOn = WorldToScreen(root.Position)
    local hPos = WorldToScreen(head.Position + V3(0, 0.5, 0))
    local lPos = WorldToScreen(root.Position - V3(0, 3, 0))
    if not rOn then HideESP(o) return end

    local bH = ABS(hPos.Y - lPos.Y)
    local bW = bH * 0.6
    local bPos = V2(rPos.X - bW / 2, hPos.Y)
    local bSize = V2(bW, bH)

    local col = BRAND
    if Config.ESP.TeamColors then col = GetTeamColor(plr) end
    if Config.ESP.RainbowMode then col = C3HSV(HueValue, 1, 1) end
    if CurrentTarget and plr == CurrentTarget then col = RED end
    if HasForceField(plr) then col = C3(0, 200, 255) end

    o.BoxOutline.Size = bSize; o.BoxOutline.Position = bPos
    o.BoxOutline.Visible = Config.ESP.BoxOutline and Config.ESP.Box

    o.Box.Size = bSize; o.Box.Position = bPos
    o.Box.Color = col; o.Box.Visible = Config.ESP.Box

    o.BoxFilled.Size = bSize; o.BoxFilled.Position = bPos
    o.BoxFilled.Color = col; o.BoxFilled.Transparency = Config.ESP.BoxFilledTransparency
    o.BoxFilled.Visible = Config.ESP.BoxFilled

    local tY = hPos.Y - 16
    if Config.ESP.Name then
        o.Name.Text = plr.DisplayName
        o.Name.Position = V2(rPos.X, tY)
        o.Name.Color = Config.ESP.RainbowMode and col or Config.ESP.NameColor
        o.Name.Visible = true
        tY = tY - 14
    else o.Name.Visible = false end

    local bY = lPos.Y + 2
    if Config.ESP.Distance then
        o.Distance.Text = FLOOR(dist) .. "m"
        o.Distance.Position = V2(rPos.X, bY)
        o.Distance.Visible = true
        bY = bY + 14
    else o.Distance.Visible = false end

    if Config.ESP.Weapon then
        o.Weapon.Text = "[" .. GetTool(char) .. "]"
        o.Weapon.Position = V2(rPos.X, bY)
        o.Weapon.Visible = true
    else o.Weapon.Visible = false end

    if Config.ESP.HealthBar then
        local hp = hum.Health / hum.MaxHealth
        local bX = bPos.X - 5
        local bTop = bPos.Y
        local bBot = bPos.Y + bH
        o.HealthBarBG.From = V2(bX, bTop); o.HealthBarBG.To = V2(bX, bBot); o.HealthBarBG.Visible = true
        local bLen = bH * hp
        o.HealthBar.From = V2(bX, bBot); o.HealthBar.To = V2(bX, bBot - bLen)
        o.HealthBar.Color = hp > 0.5 and GREEN or hp > 0.25 and YELLOW or RED
        o.HealthBar.Visible = true
        if Config.ESP.HealthText then
            o.HealthText.Text = FLOOR(hum.Health)
            o.HealthText.Position = V2(bX - 20, bBot - bLen - 6)
            o.HealthText.Color = o.HealthBar.Color
            o.HealthText.Visible = true
        else o.HealthText.Visible = false end
    else
        o.HealthBarBG.Visible = false
        o.HealthBar.Visible = false
        o.HealthText.Visible = false
    end

    if Config.ESP.Tracers then
        o.Tracer.From = V2(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        o.Tracer.To = V2(rPos.X, rPos.Y)
        o.Tracer.Color = Config.ESP.RainbowMode and col or Config.ESP.TracerColor
        o.Tracer.Visible = true
    else o.Tracer.Visible = false end

    if Config.ESP.HeadDot then
        local hp2, hp2On = WorldToScreen(head.Position)
        if hp2On then
            o.HeadDot.Position = hp2
            o.HeadDot.Radius = CLAMP(1000 / dist, 2, 6)
            o.HeadDot.Color = Config.ESP.RainbowMode and col or Config.ESP.HeadDotColor
            o.HeadDot.Visible = true
        else o.HeadDot.Visible = false end
    else o.HeadDot.Visible = false end
end

local FOVCircle = NewDrawing("Circle", {
    Thickness = 1, Color = BRAND, Filled = false, NumSides = 60,
    Radius = Config.Aimbot.FOV, Transparency = 1, Visible = false, Position = V2(0, 0),
})

local function GetClosestPlayer()
    local closest, closestDist = nil, Config.Aimbot.FOV
    local center = V2(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) and not HasForceField(plr) then
            if not (Config.Aimbot.TeamCheck and IsTeammate(plr)) then
                local char = GetChar(plr)
                local part = char:FindFirstChild(Config.Aimbot.AimPart) or GetHead(char)
                if part then
                    local sp, on = WorldToScreen(part.Position)
                    if on then
                        local d = (center - sp).Magnitude
                        if d < closestDist then closest = plr closestDist = d end
                    end
                end
            end
        end
    end
    return closest
end

local function StartAimbot()
    if AimbotConnection then return end
    AimbotConnection = RunService:BindToRenderStep("LAVI_Aimbot", Enum.RenderPriority.Camera.Value + 1, function()
        if not Config.Aimbot.Enabled then CurrentTarget = nil return end
        FOVCircle.Position = V2(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Config.Aimbot.FOV
        FOVCircle.Visible = Config.Aimbot.ShowFOV
        FOVCircle.Color = BRAND
        if not AimbotActive then CurrentTarget = nil return end
        local target = GetClosestPlayer()
        CurrentTarget = target
        if target then
            local char = GetChar(target)
            local part = char:FindFirstChild(Config.Aimbot.AimPart) or GetHead(char)
            if part then Camera.CFrame = CF(Camera.CFrame.Position, part.Position) end
        else CurrentTarget = nil end
    end)
end

local tbCD = false

RunService.Heartbeat:Connect(function()
    if not Config.Triggerbot.Enabled or tbCD then return end

    local myChar = GetChar(LocalPlayer)
    if not myChar then return end

    local tool = GetToolObject(myChar)
    if not tool then return end

    local hit = Mouse.Target
    if not hit then return end

    local targetPlayer = Players:GetPlayerFromCharacter(hit.Parent)
        or Players:GetPlayerFromCharacter(hit.Parent and hit.Parent.Parent)

    if not targetPlayer or targetPlayer == LocalPlayer then return end
    if not IsAlive(targetPlayer) then return end
    if HasForceField(targetPlayer) then return end

    tbCD = true

    pcall(mouse1press)
    task.wait(0.03)
    pcall(mouse1release)

    task.delay(Config.Triggerbot.Delay > 0 and Config.Triggerbot.Delay / 1000 or 0.05, function()
        tbCD = false
    end)
end)

RunService.Stepped:Connect(function()
    if not Config.Noclip then return end
    local char = GetChar(LocalPlayer)
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

local FlyBody, FlyGyro, Flying = nil, nil, false

local function StartFly()
    local char = GetChar(LocalPlayer)
    local root = GetRoot(char)
    local hum = GetHum(char)
    if not (char and root and hum) then return end
    Flying = true
    FlyBody = Instance.new("BodyVelocity")
    FlyBody.MaxForce = V3(math.huge, math.huge, math.huge)
    FlyBody.Velocity = V3(0, 0, 0)
    FlyBody.Parent = root
    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.MaxTorque = V3(math.huge, math.huge, math.huge)
    FlyGyro.P = 9e4
    FlyGyro.Parent = root
    hum.PlatformStand = true
end

local function StopFly()
    Flying = false
    local char = GetChar(LocalPlayer)
    local hum = GetHum(char)
    if FlyBody then FlyBody:Destroy() FlyBody = nil end
    if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
    if hum then hum.PlatformStand = false end
end

RunService:BindToRenderStep("LAVI_Fly", Enum.RenderPriority.Character.Value + 1, function()
    if Config.Fly.Enabled and Flying and FlyBody and FlyGyro then
        local root = GetRoot(GetChar(LocalPlayer))
        if not root then StopFly() return end
        FlyGyro.CFrame = Camera.CFrame
        local dir = V3(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += V3(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= V3(0, 1, 0) end
        FlyBody.Velocity = dir.Magnitude > 0 and dir.Unit * Config.Fly.Speed or V3(0, 0, 0)
    elseif not Config.Fly.Enabled and Flying then
        StopFly()
    end
end)

local OrigSizes, OrigProps = {}, {}

local function ExpandHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            local char = GetChar(plr)
            if char then
                for _, pn in pairs({"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"}) do
                    local part = char:FindFirstChild(pn)
                    if part and part:IsA("BasePart") then
                        local key = plr.Name .. "_" .. pn
                        if not OrigSizes[key] then
                            OrigSizes[key] = part.Size
                            OrigProps[key] = {Transparency = part.Transparency, Material = part.Material, CanCollide = part.CanCollide}
                        end
                        local sz = Config.Hitbox.Size
                        part.Size = V3(sz, sz, sz)
                        part.Transparency = Config.Hitbox.Visible and 0.5 or OrigProps[key].Transparency
                        part.Material = Config.Hitbox.Visible and Enum.Material.ForceField or OrigProps[key].Material
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end

local function ResetHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = GetChar(plr)
            if char then
                for _, pn in pairs({"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"}) do
                    local part = char:FindFirstChild(pn)
                    if part and part:IsA("BasePart") then
                        local key = plr.Name .. "_" .. pn
                        if OrigSizes[key] then part.Size = OrigSizes[key] end
                        if OrigProps[key] then
                            part.Transparency = OrigProps[key].Transparency
                            part.Material = OrigProps[key].Material
                            part.CanCollide = OrigProps[key].CanCollide
                        end
                    end
                end
            end
        end
    end
    OrigSizes = {}
    OrigProps = {}
end

RunService.Heartbeat:Connect(function()
    if Config.Hitbox.Enabled then ExpandHitboxes() end
end)

UserInputService.JumpRequest:Connect(function()
    if not Config.InfiniteJump then return end
    local hum = GetHum(GetChar(LocalPlayer))
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

task.spawn(function()
    while true do
        task.wait(55)
        if Config.AntiAFK then
            pcall(function()
                local hum = GetHum(GetChar(LocalPlayer))
                if hum then hum.Jump = true end
            end)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not Config.SpeedBoost.Enabled then return end
    local hum = GetHum(GetChar(LocalPlayer))
    if hum then hum.WalkSpeed = Config.SpeedBoost.Speed end
end)

RunService.RenderStepped:Connect(function()
    if Config.FOVChanger.Enabled then Camera.FieldOfView = Config.FOVChanger.FOV end
end)

local OrigLight = {}
local fbOn = false

local function ApplyFullbright()
    if fbOn then return end
    fbOn = true
    local l = game:GetService("Lighting")
    OrigLight = {Brightness=l.Brightness, ClockTime=l.ClockTime, FogEnd=l.FogEnd, GlobalShadows=l.GlobalShadows, Ambient=l.Ambient}
    l.Brightness = 2; l.ClockTime = 14; l.FogEnd = 100000; l.GlobalShadows = false; l.Ambient = C3(178, 178, 178)
    for _, v in pairs(l:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
end

local function RemoveFullbright()
    if not fbOn then return end
    fbOn = false
    local l = game:GetService("Lighting")
    l.Brightness = OrigLight.Brightness or 1
    l.ClockTime = OrigLight.ClockTime or 14
    l.FogEnd = OrigLight.FogEnd or 10000
    l.GlobalShadows = OrigLight.GlobalShadows ~= false
    l.Ambient = OrigLight.Ambient or C3(0, 0, 0)
    for _, v in pairs(l:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = true
        end
    end
end

local barriersGone = false
local function DoRemoveBarriers()
    if barriersGone then return end
    barriersGone = true
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            if v.Transparency >= 0.9 and v.CanCollide then v.CanCollide = false end
            if v.Name:lower():find("barrier") or v.Name:lower():find("wall") then
                v.CanCollide = false
                v.Transparency = 1
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if Config.Fullbright and not fbOn then ApplyFullbright()
    elseif not Config.Fullbright and fbOn then RemoveFullbright() end
    if Config.RemoveBarriers and not barriersGone then DoRemoveBarriers() end
end)

local afKills = 0

task.spawn(function()
    while true do
        task.wait(0.1)
        if not Config.AutoFarm.Enabled then continue end

        local myChar = GetChar(LocalPlayer)
        if not myChar then continue end
        local myRoot = GetRoot(myChar)
        local myHum = GetHum(myChar)
        if not myRoot or not myHum or myHum.Health <= 0 then continue end

        local tool = GetToolObject(myChar)
        if not tool then
            AutoEquipTool()
            continue
        end

        local closest, closestDist = nil, HUGE
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and IsAlive(plr) and not HasForceField(plr) then
                local tChar = GetChar(plr)
                if tChar and GetToolObject(tChar) then
                    local r = GetRoot(tChar)
                    if r then
                        local d = (myRoot.Position - r.Position).Magnitude
                        if d < closestDist then closest = plr closestDist = d end
                    end
                end
            end
        end
        if not closest then continue end

        local tChar = GetChar(closest)
        local tRoot = GetRoot(tChar)
        if not tRoot then continue end

        local angle = math.random(0, 360)
        local rad = math.rad(angle)
        local offsetX = math.cos(rad) * 1.5
        local offsetZ = math.sin(rad) * 1.5
        myRoot.CFrame = CF(tRoot.Position + V3(offsetX, 2.5, offsetZ))

        Camera.CFrame = CF(Camera.CFrame.Position, tRoot.Position)

        pcall(function() tool:Activate() end)
        pcall(mouse1click)
    end
end)

RunService.RenderStepped:Connect(function()
    HueValue = (HueValue + 0.001) % 1
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if not ESPObjects[plr] then CreateESP(plr) end
            UpdateESP(plr)
        end
    end
end)

local function ConnectKillCounter(plr)
    plr.CharacterAdded:Connect(function(c)
        local h = c:WaitForChild("Humanoid", 5)
        if h then
            h.Died:Connect(function()
                if Config.AutoFarm.Enabled then afKills += 1 end
            end)
        end
    end)
end

Players.PlayerAdded:Connect(function(plr)
    CreateESP(plr)
    ConnectKillCounter(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
    if CurrentTarget == plr then CurrentTarget = nil end
end)

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        CreateESP(plr)
        ConnectKillCounter(plr)
        local char = GetChar(plr)
        if char then
            local hum = GetHum(char)
            if hum then
                hum.Died:Connect(function()
                    if Config.AutoFarm.Enabled then afKills += 1 end
                end)
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Config.Fly.Enabled then StartFly() end
    if Config.AutoFarm.Enabled then
        task.wait(1)
        AutoEquipTool()
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.E then AimbotActive = true end
    if input.KeyCode == Enum.KeyCode.Insert then
        GUIVisible = not GUIVisible
        if CoreGui:FindFirstChild("LAVI_STUDIO_GUI") then
            CoreGui.LAVI_STUDIO_GUI.Enabled = GUIVisible
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        AimbotActive = false
        CurrentTarget = nil
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LAVI_STUDIO_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 520, 0, 400)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -200)
MainFrame.BackgroundColor3 = C3(14, 14, 14)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local ms = Instance.new("UIStroke", MainFrame)
ms.Color = C3(0, 150, 0); ms.Thickness = 1; ms.Transparency = 0.4

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = C3(18, 18, 18)
TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
local tf = Instance.new("Frame", TitleBar)
tf.Size = UDim2.new(1, 0, 0, 10); tf.Position = UDim2.new(0, 0, 1, -10)
tf.BackgroundColor3 = C3(18, 18, 18); tf.BorderSizePixel = 0

local Dot = Instance.new("Frame", TitleBar)
Dot.Size = UDim2.new(0, 8, 0, 8); Dot.Position = UDim2.new(0, 12, 0.5, -4)
Dot.BackgroundColor3 = BRAND; Dot.BorderSizePixel = 0
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Text = "LAVI STUDIO"; TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 13; TitleLbl.TextColor3 = WHITE; TitleLbl.BackgroundTransparency = 1
TitleLbl.Size = UDim2.new(0, 100, 1, 0); TitleLbl.Position = UDim2.new(0, 28, 0, 0)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local SubLbl = Instance.new("TextLabel", TitleBar)
SubLbl.Text = "KAT"; SubLbl.Font = Enum.Font.Gotham
SubLbl.TextSize = 11; SubLbl.TextColor3 = BRAND; SubLbl.BackgroundTransparency = 1
SubLbl.Size = UDim2.new(0, 30, 1, 0); SubLbl.Position = UDim2.new(0, 118, 0, 0)
SubLbl.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 22, 0, 22); CloseBtn.Position = UDim2.new(1, -30, 0.5, -11)
CloseBtn.BackgroundColor3 = C3(40, 40, 40); CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "x"; CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12; CloseBtn.TextColor3 = C3(150, 150, 150)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() GUIVisible = false ScreenGui.Enabled = false end)

local Dragging, DragInput, DragStart, StartPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true; DragStart = input.Position; StartPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
    end
end)

local LeftPanel = Instance.new("Frame", MainFrame)
LeftPanel.Size = UDim2.new(0, 120, 1, -37); LeftPanel.Position = UDim2.new(0, 2, 0, 37)
LeftPanel.BackgroundColor3 = C3(18, 18, 18); LeftPanel.BorderSizePixel = 0; LeftPanel.ClipsDescendants = true

local LeftScroll = Instance.new("ScrollingFrame", LeftPanel)
LeftScroll.Size = UDim2.new(1, 0, 1, 0); LeftScroll.BackgroundTransparency = 1
LeftScroll.ScrollBarThickness = 0; LeftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LeftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; LeftScroll.BorderSizePixel = 0
Instance.new("UIListLayout", LeftScroll).Padding = UDim.new(0, 1)

local Div = Instance.new("Frame", MainFrame)
Div.Size = UDim2.new(0, 1, 1, -37); Div.Position = UDim2.new(0, 122, 0, 37)
Div.BackgroundColor3 = C3(35, 35, 35); Div.BorderSizePixel = 0

local RightPanel = Instance.new("Frame", MainFrame)
RightPanel.Size = UDim2.new(1, -126, 1, -37); RightPanel.Position = UDim2.new(0, 125, 0, 37)
RightPanel.BackgroundTransparency = 1; RightPanel.BorderSizePixel = 0

local TabPages = {}
local TabButtons = {}
local ActiveTab = nil

local function CreateTabPage(name)
    local scroll = Instance.new("ScrollingFrame", RightPanel)
    scroll.Name = name; scroll.Size = UDim2.new(1, -6, 1, -6); scroll.Position = UDim2.new(0, 3, 0, 3)
    scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = BRAND
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.BorderSizePixel = 0; scroll.Visible = false
    local lay = Instance.new("UIListLayout", scroll); lay.Padding = UDim.new(0, 3)
    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0, 2); pad.PaddingLeft = UDim.new(0, 2); pad.PaddingRight = UDim.new(0, 2)
    TabPages[name] = scroll
    return scroll
end

local function SwitchTab(name)
    for n, p in pairs(TabPages) do p.Visible = (n == name) end
    for n, tb in pairs(TabButtons) do
        if n == name then
            tb.Button.BackgroundColor3 = C3(25, 25, 25)
            tb.Label.TextColor3 = WHITE
            tb.Accent.Visible = true
        else
            tb.Button.BackgroundColor3 = C3(18, 18, 18)
            tb.Label.TextColor3 = C3(140, 140, 140)
            tb.Accent.Visible = false
        end
    end
    ActiveTab = name
end

local function CreateTabButton(name, order)
    local btn = Instance.new("TextButton", LeftScroll)
    btn.Size = UDim2.new(1, 0, 0, 32); btn.BackgroundColor3 = C3(18, 18, 18)
    btn.BackgroundTransparency = 0; btn.BorderSizePixel = 0; btn.Text = ""
    btn.AutoButtonColor = false; btn.LayoutOrder = order

    local acc = Instance.new("Frame", btn); acc.Name = "Accent"
    acc.Size = UDim2.new(0, 3, 0.6, 0); acc.Position = UDim2.new(0, 0, 0.2, 0)
    acc.BackgroundColor3 = BRAND; acc.BorderSizePixel = 0; acc.Visible = false
    Instance.new("UICorner", acc).CornerRadius = UDim.new(0, 2)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Text = "  " .. name; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = C3(140, 140, 140); lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -8, 1, 0); lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    TabButtons[name] = {Button = btn, Label = lbl, Accent = acc}
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    btn.MouseEnter:Connect(function() if ActiveTab ~= name then btn.BackgroundColor3 = C3(22, 22, 22) end end)
    btn.MouseLeave:Connect(function() if ActiveTab ~= name then btn.BackgroundColor3 = C3(18, 18, 18) end end)
    return btn
end

local function CreateToggle(name, default, parent, callback)
    local state = default
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 28); frame.BackgroundColor3 = DARK; frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = "  " .. name; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = GREY; lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -55, 1, 0); lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(0, 36, 0, 16); track.Position = UDim2.new(1, -46, 0.5, -8)
    track.BackgroundColor3 = C3(40, 40, 40); track.BorderSizePixel = 0; track.Text = ""; track.AutoButtonColor = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 12, 0, 12); knob.BackgroundColor3 = C3(120, 120, 120); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function Update()
        if state then
            track.BackgroundColor3 = C3(0, 120, 0)
            knob.Position = UDim2.new(1, -14, 0.5, -6); knob.BackgroundColor3 = BRAND; lbl.TextColor3 = WHITE
        else
            track.BackgroundColor3 = C3(40, 40, 40)
            knob.Position = UDim2.new(0, 2, 0.5, -6); knob.BackgroundColor3 = C3(120, 120, 120); lbl.TextColor3 = GREY
        end
    end
    Update()
    track.MouseButton1Click:Connect(function() state = not state Update() callback(state) end)
    return frame
end

local function CreateSlider(name, min, max, default, parent, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 40); frame.BackgroundColor3 = DARK; frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = "  " .. name; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = GREY; lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.6, 0, 0, 20); lbl.TextXAlignment = Enum.TextXAlignment.Left

    local vLbl = Instance.new("TextLabel", frame)
    vLbl.Font = Enum.Font.GothamBold; vLbl.TextSize = 11; vLbl.TextColor3 = BRAND
    vLbl.BackgroundTransparency = 1; vLbl.Size = UDim2.new(0, 50, 0, 20)
    vLbl.Position = UDim2.new(1, -55, 0, 0); vLbl.TextXAlignment = Enum.TextXAlignment.Right

    local bg = Instance.new("Frame", frame)
    bg.Size = UDim2.new(1, -20, 0, 4); bg.Position = UDim2.new(0, 10, 0, 26)
    bg.BackgroundColor3 = C3(35, 35, 35); bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = BRAND; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0, 10, 0, 10); knob.BackgroundColor3 = WHITE; knob.BorderSizePixel = 0; knob.ZIndex = 2
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local val = CLAMP(default, min, max)
    local function SetVal(v)
        val = CLAMP(FLOOR(v + 0.5), min, max)
        local pct = (val - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -5, 0.5, -5)
        vLbl.Text = tostring(val)
        callback(val)
    end
    SetVal(default)

    local sliding = false
    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            SetVal(min + (max - min) * CLAMP((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1))
        end
    end)
    bg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            SetVal(min + (max - min) * CLAMP((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1))
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    return frame
end

local function CreateDropdown(name, options, default, parent, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 28); frame.BackgroundColor3 = DARK; frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = "  " .. name; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = GREY; lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 130, 0, 20); btn.Position = UDim2.new(1, -138, 0.5, -10)
    btn.Font = Enum.Font.Gotham; btn.TextSize = 10; btn.TextColor3 = BRAND
    btn.BackgroundColor3 = C3(30, 30, 30); btn.BorderSizePixel = 0; btn.Text = default; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local idx = 1
    for i, v in ipairs(options) do if v == default then idx = i break end end
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = options[idx]
        callback(options[idx])
    end)
    return frame
end

local espPage       = CreateTabPage("ESP")
local aimbotPage    = CreateTabPage("Aimbot")
local tbPage        = CreateTabPage("Triggerbot")
local hitboxPage    = CreateTabPage("Hitbox")
local playerPage    = CreateTabPage("Player")
local visualsPage   = CreateTabPage("Visuals")
local worldPage     = CreateTabPage("World")
local combatPage    = CreateTabPage("Combat")

CreateTabButton("ESP", 1)
CreateTabButton("Aimbot", 2)
CreateTabButton("Triggerbot", 3)
CreateTabButton("Hitbox", 4)
CreateTabButton("Player", 5)
CreateTabButton("Visuals", 6)
CreateTabButton("World", 7)
CreateTabButton("Combat", 8)

CreateToggle("ESP Enabled", Config.ESP.Enabled, espPage, function(v) Config.ESP.Enabled = v end)
CreateToggle("Box", Config.ESP.Box, espPage, function(v) Config.ESP.Box = v end)
CreateToggle("Box Outline", Config.ESP.BoxOutline, espPage, function(v) Config.ESP.BoxOutline = v end)
CreateToggle("Box Filled", Config.ESP.BoxFilled, espPage, function(v) Config.ESP.BoxFilled = v end)
CreateToggle("Name", Config.ESP.Name, espPage, function(v) Config.ESP.Name = v end)
CreateToggle("Distance", Config.ESP.Distance, espPage, function(v) Config.ESP.Distance = v end)
CreateToggle("Health Bar", Config.ESP.HealthBar, espPage, function(v) Config.ESP.HealthBar = v end)
CreateToggle("Health Text", Config.ESP.HealthText, espPage, function(v) Config.ESP.HealthText = v end)
CreateToggle("Weapon", Config.ESP.Weapon, espPage, function(v) Config.ESP.Weapon = v end)
CreateToggle("Tracers", Config.ESP.Tracers, espPage, function(v) Config.ESP.Tracers = v end)
CreateToggle("Head Dot", Config.ESP.HeadDot, espPage, function(v) Config.ESP.HeadDot = v end)
CreateToggle("Team Check", Config.ESP.TeamCheck, espPage, function(v) Config.ESP.TeamCheck = v end)
CreateToggle("Team Colors", Config.ESP.TeamColors, espPage, function(v) Config.ESP.TeamColors = v end)
CreateToggle("Rainbow Mode", Config.ESP.RainbowMode, espPage, function(v) Config.ESP.RainbowMode = v end)
CreateSlider("Max Distance", 100, 5000, Config.ESP.MaxDistance, espPage, function(v) Config.ESP.MaxDistance = v end)

CreateToggle("Aimbot Enabled", Config.Aimbot.Enabled, aimbotPage, function(v) Config.Aimbot.Enabled = v end)
CreateDropdown("Aim Part", {"Head", "HumanoidRootPart", "UpperTorso"}, Config.Aimbot.AimPart, aimbotPage, function(v) Config.Aimbot.AimPart = v end)
CreateSlider("FOV", 30, 500, Config.Aimbot.FOV, aimbotPage, function(v) Config.Aimbot.FOV = v end)
CreateToggle("Show FOV", Config.Aimbot.ShowFOV, aimbotPage, function(v) Config.Aimbot.ShowFOV = v; if not v then FOVCircle.Visible = false end end)
CreateToggle("Team Check", Config.Aimbot.TeamCheck, aimbotPage, function(v) Config.Aimbot.TeamCheck = v end)

CreateToggle("Triggerbot Enabled", Config.Triggerbot.Enabled, tbPage, function(v) Config.Triggerbot.Enabled = v end)
CreateSlider("Delay (ms)", 0, 200, Config.Triggerbot.Delay, tbPage, function(v) Config.Triggerbot.Delay = v end)

CreateToggle("Hitbox Enabled", Config.Hitbox.Enabled, hitboxPage, function(v) Config.Hitbox.Enabled = v; if not v then ResetHitboxes() end end)
CreateSlider("Hitbox Size", 5, 30, Config.Hitbox.Size, hitboxPage, function(v) Config.Hitbox.Size = v end)
CreateToggle("Show Hitbox", Config.Hitbox.Visible, hitboxPage, function(v) Config.Hitbox.Visible = v end)

CreateToggle("Noclip", Config.Noclip, playerPage, function(v) Config.Noclip = v end)
CreateToggle("Fly", Config.Fly.Enabled, playerPage, function(v) Config.Fly.Enabled = v; if v then StartFly() else StopFly() end end)
CreateSlider("Fly Speed", 10, 200, Config.Fly.Speed, playerPage, function(v) Config.Fly.Speed = v end)
CreateToggle("Infinite Jump", Config.InfiniteJump, playerPage, function(v) Config.InfiniteJump = v end)
CreateToggle("Anti AFK", Config.AntiAFK, playerPage, function(v) Config.AntiAFK = v end)
CreateToggle("Speed Boost", Config.SpeedBoost.Enabled, playerPage, function(v)
    Config.SpeedBoost.Enabled = v
    if not v then pcall(function() GetHum(GetChar(LocalPlayer)).WalkSpeed = 16 end) end
end)
CreateSlider("Walk Speed", 16, 150, Config.SpeedBoost.Speed, playerPage, function(v) Config.SpeedBoost.Speed = v end)

CreateToggle("FOV Changer", Config.FOVChanger.Enabled, visualsPage, function(v) Config.FOVChanger.Enabled = v; if not v then Camera.FieldOfView = 70 end end)
CreateSlider("FOV", 30, 120, Config.FOVChanger.FOV, visualsPage, function(v) Config.FOVChanger.FOV = v end)
CreateToggle("Fullbright", Config.Fullbright, visualsPage, function(v) Config.Fullbright = v end)

CreateToggle("Remove Barriers", Config.RemoveBarriers, worldPage, function(v) Config.RemoveBarriers = v; if v then DoRemoveBarriers() end end)

CreateToggle("Auto Farm", Config.AutoFarm.Enabled, combatPage, function(v) Config.AutoFarm.Enabled = v end)
CreateDropdown("Farm Mode", {"Melee", "Throw"}, "Melee", combatPage, function(v) Config.AutoFarm.Mode = v end)

do
    local kf = Instance.new("Frame", combatPage)
    kf.Size = UDim2.new(1, 0, 0, 28); kf.BackgroundColor3 = DARK; kf.BorderSizePixel = 0
    Instance.new("UICorner", kf).CornerRadius = UDim.new(0, 5)
    local kl = Instance.new("TextLabel", kf)
    kl.Font = Enum.Font.GothamBold; kl.TextSize = 11; kl.TextColor3 = BRAND
    kl.BackgroundTransparency = 1; kl.Size = UDim2.new(1, 0, 1, 0); kl.TextXAlignment = Enum.TextXAlignment.Left
    RunService.Heartbeat:Connect(function() kl.Text = "  Session Kills: " .. afKills end)
end

SwitchTab("ESP")
StartAimbot()

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "LAVI STUDIO",
        Text = "Yuklendi. INSERT - GUI | E - Aimbot",
        Duration = 4,
    })
end)
