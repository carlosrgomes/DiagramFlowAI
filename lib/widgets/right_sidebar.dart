import 'package:diagram_flow_ai/models/ai_engine_service.dart';
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide MessageType;

class RightSidebar extends StatefulWidget {
  const RightSidebar({super.key});

  @override
  State<RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends State<RightSidebar> {
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final AIEngineService _aiEngine = AIEngineService();
  int _activeTab = 0; // 0: Assistant, 1: Logs

  @override
  void dispose() {
    _chatController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final aiState = context.read<AIModelState>();
    final diagramState = context.read<DiagramState>();

    if (aiState.chatSession == null) {
       aiState.addMessage('Gemma engine not ready. Please initialize the model.', MessageType.ai);
       return;
    }

    aiState.addMessage(text, MessageType.user, rawLog: 'USER_PROMPT: $text');
    _chatController.clear();

    String fullResponseBuffer = "";

    try {
      final stream = _aiEngine.processPrompt(text, aiState.chatSession!);
      
      await for (final response in stream) {
        if (response is ThinkingResponse) {
          aiState.addMessage(response.content, MessageType.thought, rawLog: 'THOUGHT: ${response.content}');
        } else if (response is TextResponse) {
          fullResponseBuffer += response.token;
          aiState.addMessage(response.token, MessageType.ai, rawLog: 'TOKEN: ${response.token}');
        }
      }

      // Parse commands from the complete response
      _parseCommands(fullResponseBuffer, diagramState);

    } catch (e) {
      aiState.addMessage('Error communicating with Gemma: $e', MessageType.ai, rawLog: 'ERROR: $e');
    }
  }

  void _parseCommands(String text, DiagramState diagramState) {
    final nodeRegex = RegExp(r'NODE:([\w\s]+)@([\d.]+),([\d.]+)@([\w\d_]+)');
    final nodeMatches = nodeRegex.allMatches(text);
    
    for (final match in nodeMatches) {
      final label = match.group(1)!.trim();
      final x = double.tryParse(match.group(2)!) ?? 200.0;
      final y = double.tryParse(match.group(3)!) ?? 200.0;
      final id = match.group(4)!;
      
      diagramState.addNode(id: id, label: label, position: Offset(x, y));
    }

    final connRegex = RegExp(r'CONN:([\w\d_]+)->([\w\d_]+)');
    final connMatches = connRegex.allMatches(text);
    
    for (final match in connMatches) {
      final fromId = match.group(1)!;
      final toId = match.group(2)!;
      diagramState.addConnection(fromId, toId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      color: AppColors.surface,
      child: Column(
        children: [
          // Mermaid Architecture Section
          Expanded(
            flex: 2,
            child: _buildCodeSection(context),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          
          // Tab Header
          _buildTabHeader(),
          
          // Gemma4 AI Assistant / Logs Section
          Expanded(
            flex: 3,
            child: _activeTab == 0 ? _buildChatSection(context) : _buildLogsSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
      ),
      child: Row(
        children: [
          _buildTabButton('Assistant', 0),
          _buildTabButton('System Logs', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final active = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(
            fontSize: 9,
            color: active ? AppColors.onSurface : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCodeSection(BuildContext context) {
    return Consumer<DiagramState>(
      builder: (context, state, child) {
        String mermaidCode = 'graph TD\n';
        for (final node in state.nodes) {
          final id = node.id.length > 4 ? node.id.substring(node.id.length - 4) : node.id;
          mermaidCode += '  $id[${node.label}]\n';
        }
        for (final conn in state.connections) {
          final fromId = conn.fromId.length > 4 ? conn.fromId.substring(conn.fromId.length - 4) : conn.fromId;
          final toId = conn.toId.length > 4 ? conn.toId.substring(conn.toId.length - 4) : conn.toId;
          mermaidCode += '  $fromId --> $toId\n';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mermaid Architecture',
                    style: AppTypography.labelCaps,
                  ),
                  const Icon(Icons.copy_all_outlined, size: 16, color: AppColors.onSurfaceVariant),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF060A14),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    mermaidCode,
                    style: AppTypography.code.copyWith(color: AppColors.secondary, fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatSection(BuildContext context) {
    final aiState = context.watch<AIModelState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Model Selection & Model Download
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: aiState.selectedModel,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                          style: AppTypography.labelCaps.copyWith(fontSize: 10, color: AppColors.primary),
                          dropdownColor: AppColors.surfaceContainerHighest,
                          onChanged: (val) => aiState.setSelectedModel(val!),
                          items: aiState.availableModels.map((m) {
                            return DropdownMenuItem(value: m, child: Text(m));
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (aiState.status == AIModelStatus.notDownloaded || aiState.status == AIModelStatus.error)
                    IconButton(
                      onPressed: () {
                        aiState.setToken(_tokenController.text.trim());
                        aiState.startDownload();
                      },
                      icon: const Icon(Icons.download, size: 16),
                      tooltip: 'Download Model',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else if (aiState.status == AIModelStatus.ready)
                    const Icon(Icons.check_circle, size: 16, color: Colors.green)
                  else if (aiState.status == AIModelStatus.downloading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              if (aiState.status == AIModelStatus.notDownloaded || aiState.status == AIModelStatus.error) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  style: AppTypography.bodyMd.copyWith(fontSize: 10),
                  decoration: InputDecoration(
                    hintText: 'Hugging Face Token (hf_...)',
                    hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (aiState.status == AIModelStatus.downloading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: aiState.downloadProgress,
                  backgroundColor: AppColors.surfaceContainer,
                  color: AppColors.primary,
                  minHeight: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  'Downloading model... ${(aiState.downloadProgress * 100).toInt()}%',
                  style: AppTypography.labelCaps.copyWith(fontSize: 8),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: aiState.messages.length,
            itemBuilder: (context, index) {
              final message = aiState.messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildChatMessage(message),
              );
            },
          ),
        ),
        // Chat Input
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _chatController,
            enabled: aiState.status == AIModelStatus.ready,
            onSubmitted: (_) => _handleSendMessage(),
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: aiState.status == AIModelStatus.ready 
                  ? 'Ask Gemma4...' 
                  : 'Download model to start...',
              hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12),
              filled: true,
              fillColor: AppColors.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              suffixIcon: IconButton(
                onPressed: _handleSendMessage,
                icon: const Icon(Icons.send_outlined, size: 16, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogsSection(BuildContext context) {
    final aiState = context.watch<AIModelState>();
    return Container(
      color: const Color(0xFF040612),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: aiState.messages.length,
        itemBuilder: (context, index) {
          final message = aiState.messages[index];
          if (message.rawLog == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withAlpha(100),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.outlineVariant.withAlpha(30)),
            ),
            child: Text(
              message.rawLog!,
              style: AppTypography.code.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    if (message.type == MessageType.thought) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.auto_awesome, size: 12, color: AppColors.secondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.text,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant.withAlpha(180),
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    final isAI = message.type == MessageType.ai;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAI ? AppColors.primary.withAlpha(30) : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: isAI ? Border.all(color: AppColors.primary.withAlpha(50)) : null,
      ),
      child: Text(
        message.text,
        style: AppTypography.bodyMd.copyWith(
          color: isAI ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
