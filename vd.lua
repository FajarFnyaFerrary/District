--[[
    ============================================================
    VIOLENCE DISTRICT (DISTRIK KEKERASAN) - ROBLOX SCRIPT
    ============================================================
    Version: 4.0.0 (WindUI Rewrite)
    Game: Violence District (Distrik Kekerasan)
    UI Library: WindUI by Footagesus (.ftgs)
    
    FEATURES:
      - VIP (Auto Play, Auto Dagger, Auto Wiggle, Killer Prediction)
      - Survivor (Speed, NoSlowdown, NoClip, GodMode, etc.)
      - Killer (Vein Spear mods, Anti Blind/Stun, Teleport)
      - Visuals (ESP, FOV, Crosshair, Fullbright, Potato)
      - Combat (Aimbot, Tracer, LockOn, FPP/TPP)
      - Automation (Auto Gen, Boost Gen, Instant Escape, Self UnHook)
    
    ERROR HANDLING: All features wrapped in pcall() to prevent fatal crashes.
    ============================================================
--]]

-- ============================================
-- SECTION 0: WINDUI INITIALIZATION
-- ============================================
local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))
local TweenService = cloneref(game:GetService("TweenService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Camera = Workspace.CurrentCamera

local WindUI

do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)

    if ok then
        WindUI = result
    else
        if RunService:IsStudio() or not writefile then
            WindUI = require(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init"))
        else
            WindUI =
                loadstring(game:HttpGet("https://raw.githubusercontent.com/FajarFnyaFerrary/District/main/dist/main.lua"))()
        end
    end
end

local ThemeName = "Dark"

local Window = WindUI:CreateWindow({
    Title = "Violence District",
    Author = "v4.0 | WindUI",
    Icon = "solar:skull-bold",
    Theme = ThemeName,
    NewElements = true,
    Transparent = true,
    ToggleKey = Enum.KeyCode.RightControl,
    Acrylic = true,
})

-- ============================================
-- SECTION 1: CORE SETUP & CONFIG
-- ============================================
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local Config = {
    -- VIP
    AutoPlay = false,
    AutoDagger = false,
    AutoDaggerRange = 25,
    AutoWiggle = false,

    -- Survivor
    SpeedBoost = false,
    CustomSpeed = 16,
    NoSlowdown = false,
    NoClip = false,
    SilentActions = false,
    AntiFallDamage = false,
    GodMode = false,
    AntiKnock = false,
    AutoHealAura = false,
    AutoHealAuraRange = 30,

    -- Killer
    VeinSpearDrop = false,
    VeinSpearNoGravity = false,
    AntiBlind = false,
    AntiStun = false,
    DoubleDamageGen = false,
    DoubleDamageMultiplier = 5,
    TeleportEnabled = false,

    -- Visuals
    PlayerESP = false,
    GeneratorESP = false,
    PalletESP = false,
    ExitGateESP = false,
    HookESP = false,
    WindowESP = false,
    CustomFOV = false,
    FOVValue = 70,
    DefaultFOV = 70,
    ShowCrosshair = false,
    RemoveBlur = false,
    ForceFullbright = false,
    PotatoMode = false,

    -- Combat
    AimbotEnabled = false,
    AimRadius = 200,
    ShowTracer = false,
    LockOnHighlight = false,
    ExpandKillerHitbox = false,
    AutoAttack = false,
    AutoAttackRange = 8,

    -- Automation
    AutoGenerator = false,
    AutoGenMode = "Perfect",
    InstantEscape = false,
    SelfUnHook = false,

    -- Prediction (Lobby Only)
    KillerPrediction = false,
    PredictedKiller = nil,
}

-- Safe call wrapper - mencegah script crash
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[VD] Error: " .. tostring(result))
    end
    return success, result
end

-- ============================================
-- SECTION 2: LOBBY DETECTION SYSTEM
-- ============================================
local function IsInLobby()
    local isInLobby = false
    SafeCall(function()
        local char = LocalPlayer.Character

        -- METODE 1: Player attributes
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

        -- METODE 2: ReplicatedStorage game state
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

        -- METODE 3: Workspace lobby objects
        for _, obj in ipairs(Workspace:GetChildren()) do
            local name = string.lower(obj.Name)
            if name:find("lobby") or name:find("waiting") or name:find("queue") or name:find("pre_game") then
                isInLobby = true; return
            end
            if name:find("map") and not name:find("lobby") then
                isInLobby = false; return
            end
        end

        -- METODE 4: SpawnLocation detection
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("SpawnLocation") then
                        local spawnName = string.lower(obj.Name)
                        if spawnName:find("lobby") or spawnName:find("wait") then
                            isInLobby = true; return
                        end
                    end
                end
            end
        end

        -- METODE 5: leaderstats
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

        -- METODE 6: RemoteFunction state check
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteFunction") then
                local name = string.lower(obj.Name)
                if name:find("getstate") or name:find("get_state") or name:find("getphase") or name:find("getstatus") then
                    local ok, result = pcall(function()
                        return obj:InvokeServer()
                    end)
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

-- ============================================
-- SECTION 3: KILLER PREDICTION ENGINE
-- ============================================
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

        -- Coba InvokeServer untuk role info
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteFunction") then
                local name = string.lower(obj.Name)
                if name:find("getrole") or name:find("get_role") or name:find("getkiller")
                    or name:find("get_killer") or name:find("whokiller") or name:find("predict") then
                    SafeCall(function()
                        local ok, result = pcall(function()
                            return obj:InvokeServer()
                        end)
                        if ok and result then
                            if type(result) == "string" then
                                CapturedRoleData[result] = "killer"
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

        -- METHOD 1: Player attributes
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

                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats then
                    for _, stat in ipairs(leaderstats:GetChildren()) do
                        local statName = string.lower(stat.Name)
                        if statName:find("role") or statName:find("team") then
                            if stat:IsA("StringValue") then
                                local val = string.lower(stat.Value or "")
                                if val:find("killer") or val:find("slasher") then
                                    return true, player
                                end
                            end
                        end
                    end
                end

                if player.Character then
                    for _, obj in ipairs(player.Character:GetDescendants()) do
                        local name = string.lower(obj.Name or "")
                        if name:find("role") or name:find("team") or name:find("killer") then
                            if obj:IsA("StringValue") or obj:IsA("ObjectValue") then
                                local val = string.lower(tostring(obj.Value or ""))
                                if val:find("killer") or val:find("slasher") or val:find("murderer") then
                                    return true, player
                                end
                            end
                        end
                        if name:find("iskiller") or name:find("is_killer") then
                            if obj:IsA("BoolValue") and obj.Value == true then
                                return true, player
                            end
                        end
                    end
                end
            end)
        end

        -- METHOD 2: ReplicatedStorage role containers
        SafeCall(function()
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                local name = string.lower(obj.Name)
                if name:find("role") or name:find("killer") or name:find("assignment") then
                    if obj:IsA("Folder") or obj:IsA("Configuration") or obj:IsA("ModuleScript") then
                        for _, child in ipairs(obj:GetChildren()) do
                            local childName = string.lower(child.Name or "")
                            local childVal = string.lower(tostring(child.Value or ""))
                            if childVal:find("killer") then
                                for _, player in ipairs(Players:GetPlayers()) do
                                    if string.lower(player.Name):find(childName) or childName:find(string.lower(player.Name)) then
                                        return true, player
                                    end
                                end
                            end
                        end
                    elseif obj:IsA("StringValue") then
                        local val = string.lower(obj.Value or "")
                        for _, player in ipairs(Players:GetPlayers()) do
                            if val:find(string.lower(player.Name)) then
                                local context = string.lower(obj.Name)
                                if context:find("killer") or context:find("role") then
                                    return true, player
                                end
                            end
                        end
                    elseif obj:IsA("ObjectValue") and obj.Value and obj.Value:IsA("Player") then
                        local context = string.lower(obj.Name)
                        if context:find("killer") or context:find("role") then
                            for _, player in ipairs(Players:GetPlayers()) do
                                if player == obj.Value then
                                    return true, player
                                end
                            end
                        end
                    end
                end
            end
        end)

        -- METHOD 3: Captured hook data
        SafeCall(function()
            for playerName, roleInfo in pairs(CapturedRoleData) do
                local role = string.lower(tostring(roleInfo))
                if role:find("killer") or role:find("slasher") then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if string.lower(player.Name) == string.lower(playerName) then
                            return true, player
                        end
                    end
                end
            end
        end)

        -- METHOD 4: RemoteFunction queries
        SafeCall(function()
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteFunction") then
                    local name = string.lower(obj.Name)
                    if name:find("getrole") or name:find("get_role") or name:find("getkiller")
                        or name:find("roledata") or name:find("assign") or name:find("whois")
                        or name:find("killername") or name:find("nextkiller") then
                        SafeCall(function()
                            local ok, result = pcall(function()
                                return obj:InvokeServer()
                            end)
                            if ok and result then
                                for _, player in ipairs(Players:GetPlayers()) do
                                    if string.lower(tostring(result)):find(string.lower(player.Name)) then
                                        return true, player
                                    end
                                end
                                if type(result) == "Instance" and result:IsA("Player") then
                                    return true, result
                                end
                            end
                        end)
                    end
                end
            end
        end)

        -- METHOD 5: BindableEvent/Function
        SafeCall(function()
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                    local name = string.lower(obj.Name)
                    if name:find("killer") or name:find("role") then
                        for _, child in ipairs(obj:GetChildren()) do
                            local childName = string.lower(tostring(child.Name or ""))
                            for _, player in ipairs(Players:GetPlayers()) do
                                if childName:find(string.lower(player.Name)) then
                                    return true, player
                                end
                            end
                        end
                    end
                end
            end
        end)

        -- METHOD 6: Workspace Values
        SafeCall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("StringValue") or obj:IsA("ObjectValue") or obj:IsA("IntValue") then
                    local name = string.lower(obj.Name)
                    if name:find("killer") or name:find("role") or name:find("slasher") then
                        local val = string.lower(tostring(obj.Value or ""))
                        for _, player in ipairs(Players:GetPlayers()) do
                            if val:find(string.lower(player.Name)) then
                                return true, player
                            end
                        end
                        if obj.Value and obj.Value:IsA("Player") then
                            return true, obj.Value
                        end
                    end
                end
            end
        end)

        -- METHOD 7: Backpack weapon detection
        SafeCall(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local backpack = player:FindFirstChild("Backpack")
                    if backpack then
                        for _, tool in ipairs(backpack:GetChildren()) do
                            if tool:IsA("Tool") then
                                local toolName = string.lower(tool.Name)
                                if toolName:find("spear") or toolName:find("knife") or toolName:find("dagger")
                                    or toolName:find("weapon") or toolName:find("killer") or toolName:find("vein") then
                                    return true, player
                                end
                            end
                        end
                    end
                    for _, obj in ipairs(player.Character:GetDescendants()) do
                        if obj:IsA("Tool") then
                            local toolName = string.lower(obj.Name)
                            if toolName:find("spear") or toolName:find("knife") or toolName:find("killer") or toolName:find("vein") then
                                return true, player
                            end
                        end
                    end
                end
            end
        end)

    end)
    return false, nil
end

-- Auto-init hooks on load
SafeCall(function()
    task.spawn(function()
        task.wait(1)
        SetupRoleHooks()
    end)
end)

-- ============================================
-- SECTION 4: BUILD WINDUI - TABS & ELEMENTS
-- ============================================
local Tag = Window:Tag({
    Title = "Violence District v4.0",
    Color = "Text",
})

-- Unload button di topbar
Window.Topbar:Button({
    Name = "Unload",
    Icon = "solar:logout-3-bold",
    IconSize = 22,
})

-- ============================================
-- TAB 1: VIP
-- ============================================
local TabVIP = Window:Tab({
    Title = "VIP",
    Icon = "solar:crown-bold",
})

TabVIP:Select()

TabVIP:Section({
    Title = "Ultimate Automatic",
    Desc = "Smart AI & Auto Farming Features",
})

TabVIP:Toggle({
    Title = "Auto Play (Smart AI / AutoFarmBot)",
    Desc = "Bot cerdas pencari Generator/ Gate yang bisa otomatis kabur dari Killer",
    Value = Config.AutoPlay,
    Callback = function(val)
        Config.AutoPlay = val
    end,
})

TabVIP:Toggle({
    Title = "Auto Dagger (Auto Parry)",
    Desc = "Menangkis serangan Killer secara instan dari jarak tertentu",
    Value = Config.AutoDagger,
    Callback = function(val)
        Config.AutoDagger = val
    end,
})

TabVIP:Slider({
    Title = "Auto Dagger Range",
    Step = 1,
    Value = {
        Min = 5,
        Max = 50,
        Default = 25,
    },
    Callback = function(value)
        Config.AutoDaggerRange = tonumber(value)
    end,
})

TabVIP:Toggle({
    Title = "Auto Wiggle Master",
    Desc = "Memberontak dan lepas dari panggulan Killer secara instan",
    Value = Config.AutoWiggle,
    Callback = function(val)
        Config.AutoWiggle = val
    end,
})

TabVIP:Section({
    Title = "Killer Prediction",
    Desc = "Predict siapa Killer selanjutnya (LOBBY ONLY)",
})

TabVIP:Button({
    Title = "Predict Next Killer",
    Icon = "solar:eye-bold",
    IconAlign = "Left",
    Callback = function()
        SafeCall(function()
            if not IsInLobby() then
                WindUI:Notify({
                    Title = "NOT IN LOBBY",
                    Content = "This feature can only be used in the Lobby!\nPlease go back to the lobby first.",
                })
                return
            end

            WindUI:Notify({
                Title = "SCANNING...",
                Content = "Analyzing game data to predict the next Killer...\nPlease wait.",
            })

            -- Delay sedikit agar notification muncul dulu
            task.defer(function()
                local success, predictedPlayer = RunKillerPrediction()

                if success and predictedPlayer then
                    Config.PredictedKiller = predictedPlayer
                    Config.KillerPrediction = true

                    WindUI:Notify({
                        Title = "KILLER PREDICTED!",
                        Content = "The next Killer is predicted to be:\n\n" .. predictedPlayer.Name .. "\n\nPrepare yourself accordingly!",
                    })
                else
                    WindUI:Notify({
                        Title = "PREDICTION FAILED",
                        Content = "Could not predict the next Killer.\n\nPossible reasons:\n- Game uses server-side role assignment\n- No role data found in client\n- Try again when more players are in lobby",
                    })
                end
            end)
        end)
    end,
})

-- ============================================
-- TAB 2: SURVIVOR
-- ============================================
local TabSurvivor = Window:Tab({
    Title = "Survivor",
    Icon = "solar:heart-pulse-bold",
})

TabSurvivor:Section({
    Title = "Movement & Health",
    Desc = "Speed, NoClip, God Mode, dan fitur survivability lainnya",
})

TabSurvivor:Toggle({
    Title = "Speed Boost & Custom Speed",
    Desc = "Menambah kecepatan lari sesuai slider di bawah",
    Value = Config.SpeedBoost,
    Callback = function(val)
        Config.SpeedBoost = val
        if val then
            SafeCall(function() Humanoid.WalkSpeed = Config.CustomSpeed end)
        else
            SafeCall(function() Humanoid.WalkSpeed = 16 end)
        end
    end,
})

TabSurvivor:Slider({
    Title = "Custom Speed",
    Step = 1,
    Value = { Min = 16, Max = 100, Default = 16 },
    Callback = function(value)
        Config.CustomSpeed = tonumber(value)
        if Config.SpeedBoost then
            SafeCall(function() Humanoid.WalkSpeed = Config.CustomSpeed end)
        end
    end,
})

TabSurvivor:Toggle({
    Title = "No Slowdown",
    Desc = "Kebal terhadap semua efek perlambatan gerak",
    Value = Config.NoSlowdown,
    Callback = function(val) Config.NoSlowdown = val end,
})

TabSurvivor:Toggle({
    Title = "No Clip",
    Desc = "Menembus dinding dan objek",
    Value = Config.NoClip,
    Callback = function(val) Config.NoClip = val end,
})

TabSurvivor:Space({ Columns = 2 })

local GroupSurv1 = TabSurvivor:Group()

GroupSurv1:Button({
    Title = "Force Reset State",
    Icon = "solar:restart-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        SafeCall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.PlatformStand = false
                    hum.Sit = false
                end
                for _, anim in ipairs(char:GetDescendants()) do
                    if anim:IsA("Animator") then
                        for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                            track:Stop()
                        end
                    end
                end
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
                end
            end
            WindUI:Notify({ Title = "Reset", Content = "Character state has been reset." })
        end)
    end,
})

GroupSurv1:Space({ Columns = 0.5 })

GroupSurv1:Button({
    Title = "Instant Heal",
    Icon = "solar:heart-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        SafeCall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = hum.MaxHealth end
            end
            WindUI:Notify({ Title = "Healed", Content = "Health restored to max!" })
        end)
    end,
})

TabSurvivor:Space({ Columns = 1 })

TabSurvivor:Section({
    Title = "Defense & Stealth",
    Desc = "Perlindungan dan fitur stealth",
})

TabSurvivor:Toggle({
    Title = "Silent Actions (Anti Noise)",
    Desc = "Berlari dan melompat tanpa memberikan notifikasi ke Killer",
    Value = Config.SilentActions,
    Callback = function(val) Config.SilentActions = val end,
})

TabSurvivor:Toggle({
    Title = "Anti Fall Damage",
    Desc = "Mencegah damage saat jatuh dari tempat tinggi",
    Value = Config.AntiFallDamage,
    Callback = function(val) Config.AntiFallDamage = val end,
})

TabSurvivor:Toggle({
    Title = "God Mode",
    Desc = "Kebal dari pukulan killer (Max Health = infinity)",
    Value = Config.GodMode,
    Callback = function(val)
        Config.GodMode = val
        if val then
            SafeCall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
                end
            end)
        else
            SafeCall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.MaxHealth = 100; hum.Health = 100 end
                end
            end)
        end
    end,
})

TabSurvivor:Toggle({
    Title = "Anti Knock",
    Desc = "Mencegah karakter knocked down saat dipukul",
    Value = Config.AntiKnock,
    Callback = function(val) Config.AntiKnock = val end,
})

TabSurvivor:Toggle({
    Title = "Auto Heal Aura",
    Desc = "Menyembuhkan teman satu tim di sekitar secara otomatis",
    Value = Config.AutoHealAura,
    Callback = function(val) Config.AutoHealAura = val end,
})

TabSurvivor:Slider({
    Title = "Heal Aura Range",
    Step = 1,
    Value = { Min = 10, Max = 80, Default = 30 },
    Callback = function(value) Config.AutoHealAuraRange = tonumber(value) end,
})

-- ============================================
-- TAB 3: KILLER
-- ============================================
local TabKiller = Window:Tab({
    Title = "Killer",
    Icon = "solar:skull-bold",
})

TabKiller:Section({
    Title = "Vein Killer Modification",
    Desc = "Modifikasi dan peningkatan kemampuan Killer",
})

TabKiller:Toggle({
    Title = "Vein Spear: Drop Prediction",
    Desc = "Aimbot tombak yang mengarah ke atas untuk target jauh",
    Value = Config.VeinSpearDrop,
    Callback = function(val) Config.VeinSpearDrop = val end,
})

TabKiller:Toggle({
    Title = "Vein Spear: No Gravity",
    Desc = "Lemparan tombak terbang lurus tanpa gravitasi",
    Value = Config.VeinSpearNoGravity,
    Callback = function(val) Config.VeinSpearNoGravity = val end,
})

TabKiller:Toggle({
    Title = "Anti Blind (No Fog/Flash)",
    Desc = "Kebal terhadap efek kabut dan kilatan cahaya",
    Value = Config.AntiBlind,
    Callback = function(val) Config.AntiBlind = val end,
})

TabKiller:Toggle({
    Title = "Anti Stun (Pallet Bounce)",
    Desc = "Mencegah efek stun saat terkena bantingan Pallet",
    Value = Config.AntiStun,
    Callback = function(val) Config.AntiStun = val end,
})

TabKiller:Toggle({
    Title = "Double Damage Generator",
    Desc = "Menendang generator berkali-kali dalam satu klik",
    Value = Config.DoubleDamageGen,
    Callback = function(val) Config.DoubleDamageGen = val end,
})

TabKiller:Slider({
    Title = "Damage Multiplier",
    Step = 1,
    Value = { Min = 2, Max = 20, Default = 5 },
    Callback = function(value) Config.DoubleDamageMultiplier = tonumber(value) end,
})

TabKiller:Space({ Columns = 2 })

local GroupKill1 = TabKiller:Group()

GroupKill1:Button({
    Title = "Activate Killer Power",
    Icon = "solar:bolt-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        SafeCall(function()
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local name = string.lower(obj.Name)
                    if name:find("power") or name:find("ability") or name:find("killer") then
                        SafeCall(function() obj:FireServer() end)
                    end
                end
            end
            WindUI:Notify({ Title = "Killer Power", Content = "Attempting to activate Killer power..." })
        end)
    end,
})

GroupKill1:Space({ Columns = 0.5 })

GroupKill1:Button({
    Title = "Teleport to Survivor",
    Icon = "solar:map-point-bold",
    IconAlign = "Left",
    Size = "Small",
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
                local randomTarget = targets[math.random(1, #targets)]
                local targetRoot = randomTarget.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot and myRoot then
                    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
                end
                WindUI:Notify({ Title = "Teleported", Content = "Teleported to " .. randomTarget.Name })
            end
        end)
    end,
})

-- ============================================
-- TAB 4: VISUALS
-- ============================================
local TabVisuals = Window:Tab({
    Title = "Visuals",
    Icon = "solar:eye-bold",
})

TabVisuals:Section({
    Title = "ESP & Player Tracking",
    Desc = "Wallhack dan informasi visual di map",
})

TabVisuals:Toggle({
    Title = "Player ESP",
    Desc = "Menampilkan lokasi Survivor (hijau) & Killer (merah) + jarak",
    Value = Config.PlayerESP,
    Callback = function(val) Config.PlayerESP = val end,
})

TabVisuals:Toggle({
    Title = "ESP Generator (%)",
    Desc = "Menampilkan lokasi dan persentase Generator",
    Value = Config.GeneratorESP,
    Callback = function(val) Config.GeneratorESP = val end,
})

TabVisuals:Toggle({
    Title = "ESP Pallet",
    Desc = "Menampilkan lokasi Pallet",
    Value = Config.PalletESP,
    Callback = function(val) Config.PalletESP = val end,
})

TabVisuals:Toggle({
    Title = "ESP Exit Gate",
    Desc = "Menampilkan lokasi Exit Gate",
    Value = Config.ExitGateESP,
    Callback = function(val) Config.ExitGateESP = val end,
})

TabVisuals:Toggle({
    Title = "ESP Hook",
    Desc = "Menampilkan lokasi Hook",
    Value = Config.HookESP,
    Callback = function(val) Config.HookESP = val end,
})

TabVisuals:Toggle({
    Title = "ESP Window",
    Desc = "Menampilkan lokasi Window",
    Value = Config.WindowESP,
    Callback = function(val) Config.WindowESP = val end,
})

TabVisuals:Section({
    Title = "Camera & Rendering",
    Desc = "Pengaturan FOV, Crosshair, dan efek visual",
})

TabVisuals:Toggle({
    Title = "Enable Custom FOV",
    Desc = "Mengatur jarak pandang kamera sesuai keinginan",
    Value = Config.CustomFOV,
    Callback = function(val)
        Config.CustomFOV = val
        if val then
            SafeCall(function() Camera.FieldOfView = Config.FOVValue end)
        else
            SafeCall(function() Camera.FieldOfView = Config.DefaultFOV end)
        end
    end,
})

TabVisuals:Slider({
    Title = "FOV Value",
    Step = 1,
    Value = { Min = 30, Max = 120, Default = 70 },
    Callback = function(value)
        Config.FOVValue = tonumber(value)
        Config.DefaultFOV = tonumber(value)
        if Config.CustomFOV then
            SafeCall(function() Camera.FieldOfView = Config.FOVValue end)
        end
    end,
})

TabVisuals:Toggle({
    Title = "Show Crosshair",
    Desc = "Menampilkan titik bidik di tengah layar",
    Value = Config.ShowCrosshair,
    Callback = function(val) Config.ShowCrosshair = val end,
})

TabVisuals:Toggle({
    Title = "Remove Blur & Bloom",
    Desc = "Mematikan efek buram jarak jauh dan pantulan cahaya",
    Value = Config.RemoveBlur,
    Callback = function(val) Config.RemoveBlur = val end,
})

TabVisuals:Toggle({
    Title = "Force Fullbright",
    Desc = "Menerangkan seluruh map tanpa bayangan dan kabut",
    Value = Config.ForceFullbright,
    Callback = function(val) Config.ForceFullbright = val end,
})

TabVisuals:Toggle({
    Title = "Extreme Potato Mode",
    Desc = "Menghapus semua tekstur dan partikel untuk FPS maksimal",
    Value = Config.PotatoMode,
    Callback = function(val) Config.PotatoMode = val end,
})

-- ============================================
-- TAB 5: COMBAT
-- ============================================
local TabCombat = Window:Tab({
    Title = "Combat",
    Icon = "solar:sword-bold",
})

TabCombat:Section({
    Title = "Targeting System",
    Desc = "Aimbot, Tracer, dan sistem kunci target",
})

TabCombat:Toggle({
    Title = "Enable Aimbot",
    Desc = "Mengunci bidikan kamera ke musuh terdekat",
    Value = Config.AimbotEnabled,
    Callback = function(val) Config.AimbotEnabled = val end,
})

TabCombat:Slider({
    Title = "Aim Radius",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(value) Config.AimRadius = tonumber(value) end,
})

TabCombat:Toggle({
    Title = "Show Target Tracer",
    Desc = "Menarik garis laser merah ke arah target",
    Value = Config.ShowTracer,
    Callback = function(val) Config.ShowTracer = val end,
})

TabCombat:Toggle({
    Title = "Lock On Highlight",
    Desc = "Membuat tubuh target bersinar (Merah/Emas)",
    Value = Config.LockOnHighlight,
    Callback = function(val) Config.LockOnHighlight = val end,
})

TabCombat:Space({ Columns = 2 })

local GroupCombat1 = TabCombat:Group()

GroupCombat1:Button({
    Title = "Toggle FPP / TPP",
    Icon = "solar:camera-rotate-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        SafeCall(function()
            if Camera.CameraType == Enum.CameraType.Scriptable then
                Camera.CameraType = Enum.CameraType.Custom
            else
                Camera.CameraType = Enum.CameraType.Scriptable
            end
            WindUI:Notify({ Title = "Camera", Content = "Camera view toggled." })
        end)
    end,
})

GroupCombat1:Space({ Columns = 0.5 })

TabCombat:Space({ Columns = 1 })

TabCombat:Section({
    Title = "Offensive Combat",
    Desc = "Serangan otomatis dan peningkatan hitbox",
})

TabCombat:Toggle({
    Title = "Expand Killer Hitbox",
    Desc = "Memperbesar ukuran tubuh Killer agar mudah dipukul/stun",
    Value = Config.ExpandKillerHitbox,
    Callback = function(val) Config.ExpandKillerHitbox = val end,
})

TabCombat:Toggle({
    Title = "Auto Attack",
    Desc = "Killer otomatis memukul musuh yang masuk dalam jangkauan",
    Value = Config.AutoAttack,
    Callback = function(val) Config.AutoAttack = val end,
})

TabCombat:Slider({
    Title = "Auto Attack Range",
    Step = 1,
    Value = { Min = 3, Max = 20, Default = 8 },
    Callback = function(value) Config.AutoAttackRange = tonumber(value) end,
})

-- ============================================
-- TAB 6: AUTOMATION
-- ============================================
local TabAutomation = Window:Tab({
    Title = "Automation",
    Icon = "solar:settings-bold",
})

TabAutomation:Section({
    Title = "Generator & Utility",
    Desc = "Otomasi Skill Check, Generator, dan fitur escape",
})

TabAutomation:Toggle({
    Title = "Auto Generator (Skill Check)",
    Desc = "Menyelesaikan Skill Check secara otomatis tanpa ledakan",
    Value = Config.AutoGenerator,
    Callback = function(val) Config.AutoGenerator = val end,
})

TabAutomation:Dropdown({
    Title = "Auto Gen Mode",
    Value = Config.AutoGenMode,
    Values = { "Perfect", "Neutral" },
    Callback = function(value)
        Config.AutoGenMode = value
    end,
})

TabAutomation:Button({
    Title = "Boost All Gen (Group Project)",
    Icon = "solar:bolt-circle-bold",
    IconAlign = "Left",
    Callback = function()
        SafeCall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local name = string.lower(obj.Name)
                if (name:find("generator") or name:find("gen")) and obj:IsA("BasePart") then
                    for _, attrName in ipairs(obj:GetAttributes()) do
                        if string.lower(attrName):find("progress") or string.lower(attrName):find("percent") then
                            SafeCall(function() obj:SetAttribute(attrName, 100) end)
                        end
                    end
                    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                            local rName = string.lower(remote.Name)
                            if rName:find("gen") or rName:find("progress") or rName:find("repair") then
                                SafeCall(function()
                                    if remote:IsA("RemoteEvent") then
                                        remote:FireServer(obj, 100)
                                    else
                                        remote:InvokeServer(obj, 100)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            WindUI:Notify({ Title = "Boost Gen", Content = "Attempting to boost all generators..." })
        end)
    end,
})

TabAutomation:Toggle({
    Title = "Instant Escape (Gate)",
    Desc = "Otomatis menarik tuas gerbang dan teleport ke zona Finish",
    Value = Config.InstantEscape,
    Callback = function(val) Config.InstantEscape = val end,
})

TabAutomation:Toggle({
    Title = "Self UnHook (100% Success)",
    Desc = "Manipulasi peluang agar pasti berhasil lepas dari gantungan",
    Value = Config.SelfUnHook,
    Callback = function(val) Config.SelfUnHook = val end,
})

-- ============================================
-- SECTION 5: ESP DRAWING SYSTEM
-- ============================================
local ESPObjects = {}

local function ClearESP()
    SafeCall(function()
        for _, obj in ipairs(ESPObjects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        ESPObjects = {}
    end)
end

local function CreateESPBox(part, color, label, text)
    SafeCall(function()
        local box = Instance.new("BillboardGui")
        box.Name = "VD_ESP_" .. label
        box.Adornee = part
        box.Size = UDim2.new(0, 200, 0, 50)
        box.StudsOffset = Vector3.new(0, 3, 0)
        box.AlwaysOnTop = true
        box.Parent = part

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.5
        bg.Parent = box

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold
        lbl.Parent = bg

        local hl = Instance.new("Highlight")
        hl.Name = "VD_ESP_HL_" .. label
        hl.Adornee = part
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.7
        hl.OutlineTransparency = 0.3
        hl.Parent = part

        table.insert(ESPObjects, box)
        table.insert(ESPObjects, hl)
    end)
end

-- ============================================
-- SECTION 6: CROSSHAIR & TRACER
-- ============================================
local CrosshairGui = nil

local function UpdateCrosshair()
    SafeCall(function()
        if Config.ShowCrosshair then
            if not CrosshairGui then
                CrosshairGui = Instance.new("ScreenGui")
                CrosshairGui.Name = "VDCrosshair"
                CrosshairGui.ResetOnSpawn = false
                SafeCall(function() CrosshairGui.Parent = game:GetService("CoreGui") end)
                if not CrosshairGui.Parent then CrosshairGui.Parent = LocalPlayer.PlayerGui end

                local vLine = Instance.new("Frame")
                vLine.Size = UDim2.new(0, 2, 0, 20)
                vLine.Position = UDim2.new(0.5, -1, 0.5, -10)
                vLine.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                vLine.BorderSizePixel = 0
                vLine.Parent = CrosshairGui

                local hLine = Instance.new("Frame")
                hLine.Size = UDim2.new(0, 20, 0, 2)
                hLine.Position = UDim2.new(0.5, -10, 0.5, -1)
                hLine.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                hLine.BorderSizePixel = 0
                hLine.Parent = CrosshairGui

                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 4, 0, 4)
                dot.Position = UDim2.new(0.5, -2, 0.5, -2)
                dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                dot.BorderSizePixel = 0
                dot.Parent = CrosshairGui
            end
        else
            if CrosshairGui and CrosshairGui.Parent then
                CrosshairGui:Destroy()
                CrosshairGui = nil
            end
        end
    end)
end

local TracerLine = nil
local function UpdateTracer(targetPos)
    SafeCall(function()
        if Config.ShowTracer and targetPos then
            if not TracerLine then
                TracerLine = Instance.new("Drawing")
                TracerLine.Visible = false
                TracerLine.Color = Color3.fromRGB(255, 30, 30)
                TracerLine.Thickness = 2
                TracerLine.Transparency = 0.5
                TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            end
            TracerLine.Visible = true
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
            if onScreen then
                TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
            end
        elseif TracerLine then
            TracerLine.Visible = false
        end
    end)
end

-- ============================================
-- SECTION 7: CHARACTER RESPAWN HANDLER
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    SafeCall(function()
        Character = char
        Humanoid = char:WaitForChild("Humanoid")
        HumanoidRootPart = char:WaitForChild("HumanoidRootPart")

        if Config.GodMode then
            Humanoid.MaxHealth = math.huge
            Humanoid.Health = math.huge
        end
        if Config.SpeedBoost then
            Humanoid.WalkSpeed = Config.CustomSpeed
        end
    end)
end)

-- ============================================
-- SECTION 8: MAIN HEARTBEAT LOOP
-- ============================================
RunService.Heartbeat:Connect(function()
    SafeCall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        -- VIP: AUTO PLAY
        if Config.AutoPlay then
            SafeCall(function()
                local nearestObj = nil
                local nearestDist = math.huge

                for _, obj in ipairs(Workspace:GetDescendants()) do
                    local name = string.lower(obj.Name)
                    if (name:find("generator") or name:find("gen") or name:find("exit") or name:find("gate")) and obj:IsA("BasePart") then
                        local dist = (obj.Position - root.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestObj = obj
                        end
                    end
                end

                local nearestKiller = nil
                local killerDist = math.huge
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local kRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        if kRoot then
                            local dist = (kRoot.Position - root.Position).Magnitude
                            if dist < killerDist then
                                killerDist = dist
                                nearestKiller = kRoot
                            end
                        end
                    end
                end

                if nearestKiller and killerDist < 40 then
                    local awayDir = (root.Position - nearestKiller.Position).Unit
                    local destination = root.Position + awayDir * 50
                    root.CFrame = CFrame.new(root.Position, destination)
                    hum:Move(destination)
                elseif nearestObj and nearestDist > 5 then
                    root.CFrame = CFrame.new(root.Position, nearestObj.Position)
                    hum:Move(nearestObj.Position)
                end
            end)
        end

        -- VIP: AUTO DAGGER
        if Config.AutoDagger then
            SafeCall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        if pRoot then
                            local dist = (pRoot.Position - root.Position).Magnitude
                            if dist <= Config.AutoDaggerRange then
                                for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                                    if remote:IsA("RemoteEvent") then
                                        local rName = string.lower(remote.Name)
                                        if rName:find("parry") or rName:find("dagger") or rName:find("block") or rName:find("deflect") then
                                            SafeCall(function() remote:FireServer(player, pRoot.Position) end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- VIP: AUTO WIGGLE
        if Config.AutoWiggle then
            SafeCall(function()
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("StringValue") then
                        local name = string.lower(obj.Name)
                        if name:find("carry") or name:find("pickup") or name:find("grab") then
                            for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                                    local rName = string.lower(remote.Name)
                                    if rName:find("wiggle") or rName:find("struggle") or rName:find("escape") or rName:find("break") then
                                        SafeCall(function()
                                            if remote:IsA("RemoteEvent") then remote:FireServer()
                                            else remote:InvokeServer() end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- SURVIVOR: NO SLOWDOWN
        if Config.NoSlowdown then
            SafeCall(function()
                if Config.SpeedBoost then
                    if hum.WalkSpeed < Config.CustomSpeed then hum.WalkSpeed = Config.CustomSpeed end
                else
                    if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                end
            end)
        end

        -- SURVIVOR: NO CLIP
        if Config.NoClip then
            SafeCall(function()
                for _, bodyPart in ipairs(char:GetDescendants()) do
                    if bodyPart:IsA("BasePart") and bodyPart.CanCollide then
                        bodyPart.CanCollide = false
                    end
                end
            end)
        end

        -- SURVIVOR: ANTI FALL DAMAGE
        if Config.AntiFallDamage then
            SafeCall(function()
                if hum:GetState() == Enum.HumanoidStateType.Freefall then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end

        -- SURVIVOR: GOD MODE
        if Config.GodMode then
            SafeCall(function()
                if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
            end)
        end

        -- SURVIVOR: ANTI KNOCK
        if Config.AntiKnock then
            SafeCall(function()
                if hum:GetState() ~= Enum.HumanoidStateType.Running and
                   hum:GetState() ~= Enum.HumanoidStateType.Jumping and
                   hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end

        -- SURVIVOR: AUTO HEAL AURA
        if Config.AutoHealAura then
            SafeCall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        local pHum = player.Character:FindFirstChildOfClass("Humanoid")
                        if pRoot and pHum then
                            local dist = (pRoot.Position - root.Position).Magnitude
                            if dist <= Config.AutoHealAuraRange and pHum.Health < pHum.MaxHealth then
                                for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                                    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                                        local rName = string.lower(remote.Name)
                                        if rName:find("heal") or rName:find("med") or rName:find("recover") then
                                            SafeCall(function()
                                                if remote:IsA("RemoteEvent") then remote:FireServer(player) end
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- KILLER: ANTI BLIND
        if Config.AntiBlind then
            SafeCall(function()
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or
                       effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or
                       effect:IsA("SunRaysEffect") then
                        local name = string.lower(effect.Name)
                        if name:find("blind") or name:find("fog") or name:find("flash") or
                           name:find("stun") or name:find("killer") or name:find("vein") then
                            effect.Enabled = false
                        end
                    end
                end
            end)
        end

        -- KILLER: ANTI STUN
        if Config.AntiStun then
            SafeCall(function()
                if hum.PlatformStand then hum.PlatformStand = false end
            end)
        end

        -- AUTOMATION: SELF UNHOOK
        if Config.SelfUnHook then
            SafeCall(function()
                for _, obj in ipairs(char:GetDescendants()) do
                    local name = string.lower(obj.Name)
                    if (name:find("hook") or name:find("sacrifice")) and obj:IsA("StringValue") then
                        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                                local rName = string.lower(remote.Name)
                                if rName:find("unhook") or rName:find("escape") or rName:find("struggle") or rName:find("sabotage") then
                                    SafeCall(function()
                                        if remote:IsA("RemoteFunction") then remote:InvokeServer(1.0)
                                        elseif remote:IsA("RemoteEvent") then remote:FireServer(1.0) end
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- AUTOMATION: INSTANT ESCAPE
        if Config.InstantEscape then
            SafeCall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    local name = string.lower(obj.Name)
                    if (name:find("exit") or name:find("gate")) and obj:IsA("BasePart") then
                        root.CFrame = obj.CFrame + Vector3.new(0, 5, 10)
                        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                                local rName = string.lower(remote.Name)
                                if rName:find("exit") or rName:find("gate") or rName:find("escape") or rName:find("lever") or rName:find("open") then
                                    SafeCall(function()
                                        if remote:IsA("RemoteEvent") then remote:FireServer(obj, true)
                                        else remote:InvokeServer(obj, true) end
                                    end)
                                end
                            end
                        end
                        break
                    end
                end
            end)
        end
    end)
end)

-- ============================================
-- SECTION 9: RENDER STEPPED LOOP (Visuals & Combat)
-- ============================================
RunService.RenderStepped:Connect(function()
    SafeCall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- VISUALS: PLAYER ESP
        if Config.PlayerESP then
            SafeCall(function()
                ClearESP()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        if pRoot then
                            local dist = math.floor((pRoot.Position - root.Position).Magnitude)
                            local color = Color3.fromRGB(80, 255, 80)
                            local displayName = player.DisplayName or player.Name
                            CreateESPBox(pRoot.Parent, color, displayName, displayName .. " [" .. dist .. "m]")
                        end
                    end
                end
            end)
        end

        -- VISUALS: OBJECT ESP
        if Config.GeneratorESP or Config.PalletESP or Config.ExitGateESP or Config.HookESP or Config.WindowESP then
            SafeCall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        local name = string.lower(obj.Name)
                        local part = obj:IsA("Model") and obj.PrimaryPart or obj
                        if not part then continue end

                        local espColor = nil
                        local espLabel = ""

                        if Config.GeneratorESP and name:find("generator") then
                            espColor = Color3.fromRGB(255, 200, 50); espLabel = "Generator"
                        elseif Config.PalletESP and name:find("pallet") then
                            espColor = Color3.fromRGB(200, 150, 50); espLabel = "Pallet"
                        elseif Config.ExitGateESP and (name:find("exit") or name:find("gate")) then
                            espColor = Color3.fromRGB(50, 200, 255); espLabel = "Exit Gate"
                        elseif Config.HookESP and name:find("hook") then
                            espColor = Color3.fromRGB(255, 100, 100); espLabel = "Hook"
                        elseif Config.WindowESP and name:find("window") then
                            espColor = Color3.fromRGB(150, 255, 150); espLabel = "Window"
                        end

                        if espColor then
                            local existing = part:FindFirstChild("VD_ESP_" .. espLabel)
                            if not existing then
                                CreateESPBox(part, espColor, espLabel .. "_" .. math.random(1000, 9999), espLabel)
                            end
                        end
                    end
                end
            end)
        else
            if not Config.PlayerESP then ClearESP() end
        end

        -- VISUALS: FORCE FULLBRIGHT
        if Config.ForceFullbright then
            SafeCall(function()
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(200, 200, 200)
                Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            end)
        end

        -- VISUALS: REMOVE BLUR & BLOOM
        if Config.RemoveBlur then
            SafeCall(function()
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect") or effect:IsA("BloomEffect") or
                       effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
                        effect.Enabled = false
                    end
                end
            end)
        end

        -- VISUALS: POTATO MODE
        if Config.PotatoMode then
            SafeCall(function()
                Lighting.Brightness = 1
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 100000
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then effect.Enabled = false end
                end
                settings().QualityLevel = 1
            end)
        end

        -- VISUALS: CROSSHAIR
        UpdateCrosshair()

        -- COMBAT: AIMBOT
        if Config.AimbotEnabled then
            SafeCall(function()
                local nearestTarget = nil
                local nearestScreenDist = Config.AimRadius

                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        if pRoot then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(pRoot.Position)
                            if onScreen then
                                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                                if screenDist < nearestScreenDist then
                                    nearestScreenDist = screenDist
                                    nearestTarget = pRoot
                                end
                            end
                        end
                    end
                end

                if nearestTarget then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearestTarget.Position)
                    UpdateTracer(nearestTarget.Position)

                    if Config.LockOnHighlight then
                        SafeCall(function()
                            local targetChar = nearestTarget.Parent
                            if not targetChar:FindFirstChild("VD_LockOn") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "VD_LockOn"
                                hl.Adornee = targetChar
                                hl.FillColor = Color3.fromRGB(255, 50, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 200, 0)
                                hl.FillTransparency = 0.6
                                hl.OutlineTransparency = 0.1
                                hl.Parent = targetChar
                            end
                        end)
                    end
                else
                    UpdateTracer(nil)
                    if Config.LockOnHighlight then
                        SafeCall(function()
                            for _, player in ipairs(Players:GetPlayers()) do
                                if player ~= LocalPlayer and player.Character then
                                    local hl = player.Character:FindFirstChild("VD_LockOn")
                                    if hl then hl:Destroy() end
                                end
                            end
                        end)
                    end
                end
            end)
        else
            UpdateTracer(nil)
            SafeCall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hl = player.Character:FindFirstChild("VD_LockOn")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        end

        -- COMBAT: EXPAND KILLER HITBOX
        if Config.ExpandKillerHitbox then
            SafeCall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        for _, part in ipairs(player.Character:GetDescendants()) do
                            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                part.Size = part.Size * 1.01
                                if part.Size.X > 20 then part.Size = Vector3.new(20, part.Size.Y, part.Size.Z) end
                                if part.Size.Y > 20 then part.Size = Vector3.new(part.Size.X, 20, part.Size.Z) end
                                if part.Size.Z > 20 then part.Size = Vector3.new(part.Size.X, part.Size.Y, 20) end
                            end
                        end
                    end
                end
            end)
        end

        -- COMBAT: AUTO ATTACK
        if Config.AutoAttack then
            SafeCall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        if pRoot then
                            local dist = (pRoot.Position - root.Position).Magnitude
                            if dist <= Config.AutoAttackRange then
                                for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                                    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                                        local rName = string.lower(remote.Name)
                                        if rName:find("attack") or rName:find("hit") or rName:find("punch") or rName:find("strike") or rName:find("slash") then
                                            SafeCall(function()
                                                if remote:IsA("RemoteEvent") then remote:FireServer(player)
                                                else remote:InvokeServer(player) end
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end)

-- ============================================
-- SECTION 10: HOOKS (Silent Actions, Spear, AutoGen, DoubleDmg)
-- ============================================

-- Silent Actions
SafeCall(function()
    local originalFireServer
    originalFireServer = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.SilentActions then
            local name = string.lower(self.Name)
            if name:find("sound") or name:find("noise") or name:find("footstep") or name:find("alert") then
                if method == "FireServer" or method == "InvokeServer" then
                    return nil
                end
            end
        end
        return originalFireServer(self, ...)
    end))
end)

-- Killer Spear No Gravity
SafeCall(function()
    Workspace.ChildAdded:Connect(function(child)
        SafeCall(function()
            if Config.VeinSpearNoGravity then
                local name = string.lower(child.Name)
                if name:find("spear") or name:find("projectile") or name:find("throw") then
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

-- Auto Generator Skill Check
SafeCall(function()
    local originalNameCall
    originalNameCall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.AutoGenerator then
            local name = string.lower(self.Name)
            if name:find("skillcheck") or name:find("skill_check") or name:find("minigame") then
                if method == "FireServer" then
                    if Config.AutoGenMode == "Perfect" then return self:FireServer("perfect", 1.0)
                    else return self:FireServer("neutral", 0.5) end
                elseif method == "InvokeServer" then
                    if Config.AutoGenMode == "Perfect" then return self:InvokeServer("perfect", 1.0)
                    else return self:InvokeServer("neutral", 0.5) end
                end
            end
        end
        return originalNameCall(self, ...)
    end))
end)

-- Double Damage Generator
SafeCall(function()
    local originalNameCall2
    originalNameCall2 = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.DoubleDamageGen then
            local name = string.lower(self.Name)
            if name:find("kick") or name:find("damage") or name:find("gen") or name:find("destroy") or name:find("break") then
                if method == "FireServer" then
                    for i = 2, Config.DoubleDamageMultiplier do
                        SafeCall(function() self:FireServer(...) end)
                    end
                    return self:FireServer(...)
                end
            end
        end
        return originalNameCall2(self, ...)
    end))
end)

-- ============================================
-- SECTION 11: STARTUP
-- ============================================
task.delay(1, function()
    SafeCall(function()
        WindUI:Notify({
            Title = "Violence District v4.0",
            Content = "Script loaded successfully! All features protected by SafeCall.\nToggle: RightControl | UI: WindUI by .ftgs",
        })
    end)
end)

print("[Violence District] Script v4.0 (WindUI) successfully loaded!")
print("[Violence District] Toggle: RightControl | UI: WindUI by Footagesus (.ftgs)")
print("[Violence District] All features protected by SafeCall wrapper")
print("[Violence District] Killer Prediction: VIP Tab -> Works in Lobby only!")
