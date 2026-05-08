# Implementation Plan: High-Fidelity UI Refactor

## Phase 1: Layout Skeleton & Header
- [x] Task: Restructure `AppShell` to include Header, Footer, and a 3-column body (Left Sidebar, Canvas, Right Sidebar). [d8ccffc]
    - [x] Write Tests
    - [x] Implement Feature
- [ ] Task: Create `TopNavBar` widget matching the reference design (branding, nav links, central toolbar, user profile).
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Layout Skeleton & Header' (Protocol in workflow.md)

## Phase 2: Left Sidebar Refactor
- [ ] Task: Refactor `ResourceSidebar` to match the "Cloud Library" and "DRAG RESOURCES" sections precisely.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Update draggable items to use the custom dark-themed buttons shown in the reference.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Left Sidebar Refactor' (Protocol in workflow.md)

## Phase 3: Canvas & Right Sidebar
- [ ] Task: Adjust `DiagramCanvas` visual styling (background color, grid pattern) to match the reference screenshot.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Create `RightSidebar` widget containing 'Mermaid Architecture' code view and 'Gemma4 AI Assistant' chat view.
    - [ ] Write Tests
    - [ ] Implement Feature
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Canvas & Right Sidebar' (Protocol in workflow.md)