import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';
import 'package:diagram_flow_ai/widgets/resource_sidebar.dart';
import 'package:diagram_flow_ai/widgets/right_sidebar.dart';
import 'package:diagram_flow_ai/widgets/top_nav_bar.dart';
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
          const TopNavBar(),
          // Main Body (3 Columns)
          Expanded(
            child: Row(
              children: [
                // Left Sidebar
                const ResourceSidebar(),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.outlineVariant),
                
                // Center Canvas
                const Expanded(
                  child: DiagramCanvas(),
                ),
                
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.outlineVariant),
                
                // Right Sidebar
                const RightSidebar(),
              ],
            ),
          ),
          // Footer
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
                    style: AppTypography.code.copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Text('Documentation', style: AppTypography.code.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                const SizedBox(width: 16),
                Text('Privacy Policy', style: AppTypography.code.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                const SizedBox(width: 16),
                Text('Terms of Service', style: AppTypography.code.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
