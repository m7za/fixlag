-- | Made By m7za | --

if _G.tsb_optimizer_loaded then return end
_G.tsb_optimizer_loaded = true

-- | services | --
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local run_service = game:GetService("RunService")
local user_input_service = game:GetService("UserInputService")

local local_player = players.LocalPlayer
local terrain = workspace:FindFirstChildOfClass("Terrain") or workspace.Terrain
local player_gui = local_player:WaitForChild("PlayerGui")

-- | UTIL | --
local function safe_connect(sig, fn)
    pcall(function() sig:Connect(fn) end)
end

-- | vm instructions | --
local vm = {}

-- | [1] skybox & lighting system | --
vm[1] = function()
    local sky_textures = {
        Bk = "rbxassetid://92959017845968",
        Ft = "rbxassetid://129304841254693",
        Lf = "rbxassetid://129249062260004",
        Rt = "rbxassetid://117319232583147",
        Up = "rbxassetid://121193772599100",
        Dn = "rbxassetid://115022734343595"
    }

    local function apply_sky(sky)
        if not sky or not sky:IsA("Sky") then return end
        for side, id in pairs(sky_textures) do
            local prop = "Skybox" .. side
            if sky[prop] ~= id then sky[prop] = id end
        end
        sky.SunAngularSize = 0
        sky.SunTextureId = ""
        sky.MoonAngularSize = 0
        sky.MoonTextureId = ""
    end

    local is_updating = false
    local function update_lighting()
        if is_updating then return end
        is_updating = true

        pcall(function()
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
        end)

        is_updating = false
    end

    local custom_sky = lighting:FindFirstChildOfClass("Sky")
    if not custom_sky then
        custom_sky = Instance.new("Sky")
        custom_sky.Name = "custom_sky"
        custom_sky.Parent = lighting
    end
    apply_sky(custom_sky)

    update_lighting()
    safe_connect(lighting.Changed, update_lighting)
    safe_connect(lighting.ChildAdded, function()
        task.defer(update_lighting)
    end)
end

-- | [2] clouds removal | --
vm[2] = function()
    if not terrain then return end

    pcall(function()
        terrain.Decoration = false
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
    end)

    local function purge_cloud(child)
        if child and (child:IsA("Clouds") or child.Name:lower() == "clouds") then
            pcall(function()
                child.Enabled = false
                child.Cover = 0
                child.Density = 0
                child:Destroy()
            end)
        end
    end

    for _, child in ipairs(terrain:GetChildren()) do
        purge_cloud(child)
    end
    safe_connect(terrain.ChildAdded, purge_cloud)
end

-- | [3] world cleaner | --
vm[3] = function()
    local function clean_map_part(obj)
        if not obj:IsA("BasePart") or not obj.Anchored or not obj.CanCollide then return end
        pcall(function()
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
                    task.defer(function()
                        if child and child.Parent then child:Destroy() end
                    end)
                end
            end
            if obj:IsA("MeshPart") then obj.TextureID = "" end
        end)
    end

    local function check_tree(item)
        local name = item.Name:lower()
        if name:find("tree") or name == "3d" then
            task.defer(function()
                if item and item.Parent then item:Destroy() end
            end)
        end
    end

    local function hook_map(map)
        for _, child in ipairs(map:GetChildren()) do check_tree(child) end
        safe_connect(map.ChildAdded, check_tree)
    end

    local map = workspace:FindFirstChild("Map")
    if map then hook_map(map) end
    safe_connect(workspace.ChildAdded, function(c)
        if c.Name == "Map" then hook_map(c) end
    end)

    for _, desc in ipairs(workspace:GetDescendants()) do clean_map_part(desc) end
    safe_connect(workspace.DescendantAdded, function(desc)
        task.defer(clean_map_part, desc)
    end)
end

-- | [4] effects removal  | --
vm[4] = function()
    local body_parts = {
        ["head"] = true, ["torso"] = true, ["humanoidrootpart"] = true,
        ["left arm"] = true, ["right arm"] = true, ["left leg"] = true, ["right leg"] = true,
        ["uppertorso"] = true, ["lowertorso"] = true, ["leftupperarm"] = true, ["rightupperarm"] = true,
        ["leftlowerarm"] = true, ["rightlowerarm"] = true, ["leftupperleg"] = true, ["rightupperleg"] = true,
        ["leftlowerleg"] = true, ["rightlowerleg"] = true
    }

    local function is_real_player(model)
        if not model or not model:IsA("Model") then return false end
        if model == local_player.Character then return true end
        if players:GetPlayerFromCharacter(model) then return true end
        if model.Name:lower():find("dummy") then return true end
        return false
    end

    -- | flowing water effects removal | --
    local function is_clone_or_afterimage(item)
        if not item or not item.Parent then return false end

        if local_player.Character and (item == local_player.Character or item:IsDescendantOf(local_player.Character)) then
            return false
        end

        local model = item:IsA("Model") and item or item:FindFirstAncestorOfClass("Model")
        if model and is_real_player(model) then
            return false
        end

        local name = item.Name:lower()

        if name:find("afterimage")
            or name:find("watertrail")
            or name:find("clone")
            or name:find("ghost")
            or name:find("shadow") then
            return true
        end

        if item:IsA("BasePart") and body_parts[name] and item.Parent == workspace then
            return true
        end

        return false
    end

    -- | smoke & dust detector | --
    local function is_smoke_fx(item)
        if not item or not item.Parent then return false end
        if local_player.Character and item:IsDescendantOf(local_player.Character) then
            return false
        end
        if item:IsA("Smoke") then return true end

        local name = item.Name:lower()
        if name:find("smoke") or name:find("dust") or name:find("dirt") 
            or name:find("puff") or name:find("ground") or name:find("land")
            or name:find("nadosmoke") or name:find("smokering") then
            return true
        end

        if item:IsA("ParticleEmitter") then
            local p_name = item.Parent and item.Parent.Name:lower() or ""
            if p_name:find("smoke") or p_name:find("dust") or p_name:find("dirt")
                or p_name:find("puff") or p_name:find("nado") or p_name:find("ground") then
                return true
            end
        end

        return false
    end

    -- | garou attack detector | --
    local function is_garou_attack(name)
        return name:find("water") or name:find("flow") or name:find("stream") 
            or name:find("whirlwind") or name:find("hunter") or name:find("slash")
            or name:find("fang") or name:find("nado") or name:find("lethal")
            or name:find("rocksmash") or name:find("aura") or name:find("beam")
            or name:find("pillar") or name:find("rampage")
    end

    -- | transparent visual applier | --
    local function hide_visual(v)
        pcall(function()
            if v:IsA("Trail") then
                v.Enabled = false
                v.Transparency = NumberSequence.new(1)
            elseif v:IsA("ParticleEmitter") then
                v.Enabled = false
                v.Rate = 0
                v.Transparency = NumberSequence.new(1)
                v:Clear()
            elseif v:IsA("Beam") then
                v.Enabled = false
                v.Transparency = NumberSequence.new(1)
            elseif v:IsA("Highlight") then
                v.Enabled = false
                v.FillTransparency = 1
                v.OutlineTransparency = 1
            elseif v:IsA("BasePart") then
                v.Transparency = 1
                v.LocalTransparencyModifier = 1
                v.CastShadow = false
                v.CanCollide = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end)
    end

    -- | safe instance destroyer | --
    local function purge_element(item)
        task.defer(function()
            if item and item.Parent then
                if item:IsA("BasePart") then item.Transparency = 1 end
                pcall(function() item:Destroy() end)
            end
        end)
    end

    -- | world inspector | --
    local function inspect_object(obj)
        if not obj or not obj.Parent then return end

        if is_clone_or_afterimage(obj) then
            hide_visual(obj)
            purge_element(obj)
            return
        end

        if is_smoke_fx(obj) then
            hide_visual(obj)
            purge_element(obj)
            return
        end

        local name = obj.Name:lower()
        if is_garou_attack(name) then
            hide_visual(obj)
            for _, desc in ipairs(obj:GetDescendants()) do
                hide_visual(desc)
            end
            safe_connect(obj.DescendantAdded, hide_visual)
            return
        end

        if obj:IsA("Trail") or obj:IsA("ParticleEmitter") or obj:IsA("Beam") then
            local parent_model = obj:FindFirstAncestorOfClass("Model")
            if parent_model and (parent_model == local_player.Character or is_garou_attack(parent_model.Name:lower())) then
                hide_visual(obj)
            end
        end
    end

    -- | character effects removal | --
    local function hook_character(char)
        if not char then return end
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("Trail") or desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Highlight") then
                hide_visual(desc)
            end
        end
        safe_connect(char.DescendantAdded, function(desc)
            if desc:IsA("Trail") or desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Highlight") then
                hide_visual(desc)
            end
        end)
    end

    if local_player.Character then hook_character(local_player.Character) end
    safe_connect(local_player.CharacterAdded, hook_character)

    for _, desc in ipairs(workspace:GetDescendants()) do
        inspect_object(desc)
    end
    safe_connect(workspace.DescendantAdded, inspect_object)
end

-- | [5] direct debris removal | --
vm[5] = function()
    local function delete_debris(obj)
        if not obj or not obj.Parent then return end
        if obj:FindFirstChildOfClass("Humanoid") or (obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid")) then
            return
        end

        task.defer(function()
            if obj and obj.Parent then
                pcall(function() obj:Destroy() end)
            end
        end)
    end

    local function hook_thrown(folder)
        for _, child in ipairs(folder:GetChildren()) do
            delete_debris(child)
        end
        safe_connect(folder.ChildAdded, function(child)
            delete_debris(child)
        end)
    end

    local thrown = workspace:FindFirstChild("Thrown")
    if thrown then hook_thrown(thrown) end

    safe_connect(workspace.ChildAdded, function(child)
        if child.Name == "Thrown" then
            hook_thrown(child)
        end
    end)
end

-- | [6] camera shake, fps unlock & gui | --
vm[6] = function()
    -- | camera shake removal | --
    pcall(function()
        if getrawmetatable and setreadonly and newcclosure then
            local run = game:GetService("RunService")
            local meta = getrawmetatable(game)
            local old = meta.__index

            setreadonly(meta, false)

            meta.__index = newcclosure(function(obj, key)
                if key == "CamShakeCF" and obj == _G then
                    return CFrame.new()
                end

                if key == "CameraOffset" and obj:IsA("Humanoid") then
                    return Vector3.new(0, 0, 0)
                end

                return old(obj, key)
            end)

            setreadonly(meta, true)

            run.Heartbeat:Connect(function()
                rawset(_G, "CamShakeCF", CFrame.new())
            end)
        end
    end)

    -- | fps unlock | --
    local uncap = setfpscap or set_fps_cap
    if uncap then uncap(999) end

    -- | render | --
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    -- | Fps & ping ui | --
    local existing_gui = player_gui:FindFirstChild("fps_ping_counter")
    if existing_gui then existing_gui:Destroy() end

    local screen_gui = Instance.new("ScreenGui")
    screen_gui.Name = "fps_ping_counter"
    screen_gui.ResetOnSpawn = false
    screen_gui.Parent = player_gui

    local main_frame = Instance.new("Frame")
    main_frame.Size = UDim2.new(0, 130, 0, 30)
    main_frame.Position = UDim2.new(0.8, 0, 0, 50)
    main_frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    main_frame.BackgroundTransparency = 0.7
    main_frame.BorderSizePixel = 1
    main_frame.BorderColor3 = Color3.fromRGB(50, 50, 50)
    main_frame.Parent = screen_gui
    main_frame.Active = true
    main_frame.ClipsDescendants = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = main_frame

    local fps_label = Instance.new("TextLabel")
    fps_label.Size = UDim2.new(0.5, -5, 1, -10)
    fps_label.Position = UDim2.new(0, 5, 0, 5)
    fps_label.BackgroundTransparency = 1
    fps_label.Text = "Fps: 0"
    fps_label.TextColor3 = Color3.new(1, 1, 1)
    fps_label.Font = Enum.Font.Code
    fps_label.TextSize = 15
    fps_label.TextXAlignment = Enum.TextXAlignment.Left
    fps_label.Parent = main_frame

    local ping_label = Instance.new("TextLabel")
    ping_label.Size = UDim2.new(0.5, -5, 1, -10)
    ping_label.Position = UDim2.new(0.5, 5, 0, 5)
    ping_label.BackgroundTransparency = 1
    ping_label.Text = "Ping: 0"
    ping_label.TextColor3 = Color3.new(1, 1, 1)
    ping_label.Font = Enum.Font.Code
    ping_label.TextSize = 15
    ping_label.TextXAlignment = Enum.TextXAlignment.Right
    ping_label.Parent = main_frame

    local dragging = false
    local drag_input, mouse_pos, frame_pos

    local function update_drag(input)
        local delta = input.Position - mouse_pos
        main_frame.Position = UDim2.new(
            frame_pos.X.Scale,
            frame_pos.X.Offset + delta.X,
            frame_pos.Y.Scale,
            frame_pos.Y.Offset + delta.Y
        )
    end

    safe_connect(main_frame.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mouse_pos = input.Position
            frame_pos = main_frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    safe_connect(main_frame.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            drag_input = input
        end
    end)

    safe_connect(user_input_service.InputChanged, function(input)
        if input == drag_input and dragging then
            update_drag(input)
        end
    end)

    local displayed_fps = 60
    local displayed_ping = 0
    local last_time = tick()

    safe_connect(run_service.RenderStepped, function()
        local current_time = tick()
        local delta = current_time - last_time
        last_time = current_time

        local current_fps = 1 / math.max(delta, 0.0001)
        local current_ping = 0

        pcall(function()
            current_ping = (local_player:GetNetworkPing() or 0) * 1000
        end)

        displayed_fps = displayed_fps + (current_fps - displayed_fps) * 0.1
        displayed_ping = displayed_ping + (current_ping - displayed_ping) * 0.1

        fps_label.Text = string.format("fps: %d", math.floor(displayed_fps))
        ping_label.Text = string.format("ping: %d", math.floor(displayed_ping))

        if displayed_fps <= 25 then
            fps_label.TextColor3 = Color3.fromRGB(255, 0, 0)
        elseif displayed_fps <= 40 then
            fps_label.TextColor3 = Color3.fromRGB(255, 255, 0)
        else
            fps_label.TextColor3 = Color3.fromRGB(0, 255, 0)
        end

        if displayed_ping <= 150 then
            ping_label.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif displayed_ping <= 250 then
            ping_label.TextColor3 = Color3.fromRGB(255, 255, 0)
        else
            ping_label.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end)
end

-- | execution | --
local order = {1, 2, 3, 4, 5, 6}
while #order > 0 do
    local idx = math.random(#order)
    local task_id = order[idx]
    task.spawn(pcall, vm[task_id])
    table.remove(order, idx)
end