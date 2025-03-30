local Settings = {
    AntiAFK = true,
    AutoRejoin = true,
    Autofarm = true,
    Mode = "xp",
    AntiCheatBypass = true,
    AutoFish = {
        Enabled = true,
        AutoReel = true,
        AutoCast = true,
        InstantReel = true,
        PerfectReel = true
    }
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local CurrentTool = nil
local Progress = false
local Finished = false
local Rod = nil
local LastCastTime = 0

local function WaitForPath(Instance, Path)
    local PathParts = typeof(Path) == "string" and Path:split(".") or Path
    local Current = Instance
    
    for _, Name in ipairs(PathParts) do
        Current = Current:WaitForChild(Name)
    end
    
    return Current
end

local Remotes = {
    ReelFinished = WaitForPath(ReplicatedStorage, {"events", "reelfinished"}),
    GetSettings = WaitForPath(ReplicatedStorage, {"events", "getsettings"})
}

local XP_FARM_CFRAME = CFrame.new(-4285.89746, -11222.7461, 1741.78223, 0.155923501, -0.00169874448, 0.987767577, -0.000464356388, 0.999998331, 0.00179307954, -0.987768948, -0.000738260453, 0.155922428)

local NO_HOOKING = not (hookfunction and hookmetamethod)
if NO_HOOKING then
    hookfunction = function(...) end
    hookmetamethod = function(...) end
end

if not getconnections then
    getconnections = function(...) end
end

if not setthreadidentity then
    setthreadidentity = function(...) end
end

local Utility = {blacklisted_attachments = {"bob", "bodyweld"}}

function Utility.simulate_click(x, y, mb)
    VirtualInputManager:SendMouseButtonEvent(x, y, (mb - 1), true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(x, y, (mb - 1), false, game, 1)
end

function Utility.move_fix(bobber)
    if not bobber then return end

    local handle = bobber:FindFirstChild("Handle")
    if handle then
        handle.CanCollide = false
        handle.Massless = true
        
        for _, attachment in ipairs(handle:GetChildren()) do
            if attachment:IsA("Attachment") then
                attachment.Visible = false
                
                for _, constraint in ipairs(attachment:GetChildren()) do
                    if constraint:IsA("Constraint") then
                        constraint.Enabled = false
                    end
                end
            end
        end
    end

    local line = bobber:FindFirstChild("line")
    if line and line:IsA("Beam") then
        line.Enabled = true
        line.Width0 = 0.05
        line.Width1 = 0.05
        line.FaceCamera = true
    end
end

local Farm = {reel_tick = nil}

function Farm.cast_rod()
    if not Rod then return end
    
    if (tick() - LastCastTime) > 4 and Progress then
        Progress = false
        Finished = false
        Rod.events.reset:FireServer()
        task.wait(0.5)
    end
    
    if not Progress then
        Progress = true
        LastCastTime = tick()
        Rod.events.reset:FireServer()
        task.wait(0.5)
        Rod.events.cast:FireServer(math.random(97, 100))
    end

    local bobber = Rod:FindFirstChild("bobber")
    if bobber then
        Utility.move_fix(bobber)
    end
end

function Farm.shake()
    local shake_ui = PlayerGui:FindFirstChild("shakeui")
    if not shake_ui then return end
    
    local safezone = shake_ui:FindFirstChild("safezone")
    local button = safezone and safezone:FindFirstChild("button")
    if not button then return end

    Utility.simulate_click(
        button.AbsolutePosition.X + (button.AbsoluteSize.X / 2), 
        button.AbsolutePosition.Y + (button.AbsoluteSize.Y / 2), 
        1
    )
end

function Farm.reel()
    local reel_ui = PlayerGui:FindFirstChild("reel")
    if not reel_ui then return end

    local reel_bar = reel_ui:FindFirstChild("bar")
    if not reel_bar then return end
    
    local reel_client = reel_bar:FindFirstChild("reel")
    if not reel_client then return end

    local playerbar = reel_bar:WaitForChild("playerbar", 1)
    if playerbar then
        Finished = true
        playerbar:GetPropertyChangedSignal("Position"):Wait()
        Remotes.ReelFinished:FireServer(100, true)
    end
end

PlayerGui.DescendantAdded:Connect(function(Descendant)
    if Settings.AutoFish.Enabled then
        if Descendant.Name == "playerbar" and Descendant.Parent.Name == "bar" then
            Finished = true
            Descendant:GetPropertyChangedSignal("Position"):Wait()
            Remotes.ReelFinished:FireServer(100, true)
        end
    end
end)

PlayerGui.DescendantRemoving:Connect(function(Descendant)
    if Descendant.Name == "reel" then
        Finished = false
        Progress = false
    end
end)

LocalPlayer.Character.ChildAdded:Connect(function(Child)
    if Child:IsA("Tool") and Child.Name:lower():find("rod") then
        Rod = Child
        CurrentTool = Child
    end
end)

LocalPlayer.Character.ChildRemoved:Connect(function(Child)
    if Child == Rod then
        Settings.AutoFish.Enabled = false
        Finished = false
        Progress = false
        Rod = nil
        CurrentTool = nil
    end
end)

local current_rod = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
if current_rod and current_rod.Name:lower():find("rod") then
    Rod = current_rod
    CurrentTool = current_rod
end

local function setupAntiCheatBypass()
    if not Settings.AntiCheatBypass then return end

    if getgenv().sasware_fisch_unload then
        pcall(getgenv().sasware_fisch_unload)
        getgenv().sasware_fisch_unload = nil
    end

    local Success, Error = pcall(function()
        local BYPASS_SUBVERSION = "Full-Emulationv2"
        local NaughtyNaughty = "RemoveLoadingScreen"
        local ACFlags = 0

        local ExcludedServices = {
            "ScriptContext",
            "RobloxReplicatedStorage",
            "ReplicatedStorage",
            "StarterGui",
            "Players",
            "Workspace",
        }

        local function Unload()
            if getreg and hookfunction then
                pcall(function()
                    for _, Object in next, getgc() do
                        if type(Object) == "function" and islclosure and islclosure(Object) and not isexecutorclosure(Object) then
                            local Success, Source = pcall(function() return debug.info(Object, "s") end)
                            if Success and Source and Source:find(NaughtyNaughty) then
                                hookfunction(Object, function() end)
                            end
                        end
                    end
                end)
            end
            getgenv().sasware_fisch_unload = nil
        end
        getgenv().sasware_fisch_unload = Unload

        if getreg and hookfunction and isexecutorclosure and getgc then
            local function AssertFunction(v)
                return type(v) == "function" and islclosure and islclosure(v) and not isexecutorclosure(v)
            end

            pcall(function()
                for _, Object in next, getgc() do
                    if AssertFunction(Object) then
                        local Success, Source = pcall(function() return debug.info(Object, "s") end)
                        if Success and Source and Source:find(NaughtyNaughty) then
                            ACFlags += 1
                            hookfunction(Object, LPH_NO_UPVALUES(function() end))
                        end
                    end
                end
            end)

            pcall(function()
                for _, Object in next, getreg() do
                    if type(Object) == "thread" then
                        local Success, Source = pcall(function() return debug.info(Object, 1, "s") end)
                        if Success and Source and Source:find(NaughtyNaughty) then
                            ACFlags += 1
                            coroutine.close(Object)
                        end
                    end
                end
            end)
        else
            BYPASS_SUBVERSION = "Only-Emulationv2"
            if getnilinstances then
                BYPASS_SUBVERSION = "AltKill-Emulatedv2"

                pcall(function()
                    local NilInstances = getnilinstances()
                    for _, NilInstance in next, NilInstances do
                        if NilInstance:IsA("LuaSourceContainer") and NilInstance.Name:find("Loading") then
                            ACFlags += 1
                            NilInstance:Destroy()
                        end
                    end
                end)
            end

            pcall(function()
                for _, Service in next, game:GetChildren() do
                    if table.find(ExcludedServices, Service.Name) then
                        continue
                    end

                    for _, Child in next, Service:GetChildren() do
                        if Child:IsA("RemoteEvent") then
                            local Name = Child.Name
                            local Swap = Instance.new("UnreliableRemoteEvent")
                            Swap.Name = Name
                            Swap.Parent = Service
                            Child:Destroy()
                        end
                    end
                end
            end)
        end

        local HandshakeEmulated = LPH_NO_VIRTUALIZE(function(...)
            return task.wait(9e9)
        end)

        if Remotes.GetSettings then
            Remotes.GetSettings.OnClientInvoke = HandshakeEmulated
        else
            warn("Failed to find getsettings remote")
        end
    end)

    if not Success then
        warn("Anti-cheat bypass error:", Error)
        return false
    end

    return true
end

local function setupAntiAFK()
    if not Settings.AntiAFK then return end
    
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function setupAutoRejoin()
    if not Settings.AutoRejoin then return end
    
    local CoreGui = game:GetService("CoreGui")
    local TeleportService = game:GetService("TeleportService")
    
    CoreGui:WaitForChild('RobloxPromptGui').promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == 'ErrorPrompt' then
            repeat
                TeleportService:Teleport(game.PlaceId)
                wait(2)
            until false
        end
    end)
end

task.spawn(function()
    repeat task.wait() until CoreGui:FindFirstChild('RobloxPromptGui')
    local prompt_overlay = CoreGui.RobloxPromptGui.promptOverlay

    prompt_overlay.ChildAdded:Connect(function(child)
        if child.Name == 'ErrorPrompt' then
            repeat
                TeleportService:Teleport(game.PlaceId)
                task.wait(2)
            until false
        end
    end)
end)

local function startPositionLock()
    task.spawn(function()
        while Settings.AutoFish.Enabled do
            if LocalPlayer.Character then
                LocalPlayer.Character:PivotTo(XP_FARM_CFRAME)
                
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = 0
                    humanoid.JumpPower = 0
                end
            end
            task.wait(1)
        end
    end)
end

local function startFishing()
    if not Settings.AutoFish.Enabled then return end
    
    Progress = false
    Finished = false
    LastCastTime = 0
    
    startPositionLock()
    
    task.spawn(function()
        while task.wait(0.1) do
            if not Settings.AutoFish.Enabled then break end
            
            pcall(function()
                if not Rod or not Rod.Parent then
                    local found_rod = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                    if found_rod and found_rod.Name:lower():find("rod") then
                        Rod = found_rod
                        Progress = false
                        Finished = false
                    end
                end
                
                Farm.cast_rod()
                Farm.shake()
                Farm.reel()
            end)
        end
    end)
end

local function startAutofarm()
    if not Settings.Autofarm then return end
    
    LocalPlayer.Character:PivotTo(XP_FARM_CFRAME)
    
    startFishing()
end

task.spawn(function()
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    
    task.wait(1)
    
    if Settings.AntiCheatBypass then
        setupAntiCheatBypass()
    end
    
    if Settings.AntiAFK then
        setupAntiAFK()
    end
    
    if Settings.AutoRejoin then
        setupAutoRejoin()
    end
    
    if Settings.Autofarm then
        startAutofarm()
    else
        startFishing() 
    end
end)
