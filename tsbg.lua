-- | Made By m7za | --

-- | configuration | --
local garou_mode = (getgenv and getgenv().garou_effects) or _G.garou_effects or garou_effects or "transparent"
local is_blue = tostring(garou_mode):lower() == "blue"

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
            if sky[prop] ~= id then sky[prop] = id end
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

-- | clouds & trees removal | --
local function remove_clouds()
    if not terrain then return end
    for _, item in ipairs(terrain:GetChildren()) do
        if item:IsA("Clouds") then item.Enabled = false end
    end
    terrain.ChildAdded:Connect(function(item)
        if item:IsA("Clouds") then item.Enabled = false end
    end)
end

local function remove_trees()
    local map = workspace:WaitForChild("Map", 5) or workspace:FindFirstChild("Map")
    if not map then return end

    local function check_and_destroy(item)
        local name = item.Name:lower()
        if name:find("tree") or name == "3d" then
            item:Destroy()
        end
    end

    for _, child in ipairs(map:GetChildren()) do check_and_destroy(child) end
    map.ChildAdded:Connect(check_and_destroy)
end

-- | filters for smoke, lethal whirlwind beam & flowing water | --
local function is_smoke(name)
    return name:find("smoke") or name:find("dust") or name:find("dirt") 
        or name:find("puff") or name:find("cloud") or name:find("ground") 
        or name:find("smokering") or name:find("nadosmoke") or name:find("debris")
end

local function is_garou_vfx(name)
    -- Flowing Water (Скилл 1)
    local is_fw = name:find("water") or name:find("flow") or name:find("stream")
        or name:find("rocksmash") or name:find("fang") or name:find("slash")
        or name:find("fist") or name:find("flowing")
    
    -- Lethal Whirlwind Stream (Скилл 2 + столб света в небо)
    local is_lws = name:find("whirlwind") or name:find("lethal") or name:find("middlespin")
        or name:find("tornadomain") or name:find("tornado") or name:find("nado")
        or name:find("spiral") or name:find("wind") or name:find("pillar")
        or name:find("up") or name:find("up2") or name:find("beam") or name:find("cylinder")
        
    return is_fw or is_lws
end

local function purge_visual(item)
    if not item then return end
    pcall(function()
        if item:IsA("ParticleEmitter") then
            item.Enabled = false
            item.Rate = 0
            item.Transparency = NumberSequence.new(1)
            item:Clear()
        elseif item:IsA("Trail") or item:IsA("Beam") or item:IsA("Highlight") or item:IsA("Smoke") or item:IsA("Fire") or item:IsA("Light") then
            item.Enabled = false
        elseif item:IsA("BasePart") then
            item.Transparency = 1
            item.CanCollide = false
        end
        item:Destroy()
    end)
end

-- Проверка на огромный неоновый столб (Lethal Whirlwind Stream)
local function is_vertical_beam(part)
    if part:IsA("BasePart") then
        local size = part.Size
        -- Если деталь вытянута вертикально более чем на 15 studs или имеет неоновый голубой свет
        if size.Y > 15 or size.Z > 15 or size.X > 15 then
            if part.Material == Enum.Material.Neon or part.Material == Enum.Material.ForceField then
                return true
            end
        end
    end
    return false
end

-- | live entities (players + dummies) handler | --
local function setup_entities_and_world()
    local function process_descendant(item)
        if not item then return end
        local name = item.Name:lower()

        -- Фото 3: Удаление любого смока
        if item:IsA("Smoke") or is_smoke(name) then
            purge_visual(item)
            return
        end

        -- Фото 1 и Фото 2: Удаление скиллов и эффектов ударов
        if is_garou_vfx(name) or is_vertical_beam(item) then
            purge_visual(item)
            return
        end

        -- Трейлы и эмиттеры на конечностях персонажа/манекена
        if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
            local p_name = item.Parent and item.Parent.Name:lower() or ""
            if is_garou_vfx(p_name) or is_smoke(p_name) then
                purge_visual(item)
            end
        end
    end

    local function hook_entity(model)
        if not model or not model:IsA("Model") then return end
        for _, desc in ipairs(model:GetDescendants()) do
            process_descendant(desc)
        end
        model.DescendantAdded:Connect(process_descendant)
    end

    -- Обработка всех манекенов (Weakest Dummy) и персонажей
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            hook_entity(obj)
        else
            process_descendant(obj)
        end
    end

    workspace.DescendantAdded:Connect(function(item)
        task.defer(function()
            if item:IsA("Model") and item:FindFirstChildOfClass("Humanoid") then
                hook_entity(item)
            else
                process_descendant(item)
            end
        end)
    end)
end

-- | debris & thrown folder cleaner | --
local function start_debris_cleaner()
    local safe_whitelist = {
        ["debris2g"] = true,
        ["projectile"] = true,
        ["flash"] = true,
        ["shurikenproj"] = true,
        ["proj"] = true,
        ["dragon"] = true,
        ["kingcrab"] = true
    }

    local function inspect_thrown(obj)
        if not obj or not obj.Parent then return end
        local name = obj.Name:lower()

        -- Никаких исключений для скиллов Гароу и дыма
        if is_smoke(name) or is_garou_vfx(name) or is_vertical_beam(obj) then
            purge_visual(obj)
            return
        end

        if safe_whitelist[name] then return end
        if obj:FindFirstChildOfClass("Humanoid") then return end

        if obj:IsA("BasePart") or obj:IsA("Model") then
            purge_visual(obj)
        end
    end

    local thrown = workspace:WaitForChild("Thrown", 3) or workspace:FindFirstChild("Thrown")
    if thrown then
        for _, child in ipairs(thrown:GetChildren()) do inspect_thrown(child) end
        thrown.ChildAdded:Connect(function(child)
            task.defer(inspect_thrown, child)
        end)
    end
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

-- | camera shake removal | --
local function remove_camera_shake()
    if not (getrawmetatable and setreadonly) then return end
    local meta = getrawmetatable(game)
    local old_index = meta.__index
    setreadonly(meta, false)
    meta.__index = newcclosure(function(obj, key)
        if key == "CamShakeCF" and obj == _G then return CFrame.new() end
        if key == "CameraOffset" and obj:IsA("Humanoid") then return Vector3.zero end
        return old_index(obj, key)
    end)
    setreadonly(meta, true)
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
    setup_entities_and_world,
    create_fps_counter,
    remove_camera_shake,
    start_debris_cleaner,
    unlock_fps
}

for _, run_module in ipairs(modules) do
    task.spawn(pcall, run_module)
end

pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 
end)
