local HttpService=game:GetService("HttpService")
local ROOT="https://raw.githubusercontent.com/hshsagaga1-commits/EvadeCameraSpeedControl/feature/precision-v2/"
local source=game:HttpGet(ROOT.."InitiateV2.lua?_cb="..HttpService:GenerateGUID(false),true)
local chunk,err=loadstring(source)
if not chunk then error(err) end
return chunk()
