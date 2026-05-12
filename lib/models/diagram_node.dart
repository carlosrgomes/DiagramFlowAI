enum NodeType {
  resource,
  group,
}

class DiagramNode {
  final String id;
  final String label;
  final NodeType type;
  final String? parentId;
  final String? iconPath;
  /// Mermaid v11 shape key (rect, rounded, hex, diam, cyl, doc, ...).
  /// Defaults to 'rect' when omitted.
  final String shape;

  DiagramNode({
    required this.id,
    required this.label,
    required this.type,
    this.parentId,
    this.iconPath,
    this.shape = 'rect',
  });
}
