# Implementation Plan: Interactive Workspace & Model Control

## Phase 1: Interactive Canvas Nodes [checkpoint: 213d3a0]
- [x] Task: Update `DiagramNodeWidget` to detect drag gestures (`onPanUpdate`). [213d3a0]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Update `DiagramState` to handle node position updates during drag and ensure `ConnectionPainter` redraws. [213d3a0]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 1: Interactive Canvas Nodes' (Protocol in workflow.md)

## Phase 2: Comprehensive Asset Discovery
- [ ] Task: Implement `AssetScanner` utility to recursively find all `48.png` icons in `assets/aws/` and group them by category.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Refactor `ResourceSidebar` to build its UI dynamically based on the scanned `AssetScanner` catalog.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Comprehensive Asset Discovery' (Protocol in workflow.md)

## Phase 3: AI Model Control & Logs
- [ ] Task: Add a model selection dropdown to `RightSidebar` and update `AIModelState` to track the selected model.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Implement an "AI Logs" view in the `RightSidebar` to display detailed interaction histories.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 3: AI Model Control & Logs' (Protocol in workflow.md)