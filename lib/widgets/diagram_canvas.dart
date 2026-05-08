import 'package:flutter/material.dart';

class GridBackgroundPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;

  GridBackgroundPainter({
    required this.gridColor,
    this.spacing = 32.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

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

class DiagramCanvas extends StatelessWidget {
  const DiagramCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 2.0,
      constrained: false,
      child: CustomPaint(
        size: const Size(5000, 5000), // Large canvas area
        painter: GridBackgroundPainter(
          gridColor: Theme.of(context).colorScheme.outlineVariant.withAlpha(51), // 0.2 opacity
        ),
      ),
    );
  }
}
