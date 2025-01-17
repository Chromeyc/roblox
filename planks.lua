local replicated_storage = game:GetService("ReplicatedStorage")
local replicated_first = game:GetService("ReplicatedFirst")
local run_service = game:GetService("RunService")
local players = game:GetService("Players")

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local local_player = players.LocalPlayer

local remotes = replicated_storage.Remotes
local modules = replicated_first.Modules

local damage = remotes.CarbonEngine.Damage

local find_part_on_ray = workspace.FindPartOnRayWithIgnoreList

local raycast = require(modules.Client.Utilities.Raycast)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Lumania Hub",
    SubTitle = "by smh",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Market = Window:AddTab({ Title = "Market", Icon = "shopping-cart" })
}

local Options = Fluent.Options

_G.EnableAimbot = false
_G.EnableSpinBot = false
_G.EnableFly = false
_G.EnableESP = false
_G.WalkSpeed = 16
_G.CFspeed = 50
_G.EnableAutoKill = false
_G.EnableAutoBuy = false
_G.SelectedCrate = "Amateur Crate"

local UserInputService = game:GetService("UserInputService")
local flying = false
local CFloop = nil

local espBoxes = {}

local function getBoundingBox(character)
    local primaryPart = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
    if not primaryPart then return nil end
    
    local min, max = character:GetBoundingBox()
    return min, max
end

local function createESPBox(player)
    -- Entire function removed
end

local function updateBoxESP()
    -- Entire function removed
end

local function updateWalkSpeed()
    while true do
        task.wait(0.1)
        if local_player.Character then
            local humanoid = local_player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = _G.WalkSpeed or 16
            end
        end
    end
end

local function toggleCFrameFly()
    if not _G.EnableFly then return end
    
    flying = not flying
    local character = local_player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:WaitForChild("Head")
    
    if not humanoid or not head then return end
    
    if flying then
        humanoid.PlatformStand = true
        head.Anchored = true
        
        if CFloop then CFloop:Disconnect() end
        CFloop = run_service.Heartbeat:Connect(function(deltaTime)
            local moveDirection = humanoid.MoveDirection * (_G.CFspeed * deltaTime)
            local headCFrame = head.CFrame
            local cameraCFrame = workspace.CurrentCamera.CFrame
            
            local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
            cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
            
            local cameraPosition = cameraCFrame.Position
            local headPosition = headCFrame.Position

            local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
            head.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
        end)
    else
        if CFloop then
            CFloop:Disconnect()
            humanoid.PlatformStand = false
            head.Anchored = false
        end
    end
end

local function flyMovement()
    -- Keep this function for potential future use or compatibility
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        toggleCFrameFly()
    end
end)

task.spawn(updateWalkSpeed)

Tabs.Main:AddToggle("AimbotToggle", { Title = "Enable Aimbot", Default = false }):OnChanged(function()
    _G.EnableAimbot = Options.AimbotToggle.Value
end)

Tabs.Main:AddToggle("SpinBotToggle", { Title = "Enable SpinBot", Default = false }):OnChanged(function()
    _G.EnableSpinBot = Options.SpinBotToggle.Value
end)

Tabs.Main:AddToggle("FlyToggle", { Title = "Enable Fly", Default = false }):OnChanged(function()
    _G.EnableFly = Options.FlyToggle.Value
    
    -- Disable fly if toggle is turned off
    if not _G.EnableFly and flying then
        toggleCFrameFly()
    end
end)

Tabs.Main:AddToggle("ESPToggle", { Title = "ESP", Default = false }):OnChanged(function()
    _G.EnableESP = Options.ESPToggle.Value
    updateBoxESP()
end)

Tabs.Main:AddToggle("AutoKillToggle", { Title = "Auto Kill", Default = false }):OnChanged(function()
    _G.EnableAutoKill = Options.AutoKillToggle.Value
end)

Tabs.Main:AddSlider("WalkSpeedSlider", {
    Title = "WalkSpeed",
    Description = "Adjust WalkSpeed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        _G.WalkSpeed = Value
    end
})

Tabs.Main:AddSlider("FlySpeedSlider", {
    Title = "Fly Speed",
    Description = "Adjust Fly Speed",
    Default = 50,
    Min = 0,
    Max = 200,
    Rounding = 1,
    Callback = function(Value)
        _G.CFspeed = Value
    end
})

-- Addons:
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("RealScriptHub")
SaveManager:SetFolder("RealScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Real Script",
    Content = "The script has been loaded.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()

-- Main
local function damage_player(character)
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not character or not head or not humanoid then
        return
    end

    local local_character = local_player.Character

    if not local_character or not local_character:FindFirstChild("Head") then
        return
    end

    local origin_position = local_character.Head.Position
    local direction = (head.Position - origin_position).Unit

    damage:FireServer(humanoid, head.Name, origin_position, direction, head)
end

local function get_target()
    local closest, closest_distance = nil, 300

    for _, player in players:GetPlayers() do
        local character = player.Character
        local local_character = local_player.Character

        if player == local_player or player.Team == local_player.Team then
            continue
        end

        if not character or not local_character then
            continue
        end

        local root_part = character:FindFirstChild("HumanoidRootPart")

        if not root_part then
            continue
        end

        local humanoid = character:FindFirstChildWhichIsA("Humanoid")

        if not humanoid or humanoid.Health == 0 then
            continue
        end

        local distance = (root_part.Position - local_character.HumanoidRootPart.Position).Magnitude

        if distance > closest_distance then
            continue
        end

        local ray = Ray.new(local_character.HumanoidRootPart.Position, (root_part.Position - local_character.HumanoidRootPart.Position).Unit * distance)
        local hit_scan = find_part_on_ray(workspace, ray, {local_player.Character, workspace.CurrentCamera}, false, false)

        if not hit_scan or not hit_scan:IsDescendantOf(character) then
            continue
        end

        closest = player
        closest_distance = distance
    end

    return closest
end

run_service.RenderStepped:Connect(function()
    if _G.EnableSpinBot then
        local_player.Character.HumanoidRootPart.CFrame = local_player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(10), 0)
    end

    if _G.EnableAimbot then
        local target = get_target()
        if target then
            damage_player(target.Character)
        end
    end
end)

run_service.Heartbeat:Connect(flyMovement)

-- Handle player removal
players.PlayerRemoving:Connect(function(player)
    -- Removed old ESP connection
end)

local Settings = {
    Box_Color = Color3.fromRGB(255, 0, 0),
    Tracer_Color = Color3.fromRGB(255, 0, 0),
    Tracer_Thickness = 1,
    Box_Thickness = 1,
    Tracer_Origin = "Bottom", -- Middle or Bottom if FollowMouse is on this won't matter...
    Tracer_FollowMouse = false,
    Tracers = true
}

local Team_Check = {
    TeamCheck = false,
    Green = Color3.fromRGB(0, 255, 0),
    Red = Color3.fromRGB(255, 0, 0)
}

local TeamColor = true

local function NewQuad(thickness, color)
    local quad = Drawing.new("Quad")
    quad.Visible = false
    quad.PointA = Vector2.new(0,0)
    quad.PointB = Vector2.new(0,0)
    quad.PointC = Vector2.new(0,0)
    quad.PointD = Vector2.new(0,0)
    quad.Color = color
    quad.Filled = false
    quad.Thickness = thickness
    quad.Transparency = 1
    return quad
end

local function NewLine(thickness, color)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color 
    line.Thickness = thickness
    line.Transparency = 1
    return line
end

local function Visibility(state, lib)
    for _, x in pairs(lib) do
        x.Visible = state
    end
end

local function ESP(plr)
    local library = {
        blacktracer = NewLine(Settings.Tracer_Thickness*2, Color3.fromRGB(0,0,0)),
        tracer = NewLine(Settings.Tracer_Thickness, Settings.Tracer_Color),
        black = NewQuad(Settings.Box_Thickness*2, Color3.fromRGB(0,0,0)),
        box = NewQuad(Settings.Box_Thickness, Settings.Box_Color),
        healthbar = NewLine(3, Color3.fromRGB(0,0,0)),
        greenhealth = NewLine(1.5, Color3.fromRGB(0,0,0))
    }

    local function Colorize(color)
        for u, x in pairs(library) do
            if x ~= library.healthbar and x ~= library.greenhealth and x ~= library.blacktracer and x ~= library.black then
                x.Color = color
            end
        end
    end

    local function Updater()
        local connection
        connection = run_service.RenderStepped:Connect(function()
            if not _G.EnableESP then
                Visibility(false, library)
                return
            end

            if plr.Character and plr.Character:FindFirstChild("Humanoid") and 
               plr.Character:FindFirstChild("HumanoidRootPart") and 
               plr.Character.Humanoid.Health > 0 and 
               plr.Character:FindFirstChild("Head") then
                
                local localCharacter = local_player.Character
                if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
                    Visibility(false, library)
                    return
                end

                -- Distance check
                local distance = (plr.Character.HumanoidRootPart.Position - localCharacter.HumanoidRootPart.Position).Magnitude
                if distance > 300 then
                    Visibility(false, library)
                    return
                end
                
                local HumPos, OnScreen = workspace.CurrentCamera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                if OnScreen then
                    local head = workspace.CurrentCamera:WorldToViewportPoint(plr.Character.Head.Position)
                    local DistanceY = math.clamp((Vector2.new(head.X, head.Y) - Vector2.new(HumPos.X, HumPos.Y)).magnitude, 2, math.huge)
                    
                    local function Size(item)
                        item.PointA = Vector2.new(HumPos.X + DistanceY, HumPos.Y - DistanceY*2)
                        item.PointB = Vector2.new(HumPos.X - DistanceY, HumPos.Y - DistanceY*2)
                        item.PointC = Vector2.new(HumPos.X - DistanceY, HumPos.Y + DistanceY*2)
                        item.PointD = Vector2.new(HumPos.X + DistanceY, HumPos.Y + DistanceY*2)
                    end
                    Size(library.box)
                    Size(library.black)

                    if Settings.Tracers then
                        if Settings.Tracer_Origin == "Middle" then
                            library.tracer.From = workspace.CurrentCamera.ViewportSize*0.5
                            library.blacktracer.From = workspace.CurrentCamera.ViewportSize*0.5
                        elseif Settings.Tracer_Origin == "Bottom" then
                            library.tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X*0.5, workspace.CurrentCamera.ViewportSize.Y) 
                            library.blacktracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X*0.5, workspace.CurrentCamera.ViewportSize.Y)
                        end
                        
                        library.tracer.To = Vector2.new(HumPos.X, HumPos.Y + DistanceY*2)
                        library.blacktracer.To = Vector2.new(HumPos.X, HumPos.Y + DistanceY*2)
                    else 
                        library.tracer.From = Vector2.new(0, 0)
                        library.blacktracer.From = Vector2.new(0, 0)
                        library.tracer.To = Vector2.new(0, 0)
                        library.blacktracer.To = Vector2.new(0, 0)
                    end

                    local d = (Vector2.new(HumPos.X - DistanceY, HumPos.Y - DistanceY*2) - Vector2.new(HumPos.X - DistanceY, HumPos.Y + DistanceY*2)).magnitude 
                    local healthoffset = plr.Character.Humanoid.Health/plr.Character.Humanoid.MaxHealth * d

                    library.greenhealth.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY*2)
                    library.greenhealth.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY*2 - healthoffset)

                    library.healthbar.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY*2)
                    library.healthbar.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y - DistanceY*2)

                    local green = Color3.fromRGB(0, 255, 0)
                    local red = Color3.fromRGB(255, 0, 0)

                    library.greenhealth.Color = red:lerp(green, plr.Character.Humanoid.Health/plr.Character.Humanoid.MaxHealth)

                    if Team_Check.TeamCheck then
                        if plr.TeamColor == local_player.TeamColor then
                            Colorize(Team_Check.Green)
                        else 
                            Colorize(Team_Check.Red)
                        end
                    else 
                        library.tracer.Color = Settings.Tracer_Color
                        library.box.Color = Settings.Box_Color
                    end
                    
                    if TeamColor then
                        Colorize(plr.TeamColor.Color)
                    end
                    
                    Visibility(true, library)
                else 
                    Visibility(false, library)
                end
            else 
                Visibility(false, library)
            end
        end)
    end
    coroutine.wrap(Updater)()
end

-- Initialize ESP for existing players
for _, v in pairs(players:GetPlayers()) do
    if v.Name ~= local_player.Name then
        coroutine.wrap(ESP)(v)
    end
end

-- Handle new players
players.PlayerAdded:Connect(function(newplr)
    if newplr.Name ~= local_player.Name then
        coroutine.wrap(ESP)(newplr)
    end
end)

-- Auto Kill Feature
local firstGameDetection = true
local previousPlayerCount = 0

local function determineTeamAndTarget()
    local localPlayerName = local_player.Name
    local leaderboardGui = local_player.PlayerGui.LeaderboardGui.MainFrame
    
    local teamAPlayers = leaderboardGui["A_Players"]
    local teamBPlayers = leaderboardGui["B_Players"]
    
    local localPlayerInA = false
    local localPlayerInB = false
    local enemyTeamPlayers = {}
    
    -- Count total players
    local totalPlayerCount = 0
    for _, child in pairs(teamAPlayers:GetChildren()) do
        if child.Name ~= "UIListLayout" then
            totalPlayerCount = totalPlayerCount + 1
        end
    end
    for _, child in pairs(teamBPlayers:GetChildren()) do
        if child.Name ~= "UIListLayout" then
            totalPlayerCount = totalPlayerCount + 1
        end
    end
    
    -- Check if player list has changed
    if totalPlayerCount ~= previousPlayerCount then
        firstGameDetection = true
        previousPlayerCount = totalPlayerCount
    end
    
    print("Local Player Name: " .. localPlayerName)
    print("A Team Players:")
    for _, child in pairs(teamAPlayers:GetChildren()) do
        if child.Name == "UIListLayout" then continue end
        print(child.Name)
        if child.Name == localPlayerName then
            localPlayerInA = true
        end
    end
    
    print("B Team Players:")
    for _, child in pairs(teamBPlayers:GetChildren()) do
        if child.Name == "UIListLayout" then continue end
        print(child.Name)
        if child.Name == localPlayerName then
            localPlayerInB = true
        end
    end
    
    -- Collect enemy team players
    if localPlayerInA then
        for _, child in pairs(teamBPlayers:GetChildren()) do
            if child.Name == "UIListLayout" then continue end
            table.insert(enemyTeamPlayers, child.Name)
        end
        print("Local player is in Team A, targeting Team B")
    elseif localPlayerInB then
        for _, child in pairs(teamAPlayers:GetChildren()) do
            if child.Name == "UIListLayout" then continue end
            table.insert(enemyTeamPlayers, child.Name)
        end
        print("Local player is in Team B, targeting Team A")
    else
        print("Local player not found in either team!")
    end
    
    print("Enemy Players:")
    for _, name in ipairs(enemyTeamPlayers) do
        print(name)
    end
    
    return enemyTeamPlayers
end

local function autoKillTarget()
    if not _G.EnableAutoKill then return end
    
    local enemyPlayers = determineTeamAndTarget()
    
    if #enemyPlayers == 0 then 
        print("No enemy players found")
        return 
    end
    
    -- First game detection, wait 7 seconds
    if firstGameDetection then
        firstGameDetection = false
        print("First game detection, waiting 7 seconds")
        task.wait(8)
    end
    
    local validEnemyFound = false
    
    for _, enemyName in ipairs(enemyPlayers) do
        local enemyPlayer = players:FindFirstChild(enemyName)
        
        if enemyPlayer and enemyPlayer.Character and enemyPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local enemyHumanoid = enemyPlayer.Character:FindFirstChild("Humanoid")
            
            if enemyHumanoid and enemyHumanoid.Health > 0 then
                print("Found valid enemy: " .. enemyName)
                validEnemyFound = true
                local enemyRootPart = enemyPlayer.Character.HumanoidRootPart
                local localCharacter = local_player.Character
                
                if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then 
                    print("Local character not ready")
                    return 
                end
                
                -- More efficient tracking
                local behindOffset = enemyRootPart.CFrame * CFrame.new(0, 0, -2)
                localCharacter:SetPrimaryPartCFrame(behindOffset)
                
                break  -- Target first valid enemy
            end
        end
    end
    
    if not validEnemyFound then
        print("No valid enemy found")
        return
    end
end

-- Periodic team and target check with reduced frequency
local lastAutoKillCheck = 0
run_service.Heartbeat:Connect(function()
    if _G.EnableAutoKill then
        local currentTime = tick()
        if currentTime - lastAutoKillCheck >= 2 then 
            autoKillTarget()
            lastAutoKillCheck = currentTime
        end
    end
end)

Tabs.Market:AddDropdown("CrateSelector", {
    Title = "Select Crate",
    Description = "Choose which crate to auto-buy",
    Values = {
        "Amateur Crate",
        "Briefcase Crate", 
        "Holster Crate", 
        "Novice Crate", 
        "Keeper Crate", 
        "Advanced Crate"
    },
    Default = "Amateur Crate",
    Callback = function(Value)
        _G.SelectedCrate = Value
    end
})

Tabs.Market:AddToggle("AutoBuyToggle", {
    Title = "Auto Buy",
    Description = "Automatically buy selected crate every 5 seconds",
    Default = false
}):OnChanged(function()
    _G.EnableAutoBuy = Options.AutoBuyToggle.Value
end)

local function autoBuyCrate()
    if not _G.EnableAutoBuy then return end
    
    local cratePurchaseRemote = game:GetService("ReplicatedStorage").Remotes.PlayerData.PurchaseCrate
    
    local success, result = pcall(function()
        cratePurchaseRemote:InvokeServer(_G.SelectedCrate, "shop")
    end)
    
    if not success then
        warn("Auto Buy failed: " .. tostring(result))
    end
end

run_service.Heartbeat:Connect(function()
    if _G.EnableAutoBuy then
        local currentTime = tick()
        if currentTime - (getgenv().lastAutoBuyCheck or 0) >= 5 then
            autoBuyCrate()
            getgenv().lastAutoBuyCheck = currentTime
        end
    end
end)
