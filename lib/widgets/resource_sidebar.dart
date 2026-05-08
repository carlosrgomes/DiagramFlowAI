import 'package:diagram_flow_ai/models/asset_manager.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class ResourceSidebar extends StatelessWidget {
  const ResourceSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cloud Library',
                  style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full AWS Catalog',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppColors.outlineVariant),
          
          // Dynamic Scrollable List of Categories
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: AssetManager.catalog.entries.map((category) {
                return ExpansionTile(
                  title: Text(
                    category.key.toUpperCase(),
                    style: AppTypography.labelCaps.copyWith(
                      fontSize: 10,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  initiallyExpanded: category.key.contains('Compute'),
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: category.value.map((template) {
                        return _buildDraggableResourceCard(template);
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          
          // Bottom Footer Action
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Center(
                child: Text(
                  'Sync Assets',
                  style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableResourceCard(ResourceTemplate template) {
    return Draggable<ResourceTemplate>(
      data: template,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 100,
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withAlpha(220),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(template.path, width: 28, height: 28),
              const SizedBox(height: 4),
              Text(
                template.label, 
                style: AppTypography.labelCaps.copyWith(color: Colors.white, fontSize: 8),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(template.path, width: 24, height: 24),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                template.label, 
                style: AppTypography.labelCaps.copyWith(fontSize: 8),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
