import 'package:flutter/material.dart';
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
  
  String _code = '$_kInitialHeader\n    A[Start] --> B[End]';
  String _lastGoodCode = '$_kInitialHeader\n    A[Start] --> B[End]';
  String? _syntaxError;

  String get mermaidCode => _code;
  String? get syntaxError => _syntaxError;
  Map<String, DiagramNode> get nodes => Map.unmodifiable(_nodes);

  DiagramState() {
    // Initialize with default nodes to match initial code if needed, 
    // but for now we'll just let the first clear/add handle it.
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
    addNodeWithParent(id: 'A', label: 'Start', type: NodeType.resource);
  }

  void addNodeWithParent({
    required String id,
    required String label,
    required NodeType type,
    String? parentId,
  }) {
    _nodes[id] = DiagramNode(
      id: id,
      label: label,
      type: type,
      parentId: parentId,
    );
    _rebuildMermaidCode();
  }

  void addNode(String id, String label, {String shape = 'rect'}) {
    // Mapping old addNode to new structured model
    addNodeWithParent(id: id, label: label, type: NodeType.resource);
  }

  void addEdge(String fromId, String toId, {String? label}) {
    _edges.add(DiagramEdge(fromId: fromId, toId: toId, label: label));
    _rebuildMermaidCode();
  }

  void deleteNode(String nodeId) {
    _nodes.remove(nodeId);
    _edges.removeWhere((edge) => edge.fromId == nodeId || edge.toId == nodeId);
    _rebuildMermaidCode();
  }

  void _rebuildMermaidCode() {
    final buffer = StringBuffer();
    buffer.writeln(_kInitialHeader);

    // Group nodes by parentId
    final Map<String?, List<DiagramNode>> groupedNodes = {};
    for (var node in _nodes.values) {
      groupedNodes.putIfAbsent(node.parentId, () => []).add(node);
    }

    // First, write nodes without parents
    if (groupedNodes.containsKey(null)) {
      for (var node in groupedNodes[null]!) {
        _writeNode(buffer, node);
      }
    }

    // Then, write subgraphs for each parent
    for (var entry in groupedNodes.entries) {
      final parentId = entry.key;
      if (parentId == null) continue;

      final parentNode = _nodes[parentId];
      final label = parentNode?.label ?? parentId;
      
      buffer.writeln('    subgraph $parentId [$label]');
      for (var node in entry.value) {
        _writeNode(buffer, node, indent: '        ');
      }
      buffer.writeln('    end');
    }

    // Finally, write edges
    for (var edge in _edges) {
      final arrow = edge.label != null && edge.label!.isNotEmpty 
          ? '-->|${edge.label}|' 
          : '-->';
      buffer.writeln('    ${edge.fromId} $arrow ${edge.toId}');
    }

    _code = buffer.toString().trimRight();
    notifyListeners();
  }

  void _writeNode(StringBuffer buffer, DiagramNode node, {String indent = '    '}) {
    // For now, we use default rect shape for all. 
    // Future tracks will handle custom visual representations.
    buffer.writeln('$indent${node.id}[${node.label}]');
  }
}
