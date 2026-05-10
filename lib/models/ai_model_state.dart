import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'ai_engine_service.dart';
import 'diagram_state.dart';
import 'diagram_node.dart';

enum AIModelStatus { idle, downloading, initializing, ready, error }

enum MessageType { user, ai }

class ChatMessage {
  String text;
  final MessageType type;
  final String? rawLog;

  ChatMessage({required this.text, required this.type, this.rawLog});

  bool get isAI => type == MessageType.ai;
}

class GemmaModelConfig {
  final String name;
  final String url;
  final String filename;
  final ModelType modelType;
  final ModelFileType fileType;
  final bool needsAuth;
  final int maxTokens;

  const GemmaModelConfig({
    required this.name,
    required this.url,
    required this.filename,
    required this.modelType,
    required this.fileType,
    this.needsAuth = false,
    this.maxTokens = 2048,
  });
}

const gemmaModels = [
  GemmaModelConfig(
    name: 'Gemma 4 · 2B (no auth)',
    url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    filename: 'gemma-4-E2B-it.litertlm',
    modelType: ModelType.gemma4,
    fileType: ModelFileType.litertlm,
    needsAuth: false,
    maxTokens: 4096,
  ),
  GemmaModelConfig(
    name: 'Gemma 4 · 4B (no auth)',
    url: 'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
    filename: 'gemma-4-E4B-it.litertlm',
    modelType: ModelType.gemma4,
    fileType: ModelFileType.litertlm,
    needsAuth: false,
    maxTokens: 4096,
  ),
  GemmaModelConfig(
    name: 'Gemma 3 · 1B (auth required)',
    url: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm',
    filename: 'gemma3-1b-it.litertlm',
    modelType: ModelType.gemmaIt,
    fileType: ModelFileType.litertlm,
    needsAuth: true,
    maxTokens: 1024,
  ),
];

const _systemPrompt =
    'You are a cloud architecture diagram assistant.\n'
    'When asked to draw or modify a diagram, output ONLY structured commands — no markdown fences, no prose, no explanations.\n\n'
    'COMMAND SYNTAX:\n'
    'NODE:LABEL@ID@PARENT_ID@ICON_PATH\n'
    'GROUP:LABEL@ID@PARENT_ID\n'
    'EDGE:FROM_ID@TO_ID@LABEL\n\n'
    'Example for a VPC with a Subnet and an EC2:\n'
    'GROUP:Production VPC@vpc1@null\n'
    'GROUP:Public Subnet@subnet1@vpc1\n'
    'NODE:Web Server@ec2_1@subnet1@assets/aws/Res_Compute/Res_Amazon-EC2_48.png\n'
    'EDGE:internet@ec2_1@HTTP\n\n'
    'When the user message includes "Current state:", you MUST read it and return the FULL updated set of commands. Keep all existing entities unless told to remove them.\n'
    'Use official AWS icon paths from the catalog when possible.\n'
    'For conversational questions respond normally without any commands.';


class AIModelState extends ChangeNotifier {
  final _engine = AIEngineService();

  AIModelStatus _status = AIModelStatus.idle;
  int _selectedModelIndex = 0;

  static const _kCacheFile = 'gemma_model_index.txt';
  double _downloadProgress = 0.0;
  String? _errorMessage;
  String _hfToken = '';

  InferenceChat? _chat;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Select a Gemma model and press Download to start.',
      type: MessageType.ai,
    ),
  ];

  final List<Map<String, String>> _history = [];

  AIModelStatus get status => _status;
  int get selectedModelIndex => _selectedModelIndex;
  GemmaModelConfig get selectedModel => gemmaModels[_selectedModelIndex];
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  String get hfToken => _hfToken;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isReady => _status == AIModelStatus.ready;

  void setSelectedModel(int index) {
    if (_status == AIModelStatus.downloading || _status == AIModelStatus.initializing) return;
    _selectedModelIndex = index;
    _status = AIModelStatus.idle;
    _chat = null;
    notifyListeners();
  }

  void setToken(String token) {
    _hfToken = token.trim();
    notifyListeners();
  }

  Future<void> downloadAndLoad() async {
    if (_status == AIModelStatus.downloading || _status == AIModelStatus.initializing) return;

    try {
      await FlutterGemma.initialize();
    } catch (e) {
      dev.log('[FlutterGemma] re-initialize: $e');
    }

    final model = selectedModel;
    if (model.needsAuth && _hfToken.isEmpty) {
      _errorMessage = 'This model requires a Hugging Face token.';
      _status = AIModelStatus.error;
      notifyListeners();
      return;
    }

    _status = AIModelStatus.downloading;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final installer = FlutterGemma.installModel(
        modelType: model.modelType,
        fileType: model.fileType,
      );

      final token = model.needsAuth ? _hfToken : null;

      await installer
          .fromNetwork(model.url, token: token)
          .withProgress((p) {
            _downloadProgress = p.toDouble();
            notifyListeners();
          })
          .install();

      _status = AIModelStatus.initializing;
      notifyListeners();

      final inferenceModel = await FlutterGemma.getActiveModel(
        maxTokens: model.maxTokens,
        preferredBackend: PreferredBackend.gpu,
      );

      _chat = await inferenceModel.createChat(
        systemInstruction: _systemPrompt,
        isThinking: model.modelType == ModelType.gemma4,
        modelType: model.modelType,
        temperature: 1.0,
        topK: 64,
        topP: 0.95,
        tokenBuffer: 256,
      );

      _status = AIModelStatus.ready;
      _messages.add(ChatMessage(
        text: '${model.name} ready! Describe an architecture or ask anything.',
        type: MessageType.ai,
      ));
      await _saveModelIndex();
    } catch (e) {
      dev.log('flutter_gemma error: $e');
      _status = AIModelStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> sendMessage(String userText, {
    Map<String, DiagramNode>? nodes,
    List<DiagramEdge>? edges,
  }) async {
    final chat = _chat;
    if (chat == null || _status != AIModelStatus.ready) return;

    String currentState = '';
    if (nodes != null) {
      for (var node in nodes.values) {
        if (node.type == NodeType.group) {
          currentState += 'GROUP:${node.label}@${node.id}@${node.parentId ?? "null"}\n';
        } else {
          currentState += 'NODE:${node.label}@${node.id}@${node.parentId ?? "null"}@${node.iconPath ?? "null"}\n';
        }
      }
    }
    if (edges != null) {
      for (var edge in edges) {
        currentState += 'EDGE:${edge.fromId}@${edge.toId}@${edge.label ?? ""}\n';
      }
    }

    final modelPrompt = currentState.isNotEmpty
        ? 'Current state:\n$currentState\n\nUser request: $userText'
        : userText;

    _history.add({'role': 'user', 'content': modelPrompt});
    _messages.add(ChatMessage(
      text: userText,
      type: MessageType.user,
      rawLog: 'USER: $userText',
    ));
    notifyListeners();

    String buffer = '';
    try {
      await for (final token in _engine.streamResponse(chat, modelPrompt)) {
        buffer += token;
        if (_messages.isNotEmpty && _messages.last.isAI) {
          _messages.last.text += token;
        } else {
          _messages.add(ChatMessage(text: token, type: MessageType.ai));
        }
        notifyListeners();
      }
      _history.add({'role': 'assistant', 'content': buffer});
    } catch (e) {
      dev.log('Chat error: $e');
      _messages.add(ChatMessage(
        text: 'Error: $e',
        type: MessageType.ai,
        rawLog: 'ERROR: $e',
      ));
      notifyListeners();
    }
  }

  Future<void> parseAndApplyCommands(String text, DiagramState diagramState) async {
    final lines = text.split('\n');
    bool foundCommands = false;

    for (var line in lines) {
      final l = line.trim();
      if (l.startsWith('NODE:') || l.startsWith('GROUP:') || l.startsWith('EDGE:')) {
        if (!foundCommands) {
          diagramState.clearDiagramNoRebuild();
          foundCommands = true;
        }
        
        final parts = l.split(':');
        if (parts.length < 2) continue;
        
        final cmd = parts[0];
        final args = parts[1].split('@');
        
        if (cmd == 'NODE' && args.length >= 4) {
          final label = args[0];
          final id = args[1];
          final parentId = args[2] == 'null' ? null : args[2];
          final iconPath = args[3] == 'null' ? null : args[3];
          await diagramState.addNodeWithParent(
            id: id,
            label: label,
            type: NodeType.resource,
            parentId: parentId,
            iconPath: iconPath,
          );
        } else if (cmd == 'GROUP' && args.length >= 3) {
          final label = args[0];
          final id = args[1];
          final parentId = args[2] == 'null' ? null : args[2];
          await diagramState.addNodeWithParent(
            id: id,
            label: label,
            type: NodeType.group,
            parentId: parentId,
          );
        } else if (cmd == 'EDGE' && args.length >= 2) {
          final fromId = args[0];
          final toId = args[1];
          final label = args.length > 2 ? args[2] : null;
          diagramState.addEdge(fromId, toId, label: label);
        }
      }
    }
    if (foundCommands) {
      diagramState.rebuild();
    }
  }

  String? extractMermaidCode(String text) {
    // Keep for compatibility but use parseAndApplyCommands when possible
    final fenceRe = RegExp(r'```(?:mermaid)?\s*\n([\s\S]*?)```', multiLine: true);
    for (final m in fenceRe.allMatches(text)) {
      final content = m.group(1)!.trim();
      if (_isValidMermaidStart(content)) return content;
    }

    final lineRe = RegExp(r'^(flowchart\s+(?:TD|LR|TB|BT|RL)|graph\s+(?:TD|LR|TB|BT|RL)|sequenceDiagram|classDiagram|erDiagram|gantt|gitGraph|architecture-beta)', multiLine: true);
    final m = lineRe.firstMatch(text);
    if (m != null) return text.substring(m.start).trim();

    return null;
  }

  bool _isValidMermaidStart(String code) {
    final validStart = RegExp(
      r'^(flowchart\s+(?:TD|LR|TB|BT|RL)|graph\s+(?:TD|LR|TB|BT|RL)|sequenceDiagram|classDiagram|erDiagram|gantt|gitGraph|architecture-beta)',
      multiLine: true,
    );
    return validStart.hasMatch(code);
  }

  void clearConversation() {
    _history.clear();
    _messages
      ..clear()
      ..add(ChatMessage(
        text: 'Conversation cleared.',
        type: MessageType.ai,
      ));
    notifyListeners();
  }

  Future<void> tryRestoreFromCache() async {
    if (_status != AIModelStatus.idle) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_kCacheFile');
      if (!await file.exists()) return;

      final idx = int.tryParse((await file.readAsString()).trim());
      if (idx == null || idx < 0 || idx >= gemmaModels.length) return;

      _selectedModelIndex = idx;
      _status = AIModelStatus.initializing;
      _messages
        ..clear()
        ..add(ChatMessage(
          text: 'Restoring ${gemmaModels[idx].name} from cache...',
          type: MessageType.ai,
        ));
      notifyListeners();

      final model = gemmaModels[idx];
      final inferenceModel = await FlutterGemma.getActiveModel(
        maxTokens: model.maxTokens,
        preferredBackend: PreferredBackend.gpu,
      );

      _chat = await inferenceModel.createChat(
        systemInstruction: _systemPrompt,
        isThinking: model.modelType == ModelType.gemma4,
        modelType: model.modelType,
        temperature: 1.0,
        topK: 64,
        topP: 0.95,
        tokenBuffer: 256,
      );

      _status = AIModelStatus.ready;
      _messages
        ..clear()
        ..add(ChatMessage(
          text: '${model.name} restored. Ready!',
          type: MessageType.ai,
        ));
    } catch (e) {
      dev.log('[AIModelState] restore failed: $e');
      _status = AIModelStatus.idle;
      _messages
        ..clear()
        ..add(ChatMessage(
          text: 'Select a Gemma model and press Download to start.',
          type: MessageType.ai,
        ));
    }
    notifyListeners();
  }

  Future<void> _saveModelIndex() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_kCacheFile');
      await file.writeAsString('$_selectedModelIndex');
    } catch (e) {
      dev.log('[AIModelState] save index failed: $e');
    }
  }
}
