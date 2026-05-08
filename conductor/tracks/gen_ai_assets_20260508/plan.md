# Implementation Plan: Generative AI & AWS Assets

## Phase 1: AWS Asset Management
- [ ] Task: Download and extract the official AWS Architecture Icons ZIP to the local `assets/` folder.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Update `pubspec.yaml` to include the new image assets and create an `AssetManager` utility to load them.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Refactor `DiagramNodeWidget` and `ResourceSidebar` to render the official AWS icons instead of Material icons.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 1: AWS Asset Management' (Protocol in workflow.md)

## Phase 2: AI Model Download Manager
- [ ] Task: Implement a download button and progress indicator in the `RightSidebar` chat section for the Gemma 4 model.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Implement mock download logic and state management for model readiness.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 2: AI Model Download Manager' (Protocol in workflow.md)

## Phase 3: Generative Diagramming
- [ ] Task: Create an `AIEngineService` that parses natural language chat input into architectural commands (e.g., mapping text to Node creations).
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Connect the chat input field to the `AIEngineService` and trigger `DiagramState.addNode` automatically.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Generative Diagramming' (Protocol in workflow.md)