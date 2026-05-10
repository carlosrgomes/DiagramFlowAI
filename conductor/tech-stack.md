# Technology Stack

## Core Language & Framework
- **Dart:** Primary programming language.
- **Flutter:** Cross-platform framework targeting Windows, macOS, and Linux desktop environments.

## UI Architecture
- **Navigation Shell:** Uses a stateful `AppShell` with a `NavigationRail` for desktop-optimized sidebar navigation.
- **Design Tokens:** Centralized theme management in `lib/theme/design_tokens.dart` implementing the "Technical Architecture System".
- **Typography:** Integration of **Geist** and **JetBrains Mono** font families.
- **State Management:** (Pending selection - e.g., Provider/Riverpod) for authentication and project state.
- **Data Model:** Structured representation of nodes and groups in `DiagramNode` and `DiagramState`, with automated Mermaid code generation.

## Development Tools
- **IDE:** VS Code or Android Studio with Flutter extensions.
- **Design Integration:** Stitch extension for syncing designs.

## Testing & Quality Assurance
- **Unit & Widget Testing:** Flutter's built-in `test` and `flutter_test` packages.
- **Integration Testing:** `integration_test` package for end-to-end testing on desktop platforms.

## Dependency Management
- **Pub:** Dart's official package manager.