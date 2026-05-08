import 'package:flutter/material.dart';

enum NodeAnchor {
  top,
  bottom,
  left,
  right,
  center,
}

class DiagramNode {
  final String id;
  final String label;
  final Offset position;
  final Size size; // Added size to handle border calculations

  DiagramNode({
    required this.id,
    required this.label,
    required this.position,
    this.size = const Size(120, 50), // Default node size
  });

  DiagramNode copyWith({
    Offset? position,
    Size? size,
  }) {
    return DiagramNode(
      id: id,
      label: label,
      position: position ?? this.position,
      size: size ?? this.size,
    );
  }

  Offset getAnchorPosition(NodeAnchor anchor) {
    switch (anchor) {
      case NodeAnchor.top:
        return position + Offset(size.width / 2, 0);
      case NodeAnchor.bottom:
        return position + Offset(size.width / 2, size.height);
      case NodeAnchor.left:
        return position + Offset(0, size.height / 2);
      case NodeAnchor.right:
        return position + Offset(size.width, size.height / 2);
      case NodeAnchor.center:
        return position + Offset(size.width / 2, size.height / 2);
    }
  }
}

class DiagramConnection {
  final String fromId;
  final String toId;
  final NodeAnchor fromAnchor;
  final NodeAnchor toAnchor;

  DiagramConnection({
    required this.fromId,
    required this.toId,
    this.fromAnchor = NodeAnchor.right,
    this.toAnchor = NodeAnchor.left,
  });
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
    Size size = const Size(120, 50),
  }) {
    _nodes.add(DiagramNode(id: id, label: label, position: position, size: size));
    notifyListeners();
  }

  void addConnection(String fromId, String toId, {NodeAnchor? fromAnchor, NodeAnchor? toAnchor}) {
    final fromExists = _nodes.any((n) => n.id == fromId);
    final toExists = _nodes.any((n) => n.id == toId);
    
    if (fromExists && toExists) {
      _connections.add(DiagramConnection(
        fromId: fromId, 
        toId: toId,
        fromAnchor: fromAnchor ?? NodeAnchor.right,
        toAnchor: toAnchor ?? NodeAnchor.left,
      ));
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

  void updateNodeSize(String id, Size newSize) {
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index != -1) {
      _nodes[index] = _nodes[index].copyWith(size: newSize);
      notifyListeners();
    }
  }

  void clearDiagram() {
    _nodes.clear();
    _connections.clear();
    notifyListeners();
  }
}
