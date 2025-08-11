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

-- Storage for connections to avoid memory leaks
local connections = {}

-- Function to setup room monitoring
local function setupRoomMonitoring(room)
    if not room or connections[room] then return end
    
    connections[room] = {}
    
    -- Monitor Parts folder
    local function monitorParts(parts)
        if connections[room].parts then return end
        connections[room].parts = {}
        
        -- Monitor existing and new children in Parts
        local function checkForCrypt()
            local crypt = parts:FindFirstChild("Crypt")
            if crypt and not connections[room].crypt then
                -- Monitor CryptDesk in Crypt
                connections[room].crypt = crypt.ChildAdded:Connect(function(child)
                    if child.Name == "CryptDesk" then
                        wait(0.1) -- Small delay
                        if ESP_ENABLED then updateESP() end
                    end
                end)
                
                -- Check if CryptDesk already exists
                local cryptDesk = crypt:FindFirstChild("CryptDesk")
                if cryptDesk then
                    -- Monitor LotusPetalPickup in CryptDesk
                    local connection = cryptDesk.ChildAdded:Connect(function(child)
                        if child.Name == "LotusPetalPickup" then
                            wait(0.1)
                            if ESP_ENABLED then updateESP() end
                        end
                    end)
                    table.insert(connections[room].parts, connection)
                end
            end
        end
        
        -- Check immediately and monitor for Crypt
        checkForCrypt()
        local cryptConnection = parts.ChildAdded:Connect(function(child)
            if child.Name == "Crypt" then
                wait(0.1)
                checkForCrypt()
                if ESP_ENABLED then updateESP() end
            end
        end)
        table.insert(connections[room].parts, cryptConnection)
    end
    
    -- Check if Parts already exists
    local parts = room:FindFirstChild("Parts")
    if parts then
        monitorParts(parts)
    end
    
    -- Monitor for Parts folder creation
    connections[room].main = room.ChildAdded:Connect(function(child)
        if child.Name == "Parts" then
            wait(0.1) -- Small delay to ensure folder is ready
            monitorParts(child)
            if ESP_ENABLED then updateESP() end
        end
    end)
end

-- Function to setup CurrentRooms monitoring
local function setupCurrentRoomsMonitoring()
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms then
        -- Monitor existing rooms
        for _, room in pairs(currentRooms:GetChildren()) do
            setupRoomMonitoring(room)
        end
        
        -- Monitor new rooms
        currentRooms.ChildAdded:Connect(function(room)
            print("New room detected:", room.Name)
            wait(0.2) -- Longer delay for room to fully load
            setupRoomMonitoring(room)
            if ESP_ENABLED then updateESP() end
        end)
    end
end

-- Monitor for CurrentRooms creation if it doesn't exist
local function waitForCurrentRooms()
    if Workspace:FindFirstChild("CurrentRooms") then
        setupCurrentRoomsMonitoring()
    else
        local connection
        connection = Workspace.ChildAdded:Connect(function(child)
            if child.Name == "CurrentRooms" then
                print("CurrentRooms folder created!")
                wait(0.5)
                setupCurrentRoomsMonitoring()
                if ESP_ENABLED then updateESP() end
                connection:Disconnect()
            end
        end)
    end
end

-- Update ESP periodically (reduced frequency since we have event-based updates)
local heartbeatConnection = RunService.Heartbeat:Connect(function()
    if ESP_ENABLED and tick() % 2 < 0.1 then -- Update every 2 seconds instead of every frame
        updateESP()
    end
end)

-- Start monitoring
waitForCurrentRooms()

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
    
    -- Disconnect heartbeat
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    
    -- Disconnect all room monitoring connections
    for room, roomConnections in pairs(connections) do
        if roomConnections.main then
            roomConnections.main:Disconnect()
        end
        if roomConnections.crypt then
            roomConnections.crypt:Disconnect()
        end
        if roomConnections.parts then
            for _, conn in pairs(roomConnections.parts) do
                conn:Disconnect()
            end
        end
    end
    connections = {}
    
    if screenGui then
        screenGui:Destroy()
    end
end

-- Cleanup when player leaves
LocalPlayer.CharacterRemoving:Connect(cleanup)

print("LotusPetal ESP loaded! Use the button in top-left corner to toggle.")
print("Looking for: workspace.CurrentRooms[*].Parts.Crypt.CryptDesk.LotusPetalPickup")
print("Monitoring for dynamic content creation...")
