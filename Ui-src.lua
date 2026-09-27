local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
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
    fps += (curFPS - fps) * 0.1

    pcall(function() 
        ping = LocalPlayer:GetNetworkPing() * 1000 
    end)

    label.Text = string.format("FPS: %d | PING: %d ms", math.floor(fps), math.floor(ping))
    label.TextColor3 = Color3.fromHSV((now * 0.4) % 1, 0.8, 1)
end)