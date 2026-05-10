enum NodeType {
  resource,
  group,
}

class DiagramNode {
  final String id;
  final String label;
  final NodeType type;
  final String? parentId;

  DiagramNode({
    required this.id,
    required this.label,
    required this.type,
    this.parentId,
  });
}
