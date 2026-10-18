-- MemeDash X9.1 - Responsive touch/camera diagnostic
-- GUI and report controls are initialized before any scanning.
-- Diagnostic only; does not modify camera sensitivity or movement.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
local KEY = "__MemeDashX9Diagnostic"

pcall(function()
    local previous = env[KEY]
    if previous and previous.stop then previous.stop() end
end)

local S = {
    running = true, started = os.clock(), touchBegin = 0, touchChange = 0, touchEnd = 0,
    inputBegan = 0, inputChanged = 0, inputEnded = 0, mouseChange = 0,
    cameraChanges = 0, cameraNearTouch = 0, lastTouchTime = 0, lastTouchPos = nil,
    touchActive = {}, cameraSamples = {}, inputs = {}, modules = {}, functionHits = {},
    gcTables = 0, gcFunctions = 0, scanStatus = "Aguardando teste", connections = {}
}
env[KEY] = S

local function push(list, value, max)
    list[#list+1] = tostring(value)
    while #list > (max or 50) do table.remove(list, 1) end
end
local function safe(fn, fallback)
    local ok, result = pcall(fn)
    if ok then return result end
    return fallback or "indisponível"
end
local function connect(signal, fn)
    local ok, conn = pcall(function() return signal:Connect(fn) end)
    if ok and conn then S.connections[#S.connections+1] = conn end
    return conn
end
local function camInfo()
    local cam = workspace.CurrentCamera
    if not cam then return "CurrentCamera=nil" end
    local subject = cam.CameraSubject
    local subjectText = subject and (subject.ClassName .. ":" .. subject.Name) or "nil"
    local p, l = cam.CFrame.Position, cam.CFrame.LookVector
    return string.format("type=%s mode=%s fov=%.1f subject=%s pos=(%.1f,%.1f,%.1f) look=(%.3f,%.3f,%.3f)",
        cam.CameraType.Name, tostring(player.CameraMode), cam.FieldOfView, subjectText,
        p.X,p.Y,p.Z,l.X,l.Y,l.Z)
end
local function describeInput(input, processed, event)
    local pos = safe(function() return input.Position end, "?")
    local delta = safe(function() return input.Delta end, "?")
    local typ = safe(function() return input.UserInputType.Name end, "?")
    local state = safe(function() return input.UserInputState.Name end, "?")
    push(S.inputs, string.format("%s processed=%s type=%s state=%s pos=%s delta=%s", event, tostring(processed), tostring(typ), tostring(state), tostring(pos), tostring(delta)), 45)
end

local parent
pcall(function() if type(gethui) == "function" then parent = gethui() end end)
if not parent then parent = CoreGui end
local gui = Instance.new("ScreenGui")
gui.Name = KEY
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent
S.gui = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 238)
frame.Position = UDim2.new(0.5,-160,0.13,0)
frame.BackgroundColor3 = Color3.fromRGB(23,23,28)
frame.BorderSizePixel = 0
frame.Active = true
frame.ZIndex = 10
frame.Parent = gui
Instance.new("UICorner",frame).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-16,0,27)
title.Position = UDim2.fromOffset(8,4)
title.BackgroundTransparency = 1
title.Text = "MemeDash X9.1 | Diagnóstico"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamSemibold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 11
title.Parent = frame

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,-16,0,145)
info.Position = UDim2.fromOffset(8,33)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(225,225,230)
info.Font = Enum.Font.Code
info.TextSize = 11
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.ZIndex = 11
info.Parent = frame

local function makeButton(label, x, width)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(width,30)
    b.Position = UDim2.new(0,x,1,-36)
    b.BackgroundColor3 = Color3.fromRGB(68,68,78)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = label
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11
    b.AutoButtonColor = true
    b.Active = true
    b.Selectable = true
    b.ZIndex = 20
    b.Parent = frame
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end
local reportButton = makeButton("GERAR RELATÓRIO", 8, 132)
local closeButton = makeButton("FECHAR", 148, 75)
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-235,0,30)
status.Position = UDim2.new(0,230,1,-36)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(130,235,160)
status.Text = "Pronto"
status.Font = Enum.Font.Gotham
status.TextSize = 10
status.TextWrapped = true
status.ZIndex = 11
status.Parent = frame

local function stop()
    if not S.running then return end
    S.running = false
    for _, c in ipairs(S.connections) do pcall(function() c:Disconnect() end) end
    if S.renderConn then pcall(function() S.renderConn:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end
S.stop = stop

-- Connect controls before scanning anything.
local function generateReport()
    status.Text = "Montando..."
    local lines = {
        "=== MEMEDASH X9.1 REPORT ===",
        "Elapsed: "..string.format("%.1f",os.clock()-S.started).."s",
        "Touch begin/change/end: "..S.touchBegin.."/"..S.touchChange.."/"..S.touchEnd,
        "InputBegan/Changed/Ended: "..S.inputBegan.."/"..S.inputChanged.."/"..S.inputEnded,
        "Mouse movement events: "..S.mouseChange,
        "Camera changes: "..S.cameraChanges,
        "Camera changes within 350ms of touch: "..S.cameraNearTouch,
        "Active touches: "..tostring((function() local n=0 for _ in pairs(S.touchActive) do n+=1 end return n end)()),
        "Last touch position: "..tostring(S.lastTouchPos),
        "TouchEnabled="..tostring(UIS.TouchEnabled).." MouseEnabled="..tostring(UIS.MouseEnabled).." KeyboardEnabled="..tostring(UIS.KeyboardEnabled),
        "Camera: "..camInfo(),
        "Scan status: "..S.scanStatus,
        "GC tables scanned: "..S.gcTables.." functions scanned: "..S.gcFunctions,
        "", "--- Camera modules ---"
    }
    for _,v in ipairs(S.modules) do lines[#lines+1] = v end
    lines[#lines+1] = ""; lines[#lines+1] = "--- Camera rotation samples ---"
    for _,v in ipairs(S.cameraSamples) do lines[#lines+1] = v end
    lines[#lines+1] = ""; lines[#lines+1] = "--- Recent input events ---"
    for _,v in ipairs(S.inputs) do lines[#lines+1] = v end
    lines[#lines+1] = ""; lines[#lines+1] = "--- GC name matches ---"
    for _,v in ipairs(S.functionHits) do lines[#lines+1] = v end
    local report = table.concat(lines,"\n")
    local copied = false
    if type(setclipboard) == "function" then copied = pcall(setclipboard,report) end
    if type(toclipboard) == "function" and not copied then copied = pcall(toclipboard,report) end
    if type(warn) == "function" then pcall(warn,report) end
    if type(print) == "function" then pcall(print,report) end
    status.Text = copied and "Copiado!" or "Impresso no console"
    S.lastReport = report
end

local function bindButton(button, fn)
    local fired = false
    local function run()
        if fired then return end
        fired = true
        task.delay(0.25,function() fired = false end)
        local ok, err = pcall(fn)
        if not ok then status.Text = "Erro: "..tostring(err):sub(1,45) end
    end
    button.Activated:Connect(run)
    button.MouseButton1Click:Connect(run)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Activated handles normal touch/click; fallback only if it fails to fire.
            task.delay(0.15,function()
                if not fired and S.running then run() end
            end)
        end
    end)
end
bindButton(reportButton, generateReport)
bindButton(closeButton, stop)

connect(UIS.InputBegan,function(input,processed)
    S.inputBegan += 1
    if input.UserInputType == Enum.UserInputType.Touch then
        S.touchBegin += 1; S.touchActive[input] = true; S.lastTouchTime = os.clock(); S.lastTouchPos = input.Position
    end
    describeInput(input,processed,"BEGAN")
end)
connect(UIS.InputChanged,function(input,processed)
    S.inputChanged += 1
    if input.UserInputType == Enum.UserInputType.Touch then
        S.touchChange += 1; S.lastTouchTime = os.clock(); S.lastTouchPos = input.Position
    elseif input.UserInputType == Enum.UserInputType.MouseMovement then S.mouseChange += 1 end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then describeInput(input,processed,"CHANGED") end
end)
connect(UIS.InputEnded,function(input,processed)
    S.inputEnded += 1
    if input.UserInputType == Enum.UserInputType.Touch then
        S.touchEnd += 1; S.touchActive[input] = nil; S.lastTouchTime = os.clock()
    end
    describeInput(input,processed,"ENDED")
end)

local lastCFrame
S.renderConn = RunService.RenderStepped:Connect(function()
    if not S.running then return end
    local cam = workspace.CurrentCamera
    if cam then
        local cf = cam.CFrame
        if lastCFrame then
            local angle = lastCFrame.LookVector:Angle(cf.LookVector)
            if angle > 0.000001 then
                S.cameraChanges += 1
                if os.clock()-S.lastTouchTime < 0.35 then S.cameraNearTouch += 1 end
                push(S.cameraSamples,string.format("t=%.2f angle=%.6f %s",os.clock()-S.started,angle,camInfo()),20)
            end
        end
        lastCFrame = cf
    end
    info.Text = string.format(
        "Toque início/movimento/fim: %d/%d/%d\nEventos input: %d/%d/%d | mouse: %d\nMudanças de câmera: %d\nCâmera perto do toque: %d\nToques ativos: %d\n\nArraste a câmera por 10s e gere o relatório.",
        S.touchBegin,S.touchChange,S.touchEnd,S.inputBegan,S.inputChanged,S.inputEnded,S.mouseChange,
        S.cameraChanges,S.cameraNearTouch,(function() local n=0 for _ in pairs(S.touchActive) do n+=1 end return n end)()
    )
end)

-- Scans happen after the GUI and buttons are alive, and are deliberately bounded.
task.spawn(function()
    S.scanStatus = "Escaneando módulos..."
    local ps = player:FindFirstChildOfClass("PlayerScripts")
    local pm = ps and ps:FindFirstChild("PlayerModule")
    if pm then
        push(S.modules,"PlayerModule: "..pm:GetFullName(),50)
        local objects = pm:GetDescendants()
        local count = 0
        for _,obj in ipairs(objects) do
            if not S.running then return end
            if obj:IsA("ModuleScript") and count < 35 then
                local low = string.lower(obj.Name.." "..obj:GetFullName())
                if low:find("camera") or low:find("input") or low:find("touch") or low:find("control") then
                    push(S.modules,"ModuleScript: "..obj:GetFullName(),50)
                    count += 1
                end
            end
        end
    else
        push(S.modules,"PlayerModule not found under PlayerScripts",50)
    end
    S.scanStatus = "Módulos prontos; GC opcional"
    if type(getgc) == "function" then
        local ok, objects = pcall(getgc,true)
        if ok and type(objects) == "table" then
            local limit = math.min(#objects,2500)
            local seen = {}
            for i=1,limit do
                if not S.running then return end
                local obj = objects[i]
                if type(obj) == "table" then
                    S.gcTables += 1
                    local names = {}
                    for k,v in pairs(obj) do
                        if type(k)=="string" and (k:lower():find("camera") or k:lower():find("input") or k:lower():find("touch") or k:lower():find("rot") or k:lower():find("gesture")) then
                            names[#names+1] = k..":"..type(v)
                            if #names >= 8 then break end
                        end
                    end
                    if #names>0 then push(S.functionHits,"TABLE {"..table.concat(names,",").."}",50) end
                elseif type(obj)=="function" and not seen[obj] then
                    seen[obj]=true; S.gcFunctions += 1
                    if debug and type(debug.getinfo)=="function" then
                        local inf = safe(function() return debug.getinfo(obj,"nS") end,nil)
                        if type(inf)=="table" then
                            local name = tostring(inf.name or "")
                            local src = tostring(inf.short_src or inf.source or "")
                            local low = (name.." "..src):lower()
                            if low:find("camera") or low:find("input") or low:find("touch") or low:find("rot") or low:find("gesture") then
                                push(S.functionHits,"FUNCTION name="..name.." source="..src,50)
                            end
                        end
                    end
                end
                if i % 200 == 0 then task.wait() end
            end
            S.scanStatus = "GC limitado a "..limit.." objetos"
        else
            S.scanStatus = "getgc falhou ou indisponível"
        end
    else
        S.scanStatus = "Executor sem getgc"
    end
end)
