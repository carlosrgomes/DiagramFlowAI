# Track Specification: Advanced Connection Anchors and Edge Routing

## Goal
Improve the visual clarity of the diagram by preventing connection lines from overlapping node graphics, and provide users with interactive control over where connections start and end on a node.

## Scope
- **Anchor Data Model:**
    - Extend the `DiagramConnection` model to include `fromAnchor` and `toAnchor` identifiers (e.g., Top, Bottom, Left, Right).
- **Interactive Node Handles:**
    - Update the `DiagramNodeWidget` to display interactive anchor points (small visual handles on the borders) when hovered or selected.
    - Allow users to drag a connection from an anchor point on one node to an anchor point on another.
- **Precision Edge Routing:**
    - Refactor `ConnectionPainter` to calculate paths that begin and terminate exactly at the specified anchor positions on the node's perimeter, rather than blindly drawing center-to-center.
    - Draw a clean arrow head exactly at the edge of the destination node.
- **AI Integration Updates:**
    - Update `AIEngineService` so that when it generates connections automatically, it assigns sensible default anchors (e.g., connecting the Right anchor of the source to the Left anchor of the destination).

## Out of Scope
- Orthogonal or Manhattan routing algorithms (lines will remain straight direct vectors for now, just starting/ending at borders).
- Complex collision avoidance algorithms.