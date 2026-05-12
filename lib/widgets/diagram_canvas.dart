import 'dart:convert';
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/diagram_exporter.dart';
import 'package:diagram_flow_ai/models/diagram_node.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/diagram_viewport.dart';
import 'package:diagram_flow_ai/models/gallery_controller.dart';
import 'package:diagram_flow_ai/models/mermaid_validator.dart';
import 'package:diagram_flow_ai/widgets/template_gallery.dart';
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
    html, body { width: 100%; height: 100%; }

    /* Dark theme tokens (default) */
    body {
      --bg: #0B1326;
      --fg: #DAE2FD;
      --node-fill: #171F33;
      --node-stroke: #464554;
      --edge: #C0C1FF;
      --cluster-label: #7BD0FF;
      --err-bg: #331717;
      --err-fg: #FFB4AB;
    }
    /* Light theme overrides */
    body.theme-light {
      --bg: #F7F8FB;
      --fg: #12172A;
      --node-fill: #FFFFFF;
      --node-stroke: #CBD0DD;
      --edge: #4A4DCC;
      --cluster-label: #0288D1;
      --err-bg: #FCE8E6;
      --err-fg: #B3261E;
    }

    body { background: var(--bg); color: var(--fg); overflow: auto; font-family: sans-serif; }
    body.pan-mode { cursor: grab; }
    body.pan-mode.panning { cursor: grabbing; }
    body.pan-mode .node, body.pan-mode .edgePath { pointer-events: none; }
    #diagram { padding: 32px; min-height: 100vh; display: flex; justify-content: center; transform-origin: top left; transition: transform 60ms linear; }
    svg { max-width: none; height: auto; }

    /* Background for foreignObject / edgeLabel containers — Mermaid handles
       the rest via themeVariables passed to initialize(). */
    .edgeLabel { background-color: var(--bg) !important; color: var(--fg) !important; }
    foreignObject div { color: var(--fg); }

    #error-msg {
      display: none;
      background: var(--err-bg);
      border-left: 3px solid var(--err-fg);
      color: var(--err-fg);
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
  <div id="diagram" class="mermaid" tabindex="0">flowchart TD
    A[Start] --> B[End]</div>
  <div id="error-msg"></div>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
  <script>
    // Two complete palettes for Mermaid's `base` theme. `themeVariables`
    // controls every color Mermaid generates — including segment palettes
    // for treemap, pie, sankey, xychart that CSS overrides can't reach.
    const DARK_VARS = {
      darkMode: true,
      background: '#0B1326',
      mainBkg: '#171F33',
      primaryColor: '#171F33',
      primaryTextColor: '#DAE2FD',
      primaryBorderColor: '#464554',
      secondaryColor: '#2D3449',
      secondaryTextColor: '#DAE2FD',
      secondaryBorderColor: '#464554',
      tertiaryColor: '#171F33',
      tertiaryTextColor: '#DAE2FD',
      tertiaryBorderColor: '#464554',
      lineColor: '#C0C1FF',
      textColor: '#DAE2FD',
      titleColor: '#DAE2FD',
      nodeBkg: '#171F33',
      nodeBorder: '#464554',
      nodeTextColor: '#DAE2FD',
      clusterBkg: '#1A2238',
      clusterBorder: '#7BD0FF',
      edgeLabelBackground: '#0B1326',
      // Multi-segment palette (pie/treemap/sankey use pie1..pie12)
      pie1: '#C0C1FF', pie2: '#7BD0FF', pie3: '#FFB4AB', pie4: '#B6E0A0',
      pie5: '#FFD180', pie6: '#D5A6FF', pie7: '#FF9FB1', pie8: '#91DDFF',
      pie9: '#BBE5A2', pie10: '#FFCC80', pie11: '#A0D8FF', pie12: '#E5BBA0',
      pieTitleTextColor: '#DAE2FD',
      pieSectionTextColor: '#0B1326',
      pieLegendTextColor: '#DAE2FD',
      pieStrokeColor: '#0B1326',
      pieOuterStrokeColor: '#464554',
      // Quadrant
      quadrant1Fill: '#1A2238', quadrant2Fill: '#1A2238',
      quadrant3Fill: '#1A2238', quadrant4Fill: '#1A2238',
      quadrantTitleFill: '#DAE2FD', quadrantPointFill: '#C0C1FF',
      quadrantPointTextFill: '#DAE2FD', quadrantXAxisTextFill: '#C7C4D7',
      quadrantYAxisTextFill: '#C7C4D7', quadrantInternalBorderStrokeFill: '#464554',
      quadrantExternalBorderStrokeFill: '#7BD0FF',
      // XY chart
      xyChart: { backgroundColor: '#0B1326', titleColor: '#DAE2FD',
        xAxisLabelColor: '#C7C4D7', yAxisLabelColor: '#C7C4D7',
        plotColorPalette: '#C0C1FF,#7BD0FF,#FFB4AB,#B6E0A0,#FFD180' },
      // Git
      git0: '#C0C1FF', git1: '#7BD0FF', git2: '#FFB4AB', git3: '#B6E0A0',
      git4: '#FFD180', git5: '#D5A6FF', git6: '#FF9FB1', git7: '#91DDFF',
      gitBranchLabel0: '#0B1326', gitBranchLabel1: '#0B1326',
      gitBranchLabel2: '#0B1326', gitBranchLabel3: '#0B1326',
    };

    const LIGHT_VARS = {
      darkMode: false,
      background: '#F7F8FB',
      mainBkg: '#FFFFFF',
      primaryColor: '#FFFFFF',
      primaryTextColor: '#12172A',
      primaryBorderColor: '#CBD0DD',
      secondaryColor: '#EEF1F7',
      secondaryTextColor: '#12172A',
      secondaryBorderColor: '#CBD0DD',
      tertiaryColor: '#FFFFFF',
      tertiaryTextColor: '#12172A',
      tertiaryBorderColor: '#CBD0DD',
      lineColor: '#4A4DCC',
      textColor: '#12172A',
      titleColor: '#12172A',
      nodeBkg: '#FFFFFF',
      nodeBorder: '#CBD0DD',
      nodeTextColor: '#12172A',
      clusterBkg: '#EEF1F7',
      clusterBorder: '#0288D1',
      edgeLabelBackground: '#FFFFFF',
      // Saturated palette that pops on white
      pie1: '#4A4DCC', pie2: '#0288D1', pie3: '#B3261E', pie4: '#2E7D32',
      pie5: '#E65100', pie6: '#6A1B9A', pie7: '#C2185B', pie8: '#00838F',
      pie9: '#558B2F', pie10: '#BF360C', pie11: '#1565C0', pie12: '#AD1457',
      pieTitleTextColor: '#12172A',
      pieSectionTextColor: '#FFFFFF',
      pieLegendTextColor: '#12172A',
      pieStrokeColor: '#FFFFFF',
      pieOuterStrokeColor: '#CBD0DD',
      quadrant1Fill: '#EEF1F7', quadrant2Fill: '#EEF1F7',
      quadrant3Fill: '#EEF1F7', quadrant4Fill: '#EEF1F7',
      quadrantTitleFill: '#12172A', quadrantPointFill: '#4A4DCC',
      quadrantPointTextFill: '#FFFFFF', quadrantXAxisTextFill: '#555A6E',
      quadrantYAxisTextFill: '#555A6E', quadrantInternalBorderStrokeFill: '#CBD0DD',
      quadrantExternalBorderStrokeFill: '#0288D1',
      xyChart: { backgroundColor: '#FFFFFF', titleColor: '#12172A',
        xAxisLabelColor: '#555A6E', yAxisLabelColor: '#555A6E',
        plotColorPalette: '#4A4DCC,#0288D1,#B3261E,#2E7D32,#E65100' },
      git0: '#4A4DCC', git1: '#0288D1', git2: '#B3261E', git3: '#2E7D32',
      git4: '#E65100', git5: '#6A1B9A', git6: '#C2185B', git7: '#00838F',
      gitBranchLabel0: '#FFFFFF', gitBranchLabel1: '#FFFFFF',
      gitBranchLabel2: '#FFFFFF', gitBranchLabel3: '#FFFFFF',
    };

    function initMermaid(isDark) {
      mermaid.initialize({
        startOnLoad: false,
        theme: 'base',
        themeVariables: isDark ? DARK_VARS : LIGHT_VARS,
        securityLevel: 'loose',
        htmlLabels: true,
        flowchart: { curve: 'step', useMaxWidth: true }
      });
    }

    initMermaid(true); // default dark; Dart pushes correct theme on page load
    mermaid.run({ nodes: [document.getElementById('diagram')] });

    let _currentDiagramSource = null;
    window.setTheme = function(isDark) {
      document.body.classList.toggle('theme-light', !isDark);
      initMermaid(isDark);
      const source = _currentDiagramSource;
      if (source) renderDiagram(source);
    };

    // ── Viewport (zoom + pan) ────────────────────────────────────────────
    window.__viewport = (function() {
      const diagram = document.getElementById('diagram');
      let zoom = 1.0;
      let panMode = false;     // toggled by button
      let spaceHeld = false;   // transient (hold-space)
      let panning = false;
      let startX = 0, startY = 0, startScrollX = 0, startScrollY = 0;

      function effectivePan() { return panMode || spaceHeld; }

      function syncPanCursor() {
        const ep = effectivePan();
        document.body.classList.toggle('pan-mode', ep);
        if (!ep) {
          panning = false;
          document.body.classList.remove('panning');
        }
      }

      function apply(z, p) {
        zoom = z;
        panMode = p;
        diagram.style.transform = 'scale(' + z + ')';
        syncPanCursor();
      }

      window.addEventListener('mousedown', function(e) {
        if (!effectivePan()) return;
        panning = true;
        startX = e.clientX;
        startY = e.clientY;
        startScrollX = window.scrollX;
        startScrollY = window.scrollY;
        document.body.classList.add('panning');
        e.preventDefault();
      }, true);

      window.addEventListener('mousemove', function(e) {
        if (!panning) return;
        window.scrollTo(startScrollX - (e.clientX - startX), startScrollY - (e.clientY - startY));
      }, true);

      window.addEventListener('mouseup', function() {
        if (!panning) return;
        panning = false;
        document.body.classList.remove('panning');
      }, true);

      window.addEventListener('keydown', function(e) {
        if (e.code === 'Space' && !e.repeat) {
          spaceHeld = true;
          syncPanCursor();
          e.preventDefault();
        } else if (e.altKey && (e.code === 'Equal' || e.code === 'NumpadAdd')) {
          DiagramBridge.postMessage(JSON.stringify({type: 'viewportZoomIn'}));
          e.preventDefault();
        } else if (e.altKey && (e.code === 'Minus' || e.code === 'NumpadSubtract')) {
          DiagramBridge.postMessage(JSON.stringify({type: 'viewportZoomOut'}));
          e.preventDefault();
        }
      });

      window.addEventListener('keyup', function(e) {
        if (e.code === 'Space') {
          spaceHeld = false;
          syncPanCursor();
        }
      });

      let wheelAccum = 0;
      window.addEventListener('wheel', function(e) {
        e.preventDefault();
        wheelAccum += e.deltaY;
        if (wheelAccum <= -50) {
          DiagramBridge.postMessage(JSON.stringify({type: 'viewportZoomIn'}));
          wheelAccum = 0;
        } else if (wheelAccum >= 50) {
          DiagramBridge.postMessage(JSON.stringify({type: 'viewportZoomOut'}));
          wheelAccum = 0;
        }
      }, { passive: false });

      return { apply: apply };
    })();

    async function validateMermaid(code, requestId) {
      try {
        await mermaid.parse(code);
        DiagramBridge.postMessage(JSON.stringify({type: 'validateResult', id: requestId, ok: true}));
      } catch(e) {
        DiagramBridge.postMessage(JSON.stringify({type: 'validateResult', id: requestId, ok: false, error: String(e)}));
      }
    }

    async function renderDiagram(code) {
      const el = document.getElementById('diagram');
      const errEl = document.getElementById('error-msg');
      _currentDiagramSource = code;
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
  VoidCallback? _themeListener;
  String _lastRendered = '';
  String? _selectedNodeId;
  String? _selectedNodeLabel;
  String? _connectingFromId;
  bool _connectMode = false;
  VoidCallback? _autoCloseListener;

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
          // Push current theme + code into the page after it loads.
          final isDark = context.read<ThemeController>().isDark;
          _controller.runJavaScript('setTheme($isDark)');
          final code = context.read<DiagramState>().mermaidCode;
          _renderCode(code);
        },
      ))
      ..loadHtmlString(_buildMermaidHtml());
    context.read<DiagramExporter>().attach(_controller);
    context.read<DiagramViewport>().attach(_controller);
    context.read<MermaidValidator>().attach(_controller);

    // Push theme changes into the WebView so the Mermaid diagram swaps
    // colors and re-renders to match the rest of the app.
    final theme = context.read<ThemeController>();
    _themeListener = () {
      if (!_webViewReady) return;
      _controller.runJavaScript('setTheme(${theme.isDark})');
    };
    theme.addListener(_themeListener!);

    final ds = context.read<DiagramState>();
    final gallery = context.read<GalleryController>();
    _autoCloseListener = () {
      if (!mounted) return;
      final hasContent = ds.nodes.isNotEmpty || ds.edges.isNotEmpty;
      // Auto-close when something gets drawn on the canvas.
      if (gallery.isOpen && hasContent) {
        gallery.close();
        return;
      }
      // Auto-reopen on a fresh state (newProject): empty + no file + clean.
      if (!gallery.isOpen &&
          !hasContent &&
          !ds.isDirty &&
          ds.currentFilePath == null) {
        gallery.open();
      }
    };
    ds.addListener(_autoCloseListener!);
  }

  @override
  void dispose() {
    if (_autoCloseListener != null) {
      try {
        context.read<DiagramState>().removeListener(_autoCloseListener!);
      } catch (_) {}
    }
    if (_themeListener != null) {
      try {
        context.read<ThemeController>().removeListener(_themeListener!);
      } catch (_) {}
    }
    super.dispose();
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
      if (context.read<DiagramExporter>().handleBridgeMessage(data)) return;
      if (context.read<MermaidValidator>().handleBridgeMessage(data)) return;
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
            if (id != _connectingFromId) ds.addEdge(_connectingFromId!, id);
            setState(() {
              if (_connectMode) {
                // In sticky connect mode, chain: target becomes next source.
                _connectingFromId = id;
                _selectedNodeId = null;
                _selectedNodeLabel = null;
              } else {
                _connectingFromId = null;
                _selectedNodeId = null;
                _selectedNodeLabel = null;
              }
            });
          } else if (_connectMode) {
            setState(() {
              _connectingFromId = id;
              _selectedNodeId = null;
              _selectedNodeLabel = null;
            });
          } else {
            setState(() { _selectedNodeId = id; _selectedNodeLabel = lbl; });
          }
        case 'deselect':
          setState(() {
            _selectedNodeId = null;
            _selectedNodeLabel = null;
            if (!_connectMode) _connectingFromId = null;
          });
        case 'syntaxOk':
          ds.confirmCodeValid();
        case 'syntaxError':
          ds.reportSyntaxError(data['msg'] as String? ?? 'Syntax error');
        case 'viewportZoomIn':
          context.read<DiagramViewport>().zoomIn();
        case 'viewportZoomOut':
          context.read<DiagramViewport>().zoomOut();
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

        return Stack(
          children: [
            WebViewWidget(controller: _controller),

            if (_connectingFromId != null || _connectMode)
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

            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(child: _buildToolbar(st)),
            ),

            Consumer<GalleryController>(
              builder: (_, gc, _) => gc.isOpen
                  ? Positioned.fill(
                      child: TemplateGallery(onDismiss: gc.close),
                    )
                  : const SizedBox.shrink(),
            ),

            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(child: _StreamingBanner()),
            ),
          ],
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
    final hasSource = _connectingFromId != null;
    final msg = hasSource
        ? 'Click a node to connect from "$_connectingFromId"'
        : 'Connect Mode: click the source node';
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
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
          Flexible(
            child: Text(
              msg,
              style: AppTypography.code.copyWith(fontSize: 11, color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() {
              _connectingFromId = null;
              _connectMode = false;
            }),
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
          Consumer<GalleryController>(
            builder: (_, gc, _) => _ToolBtn(
              icon: Icons.bolt_outlined,
              label: 'Templates gallery (⌘T)',
              active: gc.isOpen,
              onTap: gc.toggle,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: AppColors.outlineVariant),
          const SizedBox(width: 8),
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
            icon: Icons.cable_outlined,
            label: _connectMode
                ? 'Connect Mode ON · click pairs of nodes (Esc to exit)'
                : 'Connect Mode · click pairs of nodes to chain edges',
            active: _connectMode,
            onTap: () => setState(() {
              _connectMode = !_connectMode;
              _connectingFromId = null;
              _selectedNodeId = null;
              _selectedNodeLabel = null;
            }),
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
  final Color? color;

  const _ActionBtn(this.icon, this.tooltip, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 15, color: color ?? AppColors.onSurfaceVariant),
          ),
        ),
      );
}

// ── Tool button ───────────────────────────────────────────────────────────────

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final bool active;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : (danger ? AppColors.error : AppColors.onSurfaceVariant);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withAlpha(40) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ── Streaming banner ──────────────────────────────────────────────────────────

class _StreamingBanner extends StatefulWidget {
  const _StreamingBanner();

  @override
  State<_StreamingBanner> createState() => _StreamingBannerState();
}

class _StreamingBannerState extends State<_StreamingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIModelState>(
      builder: (_, ai, _) {
        if (!ai.isStreaming) return const SizedBox.shrink();
        final phase = ai.streamPhase;
        final retrying = ai.isRetrying;
        final phaseLabel = retrying
            ? 'Fixing parse error · attempt ${ai.currentAttempt}/${ai.maxAttempts}'
            : phase == StreamPhase.thinking
                ? 'Gemma is reasoning'
                : 'Gemma is generating diagram';
        final elapsed = ai.streamStartedAt == null
            ? null
            : DateTime.now().difference(ai.streamStartedAt!);
        final secs =
            elapsed == null ? '' : (elapsed.inMilliseconds / 1000).toStringAsFixed(1);

        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final t = _pulse.value;
            return Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withAlpha((100 + 80 * t).round())),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withAlpha((40 + 40 * t).round()),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                      color: Colors.black.withAlpha(60), blurRadius: 12),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    retrying
                        ? Icons.healing_outlined
                        : phase == StreamPhase.thinking
                            ? Icons.psychology_outlined
                            : Icons.auto_awesome,
                    size: 14,
                    color: retrying ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      phaseLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                          fontSize: 12,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _AnimatedDots(controller: _pulse),
                  const SizedBox(width: 12),
                  Text(
                    '${ai.streamedTokens} tok · ${secs}s',
                    style: AppTypography.code.copyWith(
                        fontSize: 10, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final phase = (controller.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final on = i == phase;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: on
                      ? AppColors.primary
                      : AppColors.primary.withAlpha(60),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
