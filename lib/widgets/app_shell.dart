import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';
import 'package:diagram_flow_ai/widgets/resource_sidebar.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Placeholder
          Container(
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'CloudFlow AI',
                  style: AppTypography.h2.copyWith(color: AppColors.primary),
                ),
                const Spacer(),
                const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 16),
                const Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          // Main Body (3 Columns)
          Expanded(
            child: Row(
              children: [
                // Left Sidebar
                const ResourceSidebar(),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.outlineVariant),
                // Center Canvas
                const Expanded(child: DiagramCanvas()),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.outlineVariant),
                // Right Sidebar Placeholder
                Container(
                  width: 320,
                  color: AppColors.surfaceContainer,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildRightSection('Mermaid Architecture'),
                      ),
                      const Divider(height: 1, color: AppColors.outlineVariant),
                      Expanded(
                        flex: 1,
                        child: _buildRightSection('Gemma4 AI Assistant'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Footer Placeholder
          Container(
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.outlineVariant, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Gemma4 Connected | Engine: CloudFlow-v2.1',
                    style: AppTypography.code.copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('Documentation', style: AppTypography.code.copyWith(fontSize: 11)),
                const SizedBox(width: 16),
                Text('Privacy Policy', style: AppTypography.code.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            title,
            style: AppTypography.labelCaps,
          ),
        ),
        const Expanded(
          child: Center(
            child: Text('Content Placeholder'),
          ),
        ),
      ],
    );
  }
}
