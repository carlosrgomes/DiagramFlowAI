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
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIconForLabel(label), color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    if (label.contains('EC2')) return Icons.memory_outlined;
    if (label.contains('RDS')) return Icons.dns_outlined;
    if (label.contains('S3')) return Icons.folder_open_outlined;
    if (label.contains('VPC')) return Icons.router_outlined;
    return Icons.settings_input_component_outlined;
  }
}
