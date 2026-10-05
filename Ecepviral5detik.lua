--[[
    Axiom | Steal An Egg - Auto Steal + Auto Treadmill
    Safe Zone: Manual
--]]

if getgenv().AxiomStealEgg then
    pcall(function() getgenv().AxiomStealEgg:Destroy() end)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    Remotes = {
        Steal       = "AskFieldEggCarry",
        Treadmill   = "AskWearStill",
    },
    Delays = {
        Steal       = 0.35,
        Treadmill   = 0.5,
    },
    Toggles = {
        AutoSteal     = false,
        AutoTreadmill = false,
        Pause         = false,
    },
    TeleportOffset = Vector3.new(0, 3, 0),
}

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function resolveRemote(name)
    if not name or name == "" then return nil end
    local ok, remote = pcall(function()
        return ReplicatedStorage:FindFirstChild(name, true) or workspace:FindFirstChild(name, true)
    end)
    if ok and remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
        return remote
    end
    return nil
end

local function fireRemote(remoteName, ...)
    local remote = resolveRemote(remoteName)
    if not remote then return false end
    local args = {...}
    local ok = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(table.unpack(args))
        else
            remote:InvokeServer(table.unpack(args))
        end
    end)
    return ok
end

local function teleportTo(part)
    local hrp = getHRP()
    if hrp and part then
        hrp.CFrame = CFrame.new(part.Position + CONFIG.TeleportOffset)
    end
end

local function matches(name, keywords)
    local l = string.lower(name)
    for _, kw in ipairs(keywords) do
        if string.find(l, kw, 1, true) then return true end
    end
    return false
end

local function findNearestEgg()
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and matches(obj.Name, {"egg", "FirstAreaEgg"}) then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = (part.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = obj
                end
            end
        end
    end
    return best
end

local function getEggArgs(egg)
    if not egg then return nil end
    local uid = egg:GetAttribute("Uid") or (egg:FindFirstChild("Uid") and egg.Uid.Value)
    local slotKey = egg:GetAttribute("FirstAreaSlotKey") or (egg:FindFirstChild("FirstAreaSlotKey") and egg.FirstAreaSlotKey.Value)

    if not uid or not slotKey then
        for _, d in ipairs(egg:GetDescendants()) do
            if d:IsA("StringValue") then
                if d.Name == "Uid" then uid = d.Value end
                if d.Name == "FirstAreaSlotKey" then slotKey = d.Value end
            end
        end
    end

    if uid and slotKey then
        return { FirstAreaSlotKey = slotKey, Uid = uid }
    end
    return nil
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AxiomStealEgg"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
getgenv().AxiomStealEgg = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 270, 0, 260)
main.Position = UDim2.new(0.5, -135, 0.5, -130)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(90, 90, 110)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Axiom | Steal An Egg"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local status = Instance.new("TextLabel", main)
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 40)
status.BackgroundTransparency = 1
status.Text = "Status: Idle"
status.TextColor3 = Color3.fromRGB(180, 180, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left

local function makeToggle(label, y, key)
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(1, -20, 0, 36)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.BorderSizePixel = 0
    btn.Text = label .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        CONFIG.Toggles[key] = not CONFIG.Toggles[key]
        btn.Text = label .. ": " .. (CONFIG.Toggles[key] and "ON" or "OFF")
        btn.BackgroundColor3 = CONFIG.Toggles[key] and Color3.fromRGB(45, 90, 45) or Color3.fromRGB(35, 35, 45)
    end)
end

makeToggle("Auto Steal", 70, "AutoSteal")
makeToggle("Auto Treadmill", 115, "AutoTreadmill")
makeToggle("Pause (Manual Safe Zone)", 160, "Pause")

local info = Instance.new("TextLabel", main)
info.Size = UDim2.new(1, -20, 0, 70)
info.Position = UDim2.new(0, 10, 0, 205)
info.BackgroundTransparency = 1
info.Text = "Boss man, kalo mau drop telur ke safe zone, nyalain Pause dulu biar Auto Steal berhenti."
info.TextWrapped = true
info.TextColor3 = Color3.fromRGB(150, 150, 170)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top

-- Loops
task.spawn(function()
    while task.wait(CONFIG.Delays.Steal) do
        if CONFIG.Toggles.AutoSteal and not CONFIG.Toggles.Pause then
            local egg = findNearestEgg()
            if egg then
                teleportTo(egg)
                local args = getEggArgs(egg)
                if args then
                    local ok = fireRemote(CONFIG.Remotes.Steal, args)
                    status.Text = ok and "Status: Steal fired." or "Status: Gagal tembak steal."
                else
                    status.Text = "Status: Egg ketemu, Uid/Slot gak ada."
                end
            else
                status.Text = "Status: Egg gak ketemu di workspace."
            end
        end
    end
end)

task.spawn(function()
    while task.wait(CONFIG.Delays.Treadmill) do
        if CONFIG.Toggles.AutoTreadmill and not CONFIG.Toggles.Pause then
            local ok = fireRemote(CONFIG.Remotes.Treadmill)
            status.Text = ok and "Status: Treadmill invoked." or "Status: Gagal invoke treadmill."
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)