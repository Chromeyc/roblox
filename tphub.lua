local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "🎮 TP Hub",
    SubTitle = "by smh",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460), 
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local function Notify(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
end

local Tabs = {
    Main = Window:AddTab({ Title = "👥 Players", Icon = "users" }),
    Positions = Window:AddTab({ Title = "📍 Positions", Icon = "bookmark" })
}

local SavedPositions = {}

local function LoadSavedPositions()
    local success, data = pcall(function()
        if isfile("SavedPositions.json") then
            return game:GetService("HttpService"):JSONDecode(readfile("SavedPositions.json"))
        end
        return {}
    end)
    
    if success and type(data) == "table" then
        for name, posData in pairs(data) do
            SavedPositions[name] = CFrame.new(unpack(posData))
        end
        return true
    end
    SavedPositions = {}
    return false
end

local function SavePositionsToFile()
    local dataToSave = {}
    for name, cf in pairs(SavedPositions) do
        dataToSave[name] = {cf:GetComponents()}
    end
    writefile("SavedPositions.json", game:GetService("HttpService"):JSONEncode(dataToSave))
end

local function GetSavedPositionNames()
    local names = {}
    for name, _ in pairs(SavedPositions) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

pcall(function()
    LoadSavedPositions()
end)

local function GetPlayers()
    local players = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            table.insert(players, player.Name)
        end
    end
    return players
end

local function TeleportToPlayer(playerName)
    local targetPlayer = game.Players:FindFirstChild(playerName)
    if not targetPlayer then return false end
    
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer then return false end
    
    local function getCharacterAndRoot(player)
        local char = player.Character
        if not char then return nil end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        
        return char, root
    end
    
    local maxAttempts = 30 
    local attempts = 0
    
    while attempts < maxAttempts do
        local targetChar, targetRoot = getCharacterAndRoot(targetPlayer)
        local localChar, localRoot = getCharacterAndRoot(localPlayer)
        
        if targetRoot and localRoot then
            localRoot.CFrame = targetRoot.CFrame
            return true
        end
        
        attempts = attempts + 1
        task.wait(0.1)
    end
    
    return false
end

local function BringPlayerToMe(playerName)
    local targetPlayer = game.Players:FindFirstChild(playerName)
    if not targetPlayer then return false end
    
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer then return false end
    
    local function getCharacterAndRoot(player)
        local char = player.Character
        if not char then return nil end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return nil end
        
        return char, root, humanoid
    end
    
    local maxAttempts = 30
    local attempts = 0
    
    while attempts < maxAttempts do
        local localChar, localRoot, localHum = getCharacterAndRoot(localPlayer)
        local targetChar, targetRoot, targetHum = getCharacterAndRoot(targetPlayer)
        
        if localChar and localRoot and targetChar and targetRoot and targetHum then
            local networkClaim
            pcall(function()
                networkClaim = Instance.new("RemoteEvent", game:GetService("ReplicatedStorage"))
                networkClaim.Name = "TeleportRequest_" .. targetPlayer.UserId
            end)
            
            pcall(function()
                targetHum:ChangeState(Enum.HumanoidStateType.Physics)
                targetRoot:PivotTo(localRoot.CFrame)
                targetHum:ChangeState(Enum.HumanoidStateType.Running)
                                targetChar:PivotTo(localRoot.CFrame)
                
                targetHum.WalkToPoint = localRoot.Position
                
                targetChar:SetPrimaryPartCFrame(localRoot.CFrame)
            end)
            
            if networkClaim then
                task.delay(1, function()
                    pcall(function()
                        networkClaim:Destroy()
                    end)
                end)
            end
            
            return true
        end
        
        attempts = attempts + 1
        task.wait(0.1)
    end
    
    return false
end

local function SaveCurrentPosition(posName)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        SavedPositions[posName] = char.HumanoidRootPart.CFrame
        SavePositionsToFile()
        return true
    end
    return false
end

Tabs.Main:AddParagraph({
    Title = "👥 PLAYER TELEPORT",
    Content = "Select a player to teleport to them"
})

local selectedPlayer = nil

local PlayerDropdown = Tabs.Main:AddDropdown("PlayerSelect", {
    Title = "Select Player",
    Values = GetPlayers(),
    Multi = false,
    Default = "",
    Callback = function(Value)
        selectedPlayer = Value
    end
})

Tabs.Main:AddButton({
    Title = "🔄 Refresh Players",
    Description = "Update the player list",
    Callback = function()
        local players = GetPlayers()
        PlayerDropdown:SetValues(players)
        Notify("Players Refreshed", "Player list has been updated", 2)
    end
})

Tabs.Main:AddButton({
    Title = "🏃 Teleport to Player",
    Description = "Teleport to the selected player's location",
    Callback = function()
        if selectedPlayer and selectedPlayer ~= "" then
            if TeleportToPlayer(selectedPlayer) then
                Notify("Success", "Teleported to " .. selectedPlayer, 2)
            else
                Notify("Error", "Failed to teleport to " .. selectedPlayer, 3)
            end
        else
            Notify("Error", "Please select a player first", 3)
        end
    end
})

Tabs.Main:AddButton({
    Title = "🧲 Bring Player",
    Description = "Bring the selected player to your location",
    Callback = function()
        if selectedPlayer and selectedPlayer ~= "" then
            if BringPlayerToMe(selectedPlayer) then
                Notify("Success", "Attempting to bring " .. selectedPlayer .. " to you", 2)
            else
                Notify("Error", "Failed to bring " .. selectedPlayer, 3)
            end
        else
            Notify("Error", "Please select a player first", 3)
        end
    end
})

Tabs.Positions:AddParagraph({
    Title = "📍 SAVE NEW POSITION",
    Content = "Save your current location with a custom name"
})

local PositionNameInput = Tabs.Positions:AddInput("PositionName", {
    Title = "💫 Position Name",
    Default = "",
    Placeholder = "Enter a name for this position...",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
    end
})

Tabs.Positions:AddButton({
    Title = "💾 Save Position",
    Description = "Save your current location",
    Icon = "save",
    Callback = function()
        local posName = PositionNameInput.Value
        if not posName or posName == "" then
            Notify("Error", "Please enter a position name", 3)
            return
        end
        
        if SaveCurrentPosition(posName) then
            pcall(function()
                SavedPositionsDropdown:SetValues(GetSavedPositionNames())
            end)
            PositionNameInput:SetValue("")
            Notify("Position Saved", "Location '" .. posName .. "' has been saved", 2)
        else
            Notify("Error", "Failed to save position. Make sure your character exists", 3)
        end
    end
})

Tabs.Positions:AddParagraph({
    Title = "",
    Content = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
})

Tabs.Positions:AddParagraph({
    Title = "🎯 TELEPORT TO SAVED POSITION",
    Content = "Select and teleport to your saved locations"
})

local SavedPositionsDropdown = Tabs.Positions:AddDropdown("SavedPositions", {
    Title = "📌 Select Position",
    Values = GetSavedPositionNames(),
    Multi = false,
    Default = 1,
})

Tabs.Positions:AddButton({
    Title = "⚡ Teleport",
    Description = "Teleport to selected position",
    Icon = "navigation",
    Callback = function()
        local posName = SavedPositionsDropdown.Value
        if not posName then
            Notify("Error", "Please select a position", 3)
            return
        end
        
        if SavedPositions[posName] then
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = SavedPositions[posName]
                Notify("Success", "Teleported to '" .. posName .. "'", 2)
            else
                Notify("Error", "Character not found", 3)
            end
        else
            Notify("Error", "Position not found", 3)
        end
    end
})

Tabs.Positions:AddButton({
    Title = "🔄 Refresh List",
    Description = "Update saved positions list",
    Icon = "refresh-cw",
    Callback = function()
        LoadSavedPositions()
        SavedPositionsDropdown:SetValues(GetSavedPositionNames())
        Notify("Success", "Position list refreshed", 2)
    end
})

Tabs.Positions:AddParagraph({
    Title = "",
    Content = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
})

Tabs.Positions:AddParagraph({
    Title = "🗑️ DELETE POSITION",
    Content = "Remove a position from your saved locations"
})

local DeletePositionInput = Tabs.Positions:AddInput("DeletePosition", {
    Title = "❌ Position to Delete",
    Default = "",
    Placeholder = "Enter exact position name to delete...",
    Numeric = false,
    Finished = false,
    Callback = function(Value) end
})

Tabs.Positions:AddButton({
    Title = "🗑️ Delete Position",
    Description = "Delete selected position",
    Icon = "trash-2",
    Callback = function()
        local posName = DeletePositionInput.Value
        if not posName or posName == "" then
            Notify("Error", "Please enter a position name", 3)
            return
        end
        
        if SavedPositions[posName] then
            SavedPositions[posName] = nil
            SavePositionsToFile()
            SavedPositionsDropdown:SetValues(GetSavedPositionNames())
            DeletePositionInput:SetValue("")
            Notify("Success", "Position '" .. posName .. "' deleted", 2)
        else
            Notify("Error", "Position not found", 3)
        end
    end
})

Tabs.Positions:AddButton({
    Title = " 📋 Copy Current CFrame",
    Description = "Copy your current position CFrame to clipboard",
    Icon = "clipboard",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            setclipboard(tostring(char.HumanoidRootPart.CFrame))
        end
    end
})

SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:BuildConfigSection(Tabs.Main)

SaveManager:LoadAutoloadConfig()
