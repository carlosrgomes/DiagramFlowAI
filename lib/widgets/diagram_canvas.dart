import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/resource_template.dart';
import 'package:diagram_flow_ai/widgets/diagram_node.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Container(
      color: const Color(0xFFF3F4F6),
      child: DragTarget<ResourceTemplate>(
        onAcceptWithDetails: (details) {
          final state = context.read<DiagramState>();
          
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset localOffset = renderBox.globalToLocal(details.offset);
          final Offset adjustedOffset = _transformationController.toScene(localOffset);

          state.addNode(
            id: DateTime.now().toIso8601String(),
            label: details.data.label,
            position: adjustedOffset,
          );
        },
        builder: (context, candidateData, rejectedData) {
          return InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 2.0,
            constrained: false,
            child: Consumer<DiagramState>(
              builder: (context, state, child) {
                return SizedBox(
                  width: 5000,
                  height: 5000,
                  child: CustomPaint(
                    painter: GridBackgroundPainter(
                      gridColor: Colors.black.withAlpha(20),
                    ),
                    child: Stack(
                      children: state.nodes.map((node) {
                        return DiagramNodeWidget(
                          label: node.label,
                          position: node.position,
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
