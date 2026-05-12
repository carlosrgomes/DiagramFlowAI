import 'dart:async';

/// Lightweight bus for sending a prompt from anywhere (gallery, shortcuts)
/// to the chat input in the right sidebar. The sidebar listens, fills the
/// input, and submits if the model is ready.
class PromptDispatcher {
  final _ctrl = StreamController<String>.broadcast();
  Stream<String> get prompts => _ctrl.stream;

  void dispatch(String prompt) => _ctrl.add(prompt);

  void dispose() => _ctrl.close();
}
