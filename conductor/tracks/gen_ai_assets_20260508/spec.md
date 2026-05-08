# Track Specification: Generative AI, Complete Assets, Connections & Export

## Goal
Elevate the application to a professional standard by integrating a local generative AI model (Gemma 4) with a transparent "thought process", importing the *entire* official AWS architecture icons library (categorized), adding connection lines drawing, and supporting metadata export.

## Scope
- **AWS Assets Integration (Comprehensive):**
    - Process all SVG/PNG assets from the downloaded official AWS Architecture Icons ZIP.
    - Dynamically categorize and list all available resources in the `ResourceSidebar`.
    - Support rendering any dragged AWS icon on the canvas.
- **Generative Design Engine (Advanced):**
    - Implement stream-based parsing in `AIEngineService` to handle multi-resource generation from a single prompt.
    - Display the AI's "thought process" (reasoning steps) clearly in the chat UI before drawing the diagram.
    - Generate complete diagrams with nodes and lines automatically.
- **Connection Lines:**
    - Allow users to visually draw connections (arrows/lines) between nodes on the canvas.
    - Maintain connection references in `DiagramState`.
- **Metadata Export:**
    - Implement a JSON export feature that saves the current `DiagramState` (nodes, positions, connections) to a file.

## Out of Scope
- Actually compiling and running a local LLM inference engine in Dart (simulated via an advanced stream-based mock service).
- Auto-layout algorithms for perfectly routing complex overlapping lines (simple direct lines will suffice for now).