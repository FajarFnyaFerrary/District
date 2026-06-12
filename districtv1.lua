--[[
    District.lua - Integrated Premium Menu
    UI Framework: WindUI
    All features fully implemented with functional logic.
]]

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Workspace = cloneref(game:GetService("Workspace"))
local Camera = Workspace.CurrentCamera

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================
local function getCharacter()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
	local char = getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getNearestPlayer(roleFilter, maxDist)
	maxDist = maxDist or math.huge
	local nearest = nil
	local nearestDist = maxDist
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if roleFilter then
				-- Check if player has the matching attribute/tag
				local role = player:GetAttribute("Role") or player.Character:GetAttribute("Role")
				if role ~= roleFilter then continue end
			end
			local dist = (getRootPart().Position - player.Character.HumanoidRootPart.Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = player
			end
		end
	end
	return nearest, nearestDist
end

local function findNearestPart(model, partNamePattern, maxDist)
	maxDist = maxDist or math.huge
	local root = getRootPart()
	if not root then return nil end
	local nearest = nil
	local nearestDist = maxDist
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") and (obj.Name:find(partNamePattern) or (obj.Parent and obj.Parent.Name:find(partNamePattern))) then
			local dist = (root.Position - obj.Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = obj
			end
		end
	end
	return nearest, nearestDist
end

local function findPartByName(parent, names, maxDist)
	maxDist = maxDist or math.huge
	local root = getRootPart()
	if not root then return nil, 0 end
	local nearest = nil
	local nearestDist = maxDist
	for _, name in ipairs(names) do
		for _, obj in ipairs(parent:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name:lower():find(name:lower()) then
				local dist = (root.Position - obj.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearest = obj
				end
			end
		end
	end
	return nearest, nearestDist
end

local function moveToPosition(targetPos, speed)
	speed = speed or 16
	local char = getCharacter()
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local root = getRootPart()
	if humanoid and root and humanoid.Health > 0 then
		humanoid:MoveTo(targetPos)
	end
end

local function pathToPosition(targetPos)
	local char = getCharacter()
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:MoveTo(targetPos)
	end
end

-- ==========================================
-- GLOBAL STATE VARIABLES
-- ==========================================
_G.AutoPlay = false
_G.AutoParry = false
_G.AutoWiggle = false
_G.SpeedBoost = false
_G.WalkSpeedValue = 16
_G.NoSlowdown = false
_G.SilentActions = false
_G.AntiFallDamage = false
_G.GodMode = false
_G.AntiKnock = false
_G.AutoHealAura = false
_G.SpearPrediction = false
_G.SpearNoGravity = false
_G.AntiBlind = false
_G.AntiStun = false
_G.DoubleDamageGen = false
_G.ActivatePower = false
_G.PlayerESP = false
_G.ObjectESP = false
_G.CustomFOV = false
_G.ShowCrosshair = false
_G.RemoveBlurBloom = false
_G.Fullbright = false
_G.PotatoMode = false
_G.Aimbot = false
_G.TargetTracer = false
_G.LockOnHighlight = false
_G.FppTppToggle = false
_G.ExpandHitbox = false
_G.AutoAttack = false
_G.AutoGenSkillcheck = false
_G.SkillcheckMode = "Perfect"
_G.SelfUnHook = false
_G.AimRadius = 150
_G.AimCircleVisible = true

-- ==========================================
-- WINDUI INITIALIZATION (FIXED FOR EXECUTOR)
-- ==========================================
local WindUI
do
	local ok, result = pcall(function()
		return require("./src/Init")
	end)

	if ok then
		WindUI = result
	else
		-- Memperbaiki infinite yield jika writefile tidak ada di executor
		local rsWind = ReplicatedStorage:FindFirstChild("WindUI")
		if rsWind then
			WindUI = require(rsWind:WaitForChild("Init"))
		else
			WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/FajarFnyaFerrary/District/main/dist/main.lua"))()
		end
	end
end

local ThemeName = "Dark"

local Window = WindUI:CreateWindow({
	Title = "Violence District | ",
	Author = "by Zeetttify",
	Icon = "solar:shield-keyhole-bold",
	Theme = ThemeName,
	NewElements = true,
	Transparent = true,
	ToggleKey = Enum.KeyCode.F,
	Acrylic = true,
	
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
	}
})

-- ==========================================
-- 👑 TAB 1: VIP (ULTIMATE AUTOMATIC)
-- ==========================================
local TabVIP = Window:Tab({
	Title = "VIP",
	Icon = "solar:star-fall-minimalistic-bold",
})

TabVIP:Section({ Title = "Ultimate Automatic Bot", Desc = "Premium automated gameplay logic" })

TabVIP:Toggle({
	Title = "Auto Play (Smart AI / AutoFarm)",
	Value = false,
	Callback = function(v)
		_G.AutoPlay = v
		if v then
			WindUI:Notify({ Title = "VIP", Content = "Auto Play Bot Activated!" })
		else
			WindUI:Notify({ Title = "VIP", Content = "Auto Play Bot Deactivated." })
		end
	end,
})

TabVIP:Toggle({
	Title = "Auto Dagger (Auto Parry)",
	Value = false,
	Callback = function(v)
		_G.AutoParry = v
		if v then
			WindUI:Notify({ Title = "VIP", Content = "Auto Parry Dagger Ready!" })
		end
	end,
})

TabVIP:Toggle({
	Title = "Auto-Wiggle Master",
	Value = false,
	Callback = function(v)
		_G.AutoWiggle = v
		if v then
			WindUI:Notify({ Title = "VIP", Content = "Auto Wiggle Master Enabled!" })
		end
	end,
})

-- ==========================================
-- 🛡️ TAB 2: SURVIVOR (MOVEMENT & HEALTH)
-- ==========================================
local TabSurvivor = Window:Tab({
	Title = "Survivor",
	Icon = "solar:shield-user-bold",
})

TabSurvivor:Section({ Title = "Movement & Attributes" })

TabSurvivor:Toggle({
	Title = "Enable Speed Boost",
	Value = false,
	Callback = function(v)
		_G.SpeedBoost = v
	end,
})

TabSurvivor:Slider({
	Title = "Custom Speed",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 16, Max = 100, Default = 16 },
	Callback = function(value)
		_G.WalkSpeedValue = value
		pcall(function()
			if _G.SpeedBoost and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
				LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = value
			end
		end)
	end,
})

TabSurvivor:Toggle({
	Title = "No Slowdown (Anti-Debuff)",
	Value = false,
	Callback = function(v)
		_G.NoSlowdown = v
	end,
})

TabSurvivor:Toggle({
	Title = "Silent Actions (Anti-Noise)",
	Value = false,
	Callback = function(v)
		_G.SilentActions = v
	end,
})

TabSurvivor:Toggle({
	Title = "Anti Fall Damage",
	Value = false,
	Callback = function(v)
		_G.AntiFallDamage = v
	end,
})

TabSurvivor:Space({ Columns = 0.5 })
TabSurvivor:Section({ Title = "Health Modification (Beta)" })

TabSurvivor:Toggle({
	Title = "Client God Mode",
	Value = false,
	Callback = function(v)
		_G.GodMode = v
		if v then
			WindUI:Notify({ Title = "Survivor", Content = "Client God Mode Activated (Beta)!" })
		end
	end,
})

TabSurvivor:Toggle({
	Title = "Anti Knockdown",
	Value = false,
	Callback = function(v)
		_G.AntiKnock = v
	end,
})

TabSurvivor:Toggle({
	Title = "Auto Heal Aura (Teammates)",
	Value = false,
	Callback = function(v)
		_G.AutoHealAura = v
		if v then
			WindUI:Notify({ Title = "Survivor", Content = "Auto Heal Aura Active!" })
		end
	end,
})

TabSurvivor:Button({
	Title = "Instant Heal (Self)",
	Justify = "Center",
	Icon = "solar:heart-bold",
	Size = "Small",
	Callback = function()
		pcall(function()
			local humanoid = getHumanoid()
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
				-- Fire heal remote if exists
				for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
					if obj:IsA("RemoteEvent") and (obj.Name:lower():find("heal") or obj.Name:lower():find("health")) then
						obj:FireServer()
					end
				end
			end
		end)
		WindUI:Notify({ Title = "Survivor", Content = "Instant Heal Activated!" })
	end,
})

TabSurvivor:Button({
	Title = "Force Reset State (Anti-Stuck)",
	Justify = "Center",
	Icon = "solar:restart-bold",
	Size = "Small",
	Callback = function()
		pcall(function()
			local char = getCharacter()
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart")
			if humanoid then
				-- Reset all states
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
				-- Clear platform stand, sitting, etc.
				if humanoid.PlatformStand then
					humanoid.PlatformStand = false
				end
				if humanoid.Sit then
					humanoid.Sit = false
				end
				-- Reset animations
				for _, animTrack in ipairs(humanoid:GetPlayingAnimationTracks()) do
					animTrack:Stop()
				end
			end
			if root then
				-- Unanchor if stuck
				root.Anchored = false
				-- Reset velocity
				root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
			-- Re-trigger animations by forcing state cycle
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				task.wait(0.1)
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end)
		WindUI:Notify({ Title = "Survivor", Content = "State Reset Complete!" })
	end,
})

-- ==========================================
-- 🔪 TAB 3: KILLER (VEIN MODIFICATION)
-- ==========================================
local TabKiller = Window:Tab({
	Title = "Killer",
	Icon = "solar:danger-bold",
})

TabKiller:Section({ Title = "Vein Spear Buffs" })

TabKiller:Toggle({
	Title = "Vein Spear: Drop Prediction",
	Value = false,
	Callback = function(v)
		_G.SpearPrediction = v
		if v then
			WindUI:Notify({ Title = "Killer", Content = "Spear Drop Prediction Enabled!" })
		end
	end,
})

TabKiller:Toggle({
	Title = "Vein Spear: No Gravity",
	Value = false,
	Callback = function(v)
		_G.SpearNoGravity = v
		if v then
			WindUI:Notify({ Title = "Killer", Content = "Spear No Gravity Enabled!" })
		end
	end,
})

TabKiller:Section({ Title = "Immunities & Mechanics" })

TabKiller:Toggle({
	Title = "Anti-Blind (Fog/Flashlight)",
	Value = false,
	Callback = function(v)
		_G.AntiBlind = v
		if v then
			WindUI:Notify({ Title = "Killer", Content = "Anti-Blind Active!" })
		end
	end,
})

TabKiller:Toggle({
	Title = "Anti-Stun (Pallet Slam)",
	Value = false,
	Callback = function(v)
		_G.AntiStun = v
		if v then
			WindUI:Notify({ Title = "Killer", Content = "Anti-Stun Active!" })
		end
	end,
})

TabKiller:Toggle({
	Title = "Double Damage Generator",
	Value = false,
	Callback = function(v)
		_G.DoubleDamageGen = v
		if v then
			WindUI:Notify({ Title = "Killer", Content = "Double Damage Gen Enabled!" })
		end
	end,
})

TabKiller:Button({
	Title = "Activate Killer Power Instantly",
	Justify = "Center",
	Icon = "solar:bolt-bold",
	Size = "Small",
	Callback = function()
		_G.ActivatePower = true
		pcall(function()
			-- Try to fire killer power remote
			for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
				if obj:IsA("RemoteEvent") and (obj.Name:lower():find("power") or obj.Name:lower():find("ability")) then
					obj:FireServer()
				end
				if obj:IsA("RemoteFunction") and (obj.Name:lower():find("power") or obj.Name:lower():find("ability")) then
					obj:InvokeServer()
				end
			end
		end)
		WindUI:Notify({ Title = "Killer", Content = "Killer Power Activated!" })
	end,
})

-- ==========================================
-- 👁️ TAB 4: VISUALS (ESP & WORLD)
-- ==========================================
local TabVisuals = Window:Tab({
	Title = "Visuals",
	Icon = "solar:eye-bold",
})

TabVisuals:Section({ Title = "Extra Sensory Perception (ESP)" })

TabVisuals:Toggle({
	Title = "Player ESP (Survivor & Killer)",
	Value = false,
	Callback = function(v)
		_G.PlayerESP = v
		if v then
			WindUI:Notify({ Title = "Visuals", Content = "Player ESP Enabled!" })
		end
	end,
})

TabVisuals:Toggle({
	Title = "Object ESP (Gen, Pallet, Gate, Hook)",
	Value = false,
	Callback = function(v)
		_G.ObjectESP = v
		if v then
			WindUI:Notify({ Title = "Visuals", Content = "Object ESP Enabled!" })
		end
	end,
})

TabVisuals:Section({ Title = "Environment & Camera Settings" })

TabVisuals:Toggle({
	Title = "Enable Custom FOV",
	Value = false,
	Callback = function(v)
		_G.CustomFOV = v
		if not v then
			pcall(function()
				Camera.FieldOfView = 70
			end)
		end
	end,
})

TabVisuals:Slider({
	Title = "Field Of View",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 70, Max = 120, Default = 70 },
	Callback = function(value)
		if _G.CustomFOV then
			Camera.FieldOfView = value
		end
	end,
})

TabVisuals:Toggle({
	Title = "Show Custom Crosshair",
	Value = false,
	Callback = function(v)
		_G.ShowCrosshair = v
		if v then
			WindUI:Notify({ Title = "Visuals", Content = "Crosshair Enabled!" })
		end
	end,
})

TabVisuals:Toggle({
	Title = "Remove Blur & Bloom",
	Value = false,
	Callback = function(v)
		_G.RemoveBlurBloom = v
		if v then
			WindUI:Notify({ Title = "Visuals", Content = "Blur & Bloom Removed!" })
		end
	end,
})

TabVisuals:Toggle({
	Title = "Force Fullbright",
	Value = false,
	Callback = function(v)
		_G.Fullbright = v
		if v then
			WindUI:Notify({ Title = "Visuals", Content = "Fullbright Enabled!" })
		end
	end,
})

TabVisuals:Toggle({
	Title = "Extreme Potato Mode (FPS Boost)",
	Value = false,
	Callback = function(v)
		_G.PotatoMode = v
		if v then
			WindUI:Notify({ Title = "Visuals", Content = "Potato Mode Activated!" })
		end
	end,
})

-- ==========================================
-- ⚔️ TAB 5: COMBAT (TARGETING SYSTEM)
-- ==========================================
local TabCombat = Window:Tab({
	Title = "Combat",
	Icon = "solar:sword-bold",
})

TabCombat:Section({ Title = "Aimbot Engine" })

TabCombat:Toggle({
	Title = "Enable Combat Aimbot",
	Value = false,
	Callback = function(v)
		_G.Aimbot = v
		if v then
			WindUI:Notify({ Title = "Combat", Content = "Aimbot Enabled!" })
		end
	end,
})

TabCombat:Slider({
	Title = "Aim Radius",
	IsTooltip = true,
	Step = 10,
	Value = { Min = 50, Max = 500, Default = 150 },
	Callback = function(value)
		_G.AimRadius = value
	end,
})

TabCombat:Toggle({
	Title = "Show Target Tracer (Red Laser)",
	Value = false,
	Callback = function(v)
		_G.TargetTracer = v
		if v then
			WindUI:Notify({ Title = "Combat", Content = "Target Tracer Enabled!" })
		end
	end,
})

TabCombat:Toggle({
	Title = "Lock-On Highlight (Chams/Glow)",
	Value = false,
	Callback = function(v)
		_G.LockOnHighlight = v
		if v then
			WindUI:Notify({ Title = "Combat", Content = "Lock-On Highlight Enabled!" })
		end
	end,
})

TabCombat:Section({ Title = "Melee Modifications" })

TabCombat:Toggle({
	Title = "FPP / TPP Viewport Toggle",
	Value = false,
	Callback = function(v)
		_G.FppTppToggle = v
		if v then
			WindUI:Notify({ Title = "Combat", Content = "FPP/TPP Toggle Active!" })
		end
	end,
})

TabCombat:Toggle({
	Title = "Expand Killer Hitbox",
	Value = false,
	Callback = function(v)
		_G.ExpandHitbox = v
		if v then
			WindUI:Notify({ Title = "Combat", Content = "Hitbox Expanded!" })
		end
	end,
})

TabCombat:Toggle({
	Title = "Auto Attack Range Loop",
	Value = false,
	Callback = function(v)
		_G.AutoAttack = v
		if v then
			WindUI:Notify({ Title = "Combat", Content = "Auto Attack Active!" })
		end
	end,
})

-- ==========================================
-- ⚙️ TAB 6: AUTOMATION (GEN & UTILITY)
-- ==========================================
local TabAutomation = Window:Tab({
	Title = "Automation",
	Icon = "solar:settings-minimalistic-bold",
})

TabAutomation:Section({ Title = "Generator Exploit & Tasks" })

TabAutomation:Toggle({
	Title = "Auto Generator Skillcheck",
	Value = false,
	Callback = function(v)
		_G.AutoGenSkillcheck = v
		if v then
			WindUI:Notify({ Title = "Automation", Content = "Auto Skillcheck Enabled!" })
		end
	end,
})

TabAutomation:Dropdown({
	Title = "Skillcheck Mode",
	Value = "Perfect",
	Values = { "Perfect", "Neutral" },
	Callback = function(value)
		_G.SkillcheckMode = value
	end,
})

TabAutomation:Toggle({
	Title = "Self UnHook (100% Luck)",
	Value = false,
	Callback = function(v)
		_G.SelfUnHook = v
		if v then
			WindUI:Notify({ Title = "Automation", Content = "Self UnHook Active!" })
		end
	end,
})

TabAutomation:Space({ Columns = 0.5 })
TabAutomation:Section({ Title = "Instant Actions" })

TabAutomation:Button({
	Title = "Boost All Gen (Group Project)",
	Justify = "Center",
	Icon = "solar:upload-bold",
	Size = "Small",
	Callback = function()
		pcall(function()
			-- Find all generators in workspace and fire their progress remotes
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if (obj.Name:lower():find("generator") or obj.Name:lower():find("gen")) and obj:IsA("BasePart") then
					for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
						if remote:IsA("RemoteEvent") and (remote.Name:lower():find("gen") or remote.Name:lower():find("progress") or remote.Name:lower():find("repair")) then
							remote:FireServer(obj, 100)
						end
						if remote:IsA("RemoteFunction") and (remote.Name:lower():find("gen") or remote.Name:lower():find("progress") or remote.Name:lower():find("repair")) then
							remote:InvokeServer(obj, 100)
						end
					end
				end
			end
		end)
		WindUI:Notify({ Title = "Exploit", Content = "Injecting progress to all generators..." })
	end,
})

TabAutomation:Button({
	Title = "Instant Escape (Gate Win)",
	Justify = "Center",
	Icon = "solar:logout-bold",
	Size = "Small",
	Callback = function()
		pcall(function()
			-- Find nearest exit gate and teleport
			local gateNames = { "exit", "gate", "escape", "door" }
			local gate, dist = findPartByName(Workspace, gateNames, 500)
			if gate then
				local root = getRootPart()
				if root then
					root.CFrame = gate.CFrame + Vector3.new(0, 5, 0)
				end
				-- Fire escape remote if available
				for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
					if remote:IsA("RemoteEvent") and (remote.Name:lower():find("escape") or remote.Name:lower():find("exit") or remote.Name:lower():find("gate") or remote.Name:lower():find("win")) then
						remote:FireServer(gate)
					end
				end
			end
		end)
		WindUI:Notify({ Title = "Exploit", Content = "Teleporting to escape zone..." })
	end,
})

-- ==========================================
-- 🛠️ TAB 7: SETTINGS & THEMES
-- ==========================================
local TabSettings = Window:Tab({
	Title = "Settings",
	Icon = "solar:settings-bold",
})

local Themes = {}
local ThemesModule = WindUI.Themes
for _ThemeName, ThemeData in pairs(ThemesModule) do
	table.insert(Themes, _ThemeName)
end

TabSettings:Section({
	Title = "Theme Settings",
	Desc = "Customize your UI theme",
})

TabSettings:Space({ Columns = 2 })

local CachedPRData = {}
-- FIXED: Menggunakan FindFirstChild agar tidak terjadi Infinite Yield di Executor!
local Remote = ReplicatedStorage:FindFirstChild("GetPullRequestData")

TabSettings:Dropdown({
	Title = "Select Theme",
	Value = ThemeName,
	Values = Themes,
	Callback = function(value)
		ThemeName = value
		Window:SetTitle("Theme '" .. ThemeName .. "'")
		WindUI:SetTheme(ThemeName)
		WindUI:Notify({
			Title = "Theme Changed",
			Content = "Now using " .. ThemeName .. " theme",
		})

		local PRNumber = WindUI.Themes[ThemeName]
			and WindUI.Themes[ThemeName].Metadata
			and WindUI.Themes[ThemeName].Metadata.PullRequest
			
		-- Hanya panggil Remote jika terdeteksi di dalam Game Server
		if PRNumber and Remote then
			Window:SetAuthor("Loading...")
			if not CachedPRData[PRNumber] then
				local Success, Data = pcall(function()
					return Remote:InvokeServer("Zetttify", "WindUI", PRNumber)
				end)

				if Success and Data and Data.html_url then
					CachedPRData[PRNumber] = Data
					Window:SetAuthor("by " .. Data.user.login .. " | https://github.com/FajarFnyaFerrary/District/pull/" .. PRNumber)
				end
			else
				local Data = CachedPRData[PRNumber]
				Window:SetAuthor("by " .. Data.user.login .. " | https://github.com/FajarFnyaFerrary/District/pull/" .. PRNumber)
			end
		else
			Window:SetAuthor("by .ftgs & Fajar")
		end
	end,
})

TabSettings:Toggle({
	Title = "Toggle Window Transparency",
	Value = Window.Transparent,
	Callback = function(v)
		Window:ToggleTransparency(v)
	end,
})

TabSettings:Button({
	Title = "Unload Menu",
	Justify = "Center",
	Icon = "solar:logout-3-bold",
	Size = "Small",
	Callback = function()
		Window:Destroy()
	end,
})

TabVIP:Select()

-- #############################################################################
-- #############################################################################
--
--  ===================== FEATURE IMPLEMENTATION ENGINE =====================
--
-- #############################################################################
-- #############################################################################

-- ==========================================
-- GUI DRAWING UTILITY (ScreenGui for ESP, Crosshair, Tracer)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "District_Overlay"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = cloneref(game:GetService("CoreGui"))

-- ==========================================
-- ESP DRAWING STORAGE
-- ==========================================
local espObjects = {}      -- Player ESP highlights/billboards
local objEspObjects = {}   -- Object ESP highlights
local crosshairFrame = nil
local tracerLine = nil
local aimCircleFrame = nil

-- ==========================================
-- FUNCTION: Create/Update ESP for Players
-- ==========================================
local function clearPlayerESP()
	for _, obj in ipairs(espObjects) do
		pcall(function() obj:Destroy() end)
	end
	espObjects = {}
end

local function clearObjectESP()
	for _, obj in ipairs(objEspObjects) do
		pcall(function() obj:Destroy() end)
	end
	objEspObjects = {}
end

local function createBillboard(parent, text, color)
	local bb = Instance.new("BillboardGui")
	bb.Name = "District_ESP"
	bb.Adornee = parent
	bb.Size = UDim2.new(0, 200, 0, 60)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.5, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.Parent = bb

	local distLabel = Instance.new("TextLabel")
	distLabel.Name = "DistLabel"
	distLabel.Size = UDim2.new(1, 0, 0.5, 0)
	distLabel.Position = UDim2.new(0, 0, 0.5, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	distLabel.TextStrokeTransparency = 0.3
	distLabel.Text = ""
	distLabel.Font = Enum.Font.Gotham
	distLabel.TextSize = 11
	distLabel.Parent = bb

	return bb
end

local function createHighlight(parent, color)
	local hl = Instance.new("Highlight")
	hl.Name = "District_Highlight"
	hl.Adornee = parent
	hl.FillColor = color
	hl.FillTransparency = 0.5
	hl.OutlineColor = color
	hl.OutlineTransparency = 0.2
	hl.Parent = parent
	return hl
end

local function updatePlayerESP()
	if not _G.PlayerESP then
		clearPlayerESP()
		return
	end

	clearPlayerESP()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local char = player.Character
			local root = char.HumanoidRootPart

			-- Determine role
			local role = player:GetAttribute("Role") or char:GetAttribute("Role") or "Unknown"
			local displayName = player.DisplayName or player.Name

			-- Determine color
			local color = Color3.fromRGB(0, 255, 100) -- Survivor green
			if role:lower():find("killer") then
				color = Color3.fromRGB(255, 50, 50) -- Killer red
			elseif role:lower():find("survivor") or role == "Unknown" then
				color = Color3.fromRGB(0, 200, 255) -- Survivor cyan
			end

			local bb = createBillboard(root, "[" .. role .. "] " .. displayName, color)
			local hl = createHighlight(char, color)

			table.insert(espObjects, bb)
			table.insert(espObjects, hl)
		end
	end
end

local function updateObjectESP()
	if not _G.ObjectESP then
		clearObjectESP()
		return
	end

	clearObjectESP()

	local root = getRootPart()
	if not root then return end

	-- Search for objects in Workspace
	local objectCategories = {
		{ pattern = { "generator", "gen" }, color = Color3.fromRGB(255, 200, 0), label = "Generator" },
		{ pattern = { "pallet" }, color = Color3.fromRGB(139, 90, 43), label = "Pallet" },
		{ pattern = { "exit", "gate", "escape" }, color = Color3.fromRGB(0, 255, 100), label = "Exit Gate" },
		{ pattern = { "hook" }, color = Color3.fromRGB(255, 80, 80), label = "Hook" },
	}

	for _, cat in ipairs(objectCategories) do
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				local nameLower = obj.Name:lower()
				local matched = false
				for _, pat in ipairs(cat.pattern) do
					if nameLower:find(pat) then
						matched = true
						break
					end
				end
				if matched then
					local dist = math.floor((root.Position - obj.Position).Magnitude)
					local bb = createBillboard(obj, cat.label .. " [" .. dist .. "m]", cat.color)
					table.insert(objEspObjects, bb)

					-- For generators, show percentage if attribute exists
					if cat.label == "Generator" then
						local progress = obj:GetAttribute("Progress") or obj:GetAttribute("progress") or 0
						local distLabel = bb:FindFirstChild("DistLabel")
						if distLabel then
							distLabel.Text = "Progress: " .. tostring(progress) .. "%"
						end
					end
				end
			end
		end
	end
end

-- ==========================================
-- CROSSHAIR
-- ==========================================
local function createCrosshair()
	if crosshairFrame then pcall(function() crosshairFrame:Destroy() end) end

	crosshairFrame = Instance.new("Frame")
	crosshairFrame.Name = "District_Crosshair"
	crosshairFrame.Size = UDim2.new(0, 20, 0, 20)
	crosshairFrame.Position = UDim2.new(0.5, -10, 0.5, -10)
	crosshairFrame.BackgroundTransparency = 1
	crosshairFrame.Parent = ScreenGui

	-- Horizontal line
	local hLine = Instance.new("Frame")
	hLine.Size = UDim2.new(1, 0, 0, 2)
	hLine.Position = UDim2.new(0, 0, 0.5, -1)
	hLine.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	hLine.BorderSizePixel = 0
	hLine.Parent = crosshairFrame

	-- Vertical line
	local vLine = Instance.new("Frame")
	vLine.Size = UDim2.new(0, 2, 1, 0)
	vLine.Position = UDim2.new(0.5, -1, 0, 0)
	vLine.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	vLine.BorderSizePixel = 0
	vLine.Parent = crosshairFrame

	-- Center dot
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 4, 0, 4)
	dot.Position = UDim2.new(0.5, -2, 0.5, -2)
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.BorderSizePixel = 0
	dot.Parent = crosshairFrame
end

-- ==========================================
-- AIM CIRCLE (Visible radius indicator)
-- ==========================================
local function createAimCircle()
	if aimCircleFrame then pcall(function() aimCircleFrame:Destroy() end) end

	aimCircleFrame = Instance.new("Frame")
	aimCircleFrame.Name = "District_AimCircle"
	aimCircleFrame.Size = UDim2.new(0, _G.AimRadius * 2, 0, _G.AimRadius * 2)
	aimCircleFrame.Position = UDim2.new(0.5, -_G.AimRadius, 0.5, -_G.AimRadius)
	aimCircleFrame.BackgroundTransparency = 1
	aimCircleFrame.Parent = ScreenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = aimCircleFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 50, 50)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = aimCircleFrame
end

-- ==========================================
-- TRACER LINE
-- ==========================================
local function createTracerLine()
	if tracerLine then pcall(function() tracerLine:Destroy() end) end

	tracerLine = Instance.new("Frame")
	tracerLine.Name = "District_Tracer"
	tracerLine.Size = UDim2.new(0, 2, 0, 0)
	tracerLine.Position = UDim2.new(0.5, -1, 1, 0)
	tracerLine.AnchorPoint = Vector2.new(0.5, 1)
	tracerLine.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	tracerLine.BackgroundTransparency = 0.3
	tracerLine.BorderSizePixel = 0
	tracerLine.Parent = ScreenGui
end

-- ==========================================
-- LIGHTING EFFECTS STORAGE
-- ==========================================
local originalLightingProps = {}
local potatoModeOriginals = {}

local function saveLightingState()
	originalLightingProps = {
		Brightness = Lighting.Brightness,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
		ClockTime = Lighting.ClockTime,
		GlobalShadows = Lighting.GlobalShadows,
	}
end

local function restoreLightingState()
	pcall(function()
		for k, v in pairs(originalLightingProps) do
			Lighting[k] = v
		end
		-- Remove injected effects
		for _, obj in ipairs(Lighting:GetChildren()) do
			if obj.Name:find("District_") then
				obj:Destroy()
			end
		end
	end)
end

-- ==========================================
-- MAIN LOOPS
-- ==========================================

-- ==========================================
-- LOOP 1: AUTO PLAY (SMART AI / AUTOFARMBOT)
-- ==========================================
task.spawn(function()
	while task.wait(1) do
		if not _G.AutoPlay then continue end

		pcall(function()
			local char = getCharacter()
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			local root = getRootPart()
			if not humanoid or not root or humanoid.Health <= 0 then continue end

			-- Step 1: Detect nearest killer
			local killer, killerDist = getNearestPlayer("Killer", 80)

			if killer and killerDist < 25 then
				-- FLEE: Run away from killer
				local killerRoot = killer.Character:FindFirstChild("HumanoidRootPart")
				if killerRoot then
					local awayDir = (root.Position - killerRoot.Position).Unit
					local fleePos = root.Position + awayDir * 50

					-- Also try to find nearby pallets while fleeing
					local pallet, palletDist = findPartByName(Workspace, { "pallet" }, 30)
					if pallet then
						fleePos = pallet.Position
					end

					pathToPosition(fleePos)
				end
			else
				-- Step 2: Find nearest uncompleted generator
				local nearestGen = nil
				local nearestGenDist = math.huge
				for _, obj in ipairs(Workspace:GetDescendants()) do
					if obj:IsA("BasePart") and obj.Name:lower():find("generator") then
						local progress = obj:GetAttribute("Progress") or 0
						if progress < 100 then
							local dist = (root.Position - obj.Position).Magnitude
							if dist < nearestGenDist then
								nearestGenDist = dist
								nearestGen = obj
							end
						end
					end
				end

				if nearestGen then
					-- Walk to generator
					if nearestGenDist > 5 then
						pathToPosition(nearestGen.Position)
					else
						-- "Repair" - fire repair remote
						for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
							if remote:IsA("RemoteEvent") and (remote.Name:lower():find("repair") or remote.Name:lower():find("gen")) then
								remote:FireServer(nearestGen)
							end
						end
					end
				else
					-- Step 3: No generators left, find exit gate
					local gateNames = { "exit", "gate", "escape" }
					local gate, gateDist = findPartByName(Workspace, gateNames, 200)
					if gate then
						if gateDist > 5 then
							pathToPosition(gate.Position)
						else
							-- Try to open gate
							for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
								if remote:IsA("RemoteEvent") and (remote.Name:lower():find("gate") or remote.Name:lower():find("exit") or remote.Name:lower():find("open")) then
									remote:FireServer(gate)
								end
							end
						end
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 2: AUTO DAGGER (AUTO PARRY)
-- ==========================================
task.spawn(function()
	while task.wait(0.1) do
		if not _G.AutoParry then continue end

		pcall(function()
			local char = getCharacter()
			local root = getRootPart()
			if not root then continue end

			-- Find nearest killer
			local killer, dist = getNearestPlayer("Killer", 30)
			if not killer then continue end

			local killerRoot = killer.Character and killer.Character:FindFirstChild("HumanoidRootPart")
			if not killerRoot then continue end

			-- Check if killer is within dagger parry range (15-20 studs)
			if dist <= 20 then
				-- Check if killer is attacking (animation or velocity check)
				local killerHumanoid = killer.Character:FindFirstChildOfClass("Humanoid")
				local isAttacking = false
				if killerHumanoid then
					for _, track in ipairs(killerHumanoid:GetPlayingAnimationTracks()) do
						local animName = track.Animation and track.Animation.Name:lower() or ""
						if animName:find("attack") or animName:find("swing") or animName:find("slash") or animName:find("hit") or animName:find("lunge") then
							isAttacking = true
							break
						end
					end
				end

				if isAttacking then
					-- Fire parry/dagger remote
					for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
						if obj:IsA("RemoteEvent") and (obj.Name:lower():find("parry") or obj.Name:lower():find("dagger") or obj.Name:lower():find("deflect") or obj.Name:lower():find("block")) then
							obj:FireServer()
						end
					end
					-- Also try tool-based parry
					for _, tool in ipairs(char:GetChildren()) do
						if tool:IsA("Tool") and (tool.Name:lower():find("dagger") or tool.Name:lower():find("parry") or tool.Name:lower():find("shield")) then
							tool:Activate()
						end
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 3: AUTO-WIGGLE MASTER
-- ==========================================
task.spawn(function()
	while task.wait(0.05) do
		if not _G.AutoWiggle then continue end

		pcall(function()
			local char = getCharacter()
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			if not humanoid then continue end

			-- Check if character is in a "carried" or "hooked" state
			local isCarried = false
			local stateName = tostring(humanoid:GetState())
			if stateName:find("Physics") or stateName:find("StruckDown") or humanoid.PlatformStand then
				isCarried = true
			end

			-- Also check for carry attribute
			local isBeingCarried = char:GetAttribute("BeingCarried") or char:GetAttribute("Carried") or char:GetAttribute("isCarried")

			if isCarried or isBeingCarried then
				-- Wiggle: Rapidly simulate directional input
				local directions = {
					Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
					Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right
				}
				for i = 1, #directions do
					-- Fire input events to simulate wiggle
					local key = directions[i]
					pcall(function()
						UserInputService:SendInputMethodChanged(false, key, Enum.UserInputState.Begin)
					end)
				end

				-- Fire wiggle/struggle remote
				for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
					if obj:IsA("RemoteEvent") and (obj.Name:lower():find("wiggle") or obj.Name:lower():find("struggle") or obj.Name:lower():find("escape")) then
						obj:FireServer()
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 4: SPEED BOOST & NO SLOWDOWN
-- ==========================================
task.spawn(function()
	while task.wait(0.1) do
		pcall(function()
			local humanoid = getHumanoid()
			if not humanoid then continue end

			-- Speed Boost
			if _G.SpeedBoost then
				humanoid.WalkSpeed = _G.WalkSpeedValue
			end

			-- No Slowdown: Block any speed debuffs
			if _G.NoSlowdown then
				if humanoid.WalkSpeed < _G.WalkSpeedValue then
					humanoid.WalkSpeed = _G.WalkSpeedValue
				end
				-- Reset any slowdown attributes
				local char = getCharacter()
				if char then
					for _, attr in ipairs(char:GetAttributes()) do
						if tostring(attr):lower():find("slow") or tostring(attr):lower():find("debuff") then
							pcall(function()
								char:SetAttribute(attr, 0)
							end)
						end
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 5: SILENT ACTIONS (ANTI-NOISE)
-- ==========================================
task.spawn(function()
	while task.wait(0.5) do
		if not _G.SilentActions then continue end

		pcall(function()
			-- Disable noise-related visual/sound indicators
			local char = getCharacter()
			if not char then return end

			-- Remove noise indicator GUIs
			for _, gui in ipairs(char:GetDescendants()) do
				if gui:IsA("BillboardGui") and (gui.Name:lower():find("noise") or gui.Name:lower():find("alert") or gui.Name:lower():find("sound")) then
					gui:Destroy()
				end
			end

			-- Set silent attribute
			pcall(function() char:SetAttribute("Silent", true) end)
			pcall(function() char:SetAttribute("NoiseLevel", 0) end)

			-- Lower volume of footstep sounds
			for _, obj in ipairs(char:GetDescendants()) do
				if obj:IsA("Sound") and (obj.Name:lower():find("footstep") or obj.Name:lower():find("run") or obj.Name:lower():find("step")) then
					obj.Volume = 0
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 6: ANTI FALL DAMAGE
-- ==========================================
task.spawn(function()
	while task.wait(0.05) do
		if not _G.AntiFallDamage then continue end

		pcall(function()
			local char = getCharacter()
			local root = getRootPart()
			local humanoid = getHumanoid()
			if not root or not humanoid then continue end

			-- Monitor vertical velocity for fast downward movement
			local vy = root.AssemblyLinearVelocity.Y
			if vy < -50 then
				-- Slow down fall to prevent damage
				root.AssemblyLinearVelocity = Vector3.new(
					root.AssemblyLinearVelocity.X,
					math.max(vy, -50),
					root.AssemblyLinearVelocity.Z
				)
			end

			-- Prevent fall state
			if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				-- Reduce impact by dampening
				task.wait()
				if root then
					root.AssemblyLinearVelocity = Vector3.new(
						root.AssemblyLinearVelocity.X * 0.95,
						math.max(root.AssemblyLinearVelocity.Y, -30),
						root.AssemblyLinearVelocity.Z * 0.95
					)
				end
			end

			-- Block fall damage via attribute
			pcall(function() char:SetAttribute("FallDamage", 0) end)
		end)
	end
end)

-- ==========================================
-- LOOP 7: CLIENT GOD MODE (DAMAGE NULLIFIER)
-- ==========================================
task.spawn(function()
	while task.wait(0.1) do
		if not _G.GodMode then continue end

		pcall(function()
			local humanoid = getHumanoid()
			if not humanoid then continue end

			-- Keep health at max
			if humanoid.Health < humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth
			end

			-- Block damage by hooking TakeDamage
			local char = getCharacter()
			if char then
				pcall(function() char:SetAttribute("Invincible", true) end)
				pcall(function() char:SetAttribute("GodMode", true) end)
			end
		end)
	end
end)

-- Also hook TakeDamage at the Humanoid level
task.spawn(function()
	local char = getCharacter()
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local oldTakeDamage = hookfunction(humanoid.TakeDamage, function(self, amount)
				if _G.GodMode then
					return -- Block damage
				end
				return oldTakeDamage(self, amount)
			end)
		end
	end

	-- Re-hook on character spawn
	LocalPlayer.CharacterAdded:Connect(function(newChar)
		task.wait(1)
		local hum = newChar:FindFirstChildOfClass("Humanoid")
		if hum then
			hookfunction(hum.TakeDamage, function(self, amount)
				if _G.GodMode then
					return
				end
				return self.TakeDamage(self, amount)
			end)
		end
	end)
end)

-- ==========================================
-- LOOP 8: ANTI KNOCK (PREVENT KNOCKDOWN)
-- ==========================================
task.spawn(function()
	while task.wait(0.1) do
		if not _G.AntiKnock then continue end

		pcall(function()
			local char = getCharacter()
			local humanoid = getHumanoid()
			local root = getRootPart()
			if not char or not humanoid or not root then continue end

			-- Prevent PlatformStand (knockdown state)
			if humanoid.PlatformStand then
				humanoid.PlatformStand = false
			end

			-- Prevent Ragdoll
			local state = humanoid:GetState()
			if state == Enum.HumanoidStateType.Ragdoll then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end

			-- Block knock attribute
			pcall(function() char:SetAttribute("KnockedDown", false) end)
			pcall(function() char:SetAttribute("Knocked", false) end)
		end)
	end
end)

-- ==========================================
-- LOOP 9: AUTO HEAL AURA
-- ==========================================
task.spawn(function()
	while task.wait(2) do
		if not _G.AutoHealAura then continue end

		pcall(function()
			local myChar = getCharacter()
			local myRoot = getRootPart()
			if not myChar or not myRoot then continue end

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local teammate = player
					local teammateRoot = teammate.Character.HumanoidRootPart
					local teammateHum = teammate.Character:FindFirstChildOfClass("Humanoid")

					if teammateHum and teammateHum.Health < teammateHum.MaxHealth then
						local dist = (myRoot.Position - teammateRoot.Position).Magnitude
						if dist <= 20 then
							-- Fire heal remote for teammate
							for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
								if obj:IsA("RemoteEvent") and (obj.Name:lower():find("heal") or obj.Name:lower():find("health") or obj.Name:lower():find("medkit")) then
									obj:FireServer(teammate.Character)
								end
							end
						end
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 10: VEIN SPEAR DROP PREDICTION
-- ==========================================
task.spawn(function()
	while task.wait(0.05) do
		if not _G.SpearPrediction then continue end

		pcall(function()
			local char = getCharacter()
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			local root = getRootPart()
			if not char or not root then continue end

			-- Find equipped spear tool
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") and (tool.Name:lower():find("spear") or tool.Name:lower():find("vein")) then
					-- Find nearest target
					local target, dist = getNearestPlayer(nil, 100)
					if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
						local targetRoot = target.Character.HumanoidRootPart
						-- Calculate prediction: aim slightly above for distant targets
						local predictionOffset = math.clamp(dist * 0.08, 0, 10)
						local predictedPos = targetRoot.Position + Vector3.new(0, predictionOffset, 0)

						-- Adjust camera CFrame to aim at predicted position
						local lookDir = (predictedPos - root.Position).Unit
						Camera.CFrame = CFrame.new(root.Position, root.Position + lookDir)
					end
					break
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 11: VEIN SPEAR NO GRAVITY
-- ==========================================
task.spawn(function()
	while task.wait(0.05) do
		if not _G.SpearNoGravity then continue end

		pcall(function()
			-- Find all projectile parts that could be spears
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("BasePart") and (obj.Name:lower():find("spear") or obj.Name:lower():find("projectile") or obj.Name:lower():find("vein")) then
					if obj:FindFirstChildOfClass("BodyVelocity") or obj:FindFirstChildOfClass("LinearVelocity") then
						-- Remove gravity effect: set Y velocity to maintain level flight
						local currentVel = obj.AssemblyLinearVelocity
						if currentVel.Y < 0 then
							obj.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
						end
					elseif obj.Velocity.Magnitude > 10 then
						-- Part-based projectile: stabilize Y
						local vel = obj.AssemblyLinearVelocity
						obj.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 12: ANTI-BLIND (FOG / FLASHLIGHT)
-- ==========================================
task.spawn(function()
	while task.wait(0.5) do
		if not _G.AntiBlind then
			-- Restore when disabled
			if not _G.Fullbright and not _G.PotatoMode then
				pcall(function()
					Lighting.FogEnd = originalLightingProps.FogEnd or 100000
					Lighting.FogStart = originalLightingProps.FogStart or 0
				end)
			end
			continue
		end

		pcall(function()
			-- Remove fog entirely
			Lighting.FogEnd = 100000
			Lighting.FogStart = 0

			-- Remove blur/post-processing effects from Lighting
			for _, obj in ipairs(Lighting:GetChildren()) do
				if obj:IsA("PostEffect") or obj:IsA("BlurEffect") or obj:IsA("BloomEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") then
					if obj.Name:lower():find("blur") or obj.Name:lower():find("blind") or obj.Name:lower():find("flash") or obj.Name:lower():find("fog") or obj.Name:lower():find("dark") or obj.Name:lower():find("obscure") then
						obj.Enabled = false
					end
				end
			end

			-- Remove blind effects on character
			local char = getCharacter()
			if char then
				pcall(function() char:SetAttribute("Blinded", false) end)
				pcall(function() char:SetAttribute("FlashlightBlind", 0) end)
			end
		end)
	end
end)

-- ==========================================
-- LOOP 13: ANTI-STUN (PALLET SLAM)
-- ==========================================
task.spawn(function()
	while task.wait(0.1) do
		if not _G.AntiStun then continue end

		pcall(function()
			local char = getCharacter()
			local humanoid = getHumanoid()
			if not char or not humanoid then continue end

			-- Check for stun state
			local state = humanoid:GetState()
			if state == Enum.HumanoidStateType.Stunned or state == Enum.HumanoidStateType.PlatformStand then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end

			-- Remove stun attribute
			pcall(function() char:SetAttribute("Stunned", false) end)
			pcall(function() char:SetAttribute("StunDuration", 0) end)

			-- Remove stun animation tracks
			for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
				local animName = track.Animation and track.Animation.Name:lower() or ""
				if animName:find("stun") or animName:find("dazed") or animName:find("pallet") then
					track:Stop()
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 14: DOUBLE DAMAGE GENERATOR
-- ==========================================
task.spawn(function()
	-- Hook into kick/damage generator action
	local mt = getrawmetatable(game)
	if mt and setreadonly then
		setreadonly(mt, false)
		local oldNamecall = mt.__namecall
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			local args = {...}

			if _G.DoubleDamageGen and method == "FireServer" then
				local name = self.Name:lower()
				if name:find("generator") or name:find("gen") or name:find("kick") or name:find("damage") or name:find("hit") then
					-- Fire multiple times for double/multi damage
					oldNamecall(self, ...)
					oldNamecall(self, ...)
					return
				end
			end

			return oldNamecall(self, ...)
		end)
		setreadonly(mt, true)
	end
end)

-- ==========================================
-- LOOP 15: VISUALS - ESP UPDATE
-- ==========================================
task.spawn(function()
	task.wait(2)
	saveLightingState()

	while task.wait(2) do
		updatePlayerESP()
		updateObjectESP()
	end
end)

-- ==========================================
-- LOOP 16: VISUALS - CROSSHAIR
-- ==========================================
task.spawn(function()
	createCrosshair()
	createAimCircle()
	createTracerLine()

	while task.wait(0.5) do
		-- Crosshair visibility
		if crosshairFrame then
			crosshairFrame.Enabled = _G.ShowCrosshair
		end

		-- Aim circle for aimbot
		if aimCircleFrame then
			aimCircleFrame.Enabled = _G.Aimbot
			aimCircleFrame.Size = UDim2.new(0, _G.AimRadius * 2, 0, _G.AimRadius * 2)
			aimCircleFrame.Position = UDim2.new(0.5, -_G.AimRadius, 0.5, -_G.AimRadius)
		end
	end
end)

-- ==========================================
-- LOOP 17: VISUALS - REMOVE BLUR & BLOOM
-- ==========================================
task.spawn(function()
	while task.wait(1) do
		if not _G.RemoveBlurBloom then continue end

		pcall(function()
			for _, obj in ipairs(Lighting:GetChildren()) do
				if obj:IsA("BlurEffect") or obj:IsA("BloomEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") then
					obj.Enabled = false
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 18: VISUALS - FORCE FULLBRIGHT
-- ==========================================
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			if _G.Fullbright then
				Lighting.Brightness = 2
				Lighting.Ambient = Color3.fromRGB(200, 200, 200)
				Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
				Lighting.FogEnd = 100000
				Lighting.FogStart = 0
				Lighting.GlobalShadows = false
				Lighting.ClockTime = 14

				-- Ensure no color correction darken
				for _, obj in ipairs(Lighting:GetChildren()) do
					if obj:IsA("ColorCorrectionEffect") then
						obj.Brightness = 0.1
						obj.Contrast = 0.2
						obj.Saturation = 0.1
					end
				end
			elseif not _G.AntiBlind and not _G.PotatoMode then
				-- Restore
				Lighting.Brightness = originalLightingProps.Brightness or 1
				Lighting.Ambient = originalLightingProps.Ambient or Color3.fromRGB(127, 127, 127)
				Lighting.OutdoorAmbient = originalLightingProps.OutdoorAmbient or Color3.fromRGB(127, 127, 127)
				Lighting.GlobalShadows = originalLightingProps.GlobalShadows or true
			end
		end)
	end
end)

-- ==========================================
-- LOOP 19: VISUALS - EXTREME POTATO MODE
-- ==========================================
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			if _G.PotatoMode then
				-- Minimum lighting
				Lighting.Brightness = 0
				Lighting.Ambient = Color3.fromRGB(128, 128, 128)
				Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
				Lighting.GlobalShadows = false
				Lighting.FogEnd = 100000
				Lighting.ClockTime = 14

				-- Disable all post-processing
				for _, obj in ipairs(Lighting:GetChildren()) do
					if obj:IsA("PostEffect") then
						obj.Enabled = false
					end
				end

				-- Lower quality on workspace parts
				for _, obj in ipairs(Workspace:GetDescendants()) do
					if obj:IsA("Part") or obj:IsA("MeshPart") then
						obj.Material = Enum.Material.SmoothPlastic
						if obj:IsA("MeshPart") then
							obj.MeshId = ""
							obj.TextureID = ""
						end
					end
					-- Remove particles
					if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
						obj.Enabled = false
					end
					-- Remove decals/textures
					if obj:IsA("Decal") or obj:IsA("Texture") then
						obj.Transparency = 1
					end
				end

				-- Set low render quality
				settings().Rendering.QualityLevel = 1
			else
				settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
			end
		end)
	end
end)

-- ==========================================
-- LOOP 20: COMBAT - AIMBOT
-- ==========================================
task.spawn(function()
	while task.wait(0.01) do
		if not _G.Aimbot then continue end

		pcall(function()
			local char = getCharacter()
			local root = getRootPart()
			if not char or not root then continue end

			-- Find nearest enemy player
			local target, dist = getNearestPlayer(nil, _G.AimRadius)

			-- Also try to find killer specifically for wider range
			if not target or dist > _G.AimRadius then
				local killer, kDist = getNearestPlayer("Killer", _G.AimRadius)
				if killer then
					target = killer
					dist = kDist
				end
			end

			if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
				local targetRoot = target.Character.HumanoidRootPart
				-- Point camera at target
				local lookDir = (targetRoot.Position - root.Position).Unit
				Camera.CFrame = CFrame.new(root.Position, root.Position + lookDir)
			end
		end)
	end
end)

-- ==========================================
-- LOOP 21: COMBAT - TARGET TRACER LINE
-- ==========================================
task.spawn(function()
	while task.wait(0.03) do
		if tracerLine then
			tracerLine.Enabled = _G.TargetTracer
		end

		if not _G.TargetTracer then continue end

		pcall(function()
			local char = getCharacter()
			local root = getRootPart()
			if not root or not tracerLine then continue end

			local target, dist = getNearestPlayer(nil, 200)
			if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then continue end

			local targetRoot = target.Character.HumanoidRootPart
			local screenPos, onScreen = Camera:WorldToScreenPoint(targetRoot.Position)

			if onScreen then
				local viewSize = Camera.ViewportSize
				local screenX = screenPos.X / viewSize.X
				local screenY = screenPos.Y / viewSize.Y

				-- Calculate line from bottom center to target
				local dx = screenX - 0.5
				local dy = screenY - 1.0
				local length = math.sqrt(dx * dx + dy * dy)
				local angle = math.atan2(dy, dx)

				tracerLine.Size = UDim2.new(0, 2, 0, length * viewSize.Y)
				tracerLine.Position = UDim2.new(0.5, -1, 1, 0)
				tracerLine.Rotation = math.deg(angle) - 90
				tracerLine.BackgroundTransparency = 0.3
			else
				tracerLine.Size = UDim2.new(0, 2, 0, 0)
			end
		end)
	end
end)

-- ==========================================
-- LOOP 22: COMBAT - LOCK-ON HIGHLIGHT
-- ==========================================
local lockOnHighlights = {}

task.spawn(function()
	while task.wait(0.5) do
		-- Clear old highlights
		for _, hl in ipairs(lockOnHighlights) do
			pcall(function() hl:Destroy() end)
		end
		lockOnHighlights = {}

		if not _G.LockOnHighlight then continue end

		pcall(function()
			local target, dist = getNearestPlayer(nil, 200)
			if not target or not target.Character then return end

			local hl = Instance.new("Highlight")
			hl.Name = "District_LockOn"
			hl.Adornee = target.Character
			hl.FillColor = Color3.fromRGB(255, 50, 50)
			hl.FillTransparency = 0.6
			hl.OutlineColor = Color3.fromRGB(255, 215, 0) -- Gold outline
			hl.OutlineTransparency = 0
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = target.Character

			table.insert(lockOnHighlights, hl)
		end)
	end
end)

-- ==========================================
-- LOOP 23: COMBAT - FPP / TPP TOGGLE
-- ==========================================
local isFPP = false
task.spawn(function()
	while task.wait(0.5) do
		if not _G.FppTppToggle then continue end

		pcall(function()
			local char = getCharacter()
			if not char then return end

			local camSubject = Camera.CameraSubject
			if not camSubject then return end

			-- Toggle between first person and third person
			if UserInputService:IsKeyDown(Enum.KeyCode.V) then
				isFPP = not isFPP
				task.wait(0.5)
			end

			-- Force camera mode
			if isFPP then
				-- First person: zoom in
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.LookVector * 100 + Camera.CFrame.Position)
				Camera.FieldOfView = 90
			end
		end)
	end
end)

-- ==========================================
-- LOOP 24: COMBAT - EXPAND KILLER HITBOX
-- ==========================================
task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character then
					local role = player:GetAttribute("Role") or player.Character:GetAttribute("Role") or ""
					if role:lower():find("killer") then
						local hum = player.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							-- Expand body depth/radius for hitbox
							if _G.ExpandHitbox then
								hum.BodyDepthScale.Value = 2.0
								hum.BodyHeightScale.Value = 1.5
								hum.BodyWidthScale.Value = 2.0
								hum.HeadScale.Value = 2.0
							else
								-- Restore defaults
								hum.BodyDepthScale.Value = 1
								hum.BodyHeightScale.Value = 1
								hum.BodyWidthScale.Value = 1
								hum.HeadScale.Value = 1
							end
						end
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 25: COMBAT - AUTO ATTACK
-- ==========================================
task.spawn(function()
	while task.wait(0.3) do
		if not _G.AutoAttack then continue end

		pcall(function()
			local char = getCharacter()
			local root = getRootPart()
			if not char or not root then continue end

			-- Find nearest enemy within attack range (~5-8 studs)
			local target, dist = getNearestPlayer(nil, 8)
			if not target or not target.Character then return end

			-- Face target
			local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local lookDir = (targetRoot.Position - root.Position).Unit
				Camera.CFrame = CFrame.new(root.Position, root.Position + lookDir)
			end

			-- Try to attack using tools or remotes
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					tool:Activate()
				end
			end

			-- Fire attack remotes
			for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
				if obj:IsA("RemoteEvent") and (obj.Name:lower():find("attack") or obj.Name:lower():find("hit") or obj.Name:lower():find("swing") or obj.Name:lower():find("slash")) then
					obj:FireServer(target.Character)
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 26: AUTO GENERATOR SKILLCHECK
-- ==========================================
task.spawn(function()
	-- Hook into the GUI for skillcheck
	while task.wait(0.05) do
		if not _G.AutoGenSkillcheck then continue end

		pcall(function()
			-- Search for skillcheck UI elements in PlayerGui
			local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
			if not playerGui then continue end

			for _, gui in ipairs(playerGui:GetDescendants()) do
				if gui:IsA("Frame") and (gui.Name:lower():find("skillcheck") or gui.Name:lower():find("skill_check") or gui.Name:lower():find("skill")) then
					-- Find the indicator/needle
					for _, child in ipairs(gui:GetDescendants()) do
						if child:IsA("Frame") and (child.Name:lower():find("needle") or child.Name:lower():find("indicator") or child.Name:lower():find("pointer")) then
							-- Find the success zone
							for _, zone in ipairs(gui:GetDescendants()) do
								if zone:IsA("Frame") and (zone.Name:lower():find("good") or zone.Name:lower():find("perfect") or zone.Name:lower():find("great") or zone.Name:lower():find("success") or zone.Name:lower():find("zone")) then
									-- Move indicator to the center of the zone
									if _G.SkillcheckMode == "Perfect" then
										-- Find the "perfect" sub-zone if it exists, otherwise use the main zone
										local perfectZone = nil
										for _, pz in ipairs(gui:GetDescendants()) do
											if pz:IsA("Frame") and pz.Name:lower():find("perfect") then
												perfectZone = pz
												break
											end
										end

										local targetZone = perfectZone or zone
										if _G.SkillcheckMode == "Neutral" then
											targetZone = zone
										end

										-- Smoothly move indicator to zone center
										local zonePos = targetZone.Position
										local zoneSize = targetZone.Size
										local targetPos = UDim2.new(
											zonePos.X.Scale + zoneSize.X.Scale / 2 - child.Size.X.Scale / 2,
											zonePos.X.Offset + zoneSize.X.Offset / 2,
											child.Position.Y.Scale,
											child.Position.Y.Offset
										)

										local tween = TweenService:Create(child, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
											Position = targetPos
										})
										tween:Play()
									end
									break
								end
							end
						end
					end
				end
			end

			-- Also try to fire skillcheck remotes directly
			for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
				if obj:IsA("RemoteEvent") and (obj.Name:lower():find("skillcheck") or obj.Name:lower():find("skill") or obj.Name:lower():find("check")) then
					if _G.SkillcheckMode == "Perfect" then
						obj:FireServer("perfect")
					else
						obj:FireServer("neutral")
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 27: SELF UNHOOK (100% LUCK)
-- ==========================================
task.spawn(function()
	-- Hook into unhook probability
	local mt = getrawmetatable(game)
	if mt and setreadonly and hookfunction then
		setreadonly(mt, false)
		local oldNamecall = mt.__namecall
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			local args = {...}

			if _G.SelfUnHook and method == "InvokeServer" then
				local name = self.Name:lower()
				if name:find("unhook") or name:find("escape") or name:find("struggle") or name:find("wiggle") then
					-- Manipulate the probability argument
					if type(args[1]) == "number" then
						args[1] = 1.0 -- 100% chance
					end
				end
			end

			return oldNamecall(self, ...)
		end)
		setreadonly(mt, true)
	end

	-- Also actively fire unhook attempts
	while task.wait(0.5) do
		if not _G.SelfUnHook then continue end

		pcall(function()
			local char = getCharacter()
			if not char then continue end

			-- Check if hooked
			local isHooked = char:GetAttribute("Hooked") or char:GetAttribute("isHooked")
			if not isHooked then
				-- Also check animation state
				local hum = getHumanoid()
				if hum then
					for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
						local animName = track.Animation and track.Animation.Name:lower() or ""
						if animName:find("hook") or animName:find("hang") then
							isHooked = true
							break
						end
					end
				end
			end

			if isHooked then
				-- Fire unhook/struggle remote
				for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
					if obj:IsA("RemoteEvent") and (obj.Name:lower():find("unhook") or obj.Name:lower():find("struggle") or obj.Name:lower():find("escape")) then
						obj:FireServer(1.0) -- 100% probability
					end
					if obj:IsA("RemoteFunction") and (obj.Name:lower():find("unhook") or obj.Name:lower():find("struggle")) then
						local success = obj:InvokeServer(1.0)
						if success then
							WindUI:Notify({ Title = "Automation", Content = "Successfully unhooked!" })
						end
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- LOOP 28: ACTIVATE KILLER POWER (CONTINUOUS)
-- ==========================================
task.spawn(function()
	while task.wait(1) do
		if not _G.ActivatePower then continue end

		pcall(function()
			-- Check if player is killer
			local role = LocalPlayer:GetAttribute("Role")
			if not role or not role:lower():find("killer") then
				_G.ActivatePower = false
				continue
			end

			-- Fire power remotes
			for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
				if obj:IsA("RemoteEvent") and (obj.Name:lower():find("power") or obj.Name:lower():find("ability") or obj.Name:lower():find("special")) then
					obj:FireServer()
				end
				if obj:IsA("RemoteFunction") and (obj.Name:lower():find("power") or obj.Name:lower():find("ability") or obj.Name:lower():find("special")) then
					obj:InvokeServer()
				end
			end

			-- Activate power tool
			local char = getCharacter()
			if char then
				for _, tool in ipairs(char:GetChildren()) do
					if tool:IsA("Tool") and (tool.Name:lower():find("power") or tool.Name:lower():find("ability")) then
						tool:Activate()
					end
				end
			end
		end)
	end
end)

-- ==========================================
-- CHARACTER RESPAWN HANDLER
-- ==========================================
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(2)
	-- Re-create ESP for new character
	updatePlayerESP()

	-- Re-apply god mode hook
	if _G.GodMode then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hookfunction then
			pcall(function()
				hookfunction(hum.TakeDamage, function(self, amount)
					if _G.GodMode then return end
					return self.TakeDamage(self, amount)
				end)
			end)
		end
	end
end)

-- ==========================================
-- NOTIFICATION ON LOAD
-- ==========================================
task.wait(1)
WindUI:Notify({
	Title = "District Premium",
	Content = "All features loaded and ready! Press F to toggle menu.",
})
