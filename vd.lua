--[[
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║             VIOLENCE DISTRICT HUB — WINDUI EDITION                         ║
    ║             (Distrik Kekerasan - Premium Script Hub)                       ║
    ║                                                                            ║
    ║  Tabs : VIP | Survivor | Killer | Visuals | Combat | Automation           ║
    ║  UI   : WindUI (Solar / Lucide icons, Acrylic, Theme support)             ║
    ║                                                                            ║
    ║  Keybinds                                                                   ║
    ║    RightCtrl  -> Toggle GUI                                               ║
    ║    H          -> Instant Heal                                             ║
    ║    R          -> Force Reset State                                        ║
    ║    G          -> Toggle God Mode                                          ║
    ║    T          -> Toggle FPP / TPP                                         ║
    ╚══════════════════════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════════════════════
--  WINDUI LOADER  (sama persis seperti template)
-- ═══════════════════════════════════════════════════════════════════════

local cloneref = cloneref or clonereference or function(instance)
	return instance
end

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService         = cloneref(game:GetService("RunService"))

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
--  WINDUI WINDOW
-- ═══════════════════════════════════════════════════════════════════════

local VersionSC = "VIP"

local Window = WindUI:CreateWindow({
	Title = "Violence District '" .. VersionSC .. "'",
	Author = "by Zetttify",
	Icon = "solar:compass-big-bold",
	Theme = "Dark",
	NewElements = true,
	Transparent = true,
	ToggleKey = Enum.KeyCode.RightControl,
	Acrylic = true,
	OpenButton = {
		Title = "OPEN MENU",
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3,
		Enabled = true,
		Draggable = true,
		OnlyMobile = false,
		Scale = 0.5,
		Color = ColorSequence.new(
			Color3.fromHex("#30FF6A"),
			Color3.fromHex("#e7ff2f")
		),
	},

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

	Topbar = {
		Height = 44,
		ButtonsType = "Mac",
	},
})

local Tag = Window:Tag({
	Title = "PREMIUM",
	Icon = "sfsymbols:starFill",
	IconSize = 22,
	Color = "Text",
})

-- Topbar: Unload button
Window.Topbar:Button({
	Name = "Unload Script",
	Icon = "solar:logout-3-bold",
	IconSize = 22,
	Callback = function()
		Window:Destroy()
	end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  TABS CREATION
-- ═══════════════════════════════════════════════════════════════════════

local TabVIP  = Window:Tab({ Title = "VIP",        Icon = "solar:crown-bold",             IconThemed = true })
local TabSurv = Window:Tab({ Title = "Survivor",   Icon = "solar:shield-bold",            IconThemed = true })
local TabKill = Window:Tab({ Title = "Killer",     Icon = "solar:danger-triangle-bold",   IconThemed = true })
local TabVis  = Window:Tab({ Title = "Visuals",    Icon = "solar:eye-bold",               IconThemed = true })
local TabComb = Window:Tab({ Title = "Combat",     Icon = "solar:target-bold",            IconThemed = true })
local TabAuto = Window:Tab({ Title = "Automation", Icon = "solar:settings-bold",          IconThemed = true })

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  TAB 1 — VIP (ULTIMATE AUTOMATIC)                                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

TabVIP:Select()

TabVIP:Section({
	Title = "VIP (Ultimate Automatic)",
	Desc = "Bot cerdas pencari Generator, Auto Parry, dan Wiggle Master",
	Icon = "solar:crown-bold",
	IconThemed = true,
})

TabVIP:Space({ Columns = 1 })
TabVIP:Toggle({
	Title = "Auto Play (Smart AI / AutoFarmBot)",
	Desc = "Bot cerdas otomatis cari Generator & Gate, kabur dari Killer",
	Icon = "solar:robot-bold",
	Value = false,
	Callback = function(v)
		Config.AutoPlay = v
		if v then WindUI:Notify({ Title = "Auto Play", Content = "Bot AI aktif — mencari Generator & kabur dari Killer" }) end
	end,
})

TabVIP:Space({ Columns = 1 })
TabVIP:Slider({
	Title = "Flee Distance",
	IsTooltip = true,
	Step = 5,
	Value = { Min = 20, Max = 80, Default = 40 },
	Icons = { From = "solar:running-2-bold", To = "solar:running-2-bold" },
	Callback = function(value) Config.AutoPlayFleeDist = value end,
})

TabVIP:Space({ Columns = 1 })
TabVIP:Toggle({
	Title = "Auto Dagger (Auto Parry)",
	Desc = "Menangkis serangan Killer secara instan dengan Parrying Dagger",
	Icon = "solar:shield-check-bold",
	Value = false,
	Callback = function(v)
		Config.AutoDagger = v
		if v then WindUI:Notify({ Title = "Auto Dagger", Content = "Auto Parry aktif!" }) end
	end,
})

TabVIP:Space({ Columns = 1 })
TabVIP:Slider({
	Title = "Dagger Parry Range",
	IsTooltip = true,
	Step = 5,
	Value = { Min = 10, Max = 100, Default = 30 },
	Icons = { From = "solar:minimize-bold", To = "solar:maximize-bold" },
	Callback = function(value) Config.AutoDaggerRange = value end,
})

TabVIP:Space({ Columns = 1 })
TabVIP:Toggle({
	Title = "Auto Wiggle Master",
	Desc = "Memberontak dan lepas dari panggulan Killer secara instan",
	Icon = "solar:hand-shake-bold",
	Value = false,
	Callback = function(v)
		Config.WiggleMaster = v
		if v then WindUI:Notify({ Title = "Wiggle Master", Content = "Lepas dari panggulan Killer instan!" }) end
	end,
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  TAB 2 — SURVIVOR (MOVEMENT & HEALTH)                                    ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

TabSurv:Select()

TabSurv:Section({
	Title = "Movement",
	Desc = "Kecepatan, anti-slowdown, dan anti-stuck",
	Icon = "solar:bolt-bold",
	IconThemed = true,
})

TabSurv:Space({ Columns = 1 })
TabSurv:Toggle({
	Title = "Speed Boost",
	Desc = "Menambah kecepatan lari sesuai slider",
	Icon = "solar:bolt-circle-bold",
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
TabSurv:Slider({
	Title = "Custom Speed",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 16, Max = 100, Default = 16 },
	Icons = { From = "solar:wind-bold", To = "solar:tornado-bold" },
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
	Desc = "Kebal terhadap semua efek perlambatan gerak",
	Icon = "solar:play-bold",
	Value = false,
	Callback = function(v)
		Config.NoSlowdown = v
		if v then WindUI:Notify({ Title = "No Slowdown", Content = "Kebal semua efek perlambatan!" }) end
	end,
})

TabSurv:Space({ Columns = 1 })
TabSurv:Button({
	Title = "Force Reset State (Anti-Stuck)",
	Justify = "Left",
	Icon = "solar:restart-circle-bold",
	IconAlign = "Left",
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

TabSurv:Space({ Columns = 2 })

local GrpSilent = TabSurv:Group()
GrpSilent:Toggle({
	Title = "Silent Actions",
	Desc = "Anti-Noise: berlari tanpa notifikasi ke Killer",
	Icon = "solar:volume-cross-bold",
	Value = false,
	Callback = function(v)
		Config.SilentActions = v
		if v then WindUI:Notify({ Title = "Silent Actions", Content = "Bergerak tanpa suara/visual ke Killer" }) end
	end,
})

local GrpFall = TabSurv:Group()
GrpFall:Toggle({
	Title = "Anti Fall Damage",
	Desc = "Mencegah damage & animasi kaku saat jatuh",
	Icon = "solar:shield-minimalistic-bold",
	Value = false,
	Callback = function(v)
		Config.AntiFallDamage = v
		if v then WindUI:Notify({ Title = "Anti Fall", Content = "Fall damage dinonaktifkan!" }) end
	end,
})

-- ── Survivor: Health & Defense ──

TabSurv:Section({
	Title = "Health & Defense",
	Desc = "God Mode, Heal, Anti Knock, dan Heal Aura",
	Icon = "solar:heart-pulse-bold",
	IconThemed = true,
})

TabSurv:Space({ Columns = 1 })
TabSurv:Toggle({
	Title = "Client God Mode (Beta)",
	Desc = "Memblokir pengiriman hit ke server (Damage Nullifier)",
	Icon = "solar:infinity-bold",
	Value = false,
	Callback = function(v)
		Config.GodMode = v
		if v then WindUI:Notify({ Title = "God Mode", Content = "Client God Mode aktif — HP selalu penuh!" }) end
	end,
})

TabSurv:Space({ Columns = 2 })

local GrpHeal = TabSurv:Group()
GrpHeal:Button({
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

local GrpKnock = TabSurv:Group()
GrpKnock:Toggle({
	Title = "Anti Knock",
	Desc = "Mencegah knocked down saat dipukul",
	Icon = "solar:shield-check-bold",
	Value = false,
	Callback = function(v)
		Config.AntiKnock = v
		if v then WindUI:Notify({ Title = "Anti Knock", Content = "Tidak bisa di-knock down!" }) end
	end,
})

TabSurv:Space({ Columns = 1 })
TabSurv:Toggle({
	Title = "Auto Heal Aura",
	Desc = "Menyembuhkan teman satu tim di sekitar secara otomatis",
	Icon = "solar:heart-bold",
	Value = false,
	Callback = function(v)
		Config.AutoHealAura = v
		if v then WindUI:Notify({ Title = "Heal Aura", Content = "Menyembuhkan tim secara otomatis!" }) end
	end,
})

TabSurv:Space({ Columns = 1 })
TabSurv:Slider({
	Title = "Heal Aura Range",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 10, Max = 50, Default = 25 },
	Icons = { From = "solar:minimize-bold", To = "solar:maximize-bold" },
	Callback = function(value) Config.HealAuraRange = value end,
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  TAB 3 — KILLER (VEIN KILLER MODIFICATION)                                ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

TabKill:Select()

TabKill:Section({
	Title = "Vein Spear",
	Desc = "Modifikasi tombak: Aimbot prediksi & No Gravity",
	Icon = "solar:bolt-bold",
	IconThemed = true,
})

TabKill:Space({ Columns = 1 })
TabKill:Toggle({
	Title = "Vein Spear: Drop Prediction",
	Desc = "Aimbot tombak otomatis mengarah sedikit ke atas untuk target jauh",
	Icon = "solar:target-bold",
	Value = false,
	Callback = function(v)
		Config.SpearDropPrediction = v
		if v then WindUI:Notify({ Title = "Spear Prediction", Content = "Drop compensation aktif!" }) end
	end,
})

TabKill:Space({ Columns = 1 })
TabKill:Toggle({
	Title = "Vein Spear: No Gravity",
	Desc = "Lemparan tombak terbang lurus tanpa terpengaruh gravitasi",
	Icon = "solar:rocket-2-bold",
	Value = false,
	Callback = function(v)
		Config.SpearNoGravity = v
		if v then WindUI:Notify({ Title = "No Gravity", Content = "Tombak terbang lurus!" }) end
	end,
})

TabKill:Section({
	Title = "Killer Defense",
	Desc = "Anti-Blind, Anti-Stun, dan Killer Power",
	Icon = "solar:shield-bold",
	IconThemed = true,
})

TabKill:Space({ Columns = 2 })

local GrpBlind = TabKill:Group()
GrpBlind:Toggle({
	Title = "Anti-Blind",
	Desc = "Kebal Fog & Flash",
	Icon = "solar:eye-closed-bold",
	Value = false,
	Callback = function(v)
		Config.AntiBlind = v
		if v then WindUI:Notify({ Title = "Anti-Blind", Content = "Kebal efek kabur & kilatan!" }) end
	end,
})

local GrpStun = TabKill:Group()
GrpStun:Toggle({
	Title = "Anti-Stun",
	Desc = "Kebal stun Pallet",
	Icon = "solar:shield-bold",
	Value = false,
	Callback = function(v)
		Config.AntiStun = v
		if v then WindUI:Notify({ Title = "Anti-Stun", Content = "Tidak bisa di-stun!" }) end
	end,
})

TabKill:Section({
	Title = "Generator Attack",
	Desc = "Kerusakan Generator berlipat dan Activate Power",
	Icon = "solar:bomb-bold",
	IconThemed = true,
})

TabKill:Space({ Columns = 1 })
TabKill:Toggle({
	Title = "Double Damage Generator",
	Desc = "Menendang generator berkali-kali dalam satu klik (Multiplier)",
	Icon = "solar:bolt-circle-bold",
	Value = false,
	Callback = function(v)
		Config.DoubleDamageGen = v
		if v then WindUI:Notify({ Title = "Double Damage", Content = "Generator damage multiplier aktif!" }) end
	end,
})

TabKill:Space({ Columns = 1 })
TabKill:Slider({
	Title = "Gen Damage Multiplier",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 2, Max = 10, Default = 3 },
	Icons = { From = "solar:bolt-bold", To = "solar:bolt-circle-bold" },
	Callback = function(value) Config.GenDamageMultiplier = value end,
})

TabKill:Space({ Columns = 1 })
TabKill:Button({
	Title = "Activate Killer Power",
	Justify = "Left",
	Icon = "solar:flash-bold",
	IconAlign = "Left",
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

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  TAB 4 — VISUALS (ESP & WORLD)                                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

TabVis:Select()

TabVis:Section({
	Title = "ESP System",
	Desc = "Player ESP (warna beda Survivor/Killer) dan Object ESP",
	Icon = "solar:eye-bold",
	IconThemed = true,
})

TabVis:Space({ Columns = 2 })

local GrpPESP = TabVis:Group()
GrpPESP:Toggle({
	Title = "Player ESP",
	Desc = "Lokasi Survivor (hijau) & Killer (merah) + jarak, status, nama",
	Icon = "solar:users-group-rounded-bold",
	Value = false,
	Callback = function(v)
		Config.PlayerESP = v
		if v then WindUI:Notify({ Title = "Player ESP", Content = "Menampilkan semua pemain!" }) end
	end,
})

local GrpOESP = TabVis:Group()
GrpOESP:Toggle({
	Title = "Object ESP",
	Desc = "Generator (%), Pallet, Exit Gate, dan Hook",
	Icon = "solar:box-bold",
	Value = false,
	Callback = function(v)
		Config.ObjectESP = v
		if v then WindUI:Notify({ Title = "Object ESP", Content = "Generator, Pallet, Gate, Hook terlihat!" }) end
	end,
})

TabVis:Section({
	Title = "Camera & Effects",
	Desc = "FOV, Crosshair, Fullbright, Potato Mode",
	Icon = "solar:camera-bold",
	IconThemed = true,
})

TabVis:Space({ Columns = 1 })
TabVis:Toggle({
	Title = "Enable Custom FOV",
	Desc = "Mengatur jarak pandang kamera sesuai keinginan",
	Icon = "solar:camera-bold",
	Value = false,
	Callback = function(v)
		Config.CustomFOV = v
		if v then Camera.FieldOfView = Config.FOVValue end
	end,
})

TabVis:Space({ Columns = 1 })
TabVis:Slider({
	Title = "FOV Value",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 30, Max = 120, Default = 70 },
	Icons = { From = "solar:eye-bold", To = "solar:eye-bold" },
	Callback = function(value)
		Config.FOVValue = value
		if Config.CustomFOV then Camera.FieldOfView = value end
	end,
})

TabVis:Space({ Columns = 1 })
TabVis:Toggle({
	Title = "Show Crosshair",
	Desc = "Menampilkan titik bidik di tengah layar",
	Icon = "solar:cross-circle-bold",
	Value = false,
	Callback = function(v) Config.ShowCrosshair = v end,
})

TabVis:Space({ Columns = 2 })

local GrpBlur = TabVis:Group()
GrpBlur:Toggle({
	Title = "Remove Blur & Bloom",
	Desc = "Matikan efek buram & pantulan cahaya",
	Icon = "solar:eye-closed-bold",
	Value = false,
	Callback = function(v)
		Config.RemoveBlurBloom = v
		if v then WindUI:Notify({ Title = "Effects Off", Content = "Blur & Bloom dimatikan!" }) end
	end,
})

local GrpBright = TabVis:Group()
GrpBright:Toggle({
	Title = "Force Fullbright",
	Desc = "Map terang tanpa bayangan",
	Icon = "solar:sun-2-bold",
	Value = false,
	Callback = function(v)
		Config.ForceFullbright = v
		if v then WindUI:Notify({ Title = "Fullbright", Content = "Map terang tanpa bayangan!" }) end
	end,
})

TabVis:Space({ Columns = 1 })
TabVis:Toggle({
	Title = "Extreme Potato Mode",
	Desc = "Menghapus semua tekstur & partikel untuk memaksimalkan FPS",
	Icon = "solar:monitor-smartphone-bold",
	Value = false,
	Callback = function(v)
		Config.PotatoMode = v
		if v then WindUI:Notify({ Title = "Potato Mode", Content = "FPS Maksimal — semua efek dimatikan!" }) end
	end,
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  TAB 5 — COMBAT (TARGETING SYSTEM)                                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

TabComb:Select()

TabComb:Section({
	Title = "Aimbot & Targeting",
	Desc = "Mengunci bidikan, tracer, dan highlight target",
	Icon = "solar:target-bold",
	IconThemed = true,
})

TabComb:Space({ Columns = 1 })
TabComb:Toggle({
	Title = "Enable Aimbot",
	Desc = "Mengunci bidikan kamera ke musuh terdekat (Aim Radius & Aim Circle)",
	Icon = "solar:target-bold",
	Value = false,
	Callback = function(v)
		Config.Aimbot = v
		if v then WindUI:Notify({ Title = "Aimbot", Content = "Mengunci musuh terdekat!" }) end
	end,
})

TabComb:Space({ Columns = 1 })
TabComb:Slider({
	Title = "Aim Radius",
	IsTooltip = true,
	Step = 10,
	Value = { Min = 50, Max = 500, Default = 200 },
	Icons = { From = "solar:minimize-bold", To = "solar:maximize-bold" },
	Callback = function(value) Config.AimRadius = value end,
})

TabComb:Space({ Columns = 2 })

local GrpTracer = TabComb:Group()
GrpTracer:Toggle({
	Title = "Show Target Tracer",
	Desc = "Garis laser merah ke target",
	Icon = "solar:linear-bold",
	Value = false,
	Callback = function(v) Config.ShowTargetTracer = v end,
})

local GrpLock = TabComb:Group()
GrpLock:Toggle({
	Title = "Lock-On Highlight",
	Desc = "Tubuh target bersinar Merah/Emas",
	Icon = "solar:star-bold",
	Value = false,
	Callback = function(v) Config.LockOnHighlight = v end,
})

TabComb:Section({
	Title = "Camera & Hitbox",
	Desc = "FPP/TPP Toggle, Expand Hitbox, dan Auto Attack",
	Icon = "solar:camera-rotate-bold",
	IconThemed = true,
})

TabComb:Space({ Columns = 1 })
TabComb:Button({
	Title = "FPP / TPP Toggle",
	Justify = "Left",
	Icon = "solar:camera-rotate-bold",
	IconAlign = "Left",
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

TabComb:Space({ Columns = 1 })
TabComb:Toggle({
	Title = "Expand Killer Hitbox",
	Desc = "Memperbesar ukuran tubuh Killer agar mudah dipukul/di-stun",
	Icon = "solar:maximize-square-bold",
	Value = false,
	Callback = function(v)
		Config.ExpandHitbox = v
		if v then WindUI:Notify({ Title = "Expand Hitbox", Content = "Hitbox Killer diperbesar!" }) end
	end,
})

TabComb:Space({ Columns = 1 })
TabComb:Toggle({
	Title = "Auto Attack",
	Desc = "Killer otomatis memukul musuh yang masuk jangkauan",
	Icon = "solar:sword-bold",
	Value = false,
	Callback = function(v)
		Config.AutoAttack = v
		if v then WindUI:Notify({ Title = "Auto Attack", Content = "Otomatis memukul musuh terdekat!" }) end
	end,
})

TabComb:Space({ Columns = 1 })
TabComb:Slider({
	Title = "Auto Attack Range",
	IsTooltip = true,
	Step = 1,
	Value = { Min = 3, Max = 25, Default = 8 },
	Icons = { From = "solar:minimize-bold", To = "solar:maximize-bold" },
	Callback = function(value) Config.AutoAttackRange = value end,
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  TAB 6 — AUTOMATION (GENERATOR & UTILITY)                                ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

TabAuto:Select()

TabAuto:Section({
	Title = "Generator",
	Desc = "Auto SkillCheck dan Boost semua Generator",
	Icon = "solar:bolt-circle-bold",
	IconThemed = true,
})

TabAuto:Space({ Columns = 1 })
TabAuto:Toggle({
	Title = "Auto Generator",
	Desc = "Menyelesaikan SkillCheck mesin secara otomatis (Perfect / Neutral)",
	Icon = "solar:bolt-bold",
	Value = false,
	Callback = function(v)
		Config.AutoGenerator = v
		if v then WindUI:Notify({ Title = "Auto Generator", Content = "SkillCheck otomatis: " .. Config.GenSkillCheckMode }) end
	end,
})

TabAuto:Space({ Columns = 2 })

local GrpPerfect = TabAuto:Group()
GrpPerfect:Button({
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

local GrpNeutral = TabAuto:Group()
GrpNeutral:Button({
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
TabAuto:Button({
	Title = "Boost All Gen (Group Project)",
	Justify = "Left",
	Icon = "solar:bolt-circle-bold",
	IconAlign = "Left",
	Callback = function()
		local generators = findPartsByName({ "generator", "gen" })
		if #generators > 0 then
			local remotes = findRemotes({ "Generator", "Progress", "Repair", "Fix" })
			for _, gen in pairs(generators) do
				gen:SetAttribute("Progress", 100)
				for _, remote in pairs(remotes) do
					pcall(function() remote:FireServer(gen, 100) end)
				end
			end
			WindUI:Notify({ Title = "Boost All Gen", Content = #generators .. " generator diproses!" })
		else
			WindUI:Notify({ Title = "Boost All Gen", Content = "Generator tidak ditemukan di map" })
		end
	end,
})

TabAuto:Section({
	Title = "Escape & UnHook",
	Desc = "Instant Escape dan Self UnHook 100%",
	Icon = "solar:exit-bold",
	IconThemed = true,
})

TabAuto:Space({ Columns = 1 })
TabAuto:Button({
	Title = "Instant Escape (Gate)",
	Justify = "Left",
	Icon = "solar:logout-3-bold",
	IconAlign = "Left",
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

TabAuto:Space({ Columns = 1 })
TabAuto:Toggle({
	Title = "Self UnHook (100%)",
	Desc = "Manipulasi peluang 100% agar pasti berhasil lepas dari gantungan",
	Icon = "solar:link-circle-bold",
	Value = false,
	Callback = function(v)
		Config.SelfUnHook = v
		if v then WindUI:Notify({ Title = "Self UnHook", Content = "100% lepas dari Hook!" }) end
	end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  KEMBALI KE TAB PERTAMA
-- ═══════════════════════════════════════════════════════════════════════
TabVIP:Select()

-- ═══════════════════════════════════════════════════════════════════════
--  CROSSHAIR OVERLAY  (manual overlay, bukan bagian WindUI)
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

		if n:find("generator") or (n:find("gen") and not n:find("region")) then
			objType, color = "Generator", ESP_COLORS.GenESP
		elseif n:find("pallet") then
			objType, color = "Pallet", ESP_COLORS.PalletESP
		elseif n:find("gate") or n:find("exit") then
			objType, color = "Exit Gate", ESP_COLORS.GateESP
		elseif n:find("hook") then
			objType, color = "Hook", ESP_COLORS.HookESP
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
		for _, obj in pairs(getCharacter():GetDescendants()) do
			if obj:IsA("NumberValue") and (obj.Name:lower():find("slow") or obj.Name:lower():find("speed")) then
				if obj.Value < 0 then obj.Value = 0 end
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

local lastObjESPRefresh = 0

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

	-- Object ESP
	if Config.ObjectESP then
		if now - lastObjESPRefresh > 5 or #ObjectESPTable == 0 then
			createObjectESP(); lastObjESPRefresh = now
		end
		for _, obj in pairs(ObjectESPTable) do
			if obj:IsA("BillboardGui") and obj.Parent then
				local lbl = obj:FindFirstChild("ObjLabel")
				local progress = obj.Parent:GetAttribute("Progress")
				if lbl and progress then lbl.Text = obj.Parent.Name .. " [" .. math.floor(progress) .. "%]" end
			end
		end
	elseif #ObjectESPTable > 0 then clearObjectESP() end

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

-- AUTO GENERATOR
spawn(function()
	while wait(0.15) do
		if not Config.AutoGenerator then continue end
		local root = getRootPart()
		if not root then continue end
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

-- BOOST ALL GEN (Continuous)
spawn(function()
	while wait(2) do
		if not Config.BoostAllGen then continue end
		local gens = findPartsByName({ "generator", "gen" })
		local rems = findRemotes({ "Generator", "Progress", "Repair", "Fix" })
		for _, gen in pairs(gens) do
			gen:SetAttribute("Progress", 100)
			for _, r in pairs(rems) do pcall(function() r:FireServer(gen, 100) end) end
		end
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

print("╔══════════════════════════════════════════════════╗")
print("║   VIOLENCE DISTRICT HUB — WINDUI EDITION        ║")
print("║                                                   ║")
print("║  Keybinds:                                        ║")
print("║    RightCtrl  -> Toggle GUI (default)             ║")
print("║    H          -> Instant Heal                     ║")
print("║    R          -> Force Reset State                ║")
print("║    G          -> Toggle God Mode                  ║")
print("║    T          -> Toggle FPP / TPP                 ║")
print("╚══════════════════════════════════════════════════╝")
