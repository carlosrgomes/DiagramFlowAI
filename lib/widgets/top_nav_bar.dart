import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:diagram_flow_ai/models/diagram_exporter.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/diagram_viewport.dart';
import 'package:diagram_flow_ai/models/gallery_controller.dart';
import 'package:diagram_flow_ai/models/project_io.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _ExportFormat { png, svg, mermaid }

enum _FileAction { newProject, open, save, saveAs }

class TopNavBar extends StatelessWidget {
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onSaveAs;
  final void Function(String path) onOpenRecent;

  const TopNavBar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onSaveAs,
    required this.onOpenRecent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            'Diagram Flow AI',
            style: AppTypography.h2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          _FileMenuButton(
            onNew: onNew,
            onOpen: onOpen,
            onSave: onSave,
            onSaveAs: onSaveAs,
            onOpenRecent: onOpenRecent,
          ),
          const SizedBox(width: 4),
          const _TemplatesButton(),
          const SizedBox(width: 4),
          const _UndoRedoButtons(),
          const SizedBox(width: 12),
          const Flexible(flex: 3, child: _ProjectTitle()),
          const Spacer(),
          Flexible(
            flex: 4,
            child: Consumer<DiagramViewport>(
              builder: (context, vp, _) => Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToolIcon(Icons.zoom_in, tooltip: 'Zoom in (Alt + +)', onTap: vp.zoomIn),
                    _buildToolIcon(Icons.zoom_out, tooltip: 'Zoom out (Alt + -)', onTap: vp.zoomOut),
                    _buildToolIcon(
                      Icons.near_me_outlined,
                      tooltip: 'Select mode',
                      active: !vp.panMode,
                      onTap: vp.panMode ? vp.togglePan : null,
                    ),
                    _buildToolIcon(
                      Icons.pan_tool_outlined,
                      tooltip: 'Pan mode (or hold Space + drag)',
                      active: vp.panMode,
                      onTap: vp.togglePan,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Flexible(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                _ThemeToggle(),
                SizedBox(width: 8),
                _ExportButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon(
    IconData icon, {
    bool active = false,
    String? tooltip,
    VoidCallback? onTap,
  }) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: active ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }
}

class _ExportButton extends StatefulWidget {
  const _ExportButton();

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ExportFormat>(
      enabled: !_busy,
      tooltip: 'Export diagram',
      position: PopupMenuPosition.under,
      color: AppColors.surfaceContainer,
      onSelected: _handleSelect,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ExportFormat.png,
          child: _MenuRow(icon: Icons.image_outlined, label: 'PNG image', hint: '.png'),
        ),
        PopupMenuItem(
          value: _ExportFormat.svg,
          child: _MenuRow(icon: Icons.polyline_outlined, label: 'SVG vector', hint: '.svg'),
        ),
        PopupMenuItem(
          value: _ExportFormat.mermaid,
          child: _MenuRow(icon: Icons.code, label: 'Mermaid source', hint: '.mmd'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                ),
              )
            else
              Icon(Icons.download_outlined, size: 12, color: AppColors.onPrimary),
            const SizedBox(width: 4),
            Text(
              'Export',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSelect(_ExportFormat fmt) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final exporter = context.read<DiagramExporter>();
      final diagram = context.read<DiagramState>();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;

      Uint8List? bytes;
      String suggestedName;
      String ext;

      switch (fmt) {
        case _ExportFormat.mermaid:
          bytes = Uint8List.fromList(utf8.encode(diagram.mermaidCode));
          suggestedName = 'diagram-$stamp.mmd';
          ext = 'mmd';
        case _ExportFormat.svg:
          final svg = await exporter.getSvg();
          if (svg == null) {
            _notify('No diagram to export yet.');
            return;
          }
          bytes = Uint8List.fromList(utf8.encode(svg));
          suggestedName = 'diagram-$stamp.svg';
          ext = 'svg';
        case _ExportFormat.png:
          final png = await exporter.getPng();
          if (png == null) {
            _notify('Could not render PNG. Try again after the diagram loads.');
            return;
          }
          bytes = png;
          suggestedName = 'diagram-$stamp.png';
          ext = 'png';
      }

      final path = await FilePicker.saveFile(
        dialogTitle: 'Export diagram',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: [ext],
        bytes: bytes,
      );

      if (path == null) return;
      final file = File(path);
      if (!await file.exists() || (await file.length()) == 0) {
        await file.writeAsBytes(bytes);
      }
      _notify('Saved to $path');
    } catch (e) {
      _notify('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.bodyMd.copyWith(fontSize: 12)),
        backgroundColor: AppColors.surfaceContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _FileMenuButton extends StatelessWidget {
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onSaveAs;
  final void Function(String path) onOpenRecent;

  const _FileMenuButton({
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onSaveAs,
    required this.onOpenRecent,
  });

  @override
  Widget build(BuildContext context) {
    final recents = context.watch<RecentFiles>().paths;
    return PopupMenuButton<Object>(
      tooltip: 'File',
      position: PopupMenuPosition.under,
      color: AppColors.surfaceContainer,
      onSelected: (v) {
        if (v == _FileAction.newProject) {
          onNew();
        } else if (v == _FileAction.open) {
          onOpen();
        } else if (v == _FileAction.save) {
          onSave();
        } else if (v == _FileAction.saveAs) {
          onSaveAs();
        } else if (v is String) {
          onOpenRecent(v);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _FileAction.newProject,
          child: _MenuRow(icon: Icons.note_add_outlined, label: 'New project', hint: '⌘N'),
        ),
        const PopupMenuItem(
          value: _FileAction.open,
          child: _MenuRow(icon: Icons.folder_open_outlined, label: 'Open…', hint: '⌘O'),
        ),
        const PopupMenuItem(
          value: _FileAction.save,
          child: _MenuRow(icon: Icons.save_outlined, label: 'Save', hint: '⌘S'),
        ),
        const PopupMenuItem(
          value: _FileAction.saveAs,
          child: _MenuRow(icon: Icons.save_as_outlined, label: 'Save As…', hint: '⌘⇧S'),
        ),
        if (recents.isNotEmpty) const PopupMenuDivider(),
        if (recents.isNotEmpty)
          PopupMenuItem(
            enabled: false,
            child: Text('RECENT',
                style: AppTypography.labelCaps.copyWith(
                    fontSize: 9, color: AppColors.onSurfaceVariant)),
          ),
        for (final p in recents.take(5))
          PopupMenuItem(
            value: p,
            child: _MenuRow(
              icon: Icons.history,
              label: _basename(p),
              hint: '',
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 13, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('File',
                style: AppTypography.bodyMd
                    .copyWith(fontSize: 11, color: AppColors.onSurfaceVariant)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static String _basename(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (_, t, _) {
        return Tooltip(
          message: t.isDark ? 'Switch to light theme' : 'Switch to dark theme',
          child: InkWell(
            onTap: t.toggle,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                t.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TemplatesButton extends StatelessWidget {
  const _TemplatesButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryController>(
      builder: (_, gc, _) {
        final active = gc.isOpen;
        return Tooltip(
          message: active ? 'Hide templates (⌘T)' : 'Show templates (⌘T)',
          child: InkWell(
            onTap: gc.toggle,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withAlpha(40)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: active
                      ? AppColors.primary.withAlpha(140)
                      : AppColors.outlineVariant.withAlpha(80),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_outlined,
                      size: 13,
                      color: active
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Templates',
                    style: AppTypography.bodyMd.copyWith(
                      fontSize: 11,
                      color: active
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UndoRedoButtons extends StatelessWidget {
  const _UndoRedoButtons();

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagramState>(
      builder: (_, st, _)=> Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBtn(
            icon: Icons.undo,
            tooltip: 'Undo (⌘Z)',
            enabled: st.canUndo,
            onTap: st.undo,
          ),
          _IconBtn(
            icon: Icons.redo,
            tooltip: 'Redo (⌘⇧Z)',
            enabled: st.canRedo,
            onTap: st.redo,
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.onSurfaceVariant
        : AppColors.onSurfaceVariant.withAlpha(60);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _ProjectTitle extends StatelessWidget {
  const _ProjectTitle();

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagramState>(
      builder: (_, st, _){
        final path = st.currentFilePath;
        final name = path == null ? 'Untitled' : _basename(path);
        return Tooltip(
          message: path ?? 'Unsaved project',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                  style: AppTypography.bodyMd.copyWith(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: path == null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              if (st.isDirty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.circle,
                      size: 6, color: AppColors.primary.withAlpha(180)),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _basename(String path) {
    final i = path.lastIndexOf('/');
    final n = i < 0 ? path : path.substring(i + 1);
    return n.endsWith('.cloudflow.json')
        ? n.substring(0, n.length - '.cloudflow.json'.length)
        : n;
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  const _MenuRow({required this.icon, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            maxLines: 1,
            style: AppTypography.bodyMd.copyWith(fontSize: 12),
          ),
        ),
        if (hint.isNotEmpty) ...[
          const SizedBox(width: 12),
          Text(
            hint,
            style: AppTypography.code.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
