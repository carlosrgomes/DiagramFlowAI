import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'diagram_node.dart';

class DiagramEdge {
  final String fromId;
  final String toId;
  final String? label;

  DiagramEdge({required this.fromId, required this.toId, this.label});
}

class _Snapshot {
  final Map<String, DiagramNode> nodes;
  final List<DiagramEdge> edges;
  final String code;
  _Snapshot(this.nodes, this.edges, this.code);
}

class DiagramState extends ChangeNotifier {
  static const _kInitialHeader = 'flowchart TD';
  static const _kHistoryLimit = 50;

  final Map<String, DiagramNode> _nodes = {};
  final List<DiagramEdge> _edges = [];
  final Map<String, String> _iconBase64Cache = {};

  String _code = '$_kInitialHeader\n    A["Start"] --> B["End"]';
  String _lastGoodCode = '$_kInitialHeader\n    A["Start"] --> B["End"]';
  String? _syntaxError;

  final List<_Snapshot> _undoStack = [];
  final List<_Snapshot> _redoStack = [];

  String? _currentFilePath;
  bool _dirty = false;
  String? _savedSignature;

  String get mermaidCode => _code;
  String? get syntaxError => _syntaxError;
  Map<String, DiagramNode> get nodes => Map.unmodifiable(_nodes);
  List<DiagramEdge> get edges => List.unmodifiable(_edges);
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  String? get currentFilePath => _currentFilePath;
  bool get isDirty => _dirty;

  DiagramState() {
    _savedSignature = _signature();
  }

  void setCode(String code) {
    if (code == _code) return;
    dev.log('========== setCode (${code.length} chars) ==========', name: 'CFAI');
    final numbered = code.split('\n').asMap().entries
        .map((e) => '${(e.key + 1).toString().padLeft(3)}: ${e.value}')
        .join('\n');
    dev.log('\n$numbered', name: 'CFAI.setCode');
    _code = code;
    _syntaxError = null;
    _markDirty();
    notifyListeners();
  }

  void confirmCodeValid() {
    dev.log('Mermaid parsed OK', name: 'CFAI');
    _lastGoodCode = _code;
    _syntaxError = null;
  }

  void reportSyntaxError(String error) {
    dev.log('========== Mermaid PARSE ERROR ==========', name: 'CFAI');
    dev.log(error, name: 'CFAI.parseError');
    _code = _lastGoodCode;
    _syntaxError = error;
    notifyListeners();
  }

  void clearDiagram() {
    _pushSnapshot();
    _nodes.clear();
    _edges.clear();
    _iconBase64Cache.clear();
    addNodeWithParent(id: 'A', label: 'Start', type: NodeType.resource);
  }

  void clearDiagramNoRebuild() {
    _nodes.clear();
    _edges.clear();
  }

  Future<void> addNodeWithParent({
    required String id,
    required String label,
    required NodeType type,
    String? parentId,
    String? iconPath,
    String shape = 'rect',
    bool snapshot = true,
  }) async {
    if (snapshot) _pushSnapshot();
    final sanitizedId = _sanitizeId(id);
    final sanitizedParentId = parentId != null ? _sanitizeId(parentId) : null;
    final sanitizedLabel = _sanitizeLabel(label);

    if (iconPath != null && iconPath != 'null' && !_iconBase64Cache.containsKey(iconPath)) {
      try {
        final data = await rootBundle.load(iconPath);
        final bytes = data.buffer.asUint8List();
        _iconBase64Cache[iconPath] = base64Encode(bytes);
      } catch (e) {
        debugPrint('Error loading icon $iconPath: $e');
      }
    }

    _nodes[sanitizedId] = DiagramNode(
      id: sanitizedId,
      label: sanitizedLabel,
      type: type,
      parentId: sanitizedParentId,
      iconPath: iconPath == 'null' ? null : iconPath,
      shape: shape,
    );
    _rebuildMermaidCode();
  }

  void addNode(String id, String label, {String shape = 'rect'}) {
    addNodeWithParent(id: id, label: label, type: NodeType.resource);
  }

  void renameNode(String id, String newLabel) {
    final sanitizedId = _sanitizeId(id);
    final oldNode = _nodes[sanitizedId];
    if (oldNode == null) return;
    _pushSnapshot();
    _nodes[sanitizedId] = DiagramNode(
      id: sanitizedId,
      label: _sanitizeLabel(newLabel),
      type: oldNode.type,
      parentId: oldNode.parentId,
      iconPath: oldNode.iconPath,
      shape: oldNode.shape,
    );
    _rebuildMermaidCode();
  }

  void addEdge(String fromId, String toId, {String? label, bool snapshot = true}) {
    if (snapshot) _pushSnapshot();
    _edges.add(DiagramEdge(
      fromId: _sanitizeId(fromId),
      toId: _sanitizeId(toId),
      label: label != null ? _sanitizeLabel(label) : null,
    ));
    _rebuildMermaidCode();
  }

  void deleteNode(String nodeId) {
    _pushSnapshot();
    final sanitizedId = _sanitizeId(nodeId);
    _nodes.remove(sanitizedId);
    _edges.removeWhere((edge) => edge.fromId == sanitizedId || edge.toId == sanitizedId);
    _rebuildMermaidCode();
  }

  void rebuild() {
    _rebuildMermaidCode();
  }

  // ── History (undo/redo) ──────────────────────────────────────────────────

  /// Public boundary for callers (e.g. AI apply, drag-drop) that perform a
  /// burst of mutations and want a single Undo step instead of N.
  void pushSnapshot() => _pushSnapshot();

  void _pushSnapshot() {
    _undoStack.add(_takeSnapshot());
    if (_undoStack.length > _kHistoryLimit) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  _Snapshot _takeSnapshot() {
    final nodesCopy = <String, DiagramNode>{};
    _nodes.forEach((k, v) {
      nodesCopy[k] = DiagramNode(
        id: v.id, label: v.label, type: v.type,
        parentId: v.parentId, iconPath: v.iconPath, shape: v.shape,
      );
    });
    final edgesCopy = _edges
        .map((e) => DiagramEdge(fromId: e.fromId, toId: e.toId, label: e.label))
        .toList();
    return _Snapshot(nodesCopy, edgesCopy, _code);
  }

  void _restoreSnapshot(_Snapshot snap) {
    _nodes
      ..clear()
      ..addAll(snap.nodes);
    _edges
      ..clear()
      ..addAll(snap.edges);
    _code = snap.code;
    _lastGoodCode = snap.code;
    _syntaxError = null;
    _markDirty();
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_takeSnapshot());
    _restoreSnapshot(_undoStack.removeLast());
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_takeSnapshot());
    _restoreSnapshot(_redoStack.removeLast());
  }

  // ── Project IO + dirty tracking ──────────────────────────────────────────

  String _signature() {
    // Compact representation used to detect "clean vs dirty" without storing
    // a full snapshot. Includes the structural state, not transient flags.
    final nodeSig = _nodes.values.map((n) =>
        '${n.id}|${n.label}|${n.type.name}|${n.parentId ?? ""}|${n.iconPath ?? ""}|${n.shape}').join(';');
    final edgeSig = _edges.map((e) =>
        '${e.fromId}|${e.toId}|${e.label ?? ""}').join(';');
    return '$_code$nodeSig$edgeSig';
  }

  void _markDirty() {
    final sig = _signature();
    final newDirty = sig != _savedSignature;
    if (newDirty != _dirty) _dirty = newDirty;
  }

  void markSaved(String path) {
    _currentFilePath = path;
    _savedSignature = _signature();
    _dirty = false;
    notifyListeners();
  }

  void loadFromPayload(
    Iterable<DiagramNode> newNodes,
    Iterable<DiagramEdge> newEdges,
    String newCode, {
    String? path,
  }) {
    _undoStack.clear();
    _redoStack.clear();
    _nodes.clear();
    _edges.clear();
    _iconBase64Cache.clear();
    for (final n in newNodes) {
      _nodes[n.id] = n;
    }
    _edges.addAll(newEdges);
    _code = newCode;
    _lastGoodCode = newCode;
    _syntaxError = null;
    _currentFilePath = path;
    _savedSignature = _signature();
    _dirty = false;
    notifyListeners();
  }

  void newProject() {
    _undoStack.clear();
    _redoStack.clear();
    _nodes.clear();
    _edges.clear();
    _iconBase64Cache.clear();
    _code = '$_kInitialHeader\n    A["Start"] --> B["End"]';
    _lastGoodCode = _code;
    _syntaxError = null;
    _currentFilePath = null;
    _savedSignature = _signature();
    _dirty = false;
    notifyListeners();
  }

  String _sanitizeId(String id) {
    return id.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  String _sanitizeLabel(String label) {
    // Remove Markdown bold markers
    return label.replaceAll('**', '').trim();
  }

  void _rebuildMermaidCode() {
    final buffer = StringBuffer();
    buffer.writeln(_kInitialHeader);

    final Map<String?, List<DiagramNode>> childrenByParent = {};
    for (var node in _nodes.values) {
      childrenByParent.putIfAbsent(node.parentId, () => []).add(node);
    }

    _writeChildren(buffer, null, childrenByParent, '');

    for (var edge in _edges) {
      final arrow = edge.label != null && edge.label!.isNotEmpty 
          ? '-->|${edge.label}|' 
          : '-->';
      buffer.writeln('    ${edge.fromId} $arrow ${edge.toId}');
    }

    _code = buffer.toString().trimRight();
    _markDirty();
    notifyListeners();
  }

  void _writeChildren(StringBuffer buffer, String? parentId, Map<String?, List<DiagramNode>> childrenByParent, String indent) {
    final children = childrenByParent[parentId];
    if (children == null) return;

    for (var child in children) {
      if (child.type == NodeType.group) {
        buffer.writeln('$indent    subgraph ${child.id} ["${child.label}"]');
        _writeChildren(buffer, child.id, childrenByParent, '$indent    ');
        buffer.writeln('$indent    end');
      } else {
        _writeNode(buffer, child, indent: '$indent    ');
      }
    }
  }

  void _writeNode(StringBuffer buffer, DiagramNode node, {String indent = '    '}) {
    if (node.type == NodeType.resource && node.iconPath != null && _iconBase64Cache.containsKey(node.iconPath)) {
      final b64 = _iconBase64Cache[node.iconPath];
      final safeLabel = node.label.replaceAll('"', '&quot;');
      final html = '<div style="text-align:center; padding: 10px;"><img src="data:image/png;base64,$b64" width="48" height="48"/><br/><div style="margin-top:8px; font-weight:600; font-family: sans-serif;">$safeLabel</div></div>';
      buffer.writeln('$indent${node.id}["$html"]');
      return;
    }

    final escaped = node.label.replaceAll('"', r'\"');
    if (node.shape == 'rect') {
      buffer.writeln('$indent${node.id}["$escaped"]');
    } else {
      // Mermaid v11 shape syntax — covers all 30+ shapes uniformly.
      buffer.writeln('$indent${node.id}@{ shape: ${node.shape}, label: "$escaped" }');
    }
  }
}
