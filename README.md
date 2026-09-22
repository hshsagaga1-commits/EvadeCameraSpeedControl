# EvadeCameraSpeedControl

Overhaul camera control, updated for the PC-on-mobile rebuild.

- Native CameraInput path; does not replace Camera.CFrame
- Sensitivity slider: 0.1x to 2.0x
- Precision removes only tiny cross-axis noise; no micro-movement slowdown
- No temporal smoothing / carried velocity
- Joystick and jump touches are isolated from camera rotation
- Legacy camera/fixation now lives in the separate Legacy Camera Pack

Loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hshsagaga1-commits/EvadeCameraSpeedControl/main/Initiate.lua?nocache=" .. tostring(os.clock())))()
```
