# EvadeCameraSpeedControl

Unified Evade camera sensitivity for Legacy and Overhaul, updated for the PC-on-mobile rebuild.

- Native CameraInput path; does not replace Camera.CFrame
- Sensitivity slider: 0.1x to 2.0x
- Stronger precision removes a wider band of tiny cross-axis noise (axis snap ratio 0.18; minor-axis threshold 0.010); no temporal smoothing or micro-movement slowdown
- No temporal smoothing / carried velocity
- Joystick and jump touches are isolated from camera rotation
- Includes the experimental re-touch first-delta guard: on a camera-area touch, it drops only the first non-zero rotation sample to test/avoid the brief camera spike observed during bhop/trimp
- The guard does not alter the sensitivity multiplier or character velocity; the first tiny intended camera movement may also be skipped
- The same 0.1x–2.0x sensitivity slider and re-touch spike guard are enabled for both Legacy and Overhaul; this script does not load MemeDash or a separate dynamic-sensitivity repository

## Loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hshsagaga1-commits/EvadeCameraSpeedControl/main/Initiate.lua?nocache=" .. tostring(os.clock())))()
```

The loader fetches the unified camera source from the `rebuild-zero-v1` branch of `movimento-de-pc-no-mobile`. Sensitivity and the experimental re-touch first-delta guard are integrated into the same script, so no separate continuity loader/panel is required. Legacy support was enabled in code; runtime behavior can still vary with the Roblox client and executor.

Experimental: if the camera feels wrong, stop the script with its cleanup/reset behavior or rejoin to reset executor hooks. The guard has been observed to improve the user's test case, but compatibility can vary with Roblox updates.