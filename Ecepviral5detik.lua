--[[
    Axiom | Post-Processing Shader Suite
    Preset: Realistic, Cinematic, Vibrant, Cyberpunk
    Fitur : Tween halus antar preset, GUI draggable, cleanup otomatis.
--]]

if getgenv().AxiomShader then
    pcall(function() getgenv().AxiomShader:Destroy() end)
end

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- [1] PRESETS — Tweaked sesuai selera
-- ============================================================
local PRESETS = {
    Default = {
        Ambient          = Color3.fromRGB(70, 70, 70),
        OutdoorAmbient   = Color3.fromRGB(128, 128, 128),
        Brightness       = 2,
        ClockTime        = 14,
        FogEnd           = 100000,
        FogStart         = 0,
        FogColor         = Color3.fromRGB(192, 192, 192),
        GlobalShadows    = true,
        EnvironmentDiffuseScale = 0,
        EnvironmentSpecularScale = 0,
        ExposureCompensation = 0,
        ColorCorrection = {Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.fromRGB(255,255,255)},
        Bloom           = {Intensity = 0, Size = 0, Threshold = 0},
        DepthOfField    = {FarIntensity = 0, FocusDistance = 0, InFocusRadius = 0, NearIntensity = 0},
        SunRays         = {Intensity = 0, Spread = 0},
        Atmosphere      = {Density = 0, Offset = 0, Color = Color3.fromRGB(199,199,199), Decay = Color3.fromRGB(106,112,125), Glare = 0, Haze = 0},
    },
    Realistic = {
        Ambient          = Color3.fromRGB(40, 45, 55),
        OutdoorAmbient   = Color3.fromRGB(100, 105, 115),
        Brightness       = 2.5,
        ClockTime        = 14.5,
        FogEnd           = 8000,
        FogStart         = 100,
        FogColor         = Color3.fromRGB(180, 190, 200),
        GlobalShadows    = true,
        EnvironmentDiffuseScale = 0.5,
        EnvironmentSpecularScale = 0.5,
        ExposureCompensation = 0.2,
        ColorCorrection = {Brightness = 0.02, Contrast = 0.12, Saturation = 0.05, TintColor = Color3.fromRGB(255, 250, 245)},
        Bloom           = {Intensity = 0.6, Size = 24, Threshold = 1.2},
        DepthOfField    = {FarIntensity = 0.15, FocusDistance = 40, InFocusRadius = 60, NearIntensity = 0.05},
        SunRays         = {Intensity = 0.08, Spread = 0.8},
        Atmosphere      = {Density = 0.32, Offset = 0.1, Color = Color3.fromRGB(199,199,199), Decay = Color3.fromRGB(106,112,125), Glare = 0.1, Haze = 1.2},
    },
    Cinematic = {
        Ambient          = Color3.fromRGB(20, 20, 30),
        OutdoorAmbient   = Color3.fromRGB(80, 80, 100),
        Brightness       = 1.8,
        ClockTime        = 17,
        FogEnd           = 5000,
        FogStart         = 50,
        FogColor         = Color3.fromRGB(120, 110, 100),
        GlobalShadows    = true,
        EnvironmentDiffuseScale = 0.3,
        EnvironmentSpecularScale = 0.8,
        ExposureCompensation = -0.2,
        ColorCorrection = {Brightness = -0.05, Contrast = 0.2, Saturation = -0.1, TintColor = Color3.fromRGB(255, 240, 220)},
        Bloom           = {Intensity = 1.2, Size = 32, Threshold = 0.9},
        DepthOfField    = {FarIntensity = 0.4, FocusDistance = 25, InFocusRadius = 40, NearIntensity = 0.15},
        SunRays         = {Intensity = 0.15, Spread = 1},
        Atmosphere      = {Density = 0.4, Offset = 0.25, Color = Color3.fromRGB(180, 170, 160), Decay = Color3.fromRGB(80, 70, 60), Glare = 0.2, Haze = 2},
    },
    Vibrant = {
        Ambient          = Color3.fromRGB(90, 90, 90),
        OutdoorAmbient   = Color3.fromRGB(160, 160, 160),
        Brightness       = 3,
        ClockTime        = 13,
        FogEnd           = 20000,
        FogStart         = 0,
        FogColor         = Color3.fromRGB(200, 220, 255),
        GlobalShadows    = true,
        EnvironmentDiffuseScale = 0.8,
        EnvironmentSpecularScale = 0.8,
        ExposureCompensation = 0.3,
        ColorCorrection = {Brightness = 0.05, Contrast = 0.25, Saturation = 0.5, TintColor = Color3.fromRGB(255,255,255)},
        Bloom           = {Intensity = 0.8, Size = 20, Threshold = 1.5},
        DepthOfField    = {FarIntensity = 0, FocusDistance = 0, InFocusRadius = 0, NearIntensity = 0},
        SunRays         = {Intensity = 0.1, Spread = 0.6},
        Atmosphere      = {Density = 0.2, Offset = 0, Color = Color3.fromRGB(220, 230, 255), Decay = Color3.fromRGB(120, 140, 180), Glare = 0, Haze = 0.5},
    },
    Cyberpunk = {
        Ambient          = Color3.fromRGB(20, 10, 40),
        OutdoorAmbient   = Color3.fromRGB(60, 30, 90),
        Brightness       = 1.5,
        ClockTime        = 0,
        FogEnd           = 3000,
        FogStart         = 0,
        FogColor         = Color3.fromRGB(30, 0, 60),
        GlobalShadows    = true,
        EnvironmentDiffuseScale = 0.6,
        EnvironmentSpecularScale = 1,
        ExposureCompensation = 0.1,
        ColorCorrection = {Brightness = -0.02, Contrast = 0.35, Saturation = 0.4, TintColor = Color3.fromRGB(200, 150, 255)},
        Bloom           = {Intensity = 1.5, Size = 28, Threshold = 0.8},
        DepthOfField    = {FarIntensity = 0.2, FocusDistance = 30, InFocusRadius = 50, NearIntensity = 0.1},
        SunRays         = {Intensity = 0.05, Spread = 0.5},
        Atmosphere      = {Density = 0.5, Offset = 0.3, Color = Color3.fromRGB(80, 40, 120), Decay = Color3.fromRGB(40, 10, 80), Glare = 0.4, Haze = 3},
    },
}

-- ============================================================
-- [2] CORE EFFECT MANAGER
-- ============================================================
local function ensureEffect(className, name)
    local fx = Lighting:FindFirstChild(name)
    if not fx or fx.ClassName ~= className then
        if fx then fx:Destroy() end
        fx = Instance.new(className)
        fx.Name = name
        fx.Parent = Lighting
    end
    return fx
end

local function tweenProp(instance, prop, value, duration)
    local tween = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[prop] = value})
    tween:Play()
end

local function applyPreset(presetName, duration)
    local p = PRESETS[presetName]
    if not p then return false end
    duration = duration or 1.5

    -- Lighting properties
    tweenProp(Lighting, "Ambient", p.Ambient, duration)
    tweenProp(Lighting, "OutdoorAmbient", p.OutdoorAmbient, duration)
    tweenProp(Lighting, "Brightness", p.Brightness, duration)
    tweenProp(Lighting, "ClockTime", p.ClockTime, duration)
    tweenProp(Lighting, "FogEnd", p.FogEnd, duration)
    tweenProp(Lighting, "FogStart", p.FogStart, duration)
    tweenProp(Lighting, "FogColor", p.FogColor, duration)
    tweenProp(Lighting, "EnvironmentDiffuseScale", p.EnvironmentDiffuseScale, duration)
    tweenProp(Lighting, "EnvironmentSpecularScale", p.EnvironmentSpecularScale, duration)
    tweenProp(Lighting, "ExposureCompensation", p.ExposureCompensation, duration)
    Lighting.GlobalShadows = p.GlobalShadows

    -- ColorCorrection
    local cc = ensureEffect("ColorCorrectionEffect", "Axiom_CC")
    for k, v in pairs(p.ColorCorrection) do tweenProp(cc, k, v, duration) end

    -- Bloom
    local bl = ensureEffect("BloomEffect", "Axiom_Bloom")
    for k, v in pairs(p.Bloom) do tweenProp(bl, k, v, duration) end

    -- DepthOfField
    local dof = ensureEffect("DepthOfFieldEffect", "Axiom_DOF")
    for k, v in pairs(p.DepthOfField) do tweenProp(dof, k, v, duration) end

    -- SunRays
    local sr = ensureEffect("SunRaysEffect", "Axiom_SunRays")
    for k, v in pairs(p.SunRays) do tweenProp(sr, k, v, duration) end

    -- Atmosphere
    local at = ensureEffect("Atmosphere", "Axiom_Atmosphere")
    for k, v in pairs(p.Atmosphere) do tweenProp(at, k, v, duration) end

    return true
end

-- Apply default first
applyPreset("Realistic", 0.5)

-- ============================================================
-- [3] GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AxiomShader"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
getgenv().AxiomShader = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 240, 0, 340)
main.Position = UDim2.new(0, 20, 0.5, -170)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(100, 80, 160)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Axiom | Shader Suite"
title.TextColor3 = Color3.fromRGB(220, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local status = Instance.new("TextLabel", main)
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 40)
status.BackgroundTransparency = 1
status.Text = "Preset: Realistic"
status.TextColor3 = Color3.fromRGB(160, 160, 180)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left

local function makePresetBtn(label, y, presetName)
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(80, 60, 120)
    btnStroke.Thickness = 1

    btn.MouseButton1Click:Connect(function()
        applyPreset(presetName, 1.2)
        status.Text = "Preset: " .. label
    end)
end

makePresetBtn("Realistic", 70, "Realistic")
makePresetBtn("Cinematic", 115, "Cinematic")
makePresetBtn("Vibrant", 160, "Vibrant")
makePresetBtn("Cyberpunk", 205, "Cyberpunk")
makePresetBtn("Default (Reset)", 250, "Default")

local info = Instance.new("TextLabel", main)
info.Size = UDim2.new(1, -20, 0, 40)
info.Position = UDim2.new(0, 10, 0, 295)
info.BackgroundTransparency = 1
info.Text = "Klik preset buat ganti. Tween 1.2 detik biar mulus."
info.TextWrapped = true
info.TextColor3 = Color3.fromRGB(130, 130, 150)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top