# EvadeCameraSpeedControl

Standalone camera-only control for Evade.

- Overhaul: hooks `CameraInput.getRotation`
- Legacy: hooks `BaseCamera.InputTranslationToCameraAngleChange`
- Sensitivity range: 0.1x to 2.0x
- Step: 0.1x
- Default: 1.0x
- Independent `Precisão: ON/OFF` toggle
- Precision is memoryless: it cleans accidental minor-axis drift without adding inertia or post-release motion
- Does not load joystick, movement, crouch, body-view, or PCModeLock modules

Feature-branch loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hshsagaga1-commits/EvadeCameraSpeedControl/feature/precision-v2/Loader.lua?nocache=" .. tostring(os.clock())))()
```
