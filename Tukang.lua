local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local cloneref = (cloneref or clonereference or function(instance)
        return instance
end)

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
        Title = "Zetttify | Auto Molen",
        Folder = "zetttify_molen",
        Icon = "solar:folder-2-bold-duotone",
        NewElements = true,
        HideSearchBar = false,

        OpenButton = {
                Title = "MOLEN",
                CornerRadius = UDim.new(1, 0),
                StrokeThickness = 3,
                Enabled = true,
                Draggable = true,
                OnlyMobile = false,
                Scale = 0.5,
                Color = ColorSequence.new(
                        Color3.fromHex("#F5A623"),
                        Color3.fromHex("#D4781F")
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
Window:Tag({
        Title = "v" .. WindUI.Version,
        Icon = "github",
        Color = Color3.fromHex("#1c1c1c"),
        Border = true,
})

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
local Brown = Color3.fromHex("#8B6914")
local Sand = Color3.fromHex("#F4D03F")

-- ============================================================
-- Utility Functions
-- ============================================================
local function getCharacter()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                if char.Humanoid.Health > 0 then
                        return char
                end
        end
        return nil
end

local function getHRP()
        local char = getCharacter()
        if char then
                return char:FindFirstChild("HumanoidRootPart")
        end
        return nil
end

local function getHumanoid()
        local char = getCharacter()
        if char then
                return char:FindFirstChild("Humanoid")
        end
        return nil
end

local function waitForCharacter()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        repeat task.wait(0.1) until char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid")
        return char
end

local function teleportTo(position)
        local hrp = getHRP()
        if hrp then
                hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        end
end

local function walkTo(targetPosition, speed)
        speed = speed or 16
        local hrp = getHRP()
        local humanoid = getHumanoid()
        if not hrp or not humanoid then return false end

        local distance = (targetPosition - hrp.Position).Magnitude
        if distance < 5 then
                return true -- sudah sampai
        end

        humanoid:MoveTo(targetPosition)
        humanoid.MoveToFinished:Wait()

        -- Verifikasi apakah benar-benar sampai
        local newDistance = (targetPosition - hrp.Position).Magnitude
        return newDistance < 8
end

local function findNearestPart(parent, namePatterns, maxDistance)
        maxDistance = maxDistance or math.huge
        local hrp = getHRP()
        if not hrp then return nil, math.huge end

        local nearest = nil
        local nearestDist = math.huge

        for _, obj in ipairs(parent:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Model") then
                        local name = string.lower(obj.Name)
                        for _, pattern in ipairs(namePatterns) do
                                if name:find(pattern) then
                                        local pos
                                        if obj:IsA("Model") then
                                                pos = obj.PrimaryPart and obj.PrimaryPart.Position
                                                if not pos and obj:FindFirstChild("HumanoidRootPart") then
                                                        pos = obj.HumanoidRootPart.Position
                                                end
                                                if not pos then
                                                        pos = obj:GetPivot().Position
                                                end
                                        else
                                                pos = obj.Position
                                        end

                                        if pos then
                                                local dist = (hrp.Position - pos).Magnitude
                                                if dist < nearestDist and dist <= maxDistance then
                                                        nearestDist = dist
                                                        nearest = obj
                                                end
                                        end
                                        break
                                end
                        end
                end
        end

        return nearest, nearestDist
end

local function findAllParts(parent, namePatterns)
        local results = {}
        for _, obj in ipairs(parent:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Model") then
                        local name = string.lower(obj.Name)
                        for _, pattern in ipairs(namePatterns) do
                                if name:find(pattern) then
                                        table.insert(results, obj)
                                        break
                                end
                        end
                end
        end
        return results
end

-- Fire remote event / function
local function fireRemote(remoteName, methodName, ...)
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                        if string.lower(obj.Name):find(string.lower(remoteName)) then
                                pcall(function()
                                        if methodName == "FireServer" then
                                                obj:FireServer(...)
                                        elseif methodName == "InvokeServer" then
                                                obj:InvokeServer(...)
                                        end
                                end)
                                return true
                        end
                end
        end
        return false
end

-- ============================================================
-- Game State & Config
-- ============================================================
local State = {
        -- Auto Molen
        AutoFarmMolen = false,
        SemenRatio = 2,
        PasirRatio = 6,
        UnlimitedMolen = false,

        -- Rain Shelter
        AutoRainShelter = true,
        IsRaining = false,
        IsInShelter = false,

        -- Auto Farm
        AutoFarmLevel = false,
        AutoFarmMoney = false,

        -- Status tracking
        StatusText = "Idle",
        CurrentPhase = "Idle",
        CyclesCompleted = 0,
        SemenCollected = 0,
        PasirCollected = 0,
        MolenProduced = 0,
        Errors = 0,
}

-- Rain detection
local function detectRain()
        -- Method 1: Check workspace for rain/lightning indicators
        for _, obj in ipairs(workspace:GetDescendants()) do
                local name = string.lower(obj.Name)
                if (name:find("rain") or name:find("hujan") or name:find("petir") or name:find("lightning") or name:find("storm"))
                        and (obj:IsA("ParticleEmitter") or obj:IsA("Sound") or obj:IsA("Part") or obj:IsA("BoolValue")) then
                        if obj:IsA("BoolValue") then
                                return obj.Value
                        end
                        if obj:IsA("ParticleEmitter") and obj.Enabled then
                                return true
                        end
                        if obj:IsA("Sound") and obj.IsPlaying then
                                return true
                        end
                        if obj:IsA("Part") then
                                return true
                        end
                end
        end

        -- Method 2: Check Lighting / Atmosphere
        local lighting = game:GetService("Lighting")
        if lighting:FindFirstChild("Rain") or lighting:FindFirstChild("Hujan") then
                return true
        end

        -- Method 3: Check game attributes
        local attrs = {
                workspace:GetAttribute("IsRaining"),
                workspace:GetAttribute("isRaining"),
                workspace:GetAttribute("Raining"),
                workspace:GetAttribute("IsStorm"),
                game:GetService("Lighting"):GetAttribute("IsRaining"),
        }
        for _, attr in ipairs(attrs) do
                if attr == true then
                        return true
                end
        end

        -- Method 4: Check PlayerGui for rain UI indicators
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
                for _, guiItem in ipairs(playerGui:GetDescendants()) do
                        local name = string.lower(guiItem.Name)
                        if (name:find("rain") or name:find("hujan")) and guiItem:IsA("TextLabel") then
                                local text = string.lower(guiItem.Text or "")
                                if text:find("hujan") or text:find("rain") then
                                        return true
                                end
                        end
                end
        end

        -- Method 5: Check for dark sky / storm lighting
        local clockTime = lighting.ClockTime
        if lighting.Brightness < 0.5 and lighting.FogEnd < 500 then
                -- Possible rain, but not definitive - return nil (unknown)
        end

        return false
end

-- ============================================================
-- Find Tenda / Saung (Shelter)
-- ============================================================
local function findShelter()
        local shelterPatterns = { "tenda", "saung", "shelter", "roof", "atap", "payung", "kanopi", "bangunan" }
        local shelter, dist = findNearestPart(workspace, shelterPatterns, 300)
        if shelter then
                return shelter, dist
        end

        -- Check sub-folders
        local folders = { workspace:FindFirstChild("Map"), workspace:FindFirstChild("Buildings"), workspace:FindFirstChild("Structures") }
        for _, folder in ipairs(folders) do
                if folder then
                        shelter, dist = findNearestPart(folder, shelterPatterns, 300)
                        if shelter then
                                return shelter, dist
                        end
                end
        end

        return nil, math.huge
end

-- ============================================================
-- Find Molen
-- ============================================================
local function findMolen()
        local molenPatterns = { "molen", "mixer", "cement mixer", "concrete mixer", "pengaduk" }
        local molen, dist = findNearestPart(workspace, molenPatterns, 500)
        if molen then
                return molen, dist
        end

        -- Check sub-folders
        local folders = { workspace:FindFirstChild("Map"), workspace:FindFirstChild("Buildings"), workspace:FindFirstChild("Machines") }
        for _, folder in ipairs(folders) do
                if folder then
                        molen, dist = findNearestPart(folder, molenPatterns, 500)
                        if molen then
                                return molen, dist
                        end
                end
        end

        return nil, math.huge
end

-- ============================================================
-- Find Semen (Cement)
-- ============================================================
local function findSemen()
        local semenPatterns = { "semen", "cement", "sak semen", "karung semen", "cement bag" }
        local results = findAllParts(workspace, semenPatterns)

        if #results == 0 then
                local folders = { workspace:FindFirstChild("Map"), workspace:FindFirstChild("Resources"), workspace:FindFirstChild("Items") }
                for _, folder in ipairs(folders) do
                        if folder then
                                results = findAllParts(folder, semenPatterns)
                                if #results > 0 then break end
                        end
                end
        end

        return results
end

-- ============================================================
-- Find Pasir (Sand)
-- ============================================================
local function findPasir()
        local pasirPatterns = { "pasir", "sand", "tumpukan pasir", "sand pile", "gunungan pasir" }
        local results = findAllParts(workspace, pasirPatterns)

        if #results == 0 then
                local folders = { workspace:FindFirstChild("Map"), workspace:FindFirstChild("Resources"), workspace:FindFirstChild("Items") }
                for _, folder in ipairs(folders) do
                        if folder then
                                results = findAllParts(folder, pasirPatterns)
                                if #results > 0 then break end
                        end
                end
        end

        return results
end

-- ============================================================
-- Get position from object (BasePart or Model)
-- ============================================================
local function getPosition(obj)
        if not obj then return nil end
        if obj:IsA("BasePart") then
                return obj.Position
        elseif obj:IsA("Model") then
                if obj.PrimaryPart then
                        return obj.PrimaryPart.Position
                end
                if obj:FindFirstChild("HumanoidRootPart") then
                        return obj.HumanoidRootPart.Position
                end
                return obj:GetPivot().Position
        end
        return nil
end

-- ============================================================
-- Interact with object (proximity prompt, click detector, touch)
-- ============================================================
local function interactWith(obj)
        if not obj then return false end

        -- Method 1: ProximityPrompt
        if obj:IsA("ProximityPrompt") then
                pcall(function()
                        obj.HoldDuration = 0
                        obj:InputHoldEnd(Enum.UserInputState.Begin)
                end)
                return true
        end

        -- Find ProximityPrompt in children
        for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("ProximityPrompt") then
                        pcall(function()
                                child.HoldDuration = 0
                                child:InputHoldEnd(Enum.UserInputState.Begin)
                        end)
                        return true
                end
        end

        -- Method 2: ClickDetector
        for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("ClickDetector") then
                        pcall(function()
                                fireclickdetector(child)
                        end)
                        return true
                end
        end

        -- Method 3: Fire a remote event with the object
        local objName = obj.Name
        pcall(function()
                fireRemote("interact", "FireServer", obj)
        end)
        pcall(function()
                fireRemote("collect", "FireServer", obj)
        end)
        pcall(function()
                fireRemote("pickup", "FireServer", obj)
        end)
        pcall(function()
                fireRemote("grab", "FireServer", obj)
        end)

        -- Method 4: Touch the object (move close enough)
        local pos = getPosition(obj)
        if pos then
                local hrp = getHRP()
                if hrp then
                        local dist = (hrp.Position - pos).Magnitude
                        if dist > 5 then
                                teleportTo(pos)
                        end
                        -- Fire touch events
                        local targetPart = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart"))
                        if targetPart and hrp then
                                firetouchinterest(hrp, targetPart, 0)
                                task.wait(0.1)
                                firetouchinterest(hrp, targetPart, 1)
                        end
                end
        end

        return true
end

-- ============================================================
-- Deposit items into molen
-- ============================================================
local function depositToMolen(molen, itemType)
        if not molen then return false end

        local molenPos = getPosition(molen)
        if not molenPos then return false end

        -- Teleport ke molen
        local hrp = getHRP()
        if hrp then
                local dist = (hrp.Position - molenPos).Magnitude
                if dist > 10 then
                        teleportTo(molenPos)
                        task.wait(0.5)
                end
        end

        -- Interact with molen
        interactWith(molen)

        -- Try fire remote for deposit
        pcall(function()
                fireRemote("deposit", "FireServer", itemType)
        end)
        pcall(function()
                fireRemote("addMolen", "FireServer", itemType)
        end)
        pcall(function()
                fireRemote("insert", "FireServer", itemType, molen)
        end)
        pcall(function()
                fireRemote("molen", "FireServer", itemType)
        end)

        -- Try using ProximityPrompt on molen
        for _, child in ipairs(molen:GetDescendants()) do
                if child:IsA("ProximityPrompt") then
                        local promptName = string.lower(child.Name or "")
                        pcall(function()
                                child.HoldDuration = 0
                                child.RequiresLineOfSight = false
                                child.MaxActivationDistance = 30
                                child:InputHoldEnd(Enum.UserInputState.Begin)
                        end)
                end
        end

        return true
end

-- ============================================================
-- Collect resource (semen/pasir)
-- ============================================================
local function collectResource(resourceObj, resourceType)
        if not resourceObj then return false end

        State.StatusText = "Mengumpulkan " .. resourceType .. "..."
        local pos = getPosition(resourceObj)
        if not pos then return false end

        -- Teleport ke resource
        teleportTo(pos)
        task.wait(0.3)

        -- Interact
        interactWith(resourceObj)

        -- Additional remote fires for collection
        pcall(function()
                fireRemote("collect", "FireServer", resourceObj)
        end)
        pcall(function()
                fireRemote("pickup", "FireServer", resourceType)
        end)
        pcall(function()
                fireRemote("gather", "FireServer", resourceObj)
        end)

        task.wait(0.3)
        return true
end

-- ============================================================
-- Main Auto Molen Loop
-- ============================================================
local autoMolenThread = nil

local function stopAutoMolen()
        if autoMolenThread then
                task.cancel(autoMolenThread)
                autoMolenThread = nil
        end
        State.CurrentPhase = "Idle"
        State.StatusText = "Idle"
end

local function autoMolenLoop()
        stopAutoMolen()

        autoMolenThread = task.spawn(function()
                while State.AutoFarmMolen do
                        pcall(function()
                                -- === RAIN CHECK ===
                                if State.AutoRainShelter then
                                        local isRaining = detectRain()
                                        if isRaining and not State.IsInShelter then
                                                State.StatusText = "Hujan terdeteksi! Menuju tenda/saung..."
                                                State.CurrentPhase = "Shelter"

                                                local shelter, shelterDist = findShelter()
                                                if shelter then
                                                        local shelterPos = getPosition(shelter)
                                                        if shelterPos then
                                                                teleportTo(shelterPos)
                                                                State.IsInShelter = true
                                                        end
                                                end

                                                -- Tunggu hujan reda (check setiap 3 detik)
                                                while State.AutoFarmMolen and detectRain() do
                                                        task.wait(3)
                                                end

                                                State.IsInShelter = false
                                                State.StatusText = "Hujan reda, melanjutkan farm..."
                                        end
                                end

                                -- === CARI MOLEN ===
                                State.CurrentPhase = "Find Molen"
                                State.StatusText = "Mencari molen..."
                                local molen, molenDist = findMolen()
                                if not molen then
                                        State.Errors = State.Errors + 1
                                        State.StatusText = "Molen tidak ditemukan! Mencoba lagi..."
                                        task.wait(3)
                                        continue
                                end

                                local molenPos = getPosition(molen)

                                -- === KUMPULKAN SEMEN (2x) ===
                                for i = 1, State.SemenRatio do
                                        if not State.AutoFarmMolen then break end

                                        -- Re-check rain
                                        if State.AutoRainShelter and detectRain() then
                                                break -- akan dihandle di loop berikutnya
                                        end

                                        State.CurrentPhase = "Collect Semen"
                                        State.StatusText = string.format("Mengumpulkan semen (%d/%d)...", i, State.SemenRatio)

                                        local semenList = findSemen()
                                        if #semenList > 0 then
                                                -- Cari semen terdekat
                                                local nearestSemen = nil
                                                local nearestDist = math.huge
                                                local hrp = getHRP()
                                                if hrp then
                                                        for _, s in ipairs(semenList) do
                                                                local pos = getPosition(s)
                                                                if pos then
                                                                        local d = (hrp.Position - pos).Magnitude
                                                                        if d < nearestDist then
                                                                                nearestDist = d
                                                                                nearestSemen = s
                                                                        end
                                                                end
                                                        end
                                                end

                                                if nearestSemen then
                                                        collectResource(nearestSemen, "semen")
                                                        State.SemenCollected = State.SemenCollected + 1
                                                else
                                                        State.StatusText = "Semen tidak ditemukan di map!"
                                                end
                                        else
                                                State.StatusText = "Semen habis/tidak ada, skip..."
                                        end
                                        task.wait(0.5)
                                end

                                -- === KUMPULKAN PASIR (6x) ===
                                for i = 1, State.PasirRatio do
                                        if not State.AutoFarmMolen then break end

                                        if State.AutoRainShelter and detectRain() then
                                                break
                                        end

                                        State.CurrentPhase = "Collect Pasir"
                                        State.StatusText = string.format("Mengumpulkan pasir (%d/%d)...", i, State.PasirRatio)

                                        local pasirList = findPasir()
                                        if #pasirList > 0 then
                                                local nearestPasir = nil
                                                local nearestDist = math.huge
                                                local hrp = getHRP()
                                                if hrp then
                                                        for _, p in ipairs(pasirList) do
                                                                local pos = getPosition(p)
                                                                if pos then
                                                                        local d = (hrp.Position - pos).Magnitude
                                                                        if d < nearestDist then
                                                                                nearestDist = d
                                                                                nearestPasir = p
                                                                        end
                                                                end
                                                        end
                                                end

                                                if nearestPasir then
                                                        collectResource(nearestPasir, "pasir")
                                                        State.PasirCollected = State.PasirCollected + 1
                                                else
                                                        State.StatusText = "Pasir tidak ditemukan di map!"
                                                end
                                        else
                                                State.StatusText = "Pasir habis/tidak ada, skip..."
                                        end
                                        task.wait(0.5)
                                end

                                -- === MASUKKAN KE MOLEN ===
                                if State.AutoFarmMolen then
                                        State.CurrentPhase = "Deposit Molen"
                                        State.StatusText = "Memasukkan bahan ke molen..."

                                        -- Teleport ke molen
                                        if molenPos then
                                                teleportTo(molenPos)
                                                task.wait(0.5)
                                        end

                                        -- Deposit semen ke molen
                                        for i = 1, State.SemenRatio do
                                                depositToMolen(molen, "semen")
                                                task.wait(0.2)
                                        end

                                        -- Deposit pasir ke molen
                                        for i = 1, State.PasirRatio do
                                                depositToMolen(molen, "pasir")
                                                task.wait(0.2)
                                        end

                                        -- Trigger molen / start mixing
                                        interactWith(molen)
                                        pcall(function()
                                                fireRemote("startMolen", "FireServer", molen)
                                        end)
                                        pcall(function()
                                                fireRemote("mix", "FireServer", molen)
                                        end)
                                        pcall(function()
                                                fireRemote("produce", "FireServer", molen)
                                        end)

                                        -- Tunggu proses mixing
                                        task.wait(2)

                                        -- Collect hasil molen
                                        pcall(function()
                                                fireRemote("collectMolen", "FireServer", molen)
                                        end)
                                        pcall(function()
                                                fireRemote("takeMolen", "FireServer", molen)
                                        end)
                                        pcall(function()
                                                fireRemote("claim", "FireServer", molen)
                                        end)

                                        State.MolenProduced = State.MolenProduced + 1
                                        State.CyclesCompleted = State.CyclesCompleted + 1

                                        State.StatusText = string.format("Molen selesai! Siklus ke-%d", State.CyclesCompleted)
                                end

                                task.wait(1)
                        end)
                end

                State.CurrentPhase = "Idle"
                State.StatusText = "Auto Molen dihentikan"
        end)
end

-- ============================================================
-- Unlimited Molen (Status semen dari molen unlimited)
-- ============================================================
local unlimitedConn = nil

local function startUnlimitedMolen()
        if unlimitedConn then unlimitedConn:Disconnect() end

        unlimitedConn = RunService.Heartbeat:Connect(function()
                if not State.UnlimitedMolen then return end

                -- Intercept any attribute/value changes related to molen status
                local char = getCharacter()
                if not char then return end

                -- Keep molen-related stats at max
                for _, obj in ipairs(workspace:GetDescendants()) do
                        local name = string.lower(obj.Name)
                        if name:find("molen") or name:find("mixer") then
                                -- Reset molen cooldown
                                if obj:GetAttribute("Cooldown") ~= nil then
                                        obj:SetAttribute("Cooldown", 0)
                                end
                                if obj:GetAttribute("Progress") ~= nil then
                                        obj:SetAttribute("Progress", 100)
                                end
                                if obj:GetAttribute("IsReady") ~= nil then
                                        obj:SetAttribute("IsReady", true)
                                end
                        end
                end

                -- Also check player stats for molen count
                local player = LocalPlayer
                if player then
                        -- Try to keep semen status unlimited
                        for _, attr in ipairs({ "Semen", "Cement", "MolenCount", "MixCount" }) do
                                local val = player:GetAttribute(attr)
                                if val ~= nil and type(val) == "number" and val < 9999 then
                                        player:SetAttribute(attr, 9999)
                                end
                        end
                end
        end)
end

-- ============================================================
-- Auto Farm Level & Money
-- ============================================================
local autoFarmThread = nil

local function stopAutoFarm()
        if autoFarmThread then
                task.cancel(autoFarmThread)
                autoFarmThread = nil
        end
end

local function autoFarmLoop()
        stopAutoFarm()

        autoFarmThread = task.spawn(function()
                while State.AutoFarmLevel or State.AutoFarmMoney do
                        pcall(function()
                                -- Rain check
                                if State.AutoRainShelter and detectRain() then
                                        State.StatusText = "Hujan terdeteksi! Menuju tenda/saung..."
                                        local shelter, _ = findShelter()
                                        if shelter then
                                                local pos = getPosition(shelter)
                                                if pos then
                                                        teleportTo(pos)
                                                        State.IsInShelter = true
                                                end
                                        end
                                        while (State.AutoFarmLevel or State.AutoFarmMoney) and detectRain() do
                                                task.wait(3)
                                        end
                                        State.IsInShelter = false
                                end

                                if State.AutoFarmMoney then
                                        -- Farm money: collect molen products and deliver them
                                        State.CurrentPhase = "Farm Uang"
                                        State.StatusText = "Mencari molen untuk menghasilkan produk..."

                                        -- Find and interact with molen for production
                                        local molen, _ = findMolen()
                                        if molen then
                                                local pos = getPosition(molen)
                                                if pos then
                                                        teleportTo(pos)
                                                        task.wait(0.5)
                                                        interactWith(molen)
                                                end
                                        end

                                        -- Find delivery point / sell point
                                        local sellPatterns = { "sell", "jual", "delivery", "kirim", "submit", "toko", "shop", "counter", "penjual", "buyer" }
                                        local sellPoint, _ = findNearestPart(workspace, sellPatterns, 300)

                                        if sellPoint then
                                                local sellPos = getPosition(sellPoint)
                                                if sellPos then
                                                        State.StatusText = "Mengirim produk untuk mendapatkan uang..."
                                                        teleportTo(sellPos)
                                                        task.wait(0.5)
                                                        interactWith(sellPoint)

                                                        pcall(function() fireRemote("sell", "FireServer", sellPoint) end)
                                                        pcall(function() fireRemote("deliver", "FireServer", sellPoint) end)
                                                        pcall(function() fireRemote("submit", "FireServer", sellPoint) end)
                                                        pcall(function() fireRemote("claimReward", "FireServer") end)
                                                end
                                        else
                                                -- If no sell point, try to auto-complete molen cycles for money
                                                -- This relies on the auto molen being active or running a quick cycle
                                                State.StatusText = "Mencari cara farm uang..."
                                        end
                                end

                                if State.AutoFarmLevel then
                                        -- Farm level: repeatedly do tasks / interact with objects for XP
                                        State.CurrentPhase = "Farm Level"
                                        State.StatusText = "Mencari task/aktivitas untuk XP..."

                                        -- Interact with any interactable objects in the map
                                        local interactPatterns = {
                                                "task", "quest", "mission", "job", "work",
                                                "tugas", "kerja", "aktivitas", "xp", "exp",
                                                "semen", "pasir", "molen", "generator",
                                                "truck", "mobil", "kendaraan", "deliver",
                                        }

                                        for _, pattern in ipairs(interactPatterns) do
                                                if not (State.AutoFarmLevel or State.AutoFarmMoney) then break end

                                                local obj, dist = findNearestPart(workspace, { pattern }, 200)
                                                if obj and dist < 200 then
                                                        local pos = getPosition(obj)
                                                        if pos then
                                                                State.StatusText = "Mengerjakan: " .. obj.Name
                                                                teleportTo(pos)
                                                                task.wait(0.3)
                                                                interactWith(obj)

                                                                pcall(function() fireRemote("complete", "FireServer", obj) end)
                                                                pcall(function() fireRemote("claim", "FireServer", obj) end)
                                                                pcall(function() fireRemote("progress", "FireServer", obj) end)

                                                                task.wait(0.5)
                                                        end
                                                end
                                        end

                                        -- Also try to complete any available quests
                                        pcall(function() fireRemote("completeQuest", "FireServer") end)
                                        pcall(function() fireRemote("claimQuest", "FireServer") end)
                                        pcall(function() fireRemote("nextQuest", "FireServer") end)
                                end

                                task.wait(2)
                        end)
                end

                State.CurrentPhase = "Idle"
        end)
end

-- ============================================================
-- TABS
-- ============================================================

-- ============================================================
-- Tab 1: Auto Molen
-- ============================================================
local MolenTab = Window:Tab({
        Title = "Auto Molen",
        Icon = "solar:box-bold",
        IconColor = Brown,
        IconShape = "Square",
        Border = true,
})

do
        local MainSection = MolenTab:Section({
                Title = "Auto Farm Molen",
        })

        MainSection:Toggle({
                Title = "Auto Farm Semen & Pasir",
                Desc = "Otomatis mengumpulkan semen (2x) dan pasir (6x), lalu memasukkannya ke molen",
                Flag = "AutoFarmMolen",
                Value = false,
                Callback = function(v)
                        State.AutoFarmMolen = v
                        if v then
                                autoMolenLoop()
                                WindUI:Notify({
                                        Title = "Auto Molen",
                                        Content = "Auto farm semen & pasir dimulai!",
                                        Duration = 3,
                                })
                        else
                                stopAutoMolen()
                                WindUI:Notify({
                                        Title = "Auto Molen",
                                        Content = "Auto farm dihentikan.",
                                        Duration = 3,
                                })
                        end
                end,
        })

        MainSection:Space()

        local RatioGroup = MolenTab:Group({})

        RatioGroup:Slider({
                Title = "Semen per Siklus",
                Desc = "Jumlah semen yang dikumpulkan setiap siklus",
                Flag = "SemenRatio",
                Step = 1,
                Value = {
                        Min = 1,
                        Max = 10,
                        Default = 2,
                },
                Callback = function(value)
                        State.SemenRatio = value
                end,
        })

        RatioGroup:Space()

        RatioGroup:Slider({
                Title = "Pasir per Siklus",
                Desc = "Jumlah pasir yang dikumpulkan setiap siklus",
                Flag = "PasirRatio",
                Step = 1,
                Value = {
                        Min = 1,
                        Max = 20,
                        Default = 6,
                },
                Callback = function(value)
                        State.PasirRatio = value
                end,
        })

        MolenTab:Space({ Columns = 2 })

        local UnlimitedSection = MolenTab:Section({
                Title = "Unlimited Molen",
        })

        UnlimitedSection:Toggle({
                Title = "Unlimited Molen Status",
                Desc = "Status semen hasil dari molen menjadi unlimited. Molen cooldown direset otomatis.",
                Flag = "UnlimitedMolen",
                Value = false,
                Callback = function(v)
                        State.UnlimitedMolen = v
                        if v then
                                startUnlimitedMolen()
                                WindUI:Notify({
                                        Title = "Unlimited Molen",
                                        Content = "Molen status unlimited diaktifkan!",
                                        Duration = 3,
                                })
                        else
                                if unlimitedConn then
                                        unlimitedConn:Disconnect()
                                        unlimitedConn = nil
                                end
                        end
                end,
        })

        MolenTab:Space({ Columns = 2 })

        local RainSection = MolenTab:Section({
                Title = "Rain Shelter",
        })

        RainSection:Toggle({
                Title = "Auto Rain Shelter",
                Desc = "Otomatis pergi ke tenda/saung saat hujan untuk menghindari petir",
                Flag = "AutoRainShelter",
                Value = true,
                Callback = function(v)
                        State.AutoRainShelter = v
                        if v then
                                WindUI:Notify({
                                        Title = "Rain Shelter",
                                        Content = "Akan otomatis berlindung saat hujan!",
                                        Duration = 3,
                                })
                        end
                end,
        })
end

-- ============================================================
-- Tab 2: Auto Farm
-- ============================================================
local FarmTab = Window:Tab({
        Title = "Auto Farm",
        Icon = "solar:star-bold",
        IconColor = Yellow,
        IconShape = "Square",
        Border = true,
})

do
        local FarmSection = FarmTab:Section({
                Title = "Farm Level & Uang",
        })

        FarmSection:Toggle({
                Title = "Auto Farm Level",
                Desc = "Otomatis mengerjakan task dan aktivitas untuk mendapatkan XP naik level",
                Flag = "AutoFarmLevel",
                Value = false,
                Callback = function(v)
                        State.AutoFarmLevel = v
                        if v or State.AutoFarmMoney then
                                autoFarmLoop()
                                WindUI:Notify({
                                        Title = "Auto Farm",
                                        Content = "Auto farm level dimulai!",
                                        Duration = 3,
                                })
                        else
                                stopAutoFarm()
                        end
                end,
        })

        FarmSection:Space()

        FarmSection:Toggle({
                Title = "Auto Farm Uang",
                Desc = "Otomatis mengirim hasil molen dan mengerjakan task untuk mendapatkan uang",
                Flag = "AutoFarmMoney",
                Value = false,
                Callback = function(v)
                        State.AutoFarmMoney = v
                        if v or State.AutoFarmLevel then
                                autoFarmLoop()
                                WindUI:Notify({
                                        Title = "Auto Farm",
                                        Content = "Auto farm uang dimulai!",
                                        Duration = 3,
                                })
                        else
                                stopAutoFarm()
                        end
                end,
        })

        FarmTab:Space({ Columns = 2 })

        local WorkSection = FarmTab:Section({
                Title = "Quick Actions",
        })

        WorkSection:Button({
                Title = "Cari & Kumpulkan Semen",
                Desc = "Teleport ke semen terdekat dan mengumpulkannya",
                Color = Brown,
                Icon = "package",
                Callback = function()
                        local semenList = findSemen()
                        if #semenList > 0 then
                                local hrp = getHRP()
                                local nearest = nil
                                local nd = math.huge
                                for _, s in ipairs(semenList) do
                                        local pos = getPosition(s)
                                        if pos and hrp then
                                                local d = (hrp.Position - pos).Magnitude
                                                if d < nd then nd = d; nearest = s end
                                        end
                                end
                                if nearest then
                                        collectResource(nearest, "semen")
                                        WindUI:Notify({ Title = "Semen", Content = "Semen berhasil dikumpulkan!" })
                                end
                        else
                                WindUI:Notify({ Title = "Semen", Content = "Tidak ada semen ditemukan!" })
                        end
                end,
        })

        WorkSection:Space()

        WorkSection:Button({
                Title = "Cari & Kumpulkan Pasir",
                Desc = "Teleport ke pasir terdekat dan mengumpulkannya",
                Color = Sand,
                Icon = "layers",
                Callback = function()
                        local pasirList = findPasir()
                        if #pasirList > 0 then
                                local hrp = getHRP()
                                local nearest = nil
                                local nd = math.huge
                                for _, p in ipairs(pasirList) do
                                        local pos = getPosition(p)
                                        if pos and hrp then
                                                local d = (hrp.Position - pos).Magnitude
                                                if d < nd then nd = d; nearest = p end
                                        end
                                end
                                if nearest then
                                        collectResource(nearest, "pasir")
                                        WindUI:Notify({ Title = "Pasir", Content = "Pasir berhasil dikumpulkan!" })
                                end
                        else
                                WindUI:Notify({ Title = "Pasir", Content = "Tidak ada pasir ditemukan!" })
                        end
                end,
        })

        WorkSection:Space()

        WorkSection:Button({
                Title = "Teleport ke Molen",
                Desc = "Langsung teleport ke molen terdekat",
                Color = Color3.fromHex("#888888"),
                Icon = "target",
                Callback = function()
                        local molen, dist = findMolen()
                        if molen then
                                local pos = getPosition(molen)
                                if pos then
                                        teleportTo(pos)
                                        WindUI:Notify({ Title = "Teleport", Content = string.format("Teleported ke molen! (%dm)", math.floor(dist)) })
                                end
                        else
                                WindUI:Notify({ Title = "Teleport", Content = "Molen tidak ditemukan!" })
                        end
                end,
        })

        WorkSection:Space()

        WorkSection:Button({
                Title = "Teleport ke Tenda/Saung",
                Desc = "Langsung teleport ke tenda atau saung terdekat",
                Color = Green,
                Icon = "home",
                Callback = function()
                        local shelter, dist = findShelter()
                        if shelter then
                                local pos = getPosition(shelter)
                                if pos then
                                        teleportTo(pos)
                                        WindUI:Notify({ Title = "Shelter", Content = string.format("Teleported ke shelter! (%dm)", math.floor(dist)) })
                                end
                        else
                                WindUI:Notify({ Title = "Shelter", Content = "Tenda/Saung tidak ditemukan!" })
                        end
                end,
        })
end

-- ============================================================
-- Tab 3: Status / Info
-- ============================================================
local StatusTab = Window:Tab({
        Title = "Status",
        Icon = "solar:graph-up-bold",
        IconColor = Green,
        IconShape = "Square",
        Border = true,
})

do
        local StatusSection = StatusTab:Section({
                Title = "Farm Status",
        })

        local statusParagraph = StatusSection:Paragraph({
                Title = "Status: Idle",
                Desc = "Belum ada aktivitas berjalan.",
                Icon = "info",
                Color = "Grey",
        })

        -- Update status display every second
        task.spawn(function()
                while true do
                        local hrp = getHRP()
                        local positionStr = hrp and string.format("(%.0f, %.0f, %.0f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "N/A"

                        local rainStatus = "Cerah"
                        if State.IsInShelter then
                                rainStatus = "Berlindung (Hujan)"
                        elseif State.AutoRainShelter then
                                if detectRain() then
                                        rainStatus = "Hujan Terdeteksi!"
                                else
                                        rainStatus = "Cerah (Monitor Aktif)"
                                end
                        end

                        local desc = string.format(
                                "Fase: %s\n" ..
                                "Status: %s\n" ..
                                "Posisi: %s\n" ..
                                "Cuaca: %s\n\n" ..
                                "Siklus Selesai: %d\n" ..
                                "Semen Dikumpulkan: %d\n" ..
                                "Pasir Dikumpulkan: %d\n" ..
                                "Produk Molen: %d\n" ..
                                "Error Count: %d",
                                State.CurrentPhase,
                                State.StatusText,
                                positionStr,
                                rainStatus,
                                State.CyclesCompleted,
                                State.SemenCollected,
                                State.PasirCollected,
                                State.MolenProduced,
                                State.Errors
                        )

                        pcall(function()
                                statusParagraph:Set({
                                        Title = string.format("Status: %s", State.CurrentPhase),
                                        Desc = desc,
                                })
                        end)

                        task.wait(1)
                end
        end)

        StatusTab:Space({ Columns = 2 })

        local ResetSection = StatusTab:Section({
                Title = "Reset",
        })

        ResetSection:Button({
                Title = "Reset Counter",
                Desc = "Reset semua counter statistik menjadi 0",
                Color = Orange,
                Icon = "refresh-cw",
                Callback = function()
                        State.CyclesCompleted = 0
                        State.SemenCollected = 0
                        State.PasirCollected = 0
                        State.MolenProduced = 0
                        State.Errors = 0
                        WindUI:Notify({
                                Title = "Reset",
                                Content = "Semua counter telah direset!",
                                Duration = 3,
                        })
                end,
        })

        ResetSection:Space()

        ResetSection:Button({
                Title = "Stop Semua",
                Desc = "Menghentikan semua fitur auto yang sedang berjalan",
                Color = Red,
                Icon = "square",
                Callback = function()
                        State.AutoFarmMolen = false
                        State.AutoFarmLevel = false
                        State.AutoFarmMoney = false
                        State.UnlimitedMolen = false
                        State.AutoRainShelter = false
                        stopAutoMolen()
                        stopAutoFarm()
                        if unlimitedConn then
                                unlimitedConn:Disconnect()
                                unlimitedConn = nil
                        end
                        WindUI:Notify({
                                Title = "Stop",
                                Content = "Semua fitur auto telah dihentikan!",
                                Duration = 3,
                        })
                end,
        })
end

-- ============================================================
-- Tab 4: Info
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
                Title = "Zetttify | Auto Molen",
                TextSize = 22,
                FontWeight = Enum.FontWeight.SemiBold,
        })

        InfoTab:Space()

        InfoTab:Section({
                Title = "Script auto farm untuk game molen/semen. Fitur utama:\n\n" ..
                        "1. Auto Farm Semen & Pasir - Otomatis mengumpulkan semen dan pasir, lalu memasukkannya ke molen. Rasio default: 2x semen, 6x pasir per siklus.\n\n" ..
                        "2. Unlimited Molen Status - Membuat status semen dari molen menjadi unlimited dengan auto-reset cooldown.\n\n" ..
                        "3. Auto Rain Shelter - Otomatis pergi ke tenda/saung saat hujan untuk menghindari petir.\n\n" ..
                        "4. Auto Farm Level & Uang - Otomatis mengerjakan task dan mengirim hasil untuk XP dan uang.\n\n" ..
                        "Catatan: Jika objek tidak terdeteksi, nama object di game mungkin berbeda. Script menggunakan pattern matching yang fleksibel untuk mencocokkan nama objek.",
                TextSize = 16,
                TextTransparency = 0.25,
                FontWeight = Enum.FontWeight.Medium,
        })

        InfoTab:Space({ Columns = 3 })

        InfoTab:Section({
                Title = "Credits\nUI: WindUI by Footagesus\nScript: Zetttify",
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
                        State.AutoFarmMolen = false
                        State.AutoFarmLevel = false
                        State.AutoFarmMoney = false
                        State.UnlimitedMolen = false
                        stopAutoMolen()
                        stopAutoFarm()
                        if unlimitedConn then unlimitedConn:Disconnect() end
                        Window:Destroy()
                end,
        })
end

-- ============================================================
-- Notify on Load
-- ============================================================
WindUI:Notify({
        Title = "Zetttify | Auto Molen",
        Content = "Script loaded! Aktifkan Auto Farm Molen untuk mulai bekerja otomatis.",
        Icon = "solar:check-circle-bold",
        Duration = 5,
})
