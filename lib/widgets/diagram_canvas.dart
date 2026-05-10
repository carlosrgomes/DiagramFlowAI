import 'dart:convert';
import 'package:diagram_flow_ai/models/asset_manager.dart';
import 'package:diagram_flow_ai/models/diagram_node.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ── HTML template ─────────────────────────────────────────────────────────────

String _buildMermaidHtml() => '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: #0B1326; color: #DAE2FD; overflow: auto; font-family: sans-serif; }
    #diagram { padding: 32px; min-height: 100vh; display: flex; justify-content: center; }
    svg { max-width: 100%; height: auto; }
    
    /* Mermaid Overrides */
    .node rect, .node circle, .node ellipse, .node polygon, .node path {
      fill: #171F33 !important;
      stroke: #464554 !important;
      stroke-width: 1.5px !important;
    }
    .node .label { color: #DAE2FD !important; }
    .edgePath path { stroke: #C0C1FF !important; stroke-width: 1.5px !important; }
    .edgeLabel { background-color: #0B1326 !important; color: #DAE2FD !important; }
    .cluster rect { fill: #171F33 !important; stroke: #464554 !important; stroke-dasharray: 5 5; }
    .cluster .label { color: #7BD0FF !important; font-weight: bold; }

    #error-msg {
      display: none;
      background: #331717;
      border-left: 3px solid #FFB4AB;
      color: #FFB4AB;
      font-family: monospace;
      font-size: 12px;
      padding: 12px 16px;
      margin: 16px;
      white-space: pre-wrap;
      border-radius: 4px;
    }
  </style>
</head>
<body>
  <div id="diagram" class="mermaid">flowchart TD
    A[Start] --> B[End]</div>
  <div id="error-msg"></div>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
  <script>
    mermaid.initialize({
      startOnLoad: false,
      theme: 'dark',
      securityLevel: 'loose',
      htmlLabels: true,
      flowchart: { curve: 'step', useMaxWidth: true }
    });

    // Render initial diagram
    mermaid.run({ nodes: [document.getElementById('diagram')] });

    async function renderDiagram(code) {
      const el = document.getElementById('diagram');
      const errEl = document.getElementById('error-msg');
      try {
        await mermaid.parse(code);
        el.className = 'mermaid';
        el.textContent = code;
        el.removeAttribute('data-processed');
        errEl.style.display = 'none';
        await mermaid.run({ nodes: [el] });
        DiagramBridge.postMessage(JSON.stringify({ type: 'syntaxOk' }));
      } catch(e) {
        const msg = String(e).replace(/^.*?Parse error.*?\\n/s, '').trim() || String(e);
        errEl.textContent = msg;
        errEl.style.display = 'block';
        DiagramBridge.postMessage(JSON.stringify({ type: 'syntaxError', msg: msg }));
      }
    }

    let _ct = null;
    document.addEventListener('click', function(e) {
      clearTimeout(_ct);
      _ct = setTimeout(function() {
        const node = e.target.closest('.node');
        if (node && node.id) {
          const label = node.querySelector('span, p, foreignObject')?.textContent?.trim() || node.id;
          DiagramBridge.postMessage(JSON.stringify({ type: 'select', id: node.id, label: label }));
        } else {
          DiagramBridge.postMessage(JSON.stringify({ type: 'deselect' }));
        }
      }, 200);
    });

    document.addEventListener('dblclick', function(e) {
      clearTimeout(_ct);
      const node = e.target.closest('.node');
      if (!node) return;
      const label = node.querySelector('span, p, foreignObject')?.textContent?.trim() || '';
      const id = node.id || '';
      try {
        DiagramBridge.postMessage(JSON.stringify({ type: 'dblclick', id: id, label: label }));
      } catch(ex) {}
    });
  </script>
</body>
</html>
''';

// ── MermaidCanvas ─────────────────────────────────────────────────────────────

class DiagramCanvas extends StatefulWidget {
  const DiagramCanvas({super.key});
  @override
  State<DiagramCanvas> createState() => _DiagramCanvasState();
}

class _DiagramCanvasState extends State<DiagramCanvas> {
  late final WebViewController _controller;
  bool _webViewReady = false;
  String _lastRendered = '';
  String? _selectedNodeId;
  String? _selectedNodeLabel;
  String? _connectingFromId;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'DiagramBridge',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          _webViewReady = true;
          // Push current code into the page after it loads
          final code =
              context.read<DiagramState>().mermaidCode;
          _renderCode(code);
        },
      ))
      ..loadHtmlString(_buildMermaidHtml());
  }

  void _renderCode(String code) {
    if (!_webViewReady || code == _lastRendered) return;
    _lastRendered = code;
    // Escape backticks and backslashes for JS template literal
    final escaped = code.replaceAll('\\', '\\\\').replaceAll('`', '\\`');
    _controller.runJavaScript('renderDiagram(`$escaped`)');
  }

  void _onBridgeMessage(JavaScriptMessage msg) {
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      final ds = context.read<DiagramState>();
      switch (data['type'] as String? ?? '') {
        case 'dblclick':
          _showRenameDialog(
            data['id'] as String? ?? '',
            data['label'] as String? ?? '',
          );
        case 'select':
          final id = data['id'] as String? ?? '';
          final lbl = data['label'] as String? ?? '';
          if (_connectingFromId != null) {
            ds.addEdge(_connectingFromId!, id);
            setState(() { _connectingFromId = null; _selectedNodeId = null; _selectedNodeLabel = null; });
          } else {
            setState(() { _selectedNodeId = id; _selectedNodeLabel = lbl; });
          }
        case 'deselect':
          setState(() { _selectedNodeId = null; _selectedNodeLabel = null; _connectingFromId = null; });
        case 'syntaxOk':
          ds.confirmCodeValid();
        case 'syntaxError':
          ds.reportSyntaxError(data['msg'] as String? ?? 'Syntax error');
      }
    } catch (_) {}
  }

  void _showRenameDialog(String nodeId, String currentLabel) {
    final ctrl = TextEditingController(text: currentLabel);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Rename node',
            style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTypography.bodyMd,
          decoration: InputDecoration(
            hintText: 'New label',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newLabel = ctrl.text.trim();
              if (newLabel.isNotEmpty && newLabel != currentLabel) {
                context.read<DiagramState>().renameNode(nodeId, newLabel);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showAddNodeDialog() {
    final idCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Add Node',
            style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              autofocus: true,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: 'Node ID (e.g. ec2)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: labelCtrl,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: 'Label (e.g. EC2 Instance)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final id = idCtrl.text.trim().replaceAll(' ', '_');
              final label = labelCtrl.text.trim();
              if (id.isNotEmpty && label.isNotEmpty) {
                context.read<DiagramState>().addNodeWithParent(
                  id: id,
                  label: label,
                  type: NodeType.resource,
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddEdgeDialog() {
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Add Connection',
            style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromCtrl,
              autofocus: true,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: 'From ID',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: toCtrl,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: 'To ID',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: labelCtrl,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: 'Label (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final from = fromCtrl.text.trim();
              final to = toCtrl.text.trim();
              final lbl = labelCtrl.text.trim();
              if (from.isNotEmpty && to.isNotEmpty) {
                context
                    .read<DiagramState>()
                    .addEdge(from, to, label: lbl.isEmpty ? null : lbl);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagramState>(
      builder: (context, st, child) {
        // Push updated code into WebView whenever it changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _renderCode(st.mermaidCode);
        });

        return DragTarget<ResourceTemplate>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            final label = details.data.label;
            final id = label
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]'), '_') +
                '_${DateTime.now().millisecondsSinceEpoch % 1000}';
            st.addNodeWithParent(
              id: id,
              label: label,
              type: NodeType.resource,
              iconPath: details.data.path,
            );
          },
          builder: (context, candidateData, rejectedData) {
            final isDragging = candidateData.isNotEmpty;
            return Stack(
              children: [
                // WebView fills the center
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    border: isDragging
                        ? Border.all(
                            color: AppColors.primary.withAlpha(120),
                            width: 2)
                        : null,
                  ),
                  child: WebViewWidget(controller: _controller),
                ),

                // Drag-drop hint overlay
                if (isDragging)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Drop to add node',
                            style: AppTypography.bodyMd.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),

                // Node action bar (above toolbar)
                if (_connectingFromId != null)
                  Positioned(
                    bottom: 72,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildConnectHint()),
                  )
                else if (_selectedNodeId != null)
                  Positioned(
                    bottom: 72,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildNodeActionBar(st)),
                  ),

                // Floating toolbar
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildToolbar(st)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNodeActionBar(DiagramState st) {
    final label = (_selectedNodeLabel ?? _selectedNodeId ?? '')
        .characters
        .take(20)
        .toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radio_button_checked, size: 10, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: AppTypography.code.copyWith(
                  fontSize: 11, color: AppColors.onSurface)),
          const SizedBox(width: 10),
          _ActionBtn(Icons.edit_outlined, 'Rename', () {
            _showRenameDialog(_selectedNodeId!, _selectedNodeLabel ?? '');
            setState(() { _selectedNodeId = null; _selectedNodeLabel = null; });
          }),
          const SizedBox(width: 4),
          _ActionBtn(Icons.cable_outlined, 'Connect', () {
            setState(() {
              _connectingFromId = _selectedNodeId;
              _selectedNodeId = null;
              _selectedNodeLabel = null;
            });
          }),
          const SizedBox(width: 4),
          _ActionBtn(Icons.delete_outline, 'Delete', () {
            st.deleteNode(_selectedNodeId!);
            setState(() { _selectedNodeId = null; _selectedNodeLabel = null; });
          }, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildConnectHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cable_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text('Click a node to connect from "$_connectingFromId"',
              style: AppTypography.code.copyWith(fontSize: 11, color: Colors.white)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() { _connectingFromId = null; }),
            child: const Icon(Icons.close, size: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(DiagramState st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolBtn(
            icon: Icons.add_box_outlined,
            label: 'Add Node',
            onTap: _showAddNodeDialog,
          ),
          const SizedBox(width: 2),
          _ToolBtn(
            icon: Icons.account_tree_outlined,
            label: 'Add Connection',
            onTap: _showAddEdgeDialog,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: AppColors.outlineVariant),
          const SizedBox(width: 8),
          _ToolBtn(
            icon: Icons.delete_outline,
            label: 'Clear diagram',
            danger: true,
            onTap: st.clearDiagram,
          ),
        ],
      ),
    );
  }
}

// ── Node action button ────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn(this.icon, this.tooltip, this.onTap,
      {this.color = AppColors.onSurfaceVariant});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      );
}

// ── Tool button ───────────────────────────────────────────────────────────────

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.onSurfaceVariant;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
