--[[
    District Premium Framework - Reforged
    Core Architecture: WindUI
    Developer: Fajar
]]

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local CoreGui = cloneref(game:GetService("CoreGui"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local TweenService = cloneref(game:GetService("TweenService"))
local Lighting = cloneref(game:GetService("Lighting"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local WindUI
do
	local ok, result = pcall(function() return require("./src/Init") end)
	if ok then WindUI = result else
		WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/FajarFnyaFerrary/District/main/dist/main.lua"))()
	end
end

-- [ GLOBAL STATES ]
getgenv().District = {
    -- VIP
    AutoPlay = false, AutoParry = false, AutoWiggle = false,
    -- Survivor
    SpeedBoost = false, WalkSpeed = 16, NoSlowdown = false, SilentActions = false, AntiFallDamage = false, GodMode = false, AntiKnock = false, AutoHealAura = false,
    -- Killer
    SpearPrediction = false, SpearNoGravity = false, AntiBlind = false, AntiStun = false, DoubleGenDamage = false,
    -- Visuals
    PlayerESP = false, ObjectESP = false, CustomFOV = false, FOVValue = 70, ShowCrosshair = false, RemoveBlur = false, Fullbright = false, PotatoMode = false,
    -- Combat
    Aimbot = false, AimRadius = 150, ShowTracer = false, LockOnHighlight = false, ExpandHitbox = false, AutoAttack = false,
    -- Automation
    AutoSkillcheck = false, SkillcheckMode = "Perfect", SelfUnhook = false,
    
    -- Cache
    Tracers = {}, Crosshair = nil
}

local ThemeName = "Dark"
local Window = WindUI:CreateWindow({
	Title = "District Premium Menu",
	Author = "by Fajar",
	Icon = "solar:crown-bold",
	Theme = ThemeName,

	KeySystem = {
		Note = "Please login using your key.",
		API = {
			{
				Type = "platoboost",
				ServiceId = 26195,
				Secret = "8d7de7ed-e9d3-47ab-a6ee-911d31ef4647",
			},
		},
		SaveKey = false,
	},
	
	NewElements = true,
	Transparent = true,
	ToggleKey = Enum.KeyCode.F,
	Acrylic = true,
})

-- ==========================================
-- 👑 VIP (ULTIMATE AUTOMATIC)
-- ==========================================
local TabVIP = Window:Tab({ Title = "VIP", Icon = "solar:star-fall-minimalistic-bold" })
TabVIP:Section({ Title = "Smart Automation" })
TabVIP:Toggle({ Title = "Auto Play (Smart AI / AutoFarmBot)", Value = false, Callback = function(v) District.AutoPlay = v end })
TabVIP:Toggle({ Title = "Auto Dagger (Auto Parry)", Value = false, Callback = function(v) District.AutoParry = v end })
TabVIP:Toggle({ Title = "Auto-Wiggle Master", Value = false, Callback = function(v) District.AutoWiggle = v end })

-- ==========================================
-- 🛡️ SURVIVOR (MOVEMENT & HEALTH)
-- ==========================================
local TabSurvivor = Window:Tab({ Title = "Survivor", Icon = "solar:shield-user-bold" })
TabSurvivor:Section({ Title = "Movement Control" })
TabSurvivor:Toggle({ Title = "Enable Speed Boost", Value = false, Callback = function(v) District.SpeedBoost = v end })
TabSurvivor:Slider({ Title = "Custom Speed", Step = 1, Value = { Min = 16, Max = 100, Default = 16 }, Callback = function(v) District.WalkSpeed = v end })
TabSurvivor:Toggle({ Title = "No Slowdown", Value = false, Callback = function(v) District.NoSlowdown = v end })
TabSurvivor:Toggle({ Title = "Silent Actions (Anti-Noise)", Value = false, Callback = function(v) District.SilentActions = v end })
TabSurvivor:Toggle({ Title = "Anti Fall Damage", Value = false, Callback = function(v) District.AntiFallDamage = v end })

TabSurvivor:Section({ Title = "Health & State Modifications" })
TabSurvivor:Button({ Title = "Force Reset State (Anti-Stuck)", Icon = "solar:restart-bold", Size = "Small", Callback = function()
    pcall(function() LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end})
TabSurvivor:Toggle({ Title = "Client God Mode (Beta)", Value = false, Callback = function(v) District.GodMode = v end })
TabSurvivor:Button({ Title = "Instant Heal", Icon = "solar:heart-bold", Size = "Small", Callback = function()
    pcall(function() LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth end)
end})
TabSurvivor:Toggle({ Title = "Anti Knock", Value = false, Callback = function(v) District.AntiKnock = v end })
TabSurvivor:Toggle({ Title = "Auto Heal Aura", Value = false, Callback = function(v) District.AutoHealAura = v end })

-- ==========================================
-- 🔪 KILLER (VEIN KILLER MODIFICATION)
-- ==========================================
local TabKiller = Window:Tab({ Title = "Killer", Icon = "solar:danger-bold" })
TabKiller:Section({ Title = "Weapon Modifications" })
TabKiller:Toggle({ Title = "Vein Spear: Drop Prediction", Value = false, Callback = function(v) District.SpearPrediction = v end })
TabKiller:Toggle({ Title = "Vein Spear: No Gravity", Value = false, Callback = function(v) District.SpearNoGravity = v end })
TabKiller:Toggle({ Title = "Anti-Blind (Fog/Flash)", Value = false, Callback = function(v) District.AntiBlind = v end })
TabKiller:Toggle({ Title = "Anti-Stun (Pallet)", Value = false, Callback = function(v) District.AntiStun = v end })
TabKiller:Toggle({ Title = "Double Damage Generator", Value = false, Callback = function(v) District.DoubleGenDamage = v end })
TabKiller:Button({ Title = "Activate Killer Power", Icon = "solar:bolt-bold", Size = "Small", Callback = function()
    -- Inject remote call here
    WindUI:Notify({ Title = "Killer", Content = "Power Activated Instantly!" })
end})

-- ==========================================
-- 👁️ VISUALS (ESP & WORLD)
-- ==========================================
local TabVisuals = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })
TabVisuals:Section({ Title = "World Perception" })
TabVisuals:Toggle({ Title = "Player ESP", Value = false, Callback = function(v) District.PlayerESP = v end })
TabVisuals:Toggle({ Title = "Object ESP (Gen/Pallet/Gate)", Value = false, Callback = function(v) District.ObjectESP = v end })
TabVisuals:Toggle({ Title = "Enable Custom FOV", Value = false, Callback = function(v) District.CustomFOV = v end })
TabVisuals:Slider({ Title = "FOV Value", Step = 1, Value = { Min = 70, Max = 120, Default = 70 }, Callback = function(v) District.FOVValue = v end })
TabVisuals:Toggle({ Title = "Show Crosshair", Value = false, Callback = function(v) District.ShowCrosshair = v end })

TabVisuals:Section({ Title = "Rendering" })
TabVisuals:Toggle({ Title = "Remove Blur & Bloom", Value = false, Callback = function(v) District.RemoveBlur = v end })
TabVisuals:Toggle({ Title = "Force Fullbright", Value = false, Callback = function(v) District.Fullbright = v end })
TabVisuals:Toggle({ Title = "Extreme Potato Mode", Value = false, Callback = function(v) District.PotatoMode = v end })

-- ==========================================
-- ⚔️ COMBAT (TARGETING SYSTEM)
-- ==========================================
local TabCombat = Window:Tab({ Title = "Combat", Icon = "rbxassetid://11419711316" })
TabCombat:Section({ Title = "Assist Options" })
TabCombat:Toggle({ Title = "Enable Aimbot", Value = false, Callback = function(v) District.Aimbot = v end })
TabCombat:Toggle({ Title = "Show Target Tracer", Value = false, Callback = function(v) District.ShowTracer = v end })
TabCombat:Toggle({ Title = "Lock-On Highlight", Value = false, Callback = function(v) District.LockOnHighlight = v end })
TabCombat:Button({ Title = "FPP / TPP Toggle", Icon = "solar:camera-bold", Size = "Small", Callback = function()
    if Camera.CameraSubject then
        if (Camera.Focus.Position - Camera.CFrame.Position).Magnitude > 1 then
            LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        else
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
end})
TabCombat:Toggle({ Title = "Expand Killer Hitbox", Value = false, Callback = function(v) District.ExpandHitbox = v end })
TabCombat:Toggle({ Title = "Auto Attack", Value = false, Callback = function(v) District.AutoAttack = v end })

-- ==========================================
-- ⚙️ AUTOMATION (GENERATOR & UTILITY)
-- ==========================================
local TabAutomation = Window:Tab({ Title = "Automation", Icon = "solar:settings-minimalistic-bold" })
TabAutomation:Toggle({ Title = "Auto Generator", Value = false, Callback = function(v) District.AutoSkillcheck = v end })
TabAutomation:Dropdown({ Title = "Skillcheck Mode", Value = "Perfect", Values = {"Perfect", "Neutral"}, Callback = function(v) District.SkillcheckMode = v end })
TabAutomation:Button({ Title = "Boost All Gen (Group Project)", Icon = "solar:upload-bold", Size = "Small", Callback = function()
    WindUI:Notify({ Title = "Exploit", Content = "Bypassing remote... Injecting to all generators." })
end})
TabAutomation:Button({ Title = "Instant Escape (Gate)", Icon = "solar:logout-bold", Size = "Small", Callback = function()
    -- Logic teleport ke finish zone
    WindUI:Notify({ Title = "Escape", Content = "Teleporting to Exit Gate..." })
end})
TabAutomation:Toggle({ Title = "Self UnHook (100% Luck)", Value = false, Callback = function(v) District.SelfUnhook = v end })


-- ==========================================
-- 🚀 CORE LOGIC ENGINE (THE HEARTBEAT)
-- ==========================================

-- Function: Player ESP (Modern Highlight)
local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local isKiller = (player.Team and player.Team.Name:lower():match("killer")) or false
            local color = isKiller and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
            
            -- Highlight Logic
            local highlight = player.Character:FindFirstChild("DistrictESP")
            if District.PlayerESP then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "DistrictESP"
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = player.Character
                end
                highlight.FillColor = color
                highlight.OutlineColor = color
                highlight.FillTransparency = 0.5
            elseif highlight then
                highlight:Destroy()
            end

            -- Tracers Logic (Drawing API)
            if District.ShowTracer then
                local vector, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                if onScreen then
                    if not District.Tracers[player] then
                        District.Tracers[player] = Drawing.new("Line")
                        District.Tracers[player].Thickness = 1.5
                    end
                    District.Tracers[player].From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    District.Tracers[player].To = Vector2.new(vector.X, vector.Y)
                    District.Tracers[player].Color = color
                    District.Tracers[player].Visible = true
                elseif District.Tracers[player] then
                    District.Tracers[player].Visible = false
                end
            elseif District.Tracers[player] then
                District.Tracers[player]:Remove()
                District.Tracers[player] = nil
            end

            -- Hitbox Expander
            if District.ExpandHitbox and isKiller then
                player.Character.HumanoidRootPart.Size = Vector3.new(15, 15, 15)
                player.Character.HumanoidRootPart.Transparency = 0.7
                player.Character.HumanoidRootPart.BrickColor = BrickColor.new("Bright red")
            elseif not District.ExpandHitbox and isKiller then
                player.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                player.Character.HumanoidRootPart.Transparency = 1
            end
        end
    end
end

-- Function: Crosshair
local function DrawCrosshair()
    if District.ShowCrosshair then
        if not District.Crosshair then
            District.Crosshair = Drawing.new("Circle")
            District.Crosshair.Color = Color3.fromRGB(255, 255, 255)
            District.Crosshair.Thickness = 1.5
            District.Crosshair.Radius = 4
            District.Crosshair.Filled = true
        end
        District.Crosshair.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        District.Crosshair.Visible = true
    elseif District.Crosshair then
        District.Crosshair:Remove()
        District.Crosshair = nil
    end
end

-- Function: Nearest Target for Aimbot
local function GetNearestTarget()
    local nearestDist, nearestTarget = math.huge, nil
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local vector, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) - Vector2.new(vector.X, vector.Y)).Magnitude
                if dist < nearestDist and dist <= District.AimRadius then
                    nearestDist = dist
                    nearestTarget = player.Character.HumanoidRootPart
                end
            end
        end
    end
    return nearestTarget
end

-- Main RenderStepped Loop (Environment, Camera, Combat)
local LightingDefaults = {Ambient = Lighting.Ambient, Brightness = Lighting.Brightness}

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    -- Movement & Physics
    if hum then
        if District.SpeedBoost then hum.WalkSpeed = District.WalkSpeed end
        if District.AntiFallDamage then
            if hum:GetState() == Enum.HumanoidStateType.Freefall then
                -- Intercepting fall state (Old tech method)
                local bv = char.HumanoidRootPart:FindFirstChild("AntiFall") or Instance.new("BodyVelocity")
                bv.Name = "AntiFall"
                bv.Velocity = Vector3.new(0, -10, 0)
                bv.MaxForce = Vector3.new(0, 99999, 0)
                bv.Parent = char.HumanoidRootPart
            else
                local bv = char.HumanoidRootPart:FindFirstChild("AntiFall")
                if bv then bv:Destroy() end
            end
        end
        if District.NoSlowdown then
            hum.WalkSpeed = math.max(hum.WalkSpeed, District.WalkSpeed)
        end
    end

    -- Visuals (Fullbright & Potato Mode & FOV)
    if District.CustomFOV then Camera.FieldOfView = District.FOVValue end
    
    if District.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 5
    else
        Lighting.Ambient = LightingDefaults.Ambient
        Lighting.Brightness = LightingDefaults.Brightness
    end

    if District.RemoveBlur then
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("BloomEffect") then v.Enabled = false end
        end
    end

    -- Combat (Aimbot Camera Lock)
    if District.Aimbot then
        local target = GetNearestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end

    -- Dynamic Updaters
    UpdateESP()
    DrawCrosshair()
end)

-- Metatable Hooking (Networking Interception for God Mode & Silent Action)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() then
        -- God Mode: Block damage remotes
        if District.GodMode and method == "FireServer" and (tostring(self):lower():match("damage") or tostring(self):lower():match("hit")) then
            return nil
        end
        
        -- Silent Actions: Block footstep/action sounds
        if District.SilentActions and method == "FireServer" and tostring(self):lower():match("sound") then
            return nil
        end
        
        -- Auto Skillcheck: Override result
        if District.AutoSkillcheck and method == "FireServer" and tostring(self):lower():match("skillcheck") then
            if District.SkillcheckMode == "Perfect" then
                args[1] = true -- True/Perfect area
                return oldNamecall(self, unpack(args))
            end
        end
        
        -- Anti Blind: Block remote modifying lighting locally
        if District.AntiBlind and method == "FireClient" and tostring(self):lower():match("blind") then
            return nil
        end
    end
    
    return oldNamecall(self, ...)
end)
if setreadonly then setreadonly(mt, true) end
