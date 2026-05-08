# Implementation Plan: Generative AI, Assets, Connections & Export

## Phase 1: AWS Asset Management [checkpoint: f50bef1]
- [x] Task: Download and extract the official AWS Architecture Icons ZIP to the local `assets/` folder. [f50bef1]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Update `pubspec.yaml` to include the new image assets and create an `AssetManager` utility to load them. [f50bef1]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Refactor `DiagramNodeWidget` and `ResourceSidebar` to render the official AWS icons instead of Material icons. [f50bef1]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 1: AWS Asset Management' (Protocol in workflow.md)

## Phase 2: AI Model Download Manager [checkpoint: e9fc511]
- [x] Task: Implement a download button and progress indicator in the `RightSidebar` chat section for the Gemma 4 model. [e9fc511]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Implement mock download logic and state management for model readiness. [e9fc511]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 2: AI Model Download Manager' (Protocol in workflow.md)

## Phase 3: Generative Diagramming [checkpoint: add9da4]
- [x] Task: Create an `AIEngineService` that parses natural language chat input into architectural commands (e.g., mapping text to Node creations). [add9da4]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Connect the chat input field to the `AIEngineService` and trigger `DiagramState.addNode` automatically. [add9da4]
    - [x] Write Tests
    - [x] Implement Feature
- [~] Task: Refactor `AIEngineService` and UI to support stream-based "thought process" and multi-resource parsing.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Generative Diagramming' (Protocol in workflow.md)

## Phase 4: Comprehensive AWS Assets
- [~] Task: Refactor `AssetManager` and `ResourceSidebar` to dynamically load and categorize all extracted AWS icons.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Comprehensive AWS Assets' (Protocol in workflow.md)

## Phase 5: Connection Lines
- [~] Task: Extend `DiagramState` to support connection edges between nodes.
    - [ ] Write Tests
    - [ ] Implement Feature
- [~] Task: Implement interactive line drawing on `DiagramCanvas` using `CustomPaint`.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 5: Connection Lines' (Protocol in workflow.md)

## Phase 6: Metadata Export
- [ ] Task: Implement JSON serialization for `DiagramState` (nodes and connections).
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Connect the "Export" button in `TopNavBar` to save the JSON file to disk.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 6: Metadata Export' (Protocol in workflow.md)