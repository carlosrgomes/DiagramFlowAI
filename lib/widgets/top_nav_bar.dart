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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand & Nav
          Row(
            children: [
              Text(
                'CloudFlow AI',
                style: AppTypography.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 32),
              _buildNavLink('Canvas', active: true),
              _buildNavLink('Resources'),
              _buildNavLink('Deployment'),
              _buildNavLink('History'),
            ],
          ),
          
          // Center: Tool Palette
          Container(
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
                const SizedBox(width: 8),
                _buildToolIcon(Icons.near_me_outlined, active: true),
                _buildToolIcon(Icons.account_tree_outlined),
                _buildToolIcon(Icons.pan_tool_outlined),
              ],
            ),
          ),
          
          // Right: Actions
          Row(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant, size: 20),
              const SizedBox(width: 16),
              const Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant, size: 20),
              const SizedBox(width: 16),
              _buildActionButton('Share', isPrimary: false),
              const SizedBox(width: 8),
              _buildActionButton('Export', isPrimary: true),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 20, color: AppColors.onPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String label, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: active ? AppColors.primary : AppColors.onSurfaceVariant,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildToolIcon(IconData icon, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? AppColors.surfaceContainerHighest : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: 18,
        color: active ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildActionButton(String label, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.surfaceContainerHighest : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
