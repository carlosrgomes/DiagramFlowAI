import 'dart:async';
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class RightSidebar extends StatefulWidget {
  const RightSidebar({super.key});

  @override
  State<RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends State<RightSidebar> {
  final _chatCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _chatScroll = ScrollController();
  Timer? _debounce;
  int _activeTab = 0;
  // Track the last code we pushed into the text field to avoid loops
  String _lastExternalCode = '';

  @override
  void initState() {
    super.initState();
    final code = context.read<DiagramState>().mermaidCode;
    _codeCtrl.text = code;
    _lastExternalCode = code;

    _codeCtrl.addListener(_onCodeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync when external updates arrive (AI, drag-drop, toolbar buttons)
    final code = context.read<DiagramState>().mermaidCode;
    if (code != _lastExternalCode && code != _codeCtrl.text) {
      _lastExternalCode = code;
      _codeCtrl.removeListener(_onCodeChanged);
      _codeCtrl.text = code;
      _codeCtrl.addListener(_onCodeChanged);
    }
  }

  void _onCodeChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final code = _codeCtrl.text;
      _lastExternalCode = code;
      context.read<DiagramState>().setCode(code);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _chatCtrl.dispose();
    _tokenCtrl.dispose();
    _codeCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();

    final aiState = context.read<AIModelState>();
    final diagramState = context.read<DiagramState>();

    // Pass the current diagram state as nodes and edges
    await aiState.sendMessage(
      text,
      nodes: diagramState.nodes,
      edges: diagramState.edges,
    );

    final lastAi = aiState.messages.lastWhere(
      (m) => m.isAI,
      orElse: () => ChatMessage(text: '', type: MessageType.ai),
    );

    // Try parsing structured commands first
    await aiState.parseAndApplyCommands(lastAi.text, diagramState);
    
    // Fallback to legacy mermaid extraction if no commands were processed 
    // (though parseAndApplyCommands should handle this internally or be the primary path)
    if (!lastAi.text.contains('NODE:') && !lastAi.text.contains('GROUP:')) {
      final mermaid = aiState.extractMermaidCode(lastAi.text);
      if (mermaid != null) {
        diagramState.setCode(mermaid);
      }
    }
    
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagramState>(
      builder: (context, diagramState, child) {
        // Sync code editor when state changes externally
        final externalCode = diagramState.mermaidCode;
        if (externalCode != _lastExternalCode &&
            externalCode != _codeCtrl.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _lastExternalCode = externalCode;
            _codeCtrl.removeListener(_onCodeChanged);
            _codeCtrl.text = externalCode;
            _codeCtrl.addListener(_onCodeChanged);
          });
        }

        return Container(
          width: 320,
          color: AppColors.surface,
          child: Column(
            children: [
              Expanded(flex: 2, child: _buildMermaidSection(diagramState)),
              const Divider(height: 1, color: AppColors.outlineVariant),
              _buildTabHeader(),
              Expanded(
                flex: 3,
                child: _activeTab == 0 ? _buildAssistant() : _buildLogs(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Mermaid code panel ──────────────────────────────────────────────────────

  Widget _buildMermaidSection(DiagramState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mermaid Code', style: AppTypography.labelCaps),
              Row(children: [
                _Btn(Icons.delete_outline, 'Clear', state.clearDiagram),
                const SizedBox(width: 4),
                _Btn(Icons.copy_outlined, 'Copy',
                    () => Clipboard.setData(
                        ClipboardData(text: state.mermaidCode))),
              ]),
            ],
          ),
        ),
        if (state.syntaxError != null)
          _Banner(
            color: AppColors.error.withAlpha(20),
            borderColor: AppColors.error.withAlpha(80),
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            child: Text(
              state.syntaxError!,
              style: AppTypography.code
                  .copyWith(color: AppColors.error, fontSize: 9),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF060A14),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: state.syntaxError != null
                      ? AppColors.error.withAlpha(80)
                      : AppColors.outlineVariant.withAlpha(50)),
            ),
            child: TextField(
              controller: _codeCtrl,
              maxLines: null,
              expands: true,
              style: AppTypography.code.copyWith(
                  color: AppColors.secondary, fontSize: 10),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(10),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab header ──────────────────────────────────────────────────────────────

  Widget _buildTabHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.surfaceContainer,
      child: Row(children: [_tab('Assistant', 0), _tab('System Logs', 1)]),
    );
  }

  Widget _tab(String label, int index) {
    final active = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(
            fontSize: 9,
            color: active ? AppColors.onSurface : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ── Assistant tab ────────────────────────────────────────────────────────────

  Widget _buildAssistant() {
    final ai = context.watch<AIModelState>();
    return Column(
      children: [
        _buildModelRow(ai),
        if (ai.selectedModel.needsAuth) _buildTokenRow(ai),
        _buildStatusArea(ai),
        Expanded(child: _buildChatList(ai)),
        _buildInput(ai),
      ],
    );
  }

  Widget _buildModelRow(AIModelState ai) {
    final busy = ai.status == AIModelStatus.downloading ||
        ai.status == AIModelStatus.initializing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: ai.selectedModelIndex,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 14,
                      color: AppColors.onSurfaceVariant),
                  style: AppTypography.code
                      .copyWith(fontSize: 11, color: AppColors.primary),
                  dropdownColor: AppColors.surfaceContainerHighest,
                  onChanged: busy ? null : (v) => ai.setSelectedModel(v!),
                  items: List.generate(
                    gemmaModels.length,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(gemmaModels[i].name,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            )
          else if (ai.status == AIModelStatus.ready)
            const Icon(Icons.check_circle_outline,
                size: 18, color: Colors.greenAccent)
          else
            _Btn(Icons.download_outlined, 'Download & load',
                ai.downloadAndLoad,
                color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildTokenRow(AIModelState ai) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: TextField(
        controller: _tokenCtrl,
        obscureText: true,
        style: AppTypography.code.copyWith(fontSize: 11),
        onChanged: ai.setToken,
        decoration: InputDecoration(
          hintText: 'hf_... token required for this model',
          hintStyle: AppTypography.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant, fontSize: 10),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildStatusArea(AIModelState ai) {
    if (ai.status == AIModelStatus.downloading) {
      final pct = (ai.downloadProgress * 100).toInt();
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ai.downloadProgress > 0 ? ai.downloadProgress : null,
                backgroundColor: AppColors.surfaceContainer,
                color: AppColors.primary,
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Downloading model${pct > 0 ? " · $pct%" : "..."}',
              style: AppTypography.code
                  .copyWith(fontSize: 9, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (ai.status == AIModelStatus.initializing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Text(
          'Loading model into memory...',
          style: AppTypography.code
              .copyWith(fontSize: 10, color: AppColors.onSurfaceVariant),
        ),
      );
    }

    if (ai.status == AIModelStatus.error) {
      return _Banner(
        color: AppColors.error.withAlpha(20),
        borderColor: AppColors.error.withAlpha(60),
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        child: Text(
          ai.errorMessage ?? 'Unknown error',
          style: AppTypography.code
              .copyWith(color: AppColors.error, fontSize: 10),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (ai.status == AIModelStatus.ready) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Row(children: [
          const Icon(Icons.circle, size: 6, color: Colors.greenAccent),
          const SizedBox(width: 6),
          Text(
            'Running locally · ${ai.selectedModel.name}',
            style: AppTypography.code
                .copyWith(fontSize: 10, color: AppColors.onSurfaceVariant),
          ),
        ]),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildChatList(AIModelState ai) {
    _scrollToBottom();
    return ListView.builder(
      controller: _chatScroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: ai.messages.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildMessage(ai.messages[i]),
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isAI = msg.isAI;
    final isDiagram = isAI &&
        (msg.text.contains('flowchart') ||
            msg.text.contains('graph ') ||
            msg.text.contains('sequenceDiagram') ||
            msg.text.contains('classDiagram'));
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAI
            ? (isDiagram
                ? AppColors.secondary.withAlpha(20)
                : AppColors.primary.withAlpha(25))
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: isAI
            ? Border.all(
                color: isDiagram
                    ? AppColors.secondary.withAlpha(60)
                    : AppColors.primary.withAlpha(40),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            Icon(
              isDiagram
                  ? Icons.account_tree_outlined
                  : Icons.auto_awesome,
              size: 12,
              color: isDiagram ? AppColors.secondary : AppColors.primary,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              msg.text,
              style: AppTypography.bodyMd.copyWith(
                color:
                    isAI ? AppColors.onSurface : AppColors.onSurfaceVariant,
                fontFamily: isDiagram ? 'JetBrainsMono' : null,
                fontSize: isDiagram ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(AIModelState ai) {
    final ready = ai.isReady;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatCtrl,
              enabled: ready,
              onSubmitted: (_) => _handleSend(),
              style: AppTypography.bodyMd.copyWith(fontSize: 12),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: ready
                    ? 'Ask Gemma or describe a diagram...'
                    : 'Download a model to start...',
                hintStyle: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(children: [
            _Btn(Icons.send_outlined, 'Send',
                ready ? _handleSend : null,
                color: AppColors.primary),
            const SizedBox(height: 4),
            _Btn(Icons.refresh_outlined, 'Clear',
                ready ? ai.clearConversation : null),
          ]),
        ],
      ),
    );
  }

  // ── Logs tab ─────────────────────────────────────────────────────────────────

  Widget _buildLogs() {
    final ai = context.watch<AIModelState>();
    return Container(
      color: const Color(0xFF040612),
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: ai.messages.length,
        itemBuilder: (_, i) {
          final msg = ai.messages[i];
          if (msg.rawLog == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                  color: AppColors.outlineVariant.withAlpha(30)),
            ),
            child: Text(
              msg.rawLog!,
              style: AppTypography.code
                  .copyWith(fontSize: 9, color: AppColors.onSurfaceVariant),
            ),
          );
        },
      ),
    );
  }
}

// ── Shared micro-widgets ─────────────────────────────────────────────────────

class _Btn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;

  const _Btn(this.icon, this.tooltip, this.onTap,
      {this.color = AppColors.onSurfaceVariant});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon,
                size: 16,
                color: onTap != null ? color : color.withAlpha(80)),
          ),
        ),
      );
}

class _Banner extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _Banner({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      );
}
