--[[
    ============================================================
    ██╗  ██╗██╗   ██╗███╗   ██╗████████╗██████╗  ██████╗ 
    ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗
    ███████║██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║
    ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║
    ██║  ██║╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝
    ╚══╝═╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ 
    ============================================================
    Universal Roblox Script Hub
    Game: Dead by Daylight (Roblox Edition) / Horror Survival
    Executor: Synapse X / Krnl / Fluxus / Arceus X (Mobile)
    ============================================================
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local SoundService = game:GetService("SoundService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

-- ============================================================
-- PLAYER REFERENCES
-- ============================================================
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ============================================================
-- VARIABLES & CONFIG
-- ============================================================
local Config = {
    -- VIP
    AutoPlay = false,
    AutoDagger = false,
    DaggerRange = 30,
    AutoWiggle = false,
    WiggleSpeed = 100,

    -- Survivor
    SpeedBoost = false,
    CustomSpeed = 16,
    NoSlowdown = false,
    ForceReset = false,
    SilentActions = false,
    AntiFallDmg = false,
    GodMode = false,
    InstantHeal = false,
    AntiKnock = false,
    AutoHealAura = false,
    HealAuraRange = 25,
    HealAuraCooldown = 0,

    -- Killer
    VeinSpearPrediction = false,
    VeinSpearNoGravity = false,
    AntiBlind = false,
    AntiStun = false,
    DoubleDmgGen = false,
    DmgGenMultiplier = 3,
    ActivateKillerPower = false,

    -- Visuals
    PlayerESP = false,
    ObjectESP = false,
    CustomFOV = false,
    FOVValue = 90,
    ShowCrosshair = false,
    RemoveBlurBloom = false,
    ForceFullbright = false,
    PotatoMode = false,

    -- Combat
    EnableAimbot = false,
    AimRadius = 200,
    ShowTracer = false,
    LockOnHighlight = false,
    ExpandHitbox = false,
    AutoAttack = false,
    AutoAttackRange = 8,
    FPP = false,

    -- Automation
    AutoGenerator = false,
    GenMode = "Perfect",
    BoostAllGen = false,
    InstantEscape = false,
    SelfUnHook = false,
}

local Connections = {}
local ESPObjects = {}
local TracerLine = nil
local CrosshairGui = nil
local HighlightObj = nil
local OriginalWalkSpeed = 16
local OriginalFOV = 90
local Killers = {}
local Generators = {}
local Pallets = {}
local ExitGates = {}
local Hooks = {}
local SurvivorList = {}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function GetClosestPlayer(maxDist, predicate)
    local closest = nil
    local shortest = maxDist or math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if predicate == nil or predicate(player) then
                local dist = (player.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = player
                end
            end
        end
    end
    return closest, shortest
end

local function GetClosestPart(parts, maxDist)
    local closest = nil
    local shortest = maxDist or math.huge
    for _, part in pairs(parts) do
        if part and part.Parent then
            local dist = (part.Position - HumanoidRootPart.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = part
            end
        end
    end
    return closest, shortest
end

local function TeleportTo(position)
    if Character and HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(position)
    end
end

local function GetCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

local function FindFirstChildRecursive(parent, name)
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == name then
            return child
        end
        local found = FindFirstChildRecursive(child, name)
        if found then return found end
    end
    return nil
end

-- ============================================================
-- CUSTOM UI LIBRARY
-- ============================================================
local UI = {}

do
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ScriptHubUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 580, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -290, 0.5, -210)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(45, 45, 55)
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- Make draggable
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    MainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 38)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "  SCRIPT HUB"
    TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -36, 0, 4)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 12
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 6)
    CloseBtnCorner.Parent = CloseBtn

    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "MinBtn"
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -72, 0, 4)
    MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    MinBtn.Text = "_"
    MinBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    MinBtn.TextSize = 14
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = TitleBar
    local MinBtnCorner = Instance.new("UICorner")
    MinBtnCorner.CornerRadius = UDim.new(0, 6)
    MinBtnCorner.Parent = MinBtn

    local isMinimized = false
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 580, 0, 38)
            }):Play()
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 580, 0, 420)
            }):Play()
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Tab Bar
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, 0, 0, 36)
    TabBar.Position = UDim2.new(0, 0, 0, 38)
    TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
    TabBar.BorderSizePixel = 0
    TabBar.Parent = MainFrame

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 2)
    TabLayout.Parent = TabBar

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingLeft = UDim.new(0, 4)
    TabPadding.PaddingTop = UDim.new(0, 3)
    TabPadding.Parent = TabBar

    -- Content Area
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -74)
    ContentFrame.Position = UDim2.new(0, 0, 0, 74)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ClipsDescendants = true
    ContentFrame.Parent = MainFrame

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Name = "ScrollFrame"
    ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollFrame.Parent = ContentFrame

    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 6)
    ContentLayout.Parent = ScrollFrame

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingLeft = UDim.new(0, 12)
    ContentPadding.PaddingRight = UDim.new(0, 12)
    ContentPadding.PaddingTop = UDim.new(0, 8)
    ContentPadding.PaddingBottom = UDim.new(0, 12)
    ContentPadding.Parent = ScrollFrame

    local tabs = {}
    local currentTab = nil

    function UI:CreateTab(name, icon, order)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = name .. "Tab"
        tabBtn.Size = UDim2.new(0, 90, 0, 30)
        tabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        tabBtn.TextColor3 = Color3.fromRGB(140, 140, 155)
        tabBtn.Text = (icon or "") .. " " .. name
        tabBtn.TextSize = 11
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.LayoutOrder = order or #tabs + 1
        tabBtn.Parent = TabBar

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tabBtn

        local tabPage = Instance.new("Frame")
        tabPage.Name = name .. "Page"
        tabPage.Size = UDim2.new(1, 0, 0, 0)
        tabPage.BackgroundTransparency = 1
        tabPage.AutomaticSize = Enum.AutomaticSize.Y
        tabPage.Visible = false
        tabPage.Parent = ScrollFrame

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 5)
        pageLayout.Parent = tabPage

        tabs[name] = { button = tabBtn, page = tabPage }

        tabBtn.MouseButton1Click:Connect(function()
            if currentTab then
                tabs[currentTab].button.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
                tabs[currentTab].button.TextColor3 = Color3.fromRGB(140, 140, 155)
                tabs[currentTab].page.Visible = false
            end
            currentTab = name
            tabBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 90)
            tabBtn.TextColor3 = Color3.fromRGB(230, 200, 255)
            tabPage.Visible = true
        end)

        -- Auto select first tab
        if not currentTab then
            currentTab = name
            tabBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 90)
            tabBtn.TextColor3 = Color3.fromRGB(230, 200, 255)
            tabPage.Visible = true
        end

        return tabPage, pageLayout
    end

    function UI:CreateSection(parent, title, order)
        local section = Instance.new("Frame")
        section.Name = title
        section.Size = UDim2.new(1, 0, 0, 0)
        section.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.BorderSizePixel = 0
        section.LayoutOrder = order or 0
        section.Parent = parent

        local secCorner = Instance.new("UICorner")
        secCorner.CornerRadius = UDim.new(0, 6)
        secCorner.Parent = section

        local secPad = Instance.new("UIPadding")
        secPad.PaddingTop = UDim.new(0, 8)
        secPad.PaddingBottom = UDim.new(0, 8)
        secPad.PaddingLeft = UDim.new(0, 12)
        secPad.PaddingRight = UDim.new(0, 12)
        secPad.Parent = section

        local secLayout = Instance.new("UIListLayout")
        secLayout.SortOrder = Enum.SortOrder.LayoutOrder
        secLayout.Padding = UDim.new(0, 4)
        secLayout.Parent = section

        if title and title ~= "" then
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 18)
            label.BackgroundTransparency = 1
            label.Text = title
            label.TextColor3 = Color3.fromRGB(180, 140, 255)
            label.TextSize = 12
            label.Font = Enum.Font.GothamBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.LayoutOrder = -1
            label.Parent = section
        end

        return section, secLayout
    end

    function UI:CreateToggle(parent, label, default, order, callback)
        default = default or false
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, 0, 0, 28)
        toggle.BackgroundTransparency = 1
        toggle.LayoutOrder = order or 0
        toggle.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = toggle

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 42, 0, 22)
        btn.Position = UDim2.new(1, -42, 0.5, -11)
        btn.BackgroundColor3 = default and Color3.fromRGB(100, 60, 180) or Color3.fromRGB(45, 45, 55)
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = toggle

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = btn

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 18, 0, 18)
        indicator.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        indicator.BorderSizePixel = 0
        indicator.Parent = btn

        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(1, 0)
        indCorner.Parent = indicator

        local toggled = default
        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            if toggled then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 60, 180)}):Play()
                TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9)}):Play()
            else
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
                TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9)}):Play()
            end
            if callback then callback(toggled) end
        end)

        return {GetState = function() return toggled end, SetState = function(v)
            toggled = v
            if v then
                btn.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
                indicator.Position = UDim2.new(1, -20, 0.5, -9)
            else
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                indicator.Position = UDim2.new(0, 2, 0.5, -9)
            end
        end}
    end

    function UI:CreateSlider(parent, label, min, max, default, order, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 42)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = order or 0
        frame.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text = label .. ": " .. tostring(default)
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame

        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(1, 0, 0, 8)
        sliderBg.Position = UDim2.new(0, 0, 0, 24)
        sliderBg.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        sliderBg.BorderSizePixel = 0
        sliderBg.Parent = frame

        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(1, 0)
        bgCorner.Parent = sliderBg

        local fill = Instance.new("Frame")
        local pct = (default - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
        fill.BorderSizePixel = 0
        fill.Parent = sliderBg

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local sliderBtn = Instance.new("TextButton")
        sliderBtn.Size = UDim2.new(1, 0, 1, 14)
        sliderBtn.Position = UDim2.new(0, 0, 0, -3)
        sliderBtn.BackgroundTransparency = 1
        sliderBtn.Text = ""
        sliderBtn.Parent = sliderBg

        local sliding = false

        local function update(input)
            local relX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * relX)
            fill.Size = UDim2.new(relX, 0, 1, 0)
            lbl.Text = label .. ": " .. tostring(val)
            if callback then callback(val) end
            return val
        end

        sliderBtn.MouseButton1Down:Connect(function(input)
            sliding = true
            update(input)
        end)

        UserInputService.InputChanged:Connect(function(input)
            if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if sliding and input.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
            end
        end)

        return {GetValue = function() return tonumber(lbl.Text:match(": (.+)")) or default end}
    end

    function UI:CreateButton(parent, label, order, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(55, 40, 85)
        btn.TextColor3 = Color3.fromRGB(230, 210, 255)
        btn.Text = label
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.LayoutOrder = order or 0
        btn.Parent = parent

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
            -- Flash effect
            local orig = btn.BackgroundColor3
            btn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
            task.delay(0.15, function()
                btn.BackgroundColor3 = orig
            end)
        end)

        return btn
    end

    function UI:CreateDropdown(parent, label, options, default, order, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 30)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = order or 0
        frame.Parent = parent

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.Text = label .. ": " .. (default or options[1])
        btn.TextColor3 = Color3.fromRGB(200, 200, 210)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = frame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        local dropdown = Instance.new("Frame")
        dropdown.Size = UDim2.new(1, 0, 0, #options * 24)
        dropdown.Position = UDim2.new(0, 0, 1, 2)
        dropdown.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        dropdown.BorderSizePixel = 0
        dropdown.Visible = false
        dropdown.ZIndex = 10
        dropdown.Parent = btn

        local ddCorner = Instance.new("UICorner")
        ddCorner.CornerRadius = UDim.new(0, 6)
        ddCorner.Parent = dropdown

        local ddLayout = Instance.new("UIListLayout")
        ddLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ddLayout.Parent = dropdown

        local isOpen = false
        local selected = default or options[1]

        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 24)
            optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
            optBtn.Text = opt
            optBtn.TextColor3 = Color3.fromRGB(190, 190, 200)
            optBtn.TextSize = 11
            optBtn.Font = Enum.Font.Gotham
            optBtn.BorderSizePixel = 0
            optBtn.LayoutOrder = i
            optBtn.ZIndex = 11
            optBtn.Parent = dropdown

            local optCorner = Instance.new("UICorner")
            optCorner.CornerRadius = UDim.new(0, 4)
            optCorner.Parent = optBtn

            optBtn.MouseButton1Click:Connect(function()
                selected = opt
                btn.Text = label .. ": " .. opt
                isOpen = false
                dropdown.Visible = false
                if callback then callback(opt) end
            end)

            optBtn.MouseEnter:Connect(function()
                optBtn.BackgroundColor3 = Color3.fromRGB(60, 45, 90)
            end)
            optBtn.MouseLeave:Connect(function()
                optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
            end)
        end

        btn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            dropdown.Visible = isOpen
        end)

        return {GetSelected = function() return selected end}
    end

    function UI:GetScreenGui()
        return ScreenGui
    end
end

-- ============================================================
-- CREATE TABS
-- ============================================================
local tabVIP, vipLayout = UI:CreateTab("VIP", "[VIP]", 1)
local tabSurvivor, survLayout = UI:CreateTab("Survivor", "[S]", 2)
local tabKiller, killerLayout = UI:CreateTab("Killer", "[K]", 3)
local tabVisuals, visLayout = UI:CreateTab("Visuals", "[V]", 4)
local tabCombat, combatLayout = UI:CreateTab("Combat", "[C]", 5)
local tabAuto, autoLayout = UI:CreateTab("Auto", "[A]", 6)

-- ============================================================
-- VIP TAB
-- ============================================================
local vipSec, vipSecLayout = UI:CreateSection(tabVIP, "ULTIMATE AUTOMATIC", 1)

UI:CreateToggle(vipSec, "Auto Play (Smart AI / AutoFarmBot)", false, 1, function(v)
    Config.AutoPlay = v
    if v then Notify("Auto Play", "Smart AI Bot aktif! Mencari Generator...") end
end)

UI:CreateToggle(vipSec, "Auto Dagger (Auto Parry)", false, 2, function(v)
    Config.AutoDagger = v
    if v then Notify("Auto Dagger", "Parrying Dagger aktif!") end
end)

UI:CreateSlider(vipSec, "Dagger Range", 5, 80, 30, 3, function(v)
    Config.DaggerRange = v
end)

UI:CreateToggle(vipSec, "Auto Wiggle Master", false, 4, function(v)
    Config.AutoWiggle = v
    if v then Notify("Auto Wiggle", "Wiggle Master aktif!") end
end)

-- ============================================================
-- SURVIVOR TAB
-- ============================================================
local survSec1, survSec1Layout = UI:CreateSection(tabSurvivor, "MOVEMENT & HEALTH", 1)

UI:CreateToggle(survSec1, "Speed Boost", false, 1, function(v)
    Config.SpeedBoost = v
    if v then
        Humanoid.WalkSpeed = Config.CustomSpeed
    else
        Humanoid.WalkSpeed = OriginalWalkSpeed
    end
end)

UI:CreateSlider(survSec1, "Custom Speed", 16, 100, 16, 2, function(v)
    Config.CustomSpeed = v
    if Config.SpeedBoost then
        Humanoid.WalkSpeed = v
    end
end)

UI:CreateToggle(survSec1, "No Slowdown", false, 3, function(v)
    Config.NoSlowdown = v
end)

UI:CreateButton(survSec1, "Force Reset State (Anti-Stuck)", 4, function()
    GetCharacter()
    Humanoid.Jump = true
    task.delay(0.1, function()
        if Character:FindFirstChild("Animate") then
            Character.Animate.Disabled = true
            task.delay(0.2, function()
                Character.Animate.Disabled = false
            end)
        end
    end)
    Notify("Force Reset", "State telah di-reset!")
end)

UI:CreateToggle(survSec1, "Silent Actions (Anti-Noise)", false, 5, function(v)
    Config.SilentActions = v
end)

UI:CreateToggle(survSec1, "Anti Fall Damage", false, 6, function(v)
    Config.AntiFallDmg = v
end)

UI:CreateToggle(survSec1, "Client God Mode (Beta)", false, 7, function(v)
    Config.GodMode = v
    if v then Notify("God Mode", "Damage Nullifier aktif!") end
end)

UI:CreateButton(survSec1, "Instant Heal", 8, function()
    GetCharacter()
    if Humanoid then
        Humanoid.Health = Humanoid.MaxHealth
        Notify("Instant Heal", "Health dipulihkan ke max!")
    end
end)

UI:CreateToggle(survSec1, "Anti Knock", false, 9, function(v)
    Config.AntiKnock = v
end)

UI:CreateToggle(survSec1, "Auto Heal Aura", false, 10, function(v)
    Config.AutoHealAura = v
    if v then Notify("Auto Heal Aura", "Menyembuhkan teman sekitar!") end
end)

UI:CreateSlider(survSec1, "Heal Aura Range", 5, 60, 25, 11, function(v)
    Config.HealAuraRange = v
end)

-- ============================================================
-- KILLER TAB
-- ============================================================
local killerSec1, killerSec1Layout = UI:CreateSection(tabKiller, "VEIN KILLER MODIFICATION", 1)

UI:CreateToggle(killerSec1, "Vein Spear: Drop Prediction", false, 1, function(v)
    Config.VeinSpearPrediction = v
    if v then Notify("Vein Spear", "Drop Prediction aktif!") end
end)

UI:CreateToggle(killerSec1, "Vein Spear: No Gravity", false, 2, function(v)
    Config.VeinSpearNoGravity = v
    if v then Notify("Vein Spear", "No Gravity aktif!") end
end)

UI:CreateToggle(killerSec1, "Anti-Blind", false, 3, function(v)
    Config.AntiBlind = v
    if v then
        -- Remove fog and blind effects
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then
                if v.Name:lower():find("blind") or v.Name:lower():find("fog") or v.Name:lower():find("flash") then
                    v.Enabled = false
                end
            end
        end
    end
end)

UI:CreateToggle(killerSec1, "Anti-Stun", false, 4, function(v)
    Config.AntiStun = v
    if v then Notify("Anti-Stun", "Kebal terhadap stun!") end
end)

UI:CreateToggle(killerSec1, "Double Damage Generator", false, 5, function(v)
    Config.DoubleDmgGen = v
end)

UI:CreateSlider(killerSec1, "Gen Damage Multiplier", 2, 10, 3, 6, function(v)
    Config.DmgGenMultiplier = v
end)

UI:CreateButton(killerSec1, "Activate Killer Power", 7, function()
    Config.ActivateKillerPower = true
    -- Try to find and trigger killer power remote
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local nameLower = obj.Name:lower()
            if nameLower:find("power") or nameLower:find("ability") or nameLower:find("special") then
                pcall(function()
                    obj:FireServer()
                end)
                pcall(function()
                    obj:InvokeServer()
                end)
            end
        end
    end
    Notify("Killer Power", "Kekuatan spesial dipicu!")
    task.delay(1, function() Config.ActivateKillerPower = false end)
end)

-- ============================================================
-- VISUALS TAB
-- ============================================================
local visSec1, visSec1Layout = UI:CreateSection(tabVisuals, "ESP & WORLD", 1)

UI:CreateToggle(visSec1, "Player ESP", false, 1, function(v)
    Config.PlayerESP = v
    if v then
        CreatePlayerESP()
        Notify("ESP", "Player ESP aktif!")
    else
        ClearPlayerESP()
    end
end)

UI:CreateToggle(visSec1, "Object ESP", false, 2, function(v)
    Config.ObjectESP = v
    if v then
        CreateObjectESP()
        Notify("ESP", "Object ESP aktif!")
    else
        ClearObjectESP()
    end
end)

UI:CreateToggle(visSec1, "Enable Custom FOV", false, 3, function(v)
    Config.CustomFOV = v
    if v then
        Camera.FieldOfView = Config.FOVValue
    else
        Camera.FieldOfView = OriginalFOV
    end
end)

UI:CreateSlider(visSec1, "FOV Value", 30, 120, 90, 4, function(v)
    Config.FOVValue = v
    if Config.CustomFOV then
        Camera.FieldOfView = v
    end
end)

UI:CreateToggle(visSec1, "Show Crosshair", false, 5, function(v)
    Config.ShowCrosshair = v
    if v then CreateCrosshair() else RemoveCrosshair() end
end)

UI:CreateToggle(visSec1, "Remove Blur & Bloom", false, 6, function(v)
    Config.RemoveBlurBloom = v
    if v then
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
    end
end)

UI:CreateToggle(visSec1, "Force Fullbright", false, 7, function(v)
    Config.ForceFullbright = v
    if v then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    end
end)

UI:CreateToggle(visSec1, "Extreme Potato Mode", false, 8, function(v)
    Config.PotatoMode = v
    if v then
        -- Disable all post-processing
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = 2
        -- Low quality settings
        settings().QualityLevel = 1
    else
        settings().QualityLevel = 10
        Lighting.GlobalShadows = true
    end
end)

-- ============================================================
-- COMBAT TAB
-- ============================================================
local combatSec1, combatSec1Layout = UI:CreateSection(tabCombat, "TARGETING SYSTEM", 1)

UI:CreateToggle(combatSec1, "Enable Aimbot", false, 1, function(v)
    Config.EnableAimbot = v
    if v then Notify("Aimbot", "Aimbot aktif!") end
end)

UI:CreateSlider(combatSec1, "Aim Radius", 50, 500, 200, 2, function(v)
    Config.AimRadius = v
end)

UI:CreateToggle(combatSec1, "Show Target Tracer", false, 3, function(v)
    Config.ShowTracer = v
    if v then CreateTracer() else RemoveTracer() end
end)

UI:CreateToggle(combatSec1, "Lock-On Highlight", false, 4, function(v)
    Config.LockOnHighlight = v
    if v then CreateHighlight() else RemoveHighlight() end
end)

UI:CreateToggle(combatSec1, "FPP / TPP Toggle", false, 5, function(v)
    Config.FPP = v
    if v then
        Camera.CameraSubject = Humanoid
        Camera.CFrame = CFrame.new(HumanoidRootPart.Position + Vector3.new(0, 2, 0), HumanoidRootPart.Position)
    end
end)

UI:CreateToggle(combatSec1, "Expand Killer Hitbox", false, 6, function(v)
    Config.ExpandHitbox = v
    if v then ExpandKillerHitboxes() end
end)

UI:CreateToggle(combatSec1, "Auto Attack", false, 7, function(v)
    Config.AutoAttack = v
    if v then Notify("Auto Attack", "Auto Attack aktif!") end
end)

UI:CreateSlider(combatSec1, "Auto Attack Range", 3, 20, 8, 8, function(v)
    Config.AutoAttackRange = v
end)

-- ============================================================
-- AUTOMATION TAB
-- ============================================================
local autoSec1, autoSec1Layout = UI:CreateSection(tabAuto, "GENERATOR & UTILITY", 1)

UI:CreateToggle(autoSec1, "Auto Generator", false, 1, function(v)
    Config.AutoGenerator = v
    if v then Notify("Auto Gen", "Auto SkillCheck aktif!") end
end)

local genDropdown = UI:CreateDropdown(autoSec1, "Gen Mode", {"Perfect", "Neutral"}, "Perfect", 2, function(v)
    Config.GenMode = v
end)

UI:CreateToggle(autoSec1, "Boost All Gen (Group Project)", false, 3, function(v)
    Config.BoostAllGen = v
    if v then Notify("Boost Gen", "Menyuntikkan progress ke semua generator!") end
end)

UI:CreateButton(autoSec1, "Instant Escape (Gate)", 4, function()
    Config.InstantEscape = true
    Notify("Instant Escape", "Mencari Exit Gate...")
    -- Scan map for exit gates
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            if nameLower:find("exit") or nameLower:find("gate") or nameLower:find("escape") or nameLower:find("finish") then
                TeleportTo(obj.Position + Vector3.new(0, 3, 0))
                Notify("Instant Escape", "Teleportasi ke Exit Gate!")
                break
            end
        end
    end
    -- Try fire escape remote
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local nameLower = obj.Name:lower()
            if nameLower:find("escape") or nameLower:find("exit") or nameLower:find("gate") or nameLower:find("win") then
                pcall(function() obj:FireServer() end)
                pcall(function() obj:InvokeServer() end)
            end
        end
    end
    task.delay(2, function() Config.InstantEscape = false end)
end)

UI:CreateToggle(autoSec1, "Self UnHook (100%)", false, 5, function(v)
    Config.SelfUnHook = v
    if v then Notify("Self UnHook", "Peluang lepas 100% aktif!") end
end)

-- ============================================================
-- ESP SYSTEM
-- ============================================================
function CreatePlayerESP()
    ClearPlayerESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateESPForPlayer(player)
        end
    end
end

function CreateESPForPlayer(player)
    if not player.Character then return end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Billboard GUI
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESPGUI_" .. player.Name
    bb.Adornee = rootPart
    bb.Size = UDim2.new(0, 200, 0, 80)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = rootPart

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = player.DisplayName
    nameLabel.Parent = bb

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0, 14)
    distLabel.Position = UDim2.new(0, 0, 0, 18)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.TextSize = 11
    distLabel.Font = Enum.Font.Gotham
    distLabel.Text = "0m"
    distLabel.Parent = bb

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 14)
    statusLabel.Position = UDim2.new(0, 0, 0, 32)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.TextStrokeTransparency = 0.5
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "Alive"
    statusLabel.Parent = bb

    -- Box (Highlight)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight_" .. player.Name
    highlight.Adornee = player.Character
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent = player.Character

    table.insert(ESPObjects, {bb, highlight, player})
end

function ClearPlayerESP()
    for _, data in ipairs(ESPObjects) do
        pcall(function() data[1]:Destroy() end)
        pcall(function() data[2]:Destroy() end)
    end
    ESPObjects = {}
end

function CreateObjectESP()
    ClearObjectESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            local espType = nil
            local color = Color3.fromRGB(255, 255, 255)

            if nameLower:find("generator") or nameLower:find("gen") then
                espType = "Generator"
                color = Color3.fromRGB(255, 200, 50)
            elseif nameLower:find("pallet") then
                espType = "Pallet"
                color = Color3.fromRGB(50, 255, 50)
            elseif nameLower:find("exit") or nameLower:find("gate") then
                espType = "Exit Gate"
                color = Color3.fromRGB(50, 150, 255)
            elseif nameLower:find("hook") then
                espType = "Hook"
                color = Color3.fromRGB(255, 50, 50)
            end

            if espType then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ObjESP_" .. obj.Name
                bb.Adornee = obj
                bb.Size = UDim2.new(0, 150, 0, 30)
                bb.StudsOffset = Vector3.new(0, 2, 0)
                bb.AlwaysOnTop = true
                bb.Parent = obj

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 0.5
                label.BackgroundColor3 = color
                label.TextColor3 = Color3.fromRGB(0, 0, 0)
                label.TextSize = 11
                label.Font = Enum.Font.GothamBold
                label.Text = espType
                label.Parent = bb

                table.insert(ESPObjects, {bb, nil, obj})
            end
        end
    end
end

function ClearObjectESP()
    for _, data in ipairs(ESPObjects) do
        if data[3] and typeof(data[3]) == "Instance" then
            local existing = data[3]:FindFirstChild("ObjESP_" .. data[3].Name)
            if existing then existing:Destroy() end
        end
    end
end

-- ============================================================
-- CROSSHAIR
-- ============================================================
function CreateCrosshair()
    RemoveCrosshair()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CrosshairGui"
    gui.ResetOnSpawn = false
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 4, 0, 4)
    frame.Position = UDim2.new(0.5, -2, 0.5, -2)
    frame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    -- Outer ring
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, 20, 0, 20)
    ring.Position = UDim2.new(0.5, -10, 0.5, -10)
    ring.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ring.BackgroundTransparency = 0.7
    ring.BorderSizePixel = 1
    ring.BorderColor3 = Color3.fromRGB(255, 50, 50)
    ring.Parent = gui

    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = ring

    CrosshairGui = gui
end

function RemoveCrosshair()
    if CrosshairGui then
        pcall(function() CrosshairGui:Destroy() end)
        CrosshairGui = nil
    end
end

-- ============================================================
-- TRACER LINE
-- ============================================================
function CreateTracer()
    RemoveTracer()
    TracerLine = Drawing.new("Line")
    TracerLine.Color = Color3.fromRGB(255, 30, 30)
    TracerLine.Thickness = 1.5
    TracerLine.Transparency = 0.7
    TracerLine.Visible = false
end

function RemoveTracer()
    if TracerLine then
        pcall(function() TracerLine:Remove() end)
        TracerLine = nil
    end
end

-- ============================================================
-- HIGHLIGHT SYSTEM
-- ============================================================
function CreateHighlight()
    RemoveHighlight()
    HighlightObj = Instance.new("Highlight")
    HighlightObj.FillTransparency = 0.6
    HighlightObj.OutlineTransparency = 0
    HighlightObj.FillColor = Color3.fromRGB(255, 215, 0)
    HighlightObj.OutlineColor = Color3.fromRGB(255, 50, 50)
    HighlightObj.Parent = Workspace
end

function RemoveHighlight()
    if HighlightObj then
        pcall(function() HighlightObj:Destroy() end)
        HighlightObj = nil
    end
end

-- ============================================================
-- EXPAND HITBOX
-- ============================================================
function ExpandKillerHitboxes()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local origSize = part.Size
                    part.Size = origSize * 2
                end
            end
        end
    end
end

-- ============================================================
-- MAIN LOOPS
-- ============================================================

-- CHARACTER RESPAWN HANDLER
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    OriginalWalkSpeed = Humanoid.WalkSpeed
    if Config.SpeedBoost then
        Humanoid.WalkSpeed = Config.CustomSpeed
    end
    -- Re-create ESP for new character
    if Config.PlayerESP then
        task.delay(1, function() CreatePlayerESP() end)
    end
end)

-- PLAYER JOINED / LEFT
Players.PlayerAdded:Connect(function(player)
    if Config.PlayerESP then
        task.delay(2, function() CreateESPForPlayer(player) end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    ClearPlayerESP()
    if Config.PlayerESP then
        task.delay(1, function() CreatePlayerESP() end)
    end
end)

-- ============================================================
-- HEARTBEAT LOOP (Main Processing)
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    GetCharacter()
    if not Character or not HumanoidRootPart or not Humanoid then return end

    -- ==================
    -- AUTO PLAY (Smart AI)
    -- ==================
    if Config.AutoPlay then
        -- Find closest generator
        local closestGen, genDist = nil, math.huge
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local nameLower = obj.Name:lower()
                if (nameLower:find("generator") or nameLower:find("gen")) and not nameLower:find("complete") then
                    local dist = (obj.Position - HumanoidRootPart.Position).Magnitude
                    if dist < genDist then
                        genDist = dist
                        closestGen = obj
                    end
                end
            end
        end

        -- Check if killer is nearby
        local closestKiller, killerDist = GetClosestPlayer(60, function(p)
            return p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0
        end)

        -- Flee from killer if too close
        if closestKiller and killerDist < 25 then
            local awayDir = (HumanoidRootPart.Position - closestKiller.Character.HumanoidRootPart.Position).Unit
            local fleePos = HumanoidRootPart.Position + awayDir * 30
            Humanoid:MoveTo(fleePos)
        elseif closestGen and genDist > 5 then
            -- Walk to generator
            Humanoid:MoveTo(closestGen.Position)
        elseif closestGen then
            -- At generator - try to interact
            -- Attempt to fire any interact remote
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    local nameLower = obj.Name:lower()
                    if nameLower:find("interact") or nameLower:find("gen") or nameLower:find("repair") or nameLower:find("fix") then
                        pcall(function() obj:FireServer(closestGen) end)
                    end
                end
            end
        end

        -- Check for exit gates if generators done
        if not closestGen then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local nameLower = obj.Name:lower()
                    if nameLower:find("exit") or nameLower:find("gate") or nameLower:find("escape") then
                        local dist = (obj.Position - HumanoidRootPart.Position).Magnitude
                        if dist > 5 then
                            Humanoid:MoveTo(obj.Position)
                        else
                            -- Try open gate
                            for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                                    local rn = remote.Name:lower()
                                    if rn:find("gate") or rn:find("exit") or rn:find("open") or rn:find("escape") then
                                        pcall(function() remote:FireServer(obj) end)
                                        pcall(function() remote:InvokeServer(obj) end)
                                    end
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
    end

    -- ==================
    -- AUTO DAGGER (Auto Parry)
    -- ==================
    if Config.AutoDagger then
        local closest, dist = GetClosestPlayer(Config.DaggerRange, function(p)
            return p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0
        end)
        if closest and closest.Character then
            local killerRoot = closest.Character:FindFirstChild("HumanoidRootPart")
            if killerRoot then
                -- Face the killer
                local lookCFrame = CFrame.lookAt(HumanoidRootPart.Position, killerRoot.Position)
                HumanoidRootPart.CFrame = lookCFrame

                -- Attempt to fire parry/dagger remote
                for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                        local nameLower = obj.Name:lower()
                        if nameLower:find("parry") or nameLower:find("dagger") or nameLower:find("block") or nameLower:find("deflect") or nameLower:find("counter") then
                            pcall(function()
                                obj:FireServer(closest.Character)
                            end)
                            pcall(function()
                                obj:InvokeServer(closest.Character)
                            end)
                        end
                    end
                end
            end
        end
    end

    -- ==================
    -- AUTO WIGGLE MASTER
    -- ==================
    if Config.AutoWiggle then
        -- Check if player is being carried (hooked/carrying state)
        local isCarried = false
        pcall(function()
            -- Check for carry/hook status through character attributes or values
            for _, val in ipairs(Character:GetChildren()) do
                if val:IsA("BoolValue") or val:IsA("IntValue") or val:IsA("StringValue") then
                    local n = val.Name:lower()
                    if n:find("carry") or n:find("hook") or n:find("grab") or n:find("carry") then
                        isCarried = true
                    end
                end
            end
        end)

        if isCarried then
            -- Simulate wiggle inputs rapidly
            for i = 1, 3 do
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:SetKeyDown(Enum.KeyCode.A)
                    task.wait(0.05)
                    VirtualUser:SetKeyUp(Enum.KeyCode.A)
                    VirtualUser:SetKeyDown(Enum.KeyCode.D)
                    task.wait(0.05)
                    VirtualUser:SetKeyUp(Enum.KeyCode.D)
                    VirtualUser:SetKeyDown(Enum.KeyCode.Space)
                    task.wait(0.03)
                    VirtualUser:SetKeyUp(Enum.KeyCode.Space)
                end)
            end

            -- Fire wiggle remotes
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local nameLower = obj.Name:lower()
                    if nameLower:find("wiggle") or nameLower:find("struggle") or nameLower:find("escape") or nameLower:find("break") then
                        pcall(function() obj:FireServer(math.random(1, 4)) end)
                    end
                end
            end
        end
    end

    -- ==================
    -- NO SLOWDOWN
    -- ==================
    if Config.NoSlowdown then
        Humanoid.WalkSpeed = Config.SpeedBoost and Config.CustomSpeed or OriginalWalkSpeed
        -- Reset any slowdown attributes
        pcall(function()
            for _, val in ipairs(Character:GetChildren()) do
                if val.Name:lower():find("slow") or val.Name:lower():find("debuff") then
                    val.Value = 0
                end
            end
        end)
    end

    -- ==================
    -- SILENT ACTIONS
    -- ==================
    if Config.SilentActions then
        pcall(function()
            -- Disable footstep sounds
            for _, obj in ipairs(Character:GetDescendants()) do
                if obj:IsA("Sound") then
                    local nameLower = obj.Name:lower()
                    if nameLower:find("foot") or nameLower:find("step") or nameLower:find("run") or nameLower:find("jump") then
                        obj.Volume = 0
                    end
                end
            end
            -- Disable any noise/indicator Particles
            for _, obj in ipairs(Character:GetDescendants()) do
                if obj:IsA("ParticleEmitter") then
                    local nameLower = obj.Name:lower()
                    if nameLower:find("noise") or nameLower:find("alert") or nameLower:find("sound") or nameLower:find("indicator") then
                        obj.Enabled = false
                    end
                end
            end
        end)
    end

    -- ==================
    -- ANTI FALL DAMAGE
    -- ==================
    if Config.AntiFallDmg then
        pcall(function()
            -- Reset fall state
            if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                -- Will zero out velocity on landing
                if HumanoidRootPart.Velocity.Y < -50 then
                    HumanoidRootPart.Velocity = Vector3.new(HumanoidRootPart.Velocity.X, -10, HumanoidRootPart.Velocity.Z)
                end
            end
        end)
    end

    -- ==================
    -- CLIENT GOD MODE
    -- ==================
    if Config.GodMode then
        pcall(function()
            Humanoid.Health = Humanoid.MaxHealth
        end)
    end

    -- ==================
    -- ANTI KNOCK
    -- ==================
    if Config.AntiKnock then
        pcall(function()
            -- Prevent knockdown state
            if Humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.wait(0.1)
                Humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end

    -- ==================
    -- AUTO HEAL AURA
    -- ==================
    if Config.AutoHealAura then
        Config.HealAuraCooldown = Config.HealAuraCooldown - dt
        if Config.HealAuraCooldown <= 0 then
            Config.HealAuraCooldown = 2 -- Heal every 2 seconds
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                    local targetHumanoid = player.Character.Humanoid
                    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot and targetHumanoid.Health < targetHumanoid.MaxHealth then
                        local dist = (targetRoot.Position - HumanoidRootPart.Position).Magnitude
                        if dist <= Config.HealAuraRange then
                            -- Fire heal remote
                            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                                    local nameLower = obj.Name:lower()
                                    if nameLower:find("heal") then
                                        pcall(function() obj:FireServer(player.Character) end)
                                        pcall(function() obj:InvokeServer(player.Character) end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- ==================
    -- ANTI STUN (Killer)
    -- ==================
    if Config.AntiStun then
        pcall(function()
            if Humanoid:GetState() == Enum.HumanoidStateType.Stunned then
                Humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end

    -- ==================
    -- AIMBOT
    -- ==================
    if Config.EnableAimbot then
        local closest, dist = GetClosestPlayer(Config.AimRadius)
        if closest and closest.Character and closest.Character:FindFirstChild("HumanoidRootPart") then
            local target = closest.Character.HumanoidRootPart

            -- Move camera to target
            local targetPos = target.Position + Vector3.new(0, 2, 0)
            local newCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = newCFrame

            -- Update highlight
            if Config.LockOnHighlight and HighlightObj then
                HighlightObj.Adornee = closest.Character
            end

            -- Update tracer
            if Config.ShowTracer and TracerLine then
                TracerLine.Visible = true
                local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
                if onScreen then
                    TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                end
            end
        else
            if TracerLine then TracerLine.Visible = false end
            if HighlightObj then HighlightObj.Adornee = nil end
        end
    end

    -- ==================
    -- FPP / TPP
    -- ==================
    if Config.FPP then
        pcall(function()
            Camera.CameraType = Enum.CameraType.LockFirstPerson
        end)
    end

    -- ==================
    -- AUTO ATTACK
    -- ==================
    if Config.AutoAttack then
        local closest, dist = GetClosestPlayer(Config.AutoAttackRange)
        if closest and closest.Character then
            -- Fire attack remote
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local nameLower = obj.Name:lower()
                    if nameLower:find("attack") or nameLower:find("hit") or nameLower:find("strike") or nameLower:find("slash") then
                        pcall(function() obj:FireServer(closest.Character) end)
                        pcall(function() obj:InvokeServer(closest.Character) end)
                    end
                end
            end
        end
    end

    -- ==================
    -- AUTO GENERATOR
    -- ==================
    if Config.AutoGenerator then
        -- Find nearby generator and auto-complete skill check
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local nameLower = obj.Name:lower()
                if (nameLower:find("generator") or nameLower:find("gen")) then
                    local dist = (obj.Position - HumanoidRootPart.Position).Magnitude
                    if dist < 10 then
                        -- Try to fire skill check completion
                        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                                local rn = remote.Name:lower()
                                if rn:find("skillcheck") or rn:find("skill") or rn:find("check") or rn:find("repair") or rn:find("progress") then
                                    pcall(function()
                                        if Config.GenMode == "Perfect" then
                                            remote:FireServer(obj, true, 1.0)
                                        else
                                            remote:FireServer(obj, false, 0.5)
                                        end
                                    end)
                                    pcall(function()
                                        if Config.GenMode == "Perfect" then
                                            remote:InvokeServer(obj, true, 1.0)
                                        else
                                            remote:InvokeServer(obj, false, 0.5)
                                        end
                                    end)
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
    end

    -- ==================
    -- BOOST ALL GEN
    -- ==================
    if Config.BoostAllGen then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local nameLower = obj.Name:lower()
                if (nameLower:find("generator") or nameLower:find("gen")) and not nameLower:find("complete") then
                    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                            local rn = remote.Name:lower()
                            if rn:find("gen") or rn:find("progress") or rn:find("repair") or rn:find("fix") then
                                pcall(function() remote:FireServer(obj, 100) end)
                                pcall(function() remote:InvokeServer(obj, 100) end)
                            end
                        end
                    end
                end
            end
        end
    end

    -- ==================
    -- SELF UNHOOK
    -- ==================
    if Config.SelfUnHook then
        -- Check if hooked
        pcall(function()
            for _, val in ipairs(Character:GetChildren()) do
                if val:IsA("BoolValue") or val:IsA("IntValue") or val:IsA("NumberValue") then
                    local n = val.Name:lower()
                    if n:find("hook") or n:find("sacrifice") then
                        -- Fire unhook attempts rapidly
                        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                                local rn = remote.Name:lower()
                                if rn:find("unhook") or rn:find("escape") or rn:find("struggle") or rn:find("wiggle") then
                                    -- 100% chance manipulation
                                    pcall(function()
                                        for i = 1, 5 do
                                            remote:FireServer(1.0)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- FALL DAMAGE PREVENTION (State Changed)
-- ============================================================
Humanoid.StateChanged:Connect(function(oldState, newState)
    if Config.AntiFallDmg and newState == Enum.HumanoidStateType.Landed then
        pcall(function()
            HumanoidRootPart.Velocity = Vector3.new(HumanoidRootPart.Velocity.X, 0, HumanoidRootPart.Velocity.Z)
        end)
    end

    if Config.AntiKnock and newState == Enum.HumanoidStateType.Ragdoll then
        pcall(function()
            Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            task.delay(0.1, function()
                Humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end)
    end

    if Config.AntiStun and newState == Enum.HumanoidStateType.Stunned then
        pcall(function()
            Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end)

-- ============================================================
-- GOD MODE - Health Changed Hook
-- ============================================================
if hookfunction then
    pcall(function()
        local oldHealth = Humanoid.Health
        Humanoid.HealthChanged:Connect(function(newHealth)
            if Config.GodMode and newHealth < oldHealth then
                Humanoid.Health = Humanoid.MaxHealth
            end
            oldHealth = newHealth
        end)
    end)
end

-- ============================================================
-- ANTI-BLIND - Lighting Monitor
-- ============================================================
RunService.RenderStepped:Connect(function()
    if Config.AntiBlind then
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then
                local nameLower = v.Name:lower()
                if nameLower:find("blind") or nameLower:find("fog") or nameLower:find("flash") or nameLower:find("obscure") then
                    v.Enabled = false
                end
            end
        end
        -- Reset fog
        if Lighting.FogEnd < 10000 then
            Lighting.FogEnd = 100000
        end
    end

    if Config.RemoveBlurBloom then
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
    end

    -- Update ESP distances
    if Config.PlayerESP then
        for _, data in ipairs(ESPObjects) do
            local bb = data[1]
            local player = data[3]
            if player and typeof(player) == "Instance" and player:IsA("Player") and bb and bb.Parent then
                local distLabel = bb:FindFirstChild("DistLabel")
                local statusLabel = bb:FindFirstChild("StatusLabel")
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((player.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude)
                    if distLabel then
                        distLabel.Text = dist .. "m"
                    end
                    if statusLabel and player.Character:FindFirstChild("Humanoid") then
                        local hp = player.Character.Humanoid.Health
                        if hp <= 0 then
                            statusLabel.Text = "DEAD"
                            statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                        else
                            statusLabel.Text = "HP: " .. math.floor(hp)
                            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- KEYBINDS (Mobile Friendly Toggle Button)
-- ============================================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 44, 0, 44)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -22)
toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 140)
toggleBtn.Text = "H"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = UI:GetScreenGui()

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(1, 0)
tbCorner.Parent = toggleBtn

local mainFrameRef = UI:GetScreenGui():FindFirstChild("MainFrame")

toggleBtn.MouseButton1Click:Connect(function()
    if mainFrameRef then
        mainFrameRef.Visible = not mainFrameRef.Visible
    end
end)

-- Keyboard shortcut
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.LeftControl then
        if mainFrameRef then
            mainFrameRef.Visible = not mainFrameRef.Visible
        end
    end
    -- FPP/TPP toggle on Key
    if input.KeyCode == Enum.KeyCode.V then
        Config.FPP = not Config.FPP
        if Config.FPP then
            pcall(function() Camera.CameraType = Enum.CameraType.LockFirstPerson end)
        else
            pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
        end
    end
end)

-- ============================================================
-- INITIALIZATION COMPLETE
-- ============================================================
Notify("Script Hub", "Berhasil dimuat! Semua fitur siap.", 5)
print("=============================================")
print("  SCRIPT HUB - Successfully Loaded!")
print("  Toggle GUI: Right Ctrl / Mobile Button")
print("  FPP/TPP: V key")
print("=============================================")
