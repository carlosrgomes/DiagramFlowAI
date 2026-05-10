# Overview
This track focuses on stabilizing and modernizing the Mermaid engine integration within CloudFlow AI. It introduces a background AI agent (powered by Gemma 4) that acts as a "Proactive Suggester" to analyze diagrams and suggest architectural improvements. Additionally, it implements robust PNG export capabilities (with solid and transparent backgrounds) via Quick Actions in the UI.

# Functional Requirements
- **Mermaid Engine Robustness:** Implement error boundaries and safe parsing mechanisms to prevent application crashes when encountering invalid Mermaid syntax.
- **Background AI Specialist (Gemma 4):**
  - Implement a background service that evaluates the current Mermaid architecture state.
  - The agent must act as a "Proactive Suggester", identifying missing standard components or suggesting architectural best practices without interrupting the primary design flow.
- **PNG Export Quick Actions:**
  - Add explicit UI quick actions (menu items or buttons) to export the current diagram.
  - Provide two distinct export options: "Export as PNG (Solid Background)" and "Export as PNG (Transparent Background)".
- **Modernization:** Refactor related state management and UI components dealing with the Mermaid canvas to ensure they adhere to modern Flutter practices and the project's design tokens.

# Acceptance Criteria
- [ ] Invalid Mermaid syntax does not crash the application; errors are handled gracefully (e.g., displaying a visual error indicator on the canvas).
- [ ] The background AI agent successfully analyzes the diagram and provides at least one proactive suggestion in the UI based on the current architecture.
- [ ] Users can export a transparent PNG of the diagram via a quick action button.
- [ ] Users can export a solid background PNG of the diagram via a quick action button.

# Out of Scope
- Implementing other export formats (e.g., SVG, PDF) beyond PNG.
- Replacing Mermaid with a different rendering engine.