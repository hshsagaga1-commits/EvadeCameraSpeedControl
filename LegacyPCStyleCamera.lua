local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local env = getgenv and getgenv() or _G

if env.__EvadeLegacyPCStyleCamera then
    local old = env.__EvadeLegacyPCStyleCamera

    pcall(function()
        if old.baseCamera
            and old.originalGetSubjectPosition
            and old.baseCamera.GetSubjectPosition == old.wrapper
        then
            old.baseCamera.GetSubjectPosition = old.originalGetSubjectPosition
        end
    end)

    old.running = false
end

local state = {
    running = true,
    baseCamera = nil,
    originalGetSubjectPosition = nil,
    wrapper = nil,
    controllers = setmetatable({}, {__mode = "k"})
}

env.__EvadeLegacyPCStyleCamera = state

local HORIZONTAL_LAG_TIME = 0.06
local VERTICAL_LAG_TIME = 0.012
local HORIZONTAL_RESPONSE = 12.5
local VERTICAL_RESPONSE = 20
local MAX_HORIZONTAL_OFFSET = 3.25
local MAX_VERTICAL_OFFSET = 0.9
local RESET_DISTANCE = 24
local RESET_TIME = 0.35

local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Legacy PC Camera",
            Text = text,
            Duration = 4
        })
    end)
end

local function findLegacyBaseCamera()
    local playerScripts = player:FindFirstChild("PlayerScripts")

    if not playerScripts then
        return nil
    end

    local playerModule = playerScripts:FindFirstChild("PlayerModule")

    if not playerModule then
        return nil
    end

    local cameraModule = playerModule:FindFirstChild("CameraModule")

    if not cameraModule then
        return nil
    end

    if cameraModule:FindFirstChild("CameraInput") then
        return nil
    end

    local baseCamera = cameraModule:FindFirstChild("BaseCamera")

    if baseCamera and baseCamera:IsA("ModuleScript") then
        return baseCamera
    end

    return nil
end

local function getLocalRoot()
    local character = player.Character

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function clampVectorXZ(vector, maxMagnitude)
    local flat = Vector3.new(vector.X, 0, vector.Z)
    local magnitude = flat.Magnitude

    if magnitude > maxMagnitude and magnitude > 0 then
        flat = flat.Unit * maxMagnitude
    end

    return flat
end

local function attach()
    local module = findLegacyBaseCamera()

    if not module then
        return false
    end

    local ok, baseCamera = pcall(require, module)

    if not ok
        or type(baseCamera) ~= "table"
        or type(baseCamera.GetSubjectPosition) ~= "function"
    then
        return false
    end

    if state.baseCamera == baseCamera
        and baseCamera.GetSubjectPosition == state.wrapper
    then
        return true
    end

    local original = baseCamera.GetSubjectPosition

    local function wrapper(self, ...)
        local realPosition = original(self, ...)

        if typeof(realPosition) ~= "Vector3" then
            return realPosition
        end

        local camera = workspace.CurrentCamera

        if not camera then
            return realPosition
        end

        local subject = camera.CameraSubject

        if not subject
            or not subject:IsA("Humanoid")
            or subject.Parent ~= player.Character
        then
            state.controllers[self] = nil
            return realPosition
        end

        local root = getLocalRoot()

        if not root then
            state.controllers[self] = nil
            return realPosition
        end

        local okDistance, distance = pcall(function()
            return self:GetCameraToSubjectDistance()
        end)

        if okDistance and type(distance) == "number" and distance < 2 then
            state.controllers[self] = nil
            return realPosition
        end

        local now = os.clock()
        local data = state.controllers[self]

        if not data then
            data = {
                offset = Vector3.new(),
                lastReal = realPosition,
                time = now
            }
            state.controllers[self] = data
            return realPosition
        end

        local dt = now - data.time
        data.time = now

        if dt <= 0
            or dt > RESET_TIME
            or (realPosition - data.lastReal).Magnitude > RESET_DISTANCE
        then
            data.offset = Vector3.new()
            data.lastReal = realPosition
            return realPosition
        end

        dt = math.min(dt, 1 / 20)

        local maxHorizontal = MAX_HORIZONTAL_OFFSET
        local maxVertical = MAX_VERTICAL_OFFSET

        if okDistance and type(distance) == "number" then
            maxHorizontal = math.min(
                MAX_HORIZONTAL_OFFSET,
                math.max(0.85, distance * 0.24)
            )

            maxVertical = math.min(
                MAX_VERTICAL_OFFSET,
                math.max(0.3, distance * 0.07)
            )
        end

        local velocity = root.AssemblyLinearVelocity
        local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)

        local desiredHorizontal =
            clampVectorXZ(
                -horizontalVelocity * HORIZONTAL_LAG_TIME,
                maxHorizontal
            )

        local desiredY =
            math.clamp(
                -velocity.Y * VERTICAL_LAG_TIME,
                -maxVertical,
                maxVertical
            )

        local current = data.offset

        local horizontalAlpha =
            1 - math.exp(-HORIZONTAL_RESPONSE * dt)

        local verticalAlpha =
            1 - math.exp(-VERTICAL_RESPONSE * dt)

        local nextHorizontal =
            Vector3.new(current.X, 0, current.Z):Lerp(
                desiredHorizontal,
                horizontalAlpha
            )

        nextHorizontal =
            clampVectorXZ(nextHorizontal, maxHorizontal)

        local nextY =
            current.Y
            + (desiredY - current.Y) * verticalAlpha

        nextY = math.clamp(nextY, -maxVertical, maxVertical)

        local nextOffset =
            nextHorizontal + Vector3.new(0, nextY, 0)

        data.offset = nextOffset
        data.lastReal = realPosition

        return realPosition + nextOffset
    end

    state.baseCamera = baseCamera
    state.originalGetSubjectPosition = original
    state.wrapper = wrapper
    baseCamera.GetSubjectPosition = wrapper

    return true
end

task.spawn(function()
    local announced = false

    while state.running do
        local attached = false

        pcall(function()
            attached = attach()
        end)

        if attached and not announced then
            announced = true
            notify("PC-style follow ativo no Legacy")
        end

        task.wait(0.5)
    end
end)

if not attach() then
    notify("Aguardando camera Legacy...")
end
