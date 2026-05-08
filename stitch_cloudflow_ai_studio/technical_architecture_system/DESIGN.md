---
name: Technical Architecture System
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c7c4d7'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#908fa0'
  outline-variant: '#464554'
  surface-tint: '#c0c1ff'
  primary: '#c0c1ff'
  on-primary: '#1000a9'
  primary-container: '#8083ff'
  on-primary-container: '#0d0096'
  inverse-primary: '#494bd6'
  secondary: '#7bd0ff'
  on-secondary: '#00354a'
  secondary-container: '#00a6e0'
  on-secondary-container: '#00374d'
  tertiary: '#ffb783'
  on-tertiary: '#4f2500'
  tertiary-container: '#d97721'
  on-tertiary-container: '#452000'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2f2ebe'
  secondary-fixed: '#c4e7ff'
  secondary-fixed-dim: '#7bd0ff'
  on-secondary-fixed: '#001e2c'
  on-secondary-fixed-variant: '#004c69'
  tertiary-fixed: '#ffdcc5'
  tertiary-fixed-dim: '#ffb783'
  on-tertiary-fixed: '#301400'
  on-tertiary-fixed-variant: '#703700'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  h1:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  h2:
    fontFamily: Geist
    fontSize: 18px
    fontWeight: '600'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  code:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Geist
    fontSize: 11px
    fontWeight: '700'
    lineHeight: '1.0'
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  gutter: 16px
  sidebar_width: 280px
  toolbar_height: 56px
---

## Brand & Style

The visual identity of this design system is rooted in **Engineering Precision**. It is designed for architects and engineers who require a high-density, low-friction environment for complex cognitive tasks. The aesthetic merges **Modern Minimalism** with a **Technical Utility** layer, ensuring that the interface never competes with the user's diagrams.

The emotional response is one of controlled authority and reliability. By utilizing a dark-first approach, the system minimizes ocular fatigue during extended deep-work sessions. The UI relies on structured logic, high-contrast functional elements, and a sophisticated "blueprint" feel that honors the architectural nature of the content.

## Colors

This design system utilizes a **Deep Slate** foundation to create a "void" workspace where architectural components can stand out. The palette is strictly categorized to maintain technical clarity:

- **Primary (Indigo):** Reserved exclusively for high-priority actions, primary states, and active connection points.
- **Secondary (Sky):** Used for informational accents, selection highlights, and secondary data visualizations.
- **Surface & Stroke:** A hierarchy of cool grays (Slate) defines depth. Surfaces move from the base (#0F172A) to elevated cards (#1E293B), while strokes (#334155) provide the architectural skeleton.
- **Status:** Standardized semantic colors (Red for errors, Amber for warnings, Emerald for healthy states) must be used with high saturation to remain accessible against the dark background.

## Typography

The typography system prioritizes **legibility and density**. We use **Geist** for its neutral, humanist-grotesque qualities which excel in technical SaaS environments. 

- **Hierarchy:** Use tight leading for headlines to keep vertical space compact. 
- **Monospace Integration:** **JetBrains Mono** is utilized for technical metadata, resource IDs, and coordinate values to distinguish data from UI labels.
- **Micro-copy:** Labels for sidebar panels and tooltips should use `label-caps` for clear categorization at small scales.

## Layout & Spacing

This design system employs a **4px base grid** to ensure mathematical precision in element alignment. The layout follows a **Hybrid-Fixed model**: 

- **Canvas:** A fluid, infinite-canvas area for diagramming.
- **Sidebars:** Fixed-width utility panels (280px) for resource browsers and property inspectors.
- **Density:** High-density layouts are preferred. Padding within cards and panels should lean towards the `sm` (8px) and `md` (16px) tokens to maximize the information visible on a single screen.
- **Margins:** Use `lg` (24px) for major container separation to prevent visual clutter in data-heavy views.

## Elevation & Depth

In a dark mode technical environment, depth is communicated through **Tonal Layering** rather than heavy shadows.

- **Level 0 (Background):** Deep Slate (#0F172A). The primary workspace.
- **Level 1 (Panels):** Slate (#1E293B) with a subtle 1px border (#334155).
- **Level 2 (Cards/Modals):** Elevated surfaces that use a "Ghost Stroke"—a semi-transparent white border (5-10% opacity) to catch the "light" and define edges.
- **Shadows:** Use a single, tight ambient shadow (0px 4px 12px rgba(0,0,0,0.5)) only for floating menus or modals to separate them from the primary canvas.

## Shapes

The shape language is **Soft (0.25rem)**, striking a balance between modern friendliness and professional rigidity.

- **Components:** Buttons, inputs, and tags use the `base` (4px) radius. 
- **Large Containers:** Content cards or main sidebar containers use `rounded-lg` (8px) to provide a distinct structural frame.
- **Interactive Nodes:** Diagram nodes should maintain the 4px radius to ensure they feel like solid, architectural components rather than organic shapes.

## Components

### Buttons
- **Primary:** Solid Indigo background with white text. No gradient.
- **Secondary:** Transparent background with a 1px Slate stroke (#334155). 
- **Ghost:** No border or background until hover; used for canvas tools.

### Cards
- Cards are the primary vessel for resource properties. They should feature a header with a `label-caps` title and use 1px dividers to separate data groups.

### Inputs
- Fields must use a dark fill (slightly darker than the surface they sit on) with a persistent 1px stroke. The stroke shifts to Indigo on focus.

### Chips & Tags
- Used for cloud resource types (e.g., "AWS", "Active"). These use a low-opacity background tint of the semantic color with a high-contrast text label.

### The Canvas Toolbar
- A floating or docked horizontal bar using a glassmorphism effect (backdrop-blur: 12px) to allow the diagram to be partially visible beneath it, emphasizing the "infinite" nature of the workspace.

### Checkboxes & Radios
- These should be oversized slightly (18px) to ensure easy targeting on high-resolution displays, using Indigo for the selected state.