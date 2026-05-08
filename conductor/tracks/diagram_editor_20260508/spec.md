# Track Specification: Implement Diagram Editor with Drag and Drop

## Goal
Build the core interactive diagramming experience, allowing users to drag cloud resources from a library sidebar and drop them onto an infinite canvas.

## Scope
- **Resource Library Sidebar:** A 280px left panel listing draggable resource types (e.g., Compute, Database, Network).
- **Infinite Canvas:** A main area utilizing `InteractiveViewer` to allow panning and zooming across a grid background.
- **Drag & Drop Engine:** 
  - Implement `Draggable` on sidebar items.
  - Implement `DragTarget` on the canvas to accept drops.
  - Calculate accurate local coordinates when a drop occurs.
- **State Management:** A simple in-memory state object (e.g., using `ChangeNotifier`) to hold a list of placed nodes and their coordinates.
- **Node Rendering:** Visual representation of placed nodes on the canvas, adhering to the "Technical Architecture System" guidelines (4px radius, Deep Slate surface, clear typography).

## Out of Scope
- Drawing connection lines between nodes (this will be a separate track).
- Persisting the diagram to a database or local file.
- Advanced node properties editing.