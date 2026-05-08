import 'package:flutter/material.dart';

class DiagramNode {
  final String id;
  final String label;
  final Offset position;

  DiagramNode({
    required this.id,
    required this.label,
    required this.position,
  });

  DiagramNode copyWith({
    Offset? position,
  }) {
    return DiagramNode(
      id: id,
      label: label,
      position: position ?? this.position,
    );
  }
}

class DiagramConnection {
  final String fromId;
  final String toId;

  DiagramConnection({required this.fromId, required this.toId});
}

class DiagramState extends ChangeNotifier {
  final List<DiagramNode> _nodes = [];
  final List<DiagramConnection> _connections = [];

  List<DiagramNode> get nodes => List.unmodifiable(_nodes);
  List<DiagramConnection> get connections => List.unmodifiable(_connections);

  void addNode({
    required String id,
    required String label,
    required Offset position,
  }) {
    _nodes.add(DiagramNode(id: id, label: label, position: position));
    notifyListeners();
  }

  void addConnection(String fromId, String toId) {
    // Basic validation: ensure both nodes exist
    final fromExists = _nodes.any((n) => n.id == fromId);
    final toExists = _nodes.any((n) => n.id == toId);
    
    if (fromExists && toExists) {
      _connections.add(DiagramConnection(fromId: fromId, toId: toId));
      notifyListeners();
    }
  }

  void updateNodePosition(String id, Offset newPosition) {
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index != -1) {
      _nodes[index] = _nodes[index].copyWith(position: newPosition);
      notifyListeners();
    }
  }

  void clearDiagram() {
    _nodes.clear();
    _connections.clear();
    notifyListeners();
  }
}
