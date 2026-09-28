-- | Services | --
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Terrain = Workspace.Terrain

-- | VM Modules | --
local VM = {}

-- | [1] Skybox & Lighting Setup & Kill Sun | --
VM[1] = function()
    local SkyIDs = {
        Bk = 92959017845968, Ft = 129304841254693, Lf = 129249062260004,
        Rt = 117319232583147, Up = 121193772599100, Dn = 115022734343595
    }

    local function applySky(sky)
        if not sky:IsA("Sky") then return end
        pcall(function()
            for k, id in pairs(SkyIDs) do
                local prop = "Skybox" .. k
                local targetId = "rbxassetid://" .. id
                if sky[prop] ~= targetId then
                    sky[prop] = targetId
                end
            end
            sky.SunAngularSize = 0
            sky.SunTextureId = ""
            sky.MoonAngularSize = 0
            sky.MoonTextureId = ""
        end)
    end

    local function enforceLighting()
        pcall(function()
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = false
            Lighting.Brightness = 0.8
            Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
            Lighting.Ambient = Color3.fromRGB(120, 120, 120)
            Lighting.ExposureCompensation = -0.2
            Lighting.FogStart = 9e9
            Lighting.FogEnd = 9e9

            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("Sky") then
                    applySky(v)
                elseif v:IsA("Atmosphere") then
                    v.Density = 0
                    v.Haze = 0
                    v.Glare = 0
                elseif v:IsA("PostEffect") or v:IsA("SunRaysEffect") then
                    v.Enabled = false
                end
            end
        end)
    end

    if not Lighting:FindFirstChildOfClass("Sky") then
        local sky = Instance.new("Sky")
        sky.Name = "CustomSky"
        applySky(sky)
        sky.Parent = Lighting
    end

    enforceLighting()

    Lighting.Changed:Connect(enforceLighting)
    Lighting.ChildAdded:Connect(function()
        task.wait()
        enforceLighting()
    end)
end

-- | [2] Clouds Removal | --
VM[2] = function()
    if Terrain then
        for _, v in ipairs(Terrain:GetChildren()) do
            if v:IsA("Clouds") then pcall(function() v.Enabled = false end) end
        end
        Terrain.ChildAdded:Connect(function(v)
            if v:IsA("Clouds") then pcall(function() v.Enabled = false end) end
        end)
    end
end

-- | [3] Tree & 3D Removal | --
VM[3] = function()
    task.spawn(function()
        local map = Workspace:WaitForChild("Map", 5) or Workspace:FindFirstChild("Map")
        if map then
            local function cleanMapChild(v)
                local name = v.Name:lower()
                if name:find("tree") or name == "3d" then
                    pcall(function() v:Destroy() end)
                end
            end

            for _, child in ipairs(map:GetChildren()) do
                cleanMapChild(child)
            end
            map.ChildAdded:Connect(cleanMapChild)
        end
    end)
end

-- | [4] Character Effect & Smoke Removal | --
VM[4] = function()
    local BLUE = Color3.fromRGB(0, 85, 190)

    local function isSmoke(name)
        name = name:lower()
        return name:find("smoke") or name:find("dust") or name:find("dirt") or name:find("puff")
    end

    local function handleParticle(v)
        pcall(function()
            if v:IsA("Smoke") then
                v.Enabled = false
                v:Destroy()
            elseif v:IsA("Trail") then
                v.Color = ColorSequence.new(BLUE)
                v.Texture = ""
                v.LightEmission = 0.8
            elseif v:IsA("ParticleEmitter") then
                if isSmoke(v.Name) then
                    v.Enabled = false
                    v:Clear()
                    v:Destroy()
                else
                    v.Color = ColorSequence.new(BLUE)
                    v.LightEmission = 1
                end
            end
        end)
    end

    local function applyCharacterEffects(char)
        if not char then return end

        for _, v in ipairs(char:GetDescendants()) do
            handleParticle(v)
        end

        char.DescendantAdded:Connect(handleParticle)
    end

    if LocalPlayer.Character then applyCharacterEffects(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(applyCharacterEffects)

    task.spawn(function()
        local function cleanCloneOrSmoke(obj)
            if not obj then return end
            if obj == LocalPlayer.Character or obj:IsDescendantOf(LocalPlayer.Character) then return end

            local name = obj.Name:lower()
            local lpName = LocalPlayer.Name:lower()

            if isSmoke(name) or obj:IsA("Smoke") then
                pcall(function()
                    if obj:IsA("ParticleEmitter") then
                        obj.Enabled = false
                        obj:Clear()
                    end
                    obj:Destroy()
                end)
                return
            end

            for _, v in ipairs(obj:GetDescendants()) do
                if v:IsA("Smoke") or (v:IsA("ParticleEmitter") and isSmoke(v.Name)) then
                    pcall(function()
                        if v:IsA("ParticleEmitter") then
                            v.Enabled = false
                            v:Clear()
                        end
                        v:Destroy()
                    end)
                end
            end

            local isClone = (name == lpName)
                or name:find("clone")
                or name:find("afterimage")
                or name:find("ghost")
                or name:find("flowing")

            if not isClone and obj:IsA("Model") and obj:FindFirstChild("Head") and (obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")) then
                if not Players:GetPlayerFromCharacter(obj) and not name:find("dummy") then
                    isClone = true
                end
            end

            if isClone then
                pcall(function()
                    if obj:IsA("BasePart") then
                        obj.Transparency = 1
                        obj.CanCollide = false
                        obj:Destroy()
                    elseif obj:IsA("Model") then
                        for _, v in ipairs(obj:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.Transparency = 1
                                v.CanCollide = false
                            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                                v.Enabled = false
                            end
                        end
                        obj:Destroy()
                    end
                end)
            end
        end

        for _, child in ipairs(Workspace:GetChildren()) do
            cleanCloneOrSmoke(child)
        end

        Workspace.ChildAdded:Connect(function(child)
            task.defer(cleanCloneOrSmoke, child)
        end)

        Workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("Smoke") or (desc:IsA("ParticleEmitter") and isSmoke(desc.Name)) then
                task.defer(function()
                    pcall(function()
                        if desc:IsA("ParticleEmitter") then
                            desc.Enabled = false
                            desc:Clear()
                        end
                        desc:Destroy()
                    end)
                end)
            end
        end)

        local thrown = Workspace:FindFirstChild("Thrown")
        if thrown then
            thrown.ChildAdded:Connect(function(child)
                task.defer(cleanCloneOrSmoke, child)
            end)
        end
    end)
end

-- | [5] FPS & Ping | --
VM[5] = function()
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")

        local oldGui = playerGui:FindFirstChild("FPSPingCounter")
        if oldGui then oldGui:Destroy() end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FPSPingCounter"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = playerGui

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 300, 0, 30)
        label.Position = UDim2.new(0.5, 0, 0, 10)
        label.AnchorPoint = Vector2.new(0.5, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Code
        label.TextSize = 16
        label.TextStrokeTransparency = 0.4
        label.Parent = screenGui

        local fps, ping, lastTime = 60, 0, os.clock()

        RunService.RenderStepped:Connect(function()
            local now = os.clock()
            local curFPS = 1 / math.max(now - lastTime, 0.0001)
            lastTime = now
            fps = fps + (curFPS - fps) * 0.1

            pcall(function() 
                ping = LocalPlayer:GetNetworkPing() * 1000 
            end)

            label.Text = string.format("FPS: %d | PING: %d ms", math.floor(fps), math.floor(ping))
            label.TextColor3 = Color3.fromHSV((now * 0.4) % 1, 0.8, 1)
        end)
    end)
end

-- | [6] Camera Shake Removal | --
VM[6] = function()
    if getrawmetatable and setreadonly then
        pcall(function()
            local meta = getrawmetatable(game)
            local oldIndex = meta.__index
            setreadonly(meta, false)
            meta.__index = newcclosure(function(obj, key)
                if key == "CamShakeCF" and obj == _G then return CFrame.new() end
                if key == "CameraOffset" and obj:IsA("Humanoid") then return Vector3.zero end
                return oldIndex(obj, key)
            end)
            setreadonly(meta, true)
        end)
    end
end

-- | [7] Debris Cleaner | --
VM[7] = function()
    task.spawn(function()
        local function eliminate(obj)
            if not obj then return end
            if obj:FindFirstChildOfClass("Humanoid") or (obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid")) then
                return
            end

            pcall(function()
                if obj:IsA("BasePart") then
                    obj.Transparency = 1
                    obj.CanCollide = false
                elseif obj:IsA("Model") then
                    for _, p in ipairs(obj:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.Transparency = 1
                            p.CanCollide = false
                        end
                    end
                end
                obj:Destroy()
            end)
        end

        local function checkMatch(name)
            name = name:lower()
            return name:find("debris") or name:find("starterdeb") or name:find("vfxdebris")
        end

        local function hookThrown(folder)
            if not folder then return end
            
            for _, child in ipairs(folder:GetChildren()) do
                eliminate(child)
            end

            folder.ChildAdded:Connect(function(child)
                task.defer(eliminate, child)
            end)
        end

        local thrown = Workspace:WaitForChild("Thrown", 3) or Workspace:FindFirstChild("Thrown")
        if thrown then hookThrown(thrown) end

        local function inspectWorkspaceChild(child)
            task.defer(function()
                if not child or not child.Parent then return end
                
                local name = child.Name:lower()
                
                if name:find("vfxdebris") then
                    pcall(function()
                        child:ClearAllChildren()
                    end)
                    child.ChildAdded:Connect(function(v)
                        task.defer(eliminate, v)
                    end)
                    child.DescendantAdded:Connect(function(v)
                        task.defer(eliminate, v)
                    end)
                elseif checkMatch(name) then
                    eliminate(child)
                end
            end)
        end

        for _, child in ipairs(Workspace:GetChildren()) do
            if child.Name == "Thrown" then
                hookThrown(child)
            else
                inspectWorkspaceChild(child)
            end
        end

        Workspace.ChildAdded:Connect(function(child)
            if child.Name == "Thrown" then
                hookThrown(child)
            else
                inspectWorkspaceChild(child)
            end
        end)
    end)
end

-- | Execution | --
for i = 1, #VM do
    pcall(VM[i])
end

pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
