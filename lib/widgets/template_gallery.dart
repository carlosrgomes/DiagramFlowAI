import 'package:diagram_flow_ai/data/prompt_templates.dart';
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/prompt_dispatcher.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TemplateGallery extends StatelessWidget {
  final VoidCallback? onDismiss;

  const TemplateGallery({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AIModelState>();
    final ready = ai.isReady;

    final byCategory = <TemplateCategory, List<PromptTemplate>>{};
    for (final t in kPromptTemplates) {
      byCategory.putIfAbsent(t.category, () => []).add(t);
    }

    return Container(
      color: AppColors.background.withAlpha(245),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 560;
            return Row(
              children: [
                Icon(Icons.bolt_outlined, size: 22, color: AppColors.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Start with a template',
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    maxLines: 1,
                    style: AppTypography.h2.copyWith(
                      fontSize: 18,
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${kPromptTemplates.length}',
                    style: AppTypography.code.copyWith(
                        fontSize: 9, color: AppColors.primary),
                  ),
                ),
                const Spacer(),
                if (!ready && wide)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, left: 8),
                      child: Text(
                        'Model loading — pick anyway, it\'ll send when ready',
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        style: AppTypography.bodyMd.copyWith(
                            fontSize: 10, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  )
                else if (!ready)
                  Tooltip(
                    message: 'Model loading — pick anyway, it\'ll send when ready',
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.hourglass_top,
                          size: 14, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                if (onDismiss != null)
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 16),
                    color: AppColors.onSurfaceVariant,
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
              ],
            );
          }),
          const SizedBox(height: 4),
          Text(
            'Click a card to populate the chat and dispatch to Gemma. '
            'Covers every Mermaid diagram type — Google Cloud architectures, flows, '
            'analytics, planning, and one AWS → GCP migration.',
            style: AppTypography.bodyMd.copyWith(
                fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final cat in TemplateCategory.values)
                    if (byCategory[cat] != null)
                      _CategorySection(
                        title: cat.label,
                        templates: byCategory[cat]!,
                      ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: Text(
                        'or describe your own architecture →',
                        style: AppTypography.bodyMd.copyWith(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<PromptTemplate> templates;

  const _CategorySection({required this.title, required this.templates});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.labelCaps.copyWith(
                fontSize: 9,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.0,
              ),
            ),
          ),
          LayoutBuilder(builder: (context, c) {
            const minCardWidth = 220.0;
            final cols = (c.maxWidth / minCardWidth).floor().clamp(1, 5);
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
              children: [
                for (final t in templates) _TemplateCard(template: t),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  final PromptTemplate template;
  const _TemplateCard({required this.template});

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.read<PromptDispatcher>().dispatch(t.prompt);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hover
                ? AppColors.primary.withAlpha(28)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hover
                  ? AppColors.primary.withAlpha(140)
                  : AppColors.outlineVariant.withAlpha(80),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(t.icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withAlpha(60),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        t.diagramType,
                        style: AppTypography.code.copyWith(
                            fontSize: 8, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
