--[[
    ============================================================
    VIOLENCE DISTRICT (DISTRIK KEKERASAN) - ROBLOX SCRIPT
    ============================================================
    Version: 5.1.0 (Fixed — WindUI + Fallback UI)
    Game: Violence District (Distrik Kekerasan)
    UI Library: WindUI by Footagesus (.ftgs) — with Builtin Fallback
    
    FIXES v5.1:
      - WindUI loading sekarang pcall setiap step (tidak crash)
      - Fallback UI otomatis jika WindUI gagal load
      - Console log di setiap step untuk debug
    
    TABS:
      VIP | Survivor | Killer | Visuals | Combat | Utility
    
    ERROR HANDLING: All features wrapped in pcall() / SafeCall.
    ============================================================
--]]

-- ═══════════════════════════════════════════════════════════════════════
--  SERVICES (dimuat paling awal sebelum apapun)
-- ═══════════════════════════════════════════════════════════════════════

local cloneref = (cloneref or clonereference or function(i) return i end)

local Players          = cloneref(game:GetService("Players"))
local RunService       = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace        = cloneref(game:GetService("Workspace"))
local TweenService     = cloneref(game:GetService("TweenService"))
local Lighting         = cloneref(game:GetService("Lighting"))
local Camera           = Workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════════
--  STEP 1: LOAD WINDUI (5 fallback methods, SEMUANYA pcall)
-- ═══════════════════════════════════════════════════════════════════════

local WindUI = nil
local WindUILoaded = false
local WindUIError = ""

print("[VD] Step 1: Loading UI Library...")

-- Method 1: require local path (Studio / executor dengan file system)
if not WindUI then
    local ok, err = pcall(function()
        WindUI = require("./src/Init")
        print("[VD]   -> Method 1 OK: require('./src/Init')")
    end)
    if not ok then
        print("[VD]   -> Method 1 FAIL: " .. tostring(err))
        WindUIError = WindUIError .. "M1 "
    end
end

-- Method 2: require dari ReplicatedStorage (kalau ada)
if not WindUI then
    local ok, err = pcall(function()
        WindUI = require(ReplicatedStorage:WaitForChild("WindUI", 3):WaitForChild("Init", 3))
        print("[VD]   -> Method 2 OK: ReplicatedStorage/WindUI/Init")
    end)
    if not ok then
        print("[VD]   -> Method 2 FAIL: " .. tostring(err))
        WindUIError = WindUIError .. "M2 "
    end
end

-- Method 3: loadstring HTTP — URL utama
if not WindUI then
    local ok, err = pcall(function()
        local code = game:HttpGet("https://raw.githubusercontent.com/FajarFnyaFerrary/District/main/dist/main.lua", 15)
        if code and #code > 100 then
            WindUI = loadstring(code)()
            print("[VD]   -> Method 3 OK: HTTP loadstring (primary URL)")
        else
            error("HTTP response too short or empty")
        end
    end)
    if not ok then
        print("[VD]   -> Method 3 FAIL: " .. tostring(err))
        WindUIError = WindUIError .. "M3 "
    end
end

-- Method 4: loadstring HTTP — mirror URL
if not WindUI then
    local ok, err = pcall(function()
        local code = game:HttpGet("https://pastebin.com/raw/WindUIInit", 10)
        if code and #code > 100 then
            WindUI = loadstring(code)()
            print("[VD]   -> Method 4 OK: HTTP loadstring (mirror)")
        else
            error("HTTP response too short or empty")
        end
    end)
    if not ok then
        print("[VD]   -> Method 4 FAIL: " .. tostring(err))
        WindUIError = WindUIError .. "M4 "
    end
end

-- Method 5: cek library yang sudah ada di memory (beberapa executor inject otomatis)
if not WindUI then
    local ok, err = pcall(function()
        -- Cek apakah ada global WindUI
        if getgenv and getgenv().WindUI then
            WindUI = getgenv().WindUI
            print("[VD]   -> Method 5 OK: getgenv().WindUI")
        elseif _G and _G.WindUI then
            WindUI = _G.WindUI
            print("[VD]   -> Method 5 OK: _G.WindUI")
        else
            error("No global WindUI found")
        end
    end)
    if not ok then
        print("[VD]   -> Method 5 FAIL: " .. tostring(err))
        WindUIError = WindUIError .. "M5 "
    end
end

if WindUI then
    WindUILoaded = true
    print("[VD] WindUI loaded successfully!")
else
    print("[VD] ALL WindUI methods FAILED. Using Fallback UI.")
    print("[VD] Failed methods: " .. WindUIError)
end

-- ═══════════════════════════════════════════════════════════════════════
--  STEP 2: BUILD UI — WindUI atau Fallback Builtin
-- ═══════════════════════════════════════════════════════════════════════

local Window = nil
local UsingFallback = false

if WindUILoaded then
    -- ═══════════════════════════════════════════════════════════
    --  WINDUI MODE
    -- ═══════════════════════════════════════════════════════════
    print("[VD] Creating WindUI Window...")
    local ok, err = pcall(function()
        Window = WindUI:CreateWindow({
            Title = "Violence District",
            Author = "v5.1 by Zetttify",
            Icon = "solar:compass-big-bold",
            Theme = "Dark",
            NewElements = true,
            Transparent = true,
            ToggleKey = Enum.KeyCode.RightControl,
            Acrylic = true,
        })

        Window:Tag({
            Title = "PREMIUM",
            Color = "Text",
        })

        Window.Topbar:Button({
            Name = "Unload",
            Icon = "sfsymbols:printerFill",
            IconSize = 22,
            Callback = function() Window:Destroy() end,
        })
    end)
    if not ok then
        print("[VD] WindUI CreateWindow FAILED: " .. tostring(err))
        print("[VD] Falling back to builtin UI...")
        WindUILoaded = false
        UsingFallback = true
    else
        print("[VD] WindUI Window created!")
    end
end

if not WindUILoaded then
    -- ═══════════════════════════════════════════════════════════
    --  FALLBACK BUILTIN UI (ScreenGui — pasti jalan di semua executor)
    -- ═══════════════════════════════════════════════════════════
    UsingFallback = true
    print("[VD] Building Fallback Builtin UI...")

    -- Abstraction layer: Window, Tab, Section, Toggle, Slider, Button, Space, Group, Dropdown, Notify
    -- Semua return table dengan method yang sama persis

    local FBGui = Instance.new("ScreenGui")
    FBGui.Name = "VD_Hub"
    FBGui.ResetOnSpawn = false
    FBGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() FBGui.Parent = game:GetService("CoreGui") end)
    if not FBGui.Parent then FBGui.Parent = LocalPlayer.PlayerGui end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 520, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = FBGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    -- Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 38)
    TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Violence District v5.1"
    TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 24)
    CloseBtn.Position = UDim2.new(1, -38, 0, 7)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    CloseBtn.TextSize = 12
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

    -- Tag badge
    local TagLabel = Instance.new("TextLabel")
    TagLabel.Size = UDim2.new(0, 55, 0, 18)
    TagLabel.Position = UDim2.new(1, -100, 0, 10)
    TagLabel.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
    TagLabel.Text = "PREMIUM"
    TagLabel.TextColor3 = Color3.new(1, 1, 1)
    TagLabel.TextSize = 10
    TagLabel.Font = Enum.Font.GothamBold
    TagLabel.BorderSizePixel = 0
    TagLabel.Parent = TitleBar
    Instance.new("UICorner", TagLabel).CornerRadius = UDim.new(0, 4)

    -- Tab bar (horizontal di bawah title)
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, 0, 0, 32)
    TabBar.Position = UDim2.new(0, 0, 0, 38)
    TabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    TabBar.BorderSizePixel = 0
    TabBar.Parent = MainFrame

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 2)
    TabLayout.Parent = TabBar

    -- Content area (ScrollingFrame)
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "Content"
    ContentFrame.Size = UDim2.new(1, -16, 1, -82)
    ContentFrame.Position = UDim2.new(0, 8, 0, 74)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 4
    ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ContentFrame.Parent = MainFrame
    Instance.new("UIListLayout", ContentFrame).Padding = UDim.new(0, 4)
    Instance.new("UIPadding", ContentFrame).PaddingTop = UDim.new(0, 4)

    -- State
    local FBVisible = true
    local tabs = {}
    local currentTab = nil
    local tabCount = 0

    CloseBtn.MouseButton1Click:Connect(function()
        FBVisible = not FBVisible
        MainFrame.Visible = FBVisible
    end)

    -- Toggle GUI with RightCtrl
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            FBVisible = not FBVisible
            MainFrame.Visible = FBVisible
        end
    end)

    -- Helper: create a section label
    local function makeSection(text, desc)
        local sf = Instance.new("Frame")
        sf.Size = UDim2.new(1, 0, 0, desc and 36 or 24)
        sf.BackgroundColor3 = Color3.fromRGB(35, 35, 44)
        sf.BorderSizePixel = 0
        sf.Parent = ContentFrame
        Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -12, 0, 16)
        lbl.Position = UDim2.new(0, 8, desc and UDim.new(0, 4) or UDim.new(0, 4))
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(180, 180, 255)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = sf

        if desc then
            local dl = Instance.new("TextLabel")
            dl.Size = UDim2.new(1, -12, 0, 12)
            dl.Position = UDim2.new(0, 8, 0, 20)
            dl.BackgroundTransparency = 1
            dl.Text = desc
            dl.TextColor3 = Color3.fromRGB(130, 130, 150)
            dl.TextSize = 10
            dl.Font = Enum.Font.Gotham
            dl.TextXAlignment = Enum.TextXAlignment.Left
            dl.TextWrapped = true
            dl.Parent = sf
        end
    end

    -- Helper: create a toggle
    local function makeToggle(title, value, callback)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        f.BorderSizePixel = 0
        f.Parent = ContentFrame
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -80, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 22)
        btn.Position = UDim2.new(1, -60, 0.5, -11)
        btn.BackgroundColor3 = value and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(60, 60, 70)
        btn.Text = value and "ON" or "OFF"
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            value = not value
            btn.BackgroundColor3 = value and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(60, 60, 70)
            btn.Text = value and "ON" or "OFF"
            if callback then callback(value) end
        end)
    end

    -- Helper: create a slider
    local function makeSlider(title, min, max, default, step, callback)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 44)
        f.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        f.BorderSizePixel = 0
        f.Parent = ContentFrame
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -80, 0, 16)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = title .. ": " .. tostring(default)
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f

        local valBox = Instance.new("TextBox")
        valBox.Size = UDim2.new(0, 50, 0, 20)
        valBox.Position = UDim2.new(1, -60, 0, 4)
        valBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        valBox.Text = tostring(default)
        valBox.TextColor3 = Color3.fromRGB(220, 220, 255)
        valBox.TextSize = 11
        valBox.Font = Enum.Font.Gotham
        valBox.BorderSizePixel = 0
        valBox.Parent = f
        Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 4)

        local minusBtn = Instance.new("TextButton")
        minusBtn.Size = UDim2.new(0, 28, 0, 20)
        minusBtn.Position = UDim2.new(0, 10, 0, 22)
        minusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        minusBtn.Text = "-"
        minusBtn.TextColor3 = Color3.new(1, 1, 1)
        minusBtn.TextSize = 12
        minusBtn.Font = Enum.Font.GothamBold
        minusBtn.BorderSizePixel = 0
        minusBtn.Parent = f
        Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 4)

        local plusBtn = Instance.new("TextButton")
        plusBtn.Size = UDim2.new(0, 28, 0, 20)
        plusBtn.Position = UDim2.new(0, 42, 0, 22)
        plusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        plusBtn.Text = "+"
        plusBtn.TextColor3 = Color3.new(1, 1, 1)
        plusBtn.TextSize = 12
        plusBtn.Font = Enum.Font.GothamBold
        plusBtn.BorderSizePixel = 0
        plusBtn.Parent = f
        Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)

        local currentVal = default

        local function updateVal(v)
            v = math.clamp(math.round(v / step) * step, min, max)
            currentVal = v
            valBox.Text = tostring(v)
            lbl.Text = title .. ": " .. tostring(v)
            if callback then callback(v) end
        end

        minusBtn.MouseButton1Click:Connect(function() updateVal(currentVal - step) end)
        plusBtn.MouseButton1Click:Connect(function() updateVal(currentVal + step) end)

        valBox.FocusLost:Connect(function()
            local num = tonumber(valBox.Text)
            if num then updateVal(num) else valBox.Text = tostring(currentVal) end
        end)
    end

    -- Helper: create a button
    local function makeButton(title, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        btn.Text = title
        btn.TextColor3 = Color3.fromRGB(200, 200, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = ContentFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
    end

    -- Helper: create a dropdown
    local function makeDropdown(title, value, values, callback)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 28)
        f.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        f.BorderSizePixel = 0
        f.Parent = ContentFrame
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 120, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = title .. ":"
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 0, 22)
        btn.Position = UDim2.new(0, 130, 0.5, -11)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        btn.Text = value
        btn.TextColor3 = Color3.fromRGB(220, 220, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        local idx = 1
        for i, v in ipairs(values) do
            if v == value then idx = i; break end
        end

        btn.MouseButton1Click:Connect(function()
            idx = idx % #values + 1
            btn.Text = values[idx]
            if callback then callback(values[idx]) end
        end)
    end

    -- Space helper (adds vertical space)
    local function makeSpace(h)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, h or 6)
        f.BackgroundTransparency = 1
        f.Parent = ContentFrame
    end

    -- Build abstraction Window
    Window = {}

    function Window:Tag(opts)
        -- Already shown via TagLabel
    end

    function Window:Tab(opts)
        tabCount = tabCount + 1
        local tabName = opts.Title
        local tabFrame = Instance.new("Frame")
        tabFrame.Name = "Tab_" .. tabName
        tabFrame.Visible = false
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Parent = ContentFrame.Parent
        tabFrame.Position = ContentFrame.Position
        -- We'll swap ContentFrame children

        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "TabBtn_" .. tabName
        tabBtn.Size = UDim2.new(1, 0, 1, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
        tabBtn.TextSize = 11
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.LayoutOrder = tabCount
        tabBtn.Parent = TabBar

        tabs[tabName] = { button = tabBtn, elements = {} }

        local tabObj = {}

        function tabObj:Select()
            -- select this tab
            for name, data in pairs(tabs) do
                data.button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                data.button.TextColor3 = Color3.fromRGB(160, 160, 180)
            end
            tabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 85)
            tabBtn.TextColor3 = Color3.fromRGB(220, 220, 255)
            -- Clear content, show this tab's elements
            for _, child in ipairs(ContentFrame:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
                    child:Destroy()
                end
            end
            for _, elem in ipairs(tabs[tabName].elements) do
                elem.Parent = ContentFrame
            end
        end

        tabBtn.MouseButton1Click:Connect(function()
            tabObj:Select()
        end)

        function tabObj:Section(opts)
            table.insert(tabs[tabName].elements, (function()
                local sf = Instance.new("Frame")
                sf.Size = UDim2.new(1, 0, 0, opts.Desc and 36 or 24)
                sf.BackgroundColor3 = Color3.fromRGB(35, 35, 44)
                sf.BorderSizePixel = 0
                sf.Parent = Workspace -- temp parent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -12, 0, 16)
                lbl.Position = UDim2.new(0, 8, 0, 4)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Title or ""
                lbl.TextColor3 = Color3.fromRGB(180, 180, 255)
                lbl.TextSize = 13
                lbl.Font = Enum.Font.GothamBold
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = sf

                if opts.Desc then
                    local dl = Instance.new("TextLabel")
                    dl.Size = UDim2.new(1, -12, 0, 12)
                    dl.Position = UDim2.new(0, 8, 0, 20)
                    dl.BackgroundTransparency = 1
                    dl.Text = opts.Desc
                    dl.TextColor3 = Color3.fromRGB(130, 130, 150)
                    dl.TextSize = 10
                    dl.Font = Enum.Font.Gotham
                    dl.TextXAlignment = Enum.TextXAlignment.Left
                    dl.TextWrapped = true
                    dl.Parent = sf
                end

                Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 4)
                return sf
            end)())
        end

        function tabObj:Space()
            table.insert(tabs[tabName].elements, (function()
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, 0, 0, 4)
                f.BackgroundTransparency = 1
                f.Parent = Workspace
                return f
            end)())
        end

        function tabObj:Group()
            local g = {}
            function g:Toggle(opts)
                table.insert(tabs[tabName].elements, (function()
                    local f = Instance.new("Frame")
                    f.Size = UDim2.new(1, 0, 0, 30)
                    f.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
                    f.BorderSizePixel = 0
                    f.Parent = Workspace
                    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -80, 1, 0)
                    lbl.Position = UDim2.new(0, 10, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = opts.Title or ""
                    lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
                    lbl.TextSize = 12
                    lbl.Font = Enum.Font.Gotham
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = f

                    local val = opts.Value or false
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(0, 50, 0, 22)
                    btn.Position = UDim2.new(1, -60, 0.5, -11)
                    btn.BackgroundColor3 = val and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(60, 60, 70)
                    btn.Text = val and "ON" or "OFF"
                    btn.TextColor3 = Color3.new(1, 1, 1)
                    btn.TextSize = 10
                    btn.Font = Enum.Font.GothamBold
                    btn.BorderSizePixel = 0
                    btn.Parent = f
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

                    btn.MouseButton1Click:Connect(function()
                        val = not val
                        btn.BackgroundColor3 = val and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(60, 60, 70)
                        btn.Text = val and "ON" or "OFF"
                        if opts.Callback then opts.Callback(val) end
                    end)

                    return f
                end)())
            end

            function g:Button(opts)
                table.insert(tabs[tabName].elements, (function()
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, 28)
                    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
                    btn.Text = opts.Title or "Button"
                    btn.TextColor3 = Color3.fromRGB(200, 200, 255)
                    btn.TextSize = 12
                    btn.Font = Enum.Font.GothamBold
                    btn.BorderSizePixel = 0
                    btn.Parent = Workspace
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                    if opts.Callback then
                        btn.MouseButton1Click:Connect(opts.Callback)
                    end
                    return btn
                end)())
            end

            function g:Space()
                table.insert(tabs[tabName].elements, (function()
                    local f = Instance.new("Frame")
                    f.Size = UDim2.new(1, 0, 0, 4)
                    f.BackgroundTransparency = 1
                    f.Parent = Workspace
                    return f
                end)())
            end

            return g
        end

        function tabObj:Toggle(opts)
            table.insert(tabs[tabName].elements, (function()
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, 0, 0, 30)
                f.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
                f.BorderSizePixel = 0
                f.Parent = Workspace
                Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -80, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Title or ""
                lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
                lbl.TextSize = 12
                lbl.Font = Enum.Font.Gotham
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = f

                local val = opts.Value or false
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 50, 0, 22)
                btn.Position = UDim2.new(1, -60, 0.5, -11)
                btn.BackgroundColor3 = val and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(60, 60, 70)
                btn.Text = val and "ON" or "OFF"
                btn.TextColor3 = Color3.new(1, 1, 1)
                btn.TextSize = 10
                btn.Font = Enum.Font.GothamBold
                btn.BorderSizePixel = 0
                btn.Parent = f
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

                btn.MouseButton1Click:Connect(function()
                    val = not val
                    btn.BackgroundColor3 = val and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(60, 60, 70)
                    btn.Text = val and "ON" or "OFF"
                    if opts.Callback then opts.Callback(val) end
                end)

                return f
            end)())
        end

        function tabObj:Slider(opts)
            local minV = opts.Value and opts.Value.Min or 0
            local maxV = opts.Value and opts.Value.Max or 100
            local defV = opts.Value and opts.Value.Default or 50
            local stepV = opts.Step or 1

            table.insert(tabs[tabName].elements, (function()
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, 0, 0, 44)
                f.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
                f.BorderSizePixel = 0
                f.Parent = Workspace
                Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -80, 0, 16)
                lbl.Position = UDim2.new(0, 10, 0, 4)
                lbl.BackgroundTransparency = 1
                lbl.Text = (opts.Title or "Slider") .. ": " .. tostring(defV)
                lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
                lbl.TextSize = 12
                lbl.Font = Enum.Font.Gotham
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = f

                local valBox = Instance.new("TextBox")
                valBox.Size = UDim2.new(0, 50, 0, 20)
                valBox.Position = UDim2.new(1, -60, 0, 4)
                valBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                valBox.Text = tostring(defV)
                valBox.TextColor3 = Color3.fromRGB(220, 220, 255)
                valBox.TextSize = 11
                valBox.Font = Enum.Font.Gotham
                valBox.BorderSizePixel = 0
                valBox.Parent = f
                Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 4)

                local minusBtn = Instance.new("TextButton")
                minusBtn.Size = UDim2.new(0, 28, 0, 20)
                minusBtn.Position = UDim2.new(0, 10, 0, 22)
                minusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
                minusBtn.Text = "-"
                minusBtn.TextColor3 = Color3.new(1, 1, 1)
                minusBtn.TextSize = 12
                minusBtn.Font = Enum.Font.GothamBold
                minusBtn.BorderSizePixel = 0
                minusBtn.Parent = f
                Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 4)

                local plusBtn = Instance.new("TextButton")
                plusBtn.Size = UDim2.new(0, 28, 0, 20)
                plusBtn.Position = UDim2.new(0, 42, 0, 22)
                plusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
                plusBtn.Text = "+"
                plusBtn.TextColor3 = Color3.new(1, 1, 1)
                plusBtn.TextSize = 12
                plusBtn.Font = Enum.Font.GothamBold
                plusBtn.BorderSizePixel = 0
                plusBtn.Parent = f
                Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)

                local curVal = defV
                local function upd(v)
                    v = math.clamp(math.round(v / stepV) * stepV, minV, maxV)
                    curVal = v
                    valBox.Text = tostring(v)
                    lbl.Text = (opts.Title or "Slider") .. ": " .. tostring(v)
                    if opts.Callback then opts.Callback(v) end
                end
                minusBtn.MouseButton1Click:Connect(function() upd(curVal - stepV) end)
                plusBtn.MouseButton1Click:Connect(function() upd(curVal + stepV) end)
                valBox.FocusLost:Connect(function()
                    local n = tonumber(valBox.Text)
                    if n then upd(n) else valBox.Text = tostring(curVal) end
                end)

                return f
            end)())
        end

        function tabObj:Button(opts)
            table.insert(tabs[tabName].elements, (function()
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 28)
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
                btn.Text = opts.Title or "Button"
                btn.TextColor3 = Color3.fromRGB(200, 200, 255)
                btn.TextSize = 12
                btn.Font = Enum.Font.GothamBold
                btn.BorderSizePixel = 0
                btn.Parent = Workspace
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                if opts.Callback then
                    btn.MouseButton1Click:Connect(opts.Callback)
                end
                return btn
            end)())
        end

        function tabObj:Dropdown(opts)
            local vals = opts.Values or {}
            local curVal = opts.Value or (vals[1] or "")
            local idx = 1
            for i, v in ipairs(vals) do
                if v == curVal then idx = i; break end
            end

            table.insert(tabs[tabName].elements, (function()
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, 0, 0, 30)
                f.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
                f.BorderSizePixel = 0
                f.Parent = Workspace
                Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -130, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = (opts.Title or "") .. ":"
                lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
                lbl.TextSize = 12
                lbl.Font = Enum.Font.Gotham
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = f

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 100, 0, 22)
                btn.Position = UDim2.new(1, -110, 0.5, -11)
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
                btn.Text = curVal
                btn.TextColor3 = Color3.fromRGB(220, 220, 255)
                btn.TextSize = 11
                btn.Font = Enum.Font.GothamBold
                btn.BorderSizePixel = 0
                btn.Parent = f
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

                btn.MouseButton1Click:Connect(function()
                    idx = idx % #vals + 1
                    btn.Text = vals[idx]
                    if opts.Callback then opts.Callback(vals[idx]) end
                end)

                return f
            end)())
        end

        return tabObj
    end

    function Window:Destroy()
        FBGui:Destroy()
    end

    function Window:ToggleTransparency(v) end
    function Window:SetTitle(t) TitleLabel.Text = t end
    function Window:SetAuthor(a) end

    print("[VD] Fallback UI built successfully!")
end

-- ═══════════════════════════════════════════════════════════════════════
--  NOTIFICATION FUNCTION (works in both modes)
-- ═══════════════════════════════════════════════════════════════════════

local function Notify(opts)
    if WindUILoaded and WindUI then
        pcall(function()
            WindUI:Notify({ Title = opts.Title or "", Content = opts.Content or "" })
        end)
    else
        -- Fallback: show a brief notification in console + hint label
        print("[VD] " .. (opts.Title or "") .. ": " .. (opts.Content or ""))
        SafeCall(function()
            local hint = Instance.new("TextLabel")
            hint.Name = "VD_Notif"
            hint.Size = UDim2.new(0, 300, 0, 50)
            hint.Position = UDim2.new(0.5, -150, 0, 10)
            hint.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
            hint.BackgroundTransparency = 0.2
            hint.BorderSizePixel = 0
            hint.Text = (opts.Title or "") .. "\n" .. (opts.Content or "")
            hint.TextColor3 = Color3.fromRGB(220, 220, 255)
            hint.TextSize = 12
            hint.Font = Enum.Font.GothamBold
            hint.TextWrapped = true
            hint.ZIndex = 999
            pcall(function() hint.Parent = game:GetService("CoreGui") end)
            if not hint.Parent then hint.Parent = LocalPlayer.PlayerGui end
            Instance.new("UICorner", hint).CornerRadius = UDim.new(0, 6)
            game:GetService("Debris"):AddItem(hint, 4)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════

local Config = {
    -- VIP
    AutoPlay         = false,
    AutoPlayFleeDist = 40,
    AutoDagger       = false,
    AutoDaggerRange  = 30,
    WiggleMaster     = false,
    KillerPrediction = false,
    PredictedKiller  = nil,

    -- Survivor
    SpeedBoost       = false,
    CustomSpeed      = 16,
    NoSlowdown       = false,
    NoClip           = false,
    SilentActions    = false,
    AntiFallDamage   = false,
    GodMode          = false,
    AntiKnock        = false,
    AutoHealAura     = false,
    HealAuraRange    = 25,

    -- Killer
    SpearDropPrediction  = false,
    SpearNoGravity       = false,
    AntiBlind            = false,
    AntiStun             = false,
    DoubleDamageGen      = false,
    GenDamageMultiplier  = 3,

    -- Visuals
    PlayerESP       = false,
    ObjectESP       = false,
    GeneratorESP    = false,
    PalletESP       = false,
    ExitGateESP     = false,
    HookESP         = false,
    WindowESP       = false,
    CustomFOV       = false,
    FOVValue        = 70,
    DefaultFOV      = 70,
    ShowCrosshair   = false,
    RemoveBlurBloom = false,
    ForceFullbright = false,
    PotatoMode      = false,

    -- Combat
    Aimbot          = false,
    AimRadius       = 200,
    ShowTargetTracer = false,
    LockOnHighlight = false,
    ExpandHitbox    = false,
    AutoAttack      = false,
    AutoAttackRange = 8,

    -- Automation
    AutoGenerator       = false,
    GenSkillCheckMode   = "Perfect",
    BoostAllGen         = false,
    InstantEscape       = false,
    SelfUnHook          = false,

    -- Utility (NEW)
    AntiAFK             = false,
    AutoPallet          = false,
    AutoPalletRange     = 15,
    SpectatorFreecam   = false,
}

-- ═══════════════════════════════════════════════════════════════════════
--  UTILITY HELPERS
-- ═══════════════════════════════════════════════════════════════════════

local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[VD] Error: " .. tostring(result))
    end
    return success, result
end

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function findRemotes(patterns)
    local results, checked = {}, {}
    for _, src in ipairs({ ReplicatedStorage, Workspace }) do
        for _, obj in pairs(src:GetDescendants()) do
            if obj:IsA("RemoteEvent") and not checked[obj] then
                for _, pat in ipairs(patterns) do
                    if obj.Name:lower():find(pat:lower()) then
                        table.insert(results, obj)
                        checked[obj] = true
                        break
                    end
                end
            end
        end
    end
    return results
end

local function isPlayerKiller(player)
    if not player or not player.Character then return false end
    local role = player:GetAttribute("Role") or player:GetAttribute("Team")
    if role == "Killer" then return true end
    if player.Team and player.Team.Name:lower():find("killer") then return true end
    local function scan(parent)
        for _, item in pairs(parent:GetDescendants()) do
            local n = item.Name:lower()
            if n:find("killer") or n:find("vein") or n:find("spear") or n:find("weapon") then return true end
        end
        return false
    end
    if scan(player.Character) then return true end
    if player.Backpack and scan(player.Backpack) then return true end
    return false
end

local function getKiller()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isPlayerKiller(p) then return p end
    end
    return nil
end

local function findPartsByName(patterns, parent)
    parent = parent or Workspace
    local results = {}
    for _, obj in pairs(parent:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent then
            local n = obj.Name:lower()
            for _, pat in ipairs(patterns) do
                if n:find(pat:lower()) then
                    table.insert(results, obj)
                    break
                end
            end
        end
    end
    return results
end

local function findNearestPart(parts, pos, maxDist)
    local nearest, best = nil, maxDist or math.huge
    for _, p in pairs(parts) do
        if p and p:IsA("BasePart") and p.Parent then
            local d = (p.Position - pos).Magnitude
            if d < best then best, nearest = d, p end
        end
    end
    return nearest, best
end

local function teleportTo(position)
    local root = getRootPart()
    if root then root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) end
end

local function findAimbotTarget()
    local closest, closestDist = nil, Config.AimRadius
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local tp = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
            if tp then
                local sp, on = Camera:WorldToScreenPoint(tp.Position)
                if on then
                    local sd = (Vector2.new(sp.X, sp.Y) - Vector2.new(cx, cy)).Magnitude
                    if sd < closestDist then closestDist, closest = sd, player end
                end
            end
        end
    end
    return closest
end

-- ═══════════════════════════════════════════════════════════════════════
--  LOBBY DETECTION (6 Methods)
-- ═══════════════════════════════════════════════════════════════════════

local function IsInLobby()
    local isInLobby = false
    SafeCall(function()
        local char = LocalPlayer.Character
        if char then
            for _, attrName in ipairs(LocalPlayer:GetAttributes()) do
                local attrVal = LocalPlayer:GetAttribute(attrName)
                if attrVal and type(attrVal) == "string" then
                    local val = string.lower(attrVal)
                    if val:find("lobby") or val:find("waiting") or val:find("queue") or val:find("idle") then
                        isInLobby = true; return
                    end
                    if val:find("playing") or val:find("ingame") or val:find("match") or val:find("started") then
                        isInLobby = false; return
                    end
                end
            end
        end
        for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
            local name = string.lower(obj.Name)
            if name:find("gamestate") or name:find("game_state") or name:find("matchstate") or name:find("phase") then
                if obj:IsA("StringValue") then
                    local val = string.lower(obj.Value or "")
                    if val:find("lobby") or val:find("waiting") or val:find("queue") then
                        isInLobby = true; return
                    end
                elseif obj:IsA("IntValue") or obj:IsA("NumberValue") then
                    if obj.Value == 0 then isInLobby = true; return end
                elseif obj:IsA("BoolValue") then
                    if name:find("ingame") or name:find("started") or name:find("match") then
                        isInLobby = not obj.Value; return
                    end
                end
            end
        end
        for _, obj in ipairs(Workspace:GetChildren()) do
            local name = string.lower(obj.Name)
            if name:find("lobby") or name:find("waiting") or name:find("queue") or name:find("pre_game") then
                isInLobby = true; return
            end
            if name:find("map") and not name:find("lobby") then
                isInLobby = false; return
            end
        end
        if char then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("SpawnLocation") then
                    local spawnName = string.lower(obj.Name)
                    if spawnName:find("lobby") or spawnName:find("wait") then
                        isInLobby = true; return
                    end
                end
            end
        end
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                local statName = string.lower(stat.Name)
                if statName:find("state") or statName:find("status") or statName:find("role") then
                    if stat:IsA("StringValue") then
                        local val = string.lower(stat.Value or "")
                        if val:find("lobby") or val:find("waiting") then
                            isInLobby = true; return
                        elseif val:find("playing") or val:find("killer") or val:find("survivor") then
                            isInLobby = false; return
                        end
                    end
                end
            end
        end
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteFunction") then
                local name = string.lower(obj.Name)
                if name:find("getstate") or name:find("get_state") or name:find("getphase") or name:find("getstatus") then
                    local ok, result = pcall(function() return obj:InvokeServer() end)
                    if ok and result then
                        local val = string.lower(tostring(result))
                        if val:find("lobby") or val:find("waiting") or val:find("queue") or val == "0" then
                            isInLobby = true; return
                        end
                    end
                end
            end
        end
        isInLobby = false
    end)
    return isInLobby
end

-- ═══════════════════════════════════════════════════════════════════════
--  KILLER PREDICTION ENGINE (7 Methods)
-- ═══════════════════════════════════════════════════════════════════════

local CapturedRoleData = {}
local RoleHookActive = false

local function SetupRoleHooks()
    SafeCall(function()
        if RoleHookActive then return end
        RoleHookActive = true
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local name = string.lower(obj.Name)
                if name:find("role") or name:find("assign") or name:find("killer") or name:find("team")
                    or name:find("select") or name:find("pick") or name:find("choose")
                    or name:find("start") or name:find("begin") or name:find("round") then
                    SafeCall(function()
                        local oldNamecall
                        oldNamecall = hookmetamethod(obj, "__namecall", newcclosure(function(self, ...)
                            local method = getnamecallmethod()
                            if method == "FireClient" and self == obj then
                                local args = {...}
                                for i, arg in ipairs(args) do
                                    if type(arg) == "table" then
                                        for k, v in pairs(arg) do
                                            local key = string.lower(tostring(k))
                                            if key:find("killer") or key:find("role") or key:find("team") then
                                                CapturedRoleData[tostring(v)] = string.lower(tostring(v))
                                            end
                                        end
                                    elseif type(arg) == "string" then
                                        local val = string.lower(arg)
                                        if val:find("killer") or val:find("role") or val:find("survivor") then
                                            CapturedRoleData[arg] = val
                                        end
                                    elseif type(arg) == "Instance" and arg:IsA("Player") then
                                        CapturedRoleData[arg.Name] = "assigned"
                                    end
                                end
                            end
                            return oldNamecall(self, ...)
                        end))
                    end)
                end
            elseif obj:IsA("RemoteFunction") then
                local name = string.lower(obj.Name)
                if name:find("role") or name:find("assign") or name:find("killer") or name:find("getrole") then
                    SafeCall(function()
                        local oldNamecall2
                        oldNamecall2 = hookmetamethod(obj, "__namecall", newcclosure(function(self, ...)
                            local method = getnamecallmethod()
                            if method == "InvokeClient" and self == obj then
                                local args = {...}
                                for i, arg in ipairs(args) do
                                    if type(arg) == "string" then
                                        local val = string.lower(arg)
                                        if val:find("killer") then CapturedRoleData[arg] = "killer"
                                        elseif val:find("survivor") then CapturedRoleData[arg] = "survivor" end
                                    elseif type(arg) == "Instance" and arg:IsA("Player") then
                                        CapturedRoleData[arg.Name] = "role_received"
                                    end
                                end
                            end
                            return oldNamecall2(self, ...)
                        end))
                    end)
                end
            end
        end
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteFunction") then
                local name = string.lower(obj.Name)
                if name:find("getrole") or name:find("get_role") or name:find("getkiller")
                    or name:find("get_killer") or name:find("whokiller") or name:find("predict") then
                    SafeCall(function()
                        local ok, result = pcall(function() return obj:InvokeServer() end)
                        if ok and result then
                            if type(result) == "string" then CapturedRoleData[result] = "killer"
                            elseif type(result) == "table" then
                                for k, v in pairs(result) do
                                    CapturedRoleData[tostring(v)] = string.lower(tostring(k))
                                end
                            elseif type(result) == "Instance" and result:IsA("Player") then
                                CapturedRoleData[result.Name] = "killer"
                            end
                        end
                    end)
                end
            end
        end
    end)
end

local function RunKillerPrediction()
    SafeCall(function()
        SetupRoleHooks()
        -- METHOD 1-7 (sama seperti sebelumnya, ringkas)
        for _, player in ipairs(Players:GetPlayers()) do
            SafeCall(function()
                for _, attrName in ipairs(player:GetAttributes()) do
                    local attrVal = player:GetAttribute(attrName)
                    if attrVal and type(attrVal) == "string" then
                        local val = string.lower(attrVal)
                        if val:find("killer") or val:find("slasher") or val:find("murderer") or val:find("hunter") then
                            return true, player
                        end
                    end
                end
                local ls = player:FindFirstChild("leaderstats")
                if ls then
                    for _, stat in ipairs(ls:GetChildren()) do
                        local sn = string.lower(stat.Name)
                        if sn:find("role") or sn:find("team") then
                            if stat:IsA("StringValue") and string.lower(stat.Value or ""):find("killer") then
                                return true, player
                            end
                        end
                    end
                end
                if player.Character then
                    for _, obj in ipairs(player.Character:GetDescendants()) do
                        local n = string.lower(obj.Name or "")
                        if (n:find("role") or n:find("killer")) and (obj:IsA("StringValue") or obj:IsA("ObjectValue")) then
                            if string.lower(tostring(obj.Value or "")):find("killer") then return true, player end
                        end
                        if n:find("iskiller") and obj:IsA("BoolValue") and obj.Value then return true, player end
                    end
                end
            end)
        end
        -- Captured hook data
        SafeCall(function()
            for pn, ri in pairs(CapturedRoleData) do
                if string.lower(tostring(ri)):find("killer") then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if string.lower(p.Name) == string.lower(pn) then return true, p end
                    end
                end
            end
        end)
        -- Backpack weapon
        SafeCall(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local bp = player:FindFirstChild("Backpack")
                    if bp then
                        for _, tool in ipairs(bp:GetChildren()) do
                            if tool:IsA("Tool") then
                                local tn = string.lower(tool.Name)
                                if tn:find("spear") or tn:find("knife") or tn:find("dagger") or tn:find("vein") then
                                    return true, player
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)
    return false, nil
end

SafeCall(function()
    task.spawn(function()
        task.wait(1)
        SetupRoleHooks()
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════
--  BUILD TABS (WindUI & Fallback compatible — API sama)
-- ═══════════════════════════════════════════════════════════════════════

local TabVIP = Window:Tab({ Title = "VIP", Icon = "solar:crown-bold" })
TabVIP:Select()

TabVIP:Section({ Title = "VIP (Ultimate Automatic)", Desc = "Bot cerdas pencari Generator, Auto Parry, Wiggle Master" })
TabVIP:Space()

TabVIP:Toggle({
    Title = "Auto Play (Smart AI)",
    Value = false,
    Callback = function(v)
        Config.AutoPlay = v
        if v then Notify({ Title = "Auto Play", Content = "Bot AI aktif!" }) end
    end,
})

TabVIP:Toggle({
    Title = "Wiggle Master",
    Value = false,
    Callback = function(v)
        Config.WiggleMaster = v
        Notify({ Title = "Wiggle Master", Content = v and "ON" or "OFF" })
    end,
})

TabVIP:Section({ Title = "Flee Distance", Desc = "Jarak kabur dari Killer" })
TabVIP:Slider({
    Step = 5, Value = { Min = 20, Max = 80, Default = 40 },
    Callback = function(value) Config.AutoPlayFleeDist = value end,
})

TabVIP:Section({ Title = "Auto Dagger (Auto Parry)", Desc = "Menangkis serangan Killer secara instan" })

TabVIP:Toggle({
    Title = "Auto Dagger",
    Value = false,
    Callback = function(v)
        Config.AutoDagger = v
        if v then Notify({ Title = "Auto Dagger", Content = "Auto Parry aktif!" }) end
    end,
})

TabVIP:Section({ Title = "Dagger Parry Range" })
TabVIP:Slider({
    Step = 5, Value = { Min = 10, Max = 100, Default = 30 },
    Callback = function(value) Config.AutoDaggerRange = value end,
})

TabVIP:Section({ Title = "Killer Prediction", Desc = "Predict siapa Killer selanjutnya (LOBBY ONLY)" })

TabVIP:Button({
    Title = "Predict Next Killer",
    Callback = function()
        SafeCall(function()
            if not IsInLobby() then
                Notify({ Title = "NOT IN LOBBY", Content = "Fitur ini hanya bisa di Lobby!" })
                return
            end
            Notify({ Title = "SCANNING...", Content = "Menganalisis data game..." })
            task.defer(function()
                local success, predictedPlayer = RunKillerPrediction()
                if success and predictedPlayer then
                    Config.PredictedKiller = predictedPlayer
                    Config.KillerPrediction = true
                    Notify({ Title = "KILLER PREDICTED!", Content = "Killer: " .. predictedPlayer.Name })
                else
                    Notify({ Title = "PREDICTION FAILED", Content = "Tidak bisa memprediksi. Coba lagi." })
                end
            end)
        end)
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 2 — SURVIVOR
-- ═══════════════════════════════════════════════════════════════════════

local TabSurv = Window:Tab({ Title = "Survivor", Icon = "solar:shield-bold" })

TabSurv:Section({ Title = "Movement", Desc = "Kecepatan, NoClip, anti-slowdown" })

TabSurv:Toggle({
    Title = "Speed Boost",
    Value = false,
    Callback = function(v)
        Config.SpeedBoost = v
        if v then
            local h = getHumanoid()
            if h then h.WalkSpeed = Config.CustomSpeed end
        end
    end,
})

TabSurv:Section({ Title = "Custom Speed" })
TabSurv:Slider({
    Step = 1, Value = { Min = 16, Max = 100, Default = 16 },
    Callback = function(value)
        Config.CustomSpeed = value
        if Config.SpeedBoost then
            local h = getHumanoid()
            if h then h.WalkSpeed = value end
        end
    end,
})

TabSurv:Toggle({
    Title = "No Slowdown",
    Value = false,
    Callback = function(v)
        Config.NoSlowdown = v
        if v then Notify({ Title = "No Slowdown", Content = "Kebal semua perlambatan!" }) end
    end,
})

TabSurv:Toggle({
    Title = "No Clip",
    Value = false,
    Callback = function(v)
        Config.NoClip = v
        if v then Notify({ Title = "No Clip", Content = "Menembus dinding aktif!" }) end
    end,
})

TabSurv:Section({ Title = "Anti-Stuck & Silent" })

TabSurv:Toggle({
    Title = "Silent Actions",
    Value = false,
    Callback = function(v)
        Config.SilentActions = v
        if v then Notify({ Title = "Silent Actions", Content = "Gerak tanpa suara!" }) end
    end,
})

TabSurv:Button({
    Title = "Force Reset",
    Callback = function()
        local humanoid = getHumanoid()
        local char = getCharacter()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop() end
        end
        if char then
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BoolValue") and (obj.Name:find("Stun") or obj.Name:find("Stuck") or obj.Name:find("Frozen")) then
                    obj.Value = false
                end
            end
        end
        Notify({ Title = "Reset", Content = "State di-reset!" })
    end,
})

TabSurv:Toggle({
    Title = "Anti Fall Damage",
    Value = false,
    Callback = function(v)
        Config.AntiFallDamage = v
        if v then Notify({ Title = "Anti Fall", Content = "Fall damage off!" }) end
    end,
})

TabSurv:Section({ Title = "Health & Defense", Desc = "God Mode, Heal, Anti Knock, Heal Aura" })

TabSurv:Toggle({
    Title = "Client God Mode",
    Value = false,
    Callback = function(v)
        Config.GodMode = v
        if v then
            SafeCall(function()
                local hum = getHumanoid()
                if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
            end)
            Notify({ Title = "God Mode", Content = "HP selalu penuh!" })
        else
            SafeCall(function()
                local hum = getHumanoid()
                if hum then hum.MaxHealth = 100; hum.Health = 100 end
            end)
        end
    end,
})

TabSurv:Toggle({
    Title = "Anti Knock",
    Value = false,
    Callback = function(v)
        Config.AntiKnock = v
        if v then Notify({ Title = "Anti Knock", Content = "Tidak bisa di-knock!" }) end
    end,
})

TabSurv:Button({
    Title = "Instant Heal",
    Callback = function()
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
            Notify({ Title = "Healed", Content = "HP pulih!" })
        end
    end,
})

TabSurv:Section({ Title = "Auto Heal Aura" })

TabSurv:Toggle({
    Title = "Auto Heal Aura",
    Value = false,
    Callback = function(v)
        Config.AutoHealAura = v
        if v then Notify({ Title = "Heal Aura", Content = "Heal tim otomatis!" }) end
    end,
})

TabSurv:Slider({
    Step = 1, Value = { Min = 10, Max = 80, Default = 25 },
    Callback = function(value) Config.HealAuraRange = value end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 3 — KILLER
-- ═══════════════════════════════════════════════════════════════════════

local TabKill = Window:Tab({ Title = "Killer", Icon = "solar:danger-triangle-bold" })

TabKill:Section({ Title = "Vein Spear", Desc = "Modifikasi tombak: Aimbot prediksi & No Gravity" })

TabKill:Toggle({
    Title = "Drop Prediction",
    Value = false,
    Callback = function(v)
        Config.SpearDropPrediction = v
        if v then Notify({ Title = "Spear Prediction", Content = "Drop compensation aktif!" }) end
    end,
})

TabKill:Toggle({
    Title = "No Gravity",
    Value = false,
    Callback = function(v)
        Config.SpearNoGravity = v
        if v then Notify({ Title = "No Gravity", Content = "Tombak terbang lurus!" }) end
    end,
})

TabKill:Section({ Title = "Killer Defense" })

TabKill:Toggle({
    Title = "Anti-Blind",
    Value = false,
    Callback = function(v)
        Config.AntiBlind = v
        if v then Notify({ Title = "Anti-Blind", Content = "Kebal fog & flash!" }) end
    end,
})

TabKill:Toggle({
    Title = "Anti-Stun",
    Value = false,
    Callback = function(v)
        Config.AntiStun = v
        if v then Notify({ Title = "Anti-Stun", Content = "Tidak bisa di-stun!" }) end
    end,
})

TabKill:Section({ Title = "Generator Attack" })

TabKill:Toggle({
    Title = "Double Damage Generator",
    Value = false,
    Callback = function(v)
        Config.DoubleDamageGen = v
        if v then Notify({ Title = "Double Damage", Content = "Damage multiplier aktif!" }) end
    end,
})

TabKill:Slider({
    Step = 1, Value = { Min = 2, Max = 20, Default = 3 },
    Callback = function(value) Config.GenDamageMultiplier = value end,
})

TabKill:Button({
    Title = "Activate Power",
    Callback = function()
        local remotes = findRemotes({ "Power", "Ability", "Skill", "Special", "Ultimate" })
        if #remotes > 0 then
            for _, remote in pairs(remotes) do pcall(function() remote:FireServer() end) end
            Notify({ Title = "Killer Power", Content = "Power diaktifkan!" })
        else
            Notify({ Title = "Killer Power", Content = "Remote tidak ditemukan" })
        end
    end,
})

TabKill:Button({
    Title = "Teleport to Survivor",
    Callback = function()
        SafeCall(function()
            local targets = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    if root then table.insert(targets, player) end
                end
            end
            if #targets > 0 then
                local t = targets[math.random(1, #targets)]
                local tr = t.Character:FindFirstChild("HumanoidRootPart")
                local mr = getRootPart()
                if tr and mr then mr.CFrame = tr.CFrame * CFrame.new(0, 0, 5) end
                Notify({ Title = "Teleported", Content = "Ke " .. t.Name })
            end
        end)
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 4 — VISUALS
-- ═══════════════════════════════════════════════════════════════════════

local TabVis = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })

TabVis:Section({ Title = "ESP System" })

TabVis:Toggle({
    Title = "Player ESP",
    Value = false,
    Callback = function(v)
        Config.PlayerESP = v
        if v then Notify({ Title = "Player ESP", Content = "Menampilkan pemain!" }) end
    end,
})

TabVis:Toggle({
    Title = "Object ESP (All)",
    Value = false,
    Callback = function(v)
        Config.ObjectESP = v
        if v then
            Config.GeneratorESP = true; Config.PalletESP = true; Config.ExitGateESP = true
            Config.HookESP = true; Config.WindowESP = true
        else
            Config.GeneratorESP = false; Config.PalletESP = false; Config.ExitGateESP = false
            Config.HookESP = false; Config.WindowESP = false
        end
    end,
})

TabVis:Section({ Title = "Individual Object ESP" })

TabVis:Toggle({ Title = "ESP Generator", Value = false, Callback = function(v) Config.GeneratorESP = v end })
TabVis:Toggle({ Title = "ESP Pallet", Value = false, Callback = function(v) Config.PalletESP = v end })
TabVis:Toggle({ Title = "ESP Exit Gate", Value = false, Callback = function(v) Config.ExitGateESP = v end })
TabVis:Toggle({ Title = "ESP Hook", Value = false, Callback = function(v) Config.HookESP = v end })
TabVis:Toggle({ Title = "ESP Window", Value = false, Callback = function(v) Config.WindowESP = v end })

TabVis:Section({ Title = "Camera & FOV" })

TabVis:Toggle({
    Title = "Custom FOV",
    Value = false,
    Callback = function(v)
        Config.CustomFOV = v
        if v then Camera.FieldOfView = Config.FOVValue end
    end,
})

TabVis:Slider({
    Step = 1, Value = { Min = 30, Max = 120, Default = 70 },
    Callback = function(value)
        Config.FOVValue = value
        if Config.CustomFOV then Camera.FieldOfView = value end
    end,
})

TabVis:Section({ Title = "Effects" })

TabVis:Toggle({ Title = "Show Crosshair", Value = false, Callback = function(v) Config.ShowCrosshair = v end })

TabVis:Toggle({
    Title = "Remove Blur/Bloom",
    Value = false,
    Callback = function(v)
        Config.RemoveBlurBloom = v
        if v then Notify({ Title = "Effects Off", Content = "Blur & Bloom dimatikan!" }) end
    end,
})

TabVis:Toggle({
    Title = "Force Fullbright",
    Value = false,
    Callback = function(v)
        Config.ForceFullbright = v
        if v then Notify({ Title = "Fullbright", Content = "Map terang!" }) end
    end,
})

TabVis:Toggle({
    Title = "Potato Mode",
    Value = false,
    Callback = function(v)
        Config.PotatoMode = v
        if v then Notify({ Title = "Potato Mode", Content = "FPS Maksimal!" }) end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 5 — COMBAT
-- ═══════════════════════════════════════════════════════════════════════

local TabComb = Window:Tab({ Title = "Combat", Icon = "solar:target-bold" })

TabComb:Section({ Title = "Aimbot & Targeting" })

TabComb:Toggle({
    Title = "Enable Aimbot",
    Value = false,
    Callback = function(v)
        Config.Aimbot = v
        if v then Notify({ Title = "Aimbot", Content = "Mengunci musuh!" }) end
    end,
})

TabComb:Slider({
    Step = 10, Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(value) Config.AimRadius = value end,
})

TabComb:Section({ Title = "Target Visuals" })

TabComb:Toggle({ Title = "Target Tracer", Value = false, Callback = function(v) Config.ShowTargetTracer = v end })
TabComb:Toggle({ Title = "Lock-On Highlight", Value = false, Callback = function(v) Config.LockOnHighlight = v end })

TabComb:Section({ Title = "Camera & Hitbox" })

TabComb:Button({
    Title = "FPP / TPP",
    Callback = function()
        local h = getHumanoid()
        if h then
            local cur = h.CameraMode
            h.CameraMode = (cur == Enum.CameraMode.LockFirstPerson) and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson
            Notify({ Title = "Camera", Content = h.CameraMode == Enum.CameraMode.LockFirstPerson and "FPP" or "TPP" })
        end
    end,
})

TabComb:Button({
    Title = "Instant Heal",
    Callback = function()
        local h = getHumanoid()
        if h then h.Health = h.MaxHealth; Notify({ Title = "Healed", Content = "HP pulih!" }) end
    end,
})

TabComb:Toggle({
    Title = "Expand Hitbox",
    Value = false,
    Callback = function(v)
        Config.ExpandHitbox = v
        if v then Notify({ Title = "Expand Hitbox", Content = "Hitbox diperbesar!" }) end
    end,
})

TabComb:Toggle({
    Title = "Auto Attack",
    Value = false,
    Callback = function(v)
        Config.AutoAttack = v
        if v then Notify({ Title = "Auto Attack", Content = "Otomatis memukul!" }) end
    end,
})

TabComb:Slider({
    Step = 1, Value = { Min = 3, Max = 25, Default = 8 },
    Callback = function(value) Config.AutoAttackRange = value end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 6 — UTILITY
-- ═══════════════════════════════════════════════════════════════════════

local TabUtil = Window:Tab({ Title = "Utility", Icon = "solar:settings-bold" })

TabUtil:Section({ Title = "Generator" })

TabUtil:Toggle({
    Title = "Auto Generator",
    Value = false,
    Callback = function(v)
        Config.AutoGenerator = v
        if v then Notify({ Title = "Auto Generator", Content = "Mode: " .. Config.GenSkillCheckMode }) end
    end,
})

TabUtil:Dropdown({
    Title = "SkillCheck Mode",
    Value = "Perfect",
    Values = { "Perfect", "Neutral" },
    Callback = function(value)
        Config.GenSkillCheckMode = value
        Notify({ Title = "SkillCheck", Content = "Mode: " .. value })
    end,
})

TabUtil:Toggle({
    Title = "Boost All Gen (Continuous)",
    Value = false,
    Callback = function(v)
        Config.BoostAllGen = v
        if v then Notify({ Title = "Boost Gen", Content = "Semua gen diboost!" }) end
    end,
})

TabUtil:Section({ Title = "Escape & UnHook" })

TabUtil:Toggle({
    Title = "Instant Escape",
    Value = false,
    Callback = function(v)
        Config.InstantEscape = v
        if v then Notify({ Title = "Instant Escape", Content = "Otomatis buka gerbang!" }) end
    end,
})

TabUtil:Toggle({
    Title = "Self UnHook (100%)",
    Value = false,
    Callback = function(v)
        Config.SelfUnHook = v
        if v then Notify({ Title = "Self UnHook", Content = "100% lepas dari Hook!" }) end
    end,
})

TabUtil:Section({ Title = "Anti AFK (NEW)", Desc = "Mencegah kick karena idle" })

TabUtil:Toggle({
    Title = "Anti AFK",
    Value = false,
    Callback = function(v)
        Config.AntiAFK = v
        if v then Notify({ Title = "Anti AFK", Content = "Tidak akan di-kick!" }) end
    end,
})

TabUtil:Section({ Title = "Auto Pallet Drop (NEW)", Desc = "Otomatis jatuhkan Pallet saat Killer mendekat" })

TabUtil:Toggle({
    Title = "Auto Pallet Drop",
    Value = false,
    Callback = function(v)
        Config.AutoPallet = v
        if v then Notify({ Title = "Auto Pallet", Content = "Aktif!" }) end
    end,
})

TabUtil:Slider({
    Step = 1, Value = { Min = 5, Max = 30, Default = 15 },
    Callback = function(value) Config.AutoPalletRange = value end,
})

TabUtil:Section({ Title = "Spectator Freecam (NEW)", Desc = "Kamera bebas saat mati (WASD+Space+Shift)" })

TabUtil:Toggle({
    Title = "Spectator Freecam",
    Value = false,
    Callback = function(v)
        Config.SpectatorFreecam = v
        if v then Notify({ Title = "Freecam", Content = "Spectator cam aktif!" }) end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  OVERLAY GUI (Crosshair, Tracer, Aim Circle)
-- ═══════════════════════════════════════════════════════════════════════

local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "VD_Overlays"
OverlayGui.ResetOnSpawn = false
OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() OverlayGui.Parent = game:GetService("CoreGui") end)
if not OverlayGui.Parent then OverlayGui.Parent = LocalPlayer.PlayerGui end

local CH = Instance.new("Frame")
CH.Name = "Crosshair"
CH.Size = UDim2.new(0, 24, 0, 24)
CH.Position = UDim2.new(0.5, -12, 0.5, -12)
CH.BackgroundTransparency = 1
CH.Visible = false
CH.ZIndex = 100
CH.Parent = OverlayGui

local function mkCF(size, pos, color)
    local f = Instance.new("Frame")
    f.Size = size; f.Position = pos
    f.BackgroundColor3 = color or Color3.new(1, 1, 1)
    f.BorderSizePixel = 0; f.Parent = CH
    return f
end

mkCF(UDim2.new(0, 10, 0, 2), UDim2.new(0.5, -5, 0, 0))
mkCF(UDim2.new(0, 10, 0, 2), UDim2.new(0.5, -5, 1, -2))
mkCF(UDim2.new(0, 2, 0, 10), UDim2.new(0, 0, 0.5, -5))
mkCF(UDim2.new(0, 2, 0, 10), UDim2.new(1, -2, 0.5, -5))
local dot = mkCF(UDim2.new(0, 4, 0, 4), UDim2.new(0.5, -2, 0.5, -2), Color3.fromRGB(220, 40, 40))
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local TracerFrame = Instance.new("Frame")
TracerFrame.Name = "TracerLine"; TracerFrame.Size = UDim2.new(0, 2, 0, 1)
TracerFrame.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
TracerFrame.BorderSizePixel = 0; TracerFrame.BackgroundTransparency = 0.3
TracerFrame.Visible = false; TracerFrame.ZIndex = 90; TracerFrame.Parent = OverlayGui

local TracerOrigin = Instance.new("Frame")
TracerOrigin.Name = "TracerOrigin"; TracerOrigin.Size = UDim2.new(0, 8, 0, 8)
TracerOrigin.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
TracerOrigin.BorderSizePixel = 0; TracerOrigin.Visible = false
TracerOrigin.ZIndex = 91; TracerOrigin.Parent = OverlayGui
Instance.new("UICorner", TracerOrigin).CornerRadius = UDim.new(1, 0)

local AimCircle = Instance.new("Frame")
AimCircle.Name = "AimCircle"; AimCircle.Size = UDim2.new(0, 400, 0, 400)
AimCircle.Position = UDim2.new(0.5, -200, 0.5, -200)
AimCircle.BackgroundColor3 = Color3.new(1, 1, 1)
AimCircle.BackgroundTransparency = 0.92
AimCircle.BorderSizePixel = 1; AimCircle.BorderColor3 = Color3.fromRGB(255, 80, 80)
AimCircle.Visible = false; AimCircle.ZIndex = 89; AimCircle.Parent = OverlayGui
Instance.new("UICorner", AimCircle).CornerRadius = UDim.new(1, 0)

-- ═══════════════════════════════════════════════════════════════════════
--  ESP SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local PlayerESPTable = {}
local ObjectESPTable = {}

local ESP_COLORS = {
    KillerESP = Color3.fromRGB(255, 50, 50), SurvivorESP = Color3.fromRGB(50, 255, 120),
    GenESP = Color3.fromRGB(255, 220, 50), PalletESP = Color3.fromRGB(160, 100, 40),
    GateESP = Color3.fromRGB(0, 220, 255), HookESP = Color3.fromRGB(200, 50, 220),
    WindowESP = Color3.fromRGB(150, 255, 150),
}

local function createPlayerESP(player)
    local char = player.Character
    if not char then return end
    local isKiller = isPlayerKiller(player)
    local color = isKiller and ESP_COLORS.KillerESP or ESP_COLORS.SurvivorESP

    local highlight = Instance.new("Highlight")
    highlight.Name = "VD_ESP"
    highlight.FillTransparency = 0.75; highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = char; highlight.FillColor = color
    highlight.OutlineColor = isKiller and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(100, 255, 150)
    highlight.Parent = char

    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char
    local bb = Instance.new("BillboardGui")
    bb.Name = "VD_ESP_Info"; bb.Size = UDim2.new(0, 220, 0, 55)
    bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.AlwaysOnTop = true; bb.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"; nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
    nameLabel.BackgroundTransparency = 1; nameLabel.TextColor3 = color
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0); nameLabel.TextStrokeTransparency = 0.4
    nameLabel.TextSize = 14; nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = (isKiller and "[KILLER] " or "[SURV] ") .. player.DisplayName
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center; nameLabel.Parent = bb

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"; infoLabel.Size = UDim2.new(1, 0, 0.3, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.45, 0); infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.new(1, 1, 1); infoLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    infoLabel.TextStrokeTransparency = 0.4; infoLabel.TextSize = 11; infoLabel.Font = Enum.Font.Gotham
    infoLabel.Text = "ALIVE | 0m"; infoLabel.TextXAlignment = Enum.TextXAlignment.Center; infoLabel.Parent = bb

    local hBg = Instance.new("Frame")
    hBg.Name = "HealthBarBG"; hBg.Size = UDim2.new(0.8, 0, 0, 4)
    hBg.Position = UDim2.new(0.1, 0, 0.82, 0); hBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hBg.BorderSizePixel = 0; hBg.Parent = bb
    Instance.new("UICorner", hBg).CornerRadius = UDim.new(0, 2)

    local hFill = Instance.new("Frame")
    hFill.Name = "HealthFill"; hFill.Size = UDim2.new(1, 0, 1, 0)
    hFill.BackgroundColor3 = Color3.fromRGB(50, 220, 50); hFill.BorderSizePixel = 0; hFill.Parent = hBg
    Instance.new("UICorner", hFill).CornerRadius = UDim.new(0, 2)

    PlayerESPTable[player] = {
        highlight = highlight, billboard = bb, nameLabel = nameLabel,
        infoLabel = infoLabel, healthFill = hFill, isKiller = isKiller,
    }
end

local function removePlayerESP(player)
    local d = PlayerESPTable[player]
    if d then
        pcall(function() d.highlight:Destroy() end)
        pcall(function() d.billboard:Destroy() end)
        PlayerESPTable[player] = nil
    end
end

local function clearAllPlayerESP()
    for p, _ in pairs(PlayerESPTable) do removePlayerESP(p) end
end

local function createObjectESP()
    for _, obj in pairs(ObjectESPTable) do pcall(function() obj:Destroy() end) end
    ObjectESPTable = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if not (obj:IsA("BasePart") and obj.Parent) then continue end
        local n = obj.Name:lower()
        local objType, color = nil, nil
        if Config.GeneratorESP and (n:find("generator") or (n:find("gen") and not n:find("region"))) then
            objType, color = "Generator", ESP_COLORS.GenESP
        elseif Config.PalletESP and n:find("pallet") then
            objType, color = "Pallet", ESP_COLORS.PalletESP
        elseif Config.ExitGateESP and (n:find("gate") or n:find("exit")) then
            objType, color = "Exit Gate", ESP_COLORS.GateESP
        elseif Config.HookESP and n:find("hook") then
            objType, color = "Hook", ESP_COLORS.HookESP
        elseif Config.WindowESP and n:find("window") then
            objType, color = "Window", ESP_COLORS.WindowESP
        end
        if objType then
            local hl = Instance.new("Highlight")
            hl.Name = "VD_ObjESP"; hl.Adornee = obj
            hl.FillTransparency = 0.85; hl.OutlineTransparency = 0
            hl.FillColor = color; hl.OutlineColor = color; hl.Parent = obj
            local bb = Instance.new("BillboardGui")
            bb.Name = "VD_ObjESP_Label"; bb.Size = UDim2.new(0, 160, 0, 35)
            bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true; bb.Parent = obj
            local lbl = Instance.new("TextLabel")
            lbl.Name = "ObjLabel"; lbl.Size = UDim2.new(1, 0, 0.6, 0); lbl.BackgroundTransparency = 1
            lbl.TextColor3 = color; lbl.TextStrokeColor3 = Color3.new(0, 0, 0); lbl.TextStrokeTransparency = 0.4
            lbl.TextSize = 12; lbl.Font = Enum.Font.GothamBold
            local progress = obj:GetAttribute("Progress") or 0
            lbl.Text = objType .. (objType == "Generator" and (" [" .. math.floor(progress) .. "%]") or "")
            lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.Parent = bb
            table.insert(ObjectESPTable, hl)
            table.insert(ObjectESPTable, bb)
        end
    end
end

local function clearObjectESP()
    for _, obj in pairs(ObjectESPTable) do pcall(function() obj:Destroy() end) end
    ObjectESPTable = {}
end

-- ═══════════════════════════════════════════════════════════════════════
--  SPECTATOR FREECAM
-- ═══════════════════════════════════════════════════════════════════════

local FreecamActive = false
local FreecamPart = nil

local function StartFreecam()
    SafeCall(function()
        FreecamActive = true
        FreecamPart = Instance.new("Part")
        FreecamPart.Name = "VD_FreecamAnchor"
        FreecamPart.Anchored = true; FreecamPart.CanCollide = false
        FreecamPart.Transparency = 1; FreecamPart.Size = Vector3.new(1, 1, 1)
        FreecamPart.Parent = Workspace; FreecamPart.CFrame = Camera.CFrame
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = FreecamPart.CFrame
    end)
end

local function StopFreecam()
    SafeCall(function()
        FreecamActive = false; Camera.CameraType = Enum.CameraType.Custom
        if FreecamPart then FreecamPart:Destroy(); FreecamPart = nil end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════
--  MAIN HEARTBEAT LOOP
-- ═══════════════════════════════════════════════════════════════════════

spawn(function()
    while wait(0.1) do
        local char = getCharacter()
        if not char then continue end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then continue end

        if Config.AutoPlay then
            SafeCall(function()
                local killer = getKiller()
                local kr = killer and killer.Character and (killer.Character:FindFirstChild("HumanoidRootPart") or killer.Character:FindFirstChild("Torso"))
                if kr and (root.Position - kr.Position).Magnitude <= Config.AutoPlayFleeDist then
                    local awayDir = (root.Position - kr.Position).Unit
                    root.CFrame = CFrame.new(root.Position, root.Position + awayDir * 50)
                    humanoid:MoveTo(root.Position + awayDir * 50)
                    if Config.AutoDagger then
                        for _, r in pairs(findRemotes({ "Parry", "Dagger", "Block", "Counter", "Deflect" })) do
                            pcall(function() r:FireServer() end)
                        end
                    end
                    return
                end
                local generators = findPartsByName({ "generator", "gen" })
                local gates = findPartsByName({ "gate", "exit" })
                local best, score = nil, math.huge
                for _, g in pairs(gates) do
                    if g:GetAttribute("Open") or g:GetAttribute("Unlocked") then
                        local s = (g.Position - root.Position).Magnitude
                        if s < score then score, best = s, g end
                    end
                end
                if not best then
                    for _, gen in pairs(generators) do
                        local d = (gen.Position - root.Position).Magnitude
                        local p = gen:GetAttribute("Progress") or 0
                        local s = d - (p * 2)
                        if s < score then score, best = s, gen end
                    end
                end
                if not best and #gates > 0 then best = findNearestPart(gates, root.Position) end
                if best and (best.Position - root.Position).Magnitude > 5 then humanoid:MoveTo(best.Position) end
            end)
        end

        if Config.AutoDagger then
            SafeCall(function()
                local killer = getKiller()
                local kr = killer and killer.Character and (killer.Character:FindFirstChild("HumanoidRootPart") or killer.Character:FindFirstChild("Torso"))
                if kr and (root.Position - kr.Position).Magnitude <= Config.AutoDaggerRange then
                    for _, r in pairs(findRemotes({ "Parry", "Dagger", "Block", "Counter", "Deflect" })) do
                        pcall(function() r:FireServer() end)
                    end
                end
            end)
        end

        if Config.WiggleMaster then
            SafeCall(function()
                local s = humanoid:GetState()
                if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll then
                    for _, r in pairs(findRemotes({ "Wiggle", "Struggle", "Escape", "Break", "Resist" })) do
                        pcall(function() r:FireServer(math.random(0, 3)) end)
                    end
                end
            end)
        end

        if Config.NoSlowdown then
            SafeCall(function()
                if Config.SpeedBoost then
                    if humanoid.WalkSpeed < Config.CustomSpeed then humanoid.WalkSpeed = Config.CustomSpeed end
                else
                    if humanoid.WalkSpeed < 16 then humanoid.WalkSpeed = 16 end
                end
            end)
        end

        if Config.NoClip then
            SafeCall(function()
                for _, bp in ipairs(char:GetDescendants()) do
                    if bp:IsA("BasePart") and bp.CanCollide then bp.CanCollide = false end
                end
            end)
        end

        if Config.AntiFallDamage then
            SafeCall(function()
                if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end

        if Config.GodMode then
            SafeCall(function()
                if humanoid.Health < humanoid.MaxHealth then humanoid.Health = humanoid.MaxHealth end
            end)
        end

        if Config.AntiKnock then
            SafeCall(function()
                local s = humanoid:GetState()
                if s ~= Enum.HumanoidStateType.Running and s ~= Enum.HumanoidStateType.Jumping and s ~= Enum.HumanoidStateType.Freefall then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end

        if Config.AutoHealAura then
            SafeCall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local pR = player.Character:FindFirstChild("HumanoidRootPart")
                        local pH = player.Character:FindFirstChildOfClass("Humanoid")
                        if pR and pH and (pR.Position - root.Position).Magnitude <= Config.HealAuraRange and pH.Health < pH.MaxHealth then
                            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                                if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and string.lower(r.Name):find("heal") then
                                    SafeCall(function() if r:IsA("RemoteEvent") then r:FireServer(player) end end)
                                end
                            end
                        end
                    end
                end
            end)
        end

        if Config.AntiBlind then
            SafeCall(function()
                for _, e in pairs(Lighting:GetChildren()) do
                    if e:IsA("PostEffect") then e.Enabled = false end
                end
            end)
        end

        if Config.AntiStun then
            SafeCall(function()
                local s = humanoid:GetState()
                if s == Enum.HumanoidStateType.Stunned or s == Enum.HumanoidStateType.StunnedNoFall then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end

        if Config.DoubleDamageGen then
            SafeCall(function()
                for _, gen in pairs(findPartsByName({ "generator", "gen" })) do
                    if (gen.Position - root.Position).Magnitude < 10 then
                        for i = 1, Config.GenDamageMultiplier do
                            for _, r in pairs(findRemotes({ "Generator", "Kick", "Damage", "Sabotage", "Break" })) do
                                pcall(function() r:FireServer(gen) end)
                            end
                        end
                    end
                end
            end)
        end

        if Config.AutoGenerator then
            SafeCall(function()
                for _, gen in pairs(findPartsByName({ "generator", "gen" })) do
                    if (gen.Position - root.Position).Magnitude < 12 then
                        for _, r in pairs(findRemotes({ "SkillCheck", "Skill", "Check", "HitZone", "MiniGame" })) do
                            pcall(function()
                                if Config.GenSkillCheckMode == "Perfect" then r:FireServer("Perfect", 1.0)
                                else r:FireServer("Neutral", 0.5) end
                            end)
                        end
                        break
                    end
                end
            end)
        end

        if Config.BoostAllGen then
            SafeCall(function()
                for _, gen in pairs(findPartsByName({ "generator", "gen" })) do
                    gen:SetAttribute("Progress", 100)
                    for _, r in pairs(findRemotes({ "Generator", "Progress", "Repair", "Fix" })) do
                        pcall(function() r:FireServer(gen, 100) end)
                    end
                end
            end)
        end

        if Config.InstantEscape then
            SafeCall(function()
                for _, gate in pairs(findPartsByName({ "gate", "exit", "door" })) do
                    teleportTo(gate.Position)
                    for _, r in pairs(findRemotes({ "Gate", "Exit", "Open", "Escape", "Lever", "Complete" })) do
                        pcall(function() r:FireServer(gate) end)
                    end
                end
            end)
        end

        if Config.SelfUnHook then
            SafeCall(function()
                local s = humanoid:GetState()
                if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll then
                    for _, h in pairs(findPartsByName({ "hook" })) do
                        if (h.Position - root.Position).Magnitude < 8 then
                            for _, r in pairs(findRemotes({ "Hook", "Unhook", "Escape", "Struggle", "SelfUnhook" })) do
                                pcall(function() r:FireServer(h, 1.0, true) end)
                            end
                            break
                        end
                    end
                end
            end)
        end

        if Config.AntiAFK then
            SafeCall(function()
                if tick() % 30 < 0.2 then
                    root.CFrame = root.CFrame + Vector3.new(0, 0.1, 0)
                    task.wait(0.05)
                    root.CFrame = CFrame.new(root.Position - Vector3.new(0, 0.1, 0))
                end
            end)
        end

        if Config.AutoPallet then
            SafeCall(function()
                local killer = getKiller()
                if killer and killer.Character then
                    local kR = killer.Character:FindFirstChild("HumanoidRootPart")
                    if kR and (kR.Position - root.Position).Magnitude <= Config.AutoPalletRange then
                        for _, p in pairs(findPartsByName({ "pallet" })) do
                            if (p.Position - root.Position).Magnitude <= 8 then
                                for _, r in pairs(findRemotes({ "Pallet", "Drop", "Throw", "Break" })) do
                                    pcall(function() r:FireServer(p) end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  RENDER STEPPED LOOP (Visuals & Combat)
-- ═══════════════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
    SafeCall(function()
        CH.Visible = Config.ShowCrosshair

        if Config.Aimbot and Config.ShowTargetTracer then
            local target = findAimbotTarget()
            if target and target.Character then
                local tp = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                if tp then
                    local sp, on = Camera:WorldToScreenPoint(tp.Position)
                    if on then
                        TracerFrame.Visible = true; TracerOrigin.Visible = true
                        local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
                        local dist = math.sqrt((sp.X - cx)^2 + (sp.Y - cy)^2)
                        TracerFrame.Size = UDim2.new(0, 2, 0, dist)
                        TracerFrame.Position = UDim2.new(0.5, -1, 0.5, 0)
                        TracerFrame.Rotation = math.deg(math.atan2(sp.X - cx, sp.Y - cy))
                        TracerOrigin.Position = UDim2.new(0, sp.X - 4, 0, sp.Y - 4)
                    end
                end
            else
                TracerFrame.Visible = false; TracerOrigin.Visible = false
            end
        else
            TracerFrame.Visible = false; TracerOrigin.Visible = false
        end

        AimCircle.Visible = Config.Aimbot

        if Config.Aimbot then
            SafeCall(function()
                local target = findAimbotTarget()
                if target and target.Character then
                    local tp = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                    if tp then Camera.CFrame = CFrame.new(Camera.CFrame.Position, tp.Position) end
                    if Config.LockOnHighlight then
                        local tC = target.Character
                        if not tC:FindFirstChild("VD_LockOn") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "VD_LockOn"; hl.Adornee = tC
                            hl.FillColor = Color3.fromRGB(255, 50, 0); hl.OutlineColor = Color3.fromRGB(255, 200, 0)
                            hl.FillTransparency = 0.6; hl.OutlineTransparency = 0.1; hl.Parent = tC
                        end
                    end
                else
                    if Config.LockOnHighlight then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character then
                                local hl = p.Character:FindFirstChild("VD_LockOn")
                                if hl then hl:Destroy() end
                            end
                        end
                    end
                end
            end)
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hl = p.Character:FindFirstChild("VD_LockOn")
                    if hl then hl:Destroy() end
                end
            end
        end

        if Config.ExpandHitbox then
            SafeCall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        for _, part in ipairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                part.Size = part.Size * 1.01
                                local mx = 20
                                if part.Size.X > mx then part.Size = Vector3.new(mx, part.Size.Y, part.Size.Z) end
                                if part.Size.Y > mx then part.Size = Vector3.new(part.Size.X, mx, part.Size.Z) end
                                if part.Size.Z > mx then part.Size = Vector3.new(part.Size.X, part.Size.Y, mx) end
                            end
                        end
                    end
                end
            end)
        end

        if Config.AutoAttack then
            SafeCall(function()
                local root = getRootPart()
                if not root then return end
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local pR = p.Character:FindFirstChild("HumanoidRootPart")
                        if pR and (pR.Position - root.Position).Magnitude <= Config.AutoAttackRange then
                            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                                if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                                    local rn = string.lower(r.Name)
                                    if rn:find("attack") or rn:find("hit") or rn:find("punch") or rn:find("strike") then
                                        SafeCall(function()
                                            if r:IsA("RemoteEvent") then r:FireServer(p) else r:InvokeServer(p) end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        if Config.ForceFullbright then
            SafeCall(function()
                Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(200, 200, 200); Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            end)
        end

        if Config.RemoveBlurBloom then
            SafeCall(function()
                for _, e in pairs(Lighting:GetChildren()) do
                    if e:IsA("BlurEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect") then
                        e.Enabled = false
                    end
                end
            end)
        end

        if Config.PotatoMode then
            SafeCall(function()
                Lighting.Brightness = 1; Lighting.GlobalShadows = false; Lighting.FogEnd = 100000
                for _, e in pairs(Lighting:GetChildren()) do
                    if e:IsA("PostEffect") then e.Enabled = false end
                end
                settings().QualityLevel = 1
            end)
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════
--  HOOKS
-- ═══════════════════════════════════════════════════════════════════════

SafeCall(function()
    hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.SilentActions then
            local n = string.lower(self.Name)
            if n:find("sound") or n:find("noise") or n:find("footstep") or n:find("alert") then
                if method == "FireServer" or method == "InvokeServer" then return nil end
            end
        end
        return hookmetamethod(game, "__namecall")(...)
    end))
end)

SafeCall(function()
    Workspace.ChildAdded:Connect(function(child)
        SafeCall(function()
            if Config.SpearNoGravity then
                local n = string.lower(child.Name)
                if n:find("spear") or n:find("projectile") or n:find("throw") then
                    for _, obj in ipairs(child:GetDescendants()) do
                        if obj:IsA("BodyVelocity") then
                            obj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            obj.Velocity = obj.Velocity * Vector3.new(1, 0, 1)
                        end
                    end
                end
            end
        end)
    end)
end)

SafeCall(function()
    hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.AutoGenerator then
            local n = string.lower(self.Name)
            if n:find("skillcheck") or n:find("skill_check") or n:find("minigame") then
                if method == "FireServer" then
                    if Config.GenSkillCheckMode == "Perfect" then return self:FireServer("perfect", 1.0)
                    else return self:FireServer("neutral", 0.5) end
                elseif method == "InvokeServer" then
                    if Config.GenSkillCheckMode == "Perfect" then return self:InvokeServer("perfect", 1.0)
                    else return self:InvokeServer("neutral", 0.5) end
                end
            end
        end
        return hookmetamethod(game, "__namecall")(...)
    end))
end)

SafeCall(function()
    hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.DoubleDamageGen then
            local n = string.lower(self.Name)
            if n:find("kick") or n:find("damage") or n:find("gen") or n:find("destroy") or n:find("break") then
                if method == "FireServer" then
                    for i = 2, Config.GenDamageMultiplier do
                        SafeCall(function() self:FireServer(...) end)
                    end
                    return self:FireServer(...)
                end
            end
        end
        return hookmetamethod(game, "__namecall")(...)
    end))
end)

-- ═══════════════════════════════════════════════════════════════════════
--  ESP UPDATE LOOP
-- ═══════════════════════════════════════════════════════════════════════

spawn(function()
    while wait(0.5) do
        if Config.PlayerESP then
            SafeCall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        if not PlayerESPTable[p] then
                            createPlayerESP(p)
                        else
                            local d = PlayerESPTable[p]
                            local pR = p.Character:FindFirstChild("HumanoidRootPart")
                            local myR = getRootPart()
                            if pR and myR and d.infoLabel then
                                local dist = math.floor((pR.Position - myR.Position).Magnitude)
                                local pH = p.Character:FindFirstChildOfClass("Humanoid")
                                local hp = pH and math.floor(pH.Health / pH.MaxHealth * 100) or 100
                                d.infoLabel.Text = "HP:" .. hp .. "% | " .. dist .. "m"
                                if d.healthFill then d.healthFill.Size = UDim2.new(hp / 100, 0, 1, 0) end
                            end
                        end
                    end
                end
            end)
        else
            if next(PlayerESPTable) then clearAllPlayerESP() end
        end

        if Config.GeneratorESP or Config.PalletESP or Config.ExitGateESP or Config.HookESP or Config.WindowESP then
            SafeCall(function() createObjectESP() end)
        else
            if next(ObjectESPTable) then clearObjectESP() end
        end

        if Config.SpectatorFreecam then
            SafeCall(function()
                local h = getHumanoid()
                if h and h.Health <= 0 and not FreecamActive then StartFreecam() end
            end)
        else
            if FreecamActive then StopFreecam() end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  CHARACTER ADDED / REMOVED
-- ═══════════════════════════════════════════════════════════════════════

Players.LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    if Config.PlayerESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then createPlayerESP(p) end
        end
    end
    if Config.SpeedBoost then
        wait(0.5)
        local h = character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Config.CustomSpeed end
    end
    if Config.GodMode then
        SafeCall(function()
            local h = character:FindFirstChildOfClass("Humanoid")
            if h then h.MaxHealth = math.huge; h.Health = math.huge end
        end)
    end
    if FreecamActive then StopFreecam() end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(c)
        wait(1)
        if Config.PlayerESP then createPlayerESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerESP(player)
end)

-- ═══════════════════════════════════════════════════════════════════════
--  KEYBINDS
-- ═══════════════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.H then
        local h = getHumanoid()
        if h then h.Health = h.MaxHealth; Notify({ Title = "Instant Heal", Content = "HP pulih!" }) end
    end
    if input.KeyCode == Enum.KeyCode.R then
        local h = getHumanoid(); local c = getCharacter()
        if h then h:ChangeState(Enum.HumanoidStateType.Running); for _, t in pairs(h:GetPlayingAnimationTracks()) do t:Stop() end end
        if c then for _, o in pairs(c:GetDescendants()) do if o:IsA("BoolValue") and (o.Name:find("Stun") or o.Name:find("Stuck")) then o.Value = false end end end
        Notify({ Title = "Reset", Content = "State di-reset!" })
    end
    if input.KeyCode == Enum.KeyCode.G then
        Config.GodMode = not Config.GodMode
        if Config.GodMode then
            SafeCall(function() local h = getHumanoid(); if h then h.MaxHealth = math.huge; h.Health = math.huge end end)
        else
            SafeCall(function() local h = getHumanoid(); if h then h.MaxHealth = 100; h.Health = 100 end end)
        end
        Notify({ Title = "God Mode", Content = Config.GodMode and "ON" or "OFF" })
    end
    if input.KeyCode == Enum.KeyCode.T then
        local h = getHumanoid()
        if h then
            local cur = h.CameraMode
            h.CameraMode = (cur == Enum.CameraMode.LockFirstPerson) and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson
            Notify({ Title = "Camera", Content = h.CameraMode == Enum.CameraMode.LockFirstPerson and "FPP" or "TPP" })
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  STARTUP NOTIFICATION
-- ═══════════════════════════════════════════════════════════════════════

task.delay(1, function()
    SafeCall(function()
        Notify({
            Title = "Violence District v5.1",
            Content = "Script loaded! "
                .. (UsingFallback and "Fallback UI (WindUI unavailable)" or "WindUI UI")
                .. "\n42 Features | RightCtrl = Toggle",
        })
    end)
end)

print("╔══════════════════════════════════════════════════════════════╗")
print("║   VIOLENCE DISTRICT HUB — v5.1 FIXED                       ║")
print("║   UI: " .. (UsingFallback and "FALLBACK BUILTIN" or "WindUI") .. "                              ║")
print("║   Toggle: RightCtrl | Keybinds: H R G T                   ║")
print("╚══════════════════════════════════════════════════════════════╝")
