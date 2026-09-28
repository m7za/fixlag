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

    local function check_and_destroy(item)
        local name = item.Name:lower()
        if name:find("tree") or name == "3d" then
            item:Destroy()
        end
    end

    for _, child in ipairs(map:GetChildren()) do
        check_and_destroy(child)
    end
    map.ChildAdded:Connect(check_and_destroy)
end

-- | character effects, smoke & garou removal | --
local function setup_character_and_effects()
    local blue_color = Color3.fromRGB(0, 85, 190)

    local function is_smoke(name)
        return name:find("smoke") or name:find("dust") or name:find("dirt") 
            or name:find("puff") or name:find("cloud") or name:find("ground") 
            or name:find("dash") or name:find("step") or name:find("land")
    end

    local function is_garou_effect(name)
        return name:find("water") or name:find("flow") or name:find("stream") 
            or name:find("whirlwind") or name:find("hunter") or name:find("slash")
            or name:find("fang") or name:find("nado") or name:find("lethal")
            or name:find("rocksmash") or name:find("aura") or name:find("beam")
            or name:find("pillar") or name:find("rampage") or name:find("garou")
    end

    local function purge_visual(item)
        if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") 
            or item:IsA("Highlight") or item:IsA("Smoke") or item:IsA("Fire") 
            or item:IsA("Light") then
            pcall(function()
                item.Enabled = false
                if item:IsA("ParticleEmitter") then item:Clear() end
            end)
            item:Destroy()
        end
    end

    local function tweak_particle(item)
        local name = item.Name:lower()
        local parent_name = item.Parent and item.Parent.Name:lower() or ""

        if is_smoke(name) or is_smoke(parent_name) then
            purge_visual(item)
            return
        end

        if is_blue then
            if item:IsA("Trail") then
                item.Color = ColorSequence.new(blue_color)
                item.Texture = ""
                item.LightEmission = 0.8
            elseif item:IsA("ParticleEmitter") then
                item.Color = ColorSequence.new(blue_color)
                item.LightEmission = 1
            end
        else
            if is_garou_effect(name) or is_garou_effect(parent_name) then
                purge_visual(item)
            elseif item:IsA("Beam") or item:IsA("Trail") or item:IsA("Highlight") then
                purge_visual(item)
            elseif item:IsA("ParticleEmitter") then
                purge_visual(item)
            end
        end
    end

    local function hook_character(char)
        if not char then return end
        for _, desc in ipairs(char:GetDescendants()) do
            tweak_particle(desc)
        end
        char.DescendantAdded:Connect(tweak_particle)
    end

    local function monitor_model(model)
        if not model:IsA("Model") then return end
        if model:FindFirstChildOfClass("Humanoid") then
            hook_character(model)
        else
            local conn
            conn = model.ChildAdded:Connect(function(child)
                if child:IsA("Humanoid") then
                    hook_character(model)
                    conn:Disconnect()
                end
            end)
        end
    end

    local live = workspace:FindFirstChild("Live")
    if live then
        for _, child in ipairs(live:GetChildren()) do
            monitor_model(child)
        end
        live.ChildAdded:Connect(monitor_model)
    end

    for _, child in ipairs(workspace:GetChildren()) do
        monitor_model(child)
    end
    workspace.ChildAdded:Connect(monitor_model)

    if local_player.Character then hook_character(local_player.Character) end
    local_player.CharacterAdded:Connect(hook_character)

    local function handle_world_object(item)
        if not item or item == local_player.Character or item:IsDescendantOf(local_player.Character) then return end

        local name = item.Name:lower()
        local my_name = local_player.Name:lower()

        if is_smoke(name) then
            purge_visual(item)
            return
        end

        if not is_blue and is_garou_effect(name) then
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
            item:Destroy()
            return
        end

        local is_clone = (name == my_name)
            or name:find("clone")
            or name:find("afterimage")
            or name:find("ghost")
            or name:find("flowing")
            or (item:IsA("Model") and item:FindFirstChild("Head") and not players:GetPlayerFromCharacter(item) and not name:find("dummy"))

        if is_clone then
            if item:IsA("BasePart") then
                item.Transparency = 1
                item.CanCollide = false
            elseif item:IsA("Model") then
                for _, part in ipairs(item:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 1
                        part.CanCollide = false
                    elseif part:IsA("ParticleEmitter") then
                        part.Enabled = false
                    end
                end
            end
            item:Destroy()
        end
    end

    for _, child in ipairs(workspace:GetChildren()) do
        handle_world_object(child)
    end
    workspace.ChildAdded:Connect(function(child)
        task.defer(handle_world_object, child)
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

-- | debris & thrown cleaner | --
local function start_debris_cleaner()
    local whitelist = {
        ["ring"] = true,
        ["debris2g"] = true,
        ["projectile"] = true,
        ["middlespin"] = true,
        ["middlespinemit"] = true,
        ["flash"] = true,
        ["slash_teleport"] = true,
        ["shurikenproj"] = true,
        ["tparticles2"] = true,
        ["proj"] = true,
        ["adjusted"] = true,
        ["general"] = true,
        ["up"] = true,
        ["up2"] = true,
        ["go2"] = true,
        ["dotted"] = true,
        ["dragon"] = true,
        ["kingcrab"] = true,
        ["model"] = true,
        ["preload"] = true
    }

    if is_blue then
        whitelist["tornadomain"] = true
        whitelist["spiral"] = true
        whitelist["nadosmoke"] = true
        whitelist["smokering"] = true
        whitelist["clone_rig"] = true
        whitelist["afterimage_clone"] = true
    end

    local function is_smoke(name)
        return name:find("smoke") or name:find("dust") or name:find("dirt") 
            or name:find("puff") or name:find("cloud") or name:find("ground") 
            or name:find("dash") or name:find("step") or name:find("land")
    end

    local function is_garou_name(name)
        return name:find("water") or name:find("flow") or name:find("stream") 
            or name:find("whirlwind") or name:find("hunter") or name:find("slash")
            or name:find("fang") or name:find("nadosmoke") or name:find("smokering")
            or name:find("tornadomain") or name:find("spiral")
    end

    local function is_whitelisted(obj)
        if not obj then return true end
        local name = obj.Name:lower()

        if is_smoke(name) then return false end
        if not is_blue and is_garou_name(name) then return false end
        if whitelist[name] then return true end
        if obj:FindFirstChildOfClass("Humanoid") then return true end
        if obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid") then return true end

        if obj:IsA("BasePart") and obj.Name == "Part" and obj.Size == Vector3.new(4, 4, 4) then
            return true
        end

        return false
    end

    local function delete_debris(obj)
        if not obj or not obj.Parent or is_whitelisted(obj) then return end

        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CanCollide = false
        elseif obj:IsA("Model") then
            for _, part in ipairs(obj:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                    part.CanCollide = false
                end
            end
        end
        obj:Destroy()
    end

    local function clean_model_contents(model)
        for _, child in ipairs(model:GetChildren()) do
            if not is_whitelisted(child) then
                delete_debris(child)
            elseif child:IsA("Model") then
                clean_model_contents(child)
            end
        end
    end

    local function handle_thrown_child(child)
        if not child or not child.Parent then return end
        if is_whitelisted(child) then
            if child:IsA("Model") then
                clean_model_contents(child)
            end
            return
        end
        delete_debris(child)
    end

    local function is_debris_name(name)
        return name:find("debris") or name:find("starterdeb") or name:find("vfxdebris")
    end

    local function monitor_folder(folder)
        for _, child in ipairs(folder:GetChildren()) do
            handle_thrown_child(child)
        end
        folder.ChildAdded:Connect(function(child)
            task.defer(handle_thrown_child, child)
        end)
    end

    local thrown = workspace:WaitForChild("Thrown", 3) or workspace:FindFirstChild("Thrown")
    if thrown then monitor_folder(thrown) end

    local function inspect_element(child)
        task.defer(function()
            if not child or not child.Parent then return end
            local name = child.Name:lower()

            if name == "thrown" then
                monitor_folder(child)
            elseif name:find("vfxdebris") then
                child:ClearAllChildren()
                child.ChildAdded:Connect(function(v)
                    task.defer(delete_debris, v)
                end)
            elseif is_debris_name(name) or is_smoke(name) or (not is_blue and is_garou_name(name)) then
                delete_debris(child)
            end
        end)
    end

    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name:lower() ~= "thrown" then
            inspect_element(child)
        end
    end

    workspace.ChildAdded:Connect(inspect_element)
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
    remove_camera_shake,
    start_debris_cleaner,
    unlock_fps
}

for _, run_module in ipairs(modules) do
    task.spawn(pcall, run_module)
end

-- | engine settings | --
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 
end)