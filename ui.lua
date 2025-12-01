local Lumania = {}
Lumania.__index = Lumania

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Constants & Theme
local THEME = {
    Background = Color3.fromRGB(18, 18, 24),
    Secondary = Color3.fromRGB(25, 25, 35),
    Accent = Color3.fromRGB(138, 92, 246),
    AccentHover = Color3.fromRGB(158, 112, 255),
    Text = Color3.fromRGB(245, 245, 250),
    TextDim = Color3.fromRGB(160, 160, 170),
    Border = Color3.fromRGB(45, 45, 55),
    Success = Color3.fromRGB(74, 222, 128),
    Error = Color3.fromRGB(248, 113, 113),
    Placeholder = Color3.fromRGB(100, 100, 110)
}

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Utility Functions
local function MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        local Tween = TweenService:Create(object, TweenInfo.new(0.15), {Position = pos})
        Tween:Play()
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

-- Main Library Functions
function Lumania:CreateWindow(config)
    local Window = {}
    local ConfigFolder = config.ConfigFolder or "LumaniaConfigs"
    local ConfigFile = ConfigFolder .. "/default.json"
    
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
        Position = UDim2.new(0.5, -300, 0.5, -200),
        Size = UDim2.new(0, 600, 0, 400),
        BorderSizePixel = 0
    })
    ApplyCorner(MainFrame, 8)
    ApplyStroke(MainFrame, THEME.Border, 1)

    -- Top Bar
    local TopBar = Create("Frame", {
        Name = "TopBar",
        Parent = MainFrame,
        BackgroundColor3 = THEME.Secondary,
        Size = UDim2.new(1, 0, 0, 40),
        BorderSizePixel = 0
    })
    ApplyCorner(TopBar, 8)
    
    -- Fix bottom corners of top bar
    local TopBarCover = Create("Frame", {
        Parent = TopBar,
        BackgroundColor3 = THEME.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        ZIndex = 1
    })

    local Title = Create("TextLabel", {
        Name = "Title",
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = config.Title or "Lumania",
        TextColor3 = THEME.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2
    })

    if config.Subtitle then
        local Subtitle = Create("TextLabel", {
            Name = "Subtitle",
            Parent = TopBar,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, Title.TextBounds.X + 20, 0, 0),
            Size = UDim2.new(0, 200, 1, 0),
            Font = Enum.Font.Gotham,
            Text = config.Subtitle,
            TextColor3 = THEME.TextDim,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2
        })
    end

    MakeDraggable(TopBar, MainFrame)

    -- Content Area
    local ContentArea = Create("Frame", {
        Name = "ContentArea",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 50),
        Size = UDim2.new(1, -170, 1, -60)
    })

    -- Tab Container
    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 50),
        Size = UDim2.new(0, 140, 1, -60),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    
    local TabListLayout = Create("UIListLayout", {
        Parent = TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })

    -- Config System
    Window.Config = {}
    
    function Window:SaveConfig(name)
        local json = HttpService:JSONEncode(Window.Config)
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        writefile(ConfigFolder .. "/" .. name .. ".json", json)
    end

    function Window:LoadConfig(name)
        if isfile(ConfigFolder .. "/" .. name .. ".json") then
            local json = readfile(ConfigFolder .. "/" .. name .. ".json")
            local data = HttpService:JSONDecode(json)
            
            for tabName, tabData in pairs(data) do
                for itemName, itemValue in pairs(tabData) do
                    if Window.Config[tabName] and Window.Config[tabName][itemName] then
                        -- Update value and trigger callback
                        local item = Window.Config[tabName][itemName]
                        if item.Set then
                            item.Set(itemValue)
                        end
                    end
                end
            end
        end
    end

    -- Tab System
    local FirstTab = true
    
    function Window:AddTab(name, icon)
        local Tab = {}
        
        -- Tab Button
        local TabButton = Create("TextButton", {
            Name = name .. "Tab",
            Parent = TabContainer,
            BackgroundColor3 = THEME.Secondary,
            Size = UDim2.new(1, 0, 0, 36),
            AutoButtonColor = false,
            Font = Enum.Font.GothamMedium,
            Text = "      " .. name,
            TextColor3 = THEME.TextDim,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        ApplyCorner(TabButton, 6)
        
        if icon then
            local IconLabel = Create("TextLabel", {
                Parent = TabButton,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(0, 20, 1, 0),
                Font = Enum.Font.Gotham,
                Text = icon,
                TextColor3 = THEME.TextDim,
                TextSize = 14
            })
        end

        -- Tab Page
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
        
        local PageLayout = Create("UIListLayout", {
            Parent = TabPage,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })
        
        local PagePadding = Create("UIPadding", {
            Parent = TabPage,
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 2)
        })

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)

        -- Tab Selection Logic
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
            TweenService:Create(TabButton, TWEEN_INFO, {BackgroundColor3 = THEME.Accent, TextColor3 = THEME.Text}):Play()
        end

        TabButton.MouseButton1Click:Connect(Activate)

        if FirstTab then
            FirstTab = false
            Activate()
        end
        
        -- Init Config for Tab
        Window.Config[name] = {}

        -- Components
        function Tab:AddButton(btnConfig)
            local ButtonFrame = Create("TextButton", {
                Name = btnConfig.Text .. "Button",
                Parent = TabPage,
                BackgroundColor3 = THEME.Secondary,
                Size = UDim2.new(1, 0, 0, 38),
                AutoButtonColor = false,
                Font = Enum.Font.GothamMedium,
                Text = btnConfig.Text,
                TextColor3 = THEME.Text,
                TextSize = 14
            })
            ApplyCorner(ButtonFrame, 6)
            ApplyStroke(ButtonFrame, THEME.Border, 1)

            ButtonFrame.MouseEnter:Connect(function()
                TweenService:Create(ButtonFrame, TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
            end)

            ButtonFrame.MouseLeave:Connect(function()
                TweenService:Create(ButtonFrame, TWEEN_INFO, {BackgroundColor3 = THEME.Secondary}):Play()
            end)

            ButtonFrame.MouseButton1Click:Connect(function()
                -- Ripple effect could go here
                if btnConfig.Callback then btnConfig.Callback() end
            end)
        end

        function Tab:AddToggle(toggleConfig)
            local ToggleFrame = Create("Frame", {
                Name = toggleConfig.Text .. "Toggle",
                Parent = TabPage,
                BackgroundColor3 = THEME.Secondary,
                Size = UDim2.new(1, 0, 0, 38)
            })
            ApplyCorner(ToggleFrame, 6)
            ApplyStroke(ToggleFrame, THEME.Border, 1)

            local Label = Create("TextLabel", {
                Parent = ToggleFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.7, 0, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = toggleConfig.Text,
                TextColor3 = THEME.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local SwitchBg = Create("Frame", {
                Parent = ToggleFrame,
                BackgroundColor3 = THEME.Background,
                Position = UDim2.new(1, -50, 0.5, -10),
                Size = UDim2.new(0, 38, 0, 20)
            })
            ApplyCorner(SwitchBg, 10)

            local SwitchKnob = Create("Frame", {
                Parent = SwitchBg,
                BackgroundColor3 = THEME.TextDim,
                Position = UDim2.new(0, 2, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16)
            })
            ApplyCorner(SwitchKnob, 8)

            local Toggled = toggleConfig.Default or false
            
            -- Config Registration
            Window.Config[name][toggleConfig.Text] = {
                Value = Toggled,
                Set = function(val)
                    Toggled = val
                    if Toggled then
                        TweenService:Create(SwitchBg, TWEEN_INFO, {BackgroundColor3 = THEME.Success}):Play()
                        TweenService:Create(SwitchKnob, TWEEN_INFO, {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Color3.new(1,1,1)}):Play()
                    else
                        TweenService:Create(SwitchBg, TWEEN_INFO, {BackgroundColor3 = THEME.Background}):Play()
                        TweenService:Create(SwitchKnob, TWEEN_INFO, {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = THEME.TextDim}):Play()
                    end
                    if toggleConfig.Callback then toggleConfig.Callback(Toggled) end
                    Window.Config[name][toggleConfig.Text].Value = Toggled
                end
            }

            -- Initial State
            if Toggled then
                SwitchBg.BackgroundColor3 = THEME.Success
                SwitchKnob.Position = UDim2.new(1, -18, 0.5, -8)
                SwitchKnob.BackgroundColor3 = Color3.new(1,1,1)
            end

            local Trigger = Create("TextButton", {
                Parent = ToggleFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })

            Trigger.MouseButton1Click:Connect(function()
                Window.Config[name][toggleConfig.Text].Set(not Toggled)
            end)
        end

        function Tab:AddSlider(sliderConfig)
            local SliderFrame = Create("Frame", {
                Name = sliderConfig.Text .. "Slider",
                Parent = TabPage,
                BackgroundColor3 = THEME.Secondary,
                Size = UDim2.new(1, 0, 0, 56)
            })
            ApplyCorner(SliderFrame, 6)
            ApplyStroke(SliderFrame, THEME.Border, 1)

            local Label = Create("TextLabel", {
                Parent = SliderFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamMedium,
                Text = sliderConfig.Text,
                TextColor3 = THEME.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local ValueLabel = Create("TextLabel", {
                Parent = SliderFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.Gotham,
                Text = tostring(sliderConfig.Default or sliderConfig.Min),
                TextColor3 = THEME.TextDim,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right
            })

            local SliderBg = Create("Frame", {
                Parent = SliderFrame,
                BackgroundColor3 = THEME.Background,
                Position = UDim2.new(0, 12, 0, 34),
                Size = UDim2.new(1, -24, 0, 6)
            })
            ApplyCorner(SliderBg, 3)

            local SliderFill = Create("Frame", {
                Parent = SliderBg,
                BackgroundColor3 = THEME.Accent,
                Size = UDim2.new(0, 0, 1, 0)
            })
            ApplyCorner(SliderFill, 3)

            local SliderKnob = Create("Frame", {
                Parent = SliderFill,
                BackgroundColor3 = Color3.new(1,1,1),
                Position = UDim2.new(1, -6, 0.5, -6),
                Size = UDim2.new(0, 12, 0, 12)
            })
            ApplyCorner(SliderKnob, 6)

            local Min = sliderConfig.Min or 0
            local Max = sliderConfig.Max or 100
            local Default = sliderConfig.Default or Min
            local Value = Default

            local function Update(input)
                local SizeScale = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                local NewValue = math.floor(Min + ((Max - Min) * SizeScale))
                
                if Value ~= NewValue then
                    Value = NewValue
                    ValueLabel.Text = tostring(Value)
                    TweenService:Create(SliderFill, TweenInfo.new(0.05), {Size = UDim2.new(SizeScale, 0, 1, 0)}):Play()
                    if sliderConfig.Callback then sliderConfig.Callback(Value) end
                    Window.Config[name][sliderConfig.Text].Value = Value
                end
            end

            -- Config Registration
            Window.Config[name][sliderConfig.Text] = {
                Value = Default,
                Set = function(val)
                    Value = math.clamp(val, Min, Max)
                    local Scale = (Value - Min) / (Max - Min)
                    ValueLabel.Text = tostring(Value)
                    TweenService:Create(SliderFill, TWEEN_INFO, {Size = UDim2.new(Scale, 0, 1, 0)}):Play()
                    if sliderConfig.Callback then sliderConfig.Callback(Value) end
                    Window.Config[name][sliderConfig.Text].Value = Value
                end
            }

            -- Initial State
            Window.Config[name][sliderConfig.Text].Set(Default)

            local Dragging = false
            
            SliderFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    Update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)
        end

        function Tab:AddInput(inputConfig)
            local InputFrame = Create("Frame", {
                Name = inputConfig.Text .. "Input",
                Parent = TabPage,
                BackgroundColor3 = THEME.Secondary,
                Size = UDim2.new(1, 0, 0, 64)
            })
            ApplyCorner(InputFrame, 6)
            ApplyStroke(InputFrame, THEME.Border, 1)

            local Label = Create("TextLabel", {
                Parent = InputFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamMedium,
                Text = inputConfig.Text,
                TextColor3 = THEME.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local InputBoxBg = Create("Frame", {
                Parent = InputFrame,
                BackgroundColor3 = THEME.Background,
                Position = UDim2.new(0, 12, 0, 32),
                Size = UDim2.new(1, -24, 0, 24)
            })
            ApplyCorner(InputBoxBg, 4)
            local InputStroke = ApplyStroke(InputBoxBg, THEME.Border, 1)

            local TextBox = Create("TextBox", {
                Parent = InputBoxBg,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 0),
                Size = UDim2.new(1, -16, 1, 0),
                Font = Enum.Font.Gotham,
                PlaceholderText = inputConfig.Placeholder or "Enter text...",
                PlaceholderColor3 = THEME.Placeholder,
                Text = "",
                TextColor3 = THEME.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false
            })

            TextBox.Focused:Connect(function()
                TweenService:Create(InputStroke, TWEEN_INFO, {Color = THEME.Accent}):Play()
            end)

            TextBox.FocusLost:Connect(function()
                TweenService:Create(InputStroke, TWEEN_INFO, {Color = THEME.Border}):Play()
                if inputConfig.Callback then inputConfig.Callback(TextBox.Text) end
            end)
        end

        function Tab:AddDropdown(dropdownConfig)
            local DropdownFrame = Create("Frame", {
                Name = dropdownConfig.Text .. "Dropdown",
                Parent = TabPage,
                BackgroundColor3 = THEME.Secondary,
                Size = UDim2.new(1, 0, 0, 60), -- Starts closed
                ClipsDescendants = true
            })
            ApplyCorner(DropdownFrame, 6)
            ApplyStroke(DropdownFrame, THEME.Border, 1)

            local Label = Create("TextLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamMedium,
                Text = dropdownConfig.Text,
                TextColor3 = THEME.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local SelectedLabel = Create("TextLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 32),
                Size = UDim2.new(1, -40, 0, 20),
                Font = Enum.Font.Gotham,
                Text = "Select...",
                TextColor3 = THEME.TextDim,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Arrow = Create("TextLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -30, 0, 32),
                Size = UDim2.new(0, 20, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = "v",
                TextColor3 = THEME.TextDim,
                TextSize = 12
            })

            local OptionContainer = Create("ScrollingFrame", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 60),
                Size = UDim2.new(1, -24, 0, 0), -- Dynamic height
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = THEME.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0)
            })
            
            local OptionLayout = Create("UIListLayout", {
                Parent = OptionContainer,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4)
            })

            local IsOpen = false
            local Options = dropdownConfig.Options or {}
            local Selected = nil

            -- Config Registration
            Window.Config[name][dropdownConfig.Text] = {
                Value = nil,
                Set = function(val)
                    Selected = val
                    SelectedLabel.Text = val
                    SelectedLabel.TextColor3 = THEME.Text
                    if dropdownConfig.Callback then dropdownConfig.Callback(val) end
                    Window.Config[name][dropdownConfig.Text].Value = val
                end
            }

            local function Toggle()
                IsOpen = not IsOpen
                local TargetHeight = IsOpen and math.min(#Options * 28 + 70, 200) or 60
                
                TweenService:Create(DropdownFrame, TWEEN_INFO, {Size = UDim2.new(1, 0, 0, TargetHeight)}):Play()
                TweenService:Create(Arrow, TWEEN_INFO, {Rotation = IsOpen and 180 or 0}):Play()
                
                if IsOpen then
                    OptionContainer.Size = UDim2.new(1, -24, 1, -70)
                end
            end

            local Trigger = Create("TextButton", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 60),
                Text = "",
                ZIndex = 2
            })
            Trigger.MouseButton1Click:Connect(Toggle)

            -- Populate Options
            for _, option in ipairs(Options) do
                local OptionBtn = Create("TextButton", {
                    Parent = OptionContainer,
                    BackgroundColor3 = THEME.Background,
                    Size = UDim2.new(1, 0, 0, 24),
                    AutoButtonColor = false,
                    Font = Enum.Font.Gotham,
                    Text = option,
                    TextColor3 = THEME.TextDim,
                    TextSize = 13
                })
                ApplyCorner(OptionBtn, 4)

                OptionBtn.MouseButton1Click:Connect(function()
                    Window.Config[name][dropdownConfig.Text].Set(option)
                    Toggle()
                end)
            end
            
            OptionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                OptionContainer.CanvasSize = UDim2.new(0, 0, 0, OptionLayout.AbsoluteContentSize.Y)
            end)
        end

        return Tab
    end

    -- Auto Load
    task.spawn(function()
        if isfile(ConfigFile) then
            Window:LoadConfig("default")
        end
    end)

    return Window
end

return Lumania
