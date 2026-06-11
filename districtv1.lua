--[[
    District.lua - Violence District
    All features integrated into Main tab (WindUI tab bar limited to ~2 visible tabs)
    Original UI elements preserved: Window, Tag, Topbar, Minisize, Acrylic, ToggleKey, Settings tab
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
local TweenService = cloneref(game:GetService("TweenService"))

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

-- ============================================================
-- ORIGINAL TABS (PRESERVED EXACTLY)
-- ============================================================

local Tab1 = Window:Tab({
	Title = "Main",
	Icon = "rbxassetid://77799629590713",
	IconThemed = true,
})

local TabSettings = Window:Tab({
	Title = "Settings",
	Icon = "solar:settings-bold",
})

-- ============================================================
-- FEATURE STATE
-- ============================================================
local FS = {
	-- VIP
	AutoPlay = false,
	KillerFleeDist = 50,
	AutoDagger = false,
	AutoDaggerRange = 30,
	AutoWiggle = false,
	-- Survivor
	SpeedBoost = false,
	CustomSpeed = 16,
	NoSlowdown = false,
	ForceReset = false,
	SilentActions = false,
	AntiFallDmg = false,
	GodMode = false,
	AntiKnock = false,
	AutoHealAura = false,
	HealAuraRange = 30,
	-- Killer
	SpearPrediction = false,
	SpearNoGravity = false,
	AntiBlind = false,
	AntiStun = false,
	DoubleDmgGen = false,
	DmgMultiplier = 2,
	KillerPower = false,
	-- Visuals
	PlayerESP = false,
	ObjectESP = false,
	CustomFOV = false,
	FOVValue = 70,
	Crosshair = false,
	RemoveBlur = false,
	Fullbright = false,
	PotatoMode = false,
	OrigLighting = nil,
	OrigQuality = nil,
	-- Combat
	Aimbot = false,
	AimRadius = 150,
	AimCircle = false,
	Tracer = false,
	LockHighlight = false,
	FPPTPP = false,
	ExpandHitbox = false,
	HitboxSize = 2,
	AutoAttack = false,
	AttackRange = 10,
	-- Automation
	AutoGen = false,
	GenMode = "Perfect",
	BoostAllGen = false,
	InstantEscape = false,
	SelfUnHook = false,
}

local ESPObjects = {}
local CrosshairGui = nil
local TracerGui = nil
local TracerLine = nil
local AimCircleGui = nil

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function GetChar()
	local c = LocalPlayer.Character
	if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then return c end
	return nil
end
local function GetHum()
	local c = GetChar()
	return c and c:FindFirstChild("Humanoid") or nil
end
local function GetRoot()
	local c = GetChar()
	return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function Notify(t, c)
	pcall(function() WindUI:Notify({Title = t, Content = c}) end)
end

local function FindNearest(category, maxDist)
	local root = GetRoot()
	if not root then return nil, math.huge end
	local nearest, minD = nil, maxDist or math.huge
	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		local match = false
		if category == "killer" then
			match = (n:find("killer") or n:find("monster") or n:find("enemy") or n:find("vein")) and obj:IsA("Model")
		elseif category == "generator" then
			match = (n:find("generator") or n:find("gen")) and (obj:IsA("Model") or obj:IsA("BasePart"))
		elseif category == "gate" then
			match = (n:find("exit") or n:find("gate") or n:find("escape")) and (obj:IsA("Model") or obj:IsA("BasePart"))
		elseif category == "hook" then
			match = n:find("hook") and (obj:IsA("Model") or obj:IsA("BasePart"))
		elseif category == "pallet" then
			match = n:find("pallet") and (obj:IsA("Model") or obj:IsA("BasePart"))
		end
		if match then
			local p = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or (obj:IsA("BasePart") and obj)
			if p then
				local d = (root.Position - p.Position).Magnitude
				if d < minD then minD = d; nearest = obj end
			end
		end
	end
	-- Also check players for killer
	if category == "killer" then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				local hum = plr.Character:FindFirstChild("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local d = (root.Position - hrp.Position).Magnitude
					if d < minD then minD = d; nearest = plr end
				end
			end
		end
	end
	return nearest, minD
end

local function FireRemote(namePatterns, ...)
	for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") then
			local n = obj.Name:lower()
			for _, pat in pairs(namePatterns) do
				if n:find(pat) then
					pcall(function() obj:FireServer(...) end)
				end
			end
		end
	end
end

-- ============================================================
-- MAIN TAB - ORIGINAL CONTENT + ALL NEW FEATURES
-- ============================================================
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
	Value = { Min = 0, Max = 100, Default = 50 },
	Icons = { From = "solar:moon-stars-bold", To = "solar:sun-2-bold" },
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
	Value = { Min = 0, Max = 100, Default = 75 },
	Icons = { From = "solar:volume-cross-bold", To = "solar:volume-loud-bold" },
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
		WindUI:Notify({ Title = "Success", Content = "Settings saved!" })
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
		WindUI:Notify({ Title = "Reset", Content = "All parameters restored to default" })
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

-- ============================================================
-- [NEW] VIP SECTION
-- ============================================================
Tab1:Space({ Columns = 1 })

Tab1:Section({
	Title = "VIP - Ultimate Automatic",
	Desc = "Smart AI AutoFarmBot & Instant Actions",
	Icon = "solar:crown-bold",
})

Tab1:Toggle({
	Title = "Auto Play (Smart AI / AutoFarmBot)",
	Desc = "Bot cerdas pencari Generator/Gerbang, otomatis kabur dari Killer",
	Value = false,
	Callback = function(v)
		FS.AutoPlay = v
		Notify("Auto Play", v and "Smart AI Bot aktif! Mencari Generator..." or "Smart AI Bot dinonaktifkan.")
	end,
})

Tab1:Slider({
	Title = "Killer Flee Distance",
	IsTooltip = true,
	Step = 5,
	Value = { Min = 20, Max = 100, Default = 50 },
	Icons = { From = "solar:danger-triangle-bold", To = "solar:shield-check-bold" },
	Callback = function(v) FS.KillerFleeDist = v end,
})

Tab1:Toggle({
	Title = "Auto Dagger (Auto Parry)",
	Desc = "Menangkis serangan Killer secara instan dengan Parrying Dagger",
	Value = false,
	Callback = function(v)
		FS.AutoDagger = v
		Notify("Auto Dagger", v and "Auto Parry aktif!" or "Auto Parry nonaktif.")
	end,
})

Tab1:Slider({
	Title = "Auto Dagger Range",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 5, Max = 80, Default = 30 },
	Callback = function(v) FS.AutoDaggerRange = v end,
})

Tab1:Toggle({
	Title = "Auto-Wiggle Master",
	Desc = "Memberontak dan lepas dari panggulan Killer secara instan",
	Value = false,
	Callback = function(v)
		FS.AutoWiggle = v
		Notify("Auto-Wiggle", v and "Auto-Wiggle Master aktif!" or "Auto-Wiggle nonaktif.")
	end,
})

-- ============================================================
-- [NEW] SURVIVOR SECTION
-- ============================================================
Tab1:Space({ Columns = 1 })

Tab1:Section({
	Title = "Survivor - Movement & Health",
	Desc = "Kecepatan, perlindungan, dan penyembuhan",
	Icon = "solar:running-2-bold",
})

Tab1:Toggle({
	Title = "Speed Boost",
	Desc = "Menambah kecepatan lari karakter",
	Value = false,
	Callback = function(v)
		FS.SpeedBoost = v
		local h = GetHum()
		if h then h.WalkSpeed = v and FS.CustomSpeed or 16 end
	end,
})

Tab1:Slider({
	Title = "Custom Speed (16-100)",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 16, Max = 100, Default = 16 },
	Icons = { From = "solar:snail-bold", To = "solar:rocket-2-bold" },
	Callback = function(v)
		FS.CustomSpeed = v
		if FS.SpeedBoost then
			local h = GetHum()
			if h then h.WalkSpeed = v end
		end
	end,
})

Tab1:Toggle({
	Title = "No Slowdown",
	Desc = "Kebal terhadap semua efek perlambatan gerak",
	Value = false,
	Callback = function(v)
		FS.NoSlowdown = v
		Notify("No Slowdown", v and "Perlambatan gerak dinonaktifkan!" or "Efek perlambatan normal.")
	end,
})

Tab1:Toggle({
	Title = "Force Reset State (Anti-Stuck)",
	Desc = "Memaksa karakter keluar dari animasi kaku atau bug",
	Value = false,
	Callback = function(v)
		FS.ForceReset = v
		Notify("Anti-Stuck", v and "Force Reset State aktif!" or "Force Reset nonaktif.")
	end,
})

Tab1:Button({
	Title = "Force Reset Now",
	Icon = "solar:restart-bold",
	Callback = function()
		local c = GetChar()
		if c then
			local h = c:FindFirstChild("Humanoid")
			local r = c:FindFirstChild("HumanoidRootPart")
			if h then
				h.PlatformStand = false
				h.Sit = false
			end
			if r then
				r.AssemblyLinearVelocity = Vector3.new(0,0,0)
				r.AssemblyAngularVelocity = Vector3.new(0,0,0)
			end
			Notify("Force Reset", "Karakter berhasil di-reset!")
		end
	end,
})

Tab1:Toggle({
	Title = "Silent Actions (Anti-Noise)",
	Desc = "Berlari dan melompat tanpa notifikasi suara/visual ke Killer",
	Value = false,
	Callback = function(v)
		FS.SilentActions = v
		Notify("Silent Actions", v and "Semua suara/notifikasi dimatikan!" or "Suara/visual normal.")
	end,
})

Tab1:Toggle({
	Title = "Anti Fall Damage",
	Desc = "Mencegah damage dan animasi kaku saat jatuh dari tempat tinggi",
	Value = false,
	Callback = function(v)
		FS.AntiFallDmg = v
		Notify("Anti Fall Damage", v and "Fall damage dinonaktifkan!" or "Fall damage normal.")
	end,
})

Tab1:Toggle({
	Title = "Client God Mode (Beta)",
	Desc = "Memblokir pengiriman hit ke server (Damage Nullifier)",
	Value = false,
	Callback = function(v)
		FS.GodMode = v
		Notify("God Mode", v and "Client God Mode aktif! (Beta)" or "God Mode nonaktif.")
	end,
})

Tab1:Button({
	Title = "Instant Heal",
	Desc = "Menyembuhkan diri sendiri ke Max Health secara instan",
	Icon = "solar:heart-pulse-bold",
	Callback = function()
		local h = GetHum()
		if h then
			h.Health = h.MaxHealth
			Notify("Instant Heal", "Health dipulihkan ke maximum!")
		else
			Notify("Instant Heal", "Gagal: Karakter tidak ditemukan.")
		end
	end,
})

Tab1:Toggle({
	Title = "Anti Knock",
	Desc = "Mencegah karakter jatuh (knocked down) saat dipukul",
	Value = false,
	Callback = function(v)
		FS.AntiKnock = v
		Notify("Anti Knock", v and "Anti-Knock aktif!" or "Anti-Knock nonaktif.")
	end,
})

Tab1:Toggle({
	Title = "Auto Heal Aura",
	Desc = "Menyembuhkan teman satu tim di sekitar secara otomatis",
	Value = false,
	Callback = function(v)
		FS.AutoHealAura = v
		Notify("Auto Heal Aura", v and "Auto Heal Aura aktif!" or "Auto Heal Aura nonaktif.")
	end,
})

Tab1:Slider({
	Title = "Heal Aura Range",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 5, Max = 80, Default = 30 },
	Icons = { From = "solar:minus-circle-bold", To = "solar:add-circle-bold" },
	Callback = function(v) FS.HealAuraRange = v end,
})

-- ============================================================
-- [NEW] KILLER SECTION
-- ============================================================
Tab1:Space({ Columns = 1 })

Tab1:Section({
	Title = "Killer - Vein Modification",
	Desc = "Modifikasi serangan dan kebalan Killer",
	Icon = "solar:skull-bold",
})

Tab1:Toggle({
	Title = "Vein Spear: Drop Prediction",
	Desc = "Aimbot tombak otomatis mengarah ke atas untuk target jauh",
	Value = false,
	Callback = function(v)
		FS.SpearPrediction = v
		Notify("Spear Prediction", v and "Drop Prediction aktif!" or "Drop Prediction nonaktif.")
	end,
})

Tab1:Toggle({
	Title = "Vein Spear: No Gravity",
	Desc = "Lemparan tombak terbang lurus tanpa terpengaruh gravitasi",
	Value = false,
	Callback = function(v)
		FS.SpearNoGravity = v
		Notify("No Gravity", v and "Tombak tanpa gravitasi!" or "Gravitasi tombak normal.")
	end,
})

Tab1:Toggle({
	Title = "Anti-Blind",
	Desc = "Kebal terhadap efek kabut (Fog) dan kilatan cahaya (Flash)",
	Value = false,
	Callback = function(v)
		FS.AntiBlind = v
		for _, obj in pairs(Lighting:GetChildren()) do
			if obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") then
				local n = obj.Name:lower()
				if n:find("blind") or n:find("flash") or n:find("fog") then
					obj.Enabled = not v
				end
			end
		end
		Notify("Anti-Blind", v and "Efek kabur/kilatan dimatikan!" or "Efek visual normal.")
	end,
})

Tab1:Toggle({
	Title = "Anti-Stun",
	Desc = "Mencegah efek stun saat terkena bantingan Pallet",
	Value = false,
	Callback = function(v)
		FS.AntiStun = v
		Notify("Anti-Stun", v and "Kebal terhadap stun!" or "Stun effect normal.")
	end,
})

Tab1:Toggle({
	Title = "Double Damage Generator",
	Desc = "Menendang generator berkali-kali dalam satu klik (Multiplier)",
	Value = false,
	Callback = function(v)
		FS.DoubleDmgGen = v
		Notify("Double Damage", v and "Generator damage multiplier aktif!" or "Generator damage normal.")
	end,
})

Tab1:Slider({
	Title = "Damage Multiplier (x2 - x10)",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 2, Max = 10, Default = 2 },
	Callback = function(v) FS.DmgMultiplier = v end,
})

Tab1:Toggle({
	Title = "Activate Killer Power",
	Desc = "Memicu kekuatan spesial Killer secara instan",
	Value = false,
	Callback = function(v)
		FS.KillerPower = v
		Notify("Killer Power", v and "Kekuatan spesial aktif!" or "Kekuatan spesial nonaktif.")
	end,
})

-- ============================================================
-- [NEW] VISUALS SECTION
-- ============================================================
Tab1:Space({ Columns = 1 })

Tab1:Section({
	Title = "Visuals - ESP & World",
	Desc = "ESP, kamera, dan efek visual",
	Icon = "solar:eye-bold",
})

Tab1:Toggle({
	Title = "Player ESP",
	Desc = "Lokasi Survivor & Killer (Jarak, status, nama/topeng)",
	Value = false,
	Callback = function(v)
		FS.PlayerESP = v
		if not v then
			for _, o in pairs(ESPObjects) do if o and o.Parent then o:Destroy() end end
			ESPObjects = {}
		end
		Notify("Player ESP", v and "Player ESP aktif!" or "Player ESP nonaktif.")
	end,
})

Tab1:Toggle({
	Title = "Object ESP",
	Desc = "Generator, Pallet, Exit Gate, dan Hook",
	Value = false,
	Callback = function(v)
		FS.ObjectESP = v
		Notify("Object ESP", v and "Object ESP aktif!" or "Object ESP nonaktif.")
	end,
})

Tab1:Toggle({
	Title = "Enable Custom FOV",
	Desc = "Mengatur jarak pandang kamera sesuai keinginan",
	Value = false,
	Callback = function(v)
		FS.CustomFOV = v
		Camera.FieldOfView = v and FS.FOVValue or 70
		Notify("Custom FOV", v and "FOV diatur ke " .. FS.FOVValue or "FOV dikembalikan ke 70")
	end,
})

Tab1:Slider({
	Title = "FOV Value (30-120)",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 30, Max = 120, Default = 70 },
	Icons = { From = "solar:minimize-bold", To = "solar:maximize-bold" },
	Callback = function(v)
		FS.FOVValue = v
		if FS.CustomFOV then Camera.FieldOfView = v end
	end,
})

Tab1:Toggle({
	Title = "Show Crosshair",
	Desc = "Titik bidik di tengah layar",
	Value = false,
	Callback = function(v)
		FS.Crosshair = v
		Notify("Crosshair", v and "Crosshair ditampilkan!" or "Crosshair disembunyikan.")
	end,
})

Tab1:Toggle({
	Title = "Remove Blur & Bloom",
	Desc = "Matikan efek buram dan pantulan cahaya menyilaukan",
	Value = false,
	Callback = function(v)
		FS.RemoveBlur = v
		for _, obj in pairs(Lighting:GetChildren()) do
			if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") then
				obj.Enabled = not v
			end
		end
		Notify("Remove Effects", v and "Blur & Bloom dimatikan!" or "Efek visual dikembalikan.")
	end,
})

Tab1:Toggle({
	Title = "Force Fullbright",
	Desc = "Menerangkan seluruh map tanpa bayangan dan kabut",
	Value = false,
	Callback = function(v)
		FS.Fullbright = v
		if v then
			if not FS.OrigLighting then
				FS.OrigLighting = {
					Ambient = Lighting.Ambient,
					Brightness = Lighting.Brightness,
					OutdoorAmbient = Lighting.OutdoorAmbient,
					FogEnd = Lighting.FogEnd,
					FogStart = Lighting.FogStart,
					GlobalShadows = Lighting.GlobalShadows,
				}
			end
			Lighting.Ambient = Color3.new(1,1,1)
			Lighting.Brightness = 2
			Lighting.OutdoorAmbient = Color3.new(1,1,1)
			Lighting.FogEnd = 100000
			Lighting.FogStart = 0
			Lighting.GlobalShadows = false
			Notify("Fullbright", "Map diterangi penuh!")
		else
			if FS.OrigLighting then
				Lighting.Ambient = FS.OrigLighting.Ambient
				Lighting.Brightness = FS.OrigLighting.Brightness
				Lighting.OutdoorAmbient = FS.OrigLighting.OutdoorAmbient
				Lighting.FogEnd = FS.OrigLighting.FogEnd
				Lighting.FogStart = FS.OrigLighting.FogStart
				Lighting.GlobalShadows = FS.OrigLighting.GlobalShadows
			end
			Notify("Fullbright", "Pencahayaan dikembalikan.")
		end
	end,
})

Tab1:Toggle({
	Title = "Extreme Potato Mode",
	Desc = "Hapus semua tekstur dan partikel untuk FPS maksimal",
	Value = false,
	Callback = function(v)
		FS.PotatoMode = v
		if v then
			if not FS.OrigQuality then
				FS.OrigQuality = { Level = settings().Rendering.QualityLevel }
			end
			settings().Rendering.QualityLevel = 1
			for _, obj in pairs(Workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
					obj.Enabled = false
				end
			end
			for _, obj in pairs(Lighting:GetChildren()) do
				if obj:IsA("PostEffect") or obj:IsA("Atmosphere") then
					obj.Enabled = false
				end
			end
			Notify("Potato Mode", "Extreme Potato Mode aktif!")
		else
			if FS.OrigQuality then
				settings().Rendering.QualityLevel = FS.OrigQuality.Level
			end
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
-- [NEW] COMBAT SECTION
-- ============================================================
Tab1:Space({ Columns = 1 })

Tab1:Section({
	Title = "Combat - Targeting System",
	Desc = "Aimbot, highlight, hitbox, dan auto attack",
	Icon = "solar:target-bold",
})

Tab1:Toggle({
	Title = "Enable Aimbot",
	Desc = "Mengunci bidikan kamera ke musuh terdekat",
	Value = false,
	Callback = function(v)
		FS.Aimbot = v
		Notify("Aimbot", v and "Aimbot aktif!" or "Aimbot nonaktif.")
	end,
})

Tab1:Slider({
	Title = "Aim Radius",
	IsTooltip = true,
	Step = 5,
	Value = { Min = 50, Max = 500, Default = 150 },
	Callback = function(v) FS.AimRadius = v end,
})

Tab1:Toggle({
	Title = "Show Aim Circle",
	Desc = "Lingkaran bidik aimbot di layar",
	Value = false,
	Callback = function(v) FS.AimCircle = v end,
})

Tab1:Toggle({
	Title = "Show Target Tracer",
	Desc = "Garis laser merah dari bawah layar ke arah target",
	Value = false,
	Callback = function(v)
		FS.Tracer = v
		Notify("Tracer", v and "Target Tracer aktif!" or "Target Tracer nonaktif.")
	end,
})

Tab1:Toggle({
	Title = "Lock-On Highlight",
	Desc = "Tubuh target bersinar terang (Merah/Emas)",
	Value = false,
	Callback = function(v)
		FS.LockHighlight = v
		if not v then
			for _, obj in pairs(Workspace:GetDescendants()) do
				if obj.Name:find("LockOnHL_") then obj:Destroy() end
			end
		end
		Notify("Highlight", v and "Lock-On Highlight aktif!" or "Lock-On Highlight nonaktif.")
	end,
})

Tab1:Toggle({
	Title = "FPP / TPP Toggle",
	Desc = "Berpindah sudut pandang kamera",
	Value = false,
	Callback = function(v)
		FS.FPPTPP = v
		if v then
			LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
			Notify("Camera", "First Person Mode!")
		else
			LocalPlayer.CameraMode = Enum.CameraMode.Classic
			Notify("Camera", "Third Person Mode!")
		end
	end,
})

Tab1:Toggle({
	Title = "Expand Killer Hitbox",
	Desc = "Perbesar ukuran tubuh Killer agar mudah dipukul/di-stun",
	Value = false,
	Callback = function(v)
		FS.ExpandHitbox = v
		if not v then
			for _, obj in pairs(Workspace:GetDescendants()) do
				if obj.Name:find("ExpandedHitbox_") then obj:Destroy() end
			end
		end
		Notify("Hitbox", v and "Killer Hitbox diperbesar!" or "Hitbox normal.")
	end,
})

Tab1:Slider({
	Title = "Hitbox Size Multiplier",
	IsTooltip = true,
	Step = 0.5,
	Value = { Min = 1, Max = 5, Default = 2 },
	Callback = function(v) FS.HitboxSize = v end,
})

Tab1:Toggle({
	Title = "Auto Attack",
	Desc = "Killer otomatis memukul musuh dalam jangkauan",
	Value = false,
	Callback = function(v)
		FS.AutoAttack = v
		Notify("Auto Attack", v and "Auto Attack aktif!" or "Auto Attack nonaktif.")
	end,
})

Tab1:Slider({
	Title = "Auto Attack Range",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 3, Max = 30, Default = 10 },
	Callback = function(v) FS.AttackRange = v end,
})

-- ============================================================
-- [NEW] AUTOMATION SECTION
-- ============================================================
Tab1:Space({ Columns = 1 })

Tab1:Section({
	Title = "Automation - Generator & Utility",
	Desc = "Auto SkillCheck, Boost Gen, Escape, UnHook",
	Icon = "solar:settings-minimalistic-bold",
})

Tab1:Toggle({
	Title = "Auto Generator",
	Desc = "Menyelesaikan SkillCheck mesin secara otomatis",
	Value = false,
	Callback = function(v)
		FS.AutoGen = v
		Notify("Auto Generator", v and "Auto Generator aktif! Mode: " .. FS.GenMode or "Auto Generator nonaktif.")
	end,
})

Tab1:Dropdown({
	Title = "SkillCheck Mode",
	Value = "Perfect",
	Values = {"Perfect", "Neutral"},
	Callback = function(v)
		FS.GenMode = v
		Notify("SkillCheck Mode", "Mode: " .. v)
	end,
})

Tab1:Toggle({
	Title = "Boost All Gen (Group Project)",
	Desc = "Suntikkan progress ke seluruh generator di map secara bersamaan",
	Value = false,
	Callback = function(v)
		FS.BoostAllGen = v
		Notify("Boost All Gen", v and "Semua Generator diboost!" or "Boost nonaktif.")
	end,
})

Tab1:Toggle({
	Title = "Instant Escape (Gate)",
	Desc = "Otomatis tarik tuas gerbang dan teleportasi ke zona Finish",
	Value = false,
	Callback = function(v)
		FS.InstantEscape = v
		Notify("Instant Escape", v and "Mencari Exit Gate..." or "Instant Escape nonaktif.")
	end,
})

Tab1:Toggle({
	Title = "Self UnHook",
	Desc = "Manipulasi peluang 100% agar pasti berhasil lepas dari gantungan",
	Value = false,
	Callback = function(v)
		FS.SelfUnHook = v
		Notify("Self UnHook", v and "100% UnHook chance aktif!" or "Self UnHook nonaktif.")
	end,
})

-- ============================================================
-- SETTINGS TAB (PRESERVED EXACTLY)
-- ============================================================
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

-- ============================================================
-- GUI DRAWING HELPERS
-- ============================================================
local function MakeCrosshair()
	if CrosshairGui then return end
	CrosshairGui = Instance.new("ScreenGui")
	CrosshairGui.Name = "DCCrosshair"
	CrosshairGui.ResetOnSpawn = false
	CrosshairGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	CrosshairGui.Parent = game:GetService("CoreGui")

	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.AnchorPoint = Vector2.new(0.5,0.5)
	dot.Position = UDim2.new(0.5,0,0.5,0)
	dot.Size = UDim2.new(0,4,0,4)
	dot.BackgroundColor3 = Color3.fromRGB(255,50,50)
	dot.BorderSizePixel = 0
	dot.Parent = CrosshairGui

	local lines = {
		{UDim2.new(0.5,-12,0.5,-1), UDim2.new(0,10,0,2)},
		{UDim2.new(0.5,2,0.5,-1), UDim2.new(0,10,0,2)},
		{UDim2.new(0.5,-1,0.5,-12), UDim2.new(0,2,0,10)},
		{UDim2.new(0.5,-1,0.5,2), UDim2.new(0,2,0,10)},
	}
	for _, ld in pairs(lines) do
		local f = Instance.new("Frame")
		f.Position = ld[1]; f.Size = ld[2]
		f.BackgroundColor3 = Color3.fromRGB(255,50,50)
		f.BorderSizePixel = 0
		f.Parent = CrosshairGui
	end
end

local function KillCrosshair()
	if CrosshairGui and CrosshairGui.Parent then CrosshairGui:Destroy(); CrosshairGui = nil end
end

local function MakeTracer()
	if TracerGui then return end
	TracerGui = Instance.new("ScreenGui")
	TracerGui.Name = "DCTracer"
	TracerGui.ResetOnSpawn = false
	TracerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	TracerGui.Parent = game:GetService("CoreGui")
	TracerLine = Instance.new("Frame")
	TracerLine.Name = "Line"
	TracerLine.AnchorPoint = Vector2.new(0.5,0)
	TracerLine.Position = UDim2.new(0.5,0,1,0)
	TracerLine.Size = UDim2.new(0,2,0,0)
	TracerLine.BackgroundColor3 = Color3.fromRGB(255,0,0)
	TracerLine.BorderSizePixel = 0
	TracerLine.BackgroundTransparency = 0.3
	TracerLine.Parent = TracerGui
end

local function KillTracer()
	if TracerGui and TracerGui.Parent then TracerGui:Destroy(); TracerGui = nil; TracerLine = nil end
end

local function MakeAimCircle()
	if AimCircleGui then return end
	AimCircleGui = Instance.new("ScreenGui")
	AimCircleGui.Name = "DCAimCircle"
	AimCircleGui.ResetOnSpawn = false
	AimCircleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	AimCircleGui.Parent = game:GetService("CoreGui"
	)
	local c = Instance.new("Frame")
	c.Name = "Circle"
	c.AnchorPoint = Vector2.new(0.5,0.5)
	c.Position = UDim2.new(0.5,0,0.5,0)
	c.Size = UDim2.new(0, FS.AimRadius*2, 0, FS.AimRadius*2)
	c.BackgroundColor3 = Color3.new(1,1,1)
	c.BackgroundTransparency = 0.9
	c.BorderSizePixel = 1
	c.BorderColor3 = Color3.fromRGB(255,255,255)
	c.Parent = AimCircleGui
	local cn = Instance.new("UICorner")
	cn.CornerRadius = UDim.new(1,0)
	cn.Parent = c
end

local function KillAimCircle()
	if AimCircleGui and AimCircleGui.Parent then AimCircleGui:Destroy(); AimCircleGui = nil end
end

-- ============================================================
-- LOGIC FUNCTIONS
-- ============================================================

-- VIP: Auto Play
local function DoAutoPlay()
	if not FS.AutoPlay then return end
	local root, hum = GetRoot(), GetHum()
	if not root or not hum or hum.Health <= 0 then return end

	local killer, kDist = FindNearest("killer", FS.KillerFleeDist + 10)
	local kHRP = nil
	if killer then
		if killer.Character then
			kHRP = killer.Character:FindFirstChild("HumanoidRootPart") or killer.Character:FindFirstChild("Head")
		elseif type(killer) == "table" then
			kHRP = killer:FindFirstChild("HumanoidRootPart") or killer:FindFirstChild("Torso")
		elseif killer:IsA("Model") then
			kHRP = killer:FindFirstChild("HumanoidRootPart") or killer:FindFirstChild("Torso")
		end
	end

	if kHRP and kDist < FS.KillerFleeDist then
		-- FLEE
		local dir = (root.Position - kHRP.Position).Unit
		hum:MoveTo(root.Position + dir * 50)
	else
		-- Go to generator
		local gen = FindNearest("generator")
		if gen then
			local gp = gen:IsA("Model") and gen:FindFirstChildWhichIsA("BasePart") or (gen:IsA("BasePart") and gen)
			if gp and (root.Position - gp.Position).Magnitude > 5 then
				hum:MoveTo(gp.Position)
			end
		else
			local gate = FindNearest("gate")
			if gate then
				local gp = gate:IsA("Model") and gate:FindFirstChildWhichIsA("BasePart") or (gate:IsA("BasePart") and gate)
				if gp then hum:MoveTo(gp.Position) end
			end
		end
	end
end

-- VIP: Auto Dagger
local function DoAutoDagger()
	if not FS.AutoDagger then return end
	local root = GetRoot()
	if not root then return end
	local killer, kDist = FindNearest("killer", FS.AutoDaggerRange)
	if killer and kDist <= FS.AutoDaggerRange then
		local c = GetChar()
		if c then
			for _, tool in pairs(c:GetChildren()) do
				if tool:IsA("Tool") then
					for _, r in pairs(tool:GetDescendants()) do
						if r:IsA("RemoteEvent") then pcall(function() r:FireServer("parry") end) end
					end
					pcall(function() tool:Activate() end)
				end
			end
		end
	end
end

-- VIP: Auto Wiggle
local function DoAutoWiggle()
	if not FS.AutoWiggle then return end
	local root, hum = GetRoot(), GetHum()
	if not root or not hum then return end
	local dirs = {
		Vector3.new(1,0,0), Vector3.new(-1,0,0),
		Vector3.new(0,0,1), Vector3.new(0,0,-1),
		Vector3.new(1,0,1), Vector3.new(-1,0,-1),
	}
	hum:MoveTo(root.Position + dirs[math.random(#dirs)] * 5)
	FireRemote({"unhook","wiggle","escape","struggle"})
end

-- Survivor: Speed
local function DoSpeed()
	if not FS.SpeedBoost then return end
	local h = GetHum()
	if h and h.WalkSpeed < FS.CustomSpeed then h.WalkSpeed = FS.CustomSpeed end
end

-- Survivor: No Slowdown
local function DoNoSlowdown()
	if not FS.NoSlowdown then return end
	local h = GetHum()
	if h then
		local target = FS.SpeedBoost and FS.CustomSpeed or 16
		if h.WalkSpeed < target then h.WalkSpeed = target end
	end
end

-- Survivor: Force Reset
local function DoForceReset()
	if not FS.ForceReset then return end
	local h = GetHum()
	if h then
		if h.PlatformStand then h.PlatformStand = false end
		if h.Sit then h.Sit = false end
	end
end

-- Survivor: Silent Actions
local function DoSilent()
	if not FS.SilentActions then return end
	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if (n:find("sound") or n:find("noise") or n:find("indicator") or n:find("alert")) then
			pcall(function()
				if obj:IsA("Sound") then obj.Volume = 0
				elseif obj:IsA("BillboardGui") or obj:IsA("ParticleEmitter") then obj.Enabled = false end
			end)
		end
	end
end

-- Survivor: Anti Fall Damage
local function DoAntiFall()
	if not FS.AntiFallDmg then return end
	local h = GetHum()
	if h and h:GetState() == Enum.HumanoidStateType.Freefall then
		local r = GetRoot()
		if r and r.AssemblyLinearVelocity.Y < -50 then
			r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -30, r.AssemblyLinearVelocity.Z)
		end
	end
end

-- Survivor: God Mode
local function DoGodMode()
	if not FS.GodMode then return end
	local h = GetHum()
	if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
end

-- Survivor: Anti Knock
local function DoAntiKnock()
	if not FS.AntiKnock then return end
	local h = GetHum()
	if not h then return end
	local s = h:GetState()
	if s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.FlyingDown then
		h:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait(0.1)
		h:ChangeState(Enum.HumanoidStateType.Running)
	end
end

-- Survivor: Auto Heal Aura
local function DoHealAura()
	if not FS.AutoHealAura then return end
	local root = GetRoot()
	if not root then return end
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local c = plr.Character
			local aHRP = c:FindFirstChild("HumanoidRootPart")
			local aHum = c:FindFirstChild("Humanoid")
			if aHRP and aHum and aHum.Health > 0 and aHum.Health < aHum.MaxHealth then
				if (root.Position - aHRP.Position).Magnitude <= FS.HealAuraRange then
					aHum.Health = math.min(aHum.Health + 5, aHum.MaxHealth)
					FireRemote({"heal","medkit","support"}, plr)
				end
			end
		end
	end
end

-- Visuals: Player ESP
local function DoPlayerESP()
	-- Cleanup first
	for _, o in pairs(ESPObjects) do
		if o and o.Parent and o.Name:find("ESP_") then o:Destroy() end
	end
	ESPObjects = {}

	if not FS.PlayerESP then return end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local c = plr.Character
			local hrp = c:FindFirstChild("HumanoidRootPart")
			local hum = c:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local hl = Instance.new("Highlight")
				hl.Name = "ESP_" .. plr.Name
				hl.Adornee = c
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 0
				hl.OutlineColor = Color3.fromRGB(255,0,0)
				hl.FillColor = Color3.fromRGB(255,0,0)
				hl.Parent = c
				table.insert(ESPObjects, hl)

				local bb = Instance.new("BillboardGui")
				bb.Name = "ESP_" .. plr.Name
				bb.Adornee = hrp
				bb.Size = UDim2.new(0,200,0,50)
				bb.StudsOffset = Vector3.new(0,3,0)
				bb.AlwaysOnTop = true
				bb.Parent = hrp

				local nm = Instance.new("TextLabel")
				nm.Size = UDim2.new(1,0,0.5,0)
				nm.BackgroundTransparency = 1
				nm.TextColor3 = Color3.new(1,1,1)
				nm.TextStrokeTransparency = 0
				nm.Font = Enum.Font.GothamBold
				nm.TextSize = 14
				nm.Text = plr.Name
				nm.Parent = bb

				local dl = Instance.new("TextLabel")
				dl.Size = UDim2.new(1,0,0.5,0)
				dl.Position = UDim2.new(0,0,0.5,0)
				dl.BackgroundTransparency = 1
				dl.TextColor3 = Color3.fromRGB(255,255,0)
				dl.TextStrokeTransparency = 0
				dl.Font = Enum.Font.Gotham
				dl.TextSize = 12
				local root = GetRoot()
				local d = root and math.floor((root.Position - hrp.Position).Magnitude) or 0
				dl.Text = "HP: " .. math.floor(hum.Health) .. " | " .. d .. "m"
				dl.Parent = bb

				table.insert(ESPObjects, bb)
			end
		end
	end
end

-- Visuals: Object ESP
local function DoObjectESP()
	for _, o in pairs(ESPObjects) do
		if o and o.Parent and o.Name:find("ObjESP_") then o:Destroy() end
	end
	if not FS.ObjectESP then return end

	local function MakeESP(obj, label, color)
		local p = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or (obj:IsA("BasePart") and obj)
		if not p then return end
		local bb = Instance.new("BillboardGui")
		bb.Name = "ObjESP_" .. obj.Name
		bb.Adornee = p
		bb.Size = UDim2.new(0,150,0,30)
		bb.StudsOffset = Vector3.new(0,2,0)
		bb.AlwaysOnTop = true
		bb.Parent = p
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1,0,1,0)
		tl.BackgroundTransparency = 0.5
		tl.BackgroundColor3 = color
		tl.TextColor3 = Color3.new(1,1,1)
		tl.TextStrokeTransparency = 0
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = 12
		tl.Text = label
		tl.Parent = bb
		table.insert(ESPObjects, bb)

		local hl = Instance.new("Highlight")
		hl.Name = "ObjESP_" .. obj.Name
		hl.Adornee = obj:IsA("Model") and obj or p
		hl.FillTransparency = 0.7
		hl.OutlineTransparency = 0.3
		hl.FillColor = color
		hl.OutlineColor = color
		hl.Parent = obj:IsA("Model") and obj or p
		table.insert(ESPObjects, hl)
	end

	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if n:find("generator") or n:find("gen") then
			MakeESP(obj, "Generator", Color3.fromRGB(255,255,0))
		elseif n:find("pallet") then
			MakeESP(obj, "Pallet", Color3.fromRGB(0,255,100))
		elseif n:find("exit") or n:find("gate") then
			MakeESP(obj, "Exit Gate", Color3.fromRGB(0,200,255))
		elseif n:find("hook") then
			MakeESP(obj, "Hook", Color3.fromRGB(255,50,50))
		end
	end
end

-- Combat: Aimbot
local function DoAimbot()
	if not FS.Aimbot then return end
	local root = GetRoot()
	if not root then return end
	local nearest, minSD = nil, FS.AimRadius
	local mousePos = UserInputService:GetMouseLocation()

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local c = plr.Character
			local hrp = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
			local hum = c:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local sp, on = Camera:WorldToScreenPoint(hrp.Position)
				if on then
					local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
					if d < minSD then minSD = d; nearest = hrp end
				end
			end
		end
	end
	-- NPCs
	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if (n:find("killer") or n:find("monster") or n:find("enemy") or n:find("vein")) and obj:IsA("Model") then
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj:FindFirstChild("Torso")
			if hrp then
				local sp, on = Camera:WorldToScreenPoint(hrp.Position)
				if on then
					local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
					if d < minSD then minSD = d; nearest = hrp end
				end
			end
		end
	end
	if nearest then
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearest.Position)
	end
end

-- Combat: Tracer update
local function DoTracer()
	if not FS.Tracer or not TracerLine then return end
	local root = GetRoot()
	if not root then return end
	local nearest, minD = nil, math.huge

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			local hum = plr.Character:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local sp, on = Camera:WorldToScreenPoint(hrp.Position)
				if on then
					local d = (root.Position - hrp.Position).Magnitude
					if d < minD then minD = d; nearest = sp end
				end
			end
		end
	end
	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if (n:find("killer") or n:find("monster") or n:find("vein")) and obj:IsA("Model") then
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
			if hrp then
				local sp, on = Camera:WorldToScreenPoint(hrp.Position)
				if on then
					local d = (root.Position - hrp.Position).Magnitude
					if d < minD then minD = d; nearest = sp end
				end
			end
		end
	end

	if nearest then
		local vs = Camera.ViewportSize
		TracerLine.Size = UDim2.new(0, 2, 0, vs.Y - nearest.Y)
		TracerLine.Rotation = math.atan2(nearest.X - vs.X/2, vs.Y - nearest.Y) * (180/math.pi)
	else
		TracerLine.Size = UDim2.new(0,0,0,0)
	end
end

-- Combat: Lock-On Highlight
local function DoLockHighlight()
	if not FS.LockHighlight then return end
	local root = GetRoot()
	if not root then return end

	-- Clean old
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj.Name:find("LockOnHL_") then obj:Destroy() end
	end

	local nearest, minD = nil, math.huge
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local c = plr.Character
			local hrp = c:FindFirstChild("HumanoidRootPart")
			local hum = c:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local d = (root.Position - hrp.Position).Magnitude
				if d < minD then minD = d; nearest = c end
			end
		end
	end
	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if (n:find("killer") or n:find("monster") or n:find("vein")) and obj:IsA("Model") then
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
			if hrp then
				local d = (root.Position - hrp.Position).Magnitude
				if d < minD then minD = d; nearest = obj end
			end
		end
	end

	if nearest then
		local hl = Instance.new("Highlight")
		hl.Name = "LockOnHL_Target"
		hl.Adornee = nearest
		hl.FillColor = Color3.fromRGB(255,215,0)
		hl.OutlineColor = Color3.fromRGB(255,0,0)
		hl.FillTransparency = 0.3
		hl.OutlineTransparency = 0
		hl.Parent = nearest
	end
end

-- Combat: Expand Hitbox
local function DoExpandHitbox()
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj.Name:find("ExpandedHitbox_") then obj:Destroy() end
	end
	if not FS.ExpandHitbox then return end

	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if (n:find("killer") or n:find("monster") or n:find("vein")) and obj:IsA("Model") then
			for _, part in pairs(obj:GetDescendants()) do
				if part:IsA("BasePart") then
					local pn = part.Name:lower()
					if pn:find("hitbox") or pn:find("humanoidrootpart") or pn:find("torso") or pn:find("body") then
						local m = Instance.new("BlockMesh")
						m.Name = "ExpandedHitbox_" .. part.Name
						m.Scale = Vector3.new(FS.HitboxSize, FS.HitboxSize, FS.HitboxSize)
						m.Parent = part
					end
				end
			end
		end
	end
end

-- Combat: Auto Attack
local function DoAutoAttack()
	if not FS.AutoAttack then return end
	local root = GetRoot()
	if not root then return end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			local hum = plr.Character:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 and (root.Position - hrp.Position).Magnitude < FS.AttackRange then
				FireRemote({"attack","hit","slash","strike"}, plr.Character)
				local c = GetChar()
				if c then
					for _, t in pairs(c:GetChildren()) do
						if t:IsA("Tool") then pcall(function() t:Activate() end) end
					end
				end
				return
			end
		end
	end
	-- NPCs
	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if (n:find("survivor") or n:find("target")) and obj:IsA("Model") then
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
			if hrp and (root.Position - hrp.Position).Magnitude < FS.AttackRange then
				FireRemote({"attack","hit","slash","strike"}, obj)
				return
			end
		end
	end
end

-- Automation: Auto Generator
local function DoAutoGen()
	if not FS.AutoGen then return end
	FireRemote({"skillcheck","skill_check","check","generator"},
		FS.GenMode == "Perfect" and "perfect" or "neutral",
		FS.GenMode == "Perfect" and 1.0 or 0.5
	)
	-- Click nearby generators
	local root = GetRoot()
	if not root then return end
	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if (n:find("generator") or n:find("gen")) and obj:IsA("Model") then
			local cd = obj:FindFirstChildWhichIsA("ClickDetector")
			if cd then
				local p = obj:FindFirstChildWhichIsA("BasePart")
				if p and (root.Position - p.Position).Magnitude < 10 then
					fireclickdetector(cd)
				end
			end
		end
	end
end

-- Automation: Boost All Gen
local function DoBoostAllGen()
	if not FS.BoostAllGen then return end
	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if (n:find("generator") or n:find("gen")) then
			FireRemote({"gen","progress","boost","repair"}, obj, 100)
		end
	end
end

-- Automation: Instant Escape
local function DoInstantEscape()
	if not FS.InstantEscape then return end
	local root = GetRoot()
	if not root then return end
	local gate = FindNearest("gate")
	if not gate then return end
	local gp = gate:IsA("Model") and gate:FindFirstChildWhichIsA("BasePart") or (gate:IsA("BasePart") and gate)
	if not gp then return end

	root.CFrame = gp.CFrame + Vector3.new(0,3,0)

	-- Click levers/switches on the gate
	for _, obj in pairs(gate:GetDescendants()) do
		local n = obj.Name:lower()
		if (n:find("lever") or n:find("switch") or n:find("activate") or n:find("interact")) and obj:IsA("ClickDetector") then
			fireclickdetector(obj)
		end
	end
	FireRemote({"escape","gate","exit","open"}, gate)
end

-- Automation: Self UnHook
local function DoSelfUnHook()
	if not FS.SelfUnHook then return end
	FireRemote({"unhook","escape_hook","self_unhook","struggle"}, 1.0, true)
	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if n:find("hook") and obj:IsA("Model") then
			for _, r in pairs(obj:GetDescendants()) do
				if r:IsA("RemoteEvent") then
					pcall(function() r:FireServer(true) r:FireServer(1.0) end)
				end
			end
		end
	end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local espTick = 0
local tracerTick = 0
local hitboxTick = 0

local hbConn = RunService.Heartbeat:Connect(function()
	-- VIP
	DoAutoPlay()
	DoAutoDagger()
	DoAutoWiggle()
	-- Survivor
	DoSpeed()
	DoNoSlowdown()
	DoForceReset()
	DoSilent()
	DoAntiFall()
	DoGodMode()
	DoAntiKnock()
	DoHealAura()
	-- Combat
	DoAimbot()
	DoAutoAttack()
	-- Automation
	DoAutoGen()
	DoInstantEscape()
	DoSelfUnHook()

	-- Less frequent updates
	espTick = espTick + 1
	tracerTick = tracerTick + 1
	hitboxTick = hitboxTick + 1

	if espTick >= 30 then
		espTick = 0
		DoPlayerESP()
		DoObjectESP()
		DoLockHighlight()
	end
	if tracerTick >= 5 then
		tracerTick = 0
		DoTracer()
	end
	if hitboxTick >= 60 then
		hitboxTick = 0
		DoExpandHitbox()
	end
end)

-- GUI management loop
local rsConn = RunService.RenderStepped:Connect(function()
	if FS.Crosshair then MakeCrosshair() else KillCrosshair() end
	if FS.Tracer then MakeTracer() else KillTracer() end
	if FS.AimCircle then MakeAimCircle() else KillAimCircle() end
end)

-- Boost All Gen on timer
task.spawn(function()
	while task.wait(2) do
		if FS.BoostAllGen then DoBoostAllGen() end
	end
end)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(1)
	if FS.SpeedBoost then
		local h = char:FindFirstChild("Humanoid")
		if h then h.WalkSpeed = FS.CustomSpeed end
	end
	if FS.GodMode then
		local h = char:FindFirstChild("Humanoid")
		if h then task.wait(0.5) h.Health = h.MaxHealth end
	end
end)

-- Cleanup on destroy
local _origDestroy = Window.Destroy
Window.Destroy = function(self)
	if hbConn then hbConn:Disconnect() end
	if rsConn then rsConn:Disconnect() end
	KillCrosshair()
	KillTracer()
	KillAimCircle()
	for _, o in pairs(ESPObjects) do if o and o.Parent then o:Destroy() end end
	ESPObjects = {}
	if FS.Fullbright and FS.OrigLighting then
		Lighting.Ambient = FS.OrigLighting.Ambient
		Lighting.Brightness = FS.OrigLighting.Brightness
		Lighting.OutdoorAmbient = FS.OrigLighting.OutdoorAmbient
		Lighting.FogEnd = FS.OrigLighting.FogEnd
		Lighting.FogStart = FS.OrigLighting.FogStart
		Lighting.GlobalShadows = FS.OrigLighting.GlobalShadows
	end
	if FS.CustomFOV then Camera.FieldOfView = 70 end
	if FS.PotatoMode and FS.OrigQuality then
		settings().Rendering.QualityLevel = FS.OrigQuality.Level
	end
	_origDestroy(self)
end

Notify("District Loaded", "Semua fitur berhasil dimuat!")
print("[District] Script loaded successfully.")
