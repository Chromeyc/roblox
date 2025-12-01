local Lumania = {}
Lumania.__index = Lumania

-- Global Tables for SaveManager
getgenv().Toggles = {}
getgenv().Options = {}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Constants & Theme
local THEME = {
    Background = Color3.fromRGB(15, 15, 20),
    Secondary = Color3.fromRGB(25, 25, 30),
    Tertiary = Color3.fromRGB(35, 35, 40),
    Accent = Color3.fromRGB(138, 92, 246), -- Purple
    AccentGradient = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 92, 246)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 50, 200))
    },
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 160),
    Border = Color3.fromRGB(50, 50, 60),
    Success = Color3.fromRGB(74, 222, 128),
    Error = Color3.fromRGB(248, 113, 113),
}

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Utility Functions
local function Create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

local function ApplyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = instance
    return corner
end

local function ApplyStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or THEME.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = instance
    return stroke
end

local function ApplyGradient(instance)
    local gradient = Instance.new("UIGradient")
    gradient.Color = THEME.AccentGradient
    gradient.Parent = instance
    return gradient
end

local function MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        TweenService:Create(object, TweenInfo.new(0.15), {Position = pos}):Play()
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

-- Main Library
function Lumania:CreateWindow(config)
    local Window = {}
    
    -- Protect GUI
    local ScreenGui = Create("ScreenGui", {
        Name = "LumaniaUI",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    -- Main Frame
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = THEME.Background,
        Position = UDim2.new(0.5, -325, 0.5, -225),
        Size = UDim2.new(0, 650, 0, 450),
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    ApplyCorner(MainFrame, 10)
    ApplyStroke(MainFrame, THEME.Border, 1)

    -- Top Bar
    local TopBar = Create("Frame", {
        Name = "TopBar",
        Parent = MainFrame,
        BackgroundColor3 = THEME.Secondary,
        Size = UDim2.new(1, 0, 0, 45),
        BorderSizePixel = 0
    })
    
    local Title = Create("TextLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = config.Title or "Lumania",
        TextColor3 = THEME.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local Subtitle = Create("TextLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, Title.TextBounds.X + 25, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Font = Enum.Font.Gotham,
        Text = config.Subtitle or "Premium Hub",
        TextColor3 = THEME.TextDim,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Notification Container
    local NotificationContainer = Create("Frame", {
        Name = "Notifications",
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -320, 0, 20),
        Size = UDim2.new(0, 300, 1, -40),
        ZIndex = 100
    })
    
    local NotificationLayout = Create("UIListLayout", {
        Parent = NotificationContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        VerticalAlignment = Enum.VerticalAlignment.Top
    })

    function Window:Notify(text, duration)
        local Notif = Create("Frame", {
            Parent = NotificationContainer,
            BackgroundColor3 = THEME.Secondary,
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundTransparency = 1
        })
        ApplyCorner(Notif, 8)
        ApplyStroke(Notif, THEME.Border, 1)

        local NotifLabel = Create("TextLabel", {
            Parent = Notif,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 15, 0, 0),
            Size = UDim2.new(1, -30, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = text,
            TextColor3 = THEME.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true
        })

        local Bar = Create("Frame", {
            Parent = Notif,
            BackgroundColor3 = THEME.Accent,
            Position = UDim2.new(0, 0, 1, -2),
            Size = UDim2.new(0, 0, 0, 2)
        })

        TweenService:Create(Notif, TWEEN_INFO, {BackgroundTransparency = 0}):Play()
        TweenService:Create(Bar, TweenInfo.new(duration or 3), {Size = UDim2.new(1, 0, 0, 2)}):Play()

        task.delay(duration or 3, function()
            TweenService:Create(Notif, TWEEN_INFO, {BackgroundTransparency = 1}):Play()
            TweenService:Create(NotifLabel, TWEEN_INFO, {TextTransparency = 1}):Play()
            task.wait(0.3)
            Notif:Destroy()
        end)
    end

    MakeDraggable(TopBar, MainFrame)

    -- Tab Container
    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 60),
        Size = UDim2.new(0, 150, 1, -75),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    
    local TabListLayout = Create("UIListLayout", {
        Parent = TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })

    -- Content Area
    local ContentArea = Create("Frame", {
        Name = "ContentArea",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 180, 0, 60),
        Size = UDim2.new(1, -195, 1, -75)
    })

    local FirstTab = true

    function Window:AddTab(name)
        local Tab = {}
        
        -- Tab Button
        local TabButton = Create("TextButton", {
            Parent = TabContainer,
            BackgroundColor3 = THEME.Secondary,
            Size = UDim2.new(1, 0, 0, 40),
            AutoButtonColor = false,
            Font = Enum.Font.GothamMedium,
            Text = name,
            TextColor3 = THEME.TextDim,
            TextSize = 14
        })
        ApplyCorner(TabButton, 8)

        local TabPage = Create("ScrollingFrame", {
            Name = name .. "Page",
            Parent = ContentArea,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = THEME.Accent,
            Visible = false,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        })

        -- Layout for Groupboxes (Left/Right columns)
        local LeftColumn = Create("Frame", {
            Name = "LeftColumn",
            Parent = TabPage,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0.5, -5, 1, 0)
        })
        
        local RightColumn = Create("Frame", {
            Name = "RightColumn",
            Parent = TabPage,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 5, 0, 0),
            Size = UDim2.new(0.5, -5, 1, 0)
        })

        local function CreateColumnLayout(parent)
            local layout = Create("UIListLayout", {
                Parent = parent,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10)
            })
            return layout
        end

        local LeftLayout = CreateColumnLayout(LeftColumn)
        local RightLayout = CreateColumnLayout(RightColumn)

        -- Tab Selection
        local function Activate()
            for _, v in pairs(ContentArea:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible = false end
            end
            for _, v in pairs(TabContainer:GetChildren()) do
                if v:IsA("TextButton") then
                    TweenService:Create(v, TWEEN_INFO, {BackgroundColor3 = THEME.Secondary, TextColor3 = THEME.TextDim}):Play()
                end
            end
            
            TabPage.Visible = true
            TweenService:Create(TabButton, TWEEN_INFO, {BackgroundColor3 = THEME.Tertiary, TextColor3 = THEME.Text}):Play()
        end

        TabButton.MouseButton1Click:Connect(Activate)

        if FirstTab then
            FirstTab = false
            Activate()
        end

        -- Groupbox System
        function Tab:AddGroupbox(title, side)
            local Groupbox = {}
            local ParentColumn = (side == "right") and RightColumn or LeftColumn
            
            local BoxFrame = Create("Frame", {
                Name = title .. "Groupbox",
                Parent = ParentColumn,
                BackgroundColor3 = THEME.Secondary,
                Size = UDim2.new(1, 0, 0, 0), -- Auto size
                AutomaticSize = Enum.AutomaticSize.Y
            })
            ApplyCorner(BoxFrame, 8)
            ApplyStroke(BoxFrame, THEME.Border, 1)

            local BoxTitle = Create("TextLabel", {
                Parent = BoxFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -20, 0, 30),
                Font = Enum.Font.GothamBold,
                Text = title,
                TextColor3 = THEME.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Container = Create("Frame", {
                Parent = BoxFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 35),
                Size = UDim2.new(1, -20, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })

            local BoxLayout = Create("UIListLayout", {
                Parent = Container,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10)
            })
            
            local BoxPadding = Create("UIPadding", {
                Parent = Container,
                PaddingBottom = UDim.new(0, 10)
            })

            -- Components
            function Groupbox:AddToggle(idx, config)
                local Toggle = { Type = "Toggle", Value = config.Default or false }
                
                local Frame = Create("Frame", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20)
                })

                local Label = Create("TextLabel", {
                    Parent = Frame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -45, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = config.Text,
                    TextColor3 = THEME.TextDim,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Switch = Create("Frame", {
                    Parent = Frame,
                    BackgroundColor3 = THEME.Tertiary,
                    Position = UDim2.new(1, -40, 0.5, -10),
                    Size = UDim2.new(0, 40, 0, 20)
                })
                ApplyCorner(Switch, 10)
                
                local Knob = Create("Frame", {
                    Parent = Switch,
                    BackgroundColor3 = THEME.TextDim,
                    Position = UDim2.new(0, 2, 0.5, -8),
                    Size = UDim2.new(0, 16, 0, 16)
                })
                ApplyCorner(Knob, 8)

                local Button = Create("TextButton", {
                    Parent = Frame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })

                function Toggle:SetValue(val)
                    Toggle.Value = val
                    if val then
                        TweenService:Create(Switch, TWEEN_INFO, {BackgroundColor3 = THEME.Accent}):Play()
                        TweenService:Create(Knob, TWEEN_INFO, {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Color3.new(1,1,1)}):Play()
                        Label.TextColor3 = THEME.Text
                    else
                        TweenService:Create(Switch, TWEEN_INFO, {BackgroundColor3 = THEME.Tertiary}):Play()
                        TweenService:Create(Knob, TWEEN_INFO, {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = THEME.TextDim}):Play()
                        Label.TextColor3 = THEME.TextDim
                    end
                    if config.Callback then config.Callback(val) end
                end

                Button.MouseButton1Click:Connect(function()
                    Toggle:SetValue(not Toggle.Value)
                end)

                Toggle:SetValue(Toggle.Value)
                Toggles[idx] = Toggle
                return Toggle
            end

            function Groupbox:AddSlider(idx, config)
                local Slider = { Type = "Slider", Value = config.Default or config.Min }
                
                local Frame = Create("Frame", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 45)
                })

                local Label = Create("TextLabel", {
                    Parent = Frame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = config.Text,
                    TextColor3 = THEME.TextDim,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local ValueLabel = Create("TextLabel", {
                    Parent = Frame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = tostring(Slider.Value),
                    TextColor3 = THEME.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right
                })

                local SlideBg = Create("Frame", {
                    Parent = Frame,
                    BackgroundColor3 = THEME.Tertiary,
                    Position = UDim2.new(0, 0, 0, 25),
                    Size = UDim2.new(1, 0, 0, 6)
                })
                ApplyCorner(SlideBg, 3)

                local Fill = Create("Frame", {
                    Parent = SlideBg,
                    BackgroundColor3 = THEME.Accent,
                    Size = UDim2.new(0, 0, 1, 0)
                })
                ApplyCorner(Fill, 3)

                local Button = Create("TextButton", {
                    Parent = SlideBg,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })

                local Min, Max = config.Min, config.Max

                function Slider:SetValue(val)
                    val = math.clamp(val, Min, Max)
                    Slider.Value = val
                    ValueLabel.Text = tostring(val)
                    
                    local percent = (val - Min) / (Max - Min)
                    TweenService:Create(Fill, TWEEN_INFO, {Size = UDim2.new(percent, 0, 1, 0)}):Play()
                    
                    if config.Callback then config.Callback(val) end
                end

                local function Update(input)
                    local pos = math.clamp((input.Position.X - SlideBg.AbsolutePosition.X) / SlideBg.AbsoluteSize.X, 0, 1)
                    local val = math.floor(Min + (Max - Min) * pos)
                    Slider:SetValue(val)
                end

                local Dragging = false
                Button.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = true
                        Update(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        Update(input)
                    end
                end)

                Slider:SetValue(Slider.Value)
                Options[idx] = Slider
                return Slider
            end

            function Groupbox:AddInput(idx, config)
                local Input = { Type = "Input", Value = "" }
                
                local Frame = Create("Frame", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 45)
                })

                local Label = Create("TextLabel", {
                    Parent = Frame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = config.Text,
                    TextColor3 = THEME.TextDim,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local BoxContainer = Create("Frame", {
                    Parent = Frame,
                    BackgroundColor3 = THEME.Tertiary,
                    Position = UDim2.new(0, 0, 0, 22),
                    Size = UDim2.new(1, 0, 0, 23)
                })
                ApplyCorner(BoxContainer, 4)
                local Stroke = ApplyStroke(BoxContainer, THEME.Border, 1)

                local Box = Create("TextBox", {
                    Parent = BoxContainer,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(1, -16, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = "",
                    PlaceholderText = "...",
                    TextColor3 = THEME.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false
                })

                function Input:SetValue(val)
                    Input.Value = val
                    Box.Text = val
                    if config.Callback then config.Callback(val) end
                end

                Box.FocusLost:Connect(function()
                    Input:SetValue(Box.Text)
                    TweenService:Create(Stroke, TWEEN_INFO, {Color = THEME.Border}):Play()
                end)

                Box.Focused:Connect(function()
                    TweenService:Create(Stroke, TWEEN_INFO, {Color = THEME.Accent}):Play()
                end)

                Options[idx] = Input
                return Input
            end

            function Groupbox:AddDropdown(idx, config)
                local Dropdown = { Type = "Dropdown", Value = nil, Multi = false }
                
                local Frame = Create("Frame", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 45),
                    ZIndex = 2
                })

                local Label = Create("TextLabel", {
                    Parent = Frame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = config.Text,
                    TextColor3 = THEME.TextDim,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local DropFrame = Create("Frame", {
                    Parent = Frame,
                    BackgroundColor3 = THEME.Tertiary,
                    Position = UDim2.new(0, 0, 0, 22),
                    Size = UDim2.new(1, 0, 0, 23)
                })
                ApplyCorner(DropFrame, 4)
                local Stroke = ApplyStroke(DropFrame, THEME.Border, 1)

                local SelectedLabel = Create("TextLabel", {
                    Parent = DropFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(1, -25, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = "None",
                    TextColor3 = THEME.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Arrow = Create("TextLabel", {
                    Parent = DropFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -20, 0, 0),
                    Size = UDim2.new(0, 20, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = "v",
                    TextColor3 = THEME.TextDim,
                    TextSize = 12
                })

                local List = Create("ScrollingFrame", {
                    Parent = DropFrame,
                    BackgroundColor3 = THEME.Tertiary,
                    Position = UDim2.new(0, 0, 1, 5),
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    ScrollBarThickness = 2,
                    ZIndex = 10
                })
                ApplyCorner(List, 4)
                ApplyStroke(List, THEME.Border, 1)

                local ListLayout = Create("UIListLayout", {
                    Parent = List,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2)
                })

                local IsOpen = false

                function Dropdown:SetValues(newValues)
                    config.Values = newValues or {}
                    if IsOpen then
                        -- Refresh list if open
                        Toggle() -- Close
                        Toggle() -- Re-open to refresh
                    end
                end

                function Dropdown:SetValue(val)
                    Dropdown.Value = val
                    SelectedLabel.Text = tostring(val)
                    if val == nil then SelectedLabel.Text = "None" end
                    if config.Callback then config.Callback(val) end
                end

                local function Toggle()
                    IsOpen = not IsOpen
                    List.Visible = IsOpen
                    if IsOpen then
                        -- Populate
                        for _, child in pairs(List:GetChildren()) do
                            if child:IsA("TextButton") then child:Destroy() end
                        end
                        
                        for _, val in pairs(config.Values or {}) do
                            local Btn = Create("TextButton", {
                                Parent = List,
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 0, 25),
                                Font = Enum.Font.Gotham,
                                Text = tostring(val),
                                TextColor3 = THEME.TextDim,
                                TextSize = 13
                            })
                            
                            Btn.MouseButton1Click:Connect(function()
                                Dropdown:SetValue(val)
                                Toggle()
                            end)
                        end
                        
                        local height = math.min(#(config.Values or {}) * 27, 150)
                        List.Size = UDim2.new(1, 0, 0, height)
                        List.CanvasSize = UDim2.new(0, 0, 0, #(config.Values or {}) * 27)
                    end
                end

                local Btn = Create("TextButton", {
                    Parent = DropFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })
                Btn.MouseButton1Click:Connect(Toggle)

                Options[idx] = Dropdown
                return Dropdown
            end

            function Groupbox:AddButton(text, callback)
                local Frame = Create("Frame", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30)
                })

                local Btn = Create("TextButton", {
                    Parent = Frame,
                    BackgroundColor3 = THEME.Tertiary,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = THEME.Text,
                    TextSize = 13,
                    AutoButtonColor = false
                })
                ApplyCorner(Btn, 4)
                ApplyStroke(Btn, THEME.Border, 1)

                Btn.MouseEnter:Connect(function()
                    TweenService:Create(Btn, TWEEN_INFO, {BackgroundColor3 = THEME.Secondary}):Play()
                end)
                Btn.MouseLeave:Connect(function()
                    TweenService:Create(Btn, TWEEN_INFO, {BackgroundColor3 = THEME.Tertiary}):Play()
                end)
                
                Btn.MouseButton1Click:Connect(callback)
                
                -- Support chaining (Side by Side)
                local ButtonObj = {}
                function ButtonObj:AddButton(text2, callback2)
                    -- Resize first button
                    Btn.Size = UDim2.new(0.5, -2, 1, 0)
                    
                    local Btn2 = Create("TextButton", {
                        Parent = Frame,
                        BackgroundColor3 = THEME.Tertiary,
                        Position = UDim2.new(0.5, 2, 0, 0),
                        Size = UDim2.new(0.5, -2, 1, 0),
                        Font = Enum.Font.Gotham,
                        Text = text2,
                        TextColor3 = THEME.Text,
                        TextSize = 13,
                        AutoButtonColor = false
                    })
                    ApplyCorner(Btn2, 4)
                    ApplyStroke(Btn2, THEME.Border, 1)

                    Btn2.MouseEnter:Connect(function()
                        TweenService:Create(Btn2, TWEEN_INFO, {BackgroundColor3 = THEME.Secondary}):Play()
                    end)
                    Btn2.MouseLeave:Connect(function()
                        TweenService:Create(Btn2, TWEEN_INFO, {BackgroundColor3 = THEME.Tertiary}):Play()
                    end)
                    
                    Btn2.MouseButton1Click:Connect(callback2)
                    
                    return ButtonObj
                end
                return ButtonObj
            end
            
            function Groupbox:AddLabel(text)
                local Label = Create("TextLabel", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = THEME.TextDim,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                return {
                    SetText = function(self, t) Label.Text = t end
                }
            end

            function Groupbox:AddDivider()
                local Div = Create("Frame", {
                    Parent = Container,
                    BackgroundColor3 = THEME.Border,
                    Size = UDim2.new(1, 0, 0, 1)
                })
            end

            return Groupbox
        end

        function Tab:AddLeftGroupbox(title)
            return Tab:AddGroupbox(title, "left")
        end

        function Tab:AddRightGroupbox(title)
            return Tab:AddGroupbox(title, "right")
        end

        return Tab
    end

    return Window
end

return Lumania
