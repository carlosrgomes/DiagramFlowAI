# Track Specification: High-Fidelity Hierarchical Grouping & Professional Visuals

## Goal
Elevate the diagram editor to support professional AWS architectural standards as demonstrated in official AWS reference architectures. This includes supporting container nodes (e.g., VPCs, Subnets, AWS Accounts), orthogonal connection routing, and large-format icons with labels underneath.

## Scope
- **Data Model Extensions:**
    - Update `DiagramNode` to include a `type` property (e.g., `NodeType.resource`, `NodeType.group`).
    - Add a `parentId` property to `DiagramNode` to establish hierarchical containment.
- **Visual Overhaul (Nodes):**
    - Refactor `DiagramNodeWidget` to render `group` nodes as transparent, bordered containers with a header (AWS logo + label).
    - Refactor `resource` nodes to display a large, crisp icon with the text label positioned below it, removing the current pill-shaped dark background.
- **Orthogonal Connection Routing:**
    - Update `ConnectionPainter` to draw orthogonal (right-angled) paths between nodes and groups, replacing the current direct point-to-point lines.
- **AI Prompt Engineering:**
    - Update `AIEngineService` system instructions to understand and generate groups using a new command syntax (e.g., `GROUP:LABEL@X,Y,W,H@ID`).
    - Instruct the model to nest resources by appending parent IDs to the `NODE` command (e.g., `NODE:EC2@X,Y@ID@PARENT_ID`).

## Out of Scope
- Automatic layout algorithms (Auto-arranging nested elements automatically).
- Interactive drag-and-drop to *change* a node's parent (nodes will be placed freely; parent assignment is handled by the AI or initial placement logic for now).