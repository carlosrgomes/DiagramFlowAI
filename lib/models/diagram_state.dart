import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'diagram_node.dart';

class DiagramEdge {
  final String fromId;
  final String toId;
  final String? label;

  DiagramEdge({required this.fromId, required this.toId, this.label});
}

class DiagramState extends ChangeNotifier {
  static const _kInitialHeader = 'flowchart TD';

  final Map<String, DiagramNode> _nodes = {};
  final List<DiagramEdge> _edges = [];
  final Map<String, String> _iconBase64Cache = {};
  
  String _code = '$_kInitialHeader\n    A["Start"] --> B["End"]';
  String _lastGoodCode = '$_kInitialHeader\n    A["Start"] --> B["End"]';
  String? _syntaxError;

  String get mermaidCode => _code;
  String? get syntaxError => _syntaxError;
  Map<String, DiagramNode> get nodes => Map.unmodifiable(_nodes);
  List<DiagramEdge> get edges => List.unmodifiable(_edges);

  DiagramState() {
    // Initialize
  }

  void setCode(String code) {
    if (code == _code) return;
    _code = code;
    _syntaxError = null;
    notifyListeners();
  }

  void confirmCodeValid() {
    _lastGoodCode = _code;
    _syntaxError = null;
  }

  void reportSyntaxError(String error) {
    _code = _lastGoodCode;
    _syntaxError = error;
    notifyListeners();
  }

  void clearDiagram() {
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
  }) async {
    final sanitizedId = _sanitizeId(id);
    final sanitizedParentId = parentId != null ? _sanitizeId(parentId) : null;

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
      label: label,
      type: type,
      parentId: sanitizedParentId,
      iconPath: iconPath == 'null' ? null : iconPath,
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

    _nodes[sanitizedId] = DiagramNode(
      id: sanitizedId,
      label: newLabel,
      type: oldNode.type,
      parentId: oldNode.parentId,
      iconPath: oldNode.iconPath,
    );
    _rebuildMermaidCode();
  }

  void addEdge(String fromId, String toId, {String? label}) {
    _edges.add(DiagramEdge(
      fromId: _sanitizeId(fromId),
      toId: _sanitizeId(toId),
      label: label,
    ));
    _rebuildMermaidCode();
  }

  void deleteNode(String nodeId) {
    final sanitizedId = _sanitizeId(nodeId);
    _nodes.remove(sanitizedId);
    _edges.removeWhere((edge) => edge.fromId == sanitizedId || edge.toId == sanitizedId);
    _rebuildMermaidCode();
  }

  void rebuild() {
    _rebuildMermaidCode();
  }

  String _sanitizeId(String id) {
    return id.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
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
    } else {
      buffer.writeln('$indent${node.id}["${node.label}"]');
    }
  }
}
