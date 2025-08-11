-- LotusPetal ESP Script
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
local ESP_ENABLED = true
local ESP_COLOR = Color3.new(1, 0.5, 0) -- Orange color
local ESP_TRANSPARENCY = 0.5
local TEXT_COLOR = Color3.new(1, 1, 1) -- White text

-- Storage for ESP objects
local espObjects = {}

-- Function to create ESP highlight
local function createESP(part, name)
    if not part or not part.Parent then return end
    
    -- Create BillboardGui for text
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "LotusPetalESP"
    billboardGui.Adornee = part
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = part
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = name or "Lotus Petal"
    textLabel.TextColor3 = TEXT_COLOR
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Parent = billboardGui
    
    -- Create SelectionBox for outline
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Name = "LotusPetalBox"
    selectionBox.Adornee = part
    selectionBox.Color3 = ESP_COLOR
    selectionBox.Transparency = ESP_TRANSPARENCY
    selectionBox.LineThickness = 0.2
    selectionBox.Parent = part
    
    -- Store ESP objects for cleanup
    table.insert(espObjects, {
        part = part,
        billboard = billboardGui,
        selectionBox = selectionBox
    })
end

-- Function to remove ESP from a part
local function removeESP(part)
    if part:FindFirstChild("LotusPetalESP") then
        part.LotusPetalESP:Destroy()
    end
    if part:FindFirstChild("LotusPetalBox") then
        part.LotusPetalBox:Destroy()
    end
end

-- Function to clear all ESP
local function clearAllESP()
    for _, espData in pairs(espObjects) do
        if espData.billboard and espData.billboard.Parent then
            espData.billboard:Destroy()
        end
        if espData.selectionBox and espData.selectionBox.Parent then
            espData.selectionBox:Destroy()
        end
    end
    espObjects = {}
end

-- Function to find and highlight LotusPetalPickup in all rooms
local function updateESP()
    if not ESP_ENABLED then return end
    
    -- Clear existing ESP
    clearAllESP()
    
    -- Check if CurrentRooms exists
    if not Workspace:FindFirstChild("CurrentRooms") then return end
    
    local currentRooms = Workspace.CurrentRooms
    
    -- Iterate through all children of CurrentRooms (room numbers)
    for _, room in pairs(currentRooms:GetChildren()) do
        if room:IsA("Folder") or room:IsA("Model") then
            -- Try to find the path: room.Parts.Crypt.CryptDesk.LotusPetalPickup
            local parts = room:FindFirstChild("Parts")
            if parts then
                local crypt = parts:FindFirstChild("Crypt")
                if crypt then
                    local cryptDesk = crypt:FindFirstChild("CryptDesk")
                    if cryptDesk then
                        local lotusPetal = cryptDesk:FindFirstChild("LotusPetalPickup")
                        if lotusPetal then
                            createESP(lotusPetal, "Lotus Petal (Room " .. room.Name .. ")")
                            print("Found LotusPetalPickup in room:", room.Name)
                        end
                    end
                end
            end
        end
    end
end

-- Function to toggle ESP
local function toggleESP()
    ESP_ENABLED = not ESP_ENABLED
    if ESP_ENABLED then
        print("LotusPetal ESP: ON")
        updateESP()
    else
        print("LotusPetal ESP: OFF")
        clearAllESP()
    end
end

-- Initial ESP update
updateESP()

-- Update ESP periodically and when new rooms are added
local connection = RunService.Heartbeat:Connect(function()
    if ESP_ENABLED then
        updateESP()
    end
end)

-- Listen for new rooms being added
if Workspace:FindFirstChild("CurrentRooms") then
    Workspace.CurrentRooms.ChildAdded:Connect(function()
        if ESP_ENABLED then
            wait(0.5) -- Small delay to ensure room is fully loaded
            updateESP()
        end
    end)
end

-- GUI for easy toggle (optional)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LotusPetalESP_GUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 150, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "ESP: ON"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = screenGui

-- Add corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleButton

toggleButton.MouseButton1Click:Connect(function()
    toggleESP()
    toggleButton.Text = ESP_ENABLED and "ESP: ON" or "ESP: OFF"
    toggleButton.BackgroundColor3 = ESP_ENABLED and Color3.new(0, 0.7, 0) or Color3.new(0.7, 0, 0)
end)

-- Cleanup function
local function cleanup()
    clearAllESP()
    if connection then
        connection:Disconnect()
    end
    if screenGui then
        screenGui:Destroy()
    end
end

-- Cleanup when player leaves
LocalPlayer.CharacterRemoving:Connect(cleanup)

print("LotusPetal ESP loaded! Use the button in top-left corner to toggle.")
print("Looking for: workspace.CurrentRooms[*].Parts.Crypt.CryptDesk.LotusPetalPickup")
