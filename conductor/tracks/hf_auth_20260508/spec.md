# Track Specification: Hugging Face Token Authentication

## Goal
Resolve the HTTP 401 Unauthorized error during model download by allowing the user to input a Hugging Face 'Read' token, which is required for downloading gated models like Gemma 4.

## Scope
- **UI Updates:**
    - Add a `TextField` for the Hugging Face Token in the `RightSidebar` (only visible when the model is not downloaded or in error state).
- **State Management:**
    - Update `AIModelState` to accept and store the `huggingFaceToken`.
- **Initialization Update:**
    - Re-initialize `FlutterGemma` with the provided token before attempting the model installation.

## Out of Scope
- Persistent secure storage of the token (Keychain/Keystore) is out of scope for this quick integration track; the token will remain in memory for the session.