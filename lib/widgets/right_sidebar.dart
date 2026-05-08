import 'package:diagram_flow_ai/models/ai_engine_service.dart';
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RightSidebar extends StatefulWidget {
  const RightSidebar({super.key});

  @override
  State<RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends State<RightSidebar> {
  final TextEditingController _chatController = TextEditingController();
  final AIEngineService _aiEngine = AIEngineService();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final aiState = context.read<AIModelState>();
    final diagramState = context.read<DiagramState>();

    aiState.addMessage(text, MessageType.user);
    _chatController.clear();

    await for (final event in _aiEngine.processPrompt(text)) {
      if (event.startsWith('THOUGHT:')) {
        aiState.addMessage(event.replaceFirst('THOUGHT:', '').trim(), MessageType.thought);
      } else if (event.startsWith('NODE:')) {
        final nodeData = event.replaceFirst('NODE:', '').split('@');
        final label = nodeData[0];
        final coords = nodeData[1].split(',');
        final id = nodeData[2];
        
        diagramState.addNode(
          id: id,
          label: label,
          position: Offset(double.parse(coords[0]), double.parse(coords[1])),
        );
      } else if (event.startsWith('CONN:')) {
        final connData = event.replaceFirst('CONN:', '').split('->');
        diagramState.addConnection(connData[0], connData[1]);
      } else if (event.startsWith('ACTION:')) {
        aiState.addMessage(event.replaceFirst('ACTION:', '').trim(), MessageType.ai);
      }
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
          // Gemma4 AI Assistant Section
          Expanded(
            flex: 3,
            child: _buildChatSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSection(BuildContext context) {
    return Consumer<DiagramState>(
      builder: (context, state, child) {
        String mermaidCode = 'graph TD\n';
        for (final node in state.nodes) {
          mermaidCode += '  ${node.id.substring(node.id.length - 4)}[${node.label}]\n';
        }
        for (final conn in state.connections) {
          mermaidCode += '  ${conn.fromId.substring(conn.fromId.length - 4)} --> ${conn.toId.substring(conn.toId.length - 4)}\n';
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
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Gemma4 AI Assistant',
                        style: AppTypography.labelCaps,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (aiState.status == AIModelStatus.notDownloaded)
                TextButton.icon(
                  onPressed: () => aiState.startDownload(),
                  icon: const Icon(Icons.download, size: 12),
                  label: const Text('Download', style: TextStyle(fontSize: 10)),
                )
              else if (aiState.status == AIModelStatus.ready)
                const Icon(Icons.check_circle, size: 16, color: Colors.green)
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
                ),
                const SizedBox(height: 4),
                Text(
                  'Downloading... ${(aiState.downloadProgress * 100).toInt()}%',
                  style: AppTypography.labelCaps.copyWith(fontSize: 9),
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
