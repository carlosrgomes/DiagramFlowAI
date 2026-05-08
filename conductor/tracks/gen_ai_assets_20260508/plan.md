# Implementation Plan: Generative AI & AWS Assets

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
- [x] Task: Conductor - User Manual Verification 'Phase 3: Generative Diagramming' (Protocol in workflow.md)