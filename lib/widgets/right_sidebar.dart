import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class RightSidebar extends StatelessWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      color: AppColors.surface,
      child: Column(
        children: [
          // Mermaid Architecture Section
          Expanded(
            flex: 2,
            child: _buildCodeSection(context),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          // Gemma4 AI Assistant Section
          Expanded(
            flex: 3,
            child: _buildChatSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSection(BuildContext context) {
    const mockCode = '''graph TD
  A[App ALB] -->|Traffic| B(Web API-1)
  A -->|Traffic| C(Web API-2)
  B --> D{Primary DB}
  C --> D''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mermaid Architecture',
                style: AppTypography.labelCaps,
              ),
              const Icon(Icons.copy_all_outlined, size: 16, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF060A14), // Darker code background
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
            ),
            child: Text(
              mockCode,
              style: AppTypography.code.copyWith(color: AppColors.secondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Gemma4 AI Assistant',
                style: AppTypography.labelCaps,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildChatMessage(
                'I\'ve generated the base VPC and added two EC2 instances behind an ALB. Would you like me to add a Redis cache cluster next to the RDS?',
                isAI: true,
              ),
              const SizedBox(height: 16),
              _buildChatMessage(
                'Yes, add an ElastiCache Redis node and update the Mermaid code to reflect it.',
                isAI: false,
              ),
            ],
          ),
        ),
        // Chat Input
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: 'Ask Gemma4 to modify architecture...',
              hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              suffixIcon: const Icon(Icons.send_outlined, size: 18, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage(String text, {required bool isAI}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAI ? AppColors.primary.withAlpha(30) : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: isAI ? Border.all(color: AppColors.primary.withAlpha(50)) : null,
      ),
      child: Text(
        text,
        style: AppTypography.bodyMd.copyWith(
          color: isAI ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
