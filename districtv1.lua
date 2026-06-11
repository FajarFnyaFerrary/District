--[[
    WindUI - District Script
]]

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
	Title = "District Features",
	Author = "by Fajar",
	Icon = "solar:code-square-bold",
	Theme = ThemeName,
	NewElements = true,
	Transparent = true,
	ToggleKey = Enum.KeyCode.F,
	Acrylic = true,
})

-- =========================================================================
-- || TAB: COMBAT & MECHANICS ||
-- =========================================================================
local TabCombat = Window:Tab({ Title = "Combat & Mechanics", Icon = "solar:danger-triangle-bold" })

TabCombat:Section({ Title = "Generators" })
TabCombat:Toggle({ Title = "Anti-Fail Generator", Value = false, Callback = function(state) end })
TabCombat:Toggle({ Title = "Auto Perfect Skill Check", Value = false, Callback = function(state) end })

TabCombat:Section({ Title = "Mechanics" })
local GroupMechanics = TabCombat:Group()
GroupMechanics:Toggle({ Title = "No Parry Cooldown", Value = false, Callback = function(state) end })
GroupMechanics:Toggle({ Title = "Anti Blind", Value = false, Callback = function(state) end })
GroupMechanics:Toggle({ Title = "Anti Stun", Value = false, Callback = function(state) end })
GroupMechanics:Button({ Title = "Sacrifice Self (OP)", Callback = function() end })
GroupMechanics:Button({ Title = "Instant Escape (OP)", Callback = function() end })

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
-- || TAB: VISUALS & ESP ||
-- =========================================================================
local TabVisuals = Window:Tab({ Title = "Visuals & ESP", Icon = "solar:eye-bold" })

TabVisuals:Select() -- Set tab Visuals sebagai halaman pertama yang terbuka

TabVisuals:Section({ Title = "Target ESP" })
local GroupESP = TabVisuals:Group()
GroupESP:Toggle({ Title = "Player ESP", Value = false, Callback = function(state) end })
GroupESP:Toggle({ Title = "Enemy ESP", Value = false, Callback = function(state) end }) -- Added Enemy ESP
GroupESP:Toggle({ Title = "Generator ESP", Value = false, Callback = function(state) end })
GroupESP:Toggle({ Title = "Hook ESP", Value = false, Callback = function(state) end })
GroupESP:Toggle({ Title = "Pallet ESP", Value = false, Callback = function(state) end })
GroupESP:Toggle({ Title = "Gate ESP", Value = false, Callback = function(state) end })
GroupESP:Toggle({ Title = "Vault ESP", Value = false, Callback = function(state) end })

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
TabVisuals:Dropdown({ Title = "Highlight Mode", Values = {"AlwaysOnTop", "Occluded"}, Value = "AlwaysOnTop", Callback = function(mode) end })
TabVisuals:Toggle({ Title = "Highlight Fill", Value = false, Callback = function(state) end })
TabVisuals:Toggle({ Title = "Highlight Outline", Value = false, Callback = function(state) end })
TabVisuals:Slider({ Title = "Max Highlights", Step = 1, Value = { Min = 1, Max = 50, Default = 15 }, Callback = function(value) end })
TabVisuals:Toggle({ Title = "Use Custom Fill Color", Value = false, Callback = function(state) end })

-- =========================================================================
-- || TAB: PLAYER MODS ||
-- =========================================================================
local TabPlayer = Window:Tab({ Title = "Player Mods", Icon = "solar:user-bold" })

TabPlayer:Section({ Title = "Movement" })
TabPlayer:Toggle({ Title = "Speed Boost (Keybind)", Value = false, Callback = function(state) end })
TabPlayer:Toggle({ Title = "Speed Attribute Method", Value = false, Callback = function(state) end })
TabPlayer:Slider({ Title = "Speed Input", Step = 1, Value = { Min = 16, Max = 200, Default = 50 }, Callback = function(value) end })
TabPlayer:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 300, Default = 50 }, Callback = function(value) end })
TabPlayer:Slider({ Title = "Hip Height", Step = 0.5, Value = { Min = 2, Max = 20, Default = 2 }, Callback = function(value) end })

TabPlayer:Section({ Title = "Utilities" })
local GroupMods = TabPlayer:Group()
GroupMods:Toggle({ Title = "Noclip", Value = false, Callback = function(state) end })
GroupMods:Toggle({ Title = "Velocity Fly", Value = false, Callback = function(state) end })
GroupMods:Toggle({ Title = "CFrame Fly", Value = false, Callback = function(state) end })
GroupMods:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(state) end })
GroupMods:Toggle({ Title = "Freeze Self", Value = false, Callback = function(state) end })
GroupMods:Toggle({ Title = "Enable Shift Lock", Value = false, Callback = function(state) end })

TabPlayer:Section({ Title = "Fling Methods" })
TabPlayer:Toggle({ Title = "Fling", Value = false, Callback = function(state) end })
TabPlayer:Toggle({ Title = "Fling All", Value = false, Callback = function(state) end })
TabPlayer:Slider({ Title = "Fling Strength", Step = 50, Value = { Min = 100, Max = 5000, Default = 1000 }, Callback = function(value) end })
TabPlayer:Toggle({ Title = "Fling All Whitelist", Value = false, Callback = function(state) end })

-- =========================================================================
-- || TAB: WORLD & AMBIENCE ||
-- =========================================================================
local TabWorld = Window:Tab({ Title = "World & Emotes", Icon = "solar:earth-bold" })

TabWorld:Section({ Title = "Emotes" })
TabWorld:Dropdown({ Title = "Emote Dropdown", Values = {"Dance", "Laugh", "Wave", "Point"}, Value = "Dance", Callback = function(emote) end })
TabWorld:Button({ Title = "Play Emote", Callback = function() end })

TabWorld:Section({ Title = "Shaders & Ambience" })
TabWorld:Toggle({ Title = "Ambience", Value = false, Callback = function(state) end })
TabWorld:Toggle({ Title = "Force Time", Value = false, Callback = function(state) end })
TabWorld:Slider({ Title = "Time Slider", Step = 1, Value = { Min = 0, Max = 24, Default = 12 }, Callback = function(value) end })
TabWorld:Toggle({ Title = "Custom Saturation", Value = false, Callback = function(state) end })
TabWorld:Slider({ Title = "Saturation Density", Step = 0.1, Value = { Min = -1, Max = 2, Default = 0 }, Callback = function(value) end })

TabWorld:Section({ Title = "Environment Modification" })
TabWorld:Toggle({ Title = "Skybox Changer", Value = false, Callback = function(state) end })
TabWorld:Dropdown({ Title = "Skybox Dropdown", Values = {"Night", "Vaporwave", "Space", "Blood"}, Value = "Night", Callback = function(skybox) end })
TabWorld:Toggle({ Title = "Body Modifier", Value = false, Callback = function(state) end })
TabWorld:Dropdown({ Title = "Material Dropdown", Values = {"Plastic", "Neon", "ForceField", "Glass"}, Value = "Neon", Callback = function(material) end })
TabWorld:Toggle({ Title = "Material Color Override", Value = false, Callback = function(state) end })

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
	Callback = function(v)
		Window:ToggleTransparency(v)
	end,
})

TabSettings:Button({
	Title = "Unload UI",
	Icon = "solar:logout-3-bold",
	Callback = function()
		Window:Destroy()
	end,
})
