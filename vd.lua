--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║          VIOLENCE DISTRICT HUB - ULTIMATE SCRIPT                ║
    ║          (Distrik Kekerasan - Full Feature Script)              ║
    ║                                                                  ║
    ║  Features:                                                       ║
    ║    VIP          -> Auto Play, Auto Dagger, Wiggle Master         ║
    ║    Survivor     -> Speed, God Mode, Anti Knock, Heal Aura        ║
    ║    Killer       -> Spear Prediction, Anti Blind/Stun, Gen Dmg    ║
    ║    Visuals      -> ESP, FOV, Fullbright, Potato Mode             ║
    ║    Combat       -> Aimbot, Tracer, Highlight, Auto Attack        ║
    ║    Automation   -> Auto Gen, Boost All, Instant Escape           ║
    ║                                                                  ║
    ║  Keybinds:                                                       ║
    ║    RightCtrl   -> Toggle GUI                                     ║
    ║    H           -> Instant Heal                                   ║
    ║    R           -> Force Reset State                              ║
    ║    G           -> Toggle God Mode                                ║
    ║    F           -> Toggle FPP/TPP                                 ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                      SERVICES & VARIABLES                       ║
-- ╚══════════════════════════════════════════════════════════════════╝

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")
local StarterGui         = game:GetService("StarterGui")
local SoundService       = game:GetService("SoundService")
local VirtualUser        = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                        CONFIGURATION                            ║
-- ╚══════════════════════════════════════════════════════════════════╝

local Config = {
    -- ══ VIP (ULTIMATE AUTOMATIC) ══
    AutoPlay         = false,
    AutoPlayFleeDist = 40,
    AutoDagger       = false,
    AutoDaggerRange  = 30,
    WiggleMaster     = false,

    -- ══ SURVIVOR (MOVEMENT & HEALTH) ══
    SpeedBoost       = false,
    CustomSpeed      = 16,
    NoSlowdown       = false,
    SilentActions    = false,
    AntiFallDamage   = false,
    GodMode          = false,
    AntiKnock        = false,
    AutoHealAura     = false,
    HealAuraRange    = 25,

    -- ══ KILLER (VEIN KILLER MODIFICATION) ══
    SpearDropPrediction  = false,
    SpearNoGravity       = false,
    AntiBlind            = false,
    AntiStun             = false,
    DoubleDamageGen      = false,
    GenDamageMultiplier  = 3,
    ActivateKillerPower  = false,

    -- ══ VISUALS (ESP & WORLD) ══
    PlayerESP       = false,
    ObjectESP       = false,
    CustomFOV       = false,
    FOVValue        = 70,
    ShowCrosshair   = false,
    RemoveBlurBloom = false,
    ForceFullbright = false,
    PotatoMode      = false,

    -- ══ COMBAT (TARGETING SYSTEM) ══
    Aimbot          = false,
    AimRadius       = 200,
    ShowTargetTracer = false,
    LockOnHighlight = false,
    ExpandHitbox    = false,
    AutoAttack      = false,
    AutoAttackRange = 8,

    -- ══ AUTOMATION (GENERATOR & UTILITY) ══
    AutoGenerator       = false,
    GenSkillCheckMode   = "Perfect",
    BoostAllGen         = false,
    InstantEscape       = false,
    SelfUnHook          = false,
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                     UTILITY FUNCTIONS                          ║
-- ╚══════════════════════════════════════════════════════════════════╝

--- Mendapatkan karakter LocalPlayer
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

--- Mendapatkan Humanoid dari karakter
local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

--- Mendapatkan HumanoidRootPart
local function getRootPart()
    local char = getCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

--- Mendapatkan daftar RemoteEvent yang cocok dengan pola nama
local function findRemotes(patterns)
    local results = {}
    local checked = {}

    -- Cek ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
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

    -- Cek di dalam Workspace (beberapa game menaruh remote di map)
    for _, obj in pairs(Workspace:GetDescendants()) do
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

    return results
end

--- Mendeteksi apakah seorang player adalah Killer
local function isPlayerKiller(player)
    if not player or not player.Character then return false end

    -- Cek via Attribute (Role / Team)
    local role = player:GetAttribute("Role")
    local team = player:GetAttribute("Team")
    if role == "Killer" or team == "Killer" then return true end

    -- Cek via Team service
    if player.Team and player.Team.Name:find("Killer") then return true end

    -- Cek via Backpack/Character tools
    local function checkForKillerItems(parent)
        for _, item in pairs(parent:GetDescendants()) do
            local name = item.Name:lower()
            if name:find("killer") or name:find("vein") or name:find("spear")
                or name:find("weapon") or name:find("blade") then
                return true
            end
        end
        return false
    end

    if checkForKillerItems(player.Character) then return true end
    if player.Backpack and checkForKillerItems(player.Backpack) then return true end

    return false
end

--- Mendapatkan player Killer
local function getKiller()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isPlayerKiller(player) then
            return player
        end
    end
    return nil
end

--- Mendapatkan semua Survivor (selain LocalPlayer dan Killer)
local function getSurvivors()
    local survivors = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character
            and player.Character:FindFirstChildOfClass("Humanoid")
            and not isPlayerKiller(player) then
            table.insert(survivors, player)
        end
    end
    return survivors
end

--- Mencari BasePart terdekat dari kumpulan
local function findNearestPart(parts, position, maxDist)
    local nearest = nil
    local nearestDist = maxDist or math.huge
    for _, part in pairs(parts) do
        if part and part:IsA("BasePart") and part.Parent then
            local dist = (part.Position - position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = part
            end
        end
    end
    return nearest, nearestDist
end

--- Mencari semua BasePart yang namanya mengandung pola tertentu
local function findPartsByName(patterns, parent)
    parent = parent or Workspace
    local results = {}
    for _, obj in pairs(parent:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent then
            local name = obj.Name:lower()
            for _, pat in ipairs(patterns) do
                if name:find(pat:lower()) then
                    table.insert(results, obj)
                    break
                end
            end
        end
    end
    return results
end

--- Teleport karakter ke posisi
local function teleportTo(position)
    local root = getRootPart()
    if root then
        root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end
end

--- Mendapatkan jarak dari karakter ke posisi
local function getDistanceTo(position)
    local root = getRootPart()
    if root then
        return (root.Position - position).Magnitude
    end
    return math.huge
end

--- Mendapatkan target aimbot terdekat (dalam radius layar)
local function findAimbotTarget()
    local closest = nil
    local closestDist = Config.AimRadius
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild("Head")
                or player.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                if onScreen then
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                    if screenDist < closestDist then
                        closestDist = screenDist
                        closest = player
                    end
                end
            end
        end
    end

    return closest
end

--- Mengirim notifikasi di layar
local function notify(text, duration)
    duration = duration or 3
    -- ... (akan diimplementasi setelah GUI dibuat)
end

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    GUI SYSTEM (ScreenGui)                      ║
-- ╚══════════════════════════════════════════════════════════════════╝

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ViolenceDistrictHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Warna tema
local Theme = {
    Background    = Color3.fromRGB(18, 18, 24),
    Panel         = Color3.fromRGB(25, 25, 34),
    TitleBar      = Color3.fromRGB(30, 30, 42),
    Section       = Color3.fromRGB(35, 35, 48),
    Element       = Color3.fromRGB(30, 30, 40),
    Accent        = Color3.fromRGB(220, 40, 40),
    AccentDark    = Color3.fromRGB(160, 25, 25),
    Text          = Color3.fromRGB(220, 220, 230),
    TextDim       = Color3.fromRGB(140, 140, 155),
    Success       = Color3.fromRGB(50, 205, 80),
    Warning       = Color3.fromRGB(255, 180, 50),
    KillerESP     = Color3.fromRGB(255, 50, 50),
    SurvivorESP   = Color3.fromRGB(50, 255, 120),
    GenESP        = Color3.fromRGB(255, 220, 50),
    PalletESP     = Color3.fromRGB(160, 100, 40),
    GateESP       = Color3.fromRGB(0, 220, 255),
    HookESP       = Color3.fromRGB(200, 50, 220),
    TracerColor   = Color3.fromRGB(255, 30, 30),
}

-- ────────── Main Frame ──────────
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 540, 0, 460)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -230)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Border accent (garis bawah judul)
local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 0, 33)
AccentLine.BackgroundColor3 = Theme.Accent
AccentLine.BorderSizePixel = 0
AccentLine.Parent = MainFrame

-- ────────── Title Bar ──────────
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Theme.TitleBar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "  VIOLENCE DISTRICT HUB"
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 5, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Theme.Accent
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close / Minimize Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Size = UDim2.new(0, 32, 0, 24)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = Theme.AccentDark
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ────────── Tab Bar ──────────
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 32)
TabBar.Position = UDim2.new(0, 0, 0, 35)
TabBar.BackgroundColor3 = Theme.Panel
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 2)
TabLayout.Parent = TabBar

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingLeft = UDim.new(0, 5)
TabPadding.PaddingTop = UDim.new(0, 3)
TabPadding.Parent = TabBar

-- ────────── Content Area ──────────
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -12, 1, -78)
ContentFrame.Position = UDim2.new(0, 6, 0, 72)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ClipsDescendants = true
ContentFrame.Parent = MainFrame

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, 0, 1, 0)
ContentScroll.BackgroundTransparency = 1
ContentScroll.ScrollBarThickness = 4
ContentScroll.ScrollBarImageColor3 = Theme.Accent
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroll.BorderSizePixel = 0
ContentScroll.Parent = ContentFrame

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                   GUI BUILDER FUNCTIONS                        ║
-- ╚══════════════════════════════════════════════════════════════════╝

local TabPages = {}

--- Membuat tab baru dan mengembalikan halaman kontennya
local function createTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Text = icon .. " " .. name
    btn.Size = UDim2.new(0, 82, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    btn.TextColor3 = Theme.TextDim
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.AutoButtonColor = true
    btn.Parent = TabBar

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local page = Instance.new("Frame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = ContentScroll

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 4)
    pageLayout.Parent = page

    TabPages[name] = {button = btn, page = page}

    btn.MouseButton1Click:Connect(function()
        for _, data in pairs(TabPages) do
            data.page.Visible = false
            data.button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            data.button.TextColor3 = Theme.TextDim
        end
        page.Visible = true
        btn.BackgroundColor3 = Theme.Accent
        btn.TextColor3 = Color3.new(1, 1, 1)
    end)

    return page
end

--- Membuat header seksi
local function createSection(parent, text, order)
    local label = Instance.new("TextLabel")
    label.Text = "  " .. text
    label.Size = UDim2.new(1, 0, 0, 26)
    label.BackgroundColor3 = Theme.Section
    label.TextColor3 = Theme.Warning
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BorderSizePixel = 0
    label.LayoutOrder = order or 0
    label.Parent = parent

    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 5)
    return label
end

--- Membuat tombol toggle ON/OFF
local function createToggle(parent, text, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Theme.Element
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    frame.Parent = parent

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = frame

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 42, 0, 20)
    toggleBg.Position = UDim2.new(1, -50, 0.5, -10)
    toggleBg.BackgroundColor3 = default and Theme.Success or Color3.fromRGB(55, 55, 65)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame

    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(0, 10)

    local toggleKnob = Instance.new("Frame")
    toggleKnob.Size = UDim2.new(0, 16, 0, 16)
    toggleKnob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    toggleKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Parent = toggleBg

    Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(0, 8)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 42, 0, 20)
    toggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.Parent = frame

    local enabled = default or false

    toggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        toggleBg.BackgroundColor3 = enabled and Theme.Success or Color3.fromRGB(55, 55, 65)
        toggleKnob.Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        if callback then callback(enabled) end
    end)

    return frame
end

--- Membuat slider (penggeser nilai)
local function createSlider(parent, text, min, max, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = Theme.Element
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    frame.Parent = parent

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Text = text .. ": " .. tostring(default)
    label.Size = UDim2.new(1, -20, 0, 22)
    label.Position = UDim2.new(0, 12, 0, 3)
    label.BackgroundTransparency = 1
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = tostring(default)
    valueLabel.Size = UDim2.new(0, 40, 0, 22)
    valueLabel.Position = UDim2.new(1, -50, 0, 3)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -24, 0, 8)
    sliderTrack.Position = UDim2.new(0, 12, 0, 32)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = frame

    Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(0, 4)

    local sliderFill = Instance.new("Frame")
    local fillRatio = (default - min) / (max - min)
    sliderFill.Size = UDim2.new(fillRatio, 0, 1, 0)
    sliderFill.BackgroundColor3 = Theme.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderTrack

    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 4)

    local inputArea = Instance.new("TextButton")
    inputArea.Size = UDim2.new(1, 0, 1, 16)
    inputArea.Position = UDim2.new(0, 0, 0, -4)
    inputArea.BackgroundTransparency = 1
    inputArea.Text = ""
    inputArea.Parent = sliderTrack

    local value = default
    local dragging = false

    local function updateSlider(input)
        local relX = math.clamp(
            (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X,
            0, 1
        )
        value = math.floor(min + (max - min) * relX + 0.5)
        sliderFill.Size = UDim2.new(relX, 0, 1, 0)
        label.Text = text .. ": " .. tostring(value)
        valueLabel.Text = tostring(value)
        if callback then callback(value) end
    end

    inputArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            updateSlider(input)
        end
    end)

    return frame
end

--- Membuat tombol aksi
local function createButton(parent, text, callback, color, order)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = color or Theme.Accent
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order or 0
    btn.AutoButtonColor = true
    btn.Parent = parent

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

--- Membuat label status kecil (untuk mode selector dll)
local function createModeSelector(parent, text, options, defaultIdx, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Theme.Element
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    frame.Parent = parent

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(0, 160, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local currentIdx = defaultIdx or 1
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Text = options[currentIdx]
    modeLabel.Size = UDim2.new(0, 100, 1, 0)
    modeLabel.Position = UDim2.new(0, 180, 0, 0)
    modeLabel.BackgroundTransparency = 1
    modeLabel.TextColor3 = Theme.Warning
    modeLabel.TextSize = 12
    modeLabel.Font = Enum.Font.GothamBold
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeLabel.Parent = frame

    local cycleBtn = Instance.new("TextButton")
    cycleBtn.Text = "[Cycle]"
    cycleBtn.Size = UDim2.new(0, 55, 0, 22)
    cycleBtn.Position = UDim2.new(1, -62, 0.5, -11)
    cycleBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    cycleBtn.TextColor3 = Theme.Text
    cycleBtn.TextSize = 10
    cycleBtn.Font = Enum.Font.GothamBold
    cycleBtn.BorderSizePixel = 0
    cycleBtn.Parent = frame

    Instance.new("UICorner", cycleBtn).CornerRadius = UDim.new(0, 5)

    cycleBtn.MouseButton1Click:Connect(function()
        currentIdx = (currentIdx % #options) + 1
        modeLabel.Text = options[currentIdx]
        if callback then callback(options[currentIdx], currentIdx) end
    end)

    return frame
end

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║               NOTIFICATION SYSTEM (diimplementasi)              ║
-- ╚══════════════════════════════════════════════════════════════════╝

function notify(text, duration)
    duration = duration or 3

    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 320, 0, 44)
    notifFrame.Position = UDim2.new(0.5, -160, 0, -55)
    notifFrame.BackgroundColor3 = Theme.Panel
    notifFrame.BorderSizePixel = 0
    notifFrame.ZIndex = 999
    notifFrame.Parent = ScreenGui

    Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 8)

    -- Accent strip kiri
    local accentStrip = Instance.new("Frame")
    accentStrip.Size = UDim2.new(0, 3, 1, -8)
    accentStrip.Position = UDim2.new(0, 4, 0, 4)
    accentStrip.BackgroundColor3 = Theme.Accent
    accentStrip.BorderSizePixel = 0
    accentStrip.Parent = notifFrame

    Instance.new("UICorner", accentStrip).CornerRadius = UDim.new(0, 2)

    local notifLabel = Instance.new("TextLabel")
    notifLabel.Text = text
    notifLabel.Size = UDim2.new(1, -20, 1, 0)
    notifLabel.Position = UDim2.new(0, 14, 0, 0)
    notifLabel.BackgroundTransparency = 1
    notifLabel.TextColor3 = Color3.new(1, 1, 1)
    notifLabel.TextSize = 13
    notifLabel.Font = Enum.Font.GothamBold
    notifLabel.TextXAlignment = Enum.TextXAlignment.Left
    notifLabel.ZIndex = 1000
    notifLabel.Parent = notifFrame

    -- Animasi masuk
    local tweenIn = TweenService:Create(
        notifFrame,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -160, 0, 12)}
    )
    tweenIn:Play()

    spawn(function()
        wait(duration)
        local tweenOut = TweenService:Create(
            notifFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -160, 0, -55)}
        )
        tweenOut:Play()
        tweenOut.Completed:Wait()
        notifFrame:Destroy()
    end)
end

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                     BUILD ALL TABS                             ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ══════════ TAB 1: VIP ══════════
local vipPage = createTab("VIP", "👑", 1)
createSection(vipPage, "VIP (ULTIMATE AUTOMATIC)", 1)

createToggle(vipPage, "Auto Play (Smart AI / AutoFarmBot)", false, function(v)
    Config.AutoPlay = v
    if v then notify("Auto Play: ON - Bot mencari Generator & kabur dari Killer") end
end, 2)

createSlider(vipPage, "Flee Distance", 20, 80, 40, function(v)
    Config.AutoPlayFleeDist = v
end, 3)

createToggle(vipPage, "Auto Dagger (Auto Parry)", false, function(v)
    Config.AutoDagger = v
    if v then notify("Auto Dagger: ON - Parry otomatis aktif") end
end, 4)

createSlider(vipPage, "Dagger Parry Range", 10, 100, 30, function(v)
    Config.AutoDaggerRange = v
end, 5)

createToggle(vipPage, "Auto Wiggle Master", false, function(v)
    Config.WiggleMaster = v
    if v then notify("Wiggle Master: ON - Lepas dari panggulan Killer instan") end
end, 6)

-- ══════════ TAB 2: SURVIVOR ══════════
local survPage = createTab("Survivor", "🛡️", 2)
createSection(survPage, "SURVIVOR (MOVEMENT & HEALTH)", 1)

createToggle(survPage, "Speed Boost", false, function(v)
    Config.SpeedBoost = v
    if v then
        local h = getHumanoid()
        if h then h.WalkSpeed = Config.CustomSpeed end
    end
end, 2)

createSlider(survPage, "Custom Speed (16-100)", 16, 100, 16, function(v)
    Config.CustomSpeed = v
    if Config.SpeedBoost then
        local h = getHumanoid()
        if h then h.WalkSpeed = v end
    end
end, 3)

createToggle(survPage, "No Slowdown", false, function(v)
    Config.NoSlowdown = v
    if v then notify("No Slowdown: ON - Kebal semua efek perlambatan") end
end, 4)

createButton(survPage, "Force Reset State (Anti-Stuck)", function()
    local humanoid = getHumanoid()
    local char = getCharacter()
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
    if char then
        -- Reset semua nilai animasi yang tersangkut
        for _, obj in pairs(char:GetDescendants()) do
            if obj:IsA("BoolValue") and (obj.Name:find("Stun") or obj.Name:find("Stuck") or obj.Name:find("Frozen")) then
                obj.Value = false
            end
            if obj:IsA("NumberValue") and (obj.Name:find("Stun") or obj.Name:find("Stuck")) then
                obj.Value = 0
            end
        end
    end
    notify("State di-Reset!")
end, nil, 5)

createToggle(survPage, "Silent Actions (Anti-Noise)", false, function(v)
    Config.SilentActions = v
    if v then notify("Silent Actions: ON - Tanpa suara/visual ke Killer") end
end, 6)

createToggle(survPage, "Anti Fall Damage", false, function(v)
    Config.AntiFallDamage = v
    if v then notify("Anti Fall Damage: ON") end
end, 7)

createToggle(survPage, "Client God Mode (Beta)", false, function(v)
    Config.GodMode = v
    if v then notify("God Mode: ON - Damage Nullifier aktif") end
end, 8)

createButton(survPage, "Instant Heal", function()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.Health = humanoid.MaxHealth
        notify("Dipulihkan ke Max Health!")
    end
end, nil, 9)

createToggle(survPage, "Anti Knock", false, function(v)
    Config.AntiKnock = v
    if v then notify("Anti Knock: ON - Tidak bisa di-knock down") end
end, 10)

createToggle(survPage, "Auto Heal Aura", false, function(v)
    Config.AutoHealAura = v
    if v then notify("Auto Heal Aura: ON - Menyembuhkan tim otomatis") end
end, 11)

createSlider(survPage, "Heal Aura Range", 10, 50, 25, function(v)
    Config.HealAuraRange = v
end, 12)

-- ══════════ TAB 3: KILLER ══════════
local killerPage = createTab("Killer", "🔪", 3)
createSection(killerPage, "KILLER (VEIN KILLER MODIFICATION)", 1)

createToggle(killerPage, "Vein Spear: Drop Prediction", false, function(v)
    Config.SpearDropPrediction = v
    if v then notify("Spear Drop Prediction: ON - Aimbot tombak aktif") end
end, 2)

createToggle(killerPage, "Vein Spear: No Gravity", false, function(v)
    Config.SpearNoGravity = v
    if v then notify("Spear No Gravity: ON - Tombak terbang lurus") end
end, 3)

createToggle(killerPage, "Anti-Blind", false, function(v)
    Config.AntiBlind = v
    if v then notify("Anti-Blind: ON - Kebal Fog & Flash") end
end, 4)

createToggle(killerPage, "Anti-Stun", false, function(v)
    Config.AntiStun = v
    if v then notify("Anti-Stun: ON - Tidak bisa di-stun Pallet") end
end, 5)

createToggle(killerPage, "Double Damage Generator", false, function(v)
    Config.DoubleDamageGen = v
    if v then notify("Double Damage Gen: ON") end
end, 6)

createSlider(killerPage, "Gen Damage Multiplier", 2, 10, 3, function(v)
    Config.GenDamageMultiplier = v
end, 7)

createButton(killerPage, "Activate Killer Power", function()
    local remotes = findRemotes({"Power", "Ability", "Skill", "Special", "Ultimate"})
    if #remotes > 0 then
        for _, remote in pairs(remotes) do
            remote:FireServer()
        end
        notify("Killer Power diaktifkan!")
    else
        notify("Remote Power tidak ditemukan")
    end
end, nil, 8)

-- ══════════ TAB 4: VISUALS ══════════
local visPage = createTab("Visuals", "👁️", 4)
createSection(visPage, "VISUALS (ESP & WORLD)", 1)

createToggle(visPage, "Player ESP", false, function(v)
    Config.PlayerESP = v
    if v then notify("Player ESP: ON") end
end, 2)

createToggle(visPage, "Object ESP", false, function(v)
    Config.ObjectESP = v
    if v then notify("Object ESP: ON - Generator, Pallet, Gate, Hook") end
end, 3)

createToggle(visPage, "Enable Custom FOV", false, function(v)
    Config.CustomFOV = v
    if v then Camera.FieldOfView = Config.FOVValue end
end, 4)

createSlider(visPage, "FOV Value", 30, 120, 70, function(v)
    Config.FOVValue = v
    if Config.CustomFOV then Camera.FieldOfView = v end
end, 5)

createToggle(visPage, "Show Crosshair", false, function(v)
    Config.ShowCrosshair = v
end, 6)

createToggle(visPage, "Remove Blur & Bloom", false, function(v)
    Config.RemoveBlurBloom = v
    if v then notify("Blur & Bloom dimatikan") end
end, 7)

createToggle(visPage, "Force Fullbright", false, function(v)
    Config.ForceFullbright = v
    if v then notify("Fullbright: ON - Map terang tanpa bayangan") end
end, 8)

createToggle(visPage, "Extreme Potato Mode", false, function(v)
    Config.PotatoMode = v
    if v then notify("Potato Mode: ON - FPS Maksimal") end
end, 9)

-- ══════════ TAB 5: COMBAT ══════════
local combatPage = createTab("Combat", "⚔️", 5)
createSection(combatPage, "COMBAT (TARGETING SYSTEM)", 1)

createToggle(combatPage, "Enable Aimbot", false, function(v)
    Config.Aimbot = v
    if v then notify("Aimbot: ON - Mengunci musuh terdekat") end
end, 2)

createSlider(combatPage, "Aim Radius", 50, 500, 200, function(v)
    Config.AimRadius = v
end, 3)

createToggle(combatPage, "Show Target Tracer", false, function(v)
    Config.ShowTargetTracer = v
    if v then notify("Target Tracer: ON") end
end, 4)

createToggle(combatPage, "Lock-On Highlight", false, function(v)
    Config.LockOnHighlight = v
    if v then notify("Lock-On Highlight: ON") end
end, 5)

createButton(combatPage, "FPP / TPP Toggle", function()
    local humanoid = getHumanoid()
    if humanoid then
        local current = humanoid.CameraMode
        humanoid.CameraMode = (current == Enum.CameraMode.LockFirstPerson)
            and Enum.CameraMode.Classic
            or Enum.CameraMode.LockFirstPerson
        local mode = humanoid.CameraMode == Enum.CameraMode.LockFirstPerson and "First Person" or "Third Person"
        notify("Kamera: " .. mode)
    end
end, nil, 6)

createToggle(combatPage, "Expand Killer Hitbox", false, function(v)
    Config.ExpandHitbox = v
    if v then notify("Killer Hitbox: Diperbesar") end
end, 7)

createToggle(combatPage, "Auto Attack", false, function(v)
    Config.AutoAttack = v
    if v then notify("Auto Attack: ON") end
end, 8)

createSlider(combatPage, "Auto Attack Range", 3, 25, 8, function(v)
    Config.AutoAttackRange = v
end, 9)

-- ══════════ TAB 6: AUTOMATION ══════════
local autoPage = createTab("Auto", "⚙️", 6)
createSection(autoPage, "AUTOMATION (GENERATOR & UTILITY)", 1)

createToggle(autoPage, "Auto Generator", false, function(v)
    Config.AutoGenerator = v
    if v then notify("Auto Generator: ON - SkillCheck otomatis") end
end, 2)

createModeSelector(autoPage, "SkillCheck Mode:", {"Perfect", "Neutral"}, 1, function(mode)
    Config.GenSkillCheckMode = mode
    notify("SkillCheck Mode: " .. mode)
end, 3)

createButton(autoPage, "Boost All Gen (Group Project)", function()
    local generators = findPartsByName({"generator", "gen"})
    if #generators > 0 then
        local remotes = findRemotes({"Generator", "Progress", "Repair", "Fix"})
        for _, gen in pairs(generators) do
            gen:SetAttribute("Progress", 100)
            for _, remote in pairs(remotes) do
                pcall(function() remote:FireServer(gen, 100) end)
            end
        end
        notify("Boost All Gen: " .. #generators .. " generator diproses!")
    else
        notify("Generator tidak ditemukan di map")
    end
end, nil, 4)

createButton(autoPage, "Instant Escape (Gate)", function()
    local gates = findPartsByName({"gate", "exit", "door"})
    local remotes = findRemotes({"Gate", "Exit", "Open", "Escape", "Lever"})

    if #gates > 0 then
        for _, gate in pairs(gates) do
            teleportTo(gate.Position)
            for _, remote in pairs(remotes) do
                pcall(function() remote:FireServer(gate) end)
            end
        end
        notify("Instant Escape: Berusaha membuka gerbang...")
    else
        notify("Gerbang tidak ditemukan - coba selesaikan Generator dulu")
    end
end, nil, 5)

createToggle(autoPage, "Self UnHook (100%)", false, function(v)
    Config.SelfUnHook = v
    if v then notify("Self UnHook: ON - 100% lepas dari Hook") end
end, 6)

-- ────────── Pilih tab pertama ──────────
TabPages["VIP"].button.MouseButton1Click:Fire()

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                      CROSSHAIR OVERLAY                         ║
-- ╚══════════════════════════════════════════════════════════════════╝

local CrosshairContainer = Instance.new("Frame")
CrosshairContainer.Name = "CrosshairContainer"
CrosshairContainer.Size = UDim2.new(0, 24, 0, 24)
CrosshairContainer.Position = UDim2.new(0.5, -12, 0.5, -12)
CrosshairContainer.BackgroundTransparency = 1
CrosshairContainer.Visible = false
CrosshairContainer.ZIndex = 100
CrosshairContainer.Parent = ScreenGui

-- Garis horizontal atas
local chTop = Instance.new("Frame")
chTop.Size = UDim2.new(0, 10, 0, 2)
chTop.Position = UDim2.new(0.5, -5, 0, 0)
chTop.BackgroundColor3 = Color3.new(1, 1, 1)
chTop.BorderSizePixel = 0
chTop.Parent = CrosshairContainer

-- Garis horizontal bawah
local chBot = Instance.new("Frame")
chBot.Size = UDim2.new(0, 10, 0, 2)
chBot.Position = UDim2.new(0.5, -5, 1, -2)
chBot.BackgroundColor3 = Color3.new(1, 1, 1)
chBot.BorderSizePixel = 0
chBot.Parent = CrosshairContainer

-- Garis vertikal kiri
local chLeft = Instance.new("Frame")
chLeft.Size = UDim2.new(0, 2, 0, 10)
chLeft.Position = UDim2.new(0, 0, 0.5, -5)
chLeft.BackgroundColor3 = Color3.new(1, 1, 1)
chLeft.BorderSizePixel = 0
chLeft.Parent = CrosshairContainer

-- Garis vertikal kanan
local chRight = Instance.new("Frame")
chRight.Size = UDim2.new(0, 2, 0, 10)
chRight.Position = UDim2.new(1, -2, 0.5, -5)
chRight.BackgroundColor3 = Color3.new(1, 1, 1)
chRight.BorderSizePixel = 0
chRight.Parent = CrosshairContainer

-- Titik tengah
local chDot = Instance.new("Frame")
chDot.Size = UDim2.new(0, 4, 0, 4)
chDot.Position = UDim2.new(0.5, -2, 0.5, -2)
chDot.BackgroundColor3 = Theme.Accent
chDot.BorderSizePixel = 0
chDot.Parent = CrosshairContainer

Instance.new("UICorner", chDot).CornerRadius = UDim.new(1, 0)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                      TRACER LINE OVERLAY                       ║
-- ╚══════════════════════════════════════════════════════════════════╝

local TracerFrame = Instance.new("Frame")
TracerFrame.Name = "TracerLine"
TracerFrame.Size = UDim2.new(0, 2, 0, 1)
TracerFrame.BackgroundColor3 = Theme.TracerColor
TracerFrame.BorderSizePixel = 0
TracerFrame.BackgroundTransparency = 0.3
TracerFrame.Visible = false
TracerFrame.ZIndex = 90
TracerFrame.Parent = ScreenGui

local TracerOrigin = Instance.new("Frame")
TracerOrigin.Name = "TracerOrigin"
TracerOrigin.Size = UDim2.new(0, 8, 0, 8)
TracerOrigin.BackgroundColor3 = Theme.TracerColor
TracerOrigin.BorderSizePixel = 0
TracerOrigin.Visible = false
TracerOrigin.ZIndex = 91
TracerOrigin.Parent = ScreenGui

Instance.new("UICorner", TracerOrigin).CornerRadius = UDim.new(1, 0)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                        AIM CIRCLE OVERLAY                      ║
-- ╚══════════════════════════════════════════════════════════════════╝

local AimCircle = Instance.new("Frame")
AimCircle.Name = "AimCircle"
AimCircle.Size = UDim2.new(0, Config.AimRadius * 2, 0, Config.AimRadius * 2)
AimCircle.Position = UDim2.new(0.5, -Config.AimRadius, 0.5, -Config.AimRadius)
AimCircle.BackgroundColor3 = Color3.new(1, 1, 1)
AimCircle.BackgroundTransparency = 0.92
AimCircle.BorderSizePixel = 1
AimCircle.BorderColor3 = Color3.fromRGB(255, 80, 80)
AimCircle.Visible = false
AimCircle.ZIndex = 89
AimCircle.Parent = ScreenGui

Instance.new("UICorner", AimCircle).CornerRadius = UDim.new(1, 0)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    FPP/TPP FLOATING BUTTON (MOBILE)             ║
-- ╚══════════════════════════════════════════════════════════════════╝

local CamToggle = Instance.new("TextButton")
CamToggle.Text = "F"
CamToggle.Size = UDim2.new(0, 42, 0, 42)
CamToggle.Position = UDim2.new(1, -55, 0.5, 0)
CamToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 55, 200)
CamToggle.TextColor3 = Color3.new(1, 1, 1)
CamToggle.TextSize = 18
CamToggle.Font = Enum.Font.GothamBold
CamToggle.BorderSizePixel = 0
CamToggle.ZIndex = 50
CamToggle.Parent = ScreenGui

Instance.new("UICorner", CamToggle).CornerRadius = UDim.new(0.5, 0)

CamToggle.MouseButton1Click:Connect(function()
    local humanoid = getHumanoid()
    if humanoid then
        local current = humanoid.CameraMode
        humanoid.CameraMode = (current == Enum.CameraMode.LockFirstPerson)
            and Enum.CameraMode.Classic
            or Enum.CameraMode.LockFirstPerson
        local mode = humanoid.CameraMode == Enum.CameraMode.LockFirstPerson and "FPP" or "TPP"
        notify("Camera: " .. mode, 1.5)
    end
end)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                         ESP SYSTEM                             ║
-- ╚══════════════════════════════════════════════════════════════════╝

local PlayerESPTable = {}
local ObjectESPTable = {}

--- Membuat ESP untuk seorang player
local function createPlayerESP(player)
    local char = player.Character
    if not char then return end

    -- Deteksi role
    local isKiller = isPlayerKiller(player)

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "VD_ESP"
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = char

    if isKiller then
        highlight.FillColor = Theme.KillerESP
        highlight.OutlineColor = Color3.fromRGB(255, 80, 80)
    else
        highlight.FillColor = Theme.SurvivorESP
        highlight.OutlineColor = Color3.fromRGB(100, 255, 150)
    end
    highlight.Parent = char

    -- Billboard GUI (nama + info)
    local headPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "VD_ESP_Info"
    billboard.Size = UDim2.new(0, 220, 0, 55)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = headPart

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = isKiller and Theme.KillerESP or Theme.SurvivorESP
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = (isKiller and "[KILLER] " or "[SURVIVOR] ") .. player.DisplayName
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = billboard

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, 0, 0.3, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.45, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    infoLabel.TextStrokeTransparency = 0.4
    infoLabel.TextSize = 11
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.Text = "ALIVE | 0m"
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = billboard

    -- Health bar background
    local healthBg = Instance.new("Frame")
    healthBg.Name = "HealthBarBG"
    healthBg.Size = UDim2.new(0.8, 0, 0, 4)
    healthBg.Position = UDim2.new(0.1, 0, 0.82, 0)
    healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = billboard

    Instance.new("UICorner", healthBg).CornerRadius = UDim.new(0, 2)

    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg

    Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 2)

    PlayerESPTable[player] = {
        highlight = highlight,
        billboard = billboard,
        nameLabel = nameLabel,
        infoLabel = infoLabel,
        healthFill = healthFill,
        isKiller = isKiller,
    }
end

--- Menghapus ESP player
local function removePlayerESP(player)
    local data = PlayerESPTable[player]
    if data then
        pcall(function() data.highlight:Destroy() end)
        pcall(function() data.billboard:Destroy() end)
        PlayerESPTable[player] = nil
    end
end

--- Membersihkan semua ESP
local function clearAllPlayerESP()
    for player, _ in pairs(PlayerESPTable) do
        removePlayerESP(player)
    end
end

--- Membuat Object ESP (Generator, Pallet, Gate, Hook)
local function createObjectESP()
    -- Hapus ESP lama
    for _, obj in pairs(ObjectESPTable) do
        pcall(function() obj:Destroy() end)
    end
    ObjectESPTable = {}

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent then
            local nameLower = obj.Name:lower()
            local objType = nil
            local color = Color3.new(1, 1, 1)

            if nameLower:find("generator") or (nameLower:find("gen") and not nameLower:find("region")) then
                objType = "Generator"
                color = Theme.GenESP
            elseif nameLower:find("pallet") then
                objType = "Pallet"
                color = Theme.PalletESP
            elseif nameLower:find("gate") or nameLower:find("exit") then
                objType = "Exit Gate"
                color = Theme.GateESP
            elseif nameLower:find("hook") then
                objType = "Hook"
                color = Theme.HookESP
            end

            if objType then
                -- Highlight
                local highlight = Instance.new("Highlight")
                highlight.Name = "VD_ObjESP"
                highlight.Adornee = obj
                highlight.FillTransparency = 0.85
                highlight.OutlineTransparency = 0
                highlight.FillColor = color
                highlight.OutlineColor = color
                highlight.Parent = obj

                -- Billboard
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "VD_ObjESP_Label"
                billboard.Size = UDim2.new(0, 160, 0, 35)
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = obj

                local label = Instance.new("TextLabel")
                label.Name = "ObjLabel"
                label.Size = UDim2.new(1, 0, 0.6, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = color
                label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                label.TextStrokeTransparency = 0.4
                label.TextSize = 12
                label.Font = Enum.Font.GothamBold
                label.Text = objType
                label.TextXAlignment = Enum.TextXAlignment.Center
                label.Parent = billboard

                -- Sub-label untuk persentase (Generator)
                local subLabel = Instance.new("TextLabel")
                subLabel.Name = "ObjSubLabel"
                subLabel.Size = UDim2.new(1, 0, 0.4, 0)
                subLabel.Position = UDim2.new(0, 0, 0.6, 0)
                subLabel.BackgroundTransparency = 1
                subLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                subLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                subLabel.TextStrokeTransparency = 0.5
                subLabel.TextSize = 10
                subLabel.Font = Enum.Font.Gotham
                subLabel.Text = ""
                subLabel.TextXAlignment = Enum.TextXAlignment.Center
                subLabel.Parent = billboard

                -- Set persentase awal jika Generator
                if objType == "Generator" then
                    local progress = obj:GetAttribute("Progress") or 0
                    label.Text = objType .. " [" .. math.floor(progress) .. "%]"
                end

                table.insert(ObjectESPTable, highlight)
                table.insert(ObjectESPTable, billboard)
            end
        end
    end
end

--- Membersihkan Object ESP
local function clearObjectESP()
    for _, obj in pairs(ObjectESPTable) do
        pcall(function() obj:Destroy() end)
    end
    ObjectESPTable = {}
end

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    MAIN HEARTBEAT LOOPS                         ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ══════════ SURVIVOR LOOP (Heartbeat) ══════════
RunService.Heartbeat:Connect(function()
    local humanoid = getHumanoid()
    local root = getRootPart()
    if not humanoid or not root then return end

    -- Speed Boost
    if Config.SpeedBoost and humanoid.WalkSpeed ~= Config.CustomSpeed then
        humanoid.WalkSpeed = Config.CustomSpeed
    end

    -- No Slowdown - selalu pertahankan kecepatan
    if Config.NoSlowdown then
        local targetSpeed = Config.SpeedBoost and Config.CustomSpeed or 16
        if humanoid.WalkSpeed < targetSpeed then
            humanoid.WalkSpeed = targetSpeed
        end
        -- Reset juga jika ada nilai yang memperlambat
        for _, obj in pairs(getCharacter():GetDescendants()) do
            if obj:IsA("NumberValue") and (obj.Name:lower():find("slow") or obj.Name:lower():find("speed")) then
                if obj.Value < 0 then
                    obj.Value = 0
                end
            end
        end
    end

    -- Anti Fall Damage
    if Config.AntiFallDamage then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Landed then
            -- Baru saja mendarat - cegah damage
            humanoid.Health = math.min(humanoid.Health + 100, humanoid.MaxHealth)
        end
    end

    -- Client God Mode
    if Config.GodMode then
        -- Selalu set health ke max setiap frame
        humanoid.Health = humanoid.MaxHealth
    end

    -- Anti Knock - cegah ragdoll
    if Config.AntiKnock then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.Physics then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            wait(0.1)
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    -- Auto Heal Aura
    if Config.AutoHealAura then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    or player.Character:FindFirstChild("Torso")
                local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
                if targetRoot and targetHum then
                    local dist = (root.Position - targetRoot.Position).Magnitude
                    if dist <= Config.HealAuraRange and targetHum.Health < targetHum.MaxHealth then
                        local remotes = findRemotes({"Heal", "Revive", "Help"})
                        for _, remote in pairs(remotes) do
                            pcall(function() remote:FireServer(player) end)
                        end
                    end
                end
            end
        end
    end
end)

-- ══════════ RENDER LOOP (RenderStepped) ══════════
local lastObjectESPRefresh = 0

RunService.RenderStepped:Connect(function()
    local now = tick()

    -- ── Crosshair ──
    CrosshairContainer.Visible = Config.ShowCrosshair

    -- ── FOV ──
    if Config.CustomFOV then
        Camera.FieldOfView = Config.FOVValue
    end

    -- ── Force Fullbright ──
    if Config.ForceFullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14.5
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 0
    end

    -- ── Remove Blur & Bloom ──
    if Config.RemoveBlurBloom then
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("BloomEffect") or effect:IsA("BlurEffect")
                or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect")
                or effect:IsA("ColorCorrectionEffect") then
                effect.Enabled = false
            end
        end
    end

    -- ── Extreme Potato Mode ──
    if Config.PotatoMode then
        Lighting.Brightness = 0
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end
        -- Matikan partikel
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
    end

    -- ── Player ESP ──
    if Config.PlayerESP then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character and not PlayerESPTable[player] then
                    createPlayerESP(player)
                end
                -- Update info
                local data = PlayerESPTable[player]
                if data and player.Character then
                    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        or player.Character:FindFirstChild("Torso")
                    local myRoot = getRootPart()
                    local targetHum = player.Character:FindFirstChildOfClass("Humanoid")

                    if targetRoot and myRoot then
                        local dist = math.floor((targetRoot.Position - myRoot.Position).Magnitude)
                        local status = "ALIVE"
                        if targetHum then
                            if targetHum.Health <= 0 then
                                status = "DEAD"
                            elseif targetHum.Health < targetHum.MaxHealth * 0.3 then
                                status = "INJURED"
                            end
                            -- Update health bar
                            local healthPct = targetHum.Health / targetHum.MaxHealth
                            data.healthFill.Size = UDim2.new(healthPct, 0, 1, 0)
                            if healthPct > 0.6 then
                                data.healthFill.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
                            elseif healthPct > 0.3 then
                                data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
                            else
                                data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                            end
                        end
                        data.infoLabel.Text = status .. " | " .. dist .. "m"
                    end
                end
            end
        end
    else
        if next(PlayerESPTable) then
            clearAllPlayerESP()
        end
    end

    -- ── Object ESP ──
    if Config.ObjectESP then
        -- Refresh setiap 5 detik
        if now - lastObjectESPRefresh > 5 or #ObjectESPTable == 0 then
            createObjectESP()
            lastObjectESPRefresh = now
        end

        -- Update persentase Generator
        for _, obj in pairs(ObjectESPTable) do
            if obj:IsA("BillboardGui") and obj.Parent then
                local subLabel = obj:FindFirstChild("ObjSubLabel")
                local mainLabel = obj:FindFirstChild("ObjLabel")
                local progress = obj.Parent:GetAttribute("Progress")
                if mainLabel and progress then
                    mainLabel.Text = obj.Parent.Name .. " [" .. math.floor(progress) .. "%]"
                end
            end
        end
    else
        if #ObjectESPTable > 0 then
            clearObjectESP()
        end
    end

    -- ── Aimbot ──
    if Config.Aimbot then
        local target = findAimbotTarget()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild("Head")
                or target.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            end
        end

        -- Update Aim Circle
        AimCircle.Visible = true
        local radius = Config.AimRadius
        AimCircle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
        AimCircle.Position = UDim2.new(0.5, -radius, 0.5, -radius)
    else
        AimCircle.Visible = false
    end

    -- ── Target Tracer ──
    if Config.ShowTargetTracer then
        local target = findAimbotTarget()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild("Head")
                or target.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                if onScreen then
                    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    local targetScreen = Vector2.new(screenPos.X, screenPos.Y)

                    -- Posisi origin di bawah layar
                    TracerOrigin.Position = UDim2.new(0.5, -4, 1, -20)
                    TracerOrigin.Visible = true

                    -- Garis tracer
                    local dx = targetScreen.X - viewportCenter.X
                    local dy = targetScreen.Y - viewportCenter.Y
                    local length = math.sqrt(dx * dx + dy * dy)
                    local angle = math.atan2(dy, dx)

                    TracerFrame.Visible = true
                    TracerFrame.Size = UDim2.new(0, length, 0, 2)
                    TracerFrame.Position = UDim2.new(0, viewportCenter.X, 0, viewportCenter.Y - 10)
                    TracerFrame.Rotation = math.deg(angle)
                end
            end
        else
            TracerFrame.Visible = false
            TracerOrigin.Visible = false
        end
    else
        TracerFrame.Visible = false
        TracerOrigin.Visible = false
    end

    -- ── Lock-On Highlight ──
    if Config.LockOnHighlight then
        local target = findAimbotTarget()
        if target and target.Character then
            -- Cek apakah sudah ada highlight
            local existing = target.Character:FindFirstChild("VD_LockOn")
            if not existing then
                local hl = Instance.new("Highlight")
                hl.Name = "VD_LockOn"
                hl.FillColor = Color3.fromRGB(255, 50, 50)
                hl.OutlineColor = Color3.fromRGB(255, 215, 0)
                hl.FillTransparency = 0.4
                hl.OutlineTransparency = 0
                hl.Parent = target.Character
            end
        else
            -- Hapus highlight dari semua
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    local existing = player.Character:FindFirstChild("VD_LockOn")
                    if existing then existing:Destroy() end
                end
            end
        end
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local existing = player.Character:FindFirstChild("VD_LockOn")
                if existing then existing:Destroy() end
            end
        end
    end

    -- ── Expand Hitbox ──
    if Config.ExpandHitbox then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local nameLower = part.Name:lower()
                        if nameLower == "head" or nameLower == "humanoidrootpart"
                            or nameLower == "torso" or nameLower:find("hitbox") then
                            local maxSize = 20
                            if part.Size.X < maxSize then
                                part.Size = Vector3.new(
                                    math.min(part.Size.X * 1.005, maxSize),
                                    math.min(part.Size.Y * 1.005, maxSize),
                                    math.min(part.Size.Z * 1.005, maxSize)
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    -- ── Auto Attack ──
    if Config.AutoAttack then
        local root = getRootPart()
        if root then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        or player.Character:FindFirstChild("Torso")
                    if targetRoot then
                        local dist = (root.Position - targetRoot.Position).Magnitude
                        if dist <= Config.AutoAttackRange then
                            local remotes = findRemotes({"Attack", "Hit", "Strike", "Punch", "Slash", "Knife"})
                            for _, remote in pairs(remotes) do
                                pcall(function() remote:FireServer(player) end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                   BACKGROUND TASK LOOPS                         ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ══════════ AUTO PLAY (Smart AI / AutoFarmBot) ══════════
spawn(function()
    local lastMoveTime = 0
    while wait(0.4) do
        if not Config.AutoPlay then continue end

        local root = getRootPart()
        local humanoid = getHumanoid()
        if not root or not humanoid then continue end
        if humanoid.Health <= 0 then continue end

        -- Deteksi Killer terdekat
        local killer = getKiller()
        local killerRoot = killer and killer.Character
            and (killer.Character:FindFirstChild("HumanoidRootPart") or killer.Character:FindFirstChild("Torso"))

        if killerRoot then
            local distToKiller = (root.Position - killerRoot.Position).Magnitude

            -- Kabur jika Killer terlalu dekat
            if distToKiller < Config.AutoPlayFleeDist then
                local fleeDir = (root.Position - killerRoot.Position).Unit
                -- Tambahkan sedikit variasi arah agar tidak terlalu prediktabel
                local randomOffset = Vector3.new(
                    math.random(-20, 20),
                    0,
                    math.random(-20, 20)
                )
                local fleeTarget = root.Position + (fleeDir * 60) + randomOffset
                -- Pastikan target tidak di luar map
                fleeTarget = Vector3.new(
                    math.clamp(fleeTarget.X, -500, 500),
                    fleeTarget.Y,
                    math.clamp(fleeTarget.Z, -500, 500)
                )
                humanoid:MoveTo(fleeTarget)

                -- Juga coba auto parry saat kabur
                if Config.AutoDagger then
                    local parryRemotes = findRemotes({"Parry", "Dagger", "Block", "Counter", "Deflect"})
                    for _, remote in pairs(parryRemotes) do
                        pcall(function() remote:FireServer() end)
                    end
                end
                continue
            end
        end

        -- Pencarian target: Generator atau Exit Gate
        local generators = findPartsByName({"generator", "gen"})
        local gates = findPartsByName({"gate", "exit"})

        -- Prioritaskan: Gate terbuka > Generator terdekat
        local bestTarget = nil
        local bestDist = math.huge

        -- Cek gate yang sudah terbuka
        for _, gate in pairs(gates) do
            local isOpen = gate:GetAttribute("Open") or gate:GetAttribute("Unlocked")
            if isOpen then
                local dist = (gate.Position - root.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestTarget = gate
                end
            end
        end

        -- Jika tidak ada gate terbuka, cari generator
        if not bestTarget then
            for _, gen in pairs(generators) do
                local progress = gen:GetAttribute("Progress") or 0
                -- Prioritaskan generator yang hampir selesai
                local dist = (gen.Position - root.Position).Magnitude
                local score = dist - (progress * 2) -- Bonus untuk yang hampir selesai
                if score < bestDist then
                    bestDist = score
                    bestTarget = gen
                end
            end
        end

        -- Jika masih tidak ada, arahkan ke gate terdekat (meski belum terbuka)
        if not bestTarget and #gates > 0 then
            bestTarget, _ = findNearestPart(gates, root.Position)
        end

        if bestTarget then
            local dist = (bestTarget.Position - root.Position).Magnitude
            if dist > 5 then
                humanoid:MoveTo(bestTarget.Position)
            end
        end
    end
end)

-- ══════════ AUTO DAGGER (Auto Parry) ══════════
spawn(function()
    local lastParryTime = 0
    while wait(0.08) do
        if not Config.AutoDagger then continue end

        local root = getRootPart()
        if not root then continue end

        local killer = getKiller()
        local killerRoot = killer and killer.Character
            and (killer.Character:FindFirstChild("HumanoidRootPart") or killer.Character:FindFirstChild("Torso"))

        if killerRoot then
            local dist = (root.Position - killerRoot.Position).Magnitude
            if dist <= Config.AutoDaggerRange then
                local now = tick()
                -- Cooldown 0.5 detik agar tidak spam
                if now - lastParryTime > 0.5 then
                    local parryRemotes = findRemotes({"Parry", "Dagger", "Block", "Counter", "Deflect"})
                    for _, remote in pairs(parryRemotes) do
                        pcall(function() remote:FireServer() end)
                    end
                    lastParryTime = now
                end
            end
        end
    end
end)

-- ══════════ WIGGLE MASTER ══════════
spawn(function()
    while wait(0.04) do
        if not Config.WiggleMaster then continue end

        local humanoid = getHumanoid()
        if not humanoid then continue end

        -- Deteksi apakah sedang diangkat/dipanggul
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Ragdoll then
            -- Kirim input wiggle secara cepat
            local wiggleRemotes = findRemotes({"Wiggle", "Struggle", "Escape", "Break", "Resist"})
            for _, remote in pairs(wiggleRemotes) do
                pcall(function()
                    -- Kirim arah acak (0-3: Atas/Kanan/Bawah/Kiri)
                    remote:FireServer(math.random(0, 3))
                end)
            end
        end
    end
end)

-- ══════════ SILENT ACTIONS (Anti-Noise) ══════════
spawn(function()
    while wait(0.2) do
        if not Config.SilentActions then continue end

        -- Cegah pengiriman event noise/footstep
        local noiseRemotes = findRemotes({"Noise", "Sound", "Footstep", "Alert", "Foot", "Step", "Hear"})
        for _, remote in pairs(noiseRemotes) do
            -- Hook FireServer agar tidak mengirim ke server
            if not remote:GetAttribute("VD_Silenced") then
                remote:SetAttribute("VD_Silenced", true)
                local originalFireServer = hookfunction(remote.FireServer, function(...)
                    -- Tidak mengirim apapun - diam-diam
                    return nil
                end) or nil
            end
        end
    end
end)

-- ══════════ ANTI-BLIND ══════════
spawn(function()
    while wait(0.3) do
        if not Config.AntiBlind then continue end

        -- Matikan semua efek pasca di Lighting
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end

        -- Hapus overlay blur/flash di PlayerGui
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, obj in pairs(playerGui:GetDescendants()) do
                local nameLower = obj.Name:lower()
                if (obj:IsA("BlurEffect") or obj:IsA("Frame"))
                    and (nameLower:find("flash") or nameLower:find("blind")
                        or nameLower:find("fog") or nameLower:find("blur")
                        or nameLower:find("dark") or nameLower:find("obscure")) then
                    obj.Visible = false
                    obj.Enabled = false
                end
            end
        end
    end
end)

-- ══════════ ANTI-STUN ══════════
spawn(function()
    while wait(0.08) do
        if not Config.AntiStun then continue end

        local humanoid = getHumanoid()
        if not humanoid then continue end

        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Stunned
            or state == Enum.HumanoidStateType.StunnedNoFall then
            -- Langsung keluar dari stun
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end)

-- ══════════ SPEAR NO GRAVITY & DROP PREDICTION ══════════
spawn(function()
    while wait(0.03) do
        if not Config.SpearNoGravity and not Config.SpearDropPrediction then continue end

        for _, obj in pairs(Workspace:GetDescendants()) do
            if not obj:IsA("BasePart") then continue end
            local nameLower = obj.Name:lower()
            if not (nameLower:find("spear") or nameLower:find("projectile")
                or nameLower:find("knife") or nameLower:find("throw")
                or nameLower:find("vein")) then continue end

            -- Cek apakah objek ini bergerak cepat (projectile)
            local vel = obj.Velocity
            if vel.Magnitude < 30 then continue end

            -- No Gravity
            if Config.SpearNoGravity then
                -- Hilangkan komponen Y dari velocity
                obj.Velocity = Vector3.new(vel.X, 0, vel.Z)
                -- Hilangkan gravity dari BodyForce
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("BodyForce") then
                        child.Force = Vector3.new(child.Force.X, 0, child.Force.Z)
                    elseif child:IsA("BodyPosition") then
                        -- Biarkan position, tapi pastikan tidak ada gravity effect
                    end
                end
            end

            -- Drop Prediction
            if Config.SpearDropPrediction then
                local target = findAimbotTarget()
                if target and target.Character then
                    local targetPart = target.Character:FindFirstChild("Head")
                        or target.Character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local myRoot = getRootPart()
                        if myRoot then
                            local dist = (myRoot.Position - targetPart.Position).Magnitude
                            -- Kompensasi drop: semakin jauh, semakin tinggi aim
                            local dropCompensation = dist * 0.02
                            obj.Velocity = Vector3.new(vel.X, vel.Y + dropCompensation, vel.Z)
                        end
                    end
                end
            end
        end
    end
end)

-- ══════════ DOUBLE DAMAGE GENERATOR ══════════
spawn(function()
    while wait(0.5) do
        if not Config.DoubleDamageGen then continue end

        local root = getRootPart()
        if not root then continue end

        -- Cari generator terdekat
        local generators = findPartsByName({"generator", "gen"})
        for _, gen in pairs(generators) do
            local dist = (gen.Position - root.Position).Magnitude
            if dist < 10 then
                local remotes = findRemotes({"Generator", "Kick", "Damage", "Sabotage", "Break"})
                for i = 1, Config.GenDamageMultiplier do
                    for _, remote in pairs(remotes) do
                        pcall(function() remote:FireServer(gen) end)
                    end
                end
            end
        end
    end
end)

-- ══════════ AUTO GENERATOR (SkillCheck) ══════════
spawn(function()
    while wait(0.15) do
        if not Config.AutoGenerator then continue end

        local root = getRootPart()
        if not root then continue end

        -- Cek apakah di dekat generator
        local generators = findPartsByName({"generator", "gen"})
        local nearGen = false
        for _, gen in pairs(generators) do
            if (gen.Position - root.Position).Magnitude < 12 then
                nearGen = true
                break
            end
        end

        if nearGen then
            -- Handle SkillCheck otomatis
            local skillRemotes = findRemotes({"SkillCheck", "Skill", "Check", "HitZone", "MiniGame"})
            for _, remote in pairs(skillRemotes) do
                pcall(function()
                    if Config.GenSkillCheckMode == "Perfect" then
                        remote:FireServer("Perfect", 1.0)
                    else
                        remote:FireServer("Neutral", 0.5)
                    end
                end)
            end
        end
    end
end)

-- ══════════ SELF UNHOOK (100%) ══════════
spawn(function()
    while wait(0.25) do
        if not Config.SelfUnHook then continue end

        local humanoid = getHumanoid()
        if not humanoid then continue end

        -- Deteksi apakah sedang tergantung
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Ragdoll then

            -- Cek apakah ada Hook di dekat
            local root = getRootPart()
            if not root then continue end

            local hooks = findPartsByName({"hook"})
            for _, hook in pairs(hooks) do
                if (hook.Position - root.Position).Magnitude < 8 then
                    local remotes = findRemotes({"Hook", "Unhook", "Escape", "Struggle", "SelfUnhook"})
                    for _, remote in pairs(remotes) do
                        -- Kirim dengan peluang 100%
                        pcall(function() remote:FireServer(hook, 1.0, true) end)
                    end
                    break
                end
            end
        end
    end
end)

-- ══════════ BOOST ALL GEN (Continuous) ══════════
spawn(function()
    while wait(2) do
        if not Config.BoostAllGen then continue end

        local generators = findPartsByName({"generator", "gen"})
        local remotes = findRemotes({"Generator", "Progress", "Repair", "Fix"})
        for _, gen in pairs(generators) do
            local progress = gen:GetAttribute("Progress") or 0
            if progress < 100 then
                gen:SetAttribute("Progress", 100)
                for _, remote in pairs(remotes) do
                    pcall(function() remote:FireServer(gen, 100) end)
                end
            end
        end
    end
end)

-- ══════════ INSTANT ESCAPE (Continuous) ══════════
spawn(function()
    while wait(1) do
        if not Config.InstantEscape then continue end

        local gates = findPartsByName({"gate", "exit", "door"})
        local remotes = findRemotes({"Gate", "Exit", "Open", "Escape", "Lever", "Complete"})

        for _, gate in pairs(gates) do
            teleportTo(gate.Position)
            for _, remote in pairs(remotes) do
                pcall(function() remote:FireServer(gate) end)
            end
        end
    end
end)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              CHARACTER ADDED / REMOVED HANDLERS                ║
-- ╚══════════════════════════════════════════════════════════════════╝

Players.LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    -- Re-apply ESP
    if Config.PlayerESP then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createPlayerESP(player)
            end
        end
    end
    -- Re-apply settings
    if Config.SpeedBoost then
        wait(0.5)
        local h = character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Config.CustomSpeed end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1)
        if Config.PlayerESP then
            createPlayerESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerESP(player)
end)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                         KEYBINDS                               ║
-- ╚══════════════════════════════════════════════════════════════════╝

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    -- RightCtrl -> Toggle GUI
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end

    -- H -> Instant Heal
    if input.KeyCode == Enum.KeyCode.H then
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
            notify("Instant Heal!", 1.5)
        end
    end

    -- R -> Force Reset State
    if input.KeyCode == Enum.KeyCode.R then
        local humanoid = getHumanoid()
        local char = getCharacter()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:Stop()
            end
        end
        if char then
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BoolValue") and (obj.Name:find("Stun") or obj.Name:find("Stuck")) then
                    obj.Value = false
                end
            end
        end
        notify("State Reset!", 1.5)
    end

    -- G -> Toggle God Mode
    if input.KeyCode == Enum.KeyCode.G then
        Config.GodMode = not Config.GodMode
        notify("God Mode: " .. (Config.GodMode and "ON" or "OFF"), 1.5)
    end

    -- F -> Toggle FPP/TPP
    if input.KeyCode == Enum.KeyCode.F then
        local humanoid = getHumanoid()
        if humanoid then
            local current = humanoid.CameraMode
            humanoid.CameraMode = (current == Enum.CameraMode.LockFirstPerson)
                and Enum.CameraMode.Classic
                or Enum.CameraMode.LockFirstPerson
            notify("Camera: " .. (humanoid.CameraMode == Enum.CameraMode.LockFirstPerson and "FPP" or "TPP"), 1.5)
        end
    end
end)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                        LOADED NOTIFICATION                     ║
-- ╚══════════════════════════════════════════════════════════════════╝

notify("Violence District Hub Loaded!", 4)

-- Console log
print("╔══════════════════════════════════════════════════╗")
print("║     VIOLENCE DISTRICT HUB - LOADED              ║")
print("║                                                   ║")
print("║  Keybinds:                                        ║")
print("║    RightCtrl  -> Toggle GUI                       ║")
print("║    H          -> Instant Heal                     ║")
print("║    R          -> Force Reset State                ║")
print("║    G          -> Toggle God Mode                  ║")
print("║    F          -> Toggle FPP/TPP                   ║")
print("╚══════════════════════════════════════════════════╝")
