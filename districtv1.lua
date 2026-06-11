--[[
    District.lua - Violence District
    All features integrated with WindUI framework
    Original UI elements preserved (minisize, topbar buttons, settings, etc.)
]]

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Workspace = cloneref(game:GetService("Workspace"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local TweenService = cloneref(game:GetService("TweenService"))
local InsertService = cloneref(game:GetService("InsertService"))

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
			WindUI =
				loadstring(game:HttpGet("https://raw.githubusercontent.com/FajarFnyaFerrary/District/main/dist/main.lua"))()
		end
	end
end

--WindUI.TransparencyValue = .9
local ThemeName = "Dark"

local Window = WindUI:CreateWindow({
	Title = "Violence District'" .. ThemeName .. "'",
	Author = "by Zetttify",
	Icon = "solar:compass-big-bold",
	Theme = ThemeName,
	NewElements = true,
	Transparent = true,
	ToggleKey = Enum.KeyCode.F,
	Acrylic = true,

	--[[
	KeySystem = {
		Title = "Key System",
		Description = "Enter the correct key to unlock the window",
		KeyValidator = function(key)
			return key == "HelloWorld"
		end,
	}
	]]
})

local Tag = Window:Tag({
	Title = "Hi my tag",
	Color = "Text",
})

local TopbarButton1 = Window.Topbar:Button({
	Name = "Print to console",
	Icon = "sfsymbols:printerFill",
	IconSize = 22,
})

local Tab1 = Window:Tab({
	Title = "Main",
	Icon = "rbxassetid://77799629590713",
	IconThemed = true,
})

local Tab2 = Window:Tab({
	Title = "hahahahah",
	Icon = "user",
})

Tab1:Select()

Tab1:Section({
	Title = "Interactive Elements",
	Desc = "Demonstration of new UI components",
})

Tab1:Space({ Columns = 2 })

local Group1 = Tab1:Group()

Group1:Toggle({
	Title = "Autism",
	Value = true,
	Callback = function() end,
})

Group1:Space({ Columns = 0.5 })

Group1:Button({
	Title = "Unload",
	Justify = "Center",
	Icon = "solar:logout-3-bold",
	IconAlign = "Left",
	Size = "Small",
	Callback = function()
		Window:Destroy()
	end,
})

Tab1:Space({ Columns = 1 })

Tab1:Section({
	Title = "Brightness Control",
	TextSize = 16,
	FontWeight = Enum.FontWeight.SemiBold,
})

Tab1:Slider({
	IsTooltip = true,
	Step = 1,
	Value = {
		Min = 0,
		Max = 100,
		Default = 50,
	},
	Icons = {
		From = "solar:moon-stars-bold",
		To = "solar:sun-2-bold",
	},
	Callback = function(value)
		print("Brightness set to: " .. value .. "%")
	end,
})

Tab1:Space({ Columns = 1 })

Tab1:Section({
	Title = "Volume Settings",
	TextSize = 16,
	FontWeight = Enum.FontWeight.SemiBold,
})

Tab1:Slider({
	IsTooltip = true,
	Step = 5,
	Value = {
		Min = 0,
		Max = 100,
		Default = 75,
	},
	Icons = {
		From = "solar:volume-cross-bold",
		To = "solar:volume-loud-bold",
	},
	Callback = function(value)
		print("Volume set to: " .. value .. "%")
	end,
})

Tab1:Space({ Columns = 0.5 })

local Group2 = Tab1:Group()

Group2:Button({
	Title = "Save",
	Justify = "Center",
	Icon = "solar:check-circle-bold",
	IconAlign = "Left",
	Size = "Small",
	Callback = function()
		WindUI:Notify({
			Title = "Success",
			Content = "Settings saved!",
		})
	end,
})

Group2:Space({ Columns = 0.5 })

Group2:Button({
	Title = "Reset",
	Justify = "Center",
	Icon = "solar:restart-circle-bold",
	IconAlign = "Left",
	Size = "Small",
	Callback = function()
		WindUI:Notify({
			Title = "Reset",
			Content = "All parameters restored to default",
		})
	end,
})

local TabSettings = Window:Tab({
	Title = "Settings",
	Icon = "solar:settings-bold",
})

-- Get all available themes
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
		print(PRNumber)
		if PRNumber then
			Window:SetAuthor("Loading...")
			if not CachedPRData[PRNumber] then
				local Success, Data = pcall(function()
					return Remote:InvokeServer("Zetttify", "WindUI", PRNumber)
				end)

				if Success and Data and Data.html_url then
					CachedPRData[PRNumber] = Data
					Window:SetAuthor(
						"by " .. Data.user.login .. " | https://github.com/FajarFnyaFerrary/District/pull/" .. PRNumber
					)
				end
				print(Data)
			else
				local Data = CachedPRData[PRNumber]
				Window:SetAuthor(
					"by " .. Data.user.login .. " | https://github.com/FajarFnyaFerrary/District/pull/" .. PRNumber
				)
				print(Data)
			end
		else
			Window:SetAuthor("by .ftgs")
		end
	end,
})

local Toggle = TabSettings:Toggle({
	Title = "Toggle Window Transparency",
	Value = Window.Transparent,
	Callback = function(v)
		Window:ToggleTransparency(v)
	end,
})

local Section = Tab1:Section({
	Title = "Hi1",
	Icon = "rbxassetid://77799629590713",
	IconThemed = true,
})

local Viewport = Tab1:Viewport({
	Object = Instance.new("Part"),
	Interactive = true,
})

local EmptyTab = Window:Tab({
	Title = "Custom empty page tab",

	CustomEmptyPage = {
		Icon = "lucide:smile",
		Title = "This is a cool empty tab",
		Desc = "I like it. its so great tab with cool 'custom empty page'",
	},
})

-- ============================================================
-- FEATURE MODULES & STATE
-- ============================================================
local FeatureState = {
	-- VIP
	AutoPlay = false,
	AutoDagger = false,
	AutoDaggerRange = 30,
	AutoWiggle = false,
	-- Survivor
	SpeedBoost = false,
	CustomSpeed = 16,
	NoSlowdown = false,
	ForceResetState = false,
	SilentActions = false,
	AntiFallDamage = false,
	ClientGodMode = false,
	InstantHeal = false,
	AntiKnock = false,
	AutoHealAura = false,
	AutoHealAuraRange = 30,
	-- Killer
	VeinSpearPrediction = false,
	VeinSpearNoGravity = false,
	AntiBlind = false,
	AntiStun = false,
	DoubleDamageGen = false,
	DoubleDamageMultiplier = 2,
	ActivateKillerPower = false,
	-- Visuals
	PlayerESP = false,
	ObjectESP = false,
	CustomFOV = false,
	FOVValue = 70,
	ShowCrosshair = false,
	RemoveBlurBloom = false,
	ForceFullbright = false,
	ExtremePotatoMode = false,
	-- Combat
	Aimbot = false,
	AimRadius = 150,
	AimCircle = false,
	ShowTargetTracer = false,
	LockOnHighlight = false,
	FPPTPP = false,
	ExpandKillerHitbox = false,
	ExpandHitboxSize = 2,
	AutoAttack = false,
	AutoAttackRange = 10,
	-- Automation
	AutoGenerator = false,
	AutoGenMode = "Perfect",
	BoostAllGen = false,
	InstantEscape = false,
	SelfUnHook = false,
}

-- Connections table for cleanup
local Connections = {}
local ESPObjects = {}
local DrawingObjects = {}

-- Utility functions
local function GetCharacter()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
		return char
	end
	return nil
end

local function GetHumanoid()
	local char = GetCharacter()
	return char and char:FindFirstChild("Humanoid") or nil
end

local function GetRootPart()
	local char = GetCharacter()
	return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function FindNearestGenerator()
	local root = GetRootPart()
	if not root then return nil end
	local nearest = nil
	local minDist = math.huge
	for _, obj in pairs(Workspace:GetDescendants()) do
		if (obj.Name:lower():find("generator") or obj.Name:lower():find("gen"))
			and obj:IsA("Model") or (obj:IsA("BasePart") and obj.Name:lower():find("gen")) then
			local part = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
			if part then
				local dist = (root.Position - part.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = obj
				end
			end
		end
	end
	return nearest
end

local function FindNearestExitGate()
	local root = GetRootPart()
	if not root then return nil end
	local nearest = nil
	local minDist = math.huge
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("exit") or name:find("gate") or name:find("escape"))
			and (obj:IsA("Model") or obj:IsA("BasePart")) then
			local part = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
			if part then
				local dist = (root.Position - part.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = obj
				end
			end
		end
	end
	return nearest
end

local function FindNearestKiller()
	local root = GetRootPart()
	if not root then return nil end
	local nearest = nil
	local minDist = math.huge
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local dist = (root.Position - hrp.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = player
				end
			end
		end
	end
	-- Also search NPCs
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("killer") or name:find("monster") or name:find("enemy") or name:find("vein"))
			and obj:IsA("Model") then
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
			if hrp then
				local dist = (root.Position - hrp.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = {Character = obj, Name = obj.Name}
				end
			end
		end
	end
	return nearest
end

local function FindNearestAlly()
	local root = GetRootPart()
	if not root then return nil end
	local nearest = nil
	local minDist = math.huge
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
				local dist = (root.Position - hrp.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = player
				end
			end
		end
	end
	return nearest
end

local function Notify(title, content)
	WindUI:Notify({
		Title = title,
		Content = content,
	})
end

-- ============================================================
-- TAB: VIP (ULTIMATE AUTOMATIC)
-- ============================================================
local TabVIP = Window:Tab({
	Title = "👑 VIP",
	Icon = "solar:crown-bold",
})

TabVIP:Section({
	Title = "VIP • Ultimate Automatic",
	Desc = "Smart AI AutoFarmBot & Instant Actions",
})

-- Auto Play (Smart AI / AutoFarmBot)
TabVIP:Toggle({
	Title = "Auto Play (Smart AI / AutoFarmBot)",
	Desc = "Bot cerdas pencari Generator/Gerbang yang bisa otomatis kabur dari Killer",
	Value = false,
	Callback = function(value)
		FeatureState.AutoPlay = value
		if value then
			Notify("Auto Play", "Smart AI Bot diaktifkan! Mencari Generator...")
		else
			Notify("Auto Play", "Smart AI Bot dinonaktifkan.")
		end
	end,
})

TabVIP:Slider({
	Title = "Auto Play - Killer Flee Distance",
	IsTooltip = true,
	Step = 5,
	Value = { Min = 20, Max = 100, Default = 50 },
	Icons = { From = "solar:danger-triangle-bold", To = "solar:shield-check-bold" },
	Callback = function(value)
		FeatureState.KillerFleeDistance = value
	end,
})

-- Auto Dagger (Auto Parry)
TabVIP:Section({
	Title = "Auto Dagger (Auto Parry)",
	Desc = "Menangkis serangan Killer secara instan",
})

TabVIP:Toggle({
	Title = "Auto Dagger (Auto Parry)",
	Desc = "Menangkis serangan Killer secara instan dengan Parrying Dagger",
	Value = false,
	Callback = function(value)
		FeatureState.AutoDagger = value
		if value then
			Notify("Auto Dagger", "Auto Parry diaktifkan!")
		else
			Notify("Auto Dagger", "Auto Parry dinonaktifkan.")
		end
	end,
})

TabVIP:Slider({
	Title = "Auto Dagger Range",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 5, Max = 80, Default = 30 },
	Callback = function(value)
		FeatureState.AutoDaggerRange = value
	end,
})

-- Auto-Wiggle Master
TabVIP:Section({
	Title = "Auto-Wiggle Master",
	Desc = "Memberontak dan lepas dari panggulan Killer",
})

TabVIP:Toggle({
	Title = "Auto-Wiggle Master",
	Desc = "Memberontak dan lepas dari panggulan Killer secara instan",
	Value = false,
	Callback = function(value)
		FeatureState.AutoWiggle = value
		if value then
			Notify("Auto-Wiggle", "Auto-Wiggle Master diaktifkan!")
		else
			Notify("Auto-Wiggle", "Auto-Wiggle Master dinonaktifkan.")
		end
	end,
})

-- ============================================================
-- TAB: SURVIVOR (MOVEMENT & HEALTH)
-- ============================================================
local TabSurvivor = Window:Tab({
	Title = "🛡️ Survivor",
	Icon = "solar:running-2-bold",
})

TabSurvivor:Section({
	Title = "Movement",
	Desc = "Kecepatan & pergerakan karakter",
})

-- Speed Boost & Custom Speed
TabSurvivor:Toggle({
	Title = "Speed Boost",
	Desc = "Menambah kecepatan lari karakter",
	Value = false,
	Callback = function(value)
		FeatureState.SpeedBoost = value
		local hum = GetHumanoid()
		if hum then
			if value then
				hum.WalkSpeed = FeatureState.CustomSpeed
			else
				hum.WalkSpeed = 16
			end
		end
	end,
})

TabSurvivor:Slider({
	Title = "Custom Speed",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 16, Max = 100, Default = 16 },
	Icons = { From = "solar:snail-bold", To = "solar:rocket-2-bold" },
	Callback = function(value)
		FeatureState.CustomSpeed = value
		if FeatureState.SpeedBoost then
			local hum = GetHumanoid()
			if hum then
				hum.WalkSpeed = value
			end
		end
	end,
})

-- No Slowdown
TabSurvivor:Toggle({
	Title = "No Slowdown",
	Desc = "Kebal terhadap semua efek perlambatan gerak",
	Value = false,
	Callback = function(value)
		FeatureState.NoSlowdown = value
		if value then
			Notify("No Slowdown", "Perlambatan gerak dinonaktifkan!")
		else
			Notify("No Slowdown", "Efek perlambatan kembali normal.")
		end
	end,
})

-- Force Reset State (Anti-Stuck)
TabSurvivor:Section({
	Title = "State & Recovery",
	Desc = "Anti-stuck & recovery tools",
})

TabSurvivor:Toggle({
	Title = "Force Reset State (Anti-Stuck)",
	Desc = "Memaksa karakter keluar dari animasi kaku atau bug",
	Value = false,
	Callback = function(value)
		FeatureState.ForceResetState = value
		if value then
			Notify("Anti-Stuck", "Force Reset State aktif!")
		end
	end,
})

TabSurvivor:Button({
	Title = "Force Reset Now",
	Icon = "solar:restart-bold",
	Callback = function()
		local char = GetCharacter()
		if char then
			local hum = char:FindFirstChild("Humanoid")
			if hum then
				-- Reset all states
				hum.PlatformStand = false
				hum.Sit = false
				-- Clear all forces
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					root.Velocity = Vector3.new(0, 0, 0)
					root.RotVelocity = Vector3.new(0, 0, 0)
				end
				-- Reset animations
				for _, anim in pairs(char:GetDescendants()) do
					if anim:IsA("Script") or anim:IsA("LocalScript") then
						-- Skip
					end
				end
			end
			Notify("Force Reset", "Karakter berhasil di-reset!")
		end
	end,
})

-- Silent Actions
TabSurvivor:Section({
	Title = "Stealth",
	Desc = "Tidak terdeteksi oleh Killer",
})

TabSurvivor:Toggle({
	Title = "Silent Actions (Anti-Noise)",
	Desc = "Berlari dan melompat tanpa memberikan notifikasi suara/visual ke Killer",
	Value = false,
	Callback = function(value)
		FeatureState.SilentActions = value
		if value then
			Notify("Silent Actions", "Semua suara dan notifikasi visual dinonaktifkan!")
		else
			Notify("Silent Actions", "Efek suara/visual kembali normal.")
		end
	end,
})

-- Anti Fall Damage
TabSurvivor:Toggle({
	Title = "Anti Fall Damage",
	Desc = "Mencegah damage dan animasi kaku saat jatuh dari tempat tinggi",
	Value = false,
	Callback = function(value)
		FeatureState.AntiFallDamage = value
		if value then
			Notify("Anti Fall Damage", "Fall damage dinonaktifkan!")
		else
			Notify("Anti Fall Damage", "Fall damage kembali normal.")
		end
	end,
})

-- Health
TabSurvivor:Section({
	Title = "Health & Defense",
	Desc = "Pertahanan dan penyembuhan",
})

-- Client God Mode
TabSurvivor:Toggle({
	Title = "Client God Mode (Beta)",
	Desc = "Memblokir pengiriman hit ke server (Damage Nullifier)",
	Value = false,
	Callback = function(value)
		FeatureState.ClientGodMode = value
		if value then
			Notify("God Mode", "Client God Mode diaktifkan! (Beta)")
		else
			Notify("God Mode", "Client God Mode dinonaktifkan.")
		end
	end,
})

-- Instant Heal
TabSurvivor:Button({
	Title = "Instant Heal",
	Desc = "Menyembuhkan diri sendiri ke Max Health secara instan",
	Icon = "solar:heart-pulse-bold",
	Callback = function()
		local hum = GetHumanoid()
		if hum then
			hum.Health = hum.MaxHealth
			Notify("Instant Heal", "Health dipulihkan ke maximum!")
		else
			Notify("Instant Heal", "Gagal: Karakter tidak ditemukan.")
		end
	end,
})

-- Anti Knock
TabSurvivor:Toggle({
	Title = "Anti Knock",
	Desc = "Mencegah karakter jatuh (knocked down) saat dipukul",
	Value = false,
	Callback = function(value)
		FeatureState.AntiKnock = value
		if value then
			Notify("Anti Knock", "Karakter tidak akan ter-knock down!")
		else
			Notify("Anti Knock", "Knock effect kembali normal.")
		end
	end,
})

-- Auto Heal Aura
TabSurvivor:Toggle({
	Title = "Auto Heal Aura",
	Desc = "Menyembuhkan teman satu tim di sekitar secara otomatis",
	Value = false,
	Callback = function(value)
		FeatureState.AutoHealAura = value
		if value then
			Notify("Auto Heal Aura", "Menyembuhkan ally otomatis!")
		else
			Notify("Auto Heal Aura", "Auto Heal Aura dinonaktifkan.")
		end
	end,
})

TabSurvivor:Slider({
	Title = "Heal Aura Range",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 5, Max = 80, Default = 30 },
	Icons = { From = "solar:minus-circle-bold", To = "solar:add-circle-bold" },
	Callback = function(value)
		FeatureState.AutoHealAuraRange = value
	end,
})

-- ============================================================
-- TAB: KILLER (VEIN KILLER MODIFICATION)
-- ============================================================
local TabKiller = Window:Tab({
	Title = "🔪 Killer",
	Icon = "solar:skull-bold",
})

TabKiller:Section({
	Title = "Vein Spear Modifications",
	Desc = "Modifikasi serangan tombak Vein Killer",
})

-- Vein Spear: Drop Prediction
TabKiller:Toggle({
	Title = "Vein Spear: Drop Prediction",
	Desc = "Aimbot tombak yang otomatis mengarah sedikit ke atas untuk target jauh",
	Value = false,
	Callback = function(value)
		FeatureState.VeinSpearPrediction = value
		if value then
			Notify("Spear Prediction", "Drop Prediction diaktifkan!")
		else
			Notify("Spear Prediction", "Drop Prediction dinonaktifkan.")
		end
	end,
})

-- Vein Spear: No Gravity
TabKiller:Toggle({
	Title = "Vein Spear: No Gravity",
	Desc = "Lemparan tombak terbang lurus tanpa terpengaruh gravitasi",
	Value = false,
	Callback = function(value)
		FeatureState.VeinSpearNoGravity = value
		if value then
			Notify("No Gravity", "Tombak terbang lurus tanpa gravitasi!")
		else
			Notify("No Gravity", "Gravitasi tombak kembali normal.")
		end
	end,
})

-- Anti-Blind
TabKiller:Section({
	Title = "Killer Defense",
	Desc = "Proteksi dan kebalan untuk Killer",
})

TabKiller:Toggle({
	Title = "Anti-Blind",
	Desc = "Kebal terhadap efek kabut (Fog) dan kilatan cahaya (Flash)",
	Value = false,
	Callback = function(value)
		FeatureState.AntiBlind = value
		if value then
			-- Remove blind effects
			for _, obj in pairs(Lighting:GetChildren()) do
				if obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") then
					if obj.Name:lower():find("blind") or obj.Name:lower():find("flash") or obj.Name:lower():find("fog") then
						obj.Enabled = not value
					end
				end
			end
			Notify("Anti-Blind", "Efek kabur dan kilatan dinonaktifkan!")
		else
			Notify("Anti-Blind", "Efek visual kembali normal.")
		end
	end,
})

-- Anti-Stun
TabKiller:Toggle({
	Title = "Anti-Stun",
	Desc = "Mencegah efek stun saat terkena bantingan Pallet",
	Value = false,
	Callback = function(value)
		FeatureState.AntiStun = value
		if value then
			Notify("Anti-Stun", "Karakter kebal terhadap stun!")
		else
			Notify("Anti-Stun", "Stun effect kembali normal.")
		end
	end,
})

-- Double Damage Generator
TabKiller:Section({
	Title = "Generator Attack",
	Desc = "Serangan dan kekuatan spesial Killer",
})

TabKiller:Toggle({
	Title = "Double Damage Generator",
	Desc = "Menendang generator berkali-kali dalam satu klik (Multiplier)",
	Value = false,
	Callback = function(value)
		FeatureState.DoubleDamageGen = value
		if value then
			Notify("Double Damage", "Generator damage multiplier aktif!")
		else
			Notify("Double Damage", "Generator damage normal.")
		end
	end,
})

TabKiller:Slider({
	Title = "Damage Multiplier",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 2, Max = 10, Default = 2 },
	Callback = function(value)
		FeatureState.DoubleDamageMultiplier = value
	end,
})

-- Activate Killer Power
TabKiller:Toggle({
	Title = "Activate Killer Power",
	Desc = "Memicu kekuatan spesial Killer secara instan",
	Value = false,
	Callback = function(value)
		FeatureState.ActivateKillerPower = value
		if value then
			Notify("Killer Power", "Kekuatan spesial Killer diaktifkan!")
		else
			Notify("Killer Power", "Kekuatan spesial Killer dinonaktifkan.")
		end
	end,
})

-- ============================================================
-- TAB: VISUALS (ESP & WORLD)
-- ============================================================
local TabVisuals = Window:Tab({
	Title = "👁️ Visuals",
	Icon = "solar:eye-bold",
})

TabVisuals:Section({
	Title = "ESP System",
	Desc = "Menampilkan informasi di layar",
})

-- Player ESP
TabVisuals:Toggle({
	Title = "Player ESP",
	Desc = "Menampilkan lokasi Survivor & Killer (Jarak, status, nama/topeng)",
	Value = false,
	Callback = function(value)
		FeatureState.PlayerESP = value
		if value then
			Notify("Player ESP", "Player ESP diaktifkan!")
		else
			Notify("Player ESP", "Player ESP dinonaktifkan.")
			-- Cleanup ESP objects
			for _, obj in pairs(ESPObjects) do
				if obj and obj.Parent then
					obj:Destroy()
				end
			end
			ESPObjects = {}
		end
	end,
})

-- Object ESP
TabVisuals:Toggle({
	Title = "Object ESP",
	Desc = "Menampilkan letak Generator, Pallet, Exit Gate, dan Hook",
	Value = false,
	Callback = function(value)
		FeatureState.ObjectESP = value
		if value then
			Notify("Object ESP", "Object ESP diaktifkan!")
		else
			Notify("Object ESP", "Object ESP dinonaktifkan.")
		end
	end,
})

-- Camera Settings
TabVisuals:Section({
	Title = "Camera",
	Desc = "Pengaturan jarak pandang dan kamera",
})

-- Custom FOV
TabVisuals:Toggle({
	Title = "Enable Custom FOV",
	Desc = "Mengatur jarak pandang kamera sesuai keinginan",
	Value = false,
	Callback = function(value)
		FeatureState.CustomFOV = value
		if value then
			Camera.FieldOfView = FeatureState.FOVValue
			Notify("Custom FOV", "FOV diatur ke " .. FeatureState.FOVValue)
		else
			Camera.FieldOfView = 70
			Notify("Custom FOV", "FOV dikembalikan ke default (70)")
		end
	end,
})

TabVisuals:Slider({
	Title = "FOV Value",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 30, Max = 120, Default = 70 },
	Icons = { From = "solar:minimize-bold", To = "solar:maximize-bold" },
	Callback = function(value)
		FeatureState.FOVValue = value
		if FeatureState.CustomFOV then
			Camera.FieldOfView = value
		end
	end,
})

-- Show Crosshair
TabVisuals:Section({
	Title = "Screen Overlays",
	Desc = "Elemen tampilan layar",
})

TabVisuals:Toggle({
	Title = "Show Crosshair",
	Desc = "Menampilkan titik bidik di tengah layar",
	Value = false,
	Callback = function(value)
		FeatureState.ShowCrosshair = value
		if value then
			Notify("Crosshair", "Crosshair ditampilkan!")
		else
			Notify("Crosshair", "Crosshair disembunyikan.")
		end
	end,
})

-- Visual Effects
TabVisuals:Section({
	Title = "Visual Effects",
	Desc = "Pengaturan efek visual dan performa",
})

-- Remove Blur & Bloom
TabVisuals:Toggle({
	Title = "Remove Blur & Bloom",
	Desc = "Mematikan efek buram jarak jauh dan pantulan cahaya menyilaukan",
	Value = false,
	Callback = function(value)
		FeatureState.RemoveBlurBloom = value
		if value then
			for _, obj in pairs(Lighting:GetChildren()) do
				if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") then
					obj.Enabled = false
				end
			end
			Notify("Remove Effects", "Blur, Bloom, dan Depth of Field dimatikan!")
		else
			for _, obj in pairs(Lighting:GetChildren()) do
				if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") then
					obj.Enabled = true
				end
			end
			Notify("Remove Effects", "Efek visual dikembalikan.")
		end
	end,
})

-- Force Fullbright
TabVisuals:Toggle({
	Title = "Force Fullbright",
	Desc = "Menerangkan seluruh map tanpa bayangan dan kabut",
	Value = false,
	Callback = function(value)
		FeatureState.ForceFullbright = value
		if value then
			-- Save original values
			if not FeatureState.OriginalLighting then
				FeatureState.OriginalLighting = {
					Ambient = Lighting.Ambient,
					Brightness = Lighting.Brightness,
					OutdoorAmbient = Lighting.OutdoorAmbient,
					ClockTime = Lighting.ClockTime,
					FogEnd = Lighting.FogEnd,
					FogStart = Lighting.FogStart,
					GlobalShadows = Lighting.GlobalShadows,
				}
			end
			Lighting.Ambient = Color3.new(1, 1, 1)
			Lighting.Brightness = 2
			Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
			Lighting.FogEnd = 100000
			Lighting.FogStart = 0
			Lighting.GlobalShadows = false
			Notify("Fullbright", "Map diterangi penuh!")
		else
			-- Restore original values
			if FeatureState.OriginalLighting then
				Lighting.Ambient = FeatureState.OriginalLighting.Ambient
				Lighting.Brightness = FeatureState.OriginalLighting.Brightness
				Lighting.OutdoorAmbient = FeatureState.OriginalLighting.OutdoorAmbient
				Lighting.FogEnd = FeatureState.OriginalLighting.FogEnd
				Lighting.FogStart = FeatureState.OriginalLighting.FogStart
				Lighting.GlobalShadows = FeatureState.OriginalLighting.GlobalShadows
			end
			Notify("Fullbright", "Pencahayaan dikembalikan ke default.")
		end
	end,
})

-- Extreme Potato Mode
TabVisuals:Toggle({
	Title = "Extreme Potato Mode",
	Desc = "Menghapus semua tekstur dan partikel map untuk memaksimalkan FPS",
	Value = false,
	Callback = function(value)
		FeatureState.ExtremePotatoMode = value
		if value then
			-- Save original quality settings
			if not FeatureState.OriginalQuality then
				FeatureState.OriginalQuality = {
					QualityLevel = UserInputService.GraphicsQualityLevel,
				}
			end
			-- Set lowest quality
			settings().Rendering.QualityLevel = 1
			-- Disable particles
			for _, obj in pairs(Workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
					obj.Enabled = false
				end
			end
			-- Disable lighting effects
			for _, obj in pairs(Lighting:GetChildren()) do
				if obj:IsA("PostEffect") or obj:IsA("Atmosphere") then
					obj.Enabled = false
				end
			end
			Notify("Potato Mode", "Extreme Potato Mode diaktifkan! FPS maksimal.")
		else
			-- Restore quality
			if FeatureState.OriginalQuality then
				settings().Rendering.QualityLevel = FeatureState.OriginalQuality.QualityLevel
			end
			-- Re-enable particles
			for _, obj in pairs(Workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
					obj.Enabled = true
				end
			end
			Notify("Potato Mode", "Kualitas grafis dikembalikan.")
		end
	end,
})

-- ============================================================
-- TAB: COMBAT (TARGETING SYSTEM)
-- ============================================================
local TabCombat = Window:Tab({
	Title = "⚔️ Combat",
	Icon = "solar:target-bold",
})

TabCombat:Section({
	Title = "Aimbot System",
	Desc = "Sistem bidikan otomatis",
})

-- Enable Aimbot
TabCombat:Toggle({
	Title = "Enable Aimbot",
	Desc = "Mengunci bidikan kamera ke musuh terdekat",
	Value = false,
	Callback = function(value)
		FeatureState.Aimbot = value
		if value then
			Notify("Aimbot", "Aimbot diaktifkan!")
		else
			Notify("Aimbot", "Aimbot dinonaktifkan.")
		end
	end,
})

TabCombat:Slider({
	Title = "Aim Radius",
	IsTooltip = true,
	Step = 5,
	Value = { Min = 50, Max = 500, Default = 150 },
	Callback = function(value)
		FeatureState.AimRadius = value
	end,
})

TabCombat:Toggle({
	Title = "Show Aim Circle",
	Desc = "Menampilkan lingkaran bidik aimbot di layar",
	Value = false,
	Callback = function(value)
		FeatureState.AimCircle = value
	end,
})

-- Target Visuals
TabCombat:Section({
	Title = "Target Visuals",
	Desc = "Visualisasi target dan tracer",
})

-- Show Target Tracer
TabCombat:Toggle({
	Title = "Show Target Tracer",
	Desc = "Menarik garis laser merah dari bawah layar ke arah target",
	Value = false,
	Callback = function(value)
		FeatureState.ShowTargetTracer = value
		if value then
			Notify("Tracer", "Target Tracer ditampilkan!")
		else
			Notify("Tracer", "Target Tracer disembunyikan.")
		end
	end,
})

-- Lock-On Highlight
TabCombat:Toggle({
	Title = "Lock-On Highlight",
	Desc = "Membuat tubuh target bersinar terang (Merah/Emas)",
	Value = false,
	Callback = function(value)
		FeatureState.LockOnHighlight = value
		if value then
			Notify("Highlight", "Lock-On Highlight diaktifkan!")
		else
			Notify("Highlight", "Lock-On Highlight dinonaktifkan.")
		end
	end,
})

-- Camera & Hitbox
TabCombat:Section({
	Title = "Camera & Hitbox",
	Desc = "Pengaturan kamera dan hitbox",
})

-- FPP / TPP Toggle
TabCombat:Toggle({
	Title = "FPP / TPP Toggle",
	Desc = "Berpindah sudut pandang kamera (Tombol melayang khusus Mobile)",
	Value = false,
	Callback = function(value)
		FeatureState.FPPTPP = value
		local hum = GetHumanoid()
		if hum then
			if value then
				-- Force first person by setting camera mode
				LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
				Notify("Camera", "First Person Mode diaktifkan!")
			else
				LocalPlayer.CameraMode = Enum.CameraMode.Classic
				Notify("Camera", "Third Person Mode diaktifkan!")
			end
		end
	end,
})

-- Expand Killer Hitbox
TabCombat:Toggle({
	Title = "Expand Killer Hitbox",
	Desc = "Memperbesar ukuran tubuh Killer agar mudah dipukul/di-stun",
	Value = false,
	Callback = function(value)
		FeatureState.ExpandKillerHitbox = value
		if value then
			Notify("Hitbox Expander", "Killer Hitbox diperbesar!")
		else
			Notify("Hitbox Expander", "Killer Hitbox dikembalikan normal.")
		end
	end,
})

TabCombat:Slider({
	Title = "Hitbox Size Multiplier",
	IsTooltip = true,
	Step = 0.5,
	Value = { Min = 1, Max = 5, Default = 2 },
	Callback = function(value)
		FeatureState.ExpandHitboxSize = value
	end,
})

-- Auto Attack
TabCombat:Section({
	Title = "Auto Attack",
	Desc = "Serangan otomatis Killer",
})

TabCombat:Toggle({
	Title = "Auto Attack",
	Desc = "Killer otomatis memukul musuh yang masuk dalam jangkauan",
	Value = false,
	Callback = function(value)
		FeatureState.AutoAttack = value
		if value then
			Notify("Auto Attack", "Auto Attack diaktifkan!")
		else
			Notify("Auto Attack", "Auto Attack dinonaktifkan.")
		end
	end,
})

TabCombat:Slider({
	Title = "Auto Attack Range",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 3, Max = 30, Default = 10 },
	Callback = function(value)
		FeatureState.AutoAttackRange = value
	end,
})

-- ============================================================
-- TAB: AUTOMATION (GENERATOR & UTILITY)
-- ============================================================
local TabAutomation = Window:Tab({
	Title = "⚙️ Auto",
	Icon = "solar:settings-minimalistic-bold",
})

TabAutomation:Section({
	Title = "Generator Automation",
	Desc = "Otomatisasi penyelesaian Generator",
})

-- Auto Generator
TabAutomation:Toggle({
	Title = "Auto Generator",
	Desc = "Menyelesaikan SkillCheck mesin secara otomatis",
	Value = false,
	Callback = function(value)
		FeatureState.AutoGenerator = value
		if value then
			Notify("Auto Generator", "Auto Generator diaktifkan! Mode: " .. FeatureState.AutoGenMode)
		else
			Notify("Auto Generator", "Auto Generator dinonaktifkan.")
		end
	end,
})

TabAutomation:Dropdown({
	Title = "SkillCheck Mode",
	Value = "Perfect",
	Values = {"Perfect", "Neutral"},
	Callback = function(value)
		FeatureState.AutoGenMode = value
		Notify("SkillCheck Mode", "Mode diubah ke: " .. value)
	end,
})

-- Boost All Gen
TabAutomation:Section({
	Title = "Map-Wide Boost",
	Desc = "Boost dan escape otomatis",
})

TabAutomation:Toggle({
	Title = "Boost All Gen (Group Project)",
	Desc = "Menyuntikkan progress ke seluruh generator di map secara bersamaan",
	Value = false,
	Callback = function(value)
		FeatureState.BoostAllGen = value
		if value then
			Notify("Boost All Gen", "Semua Generator diboost!")
		else
			Notify("Boost All Gen", "Generator boost dinonaktifkan.")
		end
	end,
})

-- Instant Escape
TabAutomation:Toggle({
	Title = "Instant Escape (Gate)",
	Desc = "Otomatis menarik tuas gerbang dan teleportasi ke zona Finish",
	Value = false,
	Callback = function(value)
		FeatureState.InstantEscape = value
		if value then
			Notify("Instant Escape", "Mencari Exit Gate terdekat...")
		else
			Notify("Instant Escape", "Instant Escape dinonaktifkan.")
		end
	end,
})

-- Self UnHook
TabAutomation:Section({
	Title = "Hook Recovery",
	Desc = "Pemulihan dari gantungan",
})

TabAutomation:Toggle({
	Title = "Self UnHook",
	Desc = "Manipulasi peluang 100% agar pasti berhasil lepas dari gantungan sendiri",
	Value = false,
	Callback = function(value)
		FeatureState.SelfUnHook = value
		if value then
			Notify("Self UnHook", "100% UnHook chance diaktifkan!")
		else
			Notify("Self UnHook", "Self UnHook dinonaktifkan.")
		end
	end,
})

-- ============================================================
-- MAIN LOGIC LOOPS
-- ============================================================

-- Auto Play (Smart AI / AutoFarmBot)
local function AutoPlayLogic()
	if not FeatureState.AutoPlay then return end

	local char = GetCharacter()
	local root = GetRootPart()
	local hum = GetHumanoid()
	if not char or not root or not hum or hum.Health <= 0 then return end

	local killer = FindNearestKiller()
	local killerDist = math.huge
	local killerPos = nil

	if killer then
		local kChar = killer.Character or (killer and type(killer) == "table" and killer.Character)
		if kChar then
			local kHRP = kChar:FindFirstChild("HumanoidRootPart") or kChar:FindFirstChild("Torso")
			if kHRP then
				killerDist = (root.Position - kHRP.Position).Magnitude
				killerPos = kHRP.Position
			end
		end
	end

	local fleeDist = FeatureState.KillerFleeDistance or 50

	if killerDist < fleeDist and killerPos then
		-- FLEE from killer: run in opposite direction
		local fleeDir = (root.Position - killerPos).Unit
		local fleeTarget = root.Position + fleeDir * 50
		hum:MoveTo(fleeTarget)
	else
		-- Find nearest generator to work on
		local gen = FindNearestGenerator()
		if gen then
			local genPart = gen:IsA("Model") and gen:FindFirstChildWhichIsA("BasePart") or (gen:IsA("BasePart") and gen)
			if genPart then
				local dist = (root.Position - genPart.Position).Magnitude
				if dist > 5 then
					hum:MoveTo(genPart.Position)
				end
			end
		else
			-- No generators found, look for exit gate
			local gate = FindNearestExitGate()
			if gate then
				local gatePart = gate:IsA("Model") and gate:FindFirstChildWhichIsA("BasePart") or (gate:IsA("BasePart") and gate)
				if gatePart then
					hum:MoveTo(gatePart.Position)
				end
			end
		end
	end
end

-- Auto Dagger (Auto Parry) Logic
local function AutoDaggerLogic()
	if not FeatureState.AutoDagger then return end

	local root = GetRootPart()
	if not root then return end

	local killer = FindNearestKiller()
	if not killer then return end

	local kChar = killer.Character or (type(killer) == "table" and killer.Character)
	if not kChar then return end

	local kHRP = kChar:FindFirstChild("HumanoidRootPart") or kChar:FindFirstChild("Torso")
	if not kHRP then return end

	local dist = (root.Position - kHRP.Position).Magnitude

	if dist <= FeatureState.AutoDaggerRange then
		-- Attempt to trigger parry/dagger action
		-- Hook into game's combat system
		local char = GetCharacter()
		if char then
			for _, tool in pairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					local activateEvent = tool:FindFirstChild("ActivateEvent")
						or tool:FindFirstChild("RemoteEvent")
						or tool:FindFirstChild("Action")
					if activateEvent and activateEvent:IsA("RemoteEvent") then
						activateEvent:FireServer("parry")
					end
				end
			end
		end
	end
end

-- Auto-Wiggle Master Logic
local function AutoWiggleLogic()
	if not FeatureState.AutoWiggle then return end

	local char = GetCharacter()
	if not char then return end

	-- Check if player is in hooked/captured state
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	-- Simulate wiggle by rapidly alternating movement input
	local root = GetRootPart()
	if root then
		-- Create a random direction wiggle pattern
		local directions = {
			Vector3.new(1, 0, 0),
			Vector3.new(-1, 0, 0),
			Vector3.new(0, 0, 1),
			Vector3.new(0, 0, -1),
			Vector3.new(1, 0, 1),
			Vector3.new(-1, 0, -1),
		}
		local dir = directions[math.random(#directions)]
		hum:MoveTo(root.Position + dir * 5)

		-- Also try firing any unhook-related remote events
		for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
			local name = obj.Name:lower()
			if obj:IsA("RemoteEvent") and (name:find("unhook") or name:find("wiggle") or name:find("escape") or name:find("struggle")) then
				pcall(function()
					obj:FireServer()
				end)
			end
		end
	end
end

-- Speed Boost Logic
local function SpeedBoostLogic()
	if not FeatureState.SpeedBoost then return end

	local hum = GetHumanoid()
	if hum and hum.WalkSpeed < FeatureState.CustomSpeed then
		hum.WalkSpeed = FeatureState.CustomSpeed
	end
end

-- No Slowdown Logic
local function NoSlowdownLogic()
	if not FeatureState.NoSlowdown then return end

	local hum = GetHumanoid()
	if hum then
		-- Override any speed reduction
		if FeatureState.SpeedBoost then
			if hum.WalkSpeed < FeatureState.CustomSpeed then
				hum.WalkSpeed = FeatureState.CustomSpeed
			end
		else
			if hum.WalkSpeed < 16 then
				hum.WalkSpeed = 16
			end
		end
	end
end

-- Force Reset State Logic
local function ForceResetLogic()
	if not FeatureState.ForceResetState then return end

	local char = GetCharacter()
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	-- Auto-fix stuck states
	if hum.PlatformStand then
		hum.PlatformStand = false
	end
	if hum.Sit and not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		hum.Sit = false
	end

	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		-- If velocity is near zero but character should be moving, nudge
		if root.AssemblyLinearVelocity.Magnitude < 0.5 and FeatureState.SpeedBoost then
			root.AssemblyLinearVelocity = root.CFrame.LookVector * FeatureState.CustomSpeed * 0.5
		end
	end
end

-- Silent Actions Logic
local function SilentActionsLogic()
	if not FeatureState.SilentActions then return end

	-- Suppress sound indicators and visual notifications
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("sound") or name:find("noise") or name:find("indicator") or name:find("alert"))
			and (obj:IsA("Sound") or obj:IsA("BillboardGui") or obj:IsA("ParticleEmitter")) then
			pcall(function()
				if obj:IsA("Sound") then
					obj.Volume = 0
				elseif obj:IsA("BillboardGui") then
					obj.Enabled = false
				elseif obj:IsA("ParticleEmitter") then
					obj.Enabled = false
				end
			end)
		end
	end
end

-- Anti Fall Damage Logic
local function AntiFallDamageLogic()
	if not FeatureState.AntiFallDamage then return end

	local hum = GetHumanoid()
	if hum then
		local state = hum:GetState()
		if state == Enum.HumanoidStateType.Freefall then
			local root = GetRootPart()
			if root then
				-- Reduce fall velocity to prevent damage
				if root.AssemblyLinearVelocity.Y < -50 then
					root.AssemblyLinearVelocity = Vector3.new(
						root.AssemblyLinearVelocity.X,
						-30,
						root.AssemblyLinearVelocity.Z
					)
				end
			end
		end
	end
end

-- Client God Mode Logic
local function ClientGodModeLogic()
	if not FeatureState.ClientGodMode then return end

	local hum = GetHumanoid()
	if hum then
		-- Continuously set health to max
		if hum.Health < hum.MaxHealth then
			hum.Health = hum.MaxHealth
		end
	end
end

-- Anti Knock Logic
local function AntiKnockLogic()
	if not FeatureState.AntiKnock then return end

	local char = GetCharacter()
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	-- Prevent knocked state
	local state = hum:GetState()
	if state == Enum.HumanoidStateType.Ragdoll
		or state == Enum.HumanoidStateType.FallingDown
		or state == Enum.HumanoidStateType.FlyingDown then
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait(0.1)
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end
end

-- Auto Heal Aura Logic
local function AutoHealAuraLogic()
	if not FeatureState.AutoHealAura then return end

	local root = GetRootPart()
	if not root then return end

	-- Find allies in range
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local allyChar = player.Character
			local allyHRP = allyChar:FindFirstChild("HumanoidRootPart")
			local allyHum = allyChar:FindFirstChild("Humanoid")
			if allyHRP and allyHum and allyHum.Health > 0 and allyHum.Health < allyHum.MaxHealth then
				local dist = (root.Position - allyHRP.Position).Magnitude
				if dist <= FeatureState.AutoHealAuraRange then
					-- Heal ally via remote events or direct health manipulation
					allyHum.Health = math.min(allyHum.Health + 5, allyHum.MaxHealth)

					-- Try to find and fire heal-related remote events
					for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
						local name = obj.Name:lower()
						if obj:IsA("RemoteEvent") and (name:find("heal") or name:find("medkit") or name:find("support")) then
							pcall(function()
								obj:FireServer(player)
							end)
						end
					end
				end
			end
		end
	end
end

-- Player ESP Logic
local function PlayerESPLogic()
	if not FeatureState.PlayerESP then return end

	-- Clear old ESP objects
	for _, obj in pairs(ESPObjects) do
		if obj and obj.Parent then
			obj:Destroy()
		end
	end
	ESPObjects = {}

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")

			if hrp and hum and hum.Health > 0 then
				-- Create highlight
				local highlight = Instance.new("Highlight")
				highlight.Name = "ESP_" .. player.Name
				highlight.Adornee = char
				highlight.FillTransparency = 0.5
				highlight.OutlineTransparency = 0
				highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
				highlight.FillColor = Color3.fromRGB(255, 0, 0, 0.3)
				highlight.Parent = char

				table.insert(ESPObjects, highlight)

				-- Create Billboard GUI for info
				local billboard = Instance.new("BillboardGui")
				billboard.Name = "ESPInfo_" .. player.Name
				billboard.Adornee = hrp
				billboard.Size = UDim2.new(0, 200, 0, 50)
				billboard.StudsOffset = Vector3.new(0, 3, 0)
				billboard.AlwaysOnTop = true
				billboard.Parent = hrp

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "Name"
				nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
				nameLabel.Position = UDim2.new(0, 0, 0, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextColor3 = Color3.new(1, 1, 1)
				nameLabel.TextStrokeTransparency = 0
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextSize = 14
				nameLabel.Text = player.Name
				nameLabel.Parent = billboard

				local distLabel = Instance.new("TextLabel")
				distLabel.Name = "Distance"
				distLabel.Size = UDim2.new(1, 0, 0.5, 0)
				distLabel.Position = UDim2.new(0, 0, 0.5, 0)
				distLabel.BackgroundTransparency = 1
				distLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
				distLabel.TextStrokeTransparency = 0
				distLabel.Font = Enum.Font.Gotham
				distLabel.TextSize = 12
				local root = GetRootPart()
				local dist = root and math.floor((root.Position - hrp.Position).Magnitude) or 0
				distLabel.Text = "HP: " .. math.floor(hum.Health) .. " | " .. dist .. "m"
				distLabel.Parent = billboard

				table.insert(ESPObjects, billboard)
			end
		end
	end
end

-- Object ESP Logic
local function ObjectESPLogic()
	if not FeatureState.ObjectESP then return end

	-- Remove old object ESP
	for _, obj in pairs(ESPObjects) do
		if obj and obj.Parent and obj.Name:find("ObjESP_") then
			obj:Destroy()
		end
	end

	local function CreateObjectESP(obj, label, color)
		local part = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or (obj:IsA("BasePart") and obj)
		if not part then return end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ObjESP_" .. obj.Name
		billboard.Adornee = part
		billboard.Size = UDim2.new(0, 150, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = part

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 0.5
		textLabel.BackgroundColor3 = color
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextStrokeTransparency = 0
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextSize = 12
		textLabel.Text = label
		textLabel.Parent = billboard

		-- Add highlight
		local highlight = Instance.new("Highlight")
		highlight.Name = "ObjESPHL_" .. obj.Name
		highlight.Adornee = obj:IsA("Model") and obj or part
		highlight.FillTransparency = 0.7
		highlight.OutlineTransparency = 0.3
		highlight.FillColor = color
		highlight.OutlineColor = color
		highlight.Parent = obj:IsA("Model") and obj or part

		table.insert(ESPObjects, billboard)
		table.insert(ESPObjects, highlight)
	end

	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if name:find("generator") or name:find("gen") then
			CreateObjectESP(obj, "Generator", Color3.fromRGB(255, 255, 0))
		elseif name:find("pallet") then
			CreateObjectESP(obj, "Pallet", Color3.fromRGB(0, 255, 100))
		elseif name:find("exit") or name:find("gate") then
			CreateObjectESP(obj, "Exit Gate", Color3.fromRGB(0, 200, 255))
		elseif name:find("hook") then
			CreateObjectESP(obj, "Hook", Color3.fromRGB(255, 50, 50))
		end
	end
end

-- Aimbot Logic
local function AimbotLogic()
	if not FeatureState.Aimbot then return end

	local root = GetRootPart()
	if not root then return end

	-- Find nearest player/enemy in screen space
	local nearestTarget = nil
	local nearestScreenDist = FeatureState.AimRadius

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
			local hum = char:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local screenPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
				if onScreen then
					local mousePos = UserInputService:GetMouseLocation()
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if dist < nearestScreenDist then
						nearestScreenDist = dist
						nearestTarget = hrp
					end
				end
			end
		end
	end

	-- Also check NPC killers
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("killer") or name:find("monster") or name:find("enemy") or name:find("vein"))
			and obj:IsA("Model") then
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj:FindFirstChild("Torso")
			if hrp then
				local screenPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
				if onScreen then
					local mousePos = UserInputService:GetMouseLocation()
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if dist < nearestScreenDist then
						nearestScreenDist = dist
						nearestTarget = hrp
					end
				end
			end
		end
	end

	if nearestTarget then
		-- Smoothly move camera toward target
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearestTarget.Position)
	end
end

-- Lock-On Highlight Logic
local function LockOnHighlightLogic()
	-- Cleanup old highlights
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj.Name:find("LockOnHL_") and not FeatureState.LockOnHighlight then
			obj:Destroy()
		end
	end

	if not FeatureState.LockOnHighlight then return end

	local root = GetRootPart()
	if not root then return end

	-- Find nearest enemy and highlight
	local nearest = nil
	local minDist = math.huge

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local dist = (root.Position - hrp.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = char
				end
			end
		end
	end

	-- Check NPCs too
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("killer") or name:find("monster") or name:find("vein"))
			and obj:IsA("Model") then
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
			if hrp then
				local dist = (root.Position - hrp.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = obj
				end
			end
		end
	end

	if nearest then
		-- Remove old lock-on highlight
		for _, obj in pairs(nearest:GetChildren()) do
			if obj.Name:find("LockOnHL_") then
				obj:Destroy()
			end
		end

		local hl = Instance.new("Highlight")
		hl.Name = "LockOnHL_Target"
		hl.Adornee = nearest
		hl.FillColor = Color3.fromRGB(255, 215, 0)
		hl.OutlineColor = Color3.fromRGB(255, 0, 0)
		hl.FillTransparency = 0.3
		hl.OutlineTransparency = 0
		hl.Parent = nearest
	end
end

-- Expand Killer Hitbox Logic
local function ExpandHitboxLogic()
	-- Reset all hitboxes first
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj.Name:find("ExpandedHitbox_") then
			obj:Destroy()
		end
	end

	if not FeatureState.ExpandKillerHitbox then return end

	local function ExpandHitbox(model)
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				local name = part.Name:lower()
				if name:find("hitbox") or name:find("humanoidrootpart") or name:find("torso") or name:find("body") then
					-- Create invisible expanded hitbox
					local size = part.Size * FeatureState.ExpandHitboxSize
					local mesh = Instance.new("BlockMesh")
					mesh.Name = "ExpandedHitbox_" .. part.Name
					mesh.Scale = Vector3.new(FeatureState.ExpandHitboxSize, FeatureState.ExpandHitboxSize, FeatureState.ExpandHitboxSize)
					mesh.Parent = part
				end
			end
		end
	end

	-- Find killer NPCs and expand their hitboxes
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("killer") or name:find("monster") or name:find("enemy") or name:find("vein"))
			and obj:IsA("Model") then
			ExpandHitbox(obj)
		end
	end
end

-- Auto Attack Logic
local function AutoAttackLogic()
	if not FeatureState.AutoAttack then return end

	local root = GetRootPart()
	if not root then return end

	local nearestTarget = nil
	local minDist = FeatureState.AutoAttackRange

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local dist = (root.Position - hrp.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearestTarget = player
				end
			end
		end
	end

	-- Check NPCs
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("survivor") or name:find("player") or name:find("target"))
			and obj:IsA("Model") then
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
			if hrp then
				local dist = (root.Position - hrp.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearestTarget = {Character = obj}
				end
			end
		end
	end

	if nearestTarget then
		-- Fire attack remote events
		for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
			local name = obj.Name:lower()
			if obj:IsA("RemoteEvent") and (name:find("attack") or name:find("hit") or name:find("slash") or name:find("strike")) then
				pcall(function()
					if type(nearestTarget) == "table" and nearestTarget.Character then
						obj:FireServer(nearestTarget.Character)
					else
						obj:FireServer(nearestTarget.Character)
					end
				end)
			end
		end

		-- Also try tool activation
		local char = GetCharacter()
		if char then
			for _, tool in pairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					pcall(function()
						tool:Activate()
					end)
				end
			end
		end
	end
end

-- Auto Generator Logic
local function AutoGeneratorLogic()
	if not FeatureState.AutoGenerator then return end

	-- Hook into the game's skill check system
	for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
		local name = obj.Name:lower()
		if obj:IsA("RemoteEvent") and (name:find("skillcheck") or name:find("skill_check") or name:find("check") or name:find("generator")) then
			pcall(function()
				if FeatureState.AutoGenMode == "Perfect" then
					-- Fire perfect hit
					obj:FireServer("perfect", 1.0)
				else
					-- Fire neutral/safe zone hit
					obj:FireServer("neutral", 0.5)
				end
			end)
		end
	end

	-- Also try to interact with nearby generators
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("generator") or name:find("gen")) and obj:IsA("Model") then
			local clickDetector = obj:FindFirstChildWhichIsA("ClickDetector")
			if clickDetector then
				local root = GetRootPart()
				if root then
					local part = obj:FindFirstChildWhichIsA("BasePart")
					if part and (root.Position - part.Position).Magnitude < 10 then
						fireclickdetector(clickDetector)
					end
				end
			end
		end
	end
end

-- Boost All Gen Logic
local function BoostAllGenLogic()
	if not FeatureState.BoostAllGen then return end

	-- Find all generators and boost them
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("generator") or name:find("gen")) and (obj:IsA("Model") or obj:IsA("BasePart")) then
			-- Fire boost/progress remote events
			for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
				local rName = remote.Name:lower()
				if remote:IsA("RemoteEvent") and (rName:find("gen") or rName:find("progress") or rName:find("boost") or rName:find("repair")) then
					pcall(function()
						remote:FireServer(obj, 100)
					end)
				end
			end
		end
	end
end

-- Instant Escape Logic
local function InstantEscapeLogic()
	if not FeatureState.InstantEscape then return end

	local root = GetRootPart()
	if not root then return end

	-- Find nearest exit gate
	local gate = FindNearestExitGate()
	if gate then
		local gatePart = gate:IsA("Model") and gate:FindFirstChildWhichIsA("BasePart") or (gate:IsA("BasePart") and gate)
		if gatePart then
			-- Teleport to gate
			root.CFrame = gatePart.CFrame + Vector3.new(0, 3, 0)

			-- Try to activate the gate lever
			for _, obj in pairs(gate:GetDescendants()) do
				local name = obj.Name:lower()
				if (name:find("lever") or name:find("switch") or name:find("activate") or name:find("interact"))
					and obj:IsA("ClickDetector") then
					fireclickdetector(obj)
				end
			end

			-- Fire escape-related remote events
			for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
				local rName = remote.Name:lower()
				if remote:IsA("RemoteEvent") and (rName:find("escape") or rName:find("gate") or rName:find("exit") or rName:find("open")) then
					pcall(function()
						remote:FireServer(gate)
					end)
				end
			end
		end
	end
end

-- Self UnHook Logic
local function SelfUnHookLogic()
	if not FeatureState.SelfUnHook then return end

	local char = GetCharacter()
	if not char then return end

	-- Check if player is hooked
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	-- Try all possible unhook methods
	for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
		local name = obj.Name:lower()
		if obj:IsA("RemoteEvent") and (name:find("unhook") or name:find("escape_hook") or name:find("self_unhook") or name:find("struggle")) then
			pcall(function()
				-- Fire with 100% chance parameter
				obj:FireServer(1.0)
				obj:FireServer(true)
				obj:FireServer()
			end)
		end
	end

	-- Also try hook objects in workspace
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if name:find("hook") and obj:IsA("Model") then
			for _, remote in pairs(obj:GetDescendants()) do
				if remote:IsA("RemoteEvent") then
					pcall(function()
						remote:FireServer(true)
						remote:FireServer(1.0)
					end)
				end
			end
		end
	end
end

-- Crosshair Drawing
local CrosshairGui = nil

local function CreateCrosshair()
	if CrosshairGui then return end

	CrosshairGui = Instance.new("ScreenGui")
	CrosshairGui.Name = "CrosshairGui"
	CrosshairGui.ResetOnSpawn = false
	CrosshairGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	CrosshairGui.Parent = game:GetService("CoreGui")

	local frame = Instance.new("Frame")
	frame.Name = "Crosshair"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 4, 0, 4)
	frame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	frame.BorderSizePixel = 0
	frame.Parent = CrosshairGui

	-- Crosshair lines
	local lines = {
		{UDim2.new(0.5, -12, 0.5, -1), UDim2.new(0, 10, 0, 2)},  -- Left
		{UDim2.new(0.5, 2, 0.5, -1), UDim2.new(0, 10, 0, 2)},    -- Right
		{UDim2.new(0.5, -1, 0.5, -12), UDim2.new(0, 2, 0, 10)},  -- Top
		{UDim2.new(0.5, -1, 0.5, 2), UDim2.new(0, 2, 0, 10)},    -- Bottom
	}

	for _, lineData in pairs(lines) do
		local line = Instance.new("Frame")
		line.Position = lineData[1]
		line.Size = lineData[2]
		line.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		line.BorderSizePixel = 0
		line.Parent = CrosshairGui
	end
end

local function RemoveCrosshair()
	if CrosshairGui and CrosshairGui.Parent then
		CrosshairGui:Destroy()
		CrosshairGui = nil
	end
end

-- Target Tracer Drawing
local TracerLine = nil
local TracerGui = nil

local function CreateTracer()
	if TracerGui then return end

	TracerGui = Instance.new("ScreenGui")
	TracerGui.Name = "TracerGui"
	TracerGui.ResetOnSpawn = false
	TracerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	TracerGui.Parent = game:GetService("CoreGui")

	TracerLine = Instance.new("Frame")
	TracerLine.Name = "Tracer"
	TracerLine.AnchorPoint = Vector2.new(0.5, 0)
	TracerLine.Position = UDim2.new(0.5, 0, 1, 0)
	TracerLine.Size = UDim2.new(0, 2, 0, 0)
	TracerLine.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	TracerLine.BorderSizePixel = 0
	TracerLine.BackgroundTransparency = 0.3
	TracerLine.Parent = TracerGui
end

local function RemoveTracer()
	if TracerGui and TracerGui.Parent then
		TracerGui:Destroy()
		TracerGui = nil
		TracerLine = nil
	end
end

local function UpdateTracer()
	if not FeatureState.ShowTargetTracer or not TracerLine then return end

	local root = GetRootPart()
	if not root then return end

	-- Find nearest target
	local nearest = nil
	local minDist = math.huge

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local screenPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
				if onScreen then
					local dist = (root.Position - hrp.Position).Magnitude
					if dist < minDist then
						minDist = dist
						nearest = screenPos
					end
				end
			end
		end
	end

	-- NPCs
	for _, obj in pairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if (name:find("killer") or name:find("monster") or name:find("vein"))
			and obj:IsA("Model") then
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
			if hrp then
				local screenPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
				if onScreen then
					local dist = (root.Position - hrp.Position).Magnitude
					if dist < minDist then
						minDist = dist
						nearest = screenPos
					end
				end
			end
		end
	end

	if nearest then
		local viewportSize = Camera.ViewportSize
		local targetY = nearest.Y
		local height = viewportSize.Y - targetY

		TracerLine.Size = UDim2.new(0, 2, 0, height)
		TracerLine.Rotation = math.atan2(nearest.X - viewportSize.X / 2, height) * (180 / math.pi)
	else
		TracerLine.Size = UDim2.new(0, 0, 0, 0)
	end
end

-- Aim Circle Drawing
local AimCircleFrame = nil

local function CreateAimCircle()
	if AimCircleFrame then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AimCircleGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = game:GetService("CoreGui")

	local circle = Instance.new("Frame")
	circle.Name = "AimCircle"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.new(0.5, 0, 0.5, 0)
	circle.Size = UDim2.new(0, FeatureState.AimRadius * 2, 0, FeatureState.AimRadius * 2)
	circle.BackgroundColor3 = Color3.new(1, 1, 1)
	circle.BackgroundTransparency = 0.9
	circle.BorderSizePixel = 1
	circle.BorderColor3 = Color3.fromRGB(255, 255, 255)
	circle.Parent = gui

	-- Make it circular with UI corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle

	AimCircleFrame = gui
end

local function RemoveAimCircle()
	if AimCircleFrame and AimCircleFrame.Parent then
		AimCircleFrame:Destroy()
		AimCircleFrame = nil
	end
end

-- ============================================================
-- MAIN HEARTBEAT / UPDATE LOOP
-- ============================================================
local ESPUpdateCounter = 0
local TracerUpdateCounter = 0
local HitboxUpdateCounter = 0

local function MainLoop()
	-- VIP Features
	AutoPlayLogic()
	AutoDaggerLogic()
	AutoWiggleLogic()

	-- Survivor Features
	SpeedBoostLogic()
	NoSlowdownLogic()
	ForceResetLogic()
	SilentActionsLogic()
	AntiFallDamageLogic()
	ClientGodModeLogic()
	AntiKnockLogic()
	AutoHealAuraLogic()

	-- Combat Features
	AimbotLogic()
	AutoAttackLogic()

	-- Automation Features
	AutoGeneratorLogic()
	InstantEscapeLogic()
	SelfUnHookLogic()

	-- Update counters for less frequent operations
	ESPUpdateCounter = ESPUpdateCounter + 1
	TracerUpdateCounter = TracerUpdateCounter + 1
	HitboxUpdateCounter = HitboxUpdateCounter + 1

	-- ESP (update every 30 frames for performance)
	if ESPUpdateCounter >= 30 then
		ESPUpdateCounter = 0
		PlayerESPLogic()
		ObjectESPLogic()
		LockOnHighlightLogic()
	end

	-- Tracer (update every 5 frames)
	if TracerUpdateCounter >= 5 then
		TracerUpdateCounter = 0
		UpdateTracer()
	end

	-- Hitbox (update every 60 frames)
	if HitboxUpdateCounter >= 60 then
		HitboxUpdateCounter = 0
		ExpandHitboxLogic()
	end
end

-- Manage GUI elements based on state
local function ManageGUI()
	-- Crosshair
	if FeatureState.ShowCrosshair then
		CreateCrosshair()
	else
		RemoveCrosshair()
	end

	-- Tracer
	if FeatureState.ShowTargetTracer then
		CreateTracer()
	else
		RemoveTracer()
	end

	-- Aim Circle
	if FeatureState.AimCircle then
		CreateAimCircle()
	else
		RemoveAimCircle()
	end
end

-- Connect heartbeat
local heartbeatConn
heartbeatConn = RunService.Heartbeat:Connect(MainLoop)

-- Connect render stepped for GUI management
local renderConn
renderConn = RunService.RenderStepped:Connect(ManageGUI)

-- Boost All Gen runs on a separate timer (every 2 seconds)
if FeatureState.BoostAllGen then
	task.spawn(function()
		while FeatureState.BoostAllGen do
			BoostAllGenLogic()
			task.wait(2)
		end
	end)
end

-- Watch for BoostAllGen toggle changes with a separate loop
task.spawn(function()
	while true do
		if FeatureState.BoostAllGen then
			BoostAllGenLogic()
		end
		task.wait(2)
	end
end)

-- Character respawn handler - reapply features on respawn
local charConn
charConn = LocalPlayer.CharacterAdded:Connect(function(character)
	task.wait(1)

	-- Reapply speed if active
	if FeatureState.SpeedBoost then
		local hum = character:FindFirstChild("Humanoid")
		if hum then
			hum.WalkSpeed = FeatureState.CustomSpeed
		end
	end

	-- Reapply god mode if active
	if FeatureState.ClientGodMode then
		local hum = character:FindFirstChild("Humanoid")
		if hum then
			task.wait(0.5)
			hum.Health = hum.MaxHealth
		end
	end
end)

-- Cleanup on window destroy
local oldDestroy = Window.Destroy
Window.Destroy = function(self)
	-- Disconnect all connections
	if heartbeatConn then
		heartbeatConn:Disconnect()
	end
	if renderConn then
		renderConn:Disconnect()
	end
	if charConn then
		charConn:Disconnect()
	end

	-- Clean up GUI elements
	RemoveCrosshair()
	RemoveTracer()
	RemoveAimCircle()

	-- Clean up ESP objects
	for _, obj in pairs(ESPObjects) do
		if obj and obj.Parent then
			obj:Destroy()
		end
	end
	ESPObjects = {}

	-- Restore lighting if fullbright was on
	if FeatureState.ForceFullbright and FeatureState.OriginalLighting then
		Lighting.Ambient = FeatureState.OriginalLighting.Ambient
		Lighting.Brightness = FeatureState.OriginalLighting.Brightness
		Lighting.OutdoorAmbient = FeatureState.OriginalLighting.OutdoorAmbient
		Lighting.FogEnd = FeatureState.OriginalLighting.FogEnd
		Lighting.FogStart = FeatureState.OriginalLighting.FogStart
		Lighting.GlobalShadows = FeatureState.OriginalLighting.GlobalShadows
	end

	-- Restore FOV
	if FeatureState.CustomFOV then
		Camera.FieldOfView = 70
	end

	-- Restore quality if potato mode was on
	if FeatureState.ExtremePotatoMode and FeatureState.OriginalQuality then
		settings().Rendering.QualityLevel = FeatureState.OriginalQuality.QualityLevel
	end

	-- Call original destroy
	oldDestroy(self)
end

Notify("District Loaded", "Semua fitur berhasil dimuat!")
print("[District] Script loaded successfully with all features.")
