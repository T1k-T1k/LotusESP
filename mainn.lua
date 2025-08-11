-- LotusHolder ESP Script - Full nil protection
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
local ESP_COLOR = Color3.new(0.8, 0.6, 1) -- Light purple
local ESP_TRANSPARENCY = 0.3
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
    local existingGui = safeFind(part, "LotusHolderESP")
    if existingGui then
        safeDestroy(existingGui)
    end
    
    local existingBox = safeFind(part, "LotusHolderBox")
    if existingBox then
        safeDestroy(existingBox)
    end
    
    -- Create BillboardGui
    local billboardGui = safeCreate("BillboardGui")
    if not billboardGui then return end
    
    safeSetProperty(billboardGui, "Name", "LotusHolderESP")
    safeSetProperty(billboardGui, "Adornee", part)
    safeSetProperty(billboardGui, "Size", UDim2.new(0, 120, 0, 60))
    safeSetProperty(billboardGui, "StudsOffset", Vector3.new(0, 3, 0))
    safeSetProperty(billboardGui, "AlwaysOnTop", true)
    safeSetProperty(billboardGui, "Parent", part)
    
    -- Create text label
    local textLabel = safeCreate("TextLabel")
    if textLabel and billboardGui then
        safeSetProperty(textLabel, "Size", UDim2.new(1, 0, 1, 0))
        safeSetProperty(textLabel, "BackgroundTransparency", 1)
        safeSetProperty(textLabel, "Text", name or "LotusHolder")
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
        safeSetProperty(selectionBox, "Name", "LotusHolderBox")
        safeSetProperty(selectionBox, "Adornee", part)
        safeSetProperty(selectionBox, "Color3", ESP_COLOR)
        safeSetProperty(selectionBox, "Transparency", ESP_TRANSPARENCY)
        safeSetProperty(selectionBox, "LineThickness", 0.25)
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

-- Search for LotusHolder in any model within Assets
local function searchLotusHolderInModel(model, roomName, modelName)
    if not model then return end
    
    -- Direct check for LotusHolder in this model
    local lotusHolder = safeFind(model, "LotusHolder")
    if lotusHolder then
        local displayName = string.format("LotusHolder\nRoom: %s\nModel: %s", 
            tostring(roomName), tostring(modelName))
        createESP(lotusHolder, displayName)
        print(string.format("Found LotusHolder in Room %s -> %s", tostring(roomName), tostring(modelName)))
        return
    end
    
    -- Recursive search in child models
    local children = safeGetChildren(model)
    for _, child in pairs(children) do
        if child and child:IsA("Model") then
            searchLotusHolderInModel(child, roomName, modelName .. "." .. tostring(child.Name))
        elseif child and child.Name == "LotusHolder" then
            local displayName = string.format("LotusHolder\nRoom: %s\nModel: %s", 
                tostring(roomName), tostring(modelName))
            createESP(child, displayName)
            print(string.format("Found LotusHolder in Room %s -> %s", tostring(roomName), tostring(modelName)))
        end
    end
end

-- Search for LotusPetalPickup in Parts.Crypt.CryptDesk.Other path
local function searchLotusPetalInRoom(room, roomName)
    if not room then return end
    
    -- Look for Parts folder
    local parts = safeFind(room, "Parts")
    if parts then
        local crypt = safeFind(parts, "Crypt")
        if crypt then
            local cryptDesk = safeFind(crypt, "CryptDesk")
            if cryptDesk then
                local other = safeFind(cryptDesk, "Other")
                if other then
                    local lotusPetal = safeFind(other, "LotusPetalPickup")
                    if lotusPetal then
                        local displayName = string.format("LotusPetalPickup\nRoom: %s\nParts->Crypt->CryptDesk->Other", roomName)
                        createESP(lotusPetal, displayName)
                        print(string.format("Found LotusPetalPickup in Room %s (Parts path)", roomName))
                    end
                end
                
                -- Also check directly in CryptDesk (original path without Other)
                local directPetal = safeFind(cryptDesk, "LotusPetalPickup")
                if directPetal then
                    local displayName = string.format("LotusPetalPickup\nRoom: %s\nParts->Crypt->CryptDesk", roomName)
                    createESP(directPetal, displayName)
                    print(string.format("Found LotusPetalPickup in Room %s (Direct CryptDesk)", roomName))
                end
            end
        end
    end
end

-- Find and update ESP
local function updateESP()
    if not ESP_ENABLED then return end
    
    clearAllESP()
    
    -- Safe workspace access
    if not Workspace then return end
    
    local currentRooms = safeFind(Workspace, "CurrentRooms")
    if not currentRooms then return end
    
    -- Iterate through all rooms
    local rooms = safeGetChildren(currentRooms)
    for _, room in pairs(rooms) do
        if room and (room:IsA("Folder") or room:IsA("Model")) then
            local roomName = tostring(room.Name)
            
            -- Search for LotusHolder in Assets path
            local assets = safeFind(room, "Assets")
            if assets then
                -- Check all children in Assets
                local assetChildren = safeGetChildren(assets)
                for _, child in pairs(assetChildren) do
                    if child then
                        local childName = tostring(child.Name)
                        
                        -- If it's a model, search for LotusHolder inside it
                        if child:IsA("Model") then
                            searchLotusHolderInModel(child, roomName, childName)
                        -- If it's directly LotusHolder
                        elseif child.Name == "LotusHolder" then
                            local displayName = string.format("LotusHolder\nRoom: %s\nDirect in Assets", roomName)
                            createESP(child, displayName)
                            print(string.format("Found LotusHolder directly in Room %s Assets", roomName))
                        end
                    end
                end
            end
            
            -- Search for LotusPetalPickup in Parts path
            searchLotusPetalInRoom(room, roomName)
        end
    end
end

-- Toggle ESP
local function toggleESP()
    ESP_ENABLED = not ESP_ENABLED
    print("Lotus ESP:", ESP_ENABLED and "ON" or "OFF")
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
                wait(0.3)
                if ESP_ENABLED then
                    print("New room detected:", tostring(child.Name))
                    updateESP()
                end
            end)
        end
    end
    
    -- Monitor Workspace for CurrentRooms creation
    if not safeFind(Workspace, "CurrentRooms") then
        connections.workspace = safeConnect(Workspace.ChildAdded, function(child)
            if child and child.Name == "CurrentRooms" then
                print("CurrentRooms folder created!")
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
    
    -- Periodic update (every 2 seconds)
    connections.heartbeat = safeConnect(RunService.Heartbeat, function()
        if ESP_ENABLED and tick() % 2 < 0.1 then
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
    
    safeSetProperty(screenGui, "Name", "LotusESP_GUI")
    safeSetProperty(screenGui, "Parent", playerGui)
    
    local toggleButton = safeCreate("TextButton")
    if not toggleButton then return end
    
    safeSetProperty(toggleButton, "Name", "ToggleButton")
    safeSetProperty(toggleButton, "Size", UDim2.new(0, 160, 0, 55))
    safeSetProperty(toggleButton, "Position", UDim2.new(0, 10, 0, 10))
    safeSetProperty(toggleButton, "BackgroundColor3", Color3.new(0.5, 0.3, 0.8))
    safeSetProperty(toggleButton, "BorderSizePixel", 0)
    safeSetProperty(toggleButton, "Text", "Lotus ESP: ON")
    safeSetProperty(toggleButton, "TextColor3", Color3.new(1, 1, 1))
    safeSetProperty(toggleButton, "TextScaled", true)
    safeSetProperty(toggleButton, "Font", Enum.Font.GothamBold)
    safeSetProperty(toggleButton, "Parent", screenGui)
    
    local corner = safeCreate("UICorner")
    if corner then
        safeSetProperty(corner, "CornerRadius", UDim.new(0, 10))
        safeSetProperty(corner, "Parent", toggleButton)
    end
    
    -- Button click
    connections.buttonClick = safeConnect(toggleButton.MouseButton1Click, function()
        toggleESP()
        safeSetProperty(toggleButton, "Text", ESP_ENABLED and "Lotus ESP: ON" or "Lotus ESP: OFF")
        safeSetProperty(toggleButton, "BackgroundColor3", ESP_ENABLED and Color3.new(0.5, 0.3, 0.8) or Color3.new(0.8, 0.3, 0.3))
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
    print("Lotus ESP loading...")
    print("Target paths:")
    print("1. workspace.CurrentRooms[*].Assets.[AnyModel].LotusHolder")
    print("2. workspace.CurrentRooms[*].Parts.Crypt.CryptDesk.Other.LotusPetalPickup")
    print("3. workspace.CurrentRooms[*].Parts.Crypt.CryptDesk.LotusPetalPickup")
    print("Color: Light Purple")
    
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
    
    print("Lotus ESP loaded successfully!")
    print("Will search for both LotusHolder and LotusPetalPickup in all rooms")
end

-- Start the script
initialize()
