import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/resource_template.dart';
import 'package:diagram_flow_ai/widgets/diagram_node.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class GridBackgroundPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;

  GridBackgroundPainter({
    required this.gridColor,
    this.spacing = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConnectionPainter extends CustomPainter {
  final List<DiagramNode> nodes;
  final List<DiagramConnection> connections;
  final Color color;

  ConnectionPainter({required this.nodes, required this.connections, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final connection in connections) {
      DiagramNode? fromNode;
      DiagramNode? toNode;
      
      try {
        fromNode = nodes.firstWhere((n) => n.id == connection.fromId);
        toNode = nodes.firstWhere((n) => n.id == connection.toId);
      } catch (_) {
        continue;
      }

      final start = fromNode.getAnchorPosition(connection.fromAnchor);
      final end = toNode.getAnchorPosition(connection.toAnchor);

      final path = Path();
      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);
      canvas.drawPath(path, paint);

      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      const arrowSize = 8.0;
      final arrowPath = Path();
      arrowPath.moveTo(end.dx, end.dy);
      arrowPath.lineTo(
        end.dx - arrowSize * math.cos(angle - math.pi / 6),
        end.dy - arrowSize * math.sin(angle - math.pi / 6),
      );
      arrowPath.lineTo(
        end.dx - arrowSize * math.cos(angle + math.pi / 6),
        end.dy - arrowSize * math.sin(angle + math.pi / 6),
      );
      arrowPath.close();
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) => true;
}

class DiagramCanvas extends StatefulWidget {
  const DiagramCanvas({super.key});

  @override
  State<DiagramCanvas> createState() => _DiagramCanvasState();
}

class _DiagramCanvasState extends State<DiagramCanvas> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return DragTarget<ResourceTemplate>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final state = context.read<DiagramState>();
        
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final Offset localOffset = renderBox.globalToLocal(details.offset);
        final Offset adjustedOffset = _transformationController.toScene(localOffset);

        state.addNode(
          id: 'node_${DateTime.now().millisecondsSinceEpoch}',
          label: details.data.label,
          position: adjustedOffset,
        );

        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Added ${details.data.label}'),
            behavior: SnackBarBehavior.floating,
            width: 200,
            duration: const Duration(milliseconds: 1500),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: const Color(0xFFF3F4F6),
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(2500),
            minScale: 0.1,
            maxScale: 2.0,
            constrained: false,
            child: Consumer<DiagramState>(
              builder: (context, state, child) {
                return Container(
                  width: 5000,
                  height: 5000,
                  color: Colors.white,
                  child: CustomPaint(
                    painter: GridBackgroundPainter(
                      gridColor: Colors.black.withAlpha(15),
                    ),
                    foregroundPainter: ConnectionPainter(
                      nodes: state.nodes,
                      connections: state.connections,
                      color: const Color(0xFF202124),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: state.nodes.map((node) {
                        return DiagramNodeWidget(
                          key: ValueKey(node.id),
                          label: node.label,
                          position: node.position,
                          size: node.size,
                          onDragUpdate: (delta) {
                            state.updateNodePosition(node.id, node.position + delta);
                          },
                          onResizeUpdate: (newSize) {
                            state.updateNodeSize(node.id, newSize);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
