import 'package:diagram_flow_ai/models/asset_manager.dart';
import 'package:diagram_flow_ai/models/resource_template.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class ResourceSidebar extends StatelessWidget {
  const ResourceSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final dragResources = [
      ResourceTemplate(label: 'EC2', icon: Icons.memory_outlined, color: AppColors.secondary),
      ResourceTemplate(label: 'RDS', icon: Icons.dns_outlined, color: AppColors.secondary),
      ResourceTemplate(label: 'S3', icon: Icons.folder_open_outlined, color: AppColors.secondary),
      ResourceTemplate(label: 'VPC', icon: Icons.router_outlined, color: AppColors.secondary),
    ];

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
          
          const SizedBox(height: 32),
          
          // Drag Resources Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'DRAG RESOURCES',
              style: AppTypography.labelCaps.copyWith(letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: dragResources.map((template) => _buildDraggableResourceCard(template)).toList(),
            ),
          ),
          
          const Spacer(),
          
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
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(
          icon,
          size: 20,
          color: active ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
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
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withAlpha(200),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AssetManager.getIconForLabel(template.label), width: 32, height: 32),
              const SizedBox(height: 4),
              Text(
                template.label, 
                style: AppTypography.labelCaps.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildResourceCard(template.label),
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
          Text(label, style: AppTypography.labelCaps),
        ],
      ),
    );
  }
}
