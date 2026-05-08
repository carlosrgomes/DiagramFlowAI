import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left: Brand
          Text(
            'CloudFlow AI',
            style: AppTypography.h2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 24),
          
          // Center-Left: Nav Links
          _buildNavLink('Canvas', active: true),
          _buildNavLink('Resources'),
          _buildNavLink('Deployment'),
          _buildNavLink('History'),
          
          const Spacer(),

          // Center: Tool Palette
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToolIcon(Icons.zoom_in),
                  _buildToolIcon(Icons.zoom_out),
                  const VerticalDivider(width: 16, thickness: 1, indent: 4, endIndent: 4),
                  _buildToolIcon(Icons.near_me_outlined, active: true),
                  _buildToolIcon(Icons.account_tree_outlined),
                  _buildToolIcon(Icons.pan_tool_outlined),
                ],
              ),
            ),
          ),
          
          const Spacer(),

          // Right: Actions
          const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          const Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          
          _buildActionButton('Share', isPrimary: false),
          const SizedBox(width: 8),
          _buildActionButton('Export', isPrimary: true),
          
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 18, color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String label, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: active ? AppColors.primary : AppColors.onSurfaceVariant,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildToolIcon(IconData icon, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withAlpha(51) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: 16,
        color: active ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildActionButton(String label, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isPrimary ? null : Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: isPrimary ? AppColors.onPrimary : AppColors.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
