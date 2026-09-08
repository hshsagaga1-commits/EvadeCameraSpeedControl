local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local camera = workspace.CurrentCamera

local lines = {}

local function add(text)
    table.insert(lines, tostring(text))
end

local function describe(instance)
    if not instance then
        return "nil"
    end

    return instance:GetFullName() .. " [" .. instance.ClassName .. "]"
end

add("=== EVADE LEGACY CAMERA REPORT ===")
add("PlaceId: " .. tostring(game.PlaceId))
add("GameId: " .. tostring(game.GameId))
add("Camera: " .. describe(camera))

if camera then
    add("CameraType: " .. tostring(camera.CameraType))
    add("CameraSubject: " .. describe(camera.CameraSubject))
end

local cameraShake = playerScripts:FindFirstChild("CameraShake")

add("CameraShake: " .. describe(cameraShake))

if cameraShake and cameraShake:IsA("ValueBase") then
    local ok, value = pcall(function()
        return cameraShake.Value
    end)

    if ok then
        add("CameraShake.ValueType: " .. typeof(value))
    end
end

add("")
add("--- PlayerScripts direct children ---")

for _, object in ipairs(playerScripts:GetChildren()) do
    add(object.Name .. " [" .. object.ClassName .. "]")
end

local keywords = {
    "camera",
    "input",
    "control",
    "touch",
    "mouse",
    "look",
    "view",
    "aim",
    "shake"
}

local function interesting(name)
    name = string.lower(name)

    for _, keyword in ipairs(keywords) do
        if string.find(name, keyword, 1, true) then
            return true
        end
    end

    return false
end

add("")
add("--- Interesting PlayerScripts descendants ---")

local found = 0

for _, object in ipairs(playerScripts:GetDescendants()) do
    if interesting(object.Name) then
        add(describe(object))
        found += 1

        if found >= 150 then
            add("[truncated]")
            break
        end
    end
end

local playerGui = player:FindFirstChild("PlayerGui")

if playerGui then
    add("")
    add("--- Interesting PlayerGui descendants ---")

    local guiFound = 0

    for _, object in ipairs(playerGui:GetDescendants()) do
        if interesting(object.Name) then
            add(describe(object))
            guiFound += 1

            if guiFound >= 100 then
                add("[truncated]")
                break
            end
        end
    end
end

add("")
add("--- CameraInput modules ---")

local cameraInputs = 0

for _, object in ipairs(playerScripts:GetDescendants()) do
    if object:IsA("ModuleScript")
        and object.Name == "CameraInput"
    then
        cameraInputs += 1

        local ok, module = pcall(require, object)

        add(describe(object))
        add("require: " .. tostring(ok))

        if ok then
            add("getRotation: " .. tostring(
                type(module) == "table"
                and type(module.getRotation) == "function"
            ))
        end
    end
end

add("CameraInput count: " .. tostring(cameraInputs))

local report = table.concat(lines, "\n")

print(report)

pcall(function()
    if setclipboard then
        setclipboard(report)
    end
end)

local parent

pcall(function()
    if gethui then
        parent = gethui()
    end
end)

if not parent then
    parent = CoreGui
end

local old = parent:FindFirstChild("EvadeLegacyCameraDiagnostic")

if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "EvadeLegacyCameraDiagnostic"
gui.ResetOnSpawn = false
gui.Parent = parent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.88, 0, 0.72, 0)
frame.Position = UDim2.new(0.06, 0, 0.14, 0)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -110, 0, 42)
title.Position = UDim2.fromOffset(12, 4)
title.BackgroundTransparency = 1
title.Text = "Legacy Camera Diagnostic"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextSize = 16
title.Font = Enum.Font.GothamSemibold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(44, 32)
close.Position = UDim2.new(1, -52, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(245, 245, 245)
close.TextSize = 14
close.Font = Enum.Font.GothamBold
close.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = close

local copy = Instance.new("TextButton")
copy.Size = UDim2.fromOffset(82, 32)
copy.Position = UDim2.new(1, -142, 0, 8)
copy.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
copy.Text = "COPY"
copy.TextColor3 = Color3.fromRGB(245, 245, 245)
copy.TextSize = 12
copy.Font = Enum.Font.GothamBold
copy.Parent = frame

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 8)
copyCorner.Parent = copy

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -24, 1, -58)
box.Position = UDim2.fromOffset(12, 50)
box.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
box.BorderSizePixel = 0
box.ClearTextOnFocus = false
box.MultiLine = true
box.TextEditable = true
box.Text = report
box.TextColor3 = Color3.fromRGB(225, 225, 230)
box.TextSize = 11
box.Font = Enum.Font.Code
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.TextWrapped = false
box.Parent = frame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 8)
boxCorner.Parent = box

copy.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard(report)
            copy.Text = "COPIED"
            task.wait(1)
            copy.Text = "COPY"
        end
    end)
end)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
