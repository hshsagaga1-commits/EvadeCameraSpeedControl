local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local env = getgenv and getgenv() or _G

if env.__EvadeCameraSpeedControl then
    local oldState = env.__EvadeCameraSpeedControl

    pcall(function()
        if oldState.cameraInput
            and oldState.originalGetRotation
            and oldState.cameraInput.getRotation == oldState.wrapper
        then
            oldState.cameraInput.getRotation = oldState.originalGetRotation
        end
    end)

    pcall(function()
        if oldState.gui then
            oldState.gui:Destroy()
        end
    end)

    oldState.running = false

end

local state = {
    multiplier = 1,
    running = true,
    cameraInput = nil,
    originalGetRotation = nil,
    wrapper = nil,
    gui = nil
}

env.__EvadeCameraSpeedControl = state

local function findCameraInput()
    local playerScripts = player:FindFirstChild("PlayerScripts")

    if not playerScripts then
        return nil
    end

    local playerModule = playerScripts:FindFirstChild("PlayerModule")

    if playerModule then
        local cameraModule = playerModule:FindFirstChild("CameraModule")

        if cameraModule then
            local cameraInput = cameraModule:FindFirstChild("CameraInput")

            if cameraInput and cameraInput:IsA("ModuleScript") then
                return cameraInput
            end
        end
    end

    for _, object in ipairs(playerScripts:GetDescendants()) do
        if object:IsA("ModuleScript") and object.Name == "CameraInput" then
            return object
        end
    end

    return nil
end

local function attachCameraInput()
    local module = findCameraInput()

    if not module then
        return false
    end

    local ok, cameraInput = pcall(require, module)

    if not ok
        or type(cameraInput) ~= "table"
        or type(cameraInput.getRotation) ~= "function"
    then
        return false
    end

    if state.cameraInput == cameraInput
        and cameraInput.getRotation == state.wrapper
    then
        return true
    end

    if state.cameraInput
        and state.originalGetRotation
        and state.cameraInput.getRotation == state.wrapper
    then
        pcall(function()
            state.cameraInput.getRotation = state.originalGetRotation
        end)
    end

    local original = cameraInput.getRotation

    local function wrapper(...)
        return original(...) * state.multiplier
    end

    state.cameraInput = cameraInput
    state.originalGetRotation = original
    state.wrapper = wrapper
    cameraInput.getRotation = wrapper

    return true
end

local parent

pcall(function()
    if gethui then
        parent = gethui()
    end
end)

if not parent then
    parent = CoreGui
end

local gui = Instance.new("ScreenGui")
gui.Name = "EvadeCameraSpeedControl"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

state.gui = gui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(250, 104)
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
title.Text = "Camera Speed"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextSize = 16
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

local normalLabel = Instance.new("TextLabel")
normalLabel.Size = UDim2.fromOffset(48, 20)
normalLabel.Position = UDim2.new(1, -62, 0, 75)
normalLabel.BackgroundTransparency = 1
normalLabel.Text = "7.0x"
normalLabel.TextColor3 = Color3.fromRGB(150, 150, 158)
normalLabel.TextSize = 11
normalLabel.Font = Enum.Font.Gotham
normalLabel.TextXAlignment = Enum.TextXAlignment.Right
normalLabel.Parent = frame

local MIN = 0.1
local MAX = 7
local STEP = 0.1

local function setValue(value)
    value = math.clamp(value, MIN, MAX)
    value = math.floor((value / STEP) + 0.5) * STEP
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

    if width <= 0 then
        return
    end

    local alpha = math.clamp(
        (x - bar.AbsolutePosition.X) / width,
        0,
        1
    )

    setValue(MIN + (MAX - MIN) * alpha)
end

local function beginSlide(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1
    then
        sliding = true
        updateFromX(input.Position.X)
    end
end

bar.InputBegan:Connect(beginSlide)
knob.InputBegan:Connect(beginSlide)

UserInputService.InputChanged:Connect(function(input)
    if not sliding then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    then
        updateFromX(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1
    then
        sliding = false
    end
end)

local dragging = false
local dragStart
local startPosition

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1
    then
        if input.Position.Y <= bar.AbsolutePosition.Y - 8 then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragStart or not startPosition then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    then
        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1
    then
        dragging = false
    end
end)

task.spawn(function()
    while state.running do
        pcall(attachCameraInput)
        task.wait(0.5)
    end
end)

attachCameraInput()
