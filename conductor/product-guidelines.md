# Product Guidelines: Technical Architecture System

## 1. Visual Identity & Brand
- **Aesthetic:** Engineering Precision, Modern Minimalism, and Technical Utility.
- **Emotional Response:** Controlled authority, reliability, and low ocular fatigue.
- **Theme:** Dark-first approach using a **Deep Slate** foundation.

## 2. UI Principles
- **Grid System:** 4px base grid for mathematical precision.
- **Density:** High-density layouts are preferred. Padding within cards and panels should lean towards `sm` (8px) and `md` (16px).
- **Layout:** Hybrid-Fixed model (Sidebars: 280px, Canvas: Fluid/Infinite).
- **Depth:** Communicated through **Tonal Layering** and "Ghost Strokes" (semi-transparent borders) rather than heavy shadows.
- **Shapes:** Soft (4px radius) for components/nodes, 8px for large containers.

## 3. Colors (CloudFlow Palette)
- **Primary (Indigo):** #C0C1FF (High-priority actions, active points).
- **Secondary (Sky):** #7BD0FF (Information accents, selection highlights).
- **Surface:** #0B1326 (Base), #171F33 (Container), #2D3449 (Highest).
- **On-Surface:** #DAE2FD (Primary text), #C7C4D7 (Variant/Secondary text).
- **Status:** High-saturation semantic colors (Error: #FFB4AB).

## 4. Typography
- **Geist:** Primary typeface for all UI labels and headlines.
- **JetBrains Mono:** Monospace font for technical metadata, resource IDs, and code previews.
- **Hierarchy:** Tight leading for headlines to maintain vertical density.

## 5. Interaction
- **Stitch Design Adherence:** Implementation must faithfully follow the provided HTML/CSS mockups.
- **Desktop-First:** Optimized for mouse/keyboard with robust shortcuts and focus states.
- **Snappy Response:** UI must feel immediate; use optimistic updates for state changes.