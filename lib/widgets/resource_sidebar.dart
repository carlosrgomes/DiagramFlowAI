import 'package:diagram_flow_ai/models/asset_manager.dart';
import 'package:diagram_flow_ai/models/resource_template.dart';
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
          // Cloud Library Header
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
                  'VPC-Primary-Alpha',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // Provider Tabs
          _buildProviderItem(Icons.cloud_outlined, 'AWS', active: true),
          _buildProviderItem(Icons.layers_outlined, 'Azure'),
          _buildProviderItem(Icons.hub_outlined, 'GCP'),
          _buildProviderItem(Icons.grid_view_outlined, 'Kubernetes'),
          
          const SizedBox(height: 24),
          
          // Drag Resources Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'DRAG RESOURCES',
              style: AppTypography.labelCaps.copyWith(letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: AssetManager.awsLibrary.entries.map((category) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                      child: Text(
                        category.key.toUpperCase(),
                        style: AppTypography.labelCaps.copyWith(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant.withAlpha(150),
                        ),
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: category.value.entries.map((resource) {
                        return _buildDraggableResourceCard(
                          ResourceTemplate(
                            label: resource.key,
                            icon: Icons.help_outline, // Not used anymore as we use AssetManager
                            color: AppColors.secondary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          
          // Bottom CTA
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
                  '+ Add Resource',
                  style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderItem(IconData icon, String label, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withAlpha(51) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -4),
        leading: Icon(
          icon,
          size: 18,
          color: active ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
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
              Image.asset(AssetManager.getIconForLabel(template.label), width: 28, height: 28),
              const SizedBox(height: 4),
              Text(
                template.label, 
                style: AppTypography.labelCaps.copyWith(color: Colors.white, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
      child: _buildResourceCard(template.label),
    );
  }

  Widget _buildResourceCard(String label) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AssetManager.getIconForLabel(label), width: 24, height: 24),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.labelCaps.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
