local HttpService=game:GetService("HttpService")
local ROOT="https://raw.githubusercontent.com/hshsagaga1-commits/EvadeCameraSpeedControl/main/"

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
-- Memoryless PC-like directional precision. It never carries velocity between
-- frames: near-axis touch gestures lose only their accidental minor component,
-- while real diagonals and the dominant component keep their native magnitude.
local AXIS_LOCK_RATIO = 0.12
local AXIS_RELEASE_RATIO = 0.42

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

        if major > 0 then
            local ratio = minor / major
            local minorGain

            if ratio <= AXIS_LOCK_RATIO then
                minorGain = 0
            elseif ratio >= AXIS_RELEASE_RATIO then
                minorGain = 1
            else
                minorGain = smoothstep((ratio - AXIS_LOCK_RATIO) / (AXIS_RELEASE_RATIO - AXIS_LOCK_RATIO))
            end

            if ax >= ay then
                scaled = Vector2.new(rotation.X, rotation.Y * minorGain)
            else
                scaled = Vector2.new(rotation.X * minorGain, rotation.Y)
            end
        end
    end

    return scaled * state.multiplier
end
]]
source=replaceOncePlain(source,oldPrecision,newPrecision,"memoryless precision transform")

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
