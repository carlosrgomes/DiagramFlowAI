# Implementation Plan: Real Local Gemma 4 Integration

## Phase 1: Native Setup & Dependencies [checkpoint: 6ae2362]
- [x] Task: Add `flutter_gemma` dependency to `pubspec.yaml`. [6ae2362]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Update `macos/Podfile` to include `OTHER_LDFLAGS` for `flutter_gemma`. [6ae2362]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 1: Native Setup & Dependencies' (Protocol in workflow.md)

## Phase 2: Engine Initialization
- [ ] Task: Update `AIModelState` to initialize `FlutterGemma` and manage the engine lifecycle.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Engine Initialization' (Protocol in workflow.md)

## Phase 3: Real Inference Stream
- [ ] Task: Refactor `AIEngineService` to use `FlutterGemma.instance.getResponseStream()` with system instructions.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Update `RightSidebar` to handle real-time streaming updates for both thoughts and final actions.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Real Inference Stream' (Protocol in workflow.md)