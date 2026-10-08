--[[
    Axiom | ESP + Aimbot GUI (Fixed)
    Fitur : ESP Box, Line, Name, Health, Distance, Aimbot + FOV
    Note  : Compatible executor mobile (Delta, Arceus, Xeno, dll)
--]]

-- [0] CEK SUPPORT DRAWING
if not Drawing then
    warn("[Axiom] Executor lu gak support Drawing API. ESP gak bisa jalan.")
    return
end

-- [1] CLEANUP SCRIPT LAMA
if _G.AxiomESP then
    pcall(function() _G.AxiomESP:Destroy() end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- [2] CONFIG
-- ============================================================
local Config = {
    ESP_Enabled = true,
    ESP_Box = true,
    ESP_Line = true,
    ESP_Name = true,
    ESP_Health = true,
    ESP_Distance = false,
    ESP_TeamCheck = true,

    Aimbot_Enabled = false,
    Aimbot_Key = Enum.KeyCode.E,
    Aimbot_FOV = 120,
    Aimbot_Smoothness = 0.15,
    Aimbot_Part = "Head",

    Colors = {
        Enemy = Color3.fromRGB(255, 60, 60),
        Team  = Color3.fromRGB(60, 255, 60),
        FOV   = Color3.fromRGB(255, 255, 255),
    }
}

-- ============================================================
-- [3] DRAWING OBJECTS
-- ============================================================
local ESP_Objects = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Radius = Config.Aimbot_FOV
FOVCircle.Color = Config.Colors.FOV
FOVCircle.Filled = false
FOVCircle.Transparency = 1

-- ============================================================
-- [4] ESP HELPER
-- ============================================================
local function CreateESP(plr)
    if ESP_Objects[plr] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1.5; box.Filled = false; box.Transparency = 1; box.Visible = false

    local line = Drawing.new("Line")
    line.Thickness = 1.5; line.Transparency = 1; line.Visible = false

    local name = Drawing.new("Text")
    name.Size = 14; name.Center = true; name.Outline = true
    name.OutlineColor = Color3.new(0, 0, 0); name.Transparency = 1; name.Visible = false

    local health = Drawing.new("Text")
    health.Size = 12; health.Center = true; health.Outline = true
    health.OutlineColor = Color3.new(0, 0, 0); health.Transparency = 1; health.Visible = false

    local dist = Drawing.new("Text")
    dist.Size = 12; dist.Center = true; dist.Outline = true
    dist.OutlineColor = Color3.new(0, 0, 0); dist.Transparency = 1; dist.Visible = false

    ESP_Objects[plr] = {
        Box = box, Line = line, Name = name, Health = health, Dist = dist
    }
end

local function RemoveESP(plr)
    local o = ESP_Objects[plr]
    if not o then return end
    o.Box:Remove(); o.Line:Remove(); o.Name:Remove()
    o.Health:Remove(); o.Dist:Remove()
    ESP_Objects[plr] = nil
end

local function ClearAllESP()
    for plr, _ in pairs(ESP_Objects) do RemoveESP(plr) end
end

-- ============================================================
-- [5] AIMBOT HELPER
-- ============================================================
local function GetClosestPlayer()
    local closest, shortest = nil, Config.Aimbot_FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if Config.ESP_TeamCheck and plr.Team == LocalPlayer.Team then continue end
        local char = plr.Character
        if not char then continue end
        local part = char:FindFirstChild(Config.Aimbot_Part)
        if not part then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local mousePos = UserInputService:GetMouseLocation()
        local d = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if d < shortest then shortest = d; closest = plr end
    end
    return closest
end

-- ============================================================
-- [6] MAIN ESP LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = Config.Aimbot_Enabled and Config.ESP_Enabled
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Config.Aimbot_FOV
    FOVCircle.Color = Config.Colors.FOV

    for plr, obj in pairs(ESP_Objects) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not (Config.ESP_Enabled and hrp and head and hum and hum.Health > 0) then
            obj.Box.Visible=false; obj.Line.Visible=false; obj.Name.Visible=false
            obj.Health.Visible=false; obj.Dist.Visible=false
            continue
        end

        if Config.ESP_TeamCheck and plr.Team == LocalPlayer.Team then
            obj.Box.Visible=false; obj.Line.Visible=false; obj.Name.Visible=false
            obj.Health.Visible=false; obj.Dist.Visible=false
            continue
        end

        local headPos, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpPos, rOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

        if not (hOn and rOn) then
            obj.Box.Visible=false; obj.Line.Visible=false; obj.Name.Visible=false
            obj.Health.Visible=false; obj.Dist.Visible=false
            continue
        end

        local color = Config.Colors.Enemy
        if plr.Team == LocalPlayer.Team then color = Config.Colors.Team end

        -- Box
        if Config.ESP_Box then
            local h = math.abs(headPos.Y - hrpPos.Y)
            local w = h * 0.6
            obj.Box.Size = Vector2.new(w, h)
            obj.Box.Position = Vector2.new(headPos.X - w/2, headPos.Y)
            obj.Box.Color = color
            obj.Box.Visible = true
        else obj.Box.Visible = false end

        -- Line
        if Config.ESP_Line then
            obj.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            obj.Line.To = Vector2.new(headPos.X, headPos.Y)
            obj.Line.Color = color
            obj.Line.Visible = true
        else obj.Line.Visible = false end

        -- Name
        if Config.ESP_Name then
            obj.Name.Text = plr.Name
            obj.Name.Position = Vector2.new(headPos.X, headPos.Y - 20)
            obj.Name.Color = color
            obj.Name.Visible = true
        else obj.Name.Visible = false end

        -- Health
        if Config.ESP_Health then
            obj.Health.Text = "HP: " .. math.floor(hum.Health)
            obj.Health.Position = Vector2.new(headPos.X, headPos.Y - 36)
            obj.Health.Color = Color3.fromRGB(255, 255, 100)
            obj.Health.Visible = true
        else obj.Health.Visible = false end

        -- Distance
        if Config.ESP_Distance then
            local d = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
            obj.Dist.Text = d .. " studs"
            obj.Dist.Position = Vector2.new(headPos.X, headPos.Y - 52)
            obj.Dist.Color = Color3.fromRGB(180, 200, 255)
            obj.Dist.Visible = true
        else obj.Dist.Visible = false end
    end
end)

-- ============================================================
-- [7] AIMBOT LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not Config.Aimbot_Enabled then return end
    if UserInputService:IsKeyDown(Config.Aimbot_Key) then
        local target = GetClosestPlayer()
        if target and target.Character then
            local part = target.Character:FindFirstChild(Config.Aimbot_Part)
            if part then
                local newCF = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame = Camera.CFrame:Lerp(newCF, Config.Aimbot_Smoothness)
            end
        end
    end
end)

-- ============================================================
-- [8] PLAYER TRACKING
-- ============================================================
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateESP(p) end end)
Players.PlayerRemoving:Connect(RemoveESP)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end

-- ============================================================
-- [9] GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AxiomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Floating "A" Button
local AButton = Instance.new("TextButton")
AButton.Name = "AButton"
AButton.Size = UDim2.new(0, 50, 0, 50)
AButton.Position = UDim2.new(0, 20, 0.5, -25)
AButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
AButton.BorderSizePixel = 0
AButton.Text = "A"
AButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AButton.Font = Enum.Font.GothamBold
AButton.TextSize = 26
AButton.AutoButtonColor = false
AButton.Active = true
AButton.Parent = ScreenGui

local ACorner = Instance.new("UICorner", AButton)
ACorner.CornerRadius = UDim.new(1, 0)

local AStroke = Instance.new("UIStroke", AButton)
AStroke.Color = Color3.fromRGB(232, 89, 12)
AStroke.Thickness = 2

local AGradient = Instance.new("UIGradient", AButton)
AGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
}
AGradient.Rotation = 90

-- Main Panel
local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.new(0, 260, 0, 420)
Panel.Position = UDim2.new(0, 80, 0.5, -210)
Panel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
Panel.BorderSizePixel = 0
Panel.Visible = false
Panel.Active = true
Panel.Draggable = true
Panel.Parent = ScreenGui

local PCorner = Instance.new("UICorner", Panel)
PCorner.CornerRadius = UDim.new(0, 12)

local PStroke = Instance.new("UIStroke", Panel)
PStroke.Color = Color3.fromRGB(232, 89, 12)
PStroke.Thickness = 1.5

local PTitle = Instance.new("TextLabel")
PTitle.Size = UDim2.new(1, 0, 0, 40)
PTitle.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
PTitle.BorderSizePixel = 0
PTitle.Text = "AXIOM  |  ESP + AIMBOT"
PTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PTitle.Font = Enum.Font.GothamBold
PTitle.TextSize = 14
PTitle.Parent = Panel

local PTTitleCorner = Instance.new("UICorner", PTitle)
PTTitleCorner.CornerRadius = UDim.new(0, 12)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Panel

local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 8)

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -16, 1, -50)
ScrollFrame.Position = UDim2.new(0, 8, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(232, 89, 12)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = Panel

local ListLayout = Instance.new("UIListLayout", ScrollFrame)
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function MakeSection(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = "▸ " .. text
    lbl.TextColor3 = Color3.fromRGB(232, 89, 12)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = ScrollFrame
    return lbl
end

local function MakeToggle(text, order, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = ScrollFrame

    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(0, 10, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    dot.BorderSizePixel = 0
    dot.Parent = btn

    local dc = Instance.new("UICorner", dot)
    dc.CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 34, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local function refresh()
        local on = getter()
        if on then
            dot.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            btn.BackgroundColor3 = Color3.fromRGB(30, 45, 35)
        else
            dot.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
            btn.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
        end
    end

    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)

    refresh()
    return btn
end

local function MakeSlider(text, order, minV, maxV, getter, setter, step)
    step = step or 1
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = ScrollFrame

    local c = Instance.new("UICorner", frame)
    c.CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 22)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 60, 0, 22)
    valLbl.Position = UDim2.new(1, -70, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(getter())
    valLbl.TextColor3 = Color3.fromRGB(232, 89, 12)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 36)
    bar.BackgroundColor3 = Color3.fromRGB(60, 62, 70)
    bar.BorderSizePixel = 0
    bar.Parent = frame

    local bc = Instance.new("UICorner", bar)
    bc.CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((getter() - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(232, 89, 12)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fc = Instance.new("UICorner", fill)
    fc.CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function updateFromX(mouseX)
        local absPos = bar.AbsolutePosition.X
        local width = bar.AbsoluteSize.X
        local rel = math.clamp((mouseX - absPos) / width, 0, 1)
        local val = minV + rel * (maxV - minV)
        val = math.floor(val / step) * step
        setter(val)
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new((val - minV) / (maxV - minV), 0, 1, 0)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return frame
end

local function MakeButton(text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(232, 89, 12)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = true
    btn.LayoutOrder = order
    btn.Parent = ScrollFrame

    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ISI PANEL
MakeSection("VISUAL", 1)
MakeToggle("ESP Master Toggle", 2, function() return Config.ESP_Enabled end, function(v) Config.ESP_Enabled = v end)
MakeToggle("ESP Box", 3, function() return Config.ESP_Box end, function(v) Config.ESP_Box = v end)
MakeToggle("ESP Line (Tracer)", 4, function() return Config.ESP_Line end, function(v) Config.ESP_Line = v end)
MakeToggle("ESP Name", 5, function() return Config.ESP_Name end, function(v) Config.ESP_Name = v end)
MakeToggle("ESP Health", 6, function() return Config.ESP_Health end, function(v) Config.ESP_Health = v end)
MakeToggle("ESP Distance", 7, function() return Config.ESP_Distance end, function(v) Config.ESP_Distance = v end)
MakeToggle("Team Check", 8, function() return Config.ESP_TeamCheck end, function(v) Config.ESP_TeamCheck = v end)

MakeSection("AIMBOT", 10)
MakeToggle("Aimbot Master", 11, function() return Config.Aimbot_Enabled end, function(v) Config.Aimbot_Enabled = v end)
MakeSlider("Aimbot FOV", 12, 30, 500, function() return Config.Aimbot_FOV end, function(v) Config.Aimbot_FOV = v end)
MakeSlider("Aimbot Smoothness", 13, 0.02, 1.0, function() return Config.Aimbot_Smoothness end, function(v) Config.Aimbot_Smoothness = math.floor(v * 100) / 100 end, 0.01)

MakeSection("EXTRA", 15)
MakeButton("Reset ESP Cache", 16, function() ClearAllESP(); for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end end)
MakeButton("Unload Script", 17, function() _G.AxiomESP.Destroy(); ScreenGui:Destroy() end)

-- TOGGLE PANEL
local open = false
local function setOpen(v)
    open = v
    Panel.Visible = v
    if v then
        AStroke.Color = Color3.fromRGB(46, 204, 113)
        AButton.TextColor3 = Color3.fromRGB(46, 204, 113)
    else
        AStroke.Color = Color3.fromRGB(232, 89, 12)
        AButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

-- DRAG BUTTON
AButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        local dragStart = input.Position
        local startPos = AButton.Position
        local moved = false

        local moveConn, endConn
        moveConn = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or
               i.UserInputType == Enum.UserInputType.Touch then
                local delta = i.Position - dragStart
                if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
    = "Panel"
Panel.Size = UDim2.new(0, 260, 0, 420)
Panel.Position = UDim2.new(0, 80, 0.5, -210)
Panel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
Panel.BorderSizePixel = 0
Panel.Visible = false
Panel.Active = true
Panel.Draggable = true
Panel.Parent = ScreenGui

local PCorner = Instance.new("UICorner", Panel)
PCorner.CornerRadius = UDim.new(0, 12)

local PStroke = Instance.new("UIStroke", Panel)
PStroke.Color = Color3.fromRGB(232, 89, 12)
PStroke.Thickness = 1.5

local PTitle = Instance.new("TextLabel")
PTitle.Size = UDim2.new(1, 0, 0, 40)
PTitle.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
PTitle.BorderSizePixel = 0
PTitle.Text = "AXIOM  |  ESP + AIMBOT"
PTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PTitle.Font = Enum.Font.GothamBold
PTitle.TextSize = 14
PTitle.Parent = Panel

local PTTitleCorner = Instance.new("UICorner", PTitle)
PTTitleCorner.CornerRadius = UDim.new(0, 12)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Panel

local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 8)

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -16, 1, -50)
ScrollFrame.Position = UDim2.new(0, 8, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(232, 89, 12)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = Panel

local ListLayout = Instance.new("UIListLayout", ScrollFrame)
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function MakeSection(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = "▸ " .. text
    lbl.TextColor3 = Color3.fromRGB(232, 89, 12)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = ScrollFrame
    return lbl
end

local function MakeToggle(text, order, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = ScrollFrame

    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(0, 10, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    dot.BorderSizePixel = 0
    dot.Parent = btn

    local dc = Instance.new("UICorner", dot)
    dc.CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 34, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local function refresh()
        local on = getter()
        if on then
            dot.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            btn.BackgroundColor3 = Color3.fromRGB(30, 45, 35)
        else
            dot.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
            btn.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
        end
    end

    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)

    refresh()
    return btn
end

local function MakeSlider(text, order, minV, maxV, getter, setter, step)
    step = step or 1
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = ScrollFrame

    local c = Instance.new("UICorner", frame)
    c.CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 22)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 60, 0, 22)
    valLbl.Position = UDim2.new(1, -70, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(getter())
    valLbl.TextColor3 = Color3.fromRGB(232, 89, 12)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 36)
    bar.BackgroundColor3 = Color3.fromRGB(60, 62, 70)
    bar.BorderSizePixel = 0
    bar.Parent = frame

    local bc = Instance.new("UICorner", bar)
    bc.CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((getter() - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(232, 89, 12)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fc = Instance.new("UICorner", fill)
    fc.CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function updateFromX(mouseX)
        local absPos = bar.AbsolutePosition.X
        local width = bar.AbsoluteSize.X
        local rel = math.clamp((mouseX - absPos) / width, 0, 1)
        local val = minV + rel * (maxV - minV)
        val = math.floor(val / step) * step
        setter(val)
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new((val - minV) / (maxV - minV), 0, 1, 0)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return frame
end

local function MakeButton(text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(232, 89, 12)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = true
    btn.LayoutOrder = order
    btn.Parent = ScrollFrame

    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

------------------------------------------------------------
-- ISI PANEL
------------------------------------------------------------
MakeSection("VISUAL", 1)
MakeToggle("ESP Master Toggle", 2, function() return Config.ESP_Enabled end, function(v) Config.ESP_Enabled = v end)
MakeToggle("ESP Box", 3, function() return Config.ESP_Box end, function(v) Config.ESP_Box = v end)
MakeToggle("ESP Line (Tracer)", 4, function() return Config.ESP_Line end, function(v) Config.ESP_Line = v end)
MakeToggle("ESP Name", 5, function() return Config.ESP_Name end, function(v) Config.ESP_Name = v end)
MakeToggle("ESP Health", 6, function() return Config.ESP_Health end, function(v) Config.ESP_Health = v end)
MakeToggle("ESP Distance", 7, function() return Config.ESP_Distance end, function(v) Config.ESP_Distance = v end)
MakeToggle("Team Check", 8, function() return Config.ESP_TeamCheck end, function(v) Config.ESP_TeamCheck = v end)

MakeSection("AIMBOT", 10)
MakeToggle("Aimbot Master", 11, function() return Config.Aimbot_Enabled end, function(v) Config.Aimbot_Enabled = v end)
MakeSlider("Aimbot FOV", 12, 30, 500, function() return Config.Aimbot_FOV end, function(v) Config.Aimbot_FOV = v end)
MakeSlider("Aimbot Smoothness", 13, 0.02, 1.0, function() return Config.Aimbot_Smoothness end, function(v) Config.Aimbot_Smoothness = math.floor(v * 100) / 100 end, 0.01)

MakeSection("EXTRA", 15)
MakeButton("Reset ESP Cache", 16, function() ClearAllESP(); for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end end)
MakeButton("Unload Script", 17, function() getgenv().AxiomESP.Destroy(); ScreenGui:Destroy() end)

------------------------------------------------------------
-- TOGGLE PANEL
------------------------------------------------------------
local open = false
local function setOpen(v)
    open = v
    Panel.Visible = v
    if v then
        AStroke.Color = Color3.fromRGB(46, 204, 113)
        AButton.TextColor3 = Color3.fromRGB(46, 204, 113)
    else
        AStroke.Color = Color3.fromRGB(232, 89, 12)
        AButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

------------------------------------------------------------
-- DRAG BUTTON
------------------------------------------------------------
local dragging = false
local dragStart, startPos

AButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType =
