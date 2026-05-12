import 'dart:io';

import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/gallery_controller.dart';
import 'package:diagram_flow_ai/models/project_io.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';
import 'package:diagram_flow_ai/widgets/right_sidebar.dart';
import 'package:diagram_flow_ai/widgets/top_nav_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isMac => !kIsWeb && Platform.isMacOS;

  Future<void> _newProject() async {
    final state = context.read<DiagramState>();
    if (!await _confirmDiscard(state)) return;
    state.newProject();
  }

  Future<void> _openProject() async {
    final state = context.read<DiagramState>();
    final recent = context.read<RecentFiles>();
    if (!await _confirmDiscard(state)) return;
    final path = await ProjectIO.pickOpenPath();
    if (path == null) return;
    try {
      final raw = await ProjectIO.readString(path);
      final payload = ProjectFile.parse(raw);
      state.loadFromPayload(payload.nodes, payload.edges, payload.code, path: path);
      await recent.push(path);
      _toast('Opened ${_basename(path)}');
    } catch (e) {
      _toast('Could not open project: $e', isError: true);
    }
  }

  Future<void> _openRecent(String path) async {
    final state = context.read<DiagramState>();
    final recent = context.read<RecentFiles>();
    if (!await _confirmDiscard(state)) return;
    if (!await File(path).exists()) {
      _toast('File no longer exists: $path', isError: true);
      await recent.remove(path);
      return;
    }
    try {
      final raw = await ProjectIO.readString(path);
      final payload = ProjectFile.parse(raw);
      state.loadFromPayload(payload.nodes, payload.edges, payload.code, path: path);
      await recent.push(path);
      _toast('Opened ${_basename(path)}');
    } catch (e) {
      _toast('Could not open project: $e', isError: true);
    }
  }

  Future<void> _saveProject({bool forceDialog = false}) async {
    final state = context.read<DiagramState>();
    final recent = context.read<RecentFiles>();
    final path = (forceDialog || state.currentFilePath == null)
        ? await ProjectIO.pickSavePath(
            suggestedName: state.currentFilePath != null
                ? _basename(state.currentFilePath!)
                : null,
          )
        : state.currentFilePath;
    if (path == null) return;
    try {
      await ProjectIO.writeJson(path, ProjectFile.toJson(state));
      state.markSaved(path);
      await recent.push(path);
      _toast('Saved to ${_basename(path)}');
    } catch (e) {
      _toast('Save failed: $e', isError: true);
    }
  }

  Future<bool> _confirmDiscard(DiagramState state) async {
    if (!state.isDirty) return true;
    final keep = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Discard unsaved changes?',
            style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
        content: Text(
          'The current diagram has unsaved edits. Save before closing?',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (keep == null) return false;
    if (keep) await _saveProject();
    return true;
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTypography.bodyMd.copyWith(fontSize: 12)),
      backgroundColor:
          isError ? AppColors.error.withAlpha(220) : AppColors.surfaceContainer,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  String _basename(String path) {
    final i = path.lastIndexOf(Platform.pathSeparator);
    return i < 0 ? path : path.substring(i + 1);
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to theme changes so the entire AppShell tree rebuilds when
    // the user toggles light/dark — `AppColors.X` is a static getter that
    // doesn't participate in InheritedWidget dependency tracking, so we
    // need this explicit subscription to drive cascading rebuilds.
    context.watch<ThemeController>();

    final ctrl = _isMac
        ? LogicalKeyboardKey.meta
        : LogicalKeyboardKey.control;

    final shortcuts = <ShortcutActivator, VoidCallback>{
      SingleActivator(LogicalKeyboardKey.keyS,
              meta: _isMac, control: !_isMac): () => _saveProject(),
      SingleActivator(LogicalKeyboardKey.keyS,
              meta: _isMac, control: !_isMac, shift: true):
          () => _saveProject(forceDialog: true),
      SingleActivator(LogicalKeyboardKey.keyO,
              meta: _isMac, control: !_isMac): _openProject,
      SingleActivator(LogicalKeyboardKey.keyN,
              meta: _isMac, control: !_isMac): _newProject,
      SingleActivator(LogicalKeyboardKey.keyZ,
              meta: _isMac, control: !_isMac): () =>
          context.read<DiagramState>().undo(),
      SingleActivator(LogicalKeyboardKey.keyZ,
              meta: _isMac, control: !_isMac, shift: true): () =>
          context.read<DiagramState>().redo(),
      SingleActivator(LogicalKeyboardKey.keyT,
              meta: _isMac, control: !_isMac): () =>
          context.read<GalleryController>().toggle(),
    };
    // Reference ctrl so the analyzer doesn't complain on non-mac runs.
    assert(ctrl == ctrl);

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              TopNavBar(
                onNew: _newProject,
                onOpen: _openProject,
                onSave: () => _saveProject(),
                onSaveAs: () => _saveProject(forceDialog: true),
                onOpenRecent: _openRecent,
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: DiagramCanvas()),
                    VerticalDivider(
                        thickness: 1, width: 1, color: AppColors.outlineVariant),
                    RightSidebar(),
                  ],
                ),
              ),
              Container(
                height: 32,
                decoration: BoxDecoration(
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
                        'Gemma4 Connected | Engine: Diagram Flow AI v2.1',
                        style: AppTypography.code.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('Documentation',
                        style: AppTypography.code.copyWith(
                            fontSize: 10, color: AppColors.onSurfaceVariant)),
                    const SizedBox(width: 16),
                    Text('Privacy Policy',
                        style: AppTypography.code.copyWith(
                            fontSize: 10, color: AppColors.onSurfaceVariant)),
                    const SizedBox(width: 16),
                    Text('Terms of Service',
                        style: AppTypography.code.copyWith(
                            fontSize: 10, color: AppColors.onSurfaceVariant)),
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
