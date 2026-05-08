# Implementation Plan: Diagram Editor

## Phase 1: State & Canvas Foundation
- [x] Task: Create `DiagramState` class to manage a list of nodes and their coordinates. [0ff8d19]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Implement `DiagramCanvas` widget using `InteractiveViewer` with a custom grid background. [9cc0946]
    - [x] Write Tests
    - [x] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 1: State & Canvas Foundation' (Protocol in workflow.md)

## Phase 2: Resource Library & Draggables
- [ ] Task: Create `ResourceSidebar` widget containing categorised dummy resources.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Wrap sidebar items in `LongPressDraggable` to initiate drag events.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Resource Library & Draggables' (Protocol in workflow.md)

## Phase 3: Drop Mechanics & Rendering
- [ ] Task: Wrap `DiagramCanvas` in a `DragTarget` and handle `onAcceptWithDetails` to calculate drop coordinates.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Create `DiagramNode` widget to render placed items using a `Stack` and `Positioned`.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Drop Mechanics & Rendering' (Protocol in workflow.md)