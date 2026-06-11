local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local HttpService = cloneref(game:GetService("HttpService"))

-- ============================================================
-- WindUI Loader
-- ============================================================
local WindUI

do
	local ok, result = pcall(function()
		return require("./src/Init")
	end)

	if ok then
		WindUI = result
	else
		if cloneref(game:GetService("RunService")):IsStudio() then
			WindUI = require(cloneref(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init")))
		else
			WindUI =
				loadstring(game:HttpGet("https://raw.githubusercontent.com/FajarFnyaFerrary/District/main/dist/main.lua"))()
		end
	end
end

-- ============================================================
-- Window Setup
-- ============================================================
local Window = WindUI:CreateWindow({
	Title = "Zetttify | Violence District VFree",
	Folder = "ftgshub",
	Icon = "solar:folder-2-bold-duotone",
	NewElements = true,
	HideSearchBar = false,

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
		SaveKey = true,
	},

	Topbar = {
		Height = 44,
		ButtonsType = "Mac",
	},
})

-- ============================================================
-- Tag
-- ============================================================
do
	Window:Tag({
		Title = "v" .. WindUI.Version,
		Icon = "github",
		Color = Color3.fromHex("#1c1c1c"),
		Border = true,
	})
end

-- ============================================================
-- Colors
-- ============================================================
local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")
local Green = Color3.fromHex("#10C550")
local Grey = Color3.fromHex("#83889E")
local Blue = Color3.fromHex("#257AF7")
local Red = Color3.fromHex("#EF4F1D")
local Orange = Color3.fromHex("#FF8C00")
local White = Color3.fromHex("#FFFFFF")

-- ============================================================
-- ESP System
-- ============================================================
local ESPObjects = {} -- stores all Highlight instances for cleanup
local ESPConfig = {
	KillerESP = false,
	SurvivorESP = false,
	GeneratorESP = false,
	GateESP = false,
	HookESP = false,
	PalletESP = false,
	ShowOnlyClosestHook = false,
	ESPDistance = true,
	ESPName = true,
	CustomTransparency = 0.5,
}

local function clearESP(category)
	if ESPObjects[category] then
		for _, obj in ipairs(ESPObjects[category]) do
			if obj and obj.Parent then
				obj:Destroy()
			end
		end
		ESPObjects[category] = {}
	end
end

local function clearAllESP()
	for cat in pairs(ESPObjects) do
		clearESP(cat)
	end
end

local function createHighlight(instance, color, transparency, name)
	if not instance or not instance:IsA("Model") then return nil end
	if not instance:FindFirstChildOfClass("Highlight") then
		local hl = Instance.new("Highlight")
		hl.Name = "ESP_" .. (name or "Object")
		hl.Adornee = instance
		hl.FillColor = color
		hl.OutlineColor = color
		hl.FillTransparency = transparency or ESPConfig.CustomTransparency
		hl.OutlineTransparency = 0
		hl.Parent = instance
		return hl
	end
	return nil
end

-- Helper: get character from player
local function getCharacter(player)
	if player and player.Character then
		return player.Character
	end
	return nil
end

-- Helper: get humanoid root part position
local function getHRP(character)
	if character and character:FindFirstChild("HumanoidRootPart") then
		return character.HumanoidRootPart
	end
	return nil
end

-- Helper: get distance from local player to a position
local function getDistanceFromPlayer(position)
	local myChar = LocalPlayer.Character
	if myChar and myChar:FindFirstChild("HumanoidRootPart") then
		return (myChar.HumanoidRootPart.Position - position).Magnitude
	end
	return math.huge
end

-- Helper: format distance string
local function formatDistance(magnitude)
	return math.floor(magnitude) .. "m"
end

-- ============================================================
-- Drawing ESP (2D Billboard / Screen Labels)
-- ============================================================
local DrawingLabels = {}

local function clearDrawingLabels(category)
	if DrawingLabels[category] then
		for _, lbl in ipairs(DrawingLabels[category]) do
			if lbl then
				pcall(function() lbl:Remove() end)
			end
		end
		DrawingLabels[category] = {}
	end
end

local function clearAllDrawingLabels()
	for cat in pairs(DrawingLabels) do
		clearDrawingLabels(cat)
	end
end

local function createDrawingLabel(part, text, color)
	if not part or not Drawing then return nil end
	local label = Drawing.new("Text")
	label.Text = text
	label.Color = color
	label.Size = 13
	label.Center = true
	label.Outline = true
	label.OutlineColor = Color3.new(0, 0, 0)
	label.Position = Vector2.new(0, 0)
	label.Visible = false
	return label
end

-- ============================================================
-- ESP Update Loop (RenderStepped)
-- ============================================================
local function findGameObjects()
	local killers = {}
	local survivors = {}
	local generators = {}
	local gates = {}
	local hooks = {}
	local pallets = {}

	-- Find killer and survivor characters
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local char = player.Character
			-- Attempt to detect killer vs survivor via character attributes, tags, or names
			local isKiller = false

			-- Method 1: Check for "Killer" attribute/tag
			if char:FindFirstChild("Killer") or char:GetAttribute("IsKiller") then
				isKiller = true
			end

			-- Method 2: Check character name pattern
			if not isKiller then
				local charName = string.lower(char.Name)
				if charName:find("killer") or charName:find("slasher") then
					isKiller = true
				end
			end

			-- Method 3: Check humanoid role value
			if not isKiller and char:FindFirstChild("Humanoid") then
				local role = char.Humanoid:GetAttribute("Role")
				if role and (role == "Killer" or role == "Slayer") then
					isKiller = true
				end
			end

			-- Method 4: Check backpack / tools for killer-specific items
			if not isKiller then
				local backpack = player:FindFirstChild("Backpack")
				if backpack then
					for _, tool in ipairs(backpack:GetChildren()) do
						if tool:IsA("Tool") then
							local toolName = string.lower(tool.Name)
							if toolName:find("weapon") or toolName:find("knife") or toolName:find("blade") then
								isKiller = true
								break
							end
						end
					end
				end
			end

			if isKiller then
				table.insert(killers, char)
			else
				table.insert(survivors, char)
			end
		end
	end

	-- Also check NPCs for killer detection
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
			local model = obj.Parent
			if model:FindFirstChild("Killer") or model:GetAttribute("IsKiller") then
				local alreadyFound = false
				for _, k in ipairs(killers) do
					if k == model then
						alreadyFound = true
						break
					end
				end
				if not alreadyFound then
					table.insert(killers, model)
				end
			end
		end
	end

	-- Find generators, gates, hooks, pallets in workspace
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local name = string.lower(obj.Name)

			-- Generators
			if name:find("generator") or name:find("gen") or obj:GetAttribute("IsGenerator") then
				table.insert(generators, obj)
			end

			-- Gates / Exit Gates
			if name:find("gate") or name:find("exit") or name:find("door") or obj:GetAttribute("IsGate") then
				table.insert(gates, obj)
			end

			-- Hooks
			if name:find("hook") or obj:GetAttribute("IsHook") then
				table.insert(hooks, obj)
			end

			-- Pallets
			if name:find("pallet") or obj:GetAttribute("IsPallet") then
				table.insert(pallets, obj)
			end
		end
	end

	-- Also scan folders that may contain game objects
	local scanFolders = {
		workspace:FindFirstChild("Map"),
		workspace:FindFirstChild("GameMap"),
		workspace:FindFirstChild("Arena"),
	}
	for _, folder in ipairs(scanFolders) do
		if folder then
			for _, obj in ipairs(folder:GetDescendants()) do
				if obj:IsA("Model") then
					local name = string.lower(obj.Name)
					if name:find("generator") or name:find("gen") or obj:GetAttribute("IsGenerator") then
						local dup = false
						for _, g in ipairs(generators) do if g == obj then dup = true; break end end
						if not dup then table.insert(generators, obj) end
					end
					if name:find("gate") or name:find("exit") or obj:GetAttribute("IsGate") then
						local dup = false
						for _, g in ipairs(gates) do if g == obj then dup = true; break end end
						if not dup then table.insert(gates, obj) end
					end
					if name:find("hook") or obj:GetAttribute("IsHook") then
						local dup = false
						for _, h in ipairs(hooks) do if h == obj then dup = true; break end end
						if not dup then table.insert(hooks, obj) end
					end
					if name:find("pallet") or obj:GetAttribute("IsPallet") then
						local dup = false
						for _, p in ipairs(pallets) do if p == obj then dup = true; break end end
						if not dup then table.insert(pallets, obj) end
					end
				end
			end
		end
	end

	return killers, survivors, generators, gates, hooks, pallets
end

local espConnection = nil

local function updateESP()
	if espConnection then
		espConnection:Disconnect()
		espConnection = nil
	end

	espConnection = RunService.RenderStepped:Connect(function()
		local killers, survivors, generators, gates, hooks, pallets = findGameObjects()

		-- Killer ESP (Red)
		clearESP("Killer")
		if ESPConfig.KillerESP then
			for _, killer in ipairs(killers) do
				local hl = createHighlight(killer, Red, ESPConfig.CustomTransparency, "Killer")
				if hl then
					table.insert(ESPObjects["Killer"] or {}, hl)
				end
			end
		end

		-- Survivor ESP (Green)
		clearESP("Survivor")
		if ESPConfig.SurvivorESP then
			for _, survivor in ipairs(survivors) do
				local hl = createHighlight(survivor, Green, ESPConfig.CustomTransparency, "Survivor")
				if hl then
					table.insert(ESPObjects["Survivor"] or {}, hl)
				end
			end
		end

		-- Generator ESP (Orange)
		clearESP("Generator")
		if ESPConfig.GeneratorESP then
			for _, gen in ipairs(generators) do
				local hl = createHighlight(gen, Orange, ESPConfig.CustomTransparency, "Generator")
				if hl then
					table.insert(ESPObjects["Generator"] or {}, hl)
				end
			end
		end

		-- Gate ESP (White)
		clearESP("Gate")
		if ESPConfig.GateESP then
			for _, gate in ipairs(gates) do
				local hl = createHighlight(gate, White, ESPConfig.CustomTransparency, "Gate")
				if hl then
					table.insert(ESPObjects["Gate"] or {}, hl)
				end
			end
		end

		-- Hook ESP (Red) with closest-only option
		clearESP("Hook")
		if ESPConfig.HookESP then
			local hooksToShow = hooks
			if ESPConfig.ShowOnlyClosestHook then
				local myHRP = getHRP(LocalPlayer.Character)
				if myHRP then
					local closestHook = nil
					local closestDist = math.huge
					for _, hook in ipairs(hooks) do
						local hrp = getHRP(hook) or hook.PrimaryPart
						if hrp then
							local dist = (myHRP.Position - hrp.Position).Magnitude
							if dist < closestDist then
								closestDist = dist
								closestHook = hook
							end
						end
					end
					hooksToShow = closestHook and { closestHook } or {}
				end
			end
			for _, hook in ipairs(hooksToShow) do
				local hl = createHighlight(hook, Red, ESPConfig.CustomTransparency, "Hook")
				if hl then
					table.insert(ESPObjects["Hook"] or {}, hl)
				end
			end
		end

		-- Pallet ESP (Yellow)
		clearESP("Pallet")
		if ESPConfig.PalletESP then
			for _, pallet in ipairs(pallets) do
				local hl = createHighlight(pallet, Yellow, ESPConfig.CustomTransparency, "Pallet")
				if hl then
					table.insert(ESPObjects["Pallet"] or {}, hl)
				end
			end
		end
	end)
end

-- Start ESP loop
updateESP()

-- ============================================================
-- Teleport System
-- ============================================================
local function teleportTo(position)
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = CFrame.new(position)
	end
end

local function teleportToNearest(objectList)
	local myHRP = getHRP(LocalPlayer.Character)
	if not myHRP then return end
	local nearest = nil
	local nearestDist = math.huge
	for _, obj in ipairs(objectList) do
		local hrp = getHRP(obj) or obj.PrimaryPart
		if hrp then
			local dist = (myHRP.Position - hrp.Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = hrp
			end
		end
	end
	if nearest then
		teleportTo(nearest.Position + Vector3.new(0, 3, 0))
	end
end

local function getAllTeleportLocations()
	local locations = {}
	local myHRP = getHRP(LocalPlayer.Character)

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local name = string.lower(obj.Name)
			local hrp = getHRP(obj) or obj.PrimaryPart
			if hrp then
				if name:find("generator") or name:find("gen") or obj:GetAttribute("IsGenerator") then
					table.insert(locations, { Name = obj.Name, Type = "Generator", Position = hrp.Position })
				elseif name:find("gate") or name:find("exit") or name:GetAttribute("IsGate") then
					table.insert(locations, { Name = obj.Name, Type = "Gate", Position = hrp.Position })
				elseif name:find("hook") or obj:GetAttribute("IsHook") then
					table.insert(locations, { Name = obj.Name, Type = "Hook", Position = hrp.Position })
				elseif name:find("pallet") or obj:GetAttribute("IsPallet") then
					table.insert(locations, { Name = obj.Name, Type = "Pallet", Position = hrp.Position })
				end
			end
		end
	end

	-- Also add player positions
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local hrp = getHRP(player.Character)
			if hrp then
				table.insert(locations, { Name = player.Name, Type = "Player", Position = hrp.Position })
			end
		end
	end

	return locations
end

-- ============================================================
-- Gameplay Tools State
-- ============================================================
local GameplayState = {
	NoStun = false,
	InstantVault = false,
	AutoSkillCheck = false,
	AntiCamp = false,
	SpamVault = false,
	WalkSpeedBoost = false,
	CustomWalkSpeed = 20,
	JumpPowerBoost = false,
	CustomJumpPower = 70,
	Freecam = false,
	NoClip = false,
	InfiniteSprint = false,
}

-- Walk Speed
local walkSpeedConn = nil
local function applyWalkSpeed()
	if walkSpeedConn then walkSpeedConn:Disconnect() end
	if GameplayState.WalkSpeedBoost then
		walkSpeedConn = RunService.Heartbeat:Connect(function()
			local char = LocalPlayer.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.WalkSpeed = GameplayState.CustomWalkSpeed
			end
		end)
	end
end

-- Jump Power
local jumpPowerConn = nil
local function applyJumpPower()
	if jumpPowerConn then jumpPowerConn:Disconnect() end
	if GameplayState.JumpPowerBoost then
		jumpPowerConn = RunService.Heartbeat:Connect(function()
			local char = LocalPlayer.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.JumpPower = GameplayState.CustomJumpPower
			end
		end)
	end
end

-- NoClip
local noclipConn = nil
local function applyNoClip()
	if noclipConn then noclipConn:Disconnect() end
	if GameplayState.NoClip then
		noclipConn = RunService.Stepped:Connect(function()
			local char = LocalPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	end
end

-- Infinite Sprint
local sprintConn = nil
local function applyInfiniteSprint()
	if sprintConn then sprintConn:Disconnect() end
	if GameplayState.InfiniteSprint then
		sprintConn = RunService.Heartbeat:Connect(function()
			local char = LocalPlayer.Character
			if char and char:FindFirstChild("Humanoid") then
				-- Keep stamina / energy at max
				local humanoid = char.Humanoid
				if humanoid:GetAttribute("Stamina") ~= nil then
					humanoid:SetAttribute("Stamina", 100)
				end
				if humanoid:GetAttribute("Energy") ~= nil then
					humanoid:SetAttribute("Energy", 100)
				end
			end
		end)
	end
end

-- Freecam
local freecamConn = nil
local freecamActive = false
local freecamSpeed = 1
local freecamBody = nil

local function toggleFreecam()
	GameplayState.Freecam = not GameplayState.Freecam

	if GameplayState.Freecam then
		local char = LocalPlayer.Character
		if char then
			freecamBody = Instance.new("BodyVelocity")
			freecamBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			freecamBody.Velocity = Vector3.new(0, 0, 0)
			freecamBody.Parent = char:FindFirstChild("HumanoidRootPart")

			local gyro = Instance.new("BodyGyro")
			gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			gyro.P = 9e4
			gyro.Parent = char:FindFirstChild("HumanoidRootPart")

			freecamConn = RunService.RenderStepped:Connect(function()
				local camCF = Camera.CFrame
				local moveDir = Vector3.new(0, 0, 0)

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDir = moveDir + camCF.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDir = moveDir - camCF.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDir = moveDir - camCF.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDir = moveDir + camCF.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					moveDir = moveDir + Vector3.new(0, 1, 0)
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					moveDir = moveDir - Vector3.new(0, 1, 0)
				end

				if moveDir.Magnitude > 0 then
					moveDir = moveDir.Unit
				end

				if freecamBody then
					freecamBody.Velocity = moveDir * 50 * freecamSpeed
				end

				-- Camera follows character loosely
				local hrp = getHRP(char)
				if hrp then
					Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position)
				end
			end)

			WindUI:Notify({
				Title = "Freecam",
				Content = "Freecam enabled! WASD to move, Space/Shift for up/down.",
			})
		end
	else
		if freecamConn then
			freecamConn:Disconnect()
			freecamConn = nil
		end
		if freecamBody and freecamBody.Parent then
			freecamBody:Destroy()
			freecamBody = nil
		end
		local char = LocalPlayer.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				for _, child in ipairs(hrp:GetChildren()) do
					if child:IsA("BodyGyro") or child:IsA("BodyVelocity") then
						child:Destroy()
					end
				end
			end
		end

		WindUI:Notify({
			Title = "Freecam",
			Content = "Freecam disabled!",
		})
	end
end

-- ============================================================
-- TABS
-- ============================================================

-- ============================================================
-- ESP Tab
-- ============================================================
local ESPTab = Window:Tab({
	Title = "ESP",
	Icon = "solar:eye-bold",
	IconColor = Red,
	IconShape = "Square",
	Border = true,
})

do
	local MainSection = ESPTab:Section({
		Title = "Entity ESP",
	})

	MainSection:Toggle({
		Title = "Killer ESP",
		Desc = "Menampilkan posisi killer dengan highlight warna merah",
		Flag = "KillerESP",
		Value = false,
		Callback = function(v)
			ESPConfig.KillerESP = v
		end,
	})

	MainSection:Space()

	MainSection:Toggle({
		Title = "Survivor ESP",
		Desc = "Menampilkan posisi survivor dengan highlight warna hijau",
		Flag = "SurvivorESP",
		Value = false,
		Callback = function(v)
			ESPConfig.SurvivorESP = v
		end,
	})

	ESPTab:Space({ Columns = 2 })

	local MapSection = ESPTab:Section({
		Title = "Map ESP",
	})

	MapSection:Toggle({
		Title = "Generator ESP",
		Desc = "Menunjukkan lokasi generator yang tersedia di map",
		Flag = "GeneratorESP",
		Value = false,
		Callback = function(v)
			ESPConfig.GeneratorESP = v
		end,
	})

	MapSection:Space()

	MapSection:Toggle({
		Title = "Gate ESP",
		Desc = "Menampilkan posisi gate atau pintu keluar",
		Flag = "GateESP",
		Value = false,
		Callback = function(v)
			ESPConfig.GateESP = v
		end,
	})

	MapSection:Space()

	MapSection:Toggle({
		Title = "Hook ESP",
		Desc = "Menampilkan lokasi hook di area permainan",
		Flag = "HookESP",
		Value = false,
		Callback = function(v)
			ESPConfig.HookESP = v
		end,
	})

	MapSection:Space()

	MapSection:Toggle({
		Title = "Show Only Closest Hook",
		Desc = "Hanya menampilkan hook yang paling dekat dengan posisi player",
		Flag = "ShowOnlyClosestHook",
		Value = false,
		Callback = function(v)
			ESPConfig.ShowOnlyClosestHook = v
		end,
	})

	MapSection:Space()

	MapSection:Toggle({
		Title = "Pallet ESP",
		Desc = "Menunjukkan posisi pallet yang ada di map",
		Flag = "PalletESP",
		Value = false,
		Callback = function(v)
			ESPConfig.PalletESP = v
		end,
	})

	ESPTab:Space({ Columns = 2 })

	local SettingsSection = ESPTab:Section({
		Title = "ESP Settings",
	})

	SettingsSection:Slider({
		Title = "ESP Transparency",
		Desc = "Atur tingkat transparansi highlight ESP",
		Flag = "ESPTransparency",
		Step = 0.05,
		Value = {
			Min = 0.1,
			Max = 1.0,
			Default = 0.5,
		},
		Callback = function(value)
			ESPConfig.CustomTransparency = value
		end,
	})

	SettingsSection:Space()

	SettingsSection:Button({
		Title = "Clear All ESP",
		Desc = "Menghapus semua highlight ESP yang aktif",
		Color = Color3.fromHex("#ff4830"),
		Icon = "shredder",
		Callback = function()
			ESPConfig.KillerESP = false
			ESPConfig.SurvivorESP = false
			ESPConfig.GeneratorESP = false
			ESPConfig.GateESP = false
			ESPConfig.HookESP = false
			ESPConfig.PalletESP = false
			ESPConfig.ShowOnlyClosestHook = false
			clearAllESP()
			WindUI:Notify({
				Title = "ESP",
				Content = "Semua ESP telah dimatikan!",
			})
		end,
	})
end

-- ============================================================
-- Teleport Tab
-- ============================================================
local TeleportTab = Window:Tab({
	Title = "Teleport",
	Icon = "solar:map-point-bold",
	IconColor = Blue,
	IconShape = "Square",
	Border = true,
})

do
	local QuickSection = TeleportTab:Section({
		Title = "Quick Teleport",
	})

	QuickSection:Button({
		Title = "Teleport to Nearest Generator",
		Desc = "Teleport ke generator terdekat",
		Icon = "zap",
		Callback = function()
			local _, _, generators, _, _, _ = findGameObjects()
			if #generators > 0 then
				teleportToNearest(generators)
				WindUI:Notify({ Title = "Teleport", Content = "Teleported ke generator terdekat!" })
			else
				WindUI:Notify({ Title = "Teleport", Content = "Tidak ada generator ditemukan!" })
			end
		end,
	})

	QuickSection:Space()

	QuickSection:Button({
		Title = "Teleport to Nearest Gate",
		Desc = "Teleport ke gate/pintu keluar terdekat",
		Icon = "door-open",
		Callback = function()
			local _, _, _, gates, _, _ = findGameObjects()
			if #gates > 0 then
				teleportToNearest(gates)
				WindUI:Notify({ Title = "Teleport", Content = "Teleported ke gate terdekat!" })
			else
				WindUI:Notify({ Title = "Teleport", Content = "Tidak ada gate ditemukan!" })
			end
		end,
	})

	QuickSection:Space()

	QuickSection:Button({
		Title = "Teleport to Nearest Hook",
		Desc = "Teleport ke hook terdekat",
		Icon = "anchor",
		Callback = function()
			local _, _, _, _, hooks, _ = findGameObjects()
			if #hooks > 0 then
				teleportToNearest(hooks)
				WindUI:Notify({ Title = "Teleport", Content = "Teleported ke hook terdekat!" })
			else
				WindUI:Notify({ Title = "Teleport", Content = "Tidak ada hook ditemukan!" })
			end
		end,
	})

	QuickSection:Space()

	QuickSection:Button({
		Title = "Teleport to Nearest Pallet",
		Desc = "Teleport ke pallet terdekat",
		Icon = "box",
		Callback = function()
			local _, _, _, _, _, pallets = findGameObjects()
			if #pallets > 0 then
				teleportToNearest(pallets)
				WindUI:Notify({ Title = "Teleport", Content = "Teleported ke pallet terdekat!" })
			else
				WindUI:Notify({ Title = "Teleport", Content = "Tidak ada pallet ditemukan!" })
			end
		end,
	})

	TeleportTab:Space({ Columns = 2 })

	local PlayerTPSection = TeleportTab:Section({
		Title = "Teleport to Player",
	})

	-- Build player list dynamically
	local playerNames = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(playerNames, player.Name)
		end
	end

	PlayerTPSection:Dropdown({
		Title = "Select Player",
		Values = playerNames,
		Value = #playerNames > 0 and playerNames[1] or nil,
		Callback = function(selectedPlayer)
			local targetPlayer = Players:FindFirstChild(selectedPlayer)
			if targetPlayer and targetPlayer.Character then
				local hrp = getHRP(targetPlayer.Character)
				if hrp then
					teleportTo(hrp.Position + Vector3.new(0, 3, 0))
					WindUI:Notify({
						Title = "Teleport",
						Content = "Teleported ke " .. selectedPlayer .. "!",
					})
				end
			else
				WindUI:Notify({
					Title = "Teleport",
					Content = "Player tidak ditemukan!",
				})
			end
		end,
	})

	TeleportTab:Space({ Columns = 2 })

	local CoordSection = TeleportTab:Section({
		Title = "Coordinate Teleport",
	})

	local coordXInput = CoordSection:Input({
		Title = "X Coordinate",
		Placeholder = "0",
		Type = "Input",
		Callback = function() end,
	})

	local coordYInput = CoordSection:Input({
		Title = "Y Coordinate",
		Placeholder = "50",
		Type = "Input",
		Callback = function() end,
	})

	local coordZInput = CoordSection:Input({
		Title = "Z Coordinate",
		Placeholder = "0",
		Type = "Input",
		Callback = function() end,
	})

	CoordSection:Space()

	CoordSection:Button({
		Title = "Teleport to Coordinates",
		Desc = "Teleport ke koordinat yang ditentukan",
		Color = Blue,
		Icon = "map-pin",
		Callback = function()
			local x = tonumber(coordXInput:Get() or "0") or 0
			local y = tonumber(coordYInput:Get() or "50") or 50
			local z = tonumber(coordZInput:Get() or "0") or 0
			teleportTo(Vector3.new(x, y, z))
			WindUI:Notify({
				Title = "Teleport",
				Content = string.format("Teleported ke (%.1f, %.1f, %.1f)", x, y, z),
			})
		end,
	})

	TeleportTab:Space({ Columns = 2 })

	local SaveSection = TeleportTab:Section({
		Title = "Saved Locations",
	})

	local savedLocations = {}

	SaveSection:Button({
		Title = "Save Current Position",
		Desc = "Simpan posisi player saat ini",
		Icon = "bookmark",
		Callback = function()
			local hrp = getHRP(LocalPlayer.Character)
			if hrp then
				local pos = hrp.Position
				local locName = "Location_" .. #savedLocations + 1
				table.insert(savedLocations, { Name = locName, Position = pos })
				WindUI:Notify({
					Title = "Save Location",
					Content = string.format("Posisi disimpan: %s (%.1f, %.1f, %.1f)", locName, pos.X, pos.Y, pos.Z),
				})
			end
		end,
	})

	SaveSection:Space()

	SaveSection:Button({
		Title = "Teleport to Last Saved",
		Desc = "Teleport ke lokasi terakhir yang disimpan",
		Icon = "rotate-ccw",
		Callback = function()
			if #savedLocations > 0 then
				local lastLoc = savedLocations[#savedLocations]
				teleportTo(lastLoc.Position)
				WindUI:Notify({
					Title = "Teleport",
					Content = "Teleported ke " .. lastLoc.Name .. "!",
				})
			else
				WindUI:Notify({
					Title = "Teleport",
					Content = "Belum ada lokasi yang disimpan!",
				})
			end
		end,
	})
end

-- ============================================================
-- Gameplay Tab
-- ============================================================
local GameplayTab = Window:Tab({
	Title = "Gameplay",
	Icon = "solar:gamepad-bold",
	IconColor = Green,
	IconShape = "Square",
	Border = true,
})

do
	local MovementSection = GameplayTab:Section({
		Title = "Movement",
	})

	MovementSection:Toggle({
		Title = "Walk Speed Boost",
		Desc = "Meningkatkan kecepatan jalan player",
		Flag = "WalkSpeedBoost",
		Value = false,
		Callback = function(v)
			GameplayState.WalkSpeedBoost = v
			if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
				LocalPlayer.Character.Humanoid.WalkSpeed = 16
			end
			applyWalkSpeed()
		end,
	})

	MovementSection:Space()

	MovementSection:Slider({
		Title = "Walk Speed",
		Flag = "CustomWalkSpeed",
		Step = 1,
		Value = {
			Min = 16,
			Max = 200,
			Default = 40,
		},
		Callback = function(value)
			GameplayState.CustomWalkSpeed = value
			if GameplayState.WalkSpeedBoost then
				applyWalkSpeed()
			end
		end,
	})

	MovementSection:Space()

	MovementSection:Toggle({
		Title = "Jump Power Boost",
		Desc = "Meningkatkan ketinggian lompatan player",
		Flag = "JumpPowerBoost",
		Value = false,
		Callback = function(v)
			GameplayState.JumpPowerBoost = v
			if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
				LocalPlayer.Character.Humanoid.JumpPower = 50
			end
			applyJumpPower()
		end,
	})

	MovementSection:Space()

	MovementSection:Slider({
		Title = "Jump Power",
		Flag = "CustomJumpPower",
		Step = 5,
		Value = {
			Min = 50,
			Max = 300,
			Default = 100,
		},
		Callback = function(value)
			GameplayState.CustomJumpPower = value
			if GameplayState.JumpPowerBoost then
				applyJumpPower()
			end
		end,
	})

	MovementSection:Space()

	MovementSection:Toggle({
		Title = "NoClip",
		Desc = "Menembus dinding dan objek padat",
		Flag = "NoClip",
		Value = false,
		Callback = function(v)
			GameplayState.NoClip = v
			applyNoClip()
		end,
	})

	MovementSection:Space()

	MovementSection:Toggle({
		Title = "Infinite Sprint",
		Desc = "Berlari tanpa batas stamina",
		Flag = "InfiniteSprint",
		Value = false,
		Callback = function(v)
			GameplayState.InfiniteSprint = v
			applyInfiniteSprint()
		end,
	})

	GameplayTab:Space({ Columns = 2 })

	local UtilitySection = GameplayTab:Section({
		Title = "Utility",
	})

	UtilitySection:Toggle({
		Title = "Freecam",
		Desc = "Kamera bebas terbang melihat seluruh map. WASD untuk bergerak, Space/Shift naik/turun",
		Flag = "Freecam",
		Value = false,
		Callback = function(v)
			toggleFreecam()
		end,
	})

	UtilitySection:Space()

	UtilitySection:Toggle({
		Title = "No Stun",
		Desc = "Menghilangkan efek stun saat dikejar killer",
		Flag = "NoStun",
		Value = false,
		Callback = function(v)
			GameplayState.NoStun = v
			if v then
				WindUI:Notify({ Title = "Gameplay", Content = "No Stun enabled!" })
			end
		end,
	})

	UtilitySection:Space()

	UtilitySection:Toggle({
		Title = "Instant Vault",
		Desc = "Vault instan tanpa animasi panjang",
		Flag = "InstantVault",
		Value = false,
		Callback = function(v)
			GameplayState.InstantVault = v
			if v then
				WindUI:Notify({ Title = "Gameplay", Content = "Instant Vault enabled!" })
			end
		end,
	})

	UtilitySection:Space()

	UtilitySection:Toggle({
		Title = "Auto Skill Check",
		Desc = "Otomatis menyelesaikan skill check",
		Flag = "AutoSkillCheck",
		Value = false,
		Callback = function(v)
			GameplayState.AutoSkillCheck = v
			if v then
				WindUI:Notify({ Title = "Gameplay", Content = "Auto Skill Check enabled!" })
			end
		end,
	})

	UtilitySection:Space()

	UtilitySection:Toggle({
		Title = "Anti Camp Alert",
		Desc = "Memberikan peringatan jika killer berada terlalu lama di sekitar hook",
		Flag = "AntiCamp",
		Value = false,
		Callback = function(v)
			GameplayState.AntiCamp = v
			if v then
				WindUI:Notify({ Title = "Gameplay", Content = "Anti Camp Alert enabled!" })
			end
		end,
	})

	UtilitySection:Space()

	UtilitySection:Toggle({
		Title = "Spam Vault",
		Desc = "Memungkinkan vault berulang kali tanpa cooldown",
		Flag = "SpamVault",
		Value = false,
		Callback = function(v)
			GameplayState.SpamVault = v
			if v then
				WindUI:Notify({ Title = "Gameplay", Content = "Spam Vault enabled!" })
			end
		end,
	})

	GameplayTab:Space({ Columns = 2 })

	local FreecamSection = GameplayTab:Section({
		Title = "Freecam Settings",
	})

	FreecamSection:Slider({
		Title = "Freecam Speed",
		Flag = "FreecamSpeed",
		Step = 0.5,
		Value = {
			Min = 0.5,
			Max = 10,
			Default = 1,
		},
		Callback = function(value)
			freecamSpeed = value
		end,
	})
end

-- ============================================================
-- Info Tab (About)
-- ============================================================
do
	local InfoTab = Window:Tab({
		Title = "Info",
		Icon = "solar:info-square-bold",
		IconColor = Grey,
		IconShape = "Square",
		Border = true,
	})

	InfoTab:Section({
		Title = "Zetttify | Violence District VFree",
		TextSize = 22,
		FontWeight = Enum.FontWeight.SemiBold,
	})

	InfoTab:Space()

	InfoTab:Section({
		Title = "Script ini menyediakan berbagai fitur ESP dan gameplay tools untuk membantu pemain mendapatkan informasi map dengan lebih jelas selama permainan Violence District berlangsung.\n\nFitur utama meliputi ESP untuk Killer (Merah), Survivor (Hijau), Generator (Orange), Gate (Putih), Hook (Merah), dan Pallet (Kuning). Selain itu terdapat Teleport Menu untuk berpindah lokasi secara cepat, serta Gameplay Tools seperti Walk Speed Boost, NoClip, Freecam, dan lainnya.\n\nGunakan fitur dengan bijak. Script ini hanya untuk tujuan edukasi.",
		TextSize = 16,
		TextTransparency = 0.25,
		FontWeight = Enum.FontWeight.Medium,
	})

	InfoTab:Space({ Columns = 3 })

	local CreditsSection = InfoTab:Section({
		Title = "Credits",
	})

	CreditsSection:Section({
		Title = "UI Library: WindUI by Footagesus\nScript: Zetttify\nGame: Violence District",
		TextSize = 15,
		TextTransparency = 0.3,
	})

	InfoTab:Space()

	InfoTab:Button({
		Title = "Destroy Window",
		Desc = "Menutup dan menghapus seluruh UI",
		Color = Color3.fromHex("#ff4830"),
		Icon = "shredder",
		Callback = function()
			-- Cleanup all connections
			if espConnection then espConnection:Disconnect() end
			if walkSpeedConn then walkSpeedConn:Disconnect() end
			if jumpPowerConn then jumpPowerConn:Disconnect() end
			if noclipConn then noclipConn:Disconnect() end
			if sprintConn then sprintConn:Disconnect() end
			if freecamConn then freecamConn:Disconnect() end
			-- Clear all ESP
			clearAllESP()
			clearAllDrawingLabels()
			Window:Destroy()
		end,
	})
end

-- ============================================================
-- Anti-Camp Alert System
-- ============================================================
local function startAntiCampSystem()
	RunService.Heartbeat:Connect(function()
		if not GameplayState.AntiCamp then return end

		local myHRP = getHRP(LocalPlayer.Character)
		if not myHRP then return end

		-- Check if any killer is near any hook
		local killers, _, _, _, hooks, _ = findGameObjects()
		for _, killer in ipairs(killers) do
			local killerHRP = getHRP(killer) or (killer:FindFirstChild("HumanoidRootPart"))
			if killerHRP then
				for _, hook in ipairs(hooks) do
					local hookHRP = getHRP(hook) or hook.PrimaryPart
					if hookHRP then
						local dist = (killerHRP.Position - hookHRP.Position).Magnitude
						if dist < 15 then
							-- Killer is camping near a hook
							local myDist = (myHRP.Position - hookHRP.Position).Magnitude
							if myDist < 80 then
								WindUI:Notify({
									Title = "Anti Camp Alert",
									Content = string.format("Killer sedang camp di hook! Jarak: %d", math.floor(dist)),
									Duration = 4,
								})
								task.wait(5) -- Cooldown between alerts
							end
						end
					end
				end
			end
		end
	end)
end

startAntiCampSystem()

-- ============================================================
-- Auto Skill Check System
-- ============================================================
local function startAutoSkillCheck()
	RunService.RenderStepped:Connect(function()
		if not GameplayState.AutoSkillCheck then return end

		-- Look for skill check UI elements in PlayerGui
		local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
		if not playerGui then return end

		for _, guiItem in ipairs(playerGui:GetDescendants()) do
			local name = string.lower(guiItem.Name)
			if name:find("skillcheck") or name:find("skill_check") or name:find("skill") then
				-- Attempt to find and interact with the skill check button/hit zone
				if guiItem:IsA("ImageButton") or guiItem:IsA("TextButton") then
					pcall(function()
						guiItem.Activate:Fire()
					end)
				end
				-- Also try to find a remote event for skill checks
			end
		end

		-- Check for skill check related remote events
		for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
			local name = string.lower(obj.Name)
			if (name:find("skill") or name:find("check")) and obj:IsA("RemoteEvent") then
				pcall(function()
					obj:FireServer(true) -- Attempt to auto-complete skill check
				end)
			end
		end
	end)
end

startAutoSkillCheck()

-- ============================================================
-- No Stun System
-- ============================================================
local function startNoStunSystem()
	RunService.Heartbeat:Connect(function()
		if not GameplayState.NoStun then return end

		local char = LocalPlayer.Character
		if not char or not char:FindFirstChild("Humanoid") then return end

		local humanoid = char.Humanoid

		-- Remove stun states
		if humanoid.PlatformStand then
			humanoid.PlatformStand = false
		end

		-- Reset walk speed if it was reduced by stun
		if GameplayState.WalkSpeedBoost and humanoid.WalkSpeed < GameplayState.CustomWalkSpeed * 0.5 then
			humanoid.WalkSpeed = GameplayState.CustomWalkSpeed
		end
	end)
end

startNoStunSystem()

-- ============================================================
-- Instant Vault System
-- ============================================================
local function startInstantVaultSystem()
	-- Monitor for vault interactions
	RunService.Heartbeat:Connect(function()
		if not GameplayState.InstantVault then return end

		local char = LocalPlayer.Character
		if not char then return end

		local humanoid = char:FindFirstChild("Humanoid")
		if not humanoid then return end

		-- Speed up vaulting by manipulating animation speed
		for _, animTrack in ipairs(humanoid:GetPlayingAnimationTracks()) do
			local name = string.lower(animTrack.Animation.Name)
			if name:find("vault") or name:find("climb") or name:find("jump") then
				animTrack:AdjustSpeed(5) -- Speed up vault animation
			end
		end
	end)
end

startInstantVaultSystem()

-- ============================================================
-- Notify on Load
-- ============================================================
WindUI:Notify({
	Title = "Zetttify | Violence District",
	Content = "Script loaded successfully! Gunakan menu untuk mengaktifkan fitur.",
	Icon = "solar:check-circle-bold",
	Duration = 5,
})
