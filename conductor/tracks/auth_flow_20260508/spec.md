# Track Specification: Implement Authentication Flow and Login Screen

## Goal
Implement a functional login screen and basic authentication state management, adhering to the CloudFlow AI "Technical Architecture System" design.

## Scope
- Integrate Geist and JetBrains Mono fonts.
- Update `lib/theme/design_tokens.dart` with the full Technical Architecture System palette.
- Create a reusable `BrandLogo` component.
- Implement the `LoginScreen` widget with:
    - Email and Password fields.
    - Social Login buttons (Google, GitHub).
    - Basic field validation.
- Implement a simple `AuthService` and `AuthState` (mocking the actual auth process).
- Update `MainShell` to handle navigation between Login and Dashboard.

## Out of Scope
- Actual OAuth integration with Google/GitHub providers.
- Real backend user registration.
- Password recovery flow (UI only placeholder).