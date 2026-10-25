# EvadeCameraSpeedControl

Overhaul camera control, updated for the PC-on-mobile rebuild.

- Native CameraInput path; does not replace Camera.CFrame
- Sensitivity slider: 0.1x to 2.0x
- Precision removes only tiny cross-axis noise; no micro-movement slowdown
- No temporal smoothing / carried velocity
- Joystick and jump touches are isolated from camera rotation
- Includes the experimental re-touch first-delta guard: on a camera-area touch, it drops only the first non-zero rotation sample to test/avoid the brief camera spike observed during bhop/trimp
- The guard does not alter the sensitivity multiplier or character velocity; the first tiny intended camera movement may also be skipped
- Legacy camera/fixation now lives in the separate Legacy Camera Pack

## Loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hshsagaga1-commits/EvadeCameraSpeedControl/main/Initiate.lua?nocache=" .. tostring(os.clock())))()
```

The loader fetches the camera source from the `rebuild-zero-v1` branch of `movimento-de-pc-no-mobile`, so the integrated re-touch guard starts together with the sensitivity UI. No separate continuity panel or report is needed.

Experimental: if the camera feels wrong, stop the script with its cleanup/reset behavior or rejoin to reset executor hooks. The guard has been observed to improve the user's test case, but compatibility can vary with Roblox updates.