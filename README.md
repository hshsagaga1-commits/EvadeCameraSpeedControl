# EvadeCameraSpeedControl

One loader, two camera systems.

- Overhaul: hooks `CameraInput.getRotation`
- Legacy: hooks `BaseCamera.InputTranslationToCameraAngleChange`
- Auto-detects which camera architecture is available
- Range: 0.1x to 7.0x
- Default: 1.0x
- Step: 0.1x

Loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hshsagaga1-commits/EvadeCameraSpeedControl/main/Initiate.lua?nocache=" .. tostring(os.time())))()
```
