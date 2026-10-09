-- ESP Box & Line by Executor
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local ESP = {}

-- Setting
local SETTINGS = {
    BoxColor = Color3.fromRGB(0, 255, 0),
    LineColor = Color3.fromRGB(255, 0, 0),
    TextColor = Color3.fromRGB(255, 255, 255),
    ShowBox = true,
    ShowLine = true,
    ShowName = true,
    ShowDistance = true,
}

local function createDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function addESP(player)
    if player == LocalPlayer then return end

    local data = {
        Box = createDrawing("Square", {
            Thickness = 1,
            Filled = false,
            Color = SETTINGS.BoxColor,
            Visible = false,
        }),
        Line = createDrawing("Line", {
            Thickness = 1,
            Color = SETTINGS.LineColor,
            Visible = false,
        }),
        Name = createDrawing("Text", {
            Size = 14,
            Center = true,
            Outline = true,
            Color = SETTINGS.TextColor,
            Visible = false,
        }),
        Distance = createDrawing("Text", {
            Size = 12,
            Center = true,
            Outline = true,
            Color = SETTINGS.TextColor,
            Visible = false,
        }),
    }

    ESP[player] = data
end

local function removeESP(player)
    if ESP[player] then
        for _, d in pairs(ESP[player]) do
            d:Remove()
        end
        ESP[player] = nil
    end
end

-- Tambah semua player
for _, p in ipairs(Players:GetPlayers()) do addESP(p) end

Players.PlayerAdded:Connect(addESP)
Players.PlayerRemoving:Connect(removeESP)

-- Update loop
RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        if char and hrp and head and humanoid and humanoid.Health > 0 then
            local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                -- Hitung ukuran box berdasarkan jarak
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                local height = (Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))).Y
                local bottom = (Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))).Y
                local boxHeight = math.abs(bottom - height)
                local boxWidth = boxHeight * 0.6

                -- BOX
                if SETTINGS.ShowBox then
                    data.Box.Size = Vector2.new(boxWidth, boxHeight)
                    data.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, height)
                    data.Box.Visible = true
                else
                    data.Box.Visible = false
                end

                -- LINE (dari bawah layar ke player)
                if SETTINGS.ShowLine then
                    data.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    data.Line.To = Vector2.new(rootPos.X, bottom)
                    data.Line.Visible = true
                else
                    data.Line.Visible = false
                end

                -- NAME
                if SETTINGS.ShowName then
                    data.Name.Text = player.Name
                    data.Name.Position = Vector2.new(rootPos.X, height - 18)
                    data.Name.Visible = true
                else
                    data.Name.Visible = false
                end

                -- DISTANCE
                if SETTINGS.ShowDistance then
                    data.Distance.Text = string.format("[%d studs]", math.floor(distance))
                    data.Distance.Position = Vector2.new(rootPos.X, bottom + 2)
                    data.Distance.Visible = true
                else
                    data.Distance.Visible = false
                end
            else
                for _, d in pairs(data) do d.Visible = false end
            end
        else
            for _, d in pairs(data) do d.Visible = false end
        end
    end
end)