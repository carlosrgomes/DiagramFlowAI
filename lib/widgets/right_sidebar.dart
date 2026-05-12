import 'dart:async';
import 'dart:developer' as dev;
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/mermaid_validator.dart';
import 'package:diagram_flow_ai/models/prompt_dispatcher.dart';
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
  StreamSubscription<String>? _promptSub;
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
    _promptSub = context.read<PromptDispatcher>().prompts.listen(_onPromptDispatched);
  }

  void _onPromptDispatched(String prompt) {
    if (!mounted) return;
    _chatCtrl.text = prompt;
    setState(() => _activeTab = 0);
    if (context.read<AIModelState>().isReady) {
      _handleSend();
    }
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
    _promptSub?.cancel();
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

  static const int _kMaxAttempts = 3;

  Future<void> _handleSend() async {
    final originalPrompt = _chatCtrl.text.trim();
    if (originalPrompt.isEmpty) return;
    _chatCtrl.clear();

    final aiState = context.read<AIModelState>();
    final diagramState = context.read<DiagramState>();
    final validator = context.read<MermaidValidator>();

    String prompt = originalPrompt;
    String? lastError;
    String? lastCandidate;
    bool succeeded = false;

    try {
      for (var attempt = 1; attempt <= _kMaxAttempts; attempt++) {
        aiState.setAttempt(attempt, _kMaxAttempts);
        dev.log('========== ReAct attempt $attempt/$_kMaxAttempts ==========',
            name: 'CFAI');

        if (attempt > 1) {
          prompt = _buildCorrectionPrompt(lastError!);
          dev.log('Correction prompt:\n$prompt', name: 'CFAI.retry');
        }

        try {
          await aiState.sendMessage(
            prompt,
            nodes: diagramState.nodes,
            edges: diagramState.edges,
          );
        } catch (e, st) {
          dev.log('sendMessage threw on attempt $attempt: $e\n$st',
              name: 'CFAI.error');
          break;
        }

        final lastAi = aiState.messages.lastWhere(
          (m) => m.isAI,
          orElse: () => ChatMessage(text: '', type: MessageType.ai),
        );

        dev.log(
            'After stream: text=${lastAi.text.length} chars, '
            'thinking=${lastAi.thinking.length} chars',
            name: 'CFAI');

        // Build the working response, possibly extending it via continuation
        // calls if the model truncated mid-diagram (token-budget exhaustion).
        var responseText = lastAi.text;
        if (responseText.contains('<DIAGRAM>') &&
            !responseText.contains('</DIAGRAM>')) {
          dev.log('Truncation detected (open <DIAGRAM> with no close). '
              'Requesting continuation chunks.', name: 'CFAI');
          for (var contRound = 1; contRound <= 3; contRound++) {
            try {
              await aiState.sendMessage(
                'CONTINUE the Mermaid output from EXACTLY where you stopped. '
                'Output the remaining lines and the closing </DIAGRAM> tag. '
                'NO reasoning, NO preamble, NO restart.',
                nodes: diagramState.nodes,
                edges: diagramState.edges,
              );
            } catch (e) {
              dev.log('Continuation chunk $contRound threw: $e',
                  name: 'CFAI.error');
              break;
            }
            final chunk = aiState.messages.lastWhere((m) => m.isAI);
            responseText = '$responseText\n${chunk.text}';
            dev.log('Chunk $contRound added ${chunk.text.length} chars '
                '(total response: ${responseText.length})', name: 'CFAI');
            if (responseText.contains('</DIAGRAM>')) {
              dev.log('Closing tag found after continuation $contRound',
                  name: 'CFAI');
              break;
            }
          }
        }

        // Empty answer → token-budget exhausted before any output. Ask for a
        // shorter response.
        if (responseText.trim().isEmpty &&
            !lastAi.thinking.contains('<DIAGRAM>')) {
          dev.log('Empty answer on attempt $attempt — token-limit exhaustion.',
              name: 'CFAI');
          lastError =
              'Your previous response was empty (likely too much reasoning). '
              'Skip the planning. Output just the <DIAGRAM>...</DIAGRAM> block '
              'with the Mermaid code, nothing else.';
          continue;
        }

        // Structured commands path always produces valid Mermaid via the
        // model layer, so skip validation/retry there.
        if (responseText.contains('NODE:') || responseText.contains('GROUP:')) {
          dev.log('Structured commands path detected — applying',
              name: 'CFAI');
          await aiState.parseAndApplyCommands(responseText, diagramState);
          succeeded = true;
          break;
        }

        // Try the (possibly stitched) answer first; fall back to thinking
        // content if the model put the diagram inside <think>.
        var mermaid = aiState.extractMermaidCode(responseText);
        if (mermaid == null && lastAi.hasThinking) {
          dev.log('No diagram in answer — trying thinking content as fallback',
              name: 'CFAI');
          mermaid = aiState.extractMermaidCode(lastAi.thinking);
        }
        dev.log('Extracted (${mermaid?.length ?? 0} chars): '
            '${mermaid == null ? "<null>" : mermaid.split('\n').take(5).join(' | ')}',
            name: 'CFAI');

        if (mermaid == null) {
          // Format failure → retry with format-specific correction prompt.
          lastError =
              'Your previous response had no diagram between <DIAGRAM>...</DIAGRAM> tags. '
              'You MUST wrap the Mermaid code between those exact tags on their own lines. '
              'No fences, no markdown.';
          dev.log('No diagram extractable — retrying with format correction',
              name: 'CFAI');
          continue;
        }

        if (mermaid == lastCandidate) {
          dev.log(
              'Convergence — model produced identical output on attempt $attempt. '
              'Applying last candidate so user can hand-edit.',
              name: 'CFAI');
          diagramState.pushSnapshot();
          diagramState.setCode(mermaid);
          break;
        }
        lastCandidate = mermaid;

        MermaidValidation result;
        try {
          result = await validator.validate(mermaid);
        } catch (e) {
          dev.log('Validator threw on attempt $attempt: $e',
              name: 'CFAI.error');
          diagramState.pushSnapshot();
          diagramState.setCode(mermaid);
          break;
        }

        dev.log(
            'Validate attempt $attempt: ok=${result.ok}'
            '${result.error == null ? "" : " error=${result.error}"}',
            name: 'CFAI');

        if (result.ok) {
          diagramState.pushSnapshot();
          diagramState.setCode(mermaid);
          succeeded = true;
          break;
        }

        lastError = result.error ?? 'Unknown parse error';

        if (attempt == _kMaxAttempts) {
          dev.log(
              'All $_kMaxAttempts attempts failed — applying last candidate '
              'so user can hand-edit',
              name: 'CFAI');
          diagramState.pushSnapshot();
          diagramState.setCode(mermaid);
        }
      }

      if (!succeeded) {
        dev.log('ReAct loop ended without a valid diagram', name: 'CFAI');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Could not produce a valid diagram in $_kMaxAttempts attempts. '
              'Last error: ${lastError ?? "no diagram extracted"}',
              style: AppTypography.bodyMd.copyWith(fontSize: 12),
            ),
            backgroundColor: AppColors.error.withAlpha(220),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ));
        }
      }
    } catch (e, st) {
      dev.log('ReAct loop crashed: $e\n$st', name: 'CFAI.error');
    } finally {
      aiState.setAttempt(0, _kMaxAttempts);
      _scrollToBottom();
    }
  }

  /// Short correction prompt — the model already has its own previous output
  /// in chat history, so we don't need to paste the broken code back.
  /// Pasting it would also bloat the context window (Gemma 4 = 4K tokens).
  String _buildCorrectionPrompt(String error) {
    // Keep the prompt SHORT. Long correction prompts blow Gemma 4's 4K
    // context (reasoning + previous answer + this prompt + new answer all
    // share the budget). When the budget runs out, the model returns an
    // empty answer and the loop is dead.
    final firstThree = error.split('\n').take(3).join(' ').trim();
    return 'Mermaid rejected your diagram: $firstThree. '
        'Output ONLY the corrected diagram between <DIAGRAM>...</DIAGRAM> tags '
        'on their own lines. Keep reasoning to 2 lines max. '
        'No fences, no prose outside the tags.';
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
              Divider(height: 1, color: AppColors.outlineVariant),
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
                  icon: Icon(Icons.keyboard_arrow_down, size: 14,
                      color: AppColors.onSurfaceVariant),
                  style: AppTypography.code
                      .copyWith(fontSize: 11, color: AppColors.primary),
                  dropdownColor: AppColors.surfaceContainerHighest,
                  onChanged: busy ? null : (v) => ai.setSelectedModel(v!),
                  items: List.generate(
                    gemmaModels.length,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Row(
                        children: [
                          Icon(
                            ai.isInstalled(i)
                                ? Icons.check_circle
                                : Icons.cloud_download_outlined,
                            size: 11,
                            color: ai.isInstalled(i)
                                ? Colors.greenAccent
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(gemmaModels[i].name,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            )
          else if (ai.status == AIModelStatus.ready)
            const Icon(Icons.check_circle_outline,
                size: 18, color: Colors.greenAccent)
          else if (ai.status == AIModelStatus.error)
            _Btn(Icons.refresh, 'Retry', ai.downloadAndLoad,
                color: AppColors.error)
          else if (!ai.isSelectedInstalled)
            _Btn(Icons.download_outlined, 'Download & load',
                ai.downloadAndLoad,
                color: AppColors.primary)
          else
            // Already on disk → auto-load handles it; button stays disabled.
            Tooltip(
              message: 'Model on disk · loading automatically',
              child: Icon(Icons.bolt_outlined,
                  size: 18, color: AppColors.outlineVariant),
            ),
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
      itemBuilder: (_, i) {
        final isLast = i == ai.messages.length - 1;
        final isStreaming = ai.isStreaming && isLast && ai.messages[i].isAI;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildMessage(ai.messages[i], isStreaming: isStreaming),
        );
      },
    );
  }

  Widget _buildMessage(ChatMessage msg, {bool isStreaming = false}) {
    final isAI = msg.isAI;
    final isDiagram = isAI &&
        (mermaidHeaderRegex.hasMatch(msg.text) ||
            msg.text.contains('NODE:') ||
            msg.text.contains('GROUP:'));
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI && msg.hasThinking) _ThinkingBlock(content: msg.thinking),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAI) ...[
                Icon(
                  isDiagram ? Icons.account_tree_outlined : Icons.auto_awesome,
                  size: 12,
                  color: isDiagram ? AppColors.secondary : AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: _StreamingText(
                  text: msg.text.isEmpty && isStreaming ? '…' : msg.text,
                  showCursor: isStreaming,
                  style: AppTypography.bodyMd.copyWith(
                    color: isAI ? AppColors.onSurface : AppColors.onSurfaceVariant,
                    fontFamily: isDiagram ? 'JetBrainsMono' : null,
                    fontSize: isDiagram ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput(AIModelState ai) {
    final ready = ai.isReady;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    if (ready) _handleSend();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _chatCtrl,
                  enabled: ready,
                  style: AppTypography.bodyMd.copyWith(fontSize: 12, height: 1.4),
                  minLines: 4,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: ready
                        ? 'Ask Gemma or describe a diagram...\n(Enter to send · Shift+Enter for newline)'
                        : 'Download a model to start...',
                    hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.35),
                    filled: true,
                    fillColor: AppColors.surfaceContainer,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppColors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BoxBtn(
                  icon: Icons.send_outlined,
                  tooltip: 'Send (Enter)',
                  onTap: ready ? _handleSend : null,
                  color: AppColors.primary,
                  filled: true,
                ),
                _BoxBtn(
                  icon: Icons.refresh_outlined,
                  tooltip: 'Clear conversation',
                  onTap: ready ? ai.clearConversation : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Logs tab ─────────────────────────────────────────────────────────────────

  Widget _buildLogs() {
    final ai = context.watch<AIModelState>();
    final entries = <_LogEntry>[];
    for (final msg in ai.messages) {
      if (msg.rawLog != null) {
        entries.add(_LogEntry(kind: 'USER', body: msg.rawLog!));
      }
      if (msg.isAI && msg.hasThinking) {
        entries.add(_LogEntry(kind: 'REASONING', body: msg.thinking));
      }
      if (msg.isAI && msg.text.isNotEmpty) {
        entries.add(_LogEntry(kind: 'ANSWER', body: msg.text));
      }
    }

    return Container(
      color: const Color(0xFF040612),
      child: Column(
        children: [
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: [
                  Text(
                    '${entries.length} entries',
                    style: AppTypography.code.copyWith(
                        fontSize: 9, color: AppColors.onSurfaceVariant),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _copyAllLogs(entries),
                    icon: const Icon(Icons.copy_all_outlined, size: 12),
                    label: Text(
                      'Copy all',
                      style: AppTypography.code.copyWith(fontSize: 10),
                    ),
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 24),
                      foregroundColor: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              itemCount: entries.length,
              itemBuilder: (_, i) => _LogCard(entry: entries[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _copyAllLogs(List<_LogEntry> entries) {
    final blob = entries.map((e) => '── ${e.kind} ──\n${e.body}').join('\n\n');
    Clipboard.setData(ClipboardData(text: blob));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied ${entries.length} entries to clipboard',
          style: AppTypography.bodyMd.copyWith(fontSize: 12)),
      backgroundColor: AppColors.surfaceContainer,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}

class _LogEntry {
  final String kind; // USER · REASONING · ANSWER
  final String body;
  _LogEntry({required this.kind, required this.body});
}

class _LogCard extends StatelessWidget {
  final _LogEntry entry;
  const _LogCard({required this.entry});

  Color get _accent {
    switch (entry.kind) {
      case 'USER': return AppColors.onSurfaceVariant;
      case 'REASONING': return AppColors.secondary;
      case 'ANSWER': return AppColors.primary;
      default: return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(3),
        border: Border(left: BorderSide(color: _accent.withAlpha(160), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                entry.kind,
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 8,
                  color: _accent,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Copy',
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: entry.body));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${entry.kind} copied',
                          style:
                              AppTypography.bodyMd.copyWith(fontSize: 12)),
                      backgroundColor: AppColors.surfaceContainer,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  borderRadius: BorderRadius.circular(3),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.copy_outlined,
                        size: 11, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            entry.body,
            style: AppTypography.code.copyWith(
                fontSize: 9, color: AppColors.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ── Shared micro-widgets ─────────────────────────────────────────────────────

class _Btn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  const _Btn(this.icon, this.tooltip, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.onSurfaceVariant;
    return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon,
                size: 16,
                color: onTap != null ? c : c.withAlpha(80)),
          ),
        ),
      );
  }
}

class _ThinkingBlock extends StatefulWidget {
  final String content;
  const _ThinkingBlock({required this.content});

  @override
  State<_ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<_ThinkingBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(Icons.psychology_outlined,
                    size: 11, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Reasoning',
                  style: AppTypography.labelCaps.copyWith(
                    fontSize: 8,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.content,
                style: AppTypography.bodyMd.copyWith(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StreamingText extends StatefulWidget {
  final String text;
  final bool showCursor;
  final TextStyle style;
  const _StreamingText({
    required this.text,
    required this.showCursor,
    required this.style,
  });

  @override
  State<_StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<_StreamingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showCursor) {
      return Text(widget.text, style: widget.style);
    }
    return AnimatedBuilder(
      animation: _blink,
      builder: (_, _) {
        return Text.rich(
          TextSpan(
            text: widget.text,
            style: widget.style,
            children: [
              TextSpan(
                text: '▎',
                style: widget.style.copyWith(
                  color: AppColors.primary
                      .withAlpha((255 * _blink.value).round()),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoxBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;
  final bool filled;

  const _BoxBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final c = color ?? AppColors.onSurfaceVariant;
    final fg = enabled ? (filled ? AppColors.onPrimary : c) : c.withAlpha(80);
    final bg = filled
        ? (enabled ? c : c.withAlpha(60))
        : (enabled ? AppColors.surfaceContainer : AppColors.surfaceContainer.withAlpha(120));
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: filled
                  ? null
                  : Border.all(color: AppColors.outlineVariant.withAlpha(120)),
            ),
            child: Icon(icon, size: 16, color: fg),
          ),
        ),
      ),
    );
  }
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
