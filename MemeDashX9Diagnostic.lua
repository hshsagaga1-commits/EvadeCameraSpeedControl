-- MemeDash X9: Touch + Camera Deep Diagnostic
-- Diagnostic only. Does not change camera sensitivity or character movement.
-- Intended to gather a compact report while the user drags the camera with touch.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
local KEY = "__MemeDashX9Diagnostic"

if env[KEY] and env[KEY].stop then pcall(env[KEY].stop) end

local S = {
    running = true, events = {}, started = os.clock(), touchActive = {},
    touchBegin = 0, touchChange = 0, touchEnd = 0, mouseChange = 0,
    inputChanged = 0, inputBegan = 0, inputEnded = 0, cameraChanges = 0,
    cameraNearTouch = 0, lastTouchTime = 0, lastTouchPos = nil,
    lastCamera = nil, cameraSamples = {}, inputs = {}, connections = {},
    modules = {}, functionHits = {}, gcTables = 0, gcFunctions = 0
}
env[KEY] = S

local function push(list, value, max)
    list[#list+1] = tostring(value)
    while #list > (max or 100) do table.remove(list, 1) end
end
local function safe(fn, fallback)
    local ok, result = pcall(fn)
    if ok then return result end
    return fallback or "unavailable"
end
local function describeInput(input)
    if not input then return "nil" end
    local pos = safe(function() return input.Position end, nil)
    local delta = safe(function() return input.Delta end, nil)
    local key = safe(function() return input.KeyCode.Name end, "?")
    local state = safe(function() return input.UserInputState.Name end, "?")
    local typ = safe(function() return input.UserInputType.Name end, "?")
    return string.format("type=%s state=%s key=%s pos=%s delta=%s", tostring(typ), tostring(state), tostring(key), tostring(pos), tostring(delta))
end
local function camInfo()
    local cam = workspace.CurrentCamera
    if not cam then return "CurrentCamera=nil" end
    local subject = cam.CameraSubject
    local subjectText = subject and (subject.ClassName .. ":" .. subject.Name) or "nil"
    local p = cam.CFrame.Position
    local l = cam.CFrame.LookVector
    return string.format("type=%s mode=%s fov=%.2f subject=%s pos=(%.2f,%.2f,%.2f) look=(%.4f,%.4f,%.4f)",
        cam.CameraType.Name, tostring(player.CameraMode), cam.FieldOfView, subjectText,
        p.X,p.Y,p.Z,l.X,l.Y,l.Z)
end

local function scanPlayerModule()
    local ps = player:FindFirstChildOfClass("PlayerScripts")
    local pm = ps and ps:FindFirstChild("PlayerModule")
    if not pm then push(S.modules, "PlayerModule not found under PlayerScripts", 80); return end
    push(S.modules, "PlayerModule path=" .. pm:GetFullName(), 80)
    local objects = {pm}
    for _, obj in ipairs(pm:GetDescendants()) do objects[#objects+1] = obj end
    for _, obj in ipairs(objects) do
        if obj:IsA("ModuleScript") then
            local lower = string.lower(obj.Name .. " " .. obj:GetFullName())
            if lower:find("camera") or lower:find("input") or lower:find("touch") or lower:find("control") then
                local status = "not required"
                local ok, result = pcall(require, obj)
                if ok then
                    status = "require OK (" .. typeof(result) .. ")"
                    if type(result) == "table" then
                        local keys = {}
                        for k,v in pairs(result) do
                            if type(k) == "string" and (k:lower():find("camera") or k:lower():find("input") or k:lower():find("touch") or k:lower():find("rot")) then
                                keys[#keys+1] = k .. ":" .. typeof(v)
                            end
                        end
                        if #keys > 0 then status = status .. " keys={" .. table.concat(keys, ",") .. "}" end
                    end
                else
                    status = "require failed: " .. tostring(result)
                end
                push(S.modules, obj:GetFullName() .. " -> " .. status, 80)
            end
        end
    end
end

local function scanGC()
    if type(getgc) ~= "function" then
        push(S.functionHits, "getgc unavailable in this executor", 100)
        return
    end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then
        push(S.functionHits, "getgc scan failed: " .. tostring(objects), 100)
        return
    end
    local seen = {}
    for _, obj in ipairs(objects) do
        if type(obj) == "table" then
            S.gcTables += 1
            local keys = {}
            for k,v in pairs(obj) do
                if type(k) == "string" and (k:lower():find("camera") or k:lower():find("input") or k:lower():find("touch") or k:lower():find("rot") or k:lower():find("gesture")) then
                    keys[#keys+1] = k .. ":" .. type(v)
                end
            end
            if #keys > 0 then push(S.functionHits, "TABLE keys={" .. table.concat(keys, ",") .. "}", 100) end
        elseif type(obj) == "function" and not seen[obj] then
            seen[obj] = true
            S.gcFunctions += 1
            local info = safe(function()
                if debug and debug.getinfo then
                    local d = debug.getinfo(obj, "nS")
                    return string.format("name=%s source=%s", tostring(d.name), tostring(d.short_src or d.source))
                end
                return nil
            end, nil)
            if info then
                local low = string.lower(info)
                if low:find("camera") or low:find("input") or low:find("touch") or low:find("rot") or low:find("gesture") then
                    push(S.functionHits, "FUNCTION " .. info, 100)
                end
            end
        end
    end
end

local parent
pcall(function() if gethui then parent = gethui() end end)
if not parent then parent = CoreGui end
local gui = Instance.new("ScreenGui")
gui.Name = KEY
gui.ResetOnSpawn = false
gui.Parent = parent
S.gui = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(330, 250)
frame.Position = UDim2.new(0.5,-165,0.12,0)
frame.BackgroundColor3 = Color3.fromRGB(23,23,28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner",frame).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-12,0,26)
title.Position = UDim2.fromOffset(8,4)
title.BackgroundTransparency = 1
title.Text = "MemeDash X9 | Diagnóstico profundo"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamSemibold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,-16,0,135)
info.Position = UDim2.fromOffset(8,32)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(220,220,225)
info.Font = Enum.Font.Code
info.TextSize = 11
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = frame

local function makeButton(text, x, width)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(width,26)
    b.Position = UDim2.new(0,x,1,-32)
    b.BackgroundColor3 = Color3.fromRGB(65,65,74)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text
    b.Font = Enum.Font.Gotham
    b.TextSize = 10
    b.Parent = frame
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end
local reportButton = makeButton("Gerar relatório", 8, 110)
local closeButton = makeButton("Fechar", 126, 70)
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-210,0,26)
status.Position = UDim2.new(0,205,1,-32)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(130,235,160)
status.Text = "Pronto para testar"
status.Font = Enum.Font.Gotham
status.TextSize = 10
status.Parent = frame

local function connect(signal, fn)
    local ok, conn = pcall(function() return signal:Connect(fn) end)
    if ok and conn then S.connections[#S.connections+1] = conn end
end

connect(UIS.InputBegan, function(input, processed)
    S.inputBegan += 1
    if input.UserInputType == Enum.UserInputType.Touch then
        S.touchBegin += 1
        S.touchActive[input] = true
        S.lastTouchTime = os.clock()
        S.lastTouchPos = input.Position
    end
    push(S.inputs, "BEGAN processed="..tostring(processed).." "..describeInput(input), 60)
end)
connect(UIS.InputChanged, function(input, processed)
    S.inputChanged += 1
    if input.UserInputType == Enum.UserInputType.Touch then
        S.touchChange += 1
        S.lastTouchTime = os.clock()
        S.lastTouchPos = input.Position
    elseif input.UserInputType == Enum.UserInputType.MouseMovement then
        S.mouseChange += 1
    end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        push(S.inputs, "CHANGED processed="..tostring(processed).." "..describeInput(input), 60)
    end
end)
connect(UIS.InputEnded, function(input, processed)
    S.inputEnded += 1
    if input.UserInputType == Enum.UserInputType.Touch then
        S.touchEnd += 1
        S.touchActive[input] = nil
        S.lastTouchTime = os.clock()
    end
    push(S.inputs, "ENDED processed="..tostring(processed).." "..describeInput(input), 60)
end)

local lastCFrame
connect(RunService.RenderStepped, function()
    local cam = workspace.CurrentCamera
    if cam then
        local cf = cam.CFrame
        if lastCFrame then
            local angle = lastCFrame.LookVector:Angle(cf.LookVector)
            if angle > 0.000001 then
                S.cameraChanges += 1
                if os.clock() - S.lastTouchTime < 0.35 then S.cameraNearTouch += 1 end
                push(S.cameraSamples, string.format("t=%.2f angle=%.6f %s", os.clock()-S.started, angle, camInfo()), 30)
            end
        end
        lastCFrame = cf
    end
end)

-- Optional signal names are probed without assuming every Roblox build exposes them.
local cam = workspace.CurrentCamera
if cam then
    for _, prop in ipairs({"CameraType","CameraSubject","FieldOfView","CFrame"}) do
        push(S.modules, "Camera property available: "..prop.."="..tostring(safe(function() return cam[prop] end)), 80)
    end
end
push(S.modules, "TouchEnabled="..tostring(UIS.TouchEnabled).." MouseEnabled="..tostring(UIS.MouseEnabled).." KeyboardEnabled="..tostring(UIS.KeyboardEnabled), 80)
scanPlayerModule()
scanGC()

local function buildReport()
    local lines = {
        "=== MemeDash X9 REPORT ===",
        "Elapsed seconds: "..string.format("%.2f", os.clock()-S.started),
        "Touch begin/change/end: "..S.touchBegin.."/"..S.touchChange.."/"..S.touchEnd,
        "InputBegan/InputChanged/InputEnded: "..S.inputBegan.."/"..S.inputChanged.."/"..S.inputEnded,
        "Mouse movement events: "..S.mouseChange,
        "Camera direction changes: "..S.cameraChanges,
        "Camera changes near touch (<350ms): "..S.cameraNearTouch,
        "Active touches: "..tostring((function() local n=0 for _ in pairs(S.touchActive) do n+=1 end return n end)()),
        "Last touch position: "..tostring(S.lastTouchPos),
        "Input support: Touch="..tostring(UIS.TouchEnabled).." Mouse="..tostring(UIS.MouseEnabled).." Keyboard="..tostring(UIS.KeyboardEnabled),
        "Current camera: "..camInfo(),
        "GC tables scanned: "..S.gcTables.." | functions scanned: "..S.gcFunctions,
        "", "--- PlayerModule / camera-related modules ---"
    }
    for _,v in ipairs(S.modules) do lines[#lines+1] = v end
    lines[#lines+1] = ""
    lines[#lines+1] = "--- Camera rotation samples ---"
    for _,v in ipairs(S.cameraSamples) do lines[#lines+1] = v end
    lines[#lines+1] = ""
    lines[#lines+1] = "--- Recent touch/mouse input events ---"
    for _,v in ipairs(S.inputs) do lines[#lines+1] = v end
    lines[#lines+1] = ""
    lines[#lines+1] = "--- GC function/table name matches ---"
    for _,v in ipairs(S.functionHits) do lines[#lines+1] = v end
    return table.concat(lines, "\n")
end

reportButton.Activated:Connect(function()
    local report = buildReport()
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, report)
        if ok then status.Text = "Relatório copiado!" else status.Text = "Relatório no console" end
    else
        status.Text = "Relatório no console"
    end
    if type(warn) == "function" then warn(report) end
    if type(print) == "function" then print(report) end
end)
closeButton.Activated:Connect(function()
    S.running = false
    for _,conn in ipairs(S.connections) do pcall(function() conn:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end)

-- Keep the panel responsive; refresh display stats.
local renderConn
renderConn = RunService.RenderStepped:Connect(function()
    if not S.running then renderConn:Disconnect(); return end
    info.Text = string.format(
        "Toque início/movimento/fim: %d/%d/%d\nEventos de input: %d / %d / %d\nMovimento do mouse: %d\nMudanças de câmera: %d\nCâmera perto do toque: %d\nToques ativos: %d\n\nArraste a câmera por 10s; depois toque em Gerar relatório.",
        S.touchBegin,S.touchChange,S.touchEnd,S.inputBegan,S.inputChanged,S.inputEnded,S.mouseChange,
        S.cameraChanges,S.cameraNearTouch,(function() local n=0 for _ in pairs(S.touchActive) do n+=1 end return n end)()
    )
end)

S.stop = function()
    S.running = false
    for _,conn in ipairs(S.connections) do pcall(function() conn:Disconnect() end) end
    if renderConn then pcall(function() renderConn:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end
