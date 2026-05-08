# Implementation Plan: High-Fidelity UI Refactor

## Phase 1: Layout Skeleton & Header
- [x] Task: Restructure `AppShell` to include Header, Footer, and a 3-column body (Left Sidebar, Canvas, Right Sidebar). [d8ccffc]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Create `TopNavBar` widget matching the reference design (branding, nav links, central toolbar, user profile). [6063892]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 1: Layout Skeleton & Header' (Protocol in workflow.md)

## Phase 2: Left Sidebar Refactor [checkpoint: f92bcba]
- [x] Task: Refactor `ResourceSidebar` to match the "Cloud Library" and "DRAG RESOURCES" sections precisely. [f92bcba]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Update draggable items to use the custom dark-themed buttons shown in the reference. [f92bcba]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 2: Left Sidebar Refactor' (Protocol in workflow.md)

## Phase 3: Canvas & Right Sidebar [checkpoint: 2c7e5ac]
- [x] Task: Adjust `DiagramCanvas` visual styling (background color, grid pattern) to match the reference screenshot. [2c7e5ac]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Create `RightSidebar` widget containing 'Mermaid Architecture' code view and 'Gemma4 AI Assistant' chat view. [af37886]
    - [x] Write Tests
    - [x] Implement Feature
- [x] Task: Conductor - User Manual Verification 'Phase 3: Canvas & Right Sidebar' (Protocol in workflow.md)