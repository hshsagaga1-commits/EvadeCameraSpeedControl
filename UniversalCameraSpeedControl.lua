-- Universal Camera Speed Control (Roblox)
-- Best-effort support for games using Roblox's standard PlayerModule camera.
-- Custom camera controllers may bypass these hooks.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
local STATE_KEY = "__UniversalCameraSpeedControl"

-- Clean up a previous run without stacking hooks.
local previous = env[STATE_KEY]
if previous then
    pcall(function()
        if previous.cameraInput and previous.cameraInput.getRotation == previous.rotationWrapper then
            previous.cameraInput.getRotation = previous.originalGetRotation
        end
    end)
    pcall(function()
        if previous.baseCamera
            and previous.baseCamera.InputTranslationToCameraAngleChange == previous.legacyWrapper then
            previous.baseCamera.InputTranslationToCameraAngleChange = previous.originalInputTranslation
        end
    end)
    pcall(function()
        if previous.gui then previous.gui:Destroy() end
    end)
    previous.running = false
end

local state = {
    multiplier = 1,
    precisionEnabled = true,
    running = true,
    cameraInput = nil,
    originalGetRotation = nil,
    rotationWrapper = nil,
    baseCamera = nil,
    originalInputTranslation = nil,
    legacyWrapper = nil,
    gui = nil
}
env[STATE_KEY] = state

local STRAIGHTEN_MIN_GAIN = 0.72
local STRAIGHTEN_FULL_RATIO = 0.30

local function smoothstep(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function transformRotation(rotation)
    if typeof(rotation) == "Vector2" and state.precisionEnabled and UserInputService.TouchEnabled then
        local ax, ay = math.abs(rotation.X), math.abs(rotation.Y)
        local major, minor = math.max(ax, ay), math.min(ax, ay)
        if major > 0 and minor > 0 then
            local ratio = minor / major
            local alpha = smoothstep(ratio / STRAIGHTEN_FULL_RATIO)
            local minorGain = STRAIGHTEN_MIN_GAIN + (1 - STRAIGHTEN_MIN_GAIN) * alpha
            if ax >= ay then
                rotation = Vector2.new(rotation.X, rotation.Y * minorGain)
            else
                rotation = Vector2.new(rotation.X * minorGain, rotation.Y)
            end
        end
    end

    if typeof(rotation) == "Vector2" then
        return rotation * state.multiplier
    end
    return rotation
end

local function getPlayerModule()
    local scripts = player:FindFirstChildOfClass("PlayerScripts")
    if not scripts then return nil end
    local module = scripts:FindFirstChild("PlayerModule")
    if not module then return nil end
    return module
end

local function findModule(parent, name)
    if not parent then return nil end
    local direct = parent:FindFirstChild(name)
    if direct and direct:IsA("ModuleScript") then return direct end
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == name then
            return obj
        end
    end
    return nil
end

local function restoreLegacy()
    if state.baseCamera and state.originalInputTranslation
        and state.baseCamera.InputTranslationToCameraAngleChange == state.legacyWrapper then
        pcall(function()
            state.baseCamera.InputTranslationToCameraAngleChange = state.originalInputTranslation
        end)
    end
    state.baseCamera, state.originalInputTranslation, state.legacyWrapper = nil, nil, nil
end

local function attachCameraInput()
    local playerModule = getPlayerModule()
    local cameraModule = playerModule and playerModule:FindFirstChild("CameraModule")
    local module = findModule(cameraModule or playerModule, "CameraInput")
    if not module then return false end

    local ok, cameraInput = pcall(require, module)
    if not ok or type(cameraInput) ~= "table" or type(cameraInput.getRotation) ~= "function" then
        return false
    end

    if state.cameraInput == cameraInput and cameraInput.getRotation == state.rotationWrapper then
        restoreLegacy()
        return true
    end

    if state.cameraInput and state.originalGetRotation
        and state.cameraInput.getRotation == state.rotationWrapper then
        pcall(function()
            state.cameraInput.getRotation = state.originalGetRotation
        end)
    end

    local original = cameraInput.getRotation
    local wrapper = function(...)
        return transformRotation(original(...))
    end

    state.cameraInput = cameraInput
    state.originalGetRotation = original
    state.rotationWrapper = wrapper

    local changed = pcall(function() cameraInput.getRotation = wrapper end)
    if not changed then return false end
    restoreLegacy()
    return true
end

local function attachLegacyCamera()
    local playerModule = getPlayerModule()
    local cameraModule = playerModule and playerModule:FindFirstChild("CameraModule")
    local module = findModule(cameraModule or playerModule, "BaseCamera")
    if not module then return false end

    local ok, baseCamera = pcall(require, module)
    if not ok or type(baseCamera) ~= "table"
        or type(baseCamera.InputTranslationToCameraAngleChange) ~= "function" then
        return false
    end

    if state.baseCamera == baseCamera
        and baseCamera.InputTranslationToCameraAngleChange == state.legacyWrapper then
        return true
    end

    restoreLegacy()
    local original = baseCamera.InputTranslationToCameraAngleChange
    local wrapper = function(self, translationVector, sensitivity)
        return transformRotation(original(self, translationVector, sensitivity))
    end

    state.baseCamera = baseCamera
    state.originalInputTranslation = original
    state.legacyWrapper = wrapper
    local changed = pcall(function() baseCamera.InputTranslationToCameraAngleChange = wrapper end)
    return changed
end

-- Build a compact draggable UI.
local parent
pcall(function() if gethui then parent = gethui() end end)
if not parent then parent = CoreGui end

local gui = Instance.new("ScreenGui")
gui.Name = "UniversalCameraSpeedControl"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent
state.gui = gui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(250, 144)
frame.Position = UDim2.new(0.5, -125, 0.16, 0)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Transparency = 0.55
stroke.Color = Color3.fromRGB(130, 130, 140)
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 30)
title.Position = UDim2.fromOffset(12, 7)
title.BackgroundTransparency = 1
title.Text = "Universal Camera Speed"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextSize = 14
title.Font = Enum.Font.GothamSemibold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.fromOffset(54, 28)
valueLabel.Position = UDim2.new(1, -66, 0, 8)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "1.0x"
valueLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
valueLabel.TextSize = 14
valueLabel.Font = Enum.Font.GothamMedium
valueLabel.TextXAlignment = Enum.TextXAlignment.Right
valueLabel.Parent = frame

local bar = Instance.new("Frame")
bar.Name = "Slider"
bar.Size = UDim2.new(1, -28, 0, 8)
bar.Position = UDim2.fromOffset(14, 58)
bar.BackgroundColor3 = Color3.fromRGB(70, 70, 76)
bar.BorderSizePixel = 0
bar.Active = true
bar.Parent = frame

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = bar

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
fill.BorderSizePixel = 0
fill.Parent = bar

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(20, 20)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.fromScale(0, 0.5)
knob.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
knob.BorderSizePixel = 0
knob.Active = true
knob.Parent = bar

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = knob

local minLabel = Instance.new("TextLabel")
minLabel.Size = UDim2.fromOffset(42, 20)
minLabel.Position = UDim2.fromOffset(14, 75)
minLabel.BackgroundTransparency = 1
minLabel.Text = "0.1x"
minLabel.TextColor3 = Color3.fromRGB(150, 150, 158)
minLabel.TextSize = 11
minLabel.Font = Enum.Font.Gotham
minLabel.TextXAlignment = Enum.TextXAlignment.Left
minLabel.Parent = frame

local maxLabel = Instance.new("TextLabel")
maxLabel.Size = UDim2.fromOffset(48, 20)
maxLabel.Position = UDim2.new(1, -62, 0, 75)
maxLabel.BackgroundTransparency = 1
maxLabel.Text = "2.0x"
maxLabel.TextColor3 = Color3.fromRGB(150, 150, 158)
maxLabel.TextSize = 11
maxLabel.Font = Enum.Font.Gotham
maxLabel.TextXAlignment = Enum.TextXAlignment.Right
maxLabel.Parent = frame

local precisionButton = Instance.new("TextButton")
precisionButton.Name = "PrecisionToggle"
precisionButton.Size = UDim2.new(1, -28, 0, 28)
precisionButton.Position = UDim2.fromOffset(14, 104)
precisionButton.BackgroundColor3 = Color3.fromRGB(42, 42, 47)
precisionButton.BorderSizePixel = 0
precisionButton.TextColor3 = Color3.fromRGB(235, 235, 240)
precisionButton.TextSize = 13
precisionButton.Font = Enum.Font.GothamMedium
precisionButton.Parent = frame

local precisionCorner = Instance.new("UICorner")
precisionCorner.CornerRadius = UDim.new(0, 8)
precisionCorner.Parent = precisionButton

local function refreshPrecisionLabel()
    precisionButton.Text = state.precisionEnabled and "Precisão: ON" or "Precisão: OFF"
end
precisionButton.Activated:Connect(function()
    state.precisionEnabled = not state.precisionEnabled
    refreshPrecisionLabel()
end)
refreshPrecisionLabel()

local MIN, MAX, STEP = 0.1, 2, 0.1
local function setValue(value)
    value = math.clamp(value, MIN, MAX)
    value = math.floor(value / STEP + 0.5) * STEP
    value = math.floor(value * 10 + 0.5) / 10
    state.multiplier = value
    local alpha = (value - MIN) / (MAX - MIN)
    fill.Size = UDim2.fromScale(alpha, 1)
    knob.Position = UDim2.fromScale(alpha, 0.5)
    valueLabel.Text = string.format("%.1fx", value)
end
setValue(1)

local sliding = false
local function updateFromX(x)
    local width = bar.AbsoluteSize.X
    if width <= 0 then return end
    local alpha = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
    setValue(MIN + (MAX - MIN) * alpha)
end
local function beginSlide(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = true
        updateFromX(input.Position.X)
    end
end
bar.InputBegan:Connect(beginSlide)
knob.InputBegan:Connect(beginSlide)
UserInputService.InputChanged:Connect(function(input)
    if sliding and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
        updateFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = false
    end
end)

local dragging, dragStart, startPosition = false, nil, nil
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if input.Position.Y <= bar.AbsolutePosition.Y - 8 then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and dragStart and startPosition
        and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

task.spawn(function()
    while state.running do
        local attached = false
        pcall(function() attached = attachCameraInput() end)
        if not attached then
            pcall(attachLegacyCamera)
        end
        task.wait(1)
    end
end)

if not attachCameraInput() then
    attachLegacyCamera()
end
