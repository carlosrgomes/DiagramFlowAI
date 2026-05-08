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
  int _activeTab = 0; // 0: Assistant, 1: Logs

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

    aiState.addMessage(text, MessageType.user, rawLog: 'USER_PROMPT: $text\nMODEL: ${aiState.selectedModel}');
    _chatController.clear();

    await for (final event in _aiEngine.processPrompt(text)) {
      if (event.startsWith('THOUGHT:')) {
        final thought = event.replaceFirst('THOUGHT:', '').trim();
        aiState.addMessage(thought, MessageType.thought, rawLog: 'AI_REASONING_STEP: $thought');
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
        final action = event.replaceFirst('ACTION:', '').trim();
        aiState.addMessage(action, MessageType.ai, rawLog: 'AI_FINAL_ACTION: $action\nSTATE: UPDATED');
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
        // Model Selection & Model Download
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
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
              if (aiState.status == AIModelStatus.notDownloaded)
                IconButton(
                  onPressed: () => aiState.startDownload(),
                  icon: const Icon(Icons.download, size: 16),
                  tooltip: 'Download Model',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
