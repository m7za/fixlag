-- | Made By m7za | --

-- | configuration | --
local garou_mode = (getgenv and getgenv().garou_effects) or _G.garou_effects or garou_effects or "transparent"
local is_blue = tostring(garou_mode):lower() == "blue"
local blue_color = Color3.fromRGB(0, 85, 190)

-- | services | --
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local run_service = game:GetService("RunService")

local local_player = players.LocalPlayer
local terrain = workspace.Terrain
local player_gui = local_player:WaitForChild("PlayerGui")

-- | skybox & lighting | --
local function setup_lighting()
    local sky_textures = {
        Bk = "rbxassetid://92959017845968",
        Ft = "rbxassetid://129304841254693",
        Lf = "rbxassetid://129249062260004",
        Rt = "rbxassetid://117319232583147",
        Up = "rbxassetid://121193772599100",
        Dn = "rbxassetid://115022734343595"
    }

    local function apply_sky(sky)
        if not sky:IsA("Sky") then return end
        for side, id in pairs(sky_textures) do
            local prop = "Skybox" .. side
            if sky[prop] ~= id then
                sky[prop] = id
            end
        end
        sky.SunAngularSize = 0
        sky.SunTextureId = ""
        sky.MoonAngularSize = 0
        sky.MoonTextureId = ""
    end

    local function update_lighting()
        lighting.ClockTime = 12
        lighting.GlobalShadows = false
        lighting.Brightness = 0.8
        lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
        lighting.Ambient = Color3.fromRGB(120, 120, 120)
        lighting.ExposureCompensation = -0.2
        lighting.FogStart = 9e9
        lighting.FogEnd = 9e9

        for _, item in ipairs(lighting:GetChildren()) do
            if item:IsA("Sky") then
                apply_sky(item)
            elseif item:IsA("Atmosphere") then
                item.Density = 0
                item.Haze = 0
                item.Glare = 0
            elseif item:IsA("PostEffect") or item:IsA("SunRaysEffect") then
                item.Enabled = false
            end
        end
    end

    local custom_sky = lighting:FindFirstChildOfClass("Sky")
    if not custom_sky then
        custom_sky = Instance.new("Sky")
        custom_sky.Name = "CustomSky"
        custom_sky.Parent = lighting
    end
    apply_sky(custom_sky)

    update_lighting()
    lighting.Changed:Connect(update_lighting)
    lighting.ChildAdded:Connect(function()
        task.wait()
        update_lighting()
    end)
end

-- | clouds removal | --
local function remove_clouds()
    if not terrain then return end
    for _, item in ipairs(terrain:GetChildren()) do
        if item:IsA("Clouds") then item.Enabled = false end
    end
    terrain.ChildAdded:Connect(function(item)
        if item:IsA("Clouds") then item.Enabled = false end
    end)
end

-- | tree & 3d removal | --
local function remove_trees()
    local map = workspace:WaitForChild("Map", 5) or workspace:FindFirstChild("Map")
    if not map then return end

    local function check_and_hide(item)
        local name = item.Name:lower()
        if name:find("tree") or name == "3d" then
            if item:IsA("BasePart") then
                item.Transparency = 1
                item.CanCollide = false
            elseif item:IsA("Model") then
                for _, part in ipairs(item:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 1
                        part.CanCollide = false
                    end
                end
            end
        end
    end

    for _, child in ipairs(map:GetChildren()) do
        check_and_hide(child)
    end
    map.ChildAdded:Connect(check_and_hide)
end

-- | filters | --
local function is_smoke_name(str)
    return str:find("smoke") or str:find("dust") or str:find("dirt") 
        or str:find("puff") or str:find("smokering") or str:find("nadosmoke")
        or str:find("grounddust")
end

local function is_garou_name(str)
    return str:find("water") or str:find("flow") or str:find("stream") 
        or str:find("whirlwind") or str:find("hunter") or str:find("slash")
        or str:find("fang") or str:find("nado") or str:find("lethal")
        or str:find("rocksmash") or str:find("aura") or str:find("middlespin")
        or str:find("spiral") or str:find("tornadomain")
end

-- | safe visual silencer (не ломает логику игры и UI) | --
local function silence_visual(item)
    if not item or not item.Parent then return end

    -- Защита интерфейса и персонажей
    if item:IsDescendantOf(player_gui) or item:IsA("GuiObject") or item:IsA("Humanoid") then
        return
    end

    local name = item.Name:lower()
    local parent_name = item.Parent.Name:lower()
    local full_context = name .. " " .. parent_name

    -- 1. Смок и пыль (глушим без удаления, чтобы скрипты игры не крашились)
    if item:IsA("Smoke") then
        item.Enabled = false
        item.Opacity = 0
        return
    elseif item:IsA("ParticleEmitter") and is_smoke_name(full_context) then
        item.Enabled = false
        item.Rate = 0
        item.Transparency = NumberSequence.new(1)
        item:Clear()
        return
    end

    -- 2. Эффекты Гароу
    if is_garou_name(full_context) then
        if is_blue then
            if item:IsA("ParticleEmitter") then
                item.Color = ColorSequence.new(blue_color)
                item.LightEmission = 1
            elseif item:IsA("Trail") or item:IsA("Beam") then
                item.Color = ColorSequence.new(blue_color)
            end
        else
            -- Режим transparent: скрываем рендер
            if item:IsA("ParticleEmitter") then
                item.Enabled = false
                item.Rate = 0
                item.Transparency = NumberSequence.new(1)
                item:Clear()
            elseif item:IsA("Trail") or item:IsA("Beam") or item:IsA("Highlight") then
                item.Enabled = false
            elseif item:IsA("MeshPart") and not item.Parent:FindFirstChildOfClass("Humanoid") then
                item.Transparency = 1
            end
        end
        return
    end

    -- 3. Осколки от ударов (debris)
    if (name:find("debris") or name:find("vfxdebris")) and item:IsA("BasePart") then
        if not item.Parent:FindFirstChildOfClass("Humanoid") then
            item.Transparency = 1
            item.CastShadow = false
        end
    end
end

-- | character & vfx hooks | --
local function setup_character_and_effects()
    local function hook_container(folder)
        if not folder then return end
        for _, desc in ipairs(folder:GetDescendants()) do
            silence_visual(desc)
        end
        folder.DescendantAdded:Connect(function(desc)
            task.defer(silence_visual, desc)
        end)
    end

    -- Папка живых игроков в TSB
    local live_folder = workspace:WaitForChild("Live", 5) or workspace:FindFirstChild("Live")
    if live_folder then
        hook_container(live_folder)
    end

    -- Летящие эффекты
    local thrown = workspace:WaitForChild("Thrown", 5) or workspace:FindFirstChild("Thrown")
    if thrown then
        hook_container(thrown)
    end

    -- Объекты, появляющиеся прямо в Workspace
    workspace.ChildAdded:Connect(function(child)
        task.defer(function()
            if not child or not child.Parent then return end
            if child.Name ~= "Live" and child.Name ~= "Thrown" and child.Name ~= "Terrain" and child.Name ~= "Map" then
                silence_visual(child)
                hook_container(child)
            end
        end)
    end)
end

-- | fps & ping counter | --
local function create_fps_counter()
    local existing_gui = player_gui:FindFirstChild("FPSPingCounter")
    if existing_gui then existing_gui:Destroy() end

    local screen_gui = Instance.new("ScreenGui")
    screen_gui.Name = "FPSPingCounter"
    screen_gui.ResetOnSpawn = false
    screen_gui.Parent = player_gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 300, 0, 30)
    label.Position = UDim2.new(0.5, 0, 0, 10)
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.TextSize = 16
    label.TextStrokeTransparency = 0.4
    label.Parent = screen_gui

    local current_fps = 60
    local last_tick = os.clock()

    run_service.RenderStepped:Connect(function()
        local now = os.clock()
        local frame_fps = 1 / math.max(now - last_tick, 0.0001)
        last_tick = now
        current_fps = current_fps + (frame_fps - current_fps) * 0.1

        local ping = (local_player:GetNetworkPing() or 0) * 1000
        label.Text = string.format("FPS: %d | PING: %d ms", math.floor(current_fps), math.floor(ping))
        label.TextColor3 = Color3.fromHSV((now * 0.4) % 1, 0.8, 1)
    end)
end

-- | fps unlocker | --
local function unlock_fps()
    local uncap = setfpscap or set_fps_cap
    if uncap then uncap(999) end
end

-- | execution | --
local modules = {
    setup_lighting,
    remove_clouds,
    remove_trees,
    setup_character_and_effects,
    create_fps_counter,
    unlock_fps
}

for _, run_module in ipairs(modules) do
    task.spawn(pcall, run_module)
end

-- | engine settings | --
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 
end)