# Track Specification: Real Local Gemma 4 Integration via LiteRT

## Goal
Replace the simulated AI engine with a genuine local integration of the Gemma 4 model using the `flutter_gemma` package and the LiteRT-LM runtime.

## Scope
- **Dependency & Native Configuration:**
    - Add `flutter_gemma` to `pubspec.yaml`.
    - Configure the `macos/Podfile` with the necessary `-lGemmaModelConstraintProvider` linker flags for the FFI engine.
- **Engine Initialization:**
    - Update `AIModelState` to handle the actual initialization of `FlutterGemma.instance` using a local `.litertlm` file.
    - Provide a mechanism (or mock the download path) to locate the model file on the user's desktop.
- **Real Inference & Streaming:**
    - Refactor `AIEngineService` to call `FlutterGemma.instance.getResponseStream()`.
    - Configure the `ConversationConfig` to enable both `"thought"` and `"response"` channels.
    - Parse the real output from the model to identify node additions and connections (using structured prompting or tool calling).
- **UI Updates:**
    - Ensure the `RightSidebar` correctly displays the distinct thought and response channels as they stream from the local engine.

## Out of Scope
- Hosting the actual 2GB+ model file in the git repository (the app will expect it in a specific local path or mock the file presence for testing).
- Multi-modal capabilities (vision/audio) in this specific track.