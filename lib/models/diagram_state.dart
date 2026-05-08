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

class DiagramState extends ChangeNotifier {
  final List<DiagramNode> _nodes = [];

  List<DiagramNode> get nodes => List.unmodifiable(_nodes);

  void addNode({
    required String id,
    required String label,
    required Offset position,
  }) {
    _nodes.add(DiagramNode(id: id, label: label, position: position));
    notifyListeners();
  }

  void updateNodePosition(String id, Offset newPosition) {
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index != -1) {
      _nodes[index] = _nodes[index].copyWith(position: newPosition);
      notifyListeners();
    }
  }
}
