-- | Made By m7za | --

-- config
local garou_mode = (getgenv and getgenv().garou_effects) or _G.garou_effects or garou_effects or "transparent"
local is_blue = tostring(garou_mode):lower() == "blue"

-- cleanup
if getgenv()._FixLagConnections then
    for _, conn in ipairs(getgenv()._FixLagConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv()._FixLagConnections = {}
local function track_conn(conn)
    table.insert(getgenv()._FixLagConnections, conn)
    return conn
end

-- services
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local run_service = game:GetService("RunService")

local local_player = players.LocalPlayer
local terrain = workspace.Terrain
local player_gui = local_player:WaitForChild("PlayerGui")

-- char check
local function is_real_character(model)
    if not model or not model:IsA("Model") then return false end
    if model == local_player.Character then return true end
    if players:GetPlayerFromCharacter(model) then return true end

    local name = model.Name:lower()
    if name:find("dummy") then return true end

    return false
end

local function is_character_part(item)
    if not item then return false end
    local char = local_player.Character
    if char and (item == char or item:IsDescendantOf(char)) then
        return true
    end

    local model = item:IsA("Model") and item or item:FindFirstAncestorOfClass("Model")
    if model and is_real_character(model) then
        return true
    end

    return false
end

-- clone check
local function is_clone_model(model)
    if not model or not model:IsA("Model") then return false end
    if is_real_character(model) then return false end

    local name = model.Name:lower()
    if name:find("clone") or name:find("afterimage") or name:find("flowing") or name:find("ghost") then
        return true
    end

    if model.Name == local_player.Name and local_player.Character and model ~= local_player.Character then
        return true
    end

    return false
end

-- sky & light
local function setup_lighting()
    local SkyIDs = {
        Bk = 92959017845968,
        Ft = 129304841254693,
        Lf = 129249062260004,
        Rt = 117319232583147,
        Up = 121193772599100,
        Dn = 115022734343595
    }

    local function kill_sun(sky)
        if sky then
            sky.SunAngularSize = 0
            sky.SunTextureId = ""
            sky.MoonAngularSize = 0
            sky.MoonTextureId = ""
        end
    end

    local function apply_sky()
        for _, v in ipairs(lighting:GetChildren()) do
            if v:IsA("Sky") and v.Name ~= "CustomSky" then
                v:Destroy()
            end
        end

        local existing = lighting:FindFirstChild("CustomSky")
        if not existing then
            local s = Instance.new("Sky")
            s.Name = "CustomSky"
            for k, id in pairs(SkyIDs) do
                s["Skybox" .. k] = "rbxassetid://" .. id
            end
            kill_sun(s)
            s.Parent = lighting
        else
            kill_sun(existing)
        end
    end

    local function clean_lighting()
        lighting.ClockTime = 12
        lighting.GlobalShadows = false
        lighting.Brightness = 0.8
        lighting.ExposureCompensation = -0.2
        lighting.FogStart, lighting.FogEnd = 9e9, 9e9

        for _, v in ipairs(lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("SunRaysEffect") then
                v.Enabled = false
            elseif v:IsA("Atmosphere") then
                v.Density = 0
                v.Haze = 0
                v.Glare = 0
            end
        end
    end

    apply_sky()
    clean_lighting()

    track_conn(lighting.ChildAdded:Connect(function(v)
        if v:IsA("Sky") and v.Name ~= "CustomSky" then
            task.wait()
            v:Destroy()
            apply_sky()
        elseif v:IsA("Atmosphere") then
            v.Density = 0
            v.Haze = 0
            v.Glare = 0
        end
    end))

    track_conn(local_player.CharacterAdded:Connect(function()
        task.wait(0.2)
        apply_sky()
        clean_lighting()
    end))
end

-- clouds
local function remove_clouds()
    if not terrain then return end
    for _, item in ipairs(terrain:GetChildren()) do
        if item:IsA("Clouds") then item.Enabled = false end
    end
    track_conn(terrain.ChildAdded:Connect(function(item)
        if item:IsA("Clouds") then item.Enabled = false end
    end))
end

-- trees
local function remove_trees()
    local function check_and_destroy(item)
        if not item or not item.Parent then return end
        local name = item.Name:lower()
        if name:find("tree") or name == "3d" then
            pcall(function()
                item:Destroy()
            end)
        end
    end

    local map = workspace:WaitForChild("Map", 5) or workspace:FindFirstChild("Map")
    if map then
        for _, child in ipairs(map:GetDescendants()) do
            check_and_destroy(child)
        end
        track_conn(map.DescendantAdded:Connect(check_and_destroy))
    end

    for _, child in ipairs(workspace:GetChildren()) do
        local name = child.Name:lower()
        if (name:find("tree") or name == "3d") and child.Name ~= "Map" and child.Name ~= "Terrain" then
            check_and_destroy(child)
        end
    end
end

-- vfx lock
local function setup_character_and_effects()
    local blue_color = Color3.fromRGB(0, 85, 190)
    local invisible = NumberSequence.new(1)
    local zero_size = NumberSequence.new(0)

    local function is_smoke_name(name)
        return name:find("smoke") or name:find("dust") or name:find("dirt") 
            or name:find("puff") or name:find("cloud") or name:find("ground") 
            or name:find("dash") or name:find("step") or name:find("land")
            or name:find("foot") or name:find("slide") or name:find("crater")
            or name:find("impact")
    end

    local function is_garou_visual_name(name)
        return name:find("water") or name:find("flow") or name:find("stream") 
            or name:find("whirlwind") or name:find("hunter") or name:find("slash")
            or name:find("fang") or name:find("nado") or name:find("lethal")
            or name:find("rocksmash") or name:find("aura") or name:find("real") 
            or name:find("beam") or name:find("pillar") or name:find("rampage") 
            or name:find("garou") or name:find("airtrail") or name:find("line") 
            or name:find("shot") or name:find("palm") or name:find("constantemit")
            or name:find("middlespin") or name:find("spiral") or name:find("tornado")
            or name:find("ring") or name:find("wind")
    end

    local function is_debris_name(name)
        return name:find("debris") or name:find("starterdeb") or name:find("vfxdebris") 
            or name:find("rock") or name:find("stone") or name:find("chunk") 
            or name:find("fragment") or name:find("pebble") or name:find("rubble") 
            or name:find("broken") or name:find("crack")
    end

    local function lock_part_invisible(part)
        if not part:IsA("BasePart") or is_character_part(part) then return end
        pcall(function()
            part.Transparency = 1
            part.CanCollide = false
            part.CastShadow = false
        end)

        for _, sub in ipairs(part:GetChildren()) do
            if sub:IsA("Decal") or sub:IsA("Texture") then
                sub.Transparency = 1
            end
        end

        track_conn(part.ChildAdded:Connect(function(sub)
            if sub:IsA("Decal") or sub:IsA("Texture") then
                sub.Transparency = 1
            end
        end))

        track_conn(part:GetPropertyChangedSignal("Transparency"):Connect(function()
            if not is_character_part(part) and part.Transparency < 1 then
                part.Transparency = 1
            end
        end))
    end

    local function mute_particle(item)
        if not item:IsA("ParticleEmitter") then return end
        local function silence()
            pcall(function()
                item.Enabled = false
                item.Rate = 0
                item.Size = zero_size
                item.Transparency = invisible
                item.Texture = ""
                item:Clear()
            end)
        end
        silence()
        track_conn(item:GetPropertyChangedSignal("Enabled"):Connect(function()
            if item.Enabled then silence() end
        end))
        track_conn(item:GetPropertyChangedSignal("Texture"):Connect(function()
            if item.Texture ~= "" then silence() end
        end))
    end

    local function mute_trail(item)
        if not item:IsA("Trail") then return end
        local function silence()
            pcall(function()
                item.Enabled = false
                item.Transparency = invisible
                item.Texture = ""
            end)
        end
        silence()
        track_conn(item:GetPropertyChangedSignal("Enabled"):Connect(function()
            if item.Enabled then silence() end
        end))
    end

    local function mute_beam(item)
        if not item:IsA("Beam") then return end
        local function silence()
            pcall(function()
                item.Enabled = false
                item.Transparency = invisible
                item.Texture = ""
            end)
        end
        silence()
        track_conn(item:GetPropertyChangedSignal("Enabled"):Connect(function()
            if item.Enabled then silence() end
        end))
    end

    local function hide_entire_clone(model)
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                lock_part_invisible(part)
                part.CanCollide = false
            elseif part:IsA("ParticleEmitter") then
                mute_particle(part)
            elseif part:IsA("Trail") then
                mute_trail(part)
            elseif part:IsA("Beam") then
                mute_beam(part)
            elseif part:IsA("Highlight") then
                pcall(function() part.Enabled = false end)
            end
        end

        track_conn(model.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                lock_part_invisible(part)
                part.CanCollide = false
            elseif part:IsA("ParticleEmitter") then
                mute_particle(part)
            elseif part:IsA("Trail") then
                mute_trail(part)
            elseif part:IsA("Beam") then
                mute_beam(part)
            elseif part:IsA("Highlight") then
                pcall(function() part.Enabled = false end)
            end
        end))
    end

    local function handle_descendant(item)
        if not item then return end

        local name = item.Name:lower()
        local parent = item.Parent
        local parent_name = parent and parent.Name:lower() or ""

        if is_clone_model(item) then
            hide_entire_clone(item)
            return
        end

        if item:IsA("ParticleEmitter") then
            if not is_blue then
                mute_particle(item)
            else
                if is_smoke_name(name) or is_smoke_name(parent_name) then
                    mute_particle(item)
                else
                    item.Color = ColorSequence.new(blue_color)
                    item.LightEmission = 1
                end
            end
            return
        end

        if item:IsA("Smoke") or item:IsA("Fire") then
            pcall(function() item.Enabled = false end)
            return
        end

        if item:IsA("Trail") then
            if not is_blue or is_garou_visual_name(name) or is_garou_visual_name(parent_name) then
                mute_trail(item)
            else
                item.Color = ColorSequence.new(blue_color)
                item.Texture = ""
                item.LightEmission = 0.8
            end
            return
        end

        if item:IsA("Beam") then
            if not is_blue or is_garou_visual_name(name) or is_garou_visual_name(parent_name) then
                mute_beam(item)
            end
            return
        end

        if item:IsA("Highlight") then
            if not is_blue or is_garou_visual_name(name) or is_garou_visual_name(parent_name) then
                pcall(function()
                    item.Enabled = false
                    item.FillTransparency = 1
                    item.OutlineTransparency = 1
                end)
            end
            return
        end

        if is_character_part(item) then
            return
        end

        if item:IsA("BasePart") then
            if is_debris_name(name) or is_smoke_name(name) then
                lock_part_invisible(item)
                return
            end

            if not is_blue and is_garou_visual_name(name) then
                lock_part_invisible(item)
                return
            end
        elseif item:IsA("Model") then
            if is_debris_name(name) or is_smoke_name(name) then
                for _, part in ipairs(item:GetDescendants()) do
                    if part:IsA("BasePart") then
                        lock_part_invisible(part)
                    end
                end
                track_conn(item.DescendantAdded:Connect(function(part)
                    if part:IsA("BasePart") then
                        lock_part_invisible(part)
                    end
                end))
                return
            end
        end
    end

    for _, desc in ipairs(workspace:GetDescendants()) do
        task.spawn(handle_descendant, desc)
    end
    track_conn(workspace.DescendantAdded:Connect(function(desc)
        task.defer(handle_descendant, desc)
    end))
end

-- fps & ping
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

    track_conn(run_service.RenderStepped:Connect(function()
        local now = os.clock()
        local frame_fps = 1 / math.max(now - last_tick, 0.0001)
        last_tick = now
        current_fps = current_fps + (frame_fps - current_fps) * 0.1

        local ping = (local_player:GetNetworkPing() or 0) * 1000
        label.Text = string.format("FPS: %d | PING: %d ms", math.floor(current_fps), math.floor(ping))
        label.TextColor3 = Color3.fromHSV((now * 0.4) % 1, 0.8, 1)
    end))
end

-- cam shake
local function remove_camera_shake()
    if not (getrawmetatable and setreadonly) then return end
    local meta = getrawmetatable(game)
    local old_index = meta.__index
    setreadonly(meta, false)
    meta.__index = newcclosure(function(obj, key)
        if key == "CamShakeCF" and obj == _G then return CFrame.new() end
        if key == "CameraOffset" and typeof(obj) == "Instance" and obj:IsA("Humanoid") then return Vector3.zero end
        return old_index(obj, key)
    end)
    setreadonly(meta, true)
end

-- debris
local function start_debris_cleaner()
    local critical_hitboxes = {
        ["projectile"] = true,
        ["flash"] = true,
        ["slash_teleport"] = true,
        ["shurikenproj"] = true,
        ["proj"] = true,
        ["dragon"] = true,
        ["kingcrab"] = true
    }

    local function is_critical(obj)
        if not obj then return true end
        if is_character_part(obj) then return true end

        local name = obj.Name:lower()
        if critical_hitboxes[name] then return true end

        if obj:IsA("BasePart") and obj.Name == "Part" and obj.Size == Vector3.new(4, 4, 4) then
            return true
        end

        return false
    end

    local function lock_part_invisible(part)
        if not part:IsA("BasePart") or is_character_part(part) then return end
        pcall(function()
            part.Transparency = 1
            part.CanCollide = false
            part.CastShadow = false
        end)

        for _, sub in ipairs(part:GetChildren()) do
            if sub:IsA("Decal") or sub:IsA("Texture") then
                sub.Transparency = 1
            end
        end

        track_conn(part.ChildAdded:Connect(function(sub)
            if sub:IsA("Decal") or sub:IsA("Texture") then
                sub.Transparency = 1
            end
        end))

        track_conn(part:GetPropertyChangedSignal("Transparency"):Connect(function()
            if not is_character_part(part) and part.Transparency < 1 then
                part.Transparency = 1
            end
        end))
    end

    local function mute_particle(item)
        if not item:IsA("ParticleEmitter") then return end
        local function silence()
            pcall(function()
                item.Enabled = false
                item.Rate = 0
                item.Size = NumberSequence.new(0)
                item.Transparency = NumberSequence.new(1)
                item.Texture = ""
                item:Clear()
            end)
        end
        silence()
        track_conn(item:GetPropertyChangedSignal("Enabled"):Connect(function()
            if item.Enabled then silence() end
        end))
        track_conn(item:GetPropertyChangedSignal("Texture"):Connect(function()
            if item.Texture ~= "" then silence() end
        end))
    end

    local function handle_thrown_element(child)
        if not child or not child.Parent or is_character_part(child) then return end

        if is_critical(child) then
            return
        end

        if child:IsA("BasePart") then
            lock_part_invisible(child)
        elseif child:IsA("ParticleEmitter") then
            mute_particle(child)
        elseif child:IsA("Model") then
            for _, part in ipairs(child:GetDescendants()) do
                if part:IsA("BasePart") then
                    lock_part_invisible(part)
                elseif part:IsA("ParticleEmitter") then
                    mute_particle(part)
                end
            end
        end
    end

    local function monitor_folder(folder)
        for _, desc in ipairs(folder:GetDescendants()) do
            handle_thrown_element(desc)
        end
        track_conn(folder.DescendantAdded:Connect(function(desc)
            task.defer(handle_thrown_element, desc)
        end))
    end

    local thrown = workspace:WaitForChild("Thrown", 3) or workspace:FindFirstChild("Thrown")
    if thrown then monitor_folder(thrown) end

    local function inspect_element(child)
        task.defer(function()
            if not child or not child.Parent or is_character_part(child) then return end
            local name = child.Name:lower()

            if name == "thrown" then
                monitor_folder(child)
            elseif name:find("vfxdebris") then
                monitor_folder(child)
            end
        end)
    end

    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name:lower() ~= "thrown" then
            inspect_element(child)
        end
    end

    track_conn(workspace.ChildAdded:Connect(inspect_element))
end

-- fps uncap
local function unlock_fps()
    local uncap = setfpscap or set_fps_cap
    if uncap then uncap(999) end
end

-- exec
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

-- settings
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 
end)
