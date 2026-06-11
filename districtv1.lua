--[[
    District Script - Fixed Layout & Functional Base
    Creator: Fajar
]]

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Lighting = cloneref(game:GetService("Lighting"))

local LocalPlayer = Players.LocalPlayer
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
	Title = "District - " .. ThemeName,
	Author = "by Fajar",
	Icon = "solar:code-square-bold",
	Theme = ThemeName,
	NewElements = true,
	Transparent = true,
	ToggleKey = Enum.KeyCode.F,
	Acrylic = true,
})

-- =========================================================================
-- || CONFIGURATION SYSTEM ||
-- =========================================================================
local Config = {
	-- Movement
	SpeedBoost = false,
	SpeedMethod = "Humanoid",
	SpeedValue = 50,
	JumpPower = 50,
	HipHeight = 2,
	Noclip = false,
	InfJump = false,
	-- Visuals
	PlayerESP = false,
	EnemyESP = false,
	HighlightMode = "AlwaysOnTop",
	MaxHighlights = 15,
}

-- =========================================================================
-- || FUNCTIONAL CORE LOGIC (PLAYER MODS & UTILITIES) ||
-- =========================================================================

-- Loop handling for Speed, JumpPower, and HipHeight
RunService.Heartbeat:Connect(function()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		if Config.SpeedBoost then
			if Config.SpeedMethod == "Attributes" then
				char:SetAttribute("Speed", Config.SpeedValue)
			else
				hum.WalkSpeed = Config.SpeedValue
			end
		end
		-- Only apply custom jump power/hip height if adjusted
		if Config.JumpPower ~= 50 then hum.JumpPower = Config.JumpPower end
		if Config.HipHeight ~= 2 then hum.HipHeight = Config.HipHeight end
	end
end)

-- Noclip Functional Logic
RunService.Stepped:Connect(function()
	if Config.Noclip and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end)

-- Infinite Jump Functional Logic
UserInputService.JumpRequest:Connect(function()
	if Config.InfJump and LocalPlayer.Character then
		local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- Universal Highlight ESP Framework Base
local function applyHighlight(player, typeBox)
	local function create()
		if player == LocalPlayer then return end
		local char = player.Character
		if char and not char:FindFirstChild("DistrictHighlight") then
			local highlight = Instance.new("Highlight")
			highlight.Name = "DistrictHighlight"
			highlight.FillColor = (typeBox == "Enemy") and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 50)
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.DepthMode = Enum.HighlightDepthMode[Config.HighlightMode]
			highlight.Parent = char
		end
	end
	create()
	player.CharacterAdded:Connect(create)
end

-- =========================================================================
-- || TAB: COMBAT & MECHANICS ||
-- =========================================================================
local TabCombat = Window:Tab({ Title = "Combat & Mechanics", Icon = "solar:danger-triangle-bold" })

TabCombat:Section({ Title = "Generators" })
TabCombat:Toggle({ Title = "Anti-Fail Generator", Value = false, Callback = function(state) end })
TabCombat:Toggle({ Title = "Auto Perfect Skill Check", Value = false, Callback = function(state) end })

TabCombat:Section({ Title = "Mechanics Actions" }) -- Changed layout structure to stack cleanly
TabCombat:Toggle({ Title = "No Parry Cooldown", Value = false, Callback = function(state) end })
TabCombat:Toggle({ Title = "Anti Blind", Value = false, Callback = function(state) end })
TabCombat:Toggle({ Title = "Anti Stun", Value = false, Callback = function(state) end })
TabCombat:Button({ Title = "Sacrifice Self (OP)", Callback = function() end })
TabCombat:Button({ Title = "Instant Escape (OP)", Callback = function() end })

TabCombat:Section({ Title = "Killer" })
TabCombat:Dropdown({ Title = "Auto Slash Mode", Values = {"Off", "Legit", "Rage"}, Value = "Off", Callback = function(mode) end })
TabCombat:Toggle({ Title = "Infinite Lunge", Value = false, Callback = function(state) end })

TabCombat:Section({ Title = "Survivor" })
TabCombat:Toggle({ Title = "Auto Parry", Value = false, Callback = function(state) end })
TabCombat:Toggle({ Title = "Auto Escape", Value = false, Callback = function(state) end })
TabCombat:Toggle({ Title = "No Fall", Value = false, Callback = function(state) end })
TabCombat:Toggle({ Title = "No Turn Speed Limit", Value = false, Callback = function(state) end })
TabCombat:Button({ Title = "Gate Tool", Callback = function() end })

-- =========================================================================
-- || TAB: VISUALS & ESP (FIXED UNREGULATED LAYOUT) ||
-- =========================================================================
local TabVisuals = Window:Tab({ Title = "Visuals & ESP", Icon = "solar:eye-bold" })
TabVisuals:Select()

TabVisuals:Section({ Title = "Target ESP" })
-- FIX: Removed GroupESP to allow elements to scale vertically down and line up perfectly.
TabVisuals:Toggle({ Title = "Player ESP", Value = Config.PlayerESP, Callback = function(state) 
	Config.PlayerESP = state
	if state then
		for _, p in pairs(Players:GetPlayers()) do applyHighlight(p, "Player") end
	else
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("DistrictHighlight") then
				p.Character.DistrictHighlight:Destroy()
			end
		end
	end
end })

TabVisuals:Toggle({ Title = "Enemy ESP", Value = Config.EnemyESP, Callback = function(state) 
	Config.EnemyESP = state
	if state then
		for _, p in pairs(Players:GetPlayers()) do applyHighlight(p, "Enemy") end
	else
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("DistrictHighlight") then
				p.Character.DistrictHighlight:Destroy()
			end
		end
	end
end })

TabVisuals:Toggle({ Title = "Generator ESP", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Hook ESP", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Pallet ESP", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Gate ESP", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Vault ESP", Value = false, Callback = function(state) end })

TabVisuals:Section({ Title = "ESP Settings" })
TabVisuals:Toggle({ Title = "2D Boxes", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "3D Boxes", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Show Names", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Show Distance", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Tracers", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Show Weapon", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Health Bars", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Health Text", Value = false, Callback = function(state) end })

TabVisuals:Section({ Title = "Highlights Settings" })
TabVisuals:Toggle({ Title = "Highlights", Value = false, Callback = function(state) end })
TabVisuals:Slider({ Title = "Highlight Distance", Step = 10, Value = { Min = 0, Max = 1000, Default = 500 }, Callback = function(value) end })
TabVisuals:Dropdown({ Title = "Highlight Mode", Values = {"AlwaysOnTop", "Occluded"}, Value = Config.HighlightMode, Callback = function(mode) end })
TabVisuals:Toggle({ Title = "Highlight Fill", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Highlight Outline", Value = false, Callback = function(state) end })
TabVisuals:Slider({ Title = "Max Highlights", Step = 1, Value = { Min = 1, Max = 50, Default = Config.MaxHighlights }, Callback = function(value) Config.MaxHighlights = value end })
TabVisuals:Toggle({ Title = "Use Custom Fill Color", Value = false, Callback = function(state) end })

-- =========================================================================
-- || TAB: PLAYER MODS ||
-- =========================================================================
local TabPlayer = Window:Tab({ Title = "Player Mods", Icon = "solar:user-bold" })

TabPlayer:Section({ Title = "Movement" })
TabPlayer:Toggle({ Title = "Speed Boost", Value = Config.SpeedBoost, Callback = function(state) Config.SpeedBoost = state end })
TabPlayer:Dropdown({ Title = "Speed Method", Values = {"Humanoid", "Attributes"}, Value = Config.SpeedMethod, Callback = function(v) Config.SpeedMethod = v end })
TabPlayer:Slider({ Title = "Speed Input", Step = 1, Value = { Min = 16, Max = 200, Default = Config.SpeedValue }, Callback = function(value) Config.SpeedValue = value end })
TabPlayer:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 300, Default = Config.JumpPower }, Callback = function(value) Config.JumpPower = value end })
TabPlayer:Slider({ Title = "Hip Height", Step = 0.5, Value = { Min = 0, Max = 20, Default = Config.HipHeight }, Callback = function(value) Config.HipHeight = value end })

TabPlayer:Section({ Title = "Utilities" })
TabPlayer:Toggle({ Title = "Noclip", Value = Config.Noclip, Callback = function(state) Config.Noclip = state end })
TabPlayer:Toggle({ Title = "Infinite Jump", Value = Config.InfJump, Callback = function(state) Config.InfJump = state end })
TabPlayer:Toggle({ Title = "Freeze Self", Value = false, Callback = function(state) 
	local anchor = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if anchor then anchor.Anchored = state end
end })

TabPlayer:Section({ Title = "Fling Methods" })
TabPlayer:Toggle({ Title = "Fling", Value = false, Callback = function(state) end })
TabPlayer:Toggle({ Title = "Fling All", Value = false, Callback = function(state) end })

-- =========================================================================
-- || TAB: WORLD & AMBIENCE ||
-- =========================================================================
local TabWorld = Window:Tab({ Title = "World & Emotes", Icon = "solar:earth-bold" })

TabWorld:Section({ Title = "Shaders & Ambience" })
TabWorld:Toggle({ Title = "Force Time", Value = false, Callback = function(state) end })
TabWorld:Slider({ Title = "Time Slider", Step = 1, Value = { Min = 0, Max = 24, Default = 12 }, Callback = function(value) 
	Lighting.ClockTime = value
end })

-- =========================================================================
-- || TAB: SETTINGS & CONFIGURATION ||
-- =========================================================================
local TabSettings = Window:Tab({ Title = "Settings", Icon = "solar:settings-bold" })

local Themes = {}
for _ThemeName, _ in pairs(WindUI.Themes) do
	table.insert(Themes, _ThemeName)
end

TabSettings:Section({ Title = "UI Settings" })
TabSettings:Dropdown({
	Title = "Select Theme",
	Value = ThemeName,
	Values = Themes,
	Callback = function(value)
		ThemeName = value
		Window:SetTitle("District - " .. ThemeName)
		WindUI:SetTheme(ThemeName)
	end,
})

TabSettings:Toggle({
	Title = "Toggle Window Transparency",
	Value = Window.Transparent,
	Callback = function(v) Window:ToggleTransparency(v) end,
})

TabSettings:Button({
	Title = "Unload UI",
	Icon = "solar:logout-3-bold",
	Callback = function() Window:Destroy() end,
})
