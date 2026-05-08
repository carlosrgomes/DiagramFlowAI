# Track Specification: High-Fidelity UI Refactor for Editor Canvas

## Goal
Transform the basic application shell and diagram canvas into a professional, high-fidelity UI that perfectly matches the provided reference screenshot (CloudFlow AI Studio).

## Scope
- **Top Navigation Bar:** Create a detailed header with the brand logo, primary navigation links (Canvas, Resources, etc.), a central tool palette (zoom, pan, share), and right-aligned user actions.
- **Left Sidebar (Cloud Library):** Refactor the resource sidebar to match the specific "DRAG RESOURCES" layout, incorporating the dark theme tokens, category headers, and specific resource buttons (EC2, S3, VPC, RDS).
- **Right Sidebar (Tools & Chat):** Introduce a two-panel right sidebar containing a "Mermaid Architecture" code view and a "Gemma4 AI Assistant" chat interface.
- **Main Canvas:** Adjust the canvas area to match the visual context (light/white background inside the dark shell, with a distinct grid and precise node styling mimicking the screenshot).
- **Footer:** Add a subtle footer showing connection status ("Gemma4 Connected | Engine: CloudFlow-v2.1") and basic links.

## Out of Scope
- Fully functional AI chat backend (mock UI only).
- Live generation of Mermaid code (mock UI only).
- Actual deployment flows.