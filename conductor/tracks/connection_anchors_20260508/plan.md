# Implementation Plan: Advanced Connection Anchors and Edge Routing
## Phase 1: Anchor Data Model & Painter Update [checkpoint: d8672c8]
- [x] Task: Create `NodeAnchor` enum and update `DiagramConnection` to store `fromAnchor` and `toAnchor` properties. [d8672c8]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Refactor `ConnectionPainter` to calculate line coordinates based on anchor positions at the borders of the `DiagramNodeWidget`, ensuring arrows do not overlap the node graphic. [d8672c8]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 1: Anchor Data Model & Painter Update' (Protocol in workflow.md)

## Phase 2: Interactive Anchor Handles
- [~] Task: Update `DiagramNodeWidget` to render interactive, draggable anchor handles (Top, Bottom, Left, Right).
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Implement logic in `DiagramCanvas` to handle dragging from an anchor handle to create or modify a connection in `DiagramState`.
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Interactive Anchor Handles' (Protocol in workflow.md)

## Phase 3: AI Logic Sync
- [ ] Task: Update `AIEngineService` to generate connections with sensible default anchor points (e.g., Left-to-Right layout).
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 3: AI Logic Sync' (Protocol in workflow.md)