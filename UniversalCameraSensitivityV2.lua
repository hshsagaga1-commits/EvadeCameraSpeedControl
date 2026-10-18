-- Universal Camera Sensitivity v2
-- Best effort for games using Roblox's standard PlayerModule camera.
-- Some games use custom camera controllers and cannot be changed by this hook.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
local KEY = "__UniversalCameraSensitivityV2"

local old = env[KEY]
if old then
    old.running = false
    pcall(function()
        if old.target and old.target.getRotation == old.wrapper then
            old.target.getRotation = old.original
        end
    end)
    pcall(function() if old.gui then old.gui:Destroy() end end)
end

local state = {
    running = true, multiplier = 1, target = nil, original = nil,
    wrapper = nil, gui = nil, status = "Procurando câmera..."
}
env[KEY] = state

local function getPlayerModule()
    local ps = player:FindFirstChildOfClass("PlayerScripts")
    return ps and ps:FindFirstChild("PlayerModule")
end

local function isCameraInputTable(t)
    if type(t) ~= "table" or type(t.getRotation) ~= "function" then return false end
    local info
    pcall(function() info = debug.getinfo(t.getRotation) end)
    if info then
        local source = tostring(info.source or "")
        local name = tostring(info.name or "")
        if source:lower():find("camera") or name:lower():find("rotation") then
            return true
        end
    end
    return false
end

local function findCameraInput()
    local pm = getPlayerModule()
    if pm then
        local cm = pm:FindFirstChild("CameraModule")
        local function search(root)
            if not root then return nil end
            local objects = {root}
            for _, obj in ipairs(root:GetDescendants()) do
                objects[#objects + 1] = obj
            end
            for _, obj in ipairs(objects) do
                if obj:IsA("ModuleScript") and obj.Name == "CameraInput" then
                    local ok, result = pcall(require, obj)
                    if ok and isCameraInputTable(result) then
                        return result
                    end
                end
            end
            return nil
        end
        local found = search(cm) or search(pm)
        if found then return found end
    end

    -- Fallback for executors where the standard module is already loaded
    -- but its ModuleScript is not exposed in PlayerScripts descendants.
    if type(getgc) == "function" then
        local ok, objects = pcall(getgc, true)
        if ok and type(objects) == "table" then
            for _, obj in ipairs(objects) do
                if isCameraInputTable(obj) then
                    local info
                    pcall(function() info = debug.getinfo(obj.getRotation) end)
                    local source = info and tostring(info.source or ""):lower() or ""
                    if source:find("camera") then return obj end
                end
            end
        end
    end
    return nil
end

local function attach()
    local target = findCameraInput()
    if not target then
        state.status = "Câmera padrão não encontrada"
        return false
    end
    if state.target == target and target.getRotation == state.wrapper then
        state.status = "Conectado à câmera padrão"
        return true
    end

    if state.target and state.original and state.target.getRotation == state.wrapper then
        pcall(function() state.target.getRotation = state.original end)
    end

    local original = target.getRotation
    local wrapper = function(...)
        local result = original(...)
        if typeof(result) == "Vector2" then
            return result * state.multiplier
        end
        return result
    end

    local ok = pcall(function() target.getRotation = wrapper end)
    if not ok or target.getRotation ~= wrapper then
        state.status = "Encontrada, mas não foi possível conectar"
        return false
    end

    state.target, state.original, state.wrapper = target, original, wrapper
    state.status = "Conectado à câmera padrão"
    return true
end

local parent
pcall(function() if gethui then parent = gethui() end end)
if not parent then parent = CoreGui end

local gui = Instance.new("ScreenGui")
gui.Name = "UniversalCameraSensitivityV2"
gui.ResetOnSpawn = false
gui.Parent = parent
state.gui = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(270, 142)
frame.Position = UDim2.new(0.5, -135, 0.16, 0)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 25)
title.Position = UDim2.fromOffset(10, 7)
title.BackgroundTransparency = 1
title.Text = "Camera Sensitivity v2"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Font = Enum.Font.GothamSemibold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.fromOffset(55, 25)
valueLabel.Position = UDim2.new(1, -65, 0, 7)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "1.0x"
valueLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextSize = 13
valueLabel.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 18)
statusLabel.Position = UDim2.fromOffset(10, 32)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = state.status
statusLabel.TextColor3 = Color3.fromRGB(255, 205, 105)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, -28, 0, 8)
bar.Position = UDim2.fromOffset(14, 65)
bar.BackgroundColor3 = Color3.fromRGB(75, 75, 82)
bar.BorderSizePixel = 0
bar.Active = true
bar.Parent = frame
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0.473684, 1)
fill.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
fill.BorderSizePixel = 0
fill.Parent = bar
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(18, 18)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.fromScale(0.473684, 0.5)
knob.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
knob.BorderSizePixel = 0
knob.Active = true
knob.Parent = bar
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local minLabel = Instance.new("TextLabel")
minLabel.Size = UDim2.fromOffset(40, 18)
minLabel.Position = UDim2.fromOffset(14, 78)
minLabel.BackgroundTransparency = 1
minLabel.Text = "0.1x"
minLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
minLabel.Font = Enum.Font.Gotham
minLabel.TextSize = 10
minLabel.Parent = frame

local maxLabel = Instance.new("TextLabel")
maxLabel.Size = UDim2.fromOffset(45, 18)
maxLabel.Position = UDim2.new(1, -59, 0, 78)
maxLabel.BackgroundTransparency = 1
maxLabel.Text = "2.0x"
maxLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
maxLabel.Font = Enum.Font.Gotham
maxLabel.TextSize = 10
maxLabel.TextXAlignment = Enum.TextXAlignment.Right
maxLabel.Parent = frame

local function setValue(value)
    value = math.clamp(math.floor(value * 10 + 0.5) / 10, 0.1, 2)
    state.multiplier = value
    local alpha = (value - 0.1) / 1.9
    fill.Size = UDim2.fromScale(alpha, 1)
    knob.Position = UDim2.fromScale(alpha, 0.5)
    valueLabel.Text = string.format("%.1fx", value)
end

local sliding = false
local function updateSlider(x)
    if bar.AbsoluteSize.X <= 0 then return end
    local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
    setValue(0.1 + 1.9 * a)
end
local function startSlide(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = true
        updateSlider(input.Position.X)
    end
end
bar.InputBegan:Connect(startSlide)
knob.InputBegan:Connect(startSlide)
UserInputService.InputChanged:Connect(function(input)
    if sliding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        updateSlider(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = false
    end
end)

-- Drag from the title area only, so dragging won't steal slider touches.
local dragging, dragStart, startPos = false, nil, nil
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos = true, input.Position, frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and dragStart and startPos and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

task.spawn(function()
    while state.running do
        pcall(attach)
        statusLabel.Text = state.status
        statusLabel.TextColor3 = state.status == "Conectado à câmera padrão" and Color3.fromRGB(120, 235, 155) or Color3.fromRGB(255, 205, 105)
        task.wait(1)
    end
end)

pcall(attach)
statusLabel.Text = state.status
