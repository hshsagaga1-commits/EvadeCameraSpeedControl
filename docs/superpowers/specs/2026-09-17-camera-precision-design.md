# Camera Precision Design

## Goal
Provide an independent Evade camera control that exposes sensitivity 0.1x-2.0x and an optional PC-like directional precision mode without loading movement/joystick/body-view code.

## Requirements
- Slider: 0.1x to 2.0x, step 0.1x, default 1.0x.
- Precision toggle independent of multiplier.
- Precision has zero temporal memory/carry.
- Near-horizontal input suppresses small vertical contamination.
- Near-vertical input suppresses small horizontal contamination.
- Real diagonals remain diagonals.
- Fast swipes keep their speed; precision cleans direction rather than throttling magnitude.
- Support both Overhaul (`CameraInput.getRotation`) and Legacy (`BaseCamera.InputTranslationToCameraAngleChange`).
- UI is draggable and shows multiplier + Precision ON/OFF.
- Cleanup restores hooks and GUI.
- No references to movement repository, PCModeLock, joystick, crouch, or body-view modules.

## Algorithm
For a rotation vector `(x,y)`, compute `ax=abs(x)`, `ay=abs(y)`, `minor/maxMajor`. If precision is OFF, return the vector unchanged except multiplier. If ON and the ratio is below a configurable axis-lock threshold, attenuate the minor axis with a smooth memoryless gain approaching zero near the dominant axis. In the diagonal region, leave both axes unchanged. Preserve total magnitude for large gestures where practical so trimp turns remain fast.

## Verification
Use a Python model for horizontal, vertical, diagonal, and fast-swipe cases. Run red-green before changing Luau. Static checks ensure no movement imports and correct UI range/defaults.
