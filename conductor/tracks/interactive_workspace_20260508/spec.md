# Track Specification: Interactive Workspace & Model Control

## Goal
Provide full interactive control over the architecture canvas (moving nodes), expose the complete AWS resource library, and implement AI model management (selection and logging).

## Scope
- **Interactive Canvas Nodes:**
    - Wrap `DiagramNodeWidget` in a `GestureDetector` or `Draggable` (positioned on the canvas) to allow repositioning of already placed nodes.
    - Ensure connections (arrows) update dynamically as nodes move.
- **Comprehensive Asset Library:**
    - Write a script/logic to scan the `assets/aws` directory recursively and extract all PNG icons.
    - Dynamically build the `ResourceSidebar` UI using these discovered icons, categorized by their folder paths (e.g., Database, Compute).
- **AI Model Control:**
    - Add a ComboBox (Dropdown) to the `RightSidebar` to select between available AI models (e.g., Gemma4-2b, Gemma4-7b, GPT-4 Mock).
    - Introduce an "AI Logs" view in the `RightSidebar` to display the raw prompt/response JSON or text for debugging and transparency.

## Out of Scope
- Actually integrating real multiple local models (we will mock the selection state).
- Connecting nodes manually with the mouse (this remains out of scope for *this* track; nodes are moved, arrows follow AI creation).