-- LotusPetal ESP Script - Full nil protection kaka
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Safe service access
local function safeGetService(serviceName)
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    return success and service or nil
end

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace and Workspace.CurrentCamera or nil

-- ESP Settings
local ESP_ENABLED = true
local ESP_COLOR = Color3.new(1, 0.5, 0)
local ESP_TRANSPARENCY = 0.5
local TEXT_COLOR = Color3.new(1, 1, 1)

-- Storage
local espObjects = {}
local connections = {}

-- Safe instance creation
local function safeCreate(className)
    local success, instance = pcall(function()
        return Instance.new(className)
    end)
    return success and instance or nil
end

-- Safe FindFirstChild
local function safeFind(parent, childName)
    if not parent then return nil end
    local success, result = pcall(function()
        return parent:FindFirstChild(childName)
    end)
    return success and result or nil
end

-- Safe GetChildren
local function safeGetChildren(parent)
    if not parent then return {} end
    local success, result = pcall(function()
        return parent:GetChildren()
    end)
    return success and result or {}
end

-- Safe property setting
local function safeSetProperty(object, property, value)
    if not object then return false end
    local success = pcall(function()
        object[property] = value
    end)
    return success
end

-- Safe destroy
local function safeDestroy(object)
    if not object then return end
    pcall(function()
        object:Destroy()
    end)
end

-- Safe connection
local function safeConnect(signal, func)
    if not signal or not func then return nil end
    local success, connection = pcall(function()
        return signal:Connect(func)
    end)
    return success and connection or nil
end

-- Create ESP highlight
local function createESP(part, name)
    if not part or not part.Parent then return end
    
    -- Remove existing ESP first
    local existingGui = safeFind(part, "LotusPetalESP")
    if existingGui then
        safeDestroy(existingGui)
    end
    
    local existingBox = safeFind(part, "LotusPetalBox")
    if existingBox then
        safeDestroy(existingBox)
    end
    
    -- Create BillboardGui
    local billboardGui = safeCreate("BillboardGui")
    if not billboardGui then return end
    
    safeSetProperty(billboardGui, "Name", "LotusPetalESP")
    safeSetProperty(billboardGui, "Adornee", part)
    safeSetProperty(billboardGui, "Size", UDim2.new(0, 100, 0, 50))
    safeSetProperty(billboardGui, "StudsOffset", Vector3.new(0, 2, 0))
    safeSetProperty(billboardGui, "AlwaysOnTop", true)
    safeSetProperty(billboardGui, "Parent", part)
    
    -- Create text label
    local textLabel = safeCreate("TextLabel")
    if textLabel and billboardGui then
        safeSetProperty(textLabel, "Size", UDim2.new(1, 0, 1, 0))
        safeSetProperty(textLabel, "BackgroundTransparency", 1)
        safeSetProperty(textLabel, "Text", name or "Lotus Petal")
        safeSetProperty(textLabel, "TextColor3", TEXT_COLOR)
        safeSetProperty(textLabel, "TextScaled", true)
        safeSetProperty(textLabel, "Font", Enum.Font.GothamBold)
        safeSetProperty(textLabel, "TextStrokeTransparency", 0)
        safeSetProperty(textLabel, "TextStrokeColor3", Color3.new(0, 0, 0))
        safeSetProperty(textLabel, "Parent", billboardGui)
    end
    
    -- Create SelectionBox
    local selectionBox = safeCreate("SelectionBox")
    if selectionBox then
        safeSetProperty(selectionBox, "Name", "LotusPetalBox")
        safeSetProperty(selectionBox, "Adornee", part)
        safeSetProperty(selectionBox, "Color3", ESP_COLOR)
        safeSetProperty(selectionBox, "Transparency", ESP_TRANSPARENCY)
        safeSetProperty(selectionBox, "LineThickness", 0.2)
        safeSetProperty(selectionBox, "Parent", part)
    end
    
    -- Store for cleanup
    table.insert(espObjects, {
        part = part,
        billboard = billboardGui,
        selectionBox = selectionBox
    })
end

-- Clear all ESP
local function clearAllESP()
    for _, espData in pairs(espObjects) do
        if espData.billboard then
            safeDestroy(espData.billboard)
        end
        if espData.selectionBox then
            safeDestroy(espData.selectionBox)
        end
    end
    espObjects = {}
end

-- Find and update ESP
local function updateESP()
    if not ESP_ENABLED then return end
    
    clearAllESP()
    
    -- Safe workspace access
    if not Workspace then return end
    
    local currentRooms = safeFind(Workspace, "CurrentRooms")
    if not currentRooms then return end
    
    -- Iterate through rooms
    local rooms = safeGetChildren(currentRooms)
    for _, room in pairs(rooms) do
        if room and (room:IsA("Folder") or room:IsA("Model")) then
            local parts = safeFind(room, "Parts")
            if parts then
                local crypt = safeFind(parts, "Crypt")
                if crypt then
                    local cryptDesk = safeFind(crypt, "CryptDesk")
                    if cryptDesk then
                        local lotusPetal = safeFind(cryptDesk, "LotusPetalPickup")
                        if lotusPetal then
                            local roomName = room.Name or "Unknown"
                            createESP(lotusPetal, "Lotus Petal (Room " .. tostring(roomName) .. ")")
                            print("Found LotusPetalPickup in room:", roomName)
                        end
                    end
                end
            end
        end
    end
end

-- Toggle ESP
local function toggleESP()
    ESP_ENABLED = not ESP_ENABLED
    print("LotusPetal ESP:", ESP_ENABLED and "ON" or "OFF")
    if ESP_ENABLED then
        updateESP()
    else
        clearAllESP()
    end
end

-- Safe monitoring setup
local function setupMonitoring()
    -- Monitor CurrentRooms
    local function monitorCurrentRooms()
        local currentRooms = safeFind(Workspace, "CurrentRooms")
        if currentRooms and not connections.currentRooms then
            connections.currentRooms = safeConnect(currentRooms.ChildAdded, function(child)
                wait(0.2)
                if ESP_ENABLED then
                    updateESP()
                end
            end)
        end
    end
    
    -- Monitor Workspace for CurrentRooms creation
    if not safeFind(Workspace, "CurrentRooms") then
        connections.workspace = safeConnect(Workspace.ChildAdded, function(child)
            if child and child.Name == "CurrentRooms" then
                wait(0.5)
                monitorCurrentRooms()
                if ESP_ENABLED then
                    updateESP()
                end
            end
        end)
    else
        monitorCurrentRooms()
    end
    
    -- Periodic update (every 3 seconds)
    connections.heartbeat = safeConnect(RunService.Heartbeat, function()
        if ESP_ENABLED and tick() % 3 < 0.1 then
            updateESP()
        end
    end)
end

-- Create GUI safely
local function createGUI()
    if not LocalPlayer then return end
    
    local playerGui = safeFind(LocalPlayer, "PlayerGui")
    if not playerGui then return end
    
    local screenGui = safeCreate("ScreenGui")
    if not screenGui then return end
    
    safeSetProperty(screenGui, "Name", "LotusPetalESP_GUI")
    safeSetProperty(screenGui, "Parent", playerGui)
    
    local toggleButton = safeCreate("TextButton")
    if not toggleButton then return end
    
    safeSetProperty(toggleButton, "Name", "ToggleButton")
    safeSetProperty(toggleButton, "Size", UDim2.new(0, 150, 0, 50))
    safeSetProperty(toggleButton, "Position", UDim2.new(0, 10, 0, 10))
    safeSetProperty(toggleButton, "BackgroundColor3", Color3.new(0, 0.7, 0))
    safeSetProperty(toggleButton, "BorderSizePixel", 0)
    safeSetProperty(toggleButton, "Text", "ESP: ON")
    safeSetProperty(toggleButton, "TextColor3", Color3.new(1, 1, 1))
    safeSetProperty(toggleButton, "TextScaled", true)
    safeSetProperty(toggleButton, "Font", Enum.Font.GothamBold)
    safeSetProperty(toggleButton, "Parent", screenGui)
    
    local corner = safeCreate("UICorner")
    if corner then
        safeSetProperty(corner, "CornerRadius", UDim.new(0, 8))
        safeSetProperty(corner, "Parent", toggleButton)
    end
    
    -- Button click
    connections.buttonClick = safeConnect(toggleButton.MouseButton1Click, function()
        toggleESP()
        safeSetProperty(toggleButton, "Text", ESP_ENABLED and "ESP: ON" or "ESP: OFF")
        safeSetProperty(toggleButton, "BackgroundColor3", ESP_ENABLED and Color3.new(0, 0.7, 0) or Color3.new(0.7, 0, 0))
    end)
    
    connections.screenGui = screenGui
end

-- Cleanup function
local function cleanup()
    clearAllESP()
    
    -- Disconnect all connections
    for name, connection in pairs(connections) do
        if name ~= "screenGui" and connection and typeof(connection) == "RBXScriptConnection" then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    
    -- Destroy GUI
    if connections.screenGui then
        safeDestroy(connections.screenGui)
    end
    
    connections = {}
end

-- Safe initialization
local function initialize()
    print("LotusPetal ESP loading...")
    
    -- Initial ESP update
    updateESP()
    
    -- Setup monitoring
    setupMonitoring()
    
    -- Create GUI
    createGUI()
    
    -- Setup cleanup
    if LocalPlayer and LocalPlayer.CharacterRemoving then
        connections.cleanup = safeConnect(LocalPlayer.CharacterRemoving, cleanup)
    end
    
    print("LotusPetal ESP loaded successfully!")
    print("Looking for: workspace.CurrentRooms[*].Parts.Crypt.CryptDesk.LotusPetalPickup")
    print("Full nil protection enabled - script will work even if nothing exists at startup")
end

-- Start the script
initialize()
