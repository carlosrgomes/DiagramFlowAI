# Implementation Plan: Hierarchical Grouping & Professional Visuals

## Phase 1: Data Model & Parent-Child Logic [checkpoint: 82d904d]
- [x] Task: Update `DiagramNode` with `NodeType` enum and `parentId` field. Modify `DiagramState` to handle these properties. 89e8f77
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 1: Data Model' (Protocol in workflow.md) 82d904d

## Phase 2: Visual Overhaul (Groups & Resources) [checkpoint: d3f2a11]
- [x] Task: Refactor `DiagramNodeWidget` to support `NodeType.group` (transparent bounded box with header) and `NodeType.resource` (large icon, label below). 3a2e1f4
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 2: Visual Overhaul' (Protocol in workflow.md) d3f2a11

## Phase 3: Orthogonal Connection Routing
- [ ] Task: Update `ConnectionPainter` to calculate and draw orthogonal paths (with right angles) between anchor points instead of straight lines.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Orthogonal Connections' (Protocol in workflow.md)

## Phase 4: AI Generative Support
- [ ] Task: Update `AIEngineService` system prompt to support `GROUP:` commands and parent-child associations in `NODE:` commands. Update `RightSidebar` parsing logic.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 4: AI Generative Support' (Protocol in workflow.md)