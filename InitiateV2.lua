local HttpService=game:GetService("HttpService")
local ROOT="https://raw.githubusercontent.com/hshsagaga1-commits/EvadeCameraSpeedControl/feature/precision-v2/"

local source=game:HttpGet(ROOT.."Initiate.lua?base="..HttpService:GenerateGUID(false),true)

local function replaceOncePlain(text,needle,replacement,label)
    local first,last=text:find(needle,1,true)
    if not first then error("Camera V2 patch failed: missing "..label) end
    if text:find(needle,last+1,true) then error("Camera V2 patch failed: duplicate "..label) end
    return text:sub(1,first-1)..replacement..text:sub(last+1)
end

source=replaceOncePlain(
    source,
    [[local state = {
    multiplier = 1,
    running = true,]],
    [[local state = {
    multiplier = 1,
    precisionEnabled = true,
    running = true,]],
    "precision state"
)

local oldPrecision=[[
-- No smoothing and no carried velocity: each frame is based only on the current
-- camera delta. Small deltas are compressed so slow trimp steering has more
-- usable finger travel, while large swipes keep their normal speed.
local MICRO_GAIN = 0.38
local MICRO_FULL_AT = 0.030

local function smoothstep(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function stabilizeRotation(rotation)
    local scaled = rotation
    local ok, magnitude = pcall(function() return rotation.Magnitude end)

    if ok and type(magnitude) == "number" and magnitude > 0 and UserInputService.TouchEnabled then
        local alpha = smoothstep(magnitude / MICRO_FULL_AT)
        local precisionGain = MICRO_GAIN + (1 - MICRO_GAIN) * alpha
        scaled = rotation * precisionGain
    end

    return scaled * state.multiplier
end
]]

local newPrecision=[[
-- Soft, memoryless precision with a light brake for fast touch swipes.
-- Small adjustments stay responsive; big deltas are reduced gently without
-- adding smoothing lag or locking diagonal movement.
local STRAIGHTEN_MIN_GAIN = 0.80
local STRAIGHTEN_FULL_RATIO = 0.26
local FAST_MOVE_START = 0.06
local FAST_MOVE_FULL = 0.32
local FAST_MOVE_MIN_GAIN = 0.86

local function smoothstep(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function stabilizeRotation(rotation)
    local scaled = rotation

    if state.precisionEnabled and UserInputService.TouchEnabled and typeof(rotation) == "Vector2" then
        local ax = math.abs(rotation.X)
        local ay = math.abs(rotation.Y)
        local major = math.max(ax, ay)
        local minor = math.min(ax, ay)

        -- Reduce near-axis wobble slightly, while keeping diagonal movement alive.
        if major > 0 and minor > 0 then
            local ratio = minor / major
            local alpha = smoothstep(ratio / STRAIGHTEN_FULL_RATIO)
            local minorGain = STRAIGHTEN_MIN_GAIN + (1 - STRAIGHTEN_MIN_GAIN) * alpha

            if ax >= ay then
                scaled = Vector2.new(rotation.X, rotation.Y * minorGain)
            else
                scaled = Vector2.new(rotation.X * minorGain, rotation.Y)
            end
        end

        -- Soft brake applies only to large per-frame movement deltas.
        -- Fine movements remain untouched and there is no delayed camera follow.
        local magnitude = scaled.Magnitude
        if magnitude > FAST_MOVE_START then
            local brake = smoothstep(
                (magnitude - FAST_MOVE_START) / (FAST_MOVE_FULL - FAST_MOVE_START)
            )
            local gain = 1 - (1 - FAST_MOVE_MIN_GAIN) * brake
            scaled = scaled * gain
        end
    end

    return scaled * state.multiplier
end
]]
source=replaceOncePlain(source,oldPrecision,newPrecision,"soft precision transform")

source=replaceOncePlain(
    source,
    [[frame.Size = UDim2.fromOffset(250, 104)]],
    [[frame.Size = UDim2.fromOffset(250, 144)]],
    "panel height"
)

local marker=[[local MIN = 0.1
local MAX = 2
local STEP = 0.1
]]
local toggleBlock=[[local precisionButton = Instance.new("TextButton")
precisionButton.Name = "PrecisionToggle"
precisionButton.Size = UDim2.new(1, -28, 0, 28)
precisionButton.Position = UDim2.fromOffset(14, 104)
precisionButton.BackgroundColor3 = Color3.fromRGB(42, 42, 47)
precisionButton.BorderSizePixel = 0
precisionButton.AutoButtonColor = true
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

local MIN = 0.1
local MAX = 2
local STEP = 0.1
]]
source=replaceOncePlain(source,marker,toggleBlock,"precision toggle UI")

local chunk,err=loadstring(source)
if not chunk then error(err) end
return chunk()
