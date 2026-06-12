--[[
    District.lua - Integrated Premium Menu
    UI Framework: WindUI
]]

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
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
			WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/FajarFnyaFerrary/District/main/dist/main.lua"))()
		end
	end
end

local ThemeName = "Dark"

local Window = WindUI:CreateWindow({
	Title = "District Premium Menu",
	Author = "by .ftgs & Fajar",
	Icon = "solar:crown-bold",
	Theme = ThemeName,
	NewElements = true,
	Transparent = true,
	ToggleKey = Enum.KeyCode.F,
	Acrylic = true,
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
			task.spawn(function()
				while _G.AutoPlay do
					task.wait(1)
					-- Logika pencarian Generator / Gerbang & deteksi jarak Killer di sini
				end
			end)
		end
	end,
})

TabVIP:Toggle({
	Title = "Auto Dagger (Auto Parry)",
	Value = false,
	Callback = function(v)
		_G.AutoParry = v
	end,
})

TabVIP:Toggle({
	Title = "Auto-Wiggle Master",
	Value = false,
	Callback = function(v)
		_G.AutoWiggle = v
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
		-- Contoh aplikasi langsung ke Karakter
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
	end,
})

TabSurvivor:Button({
	Title = "Instant Heal (Self)",
	Justify = "Center",
	Icon = "solar:heart-bold",
	Size = "Small",
	Callback = function()
		WindUI:Notify({ Title = "Survivor", Content = "Instant Heal Activated!" })
		-- Selesaikan trigger instant heal di sini
	end,
})

TabSurvivor:Button({
	Title = "Force Reset State (Anti-Stuck)",
	Justify = "Center",
	Icon = "solar:restart-bold",
	Size = "Small",
	Callback = function()
		pcall(function()
			if LocalPlayer.Character then
				LocalPlayer.Character:ClearCharacterAppearance()
				-- Atau manipulasi state animasi macet di sini
			end
		end)
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
	end,
})

TabKiller:Toggle({
	Title = "Vein Spear: No Gravity",
	Value = false,
	Callback = function(v)
		_G.SpearNoGravity = v
	end,
})

TabKiller:Section({ Title = "Immunities & Mechanics" })

TabKiller:Toggle({
	Title = "Anti-Blind (Fog/Flashlight)",
	Value = false,
	Callback = function(v)
		_G.AntiBlind = v
	end,
})

TabKiller:Toggle({
	Title = "Anti-Stun (Pallet Slam)",
	Value = false,
	Callback = function(v)
		_G.AntiStun = v
	end,
})

TabKiller:Toggle({
	Title = "Double Damage Generator",
	Value = false,
	Callback = function(v)
		_G.DoubleDamageGen = v
	end,
})

TabKiller:Button({
	Title = "Activate Killer Power Instantly",
	Justify = "Center",
	Icon = "solar:bolt-bold",
	Size = "Small",
	Callback = function()
		_G.ActivatePower = true
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
	end,
})

TabVisuals:Toggle({
	Title = "Object ESP (Gen, Pallet, Gate, Hook)",
	Value = false,
	Callback = function(v)
		_G.ObjectESP = v
	end,
})

TabVisuals:Section({ Title = "Environment & Camera Settings" })

TabVisuals:Toggle({
	Title = "Enable Custom FOV",
	Value = false,
	Callback = function(v)
		_G.CustomFOV = v
	end,
})

TabVisuals:Slider({
	Title = "Field Of View",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 70, Max = 120, Default = 70 },
	Callback = function(value)
		if _G.CustomFOV then
			workspace.CurrentCamera.FieldOfView = value
		end
	end,
})

TabVisuals:Toggle({
	Title = "Show Custom Crosshair",
	Value = false,
	Callback = function(v)
		_G.ShowCrosshair = v
	end,
})

TabVisuals:Toggle({
	Title = "Remove Blur & Bloom",
	Value = false,
	Callback = function(v)
		_G.RemoveBlurBloom = v
	end,
})

TabVisuals:Toggle({
	Title = "Force Fullbright",
	Value = false,
	Callback = function(v)
		_G.Fullbright = v
	end,
})

TabVisuals:Toggle({
	Title = "Extreme Potato Mode (FPS Boost)",
	Value = false,
	Callback = function(v)
		_G.PotatoMode = v
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
	end,
})

TabCombat:Toggle({
	Title = "Show Target Tracer (Red Laser)",
	Value = false,
	Callback = function(v)
		_G.TargetTracer = v
	end,
})

TabCombat:Toggle({
	Title = "Lock-On Highlight (Chams/Glow)",
	Value = false,
	Callback = function(v)
		_G.LockOnHighlight = v
	end,
})

TabCombat:Section({ Title = "Melee Modifications" })

TabCombat:Toggle({
	Title = "FPP / TPP Viewport Toggle",
	Value = false,
	Callback = function(v)
		_G.FppTppToggle = v
	end,
})

TabCombat:Toggle({
	Title = "Expand Killer Hitbox",
	Value = false,
	Callback = function(v)
		_G.ExpandHitbox = v
	end,
})

TabCombat:Toggle({
	Title = "Auto Attack Range Loop",
	Value = false,
	Callback = function(v)
		_G.AutoAttack = v
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
		WindUI:Notify({ Title = "Exploit", Content = "Injecting progress to all generators..." })
	end,
})

TabAutomation:Button({
	Title = "Instant Escape (Gate Win)",
	Justify = "Center",
	Icon = "solar:logout-bold",
	Size = "Small",
	Callback = function()
		WindUI:Notify({ Title = "Exploit", Content = "Teleporting to escape zone..." })
	end,
})

-- ==========================================
-- 🛠️ TAB 7: SETTINGS & THEMES (DIREKTRIP ASLI)
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
local Remote = ReplicatedStorage:WaitForChild("GetPullRequestData")

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
		if PRNumber then
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
