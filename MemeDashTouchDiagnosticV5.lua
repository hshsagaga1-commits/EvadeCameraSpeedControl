-- MemeDash Touch Camera Diagnostic v5
-- Diagnostic only: does not modify camera sensitivity or character movement.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
local KEY = "__MemeDashTouchDiagnosticV5"

if env[KEY] and env[KEY].gui then pcall(function() env[KEY].gui:Destroy() end) end
local state = {touchMoves = 0, cameraChanges = 0, changesDuringTouch = 0, lastTouch = 0, running = true}
env[KEY] = state

local parent
pcall(function() if gethui then parent = gethui() end end)
if not parent then parent = CoreGui end

local gui = Instance.new("ScreenGui")
gui.Name = KEY
gui.ResetOnSpawn = false
gui.Parent = parent
state.gui = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(290, 128)
frame.Position = UDim2.new(0.5, -145, 0.16, 0)
frame.BackgroundColor3 = Color3.fromRGB(24,24,28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-16,0,25)
title.Position = UDim2.fromOffset(8,5)
title.BackgroundTransparency = 1
title.Text = "MemeDash Touch Diagnostic v5"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamSemibold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,-16,0,65)
info.Position = UDim2.fromOffset(8,32)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(220,220,225)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.TextWrapped = true
info.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(50,22)
close.Position = UDim2.new(1,-58,1,-27)
close.BackgroundColor3 = Color3.fromRGB(65,65,72)
close.Text = "Fechar"
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.Gotham
close.TextSize = 10
close.Parent = frame
close.Activated:Connect(function()
    state.running = false
    gui:Destroy()
end)

local dragging, dragStart, startPos = false, nil, nil
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos = true, input.Position, frame.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and dragStart and startPos and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        state.touchMoves += 1
        state.lastTouch = os.clock()
    end
end)

local lastCameraCFrame
local function getCamera()
    return workspace.CurrentCamera
end

local conn
conn = RunService.RenderStepped:Connect(function()
    if not state.running then if conn then conn:Disconnect() end return end
    local cam = getCamera()
    if cam then
        local cf = cam.CFrame
        if lastCameraCFrame then
            local delta = lastCameraCFrame.LookVector:Angle(cf.LookVector)
            if delta > 0.00001 then
                state.cameraChanges += 1
                if os.clock() - state.lastTouch < 0.3 then
                    state.changesDuringTouch += 1
                end
            end
        end
        lastCameraCFrame = cf
    end
    info.Text = "Movimentos de toque: " .. state.touchMoves ..
        "\nMudanças na direção da câmera: " .. state.cameraChanges ..
        "\nCâmera mudou perto do toque: " .. state.changesDuringTouch ..
        "\nArraste a câmera por 5 segundos e leia os números."
end)
