# Camera Precision V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add independent precision ON/OFF to the 0.1x-2.0x camera sensitivity control and make touch direction cleaner without temporal smoothing.

**Architecture:** Keep the existing dual-hook architecture. Replace micro-speed compression with a memoryless axis-cleanup transform gated by a Precision boolean, then add UI toggle state below the slider. The loader remains this repo only.

**Tech Stack:** Luau, Python model tests.

**Spec:** `docs/superpowers/specs/2026-09-17-camera-precision-design.md`

## Global Constraints
- 0.1x-2.0x, 0.1 step, default 1.0x.
- Precision independent of sensitivity.
- No temporal state/inertia.
- No movement-repo imports.

---

### Task 1: Red-green axis precision transform

**Files:**
- Modify: `Initiate.lua`
- Test: local Python model (ephemeral)

- [ ] **Step 1: Write failing model tests**
Cases: `(1.0,0.05)` becomes near-horizontal; `(0.05,1.0)` near-vertical; `(1,0.8)` remains diagonal; `(4,0.2)` retains approximately the original dominant magnitude; precision OFF returns exactly input*multiplier.

- [ ] **Step 2: Run against current micro-gain model**
Expected: fails axis-cleanup expectations because both axes are scaled together.

- [ ] **Step 3: Implement memoryless axis cleanup**
Use dominant/minor ratio thresholds with smooth attenuation of only the minor component. Preserve dominant component and apply multiplier after cleanup.

- [ ] **Step 4: Verify model tests**
Expected: all cases pass, no state carried between calls.

### Task 2: Precision toggle UI

- [ ] **Step 1: Write source contract checks**
Require `state.precisionEnabled`, `Precision ON/OFF` text, 0.1/2.0 range, default 1.0.

- [ ] **Step 2: Extend GUI**
Increase panel height, add a toggle row/button, update label and state on touch/click. Keep slider/drag logic unchanged otherwise.

- [ ] **Step 3: Verify source contracts**
No references to PCModeLock, joystick bridge, body-view or movement repository URLs.

### Task 3: Standalone loader + README

**Files:**
- Create: `Loader.lua`
- Modify: `README.md`

- [ ] **Step 1: Create loader**
Fetch only `Initiate.lua` from this repository with cachebuster.

- [ ] **Step 2: Update README**
Document sensitivity range, Precision toggle, and standalone loader.

- [ ] **Step 3: Verify loader isolation**
Exactly one fetch target in loader and it points to this repo.

- [ ] **Step 4: Commit**
Commit message: `feat: add independent directional precision toggle`.
