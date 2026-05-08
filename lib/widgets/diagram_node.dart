import 'package:diagram_flow_ai/models/asset_manager.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:flutter/material.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';

class DiagramNodeWidget extends StatefulWidget {
  final String label;
  final Offset position;
  final Size size;
  final Function(Offset delta)? onDragUpdate;
  final Function(Size newSize)? onResizeUpdate;

  const DiagramNodeWidget({
    super.key,
    required this.label,
    required this.position,
    required this.size,
    this.onDragUpdate,
    this.onResizeUpdate,
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
                  width: widget.size.width,
                  height: widget.size.height,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (iconPath.isNotEmpty)
                           Image.asset(iconPath, width: 22, height: 22)
                        else
                           const Icon(Icons.help_outline, size: 22, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.label,
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Resize Handle (Bottom Right)
            if (_isHovered)
              Positioned(
                right: -4,
                bottom: -4,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (widget.onResizeUpdate != null) {
                      final newSize = Size(
                        (widget.size.width + details.delta.dx).clamp(80.0, 400.0),
                        (widget.size.height + details.delta.dy).clamp(40.0, 200.0),
                      );
                      widget.onResizeUpdate!(newSize);
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
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
            width: 10,
            height: 10,
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
