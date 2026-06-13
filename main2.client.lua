--[[
    ============================================================
    VIOLENCE DISTRICT (DISTRIK KEKERASAN) - ROBLOX SCRIPT
    ============================================================
    Version: 5.0.0 (WindUI Edition — Feature Update)
    Game: Violence District (Distrik Kekerasan)
    UI Library: WindUI by Footagesus (.ftgs)
    
    TABS:
      VIP      — Auto Play, Auto Dagger, Auto Wiggle, Killer Prediction
      Survivor — Speed, NoClip, NoSlowdown, GodMode, Anti Knock, Heal Aura
      Killer   — Vein Spear, Anti Blind/Stun, Double Dmg, Teleport, Power
      Visuals  — Player ESP, Individual Object ESP, FOV, Crosshair, Fullbright
      Combat   — Aimbot, Tracer, LockOn, FPP/TPP, Expand Hitbox, Auto Attack
      Utility  — Auto Gen, Boost Gen, Instant Escape, Self UnHook, Anti AFK,
                 Auto Pallet, Spectator Freecam
    
    ERROR HANDLING: All features wrapped in pcall() / SafeCall.
    ============================================================
--]]

local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

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
    Author = "v5.0 by Zetttify",
    Icon = "rbxassetid://80069564692166",
    Theme = ThemeName,
    NewElements = true,
    Transparent = true,
    ToggleKey = Enum.KeyCode.RightControl,
    Acrylic = true,
})

local Tag = Window:Tag({
    Title = "PREMIUM",
    Color = "Text",
})

local TopbarButton1 = Window.Topbar:Button({
    Name = "Unload Script",
    Icon = "sfsymbols:printerFill",
    IconSize = 22,
    Callback = function()
        Window:Destroy()
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════════════

local Players          = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace        = cloneref(game:GetService("Workspace"))
local TweenService     = cloneref(game:GetService("TweenService"))
local Lighting         = cloneref(game:GetService("Lighting"))

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

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

    -- Killer Prediction (Lobby Only)
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
            if n:find("killer") or n:find("vein") or n:find("spear") or n:find("weapon") then
                return true
            end
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
--  LOBBY DETECTION SYSTEM (6 Methods)
-- ═══════════════════════════════════════════════════════════════════════

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
        -- METODE 4: SpawnLocation
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
        -- METODE 6: RemoteFunction
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
        -- Try InvokeServer for role info
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
                            return true, obj.Value
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

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 1 — VIP
-- ═══════════════════════════════════════════════════════════════════════

local TabVIP = Window:Tab({
    Title = "VIP",
    Icon = "solar:crown-bold",
})

TabVIP:Select()

TabVIP:Section({
    Title = "VIP (Ultimate Automatic)",
    Desc = "Bot cerdas pencari Generator, Auto Parry, dan Wiggle Master",
})

TabVIP:Space({ Columns = 2 })

local VIPGroup1 = TabVIP:Group()

VIPGroup1:Toggle({
    Title = "Auto Play (Smart AI)",
    Value = false,
    Callback = function(v)
        Config.AutoPlay = v
        if v then WindUI:Notify({ Title = "Auto Play", Content = "Bot AI aktif — mencari Generator & kabur dari Killer" }) end
    end,
})

VIPGroup1:Space({ Columns = 0.5 })

VIPGroup1:Button({
    Title = "Wiggle Master",
    Justify = "Center",
    Icon = "solar:hand-shake-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        Config.WiggleMaster = not Config.WiggleMaster
        WindUI:Notify({ Title = "Wiggle Master", Content = Config.WiggleMaster and "ON — Lepas dari panggulan!" or "OFF" })
    end,
})

TabVIP:Space({ Columns = 1 })

TabVIP:Section({
    Title = "Flee Distance",
    TextSize = 16,
    FontWeight = Enum.FontWeight.SemiBold,
})

TabVIP:Slider({
    IsTooltip = true,
    Step = 5,
    Value = {
        Min = 20,
        Max = 80,
        Default = 40,
    },
    Icons = {
        From = "solar:running-2-bold",
        To = "solar:running-2-bold",
    },
    Callback = function(value)
        Config.AutoPlayFleeDist = value
    end,
})

TabVIP:Space({ Columns = 1 })

TabVIP:Section({
    Title = "Auto Dagger (Auto Parry)",
    Desc = "Menangkis serangan Killer secara instan dengan Parrying Dagger",
})

TabVIP:Toggle({
    Title = "Auto Dagger",
    Value = false,
    Callback = function(v)
        Config.AutoDagger = v
        if v then WindUI:Notify({ Title = "Auto Dagger", Content = "Auto Parry aktif!" }) end
    end,
})

TabVIP:Space({ Columns = 1 })

TabVIP:Section({
    Title = "Dagger Parry Range",
    TextSize = 16,
    FontWeight = Enum.FontWeight.SemiBold,
})

TabVIP:Slider({
    IsTooltip = true,
    Step = 5,
    Value = {
        Min = 10,
        Max = 100,
        Default = 30,
    },
    Icons = {
        From = "solar:minimize-bold",
        To = "solar:maximize-bold",
    },
    Callback = function(value)
        Config.AutoDaggerRange = value
    end,
})

TabVIP:Space({ Columns = 1 })

TabVIP:Section({
    Title = "Killer Prediction",
    Desc = "Predict siapa Killer selanjutnya (LOBBY ONLY)",
})

TabVIP:Button({
    Title = "Predict Next Killer",
    Icon = "solar:magnifer-bold",
    IconAlign = "Left",
    Callback = function()
        SafeCall(function()
            if not IsInLobby() then
                WindUI:Notify({
                    Title = "NOT IN LOBBY",
                    Content = "Fitur ini hanya bisa di Lobby!\nKembali ke lobby dulu.",
                })
                return
            end
            WindUI:Notify({
                Title = "SCANNING...",
                Content = "Menganalisis data game untuk prediksi Killer...\nMohon tunggu.",
            })
            task.defer(function()
                local success, predictedPlayer = RunKillerPrediction()
                if success and predictedPlayer then
                    Config.PredictedKiller = predictedPlayer
                    Config.KillerPrediction = true
                    WindUI:Notify({
                        Title = "KILLER PREDICTED!",
                        Content = "Killer selanjutnya diprediksi:\n\n" .. predictedPlayer.Name .. "\n\nSiapkan diri kamu!",
                    })
                else
                    WindUI:Notify({
                        Title = "PREDICTION FAILED",
                        Content = "Tidak bisa memprediksi Killer.\n\nAlasan:\n- Role assignment server-side\n- Data role tidak ditemukan di client\n- Coba lagi saat lebih banyak pemain di lobby",
                    })
                end
            end)
        end)
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 2 — SURVIVOR
-- ═══════════════════════════════════════════════════════════════════════

local TabSurv = Window:Tab({
    Title = "Survivor",
    Icon = "solar:shield-bold",
})

TabSurv:Section({
    Title = "Movement",
    Desc = "Kecepatan, NoClip, anti-slowdown, dan anti-stuck",
})

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

TabSurv:Space({ Columns = 1 })

TabSurv:Section({
    Title = "Custom Speed",
    TextSize = 16,
    FontWeight = Enum.FontWeight.SemiBold,
})

TabSurv:Slider({
    IsTooltip = true,
    Step = 1,
    Value = {
        Min = 16,
        Max = 100,
        Default = 16,
    },
    Icons = {
        From = "solar:wind-bold",
        To = "solar:tornado-bold",
    },
    Callback = function(value)
        Config.CustomSpeed = value
        if Config.SpeedBoost then
            local h = getHumanoid()
            if h then h.WalkSpeed = value end
        end
    end,
})

TabSurv:Space({ Columns = 1 })

TabSurv:Space({ Columns = 2 })

local SurvGroup1 = TabSurv:Group()

SurvGroup1:Toggle({
    Title = "No Slowdown",
    Value = false,
    Callback = function(v)
        Config.NoSlowdown = v
        if v then WindUI:Notify({ Title = "No Slowdown", Content = "Kebal semua efek perlambatan!" }) end
    end,
})

SurvGroup1:Space({ Columns = 0.5 })

SurvGroup1:Toggle({
    Title = "No Clip",
    Value = false,
    Callback = function(v)
        Config.NoClip = v
        if v then WindUI:Notify({ Title = "No Clip", Content = "Menembus dinding aktif!" }) end
    end,
})

TabSurv:Space({ Columns = 1 })

TabSurv:Section({
    Title = "Anti-Stuck & Silent",
    Desc = "Reset state karakter dan bergerak tanpa suara",
})

TabSurv:Space({ Columns = 2 })

local SurvGroup2 = TabSurv:Group()

SurvGroup2:Toggle({
    Title = "Silent Actions",
    Value = false,
    Callback = function(v)
        Config.SilentActions = v
        if v then WindUI:Notify({ Title = "Silent Actions", Content = "Bergerak tanpa suara ke Killer" }) end
    end,
})

SurvGroup2:Space({ Columns = 0.5 })

SurvGroup2:Button({
    Title = "Force Reset",
    Justify = "Center",
    Icon = "solar:restart-circle-bold",
    IconAlign = "Left",
    Size = "Small",
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
        WindUI:Notify({ Title = "Reset", Content = "Karakter state di-reset!" })
    end,
})

TabSurv:Space({ Columns = 1 })

TabSurv:Toggle({
    Title = "Anti Fall Damage",
    Value = false,
    Callback = function(v)
        Config.AntiFallDamage = v
        if v then WindUI:Notify({ Title = "Anti Fall", Content = "Fall damage dinonaktifkan!" }) end
    end,
})

TabSurv:Space({ Columns = 1 })

TabSurv:Section({
    Title = "Health & Defense",
    Desc = "God Mode, Heal, Anti Knock, dan Heal Aura",
})

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
        else
            SafeCall(function()
                local hum = getHumanoid()
                if hum then hum.MaxHealth = 100; hum.Health = 100 end
            end)
        end
        if v then WindUI:Notify({ Title = "God Mode", Content = "HP selalu penuh!" }) end
    end,
})

TabSurv:Space({ Columns = 2 })

local SurvGroup3 = TabSurv:Group()

SurvGroup3:Toggle({
    Title = "Anti Knock",
    Value = false,
    Callback = function(v)
        Config.AntiKnock = v
        if v then WindUI:Notify({ Title = "Anti Knock", Content = "Tidak bisa di-knock down!" }) end
    end,
})

SurvGroup3:Space({ Columns = 0.5 })

SurvGroup3:Button({
    Title = "Instant Heal",
    Justify = "Center",
    Icon = "solar:heart-pulse-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
            WindUI:Notify({ Title = "Healed", Content = "Dipulihkan ke Max Health!" })
        end
    end,
})

TabSurv:Space({ Columns = 1 })

TabSurv:Section({
    Title = "Auto Heal Aura",
    Desc = "Menyembuhkan teman satu tim di sekitar secara otomatis",
})

TabSurv:Toggle({
    Title = "Auto Heal Aura",
    Value = false,
    Callback = function(v)
        Config.AutoHealAura = v
        if v then WindUI:Notify({ Title = "Heal Aura", Content = "Menyembuhkan tim secara otomatis!" }) end
    end,
})

TabSurv:Space({ Columns = 1 })

TabSurv:Section({
    Title = "Heal Aura Range",
    TextSize = 16,
    FontWeight = Enum.FontWeight.SemiBold,
})

TabSurv:Slider({
    IsTooltip = true,
    Step = 1,
    Value = {
        Min = 10,
        Max = 80,
        Default = 25,
    },
    Icons = {
        From = "solar:minimize-bold",
        To = "solar:maximize-bold",
    },
    Callback = function(value)
        Config.HealAuraRange = value
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 3 — KILLER
-- ═══════════════════════════════════════════════════════════════════════

local TabKill = Window:Tab({
    Title = "Killer",
    Icon = "solar:danger-triangle-bold",
})

TabKill:Section({
    Title = "Vein Spear",
    Desc = "Modifikasi tombak: Aimbot prediksi & No Gravity",
})

TabKill:Space({ Columns = 2 })

local KillGroup1 = TabKill:Group()

KillGroup1:Toggle({
    Title = "Drop Prediction",
    Value = false,
    Callback = function(v)
        Config.SpearDropPrediction = v
        if v then WindUI:Notify({ Title = "Spear Prediction", Content = "Drop compensation aktif!" }) end
    end,
})

KillGroup1:Space({ Columns = 0.5 })

KillGroup1:Toggle({
    Title = "No Gravity",
    Value = false,
    Callback = function(v)
        Config.SpearNoGravity = v
        if v then WindUI:Notify({ Title = "No Gravity", Content = "Tombak terbang lurus!" }) end
    end,
})

TabKill:Space({ Columns = 1 })

TabKill:Section({
    Title = "Killer Defense",
    Desc = "Anti-Blind dan Anti-Stun",
})

TabKill:Space({ Columns = 2 })

local KillGroup2 = TabKill:Group()

KillGroup2:Toggle({
    Title = "Anti-Blind",
    Value = false,
    Callback = function(v)
        Config.AntiBlind = v
        if v then WindUI:Notify({ Title = "Anti-Blind", Content = "Kebal fog & flash!" }) end
    end,
})

KillGroup2:Space({ Columns = 0.5 })

KillGroup2:Toggle({
    Title = "Anti-Stun",
    Value = false,
    Callback = function(v)
        Config.AntiStun = v
        if v then WindUI:Notify({ Title = "Anti-Stun", Content = "Tidak bisa di-stun!" }) end
    end,
})

TabKill:Space({ Columns = 1 })

TabKill:Section({
    Title = "Generator Attack",
    Desc = "Kerusakan Generator berlipat dan Activate Power",
})

TabKill:Toggle({
    Title = "Double Damage Generator",
    Value = false,
    Callback = function(v)
        Config.DoubleDamageGen = v
        if v then WindUI:Notify({ Title = "Double Damage", Content = "Generator damage multiplier aktif!" }) end
    end,
})

TabKill:Space({ Columns = 1 })

TabKill:Section({
    Title = "Gen Damage Multiplier",
    TextSize = 16,
    FontWeight = Enum.FontWeight.SemiBold,
})

TabKill:Slider({
    IsTooltip = true,
    Step = 1,
    Value = {
        Min = 2,
        Max = 20,
        Default = 3,
    },
    Icons = {
        From = "solar:bolt-bold",
        To = "solar:bolt-circle-bold",
    },
    Callback = function(value)
        Config.GenDamageMultiplier = value
    end,
})

TabKill:Space({ Columns = 0.5 })

local KillGroup3 = TabKill:Group()

KillGroup3:Button({
    Title = "Activate Power",
    Justify = "Center",
    Icon = "solar:flash-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        local remotes = findRemotes({ "Power", "Ability", "Skill", "Special", "Ultimate" })
        if #remotes > 0 then
            for _, remote in pairs(remotes) do pcall(function() remote:FireServer() end) end
            WindUI:Notify({ Title = "Killer Power", Content = "Kekuatan spesial diaktifkan!" })
        else
            WindUI:Notify({ Title = "Killer Power", Content = "Remote Power tidak ditemukan" })
        end
    end,
})

TabKill:Space({ Columns = 0.5 })

KillGroup3:Button({
    Title = "Teleport to Survivor",
    Justify = "Center",
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
                local myRoot = getRootPart()
                if targetRoot and myRoot then
                    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
                end
                WindUI:Notify({ Title = "Teleported", Content = "Teleport ke " .. randomTarget.Name })
            end
        end)
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 4 — VISUALS
-- ═══════════════════════════════════════════════════════════════════════

local TabVis = Window:Tab({
    Title = "Visuals",
    Icon = "solar:eye-bold",
})

TabVis:Section({
    Title = "ESP System",
    Desc = "Player ESP dan Object ESP",
})

TabVis:Toggle({
    Title = "Player ESP",
    Value = false,
    Callback = function(v)
        Config.PlayerESP = v
        if v then WindUI:Notify({ Title = "Player ESP", Content = "Menampilkan semua pemain!" }) end
    end,
})

TabVis:Toggle({
    Title = "Object ESP (All)",
    Value = false,
    Callback = function(v)
        Config.ObjectESP = v
        if v then
            Config.GeneratorESP = true
            Config.PalletESP = true
            Config.ExitGateESP = true
            Config.HookESP = true
            Config.WindowESP = true
            WindUI:Notify({ Title = "Object ESP", Content = "Semua objek terlihat!" })
        else
            Config.GeneratorESP = false
            Config.PalletESP = false
            Config.ExitGateESP = false
            Config.HookESP = false
            Config.WindowESP = false
        end
    end,
})

TabVis:Space({ Columns = 1 })

TabVis:Section({
    Title = "Individual Object ESP",
    Desc = "Pilih objek mana yang ingin dilihat secara terpisah",
})

TabVis:Space({ Columns = 2 })

local VisGroup1 = TabVis:Group()

VisGroup1:Toggle({
    Title = "ESP Generator",
    Value = false,
    Callback = function(v)
        Config.GeneratorESP = v
    end,
})

VisGroup1:Space({ Columns = 0.5 })

VisGroup1:Toggle({
    Title = "ESP Pallet",
    Value = false,
    Callback = function(v)
        Config.PalletESP = v
    end,
})

TabVis:Space({ Columns = 2 })

local VisGroup2 = TabVis:Group()

VisGroup2:Toggle({
    Title = "ESP Exit Gate",
    Value = false,
    Callback = function(v)
        Config.ExitGateESP = v
    end,
})

VisGroup2:Space({ Columns = 0.5 })

VisGroup2:Toggle({
    Title = "ESP Hook",
    Value = false,
    Callback = function(v)
        Config.HookESP = v
    end,
})

TabVis:Space({ Columns = 2 })

local VisGroup3 = TabVis:Group()

VisGroup3:Toggle({
    Title = "ESP Window",
    Value = false,
    Callback = function(v)
        Config.WindowESP = v
    end,
})

TabVis:Space({ Columns = 1 })

TabVis:Section({
    Title = "Camera & FOV",
    Desc = "Mengatur jarak pandang kamera",
})

TabVis:Toggle({
    Title = "Custom FOV",
    Value = false,
    Callback = function(v)
        Config.CustomFOV = v
        if v then Camera.FieldOfView = Config.FOVValue end
    end,
})

TabVis:Space({ Columns = 1 })

TabVis:Section({
    Title = "FOV Value",
    TextSize = 16,
    FontWeight = Enum.FontWeight.SemiBold,
})

TabVis:Slider({
    IsTooltip = true,
    Step = 1,
    Value = {
        Min = 30,
        Max = 120,
        Default = 70,
    },
    Icons = {
        From = "solar:eye-bold",
        To = "solar:eye-bold",
    },
    Callback = function(value)
        Config.FOVValue = value
        if Config.CustomFOV then Camera.FieldOfView = value end
    end,
})

TabVis:Space({ Columns = 1 })

TabVis:Section({
    Title = "Effects",
    Desc = "Crosshair, Fullbright, Potato Mode",
})

TabVis:Toggle({
    Title = "Show Crosshair",
    Value = false,
    Callback = function(v)
        Config.ShowCrosshair = v
    end,
})

TabVis:Space({ Columns = 2 })

local VisGroup4 = TabVis:Group()

VisGroup4:Toggle({
    Title = "Remove Blur/Bloom",
    Value = false,
    Callback = function(v)
        Config.RemoveBlurBloom = v
        if v then WindUI:Notify({ Title = "Effects Off", Content = "Blur & Bloom dimatikan!" }) end
    end,
})

VisGroup4:Space({ Columns = 0.5 })

VisGroup4:Toggle({
    Title = "Force Fullbright",
    Value = false,
    Callback = function(v)
        Config.ForceFullbright = v
        if v then WindUI:Notify({ Title = "Fullbright", Content = "Map terang tanpa bayangan!" }) end
    end,
})

TabVis:Space({ Columns = 1 })

TabVis:Toggle({
    Title = "Potato Mode",
    Value = false,
    Callback = function(v)
        Config.PotatoMode = v
        if v then WindUI:Notify({ Title = "Potato Mode", Content = "FPS Maksimal — semua efek dimatikan!" }) end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 5 — COMBAT
-- ═══════════════════════════════════════════════════════════════════════

local TabComb = Window:Tab({
    Title = "Combat",
    Icon = "solar:target-bold",
})

TabComb:Section({
    Title = "Aimbot & Targeting",
    Desc = "Mengunci bidikan ke musuh terdekat",
})

TabComb:Toggle({
    Title = "Enable Aimbot",
    Value = false,
    Callback = function(v)
        Config.Aimbot = v
        if v then WindUI:Notify({ Title = "Aimbot", Content = "Mengunci musuh terdekat!" }) end
    end,
})

TabComb:Space({ Columns = 1 })

TabComb:Section({
    Title = "Aim Radius",
    TextSize = 16,
    FontWeight = Enum.FontWeight.SemiBold,
})

TabComb:Slider({
    IsTooltip = true,
    Step = 10,
    Value = {
        Min = 50,
        Max = 500,
        Default = 200,
    },
    Icons = {
        From = "solar:minimize-bold",
        To = "solar:maximize-bold",
    },
    Callback = function(value)
        Config.AimRadius = value
    end,
})

TabComb:Space({ Columns = 1 })

TabComb:Section({
    Title = "Target Visuals",
    Desc = "Tracer dan Highlight target",
})

TabComb:Space({ Columns = 2 })

local CombGroup1 = TabComb:Group()

CombGroup1:Toggle({
    Title = "Target Tracer",
    Value = false,
    Callback = function(v)
        Config.ShowTargetTracer = v
    end,
})

CombGroup1:Space({ Columns = 0.5 })

CombGroup1:Toggle({
    Title = "Lock-On Highlight",
    Value = false,
    Callback = function(v)
        Config.LockOnHighlight = v
    end,
})

TabComb:Space({ Columns = 1 })

TabComb:Section({
    Title = "Camera & Hitbox",
    Desc = "FPP/TPP, Expand Hitbox, Auto Attack",
})

TabComb:Space({ Columns = 2 })

local CombGroup2 = TabComb:Group()

CombGroup2:Button({
    Title = "FPP / TPP",
    Justify = "Center",
    Icon = "solar:camera-rotate-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        local humanoid = getHumanoid()
        if humanoid then
            local current = humanoid.CameraMode
            humanoid.CameraMode = (current == Enum.CameraMode.LockFirstPerson)
                and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson
            local mode = humanoid.CameraMode == Enum.CameraMode.LockFirstPerson and "First Person" or "Third Person"
            WindUI:Notify({ Title = "Camera", Content = "Mode: " .. mode })
        end
    end,
})

CombGroup2:Space({ Columns = 0.5 })

CombGroup2:Button({
    Title = "Instant Heal",
    Justify = "Center",
    Icon = "solar:heart-pulse-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
            WindUI:Notify({ Title = "Healed", Content = "HP pulih!" })
        end
    end,
})

TabComb:Space({ Columns = 1 })

TabComb:Toggle({
    Title = "Expand Hitbox",
    Value = false,
    Callback = function(v)
        Config.ExpandHitbox = v
        if v then WindUI:Notify({ Title = "Expand Hitbox", Content = "Hitbox Killer diperbesar!" }) end
    end,
})

TabComb:Toggle({
    Title = "Auto Attack",
    Value = false,
    Callback = function(v)
        Config.AutoAttack = v
        if v then WindUI:Notify({ Title = "Auto Attack", Content = "Otomatis memukul musuh terdekat!" }) end
    end,
})

TabComb:Space({ Columns = 1 })

TabComb:Section({
    Title = "Auto Attack Range",
    TextSize = 16,
    FontWeight = Enum.FontWeight.SemiBold,
})

TabComb:Slider({
    IsTooltip = true,
    Step = 1,
    Value = {
        Min = 3,
        Max = 25,
        Default = 8,
    },
    Icons = {
        From = "solar:minimize-bold",
        To = "solar:maximize-bold",
    },
    Callback = function(value)
        Config.AutoAttackRange = value
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 6 — UTILITY (Automation + New Features)
-- ═══════════════════════════════════════════════════════════════════════

local TabUtil = Window:Tab({
    Title = "Utility",
    Icon = "solar:settings-bold",
})

TabUtil:Section({
    Title = "Generator",
    Desc = "Auto SkillCheck dan Boost Generator",
})

TabUtil:Toggle({
    Title = "Auto Generator",
    Value = false,
    Callback = function(v)
        Config.AutoGenerator = v
        if v then WindUI:Notify({ Title = "Auto Generator", Content = "SkillCheck otomatis: " .. Config.GenSkillCheckMode }) end
    end,
})

TabUtil:Space({ Columns = 2 })

local UtilGroup1 = TabUtil:Group()

UtilGroup1:Button({
    Title = "Mode: Perfect",
    Justify = "Center",
    Icon = "solar:check-circle-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        Config.GenSkillCheckMode = "Perfect"
        WindUI:Notify({ Title = "SkillCheck", Content = "Mode: Perfect" })
    end,
})

UtilGroup1:Space({ Columns = 0.5 })

UtilGroup1:Button({
    Title = "Mode: Neutral",
    Justify = "Center",
    Icon = "solar:minus-circle-bold",
    IconAlign = "Left",
    Size = "Small",
    Callback = function()
        Config.GenSkillCheckMode = "Neutral"
        WindUI:Notify({ Title = "SkillCheck", Content = "Mode: Neutral" })
    end,
})

TabUtil:Space({ Columns = 1 })

TabUtil:Toggle({
    Title = "Boost All Gen (Continuous)",
    Value = false,
    Callback = function(v)
        Config.BoostAllGen = v
        if v then WindUI:Notify({ Title = "Boost Gen", Content = "Semua generator diboost terus-menerus!" }) end
    end,
})

TabUtil:Space({ Columns = 1 })

TabUtil:Section({
    Title = "Escape & UnHook",
    Desc = "Instant Escape dan Self UnHook 100%",
})

TabUtil:Space({ Columns = 2 })

local UtilGroup2 = TabUtil:Group()

UtilGroup2:Toggle({
    Title = "Instant Escape",
    Value = false,
    Callback = function(v)
        Config.InstantEscape = v
        if v then WindUI:Notify({ Title = "Instant Escape", Content = "Otomatis buka gerbang!" }) end
    end,
})

UtilGroup2:Space({ Columns = 0.5 })

UtilGroup2:Toggle({
    Title = "Self UnHook (100%)",
    Value = false,
    Callback = function(v)
        Config.SelfUnHook = v
        if v then WindUI:Notify({ Title = "Self UnHook", Content = "100% lepas dari Hook!" }) end
    end,
})

TabUtil:Space({ Columns = 1 })

TabUtil:Section({
    Title = "Anti AFK",
    Desc = "Mencegah kick karena tidak aktif (NEW)",
})

TabUtil:Toggle({
    Title = "Anti AFK",
    Value = false,
    Callback = function(v)
        Config.AntiAFK = v
        if v then WindUI:Notify({ Title = "Anti AFK", Content = "Tidak akan di-kick karena idle!" }) end
    end,
})

TabUtil:Space({ Columns = 1 })

TabUtil:Section({
    Title = "Auto Pallet Drop",
    Desc = "Otomatis menjatuhkan Pallet saat Killer mendekat (NEW)",
})

TabUtil:Toggle({
    Title = "Auto Pallet Drop",
    Value = false,
    Callback = function(v)
        Config.AutoPallet = v
        if v then WindUI:Notify({ Title = "Auto Pallet", Content = "Otomatis jatuhkan Pallet!" }) end
    end,
})

TabUtil:Space({ Columns = 1 })

TabUtil:Section({
    Title = "Pallet Drop Range",
    TextSize = 16,
    FontWeight = Enum.FontWeight.SemiBold,
})

TabUtil:Slider({
    IsTooltip = true,
    Step = 1,
    Value = {
        Min = 5,
        Max = 30,
        Default = 15,
    },
    Icons = {
        From = "solar:minimize-bold",
        To = "solar:maximize-bold",
    },
    Callback = function(value)
        Config.AutoPalletRange = value
    end,
})

TabUtil:Space({ Columns = 1 })

TabUtil:Section({
    Title = "Spectator Freecam",
    Desc = "Kamera bebas saat mati untuk mengawasi permainan (NEW)",
})

TabUtil:Toggle({
    Title = "Spectator Freecam",
    Value = false,
    Callback = function(v)
        Config.SpectatorFreecam = v
        if v then WindUI:Notify({ Title = "Freecam", Content = "Spectator cam aktif!" }) end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  CROSSHAIR OVERLAY (manual overlay, bukan bagian WindUI)
-- ═══════════════════════════════════════════════════════════════════════

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VD_Overlays"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local CH = Instance.new("Frame")
CH.Name = "Crosshair"
CH.Size = UDim2.new(0, 24, 0, 24)
CH.Position = UDim2.new(0.5, -12, 0.5, -12)
CH.BackgroundTransparency = 1
CH.Visible = false
CH.ZIndex = 100
CH.Parent = ScreenGui

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
TracerFrame.Visible = false; TracerFrame.ZIndex = 90; TracerFrame.Parent = ScreenGui

local TracerOrigin = Instance.new("Frame")
TracerOrigin.Name = "TracerOrigin"; TracerOrigin.Size = UDim2.new(0, 8, 0, 8)
TracerOrigin.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
TracerOrigin.BorderSizePixel = 0; TracerOrigin.Visible = false
TracerOrigin.ZIndex = 91; TracerOrigin.Parent = ScreenGui
Instance.new("UICorner", TracerOrigin).CornerRadius = UDim.new(1, 0)

local AimCircle = Instance.new("Frame")
AimCircle.Name = "AimCircle"; AimCircle.Size = UDim2.new(0, 400, 0, 400)
AimCircle.Position = UDim2.new(0.5, -200, 0.5, -200)
AimCircle.BackgroundColor3 = Color3.new(1, 1, 1)
AimCircle.BackgroundTransparency = 0.92
AimCircle.BorderSizePixel = 1; AimCircle.BorderColor3 = Color3.fromRGB(255, 80, 80)
AimCircle.Visible = false; AimCircle.ZIndex = 89; AimCircle.Parent = ScreenGui
Instance.new("UICorner", AimCircle).CornerRadius = UDim.new(1, 0)

-- ═══════════════════════════════════════════════════════════════════════
--  ESP SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local PlayerESPTable  = {}
local ObjectESPTable  = {}

local ESP_COLORS = {
    KillerESP   = Color3.fromRGB(255, 50, 50),
    SurvivorESP = Color3.fromRGB(50, 255, 120),
    GenESP      = Color3.fromRGB(255, 220, 50),
    PalletESP   = Color3.fromRGB(160, 100, 40),
    GateESP     = Color3.fromRGB(0, 220, 255),
    HookESP     = Color3.fromRGB(200, 50, 220),
    WindowESP   = Color3.fromRGB(150, 255, 150),
}

local function createPlayerESP(player)
    local char = player.Character
    if not char then return end
    local isKiller = isPlayerKiller(player)
    local color = isKiller and ESP_COLORS.KillerESP or ESP_COLORS.SurvivorESP

    local highlight = Instance.new("Highlight")
    highlight.Name = "VD_ESP"
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = char
    highlight.FillColor = color
    highlight.OutlineColor = isKiller and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(100, 255, 150)
    highlight.Parent = char

    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char
    local bb = Instance.new("BillboardGui")
    bb.Name = "VD_ESP_Info"
    bb.Size = UDim2.new(0, 220, 0, 55)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = (isKiller and "[KILLER] " or "[SURVIVOR] ") .. player.DisplayName
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = bb

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, 0, 0.3, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.45, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.new(1, 1, 1)
    infoLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    infoLabel.TextStrokeTransparency = 0.4
    infoLabel.TextSize = 11
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.Text = "ALIVE | 0m"
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = bb

    local hBg = Instance.new("Frame")
    hBg.Name = "HealthBarBG"
    hBg.Size = UDim2.new(0.8, 0, 0, 4)
    hBg.Position = UDim2.new(0.1, 0, 0.82, 0)
    hBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hBg.BorderSizePixel = 0
    hBg.Parent = bb
    Instance.new("UICorner", hBg).CornerRadius = UDim.new(0, 2)

    local hFill = Instance.new("Frame")
    hFill.Name = "HealthFill"
    hFill.Size = UDim2.new(1, 0, 1, 0)
    hFill.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
    hFill.BorderSizePixel = 0
    hFill.Parent = hBg
    Instance.new("UICorner", hFill).CornerRadius = UDim.new(0, 2)

    PlayerESPTable[player] = {
        highlight = highlight, billboard = bb,
        nameLabel = nameLabel, infoLabel = infoLabel,
        healthFill = hFill, isKiller = isKiller,
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
            hl.FillColor = color; hl.OutlineColor = color
            hl.Parent = obj

            local bb = Instance.new("BillboardGui")
            bb.Name = "VD_ObjESP_Label"
            bb.Size = UDim2.new(0, 160, 0, 35)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true; bb.Parent = obj

            local lbl = Instance.new("TextLabel")
            lbl.Name = "ObjLabel"
            lbl.Size = UDim2.new(1, 0, 0.6, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = color
            lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
            lbl.TextStrokeTransparency = 0.4
            lbl.TextSize = 12; lbl.Font = Enum.Font.GothamBold
            local progress = obj:GetAttribute("Progress") or 0
            lbl.Text = objType .. (objType == "Generator" and (" [" .. math.floor(progress) .. "%]") or "")
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Parent = bb

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
--  SPECTATOR FREECAM SYSTEM (NEW)
-- ═══════════════════════════════════════════════════════════════════════

local FreecamActive = false
local FreecamSpeed = 1
local FreecamPart = nil

local function StartFreecam()
    SafeCall(function()
        FreecamActive = true
        FreecamPart = Instance.new("Part")
        FreecamPart.Name = "VD_FreecamAnchor"
        FreecamPart.Anchored = true
        FreecamPart.CanCollide = false
        FreecamPart.Transparency = 1
        FreecamPart.Size = Vector3.new(1, 1, 1)
        FreecamPart.Parent = Workspace
        FreecamPart.CFrame = Camera.CFrame

        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = FreecamPart.CFrame

        local lastInput = nil
        local conn
        conn = RunService.RenderStepped:Connect(function(dt)
            if not FreecamActive then
                if conn then conn:Disconnect() end
                return
            end
            local dir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

            local speed = FreecamSpeed * 50 * dt
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then speed = speed * 3 end

            if dir.Magnitude > 0 then
                FreecamPart.CFrame = CFrame.new(FreecamPart.Position + dir.Unit * speed, FreecamPart.Position + dir.Unit * speed + Camera.CFrame.LookVector)
            end
            Camera.CFrame = FreecamPart.CFrame
        end)
    end)
end

local function StopFreecam()
    SafeCall(function()
        FreecamActive = false
        Camera.CameraType = Enum.CameraType.Custom
        if FreecamPart then
            FreecamPart:Destroy()
            FreecamPart = nil
        end
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

        -- VIP: AUTO PLAY
        if Config.AutoPlay then
            SafeCall(function()
                local killer = getKiller()
                local kr = killer and killer.Character
                    and (killer.Character:FindFirstChild("HumanoidRootPart") or killer.Character:FindFirstChild("Torso"))

                if kr and (root.Position - kr.Position).Magnitude <= Config.AutoPlayFleeDist then
                    -- Flee from killer
                    local awayDir = (root.Position - kr.Position).Unit
                    local destination = root.Position + awayDir * 50
                    root.CFrame = CFrame.new(root.Position, destination)
                    humanoid:MoveTo(destination)
                    if Config.AutoDagger then
                        for _, r in pairs(findRemotes({ "Parry", "Dagger", "Block", "Counter", "Deflect" })) do
                            pcall(function() r:FireServer() end)
                        end
                    end
                    continue
                end

                local generators = findPartsByName({ "generator", "gen" })
                local gates = findPartsByName({ "gate", "exit" })
                local bestTarget, bestScore = nil, math.huge

                for _, gate in pairs(gates) do
                    if gate:GetAttribute("Open") or gate:GetAttribute("Unlocked") then
                        local score = (gate.Position - root.Position).Magnitude
                        if score < bestScore then bestScore, bestTarget = score, gate end
                    end
                end

                if not bestTarget then
                    for _, gen in pairs(generators) do
                        local dist = (gen.Position - root.Position).Magnitude
                        local progress = gen:GetAttribute("Progress") or 0
                        local score = dist - (progress * 2)
                        if score < bestScore then bestScore, bestTarget = score, gen end
                    end
                end

                if not bestTarget and #gates > 0 then bestTarget = findNearestPart(gates, root.Position) end
                if bestTarget and (bestTarget.Position - root.Position).Magnitude > 5 then
                    humanoid:MoveTo(bestTarget.Position)
                end
            end)
        end

        -- VIP: AUTO DAGGER
        if Config.AutoDagger then
            SafeCall(function()
                local killer = getKiller()
                local kr = killer and killer.Character
                    and (killer.Character:FindFirstChild("HumanoidRootPart") or killer.Character:FindFirstChild("Torso"))
                if kr and (root.Position - kr.Position).Magnitude <= Config.AutoDaggerRange then
                    for _, r in pairs(findRemotes({ "Parry", "Dagger", "Block", "Counter", "Deflect" })) do
                        pcall(function() r:FireServer() end)
                    end
                end
            end)
        end

        -- VIP: WIGGLE MASTER
        if Config.WiggleMaster then
            SafeCall(function()
                local state = humanoid:GetState()
                if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
                    for _, r in pairs(findRemotes({ "Wiggle", "Struggle", "Escape", "Break", "Resist" })) do
                        pcall(function() r:FireServer(math.random(0, 3)) end)
                    end
                end
            end)
        end

        -- SURVIVOR: NO SLOWDOWN
        if Config.NoSlowdown then
            SafeCall(function()
                if Config.SpeedBoost then
                    if humanoid.WalkSpeed < Config.CustomSpeed then humanoid.WalkSpeed = Config.CustomSpeed end
                else
                    if humanoid.WalkSpeed < 16 then humanoid.WalkSpeed = 16 end
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
                if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end

        -- SURVIVOR: GOD MODE
        if Config.GodMode then
            SafeCall(function()
                if humanoid.Health < humanoid.MaxHealth then humanoid.Health = humanoid.MaxHealth end
            end)
        end

        -- SURVIVOR: ANTI KNOCK
        if Config.AntiKnock then
            SafeCall(function()
                local s = humanoid:GetState()
                if s ~= Enum.HumanoidStateType.Running and s ~= Enum.HumanoidStateType.Jumping
                    and s ~= Enum.HumanoidStateType.Freefall then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end

        -- SURVIVOR: AUTO HEAL AURA
        if Config.AutoHealAura then
            SafeCall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        local pHum = player.Character:FindFirstChildOfClass("Humanoid")
                        if pRoot and pHum then
                            local dist = (pRoot.Position - root.Position).Magnitude
                            if dist <= Config.HealAuraRange and pHum.Health < pHum.MaxHealth then
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
                for _, e in pairs(Lighting:GetChildren()) do
                    if e:IsA("PostEffect") then e.Enabled = false end
                end
                local gui = LocalPlayer:FindFirstChild("PlayerGui")
                if gui then
                    for _, obj in pairs(gui:GetDescendants()) do
                        local n = obj.Name:lower()
                        if (obj:IsA("BlurEffect") or obj:IsA("Frame"))
                            and (n:find("flash") or n:find("blind") or n:find("fog") or n:find("blur") or n:find("dark")) then
                            obj.Visible = false; obj.Enabled = false
                        end
                    end
                end
            end)
        end

        -- KILLER: ANTI STUN
        if Config.AntiStun then
            SafeCall(function()
                local s = humanoid:GetState()
                if s == Enum.HumanoidStateType.Stunned or s == Enum.HumanoidStateType.StunnedNoFall then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end

        -- KILLER: DOUBLE DAMAGE GEN
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

        -- AUTOMATION: AUTO GENERATOR
        if Config.AutoGenerator then
            SafeCall(function()
                local near = false
                for _, gen in pairs(findPartsByName({ "generator", "gen" })) do
                    if (gen.Position - root.Position).Magnitude < 12 then near = true; break end
                end
                if near then
                    for _, r in pairs(findRemotes({ "SkillCheck", "Skill", "Check", "HitZone", "MiniGame" })) do
                        pcall(function()
                            if Config.GenSkillCheckMode == "Perfect" then r:FireServer("Perfect", 1.0)
                            else r:FireServer("Neutral", 0.5) end
                        end)
                    end
                end
            end)
        end

        -- AUTOMATION: BOOST ALL GEN (Continuous)
        if Config.BoostAllGen then
            SafeCall(function()
                local gens = findPartsByName({ "generator", "gen" })
                local rems = findRemotes({ "Generator", "Progress", "Repair", "Fix" })
                for _, gen in pairs(gens) do
                    gen:SetAttribute("Progress", 100)
                    for _, r in pairs(rems) do pcall(function() r:FireServer(gen, 100) end) end
                end
            end)
        end

        -- AUTOMATION: INSTANT ESCAPE (Continuous)
        if Config.InstantEscape then
            SafeCall(function()
                local gates = findPartsByName({ "gate", "exit", "door" })
                local rems = findRemotes({ "Gate", "Exit", "Open", "Escape", "Lever", "Complete" })
                for _, gate in pairs(gates) do
                    teleportTo(gate.Position)
                    for _, r in pairs(rems) do pcall(function() r:FireServer(gate) end) end
                end
            end)
        end

        -- AUTOMATION: SELF UNHOOK
        if Config.SelfUnHook then
            SafeCall(function()
                local s = humanoid:GetState()
                if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll then
                    for _, hook in pairs(findPartsByName({ "hook" })) do
                        if (hook.Position - root.Position).Magnitude < 8 then
                            for _, r in pairs(findRemotes({ "Hook", "Unhook", "Escape", "Struggle", "SelfUnhook" })) do
                                pcall(function() r:FireServer(hook, 1.0, true) end)
                            end
                            break
                        end
                    end
                end
            end)
        end

        -- NEW: ANTI AFK
        if Config.AntiAFK then
            SafeCall(function()
                -- Simulate micro-movement every 30 seconds
                if tick() % 30 < 0.2 then
                    local oldPos = root.Position
                    root.CFrame = root.CFrame + Vector3.new(0, 0.1, 0)
                    task.wait(0.05)
                    root.CFrame = CFrame.new(oldPos)
                end
            end)
        end

        -- NEW: AUTO PALLET DROP
        if Config.AutoPallet then
            SafeCall(function()
                local killer = getKiller()
                if killer and killer.Character then
                    local kRoot = killer.Character:FindFirstChild("HumanoidRootPart")
                    if kRoot and (kRoot.Position - root.Position).Magnitude <= Config.AutoPalletRange then
                        local pallets = findPartsByName({ "pallet" })
                        for _, pallet in pairs(pallets) do
                            if (pallet.Position - root.Position).Magnitude <= 8 then
                                for _, r in pairs(findRemotes({ "Pallet", "Drop", "Throw", "Break" })) do
                                    pcall(function() r:FireServer(pallet) end)
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
        -- CROSSHAIR
        CH.Visible = Config.ShowCrosshair

        -- TRACER
        if Config.Aimbot and Config.ShowTargetTracer then
            local target = findAimbotTarget()
            if target and target.Character then
                local tp = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                if tp then
                    local sp, on = Camera:WorldToScreenPoint(tp.Position)
                    if on then
                        TracerFrame.Visible = true
                        TracerOrigin.Visible = true
                        local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
                        local dx, dy = sp.X - cx, sp.Y - cy
                        local dist = math.sqrt(dx * dx + dy * dy)
                        TracerFrame.Size = UDim2.new(0, 2, 0, dist)
                        TracerFrame.Position = UDim2.new(0.5, -1, 0.5, 0)
                        TracerFrame.Rotation = math.deg(math.atan2(dx, dy))
                        TracerOrigin.Position = UDim2.new(0, sp.X - 4, 0, sp.Y - 4)
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

        -- AIM CIRCLE
        AimCircle.Visible = Config.Aimbot

        -- AIMBOT
        if Config.Aimbot then
            SafeCall(function()
                local target = findAimbotTarget()
                if target and target.Character then
                    local tp = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                    if tp then
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, tp.Position)
                    end

                    -- Lock-On Highlight
                    if Config.LockOnHighlight then
                        local tChar = target.Character
                        if not tChar:FindFirstChild("VD_LockOn") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "VD_LockOn"
                            hl.Adornee = tChar
                            hl.FillColor = Color3.fromRGB(255, 50, 0)
                            hl.OutlineColor = Color3.fromRGB(255, 200, 0)
                            hl.FillTransparency = 0.6
                            hl.OutlineTransparency = 0.1
                            hl.Parent = tChar
                        end
                    end
                else
                    -- Clear Lock-On
                    if Config.LockOnHighlight then
                        for _, player in pairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character then
                                local hl = player.Character:FindFirstChild("VD_LockOn")
                                if hl then hl:Destroy() end
                            end
                        end
                    end
                end
            end)
        else
            -- Clear Lock-On when aimbot off
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hl = player.Character:FindFirstChild("VD_LockOn")
                    if hl then hl:Destroy() end
                end
            end
        end

        -- EXPAND HITBOX
        if Config.ExpandHitbox then
            SafeCall(function()
                for _, player in pairs(Players:GetPlayers()) do
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

        -- AUTO ATTACK
        if Config.AutoAttack then
            SafeCall(function()
                local root = getRootPart()
                if not root then return end
                for _, player in pairs(Players:GetPlayers()) do
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

        -- FORCE FULLBRIGHT
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

        -- REMOVE BLUR/BLOOM
        if Config.RemoveBlurBloom then
            SafeCall(function()
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect") or effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
                        effect.Enabled = false
                    end
                end
            end)
        end

        -- POTATO MODE
        if Config.PotatoMode then
            SafeCall(function()
                Lighting.Brightness = 1
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 100000
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then effect.Enabled = false end
                end
                settings().QualityLevel = 1
            end)
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════
--  SILENT ACTIONS HOOK
-- ═══════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════
--  SPEAR NO GRAVITY HOOK
-- ═══════════════════════════════════════════════════════════════════════

SafeCall(function()
    Workspace.ChildAdded:Connect(function(child)
        SafeCall(function()
            if Config.SpearNoGravity then
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

-- ═══════════════════════════════════════════════════════════════════════
--  AUTO GENERATOR SKILL CHECK HOOK
-- ═══════════════════════════════════════════════════════════════════════

SafeCall(function()
    local originalNameCall
    originalNameCall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.AutoGenerator then
            local name = string.lower(self.Name)
            if name:find("skillcheck") or name:find("skill_check") or name:find("minigame") then
                if method == "FireServer" then
                    if Config.GenSkillCheckMode == "Perfect" then return self:FireServer("perfect", 1.0)
                    else return self:FireServer("neutral", 0.5) end
                elseif method == "InvokeServer" then
                    if Config.GenSkillCheckMode == "Perfect" then return self:InvokeServer("perfect", 1.0)
                    else return self:InvokeServer("neutral", 0.5) end
                end
            end
        end
        return originalNameCall(self, ...)
    end))
end)

-- ═══════════════════════════════════════════════════════════════════════
--  DOUBLE DAMAGE GENERATOR HOOK
-- ═══════════════════════════════════════════════════════════════════════

SafeCall(function()
    local originalNameCall2
    originalNameCall2 = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.DoubleDamageGen then
            local name = string.lower(self.Name)
            if name:find("kick") or name:find("damage") or name:find("gen") or name:find("destroy") or name:find("break") then
                if method == "FireServer" then
                    for i = 2, Config.GenDamageMultiplier do
                        SafeCall(function() self:FireServer(...) end)
                    end
                    return self:FireServer(...)
                end
            end
        end
        return originalNameCall2(self, ...)
    end))
end)

-- ═══════════════════════════════════════════════════════════════════════
--  ESP LOOP (RenderStepped update)
-- ═══════════════════════════════════════════════════════════════════════

spawn(function()
    while wait(0.5) do
        -- Player ESP
        if Config.PlayerESP then
            SafeCall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        if not PlayerESPTable[player] then
                            createPlayerESP(player)
                        else
                            local data = PlayerESPTable[player]
                            local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                            local myRoot = getRootPart()
                            if pRoot and myRoot and data.infoLabel then
                                local dist = math.floor((pRoot.Position - myRoot.Position).Magnitude)
                                local pHum = player.Character:FindFirstChildOfClass("Humanoid")
                                local hp = pHum and math.floor(pHum.Health / pHum.MaxHealth * 100) or 100
                                data.infoLabel.Text = "HP: " .. hp .. "% | " .. dist .. "m"
                                if data.healthFill then
                                    data.healthFill.Size = UDim2.new(hp / 100, 0, 1, 0)
                                end
                            end
                        end
                    end
                end
            end)
        else
            if next(PlayerESPTable) then clearAllPlayerESP() end
        end

        -- Object ESP
        if Config.GeneratorESP or Config.PalletESP or Config.ExitGateESP or Config.HookESP or Config.WindowESP then
            SafeCall(function()
                createObjectESP()
            end)
        else
            if next(ObjectESPTable) then clearObjectESP() end
        end

        -- Spectator Freecam
        if Config.SpectatorFreecam then
            SafeCall(function()
                local hum = getHumanoid()
                if hum and hum.Health <= 0 then
                    if not FreecamActive then StartFreecam() end
                end
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
    -- Stop freecam on respawn
    if FreecamActive then StopFreecam() end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
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
        if h then h.Health = h.MaxHealth; WindUI:Notify({ Title = "Instant Heal", Content = "HP pulih!" }) end
    end

    if input.KeyCode == Enum.KeyCode.R then
        local h = getHumanoid(); local c = getCharacter()
        if h then
            h:ChangeState(Enum.HumanoidStateType.Running)
            for _, t in pairs(h:GetPlayingAnimationTracks()) do t:Stop() end
        end
        if c then
            for _, o in pairs(c:GetDescendants()) do
                if o:IsA("BoolValue") and (o.Name:find("Stun") or o.Name:find("Stuck")) then o.Value = false end
            end
        end
        WindUI:Notify({ Title = "Reset", Content = "State di-reset!" })
    end

    if input.KeyCode == Enum.KeyCode.G then
        Config.GodMode = not Config.GodMode
        if Config.GodMode then
            SafeCall(function()
                local h = getHumanoid()
                if h then h.MaxHealth = math.huge; h.Health = math.huge end
            end)
        else
            SafeCall(function()
                local h = getHumanoid()
                if h then h.MaxHealth = 100; h.Health = 100 end
            end)
        end
        WindUI:Notify({ Title = "God Mode", Content = Config.GodMode and "ON" or "OFF" })
    end

    if input.KeyCode == Enum.KeyCode.T then
        local h = getHumanoid()
        if h then
            local cur = h.CameraMode
            h.CameraMode = (cur == Enum.CameraMode.LockFirstPerson) and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson
            WindUI:Notify({ Title = "Camera", Content = h.CameraMode == Enum.CameraMode.LockFirstPerson and "First Person" or "Third Person" })
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  CONSOLE LOG
-- ═══════════════════════════════════════════════════════════════════════

print("╔══════════════════════════════════════════════════════════════╗")
print("║   VIOLENCE DISTRICT HUB — v5.0 WINDUI EDITION               ║")
print("║                                                           ║")
print("║  Tabs: VIP | Survivor | Killer | Visuals | Combat | Utility║")
print("║                                                           ║")
print("║  Keybinds:                                                ║")
print("║    RightCtrl  -> Toggle GUI (default)                     ║")
print("║    H          -> Instant Heal                             ║")
print("║    R          -> Force Reset State                        ║")
print("║    G          -> Toggle God Mode                          ║")
print("║    T          -> Toggle FPP / TPP                         ║")
print("║                                                           ║")
print("║  New Features (v5.0):                                     ║")
print("║    - NoClip (Survivor)                                   ║")
print("║    - Individual ESP (Generator/Pallet/Gate/Hook/Window)   ║")
print("║    - Teleport to Survivor (Killer)                        ║")
print("║    - Anti AFK (Utility)                                   ║")
print("║    - Auto Pallet Drop (Utility)                           ║")
print("║    - Spectator Freecam (Utility)                          ║")
print("║    - Boost All Gen Continuous (Utility)                   ║")
print("║    - Instant Escape Toggle (Utility)                     ║")
print("╚══════════════════════════════════════════════════════════════╝")

-- Startup notification
task.delay(1, function()
    SafeCall(function()
        WindUI:Notify({
            Title = "Violence District v5.0",
            Content = "Script loaded successfully!\n7 Tabs | 40+ Features | All SafeCall protected.\nToggle: RightControl",
        })
    end)
end)
