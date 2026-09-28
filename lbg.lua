local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local lp = Players.LocalPlayer
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

do
    local marker = CoreGui:FindFirstChild("LBG_Loaded")
    if marker then
        return
    end
    local ok = pcall(function()
        local flag = Instance.new("BoolValue")
        flag.Name = "LBG_Loaded"
        flag.Parent = CoreGui
    end)
    if not ok then
        if _G.LBG_Loaded then return end
        _G.LBG_Loaded = true
    end
end

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
        })
    end)
end

local function safeConnect(sig, fn)
    local ok, conn = pcall(function() return sig:Connect(fn) end)
    if ok then return conn end
end

local function processDescendantsChunked(parent, callback, chunkSize)
    chunkSize = chunkSize or 250
    task.spawn(function()
        local count = 0
        for _, v in ipairs(parent:GetDescendants()) do
            pcall(callback, v)
            count = count + 1
            if count % chunkSize == 0 then
                task.wait()
            end
        end
    end)
end

notify("Script Loaded!", "my discord is m7za1")

local function makeTransparent(v)
    pcall(function()
        if v:IsA("ParticleEmitter") then
            v.Transparency = NumberSequence.new(1)
            v.LightEmission = 0
            v.Enabled = false
        elseif v:IsA("Trail") then
            v.Transparency = NumberSequence.new(1)
            v.LightEmission = 0
            v.Enabled = false
        elseif v:IsA("Beam") then
            v.Transparency = NumberSequence.new(1)
            v.LightEmission = 0
            v.Enabled = false
        elseif v:IsA("Highlight") then
            v.FillTransparency = 1
            v.OutlineTransparency = 1
        elseif v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            local pName = string.lower(v.Parent and v.Parent.Name or "")
            if string.find(pName, "fx") or string.find(pName, "slash") or string.find(pName, "hit") or string.find(pName, "aura") then
                v.Transparency = 1
            end
        elseif v:IsA("BasePart") then
            local name = string.lower(v.Name)
            local isNeon = (v.Material == Enum.Material.Neon)
            local isFxName = string.find(name, "fx") or string.find(name, "effect") or string.find(name, "aura") or string.find(name, "slash") or string.find(name, "wave") or string.find(name, "blast") or string.find(name, "ring") or string.find(name, "sphere")

            if isNeon or isFxName then
                local isCharacterLimb = v.Parent and v.Parent:FindFirstChildOfClass("Humanoid")
                if not isCharacterLimb then
                    v.Transparency = 1
                end
            end
        end
    end)
end

local VM = {}

VM[1] = function()
    processDescendantsChunked(Workspace, makeTransparent)

    safeConnect(Workspace.DescendantAdded, function(v)
        makeTransparent(v)
    end)
end

VM[2] = function()
    local SkyIDs = {
        Bk = 92959017845968, Ft = 129304841254693, Lf = 129249062260004,
        Rt = 117319232583147, Up = 121193772599100, Dn = 115022734343595
    }

    local function applySky()
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Sky") then
                pcall(function() v:Destroy() end)
            end
        end

        pcall(function()
            local s = Instance.new("Sky")
            for k, id in pairs(SkyIDs) do
                s["Skybox" .. k] = "rbxassetid://" .. id
            end
            s.Parent = Lighting
        end)
    end

    applySky()

    safeConnect(lp.CharacterAdded, function()
        task.wait(0.5)
        applySky()
    end)
end

VM[3] = function()
    local function cleanLighting()
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
        Lighting.Brightness = 0.8
        Lighting.ExposureCompensation = -0.2
        Lighting.FogStart, Lighting.FogEnd = 9e9, 9e9

        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("SunRaysEffect") then
                v.Enabled = false
            end
        end
    end

    cleanLighting()

    safeConnect(lp.CharacterAdded, function()
        task.wait(0.5)
        cleanLighting()
    end)
end

VM[4] = function()
    safeConnect(Workspace.DescendantAdded, function(v)
        if v:IsA("Smoke") then
            pcall(function() v:Destroy() end)
        end
    end)
end

VM[5] = function()
    if not Terrain then return end
    for _, v in ipairs(Terrain:GetChildren()) do
        if v:IsA("Clouds") then v.Enabled = false end
    end
    safeConnect(Terrain.ChildAdded, function(v)
        if v:IsA("Clouds") then v.Enabled = false end
    end)
end

VM[6] = function()
    local function killSun()
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then
            sky.SunAngularSize = 0
            sky.SunTextureId = ""
            sky.MoonAngularSize = 0
            sky.MoonTextureId = ""
        end
    end

    killSun()

    local at = Lighting:FindFirstChildOfClass("Atmosphere")
    if at then
        at.Density = 0
        at.Haze = 0
        at.Glare = 0
    end

    safeConnect(Lighting.ChildAdded, function(v)
        if v:IsA("Sky") then
            task.wait()
            killSun()
        elseif v:IsA("Atmosphere") then
            v.Density = 0
            v.Haze = 0
            v.Glare = 0
        end
    end)
end

VM[7] = function()
    local floraKeywords = {"tree", "bush", "leaf", "leaves", "foliage", "branch", "grass", "pine", "wood"}

    local function checkAndDestroy(v)
        if v:IsA("Model") or v:IsA("Part") or v:IsA("MeshPart") then
            local name = string.lower(v.Name)
            for _, word in ipairs(floraKeywords) do
                if string.find(name, word) then
                    pcall(function() v:Destroy() end)
                    break
                end
            end
        end
    end

    processDescendantsChunked(Workspace, checkAndDestroy)

    safeConnect(Workspace.DescendantAdded, function(v)
        task.wait()
        checkAndDestroy(v)
    end)
end

VM[8] = function()
    local ok, meta = pcall(getrawmetatable, game)
    if not ok or not meta then return end

    local old = meta.__index
    local setOk = pcall(setreadonly, meta, false)
    if not setOk then return end

    meta.__index = newcclosure(function(obj, key)
        if key == "CamShakeCF" and obj == _G then
            return CFrame.new()
        end

        if typeof(obj) == "Instance" and obj:IsA("Humanoid") and key == "CameraOffset" then
            return Vector3.new(0, 0, 0)
        end

        return old(obj, key)
    end)

    pcall(setreadonly, meta, true)

    safeConnect(RunService.Heartbeat, function()
        rawset(_G, "CamShakeCF", CFrame.new())
    end)
    safeConnect(RunService.RenderStepped, function()
        rawset(_G, "CamShakeCF", CFrame.new())
    end)
end

VM[9] = function()
    local playerGui = lp:WaitForChild("PlayerGui")

    local oldGui = playerGui:FindFirstChild("FPSPingCounter")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FPSPingCounter"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local counterLabel = Instance.new("TextLabel")
    counterLabel.Size = UDim2.new(0, 300, 0, 30)
    counterLabel.Position = UDim2.new(0.5, 0, 0, 10)
    counterLabel.AnchorPoint = Vector2.new(0.5, 0)
    counterLabel.BackgroundTransparency = 1
    counterLabel.Text = "FPS: 0 | PING: 0 ms"
    counterLabel.Font = Enum.Font.Code
    counterLabel.TextSize = 16
    counterLabel.TextStrokeTransparency = 0.4
    counterLabel.TextXAlignment = Enum.TextXAlignment.Center
    counterLabel.Parent = screenGui

    local displayedFPS = 0
    local displayedPing = 0
    local lastTime = tick()

    safeConnect(RunService.RenderStepped, function()
        local currentTime = tick()
        local fps = 1 / math.max(currentTime - lastTime, 0.0001)
        lastTime = currentTime

        local ping = 0
        pcall(function()
            ping = lp:GetNetworkPing() * 1000
        end)

        displayedFPS = displayedFPS + (fps - displayedFPS) * 0.1
        displayedPing = displayedPing + (ping - displayedPing) * 0.1

        counterLabel.Text = string.format("FPS: %d | PING: %d ms", math.floor(displayedFPS), math.floor(displayedPing))

        local hue = (currentTime * 0.4) % 1
        counterLabel.TextColor3 = Color3.fromHSV(hue, 0.8, 1)
    end)
end

local order = {1, 2, 3, 4, 5, 6, 7, 8, 9}
while #order > 0 do
    local i = math.random(#order)
    pcall(VM[order[i]])
    table.remove(order, i)
end

pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)