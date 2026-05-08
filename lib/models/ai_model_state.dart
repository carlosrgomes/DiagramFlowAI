import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'dart:developer' as dev;

enum AIModelStatus {
  notDownloaded,
  downloading,
  ready,
  error,
}

enum MessageType {
  user,
  ai,
  thought,
}

class ChatMessage {
  String text;
  final MessageType type;
  final String? rawLog;

  ChatMessage({required this.text, required this.type, this.rawLog});
  
  bool get isAI => type == MessageType.ai;
  bool get isThought => type == MessageType.thought;
}

class AIModelState extends ChangeNotifier {
  AIModelStatus _status = AIModelStatus.notDownloaded;
  double _downloadProgress = 0.0;
  String _selectedModel = 'Gemma4-2b';
  String? _errorMessage;
  String? _huggingFaceToken;
  
  InferenceChat? _chatSession;

  final List<String> availableModels = ['Gemma4-2b', 'Gemma4-7b', 'Claude-3-Opus', 'GPT-4-Turbo'];

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am your local Gemma4 assistant. Download the model to start building architectures.',
      type: MessageType.ai,
    ),
  ];

  AIModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  String get selectedModel => _selectedModel;
  String? get errorMessage => _errorMessage;
  String? get huggingFaceToken => _huggingFaceToken;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  InferenceChat? get chatSession => _chatSession;

  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  void setToken(String token) {
    _huggingFaceToken = token;
    notifyListeners();
  }

  Future<void> startDownload() async {
    if (_status == AIModelStatus.downloading) return;

    _status = AIModelStatus.downloading;
    _errorMessage = null;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      dev.log('Initializing FlutterGemma with token...');
      await FlutterGemma.initialize(huggingFaceToken: _huggingFaceToken);

      dev.log('Starting model installation for Gemma 4...');
      
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
      ).fromNetwork(
        'https://huggingface.co/google/gemma-2-2b-it-gpu-int8.task',
      ).withProgress((progress) {
        _downloadProgress = progress / 100.0;
        notifyListeners();
      }).install();

      const systemInstruction = """
You are an AWS Cloud Architecture expert assistant.
When asked to draw or add resources, you must include specific structured commands in your response text:
1. To add a node: NODE:LABEL@X,Y@ID (e.g. NODE:EC2@300,200@node_123)
2. To add a connection: CONN:FROM_ID->TO_ID (e.g. CONN:node_123->node_456)

Valid labels: EC2, S3, RDS, VPC, Lambda, EKS, Route53, DynamoDB, Autoscaling, EBS, CloudFront.
Generate realistic coordinates (range 0-1000).
Show your thinking process before providing the commands.
""";

      final model = await FlutterGemma.getActiveModel();
      _chatSession = await model.createChat(
        isThinking: true,
        systemInstruction: systemInstruction,
      );

      _status = AIModelStatus.ready;
      _messages.add(ChatMessage(
        text: 'Gemma4 local engine initialized and ready!', 
        type: MessageType.ai,
      ));
    } catch (e) {
      dev.log('Failed to initialize Gemma engine: $e');
      _status = AIModelStatus.error;
      _errorMessage = e.toString();
      _messages.add(ChatMessage(
        text: 'Error: $e. Please ensure your token is valid and you have accepted the model terms at hf.co.', 
        type: MessageType.ai,
      ));
    }
    notifyListeners();
  }

  void addMessage(String text, MessageType type, {String? rawLog}) {
    if (_messages.isNotEmpty && 
        _messages.last.type == type && 
        (type == MessageType.ai || type == MessageType.thought)) {
      _messages.last.text += text;
    } else {
      _messages.add(ChatMessage(text: text, type: type, rawLog: rawLog));
    }
    notifyListeners();
  }

  void clearThoughts() {
    _messages.removeWhere((m) => m.type == MessageType.thought);
    notifyListeners();
  }
}
