# Track Specification: Generative AI & Official Cloud Assets

## Goal
Elevate the application to a professional standard by integrating a local generative AI model (Gemma 4) for automated diagram creation and importing official AWS architecture icons for high-fidelity rendering.

## Scope
- **AWS Assets Integration:**
    - Download the official AWS Architecture Icons ZIP file from the provided URL.
    - Extract and organize the relevant SVG/PNG assets into the project's `assets/` directory.
    - Update `DiagramNodeWidget` and `ResourceSidebar` to utilize these official icons instead of generic Material icons.
- **AI Model Manager:**
    - Implement a UI within the `RightSidebar` chat interface to allow users to trigger the download of the Gemma 4 model.
    - Add a mock download progress indicator.
- **Generative Design Engine:**
    - Implement the logic to parse user chat commands (e.g., "add an EC2 instance") and automatically update the `DiagramState` by adding nodes to the canvas.
    - Integrate the chat interface with the `DiagramState` to allow the AI to directly draw on the canvas.

## Out of Scope
- Actually compiling and running a local LLM inference engine in Dart (we will use a simulated backend service or mock logic for the prompt parsing to demonstrate the UX and state updates).
- Importing Azure or GCP icons (focusing only on AWS for this track).