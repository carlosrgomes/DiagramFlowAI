import 'package:diagram_flow_ai/models/asset_manager.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:flutter/material.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';

class DiagramNodeWidget extends StatefulWidget {
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
  State<DiagramNodeWidget> createState() => _DiagramNodeWidgetState();
}

class _DiagramNodeWidgetState extends State<DiagramNodeWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    String iconPath;
    try {
       iconPath = AssetManager.getIconForLabel(widget.label);
    } catch (_) {
       iconPath = ''; 
    }

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onPanUpdate: (details) {
                if (widget.onDragUpdate != null) {
                  widget.onDragUpdate!(details.delta);
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
                        if (iconPath.isNotEmpty)
                           Image.asset(iconPath, width: 22, height: 22)
                        else
                           const Icon(Icons.help_outline, size: 22, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          widget.label,
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
            // Anchor Points (Visible on Hover)
            if (_isHovered) ...[
              _buildAnchor(NodeAnchor.top, alignment: Alignment.topCenter),
              _buildAnchor(NodeAnchor.bottom, alignment: Alignment.bottomCenter),
              _buildAnchor(NodeAnchor.left, alignment: Alignment.centerLeft),
              _buildAnchor(NodeAnchor.right, alignment: Alignment.centerRight),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnchor(NodeAnchor anchor, {required Alignment alignment}) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
