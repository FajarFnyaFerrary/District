--[[
    Violence District Hub — WindUI Edition
    (Distrik Kekerasan - Premium Script Hub)

    Tabs : VIP | Survivor | Killer | Visuals | Combat | Automation
    Features: Killer Prediction (Lobby Only), Split World ESP
    UI   : WindUI (Solar / Lucide icons, Acrylic, Theme support)

    Keybinds
      RightCtrl  -> Toggle GUI
      H          -> Instant Heal
      R          -> Force Reset State
      G          -> Toggle God Mode
      T          -> Toggle FPP / TPP
--]]

local cloneref = (cloneref or clonereference or function(instance)
        return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))

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
        Author = "by Zetttify",
        Icon = "solar:compass-big-bold",
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
        ESPGenerator    = false,
        ESPPallet       = false,
        ESPGate         = false,
        ESPHook         = false,
        ESPWindow       = false,
        CustomFOV       = false,
        FOVValue        = 70,
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
}

-- ═══════════════════════════════════════════════════════════════════════
--  UTILITY HELPERS
-- ═══════════════════════════════════════════════════════════════════════

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
                        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not checked[obj] then
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

-- Find generator Model objects (bukan BasePart) — generator = Model "Generator" + anak "GeneratorPoint"
local function findAllGenerators()
        local generators = {}
        local map = Workspace:FindFirstChild("Map") or Workspace
        for _, obj in pairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Generator" then
                        local genPart = obj:FindFirstChildWhichIsA("BasePart")
                        if genPart then
                                table.insert(generators, {
                                        model = obj,
                                        part = genPart,
                                        position = genPart.Position,
                                })
                        end
                end
        end
        return generators
end

local function getGeneratorRemotes()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return nil, nil end
        local genFolder = remotes:FindFirstChild("Generator")
        if not genFolder then return nil, nil end
        local repairEvent = genFolder:FindFirstChild("RepairEvent")
        local skillCheckEvent = genFolder:FindFirstChild("SkillCheckResultEvent")
        -- Also try direct children if nested structure not found
        if not repairEvent then
                for _, child in pairs(genFolder:GetDescendants()) do
                        if child.Name:find("Repair") and (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) then
                                repairEvent = child; break
                        end
                end
        end
        if not skillCheckEvent then
                for _, child in pairs(genFolder:GetDescendants()) do
                        if child.Name:find("SkillCheck") and (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) then
                                skillCheckEvent = child; break
                        end
                end
        end
        return repairEvent, skillCheckEvent
end

local function isPlayerKiller(player)
        if not player then return false end

        -- Priority 1: Direct role/team attributes (most reliable)
        local roleAttrs = { "Role", "Team", "AssignedRole", "PlayerRole", "GameRole" }
        for _, attrName in ipairs(roleAttrs) do
                local val = player:GetAttribute(attrName)
                if val and tostring(val):lower():find("killer") then return true end
        end

        -- Priority 2: Team name
        if player.Team and player.Team.Name:lower():find("killer") then return true end

        -- Priority 3: Character-level role value (no Character required for this)
        local char = player.Character
        if char then
                local charRole = char:GetAttribute("Role") or char:GetAttribute("Team") or char:GetAttribute("IsKiller")
                if charRole then
                        local rv = tostring(charRole):lower()
                        if rv == "killer" or rv == "true" then return true end
                end

                -- Priority 4: Scan for killer-specific tools (NARROW match — only actual killer weapon names)
                local function scanKillerTools(parent)
                        for _, item in pairs(parent:GetChildren()) do
                                local n = item.Name:lower()
                                -- Match only clear killer weapon/tool names, NOT generic words like "weapon"
                                if item:IsA("Tool") then
                                        if n:find("killer") or n:find("vein_") or n:find("spear") or n:find("cleaver") or n:find("blade") or n:find("chainsaw") then
                                                return true
                                        end
                                end
                                -- Also check for BoolValue/StringValue markers that games often use
                                if (item:IsA("BoolValue") or item:IsA("StringValue")) and item.Name:lower():find("killer") then
                                        if item:IsA("BoolValue") and item.Value == true then return true end
                                        if item:IsA("StringValue") and tostring(item.Value):lower():find("killer") then return true end
                                end
                        end
                        return false
                end
                if scanKillerTools(char) then return true end
                if player.Backpack and scanKillerTools(player.Backpack) then return true end
        end

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

-- ═══════════════════════════════════════════════════════════════════════
--  KILLER PREDICTION (Lobby Only)
-- ═══════════════════════════════════════════════════════════════════════

local function isPlayerInLobby()
        local root = getRootPart()
        if not root then return false end
        local pos = root.Position
        if math.abs(pos.X) > 600 or math.abs(pos.Z) > 600 then return false end
        for _, obj in pairs(Workspace:GetDescendants()) do
                local n = obj.Name:lower()
                if (n:find("lobby") or n:find("waiting") or n:find("spawn"))
                        and obj:IsA("BasePart") then
                        if (obj.Position - pos).Magnitude < 80 then return true end
                end
        end
        for _, attr in ipairs({ "InLobby", "GameState", "Phase", "Status", "MatchState" }) do
                local val = LocalPlayer:GetAttribute(attr)
                if val then
                        local v = tostring(val):lower()
                        if v:find("lobby") or v:find("waiting") or v:find("idle") then return true end
                end
        end
        -- Fallback: kalau ga ada attribute, cek apakah ada Team "Killer" — kalau ada, artinya match sudah mulai
        for _, p in pairs(Players:GetPlayers()) do
                if p.Team and p.Team.Name == "Killer" then return false end
        end
        return true
end

-- Scan semua attribute seorang player, return map {attrName: value}
local function scanAllAttributes(player)
        local attrs = {}
        local ok, err = pcall(function()
                -- GetAttributes() returns {name: value} di Roblox
                local success, result = pcall(function() return player:GetAttributes() end)
                if success and type(result) == "table" then
                        for k, v in pairs(result) do
                                attrs[k] = v
                        end
                end
                -- Juga scan character attributes
                if player.Character then
                        local cok, cresult = pcall(function() return player.Character:GetAttributes() end)
                        if cok and type(cresult) == "table" then
                                for k, v in pairs(cresult) do
                                        attrs["Char." .. k] = v
                                end
                        end
                end
        end)
        return attrs
end

local function predictKiller()
        if not isPlayerInLobby() then
                WindUI:Notify({ Title = "Prediksi Killer", Content = "Fitur ini hanya bisa di LOBBY!" })
                return
        end

        local allPlayers = Players:GetPlayers()
        local candidates = {}

        -- ============================================================
        -- SCALING: Kumpulkan semua attribute unik dari semua player
        -- untuk membandingkan siapa yang "beda" (kemungkinan killer)
        -- ============================================================
        local allAttrNames = {}
        for _, player in pairs(allPlayers) do
                if player == LocalPlayer then continue end
                local attrs = scanAllAttributes(player)
                for k, _ in pairs(attrs) do
                        allAttrNames[k] = true
                end
        end

        -- ============================================================
        -- SCALING DEEP: Cari data role di ReplicatedStorage
        -- Banyak game simpan siapa killer di folder GameData/MatchData/dll
        -- ============================================================
        local foundKillerFromStorage = nil
        pcall(function()
                for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                        local n = obj.Name:lower()
                        -- Cari folder yang berisi info role/killer assignment
                        if n:find("gamedata") or n:find("matchdata") or n:find("roundinfo")
                                or n:find("gameinfo") or n:find("roleassign") or n:find("session")
                                or n:find("matchmaking") or n:find("queue") then
                                -- Scan isi folder ini
                                for _, child in pairs(obj:GetDescendants()) do
                                        local cn = child.Name:lower()
                                        local cv = tostring(child.Value):lower()
                                        if cn:find("killer") or cv:find("killer") then
                                                -- Coba cari nama player di value
                                                for _, player in pairs(allPlayers) do
                                                        local pn = player.Name:lower()
                                                        local pd = player.DisplayName:lower()
                                                        if cv:find(pn, 1, true) or cv:find(pd, 1, true)
                                                                or cn:find(pn, 1, true) or cn:find(pd, 1, true) then
                                                                foundKillerFromStorage = player
                                                        end
                                                end
                                        end
                                end
                                -- Juga cek attribute di folder ini sendiri
                                local fOk, folderAttrs = pcall(function() return obj:GetAttributes() end)
                                if fOk and type(folderAttrs) == "table" then
                                        for k, v in pairs(folderAttrs) do
                                                local vk = tostring(k):lower()
                                                local vv = tostring(v):lower()
                                                if vk:find("killer") or vv:find("killer") then
                                                        for _, player in pairs(allPlayers) do
                                                                if player == LocalPlayer then continue end
                                                                local pn = player.Name:lower()
                                                                local pd = player.DisplayName:lower()
                                                                if vv:find(pn, 1, true) or vv:find(pd, 1, true) then
                                                                        foundKillerFromStorage = player
                                                                end
                                                        end
                                                end
                                        end
                                end
                        end
                end
        end)

        -- ============================================================
        -- SCALING: Cek RemoteEvent yang mungkin expose killer identity
        -- ============================================================
        pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                        for _, child in pairs(remotes:GetChildren()) do
                                local cn = child.Name:lower()
                                if cn:find("role") or cn:find("assign") or cn:find("killer")
                                        or cn:find("team") or cn:find("select") or cn:find("pick") then
                                        -- Jika ini adalah ObjectValue/StringValue yang berisi player reference
                                        if child:IsA("ObjectValue") and child.Value and child.Value:IsA("Player") then
                                                foundKillerFromStorage = child.Value
                                        end
                                end
                        end
                end
        end)

        -- ============================================================
        -- Jika langsung ketemu dari storage, langsung tampilkan
        -- ============================================================
        if foundKillerFromStorage and foundKillerFromStorage ~= LocalPlayer then
                WindUI:Notify({
                        Title = "Prediksi Killer",
                        Content = foundKillerFromStorage.DisplayName .. " akan menjadi Killer!",
                        Duration = 8,
                })
                print("[VD] KILLER FOUND (from storage): " .. foundKillerFromStorage.DisplayName)
                return
        end

        -- ============================================================
        -- FALLBACK: Scoring system berdasarkan attribute analysis
        -- ============================================================
        for _, player in pairs(allPlayers) do
                if player == LocalPlayer then continue end
                local score = 0
                local reasons = {}
                local attrs = scanAllAttributes(player)

                -- Cek semua attribute yang mengandung "killer", "role", "team", "assigned"
                for attrName, attrVal in pairs(attrs) do
                        local an = attrName:lower()
                        local av = tostring(attrVal):lower()
                        if av:find("killer") then
                                score = score + 1000
                                table.insert(reasons, an .. " = " .. tostring(attrVal))
                        elseif av:find("survivor") or av:find("surv") then
                                score = score - 500
                        end
                        -- Attribute yang cuma dimiliki satu player (unikk) berpotensi killer marker
                        if an:find("role") or an:find("team") or an:find("assigned")
                                or an:find("next") or an:find("queue") or an:find("selected") then
                                if av ~= "" and av ~= "nil" and av ~= "none" and av ~= "survivor" then
                                        score = score + 400
                                        table.insert(reasons, an .. " = " .. tostring(attrVal))
                                end
                        end
                end

                -- Cek Team (kalau sudah ke-assign)
                pcall(function()
                        if player.Team then
                                local tn = player.Team.Name:lower()
                                if tn:find("killer") then
                                        score = score + 2000
                                        table.insert(reasons, "Team = " .. player.Team.Name)
                                elseif tn:find("survivor") or tn:find("surv") then
                                        score = score - 300
                                end
                        end
                end)

                -- Cek leaderstats
                pcall(function()
                        local leaderstats = player:FindFirstChild("leaderstats") or player:FindFirstChild("Stats")
                        if leaderstats then
                                for _, stat in pairs(leaderstats:GetChildren()) do
                                        local sn = stat.Name:lower()
                                        local sv = tostring(stat.Value):lower()
                                        if sn:find("killer") or sn:find("role") or sn:find("team") then
                                                if sv:find("killer") then
                                                        score = score + 800
                                                        table.insert(reasons, "Stat " .. stat.Name .. " = " .. tostring(stat.Value))
                                                elseif sv ~= "survivor" and sv ~= "none" and sv ~= "" then
                                                        score = score + 200
                                                        table.insert(reasons, "Stat " .. stat.Name .. " = " .. tostring(stat.Value))
                                                end
                                        end
                                        -- Player dengan kill count tinggi mungkin akan jadi killer
                                        if sn:find("kill") and typeof(stat.Value) == "number" then
                                                score = score + stat.Value * 2
                                        end
                                        if sn:find("play") or sn:find("game") or sn:find("match") or sn:find("round") then
                                                score = score + math.random(5, 25)
                                        end
                                end
                        end
                end)

                -- Cek Tags
                pcall(function()
                        for _, tag in pairs(player:GetTags()) do
                                local t = tostring(tag):lower()
                                if t:find("killer") then
                                        score = score + 600
                                        table.insert(reasons, "Tag: " .. tostring(tag))
                                end
                        end
                end)

                -- Cek jumlah Tools di Backpack (killer biasanya punya weapon khusus)
                pcall(function()
                        local backpack = player.Backpack
                        if backpack then
                                local toolCount = #backpack:GetChildren()
                                if toolCount > 3 then
                                        score = score + toolCount * 10
                                end
                        end
                end)

                -- Tiebreaker kecil agar ga semua score sama persis
                score = score + math.random(1, 10)

                table.insert(candidates, {
                        player = player,
                        score = score,
                        reasons = reasons,
                })
        end

        if #candidates == 0 then
                WindUI:Notify({ Title = "Prediksi Killer", Content = "Tidak ada pemain lain di lobby" })
                return
        end

        table.sort(candidates, function(a, b) return a.score > b.score end)

        local top = candidates[1]
        local reasonStr = #top.reasons > 0 and table.concat(top.reasons, ", ") or "Analisis probabilistik"

        -- Tampilkan notifikasi dengan nama jelas
        WindUI:Notify({
                Title = "Prediksi Killer",
                Content = top.player.DisplayName .. " kemungkinan besar jadi Killer! (Skor: " .. top.score .. ")",
                Duration = 8,
        })

        -- Juga tampilkan top 3 di console untuk detail
        print("[VD] === KILLER PREDICTION ===")
        for i = 1, math.min(3, #candidates) do
                local c = candidates[i]
                local rStr = #c.reasons > 0 and " [" .. table.concat(c.reasons, ", ") .. "]" or ""
                print(string.format("[VD] #%d %s — Score: %d%s", i, c.player.DisplayName, c.score, rStr))
        end
        print("[VD] ==========================")
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
        Title = "Killer Prediction",
        Desc = "Prediksi siapa Killer selanjutnya (Hanya di Lobby)",
})

TabVIP:Button({
        Title = "Prediksi Killer",
        Justify = "Center",
        Icon = "solar:eye-scan-bold",
        IconAlign = "Left",
        Size = "Normal",
        Callback = function()
                predictKiller()
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

-- ═══════════════════════════════════════════════════════════════════════
--  TAB 2 — SURVIVOR
-- ═══════════════════════════════════════════════════════════════════════

local TabSurv = Window:Tab({
        Title = "Survivor",
        Icon = "solar:shield-bold",
})

TabSurv:Section({
        Title = "Movement",
        Desc = "Kecepatan, anti-slowdown, dan anti-stuck",
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

TabSurv:Toggle({
        Title = "No Slowdown",
        Value = false,
        Callback = function(v)
                Config.NoSlowdown = v
                if v then WindUI:Notify({ Title = "No Slowdown", Content = "Kebal semua efek perlambatan!" }) end
        end,
})

TabSurv:Space({ Columns = 1 })

TabSurv:Toggle({
        Title = "No Clip",
        Value = false,
        Callback = function(v)
                Config.NoClip = v
                if v then WindUI:Notify({ Title = "No Clip", Content = "Tembus dinding aktif!" }) end
        end,
})

TabSurv:Space({ Columns = 1 })

TabSurv:Section({
        Title = "Anti-Stuck & Silent",
        Desc = "Reset state karakter dan bergerak tanpa suara",
})

TabSurv:Space({ Columns = 2 })

local SurvGroup1 = TabSurv:Group()

SurvGroup1:Toggle({
        Title = "Silent Actions",
        Value = false,
        Callback = function(v)
                Config.SilentActions = v
                if v then WindUI:Notify({ Title = "Silent Actions", Content = "Bergerak tanpa suara ke Killer" }) end
        end,
})

SurvGroup1:Space({ Columns = 0.5 })

SurvGroup1:Button({
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
                if v then WindUI:Notify({ Title = "God Mode", Content = "HP selalu penuh!" }) end
        end,
})

TabSurv:Space({ Columns = 2 })

local SurvGroup2 = TabSurv:Group()

SurvGroup2:Toggle({
        Title = "Anti Knock",
        Value = false,
        Callback = function(v)
                Config.AntiKnock = v
                if v then WindUI:Notify({ Title = "Anti Knock", Content = "Tidak bisa di-knock down!" }) end
        end,
})

SurvGroup2:Space({ Columns = 0.5 })

SurvGroup2:Button({
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
                Max = 50,
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
                Max = 10,
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

TabKill:Space({ Columns = 1 })

TabKill:Section({
        Title = "Teleport",
        Desc = "Teleport ke survivor secara random atau select player",
})

TabKill:Toggle({
        Title = "Teleport to Random Survivor",
        Value = false,
        Callback = function(v)
                Config.KillerTeleport = v
                if v then
                        local survivors = {}
                        for _, p in pairs(Players:GetPlayers()) do
                                if p ~= LocalPlayer and not isPlayerKiller(p) and p.Character then
                                        local tr = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
                                        if tr then table.insert(survivors, tr) end
                                end
                        end
                        if #survivors > 0 then
                                local target = survivors[math.random(1, #survivors)]
                                teleportTo(target.Position)
                                WindUI:Notify({ Title = "Teleport", Content = "Teleport ke survivor!" })
                        else
                                WindUI:Notify({ Title = "Teleport", Content = "Tidak ada survivor ditemukan" })
                        end
                        Config.KillerTeleport = false
                end
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
        Title = "Player ESP",
        Desc = "Menampilkan lokasi Survivor & Killer dengan warna berbeda",
})

TabVis:Toggle({
        Title = "Player ESP",
        Value = false,
        Callback = function(v)
                Config.PlayerESP = v
                if v then WindUI:Notify({ Title = "Player ESP", Content = "Menampilkan semua pemain!" }) end
        end,
})

TabVis:Space({ Columns = 1 })

TabVis:Section({
        Title = "ESP World",
        Desc = "Toggle tiap objek map secara terpisah",
})

TabVis:Space({ Columns = 2 })

local VisWorldGroup1 = TabVis:Group()

VisWorldGroup1:Toggle({
        Title = "ESP Generator",
        Value = false,
        Callback = function(v)
                Config.ESPGenerator = v
                if v then WindUI:Notify({ Title = "ESP Generator", Content = "Generator terlihat dengan persentase!" }) end
        end,
})

VisWorldGroup1:Space({ Columns = 0.5 })

VisWorldGroup1:Toggle({
        Title = "ESP Pallet",
        Value = false,
        Callback = function(v)
                Config.ESPPallet = v
                if v then WindUI:Notify({ Title = "ESP Pallet", Content = "Pallet terlihat!" }) end
        end,
})

TabVis:Space({ Columns = 2 })

local VisWorldGroup2 = TabVis:Group()

VisWorldGroup2:Toggle({
        Title = "ESP Exit Gate",
        Value = false,
        Callback = function(v)
                Config.ESPGate = v
                if v then WindUI:Notify({ Title = "ESP Exit Gate", Content = "Gerbang keluar terlihat!" }) end
        end,
})

VisWorldGroup2:Space({ Columns = 0.5 })

VisWorldGroup2:Toggle({
        Title = "ESP Hook",
        Value = false,
        Callback = function(v)
                Config.ESPHook = v
                if v then WindUI:Notify({ Title = "ESP Hook", Content = "Hook terlihat!" }) end
        end,
})

TabVis:Space({ Columns = 1 })

TabVis:Toggle({
        Title = "ESP Window",
        Value = false,
        Callback = function(v)
                Config.ESPWindow = v
                if v then WindUI:Notify({ Title = "ESP Window", Content = "Window terlihat!" }) end
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

local VisGroup2 = TabVis:Group()

VisGroup2:Toggle({
        Title = "Remove Blur/Bloom",
        Value = false,
        Callback = function(v)
                Config.RemoveBlurBloom = v
                if v then WindUI:Notify({ Title = "Effects Off", Content = "Blur & Bloom dimatikan!" }) end
        end,
})

VisGroup2:Space({ Columns = 0.5 })

VisGroup2:Toggle({
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
--  TAB 6 — AUTOMATION
-- ═══════════════════════════════════════════════════════════════════════

local TabAuto = Window:Tab({
        Title = "Automation",
        Icon = "solar:settings-bold",
})

TabAuto:Section({
        Title = "Generator",
        Desc = "Auto SkillCheck dan Boost Generator",
})

TabAuto:Toggle({
        Title = "Auto Generator",
        Value = false,
        Callback = function(v)
                Config.AutoGenerator = v
                if v then WindUI:Notify({ Title = "Auto Generator", Content = "SkillCheck otomatis: " .. Config.GenSkillCheckMode }) end
        end,
})

TabAuto:Space({ Columns = 2 })

local AutoGroup1 = TabAuto:Group()

AutoGroup1:Button({
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

AutoGroup1:Space({ Columns = 0.5 })

AutoGroup1:Button({
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

TabAuto:Space({ Columns = 1 })

TabAuto:Section({
        Title = "Escape & UnHook",
        Desc = "Instant Escape dan Self UnHook 100%",
})

TabAuto:Space({ Columns = 2 })

local AutoGroup2 = TabAuto:Group()

AutoGroup2:Button({
        Title = "Instant Escape",
        Justify = "Center",
        Icon = "solar:logout-3-bold",
        IconAlign = "Left",
        Size = "Small",
        Callback = function()
                local gates = findPartsByName({ "gate", "exit", "door" })
                local remotes = findRemotes({ "Gate", "Exit", "Open", "Escape", "Lever" })
                if #gates > 0 then
                        for _, gate in pairs(gates) do
                                teleportTo(gate.Position)
                                for _, remote in pairs(remotes) do
                                        pcall(function() remote:FireServer(gate) end)
                                end
                        end
                        WindUI:Notify({ Title = "Instant Escape", Content = "Berusaha membuka gerbang..." })
                else
                        WindUI:Notify({ Title = "Instant Escape", Content = "Gerbang tidak ditemukan" })
                end
        end,
})

AutoGroup2:Space({ Columns = 0.5 })

AutoGroup2:Button({
        Title = "Complete All Gen (Instant)",
        Justify = "Center",
        Icon = "solar:bolt-circle-bold",
        IconAlign = "Left",
        Size = "Small",
        Callback = function()
                local repairEvent, skillCheckEvent = getGeneratorRemotes()
                if not repairEvent or not skillCheckEvent then
                        WindUI:Notify({ Title = "Complete Gen", Content = "Generator Remotes tidak ditemukan!" })
                        return
                end
                local completed = 0
                local generators = findAllGenerators()
                for _, genData in pairs(generators) do
                        for _, point in pairs(genData.model:GetChildren()) do
                                if point.Name:find("GeneratorPoint") then
                                        pcall(function()
                                                for i = 1, 10 do
                                                        repairEvent:FireServer(point, true)
                                                        skillCheckEvent:FireServer("success", 1, genData.model, point)
                                                end
                                                completed = completed + 1
                                        end)
                                end
                        end
                end
                if completed > 0 then
                        WindUI:Notify({ Title = "Complete Gen", Content = completed .. " generator point selesai!" })
                else
                        WindUI:Notify({ Title = "Complete Gen", Content = "Generator tidak ditemukan di map" })
                end
        end,
})

TabAuto:Space({ Columns = 1 })

TabAuto:Toggle({
        Title = "Self UnHook (100%)",
        Value = false,
        Callback = function(v)
                Config.SelfUnHook = v
                if v then WindUI:Notify({ Title = "Self UnHook", Content = "100% lepas dari Hook!" }) end
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

local ESP_COLORS = {
        KillerESP   = Color3.fromRGB(255, 50, 50),
        SurvivorESP = Color3.fromRGB(50, 255, 120),
        GenESP      = Color3.fromRGB(255, 220, 50),
        PalletESP   = Color3.fromRGB(160, 100, 40),
        GateESP     = Color3.fromRGB(0, 220, 255),
        HookESP     = Color3.fromRGB(200, 50, 220),
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

local function createWorldESP(espType)
        local function matchType(n)
                if espType == "Generator" then
                        return n:find("generator") or (n:find("gen") and not n:find("region"))
                elseif espType == "Pallet" then
                        return n:find("pallet")
                elseif espType == "Gate" then
                        return n:find("gate") or n:find("exit")
                elseif espType == "Hook" then
                        return n:find("hook")
                elseif espType == "Window" then
                        return n:find("window")
                end
                return false
        end

        local colorMap = {
                Generator = ESP_COLORS.GenESP,
                Pallet    = ESP_COLORS.PalletESP,
                Gate      = ESP_COLORS.GateESP,
                Hook      = ESP_COLORS.HookESP,
                Window    = Color3.fromRGB(100, 180, 255),
        }
        local color = colorMap[espType] or Color3.new(1, 1, 1)

        for _, obj in pairs(Workspace:GetDescendants()) do
                if not (obj:IsA("BasePart") and obj.Parent) then continue end
                if obj:FindFirstChild("VD_ObjESP_" .. espType) then continue end
                local n = obj.Name:lower()
                if not matchType(n) then continue end

                local hl = Instance.new("Highlight")
                hl.Name = "VD_ObjESP_" .. espType; hl.Adornee = obj
                hl.FillTransparency = 0.85; hl.OutlineTransparency = 0
                hl.FillColor = color; hl.OutlineColor = color
                hl.Parent = obj

                local bb = Instance.new("BillboardGui")
                bb.Name = "VD_ObjESP_" .. espType .. "_Label"
                bb.Size = UDim2.new(0, 160, 0, 35)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = true; bb.Parent = obj

                local lbl = Instance.new("TextLabel")
                lbl.Name = "ObjLabel_" .. espType
                lbl.Size = UDim2.new(1, 0, 0.6, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = color
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                lbl.TextStrokeTransparency = 0.4
                lbl.TextSize = 12; lbl.Font = Enum.Font.GothamBold
                local progress = obj:GetAttribute("Progress") or 0
                lbl.Text = espType .. (espType == "Generator" and (" [" .. math.floor(progress) .. "%]") or "")
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.Parent = bb
        end
end

local function clearWorldESP(espType)
        local tag = "VD_ObjESP_" .. espType
        for _, obj in pairs(Workspace:GetDescendants()) do
                local hl = obj:FindFirstChild(tag)
                if hl then pcall(function() hl:Destroy() end) end
                local lbl = obj:FindFirstChild(tag .. "_Label")
                if lbl then pcall(function() lbl:Destroy() end) end
        end
end

local function updateWorldESPProgress(espType)
        local tag = "VD_ObjESP_" .. espType
        for _, obj in pairs(Workspace:GetDescendants()) do
                if not (obj:IsA("BasePart") and obj.Parent) then continue end
                local lbl = obj:FindFirstChild(tag .. "_Label")
                if lbl then
                        local textLbl = lbl:FindFirstChild("ObjLabel_" .. espType)
                        local progress = obj:GetAttribute("Progress")
                        if textLbl and progress then
                                textLbl.Text = espType .. " [" .. math.floor(progress) .. "%]"
                        end
                end
        end
end

local lastWorldESPRefresh = { Generator = 0, Pallet = 0, Gate = 0, Hook = 0, Window = 0 }

-- ═══════════════════════════════════════════════════════════════════════
--  MAIN HEARTBEAT LOOP
-- ═══════════════════════════════════════════════════════════════════════

RunService.Heartbeat:Connect(function()
        local humanoid = getHumanoid()
        local root = getRootPart()
        if not humanoid or not root then return end

        if Config.SpeedBoost and humanoid.WalkSpeed ~= Config.CustomSpeed then
                humanoid.WalkSpeed = Config.CustomSpeed
        end

        if Config.NoSlowdown then
                local targetSpeed = Config.SpeedBoost and Config.CustomSpeed or 16
                if humanoid.WalkSpeed < targetSpeed then humanoid.WalkSpeed = targetSpeed end
                local char = getCharacter()
                if char then
                        for _, obj in pairs(char:GetDescendants()) do
                                if obj:IsA("NumberValue") and (obj.Name:lower():find("slow") or obj.Name:lower():find("speed")) then
                                        if obj.Value < 0 then obj.Value = 0 end
                                end
                        end
                end
        end

        if Config.NoClip then
                for _, part in pairs(getCharacter():GetDescendants()) do
                        if part:IsA("BasePart") then
                                part.CanCollide = false
                        end
                end
        end

        if Config.AntiFallDamage and humanoid:GetState() == Enum.HumanoidStateType.Landed then
                humanoid.Health = math.min(humanoid.Health + 100, humanoid.MaxHealth)
        end

        if Config.GodMode then humanoid.Health = humanoid.MaxHealth end

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

        if Config.AutoHealAura then
                for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                                local tr = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
                                local th = player.Character:FindFirstChildOfClass("Humanoid")
                                if tr and th and (root.Position - tr.Position).Magnitude <= Config.HealAuraRange and th.Health < th.MaxHealth then
                                        for _, r in pairs(findRemotes({ "Heal", "Revive", "Help" })) do
                                                pcall(function() r:FireServer(player) end)
                                        end
                                end
                        end
                end
        end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  RENDER LOOP
-- ═══════════════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
        local now = tick()

        CH.Visible = Config.ShowCrosshair

        if Config.CustomFOV then Camera.FieldOfView = Config.FOVValue end

        if Config.ForceFullbright then
                Lighting.Brightness = 2; Lighting.ClockTime = 14.5
                Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(178, 178, 178)
                Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
                Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 0
        end

        if Config.RemoveBlurBloom then
                for _, e in pairs(Lighting:GetChildren()) do
                        if e:IsA("BloomEffect") or e:IsA("BlurEffect")
                                or e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect")
                                or e:IsA("ColorCorrectionEffect") then e.Enabled = false end
                end
        end

        if Config.PotatoMode then
                Lighting.Brightness = 0; Lighting.GlobalShadows = false; Lighting.FogEnd = 100000
                for _, e in pairs(Lighting:GetChildren()) do
                        if e:IsA("PostEffect") then e.Enabled = false end
                end
                for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                                obj.Enabled = false
                        end
                end
        end

        -- Player ESP
        if Config.PlayerESP then
                for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                                if player.Character and not PlayerESPTable[player] then createPlayerESP(player) end
                                local data = PlayerESPTable[player]
                                if data and player.Character then
                                        -- Re-check killer role every frame & update visuals if changed
                                        local nowKiller = isPlayerKiller(player)
                                        if nowKiller ~= data.isKiller then
                                                data.isKiller = nowKiller
                                                local newColor = nowKiller and ESP_COLORS.KillerESP or ESP_COLORS.SurvivorESP
                                                pcall(function()
                                                        data.highlight.FillColor = newColor
                                                        data.highlight.OutlineColor = nowKiller and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(100, 255, 150)
                                                        data.nameLabel.TextColor3 = newColor
                                                        data.nameLabel.Text = (nowKiller and "[KILLER] " or "[SURVIVOR] ") .. player.DisplayName
                                                end)
                                        end
                                        local tr = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
                                        local myRoot = getRootPart()
                                        local th = player.Character:FindFirstChildOfClass("Humanoid")
                                        if tr and myRoot then
                                                local dist = math.floor((tr.Position - myRoot.Position).Magnitude)
                                                local status = "ALIVE"
                                                if th then
                                                        if th.Health <= 0 then status = "DEAD"
                                                        elseif th.Health < th.MaxHealth * 0.3 then status = "INJURED" end
                                                        local pct = th.Health / th.MaxHealth
                                                        data.healthFill.Size = UDim2.new(pct, 0, 1, 0)
                                                        data.healthFill.BackgroundColor3 = pct > 0.6
                                                                and Color3.fromRGB(50, 220, 50)
                                                                or (pct > 0.3 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 50, 50))
                                                end
                                                data.infoLabel.Text = status .. " | " .. dist .. "m"
                                        end
                                end
                        end
                end
        elseif next(PlayerESPTable) then clearAllPlayerESP() end

        -- World ESP (Per-Object Type)
        local espTypes = {
                { key = "Generator", config = Config.ESPGenerator },
                { key = "Pallet",    config = Config.ESPPallet },
                { key = "Gate",      config = Config.ESPGate },
                { key = "Hook",      config = Config.ESPHook },
                { key = "Window",    config = Config.ESPWindow },
        }
        for _, espData in ipairs(espTypes) do
                if espData.config then
                        if now - lastWorldESPRefresh[espData.key] > 5 then
                                createWorldESP(espData.key)
                                lastWorldESPRefresh[espData.key] = now
                        end
                        if espData.key == "Generator" then
                                updateWorldESPProgress("Generator")
                        end
                else
                        if lastWorldESPRefresh[espData.key] > 0 then
                                clearWorldESP(espData.key)
                                lastWorldESPRefresh[espData.key] = 0
                        end
                end
        end

        -- Aimbot
        if Config.Aimbot then
                local target = findAimbotTarget()
                if target and target.Character then
                        local tp = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                        if tp then Camera.CFrame = CFrame.new(Camera.CFrame.Position, tp.Position) end
                end
                local r = Config.AimRadius
                AimCircle.Visible = true
                AimCircle.Size = UDim2.new(0, r * 2, 0, r * 2)
                AimCircle.Position = UDim2.new(0.5, -r, 0.5, -r)
        else AimCircle.Visible = false end

        -- Target Tracer
        if Config.ShowTargetTracer then
                local target = findAimbotTarget()
                if target and target.Character then
                        local tp = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                        if tp then
                                local sp, on = Camera:WorldToScreenPoint(tp.Position)
                                if on then
                                        local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y
                                        local dx, dy = sp.X - cx, sp.Y - cy
                                        local len = math.sqrt(dx * dx + dy * dy)
                                        TracerFrame.Visible = true
                                        TracerFrame.Size = UDim2.new(0, len, 0, 2)
                                        TracerFrame.Position = UDim2.new(0, cx, 0, cy - 10)
                                        TracerFrame.Rotation = math.deg(math.atan2(dy, dx))
                                        TracerOrigin.Position = UDim2.new(0.5, -4, 1, -20)
                                        TracerOrigin.Visible = true
                                end
                        end
                else
                        TracerFrame.Visible = false; TracerOrigin.Visible = false
                end
        else
                TracerFrame.Visible = false; TracerOrigin.Visible = false
        end

        -- Lock-On Highlight
        for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                        local existing = player.Character:FindFirstChild("VD_LockOn")
                        if Config.LockOnHighlight then
                                local target = findAimbotTarget()
                                if target and player == target and not existing then
                                        local hl = Instance.new("Highlight")
                                        hl.Name = "VD_LockOn"
                                        hl.FillColor = Color3.fromRGB(255, 50, 50)
                                        hl.OutlineColor = Color3.fromRGB(255, 215, 0)
                                        hl.FillTransparency = 0.4; hl.OutlineTransparency = 0
                                        hl.Parent = player.Character
                                end
                        else
                                if existing then existing:Destroy() end
                        end
                end
        end

        -- Expand Hitbox
        if Config.ExpandHitbox then
                for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                                for _, part in pairs(player.Character:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                                local n = part.Name:lower()
                                                if n == "head" or n == "humanoidrootpart" or n == "torso" or n:find("hitbox") then
                                                        local mx = 20
                                                        if part.Size.X < mx then
                                                                part.Size = Vector3.new(
                                                                        math.min(part.Size.X * 1.005, mx),
                                                                        math.min(part.Size.Y * 1.005, mx),
                                                                        math.min(part.Size.Z * 1.005, mx)
                                                                )
                                                        end
                                                end
                                        end
                                end
                        end
                end
        end

        -- Auto Attack
        if Config.AutoAttack then
                local root = getRootPart()
                if root then
                        for _, player in pairs(Players:GetPlayers()) do
                                if player ~= LocalPlayer and player.Character then
                                        local tr = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
                                        if tr and (root.Position - tr.Position).Magnitude <= Config.AutoAttackRange then
                                                for _, r in pairs(findRemotes({ "Attack", "Hit", "Strike", "Punch", "Slash", "Knife" })) do
                                                        pcall(function() r:FireServer(player) end)
                                                end
                                        end
                                end
                        end
                end
        end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  BACKGROUND TASK LOOPS
-- ═══════════════════════════════════════════════════════════════════════

-- AUTO PLAY (Smart AI)
spawn(function()
        while wait(0.4) do
                if not Config.AutoPlay then continue end
                local root, humanoid = getRootPart(), getHumanoid()
                if not root or not humanoid or humanoid.Health <= 0 then continue end

                local killer = getKiller()
                local kr = killer and killer.Character
                        and (killer.Character:FindFirstChild("HumanoidRootPart") or killer.Character:FindFirstChild("Torso"))

                if kr and (root.Position - kr.Position).Magnitude < Config.AutoPlayFleeDist then
                        local flee = (root.Position - kr.Position).Unit
                        local offset = Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
                        local target = root.Position + flee * 60 + offset
                        target = Vector3.new(math.clamp(target.X, -500, 500), target.Y, math.clamp(target.Z, -500, 500))
                        humanoid:MoveTo(target)
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
        end
end)

-- AUTO DAGGER
spawn(function()
        local lastParry = 0
        while wait(0.08) do
                if not Config.AutoDagger then continue end
                local root = getRootPart()
                if not root then continue end
                local killer = getKiller()
                local kr = killer and killer.Character
                        and (killer.Character:FindFirstChild("HumanoidRootPart") or killer.Character:FindFirstChild("Torso"))
                if kr and (root.Position - kr.Position).Magnitude <= Config.AutoDaggerRange then
                        local now = tick()
                        if now - lastParry > 0.5 then
                                for _, r in pairs(findRemotes({ "Parry", "Dagger", "Block", "Counter", "Deflect" })) do
                                        pcall(function() r:FireServer() end)
                                end
                                lastParry = now
                        end
                end
        end
end)

-- WIGGLE MASTER
spawn(function()
        while wait(0.04) do
                if not Config.WiggleMaster then continue end
                local humanoid = getHumanoid()
                if not humanoid then continue end
                local state = humanoid:GetState()
                if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
                        for _, r in pairs(findRemotes({ "Wiggle", "Struggle", "Escape", "Break", "Resist" })) do
                                pcall(function() r:FireServer(math.random(0, 3)) end)
                        end
                end
        end
end)

-- NO CLIP
spawn(function()
        while wait(0.1) do
                if not Config.NoClip then continue end
                local char = getCharacter()
                if not char then continue end
                for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                                part.CanCollide = false
                        end
                end
        end
end)

-- SILENT ACTIONS
spawn(function()
        while wait(0.2) do
                if not Config.SilentActions then continue end
                for _, r in pairs(findRemotes({ "Noise", "Sound", "Footstep", "Alert", "Foot", "Step", "Hear" })) do
                        if not r:GetAttribute("VD_Silenced") then
                                r:SetAttribute("VD_Silenced", true)
                                if hookfunction then
                                        pcall(function() hookfunction(r.FireServer, function() return nil end) end)
                                end
                        end
                end
        end
end)

-- ANTI-BLIND
spawn(function()
        while wait(0.3) do
                if not Config.AntiBlind then continue end
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
        end
end)

-- ANTI-STUN
spawn(function()
        while wait(0.08) do
                if not Config.AntiStun then continue end
                local h = getHumanoid()
                if not h then continue end
                local s = h:GetState()
                if s == Enum.HumanoidStateType.Stunned or s == Enum.HumanoidStateType.StunnedNoFall then
                        h:ChangeState(Enum.HumanoidStateType.Running)
                end
        end
end)

-- SPEAR NO GRAVITY & DROP PREDICTION
spawn(function()
        while wait(0.03) do
                if not Config.SpearNoGravity and not Config.SpearDropPrediction then continue end
                for _, obj in pairs(Workspace:GetDescendants()) do
                        if not obj:IsA("BasePart") then continue end
                        local n = obj.Name:lower()
                        if not (n:find("spear") or n:find("projectile") or n:find("knife") or n:find("throw") or n:find("vein")) then continue end
                        local vel = obj.Velocity
                        if vel.Magnitude < 30 then continue end
                        if Config.SpearNoGravity then
                                obj.Velocity = Vector3.new(vel.X, 0, vel.Z)
                                for _, child in pairs(obj:GetChildren()) do
                                        if child:IsA("BodyForce") then child.Force = Vector3.new(child.Force.X, 0, child.Force.Z) end
                                end
                        end
                        if Config.SpearDropPrediction then
                                local target = findAimbotTarget()
                                if target and target.Character then
                                        local tp = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                                        local myRoot = getRootPart()
                                        if tp and myRoot then
                                                local dist = (myRoot.Position - tp.Position).Magnitude
                                                obj.Velocity = Vector3.new(vel.X, vel.Y + dist * 0.02, vel.Z)
                                        end
                                end
                        end
                end
        end
end)

-- DOUBLE DAMAGE GENERATOR
spawn(function()
        while wait(0.5) do
                if not Config.DoubleDamageGen then continue end
                local root = getRootPart()
                if not root then continue end
                for _, gen in pairs(findPartsByName({ "generator", "gen" })) do
                        if (gen.Position - root.Position).Magnitude < 10 then
                                for i = 1, Config.GenDamageMultiplier do
                                        for _, r in pairs(findRemotes({ "Generator", "Kick", "Damage", "Sabotage", "Break" })) do
                                                pcall(function() r:FireServer(gen) end)
                                        end
                                end
                        end
                end
        end
end)

-- AUTO GENERATOR (pakai remote: Remotes > Generator > RepairEvent / SkillCheckResultEvent)
spawn(function()
        while wait(0.2) do
                if not Config.AutoGenerator then continue end
                pcall(function()
                        local repairEvent, skillCheckEvent = getGeneratorRemotes()
                        if not repairEvent or not skillCheckEvent then return end

                        local map = Workspace:FindFirstChild("Map") or Workspace
                        for _, obj in pairs(map:GetDescendants()) do
                                if not Config.AutoGenerator then break end
                                if obj:IsA("Model") and obj.Name == "Generator" then
                                        for _, point in pairs(obj:GetChildren()) do
                                                if point.Name:find("GeneratorPoint") then
                                                        pcall(function()
                                                                repairEvent:FireServer(point, true)
                                                                local result = Config.GenSkillCheckMode == "Perfect" and "success" or "neutral"
                                                                local value = Config.GenSkillCheckMode == "Perfect" and 1 or 0
                                                                skillCheckEvent:FireServer(result, value, obj, point)
                                                        end)
                                                end
                                        end
                                end
                        end
                end)
        end
end)

-- SELF UNHOOK
spawn(function()
        while wait(0.25) do
                if not Config.SelfUnHook then continue end
                local h = getHumanoid()
                if not h then continue end
                local s = h:GetState()
                if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll then
                        local root = getRootPart()
                        if not root then continue end
                        for _, hook in pairs(findPartsByName({ "hook" })) do
                                if (hook.Position - root.Position).Magnitude < 8 then
                                        for _, r in pairs(findRemotes({ "Hook", "Unhook", "Escape", "Struggle", "SelfUnhook" })) do
                                                pcall(function() r:FireServer(hook, 1.0, true) end)
                                        end
                                        break
                                end
                        end
                end
        end
end)

-- BOOST ALL GEN (Continuous) — pakai remote yang benar
spawn(function()
        while wait(2) do
                if not Config.BoostAllGen then continue end
                pcall(function()
                        local repairEvent, skillCheckEvent = getGeneratorRemotes()
                        if not repairEvent or not skillCheckEvent then return end
                        local generators = findAllGenerators()
                        for _, genData in pairs(generators) do
                                for _, point in pairs(genData.model:GetChildren()) do
                                        if point.Name:find("GeneratorPoint") then
                                                pcall(function()
                                                        repairEvent:FireServer(point, true)
                                                        skillCheckEvent:FireServer("success", 1, genData.model, point)
                                                end)
                                        end
                                end
                        end
                end)
        end
end)

-- INSTANT ESCAPE (Continuous)
spawn(function()
        while wait(1) do
                if not Config.InstantEscape then continue end
                local gates = findPartsByName({ "gate", "exit", "door" })
                local rems = findRemotes({ "Gate", "Exit", "Open", "Escape", "Lever", "Complete" })
                for _, gate in pairs(gates) do
                        teleportTo(gate.Position)
                        for _, r in pairs(rems) do pcall(function() r:FireServer(gate) end) end
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
print("║   VIOLENCE DISTRICT HUB — WINDUI EDITION                  ║")
print("║                                                           ║")
print("║  Keybinds:                                                ║")
print("║    RightCtrl  -> Toggle GUI (default)                     ║")
print("║    H          -> Instant Heal                             ║")
print("║    R          -> Force Reset State                        ║")
print("║    G          -> Toggle God Mode                          ║")
print("║    T          -> Toggle FPP / TPP                         ║")
print("╚══════════════════════════════════════════════════════════════╝")
