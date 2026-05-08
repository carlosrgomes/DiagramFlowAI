import 'package:diagram_flow_ai/models/asset_manager.dart';
import 'package:flutter/material.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';

class DiagramNodeWidget extends StatelessWidget {
  final String label;
  final Offset position;
  final Function(Offset delta)? onDragUpdate;

  const DiagramNodeWidget({
    super.key,
    required this.label,
    required this.position,
    this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (onDragUpdate != null) {
            onDragUpdate!(details.delta);
          }
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AssetManager.getIconForLabel(label), width: 22, height: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
