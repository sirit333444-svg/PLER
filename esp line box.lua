--[[
    Axiom | Universal ESP + Aimbot
    Fitur : ESP Box, ESP Line (Tracer), Name Tag, Aimbot + FOV Circle
    Note  : Butuh executor yang support Drawing API (Synapse, Krnl, Delta, Xeno, dll)
--]]

if getgenv().AxiomESP then
    pcall(function() getgenv().AxiomESP:Destroy() end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- [1] CONFIG
-- ============================================================
local Config = {
    ESP_Enabled = true,
    ESP_Box = true,
    ESP_Line = true,
    ESP_Name = true,
    ESP_TeamCheck = true,

    Aimbot_Enabled = false,
    Aimbot_Key = Enum.KeyCode.E, -- Tombol buat nge-lock
    Aimbot_FOV = 120,
    Aimbot_Smoothness = 0.15,
    Aimbot_Part = "Head", -- "Head" atau "Torso"

    Colors = {
        Enemy = Color3.fromRGB(255, 60, 60),
        Team  = Color3.fromRGB(60, 255, 60),
        FOV   = Color3.fromRGB(255, 255, 255),
    }
}

-- ============================================================
-- [2] VARIABLES
-- ============================================================
local ESP_Objects = {}
local FOVCircle = Drawing.new("Circle")
local CurrentTarget = nil

FOVCircle.Visible = false
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Radius = Config.Aimbot_FOV
FOVCircle.Color = Config.Colors.FOV
FOVCircle.Filled = false
FOVCircle.Transparency = 1

-- ============================================================
-- [3] ESP HELPER
-- ============================================================
local function CreateESP(plr)
    if ESP_Objects[plr] then return end

    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Transparency = 1
    box.Visible = false

    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Transparency = 1
    line.Visible = false

    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.OutlineColor = Color3.new(0, 0, 0)
    name.Transparency = 1
    name.Visible = false

    ESP_Objects[plr] = {
        Box = box,
        Line = line,
        Name = name,
        Team = plr.Team
    }
end

local function RemoveESP(plr)
    local obj = ESP_Objects[plr]
    if not obj then return end
    obj.Box:Remove()
    obj.Line:Remove()
    obj.Name:Remove()
    ESP_Objects[plr] = nil
end

-- ============================================================
-- [4] AIMBOT HELPER
-- ============================================================
local function GetClosestPlayer()
    local closest = nil
    local shortest = Config.Aimbot_FOV

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
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

        if dist < shortest then
            shortest = dist
            closest = plr
        end
    end

    return closest
end

-- ============================================================
-- [5] MAIN ESP LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    -- FOV Circle
    FOVCircle.Visible = Config.Aimbot_Enabled
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Config.Aimbot_FOV

    -- ESP Render
    for plr, obj in pairs(ESP_Objects) do
        local char = plr.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then
            obj.Box.Visible = false
            obj.Line.Visible = false
            obj.Name.Visible = false
            continue
        end

        local hrp = char.HumanoidRootPart
        local head = char.Head
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if not humanoid or humanoid.Health <= 0 then
            obj.Box.Visible = false
            obj.Line.Visible = false
            obj.Name.Visible = false
            continue
        end

        -- Team check
        if Config.ESP_TeamCheck and plr.Team == LocalPlayer.Team then
            obj.Box.Visible = false
            obj.Line.Visible = false
            obj.Name.Visible = false
            continue
        end

        -- Get screen positions
        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpPos, hrpOnScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

        if not (headOnScreen and hrpOnScreen) then
            obj.Box.Visible = false
            obj.Line.Visible = false
            obj.Name.Visible = false
            continue
        end

        local color = Config.Colors.Enemy
        if plr.Team == LocalPlayer.Team then color = Config.Colors.Team end

        -- Box
        if Config.ESP_Box then
            local height = math.abs(headPos.Y - hrpPos.Y)
            local width = height * 0.6
            obj.Box.Size = Vector2.new(width, height)
            obj.Box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
            obj.Box.Color = color
            obj.Box.Visible = true
        else
            obj.Box.Visible = false
        end

        -- Line (Tracer) — dari bawah layar ke player
        if Config.ESP_Line then
            obj.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            obj.Line.To = Vector2.new(headPos.X, headPos.Y)
            obj.Line.Color = color
            obj.Line.Visible = true
        else
            obj.Line.Visible = false
        end

        -- Name Tag
        if Config.ESP_Name then
            obj.Name.Text = plr.Name .. " [" .. math.floor(humanoid.Health) .. "]"
            obj.Name.Position = Vector2.new(headPos.X, headPos.Y - 20)
            obj.Name.Color = color
            obj.Name.Visible = true
        else
            obj.Name.Visible = false
        end
    end
end)

-- ============================================================
-- [6] AIMBOT LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not Config.Aimbot_Enabled then
        CurrentTarget = nil
        return
    end

    if UserInputService:IsKeyDown(Config.Aimbot_Key) then
        local target = GetClosestPlayer()
        if target then
            CurrentTarget = target
            local part = target.Character and target.Character:FindFirstChild(Config.Aimbot_Part)
            if part then
                local newCFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Config.Aimbot_Smoothness)
            end
        end
    else
        CurrentTarget = nil
    end
end)

-- ============================================================
-- [7] PLAYER TRACKING
-- ============================================================
local function OnPlayerAdded(plr)
    if plr ~= LocalPlayer then
        CreateESP(plr)
    end
end

local function OnPlayerRemoving(plr)
    RemoveESP(plr)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

for _, plr in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(plr)
end

-- ============================================================
-- [8] CLEANUP
-- ============================================================
getgenv().AxiomESP = {
    Destroy = function()
        for plr, _ in pairs(ESP_Objects) do
            RemoveESP(plr)
        end
        FOVCircle:Remove()
    end,
    Config = Config
}

print("[Axiom] ESP + Aimbot loaded. Tekan E buat lock target.")
