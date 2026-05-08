import 'package:flutter_gemma/flutter_gemma.dart';

class AIEngineService {
  Stream<ModelResponse> processPrompt(String prompt, InferenceChat session) async* {
    await session.addQueryChunk(Message.text(text: prompt, isUser: true));
    yield* session.generateChatResponseAsync();
  }
}
