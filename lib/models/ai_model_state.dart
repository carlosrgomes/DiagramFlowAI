import 'package:flutter/material.dart';

enum AIModelStatus {
  notDownloaded,
  downloading,
  ready,
}

class ChatMessage {
  final String text;
  final bool isAI;

  ChatMessage({required this.text, required this.isAI});
}

class AIModelState extends ChangeNotifier {
  AIModelStatus _status = AIModelStatus.notDownloaded;
  double _downloadProgress = 0.0;
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'I\'ve generated the base VPC and added two EC2 instances behind an ALB. Would you like me to add a Redis cache cluster next to the RDS?',
      isAI: true,
    ),
  ];

  AIModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> startDownload() async {
    if (_status != AIModelStatus.notDownloaded) return;

    _status = AIModelStatus.downloading;
    _downloadProgress = 0.0;
    notifyListeners();

    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      _downloadProgress = i / 100.0;
      notifyListeners();
    }

    _status = AIModelStatus.ready;
    _messages.add(ChatMessage(text: 'Gemma4 model is ready! How can I help you with your architecture today?', isAI: true));
    notifyListeners();
  }

  void addMessage(String text, bool isAI) {
    _messages.add(ChatMessage(text: text, isAI: isAI));
    notifyListeners();
  }
}
