--[[
    Violence District - Ultimate Mod Hub
    Created with WindUI Framework
    Author: .ftgs
]]

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(workspace)
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
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
			WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/FajarFnyaFerrary/district/main/dist/main.lua"))()
		end
	end
end

-- ===== CONFIG & STATE =====
local Config = {
	Theme = "Dark",
	VIP = {
		AutoPlay = false,
		AutoDagger = false,
		AutoWiggle = false,
	},
	Survivor = {
		SpeedBoost = false,
		CustomSpeed = 16,
		NoSlowdown = false,
		NoClip = false,
		ForceReset = false,
		SilentActions = false,
		AntiAFallDamage = false,
		GodMode = false,
		InstantHeal = false,
		AntiKnock = false,
		AutoHealAura = false,
	},
	Killer = {
		VeinDrop = false,
		VeinNoGravity = false,
		AntiBlind = false,
		AntiStun = false,
		DoubleDamageGen = false,
		KillerPower = false,
		Teleport = false,
	},
	Visuals = {
		PlayerESP = false,
		GeneratorESP = false,
		PalletESP = false,
		ExitGateESP = false,
		HookESP = false,
		HealthESP = false,
		WindowESP = false,
		DistanceESP = false,
		CustomFOV = false,
		CustomFOVValue = 70,
		Crosshair = false,
		RemoveBlur = false,
		Fullbright = false,
		PotatoMode = false,
	},
	Combat = {
		Aimbot = false,
		AimbotRadius = 50,
		TargetTracer = false,
		LockOnHighlight = false,
		ExpandKillerHitbox = false,
		AutoAttack = false,
	},
	Automation = {
		AutoGenerator = false,
		GeneratorMode = "Perfect",
		BoostAllGen = false,
		InstantEscape = false,
		SelfUnhook = false,
	}
}

-- ===== UTILITIES =====
local function SafePcall(func, ...)
	local ok, result = pcall(func, ...)
	if not ok then
		warn("[VD-Hub] Error:", result)
		return nil
	end
	return result
end

local function GetCharacter()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHumanoid()
	local char = GetCharacter()
	return char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid")
end

local function FindInstance(path)
	local parts = string.split(path, "/")
	local current = Workspace
	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part) or current:WaitForChild(part, 5)
		if not current then return nil end
	end
	return current
end

local function CreateESP(object, color, label)
	if not object or object:IsDescendantOf(Players) then return end
	
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.MaxDistance = 500
	billboardGui.Size = UDim2.new(4, 0, 2, 0)
	billboardGui.Parent = object
	
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundColor3 = color
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 14
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Parent = billboardGui
	textLabel.Text = label or object.Name
	
	return billboardGui
end

local function Notify(title, content, duration)
	duration = duration or 3
	WindUI:Notify({
		Title = title,
		Content = content,
		Duration = duration,
	})
end

-- ===== VIP FEATURES =====
local VIPModule = {}

function VIPModule.AutoPlay()
	if not Config.VIP.AutoPlay then return end
	
	local char = GetCharacter()
	local humanoid = GetHumanoid()
	
	-- Smart AI pathfinding to generators
	local map = FindInstance("Map/Generators")
	if map then
		for _, gen in ipairs(map:GetChildren()) do
			if gen.Name:match("Generator") then
				local distance = (gen.Position - char.PrimaryPart.Position).Magnitude
				if distance < 50 then
					-- Auto repair generator
					pcall(function()
						local repairEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("RepairEvent")
						repairEvent:FireServer(gen:FindFirstChild("GeneratorPoint2") or gen, true)
					end)
				end
			end
		end
	end
end

function VIPModule.AutoDagger()
	if not Config.VIP.AutoDagger then return end
	
	-- Auto parry incoming attacks
	local char = GetCharacter()
	local humanoid = GetHumanoid()
	
	if humanoid.Health > 0 then
		-- Simulate parry action
		pcall(function()
			local daggerRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Parry")
			if daggerRemote then
				daggerRemote:FireServer()
			end
		end)
	end
end

function VIPModule.AutoWiggle()
	if not Config.VIP.AutoWiggle then return end
	
	-- Auto escape from killer's grab
	pcall(function()
		local wiggleRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Wiggle")
		if wiggleRemote then
			for i = 1, 5 do
				wiggleRemote:FireServer()
				task.wait(0.1)
			end
		end
	end)
end

-- ===== SURVIVOR FEATURES =====
local SurvivorModule = {}

function SurvivorModule.SpeedBoost()
	if not Config.Survivor.SpeedBoost then return end
	
	local humanoid = GetHumanoid()
	if humanoid then
		humanoid.WalkSpeed = Config.Survivor.CustomSpeed
	end
end

function SurvivorModule.NoClip()
	if not Config.Survivor.NoClip then return end
	
	local char = GetCharacter()
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

function SurvivorModule.GodMode()
	if not Config.Survivor.GodMode then return end
	
	local humanoid = GetHumanoid()
	if humanoid then
		humanoid:TakeDamage(0)
		humanoid.Health = humanoid.MaxHealth
	end
end

function SurvivorModule.InstantHeal()
	if not Config.Survivor.InstantHeal then return end
	
	local humanoid = GetHumanoid()
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
end

function SurvivorModule.AntiKnock()
	if not Config.Survivor.AntiKnock then return end
	
	local char = GetCharacter()
	local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
	
	if humanoidRootPart then
		humanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0.7, 0.5, 1, 1)
	end
end

function SurvivorModule.AutoHealAura()
	if not Config.Survivor.AutoHealAura then return end
	
	local char = GetCharacter()
	local humanoid = GetHumanoid()
	
	-- Heal nearby teammates
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local distance = (player.Character.PrimaryPart.Position - char.PrimaryPart.Position).Magnitude
			if distance < 20 then
				local targetHumanoid = player.Character:FindFirstChild("Humanoid")
				if targetHumanoid then
					pcall(function()
						local healRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Heal")
						if healRemote then
							healRemote:FireServer(player)
						end
					end)
				end
			end
		end
	end
end

-- ===== KILLER FEATURES =====
local KillerModule = {}

function KillerModule.VeinDrop()
	if not Config.Killer.VeinDrop then return end
	
	-- Drop prediction for spear
	local char = GetCharacter()
	local mouseTarget = LocalPlayer:GetMouse().Target
	
	if mouseTarget and mouseTarget.Parent then
		local targetHumanoid = mouseTarget.Parent:FindFirstChild("Humanoid")
		if targetHumanoid then
			pcall(function()
				local spearRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("SpearAttack")
				if spearRemote then
					spearRemote:FireServer(mouseTarget.Parent, true)
				end
			end)
		end
	end
end

function KillerModule.DoubleDamageGen()
	if not Config.Killer.DoubleDamageGen then return end
	
	pcall(function()
		local map = FindInstance("Map/Generators")
		if map then
			for _, gen in ipairs(map:GetChildren()) do
				if gen.Name:match("Generator") then
					local kickRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("KickGenerator")
					if kickRemote then
						for _ = 1, 2 do
							kickRemote:FireServer(gen)
							task.wait(0.3)
						end
					end
				end
			end
		end
	end)
end

function KillerModule.KillerPower()
	if not Config.Killer.KillerPower then return end
	
	pcall(function()
		local powerRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("ActivatePower")
		if powerRemote then
			powerRemote:FireServer()
		end
	end)
end

-- ===== VISUALS =====
local VisualsModule = {}

function VisualsModule.PlayerESP()
	if not Config.Visuals.PlayerESP then return end
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			local isKiller = char:FindFirstChild("IsKiller") or player:FindFirstChild("Role") and player.Role.Value == "Killer"
			local color = isKiller and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
			
			CreateESP(char.PrimaryPart, color, player.Name .. " [" .. (isKiller and "KILLER" or "SURVIVOR") .. "]")
		end
	end
end

function VisualsModule.GeneratorESP()
	if not Config.Visuals.GeneratorESP then return end
	
	local map = FindInstance("Map/Generators")
	if map then
		for _, gen in ipairs(map:GetChildren()) do
			if gen.Name:match("Generator") then
				CreateESP(gen.PrimaryPart, Color3.fromRGB(255, 255, 0), "GENERATOR")
			end
		end
	end
end

function VisualsModule.ExitGateESP()
	if not Config.Visuals.ExitGateESP then return end
	
	local map = FindInstance("Map/ExitGates")
	if map then
		for _, gate in ipairs(map:GetChildren()) do
			CreateESP(gate.PrimaryPart, Color3.fromRGB(0, 255, 255), "EXIT GATE")
		end
	end
end

function VisualsModule.Crosshair()
	if not Config.Visuals.Crosshair then return end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Crosshair"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	local crosshair = Instance.new("TextLabel")
	crosshair.Name = "CrosshairLabel"
	crosshair.Text = "+"
	crosshair.TextSize = 24
	crosshair.TextColor3 = Color3.fromRGB(255, 0, 0)
	crosshair.BackgroundTransparency = 1
	crosshair.Size = UDim2.new(0, 30, 0, 30)
	crosshair.Position = UDim2.new(0.5, -15, 0.5, -15)
	crosshair.Parent = screenGui
end

function VisualsModule.Fullbright()
	if not Config.Visuals.Fullbright then return end
	
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(255, 255, 255)
	lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	lighting.ClockTime = 12
	
	for _, obj in ipairs(lighting:GetDescendants()) do
		if obj:IsA("Light") then
			obj.Brightness = 10
		end
	end
end

function VisualsModule.CustomFOV()
	if not Config.Visuals.CustomFOV then
		Camera.FieldOfView = 70
		return
	end
	
	Camera.FieldOfView = Config.Visuals.CustomFOVValue
end

-- ===== COMBAT =====
local CombatModule = {}

function CombatModule.Aimbot()
	if not Config.Combat.Aimbot then return end
	
	local closestTarget = nil
	local closestDistance = Config.Combat.AimbotRadius
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local distance = (player.Character.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
			if distance < closestDistance then
				closestTarget = player.Character
				closestDistance = distance
			end
		end
	end
	
	if closestTarget then
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestTarget.PrimaryPart.Position + Vector3.new(0, 2, 0))
	end
end

function CombatModule.TargetTracer()
	if not Config.Combat.TargetTracer then return end
	
	local closestTarget = nil
	local closestDistance = 100
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local distance = (player.Character.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
			if distance < closestDistance then
				closestTarget = player.Character
				closestDistance = distance
			end
		end
	end
	
	if closestTarget then
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "Tracer"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		
		local line = Instance.new("Frame")
		line.Name = "TracerLine"
		line.BorderSizePixel = 0
		line.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		line.Parent = screenGui
	end
end

-- ===== AUTOMATION =====
local AutomationModule = {}

function AutomationModule.AutoGenerator()
	if not Config.Automation.AutoGenerator then return end
	
	pcall(function()
		local genPath = Config.Automation.GeneratorMode == "Perfect" and "neutral" or "neutral"
		
		local skillCheckEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("SkillCheckResultEvent")
		local map = FindInstance("Map/Generators")
		
		if map and skillCheckEvent then
			for _, gen in ipairs(map:GetChildren()) do
				if gen.Name:match("Generator") then
					local genPoint = gen:FindFirstChild("GeneratorPoint2") or gen
					skillCheckEvent:FireServer(genPath, 0, gen, genPoint)
				end
			end
		end
	end)
end

function AutomationModule.InstantEscape()
	if not Config.Automation.InstantEscape then return end
	
	pcall(function()
		local exitGates = FindInstance("Map/ExitGates")
		if exitGates then
			for _, gate in ipairs(exitGates:GetChildren()) do
				local openRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("OpenExit")
				if openRemote then
					openRemote:FireServer(gate)
				end
			end
		end
		
		-- Teleport to finish zone
		local char = GetCharacter()
		local finishZone = FindInstance("Map/FinishZone")
		if finishZone and char.PrimaryPart then
			char:MoveTo(finishZone.Position)
		end
	end)
end

function AutomationModule.SelfUnhook()
	if not Config.Automation.SelfUnhook then return end
	
	pcall(function()
		local unhookRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Unhook")
		if unhookRemote then
			unhookRemote:FireServer()
		end
	end)
end

-- ===== MAIN LOOP =====
local function MainLoop()
	while true do
		task.wait(0.1)
		
		if LocalPlayer and LocalPlayer.Character then
			-- VIP
			SafePcall(VIPModule.AutoPlay)
			SafePcall(VIPModule.AutoDagger)
			
			-- Survivor
			SafePcall(SurvivorModule.SpeedBoost)
			SafePcall(SurvivorModule.GodMode)
			SafePcall(SurvivorModule.AntiKnock)
			SafePcall(SurvivorModule.AutoHealAura)
			
			-- Killer
			SafePcall(KillerModule.VeinDrop)
			SafePcall(KillerModule.DoubleDamageGen)
			
			-- Combat
			SafePcall(CombatModule.Aimbot)
			
			-- Automation
			SafePcall(AutomationModule.AutoGenerator)
		end
	end
end

-- ===== WINDUI SETUP =====
local Window = WindUI:CreateWindow({
	Title = "Violence District Hub",
	Author = "by .ftgs",
	Icon = "solar:gamepad-bold",
	Theme = Config.Theme,
	NewElements = true,
	Transparent = true,
	ToggleKey = Enum.KeyCode.F,
	Acrylic = true,
})

-- VIP TAB
local TabVIP = Window:Tab({
	Title = "👑 VIP",
	Icon = "solar:crown-bold",
})

TabVIP:Section({ Title = "Automatic Features" })
TabVIP:Toggle({
	Title = "Auto Play (Smart AI)",
	Value = Config.VIP.AutoPlay,
	Callback = function(v) Config.VIP.AutoPlay = v; Notify("Auto Play", v and "Enabled" or "Disabled") end,
})

TabVIP:Toggle({
	Title = "Auto Dagger (Parry)",
	Value = Config.VIP.AutoDagger,
	Callback = function(v) Config.VIP.AutoDagger = v; Notify("Auto Dagger", v and "Enabled" or "Disabled") end,
})

TabVIP:Toggle({
	Title = "Auto Wiggle Master",
	Value = Config.VIP.AutoWiggle,
	Callback = function(v) Config.VIP.AutoWiggle = v; Notify("Auto Wiggle", v and "Enabled" or "Disabled") end,
})

-- SURVIVOR TAB
local TabSurvivor = Window:Tab({
	Title = "🛡️ SURVIVOR",
	Icon = "solar:shield-bold",
})

TabSurvivor:Section({ Title = "Movement" })
TabSurvivor:Toggle({
	Title = "Speed Boost",
	Value = Config.Survivor.SpeedBoost,
	Callback = function(v) Config.Survivor.SpeedBoost = v; Notify("Speed Boost", v and "Enabled" or "Disabled") end,
})

TabSurvivor:Slider({
	Title = "Custom Speed",
	Step = 1,
	Value = {
		Min = 16,
		Max = 100,
		Default = Config.Survivor.CustomSpeed,
	},
	Callback = function(v) Config.Survivor.CustomSpeed = v end,
})

TabSurvivor:Toggle({
	Title = "No Slowdown",
	Value = Config.Survivor.NoSlowdown,
	Callback = function(v) Config.Survivor.NoSlowdown = v; Notify("No Slowdown", v and "Enabled" or "Disabled") end,
})

TabSurvivor:Toggle({
	Title = "No Clip",
	Value = Config.Survivor.NoClip,
	Callback = function(v) Config.Survivor.NoClip = v; Notify("No Clip", v and "Enabled" or "Disabled") end,
})

TabSurvivor:Section({ Title = "Health & Defense" })
TabSurvivor:Toggle({
	Title = "God Mode",
	Value = Config.Survivor.GodMode,
	Callback = function(v) Config.Survivor.GodMode = v; Notify("God Mode", v and "Enabled" or "Disabled") end,
})

TabSurvivor:Toggle({
	Title = "Instant Heal",
	Value = Config.Survivor.InstantHeal,
	Callback = function(v) Config.Survivor.InstantHeal = v; Notify("Instant Heal", v and "Enabled" or "Disabled") end,
})

TabSurvivor:Toggle({
	Title = "Anti Knock",
	Value = Config.Survivor.AntiKnock,
	Callback = function(v) Config.Survivor.AntiKnock = v; Notify("Anti Knock", v and "Enabled" or "Disabled") end,
})

TabSurvivor:Toggle({
	Title = "Auto Heal Aura",
	Value = Config.Survivor.AutoHealAura,
	Callback = function(v) Config.Survivor.AutoHealAura = v; Notify("Auto Heal Aura", v and "Enabled" or "Disabled") end,
})

-- KILLER TAB
local TabKiller = Window:Tab({
	Title = "🔪 KILLER",
	Icon = "solar:shield-minimalistic-bold",
})

TabKiller:Section({ Title = "Vein Powers" })
TabKiller:Toggle({
	Title = "Vein Drop Prediction",
	Value = Config.Killer.VeinDrop,
	Callback = function(v) Config.Killer.VeinDrop = v; Notify("Vein Drop", v and "Enabled" or "Disabled") end,
})

TabKiller:Toggle({
	Title = "Vein No Gravity",
	Value = Config.Killer.VeinNoGravity,
	Callback = function(v) Config.Killer.VeinNoGravity = v; Notify("Vein No Gravity", v and "Enabled" or "Disabled") end,
})

TabKiller:Section({ Title = "Killer Abilities" })
TabKiller:Toggle({
	Title = "Anti Blind",
	Value = Config.Killer.AntiBlind,
	Callback = function(v) Config.Killer.AntiBlind = v; Notify("Anti Blind", v and "Enabled" or "Disabled") end,
})

TabKiller:Toggle({
	Title = "Anti Stun",
	Value = Config.Killer.AntiStun,
	Callback = function(v) Config.Killer.AntiStun = v; Notify("Anti Stun", v and "Enabled" or "Disabled") end,
})

TabKiller:Toggle({
	Title = "Double Damage Generator",
	Value = Config.Killer.DoubleDamageGen,
	Callback = function(v) Config.Killer.DoubleDamageGen = v; Notify("Double Damage", v and "Enabled" or "Disabled") end,
})

TabKiller:Toggle({
	Title = "Activate Killer Power",
	Value = Config.Killer.KillerPower,
	Callback = function(v) Config.Killer.KillerPower = v; Notify("Killer Power", v and "Enabled" or "Disabled") end,
})

-- VISUALS TAB
local TabVisuals = Window:Tab({
	Title = "👁️ VISUALS",
	Icon = "solar:eye-bold",
})

TabVisuals:Section({ Title = "ESP" })
TabVisuals:Toggle({
	Title = "Player ESP",
	Value = Config.Visuals.PlayerESP,
	Callback = function(v) Config.Visuals.PlayerESP = v; Notify("Player ESP", v and "Enabled" or "Disabled") end,
})

TabVisuals:Toggle({
	Title = "Generator ESP",
	Value = Config.Visuals.GeneratorESP,
	Callback = function(v) Config.Visuals.GeneratorESP = v; Notify("Generator ESP", v and "Enabled" or "Disabled") end,
})

TabVisuals:Toggle({
	Title = "Exit Gate ESP",
	Value = Config.Visuals.ExitGateESP,
	Callback = function(v) Config.Visuals.ExitGateESP = v; Notify("Exit Gate ESP", v and "Enabled" or "Disabled") end,
})

TabVisuals:Section({ Title = "Display" })
TabVisuals:Toggle({
	Title = "Show Crosshair",
	Value = Config.Visuals.Crosshair,
	Callback = function(v) Config.Visuals.Crosshair = v; Notify("Crosshair", v and "Enabled" or "Disabled") end,
})

TabVisuals:Toggle({
	Title = "Custom FOV",
	Value = Config.Visuals.CustomFOV,
	Callback = function(v) Config.Visuals.CustomFOV = v; VisualsModule.CustomFOV(); Notify("Custom FOV", v and "Enabled" or "Disabled") end,
})

TabVisuals:Slider({
	Title = "FOV Value",
	Step = 5,
	Value = {
		Min = 40,
		Max = 120,
		Default = Config.Visuals.CustomFOVValue,
	},
	Callback = function(v) Config.Visuals.CustomFOVValue = v; VisualsModule.CustomFOV() end,
})

TabVisuals:Toggle({
	Title = "Force Fullbright",
	Value = Config.Visuals.Fullbright,
	Callback = function(v) Config.Visuals.Fullbright = v; VisualsModule.Fullbright(); Notify("Fullbright", v and "Enabled" or "Disabled") end,
})

-- COMBAT TAB
local TabCombat = Window:Tab({
	Title = "⚔️ COMBAT",
	Icon = "solar:sword-bold",
})

TabCombat:Section({ Title = "Targeting System" })
TabCombat:Toggle({
	Title = "Enable Aimbot",
	Value = Config.Combat.Aimbot,
	Callback = function(v) Config.Combat.Aimbot = v; Notify("Aimbot", v and "Enabled" or "Disabled") end,
})

TabCombat:Slider({
	Title = "Aim Radius",
	Step = 10,
	Value = {
		Min = 20,
		Max = 200,
		Default = Config.Combat.AimbotRadius,
	},
	Callback = function(v) Config.Combat.AimbotRadius = v end,
})

TabCombat:Toggle({
	Title = "Show Target Tracer",
	Value = Config.Combat.TargetTracer,
	Callback = function(v) Config.Combat.TargetTracer = v; Notify("Target Tracer", v and "Enabled" or "Disabled") end,
})

-- AUTOMATION TAB
local TabAuto = Window:Tab({
	Title = "⚙️ AUTOMATION",
	Icon = "solar:settings-bold",
})

TabAuto:Section({ Title = "Generator" })
TabAuto:Toggle({
	Title = "Auto Generator",
	Value = Config.Automation.AutoGenerator,
	Callback = function(v) Config.Automation.AutoGenerator = v; Notify("Auto Generator", v and "Enabled" or "Disabled") end,
})

TabAuto:Dropdown({
	Title = "Generator Mode",
	Value = Config.Automation.GeneratorMode,
	Values = { "Perfect", "Neutral" },
	Callback = function(v) Config.Automation.GeneratorMode = v end,
})

TabAuto:Section({ Title = "Escape" })
TabAuto:Toggle({
	Title = "Instant Escape (Gate)",
	Value = Config.Automation.InstantEscape,
	Callback = function(v) Config.Automation.InstantEscape = v; Notify("Instant Escape", v and "Enabled" or "Disabled") end,
})

TabAuto:Toggle({
	Title = "Self Unhook",
	Value = Config.Automation.SelfUnhook,
	Callback = function(v) Config.Automation.SelfUnhook = v; Notify("Self Unhook", v and "Enabled" or "Disabled") end,
})

-- SETTINGS TAB
local TabSettings = Window:Tab({
	Title = "⚙️ Settings",
	Icon = "solar:settings-bold",
})

TabSettings:Section({ Title = "Theme" })
local Themes = {}
for name in pairs(WindUI.Themes) do
	table.insert(Themes, name)
end

TabSettings:Dropdown({
	Title = "Select Theme",
	Value = Config.Theme,
	Values = Themes,
	Callback = function(v)
		Config.Theme = v
		WindUI:SetTheme(v)
		Notify("Theme Changed", "Now using " .. v .. " theme")
	end,
})

TabSettings:Section({ Title = "Info" })
TabSettings:Button({
	Title = "Copy Discord",
	Callback = function()
		setclipboard("discord.gg/example")
		Notify("Copied", "Discord link copied to clipboard")
	end,
})

TabSettings:Button({
	Title = "Unload Script",
	Callback = function()
		Window:Destroy()
		Notify("Script", "Unloaded successfully")
	end,
})

-- Start main loop
task.spawn(MainLoop)

Notify("Violence District Hub", "Script loaded successfully!")
print("[VD-Hub] Ready to dominate!")
