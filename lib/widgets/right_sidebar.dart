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

  void _handleSendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final aiState = context.read<AIModelState>();
    final diagramState = context.read<DiagramState>();

    aiState.addMessage(text, false);
    _chatController.clear();

    // Process with AI Engine
    final command = _aiEngine.parsePrompt(text);
    if (command != null) {
      aiState.addMessage('Understood. Adding ${command.label} to the canvas...', true);
      
      diagramState.addNode(
        id: 'ai_node_${DateTime.now().millisecondsSinceEpoch}',
        label: command.label,
        position: command.position,
      );
    } else {
      aiState.addMessage('I\'m sorry, I didn\'t recognize an architectural command in your message. Try asking to "add an EC2 instance" or "create a VPC".', true);
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
    const mockCode = '''graph TD
  A[App ALB] -->|Traffic| B(Web API-1)
  A -->|Traffic| C(Web API-2)
  B --> D{Primary DB}
  C --> D''';

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
              color: const Color(0xFF060A14), // Darker code background
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
            ),
            child: Text(
              mockCode,
              style: AppTypography.code.copyWith(color: AppColors.secondary),
            ),
          ),
        ),
      ],
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
                child: _buildChatMessage(message.text, isAI: message.isAI),
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

  Widget _buildChatMessage(String text, {required bool isAI}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAI ? AppColors.primary.withAlpha(30) : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: isAI ? Border.all(color: AppColors.primary.withAlpha(50)) : null,
      ),
      child: Text(
        text,
        style: AppTypography.bodyMd.copyWith(
          color: isAI ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
