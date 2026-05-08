import 'package:flutter/material.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';

class DiagramNodeWidget extends StatelessWidget {
  final String label;
  final Offset position;

  const DiagramNodeWidget({
    super.key,
    required this.label,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(128),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTypography.bodyMd,
        ),
      ),
    );
  }
}
