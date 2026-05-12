import 'package:flutter_gemma/flutter_gemma.dart';

sealed class StreamChunk {
  const StreamChunk();
}

class TextChunk extends StreamChunk {
  final String token;
  const TextChunk(this.token);
}

class ThinkChunk extends StreamChunk {
  final String content;
  const ThinkChunk(this.content);
}

class AIEngineService {
  Stream<StreamChunk> streamResponse(InferenceChat chat, String prompt) async* {
    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        yield TextChunk(response.token);
      } else if (response is ThinkingResponse) {
        yield ThinkChunk(response.content);
      }
    }
  }
}
