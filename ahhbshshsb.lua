-- ===================
-- ESP LINE & BOX SCRIPT
-- ===================

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
local Box_Color = Color3.fromRGB(0, 255, 50)      -- Warna kotak (hijau)
local Box_Thickness = 1.5                         -- Ketebalan garis kotak
local Line_Color = Color3.fromRGB(255, 0, 0)     -- Warna garis (merah)
local Line_Thickness = 1.5                        -- Ketebalan garis
local Team_Check = true                          -- Cek tim (true = tidak tampil untuk satu tim)
local Max_Distance = 500                         -- Jarak maksimal (studs)

-- Storage untuk drawing objects
local esp_objects = {}

-- Fungsi membuat kotak baru (2D Square)
local function create_box()
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Box_Color
    box.Thickness = Box_Thickness
    box.Filled = false
    box.Transparency = 1
    box.ZIndex = 2
    return box
end

-- Fungsi membuat outline kotak (hitam, opsional)
local function create_box_outline()
    local outline = Drawing.new("Square")
    outline.Visible = false
    outline.Color = Color3.new(0, 0, 0)
    outline.Thickness = Box_Thickness * 2
    outline.Filled = false
    outline.Transparency = 0.5
    outline.ZIndex = 1
    return outline
end

-- Fungsi membuat garis (line) untuk tracer
local function create_line()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Line_Color
    line.Thickness = Line_Thickness
    line.Transparency = 1
    line.ZIndex = 1
    return line
end

-- Fungsi membersihkan ESP untuk pemain tertentu
local function cleanup_esp(player)
    if esp_objects[player] then
        for _, obj in pairs(esp_objects[player]) do
            if obj then
                obj:Remove()
            end
        end
        esp_objects[player] = nil
    end
end

-- Fungsi utama ESP untuk setiap pemain
local function setup_esp(player)
    -- Jangan buat ESP untuk local player
    if player == LocalPlayer then return end
    
    -- Buat drawing objects
    local drawings = {
        box = create_box(),
        box_outline = create_box_outline(),
        line = create_line()
    }
    
    esp_objects[player] = drawings
    
    -- Update ESP setiap frame
    RunService.RenderStepped:Connect(function()
        local char = player.Character
        local humanoid = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        
        -- Cek apakah karakter valid
        if not char or not humanoid or not root or not head or humanoid.Health <= 0 then
            for _, obj in pairs(drawings) do
                obj.Visible = false
            end
            return
        end
        
        -- Cek tim (jika Team_Check aktif)
        if Team_Check and player.Team == LocalPlayer.Team then
            for _, obj in pairs(drawings) do
                obj.Visible = false
            end
            return
        end
        
        -- Cek jarak maksimal
        local distance = (Camera.CFrame.Position - root.Position).Magnitude
        if distance > Max_Distance then
            for _, obj in pairs(drawings) do
                obj.Visible = false
            end
            return
        end
        
        -- Konversi posisi dunia ke layar
        local root_pos, on_screen = Camera:WorldToViewportPoint(root.Position)
        local head_pos = Camera:WorldToViewportPoint(head.Position)
        
        if not on_screen then
            for _, obj in pairs(drawings) do
                obj.Visible = false
            end
            return
        end
        
        -- Hitung ukuran kotak berdasarkan jarak antara head dan root
        local height = math.abs(head_pos.Y - root_pos.Y) * 2.5
        local width = height * 0.6
        
        -- Posisi kotak (tengah di root, atas di head)
        local box_x = root_pos.X - width / 2
        local box_y = head_pos.Y - height * 0.15
        
        -- Update Box
        drawings.box.Visible = true
        drawings.box.Size = Vector2.new(width, height)
        drawings.box.Position = Vector2.new(box_x, box_y)
        
        -- Update Box Outline
        drawings.box_outline.Visible = true
        drawings.box_outline.Size = Vector2.new(width, height)
        drawings.box_outline.Position = Vector2.new(box_x, box_y)
        
        -- Update Line (dari bawah layar ke pemain)
        drawings.line.Visible = true
        drawings.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        drawings.line.To = Vector2.new(root_pos.X, root_pos.Y)
        
        -- Warna berdasarkan tim (opsional)
        if player.Team then
            local team_color = player.Team.TeamColor.Color
            drawings.box.Color = team_color
        else
            drawings.box.Color = Box_Color
        end
    end)
end

-- Setup ESP untuk semua pemain yang sudah ada
for _, player in pairs(Players:GetPlayers()) do
    setup_esp(player)
end

-- Setup ESP untuk pemain yang baru bergabung
Players.PlayerAdded:Connect(function(player)
    setup_esp(player)
end)

-- Cleanup ESP ketika pemain keluar
Players.PlayerRemoving:Connect(function(player)
    cleanup_esp(player)
end)