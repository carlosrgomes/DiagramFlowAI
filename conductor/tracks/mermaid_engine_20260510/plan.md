# Implementation Plan

## Phase 1: Foundation & Modernization
- [ ] Task: Create tests for robust Mermaid syntax parsing and error handling in diagram state.
- [ ] Task: Implement error boundaries and safe parsing in `diagram_state.dart` and `diagram_canvas.dart` (Green Phase).
- [ ] Task: Refactor legacy canvas state management to modernize the implementation (Refactor Phase).
- [ ] Task: Conductor - User Manual Verification 'Foundation & Modernization' (Protocol in workflow.md)

## Phase 2: Background AI Agent (Gemma 4)
- [ ] Task: Create tests for the background AI suggestion service logic.
- [ ] Task: Implement background service integrating with `ai_engine_service.dart` to analyze diagram state.
- [ ] Task: Implement "Proactive Suggester" logic to map AI analysis to actionable UI suggestions.
- [ ] Task: Conductor - User Manual Verification 'Background AI Agent (Gemma 4)' (Protocol in workflow.md)

## Phase 3: UI Quick Actions & PNG Export
- [ ] Task: Create tests for PNG export functions (solid and transparent backgrounds).
- [ ] Task: Implement export logic leveraging Mermaid's rendering capabilities to output PNG data.
- [ ] Task: Add Quick Action buttons/menu items in `top_nav_bar.dart` or `app_shell.dart` for the export options.
- [ ] Task: Conductor - User Manual Verification 'UI Quick Actions & PNG Export' (Protocol in workflow.md)

## Phase 4: Integration & Polish
- [ ] Task: Integrate proactive AI suggestions into the primary UI flow without interrupting design.
- [ ] Task: Conduct end-to-end integration testing of the robust canvas, AI suggestions, and export flow.
- [ ] Task: Conductor - User Manual Verification 'Integration & Polish' (Protocol in workflow.md)